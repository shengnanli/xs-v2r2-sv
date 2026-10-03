// 自动生成：verif/ut/LoadPipe/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// LoadPipe 双例化逐拍比对：golden LoadPipe vs 重写 LoadPipe_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= LoadPipe =================
  int unsigned lp_mode = 0;
  function automatic logic [6:0] tb_tag_ecc(input logic [35:0] t);
    logic [5:0] p;
    p[0] = ^(t & 36'h556AAAD5B);
    p[1] = ^(t & 36'h99B33366D);
    p[2] = ^(t & 36'h1E3C3C78E);
    p[3] = ^(t & 36'hE03FC07F0);
    p[4] = ^(t & 36'h003FFF800);
    p[5] = ^(t & 36'hFFC000000);
    return {^{p, t}, p};
  endfunction
  function automatic logic [42:0] tb_tag_word(input logic [35:0] ptag);
    logic [35:0] t;
    t = ($urandom_range(0, 2) == 0) ? ptag : 36'({$urandom, $urandom});
    if ($urandom_range(0, 7) == 0) return {7'($urandom), t};
    return {tb_tag_ecc(t), t};
  endfunction
  function automatic logic [4:0] tb_cmd();
    case ($urandom_range(0, 7))
      0, 1, 2, 3: return 5'h00;
      4: return 5'h02;
      5: return 5'h03;
      6: begin
        logic [4:0] c [8] = '{5'h06, 5'h01, 5'h04, 5'h08, 5'h0C, 5'h11, 5'h07, 5'h1A};
        return c[$urandom_range(0, 7)];
      end
      default: return 5'($urandom);
    endcase
  endfunction
  logic lp_reset;
  wire  lp_g_io_lsu_req_ready, lp_i_io_lsu_req_ready;
  logic lp_s0_io_lsu_req_ready = '0, lp_s1_io_lsu_req_ready = '0;
  logic lp_io_lsu_req_valid;
  logic [4:0] lp_io_lsu_req_bits_cmd;
  logic [49:0] lp_io_lsu_req_bits_vaddr;
  logic [49:0] lp_io_lsu_req_bits_vaddr_dup;
  logic [3:0] lp_io_lsu_req_bits_instrtype;
  logic lp_io_lsu_req_bits_isFirstIssue;
  logic lp_io_lsu_req_bits_lqIdx_flag;
  logic [6:0] lp_io_lsu_req_bits_lqIdx_value;
  wire  lp_g_io_lsu_resp_valid, lp_i_io_lsu_resp_valid;
  logic lp_s0_io_lsu_resp_valid = '0, lp_s1_io_lsu_resp_valid = '0;
  wire  [127:0] lp_g_io_lsu_resp_bits_data, lp_i_io_lsu_resp_bits_data;
  logic [127:0] lp_s0_io_lsu_resp_bits_data = '0, lp_s1_io_lsu_resp_bits_data = '0;
  wire  [127:0] lp_g_io_lsu_resp_bits_data_delayed, lp_i_io_lsu_resp_bits_data_delayed;
  logic [127:0] lp_s0_io_lsu_resp_bits_data_delayed = '0, lp_s1_io_lsu_resp_bits_data_delayed = '0;
  wire  lp_g_io_lsu_resp_bits_miss, lp_i_io_lsu_resp_bits_miss;
  logic lp_s0_io_lsu_resp_bits_miss = '0, lp_s1_io_lsu_resp_bits_miss = '0;
  wire  [3:0] lp_g_io_lsu_resp_bits_mshr_id, lp_i_io_lsu_resp_bits_mshr_id;
  logic [3:0] lp_s0_io_lsu_resp_bits_mshr_id = '0, lp_s1_io_lsu_resp_bits_mshr_id = '0;
  wire  [2:0] lp_g_io_lsu_resp_bits_meta_prefetch, lp_i_io_lsu_resp_bits_meta_prefetch;
  logic [2:0] lp_s0_io_lsu_resp_bits_meta_prefetch = '0, lp_s1_io_lsu_resp_bits_meta_prefetch = '0;
  wire  lp_g_io_lsu_resp_bits_handled, lp_i_io_lsu_resp_bits_handled;
  logic lp_s0_io_lsu_resp_bits_handled = '0, lp_s1_io_lsu_resp_bits_handled = '0;
  wire  lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied, lp_i_io_lsu_resp_bits_tl_error_delayed_tl_denied;
  logic lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_denied = '0, lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_denied = '0;
  wire  lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt, lp_i_io_lsu_resp_bits_tl_error_delayed_tl_corrupt;
  logic lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_corrupt = '0, lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_corrupt = '0;
  logic lp_io_lsu_s1_kill_data_read;
  logic lp_io_lsu_s1_kill;
  logic lp_io_lsu_s2_kill;
  logic [2:0] lp_io_lsu_pf_source;
  logic [47:0] lp_io_lsu_s1_paddr_dup_lsu;
  logic [47:0] lp_io_lsu_s1_paddr_dup_dcache;
  wire  lp_g_io_lsu_s2_bank_conflict, lp_i_io_lsu_s2_bank_conflict;
  logic lp_s0_io_lsu_s2_bank_conflict = '0, lp_s1_io_lsu_s2_bank_conflict = '0;
  wire  lp_g_io_lsu_s2_mq_nack, lp_i_io_lsu_s2_mq_nack;
  logic lp_s0_io_lsu_s2_mq_nack = '0, lp_s1_io_lsu_s2_mq_nack = '0;
  logic lp_io_load128Req;
  wire  lp_g_io_meta_read_valid, lp_i_io_meta_read_valid;
  logic lp_s0_io_meta_read_valid = '0, lp_s1_io_meta_read_valid = '0;
  wire  [7:0] lp_g_io_meta_read_bits_idx, lp_i_io_meta_read_bits_idx;
  logic [7:0] lp_s0_io_meta_read_bits_idx = '0, lp_s1_io_meta_read_bits_idx = '0;
  logic [1:0] lp_io_meta_resp_0_coh_state;
  logic [1:0] lp_io_meta_resp_1_coh_state;
  logic [1:0] lp_io_meta_resp_2_coh_state;
  logic [1:0] lp_io_meta_resp_3_coh_state;
  logic lp_io_extra_meta_resp_0_error_tl_denied;
  logic lp_io_extra_meta_resp_0_error_tl_corrupt;
  logic [2:0] lp_io_extra_meta_resp_0_prefetch;
  logic lp_io_extra_meta_resp_0_access;
  logic lp_io_extra_meta_resp_1_error_tl_denied;
  logic lp_io_extra_meta_resp_1_error_tl_corrupt;
  logic [2:0] lp_io_extra_meta_resp_1_prefetch;
  logic lp_io_extra_meta_resp_1_access;
  logic lp_io_extra_meta_resp_2_error_tl_denied;
  logic lp_io_extra_meta_resp_2_error_tl_corrupt;
  logic [2:0] lp_io_extra_meta_resp_2_prefetch;
  logic lp_io_extra_meta_resp_2_access;
  logic lp_io_extra_meta_resp_3_error_tl_denied;
  logic lp_io_extra_meta_resp_3_error_tl_corrupt;
  logic [2:0] lp_io_extra_meta_resp_3_prefetch;
  logic lp_io_extra_meta_resp_3_access;
  logic lp_io_tag_read_ready;
  wire  lp_g_io_tag_read_valid, lp_i_io_tag_read_valid;
  logic lp_s0_io_tag_read_valid = '0, lp_s1_io_tag_read_valid = '0;
  wire  [7:0] lp_g_io_tag_read_bits_idx, lp_i_io_tag_read_bits_idx;
  logic [7:0] lp_s0_io_tag_read_bits_idx = '0, lp_s1_io_tag_read_bits_idx = '0;
  logic [42:0] lp_io_tag_resp_0;
  logic [42:0] lp_io_tag_resp_1;
  logic [42:0] lp_io_tag_resp_2;
  logic [42:0] lp_io_tag_resp_3;
  logic lp_io_banked_data_read_ready;
  wire  lp_g_io_banked_data_read_valid, lp_i_io_banked_data_read_valid;
  logic lp_s0_io_banked_data_read_valid = '0, lp_s1_io_banked_data_read_valid = '0;
  wire  [3:0] lp_g_io_banked_data_read_bits_way_en, lp_i_io_banked_data_read_bits_way_en;
  logic [3:0] lp_s0_io_banked_data_read_bits_way_en = '0, lp_s1_io_banked_data_read_bits_way_en = '0;
  wire  [47:0] lp_g_io_banked_data_read_bits_addr, lp_i_io_banked_data_read_bits_addr;
  logic [47:0] lp_s0_io_banked_data_read_bits_addr = '0, lp_s1_io_banked_data_read_bits_addr = '0;
  wire  [47:0] lp_g_io_banked_data_read_bits_addr_dup, lp_i_io_banked_data_read_bits_addr_dup;
  logic [47:0] lp_s0_io_banked_data_read_bits_addr_dup = '0, lp_s1_io_banked_data_read_bits_addr_dup = '0;
  wire  [7:0] lp_g_io_banked_data_read_bits_bankMask, lp_i_io_banked_data_read_bits_bankMask;
  logic [7:0] lp_s0_io_banked_data_read_bits_bankMask = '0, lp_s1_io_banked_data_read_bits_bankMask = '0;
  wire  lp_g_io_banked_data_read_bits_lqIdx_flag, lp_i_io_banked_data_read_bits_lqIdx_flag;
  logic lp_s0_io_banked_data_read_bits_lqIdx_flag = '0, lp_s1_io_banked_data_read_bits_lqIdx_flag = '0;
  wire  [6:0] lp_g_io_banked_data_read_bits_lqIdx_value, lp_i_io_banked_data_read_bits_lqIdx_value;
  logic [6:0] lp_s0_io_banked_data_read_bits_lqIdx_value = '0, lp_s1_io_banked_data_read_bits_lqIdx_value = '0;
  wire  lp_g_io_is128Req, lp_i_io_is128Req;
  logic lp_s0_io_is128Req = '0, lp_s1_io_is128Req = '0;
  logic [63:0] lp_io_banked_data_resp_0_raw_data;
  logic [63:0] lp_io_banked_data_resp_1_raw_data;
  logic lp_io_read_error_delayed_0;
  logic lp_io_read_error_delayed_1;
  wire  lp_g_io_access_flag_write_valid, lp_i_io_access_flag_write_valid;
  logic lp_s0_io_access_flag_write_valid = '0, lp_s1_io_access_flag_write_valid = '0;
  wire  [7:0] lp_g_io_access_flag_write_bits_idx, lp_i_io_access_flag_write_bits_idx;
  logic [7:0] lp_s0_io_access_flag_write_bits_idx = '0, lp_s1_io_access_flag_write_bits_idx = '0;
  wire  [3:0] lp_g_io_access_flag_write_bits_way_en, lp_i_io_access_flag_write_bits_way_en;
  logic [3:0] lp_s0_io_access_flag_write_bits_way_en = '0, lp_s1_io_access_flag_write_bits_way_en = '0;
  wire  lp_g_io_prefetch_flag_write_valid, lp_i_io_prefetch_flag_write_valid;
  logic lp_s0_io_prefetch_flag_write_valid = '0, lp_s1_io_prefetch_flag_write_valid = '0;
  wire  [7:0] lp_g_io_prefetch_flag_write_bits_idx, lp_i_io_prefetch_flag_write_bits_idx;
  logic [7:0] lp_s0_io_prefetch_flag_write_bits_idx = '0, lp_s1_io_prefetch_flag_write_bits_idx = '0;
  wire  [3:0] lp_g_io_prefetch_flag_write_bits_way_en, lp_i_io_prefetch_flag_write_bits_way_en;
  logic [3:0] lp_s0_io_prefetch_flag_write_bits_way_en = '0, lp_s1_io_prefetch_flag_write_bits_way_en = '0;
  logic lp_io_bank_conflict_slow;
  logic lp_io_miss_req_ready;
  wire  lp_g_io_miss_req_valid, lp_i_io_miss_req_valid;
  logic lp_s0_io_miss_req_valid = '0, lp_s1_io_miss_req_valid = '0;
  wire  [3:0] lp_g_io_miss_req_bits_source, lp_i_io_miss_req_bits_source;
  logic [3:0] lp_s0_io_miss_req_bits_source = '0, lp_s1_io_miss_req_bits_source = '0;
  wire  [2:0] lp_g_io_miss_req_bits_pf_source, lp_i_io_miss_req_bits_pf_source;
  logic [2:0] lp_s0_io_miss_req_bits_pf_source = '0, lp_s1_io_miss_req_bits_pf_source = '0;
  wire  [4:0] lp_g_io_miss_req_bits_cmd, lp_i_io_miss_req_bits_cmd;
  logic [4:0] lp_s0_io_miss_req_bits_cmd = '0, lp_s1_io_miss_req_bits_cmd = '0;
  wire  [47:0] lp_g_io_miss_req_bits_addr, lp_i_io_miss_req_bits_addr;
  logic [47:0] lp_s0_io_miss_req_bits_addr = '0, lp_s1_io_miss_req_bits_addr = '0;
  wire  [49:0] lp_g_io_miss_req_bits_vaddr, lp_i_io_miss_req_bits_vaddr;
  logic [49:0] lp_s0_io_miss_req_bits_vaddr = '0, lp_s1_io_miss_req_bits_vaddr = '0;
  wire  [1:0] lp_g_io_miss_req_bits_req_coh_state, lp_i_io_miss_req_bits_req_coh_state;
  logic [1:0] lp_s0_io_miss_req_bits_req_coh_state = '0, lp_s1_io_miss_req_bits_req_coh_state = '0;
  wire  lp_g_io_miss_req_bits_isBtoT, lp_i_io_miss_req_bits_isBtoT;
  logic lp_s0_io_miss_req_bits_isBtoT = '0, lp_s1_io_miss_req_bits_isBtoT = '0;
  wire  [3:0] lp_g_io_miss_req_bits_occupy_way, lp_i_io_miss_req_bits_occupy_way;
  logic [3:0] lp_s0_io_miss_req_bits_occupy_way = '0, lp_s1_io_miss_req_bits_occupy_way = '0;
  wire  lp_g_io_miss_req_bits_cancel, lp_i_io_miss_req_bits_cancel;
  logic lp_s0_io_miss_req_bits_cancel = '0, lp_s1_io_miss_req_bits_cancel = '0;
  logic [3:0] lp_io_miss_resp_id;
  logic lp_io_miss_resp_handled;
  logic lp_io_miss_resp_merged;
  wire  lp_g_io_wbq_conflict_check_valid, lp_i_io_wbq_conflict_check_valid;
  logic lp_s0_io_wbq_conflict_check_valid = '0, lp_s1_io_wbq_conflict_check_valid = '0;
  wire  [47:0] lp_g_io_wbq_conflict_check_bits, lp_i_io_wbq_conflict_check_bits;
  logic [47:0] lp_s0_io_wbq_conflict_check_bits = '0, lp_s1_io_wbq_conflict_check_bits = '0;
  logic lp_io_wbq_block_miss_req;
  wire  lp_g_io_replace_access_valid, lp_i_io_replace_access_valid;
  logic lp_s0_io_replace_access_valid = '0, lp_s1_io_replace_access_valid = '0;
  wire  [7:0] lp_g_io_replace_access_bits_set, lp_i_io_replace_access_bits_set;
  logic [7:0] lp_s0_io_replace_access_bits_set = '0, lp_s1_io_replace_access_bits_set = '0;
  wire  [1:0] lp_g_io_replace_access_bits_way, lp_i_io_replace_access_bits_way;
  logic [1:0] lp_s0_io_replace_access_bits_way = '0, lp_s1_io_replace_access_bits_way = '0;
  wire  [7:0] lp_g_io_occupy_set, lp_i_io_occupy_set;
  logic [7:0] lp_s0_io_occupy_set = '0, lp_s1_io_occupy_set = '0;
  logic lp_io_occupy_fail;
  logic lp_io_disable_ld_fast_wakeup;
  wire  lp_g_io_error_valid, lp_i_io_error_valid;
  logic lp_s0_io_error_valid = '0, lp_s1_io_error_valid = '0;
  wire  [47:0] lp_g_io_error_bits_paddr, lp_i_io_error_bits_paddr;
  logic [47:0] lp_s0_io_error_bits_paddr = '0, lp_s1_io_error_bits_paddr = '0;
  wire  lp_g_io_error_bits_report_to_beu, lp_i_io_error_bits_report_to_beu;
  logic lp_s0_io_error_bits_report_to_beu = '0, lp_s1_io_error_bits_report_to_beu = '0;
  logic lp_io_pseudo_error_valid;
  logic lp_io_pseudo_error_bits_0_valid;
  logic [63:0] lp_io_pseudo_error_bits_0_mask;
  wire  lp_g_io_pseudo_tag_error_inj_done, lp_i_io_pseudo_tag_error_inj_done;
  logic lp_s0_io_pseudo_tag_error_inj_done = '0, lp_s1_io_pseudo_tag_error_inj_done = '0;
  wire  lp_g_io_pseudo_data_error_inj_done, lp_i_io_pseudo_data_error_inj_done;
  logic lp_s0_io_pseudo_data_error_inj_done = '0, lp_s1_io_pseudo_data_error_inj_done = '0;
  wire  lp_g_io_prefetch_info_naive_total_prefetch, lp_i_io_prefetch_info_naive_total_prefetch;
  logic lp_s0_io_prefetch_info_naive_total_prefetch = '0, lp_s1_io_prefetch_info_naive_total_prefetch = '0;
  wire  lp_g_io_prefetch_info_naive_late_hit_prefetch, lp_i_io_prefetch_info_naive_late_hit_prefetch;
  logic lp_s0_io_prefetch_info_naive_late_hit_prefetch = '0, lp_s1_io_prefetch_info_naive_late_hit_prefetch = '0;
  wire  lp_g_io_prefetch_info_naive_late_prefetch_hit, lp_i_io_prefetch_info_naive_late_prefetch_hit;
  logic lp_s0_io_prefetch_info_naive_late_prefetch_hit = '0, lp_s1_io_prefetch_info_naive_late_prefetch_hit = '0;
  wire  lp_g_io_prefetch_info_naive_late_load_hit, lp_i_io_prefetch_info_naive_late_load_hit;
  logic lp_s0_io_prefetch_info_naive_late_load_hit = '0, lp_s1_io_prefetch_info_naive_late_load_hit = '0;
  wire  lp_g_io_prefetch_info_naive_useful_prefetch, lp_i_io_prefetch_info_naive_useful_prefetch;
  logic lp_s0_io_prefetch_info_naive_useful_prefetch = '0, lp_s1_io_prefetch_info_naive_useful_prefetch = '0;
  wire  lp_g_io_prefetch_info_naive_prefetch_hit, lp_i_io_prefetch_info_naive_prefetch_hit;
  logic lp_s0_io_prefetch_info_naive_prefetch_hit = '0, lp_s1_io_prefetch_info_naive_prefetch_hit = '0;
  wire  lp_g_io_prefetch_info_fdp_useful_prefetch, lp_i_io_prefetch_info_fdp_useful_prefetch;
  logic lp_s0_io_prefetch_info_fdp_useful_prefetch = '0, lp_s1_io_prefetch_info_fdp_useful_prefetch = '0;
  wire  lp_g_io_prefetch_info_fdp_demand_miss, lp_i_io_prefetch_info_fdp_demand_miss;
  logic lp_s0_io_prefetch_info_fdp_demand_miss = '0, lp_s1_io_prefetch_info_fdp_demand_miss = '0;
  wire  lp_g_io_prefetch_info_fdp_pollution, lp_i_io_prefetch_info_fdp_pollution;
  logic lp_s0_io_prefetch_info_fdp_pollution = '0, lp_s1_io_prefetch_info_fdp_pollution = '0;
  wire  lp_g_io_bloom_filter_query_query_valid, lp_i_io_bloom_filter_query_query_valid;
  logic lp_s0_io_bloom_filter_query_query_valid = '0, lp_s1_io_bloom_filter_query_query_valid = '0;
  wire  [11:0] lp_g_io_bloom_filter_query_query_bits_addr, lp_i_io_bloom_filter_query_query_bits_addr;
  logic [11:0] lp_s0_io_bloom_filter_query_query_bits_addr = '0, lp_s1_io_bloom_filter_query_query_bits_addr = '0;
  logic lp_io_bloom_filter_query_resp_valid;
  logic lp_io_bloom_filter_query_resp_bits_res;
  wire  lp_g_io_counter_filter_query_req_valid, lp_i_io_counter_filter_query_req_valid;
  logic lp_s0_io_counter_filter_query_req_valid = '0, lp_s1_io_counter_filter_query_req_valid = '0;
  wire  [7:0] lp_g_io_counter_filter_query_req_bits_idx, lp_i_io_counter_filter_query_req_bits_idx;
  logic [7:0] lp_s0_io_counter_filter_query_req_bits_idx = '0, lp_s1_io_counter_filter_query_req_bits_idx = '0;
  wire  [1:0] lp_g_io_counter_filter_query_req_bits_way, lp_i_io_counter_filter_query_req_bits_way;
  logic [1:0] lp_s0_io_counter_filter_query_req_bits_way = '0, lp_s1_io_counter_filter_query_req_bits_way = '0;
  logic lp_io_counter_filter_query_resp;
  wire  lp_g_io_counter_filter_enq_valid, lp_i_io_counter_filter_enq_valid;
  logic lp_s0_io_counter_filter_enq_valid = '0, lp_s1_io_counter_filter_enq_valid = '0;
  wire  [7:0] lp_g_io_counter_filter_enq_bits_idx, lp_i_io_counter_filter_enq_bits_idx;
  logic [7:0] lp_s0_io_counter_filter_enq_bits_idx = '0, lp_s1_io_counter_filter_enq_bits_idx = '0;
  wire  [1:0] lp_g_io_counter_filter_enq_bits_way, lp_i_io_counter_filter_enq_bits_way;
  logic [1:0] lp_s0_io_counter_filter_enq_bits_way = '0, lp_s1_io_counter_filter_enq_bits_way = '0;
  wire  [5:0] lp_g_io_perf_0_value, lp_i_io_perf_0_value;
  logic [5:0] lp_s0_io_perf_0_value = '0, lp_s1_io_perf_0_value = '0;
  wire  [5:0] lp_g_io_perf_1_value, lp_i_io_perf_1_value;
  logic [5:0] lp_s0_io_perf_1_value = '0, lp_s1_io_perf_1_value = '0;
  wire  [5:0] lp_g_io_perf_2_value, lp_i_io_perf_2_value;
  logic [5:0] lp_s0_io_perf_2_value = '0, lp_s1_io_perf_2_value = '0;
  wire  [5:0] lp_g_io_perf_3_value, lp_i_io_perf_3_value;
  logic [5:0] lp_s0_io_perf_3_value = '0, lp_s1_io_perf_3_value = '0;
  wire  [5:0] lp_g_io_perf_4_value, lp_i_io_perf_4_value;
  logic [5:0] lp_s0_io_perf_4_value = '0, lp_s1_io_perf_4_value = '0;
  wire  [5:0] lp_g_io_perf_5_value, lp_i_io_perf_5_value;
  logic [5:0] lp_s0_io_perf_5_value = '0, lp_s1_io_perf_5_value = '0;
  wire  [5:0] lp_g_io_perf_6_value, lp_i_io_perf_6_value;
  logic [5:0] lp_s0_io_perf_6_value = '0, lp_s1_io_perf_6_value = '0;
  int lp_cov_s1_hit = 0;
  int lp_cov_s1_hit_noperm = 0;
  int lp_cov_s2_real_miss = 0;
  int lp_cov_miss_fire = 0;
  int lp_cov_nack_no_mshr = 0;
  int lp_cov_nack_data = 0;
  int lp_cov_tag_error = 0;
  int lp_cov_btot = 0;
  int lp_cov_btot_occupy_fail = 0;
  int lp_cov_handled = 0;
  int lp_cov_pseudo_tag = 0;
  int lp_cov_error_valid = 0;
  int lp_cov_data_error_128 = 0;
  int lp_cov_pf_counted = 0;
  int lp_cov_pf_filtered = 0;
  int lp_cov_late_prefetch_hit = 0;
  int lp_cov_pollution = 0;
  int lp_cov_replace_access = 0;
  logic [0:0] lp_armed = '0;
  int lp_armed_at = -1;
  LoadPipe lp_u_gold (
    .clock(clk),
    .reset(lp_reset),
    .io_lsu_req_ready(lp_g_io_lsu_req_ready),
    .io_lsu_req_valid(lp_io_lsu_req_valid),
    .io_lsu_req_bits_cmd(lp_io_lsu_req_bits_cmd),
    .io_lsu_req_bits_vaddr(lp_io_lsu_req_bits_vaddr),
    .io_lsu_req_bits_vaddr_dup(lp_io_lsu_req_bits_vaddr_dup),
    .io_lsu_req_bits_instrtype(lp_io_lsu_req_bits_instrtype),
    .io_lsu_req_bits_isFirstIssue(lp_io_lsu_req_bits_isFirstIssue),
    .io_lsu_req_bits_lqIdx_flag(lp_io_lsu_req_bits_lqIdx_flag),
    .io_lsu_req_bits_lqIdx_value(lp_io_lsu_req_bits_lqIdx_value),
    .io_lsu_resp_valid(lp_g_io_lsu_resp_valid),
    .io_lsu_resp_bits_data(lp_g_io_lsu_resp_bits_data),
    .io_lsu_resp_bits_data_delayed(lp_g_io_lsu_resp_bits_data_delayed),
    .io_lsu_resp_bits_miss(lp_g_io_lsu_resp_bits_miss),
    .io_lsu_resp_bits_mshr_id(lp_g_io_lsu_resp_bits_mshr_id),
    .io_lsu_resp_bits_meta_prefetch(lp_g_io_lsu_resp_bits_meta_prefetch),
    .io_lsu_resp_bits_handled(lp_g_io_lsu_resp_bits_handled),
    .io_lsu_resp_bits_tl_error_delayed_tl_denied(lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_resp_bits_tl_error_delayed_tl_corrupt(lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_s1_kill_data_read(lp_io_lsu_s1_kill_data_read),
    .io_lsu_s1_kill(lp_io_lsu_s1_kill),
    .io_lsu_s2_kill(lp_io_lsu_s2_kill),
    .io_lsu_pf_source(lp_io_lsu_pf_source),
    .io_lsu_s1_paddr_dup_lsu(lp_io_lsu_s1_paddr_dup_lsu),
    .io_lsu_s1_paddr_dup_dcache(lp_io_lsu_s1_paddr_dup_dcache),
    .io_lsu_s2_bank_conflict(lp_g_io_lsu_s2_bank_conflict),
    .io_lsu_s2_mq_nack(lp_g_io_lsu_s2_mq_nack),
    .io_load128Req(lp_io_load128Req),
    .io_meta_read_valid(lp_g_io_meta_read_valid),
    .io_meta_read_bits_idx(lp_g_io_meta_read_bits_idx),
    .io_meta_resp_0_coh_state(lp_io_meta_resp_0_coh_state),
    .io_meta_resp_1_coh_state(lp_io_meta_resp_1_coh_state),
    .io_meta_resp_2_coh_state(lp_io_meta_resp_2_coh_state),
    .io_meta_resp_3_coh_state(lp_io_meta_resp_3_coh_state),
    .io_extra_meta_resp_0_error_tl_denied(lp_io_extra_meta_resp_0_error_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt(lp_io_extra_meta_resp_0_error_tl_corrupt),
    .io_extra_meta_resp_0_prefetch(lp_io_extra_meta_resp_0_prefetch),
    .io_extra_meta_resp_0_access(lp_io_extra_meta_resp_0_access),
    .io_extra_meta_resp_1_error_tl_denied(lp_io_extra_meta_resp_1_error_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt(lp_io_extra_meta_resp_1_error_tl_corrupt),
    .io_extra_meta_resp_1_prefetch(lp_io_extra_meta_resp_1_prefetch),
    .io_extra_meta_resp_1_access(lp_io_extra_meta_resp_1_access),
    .io_extra_meta_resp_2_error_tl_denied(lp_io_extra_meta_resp_2_error_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt(lp_io_extra_meta_resp_2_error_tl_corrupt),
    .io_extra_meta_resp_2_prefetch(lp_io_extra_meta_resp_2_prefetch),
    .io_extra_meta_resp_2_access(lp_io_extra_meta_resp_2_access),
    .io_extra_meta_resp_3_error_tl_denied(lp_io_extra_meta_resp_3_error_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt(lp_io_extra_meta_resp_3_error_tl_corrupt),
    .io_extra_meta_resp_3_prefetch(lp_io_extra_meta_resp_3_prefetch),
    .io_extra_meta_resp_3_access(lp_io_extra_meta_resp_3_access),
    .io_tag_read_ready(lp_io_tag_read_ready),
    .io_tag_read_valid(lp_g_io_tag_read_valid),
    .io_tag_read_bits_idx(lp_g_io_tag_read_bits_idx),
    .io_tag_resp_0(lp_io_tag_resp_0),
    .io_tag_resp_1(lp_io_tag_resp_1),
    .io_tag_resp_2(lp_io_tag_resp_2),
    .io_tag_resp_3(lp_io_tag_resp_3),
    .io_banked_data_read_ready(lp_io_banked_data_read_ready),
    .io_banked_data_read_valid(lp_g_io_banked_data_read_valid),
    .io_banked_data_read_bits_way_en(lp_g_io_banked_data_read_bits_way_en),
    .io_banked_data_read_bits_addr(lp_g_io_banked_data_read_bits_addr),
    .io_banked_data_read_bits_addr_dup(lp_g_io_banked_data_read_bits_addr_dup),
    .io_banked_data_read_bits_bankMask(lp_g_io_banked_data_read_bits_bankMask),
    .io_banked_data_read_bits_lqIdx_flag(lp_g_io_banked_data_read_bits_lqIdx_flag),
    .io_banked_data_read_bits_lqIdx_value(lp_g_io_banked_data_read_bits_lqIdx_value),
    .io_is128Req(lp_g_io_is128Req),
    .io_banked_data_resp_0_raw_data(lp_io_banked_data_resp_0_raw_data),
    .io_banked_data_resp_1_raw_data(lp_io_banked_data_resp_1_raw_data),
    .io_read_error_delayed_0(lp_io_read_error_delayed_0),
    .io_read_error_delayed_1(lp_io_read_error_delayed_1),
    .io_access_flag_write_valid(lp_g_io_access_flag_write_valid),
    .io_access_flag_write_bits_idx(lp_g_io_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en(lp_g_io_access_flag_write_bits_way_en),
    .io_prefetch_flag_write_valid(lp_g_io_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx(lp_g_io_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en(lp_g_io_prefetch_flag_write_bits_way_en),
    .io_bank_conflict_slow(lp_io_bank_conflict_slow),
    .io_miss_req_ready(lp_io_miss_req_ready),
    .io_miss_req_valid(lp_g_io_miss_req_valid),
    .io_miss_req_bits_source(lp_g_io_miss_req_bits_source),
    .io_miss_req_bits_pf_source(lp_g_io_miss_req_bits_pf_source),
    .io_miss_req_bits_cmd(lp_g_io_miss_req_bits_cmd),
    .io_miss_req_bits_addr(lp_g_io_miss_req_bits_addr),
    .io_miss_req_bits_vaddr(lp_g_io_miss_req_bits_vaddr),
    .io_miss_req_bits_req_coh_state(lp_g_io_miss_req_bits_req_coh_state),
    .io_miss_req_bits_isBtoT(lp_g_io_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way(lp_g_io_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel(lp_g_io_miss_req_bits_cancel),
    .io_miss_resp_id(lp_io_miss_resp_id),
    .io_miss_resp_handled(lp_io_miss_resp_handled),
    .io_miss_resp_merged(lp_io_miss_resp_merged),
    .io_wbq_conflict_check_valid(lp_g_io_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits(lp_g_io_wbq_conflict_check_bits),
    .io_wbq_block_miss_req(lp_io_wbq_block_miss_req),
    .io_replace_access_valid(lp_g_io_replace_access_valid),
    .io_replace_access_bits_set(lp_g_io_replace_access_bits_set),
    .io_replace_access_bits_way(lp_g_io_replace_access_bits_way),
    .io_occupy_set(lp_g_io_occupy_set),
    .io_occupy_fail(lp_io_occupy_fail),
    .io_disable_ld_fast_wakeup(lp_io_disable_ld_fast_wakeup),
    .io_error_valid(lp_g_io_error_valid),
    .io_error_bits_paddr(lp_g_io_error_bits_paddr),
    .io_error_bits_report_to_beu(lp_g_io_error_bits_report_to_beu),
    .io_pseudo_error_valid(lp_io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(lp_io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(lp_io_pseudo_error_bits_0_mask),
    .io_pseudo_tag_error_inj_done(lp_g_io_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done(lp_g_io_pseudo_data_error_inj_done),
    .io_prefetch_info_naive_total_prefetch(lp_g_io_prefetch_info_naive_total_prefetch),
    .io_prefetch_info_naive_late_hit_prefetch(lp_g_io_prefetch_info_naive_late_hit_prefetch),
    .io_prefetch_info_naive_late_prefetch_hit(lp_g_io_prefetch_info_naive_late_prefetch_hit),
    .io_prefetch_info_naive_late_load_hit(lp_g_io_prefetch_info_naive_late_load_hit),
    .io_prefetch_info_naive_useful_prefetch(lp_g_io_prefetch_info_naive_useful_prefetch),
    .io_prefetch_info_naive_prefetch_hit(lp_g_io_prefetch_info_naive_prefetch_hit),
    .io_prefetch_info_fdp_useful_prefetch(lp_g_io_prefetch_info_fdp_useful_prefetch),
    .io_prefetch_info_fdp_demand_miss(lp_g_io_prefetch_info_fdp_demand_miss),
    .io_prefetch_info_fdp_pollution(lp_g_io_prefetch_info_fdp_pollution),
    .io_bloom_filter_query_query_valid(lp_g_io_bloom_filter_query_query_valid),
    .io_bloom_filter_query_query_bits_addr(lp_g_io_bloom_filter_query_query_bits_addr),
    .io_bloom_filter_query_resp_valid(lp_io_bloom_filter_query_resp_valid),
    .io_bloom_filter_query_resp_bits_res(lp_io_bloom_filter_query_resp_bits_res),
    .io_counter_filter_query_req_valid(lp_g_io_counter_filter_query_req_valid),
    .io_counter_filter_query_req_bits_idx(lp_g_io_counter_filter_query_req_bits_idx),
    .io_counter_filter_query_req_bits_way(lp_g_io_counter_filter_query_req_bits_way),
    .io_counter_filter_query_resp(lp_io_counter_filter_query_resp),
    .io_counter_filter_enq_valid(lp_g_io_counter_filter_enq_valid),
    .io_counter_filter_enq_bits_idx(lp_g_io_counter_filter_enq_bits_idx),
    .io_counter_filter_enq_bits_way(lp_g_io_counter_filter_enq_bits_way),
    .io_perf_0_value(lp_g_io_perf_0_value),
    .io_perf_1_value(lp_g_io_perf_1_value),
    .io_perf_2_value(lp_g_io_perf_2_value),
    .io_perf_3_value(lp_g_io_perf_3_value),
    .io_perf_4_value(lp_g_io_perf_4_value),
    .io_perf_5_value(lp_g_io_perf_5_value),
    .io_perf_6_value(lp_g_io_perf_6_value)
  );
  LoadPipe_xs lp_u_impl (
    .clock(clk),
    .reset(lp_reset),
    .io_lsu_req_ready(lp_i_io_lsu_req_ready),
    .io_lsu_req_valid(lp_io_lsu_req_valid),
    .io_lsu_req_bits_cmd(lp_io_lsu_req_bits_cmd),
    .io_lsu_req_bits_vaddr(lp_io_lsu_req_bits_vaddr),
    .io_lsu_req_bits_vaddr_dup(lp_io_lsu_req_bits_vaddr_dup),
    .io_lsu_req_bits_instrtype(lp_io_lsu_req_bits_instrtype),
    .io_lsu_req_bits_isFirstIssue(lp_io_lsu_req_bits_isFirstIssue),
    .io_lsu_req_bits_lqIdx_flag(lp_io_lsu_req_bits_lqIdx_flag),
    .io_lsu_req_bits_lqIdx_value(lp_io_lsu_req_bits_lqIdx_value),
    .io_lsu_resp_valid(lp_i_io_lsu_resp_valid),
    .io_lsu_resp_bits_data(lp_i_io_lsu_resp_bits_data),
    .io_lsu_resp_bits_data_delayed(lp_i_io_lsu_resp_bits_data_delayed),
    .io_lsu_resp_bits_miss(lp_i_io_lsu_resp_bits_miss),
    .io_lsu_resp_bits_mshr_id(lp_i_io_lsu_resp_bits_mshr_id),
    .io_lsu_resp_bits_meta_prefetch(lp_i_io_lsu_resp_bits_meta_prefetch),
    .io_lsu_resp_bits_handled(lp_i_io_lsu_resp_bits_handled),
    .io_lsu_resp_bits_tl_error_delayed_tl_denied(lp_i_io_lsu_resp_bits_tl_error_delayed_tl_denied),
    .io_lsu_resp_bits_tl_error_delayed_tl_corrupt(lp_i_io_lsu_resp_bits_tl_error_delayed_tl_corrupt),
    .io_lsu_s1_kill_data_read(lp_io_lsu_s1_kill_data_read),
    .io_lsu_s1_kill(lp_io_lsu_s1_kill),
    .io_lsu_s2_kill(lp_io_lsu_s2_kill),
    .io_lsu_pf_source(lp_io_lsu_pf_source),
    .io_lsu_s1_paddr_dup_lsu(lp_io_lsu_s1_paddr_dup_lsu),
    .io_lsu_s1_paddr_dup_dcache(lp_io_lsu_s1_paddr_dup_dcache),
    .io_lsu_s2_bank_conflict(lp_i_io_lsu_s2_bank_conflict),
    .io_lsu_s2_mq_nack(lp_i_io_lsu_s2_mq_nack),
    .io_load128Req(lp_io_load128Req),
    .io_meta_read_valid(lp_i_io_meta_read_valid),
    .io_meta_read_bits_idx(lp_i_io_meta_read_bits_idx),
    .io_meta_resp_0_coh_state(lp_io_meta_resp_0_coh_state),
    .io_meta_resp_1_coh_state(lp_io_meta_resp_1_coh_state),
    .io_meta_resp_2_coh_state(lp_io_meta_resp_2_coh_state),
    .io_meta_resp_3_coh_state(lp_io_meta_resp_3_coh_state),
    .io_extra_meta_resp_0_error_tl_denied(lp_io_extra_meta_resp_0_error_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt(lp_io_extra_meta_resp_0_error_tl_corrupt),
    .io_extra_meta_resp_0_prefetch(lp_io_extra_meta_resp_0_prefetch),
    .io_extra_meta_resp_0_access(lp_io_extra_meta_resp_0_access),
    .io_extra_meta_resp_1_error_tl_denied(lp_io_extra_meta_resp_1_error_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt(lp_io_extra_meta_resp_1_error_tl_corrupt),
    .io_extra_meta_resp_1_prefetch(lp_io_extra_meta_resp_1_prefetch),
    .io_extra_meta_resp_1_access(lp_io_extra_meta_resp_1_access),
    .io_extra_meta_resp_2_error_tl_denied(lp_io_extra_meta_resp_2_error_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt(lp_io_extra_meta_resp_2_error_tl_corrupt),
    .io_extra_meta_resp_2_prefetch(lp_io_extra_meta_resp_2_prefetch),
    .io_extra_meta_resp_2_access(lp_io_extra_meta_resp_2_access),
    .io_extra_meta_resp_3_error_tl_denied(lp_io_extra_meta_resp_3_error_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt(lp_io_extra_meta_resp_3_error_tl_corrupt),
    .io_extra_meta_resp_3_prefetch(lp_io_extra_meta_resp_3_prefetch),
    .io_extra_meta_resp_3_access(lp_io_extra_meta_resp_3_access),
    .io_tag_read_ready(lp_io_tag_read_ready),
    .io_tag_read_valid(lp_i_io_tag_read_valid),
    .io_tag_read_bits_idx(lp_i_io_tag_read_bits_idx),
    .io_tag_resp_0(lp_io_tag_resp_0),
    .io_tag_resp_1(lp_io_tag_resp_1),
    .io_tag_resp_2(lp_io_tag_resp_2),
    .io_tag_resp_3(lp_io_tag_resp_3),
    .io_banked_data_read_ready(lp_io_banked_data_read_ready),
    .io_banked_data_read_valid(lp_i_io_banked_data_read_valid),
    .io_banked_data_read_bits_way_en(lp_i_io_banked_data_read_bits_way_en),
    .io_banked_data_read_bits_addr(lp_i_io_banked_data_read_bits_addr),
    .io_banked_data_read_bits_addr_dup(lp_i_io_banked_data_read_bits_addr_dup),
    .io_banked_data_read_bits_bankMask(lp_i_io_banked_data_read_bits_bankMask),
    .io_banked_data_read_bits_lqIdx_flag(lp_i_io_banked_data_read_bits_lqIdx_flag),
    .io_banked_data_read_bits_lqIdx_value(lp_i_io_banked_data_read_bits_lqIdx_value),
    .io_is128Req(lp_i_io_is128Req),
    .io_banked_data_resp_0_raw_data(lp_io_banked_data_resp_0_raw_data),
    .io_banked_data_resp_1_raw_data(lp_io_banked_data_resp_1_raw_data),
    .io_read_error_delayed_0(lp_io_read_error_delayed_0),
    .io_read_error_delayed_1(lp_io_read_error_delayed_1),
    .io_access_flag_write_valid(lp_i_io_access_flag_write_valid),
    .io_access_flag_write_bits_idx(lp_i_io_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en(lp_i_io_access_flag_write_bits_way_en),
    .io_prefetch_flag_write_valid(lp_i_io_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx(lp_i_io_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en(lp_i_io_prefetch_flag_write_bits_way_en),
    .io_bank_conflict_slow(lp_io_bank_conflict_slow),
    .io_miss_req_ready(lp_io_miss_req_ready),
    .io_miss_req_valid(lp_i_io_miss_req_valid),
    .io_miss_req_bits_source(lp_i_io_miss_req_bits_source),
    .io_miss_req_bits_pf_source(lp_i_io_miss_req_bits_pf_source),
    .io_miss_req_bits_cmd(lp_i_io_miss_req_bits_cmd),
    .io_miss_req_bits_addr(lp_i_io_miss_req_bits_addr),
    .io_miss_req_bits_vaddr(lp_i_io_miss_req_bits_vaddr),
    .io_miss_req_bits_req_coh_state(lp_i_io_miss_req_bits_req_coh_state),
    .io_miss_req_bits_isBtoT(lp_i_io_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way(lp_i_io_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel(lp_i_io_miss_req_bits_cancel),
    .io_miss_resp_id(lp_io_miss_resp_id),
    .io_miss_resp_handled(lp_io_miss_resp_handled),
    .io_miss_resp_merged(lp_io_miss_resp_merged),
    .io_wbq_conflict_check_valid(lp_i_io_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits(lp_i_io_wbq_conflict_check_bits),
    .io_wbq_block_miss_req(lp_io_wbq_block_miss_req),
    .io_replace_access_valid(lp_i_io_replace_access_valid),
    .io_replace_access_bits_set(lp_i_io_replace_access_bits_set),
    .io_replace_access_bits_way(lp_i_io_replace_access_bits_way),
    .io_occupy_set(lp_i_io_occupy_set),
    .io_occupy_fail(lp_io_occupy_fail),
    .io_disable_ld_fast_wakeup(lp_io_disable_ld_fast_wakeup),
    .io_error_valid(lp_i_io_error_valid),
    .io_error_bits_paddr(lp_i_io_error_bits_paddr),
    .io_error_bits_report_to_beu(lp_i_io_error_bits_report_to_beu),
    .io_pseudo_error_valid(lp_io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(lp_io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(lp_io_pseudo_error_bits_0_mask),
    .io_pseudo_tag_error_inj_done(lp_i_io_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done(lp_i_io_pseudo_data_error_inj_done),
    .io_prefetch_info_naive_total_prefetch(lp_i_io_prefetch_info_naive_total_prefetch),
    .io_prefetch_info_naive_late_hit_prefetch(lp_i_io_prefetch_info_naive_late_hit_prefetch),
    .io_prefetch_info_naive_late_prefetch_hit(lp_i_io_prefetch_info_naive_late_prefetch_hit),
    .io_prefetch_info_naive_late_load_hit(lp_i_io_prefetch_info_naive_late_load_hit),
    .io_prefetch_info_naive_useful_prefetch(lp_i_io_prefetch_info_naive_useful_prefetch),
    .io_prefetch_info_naive_prefetch_hit(lp_i_io_prefetch_info_naive_prefetch_hit),
    .io_prefetch_info_fdp_useful_prefetch(lp_i_io_prefetch_info_fdp_useful_prefetch),
    .io_prefetch_info_fdp_demand_miss(lp_i_io_prefetch_info_fdp_demand_miss),
    .io_prefetch_info_fdp_pollution(lp_i_io_prefetch_info_fdp_pollution),
    .io_bloom_filter_query_query_valid(lp_i_io_bloom_filter_query_query_valid),
    .io_bloom_filter_query_query_bits_addr(lp_i_io_bloom_filter_query_query_bits_addr),
    .io_bloom_filter_query_resp_valid(lp_io_bloom_filter_query_resp_valid),
    .io_bloom_filter_query_resp_bits_res(lp_io_bloom_filter_query_resp_bits_res),
    .io_counter_filter_query_req_valid(lp_i_io_counter_filter_query_req_valid),
    .io_counter_filter_query_req_bits_idx(lp_i_io_counter_filter_query_req_bits_idx),
    .io_counter_filter_query_req_bits_way(lp_i_io_counter_filter_query_req_bits_way),
    .io_counter_filter_query_resp(lp_io_counter_filter_query_resp),
    .io_counter_filter_enq_valid(lp_i_io_counter_filter_enq_valid),
    .io_counter_filter_enq_bits_idx(lp_i_io_counter_filter_enq_bits_idx),
    .io_counter_filter_enq_bits_way(lp_i_io_counter_filter_enq_bits_way),
    .io_perf_0_value(lp_i_io_perf_0_value),
    .io_perf_1_value(lp_i_io_perf_1_value),
    .io_perf_2_value(lp_i_io_perf_2_value),
    .io_perf_3_value(lp_i_io_perf_3_value),
    .io_perf_4_value(lp_i_io_perf_4_value),
    .io_perf_5_value(lp_i_io_perf_5_value),
    .io_perf_6_value(lp_i_io_perf_6_value)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) lp_mode = $urandom_range(0, 15);
      lp_io_lsu_req_valid = 1'($urandom);
      lp_io_lsu_req_bits_cmd = 5'($urandom);
      lp_io_lsu_req_bits_vaddr = 50'({$urandom, $urandom});
      lp_io_lsu_req_bits_vaddr_dup = 50'({$urandom, $urandom});
      lp_io_lsu_req_bits_instrtype = 4'($urandom);
      lp_io_lsu_req_bits_isFirstIssue = 1'($urandom);
      lp_io_lsu_req_bits_lqIdx_flag = 1'($urandom);
      lp_io_lsu_req_bits_lqIdx_value = 7'($urandom);
      lp_io_lsu_s1_kill_data_read = 1'($urandom);
      lp_io_lsu_s1_kill = 1'($urandom);
      lp_io_lsu_s2_kill = 1'($urandom);
      lp_io_lsu_pf_source = 3'($urandom);
      lp_io_lsu_s1_paddr_dup_lsu = 48'({$urandom, $urandom});
      lp_io_lsu_s1_paddr_dup_dcache = 48'({$urandom, $urandom});
      lp_io_load128Req = 1'($urandom);
      lp_io_meta_resp_0_coh_state = 2'($urandom);
      lp_io_meta_resp_1_coh_state = 2'($urandom);
      lp_io_meta_resp_2_coh_state = 2'($urandom);
      lp_io_meta_resp_3_coh_state = 2'($urandom);
      lp_io_extra_meta_resp_0_error_tl_denied = 1'($urandom);
      lp_io_extra_meta_resp_0_error_tl_corrupt = 1'($urandom);
      lp_io_extra_meta_resp_0_prefetch = 3'($urandom);
      lp_io_extra_meta_resp_0_access = 1'($urandom);
      lp_io_extra_meta_resp_1_error_tl_denied = 1'($urandom);
      lp_io_extra_meta_resp_1_error_tl_corrupt = 1'($urandom);
      lp_io_extra_meta_resp_1_prefetch = 3'($urandom);
      lp_io_extra_meta_resp_1_access = 1'($urandom);
      lp_io_extra_meta_resp_2_error_tl_denied = 1'($urandom);
      lp_io_extra_meta_resp_2_error_tl_corrupt = 1'($urandom);
      lp_io_extra_meta_resp_2_prefetch = 3'($urandom);
      lp_io_extra_meta_resp_2_access = 1'($urandom);
      lp_io_extra_meta_resp_3_error_tl_denied = 1'($urandom);
      lp_io_extra_meta_resp_3_error_tl_corrupt = 1'($urandom);
      lp_io_extra_meta_resp_3_prefetch = 3'($urandom);
      lp_io_extra_meta_resp_3_access = 1'($urandom);
      lp_io_tag_read_ready = 1'($urandom);
      lp_io_tag_resp_0 = 43'({$urandom, $urandom});
      lp_io_tag_resp_1 = 43'({$urandom, $urandom});
      lp_io_tag_resp_2 = 43'({$urandom, $urandom});
      lp_io_tag_resp_3 = 43'({$urandom, $urandom});
      lp_io_banked_data_read_ready = 1'($urandom);
      lp_io_banked_data_resp_0_raw_data = 64'({$urandom, $urandom});
      lp_io_banked_data_resp_1_raw_data = 64'({$urandom, $urandom});
      lp_io_read_error_delayed_0 = 1'($urandom);
      lp_io_read_error_delayed_1 = 1'($urandom);
      lp_io_bank_conflict_slow = 1'($urandom);
      lp_io_miss_req_ready = 1'($urandom);
      lp_io_miss_resp_id = 4'($urandom);
      lp_io_miss_resp_handled = 1'($urandom);
      lp_io_miss_resp_merged = 1'($urandom);
      lp_io_wbq_block_miss_req = 1'($urandom);
      lp_io_occupy_fail = 1'($urandom);
      lp_io_disable_ld_fast_wakeup = 1'($urandom);
      lp_io_pseudo_error_valid = 1'($urandom);
      lp_io_pseudo_error_bits_0_valid = 1'($urandom);
      lp_io_pseudo_error_bits_0_mask = 64'({$urandom, $urandom});
      lp_io_bloom_filter_query_resp_valid = 1'($urandom);
      lp_io_bloom_filter_query_resp_bits_res = 1'($urandom);
      lp_io_counter_filter_query_resp = 1'($urandom);
      lp_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49999) == 0);
      begin : stim_lp
        lp_io_lsu_s1_paddr_dup_lsu = lp_io_lsu_s1_paddr_dup_dcache;
        if ($urandom_range(0, 7) == 0) lp_io_lsu_s1_paddr_dup_lsu[47:12] = 36'({$urandom, $urandom});
        lp_io_tag_resp_0 = tb_tag_word(lp_io_lsu_s1_paddr_dup_dcache[47:12]);
        lp_io_tag_resp_1 = tb_tag_word(lp_io_lsu_s1_paddr_dup_dcache[47:12]);
        lp_io_tag_resp_2 = tb_tag_word(lp_io_lsu_s1_paddr_dup_dcache[47:12]);
        lp_io_tag_resp_3 = tb_tag_word(lp_io_lsu_s1_paddr_dup_dcache[47:12]);
        lp_io_lsu_req_bits_cmd = tb_cmd();
        lp_io_lsu_req_bits_instrtype = ($urandom_range(0, 3) == 0) ? 4'h3 : 4'($urandom);
        lp_io_pseudo_error_valid = ($urandom_range(0, 15) == 0);
        lp_io_load128Req = ($urandom_range(0, 3) == 0);
        lp_io_lsu_s1_kill = ($urandom_range(0, 7) == 0);
        lp_io_lsu_s2_kill = ($urandom_range(0, 7) == 0);
        lp_io_lsu_s1_kill_data_read = ($urandom_range(0, 7) == 0);
        lp_io_tag_read_ready = ($urandom_range(0, 3) != 0);
        lp_io_banked_data_read_ready = ($urandom_range(0, 3) != 0);
        lp_io_miss_req_ready = ($urandom_range(0, 3) != 0);
        lp_io_wbq_block_miss_req = ($urandom_range(0, 7) == 0);
        lp_io_bank_conflict_slow = ($urandom_range(0, 7) == 0);
        lp_io_occupy_fail = ($urandom_range(0, 3) == 0);
        lp_io_read_error_delayed_0 = ($urandom_range(0, 7) == 0);
        lp_io_read_error_delayed_1 = ($urandom_range(0, 7) == 0);
        lp_io_counter_filter_query_resp = ($urandom_range(0, 1) == 0);
        if (lp_mode[1:0] == 2'd0) lp_io_lsu_req_valid = 1'b1;
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&lp_armed)) begin
        checks++;
        if (lp_g_io_lsu_req_ready !== lp_i_io_lsu_req_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_req_ready g=%h i=%h", cyc, lp_g_io_lsu_req_ready, lp_i_io_lsu_req_ready);
        end
        lp_s1_io_lsu_req_ready |= lp_g_io_lsu_req_ready;
        lp_s0_io_lsu_req_ready |= ~lp_g_io_lsu_req_ready;
        checks++;
        if (lp_g_io_lsu_resp_valid !== lp_i_io_lsu_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_valid g=%h i=%h", cyc, lp_g_io_lsu_resp_valid, lp_i_io_lsu_resp_valid);
        end
        lp_s1_io_lsu_resp_valid |= lp_g_io_lsu_resp_valid;
        lp_s0_io_lsu_resp_valid |= ~lp_g_io_lsu_resp_valid;
        checks++;
        if (lp_g_io_lsu_resp_bits_data !== lp_i_io_lsu_resp_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_data g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_data, lp_i_io_lsu_resp_bits_data);
        end
        lp_s1_io_lsu_resp_bits_data |= lp_g_io_lsu_resp_bits_data;
        lp_s0_io_lsu_resp_bits_data |= ~lp_g_io_lsu_resp_bits_data;
        checks++;
        if (lp_g_io_lsu_resp_bits_data_delayed !== lp_i_io_lsu_resp_bits_data_delayed) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_data_delayed g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_data_delayed, lp_i_io_lsu_resp_bits_data_delayed);
        end
        lp_s1_io_lsu_resp_bits_data_delayed |= lp_g_io_lsu_resp_bits_data_delayed;
        lp_s0_io_lsu_resp_bits_data_delayed |= ~lp_g_io_lsu_resp_bits_data_delayed;
        checks++;
        if (lp_g_io_lsu_resp_bits_miss !== lp_i_io_lsu_resp_bits_miss) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_miss g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_miss, lp_i_io_lsu_resp_bits_miss);
        end
        lp_s1_io_lsu_resp_bits_miss |= lp_g_io_lsu_resp_bits_miss;
        lp_s0_io_lsu_resp_bits_miss |= ~lp_g_io_lsu_resp_bits_miss;
        checks++;
        if (lp_g_io_lsu_resp_bits_mshr_id !== lp_i_io_lsu_resp_bits_mshr_id) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_mshr_id g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_mshr_id, lp_i_io_lsu_resp_bits_mshr_id);
        end
        lp_s1_io_lsu_resp_bits_mshr_id |= lp_g_io_lsu_resp_bits_mshr_id;
        lp_s0_io_lsu_resp_bits_mshr_id |= ~lp_g_io_lsu_resp_bits_mshr_id;
        checks++;
        if (lp_g_io_lsu_resp_bits_meta_prefetch !== lp_i_io_lsu_resp_bits_meta_prefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_meta_prefetch g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_meta_prefetch, lp_i_io_lsu_resp_bits_meta_prefetch);
        end
        lp_s1_io_lsu_resp_bits_meta_prefetch |= lp_g_io_lsu_resp_bits_meta_prefetch;
        lp_s0_io_lsu_resp_bits_meta_prefetch |= ~lp_g_io_lsu_resp_bits_meta_prefetch;
        checks++;
        if (lp_g_io_lsu_resp_bits_handled !== lp_i_io_lsu_resp_bits_handled) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_handled g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_handled, lp_i_io_lsu_resp_bits_handled);
        end
        lp_s1_io_lsu_resp_bits_handled |= lp_g_io_lsu_resp_bits_handled;
        lp_s0_io_lsu_resp_bits_handled |= ~lp_g_io_lsu_resp_bits_handled;
        checks++;
        if (lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied !== lp_i_io_lsu_resp_bits_tl_error_delayed_tl_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_tl_error_delayed_tl_denied g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied, lp_i_io_lsu_resp_bits_tl_error_delayed_tl_denied);
        end
        lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_denied |= lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied;
        lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_denied |= ~lp_g_io_lsu_resp_bits_tl_error_delayed_tl_denied;
        checks++;
        if (lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt !== lp_i_io_lsu_resp_bits_tl_error_delayed_tl_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_resp_bits_tl_error_delayed_tl_corrupt g=%h i=%h", cyc, lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt, lp_i_io_lsu_resp_bits_tl_error_delayed_tl_corrupt);
        end
        lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_corrupt |= lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt;
        lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_corrupt |= ~lp_g_io_lsu_resp_bits_tl_error_delayed_tl_corrupt;
        checks++;
        if (lp_g_io_lsu_s2_bank_conflict !== lp_i_io_lsu_s2_bank_conflict) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_s2_bank_conflict g=%h i=%h", cyc, lp_g_io_lsu_s2_bank_conflict, lp_i_io_lsu_s2_bank_conflict);
        end
        lp_s1_io_lsu_s2_bank_conflict |= lp_g_io_lsu_s2_bank_conflict;
        lp_s0_io_lsu_s2_bank_conflict |= ~lp_g_io_lsu_s2_bank_conflict;
        checks++;
        if (lp_g_io_lsu_s2_mq_nack !== lp_i_io_lsu_s2_mq_nack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_lsu_s2_mq_nack g=%h i=%h", cyc, lp_g_io_lsu_s2_mq_nack, lp_i_io_lsu_s2_mq_nack);
        end
        lp_s1_io_lsu_s2_mq_nack |= lp_g_io_lsu_s2_mq_nack;
        lp_s0_io_lsu_s2_mq_nack |= ~lp_g_io_lsu_s2_mq_nack;
        checks++;
        if (lp_g_io_meta_read_valid !== lp_i_io_meta_read_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_meta_read_valid g=%h i=%h", cyc, lp_g_io_meta_read_valid, lp_i_io_meta_read_valid);
        end
        lp_s1_io_meta_read_valid |= lp_g_io_meta_read_valid;
        lp_s0_io_meta_read_valid |= ~lp_g_io_meta_read_valid;
        checks++;
        if (lp_g_io_meta_read_bits_idx !== lp_i_io_meta_read_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_meta_read_bits_idx g=%h i=%h", cyc, lp_g_io_meta_read_bits_idx, lp_i_io_meta_read_bits_idx);
        end
        lp_s1_io_meta_read_bits_idx |= lp_g_io_meta_read_bits_idx;
        lp_s0_io_meta_read_bits_idx |= ~lp_g_io_meta_read_bits_idx;
        checks++;
        if (lp_g_io_tag_read_valid !== lp_i_io_tag_read_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_tag_read_valid g=%h i=%h", cyc, lp_g_io_tag_read_valid, lp_i_io_tag_read_valid);
        end
        lp_s1_io_tag_read_valid |= lp_g_io_tag_read_valid;
        lp_s0_io_tag_read_valid |= ~lp_g_io_tag_read_valid;
        checks++;
        if (lp_g_io_tag_read_bits_idx !== lp_i_io_tag_read_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_tag_read_bits_idx g=%h i=%h", cyc, lp_g_io_tag_read_bits_idx, lp_i_io_tag_read_bits_idx);
        end
        lp_s1_io_tag_read_bits_idx |= lp_g_io_tag_read_bits_idx;
        lp_s0_io_tag_read_bits_idx |= ~lp_g_io_tag_read_bits_idx;
        checks++;
        if (lp_g_io_banked_data_read_valid !== lp_i_io_banked_data_read_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_valid g=%h i=%h", cyc, lp_g_io_banked_data_read_valid, lp_i_io_banked_data_read_valid);
        end
        lp_s1_io_banked_data_read_valid |= lp_g_io_banked_data_read_valid;
        lp_s0_io_banked_data_read_valid |= ~lp_g_io_banked_data_read_valid;
        checks++;
        if (lp_g_io_banked_data_read_bits_way_en !== lp_i_io_banked_data_read_bits_way_en) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_way_en g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_way_en, lp_i_io_banked_data_read_bits_way_en);
        end
        lp_s1_io_banked_data_read_bits_way_en |= lp_g_io_banked_data_read_bits_way_en;
        lp_s0_io_banked_data_read_bits_way_en |= ~lp_g_io_banked_data_read_bits_way_en;
        checks++;
        if (lp_g_io_banked_data_read_bits_addr !== lp_i_io_banked_data_read_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_addr g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_addr, lp_i_io_banked_data_read_bits_addr);
        end
        lp_s1_io_banked_data_read_bits_addr |= lp_g_io_banked_data_read_bits_addr;
        lp_s0_io_banked_data_read_bits_addr |= ~lp_g_io_banked_data_read_bits_addr;
        checks++;
        if (lp_g_io_banked_data_read_bits_addr_dup !== lp_i_io_banked_data_read_bits_addr_dup) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_addr_dup g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_addr_dup, lp_i_io_banked_data_read_bits_addr_dup);
        end
        lp_s1_io_banked_data_read_bits_addr_dup |= lp_g_io_banked_data_read_bits_addr_dup;
        lp_s0_io_banked_data_read_bits_addr_dup |= ~lp_g_io_banked_data_read_bits_addr_dup;
        checks++;
        if (lp_g_io_banked_data_read_bits_bankMask !== lp_i_io_banked_data_read_bits_bankMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_bankMask g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_bankMask, lp_i_io_banked_data_read_bits_bankMask);
        end
        lp_s1_io_banked_data_read_bits_bankMask |= lp_g_io_banked_data_read_bits_bankMask;
        lp_s0_io_banked_data_read_bits_bankMask |= ~lp_g_io_banked_data_read_bits_bankMask;
        checks++;
        if (lp_g_io_banked_data_read_bits_lqIdx_flag !== lp_i_io_banked_data_read_bits_lqIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_lqIdx_flag g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_lqIdx_flag, lp_i_io_banked_data_read_bits_lqIdx_flag);
        end
        lp_s1_io_banked_data_read_bits_lqIdx_flag |= lp_g_io_banked_data_read_bits_lqIdx_flag;
        lp_s0_io_banked_data_read_bits_lqIdx_flag |= ~lp_g_io_banked_data_read_bits_lqIdx_flag;
        checks++;
        if (lp_g_io_banked_data_read_bits_lqIdx_value !== lp_i_io_banked_data_read_bits_lqIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_banked_data_read_bits_lqIdx_value g=%h i=%h", cyc, lp_g_io_banked_data_read_bits_lqIdx_value, lp_i_io_banked_data_read_bits_lqIdx_value);
        end
        lp_s1_io_banked_data_read_bits_lqIdx_value |= lp_g_io_banked_data_read_bits_lqIdx_value;
        lp_s0_io_banked_data_read_bits_lqIdx_value |= ~lp_g_io_banked_data_read_bits_lqIdx_value;
        checks++;
        if (lp_g_io_is128Req !== lp_i_io_is128Req) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_is128Req g=%h i=%h", cyc, lp_g_io_is128Req, lp_i_io_is128Req);
        end
        lp_s1_io_is128Req |= lp_g_io_is128Req;
        lp_s0_io_is128Req |= ~lp_g_io_is128Req;
        checks++;
        if (lp_g_io_access_flag_write_valid !== lp_i_io_access_flag_write_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_access_flag_write_valid g=%h i=%h", cyc, lp_g_io_access_flag_write_valid, lp_i_io_access_flag_write_valid);
        end
        lp_s1_io_access_flag_write_valid |= lp_g_io_access_flag_write_valid;
        lp_s0_io_access_flag_write_valid |= ~lp_g_io_access_flag_write_valid;
        checks++;
        if (lp_g_io_access_flag_write_bits_idx !== lp_i_io_access_flag_write_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_access_flag_write_bits_idx g=%h i=%h", cyc, lp_g_io_access_flag_write_bits_idx, lp_i_io_access_flag_write_bits_idx);
        end
        lp_s1_io_access_flag_write_bits_idx |= lp_g_io_access_flag_write_bits_idx;
        lp_s0_io_access_flag_write_bits_idx |= ~lp_g_io_access_flag_write_bits_idx;
        checks++;
        if (lp_g_io_access_flag_write_bits_way_en !== lp_i_io_access_flag_write_bits_way_en) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_access_flag_write_bits_way_en g=%h i=%h", cyc, lp_g_io_access_flag_write_bits_way_en, lp_i_io_access_flag_write_bits_way_en);
        end
        lp_s1_io_access_flag_write_bits_way_en |= lp_g_io_access_flag_write_bits_way_en;
        lp_s0_io_access_flag_write_bits_way_en |= ~lp_g_io_access_flag_write_bits_way_en;
        checks++;
        if (lp_g_io_prefetch_flag_write_valid !== lp_i_io_prefetch_flag_write_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_flag_write_valid g=%h i=%h", cyc, lp_g_io_prefetch_flag_write_valid, lp_i_io_prefetch_flag_write_valid);
        end
        lp_s1_io_prefetch_flag_write_valid |= lp_g_io_prefetch_flag_write_valid;
        lp_s0_io_prefetch_flag_write_valid |= ~lp_g_io_prefetch_flag_write_valid;
        checks++;
        if (lp_g_io_prefetch_flag_write_bits_idx !== lp_i_io_prefetch_flag_write_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_flag_write_bits_idx g=%h i=%h", cyc, lp_g_io_prefetch_flag_write_bits_idx, lp_i_io_prefetch_flag_write_bits_idx);
        end
        lp_s1_io_prefetch_flag_write_bits_idx |= lp_g_io_prefetch_flag_write_bits_idx;
        lp_s0_io_prefetch_flag_write_bits_idx |= ~lp_g_io_prefetch_flag_write_bits_idx;
        checks++;
        if (lp_g_io_prefetch_flag_write_bits_way_en !== lp_i_io_prefetch_flag_write_bits_way_en) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_flag_write_bits_way_en g=%h i=%h", cyc, lp_g_io_prefetch_flag_write_bits_way_en, lp_i_io_prefetch_flag_write_bits_way_en);
        end
        lp_s1_io_prefetch_flag_write_bits_way_en |= lp_g_io_prefetch_flag_write_bits_way_en;
        lp_s0_io_prefetch_flag_write_bits_way_en |= ~lp_g_io_prefetch_flag_write_bits_way_en;
        checks++;
        if (lp_g_io_miss_req_valid !== lp_i_io_miss_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_valid g=%h i=%h", cyc, lp_g_io_miss_req_valid, lp_i_io_miss_req_valid);
        end
        lp_s1_io_miss_req_valid |= lp_g_io_miss_req_valid;
        lp_s0_io_miss_req_valid |= ~lp_g_io_miss_req_valid;
        checks++;
        if (lp_g_io_miss_req_bits_source !== lp_i_io_miss_req_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_source g=%h i=%h", cyc, lp_g_io_miss_req_bits_source, lp_i_io_miss_req_bits_source);
        end
        lp_s1_io_miss_req_bits_source |= lp_g_io_miss_req_bits_source;
        lp_s0_io_miss_req_bits_source |= ~lp_g_io_miss_req_bits_source;
        checks++;
        if (lp_g_io_miss_req_bits_pf_source !== lp_i_io_miss_req_bits_pf_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_pf_source g=%h i=%h", cyc, lp_g_io_miss_req_bits_pf_source, lp_i_io_miss_req_bits_pf_source);
        end
        lp_s1_io_miss_req_bits_pf_source |= lp_g_io_miss_req_bits_pf_source;
        lp_s0_io_miss_req_bits_pf_source |= ~lp_g_io_miss_req_bits_pf_source;
        checks++;
        if (lp_g_io_miss_req_bits_cmd !== lp_i_io_miss_req_bits_cmd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_cmd g=%h i=%h", cyc, lp_g_io_miss_req_bits_cmd, lp_i_io_miss_req_bits_cmd);
        end
        lp_s1_io_miss_req_bits_cmd |= lp_g_io_miss_req_bits_cmd;
        lp_s0_io_miss_req_bits_cmd |= ~lp_g_io_miss_req_bits_cmd;
        checks++;
        if (lp_g_io_miss_req_bits_addr !== lp_i_io_miss_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_addr g=%h i=%h", cyc, lp_g_io_miss_req_bits_addr, lp_i_io_miss_req_bits_addr);
        end
        lp_s1_io_miss_req_bits_addr |= lp_g_io_miss_req_bits_addr;
        lp_s0_io_miss_req_bits_addr |= ~lp_g_io_miss_req_bits_addr;
        checks++;
        if (lp_g_io_miss_req_bits_vaddr !== lp_i_io_miss_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_vaddr g=%h i=%h", cyc, lp_g_io_miss_req_bits_vaddr, lp_i_io_miss_req_bits_vaddr);
        end
        lp_s1_io_miss_req_bits_vaddr |= lp_g_io_miss_req_bits_vaddr;
        lp_s0_io_miss_req_bits_vaddr |= ~lp_g_io_miss_req_bits_vaddr;
        checks++;
        if (lp_g_io_miss_req_bits_req_coh_state !== lp_i_io_miss_req_bits_req_coh_state) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_req_coh_state g=%h i=%h", cyc, lp_g_io_miss_req_bits_req_coh_state, lp_i_io_miss_req_bits_req_coh_state);
        end
        lp_s1_io_miss_req_bits_req_coh_state |= lp_g_io_miss_req_bits_req_coh_state;
        lp_s0_io_miss_req_bits_req_coh_state |= ~lp_g_io_miss_req_bits_req_coh_state;
        checks++;
        if (lp_g_io_miss_req_bits_isBtoT !== lp_i_io_miss_req_bits_isBtoT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_isBtoT g=%h i=%h", cyc, lp_g_io_miss_req_bits_isBtoT, lp_i_io_miss_req_bits_isBtoT);
        end
        lp_s1_io_miss_req_bits_isBtoT |= lp_g_io_miss_req_bits_isBtoT;
        lp_s0_io_miss_req_bits_isBtoT |= ~lp_g_io_miss_req_bits_isBtoT;
        checks++;
        if (lp_g_io_miss_req_bits_occupy_way !== lp_i_io_miss_req_bits_occupy_way) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_occupy_way g=%h i=%h", cyc, lp_g_io_miss_req_bits_occupy_way, lp_i_io_miss_req_bits_occupy_way);
        end
        lp_s1_io_miss_req_bits_occupy_way |= lp_g_io_miss_req_bits_occupy_way;
        lp_s0_io_miss_req_bits_occupy_way |= ~lp_g_io_miss_req_bits_occupy_way;
        checks++;
        if (lp_g_io_miss_req_bits_cancel !== lp_i_io_miss_req_bits_cancel) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_miss_req_bits_cancel g=%h i=%h", cyc, lp_g_io_miss_req_bits_cancel, lp_i_io_miss_req_bits_cancel);
        end
        lp_s1_io_miss_req_bits_cancel |= lp_g_io_miss_req_bits_cancel;
        lp_s0_io_miss_req_bits_cancel |= ~lp_g_io_miss_req_bits_cancel;
        checks++;
        if (lp_g_io_wbq_conflict_check_valid !== lp_i_io_wbq_conflict_check_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_wbq_conflict_check_valid g=%h i=%h", cyc, lp_g_io_wbq_conflict_check_valid, lp_i_io_wbq_conflict_check_valid);
        end
        lp_s1_io_wbq_conflict_check_valid |= lp_g_io_wbq_conflict_check_valid;
        lp_s0_io_wbq_conflict_check_valid |= ~lp_g_io_wbq_conflict_check_valid;
        checks++;
        if (lp_g_io_wbq_conflict_check_bits !== lp_i_io_wbq_conflict_check_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_wbq_conflict_check_bits g=%h i=%h", cyc, lp_g_io_wbq_conflict_check_bits, lp_i_io_wbq_conflict_check_bits);
        end
        lp_s1_io_wbq_conflict_check_bits |= lp_g_io_wbq_conflict_check_bits;
        lp_s0_io_wbq_conflict_check_bits |= ~lp_g_io_wbq_conflict_check_bits;
        checks++;
        if (lp_g_io_replace_access_valid !== lp_i_io_replace_access_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_replace_access_valid g=%h i=%h", cyc, lp_g_io_replace_access_valid, lp_i_io_replace_access_valid);
        end
        lp_s1_io_replace_access_valid |= lp_g_io_replace_access_valid;
        lp_s0_io_replace_access_valid |= ~lp_g_io_replace_access_valid;
        checks++;
        if (lp_g_io_replace_access_bits_set !== lp_i_io_replace_access_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_replace_access_bits_set g=%h i=%h", cyc, lp_g_io_replace_access_bits_set, lp_i_io_replace_access_bits_set);
        end
        lp_s1_io_replace_access_bits_set |= lp_g_io_replace_access_bits_set;
        lp_s0_io_replace_access_bits_set |= ~lp_g_io_replace_access_bits_set;
        checks++;
        if (lp_g_io_replace_access_bits_way !== lp_i_io_replace_access_bits_way) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_replace_access_bits_way g=%h i=%h", cyc, lp_g_io_replace_access_bits_way, lp_i_io_replace_access_bits_way);
        end
        lp_s1_io_replace_access_bits_way |= lp_g_io_replace_access_bits_way;
        lp_s0_io_replace_access_bits_way |= ~lp_g_io_replace_access_bits_way;
        checks++;
        if (lp_g_io_occupy_set !== lp_i_io_occupy_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_occupy_set g=%h i=%h", cyc, lp_g_io_occupy_set, lp_i_io_occupy_set);
        end
        lp_s1_io_occupy_set |= lp_g_io_occupy_set;
        lp_s0_io_occupy_set |= ~lp_g_io_occupy_set;
        checks++;
        if (lp_g_io_error_valid !== lp_i_io_error_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_error_valid g=%h i=%h", cyc, lp_g_io_error_valid, lp_i_io_error_valid);
        end
        lp_s1_io_error_valid |= lp_g_io_error_valid;
        lp_s0_io_error_valid |= ~lp_g_io_error_valid;
        checks++;
        if (lp_g_io_error_bits_paddr !== lp_i_io_error_bits_paddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_error_bits_paddr g=%h i=%h", cyc, lp_g_io_error_bits_paddr, lp_i_io_error_bits_paddr);
        end
        lp_s1_io_error_bits_paddr |= lp_g_io_error_bits_paddr;
        lp_s0_io_error_bits_paddr |= ~lp_g_io_error_bits_paddr;
        checks++;
        if (lp_g_io_error_bits_report_to_beu !== lp_i_io_error_bits_report_to_beu) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_error_bits_report_to_beu g=%h i=%h", cyc, lp_g_io_error_bits_report_to_beu, lp_i_io_error_bits_report_to_beu);
        end
        lp_s1_io_error_bits_report_to_beu |= lp_g_io_error_bits_report_to_beu;
        lp_s0_io_error_bits_report_to_beu |= ~lp_g_io_error_bits_report_to_beu;
        checks++;
        if (lp_g_io_pseudo_tag_error_inj_done !== lp_i_io_pseudo_tag_error_inj_done) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_pseudo_tag_error_inj_done g=%h i=%h", cyc, lp_g_io_pseudo_tag_error_inj_done, lp_i_io_pseudo_tag_error_inj_done);
        end
        lp_s1_io_pseudo_tag_error_inj_done |= lp_g_io_pseudo_tag_error_inj_done;
        lp_s0_io_pseudo_tag_error_inj_done |= ~lp_g_io_pseudo_tag_error_inj_done;
        checks++;
        if (lp_g_io_pseudo_data_error_inj_done !== lp_i_io_pseudo_data_error_inj_done) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_pseudo_data_error_inj_done g=%h i=%h", cyc, lp_g_io_pseudo_data_error_inj_done, lp_i_io_pseudo_data_error_inj_done);
        end
        lp_s1_io_pseudo_data_error_inj_done |= lp_g_io_pseudo_data_error_inj_done;
        lp_s0_io_pseudo_data_error_inj_done |= ~lp_g_io_pseudo_data_error_inj_done;
        checks++;
        if (lp_g_io_prefetch_info_naive_total_prefetch !== lp_i_io_prefetch_info_naive_total_prefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_total_prefetch g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_total_prefetch, lp_i_io_prefetch_info_naive_total_prefetch);
        end
        lp_s1_io_prefetch_info_naive_total_prefetch |= lp_g_io_prefetch_info_naive_total_prefetch;
        lp_s0_io_prefetch_info_naive_total_prefetch |= ~lp_g_io_prefetch_info_naive_total_prefetch;
        checks++;
        if (lp_g_io_prefetch_info_naive_late_hit_prefetch !== lp_i_io_prefetch_info_naive_late_hit_prefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_late_hit_prefetch g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_late_hit_prefetch, lp_i_io_prefetch_info_naive_late_hit_prefetch);
        end
        lp_s1_io_prefetch_info_naive_late_hit_prefetch |= lp_g_io_prefetch_info_naive_late_hit_prefetch;
        lp_s0_io_prefetch_info_naive_late_hit_prefetch |= ~lp_g_io_prefetch_info_naive_late_hit_prefetch;
        checks++;
        if (lp_g_io_prefetch_info_naive_late_prefetch_hit !== lp_i_io_prefetch_info_naive_late_prefetch_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_late_prefetch_hit g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_late_prefetch_hit, lp_i_io_prefetch_info_naive_late_prefetch_hit);
        end
        lp_s1_io_prefetch_info_naive_late_prefetch_hit |= lp_g_io_prefetch_info_naive_late_prefetch_hit;
        lp_s0_io_prefetch_info_naive_late_prefetch_hit |= ~lp_g_io_prefetch_info_naive_late_prefetch_hit;
        checks++;
        if (lp_g_io_prefetch_info_naive_late_load_hit !== lp_i_io_prefetch_info_naive_late_load_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_late_load_hit g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_late_load_hit, lp_i_io_prefetch_info_naive_late_load_hit);
        end
        lp_s1_io_prefetch_info_naive_late_load_hit |= lp_g_io_prefetch_info_naive_late_load_hit;
        lp_s0_io_prefetch_info_naive_late_load_hit |= ~lp_g_io_prefetch_info_naive_late_load_hit;
        checks++;
        if (lp_g_io_prefetch_info_naive_useful_prefetch !== lp_i_io_prefetch_info_naive_useful_prefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_useful_prefetch g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_useful_prefetch, lp_i_io_prefetch_info_naive_useful_prefetch);
        end
        lp_s1_io_prefetch_info_naive_useful_prefetch |= lp_g_io_prefetch_info_naive_useful_prefetch;
        lp_s0_io_prefetch_info_naive_useful_prefetch |= ~lp_g_io_prefetch_info_naive_useful_prefetch;
        checks++;
        if (lp_g_io_prefetch_info_naive_prefetch_hit !== lp_i_io_prefetch_info_naive_prefetch_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_naive_prefetch_hit g=%h i=%h", cyc, lp_g_io_prefetch_info_naive_prefetch_hit, lp_i_io_prefetch_info_naive_prefetch_hit);
        end
        lp_s1_io_prefetch_info_naive_prefetch_hit |= lp_g_io_prefetch_info_naive_prefetch_hit;
        lp_s0_io_prefetch_info_naive_prefetch_hit |= ~lp_g_io_prefetch_info_naive_prefetch_hit;
        checks++;
        if (lp_g_io_prefetch_info_fdp_useful_prefetch !== lp_i_io_prefetch_info_fdp_useful_prefetch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_fdp_useful_prefetch g=%h i=%h", cyc, lp_g_io_prefetch_info_fdp_useful_prefetch, lp_i_io_prefetch_info_fdp_useful_prefetch);
        end
        lp_s1_io_prefetch_info_fdp_useful_prefetch |= lp_g_io_prefetch_info_fdp_useful_prefetch;
        lp_s0_io_prefetch_info_fdp_useful_prefetch |= ~lp_g_io_prefetch_info_fdp_useful_prefetch;
        checks++;
        if (lp_g_io_prefetch_info_fdp_demand_miss !== lp_i_io_prefetch_info_fdp_demand_miss) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_fdp_demand_miss g=%h i=%h", cyc, lp_g_io_prefetch_info_fdp_demand_miss, lp_i_io_prefetch_info_fdp_demand_miss);
        end
        lp_s1_io_prefetch_info_fdp_demand_miss |= lp_g_io_prefetch_info_fdp_demand_miss;
        lp_s0_io_prefetch_info_fdp_demand_miss |= ~lp_g_io_prefetch_info_fdp_demand_miss;
        checks++;
        if (lp_g_io_prefetch_info_fdp_pollution !== lp_i_io_prefetch_info_fdp_pollution) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_prefetch_info_fdp_pollution g=%h i=%h", cyc, lp_g_io_prefetch_info_fdp_pollution, lp_i_io_prefetch_info_fdp_pollution);
        end
        lp_s1_io_prefetch_info_fdp_pollution |= lp_g_io_prefetch_info_fdp_pollution;
        lp_s0_io_prefetch_info_fdp_pollution |= ~lp_g_io_prefetch_info_fdp_pollution;
        checks++;
        if (lp_g_io_bloom_filter_query_query_valid !== lp_i_io_bloom_filter_query_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_bloom_filter_query_query_valid g=%h i=%h", cyc, lp_g_io_bloom_filter_query_query_valid, lp_i_io_bloom_filter_query_query_valid);
        end
        lp_s1_io_bloom_filter_query_query_valid |= lp_g_io_bloom_filter_query_query_valid;
        lp_s0_io_bloom_filter_query_query_valid |= ~lp_g_io_bloom_filter_query_query_valid;
        checks++;
        if (lp_g_io_bloom_filter_query_query_bits_addr !== lp_i_io_bloom_filter_query_query_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_bloom_filter_query_query_bits_addr g=%h i=%h", cyc, lp_g_io_bloom_filter_query_query_bits_addr, lp_i_io_bloom_filter_query_query_bits_addr);
        end
        lp_s1_io_bloom_filter_query_query_bits_addr |= lp_g_io_bloom_filter_query_query_bits_addr;
        lp_s0_io_bloom_filter_query_query_bits_addr |= ~lp_g_io_bloom_filter_query_query_bits_addr;
        checks++;
        if (lp_g_io_counter_filter_query_req_valid !== lp_i_io_counter_filter_query_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_query_req_valid g=%h i=%h", cyc, lp_g_io_counter_filter_query_req_valid, lp_i_io_counter_filter_query_req_valid);
        end
        lp_s1_io_counter_filter_query_req_valid |= lp_g_io_counter_filter_query_req_valid;
        lp_s0_io_counter_filter_query_req_valid |= ~lp_g_io_counter_filter_query_req_valid;
        checks++;
        if (lp_g_io_counter_filter_query_req_bits_idx !== lp_i_io_counter_filter_query_req_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_query_req_bits_idx g=%h i=%h", cyc, lp_g_io_counter_filter_query_req_bits_idx, lp_i_io_counter_filter_query_req_bits_idx);
        end
        lp_s1_io_counter_filter_query_req_bits_idx |= lp_g_io_counter_filter_query_req_bits_idx;
        lp_s0_io_counter_filter_query_req_bits_idx |= ~lp_g_io_counter_filter_query_req_bits_idx;
        checks++;
        if (lp_g_io_counter_filter_query_req_bits_way !== lp_i_io_counter_filter_query_req_bits_way) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_query_req_bits_way g=%h i=%h", cyc, lp_g_io_counter_filter_query_req_bits_way, lp_i_io_counter_filter_query_req_bits_way);
        end
        lp_s1_io_counter_filter_query_req_bits_way |= lp_g_io_counter_filter_query_req_bits_way;
        lp_s0_io_counter_filter_query_req_bits_way |= ~lp_g_io_counter_filter_query_req_bits_way;
        checks++;
        if (lp_g_io_counter_filter_enq_valid !== lp_i_io_counter_filter_enq_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_enq_valid g=%h i=%h", cyc, lp_g_io_counter_filter_enq_valid, lp_i_io_counter_filter_enq_valid);
        end
        lp_s1_io_counter_filter_enq_valid |= lp_g_io_counter_filter_enq_valid;
        lp_s0_io_counter_filter_enq_valid |= ~lp_g_io_counter_filter_enq_valid;
        checks++;
        if (lp_g_io_counter_filter_enq_bits_idx !== lp_i_io_counter_filter_enq_bits_idx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_enq_bits_idx g=%h i=%h", cyc, lp_g_io_counter_filter_enq_bits_idx, lp_i_io_counter_filter_enq_bits_idx);
        end
        lp_s1_io_counter_filter_enq_bits_idx |= lp_g_io_counter_filter_enq_bits_idx;
        lp_s0_io_counter_filter_enq_bits_idx |= ~lp_g_io_counter_filter_enq_bits_idx;
        checks++;
        if (lp_g_io_counter_filter_enq_bits_way !== lp_i_io_counter_filter_enq_bits_way) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_counter_filter_enq_bits_way g=%h i=%h", cyc, lp_g_io_counter_filter_enq_bits_way, lp_i_io_counter_filter_enq_bits_way);
        end
        lp_s1_io_counter_filter_enq_bits_way |= lp_g_io_counter_filter_enq_bits_way;
        lp_s0_io_counter_filter_enq_bits_way |= ~lp_g_io_counter_filter_enq_bits_way;
        checks++;
        if (lp_g_io_perf_0_value !== lp_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_0_value g=%h i=%h", cyc, lp_g_io_perf_0_value, lp_i_io_perf_0_value);
        end
        lp_s1_io_perf_0_value |= lp_g_io_perf_0_value;
        lp_s0_io_perf_0_value |= ~lp_g_io_perf_0_value;
        checks++;
        if (lp_g_io_perf_1_value !== lp_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_1_value g=%h i=%h", cyc, lp_g_io_perf_1_value, lp_i_io_perf_1_value);
        end
        lp_s1_io_perf_1_value |= lp_g_io_perf_1_value;
        lp_s0_io_perf_1_value |= ~lp_g_io_perf_1_value;
        checks++;
        if (lp_g_io_perf_2_value !== lp_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_2_value g=%h i=%h", cyc, lp_g_io_perf_2_value, lp_i_io_perf_2_value);
        end
        lp_s1_io_perf_2_value |= lp_g_io_perf_2_value;
        lp_s0_io_perf_2_value |= ~lp_g_io_perf_2_value;
        checks++;
        if (lp_g_io_perf_3_value !== lp_i_io_perf_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_3_value g=%h i=%h", cyc, lp_g_io_perf_3_value, lp_i_io_perf_3_value);
        end
        lp_s1_io_perf_3_value |= lp_g_io_perf_3_value;
        lp_s0_io_perf_3_value |= ~lp_g_io_perf_3_value;
        checks++;
        if (lp_g_io_perf_4_value !== lp_i_io_perf_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_4_value g=%h i=%h", cyc, lp_g_io_perf_4_value, lp_i_io_perf_4_value);
        end
        lp_s1_io_perf_4_value |= lp_g_io_perf_4_value;
        lp_s0_io_perf_4_value |= ~lp_g_io_perf_4_value;
        checks++;
        if (lp_g_io_perf_5_value !== lp_i_io_perf_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_5_value g=%h i=%h", cyc, lp_g_io_perf_5_value, lp_i_io_perf_5_value);
        end
        lp_s1_io_perf_5_value |= lp_g_io_perf_5_value;
        lp_s0_io_perf_5_value |= ~lp_g_io_perf_5_value;
        checks++;
        if (lp_g_io_perf_6_value !== lp_i_io_perf_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LoadPipe.io_perf_6_value g=%h i=%h", cyc, lp_g_io_perf_6_value, lp_i_io_perf_6_value);
        end
        lp_s1_io_perf_6_value |= lp_g_io_perf_6_value;
        lp_s0_io_perf_6_value |= ~lp_g_io_perf_6_value;
        if (lp_u_gold.s1_valid && lp_u_gold.s1_tag_match_dup_dc && lp_u_gold.s1_has_permission) lp_cov_s1_hit++;
        if (lp_u_gold.s1_valid && lp_u_gold.s1_tag_match_dup_dc && !lp_u_gold.s1_has_permission) lp_cov_s1_hit_noperm++;
        if (lp_g_io_lsu_resp_valid && lp_g_io_lsu_resp_bits_miss) lp_cov_s2_real_miss++;
        if (lp_g_io_miss_req_valid && lp_io_miss_req_ready && !lp_g_io_miss_req_bits_cancel) lp_cov_miss_fire++;
        if (lp_u_gold.s2_nack_no_mshr) lp_cov_nack_no_mshr++;
        if (lp_u_gold.s2_valid && lp_u_gold.s2_nack_data) lp_cov_nack_data++;
        if (lp_u_gold.s2_valid && (|lp_u_gold.s2_tag_errors)) lp_cov_tag_error++;
        if (lp_u_gold.s2_valid && lp_u_gold.s2_grow_perm_btot) lp_cov_btot++;
        if (lp_u_gold.s2_valid && lp_u_gold.s2_btot_occupy_fail) lp_cov_btot_occupy_fail++;
        if (lp_g_io_lsu_resp_valid && lp_g_io_lsu_resp_bits_handled) lp_cov_handled++;
        if (lp_u_gold.s1_valid && lp_io_pseudo_error_valid && lp_io_pseudo_error_bits_0_valid) lp_cov_pseudo_tag++;
        if (lp_g_io_error_valid) lp_cov_error_valid++;
        if (lp_u_gold.s3_valid && lp_u_gold.s3_load128Req && lp_u_gold.s3_data_error) lp_cov_data_error_128++;
        if (lp_g_io_prefetch_flag_write_valid) lp_cov_pf_counted++;
        if (lp_g_io_counter_filter_query_req_valid && lp_io_counter_filter_query_resp) lp_cov_pf_filtered++;
        if (lp_g_io_prefetch_info_naive_late_prefetch_hit) lp_cov_late_prefetch_hit++;
        if (lp_g_io_prefetch_info_fdp_pollution) lp_cov_pollution++;
        if (lp_g_io_replace_access_valid) lp_cov_replace_access++;
      end
      if (lp_u_gold.s2_valid) lp_armed[0] = 1'b1;
      if (lp_armed_at < 0 && (&lp_armed)) lp_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(lp_s0_io_lsu_req_ready && lp_s1_io_lsu_req_ready)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_req_ready 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_valid && lp_s1_io_lsu_resp_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[0] && lp_s1_io_lsu_resp_bits_data[0])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[1] && lp_s1_io_lsu_resp_bits_data[1])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[2] && lp_s1_io_lsu_resp_bits_data[2])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[3] && lp_s1_io_lsu_resp_bits_data[3])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[4] && lp_s1_io_lsu_resp_bits_data[4])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[5] && lp_s1_io_lsu_resp_bits_data[5])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[6] && lp_s1_io_lsu_resp_bits_data[6])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[7] && lp_s1_io_lsu_resp_bits_data[7])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[8] && lp_s1_io_lsu_resp_bits_data[8])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[9] && lp_s1_io_lsu_resp_bits_data[9])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[10] && lp_s1_io_lsu_resp_bits_data[10])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[11] && lp_s1_io_lsu_resp_bits_data[11])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[12] && lp_s1_io_lsu_resp_bits_data[12])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[13] && lp_s1_io_lsu_resp_bits_data[13])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[14] && lp_s1_io_lsu_resp_bits_data[14])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[15] && lp_s1_io_lsu_resp_bits_data[15])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[16] && lp_s1_io_lsu_resp_bits_data[16])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[17] && lp_s1_io_lsu_resp_bits_data[17])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[18] && lp_s1_io_lsu_resp_bits_data[18])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[19] && lp_s1_io_lsu_resp_bits_data[19])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[20] && lp_s1_io_lsu_resp_bits_data[20])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[21] && lp_s1_io_lsu_resp_bits_data[21])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[22] && lp_s1_io_lsu_resp_bits_data[22])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[23] && lp_s1_io_lsu_resp_bits_data[23])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[24] && lp_s1_io_lsu_resp_bits_data[24])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[25] && lp_s1_io_lsu_resp_bits_data[25])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[26] && lp_s1_io_lsu_resp_bits_data[26])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[27] && lp_s1_io_lsu_resp_bits_data[27])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[28] && lp_s1_io_lsu_resp_bits_data[28])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[29] && lp_s1_io_lsu_resp_bits_data[29])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[30] && lp_s1_io_lsu_resp_bits_data[30])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[31] && lp_s1_io_lsu_resp_bits_data[31])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[32] && lp_s1_io_lsu_resp_bits_data[32])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[33] && lp_s1_io_lsu_resp_bits_data[33])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[34] && lp_s1_io_lsu_resp_bits_data[34])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[35] && lp_s1_io_lsu_resp_bits_data[35])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[36] && lp_s1_io_lsu_resp_bits_data[36])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[37] && lp_s1_io_lsu_resp_bits_data[37])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[38] && lp_s1_io_lsu_resp_bits_data[38])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[39] && lp_s1_io_lsu_resp_bits_data[39])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[40] && lp_s1_io_lsu_resp_bits_data[40])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[41] && lp_s1_io_lsu_resp_bits_data[41])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[42] && lp_s1_io_lsu_resp_bits_data[42])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[43] && lp_s1_io_lsu_resp_bits_data[43])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[44] && lp_s1_io_lsu_resp_bits_data[44])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[45] && lp_s1_io_lsu_resp_bits_data[45])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[46] && lp_s1_io_lsu_resp_bits_data[46])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[47] && lp_s1_io_lsu_resp_bits_data[47])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[48] && lp_s1_io_lsu_resp_bits_data[48])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[48] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[49] && lp_s1_io_lsu_resp_bits_data[49])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[49] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[50] && lp_s1_io_lsu_resp_bits_data[50])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[50] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[51] && lp_s1_io_lsu_resp_bits_data[51])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[51] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[52] && lp_s1_io_lsu_resp_bits_data[52])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[52] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[53] && lp_s1_io_lsu_resp_bits_data[53])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[53] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[54] && lp_s1_io_lsu_resp_bits_data[54])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[54] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[55] && lp_s1_io_lsu_resp_bits_data[55])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[55] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[56] && lp_s1_io_lsu_resp_bits_data[56])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[56] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[57] && lp_s1_io_lsu_resp_bits_data[57])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[57] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[58] && lp_s1_io_lsu_resp_bits_data[58])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[58] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[59] && lp_s1_io_lsu_resp_bits_data[59])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[59] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[60] && lp_s1_io_lsu_resp_bits_data[60])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[60] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[61] && lp_s1_io_lsu_resp_bits_data[61])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[61] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[62] && lp_s1_io_lsu_resp_bits_data[62])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[62] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[63] && lp_s1_io_lsu_resp_bits_data[63])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[63] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[64] && lp_s1_io_lsu_resp_bits_data[64])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[64] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[65] && lp_s1_io_lsu_resp_bits_data[65])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[65] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[66] && lp_s1_io_lsu_resp_bits_data[66])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[66] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[67] && lp_s1_io_lsu_resp_bits_data[67])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[67] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[68] && lp_s1_io_lsu_resp_bits_data[68])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[68] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[69] && lp_s1_io_lsu_resp_bits_data[69])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[69] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[70] && lp_s1_io_lsu_resp_bits_data[70])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[70] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[71] && lp_s1_io_lsu_resp_bits_data[71])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[71] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[72] && lp_s1_io_lsu_resp_bits_data[72])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[72] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[73] && lp_s1_io_lsu_resp_bits_data[73])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[73] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[74] && lp_s1_io_lsu_resp_bits_data[74])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[74] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[75] && lp_s1_io_lsu_resp_bits_data[75])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[75] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[76] && lp_s1_io_lsu_resp_bits_data[76])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[76] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[77] && lp_s1_io_lsu_resp_bits_data[77])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[77] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[78] && lp_s1_io_lsu_resp_bits_data[78])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[78] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[79] && lp_s1_io_lsu_resp_bits_data[79])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[79] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[80] && lp_s1_io_lsu_resp_bits_data[80])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[80] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[81] && lp_s1_io_lsu_resp_bits_data[81])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[81] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[82] && lp_s1_io_lsu_resp_bits_data[82])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[82] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[83] && lp_s1_io_lsu_resp_bits_data[83])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[83] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[84] && lp_s1_io_lsu_resp_bits_data[84])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[84] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[85] && lp_s1_io_lsu_resp_bits_data[85])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[85] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[86] && lp_s1_io_lsu_resp_bits_data[86])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[86] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[87] && lp_s1_io_lsu_resp_bits_data[87])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[87] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[88] && lp_s1_io_lsu_resp_bits_data[88])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[88] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[89] && lp_s1_io_lsu_resp_bits_data[89])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[89] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[90] && lp_s1_io_lsu_resp_bits_data[90])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[90] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[91] && lp_s1_io_lsu_resp_bits_data[91])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[91] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[92] && lp_s1_io_lsu_resp_bits_data[92])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[92] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[93] && lp_s1_io_lsu_resp_bits_data[93])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[93] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[94] && lp_s1_io_lsu_resp_bits_data[94])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[94] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[95] && lp_s1_io_lsu_resp_bits_data[95])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[95] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[96] && lp_s1_io_lsu_resp_bits_data[96])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[96] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[97] && lp_s1_io_lsu_resp_bits_data[97])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[97] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[98] && lp_s1_io_lsu_resp_bits_data[98])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[98] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[99] && lp_s1_io_lsu_resp_bits_data[99])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[99] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[100] && lp_s1_io_lsu_resp_bits_data[100])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[100] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[101] && lp_s1_io_lsu_resp_bits_data[101])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[101] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[102] && lp_s1_io_lsu_resp_bits_data[102])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[102] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[103] && lp_s1_io_lsu_resp_bits_data[103])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[103] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[104] && lp_s1_io_lsu_resp_bits_data[104])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[104] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[105] && lp_s1_io_lsu_resp_bits_data[105])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[105] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[106] && lp_s1_io_lsu_resp_bits_data[106])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[106] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[107] && lp_s1_io_lsu_resp_bits_data[107])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[107] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[108] && lp_s1_io_lsu_resp_bits_data[108])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[108] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[109] && lp_s1_io_lsu_resp_bits_data[109])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[109] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[110] && lp_s1_io_lsu_resp_bits_data[110])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[110] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[111] && lp_s1_io_lsu_resp_bits_data[111])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[111] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[112] && lp_s1_io_lsu_resp_bits_data[112])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[112] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[113] && lp_s1_io_lsu_resp_bits_data[113])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[113] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[114] && lp_s1_io_lsu_resp_bits_data[114])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[114] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[115] && lp_s1_io_lsu_resp_bits_data[115])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[115] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[116] && lp_s1_io_lsu_resp_bits_data[116])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[116] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[117] && lp_s1_io_lsu_resp_bits_data[117])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[117] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[118] && lp_s1_io_lsu_resp_bits_data[118])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[118] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[119] && lp_s1_io_lsu_resp_bits_data[119])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[119] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[120] && lp_s1_io_lsu_resp_bits_data[120])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[120] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[121] && lp_s1_io_lsu_resp_bits_data[121])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[121] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[122] && lp_s1_io_lsu_resp_bits_data[122])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[122] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[123] && lp_s1_io_lsu_resp_bits_data[123])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[123] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[124] && lp_s1_io_lsu_resp_bits_data[124])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[124] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[125] && lp_s1_io_lsu_resp_bits_data[125])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[125] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[126] && lp_s1_io_lsu_resp_bits_data[126])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[126] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data[127] && lp_s1_io_lsu_resp_bits_data[127])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data[127] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[0] && lp_s1_io_lsu_resp_bits_data_delayed[0])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[1] && lp_s1_io_lsu_resp_bits_data_delayed[1])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[2] && lp_s1_io_lsu_resp_bits_data_delayed[2])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[3] && lp_s1_io_lsu_resp_bits_data_delayed[3])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[4] && lp_s1_io_lsu_resp_bits_data_delayed[4])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[5] && lp_s1_io_lsu_resp_bits_data_delayed[5])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[6] && lp_s1_io_lsu_resp_bits_data_delayed[6])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[7] && lp_s1_io_lsu_resp_bits_data_delayed[7])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[8] && lp_s1_io_lsu_resp_bits_data_delayed[8])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[9] && lp_s1_io_lsu_resp_bits_data_delayed[9])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[10] && lp_s1_io_lsu_resp_bits_data_delayed[10])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[11] && lp_s1_io_lsu_resp_bits_data_delayed[11])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[12] && lp_s1_io_lsu_resp_bits_data_delayed[12])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[13] && lp_s1_io_lsu_resp_bits_data_delayed[13])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[14] && lp_s1_io_lsu_resp_bits_data_delayed[14])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[15] && lp_s1_io_lsu_resp_bits_data_delayed[15])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[16] && lp_s1_io_lsu_resp_bits_data_delayed[16])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[17] && lp_s1_io_lsu_resp_bits_data_delayed[17])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[18] && lp_s1_io_lsu_resp_bits_data_delayed[18])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[19] && lp_s1_io_lsu_resp_bits_data_delayed[19])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[20] && lp_s1_io_lsu_resp_bits_data_delayed[20])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[21] && lp_s1_io_lsu_resp_bits_data_delayed[21])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[22] && lp_s1_io_lsu_resp_bits_data_delayed[22])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[23] && lp_s1_io_lsu_resp_bits_data_delayed[23])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[24] && lp_s1_io_lsu_resp_bits_data_delayed[24])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[25] && lp_s1_io_lsu_resp_bits_data_delayed[25])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[26] && lp_s1_io_lsu_resp_bits_data_delayed[26])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[27] && lp_s1_io_lsu_resp_bits_data_delayed[27])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[28] && lp_s1_io_lsu_resp_bits_data_delayed[28])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[29] && lp_s1_io_lsu_resp_bits_data_delayed[29])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[30] && lp_s1_io_lsu_resp_bits_data_delayed[30])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[31] && lp_s1_io_lsu_resp_bits_data_delayed[31])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[32] && lp_s1_io_lsu_resp_bits_data_delayed[32])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[33] && lp_s1_io_lsu_resp_bits_data_delayed[33])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[34] && lp_s1_io_lsu_resp_bits_data_delayed[34])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[35] && lp_s1_io_lsu_resp_bits_data_delayed[35])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[36] && lp_s1_io_lsu_resp_bits_data_delayed[36])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[37] && lp_s1_io_lsu_resp_bits_data_delayed[37])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[38] && lp_s1_io_lsu_resp_bits_data_delayed[38])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[39] && lp_s1_io_lsu_resp_bits_data_delayed[39])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[40] && lp_s1_io_lsu_resp_bits_data_delayed[40])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[41] && lp_s1_io_lsu_resp_bits_data_delayed[41])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[42] && lp_s1_io_lsu_resp_bits_data_delayed[42])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[43] && lp_s1_io_lsu_resp_bits_data_delayed[43])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[44] && lp_s1_io_lsu_resp_bits_data_delayed[44])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[45] && lp_s1_io_lsu_resp_bits_data_delayed[45])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[46] && lp_s1_io_lsu_resp_bits_data_delayed[46])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[47] && lp_s1_io_lsu_resp_bits_data_delayed[47])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[48] && lp_s1_io_lsu_resp_bits_data_delayed[48])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[48] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[49] && lp_s1_io_lsu_resp_bits_data_delayed[49])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[49] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[50] && lp_s1_io_lsu_resp_bits_data_delayed[50])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[50] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[51] && lp_s1_io_lsu_resp_bits_data_delayed[51])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[51] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[52] && lp_s1_io_lsu_resp_bits_data_delayed[52])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[52] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[53] && lp_s1_io_lsu_resp_bits_data_delayed[53])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[53] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[54] && lp_s1_io_lsu_resp_bits_data_delayed[54])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[54] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[55] && lp_s1_io_lsu_resp_bits_data_delayed[55])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[55] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[56] && lp_s1_io_lsu_resp_bits_data_delayed[56])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[56] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[57] && lp_s1_io_lsu_resp_bits_data_delayed[57])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[57] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[58] && lp_s1_io_lsu_resp_bits_data_delayed[58])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[58] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[59] && lp_s1_io_lsu_resp_bits_data_delayed[59])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[59] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[60] && lp_s1_io_lsu_resp_bits_data_delayed[60])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[60] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[61] && lp_s1_io_lsu_resp_bits_data_delayed[61])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[61] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[62] && lp_s1_io_lsu_resp_bits_data_delayed[62])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[62] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[63] && lp_s1_io_lsu_resp_bits_data_delayed[63])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[63] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[64] && lp_s1_io_lsu_resp_bits_data_delayed[64])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[64] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[65] && lp_s1_io_lsu_resp_bits_data_delayed[65])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[65] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[66] && lp_s1_io_lsu_resp_bits_data_delayed[66])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[66] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[67] && lp_s1_io_lsu_resp_bits_data_delayed[67])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[67] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[68] && lp_s1_io_lsu_resp_bits_data_delayed[68])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[68] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[69] && lp_s1_io_lsu_resp_bits_data_delayed[69])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[69] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[70] && lp_s1_io_lsu_resp_bits_data_delayed[70])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[70] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[71] && lp_s1_io_lsu_resp_bits_data_delayed[71])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[71] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[72] && lp_s1_io_lsu_resp_bits_data_delayed[72])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[72] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[73] && lp_s1_io_lsu_resp_bits_data_delayed[73])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[73] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[74] && lp_s1_io_lsu_resp_bits_data_delayed[74])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[74] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[75] && lp_s1_io_lsu_resp_bits_data_delayed[75])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[75] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[76] && lp_s1_io_lsu_resp_bits_data_delayed[76])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[76] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[77] && lp_s1_io_lsu_resp_bits_data_delayed[77])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[77] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[78] && lp_s1_io_lsu_resp_bits_data_delayed[78])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[78] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[79] && lp_s1_io_lsu_resp_bits_data_delayed[79])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[79] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[80] && lp_s1_io_lsu_resp_bits_data_delayed[80])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[80] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[81] && lp_s1_io_lsu_resp_bits_data_delayed[81])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[81] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[82] && lp_s1_io_lsu_resp_bits_data_delayed[82])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[82] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[83] && lp_s1_io_lsu_resp_bits_data_delayed[83])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[83] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[84] && lp_s1_io_lsu_resp_bits_data_delayed[84])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[84] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[85] && lp_s1_io_lsu_resp_bits_data_delayed[85])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[85] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[86] && lp_s1_io_lsu_resp_bits_data_delayed[86])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[86] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[87] && lp_s1_io_lsu_resp_bits_data_delayed[87])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[87] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[88] && lp_s1_io_lsu_resp_bits_data_delayed[88])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[88] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[89] && lp_s1_io_lsu_resp_bits_data_delayed[89])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[89] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[90] && lp_s1_io_lsu_resp_bits_data_delayed[90])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[90] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[91] && lp_s1_io_lsu_resp_bits_data_delayed[91])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[91] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[92] && lp_s1_io_lsu_resp_bits_data_delayed[92])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[92] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[93] && lp_s1_io_lsu_resp_bits_data_delayed[93])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[93] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[94] && lp_s1_io_lsu_resp_bits_data_delayed[94])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[94] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[95] && lp_s1_io_lsu_resp_bits_data_delayed[95])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[95] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[96] && lp_s1_io_lsu_resp_bits_data_delayed[96])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[96] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[97] && lp_s1_io_lsu_resp_bits_data_delayed[97])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[97] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[98] && lp_s1_io_lsu_resp_bits_data_delayed[98])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[98] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[99] && lp_s1_io_lsu_resp_bits_data_delayed[99])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[99] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[100] && lp_s1_io_lsu_resp_bits_data_delayed[100])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[100] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[101] && lp_s1_io_lsu_resp_bits_data_delayed[101])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[101] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[102] && lp_s1_io_lsu_resp_bits_data_delayed[102])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[102] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[103] && lp_s1_io_lsu_resp_bits_data_delayed[103])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[103] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[104] && lp_s1_io_lsu_resp_bits_data_delayed[104])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[104] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[105] && lp_s1_io_lsu_resp_bits_data_delayed[105])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[105] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[106] && lp_s1_io_lsu_resp_bits_data_delayed[106])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[106] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[107] && lp_s1_io_lsu_resp_bits_data_delayed[107])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[107] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[108] && lp_s1_io_lsu_resp_bits_data_delayed[108])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[108] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[109] && lp_s1_io_lsu_resp_bits_data_delayed[109])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[109] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[110] && lp_s1_io_lsu_resp_bits_data_delayed[110])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[110] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[111] && lp_s1_io_lsu_resp_bits_data_delayed[111])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[111] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[112] && lp_s1_io_lsu_resp_bits_data_delayed[112])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[112] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[113] && lp_s1_io_lsu_resp_bits_data_delayed[113])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[113] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[114] && lp_s1_io_lsu_resp_bits_data_delayed[114])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[114] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[115] && lp_s1_io_lsu_resp_bits_data_delayed[115])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[115] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[116] && lp_s1_io_lsu_resp_bits_data_delayed[116])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[116] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[117] && lp_s1_io_lsu_resp_bits_data_delayed[117])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[117] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[118] && lp_s1_io_lsu_resp_bits_data_delayed[118])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[118] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[119] && lp_s1_io_lsu_resp_bits_data_delayed[119])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[119] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[120] && lp_s1_io_lsu_resp_bits_data_delayed[120])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[120] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[121] && lp_s1_io_lsu_resp_bits_data_delayed[121])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[121] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[122] && lp_s1_io_lsu_resp_bits_data_delayed[122])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[122] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[123] && lp_s1_io_lsu_resp_bits_data_delayed[123])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[123] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[124] && lp_s1_io_lsu_resp_bits_data_delayed[124])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[124] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[125] && lp_s1_io_lsu_resp_bits_data_delayed[125])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[125] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[126] && lp_s1_io_lsu_resp_bits_data_delayed[126])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[126] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_data_delayed[127] && lp_s1_io_lsu_resp_bits_data_delayed[127])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_data_delayed[127] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_miss && lp_s1_io_lsu_resp_bits_miss)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_miss 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_mshr_id[0] && lp_s1_io_lsu_resp_bits_mshr_id[0])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_mshr_id[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_mshr_id[1] && lp_s1_io_lsu_resp_bits_mshr_id[1])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_mshr_id[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_mshr_id[2] && lp_s1_io_lsu_resp_bits_mshr_id[2])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_mshr_id[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_mshr_id[3] && lp_s1_io_lsu_resp_bits_mshr_id[3])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_mshr_id[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_meta_prefetch[0] && lp_s1_io_lsu_resp_bits_meta_prefetch[0])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_meta_prefetch[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_meta_prefetch[1] && lp_s1_io_lsu_resp_bits_meta_prefetch[1])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_meta_prefetch[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_meta_prefetch[2] && lp_s1_io_lsu_resp_bits_meta_prefetch[2])) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_meta_prefetch[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_handled && lp_s1_io_lsu_resp_bits_handled)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_handled 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_denied && lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_denied)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_tl_error_delayed_tl_denied 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_resp_bits_tl_error_delayed_tl_corrupt && lp_s1_io_lsu_resp_bits_tl_error_delayed_tl_corrupt)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_resp_bits_tl_error_delayed_tl_corrupt 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_s2_bank_conflict && lp_s1_io_lsu_s2_bank_conflict)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_s2_bank_conflict 未见过 0 和 1"); end
    if (!(lp_s0_io_lsu_s2_mq_nack && lp_s1_io_lsu_s2_mq_nack)) begin cov_fail++; $display("[COV] LoadPipe.io_lsu_s2_mq_nack 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_valid && lp_s1_io_meta_read_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[0] && lp_s1_io_meta_read_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[1] && lp_s1_io_meta_read_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[2] && lp_s1_io_meta_read_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[3] && lp_s1_io_meta_read_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[4] && lp_s1_io_meta_read_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[5] && lp_s1_io_meta_read_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[6] && lp_s1_io_meta_read_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_meta_read_bits_idx[7] && lp_s1_io_meta_read_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_meta_read_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_valid && lp_s1_io_tag_read_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[0] && lp_s1_io_tag_read_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[1] && lp_s1_io_tag_read_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[2] && lp_s1_io_tag_read_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[3] && lp_s1_io_tag_read_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[4] && lp_s1_io_tag_read_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[5] && lp_s1_io_tag_read_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[6] && lp_s1_io_tag_read_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_tag_read_bits_idx[7] && lp_s1_io_tag_read_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_tag_read_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_valid && lp_s1_io_banked_data_read_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_way_en[0] && lp_s1_io_banked_data_read_bits_way_en[0])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_way_en[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_way_en[1] && lp_s1_io_banked_data_read_bits_way_en[1])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_way_en[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_way_en[2] && lp_s1_io_banked_data_read_bits_way_en[2])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_way_en[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_way_en[3] && lp_s1_io_banked_data_read_bits_way_en[3])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_way_en[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[0] && lp_s1_io_banked_data_read_bits_addr[0])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[1] && lp_s1_io_banked_data_read_bits_addr[1])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[2] && lp_s1_io_banked_data_read_bits_addr[2])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[3] && lp_s1_io_banked_data_read_bits_addr[3])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[4] && lp_s1_io_banked_data_read_bits_addr[4])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[5] && lp_s1_io_banked_data_read_bits_addr[5])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[6] && lp_s1_io_banked_data_read_bits_addr[6])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[7] && lp_s1_io_banked_data_read_bits_addr[7])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[8] && lp_s1_io_banked_data_read_bits_addr[8])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[9] && lp_s1_io_banked_data_read_bits_addr[9])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[10] && lp_s1_io_banked_data_read_bits_addr[10])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[11] && lp_s1_io_banked_data_read_bits_addr[11])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[12] && lp_s1_io_banked_data_read_bits_addr[12])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[13] && lp_s1_io_banked_data_read_bits_addr[13])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[14] && lp_s1_io_banked_data_read_bits_addr[14])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[15] && lp_s1_io_banked_data_read_bits_addr[15])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[16] && lp_s1_io_banked_data_read_bits_addr[16])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[17] && lp_s1_io_banked_data_read_bits_addr[17])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[18] && lp_s1_io_banked_data_read_bits_addr[18])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[19] && lp_s1_io_banked_data_read_bits_addr[19])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[20] && lp_s1_io_banked_data_read_bits_addr[20])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[21] && lp_s1_io_banked_data_read_bits_addr[21])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[22] && lp_s1_io_banked_data_read_bits_addr[22])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[23] && lp_s1_io_banked_data_read_bits_addr[23])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[24] && lp_s1_io_banked_data_read_bits_addr[24])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[25] && lp_s1_io_banked_data_read_bits_addr[25])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[26] && lp_s1_io_banked_data_read_bits_addr[26])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[27] && lp_s1_io_banked_data_read_bits_addr[27])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[28] && lp_s1_io_banked_data_read_bits_addr[28])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[29] && lp_s1_io_banked_data_read_bits_addr[29])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[30] && lp_s1_io_banked_data_read_bits_addr[30])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[31] && lp_s1_io_banked_data_read_bits_addr[31])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[32] && lp_s1_io_banked_data_read_bits_addr[32])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[33] && lp_s1_io_banked_data_read_bits_addr[33])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[34] && lp_s1_io_banked_data_read_bits_addr[34])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[35] && lp_s1_io_banked_data_read_bits_addr[35])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[36] && lp_s1_io_banked_data_read_bits_addr[36])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[37] && lp_s1_io_banked_data_read_bits_addr[37])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[38] && lp_s1_io_banked_data_read_bits_addr[38])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[39] && lp_s1_io_banked_data_read_bits_addr[39])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[40] && lp_s1_io_banked_data_read_bits_addr[40])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[41] && lp_s1_io_banked_data_read_bits_addr[41])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[42] && lp_s1_io_banked_data_read_bits_addr[42])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[43] && lp_s1_io_banked_data_read_bits_addr[43])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[44] && lp_s1_io_banked_data_read_bits_addr[44])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[45] && lp_s1_io_banked_data_read_bits_addr[45])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[46] && lp_s1_io_banked_data_read_bits_addr[46])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr[47] && lp_s1_io_banked_data_read_bits_addr[47])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[0] && lp_s1_io_banked_data_read_bits_addr_dup[0])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[1] && lp_s1_io_banked_data_read_bits_addr_dup[1])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[2] && lp_s1_io_banked_data_read_bits_addr_dup[2])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[3] && lp_s1_io_banked_data_read_bits_addr_dup[3])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[4] && lp_s1_io_banked_data_read_bits_addr_dup[4])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[5] && lp_s1_io_banked_data_read_bits_addr_dup[5])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[6] && lp_s1_io_banked_data_read_bits_addr_dup[6])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[7] && lp_s1_io_banked_data_read_bits_addr_dup[7])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[8] && lp_s1_io_banked_data_read_bits_addr_dup[8])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[9] && lp_s1_io_banked_data_read_bits_addr_dup[9])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[10] && lp_s1_io_banked_data_read_bits_addr_dup[10])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[11] && lp_s1_io_banked_data_read_bits_addr_dup[11])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[12] && lp_s1_io_banked_data_read_bits_addr_dup[12])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[13] && lp_s1_io_banked_data_read_bits_addr_dup[13])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[14] && lp_s1_io_banked_data_read_bits_addr_dup[14])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[15] && lp_s1_io_banked_data_read_bits_addr_dup[15])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[16] && lp_s1_io_banked_data_read_bits_addr_dup[16])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[17] && lp_s1_io_banked_data_read_bits_addr_dup[17])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[18] && lp_s1_io_banked_data_read_bits_addr_dup[18])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[19] && lp_s1_io_banked_data_read_bits_addr_dup[19])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[20] && lp_s1_io_banked_data_read_bits_addr_dup[20])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[21] && lp_s1_io_banked_data_read_bits_addr_dup[21])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[22] && lp_s1_io_banked_data_read_bits_addr_dup[22])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[23] && lp_s1_io_banked_data_read_bits_addr_dup[23])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[24] && lp_s1_io_banked_data_read_bits_addr_dup[24])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[25] && lp_s1_io_banked_data_read_bits_addr_dup[25])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[26] && lp_s1_io_banked_data_read_bits_addr_dup[26])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[27] && lp_s1_io_banked_data_read_bits_addr_dup[27])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[28] && lp_s1_io_banked_data_read_bits_addr_dup[28])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[29] && lp_s1_io_banked_data_read_bits_addr_dup[29])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[30] && lp_s1_io_banked_data_read_bits_addr_dup[30])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[31] && lp_s1_io_banked_data_read_bits_addr_dup[31])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[32] && lp_s1_io_banked_data_read_bits_addr_dup[32])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[33] && lp_s1_io_banked_data_read_bits_addr_dup[33])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[34] && lp_s1_io_banked_data_read_bits_addr_dup[34])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[35] && lp_s1_io_banked_data_read_bits_addr_dup[35])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[36] && lp_s1_io_banked_data_read_bits_addr_dup[36])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[37] && lp_s1_io_banked_data_read_bits_addr_dup[37])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[38] && lp_s1_io_banked_data_read_bits_addr_dup[38])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[39] && lp_s1_io_banked_data_read_bits_addr_dup[39])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[40] && lp_s1_io_banked_data_read_bits_addr_dup[40])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[41] && lp_s1_io_banked_data_read_bits_addr_dup[41])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[42] && lp_s1_io_banked_data_read_bits_addr_dup[42])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[43] && lp_s1_io_banked_data_read_bits_addr_dup[43])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[44] && lp_s1_io_banked_data_read_bits_addr_dup[44])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[45] && lp_s1_io_banked_data_read_bits_addr_dup[45])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[46] && lp_s1_io_banked_data_read_bits_addr_dup[46])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_addr_dup[47] && lp_s1_io_banked_data_read_bits_addr_dup[47])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_addr_dup[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[0] && lp_s1_io_banked_data_read_bits_bankMask[0])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[1] && lp_s1_io_banked_data_read_bits_bankMask[1])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[2] && lp_s1_io_banked_data_read_bits_bankMask[2])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[3] && lp_s1_io_banked_data_read_bits_bankMask[3])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[4] && lp_s1_io_banked_data_read_bits_bankMask[4])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[5] && lp_s1_io_banked_data_read_bits_bankMask[5])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[6] && lp_s1_io_banked_data_read_bits_bankMask[6])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_bankMask[7] && lp_s1_io_banked_data_read_bits_bankMask[7])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_bankMask[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_flag && lp_s1_io_banked_data_read_bits_lqIdx_flag)) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_flag 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[0] && lp_s1_io_banked_data_read_bits_lqIdx_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[1] && lp_s1_io_banked_data_read_bits_lqIdx_value[1])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[2] && lp_s1_io_banked_data_read_bits_lqIdx_value[2])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[3] && lp_s1_io_banked_data_read_bits_lqIdx_value[3])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[4] && lp_s1_io_banked_data_read_bits_lqIdx_value[4])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[5] && lp_s1_io_banked_data_read_bits_lqIdx_value[5])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_banked_data_read_bits_lqIdx_value[6] && lp_s1_io_banked_data_read_bits_lqIdx_value[6])) begin cov_fail++; $display("[COV] LoadPipe.io_banked_data_read_bits_lqIdx_value[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_is128Req && lp_s1_io_is128Req)) begin cov_fail++; $display("[COV] LoadPipe.io_is128Req 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_valid && lp_s1_io_access_flag_write_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[0] && lp_s1_io_access_flag_write_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[1] && lp_s1_io_access_flag_write_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[2] && lp_s1_io_access_flag_write_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[3] && lp_s1_io_access_flag_write_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[4] && lp_s1_io_access_flag_write_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[5] && lp_s1_io_access_flag_write_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[6] && lp_s1_io_access_flag_write_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_idx[7] && lp_s1_io_access_flag_write_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_way_en[0] && lp_s1_io_access_flag_write_bits_way_en[0])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_way_en[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_way_en[1] && lp_s1_io_access_flag_write_bits_way_en[1])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_way_en[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_way_en[2] && lp_s1_io_access_flag_write_bits_way_en[2])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_way_en[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_access_flag_write_bits_way_en[3] && lp_s1_io_access_flag_write_bits_way_en[3])) begin cov_fail++; $display("[COV] LoadPipe.io_access_flag_write_bits_way_en[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_valid && lp_s1_io_prefetch_flag_write_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[0] && lp_s1_io_prefetch_flag_write_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[1] && lp_s1_io_prefetch_flag_write_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[2] && lp_s1_io_prefetch_flag_write_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[3] && lp_s1_io_prefetch_flag_write_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[4] && lp_s1_io_prefetch_flag_write_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[5] && lp_s1_io_prefetch_flag_write_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[6] && lp_s1_io_prefetch_flag_write_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_idx[7] && lp_s1_io_prefetch_flag_write_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_way_en[0] && lp_s1_io_prefetch_flag_write_bits_way_en[0])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_way_en[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_way_en[1] && lp_s1_io_prefetch_flag_write_bits_way_en[1])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_way_en[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_way_en[2] && lp_s1_io_prefetch_flag_write_bits_way_en[2])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_way_en[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_flag_write_bits_way_en[3] && lp_s1_io_prefetch_flag_write_bits_way_en[3])) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_flag_write_bits_way_en[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_valid && lp_s1_io_miss_req_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_source[0] && lp_s1_io_miss_req_bits_source[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_source[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_source[1] && lp_s1_io_miss_req_bits_source[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_source[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_source[2] && lp_s1_io_miss_req_bits_source[2])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_source[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_source[3] && lp_s1_io_miss_req_bits_source[3])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_source[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_pf_source[0] && lp_s1_io_miss_req_bits_pf_source[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_pf_source[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_pf_source[1] && lp_s1_io_miss_req_bits_pf_source[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_pf_source[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_pf_source[2] && lp_s1_io_miss_req_bits_pf_source[2])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_pf_source[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cmd[0] && lp_s1_io_miss_req_bits_cmd[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cmd[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cmd[1] && lp_s1_io_miss_req_bits_cmd[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cmd[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cmd[2] && lp_s1_io_miss_req_bits_cmd[2])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cmd[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cmd[3] && lp_s1_io_miss_req_bits_cmd[3])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cmd[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cmd[4] && lp_s1_io_miss_req_bits_cmd[4])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cmd[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[6] && lp_s1_io_miss_req_bits_addr[6])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[7] && lp_s1_io_miss_req_bits_addr[7])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[8] && lp_s1_io_miss_req_bits_addr[8])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[9] && lp_s1_io_miss_req_bits_addr[9])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[10] && lp_s1_io_miss_req_bits_addr[10])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[11] && lp_s1_io_miss_req_bits_addr[11])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[12] && lp_s1_io_miss_req_bits_addr[12])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[13] && lp_s1_io_miss_req_bits_addr[13])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[14] && lp_s1_io_miss_req_bits_addr[14])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[15] && lp_s1_io_miss_req_bits_addr[15])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[16] && lp_s1_io_miss_req_bits_addr[16])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[17] && lp_s1_io_miss_req_bits_addr[17])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[18] && lp_s1_io_miss_req_bits_addr[18])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[19] && lp_s1_io_miss_req_bits_addr[19])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[20] && lp_s1_io_miss_req_bits_addr[20])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[21] && lp_s1_io_miss_req_bits_addr[21])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[22] && lp_s1_io_miss_req_bits_addr[22])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[23] && lp_s1_io_miss_req_bits_addr[23])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[24] && lp_s1_io_miss_req_bits_addr[24])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[25] && lp_s1_io_miss_req_bits_addr[25])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[26] && lp_s1_io_miss_req_bits_addr[26])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[27] && lp_s1_io_miss_req_bits_addr[27])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[28] && lp_s1_io_miss_req_bits_addr[28])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[29] && lp_s1_io_miss_req_bits_addr[29])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[30] && lp_s1_io_miss_req_bits_addr[30])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[31] && lp_s1_io_miss_req_bits_addr[31])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[32] && lp_s1_io_miss_req_bits_addr[32])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[33] && lp_s1_io_miss_req_bits_addr[33])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[34] && lp_s1_io_miss_req_bits_addr[34])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[35] && lp_s1_io_miss_req_bits_addr[35])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[36] && lp_s1_io_miss_req_bits_addr[36])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[37] && lp_s1_io_miss_req_bits_addr[37])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[38] && lp_s1_io_miss_req_bits_addr[38])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[39] && lp_s1_io_miss_req_bits_addr[39])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[40] && lp_s1_io_miss_req_bits_addr[40])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[41] && lp_s1_io_miss_req_bits_addr[41])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[42] && lp_s1_io_miss_req_bits_addr[42])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[43] && lp_s1_io_miss_req_bits_addr[43])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[44] && lp_s1_io_miss_req_bits_addr[44])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[45] && lp_s1_io_miss_req_bits_addr[45])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[46] && lp_s1_io_miss_req_bits_addr[46])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_addr[47] && lp_s1_io_miss_req_bits_addr[47])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[0] && lp_s1_io_miss_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[1] && lp_s1_io_miss_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[2] && lp_s1_io_miss_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[3] && lp_s1_io_miss_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[4] && lp_s1_io_miss_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[5] && lp_s1_io_miss_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[6] && lp_s1_io_miss_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[7] && lp_s1_io_miss_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[8] && lp_s1_io_miss_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[9] && lp_s1_io_miss_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[10] && lp_s1_io_miss_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[11] && lp_s1_io_miss_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[12] && lp_s1_io_miss_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[13] && lp_s1_io_miss_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[14] && lp_s1_io_miss_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[15] && lp_s1_io_miss_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[16] && lp_s1_io_miss_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[17] && lp_s1_io_miss_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[18] && lp_s1_io_miss_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[19] && lp_s1_io_miss_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[20] && lp_s1_io_miss_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[21] && lp_s1_io_miss_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[22] && lp_s1_io_miss_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[23] && lp_s1_io_miss_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[24] && lp_s1_io_miss_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[25] && lp_s1_io_miss_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[26] && lp_s1_io_miss_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[27] && lp_s1_io_miss_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[28] && lp_s1_io_miss_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[29] && lp_s1_io_miss_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[30] && lp_s1_io_miss_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[31] && lp_s1_io_miss_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[32] && lp_s1_io_miss_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[33] && lp_s1_io_miss_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[34] && lp_s1_io_miss_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[35] && lp_s1_io_miss_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[36] && lp_s1_io_miss_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[37] && lp_s1_io_miss_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[38] && lp_s1_io_miss_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[39] && lp_s1_io_miss_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[40] && lp_s1_io_miss_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[41] && lp_s1_io_miss_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[42] && lp_s1_io_miss_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[43] && lp_s1_io_miss_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[44] && lp_s1_io_miss_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[45] && lp_s1_io_miss_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[46] && lp_s1_io_miss_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[47] && lp_s1_io_miss_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[48] && lp_s1_io_miss_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_vaddr[49] && lp_s1_io_miss_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_req_coh_state[0] && lp_s1_io_miss_req_bits_req_coh_state[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_req_coh_state[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_req_coh_state[1] && lp_s1_io_miss_req_bits_req_coh_state[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_req_coh_state[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_isBtoT && lp_s1_io_miss_req_bits_isBtoT)) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_isBtoT 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_occupy_way[0] && lp_s1_io_miss_req_bits_occupy_way[0])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_occupy_way[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_occupy_way[1] && lp_s1_io_miss_req_bits_occupy_way[1])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_occupy_way[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_occupy_way[2] && lp_s1_io_miss_req_bits_occupy_way[2])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_occupy_way[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_occupy_way[3] && lp_s1_io_miss_req_bits_occupy_way[3])) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_occupy_way[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_miss_req_bits_cancel && lp_s1_io_miss_req_bits_cancel)) begin cov_fail++; $display("[COV] LoadPipe.io_miss_req_bits_cancel 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_valid && lp_s1_io_wbq_conflict_check_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[6] && lp_s1_io_wbq_conflict_check_bits[6])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[7] && lp_s1_io_wbq_conflict_check_bits[7])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[8] && lp_s1_io_wbq_conflict_check_bits[8])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[9] && lp_s1_io_wbq_conflict_check_bits[9])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[10] && lp_s1_io_wbq_conflict_check_bits[10])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[11] && lp_s1_io_wbq_conflict_check_bits[11])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[12] && lp_s1_io_wbq_conflict_check_bits[12])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[13] && lp_s1_io_wbq_conflict_check_bits[13])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[14] && lp_s1_io_wbq_conflict_check_bits[14])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[15] && lp_s1_io_wbq_conflict_check_bits[15])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[16] && lp_s1_io_wbq_conflict_check_bits[16])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[17] && lp_s1_io_wbq_conflict_check_bits[17])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[18] && lp_s1_io_wbq_conflict_check_bits[18])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[19] && lp_s1_io_wbq_conflict_check_bits[19])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[20] && lp_s1_io_wbq_conflict_check_bits[20])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[21] && lp_s1_io_wbq_conflict_check_bits[21])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[22] && lp_s1_io_wbq_conflict_check_bits[22])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[23] && lp_s1_io_wbq_conflict_check_bits[23])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[24] && lp_s1_io_wbq_conflict_check_bits[24])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[25] && lp_s1_io_wbq_conflict_check_bits[25])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[26] && lp_s1_io_wbq_conflict_check_bits[26])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[27] && lp_s1_io_wbq_conflict_check_bits[27])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[28] && lp_s1_io_wbq_conflict_check_bits[28])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[29] && lp_s1_io_wbq_conflict_check_bits[29])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[30] && lp_s1_io_wbq_conflict_check_bits[30])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[31] && lp_s1_io_wbq_conflict_check_bits[31])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[32] && lp_s1_io_wbq_conflict_check_bits[32])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[33] && lp_s1_io_wbq_conflict_check_bits[33])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[34] && lp_s1_io_wbq_conflict_check_bits[34])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[35] && lp_s1_io_wbq_conflict_check_bits[35])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[36] && lp_s1_io_wbq_conflict_check_bits[36])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[37] && lp_s1_io_wbq_conflict_check_bits[37])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[38] && lp_s1_io_wbq_conflict_check_bits[38])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[39] && lp_s1_io_wbq_conflict_check_bits[39])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[40] && lp_s1_io_wbq_conflict_check_bits[40])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[41] && lp_s1_io_wbq_conflict_check_bits[41])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[42] && lp_s1_io_wbq_conflict_check_bits[42])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[43] && lp_s1_io_wbq_conflict_check_bits[43])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[44] && lp_s1_io_wbq_conflict_check_bits[44])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[45] && lp_s1_io_wbq_conflict_check_bits[45])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[46] && lp_s1_io_wbq_conflict_check_bits[46])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_wbq_conflict_check_bits[47] && lp_s1_io_wbq_conflict_check_bits[47])) begin cov_fail++; $display("[COV] LoadPipe.io_wbq_conflict_check_bits[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_valid && lp_s1_io_replace_access_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[0] && lp_s1_io_replace_access_bits_set[0])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[1] && lp_s1_io_replace_access_bits_set[1])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[2] && lp_s1_io_replace_access_bits_set[2])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[3] && lp_s1_io_replace_access_bits_set[3])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[4] && lp_s1_io_replace_access_bits_set[4])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[5] && lp_s1_io_replace_access_bits_set[5])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[6] && lp_s1_io_replace_access_bits_set[6])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_set[7] && lp_s1_io_replace_access_bits_set[7])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_set[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_way[0] && lp_s1_io_replace_access_bits_way[0])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_way[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_replace_access_bits_way[1] && lp_s1_io_replace_access_bits_way[1])) begin cov_fail++; $display("[COV] LoadPipe.io_replace_access_bits_way[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[0] && lp_s1_io_occupy_set[0])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[1] && lp_s1_io_occupy_set[1])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[2] && lp_s1_io_occupy_set[2])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[3] && lp_s1_io_occupy_set[3])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[4] && lp_s1_io_occupy_set[4])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[5] && lp_s1_io_occupy_set[5])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[6] && lp_s1_io_occupy_set[6])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_occupy_set[7] && lp_s1_io_occupy_set[7])) begin cov_fail++; $display("[COV] LoadPipe.io_occupy_set[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_valid && lp_s1_io_error_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_error_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[0] && lp_s1_io_error_bits_paddr[0])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[1] && lp_s1_io_error_bits_paddr[1])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[2] && lp_s1_io_error_bits_paddr[2])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[3] && lp_s1_io_error_bits_paddr[3])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[4] && lp_s1_io_error_bits_paddr[4])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[5] && lp_s1_io_error_bits_paddr[5])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[6] && lp_s1_io_error_bits_paddr[6])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[7] && lp_s1_io_error_bits_paddr[7])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[8] && lp_s1_io_error_bits_paddr[8])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[9] && lp_s1_io_error_bits_paddr[9])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[10] && lp_s1_io_error_bits_paddr[10])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[11] && lp_s1_io_error_bits_paddr[11])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[12] && lp_s1_io_error_bits_paddr[12])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[12] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[13] && lp_s1_io_error_bits_paddr[13])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[13] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[14] && lp_s1_io_error_bits_paddr[14])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[14] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[15] && lp_s1_io_error_bits_paddr[15])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[15] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[16] && lp_s1_io_error_bits_paddr[16])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[16] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[17] && lp_s1_io_error_bits_paddr[17])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[17] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[18] && lp_s1_io_error_bits_paddr[18])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[18] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[19] && lp_s1_io_error_bits_paddr[19])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[19] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[20] && lp_s1_io_error_bits_paddr[20])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[20] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[21] && lp_s1_io_error_bits_paddr[21])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[21] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[22] && lp_s1_io_error_bits_paddr[22])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[22] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[23] && lp_s1_io_error_bits_paddr[23])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[23] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[24] && lp_s1_io_error_bits_paddr[24])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[24] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[25] && lp_s1_io_error_bits_paddr[25])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[25] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[26] && lp_s1_io_error_bits_paddr[26])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[26] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[27] && lp_s1_io_error_bits_paddr[27])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[27] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[28] && lp_s1_io_error_bits_paddr[28])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[28] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[29] && lp_s1_io_error_bits_paddr[29])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[29] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[30] && lp_s1_io_error_bits_paddr[30])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[30] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[31] && lp_s1_io_error_bits_paddr[31])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[31] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[32] && lp_s1_io_error_bits_paddr[32])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[32] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[33] && lp_s1_io_error_bits_paddr[33])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[33] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[34] && lp_s1_io_error_bits_paddr[34])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[34] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[35] && lp_s1_io_error_bits_paddr[35])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[35] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[36] && lp_s1_io_error_bits_paddr[36])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[36] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[37] && lp_s1_io_error_bits_paddr[37])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[37] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[38] && lp_s1_io_error_bits_paddr[38])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[38] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[39] && lp_s1_io_error_bits_paddr[39])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[39] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[40] && lp_s1_io_error_bits_paddr[40])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[40] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[41] && lp_s1_io_error_bits_paddr[41])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[41] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[42] && lp_s1_io_error_bits_paddr[42])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[42] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[43] && lp_s1_io_error_bits_paddr[43])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[43] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[44] && lp_s1_io_error_bits_paddr[44])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[44] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[45] && lp_s1_io_error_bits_paddr[45])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[45] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[46] && lp_s1_io_error_bits_paddr[46])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[46] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_paddr[47] && lp_s1_io_error_bits_paddr[47])) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_paddr[47] 未见过 0 和 1"); end
    if (!(lp_s0_io_error_bits_report_to_beu && lp_s1_io_error_bits_report_to_beu)) begin cov_fail++; $display("[COV] LoadPipe.io_error_bits_report_to_beu 未见过 0 和 1"); end
    if (!(lp_s0_io_pseudo_tag_error_inj_done && lp_s1_io_pseudo_tag_error_inj_done)) begin cov_fail++; $display("[COV] LoadPipe.io_pseudo_tag_error_inj_done 未见过 0 和 1"); end
    if (!(lp_s0_io_pseudo_data_error_inj_done && lp_s1_io_pseudo_data_error_inj_done)) begin cov_fail++; $display("[COV] LoadPipe.io_pseudo_data_error_inj_done 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_total_prefetch && lp_s1_io_prefetch_info_naive_total_prefetch)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_total_prefetch 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_late_hit_prefetch && lp_s1_io_prefetch_info_naive_late_hit_prefetch)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_late_hit_prefetch 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_late_prefetch_hit && lp_s1_io_prefetch_info_naive_late_prefetch_hit)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_late_prefetch_hit 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_late_load_hit && lp_s1_io_prefetch_info_naive_late_load_hit)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_late_load_hit 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_useful_prefetch && lp_s1_io_prefetch_info_naive_useful_prefetch)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_useful_prefetch 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_naive_prefetch_hit && lp_s1_io_prefetch_info_naive_prefetch_hit)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_naive_prefetch_hit 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_fdp_useful_prefetch && lp_s1_io_prefetch_info_fdp_useful_prefetch)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_fdp_useful_prefetch 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_fdp_demand_miss && lp_s1_io_prefetch_info_fdp_demand_miss)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_fdp_demand_miss 未见过 0 和 1"); end
    if (!(lp_s0_io_prefetch_info_fdp_pollution && lp_s1_io_prefetch_info_fdp_pollution)) begin cov_fail++; $display("[COV] LoadPipe.io_prefetch_info_fdp_pollution 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_valid && lp_s1_io_bloom_filter_query_query_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[0] && lp_s1_io_bloom_filter_query_query_bits_addr[0])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[1] && lp_s1_io_bloom_filter_query_query_bits_addr[1])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[2] && lp_s1_io_bloom_filter_query_query_bits_addr[2])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[3] && lp_s1_io_bloom_filter_query_query_bits_addr[3])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[4] && lp_s1_io_bloom_filter_query_query_bits_addr[4])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[5] && lp_s1_io_bloom_filter_query_query_bits_addr[5])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[6] && lp_s1_io_bloom_filter_query_query_bits_addr[6])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[7] && lp_s1_io_bloom_filter_query_query_bits_addr[7])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[8] && lp_s1_io_bloom_filter_query_query_bits_addr[8])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[8] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[9] && lp_s1_io_bloom_filter_query_query_bits_addr[9])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[9] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[10] && lp_s1_io_bloom_filter_query_query_bits_addr[10])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[10] 未见过 0 和 1"); end
    if (!(lp_s0_io_bloom_filter_query_query_bits_addr[11] && lp_s1_io_bloom_filter_query_query_bits_addr[11])) begin cov_fail++; $display("[COV] LoadPipe.io_bloom_filter_query_query_bits_addr[11] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_valid && lp_s1_io_counter_filter_query_req_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[0] && lp_s1_io_counter_filter_query_req_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[1] && lp_s1_io_counter_filter_query_req_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[2] && lp_s1_io_counter_filter_query_req_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[3] && lp_s1_io_counter_filter_query_req_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[4] && lp_s1_io_counter_filter_query_req_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[5] && lp_s1_io_counter_filter_query_req_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[6] && lp_s1_io_counter_filter_query_req_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_idx[7] && lp_s1_io_counter_filter_query_req_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_way[0] && lp_s1_io_counter_filter_query_req_bits_way[0])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_way[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_query_req_bits_way[1] && lp_s1_io_counter_filter_query_req_bits_way[1])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_query_req_bits_way[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_valid && lp_s1_io_counter_filter_enq_valid)) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_valid 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[0] && lp_s1_io_counter_filter_enq_bits_idx[0])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[1] && lp_s1_io_counter_filter_enq_bits_idx[1])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[2] && lp_s1_io_counter_filter_enq_bits_idx[2])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[2] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[3] && lp_s1_io_counter_filter_enq_bits_idx[3])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[3] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[4] && lp_s1_io_counter_filter_enq_bits_idx[4])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[4] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[5] && lp_s1_io_counter_filter_enq_bits_idx[5])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[5] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[6] && lp_s1_io_counter_filter_enq_bits_idx[6])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[6] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_idx[7] && lp_s1_io_counter_filter_enq_bits_idx[7])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_idx[7] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_way[0] && lp_s1_io_counter_filter_enq_bits_way[0])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_way[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_counter_filter_enq_bits_way[1] && lp_s1_io_counter_filter_enq_bits_way[1])) begin cov_fail++; $display("[COV] LoadPipe.io_counter_filter_enq_bits_way[1] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_0_value[0] && lp_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_1_value[0] && lp_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_2_value[0] && lp_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_3_value[0] && lp_s1_io_perf_3_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_3_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_4_value[0] && lp_s1_io_perf_4_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_4_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_5_value[0] && lp_s1_io_perf_5_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_5_value[0] 未见过 0 和 1"); end
    if (!(lp_s0_io_perf_6_value[0] && lp_s1_io_perf_6_value[0])) begin cov_fail++; $display("[COV] LoadPipe.io_perf_6_value[0] 未见过 0 和 1"); end
    $display("[ARM] LoadPipe armed_at=%0d", lp_armed_at);
    if (lp_armed_at < 0) begin cov_fail++; $display("[ARM] LoadPipe 从未 arm"); end
    $display("[COV] LoadPipe.s1_hit = %0d", lp_cov_s1_hit);
    if (lp_cov_s1_hit < 200) begin cov_fail++; $display("[COV] LoadPipe.s1_hit < 200"); end
    $display("[COV] LoadPipe.s1_hit_noperm = %0d", lp_cov_s1_hit_noperm);
    if (lp_cov_s1_hit_noperm < 200) begin cov_fail++; $display("[COV] LoadPipe.s1_hit_noperm < 200"); end
    $display("[COV] LoadPipe.s2_real_miss = %0d", lp_cov_s2_real_miss);
    if (lp_cov_s2_real_miss < 200) begin cov_fail++; $display("[COV] LoadPipe.s2_real_miss < 200"); end
    $display("[COV] LoadPipe.miss_fire = %0d", lp_cov_miss_fire);
    if (lp_cov_miss_fire < 200) begin cov_fail++; $display("[COV] LoadPipe.miss_fire < 200"); end
    $display("[COV] LoadPipe.nack_no_mshr = %0d", lp_cov_nack_no_mshr);
    if (lp_cov_nack_no_mshr < 200) begin cov_fail++; $display("[COV] LoadPipe.nack_no_mshr < 200"); end
    $display("[COV] LoadPipe.nack_data = %0d", lp_cov_nack_data);
    if (lp_cov_nack_data < 200) begin cov_fail++; $display("[COV] LoadPipe.nack_data < 200"); end
    $display("[COV] LoadPipe.tag_error = %0d", lp_cov_tag_error);
    if (lp_cov_tag_error < 200) begin cov_fail++; $display("[COV] LoadPipe.tag_error < 200"); end
    $display("[COV] LoadPipe.btot = %0d", lp_cov_btot);
    if (lp_cov_btot < 200) begin cov_fail++; $display("[COV] LoadPipe.btot < 200"); end
    $display("[COV] LoadPipe.btot_occupy_fail = %0d", lp_cov_btot_occupy_fail);
    if (lp_cov_btot_occupy_fail < 200) begin cov_fail++; $display("[COV] LoadPipe.btot_occupy_fail < 200"); end
    $display("[COV] LoadPipe.handled = %0d", lp_cov_handled);
    if (lp_cov_handled < 200) begin cov_fail++; $display("[COV] LoadPipe.handled < 200"); end
    $display("[COV] LoadPipe.pseudo_tag = %0d", lp_cov_pseudo_tag);
    if (lp_cov_pseudo_tag < 200) begin cov_fail++; $display("[COV] LoadPipe.pseudo_tag < 200"); end
    $display("[COV] LoadPipe.error_valid = %0d", lp_cov_error_valid);
    if (lp_cov_error_valid < 200) begin cov_fail++; $display("[COV] LoadPipe.error_valid < 200"); end
    $display("[COV] LoadPipe.data_error_128 = %0d", lp_cov_data_error_128);
    if (lp_cov_data_error_128 < 200) begin cov_fail++; $display("[COV] LoadPipe.data_error_128 < 200"); end
    $display("[COV] LoadPipe.pf_counted = %0d", lp_cov_pf_counted);
    if (lp_cov_pf_counted < 200) begin cov_fail++; $display("[COV] LoadPipe.pf_counted < 200"); end
    $display("[COV] LoadPipe.pf_filtered = %0d", lp_cov_pf_filtered);
    if (lp_cov_pf_filtered < 200) begin cov_fail++; $display("[COV] LoadPipe.pf_filtered < 200"); end
    $display("[COV] LoadPipe.late_prefetch_hit = %0d", lp_cov_late_prefetch_hit);
    if (lp_cov_late_prefetch_hit < 200) begin cov_fail++; $display("[COV] LoadPipe.late_prefetch_hit < 200"); end
    $display("[COV] LoadPipe.pollution = %0d", lp_cov_pollution);
    if (lp_cov_pollution < 200) begin cov_fail++; $display("[COV] LoadPipe.pollution < 200"); end
    $display("[COV] LoadPipe.replace_access = %0d", lp_cov_replace_access);
    if (lp_cov_replace_access < 200) begin cov_fail++; $display("[COV] LoadPipe.replace_access < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
