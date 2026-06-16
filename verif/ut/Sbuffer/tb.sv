// 自动生成：scripts/gen_sbuffer.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in_0_valid;
  logic [49:0] io_in_0_bits_vaddr;
  logic [127:0] io_in_0_bits_data;
  logic [15:0] io_in_0_bits_mask;
  logic [47:0] io_in_0_bits_addr;
  logic io_in_0_bits_wline;
  logic io_in_0_bits_vecValid;
  logic io_in_1_valid;
  logic [49:0] io_in_1_bits_vaddr;
  logic [127:0] io_in_1_bits_data;
  logic [15:0] io_in_1_bits_mask;
  logic [47:0] io_in_1_bits_addr;
  logic io_in_1_bits_wline;
  logic io_in_1_bits_vecValid;
  logic io_dcache_req_ready;
  logic io_dcache_main_pipe_hit_resp_valid;
  logic [5:0] io_dcache_main_pipe_hit_resp_bits_id;
  logic io_dcache_replay_resp_valid;
  logic [5:0] io_dcache_replay_resp_bits_id;
  logic [49:0] io_forward_0_vaddr;
  logic [47:0] io_forward_0_paddr;
  logic io_forward_0_valid;
  logic [49:0] io_forward_1_vaddr;
  logic [47:0] io_forward_1_paddr;
  logic io_forward_1_valid;
  logic [49:0] io_forward_2_vaddr;
  logic [47:0] io_forward_2_paddr;
  logic io_forward_2_valid;
  logic io_sqempty;
  logic io_flush_valid;
  logic io_force_write;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_dcache_req_valid;
  wire i_io_dcache_req_valid;
  wire [49:0] g_io_dcache_req_bits_vaddr;
  wire [49:0] i_io_dcache_req_bits_vaddr;
  wire [47:0] g_io_dcache_req_bits_addr;
  wire [47:0] i_io_dcache_req_bits_addr;
  wire [511:0] g_io_dcache_req_bits_data;
  wire [511:0] i_io_dcache_req_bits_data;
  wire [63:0] g_io_dcache_req_bits_mask;
  wire [63:0] i_io_dcache_req_bits_mask;
  wire [5:0] g_io_dcache_req_bits_id;
  wire [5:0] i_io_dcache_req_bits_id;
  wire g_io_forward_0_forwardMask_0;
  wire i_io_forward_0_forwardMask_0;
  wire g_io_forward_0_forwardMask_1;
  wire i_io_forward_0_forwardMask_1;
  wire g_io_forward_0_forwardMask_2;
  wire i_io_forward_0_forwardMask_2;
  wire g_io_forward_0_forwardMask_3;
  wire i_io_forward_0_forwardMask_3;
  wire g_io_forward_0_forwardMask_4;
  wire i_io_forward_0_forwardMask_4;
  wire g_io_forward_0_forwardMask_5;
  wire i_io_forward_0_forwardMask_5;
  wire g_io_forward_0_forwardMask_6;
  wire i_io_forward_0_forwardMask_6;
  wire g_io_forward_0_forwardMask_7;
  wire i_io_forward_0_forwardMask_7;
  wire g_io_forward_0_forwardMask_8;
  wire i_io_forward_0_forwardMask_8;
  wire g_io_forward_0_forwardMask_9;
  wire i_io_forward_0_forwardMask_9;
  wire g_io_forward_0_forwardMask_10;
  wire i_io_forward_0_forwardMask_10;
  wire g_io_forward_0_forwardMask_11;
  wire i_io_forward_0_forwardMask_11;
  wire g_io_forward_0_forwardMask_12;
  wire i_io_forward_0_forwardMask_12;
  wire g_io_forward_0_forwardMask_13;
  wire i_io_forward_0_forwardMask_13;
  wire g_io_forward_0_forwardMask_14;
  wire i_io_forward_0_forwardMask_14;
  wire g_io_forward_0_forwardMask_15;
  wire i_io_forward_0_forwardMask_15;
  wire [7:0] g_io_forward_0_forwardData_0;
  wire [7:0] i_io_forward_0_forwardData_0;
  wire [7:0] g_io_forward_0_forwardData_1;
  wire [7:0] i_io_forward_0_forwardData_1;
  wire [7:0] g_io_forward_0_forwardData_2;
  wire [7:0] i_io_forward_0_forwardData_2;
  wire [7:0] g_io_forward_0_forwardData_3;
  wire [7:0] i_io_forward_0_forwardData_3;
  wire [7:0] g_io_forward_0_forwardData_4;
  wire [7:0] i_io_forward_0_forwardData_4;
  wire [7:0] g_io_forward_0_forwardData_5;
  wire [7:0] i_io_forward_0_forwardData_5;
  wire [7:0] g_io_forward_0_forwardData_6;
  wire [7:0] i_io_forward_0_forwardData_6;
  wire [7:0] g_io_forward_0_forwardData_7;
  wire [7:0] i_io_forward_0_forwardData_7;
  wire [7:0] g_io_forward_0_forwardData_8;
  wire [7:0] i_io_forward_0_forwardData_8;
  wire [7:0] g_io_forward_0_forwardData_9;
  wire [7:0] i_io_forward_0_forwardData_9;
  wire [7:0] g_io_forward_0_forwardData_10;
  wire [7:0] i_io_forward_0_forwardData_10;
  wire [7:0] g_io_forward_0_forwardData_11;
  wire [7:0] i_io_forward_0_forwardData_11;
  wire [7:0] g_io_forward_0_forwardData_12;
  wire [7:0] i_io_forward_0_forwardData_12;
  wire [7:0] g_io_forward_0_forwardData_13;
  wire [7:0] i_io_forward_0_forwardData_13;
  wire [7:0] g_io_forward_0_forwardData_14;
  wire [7:0] i_io_forward_0_forwardData_14;
  wire [7:0] g_io_forward_0_forwardData_15;
  wire [7:0] i_io_forward_0_forwardData_15;
  wire g_io_forward_0_matchInvalid;
  wire i_io_forward_0_matchInvalid;
  wire g_io_forward_1_forwardMask_0;
  wire i_io_forward_1_forwardMask_0;
  wire g_io_forward_1_forwardMask_1;
  wire i_io_forward_1_forwardMask_1;
  wire g_io_forward_1_forwardMask_2;
  wire i_io_forward_1_forwardMask_2;
  wire g_io_forward_1_forwardMask_3;
  wire i_io_forward_1_forwardMask_3;
  wire g_io_forward_1_forwardMask_4;
  wire i_io_forward_1_forwardMask_4;
  wire g_io_forward_1_forwardMask_5;
  wire i_io_forward_1_forwardMask_5;
  wire g_io_forward_1_forwardMask_6;
  wire i_io_forward_1_forwardMask_6;
  wire g_io_forward_1_forwardMask_7;
  wire i_io_forward_1_forwardMask_7;
  wire g_io_forward_1_forwardMask_8;
  wire i_io_forward_1_forwardMask_8;
  wire g_io_forward_1_forwardMask_9;
  wire i_io_forward_1_forwardMask_9;
  wire g_io_forward_1_forwardMask_10;
  wire i_io_forward_1_forwardMask_10;
  wire g_io_forward_1_forwardMask_11;
  wire i_io_forward_1_forwardMask_11;
  wire g_io_forward_1_forwardMask_12;
  wire i_io_forward_1_forwardMask_12;
  wire g_io_forward_1_forwardMask_13;
  wire i_io_forward_1_forwardMask_13;
  wire g_io_forward_1_forwardMask_14;
  wire i_io_forward_1_forwardMask_14;
  wire g_io_forward_1_forwardMask_15;
  wire i_io_forward_1_forwardMask_15;
  wire [7:0] g_io_forward_1_forwardData_0;
  wire [7:0] i_io_forward_1_forwardData_0;
  wire [7:0] g_io_forward_1_forwardData_1;
  wire [7:0] i_io_forward_1_forwardData_1;
  wire [7:0] g_io_forward_1_forwardData_2;
  wire [7:0] i_io_forward_1_forwardData_2;
  wire [7:0] g_io_forward_1_forwardData_3;
  wire [7:0] i_io_forward_1_forwardData_3;
  wire [7:0] g_io_forward_1_forwardData_4;
  wire [7:0] i_io_forward_1_forwardData_4;
  wire [7:0] g_io_forward_1_forwardData_5;
  wire [7:0] i_io_forward_1_forwardData_5;
  wire [7:0] g_io_forward_1_forwardData_6;
  wire [7:0] i_io_forward_1_forwardData_6;
  wire [7:0] g_io_forward_1_forwardData_7;
  wire [7:0] i_io_forward_1_forwardData_7;
  wire [7:0] g_io_forward_1_forwardData_8;
  wire [7:0] i_io_forward_1_forwardData_8;
  wire [7:0] g_io_forward_1_forwardData_9;
  wire [7:0] i_io_forward_1_forwardData_9;
  wire [7:0] g_io_forward_1_forwardData_10;
  wire [7:0] i_io_forward_1_forwardData_10;
  wire [7:0] g_io_forward_1_forwardData_11;
  wire [7:0] i_io_forward_1_forwardData_11;
  wire [7:0] g_io_forward_1_forwardData_12;
  wire [7:0] i_io_forward_1_forwardData_12;
  wire [7:0] g_io_forward_1_forwardData_13;
  wire [7:0] i_io_forward_1_forwardData_13;
  wire [7:0] g_io_forward_1_forwardData_14;
  wire [7:0] i_io_forward_1_forwardData_14;
  wire [7:0] g_io_forward_1_forwardData_15;
  wire [7:0] i_io_forward_1_forwardData_15;
  wire g_io_forward_1_matchInvalid;
  wire i_io_forward_1_matchInvalid;
  wire g_io_forward_2_forwardMask_0;
  wire i_io_forward_2_forwardMask_0;
  wire g_io_forward_2_forwardMask_1;
  wire i_io_forward_2_forwardMask_1;
  wire g_io_forward_2_forwardMask_2;
  wire i_io_forward_2_forwardMask_2;
  wire g_io_forward_2_forwardMask_3;
  wire i_io_forward_2_forwardMask_3;
  wire g_io_forward_2_forwardMask_4;
  wire i_io_forward_2_forwardMask_4;
  wire g_io_forward_2_forwardMask_5;
  wire i_io_forward_2_forwardMask_5;
  wire g_io_forward_2_forwardMask_6;
  wire i_io_forward_2_forwardMask_6;
  wire g_io_forward_2_forwardMask_7;
  wire i_io_forward_2_forwardMask_7;
  wire g_io_forward_2_forwardMask_8;
  wire i_io_forward_2_forwardMask_8;
  wire g_io_forward_2_forwardMask_9;
  wire i_io_forward_2_forwardMask_9;
  wire g_io_forward_2_forwardMask_10;
  wire i_io_forward_2_forwardMask_10;
  wire g_io_forward_2_forwardMask_11;
  wire i_io_forward_2_forwardMask_11;
  wire g_io_forward_2_forwardMask_12;
  wire i_io_forward_2_forwardMask_12;
  wire g_io_forward_2_forwardMask_13;
  wire i_io_forward_2_forwardMask_13;
  wire g_io_forward_2_forwardMask_14;
  wire i_io_forward_2_forwardMask_14;
  wire g_io_forward_2_forwardMask_15;
  wire i_io_forward_2_forwardMask_15;
  wire [7:0] g_io_forward_2_forwardData_0;
  wire [7:0] i_io_forward_2_forwardData_0;
  wire [7:0] g_io_forward_2_forwardData_1;
  wire [7:0] i_io_forward_2_forwardData_1;
  wire [7:0] g_io_forward_2_forwardData_2;
  wire [7:0] i_io_forward_2_forwardData_2;
  wire [7:0] g_io_forward_2_forwardData_3;
  wire [7:0] i_io_forward_2_forwardData_3;
  wire [7:0] g_io_forward_2_forwardData_4;
  wire [7:0] i_io_forward_2_forwardData_4;
  wire [7:0] g_io_forward_2_forwardData_5;
  wire [7:0] i_io_forward_2_forwardData_5;
  wire [7:0] g_io_forward_2_forwardData_6;
  wire [7:0] i_io_forward_2_forwardData_6;
  wire [7:0] g_io_forward_2_forwardData_7;
  wire [7:0] i_io_forward_2_forwardData_7;
  wire [7:0] g_io_forward_2_forwardData_8;
  wire [7:0] i_io_forward_2_forwardData_8;
  wire [7:0] g_io_forward_2_forwardData_9;
  wire [7:0] i_io_forward_2_forwardData_9;
  wire [7:0] g_io_forward_2_forwardData_10;
  wire [7:0] i_io_forward_2_forwardData_10;
  wire [7:0] g_io_forward_2_forwardData_11;
  wire [7:0] i_io_forward_2_forwardData_11;
  wire [7:0] g_io_forward_2_forwardData_12;
  wire [7:0] i_io_forward_2_forwardData_12;
  wire [7:0] g_io_forward_2_forwardData_13;
  wire [7:0] i_io_forward_2_forwardData_13;
  wire [7:0] g_io_forward_2_forwardData_14;
  wire [7:0] i_io_forward_2_forwardData_14;
  wire [7:0] g_io_forward_2_forwardData_15;
  wire [7:0] i_io_forward_2_forwardData_15;
  wire g_io_forward_2_matchInvalid;
  wire i_io_forward_2_matchInvalid;
  wire g_io_sbempty;
  wire i_io_sbempty;
  wire g_io_flush_empty;
  wire i_io_flush_empty;
  wire [49:0] g_io_store_prefetch_0_bits_vaddr;
  wire [49:0] i_io_store_prefetch_0_bits_vaddr;
  wire [49:0] g_io_store_prefetch_1_bits_vaddr;
  wire [49:0] i_io_store_prefetch_1_bits_vaddr;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;
  wire [5:0] g_io_perf_8_value;
  wire [5:0] i_io_perf_8_value;
  wire [5:0] g_io_perf_9_value;
  wire [5:0] i_io_perf_9_value;
  wire [5:0] g_io_perf_10_value;
  wire [5:0] i_io_perf_10_value;
  wire [5:0] g_io_perf_11_value;
  wire [5:0] i_io_perf_11_value;
  wire [5:0] g_io_perf_12_value;
  wire [5:0] i_io_perf_12_value;
  wire [5:0] g_io_perf_13_value;
  wire [5:0] i_io_perf_13_value;
  wire [5:0] g_io_perf_14_value;
  wire [5:0] i_io_perf_14_value;
  wire [5:0] g_io_perf_15_value;
  wire [5:0] i_io_perf_15_value;
  Sbuffer    u_g (.clock(clk), .reset(rst), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_vaddr(io_in_0_bits_vaddr), .io_in_0_bits_data(io_in_0_bits_data), .io_in_0_bits_mask(io_in_0_bits_mask), .io_in_0_bits_addr(io_in_0_bits_addr), .io_in_0_bits_wline(io_in_0_bits_wline), .io_in_0_bits_vecValid(io_in_0_bits_vecValid), .io_in_1_valid(io_in_1_valid), .io_in_1_bits_vaddr(io_in_1_bits_vaddr), .io_in_1_bits_data(io_in_1_bits_data), .io_in_1_bits_mask(io_in_1_bits_mask), .io_in_1_bits_addr(io_in_1_bits_addr), .io_in_1_bits_wline(io_in_1_bits_wline), .io_in_1_bits_vecValid(io_in_1_bits_vecValid), .io_dcache_req_ready(io_dcache_req_ready), .io_dcache_main_pipe_hit_resp_valid(io_dcache_main_pipe_hit_resp_valid), .io_dcache_main_pipe_hit_resp_bits_id(io_dcache_main_pipe_hit_resp_bits_id), .io_dcache_replay_resp_valid(io_dcache_replay_resp_valid), .io_dcache_replay_resp_bits_id(io_dcache_replay_resp_bits_id), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_sqempty(io_sqempty), .io_flush_valid(io_flush_valid), .io_force_write(io_force_write), .io_in_0_ready(g_io_in_0_ready), .io_in_1_ready(g_io_in_1_ready), .io_dcache_req_valid(g_io_dcache_req_valid), .io_dcache_req_bits_vaddr(g_io_dcache_req_bits_vaddr), .io_dcache_req_bits_addr(g_io_dcache_req_bits_addr), .io_dcache_req_bits_data(g_io_dcache_req_bits_data), .io_dcache_req_bits_mask(g_io_dcache_req_bits_mask), .io_dcache_req_bits_id(g_io_dcache_req_bits_id), .io_forward_0_forwardMask_0(g_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(g_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(g_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(g_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(g_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(g_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(g_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(g_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(g_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(g_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(g_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(g_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(g_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(g_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(g_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(g_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(g_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(g_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(g_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(g_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(g_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(g_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(g_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(g_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(g_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(g_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(g_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(g_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(g_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(g_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(g_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(g_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(g_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(g_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(g_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(g_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(g_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(g_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(g_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(g_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(g_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(g_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(g_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(g_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(g_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(g_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(g_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(g_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(g_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(g_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(g_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(g_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(g_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(g_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(g_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(g_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(g_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(g_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(g_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(g_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(g_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(g_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(g_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(g_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(g_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(g_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(g_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(g_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(g_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(g_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(g_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(g_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(g_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(g_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(g_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(g_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(g_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(g_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(g_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(g_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(g_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(g_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(g_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(g_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(g_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(g_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(g_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(g_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(g_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(g_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(g_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(g_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(g_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(g_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(g_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(g_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(g_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(g_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(g_io_forward_2_matchInvalid), .io_sbempty(g_io_sbempty), .io_flush_empty(g_io_flush_empty), .io_store_prefetch_0_bits_vaddr(g_io_store_prefetch_0_bits_vaddr), .io_store_prefetch_1_bits_vaddr(g_io_store_prefetch_1_bits_vaddr), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .io_perf_8_value(g_io_perf_8_value), .io_perf_9_value(g_io_perf_9_value), .io_perf_10_value(g_io_perf_10_value), .io_perf_11_value(g_io_perf_11_value), .io_perf_12_value(g_io_perf_12_value), .io_perf_13_value(g_io_perf_13_value), .io_perf_14_value(g_io_perf_14_value), .io_perf_15_value(g_io_perf_15_value));
  Sbuffer_xs u_i (.clock(clk), .reset(rst), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_vaddr(io_in_0_bits_vaddr), .io_in_0_bits_data(io_in_0_bits_data), .io_in_0_bits_mask(io_in_0_bits_mask), .io_in_0_bits_addr(io_in_0_bits_addr), .io_in_0_bits_wline(io_in_0_bits_wline), .io_in_0_bits_vecValid(io_in_0_bits_vecValid), .io_in_1_valid(io_in_1_valid), .io_in_1_bits_vaddr(io_in_1_bits_vaddr), .io_in_1_bits_data(io_in_1_bits_data), .io_in_1_bits_mask(io_in_1_bits_mask), .io_in_1_bits_addr(io_in_1_bits_addr), .io_in_1_bits_wline(io_in_1_bits_wline), .io_in_1_bits_vecValid(io_in_1_bits_vecValid), .io_dcache_req_ready(io_dcache_req_ready), .io_dcache_main_pipe_hit_resp_valid(io_dcache_main_pipe_hit_resp_valid), .io_dcache_main_pipe_hit_resp_bits_id(io_dcache_main_pipe_hit_resp_bits_id), .io_dcache_replay_resp_valid(io_dcache_replay_resp_valid), .io_dcache_replay_resp_bits_id(io_dcache_replay_resp_bits_id), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_sqempty(io_sqempty), .io_flush_valid(io_flush_valid), .io_force_write(io_force_write), .io_in_0_ready(i_io_in_0_ready), .io_in_1_ready(i_io_in_1_ready), .io_dcache_req_valid(i_io_dcache_req_valid), .io_dcache_req_bits_vaddr(i_io_dcache_req_bits_vaddr), .io_dcache_req_bits_addr(i_io_dcache_req_bits_addr), .io_dcache_req_bits_data(i_io_dcache_req_bits_data), .io_dcache_req_bits_mask(i_io_dcache_req_bits_mask), .io_dcache_req_bits_id(i_io_dcache_req_bits_id), .io_forward_0_forwardMask_0(i_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(i_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(i_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(i_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(i_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(i_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(i_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(i_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(i_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(i_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(i_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(i_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(i_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(i_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(i_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(i_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(i_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(i_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(i_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(i_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(i_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(i_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(i_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(i_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(i_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(i_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(i_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(i_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(i_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(i_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(i_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(i_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(i_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(i_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(i_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(i_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(i_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(i_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(i_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(i_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(i_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(i_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(i_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(i_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(i_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(i_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(i_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(i_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(i_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(i_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(i_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(i_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(i_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(i_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(i_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(i_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(i_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(i_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(i_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(i_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(i_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(i_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(i_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(i_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(i_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(i_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(i_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(i_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(i_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(i_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(i_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(i_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(i_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(i_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(i_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(i_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(i_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(i_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(i_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(i_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(i_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(i_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(i_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(i_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(i_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(i_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(i_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(i_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(i_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(i_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(i_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(i_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(i_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(i_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(i_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(i_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(i_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(i_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(i_io_forward_2_matchInvalid), .io_sbempty(i_io_sbempty), .io_flush_empty(i_io_flush_empty), .io_store_prefetch_0_bits_vaddr(i_io_store_prefetch_0_bits_vaddr), .io_store_prefetch_1_bits_vaddr(i_io_store_prefetch_1_bits_vaddr), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .io_perf_8_value(i_io_perf_8_value), .io_perf_9_value(i_io_perf_9_value), .io_perf_10_value(i_io_perf_10_value), .io_perf_11_value(i_io_perf_11_value), .io_perf_12_value(i_io_perf_12_value), .io_perf_13_value(i_io_perf_13_value), .io_perf_14_value(i_io_perf_14_value), .io_perf_15_value(i_io_perf_15_value));
  always @(negedge clk) begin
    if (rst) begin
      io_in_0_valid <= 1'b0;
      io_in_1_valid <= 1'b0;
      io_flush_valid <= 1'b0;
      io_forward_0_valid <= 1'b0;
      io_forward_1_valid <= 1'b0;
      io_forward_2_valid <= 1'b0;
      io_dcache_main_pipe_hit_resp_valid <= 1'b0;
      io_dcache_replay_resp_valid <= 1'b0;
    end else begin
      io_in_0_valid <= ($urandom_range(0,1));
      io_in_0_bits_vaddr <= {41'($urandom_range(0,7)), 9'($urandom)};
      io_in_0_bits_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_in_0_bits_mask <= $urandom_range(0,3)==0 ? 16'hffff : $urandom_range(0,2)==0 ? (16'h00ff << (8*$urandom_range(0,1))) : (16'h1 << $urandom_range(0,15));
      io_in_0_bits_addr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_in_0_bits_wline <= ($urandom_range(0,15)==0);
      io_in_0_bits_vecValid <= ($urandom_range(0,7)!=0);
      io_in_1_valid <= ($urandom_range(0,1));
      io_in_1_bits_vaddr <= {41'($urandom_range(0,7)), 9'($urandom)};
      io_in_1_bits_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_in_1_bits_mask <= $urandom_range(0,3)==0 ? 16'hffff : $urandom_range(0,2)==0 ? (16'h00ff << (8*$urandom_range(0,1))) : (16'h1 << $urandom_range(0,15));
      io_in_1_bits_addr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_in_1_bits_wline <= ($urandom_range(0,15)==0);
      io_in_1_bits_vecValid <= ($urandom_range(0,7)!=0);
      io_forward_0_vaddr <= {41'($urandom_range(0,7)), 9'($urandom)};
      io_forward_0_paddr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_forward_0_valid <= ($urandom_range(0,1));
      io_forward_1_vaddr <= {41'($urandom_range(0,7)), 9'($urandom)};
      io_forward_1_paddr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_forward_1_valid <= ($urandom_range(0,1));
      io_forward_2_vaddr <= {41'($urandom_range(0,7)), 9'($urandom)};
      io_forward_2_paddr <= {39'($urandom_range(0,7)), 9'($urandom)};
      io_forward_2_valid <= ($urandom_range(0,1));
      io_sqempty <= ($urandom_range(0,3)!=0);
      io_flush_valid <= ($urandom_range(0,63)==0);
      io_force_write <= ($urandom_range(0,7)==0);
    end
  end

  // 在途记录：每个 entry id(0..15) 是否有未回的 DCache 写
  bit [15:0] dc_inflight;
  int unsigned dc_start = 0;
  always @(negedge clk) begin
    if (rst) begin
      io_dcache_req_ready                  <= 1'b1;
      io_dcache_main_pipe_hit_resp_valid   <= 1'b0;
      io_dcache_main_pipe_hit_resp_bits_id <= 6'h0;
      io_dcache_replay_resp_valid          <= 1'b0;
      io_dcache_replay_resp_bits_id        <= 6'h0;
      dc_inflight                          <= 16'h0;
    end else begin
      io_dcache_req_ready <= ($urandom_range(0,3)!=0);
      // golden req fire → 标记该 id inflight
      if (g_io_dcache_req_valid && io_dcache_req_ready)
        dc_inflight[g_io_dcache_req_bits_id[3:0]] <= 1'b1;
      // 默认不回 resp
      io_dcache_main_pipe_hit_resp_valid <= 1'b0;
      io_dcache_replay_resp_valid        <= 1'b0;
      if (|dc_inflight && ($urandom_range(0,1))) begin
        int unsigned k; bit hit; bit do_replay;
        hit = 1'b0; do_replay = ($urandom_range(0,3)==0);
        for (k = 0; k < 16; k++) begin
          if (!hit && dc_inflight[(dc_start+k)%16]) begin
            hit = 1'b1;
            if (do_replay) begin
              io_dcache_replay_resp_valid   <= 1'b1;
              io_dcache_replay_resp_bits_id <= 6'(((dc_start+k)%16));
              // replay 不释放在途（entry 仍 inflight，挂 w_timeout 后会重发）；
              // 为避免反复同 entry replay 卡死，这里也清在途，后续重发再标记。
              dc_inflight[(dc_start+k)%16] <= 1'b0;
            end else begin
              io_dcache_main_pipe_hit_resp_valid   <= 1'b1;
              io_dcache_main_pipe_hit_resp_bits_id <= 6'(((dc_start+k)%16));
              dc_inflight[(dc_start+k)%16] <= 1'b0;
            end
          end
        end
        dc_start <= dc_start + 1;
      end
    end
  end

  logic [2:0] fwd_v_q;
  always @(posedge clk) if (!rst) begin
    fwd_v_q[0] <= io_forward_0_valid;
    fwd_v_q[1] <= io_forward_1_valid;
    fwd_v_q[2] <= io_forward_2_valid;
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_in_0_ready) && g_io_in_0_ready !== i_io_in_0_ready) begin errors++;
      if(errors<=100000) $display("[%0t] io_in_0_ready g=%h i=%h", $time, g_io_in_0_ready, i_io_in_0_ready); end
    if (!$isunknown(g_io_in_1_ready) && g_io_in_1_ready !== i_io_in_1_ready) begin errors++;
      if(errors<=100000) $display("[%0t] io_in_1_ready g=%h i=%h", $time, g_io_in_1_ready, i_io_in_1_ready); end
    if (!$isunknown(g_io_dcache_req_valid) && g_io_dcache_req_valid !== i_io_dcache_req_valid) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_valid g=%h i=%h", $time, g_io_dcache_req_valid, i_io_dcache_req_valid); end
    if ((g_io_dcache_req_valid) && !$isunknown(g_io_dcache_req_bits_vaddr) && g_io_dcache_req_bits_vaddr !== i_io_dcache_req_bits_vaddr) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_bits_vaddr g=%h i=%h", $time, g_io_dcache_req_bits_vaddr, i_io_dcache_req_bits_vaddr); end
    if ((g_io_dcache_req_valid) && !$isunknown(g_io_dcache_req_bits_addr) && g_io_dcache_req_bits_addr !== i_io_dcache_req_bits_addr) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_bits_addr g=%h i=%h", $time, g_io_dcache_req_bits_addr, i_io_dcache_req_bits_addr); end
    if ((g_io_dcache_req_valid) && !$isunknown(g_io_dcache_req_bits_data) && g_io_dcache_req_bits_data !== i_io_dcache_req_bits_data) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_bits_data g=%h i=%h", $time, g_io_dcache_req_bits_data, i_io_dcache_req_bits_data); end
    if ((g_io_dcache_req_valid) && !$isunknown(g_io_dcache_req_bits_mask) && g_io_dcache_req_bits_mask !== i_io_dcache_req_bits_mask) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_bits_mask g=%h i=%h", $time, g_io_dcache_req_bits_mask, i_io_dcache_req_bits_mask); end
    if ((g_io_dcache_req_valid) && !$isunknown(g_io_dcache_req_bits_id) && g_io_dcache_req_bits_id !== i_io_dcache_req_bits_id) begin errors++;
      if(errors<=100000) $display("[%0t] io_dcache_req_bits_id g=%h i=%h", $time, g_io_dcache_req_bits_id, i_io_dcache_req_bits_id); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_0) && g_io_forward_0_forwardMask_0 !== i_io_forward_0_forwardMask_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_0 g=%h i=%h", $time, g_io_forward_0_forwardMask_0, i_io_forward_0_forwardMask_0); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_1) && g_io_forward_0_forwardMask_1 !== i_io_forward_0_forwardMask_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_1 g=%h i=%h", $time, g_io_forward_0_forwardMask_1, i_io_forward_0_forwardMask_1); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_2) && g_io_forward_0_forwardMask_2 !== i_io_forward_0_forwardMask_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_2 g=%h i=%h", $time, g_io_forward_0_forwardMask_2, i_io_forward_0_forwardMask_2); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_3) && g_io_forward_0_forwardMask_3 !== i_io_forward_0_forwardMask_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_3 g=%h i=%h", $time, g_io_forward_0_forwardMask_3, i_io_forward_0_forwardMask_3); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_4) && g_io_forward_0_forwardMask_4 !== i_io_forward_0_forwardMask_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_4 g=%h i=%h", $time, g_io_forward_0_forwardMask_4, i_io_forward_0_forwardMask_4); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_5) && g_io_forward_0_forwardMask_5 !== i_io_forward_0_forwardMask_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_5 g=%h i=%h", $time, g_io_forward_0_forwardMask_5, i_io_forward_0_forwardMask_5); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_6) && g_io_forward_0_forwardMask_6 !== i_io_forward_0_forwardMask_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_6 g=%h i=%h", $time, g_io_forward_0_forwardMask_6, i_io_forward_0_forwardMask_6); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_7) && g_io_forward_0_forwardMask_7 !== i_io_forward_0_forwardMask_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_7 g=%h i=%h", $time, g_io_forward_0_forwardMask_7, i_io_forward_0_forwardMask_7); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_8) && g_io_forward_0_forwardMask_8 !== i_io_forward_0_forwardMask_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_8 g=%h i=%h", $time, g_io_forward_0_forwardMask_8, i_io_forward_0_forwardMask_8); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_9) && g_io_forward_0_forwardMask_9 !== i_io_forward_0_forwardMask_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_9 g=%h i=%h", $time, g_io_forward_0_forwardMask_9, i_io_forward_0_forwardMask_9); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_10) && g_io_forward_0_forwardMask_10 !== i_io_forward_0_forwardMask_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_10 g=%h i=%h", $time, g_io_forward_0_forwardMask_10, i_io_forward_0_forwardMask_10); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_11) && g_io_forward_0_forwardMask_11 !== i_io_forward_0_forwardMask_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_11 g=%h i=%h", $time, g_io_forward_0_forwardMask_11, i_io_forward_0_forwardMask_11); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_12) && g_io_forward_0_forwardMask_12 !== i_io_forward_0_forwardMask_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_12 g=%h i=%h", $time, g_io_forward_0_forwardMask_12, i_io_forward_0_forwardMask_12); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_13) && g_io_forward_0_forwardMask_13 !== i_io_forward_0_forwardMask_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_13 g=%h i=%h", $time, g_io_forward_0_forwardMask_13, i_io_forward_0_forwardMask_13); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_14) && g_io_forward_0_forwardMask_14 !== i_io_forward_0_forwardMask_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_14 g=%h i=%h", $time, g_io_forward_0_forwardMask_14, i_io_forward_0_forwardMask_14); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardMask_15) && g_io_forward_0_forwardMask_15 !== i_io_forward_0_forwardMask_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardMask_15 g=%h i=%h", $time, g_io_forward_0_forwardMask_15, i_io_forward_0_forwardMask_15); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_0) && g_io_forward_0_forwardData_0 !== i_io_forward_0_forwardData_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_0 g=%h i=%h", $time, g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_1) && g_io_forward_0_forwardData_1 !== i_io_forward_0_forwardData_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_1 g=%h i=%h", $time, g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_2) && g_io_forward_0_forwardData_2 !== i_io_forward_0_forwardData_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_2 g=%h i=%h", $time, g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_3) && g_io_forward_0_forwardData_3 !== i_io_forward_0_forwardData_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_3 g=%h i=%h", $time, g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_4) && g_io_forward_0_forwardData_4 !== i_io_forward_0_forwardData_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_4 g=%h i=%h", $time, g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_5) && g_io_forward_0_forwardData_5 !== i_io_forward_0_forwardData_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_5 g=%h i=%h", $time, g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_6) && g_io_forward_0_forwardData_6 !== i_io_forward_0_forwardData_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_6 g=%h i=%h", $time, g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_7) && g_io_forward_0_forwardData_7 !== i_io_forward_0_forwardData_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_7 g=%h i=%h", $time, g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_8) && g_io_forward_0_forwardData_8 !== i_io_forward_0_forwardData_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_8 g=%h i=%h", $time, g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_9) && g_io_forward_0_forwardData_9 !== i_io_forward_0_forwardData_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_9 g=%h i=%h", $time, g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_10) && g_io_forward_0_forwardData_10 !== i_io_forward_0_forwardData_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_10 g=%h i=%h", $time, g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_11) && g_io_forward_0_forwardData_11 !== i_io_forward_0_forwardData_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_11 g=%h i=%h", $time, g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_12) && g_io_forward_0_forwardData_12 !== i_io_forward_0_forwardData_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_12 g=%h i=%h", $time, g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_13) && g_io_forward_0_forwardData_13 !== i_io_forward_0_forwardData_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_13 g=%h i=%h", $time, g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_14) && g_io_forward_0_forwardData_14 !== i_io_forward_0_forwardData_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_14 g=%h i=%h", $time, g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_forwardData_15) && g_io_forward_0_forwardData_15 !== i_io_forward_0_forwardData_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_forwardData_15 g=%h i=%h", $time, g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15); end
    if ((fwd_v_q[0]) && !$isunknown(g_io_forward_0_matchInvalid) && g_io_forward_0_matchInvalid !== i_io_forward_0_matchInvalid) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_0_matchInvalid g=%h i=%h", $time, g_io_forward_0_matchInvalid, i_io_forward_0_matchInvalid); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_0) && g_io_forward_1_forwardMask_0 !== i_io_forward_1_forwardMask_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_0 g=%h i=%h", $time, g_io_forward_1_forwardMask_0, i_io_forward_1_forwardMask_0); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_1) && g_io_forward_1_forwardMask_1 !== i_io_forward_1_forwardMask_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_1 g=%h i=%h", $time, g_io_forward_1_forwardMask_1, i_io_forward_1_forwardMask_1); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_2) && g_io_forward_1_forwardMask_2 !== i_io_forward_1_forwardMask_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_2 g=%h i=%h", $time, g_io_forward_1_forwardMask_2, i_io_forward_1_forwardMask_2); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_3) && g_io_forward_1_forwardMask_3 !== i_io_forward_1_forwardMask_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_3 g=%h i=%h", $time, g_io_forward_1_forwardMask_3, i_io_forward_1_forwardMask_3); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_4) && g_io_forward_1_forwardMask_4 !== i_io_forward_1_forwardMask_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_4 g=%h i=%h", $time, g_io_forward_1_forwardMask_4, i_io_forward_1_forwardMask_4); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_5) && g_io_forward_1_forwardMask_5 !== i_io_forward_1_forwardMask_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_5 g=%h i=%h", $time, g_io_forward_1_forwardMask_5, i_io_forward_1_forwardMask_5); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_6) && g_io_forward_1_forwardMask_6 !== i_io_forward_1_forwardMask_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_6 g=%h i=%h", $time, g_io_forward_1_forwardMask_6, i_io_forward_1_forwardMask_6); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_7) && g_io_forward_1_forwardMask_7 !== i_io_forward_1_forwardMask_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_7 g=%h i=%h", $time, g_io_forward_1_forwardMask_7, i_io_forward_1_forwardMask_7); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_8) && g_io_forward_1_forwardMask_8 !== i_io_forward_1_forwardMask_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_8 g=%h i=%h", $time, g_io_forward_1_forwardMask_8, i_io_forward_1_forwardMask_8); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_9) && g_io_forward_1_forwardMask_9 !== i_io_forward_1_forwardMask_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_9 g=%h i=%h", $time, g_io_forward_1_forwardMask_9, i_io_forward_1_forwardMask_9); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_10) && g_io_forward_1_forwardMask_10 !== i_io_forward_1_forwardMask_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_10 g=%h i=%h", $time, g_io_forward_1_forwardMask_10, i_io_forward_1_forwardMask_10); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_11) && g_io_forward_1_forwardMask_11 !== i_io_forward_1_forwardMask_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_11 g=%h i=%h", $time, g_io_forward_1_forwardMask_11, i_io_forward_1_forwardMask_11); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_12) && g_io_forward_1_forwardMask_12 !== i_io_forward_1_forwardMask_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_12 g=%h i=%h", $time, g_io_forward_1_forwardMask_12, i_io_forward_1_forwardMask_12); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_13) && g_io_forward_1_forwardMask_13 !== i_io_forward_1_forwardMask_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_13 g=%h i=%h", $time, g_io_forward_1_forwardMask_13, i_io_forward_1_forwardMask_13); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_14) && g_io_forward_1_forwardMask_14 !== i_io_forward_1_forwardMask_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_14 g=%h i=%h", $time, g_io_forward_1_forwardMask_14, i_io_forward_1_forwardMask_14); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardMask_15) && g_io_forward_1_forwardMask_15 !== i_io_forward_1_forwardMask_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardMask_15 g=%h i=%h", $time, g_io_forward_1_forwardMask_15, i_io_forward_1_forwardMask_15); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_0) && g_io_forward_1_forwardData_0 !== i_io_forward_1_forwardData_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_0 g=%h i=%h", $time, g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_1) && g_io_forward_1_forwardData_1 !== i_io_forward_1_forwardData_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_1 g=%h i=%h", $time, g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_2) && g_io_forward_1_forwardData_2 !== i_io_forward_1_forwardData_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_2 g=%h i=%h", $time, g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_3) && g_io_forward_1_forwardData_3 !== i_io_forward_1_forwardData_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_3 g=%h i=%h", $time, g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_4) && g_io_forward_1_forwardData_4 !== i_io_forward_1_forwardData_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_4 g=%h i=%h", $time, g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_5) && g_io_forward_1_forwardData_5 !== i_io_forward_1_forwardData_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_5 g=%h i=%h", $time, g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_6) && g_io_forward_1_forwardData_6 !== i_io_forward_1_forwardData_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_6 g=%h i=%h", $time, g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_7) && g_io_forward_1_forwardData_7 !== i_io_forward_1_forwardData_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_7 g=%h i=%h", $time, g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_8) && g_io_forward_1_forwardData_8 !== i_io_forward_1_forwardData_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_8 g=%h i=%h", $time, g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_9) && g_io_forward_1_forwardData_9 !== i_io_forward_1_forwardData_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_9 g=%h i=%h", $time, g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_10) && g_io_forward_1_forwardData_10 !== i_io_forward_1_forwardData_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_10 g=%h i=%h", $time, g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_11) && g_io_forward_1_forwardData_11 !== i_io_forward_1_forwardData_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_11 g=%h i=%h", $time, g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_12) && g_io_forward_1_forwardData_12 !== i_io_forward_1_forwardData_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_12 g=%h i=%h", $time, g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_13) && g_io_forward_1_forwardData_13 !== i_io_forward_1_forwardData_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_13 g=%h i=%h", $time, g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_14) && g_io_forward_1_forwardData_14 !== i_io_forward_1_forwardData_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_14 g=%h i=%h", $time, g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_forwardData_15) && g_io_forward_1_forwardData_15 !== i_io_forward_1_forwardData_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_forwardData_15 g=%h i=%h", $time, g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15); end
    if ((fwd_v_q[1]) && !$isunknown(g_io_forward_1_matchInvalid) && g_io_forward_1_matchInvalid !== i_io_forward_1_matchInvalid) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_1_matchInvalid g=%h i=%h", $time, g_io_forward_1_matchInvalid, i_io_forward_1_matchInvalid); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_0) && g_io_forward_2_forwardMask_0 !== i_io_forward_2_forwardMask_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_0 g=%h i=%h", $time, g_io_forward_2_forwardMask_0, i_io_forward_2_forwardMask_0); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_1) && g_io_forward_2_forwardMask_1 !== i_io_forward_2_forwardMask_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_1 g=%h i=%h", $time, g_io_forward_2_forwardMask_1, i_io_forward_2_forwardMask_1); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_2) && g_io_forward_2_forwardMask_2 !== i_io_forward_2_forwardMask_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_2 g=%h i=%h", $time, g_io_forward_2_forwardMask_2, i_io_forward_2_forwardMask_2); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_3) && g_io_forward_2_forwardMask_3 !== i_io_forward_2_forwardMask_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_3 g=%h i=%h", $time, g_io_forward_2_forwardMask_3, i_io_forward_2_forwardMask_3); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_4) && g_io_forward_2_forwardMask_4 !== i_io_forward_2_forwardMask_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_4 g=%h i=%h", $time, g_io_forward_2_forwardMask_4, i_io_forward_2_forwardMask_4); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_5) && g_io_forward_2_forwardMask_5 !== i_io_forward_2_forwardMask_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_5 g=%h i=%h", $time, g_io_forward_2_forwardMask_5, i_io_forward_2_forwardMask_5); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_6) && g_io_forward_2_forwardMask_6 !== i_io_forward_2_forwardMask_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_6 g=%h i=%h", $time, g_io_forward_2_forwardMask_6, i_io_forward_2_forwardMask_6); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_7) && g_io_forward_2_forwardMask_7 !== i_io_forward_2_forwardMask_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_7 g=%h i=%h", $time, g_io_forward_2_forwardMask_7, i_io_forward_2_forwardMask_7); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_8) && g_io_forward_2_forwardMask_8 !== i_io_forward_2_forwardMask_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_8 g=%h i=%h", $time, g_io_forward_2_forwardMask_8, i_io_forward_2_forwardMask_8); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_9) && g_io_forward_2_forwardMask_9 !== i_io_forward_2_forwardMask_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_9 g=%h i=%h", $time, g_io_forward_2_forwardMask_9, i_io_forward_2_forwardMask_9); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_10) && g_io_forward_2_forwardMask_10 !== i_io_forward_2_forwardMask_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_10 g=%h i=%h", $time, g_io_forward_2_forwardMask_10, i_io_forward_2_forwardMask_10); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_11) && g_io_forward_2_forwardMask_11 !== i_io_forward_2_forwardMask_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_11 g=%h i=%h", $time, g_io_forward_2_forwardMask_11, i_io_forward_2_forwardMask_11); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_12) && g_io_forward_2_forwardMask_12 !== i_io_forward_2_forwardMask_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_12 g=%h i=%h", $time, g_io_forward_2_forwardMask_12, i_io_forward_2_forwardMask_12); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_13) && g_io_forward_2_forwardMask_13 !== i_io_forward_2_forwardMask_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_13 g=%h i=%h", $time, g_io_forward_2_forwardMask_13, i_io_forward_2_forwardMask_13); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_14) && g_io_forward_2_forwardMask_14 !== i_io_forward_2_forwardMask_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_14 g=%h i=%h", $time, g_io_forward_2_forwardMask_14, i_io_forward_2_forwardMask_14); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardMask_15) && g_io_forward_2_forwardMask_15 !== i_io_forward_2_forwardMask_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardMask_15 g=%h i=%h", $time, g_io_forward_2_forwardMask_15, i_io_forward_2_forwardMask_15); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_0) && g_io_forward_2_forwardData_0 !== i_io_forward_2_forwardData_0) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_0 g=%h i=%h", $time, g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_1) && g_io_forward_2_forwardData_1 !== i_io_forward_2_forwardData_1) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_1 g=%h i=%h", $time, g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_2) && g_io_forward_2_forwardData_2 !== i_io_forward_2_forwardData_2) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_2 g=%h i=%h", $time, g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_3) && g_io_forward_2_forwardData_3 !== i_io_forward_2_forwardData_3) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_3 g=%h i=%h", $time, g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_4) && g_io_forward_2_forwardData_4 !== i_io_forward_2_forwardData_4) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_4 g=%h i=%h", $time, g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_5) && g_io_forward_2_forwardData_5 !== i_io_forward_2_forwardData_5) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_5 g=%h i=%h", $time, g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_6) && g_io_forward_2_forwardData_6 !== i_io_forward_2_forwardData_6) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_6 g=%h i=%h", $time, g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_7) && g_io_forward_2_forwardData_7 !== i_io_forward_2_forwardData_7) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_7 g=%h i=%h", $time, g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_8) && g_io_forward_2_forwardData_8 !== i_io_forward_2_forwardData_8) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_8 g=%h i=%h", $time, g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_9) && g_io_forward_2_forwardData_9 !== i_io_forward_2_forwardData_9) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_9 g=%h i=%h", $time, g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_10) && g_io_forward_2_forwardData_10 !== i_io_forward_2_forwardData_10) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_10 g=%h i=%h", $time, g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_11) && g_io_forward_2_forwardData_11 !== i_io_forward_2_forwardData_11) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_11 g=%h i=%h", $time, g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_12) && g_io_forward_2_forwardData_12 !== i_io_forward_2_forwardData_12) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_12 g=%h i=%h", $time, g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_13) && g_io_forward_2_forwardData_13 !== i_io_forward_2_forwardData_13) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_13 g=%h i=%h", $time, g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_14) && g_io_forward_2_forwardData_14 !== i_io_forward_2_forwardData_14) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_14 g=%h i=%h", $time, g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_forwardData_15) && g_io_forward_2_forwardData_15 !== i_io_forward_2_forwardData_15) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_forwardData_15 g=%h i=%h", $time, g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15); end
    if ((fwd_v_q[2]) && !$isunknown(g_io_forward_2_matchInvalid) && g_io_forward_2_matchInvalid !== i_io_forward_2_matchInvalid) begin errors++;
      if(errors<=100000) $display("[%0t] io_forward_2_matchInvalid g=%h i=%h", $time, g_io_forward_2_matchInvalid, i_io_forward_2_matchInvalid); end
    if (!$isunknown(g_io_sbempty) && g_io_sbempty !== i_io_sbempty) begin errors++;
      if(errors<=100000) $display("[%0t] io_sbempty g=%h i=%h", $time, g_io_sbempty, i_io_sbempty); end
    if (!$isunknown(g_io_flush_empty) && g_io_flush_empty !== i_io_flush_empty) begin errors++;
      if(errors<=100000) $display("[%0t] io_flush_empty g=%h i=%h", $time, g_io_flush_empty, i_io_flush_empty); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
    if (!$isunknown(g_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end
    if (!$isunknown(g_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end
    if (!$isunknown(g_io_perf_7_value) && g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_7_value g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end
    if (!$isunknown(g_io_perf_8_value) && g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_8_value g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end
    if (!$isunknown(g_io_perf_9_value) && g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_9_value g=%h i=%h", $time, g_io_perf_9_value, i_io_perf_9_value); end
    if (!$isunknown(g_io_perf_10_value) && g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_10_value g=%h i=%h", $time, g_io_perf_10_value, i_io_perf_10_value); end
    if (!$isunknown(g_io_perf_11_value) && g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_11_value g=%h i=%h", $time, g_io_perf_11_value, i_io_perf_11_value); end
    if (!$isunknown(g_io_perf_12_value) && g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_12_value g=%h i=%h", $time, g_io_perf_12_value, i_io_perf_12_value); end
    if (!$isunknown(g_io_perf_13_value) && g_io_perf_13_value !== i_io_perf_13_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_13_value g=%h i=%h", $time, g_io_perf_13_value, i_io_perf_13_value); end
    if (!$isunknown(g_io_perf_14_value) && g_io_perf_14_value !== i_io_perf_14_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_14_value g=%h i=%h", $time, g_io_perf_14_value, i_io_perf_14_value); end
    if (!$isunknown(g_io_perf_15_value) && g_io_perf_15_value !== i_io_perf_15_value) begin errors++;
      if(errors<=100000) $display("[%0t] io_perf_15_value g=%h i=%h", $time, g_io_perf_15_value, i_io_perf_15_value); end
  end
  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
