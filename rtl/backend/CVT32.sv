// CVT32.sv —— 向量浮点转换 32 位通道的转换器（yunsuan CVT32，2 拍流水）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvt 的第 1 条通道（经 VCVT_1 壳）。处理源、目的都不超过 32 位的元素，自己按
//   {opType, sew} 译码（不归本通道的组合输出 0）：
//     f2i  ：f32->i32 / f32->i16（变窄） / f16->i32（变宽） / f16->i16 / f16->i8（变窄）
//     i2f  ：i32->f32 / i16->f32（变宽） / i32->f16（变窄） / i16->f16 / i8->f16（变宽）
//     f2f  ：f16->f32（变宽，精确） / f32->f16（变窄，需舍入，含 ROD）
//     vfr  ：f16 / f32 的 vfrec7 / vfrsqrt7
//   opType 位段（yunsuan VfcvtType）：[7:5]=110 f2f；[7:6]=10 f2i / 01 i2f；[5]=估算类；
//   [4:3]=00 单宽 01 变宽 10 变窄；[0]=有符号（整数）/ rec7（估算）/ ROD（f2f 变窄）。
// 流水（Scala 文件头的拆法，本通道把 ShiftRightJam 与 i2f 的移位挪到了第 1 拍）：
//   第 0 拍：译出 10 种整数通路标志；把 f16 源摆成 f32 形状（指数放低 5 位、尾数左对齐），
//            f2i 拆 RawFloat 并分左路/右路（右路只算好移位量和待移尾数），i2f 求绝对值与 CLZ，
//            vfr 分类与规格化、算输出指数，f2f 变窄预先算好「正常 / 非规格化」两套舍入输入，
//            f2f 变宽直接算出结果字段；全部落 s1 寄存器。
//   第 1 拍：右路 ShiftRightJam、i2f 规格化左移；共用 24 位 RoundingUnit 给 f2i/i2f 舍入；
//            f2f 变窄另有两个 10 位 RoundingUnit（正常 / 非规格化）；vfr 查表；
//            24 类结果、10 类 fflags 各一个 Mux1H，落 s2 寄存器。
// 怪癖（照 golden，均为 Scala 原样）：
//   - Mux1H 一律与门后按位或，非法组合下照样或在一起；
//   - int2fp_clz 的「用 32 位 CLZ」选择条件里混进了 exp_of（f2i 的指数上溢标志），i32->f16 的
//     「高 16 位非 0」也借用 exp_of 这个寄存器传到第 1 拍；
//   - exp_normalized_8 的选择里 rec7 那一项没有 in_is_fp32 门控（Scala 运算符优先级）；
//   - f2f 变宽的指数四选一里「是零」那一档给 0，所以 golden 根本没有 isZero 寄存器；
//   - clz_fp32 存 8 位，高 3 位恒 0；in_abs 存 33 位，第 32 位第 1 拍不读。
// 子模块：CLZ_7 / CLZ_9 / CLZ_28×3 / CLZ_29×2 / CLZ_30 / CLZ_31、ShiftRightJam_2 / _3、
//   RoundingUnit_8 / RoundingUnit_9×2（均为已签核重写件）；Rec7Table / Rsqrt7Table（另一条 lane
//   认领，本 lane 两侧用 golden）。
// golden 对照：G1-canonical/golden-rtl/CVT32.sv
// =============================================================================

module xs_CVT32_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [31:0] src_in,
  input  logic [7:0]  op_type,
  input  logic [1:0]  sew,
  input  logic [2:0]  rm_in,
  output logic [31:0] result_out,
  output logic [4:0]  fflags_out
);

  // ===========================================================================
  // §0 控制译码（第 0 拍）
  // ===========================================================================
  logic is_sew_8, is_sew_16, is_sew_32;
  logic is_single, is_widen, is_narrow;
  logic is_vfr, is_fp2int, is_int2fp, is_fp2fp, is_vfrsqrt7, is_vfrec7, is_signed_int;

  assign is_sew_8      = sew == 2'b00;
  assign is_sew_16     = sew == 2'b01;
  assign is_sew_32     = sew == 2'b10;
  assign is_single     = op_type[4:3] == 2'b00;
  assign is_widen      = op_type[4:3] == 2'b01;
  assign is_narrow     = op_type[4:3] == 2'b10;
  assign is_vfr        = op_type[5] & (is_sew_16 | is_sew_32);
  assign is_fp2int     = op_type[7:6] == 2'b10
                       & (is_sew_32 & is_single | is_sew_16 & is_narrow | is_sew_16 & is_widen
                          | is_sew_16 & is_single | is_sew_8 & is_narrow);
  assign is_int2fp     = op_type[7:6] == 2'b01
                       & (is_sew_32 & is_single | is_sew_16 & is_narrow | is_sew_16 & is_widen
                          | is_sew_16 & is_single | is_sew_8 & is_widen);
  assign is_fp2fp      = op_type[7:5] == 3'b110 & is_sew_16 & (is_narrow | is_widen);
  assign is_vfrsqrt7   = is_vfr & ~op_type[0];
  assign is_vfrec7     = is_vfr & op_type[0];
  assign is_signed_int = op_type[0];

  // 源 / 目的浮点格式与 10 种整数通路
  logic in_is_fp16, in_is_fp32, out_is_fp16, out_is_fp32;
  logic fp32toint32, fp32toint16, fp16toint32, fp16toint16, fp16toint8;
  logic int32tofp32, int16tofp32, int32tofp16, int16tofp16, int8tofp16;
  assign in_is_fp16  = is_fp2int & (is_sew_16 & is_widen | is_sew_16 & is_single | is_sew_8 & is_narrow)
                     | is_vfr & is_sew_16;
  assign in_is_fp32  = is_fp2int & (is_sew_32 & is_single | is_sew_16 & is_narrow)
                     | is_vfr & is_sew_32;
  assign out_is_fp32 = is_int2fp & (is_sew_32 & is_single | is_sew_16 & is_widen)
                     | is_vfr & is_sew_32 | is_fp2fp & is_widen;
  assign out_is_fp16 = is_int2fp & (is_sew_16 & is_narrow | is_sew_16 & is_single | is_sew_8 & is_widen)
                     | is_vfr & is_sew_16 | is_fp2fp & is_narrow;
  assign fp32toint32 = is_fp2int & in_is_fp32 & is_single;
  assign fp32toint16 = is_fp2int & in_is_fp32 & is_narrow;
  assign fp16toint32 = is_fp2int & in_is_fp16 & is_widen;
  assign fp16toint16 = is_fp2int & in_is_fp16 & is_single;
  assign fp16toint8  = is_fp2int & in_is_fp16 & is_narrow;
  assign int32tofp32 = is_int2fp & out_is_fp32 & is_single;
  assign int16tofp32 = is_int2fp & out_is_fp32 & is_widen;
  assign int32tofp16 = is_int2fp & out_is_fp16 & is_narrow;
  assign int16tofp16 = is_int2fp & out_is_fp16 & is_single;
  assign int8tofp16  = is_int2fp & out_is_fp16 & is_widen;

  logic f2i_from_fp32, f2i_from_fp16;
  assign f2i_from_fp32 = fp32toint32 | fp32toint16;
  assign f2i_from_fp16 = fp16toint32 | fp16toint16 | fp16toint8;

  // ===========================================================================
  // §1 第 0 拍：源拆解（f16 源摆成 f32 形状）
  // ===========================================================================
  logic [31:0] src;     // f32 形状：[31] 符号 [30:23] 指数（f16 只占 [27:23]）[22:0] 尾数
  assign src = (in_is_fp32 | is_vfr & is_sew_32 | is_fp2fp & is_narrow ? src_in : 32'h0)
             | (in_is_fp16 | is_vfr & is_sew_16 | is_fp2fp & is_widen
                  ? {src_in[15], 3'h0, src_in[14:10], src_in[9:0], 13'h0} : 32'h0);

  logic        fp_sign;
  logic [7:0]  fp_exp;
  logic [22:0] fp_sig;
  assign fp_sign = src[31];
  assign fp_exp  = src[30:23];
  assign fp_sig  = src[22:0];

  // f2i：RawFloat = {符号, 指数(非规格化记 1), 隐含位, 23 位尾数}
  logic        exp_not_zero;
  logic [32:0] fp2int_in;
  assign exp_not_zero = f2i_from_fp32 & (|fp_exp) | f2i_from_fp16 & (|fp_exp[4:0]);
  assign fp2int_in    = {fp_sign, fp_exp | {7'h0, ~exp_not_zero}, exp_not_zero, fp_sig};

  // i2f：按源宽符号/零扩展到 33 位
  logic        i2f_from_32, i2f_from_16;
  logic [32:0] in_sext;
  assign i2f_from_32 = int32tofp32 | int32tofp16;
  assign i2f_from_16 = int16tofp32 | int16tofp16;
  assign in_sext =
      (~is_signed_int & i2f_from_32 ? {1'b0, src_in}                  : 33'h0)
    | (is_signed_int & i2f_from_32  ? {src_in[31], src_in}            : 33'h0)
    | (~is_signed_int & i2f_from_16 ? {17'h0, src_in[15:0]}           : 33'h0)
    | (is_signed_int & i2f_from_16  ? {{17{src_in[15]}}, src_in[15:0]} : 33'h0)
    | (~is_signed_int & int8tofp16  ? {25'h0, src_in[7:0]}            : 33'h0)
    | (is_signed_int & int8tofp16   ? {{25{src_in[7]}}, src_in[7:0]}  : 33'h0);

  logic [32:0] in;     // 三类共用的源：f2i 放 RawFloat，i2f 放扩展整数，vfr 放 f32 形状
  assign in = (is_fp2int ? fp2int_in    : 33'h0)
            | (is_int2fp ? in_sext      : 33'h0)
            | (is_vfr    ? {1'b0, src}  : 33'h0);

  logic        sign;
  logic [7:0]  exp;
  logic [23:0] sig;    // f2i 含隐含位（24 位）；vfr 只有 23 位尾数
  assign sign = (is_fp2int | is_int2fp) & in[32] | is_vfr & in[31] | is_fp2fp & is_widen & fp_sign;
  assign exp  = (is_fp2int ? in[31:24] : 8'h0)  | (is_vfr ? in[30:23] : 8'h0);
  assign sig  = (is_fp2int ? in[23:0]  : 24'h0) | (is_vfr ? {1'b0, in[22:0]} : 24'h0);

  // ===========================================================================
  // §2 第 0 拍：f2i 左路 / 右路准备
  // ===========================================================================
  // 能表示的最大指数（bias + 目的位数 - 1）
  logic [7:0] max_int_exp;
  assign max_int_exp = (fp32toint32 ? 8'd158 : 8'h0)   // 127 + 31
                     | (fp32toint16 ? 8'd142 : 8'h0)   // 127 + 15
                     | (fp16toint32 ? 8'd46  : 8'h0)   // 15 + 31
                     | (fp16toint16 ? 8'd30  : 8'h0)   // 15 + 15
                     | (fp16toint8  ? 8'd22  : 8'h0);  // 15 + 7

  // 左路：指数 >= bias + 尾数位数（f32 150 / f16 25）时尾数左移即整数
  //   移位量只取低 5 位（Scala 取 lpath_max_shamt 的位宽）
  logic [7:0]  lpath_shamt;
  logic [54:0] lpath_shifted_full;
  logic [31:0] lpath_sig_shifted;
  logic        lpath_iv, lpath_of, lpath_dst_ok;
  assign lpath_dst_ok       = fp32toint32 | fp16toint16 | fp16toint32;   // 能走左路的三种
  assign lpath_shamt        = 8'(exp - ((fp32toint32 ? 8'd150 : 8'h0) | (fp16toint16 | fp16toint32 ? 8'd25 : 8'h0)));
  assign lpath_shifted_full = {31'h0, sig} << lpath_shamt[4:0];
  assign lpath_sig_shifted  = (fp32toint32 ? lpath_shifted_full[31:0] : 32'h0)
                            | (fp16toint16 | fp16toint32 ? 32'(lpath_shifted_full[31:13]) : 32'h0);
  assign lpath_iv = lpath_dst_ok & ~is_signed_int & sign;
  assign lpath_of = lpath_dst_ok & is_signed_int & (exp == max_int_exp) & (~sign | sign & (|in[22:0]));

  // 右路：移位量 = (bias + 保留位数) - exp，第 1 拍再做 ShiftRightJam
  logic [7:0] rpath_shamt;
  assign rpath_shamt = 8'(((fp32toint32 ? 8'd150 : 8'h0)                  // 127 + 23
                         | (fp32toint16 ? 8'd142 : 8'h0)                  // 127 + 15
                         | (fp16toint16 | fp16toint32 ? 8'd25 : 8'h0)     // 15 + 10
                         | (fp16toint8 ? 8'd22 : 8'h0)) - exp);           // 15 + 7

  logic sel_lpath;
  assign sel_lpath = exp >= ((is_fp2int & in_is_fp32 ? 8'd150 : 8'h0) | (is_fp2int & in_is_fp16 ? 8'd25 : 8'h0));

  // 饱和值：NaN 或正数取最大，负数取最小
  logic [31:0] max_int, min_int, max_min_int;
  logic        sign_or_nan;
  assign max_int = (fp32toint32 | fp16toint32 ? {~is_signed_int, 31'h7FFFFFFF}     : 32'h0)
                 | (fp32toint16 | fp16toint16 ? {16'h0, ~is_signed_int, 15'h7FFF} : 32'h0)
                 | (fp16toint8                ? {24'h0, ~is_signed_int, 7'h7F}    : 32'h0);
  assign min_int = (fp32toint32 | fp16toint32 ? {is_signed_int, 31'h0}            : 32'h0)
                 | (fp32toint16 | fp16toint16 ? {16'h0, is_signed_int, 15'h0}     : 32'h0)
                 | (fp16toint8                ? {24'h0, is_signed_int, 7'h0}      : 32'h0);
  assign sign_or_nan = f2i_from_fp32 & (&fp_exp) & (|fp_sig)
                     | f2i_from_fp16 & (&fp_exp[4:0]) & (|fp_sig)
                     | ~sign;
  assign max_min_int = sign_or_nan ? max_int : min_int;

  // ===========================================================================
  // §3 第 0 拍：i2f 绝对值、上溢预判、CLZ
  // ===========================================================================
  logic [32:0] in_abs;
  assign in_abs = (is_int2fp & sign  ? 33'(~in + 33'h1) : 33'h0)
                | (is_int2fp & ~sign ? in               : 33'h0);

  // exp_of：f2i 指数超界（f16 源还要算上 Inf/NaN）；i32->f16 时借它表示「|x| >= 2^16」必上溢
  logic exp_of;
  assign exp_of = is_fp2int & in_is_fp32 & (exp > max_int_exp)
                | is_fp2int & in_is_fp16 & (exp > max_int_exp | (&fp_exp[4:0]))
                | int32tofp16 & (|in_abs[31:16]);

  logic [5:0] clz32_out;
  logic [4:0] clz16_out;
  CLZ_9 int2fp_clz_clz (
    .io_in  (in_abs[31:0]),
    .io_out (clz32_out)
  );
  CLZ_7 int2fp_clz_clz_1 (
    .io_in  (in_abs[15:0]),
    .io_out (clz16_out)
  );

  logic use_clz32, use_clz16;   // 32 位规格化（f32 目的或 i32->f16 上溢）/ 16 位规格化（f16 目的）
  logic [5:0] int2fp_clz;
  assign use_clz32  = out_is_fp32 | exp_of;
  assign use_clz16  = int32tofp16 & in_abs[31:16] == 16'h0 | int16tofp16 | int8tofp16;
  assign int2fp_clz = (use_clz32 ? clz32_out : 6'h0) | (use_clz16 ? {1'b0, clz16_out} : 6'h0);

  // ===========================================================================
  // §4 第 0 拍：vfr（vfrec7 / vfrsqrt7）分类与规格化
  // ===========================================================================
  logic vfr16, vfr32;
  logic [9:0]  sig16;          // f16 尾数（f32 形状里的 [22:13]）
  logic [22:0] sig32;
  assign vfr16 = is_vfr & in_is_fp16;
  assign vfr32 = is_vfr & in_is_fp32;
  assign sig16 = sig[22:13];
  assign sig32 = sig[22:0];

  logic is_normal, is_subnormal, is_inf, is_nan, frac_nz;
  logic is_poszero_posinf;
  assign frac_nz      = vfr16 & (|sig16) | vfr32 & (|sig32);
  assign is_normal    = vfr16 & (|exp[4:0]) & ~(&exp[4:0]) | vfr32 & (|exp) & ~(&exp);
  assign is_subnormal = vfr16 & ~(|exp[4:0]) | vfr32 & ~(|exp);
  assign is_inf       = vfr16 & (&exp[4:0]) & ~(|sig16) | vfr32 & (&exp) & ~(|sig32);
  assign is_nan       = vfr16 & (&exp[4:0]) & (|sig16)  | vfr32 & (&exp) & (|sig32);
  assign is_poszero_posinf = vfr16 & ~sign & (is_normal | is_subnormal & (|sig16))
                           | vfr32 & ~sign & (is_normal | is_subnormal & (|sig32));

  // rec7 的四个指数边界档（b+1 / b / b-1 对应 exp = max-1 / max-2）
  logic exp_is_bplus1, exp_is_bminus1;
  assign exp_is_bplus1  = vfr16 & exp[4:0] == 5'd30 | vfr32 & exp == 8'd254;
  assign exp_is_bminus1 = vfr16 & exp[4:0] == 5'd29 | vfr32 & exp == 8'd253;
  logic sub_top2_zero;   // 非规格化且尾数最高两位为 0：rec7 结果上溢
  assign sub_top2_zero = vfr16 & sig[22:21] == 2'b00 & is_subnormal & (|sig16)
                       | vfr32 & sig[22:21] == 2'b00 & is_subnormal & (|sig32);

  // 非规格化：规格化后指数 = 0 - CLZ(尾数)
  logic [3:0] lzc16_a;
  logic [4:0] lzc32_a;
  logic [3:0] zero_minus_lzc_f16;
  logic [4:0] zero_minus_lzc_f32;
  CLZ_28 zero_minus_lzc_f16_clz (
    .io_in  (sig16),
    .io_out (lzc16_a)
  );
  CLZ_29 zero_minus_lzc_f32_clz (
    .io_in  (sig32),
    .io_out (lzc32_a)
  );
  assign zero_minus_lzc_f16 = vfr16 ? 4'(4'h0 - lzc16_a) : 4'h0;
  assign zero_minus_lzc_f32 = vfr32 ? 5'(5'h0 - lzc32_a) : 5'h0;

  // 规格化的选择：rsqrt7 只对正的非零有限数，rec7 对所有规格化/非规格化
  logic sel_norm_any, sel_sub_any;
  assign sel_norm_any = is_vfrsqrt7 & is_poszero_posinf & is_normal  | is_vfrec7 & is_normal;
  assign sel_sub_any  = is_vfrsqrt7 & is_poszero_posinf & ~is_normal | is_vfrec7 & ~is_normal;

  logic [4:0]  exp_normalized_5;
  logic [7:0]  exp_normalized_8;
  logic [10:0] sig_normalized_11;
  logic [23:0] sig_normalized_24;
  assign exp_normalized_5  = (in_is_fp16 & sel_norm_any ? exp[4:0] : 5'h0)
                           | (in_is_fp16 & sel_sub_any  ? {zero_minus_lzc_f16[3], zero_minus_lzc_f16} : 5'h0);
  // 注意：rec7 一项没有 in_is_fp32 门控（Scala 原式的运算符优先级），照搬
  assign exp_normalized_8  = (in_is_fp32 & is_vfrsqrt7 & is_poszero_posinf & is_normal | is_vfrec7 & is_normal
                                ? exp : 8'h0)
                           | (in_is_fp32 & is_vfrsqrt7 & is_poszero_posinf & ~is_normal | is_vfrec7 & ~is_normal
                                ? {{3{zero_minus_lzc_f32[4]}}, zero_minus_lzc_f32} : 8'h0);
  assign sig_normalized_11 = (in_is_fp16 & sel_norm_any ? {1'b0, sig16} : 11'h0)
                           | (in_is_fp16 & sel_sub_any  ? {sig16, 1'b0} : 11'h0);
  assign sig_normalized_24 = (in_is_fp32 & sel_norm_any ? {1'b0, sig32} : 24'h0)
                           | (in_is_fp32 & sel_sub_any  ? {sig32, 1'b0} : 24'h0);

  logic [3:0] clz_fp16_raw;
  logic [4:0] clz_fp32_raw;
  CLZ_30 clz_fp16_clz (
    .io_in  (sig_normalized_11),
    .io_out (clz_fp16_raw)
  );
  CLZ_31 clz_fp32_clz (
    .io_in  (sig_normalized_24),
    .io_out (clz_fp32_raw)
  );

  // rec7 输出指数 = 2*bias - 1 - e（f16 29、f32 253）；为 0 或 -1 时结果非规格化
  logic       rec16, rec32;
  logic [4:0] out_exp_normalized_fp16;
  logic [7:0] out_exp_normalized_fp32;
  logic       out_exp_zero_negone;
  assign rec16 = is_vfrec7 & in_is_fp16;
  assign rec32 = is_vfrec7 & in_is_fp32;
  assign out_exp_normalized_fp16 = rec16 ? 5'(5'd29 - exp_normalized_5)  : 5'h0;
  assign out_exp_normalized_fp32 = rec32 ? 8'(8'd253 - exp_normalized_8) : 8'h0;
  assign out_exp_zero_negone =
      rec16 & (out_exp_normalized_fp16 == 5'h0 | (&out_exp_normalized_fp16))
    | rec32 & (out_exp_normalized_fp32 == 8'h0 | (&out_exp_normalized_fp32));

  // rsqrt7 输出指数 = (3*bias - 1 - e) / 2（f16 44、f32 380）；非规格化 e = -clz
  logic [3:0] lzc16_b;
  logic [4:0] lzc32_b;
  CLZ_28 out_exp_fp16_clz (
    .io_in  (sig16),
    .io_out (lzc16_b)
  );
  CLZ_29 out_exp_fp32_clz (
    .io_in  (sig32),
    .io_out (lzc32_b)
  );
  logic [5:0] rsqrt16_norm, rsqrt16_sub;
  logic [8:0] rsqrt32_norm, rsqrt32_sub;
  assign rsqrt16_norm = 6'(6'd44 - {1'b0, exp[4:0]});
  assign rsqrt16_sub  = 6'(6'd44 + {2'b00, lzc16_b});
  assign rsqrt32_norm = 9'(9'd380 - {1'b0, exp});
  assign rsqrt32_sub  = 9'(9'd380 + {4'h0, lzc32_b});

  logic [4:0] out_exp_fp16;
  logic [7:0] out_exp_fp32;
  assign out_exp_fp16 = (in_is_fp16 & is_vfrsqrt7 & is_normal  ? rsqrt16_norm[5:1] : 5'h0)
                      | (in_is_fp16 & is_vfrsqrt7 & ~is_normal ? rsqrt16_sub[5:1]  : 5'h0)
                      | (in_is_fp16 & is_vfrec7 & ~out_exp_zero_negone ? out_exp_normalized_fp16 : 5'h0);
  assign out_exp_fp32 = (in_is_fp32 & is_vfrsqrt7 & is_normal  ? rsqrt32_norm[8:1] : 8'h0)
                      | (in_is_fp32 & is_vfrsqrt7 & ~is_normal ? rsqrt32_sub[8:1]  : 8'h0)
                      | (in_is_fp32 & is_vfrec7 & ~out_exp_zero_negone ? out_exp_normalized_fp32 : 8'h0);

  // ===========================================================================
  // §5 第 0 拍：f2f 变窄（f32 -> f16）—— 正常 / 非规格化两套舍入输入
  // ===========================================================================
  logic       fp2fp_narrow, fp2fp_widen;
  assign fp2fp_narrow = is_fp2fp & is_narrow;
  assign fp2fp_widen  = is_fp2fp & is_widen;

  logic [8:0] down_exp;       // f16 偏置下的指数 = e - 112（有符号 9 位）
  assign down_exp = 9'({1'b0, fp_exp} - 9'd112);

  // 正常：保留 10 位尾数，第 11 位为 round，其后为 sticky
  logic [9:0] nor_in;
  logic       nor_roundBit, nor_stickyBit;
  assign nor_in        = fp_sig[22:13];
  assign nor_roundBit  = fp_sig[12];
  assign nor_stickyBit = |fp_sig[11:0];

  // 非规格化：{隐含位, 尾数高 11 位} 右移 (113 - e)
  logic [11:0] subnor_sig;
  logic        subnor_shift_sticky;
  ShiftRightJam_3 shiftRightJam_1 (
    .io_in     ({|fp_exp, fp_sig[22:12]}),
    .io_shamt  (8'(8'd113 - fp_exp)),
    .io_out    (subnor_sig),
    .io_sticky (subnor_shift_sticky)
  );

  // 上溢时给的值：RTZ/朝 0 方向或 ROD -> 最大有限数，否则 Inf
  logic rmin_narrow, of_to_max;
  assign rmin_narrow = fp2fp_narrow & (rm_in == 3'h1 | rm_in == 3'h2 & ~fp_sign | rm_in == 3'h3 & fp_sign);
  assign of_to_max   = rmin_narrow | op_type[0];

  logic src_exp_ones, src_is_nan;
  assign src_exp_ones = &fp_exp;
  assign src_is_nan   = src_exp_ones & (|fp_sig);

  // ===========================================================================
  // §6 第 0 拍：f2f 变宽（f16 -> f32，精确）—— 直接算出各字段
  // ===========================================================================
  logic [3:0] subnor_shamt;       // f16 非规格化的前导零
  logic [24:0] subnor_sig_shifted;
  CLZ_28 subnor_shamt_clz (
    .io_in  (fp_sig[22:13]),
    .io_out (subnor_shamt)
  );
  assign subnor_sig_shifted = {15'h0, fp_sig[22:13]} << subnor_shamt;

  logic f16_exp_ones, f16_exp_zero, f16_sig_nz;
  assign f16_exp_ones = &fp_exp[4:0];
  assign f16_exp_zero = ~(|fp_exp[4:0]);
  assign f16_sig_nz   = |fp_sig[22:13];

  // ===========================================================================
  // §7 s1 寄存器（fire 使能）
  // ===========================================================================
  logic        fireReg_last_r;
  // —— 带异步复位的（golden 里 RegEnable 给了初值的）——
  logic        is_fp2int_reg0, is_int2fp_reg0, is_fp2fp_reg0;
  logic        is_vfrsqrt7_reg0, is_vfrec7_reg0, is_signed_int_reg0;
  logic        is_normal_reg0, is_inf_reg0, is_nan_reg0, is_neginf_reg0;
  logic        is_neginf_negzero_reg0, is_negzero_reg0, is_poszero_reg0, is_snan_reg0;
  logic        is_neg2_bplus1_b_reg0, is_neg2_b_bminus1_reg0, is_neg2_negbminus1_negzero_reg0;
  logic        is_pos2_poszero_negbminus1_reg0, is_pos2_bminus1_b_reg0, is_pos2_b_bplus1_reg0;
  logic        in_orR_reg0;
  logic [32:0] in_reg0;
  logic        sign_reg0;
  logic        lpath_iv_reg0;
  logic        exp_of_reg0;
  logic [31:0] max_min_int_reg0;
  logic [4:0]  out_exp_fp16_reg0;
  logic [7:0]  out_exp_fp32_reg0;
  // —— 不复位的 ——
  logic        is_widen_reg0, is_narrow_reg0;
  logic [2:0]  rm_reg0;
  logic [9:0]  nor_in_reg0;
  logic        nor_roundBit_reg0, nor_stickyBit_reg0, nor_signBit_reg0;
  logic [9:0]  subnor_in_reg0;
  logic        subnor_roundBit_reg0, subnor_stickyBit_reg0, subnor_signBit_reg0;
  logic        in_is_fp16_reg0, in_is_fp32_reg0;
  logic        fp32toint32_reg0, fp32toint16_reg0, fp16toint32_reg0, fp16toint16_reg0, fp16toint8_reg0;
  logic        out_is_fp16_reg0, out_is_fp32_reg0;
  logic        int32tofp32_reg0, int16tofp32_reg0, int32tofp16_reg0, int16tofp16_reg0, int8tofp16_reg0;
  logic [31:0] lpath_sig_shifted_reg0;
  logic        lpath_of_reg0;
  logic [24:0] sig_cat0_reg;
  logic [7:0]  rpath_shamt_reg0;
  logic [32:0] in_abs_reg0;
  logic [5:0]  int2fp_clz_reg0;
  logic        sel_lpath_reg0;
  logic [4:0]  exp_normalized_5_reg0;
  logic [7:0]  exp_normalized_8_reg0;
  logic [10:0] sig_normalized_11_reg0;
  logic [23:0] sig_normalized_24_reg0;
  logic [3:0]  clz_fp16_reg0;
  logic [7:0]  clz_fp32_reg0;
  logic        out_exp_zero_negone_reg0;
  logic        out_sign_reg0;
  logic [8:0]  down_exp_reg0;
  logic        may_be_subnor_reg0;
  logic [4:0]  nor_of_exp_reg0;
  logic [9:0]  nor_of_sig_reg0;
  logic        special_case_reg0;
  logic        fp2fp_iv_reg0;
  logic        in_isnan_neg_reg0;
  logic        in_sigNotZero_reg0;
  logic [7:0]  nor_exp_reg0;
  logic [9:0]  nor_sig_reg0;
  logic [7:0]  subnor_exp_reg0;
  logic [9:0]  subnor_sig_w_reg0;
  logic        isNaN_reg0, expIsOnes_reg0, expIsZero_reg0, isSubnormal_reg0, sigNotZero_reg0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r                  <= 1'b0;
      is_fp2int_reg0                  <= 1'b0;
      is_int2fp_reg0                  <= 1'b0;
      is_fp2fp_reg0                   <= 1'b0;
      is_vfrsqrt7_reg0                <= 1'b0;
      is_vfrec7_reg0                  <= 1'b0;
      is_signed_int_reg0              <= 1'b0;
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
      in_reg0                         <= 33'h0;
      sign_reg0                       <= 1'b0;
      lpath_iv_reg0                   <= 1'b0;
      exp_of_reg0                     <= 1'b0;
      max_min_int_reg0                <= 32'h0;
      out_exp_fp16_reg0               <= 5'h0;
      out_exp_fp32_reg0               <= 8'h0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        is_fp2int_reg0                  <= is_fp2int;
        is_int2fp_reg0                  <= is_int2fp;
        is_fp2fp_reg0                   <= is_fp2fp;
        is_vfrsqrt7_reg0                <= is_vfrsqrt7;
        is_vfrec7_reg0                  <= is_vfrec7;
        is_signed_int_reg0              <= is_signed_int;
        is_normal_reg0                  <= is_normal;
        is_inf_reg0                     <= is_inf;
        is_nan_reg0                     <= is_nan;
        is_neginf_reg0                  <= is_vfr & sign & is_inf;
        is_neginf_negzero_reg0          <= vfr16 & sign & (is_normal | is_subnormal & (|sig16))
                                         | vfr32 & sign & (is_normal | is_subnormal & (|sig32));
        is_negzero_reg0                 <= vfr16 & sign & is_subnormal & ~(|sig16)
                                         | vfr32 & sign & is_subnormal & ~(|sig32);
        is_poszero_reg0                 <= vfr16 & ~sign & is_subnormal & ~(|sig16)
                                         | vfr32 & ~sign & is_subnormal & ~(|sig32);
        // vfr 的 sNaN；f2f 变宽时这里存 f16 源是否 sNaN（复用同一个寄存器）
        is_snan_reg0                    <= is_vfr & ~sig[22] & is_nan
                                         | fp2fp_widen & f16_exp_ones & f16_sig_nz & ~fp_sig[22];
        is_neg2_bplus1_b_reg0           <= sign & exp_is_bplus1;
        is_neg2_b_bminus1_reg0          <= sign & exp_is_bminus1;
        is_neg2_negbminus1_negzero_reg0 <= sign & sub_top2_zero;
        is_pos2_poszero_negbminus1_reg0 <= ~sign & sub_top2_zero;
        is_pos2_bminus1_b_reg0          <= ~sign & exp_is_bminus1;
        is_pos2_b_bplus1_reg0           <= ~sign & exp_is_bplus1;
        in_orR_reg0                     <= |in_sext;
        in_reg0                         <= in;
        sign_reg0                       <= sign;
        lpath_iv_reg0                   <= lpath_iv;
        exp_of_reg0                     <= exp_of;
        max_min_int_reg0                <= max_min_int;
        out_exp_fp16_reg0               <= out_exp_fp16;
        out_exp_fp32_reg0               <= out_exp_fp32;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      is_widen_reg0            <= is_widen;
      is_narrow_reg0           <= is_narrow;
      rm_reg0                  <= rm_in;
      nor_in_reg0              <= nor_in;
      nor_roundBit_reg0        <= nor_roundBit;
      nor_stickyBit_reg0       <= nor_stickyBit;
      nor_signBit_reg0         <= fp_sign;
      subnor_in_reg0           <= subnor_sig[10:1];
      subnor_roundBit_reg0     <= subnor_sig[0];
      subnor_stickyBit_reg0    <= subnor_shift_sticky | nor_stickyBit;
      subnor_signBit_reg0      <= fp_sign;
      in_is_fp16_reg0          <= in_is_fp16;
      in_is_fp32_reg0          <= in_is_fp32;
      fp32toint32_reg0         <= fp32toint32;
      fp32toint16_reg0         <= fp32toint16;
      fp16toint32_reg0         <= fp16toint32;
      fp16toint16_reg0         <= fp16toint16;
      fp16toint8_reg0          <= fp16toint8;
      out_is_fp16_reg0         <= out_is_fp16;
      out_is_fp32_reg0         <= out_is_fp32;
      int32tofp32_reg0         <= int32tofp32;
      int16tofp32_reg0         <= int16tofp32;
      int32tofp16_reg0         <= int32tofp16;
      int16tofp16_reg0         <= int16tofp16;
      int8tofp16_reg0          <= int8tofp16;
      lpath_sig_shifted_reg0   <= lpath_sig_shifted;
      lpath_of_reg0            <= lpath_of;
      sig_cat0_reg             <= {sig, 1'b0};
      rpath_shamt_reg0         <= rpath_shamt;
      in_abs_reg0              <= in_abs;
      int2fp_clz_reg0          <= int2fp_clz;
      sel_lpath_reg0           <= sel_lpath;
      exp_normalized_5_reg0    <= exp_normalized_5;
      exp_normalized_8_reg0    <= exp_normalized_8;
      sig_normalized_11_reg0   <= sig_normalized_11;
      sig_normalized_24_reg0   <= sig_normalized_24;
      clz_fp16_reg0            <= in_is_fp16 & is_vfr ? clz_fp16_raw : 4'h0;
      clz_fp32_reg0            <= in_is_fp32 & is_vfr ? 8'(clz_fp32_raw) : 8'h0;
      out_exp_zero_negone_reg0 <= out_exp_zero_negone;
      out_sign_reg0            <= is_vfrsqrt7 & is_poszero_posinf & sign;
      down_exp_reg0            <= down_exp;
      may_be_subnor_reg0       <= $signed(down_exp) < 9'sd1;
      nor_of_exp_reg0          <= of_to_max ? 5'd30 : 5'd31;
      nor_of_sig_reg0          <= of_to_max ? 10'h3FF : 10'h0;
      special_case_reg0        <= fp2fp_narrow & src_exp_ones;
      fp2fp_iv_reg0            <= fp2fp_narrow & src_is_nan & ~fp_sig[22];    // sNaN
      in_isnan_neg_reg0        <= fp2fp_narrow & ~src_is_nan & fp_sign;
      in_sigNotZero_reg0       <= fp2fp_narrow & (|fp_sig);
      nor_exp_reg0             <= fp2fp_widen ? 8'(fp_exp + 8'd112) : 8'h0;
      nor_sig_reg0             <= fp2fp_widen ? fp_sig[22:13] : 10'h0;
      subnor_exp_reg0          <= 8'(8'd112 - {4'h0, subnor_shamt});
      subnor_sig_w_reg0        <= {subnor_sig_shifted[8:0], 1'b0};
      isNaN_reg0               <= fp2fp_widen & f16_exp_ones & f16_sig_nz;
      expIsOnes_reg0           <= fp2fp_widen & f16_exp_ones;
      expIsZero_reg0           <= fp2fp_widen & f16_exp_zero;
      isSubnormal_reg0         <= fp2fp_widen & f16_exp_zero & f16_sig_nz;
      sigNotZero_reg0          <= fp2fp_widen & f16_sig_nz;
    end
  end

  // ===========================================================================
  // §8 第 1 拍：f2i 右路移位、i2f 规格化左移、共用舍入器
  // ===========================================================================
  logic [24:0] rpath_sig_shifted_reg0;
  logic        rpath_sticky_reg0;
  ShiftRightJam_2 shiftRightJam (
    .io_in     (sig_cat0_reg),
    .io_shamt  (rpath_shamt_reg0),
    .io_out    (rpath_sig_shifted_reg0),
    .io_sticky (rpath_sticky_reg0)
  );

  logic [94:0] in_abs_shifted;
  logic [30:0] in_shift_reg0;     // 规格化后（隐含位已移出）的尾数候选，左对齐在 [30]
  assign in_abs_shifted = {63'h0, in_abs_reg0[31:0]} << int2fp_clz_reg0;
  assign in_shift_reg0  = (out_is_fp32_reg0 | exp_of_reg0 ? in_abs_shifted[30:0] : 31'h0)
                        | (int32tofp16_reg0 & in_abs_reg0[31:16] == 16'h0 | int16tofp16_reg0 | int8tofp16_reg0
                             ? {in_abs_shifted[14:0], 16'h0} : 31'h0);

  // i2f 指数 = bias + (源最高位) - clz：f32 目的 127+31，f16 目的 15+15
  logic [7:0] exp_raw_reg0;
  logic [5:0] exp_raw16;
  assign exp_raw16    = 6'(6'd30 - int2fp_clz_reg0);
  assign exp_raw_reg0 = (is_int2fp_reg0 & out_is_fp32_reg0 ? 8'(8'd158 - {2'b00, int2fp_clz_reg0}) : 8'h0)
                      | (is_int2fp_reg0 & out_is_fp16_reg0 ? 8'(exp_raw16) : 8'h0);

  logic f16toi16or32_reg0, i2f16_wide_reg0;
  assign f16toi16or32_reg0 = fp16toint16_reg0 | fp16toint32_reg0;
  assign i2f16_wide_reg0   = int16tofp16_reg0 | int32tofp16_reg0;

  logic [23:0] round_in_reg0;
  logic        round_roundIn_reg0, round_stickyIn_reg0;
  assign round_in_reg0 =
      (fp32toint32_reg0  ? rpath_sig_shifted_reg0[24:1]         : 24'h0)
    | (fp32toint16_reg0  ? 24'(rpath_sig_shifted_reg0[24:9])    : 24'h0)
    | (f16toi16or32_reg0 ? 24'(rpath_sig_shifted_reg0[24:14])   : 24'h0)
    | (fp16toint8_reg0   ? 24'(rpath_sig_shifted_reg0[24:17])   : 24'h0)
    | (int16tofp32_reg0  ? 24'(in_shift_reg0[30:15])            : 24'h0)
    | (int32tofp32_reg0  ? 24'(in_shift_reg0[30:8])             : 24'h0)
    | (int8tofp16_reg0   ? 24'(in_shift_reg0[30:23])            : 24'h0)
    | (i2f16_wide_reg0   ? 24'(in_shift_reg0[30:21])            : 24'h0);
  assign round_roundIn_reg0 =
      fp32toint32_reg0 & rpath_sig_shifted_reg0[0]  | fp32toint16_reg0 & rpath_sig_shifted_reg0[8]
    | f16toi16or32_reg0 & rpath_sig_shifted_reg0[13] | fp16toint8_reg0 & rpath_sig_shifted_reg0[16]
    | int16tofp32_reg0 & in_shift_reg0[14] | int32tofp32_reg0 & in_shift_reg0[7]
    | int8tofp16_reg0 & in_shift_reg0[22]  | i2f16_wide_reg0 & in_shift_reg0[20];
  assign round_stickyIn_reg0 =
      fp32toint32_reg0  & rpath_sticky_reg0
    | fp32toint16_reg0  & (rpath_sticky_reg0 | (|rpath_sig_shifted_reg0[7:0]))
    | f16toi16or32_reg0 & (rpath_sticky_reg0 | (|rpath_sig_shifted_reg0[12:0]))
    | fp16toint8_reg0   & (rpath_sticky_reg0 | (|rpath_sig_shifted_reg0[15:0]))
    | int16tofp32_reg0  & (|in_shift_reg0[14:0])
    | int32tofp32_reg0  & (|in_shift_reg0[6:0])
    | int8tofp16_reg0   & (|in_shift_reg0[22:0])
    | i2f16_wide_reg0   & (|in_shift_reg0[19:0]);

  logic rnd_inexact, rnd_up;
  RoundingUnit_8 rounder (
    .io_in       (round_in_reg0),
    .io_roundIn  (round_roundIn_reg0),
    .io_stickyIn (round_stickyIn_reg0),
    .io_signIn   ((is_fp2int_reg0 | is_int2fp_reg0) & sign_reg0),
    .io_rm       (rm_reg0),
    .io_inexact  (rnd_inexact),
    .io_r_up     (rnd_up)
  );

  logic [23:0] out_reg0;
  logic        cout_reg0;
  assign out_reg0  = is_fp2int_reg0 | is_int2fp_reg0
                   ? (rnd_up ? 24'(round_in_reg0 + 24'h1) : round_in_reg0) : 24'h0;
  assign cout_reg0 = rnd_up & ((fp32toint32_reg0 | fp16toint32_reg0) & (&round_in_reg0)
                             | (fp32toint16_reg0 | fp16toint16_reg0) & (&round_in_reg0[14:0])
                             | fp16toint8_reg0  & (&round_in_reg0[6:0])
                             | int16tofp32_reg0 & (&round_in_reg0[15:0])
                             | int32tofp32_reg0 & (&round_in_reg0[22:0])
                             | int8tofp16_reg0  & (&round_in_reg0[7:0])
                             | i2f16_wide_reg0  & (&round_in_reg0[9:0]));

  logic [7:0]  exp_reg0;
  logic [31:0] sig_reg0;
  assign exp_reg0 = is_int2fp_reg0 & in_orR_reg0 ? 8'(exp_raw_reg0 + {7'h0, cout_reg0}) : 8'h0;
  assign sig_reg0 = (fp32toint32_reg0  ? {7'h0, cout_reg0, out_reg0}        : 32'h0)
                  | (fp32toint16_reg0  ? {8'h0, out_reg0}                   : 32'h0)
                  | (f16toi16or32_reg0 ? {20'h0, cout_reg0, out_reg0[10:0]} : 32'h0)
                  | (fp16toint8_reg0   ? {21'h0, out_reg0[10:0]}            : 32'h0)
                  | (is_int2fp_reg0    ? 32'(out_reg0)                      : 32'h0);

  // ===========================================================================
  // §9 第 1 拍：f2i / i2f 的标志
  // ===========================================================================
  logic [7:0] in_exp_reg0;
  logic       rpath_ix_reg0, rpath_iv_reg0, rpath_pos_of_reg0, rpath_neg_of_reg0, rpath_of_reg0;
  assign in_exp_reg0   = in_reg0[31:24];
  assign rpath_ix_reg0 = is_fp2int_reg0 & ~fp16toint8_reg0 & rnd_inexact
                       | is_fp2int_reg0 & fp16toint8_reg0 & (rnd_inexact | (|rpath_sig_shifted_reg0[7:0]));
  assign rpath_iv_reg0 = is_fp2int_reg0 & ~is_signed_int_reg0 & in_reg0[32] & (|sig_reg0);
  // 变窄的两种（f32->i16、f16->i8）在右路才可能越界：正数到 2^(n-1)（有符号）/ 2^n（无符号）
  assign rpath_pos_of_reg0 = is_fp2int_reg0 & ~in_reg0[32]
    & (is_signed_int_reg0
         ? fp32toint16_reg0 & (in_exp_reg0 == 8'd142 | in_exp_reg0 == 8'd141 & cout_reg0)
           | fp16toint8_reg0 & (in_exp_reg0 == 8'd22 | in_exp_reg0 == 8'd21 & cout_reg0)
         : fp32toint16_reg0 & in_exp_reg0 == 8'd142 & cout_reg0
           | fp16toint8_reg0 & in_exp_reg0 == 8'd22 & cout_reg0);
  assign rpath_neg_of_reg0 = is_fp2int_reg0 & in_reg0[32]
    & (fp32toint16_reg0 & in_exp_reg0 == 8'd142 & ((|round_in_reg0[14:0]) | rnd_up)
     | fp16toint8_reg0  & in_exp_reg0 == 8'd22  & ((|round_in_reg0[6:0])  | rnd_up));
  assign rpath_of_reg0 = (fp32toint16_reg0 | fp16toint8_reg0) & (rpath_neg_of_reg0 | rpath_pos_of_reg0)
                       | (fp32toint32_reg0 | fp16toint16_reg0 | fp16toint32_reg0) & cout_reg0;

  logic of_reg0, iv_reg0, ix_reg0;
  assign of_reg0 = is_fp2int_reg0 & (exp_of_reg0 | sel_lpath_reg0 & lpath_of_reg0 | ~sel_lpath_reg0 & rpath_of_reg0)
                 | is_int2fp_reg0 & out_is_fp32_reg0 & (exp_reg0 == 8'd255)
                 | is_int2fp_reg0 & int32tofp16_reg0 & (exp_of_reg0 | exp_reg0 == 8'd31)
                 | is_int2fp_reg0 & ~out_is_fp32_reg0 & ~int32tofp16_reg0 & (exp_reg0 == 8'd31);
  assign iv_reg0 = is_fp2int_reg0 & (of_reg0 | sel_lpath_reg0 & lpath_iv_reg0 | ~sel_lpath_reg0 & rpath_iv_reg0);
  assign ix_reg0 = is_fp2int_reg0 & (~iv_reg0 & ~sel_lpath_reg0 & rpath_ix_reg0)
                 | is_int2fp_reg0 & (out_is_fp32_reg0 | int16tofp16_reg0 | int8tofp16_reg0) & rnd_inexact
                 | int32tofp16_reg0 & (exp_of_reg0 | rnd_inexact);

  // i32 -> f16 上溢的结果：按舍入方向给最大有限数或 Inf。
  // Scala 写成单路 Mux1H(Seq(is_int2fp_reg0), ...)，而单路 Mux1H 直接返回那一路的值 ——
  // is_int2fp_reg0 并不门控（FM 首跑因为这里多加了门控而在 result0_reg1[15:0] 上 16 点 failing）。
  logic        rmin_reg0;
  logic [15:0] result_fp;
  assign rmin_reg0 = rm_reg0 == 3'h1 | rm_reg0 == 3'h2 & ~sign_reg0 | rm_reg0 == 3'h3 & sign_reg0;
  assign result_fp = {sign_reg0, rmin_reg0 ? 15'h7BFF : 15'h7C00};

  // f2i 整数结果：左路或右路的绝对值，有符号负数取负
  logic [31:0] int_abs_reg0, int_reg0;
  logic        negate_reg0;
  assign int_abs_reg0 = (is_fp2int_reg0 & sel_lpath_reg0  ? lpath_sig_shifted_reg0 : 32'h0)
                      | (is_fp2int_reg0 & ~sel_lpath_reg0 ? sig_reg0               : 32'h0);
  assign negate_reg0  = in_reg0[32] & is_signed_int_reg0;
  assign int_reg0 =
      (fp32toint16_reg0 | fp16toint16_reg0
         ? 32'(negate_reg0 ? 16'(16'h0 - int_abs_reg0[15:0]) : int_abs_reg0[15:0]) : 32'h0)
    | (fp32toint32_reg0 | fp16toint32_reg0
         ? (negate_reg0 ? 32'(32'h0 - int_abs_reg0) : int_abs_reg0)               : 32'h0)
    | (fp16toint8_reg0
         ? 32'(negate_reg0 ? 8'(8'h0 - int_abs_reg0[7:0]) : int_abs_reg0[7:0])    : 32'h0);

  // ===========================================================================
  // §10 第 1 拍：vfr 查表与结果
  // ===========================================================================
  logic rsqrt16_reg0, rec16_reg0, rsqrt32_reg0, rec32_reg0;
  assign rsqrt16_reg0 = in_is_fp16_reg0 & is_vfrsqrt7_reg0;
  assign rec16_reg0   = in_is_fp16_reg0 & is_vfrec7_reg0;
  assign rsqrt32_reg0 = in_is_fp32_reg0 & is_vfrsqrt7_reg0;
  assign rec32_reg0   = in_is_fp32_reg0 & is_vfrec7_reg0;

  logic [25:0]  sig16_shifted;
  logic [278:0] sig32_shifted;
  logic [6:0]   sig_in7;
  assign sig16_shifted = {15'h0, sig_normalized_11_reg0}  << (is_normal_reg0 ? 4'h0 : clz_fp16_reg0);
  assign sig32_shifted = {255'h0, sig_normalized_24_reg0} << (is_normal_reg0 ? 8'h0 : clz_fp32_reg0);
  assign sig_in7 = (rsqrt16_reg0 ? {exp_normalized_5_reg0[0], sig16_shifted[9:4]}   : 7'h0)
                 | (rec16_reg0   ? sig16_shifted[9:3]                               : 7'h0)
                 | (rsqrt32_reg0 ? {exp_normalized_8_reg0[0], sig32_shifted[22:17]} : 7'h0)
                 | (rec32_reg0   ? sig32_shifted[22:16]                             : 7'h0);

  logic [6:0] rsqrt7_out, rec7_out, sig_out7_reg0;
  Rsqrt7Table vfrsqrt7Table (
    .src (sig_in7),
    .out (rsqrt7_out)
  );
  Rec7Table vfrec7Table (
    .src (sig_in7),
    .out (rec7_out)
  );
  assign sig_out7_reg0 = (is_vfrsqrt7_reg0 ? rsqrt7_out : 7'h0) | (is_vfrec7_reg0 ? rec7_out : 7'h0);

  // rec7 非规格化结果：原指数 b+1 -> 右移 2（{01,表,0..}）；b-1 -> 右移 1（{1,表,0..}）；其余同 b+1
  logic rec_bplus1, rec_bminus1;
  assign rec_bplus1  = is_neg2_bplus1_b_reg0 | is_pos2_b_bplus1_reg0;
  assign rec_bminus1 = is_neg2_b_bminus1_reg0 | is_pos2_bminus1_b_reg0;

  logic [9:0]  out_sig_10_reg0;
  logic [22:0] out_sig_23_reg0;
  assign out_sig_10_reg0 =
      (rec16_reg0 & out_exp_zero_negone_reg0 & rec_bplus1                  ? {2'b01, sig_out7_reg0, 1'b0}  : 10'h0)
    | (rec16_reg0 & out_exp_zero_negone_reg0 & rec_bminus1                 ? {1'b1, sig_out7_reg0, 2'b00}  : 10'h0)
    | (rec16_reg0 & out_exp_zero_negone_reg0 & ~(rec_bplus1 | rec_bminus1) ? {2'b01, sig_out7_reg0, 1'b0}  : 10'h0)
    | (rec16_reg0 & ~out_exp_zero_negone_reg0                              ? {sig_out7_reg0, 3'h0}         : 10'h0);
  assign out_sig_23_reg0 =
      (rec32_reg0 & out_exp_zero_negone_reg0 & rec_bplus1                  ? {2'b01, sig_out7_reg0, 14'h0} : 23'h0)
    | (rec32_reg0 & out_exp_zero_negone_reg0 & rec_bminus1                 ? {1'b1, sig_out7_reg0, 15'h0}  : 23'h0)
    | (rec32_reg0 & out_exp_zero_negone_reg0 & ~(rec_bplus1 | rec_bminus1) ? {2'b01, sig_out7_reg0, 14'h0} : 23'h0)
    | (rec32_reg0 & ~out_exp_zero_negone_reg0                              ? {sig_out7_reg0, 16'h0}        : 23'h0);

  logic [15:0] fp_result_fp16;
  logic [31:0] fp_result_fp32;
  assign fp_result_fp16 = (rsqrt16_reg0 ? {out_sign_reg0, out_exp_fp16_reg0, sig_out7_reg0, 3'h0}  : 16'h0)
                        | (rec16_reg0   ? {sign_reg0, out_exp_fp16_reg0, out_sig_10_reg0}          : 16'h0);
  assign fp_result_fp32 = (rsqrt32_reg0 ? {out_sign_reg0, out_exp_fp32_reg0, sig_out7_reg0, 16'h0} : 32'h0)
                        | (rec32_reg0   ? {sign_reg0, out_exp_fp32_reg0, out_sig_23_reg0}          : 32'h0);

  // ===========================================================================
  // §11 第 1 拍：f2f 变窄（两个 10 位舍入器）与变宽
  // ===========================================================================
  logic nor_inexact, nor_up, subnor_inexact, subnor_up;
  RoundingUnit_9 nor_rounder (
    .io_in       (nor_in_reg0),
    .io_roundIn  (nor_roundBit_reg0),
    .io_stickyIn (nor_stickyBit_reg0),
    .io_signIn   (nor_signBit_reg0),
    .io_rm       (rm_reg0),
    .io_inexact  (nor_inexact),
    .io_r_up     (nor_up)
  );
  RoundingUnit_9 subnor_rounder (
    .io_in       (subnor_in_reg0),
    .io_roundIn  (subnor_roundBit_reg0),
    .io_stickyIn (subnor_stickyBit_reg0),
    .io_signIn   (subnor_signBit_reg0),
    .io_rm       (rm_reg0),
    .io_inexact  (subnor_inexact),
    .io_r_up     (subnor_up)
  );

  // 正常：尾数进位到指数；上溢 = 舍入后指数 > 30
  logic [9:0] nor_sig_rounded, subnor_sig_rounded;
  logic       nor_cout, subnor_cout, nor_of_reg0, exp_uf_reg0;
  logic [8:0] nor_exp_rounded;
  assign nor_sig_rounded = nor_up ? 10'(nor_in_reg0 + 10'h1) : nor_in_reg0;
  assign nor_cout        = nor_up & (&nor_in_reg0);
  assign nor_exp_rounded = nor_cout ? 9'(down_exp_reg0 + 9'h1) : down_exp_reg0;
  assign nor_of_reg0     = nor_cout ? $signed(down_exp_reg0) > 9'sd29 : $signed(down_exp_reg0) > 9'sd30;
  assign exp_uf_reg0     = nor_cout ? $signed(down_exp_reg0) < 9'sd0  : $signed(down_exp_reg0) < 9'sd1;
  // 非规格化：尾数满了进位就成了最小规格化数（指数 1）
  assign subnor_sig_rounded = subnor_up ? 10'(subnor_in_reg0 + 10'h1) : subnor_in_reg0;
  assign subnor_cout        = subnor_up & (&subnor_in_reg0);

  logic [4:0] common_exp;
  logic [9:0] common_sig;
  assign common_exp = (~may_be_subnor_reg0 & nor_of_reg0  ? nor_of_exp_reg0      : 5'h0)
                    | (~may_be_subnor_reg0 & ~nor_of_reg0 ? nor_exp_rounded[4:0] : 5'h0)
                    | (may_be_subnor_reg0                 ? {4'h0, subnor_cout}  : 5'h0);
  assign common_sig = (~may_be_subnor_reg0 & nor_of_reg0  ? nor_of_sig_reg0      : 10'h0)
                    | (~may_be_subnor_reg0 & ~nor_of_reg0 ? nor_sig_rounded      : 10'h0)
                    | (may_be_subnor_reg0                 ? subnor_sig_rounded   : 10'h0);

  logic fp2fp_n_reg0, fp2fp_w_reg0;
  logic fp2fp_of_reg0, fp2fp_uf_reg0, fp2fp_ix_reg0;
  assign fp2fp_n_reg0  = is_fp2fp_reg0 & is_narrow_reg0;
  assign fp2fp_w_reg0  = is_fp2fp_reg0 & is_widen_reg0;
  assign fp2fp_of_reg0 = fp2fp_n_reg0 & ~special_case_reg0 & nor_of_reg0;
  assign fp2fp_uf_reg0 = fp2fp_n_reg0 & ~special_case_reg0 & may_be_subnor_reg0 & subnor_inexact & exp_uf_reg0;
  assign fp2fp_ix_reg0 = fp2fp_n_reg0 & ~special_case_reg0
                       & (~may_be_subnor_reg0 & (nor_of_reg0 | nor_inexact) | may_be_subnor_reg0 & subnor_inexact);

  // 变窄结果：特殊值（指数全 1：Inf/NaN）直接给全 1 指数，NaN 时尾数最高位置 1（规范化）
  logic [15:0] fp2fp_narrow_result;
  assign fp2fp_narrow_result = {in_isnan_neg_reg0,
                                special_case_reg0 ? 5'h1F : common_exp,
                                special_case_reg0 ? {in_sigNotZero_reg0, 9'h0} : common_sig};

  // 变宽结果：指数四选一（全 1 / 零 / 非规格化规格化 / 正常），「零」档给 0
  logic [7:0]  widen_exp;
  logic [22:0] widen_sig;
  assign widen_exp = (expIsOnes_reg0                     ? 8'hFF           : 8'h0)
                   | (isSubnormal_reg0                   ? subnor_exp_reg0 : 8'h0)
                   | (~expIsOnes_reg0 & ~expIsZero_reg0  ? nor_exp_reg0    : 8'h0);
  assign widen_sig = (expIsOnes_reg0                     ? {sigNotZero_reg0, 22'h0}   : 23'h0)
                   | (expIsZero_reg0                     ? {subnor_sig_w_reg0, 13'h0} : 23'h0)
                   | (~expIsOnes_reg0 & ~expIsZero_reg0  ? {nor_sig_reg0, 13'h0}      : 23'h0);

  logic [31:0] fp2fp_widen_result;
  assign fp2fp_widen_result = {~isNaN_reg0 & sign_reg0, widen_exp, widen_sig};

  // ===========================================================================
  // §12 第 1 拍：24 类结果 / 10 类 fflags（Mux1H）
  // ===========================================================================
  logic vfr_nan_case, vfr_normal_case;
  assign vfr_nan_case    = is_vfrsqrt7_reg0 & (is_nan_reg0 | is_neginf_negzero_reg0) | is_vfrec7_reg0 & is_nan_reg0;
  assign vfr_normal_case = is_vfrsqrt7_reg0 & ~(is_nan_reg0 | is_neginf_negzero_reg0 | is_inf_reg0
                                               | is_negzero_reg0 | is_poszero_reg0)
                         | is_vfrec7_reg0 & ~(is_nan_reg0 | is_inf_reg0 | is_negzero_reg0 | is_poszero_reg0
                                             | is_neg2_negbminus1_negzero_reg0 | is_pos2_poszero_negbminus1_reg0);

  // result1H 的位序与 Scala VecInit 一致：[0] 整数结果 ... [23] f2f 变宽
  logic [23:0] result1H;
  assign result1H = {
    fp2fp_w_reg0,                                                         // 23
    fp2fp_n_reg0,                                                         // 22
    rec32_reg0 & is_pos2_poszero_negbminus1_reg0,                         // 21 f32 rec7 正上溢
    rec32_reg0 & is_neg2_negbminus1_negzero_reg0,                         // 20 f32 rec7 负上溢
    rec32_reg0 & (is_negzero_reg0 | is_poszero_reg0),                     // 19 f32 rec7(±0)
    rec32_reg0 & is_inf_reg0,                                             // 18 f32 rec7(±Inf)
    in_is_fp32_reg0 & vfr_normal_case,                                    // 17 f32 正常估算
    rsqrt32_reg0 & (is_negzero_reg0 | is_poszero_reg0),                   // 16 f32 rsqrt7(±0)
    rsqrt32_reg0 & is_inf_reg0,                                           // 15 f32 rsqrt7(±Inf)
    in_is_fp32_reg0 & vfr_nan_case,                                       // 14 f32 NaN
    rec16_reg0 & is_pos2_poszero_negbminus1_reg0,                         // 13
    rec16_reg0 & is_neg2_negbminus1_negzero_reg0,                         // 12
    rec16_reg0 & (is_negzero_reg0 | is_poszero_reg0),                     // 11
    rec16_reg0 & is_inf_reg0,                                             // 10
    in_is_fp16_reg0 & vfr_normal_case,                                    // 9
    rsqrt16_reg0 & (is_negzero_reg0 | is_poszero_reg0),                   // 8
    rsqrt16_reg0 & is_inf_reg0,                                           // 7
    in_is_fp16_reg0 & vfr_nan_case,                                       // 6
    int32tofp16_reg0 & ~of_reg0 | int16tofp16_reg0,                       // 5 i32/i16 -> f16
    int8tofp16_reg0,                                                      // 4 i8 -> f16
    int32tofp16_reg0 & of_reg0,                                           // 3 i32 -> f16 上溢
    int16tofp32_reg0,                                                     // 2 i16 -> f32
    int32tofp32_reg0,                                                     // 1 i32 -> f32
    is_fp2int_reg0                                                        // 0 f2i
  };

  logic rdn_rtz, rup_rtz;
  assign rup_rtz = rm_reg0 == 3'h3 | rm_reg0 == 3'h1;
  assign rdn_rtz = rm_reg0 == 3'h2 | rm_reg0 == 3'h1;

  logic [31:0] result0;
  assign result0 =
      (result1H[0]  ? (iv_reg0 ? max_min_int_reg0 : int_reg0)                     : 32'h0)
    | (result1H[1]  ? {sign_reg0, exp_reg0, sig_reg0[22:0]}                       : 32'h0)
    | (result1H[2]  ? {sign_reg0, exp_reg0, sig_reg0[15:0], 7'h0}                 : 32'h0)
    | (result1H[3]  ? 32'(result_fp)                                              : 32'h0)
    | (result1H[4]  ? {16'h0, sign_reg0, exp_reg0[4:0], sig_reg0[7:0], 2'b00}     : 32'h0)
    | (result1H[5]  ? {16'h0, sign_reg0, exp_reg0[4:0], sig_reg0[9:0]}            : 32'h0)
    // —— f16 估算 ——
    | (result1H[6]  ? 32'h00007E00                                                : 32'h0)
    | (result1H[7]  ? (is_neginf_reg0 ? 32'h00007E00 : 32'h0)                     : 32'h0)
    | (result1H[8]  ? {16'h0, is_negzero_reg0, 15'h7C00}                          : 32'h0)
    | (result1H[9]  ? 32'(fp_result_fp16)                                         : 32'h0)
    | (result1H[10] ? (is_neginf_reg0 ? 32'h00008000 : 32'h0)                     : 32'h0)
    | (result1H[11] ? (is_negzero_reg0 ? 32'h0000FC00 : 32'h00007C00)             : 32'h0)
    | (result1H[12] ? (rup_rtz ? 32'h0000FBFF : 32'h0000FC00)                     : 32'h0)
    | (result1H[13] ? (rdn_rtz ? 32'h00007BFF : 32'h00007C00)                     : 32'h0)
    // —— f32 估算 ——
    | (result1H[14] ? 32'h7FC00000                                                : 32'h0)
    | (result1H[15] ? (is_neginf_reg0 ? 32'h7FC00000 : 32'h0)                     : 32'h0)
    | (result1H[16] ? {is_negzero_reg0, 31'h7F800000}                             : 32'h0)
    | (result1H[17] ? fp_result_fp32                                              : 32'h0)
    | (result1H[18] ? (is_neginf_reg0 ? 32'h80000000 : 32'h0)                     : 32'h0)
    | (result1H[19] ? (is_negzero_reg0 ? 32'hFF800000 : 32'h7F800000)             : 32'h0)
    | (result1H[20] ? (rup_rtz ? 32'hFF7FFFFF : 32'hFF800000)                     : 32'h0)
    | (result1H[21] ? (rdn_rtz ? 32'h7F7FFFFF : 32'h7F800000)                     : 32'h0)
    // —— f2f ——
    | (result1H[22] ? 32'(fp2fp_narrow_result)                                    : 32'h0)
    | (result1H[23] ? fp2fp_widen_result                                          : 32'h0);

  // fflags = {NV, DZ, OF, UF, NX}
  logic [4:0] fflags0;
  assign fflags0 =
      (is_fp2int_reg0 ? {iv_reg0, 3'b000, ix_reg0}                               : 5'h0)
    | (is_int2fp_reg0 ? {2'b00, of_reg0, 1'b0, ix_reg0}                          : 5'h0)
    | (is_vfrsqrt7_reg0 & (is_nan_reg0 | is_neginf_negzero_reg0)
                      ? {is_snan_reg0 | is_neginf_negzero_reg0, 4'h0}            : 5'h0)
    | (is_vfrsqrt7_reg0 & is_inf_reg0 ? {is_neginf_reg0, 4'h0}                   : 5'h0)
    | ((is_vfrsqrt7_reg0 | is_vfrec7_reg0) & (is_negzero_reg0 | is_poszero_reg0) ? 5'b01000 : 5'h0)
    | (is_vfrec7_reg0 & is_nan_reg0 ? {is_snan_reg0, 4'h0}                       : 5'h0)
    | (is_vfrec7_reg0 & (is_neg2_negbminus1_negzero_reg0 | is_pos2_poszero_negbminus1_reg0)
                      ? 5'b00101                                                 : 5'h0)
    | (fp2fp_n_reg0 ? {fp2fp_iv_reg0, 1'b0, fp2fp_of_reg0, fp2fp_uf_reg0, fp2fp_ix_reg0} : 5'h0)
    | (fp2fp_w_reg0 ? {is_snan_reg0, 4'h0}                                       : 5'h0);

  // ===========================================================================
  // §13 s2 输出寄存器（fireReg_last_r 使能）
  // ===========================================================================
  logic [31:0] result0_reg1;
  logic [4:0]  fflags0_reg1;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      result0_reg1 <= 32'h0;
    else if (fireReg_last_r)
      result0_reg1 <= result0;
  end

  always_ff @(posedge clock) begin
    if (fireReg_last_r)
      fflags0_reg1 <= fflags0;
  end

  assign result_out = result0_reg1;
  assign fflags_out = fflags0_reg1;

endmodule

module CVT32(
  input         clock,
  input         reset,
  input         io_fire,
  input  [31:0] io_src,
  input  [7:0]  io_opType,
  input  [1:0]  io_sew,
  input  [2:0]  io_rm,
  output [31:0] io_result,
  output [4:0]  io_fflags
);

  xs_CVT32_core u_core (
    .clock      (clock),
    .reset      (reset),
    .fire       (io_fire),
    .src_in     (io_src),
    .op_type    (io_opType),
    .sew        (io_sew),
    .rm_in      (io_rm),
    .result_out (io_result),
    .fflags_out (io_fflags)
  );

endmodule
