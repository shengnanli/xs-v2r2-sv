// =====================================================================
// MainPipe UT —— golden MainPipe 与重写 MainPipe_xs 双例化，逐拍逐位比较全部 363 个输出端口
// ---------------------------------------------------------------------
// 端口声明 / 两个实例 / 比较 task 由 gen_mainpipe.py 生成（GENERATED 区）；激励为手写。
// 两侧例化的子模块（Arbiter4_MainPipeReq、AMOALU）都是本仓已签核的重写件（RTL_GOLDEN_DEPS），
// 所以本 UT 只比 MainPipe 本体。
//
// 激励模型（每拍在下降沿先比较、再换输入）：
//   * 四个请求源各有一个"挂起请求"：valid 保持到握手成功（偶尔中途撤销），成功后按概率
//     重新生成。地址取自小池子（4 个 set × 4 个 tag × 4 个块内行号），制造同 set 冲突、
//     命中、LR/SC 地址匹配。
//   * tag 阵列回应：4 路 tag 从同一个 tag 池里取（多数拍取一个排列 -> 请求 tag 在池里时
//     恰好命中一路），按 SECDED 正确编码，少量拍注入单比特/双比特错。
//   * meta 状态 Nothing/Branch/Trunk/Dirty 加权随机（产生权限不足 -> BtoT 升权 / miss）。
//   * 下游 ready（miss_req / wb / data_readline / tag_read）大多为 1、偶尔拉低；refill 数据
//     随机到达，制造 refill 等待 / 回 MissQueue 重来。
//
// 初值：两档 initreg（+0 / +random）。golden 与重写件都有不复位、且常态可见于输出的
//   寄存器（lrsc_addr、AMO 结果寄存器、s3 各字段…），+random 下两侧初值各摇各的。
//   所以复位后先跑一段确定性暖机（refill 一个 LR、一个 AMOADD，再跑一段随机流量），
//   让这些寄存器全部被写定，之后才打开比较窗口。
//
// 覆盖闸：见文末 COV 表，每一项都必须 >= COV_MIN，否则 TEST FAILED。
// =====================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN    = 100;
  localparam int WARMUP_RND = 400;     // 确定性暖机后的随机暖机拍数（不比较）

  bit   clock = 0;
  logic reset;
  always #5 clock = ~clock;

  int  errors = 0, checks = 0;
  bit  compare_en = 0;

  // BEGIN GENERATED(tb_ports)
  wire  g_io_probe_req_ready, i_io_probe_req_ready;
  logic io_probe_req_valid;
  logic [1:0] io_probe_req_bits_probe_param;
  logic io_probe_req_bits_probe_need_data;
  logic [49:0] io_probe_req_bits_vaddr;
  logic [47:0] io_probe_req_bits_addr;
  logic [5:0] io_probe_req_bits_id;
  logic io_miss_req_ready;
  wire  g_io_miss_req_valid, i_io_miss_req_valid;
  wire  [3:0] g_io_miss_req_bits_source, i_io_miss_req_bits_source;
  wire  [4:0] g_io_miss_req_bits_cmd, i_io_miss_req_bits_cmd;
  wire  [47:0] g_io_miss_req_bits_addr, i_io_miss_req_bits_addr;
  wire  [49:0] g_io_miss_req_bits_vaddr, i_io_miss_req_bits_vaddr;
  wire  g_io_miss_req_bits_full_overwrite, i_io_miss_req_bits_full_overwrite;
  wire  [2:0] g_io_miss_req_bits_word_idx, i_io_miss_req_bits_word_idx;
  wire  [127:0] g_io_miss_req_bits_amo_data, i_io_miss_req_bits_amo_data;
  wire  [15:0] g_io_miss_req_bits_amo_mask, i_io_miss_req_bits_amo_mask;
  wire  [127:0] g_io_miss_req_bits_amo_cmp, i_io_miss_req_bits_amo_cmp;
  wire  [1:0] g_io_miss_req_bits_req_coh_state, i_io_miss_req_bits_req_coh_state;
  wire  [5:0] g_io_miss_req_bits_id, i_io_miss_req_bits_id;
  wire  g_io_miss_req_bits_isBtoT, i_io_miss_req_bits_isBtoT;
  wire  [3:0] g_io_miss_req_bits_occupy_way, i_io_miss_req_bits_occupy_way;
  wire  g_io_miss_req_bits_cancel, i_io_miss_req_bits_cancel;
  wire  [511:0] g_io_miss_req_bits_store_data, i_io_miss_req_bits_store_data;
  wire  [63:0] g_io_miss_req_bits_store_mask, i_io_miss_req_bits_store_mask;
  wire  g_io_refill_req_ready, i_io_refill_req_ready;
  logic io_refill_req_valid;
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
  wire  g_io_wbq_conflict_check_valid, i_io_wbq_conflict_check_valid;
  wire  [47:0] g_io_wbq_conflict_check_bits, i_io_wbq_conflict_check_bits;
  logic io_wbq_block_miss_req;
  wire  g_io_store_req_ready, i_io_store_req_ready;
  logic io_store_req_valid;
  logic [49:0] io_store_req_bits_vaddr;
  logic [47:0] io_store_req_bits_addr;
  logic [511:0] io_store_req_bits_data;
  logic [63:0] io_store_req_bits_mask;
  logic [5:0] io_store_req_bits_id;
  wire  g_io_store_replay_resp_valid, i_io_store_replay_resp_valid;
  wire  [5:0] g_io_store_replay_resp_bits_id, i_io_store_replay_resp_bits_id;
  wire  g_io_store_hit_resp_valid, i_io_store_hit_resp_valid;
  wire  [5:0] g_io_store_hit_resp_bits_id, i_io_store_hit_resp_bits_id;
  wire  g_io_atomic_req_ready, i_io_atomic_req_ready;
  logic io_atomic_req_valid;
  logic [4:0] io_atomic_req_bits_cmd;
  logic [49:0] io_atomic_req_bits_vaddr;
  logic [47:0] io_atomic_req_bits_addr;
  logic [2:0] io_atomic_req_bits_word_idx;
  logic [127:0] io_atomic_req_bits_amo_data;
  logic [15:0] io_atomic_req_bits_amo_mask;
  logic [127:0] io_atomic_req_bits_amo_cmp;
  wire  g_io_atomic_resp_valid, i_io_atomic_resp_valid;
  wire  [3:0] g_io_atomic_resp_bits_source, i_io_atomic_resp_bits_source;
  wire  [127:0] g_io_atomic_resp_bits_data, i_io_atomic_resp_bits_data;
  wire  g_io_atomic_resp_bits_miss, i_io_atomic_resp_bits_miss;
  wire  [3:0] g_io_atomic_resp_bits_miss_id, i_io_atomic_resp_bits_miss_id;
  wire  g_io_atomic_resp_bits_replay, i_io_atomic_resp_bits_replay;
  wire  g_io_atomic_resp_bits_tl_error_tl_denied, i_io_atomic_resp_bits_tl_error_tl_denied;
  wire  g_io_atomic_resp_bits_tl_error_tl_corrupt, i_io_atomic_resp_bits_tl_error_tl_corrupt;
  wire  g_io_atomic_resp_bits_ack_miss_queue, i_io_atomic_resp_bits_ack_miss_queue;
  wire  [5:0] g_io_atomic_resp_bits_id, i_io_atomic_resp_bits_id;
  wire  g_io_mainpipe_info_s2_valid, i_io_mainpipe_info_s2_valid;
  wire  [3:0] g_io_mainpipe_info_s2_miss_id, i_io_mainpipe_info_s2_miss_id;
  wire  g_io_mainpipe_info_s2_replay_to_mq, i_io_mainpipe_info_s2_replay_to_mq;
  wire  g_io_mainpipe_info_s2_evict_BtoT_way, i_io_mainpipe_info_s2_evict_BtoT_way;
  wire  [3:0] g_io_mainpipe_info_s2_next_evict_way, i_io_mainpipe_info_s2_next_evict_way;
  wire  g_io_mainpipe_info_s3_valid, i_io_mainpipe_info_s3_valid;
  wire  [3:0] g_io_mainpipe_info_s3_miss_id, i_io_mainpipe_info_s3_miss_id;
  wire  g_io_mainpipe_info_s3_refill_resp, i_io_mainpipe_info_s3_refill_resp;
  logic io_refill_info_valid;
  logic [511:0] io_refill_info_bits_store_data;
  logic [63:0] io_refill_info_bits_store_mask;
  logic [1:0] io_refill_info_bits_miss_param;
  logic io_refill_info_bits_error_tl_denied;
  logic io_refill_info_bits_error_tl_corrupt;
  logic io_wb_ready;
  wire  g_io_wb_valid, i_io_wb_valid;
  wire  [2:0] g_io_wb_bits_param, i_io_wb_bits_param;
  wire  g_io_wb_bits_voluntary, i_io_wb_bits_voluntary;
  wire  g_io_wb_bits_hasData, i_io_wb_bits_hasData;
  wire  g_io_wb_bits_corrupt, i_io_wb_bits_corrupt;
  wire  g_io_wb_bits_dirty, i_io_wb_bits_dirty;
  wire  [47:0] g_io_wb_bits_addr, i_io_wb_bits_addr;
  wire  [511:0] g_io_wb_bits_data, i_io_wb_bits_data;
  wire  g_io_data_read_intend, i_io_data_read_intend;
  logic io_data_readline_ready;
  wire  g_io_data_readline_valid, i_io_data_readline_valid;
  wire  [3:0] g_io_data_readline_bits_way_en, i_io_data_readline_bits_way_en;
  wire  [47:0] g_io_data_readline_bits_addr, i_io_data_readline_bits_addr;
  wire  [7:0] g_io_data_readline_bits_rmask, i_io_data_readline_bits_rmask;
  wire  g_io_data_readline_can_go, i_io_data_readline_can_go;
  wire  g_io_data_readline_stall, i_io_data_readline_stall;
  wire  g_io_data_readline_can_resp, i_io_data_readline_can_resp;
  logic [63:0] io_data_resp_0_raw_data;
  logic [63:0] io_data_resp_1_raw_data;
  logic [63:0] io_data_resp_2_raw_data;
  logic [63:0] io_data_resp_3_raw_data;
  logic [63:0] io_data_resp_4_raw_data;
  logic [63:0] io_data_resp_5_raw_data;
  logic [63:0] io_data_resp_6_raw_data;
  logic [63:0] io_data_resp_7_raw_data;
  logic io_readline_error_delayed;
  wire  g_io_data_write_valid, i_io_data_write_valid;
  wire  [7:0] g_io_data_write_bits_wmask, i_io_data_write_bits_wmask;
  wire  [63:0] g_io_data_write_bits_data_0, i_io_data_write_bits_data_0;
  wire  [63:0] g_io_data_write_bits_data_1, i_io_data_write_bits_data_1;
  wire  [63:0] g_io_data_write_bits_data_2, i_io_data_write_bits_data_2;
  wire  [63:0] g_io_data_write_bits_data_3, i_io_data_write_bits_data_3;
  wire  [63:0] g_io_data_write_bits_data_4, i_io_data_write_bits_data_4;
  wire  [63:0] g_io_data_write_bits_data_5, i_io_data_write_bits_data_5;
  wire  [63:0] g_io_data_write_bits_data_6, i_io_data_write_bits_data_6;
  wire  [63:0] g_io_data_write_bits_data_7, i_io_data_write_bits_data_7;
  wire  g_io_data_write_dup_0_valid, i_io_data_write_dup_0_valid;
  wire  [3:0] g_io_data_write_dup_0_bits_way_en, i_io_data_write_dup_0_bits_way_en;
  wire  [47:0] g_io_data_write_dup_0_bits_addr, i_io_data_write_dup_0_bits_addr;
  wire  g_io_data_write_dup_1_valid, i_io_data_write_dup_1_valid;
  wire  [3:0] g_io_data_write_dup_1_bits_way_en, i_io_data_write_dup_1_bits_way_en;
  wire  [47:0] g_io_data_write_dup_1_bits_addr, i_io_data_write_dup_1_bits_addr;
  wire  g_io_data_write_dup_2_valid, i_io_data_write_dup_2_valid;
  wire  [3:0] g_io_data_write_dup_2_bits_way_en, i_io_data_write_dup_2_bits_way_en;
  wire  [47:0] g_io_data_write_dup_2_bits_addr, i_io_data_write_dup_2_bits_addr;
  wire  g_io_data_write_dup_3_valid, i_io_data_write_dup_3_valid;
  wire  [3:0] g_io_data_write_dup_3_bits_way_en, i_io_data_write_dup_3_bits_way_en;
  wire  [47:0] g_io_data_write_dup_3_bits_addr, i_io_data_write_dup_3_bits_addr;
  wire  g_io_data_write_dup_4_valid, i_io_data_write_dup_4_valid;
  wire  [3:0] g_io_data_write_dup_4_bits_way_en, i_io_data_write_dup_4_bits_way_en;
  wire  [47:0] g_io_data_write_dup_4_bits_addr, i_io_data_write_dup_4_bits_addr;
  wire  g_io_data_write_dup_5_valid, i_io_data_write_dup_5_valid;
  wire  [3:0] g_io_data_write_dup_5_bits_way_en, i_io_data_write_dup_5_bits_way_en;
  wire  [47:0] g_io_data_write_dup_5_bits_addr, i_io_data_write_dup_5_bits_addr;
  wire  g_io_data_write_dup_6_valid, i_io_data_write_dup_6_valid;
  wire  [3:0] g_io_data_write_dup_6_bits_way_en, i_io_data_write_dup_6_bits_way_en;
  wire  [47:0] g_io_data_write_dup_6_bits_addr, i_io_data_write_dup_6_bits_addr;
  wire  g_io_data_write_dup_7_valid, i_io_data_write_dup_7_valid;
  wire  [3:0] g_io_data_write_dup_7_bits_way_en, i_io_data_write_dup_7_bits_way_en;
  wire  [47:0] g_io_data_write_dup_7_bits_addr, i_io_data_write_dup_7_bits_addr;
  wire  g_io_meta_read_valid, i_io_meta_read_valid;
  wire  [7:0] g_io_meta_read_bits_idx, i_io_meta_read_bits_idx;
  logic [1:0] io_meta_resp_0_coh_state;
  logic [1:0] io_meta_resp_1_coh_state;
  logic [1:0] io_meta_resp_2_coh_state;
  logic [1:0] io_meta_resp_3_coh_state;
  wire  g_io_meta_write_valid, i_io_meta_write_valid;
  wire  [7:0] g_io_meta_write_bits_idx, i_io_meta_write_bits_idx;
  wire  [3:0] g_io_meta_write_bits_way_en, i_io_meta_write_bits_way_en;
  wire  [1:0] g_io_meta_write_bits_meta_coh_state, i_io_meta_write_bits_meta_coh_state;
  logic io_extra_meta_resp_0_error_tl_denied;
  logic io_extra_meta_resp_0_error_tl_corrupt;
  logic [2:0] io_extra_meta_resp_0_prefetch;
  logic io_extra_meta_resp_0_access;
  logic io_extra_meta_resp_1_error_tl_denied;
  logic io_extra_meta_resp_1_error_tl_corrupt;
  logic [2:0] io_extra_meta_resp_1_prefetch;
  logic io_extra_meta_resp_1_access;
  logic io_extra_meta_resp_2_error_tl_denied;
  logic io_extra_meta_resp_2_error_tl_corrupt;
  logic [2:0] io_extra_meta_resp_2_prefetch;
  logic io_extra_meta_resp_2_access;
  logic io_extra_meta_resp_3_error_tl_denied;
  logic io_extra_meta_resp_3_error_tl_corrupt;
  logic [2:0] io_extra_meta_resp_3_prefetch;
  logic io_extra_meta_resp_3_access;
  wire  g_io_error_flag_write_valid, i_io_error_flag_write_valid;
  wire  [7:0] g_io_error_flag_write_bits_idx, i_io_error_flag_write_bits_idx;
  wire  [3:0] g_io_error_flag_write_bits_way_en, i_io_error_flag_write_bits_way_en;
  wire  g_io_error_flag_write_bits_error_tl_denied, i_io_error_flag_write_bits_error_tl_denied;
  wire  g_io_error_flag_write_bits_error_tl_corrupt, i_io_error_flag_write_bits_error_tl_corrupt;
  wire  g_io_prefetch_flag_write_valid, i_io_prefetch_flag_write_valid;
  wire  [7:0] g_io_prefetch_flag_write_bits_idx, i_io_prefetch_flag_write_bits_idx;
  wire  [3:0] g_io_prefetch_flag_write_bits_way_en, i_io_prefetch_flag_write_bits_way_en;
  wire  [2:0] g_io_prefetch_flag_write_bits_source, i_io_prefetch_flag_write_bits_source;
  wire  g_io_access_flag_write_valid, i_io_access_flag_write_valid;
  wire  [7:0] g_io_access_flag_write_bits_idx, i_io_access_flag_write_bits_idx;
  wire  [3:0] g_io_access_flag_write_bits_way_en, i_io_access_flag_write_bits_way_en;
  wire  g_io_access_flag_write_bits_flag, i_io_access_flag_write_bits_flag;
  logic io_tag_read_ready;
  wire  g_io_tag_read_valid, i_io_tag_read_valid;
  wire  [7:0] g_io_tag_read_bits_idx, i_io_tag_read_bits_idx;
  logic [42:0] io_tag_resp_0;
  logic [42:0] io_tag_resp_1;
  logic [42:0] io_tag_resp_2;
  logic [42:0] io_tag_resp_3;
  wire  g_io_tag_write_valid, i_io_tag_write_valid;
  wire  [7:0] g_io_tag_write_bits_idx, i_io_tag_write_bits_idx;
  wire  [3:0] g_io_tag_write_bits_way_en, i_io_tag_write_bits_way_en;
  wire  [35:0] g_io_tag_write_bits_tag, i_io_tag_write_bits_tag;
  wire  g_io_tag_write_intend, i_io_tag_write_intend;
  wire  g_io_replace_access_valid, i_io_replace_access_valid;
  wire  [7:0] g_io_replace_access_bits_set, i_io_replace_access_bits_set;
  wire  [1:0] g_io_replace_access_bits_way, i_io_replace_access_bits_way;
  wire  [7:0] g_io_replace_way_set_bits, i_io_replace_way_set_bits;
  logic [1:0] io_replace_way_way;
  wire  [7:0] g_io_evict_set, i_io_evict_set;
  logic [3:0] io_btot_ways_for_set;
  wire  [47:0] g_io_replace_req_bits_addr, i_io_replace_req_bits_addr;
  wire  [49:0] g_io_replace_req_bits_vaddr, i_io_replace_req_bits_vaddr;
  logic io_replace_block;
  wire  g_io_sms_agt_evict_req_valid, i_io_sms_agt_evict_req_valid;
  wire  [49:0] g_io_sms_agt_evict_req_bits_vaddr, i_io_sms_agt_evict_req_bits_vaddr;
  wire  g_io_status_dup_0_s1_valid, i_io_status_dup_0_s1_valid;
  wire  [7:0] g_io_status_dup_0_s1_bits_set, i_io_status_dup_0_s1_bits_set;
  wire  [3:0] g_io_status_dup_0_s1_bits_way_en, i_io_status_dup_0_s1_bits_way_en;
  wire  g_io_status_dup_0_s2_valid, i_io_status_dup_0_s2_valid;
  wire  [7:0] g_io_status_dup_0_s2_bits_set, i_io_status_dup_0_s2_bits_set;
  wire  [3:0] g_io_status_dup_0_s2_bits_way_en, i_io_status_dup_0_s2_bits_way_en;
  wire  g_io_status_dup_0_s3_valid, i_io_status_dup_0_s3_valid;
  wire  [7:0] g_io_status_dup_0_s3_bits_set, i_io_status_dup_0_s3_bits_set;
  wire  [3:0] g_io_status_dup_0_s3_bits_way_en, i_io_status_dup_0_s3_bits_way_en;
  wire  g_io_status_dup_1_s1_valid, i_io_status_dup_1_s1_valid;
  wire  [7:0] g_io_status_dup_1_s1_bits_set, i_io_status_dup_1_s1_bits_set;
  wire  [3:0] g_io_status_dup_1_s1_bits_way_en, i_io_status_dup_1_s1_bits_way_en;
  wire  g_io_status_dup_1_s2_valid, i_io_status_dup_1_s2_valid;
  wire  [7:0] g_io_status_dup_1_s2_bits_set, i_io_status_dup_1_s2_bits_set;
  wire  [3:0] g_io_status_dup_1_s2_bits_way_en, i_io_status_dup_1_s2_bits_way_en;
  wire  g_io_status_dup_1_s3_valid, i_io_status_dup_1_s3_valid;
  wire  [7:0] g_io_status_dup_1_s3_bits_set, i_io_status_dup_1_s3_bits_set;
  wire  [3:0] g_io_status_dup_1_s3_bits_way_en, i_io_status_dup_1_s3_bits_way_en;
  wire  g_io_status_dup_2_s1_valid, i_io_status_dup_2_s1_valid;
  wire  [7:0] g_io_status_dup_2_s1_bits_set, i_io_status_dup_2_s1_bits_set;
  wire  [3:0] g_io_status_dup_2_s1_bits_way_en, i_io_status_dup_2_s1_bits_way_en;
  wire  g_io_status_dup_2_s2_valid, i_io_status_dup_2_s2_valid;
  wire  [7:0] g_io_status_dup_2_s2_bits_set, i_io_status_dup_2_s2_bits_set;
  wire  [3:0] g_io_status_dup_2_s2_bits_way_en, i_io_status_dup_2_s2_bits_way_en;
  wire  g_io_status_dup_2_s3_valid, i_io_status_dup_2_s3_valid;
  wire  [7:0] g_io_status_dup_2_s3_bits_set, i_io_status_dup_2_s3_bits_set;
  wire  [3:0] g_io_status_dup_2_s3_bits_way_en, i_io_status_dup_2_s3_bits_way_en;
  wire  g_io_status_dup_3_s1_valid, i_io_status_dup_3_s1_valid;
  wire  [7:0] g_io_status_dup_3_s1_bits_set, i_io_status_dup_3_s1_bits_set;
  wire  [3:0] g_io_status_dup_3_s1_bits_way_en, i_io_status_dup_3_s1_bits_way_en;
  wire  g_io_status_dup_3_s2_valid, i_io_status_dup_3_s2_valid;
  wire  [7:0] g_io_status_dup_3_s2_bits_set, i_io_status_dup_3_s2_bits_set;
  wire  [3:0] g_io_status_dup_3_s2_bits_way_en, i_io_status_dup_3_s2_bits_way_en;
  wire  g_io_status_dup_3_s3_valid, i_io_status_dup_3_s3_valid;
  wire  [7:0] g_io_status_dup_3_s3_bits_set, i_io_status_dup_3_s3_bits_set;
  wire  [3:0] g_io_status_dup_3_s3_bits_way_en, i_io_status_dup_3_s3_bits_way_en;
  wire  g_io_status_dup_4_s1_valid, i_io_status_dup_4_s1_valid;
  wire  [7:0] g_io_status_dup_4_s1_bits_set, i_io_status_dup_4_s1_bits_set;
  wire  [3:0] g_io_status_dup_4_s1_bits_way_en, i_io_status_dup_4_s1_bits_way_en;
  wire  g_io_status_dup_4_s2_valid, i_io_status_dup_4_s2_valid;
  wire  [7:0] g_io_status_dup_4_s2_bits_set, i_io_status_dup_4_s2_bits_set;
  wire  [3:0] g_io_status_dup_4_s2_bits_way_en, i_io_status_dup_4_s2_bits_way_en;
  wire  g_io_status_dup_4_s3_valid, i_io_status_dup_4_s3_valid;
  wire  [7:0] g_io_status_dup_4_s3_bits_set, i_io_status_dup_4_s3_bits_set;
  wire  [3:0] g_io_status_dup_4_s3_bits_way_en, i_io_status_dup_4_s3_bits_way_en;
  wire  g_io_status_dup_5_s1_valid, i_io_status_dup_5_s1_valid;
  wire  [7:0] g_io_status_dup_5_s1_bits_set, i_io_status_dup_5_s1_bits_set;
  wire  [3:0] g_io_status_dup_5_s1_bits_way_en, i_io_status_dup_5_s1_bits_way_en;
  wire  g_io_status_dup_5_s2_valid, i_io_status_dup_5_s2_valid;
  wire  [7:0] g_io_status_dup_5_s2_bits_set, i_io_status_dup_5_s2_bits_set;
  wire  [3:0] g_io_status_dup_5_s2_bits_way_en, i_io_status_dup_5_s2_bits_way_en;
  wire  g_io_status_dup_5_s3_valid, i_io_status_dup_5_s3_valid;
  wire  [7:0] g_io_status_dup_5_s3_bits_set, i_io_status_dup_5_s3_bits_set;
  wire  [3:0] g_io_status_dup_5_s3_bits_way_en, i_io_status_dup_5_s3_bits_way_en;
  wire  g_io_status_dup_6_s1_valid, i_io_status_dup_6_s1_valid;
  wire  [7:0] g_io_status_dup_6_s1_bits_set, i_io_status_dup_6_s1_bits_set;
  wire  [3:0] g_io_status_dup_6_s1_bits_way_en, i_io_status_dup_6_s1_bits_way_en;
  wire  g_io_status_dup_6_s2_valid, i_io_status_dup_6_s2_valid;
  wire  [7:0] g_io_status_dup_6_s2_bits_set, i_io_status_dup_6_s2_bits_set;
  wire  [3:0] g_io_status_dup_6_s2_bits_way_en, i_io_status_dup_6_s2_bits_way_en;
  wire  g_io_status_dup_6_s3_valid, i_io_status_dup_6_s3_valid;
  wire  [7:0] g_io_status_dup_6_s3_bits_set, i_io_status_dup_6_s3_bits_set;
  wire  [3:0] g_io_status_dup_6_s3_bits_way_en, i_io_status_dup_6_s3_bits_way_en;
  wire  g_io_status_dup_7_s1_valid, i_io_status_dup_7_s1_valid;
  wire  [7:0] g_io_status_dup_7_s1_bits_set, i_io_status_dup_7_s1_bits_set;
  wire  [3:0] g_io_status_dup_7_s1_bits_way_en, i_io_status_dup_7_s1_bits_way_en;
  wire  g_io_status_dup_7_s2_valid, i_io_status_dup_7_s2_valid;
  wire  [7:0] g_io_status_dup_7_s2_bits_set, i_io_status_dup_7_s2_bits_set;
  wire  [3:0] g_io_status_dup_7_s2_bits_way_en, i_io_status_dup_7_s2_bits_way_en;
  wire  g_io_status_dup_7_s3_valid, i_io_status_dup_7_s3_valid;
  wire  [7:0] g_io_status_dup_7_s3_bits_set, i_io_status_dup_7_s3_bits_set;
  wire  [3:0] g_io_status_dup_7_s3_bits_way_en, i_io_status_dup_7_s3_bits_way_en;
  wire  g_io_status_dup_8_s1_valid, i_io_status_dup_8_s1_valid;
  wire  [7:0] g_io_status_dup_8_s1_bits_set, i_io_status_dup_8_s1_bits_set;
  wire  [3:0] g_io_status_dup_8_s1_bits_way_en, i_io_status_dup_8_s1_bits_way_en;
  wire  g_io_status_dup_8_s2_valid, i_io_status_dup_8_s2_valid;
  wire  [7:0] g_io_status_dup_8_s2_bits_set, i_io_status_dup_8_s2_bits_set;
  wire  [3:0] g_io_status_dup_8_s2_bits_way_en, i_io_status_dup_8_s2_bits_way_en;
  wire  g_io_status_dup_8_s3_valid, i_io_status_dup_8_s3_valid;
  wire  [7:0] g_io_status_dup_8_s3_bits_set, i_io_status_dup_8_s3_bits_set;
  wire  [3:0] g_io_status_dup_8_s3_bits_way_en, i_io_status_dup_8_s3_bits_way_en;
  wire  g_io_status_dup_9_s1_valid, i_io_status_dup_9_s1_valid;
  wire  [7:0] g_io_status_dup_9_s1_bits_set, i_io_status_dup_9_s1_bits_set;
  wire  [3:0] g_io_status_dup_9_s1_bits_way_en, i_io_status_dup_9_s1_bits_way_en;
  wire  g_io_status_dup_9_s2_valid, i_io_status_dup_9_s2_valid;
  wire  [7:0] g_io_status_dup_9_s2_bits_set, i_io_status_dup_9_s2_bits_set;
  wire  [3:0] g_io_status_dup_9_s2_bits_way_en, i_io_status_dup_9_s2_bits_way_en;
  wire  g_io_status_dup_9_s3_valid, i_io_status_dup_9_s3_valid;
  wire  [7:0] g_io_status_dup_9_s3_bits_set, i_io_status_dup_9_s3_bits_set;
  wire  [3:0] g_io_status_dup_9_s3_bits_way_en, i_io_status_dup_9_s3_bits_way_en;
  wire  g_io_status_dup_10_s1_valid, i_io_status_dup_10_s1_valid;
  wire  [7:0] g_io_status_dup_10_s1_bits_set, i_io_status_dup_10_s1_bits_set;
  wire  [3:0] g_io_status_dup_10_s1_bits_way_en, i_io_status_dup_10_s1_bits_way_en;
  wire  g_io_status_dup_10_s2_valid, i_io_status_dup_10_s2_valid;
  wire  [7:0] g_io_status_dup_10_s2_bits_set, i_io_status_dup_10_s2_bits_set;
  wire  [3:0] g_io_status_dup_10_s2_bits_way_en, i_io_status_dup_10_s2_bits_way_en;
  wire  g_io_status_dup_10_s3_valid, i_io_status_dup_10_s3_valid;
  wire  [7:0] g_io_status_dup_10_s3_bits_set, i_io_status_dup_10_s3_bits_set;
  wire  [3:0] g_io_status_dup_10_s3_bits_way_en, i_io_status_dup_10_s3_bits_way_en;
  wire  g_io_status_dup_11_s1_valid, i_io_status_dup_11_s1_valid;
  wire  [7:0] g_io_status_dup_11_s1_bits_set, i_io_status_dup_11_s1_bits_set;
  wire  [3:0] g_io_status_dup_11_s1_bits_way_en, i_io_status_dup_11_s1_bits_way_en;
  wire  g_io_status_dup_11_s2_valid, i_io_status_dup_11_s2_valid;
  wire  [7:0] g_io_status_dup_11_s2_bits_set, i_io_status_dup_11_s2_bits_set;
  wire  [3:0] g_io_status_dup_11_s2_bits_way_en, i_io_status_dup_11_s2_bits_way_en;
  wire  g_io_status_dup_11_s3_valid, i_io_status_dup_11_s3_valid;
  wire  [7:0] g_io_status_dup_11_s3_bits_set, i_io_status_dup_11_s3_bits_set;
  wire  [3:0] g_io_status_dup_11_s3_bits_way_en, i_io_status_dup_11_s3_bits_way_en;
  wire  g_io_status_dup_12_s1_valid, i_io_status_dup_12_s1_valid;
  wire  [7:0] g_io_status_dup_12_s1_bits_set, i_io_status_dup_12_s1_bits_set;
  wire  [3:0] g_io_status_dup_12_s1_bits_way_en, i_io_status_dup_12_s1_bits_way_en;
  wire  g_io_status_dup_12_s2_valid, i_io_status_dup_12_s2_valid;
  wire  [7:0] g_io_status_dup_12_s2_bits_set, i_io_status_dup_12_s2_bits_set;
  wire  [3:0] g_io_status_dup_12_s2_bits_way_en, i_io_status_dup_12_s2_bits_way_en;
  wire  g_io_status_dup_12_s3_valid, i_io_status_dup_12_s3_valid;
  wire  [7:0] g_io_status_dup_12_s3_bits_set, i_io_status_dup_12_s3_bits_set;
  wire  [3:0] g_io_status_dup_12_s3_bits_way_en, i_io_status_dup_12_s3_bits_way_en;
  wire  g_io_status_dup_13_s1_valid, i_io_status_dup_13_s1_valid;
  wire  [7:0] g_io_status_dup_13_s1_bits_set, i_io_status_dup_13_s1_bits_set;
  wire  [3:0] g_io_status_dup_13_s1_bits_way_en, i_io_status_dup_13_s1_bits_way_en;
  wire  g_io_status_dup_13_s2_valid, i_io_status_dup_13_s2_valid;
  wire  [7:0] g_io_status_dup_13_s2_bits_set, i_io_status_dup_13_s2_bits_set;
  wire  [3:0] g_io_status_dup_13_s2_bits_way_en, i_io_status_dup_13_s2_bits_way_en;
  wire  g_io_status_dup_13_s3_valid, i_io_status_dup_13_s3_valid;
  wire  [7:0] g_io_status_dup_13_s3_bits_set, i_io_status_dup_13_s3_bits_set;
  wire  [3:0] g_io_status_dup_13_s3_bits_way_en, i_io_status_dup_13_s3_bits_way_en;
  wire  g_io_status_dup_14_s1_valid, i_io_status_dup_14_s1_valid;
  wire  [7:0] g_io_status_dup_14_s1_bits_set, i_io_status_dup_14_s1_bits_set;
  wire  [3:0] g_io_status_dup_14_s1_bits_way_en, i_io_status_dup_14_s1_bits_way_en;
  wire  g_io_status_dup_14_s2_valid, i_io_status_dup_14_s2_valid;
  wire  [7:0] g_io_status_dup_14_s2_bits_set, i_io_status_dup_14_s2_bits_set;
  wire  [3:0] g_io_status_dup_14_s2_bits_way_en, i_io_status_dup_14_s2_bits_way_en;
  wire  g_io_status_dup_14_s3_valid, i_io_status_dup_14_s3_valid;
  wire  [7:0] g_io_status_dup_14_s3_bits_set, i_io_status_dup_14_s3_bits_set;
  wire  [3:0] g_io_status_dup_14_s3_bits_way_en, i_io_status_dup_14_s3_bits_way_en;
  wire  g_io_status_dup_15_s1_valid, i_io_status_dup_15_s1_valid;
  wire  [7:0] g_io_status_dup_15_s1_bits_set, i_io_status_dup_15_s1_bits_set;
  wire  [3:0] g_io_status_dup_15_s1_bits_way_en, i_io_status_dup_15_s1_bits_way_en;
  wire  g_io_status_dup_15_s2_valid, i_io_status_dup_15_s2_valid;
  wire  [7:0] g_io_status_dup_15_s2_bits_set, i_io_status_dup_15_s2_bits_set;
  wire  [3:0] g_io_status_dup_15_s2_bits_way_en, i_io_status_dup_15_s2_bits_way_en;
  wire  g_io_status_dup_15_s3_valid, i_io_status_dup_15_s3_valid;
  wire  [7:0] g_io_status_dup_15_s3_bits_set, i_io_status_dup_15_s3_bits_set;
  wire  [3:0] g_io_status_dup_15_s3_bits_way_en, i_io_status_dup_15_s3_bits_way_en;
  wire  g_io_status_dup_16_s1_valid, i_io_status_dup_16_s1_valid;
  wire  [7:0] g_io_status_dup_16_s1_bits_set, i_io_status_dup_16_s1_bits_set;
  wire  [3:0] g_io_status_dup_16_s1_bits_way_en, i_io_status_dup_16_s1_bits_way_en;
  wire  g_io_status_dup_16_s2_valid, i_io_status_dup_16_s2_valid;
  wire  [7:0] g_io_status_dup_16_s2_bits_set, i_io_status_dup_16_s2_bits_set;
  wire  [3:0] g_io_status_dup_16_s2_bits_way_en, i_io_status_dup_16_s2_bits_way_en;
  wire  g_io_status_dup_16_s3_valid, i_io_status_dup_16_s3_valid;
  wire  [7:0] g_io_status_dup_16_s3_bits_set, i_io_status_dup_16_s3_bits_set;
  wire  [3:0] g_io_status_dup_16_s3_bits_way_en, i_io_status_dup_16_s3_bits_way_en;
  wire  g_io_status_dup_17_s1_valid, i_io_status_dup_17_s1_valid;
  wire  [7:0] g_io_status_dup_17_s1_bits_set, i_io_status_dup_17_s1_bits_set;
  wire  [3:0] g_io_status_dup_17_s1_bits_way_en, i_io_status_dup_17_s1_bits_way_en;
  wire  g_io_status_dup_17_s2_valid, i_io_status_dup_17_s2_valid;
  wire  [7:0] g_io_status_dup_17_s2_bits_set, i_io_status_dup_17_s2_bits_set;
  wire  [3:0] g_io_status_dup_17_s2_bits_way_en, i_io_status_dup_17_s2_bits_way_en;
  wire  g_io_status_dup_17_s3_valid, i_io_status_dup_17_s3_valid;
  wire  [7:0] g_io_status_dup_17_s3_bits_set, i_io_status_dup_17_s3_bits_set;
  wire  [3:0] g_io_status_dup_17_s3_bits_way_en, i_io_status_dup_17_s3_bits_way_en;
  wire  g_io_status_dup_18_s1_valid, i_io_status_dup_18_s1_valid;
  wire  [7:0] g_io_status_dup_18_s1_bits_set, i_io_status_dup_18_s1_bits_set;
  wire  [3:0] g_io_status_dup_18_s1_bits_way_en, i_io_status_dup_18_s1_bits_way_en;
  wire  g_io_status_dup_18_s2_valid, i_io_status_dup_18_s2_valid;
  wire  [7:0] g_io_status_dup_18_s2_bits_set, i_io_status_dup_18_s2_bits_set;
  wire  [3:0] g_io_status_dup_18_s2_bits_way_en, i_io_status_dup_18_s2_bits_way_en;
  wire  g_io_status_dup_18_s3_valid, i_io_status_dup_18_s3_valid;
  wire  [7:0] g_io_status_dup_18_s3_bits_set, i_io_status_dup_18_s3_bits_set;
  wire  [3:0] g_io_status_dup_18_s3_bits_way_en, i_io_status_dup_18_s3_bits_way_en;
  wire  g_io_status_dup_19_s1_valid, i_io_status_dup_19_s1_valid;
  wire  [7:0] g_io_status_dup_19_s1_bits_set, i_io_status_dup_19_s1_bits_set;
  wire  [3:0] g_io_status_dup_19_s1_bits_way_en, i_io_status_dup_19_s1_bits_way_en;
  wire  g_io_status_dup_19_s2_valid, i_io_status_dup_19_s2_valid;
  wire  [7:0] g_io_status_dup_19_s2_bits_set, i_io_status_dup_19_s2_bits_set;
  wire  [3:0] g_io_status_dup_19_s2_bits_way_en, i_io_status_dup_19_s2_bits_way_en;
  wire  g_io_status_dup_19_s3_valid, i_io_status_dup_19_s3_valid;
  wire  [7:0] g_io_status_dup_19_s3_bits_set, i_io_status_dup_19_s3_bits_set;
  wire  [3:0] g_io_status_dup_19_s3_bits_way_en, i_io_status_dup_19_s3_bits_way_en;
  wire  g_io_status_dup_20_s1_valid, i_io_status_dup_20_s1_valid;
  wire  [7:0] g_io_status_dup_20_s1_bits_set, i_io_status_dup_20_s1_bits_set;
  wire  [3:0] g_io_status_dup_20_s1_bits_way_en, i_io_status_dup_20_s1_bits_way_en;
  wire  g_io_status_dup_20_s2_valid, i_io_status_dup_20_s2_valid;
  wire  [7:0] g_io_status_dup_20_s2_bits_set, i_io_status_dup_20_s2_bits_set;
  wire  [3:0] g_io_status_dup_20_s2_bits_way_en, i_io_status_dup_20_s2_bits_way_en;
  wire  g_io_status_dup_20_s3_valid, i_io_status_dup_20_s3_valid;
  wire  [7:0] g_io_status_dup_20_s3_bits_set, i_io_status_dup_20_s3_bits_set;
  wire  [3:0] g_io_status_dup_20_s3_bits_way_en, i_io_status_dup_20_s3_bits_way_en;
  wire  g_io_status_dup_21_s1_valid, i_io_status_dup_21_s1_valid;
  wire  [7:0] g_io_status_dup_21_s1_bits_set, i_io_status_dup_21_s1_bits_set;
  wire  [3:0] g_io_status_dup_21_s1_bits_way_en, i_io_status_dup_21_s1_bits_way_en;
  wire  g_io_status_dup_21_s2_valid, i_io_status_dup_21_s2_valid;
  wire  [7:0] g_io_status_dup_21_s2_bits_set, i_io_status_dup_21_s2_bits_set;
  wire  [3:0] g_io_status_dup_21_s2_bits_way_en, i_io_status_dup_21_s2_bits_way_en;
  wire  g_io_status_dup_21_s3_valid, i_io_status_dup_21_s3_valid;
  wire  [7:0] g_io_status_dup_21_s3_bits_set, i_io_status_dup_21_s3_bits_set;
  wire  [3:0] g_io_status_dup_21_s3_bits_way_en, i_io_status_dup_21_s3_bits_way_en;
  wire  g_io_status_dup_22_s1_valid, i_io_status_dup_22_s1_valid;
  wire  [7:0] g_io_status_dup_22_s1_bits_set, i_io_status_dup_22_s1_bits_set;
  wire  [3:0] g_io_status_dup_22_s1_bits_way_en, i_io_status_dup_22_s1_bits_way_en;
  wire  g_io_status_dup_22_s2_valid, i_io_status_dup_22_s2_valid;
  wire  [7:0] g_io_status_dup_22_s2_bits_set, i_io_status_dup_22_s2_bits_set;
  wire  [3:0] g_io_status_dup_22_s2_bits_way_en, i_io_status_dup_22_s2_bits_way_en;
  wire  g_io_status_dup_22_s3_valid, i_io_status_dup_22_s3_valid;
  wire  [7:0] g_io_status_dup_22_s3_bits_set, i_io_status_dup_22_s3_bits_set;
  wire  [3:0] g_io_status_dup_22_s3_bits_way_en, i_io_status_dup_22_s3_bits_way_en;
  wire  g_io_status_dup_23_s1_valid, i_io_status_dup_23_s1_valid;
  wire  [7:0] g_io_status_dup_23_s1_bits_set, i_io_status_dup_23_s1_bits_set;
  wire  [3:0] g_io_status_dup_23_s1_bits_way_en, i_io_status_dup_23_s1_bits_way_en;
  wire  g_io_status_dup_23_s2_valid, i_io_status_dup_23_s2_valid;
  wire  [7:0] g_io_status_dup_23_s2_bits_set, i_io_status_dup_23_s2_bits_set;
  wire  [3:0] g_io_status_dup_23_s2_bits_way_en, i_io_status_dup_23_s2_bits_way_en;
  wire  g_io_status_dup_23_s3_valid, i_io_status_dup_23_s3_valid;
  wire  [7:0] g_io_status_dup_23_s3_bits_set, i_io_status_dup_23_s3_bits_set;
  wire  [3:0] g_io_status_dup_23_s3_bits_way_en, i_io_status_dup_23_s3_bits_way_en;
  wire  g_io_lrsc_locked_block_valid, i_io_lrsc_locked_block_valid;
  wire  [47:0] g_io_lrsc_locked_block_bits, i_io_lrsc_locked_block_bits;
  logic io_invalid_resv_set;
  wire  g_io_update_resv_set, i_io_update_resv_set;
  wire  g_io_block_lr, i_io_block_lr;
  wire  g_io_error_valid, i_io_error_valid;
  wire  [47:0] g_io_error_bits_paddr, i_io_error_bits_paddr;
  wire  g_io_error_bits_report_to_beu, i_io_error_bits_report_to_beu;
  logic io_pseudo_error_valid;
  logic io_pseudo_error_bits_0_valid;
  logic [63:0] io_pseudo_error_bits_0_mask;
  wire  g_io_pseudo_tag_error_inj_done, i_io_pseudo_tag_error_inj_done;
  wire  g_io_pseudo_data_error_inj_done, i_io_pseudo_data_error_inj_done;
  wire  g_io_bloom_filter_query_set_valid, i_io_bloom_filter_query_set_valid;
  wire  [11:0] g_io_bloom_filter_query_set_bits_addr, i_io_bloom_filter_query_set_bits_addr;
  wire  g_io_bloom_filter_query_clr_valid, i_io_bloom_filter_query_clr_valid;
  wire  [11:0] g_io_bloom_filter_query_clr_bits_addr, i_io_bloom_filter_query_clr_bits_addr;
  wire  [5:0] g_io_perf_0_value, i_io_perf_0_value;
  wire  [5:0] g_io_perf_1_value, i_io_perf_1_value;
  wire  [5:0] g_io_perf_2_value, i_io_perf_2_value;
  wire  [5:0] g_io_perf_3_value, i_io_perf_3_value;

  MainPipe u_gold (
    .clock(clock),
    .reset(reset),
    .io_probe_req_ready(g_io_probe_req_ready),
    .io_probe_req_valid(io_probe_req_valid),
    .io_probe_req_bits_probe_param(io_probe_req_bits_probe_param),
    .io_probe_req_bits_probe_need_data(io_probe_req_bits_probe_need_data),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_id(io_probe_req_bits_id),
    .io_miss_req_ready(io_miss_req_ready),
    .io_miss_req_valid(g_io_miss_req_valid),
    .io_miss_req_bits_source(g_io_miss_req_bits_source),
    .io_miss_req_bits_cmd(g_io_miss_req_bits_cmd),
    .io_miss_req_bits_addr(g_io_miss_req_bits_addr),
    .io_miss_req_bits_vaddr(g_io_miss_req_bits_vaddr),
    .io_miss_req_bits_full_overwrite(g_io_miss_req_bits_full_overwrite),
    .io_miss_req_bits_word_idx(g_io_miss_req_bits_word_idx),
    .io_miss_req_bits_amo_data(g_io_miss_req_bits_amo_data),
    .io_miss_req_bits_amo_mask(g_io_miss_req_bits_amo_mask),
    .io_miss_req_bits_amo_cmp(g_io_miss_req_bits_amo_cmp),
    .io_miss_req_bits_req_coh_state(g_io_miss_req_bits_req_coh_state),
    .io_miss_req_bits_id(g_io_miss_req_bits_id),
    .io_miss_req_bits_isBtoT(g_io_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way(g_io_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel(g_io_miss_req_bits_cancel),
    .io_miss_req_bits_store_data(g_io_miss_req_bits_store_data),
    .io_miss_req_bits_store_mask(g_io_miss_req_bits_store_mask),
    .io_refill_req_ready(g_io_refill_req_ready),
    .io_refill_req_valid(io_refill_req_valid),
    .io_refill_req_bits_miss_id(io_refill_req_bits_miss_id),
    .io_refill_req_bits_occupy_way(io_refill_req_bits_occupy_way),
    .io_refill_req_bits_miss_fail_cause_evict_btot(io_refill_req_bits_miss_fail_cause_evict_btot),
    .io_refill_req_bits_source(io_refill_req_bits_source),
    .io_refill_req_bits_cmd(io_refill_req_bits_cmd),
    .io_refill_req_bits_vaddr(io_refill_req_bits_vaddr),
    .io_refill_req_bits_addr(io_refill_req_bits_addr),
    .io_refill_req_bits_word_idx(io_refill_req_bits_word_idx),
    .io_refill_req_bits_amo_data(io_refill_req_bits_amo_data),
    .io_refill_req_bits_amo_mask(io_refill_req_bits_amo_mask),
    .io_refill_req_bits_amo_cmp(io_refill_req_bits_amo_cmp),
    .io_refill_req_bits_pf_source(io_refill_req_bits_pf_source),
    .io_refill_req_bits_access(io_refill_req_bits_access),
    .io_refill_req_bits_id(io_refill_req_bits_id),
    .io_wbq_conflict_check_valid(g_io_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits(g_io_wbq_conflict_check_bits),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_store_req_ready(g_io_store_req_ready),
    .io_store_req_valid(io_store_req_valid),
    .io_store_req_bits_vaddr(io_store_req_bits_vaddr),
    .io_store_req_bits_addr(io_store_req_bits_addr),
    .io_store_req_bits_data(io_store_req_bits_data),
    .io_store_req_bits_mask(io_store_req_bits_mask),
    .io_store_req_bits_id(io_store_req_bits_id),
    .io_store_replay_resp_valid(g_io_store_replay_resp_valid),
    .io_store_replay_resp_bits_id(g_io_store_replay_resp_bits_id),
    .io_store_hit_resp_valid(g_io_store_hit_resp_valid),
    .io_store_hit_resp_bits_id(g_io_store_hit_resp_bits_id),
    .io_atomic_req_ready(g_io_atomic_req_ready),
    .io_atomic_req_valid(io_atomic_req_valid),
    .io_atomic_req_bits_cmd(io_atomic_req_bits_cmd),
    .io_atomic_req_bits_vaddr(io_atomic_req_bits_vaddr),
    .io_atomic_req_bits_addr(io_atomic_req_bits_addr),
    .io_atomic_req_bits_word_idx(io_atomic_req_bits_word_idx),
    .io_atomic_req_bits_amo_data(io_atomic_req_bits_amo_data),
    .io_atomic_req_bits_amo_mask(io_atomic_req_bits_amo_mask),
    .io_atomic_req_bits_amo_cmp(io_atomic_req_bits_amo_cmp),
    .io_atomic_resp_valid(g_io_atomic_resp_valid),
    .io_atomic_resp_bits_source(g_io_atomic_resp_bits_source),
    .io_atomic_resp_bits_data(g_io_atomic_resp_bits_data),
    .io_atomic_resp_bits_miss(g_io_atomic_resp_bits_miss),
    .io_atomic_resp_bits_miss_id(g_io_atomic_resp_bits_miss_id),
    .io_atomic_resp_bits_replay(g_io_atomic_resp_bits_replay),
    .io_atomic_resp_bits_tl_error_tl_denied(g_io_atomic_resp_bits_tl_error_tl_denied),
    .io_atomic_resp_bits_tl_error_tl_corrupt(g_io_atomic_resp_bits_tl_error_tl_corrupt),
    .io_atomic_resp_bits_ack_miss_queue(g_io_atomic_resp_bits_ack_miss_queue),
    .io_atomic_resp_bits_id(g_io_atomic_resp_bits_id),
    .io_mainpipe_info_s2_valid(g_io_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id(g_io_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq(g_io_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way(g_io_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way(g_io_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid(g_io_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id(g_io_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp(g_io_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid(io_refill_info_valid),
    .io_refill_info_bits_store_data(io_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask(io_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param(io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(io_refill_info_bits_error_tl_corrupt),
    .io_wb_ready(io_wb_ready),
    .io_wb_valid(g_io_wb_valid),
    .io_wb_bits_param(g_io_wb_bits_param),
    .io_wb_bits_voluntary(g_io_wb_bits_voluntary),
    .io_wb_bits_hasData(g_io_wb_bits_hasData),
    .io_wb_bits_corrupt(g_io_wb_bits_corrupt),
    .io_wb_bits_dirty(g_io_wb_bits_dirty),
    .io_wb_bits_addr(g_io_wb_bits_addr),
    .io_wb_bits_data(g_io_wb_bits_data),
    .io_data_read_intend(g_io_data_read_intend),
    .io_data_readline_ready(io_data_readline_ready),
    .io_data_readline_valid(g_io_data_readline_valid),
    .io_data_readline_bits_way_en(g_io_data_readline_bits_way_en),
    .io_data_readline_bits_addr(g_io_data_readline_bits_addr),
    .io_data_readline_bits_rmask(g_io_data_readline_bits_rmask),
    .io_data_readline_can_go(g_io_data_readline_can_go),
    .io_data_readline_stall(g_io_data_readline_stall),
    .io_data_readline_can_resp(g_io_data_readline_can_resp),
    .io_data_resp_0_raw_data(io_data_resp_0_raw_data),
    .io_data_resp_1_raw_data(io_data_resp_1_raw_data),
    .io_data_resp_2_raw_data(io_data_resp_2_raw_data),
    .io_data_resp_3_raw_data(io_data_resp_3_raw_data),
    .io_data_resp_4_raw_data(io_data_resp_4_raw_data),
    .io_data_resp_5_raw_data(io_data_resp_5_raw_data),
    .io_data_resp_6_raw_data(io_data_resp_6_raw_data),
    .io_data_resp_7_raw_data(io_data_resp_7_raw_data),
    .io_readline_error_delayed(io_readline_error_delayed),
    .io_data_write_valid(g_io_data_write_valid),
    .io_data_write_bits_wmask(g_io_data_write_bits_wmask),
    .io_data_write_bits_data_0(g_io_data_write_bits_data_0),
    .io_data_write_bits_data_1(g_io_data_write_bits_data_1),
    .io_data_write_bits_data_2(g_io_data_write_bits_data_2),
    .io_data_write_bits_data_3(g_io_data_write_bits_data_3),
    .io_data_write_bits_data_4(g_io_data_write_bits_data_4),
    .io_data_write_bits_data_5(g_io_data_write_bits_data_5),
    .io_data_write_bits_data_6(g_io_data_write_bits_data_6),
    .io_data_write_bits_data_7(g_io_data_write_bits_data_7),
    .io_data_write_dup_0_valid(g_io_data_write_dup_0_valid),
    .io_data_write_dup_0_bits_way_en(g_io_data_write_dup_0_bits_way_en),
    .io_data_write_dup_0_bits_addr(g_io_data_write_dup_0_bits_addr),
    .io_data_write_dup_1_valid(g_io_data_write_dup_1_valid),
    .io_data_write_dup_1_bits_way_en(g_io_data_write_dup_1_bits_way_en),
    .io_data_write_dup_1_bits_addr(g_io_data_write_dup_1_bits_addr),
    .io_data_write_dup_2_valid(g_io_data_write_dup_2_valid),
    .io_data_write_dup_2_bits_way_en(g_io_data_write_dup_2_bits_way_en),
    .io_data_write_dup_2_bits_addr(g_io_data_write_dup_2_bits_addr),
    .io_data_write_dup_3_valid(g_io_data_write_dup_3_valid),
    .io_data_write_dup_3_bits_way_en(g_io_data_write_dup_3_bits_way_en),
    .io_data_write_dup_3_bits_addr(g_io_data_write_dup_3_bits_addr),
    .io_data_write_dup_4_valid(g_io_data_write_dup_4_valid),
    .io_data_write_dup_4_bits_way_en(g_io_data_write_dup_4_bits_way_en),
    .io_data_write_dup_4_bits_addr(g_io_data_write_dup_4_bits_addr),
    .io_data_write_dup_5_valid(g_io_data_write_dup_5_valid),
    .io_data_write_dup_5_bits_way_en(g_io_data_write_dup_5_bits_way_en),
    .io_data_write_dup_5_bits_addr(g_io_data_write_dup_5_bits_addr),
    .io_data_write_dup_6_valid(g_io_data_write_dup_6_valid),
    .io_data_write_dup_6_bits_way_en(g_io_data_write_dup_6_bits_way_en),
    .io_data_write_dup_6_bits_addr(g_io_data_write_dup_6_bits_addr),
    .io_data_write_dup_7_valid(g_io_data_write_dup_7_valid),
    .io_data_write_dup_7_bits_way_en(g_io_data_write_dup_7_bits_way_en),
    .io_data_write_dup_7_bits_addr(g_io_data_write_dup_7_bits_addr),
    .io_meta_read_valid(g_io_meta_read_valid),
    .io_meta_read_bits_idx(g_io_meta_read_bits_idx),
    .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state),
    .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state),
    .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state),
    .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state),
    .io_meta_write_valid(g_io_meta_write_valid),
    .io_meta_write_bits_idx(g_io_meta_write_bits_idx),
    .io_meta_write_bits_way_en(g_io_meta_write_bits_way_en),
    .io_meta_write_bits_meta_coh_state(g_io_meta_write_bits_meta_coh_state),
    .io_extra_meta_resp_0_error_tl_denied(io_extra_meta_resp_0_error_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt(io_extra_meta_resp_0_error_tl_corrupt),
    .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch),
    .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access),
    .io_extra_meta_resp_1_error_tl_denied(io_extra_meta_resp_1_error_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt(io_extra_meta_resp_1_error_tl_corrupt),
    .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch),
    .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access),
    .io_extra_meta_resp_2_error_tl_denied(io_extra_meta_resp_2_error_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt(io_extra_meta_resp_2_error_tl_corrupt),
    .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch),
    .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access),
    .io_extra_meta_resp_3_error_tl_denied(io_extra_meta_resp_3_error_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt(io_extra_meta_resp_3_error_tl_corrupt),
    .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch),
    .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access),
    .io_error_flag_write_valid(g_io_error_flag_write_valid),
    .io_error_flag_write_bits_idx(g_io_error_flag_write_bits_idx),
    .io_error_flag_write_bits_way_en(g_io_error_flag_write_bits_way_en),
    .io_error_flag_write_bits_error_tl_denied(g_io_error_flag_write_bits_error_tl_denied),
    .io_error_flag_write_bits_error_tl_corrupt(g_io_error_flag_write_bits_error_tl_corrupt),
    .io_prefetch_flag_write_valid(g_io_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx(g_io_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en(g_io_prefetch_flag_write_bits_way_en),
    .io_prefetch_flag_write_bits_source(g_io_prefetch_flag_write_bits_source),
    .io_access_flag_write_valid(g_io_access_flag_write_valid),
    .io_access_flag_write_bits_idx(g_io_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en(g_io_access_flag_write_bits_way_en),
    .io_access_flag_write_bits_flag(g_io_access_flag_write_bits_flag),
    .io_tag_read_ready(io_tag_read_ready),
    .io_tag_read_valid(g_io_tag_read_valid),
    .io_tag_read_bits_idx(g_io_tag_read_bits_idx),
    .io_tag_resp_0(io_tag_resp_0),
    .io_tag_resp_1(io_tag_resp_1),
    .io_tag_resp_2(io_tag_resp_2),
    .io_tag_resp_3(io_tag_resp_3),
    .io_tag_write_valid(g_io_tag_write_valid),
    .io_tag_write_bits_idx(g_io_tag_write_bits_idx),
    .io_tag_write_bits_way_en(g_io_tag_write_bits_way_en),
    .io_tag_write_bits_tag(g_io_tag_write_bits_tag),
    .io_tag_write_intend(g_io_tag_write_intend),
    .io_replace_access_valid(g_io_replace_access_valid),
    .io_replace_access_bits_set(g_io_replace_access_bits_set),
    .io_replace_access_bits_way(g_io_replace_access_bits_way),
    .io_replace_way_set_bits(g_io_replace_way_set_bits),
    .io_replace_way_way(io_replace_way_way),
    .io_evict_set(g_io_evict_set),
    .io_btot_ways_for_set(io_btot_ways_for_set),
    .io_replace_req_bits_addr(g_io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(g_io_replace_req_bits_vaddr),
    .io_replace_block(io_replace_block),
    .io_sms_agt_evict_req_valid(g_io_sms_agt_evict_req_valid),
    .io_sms_agt_evict_req_bits_vaddr(g_io_sms_agt_evict_req_bits_vaddr),
    .io_status_dup_0_s1_valid(g_io_status_dup_0_s1_valid),
    .io_status_dup_0_s1_bits_set(g_io_status_dup_0_s1_bits_set),
    .io_status_dup_0_s1_bits_way_en(g_io_status_dup_0_s1_bits_way_en),
    .io_status_dup_0_s2_valid(g_io_status_dup_0_s2_valid),
    .io_status_dup_0_s2_bits_set(g_io_status_dup_0_s2_bits_set),
    .io_status_dup_0_s2_bits_way_en(g_io_status_dup_0_s2_bits_way_en),
    .io_status_dup_0_s3_valid(g_io_status_dup_0_s3_valid),
    .io_status_dup_0_s3_bits_set(g_io_status_dup_0_s3_bits_set),
    .io_status_dup_0_s3_bits_way_en(g_io_status_dup_0_s3_bits_way_en),
    .io_status_dup_1_s1_valid(g_io_status_dup_1_s1_valid),
    .io_status_dup_1_s1_bits_set(g_io_status_dup_1_s1_bits_set),
    .io_status_dup_1_s1_bits_way_en(g_io_status_dup_1_s1_bits_way_en),
    .io_status_dup_1_s2_valid(g_io_status_dup_1_s2_valid),
    .io_status_dup_1_s2_bits_set(g_io_status_dup_1_s2_bits_set),
    .io_status_dup_1_s2_bits_way_en(g_io_status_dup_1_s2_bits_way_en),
    .io_status_dup_1_s3_valid(g_io_status_dup_1_s3_valid),
    .io_status_dup_1_s3_bits_set(g_io_status_dup_1_s3_bits_set),
    .io_status_dup_1_s3_bits_way_en(g_io_status_dup_1_s3_bits_way_en),
    .io_status_dup_2_s1_valid(g_io_status_dup_2_s1_valid),
    .io_status_dup_2_s1_bits_set(g_io_status_dup_2_s1_bits_set),
    .io_status_dup_2_s1_bits_way_en(g_io_status_dup_2_s1_bits_way_en),
    .io_status_dup_2_s2_valid(g_io_status_dup_2_s2_valid),
    .io_status_dup_2_s2_bits_set(g_io_status_dup_2_s2_bits_set),
    .io_status_dup_2_s2_bits_way_en(g_io_status_dup_2_s2_bits_way_en),
    .io_status_dup_2_s3_valid(g_io_status_dup_2_s3_valid),
    .io_status_dup_2_s3_bits_set(g_io_status_dup_2_s3_bits_set),
    .io_status_dup_2_s3_bits_way_en(g_io_status_dup_2_s3_bits_way_en),
    .io_status_dup_3_s1_valid(g_io_status_dup_3_s1_valid),
    .io_status_dup_3_s1_bits_set(g_io_status_dup_3_s1_bits_set),
    .io_status_dup_3_s1_bits_way_en(g_io_status_dup_3_s1_bits_way_en),
    .io_status_dup_3_s2_valid(g_io_status_dup_3_s2_valid),
    .io_status_dup_3_s2_bits_set(g_io_status_dup_3_s2_bits_set),
    .io_status_dup_3_s2_bits_way_en(g_io_status_dup_3_s2_bits_way_en),
    .io_status_dup_3_s3_valid(g_io_status_dup_3_s3_valid),
    .io_status_dup_3_s3_bits_set(g_io_status_dup_3_s3_bits_set),
    .io_status_dup_3_s3_bits_way_en(g_io_status_dup_3_s3_bits_way_en),
    .io_status_dup_4_s1_valid(g_io_status_dup_4_s1_valid),
    .io_status_dup_4_s1_bits_set(g_io_status_dup_4_s1_bits_set),
    .io_status_dup_4_s1_bits_way_en(g_io_status_dup_4_s1_bits_way_en),
    .io_status_dup_4_s2_valid(g_io_status_dup_4_s2_valid),
    .io_status_dup_4_s2_bits_set(g_io_status_dup_4_s2_bits_set),
    .io_status_dup_4_s2_bits_way_en(g_io_status_dup_4_s2_bits_way_en),
    .io_status_dup_4_s3_valid(g_io_status_dup_4_s3_valid),
    .io_status_dup_4_s3_bits_set(g_io_status_dup_4_s3_bits_set),
    .io_status_dup_4_s3_bits_way_en(g_io_status_dup_4_s3_bits_way_en),
    .io_status_dup_5_s1_valid(g_io_status_dup_5_s1_valid),
    .io_status_dup_5_s1_bits_set(g_io_status_dup_5_s1_bits_set),
    .io_status_dup_5_s1_bits_way_en(g_io_status_dup_5_s1_bits_way_en),
    .io_status_dup_5_s2_valid(g_io_status_dup_5_s2_valid),
    .io_status_dup_5_s2_bits_set(g_io_status_dup_5_s2_bits_set),
    .io_status_dup_5_s2_bits_way_en(g_io_status_dup_5_s2_bits_way_en),
    .io_status_dup_5_s3_valid(g_io_status_dup_5_s3_valid),
    .io_status_dup_5_s3_bits_set(g_io_status_dup_5_s3_bits_set),
    .io_status_dup_5_s3_bits_way_en(g_io_status_dup_5_s3_bits_way_en),
    .io_status_dup_6_s1_valid(g_io_status_dup_6_s1_valid),
    .io_status_dup_6_s1_bits_set(g_io_status_dup_6_s1_bits_set),
    .io_status_dup_6_s1_bits_way_en(g_io_status_dup_6_s1_bits_way_en),
    .io_status_dup_6_s2_valid(g_io_status_dup_6_s2_valid),
    .io_status_dup_6_s2_bits_set(g_io_status_dup_6_s2_bits_set),
    .io_status_dup_6_s2_bits_way_en(g_io_status_dup_6_s2_bits_way_en),
    .io_status_dup_6_s3_valid(g_io_status_dup_6_s3_valid),
    .io_status_dup_6_s3_bits_set(g_io_status_dup_6_s3_bits_set),
    .io_status_dup_6_s3_bits_way_en(g_io_status_dup_6_s3_bits_way_en),
    .io_status_dup_7_s1_valid(g_io_status_dup_7_s1_valid),
    .io_status_dup_7_s1_bits_set(g_io_status_dup_7_s1_bits_set),
    .io_status_dup_7_s1_bits_way_en(g_io_status_dup_7_s1_bits_way_en),
    .io_status_dup_7_s2_valid(g_io_status_dup_7_s2_valid),
    .io_status_dup_7_s2_bits_set(g_io_status_dup_7_s2_bits_set),
    .io_status_dup_7_s2_bits_way_en(g_io_status_dup_7_s2_bits_way_en),
    .io_status_dup_7_s3_valid(g_io_status_dup_7_s3_valid),
    .io_status_dup_7_s3_bits_set(g_io_status_dup_7_s3_bits_set),
    .io_status_dup_7_s3_bits_way_en(g_io_status_dup_7_s3_bits_way_en),
    .io_status_dup_8_s1_valid(g_io_status_dup_8_s1_valid),
    .io_status_dup_8_s1_bits_set(g_io_status_dup_8_s1_bits_set),
    .io_status_dup_8_s1_bits_way_en(g_io_status_dup_8_s1_bits_way_en),
    .io_status_dup_8_s2_valid(g_io_status_dup_8_s2_valid),
    .io_status_dup_8_s2_bits_set(g_io_status_dup_8_s2_bits_set),
    .io_status_dup_8_s2_bits_way_en(g_io_status_dup_8_s2_bits_way_en),
    .io_status_dup_8_s3_valid(g_io_status_dup_8_s3_valid),
    .io_status_dup_8_s3_bits_set(g_io_status_dup_8_s3_bits_set),
    .io_status_dup_8_s3_bits_way_en(g_io_status_dup_8_s3_bits_way_en),
    .io_status_dup_9_s1_valid(g_io_status_dup_9_s1_valid),
    .io_status_dup_9_s1_bits_set(g_io_status_dup_9_s1_bits_set),
    .io_status_dup_9_s1_bits_way_en(g_io_status_dup_9_s1_bits_way_en),
    .io_status_dup_9_s2_valid(g_io_status_dup_9_s2_valid),
    .io_status_dup_9_s2_bits_set(g_io_status_dup_9_s2_bits_set),
    .io_status_dup_9_s2_bits_way_en(g_io_status_dup_9_s2_bits_way_en),
    .io_status_dup_9_s3_valid(g_io_status_dup_9_s3_valid),
    .io_status_dup_9_s3_bits_set(g_io_status_dup_9_s3_bits_set),
    .io_status_dup_9_s3_bits_way_en(g_io_status_dup_9_s3_bits_way_en),
    .io_status_dup_10_s1_valid(g_io_status_dup_10_s1_valid),
    .io_status_dup_10_s1_bits_set(g_io_status_dup_10_s1_bits_set),
    .io_status_dup_10_s1_bits_way_en(g_io_status_dup_10_s1_bits_way_en),
    .io_status_dup_10_s2_valid(g_io_status_dup_10_s2_valid),
    .io_status_dup_10_s2_bits_set(g_io_status_dup_10_s2_bits_set),
    .io_status_dup_10_s2_bits_way_en(g_io_status_dup_10_s2_bits_way_en),
    .io_status_dup_10_s3_valid(g_io_status_dup_10_s3_valid),
    .io_status_dup_10_s3_bits_set(g_io_status_dup_10_s3_bits_set),
    .io_status_dup_10_s3_bits_way_en(g_io_status_dup_10_s3_bits_way_en),
    .io_status_dup_11_s1_valid(g_io_status_dup_11_s1_valid),
    .io_status_dup_11_s1_bits_set(g_io_status_dup_11_s1_bits_set),
    .io_status_dup_11_s1_bits_way_en(g_io_status_dup_11_s1_bits_way_en),
    .io_status_dup_11_s2_valid(g_io_status_dup_11_s2_valid),
    .io_status_dup_11_s2_bits_set(g_io_status_dup_11_s2_bits_set),
    .io_status_dup_11_s2_bits_way_en(g_io_status_dup_11_s2_bits_way_en),
    .io_status_dup_11_s3_valid(g_io_status_dup_11_s3_valid),
    .io_status_dup_11_s3_bits_set(g_io_status_dup_11_s3_bits_set),
    .io_status_dup_11_s3_bits_way_en(g_io_status_dup_11_s3_bits_way_en),
    .io_status_dup_12_s1_valid(g_io_status_dup_12_s1_valid),
    .io_status_dup_12_s1_bits_set(g_io_status_dup_12_s1_bits_set),
    .io_status_dup_12_s1_bits_way_en(g_io_status_dup_12_s1_bits_way_en),
    .io_status_dup_12_s2_valid(g_io_status_dup_12_s2_valid),
    .io_status_dup_12_s2_bits_set(g_io_status_dup_12_s2_bits_set),
    .io_status_dup_12_s2_bits_way_en(g_io_status_dup_12_s2_bits_way_en),
    .io_status_dup_12_s3_valid(g_io_status_dup_12_s3_valid),
    .io_status_dup_12_s3_bits_set(g_io_status_dup_12_s3_bits_set),
    .io_status_dup_12_s3_bits_way_en(g_io_status_dup_12_s3_bits_way_en),
    .io_status_dup_13_s1_valid(g_io_status_dup_13_s1_valid),
    .io_status_dup_13_s1_bits_set(g_io_status_dup_13_s1_bits_set),
    .io_status_dup_13_s1_bits_way_en(g_io_status_dup_13_s1_bits_way_en),
    .io_status_dup_13_s2_valid(g_io_status_dup_13_s2_valid),
    .io_status_dup_13_s2_bits_set(g_io_status_dup_13_s2_bits_set),
    .io_status_dup_13_s2_bits_way_en(g_io_status_dup_13_s2_bits_way_en),
    .io_status_dup_13_s3_valid(g_io_status_dup_13_s3_valid),
    .io_status_dup_13_s3_bits_set(g_io_status_dup_13_s3_bits_set),
    .io_status_dup_13_s3_bits_way_en(g_io_status_dup_13_s3_bits_way_en),
    .io_status_dup_14_s1_valid(g_io_status_dup_14_s1_valid),
    .io_status_dup_14_s1_bits_set(g_io_status_dup_14_s1_bits_set),
    .io_status_dup_14_s1_bits_way_en(g_io_status_dup_14_s1_bits_way_en),
    .io_status_dup_14_s2_valid(g_io_status_dup_14_s2_valid),
    .io_status_dup_14_s2_bits_set(g_io_status_dup_14_s2_bits_set),
    .io_status_dup_14_s2_bits_way_en(g_io_status_dup_14_s2_bits_way_en),
    .io_status_dup_14_s3_valid(g_io_status_dup_14_s3_valid),
    .io_status_dup_14_s3_bits_set(g_io_status_dup_14_s3_bits_set),
    .io_status_dup_14_s3_bits_way_en(g_io_status_dup_14_s3_bits_way_en),
    .io_status_dup_15_s1_valid(g_io_status_dup_15_s1_valid),
    .io_status_dup_15_s1_bits_set(g_io_status_dup_15_s1_bits_set),
    .io_status_dup_15_s1_bits_way_en(g_io_status_dup_15_s1_bits_way_en),
    .io_status_dup_15_s2_valid(g_io_status_dup_15_s2_valid),
    .io_status_dup_15_s2_bits_set(g_io_status_dup_15_s2_bits_set),
    .io_status_dup_15_s2_bits_way_en(g_io_status_dup_15_s2_bits_way_en),
    .io_status_dup_15_s3_valid(g_io_status_dup_15_s3_valid),
    .io_status_dup_15_s3_bits_set(g_io_status_dup_15_s3_bits_set),
    .io_status_dup_15_s3_bits_way_en(g_io_status_dup_15_s3_bits_way_en),
    .io_status_dup_16_s1_valid(g_io_status_dup_16_s1_valid),
    .io_status_dup_16_s1_bits_set(g_io_status_dup_16_s1_bits_set),
    .io_status_dup_16_s1_bits_way_en(g_io_status_dup_16_s1_bits_way_en),
    .io_status_dup_16_s2_valid(g_io_status_dup_16_s2_valid),
    .io_status_dup_16_s2_bits_set(g_io_status_dup_16_s2_bits_set),
    .io_status_dup_16_s2_bits_way_en(g_io_status_dup_16_s2_bits_way_en),
    .io_status_dup_16_s3_valid(g_io_status_dup_16_s3_valid),
    .io_status_dup_16_s3_bits_set(g_io_status_dup_16_s3_bits_set),
    .io_status_dup_16_s3_bits_way_en(g_io_status_dup_16_s3_bits_way_en),
    .io_status_dup_17_s1_valid(g_io_status_dup_17_s1_valid),
    .io_status_dup_17_s1_bits_set(g_io_status_dup_17_s1_bits_set),
    .io_status_dup_17_s1_bits_way_en(g_io_status_dup_17_s1_bits_way_en),
    .io_status_dup_17_s2_valid(g_io_status_dup_17_s2_valid),
    .io_status_dup_17_s2_bits_set(g_io_status_dup_17_s2_bits_set),
    .io_status_dup_17_s2_bits_way_en(g_io_status_dup_17_s2_bits_way_en),
    .io_status_dup_17_s3_valid(g_io_status_dup_17_s3_valid),
    .io_status_dup_17_s3_bits_set(g_io_status_dup_17_s3_bits_set),
    .io_status_dup_17_s3_bits_way_en(g_io_status_dup_17_s3_bits_way_en),
    .io_status_dup_18_s1_valid(g_io_status_dup_18_s1_valid),
    .io_status_dup_18_s1_bits_set(g_io_status_dup_18_s1_bits_set),
    .io_status_dup_18_s1_bits_way_en(g_io_status_dup_18_s1_bits_way_en),
    .io_status_dup_18_s2_valid(g_io_status_dup_18_s2_valid),
    .io_status_dup_18_s2_bits_set(g_io_status_dup_18_s2_bits_set),
    .io_status_dup_18_s2_bits_way_en(g_io_status_dup_18_s2_bits_way_en),
    .io_status_dup_18_s3_valid(g_io_status_dup_18_s3_valid),
    .io_status_dup_18_s3_bits_set(g_io_status_dup_18_s3_bits_set),
    .io_status_dup_18_s3_bits_way_en(g_io_status_dup_18_s3_bits_way_en),
    .io_status_dup_19_s1_valid(g_io_status_dup_19_s1_valid),
    .io_status_dup_19_s1_bits_set(g_io_status_dup_19_s1_bits_set),
    .io_status_dup_19_s1_bits_way_en(g_io_status_dup_19_s1_bits_way_en),
    .io_status_dup_19_s2_valid(g_io_status_dup_19_s2_valid),
    .io_status_dup_19_s2_bits_set(g_io_status_dup_19_s2_bits_set),
    .io_status_dup_19_s2_bits_way_en(g_io_status_dup_19_s2_bits_way_en),
    .io_status_dup_19_s3_valid(g_io_status_dup_19_s3_valid),
    .io_status_dup_19_s3_bits_set(g_io_status_dup_19_s3_bits_set),
    .io_status_dup_19_s3_bits_way_en(g_io_status_dup_19_s3_bits_way_en),
    .io_status_dup_20_s1_valid(g_io_status_dup_20_s1_valid),
    .io_status_dup_20_s1_bits_set(g_io_status_dup_20_s1_bits_set),
    .io_status_dup_20_s1_bits_way_en(g_io_status_dup_20_s1_bits_way_en),
    .io_status_dup_20_s2_valid(g_io_status_dup_20_s2_valid),
    .io_status_dup_20_s2_bits_set(g_io_status_dup_20_s2_bits_set),
    .io_status_dup_20_s2_bits_way_en(g_io_status_dup_20_s2_bits_way_en),
    .io_status_dup_20_s3_valid(g_io_status_dup_20_s3_valid),
    .io_status_dup_20_s3_bits_set(g_io_status_dup_20_s3_bits_set),
    .io_status_dup_20_s3_bits_way_en(g_io_status_dup_20_s3_bits_way_en),
    .io_status_dup_21_s1_valid(g_io_status_dup_21_s1_valid),
    .io_status_dup_21_s1_bits_set(g_io_status_dup_21_s1_bits_set),
    .io_status_dup_21_s1_bits_way_en(g_io_status_dup_21_s1_bits_way_en),
    .io_status_dup_21_s2_valid(g_io_status_dup_21_s2_valid),
    .io_status_dup_21_s2_bits_set(g_io_status_dup_21_s2_bits_set),
    .io_status_dup_21_s2_bits_way_en(g_io_status_dup_21_s2_bits_way_en),
    .io_status_dup_21_s3_valid(g_io_status_dup_21_s3_valid),
    .io_status_dup_21_s3_bits_set(g_io_status_dup_21_s3_bits_set),
    .io_status_dup_21_s3_bits_way_en(g_io_status_dup_21_s3_bits_way_en),
    .io_status_dup_22_s1_valid(g_io_status_dup_22_s1_valid),
    .io_status_dup_22_s1_bits_set(g_io_status_dup_22_s1_bits_set),
    .io_status_dup_22_s1_bits_way_en(g_io_status_dup_22_s1_bits_way_en),
    .io_status_dup_22_s2_valid(g_io_status_dup_22_s2_valid),
    .io_status_dup_22_s2_bits_set(g_io_status_dup_22_s2_bits_set),
    .io_status_dup_22_s2_bits_way_en(g_io_status_dup_22_s2_bits_way_en),
    .io_status_dup_22_s3_valid(g_io_status_dup_22_s3_valid),
    .io_status_dup_22_s3_bits_set(g_io_status_dup_22_s3_bits_set),
    .io_status_dup_22_s3_bits_way_en(g_io_status_dup_22_s3_bits_way_en),
    .io_status_dup_23_s1_valid(g_io_status_dup_23_s1_valid),
    .io_status_dup_23_s1_bits_set(g_io_status_dup_23_s1_bits_set),
    .io_status_dup_23_s1_bits_way_en(g_io_status_dup_23_s1_bits_way_en),
    .io_status_dup_23_s2_valid(g_io_status_dup_23_s2_valid),
    .io_status_dup_23_s2_bits_set(g_io_status_dup_23_s2_bits_set),
    .io_status_dup_23_s2_bits_way_en(g_io_status_dup_23_s2_bits_way_en),
    .io_status_dup_23_s3_valid(g_io_status_dup_23_s3_valid),
    .io_status_dup_23_s3_bits_set(g_io_status_dup_23_s3_bits_set),
    .io_status_dup_23_s3_bits_way_en(g_io_status_dup_23_s3_bits_way_en),
    .io_lrsc_locked_block_valid(g_io_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits(g_io_lrsc_locked_block_bits),
    .io_invalid_resv_set(io_invalid_resv_set),
    .io_update_resv_set(g_io_update_resv_set),
    .io_block_lr(g_io_block_lr),
    .io_error_valid(g_io_error_valid),
    .io_error_bits_paddr(g_io_error_bits_paddr),
    .io_error_bits_report_to_beu(g_io_error_bits_report_to_beu),
    .io_pseudo_error_valid(io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask),
    .io_pseudo_tag_error_inj_done(g_io_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done(g_io_pseudo_data_error_inj_done),
    .io_bloom_filter_query_set_valid(g_io_bloom_filter_query_set_valid),
    .io_bloom_filter_query_set_bits_addr(g_io_bloom_filter_query_set_bits_addr),
    .io_bloom_filter_query_clr_valid(g_io_bloom_filter_query_clr_valid),
    .io_bloom_filter_query_clr_bits_addr(g_io_bloom_filter_query_clr_bits_addr),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value)
  );
  MainPipe_xs u_impl (
    .clock(clock),
    .reset(reset),
    .io_probe_req_ready(i_io_probe_req_ready),
    .io_probe_req_valid(io_probe_req_valid),
    .io_probe_req_bits_probe_param(io_probe_req_bits_probe_param),
    .io_probe_req_bits_probe_need_data(io_probe_req_bits_probe_need_data),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_id(io_probe_req_bits_id),
    .io_miss_req_ready(io_miss_req_ready),
    .io_miss_req_valid(i_io_miss_req_valid),
    .io_miss_req_bits_source(i_io_miss_req_bits_source),
    .io_miss_req_bits_cmd(i_io_miss_req_bits_cmd),
    .io_miss_req_bits_addr(i_io_miss_req_bits_addr),
    .io_miss_req_bits_vaddr(i_io_miss_req_bits_vaddr),
    .io_miss_req_bits_full_overwrite(i_io_miss_req_bits_full_overwrite),
    .io_miss_req_bits_word_idx(i_io_miss_req_bits_word_idx),
    .io_miss_req_bits_amo_data(i_io_miss_req_bits_amo_data),
    .io_miss_req_bits_amo_mask(i_io_miss_req_bits_amo_mask),
    .io_miss_req_bits_amo_cmp(i_io_miss_req_bits_amo_cmp),
    .io_miss_req_bits_req_coh_state(i_io_miss_req_bits_req_coh_state),
    .io_miss_req_bits_id(i_io_miss_req_bits_id),
    .io_miss_req_bits_isBtoT(i_io_miss_req_bits_isBtoT),
    .io_miss_req_bits_occupy_way(i_io_miss_req_bits_occupy_way),
    .io_miss_req_bits_cancel(i_io_miss_req_bits_cancel),
    .io_miss_req_bits_store_data(i_io_miss_req_bits_store_data),
    .io_miss_req_bits_store_mask(i_io_miss_req_bits_store_mask),
    .io_refill_req_ready(i_io_refill_req_ready),
    .io_refill_req_valid(io_refill_req_valid),
    .io_refill_req_bits_miss_id(io_refill_req_bits_miss_id),
    .io_refill_req_bits_occupy_way(io_refill_req_bits_occupy_way),
    .io_refill_req_bits_miss_fail_cause_evict_btot(io_refill_req_bits_miss_fail_cause_evict_btot),
    .io_refill_req_bits_source(io_refill_req_bits_source),
    .io_refill_req_bits_cmd(io_refill_req_bits_cmd),
    .io_refill_req_bits_vaddr(io_refill_req_bits_vaddr),
    .io_refill_req_bits_addr(io_refill_req_bits_addr),
    .io_refill_req_bits_word_idx(io_refill_req_bits_word_idx),
    .io_refill_req_bits_amo_data(io_refill_req_bits_amo_data),
    .io_refill_req_bits_amo_mask(io_refill_req_bits_amo_mask),
    .io_refill_req_bits_amo_cmp(io_refill_req_bits_amo_cmp),
    .io_refill_req_bits_pf_source(io_refill_req_bits_pf_source),
    .io_refill_req_bits_access(io_refill_req_bits_access),
    .io_refill_req_bits_id(io_refill_req_bits_id),
    .io_wbq_conflict_check_valid(i_io_wbq_conflict_check_valid),
    .io_wbq_conflict_check_bits(i_io_wbq_conflict_check_bits),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_store_req_ready(i_io_store_req_ready),
    .io_store_req_valid(io_store_req_valid),
    .io_store_req_bits_vaddr(io_store_req_bits_vaddr),
    .io_store_req_bits_addr(io_store_req_bits_addr),
    .io_store_req_bits_data(io_store_req_bits_data),
    .io_store_req_bits_mask(io_store_req_bits_mask),
    .io_store_req_bits_id(io_store_req_bits_id),
    .io_store_replay_resp_valid(i_io_store_replay_resp_valid),
    .io_store_replay_resp_bits_id(i_io_store_replay_resp_bits_id),
    .io_store_hit_resp_valid(i_io_store_hit_resp_valid),
    .io_store_hit_resp_bits_id(i_io_store_hit_resp_bits_id),
    .io_atomic_req_ready(i_io_atomic_req_ready),
    .io_atomic_req_valid(io_atomic_req_valid),
    .io_atomic_req_bits_cmd(io_atomic_req_bits_cmd),
    .io_atomic_req_bits_vaddr(io_atomic_req_bits_vaddr),
    .io_atomic_req_bits_addr(io_atomic_req_bits_addr),
    .io_atomic_req_bits_word_idx(io_atomic_req_bits_word_idx),
    .io_atomic_req_bits_amo_data(io_atomic_req_bits_amo_data),
    .io_atomic_req_bits_amo_mask(io_atomic_req_bits_amo_mask),
    .io_atomic_req_bits_amo_cmp(io_atomic_req_bits_amo_cmp),
    .io_atomic_resp_valid(i_io_atomic_resp_valid),
    .io_atomic_resp_bits_source(i_io_atomic_resp_bits_source),
    .io_atomic_resp_bits_data(i_io_atomic_resp_bits_data),
    .io_atomic_resp_bits_miss(i_io_atomic_resp_bits_miss),
    .io_atomic_resp_bits_miss_id(i_io_atomic_resp_bits_miss_id),
    .io_atomic_resp_bits_replay(i_io_atomic_resp_bits_replay),
    .io_atomic_resp_bits_tl_error_tl_denied(i_io_atomic_resp_bits_tl_error_tl_denied),
    .io_atomic_resp_bits_tl_error_tl_corrupt(i_io_atomic_resp_bits_tl_error_tl_corrupt),
    .io_atomic_resp_bits_ack_miss_queue(i_io_atomic_resp_bits_ack_miss_queue),
    .io_atomic_resp_bits_id(i_io_atomic_resp_bits_id),
    .io_mainpipe_info_s2_valid(i_io_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id(i_io_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq(i_io_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way(i_io_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way(i_io_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid(i_io_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id(i_io_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp(i_io_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid(io_refill_info_valid),
    .io_refill_info_bits_store_data(io_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask(io_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param(io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(io_refill_info_bits_error_tl_corrupt),
    .io_wb_ready(io_wb_ready),
    .io_wb_valid(i_io_wb_valid),
    .io_wb_bits_param(i_io_wb_bits_param),
    .io_wb_bits_voluntary(i_io_wb_bits_voluntary),
    .io_wb_bits_hasData(i_io_wb_bits_hasData),
    .io_wb_bits_corrupt(i_io_wb_bits_corrupt),
    .io_wb_bits_dirty(i_io_wb_bits_dirty),
    .io_wb_bits_addr(i_io_wb_bits_addr),
    .io_wb_bits_data(i_io_wb_bits_data),
    .io_data_read_intend(i_io_data_read_intend),
    .io_data_readline_ready(io_data_readline_ready),
    .io_data_readline_valid(i_io_data_readline_valid),
    .io_data_readline_bits_way_en(i_io_data_readline_bits_way_en),
    .io_data_readline_bits_addr(i_io_data_readline_bits_addr),
    .io_data_readline_bits_rmask(i_io_data_readline_bits_rmask),
    .io_data_readline_can_go(i_io_data_readline_can_go),
    .io_data_readline_stall(i_io_data_readline_stall),
    .io_data_readline_can_resp(i_io_data_readline_can_resp),
    .io_data_resp_0_raw_data(io_data_resp_0_raw_data),
    .io_data_resp_1_raw_data(io_data_resp_1_raw_data),
    .io_data_resp_2_raw_data(io_data_resp_2_raw_data),
    .io_data_resp_3_raw_data(io_data_resp_3_raw_data),
    .io_data_resp_4_raw_data(io_data_resp_4_raw_data),
    .io_data_resp_5_raw_data(io_data_resp_5_raw_data),
    .io_data_resp_6_raw_data(io_data_resp_6_raw_data),
    .io_data_resp_7_raw_data(io_data_resp_7_raw_data),
    .io_readline_error_delayed(io_readline_error_delayed),
    .io_data_write_valid(i_io_data_write_valid),
    .io_data_write_bits_wmask(i_io_data_write_bits_wmask),
    .io_data_write_bits_data_0(i_io_data_write_bits_data_0),
    .io_data_write_bits_data_1(i_io_data_write_bits_data_1),
    .io_data_write_bits_data_2(i_io_data_write_bits_data_2),
    .io_data_write_bits_data_3(i_io_data_write_bits_data_3),
    .io_data_write_bits_data_4(i_io_data_write_bits_data_4),
    .io_data_write_bits_data_5(i_io_data_write_bits_data_5),
    .io_data_write_bits_data_6(i_io_data_write_bits_data_6),
    .io_data_write_bits_data_7(i_io_data_write_bits_data_7),
    .io_data_write_dup_0_valid(i_io_data_write_dup_0_valid),
    .io_data_write_dup_0_bits_way_en(i_io_data_write_dup_0_bits_way_en),
    .io_data_write_dup_0_bits_addr(i_io_data_write_dup_0_bits_addr),
    .io_data_write_dup_1_valid(i_io_data_write_dup_1_valid),
    .io_data_write_dup_1_bits_way_en(i_io_data_write_dup_1_bits_way_en),
    .io_data_write_dup_1_bits_addr(i_io_data_write_dup_1_bits_addr),
    .io_data_write_dup_2_valid(i_io_data_write_dup_2_valid),
    .io_data_write_dup_2_bits_way_en(i_io_data_write_dup_2_bits_way_en),
    .io_data_write_dup_2_bits_addr(i_io_data_write_dup_2_bits_addr),
    .io_data_write_dup_3_valid(i_io_data_write_dup_3_valid),
    .io_data_write_dup_3_bits_way_en(i_io_data_write_dup_3_bits_way_en),
    .io_data_write_dup_3_bits_addr(i_io_data_write_dup_3_bits_addr),
    .io_data_write_dup_4_valid(i_io_data_write_dup_4_valid),
    .io_data_write_dup_4_bits_way_en(i_io_data_write_dup_4_bits_way_en),
    .io_data_write_dup_4_bits_addr(i_io_data_write_dup_4_bits_addr),
    .io_data_write_dup_5_valid(i_io_data_write_dup_5_valid),
    .io_data_write_dup_5_bits_way_en(i_io_data_write_dup_5_bits_way_en),
    .io_data_write_dup_5_bits_addr(i_io_data_write_dup_5_bits_addr),
    .io_data_write_dup_6_valid(i_io_data_write_dup_6_valid),
    .io_data_write_dup_6_bits_way_en(i_io_data_write_dup_6_bits_way_en),
    .io_data_write_dup_6_bits_addr(i_io_data_write_dup_6_bits_addr),
    .io_data_write_dup_7_valid(i_io_data_write_dup_7_valid),
    .io_data_write_dup_7_bits_way_en(i_io_data_write_dup_7_bits_way_en),
    .io_data_write_dup_7_bits_addr(i_io_data_write_dup_7_bits_addr),
    .io_meta_read_valid(i_io_meta_read_valid),
    .io_meta_read_bits_idx(i_io_meta_read_bits_idx),
    .io_meta_resp_0_coh_state(io_meta_resp_0_coh_state),
    .io_meta_resp_1_coh_state(io_meta_resp_1_coh_state),
    .io_meta_resp_2_coh_state(io_meta_resp_2_coh_state),
    .io_meta_resp_3_coh_state(io_meta_resp_3_coh_state),
    .io_meta_write_valid(i_io_meta_write_valid),
    .io_meta_write_bits_idx(i_io_meta_write_bits_idx),
    .io_meta_write_bits_way_en(i_io_meta_write_bits_way_en),
    .io_meta_write_bits_meta_coh_state(i_io_meta_write_bits_meta_coh_state),
    .io_extra_meta_resp_0_error_tl_denied(io_extra_meta_resp_0_error_tl_denied),
    .io_extra_meta_resp_0_error_tl_corrupt(io_extra_meta_resp_0_error_tl_corrupt),
    .io_extra_meta_resp_0_prefetch(io_extra_meta_resp_0_prefetch),
    .io_extra_meta_resp_0_access(io_extra_meta_resp_0_access),
    .io_extra_meta_resp_1_error_tl_denied(io_extra_meta_resp_1_error_tl_denied),
    .io_extra_meta_resp_1_error_tl_corrupt(io_extra_meta_resp_1_error_tl_corrupt),
    .io_extra_meta_resp_1_prefetch(io_extra_meta_resp_1_prefetch),
    .io_extra_meta_resp_1_access(io_extra_meta_resp_1_access),
    .io_extra_meta_resp_2_error_tl_denied(io_extra_meta_resp_2_error_tl_denied),
    .io_extra_meta_resp_2_error_tl_corrupt(io_extra_meta_resp_2_error_tl_corrupt),
    .io_extra_meta_resp_2_prefetch(io_extra_meta_resp_2_prefetch),
    .io_extra_meta_resp_2_access(io_extra_meta_resp_2_access),
    .io_extra_meta_resp_3_error_tl_denied(io_extra_meta_resp_3_error_tl_denied),
    .io_extra_meta_resp_3_error_tl_corrupt(io_extra_meta_resp_3_error_tl_corrupt),
    .io_extra_meta_resp_3_prefetch(io_extra_meta_resp_3_prefetch),
    .io_extra_meta_resp_3_access(io_extra_meta_resp_3_access),
    .io_error_flag_write_valid(i_io_error_flag_write_valid),
    .io_error_flag_write_bits_idx(i_io_error_flag_write_bits_idx),
    .io_error_flag_write_bits_way_en(i_io_error_flag_write_bits_way_en),
    .io_error_flag_write_bits_error_tl_denied(i_io_error_flag_write_bits_error_tl_denied),
    .io_error_flag_write_bits_error_tl_corrupt(i_io_error_flag_write_bits_error_tl_corrupt),
    .io_prefetch_flag_write_valid(i_io_prefetch_flag_write_valid),
    .io_prefetch_flag_write_bits_idx(i_io_prefetch_flag_write_bits_idx),
    .io_prefetch_flag_write_bits_way_en(i_io_prefetch_flag_write_bits_way_en),
    .io_prefetch_flag_write_bits_source(i_io_prefetch_flag_write_bits_source),
    .io_access_flag_write_valid(i_io_access_flag_write_valid),
    .io_access_flag_write_bits_idx(i_io_access_flag_write_bits_idx),
    .io_access_flag_write_bits_way_en(i_io_access_flag_write_bits_way_en),
    .io_access_flag_write_bits_flag(i_io_access_flag_write_bits_flag),
    .io_tag_read_ready(io_tag_read_ready),
    .io_tag_read_valid(i_io_tag_read_valid),
    .io_tag_read_bits_idx(i_io_tag_read_bits_idx),
    .io_tag_resp_0(io_tag_resp_0),
    .io_tag_resp_1(io_tag_resp_1),
    .io_tag_resp_2(io_tag_resp_2),
    .io_tag_resp_3(io_tag_resp_3),
    .io_tag_write_valid(i_io_tag_write_valid),
    .io_tag_write_bits_idx(i_io_tag_write_bits_idx),
    .io_tag_write_bits_way_en(i_io_tag_write_bits_way_en),
    .io_tag_write_bits_tag(i_io_tag_write_bits_tag),
    .io_tag_write_intend(i_io_tag_write_intend),
    .io_replace_access_valid(i_io_replace_access_valid),
    .io_replace_access_bits_set(i_io_replace_access_bits_set),
    .io_replace_access_bits_way(i_io_replace_access_bits_way),
    .io_replace_way_set_bits(i_io_replace_way_set_bits),
    .io_replace_way_way(io_replace_way_way),
    .io_evict_set(i_io_evict_set),
    .io_btot_ways_for_set(io_btot_ways_for_set),
    .io_replace_req_bits_addr(i_io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(i_io_replace_req_bits_vaddr),
    .io_replace_block(io_replace_block),
    .io_sms_agt_evict_req_valid(i_io_sms_agt_evict_req_valid),
    .io_sms_agt_evict_req_bits_vaddr(i_io_sms_agt_evict_req_bits_vaddr),
    .io_status_dup_0_s1_valid(i_io_status_dup_0_s1_valid),
    .io_status_dup_0_s1_bits_set(i_io_status_dup_0_s1_bits_set),
    .io_status_dup_0_s1_bits_way_en(i_io_status_dup_0_s1_bits_way_en),
    .io_status_dup_0_s2_valid(i_io_status_dup_0_s2_valid),
    .io_status_dup_0_s2_bits_set(i_io_status_dup_0_s2_bits_set),
    .io_status_dup_0_s2_bits_way_en(i_io_status_dup_0_s2_bits_way_en),
    .io_status_dup_0_s3_valid(i_io_status_dup_0_s3_valid),
    .io_status_dup_0_s3_bits_set(i_io_status_dup_0_s3_bits_set),
    .io_status_dup_0_s3_bits_way_en(i_io_status_dup_0_s3_bits_way_en),
    .io_status_dup_1_s1_valid(i_io_status_dup_1_s1_valid),
    .io_status_dup_1_s1_bits_set(i_io_status_dup_1_s1_bits_set),
    .io_status_dup_1_s1_bits_way_en(i_io_status_dup_1_s1_bits_way_en),
    .io_status_dup_1_s2_valid(i_io_status_dup_1_s2_valid),
    .io_status_dup_1_s2_bits_set(i_io_status_dup_1_s2_bits_set),
    .io_status_dup_1_s2_bits_way_en(i_io_status_dup_1_s2_bits_way_en),
    .io_status_dup_1_s3_valid(i_io_status_dup_1_s3_valid),
    .io_status_dup_1_s3_bits_set(i_io_status_dup_1_s3_bits_set),
    .io_status_dup_1_s3_bits_way_en(i_io_status_dup_1_s3_bits_way_en),
    .io_status_dup_2_s1_valid(i_io_status_dup_2_s1_valid),
    .io_status_dup_2_s1_bits_set(i_io_status_dup_2_s1_bits_set),
    .io_status_dup_2_s1_bits_way_en(i_io_status_dup_2_s1_bits_way_en),
    .io_status_dup_2_s2_valid(i_io_status_dup_2_s2_valid),
    .io_status_dup_2_s2_bits_set(i_io_status_dup_2_s2_bits_set),
    .io_status_dup_2_s2_bits_way_en(i_io_status_dup_2_s2_bits_way_en),
    .io_status_dup_2_s3_valid(i_io_status_dup_2_s3_valid),
    .io_status_dup_2_s3_bits_set(i_io_status_dup_2_s3_bits_set),
    .io_status_dup_2_s3_bits_way_en(i_io_status_dup_2_s3_bits_way_en),
    .io_status_dup_3_s1_valid(i_io_status_dup_3_s1_valid),
    .io_status_dup_3_s1_bits_set(i_io_status_dup_3_s1_bits_set),
    .io_status_dup_3_s1_bits_way_en(i_io_status_dup_3_s1_bits_way_en),
    .io_status_dup_3_s2_valid(i_io_status_dup_3_s2_valid),
    .io_status_dup_3_s2_bits_set(i_io_status_dup_3_s2_bits_set),
    .io_status_dup_3_s2_bits_way_en(i_io_status_dup_3_s2_bits_way_en),
    .io_status_dup_3_s3_valid(i_io_status_dup_3_s3_valid),
    .io_status_dup_3_s3_bits_set(i_io_status_dup_3_s3_bits_set),
    .io_status_dup_3_s3_bits_way_en(i_io_status_dup_3_s3_bits_way_en),
    .io_status_dup_4_s1_valid(i_io_status_dup_4_s1_valid),
    .io_status_dup_4_s1_bits_set(i_io_status_dup_4_s1_bits_set),
    .io_status_dup_4_s1_bits_way_en(i_io_status_dup_4_s1_bits_way_en),
    .io_status_dup_4_s2_valid(i_io_status_dup_4_s2_valid),
    .io_status_dup_4_s2_bits_set(i_io_status_dup_4_s2_bits_set),
    .io_status_dup_4_s2_bits_way_en(i_io_status_dup_4_s2_bits_way_en),
    .io_status_dup_4_s3_valid(i_io_status_dup_4_s3_valid),
    .io_status_dup_4_s3_bits_set(i_io_status_dup_4_s3_bits_set),
    .io_status_dup_4_s3_bits_way_en(i_io_status_dup_4_s3_bits_way_en),
    .io_status_dup_5_s1_valid(i_io_status_dup_5_s1_valid),
    .io_status_dup_5_s1_bits_set(i_io_status_dup_5_s1_bits_set),
    .io_status_dup_5_s1_bits_way_en(i_io_status_dup_5_s1_bits_way_en),
    .io_status_dup_5_s2_valid(i_io_status_dup_5_s2_valid),
    .io_status_dup_5_s2_bits_set(i_io_status_dup_5_s2_bits_set),
    .io_status_dup_5_s2_bits_way_en(i_io_status_dup_5_s2_bits_way_en),
    .io_status_dup_5_s3_valid(i_io_status_dup_5_s3_valid),
    .io_status_dup_5_s3_bits_set(i_io_status_dup_5_s3_bits_set),
    .io_status_dup_5_s3_bits_way_en(i_io_status_dup_5_s3_bits_way_en),
    .io_status_dup_6_s1_valid(i_io_status_dup_6_s1_valid),
    .io_status_dup_6_s1_bits_set(i_io_status_dup_6_s1_bits_set),
    .io_status_dup_6_s1_bits_way_en(i_io_status_dup_6_s1_bits_way_en),
    .io_status_dup_6_s2_valid(i_io_status_dup_6_s2_valid),
    .io_status_dup_6_s2_bits_set(i_io_status_dup_6_s2_bits_set),
    .io_status_dup_6_s2_bits_way_en(i_io_status_dup_6_s2_bits_way_en),
    .io_status_dup_6_s3_valid(i_io_status_dup_6_s3_valid),
    .io_status_dup_6_s3_bits_set(i_io_status_dup_6_s3_bits_set),
    .io_status_dup_6_s3_bits_way_en(i_io_status_dup_6_s3_bits_way_en),
    .io_status_dup_7_s1_valid(i_io_status_dup_7_s1_valid),
    .io_status_dup_7_s1_bits_set(i_io_status_dup_7_s1_bits_set),
    .io_status_dup_7_s1_bits_way_en(i_io_status_dup_7_s1_bits_way_en),
    .io_status_dup_7_s2_valid(i_io_status_dup_7_s2_valid),
    .io_status_dup_7_s2_bits_set(i_io_status_dup_7_s2_bits_set),
    .io_status_dup_7_s2_bits_way_en(i_io_status_dup_7_s2_bits_way_en),
    .io_status_dup_7_s3_valid(i_io_status_dup_7_s3_valid),
    .io_status_dup_7_s3_bits_set(i_io_status_dup_7_s3_bits_set),
    .io_status_dup_7_s3_bits_way_en(i_io_status_dup_7_s3_bits_way_en),
    .io_status_dup_8_s1_valid(i_io_status_dup_8_s1_valid),
    .io_status_dup_8_s1_bits_set(i_io_status_dup_8_s1_bits_set),
    .io_status_dup_8_s1_bits_way_en(i_io_status_dup_8_s1_bits_way_en),
    .io_status_dup_8_s2_valid(i_io_status_dup_8_s2_valid),
    .io_status_dup_8_s2_bits_set(i_io_status_dup_8_s2_bits_set),
    .io_status_dup_8_s2_bits_way_en(i_io_status_dup_8_s2_bits_way_en),
    .io_status_dup_8_s3_valid(i_io_status_dup_8_s3_valid),
    .io_status_dup_8_s3_bits_set(i_io_status_dup_8_s3_bits_set),
    .io_status_dup_8_s3_bits_way_en(i_io_status_dup_8_s3_bits_way_en),
    .io_status_dup_9_s1_valid(i_io_status_dup_9_s1_valid),
    .io_status_dup_9_s1_bits_set(i_io_status_dup_9_s1_bits_set),
    .io_status_dup_9_s1_bits_way_en(i_io_status_dup_9_s1_bits_way_en),
    .io_status_dup_9_s2_valid(i_io_status_dup_9_s2_valid),
    .io_status_dup_9_s2_bits_set(i_io_status_dup_9_s2_bits_set),
    .io_status_dup_9_s2_bits_way_en(i_io_status_dup_9_s2_bits_way_en),
    .io_status_dup_9_s3_valid(i_io_status_dup_9_s3_valid),
    .io_status_dup_9_s3_bits_set(i_io_status_dup_9_s3_bits_set),
    .io_status_dup_9_s3_bits_way_en(i_io_status_dup_9_s3_bits_way_en),
    .io_status_dup_10_s1_valid(i_io_status_dup_10_s1_valid),
    .io_status_dup_10_s1_bits_set(i_io_status_dup_10_s1_bits_set),
    .io_status_dup_10_s1_bits_way_en(i_io_status_dup_10_s1_bits_way_en),
    .io_status_dup_10_s2_valid(i_io_status_dup_10_s2_valid),
    .io_status_dup_10_s2_bits_set(i_io_status_dup_10_s2_bits_set),
    .io_status_dup_10_s2_bits_way_en(i_io_status_dup_10_s2_bits_way_en),
    .io_status_dup_10_s3_valid(i_io_status_dup_10_s3_valid),
    .io_status_dup_10_s3_bits_set(i_io_status_dup_10_s3_bits_set),
    .io_status_dup_10_s3_bits_way_en(i_io_status_dup_10_s3_bits_way_en),
    .io_status_dup_11_s1_valid(i_io_status_dup_11_s1_valid),
    .io_status_dup_11_s1_bits_set(i_io_status_dup_11_s1_bits_set),
    .io_status_dup_11_s1_bits_way_en(i_io_status_dup_11_s1_bits_way_en),
    .io_status_dup_11_s2_valid(i_io_status_dup_11_s2_valid),
    .io_status_dup_11_s2_bits_set(i_io_status_dup_11_s2_bits_set),
    .io_status_dup_11_s2_bits_way_en(i_io_status_dup_11_s2_bits_way_en),
    .io_status_dup_11_s3_valid(i_io_status_dup_11_s3_valid),
    .io_status_dup_11_s3_bits_set(i_io_status_dup_11_s3_bits_set),
    .io_status_dup_11_s3_bits_way_en(i_io_status_dup_11_s3_bits_way_en),
    .io_status_dup_12_s1_valid(i_io_status_dup_12_s1_valid),
    .io_status_dup_12_s1_bits_set(i_io_status_dup_12_s1_bits_set),
    .io_status_dup_12_s1_bits_way_en(i_io_status_dup_12_s1_bits_way_en),
    .io_status_dup_12_s2_valid(i_io_status_dup_12_s2_valid),
    .io_status_dup_12_s2_bits_set(i_io_status_dup_12_s2_bits_set),
    .io_status_dup_12_s2_bits_way_en(i_io_status_dup_12_s2_bits_way_en),
    .io_status_dup_12_s3_valid(i_io_status_dup_12_s3_valid),
    .io_status_dup_12_s3_bits_set(i_io_status_dup_12_s3_bits_set),
    .io_status_dup_12_s3_bits_way_en(i_io_status_dup_12_s3_bits_way_en),
    .io_status_dup_13_s1_valid(i_io_status_dup_13_s1_valid),
    .io_status_dup_13_s1_bits_set(i_io_status_dup_13_s1_bits_set),
    .io_status_dup_13_s1_bits_way_en(i_io_status_dup_13_s1_bits_way_en),
    .io_status_dup_13_s2_valid(i_io_status_dup_13_s2_valid),
    .io_status_dup_13_s2_bits_set(i_io_status_dup_13_s2_bits_set),
    .io_status_dup_13_s2_bits_way_en(i_io_status_dup_13_s2_bits_way_en),
    .io_status_dup_13_s3_valid(i_io_status_dup_13_s3_valid),
    .io_status_dup_13_s3_bits_set(i_io_status_dup_13_s3_bits_set),
    .io_status_dup_13_s3_bits_way_en(i_io_status_dup_13_s3_bits_way_en),
    .io_status_dup_14_s1_valid(i_io_status_dup_14_s1_valid),
    .io_status_dup_14_s1_bits_set(i_io_status_dup_14_s1_bits_set),
    .io_status_dup_14_s1_bits_way_en(i_io_status_dup_14_s1_bits_way_en),
    .io_status_dup_14_s2_valid(i_io_status_dup_14_s2_valid),
    .io_status_dup_14_s2_bits_set(i_io_status_dup_14_s2_bits_set),
    .io_status_dup_14_s2_bits_way_en(i_io_status_dup_14_s2_bits_way_en),
    .io_status_dup_14_s3_valid(i_io_status_dup_14_s3_valid),
    .io_status_dup_14_s3_bits_set(i_io_status_dup_14_s3_bits_set),
    .io_status_dup_14_s3_bits_way_en(i_io_status_dup_14_s3_bits_way_en),
    .io_status_dup_15_s1_valid(i_io_status_dup_15_s1_valid),
    .io_status_dup_15_s1_bits_set(i_io_status_dup_15_s1_bits_set),
    .io_status_dup_15_s1_bits_way_en(i_io_status_dup_15_s1_bits_way_en),
    .io_status_dup_15_s2_valid(i_io_status_dup_15_s2_valid),
    .io_status_dup_15_s2_bits_set(i_io_status_dup_15_s2_bits_set),
    .io_status_dup_15_s2_bits_way_en(i_io_status_dup_15_s2_bits_way_en),
    .io_status_dup_15_s3_valid(i_io_status_dup_15_s3_valid),
    .io_status_dup_15_s3_bits_set(i_io_status_dup_15_s3_bits_set),
    .io_status_dup_15_s3_bits_way_en(i_io_status_dup_15_s3_bits_way_en),
    .io_status_dup_16_s1_valid(i_io_status_dup_16_s1_valid),
    .io_status_dup_16_s1_bits_set(i_io_status_dup_16_s1_bits_set),
    .io_status_dup_16_s1_bits_way_en(i_io_status_dup_16_s1_bits_way_en),
    .io_status_dup_16_s2_valid(i_io_status_dup_16_s2_valid),
    .io_status_dup_16_s2_bits_set(i_io_status_dup_16_s2_bits_set),
    .io_status_dup_16_s2_bits_way_en(i_io_status_dup_16_s2_bits_way_en),
    .io_status_dup_16_s3_valid(i_io_status_dup_16_s3_valid),
    .io_status_dup_16_s3_bits_set(i_io_status_dup_16_s3_bits_set),
    .io_status_dup_16_s3_bits_way_en(i_io_status_dup_16_s3_bits_way_en),
    .io_status_dup_17_s1_valid(i_io_status_dup_17_s1_valid),
    .io_status_dup_17_s1_bits_set(i_io_status_dup_17_s1_bits_set),
    .io_status_dup_17_s1_bits_way_en(i_io_status_dup_17_s1_bits_way_en),
    .io_status_dup_17_s2_valid(i_io_status_dup_17_s2_valid),
    .io_status_dup_17_s2_bits_set(i_io_status_dup_17_s2_bits_set),
    .io_status_dup_17_s2_bits_way_en(i_io_status_dup_17_s2_bits_way_en),
    .io_status_dup_17_s3_valid(i_io_status_dup_17_s3_valid),
    .io_status_dup_17_s3_bits_set(i_io_status_dup_17_s3_bits_set),
    .io_status_dup_17_s3_bits_way_en(i_io_status_dup_17_s3_bits_way_en),
    .io_status_dup_18_s1_valid(i_io_status_dup_18_s1_valid),
    .io_status_dup_18_s1_bits_set(i_io_status_dup_18_s1_bits_set),
    .io_status_dup_18_s1_bits_way_en(i_io_status_dup_18_s1_bits_way_en),
    .io_status_dup_18_s2_valid(i_io_status_dup_18_s2_valid),
    .io_status_dup_18_s2_bits_set(i_io_status_dup_18_s2_bits_set),
    .io_status_dup_18_s2_bits_way_en(i_io_status_dup_18_s2_bits_way_en),
    .io_status_dup_18_s3_valid(i_io_status_dup_18_s3_valid),
    .io_status_dup_18_s3_bits_set(i_io_status_dup_18_s3_bits_set),
    .io_status_dup_18_s3_bits_way_en(i_io_status_dup_18_s3_bits_way_en),
    .io_status_dup_19_s1_valid(i_io_status_dup_19_s1_valid),
    .io_status_dup_19_s1_bits_set(i_io_status_dup_19_s1_bits_set),
    .io_status_dup_19_s1_bits_way_en(i_io_status_dup_19_s1_bits_way_en),
    .io_status_dup_19_s2_valid(i_io_status_dup_19_s2_valid),
    .io_status_dup_19_s2_bits_set(i_io_status_dup_19_s2_bits_set),
    .io_status_dup_19_s2_bits_way_en(i_io_status_dup_19_s2_bits_way_en),
    .io_status_dup_19_s3_valid(i_io_status_dup_19_s3_valid),
    .io_status_dup_19_s3_bits_set(i_io_status_dup_19_s3_bits_set),
    .io_status_dup_19_s3_bits_way_en(i_io_status_dup_19_s3_bits_way_en),
    .io_status_dup_20_s1_valid(i_io_status_dup_20_s1_valid),
    .io_status_dup_20_s1_bits_set(i_io_status_dup_20_s1_bits_set),
    .io_status_dup_20_s1_bits_way_en(i_io_status_dup_20_s1_bits_way_en),
    .io_status_dup_20_s2_valid(i_io_status_dup_20_s2_valid),
    .io_status_dup_20_s2_bits_set(i_io_status_dup_20_s2_bits_set),
    .io_status_dup_20_s2_bits_way_en(i_io_status_dup_20_s2_bits_way_en),
    .io_status_dup_20_s3_valid(i_io_status_dup_20_s3_valid),
    .io_status_dup_20_s3_bits_set(i_io_status_dup_20_s3_bits_set),
    .io_status_dup_20_s3_bits_way_en(i_io_status_dup_20_s3_bits_way_en),
    .io_status_dup_21_s1_valid(i_io_status_dup_21_s1_valid),
    .io_status_dup_21_s1_bits_set(i_io_status_dup_21_s1_bits_set),
    .io_status_dup_21_s1_bits_way_en(i_io_status_dup_21_s1_bits_way_en),
    .io_status_dup_21_s2_valid(i_io_status_dup_21_s2_valid),
    .io_status_dup_21_s2_bits_set(i_io_status_dup_21_s2_bits_set),
    .io_status_dup_21_s2_bits_way_en(i_io_status_dup_21_s2_bits_way_en),
    .io_status_dup_21_s3_valid(i_io_status_dup_21_s3_valid),
    .io_status_dup_21_s3_bits_set(i_io_status_dup_21_s3_bits_set),
    .io_status_dup_21_s3_bits_way_en(i_io_status_dup_21_s3_bits_way_en),
    .io_status_dup_22_s1_valid(i_io_status_dup_22_s1_valid),
    .io_status_dup_22_s1_bits_set(i_io_status_dup_22_s1_bits_set),
    .io_status_dup_22_s1_bits_way_en(i_io_status_dup_22_s1_bits_way_en),
    .io_status_dup_22_s2_valid(i_io_status_dup_22_s2_valid),
    .io_status_dup_22_s2_bits_set(i_io_status_dup_22_s2_bits_set),
    .io_status_dup_22_s2_bits_way_en(i_io_status_dup_22_s2_bits_way_en),
    .io_status_dup_22_s3_valid(i_io_status_dup_22_s3_valid),
    .io_status_dup_22_s3_bits_set(i_io_status_dup_22_s3_bits_set),
    .io_status_dup_22_s3_bits_way_en(i_io_status_dup_22_s3_bits_way_en),
    .io_status_dup_23_s1_valid(i_io_status_dup_23_s1_valid),
    .io_status_dup_23_s1_bits_set(i_io_status_dup_23_s1_bits_set),
    .io_status_dup_23_s1_bits_way_en(i_io_status_dup_23_s1_bits_way_en),
    .io_status_dup_23_s2_valid(i_io_status_dup_23_s2_valid),
    .io_status_dup_23_s2_bits_set(i_io_status_dup_23_s2_bits_set),
    .io_status_dup_23_s2_bits_way_en(i_io_status_dup_23_s2_bits_way_en),
    .io_status_dup_23_s3_valid(i_io_status_dup_23_s3_valid),
    .io_status_dup_23_s3_bits_set(i_io_status_dup_23_s3_bits_set),
    .io_status_dup_23_s3_bits_way_en(i_io_status_dup_23_s3_bits_way_en),
    .io_lrsc_locked_block_valid(i_io_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits(i_io_lrsc_locked_block_bits),
    .io_invalid_resv_set(io_invalid_resv_set),
    .io_update_resv_set(i_io_update_resv_set),
    .io_block_lr(i_io_block_lr),
    .io_error_valid(i_io_error_valid),
    .io_error_bits_paddr(i_io_error_bits_paddr),
    .io_error_bits_report_to_beu(i_io_error_bits_report_to_beu),
    .io_pseudo_error_valid(io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(io_pseudo_error_bits_0_mask),
    .io_pseudo_tag_error_inj_done(i_io_pseudo_tag_error_inj_done),
    .io_pseudo_data_error_inj_done(i_io_pseudo_data_error_inj_done),
    .io_bloom_filter_query_set_valid(i_io_bloom_filter_query_set_valid),
    .io_bloom_filter_query_set_bits_addr(i_io_bloom_filter_query_set_bits_addr),
    .io_bloom_filter_query_clr_valid(i_io_bloom_filter_query_clr_valid),
    .io_bloom_filter_query_clr_bits_addr(i_io_bloom_filter_query_clr_bits_addr),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value)
  );
  // END GENERATED

  task automatic report_mismatch(input string name, input logic [511:0] g, input logic [511:0] i);
    errors++;
    if (errors <= 30)
      $display("MISMATCH cyc=%0d %s: g=%h i=%h", checks, name, g, i);
  endtask

  // BEGIN GENERATED(tb_compare)
  task automatic compare_outputs();
    if (g_io_probe_req_ready !== i_io_probe_req_ready) report_mismatch("io_probe_req_ready", 1'(g_io_probe_req_ready), 1'(i_io_probe_req_ready));
    if (g_io_miss_req_valid !== i_io_miss_req_valid) report_mismatch("io_miss_req_valid", 1'(g_io_miss_req_valid), 1'(i_io_miss_req_valid));
    if (g_io_miss_req_bits_source !== i_io_miss_req_bits_source) report_mismatch("io_miss_req_bits_source", 4'(g_io_miss_req_bits_source), 4'(i_io_miss_req_bits_source));
    if (g_io_miss_req_bits_cmd !== i_io_miss_req_bits_cmd) report_mismatch("io_miss_req_bits_cmd", 5'(g_io_miss_req_bits_cmd), 5'(i_io_miss_req_bits_cmd));
    if (g_io_miss_req_bits_addr !== i_io_miss_req_bits_addr) report_mismatch("io_miss_req_bits_addr", 48'(g_io_miss_req_bits_addr), 48'(i_io_miss_req_bits_addr));
    if (g_io_miss_req_bits_vaddr !== i_io_miss_req_bits_vaddr) report_mismatch("io_miss_req_bits_vaddr", 50'(g_io_miss_req_bits_vaddr), 50'(i_io_miss_req_bits_vaddr));
    if (g_io_miss_req_bits_full_overwrite !== i_io_miss_req_bits_full_overwrite) report_mismatch("io_miss_req_bits_full_overwrite", 1'(g_io_miss_req_bits_full_overwrite), 1'(i_io_miss_req_bits_full_overwrite));
    if (g_io_miss_req_bits_word_idx !== i_io_miss_req_bits_word_idx) report_mismatch("io_miss_req_bits_word_idx", 3'(g_io_miss_req_bits_word_idx), 3'(i_io_miss_req_bits_word_idx));
    if (g_io_miss_req_bits_amo_data !== i_io_miss_req_bits_amo_data) report_mismatch("io_miss_req_bits_amo_data", 128'(g_io_miss_req_bits_amo_data), 128'(i_io_miss_req_bits_amo_data));
    if (g_io_miss_req_bits_amo_mask !== i_io_miss_req_bits_amo_mask) report_mismatch("io_miss_req_bits_amo_mask", 16'(g_io_miss_req_bits_amo_mask), 16'(i_io_miss_req_bits_amo_mask));
    if (g_io_miss_req_bits_amo_cmp !== i_io_miss_req_bits_amo_cmp) report_mismatch("io_miss_req_bits_amo_cmp", 128'(g_io_miss_req_bits_amo_cmp), 128'(i_io_miss_req_bits_amo_cmp));
    if (g_io_miss_req_bits_req_coh_state !== i_io_miss_req_bits_req_coh_state) report_mismatch("io_miss_req_bits_req_coh_state", 2'(g_io_miss_req_bits_req_coh_state), 2'(i_io_miss_req_bits_req_coh_state));
    if (g_io_miss_req_bits_id !== i_io_miss_req_bits_id) report_mismatch("io_miss_req_bits_id", 6'(g_io_miss_req_bits_id), 6'(i_io_miss_req_bits_id));
    if (g_io_miss_req_bits_isBtoT !== i_io_miss_req_bits_isBtoT) report_mismatch("io_miss_req_bits_isBtoT", 1'(g_io_miss_req_bits_isBtoT), 1'(i_io_miss_req_bits_isBtoT));
    if (g_io_miss_req_bits_occupy_way !== i_io_miss_req_bits_occupy_way) report_mismatch("io_miss_req_bits_occupy_way", 4'(g_io_miss_req_bits_occupy_way), 4'(i_io_miss_req_bits_occupy_way));
    if (g_io_miss_req_bits_cancel !== i_io_miss_req_bits_cancel) report_mismatch("io_miss_req_bits_cancel", 1'(g_io_miss_req_bits_cancel), 1'(i_io_miss_req_bits_cancel));
    if (g_io_miss_req_bits_store_data !== i_io_miss_req_bits_store_data) report_mismatch("io_miss_req_bits_store_data", 512'(g_io_miss_req_bits_store_data), 512'(i_io_miss_req_bits_store_data));
    if (g_io_miss_req_bits_store_mask !== i_io_miss_req_bits_store_mask) report_mismatch("io_miss_req_bits_store_mask", 64'(g_io_miss_req_bits_store_mask), 64'(i_io_miss_req_bits_store_mask));
    if (g_io_refill_req_ready !== i_io_refill_req_ready) report_mismatch("io_refill_req_ready", 1'(g_io_refill_req_ready), 1'(i_io_refill_req_ready));
    if (g_io_wbq_conflict_check_valid !== i_io_wbq_conflict_check_valid) report_mismatch("io_wbq_conflict_check_valid", 1'(g_io_wbq_conflict_check_valid), 1'(i_io_wbq_conflict_check_valid));
    if (g_io_wbq_conflict_check_bits !== i_io_wbq_conflict_check_bits) report_mismatch("io_wbq_conflict_check_bits", 48'(g_io_wbq_conflict_check_bits), 48'(i_io_wbq_conflict_check_bits));
    if (g_io_store_req_ready !== i_io_store_req_ready) report_mismatch("io_store_req_ready", 1'(g_io_store_req_ready), 1'(i_io_store_req_ready));
    if (g_io_store_replay_resp_valid !== i_io_store_replay_resp_valid) report_mismatch("io_store_replay_resp_valid", 1'(g_io_store_replay_resp_valid), 1'(i_io_store_replay_resp_valid));
    if (g_io_store_replay_resp_bits_id !== i_io_store_replay_resp_bits_id) report_mismatch("io_store_replay_resp_bits_id", 6'(g_io_store_replay_resp_bits_id), 6'(i_io_store_replay_resp_bits_id));
    if (g_io_store_hit_resp_valid !== i_io_store_hit_resp_valid) report_mismatch("io_store_hit_resp_valid", 1'(g_io_store_hit_resp_valid), 1'(i_io_store_hit_resp_valid));
    if (g_io_store_hit_resp_bits_id !== i_io_store_hit_resp_bits_id) report_mismatch("io_store_hit_resp_bits_id", 6'(g_io_store_hit_resp_bits_id), 6'(i_io_store_hit_resp_bits_id));
    if (g_io_atomic_req_ready !== i_io_atomic_req_ready) report_mismatch("io_atomic_req_ready", 1'(g_io_atomic_req_ready), 1'(i_io_atomic_req_ready));
    if (g_io_atomic_resp_valid !== i_io_atomic_resp_valid) report_mismatch("io_atomic_resp_valid", 1'(g_io_atomic_resp_valid), 1'(i_io_atomic_resp_valid));
    if (g_io_atomic_resp_bits_source !== i_io_atomic_resp_bits_source) report_mismatch("io_atomic_resp_bits_source", 4'(g_io_atomic_resp_bits_source), 4'(i_io_atomic_resp_bits_source));
    if (g_io_atomic_resp_bits_data !== i_io_atomic_resp_bits_data) report_mismatch("io_atomic_resp_bits_data", 128'(g_io_atomic_resp_bits_data), 128'(i_io_atomic_resp_bits_data));
    if (g_io_atomic_resp_bits_miss !== i_io_atomic_resp_bits_miss) report_mismatch("io_atomic_resp_bits_miss", 1'(g_io_atomic_resp_bits_miss), 1'(i_io_atomic_resp_bits_miss));
    if (g_io_atomic_resp_bits_miss_id !== i_io_atomic_resp_bits_miss_id) report_mismatch("io_atomic_resp_bits_miss_id", 4'(g_io_atomic_resp_bits_miss_id), 4'(i_io_atomic_resp_bits_miss_id));
    if (g_io_atomic_resp_bits_replay !== i_io_atomic_resp_bits_replay) report_mismatch("io_atomic_resp_bits_replay", 1'(g_io_atomic_resp_bits_replay), 1'(i_io_atomic_resp_bits_replay));
    if (g_io_atomic_resp_bits_tl_error_tl_denied !== i_io_atomic_resp_bits_tl_error_tl_denied) report_mismatch("io_atomic_resp_bits_tl_error_tl_denied", 1'(g_io_atomic_resp_bits_tl_error_tl_denied), 1'(i_io_atomic_resp_bits_tl_error_tl_denied));
    if (g_io_atomic_resp_bits_tl_error_tl_corrupt !== i_io_atomic_resp_bits_tl_error_tl_corrupt) report_mismatch("io_atomic_resp_bits_tl_error_tl_corrupt", 1'(g_io_atomic_resp_bits_tl_error_tl_corrupt), 1'(i_io_atomic_resp_bits_tl_error_tl_corrupt));
    if (g_io_atomic_resp_bits_ack_miss_queue !== i_io_atomic_resp_bits_ack_miss_queue) report_mismatch("io_atomic_resp_bits_ack_miss_queue", 1'(g_io_atomic_resp_bits_ack_miss_queue), 1'(i_io_atomic_resp_bits_ack_miss_queue));
    if (g_io_atomic_resp_bits_id !== i_io_atomic_resp_bits_id) report_mismatch("io_atomic_resp_bits_id", 6'(g_io_atomic_resp_bits_id), 6'(i_io_atomic_resp_bits_id));
    if (g_io_mainpipe_info_s2_valid !== i_io_mainpipe_info_s2_valid) report_mismatch("io_mainpipe_info_s2_valid", 1'(g_io_mainpipe_info_s2_valid), 1'(i_io_mainpipe_info_s2_valid));
    if (g_io_mainpipe_info_s2_miss_id !== i_io_mainpipe_info_s2_miss_id) report_mismatch("io_mainpipe_info_s2_miss_id", 4'(g_io_mainpipe_info_s2_miss_id), 4'(i_io_mainpipe_info_s2_miss_id));
    if (g_io_mainpipe_info_s2_replay_to_mq !== i_io_mainpipe_info_s2_replay_to_mq) report_mismatch("io_mainpipe_info_s2_replay_to_mq", 1'(g_io_mainpipe_info_s2_replay_to_mq), 1'(i_io_mainpipe_info_s2_replay_to_mq));
    if (g_io_mainpipe_info_s2_evict_BtoT_way !== i_io_mainpipe_info_s2_evict_BtoT_way) report_mismatch("io_mainpipe_info_s2_evict_BtoT_way", 1'(g_io_mainpipe_info_s2_evict_BtoT_way), 1'(i_io_mainpipe_info_s2_evict_BtoT_way));
    if (g_io_mainpipe_info_s2_next_evict_way !== i_io_mainpipe_info_s2_next_evict_way) report_mismatch("io_mainpipe_info_s2_next_evict_way", 4'(g_io_mainpipe_info_s2_next_evict_way), 4'(i_io_mainpipe_info_s2_next_evict_way));
    if (g_io_mainpipe_info_s3_valid !== i_io_mainpipe_info_s3_valid) report_mismatch("io_mainpipe_info_s3_valid", 1'(g_io_mainpipe_info_s3_valid), 1'(i_io_mainpipe_info_s3_valid));
    if (g_io_mainpipe_info_s3_miss_id !== i_io_mainpipe_info_s3_miss_id) report_mismatch("io_mainpipe_info_s3_miss_id", 4'(g_io_mainpipe_info_s3_miss_id), 4'(i_io_mainpipe_info_s3_miss_id));
    if (g_io_mainpipe_info_s3_refill_resp !== i_io_mainpipe_info_s3_refill_resp) report_mismatch("io_mainpipe_info_s3_refill_resp", 1'(g_io_mainpipe_info_s3_refill_resp), 1'(i_io_mainpipe_info_s3_refill_resp));
    if (g_io_wb_valid !== i_io_wb_valid) report_mismatch("io_wb_valid", 1'(g_io_wb_valid), 1'(i_io_wb_valid));
    if (g_io_wb_bits_param !== i_io_wb_bits_param) report_mismatch("io_wb_bits_param", 3'(g_io_wb_bits_param), 3'(i_io_wb_bits_param));
    if (g_io_wb_bits_voluntary !== i_io_wb_bits_voluntary) report_mismatch("io_wb_bits_voluntary", 1'(g_io_wb_bits_voluntary), 1'(i_io_wb_bits_voluntary));
    if (g_io_wb_bits_hasData !== i_io_wb_bits_hasData) report_mismatch("io_wb_bits_hasData", 1'(g_io_wb_bits_hasData), 1'(i_io_wb_bits_hasData));
    if (g_io_wb_bits_corrupt !== i_io_wb_bits_corrupt) report_mismatch("io_wb_bits_corrupt", 1'(g_io_wb_bits_corrupt), 1'(i_io_wb_bits_corrupt));
    if (g_io_wb_bits_dirty !== i_io_wb_bits_dirty) report_mismatch("io_wb_bits_dirty", 1'(g_io_wb_bits_dirty), 1'(i_io_wb_bits_dirty));
    if (g_io_wb_bits_addr !== i_io_wb_bits_addr) report_mismatch("io_wb_bits_addr", 48'(g_io_wb_bits_addr), 48'(i_io_wb_bits_addr));
    if (g_io_wb_bits_data !== i_io_wb_bits_data) report_mismatch("io_wb_bits_data", 512'(g_io_wb_bits_data), 512'(i_io_wb_bits_data));
    if (g_io_data_read_intend !== i_io_data_read_intend) report_mismatch("io_data_read_intend", 1'(g_io_data_read_intend), 1'(i_io_data_read_intend));
    if (g_io_data_readline_valid !== i_io_data_readline_valid) report_mismatch("io_data_readline_valid", 1'(g_io_data_readline_valid), 1'(i_io_data_readline_valid));
    if (g_io_data_readline_bits_way_en !== i_io_data_readline_bits_way_en) report_mismatch("io_data_readline_bits_way_en", 4'(g_io_data_readline_bits_way_en), 4'(i_io_data_readline_bits_way_en));
    if (g_io_data_readline_bits_addr !== i_io_data_readline_bits_addr) report_mismatch("io_data_readline_bits_addr", 48'(g_io_data_readline_bits_addr), 48'(i_io_data_readline_bits_addr));
    if (g_io_data_readline_bits_rmask !== i_io_data_readline_bits_rmask) report_mismatch("io_data_readline_bits_rmask", 8'(g_io_data_readline_bits_rmask), 8'(i_io_data_readline_bits_rmask));
    if (g_io_data_readline_can_go !== i_io_data_readline_can_go) report_mismatch("io_data_readline_can_go", 1'(g_io_data_readline_can_go), 1'(i_io_data_readline_can_go));
    if (g_io_data_readline_stall !== i_io_data_readline_stall) report_mismatch("io_data_readline_stall", 1'(g_io_data_readline_stall), 1'(i_io_data_readline_stall));
    if (g_io_data_readline_can_resp !== i_io_data_readline_can_resp) report_mismatch("io_data_readline_can_resp", 1'(g_io_data_readline_can_resp), 1'(i_io_data_readline_can_resp));
    if (g_io_data_write_valid !== i_io_data_write_valid) report_mismatch("io_data_write_valid", 1'(g_io_data_write_valid), 1'(i_io_data_write_valid));
    if (g_io_data_write_bits_wmask !== i_io_data_write_bits_wmask) report_mismatch("io_data_write_bits_wmask", 8'(g_io_data_write_bits_wmask), 8'(i_io_data_write_bits_wmask));
    if (g_io_data_write_bits_data_0 !== i_io_data_write_bits_data_0) report_mismatch("io_data_write_bits_data_0", 64'(g_io_data_write_bits_data_0), 64'(i_io_data_write_bits_data_0));
    if (g_io_data_write_bits_data_1 !== i_io_data_write_bits_data_1) report_mismatch("io_data_write_bits_data_1", 64'(g_io_data_write_bits_data_1), 64'(i_io_data_write_bits_data_1));
    if (g_io_data_write_bits_data_2 !== i_io_data_write_bits_data_2) report_mismatch("io_data_write_bits_data_2", 64'(g_io_data_write_bits_data_2), 64'(i_io_data_write_bits_data_2));
    if (g_io_data_write_bits_data_3 !== i_io_data_write_bits_data_3) report_mismatch("io_data_write_bits_data_3", 64'(g_io_data_write_bits_data_3), 64'(i_io_data_write_bits_data_3));
    if (g_io_data_write_bits_data_4 !== i_io_data_write_bits_data_4) report_mismatch("io_data_write_bits_data_4", 64'(g_io_data_write_bits_data_4), 64'(i_io_data_write_bits_data_4));
    if (g_io_data_write_bits_data_5 !== i_io_data_write_bits_data_5) report_mismatch("io_data_write_bits_data_5", 64'(g_io_data_write_bits_data_5), 64'(i_io_data_write_bits_data_5));
    if (g_io_data_write_bits_data_6 !== i_io_data_write_bits_data_6) report_mismatch("io_data_write_bits_data_6", 64'(g_io_data_write_bits_data_6), 64'(i_io_data_write_bits_data_6));
    if (g_io_data_write_bits_data_7 !== i_io_data_write_bits_data_7) report_mismatch("io_data_write_bits_data_7", 64'(g_io_data_write_bits_data_7), 64'(i_io_data_write_bits_data_7));
    if (g_io_data_write_dup_0_valid !== i_io_data_write_dup_0_valid) report_mismatch("io_data_write_dup_0_valid", 1'(g_io_data_write_dup_0_valid), 1'(i_io_data_write_dup_0_valid));
    if (g_io_data_write_dup_0_bits_way_en !== i_io_data_write_dup_0_bits_way_en) report_mismatch("io_data_write_dup_0_bits_way_en", 4'(g_io_data_write_dup_0_bits_way_en), 4'(i_io_data_write_dup_0_bits_way_en));
    if (g_io_data_write_dup_0_bits_addr !== i_io_data_write_dup_0_bits_addr) report_mismatch("io_data_write_dup_0_bits_addr", 48'(g_io_data_write_dup_0_bits_addr), 48'(i_io_data_write_dup_0_bits_addr));
    if (g_io_data_write_dup_1_valid !== i_io_data_write_dup_1_valid) report_mismatch("io_data_write_dup_1_valid", 1'(g_io_data_write_dup_1_valid), 1'(i_io_data_write_dup_1_valid));
    if (g_io_data_write_dup_1_bits_way_en !== i_io_data_write_dup_1_bits_way_en) report_mismatch("io_data_write_dup_1_bits_way_en", 4'(g_io_data_write_dup_1_bits_way_en), 4'(i_io_data_write_dup_1_bits_way_en));
    if (g_io_data_write_dup_1_bits_addr !== i_io_data_write_dup_1_bits_addr) report_mismatch("io_data_write_dup_1_bits_addr", 48'(g_io_data_write_dup_1_bits_addr), 48'(i_io_data_write_dup_1_bits_addr));
    if (g_io_data_write_dup_2_valid !== i_io_data_write_dup_2_valid) report_mismatch("io_data_write_dup_2_valid", 1'(g_io_data_write_dup_2_valid), 1'(i_io_data_write_dup_2_valid));
    if (g_io_data_write_dup_2_bits_way_en !== i_io_data_write_dup_2_bits_way_en) report_mismatch("io_data_write_dup_2_bits_way_en", 4'(g_io_data_write_dup_2_bits_way_en), 4'(i_io_data_write_dup_2_bits_way_en));
    if (g_io_data_write_dup_2_bits_addr !== i_io_data_write_dup_2_bits_addr) report_mismatch("io_data_write_dup_2_bits_addr", 48'(g_io_data_write_dup_2_bits_addr), 48'(i_io_data_write_dup_2_bits_addr));
    if (g_io_data_write_dup_3_valid !== i_io_data_write_dup_3_valid) report_mismatch("io_data_write_dup_3_valid", 1'(g_io_data_write_dup_3_valid), 1'(i_io_data_write_dup_3_valid));
    if (g_io_data_write_dup_3_bits_way_en !== i_io_data_write_dup_3_bits_way_en) report_mismatch("io_data_write_dup_3_bits_way_en", 4'(g_io_data_write_dup_3_bits_way_en), 4'(i_io_data_write_dup_3_bits_way_en));
    if (g_io_data_write_dup_3_bits_addr !== i_io_data_write_dup_3_bits_addr) report_mismatch("io_data_write_dup_3_bits_addr", 48'(g_io_data_write_dup_3_bits_addr), 48'(i_io_data_write_dup_3_bits_addr));
    if (g_io_data_write_dup_4_valid !== i_io_data_write_dup_4_valid) report_mismatch("io_data_write_dup_4_valid", 1'(g_io_data_write_dup_4_valid), 1'(i_io_data_write_dup_4_valid));
    if (g_io_data_write_dup_4_bits_way_en !== i_io_data_write_dup_4_bits_way_en) report_mismatch("io_data_write_dup_4_bits_way_en", 4'(g_io_data_write_dup_4_bits_way_en), 4'(i_io_data_write_dup_4_bits_way_en));
    if (g_io_data_write_dup_4_bits_addr !== i_io_data_write_dup_4_bits_addr) report_mismatch("io_data_write_dup_4_bits_addr", 48'(g_io_data_write_dup_4_bits_addr), 48'(i_io_data_write_dup_4_bits_addr));
    if (g_io_data_write_dup_5_valid !== i_io_data_write_dup_5_valid) report_mismatch("io_data_write_dup_5_valid", 1'(g_io_data_write_dup_5_valid), 1'(i_io_data_write_dup_5_valid));
    if (g_io_data_write_dup_5_bits_way_en !== i_io_data_write_dup_5_bits_way_en) report_mismatch("io_data_write_dup_5_bits_way_en", 4'(g_io_data_write_dup_5_bits_way_en), 4'(i_io_data_write_dup_5_bits_way_en));
    if (g_io_data_write_dup_5_bits_addr !== i_io_data_write_dup_5_bits_addr) report_mismatch("io_data_write_dup_5_bits_addr", 48'(g_io_data_write_dup_5_bits_addr), 48'(i_io_data_write_dup_5_bits_addr));
    if (g_io_data_write_dup_6_valid !== i_io_data_write_dup_6_valid) report_mismatch("io_data_write_dup_6_valid", 1'(g_io_data_write_dup_6_valid), 1'(i_io_data_write_dup_6_valid));
    if (g_io_data_write_dup_6_bits_way_en !== i_io_data_write_dup_6_bits_way_en) report_mismatch("io_data_write_dup_6_bits_way_en", 4'(g_io_data_write_dup_6_bits_way_en), 4'(i_io_data_write_dup_6_bits_way_en));
    if (g_io_data_write_dup_6_bits_addr !== i_io_data_write_dup_6_bits_addr) report_mismatch("io_data_write_dup_6_bits_addr", 48'(g_io_data_write_dup_6_bits_addr), 48'(i_io_data_write_dup_6_bits_addr));
    if (g_io_data_write_dup_7_valid !== i_io_data_write_dup_7_valid) report_mismatch("io_data_write_dup_7_valid", 1'(g_io_data_write_dup_7_valid), 1'(i_io_data_write_dup_7_valid));
    if (g_io_data_write_dup_7_bits_way_en !== i_io_data_write_dup_7_bits_way_en) report_mismatch("io_data_write_dup_7_bits_way_en", 4'(g_io_data_write_dup_7_bits_way_en), 4'(i_io_data_write_dup_7_bits_way_en));
    if (g_io_data_write_dup_7_bits_addr !== i_io_data_write_dup_7_bits_addr) report_mismatch("io_data_write_dup_7_bits_addr", 48'(g_io_data_write_dup_7_bits_addr), 48'(i_io_data_write_dup_7_bits_addr));
    if (g_io_meta_read_valid !== i_io_meta_read_valid) report_mismatch("io_meta_read_valid", 1'(g_io_meta_read_valid), 1'(i_io_meta_read_valid));
    if (g_io_meta_read_bits_idx !== i_io_meta_read_bits_idx) report_mismatch("io_meta_read_bits_idx", 8'(g_io_meta_read_bits_idx), 8'(i_io_meta_read_bits_idx));
    if (g_io_meta_write_valid !== i_io_meta_write_valid) report_mismatch("io_meta_write_valid", 1'(g_io_meta_write_valid), 1'(i_io_meta_write_valid));
    if (g_io_meta_write_bits_idx !== i_io_meta_write_bits_idx) report_mismatch("io_meta_write_bits_idx", 8'(g_io_meta_write_bits_idx), 8'(i_io_meta_write_bits_idx));
    if (g_io_meta_write_bits_way_en !== i_io_meta_write_bits_way_en) report_mismatch("io_meta_write_bits_way_en", 4'(g_io_meta_write_bits_way_en), 4'(i_io_meta_write_bits_way_en));
    if (g_io_meta_write_bits_meta_coh_state !== i_io_meta_write_bits_meta_coh_state) report_mismatch("io_meta_write_bits_meta_coh_state", 2'(g_io_meta_write_bits_meta_coh_state), 2'(i_io_meta_write_bits_meta_coh_state));
    if (g_io_error_flag_write_valid !== i_io_error_flag_write_valid) report_mismatch("io_error_flag_write_valid", 1'(g_io_error_flag_write_valid), 1'(i_io_error_flag_write_valid));
    if (g_io_error_flag_write_bits_idx !== i_io_error_flag_write_bits_idx) report_mismatch("io_error_flag_write_bits_idx", 8'(g_io_error_flag_write_bits_idx), 8'(i_io_error_flag_write_bits_idx));
    if (g_io_error_flag_write_bits_way_en !== i_io_error_flag_write_bits_way_en) report_mismatch("io_error_flag_write_bits_way_en", 4'(g_io_error_flag_write_bits_way_en), 4'(i_io_error_flag_write_bits_way_en));
    if (g_io_error_flag_write_bits_error_tl_denied !== i_io_error_flag_write_bits_error_tl_denied) report_mismatch("io_error_flag_write_bits_error_tl_denied", 1'(g_io_error_flag_write_bits_error_tl_denied), 1'(i_io_error_flag_write_bits_error_tl_denied));
    if (g_io_error_flag_write_bits_error_tl_corrupt !== i_io_error_flag_write_bits_error_tl_corrupt) report_mismatch("io_error_flag_write_bits_error_tl_corrupt", 1'(g_io_error_flag_write_bits_error_tl_corrupt), 1'(i_io_error_flag_write_bits_error_tl_corrupt));
    if (g_io_prefetch_flag_write_valid !== i_io_prefetch_flag_write_valid) report_mismatch("io_prefetch_flag_write_valid", 1'(g_io_prefetch_flag_write_valid), 1'(i_io_prefetch_flag_write_valid));
    if (g_io_prefetch_flag_write_bits_idx !== i_io_prefetch_flag_write_bits_idx) report_mismatch("io_prefetch_flag_write_bits_idx", 8'(g_io_prefetch_flag_write_bits_idx), 8'(i_io_prefetch_flag_write_bits_idx));
    if (g_io_prefetch_flag_write_bits_way_en !== i_io_prefetch_flag_write_bits_way_en) report_mismatch("io_prefetch_flag_write_bits_way_en", 4'(g_io_prefetch_flag_write_bits_way_en), 4'(i_io_prefetch_flag_write_bits_way_en));
    if (g_io_prefetch_flag_write_bits_source !== i_io_prefetch_flag_write_bits_source) report_mismatch("io_prefetch_flag_write_bits_source", 3'(g_io_prefetch_flag_write_bits_source), 3'(i_io_prefetch_flag_write_bits_source));
    if (g_io_access_flag_write_valid !== i_io_access_flag_write_valid) report_mismatch("io_access_flag_write_valid", 1'(g_io_access_flag_write_valid), 1'(i_io_access_flag_write_valid));
    if (g_io_access_flag_write_bits_idx !== i_io_access_flag_write_bits_idx) report_mismatch("io_access_flag_write_bits_idx", 8'(g_io_access_flag_write_bits_idx), 8'(i_io_access_flag_write_bits_idx));
    if (g_io_access_flag_write_bits_way_en !== i_io_access_flag_write_bits_way_en) report_mismatch("io_access_flag_write_bits_way_en", 4'(g_io_access_flag_write_bits_way_en), 4'(i_io_access_flag_write_bits_way_en));
    if (g_io_access_flag_write_bits_flag !== i_io_access_flag_write_bits_flag) report_mismatch("io_access_flag_write_bits_flag", 1'(g_io_access_flag_write_bits_flag), 1'(i_io_access_flag_write_bits_flag));
    if (g_io_tag_read_valid !== i_io_tag_read_valid) report_mismatch("io_tag_read_valid", 1'(g_io_tag_read_valid), 1'(i_io_tag_read_valid));
    if (g_io_tag_read_bits_idx !== i_io_tag_read_bits_idx) report_mismatch("io_tag_read_bits_idx", 8'(g_io_tag_read_bits_idx), 8'(i_io_tag_read_bits_idx));
    if (g_io_tag_write_valid !== i_io_tag_write_valid) report_mismatch("io_tag_write_valid", 1'(g_io_tag_write_valid), 1'(i_io_tag_write_valid));
    if (g_io_tag_write_bits_idx !== i_io_tag_write_bits_idx) report_mismatch("io_tag_write_bits_idx", 8'(g_io_tag_write_bits_idx), 8'(i_io_tag_write_bits_idx));
    if (g_io_tag_write_bits_way_en !== i_io_tag_write_bits_way_en) report_mismatch("io_tag_write_bits_way_en", 4'(g_io_tag_write_bits_way_en), 4'(i_io_tag_write_bits_way_en));
    if (g_io_tag_write_bits_tag !== i_io_tag_write_bits_tag) report_mismatch("io_tag_write_bits_tag", 36'(g_io_tag_write_bits_tag), 36'(i_io_tag_write_bits_tag));
    if (g_io_tag_write_intend !== i_io_tag_write_intend) report_mismatch("io_tag_write_intend", 1'(g_io_tag_write_intend), 1'(i_io_tag_write_intend));
    if (g_io_replace_access_valid !== i_io_replace_access_valid) report_mismatch("io_replace_access_valid", 1'(g_io_replace_access_valid), 1'(i_io_replace_access_valid));
    if (g_io_replace_access_bits_set !== i_io_replace_access_bits_set) report_mismatch("io_replace_access_bits_set", 8'(g_io_replace_access_bits_set), 8'(i_io_replace_access_bits_set));
    if (g_io_replace_access_bits_way !== i_io_replace_access_bits_way) report_mismatch("io_replace_access_bits_way", 2'(g_io_replace_access_bits_way), 2'(i_io_replace_access_bits_way));
    if (g_io_replace_way_set_bits !== i_io_replace_way_set_bits) report_mismatch("io_replace_way_set_bits", 8'(g_io_replace_way_set_bits), 8'(i_io_replace_way_set_bits));
    if (g_io_evict_set !== i_io_evict_set) report_mismatch("io_evict_set", 8'(g_io_evict_set), 8'(i_io_evict_set));
    if (g_io_replace_req_bits_addr !== i_io_replace_req_bits_addr) report_mismatch("io_replace_req_bits_addr", 48'(g_io_replace_req_bits_addr), 48'(i_io_replace_req_bits_addr));
    if (g_io_replace_req_bits_vaddr !== i_io_replace_req_bits_vaddr) report_mismatch("io_replace_req_bits_vaddr", 50'(g_io_replace_req_bits_vaddr), 50'(i_io_replace_req_bits_vaddr));
    if (g_io_sms_agt_evict_req_valid !== i_io_sms_agt_evict_req_valid) report_mismatch("io_sms_agt_evict_req_valid", 1'(g_io_sms_agt_evict_req_valid), 1'(i_io_sms_agt_evict_req_valid));
    if (g_io_sms_agt_evict_req_bits_vaddr !== i_io_sms_agt_evict_req_bits_vaddr) report_mismatch("io_sms_agt_evict_req_bits_vaddr", 50'(g_io_sms_agt_evict_req_bits_vaddr), 50'(i_io_sms_agt_evict_req_bits_vaddr));
    if (g_io_status_dup_0_s1_valid !== i_io_status_dup_0_s1_valid) report_mismatch("io_status_dup_0_s1_valid", 1'(g_io_status_dup_0_s1_valid), 1'(i_io_status_dup_0_s1_valid));
    if (g_io_status_dup_0_s1_bits_set !== i_io_status_dup_0_s1_bits_set) report_mismatch("io_status_dup_0_s1_bits_set", 8'(g_io_status_dup_0_s1_bits_set), 8'(i_io_status_dup_0_s1_bits_set));
    if (g_io_status_dup_0_s1_bits_way_en !== i_io_status_dup_0_s1_bits_way_en) report_mismatch("io_status_dup_0_s1_bits_way_en", 4'(g_io_status_dup_0_s1_bits_way_en), 4'(i_io_status_dup_0_s1_bits_way_en));
    if (g_io_status_dup_0_s2_valid !== i_io_status_dup_0_s2_valid) report_mismatch("io_status_dup_0_s2_valid", 1'(g_io_status_dup_0_s2_valid), 1'(i_io_status_dup_0_s2_valid));
    if (g_io_status_dup_0_s2_bits_set !== i_io_status_dup_0_s2_bits_set) report_mismatch("io_status_dup_0_s2_bits_set", 8'(g_io_status_dup_0_s2_bits_set), 8'(i_io_status_dup_0_s2_bits_set));
    if (g_io_status_dup_0_s2_bits_way_en !== i_io_status_dup_0_s2_bits_way_en) report_mismatch("io_status_dup_0_s2_bits_way_en", 4'(g_io_status_dup_0_s2_bits_way_en), 4'(i_io_status_dup_0_s2_bits_way_en));
    if (g_io_status_dup_0_s3_valid !== i_io_status_dup_0_s3_valid) report_mismatch("io_status_dup_0_s3_valid", 1'(g_io_status_dup_0_s3_valid), 1'(i_io_status_dup_0_s3_valid));
    if (g_io_status_dup_0_s3_bits_set !== i_io_status_dup_0_s3_bits_set) report_mismatch("io_status_dup_0_s3_bits_set", 8'(g_io_status_dup_0_s3_bits_set), 8'(i_io_status_dup_0_s3_bits_set));
    if (g_io_status_dup_0_s3_bits_way_en !== i_io_status_dup_0_s3_bits_way_en) report_mismatch("io_status_dup_0_s3_bits_way_en", 4'(g_io_status_dup_0_s3_bits_way_en), 4'(i_io_status_dup_0_s3_bits_way_en));
    if (g_io_status_dup_1_s1_valid !== i_io_status_dup_1_s1_valid) report_mismatch("io_status_dup_1_s1_valid", 1'(g_io_status_dup_1_s1_valid), 1'(i_io_status_dup_1_s1_valid));
    if (g_io_status_dup_1_s1_bits_set !== i_io_status_dup_1_s1_bits_set) report_mismatch("io_status_dup_1_s1_bits_set", 8'(g_io_status_dup_1_s1_bits_set), 8'(i_io_status_dup_1_s1_bits_set));
    if (g_io_status_dup_1_s1_bits_way_en !== i_io_status_dup_1_s1_bits_way_en) report_mismatch("io_status_dup_1_s1_bits_way_en", 4'(g_io_status_dup_1_s1_bits_way_en), 4'(i_io_status_dup_1_s1_bits_way_en));
    if (g_io_status_dup_1_s2_valid !== i_io_status_dup_1_s2_valid) report_mismatch("io_status_dup_1_s2_valid", 1'(g_io_status_dup_1_s2_valid), 1'(i_io_status_dup_1_s2_valid));
    if (g_io_status_dup_1_s2_bits_set !== i_io_status_dup_1_s2_bits_set) report_mismatch("io_status_dup_1_s2_bits_set", 8'(g_io_status_dup_1_s2_bits_set), 8'(i_io_status_dup_1_s2_bits_set));
    if (g_io_status_dup_1_s2_bits_way_en !== i_io_status_dup_1_s2_bits_way_en) report_mismatch("io_status_dup_1_s2_bits_way_en", 4'(g_io_status_dup_1_s2_bits_way_en), 4'(i_io_status_dup_1_s2_bits_way_en));
    if (g_io_status_dup_1_s3_valid !== i_io_status_dup_1_s3_valid) report_mismatch("io_status_dup_1_s3_valid", 1'(g_io_status_dup_1_s3_valid), 1'(i_io_status_dup_1_s3_valid));
    if (g_io_status_dup_1_s3_bits_set !== i_io_status_dup_1_s3_bits_set) report_mismatch("io_status_dup_1_s3_bits_set", 8'(g_io_status_dup_1_s3_bits_set), 8'(i_io_status_dup_1_s3_bits_set));
    if (g_io_status_dup_1_s3_bits_way_en !== i_io_status_dup_1_s3_bits_way_en) report_mismatch("io_status_dup_1_s3_bits_way_en", 4'(g_io_status_dup_1_s3_bits_way_en), 4'(i_io_status_dup_1_s3_bits_way_en));
    if (g_io_status_dup_2_s1_valid !== i_io_status_dup_2_s1_valid) report_mismatch("io_status_dup_2_s1_valid", 1'(g_io_status_dup_2_s1_valid), 1'(i_io_status_dup_2_s1_valid));
    if (g_io_status_dup_2_s1_bits_set !== i_io_status_dup_2_s1_bits_set) report_mismatch("io_status_dup_2_s1_bits_set", 8'(g_io_status_dup_2_s1_bits_set), 8'(i_io_status_dup_2_s1_bits_set));
    if (g_io_status_dup_2_s1_bits_way_en !== i_io_status_dup_2_s1_bits_way_en) report_mismatch("io_status_dup_2_s1_bits_way_en", 4'(g_io_status_dup_2_s1_bits_way_en), 4'(i_io_status_dup_2_s1_bits_way_en));
    if (g_io_status_dup_2_s2_valid !== i_io_status_dup_2_s2_valid) report_mismatch("io_status_dup_2_s2_valid", 1'(g_io_status_dup_2_s2_valid), 1'(i_io_status_dup_2_s2_valid));
    if (g_io_status_dup_2_s2_bits_set !== i_io_status_dup_2_s2_bits_set) report_mismatch("io_status_dup_2_s2_bits_set", 8'(g_io_status_dup_2_s2_bits_set), 8'(i_io_status_dup_2_s2_bits_set));
    if (g_io_status_dup_2_s2_bits_way_en !== i_io_status_dup_2_s2_bits_way_en) report_mismatch("io_status_dup_2_s2_bits_way_en", 4'(g_io_status_dup_2_s2_bits_way_en), 4'(i_io_status_dup_2_s2_bits_way_en));
    if (g_io_status_dup_2_s3_valid !== i_io_status_dup_2_s3_valid) report_mismatch("io_status_dup_2_s3_valid", 1'(g_io_status_dup_2_s3_valid), 1'(i_io_status_dup_2_s3_valid));
    if (g_io_status_dup_2_s3_bits_set !== i_io_status_dup_2_s3_bits_set) report_mismatch("io_status_dup_2_s3_bits_set", 8'(g_io_status_dup_2_s3_bits_set), 8'(i_io_status_dup_2_s3_bits_set));
    if (g_io_status_dup_2_s3_bits_way_en !== i_io_status_dup_2_s3_bits_way_en) report_mismatch("io_status_dup_2_s3_bits_way_en", 4'(g_io_status_dup_2_s3_bits_way_en), 4'(i_io_status_dup_2_s3_bits_way_en));
    if (g_io_status_dup_3_s1_valid !== i_io_status_dup_3_s1_valid) report_mismatch("io_status_dup_3_s1_valid", 1'(g_io_status_dup_3_s1_valid), 1'(i_io_status_dup_3_s1_valid));
    if (g_io_status_dup_3_s1_bits_set !== i_io_status_dup_3_s1_bits_set) report_mismatch("io_status_dup_3_s1_bits_set", 8'(g_io_status_dup_3_s1_bits_set), 8'(i_io_status_dup_3_s1_bits_set));
    if (g_io_status_dup_3_s1_bits_way_en !== i_io_status_dup_3_s1_bits_way_en) report_mismatch("io_status_dup_3_s1_bits_way_en", 4'(g_io_status_dup_3_s1_bits_way_en), 4'(i_io_status_dup_3_s1_bits_way_en));
    if (g_io_status_dup_3_s2_valid !== i_io_status_dup_3_s2_valid) report_mismatch("io_status_dup_3_s2_valid", 1'(g_io_status_dup_3_s2_valid), 1'(i_io_status_dup_3_s2_valid));
    if (g_io_status_dup_3_s2_bits_set !== i_io_status_dup_3_s2_bits_set) report_mismatch("io_status_dup_3_s2_bits_set", 8'(g_io_status_dup_3_s2_bits_set), 8'(i_io_status_dup_3_s2_bits_set));
    if (g_io_status_dup_3_s2_bits_way_en !== i_io_status_dup_3_s2_bits_way_en) report_mismatch("io_status_dup_3_s2_bits_way_en", 4'(g_io_status_dup_3_s2_bits_way_en), 4'(i_io_status_dup_3_s2_bits_way_en));
    if (g_io_status_dup_3_s3_valid !== i_io_status_dup_3_s3_valid) report_mismatch("io_status_dup_3_s3_valid", 1'(g_io_status_dup_3_s3_valid), 1'(i_io_status_dup_3_s3_valid));
    if (g_io_status_dup_3_s3_bits_set !== i_io_status_dup_3_s3_bits_set) report_mismatch("io_status_dup_3_s3_bits_set", 8'(g_io_status_dup_3_s3_bits_set), 8'(i_io_status_dup_3_s3_bits_set));
    if (g_io_status_dup_3_s3_bits_way_en !== i_io_status_dup_3_s3_bits_way_en) report_mismatch("io_status_dup_3_s3_bits_way_en", 4'(g_io_status_dup_3_s3_bits_way_en), 4'(i_io_status_dup_3_s3_bits_way_en));
    if (g_io_status_dup_4_s1_valid !== i_io_status_dup_4_s1_valid) report_mismatch("io_status_dup_4_s1_valid", 1'(g_io_status_dup_4_s1_valid), 1'(i_io_status_dup_4_s1_valid));
    if (g_io_status_dup_4_s1_bits_set !== i_io_status_dup_4_s1_bits_set) report_mismatch("io_status_dup_4_s1_bits_set", 8'(g_io_status_dup_4_s1_bits_set), 8'(i_io_status_dup_4_s1_bits_set));
    if (g_io_status_dup_4_s1_bits_way_en !== i_io_status_dup_4_s1_bits_way_en) report_mismatch("io_status_dup_4_s1_bits_way_en", 4'(g_io_status_dup_4_s1_bits_way_en), 4'(i_io_status_dup_4_s1_bits_way_en));
    if (g_io_status_dup_4_s2_valid !== i_io_status_dup_4_s2_valid) report_mismatch("io_status_dup_4_s2_valid", 1'(g_io_status_dup_4_s2_valid), 1'(i_io_status_dup_4_s2_valid));
    if (g_io_status_dup_4_s2_bits_set !== i_io_status_dup_4_s2_bits_set) report_mismatch("io_status_dup_4_s2_bits_set", 8'(g_io_status_dup_4_s2_bits_set), 8'(i_io_status_dup_4_s2_bits_set));
    if (g_io_status_dup_4_s2_bits_way_en !== i_io_status_dup_4_s2_bits_way_en) report_mismatch("io_status_dup_4_s2_bits_way_en", 4'(g_io_status_dup_4_s2_bits_way_en), 4'(i_io_status_dup_4_s2_bits_way_en));
    if (g_io_status_dup_4_s3_valid !== i_io_status_dup_4_s3_valid) report_mismatch("io_status_dup_4_s3_valid", 1'(g_io_status_dup_4_s3_valid), 1'(i_io_status_dup_4_s3_valid));
    if (g_io_status_dup_4_s3_bits_set !== i_io_status_dup_4_s3_bits_set) report_mismatch("io_status_dup_4_s3_bits_set", 8'(g_io_status_dup_4_s3_bits_set), 8'(i_io_status_dup_4_s3_bits_set));
    if (g_io_status_dup_4_s3_bits_way_en !== i_io_status_dup_4_s3_bits_way_en) report_mismatch("io_status_dup_4_s3_bits_way_en", 4'(g_io_status_dup_4_s3_bits_way_en), 4'(i_io_status_dup_4_s3_bits_way_en));
    if (g_io_status_dup_5_s1_valid !== i_io_status_dup_5_s1_valid) report_mismatch("io_status_dup_5_s1_valid", 1'(g_io_status_dup_5_s1_valid), 1'(i_io_status_dup_5_s1_valid));
    if (g_io_status_dup_5_s1_bits_set !== i_io_status_dup_5_s1_bits_set) report_mismatch("io_status_dup_5_s1_bits_set", 8'(g_io_status_dup_5_s1_bits_set), 8'(i_io_status_dup_5_s1_bits_set));
    if (g_io_status_dup_5_s1_bits_way_en !== i_io_status_dup_5_s1_bits_way_en) report_mismatch("io_status_dup_5_s1_bits_way_en", 4'(g_io_status_dup_5_s1_bits_way_en), 4'(i_io_status_dup_5_s1_bits_way_en));
    if (g_io_status_dup_5_s2_valid !== i_io_status_dup_5_s2_valid) report_mismatch("io_status_dup_5_s2_valid", 1'(g_io_status_dup_5_s2_valid), 1'(i_io_status_dup_5_s2_valid));
    if (g_io_status_dup_5_s2_bits_set !== i_io_status_dup_5_s2_bits_set) report_mismatch("io_status_dup_5_s2_bits_set", 8'(g_io_status_dup_5_s2_bits_set), 8'(i_io_status_dup_5_s2_bits_set));
    if (g_io_status_dup_5_s2_bits_way_en !== i_io_status_dup_5_s2_bits_way_en) report_mismatch("io_status_dup_5_s2_bits_way_en", 4'(g_io_status_dup_5_s2_bits_way_en), 4'(i_io_status_dup_5_s2_bits_way_en));
    if (g_io_status_dup_5_s3_valid !== i_io_status_dup_5_s3_valid) report_mismatch("io_status_dup_5_s3_valid", 1'(g_io_status_dup_5_s3_valid), 1'(i_io_status_dup_5_s3_valid));
    if (g_io_status_dup_5_s3_bits_set !== i_io_status_dup_5_s3_bits_set) report_mismatch("io_status_dup_5_s3_bits_set", 8'(g_io_status_dup_5_s3_bits_set), 8'(i_io_status_dup_5_s3_bits_set));
    if (g_io_status_dup_5_s3_bits_way_en !== i_io_status_dup_5_s3_bits_way_en) report_mismatch("io_status_dup_5_s3_bits_way_en", 4'(g_io_status_dup_5_s3_bits_way_en), 4'(i_io_status_dup_5_s3_bits_way_en));
    if (g_io_status_dup_6_s1_valid !== i_io_status_dup_6_s1_valid) report_mismatch("io_status_dup_6_s1_valid", 1'(g_io_status_dup_6_s1_valid), 1'(i_io_status_dup_6_s1_valid));
    if (g_io_status_dup_6_s1_bits_set !== i_io_status_dup_6_s1_bits_set) report_mismatch("io_status_dup_6_s1_bits_set", 8'(g_io_status_dup_6_s1_bits_set), 8'(i_io_status_dup_6_s1_bits_set));
    if (g_io_status_dup_6_s1_bits_way_en !== i_io_status_dup_6_s1_bits_way_en) report_mismatch("io_status_dup_6_s1_bits_way_en", 4'(g_io_status_dup_6_s1_bits_way_en), 4'(i_io_status_dup_6_s1_bits_way_en));
    if (g_io_status_dup_6_s2_valid !== i_io_status_dup_6_s2_valid) report_mismatch("io_status_dup_6_s2_valid", 1'(g_io_status_dup_6_s2_valid), 1'(i_io_status_dup_6_s2_valid));
    if (g_io_status_dup_6_s2_bits_set !== i_io_status_dup_6_s2_bits_set) report_mismatch("io_status_dup_6_s2_bits_set", 8'(g_io_status_dup_6_s2_bits_set), 8'(i_io_status_dup_6_s2_bits_set));
    if (g_io_status_dup_6_s2_bits_way_en !== i_io_status_dup_6_s2_bits_way_en) report_mismatch("io_status_dup_6_s2_bits_way_en", 4'(g_io_status_dup_6_s2_bits_way_en), 4'(i_io_status_dup_6_s2_bits_way_en));
    if (g_io_status_dup_6_s3_valid !== i_io_status_dup_6_s3_valid) report_mismatch("io_status_dup_6_s3_valid", 1'(g_io_status_dup_6_s3_valid), 1'(i_io_status_dup_6_s3_valid));
    if (g_io_status_dup_6_s3_bits_set !== i_io_status_dup_6_s3_bits_set) report_mismatch("io_status_dup_6_s3_bits_set", 8'(g_io_status_dup_6_s3_bits_set), 8'(i_io_status_dup_6_s3_bits_set));
    if (g_io_status_dup_6_s3_bits_way_en !== i_io_status_dup_6_s3_bits_way_en) report_mismatch("io_status_dup_6_s3_bits_way_en", 4'(g_io_status_dup_6_s3_bits_way_en), 4'(i_io_status_dup_6_s3_bits_way_en));
    if (g_io_status_dup_7_s1_valid !== i_io_status_dup_7_s1_valid) report_mismatch("io_status_dup_7_s1_valid", 1'(g_io_status_dup_7_s1_valid), 1'(i_io_status_dup_7_s1_valid));
    if (g_io_status_dup_7_s1_bits_set !== i_io_status_dup_7_s1_bits_set) report_mismatch("io_status_dup_7_s1_bits_set", 8'(g_io_status_dup_7_s1_bits_set), 8'(i_io_status_dup_7_s1_bits_set));
    if (g_io_status_dup_7_s1_bits_way_en !== i_io_status_dup_7_s1_bits_way_en) report_mismatch("io_status_dup_7_s1_bits_way_en", 4'(g_io_status_dup_7_s1_bits_way_en), 4'(i_io_status_dup_7_s1_bits_way_en));
    if (g_io_status_dup_7_s2_valid !== i_io_status_dup_7_s2_valid) report_mismatch("io_status_dup_7_s2_valid", 1'(g_io_status_dup_7_s2_valid), 1'(i_io_status_dup_7_s2_valid));
    if (g_io_status_dup_7_s2_bits_set !== i_io_status_dup_7_s2_bits_set) report_mismatch("io_status_dup_7_s2_bits_set", 8'(g_io_status_dup_7_s2_bits_set), 8'(i_io_status_dup_7_s2_bits_set));
    if (g_io_status_dup_7_s2_bits_way_en !== i_io_status_dup_7_s2_bits_way_en) report_mismatch("io_status_dup_7_s2_bits_way_en", 4'(g_io_status_dup_7_s2_bits_way_en), 4'(i_io_status_dup_7_s2_bits_way_en));
    if (g_io_status_dup_7_s3_valid !== i_io_status_dup_7_s3_valid) report_mismatch("io_status_dup_7_s3_valid", 1'(g_io_status_dup_7_s3_valid), 1'(i_io_status_dup_7_s3_valid));
    if (g_io_status_dup_7_s3_bits_set !== i_io_status_dup_7_s3_bits_set) report_mismatch("io_status_dup_7_s3_bits_set", 8'(g_io_status_dup_7_s3_bits_set), 8'(i_io_status_dup_7_s3_bits_set));
    if (g_io_status_dup_7_s3_bits_way_en !== i_io_status_dup_7_s3_bits_way_en) report_mismatch("io_status_dup_7_s3_bits_way_en", 4'(g_io_status_dup_7_s3_bits_way_en), 4'(i_io_status_dup_7_s3_bits_way_en));
    if (g_io_status_dup_8_s1_valid !== i_io_status_dup_8_s1_valid) report_mismatch("io_status_dup_8_s1_valid", 1'(g_io_status_dup_8_s1_valid), 1'(i_io_status_dup_8_s1_valid));
    if (g_io_status_dup_8_s1_bits_set !== i_io_status_dup_8_s1_bits_set) report_mismatch("io_status_dup_8_s1_bits_set", 8'(g_io_status_dup_8_s1_bits_set), 8'(i_io_status_dup_8_s1_bits_set));
    if (g_io_status_dup_8_s1_bits_way_en !== i_io_status_dup_8_s1_bits_way_en) report_mismatch("io_status_dup_8_s1_bits_way_en", 4'(g_io_status_dup_8_s1_bits_way_en), 4'(i_io_status_dup_8_s1_bits_way_en));
    if (g_io_status_dup_8_s2_valid !== i_io_status_dup_8_s2_valid) report_mismatch("io_status_dup_8_s2_valid", 1'(g_io_status_dup_8_s2_valid), 1'(i_io_status_dup_8_s2_valid));
    if (g_io_status_dup_8_s2_bits_set !== i_io_status_dup_8_s2_bits_set) report_mismatch("io_status_dup_8_s2_bits_set", 8'(g_io_status_dup_8_s2_bits_set), 8'(i_io_status_dup_8_s2_bits_set));
    if (g_io_status_dup_8_s2_bits_way_en !== i_io_status_dup_8_s2_bits_way_en) report_mismatch("io_status_dup_8_s2_bits_way_en", 4'(g_io_status_dup_8_s2_bits_way_en), 4'(i_io_status_dup_8_s2_bits_way_en));
    if (g_io_status_dup_8_s3_valid !== i_io_status_dup_8_s3_valid) report_mismatch("io_status_dup_8_s3_valid", 1'(g_io_status_dup_8_s3_valid), 1'(i_io_status_dup_8_s3_valid));
    if (g_io_status_dup_8_s3_bits_set !== i_io_status_dup_8_s3_bits_set) report_mismatch("io_status_dup_8_s3_bits_set", 8'(g_io_status_dup_8_s3_bits_set), 8'(i_io_status_dup_8_s3_bits_set));
    if (g_io_status_dup_8_s3_bits_way_en !== i_io_status_dup_8_s3_bits_way_en) report_mismatch("io_status_dup_8_s3_bits_way_en", 4'(g_io_status_dup_8_s3_bits_way_en), 4'(i_io_status_dup_8_s3_bits_way_en));
    if (g_io_status_dup_9_s1_valid !== i_io_status_dup_9_s1_valid) report_mismatch("io_status_dup_9_s1_valid", 1'(g_io_status_dup_9_s1_valid), 1'(i_io_status_dup_9_s1_valid));
    if (g_io_status_dup_9_s1_bits_set !== i_io_status_dup_9_s1_bits_set) report_mismatch("io_status_dup_9_s1_bits_set", 8'(g_io_status_dup_9_s1_bits_set), 8'(i_io_status_dup_9_s1_bits_set));
    if (g_io_status_dup_9_s1_bits_way_en !== i_io_status_dup_9_s1_bits_way_en) report_mismatch("io_status_dup_9_s1_bits_way_en", 4'(g_io_status_dup_9_s1_bits_way_en), 4'(i_io_status_dup_9_s1_bits_way_en));
    if (g_io_status_dup_9_s2_valid !== i_io_status_dup_9_s2_valid) report_mismatch("io_status_dup_9_s2_valid", 1'(g_io_status_dup_9_s2_valid), 1'(i_io_status_dup_9_s2_valid));
    if (g_io_status_dup_9_s2_bits_set !== i_io_status_dup_9_s2_bits_set) report_mismatch("io_status_dup_9_s2_bits_set", 8'(g_io_status_dup_9_s2_bits_set), 8'(i_io_status_dup_9_s2_bits_set));
    if (g_io_status_dup_9_s2_bits_way_en !== i_io_status_dup_9_s2_bits_way_en) report_mismatch("io_status_dup_9_s2_bits_way_en", 4'(g_io_status_dup_9_s2_bits_way_en), 4'(i_io_status_dup_9_s2_bits_way_en));
    if (g_io_status_dup_9_s3_valid !== i_io_status_dup_9_s3_valid) report_mismatch("io_status_dup_9_s3_valid", 1'(g_io_status_dup_9_s3_valid), 1'(i_io_status_dup_9_s3_valid));
    if (g_io_status_dup_9_s3_bits_set !== i_io_status_dup_9_s3_bits_set) report_mismatch("io_status_dup_9_s3_bits_set", 8'(g_io_status_dup_9_s3_bits_set), 8'(i_io_status_dup_9_s3_bits_set));
    if (g_io_status_dup_9_s3_bits_way_en !== i_io_status_dup_9_s3_bits_way_en) report_mismatch("io_status_dup_9_s3_bits_way_en", 4'(g_io_status_dup_9_s3_bits_way_en), 4'(i_io_status_dup_9_s3_bits_way_en));
    if (g_io_status_dup_10_s1_valid !== i_io_status_dup_10_s1_valid) report_mismatch("io_status_dup_10_s1_valid", 1'(g_io_status_dup_10_s1_valid), 1'(i_io_status_dup_10_s1_valid));
    if (g_io_status_dup_10_s1_bits_set !== i_io_status_dup_10_s1_bits_set) report_mismatch("io_status_dup_10_s1_bits_set", 8'(g_io_status_dup_10_s1_bits_set), 8'(i_io_status_dup_10_s1_bits_set));
    if (g_io_status_dup_10_s1_bits_way_en !== i_io_status_dup_10_s1_bits_way_en) report_mismatch("io_status_dup_10_s1_bits_way_en", 4'(g_io_status_dup_10_s1_bits_way_en), 4'(i_io_status_dup_10_s1_bits_way_en));
    if (g_io_status_dup_10_s2_valid !== i_io_status_dup_10_s2_valid) report_mismatch("io_status_dup_10_s2_valid", 1'(g_io_status_dup_10_s2_valid), 1'(i_io_status_dup_10_s2_valid));
    if (g_io_status_dup_10_s2_bits_set !== i_io_status_dup_10_s2_bits_set) report_mismatch("io_status_dup_10_s2_bits_set", 8'(g_io_status_dup_10_s2_bits_set), 8'(i_io_status_dup_10_s2_bits_set));
    if (g_io_status_dup_10_s2_bits_way_en !== i_io_status_dup_10_s2_bits_way_en) report_mismatch("io_status_dup_10_s2_bits_way_en", 4'(g_io_status_dup_10_s2_bits_way_en), 4'(i_io_status_dup_10_s2_bits_way_en));
    if (g_io_status_dup_10_s3_valid !== i_io_status_dup_10_s3_valid) report_mismatch("io_status_dup_10_s3_valid", 1'(g_io_status_dup_10_s3_valid), 1'(i_io_status_dup_10_s3_valid));
    if (g_io_status_dup_10_s3_bits_set !== i_io_status_dup_10_s3_bits_set) report_mismatch("io_status_dup_10_s3_bits_set", 8'(g_io_status_dup_10_s3_bits_set), 8'(i_io_status_dup_10_s3_bits_set));
    if (g_io_status_dup_10_s3_bits_way_en !== i_io_status_dup_10_s3_bits_way_en) report_mismatch("io_status_dup_10_s3_bits_way_en", 4'(g_io_status_dup_10_s3_bits_way_en), 4'(i_io_status_dup_10_s3_bits_way_en));
    if (g_io_status_dup_11_s1_valid !== i_io_status_dup_11_s1_valid) report_mismatch("io_status_dup_11_s1_valid", 1'(g_io_status_dup_11_s1_valid), 1'(i_io_status_dup_11_s1_valid));
    if (g_io_status_dup_11_s1_bits_set !== i_io_status_dup_11_s1_bits_set) report_mismatch("io_status_dup_11_s1_bits_set", 8'(g_io_status_dup_11_s1_bits_set), 8'(i_io_status_dup_11_s1_bits_set));
    if (g_io_status_dup_11_s1_bits_way_en !== i_io_status_dup_11_s1_bits_way_en) report_mismatch("io_status_dup_11_s1_bits_way_en", 4'(g_io_status_dup_11_s1_bits_way_en), 4'(i_io_status_dup_11_s1_bits_way_en));
    if (g_io_status_dup_11_s2_valid !== i_io_status_dup_11_s2_valid) report_mismatch("io_status_dup_11_s2_valid", 1'(g_io_status_dup_11_s2_valid), 1'(i_io_status_dup_11_s2_valid));
    if (g_io_status_dup_11_s2_bits_set !== i_io_status_dup_11_s2_bits_set) report_mismatch("io_status_dup_11_s2_bits_set", 8'(g_io_status_dup_11_s2_bits_set), 8'(i_io_status_dup_11_s2_bits_set));
    if (g_io_status_dup_11_s2_bits_way_en !== i_io_status_dup_11_s2_bits_way_en) report_mismatch("io_status_dup_11_s2_bits_way_en", 4'(g_io_status_dup_11_s2_bits_way_en), 4'(i_io_status_dup_11_s2_bits_way_en));
    if (g_io_status_dup_11_s3_valid !== i_io_status_dup_11_s3_valid) report_mismatch("io_status_dup_11_s3_valid", 1'(g_io_status_dup_11_s3_valid), 1'(i_io_status_dup_11_s3_valid));
    if (g_io_status_dup_11_s3_bits_set !== i_io_status_dup_11_s3_bits_set) report_mismatch("io_status_dup_11_s3_bits_set", 8'(g_io_status_dup_11_s3_bits_set), 8'(i_io_status_dup_11_s3_bits_set));
    if (g_io_status_dup_11_s3_bits_way_en !== i_io_status_dup_11_s3_bits_way_en) report_mismatch("io_status_dup_11_s3_bits_way_en", 4'(g_io_status_dup_11_s3_bits_way_en), 4'(i_io_status_dup_11_s3_bits_way_en));
    if (g_io_status_dup_12_s1_valid !== i_io_status_dup_12_s1_valid) report_mismatch("io_status_dup_12_s1_valid", 1'(g_io_status_dup_12_s1_valid), 1'(i_io_status_dup_12_s1_valid));
    if (g_io_status_dup_12_s1_bits_set !== i_io_status_dup_12_s1_bits_set) report_mismatch("io_status_dup_12_s1_bits_set", 8'(g_io_status_dup_12_s1_bits_set), 8'(i_io_status_dup_12_s1_bits_set));
    if (g_io_status_dup_12_s1_bits_way_en !== i_io_status_dup_12_s1_bits_way_en) report_mismatch("io_status_dup_12_s1_bits_way_en", 4'(g_io_status_dup_12_s1_bits_way_en), 4'(i_io_status_dup_12_s1_bits_way_en));
    if (g_io_status_dup_12_s2_valid !== i_io_status_dup_12_s2_valid) report_mismatch("io_status_dup_12_s2_valid", 1'(g_io_status_dup_12_s2_valid), 1'(i_io_status_dup_12_s2_valid));
    if (g_io_status_dup_12_s2_bits_set !== i_io_status_dup_12_s2_bits_set) report_mismatch("io_status_dup_12_s2_bits_set", 8'(g_io_status_dup_12_s2_bits_set), 8'(i_io_status_dup_12_s2_bits_set));
    if (g_io_status_dup_12_s2_bits_way_en !== i_io_status_dup_12_s2_bits_way_en) report_mismatch("io_status_dup_12_s2_bits_way_en", 4'(g_io_status_dup_12_s2_bits_way_en), 4'(i_io_status_dup_12_s2_bits_way_en));
    if (g_io_status_dup_12_s3_valid !== i_io_status_dup_12_s3_valid) report_mismatch("io_status_dup_12_s3_valid", 1'(g_io_status_dup_12_s3_valid), 1'(i_io_status_dup_12_s3_valid));
    if (g_io_status_dup_12_s3_bits_set !== i_io_status_dup_12_s3_bits_set) report_mismatch("io_status_dup_12_s3_bits_set", 8'(g_io_status_dup_12_s3_bits_set), 8'(i_io_status_dup_12_s3_bits_set));
    if (g_io_status_dup_12_s3_bits_way_en !== i_io_status_dup_12_s3_bits_way_en) report_mismatch("io_status_dup_12_s3_bits_way_en", 4'(g_io_status_dup_12_s3_bits_way_en), 4'(i_io_status_dup_12_s3_bits_way_en));
    if (g_io_status_dup_13_s1_valid !== i_io_status_dup_13_s1_valid) report_mismatch("io_status_dup_13_s1_valid", 1'(g_io_status_dup_13_s1_valid), 1'(i_io_status_dup_13_s1_valid));
    if (g_io_status_dup_13_s1_bits_set !== i_io_status_dup_13_s1_bits_set) report_mismatch("io_status_dup_13_s1_bits_set", 8'(g_io_status_dup_13_s1_bits_set), 8'(i_io_status_dup_13_s1_bits_set));
    if (g_io_status_dup_13_s1_bits_way_en !== i_io_status_dup_13_s1_bits_way_en) report_mismatch("io_status_dup_13_s1_bits_way_en", 4'(g_io_status_dup_13_s1_bits_way_en), 4'(i_io_status_dup_13_s1_bits_way_en));
    if (g_io_status_dup_13_s2_valid !== i_io_status_dup_13_s2_valid) report_mismatch("io_status_dup_13_s2_valid", 1'(g_io_status_dup_13_s2_valid), 1'(i_io_status_dup_13_s2_valid));
    if (g_io_status_dup_13_s2_bits_set !== i_io_status_dup_13_s2_bits_set) report_mismatch("io_status_dup_13_s2_bits_set", 8'(g_io_status_dup_13_s2_bits_set), 8'(i_io_status_dup_13_s2_bits_set));
    if (g_io_status_dup_13_s2_bits_way_en !== i_io_status_dup_13_s2_bits_way_en) report_mismatch("io_status_dup_13_s2_bits_way_en", 4'(g_io_status_dup_13_s2_bits_way_en), 4'(i_io_status_dup_13_s2_bits_way_en));
    if (g_io_status_dup_13_s3_valid !== i_io_status_dup_13_s3_valid) report_mismatch("io_status_dup_13_s3_valid", 1'(g_io_status_dup_13_s3_valid), 1'(i_io_status_dup_13_s3_valid));
    if (g_io_status_dup_13_s3_bits_set !== i_io_status_dup_13_s3_bits_set) report_mismatch("io_status_dup_13_s3_bits_set", 8'(g_io_status_dup_13_s3_bits_set), 8'(i_io_status_dup_13_s3_bits_set));
    if (g_io_status_dup_13_s3_bits_way_en !== i_io_status_dup_13_s3_bits_way_en) report_mismatch("io_status_dup_13_s3_bits_way_en", 4'(g_io_status_dup_13_s3_bits_way_en), 4'(i_io_status_dup_13_s3_bits_way_en));
    if (g_io_status_dup_14_s1_valid !== i_io_status_dup_14_s1_valid) report_mismatch("io_status_dup_14_s1_valid", 1'(g_io_status_dup_14_s1_valid), 1'(i_io_status_dup_14_s1_valid));
    if (g_io_status_dup_14_s1_bits_set !== i_io_status_dup_14_s1_bits_set) report_mismatch("io_status_dup_14_s1_bits_set", 8'(g_io_status_dup_14_s1_bits_set), 8'(i_io_status_dup_14_s1_bits_set));
    if (g_io_status_dup_14_s1_bits_way_en !== i_io_status_dup_14_s1_bits_way_en) report_mismatch("io_status_dup_14_s1_bits_way_en", 4'(g_io_status_dup_14_s1_bits_way_en), 4'(i_io_status_dup_14_s1_bits_way_en));
    if (g_io_status_dup_14_s2_valid !== i_io_status_dup_14_s2_valid) report_mismatch("io_status_dup_14_s2_valid", 1'(g_io_status_dup_14_s2_valid), 1'(i_io_status_dup_14_s2_valid));
    if (g_io_status_dup_14_s2_bits_set !== i_io_status_dup_14_s2_bits_set) report_mismatch("io_status_dup_14_s2_bits_set", 8'(g_io_status_dup_14_s2_bits_set), 8'(i_io_status_dup_14_s2_bits_set));
    if (g_io_status_dup_14_s2_bits_way_en !== i_io_status_dup_14_s2_bits_way_en) report_mismatch("io_status_dup_14_s2_bits_way_en", 4'(g_io_status_dup_14_s2_bits_way_en), 4'(i_io_status_dup_14_s2_bits_way_en));
    if (g_io_status_dup_14_s3_valid !== i_io_status_dup_14_s3_valid) report_mismatch("io_status_dup_14_s3_valid", 1'(g_io_status_dup_14_s3_valid), 1'(i_io_status_dup_14_s3_valid));
    if (g_io_status_dup_14_s3_bits_set !== i_io_status_dup_14_s3_bits_set) report_mismatch("io_status_dup_14_s3_bits_set", 8'(g_io_status_dup_14_s3_bits_set), 8'(i_io_status_dup_14_s3_bits_set));
    if (g_io_status_dup_14_s3_bits_way_en !== i_io_status_dup_14_s3_bits_way_en) report_mismatch("io_status_dup_14_s3_bits_way_en", 4'(g_io_status_dup_14_s3_bits_way_en), 4'(i_io_status_dup_14_s3_bits_way_en));
    if (g_io_status_dup_15_s1_valid !== i_io_status_dup_15_s1_valid) report_mismatch("io_status_dup_15_s1_valid", 1'(g_io_status_dup_15_s1_valid), 1'(i_io_status_dup_15_s1_valid));
    if (g_io_status_dup_15_s1_bits_set !== i_io_status_dup_15_s1_bits_set) report_mismatch("io_status_dup_15_s1_bits_set", 8'(g_io_status_dup_15_s1_bits_set), 8'(i_io_status_dup_15_s1_bits_set));
    if (g_io_status_dup_15_s1_bits_way_en !== i_io_status_dup_15_s1_bits_way_en) report_mismatch("io_status_dup_15_s1_bits_way_en", 4'(g_io_status_dup_15_s1_bits_way_en), 4'(i_io_status_dup_15_s1_bits_way_en));
    if (g_io_status_dup_15_s2_valid !== i_io_status_dup_15_s2_valid) report_mismatch("io_status_dup_15_s2_valid", 1'(g_io_status_dup_15_s2_valid), 1'(i_io_status_dup_15_s2_valid));
    if (g_io_status_dup_15_s2_bits_set !== i_io_status_dup_15_s2_bits_set) report_mismatch("io_status_dup_15_s2_bits_set", 8'(g_io_status_dup_15_s2_bits_set), 8'(i_io_status_dup_15_s2_bits_set));
    if (g_io_status_dup_15_s2_bits_way_en !== i_io_status_dup_15_s2_bits_way_en) report_mismatch("io_status_dup_15_s2_bits_way_en", 4'(g_io_status_dup_15_s2_bits_way_en), 4'(i_io_status_dup_15_s2_bits_way_en));
    if (g_io_status_dup_15_s3_valid !== i_io_status_dup_15_s3_valid) report_mismatch("io_status_dup_15_s3_valid", 1'(g_io_status_dup_15_s3_valid), 1'(i_io_status_dup_15_s3_valid));
    if (g_io_status_dup_15_s3_bits_set !== i_io_status_dup_15_s3_bits_set) report_mismatch("io_status_dup_15_s3_bits_set", 8'(g_io_status_dup_15_s3_bits_set), 8'(i_io_status_dup_15_s3_bits_set));
    if (g_io_status_dup_15_s3_bits_way_en !== i_io_status_dup_15_s3_bits_way_en) report_mismatch("io_status_dup_15_s3_bits_way_en", 4'(g_io_status_dup_15_s3_bits_way_en), 4'(i_io_status_dup_15_s3_bits_way_en));
    if (g_io_status_dup_16_s1_valid !== i_io_status_dup_16_s1_valid) report_mismatch("io_status_dup_16_s1_valid", 1'(g_io_status_dup_16_s1_valid), 1'(i_io_status_dup_16_s1_valid));
    if (g_io_status_dup_16_s1_bits_set !== i_io_status_dup_16_s1_bits_set) report_mismatch("io_status_dup_16_s1_bits_set", 8'(g_io_status_dup_16_s1_bits_set), 8'(i_io_status_dup_16_s1_bits_set));
    if (g_io_status_dup_16_s1_bits_way_en !== i_io_status_dup_16_s1_bits_way_en) report_mismatch("io_status_dup_16_s1_bits_way_en", 4'(g_io_status_dup_16_s1_bits_way_en), 4'(i_io_status_dup_16_s1_bits_way_en));
    if (g_io_status_dup_16_s2_valid !== i_io_status_dup_16_s2_valid) report_mismatch("io_status_dup_16_s2_valid", 1'(g_io_status_dup_16_s2_valid), 1'(i_io_status_dup_16_s2_valid));
    if (g_io_status_dup_16_s2_bits_set !== i_io_status_dup_16_s2_bits_set) report_mismatch("io_status_dup_16_s2_bits_set", 8'(g_io_status_dup_16_s2_bits_set), 8'(i_io_status_dup_16_s2_bits_set));
    if (g_io_status_dup_16_s2_bits_way_en !== i_io_status_dup_16_s2_bits_way_en) report_mismatch("io_status_dup_16_s2_bits_way_en", 4'(g_io_status_dup_16_s2_bits_way_en), 4'(i_io_status_dup_16_s2_bits_way_en));
    if (g_io_status_dup_16_s3_valid !== i_io_status_dup_16_s3_valid) report_mismatch("io_status_dup_16_s3_valid", 1'(g_io_status_dup_16_s3_valid), 1'(i_io_status_dup_16_s3_valid));
    if (g_io_status_dup_16_s3_bits_set !== i_io_status_dup_16_s3_bits_set) report_mismatch("io_status_dup_16_s3_bits_set", 8'(g_io_status_dup_16_s3_bits_set), 8'(i_io_status_dup_16_s3_bits_set));
    if (g_io_status_dup_16_s3_bits_way_en !== i_io_status_dup_16_s3_bits_way_en) report_mismatch("io_status_dup_16_s3_bits_way_en", 4'(g_io_status_dup_16_s3_bits_way_en), 4'(i_io_status_dup_16_s3_bits_way_en));
    if (g_io_status_dup_17_s1_valid !== i_io_status_dup_17_s1_valid) report_mismatch("io_status_dup_17_s1_valid", 1'(g_io_status_dup_17_s1_valid), 1'(i_io_status_dup_17_s1_valid));
    if (g_io_status_dup_17_s1_bits_set !== i_io_status_dup_17_s1_bits_set) report_mismatch("io_status_dup_17_s1_bits_set", 8'(g_io_status_dup_17_s1_bits_set), 8'(i_io_status_dup_17_s1_bits_set));
    if (g_io_status_dup_17_s1_bits_way_en !== i_io_status_dup_17_s1_bits_way_en) report_mismatch("io_status_dup_17_s1_bits_way_en", 4'(g_io_status_dup_17_s1_bits_way_en), 4'(i_io_status_dup_17_s1_bits_way_en));
    if (g_io_status_dup_17_s2_valid !== i_io_status_dup_17_s2_valid) report_mismatch("io_status_dup_17_s2_valid", 1'(g_io_status_dup_17_s2_valid), 1'(i_io_status_dup_17_s2_valid));
    if (g_io_status_dup_17_s2_bits_set !== i_io_status_dup_17_s2_bits_set) report_mismatch("io_status_dup_17_s2_bits_set", 8'(g_io_status_dup_17_s2_bits_set), 8'(i_io_status_dup_17_s2_bits_set));
    if (g_io_status_dup_17_s2_bits_way_en !== i_io_status_dup_17_s2_bits_way_en) report_mismatch("io_status_dup_17_s2_bits_way_en", 4'(g_io_status_dup_17_s2_bits_way_en), 4'(i_io_status_dup_17_s2_bits_way_en));
    if (g_io_status_dup_17_s3_valid !== i_io_status_dup_17_s3_valid) report_mismatch("io_status_dup_17_s3_valid", 1'(g_io_status_dup_17_s3_valid), 1'(i_io_status_dup_17_s3_valid));
    if (g_io_status_dup_17_s3_bits_set !== i_io_status_dup_17_s3_bits_set) report_mismatch("io_status_dup_17_s3_bits_set", 8'(g_io_status_dup_17_s3_bits_set), 8'(i_io_status_dup_17_s3_bits_set));
    if (g_io_status_dup_17_s3_bits_way_en !== i_io_status_dup_17_s3_bits_way_en) report_mismatch("io_status_dup_17_s3_bits_way_en", 4'(g_io_status_dup_17_s3_bits_way_en), 4'(i_io_status_dup_17_s3_bits_way_en));
    if (g_io_status_dup_18_s1_valid !== i_io_status_dup_18_s1_valid) report_mismatch("io_status_dup_18_s1_valid", 1'(g_io_status_dup_18_s1_valid), 1'(i_io_status_dup_18_s1_valid));
    if (g_io_status_dup_18_s1_bits_set !== i_io_status_dup_18_s1_bits_set) report_mismatch("io_status_dup_18_s1_bits_set", 8'(g_io_status_dup_18_s1_bits_set), 8'(i_io_status_dup_18_s1_bits_set));
    if (g_io_status_dup_18_s1_bits_way_en !== i_io_status_dup_18_s1_bits_way_en) report_mismatch("io_status_dup_18_s1_bits_way_en", 4'(g_io_status_dup_18_s1_bits_way_en), 4'(i_io_status_dup_18_s1_bits_way_en));
    if (g_io_status_dup_18_s2_valid !== i_io_status_dup_18_s2_valid) report_mismatch("io_status_dup_18_s2_valid", 1'(g_io_status_dup_18_s2_valid), 1'(i_io_status_dup_18_s2_valid));
    if (g_io_status_dup_18_s2_bits_set !== i_io_status_dup_18_s2_bits_set) report_mismatch("io_status_dup_18_s2_bits_set", 8'(g_io_status_dup_18_s2_bits_set), 8'(i_io_status_dup_18_s2_bits_set));
    if (g_io_status_dup_18_s2_bits_way_en !== i_io_status_dup_18_s2_bits_way_en) report_mismatch("io_status_dup_18_s2_bits_way_en", 4'(g_io_status_dup_18_s2_bits_way_en), 4'(i_io_status_dup_18_s2_bits_way_en));
    if (g_io_status_dup_18_s3_valid !== i_io_status_dup_18_s3_valid) report_mismatch("io_status_dup_18_s3_valid", 1'(g_io_status_dup_18_s3_valid), 1'(i_io_status_dup_18_s3_valid));
    if (g_io_status_dup_18_s3_bits_set !== i_io_status_dup_18_s3_bits_set) report_mismatch("io_status_dup_18_s3_bits_set", 8'(g_io_status_dup_18_s3_bits_set), 8'(i_io_status_dup_18_s3_bits_set));
    if (g_io_status_dup_18_s3_bits_way_en !== i_io_status_dup_18_s3_bits_way_en) report_mismatch("io_status_dup_18_s3_bits_way_en", 4'(g_io_status_dup_18_s3_bits_way_en), 4'(i_io_status_dup_18_s3_bits_way_en));
    if (g_io_status_dup_19_s1_valid !== i_io_status_dup_19_s1_valid) report_mismatch("io_status_dup_19_s1_valid", 1'(g_io_status_dup_19_s1_valid), 1'(i_io_status_dup_19_s1_valid));
    if (g_io_status_dup_19_s1_bits_set !== i_io_status_dup_19_s1_bits_set) report_mismatch("io_status_dup_19_s1_bits_set", 8'(g_io_status_dup_19_s1_bits_set), 8'(i_io_status_dup_19_s1_bits_set));
    if (g_io_status_dup_19_s1_bits_way_en !== i_io_status_dup_19_s1_bits_way_en) report_mismatch("io_status_dup_19_s1_bits_way_en", 4'(g_io_status_dup_19_s1_bits_way_en), 4'(i_io_status_dup_19_s1_bits_way_en));
    if (g_io_status_dup_19_s2_valid !== i_io_status_dup_19_s2_valid) report_mismatch("io_status_dup_19_s2_valid", 1'(g_io_status_dup_19_s2_valid), 1'(i_io_status_dup_19_s2_valid));
    if (g_io_status_dup_19_s2_bits_set !== i_io_status_dup_19_s2_bits_set) report_mismatch("io_status_dup_19_s2_bits_set", 8'(g_io_status_dup_19_s2_bits_set), 8'(i_io_status_dup_19_s2_bits_set));
    if (g_io_status_dup_19_s2_bits_way_en !== i_io_status_dup_19_s2_bits_way_en) report_mismatch("io_status_dup_19_s2_bits_way_en", 4'(g_io_status_dup_19_s2_bits_way_en), 4'(i_io_status_dup_19_s2_bits_way_en));
    if (g_io_status_dup_19_s3_valid !== i_io_status_dup_19_s3_valid) report_mismatch("io_status_dup_19_s3_valid", 1'(g_io_status_dup_19_s3_valid), 1'(i_io_status_dup_19_s3_valid));
    if (g_io_status_dup_19_s3_bits_set !== i_io_status_dup_19_s3_bits_set) report_mismatch("io_status_dup_19_s3_bits_set", 8'(g_io_status_dup_19_s3_bits_set), 8'(i_io_status_dup_19_s3_bits_set));
    if (g_io_status_dup_19_s3_bits_way_en !== i_io_status_dup_19_s3_bits_way_en) report_mismatch("io_status_dup_19_s3_bits_way_en", 4'(g_io_status_dup_19_s3_bits_way_en), 4'(i_io_status_dup_19_s3_bits_way_en));
    if (g_io_status_dup_20_s1_valid !== i_io_status_dup_20_s1_valid) report_mismatch("io_status_dup_20_s1_valid", 1'(g_io_status_dup_20_s1_valid), 1'(i_io_status_dup_20_s1_valid));
    if (g_io_status_dup_20_s1_bits_set !== i_io_status_dup_20_s1_bits_set) report_mismatch("io_status_dup_20_s1_bits_set", 8'(g_io_status_dup_20_s1_bits_set), 8'(i_io_status_dup_20_s1_bits_set));
    if (g_io_status_dup_20_s1_bits_way_en !== i_io_status_dup_20_s1_bits_way_en) report_mismatch("io_status_dup_20_s1_bits_way_en", 4'(g_io_status_dup_20_s1_bits_way_en), 4'(i_io_status_dup_20_s1_bits_way_en));
    if (g_io_status_dup_20_s2_valid !== i_io_status_dup_20_s2_valid) report_mismatch("io_status_dup_20_s2_valid", 1'(g_io_status_dup_20_s2_valid), 1'(i_io_status_dup_20_s2_valid));
    if (g_io_status_dup_20_s2_bits_set !== i_io_status_dup_20_s2_bits_set) report_mismatch("io_status_dup_20_s2_bits_set", 8'(g_io_status_dup_20_s2_bits_set), 8'(i_io_status_dup_20_s2_bits_set));
    if (g_io_status_dup_20_s2_bits_way_en !== i_io_status_dup_20_s2_bits_way_en) report_mismatch("io_status_dup_20_s2_bits_way_en", 4'(g_io_status_dup_20_s2_bits_way_en), 4'(i_io_status_dup_20_s2_bits_way_en));
    if (g_io_status_dup_20_s3_valid !== i_io_status_dup_20_s3_valid) report_mismatch("io_status_dup_20_s3_valid", 1'(g_io_status_dup_20_s3_valid), 1'(i_io_status_dup_20_s3_valid));
    if (g_io_status_dup_20_s3_bits_set !== i_io_status_dup_20_s3_bits_set) report_mismatch("io_status_dup_20_s3_bits_set", 8'(g_io_status_dup_20_s3_bits_set), 8'(i_io_status_dup_20_s3_bits_set));
    if (g_io_status_dup_20_s3_bits_way_en !== i_io_status_dup_20_s3_bits_way_en) report_mismatch("io_status_dup_20_s3_bits_way_en", 4'(g_io_status_dup_20_s3_bits_way_en), 4'(i_io_status_dup_20_s3_bits_way_en));
    if (g_io_status_dup_21_s1_valid !== i_io_status_dup_21_s1_valid) report_mismatch("io_status_dup_21_s1_valid", 1'(g_io_status_dup_21_s1_valid), 1'(i_io_status_dup_21_s1_valid));
    if (g_io_status_dup_21_s1_bits_set !== i_io_status_dup_21_s1_bits_set) report_mismatch("io_status_dup_21_s1_bits_set", 8'(g_io_status_dup_21_s1_bits_set), 8'(i_io_status_dup_21_s1_bits_set));
    if (g_io_status_dup_21_s1_bits_way_en !== i_io_status_dup_21_s1_bits_way_en) report_mismatch("io_status_dup_21_s1_bits_way_en", 4'(g_io_status_dup_21_s1_bits_way_en), 4'(i_io_status_dup_21_s1_bits_way_en));
    if (g_io_status_dup_21_s2_valid !== i_io_status_dup_21_s2_valid) report_mismatch("io_status_dup_21_s2_valid", 1'(g_io_status_dup_21_s2_valid), 1'(i_io_status_dup_21_s2_valid));
    if (g_io_status_dup_21_s2_bits_set !== i_io_status_dup_21_s2_bits_set) report_mismatch("io_status_dup_21_s2_bits_set", 8'(g_io_status_dup_21_s2_bits_set), 8'(i_io_status_dup_21_s2_bits_set));
    if (g_io_status_dup_21_s2_bits_way_en !== i_io_status_dup_21_s2_bits_way_en) report_mismatch("io_status_dup_21_s2_bits_way_en", 4'(g_io_status_dup_21_s2_bits_way_en), 4'(i_io_status_dup_21_s2_bits_way_en));
    if (g_io_status_dup_21_s3_valid !== i_io_status_dup_21_s3_valid) report_mismatch("io_status_dup_21_s3_valid", 1'(g_io_status_dup_21_s3_valid), 1'(i_io_status_dup_21_s3_valid));
    if (g_io_status_dup_21_s3_bits_set !== i_io_status_dup_21_s3_bits_set) report_mismatch("io_status_dup_21_s3_bits_set", 8'(g_io_status_dup_21_s3_bits_set), 8'(i_io_status_dup_21_s3_bits_set));
    if (g_io_status_dup_21_s3_bits_way_en !== i_io_status_dup_21_s3_bits_way_en) report_mismatch("io_status_dup_21_s3_bits_way_en", 4'(g_io_status_dup_21_s3_bits_way_en), 4'(i_io_status_dup_21_s3_bits_way_en));
    if (g_io_status_dup_22_s1_valid !== i_io_status_dup_22_s1_valid) report_mismatch("io_status_dup_22_s1_valid", 1'(g_io_status_dup_22_s1_valid), 1'(i_io_status_dup_22_s1_valid));
    if (g_io_status_dup_22_s1_bits_set !== i_io_status_dup_22_s1_bits_set) report_mismatch("io_status_dup_22_s1_bits_set", 8'(g_io_status_dup_22_s1_bits_set), 8'(i_io_status_dup_22_s1_bits_set));
    if (g_io_status_dup_22_s1_bits_way_en !== i_io_status_dup_22_s1_bits_way_en) report_mismatch("io_status_dup_22_s1_bits_way_en", 4'(g_io_status_dup_22_s1_bits_way_en), 4'(i_io_status_dup_22_s1_bits_way_en));
    if (g_io_status_dup_22_s2_valid !== i_io_status_dup_22_s2_valid) report_mismatch("io_status_dup_22_s2_valid", 1'(g_io_status_dup_22_s2_valid), 1'(i_io_status_dup_22_s2_valid));
    if (g_io_status_dup_22_s2_bits_set !== i_io_status_dup_22_s2_bits_set) report_mismatch("io_status_dup_22_s2_bits_set", 8'(g_io_status_dup_22_s2_bits_set), 8'(i_io_status_dup_22_s2_bits_set));
    if (g_io_status_dup_22_s2_bits_way_en !== i_io_status_dup_22_s2_bits_way_en) report_mismatch("io_status_dup_22_s2_bits_way_en", 4'(g_io_status_dup_22_s2_bits_way_en), 4'(i_io_status_dup_22_s2_bits_way_en));
    if (g_io_status_dup_22_s3_valid !== i_io_status_dup_22_s3_valid) report_mismatch("io_status_dup_22_s3_valid", 1'(g_io_status_dup_22_s3_valid), 1'(i_io_status_dup_22_s3_valid));
    if (g_io_status_dup_22_s3_bits_set !== i_io_status_dup_22_s3_bits_set) report_mismatch("io_status_dup_22_s3_bits_set", 8'(g_io_status_dup_22_s3_bits_set), 8'(i_io_status_dup_22_s3_bits_set));
    if (g_io_status_dup_22_s3_bits_way_en !== i_io_status_dup_22_s3_bits_way_en) report_mismatch("io_status_dup_22_s3_bits_way_en", 4'(g_io_status_dup_22_s3_bits_way_en), 4'(i_io_status_dup_22_s3_bits_way_en));
    if (g_io_status_dup_23_s1_valid !== i_io_status_dup_23_s1_valid) report_mismatch("io_status_dup_23_s1_valid", 1'(g_io_status_dup_23_s1_valid), 1'(i_io_status_dup_23_s1_valid));
    if (g_io_status_dup_23_s1_bits_set !== i_io_status_dup_23_s1_bits_set) report_mismatch("io_status_dup_23_s1_bits_set", 8'(g_io_status_dup_23_s1_bits_set), 8'(i_io_status_dup_23_s1_bits_set));
    if (g_io_status_dup_23_s1_bits_way_en !== i_io_status_dup_23_s1_bits_way_en) report_mismatch("io_status_dup_23_s1_bits_way_en", 4'(g_io_status_dup_23_s1_bits_way_en), 4'(i_io_status_dup_23_s1_bits_way_en));
    if (g_io_status_dup_23_s2_valid !== i_io_status_dup_23_s2_valid) report_mismatch("io_status_dup_23_s2_valid", 1'(g_io_status_dup_23_s2_valid), 1'(i_io_status_dup_23_s2_valid));
    if (g_io_status_dup_23_s2_bits_set !== i_io_status_dup_23_s2_bits_set) report_mismatch("io_status_dup_23_s2_bits_set", 8'(g_io_status_dup_23_s2_bits_set), 8'(i_io_status_dup_23_s2_bits_set));
    if (g_io_status_dup_23_s2_bits_way_en !== i_io_status_dup_23_s2_bits_way_en) report_mismatch("io_status_dup_23_s2_bits_way_en", 4'(g_io_status_dup_23_s2_bits_way_en), 4'(i_io_status_dup_23_s2_bits_way_en));
    if (g_io_status_dup_23_s3_valid !== i_io_status_dup_23_s3_valid) report_mismatch("io_status_dup_23_s3_valid", 1'(g_io_status_dup_23_s3_valid), 1'(i_io_status_dup_23_s3_valid));
    if (g_io_status_dup_23_s3_bits_set !== i_io_status_dup_23_s3_bits_set) report_mismatch("io_status_dup_23_s3_bits_set", 8'(g_io_status_dup_23_s3_bits_set), 8'(i_io_status_dup_23_s3_bits_set));
    if (g_io_status_dup_23_s3_bits_way_en !== i_io_status_dup_23_s3_bits_way_en) report_mismatch("io_status_dup_23_s3_bits_way_en", 4'(g_io_status_dup_23_s3_bits_way_en), 4'(i_io_status_dup_23_s3_bits_way_en));
    if (g_io_lrsc_locked_block_valid !== i_io_lrsc_locked_block_valid) report_mismatch("io_lrsc_locked_block_valid", 1'(g_io_lrsc_locked_block_valid), 1'(i_io_lrsc_locked_block_valid));
    if (g_io_lrsc_locked_block_bits !== i_io_lrsc_locked_block_bits) report_mismatch("io_lrsc_locked_block_bits", 48'(g_io_lrsc_locked_block_bits), 48'(i_io_lrsc_locked_block_bits));
    if (g_io_update_resv_set !== i_io_update_resv_set) report_mismatch("io_update_resv_set", 1'(g_io_update_resv_set), 1'(i_io_update_resv_set));
    if (g_io_block_lr !== i_io_block_lr) report_mismatch("io_block_lr", 1'(g_io_block_lr), 1'(i_io_block_lr));
    if (g_io_error_valid !== i_io_error_valid) report_mismatch("io_error_valid", 1'(g_io_error_valid), 1'(i_io_error_valid));
    if (g_io_error_bits_paddr !== i_io_error_bits_paddr) report_mismatch("io_error_bits_paddr", 48'(g_io_error_bits_paddr), 48'(i_io_error_bits_paddr));
    if (g_io_error_bits_report_to_beu !== i_io_error_bits_report_to_beu) report_mismatch("io_error_bits_report_to_beu", 1'(g_io_error_bits_report_to_beu), 1'(i_io_error_bits_report_to_beu));
    if (g_io_pseudo_tag_error_inj_done !== i_io_pseudo_tag_error_inj_done) report_mismatch("io_pseudo_tag_error_inj_done", 1'(g_io_pseudo_tag_error_inj_done), 1'(i_io_pseudo_tag_error_inj_done));
    if (g_io_pseudo_data_error_inj_done !== i_io_pseudo_data_error_inj_done) report_mismatch("io_pseudo_data_error_inj_done", 1'(g_io_pseudo_data_error_inj_done), 1'(i_io_pseudo_data_error_inj_done));
    if (g_io_bloom_filter_query_set_valid !== i_io_bloom_filter_query_set_valid) report_mismatch("io_bloom_filter_query_set_valid", 1'(g_io_bloom_filter_query_set_valid), 1'(i_io_bloom_filter_query_set_valid));
    if (g_io_bloom_filter_query_set_bits_addr !== i_io_bloom_filter_query_set_bits_addr) report_mismatch("io_bloom_filter_query_set_bits_addr", 12'(g_io_bloom_filter_query_set_bits_addr), 12'(i_io_bloom_filter_query_set_bits_addr));
    if (g_io_bloom_filter_query_clr_valid !== i_io_bloom_filter_query_clr_valid) report_mismatch("io_bloom_filter_query_clr_valid", 1'(g_io_bloom_filter_query_clr_valid), 1'(i_io_bloom_filter_query_clr_valid));
    if (g_io_bloom_filter_query_clr_bits_addr !== i_io_bloom_filter_query_clr_bits_addr) report_mismatch("io_bloom_filter_query_clr_bits_addr", 12'(g_io_bloom_filter_query_clr_bits_addr), 12'(i_io_bloom_filter_query_clr_bits_addr));
    if (g_io_perf_0_value !== i_io_perf_0_value) report_mismatch("io_perf_0_value", 6'(g_io_perf_0_value), 6'(i_io_perf_0_value));
    if (g_io_perf_1_value !== i_io_perf_1_value) report_mismatch("io_perf_1_value", 6'(g_io_perf_1_value), 6'(i_io_perf_1_value));
    if (g_io_perf_2_value !== i_io_perf_2_value) report_mismatch("io_perf_2_value", 6'(g_io_perf_2_value), 6'(i_io_perf_2_value));
    if (g_io_perf_3_value !== i_io_perf_3_value) report_mismatch("io_perf_3_value", 6'(g_io_perf_3_value), 6'(i_io_perf_3_value));
  endtask
  // END GENERATED

  // -------------------------------------------------------------------
  // tag 的 SECDED 编码（与 utility/ECC.scala SECDEDCode 相同的算法）
  // -------------------------------------------------------------------
  function automatic logic [41:0] syn_mask(input int unsigned j);
    logic [41:0] m;
    int unsigned d, s;
    m = '0; d = 0;
    for (int unsigned pos = 1; pos <= 42; pos++) begin
      if ((pos & (pos - 1)) == 0) s = 36 + $clog2(pos);
      else begin s = d; d++; end
      if (((pos >> j) & 1) != 0) m[s] = 1'b1;
    end
    return m;
  endfunction

  function automatic logic [42:0] secded_encode(input logic [35:0] tag);
    logic [41:0] sec;
    sec[35:0] = tag;
    for (int j = 0; j < 6; j++)
      sec[36 + j] = ^(syn_mask(j)[35:0] & tag);
    return {^sec, sec};
  endfunction

  // -------------------------------------------------------------------
  // 地址池
  // -------------------------------------------------------------------
  logic [35:0] tag_pool [4];
  logic [7:0]  set_pool [4];
  initial begin
    tag_pool[0] = 36'h0_1234_5678; tag_pool[1] = 36'h8_9ABC_DEF0;
    tag_pool[2] = 36'h0_0000_0001; tag_pool[3] = 36'hF_FFFF_FFFE;
    set_pool[0] = 8'h00; set_pool[1] = 8'h3C; set_pool[2] = 8'hC3; set_pool[3] = 8'hFF;
  end

  function automatic int pick(input int unsigned n);
    return $urandom_range(0, n - 1);
  endfunction

  // 行地址：vaddr[13:6] = set，vaddr[5:0] 随机；paddr[47:12] = tag，paddr[11:6] 取 4 个行号
  function automatic logic [49:0] mk_vaddr(input logic [7:0] set);
    logic [49:0] v;
    v = {$urandom, $urandom};
    v[13:6] = set;
    return v;
  endfunction

  function automatic logic [47:0] mk_paddr(input logic [35:0] tag, input logic [7:0] set);
    logic [47:0] p;
    p = {$urandom, $urandom};
    p[47:12] = tag;
    p[11:6]  = {set[1:0], 2'b00, 2'(pick(4))};
    return p;
  endfunction

  function automatic logic [4:0] amo_cmd();
    int r = pick(20);
    case (r)
      0, 1, 2, 3: return 5'h06;        // LR
      4, 5, 6, 7: return 5'h07;        // SC
      8:          return 5'h04;        // SWAP
      9:          return 5'h08;        // ADD
      10:         return 5'h09;        // XOR
      11:         return 5'h0A;        // OR
      12:         return 5'h0B;        // AND
      13:         return 5'h0C;        // MIN
      14:         return 5'h0D;        // MAX
      15:         return 5'h0E;        // MINU
      16:         return 5'h0F;        // MAXU
      17:         return 5'h1A;        // CAS.W
      18:         return 5'h1B;        // CAS.D
      default:    return 5'h18;        // CAS.Q
    endcase
  endfunction

  function automatic logic [15:0] amo_mask_for(input logic [4:0] cmd);
    int r = pick(8);
    if (cmd == 5'h18) return 16'hFFFF;
    if (r < 4) return 16'h00FF;
    if (r < 6) return 16'h000F;
    if (r < 7) return 16'h00F0;
    return 16'($urandom);
  endfunction

  function automatic logic [63:0] store_mask_rand();
    int r = pick(6);
    logic [63:0] m;
    case (r)
      0: m = '1;                                   // 整行
      1: m = {$urandom, $urandom};                 // 乱
      2: m = 64'h0000_0000_0000_00FF << (8 * pick(8));    // 单 bank 满写
      3: m = 64'h0000_0000_0000_000F << (4 * pick(16));   // 半 bank
      4: m = {{$urandom, $urandom}} & {{$urandom, $urandom}};
      default: m = 64'h0;
    endcase
    return m;
  endfunction

  // -------------------------------------------------------------------
  // 请求源（挂起请求：valid 保持到握手）
  // -------------------------------------------------------------------
  task automatic new_probe();
    int t = pick(4), s = pick(4);
    io_probe_req_valid             = ($urandom_range(0, 99) < 6);
    io_probe_req_bits_probe_param  = ($urandom_range(0, 19) == 0) ? 2'd3 : 2'(pick(3));
    io_probe_req_bits_probe_need_data = 1'($urandom);
    io_probe_req_bits_vaddr        = mk_vaddr(set_pool[s]);
    io_probe_req_bits_addr         = mk_paddr(tag_pool[t], set_pool[s]);
    io_probe_req_bits_id           = 6'($urandom);
  endtask

  task automatic new_refill();
    int t = pick(4), s = pick(4), src = pick(6);
    io_refill_req_valid                        = ($urandom_range(0, 99) < 10);
    io_refill_req_bits_miss_id                 = 4'($urandom);
    io_refill_req_bits_occupy_way              = 4'b0001 << pick(4);
    io_refill_req_bits_miss_fail_cause_evict_btot = ($urandom_range(0, 9) == 0);
    io_refill_req_bits_source                  = (src < 2) ? 4'd1 : (src < 4) ? 4'd2 : (src < 5) ? 4'd0 : 4'($urandom);
    io_refill_req_bits_cmd                     = (io_refill_req_bits_source == 4'd1) ? ((pick(4) == 0) ? 5'h11 : 5'h01) :
                                                 (io_refill_req_bits_source == 4'd2) ? amo_cmd() :
                                                 (pick(3) == 0) ? 5'h03 : 5'(pick(3));
    io_refill_req_bits_vaddr                   = mk_vaddr(set_pool[s]);
    io_refill_req_bits_addr                    = mk_paddr(tag_pool[t], set_pool[s]);
    io_refill_req_bits_word_idx                = 3'($urandom);
    io_refill_req_bits_amo_data                = {$urandom, $urandom, $urandom, $urandom};
    io_refill_req_bits_amo_mask                = amo_mask_for(io_refill_req_bits_cmd);
    io_refill_req_bits_amo_cmp                 = {$urandom, $urandom, $urandom, $urandom};
    io_refill_req_bits_pf_source               = 3'($urandom);
    io_refill_req_bits_access                  = 1'($urandom);
    io_refill_req_bits_id                      = 6'($urandom);
  endtask

  task automatic new_store();
    int t = pick(4), s = pick(4);
    io_store_req_valid      = ($urandom_range(0, 99) < 40);
    io_store_req_bits_vaddr = mk_vaddr(set_pool[s]);
    io_store_req_bits_addr  = mk_paddr(tag_pool[t], set_pool[s]);
    for (int k = 0; k < 16; k++) io_store_req_bits_data[k*32 +: 32] = $urandom;
    io_store_req_bits_mask  = store_mask_rand();
    io_store_req_bits_id    = 6'($urandom);
  endtask

  // 最近一次 LR 的地址：SC/LR 有一半概率打同一个块（让 SC 能成功）
  logic [49:0] last_lr_vaddr;
  logic [47:0] last_lr_paddr;
  task automatic new_atomic();
    int t = pick(4), s = pick(4);
    io_atomic_req_valid         = ($urandom_range(0, 99) < 40);
    io_atomic_req_bits_cmd      = amo_cmd();
    io_atomic_req_bits_vaddr    = mk_vaddr(set_pool[s]);
    io_atomic_req_bits_addr     = mk_paddr(tag_pool[t], set_pool[s]);
    if ((io_atomic_req_bits_cmd == 5'h07 || io_atomic_req_bits_cmd == 5'h06) && pick(2) == 0) begin
      io_atomic_req_bits_vaddr = last_lr_vaddr;
      io_atomic_req_bits_addr  = last_lr_paddr;
    end
    io_atomic_req_bits_word_idx = 3'($urandom);
    io_atomic_req_bits_amo_data = {$urandom, $urandom, $urandom, $urandom};
    io_atomic_req_bits_amo_mask = amo_mask_for(io_atomic_req_bits_cmd);
    io_atomic_req_bits_amo_cmp  = (pick(2) == 0) ? 128'h0 : {$urandom, $urandom, $urandom, $urandom};
  endtask

  // -------------------------------------------------------------------
  // 存储阵列 / 下游的回应
  // -------------------------------------------------------------------
  task automatic drive_arrays();
    int perm [4];
    int use_perm = ($urandom_range(0, 9) < 7);
    // 一个 0..3 的随机排列
    for (int k = 0; k < 4; k++) perm[k] = k;
    for (int k = 3; k > 0; k--) begin
      int j = pick(k + 1);
      int tmp = perm[k]; perm[k] = perm[j]; perm[j] = tmp;
    end
    for (int w = 0; w < 4; w++) begin
      logic [42:0] enc;
      logic [1:0]  st;
      int r;
      enc = secded_encode(tag_pool[use_perm ? perm[w] : pick(4)]);
      r = pick(100);
      if (r < 4)      enc[pick(43)] ^= 1'b1;                        // 单比特错
      else if (r < 6) begin enc[pick(21)] ^= 1'b1; enc[21 + pick(22)] ^= 1'b1; end   // 双比特错
      r = pick(100);
      st = (r < 15) ? 2'd0 : (r < 40) ? 2'd1 : (r < 70) ? 2'd2 : 2'd3;
      case (w)
        0: begin io_tag_resp_0 = enc; io_meta_resp_0_coh_state = st; end
        1: begin io_tag_resp_1 = enc; io_meta_resp_1_coh_state = st; end
        2: begin io_tag_resp_2 = enc; io_meta_resp_2_coh_state = st; end
        default: begin io_tag_resp_3 = enc; io_meta_resp_3_coh_state = st; end
      endcase
    end
    {io_extra_meta_resp_0_error_tl_denied, io_extra_meta_resp_0_error_tl_corrupt} = (pick(20) == 0) ? 2'($urandom) : 2'b00;
    {io_extra_meta_resp_1_error_tl_denied, io_extra_meta_resp_1_error_tl_corrupt} = (pick(20) == 0) ? 2'($urandom) : 2'b00;
    {io_extra_meta_resp_2_error_tl_denied, io_extra_meta_resp_2_error_tl_corrupt} = (pick(20) == 0) ? 2'($urandom) : 2'b00;
    {io_extra_meta_resp_3_error_tl_denied, io_extra_meta_resp_3_error_tl_corrupt} = (pick(20) == 0) ? 2'($urandom) : 2'b00;
    io_extra_meta_resp_0_prefetch = 3'($urandom); io_extra_meta_resp_0_access = 1'($urandom);
    io_extra_meta_resp_1_prefetch = 3'($urandom); io_extra_meta_resp_1_access = 1'($urandom);
    io_extra_meta_resp_2_prefetch = 3'($urandom); io_extra_meta_resp_2_access = 1'($urandom);
    io_extra_meta_resp_3_prefetch = 3'($urandom); io_extra_meta_resp_3_access = 1'($urandom);

    // 读出数据：三成拍子全 0（配合 amo_cmp=0 让 CAS 能比较成功），其余随机
    if (pick(10) < 3) begin
      {io_data_resp_7_raw_data, io_data_resp_6_raw_data, io_data_resp_5_raw_data, io_data_resp_4_raw_data,
       io_data_resp_3_raw_data, io_data_resp_2_raw_data, io_data_resp_1_raw_data, io_data_resp_0_raw_data} = '0;
    end else begin
      io_data_resp_0_raw_data = {$urandom, $urandom};
      io_data_resp_1_raw_data = {$urandom, $urandom};
      io_data_resp_2_raw_data = {$urandom, $urandom};
      io_data_resp_3_raw_data = {$urandom, $urandom};
      io_data_resp_4_raw_data = {$urandom, $urandom};
      io_data_resp_5_raw_data = {$urandom, $urandom};
      io_data_resp_6_raw_data = {$urandom, $urandom};
      io_data_resp_7_raw_data = {$urandom, $urandom};
    end
    io_readline_error_delayed = (pick(30) == 0);

    io_refill_info_valid = (pick(10) < 6);
    for (int k = 0; k < 16; k++) io_refill_info_bits_store_data[k*32 +: 32] = $urandom;
    io_refill_info_bits_store_mask = store_mask_rand();
    io_refill_info_bits_miss_param = (pick(10) == 0) ? 2'($urandom) : 2'(pick(2));   // toT / toB
    {io_refill_info_bits_error_tl_denied, io_refill_info_bits_error_tl_corrupt} = (pick(20) == 0) ? 2'($urandom) : 2'b00;

    io_replace_way_way        = 2'($urandom);
    io_btot_ways_for_set      = (pick(4) == 0) ? 4'($urandom) : 4'h0;
    io_replace_block          = (pick(10) == 0);
    io_invalid_resv_set       = (pick(40) == 0);
    io_pseudo_error_valid     = (pick(40) == 0);
    io_pseudo_error_bits_0_valid = 1'($urandom);
    io_pseudo_error_bits_0_mask  = 64'b1 << pick(36);

    io_miss_req_ready       = (pick(10) < 8);
    io_wbq_block_miss_req   = (pick(10) == 0);
    io_wb_ready             = (pick(10) < 8);
    io_data_readline_ready  = (pick(20) < 17);
    io_tag_read_ready       = (pick(20) < 18);
  endtask

  task automatic all_inputs_zero();
    io_probe_req_valid = 0; io_refill_req_valid = 0; io_store_req_valid = 0; io_atomic_req_valid = 0;
    new_probe(); new_refill(); new_store(); new_atomic();
    io_probe_req_valid = 0; io_refill_req_valid = 0; io_store_req_valid = 0; io_atomic_req_valid = 0;
    drive_arrays();
    io_refill_info_valid = 0; io_pseudo_error_valid = 0; io_invalid_resv_set = 0;
    io_replace_block = 0; io_readline_error_delayed = 0; io_btot_ways_for_set = 0;
  endtask

  // 所有下游都放行、不出错的"干净"一拍（暖机用）
  task automatic clean_downstream();
    io_miss_req_ready = 1; io_wbq_block_miss_req = 0; io_wb_ready = 1;
    io_data_readline_ready = 1; io_tag_read_ready = 1; io_replace_block = 0;
    io_invalid_resv_set = 0; io_pseudo_error_valid = 0; io_readline_error_delayed = 0;
    io_btot_ways_for_set = 0; io_refill_info_valid = 1;
    io_refill_info_bits_miss_param = 2'd0;
    {io_refill_info_bits_error_tl_denied, io_refill_info_bits_error_tl_corrupt} = 2'b00;
  endtask

  // -------------------------------------------------------------------
  // 覆盖计数
  // -------------------------------------------------------------------
  int cov_fire_probe, cov_fire_refill, cov_fire_store, cov_fire_atomic;
  int cov_store_hit, cov_store_replay, cov_miss_req_store, cov_miss_req_amo, cov_miss_req_btot;
  int cov_miss_req_cancel, cov_atomic_hit_resp, cov_atomic_replay, cov_atomic_ack_mq;
  int cov_lr_ok, cov_sc_fire, cov_cas_fire, cov_amo_alu_fire;
  int cov_refill_done, cov_refill_replay, cov_evict_btot_block, cov_wb_release, cov_wb_probe_ack;
  int cov_wb_hasdata, cov_meta_write, cov_data_write, cov_data_write_amo, cov_error, cov_bloom_set;
  int cov_bloom_clr, cov_sms_evict, cov_pseudo_tag, cov_pseudo_data, cov_access_write, cov_err_flag;
  int cov_replace_access, cov_store_set_conflict;

  task automatic count_coverage();
    if (io_probe_req_valid  && g_io_probe_req_ready)  cov_fire_probe++;
    if (io_refill_req_valid && g_io_refill_req_ready) cov_fire_refill++;
    if (io_store_req_valid  && g_io_store_req_ready)  cov_fire_store++;
    if (io_atomic_req_valid && g_io_atomic_req_ready) begin
      cov_fire_atomic++;
      if (io_atomic_req_bits_cmd == 5'h07) cov_sc_fire++;
      if (io_atomic_req_bits_cmd inside {5'h18, 5'h1A, 5'h1B}) cov_cas_fire++;
      if (io_atomic_req_bits_cmd inside {[5'h08:5'h0F], 5'h04}) cov_amo_alu_fire++;
    end
    if (io_store_req_valid && !g_io_store_req_ready && !io_probe_req_valid && !io_refill_req_valid &&
        !io_atomic_req_valid) cov_store_set_conflict++;
    if (g_io_store_hit_resp_valid)    cov_store_hit++;
    if (g_io_store_replay_resp_valid) cov_store_replay++;
    if (g_io_miss_req_valid && g_io_miss_req_bits_source == 4'd1) cov_miss_req_store++;
    if (g_io_miss_req_valid && g_io_miss_req_bits_source == 4'd2) cov_miss_req_amo++;
    if (g_io_miss_req_valid && g_io_miss_req_bits_isBtoT)  cov_miss_req_btot++;
    if (g_io_miss_req_valid && g_io_miss_req_bits_cancel)  cov_miss_req_cancel++;
    if (g_io_atomic_resp_valid && !g_io_atomic_resp_bits_replay) cov_atomic_hit_resp++;
    if (g_io_atomic_resp_valid &&  g_io_atomic_resp_bits_replay) cov_atomic_replay++;
    if (g_io_atomic_resp_valid &&  g_io_atomic_resp_bits_ack_miss_queue) cov_atomic_ack_mq++;
    if (g_io_update_resv_set)          cov_lr_ok++;
    if (g_io_tag_write_valid)          cov_refill_done++;
    if (g_io_mainpipe_info_s2_replay_to_mq)   cov_refill_replay++;
    if (g_io_mainpipe_info_s2_evict_BtoT_way) cov_evict_btot_block++;
    if (g_io_wb_valid &&  g_io_wb_bits_voluntary) cov_wb_release++;
    if (g_io_wb_valid && !g_io_wb_bits_voluntary) cov_wb_probe_ack++;
    if (g_io_wb_valid &&  g_io_wb_bits_hasData)   cov_wb_hasdata++;
    if (g_io_meta_write_valid) cov_meta_write++;
    if (g_io_data_write_valid) cov_data_write++;
    if (g_io_data_write_valid && g_io_data_write_bits_wmask != 8'hFF && g_io_data_write_bits_wmask != 8'h00 &&
        g_io_atomic_resp_valid) cov_data_write_amo++;
    if (g_io_error_valid)                     cov_error++;
    if (g_io_bloom_filter_query_set_valid)    cov_bloom_set++;
    if (g_io_bloom_filter_query_clr_valid)    cov_bloom_clr++;
    if (g_io_sms_agt_evict_req_valid)         cov_sms_evict++;
    if (g_io_pseudo_tag_error_inj_done)       cov_pseudo_tag++;
    if (g_io_pseudo_data_error_inj_done)      cov_pseudo_data++;
    if (g_io_access_flag_write_valid)         cov_access_write++;
    if (g_io_error_flag_write_valid)          cov_err_flag++;
    if (g_io_replace_access_valid)            cov_replace_access++;
  endtask

  int cov_fail = 0;
  task automatic cov_gate(input string name, input int v);
    $display("COV %-26s %0d", name, v);
    if (v < COV_MIN) begin
      cov_fail++;
      $display("COV FAIL: %s = %0d < %0d", name, v, COV_MIN);
    end
  endtask

  // -------------------------------------------------------------------
  // 每拍：下降沿先比较（输出已稳定），再给下一拍的输入
  // -------------------------------------------------------------------
  task automatic step_random();
    // 握手成功或"等不及撤销"时换一个新请求（撤销概率：probe 很少撤，atomic 最常撤，
    // 否则 store/atomic 会互相卡住：store 有效时 atomic 永远轮不到，atomic 有效时
    // store.ready 又恒 0）
    if (!io_probe_req_valid  || g_io_probe_req_ready  || pick(50) == 0) new_probe();
    if (!io_refill_req_valid || g_io_refill_req_ready || pick(20) == 0) new_refill();
    if (!io_store_req_valid  || g_io_store_req_ready  || pick(6)  == 0) new_store();
    if (!io_atomic_req_valid || g_io_atomic_req_ready || pick(4)  == 0) new_atomic();
    drive_arrays();
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    last_lr_vaddr = mk_vaddr(set_pool[1]);
    last_lr_paddr = mk_paddr(tag_pool[1], set_pool[1]);
    reset = 1;
    all_inputs_zero();
    repeat (10) @(negedge clock);
    reset = 0;

    // ---- 确定性暖机：refill 一个 LR、一个 AMOADD（写定 lrsc_addr / AMO 结果寄存器）----
    for (int k = 0; k < 2; k++) begin
      @(negedge clock);
      all_inputs_zero();
      clean_downstream();
      io_refill_req_valid         = 1;
      io_refill_req_bits_source   = 4'd2;
      io_refill_req_bits_cmd      = (k == 0) ? 5'h06 : 5'h08;
      io_refill_req_bits_miss_fail_cause_evict_btot = 0;
      while (!(io_refill_req_valid && g_io_refill_req_ready)) @(negedge clock);
      @(negedge clock);
      io_refill_req_valid = 0;
      repeat (8) @(negedge clock);
    end
    // ---- 随机暖机（不比较）----
    repeat (WARMUP_RND) begin
      @(negedge clock);
      step_random();
    end

    // ---- 比较窗口 ----
    compare_en = 1;
    for (int c = 0; c < NCYCLES; c++) begin
      @(negedge clock);
      compare_outputs();
      checks++;
      count_coverage();
      if (io_atomic_req_valid && g_io_atomic_req_ready && io_atomic_req_bits_cmd == 5'h06) begin
        last_lr_vaddr = io_atomic_req_bits_vaddr;
        last_lr_paddr = io_atomic_req_bits_addr;
      end
      step_random();
    end

    cov_gate("s0_fire_probe",          cov_fire_probe);
    cov_gate("s0_fire_refill",         cov_fire_refill);
    cov_gate("s0_fire_store",          cov_fire_store);
    cov_gate("s0_fire_atomic",         cov_fire_atomic);
    cov_gate("store_set_conflict",     cov_store_set_conflict);
    cov_gate("store_hit_resp",         cov_store_hit);
    cov_gate("store_replay_resp",      cov_store_replay);
    cov_gate("miss_req_store",         cov_miss_req_store);
    cov_gate("miss_req_amo",           cov_miss_req_amo);
    cov_gate("miss_req_BtoT",          cov_miss_req_btot);
    cov_gate("miss_req_cancel",        cov_miss_req_cancel);
    cov_gate("atomic_hit_resp",        cov_atomic_hit_resp);
    cov_gate("atomic_replay_resp",     cov_atomic_replay);
    cov_gate("atomic_ack_miss_queue",  cov_atomic_ack_mq);
    cov_gate("lr_update_resv_set",     cov_lr_ok);
    cov_gate("sc_fire",                cov_sc_fire);
    cov_gate("cas_fire",               cov_cas_fire);
    cov_gate("amoalu_fire",            cov_amo_alu_fire);
    cov_gate("refill_tag_write",       cov_refill_done);
    cov_gate("refill_replay_to_mq",    cov_refill_replay);
    cov_gate("evict_BtoT_block",       cov_evict_btot_block);
    cov_gate("wb_release(voluntary)",  cov_wb_release);
    cov_gate("wb_probe_ack",           cov_wb_probe_ack);
    cov_gate("wb_hasData",             cov_wb_hasdata);
    cov_gate("meta_write",             cov_meta_write);
    cov_gate("data_write",             cov_data_write);
    cov_gate("data_write_amo_partial", cov_data_write_amo);
    cov_gate("ecc_error_report",       cov_error);
    cov_gate("error_flag_write",       cov_err_flag);
    cov_gate("bloom_set",              cov_bloom_set);
    cov_gate("bloom_clr",              cov_bloom_clr);
    cov_gate("sms_evict",              cov_sms_evict);
    cov_gate("pseudo_tag_inj_done",    cov_pseudo_tag);
    cov_gate("pseudo_data_inj_done",   cov_pseudo_data);
    cov_gate("access_flag_write",      cov_access_write);
    cov_gate("replace_access",         cov_replace_access);

    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else                              $display("TEST FAILED");
    $finish;
  end
endmodule
