// =============================================================================
// MissQueue —— DCache 的 miss 队列（16 个 MSHR + CMO 单元 + 入队流水寄存器 + 通道仲裁）
//
// 位置：L1 DCache 内部。load（LoadPipe）/ store 与 AMO（MainPipe）miss 后都送到这里：
//   s0  入队判定：新请求与 16 个 MSHR、流水寄存器逐个比，决定"分配新表项 / 合并进已有表项 / 拒绝"，
//       同拍回 resp（id / handled / merged）；4 条 LoadPipe 还可以提前查询"会不会被接收"（queryMQ）；
//   s1  流水寄存器 miss_req_pipe_reg：请求在这里停一拍，再真正写进被选中的 MSHR；
//       分配时流水寄存器**自己先发 Acquire**（不等表项），表项只负责之后的事；
//   通道：A 通道 18 路仲裁（CMO > 流水寄存器 > MSHR 0..15），E 通道 16 路（GrantAck），
//       D 通道按 source 分发给表项，CBOAck 给 CMOUnit；
//   回填：16 个表项的 MainPipe 请求经 Arbiter16_MainPipeReq 并成一路；
//   其它：给 LoadPipe 的 MSHR 数据前递、probe/replace 阻挡、BtoT 占路、预取迟到统计、WFI、性能事件、difftest。
//   Scala：xiangshan/cache/dcache/mainpipe/MissQueue.scala class MissQueue（及 MissReqPipeRegBundle）。
//
// 本配置（KunminghuV2）下 golden 与 Scala 的差别（照 golden 端口表写）：
//   · io.full / io.memSetPattenDetected / io.refill_to_ldq 没有端口（父级不读，DCE）；
//     refill_to_ldq 只剩 difftest 用到的 addr / data_raw / hasdata / refill_done，经 gatewayIn 端口送出；
//   · A 通道 mask/size 由各路常量拼出（CMO 的 mask/param/user 是 DontCare=0）；
//   · 性能计数 max_inflight 与断言打拍寄存器在 golden 里仍是真寄存器（无读者），§10 照留。
//
// 文件结构：missqueue_pkg → xs_MissQueue_core（手写，所有"胶水"逻辑）→ golden 同名 wrapper
//   （例化 16 个 MissEntry / CMOUnit / Arbiter16_MainPipeReq 与核，实例名与 golden 相同；
//   端口表与全部连线由 scripts/gen_missq.py 从 golden 端口表生成）。
// =============================================================================
// 本文件导航：
//   missqueue_pkg        常量、结构体、命令/来源分类、流水寄存器的合并/拒绝判定、grow 表
//   xs_MissQueue_core    §1 s0 入队判定  §2 resp 与流水寄存器  §3 memset 模式检测  §4 MSHR 数据前递
//                        §5 D 通道 / L2 hint / MainPipe 回应分发  §6 A 通道  §7 E 通道
//                        §8 refill_info / 阻挡 / BtoT 占路  §9 预取统计、WFI、性能事件、difftest
//                        §10 只为断言/性能计数而存在的寄存器
//   MissQueue            golden 同名 wrapper（GENERATED）

package missqueue_pkg;

  localparam int unsigned N_ENTRIES = 16;   // MSHR 个数（cfg.nMissEntries）
  localparam int unsigned N_QUERY   = 4;    // LoadPipe 提前查询口
  localparam int unsigned N_LDU     = 3;    // 数据前递口 / 占路检查口（LoadPipelineWidth）
  localparam int unsigned N_ACQ_SRC = N_ENTRIES + 2;   // A 通道：CMO + 流水寄存器 + 16 MSHR

  // 请求来源
  localparam logic [3:0] LOAD_SOURCE            = 4'd0;
  localparam logic [3:0] STORE_SOURCE           = 4'd1;
  localparam logic [3:0] AMO_SOURCE             = 4'd2;
  localparam logic [3:0] DCACHE_PREFETCH_SOURCE = 4'd3;

  // 内存命令（rocket-chip MemoryOpConstants）
  localparam logic [4:0] M_XWR     = 5'h01;
  localparam logic [4:0] M_PFR     = 5'h02;
  localparam logic [4:0] M_PFW     = 5'h03;
  localparam logic [4:0] M_XA_SWAP = 5'h04;
  localparam logic [4:0] M_XLR     = 5'h06;
  localparam logic [4:0] M_XSC     = 5'h07;
  localparam logic [4:0] M_XA_ADD  = 5'h08;
  localparam logic [4:0] M_XA_XOR  = 5'h09;
  localparam logic [4:0] M_XA_OR   = 5'h0A;
  localparam logic [4:0] M_XA_AND  = 5'h0B;
  localparam logic [4:0] M_XA_MIN  = 5'h0C;
  localparam logic [4:0] M_XA_MAX  = 5'h0D;
  localparam logic [4:0] M_XA_MINU = 5'h0E;
  localparam logic [4:0] M_XA_MAXU = 5'h0F;
  localparam logic [4:0] M_PWR     = 5'h11;
  localparam logic [4:0] M_XA_CASQ = 5'h18;
  localparam logic [4:0] M_XA_CASW = 5'h1A;
  localparam logic [4:0] M_XA_CASD = 5'h1B;

  localparam logic [1:0] ST_NOTHING = 2'd0;
  localparam logic [1:0] ST_BRANCH  = 2'd1;
  localparam logic [1:0] ST_TRUNK   = 2'd2;
  localparam logic [1:0] ST_DIRTY   = 2'd3;
  localparam logic [1:0] GROW_NTOB  = 2'd0;
  localparam logic [1:0] GROW_NTOT  = 2'd1;
  localparam logic [1:0] GROW_BTOT  = 2'd2;

  // TileLink
  localparam logic [3:0] TL_ACQUIRE_BLOCK = 4'd6;
  localparam logic [3:0] TL_ACQUIRE_PERM  = 4'd7;
  localparam logic [3:0] TL_CBO_ACK       = 4'd8;   // D 通道：L2 对 CBO 的回应
  localparam logic [2:0] TL_LINE_LGSIZE   = 3'd6;   // 64B 一行
  localparam logic [5:0] CMO_SOURCE_ID    = 6'(N_ENTRIES + 1);   // CMOUnit 的 A 通道 source = 17
  localparam logic [4:0] REQ_SRC_CPU_LOAD_DATA    = 5'd2;
  localparam logic [4:0] REQ_SRC_CPU_STORE_DATA   = 5'd3;
  localparam logic [4:0] REQ_SRC_CPU_ATOMIC_DATA  = 5'd4;
  localparam logic [4:0] REQ_SRC_L1_DATA_PREFETCH = 5'd6;

  // ---- 结构体 ----
  // MissReq（本配置 golden 端口上保留的字段；cancel 单独走）
  typedef struct packed {
    logic [3:0]   source;
    logic [2:0]   pf_source;
    logic [4:0]   cmd;
    logic [47:0]  addr;
    logic [49:0]  vaddr;
    logic         full_overwrite;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [1:0]   req_coh_state;
    logic [5:0]   id;
    logic         isBtoT;
    logic [3:0]   occupy_way;
    logic [511:0] store_data;
    logic [63:0]  store_mask;
  } miss_req_t;

  typedef struct packed {
    logic [3:0]  source;
    logic [47:0] addr;
    logic [49:0] vaddr;
  } query_req_t;

  // A 通道（MissQueue 出口上保留的字段）
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [2:0]  size;
    logic [5:0]  source;
    logic [47:0] address;
    logic [1:0]  user_alias;
    logic [43:0] user_vaddr;
    logic [4:0]  user_reqSource;
    logic        user_needHint;
    logic        echo_isKeyword;
    logic [31:0] mask;
  } tl_a_t;

  // MSHR 送来的 A 通道字段（size/mask 是常量，不在 MSHR 端口上）
  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [5:0]  source;
    logic [47:0] address;
    logic [1:0]  user_alias;
    logic [43:0] user_vaddr;
    logic [4:0]  user_reqSource;
    logic        user_needHint;
    logic        echo_isKeyword;
  } ent_acq_t;

  typedef struct packed {
    logic [3:0]   opcode;
    logic [1:0]   param;
    logic [2:0]   size;
    logic [5:0]   source;
    logic [9:0]   sink;
    logic         denied;
    logic [255:0] data;
    logic         corrupt;
  } tl_d_t;

  // MainPipe s2/s3 送回的信息
  typedef struct packed {
    logic       s2_valid;
    logic [3:0] s2_miss_id;
    logic       s2_replay_to_mq;
    logic       s2_evict_BtoT_way;
    logic [3:0] s2_next_evict_way;
    logic       s3_valid;
    logic [3:0] s3_miss_id;
    logic       s3_refill_resp;
  } mp_info_t;

  typedef struct packed {
    logic [511:0] store_data;
    logic [1:0]   miss_param;
    logic         tl_denied;
    logic         tl_corrupt;
  } ent_refill_info_t;

  // MSHR 的前递信息（MissEntryForwardIO）
  typedef struct packed {
    logic                  inflight;
    logic [47:0]           paddr;
    logic [7:0][63:0]      raw_data;
    logic                  firstbeat_valid;
    logic                  lastbeat_valid;
    logic                  denied;
    logic                  corrupt;
  } ent_fwd_t;

  // ---- 纯函数 ----
  function automatic logic is_from_prefetch(input logic [3:0] source);
    return source >= DCACHE_PREFETCH_SOURCE;
  endfunction

  function automatic logic same_block(input logic [47:0] a, input logic [47:0] b);
    return a[47:6] == b[47:6];
  endfunction

  function automatic logic alias_match(input logic [49:0] va, input logic [49:0] vb);
    return va[13:12] == vb[13:12];
  endfunction

  // MissReqPipeRegBundle 的合并规则：流水寄存器里正在分配的请求能不能把新请求吸收进来
  //   load 可以合并进 load/store/预取；store 可以合并进 load/预取（store 合并 store 被禁止：
  //   sbuffer 保证同地址 store 保序）；AMO 不合并。
  function automatic logic pipe_can_merge_kind(input logic [3:0] old_src, input logic [3:0] new_src);
    logic old_ld_st_pf = old_src == LOAD_SOURCE || old_src == STORE_SOURCE || is_from_prefetch(old_src);
    logic old_ld_pf    = old_src == LOAD_SOURCE || is_from_prefetch(old_src);
    return (old_ld_st_pf && new_src == LOAD_SOURCE) || (old_ld_pf && new_src == STORE_SOURCE);
  endfunction

  // merge_req：流水寄存器正在分配（alloc），同一行、alias 相同、种类可合并
  function automatic logic pipe_merge_req(input logic alloc, input miss_req_t p,
                                          input logic [3:0] src, input logic [47:0] addr,
                                          input logic [49:0] vaddr);
    return alloc & same_block(p.addr, addr) & alias_match(p.vaddr, vaddr) &
           pipe_can_merge_kind(p.source, src);
  endfunction

  // reject_req：流水寄存器正在分配，同一行，但 alias 不同或种类不可合并
  function automatic logic pipe_reject_req(input logic alloc, input miss_req_t p,
                                           input logic [3:0] src, input logic [47:0] addr,
                                           input logic [49:0] vaddr);
    return alloc & same_block(p.addr, addr) &
           (~alias_match(p.vaddr, vaddr) | ~pipe_can_merge_kind(p.source, src));
  endfunction

  function automatic logic is_amo(input logic [4:0] cmd);
    return cmd == M_XA_SWAP || cmd == M_XA_XOR || cmd == M_XA_OR || cmd == M_XA_AND ||
           cmd == M_XA_ADD || cmd == M_XA_MIN || cmd == M_XA_MAX || cmd == M_XA_MINU ||
           cmd == M_XA_MAXU || cmd == M_XA_CASW || cmd == M_XA_CASD || cmd == M_XA_CASQ;
  endfunction

  function automatic logic is_write(input logic [4:0] cmd);
    return cmd == M_XWR || cmd == M_PWR || cmd == M_XSC || is_amo(cmd);
  endfunction

  function automatic logic is_write_intent(input logic [4:0] cmd);
    return is_write(cmd) || cmd == M_PFW || cmd == M_XLR;
  endfunction

  // ClientMetadata.onAccess(cmd)._2（growStarter 表的第二列，与 MissEntry.sv / MainPipe.sv 同一张表）
  function automatic logic [1:0] acquire_grow_param(input logic [4:0] cmd, input logic [1:0] state);
    logic [1:0] cat;
    cat = {is_write(cmd), is_write_intent(cmd)};
    case ({cat, state})
      {2'b00, ST_NOTHING}: return GROW_NTOB;
      {2'b00, ST_BRANCH}:  return ST_BRANCH;
      {2'b00, ST_TRUNK}:   return ST_TRUNK;
      {2'b00, ST_DIRTY}:   return ST_DIRTY;
      {2'b01, ST_NOTHING}: return GROW_NTOT;
      {2'b01, ST_BRANCH}:  return GROW_BTOT;
      {2'b01, ST_TRUNK}:   return ST_TRUNK;
      {2'b01, ST_DIRTY}:   return ST_DIRTY;
      {2'b11, ST_NOTHING}: return GROW_NTOT;
      {2'b11, ST_BRANCH}:  return GROW_BTOT;
      {2'b11, ST_TRUNK}:   return ST_DIRTY;
      {2'b11, ST_DIRTY}:   return ST_DIRTY;
      default:             return 2'd0;
    endcase
  endfunction

  // OHToUInt：第 b 位 = 所有"下标第 b 位为 1"的输入位之或（输入不是独热时也与 Chisel 一致）
  function automatic logic [3:0] onehot_to_index(input logic [15:0] oh);
    logic [3:0] r;
    r = '0;
    for (int i = 0; i < 16; i++)
      for (int b = 0; b < 4; b++)
        if (i[b]) r[b] = r[b] | oh[i];
    return r;
  endfunction

  function automatic logic [4:0] popcount16(input logic [15:0] v);
    logic [4:0] n;
    n = '0;
    for (int i = 0; i < 16; i++) n = n + 5'(v[i]);
    return n;
  endfunction

endpackage

// =============================================================================
// xs_MissQueue_core —— MissQueue 的全部胶水逻辑（MSHR / CMOUnit / 仲裁器在 wrapper 里例化）
// =============================================================================
module xs_MissQueue_core
  import missqueue_pkg::*;
(
  input  logic                               clock,
  input  logic                               reset,
  input  logic [5:0]                         hartId,
  // ---- 新 miss 请求（s0）与回应 ----
  input  logic                               req_valid,
  input  miss_req_t                          req,
  input  logic                               req_cancel,
  output logic                               req_ready,
  output logic [3:0]                         resp_id,
  output logic                               resp_handled,
  output logic                               resp_merged,
  input  logic                               wbq_block_miss_req,
  // ---- LoadPipe 提前查询 ----
  input  query_req_t [N_QUERY-1:0]           query_req,
  output logic [N_QUERY-1:0]                 query_ready,
  // ---- A / D / E 通道 ----
  input  logic                               acq_ready,
  output logic                               acq_valid,
  output tl_a_t                              acq,
  input  logic                               grant_valid,
  input  tl_d_t                              grant,
  output logic                               grant_ready,
  input  logic                               finish_ready,
  output logic                               finish_valid,
  output logic [9:0]                         finish_sink,
  input  logic                               l2_hint_valid,
  input  logic [3:0]                         l2_hint_source_id,
  // ---- MainPipe ----
  input  logic                               mp_req_out_valid,    // Arbiter16 的输出（只用来数 fire）
  input  logic                               mp_req_out_ready,
  input  logic                               mp_resp_valid,
  input  logic [3:0]                         mp_resp_miss_id,
  input  logic                               mp_resp_ack_miss_queue,
  input  mp_info_t                           mp_info,
  output logic                               refill_info_valid,
  output logic [511:0]                       refill_info_store_data,
  output logic [63:0]                        refill_info_store_mask,
  output logic [1:0]                         refill_info_miss_param,
  output logic                               refill_info_tl_denied,
  output logic                               refill_info_tl_corrupt,
  // ---- 阻挡 / BtoT 占路 ----
  output logic                               probe_block,
  input  logic [47:0]                        replace_addr,
  input  logic [49:0]                        replace_vaddr,
  output logic                               replace_block,
  input  logic [7:0]                         evict_set,
  output logic [3:0]                         btot_ways_for_set,
  input  logic [N_LDU-1:0][7:0]              occupy_set,
  output logic [N_LDU-1:0]                   occupy_fail,
  // ---- MSHR 数据前递（LoadPipe s1 发起，s2 拿结果）----
  input  logic [N_LDU-1:0]                   fwd_valid,
  input  logic [N_LDU-1:0][3:0]              fwd_mshrid,
  input  logic [N_LDU-1:0][47:0]             fwd_paddr,
  output logic [N_LDU-1:0]                   fwd_forward_mshr,
  output logic [N_LDU-1:0][15:0][7:0]        fwd_data,
  output logic [N_LDU-1:0]                   fwd_result_valid,
  output logic [N_LDU-1:0]                   fwd_denied,
  output logic [N_LDU-1:0]                   fwd_corrupt,
  // ---- 配置 / 统计 / 其它 ----
  input  logic                               l2_pf_store_only,
  input  logic                               lqEmpty,
  output logic                               pf_naive_late_miss_prefetch,
  output logic                               pf_fdp_late_miss_prefetch,
  output logic                               pf_fdp_prefetch_monitor_cnt,
  output logic                               pf_fdp_total_prefetch,
  input  logic                               wfi_req,
  output logic                               wfi_safe,
  output logic                               rob_head_miss_in_dcache,
  output logic                               l1Miss,
  output logic [4:0][5:0]                    perf_value,
  output logic [600:0]                       difftest_refill_bore,
  // ---- 给 16 个 MSHR 的驱动 ----
  output miss_req_t                          pipe,                 // 流水寄存器里的请求（所有表项共用）
  output logic                               pipe_cancel,
  output logic [N_ENTRIES-1:0]               ent_pipe_alloc,       // 流水寄存器指向该表项且在分配
  output logic [N_ENTRIES-1:0]               ent_pipe_merge,
  output logic [N_ENTRIES-1:0]               ent_primary_valid,    // 本拍新请求分配给该表项
  output logic [N_ENTRIES-1:0]               ent_acq_ready,
  output logic [N_ENTRIES-1:0]               ent_grant_valid,
  output logic [N_ENTRIES-1:0]               ent_finish_ready,
  output logic [N_ENTRIES-1:0]               ent_l2_hint_valid,
  output logic [N_ENTRIES-1:0]               ent_mp_resp,
  output logic [N_ENTRIES-1:0]               ent_mp_refill_resp,
  output logic [N_ENTRIES-1:0]               ent_mp_replay,
  output logic [N_ENTRIES-1:0]               ent_mp_evict_BtoT_way,
  output logic                               acquire_fired_by_pipe_reg,
  output logic                               memset_pattern_detected,
  // ---- 16 个 MSHR 的输出 ----
  input  logic [N_ENTRIES-1:0]               ent_primary_ready,
  input  logic [N_ENTRIES-1:0]               ent_secondary_ready,
  input  logic [N_ENTRIES-1:0]               ent_secondary_reject,
  input  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_primary_ready,
  input  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_secondary_ready,
  input  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_secondary_reject,
  input  logic [N_ENTRIES-1:0]               ent_req_handled,
  input  logic [N_ENTRIES-1:0]               ent_acq_valid,
  input  ent_acq_t [N_ENTRIES-1:0]           ent_acq,
  input  logic [N_ENTRIES-1:0]               ent_finish_valid,
  input  logic [N_ENTRIES-1:0][9:0]          ent_finish_sink,
  input  logic [N_ENTRIES-1:0]               ent_ldq_valid,
  input  logic [N_ENTRIES-1:0][47:0]         ent_ldq_addr,
  input  logic [N_ENTRIES-1:0][511:0]        ent_ldq_data_raw,
  input  logic [N_ENTRIES-1:0]               ent_ldq_hasdata,
  input  logic [N_ENTRIES-1:0]               ent_ldq_refill_done,
  input  logic [N_ENTRIES-1:0]               ent_refill_info_valid,
  input  ent_refill_info_t [N_ENTRIES-1:0]   ent_refill_info,
  input  logic [N_ENTRIES-1:0][3:0]          ent_occupy_way,
  input  logic [N_ENTRIES-1:0]               ent_probe_block,
  input  logic [N_ENTRIES-1:0]               ent_replace_block,
  input  logic [N_ENTRIES-1:0]               ent_vaddr_valid,
  input  logic [N_ENTRIES-1:0][49:0]         ent_vaddr,
  input  logic [N_ENTRIES-1:0]               ent_isBtoT,
  input  ent_fwd_t [N_ENTRIES-1:0]           ent_fwd,
  input  logic [N_ENTRIES-1:0]               ent_rob_head_resp,
  input  logic [N_ENTRIES-1:0]               ent_late_prefetch,
  input  logic [N_ENTRIES-1:0]               ent_matched,
  input  logic [N_ENTRIES-1:0]               ent_l1Miss,
  input  logic [N_ENTRIES-1:0]               ent_wfi_safe,
  // ---- CMOUnit ----
  input  logic                               cmo_a_valid,
  input  logic [3:0]                         cmo_a_opcode,
  input  logic [47:0]                        cmo_a_address,
  output logic                               cmo_a_ready,
  output logic                               cmo_d_valid,
  input  logic                               cmo_d_ready,
  input  logic                               cmo_wfi_safe
);

  // ===========================================================================
  // 流水寄存器 miss_req_pipe_reg（RegInit(0)：整个 bundle 都异步复位为 0）
  // ===========================================================================
  miss_req_t  pipe_q;
  logic       pipe_merge_q, pipe_alloc_q, pipe_cancel_q;
  logic [3:0] pipe_mshr_id_q;

  // reg_valid：流水寄存器里有一条正在分配或合并的请求
  wire pipe_reg_valid = pipe_merge_q | pipe_alloc_q;

  assign pipe        = pipe_q;
  assign pipe_cancel = pipe_cancel_q;

  // ===========================================================================
  // §1 s0 入队判定
  // ---------------------------------------------------------------------------
  // merge  = 某个 MSHR 能合并它，或流水寄存器里正在分配的那条能吸收它；
  // reject = 某个 MSHR 要拒绝它，或流水寄存器里是同一行但合并不了；
  // alloc  = 既不合并也不拒绝，且有空表项；accept = alloc | merge。
  // 分配给哪个空表项：下标最小的 primary_ready 表项（primary_valid 独热）。
  // 查询口（queryMQ）用同样的规则给每条 LoadPipe 提前算一个 ready（时序更好）。
  // ===========================================================================
  wire pipe_merges_req  = pipe_merge_req (pipe_alloc_q, pipe_q, req.source, req.addr, req.vaddr);
  wire pipe_rejects_req = pipe_reject_req(pipe_alloc_q, pipe_q, req.source, req.addr, req.vaddr);

  wire merge  = |ent_secondary_ready  | pipe_merges_req;
  wire reject = |ent_secondary_reject | pipe_rejects_req;
  wire alloc  = ~reject & ~merge & |ent_primary_ready;
  wire accept = alloc | merge;

  assign req_ready = accept;

  always_comb begin
    logic former_ready;
    former_ready = 1'b0;
    for (int i = 0; i < N_ENTRIES; i++) begin
      ent_primary_valid[i] = req_valid & ~merge & ~reject & ~former_ready & ent_primary_ready[i];
      former_ready         = former_ready | ent_primary_ready[i];
    end
  end

  always_comb begin
    for (int q = 0; q < N_QUERY; q++) begin
      logic [N_ENTRIES-1:0] sec_ready, sec_reject, prim_ready;
      logic q_merge, q_reject, q_alloc;
      for (int i = 0; i < N_ENTRIES; i++) begin
        sec_ready[i]  = ent_query_secondary_ready[i][q];
        sec_reject[i] = ent_query_secondary_reject[i][q];
        prim_ready[i] = ent_query_primary_ready[i][q];
      end
      q_merge  = |sec_ready  | pipe_merge_req (pipe_alloc_q, pipe_q, query_req[q].source,
                                               query_req[q].addr, query_req[q].vaddr);
      q_reject = |sec_reject | pipe_reject_req(pipe_alloc_q, pipe_q, query_req[q].source,
                                               query_req[q].addr, query_req[q].vaddr);
      q_alloc  = ~q_reject & ~q_merge & |prim_ready;
      query_ready[q] = q_alloc | q_merge;
    end
  end

  // ===========================================================================
  // §2 resp 与流水寄存器
  // ---------------------------------------------------------------------------
  // 合并进流水寄存器的请求（pipe_handled）回流水寄存器的 mshr_id；否则回处理它的表项号。
  // 流水寄存器：req 字段只在 io.req.valid 拍更新；alloc/merge 标志每拍按"本拍真的收下"
  // （不取消、wbq 不挡）更新；cancel 记下 wbq 是否挡了；mshr_id 每拍 = resp.id。
  // ===========================================================================
  wire pipe_handled = pipe_merges_req & req_valid;

  assign resp_id      = pipe_handled ? pipe_mshr_id_q : onehot_to_index(ent_req_handled);
  assign resp_handled = |ent_req_handled | pipe_handled;
  assign resp_merged  = merge;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pipe_q         <= '0;
      pipe_merge_q   <= 1'b0;
      pipe_alloc_q   <= 1'b0;
      pipe_cancel_q  <= 1'b0;
      pipe_mshr_id_q <= '0;
    end else begin
      if (req_valid) pipe_q <= req;
      pipe_alloc_q   <= alloc & req_valid & ~req_cancel & ~wbq_block_miss_req;
      pipe_merge_q   <= merge & req_valid & ~req_cancel & ~wbq_block_miss_req;
      pipe_cancel_q  <= wbq_block_miss_req;
      pipe_mshr_id_q <= resp_id;
    end
  end

  // 流水寄存器只把 alloc/merge 交给它指向的那个表项；请求字段所有表项共用
  always_comb begin
    for (int i = 0; i < N_ENTRIES; i++) begin
      ent_pipe_alloc[i] = pipe_reg_valid & (pipe_mshr_id_q == 4'(i)) & pipe_alloc_q;
      ent_pipe_merge[i] = pipe_reg_valid & (pipe_mshr_id_q == 4'(i)) & pipe_merge_q;
    end
  end

  // ===========================================================================
  // §3 memset 模式检测
  // ---------------------------------------------------------------------------
  // 连续 >= 8 个被接收的 store（中间没有 load）且 LoadQueue 为空 ⇒ 认为在做 memset，
  // 此时连 0/1 号表项也允许接预取。计数器遇 load 清零、遇 store 加一（AMO/预取不动）。
  // ===========================================================================
  logic [9:0] source_except_load_cnt;
  logic       memset_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      source_except_load_cnt <= '0;
      memset_q               <= 1'b0;
    end else begin
      if (|ent_req_handled || pipe_handled) begin
        if (req.source == LOAD_SOURCE)       source_except_load_cnt <= '0;
        else if (req.source == STORE_SOURCE) source_except_load_cnt <= source_except_load_cnt + 10'd1;
      end
      memset_q <= (source_except_load_cnt >= 10'd8) & lqEmpty;
    end
  end
  assign memset_pattern_detected = memset_q;

  // ===========================================================================
  // §4 MSHR 数据前递（MissEntryForwardIO.check / forward，结果都打一拍）
  // ---------------------------------------------------------------------------
  // LoadPipe 给出 mshrid 与 paddr：
  //   result_valid = 请求有效 && 该表项占用 && 同一行；
  //   forward_mshr = 所要的半行已经到了（paddr[5]=0 看 firstbeat，=1 看 lastbeat）；
  //   data         = 16 字节：低 8 字节 = row[paddr[5:3]]；高 8 字节 = paddr[3] ? 同一 row : 下一 row（3 位回绕）。
  // forward_mshr / data 是 RegInit(0)；result_valid / denied / corrupt 是普通 RegNext（不复位）。
  // ===========================================================================
  logic [N_LDU-1:0]             fwd_mshr_q;
  logic [N_LDU-1:0][15:0][7:0]  fwd_data_q;
  logic [N_LDU-1:0]             fwd_result_valid_q, fwd_denied_q, fwd_corrupt_q;

  logic [N_LDU-1:0]             fwd_all_match;
  logic [N_LDU-1:0][127:0]      fwd_selected;
  always_comb begin
    for (int k = 0; k < N_LDU; k++) begin
      ent_fwd_t   e;
      logic [2:0] row;
      e   = ent_fwd[fwd_mshrid[k]];
      row = fwd_paddr[k][5:3];
      fwd_all_match[k] = (~fwd_paddr[k][5] & e.firstbeat_valid) | (fwd_paddr[k][5] & e.lastbeat_valid);
      fwd_selected[k]  = {fwd_paddr[k][3] ? e.raw_data[row] : e.raw_data[3'(row + 3'd1)],
                          e.raw_data[row]};
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fwd_mshr_q <= '0;
      fwd_data_q <= '0;
    end else begin
      fwd_mshr_q <= fwd_all_match;
      for (int k = 0; k < N_LDU; k++) fwd_data_q[k] <= fwd_selected[k];
    end
  end

  always_ff @(posedge clock) begin
    for (int k = 0; k < N_LDU; k++) begin
      fwd_result_valid_q[k] <= fwd_valid[k] & ent_fwd[fwd_mshrid[k]].inflight &
                               same_block(fwd_paddr[k], ent_fwd[fwd_mshrid[k]].paddr);
      fwd_corrupt_q[k]      <= ent_fwd[fwd_mshrid[k]].corrupt;
      fwd_denied_q[k]       <= ent_fwd[fwd_mshrid[k]].denied;
    end
  end

  assign fwd_forward_mshr = fwd_mshr_q;
  assign fwd_data         = fwd_data_q;
  assign fwd_result_valid = fwd_result_valid_q;
  assign fwd_denied       = fwd_denied_q;
  assign fwd_corrupt      = fwd_corrupt_q;

  // ===========================================================================
  // §5 D 通道 / L2 hint / MainPipe 回应分发
  // ---------------------------------------------------------------------------
  // Grant 按 source（= MSHR 号）送给对应表项（表项恒 ready）；opcode = CBOAck 的回应改送 CMOUnit
  // （CMOUnit 的 source 是 17，不会与表项撞号）。source 越界（>=16）且不是 CBOAck 时 ready=0。
  // ===========================================================================
  wire grant_is_cbo_ack = grant_valid & (grant.opcode == TL_CBO_ACK);
  assign cmo_d_valid = grant_is_cbo_ack & grant_valid;
  assign grant_ready = grant_is_cbo_ack ? cmo_d_ready : (grant.source < 6'(N_ENTRIES));

  always_comb begin
    for (int i = 0; i < N_ENTRIES; i++) begin
      ent_grant_valid[i]       = grant_valid & (grant.source == 6'(i));
      ent_l2_hint_valid[i]     = l2_hint_valid & (l2_hint_source_id == 4'(i));
      ent_mp_resp[i]           = mp_resp_valid & mp_resp_ack_miss_queue & (mp_resp_miss_id == 4'(i));
      ent_mp_replay[i]         = mp_info.s2_valid & mp_info.s2_replay_to_mq & (mp_info.s2_miss_id == 4'(i));
      ent_mp_evict_BtoT_way[i] = mp_info.s2_valid & mp_info.s2_evict_BtoT_way & (mp_info.s2_miss_id == 4'(i));
      ent_mp_refill_resp[i]    = mp_info.s3_valid & mp_info.s3_refill_resp & (mp_info.s3_miss_id == 4'(i));
    end
  end

  // ===========================================================================
  // §6 A 通道：流水寄存器直接发 Acquire + 18 路 TLArbiter.lowest
  // ---------------------------------------------------------------------------
  // 流水寄存器在分配拍就替表项发 Acquire（can_send_acquire）：
  //   除非本拍有一个 store 正要合并进它（store 可能改权限需求，等表项之后再发），WFI 期间不发。
  //   isKeyword：merge_req(自己) 成立（load/store/预取行里的 load）⇒ vaddr[5]；否则只有 load 分配才看 vaddr[5]。
  //   （与自身比较时 isAfter(lqIdx, lqIdx)=false、load 与 store 不可能同时成立，所以关键字就是 req.vaddr[5]。）
  // 仲裁顺序（下标小优先）：[0] CMOUnit、[1] 流水寄存器、[2+i] MSHR i。
  // 每路拍数：只有带数据的 A 消息（opcode[2]=0）是 2 拍；本模块发的 Acquire / CBO 都不带数据，
  //   但 MSHR 的 opcode 不是常量，公式照 TLArbiter 写。流水寄存器那一路 firtool 已折成 0。
  // ===========================================================================
  wire pipe_is_load  = pipe_q.source == LOAD_SOURCE;
  wire pipe_is_store = pipe_q.source == STORE_SOURCE;
  wire pipe_is_amo   = pipe_q.source == AMO_SOURCE;

  wire pipe_acq_valid = pipe_alloc_q & ~(req_valid & pipe_merges_req & (req.source == STORE_SOURCE)) &
                        ~wfi_req;

  wire pipe_self_merge = pipe_merge_req(pipe_alloc_q, pipe_q, pipe_q.source, pipe_q.addr, pipe_q.vaddr);
  wire pipe_is_keyword = pipe_self_merge ? pipe_q.vaddr[5] : (pipe_alloc_q & pipe_is_load & pipe_q.vaddr[5]);

  tl_a_t pipe_acq;
  always_comb begin
    pipe_acq.opcode         = pipe_q.full_overwrite ? TL_ACQUIRE_PERM : TL_ACQUIRE_BLOCK;
    pipe_acq.param          = {1'b0, acquire_grow_param(pipe_q.cmd, pipe_q.req_coh_state)};
    pipe_acq.size           = TL_LINE_LGSIZE;
    pipe_acq.source         = {2'b00, pipe_mshr_id_q};
    pipe_acq.address        = {pipe_q.addr[47:6], 6'd0};
    pipe_acq.user_alias     = pipe_q.vaddr[13:12];
    pipe_acq.user_vaddr     = pipe_q.vaddr[49:6];
    pipe_acq.user_needHint  = ~l2_pf_store_only | pipe_is_store;
    pipe_acq.echo_isKeyword = pipe_is_keyword;
    pipe_acq.mask           = '1;                 // 整行
    if (pipe_is_load)       pipe_acq.user_reqSource = REQ_SRC_CPU_LOAD_DATA;
    else if (pipe_is_store) pipe_acq.user_reqSource = REQ_SRC_CPU_STORE_DATA;
    else if (pipe_is_amo)   pipe_acq.user_reqSource = REQ_SRC_CPU_ATOMIC_DATA;
    else                    pipe_acq.user_reqSource = REQ_SRC_L1_DATA_PREFETCH;
  end

  // CMO 的 CacheBlockOperation：param/user/echo/mask 都是 DontCare（= 0）
  tl_a_t cmo_acq;
  always_comb begin
    cmo_acq         = '0;
    cmo_acq.opcode  = cmo_a_opcode;
    cmo_acq.size    = TL_LINE_LGSIZE;
    cmo_acq.source  = CMO_SOURCE_ID;
    cmo_acq.address = cmo_a_address;
  end

  logic [N_ACQ_SRC-1:0]            acq_src_valid, acq_src_ready, acq_src_beats1;
  tl_a_t [N_ACQ_SRC-1:0]           acq_src_bits;
  always_comb begin
    acq_src_valid[0]  = cmo_a_valid;
    acq_src_bits[0]   = cmo_acq;
    acq_src_beats1[0] = ~cmo_a_opcode[2];
    acq_src_valid[1]  = pipe_acq_valid;
    acq_src_bits[1]   = pipe_acq;
    acq_src_beats1[1] = 1'b0;
    for (int i = 0; i < N_ENTRIES; i++) begin
      acq_src_valid[2+i]               = ent_acq_valid[i];
      acq_src_bits[2+i].opcode         = ent_acq[i].opcode;
      acq_src_bits[2+i].param          = ent_acq[i].param;
      acq_src_bits[2+i].size           = TL_LINE_LGSIZE;
      acq_src_bits[2+i].source         = ent_acq[i].source;
      acq_src_bits[2+i].address        = ent_acq[i].address;
      acq_src_bits[2+i].user_alias     = ent_acq[i].user_alias;
      acq_src_bits[2+i].user_vaddr     = ent_acq[i].user_vaddr;
      acq_src_bits[2+i].user_reqSource = ent_acq[i].user_reqSource;
      acq_src_bits[2+i].user_needHint  = ent_acq[i].user_needHint;
      acq_src_bits[2+i].echo_isKeyword = ent_acq[i].echo_isKeyword;
      acq_src_bits[2+i].mask           = '1;
      acq_src_beats1[2+i]              = ~ent_acq[i].opcode[2];
    end
  end

  xs_TLArbiterLowest #(
    .N       (N_ACQ_SRC),
    .W       ($bits(tl_a_t)),
    .BEATS_W (1)
  ) u_acq_arb (
    .clock      (clock),
    .reset      (reset),
    .src_valid  (acq_src_valid),
    .src_ready  (acq_src_ready),
    .src_bits   (acq_src_bits),
    .src_beats1 (acq_src_beats1),
    .sink_ready (acq_ready),
    .sink_valid (acq_valid),
    .sink_bits  (acq)
  );

  assign cmo_a_ready               = acq_src_ready[0];
  assign acquire_fired_by_pipe_reg = acq_src_ready[1] & pipe_acq_valid;
  assign ent_acq_ready             = acq_src_ready[N_ACQ_SRC-1:2];

  // ===========================================================================
  // §7 E 通道：16 个 MSHR 的 GrantAck（单拍消息）
  // ===========================================================================
  xs_TLArbiterLowest #(
    .N       (N_ENTRIES),
    .W       (10),
    .BEATS_W (1)
  ) u_finish_arb (
    .clock      (clock),
    .reset      (reset),
    .src_valid  (ent_finish_valid),
    .src_ready  (ent_finish_ready),
    .src_bits   (ent_finish_sink),
    .src_beats1 ('0),
    .sink_ready (finish_ready),
    .sink_valid (finish_valid),
    .sink_bits  (finish_sink)
  );

  // ===========================================================================
  // §8 refill_info / probe、replace 阻挡 / BtoT 占路
  // ---------------------------------------------------------------------------
  // refill_info：MainPipe s2 按 s2_miss_id 取对应表项的回填整行（Mux1H，按位或）；
  //   store_mask 每个表项都恒为全 1。
  // replace 阻挡：任一表项占用同一行，或流水寄存器里是同一行。
  // BtoT：同 set 上正在做 BtoT 的表项（及流水寄存器）要占的路，这些路不能被替换；
  //   LoadPipe 的占路检查：同 set 被占的路超过 nWays-2=2 路 ⇒ occupy_fail。
  // ===========================================================================
  always_comb begin
    logic [N_ENTRIES-1:0] sel, hit;
    refill_info_store_data = '0;
    refill_info_store_mask = '0;
    refill_info_miss_param = '0;
    refill_info_tl_denied  = 1'b0;
    refill_info_tl_corrupt = 1'b0;
    for (int i = 0; i < N_ENTRIES; i++) begin
      sel[i] = mp_info.s2_miss_id == 4'(i);
      hit[i] = ent_refill_info_valid[i] & mp_info.s2_valid & sel[i];
      if (sel[i]) begin
        refill_info_store_data = refill_info_store_data | ent_refill_info[i].store_data;
        refill_info_store_mask = refill_info_store_mask | 64'hFFFF_FFFF_FFFF_FFFF;
        refill_info_miss_param = refill_info_miss_param | ent_refill_info[i].miss_param;
        refill_info_tl_denied  = refill_info_tl_denied  | ent_refill_info[i].tl_denied;
        refill_info_tl_corrupt = refill_info_tl_corrupt | ent_refill_info[i].tl_corrupt;
      end
    end
    refill_info_valid = |hit;
  end

  assign probe_block   = |ent_probe_block;
  assign replace_block = |ent_replace_block |
                         (pipe_reg_valid & same_block(pipe_q.addr, replace_addr) &
                          alias_match(pipe_q.vaddr, replace_vaddr));

  // 某个 set 上被 BtoT 占掉的路（16 个表项 + 流水寄存器）
  function automatic logic [3:0] btot_ways(input logic [7:0] set,
                                           input logic [N_ENTRIES-1:0] isBtoT,
                                           input logic [N_ENTRIES-1:0] vaddr_valid,
                                           input logic [N_ENTRIES-1:0][49:0] vaddr,
                                           input logic [N_ENTRIES-1:0][3:0] way,
                                           input logic pipe_valid, input miss_req_t p);
    logic [3:0] w;
    w = '0;
    for (int i = 0; i < N_ENTRIES; i++)
      if (isBtoT[i] && vaddr_valid[i] && vaddr[i][13:6] == set) w = w | way[i];
    if (pipe_valid && p.isBtoT && p.vaddr[13:6] == set) w = w | p.occupy_way;
    return w;
  endfunction

  assign btot_ways_for_set = btot_ways(evict_set, ent_isBtoT, ent_vaddr_valid, ent_vaddr,
                                       ent_occupy_way, pipe_reg_valid, pipe_q);
  always_comb begin
    for (int k = 0; k < N_LDU; k++) begin
      logic [3:0] w;
      w = btot_ways(occupy_set[k], ent_isBtoT, ent_vaddr_valid, ent_vaddr, ent_occupy_way,
                    pipe_reg_valid, pipe_q);
      occupy_fail[k] = (3'(w[0]) + 3'(w[1]) + 3'(w[2]) + 3'(w[3])) > 3'd2;
    end
  end

  // ===========================================================================
  // §9 预取统计、WFI、topdown、l1Miss、性能事件、difftest
  // ===========================================================================
  // naive：来了一个读预取，而这一行已在流水寄存器（非预取）或某表项（非预取）里 miss 着
  wire pipe_matches_req = same_block(pipe_q.addr, req.addr) & pipe_reg_valid & ~is_from_prefetch(pipe_q.source);
  assign pf_naive_late_miss_prefetch = req_valid & (req.source == DCACHE_PREFETCH_SOURCE) & (req.cmd == M_PFR) &
                                       (pipe_matches_req | |ent_matched);
  // fdp：流水寄存器 / 表项里的预取被同一行的非预取请求撞上
  assign pf_fdp_late_miss_prefetch   = (req_valid & pipe_alloc_q & same_block(pipe_q.addr, req.addr) &
                                        is_from_prefetch(pipe_q.source) & ~is_from_prefetch(req.source)) |
                                       |ent_late_prefetch;
  assign pf_fdp_prefetch_monitor_cnt = mp_req_out_valid & mp_req_out_ready;
  assign pf_fdp_total_prefetch       = alloc & req_valid & ~req_cancel & (req.pf_source > 3'd1);   // isFromL1Prefetch

  assign wfi_safe                = cmo_wfi_safe & &ent_wfi_safe;
  assign rob_head_miss_in_dcache = |ent_rob_head_resp;

  logic l1Miss_q;
  always_ff @(posedge clock) l1Miss_q <= |ent_l1Miss;
  assign l1Miss = l1Miss_q;

  // 性能事件：占用表项数打一拍后分四档，每个事件再打两拍输出（generatePerfEvent）
  logic [4:0] perf_valid_count_q;
  logic [4:0] perf_event_q1, perf_event_q2;
  wire  [4:0] perf_event = {perf_valid_count_q > 5'd12,
                            perf_valid_count_q > 5'd8 & perf_valid_count_q <= 5'd12,
                            perf_valid_count_q > 5'd4 & perf_valid_count_q <= 5'd8,
                            perf_valid_count_q < 5'd4,
                            accept & req_valid};   // req.fire
  always_ff @(posedge clock) begin
    perf_valid_count_q <= popcount16(~ent_primary_ready);
    perf_event_q1      <= perf_event;
    perf_event_q2      <= perf_event_q1;
  end
  always_comb begin
    for (int k = 0; k < 5; k++) perf_value[k] = {5'd0, perf_event_q2[k]};
  end

  // difftest DiffRefillEvent：refill_to_ldq 的 ParallelMux（按位或）结果，经 bore 端口送出
  //   {valid, addr(64), data_7..data_0(8x64), mask(8)=FF, coreid(8), index(8)=1}
  always_comb begin
    logic [47:0]  addr;
    logic [511:0] data_raw;
    logic         hasdata, refill_done;
    addr = '0; data_raw = '0; hasdata = 1'b0; refill_done = 1'b0;
    for (int i = 0; i < N_ENTRIES; i++) begin
      if (ent_ldq_valid[i]) begin
        addr        = addr        | ent_ldq_addr[i];
        data_raw    = data_raw    | ent_ldq_data_raw[i];
        hasdata     = hasdata     | ent_ldq_hasdata[i];
        refill_done = refill_done | ent_ldq_refill_done[i];
      end
    end
    difftest_refill_bore = {|ent_ldq_valid & hasdata & refill_done,
                            {16'd0, addr},
                            data_raw,
                            8'hFF,
                            {2'd0, hartId},
                            8'h01};
  end

  // ===========================================================================
  // §10 只为断言 / 性能计数而存在的寄存器（golden 同样保留；综合口径下没有读者）
  // ===========================================================================
  logic       chk_secondary_ready_onehot;   // assert(RegNext(PopCount(secondary_ready_vec) <= 1 || !req.valid))
  logic [4:0] perf_max_inflight;            // XSPerfAccumulate("max_inflight")

  always_ff @(posedge clock)
    chk_secondary_ready_onehot <= (popcount16(ent_secondary_ready) < 5'd2) | ~req_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) perf_max_inflight <= '0;
    else if (popcount16(~ent_primary_ready) > perf_max_inflight)
      perf_max_inflight <= popcount16(~ent_primary_ready);
  end

endmodule

// =============================================================================
// MissQueue —— golden 同名 wrapper：例化核、16 个 MissEntry（entries_0..15）、CMOUnit（cmo_unit）、
//   Arbiter16_MainPipeReq（main_pipe_req_arb），实例名与 golden 相同。
//   全部由 scripts/gen_missq.py 从 golden 端口表生成，改请改生成器。
// =============================================================================
module MissQueue
  import missqueue_pkg::*;
(
  // BEGIN GENERATED(missqueue-ports)
  input          clock,
  input          reset,
  input  [5:0]   io_hartId,
  output         io_req_ready,
  input          io_req_valid,
  input  [3:0]   io_req_bits_source,
  input  [2:0]   io_req_bits_pf_source,
  input  [4:0]   io_req_bits_cmd,
  input  [47:0]  io_req_bits_addr,
  input  [49:0]  io_req_bits_vaddr,
  input          io_req_bits_full_overwrite,
  input  [2:0]   io_req_bits_word_idx,
  input  [127:0] io_req_bits_amo_data,
  input  [15:0]  io_req_bits_amo_mask,
  input  [127:0] io_req_bits_amo_cmp,
  input  [1:0]   io_req_bits_req_coh_state,
  input  [5:0]   io_req_bits_id,
  input          io_req_bits_isBtoT,
  input  [3:0]   io_req_bits_occupy_way,
  input          io_req_bits_cancel,
  input  [511:0] io_req_bits_store_data,
  input  [63:0]  io_req_bits_store_mask,
  output [3:0]   io_resp_id,
  output         io_resp_handled,
  output         io_resp_merged,
  output         io_cmo_req_ready,
  input          io_cmo_req_valid,
  input  [2:0]   io_cmo_req_bits_opcode,
  input  [63:0]  io_cmo_req_bits_address,
  input          io_cmo_resp_ready,
  output         io_cmo_resp_valid,
  output         io_cmo_resp_bits_denied,
  output         io_cmo_resp_bits_corrupt,
  input  [3:0]   io_queryMQ_0_req_bits_source,
  input  [47:0]  io_queryMQ_0_req_bits_addr,
  input  [49:0]  io_queryMQ_0_req_bits_vaddr,
  output         io_queryMQ_0_ready,
  input  [3:0]   io_queryMQ_1_req_bits_source,
  input  [47:0]  io_queryMQ_1_req_bits_addr,
  input  [49:0]  io_queryMQ_1_req_bits_vaddr,
  output         io_queryMQ_1_ready,
  input  [3:0]   io_queryMQ_2_req_bits_source,
  input  [47:0]  io_queryMQ_2_req_bits_addr,
  input  [49:0]  io_queryMQ_2_req_bits_vaddr,
  output         io_queryMQ_2_ready,
  input  [3:0]   io_queryMQ_3_req_bits_source,
  input  [47:0]  io_queryMQ_3_req_bits_addr,
  input  [49:0]  io_queryMQ_3_req_bits_vaddr,
  output         io_queryMQ_3_ready,
  input          io_mem_acquire_ready,
  output         io_mem_acquire_valid,
  output [3:0]   io_mem_acquire_bits_opcode,
  output [2:0]   io_mem_acquire_bits_param,
  output [2:0]   io_mem_acquire_bits_size,
  output [5:0]   io_mem_acquire_bits_source,
  output [47:0]  io_mem_acquire_bits_address,
  output [1:0]   io_mem_acquire_bits_user_alias,
  output [43:0]  io_mem_acquire_bits_user_vaddr,
  output [4:0]   io_mem_acquire_bits_user_reqSource,
  output         io_mem_acquire_bits_user_needHint,
  output         io_mem_acquire_bits_echo_isKeyword,
  output [31:0]  io_mem_acquire_bits_mask,
  output         io_mem_grant_ready,
  input          io_mem_grant_valid,
  input  [3:0]   io_mem_grant_bits_opcode,
  input  [1:0]   io_mem_grant_bits_param,
  input  [2:0]   io_mem_grant_bits_size,
  input  [5:0]   io_mem_grant_bits_source,
  input  [9:0]   io_mem_grant_bits_sink,
  input          io_mem_grant_bits_denied,
  input  [255:0] io_mem_grant_bits_data,
  input          io_mem_grant_bits_corrupt,
  input          io_mem_finish_ready,
  output         io_mem_finish_valid,
  output [9:0]   io_mem_finish_bits_sink,
  input          io_l2_hint_valid,
  input  [3:0]   io_l2_hint_bits_sourceId,
  input          io_main_pipe_req_ready,
  output         io_main_pipe_req_valid,
  output [3:0]   io_main_pipe_req_bits_miss_id,
  output [3:0]   io_main_pipe_req_bits_occupy_way,
  output         io_main_pipe_req_bits_miss_fail_cause_evict_btot,
  output [3:0]   io_main_pipe_req_bits_source,
  output [4:0]   io_main_pipe_req_bits_cmd,
  output [49:0]  io_main_pipe_req_bits_vaddr,
  output [47:0]  io_main_pipe_req_bits_addr,
  output [2:0]   io_main_pipe_req_bits_word_idx,
  output [127:0] io_main_pipe_req_bits_amo_data,
  output [15:0]  io_main_pipe_req_bits_amo_mask,
  output [127:0] io_main_pipe_req_bits_amo_cmp,
  output [2:0]   io_main_pipe_req_bits_pf_source,
  output         io_main_pipe_req_bits_access,
  output [5:0]   io_main_pipe_req_bits_id,
  input          io_main_pipe_resp_valid,
  input  [3:0]   io_main_pipe_resp_bits_miss_id,
  input          io_main_pipe_resp_bits_ack_miss_queue,
  input          io_mainpipe_info_s2_valid,
  input  [3:0]   io_mainpipe_info_s2_miss_id,
  input          io_mainpipe_info_s2_replay_to_mq,
  input          io_mainpipe_info_s2_evict_BtoT_way,
  input  [3:0]   io_mainpipe_info_s2_next_evict_way,
  input          io_mainpipe_info_s3_valid,
  input  [3:0]   io_mainpipe_info_s3_miss_id,
  input          io_mainpipe_info_s3_refill_resp,
  output         io_refill_info_valid,
  output [511:0] io_refill_info_bits_store_data,
  output [63:0]  io_refill_info_bits_store_mask,
  output [1:0]   io_refill_info_bits_miss_param,
  output         io_refill_info_bits_error_tl_denied,
  output         io_refill_info_bits_error_tl_corrupt,
  input  [47:0]  io_probe_req_bits_addr,
  input  [49:0]  io_probe_req_bits_vaddr,
  output         io_probe_block,
  input  [47:0]  io_replace_req_bits_addr,
  input  [49:0]  io_replace_req_bits_vaddr,
  output         io_replace_block,
  input  [7:0]   io_evict_set,
  output [3:0]   io_btot_ways_for_set,
  input  [7:0]   io_occupy_set_0,
  input  [7:0]   io_occupy_set_1,
  input  [7:0]   io_occupy_set_2,
  output         io_occupy_fail_0,
  output         io_occupy_fail_1,
  output         io_occupy_fail_2,
  input          io_wbq_block_miss_req,
  input          io_forward_0_valid,
  input  [3:0]   io_forward_0_mshrid,
  input  [47:0]  io_forward_0_paddr,
  output         io_forward_0_forward_mshr,
  output [7:0]   io_forward_0_forwardData_0,
  output [7:0]   io_forward_0_forwardData_1,
  output [7:0]   io_forward_0_forwardData_2,
  output [7:0]   io_forward_0_forwardData_3,
  output [7:0]   io_forward_0_forwardData_4,
  output [7:0]   io_forward_0_forwardData_5,
  output [7:0]   io_forward_0_forwardData_6,
  output [7:0]   io_forward_0_forwardData_7,
  output [7:0]   io_forward_0_forwardData_8,
  output [7:0]   io_forward_0_forwardData_9,
  output [7:0]   io_forward_0_forwardData_10,
  output [7:0]   io_forward_0_forwardData_11,
  output [7:0]   io_forward_0_forwardData_12,
  output [7:0]   io_forward_0_forwardData_13,
  output [7:0]   io_forward_0_forwardData_14,
  output [7:0]   io_forward_0_forwardData_15,
  output         io_forward_0_forward_result_valid,
  output         io_forward_0_denied,
  output         io_forward_0_corrupt,
  input          io_forward_1_valid,
  input  [3:0]   io_forward_1_mshrid,
  input  [47:0]  io_forward_1_paddr,
  output         io_forward_1_forward_mshr,
  output [7:0]   io_forward_1_forwardData_0,
  output [7:0]   io_forward_1_forwardData_1,
  output [7:0]   io_forward_1_forwardData_2,
  output [7:0]   io_forward_1_forwardData_3,
  output [7:0]   io_forward_1_forwardData_4,
  output [7:0]   io_forward_1_forwardData_5,
  output [7:0]   io_forward_1_forwardData_6,
  output [7:0]   io_forward_1_forwardData_7,
  output [7:0]   io_forward_1_forwardData_8,
  output [7:0]   io_forward_1_forwardData_9,
  output [7:0]   io_forward_1_forwardData_10,
  output [7:0]   io_forward_1_forwardData_11,
  output [7:0]   io_forward_1_forwardData_12,
  output [7:0]   io_forward_1_forwardData_13,
  output [7:0]   io_forward_1_forwardData_14,
  output [7:0]   io_forward_1_forwardData_15,
  output         io_forward_1_forward_result_valid,
  output         io_forward_1_denied,
  output         io_forward_1_corrupt,
  input          io_forward_2_valid,
  input  [3:0]   io_forward_2_mshrid,
  input  [47:0]  io_forward_2_paddr,
  output         io_forward_2_forward_mshr,
  output [7:0]   io_forward_2_forwardData_0,
  output [7:0]   io_forward_2_forwardData_1,
  output [7:0]   io_forward_2_forwardData_2,
  output [7:0]   io_forward_2_forwardData_3,
  output [7:0]   io_forward_2_forwardData_4,
  output [7:0]   io_forward_2_forwardData_5,
  output [7:0]   io_forward_2_forwardData_6,
  output [7:0]   io_forward_2_forwardData_7,
  output [7:0]   io_forward_2_forwardData_8,
  output [7:0]   io_forward_2_forwardData_9,
  output [7:0]   io_forward_2_forwardData_10,
  output [7:0]   io_forward_2_forwardData_11,
  output [7:0]   io_forward_2_forwardData_12,
  output [7:0]   io_forward_2_forwardData_13,
  output [7:0]   io_forward_2_forwardData_14,
  output [7:0]   io_forward_2_forwardData_15,
  output         io_forward_2_forward_result_valid,
  output         io_forward_2_denied,
  output         io_forward_2_corrupt,
  input          io_l2_pf_store_only,
  input          io_lqEmpty,
  output         io_prefetch_info_naive_late_miss_prefetch,
  output         io_prefetch_info_fdp_late_miss_prefetch,
  output         io_prefetch_info_fdp_prefetch_monitor_cnt,
  output         io_prefetch_info_fdp_total_prefetch,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  input          io_debugTopDown_robHeadVaddr_valid,
  input  [49:0]  io_debugTopDown_robHeadVaddr_bits,
  output         io_debugTopDown_robHeadMissInDCache,
  output         io_l1Miss,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [600:0] gatewayIn_packed_41_bore
  // END GENERATED
);

  // BEGIN GENERATED(missqueue-body)
  // ---- 核 <-> 顶层端口：结构体 / 向量信号 ----
  miss_req_t                          req_s;
  query_req_t [N_QUERY-1:0]           query_s;
  logic [N_QUERY-1:0]                 query_ready_s;
  tl_a_t                              acq_s;
  tl_d_t                              grant_s;
  mp_info_t                           mp_info_s;
  logic [N_LDU-1:0][7:0]              occupy_set_s;
  logic [N_LDU-1:0]                   occupy_fail_s;
  logic [N_LDU-1:0]                   fwd_valid_s, fwd_forward_mshr_s, fwd_result_valid_s;
  logic [N_LDU-1:0]                   fwd_denied_s, fwd_corrupt_s;
  logic [N_LDU-1:0][3:0]              fwd_mshrid_s;
  logic [N_LDU-1:0][47:0]             fwd_paddr_s;
  logic [N_LDU-1:0][15:0][7:0]        fwd_data_s;
  logic [4:0][5:0]                    perf_value_s;
  // ---- 核 -> MSHR ----
  miss_req_t                          pipe_s;
  logic                               pipe_cancel_s, acquire_fired_by_pipe_reg_s, memset_pattern_detected_s;
  logic [N_ENTRIES-1:0]               ent_pipe_alloc;
  logic [N_ENTRIES-1:0]               ent_pipe_merge;
  logic [N_ENTRIES-1:0]               ent_primary_valid;
  logic [N_ENTRIES-1:0]               ent_acq_ready;
  logic [N_ENTRIES-1:0]               ent_grant_valid;
  logic [N_ENTRIES-1:0]               ent_finish_ready;
  logic [N_ENTRIES-1:0]               ent_l2_hint_valid;
  logic [N_ENTRIES-1:0]               ent_mp_resp;
  logic [N_ENTRIES-1:0]               ent_mp_refill_resp;
  logic [N_ENTRIES-1:0]               ent_mp_replay;
  logic [N_ENTRIES-1:0]               ent_mp_evict_BtoT_way;
  // ---- MSHR -> 核 / 仲裁器 ----
  logic [N_ENTRIES-1:0]               ent_primary_ready;
  logic [N_ENTRIES-1:0]               ent_secondary_ready;
  logic [N_ENTRIES-1:0]               ent_secondary_reject;
  logic [N_ENTRIES-1:0]               ent_req_handled;
  logic [N_ENTRIES-1:0]               ent_acq_valid;
  logic [N_ENTRIES-1:0]               ent_finish_valid;
  logic [N_ENTRIES-1:0]               ent_ldq_valid;
  logic [N_ENTRIES-1:0]               ent_ldq_hasdata;
  logic [N_ENTRIES-1:0]               ent_ldq_refill_done;
  logic [N_ENTRIES-1:0]               ent_refill_info_valid;
  logic [N_ENTRIES-1:0]               ent_probe_block;
  logic [N_ENTRIES-1:0]               ent_replace_block;
  logic [N_ENTRIES-1:0]               ent_vaddr_valid;
  logic [N_ENTRIES-1:0]               ent_isBtoT;
  logic [N_ENTRIES-1:0]               ent_rob_head_resp;
  logic [N_ENTRIES-1:0]               ent_late_prefetch;
  logic [N_ENTRIES-1:0]               ent_matched;
  logic [N_ENTRIES-1:0]               ent_l1Miss;
  logic [N_ENTRIES-1:0]               ent_wfi_safe;
  logic [N_ENTRIES-1:0]               ent_mp_valid;
  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_primary_ready;
  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_secondary_ready;
  logic [N_ENTRIES-1:0][N_QUERY-1:0]  ent_query_secondary_reject;
  ent_acq_t [N_ENTRIES-1:0]           ent_acq;
  logic [N_ENTRIES-1:0][9:0]          ent_finish_sink;
  logic [N_ENTRIES-1:0][47:0]         ent_ldq_addr;
  logic [N_ENTRIES-1:0][511:0]        ent_ldq_data_raw;
  ent_refill_info_t [N_ENTRIES-1:0]   ent_refill_info;
  logic [N_ENTRIES-1:0][3:0]          ent_occupy_way;
  logic [N_ENTRIES-1:0][49:0]         ent_vaddr;
  ent_fwd_t [N_ENTRIES-1:0]           ent_fwd;
  logic [N_ENTRIES-1:0][3:0] ent_mp_miss_id;
  logic [N_ENTRIES-1:0][3:0] ent_mp_occupy_way;
  logic [N_ENTRIES-1:0] ent_mp_miss_fail_cause_evict_btot;
  logic [N_ENTRIES-1:0][3:0] ent_mp_source;
  logic [N_ENTRIES-1:0][4:0] ent_mp_cmd;
  logic [N_ENTRIES-1:0][49:0] ent_mp_vaddr;
  logic [N_ENTRIES-1:0][47:0] ent_mp_addr;
  logic [N_ENTRIES-1:0][2:0] ent_mp_word_idx;
  logic [N_ENTRIES-1:0][127:0] ent_mp_amo_data;
  logic [N_ENTRIES-1:0][15:0] ent_mp_amo_mask;
  logic [N_ENTRIES-1:0][127:0] ent_mp_amo_cmp;
  logic [N_ENTRIES-1:0][2:0] ent_mp_pf_source;
  logic [N_ENTRIES-1:0] ent_mp_access;
  logic [N_ENTRIES-1:0][5:0] ent_mp_id;
  logic [N_ENTRIES-1:0]               arb_in_ready;
  logic                               arb_out_valid_s;
  // ---- CMOUnit ----
  logic                               cmo_a_valid_s, cmo_a_ready_s, cmo_d_valid_s, cmo_d_ready_s;
  logic                               cmo_wfi_safe_s;
  logic [3:0]                         cmo_a_opcode_s;
  logic [47:0]                        cmo_a_address_s;

  // ---- 顶层端口拆装 ----
  assign req_s.source = io_req_bits_source;
  assign req_s.pf_source = io_req_bits_pf_source;
  assign req_s.cmd = io_req_bits_cmd;
  assign req_s.addr = io_req_bits_addr;
  assign req_s.vaddr = io_req_bits_vaddr;
  assign req_s.full_overwrite = io_req_bits_full_overwrite;
  assign req_s.word_idx = io_req_bits_word_idx;
  assign req_s.amo_data = io_req_bits_amo_data;
  assign req_s.amo_mask = io_req_bits_amo_mask;
  assign req_s.amo_cmp = io_req_bits_amo_cmp;
  assign req_s.req_coh_state = io_req_bits_req_coh_state;
  assign req_s.id = io_req_bits_id;
  assign req_s.isBtoT = io_req_bits_isBtoT;
  assign req_s.occupy_way = io_req_bits_occupy_way;
  assign req_s.store_data = io_req_bits_store_data;
  assign req_s.store_mask = io_req_bits_store_mask;
  assign query_s[0].source = io_queryMQ_0_req_bits_source;
  assign query_s[0].addr = io_queryMQ_0_req_bits_addr;
  assign query_s[0].vaddr = io_queryMQ_0_req_bits_vaddr;
  assign query_s[1].source = io_queryMQ_1_req_bits_source;
  assign query_s[1].addr = io_queryMQ_1_req_bits_addr;
  assign query_s[1].vaddr = io_queryMQ_1_req_bits_vaddr;
  assign query_s[2].source = io_queryMQ_2_req_bits_source;
  assign query_s[2].addr = io_queryMQ_2_req_bits_addr;
  assign query_s[2].vaddr = io_queryMQ_2_req_bits_vaddr;
  assign query_s[3].source = io_queryMQ_3_req_bits_source;
  assign query_s[3].addr = io_queryMQ_3_req_bits_addr;
  assign query_s[3].vaddr = io_queryMQ_3_req_bits_vaddr;
  assign grant_s.opcode = io_mem_grant_bits_opcode;
  assign grant_s.param = io_mem_grant_bits_param;
  assign grant_s.size = io_mem_grant_bits_size;
  assign grant_s.source = io_mem_grant_bits_source;
  assign grant_s.sink = io_mem_grant_bits_sink;
  assign grant_s.denied = io_mem_grant_bits_denied;
  assign grant_s.data = io_mem_grant_bits_data;
  assign grant_s.corrupt = io_mem_grant_bits_corrupt;
  assign mp_info_s.s2_valid = io_mainpipe_info_s2_valid;
  assign mp_info_s.s2_miss_id = io_mainpipe_info_s2_miss_id;
  assign mp_info_s.s2_replay_to_mq = io_mainpipe_info_s2_replay_to_mq;
  assign mp_info_s.s2_evict_BtoT_way = io_mainpipe_info_s2_evict_BtoT_way;
  assign mp_info_s.s2_next_evict_way = io_mainpipe_info_s2_next_evict_way;
  assign mp_info_s.s3_valid = io_mainpipe_info_s3_valid;
  assign mp_info_s.s3_miss_id = io_mainpipe_info_s3_miss_id;
  assign mp_info_s.s3_refill_resp = io_mainpipe_info_s3_refill_resp;
  assign occupy_set_s[0] = io_occupy_set_0;
  assign fwd_valid_s[0] = io_forward_0_valid;
  assign fwd_mshrid_s[0] = io_forward_0_mshrid;
  assign fwd_paddr_s[0] = io_forward_0_paddr;
  assign occupy_set_s[1] = io_occupy_set_1;
  assign fwd_valid_s[1] = io_forward_1_valid;
  assign fwd_mshrid_s[1] = io_forward_1_mshrid;
  assign fwd_paddr_s[1] = io_forward_1_paddr;
  assign occupy_set_s[2] = io_occupy_set_2;
  assign fwd_valid_s[2] = io_forward_2_valid;
  assign fwd_mshrid_s[2] = io_forward_2_mshrid;
  assign fwd_paddr_s[2] = io_forward_2_paddr;
  assign io_queryMQ_0_ready = query_ready_s[0];
  assign io_queryMQ_1_ready = query_ready_s[1];
  assign io_queryMQ_2_ready = query_ready_s[2];
  assign io_queryMQ_3_ready = query_ready_s[3];
  assign io_mem_acquire_bits_opcode = acq_s.opcode;
  assign io_mem_acquire_bits_param = acq_s.param;
  assign io_mem_acquire_bits_size = acq_s.size;
  assign io_mem_acquire_bits_source = acq_s.source;
  assign io_mem_acquire_bits_address = acq_s.address;
  assign io_mem_acquire_bits_user_alias = acq_s.user_alias;
  assign io_mem_acquire_bits_user_vaddr = acq_s.user_vaddr;
  assign io_mem_acquire_bits_user_reqSource = acq_s.user_reqSource;
  assign io_mem_acquire_bits_user_needHint = acq_s.user_needHint;
  assign io_mem_acquire_bits_echo_isKeyword = acq_s.echo_isKeyword;
  assign io_mem_acquire_bits_mask = acq_s.mask;
  assign io_occupy_fail_0 = occupy_fail_s[0];
  assign io_forward_0_forward_mshr = fwd_forward_mshr_s[0];
  assign io_forward_0_forwardData_0 = fwd_data_s[0][0];
  assign io_forward_0_forwardData_1 = fwd_data_s[0][1];
  assign io_forward_0_forwardData_2 = fwd_data_s[0][2];
  assign io_forward_0_forwardData_3 = fwd_data_s[0][3];
  assign io_forward_0_forwardData_4 = fwd_data_s[0][4];
  assign io_forward_0_forwardData_5 = fwd_data_s[0][5];
  assign io_forward_0_forwardData_6 = fwd_data_s[0][6];
  assign io_forward_0_forwardData_7 = fwd_data_s[0][7];
  assign io_forward_0_forwardData_8 = fwd_data_s[0][8];
  assign io_forward_0_forwardData_9 = fwd_data_s[0][9];
  assign io_forward_0_forwardData_10 = fwd_data_s[0][10];
  assign io_forward_0_forwardData_11 = fwd_data_s[0][11];
  assign io_forward_0_forwardData_12 = fwd_data_s[0][12];
  assign io_forward_0_forwardData_13 = fwd_data_s[0][13];
  assign io_forward_0_forwardData_14 = fwd_data_s[0][14];
  assign io_forward_0_forwardData_15 = fwd_data_s[0][15];
  assign io_forward_0_forward_result_valid = fwd_result_valid_s[0];
  assign io_forward_0_denied = fwd_denied_s[0];
  assign io_forward_0_corrupt = fwd_corrupt_s[0];
  assign io_occupy_fail_1 = occupy_fail_s[1];
  assign io_forward_1_forward_mshr = fwd_forward_mshr_s[1];
  assign io_forward_1_forwardData_0 = fwd_data_s[1][0];
  assign io_forward_1_forwardData_1 = fwd_data_s[1][1];
  assign io_forward_1_forwardData_2 = fwd_data_s[1][2];
  assign io_forward_1_forwardData_3 = fwd_data_s[1][3];
  assign io_forward_1_forwardData_4 = fwd_data_s[1][4];
  assign io_forward_1_forwardData_5 = fwd_data_s[1][5];
  assign io_forward_1_forwardData_6 = fwd_data_s[1][6];
  assign io_forward_1_forwardData_7 = fwd_data_s[1][7];
  assign io_forward_1_forwardData_8 = fwd_data_s[1][8];
  assign io_forward_1_forwardData_9 = fwd_data_s[1][9];
  assign io_forward_1_forwardData_10 = fwd_data_s[1][10];
  assign io_forward_1_forwardData_11 = fwd_data_s[1][11];
  assign io_forward_1_forwardData_12 = fwd_data_s[1][12];
  assign io_forward_1_forwardData_13 = fwd_data_s[1][13];
  assign io_forward_1_forwardData_14 = fwd_data_s[1][14];
  assign io_forward_1_forwardData_15 = fwd_data_s[1][15];
  assign io_forward_1_forward_result_valid = fwd_result_valid_s[1];
  assign io_forward_1_denied = fwd_denied_s[1];
  assign io_forward_1_corrupt = fwd_corrupt_s[1];
  assign io_occupy_fail_2 = occupy_fail_s[2];
  assign io_forward_2_forward_mshr = fwd_forward_mshr_s[2];
  assign io_forward_2_forwardData_0 = fwd_data_s[2][0];
  assign io_forward_2_forwardData_1 = fwd_data_s[2][1];
  assign io_forward_2_forwardData_2 = fwd_data_s[2][2];
  assign io_forward_2_forwardData_3 = fwd_data_s[2][3];
  assign io_forward_2_forwardData_4 = fwd_data_s[2][4];
  assign io_forward_2_forwardData_5 = fwd_data_s[2][5];
  assign io_forward_2_forwardData_6 = fwd_data_s[2][6];
  assign io_forward_2_forwardData_7 = fwd_data_s[2][7];
  assign io_forward_2_forwardData_8 = fwd_data_s[2][8];
  assign io_forward_2_forwardData_9 = fwd_data_s[2][9];
  assign io_forward_2_forwardData_10 = fwd_data_s[2][10];
  assign io_forward_2_forwardData_11 = fwd_data_s[2][11];
  assign io_forward_2_forwardData_12 = fwd_data_s[2][12];
  assign io_forward_2_forwardData_13 = fwd_data_s[2][13];
  assign io_forward_2_forwardData_14 = fwd_data_s[2][14];
  assign io_forward_2_forwardData_15 = fwd_data_s[2][15];
  assign io_forward_2_forward_result_valid = fwd_result_valid_s[2];
  assign io_forward_2_denied = fwd_denied_s[2];
  assign io_forward_2_corrupt = fwd_corrupt_s[2];
  assign io_perf_0_value = perf_value_s[0];
  assign io_perf_1_value = perf_value_s[1];
  assign io_perf_2_value = perf_value_s[2];
  assign io_perf_3_value = perf_value_s[3];
  assign io_perf_4_value = perf_value_s[4];
  assign io_main_pipe_req_valid = arb_out_valid_s;

  xs_MissQueue_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .hartId                      (io_hartId),
    .req_valid                   (io_req_valid),
    .req                         (req_s),
    .req_cancel                  (io_req_bits_cancel),
    .req_ready                   (io_req_ready),
    .resp_id                     (io_resp_id),
    .resp_handled                (io_resp_handled),
    .resp_merged                 (io_resp_merged),
    .wbq_block_miss_req          (io_wbq_block_miss_req),
    .query_req                   (query_s),
    .query_ready                 (query_ready_s),
    .acq_ready                   (io_mem_acquire_ready),
    .acq_valid                   (io_mem_acquire_valid),
    .acq                         (acq_s),
    .grant_valid                 (io_mem_grant_valid),
    .grant                       (grant_s),
    .grant_ready                 (io_mem_grant_ready),
    .finish_ready                (io_mem_finish_ready),
    .finish_valid                (io_mem_finish_valid),
    .finish_sink                 (io_mem_finish_bits_sink),
    .l2_hint_valid               (io_l2_hint_valid),
    .l2_hint_source_id           (io_l2_hint_bits_sourceId),
    .mp_req_out_valid            (arb_out_valid_s),
    .mp_req_out_ready            (io_main_pipe_req_ready),
    .mp_resp_valid               (io_main_pipe_resp_valid),
    .mp_resp_miss_id             (io_main_pipe_resp_bits_miss_id),
    .mp_resp_ack_miss_queue      (io_main_pipe_resp_bits_ack_miss_queue),
    .mp_info                     (mp_info_s),
    .refill_info_valid           (io_refill_info_valid),
    .refill_info_store_data      (io_refill_info_bits_store_data),
    .refill_info_store_mask      (io_refill_info_bits_store_mask),
    .refill_info_miss_param      (io_refill_info_bits_miss_param),
    .refill_info_tl_denied       (io_refill_info_bits_error_tl_denied),
    .refill_info_tl_corrupt      (io_refill_info_bits_error_tl_corrupt),
    .probe_block                 (io_probe_block),
    .replace_addr                (io_replace_req_bits_addr),
    .replace_vaddr               (io_replace_req_bits_vaddr),
    .replace_block               (io_replace_block),
    .evict_set                   (io_evict_set),
    .btot_ways_for_set           (io_btot_ways_for_set),
    .occupy_set                  (occupy_set_s),
    .occupy_fail                 (occupy_fail_s),
    .fwd_valid                   (fwd_valid_s),
    .fwd_mshrid                  (fwd_mshrid_s),
    .fwd_paddr                   (fwd_paddr_s),
    .fwd_forward_mshr            (fwd_forward_mshr_s),
    .fwd_data                    (fwd_data_s),
    .fwd_result_valid            (fwd_result_valid_s),
    .fwd_denied                  (fwd_denied_s),
    .fwd_corrupt                 (fwd_corrupt_s),
    .l2_pf_store_only            (io_l2_pf_store_only),
    .lqEmpty                     (io_lqEmpty),
    .pf_naive_late_miss_prefetch (io_prefetch_info_naive_late_miss_prefetch),
    .pf_fdp_late_miss_prefetch   (io_prefetch_info_fdp_late_miss_prefetch),
    .pf_fdp_prefetch_monitor_cnt (io_prefetch_info_fdp_prefetch_monitor_cnt),
    .pf_fdp_total_prefetch       (io_prefetch_info_fdp_total_prefetch),
    .wfi_req                     (io_wfi_wfiReq),
    .wfi_safe                    (io_wfi_wfiSafe),
    .rob_head_miss_in_dcache     (io_debugTopDown_robHeadMissInDCache),
    .l1Miss                      (io_l1Miss),
    .perf_value                  (perf_value_s),
    .difftest_refill_bore        (gatewayIn_packed_41_bore),
    .pipe                        (pipe_s),
    .pipe_cancel                 (pipe_cancel_s),
    .acquire_fired_by_pipe_reg   (acquire_fired_by_pipe_reg_s),
    .memset_pattern_detected     (memset_pattern_detected_s),
    .cmo_a_valid                 (cmo_a_valid_s),
    .cmo_a_opcode                (cmo_a_opcode_s),
    .cmo_a_address               (cmo_a_address_s),
    .cmo_a_ready                 (cmo_a_ready_s),
    .cmo_d_valid                 (cmo_d_valid_s),
    .cmo_d_ready                 (cmo_d_ready_s),
    .cmo_wfi_safe                (cmo_wfi_safe_s),
    .ent_pipe_alloc              (ent_pipe_alloc),
    .ent_pipe_merge              (ent_pipe_merge),
    .ent_primary_valid           (ent_primary_valid),
    .ent_acq_ready               (ent_acq_ready),
    .ent_grant_valid             (ent_grant_valid),
    .ent_finish_ready            (ent_finish_ready),
    .ent_l2_hint_valid           (ent_l2_hint_valid),
    .ent_mp_resp                 (ent_mp_resp),
    .ent_mp_refill_resp          (ent_mp_refill_resp),
    .ent_mp_replay               (ent_mp_replay),
    .ent_mp_evict_BtoT_way       (ent_mp_evict_BtoT_way),
    .ent_primary_ready           (ent_primary_ready),
    .ent_secondary_ready         (ent_secondary_ready),
    .ent_secondary_reject        (ent_secondary_reject),
    .ent_query_primary_ready     (ent_query_primary_ready),
    .ent_query_secondary_ready   (ent_query_secondary_ready),
    .ent_query_secondary_reject  (ent_query_secondary_reject),
    .ent_req_handled             (ent_req_handled),
    .ent_acq_valid               (ent_acq_valid),
    .ent_acq                     (ent_acq),
    .ent_finish_valid            (ent_finish_valid),
    .ent_finish_sink             (ent_finish_sink),
    .ent_ldq_valid               (ent_ldq_valid),
    .ent_ldq_addr                (ent_ldq_addr),
    .ent_ldq_data_raw            (ent_ldq_data_raw),
    .ent_ldq_hasdata             (ent_ldq_hasdata),
    .ent_ldq_refill_done         (ent_ldq_refill_done),
    .ent_refill_info_valid       (ent_refill_info_valid),
    .ent_refill_info             (ent_refill_info),
    .ent_occupy_way              (ent_occupy_way),
    .ent_probe_block             (ent_probe_block),
    .ent_replace_block           (ent_replace_block),
    .ent_vaddr_valid             (ent_vaddr_valid),
    .ent_vaddr                   (ent_vaddr),
    .ent_isBtoT                  (ent_isBtoT),
    .ent_fwd                     (ent_fwd),
    .ent_rob_head_resp           (ent_rob_head_resp),
    .ent_late_prefetch           (ent_late_prefetch),
    .ent_matched                 (ent_matched),
    .ent_l1Miss                  (ent_l1Miss),
    .ent_wfi_safe                (ent_wfi_safe)
  );

  MissEntry entries_0 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd0),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[0]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[0]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[0]),
    .io_primary_ready                                 (ent_primary_ready[0]),
    .io_secondary_ready                               (ent_secondary_ready[0]),
    .io_secondary_reject                              (ent_secondary_reject[0]),
    .io_mem_acquire_ready                             (ent_acq_ready[0]),
    .io_mem_acquire_valid                             (ent_acq_valid[0]),
    .io_mem_acquire_bits_opcode                       (ent_acq[0].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[0].param),
    .io_mem_acquire_bits_source                       (ent_acq[0].source),
    .io_mem_acquire_bits_address                      (ent_acq[0].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[0].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[0].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[0].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[0].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[0].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[0]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[0]),
    .io_mem_finish_valid                              (ent_finish_valid[0]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[0]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[0][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[0][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[0][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[0][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[0][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[0][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[0][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[0][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[0][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[0][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[0][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[0][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[0]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[0]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[0]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[0]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[0]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[0]),
    .io_main_pipe_req_ready                           (arb_in_ready[0]),
    .io_main_pipe_req_valid                           (ent_mp_valid[0]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[0]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[0]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[0]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[0]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[0]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[0]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[0]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[0]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[0]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[0]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[0]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[0]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[0]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[0]),
    .io_main_pipe_resp                                (ent_mp_resp[0]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[0]),
    .io_main_pipe_replay                              (ent_mp_replay[0]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[0]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[0]),
    .io_refill_info_bits_store_data                   (ent_refill_info[0].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[0].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[0].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[0].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[0]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[0]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[0]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[0]),
    .io_req_vaddr_bits                                (ent_vaddr[0]),
    .io_req_isBtoT                                    (ent_isBtoT[0]),
    .io_req_handled_by_this_entry                     (ent_req_handled[0]),
    .io_forwardInfo_inflight                          (ent_fwd[0].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[0].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[0].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[0].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[0].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[0].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[0].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[0].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[0].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[0].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[0].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[0].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[0].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[0].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[0]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[0]),
    .io_matched                                       (ent_matched[0]),
    .io_l1Miss                                        (ent_l1Miss[0]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[0])
  );
  MissEntry entries_1 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd1),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[1]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[1]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[1]),
    .io_primary_ready                                 (ent_primary_ready[1]),
    .io_secondary_ready                               (ent_secondary_ready[1]),
    .io_secondary_reject                              (ent_secondary_reject[1]),
    .io_mem_acquire_ready                             (ent_acq_ready[1]),
    .io_mem_acquire_valid                             (ent_acq_valid[1]),
    .io_mem_acquire_bits_opcode                       (ent_acq[1].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[1].param),
    .io_mem_acquire_bits_source                       (ent_acq[1].source),
    .io_mem_acquire_bits_address                      (ent_acq[1].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[1].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[1].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[1].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[1].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[1].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[1]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[1]),
    .io_mem_finish_valid                              (ent_finish_valid[1]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[1]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[1][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[1][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[1][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[1][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[1][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[1][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[1][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[1][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[1][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[1][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[1][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[1][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[1]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[1]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[1]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[1]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[1]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[1]),
    .io_main_pipe_req_ready                           (arb_in_ready[1]),
    .io_main_pipe_req_valid                           (ent_mp_valid[1]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[1]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[1]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[1]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[1]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[1]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[1]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[1]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[1]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[1]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[1]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[1]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[1]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[1]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[1]),
    .io_main_pipe_resp                                (ent_mp_resp[1]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[1]),
    .io_main_pipe_replay                              (ent_mp_replay[1]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[1]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[1]),
    .io_refill_info_bits_store_data                   (ent_refill_info[1].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[1].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[1].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[1].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[1]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[1]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[1]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[1]),
    .io_req_vaddr_bits                                (ent_vaddr[1]),
    .io_req_isBtoT                                    (ent_isBtoT[1]),
    .io_req_handled_by_this_entry                     (ent_req_handled[1]),
    .io_forwardInfo_inflight                          (ent_fwd[1].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[1].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[1].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[1].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[1].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[1].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[1].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[1].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[1].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[1].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[1].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[1].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[1].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[1].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[1]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[1]),
    .io_matched                                       (ent_matched[1]),
    .io_l1Miss                                        (ent_l1Miss[1]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[1])
  );
  MissEntry entries_2 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd2),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[2]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[2]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[2]),
    .io_primary_ready                                 (ent_primary_ready[2]),
    .io_secondary_ready                               (ent_secondary_ready[2]),
    .io_secondary_reject                              (ent_secondary_reject[2]),
    .io_mem_acquire_ready                             (ent_acq_ready[2]),
    .io_mem_acquire_valid                             (ent_acq_valid[2]),
    .io_mem_acquire_bits_opcode                       (ent_acq[2].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[2].param),
    .io_mem_acquire_bits_source                       (ent_acq[2].source),
    .io_mem_acquire_bits_address                      (ent_acq[2].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[2].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[2].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[2].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[2].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[2].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[2]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[2]),
    .io_mem_finish_valid                              (ent_finish_valid[2]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[2]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[2][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[2][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[2][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[2][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[2][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[2][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[2][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[2][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[2][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[2][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[2][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[2][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[2]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[2]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[2]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[2]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[2]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[2]),
    .io_main_pipe_req_ready                           (arb_in_ready[2]),
    .io_main_pipe_req_valid                           (ent_mp_valid[2]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[2]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[2]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[2]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[2]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[2]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[2]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[2]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[2]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[2]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[2]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[2]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[2]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[2]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[2]),
    .io_main_pipe_resp                                (ent_mp_resp[2]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[2]),
    .io_main_pipe_replay                              (ent_mp_replay[2]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[2]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[2]),
    .io_refill_info_bits_store_data                   (ent_refill_info[2].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[2].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[2].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[2].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[2]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[2]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[2]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[2]),
    .io_req_vaddr_bits                                (ent_vaddr[2]),
    .io_req_isBtoT                                    (ent_isBtoT[2]),
    .io_req_handled_by_this_entry                     (ent_req_handled[2]),
    .io_forwardInfo_inflight                          (ent_fwd[2].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[2].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[2].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[2].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[2].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[2].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[2].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[2].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[2].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[2].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[2].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[2].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[2].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[2].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[2]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[2]),
    .io_matched                                       (ent_matched[2]),
    .io_l1Miss                                        (ent_l1Miss[2]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[2])
  );
  MissEntry entries_3 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd3),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[3]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[3]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[3]),
    .io_primary_ready                                 (ent_primary_ready[3]),
    .io_secondary_ready                               (ent_secondary_ready[3]),
    .io_secondary_reject                              (ent_secondary_reject[3]),
    .io_mem_acquire_ready                             (ent_acq_ready[3]),
    .io_mem_acquire_valid                             (ent_acq_valid[3]),
    .io_mem_acquire_bits_opcode                       (ent_acq[3].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[3].param),
    .io_mem_acquire_bits_source                       (ent_acq[3].source),
    .io_mem_acquire_bits_address                      (ent_acq[3].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[3].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[3].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[3].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[3].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[3].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[3]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[3]),
    .io_mem_finish_valid                              (ent_finish_valid[3]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[3]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[3][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[3][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[3][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[3][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[3][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[3][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[3][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[3][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[3][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[3][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[3][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[3][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[3]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[3]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[3]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[3]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[3]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[3]),
    .io_main_pipe_req_ready                           (arb_in_ready[3]),
    .io_main_pipe_req_valid                           (ent_mp_valid[3]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[3]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[3]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[3]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[3]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[3]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[3]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[3]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[3]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[3]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[3]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[3]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[3]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[3]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[3]),
    .io_main_pipe_resp                                (ent_mp_resp[3]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[3]),
    .io_main_pipe_replay                              (ent_mp_replay[3]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[3]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[3]),
    .io_refill_info_bits_store_data                   (ent_refill_info[3].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[3].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[3].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[3].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[3]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[3]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[3]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[3]),
    .io_req_vaddr_bits                                (ent_vaddr[3]),
    .io_req_isBtoT                                    (ent_isBtoT[3]),
    .io_req_handled_by_this_entry                     (ent_req_handled[3]),
    .io_forwardInfo_inflight                          (ent_fwd[3].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[3].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[3].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[3].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[3].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[3].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[3].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[3].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[3].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[3].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[3].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[3].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[3].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[3].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[3]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[3]),
    .io_matched                                       (ent_matched[3]),
    .io_l1Miss                                        (ent_l1Miss[3]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[3])
  );
  MissEntry entries_4 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd4),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[4]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[4]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[4]),
    .io_primary_ready                                 (ent_primary_ready[4]),
    .io_secondary_ready                               (ent_secondary_ready[4]),
    .io_secondary_reject                              (ent_secondary_reject[4]),
    .io_mem_acquire_ready                             (ent_acq_ready[4]),
    .io_mem_acquire_valid                             (ent_acq_valid[4]),
    .io_mem_acquire_bits_opcode                       (ent_acq[4].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[4].param),
    .io_mem_acquire_bits_source                       (ent_acq[4].source),
    .io_mem_acquire_bits_address                      (ent_acq[4].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[4].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[4].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[4].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[4].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[4].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[4]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[4]),
    .io_mem_finish_valid                              (ent_finish_valid[4]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[4]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[4][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[4][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[4][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[4][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[4][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[4][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[4][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[4][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[4][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[4][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[4][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[4][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[4]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[4]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[4]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[4]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[4]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[4]),
    .io_main_pipe_req_ready                           (arb_in_ready[4]),
    .io_main_pipe_req_valid                           (ent_mp_valid[4]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[4]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[4]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[4]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[4]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[4]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[4]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[4]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[4]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[4]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[4]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[4]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[4]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[4]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[4]),
    .io_main_pipe_resp                                (ent_mp_resp[4]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[4]),
    .io_main_pipe_replay                              (ent_mp_replay[4]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[4]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[4]),
    .io_refill_info_bits_store_data                   (ent_refill_info[4].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[4].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[4].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[4].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[4]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[4]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[4]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[4]),
    .io_req_vaddr_bits                                (ent_vaddr[4]),
    .io_req_isBtoT                                    (ent_isBtoT[4]),
    .io_req_handled_by_this_entry                     (ent_req_handled[4]),
    .io_forwardInfo_inflight                          (ent_fwd[4].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[4].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[4].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[4].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[4].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[4].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[4].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[4].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[4].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[4].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[4].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[4].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[4].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[4].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[4]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[4]),
    .io_matched                                       (ent_matched[4]),
    .io_l1Miss                                        (ent_l1Miss[4]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[4])
  );
  MissEntry entries_5 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd5),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[5]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[5]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[5]),
    .io_primary_ready                                 (ent_primary_ready[5]),
    .io_secondary_ready                               (ent_secondary_ready[5]),
    .io_secondary_reject                              (ent_secondary_reject[5]),
    .io_mem_acquire_ready                             (ent_acq_ready[5]),
    .io_mem_acquire_valid                             (ent_acq_valid[5]),
    .io_mem_acquire_bits_opcode                       (ent_acq[5].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[5].param),
    .io_mem_acquire_bits_source                       (ent_acq[5].source),
    .io_mem_acquire_bits_address                      (ent_acq[5].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[5].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[5].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[5].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[5].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[5].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[5]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[5]),
    .io_mem_finish_valid                              (ent_finish_valid[5]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[5]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[5][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[5][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[5][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[5][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[5][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[5][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[5][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[5][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[5][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[5][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[5][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[5][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[5]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[5]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[5]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[5]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[5]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[5]),
    .io_main_pipe_req_ready                           (arb_in_ready[5]),
    .io_main_pipe_req_valid                           (ent_mp_valid[5]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[5]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[5]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[5]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[5]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[5]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[5]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[5]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[5]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[5]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[5]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[5]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[5]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[5]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[5]),
    .io_main_pipe_resp                                (ent_mp_resp[5]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[5]),
    .io_main_pipe_replay                              (ent_mp_replay[5]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[5]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[5]),
    .io_refill_info_bits_store_data                   (ent_refill_info[5].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[5].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[5].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[5].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[5]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[5]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[5]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[5]),
    .io_req_vaddr_bits                                (ent_vaddr[5]),
    .io_req_isBtoT                                    (ent_isBtoT[5]),
    .io_req_handled_by_this_entry                     (ent_req_handled[5]),
    .io_forwardInfo_inflight                          (ent_fwd[5].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[5].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[5].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[5].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[5].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[5].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[5].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[5].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[5].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[5].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[5].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[5].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[5].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[5].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[5]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[5]),
    .io_matched                                       (ent_matched[5]),
    .io_l1Miss                                        (ent_l1Miss[5]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[5])
  );
  MissEntry entries_6 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd6),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[6]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[6]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[6]),
    .io_primary_ready                                 (ent_primary_ready[6]),
    .io_secondary_ready                               (ent_secondary_ready[6]),
    .io_secondary_reject                              (ent_secondary_reject[6]),
    .io_mem_acquire_ready                             (ent_acq_ready[6]),
    .io_mem_acquire_valid                             (ent_acq_valid[6]),
    .io_mem_acquire_bits_opcode                       (ent_acq[6].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[6].param),
    .io_mem_acquire_bits_source                       (ent_acq[6].source),
    .io_mem_acquire_bits_address                      (ent_acq[6].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[6].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[6].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[6].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[6].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[6].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[6]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[6]),
    .io_mem_finish_valid                              (ent_finish_valid[6]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[6]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[6][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[6][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[6][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[6][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[6][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[6][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[6][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[6][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[6][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[6][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[6][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[6][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[6]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[6]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[6]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[6]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[6]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[6]),
    .io_main_pipe_req_ready                           (arb_in_ready[6]),
    .io_main_pipe_req_valid                           (ent_mp_valid[6]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[6]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[6]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[6]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[6]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[6]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[6]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[6]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[6]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[6]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[6]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[6]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[6]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[6]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[6]),
    .io_main_pipe_resp                                (ent_mp_resp[6]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[6]),
    .io_main_pipe_replay                              (ent_mp_replay[6]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[6]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[6]),
    .io_refill_info_bits_store_data                   (ent_refill_info[6].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[6].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[6].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[6].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[6]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[6]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[6]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[6]),
    .io_req_vaddr_bits                                (ent_vaddr[6]),
    .io_req_isBtoT                                    (ent_isBtoT[6]),
    .io_req_handled_by_this_entry                     (ent_req_handled[6]),
    .io_forwardInfo_inflight                          (ent_fwd[6].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[6].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[6].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[6].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[6].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[6].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[6].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[6].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[6].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[6].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[6].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[6].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[6].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[6].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[6]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[6]),
    .io_matched                                       (ent_matched[6]),
    .io_l1Miss                                        (ent_l1Miss[6]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[6])
  );
  MissEntry entries_7 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd7),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[7]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[7]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[7]),
    .io_primary_ready                                 (ent_primary_ready[7]),
    .io_secondary_ready                               (ent_secondary_ready[7]),
    .io_secondary_reject                              (ent_secondary_reject[7]),
    .io_mem_acquire_ready                             (ent_acq_ready[7]),
    .io_mem_acquire_valid                             (ent_acq_valid[7]),
    .io_mem_acquire_bits_opcode                       (ent_acq[7].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[7].param),
    .io_mem_acquire_bits_source                       (ent_acq[7].source),
    .io_mem_acquire_bits_address                      (ent_acq[7].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[7].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[7].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[7].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[7].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[7].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[7]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[7]),
    .io_mem_finish_valid                              (ent_finish_valid[7]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[7]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[7][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[7][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[7][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[7][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[7][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[7][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[7][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[7][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[7][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[7][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[7][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[7][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[7]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[7]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[7]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[7]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[7]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[7]),
    .io_main_pipe_req_ready                           (arb_in_ready[7]),
    .io_main_pipe_req_valid                           (ent_mp_valid[7]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[7]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[7]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[7]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[7]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[7]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[7]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[7]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[7]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[7]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[7]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[7]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[7]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[7]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[7]),
    .io_main_pipe_resp                                (ent_mp_resp[7]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[7]),
    .io_main_pipe_replay                              (ent_mp_replay[7]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[7]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[7]),
    .io_refill_info_bits_store_data                   (ent_refill_info[7].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[7].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[7].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[7].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[7]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[7]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[7]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[7]),
    .io_req_vaddr_bits                                (ent_vaddr[7]),
    .io_req_isBtoT                                    (ent_isBtoT[7]),
    .io_req_handled_by_this_entry                     (ent_req_handled[7]),
    .io_forwardInfo_inflight                          (ent_fwd[7].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[7].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[7].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[7].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[7].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[7].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[7].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[7].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[7].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[7].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[7].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[7].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[7].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[7].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[7]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[7]),
    .io_matched                                       (ent_matched[7]),
    .io_l1Miss                                        (ent_l1Miss[7]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[7])
  );
  MissEntry entries_8 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd8),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[8]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[8]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[8]),
    .io_primary_ready                                 (ent_primary_ready[8]),
    .io_secondary_ready                               (ent_secondary_ready[8]),
    .io_secondary_reject                              (ent_secondary_reject[8]),
    .io_mem_acquire_ready                             (ent_acq_ready[8]),
    .io_mem_acquire_valid                             (ent_acq_valid[8]),
    .io_mem_acquire_bits_opcode                       (ent_acq[8].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[8].param),
    .io_mem_acquire_bits_source                       (ent_acq[8].source),
    .io_mem_acquire_bits_address                      (ent_acq[8].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[8].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[8].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[8].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[8].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[8].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[8]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[8]),
    .io_mem_finish_valid                              (ent_finish_valid[8]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[8]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[8][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[8][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[8][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[8][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[8][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[8][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[8][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[8][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[8][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[8][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[8][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[8][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[8]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[8]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[8]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[8]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[8]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[8]),
    .io_main_pipe_req_ready                           (arb_in_ready[8]),
    .io_main_pipe_req_valid                           (ent_mp_valid[8]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[8]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[8]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[8]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[8]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[8]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[8]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[8]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[8]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[8]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[8]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[8]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[8]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[8]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[8]),
    .io_main_pipe_resp                                (ent_mp_resp[8]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[8]),
    .io_main_pipe_replay                              (ent_mp_replay[8]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[8]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[8]),
    .io_refill_info_bits_store_data                   (ent_refill_info[8].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[8].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[8].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[8].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[8]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[8]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[8]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[8]),
    .io_req_vaddr_bits                                (ent_vaddr[8]),
    .io_req_isBtoT                                    (ent_isBtoT[8]),
    .io_req_handled_by_this_entry                     (ent_req_handled[8]),
    .io_forwardInfo_inflight                          (ent_fwd[8].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[8].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[8].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[8].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[8].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[8].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[8].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[8].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[8].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[8].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[8].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[8].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[8].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[8].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[8]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[8]),
    .io_matched                                       (ent_matched[8]),
    .io_l1Miss                                        (ent_l1Miss[8]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[8])
  );
  MissEntry entries_9 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd9),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[9]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[9]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[9]),
    .io_primary_ready                                 (ent_primary_ready[9]),
    .io_secondary_ready                               (ent_secondary_ready[9]),
    .io_secondary_reject                              (ent_secondary_reject[9]),
    .io_mem_acquire_ready                             (ent_acq_ready[9]),
    .io_mem_acquire_valid                             (ent_acq_valid[9]),
    .io_mem_acquire_bits_opcode                       (ent_acq[9].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[9].param),
    .io_mem_acquire_bits_source                       (ent_acq[9].source),
    .io_mem_acquire_bits_address                      (ent_acq[9].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[9].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[9].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[9].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[9].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[9].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[9]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[9]),
    .io_mem_finish_valid                              (ent_finish_valid[9]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[9]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[9][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[9][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[9][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[9][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[9][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[9][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[9][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[9][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[9][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[9][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[9][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[9][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[9]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[9]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[9]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[9]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[9]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[9]),
    .io_main_pipe_req_ready                           (arb_in_ready[9]),
    .io_main_pipe_req_valid                           (ent_mp_valid[9]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[9]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[9]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[9]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[9]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[9]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[9]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[9]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[9]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[9]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[9]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[9]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[9]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[9]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[9]),
    .io_main_pipe_resp                                (ent_mp_resp[9]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[9]),
    .io_main_pipe_replay                              (ent_mp_replay[9]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[9]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[9]),
    .io_refill_info_bits_store_data                   (ent_refill_info[9].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[9].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[9].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[9].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[9]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[9]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[9]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[9]),
    .io_req_vaddr_bits                                (ent_vaddr[9]),
    .io_req_isBtoT                                    (ent_isBtoT[9]),
    .io_req_handled_by_this_entry                     (ent_req_handled[9]),
    .io_forwardInfo_inflight                          (ent_fwd[9].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[9].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[9].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[9].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[9].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[9].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[9].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[9].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[9].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[9].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[9].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[9].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[9].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[9].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[9]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[9]),
    .io_matched                                       (ent_matched[9]),
    .io_l1Miss                                        (ent_l1Miss[9]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[9])
  );
  MissEntry entries_10 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd10),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[10]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[10]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[10]),
    .io_primary_ready                                 (ent_primary_ready[10]),
    .io_secondary_ready                               (ent_secondary_ready[10]),
    .io_secondary_reject                              (ent_secondary_reject[10]),
    .io_mem_acquire_ready                             (ent_acq_ready[10]),
    .io_mem_acquire_valid                             (ent_acq_valid[10]),
    .io_mem_acquire_bits_opcode                       (ent_acq[10].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[10].param),
    .io_mem_acquire_bits_source                       (ent_acq[10].source),
    .io_mem_acquire_bits_address                      (ent_acq[10].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[10].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[10].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[10].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[10].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[10].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[10]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[10]),
    .io_mem_finish_valid                              (ent_finish_valid[10]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[10]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[10][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[10][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[10][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[10][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[10][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[10][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[10][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[10][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[10][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[10][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[10][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[10][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[10]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[10]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[10]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[10]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[10]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[10]),
    .io_main_pipe_req_ready                           (arb_in_ready[10]),
    .io_main_pipe_req_valid                           (ent_mp_valid[10]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[10]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[10]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[10]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[10]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[10]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[10]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[10]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[10]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[10]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[10]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[10]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[10]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[10]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[10]),
    .io_main_pipe_resp                                (ent_mp_resp[10]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[10]),
    .io_main_pipe_replay                              (ent_mp_replay[10]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[10]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[10]),
    .io_refill_info_bits_store_data                   (ent_refill_info[10].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[10].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[10].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[10].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[10]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[10]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[10]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[10]),
    .io_req_vaddr_bits                                (ent_vaddr[10]),
    .io_req_isBtoT                                    (ent_isBtoT[10]),
    .io_req_handled_by_this_entry                     (ent_req_handled[10]),
    .io_forwardInfo_inflight                          (ent_fwd[10].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[10].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[10].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[10].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[10].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[10].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[10].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[10].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[10].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[10].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[10].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[10].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[10].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[10].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[10]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[10]),
    .io_matched                                       (ent_matched[10]),
    .io_l1Miss                                        (ent_l1Miss[10]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[10])
  );
  MissEntry entries_11 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd11),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[11]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[11]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[11]),
    .io_primary_ready                                 (ent_primary_ready[11]),
    .io_secondary_ready                               (ent_secondary_ready[11]),
    .io_secondary_reject                              (ent_secondary_reject[11]),
    .io_mem_acquire_ready                             (ent_acq_ready[11]),
    .io_mem_acquire_valid                             (ent_acq_valid[11]),
    .io_mem_acquire_bits_opcode                       (ent_acq[11].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[11].param),
    .io_mem_acquire_bits_source                       (ent_acq[11].source),
    .io_mem_acquire_bits_address                      (ent_acq[11].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[11].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[11].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[11].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[11].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[11].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[11]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[11]),
    .io_mem_finish_valid                              (ent_finish_valid[11]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[11]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[11][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[11][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[11][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[11][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[11][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[11][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[11][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[11][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[11][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[11][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[11][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[11][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[11]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[11]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[11]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[11]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[11]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[11]),
    .io_main_pipe_req_ready                           (arb_in_ready[11]),
    .io_main_pipe_req_valid                           (ent_mp_valid[11]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[11]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[11]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[11]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[11]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[11]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[11]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[11]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[11]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[11]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[11]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[11]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[11]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[11]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[11]),
    .io_main_pipe_resp                                (ent_mp_resp[11]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[11]),
    .io_main_pipe_replay                              (ent_mp_replay[11]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[11]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[11]),
    .io_refill_info_bits_store_data                   (ent_refill_info[11].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[11].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[11].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[11].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[11]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[11]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[11]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[11]),
    .io_req_vaddr_bits                                (ent_vaddr[11]),
    .io_req_isBtoT                                    (ent_isBtoT[11]),
    .io_req_handled_by_this_entry                     (ent_req_handled[11]),
    .io_forwardInfo_inflight                          (ent_fwd[11].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[11].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[11].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[11].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[11].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[11].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[11].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[11].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[11].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[11].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[11].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[11].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[11].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[11].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[11]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[11]),
    .io_matched                                       (ent_matched[11]),
    .io_l1Miss                                        (ent_l1Miss[11]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[11])
  );
  MissEntry entries_12 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd12),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[12]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[12]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[12]),
    .io_primary_ready                                 (ent_primary_ready[12]),
    .io_secondary_ready                               (ent_secondary_ready[12]),
    .io_secondary_reject                              (ent_secondary_reject[12]),
    .io_mem_acquire_ready                             (ent_acq_ready[12]),
    .io_mem_acquire_valid                             (ent_acq_valid[12]),
    .io_mem_acquire_bits_opcode                       (ent_acq[12].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[12].param),
    .io_mem_acquire_bits_source                       (ent_acq[12].source),
    .io_mem_acquire_bits_address                      (ent_acq[12].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[12].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[12].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[12].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[12].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[12].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[12]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[12]),
    .io_mem_finish_valid                              (ent_finish_valid[12]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[12]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[12][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[12][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[12][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[12][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[12][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[12][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[12][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[12][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[12][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[12][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[12][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[12][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[12]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[12]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[12]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[12]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[12]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[12]),
    .io_main_pipe_req_ready                           (arb_in_ready[12]),
    .io_main_pipe_req_valid                           (ent_mp_valid[12]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[12]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[12]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[12]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[12]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[12]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[12]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[12]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[12]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[12]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[12]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[12]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[12]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[12]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[12]),
    .io_main_pipe_resp                                (ent_mp_resp[12]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[12]),
    .io_main_pipe_replay                              (ent_mp_replay[12]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[12]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[12]),
    .io_refill_info_bits_store_data                   (ent_refill_info[12].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[12].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[12].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[12].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[12]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[12]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[12]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[12]),
    .io_req_vaddr_bits                                (ent_vaddr[12]),
    .io_req_isBtoT                                    (ent_isBtoT[12]),
    .io_req_handled_by_this_entry                     (ent_req_handled[12]),
    .io_forwardInfo_inflight                          (ent_fwd[12].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[12].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[12].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[12].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[12].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[12].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[12].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[12].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[12].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[12].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[12].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[12].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[12].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[12].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[12]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[12]),
    .io_matched                                       (ent_matched[12]),
    .io_l1Miss                                        (ent_l1Miss[12]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[12])
  );
  MissEntry entries_13 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd13),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[13]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[13]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[13]),
    .io_primary_ready                                 (ent_primary_ready[13]),
    .io_secondary_ready                               (ent_secondary_ready[13]),
    .io_secondary_reject                              (ent_secondary_reject[13]),
    .io_mem_acquire_ready                             (ent_acq_ready[13]),
    .io_mem_acquire_valid                             (ent_acq_valid[13]),
    .io_mem_acquire_bits_opcode                       (ent_acq[13].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[13].param),
    .io_mem_acquire_bits_source                       (ent_acq[13].source),
    .io_mem_acquire_bits_address                      (ent_acq[13].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[13].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[13].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[13].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[13].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[13].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[13]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[13]),
    .io_mem_finish_valid                              (ent_finish_valid[13]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[13]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[13][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[13][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[13][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[13][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[13][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[13][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[13][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[13][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[13][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[13][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[13][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[13][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[13]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[13]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[13]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[13]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[13]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[13]),
    .io_main_pipe_req_ready                           (arb_in_ready[13]),
    .io_main_pipe_req_valid                           (ent_mp_valid[13]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[13]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[13]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[13]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[13]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[13]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[13]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[13]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[13]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[13]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[13]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[13]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[13]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[13]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[13]),
    .io_main_pipe_resp                                (ent_mp_resp[13]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[13]),
    .io_main_pipe_replay                              (ent_mp_replay[13]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[13]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[13]),
    .io_refill_info_bits_store_data                   (ent_refill_info[13].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[13].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[13].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[13].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[13]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[13]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[13]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[13]),
    .io_req_vaddr_bits                                (ent_vaddr[13]),
    .io_req_isBtoT                                    (ent_isBtoT[13]),
    .io_req_handled_by_this_entry                     (ent_req_handled[13]),
    .io_forwardInfo_inflight                          (ent_fwd[13].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[13].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[13].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[13].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[13].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[13].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[13].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[13].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[13].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[13].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[13].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[13].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[13].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[13].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[13]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[13]),
    .io_matched                                       (ent_matched[13]),
    .io_l1Miss                                        (ent_l1Miss[13]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[13])
  );
  MissEntry entries_14 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd14),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[14]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[14]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[14]),
    .io_primary_ready                                 (ent_primary_ready[14]),
    .io_secondary_ready                               (ent_secondary_ready[14]),
    .io_secondary_reject                              (ent_secondary_reject[14]),
    .io_mem_acquire_ready                             (ent_acq_ready[14]),
    .io_mem_acquire_valid                             (ent_acq_valid[14]),
    .io_mem_acquire_bits_opcode                       (ent_acq[14].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[14].param),
    .io_mem_acquire_bits_source                       (ent_acq[14].source),
    .io_mem_acquire_bits_address                      (ent_acq[14].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[14].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[14].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[14].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[14].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[14].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[14]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[14]),
    .io_mem_finish_valid                              (ent_finish_valid[14]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[14]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[14][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[14][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[14][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[14][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[14][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[14][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[14][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[14][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[14][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[14][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[14][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[14][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[14]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[14]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[14]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[14]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[14]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[14]),
    .io_main_pipe_req_ready                           (arb_in_ready[14]),
    .io_main_pipe_req_valid                           (ent_mp_valid[14]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[14]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[14]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[14]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[14]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[14]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[14]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[14]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[14]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[14]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[14]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[14]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[14]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[14]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[14]),
    .io_main_pipe_resp                                (ent_mp_resp[14]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[14]),
    .io_main_pipe_replay                              (ent_mp_replay[14]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[14]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[14]),
    .io_refill_info_bits_store_data                   (ent_refill_info[14].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[14].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[14].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[14].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[14]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[14]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[14]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[14]),
    .io_req_vaddr_bits                                (ent_vaddr[14]),
    .io_req_isBtoT                                    (ent_isBtoT[14]),
    .io_req_handled_by_this_entry                     (ent_req_handled[14]),
    .io_forwardInfo_inflight                          (ent_fwd[14].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[14].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[14].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[14].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[14].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[14].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[14].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[14].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[14].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[14].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[14].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[14].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[14].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[14].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[14]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[14]),
    .io_matched                                       (ent_matched[14]),
    .io_l1Miss                                        (ent_l1Miss[14]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[14])
  );
  MissEntry entries_15 (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_id                                            (4'd15),
    .io_req_valid                                     (io_req_valid),
    .io_req_bits_source                               (io_req_bits_source),
    .io_req_bits_addr                                 (io_req_bits_addr),
    .io_req_bits_vaddr                                (io_req_bits_vaddr),
    .io_req_bits_cancel                               (io_req_bits_cancel),
    .io_wbq_block_miss_req                            (io_wbq_block_miss_req),
    .io_miss_req_pipe_reg_req_source                  (pipe_s.source),
    .io_miss_req_pipe_reg_req_pf_source               (pipe_s.pf_source),
    .io_miss_req_pipe_reg_req_cmd                     (pipe_s.cmd),
    .io_miss_req_pipe_reg_req_addr                    (pipe_s.addr),
    .io_miss_req_pipe_reg_req_vaddr                   (pipe_s.vaddr),
    .io_miss_req_pipe_reg_req_full_overwrite          (pipe_s.full_overwrite),
    .io_miss_req_pipe_reg_req_word_idx                (pipe_s.word_idx),
    .io_miss_req_pipe_reg_req_amo_data                (pipe_s.amo_data),
    .io_miss_req_pipe_reg_req_amo_mask                (pipe_s.amo_mask),
    .io_miss_req_pipe_reg_req_amo_cmp                 (pipe_s.amo_cmp),
    .io_miss_req_pipe_reg_req_req_coh_state           (pipe_s.req_coh_state),
    .io_miss_req_pipe_reg_req_id                      (pipe_s.id),
    .io_miss_req_pipe_reg_req_isBtoT                  (pipe_s.isBtoT),
    .io_miss_req_pipe_reg_req_occupy_way              (pipe_s.occupy_way),
    .io_miss_req_pipe_reg_req_store_data              (pipe_s.store_data),
    .io_miss_req_pipe_reg_req_store_mask              (pipe_s.store_mask),
    .io_miss_req_pipe_reg_merge                       (ent_pipe_merge[15]),
    .io_miss_req_pipe_reg_alloc                       (ent_pipe_alloc[15]),
    .io_miss_req_pipe_reg_cancel                      (pipe_cancel_s),
    .io_primary_valid                                 (ent_primary_valid[15]),
    .io_primary_ready                                 (ent_primary_ready[15]),
    .io_secondary_ready                               (ent_secondary_ready[15]),
    .io_secondary_reject                              (ent_secondary_reject[15]),
    .io_mem_acquire_ready                             (ent_acq_ready[15]),
    .io_mem_acquire_valid                             (ent_acq_valid[15]),
    .io_mem_acquire_bits_opcode                       (ent_acq[15].opcode),
    .io_mem_acquire_bits_param                        (ent_acq[15].param),
    .io_mem_acquire_bits_source                       (ent_acq[15].source),
    .io_mem_acquire_bits_address                      (ent_acq[15].address),
    .io_mem_acquire_bits_user_alias                   (ent_acq[15].user_alias),
    .io_mem_acquire_bits_user_vaddr                   (ent_acq[15].user_vaddr),
    .io_mem_acquire_bits_user_reqSource               (ent_acq[15].user_reqSource),
    .io_mem_acquire_bits_user_needHint                (ent_acq[15].user_needHint),
    .io_mem_acquire_bits_echo_isKeyword               (ent_acq[15].echo_isKeyword),
    .io_mem_grant_valid                               (ent_grant_valid[15]),
    .io_mem_grant_bits_opcode                         (io_mem_grant_bits_opcode),
    .io_mem_grant_bits_param                          (io_mem_grant_bits_param),
    .io_mem_grant_bits_size                           (io_mem_grant_bits_size),
    .io_mem_grant_bits_sink                           (io_mem_grant_bits_sink),
    .io_mem_grant_bits_denied                         (io_mem_grant_bits_denied),
    .io_mem_grant_bits_data                           (io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt                        (io_mem_grant_bits_corrupt),
    .io_mem_finish_ready                              (ent_finish_ready[15]),
    .io_mem_finish_valid                              (ent_finish_valid[15]),
    .io_mem_finish_bits_sink                          (ent_finish_sink[15]),
    .io_queryME_0_req_bits_source                     (io_queryMQ_0_req_bits_source),
    .io_queryME_0_req_bits_addr                       (io_queryMQ_0_req_bits_addr),
    .io_queryME_0_req_bits_vaddr                      (io_queryMQ_0_req_bits_vaddr),
    .io_queryME_0_primary_ready                       (ent_query_primary_ready[15][0]),
    .io_queryME_0_secondary_ready                     (ent_query_secondary_ready[15][0]),
    .io_queryME_0_secondary_reject                    (ent_query_secondary_reject[15][0]),
    .io_queryME_1_req_bits_source                     (io_queryMQ_1_req_bits_source),
    .io_queryME_1_req_bits_addr                       (io_queryMQ_1_req_bits_addr),
    .io_queryME_1_req_bits_vaddr                      (io_queryMQ_1_req_bits_vaddr),
    .io_queryME_1_primary_ready                       (ent_query_primary_ready[15][1]),
    .io_queryME_1_secondary_ready                     (ent_query_secondary_ready[15][1]),
    .io_queryME_1_secondary_reject                    (ent_query_secondary_reject[15][1]),
    .io_queryME_2_req_bits_source                     (io_queryMQ_2_req_bits_source),
    .io_queryME_2_req_bits_addr                       (io_queryMQ_2_req_bits_addr),
    .io_queryME_2_req_bits_vaddr                      (io_queryMQ_2_req_bits_vaddr),
    .io_queryME_2_primary_ready                       (ent_query_primary_ready[15][2]),
    .io_queryME_2_secondary_ready                     (ent_query_secondary_ready[15][2]),
    .io_queryME_2_secondary_reject                    (ent_query_secondary_reject[15][2]),
    .io_queryME_3_req_bits_source                     (io_queryMQ_3_req_bits_source),
    .io_queryME_3_req_bits_addr                       (io_queryMQ_3_req_bits_addr),
    .io_queryME_3_req_bits_vaddr                      (io_queryMQ_3_req_bits_vaddr),
    .io_queryME_3_primary_ready                       (ent_query_primary_ready[15][3]),
    .io_queryME_3_secondary_ready                     (ent_query_secondary_ready[15][3]),
    .io_queryME_3_secondary_reject                    (ent_query_secondary_reject[15][3]),
    .io_refill_to_ldq_valid                           (ent_ldq_valid[15]),
    .io_refill_to_ldq_bits_addr                       (ent_ldq_addr[15]),
    .io_refill_to_ldq_bits_data                       (),
    .io_refill_to_ldq_bits_error                      (),
    .io_refill_to_ldq_bits_data_raw                   (ent_ldq_data_raw[15]),
    .io_refill_to_ldq_bits_hasdata                    (ent_ldq_hasdata[15]),
    .io_refill_to_ldq_bits_refill_done                (ent_ldq_refill_done[15]),
    .io_refill_to_ldq_bits_id                         (),
    .io_l2_hint_valid                                 (ent_l2_hint_valid[15]),
    .io_main_pipe_req_ready                           (arb_in_ready[15]),
    .io_main_pipe_req_valid                           (ent_mp_valid[15]),
    .io_main_pipe_req_bits_miss_id                    (ent_mp_miss_id[15]),
    .io_main_pipe_req_bits_occupy_way                 (ent_mp_occupy_way[15]),
    .io_main_pipe_req_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[15]),
    .io_main_pipe_req_bits_source                     (ent_mp_source[15]),
    .io_main_pipe_req_bits_cmd                        (ent_mp_cmd[15]),
    .io_main_pipe_req_bits_vaddr                      (ent_mp_vaddr[15]),
    .io_main_pipe_req_bits_addr                       (ent_mp_addr[15]),
    .io_main_pipe_req_bits_word_idx                   (ent_mp_word_idx[15]),
    .io_main_pipe_req_bits_amo_data                   (ent_mp_amo_data[15]),
    .io_main_pipe_req_bits_amo_mask                   (ent_mp_amo_mask[15]),
    .io_main_pipe_req_bits_amo_cmp                    (ent_mp_amo_cmp[15]),
    .io_main_pipe_req_bits_pf_source                  (ent_mp_pf_source[15]),
    .io_main_pipe_req_bits_access                     (ent_mp_access[15]),
    .io_main_pipe_req_bits_id                         (ent_mp_id[15]),
    .io_main_pipe_resp                                (ent_mp_resp[15]),
    .io_main_pipe_refill_resp                         (ent_mp_refill_resp[15]),
    .io_main_pipe_replay                              (ent_mp_replay[15]),
    .io_main_pipe_evict_BtoT_way                      (ent_mp_evict_BtoT_way[15]),
    .io_main_pipe_next_evict_way                      (io_mainpipe_info_s2_next_evict_way),
    .io_refill_info_valid                             (ent_refill_info_valid[15]),
    .io_refill_info_bits_store_data                   (ent_refill_info[15].store_data),
    .io_refill_info_bits_miss_param                   (ent_refill_info[15].miss_param),
    .io_refill_info_bits_error_tl_denied              (ent_refill_info[15].tl_denied),
    .io_refill_info_bits_error_tl_corrupt             (ent_refill_info[15].tl_corrupt),
    .io_occupy_way                                    (ent_occupy_way[15]),
    .io_probe_req_bits_addr                           (io_probe_req_bits_addr),
    .io_probe_req_bits_vaddr                          (io_probe_req_bits_vaddr),
    .io_probe_block                                   (ent_probe_block[15]),
    .io_replace_req_bits_addr                         (io_replace_req_bits_addr),
    .io_replace_req_bits_vaddr                        (io_replace_req_bits_vaddr),
    .io_replace_block                                 (ent_replace_block[15]),
    .io_req_vaddr_valid                               (ent_vaddr_valid[15]),
    .io_req_vaddr_bits                                (ent_vaddr[15]),
    .io_req_isBtoT                                    (ent_isBtoT[15]),
    .io_req_handled_by_this_entry                     (ent_req_handled[15]),
    .io_forwardInfo_inflight                          (ent_fwd[15].inflight),
    .io_forwardInfo_paddr                             (ent_fwd[15].paddr),
    .io_forwardInfo_raw_data_0                        (ent_fwd[15].raw_data[0]),
    .io_forwardInfo_raw_data_1                        (ent_fwd[15].raw_data[1]),
    .io_forwardInfo_raw_data_2                        (ent_fwd[15].raw_data[2]),
    .io_forwardInfo_raw_data_3                        (ent_fwd[15].raw_data[3]),
    .io_forwardInfo_raw_data_4                        (ent_fwd[15].raw_data[4]),
    .io_forwardInfo_raw_data_5                        (ent_fwd[15].raw_data[5]),
    .io_forwardInfo_raw_data_6                        (ent_fwd[15].raw_data[6]),
    .io_forwardInfo_raw_data_7                        (ent_fwd[15].raw_data[7]),
    .io_forwardInfo_firstbeat_valid                   (ent_fwd[15].firstbeat_valid),
    .io_forwardInfo_lastbeat_valid                    (ent_fwd[15].lastbeat_valid),
    .io_forwardInfo_denied                            (ent_fwd[15].denied),
    .io_forwardInfo_corrupt                           (ent_fwd[15].corrupt),
    .io_l2_pf_store_only                              (io_l2_pf_store_only),
    .io_acquire_fired_by_pipe_reg                     (acquire_fired_by_pipe_reg_s),
    .io_memSetPattenDetected                          (memset_pattern_detected_s),
    .io_perf_pending_prefetch                         (),
    .io_perf_pending_normal                           (),
    .io_rob_head_query_vaddr                          (io_debugTopDown_robHeadVaddr_bits),
    .io_rob_head_query_query_valid                    (io_debugTopDown_robHeadVaddr_valid),
    .io_rob_head_query_resp                           (ent_rob_head_resp[15]),
    .io_latency_monitor_load_miss_refilling           (),
    .io_latency_monitor_store_miss_refilling          (),
    .io_latency_monitor_amo_miss_refilling            (),
    .io_latency_monitor_pf_miss_refilling             (),
    .io_prefetch_info_late_prefetch                   (ent_late_prefetch[15]),
    .io_matched                                       (ent_matched[15]),
    .io_l1Miss                                        (ent_l1Miss[15]),
    .io_wfi_wfiReq                                    (io_wfi_wfiReq),
    .io_wfi_wfiSafe                                   (ent_wfi_safe[15])
  );
  CMOUnit cmo_unit (
    .clock                       (clock),
    .reset                       (reset),
    .io_req_ready                (io_cmo_req_ready),
    .io_req_valid                (io_cmo_req_valid),
    .io_req_bits_opcode          (io_cmo_req_bits_opcode),
    .io_req_bits_address         (io_cmo_req_bits_address),
    .io_req_chanA_ready          (cmo_a_ready_s),
    .io_req_chanA_valid          (cmo_a_valid_s),
    .io_req_chanA_bits_opcode    (cmo_a_opcode_s),
    .io_req_chanA_bits_address   (cmo_a_address_s),
    .io_resp_chanD_ready         (cmo_d_ready_s),
    .io_resp_chanD_valid         (cmo_d_valid_s),
    .io_resp_chanD_bits_denied   (io_mem_grant_bits_denied),
    .io_resp_chanD_bits_corrupt  (io_mem_grant_bits_corrupt),
    .io_resp_to_lsq_ready        (io_cmo_resp_ready),
    .io_resp_to_lsq_valid        (io_cmo_resp_valid),
    .io_resp_to_lsq_bits_denied  (io_cmo_resp_bits_denied),
    .io_resp_to_lsq_bits_corrupt (io_cmo_resp_bits_corrupt),
    .io_wfi_wfiReq               (io_wfi_wfiReq),
    .io_wfi_wfiSafe              (cmo_wfi_safe_s)
  );
  Arbiter16_MainPipeReq main_pipe_req_arb (
    .io_in_0_ready                            (arb_in_ready[0]),
    .io_in_0_valid                            (ent_mp_valid[0]),
    .io_in_0_bits_miss_id                     (ent_mp_miss_id[0]),
    .io_in_0_bits_occupy_way                  (ent_mp_occupy_way[0]),
    .io_in_0_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[0]),
    .io_in_0_bits_source                      (ent_mp_source[0]),
    .io_in_0_bits_cmd                         (ent_mp_cmd[0]),
    .io_in_0_bits_vaddr                       (ent_mp_vaddr[0]),
    .io_in_0_bits_addr                        (ent_mp_addr[0]),
    .io_in_0_bits_word_idx                    (ent_mp_word_idx[0]),
    .io_in_0_bits_amo_data                    (ent_mp_amo_data[0]),
    .io_in_0_bits_amo_mask                    (ent_mp_amo_mask[0]),
    .io_in_0_bits_amo_cmp                     (ent_mp_amo_cmp[0]),
    .io_in_0_bits_pf_source                   (ent_mp_pf_source[0]),
    .io_in_0_bits_access                      (ent_mp_access[0]),
    .io_in_0_bits_id                          (ent_mp_id[0]),
    .io_in_1_ready                            (arb_in_ready[1]),
    .io_in_1_valid                            (ent_mp_valid[1]),
    .io_in_1_bits_miss_id                     (ent_mp_miss_id[1]),
    .io_in_1_bits_occupy_way                  (ent_mp_occupy_way[1]),
    .io_in_1_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[1]),
    .io_in_1_bits_source                      (ent_mp_source[1]),
    .io_in_1_bits_cmd                         (ent_mp_cmd[1]),
    .io_in_1_bits_vaddr                       (ent_mp_vaddr[1]),
    .io_in_1_bits_addr                        (ent_mp_addr[1]),
    .io_in_1_bits_word_idx                    (ent_mp_word_idx[1]),
    .io_in_1_bits_amo_data                    (ent_mp_amo_data[1]),
    .io_in_1_bits_amo_mask                    (ent_mp_amo_mask[1]),
    .io_in_1_bits_amo_cmp                     (ent_mp_amo_cmp[1]),
    .io_in_1_bits_pf_source                   (ent_mp_pf_source[1]),
    .io_in_1_bits_access                      (ent_mp_access[1]),
    .io_in_1_bits_id                          (ent_mp_id[1]),
    .io_in_2_ready                            (arb_in_ready[2]),
    .io_in_2_valid                            (ent_mp_valid[2]),
    .io_in_2_bits_miss_id                     (ent_mp_miss_id[2]),
    .io_in_2_bits_occupy_way                  (ent_mp_occupy_way[2]),
    .io_in_2_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[2]),
    .io_in_2_bits_source                      (ent_mp_source[2]),
    .io_in_2_bits_cmd                         (ent_mp_cmd[2]),
    .io_in_2_bits_vaddr                       (ent_mp_vaddr[2]),
    .io_in_2_bits_addr                        (ent_mp_addr[2]),
    .io_in_2_bits_word_idx                    (ent_mp_word_idx[2]),
    .io_in_2_bits_amo_data                    (ent_mp_amo_data[2]),
    .io_in_2_bits_amo_mask                    (ent_mp_amo_mask[2]),
    .io_in_2_bits_amo_cmp                     (ent_mp_amo_cmp[2]),
    .io_in_2_bits_pf_source                   (ent_mp_pf_source[2]),
    .io_in_2_bits_access                      (ent_mp_access[2]),
    .io_in_2_bits_id                          (ent_mp_id[2]),
    .io_in_3_ready                            (arb_in_ready[3]),
    .io_in_3_valid                            (ent_mp_valid[3]),
    .io_in_3_bits_miss_id                     (ent_mp_miss_id[3]),
    .io_in_3_bits_occupy_way                  (ent_mp_occupy_way[3]),
    .io_in_3_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[3]),
    .io_in_3_bits_source                      (ent_mp_source[3]),
    .io_in_3_bits_cmd                         (ent_mp_cmd[3]),
    .io_in_3_bits_vaddr                       (ent_mp_vaddr[3]),
    .io_in_3_bits_addr                        (ent_mp_addr[3]),
    .io_in_3_bits_word_idx                    (ent_mp_word_idx[3]),
    .io_in_3_bits_amo_data                    (ent_mp_amo_data[3]),
    .io_in_3_bits_amo_mask                    (ent_mp_amo_mask[3]),
    .io_in_3_bits_amo_cmp                     (ent_mp_amo_cmp[3]),
    .io_in_3_bits_pf_source                   (ent_mp_pf_source[3]),
    .io_in_3_bits_access                      (ent_mp_access[3]),
    .io_in_3_bits_id                          (ent_mp_id[3]),
    .io_in_4_ready                            (arb_in_ready[4]),
    .io_in_4_valid                            (ent_mp_valid[4]),
    .io_in_4_bits_miss_id                     (ent_mp_miss_id[4]),
    .io_in_4_bits_occupy_way                  (ent_mp_occupy_way[4]),
    .io_in_4_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[4]),
    .io_in_4_bits_source                      (ent_mp_source[4]),
    .io_in_4_bits_cmd                         (ent_mp_cmd[4]),
    .io_in_4_bits_vaddr                       (ent_mp_vaddr[4]),
    .io_in_4_bits_addr                        (ent_mp_addr[4]),
    .io_in_4_bits_word_idx                    (ent_mp_word_idx[4]),
    .io_in_4_bits_amo_data                    (ent_mp_amo_data[4]),
    .io_in_4_bits_amo_mask                    (ent_mp_amo_mask[4]),
    .io_in_4_bits_amo_cmp                     (ent_mp_amo_cmp[4]),
    .io_in_4_bits_pf_source                   (ent_mp_pf_source[4]),
    .io_in_4_bits_access                      (ent_mp_access[4]),
    .io_in_4_bits_id                          (ent_mp_id[4]),
    .io_in_5_ready                            (arb_in_ready[5]),
    .io_in_5_valid                            (ent_mp_valid[5]),
    .io_in_5_bits_miss_id                     (ent_mp_miss_id[5]),
    .io_in_5_bits_occupy_way                  (ent_mp_occupy_way[5]),
    .io_in_5_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[5]),
    .io_in_5_bits_source                      (ent_mp_source[5]),
    .io_in_5_bits_cmd                         (ent_mp_cmd[5]),
    .io_in_5_bits_vaddr                       (ent_mp_vaddr[5]),
    .io_in_5_bits_addr                        (ent_mp_addr[5]),
    .io_in_5_bits_word_idx                    (ent_mp_word_idx[5]),
    .io_in_5_bits_amo_data                    (ent_mp_amo_data[5]),
    .io_in_5_bits_amo_mask                    (ent_mp_amo_mask[5]),
    .io_in_5_bits_amo_cmp                     (ent_mp_amo_cmp[5]),
    .io_in_5_bits_pf_source                   (ent_mp_pf_source[5]),
    .io_in_5_bits_access                      (ent_mp_access[5]),
    .io_in_5_bits_id                          (ent_mp_id[5]),
    .io_in_6_ready                            (arb_in_ready[6]),
    .io_in_6_valid                            (ent_mp_valid[6]),
    .io_in_6_bits_miss_id                     (ent_mp_miss_id[6]),
    .io_in_6_bits_occupy_way                  (ent_mp_occupy_way[6]),
    .io_in_6_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[6]),
    .io_in_6_bits_source                      (ent_mp_source[6]),
    .io_in_6_bits_cmd                         (ent_mp_cmd[6]),
    .io_in_6_bits_vaddr                       (ent_mp_vaddr[6]),
    .io_in_6_bits_addr                        (ent_mp_addr[6]),
    .io_in_6_bits_word_idx                    (ent_mp_word_idx[6]),
    .io_in_6_bits_amo_data                    (ent_mp_amo_data[6]),
    .io_in_6_bits_amo_mask                    (ent_mp_amo_mask[6]),
    .io_in_6_bits_amo_cmp                     (ent_mp_amo_cmp[6]),
    .io_in_6_bits_pf_source                   (ent_mp_pf_source[6]),
    .io_in_6_bits_access                      (ent_mp_access[6]),
    .io_in_6_bits_id                          (ent_mp_id[6]),
    .io_in_7_ready                            (arb_in_ready[7]),
    .io_in_7_valid                            (ent_mp_valid[7]),
    .io_in_7_bits_miss_id                     (ent_mp_miss_id[7]),
    .io_in_7_bits_occupy_way                  (ent_mp_occupy_way[7]),
    .io_in_7_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[7]),
    .io_in_7_bits_source                      (ent_mp_source[7]),
    .io_in_7_bits_cmd                         (ent_mp_cmd[7]),
    .io_in_7_bits_vaddr                       (ent_mp_vaddr[7]),
    .io_in_7_bits_addr                        (ent_mp_addr[7]),
    .io_in_7_bits_word_idx                    (ent_mp_word_idx[7]),
    .io_in_7_bits_amo_data                    (ent_mp_amo_data[7]),
    .io_in_7_bits_amo_mask                    (ent_mp_amo_mask[7]),
    .io_in_7_bits_amo_cmp                     (ent_mp_amo_cmp[7]),
    .io_in_7_bits_pf_source                   (ent_mp_pf_source[7]),
    .io_in_7_bits_access                      (ent_mp_access[7]),
    .io_in_7_bits_id                          (ent_mp_id[7]),
    .io_in_8_ready                            (arb_in_ready[8]),
    .io_in_8_valid                            (ent_mp_valid[8]),
    .io_in_8_bits_miss_id                     (ent_mp_miss_id[8]),
    .io_in_8_bits_occupy_way                  (ent_mp_occupy_way[8]),
    .io_in_8_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[8]),
    .io_in_8_bits_source                      (ent_mp_source[8]),
    .io_in_8_bits_cmd                         (ent_mp_cmd[8]),
    .io_in_8_bits_vaddr                       (ent_mp_vaddr[8]),
    .io_in_8_bits_addr                        (ent_mp_addr[8]),
    .io_in_8_bits_word_idx                    (ent_mp_word_idx[8]),
    .io_in_8_bits_amo_data                    (ent_mp_amo_data[8]),
    .io_in_8_bits_amo_mask                    (ent_mp_amo_mask[8]),
    .io_in_8_bits_amo_cmp                     (ent_mp_amo_cmp[8]),
    .io_in_8_bits_pf_source                   (ent_mp_pf_source[8]),
    .io_in_8_bits_access                      (ent_mp_access[8]),
    .io_in_8_bits_id                          (ent_mp_id[8]),
    .io_in_9_ready                            (arb_in_ready[9]),
    .io_in_9_valid                            (ent_mp_valid[9]),
    .io_in_9_bits_miss_id                     (ent_mp_miss_id[9]),
    .io_in_9_bits_occupy_way                  (ent_mp_occupy_way[9]),
    .io_in_9_bits_miss_fail_cause_evict_btot  (ent_mp_miss_fail_cause_evict_btot[9]),
    .io_in_9_bits_source                      (ent_mp_source[9]),
    .io_in_9_bits_cmd                         (ent_mp_cmd[9]),
    .io_in_9_bits_vaddr                       (ent_mp_vaddr[9]),
    .io_in_9_bits_addr                        (ent_mp_addr[9]),
    .io_in_9_bits_word_idx                    (ent_mp_word_idx[9]),
    .io_in_9_bits_amo_data                    (ent_mp_amo_data[9]),
    .io_in_9_bits_amo_mask                    (ent_mp_amo_mask[9]),
    .io_in_9_bits_amo_cmp                     (ent_mp_amo_cmp[9]),
    .io_in_9_bits_pf_source                   (ent_mp_pf_source[9]),
    .io_in_9_bits_access                      (ent_mp_access[9]),
    .io_in_9_bits_id                          (ent_mp_id[9]),
    .io_in_10_ready                           (arb_in_ready[10]),
    .io_in_10_valid                           (ent_mp_valid[10]),
    .io_in_10_bits_miss_id                    (ent_mp_miss_id[10]),
    .io_in_10_bits_occupy_way                 (ent_mp_occupy_way[10]),
    .io_in_10_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[10]),
    .io_in_10_bits_source                     (ent_mp_source[10]),
    .io_in_10_bits_cmd                        (ent_mp_cmd[10]),
    .io_in_10_bits_vaddr                      (ent_mp_vaddr[10]),
    .io_in_10_bits_addr                       (ent_mp_addr[10]),
    .io_in_10_bits_word_idx                   (ent_mp_word_idx[10]),
    .io_in_10_bits_amo_data                   (ent_mp_amo_data[10]),
    .io_in_10_bits_amo_mask                   (ent_mp_amo_mask[10]),
    .io_in_10_bits_amo_cmp                    (ent_mp_amo_cmp[10]),
    .io_in_10_bits_pf_source                  (ent_mp_pf_source[10]),
    .io_in_10_bits_access                     (ent_mp_access[10]),
    .io_in_10_bits_id                         (ent_mp_id[10]),
    .io_in_11_ready                           (arb_in_ready[11]),
    .io_in_11_valid                           (ent_mp_valid[11]),
    .io_in_11_bits_miss_id                    (ent_mp_miss_id[11]),
    .io_in_11_bits_occupy_way                 (ent_mp_occupy_way[11]),
    .io_in_11_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[11]),
    .io_in_11_bits_source                     (ent_mp_source[11]),
    .io_in_11_bits_cmd                        (ent_mp_cmd[11]),
    .io_in_11_bits_vaddr                      (ent_mp_vaddr[11]),
    .io_in_11_bits_addr                       (ent_mp_addr[11]),
    .io_in_11_bits_word_idx                   (ent_mp_word_idx[11]),
    .io_in_11_bits_amo_data                   (ent_mp_amo_data[11]),
    .io_in_11_bits_amo_mask                   (ent_mp_amo_mask[11]),
    .io_in_11_bits_amo_cmp                    (ent_mp_amo_cmp[11]),
    .io_in_11_bits_pf_source                  (ent_mp_pf_source[11]),
    .io_in_11_bits_access                     (ent_mp_access[11]),
    .io_in_11_bits_id                         (ent_mp_id[11]),
    .io_in_12_ready                           (arb_in_ready[12]),
    .io_in_12_valid                           (ent_mp_valid[12]),
    .io_in_12_bits_miss_id                    (ent_mp_miss_id[12]),
    .io_in_12_bits_occupy_way                 (ent_mp_occupy_way[12]),
    .io_in_12_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[12]),
    .io_in_12_bits_source                     (ent_mp_source[12]),
    .io_in_12_bits_cmd                        (ent_mp_cmd[12]),
    .io_in_12_bits_vaddr                      (ent_mp_vaddr[12]),
    .io_in_12_bits_addr                       (ent_mp_addr[12]),
    .io_in_12_bits_word_idx                   (ent_mp_word_idx[12]),
    .io_in_12_bits_amo_data                   (ent_mp_amo_data[12]),
    .io_in_12_bits_amo_mask                   (ent_mp_amo_mask[12]),
    .io_in_12_bits_amo_cmp                    (ent_mp_amo_cmp[12]),
    .io_in_12_bits_pf_source                  (ent_mp_pf_source[12]),
    .io_in_12_bits_access                     (ent_mp_access[12]),
    .io_in_12_bits_id                         (ent_mp_id[12]),
    .io_in_13_ready                           (arb_in_ready[13]),
    .io_in_13_valid                           (ent_mp_valid[13]),
    .io_in_13_bits_miss_id                    (ent_mp_miss_id[13]),
    .io_in_13_bits_occupy_way                 (ent_mp_occupy_way[13]),
    .io_in_13_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[13]),
    .io_in_13_bits_source                     (ent_mp_source[13]),
    .io_in_13_bits_cmd                        (ent_mp_cmd[13]),
    .io_in_13_bits_vaddr                      (ent_mp_vaddr[13]),
    .io_in_13_bits_addr                       (ent_mp_addr[13]),
    .io_in_13_bits_word_idx                   (ent_mp_word_idx[13]),
    .io_in_13_bits_amo_data                   (ent_mp_amo_data[13]),
    .io_in_13_bits_amo_mask                   (ent_mp_amo_mask[13]),
    .io_in_13_bits_amo_cmp                    (ent_mp_amo_cmp[13]),
    .io_in_13_bits_pf_source                  (ent_mp_pf_source[13]),
    .io_in_13_bits_access                     (ent_mp_access[13]),
    .io_in_13_bits_id                         (ent_mp_id[13]),
    .io_in_14_ready                           (arb_in_ready[14]),
    .io_in_14_valid                           (ent_mp_valid[14]),
    .io_in_14_bits_miss_id                    (ent_mp_miss_id[14]),
    .io_in_14_bits_occupy_way                 (ent_mp_occupy_way[14]),
    .io_in_14_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[14]),
    .io_in_14_bits_source                     (ent_mp_source[14]),
    .io_in_14_bits_cmd                        (ent_mp_cmd[14]),
    .io_in_14_bits_vaddr                      (ent_mp_vaddr[14]),
    .io_in_14_bits_addr                       (ent_mp_addr[14]),
    .io_in_14_bits_word_idx                   (ent_mp_word_idx[14]),
    .io_in_14_bits_amo_data                   (ent_mp_amo_data[14]),
    .io_in_14_bits_amo_mask                   (ent_mp_amo_mask[14]),
    .io_in_14_bits_amo_cmp                    (ent_mp_amo_cmp[14]),
    .io_in_14_bits_pf_source                  (ent_mp_pf_source[14]),
    .io_in_14_bits_access                     (ent_mp_access[14]),
    .io_in_14_bits_id                         (ent_mp_id[14]),
    .io_in_15_ready                           (arb_in_ready[15]),
    .io_in_15_valid                           (ent_mp_valid[15]),
    .io_in_15_bits_miss_id                    (ent_mp_miss_id[15]),
    .io_in_15_bits_occupy_way                 (ent_mp_occupy_way[15]),
    .io_in_15_bits_miss_fail_cause_evict_btot (ent_mp_miss_fail_cause_evict_btot[15]),
    .io_in_15_bits_source                     (ent_mp_source[15]),
    .io_in_15_bits_cmd                        (ent_mp_cmd[15]),
    .io_in_15_bits_vaddr                      (ent_mp_vaddr[15]),
    .io_in_15_bits_addr                       (ent_mp_addr[15]),
    .io_in_15_bits_word_idx                   (ent_mp_word_idx[15]),
    .io_in_15_bits_amo_data                   (ent_mp_amo_data[15]),
    .io_in_15_bits_amo_mask                   (ent_mp_amo_mask[15]),
    .io_in_15_bits_amo_cmp                    (ent_mp_amo_cmp[15]),
    .io_in_15_bits_pf_source                  (ent_mp_pf_source[15]),
    .io_in_15_bits_access                     (ent_mp_access[15]),
    .io_in_15_bits_id                         (ent_mp_id[15]),
    .io_out_ready                             (io_main_pipe_req_ready),
    .io_out_valid                             (arb_out_valid_s),
    .io_out_bits_miss_id                      (io_main_pipe_req_bits_miss_id),
    .io_out_bits_occupy_way                   (io_main_pipe_req_bits_occupy_way),
    .io_out_bits_miss_fail_cause_evict_btot   (io_main_pipe_req_bits_miss_fail_cause_evict_btot),
    .io_out_bits_source                       (io_main_pipe_req_bits_source),
    .io_out_bits_cmd                          (io_main_pipe_req_bits_cmd),
    .io_out_bits_vaddr                        (io_main_pipe_req_bits_vaddr),
    .io_out_bits_addr                         (io_main_pipe_req_bits_addr),
    .io_out_bits_word_idx                     (io_main_pipe_req_bits_word_idx),
    .io_out_bits_amo_data                     (io_main_pipe_req_bits_amo_data),
    .io_out_bits_amo_mask                     (io_main_pipe_req_bits_amo_mask),
    .io_out_bits_amo_cmp                      (io_main_pipe_req_bits_amo_cmp),
    .io_out_bits_pf_source                    (io_main_pipe_req_bits_pf_source),
    .io_out_bits_access                       (io_main_pipe_req_bits_access),
    .io_out_bits_id                           (io_main_pipe_req_bits_id)
  );
  // END GENERATED

endmodule
