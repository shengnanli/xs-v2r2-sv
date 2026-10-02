// =============================================================================
// r4_qds_cg —— QDS 比较常数生成器（fpsqrt_r16{,_block}、fpsqrt_vector_r16 使用）
//
// 输入除数高位片段 {a0_i, a2_i, a3_i, a4_i}，查表产出四档 7 位比较常数
//   m_neg_1/m_neg_0/m_pos_1/m_pos_2（二进制补码；pos_* 为负值，注释给有符号
//   十进制）。这些常数就是 r4_qds 的 m_*_i 输入。
// 行为（现读 golden 原文逐项核过）：a0_i=1 时四档输出与 {a2,a3,a4}=7 那一行
//   逐项相同，即 a0 只是折叠进表索引的最高档，没有独立表项。
// 结构：golden 端口 -> xs_r4_qds_cg_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_r4_qds_cg_core (
  input  logic       divisor_a0,
  input  logic [2:0] divisor_top3,
  output logic [6:0] cmp_neg_1,
  output logic [6:0] cmp_neg_0,
  output logic [6:0] cmp_pos_1,
  output logic [6:0] cmp_pos_2
);
  // 查表行号：a0=1 与 idx=7 同档（见文件头）
  logic [2:0] row;
  assign row = divisor_a0 ? 3'd7 : divisor_top3;

  // 四张 8 行 LUT，按下标 0..7 书写；右侧注释是有符号十进制读法
  localparam logic [6:0] LUT_NEG_1 [0:7] =
    '{7'h0D, 7'h0E, 7'h10, 7'h11, 7'h12, 7'h14, 7'h16, 7'h17};  // +13,+14,+16,+17,+18,+20,+22,+23
  localparam logic [6:0] LUT_NEG_0 [0:7] =
    '{7'h04, 7'h05, 7'h06, 7'h06, 7'h06, 7'h08, 7'h08, 7'h08};  // +4,+5,+6,+6,+6,+8,+8,+8
  localparam logic [6:0] LUT_POS_1 [0:7] =
    '{7'h7C, 7'h7C, 7'h7C, 7'h7C, 7'h7A, 7'h7A, 7'h78, 7'h78};  // -4,-4,-4,-4,-6,-6,-8,-8
  localparam logic [6:0] LUT_POS_2 [0:7] =
    '{7'h74, 7'h72, 7'h70, 7'h70, 7'h6E, 7'h6C, 7'h6C, 7'h6A};  // -12,-14,-16,-16,-18,-20,-20,-22

  assign cmp_neg_1 = LUT_NEG_1[row];
  assign cmp_neg_0 = LUT_NEG_0[row];
  assign cmp_pos_1 = LUT_POS_1[row];
  assign cmp_pos_2 = LUT_POS_2[row];
endmodule

module r4_qds_cg (
  input  logic       a0_i,
  input  logic       a2_i,
  input  logic       a3_i,
  input  logic       a4_i,
  output logic [6:0] m_neg_1_o,
  output logic [6:0] m_neg_0_o,
  output logic [6:0] m_pos_1_o,
  output logic [6:0] m_pos_2_o
);
  xs_r4_qds_cg_core u_core (
    .divisor_a0   (a0_i),
    .divisor_top3 ({a2_i, a3_i, a4_i}),
    .cmp_neg_1    (m_neg_1_o),
    .cmp_neg_0    (m_neg_0_o),
    .cmp_pos_1    (m_pos_1_o),
    .cmp_pos_2    (m_pos_2_o)
  );
endmodule
