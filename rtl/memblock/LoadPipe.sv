// =============================================================================
// LoadPipe.sv —— DCache 的 load 读流水（每条 load 通道一条，DCache 里例化 3 份）
//
// 对应 Chisel：xiangshan.cache.LoadPipe（src/main/scala/xiangshan/cache/dcache/loadpipe/LoadPipe.scala）
//
// 【在哪里】LoadUnit 在自己的 s0 把 load 请求发给这里（io.lsu.req），DCache 的 load 流水与
// LoadUnit 的流水逐级对齐走 4 级：
//   s0  收请求（只带虚地址）→ 用 vaddr[13:6] 读 meta 阵列与 tag 阵列（4 路一起读）
//   s1  LoadUnit 送来 TLB 翻译出的 paddr（两份复制：_dup_lsu / _dup_dcache，只为扇出）；
//       4 路 tag 比较得命中路 → 发数据阵列读（按 bank 掩码只读需要的 bank）；
//       用"一致性状态 × 命令"查权限表，算出命中/缺失与缺失时要的权限升级
//   s2  数据回来 → 回 LoadUnit（data / miss / replay / mshr_id …）；
//       缺失则向 MissQueue 发 miss 请求；tag ECC 检错结果、各种 nack 原因汇总成 replay
//   s3  打一拍的"延迟"结果：data_delayed、ECC/总线错误上报、替换算法访问更新、
//       access/prefetch 标记回写、CounterFilter 去重查询
//
// 【本配置下被 firtool 常量化掉的东西】（golden 端口表现读；Chisel 里存在但这里不写）
//   · io.nack 恒 0、meta_read.ready 恒 1、lsu.resp.ready 恒 1 ⇒ s1_ready/s2_ready 恒 1，
//     流水永不阻塞：s0_fire = s0_valid，s1_fire = s1_valid，s2_fire = s2_valid；
//     io_lsu_req_ready 只剩 tag_read.ready。
//   · WPU（路预测）关闭：s1 用的就是真实命中路，pred_fail 恒 0。
//   · pseudo_error.ready 恒 0：CtrlUnit 的 tag 伪错误只"读"不"消费"（翻转掩码直接异或进 tag）。
//   · 大量调试/性能输出（s2_hit、debug_*、replay_carry …）在 LoadUnit 侧没人读，端口被删。
//
// 【复位】s1_valid / s2_valid / s2_valid_dup 异步复位；其余流水寄存器（含 s3_valid）都不复位，
// 照搬 golden（s3_valid 是 RegNext，不是 RegInit）。
//
// 【仿真检查寄存器】Chisel 的 assert(RegNext(...)) 在 golden 里留下 3 个真寄存器（只有
// `ifndef SYNTHESIS 段读它们），这里同样保留（§6），便于与 golden 逐个对应。
// =============================================================================

package loadpipe_pkg;

  localparam int N_WAYS  = 4;
  localparam int TAG_W   = 36;   // paddr[47:12]
  localparam int ECC_W   = 7;    // SECDED(43,36)
  localparam int ENC_W   = TAG_W + ECC_W;

  // 内存命令编码（rocket-chip MemoryOpConstants，只列本流水用到的）
  localparam logic [4:0] M_XRD = 5'h00;
  localparam logic [4:0] M_PFR = 5'h02;
  localparam logic [4:0] M_PFW = 5'h03;
  localparam logic [4:0] M_XLR = 5'h06;

  localparam logic [3:0] DCACHE_PREFETCH_SOURCE = 4'h3;   // instrtype：硬件预取

  // TileLink ClientStates
  localparam logic [1:0] COH_NOTHING = 2'd0;
  localparam logic [1:0] COH_BRANCH  = 2'd1;
  localparam logic [1:0] COH_TRUNK   = 2'd2;
  localparam logic [1:0] COH_DIRTY   = 2'd3;
  // TileLink Grow 参数（缺失时要的权限升级）
  localparam logic [1:0] NTOB = 2'd0;
  localparam logic [1:0] NTOT = 2'd1;
  localparam logic [1:0] BTOT = 2'd2;

  // isWrite(cmd)：写 / 条件写 / 全部 AMO（含 AMOCAS）
  function automatic logic cmd_is_write(input logic [4:0] cmd);
    case (cmd)
      5'h01, 5'h11, 5'h07,                         // M_XWR / M_PWR / M_XSC
      5'h04, 5'h09, 5'h0A, 5'h0B,                  // AMO 逻辑：SWAP / XOR / OR / AND
      5'h08, 5'h0C, 5'h0D, 5'h0E, 5'h0F,           // AMO 算术：ADD / MIN / MAX / MINU / MAXU
      5'h18, 5'h1A, 5'h1B:                         // AMOCAS 族
        cmd_is_write = 1'b1;
      default:
        cmd_is_write = 1'b0;
    endcase
  endfunction

  // 访问类别 {写, 写意图}：rd = 00，wi（写意图：预取写 / LR）= 01，wr = 11
  function automatic logic [1:0] cmd_category(input logic [4:0] cmd);
    logic wr;
    wr = cmd_is_write(cmd);
    cmd_category = {wr, wr | cmd == M_PFW | cmd == M_XLR};
  endfunction

  // ClientMetadata.growStarter：{类别, 当前状态} → {是否命中, 命中后状态 / 缺失时的 Grow 参数}
  // 表外组合（类别 10 不可能出现）给 {0, 0}，与 Chisel MuxTLookup 的缺省一致。
  typedef struct packed {
    logic       hit;
    logic [1:0] next;   // 命中：新状态；缺失：Grow 参数
  } grow_t;

  function automatic grow_t grow_starter(input logic [1:0] cat, input logic [1:0] coh);
    case ({cat, coh})
      {2'b00, COH_DIRTY}:   grow_starter = '{1'b1, COH_DIRTY};
      {2'b00, COH_TRUNK}:   grow_starter = '{1'b1, COH_TRUNK};
      {2'b00, COH_BRANCH}:  grow_starter = '{1'b1, COH_BRANCH};
      {2'b01, COH_DIRTY}:   grow_starter = '{1'b1, COH_DIRTY};
      {2'b01, COH_TRUNK}:   grow_starter = '{1'b1, COH_TRUNK};
      {2'b11, COH_DIRTY}:   grow_starter = '{1'b1, COH_DIRTY};
      {2'b11, COH_TRUNK}:   grow_starter = '{1'b1, COH_DIRTY};
      {2'b00, COH_NOTHING}: grow_starter = '{1'b0, NTOB};
      {2'b01, COH_BRANCH}:  grow_starter = '{1'b0, BTOT};
      {2'b01, COH_NOTHING}: grow_starter = '{1'b0, NTOT};
      {2'b11, COH_BRANCH}:  grow_starter = '{1'b0, BTOT};
      {2'b11, COH_NOTHING}: grow_starter = '{1'b0, NTOT};
      default:              grow_starter = '{1'b0, 2'd0};
    endcase
  endfunction

  // SECDED(43,36) 检错：enc = {ecc[6:0], tag[35:0]}。
  //   syndrome[k] = ecc[k] ^ ^(tag & H_k)（k = 0..5，H_k 与 DuplicatedTagArray 的编码矩阵相同）；
  //   ecc[6] 是整体奇偶位。error = 整体奇偶为 1（单比特错）或 syndrome 非 0（双比特错）。
  function automatic logic tag_ecc_error(input logic [ENC_W-1:0] enc);
    logic [TAG_W-1:0] tag;
    logic [5:0]       syndrome;
    tag = enc[TAG_W-1:0];
    syndrome[0] = enc[TAG_W+0] ^ ^(tag & 36'h556AAAD5B);
    syndrome[1] = enc[TAG_W+1] ^ ^(tag & 36'h99B33366D);
    syndrome[2] = enc[TAG_W+2] ^ ^(tag & 36'h1E3C3C78E);
    syndrome[3] = enc[TAG_W+3] ^ ^(tag & 36'hE03FC07F0);
    syndrome[4] = enc[TAG_W+4] ^ ^(tag & 36'h003FFF800);
    syndrome[5] = enc[TAG_W+5] ^ ^(tag & 36'hFFC000000);
    tag_ecc_error = (^enc) | (|syndrome);
  endfunction

  // 4 路独热 → 路号（OHToUInt）
  function automatic logic [1:0] oh_to_way(input logic [N_WAYS-1:0] oh);
    oh_to_way = {oh[3] | oh[2], oh[3] | oh[1]};
  endfunction

  // 预取来源是不是 L1 预取（isFromL1Prefetch：prefetch 源编码的高两位非 0）
  function automatic logic is_from_l1_prefetch(input logic [2:0] pf);
    is_from_l1_prefetch = |pf[2:1];
  endfunction

endpackage

module LoadPipe
  import loadpipe_pkg::*;
(
  input          clock,
  input          reset,
  output         io_lsu_req_ready,
  input          io_lsu_req_valid,
  input  [4:0]   io_lsu_req_bits_cmd,
  input  [49:0]  io_lsu_req_bits_vaddr,
  input  [49:0]  io_lsu_req_bits_vaddr_dup,
  input  [3:0]   io_lsu_req_bits_instrtype,
  input          io_lsu_req_bits_isFirstIssue,
  input          io_lsu_req_bits_lqIdx_flag,
  input  [6:0]   io_lsu_req_bits_lqIdx_value,
  output         io_lsu_resp_valid,
  output [127:0] io_lsu_resp_bits_data,
  output [127:0] io_lsu_resp_bits_data_delayed,
  output         io_lsu_resp_bits_miss,
  output [3:0]   io_lsu_resp_bits_mshr_id,
  output [2:0]   io_lsu_resp_bits_meta_prefetch,
  output         io_lsu_resp_bits_handled,
  output         io_lsu_resp_bits_tl_error_delayed_tl_denied,
  output         io_lsu_resp_bits_tl_error_delayed_tl_corrupt,
  input          io_lsu_s1_kill_data_read,
  input          io_lsu_s1_kill,
  input          io_lsu_s2_kill,
  input  [2:0]   io_lsu_pf_source,
  input  [47:0]  io_lsu_s1_paddr_dup_lsu,
  input  [47:0]  io_lsu_s1_paddr_dup_dcache,
  output         io_lsu_s2_bank_conflict,
  output         io_lsu_s2_mq_nack,
  input          io_load128Req,
  output         io_meta_read_valid,
  output [7:0]   io_meta_read_bits_idx,
  input  [1:0]   io_meta_resp_0_coh_state,
  input  [1:0]   io_meta_resp_1_coh_state,
  input  [1:0]   io_meta_resp_2_coh_state,
  input  [1:0]   io_meta_resp_3_coh_state,
  input          io_extra_meta_resp_0_error_tl_denied,
  input          io_extra_meta_resp_0_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_0_prefetch,
  input          io_extra_meta_resp_0_access,
  input          io_extra_meta_resp_1_error_tl_denied,
  input          io_extra_meta_resp_1_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_1_prefetch,
  input          io_extra_meta_resp_1_access,
  input          io_extra_meta_resp_2_error_tl_denied,
  input          io_extra_meta_resp_2_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_2_prefetch,
  input          io_extra_meta_resp_2_access,
  input          io_extra_meta_resp_3_error_tl_denied,
  input          io_extra_meta_resp_3_error_tl_corrupt,
  input  [2:0]   io_extra_meta_resp_3_prefetch,
  input          io_extra_meta_resp_3_access,
  input          io_tag_read_ready,
  output         io_tag_read_valid,
  output [7:0]   io_tag_read_bits_idx,
  input  [42:0]  io_tag_resp_0,
  input  [42:0]  io_tag_resp_1,
  input  [42:0]  io_tag_resp_2,
  input  [42:0]  io_tag_resp_3,
  input          io_banked_data_read_ready,
  output         io_banked_data_read_valid,
  output [3:0]   io_banked_data_read_bits_way_en,
  output [47:0]  io_banked_data_read_bits_addr,
  output [47:0]  io_banked_data_read_bits_addr_dup,
  output [7:0]   io_banked_data_read_bits_bankMask,
  output         io_banked_data_read_bits_lqIdx_flag,
  output [6:0]   io_banked_data_read_bits_lqIdx_value,
  output         io_is128Req,
  input  [63:0]  io_banked_data_resp_0_raw_data,
  input  [63:0]  io_banked_data_resp_1_raw_data,
  input          io_read_error_delayed_0,
  input          io_read_error_delayed_1,
  output         io_access_flag_write_valid,
  output [7:0]   io_access_flag_write_bits_idx,
  output [3:0]   io_access_flag_write_bits_way_en,
  output         io_prefetch_flag_write_valid,
  output [7:0]   io_prefetch_flag_write_bits_idx,
  output [3:0]   io_prefetch_flag_write_bits_way_en,
  input          io_bank_conflict_slow,
  input          io_miss_req_ready,
  output         io_miss_req_valid,
  output [3:0]   io_miss_req_bits_source,
  output [2:0]   io_miss_req_bits_pf_source,
  output [4:0]   io_miss_req_bits_cmd,
  output [47:0]  io_miss_req_bits_addr,
  output [49:0]  io_miss_req_bits_vaddr,
  output [1:0]   io_miss_req_bits_req_coh_state,
  output         io_miss_req_bits_isBtoT,
  output [3:0]   io_miss_req_bits_occupy_way,
  output         io_miss_req_bits_cancel,
  input  [3:0]   io_miss_resp_id,
  input          io_miss_resp_handled,
  input          io_miss_resp_merged,
  output         io_wbq_conflict_check_valid,
  output [47:0]  io_wbq_conflict_check_bits,
  input          io_wbq_block_miss_req,
  output         io_replace_access_valid,
  output [7:0]   io_replace_access_bits_set,
  output [1:0]   io_replace_access_bits_way,
  output [7:0]   io_occupy_set,
  input          io_occupy_fail,
  input          io_disable_ld_fast_wakeup,
  output         io_error_valid,
  output [47:0]  io_error_bits_paddr,
  output         io_error_bits_report_to_beu,
  input          io_pseudo_error_valid,
  input          io_pseudo_error_bits_0_valid,
  input  [63:0]  io_pseudo_error_bits_0_mask,
  output         io_pseudo_tag_error_inj_done,
  output         io_pseudo_data_error_inj_done,
  output         io_prefetch_info_naive_total_prefetch,
  output         io_prefetch_info_naive_late_hit_prefetch,
  output         io_prefetch_info_naive_late_prefetch_hit,
  output         io_prefetch_info_naive_late_load_hit,
  output         io_prefetch_info_naive_useful_prefetch,
  output         io_prefetch_info_naive_prefetch_hit,
  output         io_prefetch_info_fdp_useful_prefetch,
  output         io_prefetch_info_fdp_demand_miss,
  output         io_prefetch_info_fdp_pollution,
  output         io_bloom_filter_query_query_valid,
  output [11:0]  io_bloom_filter_query_query_bits_addr,
  input          io_bloom_filter_query_resp_valid,
  input          io_bloom_filter_query_resp_bits_res,
  output         io_counter_filter_query_req_valid,
  output [7:0]   io_counter_filter_query_req_bits_idx,
  output [1:0]   io_counter_filter_query_req_bits_way,
  input          io_counter_filter_query_resp,
  output         io_counter_filter_enq_valid,
  output [7:0]   io_counter_filter_enq_bits_idx,
  output [1:0]   io_counter_filter_enq_bits_way,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value
);

  // ---- 端口按路打包（4 路一起读出的 meta / 附加 meta / tag）----
  logic [1:0]       meta_coh     [N_WAYS];
  logic             ext_denied   [N_WAYS];
  logic             ext_corrupt  [N_WAYS];
  logic [2:0]       ext_prefetch [N_WAYS];
  logic             ext_access   [N_WAYS];
  logic [ENC_W-1:0] tag_resp     [N_WAYS];
  assign meta_coh     = '{io_meta_resp_0_coh_state, io_meta_resp_1_coh_state,
                          io_meta_resp_2_coh_state, io_meta_resp_3_coh_state};
  assign ext_denied   = '{io_extra_meta_resp_0_error_tl_denied, io_extra_meta_resp_1_error_tl_denied,
                          io_extra_meta_resp_2_error_tl_denied, io_extra_meta_resp_3_error_tl_denied};
  assign ext_corrupt  = '{io_extra_meta_resp_0_error_tl_corrupt, io_extra_meta_resp_1_error_tl_corrupt,
                          io_extra_meta_resp_2_error_tl_corrupt, io_extra_meta_resp_3_error_tl_corrupt};
  assign ext_prefetch = '{io_extra_meta_resp_0_prefetch, io_extra_meta_resp_1_prefetch,
                          io_extra_meta_resp_2_prefetch, io_extra_meta_resp_3_prefetch};
  assign ext_access   = '{io_extra_meta_resp_0_access, io_extra_meta_resp_1_access,
                          io_extra_meta_resp_2_access, io_extra_meta_resp_3_access};
  assign tag_resp     = '{io_tag_resp_0, io_tag_resp_1, io_tag_resp_2, io_tag_resp_3};

  // ===========================================================================
  //  §1 s0：收请求，发 meta / tag 读
  // ===========================================================================
  //  流水永不阻塞，唯一的反压是 tag 阵列的读口（被 MainPipe 占用时）。
  wire s0_valid = io_lsu_req_valid & io_tag_read_ready;   // = s0_fire

  // 128 位 load（向量）按 16B 对齐，要读相邻两个 bank
  wire [49:0] s0_vaddr   = io_load128Req ? {io_lsu_req_bits_vaddr[49:4], 4'h0} : io_lsu_req_bits_vaddr;
  wire [7:0]  s0_bank_oh_64 = 8'h1 << s0_vaddr[5:3];
  // Chisel：(oh64 << 1) | oh64 —— 左移让宽度变成 9 位，Mux 两臂取宽者，所以 s1_bank_oh
  // 是 9 位寄存器；最高位（跨出 8 个 bank 的那一位）没有读者，照 golden 保留。
  wire [8:0]  s0_bank_oh = io_load128Req ? ({s0_bank_oh_64, 1'b0} | {1'b0, s0_bank_oh_64})
                                         : {1'b0, s0_bank_oh_64};

  assign io_lsu_req_ready      = io_tag_read_ready;
  assign io_meta_read_valid    = s0_valid;
  assign io_meta_read_bits_idx = io_lsu_req_bits_vaddr[13:6];   // 用原始 vaddr（与 s0_vaddr 同位）
  assign io_tag_read_valid     = s0_valid;
  assign io_tag_read_bits_idx  = io_lsu_req_bits_vaddr[13:6];

  // ===========================================================================
  //  §2 s1：tag 比较、权限判定、发数据读
  // ===========================================================================
  logic        s1_valid;
  logic [4:0]  s1_req_cmd;
  logic [49:0] s1_req_vaddr;
  logic [49:0] s1_req_vaddr_dup;
  logic [3:0]  s1_req_instrtype;
  logic        s1_req_isFirstIssue;
  logic        s1_req_lqIdx_flag;
  logic [6:0]  s1_req_lqIdx_value;
  logic        s1_load128Req;
  logic [8:0]  s1_bank_oh;

  always_ff @(posedge clock) begin
    if (s0_valid) begin
      s1_req_cmd          <= io_lsu_req_bits_cmd;
      s1_req_vaddr        <= s0_vaddr;
      s1_req_vaddr_dup    <= io_lsu_req_bits_vaddr_dup;
      s1_req_instrtype    <= io_lsu_req_bits_instrtype;
      s1_req_isFirstIssue <= io_lsu_req_bits_isFirstIssue;
      s1_req_lqIdx_flag   <= io_lsu_req_bits_lqIdx_flag;
      s1_req_lqIdx_value  <= io_lsu_req_bits_lqIdx_value;
      s1_load128Req       <= io_load128Req;
      s1_bank_oh          <= s0_bank_oh;
    end
  end

  // 块内偏移用 paddr 的（vaddr 与 paddr 低 12 位相同，这里取 paddr 只是时序上更早可用）
  wire [5:0] s1_offset     = s1_load128Req ? {io_lsu_s1_paddr_dup_lsu[5:4], 4'h0}
                                           : io_lsu_s1_paddr_dup_lsu[5:0];
  wire [5:0] s1_offset_dup = s1_load128Req ? {io_lsu_s1_paddr_dup_dcache[5:4], 4'h0}
                                           : io_lsu_s1_paddr_dup_dcache[5:0];
  wire [49:0] s1_vaddr     = {s1_req_vaddr[49:6], s1_offset};
  wire        s1_is_prefetch = s1_req_instrtype == DCACHE_PREFETCH_SOURCE;

  // CtrlUnit 的 tag 伪错误：翻转掩码直接异或进读出的 tag（ECC 位不动 → ECC 必报错）
  wire [TAG_W-1:0] pseudo_tag_toggle_mask =
    (io_pseudo_error_valid & io_pseudo_error_bits_0_valid) ? io_pseudo_error_bits_0_mask[TAG_W-1:0] : '0;

  logic [ENC_W-1:0]  s1_enctag   [N_WAYS];   // 注入伪错误后的 {ecc, tag}
  logic [N_WAYS-1:0] s1_way_valid;           // 该路 coh != Nothing
  logic [N_WAYS-1:0] s1_tag_match_way_dup_dc;  // 用 _dup_dcache 那份 paddr 比出的命中路
  logic [N_WAYS-1:0] s1_tag_match_way_dup_lsu; // 用 _dup_lsu 那份 paddr 比出的命中路（只用于 BtoT 判定）
  logic [N_WAYS-1:0] s1_tag_errors;
  always_comb
    for (int w = 0; w < N_WAYS; w++) begin
      s1_enctag[w]                = {tag_resp[w][ENC_W-1:TAG_W], tag_resp[w][TAG_W-1:0] ^ pseudo_tag_toggle_mask};
      s1_way_valid[w]             = meta_coh[w] != COH_NOTHING;
      s1_tag_match_way_dup_dc[w]  = s1_enctag[w][TAG_W-1:0] == io_lsu_s1_paddr_dup_dcache[47:12] & s1_way_valid[w];
      s1_tag_match_way_dup_lsu[w] = s1_enctag[w][TAG_W-1:0] == io_lsu_s1_paddr_dup_lsu[47:12] & s1_way_valid[w];
      s1_tag_errors[w]            = s1_way_valid[w] & tag_ecc_error(s1_enctag[w]);
    end
  wire s1_tag_match_dup_dc  = |s1_tag_match_way_dup_dc;
  wire s1_tag_match_dup_lsu = |s1_tag_match_way_dup_lsu;

  // 命中路的 meta / 附加 meta（ParallelMux = 按独热路按位或）
  logic [1:0] s1_hit_coh;
  logic       s1_hit_denied, s1_hit_corrupt, s1_hit_access;
  logic [2:0] s1_hit_prefetch;
  always_comb begin
    s1_hit_coh      = '0;
    s1_hit_denied   = 1'b0;
    s1_hit_corrupt  = 1'b0;
    s1_hit_prefetch = '0;
    s1_hit_access   = 1'b0;
    for (int w = 0; w < N_WAYS; w++)
      if (s1_tag_match_way_dup_dc[w]) begin
        s1_hit_coh      |= meta_coh[w];
        s1_hit_denied   |= ext_denied[w];
        s1_hit_corrupt  |= ext_corrupt[w];
        s1_hit_prefetch |= ext_prefetch[w];
        s1_hit_access   |= ext_access[w];
      end
  end

  // 权限：ClientMetadata.onAccess(cmd) = growStarter
  grow_t s1_grow;
  assign s1_grow = grow_starter(cmd_category(s1_req_cmd), s1_hit_coh);
  wire        s1_has_permission = s1_grow.hit;
  wire [1:0]  s1_new_hit_coh    = s1_grow.next;   // 缺失时同时就是 shrink_perm（Grow 参数）
  wire        s1_hit = s1_tag_match_dup_dc & s1_has_permission & (s1_hit_coh == s1_new_hit_coh);
  wire        s1_will_send_miss_req = s1_valid & ~s1_hit;

  // 数据阵列读：预取请求不读数据；LoadUnit 可在 s1 叫停（s1_kill_data_read）
  wire s1_data_read_valid = s1_valid & ~s1_is_prefetch & ~io_lsu_s1_kill_data_read;
  assign io_banked_data_read_valid            = s1_data_read_valid;
  assign io_banked_data_read_bits_way_en      = s1_tag_match_way_dup_dc;
  assign io_banked_data_read_bits_addr        = s1_vaddr[47:0];
  assign io_banked_data_read_bits_addr_dup    = {s1_req_vaddr_dup[47:6], s1_offset_dup};
  assign io_banked_data_read_bits_bankMask    = s1_bank_oh[7:0];
  assign io_banked_data_read_bits_lqIdx_flag  = s1_req_lqIdx_flag;
  assign io_banked_data_read_bits_lqIdx_value = s1_req_lqIdx_value;
  assign io_is128Req                          = s1_load128Req;

  // BloomFilter 查询：paddr 的 set 下标折叠哈希（[17:6] ^ [29:18]）
  assign io_bloom_filter_query_query_valid     = s1_valid;
  assign io_bloom_filter_query_query_bits_addr = io_lsu_s1_paddr_dup_dcache[17:6] ^ io_lsu_s1_paddr_dup_dcache[29:18];

  // tag 伪错误"已注入"：s1 读到了至少一个有效路（翻转掩码就作用上去了）
  assign io_pseudo_tag_error_inj_done = s1_valid & (|s1_way_valid);

  // ===========================================================================
  //  §3 s2：回 LoadUnit、发 miss 请求
  // ===========================================================================
  logic        s2_valid;
  logic        s2_valid_dup;        // s2_valid 的复制（只驱动 miss 相关路径，为扇出）
  logic [4:0]  s2_req_cmd;
  logic [3:0]  s2_req_instrtype;
  logic        s2_req_isFirstIssue;
  logic        s2_load128Req;
  logic [47:0] s2_paddr;
  logic [49:0] s2_vaddr;
  logic [3:0]  s2_real_way_en;
  logic [3:0]  s2_tag_errors;
  logic [3:0]  s2_tag_match_way;
  logic        s2_tag_match;
  logic [1:0]  s2_hit_coh_state;
  logic        s2_has_permission;
  logic [1:0]  s2_new_hit_coh_state;
  logic        s2_grow_perm_btot;   // 缺失原因是"有 Branch 副本、要升 Trunk"
  logic        s2_can_send_miss_req;
  logic        s2_can_send_miss_req_dup;
  logic        s2_nack_data;        // s1 时数据阵列读口没空（被 MainPipe 写占）
  logic        s2_tl_error_tl_denied;
  logic        s2_tl_error_tl_corrupt;
  logic [2:0]  s2_hit_prefetch;
  logic        s2_hit_access;
  logic [2:0]  io_miss_req_bits_pf_source_REG;
  logic [2:0]  io_miss_req_bits_pf_source_REG_1;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid     <= 1'b0;
      s2_valid     <= 1'b0;
      s2_valid_dup <= 1'b0;
    end
    else begin
      s1_valid <= s0_valid;
      s2_valid <= s1_valid & ~io_lsu_s1_kill;
      // Chisel：when(s1_fire) := !s1_kill .elsewhen(resp.fire) := false，resp.fire = s2_valid
      if (s1_valid) s2_valid_dup <= ~io_lsu_s1_kill;
      else          s2_valid_dup <= s2_valid_dup & ~s2_valid;
    end
  end

  always_ff @(posedge clock) begin
    if (s1_valid) begin
      s2_req_cmd               <= s1_req_cmd;
      s2_req_instrtype         <= s1_req_instrtype;
      s2_req_isFirstIssue      <= s1_req_isFirstIssue;
      s2_load128Req            <= s1_load128Req;
      s2_paddr                 <= io_lsu_s1_paddr_dup_dcache;
      s2_vaddr                 <= s1_vaddr;
      s2_real_way_en           <= s1_tag_match_way_dup_dc;
      s2_tag_errors            <= s1_tag_errors;
      s2_tag_match_way         <= s1_tag_match_way_dup_dc;
      s2_tag_match             <= s1_tag_match_dup_dc;
      s2_hit_coh_state         <= s1_hit_coh;
      s2_has_permission        <= s1_has_permission;
      s2_new_hit_coh_state     <= s1_new_hit_coh;
      s2_grow_perm_btot        <= (s1_new_hit_coh == BTOT) & ~s1_has_permission & s1_tag_match_dup_lsu;
      s2_can_send_miss_req     <= s1_will_send_miss_req;
      s2_can_send_miss_req_dup <= s1_will_send_miss_req;
      s2_nack_data             <= ~io_banked_data_read_ready;
      // 总线错误标记只认命中路的（缺失 = 要替换，没有旧错误可报）
      s2_tl_error_tl_denied    <= s1_tag_match_dup_dc & s1_hit_denied;
      s2_tl_error_tl_corrupt   <= s1_tag_match_dup_dc & s1_hit_corrupt;
      s2_hit_prefetch          <= s1_hit_prefetch;
      s2_hit_access            <= s1_hit_access;
    end
    io_miss_req_bits_pf_source_REG   <= io_lsu_pf_source;
    io_miss_req_bits_pf_source_REG_1 <= io_miss_req_bits_pf_source_REG;
  end

  wire s2_real_miss   = ~(|s2_real_way_en);
  wire s2_hit         = s2_tag_match & s2_has_permission & (s2_hit_coh_state == s2_new_hit_coh_state);
  wire s2_is_prefetch = s2_req_instrtype == DCACHE_PREFETCH_SOURCE;
  wire s2_tag_error   = |s2_tag_errors;
  wire s2_btot_occupy_fail = io_occupy_fail & s2_grow_perm_btot;   // 升权要占的路被别人占了

  // miss 请求与各种 nack
  wire s2_miss_req_valid_dup = s2_valid_dup & s2_can_send_miss_req_dup;
  wire s2_miss_req_fire      = s2_miss_req_valid_dup & io_miss_req_ready;
  wire s2_nack_no_mshr       = s2_miss_req_valid_dup & ~io_miss_req_ready;
  wire s2_nack_wbq_conflict  = s2_miss_req_valid_dup & io_wbq_block_miss_req;
  wire s2_nack               = s2_nack_no_mshr | s2_nack_data | s2_nack_wbq_conflict;
  wire s2_miss_cancel        = io_lsu_s2_kill | s2_tag_error | s2_btot_occupy_fail;

  assign io_miss_req_valid              = s2_valid & s2_can_send_miss_req;
  assign io_miss_req_bits_source        = s2_req_instrtype;
  assign io_miss_req_bits_pf_source     = io_miss_req_bits_pf_source_REG_1;
  assign io_miss_req_bits_cmd           = s2_req_cmd;
  assign io_miss_req_bits_addr          = {s2_paddr[47:6], 6'h0};
  assign io_miss_req_bits_vaddr         = s2_vaddr;
  assign io_miss_req_bits_req_coh_state = s2_hit_coh_state;
  assign io_miss_req_bits_isBtoT        = s2_grow_perm_btot;
  assign io_miss_req_bits_occupy_way    = s2_tag_match_way;
  assign io_miss_req_bits_cancel        = s2_miss_cancel;

  assign io_wbq_conflict_check_valid = s2_miss_req_valid_dup;
  assign io_wbq_conflict_check_bits  = {s2_paddr[47:6], 6'h0};
  assign io_occupy_set               = s2_vaddr[13:6];

  // 回 LoadUnit
  wire resp_replay  = (s2_real_miss & (s2_nack | s2_miss_cancel)) | io_bank_conflict_slow | s2_btot_occupy_fail;
  wire resp_handled = s2_miss_req_fire & ~s2_miss_cancel & ~io_wbq_block_miss_req & io_miss_resp_handled;
  wire [127:0] s2_data128bit = {io_banked_data_resp_1_raw_data, io_banked_data_resp_0_raw_data};

  assign io_lsu_resp_valid              = s2_valid;
  assign io_lsu_resp_bits_data          = s2_data128bit;
  assign io_lsu_resp_bits_miss          = s2_real_miss;
  assign io_lsu_resp_bits_mshr_id       = io_miss_resp_id;
  assign io_lsu_resp_bits_meta_prefetch = s2_hit_prefetch;
  assign io_lsu_resp_bits_handled       = resp_handled;
  assign io_lsu_s2_bank_conflict        = io_bank_conflict_slow;
  assign io_lsu_s2_mq_nack =
    (s2_real_miss & (s2_nack_no_mshr | s2_miss_cancel | io_wbq_block_miss_req)) | s2_btot_occupy_fail;

  // data 伪错误"已注入"：s2 命中且没被 bank 冲突打回（数据真的从阵列读出来了）
  assign io_pseudo_data_error_inj_done = s2_valid & s2_hit & ~io_bank_conflict_slow;

  // 预取统计（naive：只看 s2 这一拍的事件）
  wire s2_pf_valid = s2_valid & s2_is_prefetch;
  assign io_prefetch_info_naive_total_prefetch    = s2_pf_valid;
  assign io_prefetch_info_naive_late_hit_prefetch = s2_pf_valid & s2_hit;
  assign io_prefetch_info_naive_late_prefetch_hit = s2_pf_valid & s2_hit &  is_from_l1_prefetch(s2_hit_prefetch);
  assign io_prefetch_info_naive_late_load_hit     = s2_pf_valid & s2_hit & ~is_from_l1_prefetch(s2_hit_prefetch);
  assign io_prefetch_info_naive_useful_prefetch   = s2_pf_valid & resp_handled & ~io_miss_resp_merged;
  // FDP：首发 demand load 缺失 / 缺失且 BloomFilter 说这行是被预取挤掉的（污染）
  wire s2_demand_miss = s2_valid & ~s2_is_prefetch & ~s2_hit & s2_req_isFirstIssue;
  assign io_prefetch_info_fdp_demand_miss = s2_demand_miss;
  assign io_prefetch_info_fdp_pollution   = s2_demand_miss & io_bloom_filter_query_resp_valid &
                                            io_bloom_filter_query_resp_bits_res;

  // ===========================================================================
  //  §4 s3：延迟结果、错误上报、元数据回写
  // ===========================================================================
  logic         s3_valid;
  logic         s3_load128Req;
  logic [49:0]  s3_vaddr;
  logic [47:0]  s3_paddr;
  logic         s3_hit;
  logic [3:0]   s3_tag_match_way;
  logic [3:0]   s3_req_instrtype;
  logic [127:0] s3_banked_data_resp_word;
  logic         s3_tag_error;
  logic         s3_tl_error_tl_denied;
  logic         s3_tl_error_tl_corrupt;
  logic [2:0]   s3_hit_prefetch;
  logic [7:0]   io_replace_access_bits_set_REG;
  logic [7:0]   io_replace_access_bits_set_REG_1;
  logic [1:0]   io_replace_access_bits_way_REG;
  logic [1:0]   io_replace_access_bits_way_REG_1;

  always_ff @(posedge clock) begin
    s3_valid <= s2_valid;
    if (s2_valid) begin
      s3_load128Req            <= s2_load128Req;
      s3_vaddr                 <= s2_vaddr;
      s3_paddr                 <= s2_paddr;
      s3_hit                   <= s2_hit;
      s3_tag_match_way         <= s2_tag_match_way;
      s3_req_instrtype         <= s2_req_instrtype;
      s3_banked_data_resp_word <= s2_data128bit;
      s3_tag_error             <= s2_tag_error;
      s3_tl_error_tl_denied    <= s2_tl_error_tl_denied;
      s3_tl_error_tl_corrupt   <= s2_tl_error_tl_corrupt;
      s3_hit_prefetch          <= s2_hit_prefetch;
    end
    // 替换算法访问：set / way 直接从 s1 打两拍（不看 valid）
    io_replace_access_bits_set_REG   <= s1_req_vaddr[13:6];
    io_replace_access_bits_set_REG_1 <= io_replace_access_bits_set_REG;
    io_replace_access_bits_way_REG   <= oh_to_way(s1_tag_match_way_dup_dc);
    io_replace_access_bits_way_REG_1 <= io_replace_access_bits_way_REG;
  end

  // 数据 ECC 错误（阵列延迟一拍报）：128 位 load 看两个 bank，否则只看第 0 个；只在命中时算数
  wire s3_data_error = (s3_load128Req ? (io_read_error_delayed_1 | io_read_error_delayed_0)
                                      : io_read_error_delayed_0) & s3_hit;
  wire s3_flag_error = s3_tl_error_tl_denied | s3_tl_error_tl_corrupt;   // L2 带回来的总线错误标记
  wire s3_is_prefetch = s3_req_instrtype == DCACHE_PREFETCH_SOURCE;
  wire s3_hit_valid   = s3_valid & s3_hit;

  assign io_lsu_resp_bits_data_delayed                = s3_banked_data_resp_word;
  assign io_lsu_resp_bits_tl_error_delayed_tl_denied  = s3_tl_error_tl_denied & s3_valid;
  assign io_lsu_resp_bits_tl_error_delayed_tl_corrupt = s3_tl_error_tl_corrupt & s3_valid;

  assign io_error_valid              = (s3_tag_error | s3_flag_error | s3_data_error) & s3_valid;
  assign io_error_bits_paddr         = s3_paddr;
  assign io_error_bits_report_to_beu = (s3_tag_error | s3_data_error) & s3_valid;

  assign io_replace_access_valid    = s3_hit_valid;
  assign io_replace_access_bits_set = io_replace_access_bits_set_REG_1;
  assign io_replace_access_bits_way = io_replace_access_bits_way_REG_1;

  // access 标记：demand load 命中 → 置"被访问过"
  assign io_access_flag_write_valid       = s3_hit_valid & ~s3_is_prefetch;
  assign io_access_flag_write_bits_idx    = s3_vaddr[13:6];
  assign io_access_flag_write_bits_way_en = s3_tag_match_way;

  // demand load 命中一条 L1 预取进来的行：清预取标记、计一次"有用预取"——
  // 先问 CounterFilter，同一 (set, way) 最近已经算过就不再算（见 CounterFilter.sv）
  wire s3_clear_pf_flag_en = s3_hit_valid & ~s3_is_prefetch & is_from_l1_prefetch(s3_hit_prefetch);
  wire s3_pf_hit_counted   = s3_clear_pf_flag_en & ~io_counter_filter_query_resp;

  assign io_prefetch_flag_write_valid       = s3_pf_hit_counted;
  assign io_prefetch_flag_write_bits_idx    = s3_vaddr[13:6];
  assign io_prefetch_flag_write_bits_way_en = s3_tag_match_way;

  assign io_counter_filter_query_req_valid    = s3_clear_pf_flag_en;
  assign io_counter_filter_query_req_bits_idx = s3_vaddr[13:6];
  assign io_counter_filter_query_req_bits_way = oh_to_way(s3_tag_match_way);
  assign io_counter_filter_enq_valid          = s3_pf_hit_counted;
  assign io_counter_filter_enq_bits_idx       = s3_vaddr[13:6];
  assign io_counter_filter_enq_bits_way       = oh_to_way(s3_tag_match_way);

  assign io_prefetch_info_naive_prefetch_hit  = s3_pf_hit_counted;
  assign io_prefetch_info_fdp_useful_prefetch = s3_pf_hit_counted;

  // ===========================================================================
  //  §5 性能事件：每个事件打两拍后输出（HasPerfEvents），值宽 6 位、只有最低位有效
  // ===========================================================================
  //   0 load_req  1 load_replay  2 replay_for_data_nack  3 replay_for_no_mshr
  //   4 replay_for_conflict  5 l1D_read_dcache_access  6 l1D_read_dcache_miss
  logic [6:0] perf_event;
  assign perf_event[0] = s0_valid;
  assign perf_event[1] = s2_valid & resp_replay;
  assign perf_event[2] = s2_valid & resp_replay & s2_nack_data;
  assign perf_event[3] = s2_valid & resp_replay & s2_nack_no_mshr;
  assign perf_event[4] = s2_valid & resp_replay & io_bank_conflict_slow;
  assign perf_event[5] = s2_valid & ~s2_is_prefetch;
  assign perf_event[6] = s2_valid & ~s2_is_prefetch & s2_real_miss;
  logic io_perf_0_value_REG, io_perf_0_value_REG_1;
  logic io_perf_1_value_REG, io_perf_1_value_REG_1;
  logic io_perf_2_value_REG, io_perf_2_value_REG_1;
  logic io_perf_3_value_REG, io_perf_3_value_REG_1;
  logic io_perf_4_value_REG, io_perf_4_value_REG_1;
  logic io_perf_5_value_REG, io_perf_5_value_REG_1;
  logic io_perf_6_value_REG, io_perf_6_value_REG_1;
  always_ff @(posedge clock) begin
    io_perf_0_value_REG   <= perf_event[0];
    io_perf_0_value_REG_1 <= io_perf_0_value_REG;
    io_perf_1_value_REG   <= perf_event[1];
    io_perf_1_value_REG_1 <= io_perf_1_value_REG;
    io_perf_2_value_REG   <= perf_event[2];
    io_perf_2_value_REG_1 <= io_perf_2_value_REG;
    io_perf_3_value_REG   <= perf_event[3];
    io_perf_3_value_REG_1 <= io_perf_3_value_REG;
    io_perf_4_value_REG   <= perf_event[4];
    io_perf_4_value_REG_1 <= io_perf_4_value_REG;
    io_perf_5_value_REG   <= perf_event[5];
    io_perf_5_value_REG_1 <= io_perf_5_value_REG;
    io_perf_6_value_REG   <= perf_event[6];
    io_perf_6_value_REG_1 <= io_perf_6_value_REG;
  end
  assign io_perf_0_value = {5'h0, io_perf_0_value_REG_1};
  assign io_perf_1_value = {5'h0, io_perf_1_value_REG_1};
  assign io_perf_2_value = {5'h0, io_perf_2_value_REG_1};
  assign io_perf_3_value = {5'h0, io_perf_3_value_REG_1};
  assign io_perf_4_value = {5'h0, io_perf_4_value_REG_1};
  assign io_perf_5_value = {5'h0, io_perf_5_value_REG_1};
  assign io_perf_6_value = {5'h0, io_perf_6_value_REG_1};

  // ===========================================================================
  //  §6 仿真检查寄存器（golden 同样保留；综合口径下没有读者）
  // ===========================================================================
  //  名字沿用 golden 的 REG_1 / REG_2 / REG_4（Chisel 给 assert(RegNext(..)) 自动起的名）：
  //  这三个寄存器两侧都没有读者，FM 不给无扇出的点做签名配对，只能靠同名配上
  //  （见 verif/fm_target_config/LoadPipe.tcl）。
  logic REG_1;   // RegNext(!(s0_valid && cmd ∉ {XRD, PFR, PFW}))：LoadPipe 只收 load/软件预取
  logic REG_2;   // RegNext(!s1_valid || PopCount(命中路) <= 1)：tag 不应多路命中
  logic REG_4;   // RegNext(s1_ready && s2_ready)：流水永不阻塞，本配置恒 1
  wire [2:0] s1_hit_way_count = 3'(s1_tag_match_way_dup_dc[0]) + 3'(s1_tag_match_way_dup_dc[1]) +
                                3'(s1_tag_match_way_dup_dc[2]) + 3'(s1_tag_match_way_dup_dc[3]);
  always_ff @(posedge clock) begin
    REG_1 <= ~(s0_valid & io_lsu_req_bits_cmd != M_XRD & io_lsu_req_bits_cmd != M_PFR &
               io_lsu_req_bits_cmd != M_PFW);
    REG_2 <= ~s1_valid | (s1_hit_way_count < 3'd2);
    REG_4 <= 1'b1;
  end
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset && !REG_1)
      $error("LoadPipe only accepts load req / softprefetch read or write!");
    if (!reset && !REG_2)
      $error("tag should not match with more than 1 way");
  end
`endif

endmodule
