// =============================================================================
// r4_qds —— radix-4 SRT 除法/开方的商数位选择（QDS）表（fpsqrt_r16_block 使用）
//
// 输入：部分余数高位 rem_i（7 位）与四档比较常数 m_neg_1/m_neg_0/m_pos_1/m_pos_2
//   （±d 阈值常数的 7 位截断，由 r4_qds_cg 这类模块按除数高位生成）。
// 机制：四个 7 位回绕加法 rem + m（golden 的 7'(a+b)，只留和低 7 位），各取
//   符号位，按选择表译出本拍商数位 q ∈ {-2,-1,0,+1,+2}。
// 输出 rt_dig_o[4:0]：one-hot，bit4=-2、bit3=-1、bit2=0、bit1=+1、bit0=+2。
//   译码沿"阈值符号链"写（q=-2 要求两个负阈之和均为负；q=0 要求 neg_0 之和非负
//   且 pos_1 之和为负）——比较常数单调时五档互斥；非单调输入的行为照抄 golden。
// 结构：golden 端口 -> xs_r4_qds_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_r4_qds_core (
  input  logic [6:0] partial_rem,
  input  logic [6:0] cmp_neg_1,
  input  logic [6:0] cmp_neg_0,
  input  logic [6:0] cmp_pos_1,
  input  logic [6:0] cmp_pos_2,
  output logic [4:0] digit_sel
);
  // 四个比较和，7 位自然回绕；符号位 1 表示 rem + m 为负
  logic [6:0] sum_neg_1, sum_neg_0, sum_pos_1, sum_pos_2;
  logic       sign_neg_1, sign_neg_0, sign_pos_1, sign_pos_2;

  assign sum_neg_1 = partial_rem + cmp_neg_1;
  assign sum_neg_0 = partial_rem + cmp_neg_0;
  assign sum_pos_1 = partial_rem + cmp_pos_1;
  assign sum_pos_2 = partial_rem + cmp_pos_2;

  assign sign_neg_1 = sum_neg_1[6];
  assign sign_neg_0 = sum_neg_0[6];
  assign sign_pos_1 = sum_pos_1[6];
  assign sign_pos_2 = sum_pos_2[6];

  // 选择表（与 golden 的 & / ==2'h2 / ==2'h0 逐项对应）
  assign digit_sel[4] = sign_neg_0 & sign_neg_1;    // q = -2
  assign digit_sel[3] = sign_neg_0 & ~sign_neg_1;   // q = -1
  assign digit_sel[2] = ~sign_neg_0 & sign_pos_1;   // q =  0
  assign digit_sel[1] = sign_pos_2 & ~sign_pos_1;   // q = +1
  assign digit_sel[0] = ~sign_pos_2 & ~sign_pos_1;  // q = +2
endmodule

module r4_qds (
  input  logic [6:0] rem_i,
  input  logic [6:0] m_neg_1_i,
  input  logic [6:0] m_neg_0_i,
  input  logic [6:0] m_pos_1_i,
  input  logic [6:0] m_pos_2_i,
  output logic [4:0] rt_dig_o
);
  xs_r4_qds_core u_core (
    .partial_rem (rem_i),
    .cmp_neg_1   (m_neg_1_i),
    .cmp_neg_0   (m_neg_0_i),
    .cmp_pos_1   (m_pos_1_i),
    .cmp_pos_2   (m_pos_2_i),
    .digit_sel   (rt_dig_o)
  );
endmodule
