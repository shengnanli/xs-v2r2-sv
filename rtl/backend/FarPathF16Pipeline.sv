// =============================================================================
// FarPathF16Pipeline —— 纯 f16 浮点加法的 far path（两拍流水）
//
// 在哪一层：FloatAdderF16Pipeline 的 U_far_path（hasMinMaxCompare=true 变体，多一个 isEfp_bGreater 输出
//   给 min/max/比较用）。设计源：yunsuan/vector/VectorFloatAdder.scala class FarPathF16Pipeline
//   （exponentWidth=5、significandWidth=11）。与已签的 FarPathF32WidenF16MixedPipeline 是同一套算法，
//   但只服务 f16，且寄存器切分不同：本件把 guard/round 打拍、把 sticky 的原料（右移结果低 12 位的
//   原码与反码两份）打拍，到第 1 拍再归约成 sticky。
// far path 管的情形：有效相加（EOP=0），或有效相减但两指数差 >= 2——结果最多左移 1 位，不需要前导零计数。
//
// 第 0 拍：
//   §1 对阶：非规格数的指数当 1 用；两个方向的指数差各算一份（Adder_18 ×2），小数的有效数右移指数差位
//      （FarShiftRightWithMuxInvFirst_18 ×2，EOP 时先取反、低位补 1，得到被减数的反码对齐值）。
//   §2 移位溢出：指数差 > 14 时小数整个掉进 sticky，加数 B 直接取全 EOP。
//   §3 guard / round 当拍定值打拍；sticky 的三种来源（移位溢出→小数非零；相加→低 12 位或；
//      相减→低 12 位反码的或）各自打拍，第 1 拍再选。
//   §4 两个加法器同时起跑（各自跨两拍）：FS0 = A + B，FS1 = A + B + 2（向上舍入备用；A/B 比结果多一位，
//      所以 +1ulp 加在第 1 位）。
//   §5 指数候选 EA（EOP 时先减 1）与 EA+1 都打拍，第 1 拍二选一。
// 第 1 拍：
//   §6 正常 / 溢出（FS0 最高位为 1，和要右移一位）两种情形各自的 LGS 与舍入进位判定；
//   §7 尾数四选一（Mux1H）；§8 指数、上溢（OF）、不精确（NX）与输出。
// 怪癖（照 golden）：
//   - EOP 打了两份寄存器：一份给 LGS 补码 / 舍入（EOP_reg），一份给 sticky 选源（Scala 里内联的 RegEnable）。
//   - 溢出情形的 grs 在非 EOP 时用的是 FS0[0]（Scala 原文如此），不是 A/B 的 LSB 之和。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：Adder_18 ×2、FarShiftRightWithMuxInvFirst_18 ×2、
//   FarPathAdderF16Pipeline ×2（U_FS0 / U_FS1）。
// golden 对照：G1-canonical/golden-rtl/FarPathF16Pipeline.sv
// =============================================================================
module xs_FarPathF16Pipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [15:0] fp_a,
  input  logic [15:0] fp_b,
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  output logic [15:0] fp_c,
  output logic [4:0]  fflags,
  output logic [4:0]  abs_exp_diff,     // |Ea - Eb|（非规格数指数按 1 算），父级用来分 far/close
  output logic        exp_b_greater     // Eb > Ea（原始指数比较）
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a, sign_b_eff, eop;
  logic [4:0]  exp_a, exp_b;
  logic        exp_a_nz, exp_b_nz;
  logic [10:0] sig_a, sig_b;              // 带隐含位的 11 位有效数（非规格数隐含位为 0）
  assign sign_a     = fp_a[15];
  assign sign_b_eff = fp_b[15] ^ is_sub;  // 减法 = 加上符号取反的 b
  assign eop        = sign_a ^ sign_b_eff;    // effective operation：1 = 有效相减
  assign exp_a      = fp_a[14:10];
  assign exp_b      = fp_b[14:10];
  assign exp_a_nz   = |exp_a;
  assign exp_b_nz   = |exp_b;
  assign sig_a      = {exp_a_nz, fp_a[9:0]};
  assign sig_b      = {exp_b_nz, fp_b[9:0]};

  // ---------------------------------------------------------------------------
  // §1 对阶
  // ---------------------------------------------------------------------------
  logic [4:0] exp_a_eff, exp_b_eff;       // 非规格数（指数 0）当指数 1 参与做差
  logic [4:0] diff_a_minus_b, diff_b_minus_a;
  assign exp_a_eff = {exp_a[4:1], exp_a[0] | ~exp_a_nz};
  assign exp_b_eff = {exp_b[4:1], exp_b[0] | ~exp_b_nz};

  Adder_18 U_Efp_aSubEfp_b (
    .io_a (exp_a_eff),
    .io_b (exp_b_eff),
    .io_c (diff_a_minus_b)
  );
  Adder_18 U_Efp_bSubEfp_a (
    .io_a (exp_b_eff),
    .io_b (exp_a_eff),
    .io_c (diff_b_minus_a)
  );

  assign exp_b_greater = exp_b > exp_a;
  assign abs_exp_diff  = exp_b_greater ? diff_b_minus_a : diff_a_minus_b;

  logic [10:0] greater_sig, smaller_sig;
  logic [11:0] add_a;                     // 加法器 A：大数有效数，EOP 时左移一位（给相减后的左规格化留位）
  assign greater_sig = exp_b_greater ? sig_b : sig_a;
  assign smaller_sig = exp_b_greater ? sig_a : sig_b;
  assign add_a       = eop ? {greater_sig, 1'b0} : {1'b0, greater_sig};

  // 两个操作数各准备一份"若它是小数时"的右移源（26 位 = 1 + 11 + 14 位低位延伸）：
  //   有效相加：{0, sig, 14'b0}；有效相减：{~sig, 15 个 1}（反码，右移时高位补 1）。
  logic [25:0] rshift_src_a, rshift_src_b;
  logic [25:0] rshift_a, rshift_b, rshift_smaller;
  assign rshift_src_a = eop ? {~sig_a, 15'h7FFF} : {1'b0, sig_a, 14'h0};
  assign rshift_src_b = eop ? {~sig_b, 15'h7FFF} : {1'b0, sig_b, 14'h0};

  FarShiftRightWithMuxInvFirst_18 U_far_rshift_1 (   // b 是小数：右移 Ea-Eb
    .io_src        (rshift_src_b),
    .io_shiftValue (diff_a_minus_b[3:0]),
    .io_result     (rshift_b),
    .io_EOP        (eop)
  );
  FarShiftRightWithMuxInvFirst_18 U_far_rshift_2 (   // a 是小数：右移 Eb-Ea
    .io_src        (rshift_src_a),
    .io_shiftValue (diff_b_minus_a[3:0]),
    .io_result     (rshift_a),
    .io_EOP        (eop)
  );
  assign rshift_smaller = exp_b_greater ? rshift_a : rshift_b;

  // ---------------------------------------------------------------------------
  // §2 移位溢出：右移量超过 11 位有效数 + 3 位保护区，小数只剩 sticky
  // ---------------------------------------------------------------------------
  logic        shift_out_of_range;
  logic [11:0] add_b;                     // 加法器 B：对齐后的小数（EOP 时为反码）
  assign shift_out_of_range = abs_exp_diff > 5'd14;
  assign add_b = shift_out_of_range ? {12{eop}} : rshift_smaller[25:14];

  // ---------------------------------------------------------------------------
  // §3 guard / round（当拍定值）与 sticky 原料
  // ---------------------------------------------------------------------------
  logic guard_bit, round_bit;
  assign guard_bit = ~shift_out_of_range & (eop ? ~rshift_smaller[13] : rshift_smaller[13]);
  assign round_bit = ~shift_out_of_range & (eop ? ~rshift_smaller[12] : rshift_smaller[12]);

  // ---------------------------------------------------------------------------
  // §4 两个加法器（各自跨两拍）：FS0 = A + B，FS1 = A + B + 2
  // ---------------------------------------------------------------------------
  logic [11:0] fs0, fs1;
  FarPathAdderF16Pipeline U_FS0 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (add_a),
    .io_B      (add_b),
    .io_result (fs0)
  );
  FarPathAdderF16Pipeline U_FS1 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (12'(add_a + 12'd2)),
    .io_B      (add_b),
    .io_result (fs1)
  );

  // ---------------------------------------------------------------------------
  // §5 指数候选与第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic [4:0] exp_greater, exp_base, exp_base_plus1;
  assign exp_greater    = exp_b_greater ? exp_b : exp_a;
  assign exp_base       = eop ? 5'(exp_greater - 5'd1) : exp_greater;
  assign exp_base_plus1 = 5'(exp_base + 5'd1);

  logic        eop_q;                     // 给 LGS 补码与舍入判定
  logic        rne_q, rtz_q, rdn_q, rup_q, rmm_q;
  logic        guard_q, round_q;
  logic        shift_out_of_range_q;      // sticky 选源：移位溢出
  logic        smaller_sig_nz_q;          //   移位溢出时 sticky = 小数非零
  logic        eop_for_sticky_q;          //   与 eop_q 同源的第二份打拍（golden 原样）
  logic [11:0] low_bits_inv_q;            //   相减：右移结果低 12 位的反码
  logic [11:0] low_bits_q;                //   相加：右移结果低 12 位
  logic        sign_q;
  logic        add_a_lsb_q;               // 溢出情形的减法 grs 用：A 的 LSB
  logic        add_b_lsb_inv_q;           //   与 B 的 LSB 取反
  logic        exp_base_is_zero_q;
  logic [4:0]  exp_base_plus1_q, exp_base_q;
  logic        exp_plus1_all_one_q;       // EA+1 已是全 1：再进位就上溢
  always_ff @(posedge clock) begin
    if (fire) begin
      eop_q                <= eop;
      rne_q                <= round_mode == 3'd0;
      rtz_q                <= round_mode == 3'd1;
      rdn_q                <= round_mode == 3'd2;
      rup_q                <= round_mode == 3'd3;
      rmm_q                <= round_mode == 3'd4;
      guard_q              <= guard_bit;
      round_q              <= round_bit;
      shift_out_of_range_q <= shift_out_of_range;
      smaller_sig_nz_q     <= |smaller_sig;
      eop_for_sticky_q     <= eop;
      low_bits_inv_q       <= ~rshift_smaller[11:0];
      low_bits_q           <= rshift_smaller[11:0];
      sign_q               <= exp_b_greater ? sign_b_eff : sign_a;
      add_a_lsb_q          <= add_a[0];
      add_b_lsb_inv_q      <= ~add_b[0];
      exp_base_is_zero_q   <= exp_base == 5'd0;
      exp_base_plus1_q     <= exp_base_plus1;
      exp_base_q           <= exp_base;
      exp_plus1_all_one_q  <= &exp_base_plus1;
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍：sticky 归约，正常 / 溢出两种情形的 LGS 与舍入判定
  // ---------------------------------------------------------------------------
  logic sticky_bit, round_sticky;
  assign sticky_bit   = shift_out_of_range_q ? smaller_sig_nz_q
                      : (eop_for_sticky_q ? (|low_bits_inv_q) : (|low_bits_q));
  assign round_sticky = round_q | sticky_bit;

  logic sum_overflow;                     // FS0 最高位为 1：和多出一位，要右移 1 位
  assign sum_overflow = fs0[11];

  // 正常情形 {LSB, G, R|S}：相减时 {G, R|S} 是反码，+1 补成真值（2 位回绕）
  logic [1:0] gs_normal;
  logic [2:0] lgs_normal;
  assign gs_normal  = eop_q ? 2'(~{guard_q, round_sticky} + 2'd1) : {guard_q, round_sticky};
  assign lgs_normal = {fs0[0], gs_normal};

  // 溢出情形（和要右移 1 位）：原 LSB 下移成 G，原 G 并入 sticky
  logic [2:0] grs_overflow, lgs_overflow;
  assign grs_overflow = eop_q ? 3'({add_a_lsb_q, 2'b00} - {add_b_lsb_inv_q, guard_q, round_sticky})
                              : {fs0[0], guard_q, round_sticky};
  assign lgs_overflow = {fs0[1], grs_overflow[2], grs_overflow[1] | grs_overflow[0]};

  // 舍入进位判定（同一张表用两次）：EOP 且 G/S 全 0 时也算"进位"——相减的反码 +1 落在 LSB 上
  function automatic logic round_up(input logic       eop_r,
                                    input logic [2:0] lgs,
                                    input logic       sign,
                                    input logic       rne, rdn, rup, rmm);
    round_up = (eop_r & ~lgs[1] & ~lgs[0])
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
  assign normal_round_carries_out = fs1[11] & fs0[0] & round_up_normal;

  // ---------------------------------------------------------------------------
  // §7 尾数：四种情形 Mux1H
  // ---------------------------------------------------------------------------
  logic sel_normal_keep, sel_normal_up, sel_overflow_keep, sel_overflow_up;
  assign sel_normal_keep   = ~sum_overflow & ((~fs0[0] & round_up_normal) | ~round_up_normal);
  assign sel_normal_up     = ~sum_overflow & fs0[0] & round_up_normal;
  assign sel_overflow_keep =  sum_overflow & ((~fs0[1] & round_up_overflow) | ~round_up_overflow);
  assign sel_overflow_up   =  sum_overflow & fs0[1] & round_up_overflow;

  // "keep"：LSB 为 0 时进位只需把 LSB 置 1（异或）；"up"：LSB 为 1，取 FS1
  logic [9:0] frac_result;
  assign frac_result = ({10{sel_normal_keep}}   & {fs0[9:1], fs0[0] ^ round_up_normal})
                     | ({10{sel_normal_up}}     & {fs1[9:1], 1'b0})
                     | ({10{sel_overflow_keep}} & {fs0[10:2], fs0[1] ^ round_up_overflow})
                     | ({10{sel_overflow_up}}   & fs1[10:1]);

  // ---------------------------------------------------------------------------
  // §8 指数、上溢与输出
  // ---------------------------------------------------------------------------
  logic       exp_takes_plus1;            // 和溢出 / 舍入进位溢出 / 非规格数相加进位成规格数
  logic [4:0] exp_result;
  logic       overflow, inexact;
  assign exp_takes_plus1 = sum_overflow | normal_round_carries_out
                         | (exp_base_is_zero_q & fs0[10]);
  assign exp_result      = exp_takes_plus1 ? exp_base_plus1_q : exp_base_q;
  assign overflow        = exp_plus1_all_one_q & (sum_overflow | normal_round_carries_out);
  assign inexact         = (sum_overflow ? (|lgs_overflow[1:0]) : (|lgs_normal[1:0])) | overflow;

  // 上溢：朝零 / 朝反方向舍入给最大有限数，否则给 Inf
  logic [14:0] overflow_magnitude;
  assign overflow_magnitude = (rtz_q | (rdn_q & ~sign_q) | (rup_q & sign_q)) ? 15'h7BFF : 15'h7C00;
  assign fp_c   = {sign_q, overflow ? overflow_magnitude : {exp_result, frac_result}};
  assign fflags = {2'b00, overflow, 1'b0, inexact};   // {NV, DZ, OF, UF, NX}
endmodule

module FarPathF16Pipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [15:0] io_fp_a,
  input  logic [15:0] io_fp_b,
  output logic [15:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  output logic [4:0]  io_absEaSubEb,
  output logic        io_isEfp_bGreater
);
  xs_FarPathF16Pipeline_core u_core (
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
