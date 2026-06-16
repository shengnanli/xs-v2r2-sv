// 自动生成：scripts/gen_mainpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_probe_req_valid;
  logic [1:0] io_probe_req_bits_probe_param;
  logic io_probe_req_bits_probe_need_data;
  logic [49:0] io_probe_req_bits_vaddr;
  logic [47:0] io_probe_req_bits_addr;
  logic [5:0] io_probe_req_bits_id;
  logic io_miss_req_ready;
  logic io_refill_req_valid;
  logic io_refill_req_bits_miss;
  logic [3:0] io_refill_req_bits_miss_id;
  logic [3:0] io_refill_req_bits_occupy_way;
  logic io_refill_req_bits_miss_fail_cause_evict_btot;
  logic [3:0] io_refill_req_bits_source;
  logic [4:0] io_refill_req_bits_cmd;
  logic [49:0] io_refill_req_bits_vaddr;
  logic [47:0] io_refill_req_bits_addr;
  logic [2:0] io_refill_req_bits_word_idx;
  logic [127:0] io_refill_req_bits_amo_data;
  logic [15:0] io_refill_req_bits_amo_mask;
  logic [127:0] io_refill_req_bits_amo_cmp;
  logic [2:0] io_refill_req_bits_pf_source;
  logic io_refill_req_bits_access;
  logic [5:0] io_refill_req_bits_id;
  logic io_wbq_block_miss_req;
  logic io_store_req_valid;
  logic [49:0] io_store_req_bits_vaddr;
  logic [47:0] io_store_req_bits_addr;
  logic [511:0] io_store_req_bits_data;
  logic [63:0] io_store_req_bits_mask;
  logic [5:0] io_store_req_bits_id;
  logic io_atomic_req_valid;
  logic [4:0] io_atomic_req_bits_cmd;
  logic [49:0] io_atomic_req_bits_vaddr;
  logic [47:0] io_atomic_req_bits_addr;
  logic [2:0] io_atomic_req_bits_word_idx;
  logic [127:0] io_atomic_req_bits_amo_data;
  logic [15:0] io_atomic_req_bits_amo_mask;
  logic [127:0] io_atomic_req_bits_amo_cmp;
  logic io_refill_info_valid;
  logic [511:0] io_refill_info_bits_store_data;
  logic [63:0] io_refill_info_bits_store_mask;
  logic [1:0] io_refill_info_bits_miss_param;
  logic io_refill_info_bits_error;
  logic io_wb_ready;
  logic io_data_readline_ready;
  logic [63:0] io_data_resp_0_raw_data;
  logic [63:0] io_data_resp_1_raw_data;
  logic [63:0] io_data_resp_2_raw_data;
  logic [63:0] io_data_resp_3_raw_data;
  logic [63:0] io_data_resp_4_raw_data;
  logic [63:0] io_data_resp_5_raw_data;
  logic [63:0] io_data_resp_6_raw_data;
  logic [63:0] io_data_resp_7_raw_data;
  logic io_readline_error;
  logic io_readline_error_delayed;
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
  logic [1:0] io_replace_way_way;
  logic [3:0] io_btot_ways_for_set;
  logic io_replace_block;
  logic io_invalid_resv_set;
  logic io_pseudo_error_valid;
  logic io_pseudo_error_bits_0_valid;
  logic [63:0] io_pseudo_error_bits_0_mask;
  wire g_io_probe_req_ready;
  wire i_io_probe_req_ready;
  wire g_io_miss_req_valid;
  wire i_io_miss_req_valid;
  wire [3:0] g_io_miss_req_bits_source;
  wire [3:0] i_io_miss_req_bits_source;
  wire [4:0] g_io_miss_req_bits_cmd;
  wire [4:0] i_io_miss_req_bits_cmd;
  wire [47:0] g_io_miss_req_bits_addr;
  wire [47:0] i_io_miss_req_bits_addr;
  wire [49:0] g_io_miss_req_bits_vaddr;
  wire [49:0] i_io_miss_req_bits_vaddr;
  wire g_io_miss_req_bits_full_overwrite;
  wire i_io_miss_req_bits_full_overwrite;
  wire [2:0] g_io_miss_req_bits_word_idx;
  wire [2:0] i_io_miss_req_bits_word_idx;
  wire [127:0] g_io_miss_req_bits_amo_data;
  wire [127:0] i_io_miss_req_bits_amo_data;
  wire [15:0] g_io_miss_req_bits_amo_mask;
  wire [15:0] i_io_miss_req_bits_amo_mask;
  wire [127:0] g_io_miss_req_bits_amo_cmp;
  wire [127:0] i_io_miss_req_bits_amo_cmp;
  wire [1:0] g_io_miss_req_bits_req_coh_state;
  wire [1:0] i_io_miss_req_bits_req_coh_state;
  wire [5:0] g_io_miss_req_bits_id;
  wire [5:0] i_io_miss_req_bits_id;
  wire g_io_miss_req_bits_isBtoT;
  wire i_io_miss_req_bits_isBtoT;
  wire [3:0] g_io_miss_req_bits_occupy_way;
  wire [3:0] i_io_miss_req_bits_occupy_way;
  wire g_io_miss_req_bits_cancel;
  wire i_io_miss_req_bits_cancel;
  wire [511:0] g_io_miss_req_bits_store_data;
  wire [511:0] i_io_miss_req_bits_store_data;
  wire [63:0] g_io_miss_req_bits_store_mask;
  wire [63:0] i_io_miss_req_bits_store_mask;
  wire g_io_refill_req_ready;
  wire i_io_refill_req_ready;
  wire g_io_wbq_conflict_check_valid;
  wire i_io_wbq_conflict_check_valid;
  wire [47:0] g_io_wbq_conflict_check_bits;
  wire [47:0] i_io_wbq_conflict_check_bits;
  wire g_io_store_req_ready;
  wire i_io_store_req_ready;
  wire g_io_store_replay_resp_valid;
  wire i_io_store_replay_resp_valid;
  wire [5:0] g_io_store_replay_resp_bits_id;
  wire [5:0] i_io_store_replay_resp_bits_id;
  wire g_io_store_hit_resp_valid;
  wire i_io_store_hit_resp_valid;
  wire [5:0] g_io_store_hit_resp_bits_id;
  wire [5:0] i_io_store_hit_resp_bits_id;
  wire g_io_atomic_req_ready;
  wire i_io_atomic_req_ready;
  wire g_io_atomic_resp_valid;
  wire i_io_atomic_resp_valid;
  wire [3:0] g_io_atomic_resp_bits_source;
  wire [3:0] i_io_atomic_resp_bits_source;
  wire [127:0] g_io_atomic_resp_bits_data;
  wire [127:0] i_io_atomic_resp_bits_data;
  wire g_io_atomic_resp_bits_miss;
  wire i_io_atomic_resp_bits_miss;
  wire [3:0] g_io_atomic_resp_bits_miss_id;
  wire [3:0] i_io_atomic_resp_bits_miss_id;
  wire g_io_atomic_resp_bits_replay;
  wire i_io_atomic_resp_bits_replay;
  wire g_io_atomic_resp_bits_error;
  wire i_io_atomic_resp_bits_error;
  wire g_io_atomic_resp_bits_ack_miss_queue;
  wire i_io_atomic_resp_bits_ack_miss_queue;
  wire [5:0] g_io_atomic_resp_bits_id;
  wire [5:0] i_io_atomic_resp_bits_id;
  wire g_io_mainpipe_info_s2_valid;
  wire i_io_mainpipe_info_s2_valid;
  wire [3:0] g_io_mainpipe_info_s2_miss_id;
  wire [3:0] i_io_mainpipe_info_s2_miss_id;
  wire g_io_mainpipe_info_s2_replay_to_mq;
  wire i_io_mainpipe_info_s2_replay_to_mq;
  wire g_io_mainpipe_info_s2_evict_BtoT_way;
  wire i_io_mainpipe_info_s2_evict_BtoT_way;
  wire [3:0] g_io_mainpipe_info_s2_next_evict_way;
  wire [3:0] i_io_mainpipe_info_s2_next_evict_way;
  wire g_io_mainpipe_info_s3_valid;
  wire i_io_mainpipe_info_s3_valid;
  wire [3:0] g_io_mainpipe_info_s3_miss_id;
  wire [3:0] i_io_mainpipe_info_s3_miss_id;
  wire g_io_mainpipe_info_s3_refill_resp;
  wire i_io_mainpipe_info_s3_refill_resp;
  wire g_io_wb_valid;
  wire i_io_wb_valid;
  wire [2:0] g_io_wb_bits_param;
  wire [2:0] i_io_wb_bits_param;
  wire g_io_wb_bits_voluntary;
  wire i_io_wb_bits_voluntary;
  wire g_io_wb_bits_hasData;
  wire i_io_wb_bits_hasData;
  wire g_io_wb_bits_corrupt;
  wire i_io_wb_bits_corrupt;
  wire g_io_wb_bits_dirty;
  wire i_io_wb_bits_dirty;
  wire [47:0] g_io_wb_bits_addr;
  wire [47:0] i_io_wb_bits_addr;
  wire [511:0] g_io_wb_bits_data;
  wire [511:0] i_io_wb_bits_data;
  wire g_io_data_read_intend;
  wire i_io_data_read_intend;
  wire g_io_data_readline_valid;
  wire i_io_data_readline_valid;
  wire [3:0] g_io_data_readline_bits_way_en;
  wire [3:0] i_io_data_readline_bits_way_en;
  wire [47:0] g_io_data_readline_bits_addr;
  wire [47:0] i_io_data_readline_bits_addr;
  wire [7:0] g_io_data_readline_bits_rmask;
  wire [7:0] i_io_data_readline_bits_rmask;
  wire g_io_data_readline_can_go;
  wire i_io_data_readline_can_go;
  wire g_io_data_readline_stall;
  wire i_io_data_readline_stall;
  wire g_io_data_readline_can_resp;
  wire i_io_data_readline_can_resp;
  wire g_io_data_write_valid;
  wire i_io_data_write_valid;
  wire [7:0] g_io_data_write_bits_wmask;
  wire [7:0] i_io_data_write_bits_wmask;
  wire [63:0] g_io_data_write_bits_data_0;
  wire [63:0] i_io_data_write_bits_data_0;
  wire [63:0] g_io_data_write_bits_data_1;
  wire [63:0] i_io_data_write_bits_data_1;
  wire [63:0] g_io_data_write_bits_data_2;
  wire [63:0] i_io_data_write_bits_data_2;
  wire [63:0] g_io_data_write_bits_data_3;
  wire [63:0] i_io_data_write_bits_data_3;
  wire [63:0] g_io_data_write_bits_data_4;
  wire [63:0] i_io_data_write_bits_data_4;
  wire [63:0] g_io_data_write_bits_data_5;
  wire [63:0] i_io_data_write_bits_data_5;
  wire [63:0] g_io_data_write_bits_data_6;
  wire [63:0] i_io_data_write_bits_data_6;
  wire [63:0] g_io_data_write_bits_data_7;
  wire [63:0] i_io_data_write_bits_data_7;
  wire g_io_data_write_dup_0_valid;
  wire i_io_data_write_dup_0_valid;
  wire [3:0] g_io_data_write_dup_0_bits_way_en;
  wire [3:0] i_io_data_write_dup_0_bits_way_en;
  wire [47:0] g_io_data_write_dup_0_bits_addr;
  wire [47:0] i_io_data_write_dup_0_bits_addr;
  wire g_io_data_write_dup_1_valid;
  wire i_io_data_write_dup_1_valid;
  wire [3:0] g_io_data_write_dup_1_bits_way_en;
  wire [3:0] i_io_data_write_dup_1_bits_way_en;
  wire [47:0] g_io_data_write_dup_1_bits_addr;
  wire [47:0] i_io_data_write_dup_1_bits_addr;
  wire g_io_data_write_dup_2_valid;
  wire i_io_data_write_dup_2_valid;
  wire [3:0] g_io_data_write_dup_2_bits_way_en;
  wire [3:0] i_io_data_write_dup_2_bits_way_en;
  wire [47:0] g_io_data_write_dup_2_bits_addr;
  wire [47:0] i_io_data_write_dup_2_bits_addr;
  wire g_io_data_write_dup_3_valid;
  wire i_io_data_write_dup_3_valid;
  wire [3:0] g_io_data_write_dup_3_bits_way_en;
  wire [3:0] i_io_data_write_dup_3_bits_way_en;
  wire [47:0] g_io_data_write_dup_3_bits_addr;
  wire [47:0] i_io_data_write_dup_3_bits_addr;
  wire g_io_data_write_dup_4_valid;
  wire i_io_data_write_dup_4_valid;
  wire [3:0] g_io_data_write_dup_4_bits_way_en;
  wire [3:0] i_io_data_write_dup_4_bits_way_en;
  wire [47:0] g_io_data_write_dup_4_bits_addr;
  wire [47:0] i_io_data_write_dup_4_bits_addr;
  wire g_io_data_write_dup_5_valid;
  wire i_io_data_write_dup_5_valid;
  wire [3:0] g_io_data_write_dup_5_bits_way_en;
  wire [3:0] i_io_data_write_dup_5_bits_way_en;
  wire [47:0] g_io_data_write_dup_5_bits_addr;
  wire [47:0] i_io_data_write_dup_5_bits_addr;
  wire g_io_data_write_dup_6_valid;
  wire i_io_data_write_dup_6_valid;
  wire [3:0] g_io_data_write_dup_6_bits_way_en;
  wire [3:0] i_io_data_write_dup_6_bits_way_en;
  wire [47:0] g_io_data_write_dup_6_bits_addr;
  wire [47:0] i_io_data_write_dup_6_bits_addr;
  wire g_io_data_write_dup_7_valid;
  wire i_io_data_write_dup_7_valid;
  wire [3:0] g_io_data_write_dup_7_bits_way_en;
  wire [3:0] i_io_data_write_dup_7_bits_way_en;
  wire [47:0] g_io_data_write_dup_7_bits_addr;
  wire [47:0] i_io_data_write_dup_7_bits_addr;
  wire g_io_meta_read_valid;
  wire i_io_meta_read_valid;
  wire [7:0] g_io_meta_read_bits_idx;
  wire [7:0] i_io_meta_read_bits_idx;
  wire g_io_meta_write_valid;
  wire i_io_meta_write_valid;
  wire [7:0] g_io_meta_write_bits_idx;
  wire [7:0] i_io_meta_write_bits_idx;
  wire [3:0] g_io_meta_write_bits_way_en;
  wire [3:0] i_io_meta_write_bits_way_en;
  wire [1:0] g_io_meta_write_bits_meta_coh_state;
  wire [1:0] i_io_meta_write_bits_meta_coh_state;
  wire g_io_error_flag_write_valid;
  wire i_io_error_flag_write_valid;
  wire [7:0] g_io_error_flag_write_bits_idx;
  wire [7:0] i_io_error_flag_write_bits_idx;
  wire [3:0] g_io_error_flag_write_bits_way_en;
  wire [3:0] i_io_error_flag_write_bits_way_en;
  wire g_io_error_flag_write_bits_flag;
  wire i_io_error_flag_write_bits_flag;
  wire g_io_prefetch_flag_write_valid;
  wire i_io_prefetch_flag_write_valid;
  wire [7:0] g_io_prefetch_flag_write_bits_idx;
  wire [7:0] i_io_prefetch_flag_write_bits_idx;
  wire [3:0] g_io_prefetch_flag_write_bits_way_en;
  wire [3:0] i_io_prefetch_flag_write_bits_way_en;
  wire [2:0] g_io_prefetch_flag_write_bits_source;
  wire [2:0] i_io_prefetch_flag_write_bits_source;
  wire g_io_access_flag_write_valid;
  wire i_io_access_flag_write_valid;
  wire [7:0] g_io_access_flag_write_bits_idx;
  wire [7:0] i_io_access_flag_write_bits_idx;
  wire [3:0] g_io_access_flag_write_bits_way_en;
  wire [3:0] i_io_access_flag_write_bits_way_en;
  wire g_io_access_flag_write_bits_flag;
  wire i_io_access_flag_write_bits_flag;
  wire g_io_tag_read_valid;
  wire i_io_tag_read_valid;
  wire [7:0] g_io_tag_read_bits_idx;
  wire [7:0] i_io_tag_read_bits_idx;
  wire g_io_tag_write_valid;
  wire i_io_tag_write_valid;
  wire [7:0] g_io_tag_write_bits_idx;
  wire [7:0] i_io_tag_write_bits_idx;
  wire [3:0] g_io_tag_write_bits_way_en;
  wire [3:0] i_io_tag_write_bits_way_en;
  wire [35:0] g_io_tag_write_bits_tag;
  wire [35:0] i_io_tag_write_bits_tag;
  wire g_io_tag_write_intend;
  wire i_io_tag_write_intend;
  wire g_io_replace_access_valid;
  wire i_io_replace_access_valid;
  wire [7:0] g_io_replace_access_bits_set;
  wire [7:0] i_io_replace_access_bits_set;
  wire [1:0] g_io_replace_access_bits_way;
  wire [1:0] i_io_replace_access_bits_way;
  wire [7:0] g_io_replace_way_set_bits;
  wire [7:0] i_io_replace_way_set_bits;
  wire [7:0] g_io_evict_set;
  wire [7:0] i_io_evict_set;
  wire [47:0] g_io_replace_req_bits_addr;
  wire [47:0] i_io_replace_req_bits_addr;
  wire [49:0] g_io_replace_req_bits_vaddr;
  wire [49:0] i_io_replace_req_bits_vaddr;
  wire g_io_sms_agt_evict_req_valid;
  wire i_io_sms_agt_evict_req_valid;
  wire [49:0] g_io_sms_agt_evict_req_bits_vaddr;
  wire [49:0] i_io_sms_agt_evict_req_bits_vaddr;
  wire g_io_status_dup_0_s1_valid;
  wire i_io_status_dup_0_s1_valid;
  wire [7:0] g_io_status_dup_0_s1_bits_set;
  wire [7:0] i_io_status_dup_0_s1_bits_set;
  wire [3:0] g_io_status_dup_0_s1_bits_way_en;
  wire [3:0] i_io_status_dup_0_s1_bits_way_en;
  wire g_io_status_dup_0_s2_valid;
  wire i_io_status_dup_0_s2_valid;
  wire [7:0] g_io_status_dup_0_s2_bits_set;
  wire [7:0] i_io_status_dup_0_s2_bits_set;
  wire [3:0] g_io_status_dup_0_s2_bits_way_en;
  wire [3:0] i_io_status_dup_0_s2_bits_way_en;
  wire g_io_status_dup_0_s3_valid;
  wire i_io_status_dup_0_s3_valid;
  wire [7:0] g_io_status_dup_0_s3_bits_set;
  wire [7:0] i_io_status_dup_0_s3_bits_set;
  wire [3:0] g_io_status_dup_0_s3_bits_way_en;
  wire [3:0] i_io_status_dup_0_s3_bits_way_en;
  wire g_io_status_dup_1_s1_valid;
  wire i_io_status_dup_1_s1_valid;
  wire [7:0] g_io_status_dup_1_s1_bits_set;
  wire [7:0] i_io_status_dup_1_s1_bits_set;
  wire [3:0] g_io_status_dup_1_s1_bits_way_en;
  wire [3:0] i_io_status_dup_1_s1_bits_way_en;
  wire g_io_status_dup_1_s2_valid;
  wire i_io_status_dup_1_s2_valid;
  wire [7:0] g_io_status_dup_1_s2_bits_set;
  wire [7:0] i_io_status_dup_1_s2_bits_set;
  wire [3:0] g_io_status_dup_1_s2_bits_way_en;
  wire [3:0] i_io_status_dup_1_s2_bits_way_en;
  wire g_io_status_dup_1_s3_valid;
  wire i_io_status_dup_1_s3_valid;
  wire [7:0] g_io_status_dup_1_s3_bits_set;
  wire [7:0] i_io_status_dup_1_s3_bits_set;
  wire [3:0] g_io_status_dup_1_s3_bits_way_en;
  wire [3:0] i_io_status_dup_1_s3_bits_way_en;
  wire g_io_status_dup_2_s1_valid;
  wire i_io_status_dup_2_s1_valid;
  wire [7:0] g_io_status_dup_2_s1_bits_set;
  wire [7:0] i_io_status_dup_2_s1_bits_set;
  wire [3:0] g_io_status_dup_2_s1_bits_way_en;
  wire [3:0] i_io_status_dup_2_s1_bits_way_en;
  wire g_io_status_dup_2_s2_valid;
  wire i_io_status_dup_2_s2_valid;
  wire [7:0] g_io_status_dup_2_s2_bits_set;
  wire [7:0] i_io_status_dup_2_s2_bits_set;
  wire [3:0] g_io_status_dup_2_s2_bits_way_en;
  wire [3:0] i_io_status_dup_2_s2_bits_way_en;
  wire g_io_status_dup_2_s3_valid;
  wire i_io_status_dup_2_s3_valid;
  wire [7:0] g_io_status_dup_2_s3_bits_set;
  wire [7:0] i_io_status_dup_2_s3_bits_set;
  wire [3:0] g_io_status_dup_2_s3_bits_way_en;
  wire [3:0] i_io_status_dup_2_s3_bits_way_en;
  wire g_io_status_dup_3_s1_valid;
  wire i_io_status_dup_3_s1_valid;
  wire [7:0] g_io_status_dup_3_s1_bits_set;
  wire [7:0] i_io_status_dup_3_s1_bits_set;
  wire [3:0] g_io_status_dup_3_s1_bits_way_en;
  wire [3:0] i_io_status_dup_3_s1_bits_way_en;
  wire g_io_status_dup_3_s2_valid;
  wire i_io_status_dup_3_s2_valid;
  wire [7:0] g_io_status_dup_3_s2_bits_set;
  wire [7:0] i_io_status_dup_3_s2_bits_set;
  wire [3:0] g_io_status_dup_3_s2_bits_way_en;
  wire [3:0] i_io_status_dup_3_s2_bits_way_en;
  wire g_io_status_dup_3_s3_valid;
  wire i_io_status_dup_3_s3_valid;
  wire [7:0] g_io_status_dup_3_s3_bits_set;
  wire [7:0] i_io_status_dup_3_s3_bits_set;
  wire [3:0] g_io_status_dup_3_s3_bits_way_en;
  wire [3:0] i_io_status_dup_3_s3_bits_way_en;
  wire g_io_status_dup_4_s1_valid;
  wire i_io_status_dup_4_s1_valid;
  wire [7:0] g_io_status_dup_4_s1_bits_set;
  wire [7:0] i_io_status_dup_4_s1_bits_set;
  wire [3:0] g_io_status_dup_4_s1_bits_way_en;
  wire [3:0] i_io_status_dup_4_s1_bits_way_en;
  wire g_io_status_dup_4_s2_valid;
  wire i_io_status_dup_4_s2_valid;
  wire [7:0] g_io_status_dup_4_s2_bits_set;
  wire [7:0] i_io_status_dup_4_s2_bits_set;
  wire [3:0] g_io_status_dup_4_s2_bits_way_en;
  wire [3:0] i_io_status_dup_4_s2_bits_way_en;
  wire g_io_status_dup_4_s3_valid;
  wire i_io_status_dup_4_s3_valid;
  wire [7:0] g_io_status_dup_4_s3_bits_set;
  wire [7:0] i_io_status_dup_4_s3_bits_set;
  wire [3:0] g_io_status_dup_4_s3_bits_way_en;
  wire [3:0] i_io_status_dup_4_s3_bits_way_en;
  wire g_io_status_dup_5_s1_valid;
  wire i_io_status_dup_5_s1_valid;
  wire [7:0] g_io_status_dup_5_s1_bits_set;
  wire [7:0] i_io_status_dup_5_s1_bits_set;
  wire [3:0] g_io_status_dup_5_s1_bits_way_en;
  wire [3:0] i_io_status_dup_5_s1_bits_way_en;
  wire g_io_status_dup_5_s2_valid;
  wire i_io_status_dup_5_s2_valid;
  wire [7:0] g_io_status_dup_5_s2_bits_set;
  wire [7:0] i_io_status_dup_5_s2_bits_set;
  wire [3:0] g_io_status_dup_5_s2_bits_way_en;
  wire [3:0] i_io_status_dup_5_s2_bits_way_en;
  wire g_io_status_dup_5_s3_valid;
  wire i_io_status_dup_5_s3_valid;
  wire [7:0] g_io_status_dup_5_s3_bits_set;
  wire [7:0] i_io_status_dup_5_s3_bits_set;
  wire [3:0] g_io_status_dup_5_s3_bits_way_en;
  wire [3:0] i_io_status_dup_5_s3_bits_way_en;
  wire g_io_status_dup_6_s1_valid;
  wire i_io_status_dup_6_s1_valid;
  wire [7:0] g_io_status_dup_6_s1_bits_set;
  wire [7:0] i_io_status_dup_6_s1_bits_set;
  wire [3:0] g_io_status_dup_6_s1_bits_way_en;
  wire [3:0] i_io_status_dup_6_s1_bits_way_en;
  wire g_io_status_dup_6_s2_valid;
  wire i_io_status_dup_6_s2_valid;
  wire [7:0] g_io_status_dup_6_s2_bits_set;
  wire [7:0] i_io_status_dup_6_s2_bits_set;
  wire [3:0] g_io_status_dup_6_s2_bits_way_en;
  wire [3:0] i_io_status_dup_6_s2_bits_way_en;
  wire g_io_status_dup_6_s3_valid;
  wire i_io_status_dup_6_s3_valid;
  wire [7:0] g_io_status_dup_6_s3_bits_set;
  wire [7:0] i_io_status_dup_6_s3_bits_set;
  wire [3:0] g_io_status_dup_6_s3_bits_way_en;
  wire [3:0] i_io_status_dup_6_s3_bits_way_en;
  wire g_io_status_dup_7_s1_valid;
  wire i_io_status_dup_7_s1_valid;
  wire [7:0] g_io_status_dup_7_s1_bits_set;
  wire [7:0] i_io_status_dup_7_s1_bits_set;
  wire [3:0] g_io_status_dup_7_s1_bits_way_en;
  wire [3:0] i_io_status_dup_7_s1_bits_way_en;
  wire g_io_status_dup_7_s2_valid;
  wire i_io_status_dup_7_s2_valid;
  wire [7:0] g_io_status_dup_7_s2_bits_set;
  wire [7:0] i_io_status_dup_7_s2_bits_set;
  wire [3:0] g_io_status_dup_7_s2_bits_way_en;
  wire [3:0] i_io_status_dup_7_s2_bits_way_en;
  wire g_io_status_dup_7_s3_valid;
  wire i_io_status_dup_7_s3_valid;
  wire [7:0] g_io_status_dup_7_s3_bits_set;
  wire [7:0] i_io_status_dup_7_s3_bits_set;
  wire [3:0] g_io_status_dup_7_s3_bits_way_en;
  wire [3:0] i_io_status_dup_7_s3_bits_way_en;
  wire g_io_status_dup_8_s1_valid;
  wire i_io_status_dup_8_s1_valid;
  wire [7:0] g_io_status_dup_8_s1_bits_set;
  wire [7:0] i_io_status_dup_8_s1_bits_set;
  wire [3:0] g_io_status_dup_8_s1_bits_way_en;
  wire [3:0] i_io_status_dup_8_s1_bits_way_en;
  wire g_io_status_dup_8_s2_valid;
  wire i_io_status_dup_8_s2_valid;
  wire [7:0] g_io_status_dup_8_s2_bits_set;
  wire [7:0] i_io_status_dup_8_s2_bits_set;
  wire [3:0] g_io_status_dup_8_s2_bits_way_en;
  wire [3:0] i_io_status_dup_8_s2_bits_way_en;
  wire g_io_status_dup_8_s3_valid;
  wire i_io_status_dup_8_s3_valid;
  wire [7:0] g_io_status_dup_8_s3_bits_set;
  wire [7:0] i_io_status_dup_8_s3_bits_set;
  wire [3:0] g_io_status_dup_8_s3_bits_way_en;
  wire [3:0] i_io_status_dup_8_s3_bits_way_en;
  wire g_io_status_dup_9_s1_valid;
  wire i_io_status_dup_9_s1_valid;
  wire [7:0] g_io_status_dup_9_s1_bits_set;
  wire [7:0] i_io_status_dup_9_s1_bits_set;
  wire [3:0] g_io_status_dup_9_s1_bits_way_en;
  wire [3:0] i_io_status_dup_9_s1_bits_way_en;
  wire g_io_status_dup_9_s2_valid;
  wire i_io_status_dup_9_s2_valid;
  wire [7:0] g_io_status_dup_9_s2_bits_set;
  wire [7:0] i_io_status_dup_9_s2_bits_set;
  wire [3:0] g_io_status_dup_9_s2_bits_way_en;
  wire [3:0] i_io_status_dup_9_s2_bits_way_en;
  wire g_io_status_dup_9_s3_valid;
  wire i_io_status_dup_9_s3_valid;
  wire [7:0] g_io_status_dup_9_s3_bits_set;
  wire [7:0] i_io_status_dup_9_s3_bits_set;
  wire [3:0] g_io_status_dup_9_s3_bits_way_en;
  wire [3:0] i_io_status_dup_9_s3_bits_way_en;
  wire g_io_status_dup_10_s1_valid;
  wire i_io_status_dup_10_s1_valid;
  wire [7:0] g_io_status_dup_10_s1_bits_set;
  wire [7:0] i_io_status_dup_10_s1_bits_set;
  wire [3:0] g_io_status_dup_10_s1_bits_way_en;
  wire [3:0] i_io_status_dup_10_s1_bits_way_en;
  wire g_io_status_dup_10_s2_valid;
  wire i_io_status_dup_10_s2_valid;
  wire [7:0] g_io_status_dup_10_s2_bits_set;
  wire [7:0] i_io_status_dup_10_s2_bits_set;
  wire [3:0] g_io_status_dup_10_s2_bits_way_en;
  wire [3:0] i_io_status_dup_10_s2_bits_way_en;
  wire g_io_status_dup_10_s3_valid;
  wire i_io_status_dup_10_s3_valid;
  wire [7:0] g_io_status_dup_10_s3_bits_set;
  wire [7:0] i_io_status_dup_10_s3_bits_set;
  wire [3:0] g_io_status_dup_10_s3_bits_way_en;
  wire [3:0] i_io_status_dup_10_s3_bits_way_en;
  wire g_io_status_dup_11_s1_valid;
  wire i_io_status_dup_11_s1_valid;
  wire [7:0] g_io_status_dup_11_s1_bits_set;
  wire [7:0] i_io_status_dup_11_s1_bits_set;
  wire [3:0] g_io_status_dup_11_s1_bits_way_en;
  wire [3:0] i_io_status_dup_11_s1_bits_way_en;
  wire g_io_status_dup_11_s2_valid;
  wire i_io_status_dup_11_s2_valid;
  wire [7:0] g_io_status_dup_11_s2_bits_set;
  wire [7:0] i_io_status_dup_11_s2_bits_set;
  wire [3:0] g_io_status_dup_11_s2_bits_way_en;
  wire [3:0] i_io_status_dup_11_s2_bits_way_en;
  wire g_io_status_dup_11_s3_valid;
  wire i_io_status_dup_11_s3_valid;
  wire [7:0] g_io_status_dup_11_s3_bits_set;
  wire [7:0] i_io_status_dup_11_s3_bits_set;
  wire [3:0] g_io_status_dup_11_s3_bits_way_en;
  wire [3:0] i_io_status_dup_11_s3_bits_way_en;
  wire g_io_status_dup_12_s1_valid;
  wire i_io_status_dup_12_s1_valid;
  wire [7:0] g_io_status_dup_12_s1_bits_set;
  wire [7:0] i_io_status_dup_12_s1_bits_set;
  wire [3:0] g_io_status_dup_12_s1_bits_way_en;
  wire [3:0] i_io_status_dup_12_s1_bits_way_en;
  wire g_io_status_dup_12_s2_valid;
  wire i_io_status_dup_12_s2_valid;
  wire [7:0] g_io_status_dup_12_s2_bits_set;
  wire [7:0] i_io_status_dup_12_s2_bits_set;
  wire [3:0] g_io_status_dup_12_s2_bits_way_en;
  wire [3:0] i_io_status_dup_12_s2_bits_way_en;
  wire g_io_status_dup_12_s3_valid;
  wire i_io_status_dup_12_s3_valid;
  wire [7:0] g_io_status_dup_12_s3_bits_set;
  wire [7:0] i_io_status_dup_12_s3_bits_set;
  wire [3:0] g_io_status_dup_12_s3_bits_way_en;
  wire [3:0] i_io_status_dup_12_s3_bits_way_en;
  wire g_io_status_dup_13_s1_valid;
  wire i_io_status_dup_13_s1_valid;
  wire [7:0] g_io_status_dup_13_s1_bits_set;
  wire [7:0] i_io_status_dup_13_s1_bits_set;
  wire [3:0] g_io_status_dup_13_s1_bits_way_en;
  wire [3:0] i_io_status_dup_13_s1_bits_way_en;
  wire g_io_status_dup_13_s2_valid;
  wire i_io_status_dup_13_s2_valid;
  wire [7:0] g_io_status_dup_13_s2_bits_set;
  wire [7:0] i_io_status_dup_13_s2_bits_set;
  wire [3:0] g_io_status_dup_13_s2_bits_way_en;
  wire [3:0] i_io_status_dup_13_s2_bits_way_en;
  wire g_io_status_dup_13_s3_valid;
  wire i_io_status_dup_13_s3_valid;
  wire [7:0] g_io_status_dup_13_s3_bits_set;
  wire [7:0] i_io_status_dup_13_s3_bits_set;
  wire [3:0] g_io_status_dup_13_s3_bits_way_en;
  wire [3:0] i_io_status_dup_13_s3_bits_way_en;
  wire g_io_status_dup_14_s1_valid;
  wire i_io_status_dup_14_s1_valid;
  wire [7:0] g_io_status_dup_14_s1_bits_set;
  wire [7:0] i_io_status_dup_14_s1_bits_set;
  wire [3:0] g_io_status_dup_14_s1_bits_way_en;
  wire [3:0] i_io_status_dup_14_s1_bits_way_en;
  wire g_io_status_dup_14_s2_valid;
  wire i_io_status_dup_14_s2_valid;
  wire [7:0] g_io_status_dup_14_s2_bits_set;
  wire [7:0] i_io_status_dup_14_s2_bits_set;
  wire [3:0] g_io_status_dup_14_s2_bits_way_en;
  wire [3:0] i_io_status_dup_14_s2_bits_way_en;
  wire g_io_status_dup_14_s3_valid;
  wire i_io_status_dup_14_s3_valid;
  wire [7:0] g_io_status_dup_14_s3_bits_set;
  wire [7:0] i_io_status_dup_14_s3_bits_set;
  wire [3:0] g_io_status_dup_14_s3_bits_way_en;
  wire [3:0] i_io_status_dup_14_s3_bits_way_en;
  wire g_io_status_dup_15_s1_valid;
  wire i_io_status_dup_15_s1_valid;
  wire [7:0] g_io_status_dup_15_s1_bits_set;
  wire [7:0] i_io_status_dup_15_s1_bits_set;
  wire [3:0] g_io_status_dup_15_s1_bits_way_en;
  wire [3:0] i_io_status_dup_15_s1_bits_way_en;
  wire g_io_status_dup_15_s2_valid;
  wire i_io_status_dup_15_s2_valid;
  wire [7:0] g_io_status_dup_15_s2_bits_set;
  wire [7:0] i_io_status_dup_15_s2_bits_set;
  wire [3:0] g_io_status_dup_15_s2_bits_way_en;
  wire [3:0] i_io_status_dup_15_s2_bits_way_en;
  wire g_io_status_dup_15_s3_valid;
  wire i_io_status_dup_15_s3_valid;
  wire [7:0] g_io_status_dup_15_s3_bits_set;
  wire [7:0] i_io_status_dup_15_s3_bits_set;
  wire [3:0] g_io_status_dup_15_s3_bits_way_en;
  wire [3:0] i_io_status_dup_15_s3_bits_way_en;
  wire g_io_status_dup_16_s1_valid;
  wire i_io_status_dup_16_s1_valid;
  wire [7:0] g_io_status_dup_16_s1_bits_set;
  wire [7:0] i_io_status_dup_16_s1_bits_set;
  wire [3:0] g_io_status_dup_16_s1_bits_way_en;
  wire [3:0] i_io_status_dup_16_s1_bits_way_en;
  wire g_io_status_dup_16_s2_valid;
  wire i_io_status_dup_16_s2_valid;
  wire [7:0] g_io_status_dup_16_s2_bits_set;
  wire [7:0] i_io_status_dup_16_s2_bits_set;
  wire [3:0] g_io_status_dup_16_s2_bits_way_en;
  wire [3:0] i_io_status_dup_16_s2_bits_way_en;
  wire g_io_status_dup_16_s3_valid;
  wire i_io_status_dup_16_s3_valid;
  wire [7:0] g_io_status_dup_16_s3_bits_set;
  wire [7:0] i_io_status_dup_16_s3_bits_set;
  wire [3:0] g_io_status_dup_16_s3_bits_way_en;
  wire [3:0] i_io_status_dup_16_s3_bits_way_en;
  wire g_io_status_dup_17_s1_valid;
  wire i_io_status_dup_17_s1_valid;
  wire [7:0] g_io_status_dup_17_s1_bits_set;
  wire [7:0] i_io_status_dup_17_s1_bits_set;
  wire [3:0] g_io_status_dup_17_s1_bits_way_en;
  wire [3:0] i_io_status_dup_17_s1_bits_way_en;
  wire g_io_status_dup_17_s2_valid;
  wire i_io_status_dup_17_s2_valid;
  wire [7:0] g_io_status_dup_17_s2_bits_set;
  wire [7:0] i_io_status_dup_17_s2_bits_set;
  wire [3:0] g_io_status_dup_17_s2_bits_way_en;
  wire [3:0] i_io_status_dup_17_s2_bits_way_en;
  wire g_io_status_dup_17_s3_valid;
  wire i_io_status_dup_17_s3_valid;
  wire [7:0] g_io_status_dup_17_s3_bits_set;
  wire [7:0] i_io_status_dup_17_s3_bits_set;
  wire [3:0] g_io_status_dup_17_s3_bits_way_en;
  wire [3:0] i_io_status_dup_17_s3_bits_way_en;
  wire g_io_status_dup_18_s1_valid;
  wire i_io_status_dup_18_s1_valid;
  wire [7:0] g_io_status_dup_18_s1_bits_set;
  wire [7:0] i_io_status_dup_18_s1_bits_set;
  wire [3:0] g_io_status_dup_18_s1_bits_way_en;
  wire [3:0] i_io_status_dup_18_s1_bits_way_en;
  wire g_io_status_dup_18_s2_valid;
  wire i_io_status_dup_18_s2_valid;
  wire [7:0] g_io_status_dup_18_s2_bits_set;
  wire [7:0] i_io_status_dup_18_s2_bits_set;
  wire [3:0] g_io_status_dup_18_s2_bits_way_en;
  wire [3:0] i_io_status_dup_18_s2_bits_way_en;
  wire g_io_status_dup_18_s3_valid;
  wire i_io_status_dup_18_s3_valid;
  wire [7:0] g_io_status_dup_18_s3_bits_set;
  wire [7:0] i_io_status_dup_18_s3_bits_set;
  wire [3:0] g_io_status_dup_18_s3_bits_way_en;
  wire [3:0] i_io_status_dup_18_s3_bits_way_en;
  wire g_io_status_dup_19_s1_valid;
  wire i_io_status_dup_19_s1_valid;
  wire [7:0] g_io_status_dup_19_s1_bits_set;
  wire [7:0] i_io_status_dup_19_s1_bits_set;
  wire [3:0] g_io_status_dup_19_s1_bits_way_en;
  wire [3:0] i_io_status_dup_19_s1_bits_way_en;
  wire g_io_status_dup_19_s2_valid;
  wire i_io_status_dup_19_s2_valid;
  wire [7:0] g_io_status_dup_19_s2_bits_set;
  wire [7:0] i_io_status_dup_19_s2_bits_set;
  wire [3:0] g_io_status_dup_19_s2_bits_way_en;
  wire [3:0] i_io_status_dup_19_s2_bits_way_en;
  wire g_io_status_dup_19_s3_valid;
  wire i_io_status_dup_19_s3_valid;
  wire [7:0] g_io_status_dup_19_s3_bits_set;
  wire [7:0] i_io_status_dup_19_s3_bits_set;
  wire [3:0] g_io_status_dup_19_s3_bits_way_en;
  wire [3:0] i_io_status_dup_19_s3_bits_way_en;
  wire g_io_status_dup_20_s1_valid;
  wire i_io_status_dup_20_s1_valid;
  wire [7:0] g_io_status_dup_20_s1_bits_set;
  wire [7:0] i_io_status_dup_20_s1_bits_set;
  wire [3:0] g_io_status_dup_20_s1_bits_way_en;
  wire [3:0] i_io_status_dup_20_s1_bits_way_en;
  wire g_io_status_dup_20_s2_valid;
  wire i_io_status_dup_20_s2_valid;
  wire [7:0] g_io_status_dup_20_s2_bits_set;
  wire [7:0] i_io_status_dup_20_s2_bits_set;
  wire [3:0] g_io_status_dup_20_s2_bits_way_en;
  wire [3:0] i_io_status_dup_20_s2_bits_way_en;
  wire g_io_status_dup_20_s3_valid;
  wire i_io_status_dup_20_s3_valid;
  wire [7:0] g_io_status_dup_20_s3_bits_set;
  wire [7:0] i_io_status_dup_20_s3_bits_set;
  wire [3:0] g_io_status_dup_20_s3_bits_way_en;
  wire [3:0] i_io_status_dup_20_s3_bits_way_en;
  wire g_io_status_dup_21_s1_valid;
  wire i_io_status_dup_21_s1_valid;
  wire [7:0] g_io_status_dup_21_s1_bits_set;
  wire [7:0] i_io_status_dup_21_s1_bits_set;
  wire [3:0] g_io_status_dup_21_s1_bits_way_en;
  wire [3:0] i_io_status_dup_21_s1_bits_way_en;
  wire g_io_status_dup_21_s2_valid;
  wire i_io_status_dup_21_s2_valid;
  wire [7:0] g_io_status_dup_21_s2_bits_set;
  wire [7:0] i_io_status_dup_21_s2_bits_set;
  wire [3:0] g_io_status_dup_21_s2_bits_way_en;
  wire [3:0] i_io_status_dup_21_s2_bits_way_en;
  wire g_io_status_dup_21_s3_valid;
  wire i_io_status_dup_21_s3_valid;
  wire [7:0] g_io_status_dup_21_s3_bits_set;
  wire [7:0] i_io_status_dup_21_s3_bits_set;
  wire [3:0] g_io_status_dup_21_s3_bits_way_en;
  wire [3:0] i_io_status_dup_21_s3_bits_way_en;
  wire g_io_status_dup_22_s1_valid;
  wire i_io_status_dup_22_s1_valid;
  wire [7:0] g_io_status_dup_22_s1_bits_set;
  wire [7:0] i_io_status_dup_22_s1_bits_set;
  wire [3:0] g_io_status_dup_22_s1_bits_way_en;
  wire [3:0] i_io_status_dup_22_s1_bits_way_en;
  wire g_io_status_dup_22_s2_valid;
  wire i_io_status_dup_22_s2_valid;
  wire [7:0] g_io_status_dup_22_s2_bits_set;
  wire [7:0] i_io_status_dup_22_s2_bits_set;
  wire [3:0] g_io_status_dup_22_s2_bits_way_en;
  wire [3:0] i_io_status_dup_22_s2_bits_way_en;
  wire g_io_status_dup_22_s3_valid;
  wire i_io_status_dup_22_s3_valid;
  wire [7:0] g_io_status_dup_22_s3_bits_set;
  wire [7:0] i_io_status_dup_22_s3_bits_set;
  wire [3:0] g_io_status_dup_22_s3_bits_way_en;
  wire [3:0] i_io_status_dup_22_s3_bits_way_en;
  wire g_io_status_dup_23_s1_valid;
  wire i_io_status_dup_23_s1_valid;
  wire [7:0] g_io_status_dup_23_s1_bits_set;
  wire [7:0] i_io_status_dup_23_s1_bits_set;
  wire [3:0] g_io_status_dup_23_s1_bits_way_en;
  wire [3:0] i_io_status_dup_23_s1_bits_way_en;
  wire g_io_status_dup_23_s2_valid;
  wire i_io_status_dup_23_s2_valid;
  wire [7:0] g_io_status_dup_23_s2_bits_set;
  wire [7:0] i_io_status_dup_23_s2_bits_set;
  wire [3:0] g_io_status_dup_23_s2_bits_way_en;
  wire [3:0] i_io_status_dup_23_s2_bits_way_en;
  wire g_io_status_dup_23_s3_valid;
  wire i_io_status_dup_23_s3_valid;
  wire [7:0] g_io_status_dup_23_s3_bits_set;
  wire [7:0] i_io_status_dup_23_s3_bits_set;
  wire [3:0] g_io_status_dup_23_s3_bits_way_en;
  wire [3:0] i_io_status_dup_23_s3_bits_way_en;
  wire g_io_lrsc_locked_block_valid;
  wire i_io_lrsc_locked_block_valid;
  wire [47:0] g_io_lrsc_locked_block_bits;
  wire [47:0] i_io_lrsc_locked_block_bits;
  wire g_io_update_resv_set;
  wire i_io_update_resv_set;
  wire g_io_block_lr;
  wire i_io_block_lr;
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
  wire g_io_bloom_filter_query_set_valid;
  wire i_io_bloom_filter_query_set_valid;
  wire [11:0] g_io_bloom_filter_query_set_bits_addr;
  wire [11:0] i_io_bloom_filter_query_set_bits_addr;
  wire g_io_bloom_filter_query_clr_valid;
  wire i_io_bloom_filter_query_clr_valid;
  wire [11:0] g_io_bloom_filter_query_clr_bits_addr;
  wire [11:0] i_io_bloom_filter_query_clr_bits_addr;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  MainPipe    u_g (.clock(clk), .reset(rst), .io_probe_req_valid(io_probe_req_valid), .io_probe_req_bits_probe_param(io_probe_req_bits_probe_param), .io_probe_req_bits_probe_need_data(io_probe_req_bits_probe_need_data), .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr), .io_probe_req_bits_addr(io_probe_req_bits_addr), .io_probe_req_bits_id(io_probe_req_bits_id), .io_miss_req_ready(io_miss_req_ready), .io_refill_req_valid(io_refill_req_valid), .io_refill_req_bits_miss(io_refill_req_bits_miss), .io_refill_req_bits_miss_id(io_refill_req_bits_miss_id), .io_refill_req_bits_occupy_way(io_refill_req_bits_occupy_way), .io_refill_req_bits_miss_fail_cause_evict_btot(io_refill_req_bits_miss_fail_cause_evict_btot), .io_refill_req_bits_source(io_refill_req_bits_source), .io_refill_req_bits_cmd(io_refill_req_bits_cmd), .io_refill_req_bits_vaddr(io_refill_req_bits_vaddr), .io_refill_req_bits_addr(io_refill_req_bits_addr), .io_refill_req_bits_word_idx(io_refill_req_bits_word_idx), .io_refill_req_bits_amo_data(io_refill_req_bits_amo_data), .io_refill_req_bits_amo_mask(io_refill_req_bits_amo_mask), .io_refill_req_bits_amo_cmp(io_refill_req_bits_amo_cmp), .io_refill_req_bits_pf_source(io_refill_req_bits_pf_source), .io_refill_req_bits_access(io_refill_req_bits_access), .io_refill_req_bits_id(io_refill_req_bits_id), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_store_req_valid(io_store_req_valid), .io_store_req_bits_vaddr(io_store_req_bits_vaddr), .io_store_req_bits_addr(io_store_req_bits_addr), .io_store_req_bits_data(io_store_req_bits_data), .io_store_req_bits_mask(io_store_req_bits_mask), .io_store_req_bits_id(io_store_req_bits_id), .io_atomic_req_valid(io_atomic_req_valid), .io_atomic_req_bits_cmd(io_atomic_req_bits_cmd), .io_atomic_req_bits_vaddr(io_atomic_req_bits_vaddr), .io_atomic_req_bits_addr(io_atomic_req_bits_addr), .io_atomic_req_bits_word_idx(io_atomic_req_bits_word_idx), .io_atomic_req_bits_amo_data(io_atomic_req_bits_amo_data), .io_atomic_req_bits_amo_mask(io_atomic_req_bits_amo_mask), .io_atomic_req_bits_amo_cmp(io_atomic_req_bits_amo_cmp), .io_refill_info_valid(io_refill_info_valid), .io_refill_info_bits_store_data(io_refill_info_bits_store_data), .io_refill_info_bits_store_mask(io_refill_info_bits_store_mask), .io_refill_info_bits_miss_param(io_refill_info_bits_miss_param), .io_refill_info_bits_error(io_refill_info_bits_error), .io_wb_ready(io_wb_ready), .io_data_readline_ready(io_data_readline_ready), .io_data_resp_0_raw_data(io_data_resp_0_raw_data), .io_data_resp_1_raw_data(io_data_resp_1_raw_data), .io_data_resp_2_raw_data(io_data_resp_2_raw_data), .io_data_resp_3_raw_data(io_data_resp_3_raw_data), .io_data_resp_4_raw_data(io_data_resp_4_raw_data), .io_data_resp_5_raw_data(io_data_resp_5_raw_data), .io_data_resp_6_raw_data(io_data_resp_6_raw_data), .io_data_resp_7_raw_data(io_data_resp_7_raw_data), .io_readline_error(io_readline_error), .io_readline_error_delayed(io_readline_error_delayed), .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state), .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state), .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state), .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state), .io_extra_meta_resp_0_error(io_extra_meta_resp_0_error), .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch), .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access), .io_extra_meta_resp_1_error(io_extra_meta_resp_1_error), .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch), .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access), .io_extra_meta_resp_2_error(io_extra_meta_resp_2_error), .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch), .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access), .io_extra_meta_resp_3_error(io_extra_meta_resp_3_error), .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch), .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access), .io_tag_read_ready(io_tag_read_ready), .io_tag_resp_0(io_tag_resp_0), .io_tag_resp_1(io_tag_resp_1), .io_tag_resp_2(io_tag_resp_2), .io_tag_resp_3(io_tag_resp_3), .io_replace_way_way(io_replace_way_way), .io_btot_ways_for_set(io_btot_ways_for_set), .io_replace_block(io_replace_block), .io_invalid_resv_set(io_invalid_resv_set), .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid), .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask), .io_probe_req_ready(g_io_probe_req_ready), .io_miss_req_valid(g_io_miss_req_valid), .io_miss_req_bits_source(g_io_miss_req_bits_source), .io_miss_req_bits_cmd(g_io_miss_req_bits_cmd), .io_miss_req_bits_addr(g_io_miss_req_bits_addr), .io_miss_req_bits_vaddr(g_io_miss_req_bits_vaddr), .io_miss_req_bits_full_overwrite(g_io_miss_req_bits_full_overwrite), .io_miss_req_bits_word_idx(g_io_miss_req_bits_word_idx), .io_miss_req_bits_amo_data(g_io_miss_req_bits_amo_data), .io_miss_req_bits_amo_mask(g_io_miss_req_bits_amo_mask), .io_miss_req_bits_amo_cmp(g_io_miss_req_bits_amo_cmp), .io_miss_req_bits_req_coh_state(g_io_miss_req_bits_req_coh_state), .io_miss_req_bits_id(g_io_miss_req_bits_id), .io_miss_req_bits_isBtoT(g_io_miss_req_bits_isBtoT), .io_miss_req_bits_occupy_way(g_io_miss_req_bits_occupy_way), .io_miss_req_bits_cancel(g_io_miss_req_bits_cancel), .io_miss_req_bits_store_data(g_io_miss_req_bits_store_data), .io_miss_req_bits_store_mask(g_io_miss_req_bits_store_mask), .io_refill_req_ready(g_io_refill_req_ready), .io_wbq_conflict_check_valid(g_io_wbq_conflict_check_valid), .io_wbq_conflict_check_bits(g_io_wbq_conflict_check_bits), .io_store_req_ready(g_io_store_req_ready), .io_store_replay_resp_valid(g_io_store_replay_resp_valid), .io_store_replay_resp_bits_id(g_io_store_replay_resp_bits_id), .io_store_hit_resp_valid(g_io_store_hit_resp_valid), .io_store_hit_resp_bits_id(g_io_store_hit_resp_bits_id), .io_atomic_req_ready(g_io_atomic_req_ready), .io_atomic_resp_valid(g_io_atomic_resp_valid), .io_atomic_resp_bits_source(g_io_atomic_resp_bits_source), .io_atomic_resp_bits_data(g_io_atomic_resp_bits_data), .io_atomic_resp_bits_miss(g_io_atomic_resp_bits_miss), .io_atomic_resp_bits_miss_id(g_io_atomic_resp_bits_miss_id), .io_atomic_resp_bits_replay(g_io_atomic_resp_bits_replay), .io_atomic_resp_bits_error(g_io_atomic_resp_bits_error), .io_atomic_resp_bits_ack_miss_queue(g_io_atomic_resp_bits_ack_miss_queue), .io_atomic_resp_bits_id(g_io_atomic_resp_bits_id), .io_mainpipe_info_s2_valid(g_io_mainpipe_info_s2_valid), .io_mainpipe_info_s2_miss_id(g_io_mainpipe_info_s2_miss_id), .io_mainpipe_info_s2_replay_to_mq(g_io_mainpipe_info_s2_replay_to_mq), .io_mainpipe_info_s2_evict_BtoT_way(g_io_mainpipe_info_s2_evict_BtoT_way), .io_mainpipe_info_s2_next_evict_way(g_io_mainpipe_info_s2_next_evict_way), .io_mainpipe_info_s3_valid(g_io_mainpipe_info_s3_valid), .io_mainpipe_info_s3_miss_id(g_io_mainpipe_info_s3_miss_id), .io_mainpipe_info_s3_refill_resp(g_io_mainpipe_info_s3_refill_resp), .io_wb_valid(g_io_wb_valid), .io_wb_bits_param(g_io_wb_bits_param), .io_wb_bits_voluntary(g_io_wb_bits_voluntary), .io_wb_bits_hasData(g_io_wb_bits_hasData), .io_wb_bits_corrupt(g_io_wb_bits_corrupt), .io_wb_bits_dirty(g_io_wb_bits_dirty), .io_wb_bits_addr(g_io_wb_bits_addr), .io_wb_bits_data(g_io_wb_bits_data), .io_data_read_intend(g_io_data_read_intend), .io_data_readline_valid(g_io_data_readline_valid), .io_data_readline_bits_way_en(g_io_data_readline_bits_way_en), .io_data_readline_bits_addr(g_io_data_readline_bits_addr), .io_data_readline_bits_rmask(g_io_data_readline_bits_rmask), .io_data_readline_can_go(g_io_data_readline_can_go), .io_data_readline_stall(g_io_data_readline_stall), .io_data_readline_can_resp(g_io_data_readline_can_resp), .io_data_write_valid(g_io_data_write_valid), .io_data_write_bits_wmask(g_io_data_write_bits_wmask), .io_data_write_bits_data_0(g_io_data_write_bits_data_0), .io_data_write_bits_data_1(g_io_data_write_bits_data_1), .io_data_write_bits_data_2(g_io_data_write_bits_data_2), .io_data_write_bits_data_3(g_io_data_write_bits_data_3), .io_data_write_bits_data_4(g_io_data_write_bits_data_4), .io_data_write_bits_data_5(g_io_data_write_bits_data_5), .io_data_write_bits_data_6(g_io_data_write_bits_data_6), .io_data_write_bits_data_7(g_io_data_write_bits_data_7), .io_data_write_dup_0_valid(g_io_data_write_dup_0_valid), .io_data_write_dup_0_bits_way_en(g_io_data_write_dup_0_bits_way_en), .io_data_write_dup_0_bits_addr(g_io_data_write_dup_0_bits_addr), .io_data_write_dup_1_valid(g_io_data_write_dup_1_valid), .io_data_write_dup_1_bits_way_en(g_io_data_write_dup_1_bits_way_en), .io_data_write_dup_1_bits_addr(g_io_data_write_dup_1_bits_addr), .io_data_write_dup_2_valid(g_io_data_write_dup_2_valid), .io_data_write_dup_2_bits_way_en(g_io_data_write_dup_2_bits_way_en), .io_data_write_dup_2_bits_addr(g_io_data_write_dup_2_bits_addr), .io_data_write_dup_3_valid(g_io_data_write_dup_3_valid), .io_data_write_dup_3_bits_way_en(g_io_data_write_dup_3_bits_way_en), .io_data_write_dup_3_bits_addr(g_io_data_write_dup_3_bits_addr), .io_data_write_dup_4_valid(g_io_data_write_dup_4_valid), .io_data_write_dup_4_bits_way_en(g_io_data_write_dup_4_bits_way_en), .io_data_write_dup_4_bits_addr(g_io_data_write_dup_4_bits_addr), .io_data_write_dup_5_valid(g_io_data_write_dup_5_valid), .io_data_write_dup_5_bits_way_en(g_io_data_write_dup_5_bits_way_en), .io_data_write_dup_5_bits_addr(g_io_data_write_dup_5_bits_addr), .io_data_write_dup_6_valid(g_io_data_write_dup_6_valid), .io_data_write_dup_6_bits_way_en(g_io_data_write_dup_6_bits_way_en), .io_data_write_dup_6_bits_addr(g_io_data_write_dup_6_bits_addr), .io_data_write_dup_7_valid(g_io_data_write_dup_7_valid), .io_data_write_dup_7_bits_way_en(g_io_data_write_dup_7_bits_way_en), .io_data_write_dup_7_bits_addr(g_io_data_write_dup_7_bits_addr), .io_meta_read_valid(g_io_meta_read_valid), .io_meta_read_bits_idx(g_io_meta_read_bits_idx), .io_meta_write_valid(g_io_meta_write_valid), .io_meta_write_bits_idx(g_io_meta_write_bits_idx), .io_meta_write_bits_way_en(g_io_meta_write_bits_way_en), .io_meta_write_bits_meta_coh_state(g_io_meta_write_bits_meta_coh_state), .io_error_flag_write_valid(g_io_error_flag_write_valid), .io_error_flag_write_bits_idx(g_io_error_flag_write_bits_idx), .io_error_flag_write_bits_way_en(g_io_error_flag_write_bits_way_en), .io_error_flag_write_bits_flag(g_io_error_flag_write_bits_flag), .io_prefetch_flag_write_valid(g_io_prefetch_flag_write_valid), .io_prefetch_flag_write_bits_idx(g_io_prefetch_flag_write_bits_idx), .io_prefetch_flag_write_bits_way_en(g_io_prefetch_flag_write_bits_way_en), .io_prefetch_flag_write_bits_source(g_io_prefetch_flag_write_bits_source), .io_access_flag_write_valid(g_io_access_flag_write_valid), .io_access_flag_write_bits_idx(g_io_access_flag_write_bits_idx), .io_access_flag_write_bits_way_en(g_io_access_flag_write_bits_way_en), .io_access_flag_write_bits_flag(g_io_access_flag_write_bits_flag), .io_tag_read_valid(g_io_tag_read_valid), .io_tag_read_bits_idx(g_io_tag_read_bits_idx), .io_tag_write_valid(g_io_tag_write_valid), .io_tag_write_bits_idx(g_io_tag_write_bits_idx), .io_tag_write_bits_way_en(g_io_tag_write_bits_way_en), .io_tag_write_bits_tag(g_io_tag_write_bits_tag), .io_tag_write_intend(g_io_tag_write_intend), .io_replace_access_valid(g_io_replace_access_valid), .io_replace_access_bits_set(g_io_replace_access_bits_set), .io_replace_access_bits_way(g_io_replace_access_bits_way), .io_replace_way_set_bits(g_io_replace_way_set_bits), .io_evict_set(g_io_evict_set), .io_replace_req_bits_addr(g_io_replace_req_bits_addr), .io_replace_req_bits_vaddr(g_io_replace_req_bits_vaddr), .io_sms_agt_evict_req_valid(g_io_sms_agt_evict_req_valid), .io_sms_agt_evict_req_bits_vaddr(g_io_sms_agt_evict_req_bits_vaddr), .io_status_dup_0_s1_valid(g_io_status_dup_0_s1_valid), .io_status_dup_0_s1_bits_set(g_io_status_dup_0_s1_bits_set), .io_status_dup_0_s1_bits_way_en(g_io_status_dup_0_s1_bits_way_en), .io_status_dup_0_s2_valid(g_io_status_dup_0_s2_valid), .io_status_dup_0_s2_bits_set(g_io_status_dup_0_s2_bits_set), .io_status_dup_0_s2_bits_way_en(g_io_status_dup_0_s2_bits_way_en), .io_status_dup_0_s3_valid(g_io_status_dup_0_s3_valid), .io_status_dup_0_s3_bits_set(g_io_status_dup_0_s3_bits_set), .io_status_dup_0_s3_bits_way_en(g_io_status_dup_0_s3_bits_way_en), .io_status_dup_1_s1_valid(g_io_status_dup_1_s1_valid), .io_status_dup_1_s1_bits_set(g_io_status_dup_1_s1_bits_set), .io_status_dup_1_s1_bits_way_en(g_io_status_dup_1_s1_bits_way_en), .io_status_dup_1_s2_valid(g_io_status_dup_1_s2_valid), .io_status_dup_1_s2_bits_set(g_io_status_dup_1_s2_bits_set), .io_status_dup_1_s2_bits_way_en(g_io_status_dup_1_s2_bits_way_en), .io_status_dup_1_s3_valid(g_io_status_dup_1_s3_valid), .io_status_dup_1_s3_bits_set(g_io_status_dup_1_s3_bits_set), .io_status_dup_1_s3_bits_way_en(g_io_status_dup_1_s3_bits_way_en), .io_status_dup_2_s1_valid(g_io_status_dup_2_s1_valid), .io_status_dup_2_s1_bits_set(g_io_status_dup_2_s1_bits_set), .io_status_dup_2_s1_bits_way_en(g_io_status_dup_2_s1_bits_way_en), .io_status_dup_2_s2_valid(g_io_status_dup_2_s2_valid), .io_status_dup_2_s2_bits_set(g_io_status_dup_2_s2_bits_set), .io_status_dup_2_s2_bits_way_en(g_io_status_dup_2_s2_bits_way_en), .io_status_dup_2_s3_valid(g_io_status_dup_2_s3_valid), .io_status_dup_2_s3_bits_set(g_io_status_dup_2_s3_bits_set), .io_status_dup_2_s3_bits_way_en(g_io_status_dup_2_s3_bits_way_en), .io_status_dup_3_s1_valid(g_io_status_dup_3_s1_valid), .io_status_dup_3_s1_bits_set(g_io_status_dup_3_s1_bits_set), .io_status_dup_3_s1_bits_way_en(g_io_status_dup_3_s1_bits_way_en), .io_status_dup_3_s2_valid(g_io_status_dup_3_s2_valid), .io_status_dup_3_s2_bits_set(g_io_status_dup_3_s2_bits_set), .io_status_dup_3_s2_bits_way_en(g_io_status_dup_3_s2_bits_way_en), .io_status_dup_3_s3_valid(g_io_status_dup_3_s3_valid), .io_status_dup_3_s3_bits_set(g_io_status_dup_3_s3_bits_set), .io_status_dup_3_s3_bits_way_en(g_io_status_dup_3_s3_bits_way_en), .io_status_dup_4_s1_valid(g_io_status_dup_4_s1_valid), .io_status_dup_4_s1_bits_set(g_io_status_dup_4_s1_bits_set), .io_status_dup_4_s1_bits_way_en(g_io_status_dup_4_s1_bits_way_en), .io_status_dup_4_s2_valid(g_io_status_dup_4_s2_valid), .io_status_dup_4_s2_bits_set(g_io_status_dup_4_s2_bits_set), .io_status_dup_4_s2_bits_way_en(g_io_status_dup_4_s2_bits_way_en), .io_status_dup_4_s3_valid(g_io_status_dup_4_s3_valid), .io_status_dup_4_s3_bits_set(g_io_status_dup_4_s3_bits_set), .io_status_dup_4_s3_bits_way_en(g_io_status_dup_4_s3_bits_way_en), .io_status_dup_5_s1_valid(g_io_status_dup_5_s1_valid), .io_status_dup_5_s1_bits_set(g_io_status_dup_5_s1_bits_set), .io_status_dup_5_s1_bits_way_en(g_io_status_dup_5_s1_bits_way_en), .io_status_dup_5_s2_valid(g_io_status_dup_5_s2_valid), .io_status_dup_5_s2_bits_set(g_io_status_dup_5_s2_bits_set), .io_status_dup_5_s2_bits_way_en(g_io_status_dup_5_s2_bits_way_en), .io_status_dup_5_s3_valid(g_io_status_dup_5_s3_valid), .io_status_dup_5_s3_bits_set(g_io_status_dup_5_s3_bits_set), .io_status_dup_5_s3_bits_way_en(g_io_status_dup_5_s3_bits_way_en), .io_status_dup_6_s1_valid(g_io_status_dup_6_s1_valid), .io_status_dup_6_s1_bits_set(g_io_status_dup_6_s1_bits_set), .io_status_dup_6_s1_bits_way_en(g_io_status_dup_6_s1_bits_way_en), .io_status_dup_6_s2_valid(g_io_status_dup_6_s2_valid), .io_status_dup_6_s2_bits_set(g_io_status_dup_6_s2_bits_set), .io_status_dup_6_s2_bits_way_en(g_io_status_dup_6_s2_bits_way_en), .io_status_dup_6_s3_valid(g_io_status_dup_6_s3_valid), .io_status_dup_6_s3_bits_set(g_io_status_dup_6_s3_bits_set), .io_status_dup_6_s3_bits_way_en(g_io_status_dup_6_s3_bits_way_en), .io_status_dup_7_s1_valid(g_io_status_dup_7_s1_valid), .io_status_dup_7_s1_bits_set(g_io_status_dup_7_s1_bits_set), .io_status_dup_7_s1_bits_way_en(g_io_status_dup_7_s1_bits_way_en), .io_status_dup_7_s2_valid(g_io_status_dup_7_s2_valid), .io_status_dup_7_s2_bits_set(g_io_status_dup_7_s2_bits_set), .io_status_dup_7_s2_bits_way_en(g_io_status_dup_7_s2_bits_way_en), .io_status_dup_7_s3_valid(g_io_status_dup_7_s3_valid), .io_status_dup_7_s3_bits_set(g_io_status_dup_7_s3_bits_set), .io_status_dup_7_s3_bits_way_en(g_io_status_dup_7_s3_bits_way_en), .io_status_dup_8_s1_valid(g_io_status_dup_8_s1_valid), .io_status_dup_8_s1_bits_set(g_io_status_dup_8_s1_bits_set), .io_status_dup_8_s1_bits_way_en(g_io_status_dup_8_s1_bits_way_en), .io_status_dup_8_s2_valid(g_io_status_dup_8_s2_valid), .io_status_dup_8_s2_bits_set(g_io_status_dup_8_s2_bits_set), .io_status_dup_8_s2_bits_way_en(g_io_status_dup_8_s2_bits_way_en), .io_status_dup_8_s3_valid(g_io_status_dup_8_s3_valid), .io_status_dup_8_s3_bits_set(g_io_status_dup_8_s3_bits_set), .io_status_dup_8_s3_bits_way_en(g_io_status_dup_8_s3_bits_way_en), .io_status_dup_9_s1_valid(g_io_status_dup_9_s1_valid), .io_status_dup_9_s1_bits_set(g_io_status_dup_9_s1_bits_set), .io_status_dup_9_s1_bits_way_en(g_io_status_dup_9_s1_bits_way_en), .io_status_dup_9_s2_valid(g_io_status_dup_9_s2_valid), .io_status_dup_9_s2_bits_set(g_io_status_dup_9_s2_bits_set), .io_status_dup_9_s2_bits_way_en(g_io_status_dup_9_s2_bits_way_en), .io_status_dup_9_s3_valid(g_io_status_dup_9_s3_valid), .io_status_dup_9_s3_bits_set(g_io_status_dup_9_s3_bits_set), .io_status_dup_9_s3_bits_way_en(g_io_status_dup_9_s3_bits_way_en), .io_status_dup_10_s1_valid(g_io_status_dup_10_s1_valid), .io_status_dup_10_s1_bits_set(g_io_status_dup_10_s1_bits_set), .io_status_dup_10_s1_bits_way_en(g_io_status_dup_10_s1_bits_way_en), .io_status_dup_10_s2_valid(g_io_status_dup_10_s2_valid), .io_status_dup_10_s2_bits_set(g_io_status_dup_10_s2_bits_set), .io_status_dup_10_s2_bits_way_en(g_io_status_dup_10_s2_bits_way_en), .io_status_dup_10_s3_valid(g_io_status_dup_10_s3_valid), .io_status_dup_10_s3_bits_set(g_io_status_dup_10_s3_bits_set), .io_status_dup_10_s3_bits_way_en(g_io_status_dup_10_s3_bits_way_en), .io_status_dup_11_s1_valid(g_io_status_dup_11_s1_valid), .io_status_dup_11_s1_bits_set(g_io_status_dup_11_s1_bits_set), .io_status_dup_11_s1_bits_way_en(g_io_status_dup_11_s1_bits_way_en), .io_status_dup_11_s2_valid(g_io_status_dup_11_s2_valid), .io_status_dup_11_s2_bits_set(g_io_status_dup_11_s2_bits_set), .io_status_dup_11_s2_bits_way_en(g_io_status_dup_11_s2_bits_way_en), .io_status_dup_11_s3_valid(g_io_status_dup_11_s3_valid), .io_status_dup_11_s3_bits_set(g_io_status_dup_11_s3_bits_set), .io_status_dup_11_s3_bits_way_en(g_io_status_dup_11_s3_bits_way_en), .io_status_dup_12_s1_valid(g_io_status_dup_12_s1_valid), .io_status_dup_12_s1_bits_set(g_io_status_dup_12_s1_bits_set), .io_status_dup_12_s1_bits_way_en(g_io_status_dup_12_s1_bits_way_en), .io_status_dup_12_s2_valid(g_io_status_dup_12_s2_valid), .io_status_dup_12_s2_bits_set(g_io_status_dup_12_s2_bits_set), .io_status_dup_12_s2_bits_way_en(g_io_status_dup_12_s2_bits_way_en), .io_status_dup_12_s3_valid(g_io_status_dup_12_s3_valid), .io_status_dup_12_s3_bits_set(g_io_status_dup_12_s3_bits_set), .io_status_dup_12_s3_bits_way_en(g_io_status_dup_12_s3_bits_way_en), .io_status_dup_13_s1_valid(g_io_status_dup_13_s1_valid), .io_status_dup_13_s1_bits_set(g_io_status_dup_13_s1_bits_set), .io_status_dup_13_s1_bits_way_en(g_io_status_dup_13_s1_bits_way_en), .io_status_dup_13_s2_valid(g_io_status_dup_13_s2_valid), .io_status_dup_13_s2_bits_set(g_io_status_dup_13_s2_bits_set), .io_status_dup_13_s2_bits_way_en(g_io_status_dup_13_s2_bits_way_en), .io_status_dup_13_s3_valid(g_io_status_dup_13_s3_valid), .io_status_dup_13_s3_bits_set(g_io_status_dup_13_s3_bits_set), .io_status_dup_13_s3_bits_way_en(g_io_status_dup_13_s3_bits_way_en), .io_status_dup_14_s1_valid(g_io_status_dup_14_s1_valid), .io_status_dup_14_s1_bits_set(g_io_status_dup_14_s1_bits_set), .io_status_dup_14_s1_bits_way_en(g_io_status_dup_14_s1_bits_way_en), .io_status_dup_14_s2_valid(g_io_status_dup_14_s2_valid), .io_status_dup_14_s2_bits_set(g_io_status_dup_14_s2_bits_set), .io_status_dup_14_s2_bits_way_en(g_io_status_dup_14_s2_bits_way_en), .io_status_dup_14_s3_valid(g_io_status_dup_14_s3_valid), .io_status_dup_14_s3_bits_set(g_io_status_dup_14_s3_bits_set), .io_status_dup_14_s3_bits_way_en(g_io_status_dup_14_s3_bits_way_en), .io_status_dup_15_s1_valid(g_io_status_dup_15_s1_valid), .io_status_dup_15_s1_bits_set(g_io_status_dup_15_s1_bits_set), .io_status_dup_15_s1_bits_way_en(g_io_status_dup_15_s1_bits_way_en), .io_status_dup_15_s2_valid(g_io_status_dup_15_s2_valid), .io_status_dup_15_s2_bits_set(g_io_status_dup_15_s2_bits_set), .io_status_dup_15_s2_bits_way_en(g_io_status_dup_15_s2_bits_way_en), .io_status_dup_15_s3_valid(g_io_status_dup_15_s3_valid), .io_status_dup_15_s3_bits_set(g_io_status_dup_15_s3_bits_set), .io_status_dup_15_s3_bits_way_en(g_io_status_dup_15_s3_bits_way_en), .io_status_dup_16_s1_valid(g_io_status_dup_16_s1_valid), .io_status_dup_16_s1_bits_set(g_io_status_dup_16_s1_bits_set), .io_status_dup_16_s1_bits_way_en(g_io_status_dup_16_s1_bits_way_en), .io_status_dup_16_s2_valid(g_io_status_dup_16_s2_valid), .io_status_dup_16_s2_bits_set(g_io_status_dup_16_s2_bits_set), .io_status_dup_16_s2_bits_way_en(g_io_status_dup_16_s2_bits_way_en), .io_status_dup_16_s3_valid(g_io_status_dup_16_s3_valid), .io_status_dup_16_s3_bits_set(g_io_status_dup_16_s3_bits_set), .io_status_dup_16_s3_bits_way_en(g_io_status_dup_16_s3_bits_way_en), .io_status_dup_17_s1_valid(g_io_status_dup_17_s1_valid), .io_status_dup_17_s1_bits_set(g_io_status_dup_17_s1_bits_set), .io_status_dup_17_s1_bits_way_en(g_io_status_dup_17_s1_bits_way_en), .io_status_dup_17_s2_valid(g_io_status_dup_17_s2_valid), .io_status_dup_17_s2_bits_set(g_io_status_dup_17_s2_bits_set), .io_status_dup_17_s2_bits_way_en(g_io_status_dup_17_s2_bits_way_en), .io_status_dup_17_s3_valid(g_io_status_dup_17_s3_valid), .io_status_dup_17_s3_bits_set(g_io_status_dup_17_s3_bits_set), .io_status_dup_17_s3_bits_way_en(g_io_status_dup_17_s3_bits_way_en), .io_status_dup_18_s1_valid(g_io_status_dup_18_s1_valid), .io_status_dup_18_s1_bits_set(g_io_status_dup_18_s1_bits_set), .io_status_dup_18_s1_bits_way_en(g_io_status_dup_18_s1_bits_way_en), .io_status_dup_18_s2_valid(g_io_status_dup_18_s2_valid), .io_status_dup_18_s2_bits_set(g_io_status_dup_18_s2_bits_set), .io_status_dup_18_s2_bits_way_en(g_io_status_dup_18_s2_bits_way_en), .io_status_dup_18_s3_valid(g_io_status_dup_18_s3_valid), .io_status_dup_18_s3_bits_set(g_io_status_dup_18_s3_bits_set), .io_status_dup_18_s3_bits_way_en(g_io_status_dup_18_s3_bits_way_en), .io_status_dup_19_s1_valid(g_io_status_dup_19_s1_valid), .io_status_dup_19_s1_bits_set(g_io_status_dup_19_s1_bits_set), .io_status_dup_19_s1_bits_way_en(g_io_status_dup_19_s1_bits_way_en), .io_status_dup_19_s2_valid(g_io_status_dup_19_s2_valid), .io_status_dup_19_s2_bits_set(g_io_status_dup_19_s2_bits_set), .io_status_dup_19_s2_bits_way_en(g_io_status_dup_19_s2_bits_way_en), .io_status_dup_19_s3_valid(g_io_status_dup_19_s3_valid), .io_status_dup_19_s3_bits_set(g_io_status_dup_19_s3_bits_set), .io_status_dup_19_s3_bits_way_en(g_io_status_dup_19_s3_bits_way_en), .io_status_dup_20_s1_valid(g_io_status_dup_20_s1_valid), .io_status_dup_20_s1_bits_set(g_io_status_dup_20_s1_bits_set), .io_status_dup_20_s1_bits_way_en(g_io_status_dup_20_s1_bits_way_en), .io_status_dup_20_s2_valid(g_io_status_dup_20_s2_valid), .io_status_dup_20_s2_bits_set(g_io_status_dup_20_s2_bits_set), .io_status_dup_20_s2_bits_way_en(g_io_status_dup_20_s2_bits_way_en), .io_status_dup_20_s3_valid(g_io_status_dup_20_s3_valid), .io_status_dup_20_s3_bits_set(g_io_status_dup_20_s3_bits_set), .io_status_dup_20_s3_bits_way_en(g_io_status_dup_20_s3_bits_way_en), .io_status_dup_21_s1_valid(g_io_status_dup_21_s1_valid), .io_status_dup_21_s1_bits_set(g_io_status_dup_21_s1_bits_set), .io_status_dup_21_s1_bits_way_en(g_io_status_dup_21_s1_bits_way_en), .io_status_dup_21_s2_valid(g_io_status_dup_21_s2_valid), .io_status_dup_21_s2_bits_set(g_io_status_dup_21_s2_bits_set), .io_status_dup_21_s2_bits_way_en(g_io_status_dup_21_s2_bits_way_en), .io_status_dup_21_s3_valid(g_io_status_dup_21_s3_valid), .io_status_dup_21_s3_bits_set(g_io_status_dup_21_s3_bits_set), .io_status_dup_21_s3_bits_way_en(g_io_status_dup_21_s3_bits_way_en), .io_status_dup_22_s1_valid(g_io_status_dup_22_s1_valid), .io_status_dup_22_s1_bits_set(g_io_status_dup_22_s1_bits_set), .io_status_dup_22_s1_bits_way_en(g_io_status_dup_22_s1_bits_way_en), .io_status_dup_22_s2_valid(g_io_status_dup_22_s2_valid), .io_status_dup_22_s2_bits_set(g_io_status_dup_22_s2_bits_set), .io_status_dup_22_s2_bits_way_en(g_io_status_dup_22_s2_bits_way_en), .io_status_dup_22_s3_valid(g_io_status_dup_22_s3_valid), .io_status_dup_22_s3_bits_set(g_io_status_dup_22_s3_bits_set), .io_status_dup_22_s3_bits_way_en(g_io_status_dup_22_s3_bits_way_en), .io_status_dup_23_s1_valid(g_io_status_dup_23_s1_valid), .io_status_dup_23_s1_bits_set(g_io_status_dup_23_s1_bits_set), .io_status_dup_23_s1_bits_way_en(g_io_status_dup_23_s1_bits_way_en), .io_status_dup_23_s2_valid(g_io_status_dup_23_s2_valid), .io_status_dup_23_s2_bits_set(g_io_status_dup_23_s2_bits_set), .io_status_dup_23_s2_bits_way_en(g_io_status_dup_23_s2_bits_way_en), .io_status_dup_23_s3_valid(g_io_status_dup_23_s3_valid), .io_status_dup_23_s3_bits_set(g_io_status_dup_23_s3_bits_set), .io_status_dup_23_s3_bits_way_en(g_io_status_dup_23_s3_bits_way_en), .io_lrsc_locked_block_valid(g_io_lrsc_locked_block_valid), .io_lrsc_locked_block_bits(g_io_lrsc_locked_block_bits), .io_update_resv_set(g_io_update_resv_set), .io_block_lr(g_io_block_lr), .io_error_valid(g_io_error_valid), .io_error_bits_paddr(g_io_error_bits_paddr), .io_error_bits_report_to_beu(g_io_error_bits_report_to_beu), .io_pseudo_tag_error_inj_done(g_io_pseudo_tag_error_inj_done), .io_pseudo_data_error_inj_done(g_io_pseudo_data_error_inj_done), .io_bloom_filter_query_set_valid(g_io_bloom_filter_query_set_valid), .io_bloom_filter_query_set_bits_addr(g_io_bloom_filter_query_set_bits_addr), .io_bloom_filter_query_clr_valid(g_io_bloom_filter_query_clr_valid), .io_bloom_filter_query_clr_bits_addr(g_io_bloom_filter_query_clr_bits_addr), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value));
  MainPipe_xs u_i (.clock(clk), .reset(rst), .io_probe_req_valid(io_probe_req_valid), .io_probe_req_bits_probe_param(io_probe_req_bits_probe_param), .io_probe_req_bits_probe_need_data(io_probe_req_bits_probe_need_data), .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr), .io_probe_req_bits_addr(io_probe_req_bits_addr), .io_probe_req_bits_id(io_probe_req_bits_id), .io_miss_req_ready(io_miss_req_ready), .io_refill_req_valid(io_refill_req_valid), .io_refill_req_bits_miss(io_refill_req_bits_miss), .io_refill_req_bits_miss_id(io_refill_req_bits_miss_id), .io_refill_req_bits_occupy_way(io_refill_req_bits_occupy_way), .io_refill_req_bits_miss_fail_cause_evict_btot(io_refill_req_bits_miss_fail_cause_evict_btot), .io_refill_req_bits_source(io_refill_req_bits_source), .io_refill_req_bits_cmd(io_refill_req_bits_cmd), .io_refill_req_bits_vaddr(io_refill_req_bits_vaddr), .io_refill_req_bits_addr(io_refill_req_bits_addr), .io_refill_req_bits_word_idx(io_refill_req_bits_word_idx), .io_refill_req_bits_amo_data(io_refill_req_bits_amo_data), .io_refill_req_bits_amo_mask(io_refill_req_bits_amo_mask), .io_refill_req_bits_amo_cmp(io_refill_req_bits_amo_cmp), .io_refill_req_bits_pf_source(io_refill_req_bits_pf_source), .io_refill_req_bits_access(io_refill_req_bits_access), .io_refill_req_bits_id(io_refill_req_bits_id), .io_wbq_block_miss_req(io_wbq_block_miss_req), .io_store_req_valid(io_store_req_valid), .io_store_req_bits_vaddr(io_store_req_bits_vaddr), .io_store_req_bits_addr(io_store_req_bits_addr), .io_store_req_bits_data(io_store_req_bits_data), .io_store_req_bits_mask(io_store_req_bits_mask), .io_store_req_bits_id(io_store_req_bits_id), .io_atomic_req_valid(io_atomic_req_valid), .io_atomic_req_bits_cmd(io_atomic_req_bits_cmd), .io_atomic_req_bits_vaddr(io_atomic_req_bits_vaddr), .io_atomic_req_bits_addr(io_atomic_req_bits_addr), .io_atomic_req_bits_word_idx(io_atomic_req_bits_word_idx), .io_atomic_req_bits_amo_data(io_atomic_req_bits_amo_data), .io_atomic_req_bits_amo_mask(io_atomic_req_bits_amo_mask), .io_atomic_req_bits_amo_cmp(io_atomic_req_bits_amo_cmp), .io_refill_info_valid(io_refill_info_valid), .io_refill_info_bits_store_data(io_refill_info_bits_store_data), .io_refill_info_bits_store_mask(io_refill_info_bits_store_mask), .io_refill_info_bits_miss_param(io_refill_info_bits_miss_param), .io_refill_info_bits_error(io_refill_info_bits_error), .io_wb_ready(io_wb_ready), .io_data_readline_ready(io_data_readline_ready), .io_data_resp_0_raw_data(io_data_resp_0_raw_data), .io_data_resp_1_raw_data(io_data_resp_1_raw_data), .io_data_resp_2_raw_data(io_data_resp_2_raw_data), .io_data_resp_3_raw_data(io_data_resp_3_raw_data), .io_data_resp_4_raw_data(io_data_resp_4_raw_data), .io_data_resp_5_raw_data(io_data_resp_5_raw_data), .io_data_resp_6_raw_data(io_data_resp_6_raw_data), .io_data_resp_7_raw_data(io_data_resp_7_raw_data), .io_readline_error(io_readline_error), .io_readline_error_delayed(io_readline_error_delayed), .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state), .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state), .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state), .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state), .io_extra_meta_resp_0_error(io_extra_meta_resp_0_error), .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch), .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access), .io_extra_meta_resp_1_error(io_extra_meta_resp_1_error), .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch), .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access), .io_extra_meta_resp_2_error(io_extra_meta_resp_2_error), .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch), .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access), .io_extra_meta_resp_3_error(io_extra_meta_resp_3_error), .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch), .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access), .io_tag_read_ready(io_tag_read_ready), .io_tag_resp_0(io_tag_resp_0), .io_tag_resp_1(io_tag_resp_1), .io_tag_resp_2(io_tag_resp_2), .io_tag_resp_3(io_tag_resp_3), .io_replace_way_way(io_replace_way_way), .io_btot_ways_for_set(io_btot_ways_for_set), .io_replace_block(io_replace_block), .io_invalid_resv_set(io_invalid_resv_set), .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid), .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask), .io_probe_req_ready(i_io_probe_req_ready), .io_miss_req_valid(i_io_miss_req_valid), .io_miss_req_bits_source(i_io_miss_req_bits_source), .io_miss_req_bits_cmd(i_io_miss_req_bits_cmd), .io_miss_req_bits_addr(i_io_miss_req_bits_addr), .io_miss_req_bits_vaddr(i_io_miss_req_bits_vaddr), .io_miss_req_bits_full_overwrite(i_io_miss_req_bits_full_overwrite), .io_miss_req_bits_word_idx(i_io_miss_req_bits_word_idx), .io_miss_req_bits_amo_data(i_io_miss_req_bits_amo_data), .io_miss_req_bits_amo_mask(i_io_miss_req_bits_amo_mask), .io_miss_req_bits_amo_cmp(i_io_miss_req_bits_amo_cmp), .io_miss_req_bits_req_coh_state(i_io_miss_req_bits_req_coh_state), .io_miss_req_bits_id(i_io_miss_req_bits_id), .io_miss_req_bits_isBtoT(i_io_miss_req_bits_isBtoT), .io_miss_req_bits_occupy_way(i_io_miss_req_bits_occupy_way), .io_miss_req_bits_cancel(i_io_miss_req_bits_cancel), .io_miss_req_bits_store_data(i_io_miss_req_bits_store_data), .io_miss_req_bits_store_mask(i_io_miss_req_bits_store_mask), .io_refill_req_ready(i_io_refill_req_ready), .io_wbq_conflict_check_valid(i_io_wbq_conflict_check_valid), .io_wbq_conflict_check_bits(i_io_wbq_conflict_check_bits), .io_store_req_ready(i_io_store_req_ready), .io_store_replay_resp_valid(i_io_store_replay_resp_valid), .io_store_replay_resp_bits_id(i_io_store_replay_resp_bits_id), .io_store_hit_resp_valid(i_io_store_hit_resp_valid), .io_store_hit_resp_bits_id(i_io_store_hit_resp_bits_id), .io_atomic_req_ready(i_io_atomic_req_ready), .io_atomic_resp_valid(i_io_atomic_resp_valid), .io_atomic_resp_bits_source(i_io_atomic_resp_bits_source), .io_atomic_resp_bits_data(i_io_atomic_resp_bits_data), .io_atomic_resp_bits_miss(i_io_atomic_resp_bits_miss), .io_atomic_resp_bits_miss_id(i_io_atomic_resp_bits_miss_id), .io_atomic_resp_bits_replay(i_io_atomic_resp_bits_replay), .io_atomic_resp_bits_error(i_io_atomic_resp_bits_error), .io_atomic_resp_bits_ack_miss_queue(i_io_atomic_resp_bits_ack_miss_queue), .io_atomic_resp_bits_id(i_io_atomic_resp_bits_id), .io_mainpipe_info_s2_valid(i_io_mainpipe_info_s2_valid), .io_mainpipe_info_s2_miss_id(i_io_mainpipe_info_s2_miss_id), .io_mainpipe_info_s2_replay_to_mq(i_io_mainpipe_info_s2_replay_to_mq), .io_mainpipe_info_s2_evict_BtoT_way(i_io_mainpipe_info_s2_evict_BtoT_way), .io_mainpipe_info_s2_next_evict_way(i_io_mainpipe_info_s2_next_evict_way), .io_mainpipe_info_s3_valid(i_io_mainpipe_info_s3_valid), .io_mainpipe_info_s3_miss_id(i_io_mainpipe_info_s3_miss_id), .io_mainpipe_info_s3_refill_resp(i_io_mainpipe_info_s3_refill_resp), .io_wb_valid(i_io_wb_valid), .io_wb_bits_param(i_io_wb_bits_param), .io_wb_bits_voluntary(i_io_wb_bits_voluntary), .io_wb_bits_hasData(i_io_wb_bits_hasData), .io_wb_bits_corrupt(i_io_wb_bits_corrupt), .io_wb_bits_dirty(i_io_wb_bits_dirty), .io_wb_bits_addr(i_io_wb_bits_addr), .io_wb_bits_data(i_io_wb_bits_data), .io_data_read_intend(i_io_data_read_intend), .io_data_readline_valid(i_io_data_readline_valid), .io_data_readline_bits_way_en(i_io_data_readline_bits_way_en), .io_data_readline_bits_addr(i_io_data_readline_bits_addr), .io_data_readline_bits_rmask(i_io_data_readline_bits_rmask), .io_data_readline_can_go(i_io_data_readline_can_go), .io_data_readline_stall(i_io_data_readline_stall), .io_data_readline_can_resp(i_io_data_readline_can_resp), .io_data_write_valid(i_io_data_write_valid), .io_data_write_bits_wmask(i_io_data_write_bits_wmask), .io_data_write_bits_data_0(i_io_data_write_bits_data_0), .io_data_write_bits_data_1(i_io_data_write_bits_data_1), .io_data_write_bits_data_2(i_io_data_write_bits_data_2), .io_data_write_bits_data_3(i_io_data_write_bits_data_3), .io_data_write_bits_data_4(i_io_data_write_bits_data_4), .io_data_write_bits_data_5(i_io_data_write_bits_data_5), .io_data_write_bits_data_6(i_io_data_write_bits_data_6), .io_data_write_bits_data_7(i_io_data_write_bits_data_7), .io_data_write_dup_0_valid(i_io_data_write_dup_0_valid), .io_data_write_dup_0_bits_way_en(i_io_data_write_dup_0_bits_way_en), .io_data_write_dup_0_bits_addr(i_io_data_write_dup_0_bits_addr), .io_data_write_dup_1_valid(i_io_data_write_dup_1_valid), .io_data_write_dup_1_bits_way_en(i_io_data_write_dup_1_bits_way_en), .io_data_write_dup_1_bits_addr(i_io_data_write_dup_1_bits_addr), .io_data_write_dup_2_valid(i_io_data_write_dup_2_valid), .io_data_write_dup_2_bits_way_en(i_io_data_write_dup_2_bits_way_en), .io_data_write_dup_2_bits_addr(i_io_data_write_dup_2_bits_addr), .io_data_write_dup_3_valid(i_io_data_write_dup_3_valid), .io_data_write_dup_3_bits_way_en(i_io_data_write_dup_3_bits_way_en), .io_data_write_dup_3_bits_addr(i_io_data_write_dup_3_bits_addr), .io_data_write_dup_4_valid(i_io_data_write_dup_4_valid), .io_data_write_dup_4_bits_way_en(i_io_data_write_dup_4_bits_way_en), .io_data_write_dup_4_bits_addr(i_io_data_write_dup_4_bits_addr), .io_data_write_dup_5_valid(i_io_data_write_dup_5_valid), .io_data_write_dup_5_bits_way_en(i_io_data_write_dup_5_bits_way_en), .io_data_write_dup_5_bits_addr(i_io_data_write_dup_5_bits_addr), .io_data_write_dup_6_valid(i_io_data_write_dup_6_valid), .io_data_write_dup_6_bits_way_en(i_io_data_write_dup_6_bits_way_en), .io_data_write_dup_6_bits_addr(i_io_data_write_dup_6_bits_addr), .io_data_write_dup_7_valid(i_io_data_write_dup_7_valid), .io_data_write_dup_7_bits_way_en(i_io_data_write_dup_7_bits_way_en), .io_data_write_dup_7_bits_addr(i_io_data_write_dup_7_bits_addr), .io_meta_read_valid(i_io_meta_read_valid), .io_meta_read_bits_idx(i_io_meta_read_bits_idx), .io_meta_write_valid(i_io_meta_write_valid), .io_meta_write_bits_idx(i_io_meta_write_bits_idx), .io_meta_write_bits_way_en(i_io_meta_write_bits_way_en), .io_meta_write_bits_meta_coh_state(i_io_meta_write_bits_meta_coh_state), .io_error_flag_write_valid(i_io_error_flag_write_valid), .io_error_flag_write_bits_idx(i_io_error_flag_write_bits_idx), .io_error_flag_write_bits_way_en(i_io_error_flag_write_bits_way_en), .io_error_flag_write_bits_flag(i_io_error_flag_write_bits_flag), .io_prefetch_flag_write_valid(i_io_prefetch_flag_write_valid), .io_prefetch_flag_write_bits_idx(i_io_prefetch_flag_write_bits_idx), .io_prefetch_flag_write_bits_way_en(i_io_prefetch_flag_write_bits_way_en), .io_prefetch_flag_write_bits_source(i_io_prefetch_flag_write_bits_source), .io_access_flag_write_valid(i_io_access_flag_write_valid), .io_access_flag_write_bits_idx(i_io_access_flag_write_bits_idx), .io_access_flag_write_bits_way_en(i_io_access_flag_write_bits_way_en), .io_access_flag_write_bits_flag(i_io_access_flag_write_bits_flag), .io_tag_read_valid(i_io_tag_read_valid), .io_tag_read_bits_idx(i_io_tag_read_bits_idx), .io_tag_write_valid(i_io_tag_write_valid), .io_tag_write_bits_idx(i_io_tag_write_bits_idx), .io_tag_write_bits_way_en(i_io_tag_write_bits_way_en), .io_tag_write_bits_tag(i_io_tag_write_bits_tag), .io_tag_write_intend(i_io_tag_write_intend), .io_replace_access_valid(i_io_replace_access_valid), .io_replace_access_bits_set(i_io_replace_access_bits_set), .io_replace_access_bits_way(i_io_replace_access_bits_way), .io_replace_way_set_bits(i_io_replace_way_set_bits), .io_evict_set(i_io_evict_set), .io_replace_req_bits_addr(i_io_replace_req_bits_addr), .io_replace_req_bits_vaddr(i_io_replace_req_bits_vaddr), .io_sms_agt_evict_req_valid(i_io_sms_agt_evict_req_valid), .io_sms_agt_evict_req_bits_vaddr(i_io_sms_agt_evict_req_bits_vaddr), .io_status_dup_0_s1_valid(i_io_status_dup_0_s1_valid), .io_status_dup_0_s1_bits_set(i_io_status_dup_0_s1_bits_set), .io_status_dup_0_s1_bits_way_en(i_io_status_dup_0_s1_bits_way_en), .io_status_dup_0_s2_valid(i_io_status_dup_0_s2_valid), .io_status_dup_0_s2_bits_set(i_io_status_dup_0_s2_bits_set), .io_status_dup_0_s2_bits_way_en(i_io_status_dup_0_s2_bits_way_en), .io_status_dup_0_s3_valid(i_io_status_dup_0_s3_valid), .io_status_dup_0_s3_bits_set(i_io_status_dup_0_s3_bits_set), .io_status_dup_0_s3_bits_way_en(i_io_status_dup_0_s3_bits_way_en), .io_status_dup_1_s1_valid(i_io_status_dup_1_s1_valid), .io_status_dup_1_s1_bits_set(i_io_status_dup_1_s1_bits_set), .io_status_dup_1_s1_bits_way_en(i_io_status_dup_1_s1_bits_way_en), .io_status_dup_1_s2_valid(i_io_status_dup_1_s2_valid), .io_status_dup_1_s2_bits_set(i_io_status_dup_1_s2_bits_set), .io_status_dup_1_s2_bits_way_en(i_io_status_dup_1_s2_bits_way_en), .io_status_dup_1_s3_valid(i_io_status_dup_1_s3_valid), .io_status_dup_1_s3_bits_set(i_io_status_dup_1_s3_bits_set), .io_status_dup_1_s3_bits_way_en(i_io_status_dup_1_s3_bits_way_en), .io_status_dup_2_s1_valid(i_io_status_dup_2_s1_valid), .io_status_dup_2_s1_bits_set(i_io_status_dup_2_s1_bits_set), .io_status_dup_2_s1_bits_way_en(i_io_status_dup_2_s1_bits_way_en), .io_status_dup_2_s2_valid(i_io_status_dup_2_s2_valid), .io_status_dup_2_s2_bits_set(i_io_status_dup_2_s2_bits_set), .io_status_dup_2_s2_bits_way_en(i_io_status_dup_2_s2_bits_way_en), .io_status_dup_2_s3_valid(i_io_status_dup_2_s3_valid), .io_status_dup_2_s3_bits_set(i_io_status_dup_2_s3_bits_set), .io_status_dup_2_s3_bits_way_en(i_io_status_dup_2_s3_bits_way_en), .io_status_dup_3_s1_valid(i_io_status_dup_3_s1_valid), .io_status_dup_3_s1_bits_set(i_io_status_dup_3_s1_bits_set), .io_status_dup_3_s1_bits_way_en(i_io_status_dup_3_s1_bits_way_en), .io_status_dup_3_s2_valid(i_io_status_dup_3_s2_valid), .io_status_dup_3_s2_bits_set(i_io_status_dup_3_s2_bits_set), .io_status_dup_3_s2_bits_way_en(i_io_status_dup_3_s2_bits_way_en), .io_status_dup_3_s3_valid(i_io_status_dup_3_s3_valid), .io_status_dup_3_s3_bits_set(i_io_status_dup_3_s3_bits_set), .io_status_dup_3_s3_bits_way_en(i_io_status_dup_3_s3_bits_way_en), .io_status_dup_4_s1_valid(i_io_status_dup_4_s1_valid), .io_status_dup_4_s1_bits_set(i_io_status_dup_4_s1_bits_set), .io_status_dup_4_s1_bits_way_en(i_io_status_dup_4_s1_bits_way_en), .io_status_dup_4_s2_valid(i_io_status_dup_4_s2_valid), .io_status_dup_4_s2_bits_set(i_io_status_dup_4_s2_bits_set), .io_status_dup_4_s2_bits_way_en(i_io_status_dup_4_s2_bits_way_en), .io_status_dup_4_s3_valid(i_io_status_dup_4_s3_valid), .io_status_dup_4_s3_bits_set(i_io_status_dup_4_s3_bits_set), .io_status_dup_4_s3_bits_way_en(i_io_status_dup_4_s3_bits_way_en), .io_status_dup_5_s1_valid(i_io_status_dup_5_s1_valid), .io_status_dup_5_s1_bits_set(i_io_status_dup_5_s1_bits_set), .io_status_dup_5_s1_bits_way_en(i_io_status_dup_5_s1_bits_way_en), .io_status_dup_5_s2_valid(i_io_status_dup_5_s2_valid), .io_status_dup_5_s2_bits_set(i_io_status_dup_5_s2_bits_set), .io_status_dup_5_s2_bits_way_en(i_io_status_dup_5_s2_bits_way_en), .io_status_dup_5_s3_valid(i_io_status_dup_5_s3_valid), .io_status_dup_5_s3_bits_set(i_io_status_dup_5_s3_bits_set), .io_status_dup_5_s3_bits_way_en(i_io_status_dup_5_s3_bits_way_en), .io_status_dup_6_s1_valid(i_io_status_dup_6_s1_valid), .io_status_dup_6_s1_bits_set(i_io_status_dup_6_s1_bits_set), .io_status_dup_6_s1_bits_way_en(i_io_status_dup_6_s1_bits_way_en), .io_status_dup_6_s2_valid(i_io_status_dup_6_s2_valid), .io_status_dup_6_s2_bits_set(i_io_status_dup_6_s2_bits_set), .io_status_dup_6_s2_bits_way_en(i_io_status_dup_6_s2_bits_way_en), .io_status_dup_6_s3_valid(i_io_status_dup_6_s3_valid), .io_status_dup_6_s3_bits_set(i_io_status_dup_6_s3_bits_set), .io_status_dup_6_s3_bits_way_en(i_io_status_dup_6_s3_bits_way_en), .io_status_dup_7_s1_valid(i_io_status_dup_7_s1_valid), .io_status_dup_7_s1_bits_set(i_io_status_dup_7_s1_bits_set), .io_status_dup_7_s1_bits_way_en(i_io_status_dup_7_s1_bits_way_en), .io_status_dup_7_s2_valid(i_io_status_dup_7_s2_valid), .io_status_dup_7_s2_bits_set(i_io_status_dup_7_s2_bits_set), .io_status_dup_7_s2_bits_way_en(i_io_status_dup_7_s2_bits_way_en), .io_status_dup_7_s3_valid(i_io_status_dup_7_s3_valid), .io_status_dup_7_s3_bits_set(i_io_status_dup_7_s3_bits_set), .io_status_dup_7_s3_bits_way_en(i_io_status_dup_7_s3_bits_way_en), .io_status_dup_8_s1_valid(i_io_status_dup_8_s1_valid), .io_status_dup_8_s1_bits_set(i_io_status_dup_8_s1_bits_set), .io_status_dup_8_s1_bits_way_en(i_io_status_dup_8_s1_bits_way_en), .io_status_dup_8_s2_valid(i_io_status_dup_8_s2_valid), .io_status_dup_8_s2_bits_set(i_io_status_dup_8_s2_bits_set), .io_status_dup_8_s2_bits_way_en(i_io_status_dup_8_s2_bits_way_en), .io_status_dup_8_s3_valid(i_io_status_dup_8_s3_valid), .io_status_dup_8_s3_bits_set(i_io_status_dup_8_s3_bits_set), .io_status_dup_8_s3_bits_way_en(i_io_status_dup_8_s3_bits_way_en), .io_status_dup_9_s1_valid(i_io_status_dup_9_s1_valid), .io_status_dup_9_s1_bits_set(i_io_status_dup_9_s1_bits_set), .io_status_dup_9_s1_bits_way_en(i_io_status_dup_9_s1_bits_way_en), .io_status_dup_9_s2_valid(i_io_status_dup_9_s2_valid), .io_status_dup_9_s2_bits_set(i_io_status_dup_9_s2_bits_set), .io_status_dup_9_s2_bits_way_en(i_io_status_dup_9_s2_bits_way_en), .io_status_dup_9_s3_valid(i_io_status_dup_9_s3_valid), .io_status_dup_9_s3_bits_set(i_io_status_dup_9_s3_bits_set), .io_status_dup_9_s3_bits_way_en(i_io_status_dup_9_s3_bits_way_en), .io_status_dup_10_s1_valid(i_io_status_dup_10_s1_valid), .io_status_dup_10_s1_bits_set(i_io_status_dup_10_s1_bits_set), .io_status_dup_10_s1_bits_way_en(i_io_status_dup_10_s1_bits_way_en), .io_status_dup_10_s2_valid(i_io_status_dup_10_s2_valid), .io_status_dup_10_s2_bits_set(i_io_status_dup_10_s2_bits_set), .io_status_dup_10_s2_bits_way_en(i_io_status_dup_10_s2_bits_way_en), .io_status_dup_10_s3_valid(i_io_status_dup_10_s3_valid), .io_status_dup_10_s3_bits_set(i_io_status_dup_10_s3_bits_set), .io_status_dup_10_s3_bits_way_en(i_io_status_dup_10_s3_bits_way_en), .io_status_dup_11_s1_valid(i_io_status_dup_11_s1_valid), .io_status_dup_11_s1_bits_set(i_io_status_dup_11_s1_bits_set), .io_status_dup_11_s1_bits_way_en(i_io_status_dup_11_s1_bits_way_en), .io_status_dup_11_s2_valid(i_io_status_dup_11_s2_valid), .io_status_dup_11_s2_bits_set(i_io_status_dup_11_s2_bits_set), .io_status_dup_11_s2_bits_way_en(i_io_status_dup_11_s2_bits_way_en), .io_status_dup_11_s3_valid(i_io_status_dup_11_s3_valid), .io_status_dup_11_s3_bits_set(i_io_status_dup_11_s3_bits_set), .io_status_dup_11_s3_bits_way_en(i_io_status_dup_11_s3_bits_way_en), .io_status_dup_12_s1_valid(i_io_status_dup_12_s1_valid), .io_status_dup_12_s1_bits_set(i_io_status_dup_12_s1_bits_set), .io_status_dup_12_s1_bits_way_en(i_io_status_dup_12_s1_bits_way_en), .io_status_dup_12_s2_valid(i_io_status_dup_12_s2_valid), .io_status_dup_12_s2_bits_set(i_io_status_dup_12_s2_bits_set), .io_status_dup_12_s2_bits_way_en(i_io_status_dup_12_s2_bits_way_en), .io_status_dup_12_s3_valid(i_io_status_dup_12_s3_valid), .io_status_dup_12_s3_bits_set(i_io_status_dup_12_s3_bits_set), .io_status_dup_12_s3_bits_way_en(i_io_status_dup_12_s3_bits_way_en), .io_status_dup_13_s1_valid(i_io_status_dup_13_s1_valid), .io_status_dup_13_s1_bits_set(i_io_status_dup_13_s1_bits_set), .io_status_dup_13_s1_bits_way_en(i_io_status_dup_13_s1_bits_way_en), .io_status_dup_13_s2_valid(i_io_status_dup_13_s2_valid), .io_status_dup_13_s2_bits_set(i_io_status_dup_13_s2_bits_set), .io_status_dup_13_s2_bits_way_en(i_io_status_dup_13_s2_bits_way_en), .io_status_dup_13_s3_valid(i_io_status_dup_13_s3_valid), .io_status_dup_13_s3_bits_set(i_io_status_dup_13_s3_bits_set), .io_status_dup_13_s3_bits_way_en(i_io_status_dup_13_s3_bits_way_en), .io_status_dup_14_s1_valid(i_io_status_dup_14_s1_valid), .io_status_dup_14_s1_bits_set(i_io_status_dup_14_s1_bits_set), .io_status_dup_14_s1_bits_way_en(i_io_status_dup_14_s1_bits_way_en), .io_status_dup_14_s2_valid(i_io_status_dup_14_s2_valid), .io_status_dup_14_s2_bits_set(i_io_status_dup_14_s2_bits_set), .io_status_dup_14_s2_bits_way_en(i_io_status_dup_14_s2_bits_way_en), .io_status_dup_14_s3_valid(i_io_status_dup_14_s3_valid), .io_status_dup_14_s3_bits_set(i_io_status_dup_14_s3_bits_set), .io_status_dup_14_s3_bits_way_en(i_io_status_dup_14_s3_bits_way_en), .io_status_dup_15_s1_valid(i_io_status_dup_15_s1_valid), .io_status_dup_15_s1_bits_set(i_io_status_dup_15_s1_bits_set), .io_status_dup_15_s1_bits_way_en(i_io_status_dup_15_s1_bits_way_en), .io_status_dup_15_s2_valid(i_io_status_dup_15_s2_valid), .io_status_dup_15_s2_bits_set(i_io_status_dup_15_s2_bits_set), .io_status_dup_15_s2_bits_way_en(i_io_status_dup_15_s2_bits_way_en), .io_status_dup_15_s3_valid(i_io_status_dup_15_s3_valid), .io_status_dup_15_s3_bits_set(i_io_status_dup_15_s3_bits_set), .io_status_dup_15_s3_bits_way_en(i_io_status_dup_15_s3_bits_way_en), .io_status_dup_16_s1_valid(i_io_status_dup_16_s1_valid), .io_status_dup_16_s1_bits_set(i_io_status_dup_16_s1_bits_set), .io_status_dup_16_s1_bits_way_en(i_io_status_dup_16_s1_bits_way_en), .io_status_dup_16_s2_valid(i_io_status_dup_16_s2_valid), .io_status_dup_16_s2_bits_set(i_io_status_dup_16_s2_bits_set), .io_status_dup_16_s2_bits_way_en(i_io_status_dup_16_s2_bits_way_en), .io_status_dup_16_s3_valid(i_io_status_dup_16_s3_valid), .io_status_dup_16_s3_bits_set(i_io_status_dup_16_s3_bits_set), .io_status_dup_16_s3_bits_way_en(i_io_status_dup_16_s3_bits_way_en), .io_status_dup_17_s1_valid(i_io_status_dup_17_s1_valid), .io_status_dup_17_s1_bits_set(i_io_status_dup_17_s1_bits_set), .io_status_dup_17_s1_bits_way_en(i_io_status_dup_17_s1_bits_way_en), .io_status_dup_17_s2_valid(i_io_status_dup_17_s2_valid), .io_status_dup_17_s2_bits_set(i_io_status_dup_17_s2_bits_set), .io_status_dup_17_s2_bits_way_en(i_io_status_dup_17_s2_bits_way_en), .io_status_dup_17_s3_valid(i_io_status_dup_17_s3_valid), .io_status_dup_17_s3_bits_set(i_io_status_dup_17_s3_bits_set), .io_status_dup_17_s3_bits_way_en(i_io_status_dup_17_s3_bits_way_en), .io_status_dup_18_s1_valid(i_io_status_dup_18_s1_valid), .io_status_dup_18_s1_bits_set(i_io_status_dup_18_s1_bits_set), .io_status_dup_18_s1_bits_way_en(i_io_status_dup_18_s1_bits_way_en), .io_status_dup_18_s2_valid(i_io_status_dup_18_s2_valid), .io_status_dup_18_s2_bits_set(i_io_status_dup_18_s2_bits_set), .io_status_dup_18_s2_bits_way_en(i_io_status_dup_18_s2_bits_way_en), .io_status_dup_18_s3_valid(i_io_status_dup_18_s3_valid), .io_status_dup_18_s3_bits_set(i_io_status_dup_18_s3_bits_set), .io_status_dup_18_s3_bits_way_en(i_io_status_dup_18_s3_bits_way_en), .io_status_dup_19_s1_valid(i_io_status_dup_19_s1_valid), .io_status_dup_19_s1_bits_set(i_io_status_dup_19_s1_bits_set), .io_status_dup_19_s1_bits_way_en(i_io_status_dup_19_s1_bits_way_en), .io_status_dup_19_s2_valid(i_io_status_dup_19_s2_valid), .io_status_dup_19_s2_bits_set(i_io_status_dup_19_s2_bits_set), .io_status_dup_19_s2_bits_way_en(i_io_status_dup_19_s2_bits_way_en), .io_status_dup_19_s3_valid(i_io_status_dup_19_s3_valid), .io_status_dup_19_s3_bits_set(i_io_status_dup_19_s3_bits_set), .io_status_dup_19_s3_bits_way_en(i_io_status_dup_19_s3_bits_way_en), .io_status_dup_20_s1_valid(i_io_status_dup_20_s1_valid), .io_status_dup_20_s1_bits_set(i_io_status_dup_20_s1_bits_set), .io_status_dup_20_s1_bits_way_en(i_io_status_dup_20_s1_bits_way_en), .io_status_dup_20_s2_valid(i_io_status_dup_20_s2_valid), .io_status_dup_20_s2_bits_set(i_io_status_dup_20_s2_bits_set), .io_status_dup_20_s2_bits_way_en(i_io_status_dup_20_s2_bits_way_en), .io_status_dup_20_s3_valid(i_io_status_dup_20_s3_valid), .io_status_dup_20_s3_bits_set(i_io_status_dup_20_s3_bits_set), .io_status_dup_20_s3_bits_way_en(i_io_status_dup_20_s3_bits_way_en), .io_status_dup_21_s1_valid(i_io_status_dup_21_s1_valid), .io_status_dup_21_s1_bits_set(i_io_status_dup_21_s1_bits_set), .io_status_dup_21_s1_bits_way_en(i_io_status_dup_21_s1_bits_way_en), .io_status_dup_21_s2_valid(i_io_status_dup_21_s2_valid), .io_status_dup_21_s2_bits_set(i_io_status_dup_21_s2_bits_set), .io_status_dup_21_s2_bits_way_en(i_io_status_dup_21_s2_bits_way_en), .io_status_dup_21_s3_valid(i_io_status_dup_21_s3_valid), .io_status_dup_21_s3_bits_set(i_io_status_dup_21_s3_bits_set), .io_status_dup_21_s3_bits_way_en(i_io_status_dup_21_s3_bits_way_en), .io_status_dup_22_s1_valid(i_io_status_dup_22_s1_valid), .io_status_dup_22_s1_bits_set(i_io_status_dup_22_s1_bits_set), .io_status_dup_22_s1_bits_way_en(i_io_status_dup_22_s1_bits_way_en), .io_status_dup_22_s2_valid(i_io_status_dup_22_s2_valid), .io_status_dup_22_s2_bits_set(i_io_status_dup_22_s2_bits_set), .io_status_dup_22_s2_bits_way_en(i_io_status_dup_22_s2_bits_way_en), .io_status_dup_22_s3_valid(i_io_status_dup_22_s3_valid), .io_status_dup_22_s3_bits_set(i_io_status_dup_22_s3_bits_set), .io_status_dup_22_s3_bits_way_en(i_io_status_dup_22_s3_bits_way_en), .io_status_dup_23_s1_valid(i_io_status_dup_23_s1_valid), .io_status_dup_23_s1_bits_set(i_io_status_dup_23_s1_bits_set), .io_status_dup_23_s1_bits_way_en(i_io_status_dup_23_s1_bits_way_en), .io_status_dup_23_s2_valid(i_io_status_dup_23_s2_valid), .io_status_dup_23_s2_bits_set(i_io_status_dup_23_s2_bits_set), .io_status_dup_23_s2_bits_way_en(i_io_status_dup_23_s2_bits_way_en), .io_status_dup_23_s3_valid(i_io_status_dup_23_s3_valid), .io_status_dup_23_s3_bits_set(i_io_status_dup_23_s3_bits_set), .io_status_dup_23_s3_bits_way_en(i_io_status_dup_23_s3_bits_way_en), .io_lrsc_locked_block_valid(i_io_lrsc_locked_block_valid), .io_lrsc_locked_block_bits(i_io_lrsc_locked_block_bits), .io_update_resv_set(i_io_update_resv_set), .io_block_lr(i_io_block_lr), .io_error_valid(i_io_error_valid), .io_error_bits_paddr(i_io_error_bits_paddr), .io_error_bits_report_to_beu(i_io_error_bits_report_to_beu), .io_pseudo_tag_error_inj_done(i_io_pseudo_tag_error_inj_done), .io_pseudo_data_error_inj_done(i_io_pseudo_data_error_inj_done), .io_bloom_filter_query_set_valid(i_io_bloom_filter_query_set_valid), .io_bloom_filter_query_set_bits_addr(i_io_bloom_filter_query_set_bits_addr), .io_bloom_filter_query_clr_valid(i_io_bloom_filter_query_clr_valid), .io_bloom_filter_query_clr_bits_addr(i_io_bloom_filter_query_clr_bits_addr), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value));
  always @(negedge clk) begin
    if (rst) begin
      io_probe_req_valid <= 1'b0;
      io_refill_req_valid <= 1'b0;
      io_store_req_valid <= 1'b0;
      io_atomic_req_valid <= 1'b0;
      io_refill_info_valid <= 1'b0;
      io_pseudo_error_valid <= 1'b0;
    end else begin
      io_probe_req_valid <= ($urandom_range(0,4)==0);
      io_probe_req_bits_probe_param <= 2'($urandom);
      io_probe_req_bits_probe_need_data <= $urandom_range(0,1);
      io_probe_req_bits_vaddr <= {42'($urandom_range(0,3)), 8'($urandom)};
      io_probe_req_bits_addr <= {40'($urandom_range(0,3)), 8'($urandom)};
      io_probe_req_bits_id <= 6'($urandom);
      io_miss_req_ready <= ($urandom_range(0,3)!=0);
      io_refill_req_valid <= ($urandom_range(0,3)==0);
      io_refill_req_bits_miss <= ($urandom_range(0,1));
      io_refill_req_bits_miss_id <= 4'($urandom);
      io_refill_req_bits_occupy_way <= 4'($urandom);
      io_refill_req_bits_miss_fail_cause_evict_btot <= $urandom_range(0,1);
      io_refill_req_bits_source <= 4'($urandom_range(0,3));
      io_refill_req_bits_vaddr <= {42'($urandom_range(0,3)), 8'($urandom)};
      io_refill_req_bits_addr <= {40'($urandom_range(0,3)), 8'($urandom)};
      io_refill_req_bits_word_idx <= 3'($urandom);
      io_refill_req_bits_amo_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_refill_req_bits_amo_mask <= 16'($urandom);
      io_refill_req_bits_amo_cmp <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_refill_req_bits_pf_source <= 3'($urandom);
      io_refill_req_bits_access <= $urandom_range(0,1);
      io_refill_req_bits_id <= 6'($urandom);
      io_wbq_block_miss_req <= ($urandom_range(0,4)==0);
      io_store_req_valid <= ($urandom_range(0,1));
      io_store_req_bits_vaddr <= {42'($urandom_range(0,3)), 8'($urandom)};
      io_store_req_bits_addr <= {40'($urandom_range(0,3)), 8'($urandom)};
      io_store_req_bits_data <= 512'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_store_req_bits_mask <= 64'({$urandom(), $urandom()});
      io_store_req_bits_id <= 6'($urandom);
      io_atomic_req_valid <= ($urandom_range(0,3)==0);
      io_atomic_req_bits_vaddr <= {42'($urandom_range(0,3)), 8'($urandom)};
      io_atomic_req_bits_addr <= {40'($urandom_range(0,3)), 8'($urandom)};
      io_atomic_req_bits_word_idx <= 3'($urandom);
      io_atomic_req_bits_amo_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_atomic_req_bits_amo_mask <= 16'($urandom);
      io_atomic_req_bits_amo_cmp <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      io_refill_info_valid <= ($urandom_range(0,1));
      io_refill_info_bits_store_data <= 512'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_refill_info_bits_store_mask <= 64'({$urandom(), $urandom()});
      io_refill_info_bits_miss_param <= 2'($urandom);
      io_refill_info_bits_error <= $urandom_range(0,1);
      io_wb_ready <= ($urandom_range(0,3)!=0);
      io_data_readline_ready <= ($urandom_range(0,3)!=0);
      io_data_resp_0_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_1_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_2_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_3_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_4_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_5_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_6_raw_data <= 64'({$urandom(), $urandom()});
      io_data_resp_7_raw_data <= 64'({$urandom(), $urandom()});
      io_readline_error <= $urandom_range(0,1);
      io_readline_error_delayed <= $urandom_range(0,1);
      io_meta_resp_0_coh_state <= 2'($urandom);
      io_meta_resp_1_coh_state <= 2'($urandom);
      io_meta_resp_2_coh_state <= 2'($urandom);
      io_meta_resp_3_coh_state <= 2'($urandom);
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
      io_tag_resp_0 <= {7'h0, 36'($urandom_range(0,7))};
      io_tag_resp_1 <= {7'h0, 36'($urandom_range(0,7))};
      io_tag_resp_2 <= {7'h0, 36'($urandom_range(0,7))};
      io_tag_resp_3 <= {7'h0, 36'($urandom_range(0,7))};
      io_replace_way_way <= 2'($urandom);
      io_btot_ways_for_set <= 4'($urandom);
      io_replace_block <= ($urandom_range(0,4)==0);
      io_invalid_resv_set <= ($urandom_range(0,7)==0);
      io_pseudo_error_valid <= ($urandom_range(0,7)==0);
      io_pseudo_error_bits_0_valid <= $urandom_range(0,1);
      io_pseudo_error_bits_0_mask <= 64'({$urandom(), $urandom()});
      begin int c; c=$urandom_range(0,9); case(c) 0:io_refill_req_bits_cmd<=5'h01; 1:io_refill_req_bits_cmd<=5'h04; 2:io_refill_req_bits_cmd<=5'h08; 3:io_refill_req_bits_cmd<=5'h06; 4:io_refill_req_bits_cmd<=5'h07; 5:io_refill_req_bits_cmd<=5'h1A; 6:io_refill_req_bits_cmd<=5'h1B; 7:io_refill_req_bits_cmd<=5'h18; 8:io_refill_req_bits_cmd<=5'h0A; default:io_refill_req_bits_cmd<=5'h01; endcase end;
      begin int c; c=$urandom_range(0,9); case(c) 0:io_atomic_req_bits_cmd<=5'h01; 1:io_atomic_req_bits_cmd<=5'h04; 2:io_atomic_req_bits_cmd<=5'h08; 3:io_atomic_req_bits_cmd<=5'h06; 4:io_atomic_req_bits_cmd<=5'h07; 5:io_atomic_req_bits_cmd<=5'h1A; 6:io_atomic_req_bits_cmd<=5'h1B; 7:io_atomic_req_bits_cmd<=5'h18; 8:io_atomic_req_bits_cmd<=5'h0A; default:io_atomic_req_bits_cmd<=5'h01; endcase end;
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_probe_req_ready) && g_io_probe_req_ready !== i_io_probe_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_probe_req_ready g=%h i=%h", $time, g_io_probe_req_ready, i_io_probe_req_ready); end
    if (!$isunknown(g_io_miss_req_valid) && g_io_miss_req_valid !== i_io_miss_req_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_valid g=%h i=%h", $time, g_io_miss_req_valid, i_io_miss_req_valid); end
    if (!$isunknown(g_io_miss_req_bits_source) && g_io_miss_req_bits_source !== i_io_miss_req_bits_source) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_source g=%h i=%h", $time, g_io_miss_req_bits_source, i_io_miss_req_bits_source); end
    if (!$isunknown(g_io_miss_req_bits_cmd) && g_io_miss_req_bits_cmd !== i_io_miss_req_bits_cmd) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_cmd g=%h i=%h", $time, g_io_miss_req_bits_cmd, i_io_miss_req_bits_cmd); end
    if (!$isunknown(g_io_miss_req_bits_addr) && g_io_miss_req_bits_addr !== i_io_miss_req_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_addr g=%h i=%h", $time, g_io_miss_req_bits_addr, i_io_miss_req_bits_addr); end
    if (!$isunknown(g_io_miss_req_bits_vaddr) && g_io_miss_req_bits_vaddr !== i_io_miss_req_bits_vaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_vaddr g=%h i=%h", $time, g_io_miss_req_bits_vaddr, i_io_miss_req_bits_vaddr); end
    if (!$isunknown(g_io_miss_req_bits_full_overwrite) && g_io_miss_req_bits_full_overwrite !== i_io_miss_req_bits_full_overwrite) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_full_overwrite g=%h i=%h", $time, g_io_miss_req_bits_full_overwrite, i_io_miss_req_bits_full_overwrite); end
    if (!$isunknown(g_io_miss_req_bits_word_idx) && g_io_miss_req_bits_word_idx !== i_io_miss_req_bits_word_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_word_idx g=%h i=%h", $time, g_io_miss_req_bits_word_idx, i_io_miss_req_bits_word_idx); end
    if (!$isunknown(g_io_miss_req_bits_amo_data) && g_io_miss_req_bits_amo_data !== i_io_miss_req_bits_amo_data) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_amo_data g=%h i=%h", $time, g_io_miss_req_bits_amo_data, i_io_miss_req_bits_amo_data); end
    if (!$isunknown(g_io_miss_req_bits_amo_mask) && g_io_miss_req_bits_amo_mask !== i_io_miss_req_bits_amo_mask) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_amo_mask g=%h i=%h", $time, g_io_miss_req_bits_amo_mask, i_io_miss_req_bits_amo_mask); end
    if (!$isunknown(g_io_miss_req_bits_amo_cmp) && g_io_miss_req_bits_amo_cmp !== i_io_miss_req_bits_amo_cmp) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_amo_cmp g=%h i=%h", $time, g_io_miss_req_bits_amo_cmp, i_io_miss_req_bits_amo_cmp); end
    if (!$isunknown(g_io_miss_req_bits_req_coh_state) && g_io_miss_req_bits_req_coh_state !== i_io_miss_req_bits_req_coh_state) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_req_coh_state g=%h i=%h", $time, g_io_miss_req_bits_req_coh_state, i_io_miss_req_bits_req_coh_state); end
    if (!$isunknown(g_io_miss_req_bits_id) && g_io_miss_req_bits_id !== i_io_miss_req_bits_id) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_id g=%h i=%h", $time, g_io_miss_req_bits_id, i_io_miss_req_bits_id); end
    if (!$isunknown(g_io_miss_req_bits_isBtoT) && g_io_miss_req_bits_isBtoT !== i_io_miss_req_bits_isBtoT) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_isBtoT g=%h i=%h", $time, g_io_miss_req_bits_isBtoT, i_io_miss_req_bits_isBtoT); end
    if (!$isunknown(g_io_miss_req_bits_occupy_way) && g_io_miss_req_bits_occupy_way !== i_io_miss_req_bits_occupy_way) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_occupy_way g=%h i=%h", $time, g_io_miss_req_bits_occupy_way, i_io_miss_req_bits_occupy_way); end
    if (!$isunknown(g_io_miss_req_bits_cancel) && g_io_miss_req_bits_cancel !== i_io_miss_req_bits_cancel) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_cancel g=%h i=%h", $time, g_io_miss_req_bits_cancel, i_io_miss_req_bits_cancel); end
    if (!$isunknown(g_io_miss_req_bits_store_data) && g_io_miss_req_bits_store_data !== i_io_miss_req_bits_store_data) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_store_data g=%h i=%h", $time, g_io_miss_req_bits_store_data, i_io_miss_req_bits_store_data); end
    if (!$isunknown(g_io_miss_req_bits_store_mask) && g_io_miss_req_bits_store_mask !== i_io_miss_req_bits_store_mask) begin errors++;
      if(errors<=60) $display("[%0t] io_miss_req_bits_store_mask g=%h i=%h", $time, g_io_miss_req_bits_store_mask, i_io_miss_req_bits_store_mask); end
    if (!$isunknown(g_io_refill_req_ready) && g_io_refill_req_ready !== i_io_refill_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_refill_req_ready g=%h i=%h", $time, g_io_refill_req_ready, i_io_refill_req_ready); end
    if (!$isunknown(g_io_wbq_conflict_check_valid) && g_io_wbq_conflict_check_valid !== i_io_wbq_conflict_check_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_wbq_conflict_check_valid g=%h i=%h", $time, g_io_wbq_conflict_check_valid, i_io_wbq_conflict_check_valid); end
    if (!$isunknown(g_io_wbq_conflict_check_bits) && g_io_wbq_conflict_check_bits !== i_io_wbq_conflict_check_bits) begin errors++;
      if(errors<=60) $display("[%0t] io_wbq_conflict_check_bits g=%h i=%h", $time, g_io_wbq_conflict_check_bits, i_io_wbq_conflict_check_bits); end
    if (!$isunknown(g_io_store_req_ready) && g_io_store_req_ready !== i_io_store_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_store_req_ready g=%h i=%h", $time, g_io_store_req_ready, i_io_store_req_ready); end
    if (!$isunknown(g_io_store_replay_resp_valid) && g_io_store_replay_resp_valid !== i_io_store_replay_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_store_replay_resp_valid g=%h i=%h", $time, g_io_store_replay_resp_valid, i_io_store_replay_resp_valid); end
    if (!$isunknown(g_io_store_replay_resp_bits_id) && g_io_store_replay_resp_bits_id !== i_io_store_replay_resp_bits_id) begin errors++;
      if(errors<=60) $display("[%0t] io_store_replay_resp_bits_id g=%h i=%h", $time, g_io_store_replay_resp_bits_id, i_io_store_replay_resp_bits_id); end
    if (!$isunknown(g_io_store_hit_resp_valid) && g_io_store_hit_resp_valid !== i_io_store_hit_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_store_hit_resp_valid g=%h i=%h", $time, g_io_store_hit_resp_valid, i_io_store_hit_resp_valid); end
    if (!$isunknown(g_io_store_hit_resp_bits_id) && g_io_store_hit_resp_bits_id !== i_io_store_hit_resp_bits_id) begin errors++;
      if(errors<=60) $display("[%0t] io_store_hit_resp_bits_id g=%h i=%h", $time, g_io_store_hit_resp_bits_id, i_io_store_hit_resp_bits_id); end
    if (!$isunknown(g_io_atomic_req_ready) && g_io_atomic_req_ready !== i_io_atomic_req_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_req_ready g=%h i=%h", $time, g_io_atomic_req_ready, i_io_atomic_req_ready); end
    if (!$isunknown(g_io_atomic_resp_valid) && g_io_atomic_resp_valid !== i_io_atomic_resp_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_valid g=%h i=%h", $time, g_io_atomic_resp_valid, i_io_atomic_resp_valid); end
    if (!$isunknown(g_io_atomic_resp_bits_source) && g_io_atomic_resp_bits_source !== i_io_atomic_resp_bits_source) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_source g=%h i=%h", $time, g_io_atomic_resp_bits_source, i_io_atomic_resp_bits_source); end
    if (!$isunknown(g_io_atomic_resp_bits_data) && g_io_atomic_resp_bits_data !== i_io_atomic_resp_bits_data) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_data g=%h i=%h", $time, g_io_atomic_resp_bits_data, i_io_atomic_resp_bits_data); end
    if (!$isunknown(g_io_atomic_resp_bits_miss) && g_io_atomic_resp_bits_miss !== i_io_atomic_resp_bits_miss) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_miss g=%h i=%h", $time, g_io_atomic_resp_bits_miss, i_io_atomic_resp_bits_miss); end
    if (!$isunknown(g_io_atomic_resp_bits_miss_id) && g_io_atomic_resp_bits_miss_id !== i_io_atomic_resp_bits_miss_id) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_miss_id g=%h i=%h", $time, g_io_atomic_resp_bits_miss_id, i_io_atomic_resp_bits_miss_id); end
    if (!$isunknown(g_io_atomic_resp_bits_replay) && g_io_atomic_resp_bits_replay !== i_io_atomic_resp_bits_replay) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_replay g=%h i=%h", $time, g_io_atomic_resp_bits_replay, i_io_atomic_resp_bits_replay); end
    if (!$isunknown(g_io_atomic_resp_bits_error) && g_io_atomic_resp_bits_error !== i_io_atomic_resp_bits_error) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_error g=%h i=%h", $time, g_io_atomic_resp_bits_error, i_io_atomic_resp_bits_error); end
    if (!$isunknown(g_io_atomic_resp_bits_ack_miss_queue) && g_io_atomic_resp_bits_ack_miss_queue !== i_io_atomic_resp_bits_ack_miss_queue) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_ack_miss_queue g=%h i=%h", $time, g_io_atomic_resp_bits_ack_miss_queue, i_io_atomic_resp_bits_ack_miss_queue); end
    if (!$isunknown(g_io_atomic_resp_bits_id) && g_io_atomic_resp_bits_id !== i_io_atomic_resp_bits_id) begin errors++;
      if(errors<=60) $display("[%0t] io_atomic_resp_bits_id g=%h i=%h", $time, g_io_atomic_resp_bits_id, i_io_atomic_resp_bits_id); end
    if (!$isunknown(g_io_mainpipe_info_s2_valid) && g_io_mainpipe_info_s2_valid !== i_io_mainpipe_info_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s2_valid g=%h i=%h", $time, g_io_mainpipe_info_s2_valid, i_io_mainpipe_info_s2_valid); end
    if (!$isunknown(g_io_mainpipe_info_s2_miss_id) && g_io_mainpipe_info_s2_miss_id !== i_io_mainpipe_info_s2_miss_id) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s2_miss_id g=%h i=%h", $time, g_io_mainpipe_info_s2_miss_id, i_io_mainpipe_info_s2_miss_id); end
    if (!$isunknown(g_io_mainpipe_info_s2_replay_to_mq) && g_io_mainpipe_info_s2_replay_to_mq !== i_io_mainpipe_info_s2_replay_to_mq) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s2_replay_to_mq g=%h i=%h", $time, g_io_mainpipe_info_s2_replay_to_mq, i_io_mainpipe_info_s2_replay_to_mq); end
    if (!$isunknown(g_io_mainpipe_info_s2_evict_BtoT_way) && g_io_mainpipe_info_s2_evict_BtoT_way !== i_io_mainpipe_info_s2_evict_BtoT_way) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s2_evict_BtoT_way g=%h i=%h", $time, g_io_mainpipe_info_s2_evict_BtoT_way, i_io_mainpipe_info_s2_evict_BtoT_way); end
    if (!$isunknown(g_io_mainpipe_info_s2_next_evict_way) && g_io_mainpipe_info_s2_next_evict_way !== i_io_mainpipe_info_s2_next_evict_way) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s2_next_evict_way g=%h i=%h", $time, g_io_mainpipe_info_s2_next_evict_way, i_io_mainpipe_info_s2_next_evict_way); end
    if (!$isunknown(g_io_mainpipe_info_s3_valid) && g_io_mainpipe_info_s3_valid !== i_io_mainpipe_info_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s3_valid g=%h i=%h", $time, g_io_mainpipe_info_s3_valid, i_io_mainpipe_info_s3_valid); end
    if (!$isunknown(g_io_mainpipe_info_s3_miss_id) && g_io_mainpipe_info_s3_miss_id !== i_io_mainpipe_info_s3_miss_id) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s3_miss_id g=%h i=%h", $time, g_io_mainpipe_info_s3_miss_id, i_io_mainpipe_info_s3_miss_id); end
    if (!$isunknown(g_io_mainpipe_info_s3_refill_resp) && g_io_mainpipe_info_s3_refill_resp !== i_io_mainpipe_info_s3_refill_resp) begin errors++;
      if(errors<=60) $display("[%0t] io_mainpipe_info_s3_refill_resp g=%h i=%h", $time, g_io_mainpipe_info_s3_refill_resp, i_io_mainpipe_info_s3_refill_resp); end
    if (!$isunknown(g_io_wb_valid) && g_io_wb_valid !== i_io_wb_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_valid g=%h i=%h", $time, g_io_wb_valid, i_io_wb_valid); end
    if (!$isunknown(g_io_wb_bits_param) && g_io_wb_bits_param !== i_io_wb_bits_param) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_param g=%h i=%h", $time, g_io_wb_bits_param, i_io_wb_bits_param); end
    if (!$isunknown(g_io_wb_bits_voluntary) && g_io_wb_bits_voluntary !== i_io_wb_bits_voluntary) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_voluntary g=%h i=%h", $time, g_io_wb_bits_voluntary, i_io_wb_bits_voluntary); end
    if (!$isunknown(g_io_wb_bits_hasData) && g_io_wb_bits_hasData !== i_io_wb_bits_hasData) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_hasData g=%h i=%h", $time, g_io_wb_bits_hasData, i_io_wb_bits_hasData); end
    if (!$isunknown(g_io_wb_bits_corrupt) && g_io_wb_bits_corrupt !== i_io_wb_bits_corrupt) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_corrupt g=%h i=%h", $time, g_io_wb_bits_corrupt, i_io_wb_bits_corrupt); end
    if (!$isunknown(g_io_wb_bits_dirty) && g_io_wb_bits_dirty !== i_io_wb_bits_dirty) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_dirty g=%h i=%h", $time, g_io_wb_bits_dirty, i_io_wb_bits_dirty); end
    if (!$isunknown(g_io_wb_bits_addr) && g_io_wb_bits_addr !== i_io_wb_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_addr g=%h i=%h", $time, g_io_wb_bits_addr, i_io_wb_bits_addr); end
    if (!$isunknown(g_io_wb_bits_data) && g_io_wb_bits_data !== i_io_wb_bits_data) begin errors++;
      if(errors<=60) $display("[%0t] io_wb_bits_data g=%h i=%h", $time, g_io_wb_bits_data, i_io_wb_bits_data); end
    if (!$isunknown(g_io_data_read_intend) && g_io_data_read_intend !== i_io_data_read_intend) begin errors++;
      if(errors<=60) $display("[%0t] io_data_read_intend g=%h i=%h", $time, g_io_data_read_intend, i_io_data_read_intend); end
    if (!$isunknown(g_io_data_readline_valid) && g_io_data_readline_valid !== i_io_data_readline_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_valid g=%h i=%h", $time, g_io_data_readline_valid, i_io_data_readline_valid); end
    if (!$isunknown(g_io_data_readline_bits_way_en) && g_io_data_readline_bits_way_en !== i_io_data_readline_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_bits_way_en g=%h i=%h", $time, g_io_data_readline_bits_way_en, i_io_data_readline_bits_way_en); end
    if (!$isunknown(g_io_data_readline_bits_addr) && g_io_data_readline_bits_addr !== i_io_data_readline_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_bits_addr g=%h i=%h", $time, g_io_data_readline_bits_addr, i_io_data_readline_bits_addr); end
    if (!$isunknown(g_io_data_readline_bits_rmask) && g_io_data_readline_bits_rmask !== i_io_data_readline_bits_rmask) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_bits_rmask g=%h i=%h", $time, g_io_data_readline_bits_rmask, i_io_data_readline_bits_rmask); end
    if (!$isunknown(g_io_data_readline_can_go) && g_io_data_readline_can_go !== i_io_data_readline_can_go) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_can_go g=%h i=%h", $time, g_io_data_readline_can_go, i_io_data_readline_can_go); end
    if (!$isunknown(g_io_data_readline_stall) && g_io_data_readline_stall !== i_io_data_readline_stall) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_stall g=%h i=%h", $time, g_io_data_readline_stall, i_io_data_readline_stall); end
    if (!$isunknown(g_io_data_readline_can_resp) && g_io_data_readline_can_resp !== i_io_data_readline_can_resp) begin errors++;
      if(errors<=60) $display("[%0t] io_data_readline_can_resp g=%h i=%h", $time, g_io_data_readline_can_resp, i_io_data_readline_can_resp); end
    if (!$isunknown(g_io_data_write_valid) && g_io_data_write_valid !== i_io_data_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_valid g=%h i=%h", $time, g_io_data_write_valid, i_io_data_write_valid); end
    if (!$isunknown(g_io_data_write_bits_wmask) && g_io_data_write_bits_wmask !== i_io_data_write_bits_wmask) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_wmask g=%h i=%h", $time, g_io_data_write_bits_wmask, i_io_data_write_bits_wmask); end
    if (!$isunknown(g_io_data_write_bits_data_0) && g_io_data_write_bits_data_0 !== i_io_data_write_bits_data_0) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_0 g=%h i=%h", $time, g_io_data_write_bits_data_0, i_io_data_write_bits_data_0); end
    if (!$isunknown(g_io_data_write_bits_data_1) && g_io_data_write_bits_data_1 !== i_io_data_write_bits_data_1) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_1 g=%h i=%h", $time, g_io_data_write_bits_data_1, i_io_data_write_bits_data_1); end
    if (!$isunknown(g_io_data_write_bits_data_2) && g_io_data_write_bits_data_2 !== i_io_data_write_bits_data_2) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_2 g=%h i=%h", $time, g_io_data_write_bits_data_2, i_io_data_write_bits_data_2); end
    if (!$isunknown(g_io_data_write_bits_data_3) && g_io_data_write_bits_data_3 !== i_io_data_write_bits_data_3) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_3 g=%h i=%h", $time, g_io_data_write_bits_data_3, i_io_data_write_bits_data_3); end
    if (!$isunknown(g_io_data_write_bits_data_4) && g_io_data_write_bits_data_4 !== i_io_data_write_bits_data_4) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_4 g=%h i=%h", $time, g_io_data_write_bits_data_4, i_io_data_write_bits_data_4); end
    if (!$isunknown(g_io_data_write_bits_data_5) && g_io_data_write_bits_data_5 !== i_io_data_write_bits_data_5) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_5 g=%h i=%h", $time, g_io_data_write_bits_data_5, i_io_data_write_bits_data_5); end
    if (!$isunknown(g_io_data_write_bits_data_6) && g_io_data_write_bits_data_6 !== i_io_data_write_bits_data_6) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_6 g=%h i=%h", $time, g_io_data_write_bits_data_6, i_io_data_write_bits_data_6); end
    if (!$isunknown(g_io_data_write_bits_data_7) && g_io_data_write_bits_data_7 !== i_io_data_write_bits_data_7) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_bits_data_7 g=%h i=%h", $time, g_io_data_write_bits_data_7, i_io_data_write_bits_data_7); end
    if (!$isunknown(g_io_data_write_dup_0_valid) && g_io_data_write_dup_0_valid !== i_io_data_write_dup_0_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_0_valid g=%h i=%h", $time, g_io_data_write_dup_0_valid, i_io_data_write_dup_0_valid); end
    if (!$isunknown(g_io_data_write_dup_0_bits_way_en) && g_io_data_write_dup_0_bits_way_en !== i_io_data_write_dup_0_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_0_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_0_bits_way_en, i_io_data_write_dup_0_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_0_bits_addr) && g_io_data_write_dup_0_bits_addr !== i_io_data_write_dup_0_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_0_bits_addr g=%h i=%h", $time, g_io_data_write_dup_0_bits_addr, i_io_data_write_dup_0_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_1_valid) && g_io_data_write_dup_1_valid !== i_io_data_write_dup_1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_1_valid g=%h i=%h", $time, g_io_data_write_dup_1_valid, i_io_data_write_dup_1_valid); end
    if (!$isunknown(g_io_data_write_dup_1_bits_way_en) && g_io_data_write_dup_1_bits_way_en !== i_io_data_write_dup_1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_1_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_1_bits_way_en, i_io_data_write_dup_1_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_1_bits_addr) && g_io_data_write_dup_1_bits_addr !== i_io_data_write_dup_1_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_1_bits_addr g=%h i=%h", $time, g_io_data_write_dup_1_bits_addr, i_io_data_write_dup_1_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_2_valid) && g_io_data_write_dup_2_valid !== i_io_data_write_dup_2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_2_valid g=%h i=%h", $time, g_io_data_write_dup_2_valid, i_io_data_write_dup_2_valid); end
    if (!$isunknown(g_io_data_write_dup_2_bits_way_en) && g_io_data_write_dup_2_bits_way_en !== i_io_data_write_dup_2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_2_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_2_bits_way_en, i_io_data_write_dup_2_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_2_bits_addr) && g_io_data_write_dup_2_bits_addr !== i_io_data_write_dup_2_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_2_bits_addr g=%h i=%h", $time, g_io_data_write_dup_2_bits_addr, i_io_data_write_dup_2_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_3_valid) && g_io_data_write_dup_3_valid !== i_io_data_write_dup_3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_3_valid g=%h i=%h", $time, g_io_data_write_dup_3_valid, i_io_data_write_dup_3_valid); end
    if (!$isunknown(g_io_data_write_dup_3_bits_way_en) && g_io_data_write_dup_3_bits_way_en !== i_io_data_write_dup_3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_3_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_3_bits_way_en, i_io_data_write_dup_3_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_3_bits_addr) && g_io_data_write_dup_3_bits_addr !== i_io_data_write_dup_3_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_3_bits_addr g=%h i=%h", $time, g_io_data_write_dup_3_bits_addr, i_io_data_write_dup_3_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_4_valid) && g_io_data_write_dup_4_valid !== i_io_data_write_dup_4_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_4_valid g=%h i=%h", $time, g_io_data_write_dup_4_valid, i_io_data_write_dup_4_valid); end
    if (!$isunknown(g_io_data_write_dup_4_bits_way_en) && g_io_data_write_dup_4_bits_way_en !== i_io_data_write_dup_4_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_4_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_4_bits_way_en, i_io_data_write_dup_4_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_4_bits_addr) && g_io_data_write_dup_4_bits_addr !== i_io_data_write_dup_4_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_4_bits_addr g=%h i=%h", $time, g_io_data_write_dup_4_bits_addr, i_io_data_write_dup_4_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_5_valid) && g_io_data_write_dup_5_valid !== i_io_data_write_dup_5_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_5_valid g=%h i=%h", $time, g_io_data_write_dup_5_valid, i_io_data_write_dup_5_valid); end
    if (!$isunknown(g_io_data_write_dup_5_bits_way_en) && g_io_data_write_dup_5_bits_way_en !== i_io_data_write_dup_5_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_5_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_5_bits_way_en, i_io_data_write_dup_5_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_5_bits_addr) && g_io_data_write_dup_5_bits_addr !== i_io_data_write_dup_5_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_5_bits_addr g=%h i=%h", $time, g_io_data_write_dup_5_bits_addr, i_io_data_write_dup_5_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_6_valid) && g_io_data_write_dup_6_valid !== i_io_data_write_dup_6_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_6_valid g=%h i=%h", $time, g_io_data_write_dup_6_valid, i_io_data_write_dup_6_valid); end
    if (!$isunknown(g_io_data_write_dup_6_bits_way_en) && g_io_data_write_dup_6_bits_way_en !== i_io_data_write_dup_6_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_6_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_6_bits_way_en, i_io_data_write_dup_6_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_6_bits_addr) && g_io_data_write_dup_6_bits_addr !== i_io_data_write_dup_6_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_6_bits_addr g=%h i=%h", $time, g_io_data_write_dup_6_bits_addr, i_io_data_write_dup_6_bits_addr); end
    if (!$isunknown(g_io_data_write_dup_7_valid) && g_io_data_write_dup_7_valid !== i_io_data_write_dup_7_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_7_valid g=%h i=%h", $time, g_io_data_write_dup_7_valid, i_io_data_write_dup_7_valid); end
    if (!$isunknown(g_io_data_write_dup_7_bits_way_en) && g_io_data_write_dup_7_bits_way_en !== i_io_data_write_dup_7_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_7_bits_way_en g=%h i=%h", $time, g_io_data_write_dup_7_bits_way_en, i_io_data_write_dup_7_bits_way_en); end
    if (!$isunknown(g_io_data_write_dup_7_bits_addr) && g_io_data_write_dup_7_bits_addr !== i_io_data_write_dup_7_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_data_write_dup_7_bits_addr g=%h i=%h", $time, g_io_data_write_dup_7_bits_addr, i_io_data_write_dup_7_bits_addr); end
    if (!$isunknown(g_io_meta_read_valid) && g_io_meta_read_valid !== i_io_meta_read_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_read_valid g=%h i=%h", $time, g_io_meta_read_valid, i_io_meta_read_valid); end
    if (!$isunknown(g_io_meta_read_bits_idx) && g_io_meta_read_bits_idx !== i_io_meta_read_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_read_bits_idx g=%h i=%h", $time, g_io_meta_read_bits_idx, i_io_meta_read_bits_idx); end
    if (!$isunknown(g_io_meta_write_valid) && g_io_meta_write_valid !== i_io_meta_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_write_valid g=%h i=%h", $time, g_io_meta_write_valid, i_io_meta_write_valid); end
    if (!$isunknown(g_io_meta_write_bits_idx) && g_io_meta_write_bits_idx !== i_io_meta_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_write_bits_idx g=%h i=%h", $time, g_io_meta_write_bits_idx, i_io_meta_write_bits_idx); end
    if (!$isunknown(g_io_meta_write_bits_way_en) && g_io_meta_write_bits_way_en !== i_io_meta_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_write_bits_way_en g=%h i=%h", $time, g_io_meta_write_bits_way_en, i_io_meta_write_bits_way_en); end
    if (!$isunknown(g_io_meta_write_bits_meta_coh_state) && g_io_meta_write_bits_meta_coh_state !== i_io_meta_write_bits_meta_coh_state) begin errors++;
      if(errors<=60) $display("[%0t] io_meta_write_bits_meta_coh_state g=%h i=%h", $time, g_io_meta_write_bits_meta_coh_state, i_io_meta_write_bits_meta_coh_state); end
    if (!$isunknown(g_io_error_flag_write_valid) && g_io_error_flag_write_valid !== i_io_error_flag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_error_flag_write_valid g=%h i=%h", $time, g_io_error_flag_write_valid, i_io_error_flag_write_valid); end
    if (!$isunknown(g_io_error_flag_write_bits_idx) && g_io_error_flag_write_bits_idx !== i_io_error_flag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_error_flag_write_bits_idx g=%h i=%h", $time, g_io_error_flag_write_bits_idx, i_io_error_flag_write_bits_idx); end
    if (!$isunknown(g_io_error_flag_write_bits_way_en) && g_io_error_flag_write_bits_way_en !== i_io_error_flag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_error_flag_write_bits_way_en g=%h i=%h", $time, g_io_error_flag_write_bits_way_en, i_io_error_flag_write_bits_way_en); end
    if (!$isunknown(g_io_error_flag_write_bits_flag) && g_io_error_flag_write_bits_flag !== i_io_error_flag_write_bits_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_error_flag_write_bits_flag g=%h i=%h", $time, g_io_error_flag_write_bits_flag, i_io_error_flag_write_bits_flag); end
    if (!$isunknown(g_io_prefetch_flag_write_valid) && g_io_prefetch_flag_write_valid !== i_io_prefetch_flag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_valid g=%h i=%h", $time, g_io_prefetch_flag_write_valid, i_io_prefetch_flag_write_valid); end
    if (!$isunknown(g_io_prefetch_flag_write_bits_idx) && g_io_prefetch_flag_write_bits_idx !== i_io_prefetch_flag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_bits_idx g=%h i=%h", $time, g_io_prefetch_flag_write_bits_idx, i_io_prefetch_flag_write_bits_idx); end
    if (!$isunknown(g_io_prefetch_flag_write_bits_way_en) && g_io_prefetch_flag_write_bits_way_en !== i_io_prefetch_flag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_bits_way_en g=%h i=%h", $time, g_io_prefetch_flag_write_bits_way_en, i_io_prefetch_flag_write_bits_way_en); end
    if (!$isunknown(g_io_prefetch_flag_write_bits_source) && g_io_prefetch_flag_write_bits_source !== i_io_prefetch_flag_write_bits_source) begin errors++;
      if(errors<=60) $display("[%0t] io_prefetch_flag_write_bits_source g=%h i=%h", $time, g_io_prefetch_flag_write_bits_source, i_io_prefetch_flag_write_bits_source); end
    if (!$isunknown(g_io_access_flag_write_valid) && g_io_access_flag_write_valid !== i_io_access_flag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_valid g=%h i=%h", $time, g_io_access_flag_write_valid, i_io_access_flag_write_valid); end
    if (!$isunknown(g_io_access_flag_write_bits_idx) && g_io_access_flag_write_bits_idx !== i_io_access_flag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_bits_idx g=%h i=%h", $time, g_io_access_flag_write_bits_idx, i_io_access_flag_write_bits_idx); end
    if (!$isunknown(g_io_access_flag_write_bits_way_en) && g_io_access_flag_write_bits_way_en !== i_io_access_flag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_bits_way_en g=%h i=%h", $time, g_io_access_flag_write_bits_way_en, i_io_access_flag_write_bits_way_en); end
    if (!$isunknown(g_io_access_flag_write_bits_flag) && g_io_access_flag_write_bits_flag !== i_io_access_flag_write_bits_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_access_flag_write_bits_flag g=%h i=%h", $time, g_io_access_flag_write_bits_flag, i_io_access_flag_write_bits_flag); end
    if (!$isunknown(g_io_tag_read_valid) && g_io_tag_read_valid !== i_io_tag_read_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_read_valid g=%h i=%h", $time, g_io_tag_read_valid, i_io_tag_read_valid); end
    if (!$isunknown(g_io_tag_read_bits_idx) && g_io_tag_read_bits_idx !== i_io_tag_read_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_read_bits_idx g=%h i=%h", $time, g_io_tag_read_bits_idx, i_io_tag_read_bits_idx); end
    if (!$isunknown(g_io_tag_write_valid) && g_io_tag_write_valid !== i_io_tag_write_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_write_valid g=%h i=%h", $time, g_io_tag_write_valid, i_io_tag_write_valid); end
    if (!$isunknown(g_io_tag_write_bits_idx) && g_io_tag_write_bits_idx !== i_io_tag_write_bits_idx) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_write_bits_idx g=%h i=%h", $time, g_io_tag_write_bits_idx, i_io_tag_write_bits_idx); end
    if (!$isunknown(g_io_tag_write_bits_way_en) && g_io_tag_write_bits_way_en !== i_io_tag_write_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_write_bits_way_en g=%h i=%h", $time, g_io_tag_write_bits_way_en, i_io_tag_write_bits_way_en); end
    if (!$isunknown(g_io_tag_write_bits_tag) && g_io_tag_write_bits_tag !== i_io_tag_write_bits_tag) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_write_bits_tag g=%h i=%h", $time, g_io_tag_write_bits_tag, i_io_tag_write_bits_tag); end
    if (!$isunknown(g_io_tag_write_intend) && g_io_tag_write_intend !== i_io_tag_write_intend) begin errors++;
      if(errors<=60) $display("[%0t] io_tag_write_intend g=%h i=%h", $time, g_io_tag_write_intend, i_io_tag_write_intend); end
    if (!$isunknown(g_io_replace_access_valid) && g_io_replace_access_valid !== i_io_replace_access_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_valid g=%h i=%h", $time, g_io_replace_access_valid, i_io_replace_access_valid); end
    if (!$isunknown(g_io_replace_access_bits_set) && g_io_replace_access_bits_set !== i_io_replace_access_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_bits_set g=%h i=%h", $time, g_io_replace_access_bits_set, i_io_replace_access_bits_set); end
    if (!$isunknown(g_io_replace_access_bits_way) && g_io_replace_access_bits_way !== i_io_replace_access_bits_way) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_access_bits_way g=%h i=%h", $time, g_io_replace_access_bits_way, i_io_replace_access_bits_way); end
    if (!$isunknown(g_io_replace_way_set_bits) && g_io_replace_way_set_bits !== i_io_replace_way_set_bits) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_way_set_bits g=%h i=%h", $time, g_io_replace_way_set_bits, i_io_replace_way_set_bits); end
    if (!$isunknown(g_io_evict_set) && g_io_evict_set !== i_io_evict_set) begin errors++;
      if(errors<=60) $display("[%0t] io_evict_set g=%h i=%h", $time, g_io_evict_set, i_io_evict_set); end
    if (!$isunknown(g_io_replace_req_bits_addr) && g_io_replace_req_bits_addr !== i_io_replace_req_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_req_bits_addr g=%h i=%h", $time, g_io_replace_req_bits_addr, i_io_replace_req_bits_addr); end
    if (!$isunknown(g_io_replace_req_bits_vaddr) && g_io_replace_req_bits_vaddr !== i_io_replace_req_bits_vaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_replace_req_bits_vaddr g=%h i=%h", $time, g_io_replace_req_bits_vaddr, i_io_replace_req_bits_vaddr); end
    if (!$isunknown(g_io_sms_agt_evict_req_valid) && g_io_sms_agt_evict_req_valid !== i_io_sms_agt_evict_req_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_sms_agt_evict_req_valid g=%h i=%h", $time, g_io_sms_agt_evict_req_valid, i_io_sms_agt_evict_req_valid); end
    if (!$isunknown(g_io_sms_agt_evict_req_bits_vaddr) && g_io_sms_agt_evict_req_bits_vaddr !== i_io_sms_agt_evict_req_bits_vaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_sms_agt_evict_req_bits_vaddr g=%h i=%h", $time, g_io_sms_agt_evict_req_bits_vaddr, i_io_sms_agt_evict_req_bits_vaddr); end
    if (!$isunknown(g_io_status_dup_0_s1_valid) && g_io_status_dup_0_s1_valid !== i_io_status_dup_0_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s1_valid g=%h i=%h", $time, g_io_status_dup_0_s1_valid, i_io_status_dup_0_s1_valid); end
    if (!$isunknown(g_io_status_dup_0_s1_bits_set) && g_io_status_dup_0_s1_bits_set !== i_io_status_dup_0_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s1_bits_set g=%h i=%h", $time, g_io_status_dup_0_s1_bits_set, i_io_status_dup_0_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_0_s1_bits_way_en) && g_io_status_dup_0_s1_bits_way_en !== i_io_status_dup_0_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_0_s1_bits_way_en, i_io_status_dup_0_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_0_s2_valid) && g_io_status_dup_0_s2_valid !== i_io_status_dup_0_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s2_valid g=%h i=%h", $time, g_io_status_dup_0_s2_valid, i_io_status_dup_0_s2_valid); end
    if (!$isunknown(g_io_status_dup_0_s2_bits_set) && g_io_status_dup_0_s2_bits_set !== i_io_status_dup_0_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s2_bits_set g=%h i=%h", $time, g_io_status_dup_0_s2_bits_set, i_io_status_dup_0_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_0_s2_bits_way_en) && g_io_status_dup_0_s2_bits_way_en !== i_io_status_dup_0_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_0_s2_bits_way_en, i_io_status_dup_0_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_0_s3_valid) && g_io_status_dup_0_s3_valid !== i_io_status_dup_0_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s3_valid g=%h i=%h", $time, g_io_status_dup_0_s3_valid, i_io_status_dup_0_s3_valid); end
    if (!$isunknown(g_io_status_dup_0_s3_bits_set) && g_io_status_dup_0_s3_bits_set !== i_io_status_dup_0_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s3_bits_set g=%h i=%h", $time, g_io_status_dup_0_s3_bits_set, i_io_status_dup_0_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_0_s3_bits_way_en) && g_io_status_dup_0_s3_bits_way_en !== i_io_status_dup_0_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_0_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_0_s3_bits_way_en, i_io_status_dup_0_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_1_s1_valid) && g_io_status_dup_1_s1_valid !== i_io_status_dup_1_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s1_valid g=%h i=%h", $time, g_io_status_dup_1_s1_valid, i_io_status_dup_1_s1_valid); end
    if (!$isunknown(g_io_status_dup_1_s1_bits_set) && g_io_status_dup_1_s1_bits_set !== i_io_status_dup_1_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s1_bits_set g=%h i=%h", $time, g_io_status_dup_1_s1_bits_set, i_io_status_dup_1_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_1_s1_bits_way_en) && g_io_status_dup_1_s1_bits_way_en !== i_io_status_dup_1_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_1_s1_bits_way_en, i_io_status_dup_1_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_1_s2_valid) && g_io_status_dup_1_s2_valid !== i_io_status_dup_1_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s2_valid g=%h i=%h", $time, g_io_status_dup_1_s2_valid, i_io_status_dup_1_s2_valid); end
    if (!$isunknown(g_io_status_dup_1_s2_bits_set) && g_io_status_dup_1_s2_bits_set !== i_io_status_dup_1_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s2_bits_set g=%h i=%h", $time, g_io_status_dup_1_s2_bits_set, i_io_status_dup_1_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_1_s2_bits_way_en) && g_io_status_dup_1_s2_bits_way_en !== i_io_status_dup_1_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_1_s2_bits_way_en, i_io_status_dup_1_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_1_s3_valid) && g_io_status_dup_1_s3_valid !== i_io_status_dup_1_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s3_valid g=%h i=%h", $time, g_io_status_dup_1_s3_valid, i_io_status_dup_1_s3_valid); end
    if (!$isunknown(g_io_status_dup_1_s3_bits_set) && g_io_status_dup_1_s3_bits_set !== i_io_status_dup_1_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s3_bits_set g=%h i=%h", $time, g_io_status_dup_1_s3_bits_set, i_io_status_dup_1_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_1_s3_bits_way_en) && g_io_status_dup_1_s3_bits_way_en !== i_io_status_dup_1_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_1_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_1_s3_bits_way_en, i_io_status_dup_1_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_2_s1_valid) && g_io_status_dup_2_s1_valid !== i_io_status_dup_2_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s1_valid g=%h i=%h", $time, g_io_status_dup_2_s1_valid, i_io_status_dup_2_s1_valid); end
    if (!$isunknown(g_io_status_dup_2_s1_bits_set) && g_io_status_dup_2_s1_bits_set !== i_io_status_dup_2_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s1_bits_set g=%h i=%h", $time, g_io_status_dup_2_s1_bits_set, i_io_status_dup_2_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_2_s1_bits_way_en) && g_io_status_dup_2_s1_bits_way_en !== i_io_status_dup_2_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_2_s1_bits_way_en, i_io_status_dup_2_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_2_s2_valid) && g_io_status_dup_2_s2_valid !== i_io_status_dup_2_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s2_valid g=%h i=%h", $time, g_io_status_dup_2_s2_valid, i_io_status_dup_2_s2_valid); end
    if (!$isunknown(g_io_status_dup_2_s2_bits_set) && g_io_status_dup_2_s2_bits_set !== i_io_status_dup_2_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s2_bits_set g=%h i=%h", $time, g_io_status_dup_2_s2_bits_set, i_io_status_dup_2_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_2_s2_bits_way_en) && g_io_status_dup_2_s2_bits_way_en !== i_io_status_dup_2_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_2_s2_bits_way_en, i_io_status_dup_2_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_2_s3_valid) && g_io_status_dup_2_s3_valid !== i_io_status_dup_2_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s3_valid g=%h i=%h", $time, g_io_status_dup_2_s3_valid, i_io_status_dup_2_s3_valid); end
    if (!$isunknown(g_io_status_dup_2_s3_bits_set) && g_io_status_dup_2_s3_bits_set !== i_io_status_dup_2_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s3_bits_set g=%h i=%h", $time, g_io_status_dup_2_s3_bits_set, i_io_status_dup_2_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_2_s3_bits_way_en) && g_io_status_dup_2_s3_bits_way_en !== i_io_status_dup_2_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_2_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_2_s3_bits_way_en, i_io_status_dup_2_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_3_s1_valid) && g_io_status_dup_3_s1_valid !== i_io_status_dup_3_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s1_valid g=%h i=%h", $time, g_io_status_dup_3_s1_valid, i_io_status_dup_3_s1_valid); end
    if (!$isunknown(g_io_status_dup_3_s1_bits_set) && g_io_status_dup_3_s1_bits_set !== i_io_status_dup_3_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s1_bits_set g=%h i=%h", $time, g_io_status_dup_3_s1_bits_set, i_io_status_dup_3_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_3_s1_bits_way_en) && g_io_status_dup_3_s1_bits_way_en !== i_io_status_dup_3_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_3_s1_bits_way_en, i_io_status_dup_3_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_3_s2_valid) && g_io_status_dup_3_s2_valid !== i_io_status_dup_3_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s2_valid g=%h i=%h", $time, g_io_status_dup_3_s2_valid, i_io_status_dup_3_s2_valid); end
    if (!$isunknown(g_io_status_dup_3_s2_bits_set) && g_io_status_dup_3_s2_bits_set !== i_io_status_dup_3_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s2_bits_set g=%h i=%h", $time, g_io_status_dup_3_s2_bits_set, i_io_status_dup_3_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_3_s2_bits_way_en) && g_io_status_dup_3_s2_bits_way_en !== i_io_status_dup_3_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_3_s2_bits_way_en, i_io_status_dup_3_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_3_s3_valid) && g_io_status_dup_3_s3_valid !== i_io_status_dup_3_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s3_valid g=%h i=%h", $time, g_io_status_dup_3_s3_valid, i_io_status_dup_3_s3_valid); end
    if (!$isunknown(g_io_status_dup_3_s3_bits_set) && g_io_status_dup_3_s3_bits_set !== i_io_status_dup_3_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s3_bits_set g=%h i=%h", $time, g_io_status_dup_3_s3_bits_set, i_io_status_dup_3_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_3_s3_bits_way_en) && g_io_status_dup_3_s3_bits_way_en !== i_io_status_dup_3_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_3_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_3_s3_bits_way_en, i_io_status_dup_3_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_4_s1_valid) && g_io_status_dup_4_s1_valid !== i_io_status_dup_4_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s1_valid g=%h i=%h", $time, g_io_status_dup_4_s1_valid, i_io_status_dup_4_s1_valid); end
    if (!$isunknown(g_io_status_dup_4_s1_bits_set) && g_io_status_dup_4_s1_bits_set !== i_io_status_dup_4_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s1_bits_set g=%h i=%h", $time, g_io_status_dup_4_s1_bits_set, i_io_status_dup_4_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_4_s1_bits_way_en) && g_io_status_dup_4_s1_bits_way_en !== i_io_status_dup_4_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_4_s1_bits_way_en, i_io_status_dup_4_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_4_s2_valid) && g_io_status_dup_4_s2_valid !== i_io_status_dup_4_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s2_valid g=%h i=%h", $time, g_io_status_dup_4_s2_valid, i_io_status_dup_4_s2_valid); end
    if (!$isunknown(g_io_status_dup_4_s2_bits_set) && g_io_status_dup_4_s2_bits_set !== i_io_status_dup_4_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s2_bits_set g=%h i=%h", $time, g_io_status_dup_4_s2_bits_set, i_io_status_dup_4_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_4_s2_bits_way_en) && g_io_status_dup_4_s2_bits_way_en !== i_io_status_dup_4_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_4_s2_bits_way_en, i_io_status_dup_4_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_4_s3_valid) && g_io_status_dup_4_s3_valid !== i_io_status_dup_4_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s3_valid g=%h i=%h", $time, g_io_status_dup_4_s3_valid, i_io_status_dup_4_s3_valid); end
    if (!$isunknown(g_io_status_dup_4_s3_bits_set) && g_io_status_dup_4_s3_bits_set !== i_io_status_dup_4_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s3_bits_set g=%h i=%h", $time, g_io_status_dup_4_s3_bits_set, i_io_status_dup_4_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_4_s3_bits_way_en) && g_io_status_dup_4_s3_bits_way_en !== i_io_status_dup_4_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_4_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_4_s3_bits_way_en, i_io_status_dup_4_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_5_s1_valid) && g_io_status_dup_5_s1_valid !== i_io_status_dup_5_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s1_valid g=%h i=%h", $time, g_io_status_dup_5_s1_valid, i_io_status_dup_5_s1_valid); end
    if (!$isunknown(g_io_status_dup_5_s1_bits_set) && g_io_status_dup_5_s1_bits_set !== i_io_status_dup_5_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s1_bits_set g=%h i=%h", $time, g_io_status_dup_5_s1_bits_set, i_io_status_dup_5_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_5_s1_bits_way_en) && g_io_status_dup_5_s1_bits_way_en !== i_io_status_dup_5_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_5_s1_bits_way_en, i_io_status_dup_5_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_5_s2_valid) && g_io_status_dup_5_s2_valid !== i_io_status_dup_5_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s2_valid g=%h i=%h", $time, g_io_status_dup_5_s2_valid, i_io_status_dup_5_s2_valid); end
    if (!$isunknown(g_io_status_dup_5_s2_bits_set) && g_io_status_dup_5_s2_bits_set !== i_io_status_dup_5_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s2_bits_set g=%h i=%h", $time, g_io_status_dup_5_s2_bits_set, i_io_status_dup_5_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_5_s2_bits_way_en) && g_io_status_dup_5_s2_bits_way_en !== i_io_status_dup_5_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_5_s2_bits_way_en, i_io_status_dup_5_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_5_s3_valid) && g_io_status_dup_5_s3_valid !== i_io_status_dup_5_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s3_valid g=%h i=%h", $time, g_io_status_dup_5_s3_valid, i_io_status_dup_5_s3_valid); end
    if (!$isunknown(g_io_status_dup_5_s3_bits_set) && g_io_status_dup_5_s3_bits_set !== i_io_status_dup_5_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s3_bits_set g=%h i=%h", $time, g_io_status_dup_5_s3_bits_set, i_io_status_dup_5_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_5_s3_bits_way_en) && g_io_status_dup_5_s3_bits_way_en !== i_io_status_dup_5_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_5_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_5_s3_bits_way_en, i_io_status_dup_5_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_6_s1_valid) && g_io_status_dup_6_s1_valid !== i_io_status_dup_6_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s1_valid g=%h i=%h", $time, g_io_status_dup_6_s1_valid, i_io_status_dup_6_s1_valid); end
    if (!$isunknown(g_io_status_dup_6_s1_bits_set) && g_io_status_dup_6_s1_bits_set !== i_io_status_dup_6_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s1_bits_set g=%h i=%h", $time, g_io_status_dup_6_s1_bits_set, i_io_status_dup_6_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_6_s1_bits_way_en) && g_io_status_dup_6_s1_bits_way_en !== i_io_status_dup_6_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_6_s1_bits_way_en, i_io_status_dup_6_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_6_s2_valid) && g_io_status_dup_6_s2_valid !== i_io_status_dup_6_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s2_valid g=%h i=%h", $time, g_io_status_dup_6_s2_valid, i_io_status_dup_6_s2_valid); end
    if (!$isunknown(g_io_status_dup_6_s2_bits_set) && g_io_status_dup_6_s2_bits_set !== i_io_status_dup_6_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s2_bits_set g=%h i=%h", $time, g_io_status_dup_6_s2_bits_set, i_io_status_dup_6_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_6_s2_bits_way_en) && g_io_status_dup_6_s2_bits_way_en !== i_io_status_dup_6_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_6_s2_bits_way_en, i_io_status_dup_6_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_6_s3_valid) && g_io_status_dup_6_s3_valid !== i_io_status_dup_6_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s3_valid g=%h i=%h", $time, g_io_status_dup_6_s3_valid, i_io_status_dup_6_s3_valid); end
    if (!$isunknown(g_io_status_dup_6_s3_bits_set) && g_io_status_dup_6_s3_bits_set !== i_io_status_dup_6_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s3_bits_set g=%h i=%h", $time, g_io_status_dup_6_s3_bits_set, i_io_status_dup_6_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_6_s3_bits_way_en) && g_io_status_dup_6_s3_bits_way_en !== i_io_status_dup_6_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_6_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_6_s3_bits_way_en, i_io_status_dup_6_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_7_s1_valid) && g_io_status_dup_7_s1_valid !== i_io_status_dup_7_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s1_valid g=%h i=%h", $time, g_io_status_dup_7_s1_valid, i_io_status_dup_7_s1_valid); end
    if (!$isunknown(g_io_status_dup_7_s1_bits_set) && g_io_status_dup_7_s1_bits_set !== i_io_status_dup_7_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s1_bits_set g=%h i=%h", $time, g_io_status_dup_7_s1_bits_set, i_io_status_dup_7_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_7_s1_bits_way_en) && g_io_status_dup_7_s1_bits_way_en !== i_io_status_dup_7_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_7_s1_bits_way_en, i_io_status_dup_7_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_7_s2_valid) && g_io_status_dup_7_s2_valid !== i_io_status_dup_7_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s2_valid g=%h i=%h", $time, g_io_status_dup_7_s2_valid, i_io_status_dup_7_s2_valid); end
    if (!$isunknown(g_io_status_dup_7_s2_bits_set) && g_io_status_dup_7_s2_bits_set !== i_io_status_dup_7_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s2_bits_set g=%h i=%h", $time, g_io_status_dup_7_s2_bits_set, i_io_status_dup_7_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_7_s2_bits_way_en) && g_io_status_dup_7_s2_bits_way_en !== i_io_status_dup_7_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_7_s2_bits_way_en, i_io_status_dup_7_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_7_s3_valid) && g_io_status_dup_7_s3_valid !== i_io_status_dup_7_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s3_valid g=%h i=%h", $time, g_io_status_dup_7_s3_valid, i_io_status_dup_7_s3_valid); end
    if (!$isunknown(g_io_status_dup_7_s3_bits_set) && g_io_status_dup_7_s3_bits_set !== i_io_status_dup_7_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s3_bits_set g=%h i=%h", $time, g_io_status_dup_7_s3_bits_set, i_io_status_dup_7_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_7_s3_bits_way_en) && g_io_status_dup_7_s3_bits_way_en !== i_io_status_dup_7_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_7_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_7_s3_bits_way_en, i_io_status_dup_7_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_8_s1_valid) && g_io_status_dup_8_s1_valid !== i_io_status_dup_8_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s1_valid g=%h i=%h", $time, g_io_status_dup_8_s1_valid, i_io_status_dup_8_s1_valid); end
    if (!$isunknown(g_io_status_dup_8_s1_bits_set) && g_io_status_dup_8_s1_bits_set !== i_io_status_dup_8_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s1_bits_set g=%h i=%h", $time, g_io_status_dup_8_s1_bits_set, i_io_status_dup_8_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_8_s1_bits_way_en) && g_io_status_dup_8_s1_bits_way_en !== i_io_status_dup_8_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_8_s1_bits_way_en, i_io_status_dup_8_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_8_s2_valid) && g_io_status_dup_8_s2_valid !== i_io_status_dup_8_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s2_valid g=%h i=%h", $time, g_io_status_dup_8_s2_valid, i_io_status_dup_8_s2_valid); end
    if (!$isunknown(g_io_status_dup_8_s2_bits_set) && g_io_status_dup_8_s2_bits_set !== i_io_status_dup_8_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s2_bits_set g=%h i=%h", $time, g_io_status_dup_8_s2_bits_set, i_io_status_dup_8_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_8_s2_bits_way_en) && g_io_status_dup_8_s2_bits_way_en !== i_io_status_dup_8_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_8_s2_bits_way_en, i_io_status_dup_8_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_8_s3_valid) && g_io_status_dup_8_s3_valid !== i_io_status_dup_8_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s3_valid g=%h i=%h", $time, g_io_status_dup_8_s3_valid, i_io_status_dup_8_s3_valid); end
    if (!$isunknown(g_io_status_dup_8_s3_bits_set) && g_io_status_dup_8_s3_bits_set !== i_io_status_dup_8_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s3_bits_set g=%h i=%h", $time, g_io_status_dup_8_s3_bits_set, i_io_status_dup_8_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_8_s3_bits_way_en) && g_io_status_dup_8_s3_bits_way_en !== i_io_status_dup_8_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_8_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_8_s3_bits_way_en, i_io_status_dup_8_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_9_s1_valid) && g_io_status_dup_9_s1_valid !== i_io_status_dup_9_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s1_valid g=%h i=%h", $time, g_io_status_dup_9_s1_valid, i_io_status_dup_9_s1_valid); end
    if (!$isunknown(g_io_status_dup_9_s1_bits_set) && g_io_status_dup_9_s1_bits_set !== i_io_status_dup_9_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s1_bits_set g=%h i=%h", $time, g_io_status_dup_9_s1_bits_set, i_io_status_dup_9_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_9_s1_bits_way_en) && g_io_status_dup_9_s1_bits_way_en !== i_io_status_dup_9_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_9_s1_bits_way_en, i_io_status_dup_9_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_9_s2_valid) && g_io_status_dup_9_s2_valid !== i_io_status_dup_9_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s2_valid g=%h i=%h", $time, g_io_status_dup_9_s2_valid, i_io_status_dup_9_s2_valid); end
    if (!$isunknown(g_io_status_dup_9_s2_bits_set) && g_io_status_dup_9_s2_bits_set !== i_io_status_dup_9_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s2_bits_set g=%h i=%h", $time, g_io_status_dup_9_s2_bits_set, i_io_status_dup_9_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_9_s2_bits_way_en) && g_io_status_dup_9_s2_bits_way_en !== i_io_status_dup_9_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_9_s2_bits_way_en, i_io_status_dup_9_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_9_s3_valid) && g_io_status_dup_9_s3_valid !== i_io_status_dup_9_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s3_valid g=%h i=%h", $time, g_io_status_dup_9_s3_valid, i_io_status_dup_9_s3_valid); end
    if (!$isunknown(g_io_status_dup_9_s3_bits_set) && g_io_status_dup_9_s3_bits_set !== i_io_status_dup_9_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s3_bits_set g=%h i=%h", $time, g_io_status_dup_9_s3_bits_set, i_io_status_dup_9_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_9_s3_bits_way_en) && g_io_status_dup_9_s3_bits_way_en !== i_io_status_dup_9_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_9_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_9_s3_bits_way_en, i_io_status_dup_9_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_10_s1_valid) && g_io_status_dup_10_s1_valid !== i_io_status_dup_10_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s1_valid g=%h i=%h", $time, g_io_status_dup_10_s1_valid, i_io_status_dup_10_s1_valid); end
    if (!$isunknown(g_io_status_dup_10_s1_bits_set) && g_io_status_dup_10_s1_bits_set !== i_io_status_dup_10_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s1_bits_set g=%h i=%h", $time, g_io_status_dup_10_s1_bits_set, i_io_status_dup_10_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_10_s1_bits_way_en) && g_io_status_dup_10_s1_bits_way_en !== i_io_status_dup_10_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_10_s1_bits_way_en, i_io_status_dup_10_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_10_s2_valid) && g_io_status_dup_10_s2_valid !== i_io_status_dup_10_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s2_valid g=%h i=%h", $time, g_io_status_dup_10_s2_valid, i_io_status_dup_10_s2_valid); end
    if (!$isunknown(g_io_status_dup_10_s2_bits_set) && g_io_status_dup_10_s2_bits_set !== i_io_status_dup_10_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s2_bits_set g=%h i=%h", $time, g_io_status_dup_10_s2_bits_set, i_io_status_dup_10_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_10_s2_bits_way_en) && g_io_status_dup_10_s2_bits_way_en !== i_io_status_dup_10_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_10_s2_bits_way_en, i_io_status_dup_10_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_10_s3_valid) && g_io_status_dup_10_s3_valid !== i_io_status_dup_10_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s3_valid g=%h i=%h", $time, g_io_status_dup_10_s3_valid, i_io_status_dup_10_s3_valid); end
    if (!$isunknown(g_io_status_dup_10_s3_bits_set) && g_io_status_dup_10_s3_bits_set !== i_io_status_dup_10_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s3_bits_set g=%h i=%h", $time, g_io_status_dup_10_s3_bits_set, i_io_status_dup_10_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_10_s3_bits_way_en) && g_io_status_dup_10_s3_bits_way_en !== i_io_status_dup_10_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_10_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_10_s3_bits_way_en, i_io_status_dup_10_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_11_s1_valid) && g_io_status_dup_11_s1_valid !== i_io_status_dup_11_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s1_valid g=%h i=%h", $time, g_io_status_dup_11_s1_valid, i_io_status_dup_11_s1_valid); end
    if (!$isunknown(g_io_status_dup_11_s1_bits_set) && g_io_status_dup_11_s1_bits_set !== i_io_status_dup_11_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s1_bits_set g=%h i=%h", $time, g_io_status_dup_11_s1_bits_set, i_io_status_dup_11_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_11_s1_bits_way_en) && g_io_status_dup_11_s1_bits_way_en !== i_io_status_dup_11_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_11_s1_bits_way_en, i_io_status_dup_11_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_11_s2_valid) && g_io_status_dup_11_s2_valid !== i_io_status_dup_11_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s2_valid g=%h i=%h", $time, g_io_status_dup_11_s2_valid, i_io_status_dup_11_s2_valid); end
    if (!$isunknown(g_io_status_dup_11_s2_bits_set) && g_io_status_dup_11_s2_bits_set !== i_io_status_dup_11_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s2_bits_set g=%h i=%h", $time, g_io_status_dup_11_s2_bits_set, i_io_status_dup_11_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_11_s2_bits_way_en) && g_io_status_dup_11_s2_bits_way_en !== i_io_status_dup_11_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_11_s2_bits_way_en, i_io_status_dup_11_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_11_s3_valid) && g_io_status_dup_11_s3_valid !== i_io_status_dup_11_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s3_valid g=%h i=%h", $time, g_io_status_dup_11_s3_valid, i_io_status_dup_11_s3_valid); end
    if (!$isunknown(g_io_status_dup_11_s3_bits_set) && g_io_status_dup_11_s3_bits_set !== i_io_status_dup_11_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s3_bits_set g=%h i=%h", $time, g_io_status_dup_11_s3_bits_set, i_io_status_dup_11_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_11_s3_bits_way_en) && g_io_status_dup_11_s3_bits_way_en !== i_io_status_dup_11_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_11_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_11_s3_bits_way_en, i_io_status_dup_11_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_12_s1_valid) && g_io_status_dup_12_s1_valid !== i_io_status_dup_12_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s1_valid g=%h i=%h", $time, g_io_status_dup_12_s1_valid, i_io_status_dup_12_s1_valid); end
    if (!$isunknown(g_io_status_dup_12_s1_bits_set) && g_io_status_dup_12_s1_bits_set !== i_io_status_dup_12_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s1_bits_set g=%h i=%h", $time, g_io_status_dup_12_s1_bits_set, i_io_status_dup_12_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_12_s1_bits_way_en) && g_io_status_dup_12_s1_bits_way_en !== i_io_status_dup_12_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_12_s1_bits_way_en, i_io_status_dup_12_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_12_s2_valid) && g_io_status_dup_12_s2_valid !== i_io_status_dup_12_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s2_valid g=%h i=%h", $time, g_io_status_dup_12_s2_valid, i_io_status_dup_12_s2_valid); end
    if (!$isunknown(g_io_status_dup_12_s2_bits_set) && g_io_status_dup_12_s2_bits_set !== i_io_status_dup_12_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s2_bits_set g=%h i=%h", $time, g_io_status_dup_12_s2_bits_set, i_io_status_dup_12_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_12_s2_bits_way_en) && g_io_status_dup_12_s2_bits_way_en !== i_io_status_dup_12_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_12_s2_bits_way_en, i_io_status_dup_12_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_12_s3_valid) && g_io_status_dup_12_s3_valid !== i_io_status_dup_12_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s3_valid g=%h i=%h", $time, g_io_status_dup_12_s3_valid, i_io_status_dup_12_s3_valid); end
    if (!$isunknown(g_io_status_dup_12_s3_bits_set) && g_io_status_dup_12_s3_bits_set !== i_io_status_dup_12_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s3_bits_set g=%h i=%h", $time, g_io_status_dup_12_s3_bits_set, i_io_status_dup_12_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_12_s3_bits_way_en) && g_io_status_dup_12_s3_bits_way_en !== i_io_status_dup_12_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_12_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_12_s3_bits_way_en, i_io_status_dup_12_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_13_s1_valid) && g_io_status_dup_13_s1_valid !== i_io_status_dup_13_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s1_valid g=%h i=%h", $time, g_io_status_dup_13_s1_valid, i_io_status_dup_13_s1_valid); end
    if (!$isunknown(g_io_status_dup_13_s1_bits_set) && g_io_status_dup_13_s1_bits_set !== i_io_status_dup_13_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s1_bits_set g=%h i=%h", $time, g_io_status_dup_13_s1_bits_set, i_io_status_dup_13_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_13_s1_bits_way_en) && g_io_status_dup_13_s1_bits_way_en !== i_io_status_dup_13_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_13_s1_bits_way_en, i_io_status_dup_13_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_13_s2_valid) && g_io_status_dup_13_s2_valid !== i_io_status_dup_13_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s2_valid g=%h i=%h", $time, g_io_status_dup_13_s2_valid, i_io_status_dup_13_s2_valid); end
    if (!$isunknown(g_io_status_dup_13_s2_bits_set) && g_io_status_dup_13_s2_bits_set !== i_io_status_dup_13_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s2_bits_set g=%h i=%h", $time, g_io_status_dup_13_s2_bits_set, i_io_status_dup_13_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_13_s2_bits_way_en) && g_io_status_dup_13_s2_bits_way_en !== i_io_status_dup_13_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_13_s2_bits_way_en, i_io_status_dup_13_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_13_s3_valid) && g_io_status_dup_13_s3_valid !== i_io_status_dup_13_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s3_valid g=%h i=%h", $time, g_io_status_dup_13_s3_valid, i_io_status_dup_13_s3_valid); end
    if (!$isunknown(g_io_status_dup_13_s3_bits_set) && g_io_status_dup_13_s3_bits_set !== i_io_status_dup_13_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s3_bits_set g=%h i=%h", $time, g_io_status_dup_13_s3_bits_set, i_io_status_dup_13_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_13_s3_bits_way_en) && g_io_status_dup_13_s3_bits_way_en !== i_io_status_dup_13_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_13_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_13_s3_bits_way_en, i_io_status_dup_13_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_14_s1_valid) && g_io_status_dup_14_s1_valid !== i_io_status_dup_14_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s1_valid g=%h i=%h", $time, g_io_status_dup_14_s1_valid, i_io_status_dup_14_s1_valid); end
    if (!$isunknown(g_io_status_dup_14_s1_bits_set) && g_io_status_dup_14_s1_bits_set !== i_io_status_dup_14_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s1_bits_set g=%h i=%h", $time, g_io_status_dup_14_s1_bits_set, i_io_status_dup_14_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_14_s1_bits_way_en) && g_io_status_dup_14_s1_bits_way_en !== i_io_status_dup_14_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_14_s1_bits_way_en, i_io_status_dup_14_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_14_s2_valid) && g_io_status_dup_14_s2_valid !== i_io_status_dup_14_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s2_valid g=%h i=%h", $time, g_io_status_dup_14_s2_valid, i_io_status_dup_14_s2_valid); end
    if (!$isunknown(g_io_status_dup_14_s2_bits_set) && g_io_status_dup_14_s2_bits_set !== i_io_status_dup_14_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s2_bits_set g=%h i=%h", $time, g_io_status_dup_14_s2_bits_set, i_io_status_dup_14_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_14_s2_bits_way_en) && g_io_status_dup_14_s2_bits_way_en !== i_io_status_dup_14_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_14_s2_bits_way_en, i_io_status_dup_14_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_14_s3_valid) && g_io_status_dup_14_s3_valid !== i_io_status_dup_14_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s3_valid g=%h i=%h", $time, g_io_status_dup_14_s3_valid, i_io_status_dup_14_s3_valid); end
    if (!$isunknown(g_io_status_dup_14_s3_bits_set) && g_io_status_dup_14_s3_bits_set !== i_io_status_dup_14_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s3_bits_set g=%h i=%h", $time, g_io_status_dup_14_s3_bits_set, i_io_status_dup_14_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_14_s3_bits_way_en) && g_io_status_dup_14_s3_bits_way_en !== i_io_status_dup_14_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_14_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_14_s3_bits_way_en, i_io_status_dup_14_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_15_s1_valid) && g_io_status_dup_15_s1_valid !== i_io_status_dup_15_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s1_valid g=%h i=%h", $time, g_io_status_dup_15_s1_valid, i_io_status_dup_15_s1_valid); end
    if (!$isunknown(g_io_status_dup_15_s1_bits_set) && g_io_status_dup_15_s1_bits_set !== i_io_status_dup_15_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s1_bits_set g=%h i=%h", $time, g_io_status_dup_15_s1_bits_set, i_io_status_dup_15_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_15_s1_bits_way_en) && g_io_status_dup_15_s1_bits_way_en !== i_io_status_dup_15_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_15_s1_bits_way_en, i_io_status_dup_15_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_15_s2_valid) && g_io_status_dup_15_s2_valid !== i_io_status_dup_15_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s2_valid g=%h i=%h", $time, g_io_status_dup_15_s2_valid, i_io_status_dup_15_s2_valid); end
    if (!$isunknown(g_io_status_dup_15_s2_bits_set) && g_io_status_dup_15_s2_bits_set !== i_io_status_dup_15_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s2_bits_set g=%h i=%h", $time, g_io_status_dup_15_s2_bits_set, i_io_status_dup_15_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_15_s2_bits_way_en) && g_io_status_dup_15_s2_bits_way_en !== i_io_status_dup_15_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_15_s2_bits_way_en, i_io_status_dup_15_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_15_s3_valid) && g_io_status_dup_15_s3_valid !== i_io_status_dup_15_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s3_valid g=%h i=%h", $time, g_io_status_dup_15_s3_valid, i_io_status_dup_15_s3_valid); end
    if (!$isunknown(g_io_status_dup_15_s3_bits_set) && g_io_status_dup_15_s3_bits_set !== i_io_status_dup_15_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s3_bits_set g=%h i=%h", $time, g_io_status_dup_15_s3_bits_set, i_io_status_dup_15_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_15_s3_bits_way_en) && g_io_status_dup_15_s3_bits_way_en !== i_io_status_dup_15_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_15_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_15_s3_bits_way_en, i_io_status_dup_15_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_16_s1_valid) && g_io_status_dup_16_s1_valid !== i_io_status_dup_16_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s1_valid g=%h i=%h", $time, g_io_status_dup_16_s1_valid, i_io_status_dup_16_s1_valid); end
    if (!$isunknown(g_io_status_dup_16_s1_bits_set) && g_io_status_dup_16_s1_bits_set !== i_io_status_dup_16_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s1_bits_set g=%h i=%h", $time, g_io_status_dup_16_s1_bits_set, i_io_status_dup_16_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_16_s1_bits_way_en) && g_io_status_dup_16_s1_bits_way_en !== i_io_status_dup_16_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_16_s1_bits_way_en, i_io_status_dup_16_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_16_s2_valid) && g_io_status_dup_16_s2_valid !== i_io_status_dup_16_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s2_valid g=%h i=%h", $time, g_io_status_dup_16_s2_valid, i_io_status_dup_16_s2_valid); end
    if (!$isunknown(g_io_status_dup_16_s2_bits_set) && g_io_status_dup_16_s2_bits_set !== i_io_status_dup_16_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s2_bits_set g=%h i=%h", $time, g_io_status_dup_16_s2_bits_set, i_io_status_dup_16_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_16_s2_bits_way_en) && g_io_status_dup_16_s2_bits_way_en !== i_io_status_dup_16_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_16_s2_bits_way_en, i_io_status_dup_16_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_16_s3_valid) && g_io_status_dup_16_s3_valid !== i_io_status_dup_16_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s3_valid g=%h i=%h", $time, g_io_status_dup_16_s3_valid, i_io_status_dup_16_s3_valid); end
    if (!$isunknown(g_io_status_dup_16_s3_bits_set) && g_io_status_dup_16_s3_bits_set !== i_io_status_dup_16_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s3_bits_set g=%h i=%h", $time, g_io_status_dup_16_s3_bits_set, i_io_status_dup_16_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_16_s3_bits_way_en) && g_io_status_dup_16_s3_bits_way_en !== i_io_status_dup_16_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_16_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_16_s3_bits_way_en, i_io_status_dup_16_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_17_s1_valid) && g_io_status_dup_17_s1_valid !== i_io_status_dup_17_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s1_valid g=%h i=%h", $time, g_io_status_dup_17_s1_valid, i_io_status_dup_17_s1_valid); end
    if (!$isunknown(g_io_status_dup_17_s1_bits_set) && g_io_status_dup_17_s1_bits_set !== i_io_status_dup_17_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s1_bits_set g=%h i=%h", $time, g_io_status_dup_17_s1_bits_set, i_io_status_dup_17_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_17_s1_bits_way_en) && g_io_status_dup_17_s1_bits_way_en !== i_io_status_dup_17_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_17_s1_bits_way_en, i_io_status_dup_17_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_17_s2_valid) && g_io_status_dup_17_s2_valid !== i_io_status_dup_17_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s2_valid g=%h i=%h", $time, g_io_status_dup_17_s2_valid, i_io_status_dup_17_s2_valid); end
    if (!$isunknown(g_io_status_dup_17_s2_bits_set) && g_io_status_dup_17_s2_bits_set !== i_io_status_dup_17_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s2_bits_set g=%h i=%h", $time, g_io_status_dup_17_s2_bits_set, i_io_status_dup_17_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_17_s2_bits_way_en) && g_io_status_dup_17_s2_bits_way_en !== i_io_status_dup_17_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_17_s2_bits_way_en, i_io_status_dup_17_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_17_s3_valid) && g_io_status_dup_17_s3_valid !== i_io_status_dup_17_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s3_valid g=%h i=%h", $time, g_io_status_dup_17_s3_valid, i_io_status_dup_17_s3_valid); end
    if (!$isunknown(g_io_status_dup_17_s3_bits_set) && g_io_status_dup_17_s3_bits_set !== i_io_status_dup_17_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s3_bits_set g=%h i=%h", $time, g_io_status_dup_17_s3_bits_set, i_io_status_dup_17_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_17_s3_bits_way_en) && g_io_status_dup_17_s3_bits_way_en !== i_io_status_dup_17_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_17_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_17_s3_bits_way_en, i_io_status_dup_17_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_18_s1_valid) && g_io_status_dup_18_s1_valid !== i_io_status_dup_18_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s1_valid g=%h i=%h", $time, g_io_status_dup_18_s1_valid, i_io_status_dup_18_s1_valid); end
    if (!$isunknown(g_io_status_dup_18_s1_bits_set) && g_io_status_dup_18_s1_bits_set !== i_io_status_dup_18_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s1_bits_set g=%h i=%h", $time, g_io_status_dup_18_s1_bits_set, i_io_status_dup_18_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_18_s1_bits_way_en) && g_io_status_dup_18_s1_bits_way_en !== i_io_status_dup_18_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_18_s1_bits_way_en, i_io_status_dup_18_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_18_s2_valid) && g_io_status_dup_18_s2_valid !== i_io_status_dup_18_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s2_valid g=%h i=%h", $time, g_io_status_dup_18_s2_valid, i_io_status_dup_18_s2_valid); end
    if (!$isunknown(g_io_status_dup_18_s2_bits_set) && g_io_status_dup_18_s2_bits_set !== i_io_status_dup_18_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s2_bits_set g=%h i=%h", $time, g_io_status_dup_18_s2_bits_set, i_io_status_dup_18_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_18_s2_bits_way_en) && g_io_status_dup_18_s2_bits_way_en !== i_io_status_dup_18_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_18_s2_bits_way_en, i_io_status_dup_18_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_18_s3_valid) && g_io_status_dup_18_s3_valid !== i_io_status_dup_18_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s3_valid g=%h i=%h", $time, g_io_status_dup_18_s3_valid, i_io_status_dup_18_s3_valid); end
    if (!$isunknown(g_io_status_dup_18_s3_bits_set) && g_io_status_dup_18_s3_bits_set !== i_io_status_dup_18_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s3_bits_set g=%h i=%h", $time, g_io_status_dup_18_s3_bits_set, i_io_status_dup_18_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_18_s3_bits_way_en) && g_io_status_dup_18_s3_bits_way_en !== i_io_status_dup_18_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_18_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_18_s3_bits_way_en, i_io_status_dup_18_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_19_s1_valid) && g_io_status_dup_19_s1_valid !== i_io_status_dup_19_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s1_valid g=%h i=%h", $time, g_io_status_dup_19_s1_valid, i_io_status_dup_19_s1_valid); end
    if (!$isunknown(g_io_status_dup_19_s1_bits_set) && g_io_status_dup_19_s1_bits_set !== i_io_status_dup_19_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s1_bits_set g=%h i=%h", $time, g_io_status_dup_19_s1_bits_set, i_io_status_dup_19_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_19_s1_bits_way_en) && g_io_status_dup_19_s1_bits_way_en !== i_io_status_dup_19_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_19_s1_bits_way_en, i_io_status_dup_19_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_19_s2_valid) && g_io_status_dup_19_s2_valid !== i_io_status_dup_19_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s2_valid g=%h i=%h", $time, g_io_status_dup_19_s2_valid, i_io_status_dup_19_s2_valid); end
    if (!$isunknown(g_io_status_dup_19_s2_bits_set) && g_io_status_dup_19_s2_bits_set !== i_io_status_dup_19_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s2_bits_set g=%h i=%h", $time, g_io_status_dup_19_s2_bits_set, i_io_status_dup_19_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_19_s2_bits_way_en) && g_io_status_dup_19_s2_bits_way_en !== i_io_status_dup_19_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_19_s2_bits_way_en, i_io_status_dup_19_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_19_s3_valid) && g_io_status_dup_19_s3_valid !== i_io_status_dup_19_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s3_valid g=%h i=%h", $time, g_io_status_dup_19_s3_valid, i_io_status_dup_19_s3_valid); end
    if (!$isunknown(g_io_status_dup_19_s3_bits_set) && g_io_status_dup_19_s3_bits_set !== i_io_status_dup_19_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s3_bits_set g=%h i=%h", $time, g_io_status_dup_19_s3_bits_set, i_io_status_dup_19_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_19_s3_bits_way_en) && g_io_status_dup_19_s3_bits_way_en !== i_io_status_dup_19_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_19_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_19_s3_bits_way_en, i_io_status_dup_19_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_20_s1_valid) && g_io_status_dup_20_s1_valid !== i_io_status_dup_20_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s1_valid g=%h i=%h", $time, g_io_status_dup_20_s1_valid, i_io_status_dup_20_s1_valid); end
    if (!$isunknown(g_io_status_dup_20_s1_bits_set) && g_io_status_dup_20_s1_bits_set !== i_io_status_dup_20_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s1_bits_set g=%h i=%h", $time, g_io_status_dup_20_s1_bits_set, i_io_status_dup_20_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_20_s1_bits_way_en) && g_io_status_dup_20_s1_bits_way_en !== i_io_status_dup_20_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_20_s1_bits_way_en, i_io_status_dup_20_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_20_s2_valid) && g_io_status_dup_20_s2_valid !== i_io_status_dup_20_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s2_valid g=%h i=%h", $time, g_io_status_dup_20_s2_valid, i_io_status_dup_20_s2_valid); end
    if (!$isunknown(g_io_status_dup_20_s2_bits_set) && g_io_status_dup_20_s2_bits_set !== i_io_status_dup_20_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s2_bits_set g=%h i=%h", $time, g_io_status_dup_20_s2_bits_set, i_io_status_dup_20_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_20_s2_bits_way_en) && g_io_status_dup_20_s2_bits_way_en !== i_io_status_dup_20_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_20_s2_bits_way_en, i_io_status_dup_20_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_20_s3_valid) && g_io_status_dup_20_s3_valid !== i_io_status_dup_20_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s3_valid g=%h i=%h", $time, g_io_status_dup_20_s3_valid, i_io_status_dup_20_s3_valid); end
    if (!$isunknown(g_io_status_dup_20_s3_bits_set) && g_io_status_dup_20_s3_bits_set !== i_io_status_dup_20_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s3_bits_set g=%h i=%h", $time, g_io_status_dup_20_s3_bits_set, i_io_status_dup_20_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_20_s3_bits_way_en) && g_io_status_dup_20_s3_bits_way_en !== i_io_status_dup_20_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_20_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_20_s3_bits_way_en, i_io_status_dup_20_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_21_s1_valid) && g_io_status_dup_21_s1_valid !== i_io_status_dup_21_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s1_valid g=%h i=%h", $time, g_io_status_dup_21_s1_valid, i_io_status_dup_21_s1_valid); end
    if (!$isunknown(g_io_status_dup_21_s1_bits_set) && g_io_status_dup_21_s1_bits_set !== i_io_status_dup_21_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s1_bits_set g=%h i=%h", $time, g_io_status_dup_21_s1_bits_set, i_io_status_dup_21_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_21_s1_bits_way_en) && g_io_status_dup_21_s1_bits_way_en !== i_io_status_dup_21_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_21_s1_bits_way_en, i_io_status_dup_21_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_21_s2_valid) && g_io_status_dup_21_s2_valid !== i_io_status_dup_21_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s2_valid g=%h i=%h", $time, g_io_status_dup_21_s2_valid, i_io_status_dup_21_s2_valid); end
    if (!$isunknown(g_io_status_dup_21_s2_bits_set) && g_io_status_dup_21_s2_bits_set !== i_io_status_dup_21_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s2_bits_set g=%h i=%h", $time, g_io_status_dup_21_s2_bits_set, i_io_status_dup_21_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_21_s2_bits_way_en) && g_io_status_dup_21_s2_bits_way_en !== i_io_status_dup_21_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_21_s2_bits_way_en, i_io_status_dup_21_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_21_s3_valid) && g_io_status_dup_21_s3_valid !== i_io_status_dup_21_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s3_valid g=%h i=%h", $time, g_io_status_dup_21_s3_valid, i_io_status_dup_21_s3_valid); end
    if (!$isunknown(g_io_status_dup_21_s3_bits_set) && g_io_status_dup_21_s3_bits_set !== i_io_status_dup_21_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s3_bits_set g=%h i=%h", $time, g_io_status_dup_21_s3_bits_set, i_io_status_dup_21_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_21_s3_bits_way_en) && g_io_status_dup_21_s3_bits_way_en !== i_io_status_dup_21_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_21_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_21_s3_bits_way_en, i_io_status_dup_21_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_22_s1_valid) && g_io_status_dup_22_s1_valid !== i_io_status_dup_22_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s1_valid g=%h i=%h", $time, g_io_status_dup_22_s1_valid, i_io_status_dup_22_s1_valid); end
    if (!$isunknown(g_io_status_dup_22_s1_bits_set) && g_io_status_dup_22_s1_bits_set !== i_io_status_dup_22_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s1_bits_set g=%h i=%h", $time, g_io_status_dup_22_s1_bits_set, i_io_status_dup_22_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_22_s1_bits_way_en) && g_io_status_dup_22_s1_bits_way_en !== i_io_status_dup_22_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_22_s1_bits_way_en, i_io_status_dup_22_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_22_s2_valid) && g_io_status_dup_22_s2_valid !== i_io_status_dup_22_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s2_valid g=%h i=%h", $time, g_io_status_dup_22_s2_valid, i_io_status_dup_22_s2_valid); end
    if (!$isunknown(g_io_status_dup_22_s2_bits_set) && g_io_status_dup_22_s2_bits_set !== i_io_status_dup_22_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s2_bits_set g=%h i=%h", $time, g_io_status_dup_22_s2_bits_set, i_io_status_dup_22_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_22_s2_bits_way_en) && g_io_status_dup_22_s2_bits_way_en !== i_io_status_dup_22_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_22_s2_bits_way_en, i_io_status_dup_22_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_22_s3_valid) && g_io_status_dup_22_s3_valid !== i_io_status_dup_22_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s3_valid g=%h i=%h", $time, g_io_status_dup_22_s3_valid, i_io_status_dup_22_s3_valid); end
    if (!$isunknown(g_io_status_dup_22_s3_bits_set) && g_io_status_dup_22_s3_bits_set !== i_io_status_dup_22_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s3_bits_set g=%h i=%h", $time, g_io_status_dup_22_s3_bits_set, i_io_status_dup_22_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_22_s3_bits_way_en) && g_io_status_dup_22_s3_bits_way_en !== i_io_status_dup_22_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_22_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_22_s3_bits_way_en, i_io_status_dup_22_s3_bits_way_en); end
    if (!$isunknown(g_io_status_dup_23_s1_valid) && g_io_status_dup_23_s1_valid !== i_io_status_dup_23_s1_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s1_valid g=%h i=%h", $time, g_io_status_dup_23_s1_valid, i_io_status_dup_23_s1_valid); end
    if (!$isunknown(g_io_status_dup_23_s1_bits_set) && g_io_status_dup_23_s1_bits_set !== i_io_status_dup_23_s1_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s1_bits_set g=%h i=%h", $time, g_io_status_dup_23_s1_bits_set, i_io_status_dup_23_s1_bits_set); end
    if (!$isunknown(g_io_status_dup_23_s1_bits_way_en) && g_io_status_dup_23_s1_bits_way_en !== i_io_status_dup_23_s1_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s1_bits_way_en g=%h i=%h", $time, g_io_status_dup_23_s1_bits_way_en, i_io_status_dup_23_s1_bits_way_en); end
    if (!$isunknown(g_io_status_dup_23_s2_valid) && g_io_status_dup_23_s2_valid !== i_io_status_dup_23_s2_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s2_valid g=%h i=%h", $time, g_io_status_dup_23_s2_valid, i_io_status_dup_23_s2_valid); end
    if (!$isunknown(g_io_status_dup_23_s2_bits_set) && g_io_status_dup_23_s2_bits_set !== i_io_status_dup_23_s2_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s2_bits_set g=%h i=%h", $time, g_io_status_dup_23_s2_bits_set, i_io_status_dup_23_s2_bits_set); end
    if (!$isunknown(g_io_status_dup_23_s2_bits_way_en) && g_io_status_dup_23_s2_bits_way_en !== i_io_status_dup_23_s2_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s2_bits_way_en g=%h i=%h", $time, g_io_status_dup_23_s2_bits_way_en, i_io_status_dup_23_s2_bits_way_en); end
    if (!$isunknown(g_io_status_dup_23_s3_valid) && g_io_status_dup_23_s3_valid !== i_io_status_dup_23_s3_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s3_valid g=%h i=%h", $time, g_io_status_dup_23_s3_valid, i_io_status_dup_23_s3_valid); end
    if (!$isunknown(g_io_status_dup_23_s3_bits_set) && g_io_status_dup_23_s3_bits_set !== i_io_status_dup_23_s3_bits_set) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s3_bits_set g=%h i=%h", $time, g_io_status_dup_23_s3_bits_set, i_io_status_dup_23_s3_bits_set); end
    if (!$isunknown(g_io_status_dup_23_s3_bits_way_en) && g_io_status_dup_23_s3_bits_way_en !== i_io_status_dup_23_s3_bits_way_en) begin errors++;
      if(errors<=60) $display("[%0t] io_status_dup_23_s3_bits_way_en g=%h i=%h", $time, g_io_status_dup_23_s3_bits_way_en, i_io_status_dup_23_s3_bits_way_en); end
    if (!$isunknown(g_io_lrsc_locked_block_valid) && g_io_lrsc_locked_block_valid !== i_io_lrsc_locked_block_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_lrsc_locked_block_valid g=%h i=%h", $time, g_io_lrsc_locked_block_valid, i_io_lrsc_locked_block_valid); end
    if (!$isunknown(g_io_lrsc_locked_block_bits) && g_io_lrsc_locked_block_bits !== i_io_lrsc_locked_block_bits) begin errors++;
      if(errors<=60) $display("[%0t] io_lrsc_locked_block_bits g=%h i=%h", $time, g_io_lrsc_locked_block_bits, i_io_lrsc_locked_block_bits); end
    if (!$isunknown(g_io_update_resv_set) && g_io_update_resv_set !== i_io_update_resv_set) begin errors++;
      if(errors<=60) $display("[%0t] io_update_resv_set g=%h i=%h", $time, g_io_update_resv_set, i_io_update_resv_set); end
    if (!$isunknown(g_io_block_lr) && g_io_block_lr !== i_io_block_lr) begin errors++;
      if(errors<=60) $display("[%0t] io_block_lr g=%h i=%h", $time, g_io_block_lr, i_io_block_lr); end
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
    if (!$isunknown(g_io_bloom_filter_query_set_valid) && g_io_bloom_filter_query_set_valid !== i_io_bloom_filter_query_set_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_set_valid g=%h i=%h", $time, g_io_bloom_filter_query_set_valid, i_io_bloom_filter_query_set_valid); end
    if (!$isunknown(g_io_bloom_filter_query_set_bits_addr) && g_io_bloom_filter_query_set_bits_addr !== i_io_bloom_filter_query_set_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_set_bits_addr g=%h i=%h", $time, g_io_bloom_filter_query_set_bits_addr, i_io_bloom_filter_query_set_bits_addr); end
    if (!$isunknown(g_io_bloom_filter_query_clr_valid) && g_io_bloom_filter_query_clr_valid !== i_io_bloom_filter_query_clr_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_clr_valid g=%h i=%h", $time, g_io_bloom_filter_query_clr_valid, i_io_bloom_filter_query_clr_valid); end
    if (!$isunknown(g_io_bloom_filter_query_clr_bits_addr) && g_io_bloom_filter_query_clr_bits_addr !== i_io_bloom_filter_query_clr_bits_addr) begin errors++;
      if(errors<=60) $display("[%0t] io_bloom_filter_query_clr_bits_addr g=%h i=%h", $time, g_io_bloom_filter_query_clr_bits_addr, i_io_bloom_filter_query_clr_bits_addr); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
