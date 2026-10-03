// =============================================================================
// r4_qds_v2 —— 比较常数折成立即数的 QDS 变体（fpdiv_r64_block{,_vector} 使用）
//
// 与 r4_qds 同一张选择表，但四个比较常数是固定立即数（6 位回绕）：
//   sign_pos_2 = sign(rem - 12)、sign_pos_1 = sign(rem - 3)、
//   sign_neg_0 = sign(rem + 4)、 sign_neg_1 = sign(rem + 13)。
// 输出 io_quo_dig_o[4:0]：one-hot，bit4=-2、bit3=-1、bit2=0、bit1=+1、bit0=+2。
// 结构：golden 端口 -> xs_r4_qds_v2_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_r4_qds_v2_core (
  input  logic [5:0] partial_rem,
  output logic [4:0] digit_sel
);
  // 四个比较和，6 位自然回绕；符号位 1 表示和为负
  logic [5:0] sum_neg_1, sum_neg_0, sum_pos_1, sum_pos_2;
  logic       sign_neg_1, sign_neg_0, sign_pos_1, sign_pos_2;

  assign sum_pos_2 = partial_rem - 6'd12;  // golden: 6'(io_rem_i - 6'hC)
  assign sum_pos_1 = partial_rem - 6'd3;   // golden: 6'(io_rem_i - 6'h3)
  assign sum_neg_0 = partial_rem + 6'd4;   // golden: 6'(io_rem_i + 6'h4)
  assign sum_neg_1 = partial_rem + 6'd13;  // golden: 6'(io_rem_i + 6'hD)

  assign sign_neg_1 = sum_neg_1[5];
  assign sign_neg_0 = sum_neg_0[5];
  assign sign_pos_1 = sum_pos_1[5];
  assign sign_pos_2 = sum_pos_2[5];

  // 与 r4_qds 相同的选择表
  assign digit_sel[4] = sign_neg_0 & sign_neg_1;    // q = -2
  assign digit_sel[3] = sign_neg_0 & ~sign_neg_1;   // q = -1
  assign digit_sel[2] = ~sign_neg_0 & sign_pos_1;   // q =  0
  assign digit_sel[1] = sign_pos_2 & ~sign_pos_1;   // q = +1
  assign digit_sel[0] = ~sign_pos_2 & ~sign_pos_1;  // q = +2
endmodule

module r4_qds_v2 (
  input  logic [5:0] io_rem_i,
  output logic [4:0] io_quo_dig_o
);
  xs_r4_qds_v2_core u_core (
    .partial_rem (io_rem_i),
    .digit_sel   (io_quo_dig_o)
  );
endmodule
