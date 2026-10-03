// CVT16.sv —— 向量浮点转换 16 位通道的转换器（yunsuan CVT16，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvt 的第 2、3 条通道（经 VCVT_2 壳）。只处理元素不超过 16 位的操作，
//   自己按 {opType, sew} 译码（其余组合本通道输出 0）：
//     f2i   ：f16 -> i16（sew=16 单宽）、f16 -> i8（sew=8 变窄）
//     i2f   ：i16 -> f16（sew=16 单宽）、i8 -> f16（sew=8 变宽）
//     vfr   ：f16 的 vfrec7 / vfrsqrt7（sew=16）
//   opType 位段（yunsuan VfcvtType）：[7:6]=10 f2i / 01 i2f，[5]=估算类，[4:3]=00 单宽 01 变宽
//   10 变窄，[0]=有符号（f2i/i2f）或 rec7（估算类）。
// 流水（Scala 文件头原话的拆法）：
//   第 0 拍：f2i —— 拆成 RawFloat（隐含位显式化、非规格化指数记 1），按指数分左路（指数够大，
//              尾数左移就是整数，可能上溢）/ 右路（尾数右移 + ShiftRightJam 求 sticky，需舍入）；
//            i2f —— 符号扩展、取绝对值、CLZ 规格化左移、算指数；
//            vfr —— 分类（零/非规格化/Inf/NaN 及 rec7 的几个边界档）、非规格化规格化、算输出指数；
//            三类共用一个 RoundingUnit（11 位），其输入在本拍就选好并落寄存器。
//   第 1 拍：舍入（+1/进位）、上溢/无效判定、取负（有符号负数）、vfr 查 7 位表；
//            按十类结果 Mux1H 出 result/fflags，落 s2 寄存器。
//   第 2 拍：输出寄存器。
// 怪癖（照 golden，均为 Scala 原样）：
//   - 所有多路选择是 Mux1H（与门后按位或），非法 opType/sew 组合下各路照样或在一起；
//   - fflags 中间寄存器 fflags0_reg1 是 16 位：Scala 把 rec7(-Inf) 那一档的 fflags 写成了与结果
//     相同的 Cat(1, 0(15))，Mux1H 于是被拉宽到 16 位。输出只取 [4:0]，第 15 位存了也没人读；
//   - out_sign 恒 0（is_poszero_posinf 已含 !sign），golden 仍保留这个寄存器，照搬；
//   - 求 CLZ(sig) 的两个实例输入相同（Scala 调了两次），照搬两份。
// 子模块：CLZ_7 / CLZ_28×2 / CLZ_30、ShiftRightJam_4、RoundingUnit_11（均为已签核重写件）；
//   Rec7Table / Rsqrt7Table（另一条 lane 认领，本 lane 两侧用 golden）。
// golden 对照：G1-canonical/golden-rtl/CVT16.sv
// =============================================================================

module xs_CVT16_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [15:0] src,
  input  logic [7:0]  op_type,
  input  logic [1:0]  sew,
  input  logic [2:0]  rm_in,
  output logic [15:0] result_out,
  output logic [4:0]  fflags_out
);

  // ===========================================================================
  // §0 控制译码（第 0 拍）
  // ===========================================================================
  logic is_sew_8, is_sew_16;
  logic is_single, is_widen, is_narrow;
  logic is_vfr, is_fp2int, is_int2fp, is_vfrsqrt7, is_vfrec7, is_signed_int;

  assign is_sew_8      = sew == 2'b00;
  assign is_sew_16     = sew == 2'b01;
  assign is_single     = op_type[4:3] == 2'b00;
  assign is_widen      = op_type[4:3] == 2'b01;
  assign is_narrow     = op_type[4:3] == 2'b10;
  assign is_vfr        = op_type[5] & is_sew_16;
  assign is_fp2int     = op_type[7:6] == 2'b10 & (is_sew_16 & is_single | is_sew_8 & is_narrow);
  assign is_int2fp     = op_type[7:6] == 2'b01 & (is_sew_8 & is_widen | is_sew_16 & is_single);
  assign is_vfrsqrt7   = is_vfr & ~op_type[0];
  assign is_vfrec7     = is_vfr & op_type[0];
  assign is_signed_int = op_type[0];

  // 两条整数通路（f2i 的目的宽 / i2f 的源宽）
  logic f2i_to_16, f2i_to_8, i2f_from_8, i2f_from_16;
  assign f2i_to_16   = is_fp2int & is_single;    // f16 -> i16
  assign f2i_to_8    = is_fp2int & is_narrow;    // f16 -> i8
  assign i2f_from_8  = is_int2fp & is_widen;     // i8  -> f16
  assign i2f_from_16 = is_int2fp & is_single;    // i16 -> f16

  // ===========================================================================
  // §1 第 0 拍：源拆解
  // ===========================================================================
  // i2f：按源宽符号/零扩展到 17 位
  logic [16:0] in_sext;
  assign in_sext =
      (is_int2fp & ~is_signed_int & is_widen  ? {9'h0, src[7:0]}       : 17'h0)
    | (is_int2fp & is_signed_int & is_widen   ? {{9{src[7]}}, src[7:0]} : 17'h0)
    | (is_int2fp & ~is_signed_int & is_single ? {1'b0, src}            : 17'h0)
    | (is_int2fp & is_signed_int & is_single  ? {src[15], src}         : 17'h0);

  // f2i：RawFloat = {符号, 指数(非规格化记 1), 隐含位, 10 位尾数}
  logic        src_exp_not_zero;
  logic [16:0] fp2int_in;
  assign src_exp_not_zero = |src[14:10];
  assign fp2int_in = {src[15], src[14:10] | {4'h0, ~src_exp_not_zero}, src_exp_not_zero, src[9:0]};

  // 三类共用的 17 位「源」：f2i 放 RawFloat，i2f 放扩展整数，vfr 放原样 f16
  logic [16:0] in;
  assign in = (is_fp2int ? fp2int_in    : 17'h0)
            | (is_int2fp ? in_sext      : 17'h0)
            | (is_vfr    ? {1'b0, src}  : 17'h0);

  logic        sign;
  logic [4:0]  exp;
  logic [10:0] sig;       // f2i 含隐含位（11 位）；vfr 只有 10 位尾数
  assign sign = (is_fp2int | is_int2fp) & in[16] | is_vfr & in[15];
  assign exp  = (is_fp2int ? in[15:11] : 5'h0) | (is_vfr ? in[14:10] : 5'h0);
  assign sig  = (is_fp2int ? in[10:0]  : 11'h0) | (is_vfr ? {1'b0, in[9:0]} : 11'h0);

  logic sig_frac_nz;       // 10 位尾数非 0
  assign sig_frac_nz = |sig[9:0];

  // ===========================================================================
  // §2 第 0 拍：f2i（左路 / 右路）
  // ===========================================================================
  // 能表示的最大指数：i16 为 bias+15 = 30，i8 为 bias+7 = 22；更大必上溢
  logic [4:0] max_int_exp;
  logic       exp_of;
  assign max_int_exp = (f2i_to_16 ? 5'd30 : 5'h0) | (f2i_to_8 ? 5'd22 : 5'h0);
  assign exp_of      = is_fp2int & (exp > max_int_exp);

  // 左路（exp >= 25 = bias+10：尾数整体左移 exp-25 位即整数，不需舍入）—— 只有 i16 目的会走到
  logic [4:0]  lpath_shamt;
  logic [41:0] lpath_shifted_full;
  logic [15:0] lpath_sig_shifted;
  logic        lpath_iv, lpath_of;
  assign lpath_shamt        = f2i_to_16 ? 5'(exp - 5'd25) : 5'h0;
  assign lpath_shifted_full = {31'h0, sig} << lpath_shamt;
  assign lpath_sig_shifted  = f2i_to_16 ? lpath_shifted_full[15:0] : 16'h0;
  assign lpath_iv = f2i_to_16 & ~is_signed_int & sign;                  // 无符号目的遇负数
  assign lpath_of = f2i_to_16 & is_signed_int & (exp == max_int_exp)    // 有符号恰在边界：
                  & (~sign | sign & (|in[9:0]));                        //   只有 -2^15 合法

  // 右路：尾数右移 (25-exp)/(22-exp) 位，ShiftRightJam 收 sticky
  logic [4:0]  rpath_shamt;
  logic [11:0] rpath_sig_shifted;
  logic        rpath_sticky;
  assign rpath_shamt = (f2i_to_16 ? 5'(5'd25 - exp) : 5'h0) | (f2i_to_8 ? 5'(5'd22 - exp) : 5'h0);

  ShiftRightJam_4 shiftRightJam (
    .io_in     ({sig, 1'b0}),
    .io_shamt  (rpath_shamt),
    .io_out    (rpath_sig_shifted),
    .io_sticky (rpath_sticky)
  );

  logic sel_lpath;
  assign sel_lpath = exp >= 5'd25;

  // 上溢 / NaN 时的饱和值：NaN 或正数取最大，负数取最小
  logic [15:0] max_int, min_int, max_min_int;
  assign max_int = (f2i_to_16 ? {~is_signed_int, 15'h7FFF} : 16'h0)
                 | (f2i_to_8  ? {8'h0, ~is_signed_int, 7'h7F} : 16'h0);
  assign min_int = (f2i_to_16 ? {is_signed_int, 15'h0} : 16'h0)
                 | (f2i_to_8  ? {8'h0, is_signed_int, 7'h0} : 16'h0);
  assign max_min_int = ((&exp) & sig_frac_nz | ~sign) ? max_int : min_int;

  // ===========================================================================
  // §3 第 0 拍：i2f（绝对值 -> CLZ -> 左移规格化）
  // ===========================================================================
  logic [16:0] in_abs;
  logic [4:0]  int2fp_clz_raw, int2fp_clz;
  logic [47:0] in_shift_full;
  logic [14:0] in_shift;          // 规格化后隐含位已移出，剩下 15 位尾数候选
  logic [4:0]  exp_raw;
  assign in_abs = (is_int2fp & sign  ? 17'(~in + 17'h1) : 17'h0)
                | (is_int2fp & ~sign ? in               : 17'h0);

  CLZ_7 int2fp_clz_clz (
    .io_in  (in_abs[15:0]),
    .io_out (int2fp_clz_raw)
  );

  assign int2fp_clz    = is_int2fp ? int2fp_clz_raw : 5'h0;
  assign in_shift_full = {31'h0, in_abs} << int2fp_clz;
  assign in_shift      = is_int2fp ? in_shift_full[14:0] : 15'h0;
  assign exp_raw       = is_int2fp ? 5'(5'd30 - int2fp_clz) : 5'h0;   // bias(15) + 15 - clz

  // ===========================================================================
  // §4 第 0 拍：共用舍入器的输入（f2i 右路 / i2f 两种宽度）
  // ===========================================================================
  logic [10:0] round_in;
  logic        round_roundIn, round_stickyIn;
  assign round_in =
      (f2i_to_16   ? rpath_sig_shifted[11:1]       : 11'h0)
    | (f2i_to_8    ? 11'(rpath_sig_shifted[11:4])  : 11'h0)
    | (i2f_from_8  ? 11'(in_shift[14:7])           : 11'h0)
    | (i2f_from_16 ? 11'(in_shift[14:5])           : 11'h0);
  assign round_roundIn =
      f2i_to_16 & rpath_sig_shifted[0] | f2i_to_8 & rpath_sig_shifted[3]
    | i2f_from_8 & in_shift[6] | i2f_from_16 & in_shift[4];
  assign round_stickyIn =
      f2i_to_16 & rpath_sticky
    | f2i_to_8 & (rpath_sticky | (|rpath_sig_shifted[2:0]))
    | i2f_from_8 & (|in_shift[5:0])
    | i2f_from_16 & (|in_shift[3:0]);

  // ===========================================================================
  // §5 第 0 拍：vfr（vfrec7 / vfrsqrt7）的分类与规格化
  // ===========================================================================
  logic is_normal, is_subnormal, is_inf, is_nan;
  logic is_poszero_posinf;
  assign is_normal         = (|exp) & ~(&exp);
  assign is_subnormal      = ~(|exp);
  assign is_inf            = (&exp) & ~sig_frac_nz;
  assign is_nan            = (&exp) & sig_frac_nz;
  assign is_poszero_posinf = ~sign & (is_normal | is_subnormal & sig_frac_nz);  // 正的非零有限数

  // 非规格化：规格化后的指数 = 0 - CLZ(尾数)
  logic [3:0] sig_lzc_a, sig_lzc_b;
  logic [3:0] zero_minus_lzc;
  CLZ_28 zero_minus_lzc_clz (
    .io_in  (sig[9:0]),
    .io_out (sig_lzc_a)
  );
  assign zero_minus_lzc = is_vfr ? 4'(4'h0 - sig_lzc_a) : 4'h0;

  logic use_norm, use_sub;      // 规格化数直接用 / 非规格化先规格化
  assign use_norm = is_vfrsqrt7 & is_poszero_posinf & is_normal    | is_vfrec7 & is_normal;
  assign use_sub  = is_vfrsqrt7 & is_poszero_posinf & is_subnormal | is_vfrec7 & is_subnormal;

  logic [4:0]  exp_normalized;
  logic [10:0] sig_normalized;
  assign exp_normalized = (use_norm ? exp : 5'h0)
                        | (use_sub  ? {zero_minus_lzc[3], zero_minus_lzc} : 5'h0);
  assign sig_normalized = (use_norm ? {1'b0, sig[9:0]} : 11'h0)
                        | (use_sub  ? {sig[9:0], 1'b0} : 11'h0);

  logic [3:0] clz_sig;
  CLZ_30 clz_sig_clz (
    .io_in  (sig_normalized),
    .io_out (clz_sig)
  );

  // rec7 的输出指数 = 2*bias - 1 - e = 29 - e；为 0 或 -1（全 1）时结果非规格化
  logic [4:0] out_exp_normalized;
  logic       out_exp_zero_negone;
  assign out_exp_normalized  = is_vfrec7 ? 5'(5'd29 - exp_normalized) : 5'h0;
  assign out_exp_zero_negone = is_vfrec7 & out_exp_normalized == 5'h0 | (&out_exp_normalized);

  // rsqrt7 的输出指数 = (3*bias - 1 - e) / 2 = (44 - e) >> 1；非规格化 e = -clz
  logic [5:0] rsqrt_exp_norm, rsqrt_exp_sub;
  assign rsqrt_exp_norm = 6'(6'd44 - {1'b0, exp});
  CLZ_28 out_exp_clz (
    .io_in  (sig[9:0]),
    .io_out (sig_lzc_b)
  );
  assign rsqrt_exp_sub = 6'(6'd44 + {2'b00, sig_lzc_b});

  logic [4:0] out_exp;
  assign out_exp =
      (is_vfrsqrt7 & is_normal                ? rsqrt_exp_norm[5:1] : 5'h0)
    | (is_vfrsqrt7 & is_subnormal             ? rsqrt_exp_sub[5:1]  : 5'h0)
    | (is_vfrec7 & ~out_exp_zero_negone       ? out_exp_normalized  : 5'h0);   // zero_negone 档给 0

  // ===========================================================================
  // §6 s1 寄存器（fire 使能）
  // ===========================================================================
  logic        fireReg_last_r;
  logic        is_single_reg0, is_widen_reg0, is_narrow_reg0;
  logic        is_vfr_reg0, is_fp2int_reg0, is_int2fp_reg0;
  logic        is_vfrsqrt7_reg0, is_vfrec7_reg0, is_signed_int_reg0;
  logic [10:0] round_in_reg0;
  logic        round_roundIn_reg0, round_stickyIn_reg0, round_signIn_reg0;
  logic [2:0]  rm_reg0;
  logic        is_normal_reg0, is_inf_reg0, is_nan_reg0, is_neginf_reg0;
  logic        is_neginf_negzero_reg0, is_negzero_reg0, is_poszero_reg0, is_snan_reg0;
  logic        is_neg2_bplus1_b_reg0, is_neg2_b_bminus1_reg0, is_neg2_negbminus1_negzero_reg0;
  logic        is_pos2_poszero_negbminus1_reg0, is_pos2_bminus1_b_reg0, is_pos2_b_bplus1_reg0;
  logic        in_orR_reg0;
  logic [16:0] in_reg0;
  logic        sign_reg0;
  logic        exp_of_reg0;
  logic [15:0] lpath_sig_shifted_reg0;
  logic        lpath_iv_reg0, lpath_of_reg0;
  logic [11:0] rpath_sig_shifted_reg0;
  logic [4:0]  exp_raw_reg0;
  logic        sel_lpath_reg0;
  logic [15:0] max_min_int_reg0;
  logic [4:0]  exp_normalized_reg0;
  logic [10:0] sig_normalized_reg0;
  logic [3:0]  clz_sig_reg0;
  logic        out_exp_zero_negone_reg0;
  logic [4:0]  out_exp_reg0;
  logic        out_sign_reg0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r                  <= 1'b0;
      is_single_reg0                  <= 1'b0;
      is_widen_reg0                   <= 1'b0;
      is_narrow_reg0                  <= 1'b0;
      is_vfr_reg0                     <= 1'b0;
      is_fp2int_reg0                  <= 1'b0;
      is_int2fp_reg0                  <= 1'b0;
      is_vfrsqrt7_reg0                <= 1'b0;
      is_vfrec7_reg0                  <= 1'b0;
      is_signed_int_reg0              <= 1'b0;
      round_in_reg0                   <= 11'h0;
      round_roundIn_reg0              <= 1'b0;
      round_stickyIn_reg0             <= 1'b0;
      round_signIn_reg0               <= 1'b0;
      is_normal_reg0                  <= 1'b0;
      is_inf_reg0                     <= 1'b0;
      is_nan_reg0                     <= 1'b0;
      is_neginf_reg0                  <= 1'b0;
      is_neginf_negzero_reg0          <= 1'b0;
      is_negzero_reg0                 <= 1'b0;
      is_poszero_reg0                 <= 1'b0;
      is_snan_reg0                    <= 1'b0;
      is_neg2_bplus1_b_reg0           <= 1'b0;
      is_neg2_b_bminus1_reg0          <= 1'b0;
      is_neg2_negbminus1_negzero_reg0 <= 1'b0;
      is_pos2_poszero_negbminus1_reg0 <= 1'b0;
      is_pos2_bminus1_b_reg0          <= 1'b0;
      is_pos2_b_bplus1_reg0           <= 1'b0;
      in_orR_reg0                     <= 1'b0;
      in_reg0                         <= 17'h0;
      sign_reg0                       <= 1'b0;
      exp_of_reg0                     <= 1'b0;
      lpath_sig_shifted_reg0          <= 16'h0;
      lpath_iv_reg0                   <= 1'b0;
      rpath_sig_shifted_reg0          <= 12'h0;
      exp_raw_reg0                    <= 5'h0;
      max_min_int_reg0                <= 16'h0;
      out_exp_reg0                    <= 5'h0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        is_single_reg0                  <= is_single;
        is_widen_reg0                   <= is_widen;
        is_narrow_reg0                  <= is_narrow;
        is_vfr_reg0                     <= is_vfr;
        is_fp2int_reg0                  <= is_fp2int;
        is_int2fp_reg0                  <= is_int2fp;
        is_vfrsqrt7_reg0                <= is_vfrsqrt7;
        is_vfrec7_reg0                  <= is_vfrec7;
        is_signed_int_reg0              <= is_signed_int;
        round_in_reg0                   <= round_in;
        round_roundIn_reg0              <= round_roundIn;
        round_stickyIn_reg0             <= round_stickyIn;
        round_signIn_reg0               <= sign;
        is_normal_reg0                  <= is_normal;
        is_inf_reg0                     <= is_inf;
        is_nan_reg0                     <= is_nan;
        is_neginf_reg0                  <= sign & is_inf;
        is_neginf_negzero_reg0          <= sign & (is_normal | is_subnormal & sig_frac_nz);
        is_negzero_reg0                 <= sign & is_subnormal & ~sig_frac_nz;
        is_poszero_reg0                 <= ~sign & is_subnormal & ~sig_frac_nz;
        is_snan_reg0                    <= ~sig[9] & is_nan;
        is_neg2_bplus1_b_reg0           <= sign & exp == 5'd30;
        is_neg2_b_bminus1_reg0          <= sign & exp == 5'd29;
        is_neg2_negbminus1_negzero_reg0 <= sign & sig[9:8] == 2'b00 & is_subnormal & sig_frac_nz;
        is_pos2_poszero_negbminus1_reg0 <= ~sign & sig[9:8] == 2'b00 & is_subnormal & sig_frac_nz;
        is_pos2_bminus1_b_reg0          <= ~sign & exp == 5'd29;
        is_pos2_b_bplus1_reg0           <= ~sign & exp == 5'd30;
        in_orR_reg0                     <= |in_sext;
        in_reg0                         <= in;
        sign_reg0                       <= sign;
        exp_of_reg0                     <= exp_of;
        lpath_sig_shifted_reg0          <= lpath_sig_shifted;
        lpath_iv_reg0                   <= lpath_iv;
        rpath_sig_shifted_reg0          <= rpath_sig_shifted;
        exp_raw_reg0                    <= exp_raw;
        max_min_int_reg0                <= max_min_int;
        out_exp_reg0                    <= out_exp;
      end
    end
  end

  // 不复位的 s1 寄存器（golden 里 RegEnable 未给初值的那几个）
  always_ff @(posedge clock) begin
    if (fire) begin
      rm_reg0                  <= rm_in;
      lpath_of_reg0            <= lpath_of;
      sel_lpath_reg0           <= sel_lpath;
      exp_normalized_reg0      <= exp_normalized;
      sig_normalized_reg0      <= sig_normalized;
      clz_sig_reg0             <= clz_sig;
      out_exp_zero_negone_reg0 <= out_exp_zero_negone;
      out_sign_reg0            <= is_vfrsqrt7 & is_poszero_posinf & sign;
    end
  end

  // ===========================================================================
  // §7 第 1 拍：舍入与整数/浮点结果拼装
  // ===========================================================================
  logic rnd_inexact, rnd_up;
  RoundingUnit_11 rounder (
    .io_in       (round_in_reg0),
    .io_roundIn  (round_roundIn_reg0),
    .io_stickyIn (round_stickyIn_reg0),
    .io_signIn   (round_signIn_reg0),
    .io_rm       (rm_reg0),
    .io_inexact  (rnd_inexact),
    .io_r_up     (rnd_up)
  );

  logic f2i_to_8_reg0, f2i_to_16_reg0;
  assign f2i_to_8_reg0  = is_fp2int_reg0 & is_narrow_reg0;
  assign f2i_to_16_reg0 = is_fp2int_reg0 & is_single_reg0;

  logic [10:0] out_reg0;     // 舍入后的尾数/整数
  logic        cout_reg0;    // 舍入进位溢出了本宽度
  assign out_reg0  = rnd_up ? 11'(round_in_reg0 + 11'h1) : round_in_reg0;
  assign cout_reg0 = rnd_up & (f2i_to_8_reg0 & (&round_in_reg0[6:0])
                             | f2i_to_16_reg0 & (&round_in_reg0)
                             | is_int2fp_reg0 & (&round_in_reg0[9:0]));

  logic [4:0]  exp_reg0;      // i2f 结果指数（源为 0 时给 0）
  logic [15:0] sig_reg0;      // f2i 右路的整数绝对值 / i2f 的尾数
  assign exp_reg0 = is_int2fp_reg0 & in_orR_reg0 ? 5'(exp_raw_reg0 + {4'h0, cout_reg0}) : 5'h0;
  assign sig_reg0 = (f2i_to_16_reg0 ? {4'h0, cout_reg0, out_reg0} : 16'h0)
                  | (f2i_to_8_reg0  ? {5'h0, out_reg0}            : 16'h0)
                  | (is_int2fp_reg0 ? 16'(out_reg0)               : 16'h0);

  // f2i 右路的标志
  logic rpath_ix_reg0, rpath_iv_reg0, rpath_pos_of_reg0, rpath_neg_of_reg0, rpath_of_reg0;
  logic [4:0] in_exp_reg0;
  assign in_exp_reg0   = in_reg0[15:11];
  assign rpath_ix_reg0 = f2i_to_16_reg0 & rnd_inexact
                       | f2i_to_8_reg0 & (rnd_inexact | (|rpath_sig_shifted_reg0[3:0]));
  assign rpath_iv_reg0 = is_fp2int_reg0 & ~is_signed_int_reg0 & in_reg0[16] & (|sig_reg0);
  // i8 目的：正数 2^7（指数 22）或 2^6 舍入进位后越界；负数 -2^7 以下越界
  assign rpath_pos_of_reg0 =
      is_fp2int_reg0 & ~in_reg0[16] & is_signed_int_reg0
        & (in_exp_reg0 == 5'd22 | in_exp_reg0 == 5'd21 & cout_reg0)
    | is_fp2int_reg0 & ~in_reg0[16] & ~is_signed_int_reg0
        & (in_exp_reg0 == 5'd22 & cout_reg0);
  assign rpath_neg_of_reg0 = is_fp2int_reg0 & in_reg0[16] & in_exp_reg0 == 5'd22
                           & ((|round_in_reg0[6:0]) | rnd_up);
  assign rpath_of_reg0 = f2i_to_8_reg0 & (rpath_pos_of_reg0 | rpath_neg_of_reg0)
                       | f2i_to_16_reg0 & cout_reg0;

  logic of_reg0, iv_reg0, ix_reg0;
  assign of_reg0 = is_fp2int_reg0 & (exp_of_reg0 | sel_lpath_reg0 & lpath_of_reg0
                                     | ~sel_lpath_reg0 & rpath_of_reg0)
                 | is_int2fp_reg0 & (exp_reg0 == 5'd31);
  assign iv_reg0 = is_fp2int_reg0 & (of_reg0 | sel_lpath_reg0 & lpath_iv_reg0
                                     | ~sel_lpath_reg0 & rpath_iv_reg0);
  assign ix_reg0 = is_fp2int_reg0 & (~iv_reg0 & ~sel_lpath_reg0 & rpath_ix_reg0)
                 | is_int2fp_reg0 & rnd_inexact;

  // f2i：取左路或右路的绝对值，有符号负数取负
  logic [15:0] int_abs_reg0, int_reg0;
  logic        negate_reg0;
  assign int_abs_reg0 = (is_fp2int_reg0 & sel_lpath_reg0  ? lpath_sig_shifted_reg0 : 16'h0)
                      | (is_fp2int_reg0 & ~sel_lpath_reg0 ? sig_reg0               : 16'h0);
  assign negate_reg0  = in_reg0[16] & is_signed_int_reg0;
  assign int_reg0 =
      (f2i_to_8_reg0  ? 16'(negate_reg0 ? 8'(8'h0 - int_abs_reg0[7:0]) : int_abs_reg0[7:0]) : 16'h0)
    | (f2i_to_16_reg0 ? (negate_reg0 ? 16'(16'h0 - int_abs_reg0) : int_abs_reg0)            : 16'h0);

  // ===========================================================================
  // §8 第 1 拍：vfr 查表与结果拼装
  // ===========================================================================
  logic [25:0] sig_in_shifted;
  logic [6:0]  sig_in7;
  logic [6:0]  rsqrt7_out, rec7_out, sig_out7_reg0;
  assign sig_in_shifted = {15'h0, sig_normalized_reg0} << (is_normal_reg0 ? 4'h0 : clz_sig_reg0);
  assign sig_in7 = (is_vfr_reg0 & is_vfrsqrt7_reg0 ? {exp_normalized_reg0[0], sig_in_shifted[9:4]} : 7'h0)
                 | (is_vfr_reg0 & is_vfrec7_reg0   ? sig_in_shifted[9:3]                         : 7'h0);

  Rsqrt7Table vfrsqrt7Table (
    .src (sig_in7),
    .out (rsqrt7_out)
  );
  Rec7Table vfrec7Table (
    .src (sig_in7),
    .out (rec7_out)
  );
  assign sig_out7_reg0 = (is_vfr_reg0 & is_vfrsqrt7_reg0 ? rsqrt7_out : 7'h0)
                       | (is_vfr_reg0 & is_vfrec7_reg0   ? rec7_out   : 7'h0);

  // rec7 结果尾数：正常档 = 表值；输出指数为 0/-1 的非规格化档按原指数 b+1 / b-1 / 其他 右移
  logic rec_sub, rec_bplus1, rec_bminus1;
  logic [9:0] out_sig_reg0;
  assign rec_sub     = is_vfrec7_reg0 & out_exp_zero_negone_reg0;
  assign rec_bplus1  = is_neg2_bplus1_b_reg0 | is_pos2_b_bplus1_reg0;
  assign rec_bminus1 = is_neg2_b_bminus1_reg0 | is_pos2_bminus1_b_reg0;
  assign out_sig_reg0 =
      (rec_sub & rec_bplus1                  ? {2'b01, sig_out7_reg0, 1'b0} : 10'h0)
    | (rec_sub & rec_bminus1                 ? {1'b1, sig_out7_reg0, 2'b00} : 10'h0)
    | (rec_sub & ~(rec_bplus1 | rec_bminus1) ? {2'b01, sig_out7_reg0, 1'b0} : 10'h0)
    | (is_vfrec7_reg0 & ~out_exp_zero_negone_reg0 ? {sig_out7_reg0, 3'h0}  : 10'h0);

  logic [15:0] fp_result;
  assign fp_result = (is_vfrsqrt7_reg0 ? {out_sign_reg0, out_exp_reg0, sig_out7_reg0, 3'h0} : 16'h0)
                   | (is_vfrec7_reg0   ? {sign_reg0, out_exp_reg0, out_sig_reg0}             : 16'h0);

  // ===========================================================================
  // §9 第 1 拍：十类结果 / 九类 fflags（Mux1H）
  // ===========================================================================
  localparam logic [15:0] RESULT_NAN  = 16'h7E00;   // 规范 NaN
  localparam logic [14:0] RESULT_INF  = 15'h7C00;   // 无符号 Inf
  localparam logic [14:0] RESULT_GFIN = 15'h7BFF;   // 最大有限数

  logic sel_fp2int, sel_int2fp, sel_nan, sel_rsqrt_inf, sel_rsqrt_zero, sel_normal;
  logic sel_rec_inf, sel_rec_zero, sel_rec_neg_tiny, sel_rec_pos_tiny;
  assign sel_fp2int       = is_fp2int_reg0;
  assign sel_int2fp       = is_int2fp_reg0;
  assign sel_nan          = is_vfrsqrt7_reg0 & (is_nan_reg0 | is_neginf_negzero_reg0)
                          | is_vfrec7_reg0 & is_nan_reg0;
  assign sel_rsqrt_inf    = is_vfrsqrt7_reg0 & is_inf_reg0;
  assign sel_rsqrt_zero   = is_vfrsqrt7_reg0 & (is_negzero_reg0 | is_poszero_reg0);
  assign sel_normal       = is_vfrsqrt7_reg0 & ~(is_nan_reg0 | is_neginf_negzero_reg0 | is_inf_reg0
                                                 | is_negzero_reg0 | is_poszero_reg0)
                          | is_vfrec7_reg0 & ~(is_nan_reg0 | is_inf_reg0 | is_negzero_reg0
                                               | is_poszero_reg0 | is_neg2_negbminus1_negzero_reg0
                                               | is_pos2_poszero_negbminus1_reg0);
  assign sel_rec_inf      = is_vfrec7_reg0 & is_inf_reg0;
  assign sel_rec_zero     = is_vfrec7_reg0 & (is_negzero_reg0 | is_poszero_reg0);
  assign sel_rec_neg_tiny = is_vfrec7_reg0 & is_neg2_negbminus1_negzero_reg0;   // 结果上溢（负）
  assign sel_rec_pos_tiny = is_vfrec7_reg0 & is_pos2_poszero_negbminus1_reg0;   // 结果上溢（正）

  logic [15:0] result0;
  assign result0 =
      (sel_fp2int       ? (iv_reg0 ? max_min_int_reg0 : int_reg0) : 16'h0)
    | (sel_int2fp       ? {is_signed_int_reg0 & sign_reg0, exp_reg0,
                           is_widen_reg0 ? {sig_reg0[7:0], 2'b00} : sig_reg0[9:0]} : 16'h0)
    | (sel_nan          ? RESULT_NAN                                         : 16'h0)
    | (sel_rsqrt_inf    ? (is_neginf_reg0 ? RESULT_NAN : 16'h0)              : 16'h0)
    | (sel_rsqrt_zero   ? {is_negzero_reg0, RESULT_INF}                      : 16'h0)
    | (sel_normal       ? fp_result                                          : 16'h0)
    | (sel_rec_inf      ? (is_neginf_reg0 ? 16'h8000 : 16'h0)                : 16'h0)
    | (sel_rec_zero     ? (is_negzero_reg0 ? 16'hFC00 : 16'h7C00)            : 16'h0)
    | (sel_rec_neg_tiny ? ((rm_reg0 == 3'h3 | rm_reg0 == 3'h1)               // RUP / RTZ
                             ? {1'b1, RESULT_GFIN} : {1'b1, RESULT_INF})     : 16'h0)
    | (sel_rec_pos_tiny ? ((rm_reg0 == 3'h2 | rm_reg0 == 3'h1)               // RDN / RTZ
                             ? {1'b0, RESULT_GFIN} : {1'b0, RESULT_INF})     : 16'h0);

  // fflags = {NV, DZ, OF, UF, NX}；rec7(-Inf) 那档照 Scala 写成 16 位（见文件头）
  logic [15:0] fflags0;
  assign fflags0 =
      (sel_fp2int ? {11'h0, iv_reg0, 3'b000, ix_reg0}            : 16'h0)
    | (sel_int2fp ? {11'h0, 2'b00, of_reg0, 1'b0, ix_reg0}       : 16'h0)
    | (is_vfrsqrt7_reg0 & (is_nan_reg0 | is_neginf_negzero_reg0)
                  ? ((is_snan_reg0 | is_neginf_negzero_reg0) ? 16'h0010 : 16'h0) : 16'h0)
    | (sel_rsqrt_inf ? (is_neginf_reg0 ? 16'h0010 : 16'h0)       : 16'h0)
    | (sel_rsqrt_zero | sel_rec_zero ? 16'h0008                  : 16'h0)   // DZ
    | (is_vfrec7_reg0 & is_nan_reg0 ? (is_snan_reg0 ? 16'h0010 : 16'h0) : 16'h0)
    | (sel_rec_inf ? (is_neginf_reg0 ? 16'h8000 : 16'h0)         : 16'h0)
    | (sel_rec_neg_tiny | sel_rec_pos_tiny ? 16'h0005            : 16'h0);  // OF | NX

  // ===========================================================================
  // §10 s2 输出寄存器（fireReg_last_r 使能）
  // ===========================================================================
  logic [15:0] result0_reg1;
  logic [15:0] fflags0_reg1;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      result0_reg1 <= 16'h0;
    else if (fireReg_last_r)
      result0_reg1 <= result0;
  end

  always_ff @(posedge clock) begin
    if (fireReg_last_r)
      fflags0_reg1 <= fflags0;
  end

  assign result_out = result0_reg1;
  assign fflags_out = fflags0_reg1[4:0];

endmodule

module CVT16(
  input         clock,
  input         reset,
  input         io_fire,
  input  [15:0] io_src,
  input  [7:0]  io_opType,
  input  [1:0]  io_sew,
  input  [2:0]  io_rm,
  output [15:0] io_result,
  output [4:0]  io_fflags
);

  xs_CVT16_core u_core (
    .clock      (clock),
    .reset      (reset),
    .fire       (io_fire),
    .src        (io_src),
    .op_type    (io_opType),
    .sew        (io_sew),
    .rm_in      (io_rm),
    .result_out (io_result),
    .fflags_out (io_fflags)
  );

endmodule
