// 自动生成：scripts/gen_sbuffer_tb.py —— 请勿手改
// （激励模板在 scripts/sbuffer_tb_stimulus.svh.in，改那里再重跑生成器）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- 共享输入（两侧同驱）----
  logic [5:0]      io_hartId;
  logic            io_in_0_valid;
  logic [49:0]     io_in_0_bits_vaddr;
  logic [127:0]    io_in_0_bits_data;
  logic [15:0]     io_in_0_bits_mask;
  logic [47:0]     io_in_0_bits_addr;
  logic            io_in_0_bits_wline;
  logic            io_in_0_bits_vecValid;
  logic            io_in_1_valid;
  logic [49:0]     io_in_1_bits_vaddr;
  logic [127:0]    io_in_1_bits_data;
  logic [15:0]     io_in_1_bits_mask;
  logic [47:0]     io_in_1_bits_addr;
  logic            io_in_1_bits_wline;
  logic            io_in_1_bits_vecValid;
  logic            io_dcache_req_ready;
  logic            io_dcache_main_pipe_hit_resp_valid;
  logic [5:0]      io_dcache_main_pipe_hit_resp_bits_id;
  logic            io_dcache_replay_resp_valid;
  logic [5:0]      io_dcache_replay_resp_bits_id;
  logic [49:0]     io_forward_0_vaddr;
  logic [47:0]     io_forward_0_paddr;
  logic            io_forward_0_valid;
  logic [49:0]     io_forward_1_vaddr;
  logic [47:0]     io_forward_1_paddr;
  logic            io_forward_1_valid;
  logic [49:0]     io_forward_2_vaddr;
  logic [47:0]     io_forward_2_paddr;
  logic            io_forward_2_valid;
  logic            io_sqempty;
  logic            io_flush_valid;
  logic [21:0]     io_csrCtrl_sbuffer_timeout;
  logic            io_force_write;
  logic [49:0]     io_diffStore_diffInfo_0_uop_pc;
  logic [34:0]     io_diffStore_diffInfo_0_uop_fuType;
  logic [8:0]      io_diffStore_diffInfo_0_uop_fuOpType;
  logic [2:0]      io_diffStore_diffInfo_0_uop_vpu_nf;
  logic [1:0]      io_diffStore_diffInfo_0_uop_vpu_veew;
  logic [7:0]      io_diffStore_diffInfo_0_uop_robIdx_value;
  logic [5:0]      io_diffStore_diffInfo_0_offset;
  logic [49:0]     io_diffStore_diffInfo_1_uop_pc;
  logic [34:0]     io_diffStore_diffInfo_1_uop_fuType;
  logic [8:0]      io_diffStore_diffInfo_1_uop_fuOpType;
  logic [2:0]      io_diffStore_diffInfo_1_uop_vpu_nf;
  logic [1:0]      io_diffStore_diffInfo_1_uop_vpu_veew;
  logic [7:0]      io_diffStore_diffInfo_1_uop_robIdx_value;
  logic [5:0]      io_diffStore_diffInfo_1_offset;
  logic            io_diffStore_pmaStore_0_valid;
  logic [127:0]    io_diffStore_pmaStore_0_bits_data;
  logic [15:0]     io_diffStore_pmaStore_0_bits_mask;
  logic [47:0]     io_diffStore_pmaStore_0_bits_addr;
  logic            io_diffStore_pmaStore_0_bits_wline;
  logic            io_diffStore_pmaStore_0_bits_vecValid;
  logic            io_diffStore_pmaStore_1_valid;
  logic [127:0]    io_diffStore_pmaStore_1_bits_data;
  logic [15:0]     io_diffStore_pmaStore_1_bits_mask;
  logic [47:0]     io_diffStore_pmaStore_1_bits_addr;
  logic            io_diffStore_pmaStore_1_bits_wline;
  logic            io_diffStore_pmaStore_1_bits_vecValid;
  logic            io_diffStore_ncStore_valid;
  logic [47:0]     io_diffStore_ncStore_bits_addr;
  logic [63:0]     io_diffStore_ncStore_bits_data;
  logic [7:0]      io_diffStore_ncStore_bits_mask;
  logic            io_diffStore_ncStore_bits_memBackTypeMM;

  // ---- 两侧输出 ----
  wire             g_io_in_0_ready, i_io_in_0_ready;
  wire             g_io_in_1_ready, i_io_in_1_ready;
  wire             g_io_dcache_req_valid, i_io_dcache_req_valid;
  wire  [49:0]     g_io_dcache_req_bits_vaddr, i_io_dcache_req_bits_vaddr;
  wire  [47:0]     g_io_dcache_req_bits_addr, i_io_dcache_req_bits_addr;
  wire  [511:0]    g_io_dcache_req_bits_data, i_io_dcache_req_bits_data;
  wire  [63:0]     g_io_dcache_req_bits_mask, i_io_dcache_req_bits_mask;
  wire  [5:0]      g_io_dcache_req_bits_id, i_io_dcache_req_bits_id;
  wire             g_io_forward_0_forwardMask_0, i_io_forward_0_forwardMask_0;
  wire             g_io_forward_0_forwardMask_1, i_io_forward_0_forwardMask_1;
  wire             g_io_forward_0_forwardMask_2, i_io_forward_0_forwardMask_2;
  wire             g_io_forward_0_forwardMask_3, i_io_forward_0_forwardMask_3;
  wire             g_io_forward_0_forwardMask_4, i_io_forward_0_forwardMask_4;
  wire             g_io_forward_0_forwardMask_5, i_io_forward_0_forwardMask_5;
  wire             g_io_forward_0_forwardMask_6, i_io_forward_0_forwardMask_6;
  wire             g_io_forward_0_forwardMask_7, i_io_forward_0_forwardMask_7;
  wire             g_io_forward_0_forwardMask_8, i_io_forward_0_forwardMask_8;
  wire             g_io_forward_0_forwardMask_9, i_io_forward_0_forwardMask_9;
  wire             g_io_forward_0_forwardMask_10, i_io_forward_0_forwardMask_10;
  wire             g_io_forward_0_forwardMask_11, i_io_forward_0_forwardMask_11;
  wire             g_io_forward_0_forwardMask_12, i_io_forward_0_forwardMask_12;
  wire             g_io_forward_0_forwardMask_13, i_io_forward_0_forwardMask_13;
  wire             g_io_forward_0_forwardMask_14, i_io_forward_0_forwardMask_14;
  wire             g_io_forward_0_forwardMask_15, i_io_forward_0_forwardMask_15;
  wire  [7:0]      g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0;
  wire  [7:0]      g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1;
  wire  [7:0]      g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2;
  wire  [7:0]      g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3;
  wire  [7:0]      g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4;
  wire  [7:0]      g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5;
  wire  [7:0]      g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6;
  wire  [7:0]      g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7;
  wire  [7:0]      g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8;
  wire  [7:0]      g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9;
  wire  [7:0]      g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10;
  wire  [7:0]      g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11;
  wire  [7:0]      g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12;
  wire  [7:0]      g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13;
  wire  [7:0]      g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14;
  wire  [7:0]      g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15;
  wire             g_io_forward_0_matchInvalid, i_io_forward_0_matchInvalid;
  wire             g_io_forward_1_forwardMask_0, i_io_forward_1_forwardMask_0;
  wire             g_io_forward_1_forwardMask_1, i_io_forward_1_forwardMask_1;
  wire             g_io_forward_1_forwardMask_2, i_io_forward_1_forwardMask_2;
  wire             g_io_forward_1_forwardMask_3, i_io_forward_1_forwardMask_3;
  wire             g_io_forward_1_forwardMask_4, i_io_forward_1_forwardMask_4;
  wire             g_io_forward_1_forwardMask_5, i_io_forward_1_forwardMask_5;
  wire             g_io_forward_1_forwardMask_6, i_io_forward_1_forwardMask_6;
  wire             g_io_forward_1_forwardMask_7, i_io_forward_1_forwardMask_7;
  wire             g_io_forward_1_forwardMask_8, i_io_forward_1_forwardMask_8;
  wire             g_io_forward_1_forwardMask_9, i_io_forward_1_forwardMask_9;
  wire             g_io_forward_1_forwardMask_10, i_io_forward_1_forwardMask_10;
  wire             g_io_forward_1_forwardMask_11, i_io_forward_1_forwardMask_11;
  wire             g_io_forward_1_forwardMask_12, i_io_forward_1_forwardMask_12;
  wire             g_io_forward_1_forwardMask_13, i_io_forward_1_forwardMask_13;
  wire             g_io_forward_1_forwardMask_14, i_io_forward_1_forwardMask_14;
  wire             g_io_forward_1_forwardMask_15, i_io_forward_1_forwardMask_15;
  wire  [7:0]      g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0;
  wire  [7:0]      g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1;
  wire  [7:0]      g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2;
  wire  [7:0]      g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3;
  wire  [7:0]      g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4;
  wire  [7:0]      g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5;
  wire  [7:0]      g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6;
  wire  [7:0]      g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7;
  wire  [7:0]      g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8;
  wire  [7:0]      g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9;
  wire  [7:0]      g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10;
  wire  [7:0]      g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11;
  wire  [7:0]      g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12;
  wire  [7:0]      g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13;
  wire  [7:0]      g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14;
  wire  [7:0]      g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15;
  wire             g_io_forward_1_matchInvalid, i_io_forward_1_matchInvalid;
  wire             g_io_forward_2_forwardMask_0, i_io_forward_2_forwardMask_0;
  wire             g_io_forward_2_forwardMask_1, i_io_forward_2_forwardMask_1;
  wire             g_io_forward_2_forwardMask_2, i_io_forward_2_forwardMask_2;
  wire             g_io_forward_2_forwardMask_3, i_io_forward_2_forwardMask_3;
  wire             g_io_forward_2_forwardMask_4, i_io_forward_2_forwardMask_4;
  wire             g_io_forward_2_forwardMask_5, i_io_forward_2_forwardMask_5;
  wire             g_io_forward_2_forwardMask_6, i_io_forward_2_forwardMask_6;
  wire             g_io_forward_2_forwardMask_7, i_io_forward_2_forwardMask_7;
  wire             g_io_forward_2_forwardMask_8, i_io_forward_2_forwardMask_8;
  wire             g_io_forward_2_forwardMask_9, i_io_forward_2_forwardMask_9;
  wire             g_io_forward_2_forwardMask_10, i_io_forward_2_forwardMask_10;
  wire             g_io_forward_2_forwardMask_11, i_io_forward_2_forwardMask_11;
  wire             g_io_forward_2_forwardMask_12, i_io_forward_2_forwardMask_12;
  wire             g_io_forward_2_forwardMask_13, i_io_forward_2_forwardMask_13;
  wire             g_io_forward_2_forwardMask_14, i_io_forward_2_forwardMask_14;
  wire             g_io_forward_2_forwardMask_15, i_io_forward_2_forwardMask_15;
  wire  [7:0]      g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0;
  wire  [7:0]      g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1;
  wire  [7:0]      g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2;
  wire  [7:0]      g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3;
  wire  [7:0]      g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4;
  wire  [7:0]      g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5;
  wire  [7:0]      g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6;
  wire  [7:0]      g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7;
  wire  [7:0]      g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8;
  wire  [7:0]      g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9;
  wire  [7:0]      g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10;
  wire  [7:0]      g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11;
  wire  [7:0]      g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12;
  wire  [7:0]      g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13;
  wire  [7:0]      g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14;
  wire  [7:0]      g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15;
  wire             g_io_forward_2_matchInvalid, i_io_forward_2_matchInvalid;
  wire             g_io_sbempty, i_io_sbempty;
  wire             g_io_sbFull, i_io_sbFull;
  wire             g_io_flush_empty, i_io_flush_empty;
  wire  [5:0]      g_io_perf_0_value, i_io_perf_0_value;
  wire  [5:0]      g_io_perf_1_value, i_io_perf_1_value;
  wire  [5:0]      g_io_perf_2_value, i_io_perf_2_value;
  wire  [5:0]      g_io_perf_3_value, i_io_perf_3_value;
  wire  [5:0]      g_io_perf_4_value, i_io_perf_4_value;
  wire  [5:0]      g_io_perf_5_value, i_io_perf_5_value;
  wire  [5:0]      g_io_perf_6_value, i_io_perf_6_value;
  wire  [5:0]      g_io_perf_7_value, i_io_perf_7_value;
  wire  [5:0]      g_io_perf_8_value, i_io_perf_8_value;
  wire  [5:0]      g_io_perf_9_value, i_io_perf_9_value;
  wire  [5:0]      g_io_perf_10_value, i_io_perf_10_value;
  wire  [5:0]      g_io_perf_11_value, i_io_perf_11_value;
  wire  [5:0]      g_io_perf_12_value, i_io_perf_12_value;
  wire  [5:0]      g_io_perf_13_value, i_io_perf_13_value;
  wire  [5:0]      g_io_perf_14_value, i_io_perf_14_value;
  wire  [5:0]      g_io_perf_15_value, i_io_perf_15_value;
  wire  [656:0]    g_gatewayIn_packed_49_bore, i_gatewayIn_packed_49_bore;
  wire  [324:0]    g_gatewayIn_packed_50_bore, i_gatewayIn_packed_50_bore;
  wire  [324:0]    g_gatewayIn_packed_51_bore, i_gatewayIn_packed_51_bore;
  wire  [324:0]    g_gatewayIn_packed_52_bore, i_gatewayIn_packed_52_bore;

  Sbuffer    u_g (.clock(clk), .reset(rst), .io_hartId(io_hartId), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_vaddr(io_in_0_bits_vaddr), .io_in_0_bits_data(io_in_0_bits_data), .io_in_0_bits_mask(io_in_0_bits_mask), .io_in_0_bits_addr(io_in_0_bits_addr), .io_in_0_bits_wline(io_in_0_bits_wline), .io_in_0_bits_vecValid(io_in_0_bits_vecValid), .io_in_1_valid(io_in_1_valid), .io_in_1_bits_vaddr(io_in_1_bits_vaddr), .io_in_1_bits_data(io_in_1_bits_data), .io_in_1_bits_mask(io_in_1_bits_mask), .io_in_1_bits_addr(io_in_1_bits_addr), .io_in_1_bits_wline(io_in_1_bits_wline), .io_in_1_bits_vecValid(io_in_1_bits_vecValid), .io_dcache_req_ready(io_dcache_req_ready), .io_dcache_main_pipe_hit_resp_valid(io_dcache_main_pipe_hit_resp_valid), .io_dcache_main_pipe_hit_resp_bits_id(io_dcache_main_pipe_hit_resp_bits_id), .io_dcache_replay_resp_valid(io_dcache_replay_resp_valid), .io_dcache_replay_resp_bits_id(io_dcache_replay_resp_bits_id), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_sqempty(io_sqempty), .io_flush_valid(io_flush_valid), .io_csrCtrl_sbuffer_timeout(io_csrCtrl_sbuffer_timeout), .io_force_write(io_force_write), .io_diffStore_diffInfo_0_uop_pc(io_diffStore_diffInfo_0_uop_pc), .io_diffStore_diffInfo_0_uop_fuType(io_diffStore_diffInfo_0_uop_fuType), .io_diffStore_diffInfo_0_uop_fuOpType(io_diffStore_diffInfo_0_uop_fuOpType), .io_diffStore_diffInfo_0_uop_vpu_nf(io_diffStore_diffInfo_0_uop_vpu_nf), .io_diffStore_diffInfo_0_uop_vpu_veew(io_diffStore_diffInfo_0_uop_vpu_veew), .io_diffStore_diffInfo_0_uop_robIdx_value(io_diffStore_diffInfo_0_uop_robIdx_value), .io_diffStore_diffInfo_0_offset(io_diffStore_diffInfo_0_offset), .io_diffStore_diffInfo_1_uop_pc(io_diffStore_diffInfo_1_uop_pc), .io_diffStore_diffInfo_1_uop_fuType(io_diffStore_diffInfo_1_uop_fuType), .io_diffStore_diffInfo_1_uop_fuOpType(io_diffStore_diffInfo_1_uop_fuOpType), .io_diffStore_diffInfo_1_uop_vpu_nf(io_diffStore_diffInfo_1_uop_vpu_nf), .io_diffStore_diffInfo_1_uop_vpu_veew(io_diffStore_diffInfo_1_uop_vpu_veew), .io_diffStore_diffInfo_1_uop_robIdx_value(io_diffStore_diffInfo_1_uop_robIdx_value), .io_diffStore_diffInfo_1_offset(io_diffStore_diffInfo_1_offset), .io_diffStore_pmaStore_0_valid(io_diffStore_pmaStore_0_valid), .io_diffStore_pmaStore_0_bits_data(io_diffStore_pmaStore_0_bits_data), .io_diffStore_pmaStore_0_bits_mask(io_diffStore_pmaStore_0_bits_mask), .io_diffStore_pmaStore_0_bits_addr(io_diffStore_pmaStore_0_bits_addr), .io_diffStore_pmaStore_0_bits_wline(io_diffStore_pmaStore_0_bits_wline), .io_diffStore_pmaStore_0_bits_vecValid(io_diffStore_pmaStore_0_bits_vecValid), .io_diffStore_pmaStore_1_valid(io_diffStore_pmaStore_1_valid), .io_diffStore_pmaStore_1_bits_data(io_diffStore_pmaStore_1_bits_data), .io_diffStore_pmaStore_1_bits_mask(io_diffStore_pmaStore_1_bits_mask), .io_diffStore_pmaStore_1_bits_addr(io_diffStore_pmaStore_1_bits_addr), .io_diffStore_pmaStore_1_bits_wline(io_diffStore_pmaStore_1_bits_wline), .io_diffStore_pmaStore_1_bits_vecValid(io_diffStore_pmaStore_1_bits_vecValid), .io_diffStore_ncStore_valid(io_diffStore_ncStore_valid), .io_diffStore_ncStore_bits_addr(io_diffStore_ncStore_bits_addr), .io_diffStore_ncStore_bits_data(io_diffStore_ncStore_bits_data), .io_diffStore_ncStore_bits_mask(io_diffStore_ncStore_bits_mask), .io_diffStore_ncStore_bits_memBackTypeMM(io_diffStore_ncStore_bits_memBackTypeMM), .io_in_0_ready(g_io_in_0_ready), .io_in_1_ready(g_io_in_1_ready), .io_dcache_req_valid(g_io_dcache_req_valid), .io_dcache_req_bits_vaddr(g_io_dcache_req_bits_vaddr), .io_dcache_req_bits_addr(g_io_dcache_req_bits_addr), .io_dcache_req_bits_data(g_io_dcache_req_bits_data), .io_dcache_req_bits_mask(g_io_dcache_req_bits_mask), .io_dcache_req_bits_id(g_io_dcache_req_bits_id), .io_forward_0_forwardMask_0(g_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(g_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(g_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(g_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(g_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(g_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(g_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(g_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(g_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(g_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(g_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(g_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(g_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(g_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(g_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(g_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(g_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(g_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(g_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(g_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(g_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(g_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(g_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(g_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(g_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(g_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(g_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(g_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(g_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(g_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(g_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(g_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(g_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(g_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(g_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(g_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(g_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(g_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(g_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(g_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(g_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(g_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(g_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(g_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(g_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(g_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(g_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(g_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(g_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(g_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(g_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(g_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(g_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(g_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(g_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(g_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(g_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(g_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(g_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(g_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(g_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(g_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(g_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(g_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(g_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(g_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(g_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(g_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(g_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(g_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(g_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(g_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(g_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(g_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(g_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(g_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(g_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(g_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(g_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(g_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(g_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(g_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(g_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(g_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(g_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(g_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(g_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(g_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(g_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(g_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(g_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(g_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(g_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(g_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(g_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(g_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(g_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(g_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(g_io_forward_2_matchInvalid), .io_sbempty(g_io_sbempty), .io_sbFull(g_io_sbFull), .io_flush_empty(g_io_flush_empty), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .io_perf_8_value(g_io_perf_8_value), .io_perf_9_value(g_io_perf_9_value), .io_perf_10_value(g_io_perf_10_value), .io_perf_11_value(g_io_perf_11_value), .io_perf_12_value(g_io_perf_12_value), .io_perf_13_value(g_io_perf_13_value), .io_perf_14_value(g_io_perf_14_value), .io_perf_15_value(g_io_perf_15_value), .gatewayIn_packed_49_bore(g_gatewayIn_packed_49_bore), .gatewayIn_packed_50_bore(g_gatewayIn_packed_50_bore), .gatewayIn_packed_51_bore(g_gatewayIn_packed_51_bore), .gatewayIn_packed_52_bore(g_gatewayIn_packed_52_bore));
  Sbuffer_xs u_i (.clock(clk), .reset(rst), .io_hartId(io_hartId), .io_in_0_valid(io_in_0_valid), .io_in_0_bits_vaddr(io_in_0_bits_vaddr), .io_in_0_bits_data(io_in_0_bits_data), .io_in_0_bits_mask(io_in_0_bits_mask), .io_in_0_bits_addr(io_in_0_bits_addr), .io_in_0_bits_wline(io_in_0_bits_wline), .io_in_0_bits_vecValid(io_in_0_bits_vecValid), .io_in_1_valid(io_in_1_valid), .io_in_1_bits_vaddr(io_in_1_bits_vaddr), .io_in_1_bits_data(io_in_1_bits_data), .io_in_1_bits_mask(io_in_1_bits_mask), .io_in_1_bits_addr(io_in_1_bits_addr), .io_in_1_bits_wline(io_in_1_bits_wline), .io_in_1_bits_vecValid(io_in_1_bits_vecValid), .io_dcache_req_ready(io_dcache_req_ready), .io_dcache_main_pipe_hit_resp_valid(io_dcache_main_pipe_hit_resp_valid), .io_dcache_main_pipe_hit_resp_bits_id(io_dcache_main_pipe_hit_resp_bits_id), .io_dcache_replay_resp_valid(io_dcache_replay_resp_valid), .io_dcache_replay_resp_bits_id(io_dcache_replay_resp_bits_id), .io_forward_0_vaddr(io_forward_0_vaddr), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_0_valid(io_forward_0_valid), .io_forward_1_vaddr(io_forward_1_vaddr), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_2_vaddr(io_forward_2_vaddr), .io_forward_2_paddr(io_forward_2_paddr), .io_forward_2_valid(io_forward_2_valid), .io_sqempty(io_sqempty), .io_flush_valid(io_flush_valid), .io_csrCtrl_sbuffer_timeout(io_csrCtrl_sbuffer_timeout), .io_force_write(io_force_write), .io_diffStore_diffInfo_0_uop_pc(io_diffStore_diffInfo_0_uop_pc), .io_diffStore_diffInfo_0_uop_fuType(io_diffStore_diffInfo_0_uop_fuType), .io_diffStore_diffInfo_0_uop_fuOpType(io_diffStore_diffInfo_0_uop_fuOpType), .io_diffStore_diffInfo_0_uop_vpu_nf(io_diffStore_diffInfo_0_uop_vpu_nf), .io_diffStore_diffInfo_0_uop_vpu_veew(io_diffStore_diffInfo_0_uop_vpu_veew), .io_diffStore_diffInfo_0_uop_robIdx_value(io_diffStore_diffInfo_0_uop_robIdx_value), .io_diffStore_diffInfo_0_offset(io_diffStore_diffInfo_0_offset), .io_diffStore_diffInfo_1_uop_pc(io_diffStore_diffInfo_1_uop_pc), .io_diffStore_diffInfo_1_uop_fuType(io_diffStore_diffInfo_1_uop_fuType), .io_diffStore_diffInfo_1_uop_fuOpType(io_diffStore_diffInfo_1_uop_fuOpType), .io_diffStore_diffInfo_1_uop_vpu_nf(io_diffStore_diffInfo_1_uop_vpu_nf), .io_diffStore_diffInfo_1_uop_vpu_veew(io_diffStore_diffInfo_1_uop_vpu_veew), .io_diffStore_diffInfo_1_uop_robIdx_value(io_diffStore_diffInfo_1_uop_robIdx_value), .io_diffStore_diffInfo_1_offset(io_diffStore_diffInfo_1_offset), .io_diffStore_pmaStore_0_valid(io_diffStore_pmaStore_0_valid), .io_diffStore_pmaStore_0_bits_data(io_diffStore_pmaStore_0_bits_data), .io_diffStore_pmaStore_0_bits_mask(io_diffStore_pmaStore_0_bits_mask), .io_diffStore_pmaStore_0_bits_addr(io_diffStore_pmaStore_0_bits_addr), .io_diffStore_pmaStore_0_bits_wline(io_diffStore_pmaStore_0_bits_wline), .io_diffStore_pmaStore_0_bits_vecValid(io_diffStore_pmaStore_0_bits_vecValid), .io_diffStore_pmaStore_1_valid(io_diffStore_pmaStore_1_valid), .io_diffStore_pmaStore_1_bits_data(io_diffStore_pmaStore_1_bits_data), .io_diffStore_pmaStore_1_bits_mask(io_diffStore_pmaStore_1_bits_mask), .io_diffStore_pmaStore_1_bits_addr(io_diffStore_pmaStore_1_bits_addr), .io_diffStore_pmaStore_1_bits_wline(io_diffStore_pmaStore_1_bits_wline), .io_diffStore_pmaStore_1_bits_vecValid(io_diffStore_pmaStore_1_bits_vecValid), .io_diffStore_ncStore_valid(io_diffStore_ncStore_valid), .io_diffStore_ncStore_bits_addr(io_diffStore_ncStore_bits_addr), .io_diffStore_ncStore_bits_data(io_diffStore_ncStore_bits_data), .io_diffStore_ncStore_bits_mask(io_diffStore_ncStore_bits_mask), .io_diffStore_ncStore_bits_memBackTypeMM(io_diffStore_ncStore_bits_memBackTypeMM), .io_in_0_ready(i_io_in_0_ready), .io_in_1_ready(i_io_in_1_ready), .io_dcache_req_valid(i_io_dcache_req_valid), .io_dcache_req_bits_vaddr(i_io_dcache_req_bits_vaddr), .io_dcache_req_bits_addr(i_io_dcache_req_bits_addr), .io_dcache_req_bits_data(i_io_dcache_req_bits_data), .io_dcache_req_bits_mask(i_io_dcache_req_bits_mask), .io_dcache_req_bits_id(i_io_dcache_req_bits_id), .io_forward_0_forwardMask_0(i_io_forward_0_forwardMask_0), .io_forward_0_forwardMask_1(i_io_forward_0_forwardMask_1), .io_forward_0_forwardMask_2(i_io_forward_0_forwardMask_2), .io_forward_0_forwardMask_3(i_io_forward_0_forwardMask_3), .io_forward_0_forwardMask_4(i_io_forward_0_forwardMask_4), .io_forward_0_forwardMask_5(i_io_forward_0_forwardMask_5), .io_forward_0_forwardMask_6(i_io_forward_0_forwardMask_6), .io_forward_0_forwardMask_7(i_io_forward_0_forwardMask_7), .io_forward_0_forwardMask_8(i_io_forward_0_forwardMask_8), .io_forward_0_forwardMask_9(i_io_forward_0_forwardMask_9), .io_forward_0_forwardMask_10(i_io_forward_0_forwardMask_10), .io_forward_0_forwardMask_11(i_io_forward_0_forwardMask_11), .io_forward_0_forwardMask_12(i_io_forward_0_forwardMask_12), .io_forward_0_forwardMask_13(i_io_forward_0_forwardMask_13), .io_forward_0_forwardMask_14(i_io_forward_0_forwardMask_14), .io_forward_0_forwardMask_15(i_io_forward_0_forwardMask_15), .io_forward_0_forwardData_0(i_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(i_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(i_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(i_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(i_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(i_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(i_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(i_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(i_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(i_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(i_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(i_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(i_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(i_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(i_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(i_io_forward_0_forwardData_15), .io_forward_0_matchInvalid(i_io_forward_0_matchInvalid), .io_forward_1_forwardMask_0(i_io_forward_1_forwardMask_0), .io_forward_1_forwardMask_1(i_io_forward_1_forwardMask_1), .io_forward_1_forwardMask_2(i_io_forward_1_forwardMask_2), .io_forward_1_forwardMask_3(i_io_forward_1_forwardMask_3), .io_forward_1_forwardMask_4(i_io_forward_1_forwardMask_4), .io_forward_1_forwardMask_5(i_io_forward_1_forwardMask_5), .io_forward_1_forwardMask_6(i_io_forward_1_forwardMask_6), .io_forward_1_forwardMask_7(i_io_forward_1_forwardMask_7), .io_forward_1_forwardMask_8(i_io_forward_1_forwardMask_8), .io_forward_1_forwardMask_9(i_io_forward_1_forwardMask_9), .io_forward_1_forwardMask_10(i_io_forward_1_forwardMask_10), .io_forward_1_forwardMask_11(i_io_forward_1_forwardMask_11), .io_forward_1_forwardMask_12(i_io_forward_1_forwardMask_12), .io_forward_1_forwardMask_13(i_io_forward_1_forwardMask_13), .io_forward_1_forwardMask_14(i_io_forward_1_forwardMask_14), .io_forward_1_forwardMask_15(i_io_forward_1_forwardMask_15), .io_forward_1_forwardData_0(i_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(i_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(i_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(i_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(i_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(i_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(i_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(i_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(i_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(i_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(i_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(i_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(i_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(i_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(i_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(i_io_forward_1_forwardData_15), .io_forward_1_matchInvalid(i_io_forward_1_matchInvalid), .io_forward_2_forwardMask_0(i_io_forward_2_forwardMask_0), .io_forward_2_forwardMask_1(i_io_forward_2_forwardMask_1), .io_forward_2_forwardMask_2(i_io_forward_2_forwardMask_2), .io_forward_2_forwardMask_3(i_io_forward_2_forwardMask_3), .io_forward_2_forwardMask_4(i_io_forward_2_forwardMask_4), .io_forward_2_forwardMask_5(i_io_forward_2_forwardMask_5), .io_forward_2_forwardMask_6(i_io_forward_2_forwardMask_6), .io_forward_2_forwardMask_7(i_io_forward_2_forwardMask_7), .io_forward_2_forwardMask_8(i_io_forward_2_forwardMask_8), .io_forward_2_forwardMask_9(i_io_forward_2_forwardMask_9), .io_forward_2_forwardMask_10(i_io_forward_2_forwardMask_10), .io_forward_2_forwardMask_11(i_io_forward_2_forwardMask_11), .io_forward_2_forwardMask_12(i_io_forward_2_forwardMask_12), .io_forward_2_forwardMask_13(i_io_forward_2_forwardMask_13), .io_forward_2_forwardMask_14(i_io_forward_2_forwardMask_14), .io_forward_2_forwardMask_15(i_io_forward_2_forwardMask_15), .io_forward_2_forwardData_0(i_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(i_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(i_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(i_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(i_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(i_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(i_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(i_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(i_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(i_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(i_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(i_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(i_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(i_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(i_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(i_io_forward_2_forwardData_15), .io_forward_2_matchInvalid(i_io_forward_2_matchInvalid), .io_sbempty(i_io_sbempty), .io_sbFull(i_io_sbFull), .io_flush_empty(i_io_flush_empty), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .io_perf_8_value(i_io_perf_8_value), .io_perf_9_value(i_io_perf_9_value), .io_perf_10_value(i_io_perf_10_value), .io_perf_11_value(i_io_perf_11_value), .io_perf_12_value(i_io_perf_12_value), .io_perf_13_value(i_io_perf_13_value), .io_perf_14_value(i_io_perf_14_value), .io_perf_15_value(i_io_perf_15_value), .gatewayIn_packed_49_bore(i_gatewayIn_packed_49_bore), .gatewayIn_packed_50_bore(i_gatewayIn_packed_50_bore), .gatewayIn_packed_51_bore(i_gatewayIn_packed_51_bore), .gatewayIn_packed_52_bore(i_gatewayIn_packed_52_bore));

  // ===========================================================================
  //  激励与覆盖闸（手写；由 gen_sbuffer_tb.py 原样嵌进 tb.sv）
  // ---------------------------------------------------------------------------
  //  ★为什么需要暖机窗口★
  //  SbufferData 的 data 阵列（16 entry × 4 vword × 16 byte）在 golden 里**没有复位**
  //  ——契约是「只读掩码置起过的字节」。但 Sbuffer 的 io_dcache_req_bits_data 与
  //  io_forward_*_forwardData 都是**不经掩码门控**直接吐出整行/整字的，于是在
  //  `+vcs+initreg+random` 下两侧各自抽到不同的上电值 ⇒ 必然不等。
  //  这时红的是 tb 不是 RTL。修法：先跑一段**只发整行写（wline=1）**的填充阶段，
  //  把 16 条 entry 的全部 64 字节都写成确定值，再打开比较窗口。
  //  填充完成的判据不是「跑够多少拍」而是**观测到 io_sbFull**（= 16 条 entry 全 valid，
  //  每条都是被一次 wline 写分配的）；没在上限内观测到就当场判 FAIL，不许静默放过。
  // ===========================================================================
  localparam int NBLK      = 24;     // 地址池 block 数（> 16，保证会发生替换/逐出）
  localparam int FILL_MAX  = 4000;   // 填充阶段上限拍数
  localparam int SETTLE    = 400;    // 填充完成后的稳定拍数（让 s1 逐出寄存器被写过）

  int unsigned cyc = 0;
  bit          compare_open = 0;
  // 诊断模式：+diag_cmp_now 让比较窗口从第 2 拍就打开（配 +vcs+initreg+0 用，
  // 两侧无复位寄存器都是 0，不需要暖机）。★该模式永远不报 TEST PASSED★，
  // 只用来定位第一处分歧，不能当验收。
  bit          diag_cmp_now = 0;
  bit          fill_done    = 0;
  int unsigned fill_cycle   = 0;
  int unsigned settle_cnt   = 0;

  // 在途 entry 影子：由 golden 的 dcache_req fire 置位、由 hit_resp 清位。
  // 用 golden 的输出做影子是允许的——它只决定**共享激励**，两侧看到的输入完全相同。
  // ★影子只是「优先猜测」，不是唯一来源★：一开始只按影子回应，结果 20k 拍里
  //   req_fire 只有 91 次 —— entry 1 一直 inflight，影子却没标上，
  //   于是永远收不到它的 hit_resp，整个 buffer 卡死在 DRAIN_ALL。
  //   所以留一条「随机 id 回应」的旁路：回应非法 id 对等价性无害（两侧同输入），
  //   却能把这类自锁打开。
  bit [15:0] inflight_shadow;

  // 激励模式：每 MODE_LEN 拍换一次，保证各类窗口都被走到
  //   0 = 满负荷写入      1 = 静默（不发 store，让 buffer 排空、sq_empty 成立）
  //   2 = 同 block 猛打（小地址池 → 大量 merge）
  //   3 = 小 coh 门限（打 G1 新增的 CSR 可编程超时路径）
  localparam int MODE_LEN = 512;
  int unsigned mode = 0;
  int unsigned mode_nblk = NBLK;

  // ---- 覆盖计数（全部取自 golden 的可观测输出；perf 口本身就是事件计数）----
  longint cov_in_fire, cov_merge, cov_alloc, cov_req_fire, cov_hit, cov_replay;
  longint cov_cohto, cov_idle, cov_drain_sb, cov_replace, cov_minv, cov_sbfull;
  longint cov_flush_empty, cov_fwd_hit, cov_nc_store, cov_pma_store, cov_oob_id;
  longint cov_sametag_alias;   // 两路同 ptag、异 vtag、且两路都被接收的拍数

  // ---- 地址构造：ptag 只用低位 block 号，vaddr 与 paddr 保持一致映射 ----------
  //   正常情况下 vtag 与 ptag 一一对应（vaddr = {2'b0, paddr}），forward/merge 的
  //   vtag 检查恒成立；以小概率注入 vaddr 别名（翻高位）来打 matchInvalid /
  //   micro-arch drain 这条路径。
  function automatic logic [47:0] mk_paddr(input int blk, input int off);
    return {34'h0, blk[7:0], off[5:0]};
  endfunction
  function automatic logic [49:0] mk_vaddr(input logic [47:0] pa, input bit alias_it);
    return {alias_it ? 2'b01 : 2'b00, pa};
  endfunction

  // ---------------------------------------------------------------------------
  //  主激励：在 negedge 驱动，避免与 posedge 采样竞争
  // ---------------------------------------------------------------------------
  always @(negedge clk) begin
    if (rst) begin
      io_hartId                  <= 6'h3;
      io_in_0_valid              <= 1'b0;
      io_in_1_valid              <= 1'b0;
      io_in_0_bits_vaddr         <= '0;
      io_in_0_bits_data          <= '0;
      io_in_0_bits_mask          <= '0;
      io_in_0_bits_addr          <= '0;
      io_in_0_bits_wline         <= 1'b0;
      io_in_0_bits_vecValid      <= 1'b0;
      io_in_1_bits_vaddr         <= '0;
      io_in_1_bits_data          <= '0;
      io_in_1_bits_mask          <= '0;
      io_in_1_bits_addr          <= '0;
      io_in_1_bits_wline         <= 1'b0;
      io_in_1_bits_vecValid      <= 1'b0;
      io_dcache_req_ready        <= 1'b0;
      io_dcache_main_pipe_hit_resp_valid   <= 1'b0;
      io_dcache_main_pipe_hit_resp_bits_id <= '0;
      io_dcache_replay_resp_valid          <= 1'b0;
      io_dcache_replay_resp_bits_id        <= '0;
      io_forward_0_valid         <= 1'b1;
      io_forward_1_valid         <= 1'b1;
      io_forward_2_valid         <= 1'b1;
      io_forward_0_vaddr         <= '0; io_forward_0_paddr <= '0;
      io_forward_1_vaddr         <= '0; io_forward_1_paddr <= '0;
      io_forward_2_vaddr         <= '0; io_forward_2_paddr <= '0;
      io_sqempty                 <= 1'b1;
      io_flush_valid             <= 1'b0;
      io_force_write             <= 1'b0;
      io_csrCtrl_sbuffer_timeout <= 22'h3FFFFF;   // 填充阶段不让 coh 超时
      inflight_shadow            <= 16'h0;
    end else begin
      automatic bit  quiet = fill_done && (mode == 1);
      automatic int  nblk  = fill_done ? ((mode == 2) ? 6 : mode_nblk) : NBLK;
      automatic int  b0    = $urandom_range(0, nblk-1);
      automatic int  b1    = $urandom_range(0, nblk-1);
      automatic int  off0  = $urandom_range(0, 63);
      automatic int  off1  = $urandom_range(0, 63);
      automatic logic [47:0] pa0 = mk_paddr(b0, off0);
      automatic logic [47:0] pa1 = mk_paddr(b1, off1);
      automatic bit  al0   = compare_open && ($urandom_range(0, 255) == 0);
      automatic bit  al1   = compare_open && ($urandom_range(0, 255) == 0);
      // ★针对性激励（由变异体 M8 逃逸逼出来的）★
      //   M8 把 alloc 时 ptag/vtag 的覆盖优先级从 port1 改成 port0。要分辨这两种写法
      //   必须同时满足：两路 sameTag（ptag 相同）→ 落到**同一条 entry**，而且两路的
      //   **vtag 不同**。纯随机激励下这两件事同时成立的概率约 1e-5/拍，3 万拍一次没中，
      //   M8 于是 errors=0 逃逸。这里直接造出来：第二路复用第一路的 paddr，
      //   同时把 vaddr 的别名位取反。
      automatic bit  same_line = fill_done && ($urandom_range(0, 47) == 0);
      automatic int  fb    = $urandom_range(0, nblk-1);
      automatic int  foff  = $urandom_range(0, 63);
      automatic int  fb1   = $urandom_range(0, nblk-1);
      automatic int  fb2   = $urandom_range(0, nblk-1);
      automatic bit [15:0] cand;   // 可回应的在途 entry 集合
      automatic int  pick;

      if (same_line) begin
        pa1 = pa0;
        al1 = ~al0;
      end

      // ---- 入口两路 store ----------------------------------------------------
      io_in_0_bits_addr     <= pa0;
      io_in_0_bits_vaddr    <= mk_vaddr(pa0, al0);
      io_in_0_bits_data     <= {$urandom(),$urandom(),$urandom(),$urandom()};
      io_in_0_bits_mask     <= 16'($urandom());
      io_in_0_bits_vecValid <= fill_done ? ($urandom_range(0,15) != 0) : 1'b1;
      io_in_0_valid         <= quiet ? 1'b0 : (fill_done ? ($urandom_range(0,3) != 0) : 1'b1);
      io_in_1_bits_addr     <= pa1;
      io_in_1_bits_vaddr    <= mk_vaddr(pa1, al1);
      io_in_1_bits_data     <= {$urandom(),$urandom(),$urandom(),$urandom()};
      io_in_1_bits_mask     <= 16'($urandom());
      io_in_1_bits_vecValid <= fill_done ? ($urandom_range(0,15) != 0) : 1'b1;
      io_in_1_valid         <= quiet ? 1'b0 : (fill_done ? ($urandom_range(0,3) != 0) : 1'b1);
      // ★填充阶段整行写★：wline=1 会把该 entry 的 4 个 vword × 16 字节全部写掉，
      //   这正是把无复位 data 阵列变成确定值的手段。
      io_in_0_bits_wline    <= fill_done ? ($urandom_range(0,7) == 0) : 1'b1;
      io_in_1_bits_wline    <= fill_done ? ($urandom_range(0,7) == 0) : 1'b1;

      // ---- DCache 侧：填充阶段不收，之后随机 ---------------------------------
      io_dcache_req_ready <= fill_done ? ($urandom_range(0,3) != 0) : 1'b0;

      // ---- hit / replay 回应：只挑真正在途的 entry（保持激励合法）------------
      cand = inflight_shadow;
      pick = $urandom_range(0, 15);
      // 影子非空时优先挑一个真在途的；否则（或 1/8 概率）直接用随机 id 解自锁
      if ((|cand) && $urandom_range(0, 7) != 0)
        for (int k = 0; k < 16; k++)
          if (cand[(pick + k) % 16]) begin pick = (pick + k) % 16; break; end
      io_dcache_main_pipe_hit_resp_valid <= 1'b0;
      io_dcache_replay_resp_valid        <= 1'b0;
      // ★id 是 6 位端口，合法取值 0..63，不只是 0..15★
      //   golden 的 maskFlushReq.wvec = (64'h1 << id)[15:0]，id>=16 时是全 0；
      //   若激励只给 0..15，「只比低 4 位」的写法在 UT 里永远看不出来。
      //   这里留 1/32 的越界 id，把那条边界挪进仿真可见范围。
      if ($urandom_range(0, 31) == 0) pick = $urandom_range(16, 63);
      if ($urandom_range(0, 5) == 0) begin
        io_dcache_replay_resp_valid   <= 1'b1;
        io_dcache_replay_resp_bits_id <= 6'(pick);
      end else if ($urandom_range(0, 2) != 0) begin
        io_dcache_main_pipe_hit_resp_valid   <= 1'b1;
        io_dcache_main_pipe_hit_resp_bits_id <= 6'(pick);
        if (pick < 16) inflight_shadow[pick] <= 1'b0;
      end
      // golden 这拍发出的写请求进影子（两侧输出在比较窗口内恒等，窗口外也只是激励）
      if (g_io_dcache_req_valid && io_dcache_req_ready)
        inflight_shadow[g_io_dcache_req_bits_id[3:0]] <= 1'b1;

      // ---- 三路 forward ------------------------------------------------------
      io_forward_0_valid <= fill_done ? ($urandom_range(0,7) != 0) : 1'b1;
      io_forward_1_valid <= fill_done ? ($urandom_range(0,7) != 0) : 1'b1;
      io_forward_2_valid <= fill_done ? ($urandom_range(0,7) != 0) : 1'b1;
      io_forward_0_paddr <= mk_paddr(fb,  foff);
      io_forward_0_vaddr <= mk_vaddr(mk_paddr(fb,  foff),
                                     compare_open && ($urandom_range(0,255)==0));
      io_forward_1_paddr <= mk_paddr(fb1, $urandom_range(0,63));
      io_forward_1_vaddr <= mk_vaddr(mk_paddr(fb1, foff), 1'b0);
      io_forward_2_paddr <= mk_paddr(fb2, $urandom_range(0,63));
      io_forward_2_vaddr <= mk_vaddr(mk_paddr(fb2, foff), 1'b0);

      // ---- fence / 阈值 ------------------------------------------------------
      io_sqempty     <= ($urandom_range(0,3) != 0);
      io_flush_valid <= fill_done ? ($urandom_range(0,255) == 0) : 1'b0;
      io_force_write <= fill_done ? ($urandom_range(0,15)  == 0) : 1'b0;
      // ★G1 的 coh 超时门限是 CSR 可编程的★：不给小值这条路就永远跑不到
      //   （默认 1<<20 拍，200k 拍的 UT 一次都不会超时）。这里按拍数分桶随机。
      if (fill_done && $urandom_range(0, 63) == 0)
        io_csrCtrl_sbuffer_timeout <= (mode == 3) ? 22'($urandom_range(1, 40))
                                                  : 22'($urandom_range(1, 4000));

      // ---- difftest 侧输入：纯观测量，直接随机（它们只喂 bore 总线）----------
      io_diffStore_diffInfo_0_uop_pc          <= 50'({$urandom(),$urandom()});
      io_diffStore_diffInfo_0_uop_fuType      <= 35'({$urandom(),$urandom()});
      io_diffStore_diffInfo_0_uop_fuOpType    <= 9'($urandom());
      io_diffStore_diffInfo_0_uop_vpu_nf      <= 3'($urandom());
      io_diffStore_diffInfo_0_uop_vpu_veew    <= 2'($urandom());
      io_diffStore_diffInfo_0_uop_robIdx_value<= 8'($urandom());
      io_diffStore_diffInfo_0_offset          <= 6'($urandom());
      io_diffStore_diffInfo_1_uop_pc          <= 50'({$urandom(),$urandom()});
      io_diffStore_diffInfo_1_uop_fuType      <= 35'({$urandom(),$urandom()});
      io_diffStore_diffInfo_1_uop_fuOpType    <= 9'($urandom());
      io_diffStore_diffInfo_1_uop_vpu_nf      <= 3'($urandom());
      io_diffStore_diffInfo_1_uop_vpu_veew    <= 2'($urandom());
      io_diffStore_diffInfo_1_uop_robIdx_value<= 8'($urandom());
      io_diffStore_diffInfo_1_offset          <= 6'($urandom());
      io_diffStore_pmaStore_0_valid           <= ($urandom_range(0,1) == 0);
      io_diffStore_pmaStore_0_bits_data       <= {$urandom(),$urandom(),$urandom(),$urandom()};
      io_diffStore_pmaStore_0_bits_mask       <= 16'($urandom());
      io_diffStore_pmaStore_0_bits_addr       <= 48'({$urandom(),$urandom()});
      io_diffStore_pmaStore_0_bits_wline      <= 1'($urandom());
      io_diffStore_pmaStore_0_bits_vecValid   <= ($urandom_range(0,3) != 0);
      io_diffStore_pmaStore_1_valid           <= ($urandom_range(0,1) == 0);
      io_diffStore_pmaStore_1_bits_data       <= {$urandom(),$urandom(),$urandom(),$urandom()};
      io_diffStore_pmaStore_1_bits_mask       <= 16'($urandom());
      io_diffStore_pmaStore_1_bits_addr       <= 48'({$urandom(),$urandom()});
      io_diffStore_pmaStore_1_bits_wline      <= 1'($urandom());
      io_diffStore_pmaStore_1_bits_vecValid   <= ($urandom_range(0,3) != 0);
      io_diffStore_ncStore_valid              <= ($urandom_range(0,1) == 0);
      io_diffStore_ncStore_bits_addr          <= 48'({$urandom(),$urandom()});
      io_diffStore_ncStore_bits_data          <= {$urandom(),$urandom()};
      io_diffStore_ncStore_bits_mask          <= 8'($urandom());
      io_diffStore_ncStore_bits_memBackTypeMM <= 1'($urandom());
    end
  end

  // ---------------------------------------------------------------------------
  //  阶段推进 + 覆盖累计
  // ---------------------------------------------------------------------------
  always @(posedge clk) if (!rst) begin
    cyc <= cyc + 1;
    if (fill_done && cyc % MODE_LEN == 0) begin
      mode      <= $urandom_range(0, 3);
      mode_nblk <= ($urandom_range(0, 3) == 2) ? 6 : NBLK;
    end
    if (diag_cmp_now && cyc >= 2) compare_open <= 1'b1;
    if (!fill_done && !diag_cmp_now) begin
      // 填充完成判据 = 观测到 16 条 entry 全 valid（io_sbFull），此后再跑 SETTLE 拍
      // 让 s1 逐出寄存器/forward 候选寄存器都被真正写过一次。
      if (g_io_sbFull && fill_cycle == 0) fill_cycle <= cyc;
      if (fill_cycle != 0) begin
        if (settle_cnt == SETTLE) begin fill_done <= 1'b1; compare_open <= 1'b1; end
        else settle_cnt <= settle_cnt + 1;
      end
      if (cyc > FILL_MAX && fill_cycle == 0) begin
        $display("FATAL: 填充阶段 %0d 拍内未观测到 io_sbFull —— 暖机窗口没建立起来", FILL_MAX);
        $display("TEST FAILED");
        $finish;
      end
    end
    if (compare_open) begin
      cov_in_fire     += (g_io_in_0_ready & io_in_0_valid) + (g_io_in_1_ready & io_in_1_valid);
      cov_merge       += g_io_perf_2_value;
      cov_alloc       += g_io_perf_3_value;
      cov_req_fire    += g_io_perf_5_value;
      cov_hit         += g_io_perf_9_value;
      cov_replay      += g_io_perf_10_value;
      cov_cohto       += g_io_perf_11_value;
      cov_idle        += g_io_perf_6_value;
      cov_drain_sb    += g_io_perf_7_value;
      cov_replace     += g_io_perf_8_value;
      cov_minv        += g_io_forward_0_matchInvalid + g_io_forward_1_matchInvalid
                       + g_io_forward_2_matchInvalid;
      cov_sbfull      += g_io_sbFull;
      cov_flush_empty += g_io_flush_empty;
      cov_fwd_hit     += (|{g_io_forward_0_forwardMask_0, g_io_forward_1_forwardMask_0,
                            g_io_forward_2_forwardMask_0});
      cov_nc_store    += g_gatewayIn_packed_52_bore[324];
      cov_pma_store   += g_gatewayIn_packed_50_bore[324] + g_gatewayIn_packed_51_bore[324];
      cov_oob_id      += (io_dcache_main_pipe_hit_resp_valid
                          && io_dcache_main_pipe_hit_resp_bits_id >= 6'd16);
      cov_sametag_alias += (io_in_0_valid && io_in_1_valid
                            && io_in_0_bits_vecValid && io_in_1_bits_vecValid
                            && g_io_in_0_ready && g_io_in_1_ready
                            && io_in_0_bits_addr[47:6] == io_in_1_bits_addr[47:6]
                            && io_in_0_bits_vaddr[49:6] != io_in_1_bits_vaddr[49:6]);
    end
  end

  // ---------------------------------------------------------------------------
  //  跑程控制与收尾判据
  // ---------------------------------------------------------------------------
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    diag_cmp_now = $test$plusargs("diag_cmp_now");
    if (diag_cmp_now)
      $display("*** DIAGNOSTIC MODE (+diag_cmp_now)：跳过暖机，本次运行不构成验收 ***");
    rst = 1'b1;
    repeat (20) @(posedge clk);
    rst = 1'b0;
    wait (cyc >= NCYCLES);
    $display("=== Sbuffer UT: cycles=%0d checks=%0d errors=%0d fill_cycle=%0d ===",
             cyc, checks, errors, fill_cycle);
    $display("COV in_fire=%0d merge=%0d alloc=%0d req_fire=%0d hit=%0d replay=%0d",
             cov_in_fire, cov_merge, cov_alloc, cov_req_fire, cov_hit, cov_replay);
    $display("COV cohto=%0d idle=%0d drain_sb=%0d replace=%0d matchInvalid=%0d sbFull=%0d",
             cov_cohto, cov_idle, cov_drain_sb, cov_replace, cov_minv, cov_sbfull);
    $display("COV flush_empty=%0d fwd_hit=%0d nc_store=%0d pma_store=%0d oob_id=%0d sametag_alias=%0d",
             cov_flush_empty, cov_fwd_hit, cov_nc_store, cov_pma_store, cov_oob_id,
             cov_sametag_alias);
    // 覆盖闸：任何一项为 0 就说明这条路径整轮没走到，errors=0 证明不了它
    if (diag_cmp_now)        begin $display("TEST FAILED (diagnostic mode, 不是验收)"); $finish; end
    if (checks == 0)         begin $display("TEST FAILED: checks==0"); $finish; end
    if (fill_cycle == 0)     begin $display("TEST FAILED: 暖机未完成"); $finish; end
    if (cov_merge == 0 || cov_alloc == 0 || cov_req_fire == 0 || cov_hit == 0
        || cov_replay == 0 || cov_cohto == 0 || cov_replace == 0 || cov_drain_sb == 0
        || cov_minv == 0 || cov_sbfull == 0 || cov_fwd_hit == 0
        || cov_nc_store == 0 || cov_pma_store == 0 || cov_oob_id == 0
        || cov_sametag_alias == 0) begin
      $display("TEST FAILED: 覆盖闸有为 0 的项（见上面 COV 行）");
      $finish;
    end
    if (diag_cmp_now)     $display("TEST FAILED (diagnostic mode, 不是验收)");
    else if (errors == 0) $display("TEST PASSED");
    else                  $display("TEST FAILED");
    $finish;
  end

  // ---- 逐拍比对：golden 的每一个输出端口都在表里，一个不许少 ----
  task automatic cmp(input string nm,
                     input logic [656:0] g, input logic [656:0] i);
    checks++;
    if (g !== i) begin
      errors++;
      if (errors <= 20)
        $display("MISMATCH cyc=%0d %s golden=%h impl=%h", cyc, nm, g, i);
    end
  endtask

  always @(posedge clk) if (!rst && compare_open) begin
    cmp("io_in_0_ready", 657'(g_io_in_0_ready), 657'(i_io_in_0_ready));
    cmp("io_in_1_ready", 657'(g_io_in_1_ready), 657'(i_io_in_1_ready));
    cmp("io_dcache_req_valid", 657'(g_io_dcache_req_valid), 657'(i_io_dcache_req_valid));
    cmp("io_dcache_req_bits_vaddr", 657'(g_io_dcache_req_bits_vaddr), 657'(i_io_dcache_req_bits_vaddr));
    cmp("io_dcache_req_bits_addr", 657'(g_io_dcache_req_bits_addr), 657'(i_io_dcache_req_bits_addr));
    cmp("io_dcache_req_bits_data", 657'(g_io_dcache_req_bits_data), 657'(i_io_dcache_req_bits_data));
    cmp("io_dcache_req_bits_mask", 657'(g_io_dcache_req_bits_mask), 657'(i_io_dcache_req_bits_mask));
    cmp("io_dcache_req_bits_id", 657'(g_io_dcache_req_bits_id), 657'(i_io_dcache_req_bits_id));
    cmp("io_forward_0_forwardMask_0", 657'(g_io_forward_0_forwardMask_0), 657'(i_io_forward_0_forwardMask_0));
    cmp("io_forward_0_forwardMask_1", 657'(g_io_forward_0_forwardMask_1), 657'(i_io_forward_0_forwardMask_1));
    cmp("io_forward_0_forwardMask_2", 657'(g_io_forward_0_forwardMask_2), 657'(i_io_forward_0_forwardMask_2));
    cmp("io_forward_0_forwardMask_3", 657'(g_io_forward_0_forwardMask_3), 657'(i_io_forward_0_forwardMask_3));
    cmp("io_forward_0_forwardMask_4", 657'(g_io_forward_0_forwardMask_4), 657'(i_io_forward_0_forwardMask_4));
    cmp("io_forward_0_forwardMask_5", 657'(g_io_forward_0_forwardMask_5), 657'(i_io_forward_0_forwardMask_5));
    cmp("io_forward_0_forwardMask_6", 657'(g_io_forward_0_forwardMask_6), 657'(i_io_forward_0_forwardMask_6));
    cmp("io_forward_0_forwardMask_7", 657'(g_io_forward_0_forwardMask_7), 657'(i_io_forward_0_forwardMask_7));
    cmp("io_forward_0_forwardMask_8", 657'(g_io_forward_0_forwardMask_8), 657'(i_io_forward_0_forwardMask_8));
    cmp("io_forward_0_forwardMask_9", 657'(g_io_forward_0_forwardMask_9), 657'(i_io_forward_0_forwardMask_9));
    cmp("io_forward_0_forwardMask_10", 657'(g_io_forward_0_forwardMask_10), 657'(i_io_forward_0_forwardMask_10));
    cmp("io_forward_0_forwardMask_11", 657'(g_io_forward_0_forwardMask_11), 657'(i_io_forward_0_forwardMask_11));
    cmp("io_forward_0_forwardMask_12", 657'(g_io_forward_0_forwardMask_12), 657'(i_io_forward_0_forwardMask_12));
    cmp("io_forward_0_forwardMask_13", 657'(g_io_forward_0_forwardMask_13), 657'(i_io_forward_0_forwardMask_13));
    cmp("io_forward_0_forwardMask_14", 657'(g_io_forward_0_forwardMask_14), 657'(i_io_forward_0_forwardMask_14));
    cmp("io_forward_0_forwardMask_15", 657'(g_io_forward_0_forwardMask_15), 657'(i_io_forward_0_forwardMask_15));
    cmp("io_forward_0_forwardData_0", 657'(g_io_forward_0_forwardData_0), 657'(i_io_forward_0_forwardData_0));
    cmp("io_forward_0_forwardData_1", 657'(g_io_forward_0_forwardData_1), 657'(i_io_forward_0_forwardData_1));
    cmp("io_forward_0_forwardData_2", 657'(g_io_forward_0_forwardData_2), 657'(i_io_forward_0_forwardData_2));
    cmp("io_forward_0_forwardData_3", 657'(g_io_forward_0_forwardData_3), 657'(i_io_forward_0_forwardData_3));
    cmp("io_forward_0_forwardData_4", 657'(g_io_forward_0_forwardData_4), 657'(i_io_forward_0_forwardData_4));
    cmp("io_forward_0_forwardData_5", 657'(g_io_forward_0_forwardData_5), 657'(i_io_forward_0_forwardData_5));
    cmp("io_forward_0_forwardData_6", 657'(g_io_forward_0_forwardData_6), 657'(i_io_forward_0_forwardData_6));
    cmp("io_forward_0_forwardData_7", 657'(g_io_forward_0_forwardData_7), 657'(i_io_forward_0_forwardData_7));
    cmp("io_forward_0_forwardData_8", 657'(g_io_forward_0_forwardData_8), 657'(i_io_forward_0_forwardData_8));
    cmp("io_forward_0_forwardData_9", 657'(g_io_forward_0_forwardData_9), 657'(i_io_forward_0_forwardData_9));
    cmp("io_forward_0_forwardData_10", 657'(g_io_forward_0_forwardData_10), 657'(i_io_forward_0_forwardData_10));
    cmp("io_forward_0_forwardData_11", 657'(g_io_forward_0_forwardData_11), 657'(i_io_forward_0_forwardData_11));
    cmp("io_forward_0_forwardData_12", 657'(g_io_forward_0_forwardData_12), 657'(i_io_forward_0_forwardData_12));
    cmp("io_forward_0_forwardData_13", 657'(g_io_forward_0_forwardData_13), 657'(i_io_forward_0_forwardData_13));
    cmp("io_forward_0_forwardData_14", 657'(g_io_forward_0_forwardData_14), 657'(i_io_forward_0_forwardData_14));
    cmp("io_forward_0_forwardData_15", 657'(g_io_forward_0_forwardData_15), 657'(i_io_forward_0_forwardData_15));
    cmp("io_forward_0_matchInvalid", 657'(g_io_forward_0_matchInvalid), 657'(i_io_forward_0_matchInvalid));
    cmp("io_forward_1_forwardMask_0", 657'(g_io_forward_1_forwardMask_0), 657'(i_io_forward_1_forwardMask_0));
    cmp("io_forward_1_forwardMask_1", 657'(g_io_forward_1_forwardMask_1), 657'(i_io_forward_1_forwardMask_1));
    cmp("io_forward_1_forwardMask_2", 657'(g_io_forward_1_forwardMask_2), 657'(i_io_forward_1_forwardMask_2));
    cmp("io_forward_1_forwardMask_3", 657'(g_io_forward_1_forwardMask_3), 657'(i_io_forward_1_forwardMask_3));
    cmp("io_forward_1_forwardMask_4", 657'(g_io_forward_1_forwardMask_4), 657'(i_io_forward_1_forwardMask_4));
    cmp("io_forward_1_forwardMask_5", 657'(g_io_forward_1_forwardMask_5), 657'(i_io_forward_1_forwardMask_5));
    cmp("io_forward_1_forwardMask_6", 657'(g_io_forward_1_forwardMask_6), 657'(i_io_forward_1_forwardMask_6));
    cmp("io_forward_1_forwardMask_7", 657'(g_io_forward_1_forwardMask_7), 657'(i_io_forward_1_forwardMask_7));
    cmp("io_forward_1_forwardMask_8", 657'(g_io_forward_1_forwardMask_8), 657'(i_io_forward_1_forwardMask_8));
    cmp("io_forward_1_forwardMask_9", 657'(g_io_forward_1_forwardMask_9), 657'(i_io_forward_1_forwardMask_9));
    cmp("io_forward_1_forwardMask_10", 657'(g_io_forward_1_forwardMask_10), 657'(i_io_forward_1_forwardMask_10));
    cmp("io_forward_1_forwardMask_11", 657'(g_io_forward_1_forwardMask_11), 657'(i_io_forward_1_forwardMask_11));
    cmp("io_forward_1_forwardMask_12", 657'(g_io_forward_1_forwardMask_12), 657'(i_io_forward_1_forwardMask_12));
    cmp("io_forward_1_forwardMask_13", 657'(g_io_forward_1_forwardMask_13), 657'(i_io_forward_1_forwardMask_13));
    cmp("io_forward_1_forwardMask_14", 657'(g_io_forward_1_forwardMask_14), 657'(i_io_forward_1_forwardMask_14));
    cmp("io_forward_1_forwardMask_15", 657'(g_io_forward_1_forwardMask_15), 657'(i_io_forward_1_forwardMask_15));
    cmp("io_forward_1_forwardData_0", 657'(g_io_forward_1_forwardData_0), 657'(i_io_forward_1_forwardData_0));
    cmp("io_forward_1_forwardData_1", 657'(g_io_forward_1_forwardData_1), 657'(i_io_forward_1_forwardData_1));
    cmp("io_forward_1_forwardData_2", 657'(g_io_forward_1_forwardData_2), 657'(i_io_forward_1_forwardData_2));
    cmp("io_forward_1_forwardData_3", 657'(g_io_forward_1_forwardData_3), 657'(i_io_forward_1_forwardData_3));
    cmp("io_forward_1_forwardData_4", 657'(g_io_forward_1_forwardData_4), 657'(i_io_forward_1_forwardData_4));
    cmp("io_forward_1_forwardData_5", 657'(g_io_forward_1_forwardData_5), 657'(i_io_forward_1_forwardData_5));
    cmp("io_forward_1_forwardData_6", 657'(g_io_forward_1_forwardData_6), 657'(i_io_forward_1_forwardData_6));
    cmp("io_forward_1_forwardData_7", 657'(g_io_forward_1_forwardData_7), 657'(i_io_forward_1_forwardData_7));
    cmp("io_forward_1_forwardData_8", 657'(g_io_forward_1_forwardData_8), 657'(i_io_forward_1_forwardData_8));
    cmp("io_forward_1_forwardData_9", 657'(g_io_forward_1_forwardData_9), 657'(i_io_forward_1_forwardData_9));
    cmp("io_forward_1_forwardData_10", 657'(g_io_forward_1_forwardData_10), 657'(i_io_forward_1_forwardData_10));
    cmp("io_forward_1_forwardData_11", 657'(g_io_forward_1_forwardData_11), 657'(i_io_forward_1_forwardData_11));
    cmp("io_forward_1_forwardData_12", 657'(g_io_forward_1_forwardData_12), 657'(i_io_forward_1_forwardData_12));
    cmp("io_forward_1_forwardData_13", 657'(g_io_forward_1_forwardData_13), 657'(i_io_forward_1_forwardData_13));
    cmp("io_forward_1_forwardData_14", 657'(g_io_forward_1_forwardData_14), 657'(i_io_forward_1_forwardData_14));
    cmp("io_forward_1_forwardData_15", 657'(g_io_forward_1_forwardData_15), 657'(i_io_forward_1_forwardData_15));
    cmp("io_forward_1_matchInvalid", 657'(g_io_forward_1_matchInvalid), 657'(i_io_forward_1_matchInvalid));
    cmp("io_forward_2_forwardMask_0", 657'(g_io_forward_2_forwardMask_0), 657'(i_io_forward_2_forwardMask_0));
    cmp("io_forward_2_forwardMask_1", 657'(g_io_forward_2_forwardMask_1), 657'(i_io_forward_2_forwardMask_1));
    cmp("io_forward_2_forwardMask_2", 657'(g_io_forward_2_forwardMask_2), 657'(i_io_forward_2_forwardMask_2));
    cmp("io_forward_2_forwardMask_3", 657'(g_io_forward_2_forwardMask_3), 657'(i_io_forward_2_forwardMask_3));
    cmp("io_forward_2_forwardMask_4", 657'(g_io_forward_2_forwardMask_4), 657'(i_io_forward_2_forwardMask_4));
    cmp("io_forward_2_forwardMask_5", 657'(g_io_forward_2_forwardMask_5), 657'(i_io_forward_2_forwardMask_5));
    cmp("io_forward_2_forwardMask_6", 657'(g_io_forward_2_forwardMask_6), 657'(i_io_forward_2_forwardMask_6));
    cmp("io_forward_2_forwardMask_7", 657'(g_io_forward_2_forwardMask_7), 657'(i_io_forward_2_forwardMask_7));
    cmp("io_forward_2_forwardMask_8", 657'(g_io_forward_2_forwardMask_8), 657'(i_io_forward_2_forwardMask_8));
    cmp("io_forward_2_forwardMask_9", 657'(g_io_forward_2_forwardMask_9), 657'(i_io_forward_2_forwardMask_9));
    cmp("io_forward_2_forwardMask_10", 657'(g_io_forward_2_forwardMask_10), 657'(i_io_forward_2_forwardMask_10));
    cmp("io_forward_2_forwardMask_11", 657'(g_io_forward_2_forwardMask_11), 657'(i_io_forward_2_forwardMask_11));
    cmp("io_forward_2_forwardMask_12", 657'(g_io_forward_2_forwardMask_12), 657'(i_io_forward_2_forwardMask_12));
    cmp("io_forward_2_forwardMask_13", 657'(g_io_forward_2_forwardMask_13), 657'(i_io_forward_2_forwardMask_13));
    cmp("io_forward_2_forwardMask_14", 657'(g_io_forward_2_forwardMask_14), 657'(i_io_forward_2_forwardMask_14));
    cmp("io_forward_2_forwardMask_15", 657'(g_io_forward_2_forwardMask_15), 657'(i_io_forward_2_forwardMask_15));
    cmp("io_forward_2_forwardData_0", 657'(g_io_forward_2_forwardData_0), 657'(i_io_forward_2_forwardData_0));
    cmp("io_forward_2_forwardData_1", 657'(g_io_forward_2_forwardData_1), 657'(i_io_forward_2_forwardData_1));
    cmp("io_forward_2_forwardData_2", 657'(g_io_forward_2_forwardData_2), 657'(i_io_forward_2_forwardData_2));
    cmp("io_forward_2_forwardData_3", 657'(g_io_forward_2_forwardData_3), 657'(i_io_forward_2_forwardData_3));
    cmp("io_forward_2_forwardData_4", 657'(g_io_forward_2_forwardData_4), 657'(i_io_forward_2_forwardData_4));
    cmp("io_forward_2_forwardData_5", 657'(g_io_forward_2_forwardData_5), 657'(i_io_forward_2_forwardData_5));
    cmp("io_forward_2_forwardData_6", 657'(g_io_forward_2_forwardData_6), 657'(i_io_forward_2_forwardData_6));
    cmp("io_forward_2_forwardData_7", 657'(g_io_forward_2_forwardData_7), 657'(i_io_forward_2_forwardData_7));
    cmp("io_forward_2_forwardData_8", 657'(g_io_forward_2_forwardData_8), 657'(i_io_forward_2_forwardData_8));
    cmp("io_forward_2_forwardData_9", 657'(g_io_forward_2_forwardData_9), 657'(i_io_forward_2_forwardData_9));
    cmp("io_forward_2_forwardData_10", 657'(g_io_forward_2_forwardData_10), 657'(i_io_forward_2_forwardData_10));
    cmp("io_forward_2_forwardData_11", 657'(g_io_forward_2_forwardData_11), 657'(i_io_forward_2_forwardData_11));
    cmp("io_forward_2_forwardData_12", 657'(g_io_forward_2_forwardData_12), 657'(i_io_forward_2_forwardData_12));
    cmp("io_forward_2_forwardData_13", 657'(g_io_forward_2_forwardData_13), 657'(i_io_forward_2_forwardData_13));
    cmp("io_forward_2_forwardData_14", 657'(g_io_forward_2_forwardData_14), 657'(i_io_forward_2_forwardData_14));
    cmp("io_forward_2_forwardData_15", 657'(g_io_forward_2_forwardData_15), 657'(i_io_forward_2_forwardData_15));
    cmp("io_forward_2_matchInvalid", 657'(g_io_forward_2_matchInvalid), 657'(i_io_forward_2_matchInvalid));
    cmp("io_sbempty", 657'(g_io_sbempty), 657'(i_io_sbempty));
    cmp("io_sbFull", 657'(g_io_sbFull), 657'(i_io_sbFull));
    cmp("io_flush_empty", 657'(g_io_flush_empty), 657'(i_io_flush_empty));
    cmp("io_perf_0_value", 657'(g_io_perf_0_value), 657'(i_io_perf_0_value));
    cmp("io_perf_1_value", 657'(g_io_perf_1_value), 657'(i_io_perf_1_value));
    cmp("io_perf_2_value", 657'(g_io_perf_2_value), 657'(i_io_perf_2_value));
    cmp("io_perf_3_value", 657'(g_io_perf_3_value), 657'(i_io_perf_3_value));
    cmp("io_perf_4_value", 657'(g_io_perf_4_value), 657'(i_io_perf_4_value));
    cmp("io_perf_5_value", 657'(g_io_perf_5_value), 657'(i_io_perf_5_value));
    cmp("io_perf_6_value", 657'(g_io_perf_6_value), 657'(i_io_perf_6_value));
    cmp("io_perf_7_value", 657'(g_io_perf_7_value), 657'(i_io_perf_7_value));
    cmp("io_perf_8_value", 657'(g_io_perf_8_value), 657'(i_io_perf_8_value));
    cmp("io_perf_9_value", 657'(g_io_perf_9_value), 657'(i_io_perf_9_value));
    cmp("io_perf_10_value", 657'(g_io_perf_10_value), 657'(i_io_perf_10_value));
    cmp("io_perf_11_value", 657'(g_io_perf_11_value), 657'(i_io_perf_11_value));
    cmp("io_perf_12_value", 657'(g_io_perf_12_value), 657'(i_io_perf_12_value));
    cmp("io_perf_13_value", 657'(g_io_perf_13_value), 657'(i_io_perf_13_value));
    cmp("io_perf_14_value", 657'(g_io_perf_14_value), 657'(i_io_perf_14_value));
    cmp("io_perf_15_value", 657'(g_io_perf_15_value), 657'(i_io_perf_15_value));
    cmp("gatewayIn_packed_49_bore", 657'(g_gatewayIn_packed_49_bore), 657'(i_gatewayIn_packed_49_bore));
    cmp("gatewayIn_packed_50_bore", 657'(g_gatewayIn_packed_50_bore), 657'(i_gatewayIn_packed_50_bore));
    cmp("gatewayIn_packed_51_bore", 657'(g_gatewayIn_packed_51_bore), 657'(i_gatewayIn_packed_51_bore));
    cmp("gatewayIn_packed_52_bore", 657'(g_gatewayIn_packed_52_bore), 657'(i_gatewayIn_packed_52_bore));
  end

endmodule
