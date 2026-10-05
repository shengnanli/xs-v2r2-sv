// =============================================================================
// FloatAdderF64WidenPipeline.sv —— 向量 f64 / f32→f64 加宽 浮点加法器 + min/max/比较/sgnj/fclass/merge/move/
//                                  归约特判（两拍流水）
//
// 在哪一层：向量浮点加法单元 VectorFloatAdder 里 64 位 lane 的那一份（hasMinMaxCompare=true 变体）。
//   普通 f64 指令直接用 fp_a / fp_b；加宽指令（vfwadd/vfwsub 等，res_widening=1）用前级 FloatAdderWidenFormat
//   已经从 f32 精确换成 f64 的 widen_a / widen_b。
// 设计源：yunsuan/vector/VectorFloatAdder.scala class FloatAdderF64WidenPipeline（exponentWidth=11，
//   significandWidth=53）。结构与 FloatAdderF32WidenF16MixedPipeline 同族，只是没有 f16 混合。
//
// 结构：
//   §1 选操作数：a 来自 f32 ⇔ res_widening & ~opb_widening（vfwadd.wv 的 a 已是 f64）；
//      b 来自 f32 ⇔ res_widening & ~is_vfwredosum（有序加宽归约的 b 是 f64 累加值）。
//   §2 特殊值判定：加宽件把 f32 的零换成指数 0x369、把 Inf/NaN 换成指数 0x47F（它只做重偏置），所以
//      「来自 f32」的操作数这两个指数也分别算零指数 / 全 1 指数。
//   §3 远/近路径：同 FloatAdderF64Pipeline——close path 只管「有效相减且 |Ea-Eb| <= 1」，其余走 far；
//      「差 1 且恰好一个是零指数」也归 far。
//   §4 非加减类指令（第 0 拍组合），§5 第 0 拍寄存器，§6 第 1 拍结果选择。
// 怪癖（照 golden）：
//   - 「零操作数直通」三格（两零 / a 零 / b 零）只在 res_widening 时生效；普通 f64 加法的零交给 far/close 自己算。
//   - min/max/sgnj/merge/move/归约返回和比较用的符号位是**原始** fp_a / fp_b，而特殊值判定、指数尾数比较用的是
//     §1 选出的操作数（加宽时两者不同；向量单元不会对加宽格式发 min/max，照抄即可）。
//   - Inf 结果、两零相加结果是 64 位寄存器，其指数/尾数位恒为常量；照留整宽（FM 里归 constant reg）。
//   - fmax_re / fmin_re 全被掩码时都给 canonical NaN；fsum_ore 被掩码的条件里 ~mask[0] 重复一次（功能等价一次）。
//   - 「是不是加减类」打两份同源寄存器（一份选 fp_c、一份选 fflags），逐份照抄；非加减类 fflags 低 4 位恒 0。
// 子模块：FarPathFloatAdderF64WidenPipeline U_far_path / ClosePathFloatAdderF64WidenPipeline U_close_path
//   （实例名与 golden 一致；本仓已签核重写件）。
// golden 对照：G1-canonical/golden-rtl/FloatAdderF64WidenPipeline.sv
// =============================================================================
module xs_FloatAdderF64WidenPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic [63:0] widen_a,            // f32→f64 加宽后的 a（前级转好）
  input  logic [63:0] widen_b,
  input  logic        mask,               // fmerge 的选择位：1 取 b
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  input  logic        opb_widening,       // 只有 b 加宽（vfwadd.wv）
  input  logic        res_widening,       // 结果是加宽格式
  input  logic [4:0]  op_code,
  input  logic [1:0]  mask_for_reduction, // 归约时两个操作数各自是否被掩码选中（bit0 = a，bit1 = b）
  input  logic        is_vfwredosum,      // 有序加宽归约：b 不加宽
  output logic [63:0] fp_c,
  output logic [4:0]  fflags              // {NV, DZ, OF, UF, NX}
);
  // ---- op_code 编码（VfaddOpCode）----
  localparam logic [4:0] OP_FADD = 5'h00, OP_FSUB = 5'h01, OP_FMIN = 5'h02, OP_FMAX = 5'h03,
                         OP_FMERGE = 5'h04, OP_FMOVE = 5'h05, OP_FSGNJ = 5'h06, OP_FSGNJN = 5'h07,
                         OP_FSGNJX = 5'h08, OP_FEQ = 5'h09, OP_FNE = 5'h0A, OP_FLT = 5'h0B,
                         OP_FLE = 5'h0C, OP_FGT = 5'h0D, OP_FGE = 5'h0E, OP_FCLASS = 5'h0F,
                         OP_FMV_F_S = 5'h11, OP_FMV_S_F = 5'h12, OP_FMIN_RE = 5'h14,
                         OP_FMAX_RE = 5'h15, OP_FSUM_ORE = 5'h16, OP_FSUM_URE = 5'h1A;
  localparam logic [63:0] CANONICAL_NAN = 64'h7FF8_0000_0000_0000;
  localparam logic [62:0] INF_MAGNITUDE = 63'h7FF0_0000_0000_0000;   // 指数全 1、尾数 0
  localparam logic [10:0] F32_ZERO_EXP    = 11'h369;   // 加宽件对 f32 ±0 给出的指数
  localparam logic [10:0] F32_ALL_ONE_EXP = 11'h47F;   // 加宽件对 f32 Inf/NaN 给出的指数（255 + 896）

  // ---------------------------------------------------------------------------
  // §1 选操作数（加宽时用前级换好的 f64）
  // ---------------------------------------------------------------------------
  logic        a_from_f32, b_from_f32;
  logic [63:0] op_a, op_b;
  assign a_from_f32 = res_widening & ~opb_widening;
  assign b_from_f32 = res_widening & ~is_vfwredosum;
  assign op_a       = a_from_f32 ? widen_a : fp_a;
  assign op_b       = b_from_f32 ? widen_b : fp_b;

  logic        sign_a, sign_b, eop;
  logic [10:0] exp_a, exp_b;
  logic [51:0] mant_a, mant_b;
  assign sign_a = op_a[63];
  assign sign_b = op_b[63];
  assign exp_a  = op_a[62:52];
  assign exp_b  = op_b[62:52];
  assign mant_a = op_a[51:0];
  assign mant_b = op_b[51:0];
  assign eop    = sign_a ^ is_sub ^ sign_b;

  // ---------------------------------------------------------------------------
  // §2 特殊值判定
  // ---------------------------------------------------------------------------
  logic exp_a_zero, exp_b_zero, exp_a_all_one, exp_b_all_one, mant_a_nz, mant_b_nz;
  assign exp_a_zero    = (exp_a == 11'h0) | (a_from_f32 & (exp_a == F32_ZERO_EXP));
  assign exp_b_zero    = (exp_b == 11'h0) | (b_from_f32 & (exp_b == F32_ZERO_EXP));
  assign exp_a_all_one = (&exp_a) | (a_from_f32 & (exp_a == F32_ALL_ONE_EXP));
  assign exp_b_all_one = (&exp_b) | (b_from_f32 & (exp_b == F32_ALL_ONE_EXP));
  assign mant_a_nz     = |mant_a;
  assign mant_b_nz     = |mant_b;

  logic a_is_nan, a_is_snan, a_is_inf, a_is_zero;
  logic b_is_nan, b_is_snan, b_is_inf, b_is_zero;
  assign a_is_nan  = exp_a_all_one & mant_a_nz;
  assign a_is_snan = a_is_nan & ~mant_a[51];
  assign a_is_inf  = exp_a_all_one & ~mant_a_nz;
  assign a_is_zero = exp_a_zero & ~mant_a_nz;
  assign b_is_nan  = exp_b_all_one & mant_b_nz;
  assign b_is_snan = b_is_nan & ~mant_b[51];
  assign b_is_inf  = exp_b_all_one & ~mant_b_nz;
  assign b_is_zero = exp_b_zero & ~mant_b_nz;

  logic any_snan, any_nan, inf_minus_inf;
  assign any_snan      = a_is_snan | b_is_snan;
  assign any_nan       = a_is_nan | b_is_nan;
  assign inf_minus_inf = eop & a_is_inf & b_is_inf;

  // ---------------------------------------------------------------------------
  // §3 远/近两条加法路径（都拿 §1 选出的操作数）
  // ---------------------------------------------------------------------------
  logic [63:0] far_fp_c, close_fp_c;
  logic [4:0]  far_fflags, close_fflags;
  logic [10:0] abs_ea_sub_eb;          // |Ea - Eb|（非规格数指数按 1 算）
  logic        exp_b_greater;          // Eb > Ea（原始指数）
  logic [53:0] close_cs1;              // close path 的 {0,sig_b} - {0,sig_a}，最高位 = 借位
  FarPathFloatAdderF64WidenPipeline U_far_path (
    .clock             (clock),
    .io_fire           (fire),
    .io_fp_a           (op_a),
    .io_fp_b           (op_b),
    .io_fp_c           (far_fp_c),
    .io_is_sub         (is_sub),
    .io_round_mode     (round_mode),
    .io_fflags         (far_fflags),
    .io_absEaSubEb     (abs_ea_sub_eb),
    .io_isEfp_bGreater (exp_b_greater)
  );
  ClosePathFloatAdderF64WidenPipeline U_close_path (
    .clock         (clock),
    .io_fire       (fire),
    .io_fp_a       (op_a),
    .io_fp_b       (op_b),
    .io_fp_c       (close_fp_c),
    .io_round_mode (round_mode),
    .io_fflags     (close_fflags),
    .io_CS1        (close_cs1)
  );

  logic is_far_path;
  assign is_far_path = ~eop | (|abs_ea_sub_eb[10:1])
                     | ((abs_ea_sub_eb == 11'd1) & (exp_a_zero ^ exp_b_zero));

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

  // b 相对 a 的大小（"b greater" = a < b）：符号取原始 fp_a/fp_b，指数尾数取 §1 的操作数
  logic raw_sign_a, raw_sign_b;
  logic exp_equal, sig_b_greater, sig_b_equal, both_zero;
  logic b_is_greater, b_is_equal, b_is_less;
  assign raw_sign_a    = fp_a[63];
  assign raw_sign_b    = fp_b[63];
  assign exp_equal     = (exp_a == exp_b);
  assign sig_b_greater = ~close_cs1[53] & (mant_a != mant_b);
  assign sig_b_equal   = (mant_a == mant_b);
  assign both_zero     = b_is_zero & a_is_zero;
  assign b_is_greater  = (~raw_sign_b & ((raw_sign_a & ~both_zero) | exp_b_greater | (exp_equal & sig_b_greater)))
                       | (raw_sign_b & raw_sign_a & ((~exp_b_greater & ~exp_equal)
                                                     | (exp_equal & ~sig_b_greater & ~sig_b_equal)));
  assign b_is_equal    = ((raw_sign_a == raw_sign_b) & exp_equal & sig_b_equal) | both_zero;
  assign b_is_less     = ~b_is_greater & ~b_is_equal;

  // min/max：一个 NaN 取另一个，两个 NaN 给 canonical NaN；±0 按符号区分（min 取 -0，max 取 +0）
  logic [63:0] result_min, result_max;
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
      result_min = (b_is_less    | (raw_sign_b & both_zero))  ? fp_b : fp_a;
      result_max = (b_is_greater | (~raw_sign_b & both_zero)) ? fp_b : fp_a;
    end
  end

  logic result_feq;
  assign result_feq = ~any_nan & b_is_equal;

  logic [9:0] fclass_bits;   // bit0 = -Inf … bit9 = qNaN
  assign fclass_bits = {a_is_nan & ~a_is_snan,
                        a_is_snan,
                        ~raw_sign_a & a_is_inf,
                        ~raw_sign_a & ~exp_a_zero & ~exp_a_all_one,
                        ~raw_sign_a & exp_a_zero & mant_a_nz,
                        ~raw_sign_a & exp_a_zero & ~mant_a_nz,
                        raw_sign_a & exp_a_zero & ~mant_a_nz,
                        raw_sign_a & exp_a_zero & mant_a_nz,
                        raw_sign_a & ~exp_a_zero & ~exp_a_all_one,
                        raw_sign_a & a_is_inf};

  // 归约的掩码特判
  logic        mask_none, mask_all;
  logic [63:0] re_masked_one_out;     // 恰一个操作数有效时取它
  assign mask_none         = (mask_for_reduction == 2'b00);
  assign mask_all          = &mask_for_reduction;
  assign re_masked_one_out = mask_for_reduction[0] ? fp_a : fp_b;

  logic [63:0] fsum_ure_masked, fmax_re_result, fmin_re_result;
  assign fsum_ure_masked = mask_none ? {round_mode != 3'b010, 63'h0}    // 全掩码：±0（RDN 给 +0）
                                     : re_masked_one_out;
  assign fmax_re_result  = mask_none ? CANONICAL_NAN : (mask_all ? result_max : re_masked_one_out);
  assign fmin_re_result  = mask_none ? CANONICAL_NAN : (mask_all ? result_min : re_masked_one_out);

  // 各 op 编码互不相同，所以 golden 的 Mux1H 就是按 op_code 选（无命中给 0）
  logic [63:0] result_stage0;
  always_comb begin
    case (op_code)
      OP_FMIN:     result_stage0 = result_min;
      OP_FMAX:     result_stage0 = result_max;
      OP_FEQ:      result_stage0 = {63'h0, result_feq};
      OP_FNE:      result_stage0 = {63'h0, ~result_feq};
      OP_FLT:      result_stage0 = {63'h0, ~any_nan & b_is_greater};
      OP_FLE:      result_stage0 = {63'h0, ~any_nan & (b_is_greater | b_is_equal)};
      OP_FGT:      result_stage0 = {63'h0, ~any_nan & b_is_less};
      OP_FGE:      result_stage0 = {63'h0, ~any_nan & (b_is_less | b_is_equal)};
      OP_FSGNJ:    result_stage0 = {raw_sign_b, fp_a[62:0]};
      OP_FSGNJN:   result_stage0 = {~raw_sign_b, fp_a[62:0]};
      OP_FSGNJX:   result_stage0 = {raw_sign_b ^ raw_sign_a, fp_a[62:0]};
      OP_FCLASS:   result_stage0 = {54'h0, fclass_bits};
      OP_FMERGE:   result_stage0 = mask ? fp_b : fp_a;
      OP_FMOVE,
      OP_FMV_F_S,
      OP_FMV_S_F:  result_stage0 = fp_b;
      OP_FSUM_URE: result_stage0 = mask_all ? 64'h0 : fsum_ure_masked;          // 未掩码走加法器
      OP_FMAX_RE:  result_stage0 = fmax_re_result;
      OP_FMIN_RE:  result_stage0 = fmin_re_result;
      OP_FSUM_ORE: result_stage0 = mask_for_reduction[0] ? 64'h0 : fp_b;        // a 未选中：直通 b
      default:     result_stage0 = 64'h0;
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
  logic        s1_a_is_zero;            // fp_a_is_zero_reg
  logic        s1_b_is_zero;            // fp_b_is_zero_reg
  logic        s1_res_widening;         // res_widening_reg
  logic        s1_is_far_path;          // is_far_path_reg
  logic        s1_flags_invalid;        // r                      : SNaN 或 Inf-Inf → NV
  logic        s1_flags_quiet;          // r_1                    : NaN/Inf → 加法 fflags 全 0
  logic        s1_result_is_nan;        // r_2                    : 任意 NaN 或 Inf-Inf → canonical NaN
  logic        s1_result_is_inf;        // r_3
  logic [63:0] s1_inf_result;           // float_adder_result_r_1 : {Inf 符号, 指数全 1, 尾数 0}
  logic [63:0] s1_both_zero_result;     // float_adder_result_r_2 : {两零相加的符号, 63 位 0}
  logic [63:0] s1_b_signed;             // float_adder_result_r_3 : a 为零时结果 = ±b
  logic [63:0] s1_a;                    // float_adder_result_r_4 : b 为零时结果 = a
  logic        s1_use_adder_for_c;      // io_fp_c_r
  logic [63:0] s1_result_stage0;        // io_fp_c_r_1
  logic        s1_use_adder_for_flags;  // io_fflags_r（与 io_fp_c_r 同源）
  logic [4:0]  s1_fflags_stage0;        // io_fflags_r_1

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_a_is_zero           <= a_is_zero;
      s1_b_is_zero           <= b_is_zero;
      s1_res_widening        <= res_widening;
      s1_is_far_path         <= is_far_path;
      s1_flags_invalid       <= any_snan | inf_minus_inf;
      s1_flags_quiet         <= any_nan | a_is_inf | b_is_inf;
      s1_result_is_nan       <= any_nan | inf_minus_inf;
      s1_result_is_inf       <= a_is_inf | b_is_inf;
      s1_inf_result          <= {a_is_inf ? sign_a : (is_sub ^ sign_b), INF_MAGNITUDE};
      // 两零相加：有效相减时只有 RDN 给 -0；有效相加时符号同 a
      s1_both_zero_result    <= {((round_mode == 3'b010) & eop) | (sign_a & ~eop), 63'h0};
      s1_b_signed            <= {is_sub ^ sign_b, op_b[62:0]};
      s1_a                   <= op_a;
      s1_use_adder_for_c     <= use_adder;
      s1_result_stage0       <= result_stage0;
      s1_use_adder_for_flags <= use_adder;
      s1_fflags_stage0       <= {fflags_nv_stage0, 4'b0};
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍结果选择（零操作数直通只在加宽时生效）
  // ---------------------------------------------------------------------------
  logic        widen_a_zero, widen_b_zero;
  logic [63:0] adder_result;
  logic [4:0]  adder_fflags;
  assign widen_a_zero = s1_res_widening & s1_a_is_zero;
  assign widen_b_zero = s1_res_widening & s1_b_is_zero;
  always_comb begin
    if (s1_result_is_nan)                  adder_result = CANONICAL_NAN;
    else if (s1_result_is_inf)             adder_result = s1_inf_result;
    else if (widen_a_zero & s1_b_is_zero)  adder_result = s1_both_zero_result;
    else if (widen_a_zero)                 adder_result = s1_b_signed;
    else if (widen_b_zero)                 adder_result = s1_a;
    else                                   adder_result = s1_is_far_path ? far_fp_c : close_fp_c;
  end
  assign adder_fflags = s1_flags_invalid                                       ? 5'b10000
                      : (s1_flags_quiet | ((s1_b_is_zero | s1_a_is_zero) & s1_res_widening)) ? 5'b00000
                      : s1_is_far_path                                         ? far_fflags : close_fflags;

  assign fp_c   = s1_use_adder_for_c     ? adder_result : s1_result_stage0;
  assign fflags = s1_use_adder_for_flags ? adder_fflags : s1_fflags_stage0;
endmodule

module FloatAdderF64WidenPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [63:0] io_fp_a,
  input  logic [63:0] io_fp_b,
  input  logic [63:0] io_widen_a,
  input  logic [63:0] io_widen_b,
  output logic [63:0] io_fp_c,
  input  logic        io_mask,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic        io_opb_widening,
  input  logic        io_res_widening,
  input  logic [4:0]  io_op_code,
  input  logic [1:0]  io_maskForReduction,
  input  logic        io_is_vfwredosum
);
  xs_FloatAdderF64WidenPipeline_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .widen_a            (io_widen_a),
    .widen_b            (io_widen_b),
    .mask               (io_mask),
    .is_sub             (io_is_sub),
    .round_mode         (io_round_mode),
    .opb_widening       (io_opb_widening),
    .res_widening       (io_res_widening),
    .op_code            (io_op_code),
    .mask_for_reduction (io_maskForReduction),
    .is_vfwredosum      (io_is_vfwredosum),
    .fp_c               (io_fp_c),
    .fflags             (io_fflags)
  );
endmodule
