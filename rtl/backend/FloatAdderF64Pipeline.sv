// =============================================================================
// FloatAdderF64Pipeline.sv —— 标量 f64 浮点加法器 + min/max/比较/sgnj/fclass（两拍流水）
//
// 在哪一层：标量浮点加法单元 FloatAdder（FAlu 的运算核）里 f64 专用的那条通路
//   （hasMinMaxCompare=true 的变体，所以除 fadd/fsub 外还做 fmin/fmax/fminm/fmaxm、feq/flt/fle/fltq/fleq、
//   fsgnj(n/x)、fclass）。f32/f16 走另一条 FloatAdderF32F16MixedPipeline。
// 设计源：yunsuan/fpu/FloatAdder.scala class FloatAdderF64Pipeline（exponentWidth=11，significandWidth=53）。
//
// 结构：
//   §1 拆字段，EOP = sign_a ^ is_sub ^ sign_b（1 = 有效相减）。
//   §2 特殊值判定：NaN / SNaN（尾数最高位为 0）/ Inf / 零；「canonical NaN」标志位（前级发现 f64 寄存器里装的
//      不是合法 NaN-boxed 值时置 1）把该操作数强制看成 qNaN。
//   §3 远/近路径：两条路径是独立的两拍流水子模块，都拿原始 fp_a / fp_b 同时算，第 1 拍二选一：
//      close path 只管「有效相减且 |Ea-Eb| <= 1」，其余走 far path；但「差 1 且恰好一个是非规格数」也归 far。
//   §4 min/max/比较/sgnj/fclass：全部第 0 拍算好打拍；大小比较借 far path 的 isEfp_bGreater（指数）与
//      close path 的 CS1 最高位（尾数借位）。
//   §5 第 0 拍寄存器（fire 使能，不复位，一份对应 golden 一个 reg）。
//   §6 第 1 拍结果选择：加减类（op 0/1）选加法器结果，否则选 §4 的打拍结果。
// 怪癖（照 golden）：
//   - 加法结果的特殊值是按「先打拍、再选」实现的：Inf 结果、两零相加结果都是 64 位寄存器，其中指数/尾数位
//     恒为常量（Scala RegEnable(Cat(...常量...))）；本件照留 64 位整宽（FM 里这些位归 constant reg）。
//   - fflags 的 NV 判定用 SNaN，结果的 NaN 判定用任意 NaN——两套打拍位（golden r / r_2）。
//   - 「是不是加减类」打了两份同源寄存器（一份选 fp_c、一份选 fflags）。逐份照抄，不合并。
//   - 比较用的是**原始**符号位（不经 canonical NaN 修正）；sgnj 用的是修正后的值（a 换成 qNaN、b 的符号清 0）。
//   - 非加减类结果的 fflags 低 4 位恒 0，但仍是 5 位寄存器。
// 子模块：FarPathFloatAdderF64WidenPipeline U_far_path / ClosePathFloatAdderF64WidenPipeline U_close_path
//   （实例名与 golden 一致；本仓已签核重写件）。
// golden 对照：G1-canonical/golden-rtl/FloatAdderF64Pipeline.sv
// =============================================================================
module xs_FloatAdderF64Pipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  input  logic [4:0]  op_code,
  input  logic        a_is_canonical_nan,  // 1：把 a 当作 canonical qNaN（非法 NaN-boxing）
  input  logic        b_is_canonical_nan,
  output logic [63:0] fp_c,
  output logic [4:0]  fflags               // {NV, DZ, OF, UF, NX}
);
  // ---- op_code 编码（FaddOpCode）----
  localparam logic [4:0] OP_FADD = 5'h00, OP_FSUB = 5'h01, OP_FMIN = 5'h02, OP_FMAX = 5'h03,
                         OP_FSGNJ = 5'h06, OP_FSGNJN = 5'h07, OP_FSGNJX = 5'h08, OP_FEQ = 5'h09,
                         OP_FLT = 5'h0B, OP_FLE = 5'h0C, OP_FCLASS = 5'h0F, OP_FMAXM = 5'h13,
                         OP_FLTQ = 5'h1B, OP_FLEQ = 5'h1C, OP_FMINM = 5'h1E;
  localparam logic [63:0] CANONICAL_NAN = 64'h7FF8_0000_0000_0000;
  localparam logic [62:0] INF_MAGNITUDE = 63'h7FF0_0000_0000_0000;   // 指数全 1、尾数 0

  // ---------------------------------------------------------------------------
  // §1 拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a, sign_b, eop;
  logic [10:0] exp_a, exp_b;
  logic [51:0] mant_a, mant_b;
  assign sign_a = fp_a[63];
  assign sign_b = fp_b[63];
  assign exp_a  = fp_a[62:52];
  assign exp_b  = fp_b[62:52];
  assign mant_a = fp_a[51:0];
  assign mant_b = fp_b[51:0];
  assign eop    = sign_a ^ is_sub ^ sign_b;

  // ---------------------------------------------------------------------------
  // §2 特殊值判定
  // ---------------------------------------------------------------------------
  logic exp_a_zero, exp_b_zero, exp_a_all_one, exp_b_all_one, mant_a_nz, mant_b_nz;
  assign exp_a_zero    = (exp_a == 11'h0);
  assign exp_b_zero    = (exp_b == 11'h0);
  assign exp_a_all_one = &exp_a;
  assign exp_b_all_one = &exp_b;
  assign mant_a_nz     = |mant_a;
  assign mant_b_nz     = |mant_b;

  logic a_is_nan, a_is_snan, a_is_inf, a_is_zero;
  logic b_is_nan, b_is_snan, b_is_inf, b_is_zero;
  assign a_is_nan  = a_is_canonical_nan | (exp_a_all_one & mant_a_nz);
  assign a_is_snan = ~a_is_canonical_nan & exp_a_all_one & mant_a_nz & ~mant_a[51];
  assign a_is_inf  = ~a_is_canonical_nan & exp_a_all_one & ~mant_a_nz;
  assign a_is_zero = ~a_is_canonical_nan & exp_a_zero & ~mant_a_nz;
  assign b_is_nan  = b_is_canonical_nan | (exp_b_all_one & mant_b_nz);
  assign b_is_snan = ~b_is_canonical_nan & exp_b_all_one & mant_b_nz & ~mant_b[51];
  assign b_is_inf  = ~b_is_canonical_nan & exp_b_all_one & ~mant_b_nz;
  assign b_is_zero = ~b_is_canonical_nan & exp_b_zero & ~mant_b_nz;

  logic any_snan, any_nan, inf_minus_inf;
  assign any_snan      = a_is_snan | b_is_snan;
  assign any_nan       = a_is_nan | b_is_nan;
  assign inf_minus_inf = eop & a_is_inf & b_is_inf;

  // ---------------------------------------------------------------------------
  // §3 远/近两条加法路径
  // ---------------------------------------------------------------------------
  logic [63:0] far_fp_c, close_fp_c;
  logic [4:0]  far_fflags, close_fflags;
  logic [10:0] abs_ea_sub_eb;          // |Ea - Eb|（非规格数指数按 1 算）
  logic        exp_b_greater;          // Eb > Ea（原始指数）
  logic [53:0] close_cs1;              // close path 的 {0,sig_b} - {0,sig_a}，最高位 = 借位
  FarPathFloatAdderF64WidenPipeline U_far_path (
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
  ClosePathFloatAdderF64WidenPipeline U_close_path (
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
  assign is_far_path = ~eop | (|abs_ea_sub_eb[10:1])
                     | ((abs_ea_sub_eb == 11'd1) & (exp_a_zero ^ exp_b_zero));

  // ---------------------------------------------------------------------------
  // §4 非加减类指令（第 0 拍组合）
  // ---------------------------------------------------------------------------
  logic is_min, is_max, is_feq, is_flt, is_fle, is_fminm, is_fmaxm, is_fleq, is_fltq, is_addsub;
  assign is_min    = (op_code == OP_FMIN);
  assign is_max    = (op_code == OP_FMAX);
  assign is_feq    = (op_code == OP_FEQ);
  assign is_flt    = (op_code == OP_FLT);
  assign is_fle    = (op_code == OP_FLE);
  assign is_fminm  = (op_code == OP_FMINM);
  assign is_fmaxm  = (op_code == OP_FMAXM);
  assign is_fleq   = (op_code == OP_FLEQ);
  assign is_fltq   = (op_code == OP_FLTQ);
  assign is_addsub = (op_code == OP_FADD) | (op_code == OP_FSUB);

  // b 相对 a 的大小（"b greater" = a < b），用原始符号位
  logic exp_equal, sig_b_greater, sig_b_equal, both_zero;
  logic b_is_greater, b_is_equal, b_is_less;
  assign exp_equal     = (exp_a == exp_b);
  assign sig_b_greater = ~close_cs1[53] & (mant_a != mant_b);
  assign sig_b_equal   = (mant_a == mant_b);
  assign both_zero     = b_is_zero & a_is_zero;
  assign b_is_greater  = (~sign_b & ((sign_a & ~both_zero) | exp_b_greater | (exp_equal & sig_b_greater)))
                       | (sign_b & sign_a & ((~exp_b_greater & ~exp_equal)
                                             | (exp_equal & ~sig_b_greater & ~sig_b_equal)));
  assign b_is_equal    = ((sign_a == sign_b) & exp_equal & sig_b_equal) | both_zero;
  assign b_is_less     = ~b_is_greater & ~b_is_equal;

  // min/max 的「两个都不是 NaN」时的选择；±0 按符号区分（min 取 -0，max 取 +0）
  logic [63:0] pick_min, pick_max;
  assign pick_min = (b_is_less    | (sign_b & both_zero))  ? fp_b : fp_a;
  assign pick_max = (b_is_greater | (~sign_b & both_zero)) ? fp_b : fp_a;

  // fmin/fmax（IEEE 754-2008 minNum：一个 NaN 取另一个）；fminm/fmaxm（754-2019 minimum：有 NaN 即 NaN）
  logic [63:0] result_min, result_max, result_minm, result_maxm;
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
      result_min = pick_min;
      result_max = pick_max;
    end
  end
  assign result_minm = any_nan ? CANONICAL_NAN : pick_min;
  assign result_maxm = any_nan ? CANONICAL_NAN : pick_max;

  // sgnj 系列用 canonical NaN 修正后的操作数：a 整个换成 qNaN，b 只取符号（修正后为 0）
  logic [63:0] fp_a_fixed;
  logic        sign_b_fixed;
  assign fp_a_fixed   = a_is_canonical_nan ? CANONICAL_NAN : fp_a;
  assign sign_b_fixed = ~b_is_canonical_nan & sign_b;

  logic [9:0] fclass_bits;   // bit0 = -Inf … bit9 = qNaN
  assign fclass_bits = a_is_canonical_nan ? 10'h200
                     : {a_is_nan & ~a_is_snan,
                        a_is_snan,
                        ~sign_a & a_is_inf,
                        ~sign_a & ~exp_a_zero & ~exp_a_all_one,
                        ~sign_a & exp_a_zero & mant_a_nz,
                        ~sign_a & exp_a_zero & ~mant_a_nz,
                        sign_a & exp_a_zero & ~mant_a_nz,
                        sign_a & exp_a_zero & mant_a_nz,
                        sign_a & ~exp_a_zero & ~exp_a_all_one,
                        sign_a & a_is_inf};

  // 各 op 编码互不相同，所以 golden 的 Mux1H 就是按 op_code 选（无命中给 0）
  logic [63:0] result_stage0;
  always_comb begin
    case (op_code)
      OP_FMIN:          result_stage0 = result_min;
      OP_FMAX:          result_stage0 = result_max;
      OP_FEQ:           result_stage0 = {63'h0, ~any_nan & b_is_equal};
      OP_FLT, OP_FLTQ:  result_stage0 = {63'h0, ~any_nan & b_is_greater};
      OP_FLE, OP_FLEQ:  result_stage0 = {63'h0, ~any_nan & (b_is_greater | b_is_equal)};
      OP_FSGNJ:         result_stage0 = {sign_b_fixed, fp_a_fixed[62:0]};
      OP_FSGNJN:        result_stage0 = {~sign_b_fixed, fp_a_fixed[62:0]};
      OP_FSGNJX:        result_stage0 = {sign_b_fixed ^ fp_a_fixed[63], fp_a_fixed[62:0]};
      OP_FCLASS:        result_stage0 = {54'h0, fclass_bits};
      OP_FMINM:         result_stage0 = result_minm;
      OP_FMAXM:         result_stage0 = result_maxm;
      default:          result_stage0 = 64'h0;
    endcase
  end

  // 非加减类的 NV：比较 flt/fle 是 signaling 比较（任意 NaN 置 NV），其余只看 SNaN
  logic fflags_nv_stage0;
  assign fflags_nv_stage0 = ((is_min | is_max) & any_snan)
                          | (is_feq & any_snan)
                          | ((is_flt | is_fle) & any_nan)
                          | ((is_fminm | is_fmaxm) & any_snan)
                          | ((is_fltq | is_fleq) & any_snan);

  // ---------------------------------------------------------------------------
  // §5 第 0 拍寄存器（fire 使能，不复位；注释里是 golden 寄存器名）
  // ---------------------------------------------------------------------------
  logic        s1_a_is_zero;            // fp_a_is_zero_reg
  logic        s1_b_is_zero;            // fp_b_is_zero_reg
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
      s1_is_far_path         <= is_far_path;
      s1_flags_invalid       <= any_snan | inf_minus_inf;
      s1_flags_quiet         <= any_nan | a_is_inf | b_is_inf;
      s1_result_is_nan       <= any_nan | inf_minus_inf;
      s1_result_is_inf       <= a_is_inf | b_is_inf;
      s1_inf_result          <= {a_is_inf ? sign_a : (is_sub ^ sign_b), INF_MAGNITUDE};
      // 两零相加：有效相减时只有 RDN 给 -0；有效相加时符号同 a
      s1_both_zero_result    <= {((round_mode == 3'b010) & eop) | (sign_a & ~eop), 63'h0};
      s1_b_signed            <= {is_sub ^ sign_b, fp_b[62:0]};
      s1_a                   <= fp_a;
      s1_use_adder_for_c     <= is_addsub;
      s1_result_stage0       <= result_stage0;
      s1_use_adder_for_flags <= is_addsub;
      s1_fflags_stage0       <= {fflags_nv_stage0, 4'b0};
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍结果选择（优先级照 Scala when 链）
  // ---------------------------------------------------------------------------
  logic [63:0] adder_result;
  logic [4:0]  adder_fflags;
  always_comb begin
    if (s1_result_is_nan)                  adder_result = CANONICAL_NAN;
    else if (s1_result_is_inf)             adder_result = s1_inf_result;
    else if (s1_a_is_zero & s1_b_is_zero)  adder_result = s1_both_zero_result;
    else if (s1_a_is_zero)                 adder_result = s1_b_signed;
    else if (s1_b_is_zero)                 adder_result = s1_a;
    else                                   adder_result = s1_is_far_path ? far_fp_c : close_fp_c;
  end
  assign adder_fflags = s1_flags_invalid                                ? 5'b10000
                      : (s1_flags_quiet | s1_b_is_zero | s1_a_is_zero)  ? 5'b00000
                      : s1_is_far_path                                  ? far_fflags : close_fflags;

  assign fp_c   = s1_use_adder_for_c     ? adder_result : s1_result_stage0;
  assign fflags = s1_use_adder_for_flags ? adder_fflags : s1_fflags_stage0;
endmodule

module FloatAdderF64Pipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [63:0] io_fp_a,
  input  logic [63:0] io_fp_b,
  output logic [63:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic [4:0]  io_op_code,
  input  logic        io_fp_aIsFpCanonicalNAN,
  input  logic        io_fp_bIsFpCanonicalNAN
);
  xs_FloatAdderF64Pipeline_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .is_sub             (io_is_sub),
    .round_mode         (io_round_mode),
    .op_code            (io_op_code),
    .a_is_canonical_nan (io_fp_aIsFpCanonicalNAN),
    .b_is_canonical_nan (io_fp_bIsFpCanonicalNAN),
    .fp_c               (io_fp_c),
    .fflags             (io_fflags)
  );
endmodule
