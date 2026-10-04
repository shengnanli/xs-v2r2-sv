// =============================================================================
// FarPathFloatAdderF64WidenPipeline —— f64 浮点加法的 far path（两拍流水）
//
// 在哪一层：FloatAdderF64WidenPipeline 的 U_far_path（hasMinMaxCompare=true 变体，所以多一个
//   isEfp_bGreater 输出给 min/max/比较用）。设计源：yunsuan/vector/VectorFloatAdder.scala
//   class FarPathFloatAdderF64WidenPipeline（exponentWidth=11，significandWidth=53）。
//   名字里的 "Widen" 指它所属的加法器也接 f32→f64 加宽操作数；加宽在父级完成，本件只见 f64 布局，
//   golden 端口里没有任何加宽相关信号。
// far path 管的情形：有效相加（EOP=0），或有效相减但两指数差 >= 2——此时结果最多左移 1 位，
//   不需要前导零计数；父级按指数差在 far / close 两条路径之间选。本件对 NaN/Inf 不做特判（父级做）。
//
// 第 0 拍（组合 + 打拍）：
//   §1 对阶：非规格数的指数当 1 用；两个方向的指数差各算一份（Adder ×2），大的那个操作数不动，
//      小的那个尾数右移指数差位（FarShiftRightWithMuxInvFirst ×2，EOP 时先取反再移、高位补 1，
//      即直接得到被减数的反码对齐值）。右移源 110 位 = 1 + 53 + 56 位低位延伸。
//   §2 移位溢出：指数差超过 56（= 53 + 3 位保护区）时小数整个掉进 sticky，B 直接取全 EOP。
//   §3 guard / round 第 0 拍就定好打拍；sticky 的原料（移出去的 54 位、及其反码，各一份；"整个移出"
//      标志与小数是否非零）原样打拍，第 1 拍才做归约或——golden 就是这么切级的，照抄。
//   §4 两个加法器同时起跑：FS0 = A + B（不舍入的和），FS1 = A + B + 2ulp（向上舍入备用，
//      加在第 1 位是因为 A/B 都比结果多一位、溢出时还要再右移一位）。两个加法器自身跨两拍。
//   §5 指数候选 EA（EOP 时先减 1，为"相减后左移 1 位"预留）与 EA+1 都打拍，第 1 拍二选一。
// 第 1 拍：
//   §6 按 FS0 最高位判"和溢出（需右移 1 位）"还是"正常"，两种情形各有自己的 LGS 三元组与舍入判定；
//   §7 舍入：四种（正常/溢出 × 不进位/进位）用 Mux1H 选尾数；进位情形直接取 FS1 的对应位。
//   §8 上溢：EA+1 全 1 且结果确实进了一位 → OF，按舍入方向给最大有限数或 Inf；NX = 有效 LGS 非零或 OF。
// 怪癖（照 golden）：
//   - "和溢出"情形的舍入判定也用 EOP_reg（正常/溢出两个判定共用一份，本变体只有一份 EOP 打拍）。
//   - sticky 原料按 54 位宽两份（原码、反码）打拍，而不是先归约成 1 位再打拍。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：Adder ×2、FarShiftRightWithMuxInvFirst ×2、
//   FarPathAdderF64WidenPipeline ×2（U_FS0 / U_FS1）。
// golden 对照：G1-canonical/golden-rtl/FarPathFloatAdderF64WidenPipeline.sv
// =============================================================================
module xs_FarPathFloatAdderF64WidenPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  output logic [63:0] fp_c,
  output logic [4:0]  fflags,           // {NV, DZ, OF, UF, NX}
  output logic [10:0] abs_exp_diff,     // |Ea - Eb|（非规格数指数按 1 算），父级用来分 far/close
  output logic        exp_b_greater     // Eb > Ea（原始指数比较），父级 min/max/比较用
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a, sign_b_eff, eop;
  logic [10:0] exp_a, exp_b;
  logic        exp_a_nz, exp_b_nz;
  logic [52:0] sig_a, sig_b;             // 带隐含位的 53 位有效数（非规格数隐含位为 0）
  assign sign_a     = fp_a[63];
  assign sign_b_eff = fp_b[63] ^ is_sub; // 减法 = 加上符号取反的 b
  assign eop        = sign_a ^ sign_b_eff;   // effective operation：1 = 有效相减
  assign exp_a      = fp_a[62:52];
  assign exp_b      = fp_b[62:52];
  assign exp_a_nz   = |exp_a;
  assign exp_b_nz   = |exp_b;
  assign sig_a      = {exp_a_nz, fp_a[51:0]};
  assign sig_b      = {exp_b_nz, fp_b[51:0]};

  // ---------------------------------------------------------------------------
  // §1 对阶
  // ---------------------------------------------------------------------------
  logic [10:0] exp_a_eff, exp_b_eff;     // 非规格数（指数 0）当指数 1 参与做差
  logic [10:0] diff_a_minus_b, diff_b_minus_a;
  assign exp_a_eff = {exp_a[10:1], exp_a[0] | ~exp_a_nz};
  assign exp_b_eff = {exp_b[10:1], exp_b[0] | ~exp_b_nz};

  Adder U_Efp_aSubEfp_b (
    .io_a (exp_a_eff),
    .io_b (exp_b_eff),
    .io_c (diff_a_minus_b)
  );
  Adder U_Efp_bSubEfp_a (
    .io_a (exp_b_eff),
    .io_b (exp_a_eff),
    .io_c (diff_b_minus_a)
  );

  assign exp_b_greater = exp_b > exp_a;
  assign abs_exp_diff  = exp_b_greater ? diff_b_minus_a : diff_a_minus_b;

  logic [52:0] greater_sig, smaller_sig;
  logic [53:0] add_a;                    // 加法器的 A：大数有效数，EOP 时左移一位（给相减后的左规格化留位）
  assign greater_sig = exp_b_greater ? sig_b : sig_a;
  assign smaller_sig = exp_b_greater ? sig_a : sig_b;
  assign add_a       = eop ? {greater_sig, 1'b0} : {1'b0, greater_sig};

  // 两个操作数都准备一份"若它是小数时"的右移源（110 位）：
  //   有效相加：{0, sig, 56'b0}；有效相减：{~sig, 57 个 1}（反码，右移时高位补 1）。
  logic [109:0] rshift_src_a, rshift_src_b;
  logic [109:0] rshift_a, rshift_b, rshift_smaller;
  assign rshift_src_a = eop ? {~sig_a, {57{1'b1}}} : {1'b0, sig_a, 56'h0};
  assign rshift_src_b = eop ? {~sig_b, {57{1'b1}}} : {1'b0, sig_b, 56'h0};

  FarShiftRightWithMuxInvFirst U_far_rshift_1 (   // b 是小数：右移 Ea-Eb（只用低 6 位，超出由 §2 兜底）
    .io_src        (rshift_src_b),
    .io_shiftValue (diff_a_minus_b[5:0]),
    .io_result     (rshift_b),
    .io_EOP        (eop)
  );
  FarShiftRightWithMuxInvFirst U_far_rshift_2 (   // a 是小数：右移 Eb-Ea
    .io_src        (rshift_src_a),
    .io_shiftValue (diff_b_minus_a[5:0]),
    .io_result     (rshift_a),
    .io_EOP        (eop)
  );
  assign rshift_smaller = exp_b_greater ? rshift_a : rshift_b;

  // ---------------------------------------------------------------------------
  // §2 移位溢出：右移量超过有效数 + 3 位保护区，小数只剩 sticky
  // ---------------------------------------------------------------------------
  logic        shift_out_of_range;
  logic [53:0] add_b;                    // 加法器的 B：对齐后的小数（EOP 时为反码）
  assign shift_out_of_range = abs_exp_diff > 11'd56;
  assign add_b = shift_out_of_range ? {54{eop}} : rshift_smaller[109:56];

  // ---------------------------------------------------------------------------
  // §3 guard / round（结果 LSB 在 rshift[56]）；EOP 时是反码，取反回来
  // ---------------------------------------------------------------------------
  logic guard_bit, round_bit;
  assign guard_bit = ~shift_out_of_range & (eop ? ~rshift_smaller[55] : rshift_smaller[55]);
  assign round_bit = ~shift_out_of_range & (eop ? ~rshift_smaller[54] : rshift_smaller[54]);

  // ---------------------------------------------------------------------------
  // §4 两个加法器（各自跨两拍）：FS0 = A + B，FS1 = A + B + 2ulp
  // ---------------------------------------------------------------------------
  logic [53:0] fs0, fs1;
  FarPathAdderF64WidenPipeline U_FS0 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (add_a),
    .io_B      (add_b),
    .io_result (fs0)
  );
  FarPathAdderF64WidenPipeline U_FS1 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (54'(add_a + 54'h2)),
    .io_B      (add_b),
    .io_result (fs1)
  );

  // ---------------------------------------------------------------------------
  // §5 指数候选与第 0 拍寄存器（注释里是 golden 寄存器名）
  // ---------------------------------------------------------------------------
  logic [10:0] exp_greater, exp_base, exp_base_plus1;
  assign exp_greater    = exp_b_greater ? exp_b : exp_a;
  assign exp_base       = eop ? 11'(exp_greater - 11'd1) : exp_greater;
  assign exp_base_plus1 = 11'(exp_base + 11'd1);

  logic        eop_q;                    // EOP_reg
  logic        rne_q, rtz_q, rdn_q, rup_q, rmm_q;   // RNE_reg … RMM_reg
  logic        guard_q, round_q;         // B_guard_normal_reg / B_round_normal_reg
  logic        shift_out_q;              // B_sticky_normal_reg_r   : 小数整个移出
  logic        smaller_sig_nz_q;         // B_sticky_normal_reg_r_1 : 移出时的 sticky = 小数非零
  logic [53:0] shifted_out_inv_q;        // B_sticky_normal_reg_r_2 : 移出部分的反码（EOP 用）
  logic [53:0] shifted_out_q;            // B_sticky_normal_reg_r_3 : 移出部分（相加用）
  logic        sign_q;                   // far_sign_result_reg
  logic        add_a_lsb_q;              // grs_overflow_r
  logic        add_b_lsb_inv_q;          // grs_overflow_r_1
  logic        exp_base_is_zero_q;       // far_exponent_result_r
  logic [10:0] exp_base_plus1_q;         // far_exponent_result_r_1
  logic [10:0] exp_base_q;               // far_exponent_result_r_2
  logic        exp_plus1_all_one_q;      // OF_r
  always_ff @(posedge clock) begin
    if (fire) begin
      eop_q               <= eop;
      rne_q               <= round_mode == 3'd0;
      rtz_q               <= round_mode == 3'd1;
      rdn_q               <= round_mode == 3'd2;
      rup_q               <= round_mode == 3'd3;
      rmm_q               <= round_mode == 3'd4;
      guard_q             <= guard_bit;
      round_q             <= round_bit;
      shift_out_q         <= shift_out_of_range;
      smaller_sig_nz_q    <= |smaller_sig;
      shifted_out_inv_q   <= ~rshift_smaller[53:0];
      shifted_out_q       <= rshift_smaller[53:0];
      sign_q              <= exp_b_greater ? sign_b_eff : sign_a;
      add_a_lsb_q         <= add_a[0];
      add_b_lsb_inv_q     <= ~add_b[0];
      exp_base_is_zero_q  <= exp_base == 11'h0;
      exp_base_plus1_q    <= exp_base_plus1;
      exp_base_q          <= exp_base;
      exp_plus1_all_one_q <= &exp_base_plus1;
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍：sticky 归约；正常 / 溢出两种情形的 LGS 与舍入判定
  // ---------------------------------------------------------------------------
  logic sticky_bit, round_sticky;
  assign sticky_bit   = shift_out_q ? smaller_sig_nz_q
                                    : (eop_q ? (|shifted_out_inv_q) : (|shifted_out_q));
  assign round_sticky = round_q | sticky_bit;

  logic sum_overflow;                    // FS0 最高位为 1：和多出一位，要右移 1 位
  assign sum_overflow = fs0[53];

  // 正常情形的 {L, G, R|S}：相减时 {G, R|S} 是反码，+1 补成真值（2 位回绕）
  logic [2:0] lgs_normal;
  assign lgs_normal = {fs0[0], eop_q ? 2'(~{guard_q, round_sticky} + 2'd1) : {guard_q, round_sticky}};

  // 溢出情形（和要右移 1 位）的 {G', R', S'}：原 LSB 下移成 G'，原 G 并入 sticky；
  // 相减时用 "A 的 LSB 后接 00" 减去 "B 的 LSB 反码、G、R|S" 直接得到真值
  logic [2:0] grs_overflow, lgs_overflow;
  assign grs_overflow = eop_q ? 3'({add_a_lsb_q, 2'b00} - {add_b_lsb_inv_q, guard_q, round_sticky})
                              : {fs0[0], guard_q, round_sticky};
  assign lgs_overflow = {fs0[1], grs_overflow[2], grs_overflow[1] | grs_overflow[0]};

  // 舍入进位判定（同一张表用两次）：EOP 且 G/S 全 0 时也算"进位"——相减的反码 +1 落在 LSB 上
  function automatic logic round_up(input logic       eop_s1,
                                    input logic [2:0] lgs,
                                    input logic       sign,
                                    input logic       rne, rdn, rup, rmm);
    round_up = (eop_s1 & ~lgs[1] & ~lgs[0])
             | (rne & lgs[1] & (lgs[2] | lgs[0]))
             | (rdn & sign & (lgs[1] | lgs[0]))
             | (rup & ~sign & (lgs[1] | lgs[0]))
             | (rmm & lgs[1]);
  endfunction

  logic round_up_normal, round_up_overflow;
  assign round_up_normal   = round_up(eop_q, lgs_normal, sign_q, rne_q, rdn_q, rup_q, rmm_q);
  assign round_up_overflow = round_up(eop_q, lgs_overflow, sign_q, rne_q, rdn_q, rup_q, rmm_q);

  // 正常情形下舍入进位又让和溢出：FS1 最高位为 1
  logic normal_round_carries_out;
  assign normal_round_carries_out = fs1[53] & fs0[0] & round_up_normal;

  // ---------------------------------------------------------------------------
  // §7 尾数：四种情形 Mux1H
  // ---------------------------------------------------------------------------
  logic sel_normal_keep, sel_normal_up, sel_overflow_keep, sel_overflow_up;
  assign sel_normal_keep   = ~sum_overflow & ((~fs0[0] & round_up_normal) | ~round_up_normal);
  assign sel_normal_up     = ~sum_overflow & fs0[0] & round_up_normal;
  assign sel_overflow_keep =  sum_overflow & ((~fs0[1] & round_up_overflow) | ~round_up_overflow);
  assign sel_overflow_up   =  sum_overflow & fs0[1] & round_up_overflow;

  // "keep"：LSB 为 0 时进位只需把 LSB 置 1（异或），不必等进位链；"up"：LSB 为 1，取 FS1
  logic [51:0] frac_normal_keep, frac_normal_up, frac_overflow_keep, frac_overflow_up;
  assign frac_normal_keep   = {fs0[51:1], fs0[0] ^ round_up_normal};
  assign frac_normal_up     = {fs1[51:1], 1'b0};
  assign frac_overflow_keep = {fs0[52:2], fs0[1] ^ round_up_overflow};
  assign frac_overflow_up   = fs1[52:1];

  logic [51:0] frac_result;
  assign frac_result = ({52{sel_normal_keep}}   & frac_normal_keep)
                     | ({52{sel_normal_up}}     & frac_normal_up)
                     | ({52{sel_overflow_keep}} & frac_overflow_keep)
                     | ({52{sel_overflow_up}}   & frac_overflow_up);

  // ---------------------------------------------------------------------------
  // §8 指数、上溢与输出
  // ---------------------------------------------------------------------------
  logic        exp_takes_plus1;          // 和溢出 / 舍入进位溢出 / 非规格数相加进位成规格数
  logic [10:0] exp_result;
  logic        overflow, inexact;
  assign exp_takes_plus1 = sum_overflow | normal_round_carries_out
                         | (exp_base_is_zero_q & fs0[52]);
  assign exp_result      = exp_takes_plus1 ? exp_base_plus1_q : exp_base_q;
  assign overflow        = exp_plus1_all_one_q & (sum_overflow | normal_round_carries_out);
  assign inexact         = (sum_overflow ? (|lgs_overflow[1:0]) : (|lgs_normal[1:0])) | overflow;

  // 上溢：朝零 / 朝反方向舍入给最大有限数，否则给 Inf
  logic [62:0] overflow_magnitude;
  assign overflow_magnitude = (rtz_q | (rdn_q & ~sign_q) | (rup_q & sign_q)) ? 63'h7FEF_FFFF_FFFF_FFFF
                                                                             : 63'h7FF0_0000_0000_0000;
  assign fp_c   = {sign_q, overflow ? overflow_magnitude : {exp_result, frac_result}};
  assign fflags = {2'b00, overflow, 1'b0, inexact};
endmodule

module FarPathFloatAdderF64WidenPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [63:0] io_fp_a,
  input  logic [63:0] io_fp_b,
  output logic [63:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  output logic [10:0] io_absEaSubEb,
  output logic        io_isEfp_bGreater
);
  xs_FarPathFloatAdderF64WidenPipeline_core u_core (
    .clock         (clock),
    .fire          (io_fire),
    .fp_a          (io_fp_a),
    .fp_b          (io_fp_b),
    .is_sub        (io_is_sub),
    .round_mode    (io_round_mode),
    .fp_c          (io_fp_c),
    .fflags        (io_fflags),
    .abs_exp_diff  (io_absEaSubEb),
    .exp_b_greater (io_isEfp_bGreater)
  );
endmodule
