// MissEntry 双例化逐拍比对：golden MissEntry vs 重写件 MissEntry_xs（xs_MissEntry_core）。
// GENERATED 区由 gen.py 从 G1 golden 端口表生成（勿手改）；其余为手写激励与覆盖。
//
// 激励：每拍随机驱动全部输入，但地址取自一个很小的"行池"（4 个 cache 行 × 2 种 alias，每 2000 拍换池），
//   让同一行的合并 / 拒绝 / probe、replace 阻挡 / 前递命中高频发生；
//   流水寄存器的 alloc / merge / cancel 随机给（表项不关心 MissQueue 的协议，任何组合都要一致）；
//   D 通道 Grant(4) / GrantData(5) × size 5/6（1 拍 / 2 拍）随机；MainPipe 的 resp / replay /
//   evict、L2 hint、wfiReq 成段出现；io_id 每 4000 拍在 {0,1} 与 {2..15} 之间交替（覆盖两类表项）；
//   rob_head 查询一半拍取表项当前 vaddr（否则几乎撞不上）；
//   约每 5000 拍随机打一次异步复位。
// 暖机：复位后先做一次"store 分配 + 两拍 GrantData"，把所有不复位、又能从输出看到的寄存器
//   （请求字段、整行数据、raw 数据、grant_param、sink、refill_to_ldq 锁存）写定，再开比较窗口
//   （+vcs+initreg+random 下两实例的这些寄存器初值不同）。
// 覆盖闸：各事件计数 >= COV_MIN，外加每个输出位见过 0 和 1（结构恒定位在 gen.py 里逐个豁免）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 200;
  int errors = 0, checks = 0, cov_fail = 0, cyc = 0;

  bit   clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // BEGIN GENERATED(tb-ports)
  // ---- 输入（两侧共用；clock/reset 由 tb 手写区驱动）----
  logic [3:0] io_id;
  logic io_req_valid;
  logic [3:0] io_req_bits_source;
  logic [47:0] io_req_bits_addr;
  logic [49:0] io_req_bits_vaddr;
  logic io_req_bits_cancel;
  logic io_wbq_block_miss_req;
  logic [3:0] io_miss_req_pipe_reg_req_source;
  logic [2:0] io_miss_req_pipe_reg_req_pf_source;
  logic [4:0] io_miss_req_pipe_reg_req_cmd;
  logic [47:0] io_miss_req_pipe_reg_req_addr;
  logic [49:0] io_miss_req_pipe_reg_req_vaddr;
  logic io_miss_req_pipe_reg_req_full_overwrite;
  logic [2:0] io_miss_req_pipe_reg_req_word_idx;
  logic [127:0] io_miss_req_pipe_reg_req_amo_data;
  logic [15:0] io_miss_req_pipe_reg_req_amo_mask;
  logic [127:0] io_miss_req_pipe_reg_req_amo_cmp;
  logic [1:0] io_miss_req_pipe_reg_req_req_coh_state;
  logic [5:0] io_miss_req_pipe_reg_req_id;
  logic io_miss_req_pipe_reg_req_isBtoT;
  logic [3:0] io_miss_req_pipe_reg_req_occupy_way;
  logic [511:0] io_miss_req_pipe_reg_req_store_data;
  logic [63:0] io_miss_req_pipe_reg_req_store_mask;
  logic io_miss_req_pipe_reg_merge;
  logic io_miss_req_pipe_reg_alloc;
  logic io_miss_req_pipe_reg_cancel;
  logic io_primary_valid;
  logic io_mem_acquire_ready;
  logic io_mem_grant_valid;
  logic [3:0] io_mem_grant_bits_opcode;
  logic [1:0] io_mem_grant_bits_param;
  logic [2:0] io_mem_grant_bits_size;
  logic [9:0] io_mem_grant_bits_sink;
  logic io_mem_grant_bits_denied;
  logic [255:0] io_mem_grant_bits_data;
  logic io_mem_grant_bits_corrupt;
  logic io_mem_finish_ready;
  logic [3:0] io_queryME_0_req_bits_source;
  logic [47:0] io_queryME_0_req_bits_addr;
  logic [49:0] io_queryME_0_req_bits_vaddr;
  logic [3:0] io_queryME_1_req_bits_source;
  logic [47:0] io_queryME_1_req_bits_addr;
  logic [49:0] io_queryME_1_req_bits_vaddr;
  logic [3:0] io_queryME_2_req_bits_source;
  logic [47:0] io_queryME_2_req_bits_addr;
  logic [49:0] io_queryME_2_req_bits_vaddr;
  logic [3:0] io_queryME_3_req_bits_source;
  logic [47:0] io_queryME_3_req_bits_addr;
  logic [49:0] io_queryME_3_req_bits_vaddr;
  logic io_l2_hint_valid;
  logic io_main_pipe_req_ready;
  logic io_main_pipe_resp;
  logic io_main_pipe_refill_resp;
  logic io_main_pipe_replay;
  logic io_main_pipe_evict_BtoT_way;
  logic [3:0] io_main_pipe_next_evict_way;
  logic [47:0] io_probe_req_bits_addr;
  logic [49:0] io_probe_req_bits_vaddr;
  logic [47:0] io_replace_req_bits_addr;
  logic [49:0] io_replace_req_bits_vaddr;
  logic io_l2_pf_store_only;
  logic io_acquire_fired_by_pipe_reg;
  logic io_memSetPattenDetected;
  logic [49:0] io_rob_head_query_vaddr;
  logic io_rob_head_query_query_valid;
  logic io_wfi_wfiReq;
  // ---- 输出（g_ = golden，i_ = 重写）----
  wire  g_io_primary_ready, i_io_primary_ready;
  wire  g_io_secondary_ready, i_io_secondary_ready;
  wire  g_io_secondary_reject, i_io_secondary_reject;
  wire  g_io_mem_acquire_valid, i_io_mem_acquire_valid;
  wire  [3:0] g_io_mem_acquire_bits_opcode, i_io_mem_acquire_bits_opcode;
  wire  [2:0] g_io_mem_acquire_bits_param, i_io_mem_acquire_bits_param;
  wire  [5:0] g_io_mem_acquire_bits_source, i_io_mem_acquire_bits_source;
  wire  [47:0] g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address;
  wire  [1:0] g_io_mem_acquire_bits_user_alias, i_io_mem_acquire_bits_user_alias;
  wire  [43:0] g_io_mem_acquire_bits_user_vaddr, i_io_mem_acquire_bits_user_vaddr;
  wire  [4:0] g_io_mem_acquire_bits_user_reqSource, i_io_mem_acquire_bits_user_reqSource;
  wire  g_io_mem_acquire_bits_user_needHint, i_io_mem_acquire_bits_user_needHint;
  wire  g_io_mem_acquire_bits_echo_isKeyword, i_io_mem_acquire_bits_echo_isKeyword;
  wire  g_io_mem_finish_valid, i_io_mem_finish_valid;
  wire  [9:0] g_io_mem_finish_bits_sink, i_io_mem_finish_bits_sink;
  wire  g_io_queryME_0_primary_ready, i_io_queryME_0_primary_ready;
  wire  g_io_queryME_0_secondary_ready, i_io_queryME_0_secondary_ready;
  wire  g_io_queryME_0_secondary_reject, i_io_queryME_0_secondary_reject;
  wire  g_io_queryME_1_primary_ready, i_io_queryME_1_primary_ready;
  wire  g_io_queryME_1_secondary_ready, i_io_queryME_1_secondary_ready;
  wire  g_io_queryME_1_secondary_reject, i_io_queryME_1_secondary_reject;
  wire  g_io_queryME_2_primary_ready, i_io_queryME_2_primary_ready;
  wire  g_io_queryME_2_secondary_ready, i_io_queryME_2_secondary_ready;
  wire  g_io_queryME_2_secondary_reject, i_io_queryME_2_secondary_reject;
  wire  g_io_queryME_3_primary_ready, i_io_queryME_3_primary_ready;
  wire  g_io_queryME_3_secondary_ready, i_io_queryME_3_secondary_ready;
  wire  g_io_queryME_3_secondary_reject, i_io_queryME_3_secondary_reject;
  wire  g_io_refill_to_ldq_valid, i_io_refill_to_ldq_valid;
  wire  [47:0] g_io_refill_to_ldq_bits_addr, i_io_refill_to_ldq_bits_addr;
  wire  [255:0] g_io_refill_to_ldq_bits_data, i_io_refill_to_ldq_bits_data;
  wire  g_io_refill_to_ldq_bits_error, i_io_refill_to_ldq_bits_error;
  wire  [511:0] g_io_refill_to_ldq_bits_data_raw, i_io_refill_to_ldq_bits_data_raw;
  wire  g_io_refill_to_ldq_bits_hasdata, i_io_refill_to_ldq_bits_hasdata;
  wire  g_io_refill_to_ldq_bits_refill_done, i_io_refill_to_ldq_bits_refill_done;
  wire  [3:0] g_io_refill_to_ldq_bits_id, i_io_refill_to_ldq_bits_id;
  wire  g_io_main_pipe_req_valid, i_io_main_pipe_req_valid;
  wire  [3:0] g_io_main_pipe_req_bits_miss_id, i_io_main_pipe_req_bits_miss_id;
  wire  [3:0] g_io_main_pipe_req_bits_occupy_way, i_io_main_pipe_req_bits_occupy_way;
  wire  g_io_main_pipe_req_bits_miss_fail_cause_evict_btot, i_io_main_pipe_req_bits_miss_fail_cause_evict_btot;
  wire  [3:0] g_io_main_pipe_req_bits_source, i_io_main_pipe_req_bits_source;
  wire  [4:0] g_io_main_pipe_req_bits_cmd, i_io_main_pipe_req_bits_cmd;
  wire  [49:0] g_io_main_pipe_req_bits_vaddr, i_io_main_pipe_req_bits_vaddr;
  wire  [47:0] g_io_main_pipe_req_bits_addr, i_io_main_pipe_req_bits_addr;
  wire  [2:0] g_io_main_pipe_req_bits_word_idx, i_io_main_pipe_req_bits_word_idx;
  wire  [127:0] g_io_main_pipe_req_bits_amo_data, i_io_main_pipe_req_bits_amo_data;
  wire  [15:0] g_io_main_pipe_req_bits_amo_mask, i_io_main_pipe_req_bits_amo_mask;
  wire  [127:0] g_io_main_pipe_req_bits_amo_cmp, i_io_main_pipe_req_bits_amo_cmp;
  wire  [2:0] g_io_main_pipe_req_bits_pf_source, i_io_main_pipe_req_bits_pf_source;
  wire  g_io_main_pipe_req_bits_access, i_io_main_pipe_req_bits_access;
  wire  [5:0] g_io_main_pipe_req_bits_id, i_io_main_pipe_req_bits_id;
  wire  g_io_refill_info_valid, i_io_refill_info_valid;
  wire  [511:0] g_io_refill_info_bits_store_data, i_io_refill_info_bits_store_data;
  wire  [1:0] g_io_refill_info_bits_miss_param, i_io_refill_info_bits_miss_param;
  wire  g_io_refill_info_bits_error_tl_denied, i_io_refill_info_bits_error_tl_denied;
  wire  g_io_refill_info_bits_error_tl_corrupt, i_io_refill_info_bits_error_tl_corrupt;
  wire  [3:0] g_io_occupy_way, i_io_occupy_way;
  wire  g_io_probe_block, i_io_probe_block;
  wire  g_io_replace_block, i_io_replace_block;
  wire  g_io_req_vaddr_valid, i_io_req_vaddr_valid;
  wire  [49:0] g_io_req_vaddr_bits, i_io_req_vaddr_bits;
  wire  g_io_req_isBtoT, i_io_req_isBtoT;
  wire  g_io_req_handled_by_this_entry, i_io_req_handled_by_this_entry;
  wire  g_io_forwardInfo_inflight, i_io_forwardInfo_inflight;
  wire  [47:0] g_io_forwardInfo_paddr, i_io_forwardInfo_paddr;
  wire  [63:0] g_io_forwardInfo_raw_data_0, i_io_forwardInfo_raw_data_0;
  wire  [63:0] g_io_forwardInfo_raw_data_1, i_io_forwardInfo_raw_data_1;
  wire  [63:0] g_io_forwardInfo_raw_data_2, i_io_forwardInfo_raw_data_2;
  wire  [63:0] g_io_forwardInfo_raw_data_3, i_io_forwardInfo_raw_data_3;
  wire  [63:0] g_io_forwardInfo_raw_data_4, i_io_forwardInfo_raw_data_4;
  wire  [63:0] g_io_forwardInfo_raw_data_5, i_io_forwardInfo_raw_data_5;
  wire  [63:0] g_io_forwardInfo_raw_data_6, i_io_forwardInfo_raw_data_6;
  wire  [63:0] g_io_forwardInfo_raw_data_7, i_io_forwardInfo_raw_data_7;
  wire  g_io_forwardInfo_firstbeat_valid, i_io_forwardInfo_firstbeat_valid;
  wire  g_io_forwardInfo_lastbeat_valid, i_io_forwardInfo_lastbeat_valid;
  wire  g_io_forwardInfo_denied, i_io_forwardInfo_denied;
  wire  g_io_forwardInfo_corrupt, i_io_forwardInfo_corrupt;
  wire  g_io_perf_pending_prefetch, i_io_perf_pending_prefetch;
  wire  g_io_perf_pending_normal, i_io_perf_pending_normal;
  wire  g_io_rob_head_query_resp, i_io_rob_head_query_resp;
  wire  g_io_latency_monitor_load_miss_refilling, i_io_latency_monitor_load_miss_refilling;
  wire  g_io_latency_monitor_store_miss_refilling, i_io_latency_monitor_store_miss_refilling;
  wire  g_io_latency_monitor_amo_miss_refilling, i_io_latency_monitor_amo_miss_refilling;
  wire  g_io_latency_monitor_pf_miss_refilling, i_io_latency_monitor_pf_miss_refilling;
  wire  g_io_prefetch_info_late_prefetch, i_io_prefetch_info_late_prefetch;
  wire  g_io_matched, i_io_matched;
  wire  g_io_l1Miss, i_io_l1Miss;
  wire  g_io_wfi_wfiSafe, i_io_wfi_wfiSafe;
  MissEntry u_gold (
    .clock(clock),
    .reset(reset),
    .io_id(io_id),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_vaddr(io_req_bits_vaddr),
    .io_req_bits_cancel(io_req_bits_cancel),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source(io_miss_req_pipe_reg_req_source),
    .io_miss_req_pipe_reg_req_pf_source(io_miss_req_pipe_reg_req_pf_source),
    .io_miss_req_pipe_reg_req_cmd(io_miss_req_pipe_reg_req_cmd),
    .io_miss_req_pipe_reg_req_addr(io_miss_req_pipe_reg_req_addr),
    .io_miss_req_pipe_reg_req_vaddr(io_miss_req_pipe_reg_req_vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite(io_miss_req_pipe_reg_req_full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx(io_miss_req_pipe_reg_req_word_idx),
    .io_miss_req_pipe_reg_req_amo_data(io_miss_req_pipe_reg_req_amo_data),
    .io_miss_req_pipe_reg_req_amo_mask(io_miss_req_pipe_reg_req_amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp(io_miss_req_pipe_reg_req_amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state(io_miss_req_pipe_reg_req_req_coh_state),
    .io_miss_req_pipe_reg_req_id(io_miss_req_pipe_reg_req_id),
    .io_miss_req_pipe_reg_req_isBtoT(io_miss_req_pipe_reg_req_isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way(io_miss_req_pipe_reg_req_occupy_way),
    .io_miss_req_pipe_reg_req_store_data(io_miss_req_pipe_reg_req_store_data),
    .io_miss_req_pipe_reg_req_store_mask(io_miss_req_pipe_reg_req_store_mask),
    .io_miss_req_pipe_reg_merge(io_miss_req_pipe_reg_merge),
    .io_miss_req_pipe_reg_alloc(io_miss_req_pipe_reg_alloc),
    .io_miss_req_pipe_reg_cancel(io_miss_req_pipe_reg_cancel),
    .io_primary_valid(io_primary_valid),
    .io_primary_ready(g_io_primary_ready),
    .io_secondary_ready(g_io_secondary_ready),
    .io_secondary_reject(g_io_secondary_reject),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(g_io_mem_acquire_valid),
    .io_mem_acquire_bits_opcode(g_io_mem_acquire_bits_opcode),
    .io_mem_acquire_bits_param(g_io_mem_acquire_bits_param),
    .io_mem_acquire_bits_source(g_io_mem_acquire_bits_source),
    .io_mem_acquire_bits_address(g_io_mem_acquire_bits_address),
    .io_mem_acquire_bits_user_alias(g_io_mem_acquire_bits_user_alias),
    .io_mem_acquire_bits_user_vaddr(g_io_mem_acquire_bits_user_vaddr),
    .io_mem_acquire_bits_user_reqSource(g_io_mem_acquire_bits_user_reqSource),
    .io_mem_acquire_bits_user_needHint(g_io_mem_acquire_bits_user_needHint),
    .io_mem_acquire_bits_echo_isKeyword(g_io_mem_acquire_bits_echo_isKeyword),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param(io_mem_grant_bits_param),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_sink(io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied(io_mem_grant_bits_denied),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .io_mem_finish_ready(io_mem_finish_ready),
    .io_mem_finish_valid(g_io_mem_finish_valid),
    .io_mem_finish_bits_sink(g_io_mem_finish_bits_sink),
    .io_queryME_0_req_bits_source(io_queryME_0_req_bits_source),
    .io_queryME_0_req_bits_addr(io_queryME_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr(io_queryME_0_req_bits_vaddr),
    .io_queryME_0_primary_ready(g_io_queryME_0_primary_ready),
    .io_queryME_0_secondary_ready(g_io_queryME_0_secondary_ready),
    .io_queryME_0_secondary_reject(g_io_queryME_0_secondary_reject),
    .io_queryME_1_req_bits_source(io_queryME_1_req_bits_source),
    .io_queryME_1_req_bits_addr(io_queryME_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr(io_queryME_1_req_bits_vaddr),
    .io_queryME_1_primary_ready(g_io_queryME_1_primary_ready),
    .io_queryME_1_secondary_ready(g_io_queryME_1_secondary_ready),
    .io_queryME_1_secondary_reject(g_io_queryME_1_secondary_reject),
    .io_queryME_2_req_bits_source(io_queryME_2_req_bits_source),
    .io_queryME_2_req_bits_addr(io_queryME_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr(io_queryME_2_req_bits_vaddr),
    .io_queryME_2_primary_ready(g_io_queryME_2_primary_ready),
    .io_queryME_2_secondary_ready(g_io_queryME_2_secondary_ready),
    .io_queryME_2_secondary_reject(g_io_queryME_2_secondary_reject),
    .io_queryME_3_req_bits_source(io_queryME_3_req_bits_source),
    .io_queryME_3_req_bits_addr(io_queryME_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr(io_queryME_3_req_bits_vaddr),
    .io_queryME_3_primary_ready(g_io_queryME_3_primary_ready),
    .io_queryME_3_secondary_ready(g_io_queryME_3_secondary_ready),
    .io_queryME_3_secondary_reject(g_io_queryME_3_secondary_reject),
    .io_refill_to_ldq_valid(g_io_refill_to_ldq_valid),
    .io_refill_to_ldq_bits_addr(g_io_refill_to_ldq_bits_addr),
    .io_refill_to_ldq_bits_data(g_io_refill_to_ldq_bits_data),
    .io_refill_to_ldq_bits_error(g_io_refill_to_ldq_bits_error),
    .io_refill_to_ldq_bits_data_raw(g_io_refill_to_ldq_bits_data_raw),
    .io_refill_to_ldq_bits_hasdata(g_io_refill_to_ldq_bits_hasdata),
    .io_refill_to_ldq_bits_refill_done(g_io_refill_to_ldq_bits_refill_done),
    .io_refill_to_ldq_bits_id(g_io_refill_to_ldq_bits_id),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_main_pipe_req_ready(io_main_pipe_req_ready),
    .io_main_pipe_req_valid(g_io_main_pipe_req_valid),
    .io_main_pipe_req_bits_miss_id(g_io_main_pipe_req_bits_miss_id),
    .io_main_pipe_req_bits_occupy_way(g_io_main_pipe_req_bits_occupy_way),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot(g_io_main_pipe_req_bits_miss_fail_cause_evict_btot),
    .io_main_pipe_req_bits_source(g_io_main_pipe_req_bits_source),
    .io_main_pipe_req_bits_cmd(g_io_main_pipe_req_bits_cmd),
    .io_main_pipe_req_bits_vaddr(g_io_main_pipe_req_bits_vaddr),
    .io_main_pipe_req_bits_addr(g_io_main_pipe_req_bits_addr),
    .io_main_pipe_req_bits_word_idx(g_io_main_pipe_req_bits_word_idx),
    .io_main_pipe_req_bits_amo_data(g_io_main_pipe_req_bits_amo_data),
    .io_main_pipe_req_bits_amo_mask(g_io_main_pipe_req_bits_amo_mask),
    .io_main_pipe_req_bits_amo_cmp(g_io_main_pipe_req_bits_amo_cmp),
    .io_main_pipe_req_bits_pf_source(g_io_main_pipe_req_bits_pf_source),
    .io_main_pipe_req_bits_access(g_io_main_pipe_req_bits_access),
    .io_main_pipe_req_bits_id(g_io_main_pipe_req_bits_id),
    .io_main_pipe_resp(io_main_pipe_resp),
    .io_main_pipe_refill_resp(io_main_pipe_refill_resp),
    .io_main_pipe_replay(io_main_pipe_replay),
    .io_main_pipe_evict_BtoT_way(io_main_pipe_evict_BtoT_way),
    .io_main_pipe_next_evict_way(io_main_pipe_next_evict_way),
    .io_refill_info_valid(g_io_refill_info_valid),
    .io_refill_info_bits_store_data(g_io_refill_info_bits_store_data),
    .io_refill_info_bits_miss_param(g_io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(g_io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(g_io_refill_info_bits_error_tl_corrupt),
    .io_occupy_way(g_io_occupy_way),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_block(g_io_probe_block),
    .io_replace_req_bits_addr(io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr),
    .io_replace_block(g_io_replace_block),
    .io_req_vaddr_valid(g_io_req_vaddr_valid),
    .io_req_vaddr_bits(g_io_req_vaddr_bits),
    .io_req_isBtoT(g_io_req_isBtoT),
    .io_req_handled_by_this_entry(g_io_req_handled_by_this_entry),
    .io_forwardInfo_inflight(g_io_forwardInfo_inflight),
    .io_forwardInfo_paddr(g_io_forwardInfo_paddr),
    .io_forwardInfo_raw_data_0(g_io_forwardInfo_raw_data_0),
    .io_forwardInfo_raw_data_1(g_io_forwardInfo_raw_data_1),
    .io_forwardInfo_raw_data_2(g_io_forwardInfo_raw_data_2),
    .io_forwardInfo_raw_data_3(g_io_forwardInfo_raw_data_3),
    .io_forwardInfo_raw_data_4(g_io_forwardInfo_raw_data_4),
    .io_forwardInfo_raw_data_5(g_io_forwardInfo_raw_data_5),
    .io_forwardInfo_raw_data_6(g_io_forwardInfo_raw_data_6),
    .io_forwardInfo_raw_data_7(g_io_forwardInfo_raw_data_7),
    .io_forwardInfo_firstbeat_valid(g_io_forwardInfo_firstbeat_valid),
    .io_forwardInfo_lastbeat_valid(g_io_forwardInfo_lastbeat_valid),
    .io_forwardInfo_denied(g_io_forwardInfo_denied),
    .io_forwardInfo_corrupt(g_io_forwardInfo_corrupt),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg(io_acquire_fired_by_pipe_reg),
    .io_memSetPattenDetected(io_memSetPattenDetected),
    .io_perf_pending_prefetch(g_io_perf_pending_prefetch),
    .io_perf_pending_normal(g_io_perf_pending_normal),
    .io_rob_head_query_vaddr(io_rob_head_query_vaddr),
    .io_rob_head_query_query_valid(io_rob_head_query_query_valid),
    .io_rob_head_query_resp(g_io_rob_head_query_resp),
    .io_latency_monitor_load_miss_refilling(g_io_latency_monitor_load_miss_refilling),
    .io_latency_monitor_store_miss_refilling(g_io_latency_monitor_store_miss_refilling),
    .io_latency_monitor_amo_miss_refilling(g_io_latency_monitor_amo_miss_refilling),
    .io_latency_monitor_pf_miss_refilling(g_io_latency_monitor_pf_miss_refilling),
    .io_prefetch_info_late_prefetch(g_io_prefetch_info_late_prefetch),
    .io_matched(g_io_matched),
    .io_l1Miss(g_io_l1Miss),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(g_io_wfi_wfiSafe)
  );
  MissEntry_xs u_impl (
    .clock(clock),
    .reset(reset),
    .io_id(io_id),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_vaddr(io_req_bits_vaddr),
    .io_req_bits_cancel(io_req_bits_cancel),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source(io_miss_req_pipe_reg_req_source),
    .io_miss_req_pipe_reg_req_pf_source(io_miss_req_pipe_reg_req_pf_source),
    .io_miss_req_pipe_reg_req_cmd(io_miss_req_pipe_reg_req_cmd),
    .io_miss_req_pipe_reg_req_addr(io_miss_req_pipe_reg_req_addr),
    .io_miss_req_pipe_reg_req_vaddr(io_miss_req_pipe_reg_req_vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite(io_miss_req_pipe_reg_req_full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx(io_miss_req_pipe_reg_req_word_idx),
    .io_miss_req_pipe_reg_req_amo_data(io_miss_req_pipe_reg_req_amo_data),
    .io_miss_req_pipe_reg_req_amo_mask(io_miss_req_pipe_reg_req_amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp(io_miss_req_pipe_reg_req_amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state(io_miss_req_pipe_reg_req_req_coh_state),
    .io_miss_req_pipe_reg_req_id(io_miss_req_pipe_reg_req_id),
    .io_miss_req_pipe_reg_req_isBtoT(io_miss_req_pipe_reg_req_isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way(io_miss_req_pipe_reg_req_occupy_way),
    .io_miss_req_pipe_reg_req_store_data(io_miss_req_pipe_reg_req_store_data),
    .io_miss_req_pipe_reg_req_store_mask(io_miss_req_pipe_reg_req_store_mask),
    .io_miss_req_pipe_reg_merge(io_miss_req_pipe_reg_merge),
    .io_miss_req_pipe_reg_alloc(io_miss_req_pipe_reg_alloc),
    .io_miss_req_pipe_reg_cancel(io_miss_req_pipe_reg_cancel),
    .io_primary_valid(io_primary_valid),
    .io_primary_ready(i_io_primary_ready),
    .io_secondary_ready(i_io_secondary_ready),
    .io_secondary_reject(i_io_secondary_reject),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(i_io_mem_acquire_valid),
    .io_mem_acquire_bits_opcode(i_io_mem_acquire_bits_opcode),
    .io_mem_acquire_bits_param(i_io_mem_acquire_bits_param),
    .io_mem_acquire_bits_source(i_io_mem_acquire_bits_source),
    .io_mem_acquire_bits_address(i_io_mem_acquire_bits_address),
    .io_mem_acquire_bits_user_alias(i_io_mem_acquire_bits_user_alias),
    .io_mem_acquire_bits_user_vaddr(i_io_mem_acquire_bits_user_vaddr),
    .io_mem_acquire_bits_user_reqSource(i_io_mem_acquire_bits_user_reqSource),
    .io_mem_acquire_bits_user_needHint(i_io_mem_acquire_bits_user_needHint),
    .io_mem_acquire_bits_echo_isKeyword(i_io_mem_acquire_bits_echo_isKeyword),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param(io_mem_grant_bits_param),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_sink(io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied(io_mem_grant_bits_denied),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .io_mem_finish_ready(io_mem_finish_ready),
    .io_mem_finish_valid(i_io_mem_finish_valid),
    .io_mem_finish_bits_sink(i_io_mem_finish_bits_sink),
    .io_queryME_0_req_bits_source(io_queryME_0_req_bits_source),
    .io_queryME_0_req_bits_addr(io_queryME_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr(io_queryME_0_req_bits_vaddr),
    .io_queryME_0_primary_ready(i_io_queryME_0_primary_ready),
    .io_queryME_0_secondary_ready(i_io_queryME_0_secondary_ready),
    .io_queryME_0_secondary_reject(i_io_queryME_0_secondary_reject),
    .io_queryME_1_req_bits_source(io_queryME_1_req_bits_source),
    .io_queryME_1_req_bits_addr(io_queryME_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr(io_queryME_1_req_bits_vaddr),
    .io_queryME_1_primary_ready(i_io_queryME_1_primary_ready),
    .io_queryME_1_secondary_ready(i_io_queryME_1_secondary_ready),
    .io_queryME_1_secondary_reject(i_io_queryME_1_secondary_reject),
    .io_queryME_2_req_bits_source(io_queryME_2_req_bits_source),
    .io_queryME_2_req_bits_addr(io_queryME_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr(io_queryME_2_req_bits_vaddr),
    .io_queryME_2_primary_ready(i_io_queryME_2_primary_ready),
    .io_queryME_2_secondary_ready(i_io_queryME_2_secondary_ready),
    .io_queryME_2_secondary_reject(i_io_queryME_2_secondary_reject),
    .io_queryME_3_req_bits_source(io_queryME_3_req_bits_source),
    .io_queryME_3_req_bits_addr(io_queryME_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr(io_queryME_3_req_bits_vaddr),
    .io_queryME_3_primary_ready(i_io_queryME_3_primary_ready),
    .io_queryME_3_secondary_ready(i_io_queryME_3_secondary_ready),
    .io_queryME_3_secondary_reject(i_io_queryME_3_secondary_reject),
    .io_refill_to_ldq_valid(i_io_refill_to_ldq_valid),
    .io_refill_to_ldq_bits_addr(i_io_refill_to_ldq_bits_addr),
    .io_refill_to_ldq_bits_data(i_io_refill_to_ldq_bits_data),
    .io_refill_to_ldq_bits_error(i_io_refill_to_ldq_bits_error),
    .io_refill_to_ldq_bits_data_raw(i_io_refill_to_ldq_bits_data_raw),
    .io_refill_to_ldq_bits_hasdata(i_io_refill_to_ldq_bits_hasdata),
    .io_refill_to_ldq_bits_refill_done(i_io_refill_to_ldq_bits_refill_done),
    .io_refill_to_ldq_bits_id(i_io_refill_to_ldq_bits_id),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_main_pipe_req_ready(io_main_pipe_req_ready),
    .io_main_pipe_req_valid(i_io_main_pipe_req_valid),
    .io_main_pipe_req_bits_miss_id(i_io_main_pipe_req_bits_miss_id),
    .io_main_pipe_req_bits_occupy_way(i_io_main_pipe_req_bits_occupy_way),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot(i_io_main_pipe_req_bits_miss_fail_cause_evict_btot),
    .io_main_pipe_req_bits_source(i_io_main_pipe_req_bits_source),
    .io_main_pipe_req_bits_cmd(i_io_main_pipe_req_bits_cmd),
    .io_main_pipe_req_bits_vaddr(i_io_main_pipe_req_bits_vaddr),
    .io_main_pipe_req_bits_addr(i_io_main_pipe_req_bits_addr),
    .io_main_pipe_req_bits_word_idx(i_io_main_pipe_req_bits_word_idx),
    .io_main_pipe_req_bits_amo_data(i_io_main_pipe_req_bits_amo_data),
    .io_main_pipe_req_bits_amo_mask(i_io_main_pipe_req_bits_amo_mask),
    .io_main_pipe_req_bits_amo_cmp(i_io_main_pipe_req_bits_amo_cmp),
    .io_main_pipe_req_bits_pf_source(i_io_main_pipe_req_bits_pf_source),
    .io_main_pipe_req_bits_access(i_io_main_pipe_req_bits_access),
    .io_main_pipe_req_bits_id(i_io_main_pipe_req_bits_id),
    .io_main_pipe_resp(io_main_pipe_resp),
    .io_main_pipe_refill_resp(io_main_pipe_refill_resp),
    .io_main_pipe_replay(io_main_pipe_replay),
    .io_main_pipe_evict_BtoT_way(io_main_pipe_evict_BtoT_way),
    .io_main_pipe_next_evict_way(io_main_pipe_next_evict_way),
    .io_refill_info_valid(i_io_refill_info_valid),
    .io_refill_info_bits_store_data(i_io_refill_info_bits_store_data),
    .io_refill_info_bits_miss_param(i_io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(i_io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(i_io_refill_info_bits_error_tl_corrupt),
    .io_occupy_way(i_io_occupy_way),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_block(i_io_probe_block),
    .io_replace_req_bits_addr(io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr),
    .io_replace_block(i_io_replace_block),
    .io_req_vaddr_valid(i_io_req_vaddr_valid),
    .io_req_vaddr_bits(i_io_req_vaddr_bits),
    .io_req_isBtoT(i_io_req_isBtoT),
    .io_req_handled_by_this_entry(i_io_req_handled_by_this_entry),
    .io_forwardInfo_inflight(i_io_forwardInfo_inflight),
    .io_forwardInfo_paddr(i_io_forwardInfo_paddr),
    .io_forwardInfo_raw_data_0(i_io_forwardInfo_raw_data_0),
    .io_forwardInfo_raw_data_1(i_io_forwardInfo_raw_data_1),
    .io_forwardInfo_raw_data_2(i_io_forwardInfo_raw_data_2),
    .io_forwardInfo_raw_data_3(i_io_forwardInfo_raw_data_3),
    .io_forwardInfo_raw_data_4(i_io_forwardInfo_raw_data_4),
    .io_forwardInfo_raw_data_5(i_io_forwardInfo_raw_data_5),
    .io_forwardInfo_raw_data_6(i_io_forwardInfo_raw_data_6),
    .io_forwardInfo_raw_data_7(i_io_forwardInfo_raw_data_7),
    .io_forwardInfo_firstbeat_valid(i_io_forwardInfo_firstbeat_valid),
    .io_forwardInfo_lastbeat_valid(i_io_forwardInfo_lastbeat_valid),
    .io_forwardInfo_denied(i_io_forwardInfo_denied),
    .io_forwardInfo_corrupt(i_io_forwardInfo_corrupt),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg(io_acquire_fired_by_pipe_reg),
    .io_memSetPattenDetected(io_memSetPattenDetected),
    .io_perf_pending_prefetch(i_io_perf_pending_prefetch),
    .io_perf_pending_normal(i_io_perf_pending_normal),
    .io_rob_head_query_vaddr(io_rob_head_query_vaddr),
    .io_rob_head_query_query_valid(io_rob_head_query_query_valid),
    .io_rob_head_query_resp(i_io_rob_head_query_resp),
    .io_latency_monitor_load_miss_refilling(i_io_latency_monitor_load_miss_refilling),
    .io_latency_monitor_store_miss_refilling(i_io_latency_monitor_store_miss_refilling),
    .io_latency_monitor_amo_miss_refilling(i_io_latency_monitor_amo_miss_refilling),
    .io_latency_monitor_pf_miss_refilling(i_io_latency_monitor_pf_miss_refilling),
    .io_prefetch_info_late_prefetch(i_io_prefetch_info_late_prefetch),
    .io_matched(i_io_matched),
    .io_l1Miss(i_io_l1Miss),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(i_io_wfi_wfiSafe)
  );
  // END GENERATED

  // BEGIN GENERATED(tb-compare)
  logic seen1_io_primary_ready = '0, seen0_io_primary_ready = '0;
  logic seen1_io_secondary_ready = '0, seen0_io_secondary_ready = '0;
  logic seen1_io_secondary_reject = '0, seen0_io_secondary_reject = '0;
  logic seen1_io_mem_acquire_valid = '0, seen0_io_mem_acquire_valid = '0;
  logic [3:0] seen1_io_mem_acquire_bits_opcode = '0, seen0_io_mem_acquire_bits_opcode = '0;
  logic [2:0] seen1_io_mem_acquire_bits_param = '0, seen0_io_mem_acquire_bits_param = '0;
  logic [5:0] seen1_io_mem_acquire_bits_source = '0, seen0_io_mem_acquire_bits_source = '0;
  logic [47:0] seen1_io_mem_acquire_bits_address = '0, seen0_io_mem_acquire_bits_address = '0;
  logic [1:0] seen1_io_mem_acquire_bits_user_alias = '0, seen0_io_mem_acquire_bits_user_alias = '0;
  logic [43:0] seen1_io_mem_acquire_bits_user_vaddr = '0, seen0_io_mem_acquire_bits_user_vaddr = '0;
  logic [4:0] seen1_io_mem_acquire_bits_user_reqSource = '0, seen0_io_mem_acquire_bits_user_reqSource = '0;
  logic seen1_io_mem_acquire_bits_user_needHint = '0, seen0_io_mem_acquire_bits_user_needHint = '0;
  logic seen1_io_mem_acquire_bits_echo_isKeyword = '0, seen0_io_mem_acquire_bits_echo_isKeyword = '0;
  logic seen1_io_mem_finish_valid = '0, seen0_io_mem_finish_valid = '0;
  logic [9:0] seen1_io_mem_finish_bits_sink = '0, seen0_io_mem_finish_bits_sink = '0;
  logic seen1_io_queryME_0_primary_ready = '0, seen0_io_queryME_0_primary_ready = '0;
  logic seen1_io_queryME_0_secondary_ready = '0, seen0_io_queryME_0_secondary_ready = '0;
  logic seen1_io_queryME_0_secondary_reject = '0, seen0_io_queryME_0_secondary_reject = '0;
  logic seen1_io_queryME_1_primary_ready = '0, seen0_io_queryME_1_primary_ready = '0;
  logic seen1_io_queryME_1_secondary_ready = '0, seen0_io_queryME_1_secondary_ready = '0;
  logic seen1_io_queryME_1_secondary_reject = '0, seen0_io_queryME_1_secondary_reject = '0;
  logic seen1_io_queryME_2_primary_ready = '0, seen0_io_queryME_2_primary_ready = '0;
  logic seen1_io_queryME_2_secondary_ready = '0, seen0_io_queryME_2_secondary_ready = '0;
  logic seen1_io_queryME_2_secondary_reject = '0, seen0_io_queryME_2_secondary_reject = '0;
  logic seen1_io_queryME_3_primary_ready = '0, seen0_io_queryME_3_primary_ready = '0;
  logic seen1_io_queryME_3_secondary_ready = '0, seen0_io_queryME_3_secondary_ready = '0;
  logic seen1_io_queryME_3_secondary_reject = '0, seen0_io_queryME_3_secondary_reject = '0;
  logic seen1_io_refill_to_ldq_valid = '0, seen0_io_refill_to_ldq_valid = '0;
  logic [47:0] seen1_io_refill_to_ldq_bits_addr = '0, seen0_io_refill_to_ldq_bits_addr = '0;
  logic [255:0] seen1_io_refill_to_ldq_bits_data = '0, seen0_io_refill_to_ldq_bits_data = '0;
  logic seen1_io_refill_to_ldq_bits_error = '0, seen0_io_refill_to_ldq_bits_error = '0;
  logic [511:0] seen1_io_refill_to_ldq_bits_data_raw = '0, seen0_io_refill_to_ldq_bits_data_raw = '0;
  logic seen1_io_refill_to_ldq_bits_hasdata = '0, seen0_io_refill_to_ldq_bits_hasdata = '0;
  logic seen1_io_refill_to_ldq_bits_refill_done = '0, seen0_io_refill_to_ldq_bits_refill_done = '0;
  logic [3:0] seen1_io_refill_to_ldq_bits_id = '0, seen0_io_refill_to_ldq_bits_id = '0;
  logic seen1_io_main_pipe_req_valid = '0, seen0_io_main_pipe_req_valid = '0;
  logic [3:0] seen1_io_main_pipe_req_bits_miss_id = '0, seen0_io_main_pipe_req_bits_miss_id = '0;
  logic [3:0] seen1_io_main_pipe_req_bits_occupy_way = '0, seen0_io_main_pipe_req_bits_occupy_way = '0;
  logic seen1_io_main_pipe_req_bits_miss_fail_cause_evict_btot = '0, seen0_io_main_pipe_req_bits_miss_fail_cause_evict_btot = '0;
  logic [3:0] seen1_io_main_pipe_req_bits_source = '0, seen0_io_main_pipe_req_bits_source = '0;
  logic [4:0] seen1_io_main_pipe_req_bits_cmd = '0, seen0_io_main_pipe_req_bits_cmd = '0;
  logic [49:0] seen1_io_main_pipe_req_bits_vaddr = '0, seen0_io_main_pipe_req_bits_vaddr = '0;
  logic [47:0] seen1_io_main_pipe_req_bits_addr = '0, seen0_io_main_pipe_req_bits_addr = '0;
  logic [2:0] seen1_io_main_pipe_req_bits_word_idx = '0, seen0_io_main_pipe_req_bits_word_idx = '0;
  logic [127:0] seen1_io_main_pipe_req_bits_amo_data = '0, seen0_io_main_pipe_req_bits_amo_data = '0;
  logic [15:0] seen1_io_main_pipe_req_bits_amo_mask = '0, seen0_io_main_pipe_req_bits_amo_mask = '0;
  logic [127:0] seen1_io_main_pipe_req_bits_amo_cmp = '0, seen0_io_main_pipe_req_bits_amo_cmp = '0;
  logic [2:0] seen1_io_main_pipe_req_bits_pf_source = '0, seen0_io_main_pipe_req_bits_pf_source = '0;
  logic seen1_io_main_pipe_req_bits_access = '0, seen0_io_main_pipe_req_bits_access = '0;
  logic [5:0] seen1_io_main_pipe_req_bits_id = '0, seen0_io_main_pipe_req_bits_id = '0;
  logic seen1_io_refill_info_valid = '0, seen0_io_refill_info_valid = '0;
  logic [511:0] seen1_io_refill_info_bits_store_data = '0, seen0_io_refill_info_bits_store_data = '0;
  logic [1:0] seen1_io_refill_info_bits_miss_param = '0, seen0_io_refill_info_bits_miss_param = '0;
  logic seen1_io_refill_info_bits_error_tl_denied = '0, seen0_io_refill_info_bits_error_tl_denied = '0;
  logic seen1_io_refill_info_bits_error_tl_corrupt = '0, seen0_io_refill_info_bits_error_tl_corrupt = '0;
  logic [3:0] seen1_io_occupy_way = '0, seen0_io_occupy_way = '0;
  logic seen1_io_probe_block = '0, seen0_io_probe_block = '0;
  logic seen1_io_replace_block = '0, seen0_io_replace_block = '0;
  logic seen1_io_req_vaddr_valid = '0, seen0_io_req_vaddr_valid = '0;
  logic [49:0] seen1_io_req_vaddr_bits = '0, seen0_io_req_vaddr_bits = '0;
  logic seen1_io_req_isBtoT = '0, seen0_io_req_isBtoT = '0;
  logic seen1_io_req_handled_by_this_entry = '0, seen0_io_req_handled_by_this_entry = '0;
  logic seen1_io_forwardInfo_inflight = '0, seen0_io_forwardInfo_inflight = '0;
  logic [47:0] seen1_io_forwardInfo_paddr = '0, seen0_io_forwardInfo_paddr = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_0 = '0, seen0_io_forwardInfo_raw_data_0 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_1 = '0, seen0_io_forwardInfo_raw_data_1 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_2 = '0, seen0_io_forwardInfo_raw_data_2 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_3 = '0, seen0_io_forwardInfo_raw_data_3 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_4 = '0, seen0_io_forwardInfo_raw_data_4 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_5 = '0, seen0_io_forwardInfo_raw_data_5 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_6 = '0, seen0_io_forwardInfo_raw_data_6 = '0;
  logic [63:0] seen1_io_forwardInfo_raw_data_7 = '0, seen0_io_forwardInfo_raw_data_7 = '0;
  logic seen1_io_forwardInfo_firstbeat_valid = '0, seen0_io_forwardInfo_firstbeat_valid = '0;
  logic seen1_io_forwardInfo_lastbeat_valid = '0, seen0_io_forwardInfo_lastbeat_valid = '0;
  logic seen1_io_forwardInfo_denied = '0, seen0_io_forwardInfo_denied = '0;
  logic seen1_io_forwardInfo_corrupt = '0, seen0_io_forwardInfo_corrupt = '0;
  logic seen1_io_perf_pending_prefetch = '0, seen0_io_perf_pending_prefetch = '0;
  logic seen1_io_perf_pending_normal = '0, seen0_io_perf_pending_normal = '0;
  logic seen1_io_rob_head_query_resp = '0, seen0_io_rob_head_query_resp = '0;
  logic seen1_io_latency_monitor_load_miss_refilling = '0, seen0_io_latency_monitor_load_miss_refilling = '0;
  logic seen1_io_latency_monitor_store_miss_refilling = '0, seen0_io_latency_monitor_store_miss_refilling = '0;
  logic seen1_io_latency_monitor_amo_miss_refilling = '0, seen0_io_latency_monitor_amo_miss_refilling = '0;
  logic seen1_io_latency_monitor_pf_miss_refilling = '0, seen0_io_latency_monitor_pf_miss_refilling = '0;
  logic seen1_io_prefetch_info_late_prefetch = '0, seen0_io_prefetch_info_late_prefetch = '0;
  logic seen1_io_matched = '0, seen0_io_matched = '0;
  logic seen1_io_l1Miss = '0, seen0_io_l1Miss = '0;
  logic seen1_io_wfi_wfiSafe = '0, seen0_io_wfi_wfiSafe = '0;
  task automatic compare_outputs();
    if (g_io_primary_ready !== i_io_primary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_primary_ready: g=%h i=%h", cyc, g_io_primary_ready, i_io_primary_ready);
    end
    seen1_io_primary_ready |= g_io_primary_ready;
    seen0_io_primary_ready |= ~g_io_primary_ready;
    if (g_io_secondary_ready !== i_io_secondary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_secondary_ready: g=%h i=%h", cyc, g_io_secondary_ready, i_io_secondary_ready);
    end
    seen1_io_secondary_ready |= g_io_secondary_ready;
    seen0_io_secondary_ready |= ~g_io_secondary_ready;
    if (g_io_secondary_reject !== i_io_secondary_reject) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_secondary_reject: g=%h i=%h", cyc, g_io_secondary_reject, i_io_secondary_reject);
    end
    seen1_io_secondary_reject |= g_io_secondary_reject;
    seen0_io_secondary_reject |= ~g_io_secondary_reject;
    if (g_io_mem_acquire_valid !== i_io_mem_acquire_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_valid: g=%h i=%h", cyc, g_io_mem_acquire_valid, i_io_mem_acquire_valid);
    end
    seen1_io_mem_acquire_valid |= g_io_mem_acquire_valid;
    seen0_io_mem_acquire_valid |= ~g_io_mem_acquire_valid;
    if (g_io_mem_acquire_bits_opcode !== i_io_mem_acquire_bits_opcode) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_opcode: g=%h i=%h", cyc, g_io_mem_acquire_bits_opcode, i_io_mem_acquire_bits_opcode);
    end
    seen1_io_mem_acquire_bits_opcode |= g_io_mem_acquire_bits_opcode;
    seen0_io_mem_acquire_bits_opcode |= ~g_io_mem_acquire_bits_opcode;
    if (g_io_mem_acquire_bits_param !== i_io_mem_acquire_bits_param) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_param: g=%h i=%h", cyc, g_io_mem_acquire_bits_param, i_io_mem_acquire_bits_param);
    end
    seen1_io_mem_acquire_bits_param |= g_io_mem_acquire_bits_param;
    seen0_io_mem_acquire_bits_param |= ~g_io_mem_acquire_bits_param;
    if (g_io_mem_acquire_bits_source !== i_io_mem_acquire_bits_source) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_source: g=%h i=%h", cyc, g_io_mem_acquire_bits_source, i_io_mem_acquire_bits_source);
    end
    seen1_io_mem_acquire_bits_source |= g_io_mem_acquire_bits_source;
    seen0_io_mem_acquire_bits_source |= ~g_io_mem_acquire_bits_source;
    if (g_io_mem_acquire_bits_address !== i_io_mem_acquire_bits_address) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_address: g=%h i=%h", cyc, g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address);
    end
    seen1_io_mem_acquire_bits_address |= g_io_mem_acquire_bits_address;
    seen0_io_mem_acquire_bits_address |= ~g_io_mem_acquire_bits_address;
    if (g_io_mem_acquire_bits_user_alias !== i_io_mem_acquire_bits_user_alias) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_user_alias: g=%h i=%h", cyc, g_io_mem_acquire_bits_user_alias, i_io_mem_acquire_bits_user_alias);
    end
    seen1_io_mem_acquire_bits_user_alias |= g_io_mem_acquire_bits_user_alias;
    seen0_io_mem_acquire_bits_user_alias |= ~g_io_mem_acquire_bits_user_alias;
    if (g_io_mem_acquire_bits_user_vaddr !== i_io_mem_acquire_bits_user_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_user_vaddr: g=%h i=%h", cyc, g_io_mem_acquire_bits_user_vaddr, i_io_mem_acquire_bits_user_vaddr);
    end
    seen1_io_mem_acquire_bits_user_vaddr |= g_io_mem_acquire_bits_user_vaddr;
    seen0_io_mem_acquire_bits_user_vaddr |= ~g_io_mem_acquire_bits_user_vaddr;
    if (g_io_mem_acquire_bits_user_reqSource !== i_io_mem_acquire_bits_user_reqSource) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_user_reqSource: g=%h i=%h", cyc, g_io_mem_acquire_bits_user_reqSource, i_io_mem_acquire_bits_user_reqSource);
    end
    seen1_io_mem_acquire_bits_user_reqSource |= g_io_mem_acquire_bits_user_reqSource;
    seen0_io_mem_acquire_bits_user_reqSource |= ~g_io_mem_acquire_bits_user_reqSource;
    if (g_io_mem_acquire_bits_user_needHint !== i_io_mem_acquire_bits_user_needHint) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_user_needHint: g=%h i=%h", cyc, g_io_mem_acquire_bits_user_needHint, i_io_mem_acquire_bits_user_needHint);
    end
    seen1_io_mem_acquire_bits_user_needHint |= g_io_mem_acquire_bits_user_needHint;
    seen0_io_mem_acquire_bits_user_needHint |= ~g_io_mem_acquire_bits_user_needHint;
    if (g_io_mem_acquire_bits_echo_isKeyword !== i_io_mem_acquire_bits_echo_isKeyword) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_echo_isKeyword: g=%h i=%h", cyc, g_io_mem_acquire_bits_echo_isKeyword, i_io_mem_acquire_bits_echo_isKeyword);
    end
    seen1_io_mem_acquire_bits_echo_isKeyword |= g_io_mem_acquire_bits_echo_isKeyword;
    seen0_io_mem_acquire_bits_echo_isKeyword |= ~g_io_mem_acquire_bits_echo_isKeyword;
    if (g_io_mem_finish_valid !== i_io_mem_finish_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_finish_valid: g=%h i=%h", cyc, g_io_mem_finish_valid, i_io_mem_finish_valid);
    end
    seen1_io_mem_finish_valid |= g_io_mem_finish_valid;
    seen0_io_mem_finish_valid |= ~g_io_mem_finish_valid;
    if (g_io_mem_finish_bits_sink !== i_io_mem_finish_bits_sink) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_finish_bits_sink: g=%h i=%h", cyc, g_io_mem_finish_bits_sink, i_io_mem_finish_bits_sink);
    end
    seen1_io_mem_finish_bits_sink |= g_io_mem_finish_bits_sink;
    seen0_io_mem_finish_bits_sink |= ~g_io_mem_finish_bits_sink;
    if (g_io_queryME_0_primary_ready !== i_io_queryME_0_primary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_0_primary_ready: g=%h i=%h", cyc, g_io_queryME_0_primary_ready, i_io_queryME_0_primary_ready);
    end
    seen1_io_queryME_0_primary_ready |= g_io_queryME_0_primary_ready;
    seen0_io_queryME_0_primary_ready |= ~g_io_queryME_0_primary_ready;
    if (g_io_queryME_0_secondary_ready !== i_io_queryME_0_secondary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_0_secondary_ready: g=%h i=%h", cyc, g_io_queryME_0_secondary_ready, i_io_queryME_0_secondary_ready);
    end
    seen1_io_queryME_0_secondary_ready |= g_io_queryME_0_secondary_ready;
    seen0_io_queryME_0_secondary_ready |= ~g_io_queryME_0_secondary_ready;
    if (g_io_queryME_0_secondary_reject !== i_io_queryME_0_secondary_reject) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_0_secondary_reject: g=%h i=%h", cyc, g_io_queryME_0_secondary_reject, i_io_queryME_0_secondary_reject);
    end
    seen1_io_queryME_0_secondary_reject |= g_io_queryME_0_secondary_reject;
    seen0_io_queryME_0_secondary_reject |= ~g_io_queryME_0_secondary_reject;
    if (g_io_queryME_1_primary_ready !== i_io_queryME_1_primary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_1_primary_ready: g=%h i=%h", cyc, g_io_queryME_1_primary_ready, i_io_queryME_1_primary_ready);
    end
    seen1_io_queryME_1_primary_ready |= g_io_queryME_1_primary_ready;
    seen0_io_queryME_1_primary_ready |= ~g_io_queryME_1_primary_ready;
    if (g_io_queryME_1_secondary_ready !== i_io_queryME_1_secondary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_1_secondary_ready: g=%h i=%h", cyc, g_io_queryME_1_secondary_ready, i_io_queryME_1_secondary_ready);
    end
    seen1_io_queryME_1_secondary_ready |= g_io_queryME_1_secondary_ready;
    seen0_io_queryME_1_secondary_ready |= ~g_io_queryME_1_secondary_ready;
    if (g_io_queryME_1_secondary_reject !== i_io_queryME_1_secondary_reject) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_1_secondary_reject: g=%h i=%h", cyc, g_io_queryME_1_secondary_reject, i_io_queryME_1_secondary_reject);
    end
    seen1_io_queryME_1_secondary_reject |= g_io_queryME_1_secondary_reject;
    seen0_io_queryME_1_secondary_reject |= ~g_io_queryME_1_secondary_reject;
    if (g_io_queryME_2_primary_ready !== i_io_queryME_2_primary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_2_primary_ready: g=%h i=%h", cyc, g_io_queryME_2_primary_ready, i_io_queryME_2_primary_ready);
    end
    seen1_io_queryME_2_primary_ready |= g_io_queryME_2_primary_ready;
    seen0_io_queryME_2_primary_ready |= ~g_io_queryME_2_primary_ready;
    if (g_io_queryME_2_secondary_ready !== i_io_queryME_2_secondary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_2_secondary_ready: g=%h i=%h", cyc, g_io_queryME_2_secondary_ready, i_io_queryME_2_secondary_ready);
    end
    seen1_io_queryME_2_secondary_ready |= g_io_queryME_2_secondary_ready;
    seen0_io_queryME_2_secondary_ready |= ~g_io_queryME_2_secondary_ready;
    if (g_io_queryME_2_secondary_reject !== i_io_queryME_2_secondary_reject) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_2_secondary_reject: g=%h i=%h", cyc, g_io_queryME_2_secondary_reject, i_io_queryME_2_secondary_reject);
    end
    seen1_io_queryME_2_secondary_reject |= g_io_queryME_2_secondary_reject;
    seen0_io_queryME_2_secondary_reject |= ~g_io_queryME_2_secondary_reject;
    if (g_io_queryME_3_primary_ready !== i_io_queryME_3_primary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_3_primary_ready: g=%h i=%h", cyc, g_io_queryME_3_primary_ready, i_io_queryME_3_primary_ready);
    end
    seen1_io_queryME_3_primary_ready |= g_io_queryME_3_primary_ready;
    seen0_io_queryME_3_primary_ready |= ~g_io_queryME_3_primary_ready;
    if (g_io_queryME_3_secondary_ready !== i_io_queryME_3_secondary_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_3_secondary_ready: g=%h i=%h", cyc, g_io_queryME_3_secondary_ready, i_io_queryME_3_secondary_ready);
    end
    seen1_io_queryME_3_secondary_ready |= g_io_queryME_3_secondary_ready;
    seen0_io_queryME_3_secondary_ready |= ~g_io_queryME_3_secondary_ready;
    if (g_io_queryME_3_secondary_reject !== i_io_queryME_3_secondary_reject) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryME_3_secondary_reject: g=%h i=%h", cyc, g_io_queryME_3_secondary_reject, i_io_queryME_3_secondary_reject);
    end
    seen1_io_queryME_3_secondary_reject |= g_io_queryME_3_secondary_reject;
    seen0_io_queryME_3_secondary_reject |= ~g_io_queryME_3_secondary_reject;
    if (g_io_refill_to_ldq_valid !== i_io_refill_to_ldq_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_valid: g=%h i=%h", cyc, g_io_refill_to_ldq_valid, i_io_refill_to_ldq_valid);
    end
    seen1_io_refill_to_ldq_valid |= g_io_refill_to_ldq_valid;
    seen0_io_refill_to_ldq_valid |= ~g_io_refill_to_ldq_valid;
    if (g_io_refill_to_ldq_bits_addr !== i_io_refill_to_ldq_bits_addr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_addr: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_addr, i_io_refill_to_ldq_bits_addr);
    end
    seen1_io_refill_to_ldq_bits_addr |= g_io_refill_to_ldq_bits_addr;
    seen0_io_refill_to_ldq_bits_addr |= ~g_io_refill_to_ldq_bits_addr;
    if (g_io_refill_to_ldq_bits_data !== i_io_refill_to_ldq_bits_data) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_data: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_data, i_io_refill_to_ldq_bits_data);
    end
    seen1_io_refill_to_ldq_bits_data |= g_io_refill_to_ldq_bits_data;
    seen0_io_refill_to_ldq_bits_data |= ~g_io_refill_to_ldq_bits_data;
    if (g_io_refill_to_ldq_bits_error !== i_io_refill_to_ldq_bits_error) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_error: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_error, i_io_refill_to_ldq_bits_error);
    end
    seen1_io_refill_to_ldq_bits_error |= g_io_refill_to_ldq_bits_error;
    seen0_io_refill_to_ldq_bits_error |= ~g_io_refill_to_ldq_bits_error;
    if (g_io_refill_to_ldq_bits_data_raw !== i_io_refill_to_ldq_bits_data_raw) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_data_raw: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_data_raw, i_io_refill_to_ldq_bits_data_raw);
    end
    seen1_io_refill_to_ldq_bits_data_raw |= g_io_refill_to_ldq_bits_data_raw;
    seen0_io_refill_to_ldq_bits_data_raw |= ~g_io_refill_to_ldq_bits_data_raw;
    if (g_io_refill_to_ldq_bits_hasdata !== i_io_refill_to_ldq_bits_hasdata) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_hasdata: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_hasdata, i_io_refill_to_ldq_bits_hasdata);
    end
    seen1_io_refill_to_ldq_bits_hasdata |= g_io_refill_to_ldq_bits_hasdata;
    seen0_io_refill_to_ldq_bits_hasdata |= ~g_io_refill_to_ldq_bits_hasdata;
    if (g_io_refill_to_ldq_bits_refill_done !== i_io_refill_to_ldq_bits_refill_done) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_refill_done: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_refill_done, i_io_refill_to_ldq_bits_refill_done);
    end
    seen1_io_refill_to_ldq_bits_refill_done |= g_io_refill_to_ldq_bits_refill_done;
    seen0_io_refill_to_ldq_bits_refill_done |= ~g_io_refill_to_ldq_bits_refill_done;
    if (g_io_refill_to_ldq_bits_id !== i_io_refill_to_ldq_bits_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_to_ldq_bits_id: g=%h i=%h", cyc, g_io_refill_to_ldq_bits_id, i_io_refill_to_ldq_bits_id);
    end
    seen1_io_refill_to_ldq_bits_id |= g_io_refill_to_ldq_bits_id;
    seen0_io_refill_to_ldq_bits_id |= ~g_io_refill_to_ldq_bits_id;
    if (g_io_main_pipe_req_valid !== i_io_main_pipe_req_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_valid: g=%h i=%h", cyc, g_io_main_pipe_req_valid, i_io_main_pipe_req_valid);
    end
    seen1_io_main_pipe_req_valid |= g_io_main_pipe_req_valid;
    seen0_io_main_pipe_req_valid |= ~g_io_main_pipe_req_valid;
    if (g_io_main_pipe_req_bits_miss_id !== i_io_main_pipe_req_bits_miss_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_miss_id: g=%h i=%h", cyc, g_io_main_pipe_req_bits_miss_id, i_io_main_pipe_req_bits_miss_id);
    end
    seen1_io_main_pipe_req_bits_miss_id |= g_io_main_pipe_req_bits_miss_id;
    seen0_io_main_pipe_req_bits_miss_id |= ~g_io_main_pipe_req_bits_miss_id;
    if (g_io_main_pipe_req_bits_occupy_way !== i_io_main_pipe_req_bits_occupy_way) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_occupy_way: g=%h i=%h", cyc, g_io_main_pipe_req_bits_occupy_way, i_io_main_pipe_req_bits_occupy_way);
    end
    seen1_io_main_pipe_req_bits_occupy_way |= g_io_main_pipe_req_bits_occupy_way;
    seen0_io_main_pipe_req_bits_occupy_way |= ~g_io_main_pipe_req_bits_occupy_way;
    if (g_io_main_pipe_req_bits_miss_fail_cause_evict_btot !== i_io_main_pipe_req_bits_miss_fail_cause_evict_btot) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_miss_fail_cause_evict_btot: g=%h i=%h", cyc, g_io_main_pipe_req_bits_miss_fail_cause_evict_btot, i_io_main_pipe_req_bits_miss_fail_cause_evict_btot);
    end
    seen1_io_main_pipe_req_bits_miss_fail_cause_evict_btot |= g_io_main_pipe_req_bits_miss_fail_cause_evict_btot;
    seen0_io_main_pipe_req_bits_miss_fail_cause_evict_btot |= ~g_io_main_pipe_req_bits_miss_fail_cause_evict_btot;
    if (g_io_main_pipe_req_bits_source !== i_io_main_pipe_req_bits_source) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_source: g=%h i=%h", cyc, g_io_main_pipe_req_bits_source, i_io_main_pipe_req_bits_source);
    end
    seen1_io_main_pipe_req_bits_source |= g_io_main_pipe_req_bits_source;
    seen0_io_main_pipe_req_bits_source |= ~g_io_main_pipe_req_bits_source;
    if (g_io_main_pipe_req_bits_cmd !== i_io_main_pipe_req_bits_cmd) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_cmd: g=%h i=%h", cyc, g_io_main_pipe_req_bits_cmd, i_io_main_pipe_req_bits_cmd);
    end
    seen1_io_main_pipe_req_bits_cmd |= g_io_main_pipe_req_bits_cmd;
    seen0_io_main_pipe_req_bits_cmd |= ~g_io_main_pipe_req_bits_cmd;
    if (g_io_main_pipe_req_bits_vaddr !== i_io_main_pipe_req_bits_vaddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_vaddr: g=%h i=%h", cyc, g_io_main_pipe_req_bits_vaddr, i_io_main_pipe_req_bits_vaddr);
    end
    seen1_io_main_pipe_req_bits_vaddr |= g_io_main_pipe_req_bits_vaddr;
    seen0_io_main_pipe_req_bits_vaddr |= ~g_io_main_pipe_req_bits_vaddr;
    if (g_io_main_pipe_req_bits_addr !== i_io_main_pipe_req_bits_addr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_addr: g=%h i=%h", cyc, g_io_main_pipe_req_bits_addr, i_io_main_pipe_req_bits_addr);
    end
    seen1_io_main_pipe_req_bits_addr |= g_io_main_pipe_req_bits_addr;
    seen0_io_main_pipe_req_bits_addr |= ~g_io_main_pipe_req_bits_addr;
    if (g_io_main_pipe_req_bits_word_idx !== i_io_main_pipe_req_bits_word_idx) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_word_idx: g=%h i=%h", cyc, g_io_main_pipe_req_bits_word_idx, i_io_main_pipe_req_bits_word_idx);
    end
    seen1_io_main_pipe_req_bits_word_idx |= g_io_main_pipe_req_bits_word_idx;
    seen0_io_main_pipe_req_bits_word_idx |= ~g_io_main_pipe_req_bits_word_idx;
    if (g_io_main_pipe_req_bits_amo_data !== i_io_main_pipe_req_bits_amo_data) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_amo_data: g=%h i=%h", cyc, g_io_main_pipe_req_bits_amo_data, i_io_main_pipe_req_bits_amo_data);
    end
    seen1_io_main_pipe_req_bits_amo_data |= g_io_main_pipe_req_bits_amo_data;
    seen0_io_main_pipe_req_bits_amo_data |= ~g_io_main_pipe_req_bits_amo_data;
    if (g_io_main_pipe_req_bits_amo_mask !== i_io_main_pipe_req_bits_amo_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_amo_mask: g=%h i=%h", cyc, g_io_main_pipe_req_bits_amo_mask, i_io_main_pipe_req_bits_amo_mask);
    end
    seen1_io_main_pipe_req_bits_amo_mask |= g_io_main_pipe_req_bits_amo_mask;
    seen0_io_main_pipe_req_bits_amo_mask |= ~g_io_main_pipe_req_bits_amo_mask;
    if (g_io_main_pipe_req_bits_amo_cmp !== i_io_main_pipe_req_bits_amo_cmp) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_amo_cmp: g=%h i=%h", cyc, g_io_main_pipe_req_bits_amo_cmp, i_io_main_pipe_req_bits_amo_cmp);
    end
    seen1_io_main_pipe_req_bits_amo_cmp |= g_io_main_pipe_req_bits_amo_cmp;
    seen0_io_main_pipe_req_bits_amo_cmp |= ~g_io_main_pipe_req_bits_amo_cmp;
    if (g_io_main_pipe_req_bits_pf_source !== i_io_main_pipe_req_bits_pf_source) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_pf_source: g=%h i=%h", cyc, g_io_main_pipe_req_bits_pf_source, i_io_main_pipe_req_bits_pf_source);
    end
    seen1_io_main_pipe_req_bits_pf_source |= g_io_main_pipe_req_bits_pf_source;
    seen0_io_main_pipe_req_bits_pf_source |= ~g_io_main_pipe_req_bits_pf_source;
    if (g_io_main_pipe_req_bits_access !== i_io_main_pipe_req_bits_access) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_access: g=%h i=%h", cyc, g_io_main_pipe_req_bits_access, i_io_main_pipe_req_bits_access);
    end
    seen1_io_main_pipe_req_bits_access |= g_io_main_pipe_req_bits_access;
    seen0_io_main_pipe_req_bits_access |= ~g_io_main_pipe_req_bits_access;
    if (g_io_main_pipe_req_bits_id !== i_io_main_pipe_req_bits_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_main_pipe_req_bits_id: g=%h i=%h", cyc, g_io_main_pipe_req_bits_id, i_io_main_pipe_req_bits_id);
    end
    seen1_io_main_pipe_req_bits_id |= g_io_main_pipe_req_bits_id;
    seen0_io_main_pipe_req_bits_id |= ~g_io_main_pipe_req_bits_id;
    if (g_io_refill_info_valid !== i_io_refill_info_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_valid: g=%h i=%h", cyc, g_io_refill_info_valid, i_io_refill_info_valid);
    end
    seen1_io_refill_info_valid |= g_io_refill_info_valid;
    seen0_io_refill_info_valid |= ~g_io_refill_info_valid;
    if (g_io_refill_info_bits_store_data !== i_io_refill_info_bits_store_data) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_bits_store_data: g=%h i=%h", cyc, g_io_refill_info_bits_store_data, i_io_refill_info_bits_store_data);
    end
    seen1_io_refill_info_bits_store_data |= g_io_refill_info_bits_store_data;
    seen0_io_refill_info_bits_store_data |= ~g_io_refill_info_bits_store_data;
    if (g_io_refill_info_bits_miss_param !== i_io_refill_info_bits_miss_param) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_bits_miss_param: g=%h i=%h", cyc, g_io_refill_info_bits_miss_param, i_io_refill_info_bits_miss_param);
    end
    seen1_io_refill_info_bits_miss_param |= g_io_refill_info_bits_miss_param;
    seen0_io_refill_info_bits_miss_param |= ~g_io_refill_info_bits_miss_param;
    if (g_io_refill_info_bits_error_tl_denied !== i_io_refill_info_bits_error_tl_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_bits_error_tl_denied: g=%h i=%h", cyc, g_io_refill_info_bits_error_tl_denied, i_io_refill_info_bits_error_tl_denied);
    end
    seen1_io_refill_info_bits_error_tl_denied |= g_io_refill_info_bits_error_tl_denied;
    seen0_io_refill_info_bits_error_tl_denied |= ~g_io_refill_info_bits_error_tl_denied;
    if (g_io_refill_info_bits_error_tl_corrupt !== i_io_refill_info_bits_error_tl_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_bits_error_tl_corrupt: g=%h i=%h", cyc, g_io_refill_info_bits_error_tl_corrupt, i_io_refill_info_bits_error_tl_corrupt);
    end
    seen1_io_refill_info_bits_error_tl_corrupt |= g_io_refill_info_bits_error_tl_corrupt;
    seen0_io_refill_info_bits_error_tl_corrupt |= ~g_io_refill_info_bits_error_tl_corrupt;
    if (g_io_occupy_way !== i_io_occupy_way) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_occupy_way: g=%h i=%h", cyc, g_io_occupy_way, i_io_occupy_way);
    end
    seen1_io_occupy_way |= g_io_occupy_way;
    seen0_io_occupy_way |= ~g_io_occupy_way;
    if (g_io_probe_block !== i_io_probe_block) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_probe_block: g=%h i=%h", cyc, g_io_probe_block, i_io_probe_block);
    end
    seen1_io_probe_block |= g_io_probe_block;
    seen0_io_probe_block |= ~g_io_probe_block;
    if (g_io_replace_block !== i_io_replace_block) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_replace_block: g=%h i=%h", cyc, g_io_replace_block, i_io_replace_block);
    end
    seen1_io_replace_block |= g_io_replace_block;
    seen0_io_replace_block |= ~g_io_replace_block;
    if (g_io_req_vaddr_valid !== i_io_req_vaddr_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_vaddr_valid: g=%h i=%h", cyc, g_io_req_vaddr_valid, i_io_req_vaddr_valid);
    end
    seen1_io_req_vaddr_valid |= g_io_req_vaddr_valid;
    seen0_io_req_vaddr_valid |= ~g_io_req_vaddr_valid;
    if (g_io_req_vaddr_bits !== i_io_req_vaddr_bits) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_vaddr_bits: g=%h i=%h", cyc, g_io_req_vaddr_bits, i_io_req_vaddr_bits);
    end
    seen1_io_req_vaddr_bits |= g_io_req_vaddr_bits;
    seen0_io_req_vaddr_bits |= ~g_io_req_vaddr_bits;
    if (g_io_req_isBtoT !== i_io_req_isBtoT) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_isBtoT: g=%h i=%h", cyc, g_io_req_isBtoT, i_io_req_isBtoT);
    end
    seen1_io_req_isBtoT |= g_io_req_isBtoT;
    seen0_io_req_isBtoT |= ~g_io_req_isBtoT;
    if (g_io_req_handled_by_this_entry !== i_io_req_handled_by_this_entry) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_handled_by_this_entry: g=%h i=%h", cyc, g_io_req_handled_by_this_entry, i_io_req_handled_by_this_entry);
    end
    seen1_io_req_handled_by_this_entry |= g_io_req_handled_by_this_entry;
    seen0_io_req_handled_by_this_entry |= ~g_io_req_handled_by_this_entry;
    if (g_io_forwardInfo_inflight !== i_io_forwardInfo_inflight) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_inflight: g=%h i=%h", cyc, g_io_forwardInfo_inflight, i_io_forwardInfo_inflight);
    end
    seen1_io_forwardInfo_inflight |= g_io_forwardInfo_inflight;
    seen0_io_forwardInfo_inflight |= ~g_io_forwardInfo_inflight;
    if (g_io_forwardInfo_paddr !== i_io_forwardInfo_paddr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_paddr: g=%h i=%h", cyc, g_io_forwardInfo_paddr, i_io_forwardInfo_paddr);
    end
    seen1_io_forwardInfo_paddr |= g_io_forwardInfo_paddr;
    seen0_io_forwardInfo_paddr |= ~g_io_forwardInfo_paddr;
    if (g_io_forwardInfo_raw_data_0 !== i_io_forwardInfo_raw_data_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_0: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_0, i_io_forwardInfo_raw_data_0);
    end
    seen1_io_forwardInfo_raw_data_0 |= g_io_forwardInfo_raw_data_0;
    seen0_io_forwardInfo_raw_data_0 |= ~g_io_forwardInfo_raw_data_0;
    if (g_io_forwardInfo_raw_data_1 !== i_io_forwardInfo_raw_data_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_1: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_1, i_io_forwardInfo_raw_data_1);
    end
    seen1_io_forwardInfo_raw_data_1 |= g_io_forwardInfo_raw_data_1;
    seen0_io_forwardInfo_raw_data_1 |= ~g_io_forwardInfo_raw_data_1;
    if (g_io_forwardInfo_raw_data_2 !== i_io_forwardInfo_raw_data_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_2: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_2, i_io_forwardInfo_raw_data_2);
    end
    seen1_io_forwardInfo_raw_data_2 |= g_io_forwardInfo_raw_data_2;
    seen0_io_forwardInfo_raw_data_2 |= ~g_io_forwardInfo_raw_data_2;
    if (g_io_forwardInfo_raw_data_3 !== i_io_forwardInfo_raw_data_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_3: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_3, i_io_forwardInfo_raw_data_3);
    end
    seen1_io_forwardInfo_raw_data_3 |= g_io_forwardInfo_raw_data_3;
    seen0_io_forwardInfo_raw_data_3 |= ~g_io_forwardInfo_raw_data_3;
    if (g_io_forwardInfo_raw_data_4 !== i_io_forwardInfo_raw_data_4) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_4: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_4, i_io_forwardInfo_raw_data_4);
    end
    seen1_io_forwardInfo_raw_data_4 |= g_io_forwardInfo_raw_data_4;
    seen0_io_forwardInfo_raw_data_4 |= ~g_io_forwardInfo_raw_data_4;
    if (g_io_forwardInfo_raw_data_5 !== i_io_forwardInfo_raw_data_5) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_5: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_5, i_io_forwardInfo_raw_data_5);
    end
    seen1_io_forwardInfo_raw_data_5 |= g_io_forwardInfo_raw_data_5;
    seen0_io_forwardInfo_raw_data_5 |= ~g_io_forwardInfo_raw_data_5;
    if (g_io_forwardInfo_raw_data_6 !== i_io_forwardInfo_raw_data_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_6: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_6, i_io_forwardInfo_raw_data_6);
    end
    seen1_io_forwardInfo_raw_data_6 |= g_io_forwardInfo_raw_data_6;
    seen0_io_forwardInfo_raw_data_6 |= ~g_io_forwardInfo_raw_data_6;
    if (g_io_forwardInfo_raw_data_7 !== i_io_forwardInfo_raw_data_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_raw_data_7: g=%h i=%h", cyc, g_io_forwardInfo_raw_data_7, i_io_forwardInfo_raw_data_7);
    end
    seen1_io_forwardInfo_raw_data_7 |= g_io_forwardInfo_raw_data_7;
    seen0_io_forwardInfo_raw_data_7 |= ~g_io_forwardInfo_raw_data_7;
    if (g_io_forwardInfo_firstbeat_valid !== i_io_forwardInfo_firstbeat_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_firstbeat_valid: g=%h i=%h", cyc, g_io_forwardInfo_firstbeat_valid, i_io_forwardInfo_firstbeat_valid);
    end
    seen1_io_forwardInfo_firstbeat_valid |= g_io_forwardInfo_firstbeat_valid;
    seen0_io_forwardInfo_firstbeat_valid |= ~g_io_forwardInfo_firstbeat_valid;
    if (g_io_forwardInfo_lastbeat_valid !== i_io_forwardInfo_lastbeat_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_lastbeat_valid: g=%h i=%h", cyc, g_io_forwardInfo_lastbeat_valid, i_io_forwardInfo_lastbeat_valid);
    end
    seen1_io_forwardInfo_lastbeat_valid |= g_io_forwardInfo_lastbeat_valid;
    seen0_io_forwardInfo_lastbeat_valid |= ~g_io_forwardInfo_lastbeat_valid;
    if (g_io_forwardInfo_denied !== i_io_forwardInfo_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_denied: g=%h i=%h", cyc, g_io_forwardInfo_denied, i_io_forwardInfo_denied);
    end
    seen1_io_forwardInfo_denied |= g_io_forwardInfo_denied;
    seen0_io_forwardInfo_denied |= ~g_io_forwardInfo_denied;
    if (g_io_forwardInfo_corrupt !== i_io_forwardInfo_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forwardInfo_corrupt: g=%h i=%h", cyc, g_io_forwardInfo_corrupt, i_io_forwardInfo_corrupt);
    end
    seen1_io_forwardInfo_corrupt |= g_io_forwardInfo_corrupt;
    seen0_io_forwardInfo_corrupt |= ~g_io_forwardInfo_corrupt;
    if (g_io_perf_pending_prefetch !== i_io_perf_pending_prefetch) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_pending_prefetch: g=%h i=%h", cyc, g_io_perf_pending_prefetch, i_io_perf_pending_prefetch);
    end
    seen1_io_perf_pending_prefetch |= g_io_perf_pending_prefetch;
    seen0_io_perf_pending_prefetch |= ~g_io_perf_pending_prefetch;
    if (g_io_perf_pending_normal !== i_io_perf_pending_normal) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_pending_normal: g=%h i=%h", cyc, g_io_perf_pending_normal, i_io_perf_pending_normal);
    end
    seen1_io_perf_pending_normal |= g_io_perf_pending_normal;
    seen0_io_perf_pending_normal |= ~g_io_perf_pending_normal;
    if (g_io_rob_head_query_resp !== i_io_rob_head_query_resp) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_rob_head_query_resp: g=%h i=%h", cyc, g_io_rob_head_query_resp, i_io_rob_head_query_resp);
    end
    seen1_io_rob_head_query_resp |= g_io_rob_head_query_resp;
    seen0_io_rob_head_query_resp |= ~g_io_rob_head_query_resp;
    if (g_io_latency_monitor_load_miss_refilling !== i_io_latency_monitor_load_miss_refilling) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_latency_monitor_load_miss_refilling: g=%h i=%h", cyc, g_io_latency_monitor_load_miss_refilling, i_io_latency_monitor_load_miss_refilling);
    end
    seen1_io_latency_monitor_load_miss_refilling |= g_io_latency_monitor_load_miss_refilling;
    seen0_io_latency_monitor_load_miss_refilling |= ~g_io_latency_monitor_load_miss_refilling;
    if (g_io_latency_monitor_store_miss_refilling !== i_io_latency_monitor_store_miss_refilling) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_latency_monitor_store_miss_refilling: g=%h i=%h", cyc, g_io_latency_monitor_store_miss_refilling, i_io_latency_monitor_store_miss_refilling);
    end
    seen1_io_latency_monitor_store_miss_refilling |= g_io_latency_monitor_store_miss_refilling;
    seen0_io_latency_monitor_store_miss_refilling |= ~g_io_latency_monitor_store_miss_refilling;
    if (g_io_latency_monitor_amo_miss_refilling !== i_io_latency_monitor_amo_miss_refilling) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_latency_monitor_amo_miss_refilling: g=%h i=%h", cyc, g_io_latency_monitor_amo_miss_refilling, i_io_latency_monitor_amo_miss_refilling);
    end
    seen1_io_latency_monitor_amo_miss_refilling |= g_io_latency_monitor_amo_miss_refilling;
    seen0_io_latency_monitor_amo_miss_refilling |= ~g_io_latency_monitor_amo_miss_refilling;
    if (g_io_latency_monitor_pf_miss_refilling !== i_io_latency_monitor_pf_miss_refilling) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_latency_monitor_pf_miss_refilling: g=%h i=%h", cyc, g_io_latency_monitor_pf_miss_refilling, i_io_latency_monitor_pf_miss_refilling);
    end
    seen1_io_latency_monitor_pf_miss_refilling |= g_io_latency_monitor_pf_miss_refilling;
    seen0_io_latency_monitor_pf_miss_refilling |= ~g_io_latency_monitor_pf_miss_refilling;
    if (g_io_prefetch_info_late_prefetch !== i_io_prefetch_info_late_prefetch) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_prefetch_info_late_prefetch: g=%h i=%h", cyc, g_io_prefetch_info_late_prefetch, i_io_prefetch_info_late_prefetch);
    end
    seen1_io_prefetch_info_late_prefetch |= g_io_prefetch_info_late_prefetch;
    seen0_io_prefetch_info_late_prefetch |= ~g_io_prefetch_info_late_prefetch;
    if (g_io_matched !== i_io_matched) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_matched: g=%h i=%h", cyc, g_io_matched, i_io_matched);
    end
    seen1_io_matched |= g_io_matched;
    seen0_io_matched |= ~g_io_matched;
    if (g_io_l1Miss !== i_io_l1Miss) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_l1Miss: g=%h i=%h", cyc, g_io_l1Miss, i_io_l1Miss);
    end
    seen1_io_l1Miss |= g_io_l1Miss;
    seen0_io_l1Miss |= ~g_io_l1Miss;
    if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_wfi_wfiSafe: g=%h i=%h", cyc, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe);
    end
    seen1_io_wfi_wfiSafe |= g_io_wfi_wfiSafe;
    seen0_io_wfi_wfiSafe |= ~g_io_wfi_wfiSafe;
    checks++;
  endtask
  // 返回从未翻转过的输出端口个数（逐个打印）
  function automatic int report_toggle();
    int bad = 0;
    if (((~seen1_io_primary_ready | ~seen0_io_primary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_primary_ready 1=%h 0=%h", seen1_io_primary_ready, seen0_io_primary_ready); end
    if (((~seen1_io_secondary_ready | ~seen0_io_secondary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_secondary_ready 1=%h 0=%h", seen1_io_secondary_ready, seen0_io_secondary_ready); end
    if (((~seen1_io_secondary_reject | ~seen0_io_secondary_reject)) != '0) begin bad++; $display("TOGGLE MISS io_secondary_reject 1=%h 0=%h", seen1_io_secondary_reject, seen0_io_secondary_reject); end
    if (((~seen1_io_mem_acquire_valid | ~seen0_io_mem_acquire_valid)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_valid 1=%h 0=%h", seen1_io_mem_acquire_valid, seen0_io_mem_acquire_valid); end
    if (((~seen1_io_mem_acquire_bits_opcode | ~seen0_io_mem_acquire_bits_opcode) & ~4'he) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_opcode 1=%h 0=%h", seen1_io_mem_acquire_bits_opcode, seen0_io_mem_acquire_bits_opcode); end
    if (((~seen1_io_mem_acquire_bits_param | ~seen0_io_mem_acquire_bits_param) & ~3'h4) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_param 1=%h 0=%h", seen1_io_mem_acquire_bits_param, seen0_io_mem_acquire_bits_param); end
    if (((~seen1_io_mem_acquire_bits_source | ~seen0_io_mem_acquire_bits_source) & ~6'h30) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_source 1=%h 0=%h", seen1_io_mem_acquire_bits_source, seen0_io_mem_acquire_bits_source); end
    if (((~seen1_io_mem_acquire_bits_address | ~seen0_io_mem_acquire_bits_address) & ~48'h3f) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_address 1=%h 0=%h", seen1_io_mem_acquire_bits_address, seen0_io_mem_acquire_bits_address); end
    if (((~seen1_io_mem_acquire_bits_user_alias | ~seen0_io_mem_acquire_bits_user_alias)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_alias 1=%h 0=%h", seen1_io_mem_acquire_bits_user_alias, seen0_io_mem_acquire_bits_user_alias); end
    if (((~seen1_io_mem_acquire_bits_user_vaddr | ~seen0_io_mem_acquire_bits_user_vaddr)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_vaddr 1=%h 0=%h", seen1_io_mem_acquire_bits_user_vaddr, seen0_io_mem_acquire_bits_user_vaddr); end
    if (((~seen1_io_mem_acquire_bits_user_reqSource | ~seen0_io_mem_acquire_bits_user_reqSource) & ~5'h18) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_reqSource 1=%h 0=%h", seen1_io_mem_acquire_bits_user_reqSource, seen0_io_mem_acquire_bits_user_reqSource); end
    if (((~seen1_io_mem_acquire_bits_user_needHint | ~seen0_io_mem_acquire_bits_user_needHint)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_needHint 1=%h 0=%h", seen1_io_mem_acquire_bits_user_needHint, seen0_io_mem_acquire_bits_user_needHint); end
    if (((~seen1_io_mem_acquire_bits_echo_isKeyword | ~seen0_io_mem_acquire_bits_echo_isKeyword)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_echo_isKeyword 1=%h 0=%h", seen1_io_mem_acquire_bits_echo_isKeyword, seen0_io_mem_acquire_bits_echo_isKeyword); end
    if (((~seen1_io_mem_finish_valid | ~seen0_io_mem_finish_valid)) != '0) begin bad++; $display("TOGGLE MISS io_mem_finish_valid 1=%h 0=%h", seen1_io_mem_finish_valid, seen0_io_mem_finish_valid); end
    if (((~seen1_io_mem_finish_bits_sink | ~seen0_io_mem_finish_bits_sink)) != '0) begin bad++; $display("TOGGLE MISS io_mem_finish_bits_sink 1=%h 0=%h", seen1_io_mem_finish_bits_sink, seen0_io_mem_finish_bits_sink); end
    if (((~seen1_io_queryME_0_primary_ready | ~seen0_io_queryME_0_primary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_0_primary_ready 1=%h 0=%h", seen1_io_queryME_0_primary_ready, seen0_io_queryME_0_primary_ready); end
    if (((~seen1_io_queryME_0_secondary_ready | ~seen0_io_queryME_0_secondary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_0_secondary_ready 1=%h 0=%h", seen1_io_queryME_0_secondary_ready, seen0_io_queryME_0_secondary_ready); end
    if (((~seen1_io_queryME_0_secondary_reject | ~seen0_io_queryME_0_secondary_reject)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_0_secondary_reject 1=%h 0=%h", seen1_io_queryME_0_secondary_reject, seen0_io_queryME_0_secondary_reject); end
    if (((~seen1_io_queryME_1_primary_ready | ~seen0_io_queryME_1_primary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_1_primary_ready 1=%h 0=%h", seen1_io_queryME_1_primary_ready, seen0_io_queryME_1_primary_ready); end
    if (((~seen1_io_queryME_1_secondary_ready | ~seen0_io_queryME_1_secondary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_1_secondary_ready 1=%h 0=%h", seen1_io_queryME_1_secondary_ready, seen0_io_queryME_1_secondary_ready); end
    if (((~seen1_io_queryME_1_secondary_reject | ~seen0_io_queryME_1_secondary_reject)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_1_secondary_reject 1=%h 0=%h", seen1_io_queryME_1_secondary_reject, seen0_io_queryME_1_secondary_reject); end
    if (((~seen1_io_queryME_2_primary_ready | ~seen0_io_queryME_2_primary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_2_primary_ready 1=%h 0=%h", seen1_io_queryME_2_primary_ready, seen0_io_queryME_2_primary_ready); end
    if (((~seen1_io_queryME_2_secondary_ready | ~seen0_io_queryME_2_secondary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_2_secondary_ready 1=%h 0=%h", seen1_io_queryME_2_secondary_ready, seen0_io_queryME_2_secondary_ready); end
    if (((~seen1_io_queryME_2_secondary_reject | ~seen0_io_queryME_2_secondary_reject)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_2_secondary_reject 1=%h 0=%h", seen1_io_queryME_2_secondary_reject, seen0_io_queryME_2_secondary_reject); end
    if (((~seen1_io_queryME_3_primary_ready | ~seen0_io_queryME_3_primary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_3_primary_ready 1=%h 0=%h", seen1_io_queryME_3_primary_ready, seen0_io_queryME_3_primary_ready); end
    if (((~seen1_io_queryME_3_secondary_ready | ~seen0_io_queryME_3_secondary_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_3_secondary_ready 1=%h 0=%h", seen1_io_queryME_3_secondary_ready, seen0_io_queryME_3_secondary_ready); end
    if (((~seen1_io_queryME_3_secondary_reject | ~seen0_io_queryME_3_secondary_reject)) != '0) begin bad++; $display("TOGGLE MISS io_queryME_3_secondary_reject 1=%h 0=%h", seen1_io_queryME_3_secondary_reject, seen0_io_queryME_3_secondary_reject); end
    if (((~seen1_io_refill_to_ldq_valid | ~seen0_io_refill_to_ldq_valid)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_valid 1=%h 0=%h", seen1_io_refill_to_ldq_valid, seen0_io_refill_to_ldq_valid); end
    if (((~seen1_io_refill_to_ldq_bits_addr | ~seen0_io_refill_to_ldq_bits_addr) & ~48'h1f) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_addr 1=%h 0=%h", seen1_io_refill_to_ldq_bits_addr, seen0_io_refill_to_ldq_bits_addr); end
    if (((~seen1_io_refill_to_ldq_bits_data | ~seen0_io_refill_to_ldq_bits_data)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_data 1=%h 0=%h", seen1_io_refill_to_ldq_bits_data, seen0_io_refill_to_ldq_bits_data); end
    if (((~seen1_io_refill_to_ldq_bits_error | ~seen0_io_refill_to_ldq_bits_error)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_error 1=%h 0=%h", seen1_io_refill_to_ldq_bits_error, seen0_io_refill_to_ldq_bits_error); end
    if (((~seen1_io_refill_to_ldq_bits_data_raw | ~seen0_io_refill_to_ldq_bits_data_raw)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_data_raw 1=%h 0=%h", seen1_io_refill_to_ldq_bits_data_raw, seen0_io_refill_to_ldq_bits_data_raw); end
    if (((~seen1_io_refill_to_ldq_bits_hasdata | ~seen0_io_refill_to_ldq_bits_hasdata)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_hasdata 1=%h 0=%h", seen1_io_refill_to_ldq_bits_hasdata, seen0_io_refill_to_ldq_bits_hasdata); end
    if (((~seen1_io_refill_to_ldq_bits_refill_done | ~seen0_io_refill_to_ldq_bits_refill_done)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_refill_done 1=%h 0=%h", seen1_io_refill_to_ldq_bits_refill_done, seen0_io_refill_to_ldq_bits_refill_done); end
    if (((~seen1_io_refill_to_ldq_bits_id | ~seen0_io_refill_to_ldq_bits_id)) != '0) begin bad++; $display("TOGGLE MISS io_refill_to_ldq_bits_id 1=%h 0=%h", seen1_io_refill_to_ldq_bits_id, seen0_io_refill_to_ldq_bits_id); end
    if (((~seen1_io_main_pipe_req_valid | ~seen0_io_main_pipe_req_valid)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_valid 1=%h 0=%h", seen1_io_main_pipe_req_valid, seen0_io_main_pipe_req_valid); end
    if (((~seen1_io_main_pipe_req_bits_miss_id | ~seen0_io_main_pipe_req_bits_miss_id)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_miss_id 1=%h 0=%h", seen1_io_main_pipe_req_bits_miss_id, seen0_io_main_pipe_req_bits_miss_id); end
    if (((~seen1_io_main_pipe_req_bits_occupy_way | ~seen0_io_main_pipe_req_bits_occupy_way)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_occupy_way 1=%h 0=%h", seen1_io_main_pipe_req_bits_occupy_way, seen0_io_main_pipe_req_bits_occupy_way); end
    if (((~seen1_io_main_pipe_req_bits_miss_fail_cause_evict_btot | ~seen0_io_main_pipe_req_bits_miss_fail_cause_evict_btot)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_miss_fail_cause_evict_btot 1=%h 0=%h", seen1_io_main_pipe_req_bits_miss_fail_cause_evict_btot, seen0_io_main_pipe_req_bits_miss_fail_cause_evict_btot); end
    if (((~seen1_io_main_pipe_req_bits_source | ~seen0_io_main_pipe_req_bits_source)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_source 1=%h 0=%h", seen1_io_main_pipe_req_bits_source, seen0_io_main_pipe_req_bits_source); end
    if (((~seen1_io_main_pipe_req_bits_cmd | ~seen0_io_main_pipe_req_bits_cmd)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_cmd 1=%h 0=%h", seen1_io_main_pipe_req_bits_cmd, seen0_io_main_pipe_req_bits_cmd); end
    if (((~seen1_io_main_pipe_req_bits_vaddr | ~seen0_io_main_pipe_req_bits_vaddr)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_vaddr 1=%h 0=%h", seen1_io_main_pipe_req_bits_vaddr, seen0_io_main_pipe_req_bits_vaddr); end
    if (((~seen1_io_main_pipe_req_bits_addr | ~seen0_io_main_pipe_req_bits_addr) & ~48'h3f) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_addr 1=%h 0=%h", seen1_io_main_pipe_req_bits_addr, seen0_io_main_pipe_req_bits_addr); end
    if (((~seen1_io_main_pipe_req_bits_word_idx | ~seen0_io_main_pipe_req_bits_word_idx)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_word_idx 1=%h 0=%h", seen1_io_main_pipe_req_bits_word_idx, seen0_io_main_pipe_req_bits_word_idx); end
    if (((~seen1_io_main_pipe_req_bits_amo_data | ~seen0_io_main_pipe_req_bits_amo_data)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_amo_data 1=%h 0=%h", seen1_io_main_pipe_req_bits_amo_data, seen0_io_main_pipe_req_bits_amo_data); end
    if (((~seen1_io_main_pipe_req_bits_amo_mask | ~seen0_io_main_pipe_req_bits_amo_mask)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_amo_mask 1=%h 0=%h", seen1_io_main_pipe_req_bits_amo_mask, seen0_io_main_pipe_req_bits_amo_mask); end
    if (((~seen1_io_main_pipe_req_bits_amo_cmp | ~seen0_io_main_pipe_req_bits_amo_cmp)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_amo_cmp 1=%h 0=%h", seen1_io_main_pipe_req_bits_amo_cmp, seen0_io_main_pipe_req_bits_amo_cmp); end
    if (((~seen1_io_main_pipe_req_bits_pf_source | ~seen0_io_main_pipe_req_bits_pf_source)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_pf_source 1=%h 0=%h", seen1_io_main_pipe_req_bits_pf_source, seen0_io_main_pipe_req_bits_pf_source); end
    if (((~seen1_io_main_pipe_req_bits_access | ~seen0_io_main_pipe_req_bits_access)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_access 1=%h 0=%h", seen1_io_main_pipe_req_bits_access, seen0_io_main_pipe_req_bits_access); end
    if (((~seen1_io_main_pipe_req_bits_id | ~seen0_io_main_pipe_req_bits_id)) != '0) begin bad++; $display("TOGGLE MISS io_main_pipe_req_bits_id 1=%h 0=%h", seen1_io_main_pipe_req_bits_id, seen0_io_main_pipe_req_bits_id); end
    if (((~seen1_io_refill_info_valid | ~seen0_io_refill_info_valid)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_valid 1=%h 0=%h", seen1_io_refill_info_valid, seen0_io_refill_info_valid); end
    if (((~seen1_io_refill_info_bits_store_data | ~seen0_io_refill_info_bits_store_data)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_store_data 1=%h 0=%h", seen1_io_refill_info_bits_store_data, seen0_io_refill_info_bits_store_data); end
    if (((~seen1_io_refill_info_bits_miss_param | ~seen0_io_refill_info_bits_miss_param)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_miss_param 1=%h 0=%h", seen1_io_refill_info_bits_miss_param, seen0_io_refill_info_bits_miss_param); end
    if (((~seen1_io_refill_info_bits_error_tl_denied | ~seen0_io_refill_info_bits_error_tl_denied)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_error_tl_denied 1=%h 0=%h", seen1_io_refill_info_bits_error_tl_denied, seen0_io_refill_info_bits_error_tl_denied); end
    if (((~seen1_io_refill_info_bits_error_tl_corrupt | ~seen0_io_refill_info_bits_error_tl_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_error_tl_corrupt 1=%h 0=%h", seen1_io_refill_info_bits_error_tl_corrupt, seen0_io_refill_info_bits_error_tl_corrupt); end
    if (((~seen1_io_occupy_way | ~seen0_io_occupy_way)) != '0) begin bad++; $display("TOGGLE MISS io_occupy_way 1=%h 0=%h", seen1_io_occupy_way, seen0_io_occupy_way); end
    if (((~seen1_io_probe_block | ~seen0_io_probe_block)) != '0) begin bad++; $display("TOGGLE MISS io_probe_block 1=%h 0=%h", seen1_io_probe_block, seen0_io_probe_block); end
    if (((~seen1_io_replace_block | ~seen0_io_replace_block)) != '0) begin bad++; $display("TOGGLE MISS io_replace_block 1=%h 0=%h", seen1_io_replace_block, seen0_io_replace_block); end
    if (((~seen1_io_req_vaddr_valid | ~seen0_io_req_vaddr_valid)) != '0) begin bad++; $display("TOGGLE MISS io_req_vaddr_valid 1=%h 0=%h", seen1_io_req_vaddr_valid, seen0_io_req_vaddr_valid); end
    if (((~seen1_io_req_vaddr_bits | ~seen0_io_req_vaddr_bits)) != '0) begin bad++; $display("TOGGLE MISS io_req_vaddr_bits 1=%h 0=%h", seen1_io_req_vaddr_bits, seen0_io_req_vaddr_bits); end
    if (((~seen1_io_req_isBtoT | ~seen0_io_req_isBtoT)) != '0) begin bad++; $display("TOGGLE MISS io_req_isBtoT 1=%h 0=%h", seen1_io_req_isBtoT, seen0_io_req_isBtoT); end
    if (((~seen1_io_req_handled_by_this_entry | ~seen0_io_req_handled_by_this_entry)) != '0) begin bad++; $display("TOGGLE MISS io_req_handled_by_this_entry 1=%h 0=%h", seen1_io_req_handled_by_this_entry, seen0_io_req_handled_by_this_entry); end
    if (((~seen1_io_forwardInfo_inflight | ~seen0_io_forwardInfo_inflight)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_inflight 1=%h 0=%h", seen1_io_forwardInfo_inflight, seen0_io_forwardInfo_inflight); end
    if (((~seen1_io_forwardInfo_paddr | ~seen0_io_forwardInfo_paddr) & ~48'h3f) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_paddr 1=%h 0=%h", seen1_io_forwardInfo_paddr, seen0_io_forwardInfo_paddr); end
    if (((~seen1_io_forwardInfo_raw_data_0 | ~seen0_io_forwardInfo_raw_data_0)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_0 1=%h 0=%h", seen1_io_forwardInfo_raw_data_0, seen0_io_forwardInfo_raw_data_0); end
    if (((~seen1_io_forwardInfo_raw_data_1 | ~seen0_io_forwardInfo_raw_data_1)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_1 1=%h 0=%h", seen1_io_forwardInfo_raw_data_1, seen0_io_forwardInfo_raw_data_1); end
    if (((~seen1_io_forwardInfo_raw_data_2 | ~seen0_io_forwardInfo_raw_data_2)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_2 1=%h 0=%h", seen1_io_forwardInfo_raw_data_2, seen0_io_forwardInfo_raw_data_2); end
    if (((~seen1_io_forwardInfo_raw_data_3 | ~seen0_io_forwardInfo_raw_data_3)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_3 1=%h 0=%h", seen1_io_forwardInfo_raw_data_3, seen0_io_forwardInfo_raw_data_3); end
    if (((~seen1_io_forwardInfo_raw_data_4 | ~seen0_io_forwardInfo_raw_data_4)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_4 1=%h 0=%h", seen1_io_forwardInfo_raw_data_4, seen0_io_forwardInfo_raw_data_4); end
    if (((~seen1_io_forwardInfo_raw_data_5 | ~seen0_io_forwardInfo_raw_data_5)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_5 1=%h 0=%h", seen1_io_forwardInfo_raw_data_5, seen0_io_forwardInfo_raw_data_5); end
    if (((~seen1_io_forwardInfo_raw_data_6 | ~seen0_io_forwardInfo_raw_data_6)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_6 1=%h 0=%h", seen1_io_forwardInfo_raw_data_6, seen0_io_forwardInfo_raw_data_6); end
    if (((~seen1_io_forwardInfo_raw_data_7 | ~seen0_io_forwardInfo_raw_data_7)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_raw_data_7 1=%h 0=%h", seen1_io_forwardInfo_raw_data_7, seen0_io_forwardInfo_raw_data_7); end
    if (((~seen1_io_forwardInfo_firstbeat_valid | ~seen0_io_forwardInfo_firstbeat_valid)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_firstbeat_valid 1=%h 0=%h", seen1_io_forwardInfo_firstbeat_valid, seen0_io_forwardInfo_firstbeat_valid); end
    if (((~seen1_io_forwardInfo_lastbeat_valid | ~seen0_io_forwardInfo_lastbeat_valid)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_lastbeat_valid 1=%h 0=%h", seen1_io_forwardInfo_lastbeat_valid, seen0_io_forwardInfo_lastbeat_valid); end
    if (((~seen1_io_forwardInfo_denied | ~seen0_io_forwardInfo_denied)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_denied 1=%h 0=%h", seen1_io_forwardInfo_denied, seen0_io_forwardInfo_denied); end
    if (((~seen1_io_forwardInfo_corrupt | ~seen0_io_forwardInfo_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_forwardInfo_corrupt 1=%h 0=%h", seen1_io_forwardInfo_corrupt, seen0_io_forwardInfo_corrupt); end
    if (((~seen1_io_perf_pending_prefetch | ~seen0_io_perf_pending_prefetch)) != '0) begin bad++; $display("TOGGLE MISS io_perf_pending_prefetch 1=%h 0=%h", seen1_io_perf_pending_prefetch, seen0_io_perf_pending_prefetch); end
    if (((~seen1_io_perf_pending_normal | ~seen0_io_perf_pending_normal)) != '0) begin bad++; $display("TOGGLE MISS io_perf_pending_normal 1=%h 0=%h", seen1_io_perf_pending_normal, seen0_io_perf_pending_normal); end
    if (((~seen1_io_rob_head_query_resp | ~seen0_io_rob_head_query_resp)) != '0) begin bad++; $display("TOGGLE MISS io_rob_head_query_resp 1=%h 0=%h", seen1_io_rob_head_query_resp, seen0_io_rob_head_query_resp); end
    if (((~seen1_io_latency_monitor_load_miss_refilling | ~seen0_io_latency_monitor_load_miss_refilling)) != '0) begin bad++; $display("TOGGLE MISS io_latency_monitor_load_miss_refilling 1=%h 0=%h", seen1_io_latency_monitor_load_miss_refilling, seen0_io_latency_monitor_load_miss_refilling); end
    if (((~seen1_io_latency_monitor_store_miss_refilling | ~seen0_io_latency_monitor_store_miss_refilling)) != '0) begin bad++; $display("TOGGLE MISS io_latency_monitor_store_miss_refilling 1=%h 0=%h", seen1_io_latency_monitor_store_miss_refilling, seen0_io_latency_monitor_store_miss_refilling); end
    if (((~seen1_io_latency_monitor_amo_miss_refilling | ~seen0_io_latency_monitor_amo_miss_refilling)) != '0) begin bad++; $display("TOGGLE MISS io_latency_monitor_amo_miss_refilling 1=%h 0=%h", seen1_io_latency_monitor_amo_miss_refilling, seen0_io_latency_monitor_amo_miss_refilling); end
    if (((~seen1_io_latency_monitor_pf_miss_refilling | ~seen0_io_latency_monitor_pf_miss_refilling)) != '0) begin bad++; $display("TOGGLE MISS io_latency_monitor_pf_miss_refilling 1=%h 0=%h", seen1_io_latency_monitor_pf_miss_refilling, seen0_io_latency_monitor_pf_miss_refilling); end
    if (((~seen1_io_prefetch_info_late_prefetch | ~seen0_io_prefetch_info_late_prefetch)) != '0) begin bad++; $display("TOGGLE MISS io_prefetch_info_late_prefetch 1=%h 0=%h", seen1_io_prefetch_info_late_prefetch, seen0_io_prefetch_info_late_prefetch); end
    if (((~seen1_io_matched | ~seen0_io_matched)) != '0) begin bad++; $display("TOGGLE MISS io_matched 1=%h 0=%h", seen1_io_matched, seen0_io_matched); end
    if (((~seen1_io_l1Miss | ~seen0_io_l1Miss)) != '0) begin bad++; $display("TOGGLE MISS io_l1Miss 1=%h 0=%h", seen1_io_l1Miss, seen0_io_l1Miss); end
    if (((~seen1_io_wfi_wfiSafe | ~seen0_io_wfi_wfiSafe)) != '0) begin bad++; $display("TOGGLE MISS io_wfi_wfiSafe 1=%h 0=%h", seen1_io_wfi_wfiSafe, seen0_io_wfi_wfiSafe); end
    return bad;
  endfunction
  // END GENERATED

  // ---- 地址池（每 2000 拍整体换一次，让高位地址也翻转）----
  logic [47:0] blk_pool [4];
  logic [43:0] vline_pool [4];     // vaddr[49:6]
  logic [1:0]  alias_pool [2];
  task automatic refresh_pools();
    for (int k = 0; k < 4; k++) begin
      blk_pool[k]   = {$urandom, $urandom};
      vline_pool[k] = {$urandom, $urandom};
    end
    alias_pool[0] = 2'($urandom); alias_pool[1] = ~alias_pool[0];
  endtask
  function automatic logic [47:0] rand_paddr();
    return {blk_pool[$urandom_range(0, 3)][47:6], 6'($urandom)};
  endfunction
  function automatic logic [49:0] rand_vaddr();
    logic [49:0] v = {$urandom, $urandom};
    if ($urandom_range(0, 3) != 0) v[49:6] = vline_pool[$urandom_range(0, 3)];
    v[13:12] = alias_pool[$urandom_range(0, 1)];
    return v;
  endfunction
  function automatic logic [3:0] rand_source();
    int r = $urandom_range(0, 99);
    if (r < 40) return 4'd0;          // load
    if (r < 65) return 4'd1;          // store
    if (r < 80) return 4'd2;          // amo
    if (r < 95) return 4'd3;          // prefetch
    return 4'($urandom_range(4, 15));
  endfunction
  function automatic logic [4:0] rand_cmd();
    int r = $urandom_range(0, 9);
    if (r < 3) return 5'($urandom);
    if (r < 5) return 5'($urandom_range(0, 3));
    if (r < 7) return 5'h1;
    return 5'($urandom_range(4, 15));
  endfunction

  int wfi_len = 0;
  logic [3:0] cur_id = 0;

  task automatic drive();
    io_id                              = cur_id;
    io_req_valid                       = ($urandom_range(0, 1) == 0);
    io_req_bits_source                 = rand_source();
    io_req_bits_addr                   = rand_paddr();
    io_req_bits_vaddr                  = rand_vaddr();
    io_req_bits_cancel                 = ($urandom_range(0, 9) == 0);
    io_wbq_block_miss_req              = ($urandom_range(0, 9) == 0);
    io_primary_valid                   = ($urandom_range(0, 1) == 0);
    io_miss_req_pipe_reg_req_source    = rand_source();
    io_miss_req_pipe_reg_req_pf_source = 3'($urandom);
    io_miss_req_pipe_reg_req_cmd       = rand_cmd();
    io_miss_req_pipe_reg_req_addr      = rand_paddr();
    io_miss_req_pipe_reg_req_vaddr     = rand_vaddr();
    io_miss_req_pipe_reg_req_full_overwrite = ($urandom_range(0, 3) == 0);
    io_miss_req_pipe_reg_req_word_idx  = 3'($urandom);
    io_miss_req_pipe_reg_req_amo_data  = {$urandom, $urandom, $urandom, $urandom};
    io_miss_req_pipe_reg_req_amo_mask  = 16'($urandom);
    io_miss_req_pipe_reg_req_amo_cmp   = {$urandom, $urandom, $urandom, $urandom};
    io_miss_req_pipe_reg_req_req_coh_state = 2'($urandom);
    io_miss_req_pipe_reg_req_id        = 6'($urandom);
    io_miss_req_pipe_reg_req_isBtoT    = 1'($urandom);
    io_miss_req_pipe_reg_req_occupy_way = 4'($urandom);
    for (int k = 0; k < 16; k++) io_miss_req_pipe_reg_req_store_data[k*32 +: 32] = $urandom;
    io_miss_req_pipe_reg_req_store_mask = {$urandom, $urandom} & {$urandom, $urandom};
    io_miss_req_pipe_reg_alloc         = ($urandom_range(0, 9) < 2);
    io_miss_req_pipe_reg_merge         = ($urandom_range(0, 9) < 2);
    io_miss_req_pipe_reg_cancel        = ($urandom_range(0, 9) == 0);
    io_acquire_fired_by_pipe_reg       = ($urandom_range(0, 2) == 0);
    io_mem_acquire_ready               = ($urandom_range(0, 4) < 3);
    io_mem_grant_valid                 = ($urandom_range(0, 3) == 0);
    io_mem_grant_bits_opcode           = ($urandom_range(0, 4) == 0) ? 4'd4 :
                                         ($urandom_range(0, 19) == 0) ? 4'($urandom) : 4'd5;
    io_mem_grant_bits_param            = 2'($urandom);
    io_mem_grant_bits_size             = ($urandom_range(0, 5) == 0) ? 3'($urandom) : 3'd6;
    io_mem_grant_bits_sink             = 10'($urandom);
    io_mem_grant_bits_denied           = ($urandom_range(0, 15) == 0);
    io_mem_grant_bits_corrupt          = ($urandom_range(0, 15) == 0);
    for (int k = 0; k < 8; k++) io_mem_grant_bits_data[k*32 +: 32] = $urandom;
    io_mem_finish_ready                = ($urandom_range(0, 3) != 0);
    io_queryME_0_req_bits_source       = rand_source();
    io_queryME_0_req_bits_addr         = rand_paddr();
    io_queryME_0_req_bits_vaddr        = rand_vaddr();
    io_queryME_1_req_bits_source       = rand_source();
    io_queryME_1_req_bits_addr         = rand_paddr();
    io_queryME_1_req_bits_vaddr        = rand_vaddr();
    io_queryME_2_req_bits_source       = rand_source();
    io_queryME_2_req_bits_addr         = rand_paddr();
    io_queryME_2_req_bits_vaddr        = rand_vaddr();
    io_queryME_3_req_bits_source       = rand_source();
    io_queryME_3_req_bits_addr         = rand_paddr();
    io_queryME_3_req_bits_vaddr        = rand_vaddr();
    io_l2_hint_valid                   = ($urandom_range(0, 19) == 0);
    io_main_pipe_req_ready             = ($urandom_range(0, 2) != 0);
    io_main_pipe_resp                  = ($urandom_range(0, 9) == 0);
    io_main_pipe_refill_resp           = ($urandom_range(0, 9) == 0);
    io_main_pipe_replay                = ($urandom_range(0, 19) == 0);
    io_main_pipe_evict_BtoT_way        = ($urandom_range(0, 19) == 0);
    io_main_pipe_next_evict_way        = 4'($urandom);
    io_probe_req_bits_addr             = rand_paddr();
    io_probe_req_bits_vaddr            = rand_vaddr();
    io_replace_req_bits_addr           = rand_paddr();
    io_replace_req_bits_vaddr          = rand_vaddr();
    io_l2_pf_store_only                = ($urandom_range(0, 7) == 0);
    io_memSetPattenDetected            = ($urandom_range(0, 9) == 0);
    io_rob_head_query_vaddr            = ($urandom_range(0, 1) == 0) ? u_gold.req_vaddr : rand_vaddr();
    io_rob_head_query_query_valid      = ($urandom_range(0, 1) == 0);
    if (wfi_len > 0) wfi_len--;
    else if ($urandom_range(0, 59) == 0) wfi_len = $urandom_range(1, 20);
    io_wfi_wfiReq = (wfi_len > 0);
  endtask

  // ---- 覆盖计数（看 golden 内部信号）----
  int cov_alloc, cov_merge_load, cov_merge_store, cov_acq_fire, cov_acq_perm;
  int cov_grant_data_kw, cov_grant_data_nokw, cov_grant_nodata, cov_grant_store_merge;
  int cov_finish, cov_mp_fire, cov_replay, cov_evict, cov_release;
  int cov_prim_slot, cov_prim_noslot_pf_block, cov_sec_ready, cov_reject, cov_late_pf;
  int cov_probe_block, cov_replace_block, cov_ldq, cov_wfi_block, cov_reset, cov_handled;
  int cov_query_sec, cov_query_rej, cov_fwd_first_only;

  task automatic count_cov();
    logic alloc_f = io_miss_req_pipe_reg_alloc & ~io_miss_req_pipe_reg_cancel;
    logic merge_f = io_miss_req_pipe_reg_merge & ~io_miss_req_pipe_reg_cancel;
    if (alloc_f) cov_alloc++;
    if (merge_f && io_miss_req_pipe_reg_req_source == 0) cov_merge_load++;
    if (merge_f && io_miss_req_pipe_reg_req_source == 1) cov_merge_store++;
    if (io_mem_acquire_ready && g_io_mem_acquire_valid) begin
      cov_acq_fire++;
      if (g_io_mem_acquire_bits_opcode == 4'd7) cov_acq_perm++;
    end
    if (io_mem_grant_valid && io_mem_grant_bits_opcode[0]) begin
      if (u_gold.isKeyword) cov_grant_data_kw++; else cov_grant_data_nokw++;
      if (u_gold.req_source == 4'd1 && u_gold.req_store_mask != 0) cov_grant_store_merge++;
    end
    if (io_mem_grant_valid && !io_mem_grant_bits_opcode[0]) cov_grant_nodata++;
    if (io_mem_finish_ready && g_io_mem_finish_valid) cov_finish++;
    if (io_main_pipe_req_ready && g_io_main_pipe_req_valid) cov_mp_fire++;
    if (io_main_pipe_replay) cov_replay++;
    if (io_main_pipe_evict_BtoT_way && !io_main_pipe_replay) cov_evict++;
    if (u_gold.req_valid && u_gold.release_entry_probe) cov_release++;
    if (g_io_primary_ready && u_gold.last_REG) cov_prim_slot++;
    if (!u_gold.req_valid && !u_gold.last_REG && io_req_bits_source >= 3 && !io_memSetPattenDetected)
      cov_prim_noslot_pf_block++;
    if (g_io_secondary_ready && io_req_valid) cov_sec_ready++;
    if (g_io_secondary_reject && io_req_valid) cov_reject++;
    if (g_io_queryME_0_secondary_ready | g_io_queryME_3_secondary_ready) cov_query_sec++;
    if (g_io_queryME_1_secondary_reject | g_io_queryME_2_secondary_reject) cov_query_rej++;
    if (g_io_prefetch_info_late_prefetch) cov_late_pf++;
    if (g_io_probe_block) cov_probe_block++;
    if (g_io_replace_block) cov_replace_block++;
    if (g_io_refill_to_ldq_valid) cov_ldq++;
    if (io_wfi_wfiReq && !u_gold.s_acquire) cov_wfi_block++;
    if (g_io_req_handled_by_this_entry) cov_handled++;
    if (g_io_forwardInfo_firstbeat_valid && !g_io_forwardInfo_lastbeat_valid) cov_fwd_first_only++;
  endtask

  task automatic warmup();
    // store 分配（不取消）
    @(negedge clock);
    drive();
    io_mem_grant_valid = 0;
    io_miss_req_pipe_reg_alloc = 1; io_miss_req_pipe_reg_merge = 0; io_miss_req_pipe_reg_cancel = 0;
    io_miss_req_pipe_reg_req_source = 4'd1;
    // 两拍 GrantData
    for (int b = 0; b < 2; b++) begin
      @(negedge clock);
      drive();
      io_miss_req_pipe_reg_alloc = 0; io_miss_req_pipe_reg_merge = 0;
      io_mem_grant_valid = 1; io_mem_grant_bits_opcode = 4'd5; io_mem_grant_bits_size = 3'd6;
    end
    @(negedge clock);
    drive();
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    refresh_pools();
    cur_id = 4'($urandom_range(0, 1));
    reset = 1;
    drive();
    repeat (5) @(negedge clock);
    reset = 0;
    warmup();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      // io_id 交替取 {0,1}（不能接预取的表项）与 {2..15}（能接预取的表项）
      if (cyc % 4000 == 3999) cur_id = (cyc / 4000 % 2 == 0) ? 4'($urandom_range(2, 15)) : 4'($urandom_range(0, 1));
      if (cyc % 2000 == 1999) refresh_pools();
      drive();
      if ($urandom_range(0, 4999) == 0) begin
        reset = 1; cov_reset++;
        #1; compare_outputs();
        repeat ($urandom_range(1, 3)) @(negedge clock);
        reset = 0;
        drive();
      end
      #1;
      compare_outputs();
      count_cov();
    end
    $display("COVERAGE alloc=%0d merge_load=%0d merge_store=%0d acq_fire=%0d acq_perm=%0d",
             cov_alloc, cov_merge_load, cov_merge_store, cov_acq_fire, cov_acq_perm);
    $display("COVERAGE grant_data_kw=%0d grant_data_nokw=%0d grant_nodata=%0d grant_store_merge=%0d",
             cov_grant_data_kw, cov_grant_data_nokw, cov_grant_nodata, cov_grant_store_merge);
    $display("COVERAGE finish=%0d mp_fire=%0d replay=%0d evict=%0d release=%0d handled=%0d",
             cov_finish, cov_mp_fire, cov_replay, cov_evict, cov_release, cov_handled);
    $display("COVERAGE prim_slot=%0d prim_noslot_pf_block=%0d sec_ready=%0d reject=%0d query_sec=%0d query_rej=%0d late_pf=%0d",
             cov_prim_slot, cov_prim_noslot_pf_block, cov_sec_ready, cov_reject, cov_query_sec, cov_query_rej, cov_late_pf);
    $display("COVERAGE probe_block=%0d replace_block=%0d ldq=%0d wfi_block=%0d fwd_first_only=%0d reset=%0d",
             cov_probe_block, cov_replace_block, cov_ldq, cov_wfi_block, cov_fwd_first_only, cov_reset);
    begin
      int c [$];
      c = '{cov_alloc, cov_merge_load, cov_merge_store, cov_acq_fire, cov_acq_perm,
                    cov_grant_data_kw, cov_grant_data_nokw, cov_grant_nodata, cov_grant_store_merge,
                    cov_finish, cov_mp_fire, cov_replay, cov_evict, cov_release, cov_handled,
                    cov_prim_slot, cov_prim_noslot_pf_block, cov_sec_ready, cov_reject,
                    cov_query_sec, cov_query_rej, cov_late_pf, cov_probe_block, cov_replace_block,
                    cov_ldq, cov_wfi_block, cov_fwd_first_only};
      foreach (c[k]) if (c[k] < COV_MIN) begin cov_fail++; $display("COV FAIL: item %0d = %0d", k, c[k]); end
    end
    if (NCYCLES >= 100000 && cov_reset < 10) begin cov_fail++; $display("COV FAIL: reset"); end
    cov_fail += report_toggle();
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
