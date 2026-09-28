// =============================================================================
// MissEntry —— DCache 的一个 MSHR（miss 状态保持寄存器）表项
//
// 位置：DCache MissQueue 里有 16 个本模块（MSHR 0..15，io_id 区分）。每个表项负责一条
//   cache 行的 miss 全过程：
//     分配(alloc)  MissQueue 的流水寄存器把新 miss 交给一个空表项；
//     合并(merge)  同一行的后续 load（数据还没回来之前）/ store 合并进同一表项；
//     A 通道       向 L2 发 AcquireBlock / AcquirePerm（有的 miss 已由流水寄存器直接发过）；
//     D 通道       收 Grant / GrantData（64B 行 = 2 拍 × 32B），与 store 数据按字节合并；
//     E 通道       回 GrantAck；
//     回填         数据到齐（或 L2 hint 先到）后向 MainPipe 发 refill 请求，写 tag/meta/data，
//                  AMO miss 在 MainPipe 里顺带执行；MainPipe 回应后表项释放。
//   同时对外提供：load 的 miss 数据前递（forwardInfo）、给 LoadQueue 的逐拍回填（refill_to_ldq）、
//   阻挡同地址 probe / replace、BtoT 升权占路信息、若干性能/延迟监控位。
//
// 状态用一组 s_*（"已发出"）/ w_*（"已等到"）标志表达（Scala: MissQueue.scala class MissEntry），
//   分配时置成"待办"，事件发生时置回 1；s_grantack && w_mainpipe_resp && w_refill_resp 即释放。
//   同一拍多个事件改同一寄存器时，按 Scala 语句顺序"后写者赢"——本文件的 always_ff
//   严格按 Scala 的语句顺序排列，读者可以逐段对照。
//
// 本配置（KunminghuV2）下 golden 与 Scala 的差别（firtool 常量折叠 / DCE，照 golden 端口表写）：
//   · nMaxPrefetchEntry（Constantin，初值 14）是常量 ⇒ "能接预取"的表项 = id >= 2；
//   · mem_grant.ready 恒 1（端口被删）；hartId / isDirty / miss_dirty / req_addr 输出被删；
//   · 存储的请求只剩被读到的字段（lqIdx / pc / cancel / full_overwrite 等不在 req 里）；
//   · 性能计数（XSPerf*）与断言的打拍寄存器在 golden 里仍是真寄存器（只是没有读者），
//     这里在 §9 逐个照留，保证两侧寄存器一一对应。
// =============================================================================
// 本文件导航：
//   missentry_pkg        常量、请求/通道结构体、命令分类与 ClientMetadata.onAccess
//   xs_MissEntry_core    §1 接收新请求  §2 请求与状态寄存器（alloc / merge / 各通道事件）
//                        §3 A 通道  §4 D 通道与回填数据合并  §5 E 通道  §6 MainPipe 回填请求
//                        §7 给 LoadQueue / MainPipe / probe / replace / 前递的输出
//                        §8 延迟监控与性能输出  §9 只为断言/性能计数而存在的寄存器
//   MissEntry            golden 同名 wrapper（端口表与字段拆装由 scripts/gen_missq.py 生成）

package missentry_pkg;

  localparam int unsigned PADDR_W  = 48;
  localparam int unsigned VADDR_W  = 50;
  localparam int unsigned ROWS     = 8;     // 一行 64B = 8 × 64 位 row
  localparam int unsigned ROW_W    = 64;
  localparam int unsigned BEAT_W   = 256;   // L1-L2 总线 32B / 拍，一行 2 拍
  localparam int unsigned BEAT_ROWS = 4;    // 每拍 4 个 row

  // 请求来源（注意是"来源"不是命令：预取来源可以带读或写命令）
  localparam logic [3:0] LOAD_SOURCE            = 4'd0;
  localparam logic [3:0] STORE_SOURCE           = 4'd1;
  localparam logic [3:0] AMO_SOURCE             = 4'd2;
  localparam logic [3:0] DCACHE_PREFETCH_SOURCE = 4'd3;   // >= 3 都算预取

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

  // ClientMetadata 一致性状态 / TileLink grow 参数
  localparam logic [1:0] ST_NOTHING = 2'd0;
  localparam logic [1:0] ST_BRANCH  = 2'd1;
  localparam logic [1:0] ST_TRUNK   = 2'd2;
  localparam logic [1:0] ST_DIRTY   = 2'd3;
  localparam logic [1:0] GROW_NTOB  = 2'd0;
  localparam logic [1:0] GROW_NTOT  = 2'd1;
  localparam logic [1:0] GROW_BTOT  = 2'd2;

  // TileLink A 通道 opcode
  localparam logic [3:0] TL_ACQUIRE_BLOCK = 4'd6;
  localparam logic [3:0] TL_ACQUIRE_PERM  = 4'd7;   // 整行覆盖写：只要权限不要数据

  // A 通道 user.reqSource（coupledL2 MemReqSource 编号）
  localparam logic [4:0] REQ_SRC_CPU_LOAD_DATA   = 5'd2;
  localparam logic [4:0] REQ_SRC_CPU_STORE_DATA  = 5'd3;
  localparam logic [4:0] REQ_SRC_CPU_ATOMIC_DATA = 5'd4;
  localparam logic [4:0] REQ_SRC_L1_DATA_PREFETCH = 5'd6;

  // ---- 结构体 ----
  // 新请求里表项需要看的字段（io.req / io.queryME(i).req 的 MissReqWoStoreData 子集）
  typedef struct packed {
    logic [3:0]  source;
    logic [47:0] addr;
    logic [49:0] vaddr;
  } query_req_t;

  // MissQueue 流水寄存器里的请求（MissReq，保留了表项会读到的字段）
  typedef struct packed {
    logic [3:0]   source;
    logic [2:0]   pf_source;
    logic [4:0]   cmd;
    logic [47:0]  addr;
    logic [49:0]  vaddr;
    logic         full_overwrite;   // store 整行覆盖（只要 T 权限，不要数据）
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [1:0]   req_coh_state;    // 请求时该行在 L1 的一致性状态（miss 时一般是 Nothing）
    logic [5:0]   id;
    logic         isBtoT;           // 是 Branch->Trunk 升权（同 set 的其它 BtoT 要被挡）
    logic [3:0]   occupy_way;       // BtoT 要占的路
    logic [511:0] store_data;
    logic [63:0]  store_mask;
  } pipe_req_t;

  // 表项里存着的请求（MissReqWoStoreData 在 golden 里还剩下的字段）
  typedef struct packed {
    logic [3:0]   source;
    logic [2:0]   pf_source;
    logic [4:0]   cmd;
    logic [47:0]  addr;             // 行对齐（低 6 位写 0）
    logic [49:0]  vaddr;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [1:0]   req_coh_state;
    logic [5:0]   id;
    logic         isBtoT;
    logic [3:0]   occupy_way;
  } entry_req_t;

  typedef struct packed {
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [5:0]  source;
    logic [47:0] address;
    logic [1:0]  user_alias;        // vaddr[13:12]：L2 用它解决 cache alias
    logic [43:0] user_vaddr;        // vaddr 行号
    logic [4:0]  user_reqSource;
    logic        user_needHint;     // PrefetchKey：是否让 L2 触发预取 / 回 hint
    logic        echo_isKeyword;    // 关键字（先回哪半行）
  } acquire_t;

  typedef struct packed {
    logic [3:0]   opcode;
    logic [1:0]   param;
    logic [2:0]   size;
    logic [9:0]   sink;
    logic         denied;
    logic [255:0] data;
    logic         corrupt;
  } grant_t;

  typedef struct packed {
    logic [47:0]  addr;
    logic [255:0] data;
    logic         error;
    logic [511:0] data_raw;
    logic         hasdata;
    logic         refill_done;
    logic [3:0]   id;
  } refill_ldq_t;

  // 发给 MainPipe 的 refill 请求（MainPipeReq 在 golden 端口上保留的字段）
  typedef struct packed {
    logic [3:0]   miss_id;
    logic [3:0]   occupy_way;
    logic         miss_fail_cause_evict_btot;
    logic [3:0]   source;
    logic [4:0]   cmd;
    logic [49:0]  vaddr;
    logic [47:0]  addr;
    logic [2:0]   word_idx;
    logic [127:0] amo_data;
    logic [15:0]  amo_mask;
    logic [127:0] amo_cmp;
    logic [2:0]   pf_source;
    logic         access;
    logic [5:0]   id;
  } mp_req_t;

  typedef struct packed {
    logic [511:0] store_data;       // 回填整行（L2 数据与 store 数据合并后）
    logic [1:0]   miss_param;       // Grant 给的权限
    logic         tl_denied;
    logic         tl_corrupt;
  } refill_info_t;

  typedef struct packed {
    logic                       inflight;
    logic [47:0]                paddr;
    logic [ROWS-1:0][ROW_W-1:0] raw_data;          // [7] 在最高位
    logic                       firstbeat_valid;
    logic                       lastbeat_valid;
    logic                       denied;
    logic                       corrupt;
  } fwd_info_t;

  // ---- 纯函数 ----
  function automatic logic is_from_prefetch(input logic [3:0] source);
    return source >= DCACHE_PREFETCH_SOURCE;
  endfunction

  // 同一 cache 行（物理地址 [47:6]）
  function automatic logic same_block(input logic [47:0] a, input logic [47:0] b);
    return a[47:6] == b[47:6];
  endfunction

  // alias 位相同（vaddr[13:12]：VIPT 64KB 下 set 下标越过页内偏移的那两位）
  function automatic logic alias_match(input logic [49:0] va, input logic [49:0] vb);
    return va[13:12] == vb[13:12];
  endfunction

  // 命令分类（rocket-chip MemoryOpCategories）
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

  // ClientMetadata.onAccess(cmd)._2 —— growStarter 表的第二列：命中时是新状态，
  // 不命中时是 Acquire 要的 grow 参数（本模块只拿它当 Acquire 的 param）。
  // 表与 MainPipe.sv mainpipe_pkg::grow_starter 是同一张（rocket-chip tilelink/Metadata.scala）。
  function automatic logic [1:0] acquire_grow_param(input logic [4:0] cmd, input logic [1:0] state);
    logic [1:0] cat;
    cat = {is_write(cmd), is_write_intent(cmd)};   // rd=00 / wi=01 / wr=11
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
      default:             return 2'd0;          // cat=10 不会出现，表的缺省项
    endcase
  endfunction

  // FillInterleaved(8, mask)：字节掩码 -> 位掩码
  function automatic logic [63:0] byte_to_bit_mask(input logic [7:0] m);
    logic [63:0] r;
    for (int b = 0; b < 8; b++) r[b*8 +: 8] = {8{m[b]}};
    return r;
  endfunction

endpackage

// =============================================================================
// xs_MissEntry_core —— 一个 MSHR 的可读核
// =============================================================================
module xs_MissEntry_core
  import missentry_pkg::*;
(
  input  logic               clock,
  input  logic               reset,                  // 异步复位（高有效）
  input  logic [3:0]         id,                     // 本表项的 MSHR 号
  // ---- MissQueue s0：本拍的新 miss 请求（用来算 ready / 合并 / 拒绝）----
  input  logic               req_valid,
  input  query_req_t         req,
  input  logic               req_cancel,
  input  logic               wbq_block_miss_req,     // WritebackQueue 有同地址写回在途：本拍不能收
  input  logic               primary_valid,          // MissQueue 选中本表项来分配
  output logic               primary_ready,          // 本表项空闲、可以分配
  output logic               secondary_ready,        // 本表项可以合并这个请求
  output logic               secondary_reject,       // 同一行但合并不了：请求要被拒
  output logic               req_handled,            // 本表项接收了这个请求（分配或合并）
  // ---- LoadPipe 提前查询（每条 load 流水一个）----
  input  query_req_t [3:0]   query_req,
  output logic [3:0]         query_primary_ready,
  output logic [3:0]         query_secondary_ready,
  output logic [3:0]         query_secondary_reject,
  // ---- MissQueue s1：流水寄存器（只有 mshr_id 指向本表项时 alloc/merge 才可能为 1）----
  input  pipe_req_t          pipe,
  input  logic               pipe_alloc,
  input  logic               pipe_merge,
  input  logic               pipe_cancel,
  input  logic               acquire_fired_by_pipe_reg,   // 流水寄存器本拍已替本表项发了 Acquire
  // ---- A / D / E 通道 ----
  input  logic               acquire_ready,
  output logic               acquire_valid,
  output acquire_t           acquire,
  input  logic               grant_valid,            // ready 恒 1，valid 即 fire
  input  grant_t             grant,
  input  logic               finish_ready,
  output logic               finish_valid,
  output logic [9:0]         finish_sink,
  input  logic               l2_hint_valid,          // L2 提前告知数据快到了（sourceId 已由父级匹配）
  // ---- MainPipe ----
  input  logic               mp_req_ready,
  output logic               mp_req_valid,
  output mp_req_t            mp_req,
  input  logic               mp_resp,                // AMO 执行完（ack_miss_queue）
  input  logic               mp_refill_resp,         // s3 refill 完成
  input  logic               mp_replay,              // s2 让本表项重发 refill
  input  logic               mp_evict_BtoT_way,      // s2：没有空路，要按 next_evict_way 占路
  input  logic [3:0]         mp_next_evict_way,
  output logic               refill_info_valid,
  output refill_info_t       refill_info,
  // ---- 回填给 LoadQueue ----
  output logic               refill_ldq_valid,
  output refill_ldq_t        refill_ldq,
  // ---- 地址阻挡 / 查询 ----
  input  logic [47:0]        probe_addr,
  input  logic [49:0]        probe_vaddr,
  output logic               probe_block,
  input  logic [47:0]        replace_addr,
  input  logic [49:0]        replace_vaddr,
  output logic               replace_block,
  output logic [3:0]         occupy_way,
  output logic               req_vaddr_valid,
  output logic [49:0]        req_vaddr_bits,
  output logic               req_isBtoT,
  output fwd_info_t          fwd,
  // ---- 配置 / 其它 ----
  input  logic               l2_pf_store_only,
  input  logic               memSetPattenDetected,   // memset 模式：连非预取表项也接预取
  input  logic [49:0]        rob_head_vaddr,
  input  logic               rob_head_query_valid,
  output logic               rob_head_resp,
  output logic               perf_pending_prefetch,
  output logic               perf_pending_normal,
  output logic [3:0]         latency_refilling,      // {pf, amo, store, load}
  output logic               late_prefetch,
  output logic               matched,
  output logic               l1Miss,
  input  logic               wfi_req,
  output logic               wfi_safe
);

  // ===========================================================================
  // 状态寄存器
  // ===========================================================================
  entry_req_t  req_q;                    // 本表项承接的请求（不复位）
  logic [3:0]  req_primary_fire_source;  // 分配时的来源（合并 store 会改 req_q.source，这份不改）
  logic [63:0] req_store_mask;
  logic        req_valid_q;              // 表项占用
  logic        evict_BtoT_way;           // MainPipe 要求改占 occupy_way（BtoT 失败）
  logic        isKeyword;                // 关键字在后半行：L2 先回后半行，beat 下标要翻转
  logic        full_overwrite;           // 只要 T 权限：发 AcquirePerm

  // s_*：该发的已经发了；w_*：该等的已经等到。复位与空闲时全为 1。
  logic s_acquire, s_grantack, s_mainpipe_req;
  logic w_grantfirst, w_grantlast, w_mainpipe_resp, w_refill_resp, w_l2hint;
  logic no_pending;                      // 没有在途的 A 请求（WFI 握手用）
  logic mainpipe_req_fired;

  logic denied, corrupt;                 // Grant 带回的错误，累积
  logic prefetch;                        // 这是一次预取 miss（被非预取请求撞上就清掉）
  logic access;                          // 合并过非预取请求（该行被真正访问过）
  logic secondary_fired;                 // 合并过请求
  logic should_refill_data_reg;          // 承接过 load（只给性能计数用）
  logic hasData;                         // 最后一个 Grant 是否带数据

  logic                       beat_left;              // D 通道 beat 计数（edge.count 的 counter）
  logic [1:0]                 grant_param;
  logic [ROWS-1:0][ROW_W-1:0] refill_and_store_data;  // store 数据 + L2 数据合并后的整行
  logic [1:0][BEAT_W-1:0]     refill_data_raw;        // L2 原始数据（按 beat 存）
  logic [9:0]                 grantack_sink;

  // ===========================================================================
  // §1 接收新请求：primary（分配）/ secondary（合并）/ reject（拒绝）
  // ---------------------------------------------------------------------------
  // 分配：表项空闲，且"刚被分配的那一拍"之后一拍也不行（req_valid 晚一拍才置起）。
  //   只有 id >= 16 - nMaxPrefetchEntry(=14) 的表项（id >= 2）能接预取请求，
  //   0/1 两个表项留给非预取 —— 除非检测到 memset 模式。这个判断打了一拍（GatedValidRegNext）。
  // 合并：同一行、alias 位相同、L2 数据还没回（w_grantfirst=0）、新请求是 load。
  //   （before_req_sent_can_merge 为了时序被写死成 false：acquire 发出前也不合并。）
  //   注意 secondary_ready 不看 req_valid —— 空表项的 w_grantfirst=1，自然为 0。
  // 拒绝：表项占用、同一行，但合并不了（不是 load / 数据已开始回 / alias 不同）。
  // golden 里 main 请求口和 4 个查询口各有一份打拍寄存器（Chisel when/otherwise 各建一个），
  //   这里照样每口一份：[0]=main 口，[1..4]=查询口 0..3。
  // ===========================================================================
  logic [4:0] prefetch_slot_q;     // RegNext(id >= 2)，复位 0
  logic [4:0] prim_fire_q_slot;    // RegNext(primary_fire)：when 分支那一份
  logic [4:0] prim_fire_q_other;   // RegNext(primary_fire)：otherwise 分支那一份

  logic primary_fire, primary_accept, secondary_fire, secondary_accept;

  function automatic logic calc_primary_ready(input logic slot, input logic fire_slot,
                                              input logic fire_other, input logic busy,
                                              input logic [3:0] source, input logic memset);
    return slot ? ~busy & ~fire_slot
                : ~busy & (~is_from_prefetch(source) | memset) & ~fire_other;
  endfunction

  function automatic logic calc_secondary_ready(input entry_req_t e, input logic w_first,
                                                input query_req_t r);
    return same_block(e.addr, r.addr) & alias_match(e.vaddr, r.vaddr) &
           ~w_first & (r.source == LOAD_SOURCE);
  endfunction

  function automatic logic calc_secondary_reject(input entry_req_t e, input logic busy,
                                                 input logic w_first, input query_req_t r);
    return busy & same_block(e.addr, r.addr) &
           (~(~w_first & (r.source == LOAD_SOURCE)) | ~alias_match(e.vaddr, r.vaddr));
  endfunction

  assign primary_ready    = calc_primary_ready(prefetch_slot_q[0], prim_fire_q_slot[0],
                                               prim_fire_q_other[0], req_valid_q, req.source,
                                               memSetPattenDetected);
  assign secondary_ready  = calc_secondary_ready(req_q, w_grantfirst, req);
  assign secondary_reject = calc_secondary_reject(req_q, req_valid_q, w_grantfirst, req);

  for (genvar q = 0; q < 4; q++) begin : g_query
    assign query_primary_ready[q]    = calc_primary_ready(prefetch_slot_q[q+1], prim_fire_q_slot[q+1],
                                                          prim_fire_q_other[q+1], req_valid_q,
                                                          query_req[q].source, memSetPattenDetected);
    assign query_secondary_ready[q]  = calc_secondary_ready(req_q, w_grantfirst, query_req[q]);
    assign query_secondary_reject[q] = calc_secondary_reject(req_q, req_valid_q, w_grantfirst,
                                                             query_req[q]);
  end

  // accept = 本表项收下（MissQueue 据此回 resp）；fire 还要求 wbq 不挡（才真正进流水寄存器）
  assign primary_accept   = req_valid & primary_ready & primary_valid & ~req_cancel;
  assign primary_fire     = primary_accept & ~wbq_block_miss_req;
  assign secondary_accept = req_valid & secondary_ready & ~req_cancel;
  assign secondary_fire   = secondary_accept & ~wbq_block_miss_req;
  assign req_handled      = primary_accept | secondary_accept;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      prefetch_slot_q   <= '0;
      prim_fire_q_slot  <= '0;
      prim_fire_q_other <= '0;
    end else begin
      prefetch_slot_q   <= {5{id >= 4'd2}};
      prim_fire_q_slot  <= {5{primary_fire}};
      prim_fire_q_other <= {5{primary_fire}};
    end
  end

  // ===========================================================================
  // §2 请求与状态寄存器
  // ---------------------------------------------------------------------------
  // 流水寄存器指向本表项时：
  //   alloc_fire —— 新分配：整条请求写进来，所有 s_*/w_* 置成"待办"
  //                 （若流水寄存器本拍已经替我们发了 Acquire，s_acquire 直接为 1）；
  //   merge_fire —— 合并：更新一致性状态；合并的是 store 就整条请求换成 store 的
  //                 （store 数据/掩码也换掉），并标记 access / secondary_fired。
  // 之后各通道事件把对应标志置回 1。语句顺序即 Scala 顺序（后写者赢）。
  // ===========================================================================
  wire alloc_fire  = pipe_alloc & ~pipe_cancel;
  wire merge_fire  = pipe_merge & ~pipe_cancel;
  wire pipe_is_load   = pipe.source == LOAD_SOURCE;
  wire pipe_is_store  = pipe.source == STORE_SOURCE;
  wire pipe_is_amo    = pipe.source == AMO_SOURCE;
  wire pipe_is_pf_cmd = pipe.cmd == M_PFR || pipe.cmd == M_PFW;   // isPrefetch(cmd)

  // MissReqPipeRegBundle.prefetch_late_en：流水寄存器里正在分配的是预取，本拍又来了一个
  //   同一行的非预取请求 —— 这次预取"来晚了"，分配时就不再标记为预取。
  wire pipe_prefetch_late = req_valid & pipe_alloc & same_block(pipe.addr, req.addr) &
                            is_from_prefetch(pipe.source) & ~is_from_prefetch(req.source);

  wire release_entry = s_grantack & w_mainpipe_resp & w_refill_resp;

  wire acquire_fire = acquire_ready & acquire_valid;
  wire finish_fire  = finish_ready & finish_valid;
  wire mp_req_fire  = mp_req_ready & mp_req_valid;

  // D 通道拍计数（TLEdge.count，1 位 counter：一行最多 2 拍）
  //   beats1     = 本消息的拍数 - 1：带数据且 size=64B（>32B）时为 1
  //   refill_count = 当前是第几拍；refill_done = 最后一拍
  wire grant_has_data = grant.opcode[0];                      // GrantData=5 / Grant=4
  wire grant_beats1   = grant_has_data & (grant.size > 3'd5);
  wire refill_count   = grant_beats1 & ~(beat_left - 1'b1);
  wire refill_done    = (beat_left | ~grant_beats1) & grant_valid;

  // 本拍 L2 数据落在哪一半行：isKeyword 时 L2 先回后半行，beat 下标翻转
  wire beat_sel = refill_count ^ isKeyword;

  // late_prefetch：本拍来了一个同一行的非预取请求，而表项里是预取 —— 预取标记清掉
  assign late_prefetch = req_valid & ~is_from_prefetch(req.source) & req_valid_q &
                         same_block(req_q.addr, req.addr) & prefetch;

  // --- 复位域：状态标志 ---
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid_q        <= 1'b0;
      evict_BtoT_way     <= 1'b0;
      isKeyword          <= 1'b0;
      s_acquire          <= 1'b1;
      s_grantack         <= 1'b1;
      s_mainpipe_req     <= 1'b1;
      w_grantfirst       <= 1'b1;
      w_grantlast        <= 1'b1;
      w_mainpipe_resp    <= 1'b1;
      w_refill_resp      <= 1'b1;
      w_l2hint           <= 1'b1;
      no_pending         <= 1'b1;
      mainpipe_req_fired <= 1'b1;
      denied             <= 1'b0;
      corrupt            <= 1'b0;
      prefetch           <= 1'b0;
      access             <= 1'b0;
      beat_left          <= 1'b0;
      secondary_fired    <= 1'b0;
      hasData            <= 1'b1;
    end else begin
      // 释放
      if (release_entry && req_valid_q)
        req_valid_q <= 1'b0;

      // 分配
      if (alloc_fire) begin
        req_valid_q        <= 1'b1;
        evict_BtoT_way     <= 1'b0;
        isKeyword          <= pipe_is_load & pipe.vaddr[5];   // 只有 load miss 需要关键字
        s_acquire          <= acquire_fired_by_pipe_reg;
        s_grantack         <= 1'b0;
        s_mainpipe_req     <= 1'b0;
        w_grantfirst       <= 1'b0;
        w_grantlast        <= 1'b0;
        w_l2hint           <= 1'b0;
        mainpipe_req_fired <= 1'b0;
        no_pending         <= ~acquire_fired_by_pipe_reg;
        if (!pipe_is_amo) w_refill_resp   <= 1'b0;   // 非 AMO：等 MainPipe s3 refill 完成
        if (pipe_is_amo)  w_mainpipe_resp <= 1'b0;   // AMO：等 MainPipe 执行完 AMO
        denied             <= 1'b0;
        corrupt            <= 1'b0;
        prefetch           <= pipe_is_pf_cmd & ~pipe_prefetch_late;
        access             <= 1'b0;
        secondary_fired    <= 1'b0;
      end

      // 合并（before_req_sent_can_merge 恒 false ⇒ isKeyword 保持；这一句也覆盖同拍 alloc 的写）
      if (merge_fire) begin
        isKeyword <= isKeyword;
        if (pipe_is_store) evict_BtoT_way <= 1'b0;
        if (!pipe_is_pf_cmd) access <= 1'b1;
        secondary_fired <= 1'b1;
      end

      // A 通道发出
      if (acquire_fire) begin
        s_acquire  <= 1'b1;
        no_pending <= 1'b0;
      end

      // D 通道：Grant / GrantData（读的都是寄存器的当前值，所以会盖掉同拍 alloc 的清零）
      if (grant_valid) begin
        w_grantfirst <= 1'b1;
        if (grant_has_data) begin
          w_grantlast <= w_grantlast | refill_done;
          no_pending  <= no_pending | refill_done;
          hasData     <= 1'b1;
        end else begin
          w_grantlast <= 1'b1;
          no_pending  <= 1'b1;
          hasData     <= 1'b0;
        end
        denied    <= grant.denied | denied;
        corrupt   <= grant.corrupt | corrupt;
        beat_left <= (beat_left == 1'b0) ? grant_beats1 : beat_left - 1'b1;
      end

      // E 通道发出
      if (finish_fire) s_grantack <= 1'b1;

      // MainPipe
      if (mp_req_fire) begin
        s_mainpipe_req     <= 1'b1;
        mainpipe_req_fired <= 1'b1;
      end
      if (mp_replay || mp_evict_BtoT_way) s_mainpipe_req <= 1'b0;   // 要重发
      if (mp_replay)              evict_BtoT_way <= 1'b0;
      else if (mp_evict_BtoT_way) evict_BtoT_way <= 1'b1;
      if (mp_resp)        w_mainpipe_resp <= 1'b1;
      if (mp_refill_resp) w_refill_resp   <= 1'b1;
      if (l2_hint_valid)  w_l2hint        <= 1'b1;

      // 迟到的预取被非预取请求撞上
      if (late_prefetch) prefetch <= 1'b0;
    end
  end

  // --- 不复位：请求内容与数据 ---
  // should_refill_data = 承接过 load（合并 load 那一拍组合地并进来）
  wire should_refill_data = should_refill_data_reg | (merge_fire & pipe_is_load);

  function automatic entry_req_t to_entry_req(input pipe_req_t p);
    entry_req_t e;
    e.source        = p.source;
    e.pf_source     = p.pf_source;
    e.cmd           = p.cmd;
    e.addr          = {p.addr[47:6], 6'd0};    // get_block_addr
    e.vaddr         = p.vaddr;
    e.word_idx      = p.word_idx;
    e.amo_data      = p.amo_data;
    e.amo_mask      = p.amo_mask;
    e.amo_cmp       = p.amo_cmp;
    e.req_coh_state = p.req_coh_state;
    e.id            = p.id;
    e.isBtoT        = p.isBtoT;
    e.occupy_way    = p.occupy_way;
    return e;
  endfunction

  // 本拍 L2 数据写到哪 4 个 row、写什么：GrantData 与 store 数据按字节合并（store 字节优先）
  //   row 下标 = (refill_count*4 + i) ^ (isKeyword ? 4 : 0)
  logic [BEAT_ROWS-1:0][2:0]       grant_row_idx;
  logic [BEAT_ROWS-1:0][ROW_W-1:0] grant_row_data;
  always_comb begin
    for (int i = 0; i < BEAT_ROWS; i++) begin
      logic [7:0]  row_mask;
      logic [63:0] bit_mask;
      grant_row_idx[i] = 3'({refill_count, 2'b00} + 3'(i)) ^ {isKeyword, 2'b00};
      // new_mask(idx)：只有 store 请求才有要保留的字节
      row_mask = (req_q.source == STORE_SOURCE) ? req_store_mask[grant_row_idx[i]*8 +: 8] : 8'd0;
      bit_mask = byte_to_bit_mask(row_mask);
      grant_row_data[i] = (~bit_mask & grant.data[i*ROW_W +: ROW_W]) |
                          (bit_mask & refill_and_store_data[grant_row_idx[i]]);
    end
  end

  always_ff @(posedge clock) begin
    // 分配
    if (alloc_fire) begin
      req_q                   <= to_entry_req(pipe);
      req_primary_fire_source <= pipe.source;
      if (pipe_is_store) begin
        req_store_mask        <= pipe.store_mask;
        refill_and_store_data <= pipe.store_data;
      end
      full_overwrite          <= pipe_is_store & pipe.full_overwrite;
      should_refill_data_reg  <= pipe_is_load;
    end

    // 合并：总是用最新的一致性状态；合并 store 时换成 store 的整条请求
    if (merge_fire) begin
      req_q.req_coh_state <= pipe.req_coh_state;
      if (pipe_is_store) begin
        req_q                 <= to_entry_req(pipe);
        req_store_mask        <= pipe.store_mask;
        refill_and_store_data <= pipe.store_data;
        full_overwrite        <= pipe_is_store & pipe.full_overwrite;
      end
      should_refill_data_reg <= should_refill_data;
    end

    // D 通道
    if (grant_valid) begin
      grant_param <= grant.param;
      if (grant_has_data) begin
        for (int i = 0; i < BEAT_ROWS; i++)
          refill_and_store_data[grant_row_idx[i]] <= grant_row_data[i];
      end else begin
        // 无数据的 Grant（整行覆盖写）：数据保持 = store 数据本身。这句也覆盖了同拍
        // alloc/merge 的 store 数据写入（Scala 里 refill_and_store_data(i) := new_data(i) 在后）。
        refill_and_store_data <= refill_and_store_data;
      end
      refill_data_raw[beat_sel] <= grant.data;
      grantack_sink             <= grant.sink;
    end

    // MainPipe 要求改占路
    if (!mp_replay && mp_evict_BtoT_way)
      req_q.occupy_way <= mp_next_evict_way;
  end

  // ===========================================================================
  // §3 A 通道：AcquireBlock / AcquirePerm
  // ---------------------------------------------------------------------------
  // 流水寄存器本拍正要把一个 store 合并进来时先别发（store 可能要 T 权限，参数会变）；
  // WFI 期间不发。
  // ===========================================================================
  assign acquire_valid = ~s_acquire & ~(merge_fire & pipe_is_store) & ~wfi_req;

  always_comb begin
    acquire.opcode         = full_overwrite ? TL_ACQUIRE_PERM : TL_ACQUIRE_BLOCK;
    acquire.param          = {1'b0, acquire_grow_param(req_q.cmd, req_q.req_coh_state)};
    acquire.source         = {2'b00, id};
    acquire.address        = req_q.addr;
    acquire.user_alias     = req_q.vaddr[13:12];
    acquire.user_vaddr     = req_q.vaddr[49:6];
    acquire.user_needHint  = ~l2_pf_store_only | (req_q.source == STORE_SOURCE);
    acquire.echo_isKeyword = isKeyword;
    if (prefetch && !secondary_fired)          acquire.user_reqSource = REQ_SRC_L1_DATA_PREFETCH;
    else if (req_q.source == STORE_SOURCE)     acquire.user_reqSource = REQ_SRC_CPU_STORE_DATA;
    else if (req_q.source == LOAD_SOURCE)      acquire.user_reqSource = REQ_SRC_CPU_LOAD_DATA;
    else if (req_q.source == AMO_SOURCE)       acquire.user_reqSource = REQ_SRC_CPU_ATOMIC_DATA;
    else                                       acquire.user_reqSource = REQ_SRC_L1_DATA_PREFETCH;
  end

  // ===========================================================================
  // §4 D 通道（寄存器更新已在 §2）/ §5 E 通道：GrantAck
  // ---------------------------------------------------------------------------
  // 第一拍 Grant 到了就可以回 GrantAck（sink 取自 Grant，在 D.fire 时锁存）。
  // ===========================================================================
  assign finish_valid = ~s_grantack & w_grantfirst;
  assign finish_sink  = grantack_sink;

  // ===========================================================================
  // §6 MainPipe 回填请求：数据到齐或 L2 hint 先到就发
  // ===========================================================================
  assign mp_req_valid = ~s_mainpipe_req & (w_l2hint | w_grantlast);

  always_comb begin
    mp_req.miss_id                    = id;
    mp_req.occupy_way                 = req_q.occupy_way;
    mp_req.miss_fail_cause_evict_btot = evict_BtoT_way;
    mp_req.source                     = req_q.source;
    mp_req.cmd                        = req_q.cmd;
    mp_req.vaddr                      = req_q.vaddr;
    mp_req.addr                       = req_q.addr;
    mp_req.word_idx                   = req_q.word_idx;
    mp_req.amo_data                   = req_q.amo_data;
    mp_req.amo_mask                   = req_q.amo_mask;
    mp_req.amo_cmp                    = req_q.amo_cmp;
    mp_req.pf_source                  = req_q.pf_source;
    mp_req.access                     = access;
    mp_req.id                         = req_q.id;
  end

  assign refill_info_valid      = req_valid_q & w_grantlast;
  assign refill_info.store_data = refill_and_store_data;
  assign refill_info.miss_param = grant_param;
  assign refill_info.tl_denied  = denied;
  assign refill_info.tl_corrupt = corrupt;

  // ===========================================================================
  // §7 其它输出
  // ---------------------------------------------------------------------------
  // refill_to_ldq：每收一拍数据（数据到齐之前），下一拍把对应半行送给 LoadQueue 唤醒 miss 的 load。
  //   地址/半行选择/错误/是否最后一拍都在 D.fire 那拍锁存；data 是锁存的半行选择去选
  //   **当前**整行寄存器（那一拍刚写好）。
  // ===========================================================================
  wire refill_to_ldq_en = ~w_grantlast & grant_valid;

  logic        refill_ldq_valid_q;
  logic [47:0] refill_ldq_addr_q;
  logic        refill_ldq_half_q;
  logic        refill_ldq_error_q;
  logic        refill_ldq_done_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) refill_ldq_valid_q <= 1'b0;
    else       refill_ldq_valid_q <= refill_to_ldq_en;
  end

  always_ff @(posedge clock) begin
    if (refill_to_ldq_en) begin
      refill_ldq_addr_q  <= req_q.addr + {42'd0, beat_sel, 5'd0};
      refill_ldq_half_q  <= beat_sel;
      refill_ldq_error_q <= grant.corrupt | grant.denied;
      refill_ldq_done_q  <= refill_done & grant_valid;
    end
  end

  assign refill_ldq_valid         = refill_ldq_valid_q;
  assign refill_ldq.addr          = refill_ldq_addr_q;
  assign refill_ldq.data          = refill_ldq_half_q ? refill_and_store_data[7:4]
                                                      : refill_and_store_data[3:0];
  assign refill_ldq.error         = refill_ldq_error_q;
  assign refill_ldq.data_raw      = refill_data_raw;
  assign refill_ldq.hasdata       = hasData;
  assign refill_ldq.refill_done   = refill_ldq_done_q;
  assign refill_ldq.id            = id;

  // probe 只在数据到齐后才挡（之前 L2 本来就不会 probe 这一行）；replace 占用期间都挡
  assign probe_block   = req_valid_q & w_grantlast &
                         same_block(req_q.addr, probe_addr) & alias_match(req_q.vaddr, probe_vaddr);
  assign replace_block = req_valid_q &
                         same_block(req_q.addr, replace_addr) & alias_match(req_q.vaddr, replace_vaddr);

  assign occupy_way      = req_q.occupy_way;
  assign req_vaddr_valid = req_valid_q;
  assign req_vaddr_bits  = req_q.vaddr;
  assign req_isBtoT      = req_q.isBtoT;

  // 前递：isKeyword 时后半行先到，"第一拍"与"最后一拍"的含义对调
  assign fwd.inflight        = req_valid_q;
  assign fwd.paddr           = req_q.addr;
  assign fwd.raw_data        = refill_and_store_data;
  assign fwd.firstbeat_valid = isKeyword ? w_grantlast : w_grantfirst;
  assign fwd.lastbeat_valid  = isKeyword ? w_grantfirst : w_grantlast;
  assign fwd.denied          = denied;
  assign fwd.corrupt         = corrupt;

  assign matched = req_valid_q & same_block(req_q.addr, req.addr) & ~prefetch;
  assign l1Miss  = req_valid_q;

  assign rob_head_resp = rob_head_query_valid & (rob_head_vaddr[49:6] == req_q.vaddr[49:6]) &
                         req_valid_q;

  // WFI：没有在途 A 请求时回 safe（打一拍，复位 0）
  logic wfi_safe_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) wfi_safe_q <= 1'b0;
    else       wfi_safe_q <= no_pending & wfi_req;
  end
  assign wfi_safe = wfi_safe_q;

  // ===========================================================================
  // §8 延迟监控与性能输出
  // ---------------------------------------------------------------------------
  // refill 延迟"秒表"：从 Acquire 发出（或流水寄存器替我们发了、分配后两拍）开始计，
  //   到收到非最后一拍的数据为止。BoolStopWatch(start, stop, startHighPriority, bypass)：
  //   输出 = start | 状态，状态 <= start | (~stop & 状态)。四种来源各一个（golden 各一份寄存器）。
  // ===========================================================================
  logic       acq_fire_q;                     // RegNext(acquire.fire)
  logic [1:0] prim_fire_dly;                  // primary_fire 打 1 拍、2 拍
  logic [3:0] lat_watch_q;                    // {pf, amo, store, load}

  wire start_counting = acq_fire_q | (prim_fire_dly[1] & s_acquire);
  wire lat_stop       = grant_valid & ~refill_done;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      acq_fire_q    <= 1'b0;
      prim_fire_dly <= '0;
      lat_watch_q   <= '0;
    end else begin
      acq_fire_q    <= acquire_fire;
      prim_fire_dly <= {prim_fire_dly[0], primary_fire};
      for (int k = 0; k < 4; k++)
        lat_watch_q[k] <= start_counting | (~lat_stop & lat_watch_q[k]);
    end
  end

  wire [3:0] primary_source_is = {is_from_prefetch(req_primary_fire_source),
                                  req_primary_fire_source == AMO_SOURCE,
                                  req_primary_fire_source == STORE_SOURCE,
                                  req_primary_fire_source == LOAD_SOURCE};
  assign latency_refilling = {4{req_valid_q}} & primary_source_is &
                             ({4{start_counting}} | lat_watch_q);

  assign perf_pending_prefetch = req_valid_q & prefetch & ~secondary_fired;
  assign perf_pending_normal   = req_valid_q & (~prefetch | secondary_fired);

  // ===========================================================================
  // §9 只为断言 / 性能计数而存在的寄存器（golden 同样保留；综合口径下没有读者）
  // ---------------------------------------------------------------------------
  // Chisel 的 assert(RegNext(...))、XSPerfAccumulate(BoolStopWatch(...))、
  // TransactionLatencyCounter 在 golden 里都是真寄存器。照留，两侧一一对应。
  // ===========================================================================
  // 断言打拍（不复位）
  logic chk_primary_valid_not_ready;   // assert(!RegNext(primary_valid && !primary_ready))
  logic chk_primary_fire_d1;           // assert(RegNext(primary_fire))（alloc 时）
  logic chk_secondary_fire_d1;         // merge 时：RegNext(secondary_fire)
  logic chk_primary_fire_m1;           // merge 时：RegNext(RegNext(primary_fire)) 的两拍
  logic chk_primary_fire_m2;
  logic chk_ready_onehot;              // PopCount(primary/secondary_ready/reject) <= 1 || !req.valid
  logic chk_grant_is_request;          // !grant.fire || isRequest(grant)
  logic w_grantlast_d1;                // RegNext(w_grantlast)

  wire [1:0] ready_popcount = 2'(primary_ready) + 2'(secondary_ready) + 2'(secondary_reject);

  always_ff @(posedge clock) begin
    chk_primary_valid_not_ready <= primary_valid & ~primary_ready;
    chk_primary_fire_d1         <= primary_fire;
    chk_secondary_fire_d1       <= secondary_fire;
    chk_primary_fire_m1         <= primary_fire;
    chk_primary_fire_m2         <= chk_primary_fire_m1;
    chk_ready_onehot            <= (ready_popcount <= 2'd1) | ~req_valid;
    // D 通道 isRequest：opcode[2:0] ∈ {Grant=4, GrantData=5}
    chk_grant_is_request        <= ~grant_valid | (grant.opcode[2:0] == 3'd4) |
                                   (grant.opcode[2:0] == 3'd5);
    w_grantlast_d1              <= w_grantlast;
  end

  // 性能计数的秒表与延迟计数器（复位）
  logic        perf_load_penalty_watch;      // BoolStopWatch(primary_fire, refill_to_ldq.valid, true)
  logic        perf_grantlast_release_watch; // BoolStopWatch(w_grantlast 上升沿, release_entry, true)
  logic        perf_mainpipe_watch;          // BoolStopWatch(main_pipe_req.fire, main_pipe_resp)
  logic [1:0]  perf_prim_fire_dly;           // GatedValidRegNextN(primary_fire, 2)
  logic [63:0] perf_mshr_penalty;            // TransactionLatencyCounter(分配后 2 拍, release_entry)
  logic        perf_refill_finished_d1;      // GatedValidRegNext(!w_grantlast && refill_done)
  logic [63:0] perf_load_miss_penalty;       // TransactionLatencyCounter(load 分配, 回填完)
  logic        perf_last_beat_d1;            // GatedValidRegNext(grant.fire && refill_done)
  logic [63:0] perf_a_to_d_penalty;          // TransactionLatencyCounter(start_counting, 最后一拍)

  wire perf_load_miss_begin = primary_fire & (req.source == LOAD_SOURCE);
  wire perf_refill_finished = perf_refill_finished_d1 & should_refill_data;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      perf_load_penalty_watch      <= 1'b0;
      perf_grantlast_release_watch <= 1'b0;
      perf_mainpipe_watch          <= 1'b0;
      perf_prim_fire_dly           <= '0;
      perf_mshr_penalty            <= '0;
      perf_refill_finished_d1      <= 1'b0;
      perf_load_miss_penalty       <= '0;
      perf_last_beat_d1            <= 1'b0;
      perf_a_to_d_penalty          <= '0;
    end else begin
      perf_load_penalty_watch      <= primary_fire | (~refill_ldq_valid_q & perf_load_penalty_watch);
      perf_grantlast_release_watch <= (~w_grantlast_d1 & w_grantlast) |
                                      (~release_entry & perf_grantlast_release_watch);
      perf_mainpipe_watch          <= ~mp_resp & (mp_req_fire | perf_mainpipe_watch);
      perf_prim_fire_dly           <= {perf_prim_fire_dly[0], primary_fire};
      perf_mshr_penalty            <= (perf_prim_fire_dly[1] | release_entry) ? 64'd0
                                                                              : perf_mshr_penalty + 64'd1;
      perf_refill_finished_d1      <= ~w_grantlast & refill_done;
      perf_load_miss_penalty       <= (perf_load_miss_begin | perf_refill_finished) ? 64'd0
                                                                                   : perf_load_miss_penalty + 64'd1;
      perf_last_beat_d1            <= grant_valid & refill_done;
      perf_a_to_d_penalty          <= (start_counting | perf_last_beat_d1) ? 64'd0
                                                                           : perf_a_to_d_penalty + 64'd1;
    end
  end

endmodule

// =============================================================================
// MissEntry —— golden 同名 wrapper：端口逐位同名，结构体拆装由 scripts/gen_missq.py 生成
// =============================================================================
module MissEntry
  import missentry_pkg::*;
(
  // BEGIN GENERATED(missentry-ports)
  input          clock,
  input          reset,
  input  [3:0]   io_id,
  input          io_req_valid,
  input  [3:0]   io_req_bits_source,
  input  [47:0]  io_req_bits_addr,
  input  [49:0]  io_req_bits_vaddr,
  input          io_req_bits_cancel,
  input          io_wbq_block_miss_req,
  input  [3:0]   io_miss_req_pipe_reg_req_source,
  input  [2:0]   io_miss_req_pipe_reg_req_pf_source,
  input  [4:0]   io_miss_req_pipe_reg_req_cmd,
  input  [47:0]  io_miss_req_pipe_reg_req_addr,
  input  [49:0]  io_miss_req_pipe_reg_req_vaddr,
  input          io_miss_req_pipe_reg_req_full_overwrite,
  input  [2:0]   io_miss_req_pipe_reg_req_word_idx,
  input  [127:0] io_miss_req_pipe_reg_req_amo_data,
  input  [15:0]  io_miss_req_pipe_reg_req_amo_mask,
  input  [127:0] io_miss_req_pipe_reg_req_amo_cmp,
  input  [1:0]   io_miss_req_pipe_reg_req_req_coh_state,
  input  [5:0]   io_miss_req_pipe_reg_req_id,
  input          io_miss_req_pipe_reg_req_isBtoT,
  input  [3:0]   io_miss_req_pipe_reg_req_occupy_way,
  input  [511:0] io_miss_req_pipe_reg_req_store_data,
  input  [63:0]  io_miss_req_pipe_reg_req_store_mask,
  input          io_miss_req_pipe_reg_merge,
  input          io_miss_req_pipe_reg_alloc,
  input          io_miss_req_pipe_reg_cancel,
  input          io_primary_valid,
  output         io_primary_ready,
  output         io_secondary_ready,
  output         io_secondary_reject,
  input          io_mem_acquire_ready,
  output         io_mem_acquire_valid,
  output [3:0]   io_mem_acquire_bits_opcode,
  output [2:0]   io_mem_acquire_bits_param,
  output [5:0]   io_mem_acquire_bits_source,
  output [47:0]  io_mem_acquire_bits_address,
  output [1:0]   io_mem_acquire_bits_user_alias,
  output [43:0]  io_mem_acquire_bits_user_vaddr,
  output [4:0]   io_mem_acquire_bits_user_reqSource,
  output         io_mem_acquire_bits_user_needHint,
  output         io_mem_acquire_bits_echo_isKeyword,
  input          io_mem_grant_valid,
  input  [3:0]   io_mem_grant_bits_opcode,
  input  [1:0]   io_mem_grant_bits_param,
  input  [2:0]   io_mem_grant_bits_size,
  input  [9:0]   io_mem_grant_bits_sink,
  input          io_mem_grant_bits_denied,
  input  [255:0] io_mem_grant_bits_data,
  input          io_mem_grant_bits_corrupt,
  input          io_mem_finish_ready,
  output         io_mem_finish_valid,
  output [9:0]   io_mem_finish_bits_sink,
  input  [3:0]   io_queryME_0_req_bits_source,
  input  [47:0]  io_queryME_0_req_bits_addr,
  input  [49:0]  io_queryME_0_req_bits_vaddr,
  output         io_queryME_0_primary_ready,
  output         io_queryME_0_secondary_ready,
  output         io_queryME_0_secondary_reject,
  input  [3:0]   io_queryME_1_req_bits_source,
  input  [47:0]  io_queryME_1_req_bits_addr,
  input  [49:0]  io_queryME_1_req_bits_vaddr,
  output         io_queryME_1_primary_ready,
  output         io_queryME_1_secondary_ready,
  output         io_queryME_1_secondary_reject,
  input  [3:0]   io_queryME_2_req_bits_source,
  input  [47:0]  io_queryME_2_req_bits_addr,
  input  [49:0]  io_queryME_2_req_bits_vaddr,
  output         io_queryME_2_primary_ready,
  output         io_queryME_2_secondary_ready,
  output         io_queryME_2_secondary_reject,
  input  [3:0]   io_queryME_3_req_bits_source,
  input  [47:0]  io_queryME_3_req_bits_addr,
  input  [49:0]  io_queryME_3_req_bits_vaddr,
  output         io_queryME_3_primary_ready,
  output         io_queryME_3_secondary_ready,
  output         io_queryME_3_secondary_reject,
  output         io_refill_to_ldq_valid,
  output [47:0]  io_refill_to_ldq_bits_addr,
  output [255:0] io_refill_to_ldq_bits_data,
  output         io_refill_to_ldq_bits_error,
  output [511:0] io_refill_to_ldq_bits_data_raw,
  output         io_refill_to_ldq_bits_hasdata,
  output         io_refill_to_ldq_bits_refill_done,
  output [3:0]   io_refill_to_ldq_bits_id,
  input          io_l2_hint_valid,
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
  input          io_main_pipe_resp,
  input          io_main_pipe_refill_resp,
  input          io_main_pipe_replay,
  input          io_main_pipe_evict_BtoT_way,
  input  [3:0]   io_main_pipe_next_evict_way,
  output         io_refill_info_valid,
  output [511:0] io_refill_info_bits_store_data,
  output [1:0]   io_refill_info_bits_miss_param,
  output         io_refill_info_bits_error_tl_denied,
  output         io_refill_info_bits_error_tl_corrupt,
  output [3:0]   io_occupy_way,
  input  [47:0]  io_probe_req_bits_addr,
  input  [49:0]  io_probe_req_bits_vaddr,
  output         io_probe_block,
  input  [47:0]  io_replace_req_bits_addr,
  input  [49:0]  io_replace_req_bits_vaddr,
  output         io_replace_block,
  output         io_req_vaddr_valid,
  output [49:0]  io_req_vaddr_bits,
  output         io_req_isBtoT,
  output         io_req_handled_by_this_entry,
  output         io_forwardInfo_inflight,
  output [47:0]  io_forwardInfo_paddr,
  output [63:0]  io_forwardInfo_raw_data_0,
  output [63:0]  io_forwardInfo_raw_data_1,
  output [63:0]  io_forwardInfo_raw_data_2,
  output [63:0]  io_forwardInfo_raw_data_3,
  output [63:0]  io_forwardInfo_raw_data_4,
  output [63:0]  io_forwardInfo_raw_data_5,
  output [63:0]  io_forwardInfo_raw_data_6,
  output [63:0]  io_forwardInfo_raw_data_7,
  output         io_forwardInfo_firstbeat_valid,
  output         io_forwardInfo_lastbeat_valid,
  output         io_forwardInfo_denied,
  output         io_forwardInfo_corrupt,
  input          io_l2_pf_store_only,
  input          io_acquire_fired_by_pipe_reg,
  input          io_memSetPattenDetected,
  output         io_perf_pending_prefetch,
  output         io_perf_pending_normal,
  input  [49:0]  io_rob_head_query_vaddr,
  input          io_rob_head_query_query_valid,
  output         io_rob_head_query_resp,
  output         io_latency_monitor_load_miss_refilling,
  output         io_latency_monitor_store_miss_refilling,
  output         io_latency_monitor_amo_miss_refilling,
  output         io_latency_monitor_pf_miss_refilling,
  output         io_prefetch_info_late_prefetch,
  output         io_matched,
  output         io_l1Miss,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe
  // END GENERATED
);

  // BEGIN GENERATED(missentry-body)
  // ---- 结构体信号（golden 扁平端口在这里拆装）----
  query_req_t       req_s;
  query_req_t [3:0] query_s;
  pipe_req_t        pipe_s;
  grant_t           grant_s;
  acquire_t         acq_s;
  refill_ldq_t      ldq_s;
  mp_req_t          mp_s;
  refill_info_t     info_s;
  fwd_info_t        fwd_s;
  logic [3:0] query_primary_ready_s;
  logic [3:0] query_secondary_ready_s;
  logic [3:0] query_secondary_reject_s;
  logic [3:0] latency_refilling_s;

  assign req_s.source = io_req_bits_source;
  assign req_s.addr = io_req_bits_addr;
  assign req_s.vaddr = io_req_bits_vaddr;
  assign query_s[0].source = io_queryME_0_req_bits_source;
  assign query_s[0].addr = io_queryME_0_req_bits_addr;
  assign query_s[0].vaddr = io_queryME_0_req_bits_vaddr;
  assign query_s[1].source = io_queryME_1_req_bits_source;
  assign query_s[1].addr = io_queryME_1_req_bits_addr;
  assign query_s[1].vaddr = io_queryME_1_req_bits_vaddr;
  assign query_s[2].source = io_queryME_2_req_bits_source;
  assign query_s[2].addr = io_queryME_2_req_bits_addr;
  assign query_s[2].vaddr = io_queryME_2_req_bits_vaddr;
  assign query_s[3].source = io_queryME_3_req_bits_source;
  assign query_s[3].addr = io_queryME_3_req_bits_addr;
  assign query_s[3].vaddr = io_queryME_3_req_bits_vaddr;
  assign pipe_s.source = io_miss_req_pipe_reg_req_source;
  assign pipe_s.pf_source = io_miss_req_pipe_reg_req_pf_source;
  assign pipe_s.cmd = io_miss_req_pipe_reg_req_cmd;
  assign pipe_s.addr = io_miss_req_pipe_reg_req_addr;
  assign pipe_s.vaddr = io_miss_req_pipe_reg_req_vaddr;
  assign pipe_s.full_overwrite = io_miss_req_pipe_reg_req_full_overwrite;
  assign pipe_s.word_idx = io_miss_req_pipe_reg_req_word_idx;
  assign pipe_s.amo_data = io_miss_req_pipe_reg_req_amo_data;
  assign pipe_s.amo_mask = io_miss_req_pipe_reg_req_amo_mask;
  assign pipe_s.amo_cmp = io_miss_req_pipe_reg_req_amo_cmp;
  assign pipe_s.req_coh_state = io_miss_req_pipe_reg_req_req_coh_state;
  assign pipe_s.id = io_miss_req_pipe_reg_req_id;
  assign pipe_s.isBtoT = io_miss_req_pipe_reg_req_isBtoT;
  assign pipe_s.occupy_way = io_miss_req_pipe_reg_req_occupy_way;
  assign pipe_s.store_data = io_miss_req_pipe_reg_req_store_data;
  assign pipe_s.store_mask = io_miss_req_pipe_reg_req_store_mask;
  assign grant_s.opcode = io_mem_grant_bits_opcode;
  assign grant_s.param = io_mem_grant_bits_param;
  assign grant_s.size = io_mem_grant_bits_size;
  assign grant_s.sink = io_mem_grant_bits_sink;
  assign grant_s.denied = io_mem_grant_bits_denied;
  assign grant_s.data = io_mem_grant_bits_data;
  assign grant_s.corrupt = io_mem_grant_bits_corrupt;
  assign io_mem_acquire_bits_opcode = acq_s.opcode;
  assign io_mem_acquire_bits_param = acq_s.param;
  assign io_mem_acquire_bits_source = acq_s.source;
  assign io_mem_acquire_bits_address = acq_s.address;
  assign io_mem_acquire_bits_user_alias = acq_s.user_alias;
  assign io_mem_acquire_bits_user_vaddr = acq_s.user_vaddr;
  assign io_mem_acquire_bits_user_reqSource = acq_s.user_reqSource;
  assign io_mem_acquire_bits_user_needHint = acq_s.user_needHint;
  assign io_mem_acquire_bits_echo_isKeyword = acq_s.echo_isKeyword;
  assign io_refill_to_ldq_bits_addr = ldq_s.addr;
  assign io_refill_to_ldq_bits_data = ldq_s.data;
  assign io_refill_to_ldq_bits_error = ldq_s.error;
  assign io_refill_to_ldq_bits_data_raw = ldq_s.data_raw;
  assign io_refill_to_ldq_bits_hasdata = ldq_s.hasdata;
  assign io_refill_to_ldq_bits_refill_done = ldq_s.refill_done;
  assign io_refill_to_ldq_bits_id = ldq_s.id;
  assign io_main_pipe_req_bits_miss_id = mp_s.miss_id;
  assign io_main_pipe_req_bits_occupy_way = mp_s.occupy_way;
  assign io_main_pipe_req_bits_miss_fail_cause_evict_btot = mp_s.miss_fail_cause_evict_btot;
  assign io_main_pipe_req_bits_source = mp_s.source;
  assign io_main_pipe_req_bits_cmd = mp_s.cmd;
  assign io_main_pipe_req_bits_vaddr = mp_s.vaddr;
  assign io_main_pipe_req_bits_addr = mp_s.addr;
  assign io_main_pipe_req_bits_word_idx = mp_s.word_idx;
  assign io_main_pipe_req_bits_amo_data = mp_s.amo_data;
  assign io_main_pipe_req_bits_amo_mask = mp_s.amo_mask;
  assign io_main_pipe_req_bits_amo_cmp = mp_s.amo_cmp;
  assign io_main_pipe_req_bits_pf_source = mp_s.pf_source;
  assign io_main_pipe_req_bits_access = mp_s.access;
  assign io_main_pipe_req_bits_id = mp_s.id;
  assign io_refill_info_bits_store_data = info_s.store_data;
  assign io_refill_info_bits_miss_param = info_s.miss_param;
  assign io_refill_info_bits_error_tl_denied = info_s.tl_denied;
  assign io_refill_info_bits_error_tl_corrupt = info_s.tl_corrupt;
  assign io_forwardInfo_inflight = fwd_s.inflight;
  assign io_forwardInfo_paddr = fwd_s.paddr;
  assign io_forwardInfo_raw_data_0 = fwd_s.raw_data[0];
  assign io_forwardInfo_raw_data_1 = fwd_s.raw_data[1];
  assign io_forwardInfo_raw_data_2 = fwd_s.raw_data[2];
  assign io_forwardInfo_raw_data_3 = fwd_s.raw_data[3];
  assign io_forwardInfo_raw_data_4 = fwd_s.raw_data[4];
  assign io_forwardInfo_raw_data_5 = fwd_s.raw_data[5];
  assign io_forwardInfo_raw_data_6 = fwd_s.raw_data[6];
  assign io_forwardInfo_raw_data_7 = fwd_s.raw_data[7];
  assign io_forwardInfo_firstbeat_valid = fwd_s.firstbeat_valid;
  assign io_forwardInfo_lastbeat_valid = fwd_s.lastbeat_valid;
  assign io_forwardInfo_denied = fwd_s.denied;
  assign io_forwardInfo_corrupt = fwd_s.corrupt;
  assign io_queryME_0_primary_ready = query_primary_ready_s[0];
  assign io_queryME_1_primary_ready = query_primary_ready_s[1];
  assign io_queryME_2_primary_ready = query_primary_ready_s[2];
  assign io_queryME_3_primary_ready = query_primary_ready_s[3];
  assign io_queryME_0_secondary_ready = query_secondary_ready_s[0];
  assign io_queryME_1_secondary_ready = query_secondary_ready_s[1];
  assign io_queryME_2_secondary_ready = query_secondary_ready_s[2];
  assign io_queryME_3_secondary_ready = query_secondary_ready_s[3];
  assign io_queryME_0_secondary_reject = query_secondary_reject_s[0];
  assign io_queryME_1_secondary_reject = query_secondary_reject_s[1];
  assign io_queryME_2_secondary_reject = query_secondary_reject_s[2];
  assign io_queryME_3_secondary_reject = query_secondary_reject_s[3];
  assign io_latency_monitor_load_miss_refilling = latency_refilling_s[0];
  assign io_latency_monitor_store_miss_refilling = latency_refilling_s[1];
  assign io_latency_monitor_amo_miss_refilling = latency_refilling_s[2];
  assign io_latency_monitor_pf_miss_refilling = latency_refilling_s[3];

  xs_MissEntry_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .id                        (io_id),
    .req_valid                 (io_req_valid),
    .req_cancel                (io_req_bits_cancel),
    .wbq_block_miss_req        (io_wbq_block_miss_req),
    .primary_valid             (io_primary_valid),
    .primary_ready             (io_primary_ready),
    .secondary_ready           (io_secondary_ready),
    .secondary_reject          (io_secondary_reject),
    .req_handled               (io_req_handled_by_this_entry),
    .pipe_alloc                (io_miss_req_pipe_reg_alloc),
    .pipe_merge                (io_miss_req_pipe_reg_merge),
    .pipe_cancel               (io_miss_req_pipe_reg_cancel),
    .acquire_fired_by_pipe_reg (io_acquire_fired_by_pipe_reg),
    .acquire_ready             (io_mem_acquire_ready),
    .acquire_valid             (io_mem_acquire_valid),
    .grant_valid               (io_mem_grant_valid),
    .finish_ready              (io_mem_finish_ready),
    .finish_valid              (io_mem_finish_valid),
    .finish_sink               (io_mem_finish_bits_sink),
    .l2_hint_valid             (io_l2_hint_valid),
    .mp_req_ready              (io_main_pipe_req_ready),
    .mp_req_valid              (io_main_pipe_req_valid),
    .mp_resp                   (io_main_pipe_resp),
    .mp_refill_resp            (io_main_pipe_refill_resp),
    .mp_replay                 (io_main_pipe_replay),
    .mp_evict_BtoT_way         (io_main_pipe_evict_BtoT_way),
    .mp_next_evict_way         (io_main_pipe_next_evict_way),
    .refill_info_valid         (io_refill_info_valid),
    .refill_ldq_valid          (io_refill_to_ldq_valid),
    .probe_addr                (io_probe_req_bits_addr),
    .probe_vaddr               (io_probe_req_bits_vaddr),
    .probe_block               (io_probe_block),
    .replace_addr              (io_replace_req_bits_addr),
    .replace_vaddr             (io_replace_req_bits_vaddr),
    .replace_block             (io_replace_block),
    .occupy_way                (io_occupy_way),
    .req_vaddr_valid           (io_req_vaddr_valid),
    .req_vaddr_bits            (io_req_vaddr_bits),
    .req_isBtoT                (io_req_isBtoT),
    .l2_pf_store_only          (io_l2_pf_store_only),
    .memSetPattenDetected      (io_memSetPattenDetected),
    .rob_head_vaddr            (io_rob_head_query_vaddr),
    .rob_head_query_valid      (io_rob_head_query_query_valid),
    .rob_head_resp             (io_rob_head_query_resp),
    .perf_pending_prefetch     (io_perf_pending_prefetch),
    .perf_pending_normal       (io_perf_pending_normal),
    .late_prefetch             (io_prefetch_info_late_prefetch),
    .matched                   (io_matched),
    .l1Miss                    (io_l1Miss),
    .wfi_req                   (io_wfi_wfiReq),
    .wfi_safe                  (io_wfi_wfiSafe),
    .req                       (req_s),
    .query_req                 (query_s),
    .pipe                      (pipe_s),
    .grant                     (grant_s),
    .acquire                   (acq_s),
    .refill_ldq                (ldq_s),
    .mp_req                    (mp_s),
    .refill_info               (info_s),
    .fwd                       (fwd_s),
    .query_primary_ready       (query_primary_ready_s),
    .query_secondary_ready     (query_secondary_ready_s),
    .query_secondary_reject    (query_secondary_reject_s),
    .latency_refilling         (latency_refilling_s)
  );
  // END GENERATED

endmodule
