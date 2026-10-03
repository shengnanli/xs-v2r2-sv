// INT2FP.sv —— 向量转换 64 位通道里的「整数 → 浮点」子单元（yunsuan INT2FP，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：VCVT_8 -> VectorCvtTop -> VectorCvt -> VCVT(64) -> CVT64_1 的三个并行子单元之一
//   （另两个是 FP_INCVT：浮点源的转换；Estimate7：vfrec7/vfrsqrt7）。三者同拍收同一组输入，
//   CVT64_1 在第 2 拍末按操作类型三选一。
// 输入：src 低位放一个 8/16/32/64 位整数（宽度由 input1H 独热指定），opType[0]=有符号；
//   输出格式由 output1H 独热指定（[1]=f16, [2]=f32, [3]=f64；[0]=8 位不是浮点格式，忽略）。
// 机制（Scala: yunsuan/vector/VectorConvert/CVT64.scala class INT2FP）：
//   第 0 拍（组合，落 s1 寄存器）：按宽度符号/零扩展到 65 位 -> 取绝对值 -> CLZ 求前导零；
//     指数加法器的两个加数提前备好：bias+63 与 -(前导零)。
//   第 1 拍：绝对值左移前导零+1 位（把最高位的隐含 1 移出去），按目标格式取尾数 /
//     round 位 / sticky 位交给 RoundingUnit；进位 cout 时指数 +1；判上溢；
//     四选一出结果：上溢且向 0 方向舍（rmin）-> 最大有限数，上溢其余 -> 无穷，
//     源为 0 -> ±0，其余 -> 正常舍入结果。落 s2 结果寄存器。
//   fflags 只可能有 OF 与 NX（整数转浮点不会 NV/DZ/UF）。
// 怪癖（照 golden）：
//   - 所有 Mux1H 都是「各路与门再按位或」，非独热的 output1H 会把多路结果或在一起；
//   - 指数加法器宽 13 位（够用），上溢判定看 exp[12]=0 且（[fmt 指数宽-1:0] 全 1 或更高位非 0）；
//   - fireReg_last_r 是 GatedValidRegNext：只在 fire 或自身为 1 时更新，等价于 fire 打一拍。
// 子模块：CLZ_6（64 位前导零）、RoundingUnit_3（舍入判定）—— 均为本仓已签核重写件。
// golden 对照：G1-canonical/golden-rtl/INT2FP.sv
// =============================================================================

module xs_INT2FP_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,          // 本拍输入有效
  input  logic [63:0] src,           // 整数源（低位对齐）
  input  logic [7:0]  op_type,       // 只用 [0]：1=有符号整数
  input  logic [2:0]  rm_in,         // 舍入模式（RNE/RTZ/RDN/RUP/RMM/ROD）
  input  logic [3:0]  in_width_1h,   // 源整数宽度独热：[0]=8 [1]=16 [2]=32 [3]=64
  input  logic [3:0]  out_width_1h,  // 目标格式独热：[1]=f16 [2]=f32 [3]=f64
  output logic [63:0] result_out,
  output logic [4:0]  fflags_out     // {NV, DZ, OF, UF, NX}
);

  // ===========================================================================
  // §0 第 0 拍：扩展、取绝对值、求前导零、备好指数加数
  // ===========================================================================
  // 按源宽度扩展到 65 位：有符号且最高位为 1 时补 1，否则补 0（Mux1H，各路按位或）。
  logic        is_signed;
  logic [64:0] int_ext;            // 65 位扩展后的整数，[64] 即符号
  logic        sign_next;
  logic [63:0] abs_int_next;       // |整数|（64 位够放 2^63）
  logic [6:0]  lead_zeros_next;    // abs_int_next 的前导零个数（0..64）
  logic [7:0]  minus_lz8;          // -(前导零)，8 位补码
  logic [12:0] exp_bias_next;      // bias + 63：最高有效位在第 63 位时的指数
  logic [12:0] exp_minus_lz_next;  // -(前导零)，符号扩展到 13 位

  assign is_signed = op_type[0];
  assign int_ext =
      (in_width_1h[0] ? {{57{is_signed & src[7]}},  src[7:0]}  : 65'h0)
    | (in_width_1h[1] ? {{49{is_signed & src[15]}}, src[15:0]} : 65'h0)
    | (in_width_1h[2] ? {{33{is_signed & src[31]}}, src[31:0]} : 65'h0)
    | (in_width_1h[3] ? {is_signed & src[63], src}             : 65'h0);
  assign sign_next    = int_ext[64];
  assign abs_int_next = sign_next ? 64'(~int_ext[63:0] + 64'h1) : int_ext[63:0];

  CLZ_6 leadZerosNext_clz (
    .io_in  (abs_int_next),
    .io_out (lead_zeros_next)
  );

  // 指数 = (bias + 63) - 前导零：结果的最高有效位在第 (63 - 前导零) 位。
  // 目标格式的 bias：f16=15、f32=127、f64=1023，各加 63。
  assign exp_bias_next =
      (out_width_1h[1] ? 13'd78   : 13'h0)   // 15 + 63
    | (out_width_1h[2] ? 13'd190  : 13'h0)   // 127 + 63
    | (out_width_1h[3] ? 13'd1086 : 13'h0);  // 1023 + 63
  assign minus_lz8         = 8'(~{1'b0, lead_zeros_next} + 8'h1);
  assign exp_minus_lz_next = {{5{minus_lz8[7]}}, minus_lz8};

  // ===========================================================================
  // §1 s1 寄存器（fire 使能）。fireReg_last_r = fire 打一拍（GatedValidRegNext）。
  //    golden 的复位域：控制/符号位异步复位；指数加数、绝对值、前导零不复位。
  // ===========================================================================
  logic        fireReg_last_r;
  logic [3:0]  output1HReg;
  logic        signSrc;
  logic [2:0]  rm;
  logic        isZeroIntSrc;
  logic [12:0] expAdderIn0;
  logic [12:0] expAdderIn1;
  logic [63:0] absIntSrc;
  logic [6:0]  leadZeros;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r <= 1'b0;
      output1HReg    <= 4'h0;
      signSrc        <= 1'b0;
      rm             <= 3'h0;
      isZeroIntSrc   <= 1'b0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        output1HReg  <= out_width_1h;
        signSrc      <= sign_next;
        rm           <= rm_in;
        isZeroIntSrc <= abs_int_next == 64'h0;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      expAdderIn0 <= exp_bias_next;
      expAdderIn1 <= exp_minus_lz_next;
      absIntSrc   <= abs_int_next;
      leadZeros   <= lead_zeros_next;
    end
  end

  // ===========================================================================
  // §2 第 1 拍：规格化左移、按目标格式切尾数、舍入
  // ===========================================================================
  logic        out_f16, out_f32, out_f64;
  logic [12:0] exp;                // 未舍入指数
  logic [63:0] shifted;            // 绝对值左移 (前导零 + 1)：隐含 1 移出，尾数顶格
  logic [51:0] frac_in;            // 交给舍入器的尾数（f16 取 10 位、f32 取 23、f64 取 52）
  logic        round_bit;
  logic        sticky_bit;
  logic        frac_all_ones;      // 尾数全 1：再进位就会进到指数
  logic        rnd_inexact;
  logic        rnd_up;

  assign out_f16 = output1HReg[1];
  assign out_f32 = output1HReg[2];
  assign out_f64 = output1HReg[3];

  assign exp     = 13'(expAdderIn0 + expAdderIn1);
  assign shifted = 64'({absIntSrc, 1'b0} << leadZeros);

  assign frac_in =
      (out_f16 ? 52'(shifted[63:54]) : 52'h0)
    | (out_f32 ? 52'(shifted[63:41]) : 52'h0)
    | (out_f64 ? shifted[63:12]      : 52'h0);
  assign round_bit =
      out_f16 & shifted[53] | out_f32 & shifted[40] | out_f64 & shifted[11];
  assign sticky_bit =
      out_f16 & (|shifted[52:0]) | out_f32 & (|shifted[39:0]) | out_f64 & (|shifted[10:0]);
  assign frac_all_ones =
      out_f16 & (&shifted[63:54]) | out_f32 & (&shifted[63:41]) | out_f64 & (&shifted[63:12]);

  RoundingUnit_3 rounder (
    .io_in       ({12'h0, frac_in}),
    .io_roundIn  (round_bit),
    .io_stickyIn (sticky_bit),
    .io_signIn   (signSrc),
    .io_rm       (rm),
    .io_inexact  (rnd_inexact),
    .io_r_up     (rnd_up)
  );

  // 舍入后：尾数 +1；若尾数原本全 1 则进位到指数（cout）。
  logic        cout;
  logic [10:0] exp_rounded;
  logic [51:0] frac_rounded;
  assign cout         = rnd_up & frac_all_ones;
  assign exp_rounded  = cout ? 11'(exp[10:0] + 11'h1) : exp[10:0];
  assign frac_rounded = rnd_up ? 52'(frac_in + 52'h1) : frac_in;

  // 上溢：指数非负（[12]=0）且 ≥ 全 1 指数（进位时提前一档判）。
  // 每个格式看自己的指数宽 E：[E-1:0] 全 1，或 [11:E] 有 1。
  logic of_f16, of_f32, of_f64, overflow;
  assign of_f16 = cout ? (&exp[4:1])  | (|exp[11:5]) : (&exp[4:0])  | (|exp[11:5]);
  assign of_f32 = cout ? (&exp[7:1])  | (|exp[11:8]) : (&exp[7:0])  | (|exp[11:8]);
  assign of_f64 = cout ? (&exp[10:1]) | exp[11]      : (&exp[10:0]) | exp[11];
  assign overflow = ~exp[12] & (out_f16 & of_f16 | out_f32 & of_f32 | out_f64 & of_f64);

  // rmin：舍入方向朝 0（RTZ，或负数 RUP，或正数 RDN）—— 上溢时给最大有限数而非无穷
  logic rmin;
  assign rmin = rm == 3'h1 | signSrc & rm == 3'h3 | ~signSrc & rm == 3'h2;

  // 四类结果的独热选择（Mux1H）
  logic sel_max_finite, sel_inf, sel_normal;
  assign sel_max_finite = overflow & rmin;
  assign sel_inf        = overflow & ~rmin;
  assign sel_normal     = ~overflow & ~isZeroIntSrc;

  logic [15:0] result_f16;
  logic [31:0] result_f32;
  logic [63:0] result_f64;
  assign result_f16 =
      (sel_max_finite ? {signSrc, 5'h1E, 10'h3FF}                       : 16'h0)
    | (sel_inf        ? {signSrc, 5'h1F, 10'h0}                         : 16'h0)
    | (isZeroIntSrc   ? {signSrc, 15'h0}                                : 16'h0)
    | (sel_normal     ? {signSrc, exp_rounded[4:0], frac_rounded[9:0]}  : 16'h0);
  assign result_f32 =
      (sel_max_finite ? {signSrc, 8'hFE, 23'h7FFFFF}                    : 32'h0)
    | (sel_inf        ? {signSrc, 8'hFF, 23'h0}                         : 32'h0)
    | (isZeroIntSrc   ? {signSrc, 31'h0}                                : 32'h0)
    | (sel_normal     ? {signSrc, exp_rounded[7:0], frac_rounded[22:0]} : 32'h0);
  assign result_f64 =
      (sel_max_finite ? {signSrc, 11'h7FE, 52'hFFFFFFFFFFFFF}           : 64'h0)
    | (sel_inf        ? {signSrc, 11'h7FF, 52'h0}                       : 64'h0)
    | (isZeroIntSrc   ? {signSrc, 63'h0}                                : 64'h0)
    | (sel_normal     ? {signSrc, exp_rounded, frac_rounded}            : 64'h0);

  // ===========================================================================
  // §3 s2 寄存器（fireReg_last_r 使能）：结果与 fflags
  // ===========================================================================
  logic [4:0]  fflags;
  logic [63:0] result;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fflags <= 5'h0;
      result <= 64'h0;
    end else if (fireReg_last_r) begin
      fflags <= {2'b00, overflow, 1'b0, overflow | rnd_inexact};  // {NV,DZ,OF,UF,NX}
      result <= (out_f16 ? 64'(result_f16) : 64'h0)
              | (out_f32 ? 64'(result_f32) : 64'h0)
              | (out_f64 ? result_f64      : 64'h0);
    end
  end

  assign result_out = result;
  assign fflags_out = fflags;

endmodule

module INT2FP(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [2:0]  io_rm,
  input  [3:0]  io_input1H,
  input  [3:0]  io_output1H,
  output [63:0] io_result,
  output [4:0]  io_fflags
);

  xs_INT2FP_core u_core (
    .clock        (clock),
    .reset        (reset),
    .fire         (io_fire),
    .src          (io_src),
    .op_type      (io_opType),
    .rm_in        (io_rm),
    .in_width_1h  (io_input1H),
    .out_width_1h (io_output1H),
    .result_out   (io_result),
    .fflags_out   (io_fflags)
  );

endmodule
