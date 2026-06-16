// 自动生成：scripts/gen_missqueue.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_req_valid;
  logic [3:0] io_req_bits_source;
  logic [2:0] io_req_bits_pf_source;
  logic [4:0] io_req_bits_cmd;
  logic [47:0] io_req_bits_addr;
  logic [49:0] io_req_bits_vaddr;
  logic io_req_bits_full_overwrite;
  logic [2:0] io_req_bits_word_idx;
  logic [127:0] io_req_bits_amo_data;
  logic [15:0] io_req_bits_amo_mask;
  logic [127:0] io_req_bits_amo_cmp;
  logic [1:0] io_req_bits_req_coh_state;
  logic [5:0] io_req_bits_id;
  logic io_req_bits_isBtoT;
  logic [3:0] io_req_bits_occupy_way;
  logic io_req_bits_cancel;
  logic [511:0] io_req_bits_store_data;
  logic [63:0] io_req_bits_store_mask;
  logic io_cmo_req_valid;
  logic [2:0] io_cmo_req_bits_opcode;
  logic [63:0] io_cmo_req_bits_address;
  logic io_cmo_resp_ready;
  logic [3:0] io_queryMQ_0_req_bits_source;
  logic [47:0] io_queryMQ_0_req_bits_addr;
  logic [49:0] io_queryMQ_0_req_bits_vaddr;
  logic [3:0] io_queryMQ_1_req_bits_source;
  logic [47:0] io_queryMQ_1_req_bits_addr;
  logic [49:0] io_queryMQ_1_req_bits_vaddr;
  logic [3:0] io_queryMQ_2_req_bits_source;
  logic [47:0] io_queryMQ_2_req_bits_addr;
  logic [49:0] io_queryMQ_2_req_bits_vaddr;
  logic [3:0] io_queryMQ_3_req_bits_source;
  logic [47:0] io_queryMQ_3_req_bits_addr;
  logic [49:0] io_queryMQ_3_req_bits_vaddr;
  logic io_mem_acquire_ready;
  logic io_mem_grant_valid;
  logic [3:0] io_mem_grant_bits_opcode;
  logic [1:0] io_mem_grant_bits_param;
  logic [2:0] io_mem_grant_bits_size;
  logic [5:0] io_mem_grant_bits_source;
  logic [9:0] io_mem_grant_bits_sink;
  logic io_mem_grant_bits_denied;
  logic [255:0] io_mem_grant_bits_data;
  logic io_mem_grant_bits_corrupt;
  logic io_mem_finish_ready;
  logic io_l2_hint_valid;
  logic [3:0] io_l2_hint_bits_sourceId;
  logic io_main_pipe_req_ready;
  logic io_main_pipe_resp_valid;
  logic [3:0] io_main_pipe_resp_bits_miss_id;
  logic io_main_pipe_resp_bits_ack_miss_queue;
  logic io_mainpipe_info_s2_valid;
  logic [3:0] io_mainpipe_info_s2_miss_id;
  logic io_mainpipe_info_s2_replay_to_mq;
  logic io_mainpipe_info_s2_evict_BtoT_way;
  logic [3:0] io_mainpipe_info_s2_next_evict_way;
  logic io_mainpipe_info_s3_valid;
  logic [3:0] io_mainpipe_info_s3_miss_id;
  logic io_mainpipe_info_s3_refill_resp;
  logic [47:0] io_probe_req_bits_addr;
  logic [49:0] io_probe_req_bits_vaddr;
  logic [47:0] io_replace_req_bits_addr;
  logic [49:0] io_replace_req_bits_vaddr;
  logic [7:0] io_evict_set;
  logic [7:0] io_occupy_set_0;
  logic [7:0] io_occupy_set_1;
  logic [7:0] io_occupy_set_2;
  logic io_wbq_block_miss_req;
  logic io_forward_0_valid;
  logic [3:0] io_forward_0_mshrid;
  logic [47:0] io_forward_0_paddr;
  logic io_forward_1_valid;
  logic [3:0] io_forward_1_mshrid;
  logic [47:0] io_forward_1_paddr;
  logic io_forward_2_valid;
  logic [3:0] io_forward_2_mshrid;
  logic [47:0] io_forward_2_paddr;
  logic io_l2_pf_store_only;
  logic io_lqEmpty;
  logic io_wfi_wfiReq;
  logic io_debugTopDown_robHeadVaddr_valid;
  logic [49:0] io_debugTopDown_robHeadVaddr_bits;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire [3:0] g_io_resp_id;
  wire [3:0] i_io_resp_id;
  wire g_io_resp_handled;
  wire i_io_resp_handled;
  wire g_io_resp_merged;
  wire i_io_resp_merged;
  wire g_io_cmo_req_ready;
  wire i_io_cmo_req_ready;
  wire g_io_cmo_resp_valid;
  wire i_io_cmo_resp_valid;
  wire g_io_cmo_resp_bits_nderr;
  wire i_io_cmo_resp_bits_nderr;
  wire g_io_queryMQ_0_ready;
  wire i_io_queryMQ_0_ready;
  wire g_io_queryMQ_1_ready;
  wire i_io_queryMQ_1_ready;
  wire g_io_queryMQ_2_ready;
  wire i_io_queryMQ_2_ready;
  wire g_io_queryMQ_3_ready;
  wire i_io_queryMQ_3_ready;
  wire g_io_mem_acquire_valid;
  wire i_io_mem_acquire_valid;
  wire [3:0] g_io_mem_acquire_bits_opcode;
  wire [3:0] i_io_mem_acquire_bits_opcode;
  wire [2:0] g_io_mem_acquire_bits_param;
  wire [2:0] i_io_mem_acquire_bits_param;
  wire [2:0] g_io_mem_acquire_bits_size;
  wire [2:0] i_io_mem_acquire_bits_size;
  wire [5:0] g_io_mem_acquire_bits_source;
  wire [5:0] i_io_mem_acquire_bits_source;
  wire [47:0] g_io_mem_acquire_bits_address;
  wire [47:0] i_io_mem_acquire_bits_address;
  wire [1:0] g_io_mem_acquire_bits_user_alias;
  wire [1:0] i_io_mem_acquire_bits_user_alias;
  wire [43:0] g_io_mem_acquire_bits_user_vaddr;
  wire [43:0] i_io_mem_acquire_bits_user_vaddr;
  wire [4:0] g_io_mem_acquire_bits_user_reqSource;
  wire [4:0] i_io_mem_acquire_bits_user_reqSource;
  wire g_io_mem_acquire_bits_user_needHint;
  wire i_io_mem_acquire_bits_user_needHint;
  wire g_io_mem_acquire_bits_echo_isKeyword;
  wire i_io_mem_acquire_bits_echo_isKeyword;
  wire [31:0] g_io_mem_acquire_bits_mask;
  wire [31:0] i_io_mem_acquire_bits_mask;
  wire g_io_mem_grant_ready;
  wire i_io_mem_grant_ready;
  wire g_io_mem_finish_valid;
  wire i_io_mem_finish_valid;
  wire [9:0] g_io_mem_finish_bits_sink;
  wire [9:0] i_io_mem_finish_bits_sink;
  wire g_io_main_pipe_req_valid;
  wire i_io_main_pipe_req_valid;
  wire g_io_main_pipe_req_bits_miss;
  wire i_io_main_pipe_req_bits_miss;
  wire [3:0] g_io_main_pipe_req_bits_miss_id;
  wire [3:0] i_io_main_pipe_req_bits_miss_id;
  wire [3:0] g_io_main_pipe_req_bits_occupy_way;
  wire [3:0] i_io_main_pipe_req_bits_occupy_way;
  wire g_io_main_pipe_req_bits_miss_fail_cause_evict_btot;
  wire i_io_main_pipe_req_bits_miss_fail_cause_evict_btot;
  wire [3:0] g_io_main_pipe_req_bits_source;
  wire [3:0] i_io_main_pipe_req_bits_source;
  wire [4:0] g_io_main_pipe_req_bits_cmd;
  wire [4:0] i_io_main_pipe_req_bits_cmd;
  wire [49:0] g_io_main_pipe_req_bits_vaddr;
  wire [49:0] i_io_main_pipe_req_bits_vaddr;
  wire [47:0] g_io_main_pipe_req_bits_addr;
  wire [47:0] i_io_main_pipe_req_bits_addr;
  wire [2:0] g_io_main_pipe_req_bits_word_idx;
  wire [2:0] i_io_main_pipe_req_bits_word_idx;
  wire [127:0] g_io_main_pipe_req_bits_amo_data;
  wire [127:0] i_io_main_pipe_req_bits_amo_data;
  wire [15:0] g_io_main_pipe_req_bits_amo_mask;
  wire [15:0] i_io_main_pipe_req_bits_amo_mask;
  wire [127:0] g_io_main_pipe_req_bits_amo_cmp;
  wire [127:0] i_io_main_pipe_req_bits_amo_cmp;
  wire [2:0] g_io_main_pipe_req_bits_pf_source;
  wire [2:0] i_io_main_pipe_req_bits_pf_source;
  wire g_io_main_pipe_req_bits_access;
  wire i_io_main_pipe_req_bits_access;
  wire [5:0] g_io_main_pipe_req_bits_id;
  wire [5:0] i_io_main_pipe_req_bits_id;
  wire g_io_refill_info_valid;
  wire i_io_refill_info_valid;
  wire [511:0] g_io_refill_info_bits_store_data;
  wire [511:0] i_io_refill_info_bits_store_data;
  wire [63:0] g_io_refill_info_bits_store_mask;
  wire [63:0] i_io_refill_info_bits_store_mask;
  wire [1:0] g_io_refill_info_bits_miss_param;
  wire [1:0] i_io_refill_info_bits_miss_param;
  wire g_io_refill_info_bits_error;
  wire i_io_refill_info_bits_error;
  wire g_io_probe_block;
  wire i_io_probe_block;
  wire g_io_replace_block;
  wire i_io_replace_block;
  wire [3:0] g_io_btot_ways_for_set;
  wire [3:0] i_io_btot_ways_for_set;
  wire g_io_occupy_fail_0;
  wire i_io_occupy_fail_0;
  wire g_io_occupy_fail_1;
  wire i_io_occupy_fail_1;
  wire g_io_occupy_fail_2;
  wire i_io_occupy_fail_2;
  wire g_io_forward_0_forward_mshr;
  wire i_io_forward_0_forward_mshr;
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
  wire g_io_forward_0_forward_result_valid;
  wire i_io_forward_0_forward_result_valid;
  wire g_io_forward_0_corrupt;
  wire i_io_forward_0_corrupt;
  wire g_io_forward_1_forward_mshr;
  wire i_io_forward_1_forward_mshr;
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
  wire g_io_forward_1_forward_result_valid;
  wire i_io_forward_1_forward_result_valid;
  wire g_io_forward_1_corrupt;
  wire i_io_forward_1_corrupt;
  wire g_io_forward_2_forward_mshr;
  wire i_io_forward_2_forward_mshr;
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
  wire g_io_forward_2_forward_result_valid;
  wire i_io_forward_2_forward_result_valid;
  wire g_io_forward_2_corrupt;
  wire i_io_forward_2_corrupt;
  wire g_io_prefetch_info_naive_late_miss_prefetch;
  wire i_io_prefetch_info_naive_late_miss_prefetch;
  wire g_io_prefetch_info_fdp_late_miss_prefetch;
  wire i_io_prefetch_info_fdp_late_miss_prefetch;
  wire g_io_prefetch_info_fdp_prefetch_monitor_cnt;
  wire i_io_prefetch_info_fdp_prefetch_monitor_cnt;
  wire g_io_prefetch_info_fdp_total_prefetch;
  wire i_io_prefetch_info_fdp_total_prefetch;
  wire g_io_wfi_wfiSafe;
  wire i_io_wfi_wfiSafe;
  wire g_io_debugTopDown_robHeadMissInDCache;
  wire i_io_debugTopDown_robHeadMissInDCache;
  wire g_io_l1Miss;
  wire i_io_l1Miss;
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
  MissQueue    u_g (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_source(io_req_bits_source), .io_req_bits_pf_source(io_req_bits_pf_source), .io_req_bits_cmd(io_req_bits_cmd), .io_req_bits_addr(io_req_bits_addr), .io_req_bits_vaddr(io_req_bits_vaddr), .io_req_bits_full_overwrite(io_req_bits_full_overwrite), .io_req_bits_word_idx(io_req_bits_word_idx), .io_req_bits_amo_data(io_req_bits_amo_data), .io_req_bits_amo_mask(io_req_bits_amo_mask), .io_req_bits_amo_cmp(io_req_bits_amo_cmp), .io_req_bits_req_coh_state(io_req_bits_req_coh_state), .io_req_bits_id(io_req_bits_id), .io_req_bits_isBtoT(io_req_bits_isBtoT), .io_req_bits_occupy_way(io_req_bits_occupy_way), .io_req_bits_cancel(io_req_bits_cancel), .io_req_bits_store_data(io_req_bits_store_data), .io_req_bits_store_mask(io_req_bits_store_mask), .io_cmo_req_valid(io_cmo_req_valid), .io_cmo_req_bits_opcode(io_cmo_req_bits_opcode), .io_cmo_req_bits_address(io_cmo_req_bits_address), .io_cmo_resp_ready(io_cmo_resp_ready), .io_queryMQ_0_req_bits_source(io_queryMQ_0_req_bits_source), .io_queryMQ_0_req_bits_addr(io_queryMQ_0_req_bits_addr), .io_queryMQ_0_req_bits_vaddr(io_queryMQ_0_req_bits_vaddr), .io_queryMQ_1_req_bits_source(io_queryMQ_1_req_bits_source), .io_queryMQ_1_req_bits_addr(io_queryMQ_1_req_bits_addr), .io_queryMQ_1_req_bits_vaddr(io_queryMQ_1_req_bits_vaddr), .io_queryMQ_2_req_bits_source(io_queryMQ_2_req_bits_source), .io_queryMQ_2_req_bits_addr(io_queryMQ_2_req_bits_addr), .io_queryMQ_2_req_bits_vaddr(io_queryMQ_2_req_bits_vaddr), .io_queryMQ_3_req_bits_source(io_queryMQ_3_req_bits_source), .io_queryMQ_3_req_bits_addr(io_queryMQ_3_req_bits_addr), .io_queryMQ_3_req_bits_vaddr(io_queryMQ_3_req_bits_vaddr), .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode), .io_mem_grant_bits_param(io_mem_grant_bits_param), .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_mem_grant_bits_sink(io_mem_grant_bits_sink), .io_mem_grant_bits_denied(io_mem_grant_bits_denied), .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt), .io_mem_finish_ready(io_mem_finish_ready), .io_l2_hint_valid(io_l2_hint_valid), .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId), .io_main_pipe_req_ready(io_main_pipe_req_ready), .io_main_pipe_resp_valid(io_main_pipe_resp_valid), .io_main_pipe_resp_bits_miss_id(io_main_pipe_resp_bits_miss_id), .io_main_pipe_resp_bits_ack_miss_queue(io_main_pipe_resp_bits_ack_miss_queue), .io_mainpipe_info_s2_valid(io_mainpipe_info_s2_valid), .io_mainpipe_info_s2_miss_id(io_mainpipe_info_s2_miss_id), .io_mainpipe_info_s2_replay_to_mq(io_mainpipe_info_s2_replay_to_mq), .io_mainpipe_info_s2_evict_BtoT_way(io_mainpipe_info_s2_evict_BtoT_way), .io_mainpipe_info_s2_next_evict_way(io_mainpipe_info_s2_next_evict_way), .io_mainpipe_info_s3_valid(io_mainpipe_info_s3_valid), .io_mainpipe_info_s3_miss_id(io_mainpipe_info_s3_miss_id), .io_mainpipe_info_s3_refill_resp(io_mainpipe_info_s3_refill_resp), .io_probe_req_bits_addr(io_probe_req_bits_addr), .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr), .io_replace_req_bits_addr(io_replace_req_bits_addr), .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr), .io_evict_set(io_evict_set), .io_occupy_set_0(io_occupy_set_0), .io_occupy_set_1(io_occupy_set_1), .io_occupy_set_2(io_occupy_set_2), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_forward_0_valid(io_forward_0_valid), .io_forward_0_mshrid(io_forward_0_mshrid), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_1_mshrid(io_forward_1_mshrid), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_2_valid(io_forward_2_valid), .io_forward_2_mshrid(io_forward_2_mshrid), .io_forward_2_paddr(io_forward_2_paddr), .io_l2_pf_store_only(io_l2_pf_store_only), .io_lqEmpty(io_lqEmpty), .io_wfi_wfiReq(io_wfi_wfiReq), .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid), .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits), .io_req_ready(g_io_req_ready), .io_resp_id(g_io_resp_id), .io_resp_handled(g_io_resp_handled), .io_resp_merged(g_io_resp_merged), .io_cmo_req_ready(g_io_cmo_req_ready), .io_cmo_resp_valid(g_io_cmo_resp_valid), .io_cmo_resp_bits_nderr(g_io_cmo_resp_bits_nderr), .io_queryMQ_0_ready(g_io_queryMQ_0_ready), .io_queryMQ_1_ready(g_io_queryMQ_1_ready), .io_queryMQ_2_ready(g_io_queryMQ_2_ready), .io_queryMQ_3_ready(g_io_queryMQ_3_ready), .io_mem_acquire_valid(g_io_mem_acquire_valid), .io_mem_acquire_bits_opcode(g_io_mem_acquire_bits_opcode), .io_mem_acquire_bits_param(g_io_mem_acquire_bits_param), .io_mem_acquire_bits_size(g_io_mem_acquire_bits_size), .io_mem_acquire_bits_source(g_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(g_io_mem_acquire_bits_address), .io_mem_acquire_bits_user_alias(g_io_mem_acquire_bits_user_alias), .io_mem_acquire_bits_user_vaddr(g_io_mem_acquire_bits_user_vaddr), .io_mem_acquire_bits_user_reqSource(g_io_mem_acquire_bits_user_reqSource), .io_mem_acquire_bits_user_needHint(g_io_mem_acquire_bits_user_needHint), .io_mem_acquire_bits_echo_isKeyword(g_io_mem_acquire_bits_echo_isKeyword), .io_mem_acquire_bits_mask(g_io_mem_acquire_bits_mask), .io_mem_grant_ready(g_io_mem_grant_ready), .io_mem_finish_valid(g_io_mem_finish_valid), .io_mem_finish_bits_sink(g_io_mem_finish_bits_sink), .io_main_pipe_req_valid(g_io_main_pipe_req_valid), .io_main_pipe_req_bits_miss(g_io_main_pipe_req_bits_miss), .io_main_pipe_req_bits_miss_id(g_io_main_pipe_req_bits_miss_id), .io_main_pipe_req_bits_occupy_way(g_io_main_pipe_req_bits_occupy_way), .io_main_pipe_req_bits_miss_fail_cause_evict_btot(g_io_main_pipe_req_bits_miss_fail_cause_evict_btot), .io_main_pipe_req_bits_source(g_io_main_pipe_req_bits_source), .io_main_pipe_req_bits_cmd(g_io_main_pipe_req_bits_cmd), .io_main_pipe_req_bits_vaddr(g_io_main_pipe_req_bits_vaddr), .io_main_pipe_req_bits_addr(g_io_main_pipe_req_bits_addr), .io_main_pipe_req_bits_word_idx(g_io_main_pipe_req_bits_word_idx), .io_main_pipe_req_bits_amo_data(g_io_main_pipe_req_bits_amo_data), .io_main_pipe_req_bits_amo_mask(g_io_main_pipe_req_bits_amo_mask), .io_main_pipe_req_bits_amo_cmp(g_io_main_pipe_req_bits_amo_cmp), .io_main_pipe_req_bits_pf_source(g_io_main_pipe_req_bits_pf_source), .io_main_pipe_req_bits_access(g_io_main_pipe_req_bits_access), .io_main_pipe_req_bits_id(g_io_main_pipe_req_bits_id), .io_refill_info_valid(g_io_refill_info_valid), .io_refill_info_bits_store_data(g_io_refill_info_bits_store_data), .io_refill_info_bits_store_mask(g_io_refill_info_bits_store_mask), .io_refill_info_bits_miss_param(g_io_refill_info_bits_miss_param), .io_refill_info_bits_error(g_io_refill_info_bits_error), .io_probe_block(g_io_probe_block), .io_replace_block(g_io_replace_block), .io_btot_ways_for_set(g_io_btot_ways_for_set), .io_occupy_fail_0(g_io_occupy_fail_0), .io_occupy_fail_1(g_io_occupy_fail_1), .io_occupy_fail_2(g_io_occupy_fail_2), .io_forward_0_forward_mshr(g_io_forward_0_forward_mshr), .io_forward_0_forwardData_0(g_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(g_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(g_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(g_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(g_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(g_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(g_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(g_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(g_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(g_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(g_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(g_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(g_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(g_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(g_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(g_io_forward_0_forwardData_15), .io_forward_0_forward_result_valid(g_io_forward_0_forward_result_valid), .io_forward_0_corrupt(g_io_forward_0_corrupt), .io_forward_1_forward_mshr(g_io_forward_1_forward_mshr), .io_forward_1_forwardData_0(g_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(g_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(g_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(g_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(g_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(g_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(g_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(g_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(g_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(g_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(g_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(g_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(g_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(g_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(g_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(g_io_forward_1_forwardData_15), .io_forward_1_forward_result_valid(g_io_forward_1_forward_result_valid), .io_forward_1_corrupt(g_io_forward_1_corrupt), .io_forward_2_forward_mshr(g_io_forward_2_forward_mshr), .io_forward_2_forwardData_0(g_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(g_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(g_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(g_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(g_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(g_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(g_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(g_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(g_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(g_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(g_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(g_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(g_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(g_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(g_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(g_io_forward_2_forwardData_15), .io_forward_2_forward_result_valid(g_io_forward_2_forward_result_valid), .io_forward_2_corrupt(g_io_forward_2_corrupt), .io_prefetch_info_naive_late_miss_prefetch(g_io_prefetch_info_naive_late_miss_prefetch), .io_prefetch_info_fdp_late_miss_prefetch(g_io_prefetch_info_fdp_late_miss_prefetch), .io_prefetch_info_fdp_prefetch_monitor_cnt(g_io_prefetch_info_fdp_prefetch_monitor_cnt), .io_prefetch_info_fdp_total_prefetch(g_io_prefetch_info_fdp_total_prefetch), .io_wfi_wfiSafe(g_io_wfi_wfiSafe), .io_debugTopDown_robHeadMissInDCache(g_io_debugTopDown_robHeadMissInDCache), .io_l1Miss(g_io_l1Miss), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value));
  MissQueue_xs u_i (.clock(clk), .reset(rst), .io_req_valid(io_req_valid), .io_req_bits_source(io_req_bits_source), .io_req_bits_pf_source(io_req_bits_pf_source), .io_req_bits_cmd(io_req_bits_cmd), .io_req_bits_addr(io_req_bits_addr), .io_req_bits_vaddr(io_req_bits_vaddr), .io_req_bits_full_overwrite(io_req_bits_full_overwrite), .io_req_bits_word_idx(io_req_bits_word_idx), .io_req_bits_amo_data(io_req_bits_amo_data), .io_req_bits_amo_mask(io_req_bits_amo_mask), .io_req_bits_amo_cmp(io_req_bits_amo_cmp), .io_req_bits_req_coh_state(io_req_bits_req_coh_state), .io_req_bits_id(io_req_bits_id), .io_req_bits_isBtoT(io_req_bits_isBtoT), .io_req_bits_occupy_way(io_req_bits_occupy_way), .io_req_bits_cancel(io_req_bits_cancel), .io_req_bits_store_data(io_req_bits_store_data), .io_req_bits_store_mask(io_req_bits_store_mask), .io_cmo_req_valid(io_cmo_req_valid), .io_cmo_req_bits_opcode(io_cmo_req_bits_opcode), .io_cmo_req_bits_address(io_cmo_req_bits_address), .io_cmo_resp_ready(io_cmo_resp_ready), .io_queryMQ_0_req_bits_source(io_queryMQ_0_req_bits_source), .io_queryMQ_0_req_bits_addr(io_queryMQ_0_req_bits_addr), .io_queryMQ_0_req_bits_vaddr(io_queryMQ_0_req_bits_vaddr), .io_queryMQ_1_req_bits_source(io_queryMQ_1_req_bits_source), .io_queryMQ_1_req_bits_addr(io_queryMQ_1_req_bits_addr), .io_queryMQ_1_req_bits_vaddr(io_queryMQ_1_req_bits_vaddr), .io_queryMQ_2_req_bits_source(io_queryMQ_2_req_bits_source), .io_queryMQ_2_req_bits_addr(io_queryMQ_2_req_bits_addr), .io_queryMQ_2_req_bits_vaddr(io_queryMQ_2_req_bits_vaddr), .io_queryMQ_3_req_bits_source(io_queryMQ_3_req_bits_source), .io_queryMQ_3_req_bits_addr(io_queryMQ_3_req_bits_addr), .io_queryMQ_3_req_bits_vaddr(io_queryMQ_3_req_bits_vaddr), .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode), .io_mem_grant_bits_param(io_mem_grant_bits_param), .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source), .io_mem_grant_bits_sink(io_mem_grant_bits_sink), .io_mem_grant_bits_denied(io_mem_grant_bits_denied), .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt), .io_mem_finish_ready(io_mem_finish_ready), .io_l2_hint_valid(io_l2_hint_valid), .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId), .io_main_pipe_req_ready(io_main_pipe_req_ready), .io_main_pipe_resp_valid(io_main_pipe_resp_valid), .io_main_pipe_resp_bits_miss_id(io_main_pipe_resp_bits_miss_id), .io_main_pipe_resp_bits_ack_miss_queue(io_main_pipe_resp_bits_ack_miss_queue), .io_mainpipe_info_s2_valid(io_mainpipe_info_s2_valid), .io_mainpipe_info_s2_miss_id(io_mainpipe_info_s2_miss_id), .io_mainpipe_info_s2_replay_to_mq(io_mainpipe_info_s2_replay_to_mq), .io_mainpipe_info_s2_evict_BtoT_way(io_mainpipe_info_s2_evict_BtoT_way), .io_mainpipe_info_s2_next_evict_way(io_mainpipe_info_s2_next_evict_way), .io_mainpipe_info_s3_valid(io_mainpipe_info_s3_valid), .io_mainpipe_info_s3_miss_id(io_mainpipe_info_s3_miss_id), .io_mainpipe_info_s3_refill_resp(io_mainpipe_info_s3_refill_resp), .io_probe_req_bits_addr(io_probe_req_bits_addr), .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr), .io_replace_req_bits_addr(io_replace_req_bits_addr), .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr), .io_evict_set(io_evict_set), .io_occupy_set_0(io_occupy_set_0), .io_occupy_set_1(io_occupy_set_1), .io_occupy_set_2(io_occupy_set_2), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_forward_0_valid(io_forward_0_valid), .io_forward_0_mshrid(io_forward_0_mshrid), .io_forward_0_paddr(io_forward_0_paddr), .io_forward_1_valid(io_forward_1_valid), .io_forward_1_mshrid(io_forward_1_mshrid), .io_forward_1_paddr(io_forward_1_paddr), .io_forward_2_valid(io_forward_2_valid), .io_forward_2_mshrid(io_forward_2_mshrid), .io_forward_2_paddr(io_forward_2_paddr), .io_l2_pf_store_only(io_l2_pf_store_only), .io_lqEmpty(io_lqEmpty), .io_wfi_wfiReq(io_wfi_wfiReq), .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid), .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits), .io_req_ready(i_io_req_ready), .io_resp_id(i_io_resp_id), .io_resp_handled(i_io_resp_handled), .io_resp_merged(i_io_resp_merged), .io_cmo_req_ready(i_io_cmo_req_ready), .io_cmo_resp_valid(i_io_cmo_resp_valid), .io_cmo_resp_bits_nderr(i_io_cmo_resp_bits_nderr), .io_queryMQ_0_ready(i_io_queryMQ_0_ready), .io_queryMQ_1_ready(i_io_queryMQ_1_ready), .io_queryMQ_2_ready(i_io_queryMQ_2_ready), .io_queryMQ_3_ready(i_io_queryMQ_3_ready), .io_mem_acquire_valid(i_io_mem_acquire_valid), .io_mem_acquire_bits_opcode(i_io_mem_acquire_bits_opcode), .io_mem_acquire_bits_param(i_io_mem_acquire_bits_param), .io_mem_acquire_bits_size(i_io_mem_acquire_bits_size), .io_mem_acquire_bits_source(i_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(i_io_mem_acquire_bits_address), .io_mem_acquire_bits_user_alias(i_io_mem_acquire_bits_user_alias), .io_mem_acquire_bits_user_vaddr(i_io_mem_acquire_bits_user_vaddr), .io_mem_acquire_bits_user_reqSource(i_io_mem_acquire_bits_user_reqSource), .io_mem_acquire_bits_user_needHint(i_io_mem_acquire_bits_user_needHint), .io_mem_acquire_bits_echo_isKeyword(i_io_mem_acquire_bits_echo_isKeyword), .io_mem_acquire_bits_mask(i_io_mem_acquire_bits_mask), .io_mem_grant_ready(i_io_mem_grant_ready), .io_mem_finish_valid(i_io_mem_finish_valid), .io_mem_finish_bits_sink(i_io_mem_finish_bits_sink), .io_main_pipe_req_valid(i_io_main_pipe_req_valid), .io_main_pipe_req_bits_miss(i_io_main_pipe_req_bits_miss), .io_main_pipe_req_bits_miss_id(i_io_main_pipe_req_bits_miss_id), .io_main_pipe_req_bits_occupy_way(i_io_main_pipe_req_bits_occupy_way), .io_main_pipe_req_bits_miss_fail_cause_evict_btot(i_io_main_pipe_req_bits_miss_fail_cause_evict_btot), .io_main_pipe_req_bits_source(i_io_main_pipe_req_bits_source), .io_main_pipe_req_bits_cmd(i_io_main_pipe_req_bits_cmd), .io_main_pipe_req_bits_vaddr(i_io_main_pipe_req_bits_vaddr), .io_main_pipe_req_bits_addr(i_io_main_pipe_req_bits_addr), .io_main_pipe_req_bits_word_idx(i_io_main_pipe_req_bits_word_idx), .io_main_pipe_req_bits_amo_data(i_io_main_pipe_req_bits_amo_data), .io_main_pipe_req_bits_amo_mask(i_io_main_pipe_req_bits_amo_mask), .io_main_pipe_req_bits_amo_cmp(i_io_main_pipe_req_bits_amo_cmp), .io_main_pipe_req_bits_pf_source(i_io_main_pipe_req_bits_pf_source), .io_main_pipe_req_bits_access(i_io_main_pipe_req_bits_access), .io_main_pipe_req_bits_id(i_io_main_pipe_req_bits_id), .io_refill_info_valid(i_io_refill_info_valid), .io_refill_info_bits_store_data(i_io_refill_info_bits_store_data), .io_refill_info_bits_store_mask(i_io_refill_info_bits_store_mask), .io_refill_info_bits_miss_param(i_io_refill_info_bits_miss_param), .io_refill_info_bits_error(i_io_refill_info_bits_error), .io_probe_block(i_io_probe_block), .io_replace_block(i_io_replace_block), .io_btot_ways_for_set(i_io_btot_ways_for_set), .io_occupy_fail_0(i_io_occupy_fail_0), .io_occupy_fail_1(i_io_occupy_fail_1), .io_occupy_fail_2(i_io_occupy_fail_2), .io_forward_0_forward_mshr(i_io_forward_0_forward_mshr), .io_forward_0_forwardData_0(i_io_forward_0_forwardData_0), .io_forward_0_forwardData_1(i_io_forward_0_forwardData_1), .io_forward_0_forwardData_2(i_io_forward_0_forwardData_2), .io_forward_0_forwardData_3(i_io_forward_0_forwardData_3), .io_forward_0_forwardData_4(i_io_forward_0_forwardData_4), .io_forward_0_forwardData_5(i_io_forward_0_forwardData_5), .io_forward_0_forwardData_6(i_io_forward_0_forwardData_6), .io_forward_0_forwardData_7(i_io_forward_0_forwardData_7), .io_forward_0_forwardData_8(i_io_forward_0_forwardData_8), .io_forward_0_forwardData_9(i_io_forward_0_forwardData_9), .io_forward_0_forwardData_10(i_io_forward_0_forwardData_10), .io_forward_0_forwardData_11(i_io_forward_0_forwardData_11), .io_forward_0_forwardData_12(i_io_forward_0_forwardData_12), .io_forward_0_forwardData_13(i_io_forward_0_forwardData_13), .io_forward_0_forwardData_14(i_io_forward_0_forwardData_14), .io_forward_0_forwardData_15(i_io_forward_0_forwardData_15), .io_forward_0_forward_result_valid(i_io_forward_0_forward_result_valid), .io_forward_0_corrupt(i_io_forward_0_corrupt), .io_forward_1_forward_mshr(i_io_forward_1_forward_mshr), .io_forward_1_forwardData_0(i_io_forward_1_forwardData_0), .io_forward_1_forwardData_1(i_io_forward_1_forwardData_1), .io_forward_1_forwardData_2(i_io_forward_1_forwardData_2), .io_forward_1_forwardData_3(i_io_forward_1_forwardData_3), .io_forward_1_forwardData_4(i_io_forward_1_forwardData_4), .io_forward_1_forwardData_5(i_io_forward_1_forwardData_5), .io_forward_1_forwardData_6(i_io_forward_1_forwardData_6), .io_forward_1_forwardData_7(i_io_forward_1_forwardData_7), .io_forward_1_forwardData_8(i_io_forward_1_forwardData_8), .io_forward_1_forwardData_9(i_io_forward_1_forwardData_9), .io_forward_1_forwardData_10(i_io_forward_1_forwardData_10), .io_forward_1_forwardData_11(i_io_forward_1_forwardData_11), .io_forward_1_forwardData_12(i_io_forward_1_forwardData_12), .io_forward_1_forwardData_13(i_io_forward_1_forwardData_13), .io_forward_1_forwardData_14(i_io_forward_1_forwardData_14), .io_forward_1_forwardData_15(i_io_forward_1_forwardData_15), .io_forward_1_forward_result_valid(i_io_forward_1_forward_result_valid), .io_forward_1_corrupt(i_io_forward_1_corrupt), .io_forward_2_forward_mshr(i_io_forward_2_forward_mshr), .io_forward_2_forwardData_0(i_io_forward_2_forwardData_0), .io_forward_2_forwardData_1(i_io_forward_2_forwardData_1), .io_forward_2_forwardData_2(i_io_forward_2_forwardData_2), .io_forward_2_forwardData_3(i_io_forward_2_forwardData_3), .io_forward_2_forwardData_4(i_io_forward_2_forwardData_4), .io_forward_2_forwardData_5(i_io_forward_2_forwardData_5), .io_forward_2_forwardData_6(i_io_forward_2_forwardData_6), .io_forward_2_forwardData_7(i_io_forward_2_forwardData_7), .io_forward_2_forwardData_8(i_io_forward_2_forwardData_8), .io_forward_2_forwardData_9(i_io_forward_2_forwardData_9), .io_forward_2_forwardData_10(i_io_forward_2_forwardData_10), .io_forward_2_forwardData_11(i_io_forward_2_forwardData_11), .io_forward_2_forwardData_12(i_io_forward_2_forwardData_12), .io_forward_2_forwardData_13(i_io_forward_2_forwardData_13), .io_forward_2_forwardData_14(i_io_forward_2_forwardData_14), .io_forward_2_forwardData_15(i_io_forward_2_forwardData_15), .io_forward_2_forward_result_valid(i_io_forward_2_forward_result_valid), .io_forward_2_corrupt(i_io_forward_2_corrupt), .io_prefetch_info_naive_late_miss_prefetch(i_io_prefetch_info_naive_late_miss_prefetch), .io_prefetch_info_fdp_late_miss_prefetch(i_io_prefetch_info_fdp_late_miss_prefetch), .io_prefetch_info_fdp_prefetch_monitor_cnt(i_io_prefetch_info_fdp_prefetch_monitor_cnt), .io_prefetch_info_fdp_total_prefetch(i_io_prefetch_info_fdp_total_prefetch), .io_wfi_wfiSafe(i_io_wfi_wfiSafe), .io_debugTopDown_robHeadMissInDCache(i_io_debugTopDown_robHeadMissInDCache), .io_l1Miss(i_io_l1Miss), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value));
  always @(negedge clk) begin
    if (rst) begin
      io_req_valid <= 1'b0;
      io_cmo_req_valid <= 1'b0;
      io_mem_grant_valid <= 1'b0;
      io_l2_hint_valid <= 1'b0;
      io_main_pipe_resp_valid <= 1'b0;
      io_mainpipe_info_s2_valid <= 1'b0;
      io_mainpipe_info_s3_valid <= 1'b0;
      io_forward_0_valid <= 1'b0;
      io_forward_1_valid <= 1'b0;
      io_forward_2_valid <= 1'b0;
      io_debugTopDown_robHeadVaddr_valid <= 1'b0;
    end else begin
      io_req_valid <= ($urandom_range(0,1));
      io_req_bits_source <= (4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3));
      io_req_bits_pf_source <= 3'($urandom);
      io_req_bits_cmd <= 5'($urandom);
      io_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_req_bits_full_overwrite <= $urandom_range(0,1);
      io_req_bits_word_idx <= 3'($urandom);
      io_req_bits_amo_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_req_bits_amo_mask <= 16'($urandom);
      io_req_bits_amo_cmp <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_req_bits_req_coh_state <= 2'($urandom);
      io_req_bits_id <= 6'($urandom);
      io_req_bits_isBtoT <= $urandom_range(0,1);
      io_req_bits_occupy_way <= 4'($urandom);
      io_req_bits_cancel <= ($urandom_range(0,7)==0);
      io_req_bits_store_data <= 512'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_req_bits_store_mask <= 64'({$urandom(), $urandom()});
      io_cmo_req_valid <= ($urandom_range(0,7)==0);
      io_cmo_req_bits_opcode <= 3'($urandom);
      io_cmo_req_bits_address <= 64'({$urandom(), $urandom()});
      io_cmo_resp_ready <= ($urandom_range(0,3)!=0);
      io_queryMQ_0_req_bits_source <= (4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3));
      io_queryMQ_0_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_0_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_1_req_bits_source <= (4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3));
      io_queryMQ_1_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_1_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_2_req_bits_source <= (4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3));
      io_queryMQ_2_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_2_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_3_req_bits_source <= (4'($urandom_range(0,1) ? $urandom_range(0,1) : 4'h3));
      io_queryMQ_3_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_queryMQ_3_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_mem_acquire_ready <= ($urandom_range(0,3)!=0);
      io_mem_grant_bits_param <= 2'($urandom);
      io_mem_grant_bits_size <= 3'($urandom);
      io_mem_grant_bits_sink <= 10'($urandom);
      io_mem_grant_bits_denied <= $urandom_range(0,1);
      io_mem_grant_bits_data <= 256'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_mem_grant_bits_corrupt <= $urandom_range(0,1);
      io_mem_finish_ready <= ($urandom_range(0,3)!=0);
      io_l2_hint_valid <= ($urandom_range(0,3)==0);
      io_l2_hint_bits_sourceId <= 4'($urandom_range(0,15));
      io_main_pipe_req_ready <= ($urandom_range(0,3)!=0);
      io_main_pipe_resp_valid <= ($urandom_range(0,1));
      io_main_pipe_resp_bits_miss_id <= 4'($urandom_range(0,15));
      io_main_pipe_resp_bits_ack_miss_queue <= $urandom_range(0,1);
      io_mainpipe_info_s2_valid <= ($urandom_range(0,1));
      io_mainpipe_info_s2_miss_id <= 4'($urandom_range(0,15));
      io_mainpipe_info_s2_replay_to_mq <= $urandom_range(0,1);
      io_mainpipe_info_s2_evict_BtoT_way <= $urandom_range(0,1);
      io_mainpipe_info_s2_next_evict_way <= 4'($urandom);
      io_mainpipe_info_s3_valid <= ($urandom_range(0,1));
      io_mainpipe_info_s3_miss_id <= 4'($urandom_range(0,15));
      io_mainpipe_info_s3_refill_resp <= $urandom_range(0,1);
      io_probe_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_probe_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_replace_req_bits_addr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_replace_req_bits_vaddr <= {35'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_evict_set <= 8'($urandom);
      io_occupy_set_0 <= 8'($urandom);
      io_occupy_set_1 <= 8'($urandom);
      io_occupy_set_2 <= 8'($urandom);
      io_wbq_block_miss_req <= ($urandom_range(0,7)==0);
      io_forward_0_valid <= ($urandom_range(0,1));
      io_forward_0_mshrid <= 4'($urandom_range(0,15));
      io_forward_0_paddr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_forward_1_valid <= ($urandom_range(0,1));
      io_forward_1_mshrid <= 4'($urandom_range(0,15));
      io_forward_1_paddr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_forward_2_valid <= ($urandom_range(0,1));
      io_forward_2_mshrid <= 4'($urandom_range(0,15));
      io_forward_2_paddr <= {33'($urandom_range(0,3)), 3'($urandom_range(0,7)), 12'($urandom)};
      io_l2_pf_store_only <= $urandom_range(0,1);
      io_lqEmpty <= $urandom_range(0,1);
      io_wfi_wfiReq <= $urandom_range(0,1);
      io_debugTopDown_robHeadVaddr_valid <= $urandom_range(0,1);
      io_debugTopDown_robHeadVaddr_bits <= 50'({$urandom(), $urandom()});
    end
  end

  always @(negedge clk) begin
    if (rst) begin
      io_mem_grant_valid       <= 1'b0;
      io_mem_grant_bits_source <= 6'h0;
      io_mem_grant_bits_opcode <= 4'h0;
    end else begin
      io_mem_grant_valid       <= ($urandom_range(0,1));
      // source：多数命中 entry(0..15)，偶尔 17(CMO)
      io_mem_grant_bits_source <= ($urandom_range(0,7)==0) ? 6'h11
                                                           : 6'($urandom_range(0,15));
      // opcode：GrantData(5)/Grant(4)/CBOAck(8)
      case ($urandom_range(0,2))
        0: io_mem_grant_bits_opcode <= 4'h5;
        1: io_mem_grant_bits_opcode <= 4'h4;
        default: io_mem_grant_bits_opcode <= 4'h8;
      endcase
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_req_ready) && g_io_req_ready !== i_io_req_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_req_ready g=%h i=%h", $time, g_io_req_ready, i_io_req_ready); end
    if (!$isunknown(g_io_resp_id) && g_io_resp_id !== i_io_resp_id) begin errors++;
      if(errors<=80) $display("[%0t] io_resp_id g=%h i=%h", $time, g_io_resp_id, i_io_resp_id); end
    if (!$isunknown(g_io_resp_handled) && g_io_resp_handled !== i_io_resp_handled) begin errors++;
      if(errors<=80) $display("[%0t] io_resp_handled g=%h i=%h", $time, g_io_resp_handled, i_io_resp_handled); end
    if (!$isunknown(g_io_resp_merged) && g_io_resp_merged !== i_io_resp_merged) begin errors++;
      if(errors<=80) $display("[%0t] io_resp_merged g=%h i=%h", $time, g_io_resp_merged, i_io_resp_merged); end
    if (!$isunknown(g_io_cmo_req_ready) && g_io_cmo_req_ready !== i_io_cmo_req_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_cmo_req_ready g=%h i=%h", $time, g_io_cmo_req_ready, i_io_cmo_req_ready); end
    if (!$isunknown(g_io_cmo_resp_valid) && g_io_cmo_resp_valid !== i_io_cmo_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_cmo_resp_valid g=%h i=%h", $time, g_io_cmo_resp_valid, i_io_cmo_resp_valid); end
    if ((g_io_cmo_resp_valid) && !$isunknown(g_io_cmo_resp_bits_nderr) && g_io_cmo_resp_bits_nderr !== i_io_cmo_resp_bits_nderr) begin errors++;
      if(errors<=80) $display("[%0t] io_cmo_resp_bits_nderr g=%h i=%h", $time, g_io_cmo_resp_bits_nderr, i_io_cmo_resp_bits_nderr); end
    if (!$isunknown(g_io_queryMQ_0_ready) && g_io_queryMQ_0_ready !== i_io_queryMQ_0_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_queryMQ_0_ready g=%h i=%h", $time, g_io_queryMQ_0_ready, i_io_queryMQ_0_ready); end
    if (!$isunknown(g_io_queryMQ_1_ready) && g_io_queryMQ_1_ready !== i_io_queryMQ_1_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_queryMQ_1_ready g=%h i=%h", $time, g_io_queryMQ_1_ready, i_io_queryMQ_1_ready); end
    if (!$isunknown(g_io_queryMQ_2_ready) && g_io_queryMQ_2_ready !== i_io_queryMQ_2_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_queryMQ_2_ready g=%h i=%h", $time, g_io_queryMQ_2_ready, i_io_queryMQ_2_ready); end
    if (!$isunknown(g_io_queryMQ_3_ready) && g_io_queryMQ_3_ready !== i_io_queryMQ_3_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_queryMQ_3_ready g=%h i=%h", $time, g_io_queryMQ_3_ready, i_io_queryMQ_3_ready); end
    if (!$isunknown(g_io_mem_acquire_valid) && g_io_mem_acquire_valid !== i_io_mem_acquire_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_valid g=%h i=%h", $time, g_io_mem_acquire_valid, i_io_mem_acquire_valid); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_opcode) && g_io_mem_acquire_bits_opcode !== i_io_mem_acquire_bits_opcode) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_opcode g=%h i=%h", $time, g_io_mem_acquire_bits_opcode, i_io_mem_acquire_bits_opcode); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_param) && g_io_mem_acquire_bits_param !== i_io_mem_acquire_bits_param) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_param g=%h i=%h", $time, g_io_mem_acquire_bits_param, i_io_mem_acquire_bits_param); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_size) && g_io_mem_acquire_bits_size !== i_io_mem_acquire_bits_size) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_size g=%h i=%h", $time, g_io_mem_acquire_bits_size, i_io_mem_acquire_bits_size); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_source) && g_io_mem_acquire_bits_source !== i_io_mem_acquire_bits_source) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_source g=%h i=%h", $time, g_io_mem_acquire_bits_source, i_io_mem_acquire_bits_source); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_address) && g_io_mem_acquire_bits_address !== i_io_mem_acquire_bits_address) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_address g=%h i=%h", $time, g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_user_alias) && g_io_mem_acquire_bits_user_alias !== i_io_mem_acquire_bits_user_alias) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_user_alias g=%h i=%h", $time, g_io_mem_acquire_bits_user_alias, i_io_mem_acquire_bits_user_alias); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_user_vaddr) && g_io_mem_acquire_bits_user_vaddr !== i_io_mem_acquire_bits_user_vaddr) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_user_vaddr g=%h i=%h", $time, g_io_mem_acquire_bits_user_vaddr, i_io_mem_acquire_bits_user_vaddr); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_user_reqSource) && g_io_mem_acquire_bits_user_reqSource !== i_io_mem_acquire_bits_user_reqSource) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_user_reqSource g=%h i=%h", $time, g_io_mem_acquire_bits_user_reqSource, i_io_mem_acquire_bits_user_reqSource); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_user_needHint) && g_io_mem_acquire_bits_user_needHint !== i_io_mem_acquire_bits_user_needHint) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_user_needHint g=%h i=%h", $time, g_io_mem_acquire_bits_user_needHint, i_io_mem_acquire_bits_user_needHint); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_echo_isKeyword) && g_io_mem_acquire_bits_echo_isKeyword !== i_io_mem_acquire_bits_echo_isKeyword) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_echo_isKeyword g=%h i=%h", $time, g_io_mem_acquire_bits_echo_isKeyword, i_io_mem_acquire_bits_echo_isKeyword); end
    if ((g_io_mem_acquire_valid) && !$isunknown(g_io_mem_acquire_bits_mask) && g_io_mem_acquire_bits_mask !== i_io_mem_acquire_bits_mask) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_acquire_bits_mask g=%h i=%h", $time, g_io_mem_acquire_bits_mask, i_io_mem_acquire_bits_mask); end
    if (!$isunknown(g_io_mem_grant_ready) && g_io_mem_grant_ready !== i_io_mem_grant_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_grant_ready g=%h i=%h", $time, g_io_mem_grant_ready, i_io_mem_grant_ready); end
    if (!$isunknown(g_io_mem_finish_valid) && g_io_mem_finish_valid !== i_io_mem_finish_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_finish_valid g=%h i=%h", $time, g_io_mem_finish_valid, i_io_mem_finish_valid); end
    if ((g_io_mem_finish_valid) && !$isunknown(g_io_mem_finish_bits_sink) && g_io_mem_finish_bits_sink !== i_io_mem_finish_bits_sink) begin errors++;
      if(errors<=80) $display("[%0t] io_mem_finish_bits_sink g=%h i=%h", $time, g_io_mem_finish_bits_sink, i_io_mem_finish_bits_sink); end
    if (!$isunknown(g_io_main_pipe_req_valid) && g_io_main_pipe_req_valid !== i_io_main_pipe_req_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_valid g=%h i=%h", $time, g_io_main_pipe_req_valid, i_io_main_pipe_req_valid); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_miss) && g_io_main_pipe_req_bits_miss !== i_io_main_pipe_req_bits_miss) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_miss g=%h i=%h", $time, g_io_main_pipe_req_bits_miss, i_io_main_pipe_req_bits_miss); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_miss_id) && g_io_main_pipe_req_bits_miss_id !== i_io_main_pipe_req_bits_miss_id) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_miss_id g=%h i=%h", $time, g_io_main_pipe_req_bits_miss_id, i_io_main_pipe_req_bits_miss_id); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_occupy_way) && g_io_main_pipe_req_bits_occupy_way !== i_io_main_pipe_req_bits_occupy_way) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_occupy_way g=%h i=%h", $time, g_io_main_pipe_req_bits_occupy_way, i_io_main_pipe_req_bits_occupy_way); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_miss_fail_cause_evict_btot) && g_io_main_pipe_req_bits_miss_fail_cause_evict_btot !== i_io_main_pipe_req_bits_miss_fail_cause_evict_btot) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_miss_fail_cause_evict_btot g=%h i=%h", $time, g_io_main_pipe_req_bits_miss_fail_cause_evict_btot, i_io_main_pipe_req_bits_miss_fail_cause_evict_btot); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_source) && g_io_main_pipe_req_bits_source !== i_io_main_pipe_req_bits_source) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_source g=%h i=%h", $time, g_io_main_pipe_req_bits_source, i_io_main_pipe_req_bits_source); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_cmd) && g_io_main_pipe_req_bits_cmd !== i_io_main_pipe_req_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_cmd g=%h i=%h", $time, g_io_main_pipe_req_bits_cmd, i_io_main_pipe_req_bits_cmd); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_vaddr) && g_io_main_pipe_req_bits_vaddr !== i_io_main_pipe_req_bits_vaddr) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_vaddr g=%h i=%h", $time, g_io_main_pipe_req_bits_vaddr, i_io_main_pipe_req_bits_vaddr); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_addr) && g_io_main_pipe_req_bits_addr !== i_io_main_pipe_req_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_addr g=%h i=%h", $time, g_io_main_pipe_req_bits_addr, i_io_main_pipe_req_bits_addr); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_word_idx) && g_io_main_pipe_req_bits_word_idx !== i_io_main_pipe_req_bits_word_idx) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_word_idx g=%h i=%h", $time, g_io_main_pipe_req_bits_word_idx, i_io_main_pipe_req_bits_word_idx); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_amo_data) && g_io_main_pipe_req_bits_amo_data !== i_io_main_pipe_req_bits_amo_data) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_amo_data g=%h i=%h", $time, g_io_main_pipe_req_bits_amo_data, i_io_main_pipe_req_bits_amo_data); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_amo_mask) && g_io_main_pipe_req_bits_amo_mask !== i_io_main_pipe_req_bits_amo_mask) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_amo_mask g=%h i=%h", $time, g_io_main_pipe_req_bits_amo_mask, i_io_main_pipe_req_bits_amo_mask); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_amo_cmp) && g_io_main_pipe_req_bits_amo_cmp !== i_io_main_pipe_req_bits_amo_cmp) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_amo_cmp g=%h i=%h", $time, g_io_main_pipe_req_bits_amo_cmp, i_io_main_pipe_req_bits_amo_cmp); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_pf_source) && g_io_main_pipe_req_bits_pf_source !== i_io_main_pipe_req_bits_pf_source) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_pf_source g=%h i=%h", $time, g_io_main_pipe_req_bits_pf_source, i_io_main_pipe_req_bits_pf_source); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_access) && g_io_main_pipe_req_bits_access !== i_io_main_pipe_req_bits_access) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_access g=%h i=%h", $time, g_io_main_pipe_req_bits_access, i_io_main_pipe_req_bits_access); end
    if ((g_io_main_pipe_req_valid) && !$isunknown(g_io_main_pipe_req_bits_id) && g_io_main_pipe_req_bits_id !== i_io_main_pipe_req_bits_id) begin errors++;
      if(errors<=80) $display("[%0t] io_main_pipe_req_bits_id g=%h i=%h", $time, g_io_main_pipe_req_bits_id, i_io_main_pipe_req_bits_id); end
    if (!$isunknown(g_io_refill_info_valid) && g_io_refill_info_valid !== i_io_refill_info_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_refill_info_valid g=%h i=%h", $time, g_io_refill_info_valid, i_io_refill_info_valid); end
    if ((g_io_refill_info_valid) && !$isunknown(g_io_refill_info_bits_store_data) && g_io_refill_info_bits_store_data !== i_io_refill_info_bits_store_data) begin errors++;
      if(errors<=80) $display("[%0t] io_refill_info_bits_store_data g=%h i=%h", $time, g_io_refill_info_bits_store_data, i_io_refill_info_bits_store_data); end
    if ((g_io_refill_info_valid) && !$isunknown(g_io_refill_info_bits_store_mask) && g_io_refill_info_bits_store_mask !== i_io_refill_info_bits_store_mask) begin errors++;
      if(errors<=80) $display("[%0t] io_refill_info_bits_store_mask g=%h i=%h", $time, g_io_refill_info_bits_store_mask, i_io_refill_info_bits_store_mask); end
    if ((g_io_refill_info_valid) && !$isunknown(g_io_refill_info_bits_miss_param) && g_io_refill_info_bits_miss_param !== i_io_refill_info_bits_miss_param) begin errors++;
      if(errors<=80) $display("[%0t] io_refill_info_bits_miss_param g=%h i=%h", $time, g_io_refill_info_bits_miss_param, i_io_refill_info_bits_miss_param); end
    if ((g_io_refill_info_valid) && !$isunknown(g_io_refill_info_bits_error) && g_io_refill_info_bits_error !== i_io_refill_info_bits_error) begin errors++;
      if(errors<=80) $display("[%0t] io_refill_info_bits_error g=%h i=%h", $time, g_io_refill_info_bits_error, i_io_refill_info_bits_error); end
    if (!$isunknown(g_io_probe_block) && g_io_probe_block !== i_io_probe_block) begin errors++;
      if(errors<=80) $display("[%0t] io_probe_block g=%h i=%h", $time, g_io_probe_block, i_io_probe_block); end
    if (!$isunknown(g_io_replace_block) && g_io_replace_block !== i_io_replace_block) begin errors++;
      if(errors<=80) $display("[%0t] io_replace_block g=%h i=%h", $time, g_io_replace_block, i_io_replace_block); end
    if (!$isunknown(g_io_btot_ways_for_set) && g_io_btot_ways_for_set !== i_io_btot_ways_for_set) begin errors++;
      if(errors<=80) $display("[%0t] io_btot_ways_for_set g=%h i=%h", $time, g_io_btot_ways_for_set, i_io_btot_ways_for_set); end
    if (!$isunknown(g_io_occupy_fail_0) && g_io_occupy_fail_0 !== i_io_occupy_fail_0) begin errors++;
      if(errors<=80) $display("[%0t] io_occupy_fail_0 g=%h i=%h", $time, g_io_occupy_fail_0, i_io_occupy_fail_0); end
    if (!$isunknown(g_io_occupy_fail_1) && g_io_occupy_fail_1 !== i_io_occupy_fail_1) begin errors++;
      if(errors<=80) $display("[%0t] io_occupy_fail_1 g=%h i=%h", $time, g_io_occupy_fail_1, i_io_occupy_fail_1); end
    if (!$isunknown(g_io_occupy_fail_2) && g_io_occupy_fail_2 !== i_io_occupy_fail_2) begin errors++;
      if(errors<=80) $display("[%0t] io_occupy_fail_2 g=%h i=%h", $time, g_io_occupy_fail_2, i_io_occupy_fail_2); end
    if (!$isunknown(g_io_forward_0_forward_mshr) && g_io_forward_0_forward_mshr !== i_io_forward_0_forward_mshr) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forward_mshr g=%h i=%h", $time, g_io_forward_0_forward_mshr, i_io_forward_0_forward_mshr); end
    if (!$isunknown(g_io_forward_0_forwardData_0) && g_io_forward_0_forwardData_0 !== i_io_forward_0_forwardData_0) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_0 g=%h i=%h", $time, g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0); end
    if (!$isunknown(g_io_forward_0_forwardData_1) && g_io_forward_0_forwardData_1 !== i_io_forward_0_forwardData_1) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_1 g=%h i=%h", $time, g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1); end
    if (!$isunknown(g_io_forward_0_forwardData_2) && g_io_forward_0_forwardData_2 !== i_io_forward_0_forwardData_2) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_2 g=%h i=%h", $time, g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2); end
    if (!$isunknown(g_io_forward_0_forwardData_3) && g_io_forward_0_forwardData_3 !== i_io_forward_0_forwardData_3) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_3 g=%h i=%h", $time, g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3); end
    if (!$isunknown(g_io_forward_0_forwardData_4) && g_io_forward_0_forwardData_4 !== i_io_forward_0_forwardData_4) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_4 g=%h i=%h", $time, g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4); end
    if (!$isunknown(g_io_forward_0_forwardData_5) && g_io_forward_0_forwardData_5 !== i_io_forward_0_forwardData_5) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_5 g=%h i=%h", $time, g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5); end
    if (!$isunknown(g_io_forward_0_forwardData_6) && g_io_forward_0_forwardData_6 !== i_io_forward_0_forwardData_6) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_6 g=%h i=%h", $time, g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6); end
    if (!$isunknown(g_io_forward_0_forwardData_7) && g_io_forward_0_forwardData_7 !== i_io_forward_0_forwardData_7) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_7 g=%h i=%h", $time, g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7); end
    if (!$isunknown(g_io_forward_0_forwardData_8) && g_io_forward_0_forwardData_8 !== i_io_forward_0_forwardData_8) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_8 g=%h i=%h", $time, g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8); end
    if (!$isunknown(g_io_forward_0_forwardData_9) && g_io_forward_0_forwardData_9 !== i_io_forward_0_forwardData_9) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_9 g=%h i=%h", $time, g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9); end
    if (!$isunknown(g_io_forward_0_forwardData_10) && g_io_forward_0_forwardData_10 !== i_io_forward_0_forwardData_10) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_10 g=%h i=%h", $time, g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10); end
    if (!$isunknown(g_io_forward_0_forwardData_11) && g_io_forward_0_forwardData_11 !== i_io_forward_0_forwardData_11) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_11 g=%h i=%h", $time, g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11); end
    if (!$isunknown(g_io_forward_0_forwardData_12) && g_io_forward_0_forwardData_12 !== i_io_forward_0_forwardData_12) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_12 g=%h i=%h", $time, g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12); end
    if (!$isunknown(g_io_forward_0_forwardData_13) && g_io_forward_0_forwardData_13 !== i_io_forward_0_forwardData_13) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_13 g=%h i=%h", $time, g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13); end
    if (!$isunknown(g_io_forward_0_forwardData_14) && g_io_forward_0_forwardData_14 !== i_io_forward_0_forwardData_14) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_14 g=%h i=%h", $time, g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14); end
    if (!$isunknown(g_io_forward_0_forwardData_15) && g_io_forward_0_forwardData_15 !== i_io_forward_0_forwardData_15) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forwardData_15 g=%h i=%h", $time, g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15); end
    if (!$isunknown(g_io_forward_0_forward_result_valid) && g_io_forward_0_forward_result_valid !== i_io_forward_0_forward_result_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_forward_result_valid g=%h i=%h", $time, g_io_forward_0_forward_result_valid, i_io_forward_0_forward_result_valid); end
    if (!$isunknown(g_io_forward_0_corrupt) && g_io_forward_0_corrupt !== i_io_forward_0_corrupt) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_0_corrupt g=%h i=%h", $time, g_io_forward_0_corrupt, i_io_forward_0_corrupt); end
    if (!$isunknown(g_io_forward_1_forward_mshr) && g_io_forward_1_forward_mshr !== i_io_forward_1_forward_mshr) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forward_mshr g=%h i=%h", $time, g_io_forward_1_forward_mshr, i_io_forward_1_forward_mshr); end
    if (!$isunknown(g_io_forward_1_forwardData_0) && g_io_forward_1_forwardData_0 !== i_io_forward_1_forwardData_0) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_0 g=%h i=%h", $time, g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0); end
    if (!$isunknown(g_io_forward_1_forwardData_1) && g_io_forward_1_forwardData_1 !== i_io_forward_1_forwardData_1) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_1 g=%h i=%h", $time, g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1); end
    if (!$isunknown(g_io_forward_1_forwardData_2) && g_io_forward_1_forwardData_2 !== i_io_forward_1_forwardData_2) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_2 g=%h i=%h", $time, g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2); end
    if (!$isunknown(g_io_forward_1_forwardData_3) && g_io_forward_1_forwardData_3 !== i_io_forward_1_forwardData_3) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_3 g=%h i=%h", $time, g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3); end
    if (!$isunknown(g_io_forward_1_forwardData_4) && g_io_forward_1_forwardData_4 !== i_io_forward_1_forwardData_4) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_4 g=%h i=%h", $time, g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4); end
    if (!$isunknown(g_io_forward_1_forwardData_5) && g_io_forward_1_forwardData_5 !== i_io_forward_1_forwardData_5) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_5 g=%h i=%h", $time, g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5); end
    if (!$isunknown(g_io_forward_1_forwardData_6) && g_io_forward_1_forwardData_6 !== i_io_forward_1_forwardData_6) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_6 g=%h i=%h", $time, g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6); end
    if (!$isunknown(g_io_forward_1_forwardData_7) && g_io_forward_1_forwardData_7 !== i_io_forward_1_forwardData_7) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_7 g=%h i=%h", $time, g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7); end
    if (!$isunknown(g_io_forward_1_forwardData_8) && g_io_forward_1_forwardData_8 !== i_io_forward_1_forwardData_8) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_8 g=%h i=%h", $time, g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8); end
    if (!$isunknown(g_io_forward_1_forwardData_9) && g_io_forward_1_forwardData_9 !== i_io_forward_1_forwardData_9) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_9 g=%h i=%h", $time, g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9); end
    if (!$isunknown(g_io_forward_1_forwardData_10) && g_io_forward_1_forwardData_10 !== i_io_forward_1_forwardData_10) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_10 g=%h i=%h", $time, g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10); end
    if (!$isunknown(g_io_forward_1_forwardData_11) && g_io_forward_1_forwardData_11 !== i_io_forward_1_forwardData_11) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_11 g=%h i=%h", $time, g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11); end
    if (!$isunknown(g_io_forward_1_forwardData_12) && g_io_forward_1_forwardData_12 !== i_io_forward_1_forwardData_12) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_12 g=%h i=%h", $time, g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12); end
    if (!$isunknown(g_io_forward_1_forwardData_13) && g_io_forward_1_forwardData_13 !== i_io_forward_1_forwardData_13) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_13 g=%h i=%h", $time, g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13); end
    if (!$isunknown(g_io_forward_1_forwardData_14) && g_io_forward_1_forwardData_14 !== i_io_forward_1_forwardData_14) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_14 g=%h i=%h", $time, g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14); end
    if (!$isunknown(g_io_forward_1_forwardData_15) && g_io_forward_1_forwardData_15 !== i_io_forward_1_forwardData_15) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forwardData_15 g=%h i=%h", $time, g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15); end
    if (!$isunknown(g_io_forward_1_forward_result_valid) && g_io_forward_1_forward_result_valid !== i_io_forward_1_forward_result_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_forward_result_valid g=%h i=%h", $time, g_io_forward_1_forward_result_valid, i_io_forward_1_forward_result_valid); end
    if (!$isunknown(g_io_forward_1_corrupt) && g_io_forward_1_corrupt !== i_io_forward_1_corrupt) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_1_corrupt g=%h i=%h", $time, g_io_forward_1_corrupt, i_io_forward_1_corrupt); end
    if (!$isunknown(g_io_forward_2_forward_mshr) && g_io_forward_2_forward_mshr !== i_io_forward_2_forward_mshr) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forward_mshr g=%h i=%h", $time, g_io_forward_2_forward_mshr, i_io_forward_2_forward_mshr); end
    if (!$isunknown(g_io_forward_2_forwardData_0) && g_io_forward_2_forwardData_0 !== i_io_forward_2_forwardData_0) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_0 g=%h i=%h", $time, g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0); end
    if (!$isunknown(g_io_forward_2_forwardData_1) && g_io_forward_2_forwardData_1 !== i_io_forward_2_forwardData_1) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_1 g=%h i=%h", $time, g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1); end
    if (!$isunknown(g_io_forward_2_forwardData_2) && g_io_forward_2_forwardData_2 !== i_io_forward_2_forwardData_2) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_2 g=%h i=%h", $time, g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2); end
    if (!$isunknown(g_io_forward_2_forwardData_3) && g_io_forward_2_forwardData_3 !== i_io_forward_2_forwardData_3) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_3 g=%h i=%h", $time, g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3); end
    if (!$isunknown(g_io_forward_2_forwardData_4) && g_io_forward_2_forwardData_4 !== i_io_forward_2_forwardData_4) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_4 g=%h i=%h", $time, g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4); end
    if (!$isunknown(g_io_forward_2_forwardData_5) && g_io_forward_2_forwardData_5 !== i_io_forward_2_forwardData_5) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_5 g=%h i=%h", $time, g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5); end
    if (!$isunknown(g_io_forward_2_forwardData_6) && g_io_forward_2_forwardData_6 !== i_io_forward_2_forwardData_6) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_6 g=%h i=%h", $time, g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6); end
    if (!$isunknown(g_io_forward_2_forwardData_7) && g_io_forward_2_forwardData_7 !== i_io_forward_2_forwardData_7) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_7 g=%h i=%h", $time, g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7); end
    if (!$isunknown(g_io_forward_2_forwardData_8) && g_io_forward_2_forwardData_8 !== i_io_forward_2_forwardData_8) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_8 g=%h i=%h", $time, g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8); end
    if (!$isunknown(g_io_forward_2_forwardData_9) && g_io_forward_2_forwardData_9 !== i_io_forward_2_forwardData_9) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_9 g=%h i=%h", $time, g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9); end
    if (!$isunknown(g_io_forward_2_forwardData_10) && g_io_forward_2_forwardData_10 !== i_io_forward_2_forwardData_10) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_10 g=%h i=%h", $time, g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10); end
    if (!$isunknown(g_io_forward_2_forwardData_11) && g_io_forward_2_forwardData_11 !== i_io_forward_2_forwardData_11) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_11 g=%h i=%h", $time, g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11); end
    if (!$isunknown(g_io_forward_2_forwardData_12) && g_io_forward_2_forwardData_12 !== i_io_forward_2_forwardData_12) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_12 g=%h i=%h", $time, g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12); end
    if (!$isunknown(g_io_forward_2_forwardData_13) && g_io_forward_2_forwardData_13 !== i_io_forward_2_forwardData_13) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_13 g=%h i=%h", $time, g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13); end
    if (!$isunknown(g_io_forward_2_forwardData_14) && g_io_forward_2_forwardData_14 !== i_io_forward_2_forwardData_14) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_14 g=%h i=%h", $time, g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14); end
    if (!$isunknown(g_io_forward_2_forwardData_15) && g_io_forward_2_forwardData_15 !== i_io_forward_2_forwardData_15) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forwardData_15 g=%h i=%h", $time, g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15); end
    if (!$isunknown(g_io_forward_2_forward_result_valid) && g_io_forward_2_forward_result_valid !== i_io_forward_2_forward_result_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_forward_result_valid g=%h i=%h", $time, g_io_forward_2_forward_result_valid, i_io_forward_2_forward_result_valid); end
    if (!$isunknown(g_io_forward_2_corrupt) && g_io_forward_2_corrupt !== i_io_forward_2_corrupt) begin errors++;
      if(errors<=80) $display("[%0t] io_forward_2_corrupt g=%h i=%h", $time, g_io_forward_2_corrupt, i_io_forward_2_corrupt); end
    if (!$isunknown(g_io_prefetch_info_naive_late_miss_prefetch) && g_io_prefetch_info_naive_late_miss_prefetch !== i_io_prefetch_info_naive_late_miss_prefetch) begin errors++;
      if(errors<=80) $display("[%0t] io_prefetch_info_naive_late_miss_prefetch g=%h i=%h", $time, g_io_prefetch_info_naive_late_miss_prefetch, i_io_prefetch_info_naive_late_miss_prefetch); end
    if (!$isunknown(g_io_prefetch_info_fdp_late_miss_prefetch) && g_io_prefetch_info_fdp_late_miss_prefetch !== i_io_prefetch_info_fdp_late_miss_prefetch) begin errors++;
      if(errors<=80) $display("[%0t] io_prefetch_info_fdp_late_miss_prefetch g=%h i=%h", $time, g_io_prefetch_info_fdp_late_miss_prefetch, i_io_prefetch_info_fdp_late_miss_prefetch); end
    if (!$isunknown(g_io_prefetch_info_fdp_prefetch_monitor_cnt) && g_io_prefetch_info_fdp_prefetch_monitor_cnt !== i_io_prefetch_info_fdp_prefetch_monitor_cnt) begin errors++;
      if(errors<=80) $display("[%0t] io_prefetch_info_fdp_prefetch_monitor_cnt g=%h i=%h", $time, g_io_prefetch_info_fdp_prefetch_monitor_cnt, i_io_prefetch_info_fdp_prefetch_monitor_cnt); end
    if (!$isunknown(g_io_prefetch_info_fdp_total_prefetch) && g_io_prefetch_info_fdp_total_prefetch !== i_io_prefetch_info_fdp_total_prefetch) begin errors++;
      if(errors<=80) $display("[%0t] io_prefetch_info_fdp_total_prefetch g=%h i=%h", $time, g_io_prefetch_info_fdp_total_prefetch, i_io_prefetch_info_fdp_total_prefetch); end
    if (!$isunknown(g_io_wfi_wfiSafe) && g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++;
      if(errors<=80) $display("[%0t] io_wfi_wfiSafe g=%h i=%h", $time, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end
    if (!$isunknown(g_io_debugTopDown_robHeadMissInDCache) && g_io_debugTopDown_robHeadMissInDCache !== i_io_debugTopDown_robHeadMissInDCache) begin errors++;
      if(errors<=80) $display("[%0t] io_debugTopDown_robHeadMissInDCache g=%h i=%h", $time, g_io_debugTopDown_robHeadMissInDCache, i_io_debugTopDown_robHeadMissInDCache); end
    if (!$isunknown(g_io_l1Miss) && g_io_l1Miss !== i_io_l1Miss) begin errors++;
      if(errors<=80) $display("[%0t] io_l1Miss g=%h i=%h", $time, g_io_l1Miss, i_io_l1Miss); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
  end
  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
