// =============================================================================
//  missqueue_pkg —— DCache MissQueue 可读重写用类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/cache/dcache/mainpipe/MissQueue.scala（class MissQueue）
//
//  MissQueue 是 L1 DCache 的「未命中处理队列」（MSHR file，Kroft 1981 lockup-free cache）。
//  它持有 nMissEntries(=16) 个 MissEntry（每个是一个 MSHR：一条在途的 cacheline 缺失），
//  经 TileLink A 通道（mem_acquire）向 L2 发 refill 请求，收 D 通道（mem_grant）数据后写回
//  DCache 并唤醒等待的 load/store。本工程把「每条 MSHR 的状态机 MissEntry」「CMO 状态机
//  CMOUnit」「amo main_pipe_req 仲裁 FastArbiter」都当 golden 黑盒；可读核 xs_MissQueue_core
//  只重写「队列级」黏合逻辑：
//    (1) 入队两段流水（s0 arbiter 判 alloc/merge/reject → miss_req_pipe_reg → s1 真正写 entry）；
//    (2) 把请求唯一分给「最低空闲下标」的 entry（primary_valid one-hot）；
//    (3) 4 路 queryMQ「能否被收下」的提前判定（与主请求同构，给上游做 timing）；
//    (4) miss_req_pipe_reg 直接产生一条 acquire（acquire_from_pipereg，尽早发请求降低延迟）；
//    (5) TileLink 通道仲裁：mem_acquire（lowest 优先：cmo > pipereg > entry0..15，共 18 源）、
//        mem_finish（lowest 优先：entry0..15，共 16 源）；
//    (6) mem_grant 按 source 路由到对应 entry（或 CBOAck → CMOUnit）；
//    (7) refill_info（给 MainPipe s2 唤醒）、probe/replace block、btot/occupy 冲突、
//        3 路 load forward（从在途 MSHR 前递尚未写回的 refill 数据）。
//
//  详见 docs/memblock/MissQueue.md。
//  本配置（与 golden 裁剪一致）：nMissEntries=16, reqNum(=queryMQ 路数)=3? 实际 golden 端口
//  暴露 4 路 queryMQ（reqNum=4）, LoadPipelineWidth=3（forward/occupy 3 路）。
// =============================================================================
package missqueue_pkg;

  // ---- 队列规模 ----
  localparam int unsigned N_ENTRY      = 16;  // cfg.nMissEntries：MSHR 条数
  localparam int unsigned ENTRY_IDX_W  = 4;   // log2Up(16)
  localparam int unsigned N_QUERY      = 4;   // queryMQ 路数（reqNum）
  localparam int unsigned LD_WIDTH     = 3;   // LoadPipelineWidth：forward/occupy 路数

  // ---- 仲裁源数 ----
  //  mem_acquire（A 通道）的 lowest-优先源：idx0=CMOUnit, idx1=pipereg, idx2..17=entry0..15
  localparam int unsigned N_ACQ_SRC    = 18;
  //  mem_finish（E 通道）的 lowest-优先源：idx0..15 = entry0..15
  localparam int unsigned N_FIN_SRC    = 16;

  // ---- 地址 / 数据位宽（与 golden 扁平端口一致）----
  localparam int unsigned PADDR_BITS   = 48;
  localparam int unsigned VADDR_BITS   = 50;
  localparam int unsigned SRC_BITS     = 6;   // TL source id 位宽
  localparam int unsigned ACQ_SRC_ID   = 17;  // CMOUnit 在 A 通道用的 source id (nMissEntries+1)
  localparam int unsigned BLOCK_BITS   = 512; // 一整行 64B = 512 bit
  localparam int unsigned BLOCK_MASK_W = 64;
  localparam int unsigned FWD_BEATS    = 8;   // raw_data 切成 8×64bit（blockBytes/8）

  // ---- 请求来源编码（DCacheBundle source）----
  //  Note：source 不是 cmd。只用其值判定来路。
  typedef enum logic [3:0] {
    SRC_LOAD   = 4'h0,   // LOAD_SOURCE
    SRC_STORE  = 4'h1,   // STORE_SOURCE
    SRC_AMO    = 4'h2,   // AMO_SOURCE
    SRC_PREF   = 4'h3    // DCACHE_PREFETCH_SOURCE（>=3 都算 prefetch）
  } req_source_e;

  // ---- TileLink A 通道 user.reqSource（MemReqSource）----
  localparam logic [4:0] REQSRC_CPU_LOAD   = 5'h2;  // CPULoadData
  localparam logic [4:0] REQSRC_CPU_STORE  = 5'h3;  // CPUStoreData
  // L1DataPrefetch 在 golden 里被编成 {3'h1, src!=AMO, 1'h0}（见 get_acquire reqSource）

  // ---------------------------------------------------------------------------
  //  miss_req_pipe_reg：MissReq 的「入队第二级」流水寄存器（class MissReqPipeRegBundle）。
  //  只保留 queue 级逻辑真正用到的字段（与 golden 一致：amo/store_data 等也在 entry 用到，
  //  但 queue 级仅在 acquire/merge/reject 判定中用 source/cmd/addr/vaddr/coh/id/btot/way/
  //  full_overwrite）。这里用 struct 聚合，写时序与 golden 完全一致（io_req.valid 时锁存
  //  payload；alloc/merge/cancel/mshr_id 每拍按判定结果更新）。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [3:0]                source;
    logic [2:0]                pf_source;
    logic [4:0]                cmd;
    logic [PADDR_BITS-1:0]     addr;
    logic [VADDR_BITS-1:0]     vaddr;
    logic                      full_overwrite;
    logic [2:0]                word_idx;
    logic [127:0]              amo_data;
    logic [15:0]               amo_mask;
    logic [127:0]              amo_cmp;
    logic [1:0]                req_coh_state;
    logic [SRC_BITS-1:0]       id;
    logic                      isBtoT;
    logic [3:0]                occupy_way;
    logic [BLOCK_BITS-1:0]     store_data;
    logic [BLOCK_MASK_W-1:0]   store_mask;
  } miss_req_t;

  // ---------------------------------------------------------------------------
  //  lowest-优先仲裁的 winner one-hot：winner[i] = valid[i] & ~(|valid[0..i-1])。
  //  对应 Rocket Arbiter「lowest」策略（idx0 最高优先）。这里用纯函数表达「前缀或」。
  //  注意 N 路输入，返回 N 位 one-hot（至多一位 1）。
  // ---------------------------------------------------------------------------
  //  TLArbiter「ready/allowed」语义（关键坑）：源 i 被「允许」当且仅当没有更高优先级
  //  (下标更小) 的源 valid——**与源 i 自身是否 valid 无关**。各源的通道 ready 据此给出
  //  （ready[i] = sink.ready & allowed[i]）。winner[i] = allowed[i] & valid[i]（用于 payload）。
  function automatic logic [N_ACQ_SRC-1:0] lowest_allowed_acq(input logic [N_ACQ_SRC-1:0] valid);
    logic [N_ACQ_SRC-1:0] a;
    logic                  higher;     // 是否已有更高优先级 valid
    higher = 1'b0;
    for (int i = 0; i < N_ACQ_SRC; i++) begin
      a[i]   = ~higher;
      higher = higher | valid[i];
    end
    return a;
  endfunction

  function automatic logic [N_FIN_SRC-1:0] lowest_allowed_fin(input logic [N_FIN_SRC-1:0] valid);
    logic [N_FIN_SRC-1:0] a;
    logic                  higher;
    higher = 1'b0;
    for (int i = 0; i < N_FIN_SRC; i++) begin
      a[i]   = ~higher;
      higher = higher | valid[i];
    end
    return a;
  endfunction

  // ---------------------------------------------------------------------------
  //  pipereg 直发 acquire 的 grow_param 推导（ClientMetadata(coh).onAccess(cmd)._2）。
  //  grow_param = 把当前一致性权限「升」到本次访问所需权限时的 TLPermissions 增量编码
  //  （NtoB=0,NtoT=1,BtoT=2,...，取值 0..3）。穷举 golden 全 (coh,cmd) 表归纳出三类 cmd：
  //    · coh==3（已 Trunk/独占）：param 恒 3（无需 grow）；否则按 cmd 类别：
  //      (A) is_write_intent（普通写/AMO/CBO 等需独占）：param = coh + 1（coh0→1,1→2,2→3）；
  //      (B) LR/SC（cmd==M_XLR(3) | M_XSC(6)）：param = coh0→1，coh1/2→2（升到 BtoT 即止）；
  //      (C) 纯读（其余）：param = coh（coh0→0,1→1,2→2）。
  //  注：(A) 与 (B) 只在 coh==2 时分叉（A→3 独占, B→2 共享升级）；(B)(C) 的差异在 coh!=0。
  // ---------------------------------------------------------------------------
  //  写意图 cmd 集合（穷举 golden grow_param 表归纳）：1,11,7,4,9,A,B,8,C,D,E,F,1A,1B,18
  function automatic logic is_write_intent(input logic [4:0] cmd);
    return (cmd == 5'h01) | (cmd == 5'h11) | (cmd == 5'h07) | (cmd == 5'h04)
         | (cmd == 5'h09) | (cmd == 5'h0A) | (cmd == 5'h0B) | (cmd == 5'h08)
         | (cmd == 5'h0C) | (cmd == 5'h0D) | (cmd == 5'h0E) | (cmd == 5'h0F)
         | (cmd == 5'h1A) | (cmd == 5'h1B) | (cmd == 5'h18);
  endfunction
  function automatic logic is_lr_sc(input logic [4:0] cmd);
    return (cmd == 5'h03) | (cmd == 5'h06);
  endfunction

  //  grow_param（3 位，实际取值 0..3）。
  function automatic logic [2:0] grow_param(input logic [4:0] cmd, input logic [1:0] coh_state);
    if (coh_state == 2'h3)         return 3'h3;
    else if (is_write_intent(cmd)) return 3'(coh_state) + 3'h1;     // coh0→1,1→2,2→3
    else if (is_lr_sc(cmd))        return (coh_state == 2'h0) ? 3'h1 : 3'h2;
    else                           return 3'(coh_state);           // 纯读：coh0→0,1→1,2→2
  endfunction

endpackage
