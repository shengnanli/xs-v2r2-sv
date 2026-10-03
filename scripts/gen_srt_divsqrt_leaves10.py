#!/usr/bin/env python3
"""Generate ten readable FPU radix-4 SRT division/square-root leaf modules.

Family A of the kimi/k3-next20 lane (docs/lanes/k3next20_prereg.md):
six quotient-digit-selection (QDS) tables, one constant generator, one LUT,
one iterative 8-bit non-restoring divide block, and three leading-zero counters.
All modules are pure combinational with zero child instances.  Every file is a
readable rewrite of /home/eda/xs-env/G1-canonical/golden-rtl/<Name>.sv with a
bit-identical wrapper port contract, verified bug-for-bug by UT (dual
instantiation) and FM (signoff-strict).
"""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


R4_QDS = '''// =============================================================================
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
'''


R4_QDS_V2 = '''// =============================================================================
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
'''


R4_QDS_SPEC = '''// =============================================================================
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
'''


R4_QDS_V2_SPEC = '''// =============================================================================
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
'''


R4_QDS_CG = '''// =============================================================================
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
'''


SRT4QDS_CONS = '''// =============================================================================
// SRT4qdsCons —— 整数 SRT 除法的 QDS 比较常数查表（SRT16Divint{,_4,_6} 使用）
//
// 按除数高 3 位 io_d_trunc_3 查表产出四档 9 位比较常数
//   io_m_neg_1/io_m_neg_0/io_m_pos_1/io_m_pos_2（二进制补码；pos_* 为负值）。
// 注意 golden 的压缩数组字面量 '{a,b,...} 首元素对应**最高**下标（[7]）——
//   本文件 LUT 一律按下标 0..7 顺序书写并注释有符号十进制，避免 cat 方向误读。
// 结构：golden 端口 -> xs_SRT4qdsCons_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_SRT4qdsCons_core (
  input  logic [2:0] divisor_top3,
  output logic [8:0] cmp_neg_1,
  output logic [8:0] cmp_neg_0,
  output logic [8:0] cmp_pos_1,
  output logic [8:0] cmp_pos_2
);
  // 四张 8 行 LUT，按下标 0..7 书写；右侧注释是有符号十进制读法
  localparam logic [8:0] LUT_NEG_1 [0:7] =
    '{9'h034, 9'h03C, 9'h040, 9'h048, 9'h04C, 9'h054, 9'h058, 9'h060};  // +52,+60,+64,+72,+76,+84,+88,+96
  localparam logic [8:0] LUT_NEG_0 [0:7] =
    '{9'h010, 9'h018, 9'h018, 9'h018, 9'h020, 9'h020, 9'h020, 9'h020};  // +16,+24,+24,+24,+32,+32,+32,+32
  localparam logic [8:0] LUT_POS_1 [0:7] =
    '{9'h1F4, 9'h1F0, 9'h1F0, 9'h1F0, 9'h1EC, 9'h1E8, 9'h1E8, 9'h1E8};  // -12,-16,-16,-16,-20,-24,-24,-24
  localparam logic [8:0] LUT_POS_2 [0:7] =
    '{9'h1D0, 9'h1C8, 9'h1C4, 9'h1BC, 9'h1B8, 9'h1B0, 9'h1AC, 9'h1A4};  // -48,-56,-60,-68,-72,-80,-84,-92

  assign cmp_neg_1 = LUT_NEG_1[divisor_top3];
  assign cmp_neg_0 = LUT_NEG_0[divisor_top3];
  assign cmp_pos_1 = LUT_POS_1[divisor_top3];
  assign cmp_pos_2 = LUT_POS_2[divisor_top3];
endmodule

module SRT4qdsCons (
  input  logic [2:0] io_d_trunc_3,
  output logic [8:0] io_m_neg_1,
  output logic [8:0] io_m_neg_0,
  output logic [8:0] io_m_pos_1,
  output logic [8:0] io_m_pos_2
);
  xs_SRT4qdsCons_core u_core (
    .divisor_top3 (io_d_trunc_3),
    .cmp_neg_1    (io_m_neg_1),
    .cmp_neg_0    (io_m_neg_0),
    .cmp_pos_1    (io_m_pos_1),
    .cmp_pos_2    (io_m_pos_2)
  );
endmodule
'''


ITER_BLOCK = '''// =============================================================================
// IterBlockI8Nr4 —— 8 位非恢复（non-restoring）除法迭代块（I8DivNr4 使用）
//
// 每拍消耗余数低位部分 pre_w_low 的 2 位、产出 2 个商数位：余数非负（符号位 0）
//   商 1。pre_w 是部分余数的高 9 位（带符号），pre_w_low 是低 8 位。
// 机制：第一档把 w 左移 1 位、补入 w_low[7]，与 divisor_cons[上拍符号+1]
//   （非负取 1 号、负取 2 号；golden 写法是 2'({1'h0, pre_w[8]} + 2'h1)，
//   2 位回绕后恰为 {1,2}）试加得 trial_rem；第二档再左移 1 位（累计 2 位），
//   按 {上拍符号, trial 符号} 四选一 divisor_cons 得新余数。
//   所有加法均为 9 位回绕（golden 的 9'(...)）。
// divisor_cons 是 I8DivNr4 预存的四个除数倍数档，本块只做选择，不解释其语义。
// 结构：golden 端口 -> xs_IterBlockI8Nr4_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_IterBlockI8Nr4_core (
  input  logic [8:0] divisor_cons [0:3],
  input  logic [8:0] pre_w,
  input  logic [7:0] pre_w_low,
  output logic [8:0] nxt_w,
  output logic [7:0] nxt_w_low,
  input  logic [7:0] pre_q,
  output logic [7:0] nxt_q
);
  // 第一档试加：w 左移 1 位补入 w_low[7]；倍数由上拍余数符号选择
  logic [1:0] trial_sel;
  logic [8:0] w_shift1, trial_rem;
  assign trial_sel = {1'b0, pre_w[8]} + 2'd1;
  assign w_shift1  = {pre_w[7:0], pre_w_low[7]};
  assign trial_rem = divisor_cons[trial_sel] + w_shift1;  // 9 位回绕

  // 第二档：累计左移 2 位，按 {上拍符号, trial 符号} 选倍数
  logic [1:0] next_sel;
  logic [8:0] w_shift2;
  assign next_sel = {pre_w[8], trial_rem[8]};
  assign w_shift2 = {pre_w[6:0], pre_w_low[7:6]};

  always_comb begin
    case (next_sel)
      2'b00:   nxt_w = divisor_cons[0] + w_shift2;
      2'b01:   nxt_w = divisor_cons[1] + w_shift2;
      2'b10:   nxt_w = divisor_cons[2] + w_shift2;
      default: nxt_w = divisor_cons[3] + w_shift2;
    endcase
  end

  // 两个商数位：余数非负（符号位 0）则商 1；低位部分左移 2 位出
  assign nxt_q     = {pre_q[5:0], ~trial_rem[8], ~nxt_w[8]};
  assign nxt_w_low = {pre_w_low[5:0], 2'b00};
endmodule

module IterBlockI8Nr4 (
  input  logic [8:0] io_d_cons_0,
  input  logic [8:0] io_d_cons_1,
  input  logic [8:0] io_d_cons_2,
  input  logic [8:0] io_d_cons_3,
  input  logic [8:0] io_pre_w,
  input  logic [7:0] io_pre_w_low,
  output logic [8:0] io_nxt_w,
  output logic [7:0] io_nxt_w_low,
  input  logic [7:0] io_pre_q,
  output logic [7:0] io_nxt_q
);
  logic [8:0] divisor_cons [0:3];

  assign divisor_cons[0] = io_d_cons_0;
  assign divisor_cons[1] = io_d_cons_1;
  assign divisor_cons[2] = io_d_cons_2;
  assign divisor_cons[3] = io_d_cons_3;

  xs_IterBlockI8Nr4_core u_core (
    .divisor_cons (divisor_cons),
    .pre_w        (io_pre_w),
    .pre_w_low    (io_pre_w_low),
    .nxt_w        (io_nxt_w),
    .nxt_w_low    (io_nxt_w_low),
    .pre_q        (io_pre_q),
    .nxt_q        (io_nxt_q)
  );
endmodule
'''


def lzc(mod: str, width: int, cw: int, users: str) -> str:
    """Emit one leading-zero-counter variant (self-contained core + wrapper)."""
    fb = width - 1
    return f'''// =============================================================================
// {mod} —— {width} 位前导零计数（{users} 的规格化移位量）
//
// 本变体的参数与规模（按 G1 golden 现读）：输入 {width} 位，cnt_o {cw} 位，
//   纯组合、无寄存器、无子模块。
// 语义（Chisel PriorityEncoder 兜底语义，bug-for-bug 照抄）：
//   cnt_o = in_i 的前导零个数（最高置位在第 p 位则 cnt = {fb}-p）；
//   第 0 位不在显式扫描链里，而是优先级链的无条件末档 —— 仅第 0 位置位时
//   cnt_o = {fb}，与常规全宽 CLZ 结果相同；
//   ★全零输入★：empty_o = 1 且 cnt_o = 0（golden 链首即 empty|in[{fb}] ? 0
//   —— 是 0，不是 {width}）。这是与 CLZ.sv 同族的兜底陷阱，照抄不"修正"。
// golden 里的共享中间线只是 firtool 对扫描链的布尔化简，已逐位核对扫描链
//   恰好覆盖第 {fb}..1 位、每一位各一次，无丢位无错位。
// 结构：golden 端口 -> xs_{mod}_core（优先级扫描核）-> 直接出。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_{mod}_core (
  input  logic [{fb}:0] data_i,
  output logic [{cw-1}:0] count_o,
  output logic          empty_o
);
  assign empty_o = (data_i == '0);

  // 优先级扫描：最高的置位决定计数；第 0 位是无条件末档（count = {fb}，
  // 与全宽 CLZ 一致）；全零由 empty 先行截为 0（见文件头）。
  always_comb begin
    count_o = '0;
    if (data_i != '0) begin
      count_o = {cw}'d{fb};
      for (int i = 1; i < {width}; i++)
        if (data_i[i]) count_o = {cw}'({fb} - i);
    end
  end
endmodule

module {mod} (
  input  logic [{fb}:0] in_i,
  output logic [{cw-1}:0] cnt_o,
  output logic          empty_o
);
  xs_{mod}_core u_core (
    .data_i  (in_i),
    .count_o (cnt_o),
    .empty_o (empty_o)
  );
endmodule
'''


OUTPUTS = {
    "r4_qds": R4_QDS,
    "r4_qds_v2": R4_QDS_V2,
    "r4_qds_spec": R4_QDS_SPEC,
    "r4_qds_v2_spec": R4_QDS_V2_SPEC,
    "r4_qds_cg": R4_QDS_CG,
    "SRT4qdsCons": SRT4QDS_CONS,
    "IterBlockI8Nr4": ITER_BLOCK,
    "lzc": lzc("lzc", 53, 6, "fpsqrt_r16{,_vector_r16}"),
    "lzc_3": lzc("lzc_3", 24, 5, "fpsqrt_vector_r16"),
    "lzc_4": lzc("lzc_4", 11, 4, "fpsqrt_vector_r16"),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for module, contents in OUTPUTS.items():
        path = RTL_DIR / f"{module}.sv"
        if args.check:
            if not path.exists() or path.read_text() != contents:
                drift.append(str(path))
        else:
            path.write_text(contents)

    if drift:
        print("gen_srt_divsqrt_leaves10 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_srt_divsqrt_leaves10 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
