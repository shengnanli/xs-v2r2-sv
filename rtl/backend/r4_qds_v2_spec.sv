// =============================================================================
// r4_qds_v2_spec —— 除数倍数版本、阈值折成立即数的推测 QDS
//   （fpdiv_r64_block{,_vector} 使用）
//
// 与 r4_qds_spec 同构，但余数修正是四个除数倍数输入 io_divisor_mul_*_i
//   （候选 c=0:+2 接 neg_2、c=1:+1 接 neg_1、c=2:0 无修正、c=3:-1 接 pos_1、
//   c=4:-2 接 pos_2），且四档选择阈值是固定偏移（7 位回绕）：
//   档 +2: base - 7'h18 (-24)、档 +1: base - 7'h06 (-6)、
//   档 -0: base + 7'h08 (+8)、档 -1: base + 7'h1A (+26)。
// 选择：prev_rt_dig_i 多 hot 时各候选组按位或（golden 为掩码 AND-OR，语义相同）。
// 输出 io_quo_dig_o[4:0]：one-hot，bit4=-2、bit3=-1、bit2=0、bit1=+1、bit0=+2。
// 结构：golden 端口 -> xs_r4_qds_v2_spec_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_r4_qds_v2_spec_core (
  input  logic [6:0] partial_rem,
  input  logic [6:0] divisor_mul [0:4],
  input  logic [4:0] prev_digit,
  output logic [4:0] digit_sel
);
  // divisor_mul[c]：候选 c 的余数修正项（c=2 即上拍 q=0，无修正，接 0）
  logic [6:0] rem_base [0:4];
  logic [6:0] sum_pos_2 [0:4];
  logic [6:0] sum_pos_1 [0:4];
  logic [6:0] sum_neg_0 [0:4];
  logic [6:0] sum_neg_1 [0:4];
  logic [3:0] sign_group [0:4];
  logic [3:0] sel_signs;

  always_comb begin
    for (int c = 0; c < 5; c++) begin
      // 基准与四档比较和均为 7 位回绕（golden 的 7'(...)）
      rem_base[c]  = partial_rem + divisor_mul[c];
      sum_pos_2[c] = rem_base[c] - 7'h18;
      sum_pos_1[c] = rem_base[c] - 7'h06;
      sum_neg_0[c] = rem_base[c] + 7'h08;
      sum_neg_1[c] = rem_base[c] + 7'h1A;
      sign_group[c] = {sum_pos_2[c][6], sum_pos_1[c][6],
                       sum_neg_0[c][6], sum_neg_1[c][6]};
    end
    // one-hot 挑出选中候选的符号组；多 hot 时按位或
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

module r4_qds_v2_spec (
  input  logic [6:0] io_rem_i,
  input  logic [6:0] io_divisor_mul_pos_2_i,
  input  logic [6:0] io_divisor_mul_pos_1_i,
  input  logic [6:0] io_divisor_mul_neg_1_i,
  input  logic [6:0] io_divisor_mul_neg_2_i,
  input  logic [4:0] io_prev_quo_dig_i,
  output logic [4:0] io_quo_dig_o
);
  // 候选索引 c 与 io_prev_quo_dig_i 位序一致：c=0:+2、1:+1、2:0、3:-1、4:-2
  logic [6:0] divisor_mul [0:4];

  assign divisor_mul[0] = io_divisor_mul_neg_2_i;
  assign divisor_mul[1] = io_divisor_mul_neg_1_i;
  assign divisor_mul[2] = 7'h0;  // 上拍 q=0：golden 直接用 rem，无修正项
  assign divisor_mul[3] = io_divisor_mul_pos_1_i;
  assign divisor_mul[4] = io_divisor_mul_pos_2_i;

  xs_r4_qds_v2_spec_core u_core (
    .partial_rem (io_rem_i),
    .divisor_mul (divisor_mul),
    .prev_digit  (io_prev_quo_dig_i),
    .digit_sel   (io_quo_dig_o)
  );
endmodule
