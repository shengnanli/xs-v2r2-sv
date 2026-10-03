// FP_INCVT.sv —— 「浮点源」转换单元（yunsuan FP_INCVT，2 拍流水）：fp→int、fp→fp 宽窄转换、fround、fcvtmod
// -----------------------------------------------------------------------------
// 在哪一层：CVT64（标量 FCVT 下的 FPCVT 兄弟）与 CVT64_1（向量 VCVT 64 位通道）都把它当作
//   「源操作数是浮点」的那一支；整数源走 INT2FP，vfrec7/vfrsqrt7 走 Estimate7。
// 输入：src 低位放一个 f16/f32/f64（input1H 独热：[1]=f16 [2]=f32 [3]=f64，[0]=8 位格式不支持）；
//   output1H 独热选目标宽度（fp 目标：[1]=f16 [2]=f32 [3]=f64；int 目标：[0..3]=8/16/32/64 位）。
//   opType[6]=目标是浮点，opType[4:3] 区分 widen(01)/narrow(10)/cross(11)，opType[0]=有符号整数；
//   isFround=fround/froundnx（[1]=nx 版），isFcvtmod=fcvtmod.w.d，isFpToVecInst=标量→向量要检查 NaN-box。
// 机制（Scala: yunsuan/vector/VectorConvert/CVT64.scala class FP_INCVT）：
//   第 0 拍：把源浮点按 f64 的位置摆好（指数低位对齐、尾数高位对齐，不改偏置）→ 解码类别；
//     备好指数加法器两个加数、尾数左对齐 + CLZ（widen 的非规格数要规格化）、右移量（narrow/fp→int/fround
//     要右移出整数位或目标尾数位），以及 fround 的掩码量、fcvtmod 的移位结果，统统落 s1 寄存器。
//   第 1 拍：指数相加；右移 + 舍入（RoundingUnit_3，64 位）；narrow 结果落进非规格区时另用一套
//     23 位舍入（RoundingUnit_4）；五条路径各自出结果与 fflags，按优先级 widen > narrow > fround
//     > fcvtmod > fp→int 选一个落 s2 结果寄存器。
// 怪癖（照 golden，bug-for-bug）：
//   - 所有 Mux1H 都是「各路与门再按位或」，非独热的 input1H/output1H 会把多路或在一起；
//   - fround 的「保持原值」分支用的 oldInputReg 是三种格式或在一起的那一份；
//   - fcvtmod 的移位器只在指数距 1075 不足 64 时移，否则清零（左移太多）或全舍（右移太多，NX=1）；
//   - 结果/标志寄存器只在 fireReg_last_r（fire 打一拍）时更新；复位域：控制类与结果异步复位，
//     指数加数、前导零、右移输入/量、s1_fpCanonicalNAN 不复位（Scala RegEnable 无初值）。
// 子模块：CLZ_6（64 位前导零）、ShiftRightJam（65 位右移带 sticky）、RoundingUnit_3（64 位舍入判定）、
//   RoundingUnit_4（23 位舍入判定）—— 均为本仓已签核重写件。
// golden 对照：G1-canonical/golden-rtl/FP_INCVT.sv
// =============================================================================

module xs_FP_INCVT_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,               // 本拍输入有效
  input  logic [63:0] src,                // 浮点源（低位对齐）
  input  logic [7:0]  op_type,            // [6]=目标是浮点 [4:3]=widen/narrow/cross [0]=有符号整数
  input  logic [2:0]  rm_in,              // 舍入模式（RNE/RTZ/RDN/RUP/RMM/ROD=6）
  input  logic [3:0]  in_width_1h,        // 源格式独热：[1]=f16 [2]=f32 [3]=f64
  input  logic [3:0]  out_width_1h,       // 目标宽度独热：fp [1..3]=f16/f32/f64，int [0..3]=8/16/32/64
  input  logic        is_fp_to_vec_inst,  // 标量浮点送向量：窄浮点必须 NaN-box，否则当作规范 NaN
  input  logic [1:0]  is_fround,          // [0]=fround [1]=froundnx
  input  logic        is_fcvtmod,         // fcvtmod.w.d
  output logic [63:0] result_out,
  output logic [4:0]  fflags_out          // {NV, DZ, OF, UF, NX}
);

  // ===========================================================================
  // §0 第 0 拍：把源浮点摆到 f64 的位置上并解码
  //    f16 的 5 位指数放在 [56:52]、10 位尾数放在 [51:42]；f32 的 8 位指数在 [59:52]、尾数在 [51:29]。
  //    指数只是低位对齐，偏置不变——后面每种格式各用自己的指数宽度去看 [62:52] 的低几位。
  // ===========================================================================
  logic [63:0] src_as_f64;
  logic [10:0] exp_src;        // 源指数（按源格式的宽度，高位补 0）
  logic [51:0] frac_src;       // 源尾数（高位对齐到 [51]）
  logic        sign_src_next;

  assign src_as_f64 =
      (in_width_1h[1] ? {src[15], 6'h0, src[14:0], 42'h0} : 64'h0)
    | (in_width_1h[2] ? {src[31], 3'h0, src[30:0], 29'h0} : 64'h0)
    | (in_width_1h[3] ? src                               : 64'h0);
  assign exp_src       = src_as_f64[62:52];
  assign frac_src      = src_as_f64[51:0];
  assign sign_src_next = src_as_f64[63];

  // 三个解码位：指数非零 / 指数全 1 / 尾数非零（各格式只看自己的位宽，Mux1H）
  logic exp_not_zero_next, exp_is_ones_next, frac_not_zero_next;
  assign exp_not_zero_next =
      in_width_1h[1] & (|exp_src[4:0]) | in_width_1h[2] & (|exp_src[7:0]) | in_width_1h[3] & (|exp_src);
  assign exp_is_ones_next =
      in_width_1h[1] & (&exp_src[4:0]) | in_width_1h[2] & (&exp_src[7:0]) | in_width_1h[3] & (&exp_src);
  assign frac_not_zero_next =
      in_width_1h[1] & (|frac_src[51:42]) | in_width_1h[2] & (|frac_src[51:29]) | in_width_1h[3] & (|frac_src);

  logic is_nan_next, is_zero_next, is_subnormal_next, is_normal_next, is_inf_next, is_snan_next;
  assign is_nan_next       = exp_is_ones_next & frac_not_zero_next;
  assign is_zero_next      = ~exp_not_zero_next & ~frac_not_zero_next;
  assign is_subnormal_next = ~exp_not_zero_next & frac_not_zero_next;
  assign is_normal_next    = ~exp_is_ones_next & exp_not_zero_next;
  assign is_inf_next       = exp_is_ones_next & ~frac_not_zero_next;
  assign is_snan_next      = is_nan_next & ~frac_src[51];       // 尾数最高位为 0 的 NaN 是 sNaN

  // 操作种类（第 0 拍）。cross：f16<->f64 跨两档，High=加宽到 f64，Low=收窄到 f16。
  logic out_is_fp_next;
  logic is_cross_low_raw;      // 不看 out_is_fp 也已含 opType[6] 的 crossLow 判定（右移量那里直接用它）
  logic is_fp_widen_next, is_fp_narrow_next, is_fp2int_next, is_fp_cross_high_next, is_fp_cross_low_next;
  logic is_fround_any_next;
  assign out_is_fp_next        = op_type[6];
  assign is_cross_low_raw      = op_type[4] & op_type[3] & out_is_fp_next & out_width_1h[1];
  assign is_fp_widen_next      = out_is_fp_next & ~op_type[4] & op_type[3];
  assign is_fp_narrow_next     = out_is_fp_next & op_type[4] & ~op_type[3];
  assign is_fp2int_next        = ~out_is_fp_next;
  assign is_fp_cross_high_next = out_is_fp_next & op_type[4] & op_type[3] & out_width_1h[3];
  assign is_fp_cross_low_next  = out_is_fp_next & is_cross_low_raw;
  assign is_fround_any_next    = |is_fround;

  // 标量窄浮点送向量时必须 NaN-box（高位全 1），否则按 RISC-V 规定当作规范 NaN
  logic fp_canonical_nan_next;
  assign fp_canonical_nan_next =
      is_fp_to_vec_inst & (in_width_1h[1] & src[63:16] != 48'hFFFF_FFFF_FFFF
                         | in_width_1h[2] & src[63:32] != 32'hFFFF_FFFF);

  // ---------------------------------------------------------------------------
  // §0.1 指数加法器的两个加数（第 1 拍相加，13 位够用）
  //   widen：  in0 = 偏置差（f16→f32 112，f32→f64 896），in1 = 源指数（非规格数：-前导零）
  //   crossH： in0 = 1008（f16→f64），in1 同 widen
  //   narrow/crossL/fp→int：in0 = 源指数（非规格数取 1），in1 = -(偏置差 / 1008 / 源偏置)
  // ---------------------------------------------------------------------------
  logic [63:0] frac_left_next;     // 尾数顶格左对齐到 64 位
  logic [6:0]  lead_zeros_next;    // frac_left_next 的前导零（只对非规格数有意义）
  assign frac_left_next = {frac_src, 12'h0};

  CLZ_6 leadZerosNext_clz (
    .io_in  (frac_left_next),
    .io_out (lead_zeros_next)
  );

  logic [9:0]  narrow_bias_delta;  // narrow 的偏置差，按目标格式
  logic [9:0]  src_bias;           // fp→int 用的源偏置
  logic [9:0]  minus_operand;      // 要取负的那个量（Mux1H）
  logic [10:0] minus_exp11;
  logic [12:0] minus_exp;          // -(minus_operand)，11 位补码符号扩展到 13 位
  logic [11:0] exp_or_one;         // 源指数；非规格数的「真指数」按 1 算
  logic [12:0] exp_adder_in0_next, exp_adder_in1_next;

  assign narrow_bias_delta = (out_width_1h[1] ? 10'h070 : 10'h0) | (out_width_1h[2] ? 10'h380 : 10'h0);
  assign src_bias =
      (in_width_1h[1] ? 10'd15 : 10'h0) | (in_width_1h[2] ? 10'd127 : 10'h0) | (in_width_1h[3] ? 10'd1023 : 10'h0);
  assign minus_operand =
      (is_fp_widen_next | is_fp_cross_high_next ? {3'h0, lead_zeros_next} : 10'h0)
    | (is_fp_narrow_next                        ? narrow_bias_delta       : 10'h0)
    | (is_fp_cross_low_next                     ? 10'h3F0                 : 10'h0)
    | (is_fp2int_next                           ? src_bias                : 10'h0);
  assign minus_exp11 = 11'(~{1'b0, minus_operand} + 11'h1);
  assign minus_exp   = {{2{minus_exp11[10]}}, minus_exp11};
  assign exp_or_one  = is_subnormal_next ? 12'h1 : {1'b0, exp_src};

  assign exp_adder_in0_next =
      (is_fp_widen_next ? 13'((out_width_1h[2] ? 10'h070 : 10'h0) | (out_width_1h[3] ? 10'h380 : 10'h0)) : 13'h0)
    | (is_fp_cross_high_next                     ? 13'h3F0          : 13'h0)
    | (is_fp_narrow_next | is_fp_cross_low_next  ? 13'(exp_or_one)  : 13'h0)
    | (is_fp2int_next                            ? 13'(exp_or_one)  : 13'h0);
  assign exp_adder_in1_next =
      (is_fp_narrow_next | is_fp2int_next | is_fp_cross_low_next ? minus_exp : 13'h0)
    | (is_fp_widen_next | is_fp_cross_high_next
         ? (is_subnormal_next ? minus_exp : {2'h0, exp_src}) : 13'h0);

  // ---------------------------------------------------------------------------
  // §0.2 右移（narrow / fp→int / fround 共用）：带隐含位的 53 位尾数放在 65 位的高端，
  //   右移量 = 「让结果最低位落在目标格式最低尾数位/整数个位」所需的位数，饱和到 65（全移出）。
  // ---------------------------------------------------------------------------
  logic        frac_hidden_bit;    // 隐含 1：规格数（指数非零且非全 1）
  logic [52:0] frac_value_src;     // {隐含位, 尾数}
  logic [10:0] shift_base;
  logic [10:0] shift_width;
  logic [64:0] shamt_in_next;
  logic [10:0] shamt_next;

  assign frac_hidden_bit = exp_not_zero_next & ~exp_is_ones_next;
  assign frac_value_src  = {frac_hidden_bit, frac_src};
  assign shamt_in_next   = {frac_value_src, 12'h0};
  // fp→int / fround：63 + 源偏置（f16 78、f32 190、f64 1086）；narrow：目标偏置差 + 1；crossL：1009
  assign shift_base =
      (is_fp2int_next | is_fround_any_next)
        ? ((in_width_1h[1] ? 11'h04E : 11'h0) | (in_width_1h[2] ? 11'h0BE : 11'h0) | (in_width_1h[3] ? 11'h43E : 11'h0))
        : (is_cross_low_raw
             ? 11'h3F1
             : ((out_width_1h[1] ? 11'h071 : 11'h0) | (out_width_1h[2] ? 11'h381 : 11'h0)));
  assign shift_width = 11'(shift_base - exp_src);
  assign shamt_next  = shift_width > 11'd64 ? 11'd65 : shift_width;

  // ---------------------------------------------------------------------------
  // §0.3 fround 的准备：按目标格式（就是源格式）算「要清掉的低位数」与两端的特判
  //   froundShiftMask = 尾数宽 + 偏置 - 指数（f16 67、f32 179、f64 1075）；≥ 64 时掩码全 0
  // ---------------------------------------------------------------------------
  logic        fround_exp_lt_bias_next;     // |x| < 1
  logic        fround_exp_ge_max_next;      // 已经是整数（指数 ≥ 偏置 + 尾数宽）
  logic [10:0] frac_shift_mask_next;
  logic [10:0] fround_max_exp;
  logic [10:0] fround_shift_base;
  assign fround_exp_lt_bias_next =
      out_width_1h[1] & ~exp_src[4]  & exp_src[3:0] != 4'hF
    | out_width_1h[2] & ~exp_src[7]  & exp_src[6:0] != 7'h7F
    | out_width_1h[3] & ~exp_src[10] & exp_src[9:0] != 10'h3FF;
  assign fround_max_exp =
      (out_width_1h[1] ? 11'h019 : 11'h0) | (out_width_1h[2] ? 11'h096 : 11'h0) | (out_width_1h[3] ? 11'h433 : 11'h0);
  assign fround_exp_ge_max_next = exp_src >= fround_max_exp;
  assign fround_shift_base =
      (out_width_1h[1] ? 11'h043 : 11'h0) | (out_width_1h[2] ? 11'h0B3 : 11'h0) | (out_width_1h[3] ? 11'h433 : 11'h0);
  assign frac_shift_mask_next = 11'(fround_shift_base - exp_src);

  // ---------------------------------------------------------------------------
  // §0.4 fcvtmod.w.d：f64 截断成 int32（取模语义）。以 1075（=1023+52，尾数个位对齐）为界：
  //   指数 ≥ 1075：左移 (exp-1075)；≥ 64 位直接全 0（只剩高位，模 2^64 为 0），无 NX；
  //   指数 < 1075：右移 (1075-exp)；不足 64 位时被移出的位非零即 NX；≥ 64 位则全 0、NX=1。
  // ---------------------------------------------------------------------------
  logic [63:0] fcvtmod_frac_tmp;
  logic        fcvtmod_shift_left;          // 指数 ≥ 1075
  logic [10:0] fcvtmod_shift_delta;         // exp - 1075（11 位回绕）
  logic [10:0] fcvtmod_shift;               // 移位量的绝对值
  logic        fcvtmod_shift_small;         // 移位量 < 64
  logic [63:0] fcvtmod_frac_next;
  logic        fcvtmod_nx_next;
  assign fcvtmod_frac_tmp    = {11'h0, frac_value_src};
  assign fcvtmod_shift_left  = exp_src > 11'd1074;
  assign fcvtmod_shift_delta = 11'(exp_src - 11'd1075);
  assign fcvtmod_shift       = fcvtmod_shift_left ? fcvtmod_shift_delta : 11'(~fcvtmod_shift_delta + 11'h1);
  assign fcvtmod_shift_small = ~(|fcvtmod_shift[10:6]);

  always_comb begin
    if (fcvtmod_shift_left & ~fcvtmod_shift_small) begin
      fcvtmod_frac_next = 64'h0;
      fcvtmod_nx_next   = 1'b0;
    end else if (fcvtmod_shift_left) begin
      fcvtmod_frac_next = 64'(fcvtmod_frac_tmp << fcvtmod_shift[5:0]);
      fcvtmod_nx_next   = 1'b0;
    end else if (fcvtmod_shift_small) begin
      // 右移 1..63 位：被移出的低位就是 NX
      fcvtmod_frac_next = fcvtmod_frac_tmp >> fcvtmod_shift[5:0];
      fcvtmod_nx_next   = |(fcvtmod_frac_tmp & 64'((64'h1 << fcvtmod_shift[5:0]) - 64'h1));
    end else begin
      fcvtmod_frac_next = 64'h0;
      fcvtmod_nx_next   = 1'b1;
    end
  end

  // ===========================================================================
  // §1 s1 寄存器（fire 使能）。fireReg_last_r = fire 打一拍（GatedValidRegNext）。
  //    复位域照 golden：控制/类别/fround/fcvtmod 异步复位；指数加数等五组不复位。
  // ===========================================================================
  logic        fireReg_last_r;
  logic        expNotZeroSrc, expIsOnesSrc, fracNotZeroSrc;
  logic        isInfSrc, isZeroSrc, isSubnormalSrc, isnormalSrc, isSNaNSrc, isNaNSrc;
  logic        isFpWiden, isFpNarrow, isFp2Int, isFpCrossHigh, isFpCrossLow;
  logic        isFroundnxReg, isFroundOrFroundnxReg, isFcvtmodReg, froundOrFroundnxIsZeroOrInf;
  logic        trunSticky;       // narrow 时 f64 尾数里 f32 放不下的低 29 位是否非零
  logic        signSrc;
  logic [2:0]  rm;
  logic        hasSignInt;
  logic [3:0]  output1HReg;
  logic [63:0] fracSrcLeft;
  logic        froundExpLessThanBias, froundExpGreaterThanMaxExp;
  logic [10:0] fracShiftMask;
  logic [10:0] froundOldExp;
  logic [51:0] froundOldFrac;
  logic [63:0] fcvtmodFracReg;
  logic [10:0] fcvtmodTrueExpReg;
  logic        fcvtmodNxReg;
  logic        fcvtmodExpLessThanBias;
  logic        s1_fpCanonicalNAN;
  logic [12:0] expAdderIn0, expAdderIn1;
  logic [6:0]  leadZeros;
  logic [64:0] shamtIn;
  logic [10:0] shamt;

  // s2（fireReg_last_r 使能）
  logic [4:0]  fflags;
  logic [63:0] result;
  logic [4:0]  fflags_next;
  logic [63:0] result_next;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fireReg_last_r              <= 1'b0;
      expNotZeroSrc               <= 1'b0;
      expIsOnesSrc                <= 1'b0;
      fracNotZeroSrc              <= 1'b0;
      isInfSrc                    <= 1'b0;
      isZeroSrc                   <= 1'b0;
      isSubnormalSrc              <= 1'b0;
      isnormalSrc                 <= 1'b0;
      isSNaNSrc                   <= 1'b0;
      isFpWiden                   <= 1'b0;
      isFpNarrow                  <= 1'b0;
      isFp2Int                    <= 1'b0;
      isFpCrossHigh               <= 1'b0;
      isFpCrossLow                <= 1'b0;
      isNaNSrc                    <= 1'b0;
      isFroundnxReg               <= 1'b0;
      isFroundOrFroundnxReg       <= 1'b0;
      isFcvtmodReg                <= 1'b0;
      froundOrFroundnxIsZeroOrInf <= 1'b0;
      trunSticky                  <= 1'b0;
      signSrc                     <= 1'b0;
      rm                          <= 3'h0;
      hasSignInt                  <= 1'b0;
      output1HReg                 <= 4'h0;
      fflags                      <= 5'h0;
      result                      <= 64'h0;
      fracSrcLeft                 <= 64'h0;
      froundExpLessThanBias       <= 1'b0;
      froundExpGreaterThanMaxExp  <= 1'b0;
      fracShiftMask               <= 11'h0;
      froundOldExp                <= 11'h0;
      froundOldFrac               <= 52'h0;
      fcvtmodFracReg              <= 64'h0;
      fcvtmodTrueExpReg           <= 11'h0;
      fcvtmodNxReg                <= 1'b0;
      fcvtmodExpLessThanBias      <= 1'b0;
    end else begin
      if (fire | fireReg_last_r)
        fireReg_last_r <= fire;
      if (fire) begin
        expNotZeroSrc               <= exp_not_zero_next;
        expIsOnesSrc                <= exp_is_ones_next;
        fracNotZeroSrc              <= frac_not_zero_next;
        isInfSrc                    <= is_inf_next;
        isZeroSrc                   <= is_zero_next;
        isSubnormalSrc              <= is_subnormal_next;
        isnormalSrc                 <= is_normal_next;
        isSNaNSrc                   <= is_snan_next;
        isFpWiden                   <= is_fp_widen_next;
        isFpNarrow                  <= is_fp_narrow_next;
        isFp2Int                    <= is_fp2int_next;
        isFpCrossHigh               <= is_fp_cross_high_next;
        isFpCrossLow                <= is_fp_cross_low_next;
        isNaNSrc                    <= is_nan_next;
        isFroundnxReg               <= is_fround[1];
        isFroundOrFroundnxReg       <= is_fround_any_next;
        isFcvtmodReg                <= is_fcvtmod;
        froundOrFroundnxIsZeroOrInf <= is_fround_any_next & (is_zero_next | is_inf_next);
        trunSticky                  <= |frac_src[28:0];
        signSrc                     <= sign_src_next;
        rm                          <= rm_in;
        hasSignInt                  <= op_type[0];
        output1HReg                 <= out_width_1h;
        fracSrcLeft                 <= frac_left_next;
        froundExpLessThanBias       <= fround_exp_lt_bias_next;
        froundExpGreaterThanMaxExp  <= fround_exp_ge_max_next;
        fracShiftMask               <= frac_shift_mask_next;
        froundOldExp                <= exp_src;
        froundOldFrac               <= frac_src;
        fcvtmodFracReg              <= fcvtmod_frac_next;
        fcvtmodTrueExpReg           <= 11'(exp_src - 11'd1023);
        fcvtmodNxReg                <= fcvtmod_nx_next;
        fcvtmodExpLessThanBias      <= ~exp_src[10] & exp_src[9:0] != 10'h3FF;
      end
      if (fireReg_last_r) begin
        fflags <= fflags_next;
        result <= result_next;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_fpCanonicalNAN <= fp_canonical_nan_next;
      expAdderIn0       <= exp_adder_in0_next;
      expAdderIn1       <= exp_adder_in1_next;
      leadZeros         <= lead_zeros_next;
      shamtIn           <= shamt_in_next;
      shamt             <= shamt_next;
    end
  end

  // ===========================================================================
  // §2 第 1 拍公共部分：指数、规格化左移、右移、两个舍入器
  // ===========================================================================
  logic out_8, out_16, out_32, out_64;   // output1HReg 的四位（fp 目标时 16/32/64 即 f16/f32/f64）
  assign out_8  = output1HReg[0];
  assign out_16 = output1HReg[1];
  assign out_32 = output1HReg[2];
  assign out_64 = output1HReg[3];

  logic [12:0] exp;                // 未舍入的结果指数（有符号 13 位，[12]=负）
  logic [63:0] shift_left;         // 尾数左移 (前导零 + 1)：非规格数规格化，隐含 1 移出
  logic [63:0] frac_normaled;      // widen 用：非规格数取规格化后的尾数
  logic        sign_non_nan;       // NaN 的结果符号一律为 0
  assign exp           = 13'(expAdderIn0 + expAdderIn1);
  assign shift_left    = 64'({fracSrcLeft, 1'b0} << leadZeros);
  assign frac_normaled = isSubnormalSrc ? shift_left : fracSrcLeft;
  assign sign_non_nan  = ~isNaNSrc & signSrc;

  logic [64:0] srj_out;            // 右移后的 65 位：[64:1] 是保留部分，[0] 是 round 位
  logic        srj_sticky;         // 移出去的位里有没有 1
  ShiftRightJam shiftRightJam (
    .io_in     (shamtIn),
    .io_shamt  (shamt),
    .io_out    (srj_out),
    .io_sticky (srj_sticky)
  );

  // 主舍入器的输入：fp→int 与 fround 取右移结果；fp→fp 取尾数按目标格式切出的高位
  //   （narrow 直接用左对齐的源尾数，其余用规格化左移后的尾数）。
  logic        is_narrow_like;     // narrow 或 crossLow
  logic [63:0] rounder_map_in;
  logic        select_shifted;     // fp→int 或 fround
  logic [63:0] rounder_input;
  logic        rounder_round_in, rounder_sticky_in;
  logic        rounder_inexact, rounder_up;
  assign is_narrow_like = isFpNarrow | isFpCrossLow;
  assign rounder_map_in = is_narrow_like ? fracSrcLeft : shift_left;
  assign select_shifted = isFp2Int | isFroundOrFroundnxReg;
  assign rounder_input =
      select_shifted
        ? srj_out[64:1]
        : ((out_16 ? 64'(rounder_map_in[63:54]) : 64'h0)
         | (out_32 ? 64'(rounder_map_in[63:41]) : 64'h0)
         | (out_64 ? 64'(rounder_map_in[63:12]) : 64'h0));
  assign rounder_round_in =
      select_shifted
        ? srj_out[0]
        : out_16 & rounder_map_in[53] | out_32 & rounder_map_in[40] | out_64 & rounder_map_in[11];
  assign rounder_sticky_in =
      select_shifted
        ? srj_sticky
        : out_16 & (|rounder_map_in[52:0]) | out_32 & (|rounder_map_in[39:0]) | out_64 & (|rounder_map_in[10:0]);

  RoundingUnit_3 rounder (
    .io_in       (rounder_input),
    .io_roundIn  (rounder_round_in),
    .io_stickyIn (rounder_sticky_in),
    .io_signIn   (signSrc),
    .io_rm       (rm),
    .io_inexact  (rounder_inexact),
    .io_r_up     (rounder_up)
  );

  // 非规格结果的舍入器（narrow 到 f16/f32 且结果落进非规格区）：输入取右移结果去掉最高位
  logic [22:0] sub_rounder_input;
  logic        sub_round_in, sub_sticky_in;
  logic        sub_inexact, sub_up;
  assign sub_rounder_input =
      (out_16 ? 23'(srj_out[63:54]) : 23'h0) | (out_32 ? srj_out[63:41] : 23'h0);
  assign sub_round_in = out_16 & srj_out[53] | out_32 & srj_out[40];
  assign sub_sticky_in =
      out_16 & (trunSticky | srj_sticky | (|srj_out[52:0]))
    | out_32 & (trunSticky | srj_sticky | (|srj_out[39:0]));

  RoundingUnit_4 subRounder (
    .io_in       (sub_rounder_input),
    .io_roundIn  (sub_round_in),
    .io_stickyIn (sub_sticky_in),
    .io_signIn   (signSrc),
    .io_rm       (rm),
    .io_inexact  (sub_inexact),
    .io_r_up     (sub_up)
  );

  // 舍入后：尾数 +1；若被 +1 的那段原本全 1，则进位到指数（cout）。
  //   fp→int：「那段」是整数的 n 位（有符号时 n-1 位）；fp→fp：目标尾数位。
  logic        int_all_ones;
  logic        frac_all_ones;
  logic        cout;
  logic [10:0] exp_rounded;
  logic [63:0] frac_rounded;
  logic        rmin;               // 舍入方向朝 0（RTZ，或负数 RUP，或正数 RDN）
  always_comb begin
    int_all_ones = 1'b0;
    for (int k = 0; k < 4; k++) begin
      // k=0..3 -> 8/16/32/64 位整数；有符号时最高位是符号，只看低 n-1 位
      automatic int unsigned n = 8 << k;
      automatic logic [63:0] mask = hasSignInt ? 64'((65'h1 << (n - 1)) - 65'h1) : 64'((65'h1 << n) - 65'h1);
      int_all_ones |= output1HReg[k] & ((rounder_input & mask) == mask);
    end
  end
  assign frac_all_ones =
      out_16 & (&rounder_map_in[63:54]) | out_32 & (&rounder_map_in[63:41]) | out_64 & (&rounder_map_in[63:12]);
  assign cout         = rounder_up & (isFp2Int ? int_all_ones : frac_all_ones);
  assign exp_rounded  = cout ? 11'(exp[10:0] + 11'h1) : exp[10:0];
  assign frac_rounded = rounder_up ? 64'(rounder_input + 64'h1) : rounder_input;
  assign rmin         = rm == 3'h1 | signSrc & rm == 3'h3 | ~signSrc & rm == 3'h2;

  // ===========================================================================
  // §3 路径 A：widen（f16→f32、f32→f64）与 crossHigh（f16→f64）——永远精确，只有 sNaN 报 NV
  // ===========================================================================
  logic        is_widen_like;
  logic        widen_finite;       // 规格数或非规格数（目标格式里都是规格数）
  logic [31:0] widen_f32;
  logic [63:0] widen_f64;
  logic [63:0] widen_result;
  assign is_widen_like = isFpWiden | isFpCrossHigh;
  assign widen_finite  = isSubnormalSrc | isnormalSrc;
  assign widen_f32 =
      (expIsOnesSrc ? {sign_non_nan, 8'hFF, fracNotZeroSrc, 22'h0}       : 32'h0)   // Inf，或 NaN→qNaN
    | (isZeroSrc    ? {sign_non_nan, 31'h0}                              : 32'h0)
    | (widen_finite ? {sign_non_nan, exp[7:0], frac_normaled[63:41]}     : 32'h0);
  assign widen_f64 =
      (expIsOnesSrc ? {sign_non_nan, 11'h7FF, fracNotZeroSrc, 51'h0}     : 64'h0)
    | (isZeroSrc    ? {sign_non_nan, 63'h0}                              : 64'h0)
    | (widen_finite ? {sign_non_nan, exp[10:0], frac_normaled[63:12]}    : 64'h0);
  assign widen_result = (out_32 ? 64'(widen_f32) : 64'h0) | (out_64 ? widen_f64 : 64'h0);

  // ===========================================================================
  // §4 路径 B：narrow（f32→f16、f64→f32）与 crossLow（f64→f16）
  //   上溢：指数（进位时提前一档）到达全 1；结果落进非规格区（exp ≤ 0）时改用 subRounder 的结果。
  // ===========================================================================
  logic of_rounded;
  logic maybe_sub;                 // 未舍入指数 ≤ 0：结果是非规格数或 0
  logic uf_exp_rounded;            // RISC-V 的 UF：舍入**之后**仍在非规格区
  assign of_rounded = ~exp[12] & (
      out_16 & (cout ? (&exp[4:1])  | (|exp[11:5]) : (&exp[4:0])  | (|exp[11:5]))
    | out_32 & (cout ? (&exp[7:1])  | (|exp[11:8]) : (&exp[7:0])  | (|exp[11:8]))
    | out_64 & (cout ? (&exp[10:1]) | exp[11]      : (&exp[10:0]) | exp[11]));
  assign maybe_sub      = exp[12] | ~(|exp);
  assign uf_exp_rounded = cout ? exp[12] : exp[12] | ~(|exp);

  logic [22:0] sub_frac_rounded;
  logic        sub_cout;           // 非规格尾数全 1 再进位 → 变成最小规格数（指数 1）
  assign sub_frac_rounded = sub_up ? 23'(sub_rounder_input + 23'h1) : sub_rounder_input;
  assign sub_cout = sub_up & (out_16 & (&srj_out[63:54]) | out_32 & (&srj_out[63:41]));

  // 五类结果的独热选择
  logic is_rto;
  logic narrow_nan_inf, narrow_max_finite, narrow_inf, narrow_normal, narrow_sub;
  assign is_rto            = rm == 3'h6;
  assign narrow_nan_inf    = expIsOnesSrc;
  assign narrow_max_finite = ~expIsOnesSrc & ~maybe_sub & of_rounded & (rmin | is_rto);
  assign narrow_inf        = ~expIsOnesSrc & ~maybe_sub & of_rounded & ~(rmin | is_rto);
  assign narrow_normal     = ~expIsOnesSrc & ~maybe_sub & ~of_rounded;
  assign narrow_sub        = ~expIsOnesSrc & maybe_sub;

  logic [15:0] narrow_f16;
  logic [31:0] narrow_f32;
  logic [63:0] narrow_result;
  assign narrow_f16 =
      (narrow_nan_inf    ? {sign_non_nan, 5'h1F, fracNotZeroSrc, 9'h0}                  : 16'h0)
    | (narrow_max_finite ? {sign_non_nan, 5'h1E, 10'h3FF}                               : 16'h0)
    | (narrow_inf        ? {sign_non_nan, 5'h1F, 10'h0}                                 : 16'h0)
    | (narrow_normal     ? {sign_non_nan, exp_rounded[4:0], frac_rounded[9:0]}          : 16'h0)
    | (narrow_sub        ? {sign_non_nan, 4'h0, sub_cout, sub_frac_rounded[9:0]}        : 16'h0);
  assign narrow_f32 =
      (narrow_nan_inf    ? {sign_non_nan, 8'hFF, fracNotZeroSrc, 22'h0}                 : 32'h0)
    | (narrow_max_finite ? {sign_non_nan, 8'hFE, 23'h7FFFFF}                            : 32'h0)
    | (narrow_inf        ? {sign_non_nan, 8'hFF, 23'h0}                                 : 32'h0)
    | (narrow_normal     ? {sign_non_nan, exp_rounded[7:0], frac_rounded[22:0]}         : 32'h0)
    | (narrow_sub        ? {sign_non_nan, 7'h0, sub_cout, sub_frac_rounded}             : 32'h0);
  assign narrow_result = (out_16 ? 64'(narrow_f16) : 64'h0) | (out_32 ? 64'(narrow_f32) : 64'h0);

  logic narrow_nv, narrow_of, narrow_uf, narrow_nx;
  assign narrow_nv = isSNaNSrc & ~s1_fpCanonicalNAN;
  assign narrow_of = ~expIsOnesSrc & of_rounded & ~s1_fpCanonicalNAN;
  assign narrow_uf = ~expIsOnesSrc & maybe_sub & uf_exp_rounded & sub_inexact & ~s1_fpCanonicalNAN;
  assign narrow_nx = ~expIsOnesSrc
                   & (~maybe_sub & (rounder_inexact | of_rounded) | maybe_sub & sub_inexact)
                   & ~s1_fpCanonicalNAN;

  // ===========================================================================
  // §5 路径 C：fround / froundnx（舍入到整数值、格式不变）
  //   把「小数部分」那些低位清零（froundOldInput），需要进位时在保留部分最低位 +1（froundUpInput）；
  //   |x| < 1 时结果是 ±0 或 ±1.0；已经是整数 / 0 / Inf 时原样返回；NaN 返回规范 qNaN。
  // ===========================================================================
  logic [63:0] fround_keep_mask;   // 低 fracShiftMask 位清零；fracShiftMask ≥ 64 时全清
  logic [63:0] fround_lsb;         // 保留部分的最低位
  logic [63:0] fround_old_input;
  logic [63:0] fround_up_input;
  assign fround_keep_mask = fracShiftMask < 11'd64 ? 64'(64'hFFFF_FFFF_FFFF_FFFF << fracShiftMask[5:0]) : 64'h0;
  assign fround_lsb       = fracShiftMask < 11'd64 ? 64'(64'h1 << fracShiftMask[5:0]) : 64'h0;
  assign fround_old_input = {signSrc, froundOldExp, froundOldFrac} & fround_keep_mask;
  assign fround_up_input  = 64'(fround_old_input + fround_lsb);

  // 「原值」：三种格式按 Mux1H 或在一起的那一份（golden 每种格式的保持分支都用这同一份）
  logic [63:0] fround_orig;
  assign fround_orig =
      (out_16 ? 64'({signSrc, froundOldExp[4:0], froundOldFrac[51:42]}) : 64'h0)
    | (out_32 ? 64'({signSrc, froundOldExp[7:0], froundOldFrac[51:29]}) : 64'h0)
    | (out_64 ? {signSrc, froundOldExp, froundOldFrac}                  : 64'h0);

  logic        fround_keep, fround_lt_one, fround_normal;
  logic [63:0] fround_rounded;     // 舍入后的 f64 布局值（按是否进位二选一）
  assign fround_keep    = froundOrFroundnxIsZeroOrInf | froundExpGreaterThanMaxExp & ~isNaNSrc;
  assign fround_lt_one  = froundExpLessThanBias & ~froundOrFroundnxIsZeroOrInf;
  assign fround_normal  = ~froundExpLessThanBias & ~froundExpGreaterThanMaxExp;
  assign fround_rounded = rounder_up ? fround_up_input : fround_old_input;

  logic [15:0] fround_f16;
  logic [31:0] fround_f32;
  logic [63:0] fround_f64;
  logic [63:0] fround_result;
  assign fround_f16 =
      (isNaNSrc       ? 16'h7E00                                                              : 16'h0)
    | (fround_lt_one  ? {signSrc, rounder_up ? 5'h0F : 5'h0, 10'h0}                           : 16'h0)
    | (fround_normal  ? {fround_rounded[63], fround_rounded[56:52], fround_rounded[51:42]}    : 16'h0);
  assign fround_f32 =
      (isNaNSrc       ? 32'h7FC0_0000                                                         : 32'h0)
    | (fround_lt_one  ? {signSrc, rounder_up ? 8'h7F : 8'h0, 23'h0}                           : 32'h0)
    | (fround_normal  ? {fround_rounded[63], fround_rounded[59:52], fround_rounded[51:29]}    : 32'h0);
  assign fround_f64 =
      (isNaNSrc       ? 64'h7FF8_0000_0000_0000                                               : 64'h0)
    | (fround_lt_one  ? {signSrc, rounder_up ? 11'h3FF : 11'h0, 52'h0}                        : 64'h0)
    | (fround_normal  ? fround_rounded                                                        : 64'h0);
  assign fround_result =
      (out_16 ? (fround_keep ? fround_orig : 64'h0) | 64'(fround_f16) : 64'h0)
    | (out_32 ? (fround_keep ? fround_orig : 64'h0) | 64'(fround_f32) : 64'h0)
    | (out_64 ? (fround_keep ? fround_orig : 64'h0) | fround_f64      : 64'h0);

  logic fround_nx;
  assign fround_nx = isFroundnxReg & rounder_inexact & ~froundOrFroundnxIsZeroOrInf & ~froundExpGreaterThanMaxExp;

  // ===========================================================================
  // §6 路径 D：fcvtmod.w.d —— 截断后的整数取低 32 位并符号扩展；超出 int32 范围报 NV
  // ===========================================================================
  logic        fcvtmod_exp_of, fcvtmod_frac_of, fcvtmod_is_of;
  logic [31:0] fcvtmod_low32;
  logic        fcvtmod_nx;
  assign fcvtmod_exp_of  = ~fcvtmodExpLessThanBias & (|fcvtmodTrueExpReg[10:5]);   // 真指数 ≥ 32
  assign fcvtmod_frac_of =
      signSrc ? (|fcvtmodFracReg[63:32]) | fcvtmodFracReg[63:32] == 32'h0 & fcvtmodFracReg[31] & (|fcvtmodFracReg[30:0])
              : (|fcvtmodFracReg[63:31]);
  assign fcvtmod_is_of = fcvtmod_exp_of | fcvtmod_frac_of;
  assign fcvtmod_low32 = signSrc ? 32'(~fcvtmodFracReg[31:0] + 32'h1) : fcvtmodFracReg[31:0];
  assign fcvtmod_nx =
      ~expNotZeroSrc & fracNotZeroSrc                                          // 非规格数：非零即不精确
    | expNotZeroSrc & ~expIsOnesSrc & ~fcvtmod_is_of & fcvtmodNxReg;          // 规格数：移出位非零

  // ===========================================================================
  // §7 路径 E：fp→int（8/16/32/64 位，有/无符号）
  //   指数上溢：真指数 ≥ 整数位数（有符号少一档，舍入进位再少一档）；唯一例外是有符号最小值 -2^(n-1)。
  // ===========================================================================
  logic of_exp_rounded;            // 舍入后量级超出目标整数范围
  logic exclude_exp, exclude_frac; // 恰好是 -2^(n-1)：指数正好 n-1 且结果为 100…0
  always_comb begin
    of_exp_rounded = 1'b0;
    exclude_exp    = 1'b0;
    exclude_frac   = 1'b0;
    for (int k = 0; k < 4; k++) begin
      automatic int unsigned i = k + 3;                         // log2(整数位数)
      automatic logic [12:0] low_mask = 13'((13'h1 << i) - 13'h1);   // exp[i-1:0]
      automatic logic [12:0] low_mask_hi = low_mask & ~13'h1;        // exp[i-1:1]
      automatic logic hi_nonzero = |(exp[11:0] >> i);           // exp[11:i] 非零
      automatic logic low_ones   = (exp & low_mask) == low_mask;
      automatic logic low_ones_hi = (exp & low_mask_hi) == low_mask_hi;
      automatic logic of_k;
      case ({hasSignInt, cout})
        2'b00:         of_k = hi_nonzero;                       // 无符号、不进位：≥ n
        2'b01, 2'b10:  of_k = hi_nonzero | low_ones;            // ≥ n-1
        default:       of_k = hi_nonzero | low_ones_hi;         // 有符号且进位：≥ n-2
      endcase
      of_exp_rounded |= output1HReg[k] & of_k;
      exclude_exp |= output1HReg[k] & ((exp >> i) == 13'h0)
                   & (cout ? low_ones_hi & ~exp[0] : low_ones);
      exclude_frac |= output1HReg[k]
                    & ((frac_rounded & 64'((65'h1 << (8 << k)) - 65'h1)) == 64'(64'h1 << ((8 << k) - 1)));
    end
    of_exp_rounded &= ~exp[12];
  end

  logic to_unv, to_inv;            // 无符号 / 有符号目标是否无效（NV）
  assign to_unv = of_exp_rounded | expIsOnesSrc
                | signSrc & ~(isZeroSrc | ~(|frac_rounded) & ~of_exp_rounded);   // 负数（舍入后不是 -0）
  assign to_inv = of_exp_rounded & ~(signSrc & exclude_exp & exclude_frac) | expIsOnesSrc;

  logic        int_ok, int_all_ones_res, int_signed_sat;
  logic [63:0] int_normal;         // 舍入后的整数（负数取补码）
  logic [63:0] int_signed_limit;   // 有符号饱和值：正 = 2^(n-1)-1，负 = -2^(n-1)（按宽度零扩展）
  logic [63:0] int_result;
  assign int_ok           = ~hasSignInt & ~to_unv | hasSignInt & ~to_inv;
  assign int_all_ones_res = ~hasSignInt & to_unv & (isNaNSrc | ~signSrc & (isInfSrc | of_exp_rounded));
  assign int_signed_sat   = hasSignInt & to_inv;
  assign int_normal       = signSrc & (|frac_rounded) ? 64'(~frac_rounded + 64'h1) : frac_rounded;
  always_comb begin
    int_signed_limit = 64'h0;
    for (int k = 0; k < 4; k++) begin
      automatic logic [63:0] top = 64'(64'h1 << ((8 << k) - 1));
      if (output1HReg[k])
        int_signed_limit |= sign_non_nan ? top : 64'(top - 64'h1);
    end
  end
  assign int_result =
      (int_ok         ? int_normal       : 64'h0)
    | {64{int_all_ones_res}}                         // 无符号上溢 / NaN / +Inf：全 1；负数：全 0（无此项）
    | (int_signed_sat ? int_signed_limit : 64'h0);

  // ===========================================================================
  // §8 五路优先选择 → s2
  // ===========================================================================
  always_comb begin
    if (is_widen_like) begin
      result_next = widen_result;
      fflags_next = {isSNaNSrc & ~s1_fpCanonicalNAN, 4'b0000};
    end else if (is_narrow_like) begin
      result_next = narrow_result;
      fflags_next = {narrow_nv, 1'b0, narrow_of, narrow_uf, narrow_nx};
    end else if (isFroundOrFroundnxReg) begin
      result_next = fround_result;
      fflags_next = {isSNaNSrc, 3'b000, fround_nx};
    end else if (isFcvtmodReg) begin
      result_next = {{32{fcvtmod_low32[31]}}, fcvtmod_low32};
      fflags_next = {expIsOnesSrc | fcvtmod_is_of, 3'b000, fcvtmod_nx};
    end else begin
      result_next = int_result;
      fflags_next = hasSignInt ? {to_inv, 3'b000, ~to_inv & rounder_inexact}
                               : {to_unv, 3'b000, ~to_unv & rounder_inexact};
    end
  end

  assign result_out = result;
  assign fflags_out = fflags;

endmodule

module FP_INCVT(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [2:0]  io_rm,
  input  [3:0]  io_input1H,
  input  [3:0]  io_output1H,
  input         io_isFpToVecInst,
  input  [1:0]  io_isFround,
  input         io_isFcvtmod,
  output [63:0] io_result,
  output [4:0]  io_fflags
);

  xs_FP_INCVT_core u_core (
    .clock             (clock),
    .reset             (reset),
    .fire              (io_fire),
    .src               (io_src),
    .op_type           (io_opType),
    .rm_in             (io_rm),
    .in_width_1h       (io_input1H),
    .out_width_1h      (io_output1H),
    .is_fp_to_vec_inst (io_isFpToVecInst),
    .is_fround         (io_isFround),
    .is_fcvtmod        (io_isFcvtmod),
    .result_out        (io_result),
    .fflags_out        (io_fflags)
  );

endmodule
