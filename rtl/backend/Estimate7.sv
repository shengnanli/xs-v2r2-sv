// Estimate7.sv —— 向量转换 64 位通道里的倒数/平方根倒数 7 位估算子单元（vfrec7 / vfrsqrt7，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：CVT64_1 的三个并行子单元之一（另两个 FP_INCVT / INT2FP），CVT64_1 在第 2 拍末按
//   操作类型三选一。输入 src 低位放一个 f16/f32/f64（input1H 独热 [1]/[2]/[3]），输出同格式
//   （output1H）。opType[5]=估算类，opType[0]=1 为 vfrec7（倒数），0 为 vfrsqrt7（平方根倒数）。
// 机制（Scala: yunsuan/vector/VectorConvert/CVT64.scala class Estimate7；算法即 RVV 规范附录）：
//   第 0 拍：把三种格式统一摆成「f64 形状」（符号/11 位指数/52 位尾数，窄格式的指数只占低位、
//     尾数左对齐）；分类（零/非规格化/无穷/NaN/sNaN/qNaN，以及 rec7 才用到的几个边界档）；
//     非规格化数用 CLZ 求规格化左移量；指数加法器的两个加数提前备好：
//       rec7  ：out_exp = 2*bias - 1 - e
//       rsqrt7：out_exp = (3*bias - 1 - e) / 2   （除 2 在第 1 拍取 exp[E:1] 实现）
//     其中 e 对非规格化数是「-前导零」（加数直接给 +前导零）。
//   第 1 拍：非规格化尾数左移规格化 -> 取尾数高 7 位（rsqrt 取指数最低位 + 尾数高 6 位）查表
//     （Rec7Table / Rsqrt7Table，128 项 7 位）-> 按分类 Mux1H 出结果与 fflags，落 s2 寄存器。
// rec7 的几个特殊档（照规范）：
//   - NaN -> 规范 NaN；±Inf -> ±0；±0 -> ±Inf 且 DZ；
//   - 非规格化且尾数最高两位为 00（isSubnormalRec2）：结果上溢 —— OF|NX，按舍入方向给
//     ±Inf 或 ±最大有限数；
//   - 指数为 max-1 / max-2（isNormalRec0/1）与尾数最高位为 1/01 的非规格化：结果是非规格化，
//     表值前面补 1 再右移 1 或 2 位（这里直接按档位拼常数）；其余：正常指数 + 表值。
// rsqrt7：负数（非 -0）或 NaN -> 规范 NaN（负数/ sNaN 置 NV）；±0 -> ±Inf 且 DZ；+Inf -> +0。
// 怪癖（照 golden）：
//   - Mux1H 一律「与门后按位或」；output1H 多热时多格式结果或在一起；
//   - 指数加法器 13 位，但结果只用到 [11:0]（golden 同样不读两个加数寄存器的第 12 位）；
//   - fracSrcLeft 低 12 位恒 0（左移补的 0），仍按 golden 存满 64 位并带复位。
// 子模块：CLZ_6（重写件，已签核）；Rec7Table / Rsqrt7Table（另一条 lane 认领，本 lane 用 golden）。
// golden 对照：G1-canonical/golden-rtl/Estimate7.sv
// =============================================================================

module xs_Estimate7_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [63:0] src,           // f16/f32/f64 源（低位对齐）
  input  logic [7:0]  op_type,       // [5]=估算类 [0]=1:rec7 0:rsqrt7
  input  logic [2:0]  rm_in,
  input  logic [3:0]  in_width_1h,   // [1]=f16 [2]=f32 [3]=f64
  input  logic [3:0]  out_width_1h,  // 同上（结果格式）
  output logic [63:0] result_out,
  output logic [4:0]  fflags_out     // {NV, DZ, OF, UF, NX}
);

  // ===========================================================================
  // §0 第 0 拍：统一成 f64 形状并分类
  // ===========================================================================
  // fp64 形状：[63]=符号 [62:52]=指数（窄格式只占低 5/8 位）[51:0]=尾数（左对齐）
  logic [63:0] fp_in;
  assign fp_in =
      (in_width_1h[1] ? {src[15], 6'h0, src[14:0], 42'h0} : 64'h0)
    | (in_width_1h[2] ? {src[31], 3'h0, src[30:0], 29'h0} : 64'h0)
    | (in_width_1h[3] ? src                               : 64'h0);

  logic        sign_next;
  logic [10:0] exp_next;
  logic [51:0] frac_next;
  assign sign_next = fp_in[63];
  assign exp_next  = fp_in[62:52];
  assign frac_next = fp_in[51:0];

  logic is_rec_next;
  assign is_rec_next = op_type[5] & op_type[0];

  // 按源格式解码三个基本事实（Mux1H）：指数非 0 / 指数全 1 / 尾数非 0
  logic exp_not_zero, exp_is_ones, frac_not_zero;
  assign exp_not_zero =
      in_width_1h[1] & (|exp_next[4:0]) | in_width_1h[2] & (|exp_next[7:0])
    | in_width_1h[3] & (|exp_next);
  assign exp_is_ones =
      in_width_1h[1] & (&exp_next[4:0]) | in_width_1h[2] & (&exp_next[7:0])
    | in_width_1h[3] & (&exp_next);
  assign frac_not_zero =
      in_width_1h[1] & (|frac_next[51:42]) | in_width_1h[2] & (|frac_next[51:29])
    | in_width_1h[3] & (|frac_next);

  logic is_subnormal_next, is_nan_next;
  assign is_subnormal_next = ~exp_not_zero & frac_not_zero;
  assign is_nan_next       = exp_is_ones & frac_not_zero;

  // rec7 的两个「结果会变非规格化」的指数档：e = max-1（Rec0）/ max-2（Rec1）
  logic is_normal_rec0_next, is_normal_rec1_next;
  assign is_normal_rec0_next =
      in_width_1h[1] & ((&exp_next[4:1])  & ~exp_next[0])
    | in_width_1h[2] & ((&exp_next[7:1])  & ~exp_next[0])
    | in_width_1h[3] & ((&exp_next[10:1]) & ~exp_next[0]);
  assign is_normal_rec1_next =
      in_width_1h[1] & ((&exp_next[4:2])  & ~exp_next[1] & exp_next[0])
    | in_width_1h[2] & ((&exp_next[7:2])  & ~exp_next[1] & exp_next[0])
    | in_width_1h[3] & ((&exp_next[10:2]) & ~exp_next[1] & exp_next[0]);

  // 非规格化：尾数左对齐后数前导零（低 12 位补 0）
  logic [63:0] frac_left_next;
  logic [6:0]  lead_zeros_next;
  assign frac_left_next = {frac_next, 12'h0};

  CLZ_6 leadZerosNext_clz (
    .io_in  (frac_left_next),
    .io_out (lead_zeros_next)
  );

  // 指数加数：常数项（按目标格式与 rec/rsqrt）+ 「-e」项（非规格化时用 +前导零）
  logic [12:0] exp_const_next;
  logic [11:0] minus_exp12;
  logic [12:0] exp_var_next;
  assign exp_const_next =
      (out_width_1h[1] ? (is_rec_next ? 13'd29   : 13'd44)   : 13'h0)   // f16: 2b-1 / 3b-1
    | (out_width_1h[2] ? (is_rec_next ? 13'd253  : 13'd380)  : 13'h0)   // f32
    | (out_width_1h[3] ? (is_rec_next ? 13'd2045 : 13'd3068) : 13'h0);  // f64
  assign minus_exp12  = 12'(~{1'b0, exp_next} + 12'h1);
  assign exp_var_next = is_subnormal_next ? 13'(lead_zeros_next) : {minus_exp12[11], minus_exp12};

  // ===========================================================================
  // §1 s1 寄存器（fire 使能）。分类位、符号、舍入模式带异步复位；
  //    指数加数与前导零不复位（照 golden）。
  // ===========================================================================
  logic        fireReg_last_r;
  logic [2:0]  rm;
  logic        expIsOnesSrc;
  logic        isSubnormalSrc;
  logic        isRec;
  logic        isSNaNSrc;
  logic        signSrc;
  logic        isZeroSrc;
  logic        isQNaNSrc;
  logic        isSubnormalRec2;
  logic        isInfSrc;
  logic        isNaNSrc;
  logic        isNormalRec0;
  logic        isNormalRec1;
  logic        isNormalRec2;
  logic        isSubnormalRec0;
  logic        isSubnormalRec1;
  logic [3:0]  output1HReg;
  logic        expNormaled0;    // rsqrt 查表要的「规格化后指数最低位」
  logic [63:0] fracSrcLeft;
  logic [12:0] expAdderIn0;
  logic [12:0] expAdderIn1;
  logic [6:0]  leadZeros;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r  <= 1'b0;
      rm              <= 3'h0;
      expIsOnesSrc    <= 1'b0;
      isSubnormalSrc  <= 1'b0;
      isRec           <= 1'b0;
      isSNaNSrc       <= 1'b0;
      signSrc         <= 1'b0;
      isZeroSrc       <= 1'b0;
      isQNaNSrc       <= 1'b0;
      isSubnormalRec2 <= 1'b0;
      isInfSrc        <= 1'b0;
      isNaNSrc        <= 1'b0;
      isNormalRec0    <= 1'b0;
      isNormalRec1    <= 1'b0;
      isNormalRec2    <= 1'b0;
      isSubnormalRec0 <= 1'b0;
      isSubnormalRec1 <= 1'b0;
      output1HReg     <= 4'h0;
      expNormaled0    <= 1'b0;
      fracSrcLeft     <= 64'h0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        rm              <= rm_in;
        expIsOnesSrc    <= exp_is_ones;
        isSubnormalSrc  <= is_subnormal_next;
        isRec           <= is_rec_next;
        isSNaNSrc       <= is_nan_next & ~frac_next[51];
        signSrc         <= sign_next;
        isZeroSrc       <= ~exp_not_zero & ~frac_not_zero;
        isQNaNSrc       <= is_nan_next & frac_next[51];
        isSubnormalRec2 <= is_subnormal_next & frac_next[51:50] == 2'b00;
        isInfSrc        <= exp_is_ones & ~frac_not_zero;
        isNaNSrc        <= is_nan_next;
        isNormalRec0    <= is_normal_rec0_next;
        isNormalRec1    <= is_normal_rec1_next;
        isNormalRec2    <= exp_not_zero & ~exp_is_ones & ~is_normal_rec0_next & ~is_normal_rec1_next;
        isSubnormalRec0 <= is_subnormal_next & frac_next[51];
        isSubnormalRec1 <= is_subnormal_next & ~frac_next[51] & frac_next[50];
        output1HReg     <= out_width_1h;
        expNormaled0    <= is_subnormal_next ? lead_zeros_next[0] : exp_next[0];
        fracSrcLeft     <= frac_left_next;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      expAdderIn0 <= exp_const_next;
      expAdderIn1 <= exp_var_next;
      leadZeros   <= lead_zeros_next;
    end
  end

  // ===========================================================================
  // §2 第 1 拍：规格化、查表、按分类出结果
  // ===========================================================================
  logic [11:0] exp;            // 输出指数（rsqrt 取 [E:1] 即除 2）
  logic [63:0] frac_shifted;   // 非规格化尾数左移 (前导零+1)：隐含 1 移出
  logic [63:0] frac_norm;
  logic [6:0]  rec7_out, rsqrt7_out, frac_est;

  assign exp          = 12'(expAdderIn0[11:0] + expAdderIn1[11:0]);
  assign frac_shifted = 64'({fracSrcLeft, 1'b0} << leadZeros);
  assign frac_norm    = isSubnormalSrc ? frac_shifted : fracSrcLeft;

  Rsqrt7Table rsqrt7Table (
    .src ({expNormaled0, frac_norm[63:58]}),
    .out (rsqrt7_out)
  );
  Rec7Table rec7Table (
    .src (frac_norm[63:57]),
    .out (rec7_out)
  );
  assign frac_est = isRec ? rec7_out : rsqrt7_out;

  // rmin：舍入方向朝 0（RTZ，或负数 RUP，或正数 RDN）
  logic rmin;
  assign rmin = rm == 3'h1 | signSrc & rm == 3'h3 | ~signSrc & rm == 3'h2;

  // ---- rec7 结果（7 选 1）----
  logic rec_nan, rec_zero_out, rec_inf_out, rec_sub1, rec_sub2, rec_norm, rec_max_finite;
  assign rec_nan        = isNaNSrc;
  assign rec_zero_out   = isInfSrc;                                    // 1/±Inf = ±0
  assign rec_inf_out    = isZeroSrc | isSubnormalRec2 & ~rmin;         // 1/±0 或上溢
  assign rec_sub1       = isNormalRec0;                                // 结果非规格化，右移 1
  assign rec_sub2       = isNormalRec1;                                // 结果非规格化，右移 2
  assign rec_norm       = isNormalRec2 | isSubnormalRec0 | isSubnormalRec1;
  assign rec_max_finite = isSubnormalRec2 & rmin;

  logic [15:0] rec_f16;
  logic [31:0] rec_f32;
  logic [63:0] rec_f64;
  assign rec_f16 =
      (rec_nan        ? 16'h7E00                                  : 16'h0)
    | (rec_zero_out   ? {signSrc, 15'h0}                          : 16'h0)
    | (rec_inf_out    ? {signSrc, 5'h1F, 10'h0}                   : 16'h0)
    | (rec_sub1       ? {signSrc, 5'h0, 2'b01, frac_est, 1'b0}    : 16'h0)
    | (rec_sub2       ? {signSrc, 5'h0, 1'b1, frac_est, 2'b0}     : 16'h0)
    | (rec_norm       ? {signSrc, exp[4:0], frac_est, 3'h0}       : 16'h0)
    | (rec_max_finite ? {signSrc, 5'h1E, 10'h3FF}                 : 16'h0);
  assign rec_f32 =
      (rec_nan        ? 32'h7FC00000                              : 32'h0)
    | (rec_zero_out   ? {signSrc, 31'h0}                          : 32'h0)
    | (rec_inf_out    ? {signSrc, 8'hFF, 23'h0}                   : 32'h0)
    | (rec_sub1       ? {signSrc, 8'h0, 2'b01, frac_est, 14'h0}   : 32'h0)
    | (rec_sub2       ? {signSrc, 8'h0, 1'b1, frac_est, 15'h0}    : 32'h0)
    | (rec_norm       ? {signSrc, exp[7:0], frac_est, 16'h0}      : 32'h0)
    | (rec_max_finite ? {signSrc, 8'hFE, 23'h7FFFFF}              : 32'h0);
  assign rec_f64 =
      (rec_nan        ? 64'h7FF8000000000000                      : 64'h0)
    | (rec_zero_out   ? {signSrc, 63'h0}                          : 64'h0)
    | (rec_inf_out    ? {signSrc, 11'h7FF, 52'h0}                 : 64'h0)
    | (rec_sub1       ? {signSrc, 11'h0, 2'b01, frac_est, 43'h0}  : 64'h0)
    | (rec_sub2       ? {signSrc, 11'h0, 1'b1, frac_est, 44'h0}   : 64'h0)
    | (rec_norm       ? {signSrc, exp[10:0], frac_est, 45'h0}     : 64'h0)
    | (rec_max_finite ? {signSrc, 11'h7FE, 52'hFFFFFFFFFFFFF}     : 64'h0);

  // ---- rsqrt7 结果（4 选 1，第 4 档「+Inf -> +0」恰好是全 0，不出现在或式里）----
  logic sqrt_nan, sqrt_inf_out, sqrt_norm;
  assign sqrt_nan     = signSrc & ~isZeroSrc | isNaNSrc;
  assign sqrt_inf_out = isZeroSrc;
  assign sqrt_norm    = ~signSrc & ~isZeroSrc & ~expIsOnesSrc;

  logic [15:0] sqrt_f16;
  logic [31:0] sqrt_f32;
  logic [63:0] sqrt_f64;
  assign sqrt_f16 =
      (sqrt_nan     ? 16'h7E00                                : 16'h0)
    | (sqrt_inf_out ? {signSrc, 5'h1F, 10'h0}                 : 16'h0)
    | (sqrt_norm    ? {signSrc, exp[5:1], frac_est, 3'h0}     : 16'h0);
  assign sqrt_f32 =
      (sqrt_nan     ? 32'h7FC00000                            : 32'h0)
    | (sqrt_inf_out ? {signSrc, 8'hFF, 23'h0}                 : 32'h0)
    | (sqrt_norm    ? {signSrc, exp[8:1], frac_est, 16'h0}    : 32'h0);
  assign sqrt_f64 =
      (sqrt_nan     ? 64'h7FF8000000000000                    : 64'h0)
    | (sqrt_inf_out ? {signSrc, 11'h7FF, 52'h0}               : 64'h0)
    | (sqrt_norm    ? {signSrc, exp[11:1], frac_est, 45'h0}   : 64'h0);

  // ---- 按输出格式选（Mux1H）----
  logic [63:0] result_next;
  logic        out_f16, out_f32, out_f64;
  assign out_f16 = output1HReg[1];
  assign out_f32 = output1HReg[2];
  assign out_f64 = output1HReg[3];
  assign result_next = isRec
    ? (out_f16 ? 64'(rec_f16) : 64'h0) | (out_f32 ? 64'(rec_f32) : 64'h0) | (out_f64 ? rec_f64 : 64'h0)
    : (out_f16 ? 64'(sqrt_f16) : 64'h0) | (out_f32 ? 64'(sqrt_f32) : 64'h0) | (out_f64 ? sqrt_f64 : 64'h0);

  // ---- fflags ----
  logic nv, dz, of;
  assign nv = isRec ? isSNaNSrc : (signSrc & ~isZeroSrc & ~isQNaNSrc) | isSNaNSrc;
  assign dz = isZeroSrc;
  assign of = isRec & isSubnormalRec2;

  // ===========================================================================
  // §3 s2 寄存器（fireReg_last_r 使能）
  // ===========================================================================
  logic [4:0]  fflags;
  logic [63:0] result;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fflags <= 5'h0;
      result <= 64'h0;
    end else if (fireReg_last_r) begin
      fflags <= {nv, dz, of, 1'b0, of};     // {NV,DZ,OF,UF,NX}：上溢必不精确
      result <= result_next;
    end
  end

  assign result_out = result;
  assign fflags_out = fflags;

endmodule

module Estimate7(
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

  xs_Estimate7_core u_core (
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
