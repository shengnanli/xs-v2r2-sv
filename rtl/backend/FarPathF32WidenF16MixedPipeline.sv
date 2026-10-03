// =============================================================================
// FarPathF32WidenF16MixedPipeline —— f32 / f16 混合浮点加法的 far path（两拍流水）
//
// 在哪一层：FloatAdderF32WidenF16MixedPipeline 的 U_far_path（hasMinMaxCompare=true 变体，所以多一个
//   isEfp_bGreater 输出给 min/max/比较用）。设计源：yunsuan/vector/VectorFloatAdder.scala
//   class FarPathF32WidenF16MixedPipeline。f16 操作数由父级铺成 f32 布局（尾数低 13 位为 0），
//   本件只靠 res_is_f32 选"最低有效位在第 0 位还是第 13 位"。
// far path 管的情形：有效相加（EOP=0），或有效相减但两指数差 >= 2——此时结果最多左移 1 位，
//   不需要前导零计数；父级按指数差在 far / close 两条路径之间选。
//
// 第 0 拍（组合 + 打拍）：
//   §1 对阶：非规格数的指数当 1 用；两个方向的指数差各算一份（Adder_2 ×2），大的那个操作数不动，
//      小的那个尾数右移指数差位（FarShiftRightWithMuxInvFirst_2 ×2，EOP 时先取反再移、高位补 1，
//      即直接得到被减数的反码对齐值）。
//   §2 移位溢出：指数差超过 27（f32）/ 14（f16）时小数整个掉进 sticky，B 直接取全 EOP。
//   §3 guard / round / sticky：从右移结果里按格式取保护位、舍入位、粘滞位（EOP 时这三者是反码，
//      取反回来；减法的 +1 补码进位体现在 lgs_normal 的 "~{g,rs}+1" 与 grs_overflow 的减法里）。
//   §4 两个加法器同时起跑：FS0 = A + B（不舍入的和），FS1 = A + B + 2ulp（向上舍入备用，
//      加在第 1 位是因为 A/B 都比结果多一位、溢出时还要再右移一位）。两个加法器自身跨两拍。
//   §5 指数候选 EA（EOP 时先减 1，为"相减后左移 1 位"预留）与 EA+1 都打拍，第 1 拍二选一。
// 第 1 拍：
//   §6 按 FS0 最高位判"和溢出（需右移 1 位）"还是"正常"，两种情形各有自己的 LGS 三元组与舍入判定；
//   §7 舍入：四种（正常/溢出 × 不进位/进位）用 Mux1H 选尾数；进位情形直接取 FS1 的对应位。
//   §8 上溢：EA+1 全 1 且结果确实进了一位 → OF，按舍入方向给最大有限数或 Inf；NX = 有效 LGS 非零或 OF。
// 怪癖（照 golden）：
//   - "EOP 打拍"这件事 Scala 写了两次 RegEnable(EOP)（正常/溢出两个舍入判定各一份），本件照抄两份寄存器。
//   - f16 时正常情形尾数第 0 位写成 "FS0[13] ^ 进位"（不是 FS0[0]），与第 13 位重复；高 10 位之外的
//     低位在 f16 下本来就是填充位，golden 原样保留。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：Adder_2 ×2、FarShiftRightWithMuxInvFirst_2 ×2、
//   FarPathF32WidenF16MixedAdderPipeline ×2（U_FS0 / U_FS1）。
// golden 对照：G1-canonical/golden-rtl/FarPathF32WidenF16MixedPipeline.sv
// =============================================================================
module xs_FarPathF32WidenF16MixedPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [31:0] fp_a,
  input  logic [31:0] fp_b,
  input  logic        is_sub,
  input  logic [2:0]  round_mode,
  input  logic        res_is_f32,
  output logic [31:0] fp_c,
  output logic [4:0]  fflags,
  output logic [7:0]  abs_exp_diff,     // |Ea - Eb|（非规格数指数按 1 算），父级用来分 far/close
  output logic        exp_b_greater     // Eb > Ea（原始指数比较），父级 min/max/比较用
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a, sign_b_eff, eop;
  logic [7:0]  exp_a, exp_b;
  logic        exp_a_nz, exp_b_nz;
  logic [23:0] sig_a, sig_b;             // 带隐含位的 24 位有效数（非规格数隐含位为 0）
  assign sign_a     = fp_a[31];
  assign sign_b_eff = fp_b[31] ^ is_sub; // 减法 = 加上符号取反的 b
  assign eop        = sign_a ^ sign_b_eff;   // effective operation：1 = 有效相减
  assign exp_a      = fp_a[30:23];
  assign exp_b      = fp_b[30:23];
  assign exp_a_nz   = |exp_a;
  assign exp_b_nz   = |exp_b;
  assign sig_a      = {exp_a_nz, fp_a[22:0]};
  assign sig_b      = {exp_b_nz, fp_b[22:0]};

  // ---------------------------------------------------------------------------
  // §1 对阶
  // ---------------------------------------------------------------------------
  logic [7:0] exp_a_eff, exp_b_eff;      // 非规格数（指数 0）当指数 1 参与做差
  logic [7:0] diff_a_minus_b, diff_b_minus_a;
  assign exp_a_eff = {exp_a[7:1], exp_a[0] | ~exp_a_nz};
  assign exp_b_eff = {exp_b[7:1], exp_b[0] | ~exp_b_nz};

  Adder_2 U_Efp_aSubEfp_b (
    .io_a (exp_a_eff),
    .io_b (exp_b_eff),
    .io_c (diff_a_minus_b)
  );
  Adder_2 U_Efp_bSubEfp_a (
    .io_a (exp_b_eff),
    .io_b (exp_a_eff),
    .io_c (diff_b_minus_a)
  );

  assign exp_b_greater = exp_b > exp_a;
  assign abs_exp_diff  = exp_b_greater ? diff_b_minus_a : diff_a_minus_b;

  logic [23:0] greater_sig, smaller_sig;
  logic [24:0] add_a;                    // 加法器的 A：大数有效数，EOP 时左移一位（给相减后的左规格化留位）
  assign greater_sig = exp_b_greater ? sig_b : sig_a;
  assign smaller_sig = exp_b_greater ? sig_a : sig_b;
  assign add_a       = eop ? {greater_sig, 1'b0} : {1'b0, greater_sig};

  // 两个操作数都准备一份"若它是小数时"的右移源（52 位 = 1 + 24 + 27 位低位延伸）：
  //   有效相加：{0, sig, 27'b0}；有效相减：{~sig, 28 个 1}（反码，右移时高位补 1）。
  logic [51:0] rshift_src_a, rshift_src_b;
  logic [51:0] rshift_a, rshift_b, rshift_smaller;
  assign rshift_src_a = eop ? {~sig_a, 28'hFFF_FFFF} : {1'b0, sig_a, 27'h0};
  assign rshift_src_b = eop ? {~sig_b, 28'hFFF_FFFF} : {1'b0, sig_b, 27'h0};

  FarShiftRightWithMuxInvFirst_2 U_far_rshift_1 (   // b 是小数：右移 Ea-Eb
    .io_src        (rshift_src_b),
    .io_shiftValue (diff_a_minus_b[4:0]),
    .io_result     (rshift_b),
    .io_EOP        (eop)
  );
  FarShiftRightWithMuxInvFirst_2 U_far_rshift_2 (   // a 是小数：右移 Eb-Ea
    .io_src        (rshift_src_a),
    .io_shiftValue (diff_b_minus_a[4:0]),
    .io_result     (rshift_a),
    .io_EOP        (eop)
  );
  assign rshift_smaller = exp_b_greater ? rshift_a : rshift_b;

  // ---------------------------------------------------------------------------
  // §2 移位溢出：右移量超过有效数 + 3 位保护区，小数只剩 sticky
  // ---------------------------------------------------------------------------
  logic        shift_out_of_range;
  logic [24:0] add_b;                    // 加法器的 B：对齐后的小数（EOP 时为反码）
  assign shift_out_of_range = res_is_f32 ? (abs_exp_diff > 8'd27) : (abs_exp_diff > 8'd14);
  assign add_b = shift_out_of_range ? {25{eop}} : rshift_smaller[51:27];

  // ---------------------------------------------------------------------------
  // §3 guard / round / sticky（f32 的结果 LSB 在 rshift[27]，f16 的在 rshift[40]）
  // ---------------------------------------------------------------------------
  logic guard_raw, round_raw, sticky_raw_add, sticky_raw_sub;
  assign guard_raw      = res_is_f32 ? rshift_smaller[26] : rshift_smaller[39];
  assign round_raw      = res_is_f32 ? rshift_smaller[25] : rshift_smaller[38];
  assign sticky_raw_add = res_is_f32 ? (|rshift_smaller[24:0]) : (|rshift_smaller[37:0]);
  assign sticky_raw_sub = res_is_f32 ? (rshift_smaller[24:0] != 25'h1FF_FFFF)
                                     : (rshift_smaller[37:0] != 38'h3F_FFFF_FFFF);

  logic guard_bit, round_bit, sticky_bit, round_sticky;
  assign guard_bit    = ~shift_out_of_range & (eop ? ~guard_raw : guard_raw);
  assign round_bit    = ~shift_out_of_range & (eop ? ~round_raw : round_raw);
  assign sticky_bit   = shift_out_of_range ? (|smaller_sig) : (eop ? sticky_raw_sub : sticky_raw_add);
  assign round_sticky = round_bit | sticky_bit;

  // 正常情形的低两位 {G, R|S}：相减时是反码，+1 补成真值（2 位回绕）
  logic [1:0] gs_normal;
  assign gs_normal = eop ? 2'(~{guard_bit, round_sticky} + 2'd1) : {guard_bit, round_sticky};

  // 溢出情形（和要右移 1 位）的 {L, G, R|S}：原 LSB 下移成 G，原 G 并入 sticky
  logic       add_a_lsb, add_b_lsb;
  logic [2:0] grs_overflow;
  assign add_a_lsb    = res_is_f32 ? add_a[0] : add_a[13];
  assign add_b_lsb    = res_is_f32 ? add_b[0] : add_b[13];
  assign grs_overflow = eop ? 3'({add_a_lsb, 2'b00} - {~add_b_lsb, guard_bit, round_sticky})
                            : {add_a_lsb ^ add_b_lsb, guard_bit, round_sticky};

  // ---------------------------------------------------------------------------
  // §4 两个加法器（各自跨两拍）：FS0 = A + B，FS1 = A + B + 2ulp
  // ---------------------------------------------------------------------------
  logic [24:0] fs0, fs1;
  FarPathF32WidenF16MixedAdderPipeline U_FS0 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (add_a),
    .io_B      (add_b),
    .io_result (fs0)
  );
  FarPathF32WidenF16MixedAdderPipeline U_FS1 (
    .clock     (clock),
    .io_fire   (fire),
    .io_A      (25'(add_a + (res_is_f32 ? 25'h2 : 25'h4000))),
    .io_B      (add_b),
    .io_result (fs1)
  );

  // ---------------------------------------------------------------------------
  // §5 指数候选与第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic [7:0] exp_greater, exp_base, exp_base_plus1;
  assign exp_greater    = exp_b_greater ? exp_b : exp_a;
  assign exp_base       = eop ? 8'(exp_greater - 8'd1) : exp_greater;
  assign exp_base_plus1 = 8'(exp_base + 8'd1);

  logic       res_is_f32_q;
  logic       rne_q, rtz_q, rdn_q, rup_q, rmm_q;
  logic [1:0] gs_normal_q;
  logic       sign_q;
  logic       eop_for_normal_q, eop_for_overflow_q;   // 同一个 EOP 的两份打拍（golden 原样）
  logic [2:0] grs_overflow_q;
  logic       exp_base_is_zero_q;
  logic [7:0] exp_base_plus1_q, exp_base_q;
  logic       exp_plus1_all_one_q;                    // EA+1 是否已是全 1（f16 只看低 5 位）
  always_ff @(posedge clock) begin
    if (fire) begin
      res_is_f32_q        <= res_is_f32;
      rne_q               <= round_mode == 3'd0;
      rtz_q               <= round_mode == 3'd1;
      rdn_q               <= round_mode == 3'd2;
      rup_q               <= round_mode == 3'd3;
      rmm_q               <= round_mode == 3'd4;
      gs_normal_q         <= gs_normal;
      sign_q              <= exp_b_greater ? sign_b_eff : sign_a;
      eop_for_normal_q    <= eop;
      grs_overflow_q      <= grs_overflow;
      eop_for_overflow_q  <= eop;
      exp_base_is_zero_q  <= exp_base == 8'h0;
      exp_base_plus1_q    <= exp_base_plus1;
      exp_base_q          <= exp_base;
      exp_plus1_all_one_q <= res_is_f32 ? (&exp_base_plus1) : (&exp_base_plus1[4:0]);
    end
  end

  // ---------------------------------------------------------------------------
  // §6 第 1 拍：正常 / 溢出两种情形的 LGS 与舍入判定
  // ---------------------------------------------------------------------------
  logic sum_overflow;                    // FS0 最高位为 1：和多出一位，要右移 1 位
  logic fs0_lsb, fs0_lsb_up1;            // 结果 LSB（正常 / 溢出情形）
  assign sum_overflow = fs0[24];
  assign fs0_lsb      = res_is_f32_q ? fs0[0] : fs0[13];
  assign fs0_lsb_up1  = res_is_f32_q ? fs0[1] : fs0[14];

  logic [2:0] lgs_normal, lgs_overflow;  // {LSB, guard, round|sticky}
  assign lgs_normal   = {fs0_lsb, gs_normal_q};
  assign lgs_overflow = {fs0_lsb_up1, grs_overflow_q[2], grs_overflow_q[1] | grs_overflow_q[0]};

  // 舍入进位判定（同一张表用两次）：EOP 且 G/S 全 0 时也算"进位"——相减的反码 +1 落在 LSB 上
  function automatic logic round_up(input logic       eop_q,
                                    input logic [2:0] lgs,
                                    input logic       sign,
                                    input logic       rne, rdn, rup, rmm);
    round_up = (eop_q & ~lgs[1] & ~lgs[0])
             | (rne & lgs[1] & (lgs[2] | lgs[0]))
             | (rdn & sign & (lgs[1] | lgs[0]))
             | (rup & ~sign & (lgs[1] | lgs[0]))
             | (rmm & lgs[1]);
  endfunction

  logic round_up_normal, round_up_overflow;
  assign round_up_normal   = round_up(eop_for_normal_q, lgs_normal, sign_q, rne_q, rdn_q, rup_q, rmm_q);
  assign round_up_overflow = round_up(eop_for_overflow_q, lgs_overflow, sign_q, rne_q, rdn_q, rup_q, rmm_q);

  // 正常情形下舍入进位又让和溢出：FS1 最高位为 1
  logic normal_round_carries_out;
  assign normal_round_carries_out = fs1[24] & fs0_lsb & round_up_normal;

  // ---------------------------------------------------------------------------
  // §7 尾数：四种情形 Mux1H
  // ---------------------------------------------------------------------------
  logic sel_normal_keep, sel_normal_up, sel_overflow_keep, sel_overflow_up;
  assign sel_normal_keep   = ~sum_overflow & ((~fs0_lsb & round_up_normal) | ~round_up_normal);
  assign sel_normal_up     = ~sum_overflow & fs0_lsb & round_up_normal;
  assign sel_overflow_keep =  sum_overflow & ((~fs0_lsb_up1 & round_up_overflow) | ~round_up_overflow);
  assign sel_overflow_up   =  sum_overflow & fs0_lsb_up1 & round_up_overflow;

  // "keep"：LSB 为 0 时进位只需把 LSB 置 1（异或），不必等进位链；"up"：LSB 为 1，取 FS1
  logic [22:0] frac_normal_keep, frac_normal_up, frac_overflow_keep, frac_overflow_up;
  assign frac_normal_keep   = {fs0[22:14], (~res_is_f32_q & round_up_normal) ^ fs0[13],
                               fs0[12:1], fs0_lsb ^ round_up_normal};
  assign frac_normal_up     = {fs1[22:14], res_is_f32_q & fs1[13], fs1[12:1], 1'b0};
  assign frac_overflow_keep = {fs0[23:15], (~res_is_f32_q & round_up_overflow) ^ fs0[14],
                               fs0[13:2], fs0_lsb_up1 ^ round_up_overflow};
  assign frac_overflow_up   = fs1[23:1];

  logic [22:0] frac_result;
  assign frac_result = ({23{sel_normal_keep}}   & frac_normal_keep)
                     | ({23{sel_normal_up}}     & frac_normal_up)
                     | ({23{sel_overflow_keep}} & frac_overflow_keep)
                     | ({23{sel_overflow_up}}   & frac_overflow_up);

  // ---------------------------------------------------------------------------
  // §8 指数、上溢与输出
  // ---------------------------------------------------------------------------
  logic       exp_takes_plus1;          // 和溢出 / 舍入进位溢出 / 非规格数相加进位成规格数
  logic [7:0] exp_result;
  logic       overflow, inexact;
  assign exp_takes_plus1 = sum_overflow | normal_round_carries_out
                         | (exp_base_is_zero_q & fs0[23]);
  assign exp_result      = exp_takes_plus1 ? exp_base_plus1_q : exp_base_q;
  assign overflow        = exp_plus1_all_one_q & (sum_overflow | normal_round_carries_out);
  assign inexact         = (sum_overflow ? (|lgs_overflow[1:0]) : (|lgs_normal[1:0])) | overflow;

  // 上溢：朝零 / 朝反方向舍入给最大有限数，否则给 Inf
  logic [30:0] overflow_magnitude;
  assign overflow_magnitude = (rtz_q | (rdn_q & ~sign_q) | (rup_q & sign_q)) ? 31'h7F7F_FFFF
                                                                             : 31'h7F80_0000;
  assign fp_c   = {sign_q, overflow ? overflow_magnitude : {exp_result, frac_result}};
  assign fflags = {2'b00, overflow, 1'b0, inexact};   // {NV, DZ, OF, UF, NX}
endmodule

module FarPathF32WidenF16MixedPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [31:0] io_fp_a,
  input  logic [31:0] io_fp_b,
  output logic [31:0] io_fp_c,
  input  logic        io_is_sub,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  output logic [7:0]  io_absEaSubEb,
  input  logic        io_res_is_f32,
  output logic        io_isEfp_bGreater
);
  xs_FarPathF32WidenF16MixedPipeline_core u_core (
    .clock         (clock),
    .fire          (io_fire),
    .fp_a          (io_fp_a),
    .fp_b          (io_fp_b),
    .is_sub        (io_is_sub),
    .round_mode    (io_round_mode),
    .res_is_f32    (io_res_is_f32),
    .fp_c          (io_fp_c),
    .fflags        (io_fflags),
    .abs_exp_diff  (io_absEaSubEb),
    .exp_b_greater (io_isEfp_bGreater)
  );
endmodule
