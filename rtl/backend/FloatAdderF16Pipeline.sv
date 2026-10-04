// =============================================================================
// FloatAdderF16Pipeline.sv —— 纯 f16 浮点加法器 + min/max/比较/sgnj/fclass/merge/move/归约特判（两拍流水）
//
// 在哪一层：向量浮点加法单元 VectorFloatAdder 里 f16 专用的 lane（hasMinMaxCompare=true 变体）。
// 设计源：yunsuan/vector/VectorFloatAdder.scala class FloatAdderF16Pipeline（exponentWidth=5，
//   significandWidth=11）。结构与 FloatAdderF32WidenF16MixedPipeline 相同，只是没有格式混合/加宽。
//
// 结构：
//   §1 拆字段，EOP = sign_a ^ is_sub ^ sign_b（1 = 有效相减）。
//   §2 特殊值判定：NaN / SNaN（尾数最高位为 0）/ Inf / 零。
//   §3 远/近路径：两条路径是独立的两拍流水子模块，都拿原始 fp_a / fp_b 同时算，第 1 拍二选一：
//      close path 只管"有效相减且 |Ea-Eb| <= 1"（可能大量抵消、要前导零计数），其余走 far path；
//      但"差 1 且恰好一个是非规格数"也归 far（非规格数指数按 1 算，实际差 0，close 只看指数低两位
//      会算错，所以父级把这格路由给 far）。
//   §4 min/max/比较/sgnj/fclass/merge/move/归约掩码特判：全部第 0 拍算好打拍；大小比较借 far path
//      的 isEfp_bGreater（指数）与 close path 的 CS1 最高位（尾数借位）。
//   §5 第 0 拍寄存器（fire 使能，不复位，一份对应 golden 一个 reg）。
//   §6 第 1 拍结果选择：加减类（fadd/fsub，或未被掩码的归约求和）选加法器结果，否则选 §4 的打拍结果。
// 怪癖（照 golden）：
//   - fp_aIsFpCanonicalNAN / fp_bIsFpCanonicalNAN 在本配置恒 0，golden 已消掉端口与分支。
//   - "是不是加减类"打了两份同源寄存器（一份选 fp_c、一份选 fflags）；"走 far path"也打了两份
//     （Scala 在 fflags 与 result 两个 when 里各写一次 RegEnable）。本件逐份照抄，不合并。
//   - fflags 的 NV 判定用 SNaN，结果的 NaN 判定用任意 NaN——两套打拍位（golden r / r_2）。
//   - fmax_re / fmin_re 全被掩码时都给 canonical NaN（Scala 的 outInf 没被使用）。
//   - fsum_ore 被掩码的条件里 ~mask[0] 重复一次（golden 原样），功能上等价于一次。
//   - 非加减类结果的 fflags 低 4 位恒 0，但仍是 5 位寄存器（golden 原样）。
// 子模块：FarPathF16Pipeline U_far_path / ClosePathF16Pipeline U_close_path（实例名与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/FloatAdderF16Pipeline.sv
// =============================================================================
module xs_FloatAdderF16Pipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [15:0] fp_a,
  input  logic [15:0] fp_b,
  input  logic        is_sub,
  input  logic        mask,               // fmerge 的选择位：1 取 b
  input  logic [2:0]  round_mode,
  input  logic [4:0]  op_code,
  input  logic [1:0]  mask_for_reduction, // 归约时两个操作数各自是否被掩码选中（bit0 = a，bit1 = b）
  output logic [15:0] fp_c,
  output logic [4:0]  fflags              // {NV, DZ, OF, UF, NX}
);
  // ---- op_code 编码（VfaddOpCode）----
  localparam logic [4:0] OP_FADD = 5'h00, OP_FSUB = 5'h01, OP_FMIN = 5'h02, OP_FMAX = 5'h03,
                         OP_FMERGE = 5'h04, OP_FMOVE = 5'h05, OP_FSGNJ = 5'h06, OP_FSGNJN = 5'h07,
                         OP_FSGNJX = 5'h08, OP_FEQ = 5'h09, OP_FNE = 5'h0A, OP_FLT = 5'h0B,
                         OP_FLE = 5'h0C, OP_FGT = 5'h0D, OP_FGE = 5'h0E, OP_FCLASS = 5'h0F,
                         OP_FMV_F_S = 5'h11, OP_FMV_S_F = 5'h12, OP_FMIN_RE = 5'h14,
                         OP_FMAX_RE = 5'h15, OP_FSUM_ORE = 5'h16, OP_FSUM_URE = 5'h1A;
  localparam logic [15:0] CANONICAL_NAN = 16'h7E00;

  // ---------------------------------------------------------------------------
  // §1 拆字段
  // ---------------------------------------------------------------------------
  logic       sign_a, sign_b, eop;
  logic [4:0] exp_a, exp_b;
  logic [9:0] mant_a, mant_b;
  assign sign_a = fp_a[15];
  assign sign_b = fp_b[15];
  assign exp_a  = fp_a[14:10];
  assign exp_b  = fp_b[14:10];
  assign mant_a = fp_a[9:0];
  assign mant_b = fp_b[9:0];
  assign eop    = sign_a ^ is_sub ^ sign_b;

  // ---------------------------------------------------------------------------
  // §2 特殊值判定
  // ---------------------------------------------------------------------------
  logic exp_a_nz, exp_b_nz, exp_a_all_one, exp_b_all_one, mant_a_nz, mant_b_nz;
  assign exp_a_nz      = |exp_a;
  assign exp_b_nz      = |exp_b;
  assign exp_a_all_one = &exp_a;
  assign exp_b_all_one = &exp_b;
  assign mant_a_nz     = |mant_a;
  assign mant_b_nz     = |mant_b;

  logic a_is_nan, a_is_snan, a_is_inf, a_is_zero;
  logic b_is_nan, b_is_snan, b_is_inf, b_is_zero;
  assign a_is_nan  = exp_a_all_one & mant_a_nz;
  assign a_is_snan = a_is_nan & ~mant_a[9];
  assign a_is_inf  = exp_a_all_one & ~mant_a_nz;
  assign a_is_zero = ~exp_a_nz & ~mant_a_nz;
  assign b_is_nan  = exp_b_all_one & mant_b_nz;
  assign b_is_snan = b_is_nan & ~mant_b[9];
  assign b_is_inf  = exp_b_all_one & ~mant_b_nz;
  assign b_is_zero = ~exp_b_nz & ~mant_b_nz;

  logic any_snan, any_nan, inf_minus_inf;
  assign any_snan      = a_is_snan | b_is_snan;
  assign any_nan       = a_is_nan | b_is_nan;
  assign inf_minus_inf = eop & a_is_inf & b_is_inf;

  // ---------------------------------------------------------------------------
  // §3 远/近两条加法路径
  // ---------------------------------------------------------------------------
  logic [15:0] far_fp_c, close_fp_c;
  logic [4:0]  far_fflags, close_fflags;
  logic [4:0]  abs_ea_sub_eb;          // |Ea - Eb|（非规格数指数按 1 算）
  logic        exp_b_greater;          // Eb > Ea（原始指数）
  logic [11:0] close_cs1;              // close path 的 {0,sig_b} - {0,sig_a}，最高位 = 借位
  FarPathF16Pipeline U_far_path (
    .clock             (clock),
    .io_fire           (fire),
    .io_fp_a           (fp_a),
    .io_fp_b           (fp_b),
    .io_fp_c           (far_fp_c),
    .io_is_sub         (is_sub),
    .io_round_mode     (round_mode),
    .io_fflags         (far_fflags),
    .io_absEaSubEb     (abs_ea_sub_eb),
    .io_isEfp_bGreater (exp_b_greater)
  );
  ClosePathF16Pipeline U_close_path (
    .clock         (clock),
    .io_fire       (fire),
    .io_fp_a       (fp_a),
    .io_fp_b       (fp_b),
    .io_fp_c       (close_fp_c),
    .io_round_mode (round_mode),
    .io_fflags     (close_fflags),
    .io_CS1        (close_cs1)
  );

  logic is_far_path;
  assign is_far_path = ~eop | (|abs_ea_sub_eb[4:1])
                     | ((abs_ea_sub_eb == 5'd1) & (exp_a_nz ^ exp_b_nz));

  // ---------------------------------------------------------------------------
  // §4 非加减类指令（第 0 拍组合）
  // ---------------------------------------------------------------------------
  logic is_min, is_max, is_feq, is_fne, is_flt, is_fle, is_fgt, is_fge;
  logic is_fsum_ure, is_fmin_re, is_fmax_re, is_fsum_ore, is_addsub;
  assign is_min      = (op_code == OP_FMIN);
  assign is_max      = (op_code == OP_FMAX);
  assign is_feq      = (op_code == OP_FEQ);
  assign is_fne      = (op_code == OP_FNE);
  assign is_flt      = (op_code == OP_FLT);
  assign is_fle      = (op_code == OP_FLE);
  assign is_fgt      = (op_code == OP_FGT);
  assign is_fge      = (op_code == OP_FGE);
  assign is_fsum_ure = (op_code == OP_FSUM_URE);
  assign is_fmin_re  = (op_code == OP_FMIN_RE);
  assign is_fmax_re  = (op_code == OP_FMAX_RE);
  assign is_fsum_ore = (op_code == OP_FSUM_ORE);
  assign is_addsub   = (op_code == OP_FADD) | (op_code == OP_FSUB);

  // b 相对 a 的大小（"b greater" = a < b）
  logic exp_equal, sig_b_greater, sig_b_equal, both_zero;
  logic b_is_greater, b_is_equal, b_is_less;
  assign exp_equal     = (exp_a == exp_b);
  assign sig_b_greater = ~close_cs1[11] & (mant_a != mant_b);
  assign sig_b_equal   = (mant_a == mant_b);
  assign both_zero     = b_is_zero & a_is_zero;
  assign b_is_greater  = (~sign_b & ((sign_a & ~both_zero) | exp_b_greater | (exp_equal & sig_b_greater)))
                       | (sign_b & sign_a & ((~exp_b_greater & ~exp_equal)
                                             | (exp_equal & ~sig_b_greater & ~sig_b_equal)));
  assign b_is_equal    = ((sign_a == sign_b) & exp_equal & sig_b_equal) | both_zero;
  assign b_is_less     = ~b_is_greater & ~b_is_equal;

  // min/max：一个 NaN 取另一个，两个 NaN 给 canonical NaN；±0 按符号区分（min 取 -0，max 取 +0）
  logic [15:0] result_min, result_max;
  always_comb begin
    if (a_is_nan & b_is_nan) begin
      result_min = CANONICAL_NAN;
      result_max = CANONICAL_NAN;
    end else if (a_is_nan) begin
      result_min = fp_b;
      result_max = fp_b;
    end else if (b_is_nan) begin
      result_min = fp_a;
      result_max = fp_a;
    end else begin
      result_min = (b_is_less    | (sign_b & both_zero))  ? fp_b : fp_a;
      result_max = (b_is_greater | (~sign_b & both_zero)) ? fp_b : fp_a;
    end
  end

  logic result_feq;
  assign result_feq = ~any_nan & b_is_equal;

  logic [9:0] fclass_bits;   // bit0 = -Inf … bit9 = qNaN
  assign fclass_bits = {a_is_nan & ~a_is_snan,
                        a_is_snan,
                        ~sign_a & a_is_inf,
                        ~sign_a & exp_a_nz & ~exp_a_all_one,
                        ~sign_a & ~exp_a_nz & mant_a_nz,
                        ~sign_a & a_is_zero,
                        sign_a & a_is_zero,
                        sign_a & ~exp_a_nz & mant_a_nz,
                        sign_a & exp_a_nz & ~exp_a_all_one,
                        sign_a & a_is_inf};

  // 归约的掩码特判
  logic        mask_none, mask_all;
  logic [15:0] re_masked_one_out;     // 恰一个操作数有效时取它
  assign mask_none         = (mask_for_reduction == 2'b00);
  assign mask_all          = &mask_for_reduction;
  assign re_masked_one_out = mask_for_reduction[0] ? fp_a : fp_b;

  logic [15:0] fsum_ure_masked, fmax_re_result, fmin_re_result;
  assign fsum_ure_masked = mask_none ? {round_mode != 3'b010, 15'h0}    // 全掩码：±0（RDN 给 +0）
                                     : re_masked_one_out;
  assign fmax_re_result  = mask_none ? CANONICAL_NAN : (mask_all ? result_max : re_masked_one_out);
  assign fmin_re_result  = mask_none ? CANONICAL_NAN : (mask_all ? result_min : re_masked_one_out);

  // 各 op 编码互不相同，所以这里的 Mux1H 就是按 op_code 选（无命中给 0）
  logic [15:0] result_stage0;
  always_comb begin
    case (op_code)
      OP_FMIN:     result_stage0 = result_min;
      OP_FMAX:     result_stage0 = result_max;
      OP_FEQ:      result_stage0 = {15'h0, result_feq};
      OP_FNE:      result_stage0 = {15'h0, ~result_feq};
      OP_FLT:      result_stage0 = {15'h0, ~any_nan & b_is_greater};
      OP_FLE:      result_stage0 = {15'h0, ~any_nan & (b_is_greater | b_is_equal)};
      OP_FGT:      result_stage0 = {15'h0, ~any_nan & b_is_less};
      OP_FGE:      result_stage0 = {15'h0, ~any_nan & (b_is_less | b_is_equal)};
      OP_FSGNJ:    result_stage0 = {sign_b, fp_a[14:0]};
      OP_FSGNJN:   result_stage0 = {~sign_b, fp_a[14:0]};
      OP_FSGNJX:   result_stage0 = {sign_b ^ sign_a, fp_a[14:0]};
      OP_FCLASS:   result_stage0 = {6'h0, fclass_bits};
      OP_FMERGE:   result_stage0 = mask ? fp_b : fp_a;
      OP_FMOVE,
      OP_FMV_F_S,
      OP_FMV_S_F:  result_stage0 = fp_b;
      OP_FSUM_URE: result_stage0 = mask_all ? 16'h0 : fsum_ure_masked;          // 未掩码走加法器
      OP_FMAX_RE:  result_stage0 = fmax_re_result;
      OP_FMIN_RE:  result_stage0 = fmin_re_result;
      OP_FSUM_ORE: result_stage0 = mask_for_reduction[0] ? 16'h0 : fp_b;        // a 未选中：直通 b
      default:     result_stage0 = 16'h0;
    endcase
  end

  logic fflags_nv_stage0;
  assign fflags_nv_stage0 = ((is_min | is_max) & any_snan)
                          | ((is_feq | is_fne) & any_snan)
                          | ((is_flt | is_fle | is_fgt | is_fge) & any_nan)
                          | ((is_fmax_re | is_fmin_re)
                             & ((mask_for_reduction[0] & a_is_snan) | (mask_for_reduction[1] & b_is_snan)));

  // 走加法器结果：fadd/fsub，或归约求和且本 lane 未被掩码
  logic use_adder;
  assign use_adder = is_addsub | (is_fsum_ure & mask_all) | (is_fsum_ore & mask_for_reduction[0]);

  // ---------------------------------------------------------------------------
  // §5 第 0 拍寄存器（fire 使能，不复位；注释里是 golden 寄存器名）
  // ---------------------------------------------------------------------------
  logic        s1_flags_invalid;        // r                      : SNaN 或 Inf-Inf → NV
  logic        s1_flags_quiet;          // r_1                    : NaN/Inf → 加法 fflags 全 0
  logic        s1_flags_far_path;       // float_adder_fflags_r   : fflags 取 far path 的
  logic        s1_result_is_nan;        // r_2                    : 任意 NaN 或 Inf-Inf → canonical NaN
  logic        s1_result_is_inf;        // r_3
  logic        s1_inf_sign;             // float_adder_result_r   : Inf 结果的符号
  logic        s1_result_far_path;      // float_adder_result_r_1 : fp_c 取 far path 的（与上面同源）
  logic        s1_use_adder_for_c;      // io_fp_c_r
  logic [15:0] s1_result_stage0;        // io_fp_c_r_1
  logic        s1_use_adder_for_flags;  // io_fflags_r（与 io_fp_c_r 同源）
  logic [4:0]  s1_fflags_stage0;        // io_fflags_r_1

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_flags_invalid       <= any_snan | inf_minus_inf;
      s1_flags_quiet         <= any_nan | a_is_inf | b_is_inf;
      s1_flags_far_path      <= is_far_path;
      s1_result_is_nan       <= any_nan | inf_minus_inf;
      s1_result_is_inf       <= a_is_inf | b_is_inf;
      s1_inf_sign            <= a_is_inf ? sign_a : (is_sub ^ sign_b);
      s1_result_far_path     <= is_far_path;
      s1_use_adder_for_c     <= use_adder;
      s1_result_stage0       <= result_stage0;
      s1_use_adder_for_flags <= use_adder;
      s1_fflags_stage0       <= {fflags_nv_stage0, 4'b0};
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍结果选择
  // ---------------------------------------------------------------------------
  logic [15:0] adder_result;
  logic [4:0]  adder_fflags;
  assign adder_result = s1_result_is_nan   ? CANONICAL_NAN
                      : s1_result_is_inf   ? {s1_inf_sign, 5'h1F, 10'h0}
                      : s1_result_far_path ? far_fp_c : close_fp_c;
  assign adder_fflags = s1_flags_invalid   ? 5'b10000
                      : s1_flags_quiet     ? 5'b00000
                      : s1_flags_far_path  ? far_fflags : close_fflags;

  assign fp_c   = s1_use_adder_for_c     ? adder_result : s1_result_stage0;
  assign fflags = s1_use_adder_for_flags ? adder_fflags : s1_fflags_stage0;
endmodule

module FloatAdderF16Pipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [15:0] io_fp_a,
  input  logic [15:0] io_fp_b,
  output logic [15:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic        io_mask,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic [4:0]  io_op_code,
  input  logic [1:0]  io_maskForReduction
);
  xs_FloatAdderF16Pipeline_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .is_sub             (io_is_sub),
    .mask               (io_mask),
    .round_mode         (io_round_mode),
    .op_code            (io_op_code),
    .mask_for_reduction (io_maskForReduction),
    .fp_c               (io_fp_c),
    .fflags             (io_fflags)
  );
endmodule
