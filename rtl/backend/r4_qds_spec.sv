// =============================================================================
// r4_qds_spec —— 带上一拍商数位推测的 QDS（fpsqrt_r16_block 使用）
//
// 开方迭代里本拍余数依赖上一拍商数位，因此对上一拍 q 的 5 个候选各预备一组
//   四个比较和（共 20 组），再用 prev_rt_dig_i（one-hot）挑出本拍选择表输入。
// 每候选 c（c=0:+2、1:+1、2:0、3:-1、4:-2，与 prev_rt_dig_i 位序一致）：
//   基准 base = 9 位回绕 rem + sqrt_csa_val（上拍 q=0 的候选没有修正项，
//   golden 直接用 rem）；四档比较和 = 9 位回绕 base + {m, 2'b00}（比较常数
//   左移 2 位），取符号位得 4 位组 {pos_2, pos_1, neg_0, neg_1}。
// 选择：prev_rt_dig_i 多 hot 时各候选组按位或（golden 原文即 OR 结构，照抄）。
// 输出 rt_dig_o[4:0]：与 r4_qds 同一张译码表，one-hot {-2,-1,0,+1,+2}。
// 结构：golden 端口 -> 展平成数组 -> xs_r4_qds_spec_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_r4_qds_spec_core (
  input  logic [8:0] partial_rem,
  input  logic [8:0] csa_msbs [0:4],
  input  logic [6:0] cmp_const [0:4][0:3],
  input  logic [4:0] prev_digit,
  output logic [4:0] digit_sel
);
  // csa_msbs[c]：候选 c 的余数修正项（c=2 即上拍 q=0，无修正，接 0）。
  // cmp_const[c][j]：候选 c 下档位 j 的比较常数，j=0:+2、1:+1、2:-0、3:-1。
  logic [8:0] rem_base [0:4];
  logic [8:0] cmp_sum [0:4][0:3];
  logic [3:0] sign_group [0:4];
  logic [3:0] sel_signs;

  always_comb begin
    for (int c = 0; c < 5; c++) begin
      // 基准与四档比较和均为 9 位回绕（golden 的 9'(...)）
      rem_base[c] = partial_rem + csa_msbs[c];
      for (int j = 0; j < 4; j++)
        cmp_sum[c][j] = rem_base[c] + {cmp_const[c][j], 2'b00};
      sign_group[c] = {cmp_sum[c][0][8], cmp_sum[c][1][8],
                       cmp_sum[c][2][8], cmp_sum[c][3][8]};
    end
    // one-hot 挑出选中候选的符号组；多 hot 时按位或（与 golden 的 OR 结构一致）
    sel_signs = 4'h0;
    for (int c = 0; c < 5; c++)
      if (prev_digit[c])
        sel_signs = sel_signs | sign_group[c];
  end

  // 与 r4_qds 相同的选择表：组内位序 {pos_2, pos_1, neg_0, neg_1} = [3:0]
  assign digit_sel[4] = sel_signs[1] & sel_signs[0];    // q = -2
  assign digit_sel[3] = sel_signs[1] & ~sel_signs[0];   // q = -1
  assign digit_sel[2] = sel_signs[2] & ~sel_signs[1];   // q =  0
  assign digit_sel[1] = sel_signs[3] & ~sel_signs[2];   // q = +1
  assign digit_sel[0] = ~sel_signs[3] & ~sel_signs[2];  // q = +2
endmodule

module r4_qds_spec (
  input  logic [8:0] rem_i,
  input  logic [8:0] sqrt_csa_val_neg_2_msbs_i,
  input  logic [8:0] sqrt_csa_val_neg_1_msbs_i,
  input  logic [8:0] sqrt_csa_val_pos_1_msbs_i,
  input  logic [8:0] sqrt_csa_val_pos_2_msbs_i,
  input  logic [6:0] m_neg_1_neg_2_i,
  input  logic [6:0] m_neg_0_neg_2_i,
  input  logic [6:0] m_pos_1_neg_2_i,
  input  logic [6:0] m_pos_2_neg_2_i,
  input  logic [6:0] m_neg_1_neg_1_i,
  input  logic [6:0] m_neg_0_neg_1_i,
  input  logic [6:0] m_pos_1_neg_1_i,
  input  logic [6:0] m_pos_2_neg_1_i,
  input  logic [6:0] m_neg_1_neg_0_i,
  input  logic [6:0] m_neg_0_neg_0_i,
  input  logic [6:0] m_pos_1_neg_0_i,
  input  logic [6:0] m_pos_2_neg_0_i,
  input  logic [6:0] m_neg_1_pos_1_i,
  input  logic [6:0] m_neg_0_pos_1_i,
  input  logic [6:0] m_pos_1_pos_1_i,
  input  logic [6:0] m_pos_2_pos_1_i,
  input  logic [6:0] m_neg_1_pos_2_i,
  input  logic [6:0] m_neg_0_pos_2_i,
  input  logic [6:0] m_pos_1_pos_2_i,
  input  logic [6:0] m_pos_2_pos_2_i,
  input  logic [4:0] prev_rt_dig_i,
  output logic [4:0] rt_dig_o
);
  // 候选索引 c 与 prev_rt_dig_i 位序一致：c=0:+2、1:+1、2:0、3:-1、4:-2
  logic [8:0] csa_msbs [0:4];
  logic [6:0] cmp_const [0:4][0:3];

  assign csa_msbs[0] = sqrt_csa_val_pos_2_msbs_i;
  assign csa_msbs[1] = sqrt_csa_val_pos_1_msbs_i;
  assign csa_msbs[2] = 9'h0;  // 上拍 q=0：golden 直接用 rem，无修正项
  assign csa_msbs[3] = sqrt_csa_val_neg_1_msbs_i;
  assign csa_msbs[4] = sqrt_csa_val_neg_2_msbs_i;

  // cmp_const[c] = {+2, +1, -0, -1} 四档；端口名形如 m_<档>_<上拍>_i
  assign cmp_const[0][0] = m_pos_2_pos_2_i;
  assign cmp_const[0][1] = m_pos_1_pos_2_i;
  assign cmp_const[0][2] = m_neg_0_pos_2_i;
  assign cmp_const[0][3] = m_neg_1_pos_2_i;
  assign cmp_const[1][0] = m_pos_2_pos_1_i;
  assign cmp_const[1][1] = m_pos_1_pos_1_i;
  assign cmp_const[1][2] = m_neg_0_pos_1_i;
  assign cmp_const[1][3] = m_neg_1_pos_1_i;
  assign cmp_const[2][0] = m_pos_2_neg_0_i;
  assign cmp_const[2][1] = m_pos_1_neg_0_i;
  assign cmp_const[2][2] = m_neg_0_neg_0_i;
  assign cmp_const[2][3] = m_neg_1_neg_0_i;
  assign cmp_const[3][0] = m_pos_2_neg_1_i;
  assign cmp_const[3][1] = m_pos_1_neg_1_i;
  assign cmp_const[3][2] = m_neg_0_neg_1_i;
  assign cmp_const[3][3] = m_neg_1_neg_1_i;
  assign cmp_const[4][0] = m_pos_2_neg_2_i;
  assign cmp_const[4][1] = m_pos_1_neg_2_i;
  assign cmp_const[4][2] = m_neg_0_neg_2_i;
  assign cmp_const[4][3] = m_neg_1_neg_2_i;

  xs_r4_qds_spec_core u_core (
    .partial_rem (rem_i),
    .csa_msbs    (csa_msbs),
    .cmp_const   (cmp_const),
    .prev_digit  (prev_rt_dig_i),
    .digit_sel   (rt_dig_o)
  );
endmodule
