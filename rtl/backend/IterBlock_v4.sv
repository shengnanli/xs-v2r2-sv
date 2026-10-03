// =============================================================================
// IterBlock_v4.sv —— SRT radix-16 整数除法的一拍迭代（两个 radix-4 商位）
//                    家族参数化核 + IterBlock_v4（16 位，w 宽 22）wrapper
//
// 在哪一层：VectorIdiv → SRT16Divint{,_4,_6}（16/32/64 位）→ 本块 → SelBlock_v4 +
//   SpecBlock_v4 + 2×CSA3_2_<w> + CSA3_2_4017 + 2×Conversion*。SRT16Divint 在 iter
//   状态每拍调用本块一次，把本块的 nxt_* 寄存起来作为下一拍的 pre_*。
//
// SRT 原理（本块对应「迭代合成」）：
//   余数递推 w[j+1] = 4·w[j] − q[j+1]·d，商位 q ∈ {-2,-1,0,+1,+2}（radix-4 最小冗余）。
//   余数始终以 carry-save（sum, carry 两个向量）保存，循环里没有长进位链。
//   一拍做两步（radix-16 = 4×4）：
//     q1：SelBlock 由上一拍的 pre_sel 取符号定出（不依赖本拍任何余数计算）；
//     q2：SpecBlock 在上一拍已对 q1 的 5 种可能各算好一套，本拍按 q1 一选；
//   然后本块把两步的余数更新串起来：
//     w1 = CSA(pre_iterB.sum, pre_iterB.carry, −q1·d)          （第一步，已 ×4 对齐）
//     w2 = CSA(4·w1.sum, 4·w1.carry, −q2·d)                    （第二步）
//     nxt_iterB = 4·w2（下一拍的输入已预先 ×4）
//   商用 on-the-fly conversion（Conversion，A/B 两个寄存器，A=Q，B=Q−1）逐位拼出，
//   不需要最后再做一次带符号数字到二进制的转换加法。
//   选择/投机路径用不着整条余数：从 pre_iterB 截 11 位（3 位整数 + 8 位小数），加上
//   −16·q1·d 的截断（spec_r2ud[q1]）过一级 CSA，得到 16·w1 的短估计，
//   高 8 位给 SelBlock（3+5 格式）、低 9 位给 SpecBlock（3+6 格式）。
//
// 商位编码（全族统一）：独热第 i 位代表商位 2-i（bit0=+2 … bit4=-2）。
//   iter_cons[i] / spec_r2ud[i] 是「−(2-i)·d」的整宽 / 截断值。i=2 即 q=0，父级恒连 0，
//   golden 因而把 io_iter_cons_2 / io_spec_r2ud_2 两个端口优化掉了；wrapper 在这两个
//   下标上接常数 0，核里仍按 5 选 1 写（q=0 时加 0，语义一致）。
//
// 位宽（BIT_WIDTH = 被除数位宽 16/32/64）：
//   W = BIT_WIDTH + 6（1 位符号 + 2 位 ×4 移位余量 + 3 位对齐，Scala 注释原话）。
//   carry 向量出 CSA 后要左移 1 位对齐权重；再 ×4 即合计左移 3 位，高位截掉。
//   截取窗口 pre_iterB[W-5 : W-15]（即 (x<<4) 的最高 11 位）。
//
// 变体：IterBlock_v4（16 位，本文件 wrapper）、IterBlock_v4_4（32）、IterBlock_v4_6（64）
//   只差位宽与子模块编号（golden 按位宽把同一个 Chisel 类实例化成不同编号的模块）：
//     BIT_WIDTH 16 → CSA3_2_3987(22) + Conversion
//     BIT_WIDTH 32 → CSA3_2_4111(38) + Conversion_8
//     BIT_WIDTH 64 → CSA3_2_4173(70) + Conversion_12
//   核里用 generate 按 BIT_WIDTH 挑选，其余一律共用；变体文件只是薄 wrapper。
//
// 子模块全部两侧白盒（本仓已签核重写件）。纯组合：零寄存器、无 clock/reset。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class IterBlock_v4)
// golden 对照：G1-canonical/golden-rtl/IterBlock_v4{,_4,_6}.sv
// wrapper 与 selB/specB 的端口连线由 scripts/gen_srt_divblocks.py 生成（GENERATED 区）。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_IterBlock_v4_core —— 参数化可读核（端口名沿用 Scala 的 io 字段名）
// -----------------------------------------------------------------------------
module xs_IterBlock_v4_core #(
  parameter int BIT_WIDTH = 16
) (
  input  logic [7:0]             Sel_cons  [0:4][0:3],      // SelBlock 比较常数 [q2][k]
  input  logic [8:0]             Spec_cons [0:4][0:3],      // SpecBlock 比较常数 [q2][k]
  input  logic [BIT_WIDTH+5:0]   iter_cons [0:4],           // −q·d（整宽），[2] 恒 0
  input  logic [8:0]             d_trunc   [0:3],           // 投机用 −u·d 截断（u=+2,+1,-1,-2）
  input  logic [10:0]            spec_r2ud [0:4],           // −16·q·d 截断（11 位），[2] 恒 0
  input  logic [BIT_WIDTH-1:0]   pre_q_A,                   // on-the-fly 商寄存器 A（=Q）
  input  logic [BIT_WIDTH-1:0]   pre_q_B,                   //                     B（=Q−1）
  output logic [BIT_WIDTH-1:0]   nxt_q_A,
  output logic [BIT_WIDTH-1:0]   nxt_q_B,
  input  logic [7:0]             pre_sel   [0:3][0:1],
  output logic [7:0]             nxt_sel   [0:3][0:1],
  input  logic [8:0]             pre_spec  [0:4][0:3][0:1],
  output logic [8:0]             nxt_spec  [0:4][0:3][0:1],
  input  logic [BIT_WIDTH+5:0]   pre_iterB [0:1],           // 4·w[j]（[0]=sum, [1]=carry 已对齐）
  output logic [BIT_WIDTH+5:0]   nxt_iterB [0:1]            // 4·w[j+2]
);
  localparam int W = BIT_WIDTH + 6;

  logic [4:0] q1_oh;    // 本拍第一个商位（SelBlock 出）
  logic [4:0] q2_oh;    // 本拍第二个商位（SpecBlock 出）

  // ---------------------------------------------------------------------------
  // §1 −q·d 选择（Mux1H = 按位或，非独热时照 golden 叠加）
  // ---------------------------------------------------------------------------
  logic [W-1:0] neg_q1_d, neg_q2_d;
  logic [10:0]  neg_q1_d_x16_trunc;
  always_comb begin
    neg_q1_d           = '0;
    neg_q2_d           = '0;
    neg_q1_d_x16_trunc = '0;
    for (int i = 0; i < 5; i++) begin
      if (q1_oh[i]) neg_q1_d           = neg_q1_d           | iter_cons[i];
      if (q2_oh[i]) neg_q2_d           = neg_q2_d           | iter_cons[i];
      if (q1_oh[i]) neg_q1_d_x16_trunc = neg_q1_d_x16_trunc | spec_r2ud[i];
    end
  end

  // ---------------------------------------------------------------------------
  // §2 余数短估计（给下一拍的选择/投机用）：16·w1 ≈ (pre_iterB << 4) 的高 11 位
  //    + (−16·q1·d) 截断，一级 11 位 CSA。高 8 位 → SelBlock，低 9 位 → SpecBlock。
  // ---------------------------------------------------------------------------
  logic [10:0] est_sum, est_carry;
  CSA3_2_4017 u_csa_est (
    .io_in_0  (pre_iterB[0][W-5 -: 11]),
    .io_in_1  (pre_iterB[1][W-5 -: 11]),
    .io_in_2  (neg_q1_d_x16_trunc),
    .io_out_0 (est_sum),
    .io_out_1 (est_carry)
  );

  logic [10:0] est_carry_x2;            // carry 权重对齐（左移 1，11 位截断）
  logic [7:0]  sel_rem  [0:1];          // 3+5 格式
  logic [8:0]  spec_rem [0:1];          // 3+6 格式
  assign est_carry_x2 = {est_carry[9:0], 1'b0};
  assign sel_rem[0]   = est_sum[10:3];
  assign sel_rem[1]   = est_carry_x2[10:3];
  assign spec_rem[0]  = est_sum[8:0];
  assign spec_rem[1]  = est_carry_x2[8:0];

  // ---------------------------------------------------------------------------
  // §3 两步余数更新（整宽 carry-save）。
  //    第一步：w1 = pre_iterB + (−q1·d)；
  //    第二步：w2 = 4·w1 + (−q2·d)，carry 半边先左移 1 对齐再 ×4；
  //    出口：nxt_iterB = 4·w2（同样的移位），供下一拍直接当 pre_iterB。
  // ---------------------------------------------------------------------------
  logic [W-1:0] w1_sum, w1_carry, w2_sum, w2_carry;
  logic [W-1:0] w1x4_sum, w1x4_carry;
  assign w1x4_sum     = {w1_sum[W-3:0], 2'b00};
  assign w1x4_carry   = {w1_carry[W-4:0], 3'b000};
  assign nxt_iterB[0] = {w2_sum[W-3:0], 2'b00};
  assign nxt_iterB[1] = {w2_carry[W-4:0], 3'b000};

  // ---------------------------------------------------------------------------
  // §4 按位宽挑选子模块编号（同一 Chisel 类在 golden 里按宽度编了不同的号）：
  //    整宽 CSA ×2（两步余数更新）+ Conversion ×2（两个商位依次拼进 A/B）。
  // ---------------------------------------------------------------------------
  logic [BIT_WIDTH-1:0] mid_q_A, mid_q_B;   // 拼完 q1、尚未拼 q2 的商
  if (BIT_WIDTH == 16) begin : g_w16
    CSA3_2_3987 u_csa_step1 (.io_in_0(pre_iterB[0]), .io_in_1(pre_iterB[1]), .io_in_2(neg_q1_d),
                             .io_out_0(w1_sum), .io_out_1(w1_carry));
    CSA3_2_3987 u_csa_step2 (.io_in_0(w1x4_sum), .io_in_1(w1x4_carry), .io_in_2(neg_q2_d),
                             .io_out_0(w2_sum), .io_out_1(w2_carry));
    Conversion  u_conv_q1   (.io_q_j_1(q1_oh), .io_pre_q_A(pre_q_A), .io_pre_q_B(pre_q_B),
                             .io_nxt_q_A(mid_q_A), .io_nxt_q_B(mid_q_B));
    Conversion  u_conv_q2   (.io_q_j_1(q2_oh), .io_pre_q_A(mid_q_A), .io_pre_q_B(mid_q_B),
                             .io_nxt_q_A(nxt_q_A), .io_nxt_q_B(nxt_q_B));
  end else if (BIT_WIDTH == 32) begin : g_w32
    CSA3_2_4111 u_csa_step1 (.io_in_0(pre_iterB[0]), .io_in_1(pre_iterB[1]), .io_in_2(neg_q1_d),
                             .io_out_0(w1_sum), .io_out_1(w1_carry));
    CSA3_2_4111 u_csa_step2 (.io_in_0(w1x4_sum), .io_in_1(w1x4_carry), .io_in_2(neg_q2_d),
                             .io_out_0(w2_sum), .io_out_1(w2_carry));
    Conversion_8 u_conv_q1  (.io_q_j_1(q1_oh), .io_pre_q_A(pre_q_A), .io_pre_q_B(pre_q_B),
                             .io_nxt_q_A(mid_q_A), .io_nxt_q_B(mid_q_B));
    Conversion_8 u_conv_q2  (.io_q_j_1(q2_oh), .io_pre_q_A(mid_q_A), .io_pre_q_B(mid_q_B),
                             .io_nxt_q_A(nxt_q_A), .io_nxt_q_B(nxt_q_B));
  end else if (BIT_WIDTH == 64) begin : g_w64
    CSA3_2_4173 u_csa_step1 (.io_in_0(pre_iterB[0]), .io_in_1(pre_iterB[1]), .io_in_2(neg_q1_d),
                             .io_out_0(w1_sum), .io_out_1(w1_carry));
    CSA3_2_4173 u_csa_step2 (.io_in_0(w1x4_sum), .io_in_1(w1x4_carry), .io_in_2(neg_q2_d),
                             .io_out_0(w2_sum), .io_out_1(w2_carry));
    Conversion_12 u_conv_q1 (.io_q_j_1(q1_oh), .io_pre_q_A(pre_q_A), .io_pre_q_B(pre_q_B),
                             .io_nxt_q_A(mid_q_A), .io_nxt_q_B(mid_q_B));
    Conversion_12 u_conv_q2 (.io_q_j_1(q2_oh), .io_pre_q_A(mid_q_A), .io_pre_q_B(mid_q_B),
                             .io_nxt_q_A(nxt_q_A), .io_nxt_q_B(nxt_q_B));
  end
  // BIT_WIDTH 只有 16/32/64 三档（golden 只有这三个变体）；其它值没有对应子模块，
  // 上面三支都不生成，w1/w2/商输出悬空——VCS 会报未驱动告警，不会静默"对"。

  // ---------------------------------------------------------------------------
  // §5 商位选择：SelBlock 出 q1、SpecBlock 出 q2；二者都用 q2 选下一拍的比较常数。
  //    （specB 的 q_j 输入接的是它自己的 q_j_2 输出——不成环：块内 q_j 只影响
  //    nxt_spec，而 q_j_2 只由 q_j_1 与 pre_spec 决定。golden 同此接法。）
  // ---------------------------------------------------------------------------
  // BEGIN GENERATED(iterblock-selB)
  SelBlock_v4 u_sel (
    .io_q_j         (q2_oh),
    .io_q_j_1       (q1_oh),
    .io_cons_0_0    (Sel_cons[0][0]),
    .io_cons_0_1    (Sel_cons[0][1]),
    .io_cons_0_2    (Sel_cons[0][2]),
    .io_cons_0_3    (Sel_cons[0][3]),
    .io_cons_1_0    (Sel_cons[1][0]),
    .io_cons_1_1    (Sel_cons[1][1]),
    .io_cons_1_2    (Sel_cons[1][2]),
    .io_cons_1_3    (Sel_cons[1][3]),
    .io_cons_2_0    (Sel_cons[2][0]),
    .io_cons_2_1    (Sel_cons[2][1]),
    .io_cons_2_2    (Sel_cons[2][2]),
    .io_cons_2_3    (Sel_cons[2][3]),
    .io_cons_3_0    (Sel_cons[3][0]),
    .io_cons_3_1    (Sel_cons[3][1]),
    .io_cons_3_2    (Sel_cons[3][2]),
    .io_cons_3_3    (Sel_cons[3][3]),
    .io_cons_4_0    (Sel_cons[4][0]),
    .io_cons_4_1    (Sel_cons[4][1]),
    .io_cons_4_2    (Sel_cons[4][2]),
    .io_cons_4_3    (Sel_cons[4][3]),
    .io_rem_3_5_0   (sel_rem[0]),
    .io_rem_3_5_1   (sel_rem[1]),
    .io_pre_sel_0_0 (pre_sel[0][0]),
    .io_pre_sel_0_1 (pre_sel[0][1]),
    .io_pre_sel_1_0 (pre_sel[1][0]),
    .io_pre_sel_1_1 (pre_sel[1][1]),
    .io_pre_sel_2_0 (pre_sel[2][0]),
    .io_pre_sel_2_1 (pre_sel[2][1]),
    .io_pre_sel_3_0 (pre_sel[3][0]),
    .io_pre_sel_3_1 (pre_sel[3][1]),
    .io_nxt_sel_0_0 (nxt_sel[0][0]),
    .io_nxt_sel_0_1 (nxt_sel[0][1]),
    .io_nxt_sel_1_0 (nxt_sel[1][0]),
    .io_nxt_sel_1_1 (nxt_sel[1][1]),
    .io_nxt_sel_2_0 (nxt_sel[2][0]),
    .io_nxt_sel_2_1 (nxt_sel[2][1]),
    .io_nxt_sel_3_0 (nxt_sel[3][0]),
    .io_nxt_sel_3_1 (nxt_sel[3][1])
  );
  // END GENERATED

  // BEGIN GENERATED(iterblock-specB)
  SpecBlock_v4 u_spec (
    .io_q_j            (q2_oh),
    .io_cons_0_0       (Spec_cons[0][0]),
    .io_cons_0_1       (Spec_cons[0][1]),
    .io_cons_0_2       (Spec_cons[0][2]),
    .io_cons_0_3       (Spec_cons[0][3]),
    .io_cons_1_0       (Spec_cons[1][0]),
    .io_cons_1_1       (Spec_cons[1][1]),
    .io_cons_1_2       (Spec_cons[1][2]),
    .io_cons_1_3       (Spec_cons[1][3]),
    .io_cons_2_0       (Spec_cons[2][0]),
    .io_cons_2_1       (Spec_cons[2][1]),
    .io_cons_2_2       (Spec_cons[2][2]),
    .io_cons_2_3       (Spec_cons[2][3]),
    .io_cons_3_0       (Spec_cons[3][0]),
    .io_cons_3_1       (Spec_cons[3][1]),
    .io_cons_3_2       (Spec_cons[3][2]),
    .io_cons_3_3       (Spec_cons[3][3]),
    .io_cons_4_0       (Spec_cons[4][0]),
    .io_cons_4_1       (Spec_cons[4][1]),
    .io_cons_4_2       (Spec_cons[4][2]),
    .io_cons_4_3       (Spec_cons[4][3]),
    .io_d_trunc_0      (d_trunc[0]),
    .io_d_trunc_1      (d_trunc[1]),
    .io_d_trunc_2      (d_trunc[2]),
    .io_d_trunc_3      (d_trunc[3]),
    .io_q_j_1          (q1_oh),
    .io_rem_3_5_0      (spec_rem[0]),
    .io_rem_3_5_1      (spec_rem[1]),
    .io_q_j_2          (q2_oh),
    .io_pre_spec_0_0_0 (pre_spec[0][0][0]),
    .io_pre_spec_0_0_1 (pre_spec[0][0][1]),
    .io_pre_spec_0_1_0 (pre_spec[0][1][0]),
    .io_pre_spec_0_1_1 (pre_spec[0][1][1]),
    .io_pre_spec_0_2_0 (pre_spec[0][2][0]),
    .io_pre_spec_0_2_1 (pre_spec[0][2][1]),
    .io_pre_spec_0_3_0 (pre_spec[0][3][0]),
    .io_pre_spec_0_3_1 (pre_spec[0][3][1]),
    .io_pre_spec_1_0_0 (pre_spec[1][0][0]),
    .io_pre_spec_1_0_1 (pre_spec[1][0][1]),
    .io_pre_spec_1_1_0 (pre_spec[1][1][0]),
    .io_pre_spec_1_1_1 (pre_spec[1][1][1]),
    .io_pre_spec_1_2_0 (pre_spec[1][2][0]),
    .io_pre_spec_1_2_1 (pre_spec[1][2][1]),
    .io_pre_spec_1_3_0 (pre_spec[1][3][0]),
    .io_pre_spec_1_3_1 (pre_spec[1][3][1]),
    .io_pre_spec_2_0_0 (pre_spec[2][0][0]),
    .io_pre_spec_2_0_1 (pre_spec[2][0][1]),
    .io_pre_spec_2_1_0 (pre_spec[2][1][0]),
    .io_pre_spec_2_1_1 (pre_spec[2][1][1]),
    .io_pre_spec_2_2_0 (pre_spec[2][2][0]),
    .io_pre_spec_2_2_1 (pre_spec[2][2][1]),
    .io_pre_spec_2_3_0 (pre_spec[2][3][0]),
    .io_pre_spec_2_3_1 (pre_spec[2][3][1]),
    .io_pre_spec_3_0_0 (pre_spec[3][0][0]),
    .io_pre_spec_3_0_1 (pre_spec[3][0][1]),
    .io_pre_spec_3_1_0 (pre_spec[3][1][0]),
    .io_pre_spec_3_1_1 (pre_spec[3][1][1]),
    .io_pre_spec_3_2_0 (pre_spec[3][2][0]),
    .io_pre_spec_3_2_1 (pre_spec[3][2][1]),
    .io_pre_spec_3_3_0 (pre_spec[3][3][0]),
    .io_pre_spec_3_3_1 (pre_spec[3][3][1]),
    .io_pre_spec_4_0_0 (pre_spec[4][0][0]),
    .io_pre_spec_4_0_1 (pre_spec[4][0][1]),
    .io_pre_spec_4_1_0 (pre_spec[4][1][0]),
    .io_pre_spec_4_1_1 (pre_spec[4][1][1]),
    .io_pre_spec_4_2_0 (pre_spec[4][2][0]),
    .io_pre_spec_4_2_1 (pre_spec[4][2][1]),
    .io_pre_spec_4_3_0 (pre_spec[4][3][0]),
    .io_pre_spec_4_3_1 (pre_spec[4][3][1]),
    .io_nxt_spec_0_0_0 (nxt_spec[0][0][0]),
    .io_nxt_spec_0_0_1 (nxt_spec[0][0][1]),
    .io_nxt_spec_0_1_0 (nxt_spec[0][1][0]),
    .io_nxt_spec_0_1_1 (nxt_spec[0][1][1]),
    .io_nxt_spec_0_2_0 (nxt_spec[0][2][0]),
    .io_nxt_spec_0_2_1 (nxt_spec[0][2][1]),
    .io_nxt_spec_0_3_0 (nxt_spec[0][3][0]),
    .io_nxt_spec_0_3_1 (nxt_spec[0][3][1]),
    .io_nxt_spec_1_0_0 (nxt_spec[1][0][0]),
    .io_nxt_spec_1_0_1 (nxt_spec[1][0][1]),
    .io_nxt_spec_1_1_0 (nxt_spec[1][1][0]),
    .io_nxt_spec_1_1_1 (nxt_spec[1][1][1]),
    .io_nxt_spec_1_2_0 (nxt_spec[1][2][0]),
    .io_nxt_spec_1_2_1 (nxt_spec[1][2][1]),
    .io_nxt_spec_1_3_0 (nxt_spec[1][3][0]),
    .io_nxt_spec_1_3_1 (nxt_spec[1][3][1]),
    .io_nxt_spec_2_0_0 (nxt_spec[2][0][0]),
    .io_nxt_spec_2_0_1 (nxt_spec[2][0][1]),
    .io_nxt_spec_2_1_0 (nxt_spec[2][1][0]),
    .io_nxt_spec_2_1_1 (nxt_spec[2][1][1]),
    .io_nxt_spec_2_2_0 (nxt_spec[2][2][0]),
    .io_nxt_spec_2_2_1 (nxt_spec[2][2][1]),
    .io_nxt_spec_2_3_0 (nxt_spec[2][3][0]),
    .io_nxt_spec_2_3_1 (nxt_spec[2][3][1]),
    .io_nxt_spec_3_0_0 (nxt_spec[3][0][0]),
    .io_nxt_spec_3_0_1 (nxt_spec[3][0][1]),
    .io_nxt_spec_3_1_0 (nxt_spec[3][1][0]),
    .io_nxt_spec_3_1_1 (nxt_spec[3][1][1]),
    .io_nxt_spec_3_2_0 (nxt_spec[3][2][0]),
    .io_nxt_spec_3_2_1 (nxt_spec[3][2][1]),
    .io_nxt_spec_3_3_0 (nxt_spec[3][3][0]),
    .io_nxt_spec_3_3_1 (nxt_spec[3][3][1]),
    .io_nxt_spec_4_0_0 (nxt_spec[4][0][0]),
    .io_nxt_spec_4_0_1 (nxt_spec[4][0][1]),
    .io_nxt_spec_4_1_0 (nxt_spec[4][1][0]),
    .io_nxt_spec_4_1_1 (nxt_spec[4][1][1]),
    .io_nxt_spec_4_2_0 (nxt_spec[4][2][0]),
    .io_nxt_spec_4_2_1 (nxt_spec[4][2][1]),
    .io_nxt_spec_4_3_0 (nxt_spec[4][3][0]),
    .io_nxt_spec_4_3_1 (nxt_spec[4][3][1])
  );
  // END GENERATED
endmodule

// BEGIN GENERATED(iterblock-wrapper)
// -----------------------------------------------------------------------------
// IterBlock_v4 —— golden 同名 wrapper：端口表逐字取 golden，展平端口 <-> 核数组（机械生成）
// -----------------------------------------------------------------------------
module IterBlock_v4(
  input  [7:0]  io_Sel_cons_0_0,
  input  [7:0]  io_Sel_cons_0_1,
  input  [7:0]  io_Sel_cons_0_2,
  input  [7:0]  io_Sel_cons_0_3,
  input  [7:0]  io_Sel_cons_1_0,
  input  [7:0]  io_Sel_cons_1_1,
  input  [7:0]  io_Sel_cons_1_2,
  input  [7:0]  io_Sel_cons_1_3,
  input  [7:0]  io_Sel_cons_2_0,
  input  [7:0]  io_Sel_cons_2_1,
  input  [7:0]  io_Sel_cons_2_2,
  input  [7:0]  io_Sel_cons_2_3,
  input  [7:0]  io_Sel_cons_3_0,
  input  [7:0]  io_Sel_cons_3_1,
  input  [7:0]  io_Sel_cons_3_2,
  input  [7:0]  io_Sel_cons_3_3,
  input  [7:0]  io_Sel_cons_4_0,
  input  [7:0]  io_Sel_cons_4_1,
  input  [7:0]  io_Sel_cons_4_2,
  input  [7:0]  io_Sel_cons_4_3,
  input  [8:0]  io_Spec_cons_0_0,
  input  [8:0]  io_Spec_cons_0_1,
  input  [8:0]  io_Spec_cons_0_2,
  input  [8:0]  io_Spec_cons_0_3,
  input  [8:0]  io_Spec_cons_1_0,
  input  [8:0]  io_Spec_cons_1_1,
  input  [8:0]  io_Spec_cons_1_2,
  input  [8:0]  io_Spec_cons_1_3,
  input  [8:0]  io_Spec_cons_2_0,
  input  [8:0]  io_Spec_cons_2_1,
  input  [8:0]  io_Spec_cons_2_2,
  input  [8:0]  io_Spec_cons_2_3,
  input  [8:0]  io_Spec_cons_3_0,
  input  [8:0]  io_Spec_cons_3_1,
  input  [8:0]  io_Spec_cons_3_2,
  input  [8:0]  io_Spec_cons_3_3,
  input  [8:0]  io_Spec_cons_4_0,
  input  [8:0]  io_Spec_cons_4_1,
  input  [8:0]  io_Spec_cons_4_2,
  input  [8:0]  io_Spec_cons_4_3,
  input  [21:0] io_iter_cons_0,
  input  [21:0] io_iter_cons_1,
  input  [21:0] io_iter_cons_3,
  input  [21:0] io_iter_cons_4,
  input  [8:0]  io_d_trunc_0,
  input  [8:0]  io_d_trunc_1,
  input  [8:0]  io_d_trunc_2,
  input  [8:0]  io_d_trunc_3,
  input  [10:0] io_spec_r2ud_0,
  input  [10:0] io_spec_r2ud_1,
  input  [10:0] io_spec_r2ud_3,
  input  [10:0] io_spec_r2ud_4,
  input  [15:0] io_pre_q_A,
  input  [15:0] io_pre_q_B,
  output [15:0] io_nxt_q_A,
  output [15:0] io_nxt_q_B,
  input  [7:0]  io_pre_sel_0_0,
  input  [7:0]  io_pre_sel_0_1,
  input  [7:0]  io_pre_sel_1_0,
  input  [7:0]  io_pre_sel_1_1,
  input  [7:0]  io_pre_sel_2_0,
  input  [7:0]  io_pre_sel_2_1,
  input  [7:0]  io_pre_sel_3_0,
  input  [7:0]  io_pre_sel_3_1,
  output [7:0]  io_nxt_sel_0_0,
  output [7:0]  io_nxt_sel_0_1,
  output [7:0]  io_nxt_sel_1_0,
  output [7:0]  io_nxt_sel_1_1,
  output [7:0]  io_nxt_sel_2_0,
  output [7:0]  io_nxt_sel_2_1,
  output [7:0]  io_nxt_sel_3_0,
  output [7:0]  io_nxt_sel_3_1,
  input  [8:0]  io_pre_spec_0_0_0,
  input  [8:0]  io_pre_spec_0_0_1,
  input  [8:0]  io_pre_spec_0_1_0,
  input  [8:0]  io_pre_spec_0_1_1,
  input  [8:0]  io_pre_spec_0_2_0,
  input  [8:0]  io_pre_spec_0_2_1,
  input  [8:0]  io_pre_spec_0_3_0,
  input  [8:0]  io_pre_spec_0_3_1,
  input  [8:0]  io_pre_spec_1_0_0,
  input  [8:0]  io_pre_spec_1_0_1,
  input  [8:0]  io_pre_spec_1_1_0,
  input  [8:0]  io_pre_spec_1_1_1,
  input  [8:0]  io_pre_spec_1_2_0,
  input  [8:0]  io_pre_spec_1_2_1,
  input  [8:0]  io_pre_spec_1_3_0,
  input  [8:0]  io_pre_spec_1_3_1,
  input  [8:0]  io_pre_spec_2_0_0,
  input  [8:0]  io_pre_spec_2_0_1,
  input  [8:0]  io_pre_spec_2_1_0,
  input  [8:0]  io_pre_spec_2_1_1,
  input  [8:0]  io_pre_spec_2_2_0,
  input  [8:0]  io_pre_spec_2_2_1,
  input  [8:0]  io_pre_spec_2_3_0,
  input  [8:0]  io_pre_spec_2_3_1,
  input  [8:0]  io_pre_spec_3_0_0,
  input  [8:0]  io_pre_spec_3_0_1,
  input  [8:0]  io_pre_spec_3_1_0,
  input  [8:0]  io_pre_spec_3_1_1,
  input  [8:0]  io_pre_spec_3_2_0,
  input  [8:0]  io_pre_spec_3_2_1,
  input  [8:0]  io_pre_spec_3_3_0,
  input  [8:0]  io_pre_spec_3_3_1,
  input  [8:0]  io_pre_spec_4_0_0,
  input  [8:0]  io_pre_spec_4_0_1,
  input  [8:0]  io_pre_spec_4_1_0,
  input  [8:0]  io_pre_spec_4_1_1,
  input  [8:0]  io_pre_spec_4_2_0,
  input  [8:0]  io_pre_spec_4_2_1,
  input  [8:0]  io_pre_spec_4_3_0,
  input  [8:0]  io_pre_spec_4_3_1,
  output [8:0]  io_nxt_spec_0_0_0,
  output [8:0]  io_nxt_spec_0_0_1,
  output [8:0]  io_nxt_spec_0_1_0,
  output [8:0]  io_nxt_spec_0_1_1,
  output [8:0]  io_nxt_spec_0_2_0,
  output [8:0]  io_nxt_spec_0_2_1,
  output [8:0]  io_nxt_spec_0_3_0,
  output [8:0]  io_nxt_spec_0_3_1,
  output [8:0]  io_nxt_spec_1_0_0,
  output [8:0]  io_nxt_spec_1_0_1,
  output [8:0]  io_nxt_spec_1_1_0,
  output [8:0]  io_nxt_spec_1_1_1,
  output [8:0]  io_nxt_spec_1_2_0,
  output [8:0]  io_nxt_spec_1_2_1,
  output [8:0]  io_nxt_spec_1_3_0,
  output [8:0]  io_nxt_spec_1_3_1,
  output [8:0]  io_nxt_spec_2_0_0,
  output [8:0]  io_nxt_spec_2_0_1,
  output [8:0]  io_nxt_spec_2_1_0,
  output [8:0]  io_nxt_spec_2_1_1,
  output [8:0]  io_nxt_spec_2_2_0,
  output [8:0]  io_nxt_spec_2_2_1,
  output [8:0]  io_nxt_spec_2_3_0,
  output [8:0]  io_nxt_spec_2_3_1,
  output [8:0]  io_nxt_spec_3_0_0,
  output [8:0]  io_nxt_spec_3_0_1,
  output [8:0]  io_nxt_spec_3_1_0,
  output [8:0]  io_nxt_spec_3_1_1,
  output [8:0]  io_nxt_spec_3_2_0,
  output [8:0]  io_nxt_spec_3_2_1,
  output [8:0]  io_nxt_spec_3_3_0,
  output [8:0]  io_nxt_spec_3_3_1,
  output [8:0]  io_nxt_spec_4_0_0,
  output [8:0]  io_nxt_spec_4_0_1,
  output [8:0]  io_nxt_spec_4_1_0,
  output [8:0]  io_nxt_spec_4_1_1,
  output [8:0]  io_nxt_spec_4_2_0,
  output [8:0]  io_nxt_spec_4_2_1,
  output [8:0]  io_nxt_spec_4_3_0,
  output [8:0]  io_nxt_spec_4_3_1,
  input  [21:0] io_pre_iterB_0,
  input  [21:0] io_pre_iterB_1,
  output [21:0] io_nxt_iterB_0,
  output [21:0] io_nxt_iterB_1
);

  // 展平端口 <-> 核的数组（Scala Vec）
  logic [7:0] Sel_cons [0:4] [0:3];
  logic [8:0] Spec_cons [0:4] [0:3];
  logic [21:0] iter_cons [0:4];
  logic [8:0] d_trunc [0:3];
  logic [10:0] spec_r2ud [0:4];
  logic [7:0] pre_sel [0:3] [0:1];
  logic [7:0] nxt_sel [0:3] [0:1];
  logic [8:0] pre_spec [0:4] [0:3] [0:1];
  logic [8:0] nxt_spec [0:4] [0:3] [0:1];
  logic [21:0] pre_iterB [0:1];
  logic [21:0] nxt_iterB [0:1];

  assign Sel_cons[0][0] = io_Sel_cons_0_0;
  assign Sel_cons[0][1] = io_Sel_cons_0_1;
  assign Sel_cons[0][2] = io_Sel_cons_0_2;
  assign Sel_cons[0][3] = io_Sel_cons_0_3;
  assign Sel_cons[1][0] = io_Sel_cons_1_0;
  assign Sel_cons[1][1] = io_Sel_cons_1_1;
  assign Sel_cons[1][2] = io_Sel_cons_1_2;
  assign Sel_cons[1][3] = io_Sel_cons_1_3;
  assign Sel_cons[2][0] = io_Sel_cons_2_0;
  assign Sel_cons[2][1] = io_Sel_cons_2_1;
  assign Sel_cons[2][2] = io_Sel_cons_2_2;
  assign Sel_cons[2][3] = io_Sel_cons_2_3;
  assign Sel_cons[3][0] = io_Sel_cons_3_0;
  assign Sel_cons[3][1] = io_Sel_cons_3_1;
  assign Sel_cons[3][2] = io_Sel_cons_3_2;
  assign Sel_cons[3][3] = io_Sel_cons_3_3;
  assign Sel_cons[4][0] = io_Sel_cons_4_0;
  assign Sel_cons[4][1] = io_Sel_cons_4_1;
  assign Sel_cons[4][2] = io_Sel_cons_4_2;
  assign Sel_cons[4][3] = io_Sel_cons_4_3;
  assign Spec_cons[0][0] = io_Spec_cons_0_0;
  assign Spec_cons[0][1] = io_Spec_cons_0_1;
  assign Spec_cons[0][2] = io_Spec_cons_0_2;
  assign Spec_cons[0][3] = io_Spec_cons_0_3;
  assign Spec_cons[1][0] = io_Spec_cons_1_0;
  assign Spec_cons[1][1] = io_Spec_cons_1_1;
  assign Spec_cons[1][2] = io_Spec_cons_1_2;
  assign Spec_cons[1][3] = io_Spec_cons_1_3;
  assign Spec_cons[2][0] = io_Spec_cons_2_0;
  assign Spec_cons[2][1] = io_Spec_cons_2_1;
  assign Spec_cons[2][2] = io_Spec_cons_2_2;
  assign Spec_cons[2][3] = io_Spec_cons_2_3;
  assign Spec_cons[3][0] = io_Spec_cons_3_0;
  assign Spec_cons[3][1] = io_Spec_cons_3_1;
  assign Spec_cons[3][2] = io_Spec_cons_3_2;
  assign Spec_cons[3][3] = io_Spec_cons_3_3;
  assign Spec_cons[4][0] = io_Spec_cons_4_0;
  assign Spec_cons[4][1] = io_Spec_cons_4_1;
  assign Spec_cons[4][2] = io_Spec_cons_4_2;
  assign Spec_cons[4][3] = io_Spec_cons_4_3;
  assign iter_cons[0] = io_iter_cons_0;
  assign iter_cons[1] = io_iter_cons_1;
  assign iter_cons[3] = io_iter_cons_3;
  assign iter_cons[4] = io_iter_cons_4;
  assign d_trunc[0] = io_d_trunc_0;
  assign d_trunc[1] = io_d_trunc_1;
  assign d_trunc[2] = io_d_trunc_2;
  assign d_trunc[3] = io_d_trunc_3;
  assign spec_r2ud[0] = io_spec_r2ud_0;
  assign spec_r2ud[1] = io_spec_r2ud_1;
  assign spec_r2ud[3] = io_spec_r2ud_3;
  assign spec_r2ud[4] = io_spec_r2ud_4;
  assign pre_sel[0][0] = io_pre_sel_0_0;
  assign pre_sel[0][1] = io_pre_sel_0_1;
  assign pre_sel[1][0] = io_pre_sel_1_0;
  assign pre_sel[1][1] = io_pre_sel_1_1;
  assign pre_sel[2][0] = io_pre_sel_2_0;
  assign pre_sel[2][1] = io_pre_sel_2_1;
  assign pre_sel[3][0] = io_pre_sel_3_0;
  assign pre_sel[3][1] = io_pre_sel_3_1;
  assign pre_spec[0][0][0] = io_pre_spec_0_0_0;
  assign pre_spec[0][0][1] = io_pre_spec_0_0_1;
  assign pre_spec[0][1][0] = io_pre_spec_0_1_0;
  assign pre_spec[0][1][1] = io_pre_spec_0_1_1;
  assign pre_spec[0][2][0] = io_pre_spec_0_2_0;
  assign pre_spec[0][2][1] = io_pre_spec_0_2_1;
  assign pre_spec[0][3][0] = io_pre_spec_0_3_0;
  assign pre_spec[0][3][1] = io_pre_spec_0_3_1;
  assign pre_spec[1][0][0] = io_pre_spec_1_0_0;
  assign pre_spec[1][0][1] = io_pre_spec_1_0_1;
  assign pre_spec[1][1][0] = io_pre_spec_1_1_0;
  assign pre_spec[1][1][1] = io_pre_spec_1_1_1;
  assign pre_spec[1][2][0] = io_pre_spec_1_2_0;
  assign pre_spec[1][2][1] = io_pre_spec_1_2_1;
  assign pre_spec[1][3][0] = io_pre_spec_1_3_0;
  assign pre_spec[1][3][1] = io_pre_spec_1_3_1;
  assign pre_spec[2][0][0] = io_pre_spec_2_0_0;
  assign pre_spec[2][0][1] = io_pre_spec_2_0_1;
  assign pre_spec[2][1][0] = io_pre_spec_2_1_0;
  assign pre_spec[2][1][1] = io_pre_spec_2_1_1;
  assign pre_spec[2][2][0] = io_pre_spec_2_2_0;
  assign pre_spec[2][2][1] = io_pre_spec_2_2_1;
  assign pre_spec[2][3][0] = io_pre_spec_2_3_0;
  assign pre_spec[2][3][1] = io_pre_spec_2_3_1;
  assign pre_spec[3][0][0] = io_pre_spec_3_0_0;
  assign pre_spec[3][0][1] = io_pre_spec_3_0_1;
  assign pre_spec[3][1][0] = io_pre_spec_3_1_0;
  assign pre_spec[3][1][1] = io_pre_spec_3_1_1;
  assign pre_spec[3][2][0] = io_pre_spec_3_2_0;
  assign pre_spec[3][2][1] = io_pre_spec_3_2_1;
  assign pre_spec[3][3][0] = io_pre_spec_3_3_0;
  assign pre_spec[3][3][1] = io_pre_spec_3_3_1;
  assign pre_spec[4][0][0] = io_pre_spec_4_0_0;
  assign pre_spec[4][0][1] = io_pre_spec_4_0_1;
  assign pre_spec[4][1][0] = io_pre_spec_4_1_0;
  assign pre_spec[4][1][1] = io_pre_spec_4_1_1;
  assign pre_spec[4][2][0] = io_pre_spec_4_2_0;
  assign pre_spec[4][2][1] = io_pre_spec_4_2_1;
  assign pre_spec[4][3][0] = io_pre_spec_4_3_0;
  assign pre_spec[4][3][1] = io_pre_spec_4_3_1;
  assign pre_iterB[0] = io_pre_iterB_0;
  assign pre_iterB[1] = io_pre_iterB_1;
  assign iter_cons[2] = '0;   // golden 无此端口：父级恒连 0（q=0 时 −0·d）
  assign spec_r2ud[2] = '0;   // golden 无此端口：父级恒连 0（q=0 时 −0·d）

  xs_IterBlock_v4_core #(.BIT_WIDTH(16)) u_core (
    .Sel_cons  (Sel_cons),
    .Spec_cons (Spec_cons),
    .iter_cons (iter_cons),
    .d_trunc   (d_trunc),
    .spec_r2ud (spec_r2ud),
    .pre_q_A   (io_pre_q_A),
    .pre_q_B   (io_pre_q_B),
    .nxt_q_A   (io_nxt_q_A),
    .nxt_q_B   (io_nxt_q_B),
    .pre_sel   (pre_sel),
    .nxt_sel   (nxt_sel),
    .pre_spec  (pre_spec),
    .nxt_spec  (nxt_spec),
    .pre_iterB (pre_iterB),
    .nxt_iterB (nxt_iterB)
  );

  assign io_nxt_sel_0_0 = nxt_sel[0][0];
  assign io_nxt_sel_0_1 = nxt_sel[0][1];
  assign io_nxt_sel_1_0 = nxt_sel[1][0];
  assign io_nxt_sel_1_1 = nxt_sel[1][1];
  assign io_nxt_sel_2_0 = nxt_sel[2][0];
  assign io_nxt_sel_2_1 = nxt_sel[2][1];
  assign io_nxt_sel_3_0 = nxt_sel[3][0];
  assign io_nxt_sel_3_1 = nxt_sel[3][1];
  assign io_nxt_spec_0_0_0 = nxt_spec[0][0][0];
  assign io_nxt_spec_0_0_1 = nxt_spec[0][0][1];
  assign io_nxt_spec_0_1_0 = nxt_spec[0][1][0];
  assign io_nxt_spec_0_1_1 = nxt_spec[0][1][1];
  assign io_nxt_spec_0_2_0 = nxt_spec[0][2][0];
  assign io_nxt_spec_0_2_1 = nxt_spec[0][2][1];
  assign io_nxt_spec_0_3_0 = nxt_spec[0][3][0];
  assign io_nxt_spec_0_3_1 = nxt_spec[0][3][1];
  assign io_nxt_spec_1_0_0 = nxt_spec[1][0][0];
  assign io_nxt_spec_1_0_1 = nxt_spec[1][0][1];
  assign io_nxt_spec_1_1_0 = nxt_spec[1][1][0];
  assign io_nxt_spec_1_1_1 = nxt_spec[1][1][1];
  assign io_nxt_spec_1_2_0 = nxt_spec[1][2][0];
  assign io_nxt_spec_1_2_1 = nxt_spec[1][2][1];
  assign io_nxt_spec_1_3_0 = nxt_spec[1][3][0];
  assign io_nxt_spec_1_3_1 = nxt_spec[1][3][1];
  assign io_nxt_spec_2_0_0 = nxt_spec[2][0][0];
  assign io_nxt_spec_2_0_1 = nxt_spec[2][0][1];
  assign io_nxt_spec_2_1_0 = nxt_spec[2][1][0];
  assign io_nxt_spec_2_1_1 = nxt_spec[2][1][1];
  assign io_nxt_spec_2_2_0 = nxt_spec[2][2][0];
  assign io_nxt_spec_2_2_1 = nxt_spec[2][2][1];
  assign io_nxt_spec_2_3_0 = nxt_spec[2][3][0];
  assign io_nxt_spec_2_3_1 = nxt_spec[2][3][1];
  assign io_nxt_spec_3_0_0 = nxt_spec[3][0][0];
  assign io_nxt_spec_3_0_1 = nxt_spec[3][0][1];
  assign io_nxt_spec_3_1_0 = nxt_spec[3][1][0];
  assign io_nxt_spec_3_1_1 = nxt_spec[3][1][1];
  assign io_nxt_spec_3_2_0 = nxt_spec[3][2][0];
  assign io_nxt_spec_3_2_1 = nxt_spec[3][2][1];
  assign io_nxt_spec_3_3_0 = nxt_spec[3][3][0];
  assign io_nxt_spec_3_3_1 = nxt_spec[3][3][1];
  assign io_nxt_spec_4_0_0 = nxt_spec[4][0][0];
  assign io_nxt_spec_4_0_1 = nxt_spec[4][0][1];
  assign io_nxt_spec_4_1_0 = nxt_spec[4][1][0];
  assign io_nxt_spec_4_1_1 = nxt_spec[4][1][1];
  assign io_nxt_spec_4_2_0 = nxt_spec[4][2][0];
  assign io_nxt_spec_4_2_1 = nxt_spec[4][2][1];
  assign io_nxt_spec_4_3_0 = nxt_spec[4][3][0];
  assign io_nxt_spec_4_3_1 = nxt_spec[4][3][1];
  assign io_nxt_iterB_0 = nxt_iterB[0];
  assign io_nxt_iterB_1 = nxt_iterB[1];
endmodule
// END GENERATED
