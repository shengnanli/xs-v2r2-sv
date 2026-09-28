// 自动生成：verif/ut/Arbiter16_MainPipeReq/gen.py（读 G1 golden 端口表）—— 勿手改
// Arbiter16_MainPipeReq 双例化逐拍比对：golden Arbiter16_MainPipeReq vs Arbiter16_MainPipeReq_xs（xs_FixedPriorityArbiter_core）。
// 激励：16 路 valid 位图混合全 0/单热/稀疏/全随机，载荷逐位随机，out_ready 半数为 0。
// 覆盖闸：每一路单独胜出、无人请求、out_ready=0 各 >= COV_MIN；每个输出位见过 0 和 1。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  int errors = 0, checks = 0, cov_fail = 0;
  int win [16];
  int none_cnt = 0, stall_cnt = 0;

  // ---- 输入（两侧共用）----
  logic io_in_0_valid;
  logic [3:0] io_in_0_bits_miss_id;
  logic [3:0] io_in_0_bits_occupy_way;
  logic io_in_0_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_0_bits_source;
  logic [4:0] io_in_0_bits_cmd;
  logic [49:0] io_in_0_bits_vaddr;
  logic [47:0] io_in_0_bits_addr;
  logic [2:0] io_in_0_bits_word_idx;
  logic [127:0] io_in_0_bits_amo_data;
  logic [15:0] io_in_0_bits_amo_mask;
  logic [127:0] io_in_0_bits_amo_cmp;
  logic [2:0] io_in_0_bits_pf_source;
  logic io_in_0_bits_access;
  logic [5:0] io_in_0_bits_id;
  logic io_in_1_valid;
  logic [3:0] io_in_1_bits_miss_id;
  logic [3:0] io_in_1_bits_occupy_way;
  logic io_in_1_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_1_bits_source;
  logic [4:0] io_in_1_bits_cmd;
  logic [49:0] io_in_1_bits_vaddr;
  logic [47:0] io_in_1_bits_addr;
  logic [2:0] io_in_1_bits_word_idx;
  logic [127:0] io_in_1_bits_amo_data;
  logic [15:0] io_in_1_bits_amo_mask;
  logic [127:0] io_in_1_bits_amo_cmp;
  logic [2:0] io_in_1_bits_pf_source;
  logic io_in_1_bits_access;
  logic [5:0] io_in_1_bits_id;
  logic io_in_2_valid;
  logic [3:0] io_in_2_bits_miss_id;
  logic [3:0] io_in_2_bits_occupy_way;
  logic io_in_2_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_2_bits_source;
  logic [4:0] io_in_2_bits_cmd;
  logic [49:0] io_in_2_bits_vaddr;
  logic [47:0] io_in_2_bits_addr;
  logic [2:0] io_in_2_bits_word_idx;
  logic [127:0] io_in_2_bits_amo_data;
  logic [15:0] io_in_2_bits_amo_mask;
  logic [127:0] io_in_2_bits_amo_cmp;
  logic [2:0] io_in_2_bits_pf_source;
  logic io_in_2_bits_access;
  logic [5:0] io_in_2_bits_id;
  logic io_in_3_valid;
  logic [3:0] io_in_3_bits_miss_id;
  logic [3:0] io_in_3_bits_occupy_way;
  logic io_in_3_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_3_bits_source;
  logic [4:0] io_in_3_bits_cmd;
  logic [49:0] io_in_3_bits_vaddr;
  logic [47:0] io_in_3_bits_addr;
  logic [2:0] io_in_3_bits_word_idx;
  logic [127:0] io_in_3_bits_amo_data;
  logic [15:0] io_in_3_bits_amo_mask;
  logic [127:0] io_in_3_bits_amo_cmp;
  logic [2:0] io_in_3_bits_pf_source;
  logic io_in_3_bits_access;
  logic [5:0] io_in_3_bits_id;
  logic io_in_4_valid;
  logic [3:0] io_in_4_bits_miss_id;
  logic [3:0] io_in_4_bits_occupy_way;
  logic io_in_4_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_4_bits_source;
  logic [4:0] io_in_4_bits_cmd;
  logic [49:0] io_in_4_bits_vaddr;
  logic [47:0] io_in_4_bits_addr;
  logic [2:0] io_in_4_bits_word_idx;
  logic [127:0] io_in_4_bits_amo_data;
  logic [15:0] io_in_4_bits_amo_mask;
  logic [127:0] io_in_4_bits_amo_cmp;
  logic [2:0] io_in_4_bits_pf_source;
  logic io_in_4_bits_access;
  logic [5:0] io_in_4_bits_id;
  logic io_in_5_valid;
  logic [3:0] io_in_5_bits_miss_id;
  logic [3:0] io_in_5_bits_occupy_way;
  logic io_in_5_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_5_bits_source;
  logic [4:0] io_in_5_bits_cmd;
  logic [49:0] io_in_5_bits_vaddr;
  logic [47:0] io_in_5_bits_addr;
  logic [2:0] io_in_5_bits_word_idx;
  logic [127:0] io_in_5_bits_amo_data;
  logic [15:0] io_in_5_bits_amo_mask;
  logic [127:0] io_in_5_bits_amo_cmp;
  logic [2:0] io_in_5_bits_pf_source;
  logic io_in_5_bits_access;
  logic [5:0] io_in_5_bits_id;
  logic io_in_6_valid;
  logic [3:0] io_in_6_bits_miss_id;
  logic [3:0] io_in_6_bits_occupy_way;
  logic io_in_6_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_6_bits_source;
  logic [4:0] io_in_6_bits_cmd;
  logic [49:0] io_in_6_bits_vaddr;
  logic [47:0] io_in_6_bits_addr;
  logic [2:0] io_in_6_bits_word_idx;
  logic [127:0] io_in_6_bits_amo_data;
  logic [15:0] io_in_6_bits_amo_mask;
  logic [127:0] io_in_6_bits_amo_cmp;
  logic [2:0] io_in_6_bits_pf_source;
  logic io_in_6_bits_access;
  logic [5:0] io_in_6_bits_id;
  logic io_in_7_valid;
  logic [3:0] io_in_7_bits_miss_id;
  logic [3:0] io_in_7_bits_occupy_way;
  logic io_in_7_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_7_bits_source;
  logic [4:0] io_in_7_bits_cmd;
  logic [49:0] io_in_7_bits_vaddr;
  logic [47:0] io_in_7_bits_addr;
  logic [2:0] io_in_7_bits_word_idx;
  logic [127:0] io_in_7_bits_amo_data;
  logic [15:0] io_in_7_bits_amo_mask;
  logic [127:0] io_in_7_bits_amo_cmp;
  logic [2:0] io_in_7_bits_pf_source;
  logic io_in_7_bits_access;
  logic [5:0] io_in_7_bits_id;
  logic io_in_8_valid;
  logic [3:0] io_in_8_bits_miss_id;
  logic [3:0] io_in_8_bits_occupy_way;
  logic io_in_8_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_8_bits_source;
  logic [4:0] io_in_8_bits_cmd;
  logic [49:0] io_in_8_bits_vaddr;
  logic [47:0] io_in_8_bits_addr;
  logic [2:0] io_in_8_bits_word_idx;
  logic [127:0] io_in_8_bits_amo_data;
  logic [15:0] io_in_8_bits_amo_mask;
  logic [127:0] io_in_8_bits_amo_cmp;
  logic [2:0] io_in_8_bits_pf_source;
  logic io_in_8_bits_access;
  logic [5:0] io_in_8_bits_id;
  logic io_in_9_valid;
  logic [3:0] io_in_9_bits_miss_id;
  logic [3:0] io_in_9_bits_occupy_way;
  logic io_in_9_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_9_bits_source;
  logic [4:0] io_in_9_bits_cmd;
  logic [49:0] io_in_9_bits_vaddr;
  logic [47:0] io_in_9_bits_addr;
  logic [2:0] io_in_9_bits_word_idx;
  logic [127:0] io_in_9_bits_amo_data;
  logic [15:0] io_in_9_bits_amo_mask;
  logic [127:0] io_in_9_bits_amo_cmp;
  logic [2:0] io_in_9_bits_pf_source;
  logic io_in_9_bits_access;
  logic [5:0] io_in_9_bits_id;
  logic io_in_10_valid;
  logic [3:0] io_in_10_bits_miss_id;
  logic [3:0] io_in_10_bits_occupy_way;
  logic io_in_10_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_10_bits_source;
  logic [4:0] io_in_10_bits_cmd;
  logic [49:0] io_in_10_bits_vaddr;
  logic [47:0] io_in_10_bits_addr;
  logic [2:0] io_in_10_bits_word_idx;
  logic [127:0] io_in_10_bits_amo_data;
  logic [15:0] io_in_10_bits_amo_mask;
  logic [127:0] io_in_10_bits_amo_cmp;
  logic [2:0] io_in_10_bits_pf_source;
  logic io_in_10_bits_access;
  logic [5:0] io_in_10_bits_id;
  logic io_in_11_valid;
  logic [3:0] io_in_11_bits_miss_id;
  logic [3:0] io_in_11_bits_occupy_way;
  logic io_in_11_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_11_bits_source;
  logic [4:0] io_in_11_bits_cmd;
  logic [49:0] io_in_11_bits_vaddr;
  logic [47:0] io_in_11_bits_addr;
  logic [2:0] io_in_11_bits_word_idx;
  logic [127:0] io_in_11_bits_amo_data;
  logic [15:0] io_in_11_bits_amo_mask;
  logic [127:0] io_in_11_bits_amo_cmp;
  logic [2:0] io_in_11_bits_pf_source;
  logic io_in_11_bits_access;
  logic [5:0] io_in_11_bits_id;
  logic io_in_12_valid;
  logic [3:0] io_in_12_bits_miss_id;
  logic [3:0] io_in_12_bits_occupy_way;
  logic io_in_12_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_12_bits_source;
  logic [4:0] io_in_12_bits_cmd;
  logic [49:0] io_in_12_bits_vaddr;
  logic [47:0] io_in_12_bits_addr;
  logic [2:0] io_in_12_bits_word_idx;
  logic [127:0] io_in_12_bits_amo_data;
  logic [15:0] io_in_12_bits_amo_mask;
  logic [127:0] io_in_12_bits_amo_cmp;
  logic [2:0] io_in_12_bits_pf_source;
  logic io_in_12_bits_access;
  logic [5:0] io_in_12_bits_id;
  logic io_in_13_valid;
  logic [3:0] io_in_13_bits_miss_id;
  logic [3:0] io_in_13_bits_occupy_way;
  logic io_in_13_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_13_bits_source;
  logic [4:0] io_in_13_bits_cmd;
  logic [49:0] io_in_13_bits_vaddr;
  logic [47:0] io_in_13_bits_addr;
  logic [2:0] io_in_13_bits_word_idx;
  logic [127:0] io_in_13_bits_amo_data;
  logic [15:0] io_in_13_bits_amo_mask;
  logic [127:0] io_in_13_bits_amo_cmp;
  logic [2:0] io_in_13_bits_pf_source;
  logic io_in_13_bits_access;
  logic [5:0] io_in_13_bits_id;
  logic io_in_14_valid;
  logic [3:0] io_in_14_bits_miss_id;
  logic [3:0] io_in_14_bits_occupy_way;
  logic io_in_14_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_14_bits_source;
  logic [4:0] io_in_14_bits_cmd;
  logic [49:0] io_in_14_bits_vaddr;
  logic [47:0] io_in_14_bits_addr;
  logic [2:0] io_in_14_bits_word_idx;
  logic [127:0] io_in_14_bits_amo_data;
  logic [15:0] io_in_14_bits_amo_mask;
  logic [127:0] io_in_14_bits_amo_cmp;
  logic [2:0] io_in_14_bits_pf_source;
  logic io_in_14_bits_access;
  logic [5:0] io_in_14_bits_id;
  logic io_in_15_valid;
  logic [3:0] io_in_15_bits_miss_id;
  logic [3:0] io_in_15_bits_occupy_way;
  logic io_in_15_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_in_15_bits_source;
  logic [4:0] io_in_15_bits_cmd;
  logic [49:0] io_in_15_bits_vaddr;
  logic [47:0] io_in_15_bits_addr;
  logic [2:0] io_in_15_bits_word_idx;
  logic [127:0] io_in_15_bits_amo_data;
  logic [15:0] io_in_15_bits_amo_mask;
  logic [127:0] io_in_15_bits_amo_cmp;
  logic [2:0] io_in_15_bits_pf_source;
  logic io_in_15_bits_access;
  logic [5:0] io_in_15_bits_id;
  logic io_out_ready;
  // ---- 输出（g_ = golden，i_ = 重写）----
  wire  g_io_in_0_ready, i_io_in_0_ready;
  logic seen1_io_in_0_ready, seen0_io_in_0_ready;
  wire  g_io_in_1_ready, i_io_in_1_ready;
  logic seen1_io_in_1_ready, seen0_io_in_1_ready;
  wire  g_io_in_2_ready, i_io_in_2_ready;
  logic seen1_io_in_2_ready, seen0_io_in_2_ready;
  wire  g_io_in_3_ready, i_io_in_3_ready;
  logic seen1_io_in_3_ready, seen0_io_in_3_ready;
  wire  g_io_in_4_ready, i_io_in_4_ready;
  logic seen1_io_in_4_ready, seen0_io_in_4_ready;
  wire  g_io_in_5_ready, i_io_in_5_ready;
  logic seen1_io_in_5_ready, seen0_io_in_5_ready;
  wire  g_io_in_6_ready, i_io_in_6_ready;
  logic seen1_io_in_6_ready, seen0_io_in_6_ready;
  wire  g_io_in_7_ready, i_io_in_7_ready;
  logic seen1_io_in_7_ready, seen0_io_in_7_ready;
  wire  g_io_in_8_ready, i_io_in_8_ready;
  logic seen1_io_in_8_ready, seen0_io_in_8_ready;
  wire  g_io_in_9_ready, i_io_in_9_ready;
  logic seen1_io_in_9_ready, seen0_io_in_9_ready;
  wire  g_io_in_10_ready, i_io_in_10_ready;
  logic seen1_io_in_10_ready, seen0_io_in_10_ready;
  wire  g_io_in_11_ready, i_io_in_11_ready;
  logic seen1_io_in_11_ready, seen0_io_in_11_ready;
  wire  g_io_in_12_ready, i_io_in_12_ready;
  logic seen1_io_in_12_ready, seen0_io_in_12_ready;
  wire  g_io_in_13_ready, i_io_in_13_ready;
  logic seen1_io_in_13_ready, seen0_io_in_13_ready;
  wire  g_io_in_14_ready, i_io_in_14_ready;
  logic seen1_io_in_14_ready, seen0_io_in_14_ready;
  wire  g_io_in_15_ready, i_io_in_15_ready;
  logic seen1_io_in_15_ready, seen0_io_in_15_ready;
  wire  g_io_out_valid, i_io_out_valid;
  logic seen1_io_out_valid, seen0_io_out_valid;
  wire  [3:0] g_io_out_bits_miss_id, i_io_out_bits_miss_id;
  logic [3:0] seen1_io_out_bits_miss_id, seen0_io_out_bits_miss_id;
  wire  [3:0] g_io_out_bits_occupy_way, i_io_out_bits_occupy_way;
  logic [3:0] seen1_io_out_bits_occupy_way, seen0_io_out_bits_occupy_way;
  wire  g_io_out_bits_miss_fail_cause_evict_btot, i_io_out_bits_miss_fail_cause_evict_btot;
  logic seen1_io_out_bits_miss_fail_cause_evict_btot, seen0_io_out_bits_miss_fail_cause_evict_btot;
  wire  [3:0] g_io_out_bits_source, i_io_out_bits_source;
  logic [3:0] seen1_io_out_bits_source, seen0_io_out_bits_source;
  wire  [4:0] g_io_out_bits_cmd, i_io_out_bits_cmd;
  logic [4:0] seen1_io_out_bits_cmd, seen0_io_out_bits_cmd;
  wire  [49:0] g_io_out_bits_vaddr, i_io_out_bits_vaddr;
  logic [49:0] seen1_io_out_bits_vaddr, seen0_io_out_bits_vaddr;
  wire  [47:0] g_io_out_bits_addr, i_io_out_bits_addr;
  logic [47:0] seen1_io_out_bits_addr, seen0_io_out_bits_addr;
  wire  [2:0] g_io_out_bits_word_idx, i_io_out_bits_word_idx;
  logic [2:0] seen1_io_out_bits_word_idx, seen0_io_out_bits_word_idx;
  wire  [127:0] g_io_out_bits_amo_data, i_io_out_bits_amo_data;
  logic [127:0] seen1_io_out_bits_amo_data, seen0_io_out_bits_amo_data;
  wire  [15:0] g_io_out_bits_amo_mask, i_io_out_bits_amo_mask;
  logic [15:0] seen1_io_out_bits_amo_mask, seen0_io_out_bits_amo_mask;
  wire  [127:0] g_io_out_bits_amo_cmp, i_io_out_bits_amo_cmp;
  logic [127:0] seen1_io_out_bits_amo_cmp, seen0_io_out_bits_amo_cmp;
  wire  [2:0] g_io_out_bits_pf_source, i_io_out_bits_pf_source;
  logic [2:0] seen1_io_out_bits_pf_source, seen0_io_out_bits_pf_source;
  wire  g_io_out_bits_access, i_io_out_bits_access;
  logic seen1_io_out_bits_access, seen0_io_out_bits_access;
  wire  [5:0] g_io_out_bits_id, i_io_out_bits_id;
  logic [5:0] seen1_io_out_bits_id, seen0_io_out_bits_id;

  Arbiter16_MainPipeReq u_gold (
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_miss_id(io_in_0_bits_miss_id),
    .io_in_0_bits_occupy_way(io_in_0_bits_occupy_way),
    .io_in_0_bits_miss_fail_cause_evict_btot(io_in_0_bits_miss_fail_cause_evict_btot),
    .io_in_0_bits_source(io_in_0_bits_source),
    .io_in_0_bits_cmd(io_in_0_bits_cmd),
    .io_in_0_bits_vaddr(io_in_0_bits_vaddr),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_word_idx(io_in_0_bits_word_idx),
    .io_in_0_bits_amo_data(io_in_0_bits_amo_data),
    .io_in_0_bits_amo_mask(io_in_0_bits_amo_mask),
    .io_in_0_bits_amo_cmp(io_in_0_bits_amo_cmp),
    .io_in_0_bits_pf_source(io_in_0_bits_pf_source),
    .io_in_0_bits_access(io_in_0_bits_access),
    .io_in_0_bits_id(io_in_0_bits_id),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_miss_id(io_in_1_bits_miss_id),
    .io_in_1_bits_occupy_way(io_in_1_bits_occupy_way),
    .io_in_1_bits_miss_fail_cause_evict_btot(io_in_1_bits_miss_fail_cause_evict_btot),
    .io_in_1_bits_source(io_in_1_bits_source),
    .io_in_1_bits_cmd(io_in_1_bits_cmd),
    .io_in_1_bits_vaddr(io_in_1_bits_vaddr),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_word_idx(io_in_1_bits_word_idx),
    .io_in_1_bits_amo_data(io_in_1_bits_amo_data),
    .io_in_1_bits_amo_mask(io_in_1_bits_amo_mask),
    .io_in_1_bits_amo_cmp(io_in_1_bits_amo_cmp),
    .io_in_1_bits_pf_source(io_in_1_bits_pf_source),
    .io_in_1_bits_access(io_in_1_bits_access),
    .io_in_1_bits_id(io_in_1_bits_id),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_miss_id(io_in_2_bits_miss_id),
    .io_in_2_bits_occupy_way(io_in_2_bits_occupy_way),
    .io_in_2_bits_miss_fail_cause_evict_btot(io_in_2_bits_miss_fail_cause_evict_btot),
    .io_in_2_bits_source(io_in_2_bits_source),
    .io_in_2_bits_cmd(io_in_2_bits_cmd),
    .io_in_2_bits_vaddr(io_in_2_bits_vaddr),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_word_idx(io_in_2_bits_word_idx),
    .io_in_2_bits_amo_data(io_in_2_bits_amo_data),
    .io_in_2_bits_amo_mask(io_in_2_bits_amo_mask),
    .io_in_2_bits_amo_cmp(io_in_2_bits_amo_cmp),
    .io_in_2_bits_pf_source(io_in_2_bits_pf_source),
    .io_in_2_bits_access(io_in_2_bits_access),
    .io_in_2_bits_id(io_in_2_bits_id),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_miss_id(io_in_3_bits_miss_id),
    .io_in_3_bits_occupy_way(io_in_3_bits_occupy_way),
    .io_in_3_bits_miss_fail_cause_evict_btot(io_in_3_bits_miss_fail_cause_evict_btot),
    .io_in_3_bits_source(io_in_3_bits_source),
    .io_in_3_bits_cmd(io_in_3_bits_cmd),
    .io_in_3_bits_vaddr(io_in_3_bits_vaddr),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_word_idx(io_in_3_bits_word_idx),
    .io_in_3_bits_amo_data(io_in_3_bits_amo_data),
    .io_in_3_bits_amo_mask(io_in_3_bits_amo_mask),
    .io_in_3_bits_amo_cmp(io_in_3_bits_amo_cmp),
    .io_in_3_bits_pf_source(io_in_3_bits_pf_source),
    .io_in_3_bits_access(io_in_3_bits_access),
    .io_in_3_bits_id(io_in_3_bits_id),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_miss_id(io_in_4_bits_miss_id),
    .io_in_4_bits_occupy_way(io_in_4_bits_occupy_way),
    .io_in_4_bits_miss_fail_cause_evict_btot(io_in_4_bits_miss_fail_cause_evict_btot),
    .io_in_4_bits_source(io_in_4_bits_source),
    .io_in_4_bits_cmd(io_in_4_bits_cmd),
    .io_in_4_bits_vaddr(io_in_4_bits_vaddr),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_word_idx(io_in_4_bits_word_idx),
    .io_in_4_bits_amo_data(io_in_4_bits_amo_data),
    .io_in_4_bits_amo_mask(io_in_4_bits_amo_mask),
    .io_in_4_bits_amo_cmp(io_in_4_bits_amo_cmp),
    .io_in_4_bits_pf_source(io_in_4_bits_pf_source),
    .io_in_4_bits_access(io_in_4_bits_access),
    .io_in_4_bits_id(io_in_4_bits_id),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_miss_id(io_in_5_bits_miss_id),
    .io_in_5_bits_occupy_way(io_in_5_bits_occupy_way),
    .io_in_5_bits_miss_fail_cause_evict_btot(io_in_5_bits_miss_fail_cause_evict_btot),
    .io_in_5_bits_source(io_in_5_bits_source),
    .io_in_5_bits_cmd(io_in_5_bits_cmd),
    .io_in_5_bits_vaddr(io_in_5_bits_vaddr),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_word_idx(io_in_5_bits_word_idx),
    .io_in_5_bits_amo_data(io_in_5_bits_amo_data),
    .io_in_5_bits_amo_mask(io_in_5_bits_amo_mask),
    .io_in_5_bits_amo_cmp(io_in_5_bits_amo_cmp),
    .io_in_5_bits_pf_source(io_in_5_bits_pf_source),
    .io_in_5_bits_access(io_in_5_bits_access),
    .io_in_5_bits_id(io_in_5_bits_id),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_miss_id(io_in_6_bits_miss_id),
    .io_in_6_bits_occupy_way(io_in_6_bits_occupy_way),
    .io_in_6_bits_miss_fail_cause_evict_btot(io_in_6_bits_miss_fail_cause_evict_btot),
    .io_in_6_bits_source(io_in_6_bits_source),
    .io_in_6_bits_cmd(io_in_6_bits_cmd),
    .io_in_6_bits_vaddr(io_in_6_bits_vaddr),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_word_idx(io_in_6_bits_word_idx),
    .io_in_6_bits_amo_data(io_in_6_bits_amo_data),
    .io_in_6_bits_amo_mask(io_in_6_bits_amo_mask),
    .io_in_6_bits_amo_cmp(io_in_6_bits_amo_cmp),
    .io_in_6_bits_pf_source(io_in_6_bits_pf_source),
    .io_in_6_bits_access(io_in_6_bits_access),
    .io_in_6_bits_id(io_in_6_bits_id),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_miss_id(io_in_7_bits_miss_id),
    .io_in_7_bits_occupy_way(io_in_7_bits_occupy_way),
    .io_in_7_bits_miss_fail_cause_evict_btot(io_in_7_bits_miss_fail_cause_evict_btot),
    .io_in_7_bits_source(io_in_7_bits_source),
    .io_in_7_bits_cmd(io_in_7_bits_cmd),
    .io_in_7_bits_vaddr(io_in_7_bits_vaddr),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_word_idx(io_in_7_bits_word_idx),
    .io_in_7_bits_amo_data(io_in_7_bits_amo_data),
    .io_in_7_bits_amo_mask(io_in_7_bits_amo_mask),
    .io_in_7_bits_amo_cmp(io_in_7_bits_amo_cmp),
    .io_in_7_bits_pf_source(io_in_7_bits_pf_source),
    .io_in_7_bits_access(io_in_7_bits_access),
    .io_in_7_bits_id(io_in_7_bits_id),
    .io_in_8_ready(g_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_miss_id(io_in_8_bits_miss_id),
    .io_in_8_bits_occupy_way(io_in_8_bits_occupy_way),
    .io_in_8_bits_miss_fail_cause_evict_btot(io_in_8_bits_miss_fail_cause_evict_btot),
    .io_in_8_bits_source(io_in_8_bits_source),
    .io_in_8_bits_cmd(io_in_8_bits_cmd),
    .io_in_8_bits_vaddr(io_in_8_bits_vaddr),
    .io_in_8_bits_addr(io_in_8_bits_addr),
    .io_in_8_bits_word_idx(io_in_8_bits_word_idx),
    .io_in_8_bits_amo_data(io_in_8_bits_amo_data),
    .io_in_8_bits_amo_mask(io_in_8_bits_amo_mask),
    .io_in_8_bits_amo_cmp(io_in_8_bits_amo_cmp),
    .io_in_8_bits_pf_source(io_in_8_bits_pf_source),
    .io_in_8_bits_access(io_in_8_bits_access),
    .io_in_8_bits_id(io_in_8_bits_id),
    .io_in_9_ready(g_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_miss_id(io_in_9_bits_miss_id),
    .io_in_9_bits_occupy_way(io_in_9_bits_occupy_way),
    .io_in_9_bits_miss_fail_cause_evict_btot(io_in_9_bits_miss_fail_cause_evict_btot),
    .io_in_9_bits_source(io_in_9_bits_source),
    .io_in_9_bits_cmd(io_in_9_bits_cmd),
    .io_in_9_bits_vaddr(io_in_9_bits_vaddr),
    .io_in_9_bits_addr(io_in_9_bits_addr),
    .io_in_9_bits_word_idx(io_in_9_bits_word_idx),
    .io_in_9_bits_amo_data(io_in_9_bits_amo_data),
    .io_in_9_bits_amo_mask(io_in_9_bits_amo_mask),
    .io_in_9_bits_amo_cmp(io_in_9_bits_amo_cmp),
    .io_in_9_bits_pf_source(io_in_9_bits_pf_source),
    .io_in_9_bits_access(io_in_9_bits_access),
    .io_in_9_bits_id(io_in_9_bits_id),
    .io_in_10_ready(g_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_miss_id(io_in_10_bits_miss_id),
    .io_in_10_bits_occupy_way(io_in_10_bits_occupy_way),
    .io_in_10_bits_miss_fail_cause_evict_btot(io_in_10_bits_miss_fail_cause_evict_btot),
    .io_in_10_bits_source(io_in_10_bits_source),
    .io_in_10_bits_cmd(io_in_10_bits_cmd),
    .io_in_10_bits_vaddr(io_in_10_bits_vaddr),
    .io_in_10_bits_addr(io_in_10_bits_addr),
    .io_in_10_bits_word_idx(io_in_10_bits_word_idx),
    .io_in_10_bits_amo_data(io_in_10_bits_amo_data),
    .io_in_10_bits_amo_mask(io_in_10_bits_amo_mask),
    .io_in_10_bits_amo_cmp(io_in_10_bits_amo_cmp),
    .io_in_10_bits_pf_source(io_in_10_bits_pf_source),
    .io_in_10_bits_access(io_in_10_bits_access),
    .io_in_10_bits_id(io_in_10_bits_id),
    .io_in_11_ready(g_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_miss_id(io_in_11_bits_miss_id),
    .io_in_11_bits_occupy_way(io_in_11_bits_occupy_way),
    .io_in_11_bits_miss_fail_cause_evict_btot(io_in_11_bits_miss_fail_cause_evict_btot),
    .io_in_11_bits_source(io_in_11_bits_source),
    .io_in_11_bits_cmd(io_in_11_bits_cmd),
    .io_in_11_bits_vaddr(io_in_11_bits_vaddr),
    .io_in_11_bits_addr(io_in_11_bits_addr),
    .io_in_11_bits_word_idx(io_in_11_bits_word_idx),
    .io_in_11_bits_amo_data(io_in_11_bits_amo_data),
    .io_in_11_bits_amo_mask(io_in_11_bits_amo_mask),
    .io_in_11_bits_amo_cmp(io_in_11_bits_amo_cmp),
    .io_in_11_bits_pf_source(io_in_11_bits_pf_source),
    .io_in_11_bits_access(io_in_11_bits_access),
    .io_in_11_bits_id(io_in_11_bits_id),
    .io_in_12_ready(g_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_miss_id(io_in_12_bits_miss_id),
    .io_in_12_bits_occupy_way(io_in_12_bits_occupy_way),
    .io_in_12_bits_miss_fail_cause_evict_btot(io_in_12_bits_miss_fail_cause_evict_btot),
    .io_in_12_bits_source(io_in_12_bits_source),
    .io_in_12_bits_cmd(io_in_12_bits_cmd),
    .io_in_12_bits_vaddr(io_in_12_bits_vaddr),
    .io_in_12_bits_addr(io_in_12_bits_addr),
    .io_in_12_bits_word_idx(io_in_12_bits_word_idx),
    .io_in_12_bits_amo_data(io_in_12_bits_amo_data),
    .io_in_12_bits_amo_mask(io_in_12_bits_amo_mask),
    .io_in_12_bits_amo_cmp(io_in_12_bits_amo_cmp),
    .io_in_12_bits_pf_source(io_in_12_bits_pf_source),
    .io_in_12_bits_access(io_in_12_bits_access),
    .io_in_12_bits_id(io_in_12_bits_id),
    .io_in_13_ready(g_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_miss_id(io_in_13_bits_miss_id),
    .io_in_13_bits_occupy_way(io_in_13_bits_occupy_way),
    .io_in_13_bits_miss_fail_cause_evict_btot(io_in_13_bits_miss_fail_cause_evict_btot),
    .io_in_13_bits_source(io_in_13_bits_source),
    .io_in_13_bits_cmd(io_in_13_bits_cmd),
    .io_in_13_bits_vaddr(io_in_13_bits_vaddr),
    .io_in_13_bits_addr(io_in_13_bits_addr),
    .io_in_13_bits_word_idx(io_in_13_bits_word_idx),
    .io_in_13_bits_amo_data(io_in_13_bits_amo_data),
    .io_in_13_bits_amo_mask(io_in_13_bits_amo_mask),
    .io_in_13_bits_amo_cmp(io_in_13_bits_amo_cmp),
    .io_in_13_bits_pf_source(io_in_13_bits_pf_source),
    .io_in_13_bits_access(io_in_13_bits_access),
    .io_in_13_bits_id(io_in_13_bits_id),
    .io_in_14_ready(g_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_miss_id(io_in_14_bits_miss_id),
    .io_in_14_bits_occupy_way(io_in_14_bits_occupy_way),
    .io_in_14_bits_miss_fail_cause_evict_btot(io_in_14_bits_miss_fail_cause_evict_btot),
    .io_in_14_bits_source(io_in_14_bits_source),
    .io_in_14_bits_cmd(io_in_14_bits_cmd),
    .io_in_14_bits_vaddr(io_in_14_bits_vaddr),
    .io_in_14_bits_addr(io_in_14_bits_addr),
    .io_in_14_bits_word_idx(io_in_14_bits_word_idx),
    .io_in_14_bits_amo_data(io_in_14_bits_amo_data),
    .io_in_14_bits_amo_mask(io_in_14_bits_amo_mask),
    .io_in_14_bits_amo_cmp(io_in_14_bits_amo_cmp),
    .io_in_14_bits_pf_source(io_in_14_bits_pf_source),
    .io_in_14_bits_access(io_in_14_bits_access),
    .io_in_14_bits_id(io_in_14_bits_id),
    .io_in_15_ready(g_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_miss_id(io_in_15_bits_miss_id),
    .io_in_15_bits_occupy_way(io_in_15_bits_occupy_way),
    .io_in_15_bits_miss_fail_cause_evict_btot(io_in_15_bits_miss_fail_cause_evict_btot),
    .io_in_15_bits_source(io_in_15_bits_source),
    .io_in_15_bits_cmd(io_in_15_bits_cmd),
    .io_in_15_bits_vaddr(io_in_15_bits_vaddr),
    .io_in_15_bits_addr(io_in_15_bits_addr),
    .io_in_15_bits_word_idx(io_in_15_bits_word_idx),
    .io_in_15_bits_amo_data(io_in_15_bits_amo_data),
    .io_in_15_bits_amo_mask(io_in_15_bits_amo_mask),
    .io_in_15_bits_amo_cmp(io_in_15_bits_amo_cmp),
    .io_in_15_bits_pf_source(io_in_15_bits_pf_source),
    .io_in_15_bits_access(io_in_15_bits_access),
    .io_in_15_bits_id(io_in_15_bits_id),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_miss_id(g_io_out_bits_miss_id),
    .io_out_bits_occupy_way(g_io_out_bits_occupy_way),
    .io_out_bits_miss_fail_cause_evict_btot(g_io_out_bits_miss_fail_cause_evict_btot),
    .io_out_bits_source(g_io_out_bits_source),
    .io_out_bits_cmd(g_io_out_bits_cmd),
    .io_out_bits_vaddr(g_io_out_bits_vaddr),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_word_idx(g_io_out_bits_word_idx),
    .io_out_bits_amo_data(g_io_out_bits_amo_data),
    .io_out_bits_amo_mask(g_io_out_bits_amo_mask),
    .io_out_bits_amo_cmp(g_io_out_bits_amo_cmp),
    .io_out_bits_pf_source(g_io_out_bits_pf_source),
    .io_out_bits_access(g_io_out_bits_access),
    .io_out_bits_id(g_io_out_bits_id)
  );
  Arbiter16_MainPipeReq_xs u_impl (
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_miss_id(io_in_0_bits_miss_id),
    .io_in_0_bits_occupy_way(io_in_0_bits_occupy_way),
    .io_in_0_bits_miss_fail_cause_evict_btot(io_in_0_bits_miss_fail_cause_evict_btot),
    .io_in_0_bits_source(io_in_0_bits_source),
    .io_in_0_bits_cmd(io_in_0_bits_cmd),
    .io_in_0_bits_vaddr(io_in_0_bits_vaddr),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_word_idx(io_in_0_bits_word_idx),
    .io_in_0_bits_amo_data(io_in_0_bits_amo_data),
    .io_in_0_bits_amo_mask(io_in_0_bits_amo_mask),
    .io_in_0_bits_amo_cmp(io_in_0_bits_amo_cmp),
    .io_in_0_bits_pf_source(io_in_0_bits_pf_source),
    .io_in_0_bits_access(io_in_0_bits_access),
    .io_in_0_bits_id(io_in_0_bits_id),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_miss_id(io_in_1_bits_miss_id),
    .io_in_1_bits_occupy_way(io_in_1_bits_occupy_way),
    .io_in_1_bits_miss_fail_cause_evict_btot(io_in_1_bits_miss_fail_cause_evict_btot),
    .io_in_1_bits_source(io_in_1_bits_source),
    .io_in_1_bits_cmd(io_in_1_bits_cmd),
    .io_in_1_bits_vaddr(io_in_1_bits_vaddr),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_word_idx(io_in_1_bits_word_idx),
    .io_in_1_bits_amo_data(io_in_1_bits_amo_data),
    .io_in_1_bits_amo_mask(io_in_1_bits_amo_mask),
    .io_in_1_bits_amo_cmp(io_in_1_bits_amo_cmp),
    .io_in_1_bits_pf_source(io_in_1_bits_pf_source),
    .io_in_1_bits_access(io_in_1_bits_access),
    .io_in_1_bits_id(io_in_1_bits_id),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_miss_id(io_in_2_bits_miss_id),
    .io_in_2_bits_occupy_way(io_in_2_bits_occupy_way),
    .io_in_2_bits_miss_fail_cause_evict_btot(io_in_2_bits_miss_fail_cause_evict_btot),
    .io_in_2_bits_source(io_in_2_bits_source),
    .io_in_2_bits_cmd(io_in_2_bits_cmd),
    .io_in_2_bits_vaddr(io_in_2_bits_vaddr),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_word_idx(io_in_2_bits_word_idx),
    .io_in_2_bits_amo_data(io_in_2_bits_amo_data),
    .io_in_2_bits_amo_mask(io_in_2_bits_amo_mask),
    .io_in_2_bits_amo_cmp(io_in_2_bits_amo_cmp),
    .io_in_2_bits_pf_source(io_in_2_bits_pf_source),
    .io_in_2_bits_access(io_in_2_bits_access),
    .io_in_2_bits_id(io_in_2_bits_id),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_miss_id(io_in_3_bits_miss_id),
    .io_in_3_bits_occupy_way(io_in_3_bits_occupy_way),
    .io_in_3_bits_miss_fail_cause_evict_btot(io_in_3_bits_miss_fail_cause_evict_btot),
    .io_in_3_bits_source(io_in_3_bits_source),
    .io_in_3_bits_cmd(io_in_3_bits_cmd),
    .io_in_3_bits_vaddr(io_in_3_bits_vaddr),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_word_idx(io_in_3_bits_word_idx),
    .io_in_3_bits_amo_data(io_in_3_bits_amo_data),
    .io_in_3_bits_amo_mask(io_in_3_bits_amo_mask),
    .io_in_3_bits_amo_cmp(io_in_3_bits_amo_cmp),
    .io_in_3_bits_pf_source(io_in_3_bits_pf_source),
    .io_in_3_bits_access(io_in_3_bits_access),
    .io_in_3_bits_id(io_in_3_bits_id),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_miss_id(io_in_4_bits_miss_id),
    .io_in_4_bits_occupy_way(io_in_4_bits_occupy_way),
    .io_in_4_bits_miss_fail_cause_evict_btot(io_in_4_bits_miss_fail_cause_evict_btot),
    .io_in_4_bits_source(io_in_4_bits_source),
    .io_in_4_bits_cmd(io_in_4_bits_cmd),
    .io_in_4_bits_vaddr(io_in_4_bits_vaddr),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_word_idx(io_in_4_bits_word_idx),
    .io_in_4_bits_amo_data(io_in_4_bits_amo_data),
    .io_in_4_bits_amo_mask(io_in_4_bits_amo_mask),
    .io_in_4_bits_amo_cmp(io_in_4_bits_amo_cmp),
    .io_in_4_bits_pf_source(io_in_4_bits_pf_source),
    .io_in_4_bits_access(io_in_4_bits_access),
    .io_in_4_bits_id(io_in_4_bits_id),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_miss_id(io_in_5_bits_miss_id),
    .io_in_5_bits_occupy_way(io_in_5_bits_occupy_way),
    .io_in_5_bits_miss_fail_cause_evict_btot(io_in_5_bits_miss_fail_cause_evict_btot),
    .io_in_5_bits_source(io_in_5_bits_source),
    .io_in_5_bits_cmd(io_in_5_bits_cmd),
    .io_in_5_bits_vaddr(io_in_5_bits_vaddr),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_word_idx(io_in_5_bits_word_idx),
    .io_in_5_bits_amo_data(io_in_5_bits_amo_data),
    .io_in_5_bits_amo_mask(io_in_5_bits_amo_mask),
    .io_in_5_bits_amo_cmp(io_in_5_bits_amo_cmp),
    .io_in_5_bits_pf_source(io_in_5_bits_pf_source),
    .io_in_5_bits_access(io_in_5_bits_access),
    .io_in_5_bits_id(io_in_5_bits_id),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_miss_id(io_in_6_bits_miss_id),
    .io_in_6_bits_occupy_way(io_in_6_bits_occupy_way),
    .io_in_6_bits_miss_fail_cause_evict_btot(io_in_6_bits_miss_fail_cause_evict_btot),
    .io_in_6_bits_source(io_in_6_bits_source),
    .io_in_6_bits_cmd(io_in_6_bits_cmd),
    .io_in_6_bits_vaddr(io_in_6_bits_vaddr),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_word_idx(io_in_6_bits_word_idx),
    .io_in_6_bits_amo_data(io_in_6_bits_amo_data),
    .io_in_6_bits_amo_mask(io_in_6_bits_amo_mask),
    .io_in_6_bits_amo_cmp(io_in_6_bits_amo_cmp),
    .io_in_6_bits_pf_source(io_in_6_bits_pf_source),
    .io_in_6_bits_access(io_in_6_bits_access),
    .io_in_6_bits_id(io_in_6_bits_id),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_miss_id(io_in_7_bits_miss_id),
    .io_in_7_bits_occupy_way(io_in_7_bits_occupy_way),
    .io_in_7_bits_miss_fail_cause_evict_btot(io_in_7_bits_miss_fail_cause_evict_btot),
    .io_in_7_bits_source(io_in_7_bits_source),
    .io_in_7_bits_cmd(io_in_7_bits_cmd),
    .io_in_7_bits_vaddr(io_in_7_bits_vaddr),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_word_idx(io_in_7_bits_word_idx),
    .io_in_7_bits_amo_data(io_in_7_bits_amo_data),
    .io_in_7_bits_amo_mask(io_in_7_bits_amo_mask),
    .io_in_7_bits_amo_cmp(io_in_7_bits_amo_cmp),
    .io_in_7_bits_pf_source(io_in_7_bits_pf_source),
    .io_in_7_bits_access(io_in_7_bits_access),
    .io_in_7_bits_id(io_in_7_bits_id),
    .io_in_8_ready(i_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_miss_id(io_in_8_bits_miss_id),
    .io_in_8_bits_occupy_way(io_in_8_bits_occupy_way),
    .io_in_8_bits_miss_fail_cause_evict_btot(io_in_8_bits_miss_fail_cause_evict_btot),
    .io_in_8_bits_source(io_in_8_bits_source),
    .io_in_8_bits_cmd(io_in_8_bits_cmd),
    .io_in_8_bits_vaddr(io_in_8_bits_vaddr),
    .io_in_8_bits_addr(io_in_8_bits_addr),
    .io_in_8_bits_word_idx(io_in_8_bits_word_idx),
    .io_in_8_bits_amo_data(io_in_8_bits_amo_data),
    .io_in_8_bits_amo_mask(io_in_8_bits_amo_mask),
    .io_in_8_bits_amo_cmp(io_in_8_bits_amo_cmp),
    .io_in_8_bits_pf_source(io_in_8_bits_pf_source),
    .io_in_8_bits_access(io_in_8_bits_access),
    .io_in_8_bits_id(io_in_8_bits_id),
    .io_in_9_ready(i_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_miss_id(io_in_9_bits_miss_id),
    .io_in_9_bits_occupy_way(io_in_9_bits_occupy_way),
    .io_in_9_bits_miss_fail_cause_evict_btot(io_in_9_bits_miss_fail_cause_evict_btot),
    .io_in_9_bits_source(io_in_9_bits_source),
    .io_in_9_bits_cmd(io_in_9_bits_cmd),
    .io_in_9_bits_vaddr(io_in_9_bits_vaddr),
    .io_in_9_bits_addr(io_in_9_bits_addr),
    .io_in_9_bits_word_idx(io_in_9_bits_word_idx),
    .io_in_9_bits_amo_data(io_in_9_bits_amo_data),
    .io_in_9_bits_amo_mask(io_in_9_bits_amo_mask),
    .io_in_9_bits_amo_cmp(io_in_9_bits_amo_cmp),
    .io_in_9_bits_pf_source(io_in_9_bits_pf_source),
    .io_in_9_bits_access(io_in_9_bits_access),
    .io_in_9_bits_id(io_in_9_bits_id),
    .io_in_10_ready(i_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_miss_id(io_in_10_bits_miss_id),
    .io_in_10_bits_occupy_way(io_in_10_bits_occupy_way),
    .io_in_10_bits_miss_fail_cause_evict_btot(io_in_10_bits_miss_fail_cause_evict_btot),
    .io_in_10_bits_source(io_in_10_bits_source),
    .io_in_10_bits_cmd(io_in_10_bits_cmd),
    .io_in_10_bits_vaddr(io_in_10_bits_vaddr),
    .io_in_10_bits_addr(io_in_10_bits_addr),
    .io_in_10_bits_word_idx(io_in_10_bits_word_idx),
    .io_in_10_bits_amo_data(io_in_10_bits_amo_data),
    .io_in_10_bits_amo_mask(io_in_10_bits_amo_mask),
    .io_in_10_bits_amo_cmp(io_in_10_bits_amo_cmp),
    .io_in_10_bits_pf_source(io_in_10_bits_pf_source),
    .io_in_10_bits_access(io_in_10_bits_access),
    .io_in_10_bits_id(io_in_10_bits_id),
    .io_in_11_ready(i_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_miss_id(io_in_11_bits_miss_id),
    .io_in_11_bits_occupy_way(io_in_11_bits_occupy_way),
    .io_in_11_bits_miss_fail_cause_evict_btot(io_in_11_bits_miss_fail_cause_evict_btot),
    .io_in_11_bits_source(io_in_11_bits_source),
    .io_in_11_bits_cmd(io_in_11_bits_cmd),
    .io_in_11_bits_vaddr(io_in_11_bits_vaddr),
    .io_in_11_bits_addr(io_in_11_bits_addr),
    .io_in_11_bits_word_idx(io_in_11_bits_word_idx),
    .io_in_11_bits_amo_data(io_in_11_bits_amo_data),
    .io_in_11_bits_amo_mask(io_in_11_bits_amo_mask),
    .io_in_11_bits_amo_cmp(io_in_11_bits_amo_cmp),
    .io_in_11_bits_pf_source(io_in_11_bits_pf_source),
    .io_in_11_bits_access(io_in_11_bits_access),
    .io_in_11_bits_id(io_in_11_bits_id),
    .io_in_12_ready(i_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_miss_id(io_in_12_bits_miss_id),
    .io_in_12_bits_occupy_way(io_in_12_bits_occupy_way),
    .io_in_12_bits_miss_fail_cause_evict_btot(io_in_12_bits_miss_fail_cause_evict_btot),
    .io_in_12_bits_source(io_in_12_bits_source),
    .io_in_12_bits_cmd(io_in_12_bits_cmd),
    .io_in_12_bits_vaddr(io_in_12_bits_vaddr),
    .io_in_12_bits_addr(io_in_12_bits_addr),
    .io_in_12_bits_word_idx(io_in_12_bits_word_idx),
    .io_in_12_bits_amo_data(io_in_12_bits_amo_data),
    .io_in_12_bits_amo_mask(io_in_12_bits_amo_mask),
    .io_in_12_bits_amo_cmp(io_in_12_bits_amo_cmp),
    .io_in_12_bits_pf_source(io_in_12_bits_pf_source),
    .io_in_12_bits_access(io_in_12_bits_access),
    .io_in_12_bits_id(io_in_12_bits_id),
    .io_in_13_ready(i_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_miss_id(io_in_13_bits_miss_id),
    .io_in_13_bits_occupy_way(io_in_13_bits_occupy_way),
    .io_in_13_bits_miss_fail_cause_evict_btot(io_in_13_bits_miss_fail_cause_evict_btot),
    .io_in_13_bits_source(io_in_13_bits_source),
    .io_in_13_bits_cmd(io_in_13_bits_cmd),
    .io_in_13_bits_vaddr(io_in_13_bits_vaddr),
    .io_in_13_bits_addr(io_in_13_bits_addr),
    .io_in_13_bits_word_idx(io_in_13_bits_word_idx),
    .io_in_13_bits_amo_data(io_in_13_bits_amo_data),
    .io_in_13_bits_amo_mask(io_in_13_bits_amo_mask),
    .io_in_13_bits_amo_cmp(io_in_13_bits_amo_cmp),
    .io_in_13_bits_pf_source(io_in_13_bits_pf_source),
    .io_in_13_bits_access(io_in_13_bits_access),
    .io_in_13_bits_id(io_in_13_bits_id),
    .io_in_14_ready(i_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_miss_id(io_in_14_bits_miss_id),
    .io_in_14_bits_occupy_way(io_in_14_bits_occupy_way),
    .io_in_14_bits_miss_fail_cause_evict_btot(io_in_14_bits_miss_fail_cause_evict_btot),
    .io_in_14_bits_source(io_in_14_bits_source),
    .io_in_14_bits_cmd(io_in_14_bits_cmd),
    .io_in_14_bits_vaddr(io_in_14_bits_vaddr),
    .io_in_14_bits_addr(io_in_14_bits_addr),
    .io_in_14_bits_word_idx(io_in_14_bits_word_idx),
    .io_in_14_bits_amo_data(io_in_14_bits_amo_data),
    .io_in_14_bits_amo_mask(io_in_14_bits_amo_mask),
    .io_in_14_bits_amo_cmp(io_in_14_bits_amo_cmp),
    .io_in_14_bits_pf_source(io_in_14_bits_pf_source),
    .io_in_14_bits_access(io_in_14_bits_access),
    .io_in_14_bits_id(io_in_14_bits_id),
    .io_in_15_ready(i_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_miss_id(io_in_15_bits_miss_id),
    .io_in_15_bits_occupy_way(io_in_15_bits_occupy_way),
    .io_in_15_bits_miss_fail_cause_evict_btot(io_in_15_bits_miss_fail_cause_evict_btot),
    .io_in_15_bits_source(io_in_15_bits_source),
    .io_in_15_bits_cmd(io_in_15_bits_cmd),
    .io_in_15_bits_vaddr(io_in_15_bits_vaddr),
    .io_in_15_bits_addr(io_in_15_bits_addr),
    .io_in_15_bits_word_idx(io_in_15_bits_word_idx),
    .io_in_15_bits_amo_data(io_in_15_bits_amo_data),
    .io_in_15_bits_amo_mask(io_in_15_bits_amo_mask),
    .io_in_15_bits_amo_cmp(io_in_15_bits_amo_cmp),
    .io_in_15_bits_pf_source(io_in_15_bits_pf_source),
    .io_in_15_bits_access(io_in_15_bits_access),
    .io_in_15_bits_id(io_in_15_bits_id),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_miss_id(i_io_out_bits_miss_id),
    .io_out_bits_occupy_way(i_io_out_bits_occupy_way),
    .io_out_bits_miss_fail_cause_evict_btot(i_io_out_bits_miss_fail_cause_evict_btot),
    .io_out_bits_source(i_io_out_bits_source),
    .io_out_bits_cmd(i_io_out_bits_cmd),
    .io_out_bits_vaddr(i_io_out_bits_vaddr),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_word_idx(i_io_out_bits_word_idx),
    .io_out_bits_amo_data(i_io_out_bits_amo_data),
    .io_out_bits_amo_mask(i_io_out_bits_amo_mask),
    .io_out_bits_amo_cmp(i_io_out_bits_amo_cmp),
    .io_out_bits_pf_source(i_io_out_bits_pf_source),
    .io_out_bits_access(i_io_out_bits_access),
    .io_out_bits_id(i_io_out_bits_id)
  );

  task automatic drive();
    int mode = $urandom_range(0, 3);
    logic [15:0] v;
    case (mode)
      0: v = '0;
      1: v = 16'(1) << $urandom_range(0, 15);
      2: v = 16'($urandom) & 16'($urandom) & 16'($urandom);
      default: v = 16'($urandom);
    endcase
    {io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid, io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid, io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid} = v;
    io_in_0_bits_miss_id = 4'($urandom);
    io_in_0_bits_occupy_way = 4'($urandom);
    io_in_0_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_0_bits_source = 4'($urandom);
    io_in_0_bits_cmd = 5'($urandom);
    io_in_0_bits_vaddr = 50'({$urandom, $urandom});
    io_in_0_bits_addr = 48'({$urandom, $urandom});
    io_in_0_bits_word_idx = 3'($urandom);
    io_in_0_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_0_bits_amo_mask = 16'($urandom);
    io_in_0_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_0_bits_pf_source = 3'($urandom);
    io_in_0_bits_access = 1'($urandom);
    io_in_0_bits_id = 6'($urandom);
    io_in_1_bits_miss_id = 4'($urandom);
    io_in_1_bits_occupy_way = 4'($urandom);
    io_in_1_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_1_bits_source = 4'($urandom);
    io_in_1_bits_cmd = 5'($urandom);
    io_in_1_bits_vaddr = 50'({$urandom, $urandom});
    io_in_1_bits_addr = 48'({$urandom, $urandom});
    io_in_1_bits_word_idx = 3'($urandom);
    io_in_1_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_1_bits_amo_mask = 16'($urandom);
    io_in_1_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_1_bits_pf_source = 3'($urandom);
    io_in_1_bits_access = 1'($urandom);
    io_in_1_bits_id = 6'($urandom);
    io_in_2_bits_miss_id = 4'($urandom);
    io_in_2_bits_occupy_way = 4'($urandom);
    io_in_2_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_2_bits_source = 4'($urandom);
    io_in_2_bits_cmd = 5'($urandom);
    io_in_2_bits_vaddr = 50'({$urandom, $urandom});
    io_in_2_bits_addr = 48'({$urandom, $urandom});
    io_in_2_bits_word_idx = 3'($urandom);
    io_in_2_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_2_bits_amo_mask = 16'($urandom);
    io_in_2_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_2_bits_pf_source = 3'($urandom);
    io_in_2_bits_access = 1'($urandom);
    io_in_2_bits_id = 6'($urandom);
    io_in_3_bits_miss_id = 4'($urandom);
    io_in_3_bits_occupy_way = 4'($urandom);
    io_in_3_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_3_bits_source = 4'($urandom);
    io_in_3_bits_cmd = 5'($urandom);
    io_in_3_bits_vaddr = 50'({$urandom, $urandom});
    io_in_3_bits_addr = 48'({$urandom, $urandom});
    io_in_3_bits_word_idx = 3'($urandom);
    io_in_3_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_3_bits_amo_mask = 16'($urandom);
    io_in_3_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_3_bits_pf_source = 3'($urandom);
    io_in_3_bits_access = 1'($urandom);
    io_in_3_bits_id = 6'($urandom);
    io_in_4_bits_miss_id = 4'($urandom);
    io_in_4_bits_occupy_way = 4'($urandom);
    io_in_4_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_4_bits_source = 4'($urandom);
    io_in_4_bits_cmd = 5'($urandom);
    io_in_4_bits_vaddr = 50'({$urandom, $urandom});
    io_in_4_bits_addr = 48'({$urandom, $urandom});
    io_in_4_bits_word_idx = 3'($urandom);
    io_in_4_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_4_bits_amo_mask = 16'($urandom);
    io_in_4_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_4_bits_pf_source = 3'($urandom);
    io_in_4_bits_access = 1'($urandom);
    io_in_4_bits_id = 6'($urandom);
    io_in_5_bits_miss_id = 4'($urandom);
    io_in_5_bits_occupy_way = 4'($urandom);
    io_in_5_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_5_bits_source = 4'($urandom);
    io_in_5_bits_cmd = 5'($urandom);
    io_in_5_bits_vaddr = 50'({$urandom, $urandom});
    io_in_5_bits_addr = 48'({$urandom, $urandom});
    io_in_5_bits_word_idx = 3'($urandom);
    io_in_5_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_5_bits_amo_mask = 16'($urandom);
    io_in_5_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_5_bits_pf_source = 3'($urandom);
    io_in_5_bits_access = 1'($urandom);
    io_in_5_bits_id = 6'($urandom);
    io_in_6_bits_miss_id = 4'($urandom);
    io_in_6_bits_occupy_way = 4'($urandom);
    io_in_6_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_6_bits_source = 4'($urandom);
    io_in_6_bits_cmd = 5'($urandom);
    io_in_6_bits_vaddr = 50'({$urandom, $urandom});
    io_in_6_bits_addr = 48'({$urandom, $urandom});
    io_in_6_bits_word_idx = 3'($urandom);
    io_in_6_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_6_bits_amo_mask = 16'($urandom);
    io_in_6_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_6_bits_pf_source = 3'($urandom);
    io_in_6_bits_access = 1'($urandom);
    io_in_6_bits_id = 6'($urandom);
    io_in_7_bits_miss_id = 4'($urandom);
    io_in_7_bits_occupy_way = 4'($urandom);
    io_in_7_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_7_bits_source = 4'($urandom);
    io_in_7_bits_cmd = 5'($urandom);
    io_in_7_bits_vaddr = 50'({$urandom, $urandom});
    io_in_7_bits_addr = 48'({$urandom, $urandom});
    io_in_7_bits_word_idx = 3'($urandom);
    io_in_7_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_7_bits_amo_mask = 16'($urandom);
    io_in_7_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_7_bits_pf_source = 3'($urandom);
    io_in_7_bits_access = 1'($urandom);
    io_in_7_bits_id = 6'($urandom);
    io_in_8_bits_miss_id = 4'($urandom);
    io_in_8_bits_occupy_way = 4'($urandom);
    io_in_8_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_8_bits_source = 4'($urandom);
    io_in_8_bits_cmd = 5'($urandom);
    io_in_8_bits_vaddr = 50'({$urandom, $urandom});
    io_in_8_bits_addr = 48'({$urandom, $urandom});
    io_in_8_bits_word_idx = 3'($urandom);
    io_in_8_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_8_bits_amo_mask = 16'($urandom);
    io_in_8_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_8_bits_pf_source = 3'($urandom);
    io_in_8_bits_access = 1'($urandom);
    io_in_8_bits_id = 6'($urandom);
    io_in_9_bits_miss_id = 4'($urandom);
    io_in_9_bits_occupy_way = 4'($urandom);
    io_in_9_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_9_bits_source = 4'($urandom);
    io_in_9_bits_cmd = 5'($urandom);
    io_in_9_bits_vaddr = 50'({$urandom, $urandom});
    io_in_9_bits_addr = 48'({$urandom, $urandom});
    io_in_9_bits_word_idx = 3'($urandom);
    io_in_9_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_9_bits_amo_mask = 16'($urandom);
    io_in_9_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_9_bits_pf_source = 3'($urandom);
    io_in_9_bits_access = 1'($urandom);
    io_in_9_bits_id = 6'($urandom);
    io_in_10_bits_miss_id = 4'($urandom);
    io_in_10_bits_occupy_way = 4'($urandom);
    io_in_10_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_10_bits_source = 4'($urandom);
    io_in_10_bits_cmd = 5'($urandom);
    io_in_10_bits_vaddr = 50'({$urandom, $urandom});
    io_in_10_bits_addr = 48'({$urandom, $urandom});
    io_in_10_bits_word_idx = 3'($urandom);
    io_in_10_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_10_bits_amo_mask = 16'($urandom);
    io_in_10_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_10_bits_pf_source = 3'($urandom);
    io_in_10_bits_access = 1'($urandom);
    io_in_10_bits_id = 6'($urandom);
    io_in_11_bits_miss_id = 4'($urandom);
    io_in_11_bits_occupy_way = 4'($urandom);
    io_in_11_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_11_bits_source = 4'($urandom);
    io_in_11_bits_cmd = 5'($urandom);
    io_in_11_bits_vaddr = 50'({$urandom, $urandom});
    io_in_11_bits_addr = 48'({$urandom, $urandom});
    io_in_11_bits_word_idx = 3'($urandom);
    io_in_11_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_11_bits_amo_mask = 16'($urandom);
    io_in_11_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_11_bits_pf_source = 3'($urandom);
    io_in_11_bits_access = 1'($urandom);
    io_in_11_bits_id = 6'($urandom);
    io_in_12_bits_miss_id = 4'($urandom);
    io_in_12_bits_occupy_way = 4'($urandom);
    io_in_12_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_12_bits_source = 4'($urandom);
    io_in_12_bits_cmd = 5'($urandom);
    io_in_12_bits_vaddr = 50'({$urandom, $urandom});
    io_in_12_bits_addr = 48'({$urandom, $urandom});
    io_in_12_bits_word_idx = 3'($urandom);
    io_in_12_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_12_bits_amo_mask = 16'($urandom);
    io_in_12_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_12_bits_pf_source = 3'($urandom);
    io_in_12_bits_access = 1'($urandom);
    io_in_12_bits_id = 6'($urandom);
    io_in_13_bits_miss_id = 4'($urandom);
    io_in_13_bits_occupy_way = 4'($urandom);
    io_in_13_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_13_bits_source = 4'($urandom);
    io_in_13_bits_cmd = 5'($urandom);
    io_in_13_bits_vaddr = 50'({$urandom, $urandom});
    io_in_13_bits_addr = 48'({$urandom, $urandom});
    io_in_13_bits_word_idx = 3'($urandom);
    io_in_13_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_13_bits_amo_mask = 16'($urandom);
    io_in_13_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_13_bits_pf_source = 3'($urandom);
    io_in_13_bits_access = 1'($urandom);
    io_in_13_bits_id = 6'($urandom);
    io_in_14_bits_miss_id = 4'($urandom);
    io_in_14_bits_occupy_way = 4'($urandom);
    io_in_14_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_14_bits_source = 4'($urandom);
    io_in_14_bits_cmd = 5'($urandom);
    io_in_14_bits_vaddr = 50'({$urandom, $urandom});
    io_in_14_bits_addr = 48'({$urandom, $urandom});
    io_in_14_bits_word_idx = 3'($urandom);
    io_in_14_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_14_bits_amo_mask = 16'($urandom);
    io_in_14_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_14_bits_pf_source = 3'($urandom);
    io_in_14_bits_access = 1'($urandom);
    io_in_14_bits_id = 6'($urandom);
    io_in_15_bits_miss_id = 4'($urandom);
    io_in_15_bits_occupy_way = 4'($urandom);
    io_in_15_bits_miss_fail_cause_evict_btot = 1'($urandom);
    io_in_15_bits_source = 4'($urandom);
    io_in_15_bits_cmd = 5'($urandom);
    io_in_15_bits_vaddr = 50'({$urandom, $urandom});
    io_in_15_bits_addr = 48'({$urandom, $urandom});
    io_in_15_bits_word_idx = 3'($urandom);
    io_in_15_bits_amo_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_15_bits_amo_mask = 16'($urandom);
    io_in_15_bits_amo_cmp = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_15_bits_pf_source = 3'($urandom);
    io_in_15_bits_access = 1'($urandom);
    io_in_15_bits_id = 6'($urandom);
    io_out_ready = 1'($urandom);
  endtask

  task automatic compare();
    if (g_io_in_0_ready !== i_io_in_0_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_0_ready: g=%h i=%h", checks, g_io_in_0_ready, i_io_in_0_ready);
    end
    seen1_io_in_0_ready |= g_io_in_0_ready;
    seen0_io_in_0_ready |= ~g_io_in_0_ready;
    if (g_io_in_1_ready !== i_io_in_1_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_1_ready: g=%h i=%h", checks, g_io_in_1_ready, i_io_in_1_ready);
    end
    seen1_io_in_1_ready |= g_io_in_1_ready;
    seen0_io_in_1_ready |= ~g_io_in_1_ready;
    if (g_io_in_2_ready !== i_io_in_2_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_2_ready: g=%h i=%h", checks, g_io_in_2_ready, i_io_in_2_ready);
    end
    seen1_io_in_2_ready |= g_io_in_2_ready;
    seen0_io_in_2_ready |= ~g_io_in_2_ready;
    if (g_io_in_3_ready !== i_io_in_3_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_3_ready: g=%h i=%h", checks, g_io_in_3_ready, i_io_in_3_ready);
    end
    seen1_io_in_3_ready |= g_io_in_3_ready;
    seen0_io_in_3_ready |= ~g_io_in_3_ready;
    if (g_io_in_4_ready !== i_io_in_4_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_4_ready: g=%h i=%h", checks, g_io_in_4_ready, i_io_in_4_ready);
    end
    seen1_io_in_4_ready |= g_io_in_4_ready;
    seen0_io_in_4_ready |= ~g_io_in_4_ready;
    if (g_io_in_5_ready !== i_io_in_5_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_5_ready: g=%h i=%h", checks, g_io_in_5_ready, i_io_in_5_ready);
    end
    seen1_io_in_5_ready |= g_io_in_5_ready;
    seen0_io_in_5_ready |= ~g_io_in_5_ready;
    if (g_io_in_6_ready !== i_io_in_6_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_6_ready: g=%h i=%h", checks, g_io_in_6_ready, i_io_in_6_ready);
    end
    seen1_io_in_6_ready |= g_io_in_6_ready;
    seen0_io_in_6_ready |= ~g_io_in_6_ready;
    if (g_io_in_7_ready !== i_io_in_7_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_7_ready: g=%h i=%h", checks, g_io_in_7_ready, i_io_in_7_ready);
    end
    seen1_io_in_7_ready |= g_io_in_7_ready;
    seen0_io_in_7_ready |= ~g_io_in_7_ready;
    if (g_io_in_8_ready !== i_io_in_8_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_8_ready: g=%h i=%h", checks, g_io_in_8_ready, i_io_in_8_ready);
    end
    seen1_io_in_8_ready |= g_io_in_8_ready;
    seen0_io_in_8_ready |= ~g_io_in_8_ready;
    if (g_io_in_9_ready !== i_io_in_9_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_9_ready: g=%h i=%h", checks, g_io_in_9_ready, i_io_in_9_ready);
    end
    seen1_io_in_9_ready |= g_io_in_9_ready;
    seen0_io_in_9_ready |= ~g_io_in_9_ready;
    if (g_io_in_10_ready !== i_io_in_10_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_10_ready: g=%h i=%h", checks, g_io_in_10_ready, i_io_in_10_ready);
    end
    seen1_io_in_10_ready |= g_io_in_10_ready;
    seen0_io_in_10_ready |= ~g_io_in_10_ready;
    if (g_io_in_11_ready !== i_io_in_11_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_11_ready: g=%h i=%h", checks, g_io_in_11_ready, i_io_in_11_ready);
    end
    seen1_io_in_11_ready |= g_io_in_11_ready;
    seen0_io_in_11_ready |= ~g_io_in_11_ready;
    if (g_io_in_12_ready !== i_io_in_12_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_12_ready: g=%h i=%h", checks, g_io_in_12_ready, i_io_in_12_ready);
    end
    seen1_io_in_12_ready |= g_io_in_12_ready;
    seen0_io_in_12_ready |= ~g_io_in_12_ready;
    if (g_io_in_13_ready !== i_io_in_13_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_13_ready: g=%h i=%h", checks, g_io_in_13_ready, i_io_in_13_ready);
    end
    seen1_io_in_13_ready |= g_io_in_13_ready;
    seen0_io_in_13_ready |= ~g_io_in_13_ready;
    if (g_io_in_14_ready !== i_io_in_14_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_14_ready: g=%h i=%h", checks, g_io_in_14_ready, i_io_in_14_ready);
    end
    seen1_io_in_14_ready |= g_io_in_14_ready;
    seen0_io_in_14_ready |= ~g_io_in_14_ready;
    if (g_io_in_15_ready !== i_io_in_15_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_in_15_ready: g=%h i=%h", checks, g_io_in_15_ready, i_io_in_15_ready);
    end
    seen1_io_in_15_ready |= g_io_in_15_ready;
    seen0_io_in_15_ready |= ~g_io_in_15_ready;
    if (g_io_out_valid !== i_io_out_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_valid: g=%h i=%h", checks, g_io_out_valid, i_io_out_valid);
    end
    seen1_io_out_valid |= g_io_out_valid;
    seen0_io_out_valid |= ~g_io_out_valid;
    if (g_io_out_bits_miss_id !== i_io_out_bits_miss_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_miss_id: g=%h i=%h", checks, g_io_out_bits_miss_id, i_io_out_bits_miss_id);
    end
    seen1_io_out_bits_miss_id |= g_io_out_bits_miss_id;
    seen0_io_out_bits_miss_id |= ~g_io_out_bits_miss_id;
    if (g_io_out_bits_occupy_way !== i_io_out_bits_occupy_way) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_occupy_way: g=%h i=%h", checks, g_io_out_bits_occupy_way, i_io_out_bits_occupy_way);
    end
    seen1_io_out_bits_occupy_way |= g_io_out_bits_occupy_way;
    seen0_io_out_bits_occupy_way |= ~g_io_out_bits_occupy_way;
    if (g_io_out_bits_miss_fail_cause_evict_btot !== i_io_out_bits_miss_fail_cause_evict_btot) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_miss_fail_cause_evict_btot: g=%h i=%h", checks, g_io_out_bits_miss_fail_cause_evict_btot, i_io_out_bits_miss_fail_cause_evict_btot);
    end
    seen1_io_out_bits_miss_fail_cause_evict_btot |= g_io_out_bits_miss_fail_cause_evict_btot;
    seen0_io_out_bits_miss_fail_cause_evict_btot |= ~g_io_out_bits_miss_fail_cause_evict_btot;
    if (g_io_out_bits_source !== i_io_out_bits_source) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_source: g=%h i=%h", checks, g_io_out_bits_source, i_io_out_bits_source);
    end
    seen1_io_out_bits_source |= g_io_out_bits_source;
    seen0_io_out_bits_source |= ~g_io_out_bits_source;
    if (g_io_out_bits_cmd !== i_io_out_bits_cmd) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_cmd: g=%h i=%h", checks, g_io_out_bits_cmd, i_io_out_bits_cmd);
    end
    seen1_io_out_bits_cmd |= g_io_out_bits_cmd;
    seen0_io_out_bits_cmd |= ~g_io_out_bits_cmd;
    if (g_io_out_bits_vaddr !== i_io_out_bits_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_vaddr: g=%h i=%h", checks, g_io_out_bits_vaddr, i_io_out_bits_vaddr);
    end
    seen1_io_out_bits_vaddr |= g_io_out_bits_vaddr;
    seen0_io_out_bits_vaddr |= ~g_io_out_bits_vaddr;
    if (g_io_out_bits_addr !== i_io_out_bits_addr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_addr: g=%h i=%h", checks, g_io_out_bits_addr, i_io_out_bits_addr);
    end
    seen1_io_out_bits_addr |= g_io_out_bits_addr;
    seen0_io_out_bits_addr |= ~g_io_out_bits_addr;
    if (g_io_out_bits_word_idx !== i_io_out_bits_word_idx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_word_idx: g=%h i=%h", checks, g_io_out_bits_word_idx, i_io_out_bits_word_idx);
    end
    seen1_io_out_bits_word_idx |= g_io_out_bits_word_idx;
    seen0_io_out_bits_word_idx |= ~g_io_out_bits_word_idx;
    if (g_io_out_bits_amo_data !== i_io_out_bits_amo_data) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_amo_data: g=%h i=%h", checks, g_io_out_bits_amo_data, i_io_out_bits_amo_data);
    end
    seen1_io_out_bits_amo_data |= g_io_out_bits_amo_data;
    seen0_io_out_bits_amo_data |= ~g_io_out_bits_amo_data;
    if (g_io_out_bits_amo_mask !== i_io_out_bits_amo_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_amo_mask: g=%h i=%h", checks, g_io_out_bits_amo_mask, i_io_out_bits_amo_mask);
    end
    seen1_io_out_bits_amo_mask |= g_io_out_bits_amo_mask;
    seen0_io_out_bits_amo_mask |= ~g_io_out_bits_amo_mask;
    if (g_io_out_bits_amo_cmp !== i_io_out_bits_amo_cmp) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_amo_cmp: g=%h i=%h", checks, g_io_out_bits_amo_cmp, i_io_out_bits_amo_cmp);
    end
    seen1_io_out_bits_amo_cmp |= g_io_out_bits_amo_cmp;
    seen0_io_out_bits_amo_cmp |= ~g_io_out_bits_amo_cmp;
    if (g_io_out_bits_pf_source !== i_io_out_bits_pf_source) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_pf_source: g=%h i=%h", checks, g_io_out_bits_pf_source, i_io_out_bits_pf_source);
    end
    seen1_io_out_bits_pf_source |= g_io_out_bits_pf_source;
    seen0_io_out_bits_pf_source |= ~g_io_out_bits_pf_source;
    if (g_io_out_bits_access !== i_io_out_bits_access) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_access: g=%h i=%h", checks, g_io_out_bits_access, i_io_out_bits_access);
    end
    seen1_io_out_bits_access |= g_io_out_bits_access;
    seen0_io_out_bits_access |= ~g_io_out_bits_access;
    if (g_io_out_bits_id !== i_io_out_bits_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_out_bits_id: g=%h i=%h", checks, g_io_out_bits_id, i_io_out_bits_id);
    end
    seen1_io_out_bits_id |= g_io_out_bits_id;
    seen0_io_out_bits_id |= ~g_io_out_bits_id;
    checks++;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    seen1_io_in_0_ready = '0; seen0_io_in_0_ready = '0;
    seen1_io_in_1_ready = '0; seen0_io_in_1_ready = '0;
    seen1_io_in_2_ready = '0; seen0_io_in_2_ready = '0;
    seen1_io_in_3_ready = '0; seen0_io_in_3_ready = '0;
    seen1_io_in_4_ready = '0; seen0_io_in_4_ready = '0;
    seen1_io_in_5_ready = '0; seen0_io_in_5_ready = '0;
    seen1_io_in_6_ready = '0; seen0_io_in_6_ready = '0;
    seen1_io_in_7_ready = '0; seen0_io_in_7_ready = '0;
    seen1_io_in_8_ready = '0; seen0_io_in_8_ready = '0;
    seen1_io_in_9_ready = '0; seen0_io_in_9_ready = '0;
    seen1_io_in_10_ready = '0; seen0_io_in_10_ready = '0;
    seen1_io_in_11_ready = '0; seen0_io_in_11_ready = '0;
    seen1_io_in_12_ready = '0; seen0_io_in_12_ready = '0;
    seen1_io_in_13_ready = '0; seen0_io_in_13_ready = '0;
    seen1_io_in_14_ready = '0; seen0_io_in_14_ready = '0;
    seen1_io_in_15_ready = '0; seen0_io_in_15_ready = '0;
    seen1_io_out_valid = '0; seen0_io_out_valid = '0;
    seen1_io_out_bits_miss_id = '0; seen0_io_out_bits_miss_id = '0;
    seen1_io_out_bits_occupy_way = '0; seen0_io_out_bits_occupy_way = '0;
    seen1_io_out_bits_miss_fail_cause_evict_btot = '0; seen0_io_out_bits_miss_fail_cause_evict_btot = '0;
    seen1_io_out_bits_source = '0; seen0_io_out_bits_source = '0;
    seen1_io_out_bits_cmd = '0; seen0_io_out_bits_cmd = '0;
    seen1_io_out_bits_vaddr = '0; seen0_io_out_bits_vaddr = '0;
    seen1_io_out_bits_addr = '0; seen0_io_out_bits_addr = '0;
    seen1_io_out_bits_word_idx = '0; seen0_io_out_bits_word_idx = '0;
    seen1_io_out_bits_amo_data = '0; seen0_io_out_bits_amo_data = '0;
    seen1_io_out_bits_amo_mask = '0; seen0_io_out_bits_amo_mask = '0;
    seen1_io_out_bits_amo_cmp = '0; seen0_io_out_bits_amo_cmp = '0;
    seen1_io_out_bits_pf_source = '0; seen0_io_out_bits_pf_source = '0;
    seen1_io_out_bits_access = '0; seen0_io_out_bits_access = '0;
    seen1_io_out_bits_id = '0; seen0_io_out_bits_id = '0;
    for (int c = 0; c < NCYCLES; c++) begin
      drive();
      #1;
      compare();
      if (io_in_0_valid) win[0]++;
      else if (io_in_1_valid) win[1]++;
      else if (io_in_2_valid) win[2]++;
      else if (io_in_3_valid) win[3]++;
      else if (io_in_4_valid) win[4]++;
      else if (io_in_5_valid) win[5]++;
      else if (io_in_6_valid) win[6]++;
      else if (io_in_7_valid) win[7]++;
      else if (io_in_8_valid) win[8]++;
      else if (io_in_9_valid) win[9]++;
      else if (io_in_10_valid) win[10]++;
      else if (io_in_11_valid) win[11]++;
      else if (io_in_12_valid) win[12]++;
      else if (io_in_13_valid) win[13]++;
      else if (io_in_14_valid) win[14]++;
      else if (io_in_15_valid) win[15]++;
      else none_cnt++;
      if (!io_out_ready) stall_cnt++;
      #9;
    end
    for (int k = 0; k < 16; k++) $display("COVERAGE win[%0d]=%0d", k, win[k]);
    $display("COVERAGE none=%0d out_ready0=%0d", none_cnt, stall_cnt);
    for (int k = 0; k < 16; k++) if (win[k] < COV_MIN) begin cov_fail++; $display("COV FAIL: way %0d wins %0d", k, win[k]); end
    if (none_cnt < COV_MIN) begin cov_fail++; $display("COV FAIL: none"); end
    if (stall_cnt < COV_MIN) begin cov_fail++; $display("COV FAIL: out_ready=0"); end
    if (~seen1_io_in_0_ready != '0 || ~seen0_io_in_0_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_0_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_0_ready, seen0_io_in_0_ready); end
    if (~seen1_io_in_1_ready != '0 || ~seen0_io_in_1_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_1_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_1_ready, seen0_io_in_1_ready); end
    if (~seen1_io_in_2_ready != '0 || ~seen0_io_in_2_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_2_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_2_ready, seen0_io_in_2_ready); end
    if (~seen1_io_in_3_ready != '0 || ~seen0_io_in_3_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_3_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_3_ready, seen0_io_in_3_ready); end
    if (~seen1_io_in_4_ready != '0 || ~seen0_io_in_4_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_4_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_4_ready, seen0_io_in_4_ready); end
    if (~seen1_io_in_5_ready != '0 || ~seen0_io_in_5_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_5_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_5_ready, seen0_io_in_5_ready); end
    if (~seen1_io_in_6_ready != '0 || ~seen0_io_in_6_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_6_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_6_ready, seen0_io_in_6_ready); end
    if (~seen1_io_in_7_ready != '0 || ~seen0_io_in_7_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_7_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_7_ready, seen0_io_in_7_ready); end
    if (~seen1_io_in_8_ready != '0 || ~seen0_io_in_8_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_8_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_8_ready, seen0_io_in_8_ready); end
    if (~seen1_io_in_9_ready != '0 || ~seen0_io_in_9_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_9_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_9_ready, seen0_io_in_9_ready); end
    if (~seen1_io_in_10_ready != '0 || ~seen0_io_in_10_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_10_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_10_ready, seen0_io_in_10_ready); end
    if (~seen1_io_in_11_ready != '0 || ~seen0_io_in_11_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_11_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_11_ready, seen0_io_in_11_ready); end
    if (~seen1_io_in_12_ready != '0 || ~seen0_io_in_12_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_12_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_12_ready, seen0_io_in_12_ready); end
    if (~seen1_io_in_13_ready != '0 || ~seen0_io_in_13_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_13_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_13_ready, seen0_io_in_13_ready); end
    if (~seen1_io_in_14_ready != '0 || ~seen0_io_in_14_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_14_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_14_ready, seen0_io_in_14_ready); end
    if (~seen1_io_in_15_ready != '0 || ~seen0_io_in_15_ready != '0) begin cov_fail++; $display("COV FAIL: io_in_15_ready 有位没翻转过 1=%h 0=%h", seen1_io_in_15_ready, seen0_io_in_15_ready); end
    if (~seen1_io_out_valid != '0 || ~seen0_io_out_valid != '0) begin cov_fail++; $display("COV FAIL: io_out_valid 有位没翻转过 1=%h 0=%h", seen1_io_out_valid, seen0_io_out_valid); end
    if (~seen1_io_out_bits_miss_id != '0 || ~seen0_io_out_bits_miss_id != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_miss_id 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_miss_id, seen0_io_out_bits_miss_id); end
    if (~seen1_io_out_bits_occupy_way != '0 || ~seen0_io_out_bits_occupy_way != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_occupy_way 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_occupy_way, seen0_io_out_bits_occupy_way); end
    if (~seen1_io_out_bits_miss_fail_cause_evict_btot != '0 || ~seen0_io_out_bits_miss_fail_cause_evict_btot != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_miss_fail_cause_evict_btot 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_miss_fail_cause_evict_btot, seen0_io_out_bits_miss_fail_cause_evict_btot); end
    if (~seen1_io_out_bits_source != '0 || ~seen0_io_out_bits_source != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_source 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_source, seen0_io_out_bits_source); end
    if (~seen1_io_out_bits_cmd != '0 || ~seen0_io_out_bits_cmd != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_cmd 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_cmd, seen0_io_out_bits_cmd); end
    if (~seen1_io_out_bits_vaddr != '0 || ~seen0_io_out_bits_vaddr != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_vaddr 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_vaddr, seen0_io_out_bits_vaddr); end
    if (~seen1_io_out_bits_addr != '0 || ~seen0_io_out_bits_addr != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_addr 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_addr, seen0_io_out_bits_addr); end
    if (~seen1_io_out_bits_word_idx != '0 || ~seen0_io_out_bits_word_idx != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_word_idx 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_word_idx, seen0_io_out_bits_word_idx); end
    if (~seen1_io_out_bits_amo_data != '0 || ~seen0_io_out_bits_amo_data != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_amo_data 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_amo_data, seen0_io_out_bits_amo_data); end
    if (~seen1_io_out_bits_amo_mask != '0 || ~seen0_io_out_bits_amo_mask != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_amo_mask 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_amo_mask, seen0_io_out_bits_amo_mask); end
    if (~seen1_io_out_bits_amo_cmp != '0 || ~seen0_io_out_bits_amo_cmp != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_amo_cmp 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_amo_cmp, seen0_io_out_bits_amo_cmp); end
    if (~seen1_io_out_bits_pf_source != '0 || ~seen0_io_out_bits_pf_source != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_pf_source 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_pf_source, seen0_io_out_bits_pf_source); end
    if (~seen1_io_out_bits_access != '0 || ~seen0_io_out_bits_access != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_access 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_access, seen0_io_out_bits_access); end
    if (~seen1_io_out_bits_id != '0 || ~seen0_io_out_bits_id != '0) begin cov_fail++; $display("COV FAIL: io_out_bits_id 有位没翻转过 1=%h 0=%h", seen1_io_out_bits_id, seen0_io_out_bits_id); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
