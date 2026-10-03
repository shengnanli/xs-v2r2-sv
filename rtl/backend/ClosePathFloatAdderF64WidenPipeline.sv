// =============================================================================
// ClosePathFloatAdderF64WidenPipeline —— f64 浮点加法的 close path（两拍流水）
//
// 在哪一层：FloatAdderF64WidenPipeline / FloatAdderF64Pipeline 的 U_close_path（hasMinMaxCompare=true，
//   CS1 = b - a 引出给父级比较尾数大小）。设计源：yunsuan/vector/VectorFloatAdder.scala
//   class ClosePathFloatAdderF64WidenPipeline（exponentWidth=11, significandWidth=53）。
// close path 管的情形：有效相减且两指数差 <= 1。对阶至多右移 1 位（只产生一个 guard 位，没有
//   round/sticky），但相减可能大量抵消，需要前导零计数（LZD）+ 左移规格化。
//   与 f32/f16 那份（ClosePathF32WidenF16MixedPipeline）同一套算法，只是没有 f16 铺位、宽度换成 f64。
//
// 第 0 拍：
//   §1 指数关系：只看指数低两位就能在"差 <= 1"前提下判出 b 大还是相等；指数 0 与 1 视为相等
//      （非规格数的有效指数是 1）。
//   §2 四个候选差同时算（ClosePathAdder / ClosePathAdder_2，各 54 位带借位）：
//        CS0 = a - b、CS1 = b - a（指数相等）；
//        CS2 = 2a - b、CS3 = 2b - a（指数差 1，大数左移一位代替小数右移一位，guard 位落在 bit0）。
//      选择：指数相等按 CS0 借位选 CS0 / CS1；差 1 时一般选 CS2 / CS3，但若"结果最高位为 1 且
//      guard 会让结果进位"——即结果不需要左移、舍入还会进上去——改走 CS4（第 1 拍的直接相减路径）。
//   §3 指数下限掩码：大数指数为 e 时左移量最多 e-1（再多就成非规格数），把这个位置在 54 位候选上
//      标成 1 再一起做 LZD，左移量就自动被截在下限。
//   §4 打拍。
// 第 1 拍：
//   §5 左移规格化（CloseShiftLeftWithMux）；CS4 = 大数有效数 - 小数右移一位。
//   §6 指数 = EA - 左移量；"左移后最高位为 1"不成立（全部抵消 / 撞到下限）时减掉整个 EA（得 0）。
// 怪癖（照 golden，寄存器集合与位宽逐个对应，不合并）：
//   - 选中的候选打了两份（一份给移位器，一份只用来判"非全 0"）；sel_CS4 打了两份（选尾数 / 选指数
//     减数）；EA 打了两份（被减数 / 减数备选），另存一份 EA-1 给"最高位为 1"比较；
//     "下限位命中"存的是整条 54 位的 mask & CS，到第 1 拍才归约。
//   - CS4 减数寄存器 53 位、最高位恒 0；CS4 只取结果 [51:0]，被减数 MSB 实际不影响输出。
//   - 符号的 Mux1H 第一项写成 "sel_CS0 & (CS0 借位 | CS1 借位)"，而 sel_CS0 已蕴含 CS0 无借位，
//     实际只看 CS1 借位；照抄。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：ClosePathAdder ×3（U_CS0/U_CS1/U_CS4）、ClosePathAdder_2 ×2
//   （U_CS2/U_CS3）、CloseShiftLeftWithMux（U_Lshift）。
// golden 对照：G1-canonical/golden-rtl/ClosePathFloatAdderF64WidenPipeline.sv
// =============================================================================
module xs_ClosePathFloatAdderF64WidenPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [63:0] fp_a,
  input  logic [63:0] fp_b,
  input  logic [2:0]  round_mode,
  output logic [63:0] fp_c,
  output logic [4:0]  fflags,
  output logic [53:0] cs1_b_minus_a    // CS1 = {0,sig_b} - {0,sig_a}，父级比较尾数大小用
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a;
  logic [10:0] exp_a, exp_b;
  logic [51:0] mant_a, mant_b;
  logic        exp_a_nz, exp_b_nz;
  logic [52:0] sig_a, sig_b;
  assign sign_a   = fp_a[63];
  assign exp_a    = fp_a[62:52];
  assign exp_b    = fp_b[62:52];
  assign mant_a   = fp_a[51:0];
  assign mant_b   = fp_b[51:0];
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
  logic        exp_b_greater, exp_equal;
  logic [10:0] exp_big;                // EA：大数的指数
  // 差 1 时两个 LSB 必不同；此时 b 大 <=> (a1 ^ b1) == a0
  assign exp_b_greater = (exp_b[0] ^ exp_a[0]) & (exp_a[1] ^ exp_b[1] ^ ~exp_a[0]);
  // LSB 相同 = 相等；或一个是 0 一个非 0（只可能是 0 对 1：有效指数都是 1）
  assign exp_equal     = ~(exp_a[0] ^ exp_b[0]) | (exp_a_nz ^ exp_b_nz);
  assign exp_big       = exp_b_greater ? exp_b : exp_a;

  // ---------------------------------------------------------------------------
  // §2 四个候选差
  // ---------------------------------------------------------------------------
  logic [53:0] cs0, cs1, cs2, cs3;
  ClosePathAdder U_CS0 (               // a - b
    .io_adder_op0 (sig_a),
    .io_adder_op1 (sig_b),
    .io_result    (cs0)
  );
  ClosePathAdder U_CS1 (               // b - a
    .io_adder_op0 (sig_b),
    .io_adder_op1 (sig_a),
    .io_result    (cs1)
  );
  ClosePathAdder_2 U_CS2 (             // 2a - b（a 大一个指数时隐含位必为 1）
    .io_adder_op0 ({1'b1, mant_a}),
    .io_adder_op1 ({1'b1, mant_b}),
    .io_result    (cs2)
  );
  ClosePathAdder_2 U_CS3 (             // 2b - a
    .io_adder_op0 ({1'b1, mant_b}),
    .io_adder_op1 ({1'b1, mant_a}),
    .io_result    (cs3)
  );
  assign cs1_b_minus_a = cs1;

  // 差 1 时"若不左移、guard 会不会让结果进位"：bit0 是 guard 位置、bit1 是不左移时结果的 LSB；
  // 结果符号 a 大为 sign_a，b 大为 ~sign_a
  logic cs2_round_up, cs3_round_up;
  assign cs2_round_up = mant_b[0] & ((rup & ~sign_a) | (rdn & sign_a) | (rne & cs2[1] & cs2[0]) | rmm);
  assign cs3_round_up = mant_a[0] & ((rup & sign_a) | (rdn & ~sign_a) | (rne & cs3[1] & cs3[0]) | rmm);

  logic sel_cs0, sel_cs1, sel_cs2, sel_cs3, sel_cs4;
  assign sel_cs0 = exp_equal & ~cs0[53];
  assign sel_cs1 = exp_equal &  cs0[53];
  assign sel_cs2 = ~exp_equal & ~exp_b_greater & (~cs2[53] | ~cs2[0] | ~cs2_round_up);
  assign sel_cs3 = ~exp_equal &  exp_b_greater & (~cs3[53] | ~cs3[0] | ~cs3_round_up);
  assign sel_cs4 = ~exp_equal & ((~exp_b_greater & cs2[53] & cs2[0] & cs2_round_up)
                               | ( exp_b_greater & cs3[53] & cs3[0] & cs3_round_up));

  logic [53:0] cs_selected;            // CS0/CS1 补一位 0 对齐到 CS2/CS3 的 54 位格式
  assign cs_selected = ({54{sel_cs0}} & {cs0[52:0], 1'b0})
                     | ({54{sel_cs1}} & {cs1[52:0], 1'b0})
                     | ({54{sel_cs2}} & cs2)
                     | ({54{sel_cs3}} & cs3);

  // ---------------------------------------------------------------------------
  // §3 指数下限掩码 + 前导零计数
  // ---------------------------------------------------------------------------
  // exp_floor_mask(e)[52] = (e <= 1)：不许左移
  // exp_floor_mask(e)[k]  = (e == 53 - k), k = 0..51：最多左移 e-1 位，在那一位标 1
  function automatic logic [52:0] exp_floor_mask(input logic [10:0] e);
    exp_floor_mask[52] = (e == 11'd0) | (e == 11'd1);
    for (int k = 0; k < 52; k++)
      exp_floor_mask[k] = (e == 11'(53 - k));
  endfunction

  logic [52:0] floor_mask_a, floor_mask_b;
  logic [53:0] floor_mask;
  assign floor_mask_a = exp_floor_mask(exp_a);
  assign floor_mask_b = exp_floor_mask(exp_b);
  assign floor_mask = ({54{sel_cs0}} & {floor_mask_a, 1'b1})
                    | ({54{sel_cs1}} & {floor_mask_b, 1'b1})
                    | ({54{sel_cs2}} & {floor_mask_a, exp_a == 11'd54})
                    | ({54{sel_cs3}} & {floor_mask_b, exp_b == 11'd54});

  logic [53:0] lzd_input;
  logic [5:0]  lzd;                    // 前导零个数；全 0 时为 54
  assign lzd_input = cs_selected | floor_mask;
  always_comb begin
    lzd = 6'd54;
    for (int i = 0; i < 54; i++)
      if (lzd_input[i]) lzd = 6'(53 - i);    // 从低往高扫，最后命中的是最高的 1
  end

  // ---------------------------------------------------------------------------
  // §4 第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic guard_bit;                     // 小数被右移掉的 guard 位（小数是非规格数时为 0）
  logic inexact;
  logic result_sign;
  assign guard_bit = exp_b_greater ? (exp_a_nz & mant_a[0]) : (exp_b_nz & mant_b[0]);
  assign inexact   = ((sel_cs2 & cs2[53] & cs2[0] & ~cs2_round_up)
                    | (sel_cs3 & cs3[53] & cs3[0] & ~cs3_round_up)
                    | sel_cs4) & guard_bit;
  assign result_sign = (sel_cs0 & exp_equal & (cs0[53] | cs1[53]) & sign_a)   // a > b
                     | (sel_cs0 & exp_equal & ~cs0[53] & ~cs1[53] & rdn)      // 恰好抵消：RDN 给 -0
                     | (sel_cs1 & ~sign_a)
                     | (sel_cs2 & sign_a)
                     | (sel_cs3 & ~sign_a)
                     | (sel_cs4 & (exp_b_greater ^ sign_a));

  logic [52:0] cs4_op0_q;              // CS4 被减数：大数有效数
  logic [52:0] cs4_op1_q;              // CS4 减数：小数有效数右移一位（MSB 恒 0）
  logic [5:0]  lzd_q;                  // 左移量（也作指数减数）
  logic [53:0] cs_selected_q;          // 给移位器
  logic        inexact_q;
  logic        frac_from_cs4_q;        // sel_CS4（选尾数用）
  logic [10:0] exp_big_minus1_q;       // EA - 1：左移量不超过它才算"最高位为 1"
  logic [53:0] cs_selected_chk_q;      // 选中候选的第二份（只判非全 0）
  logic [53:0] floor_hit_q;            // mask & CS：候选在下限位置上为 1
  logic        exp_from_cs4_q;         // sel_CS4（选指数减数用，与上面同源）
  logic [10:0] exp_big_alt_q;          // EA 的第二份（"结果为 0"时整个减掉）
  logic [10:0] exp_big_q;              // EA（被减数）
  logic        sign_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      cs4_op0_q         <= exp_b_greater ? sig_b : sig_a;
      cs4_op1_q         <= {1'b0, exp_b_greater ? sig_a[52:1] : sig_b[52:1]};
      lzd_q             <= lzd;
      cs_selected_q     <= cs_selected;
      inexact_q         <= inexact;
      frac_from_cs4_q   <= sel_cs4;
      exp_big_minus1_q  <= 11'(exp_big - 11'd1);
      cs_selected_chk_q <= cs_selected;
      floor_hit_q       <= floor_mask & cs_selected;
      exp_from_cs4_q    <= sel_cs4;
      exp_big_alt_q     <= exp_big;
      exp_big_q         <= exp_big;
      sign_q            <= result_sign;
    end
  end

  // ---------------------------------------------------------------------------
  // §5 第 1 拍：左移规格化 / CS4 直接相减
  // ---------------------------------------------------------------------------
  logic [53:0] cs4, lshifted;
  ClosePathAdder U_CS4 (
    .io_adder_op0 (cs4_op0_q),
    .io_adder_op1 (cs4_op1_q),
    .io_result    (cs4)
  );
  CloseShiftLeftWithMux U_Lshift (
    .io_src        (cs_selected_q),
    .io_shiftValue (lzd_q),
    .io_result     (lshifted)
  );

  logic [51:0] frac_result;
  assign frac_result = frac_from_cs4_q ? cs4[51:0] : lshifted[52:1];

  // ---------------------------------------------------------------------------
  // §6 指数
  // ---------------------------------------------------------------------------
  logic        head_is_one;            // 左移后最高位确实是 1（规格数结果）
  logic [10:0] exp_sub, exp_result;
  assign head_is_one = ((exp_big_minus1_q > {5'b00000, lzd_q}) & (|cs_selected_chk_q)) | (|floor_hit_q);
  assign exp_sub     = exp_from_cs4_q ? 11'h0 : (head_is_one ? {5'b00000, lzd_q} : exp_big_alt_q);
  assign exp_result  = 11'(exp_big_q - exp_sub);

  assign fp_c   = {sign_q, exp_result, frac_result};
  assign fflags = {4'b0000, inexact_q};          // {NV, DZ, OF, UF, NX}
endmodule

module ClosePathFloatAdderF64WidenPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [63:0] io_fp_a,
  input  logic [63:0] io_fp_b,
  output logic [63:0] io_fp_c,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  output logic [53:0] io_CS1
);
  xs_ClosePathFloatAdderF64WidenPipeline_core u_core (
    .clock         (clock),
    .fire          (io_fire),
    .fp_a          (io_fp_a),
    .fp_b          (io_fp_b),
    .round_mode    (io_round_mode),
    .fp_c          (io_fp_c),
    .fflags        (io_fflags),
    .cs1_b_minus_a (io_CS1)
  );
endmodule
