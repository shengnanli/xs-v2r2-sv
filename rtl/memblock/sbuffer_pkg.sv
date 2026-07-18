// =============================================================================
//  sbuffer_pkg —— Sbuffer（store 写合并缓冲）可读重写用的类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala
//
//  Sbuffer 位于 MemBlock store 通路末端：被 StoreQueue 提交的 store（已确定地址+数据
//  +字节掩码）不会逐条写 DCache，而是先攒进 Sbuffer。Sbuffer 维护 StoreBufferSize 个
//  「cacheline 缓冲 entry」，把落在同一条 cacheline 的多个 store 合并（merge）到同一
//  entry，等到 entry 攒够（buffer 接近满）/ 超时（cohCount 计满）/ 被 flush/fence 时，
//  再把整条 cacheline（512b 数据 + 64B 掩码）一次性写进 DCache（write coalescing）。
//  同时给 load 流水提供 forward：load 可从尚未写回 DCache 的 store 数据里前递最新字节。
//
//  ── entry 状态（见 sbuf_state_t，对应 Scala SbufferEntryState 的 4 个 bool）──────
//      state_valid           ：该 entry 活跃（占用一条 cacheline）
//      state_inflight        ：正在/已向 DCache 发该 entry 的写请求，等 DCache 回应
//      w_timeout             ：DCache 回了 replay（需重发），挂起等 replay 计数超时再重试
//      w_sameblock_inflight  ：分配时发现同 block 已有 entry 在途，先挂起等它写完
//    生命周期：
//      invalid ──alloc──▶ active(valid&!inflight) ──发DCache写──▶ inflight
//                              ▲                                      │
//                              └──────── replay(w_timeout) ◀──────────┘
//                         hit_resp ──▶ invalid（释放）
//
//  ── 三个并发处理面（对应 Scala 分节）──────────────────────────────────────
//   (1) Enq（in_s0/s1/s2）：收 EnsbufferWidth 路 store，查同 ptag 的 active entry →
//       命中则 merge（按字节掩码合并进该 entry 的 data/mask），否则 alloc 新 entry
//       （奇/偶下标分组分配，两路并发不冲突）。data/mask 用 2 拍流水写入。
//   (2) Deq（out_s0/s1）：按优先级在 drain / cohTimeOut / replace(PLRU) 里选一个
//       evictionIdx，置 inflight，组 DCache 写请求（getAddr + 整行 data/mask）。
//   (3) Resp：收 DCache hit_resp 释放 entry（清 valid/inflight、清该行 mask）；收
//       replay_resp 挂 w_timeout 等重发。
//   另有 forward 面：load 用 vaddr CAM 命中 active/inflight entry，逐字节前递 data。
//
//  ── 全局 4 态状态机 sbuffer_state（控制 deq 优先级与是否收新 store）──────────
//      x_idle    ：正常；buffer 接近满触发 do_eviction → x_replace
//      x_replace ：按 PLRU 逐出，直到不再需要逐出回 x_idle
//      x_drain_all     ：flush/fence，排空 sbuffer + storeQueue，empty 后回 idle
//      x_drain_sbuffer ：仅排空 sbuffer（micro-arch drain，如 forward/merge vtag 失配）
//
//  ── 本工程 KunmingHu V2R2 配置固化参数（与 golden Sbuffer.sv 端口对齐）─────────
//      StoreBufferSize = 16  →  SB_IDX_W = 4（entry 下标 4 位；DCache id 端口 6 位但仅低 4 有效）
//      EnsbufferWidth  = 2   →  入口 2 路；LoadPipelineWidth = 3 → forward 3 路
//      VLEN=128（入口 data 128b/mask 16b），PAddrBits=48，VAddrBits=50
//      CacheLineSize=512（DCache 写口 data 512b/mask 64b），CacheLineVWords=4（每行 4×16B）
//      EvictCycles=1<<20 → EVICT_CNT_W=21；SbufferReplayDelayCycles=16 → REPLAY_CNT_W=5
//      本配置 EnableStorePrefetchSPB / AtCommit 均 false、Difftest 关、无 csrCtrl/hartId：
//      故 store_prefetch 仅由黑盒 StorePfWrapper 直驱，threshold/base 固化为 7/4。
// =============================================================================
package sbuffer_pkg;

  // ---- 关键位宽/常量（与香山 KunmingHu V2R2 配置一致）-----------------------
  localparam int SB_SIZE      = 16;                // StoreBufferSize（cacheline entry 数）
  localparam int SB_IDX_W     = 4;                 // log2Up(SB_SIZE)
  localparam int ENSB_W       = 2;                 // EnsbufferWidth（入口路数）
  localparam int LD_WIDTH     = 3;                 // LoadPipelineWidth（forward 路数）

  localparam int VLEN         = 128;
  localparam int VDATA_BYTES  = 16;                // VLEN/8（入口一拍数据字节数 = VWord 字节数）
  localparam int PADDR_BITS   = 48;
  localparam int VADDR_BITS   = 50;

  localparam int CLINE_BITS   = 512;               // CacheLineSize（DCache 写口数据宽）
  localparam int CLINE_BYTES  = 64;                // CacheLineSize/8（写口掩码宽）
  localparam int CLINE_VWORDS = 4;                 // CacheLineBytes/VDataBytes = 64/16
  localparam int VWORDS_W     = 2;                 // log2Up(CLINE_VWORDS)

  localparam int OFFSET_W     = 6;                 // log2Up(CacheLineBytes=64)
  localparam int PTAG_W       = PADDR_BITS - OFFSET_W;   // 48-6 = 42
  localparam int VTAG_W       = VADDR_BITS - OFFSET_W;   // 50-6 = 44

  // cohCount：每拍 +1，最高位（[EVICT_CNT_W-1]）置 1 表示超时该逐出
  localparam int EVICT_CNT_W  = 21;                // log2Up(EvictCycles+1)，EvictCycles=1<<20
  // missqReplayCount：replay 后每拍 +1，最高位置 1 表示重发延时到，可再次逐出
  localparam int REPLAY_CNT_W = 5;                 // log2Up(16)+1

  // 逐出阈值（Constantin 固化）：StoreBufferThreshold=7, base=4
  //   forceThreshold = force_write ? (7-4)=3 : 7
  localparam logic [4:0] SBUF_THRESHOLD = 5'd7;
  localparam logic [4:0] SBUF_BASE      = 5'd4;

  // ---- 全局状态机 4 态（needDrain = state[1]）-------------------------------
  typedef enum logic [1:0] {
    X_IDLE          = 2'h0,
    X_REPLACE       = 2'h1,
    X_DRAIN_ALL     = 2'h2,
    X_DRAIN_SBUFFER = 2'h3
  } sbuf_gstate_e;

  // ---- 单 entry 状态（4 bool，对应 Scala SbufferEntryState）-----------------
  typedef struct packed {
    logic state_valid;            // entry 活跃
    logic state_inflight;         // 正向 DCache 写该行，等回应
    logic w_timeout;              // 收到 replay，等重发延时
    logic w_sameblock_inflight;   // 分配时同 block 有 entry 在途，先挂起
  } sbuf_state_t;

  // ---- entry 元数据（每 entry 一份；data/mask 单独在核内用 2 维数组存）--------
  //   tag 用 ptag（物理）做 DCache 写地址与同 block 判定；vtag（虚拟）做 forward CAM
  //   与 vtag 一致性检查（merge/forward vtag 失配 → micro-arch drain）。
  typedef struct packed {
    logic [PTAG_W-1:0] ptag;
    logic [VTAG_W-1:0] vtag;
  } sbuf_meta_t;

  // ---- 入口请求（DCacheWordReqWithVaddrAndPfFlag 的相关字段）-----------------
  typedef struct packed {
    logic [VADDR_BITS-1:0] vaddr;
    logic [VLEN-1:0]       data;
    logic [VDATA_BYTES-1:0] mask;
    logic [PADDR_BITS-1:0] addr;
    logic                  wline;     // 整行写（vector wline store）
    logic                  vecValid;  // 该路有效（vector mask 后是否真有字节）
  } sbuf_inreq_t;

  // ===========================================================================
  //  纯函数：tag/word 抽取、对齐、entry 状态判定
  // ===========================================================================
  function automatic logic [PTAG_W-1:0] get_ptag(input logic [PADDR_BITS-1:0] pa);
    return pa[PADDR_BITS-1 -: PTAG_W];
  endfunction
  function automatic logic [VTAG_W-1:0] get_vtag(input logic [VADDR_BITS-1:0] va);
    return va[VADDR_BITS-1 -: VTAG_W];
  endfunction
  // getVWord：物理地址按 16B 字粒度（去掉低 4 位）；forward 取行内 VWord 偏移
  function automatic logic [VWORDS_W-1:0] get_vword_off(input logic [PADDR_BITS-1:0] pa);
    return pa[OFFSET_W-1 -: VWORDS_W];      // OFFSET_W-1 .. VWordWidth(=4)，即 [5:4]
  endfunction
  // getAddr：由 ptag 还原 cacheline 基址（低 OFFSET_W 位补 0）
  function automatic logic [PADDR_BITS-1:0] addr_from_ptag(input logic [PTAG_W-1:0] pt);
    return {pt, {OFFSET_W{1'b0}}};
  endfunction

  // entry 状态判定（对应 Scala 的 isXxx 方法）
  function automatic logic st_is_invalid(input sbuf_state_t s); return ~s.state_valid; endfunction
  function automatic logic st_is_valid  (input sbuf_state_t s); return  s.state_valid; endfunction
  function automatic logic st_is_active (input sbuf_state_t s); return  s.state_valid & ~s.state_inflight; endfunction
  function automatic logic st_is_inflight(input sbuf_state_t s); return s.state_inflight; endfunction
  // 可作为 DCache 写候选：valid & !inflight & !同block在途
  function automatic logic st_is_dcache_cand(input sbuf_state_t s);
    return s.state_valid & ~s.state_inflight & ~s.w_sameblock_inflight;
  endfunction

  // ---- 优先级编码：返回最低位 1 的下标（无 1 则 0）---------------------------
  function automatic logic [SB_IDX_W-1:0] prio_enc16(input logic [SB_SIZE-1:0] v);
    prio_enc16 = '0;
    for (int i = SB_SIZE-1; i >= 0; i--) if (v[i]) prio_enc16 = i[SB_IDX_W-1:0];
  endfunction

  // ---- golden ParallelPriorityMux 形态：低位优先，**全 0 时默认末项 15**
  //   （golden evictionIdx 的 drain/cohTimeOut 编码尾项是 {3'h7, ~v[14]}：
  //    v[14]→14，否则 15；只有 fire 门控外的消费者(shouldWaitWriteFinish)看得出差别）
  function automatic logic [SB_IDX_W-1:0] prio_enc16_deflast(input logic [SB_SIZE-1:0] v);
    prio_enc16_deflast = 4'hF;
    for (int i = SB_SIZE-2; i >= 0; i--) if (v[i]) prio_enc16_deflast = i[SB_IDX_W-1:0];
  endfunction

  // ---- getFirstOneOH：在一串 bit 里取「第一个 1」的 one-hot（Scala getFirstOneOH）
  function automatic logic [7:0] first_one_oh8(input logic [7:0] v);
    logic seen;           // 已遇到更低位的 1
    seen = 1'b0;
    first_one_oh8 = '0;
    for (int i = 0; i < 8; i++) begin
      first_one_oh8[i] = ~seen & v[i];
      seen = seen | v[i];
    end
  endfunction

  // ---- popcount（valid 计数用）----------------------------------------------
  function automatic logic [4:0] popcnt16(input logic [SB_SIZE-1:0] v);
    popcnt16 = '0;
    for (int i = 0; i < SB_SIZE; i++) popcnt16 += {4'h0, v[i]};
  endfunction

endpackage
