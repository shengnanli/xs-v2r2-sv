// =============================================================================
// ClosePathF32WidenF16MixedPipeline —— f32 / f16 混合浮点加法的 close path（两拍流水）
//
// 在哪一层：FloatAdderF32WidenF16MixedPipeline 的 U_close_path（hasMinMaxCompare=true 变体，CS1
//   减法器的结果引出给父级做尾数大小比较）。设计源：yunsuan/vector/VectorFloatAdder.scala
//   class ClosePathF32WidenF16MixedPipeline。f16 操作数由父级铺成 f32 布局，LSB 在第 13 位。
// close path 管的情形：有效相减且两指数差 <= 1。此时对阶至多右移 1 位（只产生一个 guard 位，
//   没有 round/sticky），但相减可能大量抵消，需要前导零计数 + 左移规格化。
//
// 第 0 拍：
//   §1 指数关系：只看指数低两位就能在"差 <= 1"前提下判出 b 大还是相等（Efp_b_is_greater /
//      exp_is_equal）；指数 0 与 1 视为相等（非规格数的有效指数是 1）。
//   §2 四个候选差同时算（ClosePathF32WidenF16MixedPipelineAdder / _2）：
//        CS0 = a - b、CS1 = b - a（指数相等，25 位带借位）；
//        CS2 = 2a - b、CS3 = 2b - a（指数差 1，大数左移一位代替小数右移一位，guard 位落在 bit0）。
//      再选一个：指数相等按 CS0 借位选 CS0 / CS1；差 1 时一般选 CS2 / CS3，但若"结果最高位为 1
//      且 guard 位要进位"——即结果不需要左移、舍入还会进上去——改走 CS4（第 1 拍的直接相减路径）。
//   §3 指数下限掩码：大数指数为 e 时左移量最多 e-1（再多就变非规格数），把这个位置在 25 位候选上
//      标成 1 再一起做前导零计数（LZD），左移量就自动被截在下限。
//   §4 打拍：选中的候选、LZD、EA、CS4 的两个操作数、符号、NX、若干选择位。
// 第 1 拍：
//   §5 左移规格化（CloseShiftLeftWithMux_1）；CS4 = 大数有效数 - 小数右移一位（截到格式 LSB）。
//   §6 指数 = EA - 左移量；"左移后最高位为 1"不成立（全部抵消 / 撞到下限）时减掉整个 EA（得 0）。
// 怪癖（照 golden）：
//   - sel_CS4 打了两份寄存器（一份选尾数、一份选指数减数），LZD 也打了两份（一份 5 位给移位器、
//     一份扩成 8 位当指数减数）；本件照抄，不合并。
//   - 符号的 Mux1H 里第一项写成 "sel_CS0 & (CS0 借位 | CS1 借位)"，而 sel_CS0 已蕴含 CS0 无借位，
//     实际只看 CS1 借位；照抄。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：ClosePathF32WidenF16MixedPipelineAdder ×3（U_CS0/U_CS1/U_CS4）、
//   ClosePathF32WidenF16MixedPipelineAdder_2 ×2（U_CS2/U_CS3）、CloseShiftLeftWithMux_1（U_Lshift）。
// golden 对照：G1-canonical/golden-rtl/ClosePathF32WidenF16MixedPipeline.sv
// =============================================================================
module xs_ClosePathF32WidenF16MixedPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [31:0] fp_a,
  input  logic [31:0] fp_b,
  input  logic [2:0]  round_mode,
  input  logic        res_is_f32,
  output logic [31:0] fp_c,
  output logic [4:0]  fflags,
  output logic [24:0] cs1_b_minus_a    // CS1 = {0,sig_b} - {0,sig_a}，父级比较尾数大小用
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a;
  logic [7:0]  exp_a, exp_b;
  logic [22:0] mant_a, mant_b;
  logic        exp_a_nz, exp_b_nz;
  logic [23:0] sig_a, sig_b;
  assign sign_a   = fp_a[31];
  assign exp_a    = fp_a[30:23];
  assign exp_b    = fp_b[30:23];
  assign mant_a   = fp_a[22:0];
  assign mant_b   = fp_b[22:0];
  assign exp_a_nz = |exp_a;
  assign exp_b_nz = |exp_b;
  assign sig_a    = {exp_a_nz, mant_a};
  assign sig_b    = {exp_b_nz, mant_b};

  logic rne, rdn, rup, rmm;
  assign rne = round_mode == 3'd0;
  assign rdn = round_mode == 3'd2;
  assign rup = round_mode == 3'd3;
  assign rmm = round_mode == 3'd4;

  // ---------------------------------------------------------------------------
  // §1 指数关系（前提：|Ea - Eb| <= 1）
  // ---------------------------------------------------------------------------
  logic       exp_b_greater, exp_equal;
  logic [7:0] exp_big;                 // EA：大数的指数
  // 差 1 时两个 LSB 必不同；此时 b 大 <=> (a1 ^ b1) == a0（a 的 LSB 为 1 时 b 不进位到 bit1）
  assign exp_b_greater = (exp_b[0] ^ exp_a[0]) & (exp_a[1] ^ exp_b[1] ^ ~exp_a[0]);
  // LSB 相同 = 相等；或一个是 0 一个非 0（只可能是 0 对 1：有效指数都是 1）
  assign exp_equal     = ~(exp_a[0] ^ exp_b[0]) | (exp_a_nz ^ exp_b_nz);
  assign exp_big       = exp_b_greater ? exp_b : exp_a;

  // ---------------------------------------------------------------------------
  // §2 四个候选差
  // ---------------------------------------------------------------------------
  logic [24:0] cs0, cs1, cs2, cs3;
  ClosePathF32WidenF16MixedPipelineAdder U_CS0 (     // a - b
    .io_adder_op0 (sig_a),
    .io_adder_op1 (sig_b),
    .io_result    (cs0)
  );
  ClosePathF32WidenF16MixedPipelineAdder U_CS1 (     // b - a
    .io_adder_op0 (sig_b),
    .io_adder_op1 (sig_a),
    .io_result    (cs1)
  );
  ClosePathF32WidenF16MixedPipelineAdder_2 U_CS2 (   // 2a - b（a 大一个指数时隐含位必为 1）
    .io_adder_op0 ({1'b1, mant_a}),
    .io_adder_op1 ({1'b1, mant_b}),
    .io_result    (cs2)
  );
  ClosePathF32WidenF16MixedPipelineAdder_2 U_CS3 (   // 2b - a
    .io_adder_op0 ({1'b1, mant_b}),
    .io_adder_op1 ({1'b1, mant_a}),
    .io_result    (cs3)
  );
  assign cs1_b_minus_a = cs1;

  // CS2/CS3 以大数的半个 ulp 为单位：bit0（f16 为 bit13）是 guard 位置，bit1（f16 为 bit14）是
  // 不左移时结果的 LSB
  logic cs2_lsb0, cs2_lsb1, cs3_lsb0, cs3_lsb1;
  assign cs2_lsb0 = res_is_f32 ? cs2[0] : cs2[13];
  assign cs2_lsb1 = res_is_f32 ? cs2[1] : cs2[14];
  assign cs3_lsb0 = res_is_f32 ? cs3[0] : cs3[13];
  assign cs3_lsb1 = res_is_f32 ? cs3[1] : cs3[14];

  // 小数被右移掉的那一位（guard），按格式取
  logic guard_of_b, guard_of_a;
  assign guard_of_b = res_is_f32 ? fp_b[0] : fp_b[13];
  assign guard_of_a = res_is_f32 ? fp_a[0] : fp_a[13];

  // 差 1 时"若不左移、guard 会不会让结果进位"：结果符号 a 大为 sign_a，b 大为 ~sign_a
  logic cs2_round_up, cs3_round_up;
  assign cs2_round_up = guard_of_b & ((rup & ~sign_a) | (rdn & sign_a) | (rne & cs2_lsb1 & cs2_lsb0) | rmm);
  assign cs3_round_up = guard_of_a & ((rup & sign_a) | (rdn & ~sign_a) | (rne & cs3_lsb1 & cs3_lsb0) | rmm);

  logic sel_cs0, sel_cs1, sel_cs2, sel_cs3, sel_cs4;
  assign sel_cs0 = exp_equal & ~cs0[24];
  assign sel_cs1 = exp_equal &  cs0[24];
  assign sel_cs2 = ~exp_equal & ~exp_b_greater & (~cs2[24] | ~cs2_lsb0 | ~cs2_round_up);
  assign sel_cs3 = ~exp_equal &  exp_b_greater & (~cs3[24] | ~cs3_lsb0 | ~cs3_round_up);
  assign sel_cs4 = ~exp_equal & ((~exp_b_greater & cs2[24] & cs2_lsb0 & cs2_round_up)
                               | ( exp_b_greater & cs3[24] & cs3_lsb0 & cs3_round_up));

  logic [24:0] cs_selected;            // CS0/CS1 补一位 0 对齐到 CS2/CS3 的 25 位格式
  assign cs_selected = ({25{sel_cs0}} & {cs0[23:0], 1'b0})
                     | ({25{sel_cs1}} & {cs1[23:0], 1'b0})
                     | ({25{sel_cs2}} & cs2)
                     | ({25{sel_cs3}} & cs3);

  // ---------------------------------------------------------------------------
  // §3 指数下限掩码 + 前导零计数
  // ---------------------------------------------------------------------------
  // exp_floor_mask(e)[23]   = (e <= 1)：不许左移
  // exp_floor_mask(e)[k]    = (e == 24 - k), k = 0..22：最多左移 e-1 位，在那一位标 1
  function automatic logic [23:0] exp_floor_mask(input logic [7:0] e);
    exp_floor_mask[23] = (e == 8'd0) | (e == 8'd1);
    for (int k = 0; k < 23; k++)
      exp_floor_mask[k] = (e == 8'(24 - k));
  endfunction

  logic [23:0] floor_mask_a, floor_mask_b;
  logic [24:0] floor_mask;
  assign floor_mask_a = exp_floor_mask(exp_a);
  assign floor_mask_b = exp_floor_mask(exp_b);
  assign floor_mask = ({25{sel_cs0}} & {floor_mask_a, 1'b1})
                    | ({25{sel_cs1}} & {floor_mask_b, 1'b1})
                    | ({25{sel_cs2}} & {floor_mask_a, exp_a == 8'd25})
                    | ({25{sel_cs3}} & {floor_mask_b, exp_b == 8'd25});

  logic [24:0] lzd_input;
  logic [4:0]  lzd;                    // 前导零个数；全 0 时为 25
  assign lzd_input = cs_selected | floor_mask;
  always_comb begin
    lzd = 5'd25;
    for (int i = 0; i < 25; i++)
      if (lzd_input[i]) lzd = 5'(24 - i);    // 从低往高扫，最后命中的是最高的 1
  end

  // ---------------------------------------------------------------------------
  // §4 第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic        guard_bit;              // 小数被右移掉的 guard 位（小数是非规格数时为 0）
  logic        inexact;
  logic        result_sign;
  assign guard_bit = exp_b_greater ? (exp_a_nz & guard_of_a) : (exp_b_nz & guard_of_b);
  assign inexact   = ((sel_cs2 & cs2[24] & cs2_lsb0 & ~cs2_round_up)
                    | (sel_cs3 & cs3[24] & cs3_lsb0 & ~cs3_round_up)
                    | sel_cs4) & guard_bit;
  assign result_sign = (sel_cs0 & exp_equal & (cs0[24] | cs1[24]) & sign_a)   // a > b
                     | (sel_cs0 & exp_equal & ~cs0[24] & ~cs1[24] & rdn)      // 恰好抵消：RDN 给 -0
                     | (sel_cs1 & ~sign_a)
                     | (sel_cs2 & sign_a)
                     | (sel_cs3 & ~sign_a)
                     | (sel_cs4 & (exp_b_greater ^ sign_a));

  // CS4 的操作数：大数有效数，与小数右移一位（f16 时截掉 LSB 以下的填充位）
  logic [22:0] small_shr1_a, small_shr1_b;
  assign small_shr1_a = {exp_a_nz, res_is_f32 ? mant_a[22:1] : {mant_a[22:14], 13'h0}};
  assign small_shr1_b = {exp_b_nz, res_is_f32 ? mant_b[22:1] : {mant_b[22:14], 13'h0}};

  logic [7:0]  exp_big_q;
  logic [23:0] cs4_op0_q, cs4_op1_q;
  logic [4:0]  lzd_q;                  // 给移位器
  logic [24:0] cs_selected_q;
  logic        inexact_q;
  logic        frac_from_cs4_q;        // sel_CS4（选尾数用）
  logic        cs_selected_nz_q;
  logic        floor_hit_q;            // 选中的候选在下限掩码位置上为 1
  logic        exp_from_cs4_q;         // sel_CS4（选指数减数用，与上面同源）
  logic [7:0]  exp_sub_lzd_q;          // LZD 扩成指数宽度（指数减数用，与 lzd_q 同源）
  logic        sign_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      exp_big_q        <= exp_big;
      cs4_op0_q        <= exp_b_greater ? sig_b : sig_a;
      cs4_op1_q        <= {1'b0, exp_b_greater ? small_shr1_a : small_shr1_b};
      lzd_q            <= lzd;
      cs_selected_q    <= cs_selected;
      inexact_q        <= inexact;
      frac_from_cs4_q  <= sel_cs4;
      cs_selected_nz_q <= |cs_selected;
      floor_hit_q      <= |(floor_mask & cs_selected);
      exp_from_cs4_q   <= sel_cs4;
      exp_sub_lzd_q    <= {3'b000, lzd};
      sign_q           <= result_sign;
    end
  end

  // ---------------------------------------------------------------------------
  // §5 第 1 拍：左移规格化 / CS4 直接相减
  // ---------------------------------------------------------------------------
  logic [24:0] cs4, lshifted;
  ClosePathF32WidenF16MixedPipelineAdder U_CS4 (
    .io_adder_op0 (cs4_op0_q),
    .io_adder_op1 (cs4_op1_q),
    .io_result    (cs4)
  );
  CloseShiftLeftWithMux_1 U_Lshift (
    .io_src        (cs_selected_q),
    .io_shiftValue (lzd_q),
    .io_result     (lshifted)
  );

  logic [22:0] frac_result;
  assign frac_result = frac_from_cs4_q ? cs4[22:0] : lshifted[23:1];

  // ---------------------------------------------------------------------------
  // §6 指数
  // ---------------------------------------------------------------------------
  logic       head_is_one;             // 左移后最高位确实是 1（规格数结果）
  logic [7:0] exp_sub, exp_result;
  assign head_is_one = ((8'(exp_big_q - 8'd1) > {3'b000, lzd_q}) & cs_selected_nz_q) | floor_hit_q;
  assign exp_sub     = exp_from_cs4_q ? 8'h0 : (head_is_one ? exp_sub_lzd_q : exp_big_q);
  assign exp_result  = 8'(exp_big_q - exp_sub);

  assign fp_c   = {sign_q, exp_result, frac_result};
  assign fflags = {4'b0000, inexact_q};          // {NV, DZ, OF, UF, NX}
endmodule

module ClosePathF32WidenF16MixedPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [31:0] io_fp_a,
  input  logic [31:0] io_fp_b,
  output logic [31:0] io_fp_c,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  input  logic        io_res_is_f32,
  output logic [24:0] io_CS1
);
  xs_ClosePathF32WidenF16MixedPipeline_core u_core (
    .clock         (clock),
    .fire          (io_fire),
    .fp_a          (io_fp_a),
    .fp_b          (io_fp_b),
    .round_mode    (io_round_mode),
    .res_is_f32    (io_res_is_f32),
    .fp_c          (io_fp_c),
    .fflags        (io_fflags),
    .cs1_b_minus_a (io_CS1)
  );
endmodule
