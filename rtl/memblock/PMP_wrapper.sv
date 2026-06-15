// 自动生成：scripts/gen_pmp.py —— 勿手改
// PMP golden 同名/xs 变体扁平包装：扁平 CSR 端口 <-> 可读核 xs_PMP_core 的条目结构。
module PMP import xs_pmp_pkg::*; (
  input clock,
  input reset,
  input io_distribute_csr_w_valid,
  input [11:0] io_distribute_csr_w_bits_addr,
  input [63:0] io_distribute_csr_w_bits_data,
  output io_pmp_0_cfg_l,
  output [1:0] io_pmp_0_cfg_a,
  output io_pmp_0_cfg_x,
  output io_pmp_0_cfg_w,
  output io_pmp_0_cfg_r,
  output [45:0] io_pmp_0_addr,
  output [47:0] io_pmp_0_mask,
  output io_pmp_1_cfg_l,
  output [1:0] io_pmp_1_cfg_a,
  output io_pmp_1_cfg_x,
  output io_pmp_1_cfg_w,
  output io_pmp_1_cfg_r,
  output [45:0] io_pmp_1_addr,
  output [47:0] io_pmp_1_mask,
  output io_pmp_2_cfg_l,
  output [1:0] io_pmp_2_cfg_a,
  output io_pmp_2_cfg_x,
  output io_pmp_2_cfg_w,
  output io_pmp_2_cfg_r,
  output [45:0] io_pmp_2_addr,
  output [47:0] io_pmp_2_mask,
  output io_pmp_3_cfg_l,
  output [1:0] io_pmp_3_cfg_a,
  output io_pmp_3_cfg_x,
  output io_pmp_3_cfg_w,
  output io_pmp_3_cfg_r,
  output [45:0] io_pmp_3_addr,
  output [47:0] io_pmp_3_mask,
  output io_pmp_4_cfg_l,
  output [1:0] io_pmp_4_cfg_a,
  output io_pmp_4_cfg_x,
  output io_pmp_4_cfg_w,
  output io_pmp_4_cfg_r,
  output [45:0] io_pmp_4_addr,
  output [47:0] io_pmp_4_mask,
  output io_pmp_5_cfg_l,
  output [1:0] io_pmp_5_cfg_a,
  output io_pmp_5_cfg_x,
  output io_pmp_5_cfg_w,
  output io_pmp_5_cfg_r,
  output [45:0] io_pmp_5_addr,
  output [47:0] io_pmp_5_mask,
  output io_pmp_6_cfg_l,
  output [1:0] io_pmp_6_cfg_a,
  output io_pmp_6_cfg_x,
  output io_pmp_6_cfg_w,
  output io_pmp_6_cfg_r,
  output [45:0] io_pmp_6_addr,
  output [47:0] io_pmp_6_mask,
  output io_pmp_7_cfg_l,
  output [1:0] io_pmp_7_cfg_a,
  output io_pmp_7_cfg_x,
  output io_pmp_7_cfg_w,
  output io_pmp_7_cfg_r,
  output [45:0] io_pmp_7_addr,
  output [47:0] io_pmp_7_mask,
  output io_pmp_8_cfg_l,
  output [1:0] io_pmp_8_cfg_a,
  output io_pmp_8_cfg_x,
  output io_pmp_8_cfg_w,
  output io_pmp_8_cfg_r,
  output [45:0] io_pmp_8_addr,
  output [47:0] io_pmp_8_mask,
  output io_pmp_9_cfg_l,
  output [1:0] io_pmp_9_cfg_a,
  output io_pmp_9_cfg_x,
  output io_pmp_9_cfg_w,
  output io_pmp_9_cfg_r,
  output [45:0] io_pmp_9_addr,
  output [47:0] io_pmp_9_mask,
  output io_pmp_10_cfg_l,
  output [1:0] io_pmp_10_cfg_a,
  output io_pmp_10_cfg_x,
  output io_pmp_10_cfg_w,
  output io_pmp_10_cfg_r,
  output [45:0] io_pmp_10_addr,
  output [47:0] io_pmp_10_mask,
  output io_pmp_11_cfg_l,
  output [1:0] io_pmp_11_cfg_a,
  output io_pmp_11_cfg_x,
  output io_pmp_11_cfg_w,
  output io_pmp_11_cfg_r,
  output [45:0] io_pmp_11_addr,
  output [47:0] io_pmp_11_mask,
  output io_pmp_12_cfg_l,
  output [1:0] io_pmp_12_cfg_a,
  output io_pmp_12_cfg_x,
  output io_pmp_12_cfg_w,
  output io_pmp_12_cfg_r,
  output [45:0] io_pmp_12_addr,
  output [47:0] io_pmp_12_mask,
  output io_pmp_13_cfg_l,
  output [1:0] io_pmp_13_cfg_a,
  output io_pmp_13_cfg_x,
  output io_pmp_13_cfg_w,
  output io_pmp_13_cfg_r,
  output [45:0] io_pmp_13_addr,
  output [47:0] io_pmp_13_mask,
  output io_pmp_14_cfg_l,
  output [1:0] io_pmp_14_cfg_a,
  output io_pmp_14_cfg_x,
  output io_pmp_14_cfg_w,
  output io_pmp_14_cfg_r,
  output [45:0] io_pmp_14_addr,
  output [47:0] io_pmp_14_mask,
  output io_pmp_15_cfg_l,
  output [1:0] io_pmp_15_cfg_a,
  output io_pmp_15_cfg_x,
  output io_pmp_15_cfg_w,
  output io_pmp_15_cfg_r,
  output [45:0] io_pmp_15_addr,
  output [47:0] io_pmp_15_mask,
  output io_pma_0_cfg_c,
  output io_pma_0_cfg_atomic,
  output [1:0] io_pma_0_cfg_a,
  output io_pma_0_cfg_x,
  output io_pma_0_cfg_w,
  output io_pma_0_cfg_r,
  output [45:0] io_pma_0_addr,
  output [47:0] io_pma_0_mask,
  output io_pma_1_cfg_c,
  output io_pma_1_cfg_atomic,
  output [1:0] io_pma_1_cfg_a,
  output io_pma_1_cfg_x,
  output io_pma_1_cfg_w,
  output io_pma_1_cfg_r,
  output [45:0] io_pma_1_addr,
  output [47:0] io_pma_1_mask,
  output io_pma_2_cfg_c,
  output io_pma_2_cfg_atomic,
  output [1:0] io_pma_2_cfg_a,
  output io_pma_2_cfg_x,
  output io_pma_2_cfg_w,
  output io_pma_2_cfg_r,
  output [45:0] io_pma_2_addr,
  output [47:0] io_pma_2_mask,
  output io_pma_3_cfg_c,
  output io_pma_3_cfg_atomic,
  output [1:0] io_pma_3_cfg_a,
  output io_pma_3_cfg_x,
  output io_pma_3_cfg_w,
  output io_pma_3_cfg_r,
  output [45:0] io_pma_3_addr,
  output [47:0] io_pma_3_mask,
  output io_pma_4_cfg_c,
  output io_pma_4_cfg_atomic,
  output [1:0] io_pma_4_cfg_a,
  output io_pma_4_cfg_x,
  output io_pma_4_cfg_w,
  output io_pma_4_cfg_r,
  output [45:0] io_pma_4_addr,
  output [47:0] io_pma_4_mask,
  output io_pma_5_cfg_c,
  output io_pma_5_cfg_atomic,
  output [1:0] io_pma_5_cfg_a,
  output io_pma_5_cfg_x,
  output io_pma_5_cfg_w,
  output io_pma_5_cfg_r,
  output [45:0] io_pma_5_addr,
  output [47:0] io_pma_5_mask,
  output io_pma_6_cfg_c,
  output io_pma_6_cfg_atomic,
  output [1:0] io_pma_6_cfg_a,
  output io_pma_6_cfg_x,
  output io_pma_6_cfg_w,
  output io_pma_6_cfg_r,
  output [45:0] io_pma_6_addr,
  output [47:0] io_pma_6_mask,
  output io_pma_7_cfg_c,
  output io_pma_7_cfg_atomic,
  output [1:0] io_pma_7_cfg_a,
  output io_pma_7_cfg_x,
  output io_pma_7_cfg_w,
  output io_pma_7_cfg_r,
  output [45:0] io_pma_7_addr,
  output [47:0] io_pma_7_mask,
  output io_pma_8_cfg_c,
  output io_pma_8_cfg_atomic,
  output [1:0] io_pma_8_cfg_a,
  output io_pma_8_cfg_x,
  output io_pma_8_cfg_w,
  output io_pma_8_cfg_r,
  output [45:0] io_pma_8_addr,
  output [47:0] io_pma_8_mask,
  output io_pma_9_cfg_c,
  output io_pma_9_cfg_atomic,
  output [1:0] io_pma_9_cfg_a,
  output io_pma_9_cfg_x,
  output io_pma_9_cfg_w,
  output io_pma_9_cfg_r,
  output [45:0] io_pma_9_addr,
  output [47:0] io_pma_9_mask,
  output io_pma_10_cfg_c,
  output io_pma_10_cfg_atomic,
  output [1:0] io_pma_10_cfg_a,
  output io_pma_10_cfg_x,
  output io_pma_10_cfg_w,
  output io_pma_10_cfg_r,
  output [45:0] io_pma_10_addr,
  output [47:0] io_pma_10_mask,
  output io_pma_11_cfg_c,
  output io_pma_11_cfg_atomic,
  output [1:0] io_pma_11_cfg_a,
  output io_pma_11_cfg_x,
  output io_pma_11_cfg_w,
  output io_pma_11_cfg_r,
  output [45:0] io_pma_11_addr,
  output [47:0] io_pma_11_mask,
  output io_pma_12_cfg_c,
  output io_pma_12_cfg_atomic,
  output [1:0] io_pma_12_cfg_a,
  output io_pma_12_cfg_x,
  output io_pma_12_cfg_w,
  output io_pma_12_cfg_r,
  output [45:0] io_pma_12_addr,
  output [47:0] io_pma_12_mask,
  output io_pma_13_cfg_c,
  output io_pma_13_cfg_atomic,
  output [1:0] io_pma_13_cfg_a,
  output io_pma_13_cfg_x,
  output io_pma_13_cfg_w,
  output io_pma_13_cfg_r,
  output [45:0] io_pma_13_addr,
  output [47:0] io_pma_13_mask,
  output io_pma_14_cfg_c,
  output io_pma_14_cfg_atomic,
  output [1:0] io_pma_14_cfg_a,
  output io_pma_14_cfg_x,
  output io_pma_14_cfg_w,
  output io_pma_14_cfg_r,
  output [45:0] io_pma_14_addr,
  output [47:0] io_pma_14_mask,
  output io_pma_15_cfg_c,
  output io_pma_15_cfg_atomic,
  output [1:0] io_pma_15_cfg_a,
  output io_pma_15_cfg_x,
  output io_pma_15_cfg_w,
  output io_pma_15_cfg_r,
  output [45:0] io_pma_15_addr,
  output [47:0] io_pma_15_mask
);
  pmp_entry_t [NUM_PMP-1:0] pmp;
  pmp_entry_t [NUM_PMA-1:0] pma;
  xs_PMP_core u_core (
    .clock(clock), .reset(reset),
    .io_distribute_csr_w_valid(io_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data),
    .io_pmp(pmp), .io_pma(pma)
  );
  assign io_pmp_0_cfg_l = pmp[0].cfg.l;
  assign io_pmp_0_cfg_a = pmp[0].cfg.a;
  assign io_pmp_0_cfg_x = pmp[0].cfg.x;
  assign io_pmp_0_cfg_w = pmp[0].cfg.w;
  assign io_pmp_0_cfg_r = pmp[0].cfg.r;
  assign io_pmp_0_addr = pmp[0].addr;
  assign io_pmp_0_mask = pmp[0].mask;
  assign io_pmp_1_cfg_l = pmp[1].cfg.l;
  assign io_pmp_1_cfg_a = pmp[1].cfg.a;
  assign io_pmp_1_cfg_x = pmp[1].cfg.x;
  assign io_pmp_1_cfg_w = pmp[1].cfg.w;
  assign io_pmp_1_cfg_r = pmp[1].cfg.r;
  assign io_pmp_1_addr = pmp[1].addr;
  assign io_pmp_1_mask = pmp[1].mask;
  assign io_pmp_2_cfg_l = pmp[2].cfg.l;
  assign io_pmp_2_cfg_a = pmp[2].cfg.a;
  assign io_pmp_2_cfg_x = pmp[2].cfg.x;
  assign io_pmp_2_cfg_w = pmp[2].cfg.w;
  assign io_pmp_2_cfg_r = pmp[2].cfg.r;
  assign io_pmp_2_addr = pmp[2].addr;
  assign io_pmp_2_mask = pmp[2].mask;
  assign io_pmp_3_cfg_l = pmp[3].cfg.l;
  assign io_pmp_3_cfg_a = pmp[3].cfg.a;
  assign io_pmp_3_cfg_x = pmp[3].cfg.x;
  assign io_pmp_3_cfg_w = pmp[3].cfg.w;
  assign io_pmp_3_cfg_r = pmp[3].cfg.r;
  assign io_pmp_3_addr = pmp[3].addr;
  assign io_pmp_3_mask = pmp[3].mask;
  assign io_pmp_4_cfg_l = pmp[4].cfg.l;
  assign io_pmp_4_cfg_a = pmp[4].cfg.a;
  assign io_pmp_4_cfg_x = pmp[4].cfg.x;
  assign io_pmp_4_cfg_w = pmp[4].cfg.w;
  assign io_pmp_4_cfg_r = pmp[4].cfg.r;
  assign io_pmp_4_addr = pmp[4].addr;
  assign io_pmp_4_mask = pmp[4].mask;
  assign io_pmp_5_cfg_l = pmp[5].cfg.l;
  assign io_pmp_5_cfg_a = pmp[5].cfg.a;
  assign io_pmp_5_cfg_x = pmp[5].cfg.x;
  assign io_pmp_5_cfg_w = pmp[5].cfg.w;
  assign io_pmp_5_cfg_r = pmp[5].cfg.r;
  assign io_pmp_5_addr = pmp[5].addr;
  assign io_pmp_5_mask = pmp[5].mask;
  assign io_pmp_6_cfg_l = pmp[6].cfg.l;
  assign io_pmp_6_cfg_a = pmp[6].cfg.a;
  assign io_pmp_6_cfg_x = pmp[6].cfg.x;
  assign io_pmp_6_cfg_w = pmp[6].cfg.w;
  assign io_pmp_6_cfg_r = pmp[6].cfg.r;
  assign io_pmp_6_addr = pmp[6].addr;
  assign io_pmp_6_mask = pmp[6].mask;
  assign io_pmp_7_cfg_l = pmp[7].cfg.l;
  assign io_pmp_7_cfg_a = pmp[7].cfg.a;
  assign io_pmp_7_cfg_x = pmp[7].cfg.x;
  assign io_pmp_7_cfg_w = pmp[7].cfg.w;
  assign io_pmp_7_cfg_r = pmp[7].cfg.r;
  assign io_pmp_7_addr = pmp[7].addr;
  assign io_pmp_7_mask = pmp[7].mask;
  assign io_pmp_8_cfg_l = pmp[8].cfg.l;
  assign io_pmp_8_cfg_a = pmp[8].cfg.a;
  assign io_pmp_8_cfg_x = pmp[8].cfg.x;
  assign io_pmp_8_cfg_w = pmp[8].cfg.w;
  assign io_pmp_8_cfg_r = pmp[8].cfg.r;
  assign io_pmp_8_addr = pmp[8].addr;
  assign io_pmp_8_mask = pmp[8].mask;
  assign io_pmp_9_cfg_l = pmp[9].cfg.l;
  assign io_pmp_9_cfg_a = pmp[9].cfg.a;
  assign io_pmp_9_cfg_x = pmp[9].cfg.x;
  assign io_pmp_9_cfg_w = pmp[9].cfg.w;
  assign io_pmp_9_cfg_r = pmp[9].cfg.r;
  assign io_pmp_9_addr = pmp[9].addr;
  assign io_pmp_9_mask = pmp[9].mask;
  assign io_pmp_10_cfg_l = pmp[10].cfg.l;
  assign io_pmp_10_cfg_a = pmp[10].cfg.a;
  assign io_pmp_10_cfg_x = pmp[10].cfg.x;
  assign io_pmp_10_cfg_w = pmp[10].cfg.w;
  assign io_pmp_10_cfg_r = pmp[10].cfg.r;
  assign io_pmp_10_addr = pmp[10].addr;
  assign io_pmp_10_mask = pmp[10].mask;
  assign io_pmp_11_cfg_l = pmp[11].cfg.l;
  assign io_pmp_11_cfg_a = pmp[11].cfg.a;
  assign io_pmp_11_cfg_x = pmp[11].cfg.x;
  assign io_pmp_11_cfg_w = pmp[11].cfg.w;
  assign io_pmp_11_cfg_r = pmp[11].cfg.r;
  assign io_pmp_11_addr = pmp[11].addr;
  assign io_pmp_11_mask = pmp[11].mask;
  assign io_pmp_12_cfg_l = pmp[12].cfg.l;
  assign io_pmp_12_cfg_a = pmp[12].cfg.a;
  assign io_pmp_12_cfg_x = pmp[12].cfg.x;
  assign io_pmp_12_cfg_w = pmp[12].cfg.w;
  assign io_pmp_12_cfg_r = pmp[12].cfg.r;
  assign io_pmp_12_addr = pmp[12].addr;
  assign io_pmp_12_mask = pmp[12].mask;
  assign io_pmp_13_cfg_l = pmp[13].cfg.l;
  assign io_pmp_13_cfg_a = pmp[13].cfg.a;
  assign io_pmp_13_cfg_x = pmp[13].cfg.x;
  assign io_pmp_13_cfg_w = pmp[13].cfg.w;
  assign io_pmp_13_cfg_r = pmp[13].cfg.r;
  assign io_pmp_13_addr = pmp[13].addr;
  assign io_pmp_13_mask = pmp[13].mask;
  assign io_pmp_14_cfg_l = pmp[14].cfg.l;
  assign io_pmp_14_cfg_a = pmp[14].cfg.a;
  assign io_pmp_14_cfg_x = pmp[14].cfg.x;
  assign io_pmp_14_cfg_w = pmp[14].cfg.w;
  assign io_pmp_14_cfg_r = pmp[14].cfg.r;
  assign io_pmp_14_addr = pmp[14].addr;
  assign io_pmp_14_mask = pmp[14].mask;
  assign io_pmp_15_cfg_l = pmp[15].cfg.l;
  assign io_pmp_15_cfg_a = pmp[15].cfg.a;
  assign io_pmp_15_cfg_x = pmp[15].cfg.x;
  assign io_pmp_15_cfg_w = pmp[15].cfg.w;
  assign io_pmp_15_cfg_r = pmp[15].cfg.r;
  assign io_pmp_15_addr = pmp[15].addr;
  assign io_pmp_15_mask = pmp[15].mask;
  assign io_pma_0_cfg_c = pma[0].cfg.c;
  assign io_pma_0_cfg_atomic = pma[0].cfg.atomic;
  assign io_pma_0_cfg_a = pma[0].cfg.a;
  assign io_pma_0_cfg_x = pma[0].cfg.x;
  assign io_pma_0_cfg_w = pma[0].cfg.w;
  assign io_pma_0_cfg_r = pma[0].cfg.r;
  assign io_pma_0_addr = pma[0].addr;
  assign io_pma_0_mask = pma[0].mask;
  assign io_pma_1_cfg_c = pma[1].cfg.c;
  assign io_pma_1_cfg_atomic = pma[1].cfg.atomic;
  assign io_pma_1_cfg_a = pma[1].cfg.a;
  assign io_pma_1_cfg_x = pma[1].cfg.x;
  assign io_pma_1_cfg_w = pma[1].cfg.w;
  assign io_pma_1_cfg_r = pma[1].cfg.r;
  assign io_pma_1_addr = pma[1].addr;
  assign io_pma_1_mask = pma[1].mask;
  assign io_pma_2_cfg_c = pma[2].cfg.c;
  assign io_pma_2_cfg_atomic = pma[2].cfg.atomic;
  assign io_pma_2_cfg_a = pma[2].cfg.a;
  assign io_pma_2_cfg_x = pma[2].cfg.x;
  assign io_pma_2_cfg_w = pma[2].cfg.w;
  assign io_pma_2_cfg_r = pma[2].cfg.r;
  assign io_pma_2_addr = pma[2].addr;
  assign io_pma_2_mask = pma[2].mask;
  assign io_pma_3_cfg_c = pma[3].cfg.c;
  assign io_pma_3_cfg_atomic = pma[3].cfg.atomic;
  assign io_pma_3_cfg_a = pma[3].cfg.a;
  assign io_pma_3_cfg_x = pma[3].cfg.x;
  assign io_pma_3_cfg_w = pma[3].cfg.w;
  assign io_pma_3_cfg_r = pma[3].cfg.r;
  assign io_pma_3_addr = pma[3].addr;
  assign io_pma_3_mask = pma[3].mask;
  assign io_pma_4_cfg_c = pma[4].cfg.c;
  assign io_pma_4_cfg_atomic = pma[4].cfg.atomic;
  assign io_pma_4_cfg_a = pma[4].cfg.a;
  assign io_pma_4_cfg_x = pma[4].cfg.x;
  assign io_pma_4_cfg_w = pma[4].cfg.w;
  assign io_pma_4_cfg_r = pma[4].cfg.r;
  assign io_pma_4_addr = pma[4].addr;
  assign io_pma_4_mask = pma[4].mask;
  assign io_pma_5_cfg_c = pma[5].cfg.c;
  assign io_pma_5_cfg_atomic = pma[5].cfg.atomic;
  assign io_pma_5_cfg_a = pma[5].cfg.a;
  assign io_pma_5_cfg_x = pma[5].cfg.x;
  assign io_pma_5_cfg_w = pma[5].cfg.w;
  assign io_pma_5_cfg_r = pma[5].cfg.r;
  assign io_pma_5_addr = pma[5].addr;
  assign io_pma_5_mask = pma[5].mask;
  assign io_pma_6_cfg_c = pma[6].cfg.c;
  assign io_pma_6_cfg_atomic = pma[6].cfg.atomic;
  assign io_pma_6_cfg_a = pma[6].cfg.a;
  assign io_pma_6_cfg_x = pma[6].cfg.x;
  assign io_pma_6_cfg_w = pma[6].cfg.w;
  assign io_pma_6_cfg_r = pma[6].cfg.r;
  assign io_pma_6_addr = pma[6].addr;
  assign io_pma_6_mask = pma[6].mask;
  assign io_pma_7_cfg_c = pma[7].cfg.c;
  assign io_pma_7_cfg_atomic = pma[7].cfg.atomic;
  assign io_pma_7_cfg_a = pma[7].cfg.a;
  assign io_pma_7_cfg_x = pma[7].cfg.x;
  assign io_pma_7_cfg_w = pma[7].cfg.w;
  assign io_pma_7_cfg_r = pma[7].cfg.r;
  assign io_pma_7_addr = pma[7].addr;
  assign io_pma_7_mask = pma[7].mask;
  assign io_pma_8_cfg_c = pma[8].cfg.c;
  assign io_pma_8_cfg_atomic = pma[8].cfg.atomic;
  assign io_pma_8_cfg_a = pma[8].cfg.a;
  assign io_pma_8_cfg_x = pma[8].cfg.x;
  assign io_pma_8_cfg_w = pma[8].cfg.w;
  assign io_pma_8_cfg_r = pma[8].cfg.r;
  assign io_pma_8_addr = pma[8].addr;
  assign io_pma_8_mask = pma[8].mask;
  assign io_pma_9_cfg_c = pma[9].cfg.c;
  assign io_pma_9_cfg_atomic = pma[9].cfg.atomic;
  assign io_pma_9_cfg_a = pma[9].cfg.a;
  assign io_pma_9_cfg_x = pma[9].cfg.x;
  assign io_pma_9_cfg_w = pma[9].cfg.w;
  assign io_pma_9_cfg_r = pma[9].cfg.r;
  assign io_pma_9_addr = pma[9].addr;
  assign io_pma_9_mask = pma[9].mask;
  assign io_pma_10_cfg_c = pma[10].cfg.c;
  assign io_pma_10_cfg_atomic = pma[10].cfg.atomic;
  assign io_pma_10_cfg_a = pma[10].cfg.a;
  assign io_pma_10_cfg_x = pma[10].cfg.x;
  assign io_pma_10_cfg_w = pma[10].cfg.w;
  assign io_pma_10_cfg_r = pma[10].cfg.r;
  assign io_pma_10_addr = pma[10].addr;
  assign io_pma_10_mask = pma[10].mask;
  assign io_pma_11_cfg_c = pma[11].cfg.c;
  assign io_pma_11_cfg_atomic = pma[11].cfg.atomic;
  assign io_pma_11_cfg_a = pma[11].cfg.a;
  assign io_pma_11_cfg_x = pma[11].cfg.x;
  assign io_pma_11_cfg_w = pma[11].cfg.w;
  assign io_pma_11_cfg_r = pma[11].cfg.r;
  assign io_pma_11_addr = pma[11].addr;
  assign io_pma_11_mask = pma[11].mask;
  assign io_pma_12_cfg_c = pma[12].cfg.c;
  assign io_pma_12_cfg_atomic = pma[12].cfg.atomic;
  assign io_pma_12_cfg_a = pma[12].cfg.a;
  assign io_pma_12_cfg_x = pma[12].cfg.x;
  assign io_pma_12_cfg_w = pma[12].cfg.w;
  assign io_pma_12_cfg_r = pma[12].cfg.r;
  assign io_pma_12_addr = pma[12].addr;
  assign io_pma_12_mask = pma[12].mask;
  assign io_pma_13_cfg_c = pma[13].cfg.c;
  assign io_pma_13_cfg_atomic = pma[13].cfg.atomic;
  assign io_pma_13_cfg_a = pma[13].cfg.a;
  assign io_pma_13_cfg_x = pma[13].cfg.x;
  assign io_pma_13_cfg_w = pma[13].cfg.w;
  assign io_pma_13_cfg_r = pma[13].cfg.r;
  assign io_pma_13_addr = pma[13].addr;
  assign io_pma_13_mask = pma[13].mask;
  assign io_pma_14_cfg_c = pma[14].cfg.c;
  assign io_pma_14_cfg_atomic = pma[14].cfg.atomic;
  assign io_pma_14_cfg_a = pma[14].cfg.a;
  assign io_pma_14_cfg_x = pma[14].cfg.x;
  assign io_pma_14_cfg_w = pma[14].cfg.w;
  assign io_pma_14_cfg_r = pma[14].cfg.r;
  assign io_pma_14_addr = pma[14].addr;
  assign io_pma_14_mask = pma[14].mask;
  assign io_pma_15_cfg_c = pma[15].cfg.c;
  assign io_pma_15_cfg_atomic = pma[15].cfg.atomic;
  assign io_pma_15_cfg_a = pma[15].cfg.a;
  assign io_pma_15_cfg_x = pma[15].cfg.x;
  assign io_pma_15_cfg_w = pma[15].cfg.w;
  assign io_pma_15_cfg_r = pma[15].cfg.r;
  assign io_pma_15_addr = pma[15].addr;
  assign io_pma_15_mask = pma[15].mask;
endmodule
