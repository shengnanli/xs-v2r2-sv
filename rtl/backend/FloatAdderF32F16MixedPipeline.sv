// =============================================================================
// FloatAdderF32F16MixedPipeline —— 标量 FPU 的 f32 / f16 浮点加减 + 比较类运算（两拍流水）
//
// 在哪一层：FloatAdder（标量 FAlu 的浮点加法器）里的 F32Adder，hasMinMaxCompare=true。
//   设计源：yunsuan/fpu/FloatAdder.scala class FloatAdderF32F16MixedPipeline。
//   与向量那份 FloatAdderF32WidenF16MixedPipeline 共用 far/close 两条路径，但没有加宽 / 归约，
//   多了 canonical-NaN 输入（NaN-boxing 失败的操作数由上游标出，按 canonical NaN 处理）。
// 端口：fp_format[0]=1 为 f32，否则 f16（f16 操作数在低 16 位）；op_code 见 FaddOpCode
//   （fadd/fsub 走加法器，其余 min/max/比较/符号注入/fclass/fminm/fmaxm 在第 0 拍直接算完打拍）。
//
// 第 0 拍：
//   §1 f16 铺成 f32 布局（{s, 3'b0, e5, m10, 13'b0}）后送 far / close 两条路径（各自两拍）。
//   §2 操作数分类：零 / 无穷 / NaN / sNaN；并决定走 far 还是 close。
//   §3 特殊情况：NaN、无穷、零参与时加法结果不来自路径，第 0 拍记下选哪个、并备好候选值。
//   §4 比较类（hasMinMaxCompare）：b 与 a 的大小关系用 far 的"Eb 大"和 close 的 CS1 借位判定，
//      结果与 NV 标志第 0 拍算完打拍。
// 第 1 拍：
//   §5 加法结果：特殊情况优先，否则按 is_far_path 选 far / close 的结果，f16 时收回 16 位。
//   §6 输出：fadd/fsub 选加法器结果，否则选第 0 拍打好的比较类结果。
// 怪癖（照 golden）：
//   - "指数为零"对 f16 还多认一个 0x66（Scala 源里的常量，照抄）：本铺位法下 f16 指数的高 3 位恒 0，
//     永远等不到 0x66，这一项是死逻辑。
//   - b 为零时结果取第 0 拍原样打拍的整个 io_fp_a（f16 时连高 16 位一起），不清高位。
//   - fadd0_result0 打两份（1 位给 f32、17 位全复制给 f16）；fadd0_result1 两份（f32 / f16 拼法）；
//     "是不是加减"打两份（选结果 / 选标志）；全部照抄，不合并。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：FarPathF32WidenF16MixedPipeline（U_far_path）、
//   ClosePathF32WidenF16MixedPipeline（U_close_path）。
// golden 对照：G1-canonical/golden-rtl/FloatAdderF32F16MixedPipeline.sv
// =============================================================================
module xs_FloatAdderF32F16MixedPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [31:0] fp_a,
  input  logic [31:0] fp_b,
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  input  logic [1:0]  fp_format,
  input  logic [4:0]  op_code,
  input  logic        a_is_canonical_nan,  // a 的 NaN-boxing 失败，当 canonical NaN
  input  logic        b_is_canonical_nan,
  output logic [31:0] fp_c,
  output logic [4:0]  fflags
);
  // FaddOpCode
  localparam logic [4:0] OP_FADD   = 5'b00000;
  localparam logic [4:0] OP_FSUB   = 5'b00001;
  localparam logic [4:0] OP_FMIN   = 5'b00010;
  localparam logic [4:0] OP_FMAX   = 5'b00011;
  localparam logic [4:0] OP_FSGNJ  = 5'b00110;
  localparam logic [4:0] OP_FSGNJN = 5'b00111;
  localparam logic [4:0] OP_FSGNJX = 5'b01000;
  localparam logic [4:0] OP_FEQ    = 5'b01001;
  localparam logic [4:0] OP_FLT    = 5'b01011;
  localparam logic [4:0] OP_FLE    = 5'b01100;
  localparam logic [4:0] OP_FCLASS = 5'b01111;
  localparam logic [4:0] OP_FMAXM  = 5'b10011;
  localparam logic [4:0] OP_FLTQ   = 5'b11011;
  localparam logic [4:0] OP_FLEQ   = 5'b11100;
  localparam logic [4:0] OP_FMINM  = 5'b11110;

  // ---------------------------------------------------------------------------
  // §1 f16 铺成 f32 布局，送两条路径
  // ---------------------------------------------------------------------------
  logic        res_is_f32;
  logic [31:0] a32, b32;               // 铺位后的操作数
  assign res_is_f32 = fp_format[0];
  assign a32 = res_is_f32 ? fp_a : {fp_a[15], 3'b000, fp_a[14:0], 13'h0};
  assign b32 = res_is_f32 ? fp_b : {fp_b[15], 3'b000, fp_b[14:0], 13'h0};

  logic        sign_a, sign_b;
  logic [7:0]  exp_a, exp_b;
  logic [22:0] mant_a, mant_b;
  assign sign_a = a32[31];
  assign sign_b = b32[31];
  assign exp_a  = a32[30:23];
  assign exp_b  = b32[30:23];
  assign mant_a = a32[22:0];
  assign mant_b = b32[22:0];

  logic        eff_sub;                // EOP：有效相减
  assign eff_sub = sign_a ^ is_sub ^ sign_b;

  logic [31:0] far_fp_c, close_fp_c;
  logic [4:0]  far_fflags, close_fflags;
  logic [7:0]  far_abs_exp_diff;       // |Ea - Eb|（far path 第 0 拍算出，组合输出）
  logic        far_exp_b_greater;      // Eb > Ea
  logic [24:0] close_cs1;              // {0,sig_b} - {0,sig_a}，借位 = a 的尾数大
  FarPathF32WidenF16MixedPipeline U_far_path (
    .clock             (clock),
    .io_fire           (fire),
    .io_fp_a           (a32),
    .io_fp_b           (b32),
    .io_fp_c           (far_fp_c),
    .io_is_sub         (is_sub),
    .io_round_mode     (round_mode),
    .io_fflags         (far_fflags),
    .io_absEaSubEb     (far_abs_exp_diff),
    .io_res_is_f32     (res_is_f32),
    .io_isEfp_bGreater (far_exp_b_greater)
  );
  ClosePathF32WidenF16MixedPipeline U_close_path (
    .clock         (clock),
    .io_fire       (fire),
    .io_fp_a       (a32),
    .io_fp_b       (b32),
    .io_fp_c       (close_fp_c),
    .io_round_mode (round_mode),
    .io_fflags     (close_fflags),
    .io_res_is_f32 (res_is_f32),
    .io_CS1        (close_cs1)
  );

  // ---------------------------------------------------------------------------
  // §2 操作数分类 + 路径选择
  // ---------------------------------------------------------------------------
  logic exp_a_is_zero, exp_b_is_zero, exp_a_all_one, exp_b_all_one;
  logic mant_a_nz, mant_b_nz;
  assign exp_a_is_zero = (exp_a == 8'h00) | (~res_is_f32 & exp_a == 8'h66);
  assign exp_b_is_zero = (exp_b == 8'h00) | (~res_is_f32 & exp_b == 8'h66);
  assign exp_a_all_one = res_is_f32 ? (&fp_a[30:23]) : (&fp_a[14:10]);
  assign exp_b_all_one = res_is_f32 ? (&fp_b[30:23]) : (&fp_b[14:10]);
  assign mant_a_nz     = |mant_a;
  assign mant_b_nz     = |mant_b;

  logic a_is_nan, a_is_snan, a_is_inf, a_is_zero;
  logic b_is_nan, b_is_snan, b_is_inf, b_is_zero;
  assign a_is_nan  = a_is_canonical_nan | (exp_a_all_one & mant_a_nz);
  assign a_is_snan = ~a_is_canonical_nan & exp_a_all_one & mant_a_nz & ~mant_a[22];
  assign a_is_inf  = ~a_is_canonical_nan & exp_a_all_one & ~mant_a_nz;
  assign a_is_zero = ~a_is_canonical_nan & exp_a_is_zero & ~mant_a_nz;
  assign b_is_nan  = b_is_canonical_nan | (exp_b_all_one & mant_b_nz);
  assign b_is_snan = ~b_is_canonical_nan & exp_b_all_one & mant_b_nz & ~mant_b[22];
  assign b_is_inf  = ~b_is_canonical_nan & exp_b_all_one & ~mant_b_nz;
  assign b_is_zero = ~b_is_canonical_nan & exp_b_is_zero & ~mant_b_nz;

  logic any_snan, any_nan, inf_minus_inf;
  assign any_snan      = a_is_snan | b_is_snan;
  assign any_nan       = a_is_nan | b_is_nan;
  assign inf_minus_inf = eff_sub & a_is_inf & b_is_inf;

  // 走 far path：有效相加、或指数差 >= 2、或指数差恰为 1 而其中一个指数为 0（照 Scala 原样）
  logic is_far_path;
  assign is_far_path = ~eff_sub | (eff_sub & (|far_abs_exp_diff[7:1]))
                     | ((far_abs_exp_diff == 8'd1) & (exp_a_is_zero ^ exp_b_is_zero));

  // ---------------------------------------------------------------------------
  // §3 加法的特殊情况（第 0 拍判定、第 1 拍选）
  // ---------------------------------------------------------------------------
  logic zero_sum_negative;             // 两数和为 0 的符号：RDN 下相减得 -0，或同号负数相加
  assign zero_sum_negative = (round_mode == 3'd2 & eff_sub) | (sign_a & ~eff_sub);

  // ---------------------------------------------------------------------------
  // §4 比较类运算（第 0 拍算完）
  // ---------------------------------------------------------------------------
  logic is_min, is_max, is_feq, is_flt, is_fle, is_fminm, is_fmaxm, is_fleq, is_fltq, is_add_sub;
  assign is_min     = op_code == OP_FMIN;
  assign is_max     = op_code == OP_FMAX;
  assign is_feq     = op_code == OP_FEQ;
  assign is_flt     = op_code == OP_FLT;
  assign is_fle     = op_code == OP_FLE;
  assign is_fminm   = op_code == OP_FMINM;
  assign is_fmaxm   = op_code == OP_FMAXM;
  assign is_fleq    = op_code == OP_FLEQ;
  assign is_fltq    = op_code == OP_FLTQ;
  assign is_add_sub = (op_code == OP_FADD) | (op_code == OP_FSUB);

  // b 与 a 的大小：先比符号，再比指数（far path 的 Eb > Ea），再比尾数（close path CS1 无借位且不等）
  logic exp_equal, mant_b_greater, mant_equal, both_zero;
  logic b_greater, b_equal, b_less;
  assign exp_equal      = exp_a == exp_b;
  assign mant_b_greater = ~close_cs1[24] & (mant_a != mant_b);
  assign mant_equal     = mant_a == mant_b;
  assign both_zero      = b_is_zero & a_is_zero;
  assign b_greater = (~sign_b & ((sign_a & ~both_zero) | far_exp_b_greater | (exp_equal & mant_b_greater)))
                   | (sign_b & sign_a & ((~far_exp_b_greater & ~exp_equal)
                                         | (exp_equal & ~mant_b_greater & ~mant_equal)));
  assign b_equal   = ((sign_a == sign_b) & exp_equal & mant_equal) | both_zero;
  assign b_less    = ~b_greater & ~b_equal;

  // canonical NaN 的输入当成标准 qNaN 参与 min/max/符号注入
  logic [31:0] quiet_nan;              // 本格式的 canonical NaN（f16 在低 16 位）
  logic [31:0] a_fix, b_fix;
  logic [31:0] a_native, b_native;     // 本格式原样（f16 时高 16 位清 0）
  assign quiet_nan = res_is_f32 ? 32'h7FC0_0000 : 32'h0000_7E00;
  assign a_fix     = a_is_canonical_nan ? quiet_nan : fp_a;
  assign b_fix     = b_is_canonical_nan ? quiet_nan : fp_b;
  assign a_native  = res_is_f32 ? a_fix : {16'h0, a_fix[15:0]};
  assign b_native  = res_is_f32 ? b_fix : {16'h0, b_fix[15:0]};

  // min/max：两个都不是 NaN 时比大小（±0 时 min 取 -0、max 取 +0）；只有一个 NaN 取另一个；都是 NaN 给 qNaN
  logic [31:0] pick_min, pick_max, result_min, result_max;
  assign pick_min = (b_less | (sign_b & both_zero)) ? b_native : a_native;
  assign pick_max = (b_greater | (~sign_b & both_zero)) ? b_native : a_native;
  assign result_min = ({32{~a_is_nan & ~b_is_nan}} & pick_min)
                    | ({32{~a_is_nan &  b_is_nan}} & a_native)
                    | ({32{ a_is_nan & ~b_is_nan}} & b_native)
                    | ({32{ a_is_nan &  b_is_nan}} & quiet_nan);
  assign result_max = ({32{~a_is_nan & ~b_is_nan}} & pick_max)
                    | ({32{~a_is_nan &  b_is_nan}} & a_native)
                    | ({32{ a_is_nan & ~b_is_nan}} & b_native)
                    | ({32{ a_is_nan &  b_is_nan}} & quiet_nan);
  // fminm/fmaxm：任一 NaN 即给 qNaN
  logic [31:0] result_fminm, result_fmaxm;
  assign result_fminm = any_nan ? quiet_nan : pick_min;
  assign result_fmaxm = any_nan ? quiet_nan : pick_max;

  logic result_feq, result_flt, result_fle;
  assign result_feq = ~any_nan & b_equal;
  assign result_flt = ~any_nan & b_greater;
  assign result_fle = ~any_nan & (b_greater | b_equal);

  logic [31:0] result_fsgnj, result_fsgnjn, result_fsgnjx;
  assign result_fsgnj  = res_is_f32 ? {b_fix[31], a_fix[30:0]}
                                    : {16'h0, b_fix[15], a_fix[14:0]};
  assign result_fsgnjn = res_is_f32 ? {~b_fix[31], a_fix[30:0]}
                                    : {16'h0, ~b_fix[15], a_fix[14:0]};
  assign result_fsgnjx = res_is_f32 ? {b_fix[31] ^ a_fix[31], a_fix[30:0]}
                                    : {16'h0, b_fix[15] ^ a_fix[15], a_fix[14:0]};

  // fclass（10 位独热，bit0 = -inf … bit9 = qNaN）
  logic [9:0] result_fclass;
  assign result_fclass = a_is_canonical_nan ? 10'h200 : {
    a_is_nan & ~a_is_snan,                              // 9 qNaN
    a_is_snan,                                          // 8 sNaN
    ~sign_a & a_is_inf,                                 // 7 +inf
    ~sign_a & ~exp_a_is_zero & ~exp_a_all_one,          // 6 +normal
    ~sign_a & exp_a_is_zero & mant_a_nz,                // 5 +subnormal
    ~sign_a & exp_a_is_zero & ~mant_a_nz,               // 4 +0
    sign_a & exp_a_is_zero & ~mant_a_nz,                // 3 -0
    sign_a & exp_a_is_zero & mant_a_nz,                 // 2 -subnormal
    sign_a & ~exp_a_is_zero & ~exp_a_all_one,           // 1 -normal
    sign_a & a_is_inf                                   // 0 -inf
  };

  logic [31:0] result_stage0;          // 比较类结果（op_code 独热，Mux1H = 按位或）
  assign result_stage0 = ({32{is_min}}                      & result_min)
                       | ({32{is_max}}                      & result_max)
                       | ({32{is_feq}}                      & {31'h0, result_feq})
                       | ({32{is_flt | is_fltq}}            & {31'h0, result_flt})
                       | ({32{is_fle | is_fleq}}            & {31'h0, result_fle})
                       | ({32{op_code == OP_FSGNJ}}         & result_fsgnj)
                       | ({32{op_code == OP_FSGNJN}}        & result_fsgnjn)
                       | ({32{op_code == OP_FSGNJX}}        & result_fsgnjx)
                       | ({32{op_code == OP_FCLASS}}        & {22'h0, result_fclass})
                       | ({32{is_fminm}}                    & result_fminm)
                       | ({32{is_fmaxm}}                    & result_fmaxm);

  logic nv_stage0;                     // 比较类的无效操作：flt/fle 遇任何 NaN，其余遇 sNaN
  assign nv_stage0 = ((is_min | is_max) & any_snan)
                   | (is_feq & any_snan)
                   | ((is_flt | is_fle) & any_nan)
                   | ((is_fminm | is_fmaxm) & any_snan)
                   | ((is_fltq | is_fleq) & any_snan);

  // ---------------------------------------------------------------------------
  // 第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic        far_path_q;
  logic        flag_invalid_q;         // sNaN 参与或 inf - inf：fflags = NV
  logic        flag_special_q;         // NaN / 无穷 / 零参与：fflags = 0
  logic        res_is_f32_q;
  logic        zero_sign_f32_q;        // 两零相加的符号（f32 用）
  logic [16:0] zero_sign_f16_q;        // 同上复制 17 份（f16 用，连同高 16 位）
  logic [31:0] b_signed_f32_q;         // a 为零：结果 = ±b（f32 拼法）
  logic [31:0] b_signed_f16_q;         // 同上（f16 拼法，高 16 位 0）
  logic        inf_sign_q;
  logic        res_nan_q;
  logic        res_inf_q;
  logic        res_both_zero_q;
  logic        res_a_zero_q;
  logic        res_b_zero_q;
  logic [31:0] fp_a_q;                 // b 为零：结果 = a（整个 32 位原样）
  logic        sel_adder_result_q;     // fadd/fsub：fp_c 取加法器结果
  logic [31:0] result_stage0_q;
  logic        sel_adder_fflags_q;     // fadd/fsub：fflags 取加法器标志（与上同源）
  logic [4:0]  fflags_stage0_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      far_path_q         <= is_far_path;
      flag_invalid_q     <= any_snan | inf_minus_inf;
      flag_special_q     <= a_is_nan | b_is_nan | a_is_inf | b_is_inf | b_is_zero | a_is_zero;
      res_is_f32_q       <= res_is_f32;
      zero_sign_f32_q    <= zero_sum_negative;
      zero_sign_f16_q    <= {17{zero_sum_negative}};
      b_signed_f32_q     <= {is_sub ^ fp_b[31], fp_b[30:0]};
      b_signed_f16_q     <= {16'h0, is_sub ^ fp_b[15], fp_b[14:0]};
      inf_sign_q         <= a_is_inf ? sign_a : (is_sub ^ sign_b);
      res_nan_q          <= any_nan | inf_minus_inf;
      res_inf_q          <= a_is_inf | b_is_inf;
      res_both_zero_q    <= a_is_zero & b_is_zero;
      res_a_zero_q       <= a_is_zero;
      res_b_zero_q       <= b_is_zero;
      fp_a_q             <= fp_a;
      sel_adder_result_q <= is_add_sub;
      result_stage0_q    <= result_stage0;
      sel_adder_fflags_q <= is_add_sub;
      fflags_stage0_q    <= {nv_stage0, 4'b0000};
    end
  end

  // ---------------------------------------------------------------------------
  // §5 第 1 拍：加法结果
  // ---------------------------------------------------------------------------
  logic [31:0] path_result;            // far / close 选一（f32 布局）
  logic [31:0] path_result_native;     // 收回本格式
  logic [31:0] adder_result;
  logic [4:0]  adder_fflags;
  assign path_result        = far_path_q ? far_fp_c : close_fp_c;
  assign path_result_native = res_is_f32_q ? path_result
                                           : {16'h0, path_result[31], path_result[27:13]};
  always_comb begin
    if (res_nan_q)
      adder_result = res_is_f32_q ? 32'h7FC0_0000 : 32'h0000_7E00;
    else if (res_inf_q)
      adder_result = res_is_f32_q ? {inf_sign_q, 31'h7F80_0000} : {16'h0, inf_sign_q, 15'h7C00};
    else if (res_both_zero_q)
      adder_result = res_is_f32_q ? {zero_sign_f32_q, 31'h0} : {zero_sign_f16_q, 15'h0};
    else if (res_a_zero_q)
      adder_result = res_is_f32_q ? b_signed_f32_q : b_signed_f16_q;
    else if (res_b_zero_q)
      adder_result = fp_a_q;
    else
      adder_result = path_result_native;
  end

  always_comb begin
    if (flag_invalid_q)      adder_fflags = 5'b10000;
    else if (flag_special_q) adder_fflags = 5'b00000;
    else                     adder_fflags = far_path_q ? far_fflags : close_fflags;
  end

  // ---------------------------------------------------------------------------
  // §6 输出
  // ---------------------------------------------------------------------------
  assign fp_c   = sel_adder_result_q ? adder_result : result_stage0_q;
  assign fflags = sel_adder_fflags_q ? adder_fflags : fflags_stage0_q;
endmodule

module FloatAdderF32F16MixedPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [31:0] io_fp_a,
  input  logic [31:0] io_fp_b,
  output logic [31:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic [1:0]  io_fp_format,
  input  logic [4:0]  io_op_code,
  input  logic        io_fp_aIsFpCanonicalNAN,
  input  logic        io_fp_bIsFpCanonicalNAN
);
  xs_FloatAdderF32F16MixedPipeline_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .is_sub             (io_is_sub),
    .round_mode         (io_round_mode),
    .fp_format          (io_fp_format),
    .op_code            (io_op_code),
    .a_is_canonical_nan (io_fp_aIsFpCanonicalNAN),
    .b_is_canonical_nan (io_fp_bIsFpCanonicalNAN),
    .fp_c               (io_fp_c),
    .fflags             (io_fflags)
  );
endmodule
