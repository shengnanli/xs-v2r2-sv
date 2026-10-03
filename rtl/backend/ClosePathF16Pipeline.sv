// =============================================================================
// ClosePathF16Pipeline —— 纯 f16 浮点加法的 close path（两拍流水）
//
// 在哪一层：FloatAdderF16Pipeline 的 U_close_path（hasMinMaxCompare=true 变体，CS1 减法器结果引出给
//   父级做尾数大小比较）。设计源：yunsuan/vector/VectorFloatAdder.scala class ClosePathF16Pipeline
//   （exponentWidth=5、significandWidth=11）。算法与已签的 ClosePathF32WidenF16MixedPipeline 相同，
//   只服务 f16；寄存器集合照 golden（"左移后最高位为 1"的两份原料按 12 位向量打拍，第 1 拍再归约）。
// close path 管的情形：有效相减且两指数差 <= 1。对阶至多右移 1 位（只产生一个 guard 位），
//   但相减可能大量抵消，需要前导零计数 + 左移规格化。
//
// 第 0 拍：
//   §1 指数关系：只看指数低两位就能在"差 <= 1"前提下判出 b 大还是相等；指数 0 与 1 视为相等。
//   §2 四个候选差同时算：CS0 = a - b、CS1 = b - a（指数相等，12 位带借位，ClosePathAdderF16Pipeline）；
//      CS2 = 2a - b、CS3 = 2b - a（指数差 1，大数左移一位代替小数右移一位，guard 落在 bit0，
//      ClosePathAdderF16Pipeline_2）。指数相等按 CS0 借位选 CS0 / CS1；差 1 时一般选 CS2 / CS3，
//      但若"结果最高位为 1 且 guard 要进位"——不必左移、舍入还会进上去——改走 CS4（第 1 拍直接相减）。
//   §3 指数下限掩码：大数指数为 e 时左移量最多 e-1，把那一位在 12 位候选上标 1 再做前导零计数（LZD），
//      左移量就自动截在下限。
//   §4 打拍。
// 第 1 拍：
//   §5 左移规格化（CloseShiftLeftWithMux_9）；CS4 = 大数有效数 - 小数右移一位。
//   §6 指数 = EA - 左移量；"左移后最高位为 1"不成立（全部抵消 / 撞到下限）时减掉整个 EA（得 0）。
// 怪癖（照 golden，不合并）：
//   - sel_CS4 打两份（一份选尾数、一份选指数减数）；EA 打两份（被减数一份、"减掉整个 EA"一份）；
//     选中的候选 CS_0123 打两份（一份进左移器，一份在第 1 拍做"非零"归约）。
//   - CS4 的减数寄存器最高位恒 0（{0, 小数有效数[10:1]}），照 golden 保留 11 位宽。
//   - 符号 Mux1H 第一项写成 "sel_CS0 & (CS0 借位 | CS1 借位)"，sel_CS0 已蕴含 CS0 无借位；照抄。
//   - CS2 的舍入判定用 fp_b[0]（不看 b 是否非规格数），NX 的 guard 位才按非规格数门控。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 子模块（实例名与 golden 一致）：ClosePathAdderF16Pipeline ×3（U_CS0/U_CS1/U_CS4）、
//   ClosePathAdderF16Pipeline_2 ×2（U_CS2/U_CS3）、CloseShiftLeftWithMux_9（U_Lshift）。
// golden 对照：G1-canonical/golden-rtl/ClosePathF16Pipeline.sv
// =============================================================================
module xs_ClosePathF16Pipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [15:0] fp_a,
  input  logic [15:0] fp_b,
  input  logic [2:0]  round_mode,
  output logic [15:0] fp_c,
  output logic [4:0]  fflags,
  output logic [11:0] cs1_b_minus_a     // CS1 = {0,sig_b} - {0,sig_a}，父级比较尾数大小用
);
  // ---------------------------------------------------------------------------
  // 输入拆字段
  // ---------------------------------------------------------------------------
  logic        sign_a;
  logic [4:0]  exp_a, exp_b;
  logic [9:0]  mant_a, mant_b;
  logic        exp_a_nz, exp_b_nz;
  logic [10:0] sig_a, sig_b;
  assign sign_a   = fp_a[15];
  assign exp_a    = fp_a[14:10];
  assign exp_b    = fp_b[14:10];
  assign mant_a   = fp_a[9:0];
  assign mant_b   = fp_b[9:0];
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
  logic [4:0] exp_big;                  // EA：大数的指数
  // 差 1 时两个 LSB 必不同；此时 b 大 <=> (a1 ^ b1) == a0
  assign exp_b_greater = (exp_b[0] ^ exp_a[0]) & (exp_a[1] ^ exp_b[1] ^ ~exp_a[0]);
  // LSB 相同 = 相等；或一个是 0 一个非 0（只可能是 0 对 1：有效指数都是 1）
  assign exp_equal     = ~(exp_a[0] ^ exp_b[0]) | (exp_a_nz ^ exp_b_nz);
  assign exp_big       = exp_b_greater ? exp_b : exp_a;

  // ---------------------------------------------------------------------------
  // §2 四个候选差
  // ---------------------------------------------------------------------------
  logic [11:0] cs0, cs1, cs2, cs3;
  ClosePathAdderF16Pipeline U_CS0 (      // a - b
    .io_adder_op0 (sig_a),
    .io_adder_op1 (sig_b),
    .io_result    (cs0)
  );
  ClosePathAdderF16Pipeline U_CS1 (      // b - a
    .io_adder_op0 (sig_b),
    .io_adder_op1 (sig_a),
    .io_result    (cs1)
  );
  ClosePathAdderF16Pipeline_2 U_CS2 (    // 2a - b（a 大一个指数时隐含位必为 1）
    .io_adder_op0 ({1'b1, mant_a}),
    .io_adder_op1 ({1'b1, mant_b}),
    .io_result    (cs2)
  );
  ClosePathAdderF16Pipeline_2 U_CS3 (    // 2b - a
    .io_adder_op0 ({1'b1, mant_b}),
    .io_adder_op1 ({1'b1, mant_a}),
    .io_result    (cs3)
  );
  assign cs1_b_minus_a = cs1;

  // 差 1 时"若不左移、guard 会不会让结果进位"：bit0 是 guard 位置，bit1 是不左移时结果的 LSB；
  // 结果符号 a 大为 sign_a，b 大为 ~sign_a
  logic cs2_round_up, cs3_round_up;
  assign cs2_round_up = mant_b[0] & ((rup & ~sign_a) | (rdn & sign_a) | (rne & cs2[1] & cs2[0]) | rmm);
  assign cs3_round_up = mant_a[0] & ((rup & sign_a) | (rdn & ~sign_a) | (rne & cs3[1] & cs3[0]) | rmm);

  logic sel_cs0, sel_cs1, sel_cs2, sel_cs3, sel_cs4;
  assign sel_cs0 = exp_equal & ~cs0[11];
  assign sel_cs1 = exp_equal &  cs0[11];
  assign sel_cs2 = ~exp_equal & ~exp_b_greater & (~cs2[11] | ~cs2[0] | ~cs2_round_up);
  assign sel_cs3 = ~exp_equal &  exp_b_greater & (~cs3[11] | ~cs3[0] | ~cs3_round_up);
  assign sel_cs4 = ~exp_equal & ((~exp_b_greater & cs2[11] & cs2[0] & cs2_round_up)
                               | ( exp_b_greater & cs3[11] & cs3[0] & cs3_round_up));

  logic [11:0] cs_selected;             // CS0/CS1 补一位 0 对齐到 CS2/CS3 的 12 位格式
  assign cs_selected = ({12{sel_cs0}} & {cs0[10:0], 1'b0})
                     | ({12{sel_cs1}} & {cs1[10:0], 1'b0})
                     | ({12{sel_cs2}} & cs2)
                     | ({12{sel_cs3}} & cs3);

  // ---------------------------------------------------------------------------
  // §3 指数下限掩码 + 前导零计数
  // ---------------------------------------------------------------------------
  // exp_floor_mask(e)[10] = (e <= 1)：不许左移
  // exp_floor_mask(e)[k]  = (e == 11 - k), k = 0..9：最多左移 e-1 位，在那一位标 1
  function automatic logic [10:0] exp_floor_mask(input logic [4:0] e);
    exp_floor_mask[10] = (e == 5'd0) | (e == 5'd1);
    for (int k = 0; k < 10; k++)
      exp_floor_mask[k] = (e == 5'(11 - k));
  endfunction

  logic [10:0] floor_mask_a, floor_mask_b;
  logic [11:0] floor_mask;
  assign floor_mask_a = exp_floor_mask(exp_a);
  assign floor_mask_b = exp_floor_mask(exp_b);
  assign floor_mask = ({12{sel_cs0}} & {floor_mask_a, 1'b1})
                    | ({12{sel_cs1}} & {floor_mask_b, 1'b1})
                    | ({12{sel_cs2}} & {floor_mask_a, exp_a == 5'd12})
                    | ({12{sel_cs3}} & {floor_mask_b, exp_b == 5'd12});

  logic [11:0] lzd_input;
  logic [3:0]  lzd;                     // 前导零个数；全 0 时为 12
  assign lzd_input = cs_selected | floor_mask;
  always_comb begin
    lzd = 4'd12;
    for (int i = 0; i < 12; i++)
      if (lzd_input[i]) lzd = 4'(11 - i);    // 从低往高扫，最后命中的是最高的 1
  end

  // ---------------------------------------------------------------------------
  // §4 第 0 拍寄存器
  // ---------------------------------------------------------------------------
  logic guard_bit;                      // 小数被右移掉的 guard 位（小数是非规格数时为 0）
  logic inexact;
  logic result_sign;
  assign guard_bit = exp_b_greater ? (exp_a_nz & mant_a[0]) : (exp_b_nz & mant_b[0]);
  assign inexact   = ((sel_cs2 & cs2[11] & cs2[0] & ~cs2_round_up)
                    | (sel_cs3 & cs3[11] & cs3[0] & ~cs3_round_up)
                    | sel_cs4) & guard_bit;
  assign result_sign = (sel_cs0 & exp_equal & (cs0[11] | cs1[11]) & sign_a)   // a > b
                     | (sel_cs0 & exp_equal & ~cs0[11] & ~cs1[11] & rdn)      // 恰好抵消：RDN 给 -0
                     | (sel_cs1 & ~sign_a)
                     | (sel_cs2 & sign_a)
                     | (sel_cs3 & ~sign_a)
                     | (sel_cs4 & (exp_b_greater ^ sign_a));

  logic [10:0] cs4_op0_q, cs4_op1_q;    // CS4：大数有效数 - 小数右移一位（op1[10] 恒 0）
  logic [3:0]  lzd_q;
  logic [11:0] cs_selected_q;           // 进左移器
  logic        inexact_q;
  logic        frac_from_cs4_q;         // sel_CS4（选尾数用）
  logic [4:0]  exp_big_minus1_q;        // EA - 1：左移量上限
  logic [11:0] cs_selected_dup_q;       // 与 cs_selected_q 同源，第 1 拍做"非零"归约
  logic [11:0] floor_hit_q;             // 选中候选与下限掩码的交
  logic        exp_from_cs4_q;          // sel_CS4（选指数减数用，与上面同源）
  logic [4:0]  exp_big_sub_q;           // EA（"减掉整个 EA"那一份）
  logic [4:0]  exp_big_q;               // EA（被减数那一份）
  logic        sign_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      cs4_op0_q         <= exp_b_greater ? sig_b : sig_a;
      cs4_op1_q         <= {1'b0, exp_b_greater ? sig_a[10:1] : sig_b[10:1]};
      lzd_q             <= lzd;
      cs_selected_q     <= cs_selected;
      inexact_q         <= inexact;
      frac_from_cs4_q   <= sel_cs4;
      exp_big_minus1_q  <= 5'(exp_big - 5'd1);
      cs_selected_dup_q <= cs_selected;
      floor_hit_q       <= floor_mask & cs_selected;
      exp_from_cs4_q    <= sel_cs4;
      exp_big_sub_q     <= exp_big;
      exp_big_q         <= exp_big;
      sign_q            <= result_sign;
    end
  end

  // ---------------------------------------------------------------------------
  // §5 第 1 拍：左移规格化 / CS4 直接相减
  // ---------------------------------------------------------------------------
  logic [11:0] cs4, lshifted;
  ClosePathAdderF16Pipeline U_CS4 (
    .io_adder_op0 (cs4_op0_q),
    .io_adder_op1 (cs4_op1_q),
    .io_result    (cs4)
  );
  CloseShiftLeftWithMux_9 U_Lshift (
    .io_src        (cs_selected_q),
    .io_shiftValue (lzd_q),
    .io_result     (lshifted)
  );

  logic [9:0] frac_result;
  assign frac_result = frac_from_cs4_q ? cs4[9:0] : lshifted[10:1];

  // ---------------------------------------------------------------------------
  // §6 指数
  // ---------------------------------------------------------------------------
  logic       head_is_one;              // 左移后最高位确实是 1（规格数结果）
  logic [4:0] exp_sub;
  assign head_is_one = ((exp_big_minus1_q > {1'b0, lzd_q}) & (|cs_selected_dup_q)) | (|floor_hit_q);
  assign exp_sub     = exp_from_cs4_q ? 5'd0 : (head_is_one ? {1'b0, lzd_q} : exp_big_sub_q);

  assign fp_c   = {sign_q, 5'(exp_big_q - exp_sub), frac_result};
  assign fflags = {4'b0000, inexact_q};           // {NV, DZ, OF, UF, NX}
endmodule

module ClosePathF16Pipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [15:0] io_fp_a,
  input  logic [15:0] io_fp_b,
  output logic [15:0] io_fp_c,
  input  logic [2:0]  io_round_mode,
  output logic [4:0]  io_fflags,
  output logic [11:0] io_CS1
);
  xs_ClosePathF16Pipeline_core u_core (
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
