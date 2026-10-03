// MissQueue 双例化逐拍比对：golden MissQueue vs 重写件 MissQueue_xs（xs_MissQueue_core + 生成的 wrapper）。
// 两侧例化同一份子模块重写件（MissEntry / CMOUnit / Arbiter16_MainPipeReq，均已单独签核），所以这里
// 比的是 MissQueue 本体的胶水：入队判定、流水寄存器、A/E 通道仲裁、D 通道分发、前递、占路、统计、difftest。
// GENERATED 区由 gen.py 从 G1 golden 端口表生成（勿手改）；其余为手写激励与覆盖。
//
// 激励：每拍随机驱动全部输入；地址取自 8 行 × 2 alias 的小池（每 3000 拍换池），set 下标也取自小池，
//   让合并 / 拒绝 / 前递命中 / BtoT 占路高频发生；Grant 的 source 多数取 0..15（偶尔 16..63 越界），
//   opcode ∈ {GrantData, Grant, CBOAck, 随机}；MainPipe resp / s2 / s3 的 miss_id 多数取刚发出的回填请求号；
//   四分之一的拍重复上一拍的行（撞流水寄存器）；每 1000 拍有两成概率进入"store 连发 + LoadQueue 空"模式
//   （store/预取/少量 load 混合，计数器反复穿过门槛 8）以触发 memset 检测；wfiReq 成段且段内逐个给表项回无数据 Grant（让 wfiSafe 能为 1）；hartId 每 5000 拍换；随机异步复位。
// 暖机：复位后把 16 个 MSHR 各分配一次 store（写定请求字段、store 数据与掩码）并各回两拍 GrantData
//   （写定 grant_param / raw 数据 / sink / refill_to_ldq 锁存），之后才开比较窗口 ——
//   +vcs+initreg+random 下两侧 MSHR 的不复位寄存器初值不同，而回填仲裁器空闲时输出第 15 路载荷、
//   refill_info 与前递按 id 选任意表项，这些寄存器都直接可见。
// 覆盖闸：各事件计数 >= COV_MIN，外加每个输出位见过 0 和 1。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 100;
  int errors = 0, checks = 0, cov_fail = 0, cyc = 0;
  bit   clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // BEGIN GENERATED(tb-ports)
  // ---- 输入（两侧共用；clock/reset 由 tb 手写区驱动）----
  logic [5:0] io_hartId;
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
  // ---- 输出（g_ = golden，i_ = 重写）----
  wire  g_io_req_ready, i_io_req_ready;
  wire  [3:0] g_io_resp_id, i_io_resp_id;
  wire  g_io_resp_handled, i_io_resp_handled;
  wire  g_io_resp_merged, i_io_resp_merged;
  wire  g_io_cmo_req_ready, i_io_cmo_req_ready;
  wire  g_io_cmo_resp_valid, i_io_cmo_resp_valid;
  wire  g_io_cmo_resp_bits_denied, i_io_cmo_resp_bits_denied;
  wire  g_io_cmo_resp_bits_corrupt, i_io_cmo_resp_bits_corrupt;
  wire  g_io_queryMQ_0_ready, i_io_queryMQ_0_ready;
  wire  g_io_queryMQ_1_ready, i_io_queryMQ_1_ready;
  wire  g_io_queryMQ_2_ready, i_io_queryMQ_2_ready;
  wire  g_io_queryMQ_3_ready, i_io_queryMQ_3_ready;
  wire  g_io_mem_acquire_valid, i_io_mem_acquire_valid;
  wire  [3:0] g_io_mem_acquire_bits_opcode, i_io_mem_acquire_bits_opcode;
  wire  [2:0] g_io_mem_acquire_bits_param, i_io_mem_acquire_bits_param;
  wire  [2:0] g_io_mem_acquire_bits_size, i_io_mem_acquire_bits_size;
  wire  [5:0] g_io_mem_acquire_bits_source, i_io_mem_acquire_bits_source;
  wire  [47:0] g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address;
  wire  [1:0] g_io_mem_acquire_bits_user_alias, i_io_mem_acquire_bits_user_alias;
  wire  [43:0] g_io_mem_acquire_bits_user_vaddr, i_io_mem_acquire_bits_user_vaddr;
  wire  [4:0] g_io_mem_acquire_bits_user_reqSource, i_io_mem_acquire_bits_user_reqSource;
  wire  g_io_mem_acquire_bits_user_needHint, i_io_mem_acquire_bits_user_needHint;
  wire  g_io_mem_acquire_bits_echo_isKeyword, i_io_mem_acquire_bits_echo_isKeyword;
  wire  [31:0] g_io_mem_acquire_bits_mask, i_io_mem_acquire_bits_mask;
  wire  g_io_mem_grant_ready, i_io_mem_grant_ready;
  wire  g_io_mem_finish_valid, i_io_mem_finish_valid;
  wire  [9:0] g_io_mem_finish_bits_sink, i_io_mem_finish_bits_sink;
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
  wire  [63:0] g_io_refill_info_bits_store_mask, i_io_refill_info_bits_store_mask;
  wire  [1:0] g_io_refill_info_bits_miss_param, i_io_refill_info_bits_miss_param;
  wire  g_io_refill_info_bits_error_tl_denied, i_io_refill_info_bits_error_tl_denied;
  wire  g_io_refill_info_bits_error_tl_corrupt, i_io_refill_info_bits_error_tl_corrupt;
  wire  g_io_probe_block, i_io_probe_block;
  wire  g_io_replace_block, i_io_replace_block;
  wire  [3:0] g_io_btot_ways_for_set, i_io_btot_ways_for_set;
  wire  g_io_occupy_fail_0, i_io_occupy_fail_0;
  wire  g_io_occupy_fail_1, i_io_occupy_fail_1;
  wire  g_io_occupy_fail_2, i_io_occupy_fail_2;
  wire  g_io_forward_0_forward_mshr, i_io_forward_0_forward_mshr;
  wire  [7:0] g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0;
  wire  [7:0] g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1;
  wire  [7:0] g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2;
  wire  [7:0] g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3;
  wire  [7:0] g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4;
  wire  [7:0] g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5;
  wire  [7:0] g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6;
  wire  [7:0] g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7;
  wire  [7:0] g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8;
  wire  [7:0] g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9;
  wire  [7:0] g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10;
  wire  [7:0] g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11;
  wire  [7:0] g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12;
  wire  [7:0] g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13;
  wire  [7:0] g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14;
  wire  [7:0] g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15;
  wire  g_io_forward_0_forward_result_valid, i_io_forward_0_forward_result_valid;
  wire  g_io_forward_0_denied, i_io_forward_0_denied;
  wire  g_io_forward_0_corrupt, i_io_forward_0_corrupt;
  wire  g_io_forward_1_forward_mshr, i_io_forward_1_forward_mshr;
  wire  [7:0] g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0;
  wire  [7:0] g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1;
  wire  [7:0] g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2;
  wire  [7:0] g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3;
  wire  [7:0] g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4;
  wire  [7:0] g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5;
  wire  [7:0] g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6;
  wire  [7:0] g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7;
  wire  [7:0] g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8;
  wire  [7:0] g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9;
  wire  [7:0] g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10;
  wire  [7:0] g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11;
  wire  [7:0] g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12;
  wire  [7:0] g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13;
  wire  [7:0] g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14;
  wire  [7:0] g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15;
  wire  g_io_forward_1_forward_result_valid, i_io_forward_1_forward_result_valid;
  wire  g_io_forward_1_denied, i_io_forward_1_denied;
  wire  g_io_forward_1_corrupt, i_io_forward_1_corrupt;
  wire  g_io_forward_2_forward_mshr, i_io_forward_2_forward_mshr;
  wire  [7:0] g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0;
  wire  [7:0] g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1;
  wire  [7:0] g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2;
  wire  [7:0] g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3;
  wire  [7:0] g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4;
  wire  [7:0] g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5;
  wire  [7:0] g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6;
  wire  [7:0] g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7;
  wire  [7:0] g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8;
  wire  [7:0] g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9;
  wire  [7:0] g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10;
  wire  [7:0] g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11;
  wire  [7:0] g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12;
  wire  [7:0] g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13;
  wire  [7:0] g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14;
  wire  [7:0] g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15;
  wire  g_io_forward_2_forward_result_valid, i_io_forward_2_forward_result_valid;
  wire  g_io_forward_2_denied, i_io_forward_2_denied;
  wire  g_io_forward_2_corrupt, i_io_forward_2_corrupt;
  wire  g_io_prefetch_info_naive_late_miss_prefetch, i_io_prefetch_info_naive_late_miss_prefetch;
  wire  g_io_prefetch_info_fdp_late_miss_prefetch, i_io_prefetch_info_fdp_late_miss_prefetch;
  wire  g_io_prefetch_info_fdp_prefetch_monitor_cnt, i_io_prefetch_info_fdp_prefetch_monitor_cnt;
  wire  g_io_prefetch_info_fdp_total_prefetch, i_io_prefetch_info_fdp_total_prefetch;
  wire  g_io_wfi_wfiSafe, i_io_wfi_wfiSafe;
  wire  g_io_debugTopDown_robHeadMissInDCache, i_io_debugTopDown_robHeadMissInDCache;
  wire  g_io_l1Miss, i_io_l1Miss;
  wire  [5:0] g_io_perf_0_value, i_io_perf_0_value;
  wire  [5:0] g_io_perf_1_value, i_io_perf_1_value;
  wire  [5:0] g_io_perf_2_value, i_io_perf_2_value;
  wire  [5:0] g_io_perf_3_value, i_io_perf_3_value;
  wire  [5:0] g_io_perf_4_value, i_io_perf_4_value;
  wire  [600:0] g_gatewayIn_packed_41_bore, i_gatewayIn_packed_41_bore;
  MissQueue u_gold (
    .clock(clock),
    .reset(reset),
    .io_hartId(io_hartId),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_pf_source(io_req_bits_pf_source),
    .io_req_bits_cmd(io_req_bits_cmd),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_vaddr(io_req_bits_vaddr),
    .io_req_bits_full_overwrite(io_req_bits_full_overwrite),
    .io_req_bits_word_idx(io_req_bits_word_idx),
    .io_req_bits_amo_data(io_req_bits_amo_data),
    .io_req_bits_amo_mask(io_req_bits_amo_mask),
    .io_req_bits_amo_cmp(io_req_bits_amo_cmp),
    .io_req_bits_req_coh_state(io_req_bits_req_coh_state),
    .io_req_bits_id(io_req_bits_id),
    .io_req_bits_isBtoT(io_req_bits_isBtoT),
    .io_req_bits_occupy_way(io_req_bits_occupy_way),
    .io_req_bits_cancel(io_req_bits_cancel),
    .io_req_bits_store_data(io_req_bits_store_data),
    .io_req_bits_store_mask(io_req_bits_store_mask),
    .io_resp_id(g_io_resp_id),
    .io_resp_handled(g_io_resp_handled),
    .io_resp_merged(g_io_resp_merged),
    .io_cmo_req_ready(g_io_cmo_req_ready),
    .io_cmo_req_valid(io_cmo_req_valid),
    .io_cmo_req_bits_opcode(io_cmo_req_bits_opcode),
    .io_cmo_req_bits_address(io_cmo_req_bits_address),
    .io_cmo_resp_ready(io_cmo_resp_ready),
    .io_cmo_resp_valid(g_io_cmo_resp_valid),
    .io_cmo_resp_bits_denied(g_io_cmo_resp_bits_denied),
    .io_cmo_resp_bits_corrupt(g_io_cmo_resp_bits_corrupt),
    .io_queryMQ_0_req_bits_source(io_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr(io_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr(io_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready(g_io_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source(io_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr(io_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr(io_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready(g_io_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source(io_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr(io_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr(io_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready(g_io_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source(io_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr(io_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr(io_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready(g_io_queryMQ_3_ready),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(g_io_mem_acquire_valid),
    .io_mem_acquire_bits_opcode(g_io_mem_acquire_bits_opcode),
    .io_mem_acquire_bits_param(g_io_mem_acquire_bits_param),
    .io_mem_acquire_bits_size(g_io_mem_acquire_bits_size),
    .io_mem_acquire_bits_source(g_io_mem_acquire_bits_source),
    .io_mem_acquire_bits_address(g_io_mem_acquire_bits_address),
    .io_mem_acquire_bits_user_alias(g_io_mem_acquire_bits_user_alias),
    .io_mem_acquire_bits_user_vaddr(g_io_mem_acquire_bits_user_vaddr),
    .io_mem_acquire_bits_user_reqSource(g_io_mem_acquire_bits_user_reqSource),
    .io_mem_acquire_bits_user_needHint(g_io_mem_acquire_bits_user_needHint),
    .io_mem_acquire_bits_echo_isKeyword(g_io_mem_acquire_bits_echo_isKeyword),
    .io_mem_acquire_bits_mask(g_io_mem_acquire_bits_mask),
    .io_mem_grant_ready(g_io_mem_grant_ready),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param(io_mem_grant_bits_param),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_sink(io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied(io_mem_grant_bits_denied),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .io_mem_finish_ready(io_mem_finish_ready),
    .io_mem_finish_valid(g_io_mem_finish_valid),
    .io_mem_finish_bits_sink(g_io_mem_finish_bits_sink),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
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
    .io_main_pipe_resp_valid(io_main_pipe_resp_valid),
    .io_main_pipe_resp_bits_miss_id(io_main_pipe_resp_bits_miss_id),
    .io_main_pipe_resp_bits_ack_miss_queue(io_main_pipe_resp_bits_ack_miss_queue),
    .io_mainpipe_info_s2_valid(io_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id(io_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq(io_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way(io_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way(io_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid(io_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id(io_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp(io_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid(g_io_refill_info_valid),
    .io_refill_info_bits_store_data(g_io_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask(g_io_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param(g_io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(g_io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(g_io_refill_info_bits_error_tl_corrupt),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_block(g_io_probe_block),
    .io_replace_req_bits_addr(io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr),
    .io_replace_block(g_io_replace_block),
    .io_evict_set(io_evict_set),
    .io_btot_ways_for_set(g_io_btot_ways_for_set),
    .io_occupy_set_0(io_occupy_set_0),
    .io_occupy_set_1(io_occupy_set_1),
    .io_occupy_set_2(io_occupy_set_2),
    .io_occupy_fail_0(g_io_occupy_fail_0),
    .io_occupy_fail_1(g_io_occupy_fail_1),
    .io_occupy_fail_2(g_io_occupy_fail_2),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_forward_0_valid(io_forward_0_valid),
    .io_forward_0_mshrid(io_forward_0_mshrid),
    .io_forward_0_paddr(io_forward_0_paddr),
    .io_forward_0_forward_mshr(g_io_forward_0_forward_mshr),
    .io_forward_0_forwardData_0(g_io_forward_0_forwardData_0),
    .io_forward_0_forwardData_1(g_io_forward_0_forwardData_1),
    .io_forward_0_forwardData_2(g_io_forward_0_forwardData_2),
    .io_forward_0_forwardData_3(g_io_forward_0_forwardData_3),
    .io_forward_0_forwardData_4(g_io_forward_0_forwardData_4),
    .io_forward_0_forwardData_5(g_io_forward_0_forwardData_5),
    .io_forward_0_forwardData_6(g_io_forward_0_forwardData_6),
    .io_forward_0_forwardData_7(g_io_forward_0_forwardData_7),
    .io_forward_0_forwardData_8(g_io_forward_0_forwardData_8),
    .io_forward_0_forwardData_9(g_io_forward_0_forwardData_9),
    .io_forward_0_forwardData_10(g_io_forward_0_forwardData_10),
    .io_forward_0_forwardData_11(g_io_forward_0_forwardData_11),
    .io_forward_0_forwardData_12(g_io_forward_0_forwardData_12),
    .io_forward_0_forwardData_13(g_io_forward_0_forwardData_13),
    .io_forward_0_forwardData_14(g_io_forward_0_forwardData_14),
    .io_forward_0_forwardData_15(g_io_forward_0_forwardData_15),
    .io_forward_0_forward_result_valid(g_io_forward_0_forward_result_valid),
    .io_forward_0_denied(g_io_forward_0_denied),
    .io_forward_0_corrupt(g_io_forward_0_corrupt),
    .io_forward_1_valid(io_forward_1_valid),
    .io_forward_1_mshrid(io_forward_1_mshrid),
    .io_forward_1_paddr(io_forward_1_paddr),
    .io_forward_1_forward_mshr(g_io_forward_1_forward_mshr),
    .io_forward_1_forwardData_0(g_io_forward_1_forwardData_0),
    .io_forward_1_forwardData_1(g_io_forward_1_forwardData_1),
    .io_forward_1_forwardData_2(g_io_forward_1_forwardData_2),
    .io_forward_1_forwardData_3(g_io_forward_1_forwardData_3),
    .io_forward_1_forwardData_4(g_io_forward_1_forwardData_4),
    .io_forward_1_forwardData_5(g_io_forward_1_forwardData_5),
    .io_forward_1_forwardData_6(g_io_forward_1_forwardData_6),
    .io_forward_1_forwardData_7(g_io_forward_1_forwardData_7),
    .io_forward_1_forwardData_8(g_io_forward_1_forwardData_8),
    .io_forward_1_forwardData_9(g_io_forward_1_forwardData_9),
    .io_forward_1_forwardData_10(g_io_forward_1_forwardData_10),
    .io_forward_1_forwardData_11(g_io_forward_1_forwardData_11),
    .io_forward_1_forwardData_12(g_io_forward_1_forwardData_12),
    .io_forward_1_forwardData_13(g_io_forward_1_forwardData_13),
    .io_forward_1_forwardData_14(g_io_forward_1_forwardData_14),
    .io_forward_1_forwardData_15(g_io_forward_1_forwardData_15),
    .io_forward_1_forward_result_valid(g_io_forward_1_forward_result_valid),
    .io_forward_1_denied(g_io_forward_1_denied),
    .io_forward_1_corrupt(g_io_forward_1_corrupt),
    .io_forward_2_valid(io_forward_2_valid),
    .io_forward_2_mshrid(io_forward_2_mshrid),
    .io_forward_2_paddr(io_forward_2_paddr),
    .io_forward_2_forward_mshr(g_io_forward_2_forward_mshr),
    .io_forward_2_forwardData_0(g_io_forward_2_forwardData_0),
    .io_forward_2_forwardData_1(g_io_forward_2_forwardData_1),
    .io_forward_2_forwardData_2(g_io_forward_2_forwardData_2),
    .io_forward_2_forwardData_3(g_io_forward_2_forwardData_3),
    .io_forward_2_forwardData_4(g_io_forward_2_forwardData_4),
    .io_forward_2_forwardData_5(g_io_forward_2_forwardData_5),
    .io_forward_2_forwardData_6(g_io_forward_2_forwardData_6),
    .io_forward_2_forwardData_7(g_io_forward_2_forwardData_7),
    .io_forward_2_forwardData_8(g_io_forward_2_forwardData_8),
    .io_forward_2_forwardData_9(g_io_forward_2_forwardData_9),
    .io_forward_2_forwardData_10(g_io_forward_2_forwardData_10),
    .io_forward_2_forwardData_11(g_io_forward_2_forwardData_11),
    .io_forward_2_forwardData_12(g_io_forward_2_forwardData_12),
    .io_forward_2_forwardData_13(g_io_forward_2_forwardData_13),
    .io_forward_2_forwardData_14(g_io_forward_2_forwardData_14),
    .io_forward_2_forwardData_15(g_io_forward_2_forwardData_15),
    .io_forward_2_forward_result_valid(g_io_forward_2_forward_result_valid),
    .io_forward_2_denied(g_io_forward_2_denied),
    .io_forward_2_corrupt(g_io_forward_2_corrupt),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_lqEmpty(io_lqEmpty),
    .io_prefetch_info_naive_late_miss_prefetch(g_io_prefetch_info_naive_late_miss_prefetch),
    .io_prefetch_info_fdp_late_miss_prefetch(g_io_prefetch_info_fdp_late_miss_prefetch),
    .io_prefetch_info_fdp_prefetch_monitor_cnt(g_io_prefetch_info_fdp_prefetch_monitor_cnt),
    .io_prefetch_info_fdp_total_prefetch(g_io_prefetch_info_fdp_total_prefetch),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(g_io_wfi_wfiSafe),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDCache(g_io_debugTopDown_robHeadMissInDCache),
    .io_l1Miss(g_io_l1Miss),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .gatewayIn_packed_41_bore(g_gatewayIn_packed_41_bore)
  );
  MissQueue_xs u_impl (
    .clock(clock),
    .reset(reset),
    .io_hartId(io_hartId),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_pf_source(io_req_bits_pf_source),
    .io_req_bits_cmd(io_req_bits_cmd),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_vaddr(io_req_bits_vaddr),
    .io_req_bits_full_overwrite(io_req_bits_full_overwrite),
    .io_req_bits_word_idx(io_req_bits_word_idx),
    .io_req_bits_amo_data(io_req_bits_amo_data),
    .io_req_bits_amo_mask(io_req_bits_amo_mask),
    .io_req_bits_amo_cmp(io_req_bits_amo_cmp),
    .io_req_bits_req_coh_state(io_req_bits_req_coh_state),
    .io_req_bits_id(io_req_bits_id),
    .io_req_bits_isBtoT(io_req_bits_isBtoT),
    .io_req_bits_occupy_way(io_req_bits_occupy_way),
    .io_req_bits_cancel(io_req_bits_cancel),
    .io_req_bits_store_data(io_req_bits_store_data),
    .io_req_bits_store_mask(io_req_bits_store_mask),
    .io_resp_id(i_io_resp_id),
    .io_resp_handled(i_io_resp_handled),
    .io_resp_merged(i_io_resp_merged),
    .io_cmo_req_ready(i_io_cmo_req_ready),
    .io_cmo_req_valid(io_cmo_req_valid),
    .io_cmo_req_bits_opcode(io_cmo_req_bits_opcode),
    .io_cmo_req_bits_address(io_cmo_req_bits_address),
    .io_cmo_resp_ready(io_cmo_resp_ready),
    .io_cmo_resp_valid(i_io_cmo_resp_valid),
    .io_cmo_resp_bits_denied(i_io_cmo_resp_bits_denied),
    .io_cmo_resp_bits_corrupt(i_io_cmo_resp_bits_corrupt),
    .io_queryMQ_0_req_bits_source(io_queryMQ_0_req_bits_source),
    .io_queryMQ_0_req_bits_addr(io_queryMQ_0_req_bits_addr),
    .io_queryMQ_0_req_bits_vaddr(io_queryMQ_0_req_bits_vaddr),
    .io_queryMQ_0_ready(i_io_queryMQ_0_ready),
    .io_queryMQ_1_req_bits_source(io_queryMQ_1_req_bits_source),
    .io_queryMQ_1_req_bits_addr(io_queryMQ_1_req_bits_addr),
    .io_queryMQ_1_req_bits_vaddr(io_queryMQ_1_req_bits_vaddr),
    .io_queryMQ_1_ready(i_io_queryMQ_1_ready),
    .io_queryMQ_2_req_bits_source(io_queryMQ_2_req_bits_source),
    .io_queryMQ_2_req_bits_addr(io_queryMQ_2_req_bits_addr),
    .io_queryMQ_2_req_bits_vaddr(io_queryMQ_2_req_bits_vaddr),
    .io_queryMQ_2_ready(i_io_queryMQ_2_ready),
    .io_queryMQ_3_req_bits_source(io_queryMQ_3_req_bits_source),
    .io_queryMQ_3_req_bits_addr(io_queryMQ_3_req_bits_addr),
    .io_queryMQ_3_req_bits_vaddr(io_queryMQ_3_req_bits_vaddr),
    .io_queryMQ_3_ready(i_io_queryMQ_3_ready),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(i_io_mem_acquire_valid),
    .io_mem_acquire_bits_opcode(i_io_mem_acquire_bits_opcode),
    .io_mem_acquire_bits_param(i_io_mem_acquire_bits_param),
    .io_mem_acquire_bits_size(i_io_mem_acquire_bits_size),
    .io_mem_acquire_bits_source(i_io_mem_acquire_bits_source),
    .io_mem_acquire_bits_address(i_io_mem_acquire_bits_address),
    .io_mem_acquire_bits_user_alias(i_io_mem_acquire_bits_user_alias),
    .io_mem_acquire_bits_user_vaddr(i_io_mem_acquire_bits_user_vaddr),
    .io_mem_acquire_bits_user_reqSource(i_io_mem_acquire_bits_user_reqSource),
    .io_mem_acquire_bits_user_needHint(i_io_mem_acquire_bits_user_needHint),
    .io_mem_acquire_bits_echo_isKeyword(i_io_mem_acquire_bits_echo_isKeyword),
    .io_mem_acquire_bits_mask(i_io_mem_acquire_bits_mask),
    .io_mem_grant_ready(i_io_mem_grant_ready),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param(io_mem_grant_bits_param),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_sink(io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied(io_mem_grant_bits_denied),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .io_mem_finish_ready(io_mem_finish_ready),
    .io_mem_finish_valid(i_io_mem_finish_valid),
    .io_mem_finish_bits_sink(i_io_mem_finish_bits_sink),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
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
    .io_main_pipe_resp_valid(io_main_pipe_resp_valid),
    .io_main_pipe_resp_bits_miss_id(io_main_pipe_resp_bits_miss_id),
    .io_main_pipe_resp_bits_ack_miss_queue(io_main_pipe_resp_bits_ack_miss_queue),
    .io_mainpipe_info_s2_valid(io_mainpipe_info_s2_valid),
    .io_mainpipe_info_s2_miss_id(io_mainpipe_info_s2_miss_id),
    .io_mainpipe_info_s2_replay_to_mq(io_mainpipe_info_s2_replay_to_mq),
    .io_mainpipe_info_s2_evict_BtoT_way(io_mainpipe_info_s2_evict_BtoT_way),
    .io_mainpipe_info_s2_next_evict_way(io_mainpipe_info_s2_next_evict_way),
    .io_mainpipe_info_s3_valid(io_mainpipe_info_s3_valid),
    .io_mainpipe_info_s3_miss_id(io_mainpipe_info_s3_miss_id),
    .io_mainpipe_info_s3_refill_resp(io_mainpipe_info_s3_refill_resp),
    .io_refill_info_valid(i_io_refill_info_valid),
    .io_refill_info_bits_store_data(i_io_refill_info_bits_store_data),
    .io_refill_info_bits_store_mask(i_io_refill_info_bits_store_mask),
    .io_refill_info_bits_miss_param(i_io_refill_info_bits_miss_param),
    .io_refill_info_bits_error_tl_denied(i_io_refill_info_bits_error_tl_denied),
    .io_refill_info_bits_error_tl_corrupt(i_io_refill_info_bits_error_tl_corrupt),
    .io_probe_req_bits_addr(io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr(io_probe_req_bits_vaddr),
    .io_probe_block(i_io_probe_block),
    .io_replace_req_bits_addr(io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr(io_replace_req_bits_vaddr),
    .io_replace_block(i_io_replace_block),
    .io_evict_set(io_evict_set),
    .io_btot_ways_for_set(i_io_btot_ways_for_set),
    .io_occupy_set_0(io_occupy_set_0),
    .io_occupy_set_1(io_occupy_set_1),
    .io_occupy_set_2(io_occupy_set_2),
    .io_occupy_fail_0(i_io_occupy_fail_0),
    .io_occupy_fail_1(i_io_occupy_fail_1),
    .io_occupy_fail_2(i_io_occupy_fail_2),
    .io_wbq_block_miss_req(io_wbq_block_miss_req),
    .io_forward_0_valid(io_forward_0_valid),
    .io_forward_0_mshrid(io_forward_0_mshrid),
    .io_forward_0_paddr(io_forward_0_paddr),
    .io_forward_0_forward_mshr(i_io_forward_0_forward_mshr),
    .io_forward_0_forwardData_0(i_io_forward_0_forwardData_0),
    .io_forward_0_forwardData_1(i_io_forward_0_forwardData_1),
    .io_forward_0_forwardData_2(i_io_forward_0_forwardData_2),
    .io_forward_0_forwardData_3(i_io_forward_0_forwardData_3),
    .io_forward_0_forwardData_4(i_io_forward_0_forwardData_4),
    .io_forward_0_forwardData_5(i_io_forward_0_forwardData_5),
    .io_forward_0_forwardData_6(i_io_forward_0_forwardData_6),
    .io_forward_0_forwardData_7(i_io_forward_0_forwardData_7),
    .io_forward_0_forwardData_8(i_io_forward_0_forwardData_8),
    .io_forward_0_forwardData_9(i_io_forward_0_forwardData_9),
    .io_forward_0_forwardData_10(i_io_forward_0_forwardData_10),
    .io_forward_0_forwardData_11(i_io_forward_0_forwardData_11),
    .io_forward_0_forwardData_12(i_io_forward_0_forwardData_12),
    .io_forward_0_forwardData_13(i_io_forward_0_forwardData_13),
    .io_forward_0_forwardData_14(i_io_forward_0_forwardData_14),
    .io_forward_0_forwardData_15(i_io_forward_0_forwardData_15),
    .io_forward_0_forward_result_valid(i_io_forward_0_forward_result_valid),
    .io_forward_0_denied(i_io_forward_0_denied),
    .io_forward_0_corrupt(i_io_forward_0_corrupt),
    .io_forward_1_valid(io_forward_1_valid),
    .io_forward_1_mshrid(io_forward_1_mshrid),
    .io_forward_1_paddr(io_forward_1_paddr),
    .io_forward_1_forward_mshr(i_io_forward_1_forward_mshr),
    .io_forward_1_forwardData_0(i_io_forward_1_forwardData_0),
    .io_forward_1_forwardData_1(i_io_forward_1_forwardData_1),
    .io_forward_1_forwardData_2(i_io_forward_1_forwardData_2),
    .io_forward_1_forwardData_3(i_io_forward_1_forwardData_3),
    .io_forward_1_forwardData_4(i_io_forward_1_forwardData_4),
    .io_forward_1_forwardData_5(i_io_forward_1_forwardData_5),
    .io_forward_1_forwardData_6(i_io_forward_1_forwardData_6),
    .io_forward_1_forwardData_7(i_io_forward_1_forwardData_7),
    .io_forward_1_forwardData_8(i_io_forward_1_forwardData_8),
    .io_forward_1_forwardData_9(i_io_forward_1_forwardData_9),
    .io_forward_1_forwardData_10(i_io_forward_1_forwardData_10),
    .io_forward_1_forwardData_11(i_io_forward_1_forwardData_11),
    .io_forward_1_forwardData_12(i_io_forward_1_forwardData_12),
    .io_forward_1_forwardData_13(i_io_forward_1_forwardData_13),
    .io_forward_1_forwardData_14(i_io_forward_1_forwardData_14),
    .io_forward_1_forwardData_15(i_io_forward_1_forwardData_15),
    .io_forward_1_forward_result_valid(i_io_forward_1_forward_result_valid),
    .io_forward_1_denied(i_io_forward_1_denied),
    .io_forward_1_corrupt(i_io_forward_1_corrupt),
    .io_forward_2_valid(io_forward_2_valid),
    .io_forward_2_mshrid(io_forward_2_mshrid),
    .io_forward_2_paddr(io_forward_2_paddr),
    .io_forward_2_forward_mshr(i_io_forward_2_forward_mshr),
    .io_forward_2_forwardData_0(i_io_forward_2_forwardData_0),
    .io_forward_2_forwardData_1(i_io_forward_2_forwardData_1),
    .io_forward_2_forwardData_2(i_io_forward_2_forwardData_2),
    .io_forward_2_forwardData_3(i_io_forward_2_forwardData_3),
    .io_forward_2_forwardData_4(i_io_forward_2_forwardData_4),
    .io_forward_2_forwardData_5(i_io_forward_2_forwardData_5),
    .io_forward_2_forwardData_6(i_io_forward_2_forwardData_6),
    .io_forward_2_forwardData_7(i_io_forward_2_forwardData_7),
    .io_forward_2_forwardData_8(i_io_forward_2_forwardData_8),
    .io_forward_2_forwardData_9(i_io_forward_2_forwardData_9),
    .io_forward_2_forwardData_10(i_io_forward_2_forwardData_10),
    .io_forward_2_forwardData_11(i_io_forward_2_forwardData_11),
    .io_forward_2_forwardData_12(i_io_forward_2_forwardData_12),
    .io_forward_2_forwardData_13(i_io_forward_2_forwardData_13),
    .io_forward_2_forwardData_14(i_io_forward_2_forwardData_14),
    .io_forward_2_forwardData_15(i_io_forward_2_forwardData_15),
    .io_forward_2_forward_result_valid(i_io_forward_2_forward_result_valid),
    .io_forward_2_denied(i_io_forward_2_denied),
    .io_forward_2_corrupt(i_io_forward_2_corrupt),
    .io_l2_pf_store_only(io_l2_pf_store_only),
    .io_lqEmpty(io_lqEmpty),
    .io_prefetch_info_naive_late_miss_prefetch(i_io_prefetch_info_naive_late_miss_prefetch),
    .io_prefetch_info_fdp_late_miss_prefetch(i_io_prefetch_info_fdp_late_miss_prefetch),
    .io_prefetch_info_fdp_prefetch_monitor_cnt(i_io_prefetch_info_fdp_prefetch_monitor_cnt),
    .io_prefetch_info_fdp_total_prefetch(i_io_prefetch_info_fdp_total_prefetch),
    .io_wfi_wfiReq(io_wfi_wfiReq),
    .io_wfi_wfiSafe(i_io_wfi_wfiSafe),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDCache(i_io_debugTopDown_robHeadMissInDCache),
    .io_l1Miss(i_io_l1Miss),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .gatewayIn_packed_41_bore(i_gatewayIn_packed_41_bore)
  );
  // END GENERATED

  // BEGIN GENERATED(tb-compare)
  logic seen1_io_req_ready = '0, seen0_io_req_ready = '0;
  logic [3:0] seen1_io_resp_id = '0, seen0_io_resp_id = '0;
  logic seen1_io_resp_handled = '0, seen0_io_resp_handled = '0;
  logic seen1_io_resp_merged = '0, seen0_io_resp_merged = '0;
  logic seen1_io_cmo_req_ready = '0, seen0_io_cmo_req_ready = '0;
  logic seen1_io_cmo_resp_valid = '0, seen0_io_cmo_resp_valid = '0;
  logic seen1_io_cmo_resp_bits_denied = '0, seen0_io_cmo_resp_bits_denied = '0;
  logic seen1_io_cmo_resp_bits_corrupt = '0, seen0_io_cmo_resp_bits_corrupt = '0;
  logic seen1_io_queryMQ_0_ready = '0, seen0_io_queryMQ_0_ready = '0;
  logic seen1_io_queryMQ_1_ready = '0, seen0_io_queryMQ_1_ready = '0;
  logic seen1_io_queryMQ_2_ready = '0, seen0_io_queryMQ_2_ready = '0;
  logic seen1_io_queryMQ_3_ready = '0, seen0_io_queryMQ_3_ready = '0;
  logic seen1_io_mem_acquire_valid = '0, seen0_io_mem_acquire_valid = '0;
  logic [3:0] seen1_io_mem_acquire_bits_opcode = '0, seen0_io_mem_acquire_bits_opcode = '0;
  logic [2:0] seen1_io_mem_acquire_bits_param = '0, seen0_io_mem_acquire_bits_param = '0;
  logic [2:0] seen1_io_mem_acquire_bits_size = '0, seen0_io_mem_acquire_bits_size = '0;
  logic [5:0] seen1_io_mem_acquire_bits_source = '0, seen0_io_mem_acquire_bits_source = '0;
  logic [47:0] seen1_io_mem_acquire_bits_address = '0, seen0_io_mem_acquire_bits_address = '0;
  logic [1:0] seen1_io_mem_acquire_bits_user_alias = '0, seen0_io_mem_acquire_bits_user_alias = '0;
  logic [43:0] seen1_io_mem_acquire_bits_user_vaddr = '0, seen0_io_mem_acquire_bits_user_vaddr = '0;
  logic [4:0] seen1_io_mem_acquire_bits_user_reqSource = '0, seen0_io_mem_acquire_bits_user_reqSource = '0;
  logic seen1_io_mem_acquire_bits_user_needHint = '0, seen0_io_mem_acquire_bits_user_needHint = '0;
  logic seen1_io_mem_acquire_bits_echo_isKeyword = '0, seen0_io_mem_acquire_bits_echo_isKeyword = '0;
  logic [31:0] seen1_io_mem_acquire_bits_mask = '0, seen0_io_mem_acquire_bits_mask = '0;
  logic seen1_io_mem_grant_ready = '0, seen0_io_mem_grant_ready = '0;
  logic seen1_io_mem_finish_valid = '0, seen0_io_mem_finish_valid = '0;
  logic [9:0] seen1_io_mem_finish_bits_sink = '0, seen0_io_mem_finish_bits_sink = '0;
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
  logic [63:0] seen1_io_refill_info_bits_store_mask = '0, seen0_io_refill_info_bits_store_mask = '0;
  logic [1:0] seen1_io_refill_info_bits_miss_param = '0, seen0_io_refill_info_bits_miss_param = '0;
  logic seen1_io_refill_info_bits_error_tl_denied = '0, seen0_io_refill_info_bits_error_tl_denied = '0;
  logic seen1_io_refill_info_bits_error_tl_corrupt = '0, seen0_io_refill_info_bits_error_tl_corrupt = '0;
  logic seen1_io_probe_block = '0, seen0_io_probe_block = '0;
  logic seen1_io_replace_block = '0, seen0_io_replace_block = '0;
  logic [3:0] seen1_io_btot_ways_for_set = '0, seen0_io_btot_ways_for_set = '0;
  logic seen1_io_occupy_fail_0 = '0, seen0_io_occupy_fail_0 = '0;
  logic seen1_io_occupy_fail_1 = '0, seen0_io_occupy_fail_1 = '0;
  logic seen1_io_occupy_fail_2 = '0, seen0_io_occupy_fail_2 = '0;
  logic seen1_io_forward_0_forward_mshr = '0, seen0_io_forward_0_forward_mshr = '0;
  logic [7:0] seen1_io_forward_0_forwardData_0 = '0, seen0_io_forward_0_forwardData_0 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_1 = '0, seen0_io_forward_0_forwardData_1 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_2 = '0, seen0_io_forward_0_forwardData_2 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_3 = '0, seen0_io_forward_0_forwardData_3 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_4 = '0, seen0_io_forward_0_forwardData_4 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_5 = '0, seen0_io_forward_0_forwardData_5 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_6 = '0, seen0_io_forward_0_forwardData_6 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_7 = '0, seen0_io_forward_0_forwardData_7 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_8 = '0, seen0_io_forward_0_forwardData_8 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_9 = '0, seen0_io_forward_0_forwardData_9 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_10 = '0, seen0_io_forward_0_forwardData_10 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_11 = '0, seen0_io_forward_0_forwardData_11 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_12 = '0, seen0_io_forward_0_forwardData_12 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_13 = '0, seen0_io_forward_0_forwardData_13 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_14 = '0, seen0_io_forward_0_forwardData_14 = '0;
  logic [7:0] seen1_io_forward_0_forwardData_15 = '0, seen0_io_forward_0_forwardData_15 = '0;
  logic seen1_io_forward_0_forward_result_valid = '0, seen0_io_forward_0_forward_result_valid = '0;
  logic seen1_io_forward_0_denied = '0, seen0_io_forward_0_denied = '0;
  logic seen1_io_forward_0_corrupt = '0, seen0_io_forward_0_corrupt = '0;
  logic seen1_io_forward_1_forward_mshr = '0, seen0_io_forward_1_forward_mshr = '0;
  logic [7:0] seen1_io_forward_1_forwardData_0 = '0, seen0_io_forward_1_forwardData_0 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_1 = '0, seen0_io_forward_1_forwardData_1 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_2 = '0, seen0_io_forward_1_forwardData_2 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_3 = '0, seen0_io_forward_1_forwardData_3 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_4 = '0, seen0_io_forward_1_forwardData_4 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_5 = '0, seen0_io_forward_1_forwardData_5 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_6 = '0, seen0_io_forward_1_forwardData_6 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_7 = '0, seen0_io_forward_1_forwardData_7 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_8 = '0, seen0_io_forward_1_forwardData_8 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_9 = '0, seen0_io_forward_1_forwardData_9 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_10 = '0, seen0_io_forward_1_forwardData_10 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_11 = '0, seen0_io_forward_1_forwardData_11 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_12 = '0, seen0_io_forward_1_forwardData_12 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_13 = '0, seen0_io_forward_1_forwardData_13 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_14 = '0, seen0_io_forward_1_forwardData_14 = '0;
  logic [7:0] seen1_io_forward_1_forwardData_15 = '0, seen0_io_forward_1_forwardData_15 = '0;
  logic seen1_io_forward_1_forward_result_valid = '0, seen0_io_forward_1_forward_result_valid = '0;
  logic seen1_io_forward_1_denied = '0, seen0_io_forward_1_denied = '0;
  logic seen1_io_forward_1_corrupt = '0, seen0_io_forward_1_corrupt = '0;
  logic seen1_io_forward_2_forward_mshr = '0, seen0_io_forward_2_forward_mshr = '0;
  logic [7:0] seen1_io_forward_2_forwardData_0 = '0, seen0_io_forward_2_forwardData_0 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_1 = '0, seen0_io_forward_2_forwardData_1 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_2 = '0, seen0_io_forward_2_forwardData_2 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_3 = '0, seen0_io_forward_2_forwardData_3 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_4 = '0, seen0_io_forward_2_forwardData_4 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_5 = '0, seen0_io_forward_2_forwardData_5 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_6 = '0, seen0_io_forward_2_forwardData_6 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_7 = '0, seen0_io_forward_2_forwardData_7 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_8 = '0, seen0_io_forward_2_forwardData_8 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_9 = '0, seen0_io_forward_2_forwardData_9 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_10 = '0, seen0_io_forward_2_forwardData_10 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_11 = '0, seen0_io_forward_2_forwardData_11 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_12 = '0, seen0_io_forward_2_forwardData_12 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_13 = '0, seen0_io_forward_2_forwardData_13 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_14 = '0, seen0_io_forward_2_forwardData_14 = '0;
  logic [7:0] seen1_io_forward_2_forwardData_15 = '0, seen0_io_forward_2_forwardData_15 = '0;
  logic seen1_io_forward_2_forward_result_valid = '0, seen0_io_forward_2_forward_result_valid = '0;
  logic seen1_io_forward_2_denied = '0, seen0_io_forward_2_denied = '0;
  logic seen1_io_forward_2_corrupt = '0, seen0_io_forward_2_corrupt = '0;
  logic seen1_io_prefetch_info_naive_late_miss_prefetch = '0, seen0_io_prefetch_info_naive_late_miss_prefetch = '0;
  logic seen1_io_prefetch_info_fdp_late_miss_prefetch = '0, seen0_io_prefetch_info_fdp_late_miss_prefetch = '0;
  logic seen1_io_prefetch_info_fdp_prefetch_monitor_cnt = '0, seen0_io_prefetch_info_fdp_prefetch_monitor_cnt = '0;
  logic seen1_io_prefetch_info_fdp_total_prefetch = '0, seen0_io_prefetch_info_fdp_total_prefetch = '0;
  logic seen1_io_wfi_wfiSafe = '0, seen0_io_wfi_wfiSafe = '0;
  logic seen1_io_debugTopDown_robHeadMissInDCache = '0, seen0_io_debugTopDown_robHeadMissInDCache = '0;
  logic seen1_io_l1Miss = '0, seen0_io_l1Miss = '0;
  logic [5:0] seen1_io_perf_0_value = '0, seen0_io_perf_0_value = '0;
  logic [5:0] seen1_io_perf_1_value = '0, seen0_io_perf_1_value = '0;
  logic [5:0] seen1_io_perf_2_value = '0, seen0_io_perf_2_value = '0;
  logic [5:0] seen1_io_perf_3_value = '0, seen0_io_perf_3_value = '0;
  logic [5:0] seen1_io_perf_4_value = '0, seen0_io_perf_4_value = '0;
  logic [600:0] seen1_gatewayIn_packed_41_bore = '0, seen0_gatewayIn_packed_41_bore = '0;
  task automatic compare_outputs();
    if (g_io_req_ready !== i_io_req_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_req_ready: g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready);
    end
    seen1_io_req_ready |= g_io_req_ready;
    seen0_io_req_ready |= ~g_io_req_ready;
    if (g_io_resp_id !== i_io_resp_id) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_id: g=%h i=%h", cyc, g_io_resp_id, i_io_resp_id);
    end
    seen1_io_resp_id |= g_io_resp_id;
    seen0_io_resp_id |= ~g_io_resp_id;
    if (g_io_resp_handled !== i_io_resp_handled) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_handled: g=%h i=%h", cyc, g_io_resp_handled, i_io_resp_handled);
    end
    seen1_io_resp_handled |= g_io_resp_handled;
    seen0_io_resp_handled |= ~g_io_resp_handled;
    if (g_io_resp_merged !== i_io_resp_merged) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_resp_merged: g=%h i=%h", cyc, g_io_resp_merged, i_io_resp_merged);
    end
    seen1_io_resp_merged |= g_io_resp_merged;
    seen0_io_resp_merged |= ~g_io_resp_merged;
    if (g_io_cmo_req_ready !== i_io_cmo_req_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_cmo_req_ready: g=%h i=%h", cyc, g_io_cmo_req_ready, i_io_cmo_req_ready);
    end
    seen1_io_cmo_req_ready |= g_io_cmo_req_ready;
    seen0_io_cmo_req_ready |= ~g_io_cmo_req_ready;
    if (g_io_cmo_resp_valid !== i_io_cmo_resp_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_cmo_resp_valid: g=%h i=%h", cyc, g_io_cmo_resp_valid, i_io_cmo_resp_valid);
    end
    seen1_io_cmo_resp_valid |= g_io_cmo_resp_valid;
    seen0_io_cmo_resp_valid |= ~g_io_cmo_resp_valid;
    if (g_io_cmo_resp_bits_denied !== i_io_cmo_resp_bits_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_cmo_resp_bits_denied: g=%h i=%h", cyc, g_io_cmo_resp_bits_denied, i_io_cmo_resp_bits_denied);
    end
    seen1_io_cmo_resp_bits_denied |= g_io_cmo_resp_bits_denied;
    seen0_io_cmo_resp_bits_denied |= ~g_io_cmo_resp_bits_denied;
    if (g_io_cmo_resp_bits_corrupt !== i_io_cmo_resp_bits_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_cmo_resp_bits_corrupt: g=%h i=%h", cyc, g_io_cmo_resp_bits_corrupt, i_io_cmo_resp_bits_corrupt);
    end
    seen1_io_cmo_resp_bits_corrupt |= g_io_cmo_resp_bits_corrupt;
    seen0_io_cmo_resp_bits_corrupt |= ~g_io_cmo_resp_bits_corrupt;
    if (g_io_queryMQ_0_ready !== i_io_queryMQ_0_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryMQ_0_ready: g=%h i=%h", cyc, g_io_queryMQ_0_ready, i_io_queryMQ_0_ready);
    end
    seen1_io_queryMQ_0_ready |= g_io_queryMQ_0_ready;
    seen0_io_queryMQ_0_ready |= ~g_io_queryMQ_0_ready;
    if (g_io_queryMQ_1_ready !== i_io_queryMQ_1_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryMQ_1_ready: g=%h i=%h", cyc, g_io_queryMQ_1_ready, i_io_queryMQ_1_ready);
    end
    seen1_io_queryMQ_1_ready |= g_io_queryMQ_1_ready;
    seen0_io_queryMQ_1_ready |= ~g_io_queryMQ_1_ready;
    if (g_io_queryMQ_2_ready !== i_io_queryMQ_2_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryMQ_2_ready: g=%h i=%h", cyc, g_io_queryMQ_2_ready, i_io_queryMQ_2_ready);
    end
    seen1_io_queryMQ_2_ready |= g_io_queryMQ_2_ready;
    seen0_io_queryMQ_2_ready |= ~g_io_queryMQ_2_ready;
    if (g_io_queryMQ_3_ready !== i_io_queryMQ_3_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_queryMQ_3_ready: g=%h i=%h", cyc, g_io_queryMQ_3_ready, i_io_queryMQ_3_ready);
    end
    seen1_io_queryMQ_3_ready |= g_io_queryMQ_3_ready;
    seen0_io_queryMQ_3_ready |= ~g_io_queryMQ_3_ready;
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
    if (g_io_mem_acquire_bits_size !== i_io_mem_acquire_bits_size) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_size: g=%h i=%h", cyc, g_io_mem_acquire_bits_size, i_io_mem_acquire_bits_size);
    end
    seen1_io_mem_acquire_bits_size |= g_io_mem_acquire_bits_size;
    seen0_io_mem_acquire_bits_size |= ~g_io_mem_acquire_bits_size;
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
    if (g_io_mem_acquire_bits_mask !== i_io_mem_acquire_bits_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_acquire_bits_mask: g=%h i=%h", cyc, g_io_mem_acquire_bits_mask, i_io_mem_acquire_bits_mask);
    end
    seen1_io_mem_acquire_bits_mask |= g_io_mem_acquire_bits_mask;
    seen0_io_mem_acquire_bits_mask |= ~g_io_mem_acquire_bits_mask;
    if (g_io_mem_grant_ready !== i_io_mem_grant_ready) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_mem_grant_ready: g=%h i=%h", cyc, g_io_mem_grant_ready, i_io_mem_grant_ready);
    end
    seen1_io_mem_grant_ready |= g_io_mem_grant_ready;
    seen0_io_mem_grant_ready |= ~g_io_mem_grant_ready;
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
    if (g_io_refill_info_bits_store_mask !== i_io_refill_info_bits_store_mask) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_refill_info_bits_store_mask: g=%h i=%h", cyc, g_io_refill_info_bits_store_mask, i_io_refill_info_bits_store_mask);
    end
    seen1_io_refill_info_bits_store_mask |= g_io_refill_info_bits_store_mask;
    seen0_io_refill_info_bits_store_mask |= ~g_io_refill_info_bits_store_mask;
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
    if (g_io_btot_ways_for_set !== i_io_btot_ways_for_set) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_btot_ways_for_set: g=%h i=%h", cyc, g_io_btot_ways_for_set, i_io_btot_ways_for_set);
    end
    seen1_io_btot_ways_for_set |= g_io_btot_ways_for_set;
    seen0_io_btot_ways_for_set |= ~g_io_btot_ways_for_set;
    if (g_io_occupy_fail_0 !== i_io_occupy_fail_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_occupy_fail_0: g=%h i=%h", cyc, g_io_occupy_fail_0, i_io_occupy_fail_0);
    end
    seen1_io_occupy_fail_0 |= g_io_occupy_fail_0;
    seen0_io_occupy_fail_0 |= ~g_io_occupy_fail_0;
    if (g_io_occupy_fail_1 !== i_io_occupy_fail_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_occupy_fail_1: g=%h i=%h", cyc, g_io_occupy_fail_1, i_io_occupy_fail_1);
    end
    seen1_io_occupy_fail_1 |= g_io_occupy_fail_1;
    seen0_io_occupy_fail_1 |= ~g_io_occupy_fail_1;
    if (g_io_occupy_fail_2 !== i_io_occupy_fail_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_occupy_fail_2: g=%h i=%h", cyc, g_io_occupy_fail_2, i_io_occupy_fail_2);
    end
    seen1_io_occupy_fail_2 |= g_io_occupy_fail_2;
    seen0_io_occupy_fail_2 |= ~g_io_occupy_fail_2;
    if (g_io_forward_0_forward_mshr !== i_io_forward_0_forward_mshr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forward_mshr: g=%h i=%h", cyc, g_io_forward_0_forward_mshr, i_io_forward_0_forward_mshr);
    end
    seen1_io_forward_0_forward_mshr |= g_io_forward_0_forward_mshr;
    seen0_io_forward_0_forward_mshr |= ~g_io_forward_0_forward_mshr;
    if (g_io_forward_0_forwardData_0 !== i_io_forward_0_forwardData_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_0: g=%h i=%h", cyc, g_io_forward_0_forwardData_0, i_io_forward_0_forwardData_0);
    end
    seen1_io_forward_0_forwardData_0 |= g_io_forward_0_forwardData_0;
    seen0_io_forward_0_forwardData_0 |= ~g_io_forward_0_forwardData_0;
    if (g_io_forward_0_forwardData_1 !== i_io_forward_0_forwardData_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_1: g=%h i=%h", cyc, g_io_forward_0_forwardData_1, i_io_forward_0_forwardData_1);
    end
    seen1_io_forward_0_forwardData_1 |= g_io_forward_0_forwardData_1;
    seen0_io_forward_0_forwardData_1 |= ~g_io_forward_0_forwardData_1;
    if (g_io_forward_0_forwardData_2 !== i_io_forward_0_forwardData_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_2: g=%h i=%h", cyc, g_io_forward_0_forwardData_2, i_io_forward_0_forwardData_2);
    end
    seen1_io_forward_0_forwardData_2 |= g_io_forward_0_forwardData_2;
    seen0_io_forward_0_forwardData_2 |= ~g_io_forward_0_forwardData_2;
    if (g_io_forward_0_forwardData_3 !== i_io_forward_0_forwardData_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_3: g=%h i=%h", cyc, g_io_forward_0_forwardData_3, i_io_forward_0_forwardData_3);
    end
    seen1_io_forward_0_forwardData_3 |= g_io_forward_0_forwardData_3;
    seen0_io_forward_0_forwardData_3 |= ~g_io_forward_0_forwardData_3;
    if (g_io_forward_0_forwardData_4 !== i_io_forward_0_forwardData_4) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_4: g=%h i=%h", cyc, g_io_forward_0_forwardData_4, i_io_forward_0_forwardData_4);
    end
    seen1_io_forward_0_forwardData_4 |= g_io_forward_0_forwardData_4;
    seen0_io_forward_0_forwardData_4 |= ~g_io_forward_0_forwardData_4;
    if (g_io_forward_0_forwardData_5 !== i_io_forward_0_forwardData_5) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_5: g=%h i=%h", cyc, g_io_forward_0_forwardData_5, i_io_forward_0_forwardData_5);
    end
    seen1_io_forward_0_forwardData_5 |= g_io_forward_0_forwardData_5;
    seen0_io_forward_0_forwardData_5 |= ~g_io_forward_0_forwardData_5;
    if (g_io_forward_0_forwardData_6 !== i_io_forward_0_forwardData_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_6: g=%h i=%h", cyc, g_io_forward_0_forwardData_6, i_io_forward_0_forwardData_6);
    end
    seen1_io_forward_0_forwardData_6 |= g_io_forward_0_forwardData_6;
    seen0_io_forward_0_forwardData_6 |= ~g_io_forward_0_forwardData_6;
    if (g_io_forward_0_forwardData_7 !== i_io_forward_0_forwardData_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_7: g=%h i=%h", cyc, g_io_forward_0_forwardData_7, i_io_forward_0_forwardData_7);
    end
    seen1_io_forward_0_forwardData_7 |= g_io_forward_0_forwardData_7;
    seen0_io_forward_0_forwardData_7 |= ~g_io_forward_0_forwardData_7;
    if (g_io_forward_0_forwardData_8 !== i_io_forward_0_forwardData_8) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_8: g=%h i=%h", cyc, g_io_forward_0_forwardData_8, i_io_forward_0_forwardData_8);
    end
    seen1_io_forward_0_forwardData_8 |= g_io_forward_0_forwardData_8;
    seen0_io_forward_0_forwardData_8 |= ~g_io_forward_0_forwardData_8;
    if (g_io_forward_0_forwardData_9 !== i_io_forward_0_forwardData_9) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_9: g=%h i=%h", cyc, g_io_forward_0_forwardData_9, i_io_forward_0_forwardData_9);
    end
    seen1_io_forward_0_forwardData_9 |= g_io_forward_0_forwardData_9;
    seen0_io_forward_0_forwardData_9 |= ~g_io_forward_0_forwardData_9;
    if (g_io_forward_0_forwardData_10 !== i_io_forward_0_forwardData_10) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_10: g=%h i=%h", cyc, g_io_forward_0_forwardData_10, i_io_forward_0_forwardData_10);
    end
    seen1_io_forward_0_forwardData_10 |= g_io_forward_0_forwardData_10;
    seen0_io_forward_0_forwardData_10 |= ~g_io_forward_0_forwardData_10;
    if (g_io_forward_0_forwardData_11 !== i_io_forward_0_forwardData_11) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_11: g=%h i=%h", cyc, g_io_forward_0_forwardData_11, i_io_forward_0_forwardData_11);
    end
    seen1_io_forward_0_forwardData_11 |= g_io_forward_0_forwardData_11;
    seen0_io_forward_0_forwardData_11 |= ~g_io_forward_0_forwardData_11;
    if (g_io_forward_0_forwardData_12 !== i_io_forward_0_forwardData_12) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_12: g=%h i=%h", cyc, g_io_forward_0_forwardData_12, i_io_forward_0_forwardData_12);
    end
    seen1_io_forward_0_forwardData_12 |= g_io_forward_0_forwardData_12;
    seen0_io_forward_0_forwardData_12 |= ~g_io_forward_0_forwardData_12;
    if (g_io_forward_0_forwardData_13 !== i_io_forward_0_forwardData_13) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_13: g=%h i=%h", cyc, g_io_forward_0_forwardData_13, i_io_forward_0_forwardData_13);
    end
    seen1_io_forward_0_forwardData_13 |= g_io_forward_0_forwardData_13;
    seen0_io_forward_0_forwardData_13 |= ~g_io_forward_0_forwardData_13;
    if (g_io_forward_0_forwardData_14 !== i_io_forward_0_forwardData_14) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_14: g=%h i=%h", cyc, g_io_forward_0_forwardData_14, i_io_forward_0_forwardData_14);
    end
    seen1_io_forward_0_forwardData_14 |= g_io_forward_0_forwardData_14;
    seen0_io_forward_0_forwardData_14 |= ~g_io_forward_0_forwardData_14;
    if (g_io_forward_0_forwardData_15 !== i_io_forward_0_forwardData_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forwardData_15: g=%h i=%h", cyc, g_io_forward_0_forwardData_15, i_io_forward_0_forwardData_15);
    end
    seen1_io_forward_0_forwardData_15 |= g_io_forward_0_forwardData_15;
    seen0_io_forward_0_forwardData_15 |= ~g_io_forward_0_forwardData_15;
    if (g_io_forward_0_forward_result_valid !== i_io_forward_0_forward_result_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_forward_result_valid: g=%h i=%h", cyc, g_io_forward_0_forward_result_valid, i_io_forward_0_forward_result_valid);
    end
    seen1_io_forward_0_forward_result_valid |= g_io_forward_0_forward_result_valid;
    seen0_io_forward_0_forward_result_valid |= ~g_io_forward_0_forward_result_valid;
    if (g_io_forward_0_denied !== i_io_forward_0_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_denied: g=%h i=%h", cyc, g_io_forward_0_denied, i_io_forward_0_denied);
    end
    seen1_io_forward_0_denied |= g_io_forward_0_denied;
    seen0_io_forward_0_denied |= ~g_io_forward_0_denied;
    if (g_io_forward_0_corrupt !== i_io_forward_0_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_0_corrupt: g=%h i=%h", cyc, g_io_forward_0_corrupt, i_io_forward_0_corrupt);
    end
    seen1_io_forward_0_corrupt |= g_io_forward_0_corrupt;
    seen0_io_forward_0_corrupt |= ~g_io_forward_0_corrupt;
    if (g_io_forward_1_forward_mshr !== i_io_forward_1_forward_mshr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forward_mshr: g=%h i=%h", cyc, g_io_forward_1_forward_mshr, i_io_forward_1_forward_mshr);
    end
    seen1_io_forward_1_forward_mshr |= g_io_forward_1_forward_mshr;
    seen0_io_forward_1_forward_mshr |= ~g_io_forward_1_forward_mshr;
    if (g_io_forward_1_forwardData_0 !== i_io_forward_1_forwardData_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_0: g=%h i=%h", cyc, g_io_forward_1_forwardData_0, i_io_forward_1_forwardData_0);
    end
    seen1_io_forward_1_forwardData_0 |= g_io_forward_1_forwardData_0;
    seen0_io_forward_1_forwardData_0 |= ~g_io_forward_1_forwardData_0;
    if (g_io_forward_1_forwardData_1 !== i_io_forward_1_forwardData_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_1: g=%h i=%h", cyc, g_io_forward_1_forwardData_1, i_io_forward_1_forwardData_1);
    end
    seen1_io_forward_1_forwardData_1 |= g_io_forward_1_forwardData_1;
    seen0_io_forward_1_forwardData_1 |= ~g_io_forward_1_forwardData_1;
    if (g_io_forward_1_forwardData_2 !== i_io_forward_1_forwardData_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_2: g=%h i=%h", cyc, g_io_forward_1_forwardData_2, i_io_forward_1_forwardData_2);
    end
    seen1_io_forward_1_forwardData_2 |= g_io_forward_1_forwardData_2;
    seen0_io_forward_1_forwardData_2 |= ~g_io_forward_1_forwardData_2;
    if (g_io_forward_1_forwardData_3 !== i_io_forward_1_forwardData_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_3: g=%h i=%h", cyc, g_io_forward_1_forwardData_3, i_io_forward_1_forwardData_3);
    end
    seen1_io_forward_1_forwardData_3 |= g_io_forward_1_forwardData_3;
    seen0_io_forward_1_forwardData_3 |= ~g_io_forward_1_forwardData_3;
    if (g_io_forward_1_forwardData_4 !== i_io_forward_1_forwardData_4) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_4: g=%h i=%h", cyc, g_io_forward_1_forwardData_4, i_io_forward_1_forwardData_4);
    end
    seen1_io_forward_1_forwardData_4 |= g_io_forward_1_forwardData_4;
    seen0_io_forward_1_forwardData_4 |= ~g_io_forward_1_forwardData_4;
    if (g_io_forward_1_forwardData_5 !== i_io_forward_1_forwardData_5) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_5: g=%h i=%h", cyc, g_io_forward_1_forwardData_5, i_io_forward_1_forwardData_5);
    end
    seen1_io_forward_1_forwardData_5 |= g_io_forward_1_forwardData_5;
    seen0_io_forward_1_forwardData_5 |= ~g_io_forward_1_forwardData_5;
    if (g_io_forward_1_forwardData_6 !== i_io_forward_1_forwardData_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_6: g=%h i=%h", cyc, g_io_forward_1_forwardData_6, i_io_forward_1_forwardData_6);
    end
    seen1_io_forward_1_forwardData_6 |= g_io_forward_1_forwardData_6;
    seen0_io_forward_1_forwardData_6 |= ~g_io_forward_1_forwardData_6;
    if (g_io_forward_1_forwardData_7 !== i_io_forward_1_forwardData_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_7: g=%h i=%h", cyc, g_io_forward_1_forwardData_7, i_io_forward_1_forwardData_7);
    end
    seen1_io_forward_1_forwardData_7 |= g_io_forward_1_forwardData_7;
    seen0_io_forward_1_forwardData_7 |= ~g_io_forward_1_forwardData_7;
    if (g_io_forward_1_forwardData_8 !== i_io_forward_1_forwardData_8) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_8: g=%h i=%h", cyc, g_io_forward_1_forwardData_8, i_io_forward_1_forwardData_8);
    end
    seen1_io_forward_1_forwardData_8 |= g_io_forward_1_forwardData_8;
    seen0_io_forward_1_forwardData_8 |= ~g_io_forward_1_forwardData_8;
    if (g_io_forward_1_forwardData_9 !== i_io_forward_1_forwardData_9) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_9: g=%h i=%h", cyc, g_io_forward_1_forwardData_9, i_io_forward_1_forwardData_9);
    end
    seen1_io_forward_1_forwardData_9 |= g_io_forward_1_forwardData_9;
    seen0_io_forward_1_forwardData_9 |= ~g_io_forward_1_forwardData_9;
    if (g_io_forward_1_forwardData_10 !== i_io_forward_1_forwardData_10) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_10: g=%h i=%h", cyc, g_io_forward_1_forwardData_10, i_io_forward_1_forwardData_10);
    end
    seen1_io_forward_1_forwardData_10 |= g_io_forward_1_forwardData_10;
    seen0_io_forward_1_forwardData_10 |= ~g_io_forward_1_forwardData_10;
    if (g_io_forward_1_forwardData_11 !== i_io_forward_1_forwardData_11) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_11: g=%h i=%h", cyc, g_io_forward_1_forwardData_11, i_io_forward_1_forwardData_11);
    end
    seen1_io_forward_1_forwardData_11 |= g_io_forward_1_forwardData_11;
    seen0_io_forward_1_forwardData_11 |= ~g_io_forward_1_forwardData_11;
    if (g_io_forward_1_forwardData_12 !== i_io_forward_1_forwardData_12) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_12: g=%h i=%h", cyc, g_io_forward_1_forwardData_12, i_io_forward_1_forwardData_12);
    end
    seen1_io_forward_1_forwardData_12 |= g_io_forward_1_forwardData_12;
    seen0_io_forward_1_forwardData_12 |= ~g_io_forward_1_forwardData_12;
    if (g_io_forward_1_forwardData_13 !== i_io_forward_1_forwardData_13) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_13: g=%h i=%h", cyc, g_io_forward_1_forwardData_13, i_io_forward_1_forwardData_13);
    end
    seen1_io_forward_1_forwardData_13 |= g_io_forward_1_forwardData_13;
    seen0_io_forward_1_forwardData_13 |= ~g_io_forward_1_forwardData_13;
    if (g_io_forward_1_forwardData_14 !== i_io_forward_1_forwardData_14) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_14: g=%h i=%h", cyc, g_io_forward_1_forwardData_14, i_io_forward_1_forwardData_14);
    end
    seen1_io_forward_1_forwardData_14 |= g_io_forward_1_forwardData_14;
    seen0_io_forward_1_forwardData_14 |= ~g_io_forward_1_forwardData_14;
    if (g_io_forward_1_forwardData_15 !== i_io_forward_1_forwardData_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forwardData_15: g=%h i=%h", cyc, g_io_forward_1_forwardData_15, i_io_forward_1_forwardData_15);
    end
    seen1_io_forward_1_forwardData_15 |= g_io_forward_1_forwardData_15;
    seen0_io_forward_1_forwardData_15 |= ~g_io_forward_1_forwardData_15;
    if (g_io_forward_1_forward_result_valid !== i_io_forward_1_forward_result_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_forward_result_valid: g=%h i=%h", cyc, g_io_forward_1_forward_result_valid, i_io_forward_1_forward_result_valid);
    end
    seen1_io_forward_1_forward_result_valid |= g_io_forward_1_forward_result_valid;
    seen0_io_forward_1_forward_result_valid |= ~g_io_forward_1_forward_result_valid;
    if (g_io_forward_1_denied !== i_io_forward_1_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_denied: g=%h i=%h", cyc, g_io_forward_1_denied, i_io_forward_1_denied);
    end
    seen1_io_forward_1_denied |= g_io_forward_1_denied;
    seen0_io_forward_1_denied |= ~g_io_forward_1_denied;
    if (g_io_forward_1_corrupt !== i_io_forward_1_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_1_corrupt: g=%h i=%h", cyc, g_io_forward_1_corrupt, i_io_forward_1_corrupt);
    end
    seen1_io_forward_1_corrupt |= g_io_forward_1_corrupt;
    seen0_io_forward_1_corrupt |= ~g_io_forward_1_corrupt;
    if (g_io_forward_2_forward_mshr !== i_io_forward_2_forward_mshr) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forward_mshr: g=%h i=%h", cyc, g_io_forward_2_forward_mshr, i_io_forward_2_forward_mshr);
    end
    seen1_io_forward_2_forward_mshr |= g_io_forward_2_forward_mshr;
    seen0_io_forward_2_forward_mshr |= ~g_io_forward_2_forward_mshr;
    if (g_io_forward_2_forwardData_0 !== i_io_forward_2_forwardData_0) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_0: g=%h i=%h", cyc, g_io_forward_2_forwardData_0, i_io_forward_2_forwardData_0);
    end
    seen1_io_forward_2_forwardData_0 |= g_io_forward_2_forwardData_0;
    seen0_io_forward_2_forwardData_0 |= ~g_io_forward_2_forwardData_0;
    if (g_io_forward_2_forwardData_1 !== i_io_forward_2_forwardData_1) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_1: g=%h i=%h", cyc, g_io_forward_2_forwardData_1, i_io_forward_2_forwardData_1);
    end
    seen1_io_forward_2_forwardData_1 |= g_io_forward_2_forwardData_1;
    seen0_io_forward_2_forwardData_1 |= ~g_io_forward_2_forwardData_1;
    if (g_io_forward_2_forwardData_2 !== i_io_forward_2_forwardData_2) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_2: g=%h i=%h", cyc, g_io_forward_2_forwardData_2, i_io_forward_2_forwardData_2);
    end
    seen1_io_forward_2_forwardData_2 |= g_io_forward_2_forwardData_2;
    seen0_io_forward_2_forwardData_2 |= ~g_io_forward_2_forwardData_2;
    if (g_io_forward_2_forwardData_3 !== i_io_forward_2_forwardData_3) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_3: g=%h i=%h", cyc, g_io_forward_2_forwardData_3, i_io_forward_2_forwardData_3);
    end
    seen1_io_forward_2_forwardData_3 |= g_io_forward_2_forwardData_3;
    seen0_io_forward_2_forwardData_3 |= ~g_io_forward_2_forwardData_3;
    if (g_io_forward_2_forwardData_4 !== i_io_forward_2_forwardData_4) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_4: g=%h i=%h", cyc, g_io_forward_2_forwardData_4, i_io_forward_2_forwardData_4);
    end
    seen1_io_forward_2_forwardData_4 |= g_io_forward_2_forwardData_4;
    seen0_io_forward_2_forwardData_4 |= ~g_io_forward_2_forwardData_4;
    if (g_io_forward_2_forwardData_5 !== i_io_forward_2_forwardData_5) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_5: g=%h i=%h", cyc, g_io_forward_2_forwardData_5, i_io_forward_2_forwardData_5);
    end
    seen1_io_forward_2_forwardData_5 |= g_io_forward_2_forwardData_5;
    seen0_io_forward_2_forwardData_5 |= ~g_io_forward_2_forwardData_5;
    if (g_io_forward_2_forwardData_6 !== i_io_forward_2_forwardData_6) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_6: g=%h i=%h", cyc, g_io_forward_2_forwardData_6, i_io_forward_2_forwardData_6);
    end
    seen1_io_forward_2_forwardData_6 |= g_io_forward_2_forwardData_6;
    seen0_io_forward_2_forwardData_6 |= ~g_io_forward_2_forwardData_6;
    if (g_io_forward_2_forwardData_7 !== i_io_forward_2_forwardData_7) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_7: g=%h i=%h", cyc, g_io_forward_2_forwardData_7, i_io_forward_2_forwardData_7);
    end
    seen1_io_forward_2_forwardData_7 |= g_io_forward_2_forwardData_7;
    seen0_io_forward_2_forwardData_7 |= ~g_io_forward_2_forwardData_7;
    if (g_io_forward_2_forwardData_8 !== i_io_forward_2_forwardData_8) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_8: g=%h i=%h", cyc, g_io_forward_2_forwardData_8, i_io_forward_2_forwardData_8);
    end
    seen1_io_forward_2_forwardData_8 |= g_io_forward_2_forwardData_8;
    seen0_io_forward_2_forwardData_8 |= ~g_io_forward_2_forwardData_8;
    if (g_io_forward_2_forwardData_9 !== i_io_forward_2_forwardData_9) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_9: g=%h i=%h", cyc, g_io_forward_2_forwardData_9, i_io_forward_2_forwardData_9);
    end
    seen1_io_forward_2_forwardData_9 |= g_io_forward_2_forwardData_9;
    seen0_io_forward_2_forwardData_9 |= ~g_io_forward_2_forwardData_9;
    if (g_io_forward_2_forwardData_10 !== i_io_forward_2_forwardData_10) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_10: g=%h i=%h", cyc, g_io_forward_2_forwardData_10, i_io_forward_2_forwardData_10);
    end
    seen1_io_forward_2_forwardData_10 |= g_io_forward_2_forwardData_10;
    seen0_io_forward_2_forwardData_10 |= ~g_io_forward_2_forwardData_10;
    if (g_io_forward_2_forwardData_11 !== i_io_forward_2_forwardData_11) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_11: g=%h i=%h", cyc, g_io_forward_2_forwardData_11, i_io_forward_2_forwardData_11);
    end
    seen1_io_forward_2_forwardData_11 |= g_io_forward_2_forwardData_11;
    seen0_io_forward_2_forwardData_11 |= ~g_io_forward_2_forwardData_11;
    if (g_io_forward_2_forwardData_12 !== i_io_forward_2_forwardData_12) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_12: g=%h i=%h", cyc, g_io_forward_2_forwardData_12, i_io_forward_2_forwardData_12);
    end
    seen1_io_forward_2_forwardData_12 |= g_io_forward_2_forwardData_12;
    seen0_io_forward_2_forwardData_12 |= ~g_io_forward_2_forwardData_12;
    if (g_io_forward_2_forwardData_13 !== i_io_forward_2_forwardData_13) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_13: g=%h i=%h", cyc, g_io_forward_2_forwardData_13, i_io_forward_2_forwardData_13);
    end
    seen1_io_forward_2_forwardData_13 |= g_io_forward_2_forwardData_13;
    seen0_io_forward_2_forwardData_13 |= ~g_io_forward_2_forwardData_13;
    if (g_io_forward_2_forwardData_14 !== i_io_forward_2_forwardData_14) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_14: g=%h i=%h", cyc, g_io_forward_2_forwardData_14, i_io_forward_2_forwardData_14);
    end
    seen1_io_forward_2_forwardData_14 |= g_io_forward_2_forwardData_14;
    seen0_io_forward_2_forwardData_14 |= ~g_io_forward_2_forwardData_14;
    if (g_io_forward_2_forwardData_15 !== i_io_forward_2_forwardData_15) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forwardData_15: g=%h i=%h", cyc, g_io_forward_2_forwardData_15, i_io_forward_2_forwardData_15);
    end
    seen1_io_forward_2_forwardData_15 |= g_io_forward_2_forwardData_15;
    seen0_io_forward_2_forwardData_15 |= ~g_io_forward_2_forwardData_15;
    if (g_io_forward_2_forward_result_valid !== i_io_forward_2_forward_result_valid) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_forward_result_valid: g=%h i=%h", cyc, g_io_forward_2_forward_result_valid, i_io_forward_2_forward_result_valid);
    end
    seen1_io_forward_2_forward_result_valid |= g_io_forward_2_forward_result_valid;
    seen0_io_forward_2_forward_result_valid |= ~g_io_forward_2_forward_result_valid;
    if (g_io_forward_2_denied !== i_io_forward_2_denied) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_denied: g=%h i=%h", cyc, g_io_forward_2_denied, i_io_forward_2_denied);
    end
    seen1_io_forward_2_denied |= g_io_forward_2_denied;
    seen0_io_forward_2_denied |= ~g_io_forward_2_denied;
    if (g_io_forward_2_corrupt !== i_io_forward_2_corrupt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_forward_2_corrupt: g=%h i=%h", cyc, g_io_forward_2_corrupt, i_io_forward_2_corrupt);
    end
    seen1_io_forward_2_corrupt |= g_io_forward_2_corrupt;
    seen0_io_forward_2_corrupt |= ~g_io_forward_2_corrupt;
    if (g_io_prefetch_info_naive_late_miss_prefetch !== i_io_prefetch_info_naive_late_miss_prefetch) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_prefetch_info_naive_late_miss_prefetch: g=%h i=%h", cyc, g_io_prefetch_info_naive_late_miss_prefetch, i_io_prefetch_info_naive_late_miss_prefetch);
    end
    seen1_io_prefetch_info_naive_late_miss_prefetch |= g_io_prefetch_info_naive_late_miss_prefetch;
    seen0_io_prefetch_info_naive_late_miss_prefetch |= ~g_io_prefetch_info_naive_late_miss_prefetch;
    if (g_io_prefetch_info_fdp_late_miss_prefetch !== i_io_prefetch_info_fdp_late_miss_prefetch) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_prefetch_info_fdp_late_miss_prefetch: g=%h i=%h", cyc, g_io_prefetch_info_fdp_late_miss_prefetch, i_io_prefetch_info_fdp_late_miss_prefetch);
    end
    seen1_io_prefetch_info_fdp_late_miss_prefetch |= g_io_prefetch_info_fdp_late_miss_prefetch;
    seen0_io_prefetch_info_fdp_late_miss_prefetch |= ~g_io_prefetch_info_fdp_late_miss_prefetch;
    if (g_io_prefetch_info_fdp_prefetch_monitor_cnt !== i_io_prefetch_info_fdp_prefetch_monitor_cnt) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_prefetch_info_fdp_prefetch_monitor_cnt: g=%h i=%h", cyc, g_io_prefetch_info_fdp_prefetch_monitor_cnt, i_io_prefetch_info_fdp_prefetch_monitor_cnt);
    end
    seen1_io_prefetch_info_fdp_prefetch_monitor_cnt |= g_io_prefetch_info_fdp_prefetch_monitor_cnt;
    seen0_io_prefetch_info_fdp_prefetch_monitor_cnt |= ~g_io_prefetch_info_fdp_prefetch_monitor_cnt;
    if (g_io_prefetch_info_fdp_total_prefetch !== i_io_prefetch_info_fdp_total_prefetch) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_prefetch_info_fdp_total_prefetch: g=%h i=%h", cyc, g_io_prefetch_info_fdp_total_prefetch, i_io_prefetch_info_fdp_total_prefetch);
    end
    seen1_io_prefetch_info_fdp_total_prefetch |= g_io_prefetch_info_fdp_total_prefetch;
    seen0_io_prefetch_info_fdp_total_prefetch |= ~g_io_prefetch_info_fdp_total_prefetch;
    if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_wfi_wfiSafe: g=%h i=%h", cyc, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe);
    end
    seen1_io_wfi_wfiSafe |= g_io_wfi_wfiSafe;
    seen0_io_wfi_wfiSafe |= ~g_io_wfi_wfiSafe;
    if (g_io_debugTopDown_robHeadMissInDCache !== i_io_debugTopDown_robHeadMissInDCache) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_debugTopDown_robHeadMissInDCache: g=%h i=%h", cyc, g_io_debugTopDown_robHeadMissInDCache, i_io_debugTopDown_robHeadMissInDCache);
    end
    seen1_io_debugTopDown_robHeadMissInDCache |= g_io_debugTopDown_robHeadMissInDCache;
    seen0_io_debugTopDown_robHeadMissInDCache |= ~g_io_debugTopDown_robHeadMissInDCache;
    if (g_io_l1Miss !== i_io_l1Miss) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_l1Miss: g=%h i=%h", cyc, g_io_l1Miss, i_io_l1Miss);
    end
    seen1_io_l1Miss |= g_io_l1Miss;
    seen0_io_l1Miss |= ~g_io_l1Miss;
    if (g_io_perf_0_value !== i_io_perf_0_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_0_value: g=%h i=%h", cyc, g_io_perf_0_value, i_io_perf_0_value);
    end
    seen1_io_perf_0_value |= g_io_perf_0_value;
    seen0_io_perf_0_value |= ~g_io_perf_0_value;
    if (g_io_perf_1_value !== i_io_perf_1_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_1_value: g=%h i=%h", cyc, g_io_perf_1_value, i_io_perf_1_value);
    end
    seen1_io_perf_1_value |= g_io_perf_1_value;
    seen0_io_perf_1_value |= ~g_io_perf_1_value;
    if (g_io_perf_2_value !== i_io_perf_2_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_2_value: g=%h i=%h", cyc, g_io_perf_2_value, i_io_perf_2_value);
    end
    seen1_io_perf_2_value |= g_io_perf_2_value;
    seen0_io_perf_2_value |= ~g_io_perf_2_value;
    if (g_io_perf_3_value !== i_io_perf_3_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_3_value: g=%h i=%h", cyc, g_io_perf_3_value, i_io_perf_3_value);
    end
    seen1_io_perf_3_value |= g_io_perf_3_value;
    seen0_io_perf_3_value |= ~g_io_perf_3_value;
    if (g_io_perf_4_value !== i_io_perf_4_value) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d io_perf_4_value: g=%h i=%h", cyc, g_io_perf_4_value, i_io_perf_4_value);
    end
    seen1_io_perf_4_value |= g_io_perf_4_value;
    seen0_io_perf_4_value |= ~g_io_perf_4_value;
    if (g_gatewayIn_packed_41_bore !== i_gatewayIn_packed_41_bore) begin
      errors++;
      if (errors <= 20) $display("MISMATCH cyc=%0d gatewayIn_packed_41_bore: g=%h i=%h", cyc, g_gatewayIn_packed_41_bore, i_gatewayIn_packed_41_bore);
    end
    seen1_gatewayIn_packed_41_bore |= g_gatewayIn_packed_41_bore;
    seen0_gatewayIn_packed_41_bore |= ~g_gatewayIn_packed_41_bore;
    checks++;
  endtask
  // 返回从未翻转过的输出端口个数（逐个打印）
  function automatic int report_toggle();
    int bad = 0;
    if (((~seen1_io_req_ready | ~seen0_io_req_ready)) != '0) begin bad++; $display("TOGGLE MISS io_req_ready 1=%h 0=%h", seen1_io_req_ready, seen0_io_req_ready); end
    if (((~seen1_io_resp_id | ~seen0_io_resp_id)) != '0) begin bad++; $display("TOGGLE MISS io_resp_id 1=%h 0=%h", seen1_io_resp_id, seen0_io_resp_id); end
    if (((~seen1_io_resp_handled | ~seen0_io_resp_handled)) != '0) begin bad++; $display("TOGGLE MISS io_resp_handled 1=%h 0=%h", seen1_io_resp_handled, seen0_io_resp_handled); end
    if (((~seen1_io_resp_merged | ~seen0_io_resp_merged)) != '0) begin bad++; $display("TOGGLE MISS io_resp_merged 1=%h 0=%h", seen1_io_resp_merged, seen0_io_resp_merged); end
    if (((~seen1_io_cmo_req_ready | ~seen0_io_cmo_req_ready)) != '0) begin bad++; $display("TOGGLE MISS io_cmo_req_ready 1=%h 0=%h", seen1_io_cmo_req_ready, seen0_io_cmo_req_ready); end
    if (((~seen1_io_cmo_resp_valid | ~seen0_io_cmo_resp_valid)) != '0) begin bad++; $display("TOGGLE MISS io_cmo_resp_valid 1=%h 0=%h", seen1_io_cmo_resp_valid, seen0_io_cmo_resp_valid); end
    if (((~seen1_io_cmo_resp_bits_denied | ~seen0_io_cmo_resp_bits_denied)) != '0) begin bad++; $display("TOGGLE MISS io_cmo_resp_bits_denied 1=%h 0=%h", seen1_io_cmo_resp_bits_denied, seen0_io_cmo_resp_bits_denied); end
    if (((~seen1_io_cmo_resp_bits_corrupt | ~seen0_io_cmo_resp_bits_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_cmo_resp_bits_corrupt 1=%h 0=%h", seen1_io_cmo_resp_bits_corrupt, seen0_io_cmo_resp_bits_corrupt); end
    if (((~seen1_io_queryMQ_0_ready | ~seen0_io_queryMQ_0_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryMQ_0_ready 1=%h 0=%h", seen1_io_queryMQ_0_ready, seen0_io_queryMQ_0_ready); end
    if (((~seen1_io_queryMQ_1_ready | ~seen0_io_queryMQ_1_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryMQ_1_ready 1=%h 0=%h", seen1_io_queryMQ_1_ready, seen0_io_queryMQ_1_ready); end
    if (((~seen1_io_queryMQ_2_ready | ~seen0_io_queryMQ_2_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryMQ_2_ready 1=%h 0=%h", seen1_io_queryMQ_2_ready, seen0_io_queryMQ_2_ready); end
    if (((~seen1_io_queryMQ_3_ready | ~seen0_io_queryMQ_3_ready)) != '0) begin bad++; $display("TOGGLE MISS io_queryMQ_3_ready 1=%h 0=%h", seen1_io_queryMQ_3_ready, seen0_io_queryMQ_3_ready); end
    if (((~seen1_io_mem_acquire_valid | ~seen0_io_mem_acquire_valid)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_valid 1=%h 0=%h", seen1_io_mem_acquire_valid, seen0_io_mem_acquire_valid); end
    if (((~seen1_io_mem_acquire_bits_opcode | ~seen0_io_mem_acquire_bits_opcode)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_opcode 1=%h 0=%h", seen1_io_mem_acquire_bits_opcode, seen0_io_mem_acquire_bits_opcode); end
    if (((~seen1_io_mem_acquire_bits_param | ~seen0_io_mem_acquire_bits_param) & ~3'h4) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_param 1=%h 0=%h", seen1_io_mem_acquire_bits_param, seen0_io_mem_acquire_bits_param); end
    if (((~seen1_io_mem_acquire_bits_size | ~seen0_io_mem_acquire_bits_size) & ~3'h1) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_size 1=%h 0=%h", seen1_io_mem_acquire_bits_size, seen0_io_mem_acquire_bits_size); end
    if (((~seen1_io_mem_acquire_bits_source | ~seen0_io_mem_acquire_bits_source) & ~6'h20) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_source 1=%h 0=%h", seen1_io_mem_acquire_bits_source, seen0_io_mem_acquire_bits_source); end
    if (((~seen1_io_mem_acquire_bits_address | ~seen0_io_mem_acquire_bits_address)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_address 1=%h 0=%h", seen1_io_mem_acquire_bits_address, seen0_io_mem_acquire_bits_address); end
    if (((~seen1_io_mem_acquire_bits_user_alias | ~seen0_io_mem_acquire_bits_user_alias)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_alias 1=%h 0=%h", seen1_io_mem_acquire_bits_user_alias, seen0_io_mem_acquire_bits_user_alias); end
    if (((~seen1_io_mem_acquire_bits_user_vaddr | ~seen0_io_mem_acquire_bits_user_vaddr)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_vaddr 1=%h 0=%h", seen1_io_mem_acquire_bits_user_vaddr, seen0_io_mem_acquire_bits_user_vaddr); end
    if (((~seen1_io_mem_acquire_bits_user_reqSource | ~seen0_io_mem_acquire_bits_user_reqSource) & ~5'h18) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_reqSource 1=%h 0=%h", seen1_io_mem_acquire_bits_user_reqSource, seen0_io_mem_acquire_bits_user_reqSource); end
    if (((~seen1_io_mem_acquire_bits_user_needHint | ~seen0_io_mem_acquire_bits_user_needHint)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_user_needHint 1=%h 0=%h", seen1_io_mem_acquire_bits_user_needHint, seen0_io_mem_acquire_bits_user_needHint); end
    if (((~seen1_io_mem_acquire_bits_echo_isKeyword | ~seen0_io_mem_acquire_bits_echo_isKeyword)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_echo_isKeyword 1=%h 0=%h", seen1_io_mem_acquire_bits_echo_isKeyword, seen0_io_mem_acquire_bits_echo_isKeyword); end
    if (((~seen1_io_mem_acquire_bits_mask | ~seen0_io_mem_acquire_bits_mask)) != '0) begin bad++; $display("TOGGLE MISS io_mem_acquire_bits_mask 1=%h 0=%h", seen1_io_mem_acquire_bits_mask, seen0_io_mem_acquire_bits_mask); end
    if (((~seen1_io_mem_grant_ready | ~seen0_io_mem_grant_ready)) != '0) begin bad++; $display("TOGGLE MISS io_mem_grant_ready 1=%h 0=%h", seen1_io_mem_grant_ready, seen0_io_mem_grant_ready); end
    if (((~seen1_io_mem_finish_valid | ~seen0_io_mem_finish_valid)) != '0) begin bad++; $display("TOGGLE MISS io_mem_finish_valid 1=%h 0=%h", seen1_io_mem_finish_valid, seen0_io_mem_finish_valid); end
    if (((~seen1_io_mem_finish_bits_sink | ~seen0_io_mem_finish_bits_sink)) != '0) begin bad++; $display("TOGGLE MISS io_mem_finish_bits_sink 1=%h 0=%h", seen1_io_mem_finish_bits_sink, seen0_io_mem_finish_bits_sink); end
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
    if (((~seen1_io_refill_info_bits_store_mask | ~seen0_io_refill_info_bits_store_mask) & ~64'hffffffffffffffff) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_store_mask 1=%h 0=%h", seen1_io_refill_info_bits_store_mask, seen0_io_refill_info_bits_store_mask); end
    if (((~seen1_io_refill_info_bits_miss_param | ~seen0_io_refill_info_bits_miss_param)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_miss_param 1=%h 0=%h", seen1_io_refill_info_bits_miss_param, seen0_io_refill_info_bits_miss_param); end
    if (((~seen1_io_refill_info_bits_error_tl_denied | ~seen0_io_refill_info_bits_error_tl_denied)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_error_tl_denied 1=%h 0=%h", seen1_io_refill_info_bits_error_tl_denied, seen0_io_refill_info_bits_error_tl_denied); end
    if (((~seen1_io_refill_info_bits_error_tl_corrupt | ~seen0_io_refill_info_bits_error_tl_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_refill_info_bits_error_tl_corrupt 1=%h 0=%h", seen1_io_refill_info_bits_error_tl_corrupt, seen0_io_refill_info_bits_error_tl_corrupt); end
    if (((~seen1_io_probe_block | ~seen0_io_probe_block)) != '0) begin bad++; $display("TOGGLE MISS io_probe_block 1=%h 0=%h", seen1_io_probe_block, seen0_io_probe_block); end
    if (((~seen1_io_replace_block | ~seen0_io_replace_block)) != '0) begin bad++; $display("TOGGLE MISS io_replace_block 1=%h 0=%h", seen1_io_replace_block, seen0_io_replace_block); end
    if (((~seen1_io_btot_ways_for_set | ~seen0_io_btot_ways_for_set)) != '0) begin bad++; $display("TOGGLE MISS io_btot_ways_for_set 1=%h 0=%h", seen1_io_btot_ways_for_set, seen0_io_btot_ways_for_set); end
    if (((~seen1_io_occupy_fail_0 | ~seen0_io_occupy_fail_0)) != '0) begin bad++; $display("TOGGLE MISS io_occupy_fail_0 1=%h 0=%h", seen1_io_occupy_fail_0, seen0_io_occupy_fail_0); end
    if (((~seen1_io_occupy_fail_1 | ~seen0_io_occupy_fail_1)) != '0) begin bad++; $display("TOGGLE MISS io_occupy_fail_1 1=%h 0=%h", seen1_io_occupy_fail_1, seen0_io_occupy_fail_1); end
    if (((~seen1_io_occupy_fail_2 | ~seen0_io_occupy_fail_2)) != '0) begin bad++; $display("TOGGLE MISS io_occupy_fail_2 1=%h 0=%h", seen1_io_occupy_fail_2, seen0_io_occupy_fail_2); end
    if (((~seen1_io_forward_0_forward_mshr | ~seen0_io_forward_0_forward_mshr)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forward_mshr 1=%h 0=%h", seen1_io_forward_0_forward_mshr, seen0_io_forward_0_forward_mshr); end
    if (((~seen1_io_forward_0_forwardData_0 | ~seen0_io_forward_0_forwardData_0)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_0 1=%h 0=%h", seen1_io_forward_0_forwardData_0, seen0_io_forward_0_forwardData_0); end
    if (((~seen1_io_forward_0_forwardData_1 | ~seen0_io_forward_0_forwardData_1)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_1 1=%h 0=%h", seen1_io_forward_0_forwardData_1, seen0_io_forward_0_forwardData_1); end
    if (((~seen1_io_forward_0_forwardData_2 | ~seen0_io_forward_0_forwardData_2)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_2 1=%h 0=%h", seen1_io_forward_0_forwardData_2, seen0_io_forward_0_forwardData_2); end
    if (((~seen1_io_forward_0_forwardData_3 | ~seen0_io_forward_0_forwardData_3)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_3 1=%h 0=%h", seen1_io_forward_0_forwardData_3, seen0_io_forward_0_forwardData_3); end
    if (((~seen1_io_forward_0_forwardData_4 | ~seen0_io_forward_0_forwardData_4)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_4 1=%h 0=%h", seen1_io_forward_0_forwardData_4, seen0_io_forward_0_forwardData_4); end
    if (((~seen1_io_forward_0_forwardData_5 | ~seen0_io_forward_0_forwardData_5)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_5 1=%h 0=%h", seen1_io_forward_0_forwardData_5, seen0_io_forward_0_forwardData_5); end
    if (((~seen1_io_forward_0_forwardData_6 | ~seen0_io_forward_0_forwardData_6)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_6 1=%h 0=%h", seen1_io_forward_0_forwardData_6, seen0_io_forward_0_forwardData_6); end
    if (((~seen1_io_forward_0_forwardData_7 | ~seen0_io_forward_0_forwardData_7)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_7 1=%h 0=%h", seen1_io_forward_0_forwardData_7, seen0_io_forward_0_forwardData_7); end
    if (((~seen1_io_forward_0_forwardData_8 | ~seen0_io_forward_0_forwardData_8)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_8 1=%h 0=%h", seen1_io_forward_0_forwardData_8, seen0_io_forward_0_forwardData_8); end
    if (((~seen1_io_forward_0_forwardData_9 | ~seen0_io_forward_0_forwardData_9)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_9 1=%h 0=%h", seen1_io_forward_0_forwardData_9, seen0_io_forward_0_forwardData_9); end
    if (((~seen1_io_forward_0_forwardData_10 | ~seen0_io_forward_0_forwardData_10)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_10 1=%h 0=%h", seen1_io_forward_0_forwardData_10, seen0_io_forward_0_forwardData_10); end
    if (((~seen1_io_forward_0_forwardData_11 | ~seen0_io_forward_0_forwardData_11)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_11 1=%h 0=%h", seen1_io_forward_0_forwardData_11, seen0_io_forward_0_forwardData_11); end
    if (((~seen1_io_forward_0_forwardData_12 | ~seen0_io_forward_0_forwardData_12)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_12 1=%h 0=%h", seen1_io_forward_0_forwardData_12, seen0_io_forward_0_forwardData_12); end
    if (((~seen1_io_forward_0_forwardData_13 | ~seen0_io_forward_0_forwardData_13)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_13 1=%h 0=%h", seen1_io_forward_0_forwardData_13, seen0_io_forward_0_forwardData_13); end
    if (((~seen1_io_forward_0_forwardData_14 | ~seen0_io_forward_0_forwardData_14)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_14 1=%h 0=%h", seen1_io_forward_0_forwardData_14, seen0_io_forward_0_forwardData_14); end
    if (((~seen1_io_forward_0_forwardData_15 | ~seen0_io_forward_0_forwardData_15)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forwardData_15 1=%h 0=%h", seen1_io_forward_0_forwardData_15, seen0_io_forward_0_forwardData_15); end
    if (((~seen1_io_forward_0_forward_result_valid | ~seen0_io_forward_0_forward_result_valid)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_forward_result_valid 1=%h 0=%h", seen1_io_forward_0_forward_result_valid, seen0_io_forward_0_forward_result_valid); end
    if (((~seen1_io_forward_0_denied | ~seen0_io_forward_0_denied)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_denied 1=%h 0=%h", seen1_io_forward_0_denied, seen0_io_forward_0_denied); end
    if (((~seen1_io_forward_0_corrupt | ~seen0_io_forward_0_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_forward_0_corrupt 1=%h 0=%h", seen1_io_forward_0_corrupt, seen0_io_forward_0_corrupt); end
    if (((~seen1_io_forward_1_forward_mshr | ~seen0_io_forward_1_forward_mshr)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forward_mshr 1=%h 0=%h", seen1_io_forward_1_forward_mshr, seen0_io_forward_1_forward_mshr); end
    if (((~seen1_io_forward_1_forwardData_0 | ~seen0_io_forward_1_forwardData_0)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_0 1=%h 0=%h", seen1_io_forward_1_forwardData_0, seen0_io_forward_1_forwardData_0); end
    if (((~seen1_io_forward_1_forwardData_1 | ~seen0_io_forward_1_forwardData_1)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_1 1=%h 0=%h", seen1_io_forward_1_forwardData_1, seen0_io_forward_1_forwardData_1); end
    if (((~seen1_io_forward_1_forwardData_2 | ~seen0_io_forward_1_forwardData_2)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_2 1=%h 0=%h", seen1_io_forward_1_forwardData_2, seen0_io_forward_1_forwardData_2); end
    if (((~seen1_io_forward_1_forwardData_3 | ~seen0_io_forward_1_forwardData_3)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_3 1=%h 0=%h", seen1_io_forward_1_forwardData_3, seen0_io_forward_1_forwardData_3); end
    if (((~seen1_io_forward_1_forwardData_4 | ~seen0_io_forward_1_forwardData_4)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_4 1=%h 0=%h", seen1_io_forward_1_forwardData_4, seen0_io_forward_1_forwardData_4); end
    if (((~seen1_io_forward_1_forwardData_5 | ~seen0_io_forward_1_forwardData_5)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_5 1=%h 0=%h", seen1_io_forward_1_forwardData_5, seen0_io_forward_1_forwardData_5); end
    if (((~seen1_io_forward_1_forwardData_6 | ~seen0_io_forward_1_forwardData_6)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_6 1=%h 0=%h", seen1_io_forward_1_forwardData_6, seen0_io_forward_1_forwardData_6); end
    if (((~seen1_io_forward_1_forwardData_7 | ~seen0_io_forward_1_forwardData_7)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_7 1=%h 0=%h", seen1_io_forward_1_forwardData_7, seen0_io_forward_1_forwardData_7); end
    if (((~seen1_io_forward_1_forwardData_8 | ~seen0_io_forward_1_forwardData_8)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_8 1=%h 0=%h", seen1_io_forward_1_forwardData_8, seen0_io_forward_1_forwardData_8); end
    if (((~seen1_io_forward_1_forwardData_9 | ~seen0_io_forward_1_forwardData_9)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_9 1=%h 0=%h", seen1_io_forward_1_forwardData_9, seen0_io_forward_1_forwardData_9); end
    if (((~seen1_io_forward_1_forwardData_10 | ~seen0_io_forward_1_forwardData_10)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_10 1=%h 0=%h", seen1_io_forward_1_forwardData_10, seen0_io_forward_1_forwardData_10); end
    if (((~seen1_io_forward_1_forwardData_11 | ~seen0_io_forward_1_forwardData_11)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_11 1=%h 0=%h", seen1_io_forward_1_forwardData_11, seen0_io_forward_1_forwardData_11); end
    if (((~seen1_io_forward_1_forwardData_12 | ~seen0_io_forward_1_forwardData_12)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_12 1=%h 0=%h", seen1_io_forward_1_forwardData_12, seen0_io_forward_1_forwardData_12); end
    if (((~seen1_io_forward_1_forwardData_13 | ~seen0_io_forward_1_forwardData_13)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_13 1=%h 0=%h", seen1_io_forward_1_forwardData_13, seen0_io_forward_1_forwardData_13); end
    if (((~seen1_io_forward_1_forwardData_14 | ~seen0_io_forward_1_forwardData_14)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_14 1=%h 0=%h", seen1_io_forward_1_forwardData_14, seen0_io_forward_1_forwardData_14); end
    if (((~seen1_io_forward_1_forwardData_15 | ~seen0_io_forward_1_forwardData_15)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forwardData_15 1=%h 0=%h", seen1_io_forward_1_forwardData_15, seen0_io_forward_1_forwardData_15); end
    if (((~seen1_io_forward_1_forward_result_valid | ~seen0_io_forward_1_forward_result_valid)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_forward_result_valid 1=%h 0=%h", seen1_io_forward_1_forward_result_valid, seen0_io_forward_1_forward_result_valid); end
    if (((~seen1_io_forward_1_denied | ~seen0_io_forward_1_denied)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_denied 1=%h 0=%h", seen1_io_forward_1_denied, seen0_io_forward_1_denied); end
    if (((~seen1_io_forward_1_corrupt | ~seen0_io_forward_1_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_forward_1_corrupt 1=%h 0=%h", seen1_io_forward_1_corrupt, seen0_io_forward_1_corrupt); end
    if (((~seen1_io_forward_2_forward_mshr | ~seen0_io_forward_2_forward_mshr)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forward_mshr 1=%h 0=%h", seen1_io_forward_2_forward_mshr, seen0_io_forward_2_forward_mshr); end
    if (((~seen1_io_forward_2_forwardData_0 | ~seen0_io_forward_2_forwardData_0)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_0 1=%h 0=%h", seen1_io_forward_2_forwardData_0, seen0_io_forward_2_forwardData_0); end
    if (((~seen1_io_forward_2_forwardData_1 | ~seen0_io_forward_2_forwardData_1)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_1 1=%h 0=%h", seen1_io_forward_2_forwardData_1, seen0_io_forward_2_forwardData_1); end
    if (((~seen1_io_forward_2_forwardData_2 | ~seen0_io_forward_2_forwardData_2)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_2 1=%h 0=%h", seen1_io_forward_2_forwardData_2, seen0_io_forward_2_forwardData_2); end
    if (((~seen1_io_forward_2_forwardData_3 | ~seen0_io_forward_2_forwardData_3)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_3 1=%h 0=%h", seen1_io_forward_2_forwardData_3, seen0_io_forward_2_forwardData_3); end
    if (((~seen1_io_forward_2_forwardData_4 | ~seen0_io_forward_2_forwardData_4)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_4 1=%h 0=%h", seen1_io_forward_2_forwardData_4, seen0_io_forward_2_forwardData_4); end
    if (((~seen1_io_forward_2_forwardData_5 | ~seen0_io_forward_2_forwardData_5)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_5 1=%h 0=%h", seen1_io_forward_2_forwardData_5, seen0_io_forward_2_forwardData_5); end
    if (((~seen1_io_forward_2_forwardData_6 | ~seen0_io_forward_2_forwardData_6)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_6 1=%h 0=%h", seen1_io_forward_2_forwardData_6, seen0_io_forward_2_forwardData_6); end
    if (((~seen1_io_forward_2_forwardData_7 | ~seen0_io_forward_2_forwardData_7)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_7 1=%h 0=%h", seen1_io_forward_2_forwardData_7, seen0_io_forward_2_forwardData_7); end
    if (((~seen1_io_forward_2_forwardData_8 | ~seen0_io_forward_2_forwardData_8)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_8 1=%h 0=%h", seen1_io_forward_2_forwardData_8, seen0_io_forward_2_forwardData_8); end
    if (((~seen1_io_forward_2_forwardData_9 | ~seen0_io_forward_2_forwardData_9)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_9 1=%h 0=%h", seen1_io_forward_2_forwardData_9, seen0_io_forward_2_forwardData_9); end
    if (((~seen1_io_forward_2_forwardData_10 | ~seen0_io_forward_2_forwardData_10)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_10 1=%h 0=%h", seen1_io_forward_2_forwardData_10, seen0_io_forward_2_forwardData_10); end
    if (((~seen1_io_forward_2_forwardData_11 | ~seen0_io_forward_2_forwardData_11)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_11 1=%h 0=%h", seen1_io_forward_2_forwardData_11, seen0_io_forward_2_forwardData_11); end
    if (((~seen1_io_forward_2_forwardData_12 | ~seen0_io_forward_2_forwardData_12)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_12 1=%h 0=%h", seen1_io_forward_2_forwardData_12, seen0_io_forward_2_forwardData_12); end
    if (((~seen1_io_forward_2_forwardData_13 | ~seen0_io_forward_2_forwardData_13)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_13 1=%h 0=%h", seen1_io_forward_2_forwardData_13, seen0_io_forward_2_forwardData_13); end
    if (((~seen1_io_forward_2_forwardData_14 | ~seen0_io_forward_2_forwardData_14)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_14 1=%h 0=%h", seen1_io_forward_2_forwardData_14, seen0_io_forward_2_forwardData_14); end
    if (((~seen1_io_forward_2_forwardData_15 | ~seen0_io_forward_2_forwardData_15)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forwardData_15 1=%h 0=%h", seen1_io_forward_2_forwardData_15, seen0_io_forward_2_forwardData_15); end
    if (((~seen1_io_forward_2_forward_result_valid | ~seen0_io_forward_2_forward_result_valid)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_forward_result_valid 1=%h 0=%h", seen1_io_forward_2_forward_result_valid, seen0_io_forward_2_forward_result_valid); end
    if (((~seen1_io_forward_2_denied | ~seen0_io_forward_2_denied)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_denied 1=%h 0=%h", seen1_io_forward_2_denied, seen0_io_forward_2_denied); end
    if (((~seen1_io_forward_2_corrupt | ~seen0_io_forward_2_corrupt)) != '0) begin bad++; $display("TOGGLE MISS io_forward_2_corrupt 1=%h 0=%h", seen1_io_forward_2_corrupt, seen0_io_forward_2_corrupt); end
    if (((~seen1_io_prefetch_info_naive_late_miss_prefetch | ~seen0_io_prefetch_info_naive_late_miss_prefetch)) != '0) begin bad++; $display("TOGGLE MISS io_prefetch_info_naive_late_miss_prefetch 1=%h 0=%h", seen1_io_prefetch_info_naive_late_miss_prefetch, seen0_io_prefetch_info_naive_late_miss_prefetch); end
    if (((~seen1_io_prefetch_info_fdp_late_miss_prefetch | ~seen0_io_prefetch_info_fdp_late_miss_prefetch)) != '0) begin bad++; $display("TOGGLE MISS io_prefetch_info_fdp_late_miss_prefetch 1=%h 0=%h", seen1_io_prefetch_info_fdp_late_miss_prefetch, seen0_io_prefetch_info_fdp_late_miss_prefetch); end
    if (((~seen1_io_prefetch_info_fdp_prefetch_monitor_cnt | ~seen0_io_prefetch_info_fdp_prefetch_monitor_cnt)) != '0) begin bad++; $display("TOGGLE MISS io_prefetch_info_fdp_prefetch_monitor_cnt 1=%h 0=%h", seen1_io_prefetch_info_fdp_prefetch_monitor_cnt, seen0_io_prefetch_info_fdp_prefetch_monitor_cnt); end
    if (((~seen1_io_prefetch_info_fdp_total_prefetch | ~seen0_io_prefetch_info_fdp_total_prefetch)) != '0) begin bad++; $display("TOGGLE MISS io_prefetch_info_fdp_total_prefetch 1=%h 0=%h", seen1_io_prefetch_info_fdp_total_prefetch, seen0_io_prefetch_info_fdp_total_prefetch); end
    if (((~seen1_io_wfi_wfiSafe | ~seen0_io_wfi_wfiSafe)) != '0) begin bad++; $display("TOGGLE MISS io_wfi_wfiSafe 1=%h 0=%h", seen1_io_wfi_wfiSafe, seen0_io_wfi_wfiSafe); end
    if (((~seen1_io_debugTopDown_robHeadMissInDCache | ~seen0_io_debugTopDown_robHeadMissInDCache)) != '0) begin bad++; $display("TOGGLE MISS io_debugTopDown_robHeadMissInDCache 1=%h 0=%h", seen1_io_debugTopDown_robHeadMissInDCache, seen0_io_debugTopDown_robHeadMissInDCache); end
    if (((~seen1_io_l1Miss | ~seen0_io_l1Miss)) != '0) begin bad++; $display("TOGGLE MISS io_l1Miss 1=%h 0=%h", seen1_io_l1Miss, seen0_io_l1Miss); end
    if (((~seen1_io_perf_0_value | ~seen0_io_perf_0_value) & ~6'h3e) != '0) begin bad++; $display("TOGGLE MISS io_perf_0_value 1=%h 0=%h", seen1_io_perf_0_value, seen0_io_perf_0_value); end
    if (((~seen1_io_perf_1_value | ~seen0_io_perf_1_value) & ~6'h3e) != '0) begin bad++; $display("TOGGLE MISS io_perf_1_value 1=%h 0=%h", seen1_io_perf_1_value, seen0_io_perf_1_value); end
    if (((~seen1_io_perf_2_value | ~seen0_io_perf_2_value) & ~6'h3e) != '0) begin bad++; $display("TOGGLE MISS io_perf_2_value 1=%h 0=%h", seen1_io_perf_2_value, seen0_io_perf_2_value); end
    if (((~seen1_io_perf_3_value | ~seen0_io_perf_3_value) & ~6'h3e) != '0) begin bad++; $display("TOGGLE MISS io_perf_3_value 1=%h 0=%h", seen1_io_perf_3_value, seen0_io_perf_3_value); end
    if (((~seen1_io_perf_4_value | ~seen0_io_perf_4_value) & ~6'h3e) != '0) begin bad++; $display("TOGGLE MISS io_perf_4_value 1=%h 0=%h", seen1_io_perf_4_value, seen0_io_perf_4_value); end
    if (((~seen1_gatewayIn_packed_41_bore | ~seen0_gatewayIn_packed_41_bore) & ~601'hffff00000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffc0ff) != '0) begin bad++; $display("TOGGLE MISS gatewayIn_packed_41_bore 1=%h 0=%h", seen1_gatewayIn_packed_41_bore, seen0_gatewayIn_packed_41_bore); end
    return bad;
  endfunction
  // END GENERATED

  // ---- 地址池 ----
  logic [47:0] blk_pool [8];
  logic [1:0]  alias_pool [2];
  logic [7:0]  set_pool [4];
  task automatic refresh_pools();
    for (int k = 0; k < 8; k++) blk_pool[k] = {$urandom, $urandom};
    for (int k = 0; k < 4; k++) set_pool[k] = 8'($urandom);
    alias_pool[0] = 2'($urandom); alias_pool[1] = ~alias_pool[0];
  endtask
  function automatic logic [47:0] rand_paddr();
    return {blk_pool[$urandom_range(0, 7)][47:6], 6'($urandom)};
  endfunction
  // vaddr 与 paddr 同池（页内偏移相同更像真的），alias 位 / set 下标另取小池
  function automatic logic [49:0] rand_vaddr(input logic [47:0] pa);
    logic [49:0] v = {2'($urandom), pa};
    if ($urandom_range(0, 3) == 0) v[49:14] = {$urandom, 4'($urandom)};
    v[13:12] = alias_pool[$urandom_range(0, 1)];
    if ($urandom_range(0, 1) == 0) v[13:6] = {alias_pool[$urandom_range(0, 1)], set_pool[$urandom_range(0, 3)][5:0]};
    return v;
  endfunction
  function automatic logic [3:0] rand_source();
    int r = $urandom_range(0, 99);
    if (r < 40) return 4'd0;
    if (r < 65) return 4'd1;
    if (r < 75) return 4'd2;
    if (r < 95) return 4'd3;
    return 4'($urandom_range(4, 15));
  endfunction
  function automatic logic [4:0] rand_cmd();
    int r = $urandom_range(0, 9);
    if (r < 3) return 5'($urandom);
    if (r < 6) return 5'($urandom_range(0, 3));
    return 5'($urandom_range(4, 15));
  endfunction

  int wfi_len = 0;
  bit store_burst = 0;
  logic [3:0] last_mp_id = 0;

  task automatic drive();
    logic [47:0] pa;
    io_req_valid                = ($urandom_range(0, 4) < 3);
    // store 连发模式：store 五成、预取四成、load 一成 —— 计数器在 0..十几之间来回，
    // 门槛 8 附近（恰好停在 7 / 8）也会被经过
    if (store_burst) begin
      case ($urandom_range(0, 9))
        0:          io_req_bits_source = 4'd0;
        1, 2, 3, 4: io_req_bits_source = 4'd3;
        default:    io_req_bits_source = 4'd1;
      endcase
    end else
      io_req_bits_source        = rand_source();
    io_req_bits_pf_source       = 3'($urandom);
    io_req_bits_cmd             = rand_cmd();
    pa                          = rand_paddr();
    if ($urandom_range(0, 3) == 0) begin
      // 重复上一拍的行：让新请求撞上流水寄存器里正在分配的那条（合并进流水寄存器 / 被它拒绝）
      io_req_bits_addr          = {io_req_bits_addr[47:6], 6'($urandom)};
      io_req_bits_vaddr         = {io_req_bits_vaddr[49:6], io_req_bits_addr[5:0]};
    end else begin
      io_req_bits_addr          = pa;
      io_req_bits_vaddr         = rand_vaddr(pa);
    end
    io_req_bits_full_overwrite  = ($urandom_range(0, 3) == 0);
    io_req_bits_word_idx        = 3'($urandom);
    io_req_bits_amo_data        = {$urandom, $urandom, $urandom, $urandom};
    io_req_bits_amo_mask        = 16'($urandom);
    io_req_bits_amo_cmp         = {$urandom, $urandom, $urandom, $urandom};
    io_req_bits_req_coh_state   = 2'($urandom);
    io_req_bits_id              = 6'($urandom);
    io_req_bits_isBtoT          = ($urandom_range(0, 3) == 0);
    io_req_bits_occupy_way      = 4'($urandom);
    io_req_bits_cancel          = ($urandom_range(0, 9) == 0);
    for (int k = 0; k < 16; k++) io_req_bits_store_data[k*32 +: 32] = $urandom;
    io_req_bits_store_mask      = {$urandom, $urandom} & {$urandom, $urandom};
    io_wbq_block_miss_req       = ($urandom_range(0, 9) == 0);
    io_cmo_req_valid            = ($urandom_range(0, 9) == 0);
    io_cmo_req_bits_opcode      = 3'($urandom);
    io_cmo_req_bits_address     = {$urandom, $urandom};
    io_cmo_resp_ready           = ($urandom_range(0, 2) != 0);
    pa = rand_paddr(); io_queryMQ_0_req_bits_source = rand_source(); io_queryMQ_0_req_bits_addr = pa; io_queryMQ_0_req_bits_vaddr = rand_vaddr(pa);
    pa = rand_paddr(); io_queryMQ_1_req_bits_source = rand_source(); io_queryMQ_1_req_bits_addr = pa; io_queryMQ_1_req_bits_vaddr = rand_vaddr(pa);
    pa = rand_paddr(); io_queryMQ_2_req_bits_source = rand_source(); io_queryMQ_2_req_bits_addr = pa; io_queryMQ_2_req_bits_vaddr = rand_vaddr(pa);
    pa = rand_paddr(); io_queryMQ_3_req_bits_source = rand_source(); io_queryMQ_3_req_bits_addr = pa; io_queryMQ_3_req_bits_vaddr = rand_vaddr(pa);
    io_mem_acquire_ready        = ($urandom_range(0, 9) < 7);
    io_mem_grant_valid          = ($urandom_range(0, 9) < 3);
    case ($urandom_range(0, 19))
      0, 1, 2:  io_mem_grant_bits_opcode = 4'd4;
      3, 4:     io_mem_grant_bits_opcode = 4'd8;
      5:        io_mem_grant_bits_opcode = 4'($urandom);
      default:  io_mem_grant_bits_opcode = 4'd5;
    endcase
    io_mem_grant_bits_param     = 2'($urandom);
    io_mem_grant_bits_size      = ($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'd6;
    io_mem_grant_bits_source    = ($urandom_range(0, 19) == 0) ? 6'($urandom) :
                                  (io_mem_grant_bits_opcode == 4'd8) ? 6'd17 : 6'($urandom_range(0, 15));
    // WFI 段内：逐个给表项回无数据 Grant，让在途请求收尾（否则 wfiSafe 很难为 1）
    if (wfi_len > 0) begin
      io_mem_grant_valid = 1'b1; io_mem_grant_bits_opcode = 4'd4;
      io_mem_grant_bits_source = 6'(wfi_len % 16);
    end
    io_mem_grant_bits_sink      = 10'($urandom);
    io_mem_grant_bits_denied    = ($urandom_range(0, 15) == 0);
    io_mem_grant_bits_corrupt   = ($urandom_range(0, 15) == 0);
    for (int k = 0; k < 8; k++) io_mem_grant_bits_data[k*32 +: 32] = $urandom;
    io_mem_finish_ready         = ($urandom_range(0, 3) != 0);
    io_l2_hint_valid            = ($urandom_range(0, 9) == 0);
    io_l2_hint_bits_sourceId    = 4'($urandom);
    io_main_pipe_req_ready      = ($urandom_range(0, 4) < 3);
    io_main_pipe_resp_valid     = ($urandom_range(0, 4) == 0);
    io_main_pipe_resp_bits_miss_id = ($urandom_range(0, 1) == 0) ? last_mp_id : 4'($urandom);
    io_main_pipe_resp_bits_ack_miss_queue = ($urandom_range(0, 3) != 0);
    io_mainpipe_info_s2_valid   = ($urandom_range(0, 2) == 0);
    io_mainpipe_info_s2_miss_id = ($urandom_range(0, 1) == 0) ? last_mp_id : 4'($urandom);
    io_mainpipe_info_s2_replay_to_mq   = ($urandom_range(0, 4) == 0);
    io_mainpipe_info_s2_evict_BtoT_way = ($urandom_range(0, 9) == 0);
    io_mainpipe_info_s2_next_evict_way = 4'($urandom);
    io_mainpipe_info_s3_valid   = ($urandom_range(0, 2) == 0);
    io_mainpipe_info_s3_miss_id = ($urandom_range(0, 1) == 0) ? last_mp_id : 4'($urandom);
    io_mainpipe_info_s3_refill_resp = ($urandom_range(0, 2) != 0);
    pa = rand_paddr(); io_probe_req_bits_addr = pa;   io_probe_req_bits_vaddr = rand_vaddr(pa);
    pa = rand_paddr(); io_replace_req_bits_addr = pa; io_replace_req_bits_vaddr = rand_vaddr(pa);
    io_evict_set                = {alias_pool[$urandom_range(0, 1)], set_pool[$urandom_range(0, 3)][5:0]};
    io_occupy_set_0             = {alias_pool[$urandom_range(0, 1)], set_pool[$urandom_range(0, 3)][5:0]};
    io_occupy_set_1             = {alias_pool[$urandom_range(0, 1)], set_pool[$urandom_range(0, 3)][5:0]};
    io_occupy_set_2             = 8'($urandom);
    io_forward_0_valid          = ($urandom_range(0, 1) == 0);
    io_forward_0_mshrid         = 4'($urandom);
    io_forward_0_paddr          = rand_paddr();
    io_forward_1_valid          = ($urandom_range(0, 1) == 0);
    io_forward_1_mshrid         = 4'($urandom);
    io_forward_1_paddr          = rand_paddr();
    io_forward_2_valid          = ($urandom_range(0, 1) == 0);
    io_forward_2_mshrid         = 4'($urandom);
    io_forward_2_paddr          = rand_paddr();
    io_l2_pf_store_only         = ($urandom_range(0, 7) == 0);
    io_lqEmpty                  = store_burst ? 1'b1 : ($urandom_range(0, 1) == 0);
    if (wfi_len > 0) wfi_len--;
    else if ($urandom_range(0, 199) == 0) wfi_len = $urandom_range(1, 80);
    io_wfi_wfiReq               = (wfi_len > 0);
    io_debugTopDown_robHeadVaddr_valid = ($urandom_range(0, 1) == 0);
    pa = rand_paddr(); io_debugTopDown_robHeadVaddr_bits = rand_vaddr(pa);
  endtask

  // ---- 覆盖计数（看 golden 顶层与内部信号）----
  int cov_alloc, cov_merge_ent, cov_merge_pipe, cov_reject, cov_query_rdy0, cov_query_rdy1;
  int cov_pipe_acq, cov_ent_acq, cov_cmo_acq, cov_cmo_d, cov_cmo_resp, cov_grant_nready;
  int cov_finish, cov_mp_fire, cov_refill_info, cov_probe_block, cov_replace_pipe, cov_btot;
  int cov_occupy_fail, cov_fwd_valid, cov_fwd_mshr, cov_memset, cov_difftest, cov_wfi_safe;
  int cov_acq_blocked, cov_reset;

  task automatic count_cov();
    if (io_req_valid && g_io_resp_handled && !g_io_resp_merged) cov_alloc++;
    if (io_req_valid && g_io_resp_merged && !u_gold.req_pipeline_reg_handled) cov_merge_ent++;
    if (u_gold.req_pipeline_reg_handled) cov_merge_pipe++;
    if (io_req_valid && u_gold.reject) cov_reject++;
    if (!g_io_queryMQ_0_ready) cov_query_rdy0++;
    if (g_io_queryMQ_2_ready) cov_query_rdy1++;
    if (u_gold._entries_15_io_acquire_fired_by_pipe_reg_T_probe) cov_pipe_acq++;
    if (io_mem_acquire_ready && g_io_mem_acquire_valid && g_io_mem_acquire_bits_source < 16 &&
        !u_gold.muxState_1) cov_ent_acq++;
    if (io_mem_acquire_ready && g_io_mem_acquire_valid && g_io_mem_acquire_bits_source == 17) cov_cmo_acq++;
    if (u_gold._cmo_unit_io_resp_chanD_ready && u_gold._GEN_32) cov_cmo_d++;
    if (io_cmo_resp_ready && g_io_cmo_resp_valid) cov_cmo_resp++;
    if (io_mem_grant_valid && !g_io_mem_grant_ready) cov_grant_nready++;
    if (io_mem_finish_ready && g_io_mem_finish_valid) cov_finish++;
    if (io_main_pipe_req_ready && g_io_main_pipe_req_valid) cov_mp_fire++;
    if (g_io_refill_info_valid) cov_refill_info++;
    if (g_io_probe_block) cov_probe_block++;
    if (u_gold._io_prefetch_info_naive_late_miss_prefetch_T_4_probe &&
        u_gold.miss_req_pipe_reg_req_addr[47:6] == io_replace_req_bits_addr[47:6]) cov_replace_pipe++;
    if (g_io_btot_ways_for_set != 0) cov_btot++;
    if (g_io_occupy_fail_0 | g_io_occupy_fail_1) cov_occupy_fail++;
    if (g_io_forward_0_forward_result_valid | g_io_forward_1_forward_result_valid) cov_fwd_valid++;
    if (g_io_forward_2_forward_mshr) cov_fwd_mshr++;
    if (u_gold.memSetPattenDetected_last_REG) cov_memset++;
    if (g_gatewayIn_packed_41_bore[600]) cov_difftest++;
    if (io_wfi_wfiReq && g_io_wfi_wfiSafe) cov_wfi_safe++;
    if (!io_mem_acquire_ready && g_io_mem_acquire_valid) cov_acq_blocked++;
    if (io_main_pipe_req_ready && g_io_main_pipe_req_valid) last_mp_id = g_io_main_pipe_req_bits_miss_id;
  endtask

  // 暖机：16 个 MSHR 各分配一次 store，再各回两拍 GrantData
  task automatic warmup();
    for (int i = 0; i < 16; i++) begin
      @(negedge clock);
      drive();
      io_req_valid = 1; io_req_bits_cancel = 0; io_wbq_block_miss_req = 0;
      io_req_bits_source = 4'd1;
      io_req_bits_addr = {blk_pool[0][47:12], 6'(i), 6'd0};
      io_req_bits_vaddr = {2'd0, io_req_bits_addr};
      io_mem_grant_valid = 0; io_cmo_req_valid = 0;
      io_main_pipe_resp_valid = 0; io_mainpipe_info_s2_valid = 0; io_mainpipe_info_s3_valid = 0;
    end
    for (int i = 0; i < 32; i++) begin
      @(negedge clock);
      drive();
      io_req_valid = 0; io_cmo_req_valid = 0;
      io_main_pipe_resp_valid = 0; io_mainpipe_info_s2_valid = 0; io_mainpipe_info_s3_valid = 0;
      io_mem_grant_valid = 1; io_mem_grant_bits_opcode = 4'd5; io_mem_grant_bits_size = 3'd6;
      io_mem_grant_bits_source = 6'(i / 2);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    refresh_pools();
    io_hartId = 6'($urandom);
    reset = 1;
    drive();
    repeat (5) @(negedge clock);
    reset = 0;
    warmup();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (cyc % 3000 == 2999) refresh_pools();
      if (cyc % 5000 == 4999) io_hartId = 6'($urandom);
      if (cyc % 1000 == 0) store_burst = ($urandom_range(0, 4) == 0);
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
    $display("COVERAGE alloc=%0d merge_ent=%0d merge_pipe=%0d reject=%0d query_nrdy=%0d query_rdy=%0d",
             cov_alloc, cov_merge_ent, cov_merge_pipe, cov_reject, cov_query_rdy0, cov_query_rdy1);
    $display("COVERAGE pipe_acq=%0d ent_acq=%0d cmo_acq=%0d cmo_d=%0d cmo_resp=%0d grant_nready=%0d acq_blocked=%0d",
             cov_pipe_acq, cov_ent_acq, cov_cmo_acq, cov_cmo_d, cov_cmo_resp, cov_grant_nready, cov_acq_blocked);
    $display("COVERAGE finish=%0d mp_fire=%0d refill_info=%0d probe_block=%0d replace_pipe=%0d btot=%0d occupy_fail=%0d",
             cov_finish, cov_mp_fire, cov_refill_info, cov_probe_block, cov_replace_pipe, cov_btot, cov_occupy_fail);
    $display("COVERAGE fwd_valid=%0d fwd_mshr=%0d memset=%0d difftest=%0d wfi_safe=%0d reset=%0d",
             cov_fwd_valid, cov_fwd_mshr, cov_memset, cov_difftest, cov_wfi_safe, cov_reset);
    begin
      int c [$];
      c = '{cov_alloc, cov_merge_ent, cov_merge_pipe, cov_reject, cov_query_rdy0, cov_query_rdy1,
            cov_pipe_acq, cov_ent_acq, cov_cmo_acq, cov_cmo_d, cov_cmo_resp, cov_grant_nready,
            cov_acq_blocked, cov_finish, cov_mp_fire, cov_refill_info, cov_probe_block,
            cov_replace_pipe, cov_btot, cov_occupy_fail, cov_fwd_valid, cov_fwd_mshr, cov_memset,
            cov_difftest, cov_wfi_safe};
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
