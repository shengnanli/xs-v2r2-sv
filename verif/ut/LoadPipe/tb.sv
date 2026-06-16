// 自动生成：scripts/gen_loadpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_lsu_req_valid;
  logic [4:0] io_lsu_req_bits_cmd;
  logic [49:0] io_lsu_req_bits_vaddr;
  logic [49:0] io_lsu_req_bits_vaddr_dup;
  logic [3:0] io_lsu_req_bits_instrtype;
  logic io_lsu_req_bits_isFirstIssue;
  logic io_lsu_req_bits_lqIdx_flag;
  logic [6:0] io_lsu_req_bits_lqIdx_value;
  logic io_lsu_s1_kill;
  logic io_lsu_s2_kill;
  logic [2:0] io_lsu_pf_source;
  logic [47:0] io_lsu_s1_paddr_dup_lsu;
  logic [47:0] io_lsu_s1_paddr_dup_dcache;
  logic io_load128Req;
  logic [1:0] io_meta_resp_0_coh_state;
  logic [1:0] io_meta_resp_1_coh_state;
  logic [1:0] io_meta_resp_2_coh_state;
  logic [1:0] io_meta_resp_3_coh_state;
  logic io_extra_meta_resp_0_error;
  logic [2:0] io_extra_meta_resp_0_prefetch;
  logic io_extra_meta_resp_0_access;
  logic io_extra_meta_resp_1_error;
  logic [2:0] io_extra_meta_resp_1_prefetch;
  logic io_extra_meta_resp_1_access;
  logic io_extra_meta_resp_2_error;
  logic [2:0] io_extra_meta_resp_2_prefetch;
  logic io_extra_meta_resp_2_access;
  logic io_extra_meta_resp_3_error;
  logic [2:0] io_extra_meta_resp_3_prefetch;
  logic io_extra_meta_resp_3_access;
  logic io_tag_read_ready;
  logic [42:0] io_tag_resp_0;
  logic [42:0] io_tag_resp_1;
  logic [42:0] io_tag_resp_2;
  logic [42:0] io_tag_resp_3;
  logic io_banked_data_read_ready;
  logic [63:0] io_banked_data_resp_0_raw_data;
  logic [63:0] io_banked_data_resp_1_raw_data;
  logic io_read_error_delayed_0;
  logic io_read_error_delayed_1;
  logic io_bank_conflict_slow;
  logic io_miss_req_ready;
  logic [3:0] io_miss_resp_id;
  logic io_miss_resp_handled;
  logic io_miss_resp_merged;
  logic io_wbq_block_miss_req;
  logic io_occupy_fail;
  logic io_disable_ld_fast_wakeup;
  logic io_pseudo_error_valid;
  logic io_pseudo_error_bits_0_valid;
  logic [63:0] io_pseudo_error_bits_0_mask;
  logic io_bloom_filter_query_resp_valid;
  logic io_bloom_filter_query_resp_bits_res;
  logic io_counter_filter_query_resp;
  wire g_io_lsu_req_ready;
  wire i_io_lsu_req_ready;
  wire g_io_lsu_resp_valid;
  wire i_io_lsu_resp_valid;
  wire [127:0] g_io_lsu_resp_bits_data;
  wire [127:0] i_io_lsu_resp_bits_data;
  wire [127:0] g_io_lsu_resp_bits_data_delayed;
  wire [127:0] i_io_lsu_resp_bits_data_delayed;
  wire g_io_lsu_resp_bits_miss;
  wire i_io_lsu_resp_bits_miss;
  wire [3:0] g_io_lsu_resp_bits_mshr_id;
  wire [3:0] i_io_lsu_resp_bits_mshr_id;
  wire [2:0] g_io_lsu_resp_bits_meta_prefetch;
  wire [2:0] i_io_lsu_resp_bits_meta_prefetch;
  wire g_io_lsu_resp_bits_handled;
  wire i_io_lsu_resp_bits_handled;
  wire g_io_lsu_resp_bits_error_delayed;
  wire i_io_lsu_resp_bits_error_delayed;
  wire g_io_lsu_s2_bank_conflict;
  wire i_io_lsu_s2_bank_conflict;
  wire g_io_lsu_s2_mq_nack;
  wire i_io_lsu_s2_mq_nack;
  wire g_io_meta_read_valid;
  wire i_io_meta_read_valid;
  wire [7:0] g_io_meta_read_bits_idx;
  wire [7:0] i_io_meta_read_bits_idx;
  wire g_io_tag_read_valid;
  wire i_io_tag_read_valid;
  wire [7:0] g_io_tag_read_bits_idx;
  wire [7:0] i_io_tag_read_bits_idx;
  wire g_io_banked_data_read_valid;
  wire i_io_banked_data_read_valid;
  wire [3:0] g_io_banked_data_read_bits_way_en;
  wire [3:0] i_io_banked_data_read_bits_way_en;
  wire [47:0] g_io_banked_data_read_bits_addr;
  wire [47:0] i_io_banked_data_read_bits_addr;
  wire [47:0] g_io_banked_data_read_bits_addr_dup;
  wire [47:0] i_io_banked_data_read_bits_addr_dup;
  wire [7:0] g_io_banked_data_read_bits_bankMask;
  wire [7:0] i_io_banked_data_read_bits_bankMask;
  wire g_io_banked_data_read_bits_lqIdx_flag;
  wire i_io_banked_data_read_bits_lqIdx_flag;
  wire [6:0] g_io_banked_data_read_bits_lqIdx_value;
  wire [6:0] i_io_banked_data_read_bits_lqIdx_value;
  wire g_io_is128Req;
  wire i_io_is128Req;
  wire g_io_access_flag_write_valid;
  wire i_io_access_flag_write_valid;
  wire [7:0] g_io_access_flag_write_bits_idx;
  wire [7:0] i_io_access_flag_write_bits_idx;
  wire [3:0] g_io_access_flag_write_bits_way_en;
  wire [3:0] i_io_access_flag_write_bits_way_en;
  wire g_io_prefetch_flag_write_valid;
  wire i_io_prefetch_flag_write_valid;
  wire [7:0] g_io_prefetch_flag_write_bits_idx;
  wire [7:0] i_io_prefetch_flag_write_bits_idx;
  wire [3:0] g_io_prefetch_flag_write_bits_way_en;
  wire [3:0] i_io_prefetch_flag_write_bits_way_en;
  wire g_io_miss_req_valid;
  wire i_io_miss_req_valid;
  wire [3:0] g_io_miss_req_bits_source;
  wire [3:0] i_io_miss_req_bits_source;
  wire [2:0] g_io_miss_req_bits_pf_source;
  wire [2:0] i_io_miss_req_bits_pf_source;
  wire [4:0] g_io_miss_req_bits_cmd;
  wire [4:0] i_io_miss_req_bits_cmd;
  wire [47:0] g_io_miss_req_bits_addr;
  wire [47:0] i_io_miss_req_bits_addr;
  wire [49:0] g_io_miss_req_bits_vaddr;
  wire [49:0] i_io_miss_req_bits_vaddr;
  wire [1:0] g_io_miss_req_bits_req_coh_state;
  wire [1:0] i_io_miss_req_bits_req_coh_state;
  wire g_io_miss_req_bits_isBtoT;
  wire i_io_miss_req_bits_isBtoT;
  wire [3:0] g_io_miss_req_bits_occupy_way;
  wire [3:0] i_io_miss_req_bits_occupy_way;
  wire g_io_miss_req_bits_cancel;
  wire i_io_miss_req_bits_cancel;
  wire g_io_wbq_conflict_check_valid;
  wire i_io_wbq_conflict_check_valid;
  wire [47:0] g_io_wbq_conflict_check_bits;
  wire [47:0] i_io_wbq_conflict_check_bits;
  wire g_io_replace_access_valid;
  wire i_io_replace_access_valid;
  wire [7:0] g_io_replace_access_bits_set;
  wire [7:0] i_io_replace_access_bits_set;
  wire [1:0] g_io_replace_access_bits_way;
  wire [1:0] i_io_replace_access_bits_way;
  wire [7:0] g_io_occupy_set;
  wire [7:0] i_io_occupy_set;
  wire g_io_error_valid;
  wire i_io_error_valid;
  wire [47:0] g_io_error_bits_paddr;
  wire [47:0] i_io_error_bits_paddr;
  wire g_io_error_bits_report_to_beu;
  wire i_io_error_bits_report_to_beu;
  wire g_io_pseudo_tag_error_inj_done;
  wire i_io_pseudo_tag_error_inj_done;
  wire g_io_pseudo_data_error_inj_done;
  wire i_io_pseudo_data_error_inj_done;
  wire g_io_prefetch_info_naive_total_prefetch;
  wire i_io_prefetch_info_naive_total_prefetch;
  wire g_io_prefetch_info_naive_late_hit_prefetch;
  wire i_io_prefetch_info_naive_late_hit_prefetch;
  wire g_io_prefetch_info_naive_late_prefetch_hit;
  wire i_io_prefetch_info_naive_late_prefetch_hit;
  wire g_io_prefetch_info_naive_late_load_hit;
  wire i_io_prefetch_info_naive_late_load_hit;
  wire g_io_prefetch_info_naive_useful_prefetch;
  wire i_io_prefetch_info_naive_useful_prefetch;
  wire g_io_prefetch_info_naive_prefetch_hit;
  wire i_io_prefetch_info_naive_prefetch_hit;
  wire g_io_prefetch_info_fdp_useful_prefetch;
  wire i_io_prefetch_info_fdp_useful_prefetch;
  wire g_io_prefetch_info_fdp_demand_miss;
  wire i_io_prefetch_info_fdp_demand_miss;
  wire g_io_prefetch_info_fdp_pollution;
  wire i_io_prefetch_info_fdp_pollution;
  wire g_io_bloom_filter_query_query_valid;
  wire i_io_bloom_filter_query_query_valid;
  wire [11:0] g_io_bloom_filter_query_query_bits_addr;
  wire [11:0] i_io_bloom_filter_query_query_bits_addr;
  wire g_io_counter_filter_query_req_valid;
  wire i_io_counter_filter_query_req_valid;
  wire [7:0] g_io_counter_filter_query_req_bits_idx;
  wire [7:0] i_io_counter_filter_query_req_bits_idx;
  wire [1:0] g_io_counter_filter_query_req_bits_way;
  wire [1:0] i_io_counter_filter_query_req_bits_way;
  wire g_io_counter_filter_enq_valid;
  wire i_io_counter_filter_enq_valid;
  wire [7:0] g_io_counter_filter_enq_bits_idx;
  wire [7:0] i_io_counter_filter_enq_bits_idx;
  wire [1:0] g_io_counter_filter_enq_bits_way;
  wire [1:0] i_io_counter_filter_enq_bits_way;
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
  LoadPipe    u_g (.clock(clk), .reset(rst), .io_lsu_req_valid(io_lsu_req_valid), .io_lsu_req_bits_cmd(io_lsu_req_bits_cmd), .io_lsu_req_bits_vaddr(io_lsu_req_bits_vaddr), .io_lsu_req_bits_vaddr_dup(io_lsu_req_bits_vaddr_dup), .io_lsu_req_bits_instrtype(io_lsu_req_bits_instrtype), .io_lsu_req_bits_isFirstIssue(io_lsu_req_bits_isFirstIssue), .io_lsu_req_bits_lqIdx_flag(io_lsu_req_bits_lqIdx_flag), .io_lsu_req_bits_lqIdx_value(io_lsu_req_bits_lqIdx_value), .io_lsu_s1_kill(io_lsu_s1_kill), .io_lsu_s2_kill(io_lsu_s2_kill), .io_lsu_pf_source(io_lsu_pf_source), .io_lsu_s1_paddr_dup_lsu(io_lsu_s1_paddr_dup_lsu), .io_lsu_s1_paddr_dup_dcache(io_lsu_s1_paddr_dup_dcache), .io_load128Req(io_load128Req), .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state), .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state), .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state), .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state), .io_extra_meta_resp_0_error(io_extra_meta_resp_0_error), .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch), .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access), .io_extra_meta_resp_1_error(io_extra_meta_resp_1_error), .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch), .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access), .io_extra_meta_resp_2_error(io_extra_meta_resp_2_error), .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch), .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access), .io_extra_meta_resp_3_error(io_extra_meta_resp_3_error), .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch), .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access), .io_tag_read_ready(io_tag_read_ready), .io_tag_resp_0(io_tag_resp_0), .io_tag_resp_1(io_tag_resp_1), .io_tag_resp_2(io_tag_resp_2), .io_tag_resp_3(io_tag_resp_3), .io_banked_data_read_ready(io_banked_data_read_ready), .io_banked_data_resp_0_raw_data(io_banked_data_resp_0_raw_data), .io_banked_data_resp_1_raw_data(io_banked_data_resp_1_raw_data), .io_read_error_delayed_0(io_read_error_delayed_0), .io_read_error_delayed_1(io_read_error_delayed_1), .io_bank_conflict_slow(io_bank_conflict_slow), .io_miss_req_ready(io_miss_req_ready), .io_miss_resp_id(io_miss_resp_id), .io_miss_resp_handled(io_miss_resp_handled), .io_miss_resp_merged(io_miss_resp_merged), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_occupy_fail(io_occupy_fail), .io_disable_ld_fast_wakeup(io_disable_ld_fast_wakeup), .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid), .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask), .io_bloom_filter_query_resp_valid(io_bloom_filter_query_resp_valid), .io_bloom_filter_query_resp_bits_res(io_bloom_filter_query_resp_bits_res), .io_counter_filter_query_resp(io_counter_filter_query_resp), .io_lsu_req_ready(g_io_lsu_req_ready), .io_lsu_resp_valid(g_io_lsu_resp_valid), .io_lsu_resp_bits_data(g_io_lsu_resp_bits_data), .io_lsu_resp_bits_data_delayed(g_io_lsu_resp_bits_data_delayed), .io_lsu_resp_bits_miss(g_io_lsu_resp_bits_miss), .io_lsu_resp_bits_mshr_id(g_io_lsu_resp_bits_mshr_id), .io_lsu_resp_bits_meta_prefetch(g_io_lsu_resp_bits_meta_prefetch), .io_lsu_resp_bits_handled(g_io_lsu_resp_bits_handled), .io_lsu_resp_bits_error_delayed(g_io_lsu_resp_bits_error_delayed), .io_lsu_s2_bank_conflict(g_io_lsu_s2_bank_conflict), .io_lsu_s2_mq_nack(g_io_lsu_s2_mq_nack), .io_meta_read_valid(g_io_meta_read_valid), .io_meta_read_bits_idx(g_io_meta_read_bits_idx), .io_tag_read_valid(g_io_tag_read_valid), .io_tag_read_bits_idx(g_io_tag_read_bits_idx), .io_banked_data_read_valid(g_io_banked_data_read_valid), .io_banked_data_read_bits_way_en(g_io_banked_data_read_bits_way_en), .io_banked_data_read_bits_addr(g_io_banked_data_read_bits_addr), .io_banked_data_read_bits_addr_dup(g_io_banked_data_read_bits_addr_dup), .io_banked_data_read_bits_bankMask(g_io_banked_data_read_bits_bankMask), .io_banked_data_read_bits_lqIdx_flag(g_io_banked_data_read_bits_lqIdx_flag), .io_banked_data_read_bits_lqIdx_value(g_io_banked_data_read_bits_lqIdx_value), .io_is128Req(g_io_is128Req), .io_access_flag_write_valid(g_io_access_flag_write_valid), .io_access_flag_write_bits_idx(g_io_access_flag_write_bits_idx), .io_access_flag_write_bits_way_en(g_io_access_flag_write_bits_way_en), .io_prefetch_flag_write_valid(g_io_prefetch_flag_write_valid), .io_prefetch_flag_write_bits_idx(g_io_prefetch_flag_write_bits_idx), .io_prefetch_flag_write_bits_way_en(g_io_prefetch_flag_write_bits_way_en), .io_miss_req_valid(g_io_miss_req_valid), .io_miss_req_bits_source(g_io_miss_req_bits_source), .io_miss_req_bits_pf_source(g_io_miss_req_bits_pf_source), .io_miss_req_bits_cmd(g_io_miss_req_bits_cmd), .io_miss_req_bits_addr(g_io_miss_req_bits_addr), .io_miss_req_bits_vaddr(g_io_miss_req_bits_vaddr), .io_miss_req_bits_req_coh_state(g_io_miss_req_bits_req_coh_state), .io_miss_req_bits_isBtoT(g_io_miss_req_bits_isBtoT), .io_miss_req_bits_occupy_way(g_io_miss_req_bits_occupy_way), .io_miss_req_bits_cancel(g_io_miss_req_bits_cancel), .io_wbq_conflict_check_valid(g_io_wbq_conflict_check_valid), .io_wbq_conflict_check_bits(g_io_wbq_conflict_check_bits), .io_replace_access_valid(g_io_replace_access_valid), .io_replace_access_bits_set(g_io_replace_access_bits_set), .io_replace_access_bits_way(g_io_replace_access_bits_way), .io_occupy_set(g_io_occupy_set), .io_error_valid(g_io_error_valid), .io_error_bits_paddr(g_io_error_bits_paddr), .io_error_bits_report_to_beu(g_io_error_bits_report_to_beu), .io_pseudo_tag_error_inj_done(g_io_pseudo_tag_error_inj_done), .io_pseudo_data_error_inj_done(g_io_pseudo_data_error_inj_done), .io_prefetch_info_naive_total_prefetch(g_io_prefetch_info_naive_total_prefetch), .io_prefetch_info_naive_late_hit_prefetch(g_io_prefetch_info_naive_late_hit_prefetch), .io_prefetch_info_naive_late_prefetch_hit(g_io_prefetch_info_naive_late_prefetch_hit), .io_prefetch_info_naive_late_load_hit(g_io_prefetch_info_naive_late_load_hit), .io_prefetch_info_naive_useful_prefetch(g_io_prefetch_info_naive_useful_prefetch), .io_prefetch_info_naive_prefetch_hit(g_io_prefetch_info_naive_prefetch_hit), .io_prefetch_info_fdp_useful_prefetch(g_io_prefetch_info_fdp_useful_prefetch), .io_prefetch_info_fdp_demand_miss(g_io_prefetch_info_fdp_demand_miss), .io_prefetch_info_fdp_pollution(g_io_prefetch_info_fdp_pollution), .io_bloom_filter_query_query_valid(g_io_bloom_filter_query_query_valid), .io_bloom_filter_query_query_bits_addr(g_io_bloom_filter_query_query_bits_addr), .io_counter_filter_query_req_valid(g_io_counter_filter_query_req_valid), .io_counter_filter_query_req_bits_idx(g_io_counter_filter_query_req_bits_idx), .io_counter_filter_query_req_bits_way(g_io_counter_filter_query_req_bits_way), .io_counter_filter_enq_valid(g_io_counter_filter_enq_valid), .io_counter_filter_enq_bits_idx(g_io_counter_filter_enq_bits_idx), .io_counter_filter_enq_bits_way(g_io_counter_filter_enq_bits_way), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value));
  LoadPipe_xs u_i (.clock(clk), .reset(rst), .io_lsu_req_valid(io_lsu_req_valid), .io_lsu_req_bits_cmd(io_lsu_req_bits_cmd), .io_lsu_req_bits_vaddr(io_lsu_req_bits_vaddr), .io_lsu_req_bits_vaddr_dup(io_lsu_req_bits_vaddr_dup), .io_lsu_req_bits_instrtype(io_lsu_req_bits_instrtype), .io_lsu_req_bits_isFirstIssue(io_lsu_req_bits_isFirstIssue), .io_lsu_req_bits_lqIdx_flag(io_lsu_req_bits_lqIdx_flag), .io_lsu_req_bits_lqIdx_value(io_lsu_req_bits_lqIdx_value), .io_lsu_s1_kill(io_lsu_s1_kill), .io_lsu_s2_kill(io_lsu_s2_kill), .io_lsu_pf_source(io_lsu_pf_source), .io_lsu_s1_paddr_dup_lsu(io_lsu_s1_paddr_dup_lsu), .io_lsu_s1_paddr_dup_dcache(io_lsu_s1_paddr_dup_dcache), .io_load128Req(io_load128Req), .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state), .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state), .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state), .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state), .io_extra_meta_resp_0_error(io_extra_meta_resp_0_error), .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch), .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access), .io_extra_meta_resp_1_error(io_extra_meta_resp_1_error), .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch), .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access), .io_extra_meta_resp_2_error(io_extra_meta_resp_2_error), .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch), .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access), .io_extra_meta_resp_3_error(io_extra_meta_resp_3_error), .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch), .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access), .io_tag_read_ready(io_tag_read_ready), .io_tag_resp_0(io_tag_resp_0), .io_tag_resp_1(io_tag_resp_1), .io_tag_resp_2(io_tag_resp_2), .io_tag_resp_3(io_tag_resp_3), .io_banked_data_read_ready(io_banked_data_read_ready), .io_banked_data_resp_0_raw_data(io_banked_data_resp_0_raw_data), .io_banked_data_resp_1_raw_data(io_banked_data_resp_1_raw_data), .io_read_error_delayed_0(io_read_error_delayed_0), .io_read_error_delayed_1(io_read_error_delayed_1), .io_bank_conflict_slow(io_bank_conflict_slow), .io_miss_req_ready(io_miss_req_ready), .io_miss_resp_id(io_miss_resp_id), .io_miss_resp_handled(io_miss_resp_handled), .io_miss_resp_merged(io_miss_resp_merged), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_occupy_fail(io_occupy_fail), .io_disable_ld_fast_wakeup(io_disable_ld_fast_wakeup), .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid), .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask), .io_bloom_filter_query_resp_valid(io_bloom_filter_query_resp_valid), .io_bloom_filter_query_resp_bits_res(io_bloom_filter_query_resp_bits_res), .io_counter_filter_query_resp(io_counter_filter_query_resp), .io_lsu_req_ready(i_io_lsu_req_ready), .io_lsu_resp_valid(i_io_lsu_resp_valid), .io_lsu_resp_bits_data(i_io_lsu_resp_bits_data), .io_lsu_resp_bits_data_delayed(i_io_lsu_resp_bits_data_delayed), .io_lsu_resp_bits_miss(i_io_lsu_resp_bits_miss), .io_lsu_resp_bits_mshr_id(i_io_lsu_resp_bits_mshr_id), .io_lsu_resp_bits_meta_prefetch(i_io_lsu_resp_bits_meta_prefetch), .io_lsu_resp_bits_handled(i_io_lsu_resp_bits_handled), .io_lsu_resp_bits_error_delayed(i_io_lsu_resp_bits_error_delayed), .io_lsu_s2_bank_conflict(i_io_lsu_s2_bank_conflict), .io_lsu_s2_mq_nack(i_io_lsu_s2_mq_nack), .io_meta_read_valid(i_io_meta_read_valid), .io_meta_read_bits_idx(i_io_meta_read_bits_idx), .io_tag_read_valid(i_io_tag_read_valid), .io_tag_read_bits_idx(i_io_tag_read_bits_idx), .io_banked_data_read_valid(i_io_banked_data_read_valid), .io_banked_data_read_bits_way_en(i_io_banked_data_read_bits_way_en), .io_banked_data_read_bits_addr(i_io_banked_data_read_bits_addr), .io_banked_data_read_bits_addr_dup(i_io_banked_data_read_bits_addr_dup), .io_banked_data_read_bits_bankMask(i_io_banked_data_read_bits_bankMask), .io_banked_data_read_bits_lqIdx_flag(i_io_banked_data_read_bits_lqIdx_flag), .io_banked_data_read_bits_lqIdx_value(i_io_banked_data_read_bits_lqIdx_value), .io_is128Req(i_io_is128Req), .io_access_flag_write_valid(i_io_access_flag_write_valid), .io_access_flag_write_bits_idx(i_io_access_flag_write_bits_idx), .io_access_flag_write_bits_way_en(i_io_access_flag_write_bits_way_en), .io_prefetch_flag_write_valid(i_io_prefetch_flag_write_valid), .io_prefetch_flag_write_bits_idx(i_io_prefetch_flag_write_bits_idx), .io_prefetch_flag_write_bits_way_en(i_io_prefetch_flag_write_bits_way_en), .io_miss_req_valid(i_io_miss_req_valid), .io_miss_req_bits_source(i_io_miss_req_bits_source), .io_miss_req_bits_pf_source(i_io_miss_req_bits_pf_source), .io_miss_req_bits_cmd(i_io_miss_req_bits_cmd), .io_miss_req_bits_addr(i_io_miss_req_bits_addr), .io_miss_req_bits_vaddr(i_io_miss_req_bits_vaddr), .io_miss_req_bits_req_coh_state(i_io_miss_req_bits_req_coh_state), .io_miss_req_bits_isBtoT(i_io_miss_req_bits_isBtoT), .io_miss_req_bits_occupy_way(i_io_miss_req_bits_occupy_way), .io_miss_req_bits_cancel(i_io_miss_req_bits_cancel), .io_wbq_conflict_check_valid(i_io_wbq_conflict_check_valid), .io_wbq_conflict_check_bits(i_io_wbq_conflict_check_bits), .io_replace_access_valid(i_io_replace_access_valid), .io_replace_access_bits_set(i_io_replace_access_bits_set), .io_replace_access_bits_way(i_io_replace_access_bits_way), .io_occupy_set(i_io_occupy_set), .io_error_valid(i_io_error_valid), .io_error_bits_paddr(i_io_error_bits_paddr), .io_error_bits_report_to_beu(i_io_error_bits_report_to_beu), .io_pseudo_tag_error_inj_done(i_io_pseudo_tag_error_inj_done), .io_pseudo_data_error_inj_done(i_io_pseudo_data_error_inj_done), .io_prefetch_info_naive_total_prefetch(i_io_prefetch_info_naive_total_prefetch), .io_prefetch_info_naive_late_hit_prefetch(i_io_prefetch_info_naive_late_hit_prefetch), .io_prefetch_info_naive_late_prefetch_hit(i_io_prefetch_info_naive_late_prefetch_hit), .io_prefetch_info_naive_late_load_hit(i_io_prefetch_info_naive_late_load_hit), .io_prefetch_info_naive_useful_prefetch(i_io_prefetch_info_naive_useful_prefetch), .io_prefetch_info_naive_prefetch_hit(i_io_prefetch_info_naive_prefetch_hit), .io_prefetch_info_fdp_useful_prefetch(i_io_prefetch_info_fdp_useful_prefetch), .io_prefetch_info_fdp_demand_miss(i_io_prefetch_info_fdp_demand_miss), .io_prefetch_info_fdp_pollution(i_io_prefetch_info_fdp_pollution), .io_bloom_filter_query_query_valid(i_io_bloom_filter_query_query_valid), .io_bloom_filter_query_query_bits_addr(i_io_bloom_filter_query_query_bits_addr), .io_counter_filter_query_req_valid(i_io_counter_filter_query_req_valid), .io_counter_filter_query_req_bits_idx(i_io_counter_filter_query_req_bits_idx), .io_counter_filter_query_req_bits_way(i_io_counter_filter_query_req_bits_way), .io_counter_filter_enq_valid(i_io_counter_filter_enq_valid), .io_counter_filter_enq_bits_idx(i_io_counter_filter_enq_bits_idx), .io_counter_filter_enq_bits_way(i_io_counter_filter_enq_bits_way), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value));
  always @(negedge clk) begin
    if (rst) begin
      io_lsu_req_valid <= 1'b0;
    end else begin
      io_lsu_req_valid <= ($urandom_range(0,4)!=0);
      io_lsu_req_bits_cmd <= 5'($urandom_range(0,15));
      io_lsu_req_bits_vaddr <= 50'({$urandom(), $urandom()});
      io_lsu_req_bits_vaddr_dup <= 50'({$urandom(), $urandom()});
      io_lsu_req_bits_instrtype <= 4'($urandom_range(0,3));
      io_lsu_req_bits_isFirstIssue <= $urandom_range(0,1);
      io_lsu_req_bits_lqIdx_flag <= $urandom_range(0,1);
      io_lsu_req_bits_lqIdx_value <= 7'($urandom);
      io_lsu_s1_kill <= ($urandom_range(0,7)==0);
      io_lsu_s2_kill <= ($urandom_range(0,7)==0);
      io_lsu_pf_source <= 3'($urandom);
      io_lsu_s1_paddr_dup_lsu <= {34'h0, 2'($urandom_range(0,3)), 12'($urandom)};
      io_lsu_s1_paddr_dup_dcache <= {34'h0, 2'($urandom_range(0,3)), 12'($urandom)};
      io_load128Req <= ($urandom_range(0,3)==0);
      io_meta_resp_0_coh_state <= 2'($urandom_range(0,3));
      io_meta_resp_1_coh_state <= 2'($urandom_range(0,3));
      io_meta_resp_2_coh_state <= 2'($urandom_range(0,3));
      io_meta_resp_3_coh_state <= 2'($urandom_range(0,3));
      io_extra_meta_resp_0_error <= $urandom_range(0,1);
      io_extra_meta_resp_0_prefetch <= 3'($urandom);
      io_extra_meta_resp_0_access <= $urandom_range(0,1);
      io_extra_meta_resp_1_error <= $urandom_range(0,1);
      io_extra_meta_resp_1_prefetch <= 3'($urandom);
      io_extra_meta_resp_1_access <= $urandom_range(0,1);
      io_extra_meta_resp_2_error <= $urandom_range(0,1);
      io_extra_meta_resp_2_prefetch <= 3'($urandom);
      io_extra_meta_resp_2_access <= $urandom_range(0,1);
      io_extra_meta_resp_3_error <= $urandom_range(0,1);
      io_extra_meta_resp_3_prefetch <= 3'($urandom);
      io_extra_meta_resp_3_access <= $urandom_range(0,1);
      io_tag_read_ready <= ($urandom_range(0,4)!=0);
      io_tag_resp_0 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      io_tag_resp_1 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      io_tag_resp_2 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      io_tag_resp_3 <= {7'($urandom), 34'h0, 2'($urandom_range(0,3))};
      io_banked_data_read_ready <= ($urandom_range(0,4)!=0);
      io_banked_data_resp_0_raw_data <= 64'({$urandom(), $urandom()});
      io_banked_data_resp_1_raw_data <= 64'({$urandom(), $urandom()});
      io_read_error_delayed_0 <= $urandom_range(0,1);
      io_read_error_delayed_1 <= $urandom_range(0,1);
      io_bank_conflict_slow <= ($urandom_range(0,5)==0);
      io_miss_req_ready <= ($urandom_range(0,4)!=0);
      io_miss_resp_id <= 4'($urandom);
      io_miss_resp_handled <= $urandom_range(0,1);
      io_miss_resp_merged <= $urandom_range(0,1);
      io_wbq_block_miss_req <= ($urandom_range(0,5)==0);
      io_occupy_fail <= ($urandom_range(0,5)==0);
      io_disable_ld_fast_wakeup <= $urandom_range(0,1);
      io_pseudo_error_valid <= $urandom_range(0,1);
      io_pseudo_error_bits_0_valid <= $urandom_range(0,1);
      io_pseudo_error_bits_0_mask <= 64'({$urandom(), $urandom()});
      io_bloom_filter_query_resp_valid <= $urandom_range(0,1);
      io_bloom_filter_query_resp_bits_res <= $urandom_range(0,1);
      io_counter_filter_query_resp <= $urandom_range(0,1);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_lsu_req_ready) && g_io_lsu_req_ready !== i_io_lsu_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_req_ready g=%h i=%h", $time, g_io_lsu_req_ready, i_io_lsu_req_ready); end
    if (!$isunknown(g_io_lsu_resp_valid) && g_io_lsu_resp_valid !== i_io_lsu_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_valid g=%h i=%h", $time, g_io_lsu_resp_valid, i_io_lsu_resp_valid); end
    if (!$isunknown(g_io_lsu_resp_bits_data) && g_io_lsu_resp_bits_data !== i_io_lsu_resp_bits_data) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_data g=%h i=%h", $time, g_io_lsu_resp_bits_data, i_io_lsu_resp_bits_data); end
    if (!$isunknown(g_io_lsu_resp_bits_data_delayed) && g_io_lsu_resp_bits_data_delayed !== i_io_lsu_resp_bits_data_delayed) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_data_delayed g=%h i=%h", $time, g_io_lsu_resp_bits_data_delayed, i_io_lsu_resp_bits_data_delayed); end
    if (!$isunknown(g_io_lsu_resp_bits_miss) && g_io_lsu_resp_bits_miss !== i_io_lsu_resp_bits_miss) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_miss g=%h i=%h", $time, g_io_lsu_resp_bits_miss, i_io_lsu_resp_bits_miss); end
    if (!$isunknown(g_io_lsu_resp_bits_mshr_id) && g_io_lsu_resp_bits_mshr_id !== i_io_lsu_resp_bits_mshr_id) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_mshr_id g=%h i=%h", $time, g_io_lsu_resp_bits_mshr_id, i_io_lsu_resp_bits_mshr_id); end
    if (!$isunknown(g_io_lsu_resp_bits_meta_prefetch) && g_io_lsu_resp_bits_meta_prefetch !== i_io_lsu_resp_bits_meta_prefetch) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_meta_prefetch g=%h i=%h", $time, g_io_lsu_resp_bits_meta_prefetch, i_io_lsu_resp_bits_meta_prefetch); end
    if (!$isunknown(g_io_lsu_resp_bits_handled) && g_io_lsu_resp_bits_handled !== i_io_lsu_resp_bits_handled) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_handled g=%h i=%h", $time, g_io_lsu_resp_bits_handled, i_io_lsu_resp_bits_handled); end
    if (!$isunknown(g_io_lsu_resp_bits_error_delayed) && g_io_lsu_resp_bits_error_delayed !== i_io_lsu_resp_bits_error_delayed) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_resp_bits_error_delayed g=%h i=%h", $time, g_io_lsu_resp_bits_error_delayed, i_io_lsu_resp_bits_error_delayed); end
    if (!$isunknown(g_io_lsu_s2_bank_conflict) && g_io_lsu_s2_bank_conflict !== i_io_lsu_s2_bank_conflict) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_s2_bank_conflict g=%h i=%h", $time, g_io_lsu_s2_bank_conflict, i_io_lsu_s2_bank_conflict); end
    if (!$isunknown(g_io_lsu_s2_mq_nack) && g_io_lsu_s2_mq_nack !== i_io_lsu_s2_mq_nack) begin errors++;
      if(errors<=60) $display("[%0t] io_lsu_s2_mq_nack g=%h i=%h", $time, g_io_lsu_s2_mq_nack, i_io_lsu_s2_mq_nack); end
    if (!$isunknown(g_io_meta_read_valid) && g_io_meta_read_valid !== i_io_meta_read_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_read_valid g=%h i=%h", $time, g_io_meta_read_valid, i_io_meta_read_valid); end
    if (!$isunknown(g_io_meta_read_bits_idx) && g_io_meta_read_bits_idx !== i_io_meta_read_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_read_bits_idx g=%h i=%h", $time, g_io_meta_read_bits_idx, i_io_meta_read_bits_idx); end
    if (!$isunknown(g_io_tag_read_valid) && g_io_tag_read_valid !== i_io_tag_read_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_read_valid g=%h i=%h", $time, g_io_tag_read_valid, i_io_tag_read_valid); end
    if (!$isunknown(g_io_tag_read_bits_idx) && g_io_tag_read_bits_idx !== i_io_tag_read_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_read_bits_idx g=%h i=%h", $time, g_io_tag_read_bits_idx, i_io_tag_read_bits_idx); end
    if (!$isunknown(g_io_banked_data_read_valid) && g_io_banked_data_read_valid !== i_io_banked_data_read_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_valid g=%h i=%h", $time, g_io_banked_data_read_valid, i_io_banked_data_read_valid); end
    if (!$isunknown(g_io_banked_data_read_bits_way_en) && g_io_banked_data_read_bits_way_en !== i_io_banked_data_read_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_way_en g=%h i=%h", $time, g_io_banked_data_read_bits_way_en, i_io_banked_data_read_bits_way_en); end
    if (!$isunknown(g_io_banked_data_read_bits_addr) && g_io_banked_data_read_bits_addr !== i_io_banked_data_read_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_addr g=%h i=%h", $time, g_io_banked_data_read_bits_addr, i_io_banked_data_read_bits_addr); end
    if (!$isunknown(g_io_banked_data_read_bits_addr_dup) && g_io_banked_data_read_bits_addr_dup !== i_io_banked_data_read_bits_addr_dup) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_addr_dup g=%h i=%h", $time, g_io_banked_data_read_bits_addr_dup, i_io_banked_data_read_bits_addr_dup); end
    if (!$isunknown(g_io_banked_data_read_bits_bankMask) && g_io_banked_data_read_bits_bankMask !== i_io_banked_data_read_bits_bankMask) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_bankMask g=%h i=%h", $time, g_io_banked_data_read_bits_bankMask, i_io_banked_data_read_bits_bankMask); end
    if (!$isunknown(g_io_banked_data_read_bits_lqIdx_flag) && g_io_banked_data_read_bits_lqIdx_flag !== i_io_banked_data_read_bits_lqIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_lqIdx_flag g=%h i=%h", $time, g_io_banked_data_read_bits_lqIdx_flag, i_io_banked_data_read_bits_lqIdx_flag); end
    if (!$isunknown(g_io_banked_data_read_bits_lqIdx_value) && g_io_banked_data_read_bits_lqIdx_value !== i_io_banked_data_read_bits_lqIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_banked_data_read_bits_lqIdx_value g=%h i=%h", $time, g_io_banked_data_read_bits_lqIdx_value, i_io_banked_data_read_bits_lqIdx_value); end
    if (!$isunknown(g_io_is128Req) && g_io_is128Req !== i_io_is128Req) begin errors++;
      if(errors<=60) $display("[%0t] io_is128Req g=%h i=%h", $time, g_io_is128Req, i_io_is128Req); end
    if (!$isunknown(g_io_access_flag_write_valid) && g_io_access_flag_write_valid !== i_io_access_flag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_valid g=%h i=%h", $time, g_io_access_flag_write_valid, i_io_access_flag_write_valid); end
    if (!$isunknown(g_io_access_flag_write_bits_idx) && g_io_access_flag_write_bits_idx !== i_io_access_flag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_bits_idx g=%h i=%h", $time, g_io_access_flag_write_bits_idx, i_io_access_flag_write_bits_idx); end
    if (!$isunknown(g_io_access_flag_write_bits_way_en) && g_io_access_flag_write_bits_way_en !== i_io_access_flag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_bits_way_en g=%h i=%h", $time, g_io_access_flag_write_bits_way_en, i_io_access_flag_write_bits_way_en); end
    if (!$isunknown(g_io_prefetch_flag_write_valid) && g_io_prefetch_flag_write_valid !== i_io_prefetch_flag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_valid g=%h i=%h", $time, g_io_prefetch_flag_write_valid, i_io_prefetch_flag_write_valid); end
    if (!$isunknown(g_io_prefetch_flag_write_bits_idx) && g_io_prefetch_flag_write_bits_idx !== i_io_prefetch_flag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_bits_idx g=%h i=%h", $time, g_io_prefetch_flag_write_bits_idx, i_io_prefetch_flag_write_bits_idx); end
    if (!$isunknown(g_io_prefetch_flag_write_bits_way_en) && g_io_prefetch_flag_write_bits_way_en !== i_io_prefetch_flag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_bits_way_en g=%h i=%h", $time, g_io_prefetch_flag_write_bits_way_en, i_io_prefetch_flag_write_bits_way_en); end
    if (!$isunknown(g_io_miss_req_valid) && g_io_miss_req_valid !== i_io_miss_req_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_valid g=%h i=%h", $time, g_io_miss_req_valid, i_io_miss_req_valid); end
    if (!$isunknown(g_io_miss_req_bits_source) && g_io_miss_req_bits_source !== i_io_miss_req_bits_source) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_source g=%h i=%h", $time, g_io_miss_req_bits_source, i_io_miss_req_bits_source); end
    if (!$isunknown(g_io_miss_req_bits_pf_source) && g_io_miss_req_bits_pf_source !== i_io_miss_req_bits_pf_source) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_pf_source g=%h i=%h", $time, g_io_miss_req_bits_pf_source, i_io_miss_req_bits_pf_source); end
    if (!$isunknown(g_io_miss_req_bits_cmd) && g_io_miss_req_bits_cmd !== i_io_miss_req_bits_cmd) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_cmd g=%h i=%h", $time, g_io_miss_req_bits_cmd, i_io_miss_req_bits_cmd); end
    if (!$isunknown(g_io_miss_req_bits_addr) && g_io_miss_req_bits_addr !== i_io_miss_req_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_addr g=%h i=%h", $time, g_io_miss_req_bits_addr, i_io_miss_req_bits_addr); end
    if (!$isunknown(g_io_miss_req_bits_vaddr) && g_io_miss_req_bits_vaddr !== i_io_miss_req_bits_vaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_vaddr g=%h i=%h", $time, g_io_miss_req_bits_vaddr, i_io_miss_req_bits_vaddr); end
    if (!$isunknown(g_io_miss_req_bits_req_coh_state) && g_io_miss_req_bits_req_coh_state !== i_io_miss_req_bits_req_coh_state) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_req_coh_state g=%h i=%h", $time, g_io_miss_req_bits_req_coh_state, i_io_miss_req_bits_req_coh_state); end
    if (!$isunknown(g_io_miss_req_bits_isBtoT) && g_io_miss_req_bits_isBtoT !== i_io_miss_req_bits_isBtoT) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_isBtoT g=%h i=%h", $time, g_io_miss_req_bits_isBtoT, i_io_miss_req_bits_isBtoT); end
    if (!$isunknown(g_io_miss_req_bits_occupy_way) && g_io_miss_req_bits_occupy_way !== i_io_miss_req_bits_occupy_way) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_occupy_way g=%h i=%h", $time, g_io_miss_req_bits_occupy_way, i_io_miss_req_bits_occupy_way); end
    if (!$isunknown(g_io_miss_req_bits_cancel) && g_io_miss_req_bits_cancel !== i_io_miss_req_bits_cancel) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_cancel g=%h i=%h", $time, g_io_miss_req_bits_cancel, i_io_miss_req_bits_cancel); end
    if (!$isunknown(g_io_wbq_conflict_check_valid) && g_io_wbq_conflict_check_valid !== i_io_wbq_conflict_check_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_wbq_conflict_check_valid g=%h i=%h", $time, g_io_wbq_conflict_check_valid, i_io_wbq_conflict_check_valid); end
    if (!$isunknown(g_io_wbq_conflict_check_bits) && g_io_wbq_conflict_check_bits !== i_io_wbq_conflict_check_bits) begin errors++;
      if(errors<=60) $display("[%0t] io_wbq_conflict_check_bits g=%h i=%h", $time, g_io_wbq_conflict_check_bits, i_io_wbq_conflict_check_bits); end
    if (!$isunknown(g_io_replace_access_valid) && g_io_replace_access_valid !== i_io_replace_access_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_valid g=%h i=%h", $time, g_io_replace_access_valid, i_io_replace_access_valid); end
    if (!$isunknown(g_io_replace_access_bits_set) && g_io_replace_access_bits_set !== i_io_replace_access_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_bits_set g=%h i=%h", $time, g_io_replace_access_bits_set, i_io_replace_access_bits_set); end
    if (!$isunknown(g_io_replace_access_bits_way) && g_io_replace_access_bits_way !== i_io_replace_access_bits_way) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_bits_way g=%h i=%h", $time, g_io_replace_access_bits_way, i_io_replace_access_bits_way); end
    if (!$isunknown(g_io_occupy_set) && g_io_occupy_set !== i_io_occupy_set) begin errors++;
      if(errors<=60) $display("[%0t] io_occupy_set g=%h i=%h", $time, g_io_occupy_set, i_io_occupy_set); end
    if (!$isunknown(g_io_error_valid) && g_io_error_valid !== i_io_error_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_error_valid g=%h i=%h", $time, g_io_error_valid, i_io_error_valid); end
    if (!$isunknown(g_io_error_bits_paddr) && g_io_error_bits_paddr !== i_io_error_bits_paddr) begin errors++;
      if(errors<=60) $display("[%0t] io_error_bits_paddr g=%h i=%h", $time, g_io_error_bits_paddr, i_io_error_bits_paddr); end
    if (!$isunknown(g_io_error_bits_report_to_beu) && g_io_error_bits_report_to_beu !== i_io_error_bits_report_to_beu) begin errors++;
      if(errors<=60) $display("[%0t] io_error_bits_report_to_beu g=%h i=%h", $time, g_io_error_bits_report_to_beu, i_io_error_bits_report_to_beu); end
    if (!$isunknown(g_io_pseudo_tag_error_inj_done) && g_io_pseudo_tag_error_inj_done !== i_io_pseudo_tag_error_inj_done) begin errors++;
      if(errors<=60) $display("[%0t] io_pseudo_tag_error_inj_done g=%h i=%h", $time, g_io_pseudo_tag_error_inj_done, i_io_pseudo_tag_error_inj_done); end
    if (!$isunknown(g_io_pseudo_data_error_inj_done) && g_io_pseudo_data_error_inj_done !== i_io_pseudo_data_error_inj_done) begin errors++;
      if(errors<=60) $display("[%0t] io_pseudo_data_error_inj_done g=%h i=%h", $time, g_io_pseudo_data_error_inj_done, i_io_pseudo_data_error_inj_done); end
    if (!$isunknown(g_io_prefetch_info_naive_total_prefetch) && g_io_prefetch_info_naive_total_prefetch !== i_io_prefetch_info_naive_total_prefetch) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_total_prefetch g=%h i=%h", $time, g_io_prefetch_info_naive_total_prefetch, i_io_prefetch_info_naive_total_prefetch); end
    if (!$isunknown(g_io_prefetch_info_naive_late_hit_prefetch) && g_io_prefetch_info_naive_late_hit_prefetch !== i_io_prefetch_info_naive_late_hit_prefetch) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_late_hit_prefetch g=%h i=%h", $time, g_io_prefetch_info_naive_late_hit_prefetch, i_io_prefetch_info_naive_late_hit_prefetch); end
    if (!$isunknown(g_io_prefetch_info_naive_late_prefetch_hit) && g_io_prefetch_info_naive_late_prefetch_hit !== i_io_prefetch_info_naive_late_prefetch_hit) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_late_prefetch_hit g=%h i=%h", $time, g_io_prefetch_info_naive_late_prefetch_hit, i_io_prefetch_info_naive_late_prefetch_hit); end
    if (!$isunknown(g_io_prefetch_info_naive_late_load_hit) && g_io_prefetch_info_naive_late_load_hit !== i_io_prefetch_info_naive_late_load_hit) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_late_load_hit g=%h i=%h", $time, g_io_prefetch_info_naive_late_load_hit, i_io_prefetch_info_naive_late_load_hit); end
    if (!$isunknown(g_io_prefetch_info_naive_useful_prefetch) && g_io_prefetch_info_naive_useful_prefetch !== i_io_prefetch_info_naive_useful_prefetch) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_useful_prefetch g=%h i=%h", $time, g_io_prefetch_info_naive_useful_prefetch, i_io_prefetch_info_naive_useful_prefetch); end
    if (!$isunknown(g_io_prefetch_info_naive_prefetch_hit) && g_io_prefetch_info_naive_prefetch_hit !== i_io_prefetch_info_naive_prefetch_hit) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_naive_prefetch_hit g=%h i=%h", $time, g_io_prefetch_info_naive_prefetch_hit, i_io_prefetch_info_naive_prefetch_hit); end
    if (!$isunknown(g_io_prefetch_info_fdp_useful_prefetch) && g_io_prefetch_info_fdp_useful_prefetch !== i_io_prefetch_info_fdp_useful_prefetch) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_fdp_useful_prefetch g=%h i=%h", $time, g_io_prefetch_info_fdp_useful_prefetch, i_io_prefetch_info_fdp_useful_prefetch); end
    if (!$isunknown(g_io_prefetch_info_fdp_demand_miss) && g_io_prefetch_info_fdp_demand_miss !== i_io_prefetch_info_fdp_demand_miss) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_fdp_demand_miss g=%h i=%h", $time, g_io_prefetch_info_fdp_demand_miss, i_io_prefetch_info_fdp_demand_miss); end
    if (!$isunknown(g_io_prefetch_info_fdp_pollution) && g_io_prefetch_info_fdp_pollution !== i_io_prefetch_info_fdp_pollution) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_info_fdp_pollution g=%h i=%h", $time, g_io_prefetch_info_fdp_pollution, i_io_prefetch_info_fdp_pollution); end
    if (!$isunknown(g_io_bloom_filter_query_query_valid) && g_io_bloom_filter_query_query_valid !== i_io_bloom_filter_query_query_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_query_valid g=%h i=%h", $time, g_io_bloom_filter_query_query_valid, i_io_bloom_filter_query_query_valid); end
    if (!$isunknown(g_io_bloom_filter_query_query_bits_addr) && g_io_bloom_filter_query_query_bits_addr !== i_io_bloom_filter_query_query_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_query_bits_addr g=%h i=%h", $time, g_io_bloom_filter_query_query_bits_addr, i_io_bloom_filter_query_query_bits_addr); end
    if (!$isunknown(g_io_counter_filter_query_req_valid) && g_io_counter_filter_query_req_valid !== i_io_counter_filter_query_req_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_query_req_valid g=%h i=%h", $time, g_io_counter_filter_query_req_valid, i_io_counter_filter_query_req_valid); end
    if (!$isunknown(g_io_counter_filter_query_req_bits_idx) && g_io_counter_filter_query_req_bits_idx !== i_io_counter_filter_query_req_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_query_req_bits_idx g=%h i=%h", $time, g_io_counter_filter_query_req_bits_idx, i_io_counter_filter_query_req_bits_idx); end
    if (!$isunknown(g_io_counter_filter_query_req_bits_way) && g_io_counter_filter_query_req_bits_way !== i_io_counter_filter_query_req_bits_way) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_query_req_bits_way g=%h i=%h", $time, g_io_counter_filter_query_req_bits_way, i_io_counter_filter_query_req_bits_way); end
    if (!$isunknown(g_io_counter_filter_enq_valid) && g_io_counter_filter_enq_valid !== i_io_counter_filter_enq_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_enq_valid g=%h i=%h", $time, g_io_counter_filter_enq_valid, i_io_counter_filter_enq_valid); end
    if (!$isunknown(g_io_counter_filter_enq_bits_idx) && g_io_counter_filter_enq_bits_idx !== i_io_counter_filter_enq_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_enq_bits_idx g=%h i=%h", $time, g_io_counter_filter_enq_bits_idx, i_io_counter_filter_enq_bits_idx); end
    if (!$isunknown(g_io_counter_filter_enq_bits_way) && g_io_counter_filter_enq_bits_way !== i_io_counter_filter_enq_bits_way) begin errors++;
      if(errors<=60) $display("[%0t] io_counter_filter_enq_bits_way g=%h i=%h", $time, g_io_counter_filter_enq_bits_way, i_io_counter_filter_enq_bits_way); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
