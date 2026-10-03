// =============================================================================
// FloatAdderF32WidenF16MixedPipeline.sv —— f32 / f16 / f16→f32 加宽 混合浮点加法器（两拍流水）
//
// 在哪一层：向量浮点加法单元 VectorFloatAdder 的一条 32 位 lane（hasMinMaxCompare=true 的变体，
//   所以除 fadd/fsub 外还做 min/max/比较/符号注入/fclass/merge/move/归约的掩码特判）。
// 设计源：yunsuan/vector/VectorFloatAdder.scala class FloatAdderF32WidenF16MixedPipeline。
//
// 结构：
//   §1 输入整形：f16 操作数先铺成 f32 布局（符号、3 位 0 + 5 位指数、10 位尾数 + 13 位 0）；
//      加宽指令（res_widening）直接用前级已转成 f32 的 widen_a / widen_b。
//   §2 特殊值判定：按"这个操作数原来是不是 f16"决定零指数（f16 铺成 f32 后指数 0x66 也算零）与
//      全 1 指数（f16 加宽后是 0x8F）的判法，再得 NaN / SNaN / Inf / 零。
//   §3 远/近路径：EOP（有效相减）且指数差 <= 1 走 close path，否则 far path；两条路径都是独立的
//      两拍流水子模块（本仓重写件，fpaddpath-sqrtblock lane 签核；证明时 ref golden / impl 重写件两侧白盒）。
//   §4 第 0 拍打拍的特殊结果选择位（NaN / Inf / 加宽且有零操作数三种直通），第 1 拍按优先级选结果。
//   §5 min/max/比较/sgnj/fclass/merge/move/归约掩码特判：全部在第 0 拍算好并打拍，第 1 拍由
//      "是不是加减类（op 0/1，或归约求和且未被掩码）"选加法器结果还是这组结果。
// 怪癖（照 golden）：
//   - fp_aIsFpCanonicalNAN / fp_bIsFpCanonicalNAN 在本例化里恒 0，golden 已消掉端口与分支。
//   - "是不是加减类"这个选择位打了两份完全相同的寄存器（io_fp_c_r / io_fflags_r），一份选 fp_c 一份选 fflags；
//     NaN 相关的打拍位也有多份同源（golden r / r_2 / r_1 …）。本件逐份照抄，不合并。
//   - 所有寄存器 RegEnable(fire)，不复位。
//   - fsum_ore 被掩码时的 Mux1H 条件里 ~mask[0] 重复出现一次（golden 原样），功能上等价于一次。
// 子模块：FarPathF32WidenF16MixedPipeline / ClosePathF32WidenF16MixedPipeline（实例名与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/FloatAdderF32WidenF16MixedPipeline.sv
// =============================================================================
module xs_FloatAdderF32WidenF16MixedPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [31:0] fp_a,
  input  logic [31:0] fp_b,
  input  logic [31:0] widen_a,            // f16→f32 加宽后的 a（前级转好）
  input  logic [31:0] widen_b,
  input  logic        is_sub,
  input  logic        mask,               // fmerge 的选择位
  input  logic [2:0]  round_mode,
  input  logic [1:0]  fp_format,          // bit0: 1=f32 0=f16
  input  logic        opb_widening,       // 只有 b 加宽（vfwadd.wv）
  input  logic        res_widening,       // 结果是加宽格式
  input  logic [4:0]  op_code,
  input  logic [1:0]  mask_for_reduction,
  input  logic        is_vfwredosum,
  output logic [31:0] fp_c,
  output logic [4:0]  fflags
);
  // ---- op_code 编码（VfaddOpCode）----
  localparam logic [4:0] OP_FADD = 5'h00, OP_FSUB = 5'h01, OP_FMIN = 5'h02, OP_FMAX = 5'h03,
                         OP_FMERGE = 5'h04, OP_FMOVE = 5'h05, OP_FSGNJ = 5'h06, OP_FSGNJN = 5'h07,
                         OP_FSGNJX = 5'h08, OP_FEQ = 5'h09, OP_FNE = 5'h0A, OP_FLT = 5'h0B,
                         OP_FLE = 5'h0C, OP_FGT = 5'h0D, OP_FGE = 5'h0E, OP_FCLASS = 5'h0F,
                         OP_FMV_F_S = 5'h11, OP_FMV_S_F = 5'h12, OP_FMIN_RE = 5'h14,
                         OP_FMAX_RE = 5'h15, OP_FSUM_ORE = 5'h16, OP_FSUM_URE = 5'h1A;

  // ---- §1 输入整形 ----
  logic        res_is_f32;
  logic [31:0] fp_a_16as32, fp_b_16as32;
  logic [31:0] fp_a_to32, fp_b_to32;
  assign res_is_f32  = fp_format[0];
  assign fp_a_16as32 = {fp_a[15], 3'b0, fp_a[14:10], fp_a[9:0], 13'b0};
  assign fp_b_16as32 = {fp_b[15], 3'b0, fp_b[14:10], fp_b[9:0], 13'b0};
  assign fp_a_to32 = (res_widening & ~opb_widening)  ? widen_a : (res_is_f32 ? fp_a : fp_a_16as32);
  assign fp_b_to32 = (res_widening & ~is_vfwredosum) ? widen_b : (res_is_f32 ? fp_b : fp_b_16as32);

  logic        sign_a, sign_b, eop;
  logic [7:0]  exp_a, exp_b;
  logic [22:0] mant_a, mant_b;
  assign sign_a = fp_a_to32[31];  assign sign_b = fp_b_to32[31];
  assign exp_a  = fp_a_to32[30:23]; assign exp_b = fp_b_to32[30:23];
  assign mant_a = fp_a_to32[22:0]; assign mant_b = fp_b_to32[22:0];
  assign eop = sign_a ^ is_sub ^ sign_b;   // 有效操作是相减

  // ---- §2 特殊值判定 ----
  logic fp_a_is_f16, fp_b_is_f16;
  logic exp_a_is_zero, exp_b_is_zero, exp_a_all_one, exp_b_all_one;
  logic mant_a_nz, mant_b_nz;
  assign fp_a_is_f16 = ~res_is_f32 | (res_widening & ~opb_widening);
  assign fp_b_is_f16 = ~res_is_f32 | (res_widening & ~is_vfwredosum);
  assign exp_a_is_zero = (exp_a == 8'h00) | (fp_a_is_f16 & (exp_a == 8'h66));
  assign exp_b_is_zero = (exp_b == 8'h00) | (fp_b_is_f16 & (exp_b == 8'h66));
  assign exp_a_all_one = fp_a_is_f16 ? (res_widening ? (exp_a == 8'h8F) : (&fp_a[14:10])) : (&fp_a[30:23]);
  assign exp_b_all_one = fp_b_is_f16 ? (res_widening ? (exp_b == 8'h8F) : (&fp_b[14:10])) : (&fp_b[30:23]);
  assign mant_a_nz = |mant_a;
  assign mant_b_nz = |mant_b;

  logic a_is_nan, a_is_snan, a_is_inf, a_is_zero;
  logic b_is_nan, b_is_snan, b_is_inf, b_is_zero;
  assign a_is_nan  = exp_a_all_one & mant_a_nz;
  assign a_is_snan = exp_a_all_one & mant_a_nz & ~fp_a_to32[22];
  assign a_is_inf  = exp_a_all_one & ~mant_a_nz;
  assign a_is_zero = exp_a_is_zero & ~mant_a_nz;
  assign b_is_nan  = exp_b_all_one & mant_b_nz;
  assign b_is_snan = exp_b_all_one & mant_b_nz & ~fp_b_to32[22];
  assign b_is_inf  = exp_b_all_one & ~mant_b_nz;
  assign b_is_zero = exp_b_is_zero & ~mant_b_nz;

  logic any_snan, any_nan, inf_minus_inf;
  assign any_snan      = a_is_snan | b_is_snan;
  assign any_nan       = a_is_nan | b_is_nan;
  assign inf_minus_inf = eop & a_is_inf & b_is_inf;

  // ---- §3 远/近路径 ----
  logic [31:0] far_fp_c, close_fp_c;
  logic [4:0]  far_fflags, close_fflags;
  logic [7:0]  abs_ea_sub_eb;
  logic        exp_b_greater;
  logic [24:0] close_cs1;
  FarPathF32WidenF16MixedPipeline U_far_path (
    .clock             (clock),
    .io_fire           (fire),
    .io_fp_a           (fp_a_to32),
    .io_fp_b           (fp_b_to32),
    .io_fp_c           (far_fp_c),
    .io_is_sub         (is_sub),
    .io_round_mode     (round_mode),
    .io_fflags         (far_fflags),
    .io_absEaSubEb     (abs_ea_sub_eb),
    .io_res_is_f32     (res_is_f32),
    .io_isEfp_bGreater (exp_b_greater)
  );
  ClosePathF32WidenF16MixedPipeline U_close_path (
    .clock         (clock),
    .io_fire       (fire),
    .io_fp_a       (fp_a_to32),
    .io_fp_b       (fp_b_to32),
    .io_fp_c       (close_fp_c),
    .io_round_mode (round_mode),
    .io_fflags     (close_fflags),
    .io_res_is_f32 (res_is_f32),
    .io_CS1        (close_cs1)
  );
  logic is_far_path;
  assign is_far_path = ~eop | (eop & (|abs_ea_sub_eb[7:1]))
                     | ((abs_ea_sub_eb == 8'd1) & (exp_a_is_zero ^ exp_b_is_zero));

  // ---- §5（第 0 拍）min/max/比较/符号注入/fclass/merge/move/归约 ----
  logic is_min, is_max, is_feq, is_fne, is_flt, is_fle, is_fgt, is_fge;
  logic is_fsum_ure, is_fmin_re, is_fmax_re, is_fsum_ore, is_addsub;
  assign is_min = (op_code == OP_FMIN);   assign is_max = (op_code == OP_FMAX);
  assign is_feq = (op_code == OP_FEQ);    assign is_fne = (op_code == OP_FNE);
  assign is_flt = (op_code == OP_FLT);    assign is_fle = (op_code == OP_FLE);
  assign is_fgt = (op_code == OP_FGT);    assign is_fge = (op_code == OP_FGE);
  assign is_fsum_ure = (op_code == OP_FSUM_URE);
  assign is_fmin_re  = (op_code == OP_FMIN_RE);
  assign is_fmax_re  = (op_code == OP_FMAX_RE);
  assign is_fsum_ore = (op_code == OP_FSUM_ORE);
  assign is_addsub   = (op_code == OP_FADD) | (op_code == OP_FSUB);

  // b 与 a 的大小关系（指数比较借 far path 的 isEfp_bGreater，尾数比较借 close path 的 CS1 进位）
  logic exp_equal, sig_b_greater, sig_b_equal, both_zero;
  logic b_is_greater, b_is_equal, b_is_less;
  assign exp_equal     = (exp_a == exp_b);
  assign sig_b_greater = ~close_cs1[24] & (mant_a != mant_b);
  assign sig_b_equal   = (mant_a == mant_b);
  assign both_zero     = b_is_zero & a_is_zero;
  assign b_is_greater  = (~sign_b & ((sign_a & ~both_zero) | exp_b_greater | (exp_equal & sig_b_greater)))
                       | (sign_b & sign_a & ((~exp_b_greater & ~exp_equal) | (exp_equal & ~sig_b_greater & ~sig_b_equal)));
  assign b_is_equal    = ((sign_a == sign_b) & exp_equal & sig_b_equal) | both_zero;
  assign b_is_less     = ~b_is_greater & ~b_is_equal;

  logic [31:0] out_nan, fp_a_16_or_32, fp_b_16_or_32, re_masked_one_out;
  logic        zero_sign, no_nan, both_nan, mask_none, mask_all;
  logic [31:0] result_min, result_max;
  logic        result_feq;
  assign out_nan       = res_is_f32 ? 32'h7FC0_0000 : 32'h0000_7E00;   // canonical NaN
  assign zero_sign     = (round_mode != 3'b010);                        // 全掩码归约求和的"零"的符号
  assign fp_a_16_or_32 = res_is_f32 ? fp_a : {16'b0, fp_a[15:0]};
  assign fp_b_16_or_32 = res_is_f32 ? fp_b : {16'b0, fp_b[15:0]};
  assign no_nan   = ~(a_is_nan | b_is_nan);
  assign both_nan = a_is_nan & b_is_nan;
  assign mask_none = (mask_for_reduction == 2'b00);
  assign mask_all  = &mask_for_reduction;
  assign re_masked_one_out = mask_for_reduction[0] ? fp_a : fp_b;
  // min/max：一个 NaN 取另一个，两个 NaN 给 canonical NaN；±0 比较按符号
  assign result_min = (no_nan ? ((b_is_less | (sign_b & both_zero)) ? fp_b_16_or_32 : fp_a_16_or_32) : 32'h0)
                    | ((~a_is_nan & b_is_nan) ? fp_a_16_or_32 : 32'h0)
                    | ((a_is_nan & ~b_is_nan) ? fp_b_16_or_32 : 32'h0)
                    | (both_nan ? out_nan : 32'h0);
  assign result_max = (no_nan ? ((b_is_greater | (~sign_b & both_zero)) ? fp_b_16_or_32 : fp_a_16_or_32) : 32'h0)
                    | ((~a_is_nan & b_is_nan) ? fp_a_16_or_32 : 32'h0)
                    | ((a_is_nan & ~b_is_nan) ? fp_b_16_or_32 : 32'h0)
                    | (both_nan ? out_nan : 32'h0);
  assign result_feq = ~any_nan & b_is_equal;

  logic [9:0] fclass_bits;   // fclass 的 10 个分类位（bit0 = -Inf … bit9 = qNaN）
  assign fclass_bits = {a_is_nan & ~a_is_snan,
                        a_is_snan,
                        ~sign_a & a_is_inf,
                        ~sign_a & ~exp_a_is_zero & ~exp_a_all_one,
                        ~sign_a & exp_a_is_zero & mant_a_nz,
                        ~sign_a & exp_a_is_zero & ~mant_a_nz,
                        sign_a & exp_a_is_zero & ~mant_a_nz,
                        sign_a & exp_a_is_zero & mant_a_nz,
                        sign_a & ~exp_a_is_zero & ~exp_a_all_one,
                        sign_a & a_is_inf};

  logic [31:0] result_stage0;   // 非加减类指令的结果（Mux1H，按 op 相或）
  assign result_stage0 =
      (is_min ? result_min : 32'h0)
    | (is_max ? result_max : 32'h0)
    | (is_feq ? {31'h0, result_feq} : 32'h0)
    | (is_fne ? {31'h0, ~result_feq} : 32'h0)
    | (is_flt ? {31'h0, ~any_nan & b_is_greater} : 32'h0)
    | (is_fle ? {31'h0, ~any_nan & (b_is_greater | b_is_equal)} : 32'h0)
    | (is_fgt ? {31'h0, ~any_nan & b_is_less} : 32'h0)
    | (is_fge ? {31'h0, ~any_nan & (b_is_less | b_is_equal)} : 32'h0)
    | ((op_code == OP_FSGNJ)  ? (res_is_f32 ? {fp_b[31], fp_a[30:0]}            : {16'h0, fp_b[15], fp_a[14:0]})            : 32'h0)
    | ((op_code == OP_FSGNJN) ? (res_is_f32 ? {~fp_b[31], fp_a[30:0]}           : {16'h0, ~fp_b[15], fp_a[14:0]})           : 32'h0)
    | ((op_code == OP_FSGNJX) ? (res_is_f32 ? {fp_b[31] ^ fp_a[31], fp_a[30:0]} : {16'h0, fp_b[15] ^ fp_a[15], fp_a[14:0]}) : 32'h0)
    | ((op_code == OP_FCLASS) ? {22'h0, fclass_bits} : 32'h0)
    | ((op_code == OP_FMERGE) ? (res_is_f32 ? (mask ? fp_b : fp_a) : {16'h0, mask ? fp_b[15:0] : fp_a[15:0]}) : 32'h0)
    | (((op_code == OP_FMOVE) | (op_code == OP_FMV_F_S) | (op_code == OP_FMV_S_F))
         ? (res_is_f32 ? fp_b : {16'h0, fp_b[15:0]}) : 32'h0)
    | ((is_fsum_ure & ~mask_all)
         ? (mask_none ? (res_is_f32 ? {zero_sign, 31'h0} : {16'h0, zero_sign, 15'h0}) : re_masked_one_out) : 32'h0)
    | (is_fmax_re ? (mask_none ? out_nan : (mask_all ? result_max : re_masked_one_out)) : 32'h0)
    | (is_fmin_re ? (mask_none ? out_nan : (mask_all ? result_min : re_masked_one_out)) : 32'h0)
    | ((is_fsum_ore & ~mask_for_reduction[0] & ~mask_for_reduction[0]) ? fp_b : 32'h0);

  logic fflags_nv_stage0;
  assign fflags_nv_stage0 = ((is_min | is_max) & any_snan)
                          | ((is_feq | is_fne) & any_snan)
                          | ((is_flt | is_fle | is_fgt | is_fge) & any_nan)
                          | ((is_fmax_re | is_fmin_re)
                             & ((mask_for_reduction[0] & a_is_snan) | (mask_for_reduction[1] & b_is_snan)));

  // 走加法器结果：fadd/fsub，或归约求和且本 lane 未被掩码
  logic use_adder;
  assign use_adder = is_addsub | (is_fsum_ure & mask_all) | (is_fsum_ore & mask_for_reduction[0]);

  // ---- §4 流水寄存器（fire 使能，不复位；一份对应 golden 一个 reg）----
  logic        s1_is_far_path;                 // is_far_path_reg
  logic        s1_fflags_invalid;              // r      : SNaN 或 Inf-Inf → NV
  logic        s1_fflags_quiet;                // r_1    : NaN/Inf/加宽零 → fflags 全 0
  logic        s1_res_is_f32;                  // res_is_f32_reg
  logic        s1_out_inf_sign;                // out_infinite_sign_reg
  logic        s1_result_is_nan;               // r_2    : NaN 或 Inf-Inf → canonical NaN
  logic        s1_result_is_inf;               // r_3
  logic        s1_widen_both_zero;             // r_4    : 加宽且 a、b 都是零
  logic        s1_widen_zero_sign;             // float_adder_result_r
  logic        s1_widen_a_zero;                // r_5
  logic [31:0] s1_b_signed;                    // float_adder_result_r_1 : b 带上运算符号
  logic        s1_widen_b_zero;                // r_6
  logic [31:0] s1_a_to32;                      // float_adder_result_r_2
  logic        s1_use_adder_for_c;             // io_fp_c_r
  logic [31:0] s1_result_stage0;               // io_fp_c_r_1
  logic        s1_use_adder_for_flags;         // io_fflags_r（与上面那份同源，golden 两份）
  logic [4:0]  s1_fflags_stage0;               // io_fflags_r_1

  always_ff @(posedge clock) begin
    if (fire) begin
      s1_is_far_path         <= is_far_path;
      s1_fflags_invalid      <= any_snan | inf_minus_inf;
      s1_fflags_quiet        <= a_is_nan | b_is_nan | a_is_inf | b_is_inf | ((b_is_zero | a_is_zero) & res_widening);
      s1_res_is_f32          <= res_is_f32;
      s1_out_inf_sign        <= a_is_inf ? sign_a : (is_sub ^ sign_b);
      s1_result_is_nan       <= any_nan | inf_minus_inf;
      s1_result_is_inf       <= a_is_inf | b_is_inf;
      s1_widen_both_zero     <= res_widening & a_is_zero & b_is_zero;
      s1_widen_zero_sign     <= ((round_mode == 3'b010) & eop) | (sign_a & ~eop);
      s1_widen_a_zero        <= res_widening & a_is_zero;
      s1_b_signed            <= {is_sub ^ sign_b, fp_b_to32[30:0]};
      s1_widen_b_zero        <= res_widening & b_is_zero;
      s1_a_to32              <= fp_a_to32;
      s1_use_adder_for_c     <= use_adder;
      s1_result_stage0       <= result_stage0;
      s1_use_adder_for_flags <= use_adder;
      s1_fflags_stage0       <= {fflags_nv_stage0, 4'b0};
    end
  end

  // ---- §4（第 1 拍）结果选择 ----
  logic [31:0] out_fp32;
  logic [31:0] out_nan_s1, out_inf_s1, out_fp32_packed, adder_result;
  logic [4:0]  adder_fflags;
  assign out_fp32        = s1_is_far_path ? far_fp_c : close_fp_c;
  assign out_nan_s1      = s1_res_is_f32 ? 32'h7FC0_0000 : 32'h0000_7E00;
  assign out_inf_s1      = s1_res_is_f32 ? {s1_out_inf_sign, 8'hFF, 23'h0} : {16'h0, s1_out_inf_sign, 5'h1F, 10'h0};
  assign out_fp32_packed = s1_res_is_f32 ? out_fp32 : {16'h0, out_fp32[31], out_fp32[27:13]};  // f16 结果从 f32 布局抽回
  assign adder_result = s1_result_is_nan   ? out_nan_s1
                      : s1_result_is_inf   ? out_inf_s1
                      : s1_widen_both_zero ? {s1_widen_zero_sign, 31'h0}
                      : s1_widen_a_zero    ? s1_b_signed
                      : s1_widen_b_zero    ? s1_a_to32
                      :                      out_fp32_packed;
  assign adder_fflags = s1_fflags_invalid ? 5'b10000
                      : s1_fflags_quiet   ? 5'b00000
                      : s1_is_far_path    ? far_fflags : close_fflags;

  assign fp_c   = s1_use_adder_for_c     ? adder_result : s1_result_stage0;
  assign fflags = s1_use_adder_for_flags ? adder_fflags : s1_fflags_stage0;
endmodule

module FloatAdderF32WidenF16MixedPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [31:0] io_fp_a,
  input  logic [31:0] io_fp_b,
  input  logic [31:0] io_widen_a,
  input  logic [31:0] io_widen_b,
  output logic [31:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic        io_mask,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic [1:0]  io_fp_format,
  input  logic        io_opb_widening,
  input  logic        io_res_widening,
  input  logic [4:0]  io_op_code,
  input  logic [1:0]  io_maskForReduction,
  input  logic        io_is_vfwredosum
);
  xs_FloatAdderF32WidenF16MixedPipeline_core u_core (
    .clock              (clock),
    .fire               (io_fire),
    .fp_a               (io_fp_a),
    .fp_b               (io_fp_b),
    .widen_a            (io_widen_a),
    .widen_b            (io_widen_b),
    .is_sub             (io_is_sub),
    .mask               (io_mask),
    .round_mode         (io_round_mode),
    .fp_format          (io_fp_format),
    .opb_widening       (io_opb_widening),
    .res_widening       (io_res_widening),
    .op_code            (io_op_code),
    .mask_for_reduction (io_maskForReduction),
    .is_vfwredosum      (io_is_vfwredosum),
    .fp_c               (io_fp_c),
    .fflags             (io_fflags)
  );
endmodule
