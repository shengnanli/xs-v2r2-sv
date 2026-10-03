// =============================================================================
// IterBlock_v4_4.sv —— SRT radix-16 整数除法的一拍迭代，**本变体 BIT_WIDTH=32**
//
// 在哪一层：VectorIdiv → SRT16Divint_4（32 位整数除法，sew 可取 00..10）→ 本块。
// 本变体规模：余数 carry-save 向量宽 W=38（= BIT_WIDTH + 6），商 A/B 各 32 位；
//   子模块 CSA3_2_4111（38 位 3:2 CSA）×2、CSA3_2_4017 ×1、Conversion_8 ×2、
//   SelBlock_v4 ×1、SpecBlock_v4 ×1，全部为本仓已签核重写件。纯组合。
// 与 IterBlock_v4（16 位）只差位宽与子模块编号；SRT 原理、商位编码、位宽推导与
//   参数化核 xs_IterBlock_v4_core 都在 rtl/backend/IterBlock_v4.sv，核体不复制。
// golden 无 io_iter_cons_2 / io_spec_r2ud_2（父级恒连 0），wrapper 在该下标接 0。
//
// 本文件由 scripts/gen_srt_divblocks.py 生成，勿手改。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class IterBlock_v4)
// golden 对照：G1-canonical/golden-rtl/IterBlock_v4_4.sv
// =============================================================================

module IterBlock_v4_4(
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
  input  [37:0] io_iter_cons_0,
  input  [37:0] io_iter_cons_1,
  input  [37:0] io_iter_cons_3,
  input  [37:0] io_iter_cons_4,
  input  [8:0]  io_d_trunc_0,
  input  [8:0]  io_d_trunc_1,
  input  [8:0]  io_d_trunc_2,
  input  [8:0]  io_d_trunc_3,
  input  [10:0] io_spec_r2ud_0,
  input  [10:0] io_spec_r2ud_1,
  input  [10:0] io_spec_r2ud_3,
  input  [10:0] io_spec_r2ud_4,
  input  [31:0] io_pre_q_A,
  input  [31:0] io_pre_q_B,
  output [31:0] io_nxt_q_A,
  output [31:0] io_nxt_q_B,
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
  input  [37:0] io_pre_iterB_0,
  input  [37:0] io_pre_iterB_1,
  output [37:0] io_nxt_iterB_0,
  output [37:0] io_nxt_iterB_1
);

  // 展平端口 <-> 核的数组（Scala Vec）
  logic [7:0] Sel_cons [0:4] [0:3];
  logic [8:0] Spec_cons [0:4] [0:3];
  logic [37:0] iter_cons [0:4];
  logic [8:0] d_trunc [0:3];
  logic [10:0] spec_r2ud [0:4];
  logic [7:0] pre_sel [0:3] [0:1];
  logic [7:0] nxt_sel [0:3] [0:1];
  logic [8:0] pre_spec [0:4] [0:3] [0:1];
  logic [8:0] nxt_spec [0:4] [0:3] [0:1];
  logic [37:0] pre_iterB [0:1];
  logic [37:0] nxt_iterB [0:1];

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

  xs_IterBlock_v4_core #(.BIT_WIDTH(32)) u_core (
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
