// 自动生成：scripts/gen_pmp.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 20000;
  int errors = 0, checks = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;
  logic io_distribute_csr_w_valid;
  logic [11:0] io_distribute_csr_w_bits_addr;
  logic [63:0] io_distribute_csr_w_bits_data;
  wire g_io_pmp_0_cfg_l;  wire i_io_pmp_0_cfg_l;
  wire [1:0] g_io_pmp_0_cfg_a;  wire [1:0] i_io_pmp_0_cfg_a;
  wire g_io_pmp_0_cfg_x;  wire i_io_pmp_0_cfg_x;
  wire g_io_pmp_0_cfg_w;  wire i_io_pmp_0_cfg_w;
  wire g_io_pmp_0_cfg_r;  wire i_io_pmp_0_cfg_r;
  wire [45:0] g_io_pmp_0_addr;  wire [45:0] i_io_pmp_0_addr;
  wire [47:0] g_io_pmp_0_mask;  wire [47:0] i_io_pmp_0_mask;
  wire g_io_pmp_1_cfg_l;  wire i_io_pmp_1_cfg_l;
  wire [1:0] g_io_pmp_1_cfg_a;  wire [1:0] i_io_pmp_1_cfg_a;
  wire g_io_pmp_1_cfg_x;  wire i_io_pmp_1_cfg_x;
  wire g_io_pmp_1_cfg_w;  wire i_io_pmp_1_cfg_w;
  wire g_io_pmp_1_cfg_r;  wire i_io_pmp_1_cfg_r;
  wire [45:0] g_io_pmp_1_addr;  wire [45:0] i_io_pmp_1_addr;
  wire [47:0] g_io_pmp_1_mask;  wire [47:0] i_io_pmp_1_mask;
  wire g_io_pmp_2_cfg_l;  wire i_io_pmp_2_cfg_l;
  wire [1:0] g_io_pmp_2_cfg_a;  wire [1:0] i_io_pmp_2_cfg_a;
  wire g_io_pmp_2_cfg_x;  wire i_io_pmp_2_cfg_x;
  wire g_io_pmp_2_cfg_w;  wire i_io_pmp_2_cfg_w;
  wire g_io_pmp_2_cfg_r;  wire i_io_pmp_2_cfg_r;
  wire [45:0] g_io_pmp_2_addr;  wire [45:0] i_io_pmp_2_addr;
  wire [47:0] g_io_pmp_2_mask;  wire [47:0] i_io_pmp_2_mask;
  wire g_io_pmp_3_cfg_l;  wire i_io_pmp_3_cfg_l;
  wire [1:0] g_io_pmp_3_cfg_a;  wire [1:0] i_io_pmp_3_cfg_a;
  wire g_io_pmp_3_cfg_x;  wire i_io_pmp_3_cfg_x;
  wire g_io_pmp_3_cfg_w;  wire i_io_pmp_3_cfg_w;
  wire g_io_pmp_3_cfg_r;  wire i_io_pmp_3_cfg_r;
  wire [45:0] g_io_pmp_3_addr;  wire [45:0] i_io_pmp_3_addr;
  wire [47:0] g_io_pmp_3_mask;  wire [47:0] i_io_pmp_3_mask;
  wire g_io_pmp_4_cfg_l;  wire i_io_pmp_4_cfg_l;
  wire [1:0] g_io_pmp_4_cfg_a;  wire [1:0] i_io_pmp_4_cfg_a;
  wire g_io_pmp_4_cfg_x;  wire i_io_pmp_4_cfg_x;
  wire g_io_pmp_4_cfg_w;  wire i_io_pmp_4_cfg_w;
  wire g_io_pmp_4_cfg_r;  wire i_io_pmp_4_cfg_r;
  wire [45:0] g_io_pmp_4_addr;  wire [45:0] i_io_pmp_4_addr;
  wire [47:0] g_io_pmp_4_mask;  wire [47:0] i_io_pmp_4_mask;
  wire g_io_pmp_5_cfg_l;  wire i_io_pmp_5_cfg_l;
  wire [1:0] g_io_pmp_5_cfg_a;  wire [1:0] i_io_pmp_5_cfg_a;
  wire g_io_pmp_5_cfg_x;  wire i_io_pmp_5_cfg_x;
  wire g_io_pmp_5_cfg_w;  wire i_io_pmp_5_cfg_w;
  wire g_io_pmp_5_cfg_r;  wire i_io_pmp_5_cfg_r;
  wire [45:0] g_io_pmp_5_addr;  wire [45:0] i_io_pmp_5_addr;
  wire [47:0] g_io_pmp_5_mask;  wire [47:0] i_io_pmp_5_mask;
  wire g_io_pmp_6_cfg_l;  wire i_io_pmp_6_cfg_l;
  wire [1:0] g_io_pmp_6_cfg_a;  wire [1:0] i_io_pmp_6_cfg_a;
  wire g_io_pmp_6_cfg_x;  wire i_io_pmp_6_cfg_x;
  wire g_io_pmp_6_cfg_w;  wire i_io_pmp_6_cfg_w;
  wire g_io_pmp_6_cfg_r;  wire i_io_pmp_6_cfg_r;
  wire [45:0] g_io_pmp_6_addr;  wire [45:0] i_io_pmp_6_addr;
  wire [47:0] g_io_pmp_6_mask;  wire [47:0] i_io_pmp_6_mask;
  wire g_io_pmp_7_cfg_l;  wire i_io_pmp_7_cfg_l;
  wire [1:0] g_io_pmp_7_cfg_a;  wire [1:0] i_io_pmp_7_cfg_a;
  wire g_io_pmp_7_cfg_x;  wire i_io_pmp_7_cfg_x;
  wire g_io_pmp_7_cfg_w;  wire i_io_pmp_7_cfg_w;
  wire g_io_pmp_7_cfg_r;  wire i_io_pmp_7_cfg_r;
  wire [45:0] g_io_pmp_7_addr;  wire [45:0] i_io_pmp_7_addr;
  wire [47:0] g_io_pmp_7_mask;  wire [47:0] i_io_pmp_7_mask;
  wire g_io_pmp_8_cfg_l;  wire i_io_pmp_8_cfg_l;
  wire [1:0] g_io_pmp_8_cfg_a;  wire [1:0] i_io_pmp_8_cfg_a;
  wire g_io_pmp_8_cfg_x;  wire i_io_pmp_8_cfg_x;
  wire g_io_pmp_8_cfg_w;  wire i_io_pmp_8_cfg_w;
  wire g_io_pmp_8_cfg_r;  wire i_io_pmp_8_cfg_r;
  wire [45:0] g_io_pmp_8_addr;  wire [45:0] i_io_pmp_8_addr;
  wire [47:0] g_io_pmp_8_mask;  wire [47:0] i_io_pmp_8_mask;
  wire g_io_pmp_9_cfg_l;  wire i_io_pmp_9_cfg_l;
  wire [1:0] g_io_pmp_9_cfg_a;  wire [1:0] i_io_pmp_9_cfg_a;
  wire g_io_pmp_9_cfg_x;  wire i_io_pmp_9_cfg_x;
  wire g_io_pmp_9_cfg_w;  wire i_io_pmp_9_cfg_w;
  wire g_io_pmp_9_cfg_r;  wire i_io_pmp_9_cfg_r;
  wire [45:0] g_io_pmp_9_addr;  wire [45:0] i_io_pmp_9_addr;
  wire [47:0] g_io_pmp_9_mask;  wire [47:0] i_io_pmp_9_mask;
  wire g_io_pmp_10_cfg_l;  wire i_io_pmp_10_cfg_l;
  wire [1:0] g_io_pmp_10_cfg_a;  wire [1:0] i_io_pmp_10_cfg_a;
  wire g_io_pmp_10_cfg_x;  wire i_io_pmp_10_cfg_x;
  wire g_io_pmp_10_cfg_w;  wire i_io_pmp_10_cfg_w;
  wire g_io_pmp_10_cfg_r;  wire i_io_pmp_10_cfg_r;
  wire [45:0] g_io_pmp_10_addr;  wire [45:0] i_io_pmp_10_addr;
  wire [47:0] g_io_pmp_10_mask;  wire [47:0] i_io_pmp_10_mask;
  wire g_io_pmp_11_cfg_l;  wire i_io_pmp_11_cfg_l;
  wire [1:0] g_io_pmp_11_cfg_a;  wire [1:0] i_io_pmp_11_cfg_a;
  wire g_io_pmp_11_cfg_x;  wire i_io_pmp_11_cfg_x;
  wire g_io_pmp_11_cfg_w;  wire i_io_pmp_11_cfg_w;
  wire g_io_pmp_11_cfg_r;  wire i_io_pmp_11_cfg_r;
  wire [45:0] g_io_pmp_11_addr;  wire [45:0] i_io_pmp_11_addr;
  wire [47:0] g_io_pmp_11_mask;  wire [47:0] i_io_pmp_11_mask;
  wire g_io_pmp_12_cfg_l;  wire i_io_pmp_12_cfg_l;
  wire [1:0] g_io_pmp_12_cfg_a;  wire [1:0] i_io_pmp_12_cfg_a;
  wire g_io_pmp_12_cfg_x;  wire i_io_pmp_12_cfg_x;
  wire g_io_pmp_12_cfg_w;  wire i_io_pmp_12_cfg_w;
  wire g_io_pmp_12_cfg_r;  wire i_io_pmp_12_cfg_r;
  wire [45:0] g_io_pmp_12_addr;  wire [45:0] i_io_pmp_12_addr;
  wire [47:0] g_io_pmp_12_mask;  wire [47:0] i_io_pmp_12_mask;
  wire g_io_pmp_13_cfg_l;  wire i_io_pmp_13_cfg_l;
  wire [1:0] g_io_pmp_13_cfg_a;  wire [1:0] i_io_pmp_13_cfg_a;
  wire g_io_pmp_13_cfg_x;  wire i_io_pmp_13_cfg_x;
  wire g_io_pmp_13_cfg_w;  wire i_io_pmp_13_cfg_w;
  wire g_io_pmp_13_cfg_r;  wire i_io_pmp_13_cfg_r;
  wire [45:0] g_io_pmp_13_addr;  wire [45:0] i_io_pmp_13_addr;
  wire [47:0] g_io_pmp_13_mask;  wire [47:0] i_io_pmp_13_mask;
  wire g_io_pmp_14_cfg_l;  wire i_io_pmp_14_cfg_l;
  wire [1:0] g_io_pmp_14_cfg_a;  wire [1:0] i_io_pmp_14_cfg_a;
  wire g_io_pmp_14_cfg_x;  wire i_io_pmp_14_cfg_x;
  wire g_io_pmp_14_cfg_w;  wire i_io_pmp_14_cfg_w;
  wire g_io_pmp_14_cfg_r;  wire i_io_pmp_14_cfg_r;
  wire [45:0] g_io_pmp_14_addr;  wire [45:0] i_io_pmp_14_addr;
  wire [47:0] g_io_pmp_14_mask;  wire [47:0] i_io_pmp_14_mask;
  wire g_io_pmp_15_cfg_l;  wire i_io_pmp_15_cfg_l;
  wire [1:0] g_io_pmp_15_cfg_a;  wire [1:0] i_io_pmp_15_cfg_a;
  wire g_io_pmp_15_cfg_x;  wire i_io_pmp_15_cfg_x;
  wire g_io_pmp_15_cfg_w;  wire i_io_pmp_15_cfg_w;
  wire g_io_pmp_15_cfg_r;  wire i_io_pmp_15_cfg_r;
  wire [45:0] g_io_pmp_15_addr;  wire [45:0] i_io_pmp_15_addr;
  wire [47:0] g_io_pmp_15_mask;  wire [47:0] i_io_pmp_15_mask;
  wire g_io_pma_0_cfg_c;  wire i_io_pma_0_cfg_c;
  wire g_io_pma_0_cfg_atomic;  wire i_io_pma_0_cfg_atomic;
  wire [1:0] g_io_pma_0_cfg_a;  wire [1:0] i_io_pma_0_cfg_a;
  wire g_io_pma_0_cfg_x;  wire i_io_pma_0_cfg_x;
  wire g_io_pma_0_cfg_w;  wire i_io_pma_0_cfg_w;
  wire g_io_pma_0_cfg_r;  wire i_io_pma_0_cfg_r;
  wire [45:0] g_io_pma_0_addr;  wire [45:0] i_io_pma_0_addr;
  wire [47:0] g_io_pma_0_mask;  wire [47:0] i_io_pma_0_mask;
  wire g_io_pma_1_cfg_c;  wire i_io_pma_1_cfg_c;
  wire g_io_pma_1_cfg_atomic;  wire i_io_pma_1_cfg_atomic;
  wire [1:0] g_io_pma_1_cfg_a;  wire [1:0] i_io_pma_1_cfg_a;
  wire g_io_pma_1_cfg_x;  wire i_io_pma_1_cfg_x;
  wire g_io_pma_1_cfg_w;  wire i_io_pma_1_cfg_w;
  wire g_io_pma_1_cfg_r;  wire i_io_pma_1_cfg_r;
  wire [45:0] g_io_pma_1_addr;  wire [45:0] i_io_pma_1_addr;
  wire [47:0] g_io_pma_1_mask;  wire [47:0] i_io_pma_1_mask;
  wire g_io_pma_2_cfg_c;  wire i_io_pma_2_cfg_c;
  wire g_io_pma_2_cfg_atomic;  wire i_io_pma_2_cfg_atomic;
  wire [1:0] g_io_pma_2_cfg_a;  wire [1:0] i_io_pma_2_cfg_a;
  wire g_io_pma_2_cfg_x;  wire i_io_pma_2_cfg_x;
  wire g_io_pma_2_cfg_w;  wire i_io_pma_2_cfg_w;
  wire g_io_pma_2_cfg_r;  wire i_io_pma_2_cfg_r;
  wire [45:0] g_io_pma_2_addr;  wire [45:0] i_io_pma_2_addr;
  wire [47:0] g_io_pma_2_mask;  wire [47:0] i_io_pma_2_mask;
  wire g_io_pma_3_cfg_c;  wire i_io_pma_3_cfg_c;
  wire g_io_pma_3_cfg_atomic;  wire i_io_pma_3_cfg_atomic;
  wire [1:0] g_io_pma_3_cfg_a;  wire [1:0] i_io_pma_3_cfg_a;
  wire g_io_pma_3_cfg_x;  wire i_io_pma_3_cfg_x;
  wire g_io_pma_3_cfg_w;  wire i_io_pma_3_cfg_w;
  wire g_io_pma_3_cfg_r;  wire i_io_pma_3_cfg_r;
  wire [45:0] g_io_pma_3_addr;  wire [45:0] i_io_pma_3_addr;
  wire [47:0] g_io_pma_3_mask;  wire [47:0] i_io_pma_3_mask;
  wire g_io_pma_4_cfg_c;  wire i_io_pma_4_cfg_c;
  wire g_io_pma_4_cfg_atomic;  wire i_io_pma_4_cfg_atomic;
  wire [1:0] g_io_pma_4_cfg_a;  wire [1:0] i_io_pma_4_cfg_a;
  wire g_io_pma_4_cfg_x;  wire i_io_pma_4_cfg_x;
  wire g_io_pma_4_cfg_w;  wire i_io_pma_4_cfg_w;
  wire g_io_pma_4_cfg_r;  wire i_io_pma_4_cfg_r;
  wire [45:0] g_io_pma_4_addr;  wire [45:0] i_io_pma_4_addr;
  wire [47:0] g_io_pma_4_mask;  wire [47:0] i_io_pma_4_mask;
  wire g_io_pma_5_cfg_c;  wire i_io_pma_5_cfg_c;
  wire g_io_pma_5_cfg_atomic;  wire i_io_pma_5_cfg_atomic;
  wire [1:0] g_io_pma_5_cfg_a;  wire [1:0] i_io_pma_5_cfg_a;
  wire g_io_pma_5_cfg_x;  wire i_io_pma_5_cfg_x;
  wire g_io_pma_5_cfg_w;  wire i_io_pma_5_cfg_w;
  wire g_io_pma_5_cfg_r;  wire i_io_pma_5_cfg_r;
  wire [45:0] g_io_pma_5_addr;  wire [45:0] i_io_pma_5_addr;
  wire [47:0] g_io_pma_5_mask;  wire [47:0] i_io_pma_5_mask;
  wire g_io_pma_6_cfg_c;  wire i_io_pma_6_cfg_c;
  wire g_io_pma_6_cfg_atomic;  wire i_io_pma_6_cfg_atomic;
  wire [1:0] g_io_pma_6_cfg_a;  wire [1:0] i_io_pma_6_cfg_a;
  wire g_io_pma_6_cfg_x;  wire i_io_pma_6_cfg_x;
  wire g_io_pma_6_cfg_w;  wire i_io_pma_6_cfg_w;
  wire g_io_pma_6_cfg_r;  wire i_io_pma_6_cfg_r;
  wire [45:0] g_io_pma_6_addr;  wire [45:0] i_io_pma_6_addr;
  wire [47:0] g_io_pma_6_mask;  wire [47:0] i_io_pma_6_mask;
  wire g_io_pma_7_cfg_c;  wire i_io_pma_7_cfg_c;
  wire g_io_pma_7_cfg_atomic;  wire i_io_pma_7_cfg_atomic;
  wire [1:0] g_io_pma_7_cfg_a;  wire [1:0] i_io_pma_7_cfg_a;
  wire g_io_pma_7_cfg_x;  wire i_io_pma_7_cfg_x;
  wire g_io_pma_7_cfg_w;  wire i_io_pma_7_cfg_w;
  wire g_io_pma_7_cfg_r;  wire i_io_pma_7_cfg_r;
  wire [45:0] g_io_pma_7_addr;  wire [45:0] i_io_pma_7_addr;
  wire [47:0] g_io_pma_7_mask;  wire [47:0] i_io_pma_7_mask;
  wire g_io_pma_8_cfg_c;  wire i_io_pma_8_cfg_c;
  wire g_io_pma_8_cfg_atomic;  wire i_io_pma_8_cfg_atomic;
  wire [1:0] g_io_pma_8_cfg_a;  wire [1:0] i_io_pma_8_cfg_a;
  wire g_io_pma_8_cfg_x;  wire i_io_pma_8_cfg_x;
  wire g_io_pma_8_cfg_w;  wire i_io_pma_8_cfg_w;
  wire g_io_pma_8_cfg_r;  wire i_io_pma_8_cfg_r;
  wire [45:0] g_io_pma_8_addr;  wire [45:0] i_io_pma_8_addr;
  wire [47:0] g_io_pma_8_mask;  wire [47:0] i_io_pma_8_mask;
  wire g_io_pma_9_cfg_c;  wire i_io_pma_9_cfg_c;
  wire g_io_pma_9_cfg_atomic;  wire i_io_pma_9_cfg_atomic;
  wire [1:0] g_io_pma_9_cfg_a;  wire [1:0] i_io_pma_9_cfg_a;
  wire g_io_pma_9_cfg_x;  wire i_io_pma_9_cfg_x;
  wire g_io_pma_9_cfg_w;  wire i_io_pma_9_cfg_w;
  wire g_io_pma_9_cfg_r;  wire i_io_pma_9_cfg_r;
  wire [45:0] g_io_pma_9_addr;  wire [45:0] i_io_pma_9_addr;
  wire [47:0] g_io_pma_9_mask;  wire [47:0] i_io_pma_9_mask;
  wire g_io_pma_10_cfg_c;  wire i_io_pma_10_cfg_c;
  wire g_io_pma_10_cfg_atomic;  wire i_io_pma_10_cfg_atomic;
  wire [1:0] g_io_pma_10_cfg_a;  wire [1:0] i_io_pma_10_cfg_a;
  wire g_io_pma_10_cfg_x;  wire i_io_pma_10_cfg_x;
  wire g_io_pma_10_cfg_w;  wire i_io_pma_10_cfg_w;
  wire g_io_pma_10_cfg_r;  wire i_io_pma_10_cfg_r;
  wire [45:0] g_io_pma_10_addr;  wire [45:0] i_io_pma_10_addr;
  wire [47:0] g_io_pma_10_mask;  wire [47:0] i_io_pma_10_mask;
  wire g_io_pma_11_cfg_c;  wire i_io_pma_11_cfg_c;
  wire g_io_pma_11_cfg_atomic;  wire i_io_pma_11_cfg_atomic;
  wire [1:0] g_io_pma_11_cfg_a;  wire [1:0] i_io_pma_11_cfg_a;
  wire g_io_pma_11_cfg_x;  wire i_io_pma_11_cfg_x;
  wire g_io_pma_11_cfg_w;  wire i_io_pma_11_cfg_w;
  wire g_io_pma_11_cfg_r;  wire i_io_pma_11_cfg_r;
  wire [45:0] g_io_pma_11_addr;  wire [45:0] i_io_pma_11_addr;
  wire [47:0] g_io_pma_11_mask;  wire [47:0] i_io_pma_11_mask;
  wire g_io_pma_12_cfg_c;  wire i_io_pma_12_cfg_c;
  wire g_io_pma_12_cfg_atomic;  wire i_io_pma_12_cfg_atomic;
  wire [1:0] g_io_pma_12_cfg_a;  wire [1:0] i_io_pma_12_cfg_a;
  wire g_io_pma_12_cfg_x;  wire i_io_pma_12_cfg_x;
  wire g_io_pma_12_cfg_w;  wire i_io_pma_12_cfg_w;
  wire g_io_pma_12_cfg_r;  wire i_io_pma_12_cfg_r;
  wire [45:0] g_io_pma_12_addr;  wire [45:0] i_io_pma_12_addr;
  wire [47:0] g_io_pma_12_mask;  wire [47:0] i_io_pma_12_mask;
  wire g_io_pma_13_cfg_c;  wire i_io_pma_13_cfg_c;
  wire g_io_pma_13_cfg_atomic;  wire i_io_pma_13_cfg_atomic;
  wire [1:0] g_io_pma_13_cfg_a;  wire [1:0] i_io_pma_13_cfg_a;
  wire g_io_pma_13_cfg_x;  wire i_io_pma_13_cfg_x;
  wire g_io_pma_13_cfg_w;  wire i_io_pma_13_cfg_w;
  wire g_io_pma_13_cfg_r;  wire i_io_pma_13_cfg_r;
  wire [45:0] g_io_pma_13_addr;  wire [45:0] i_io_pma_13_addr;
  wire [47:0] g_io_pma_13_mask;  wire [47:0] i_io_pma_13_mask;
  wire g_io_pma_14_cfg_c;  wire i_io_pma_14_cfg_c;
  wire g_io_pma_14_cfg_atomic;  wire i_io_pma_14_cfg_atomic;
  wire [1:0] g_io_pma_14_cfg_a;  wire [1:0] i_io_pma_14_cfg_a;
  wire g_io_pma_14_cfg_x;  wire i_io_pma_14_cfg_x;
  wire g_io_pma_14_cfg_w;  wire i_io_pma_14_cfg_w;
  wire g_io_pma_14_cfg_r;  wire i_io_pma_14_cfg_r;
  wire [45:0] g_io_pma_14_addr;  wire [45:0] i_io_pma_14_addr;
  wire [47:0] g_io_pma_14_mask;  wire [47:0] i_io_pma_14_mask;
  wire g_io_pma_15_cfg_c;  wire i_io_pma_15_cfg_c;
  wire g_io_pma_15_cfg_atomic;  wire i_io_pma_15_cfg_atomic;
  wire [1:0] g_io_pma_15_cfg_a;  wire [1:0] i_io_pma_15_cfg_a;
  wire g_io_pma_15_cfg_x;  wire i_io_pma_15_cfg_x;
  wire g_io_pma_15_cfg_w;  wire i_io_pma_15_cfg_w;
  wire g_io_pma_15_cfg_r;  wire i_io_pma_15_cfg_r;
  wire [45:0] g_io_pma_15_addr;  wire [45:0] i_io_pma_15_addr;
  wire [47:0] g_io_pma_15_mask;  wire [47:0] i_io_pma_15_mask;
  logic [11:0] addr_pool [];
  initial begin
    addr_pool = new[36];
    addr_pool[0]=12'h3A0; addr_pool[1]=12'h3A2;
    for (int i=0;i<16;i++) addr_pool[2+i]=12'h3B0+i[11:0];
    addr_pool[18]=12'h7C0; addr_pool[19]=12'h7C2;
    for (int i=0;i<16;i++) addr_pool[20+i]=12'h7C8+i[11:0];
  end
  PMP g_u (.clock(clock), .reset(reset), .io_distribute_csr_w_valid(io_distribute_csr_w_valid), .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr), .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data), .io_pmp_0_cfg_l(g_io_pmp_0_cfg_l), .io_pmp_0_cfg_a(g_io_pmp_0_cfg_a), .io_pmp_0_cfg_x(g_io_pmp_0_cfg_x), .io_pmp_0_cfg_w(g_io_pmp_0_cfg_w), .io_pmp_0_cfg_r(g_io_pmp_0_cfg_r), .io_pmp_0_addr(g_io_pmp_0_addr), .io_pmp_0_mask(g_io_pmp_0_mask), .io_pmp_1_cfg_l(g_io_pmp_1_cfg_l), .io_pmp_1_cfg_a(g_io_pmp_1_cfg_a), .io_pmp_1_cfg_x(g_io_pmp_1_cfg_x), .io_pmp_1_cfg_w(g_io_pmp_1_cfg_w), .io_pmp_1_cfg_r(g_io_pmp_1_cfg_r), .io_pmp_1_addr(g_io_pmp_1_addr), .io_pmp_1_mask(g_io_pmp_1_mask), .io_pmp_2_cfg_l(g_io_pmp_2_cfg_l), .io_pmp_2_cfg_a(g_io_pmp_2_cfg_a), .io_pmp_2_cfg_x(g_io_pmp_2_cfg_x), .io_pmp_2_cfg_w(g_io_pmp_2_cfg_w), .io_pmp_2_cfg_r(g_io_pmp_2_cfg_r), .io_pmp_2_addr(g_io_pmp_2_addr), .io_pmp_2_mask(g_io_pmp_2_mask), .io_pmp_3_cfg_l(g_io_pmp_3_cfg_l), .io_pmp_3_cfg_a(g_io_pmp_3_cfg_a), .io_pmp_3_cfg_x(g_io_pmp_3_cfg_x), .io_pmp_3_cfg_w(g_io_pmp_3_cfg_w), .io_pmp_3_cfg_r(g_io_pmp_3_cfg_r), .io_pmp_3_addr(g_io_pmp_3_addr), .io_pmp_3_mask(g_io_pmp_3_mask), .io_pmp_4_cfg_l(g_io_pmp_4_cfg_l), .io_pmp_4_cfg_a(g_io_pmp_4_cfg_a), .io_pmp_4_cfg_x(g_io_pmp_4_cfg_x), .io_pmp_4_cfg_w(g_io_pmp_4_cfg_w), .io_pmp_4_cfg_r(g_io_pmp_4_cfg_r), .io_pmp_4_addr(g_io_pmp_4_addr), .io_pmp_4_mask(g_io_pmp_4_mask), .io_pmp_5_cfg_l(g_io_pmp_5_cfg_l), .io_pmp_5_cfg_a(g_io_pmp_5_cfg_a), .io_pmp_5_cfg_x(g_io_pmp_5_cfg_x), .io_pmp_5_cfg_w(g_io_pmp_5_cfg_w), .io_pmp_5_cfg_r(g_io_pmp_5_cfg_r), .io_pmp_5_addr(g_io_pmp_5_addr), .io_pmp_5_mask(g_io_pmp_5_mask), .io_pmp_6_cfg_l(g_io_pmp_6_cfg_l), .io_pmp_6_cfg_a(g_io_pmp_6_cfg_a), .io_pmp_6_cfg_x(g_io_pmp_6_cfg_x), .io_pmp_6_cfg_w(g_io_pmp_6_cfg_w), .io_pmp_6_cfg_r(g_io_pmp_6_cfg_r), .io_pmp_6_addr(g_io_pmp_6_addr), .io_pmp_6_mask(g_io_pmp_6_mask), .io_pmp_7_cfg_l(g_io_pmp_7_cfg_l), .io_pmp_7_cfg_a(g_io_pmp_7_cfg_a), .io_pmp_7_cfg_x(g_io_pmp_7_cfg_x), .io_pmp_7_cfg_w(g_io_pmp_7_cfg_w), .io_pmp_7_cfg_r(g_io_pmp_7_cfg_r), .io_pmp_7_addr(g_io_pmp_7_addr), .io_pmp_7_mask(g_io_pmp_7_mask), .io_pmp_8_cfg_l(g_io_pmp_8_cfg_l), .io_pmp_8_cfg_a(g_io_pmp_8_cfg_a), .io_pmp_8_cfg_x(g_io_pmp_8_cfg_x), .io_pmp_8_cfg_w(g_io_pmp_8_cfg_w), .io_pmp_8_cfg_r(g_io_pmp_8_cfg_r), .io_pmp_8_addr(g_io_pmp_8_addr), .io_pmp_8_mask(g_io_pmp_8_mask), .io_pmp_9_cfg_l(g_io_pmp_9_cfg_l), .io_pmp_9_cfg_a(g_io_pmp_9_cfg_a), .io_pmp_9_cfg_x(g_io_pmp_9_cfg_x), .io_pmp_9_cfg_w(g_io_pmp_9_cfg_w), .io_pmp_9_cfg_r(g_io_pmp_9_cfg_r), .io_pmp_9_addr(g_io_pmp_9_addr), .io_pmp_9_mask(g_io_pmp_9_mask), .io_pmp_10_cfg_l(g_io_pmp_10_cfg_l), .io_pmp_10_cfg_a(g_io_pmp_10_cfg_a), .io_pmp_10_cfg_x(g_io_pmp_10_cfg_x), .io_pmp_10_cfg_w(g_io_pmp_10_cfg_w), .io_pmp_10_cfg_r(g_io_pmp_10_cfg_r), .io_pmp_10_addr(g_io_pmp_10_addr), .io_pmp_10_mask(g_io_pmp_10_mask), .io_pmp_11_cfg_l(g_io_pmp_11_cfg_l), .io_pmp_11_cfg_a(g_io_pmp_11_cfg_a), .io_pmp_11_cfg_x(g_io_pmp_11_cfg_x), .io_pmp_11_cfg_w(g_io_pmp_11_cfg_w), .io_pmp_11_cfg_r(g_io_pmp_11_cfg_r), .io_pmp_11_addr(g_io_pmp_11_addr), .io_pmp_11_mask(g_io_pmp_11_mask), .io_pmp_12_cfg_l(g_io_pmp_12_cfg_l), .io_pmp_12_cfg_a(g_io_pmp_12_cfg_a), .io_pmp_12_cfg_x(g_io_pmp_12_cfg_x), .io_pmp_12_cfg_w(g_io_pmp_12_cfg_w), .io_pmp_12_cfg_r(g_io_pmp_12_cfg_r), .io_pmp_12_addr(g_io_pmp_12_addr), .io_pmp_12_mask(g_io_pmp_12_mask), .io_pmp_13_cfg_l(g_io_pmp_13_cfg_l), .io_pmp_13_cfg_a(g_io_pmp_13_cfg_a), .io_pmp_13_cfg_x(g_io_pmp_13_cfg_x), .io_pmp_13_cfg_w(g_io_pmp_13_cfg_w), .io_pmp_13_cfg_r(g_io_pmp_13_cfg_r), .io_pmp_13_addr(g_io_pmp_13_addr), .io_pmp_13_mask(g_io_pmp_13_mask), .io_pmp_14_cfg_l(g_io_pmp_14_cfg_l), .io_pmp_14_cfg_a(g_io_pmp_14_cfg_a), .io_pmp_14_cfg_x(g_io_pmp_14_cfg_x), .io_pmp_14_cfg_w(g_io_pmp_14_cfg_w), .io_pmp_14_cfg_r(g_io_pmp_14_cfg_r), .io_pmp_14_addr(g_io_pmp_14_addr), .io_pmp_14_mask(g_io_pmp_14_mask), .io_pmp_15_cfg_l(g_io_pmp_15_cfg_l), .io_pmp_15_cfg_a(g_io_pmp_15_cfg_a), .io_pmp_15_cfg_x(g_io_pmp_15_cfg_x), .io_pmp_15_cfg_w(g_io_pmp_15_cfg_w), .io_pmp_15_cfg_r(g_io_pmp_15_cfg_r), .io_pmp_15_addr(g_io_pmp_15_addr), .io_pmp_15_mask(g_io_pmp_15_mask), .io_pma_0_cfg_c(g_io_pma_0_cfg_c), .io_pma_0_cfg_atomic(g_io_pma_0_cfg_atomic), .io_pma_0_cfg_a(g_io_pma_0_cfg_a), .io_pma_0_cfg_x(g_io_pma_0_cfg_x), .io_pma_0_cfg_w(g_io_pma_0_cfg_w), .io_pma_0_cfg_r(g_io_pma_0_cfg_r), .io_pma_0_addr(g_io_pma_0_addr), .io_pma_0_mask(g_io_pma_0_mask), .io_pma_1_cfg_c(g_io_pma_1_cfg_c), .io_pma_1_cfg_atomic(g_io_pma_1_cfg_atomic), .io_pma_1_cfg_a(g_io_pma_1_cfg_a), .io_pma_1_cfg_x(g_io_pma_1_cfg_x), .io_pma_1_cfg_w(g_io_pma_1_cfg_w), .io_pma_1_cfg_r(g_io_pma_1_cfg_r), .io_pma_1_addr(g_io_pma_1_addr), .io_pma_1_mask(g_io_pma_1_mask), .io_pma_2_cfg_c(g_io_pma_2_cfg_c), .io_pma_2_cfg_atomic(g_io_pma_2_cfg_atomic), .io_pma_2_cfg_a(g_io_pma_2_cfg_a), .io_pma_2_cfg_x(g_io_pma_2_cfg_x), .io_pma_2_cfg_w(g_io_pma_2_cfg_w), .io_pma_2_cfg_r(g_io_pma_2_cfg_r), .io_pma_2_addr(g_io_pma_2_addr), .io_pma_2_mask(g_io_pma_2_mask), .io_pma_3_cfg_c(g_io_pma_3_cfg_c), .io_pma_3_cfg_atomic(g_io_pma_3_cfg_atomic), .io_pma_3_cfg_a(g_io_pma_3_cfg_a), .io_pma_3_cfg_x(g_io_pma_3_cfg_x), .io_pma_3_cfg_w(g_io_pma_3_cfg_w), .io_pma_3_cfg_r(g_io_pma_3_cfg_r), .io_pma_3_addr(g_io_pma_3_addr), .io_pma_3_mask(g_io_pma_3_mask), .io_pma_4_cfg_c(g_io_pma_4_cfg_c), .io_pma_4_cfg_atomic(g_io_pma_4_cfg_atomic), .io_pma_4_cfg_a(g_io_pma_4_cfg_a), .io_pma_4_cfg_x(g_io_pma_4_cfg_x), .io_pma_4_cfg_w(g_io_pma_4_cfg_w), .io_pma_4_cfg_r(g_io_pma_4_cfg_r), .io_pma_4_addr(g_io_pma_4_addr), .io_pma_4_mask(g_io_pma_4_mask), .io_pma_5_cfg_c(g_io_pma_5_cfg_c), .io_pma_5_cfg_atomic(g_io_pma_5_cfg_atomic), .io_pma_5_cfg_a(g_io_pma_5_cfg_a), .io_pma_5_cfg_x(g_io_pma_5_cfg_x), .io_pma_5_cfg_w(g_io_pma_5_cfg_w), .io_pma_5_cfg_r(g_io_pma_5_cfg_r), .io_pma_5_addr(g_io_pma_5_addr), .io_pma_5_mask(g_io_pma_5_mask), .io_pma_6_cfg_c(g_io_pma_6_cfg_c), .io_pma_6_cfg_atomic(g_io_pma_6_cfg_atomic), .io_pma_6_cfg_a(g_io_pma_6_cfg_a), .io_pma_6_cfg_x(g_io_pma_6_cfg_x), .io_pma_6_cfg_w(g_io_pma_6_cfg_w), .io_pma_6_cfg_r(g_io_pma_6_cfg_r), .io_pma_6_addr(g_io_pma_6_addr), .io_pma_6_mask(g_io_pma_6_mask), .io_pma_7_cfg_c(g_io_pma_7_cfg_c), .io_pma_7_cfg_atomic(g_io_pma_7_cfg_atomic), .io_pma_7_cfg_a(g_io_pma_7_cfg_a), .io_pma_7_cfg_x(g_io_pma_7_cfg_x), .io_pma_7_cfg_w(g_io_pma_7_cfg_w), .io_pma_7_cfg_r(g_io_pma_7_cfg_r), .io_pma_7_addr(g_io_pma_7_addr), .io_pma_7_mask(g_io_pma_7_mask), .io_pma_8_cfg_c(g_io_pma_8_cfg_c), .io_pma_8_cfg_atomic(g_io_pma_8_cfg_atomic), .io_pma_8_cfg_a(g_io_pma_8_cfg_a), .io_pma_8_cfg_x(g_io_pma_8_cfg_x), .io_pma_8_cfg_w(g_io_pma_8_cfg_w), .io_pma_8_cfg_r(g_io_pma_8_cfg_r), .io_pma_8_addr(g_io_pma_8_addr), .io_pma_8_mask(g_io_pma_8_mask), .io_pma_9_cfg_c(g_io_pma_9_cfg_c), .io_pma_9_cfg_atomic(g_io_pma_9_cfg_atomic), .io_pma_9_cfg_a(g_io_pma_9_cfg_a), .io_pma_9_cfg_x(g_io_pma_9_cfg_x), .io_pma_9_cfg_w(g_io_pma_9_cfg_w), .io_pma_9_cfg_r(g_io_pma_9_cfg_r), .io_pma_9_addr(g_io_pma_9_addr), .io_pma_9_mask(g_io_pma_9_mask), .io_pma_10_cfg_c(g_io_pma_10_cfg_c), .io_pma_10_cfg_atomic(g_io_pma_10_cfg_atomic), .io_pma_10_cfg_a(g_io_pma_10_cfg_a), .io_pma_10_cfg_x(g_io_pma_10_cfg_x), .io_pma_10_cfg_w(g_io_pma_10_cfg_w), .io_pma_10_cfg_r(g_io_pma_10_cfg_r), .io_pma_10_addr(g_io_pma_10_addr), .io_pma_10_mask(g_io_pma_10_mask), .io_pma_11_cfg_c(g_io_pma_11_cfg_c), .io_pma_11_cfg_atomic(g_io_pma_11_cfg_atomic), .io_pma_11_cfg_a(g_io_pma_11_cfg_a), .io_pma_11_cfg_x(g_io_pma_11_cfg_x), .io_pma_11_cfg_w(g_io_pma_11_cfg_w), .io_pma_11_cfg_r(g_io_pma_11_cfg_r), .io_pma_11_addr(g_io_pma_11_addr), .io_pma_11_mask(g_io_pma_11_mask), .io_pma_12_cfg_c(g_io_pma_12_cfg_c), .io_pma_12_cfg_atomic(g_io_pma_12_cfg_atomic), .io_pma_12_cfg_a(g_io_pma_12_cfg_a), .io_pma_12_cfg_x(g_io_pma_12_cfg_x), .io_pma_12_cfg_w(g_io_pma_12_cfg_w), .io_pma_12_cfg_r(g_io_pma_12_cfg_r), .io_pma_12_addr(g_io_pma_12_addr), .io_pma_12_mask(g_io_pma_12_mask), .io_pma_13_cfg_c(g_io_pma_13_cfg_c), .io_pma_13_cfg_atomic(g_io_pma_13_cfg_atomic), .io_pma_13_cfg_a(g_io_pma_13_cfg_a), .io_pma_13_cfg_x(g_io_pma_13_cfg_x), .io_pma_13_cfg_w(g_io_pma_13_cfg_w), .io_pma_13_cfg_r(g_io_pma_13_cfg_r), .io_pma_13_addr(g_io_pma_13_addr), .io_pma_13_mask(g_io_pma_13_mask), .io_pma_14_cfg_c(g_io_pma_14_cfg_c), .io_pma_14_cfg_atomic(g_io_pma_14_cfg_atomic), .io_pma_14_cfg_a(g_io_pma_14_cfg_a), .io_pma_14_cfg_x(g_io_pma_14_cfg_x), .io_pma_14_cfg_w(g_io_pma_14_cfg_w), .io_pma_14_cfg_r(g_io_pma_14_cfg_r), .io_pma_14_addr(g_io_pma_14_addr), .io_pma_14_mask(g_io_pma_14_mask), .io_pma_15_cfg_c(g_io_pma_15_cfg_c), .io_pma_15_cfg_atomic(g_io_pma_15_cfg_atomic), .io_pma_15_cfg_a(g_io_pma_15_cfg_a), .io_pma_15_cfg_x(g_io_pma_15_cfg_x), .io_pma_15_cfg_w(g_io_pma_15_cfg_w), .io_pma_15_cfg_r(g_io_pma_15_cfg_r), .io_pma_15_addr(g_io_pma_15_addr), .io_pma_15_mask(g_io_pma_15_mask));
  PMP_xs i_u (.clock(clock), .reset(reset), .io_distribute_csr_w_valid(io_distribute_csr_w_valid), .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr), .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data), .io_pmp_0_cfg_l(i_io_pmp_0_cfg_l), .io_pmp_0_cfg_a(i_io_pmp_0_cfg_a), .io_pmp_0_cfg_x(i_io_pmp_0_cfg_x), .io_pmp_0_cfg_w(i_io_pmp_0_cfg_w), .io_pmp_0_cfg_r(i_io_pmp_0_cfg_r), .io_pmp_0_addr(i_io_pmp_0_addr), .io_pmp_0_mask(i_io_pmp_0_mask), .io_pmp_1_cfg_l(i_io_pmp_1_cfg_l), .io_pmp_1_cfg_a(i_io_pmp_1_cfg_a), .io_pmp_1_cfg_x(i_io_pmp_1_cfg_x), .io_pmp_1_cfg_w(i_io_pmp_1_cfg_w), .io_pmp_1_cfg_r(i_io_pmp_1_cfg_r), .io_pmp_1_addr(i_io_pmp_1_addr), .io_pmp_1_mask(i_io_pmp_1_mask), .io_pmp_2_cfg_l(i_io_pmp_2_cfg_l), .io_pmp_2_cfg_a(i_io_pmp_2_cfg_a), .io_pmp_2_cfg_x(i_io_pmp_2_cfg_x), .io_pmp_2_cfg_w(i_io_pmp_2_cfg_w), .io_pmp_2_cfg_r(i_io_pmp_2_cfg_r), .io_pmp_2_addr(i_io_pmp_2_addr), .io_pmp_2_mask(i_io_pmp_2_mask), .io_pmp_3_cfg_l(i_io_pmp_3_cfg_l), .io_pmp_3_cfg_a(i_io_pmp_3_cfg_a), .io_pmp_3_cfg_x(i_io_pmp_3_cfg_x), .io_pmp_3_cfg_w(i_io_pmp_3_cfg_w), .io_pmp_3_cfg_r(i_io_pmp_3_cfg_r), .io_pmp_3_addr(i_io_pmp_3_addr), .io_pmp_3_mask(i_io_pmp_3_mask), .io_pmp_4_cfg_l(i_io_pmp_4_cfg_l), .io_pmp_4_cfg_a(i_io_pmp_4_cfg_a), .io_pmp_4_cfg_x(i_io_pmp_4_cfg_x), .io_pmp_4_cfg_w(i_io_pmp_4_cfg_w), .io_pmp_4_cfg_r(i_io_pmp_4_cfg_r), .io_pmp_4_addr(i_io_pmp_4_addr), .io_pmp_4_mask(i_io_pmp_4_mask), .io_pmp_5_cfg_l(i_io_pmp_5_cfg_l), .io_pmp_5_cfg_a(i_io_pmp_5_cfg_a), .io_pmp_5_cfg_x(i_io_pmp_5_cfg_x), .io_pmp_5_cfg_w(i_io_pmp_5_cfg_w), .io_pmp_5_cfg_r(i_io_pmp_5_cfg_r), .io_pmp_5_addr(i_io_pmp_5_addr), .io_pmp_5_mask(i_io_pmp_5_mask), .io_pmp_6_cfg_l(i_io_pmp_6_cfg_l), .io_pmp_6_cfg_a(i_io_pmp_6_cfg_a), .io_pmp_6_cfg_x(i_io_pmp_6_cfg_x), .io_pmp_6_cfg_w(i_io_pmp_6_cfg_w), .io_pmp_6_cfg_r(i_io_pmp_6_cfg_r), .io_pmp_6_addr(i_io_pmp_6_addr), .io_pmp_6_mask(i_io_pmp_6_mask), .io_pmp_7_cfg_l(i_io_pmp_7_cfg_l), .io_pmp_7_cfg_a(i_io_pmp_7_cfg_a), .io_pmp_7_cfg_x(i_io_pmp_7_cfg_x), .io_pmp_7_cfg_w(i_io_pmp_7_cfg_w), .io_pmp_7_cfg_r(i_io_pmp_7_cfg_r), .io_pmp_7_addr(i_io_pmp_7_addr), .io_pmp_7_mask(i_io_pmp_7_mask), .io_pmp_8_cfg_l(i_io_pmp_8_cfg_l), .io_pmp_8_cfg_a(i_io_pmp_8_cfg_a), .io_pmp_8_cfg_x(i_io_pmp_8_cfg_x), .io_pmp_8_cfg_w(i_io_pmp_8_cfg_w), .io_pmp_8_cfg_r(i_io_pmp_8_cfg_r), .io_pmp_8_addr(i_io_pmp_8_addr), .io_pmp_8_mask(i_io_pmp_8_mask), .io_pmp_9_cfg_l(i_io_pmp_9_cfg_l), .io_pmp_9_cfg_a(i_io_pmp_9_cfg_a), .io_pmp_9_cfg_x(i_io_pmp_9_cfg_x), .io_pmp_9_cfg_w(i_io_pmp_9_cfg_w), .io_pmp_9_cfg_r(i_io_pmp_9_cfg_r), .io_pmp_9_addr(i_io_pmp_9_addr), .io_pmp_9_mask(i_io_pmp_9_mask), .io_pmp_10_cfg_l(i_io_pmp_10_cfg_l), .io_pmp_10_cfg_a(i_io_pmp_10_cfg_a), .io_pmp_10_cfg_x(i_io_pmp_10_cfg_x), .io_pmp_10_cfg_w(i_io_pmp_10_cfg_w), .io_pmp_10_cfg_r(i_io_pmp_10_cfg_r), .io_pmp_10_addr(i_io_pmp_10_addr), .io_pmp_10_mask(i_io_pmp_10_mask), .io_pmp_11_cfg_l(i_io_pmp_11_cfg_l), .io_pmp_11_cfg_a(i_io_pmp_11_cfg_a), .io_pmp_11_cfg_x(i_io_pmp_11_cfg_x), .io_pmp_11_cfg_w(i_io_pmp_11_cfg_w), .io_pmp_11_cfg_r(i_io_pmp_11_cfg_r), .io_pmp_11_addr(i_io_pmp_11_addr), .io_pmp_11_mask(i_io_pmp_11_mask), .io_pmp_12_cfg_l(i_io_pmp_12_cfg_l), .io_pmp_12_cfg_a(i_io_pmp_12_cfg_a), .io_pmp_12_cfg_x(i_io_pmp_12_cfg_x), .io_pmp_12_cfg_w(i_io_pmp_12_cfg_w), .io_pmp_12_cfg_r(i_io_pmp_12_cfg_r), .io_pmp_12_addr(i_io_pmp_12_addr), .io_pmp_12_mask(i_io_pmp_12_mask), .io_pmp_13_cfg_l(i_io_pmp_13_cfg_l), .io_pmp_13_cfg_a(i_io_pmp_13_cfg_a), .io_pmp_13_cfg_x(i_io_pmp_13_cfg_x), .io_pmp_13_cfg_w(i_io_pmp_13_cfg_w), .io_pmp_13_cfg_r(i_io_pmp_13_cfg_r), .io_pmp_13_addr(i_io_pmp_13_addr), .io_pmp_13_mask(i_io_pmp_13_mask), .io_pmp_14_cfg_l(i_io_pmp_14_cfg_l), .io_pmp_14_cfg_a(i_io_pmp_14_cfg_a), .io_pmp_14_cfg_x(i_io_pmp_14_cfg_x), .io_pmp_14_cfg_w(i_io_pmp_14_cfg_w), .io_pmp_14_cfg_r(i_io_pmp_14_cfg_r), .io_pmp_14_addr(i_io_pmp_14_addr), .io_pmp_14_mask(i_io_pmp_14_mask), .io_pmp_15_cfg_l(i_io_pmp_15_cfg_l), .io_pmp_15_cfg_a(i_io_pmp_15_cfg_a), .io_pmp_15_cfg_x(i_io_pmp_15_cfg_x), .io_pmp_15_cfg_w(i_io_pmp_15_cfg_w), .io_pmp_15_cfg_r(i_io_pmp_15_cfg_r), .io_pmp_15_addr(i_io_pmp_15_addr), .io_pmp_15_mask(i_io_pmp_15_mask), .io_pma_0_cfg_c(i_io_pma_0_cfg_c), .io_pma_0_cfg_atomic(i_io_pma_0_cfg_atomic), .io_pma_0_cfg_a(i_io_pma_0_cfg_a), .io_pma_0_cfg_x(i_io_pma_0_cfg_x), .io_pma_0_cfg_w(i_io_pma_0_cfg_w), .io_pma_0_cfg_r(i_io_pma_0_cfg_r), .io_pma_0_addr(i_io_pma_0_addr), .io_pma_0_mask(i_io_pma_0_mask), .io_pma_1_cfg_c(i_io_pma_1_cfg_c), .io_pma_1_cfg_atomic(i_io_pma_1_cfg_atomic), .io_pma_1_cfg_a(i_io_pma_1_cfg_a), .io_pma_1_cfg_x(i_io_pma_1_cfg_x), .io_pma_1_cfg_w(i_io_pma_1_cfg_w), .io_pma_1_cfg_r(i_io_pma_1_cfg_r), .io_pma_1_addr(i_io_pma_1_addr), .io_pma_1_mask(i_io_pma_1_mask), .io_pma_2_cfg_c(i_io_pma_2_cfg_c), .io_pma_2_cfg_atomic(i_io_pma_2_cfg_atomic), .io_pma_2_cfg_a(i_io_pma_2_cfg_a), .io_pma_2_cfg_x(i_io_pma_2_cfg_x), .io_pma_2_cfg_w(i_io_pma_2_cfg_w), .io_pma_2_cfg_r(i_io_pma_2_cfg_r), .io_pma_2_addr(i_io_pma_2_addr), .io_pma_2_mask(i_io_pma_2_mask), .io_pma_3_cfg_c(i_io_pma_3_cfg_c), .io_pma_3_cfg_atomic(i_io_pma_3_cfg_atomic), .io_pma_3_cfg_a(i_io_pma_3_cfg_a), .io_pma_3_cfg_x(i_io_pma_3_cfg_x), .io_pma_3_cfg_w(i_io_pma_3_cfg_w), .io_pma_3_cfg_r(i_io_pma_3_cfg_r), .io_pma_3_addr(i_io_pma_3_addr), .io_pma_3_mask(i_io_pma_3_mask), .io_pma_4_cfg_c(i_io_pma_4_cfg_c), .io_pma_4_cfg_atomic(i_io_pma_4_cfg_atomic), .io_pma_4_cfg_a(i_io_pma_4_cfg_a), .io_pma_4_cfg_x(i_io_pma_4_cfg_x), .io_pma_4_cfg_w(i_io_pma_4_cfg_w), .io_pma_4_cfg_r(i_io_pma_4_cfg_r), .io_pma_4_addr(i_io_pma_4_addr), .io_pma_4_mask(i_io_pma_4_mask), .io_pma_5_cfg_c(i_io_pma_5_cfg_c), .io_pma_5_cfg_atomic(i_io_pma_5_cfg_atomic), .io_pma_5_cfg_a(i_io_pma_5_cfg_a), .io_pma_5_cfg_x(i_io_pma_5_cfg_x), .io_pma_5_cfg_w(i_io_pma_5_cfg_w), .io_pma_5_cfg_r(i_io_pma_5_cfg_r), .io_pma_5_addr(i_io_pma_5_addr), .io_pma_5_mask(i_io_pma_5_mask), .io_pma_6_cfg_c(i_io_pma_6_cfg_c), .io_pma_6_cfg_atomic(i_io_pma_6_cfg_atomic), .io_pma_6_cfg_a(i_io_pma_6_cfg_a), .io_pma_6_cfg_x(i_io_pma_6_cfg_x), .io_pma_6_cfg_w(i_io_pma_6_cfg_w), .io_pma_6_cfg_r(i_io_pma_6_cfg_r), .io_pma_6_addr(i_io_pma_6_addr), .io_pma_6_mask(i_io_pma_6_mask), .io_pma_7_cfg_c(i_io_pma_7_cfg_c), .io_pma_7_cfg_atomic(i_io_pma_7_cfg_atomic), .io_pma_7_cfg_a(i_io_pma_7_cfg_a), .io_pma_7_cfg_x(i_io_pma_7_cfg_x), .io_pma_7_cfg_w(i_io_pma_7_cfg_w), .io_pma_7_cfg_r(i_io_pma_7_cfg_r), .io_pma_7_addr(i_io_pma_7_addr), .io_pma_7_mask(i_io_pma_7_mask), .io_pma_8_cfg_c(i_io_pma_8_cfg_c), .io_pma_8_cfg_atomic(i_io_pma_8_cfg_atomic), .io_pma_8_cfg_a(i_io_pma_8_cfg_a), .io_pma_8_cfg_x(i_io_pma_8_cfg_x), .io_pma_8_cfg_w(i_io_pma_8_cfg_w), .io_pma_8_cfg_r(i_io_pma_8_cfg_r), .io_pma_8_addr(i_io_pma_8_addr), .io_pma_8_mask(i_io_pma_8_mask), .io_pma_9_cfg_c(i_io_pma_9_cfg_c), .io_pma_9_cfg_atomic(i_io_pma_9_cfg_atomic), .io_pma_9_cfg_a(i_io_pma_9_cfg_a), .io_pma_9_cfg_x(i_io_pma_9_cfg_x), .io_pma_9_cfg_w(i_io_pma_9_cfg_w), .io_pma_9_cfg_r(i_io_pma_9_cfg_r), .io_pma_9_addr(i_io_pma_9_addr), .io_pma_9_mask(i_io_pma_9_mask), .io_pma_10_cfg_c(i_io_pma_10_cfg_c), .io_pma_10_cfg_atomic(i_io_pma_10_cfg_atomic), .io_pma_10_cfg_a(i_io_pma_10_cfg_a), .io_pma_10_cfg_x(i_io_pma_10_cfg_x), .io_pma_10_cfg_w(i_io_pma_10_cfg_w), .io_pma_10_cfg_r(i_io_pma_10_cfg_r), .io_pma_10_addr(i_io_pma_10_addr), .io_pma_10_mask(i_io_pma_10_mask), .io_pma_11_cfg_c(i_io_pma_11_cfg_c), .io_pma_11_cfg_atomic(i_io_pma_11_cfg_atomic), .io_pma_11_cfg_a(i_io_pma_11_cfg_a), .io_pma_11_cfg_x(i_io_pma_11_cfg_x), .io_pma_11_cfg_w(i_io_pma_11_cfg_w), .io_pma_11_cfg_r(i_io_pma_11_cfg_r), .io_pma_11_addr(i_io_pma_11_addr), .io_pma_11_mask(i_io_pma_11_mask), .io_pma_12_cfg_c(i_io_pma_12_cfg_c), .io_pma_12_cfg_atomic(i_io_pma_12_cfg_atomic), .io_pma_12_cfg_a(i_io_pma_12_cfg_a), .io_pma_12_cfg_x(i_io_pma_12_cfg_x), .io_pma_12_cfg_w(i_io_pma_12_cfg_w), .io_pma_12_cfg_r(i_io_pma_12_cfg_r), .io_pma_12_addr(i_io_pma_12_addr), .io_pma_12_mask(i_io_pma_12_mask), .io_pma_13_cfg_c(i_io_pma_13_cfg_c), .io_pma_13_cfg_atomic(i_io_pma_13_cfg_atomic), .io_pma_13_cfg_a(i_io_pma_13_cfg_a), .io_pma_13_cfg_x(i_io_pma_13_cfg_x), .io_pma_13_cfg_w(i_io_pma_13_cfg_w), .io_pma_13_cfg_r(i_io_pma_13_cfg_r), .io_pma_13_addr(i_io_pma_13_addr), .io_pma_13_mask(i_io_pma_13_mask), .io_pma_14_cfg_c(i_io_pma_14_cfg_c), .io_pma_14_cfg_atomic(i_io_pma_14_cfg_atomic), .io_pma_14_cfg_a(i_io_pma_14_cfg_a), .io_pma_14_cfg_x(i_io_pma_14_cfg_x), .io_pma_14_cfg_w(i_io_pma_14_cfg_w), .io_pma_14_cfg_r(i_io_pma_14_cfg_r), .io_pma_14_addr(i_io_pma_14_addr), .io_pma_14_mask(i_io_pma_14_mask), .io_pma_15_cfg_c(i_io_pma_15_cfg_c), .io_pma_15_cfg_atomic(i_io_pma_15_cfg_atomic), .io_pma_15_cfg_a(i_io_pma_15_cfg_a), .io_pma_15_cfg_x(i_io_pma_15_cfg_x), .io_pma_15_cfg_w(i_io_pma_15_cfg_w), .io_pma_15_cfg_r(i_io_pma_15_cfg_r), .io_pma_15_addr(i_io_pma_15_addr), .io_pma_15_mask(i_io_pma_15_mask));
  task automatic do_check(int t);
    checks++;
    if (g_io_pmp_0_cfg_l !== i_io_pmp_0_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_cfg_l: g=%h i=%h", t, g_io_pmp_0_cfg_l, i_io_pmp_0_cfg_l); end
    if (g_io_pmp_0_cfg_a !== i_io_pmp_0_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_cfg_a: g=%h i=%h", t, g_io_pmp_0_cfg_a, i_io_pmp_0_cfg_a); end
    if (g_io_pmp_0_cfg_x !== i_io_pmp_0_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_cfg_x: g=%h i=%h", t, g_io_pmp_0_cfg_x, i_io_pmp_0_cfg_x); end
    if (g_io_pmp_0_cfg_w !== i_io_pmp_0_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_cfg_w: g=%h i=%h", t, g_io_pmp_0_cfg_w, i_io_pmp_0_cfg_w); end
    if (g_io_pmp_0_cfg_r !== i_io_pmp_0_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_cfg_r: g=%h i=%h", t, g_io_pmp_0_cfg_r, i_io_pmp_0_cfg_r); end
    if (g_io_pmp_0_addr !== i_io_pmp_0_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_addr: g=%h i=%h", t, g_io_pmp_0_addr, i_io_pmp_0_addr); end
    if (g_io_pmp_0_mask !== i_io_pmp_0_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_0_mask: g=%h i=%h", t, g_io_pmp_0_mask, i_io_pmp_0_mask); end
    if (g_io_pmp_1_cfg_l !== i_io_pmp_1_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_cfg_l: g=%h i=%h", t, g_io_pmp_1_cfg_l, i_io_pmp_1_cfg_l); end
    if (g_io_pmp_1_cfg_a !== i_io_pmp_1_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_cfg_a: g=%h i=%h", t, g_io_pmp_1_cfg_a, i_io_pmp_1_cfg_a); end
    if (g_io_pmp_1_cfg_x !== i_io_pmp_1_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_cfg_x: g=%h i=%h", t, g_io_pmp_1_cfg_x, i_io_pmp_1_cfg_x); end
    if (g_io_pmp_1_cfg_w !== i_io_pmp_1_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_cfg_w: g=%h i=%h", t, g_io_pmp_1_cfg_w, i_io_pmp_1_cfg_w); end
    if (g_io_pmp_1_cfg_r !== i_io_pmp_1_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_cfg_r: g=%h i=%h", t, g_io_pmp_1_cfg_r, i_io_pmp_1_cfg_r); end
    if (g_io_pmp_1_addr !== i_io_pmp_1_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_addr: g=%h i=%h", t, g_io_pmp_1_addr, i_io_pmp_1_addr); end
    if (g_io_pmp_1_mask !== i_io_pmp_1_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_1_mask: g=%h i=%h", t, g_io_pmp_1_mask, i_io_pmp_1_mask); end
    if (g_io_pmp_2_cfg_l !== i_io_pmp_2_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_cfg_l: g=%h i=%h", t, g_io_pmp_2_cfg_l, i_io_pmp_2_cfg_l); end
    if (g_io_pmp_2_cfg_a !== i_io_pmp_2_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_cfg_a: g=%h i=%h", t, g_io_pmp_2_cfg_a, i_io_pmp_2_cfg_a); end
    if (g_io_pmp_2_cfg_x !== i_io_pmp_2_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_cfg_x: g=%h i=%h", t, g_io_pmp_2_cfg_x, i_io_pmp_2_cfg_x); end
    if (g_io_pmp_2_cfg_w !== i_io_pmp_2_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_cfg_w: g=%h i=%h", t, g_io_pmp_2_cfg_w, i_io_pmp_2_cfg_w); end
    if (g_io_pmp_2_cfg_r !== i_io_pmp_2_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_cfg_r: g=%h i=%h", t, g_io_pmp_2_cfg_r, i_io_pmp_2_cfg_r); end
    if (g_io_pmp_2_addr !== i_io_pmp_2_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_addr: g=%h i=%h", t, g_io_pmp_2_addr, i_io_pmp_2_addr); end
    if (g_io_pmp_2_mask !== i_io_pmp_2_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_2_mask: g=%h i=%h", t, g_io_pmp_2_mask, i_io_pmp_2_mask); end
    if (g_io_pmp_3_cfg_l !== i_io_pmp_3_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_cfg_l: g=%h i=%h", t, g_io_pmp_3_cfg_l, i_io_pmp_3_cfg_l); end
    if (g_io_pmp_3_cfg_a !== i_io_pmp_3_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_cfg_a: g=%h i=%h", t, g_io_pmp_3_cfg_a, i_io_pmp_3_cfg_a); end
    if (g_io_pmp_3_cfg_x !== i_io_pmp_3_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_cfg_x: g=%h i=%h", t, g_io_pmp_3_cfg_x, i_io_pmp_3_cfg_x); end
    if (g_io_pmp_3_cfg_w !== i_io_pmp_3_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_cfg_w: g=%h i=%h", t, g_io_pmp_3_cfg_w, i_io_pmp_3_cfg_w); end
    if (g_io_pmp_3_cfg_r !== i_io_pmp_3_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_cfg_r: g=%h i=%h", t, g_io_pmp_3_cfg_r, i_io_pmp_3_cfg_r); end
    if (g_io_pmp_3_addr !== i_io_pmp_3_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_addr: g=%h i=%h", t, g_io_pmp_3_addr, i_io_pmp_3_addr); end
    if (g_io_pmp_3_mask !== i_io_pmp_3_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_3_mask: g=%h i=%h", t, g_io_pmp_3_mask, i_io_pmp_3_mask); end
    if (g_io_pmp_4_cfg_l !== i_io_pmp_4_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_cfg_l: g=%h i=%h", t, g_io_pmp_4_cfg_l, i_io_pmp_4_cfg_l); end
    if (g_io_pmp_4_cfg_a !== i_io_pmp_4_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_cfg_a: g=%h i=%h", t, g_io_pmp_4_cfg_a, i_io_pmp_4_cfg_a); end
    if (g_io_pmp_4_cfg_x !== i_io_pmp_4_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_cfg_x: g=%h i=%h", t, g_io_pmp_4_cfg_x, i_io_pmp_4_cfg_x); end
    if (g_io_pmp_4_cfg_w !== i_io_pmp_4_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_cfg_w: g=%h i=%h", t, g_io_pmp_4_cfg_w, i_io_pmp_4_cfg_w); end
    if (g_io_pmp_4_cfg_r !== i_io_pmp_4_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_cfg_r: g=%h i=%h", t, g_io_pmp_4_cfg_r, i_io_pmp_4_cfg_r); end
    if (g_io_pmp_4_addr !== i_io_pmp_4_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_addr: g=%h i=%h", t, g_io_pmp_4_addr, i_io_pmp_4_addr); end
    if (g_io_pmp_4_mask !== i_io_pmp_4_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_4_mask: g=%h i=%h", t, g_io_pmp_4_mask, i_io_pmp_4_mask); end
    if (g_io_pmp_5_cfg_l !== i_io_pmp_5_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_cfg_l: g=%h i=%h", t, g_io_pmp_5_cfg_l, i_io_pmp_5_cfg_l); end
    if (g_io_pmp_5_cfg_a !== i_io_pmp_5_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_cfg_a: g=%h i=%h", t, g_io_pmp_5_cfg_a, i_io_pmp_5_cfg_a); end
    if (g_io_pmp_5_cfg_x !== i_io_pmp_5_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_cfg_x: g=%h i=%h", t, g_io_pmp_5_cfg_x, i_io_pmp_5_cfg_x); end
    if (g_io_pmp_5_cfg_w !== i_io_pmp_5_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_cfg_w: g=%h i=%h", t, g_io_pmp_5_cfg_w, i_io_pmp_5_cfg_w); end
    if (g_io_pmp_5_cfg_r !== i_io_pmp_5_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_cfg_r: g=%h i=%h", t, g_io_pmp_5_cfg_r, i_io_pmp_5_cfg_r); end
    if (g_io_pmp_5_addr !== i_io_pmp_5_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_addr: g=%h i=%h", t, g_io_pmp_5_addr, i_io_pmp_5_addr); end
    if (g_io_pmp_5_mask !== i_io_pmp_5_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_5_mask: g=%h i=%h", t, g_io_pmp_5_mask, i_io_pmp_5_mask); end
    if (g_io_pmp_6_cfg_l !== i_io_pmp_6_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_cfg_l: g=%h i=%h", t, g_io_pmp_6_cfg_l, i_io_pmp_6_cfg_l); end
    if (g_io_pmp_6_cfg_a !== i_io_pmp_6_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_cfg_a: g=%h i=%h", t, g_io_pmp_6_cfg_a, i_io_pmp_6_cfg_a); end
    if (g_io_pmp_6_cfg_x !== i_io_pmp_6_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_cfg_x: g=%h i=%h", t, g_io_pmp_6_cfg_x, i_io_pmp_6_cfg_x); end
    if (g_io_pmp_6_cfg_w !== i_io_pmp_6_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_cfg_w: g=%h i=%h", t, g_io_pmp_6_cfg_w, i_io_pmp_6_cfg_w); end
    if (g_io_pmp_6_cfg_r !== i_io_pmp_6_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_cfg_r: g=%h i=%h", t, g_io_pmp_6_cfg_r, i_io_pmp_6_cfg_r); end
    if (g_io_pmp_6_addr !== i_io_pmp_6_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_addr: g=%h i=%h", t, g_io_pmp_6_addr, i_io_pmp_6_addr); end
    if (g_io_pmp_6_mask !== i_io_pmp_6_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_6_mask: g=%h i=%h", t, g_io_pmp_6_mask, i_io_pmp_6_mask); end
    if (g_io_pmp_7_cfg_l !== i_io_pmp_7_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_cfg_l: g=%h i=%h", t, g_io_pmp_7_cfg_l, i_io_pmp_7_cfg_l); end
    if (g_io_pmp_7_cfg_a !== i_io_pmp_7_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_cfg_a: g=%h i=%h", t, g_io_pmp_7_cfg_a, i_io_pmp_7_cfg_a); end
    if (g_io_pmp_7_cfg_x !== i_io_pmp_7_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_cfg_x: g=%h i=%h", t, g_io_pmp_7_cfg_x, i_io_pmp_7_cfg_x); end
    if (g_io_pmp_7_cfg_w !== i_io_pmp_7_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_cfg_w: g=%h i=%h", t, g_io_pmp_7_cfg_w, i_io_pmp_7_cfg_w); end
    if (g_io_pmp_7_cfg_r !== i_io_pmp_7_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_cfg_r: g=%h i=%h", t, g_io_pmp_7_cfg_r, i_io_pmp_7_cfg_r); end
    if (g_io_pmp_7_addr !== i_io_pmp_7_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_addr: g=%h i=%h", t, g_io_pmp_7_addr, i_io_pmp_7_addr); end
    if (g_io_pmp_7_mask !== i_io_pmp_7_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_7_mask: g=%h i=%h", t, g_io_pmp_7_mask, i_io_pmp_7_mask); end
    if (g_io_pmp_8_cfg_l !== i_io_pmp_8_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_cfg_l: g=%h i=%h", t, g_io_pmp_8_cfg_l, i_io_pmp_8_cfg_l); end
    if (g_io_pmp_8_cfg_a !== i_io_pmp_8_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_cfg_a: g=%h i=%h", t, g_io_pmp_8_cfg_a, i_io_pmp_8_cfg_a); end
    if (g_io_pmp_8_cfg_x !== i_io_pmp_8_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_cfg_x: g=%h i=%h", t, g_io_pmp_8_cfg_x, i_io_pmp_8_cfg_x); end
    if (g_io_pmp_8_cfg_w !== i_io_pmp_8_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_cfg_w: g=%h i=%h", t, g_io_pmp_8_cfg_w, i_io_pmp_8_cfg_w); end
    if (g_io_pmp_8_cfg_r !== i_io_pmp_8_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_cfg_r: g=%h i=%h", t, g_io_pmp_8_cfg_r, i_io_pmp_8_cfg_r); end
    if (g_io_pmp_8_addr !== i_io_pmp_8_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_addr: g=%h i=%h", t, g_io_pmp_8_addr, i_io_pmp_8_addr); end
    if (g_io_pmp_8_mask !== i_io_pmp_8_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_8_mask: g=%h i=%h", t, g_io_pmp_8_mask, i_io_pmp_8_mask); end
    if (g_io_pmp_9_cfg_l !== i_io_pmp_9_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_cfg_l: g=%h i=%h", t, g_io_pmp_9_cfg_l, i_io_pmp_9_cfg_l); end
    if (g_io_pmp_9_cfg_a !== i_io_pmp_9_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_cfg_a: g=%h i=%h", t, g_io_pmp_9_cfg_a, i_io_pmp_9_cfg_a); end
    if (g_io_pmp_9_cfg_x !== i_io_pmp_9_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_cfg_x: g=%h i=%h", t, g_io_pmp_9_cfg_x, i_io_pmp_9_cfg_x); end
    if (g_io_pmp_9_cfg_w !== i_io_pmp_9_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_cfg_w: g=%h i=%h", t, g_io_pmp_9_cfg_w, i_io_pmp_9_cfg_w); end
    if (g_io_pmp_9_cfg_r !== i_io_pmp_9_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_cfg_r: g=%h i=%h", t, g_io_pmp_9_cfg_r, i_io_pmp_9_cfg_r); end
    if (g_io_pmp_9_addr !== i_io_pmp_9_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_addr: g=%h i=%h", t, g_io_pmp_9_addr, i_io_pmp_9_addr); end
    if (g_io_pmp_9_mask !== i_io_pmp_9_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_9_mask: g=%h i=%h", t, g_io_pmp_9_mask, i_io_pmp_9_mask); end
    if (g_io_pmp_10_cfg_l !== i_io_pmp_10_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_cfg_l: g=%h i=%h", t, g_io_pmp_10_cfg_l, i_io_pmp_10_cfg_l); end
    if (g_io_pmp_10_cfg_a !== i_io_pmp_10_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_cfg_a: g=%h i=%h", t, g_io_pmp_10_cfg_a, i_io_pmp_10_cfg_a); end
    if (g_io_pmp_10_cfg_x !== i_io_pmp_10_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_cfg_x: g=%h i=%h", t, g_io_pmp_10_cfg_x, i_io_pmp_10_cfg_x); end
    if (g_io_pmp_10_cfg_w !== i_io_pmp_10_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_cfg_w: g=%h i=%h", t, g_io_pmp_10_cfg_w, i_io_pmp_10_cfg_w); end
    if (g_io_pmp_10_cfg_r !== i_io_pmp_10_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_cfg_r: g=%h i=%h", t, g_io_pmp_10_cfg_r, i_io_pmp_10_cfg_r); end
    if (g_io_pmp_10_addr !== i_io_pmp_10_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_addr: g=%h i=%h", t, g_io_pmp_10_addr, i_io_pmp_10_addr); end
    if (g_io_pmp_10_mask !== i_io_pmp_10_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_10_mask: g=%h i=%h", t, g_io_pmp_10_mask, i_io_pmp_10_mask); end
    if (g_io_pmp_11_cfg_l !== i_io_pmp_11_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_cfg_l: g=%h i=%h", t, g_io_pmp_11_cfg_l, i_io_pmp_11_cfg_l); end
    if (g_io_pmp_11_cfg_a !== i_io_pmp_11_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_cfg_a: g=%h i=%h", t, g_io_pmp_11_cfg_a, i_io_pmp_11_cfg_a); end
    if (g_io_pmp_11_cfg_x !== i_io_pmp_11_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_cfg_x: g=%h i=%h", t, g_io_pmp_11_cfg_x, i_io_pmp_11_cfg_x); end
    if (g_io_pmp_11_cfg_w !== i_io_pmp_11_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_cfg_w: g=%h i=%h", t, g_io_pmp_11_cfg_w, i_io_pmp_11_cfg_w); end
    if (g_io_pmp_11_cfg_r !== i_io_pmp_11_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_cfg_r: g=%h i=%h", t, g_io_pmp_11_cfg_r, i_io_pmp_11_cfg_r); end
    if (g_io_pmp_11_addr !== i_io_pmp_11_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_addr: g=%h i=%h", t, g_io_pmp_11_addr, i_io_pmp_11_addr); end
    if (g_io_pmp_11_mask !== i_io_pmp_11_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_11_mask: g=%h i=%h", t, g_io_pmp_11_mask, i_io_pmp_11_mask); end
    if (g_io_pmp_12_cfg_l !== i_io_pmp_12_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_cfg_l: g=%h i=%h", t, g_io_pmp_12_cfg_l, i_io_pmp_12_cfg_l); end
    if (g_io_pmp_12_cfg_a !== i_io_pmp_12_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_cfg_a: g=%h i=%h", t, g_io_pmp_12_cfg_a, i_io_pmp_12_cfg_a); end
    if (g_io_pmp_12_cfg_x !== i_io_pmp_12_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_cfg_x: g=%h i=%h", t, g_io_pmp_12_cfg_x, i_io_pmp_12_cfg_x); end
    if (g_io_pmp_12_cfg_w !== i_io_pmp_12_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_cfg_w: g=%h i=%h", t, g_io_pmp_12_cfg_w, i_io_pmp_12_cfg_w); end
    if (g_io_pmp_12_cfg_r !== i_io_pmp_12_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_cfg_r: g=%h i=%h", t, g_io_pmp_12_cfg_r, i_io_pmp_12_cfg_r); end
    if (g_io_pmp_12_addr !== i_io_pmp_12_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_addr: g=%h i=%h", t, g_io_pmp_12_addr, i_io_pmp_12_addr); end
    if (g_io_pmp_12_mask !== i_io_pmp_12_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_12_mask: g=%h i=%h", t, g_io_pmp_12_mask, i_io_pmp_12_mask); end
    if (g_io_pmp_13_cfg_l !== i_io_pmp_13_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_cfg_l: g=%h i=%h", t, g_io_pmp_13_cfg_l, i_io_pmp_13_cfg_l); end
    if (g_io_pmp_13_cfg_a !== i_io_pmp_13_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_cfg_a: g=%h i=%h", t, g_io_pmp_13_cfg_a, i_io_pmp_13_cfg_a); end
    if (g_io_pmp_13_cfg_x !== i_io_pmp_13_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_cfg_x: g=%h i=%h", t, g_io_pmp_13_cfg_x, i_io_pmp_13_cfg_x); end
    if (g_io_pmp_13_cfg_w !== i_io_pmp_13_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_cfg_w: g=%h i=%h", t, g_io_pmp_13_cfg_w, i_io_pmp_13_cfg_w); end
    if (g_io_pmp_13_cfg_r !== i_io_pmp_13_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_cfg_r: g=%h i=%h", t, g_io_pmp_13_cfg_r, i_io_pmp_13_cfg_r); end
    if (g_io_pmp_13_addr !== i_io_pmp_13_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_addr: g=%h i=%h", t, g_io_pmp_13_addr, i_io_pmp_13_addr); end
    if (g_io_pmp_13_mask !== i_io_pmp_13_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_13_mask: g=%h i=%h", t, g_io_pmp_13_mask, i_io_pmp_13_mask); end
    if (g_io_pmp_14_cfg_l !== i_io_pmp_14_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_cfg_l: g=%h i=%h", t, g_io_pmp_14_cfg_l, i_io_pmp_14_cfg_l); end
    if (g_io_pmp_14_cfg_a !== i_io_pmp_14_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_cfg_a: g=%h i=%h", t, g_io_pmp_14_cfg_a, i_io_pmp_14_cfg_a); end
    if (g_io_pmp_14_cfg_x !== i_io_pmp_14_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_cfg_x: g=%h i=%h", t, g_io_pmp_14_cfg_x, i_io_pmp_14_cfg_x); end
    if (g_io_pmp_14_cfg_w !== i_io_pmp_14_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_cfg_w: g=%h i=%h", t, g_io_pmp_14_cfg_w, i_io_pmp_14_cfg_w); end
    if (g_io_pmp_14_cfg_r !== i_io_pmp_14_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_cfg_r: g=%h i=%h", t, g_io_pmp_14_cfg_r, i_io_pmp_14_cfg_r); end
    if (g_io_pmp_14_addr !== i_io_pmp_14_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_addr: g=%h i=%h", t, g_io_pmp_14_addr, i_io_pmp_14_addr); end
    if (g_io_pmp_14_mask !== i_io_pmp_14_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_14_mask: g=%h i=%h", t, g_io_pmp_14_mask, i_io_pmp_14_mask); end
    if (g_io_pmp_15_cfg_l !== i_io_pmp_15_cfg_l) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_cfg_l: g=%h i=%h", t, g_io_pmp_15_cfg_l, i_io_pmp_15_cfg_l); end
    if (g_io_pmp_15_cfg_a !== i_io_pmp_15_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_cfg_a: g=%h i=%h", t, g_io_pmp_15_cfg_a, i_io_pmp_15_cfg_a); end
    if (g_io_pmp_15_cfg_x !== i_io_pmp_15_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_cfg_x: g=%h i=%h", t, g_io_pmp_15_cfg_x, i_io_pmp_15_cfg_x); end
    if (g_io_pmp_15_cfg_w !== i_io_pmp_15_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_cfg_w: g=%h i=%h", t, g_io_pmp_15_cfg_w, i_io_pmp_15_cfg_w); end
    if (g_io_pmp_15_cfg_r !== i_io_pmp_15_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_cfg_r: g=%h i=%h", t, g_io_pmp_15_cfg_r, i_io_pmp_15_cfg_r); end
    if (g_io_pmp_15_addr !== i_io_pmp_15_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_addr: g=%h i=%h", t, g_io_pmp_15_addr, i_io_pmp_15_addr); end
    if (g_io_pmp_15_mask !== i_io_pmp_15_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pmp_15_mask: g=%h i=%h", t, g_io_pmp_15_mask, i_io_pmp_15_mask); end
    if (g_io_pma_0_cfg_c !== i_io_pma_0_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_c: g=%h i=%h", t, g_io_pma_0_cfg_c, i_io_pma_0_cfg_c); end
    if (g_io_pma_0_cfg_atomic !== i_io_pma_0_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_atomic: g=%h i=%h", t, g_io_pma_0_cfg_atomic, i_io_pma_0_cfg_atomic); end
    if (g_io_pma_0_cfg_a !== i_io_pma_0_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_a: g=%h i=%h", t, g_io_pma_0_cfg_a, i_io_pma_0_cfg_a); end
    if (g_io_pma_0_cfg_x !== i_io_pma_0_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_x: g=%h i=%h", t, g_io_pma_0_cfg_x, i_io_pma_0_cfg_x); end
    if (g_io_pma_0_cfg_w !== i_io_pma_0_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_w: g=%h i=%h", t, g_io_pma_0_cfg_w, i_io_pma_0_cfg_w); end
    if (g_io_pma_0_cfg_r !== i_io_pma_0_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_cfg_r: g=%h i=%h", t, g_io_pma_0_cfg_r, i_io_pma_0_cfg_r); end
    if (g_io_pma_0_addr !== i_io_pma_0_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_addr: g=%h i=%h", t, g_io_pma_0_addr, i_io_pma_0_addr); end
    if (g_io_pma_0_mask !== i_io_pma_0_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_0_mask: g=%h i=%h", t, g_io_pma_0_mask, i_io_pma_0_mask); end
    if (g_io_pma_1_cfg_c !== i_io_pma_1_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_c: g=%h i=%h", t, g_io_pma_1_cfg_c, i_io_pma_1_cfg_c); end
    if (g_io_pma_1_cfg_atomic !== i_io_pma_1_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_atomic: g=%h i=%h", t, g_io_pma_1_cfg_atomic, i_io_pma_1_cfg_atomic); end
    if (g_io_pma_1_cfg_a !== i_io_pma_1_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_a: g=%h i=%h", t, g_io_pma_1_cfg_a, i_io_pma_1_cfg_a); end
    if (g_io_pma_1_cfg_x !== i_io_pma_1_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_x: g=%h i=%h", t, g_io_pma_1_cfg_x, i_io_pma_1_cfg_x); end
    if (g_io_pma_1_cfg_w !== i_io_pma_1_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_w: g=%h i=%h", t, g_io_pma_1_cfg_w, i_io_pma_1_cfg_w); end
    if (g_io_pma_1_cfg_r !== i_io_pma_1_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_cfg_r: g=%h i=%h", t, g_io_pma_1_cfg_r, i_io_pma_1_cfg_r); end
    if (g_io_pma_1_addr !== i_io_pma_1_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_addr: g=%h i=%h", t, g_io_pma_1_addr, i_io_pma_1_addr); end
    if (g_io_pma_1_mask !== i_io_pma_1_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_1_mask: g=%h i=%h", t, g_io_pma_1_mask, i_io_pma_1_mask); end
    if (g_io_pma_2_cfg_c !== i_io_pma_2_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_c: g=%h i=%h", t, g_io_pma_2_cfg_c, i_io_pma_2_cfg_c); end
    if (g_io_pma_2_cfg_atomic !== i_io_pma_2_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_atomic: g=%h i=%h", t, g_io_pma_2_cfg_atomic, i_io_pma_2_cfg_atomic); end
    if (g_io_pma_2_cfg_a !== i_io_pma_2_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_a: g=%h i=%h", t, g_io_pma_2_cfg_a, i_io_pma_2_cfg_a); end
    if (g_io_pma_2_cfg_x !== i_io_pma_2_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_x: g=%h i=%h", t, g_io_pma_2_cfg_x, i_io_pma_2_cfg_x); end
    if (g_io_pma_2_cfg_w !== i_io_pma_2_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_w: g=%h i=%h", t, g_io_pma_2_cfg_w, i_io_pma_2_cfg_w); end
    if (g_io_pma_2_cfg_r !== i_io_pma_2_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_cfg_r: g=%h i=%h", t, g_io_pma_2_cfg_r, i_io_pma_2_cfg_r); end
    if (g_io_pma_2_addr !== i_io_pma_2_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_addr: g=%h i=%h", t, g_io_pma_2_addr, i_io_pma_2_addr); end
    if (g_io_pma_2_mask !== i_io_pma_2_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_2_mask: g=%h i=%h", t, g_io_pma_2_mask, i_io_pma_2_mask); end
    if (g_io_pma_3_cfg_c !== i_io_pma_3_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_c: g=%h i=%h", t, g_io_pma_3_cfg_c, i_io_pma_3_cfg_c); end
    if (g_io_pma_3_cfg_atomic !== i_io_pma_3_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_atomic: g=%h i=%h", t, g_io_pma_3_cfg_atomic, i_io_pma_3_cfg_atomic); end
    if (g_io_pma_3_cfg_a !== i_io_pma_3_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_a: g=%h i=%h", t, g_io_pma_3_cfg_a, i_io_pma_3_cfg_a); end
    if (g_io_pma_3_cfg_x !== i_io_pma_3_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_x: g=%h i=%h", t, g_io_pma_3_cfg_x, i_io_pma_3_cfg_x); end
    if (g_io_pma_3_cfg_w !== i_io_pma_3_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_w: g=%h i=%h", t, g_io_pma_3_cfg_w, i_io_pma_3_cfg_w); end
    if (g_io_pma_3_cfg_r !== i_io_pma_3_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_cfg_r: g=%h i=%h", t, g_io_pma_3_cfg_r, i_io_pma_3_cfg_r); end
    if (g_io_pma_3_addr !== i_io_pma_3_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_addr: g=%h i=%h", t, g_io_pma_3_addr, i_io_pma_3_addr); end
    if (g_io_pma_3_mask !== i_io_pma_3_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_3_mask: g=%h i=%h", t, g_io_pma_3_mask, i_io_pma_3_mask); end
    if (g_io_pma_4_cfg_c !== i_io_pma_4_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_c: g=%h i=%h", t, g_io_pma_4_cfg_c, i_io_pma_4_cfg_c); end
    if (g_io_pma_4_cfg_atomic !== i_io_pma_4_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_atomic: g=%h i=%h", t, g_io_pma_4_cfg_atomic, i_io_pma_4_cfg_atomic); end
    if (g_io_pma_4_cfg_a !== i_io_pma_4_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_a: g=%h i=%h", t, g_io_pma_4_cfg_a, i_io_pma_4_cfg_a); end
    if (g_io_pma_4_cfg_x !== i_io_pma_4_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_x: g=%h i=%h", t, g_io_pma_4_cfg_x, i_io_pma_4_cfg_x); end
    if (g_io_pma_4_cfg_w !== i_io_pma_4_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_w: g=%h i=%h", t, g_io_pma_4_cfg_w, i_io_pma_4_cfg_w); end
    if (g_io_pma_4_cfg_r !== i_io_pma_4_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_cfg_r: g=%h i=%h", t, g_io_pma_4_cfg_r, i_io_pma_4_cfg_r); end
    if (g_io_pma_4_addr !== i_io_pma_4_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_addr: g=%h i=%h", t, g_io_pma_4_addr, i_io_pma_4_addr); end
    if (g_io_pma_4_mask !== i_io_pma_4_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_4_mask: g=%h i=%h", t, g_io_pma_4_mask, i_io_pma_4_mask); end
    if (g_io_pma_5_cfg_c !== i_io_pma_5_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_c: g=%h i=%h", t, g_io_pma_5_cfg_c, i_io_pma_5_cfg_c); end
    if (g_io_pma_5_cfg_atomic !== i_io_pma_5_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_atomic: g=%h i=%h", t, g_io_pma_5_cfg_atomic, i_io_pma_5_cfg_atomic); end
    if (g_io_pma_5_cfg_a !== i_io_pma_5_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_a: g=%h i=%h", t, g_io_pma_5_cfg_a, i_io_pma_5_cfg_a); end
    if (g_io_pma_5_cfg_x !== i_io_pma_5_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_x: g=%h i=%h", t, g_io_pma_5_cfg_x, i_io_pma_5_cfg_x); end
    if (g_io_pma_5_cfg_w !== i_io_pma_5_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_w: g=%h i=%h", t, g_io_pma_5_cfg_w, i_io_pma_5_cfg_w); end
    if (g_io_pma_5_cfg_r !== i_io_pma_5_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_cfg_r: g=%h i=%h", t, g_io_pma_5_cfg_r, i_io_pma_5_cfg_r); end
    if (g_io_pma_5_addr !== i_io_pma_5_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_addr: g=%h i=%h", t, g_io_pma_5_addr, i_io_pma_5_addr); end
    if (g_io_pma_5_mask !== i_io_pma_5_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_5_mask: g=%h i=%h", t, g_io_pma_5_mask, i_io_pma_5_mask); end
    if (g_io_pma_6_cfg_c !== i_io_pma_6_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_c: g=%h i=%h", t, g_io_pma_6_cfg_c, i_io_pma_6_cfg_c); end
    if (g_io_pma_6_cfg_atomic !== i_io_pma_6_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_atomic: g=%h i=%h", t, g_io_pma_6_cfg_atomic, i_io_pma_6_cfg_atomic); end
    if (g_io_pma_6_cfg_a !== i_io_pma_6_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_a: g=%h i=%h", t, g_io_pma_6_cfg_a, i_io_pma_6_cfg_a); end
    if (g_io_pma_6_cfg_x !== i_io_pma_6_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_x: g=%h i=%h", t, g_io_pma_6_cfg_x, i_io_pma_6_cfg_x); end
    if (g_io_pma_6_cfg_w !== i_io_pma_6_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_w: g=%h i=%h", t, g_io_pma_6_cfg_w, i_io_pma_6_cfg_w); end
    if (g_io_pma_6_cfg_r !== i_io_pma_6_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_cfg_r: g=%h i=%h", t, g_io_pma_6_cfg_r, i_io_pma_6_cfg_r); end
    if (g_io_pma_6_addr !== i_io_pma_6_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_addr: g=%h i=%h", t, g_io_pma_6_addr, i_io_pma_6_addr); end
    if (g_io_pma_6_mask !== i_io_pma_6_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_6_mask: g=%h i=%h", t, g_io_pma_6_mask, i_io_pma_6_mask); end
    if (g_io_pma_7_cfg_c !== i_io_pma_7_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_c: g=%h i=%h", t, g_io_pma_7_cfg_c, i_io_pma_7_cfg_c); end
    if (g_io_pma_7_cfg_atomic !== i_io_pma_7_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_atomic: g=%h i=%h", t, g_io_pma_7_cfg_atomic, i_io_pma_7_cfg_atomic); end
    if (g_io_pma_7_cfg_a !== i_io_pma_7_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_a: g=%h i=%h", t, g_io_pma_7_cfg_a, i_io_pma_7_cfg_a); end
    if (g_io_pma_7_cfg_x !== i_io_pma_7_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_x: g=%h i=%h", t, g_io_pma_7_cfg_x, i_io_pma_7_cfg_x); end
    if (g_io_pma_7_cfg_w !== i_io_pma_7_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_w: g=%h i=%h", t, g_io_pma_7_cfg_w, i_io_pma_7_cfg_w); end
    if (g_io_pma_7_cfg_r !== i_io_pma_7_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_cfg_r: g=%h i=%h", t, g_io_pma_7_cfg_r, i_io_pma_7_cfg_r); end
    if (g_io_pma_7_addr !== i_io_pma_7_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_addr: g=%h i=%h", t, g_io_pma_7_addr, i_io_pma_7_addr); end
    if (g_io_pma_7_mask !== i_io_pma_7_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_7_mask: g=%h i=%h", t, g_io_pma_7_mask, i_io_pma_7_mask); end
    if (g_io_pma_8_cfg_c !== i_io_pma_8_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_c: g=%h i=%h", t, g_io_pma_8_cfg_c, i_io_pma_8_cfg_c); end
    if (g_io_pma_8_cfg_atomic !== i_io_pma_8_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_atomic: g=%h i=%h", t, g_io_pma_8_cfg_atomic, i_io_pma_8_cfg_atomic); end
    if (g_io_pma_8_cfg_a !== i_io_pma_8_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_a: g=%h i=%h", t, g_io_pma_8_cfg_a, i_io_pma_8_cfg_a); end
    if (g_io_pma_8_cfg_x !== i_io_pma_8_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_x: g=%h i=%h", t, g_io_pma_8_cfg_x, i_io_pma_8_cfg_x); end
    if (g_io_pma_8_cfg_w !== i_io_pma_8_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_w: g=%h i=%h", t, g_io_pma_8_cfg_w, i_io_pma_8_cfg_w); end
    if (g_io_pma_8_cfg_r !== i_io_pma_8_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_cfg_r: g=%h i=%h", t, g_io_pma_8_cfg_r, i_io_pma_8_cfg_r); end
    if (g_io_pma_8_addr !== i_io_pma_8_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_addr: g=%h i=%h", t, g_io_pma_8_addr, i_io_pma_8_addr); end
    if (g_io_pma_8_mask !== i_io_pma_8_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_8_mask: g=%h i=%h", t, g_io_pma_8_mask, i_io_pma_8_mask); end
    if (g_io_pma_9_cfg_c !== i_io_pma_9_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_c: g=%h i=%h", t, g_io_pma_9_cfg_c, i_io_pma_9_cfg_c); end
    if (g_io_pma_9_cfg_atomic !== i_io_pma_9_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_atomic: g=%h i=%h", t, g_io_pma_9_cfg_atomic, i_io_pma_9_cfg_atomic); end
    if (g_io_pma_9_cfg_a !== i_io_pma_9_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_a: g=%h i=%h", t, g_io_pma_9_cfg_a, i_io_pma_9_cfg_a); end
    if (g_io_pma_9_cfg_x !== i_io_pma_9_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_x: g=%h i=%h", t, g_io_pma_9_cfg_x, i_io_pma_9_cfg_x); end
    if (g_io_pma_9_cfg_w !== i_io_pma_9_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_w: g=%h i=%h", t, g_io_pma_9_cfg_w, i_io_pma_9_cfg_w); end
    if (g_io_pma_9_cfg_r !== i_io_pma_9_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_cfg_r: g=%h i=%h", t, g_io_pma_9_cfg_r, i_io_pma_9_cfg_r); end
    if (g_io_pma_9_addr !== i_io_pma_9_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_addr: g=%h i=%h", t, g_io_pma_9_addr, i_io_pma_9_addr); end
    if (g_io_pma_9_mask !== i_io_pma_9_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_9_mask: g=%h i=%h", t, g_io_pma_9_mask, i_io_pma_9_mask); end
    if (g_io_pma_10_cfg_c !== i_io_pma_10_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_c: g=%h i=%h", t, g_io_pma_10_cfg_c, i_io_pma_10_cfg_c); end
    if (g_io_pma_10_cfg_atomic !== i_io_pma_10_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_atomic: g=%h i=%h", t, g_io_pma_10_cfg_atomic, i_io_pma_10_cfg_atomic); end
    if (g_io_pma_10_cfg_a !== i_io_pma_10_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_a: g=%h i=%h", t, g_io_pma_10_cfg_a, i_io_pma_10_cfg_a); end
    if (g_io_pma_10_cfg_x !== i_io_pma_10_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_x: g=%h i=%h", t, g_io_pma_10_cfg_x, i_io_pma_10_cfg_x); end
    if (g_io_pma_10_cfg_w !== i_io_pma_10_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_w: g=%h i=%h", t, g_io_pma_10_cfg_w, i_io_pma_10_cfg_w); end
    if (g_io_pma_10_cfg_r !== i_io_pma_10_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_cfg_r: g=%h i=%h", t, g_io_pma_10_cfg_r, i_io_pma_10_cfg_r); end
    if (g_io_pma_10_addr !== i_io_pma_10_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_addr: g=%h i=%h", t, g_io_pma_10_addr, i_io_pma_10_addr); end
    if (g_io_pma_10_mask !== i_io_pma_10_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_10_mask: g=%h i=%h", t, g_io_pma_10_mask, i_io_pma_10_mask); end
    if (g_io_pma_11_cfg_c !== i_io_pma_11_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_c: g=%h i=%h", t, g_io_pma_11_cfg_c, i_io_pma_11_cfg_c); end
    if (g_io_pma_11_cfg_atomic !== i_io_pma_11_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_atomic: g=%h i=%h", t, g_io_pma_11_cfg_atomic, i_io_pma_11_cfg_atomic); end
    if (g_io_pma_11_cfg_a !== i_io_pma_11_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_a: g=%h i=%h", t, g_io_pma_11_cfg_a, i_io_pma_11_cfg_a); end
    if (g_io_pma_11_cfg_x !== i_io_pma_11_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_x: g=%h i=%h", t, g_io_pma_11_cfg_x, i_io_pma_11_cfg_x); end
    if (g_io_pma_11_cfg_w !== i_io_pma_11_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_w: g=%h i=%h", t, g_io_pma_11_cfg_w, i_io_pma_11_cfg_w); end
    if (g_io_pma_11_cfg_r !== i_io_pma_11_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_cfg_r: g=%h i=%h", t, g_io_pma_11_cfg_r, i_io_pma_11_cfg_r); end
    if (g_io_pma_11_addr !== i_io_pma_11_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_addr: g=%h i=%h", t, g_io_pma_11_addr, i_io_pma_11_addr); end
    if (g_io_pma_11_mask !== i_io_pma_11_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_11_mask: g=%h i=%h", t, g_io_pma_11_mask, i_io_pma_11_mask); end
    if (g_io_pma_12_cfg_c !== i_io_pma_12_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_c: g=%h i=%h", t, g_io_pma_12_cfg_c, i_io_pma_12_cfg_c); end
    if (g_io_pma_12_cfg_atomic !== i_io_pma_12_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_atomic: g=%h i=%h", t, g_io_pma_12_cfg_atomic, i_io_pma_12_cfg_atomic); end
    if (g_io_pma_12_cfg_a !== i_io_pma_12_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_a: g=%h i=%h", t, g_io_pma_12_cfg_a, i_io_pma_12_cfg_a); end
    if (g_io_pma_12_cfg_x !== i_io_pma_12_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_x: g=%h i=%h", t, g_io_pma_12_cfg_x, i_io_pma_12_cfg_x); end
    if (g_io_pma_12_cfg_w !== i_io_pma_12_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_w: g=%h i=%h", t, g_io_pma_12_cfg_w, i_io_pma_12_cfg_w); end
    if (g_io_pma_12_cfg_r !== i_io_pma_12_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_cfg_r: g=%h i=%h", t, g_io_pma_12_cfg_r, i_io_pma_12_cfg_r); end
    if (g_io_pma_12_addr !== i_io_pma_12_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_addr: g=%h i=%h", t, g_io_pma_12_addr, i_io_pma_12_addr); end
    if (g_io_pma_12_mask !== i_io_pma_12_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_12_mask: g=%h i=%h", t, g_io_pma_12_mask, i_io_pma_12_mask); end
    if (g_io_pma_13_cfg_c !== i_io_pma_13_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_c: g=%h i=%h", t, g_io_pma_13_cfg_c, i_io_pma_13_cfg_c); end
    if (g_io_pma_13_cfg_atomic !== i_io_pma_13_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_atomic: g=%h i=%h", t, g_io_pma_13_cfg_atomic, i_io_pma_13_cfg_atomic); end
    if (g_io_pma_13_cfg_a !== i_io_pma_13_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_a: g=%h i=%h", t, g_io_pma_13_cfg_a, i_io_pma_13_cfg_a); end
    if (g_io_pma_13_cfg_x !== i_io_pma_13_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_x: g=%h i=%h", t, g_io_pma_13_cfg_x, i_io_pma_13_cfg_x); end
    if (g_io_pma_13_cfg_w !== i_io_pma_13_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_w: g=%h i=%h", t, g_io_pma_13_cfg_w, i_io_pma_13_cfg_w); end
    if (g_io_pma_13_cfg_r !== i_io_pma_13_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_cfg_r: g=%h i=%h", t, g_io_pma_13_cfg_r, i_io_pma_13_cfg_r); end
    if (g_io_pma_13_addr !== i_io_pma_13_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_addr: g=%h i=%h", t, g_io_pma_13_addr, i_io_pma_13_addr); end
    if (g_io_pma_13_mask !== i_io_pma_13_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_13_mask: g=%h i=%h", t, g_io_pma_13_mask, i_io_pma_13_mask); end
    if (g_io_pma_14_cfg_c !== i_io_pma_14_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_c: g=%h i=%h", t, g_io_pma_14_cfg_c, i_io_pma_14_cfg_c); end
    if (g_io_pma_14_cfg_atomic !== i_io_pma_14_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_atomic: g=%h i=%h", t, g_io_pma_14_cfg_atomic, i_io_pma_14_cfg_atomic); end
    if (g_io_pma_14_cfg_a !== i_io_pma_14_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_a: g=%h i=%h", t, g_io_pma_14_cfg_a, i_io_pma_14_cfg_a); end
    if (g_io_pma_14_cfg_x !== i_io_pma_14_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_x: g=%h i=%h", t, g_io_pma_14_cfg_x, i_io_pma_14_cfg_x); end
    if (g_io_pma_14_cfg_w !== i_io_pma_14_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_w: g=%h i=%h", t, g_io_pma_14_cfg_w, i_io_pma_14_cfg_w); end
    if (g_io_pma_14_cfg_r !== i_io_pma_14_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_cfg_r: g=%h i=%h", t, g_io_pma_14_cfg_r, i_io_pma_14_cfg_r); end
    if (g_io_pma_14_addr !== i_io_pma_14_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_addr: g=%h i=%h", t, g_io_pma_14_addr, i_io_pma_14_addr); end
    if (g_io_pma_14_mask !== i_io_pma_14_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_14_mask: g=%h i=%h", t, g_io_pma_14_mask, i_io_pma_14_mask); end
    if (g_io_pma_15_cfg_c !== i_io_pma_15_cfg_c) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_c: g=%h i=%h", t, g_io_pma_15_cfg_c, i_io_pma_15_cfg_c); end
    if (g_io_pma_15_cfg_atomic !== i_io_pma_15_cfg_atomic) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_atomic: g=%h i=%h", t, g_io_pma_15_cfg_atomic, i_io_pma_15_cfg_atomic); end
    if (g_io_pma_15_cfg_a !== i_io_pma_15_cfg_a) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_a: g=%h i=%h", t, g_io_pma_15_cfg_a, i_io_pma_15_cfg_a); end
    if (g_io_pma_15_cfg_x !== i_io_pma_15_cfg_x) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_x: g=%h i=%h", t, g_io_pma_15_cfg_x, i_io_pma_15_cfg_x); end
    if (g_io_pma_15_cfg_w !== i_io_pma_15_cfg_w) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_w: g=%h i=%h", t, g_io_pma_15_cfg_w, i_io_pma_15_cfg_w); end
    if (g_io_pma_15_cfg_r !== i_io_pma_15_cfg_r) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_cfg_r: g=%h i=%h", t, g_io_pma_15_cfg_r, i_io_pma_15_cfg_r); end
    if (g_io_pma_15_addr !== i_io_pma_15_addr) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_addr: g=%h i=%h", t, g_io_pma_15_addr, i_io_pma_15_addr); end
    if (g_io_pma_15_mask !== i_io_pma_15_mask) begin errors++;
      if (errors<=40) $display("vec %0d io_pma_15_mask: g=%h i=%h", t, g_io_pma_15_mask, i_io_pma_15_mask); end
  endtask
  initial begin
    reset = 1; io_distribute_csr_w_valid = 0;
    io_distribute_csr_w_bits_addr = 0; io_distribute_csr_w_bits_data = 0;
    repeat (3) @(posedge clock); #1; reset = 0;
    @(posedge clock);
    for (int t = 0; t < NVEC; t++) begin
      // 多数拍发合法 CSR 写；偶发无写 / 随机非法地址
      automatic int kind = $urandom_range(0, 9);
      io_distribute_csr_w_valid = (kind != 0);
      if (kind <= 7)
        io_distribute_csr_w_bits_addr = addr_pool[$urandom_range(0, 35)];
      else
        io_distribute_csr_w_bits_addr = 12'($urandom);
      io_distribute_csr_w_bits_data = {$urandom, $urandom};
      @(posedge clock); #1;
      do_check(t);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
