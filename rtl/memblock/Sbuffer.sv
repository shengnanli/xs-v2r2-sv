// =============================================================================
//  Sbuffer.sv —— store 写合并缓冲（MemBlock store 通路末端的 cacheline 攒批器）
// -----------------------------------------------------------------------------
//  位置：StoreQueue 提交的 store（地址+数据+字节掩码都已确定）不逐条写 DCache，
//        而是先进 Sbuffer 攒成整条 cacheline，再一次性写 DCache（write coalescing）。
//        同时给 load 流水提供 forward：load 能从还没写回 DCache 的 store 里取最新字节。
//  输入：io_in_0/1（2 路已提交 store）、io_forward_0..2（3 路 load 前递查询）、
//        io_dcache_*（DCache 写口与 hit/replay 回应）、io_flush/io_sqempty（fence）。
//  输出：io_dcache_req（整行 512b 数据 + 64B 掩码）、io_forward_*_forwardMask/Data、
//        io_sbempty/io_sbFull/io_flush_empty、16 路 perf、4 根 difftest gateway 总线。
//  核心机制：16 条 cacheline entry 的 {ptag,vtag} CAM —— 同 ptag 命中就 merge，
//        否则按奇/偶分组取空位 alloc；逐出顺序 = replay超时 > drain > coh超时 > PLRU。
//
//  文件结构（单文件规范）：sbuffer_pkg → xs_Sbuffer_core（可读核）→ Sbuffer（wrapper）。
//  数据体（每 entry 4×16B 的 data/mask 阵列）在**独立目标 SbufferData** 里，
//  由 wrapper 例化 `dataModule`；本核只出写请求、收全体读出（见 §7/§8）。
//  该子模块在 UT/FM 的 impl 侧用的是重写件 rtl/memblock/SbufferData.sv。
// =============================================================================
// 本文件导航（共 3843 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L37    位置：StoreQueue 提交的 store
//   L54    sbuffer_pkg —— Sbuffer 私有的位宽常量 / entry 类型 / 纯函数
//   L56    设计意图来源
//   L146   纯函数：tag / 行内字偏移 / 对齐 / entry 状态判定
//   L202   ValidPseudoLRU(16)：15 位树状态上的「取最旧的有效候选」与「touch 更新」
//   L204   树叶布局
//   L211   一级合并：左子
//   L251   xs_Sbuffer_core —— Sbuffer 可读核
//   L477   §1 入口聚合：两路 store 端口打成数组，后面一律用 for/genvar 统一处理
//   L488   §2 entry 存储
//   L490   golden 顶层是一组独立的 vtag_<i>/ptag_<i> 寄存器
//   L517   §3 全局 4 态状态机
//   L523   §4 PLRU：在「DCache 写候选」里选最旧的一条
//   L525   Scala 是 plru.way(candidateVec.reverse)：候选序反着喂进 ValidPseudoLRU
//   L554   §5 两个超时：coh
//   L556   ★G1 相对 G0 的真逻辑变化★：coh 超时阈值从固定的 cohCount[20] 位测试，
//   L589   §6 Enq
//   L682   §7 写数据请求：merge 打到 mergeVec，alloc 打到 insertVec；数据体在 dataModule
//   L711   §3' 逐出触发 / 空满标志 / 状态机转移
//   L760   §8 Deq：out_s0 选 victim，out_s1 组 DCache 整行写请求
//   L762   优先级：missqReplay 超时 > drain
//   L832   §9 Resp：hit_resp 释放 entry / replay_resp 挂超时重发；entry 时序统一更新
//   L947   §10 Forward：把还没写回 DCache 的 store 字节前递给 load
//   L949   f0：用 forward.vaddr 做 vtag CAM，分「active 候选」与「inflight 候选」两类；
//   L1155  §11 PLRU touch：三个 touch 口在同一拍**依次叠加**
//   L1157  ValidPseudoLRU.access(Seq(t0,t1,t2)) 的语义是后一个基于前一个的结果再更新
//   L1176  §12 perf 事件
//   L1224  §13 difftest gateway
//   L1226  四根打包总线被 XSTop 里的 difftest gateway「bore」走，内容是纯组合的观测量：
//   L1332  Sbuffer —— golden 同名 wrapper
//   L1334  端口与 golden Sbuffer 逐位同名同序；内部例化：
//

// =============================================================================
//  sbuffer_pkg —— Sbuffer 私有的位宽常量 / entry 类型 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala
//
//  ── entry 状态（sbuf_state_t，对应 Scala SbufferEntryState 的 4 个 bool）──────
//      state_valid           ：该 entry 活跃（占用一条 cacheline）
//      state_inflight        ：已向 DCache 发该 entry 的写请求，等回应
//      w_timeout             ：DCache 回了 replay，挂起等重发延时
//      w_sameblock_inflight  ：alloc 时发现同 block 已有 entry 在途，先挂起等它写完
//    生命周期：
//      invalid ──alloc──▶ active(valid&!inflight) ──发 DCache 写──▶ inflight
//                              ▲                                      │
//                              └──────── replay(w_timeout) ◀──────────┘
//                         hit_resp ──▶ invalid（释放）
//
//  ── 全局 4 态状态机 sbuffer_state（控制 deq 优先级与是否收新 store）──────────
//      x_idle          ：正常；buffer 接近满触发 do_eviction → x_replace
//      x_replace       ：按 PLRU 逐出，直到不再需要逐出回 x_idle
//      x_drain_all     ：flush/fence，排空 sbuffer + storeQueue，empty 后回 idle
//      x_drain_sbuffer ：仅排空 sbuffer（micro-arch drain：forward/merge vtag 失配）
//
//  ── 本工程 KunmingHu V2（G1）配置固化参数 ──────────────────────────────────
//      StoreBufferSize=16（SB_IDX_W=4；DCache id 端口 6 位但仅低 4 位有效）
//      EnsbufferWidth=2，LoadPipelineWidth=3，VLEN=128，PAddrBits=48，VAddrBits=50
//      CacheLineSize=512（写口 data 512b/mask 64b），CacheLineVWords=4（每行 4×16B）
//      EvictCycles=1<<20 → cohCount 21 位；SbufferReplayDelayCycles=16 → 5 位
//      StoreBufferThreshold=7 / base=4（forceThreshold = force_write ? 3 : 7）
//  ★与上一轮 G0 的差别★：G1 的 coh 超时阈值不再是固定的 cohCount[20]，
//      而是可由 CSR 编程的 io_csrCtrl_sbuffer_timeout（22 位无符号比较），见核 §5。
// =============================================================================
package sbuffer_pkg;

  // ---- 关键位宽/常量 --------------------------------------------------------
  localparam int SB_SIZE      = 16;   // StoreBufferSize（cacheline entry 数）
  localparam int SB_IDX_W     = 4;    // log2Up(SB_SIZE)
  localparam int ENSB_W       = 2;    // EnsbufferWidth（入口路数）
  localparam int LD_WIDTH     = 3;    // LoadPipelineWidth（forward 路数）

  localparam int VLEN         = 128;
  localparam int VDATA_BYTES  = 16;   // VLEN/8 = 一个 VWord 的字节数
  localparam int PADDR_BITS   = 48;
  localparam int VADDR_BITS   = 50;

  localparam int CLINE_BITS   = 512;  // CacheLineSize（DCache 写口数据宽）
  localparam int CLINE_BYTES  = 64;   // CacheLineSize/8（写口掩码宽）
  localparam int CLINE_VWORDS = 4;    // CacheLineBytes/VDataBytes = 64/16
  localparam int VWORDS_W     = 2;    // log2Up(CLINE_VWORDS)

  localparam int OFFSET_W     = 6;                       // log2Up(CacheLineBytes=64)
  localparam int PTAG_W       = PADDR_BITS - OFFSET_W;   // 48-6 = 42
  localparam int VTAG_W       = VADDR_BITS - OFFSET_W;   // 50-6 = 44

  // SbufferData 的 vwordOffset 端口是「16B 字地址」整条（paddr[47:4]），
  // 只有低 VWORDS_W 位真正参与行内选字；宽度照抄 golden 端口。
  localparam int VWOFF_W      = PADDR_BITS - 4;          // = 44

  localparam int EVICT_CNT_W  = 21;   // cohCount 位宽（EvictCycles=1<<20）
  localparam int REPLAY_CNT_W = 5;    // missqReplayCount 位宽（延时 16 拍 + 溢出位）
  localparam int TIMEOUT_W    = 22;   // io_csrCtrl_sbuffer_timeout 位宽

  // difftest gateway 打包总线宽度（见核 §10；与 golden 端口逐位一致）
  localparam int BORE_SB_W    = 657;  // {valid,addr,64B data,64b mask,coreid,index}
  localparam int BORE_ST_W    = 325;  // {valid,addr,data,highData,mask,wLine,...}

  // ---- 全局状态机 4 态（needDrain = state[1]）-------------------------------
  typedef enum logic [1:0] {
    X_IDLE          = 2'h0,
    X_REPLACE       = 2'h1,
    X_DRAIN_ALL     = 2'h2,
    X_DRAIN_SBUFFER = 2'h3
  } sbuf_gstate_e;

  // ---- 单 entry 状态（4 bool，对应 Scala SbufferEntryState）-----------------
  typedef struct packed {
    logic state_valid;
    logic state_inflight;
    logic w_timeout;
    logic w_sameblock_inflight;
  } sbuf_state_t;

  // ---- 入口请求（DCacheWordReqWithVaddrAndPfFlag 里本层用到的字段）-----------
  typedef struct packed {
    logic [VADDR_BITS-1:0]  vaddr;
    logic [VLEN-1:0]        data;
    logic [VDATA_BYTES-1:0] mask;
    logic [PADDR_BITS-1:0]  addr;
    logic                   wline;     // 整行写（vector wline store）
    logic                   vecValid;  // 该路 vector mask 后确实有字节
  } sbuf_inreq_t;

  // ===========================================================================
  //  纯函数：tag / 行内字偏移 / 对齐 / entry 状态判定
  // ===========================================================================
  function automatic logic [PTAG_W-1:0] get_ptag(input logic [PADDR_BITS-1:0] pa);
    return pa[PADDR_BITS-1 -: PTAG_W];
  endfunction
  function automatic logic [VTAG_W-1:0] get_vtag(input logic [VADDR_BITS-1:0] va);
    return va[VADDR_BITS-1 -: VTAG_W];
  endfunction
  // getVWord：行内 16B 字偏移（paddr[5:4]）
  function automatic logic [VWORDS_W-1:0] get_vword_off(input logic [PADDR_BITS-1:0] pa);
    return pa[OFFSET_W-1 -: VWORDS_W];
  endfunction
  // getAddr：由 ptag 还原 cacheline 基址（低 OFFSET_W 位补 0）
  function automatic logic [PADDR_BITS-1:0] addr_from_ptag(input logic [PTAG_W-1:0] pt);
    return {pt, {OFFSET_W{1'b0}}};
  endfunction

  function automatic logic st_is_invalid (input sbuf_state_t s); return ~s.state_valid; endfunction
  function automatic logic st_is_valid   (input sbuf_state_t s); return  s.state_valid; endfunction
  function automatic logic st_is_active  (input sbuf_state_t s); return  s.state_valid & ~s.state_inflight; endfunction
  // 可作为 DCache 写候选：valid & !inflight & !同 block 在途
  function automatic logic st_is_dcache_cand(input sbuf_state_t s);
    return s.state_valid & ~s.state_inflight & ~s.w_sameblock_inflight;
  endfunction

  // ---- 优先级编码：最低位 1 的下标（全 0 → 0）-------------------------------
  function automatic logic [SB_IDX_W-1:0] prio_enc16(input logic [SB_SIZE-1:0] v);
    prio_enc16 = '0;
    for (int i = SB_SIZE-1; i >= 0; i--) if (v[i]) prio_enc16 = i[SB_IDX_W-1:0];
  endfunction

  // ---- golden ParallelPriorityMux 形态：低位优先，**全 0 时默认末项 15**。
  //   golden 的 drain/cohTimeOut evictionIdx 编码尾项是 {3'h7, ~v[14]}：v[14] 置起取
  //   14，否则取 15 —— 即「没有候选时也给 15」。这份不对称照抄，不许补成 0。
  function automatic logic [SB_IDX_W-1:0] prio_enc16_deflast(input logic [SB_SIZE-1:0] v);
    prio_enc16_deflast = 4'hF;
    for (int i = SB_SIZE-2; i >= 0; i--) if (v[i]) prio_enc16_deflast = i[SB_IDX_W-1:0];
  endfunction

  // ---- getFirstOneOH：一串 bit 里「第一个 1」的 one-hot（Scala getFirstOneOH）
  function automatic logic [7:0] first_one_oh8(input logic [7:0] v);
    logic seen;
    seen = 1'b0;
    first_one_oh8 = '0;
    for (int i = 0; i < 8; i++) begin
      first_one_oh8[i] = ~seen & v[i];
      seen = seen | v[i];
    end
  endfunction

  function automatic logic [4:0] popcnt16(input logic [SB_SIZE-1:0] v);
    popcnt16 = '0;
    for (int i = 0; i < SB_SIZE; i++) popcnt16 += {4'h0, v[i]};
  endfunction

  // ===========================================================================
  //  ValidPseudoLRU(16)：15 位树状态上的「取最旧的有效候选」与「touch 更新」
  // ---------------------------------------------------------------------------
  //  树叶布局（与 rocket-chip PseudoLRU 注释 + golden 一致）：最左叶 = way15，
  //  最右叶 = way0；分支节点的 state bit 语义是「左子更旧」，两子都有候选时用它选边，
  //  否则直接选有候选的那一侧（左 → idx 高位 1，右 → 0）。
  //    pair（叶对）：15/14→s[11] 13/12→s[10] 11/10→s[8] 9/8→s[7]
  //                  7/6 →s[4]  5/4  →s[3]  3/2  →s[1] 1/0→s[0]
  //    quad：s[12] s[9] s[5] s[2]   oct：s[13] s[6]   root：s[14]
  // ===========================================================================
  // 一级合并：左子（高 way 半区）与右子各给 (有效, 子下标)，输出 (有效, 本级下标)。
  //   nsub = 子下标的有效位数（叶对 0 / quad 1 / oct 2 / root 3）：本级把「选边位」
  //   放到子下标之上一位。★这个位置参数不能省★：四层的下标宽度是逐层长一位的，
  //   用同一个固定宽度拼接会把高位截掉（实测就是这样先错了一版：PLRU 选出的 way
  //   与 golden 不同，UT 第 6 拍就在 io_dcache_req_bits_addr 上炸开）。
  function automatic logic [4:0] plru_join(input logic lv, input logic [3:0] lidx,
                                           input logic rv, input logic [3:0] ridx,
                                           input logic s, input int nsub);
    logic       v, top;
    logic [3:0] sub;
    v = lv | rv;
    if (lv & rv) begin top = s;  sub = s  ? lidx : ridx; end
    else         begin top = lv; sub = lv ? lidx : ridx; end
    return {v, 4'((logic'(top) << nsub) | sub)};
  endfunction

  // touch：把被访问 way 路径上的每个节点置成「指向另一侧」（远离刚被访问的子树）
  function automatic logic [14:0] plru_touch(input logic [14:0] st, input logic [3:0] way);
    logic [14:0] ns;
    ns     = st;
    ns[14] = ~way[3];                                         // root
    if (way[3]) ns[13] = ~way[2]; else ns[6] = ~way[2];        // oct
    if (way[3]) begin                                          // quad
      if (way[2]) ns[12] = ~way[1]; else ns[9] = ~way[1];
    end else begin
      if (way[2]) ns[5]  = ~way[1]; else ns[2] = ~way[1];
    end
    if (way[3]) begin                                          // pair
      if (way[2]) begin if (way[1]) ns[11] = ~way[0]; else ns[10] = ~way[0]; end
      else        begin if (way[1]) ns[8]  = ~way[0]; else ns[7]  = ~way[0]; end
    end else begin
      if (way[2]) begin if (way[1]) ns[4]  = ~way[0]; else ns[3]  = ~way[0]; end
      else        begin if (way[1]) ns[1]  = ~way[0]; else ns[0]  = ~way[0]; end
    end
    return ns;
  endfunction

endpackage

// =============================================================================
//  xs_Sbuffer_core —— Sbuffer 可读核
// -----------------------------------------------------------------------------
//  分节：
//    §1 入口聚合          §2 entry 存储与派生掩码   §3 全局状态机
//    §4 PLRU 选victim     §5 超时（coh / replay）   §6 Enq（merge/alloc）
//    §7 写数据请求        §8 Deq（选 victim → DCache 写）
//    §9 Resp + entry 时序 §10 Forward              §11 PLRU touch
//    §12 perf             §13 difftest gateway
// =============================================================================
module xs_Sbuffer_core
  import sbuffer_pkg::*;
(
  // BEGIN GENERATED(core_ports)
  input          clock,
  input          reset,
  input  [5:0]   io_hartId,
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [49:0]  io_in_0_bits_vaddr,
  input  [127:0] io_in_0_bits_data,
  input  [15:0]  io_in_0_bits_mask,
  input  [47:0]  io_in_0_bits_addr,
  input          io_in_0_bits_wline,
  input          io_in_0_bits_vecValid,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [127:0] io_in_1_bits_data,
  input  [15:0]  io_in_1_bits_mask,
  input  [47:0]  io_in_1_bits_addr,
  input          io_in_1_bits_wline,
  input          io_in_1_bits_vecValid,
  input          io_dcache_req_ready,
  output         io_dcache_req_valid,
  output [49:0]  io_dcache_req_bits_vaddr,
  output [47:0]  io_dcache_req_bits_addr,
  output [511:0] io_dcache_req_bits_data,
  output [63:0]  io_dcache_req_bits_mask,
  output [5:0]   io_dcache_req_bits_id,
  input          io_dcache_main_pipe_hit_resp_valid,
  input  [5:0]   io_dcache_main_pipe_hit_resp_bits_id,
  input          io_dcache_replay_resp_valid,
  input  [5:0]   io_dcache_replay_resp_bits_id,
  input  [49:0]  io_forward_0_vaddr,
  input  [47:0]  io_forward_0_paddr,
  input          io_forward_0_valid,
  output         io_forward_0_forwardMask_0,
  output         io_forward_0_forwardMask_1,
  output         io_forward_0_forwardMask_2,
  output         io_forward_0_forwardMask_3,
  output         io_forward_0_forwardMask_4,
  output         io_forward_0_forwardMask_5,
  output         io_forward_0_forwardMask_6,
  output         io_forward_0_forwardMask_7,
  output         io_forward_0_forwardMask_8,
  output         io_forward_0_forwardMask_9,
  output         io_forward_0_forwardMask_10,
  output         io_forward_0_forwardMask_11,
  output         io_forward_0_forwardMask_12,
  output         io_forward_0_forwardMask_13,
  output         io_forward_0_forwardMask_14,
  output         io_forward_0_forwardMask_15,
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
  output         io_forward_0_matchInvalid,
  input  [49:0]  io_forward_1_vaddr,
  input  [47:0]  io_forward_1_paddr,
  input          io_forward_1_valid,
  output         io_forward_1_forwardMask_0,
  output         io_forward_1_forwardMask_1,
  output         io_forward_1_forwardMask_2,
  output         io_forward_1_forwardMask_3,
  output         io_forward_1_forwardMask_4,
  output         io_forward_1_forwardMask_5,
  output         io_forward_1_forwardMask_6,
  output         io_forward_1_forwardMask_7,
  output         io_forward_1_forwardMask_8,
  output         io_forward_1_forwardMask_9,
  output         io_forward_1_forwardMask_10,
  output         io_forward_1_forwardMask_11,
  output         io_forward_1_forwardMask_12,
  output         io_forward_1_forwardMask_13,
  output         io_forward_1_forwardMask_14,
  output         io_forward_1_forwardMask_15,
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
  output         io_forward_1_matchInvalid,
  input  [49:0]  io_forward_2_vaddr,
  input  [47:0]  io_forward_2_paddr,
  input          io_forward_2_valid,
  output         io_forward_2_forwardMask_0,
  output         io_forward_2_forwardMask_1,
  output         io_forward_2_forwardMask_2,
  output         io_forward_2_forwardMask_3,
  output         io_forward_2_forwardMask_4,
  output         io_forward_2_forwardMask_5,
  output         io_forward_2_forwardMask_6,
  output         io_forward_2_forwardMask_7,
  output         io_forward_2_forwardMask_8,
  output         io_forward_2_forwardMask_9,
  output         io_forward_2_forwardMask_10,
  output         io_forward_2_forwardMask_11,
  output         io_forward_2_forwardMask_12,
  output         io_forward_2_forwardMask_13,
  output         io_forward_2_forwardMask_14,
  output         io_forward_2_forwardMask_15,
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
  output         io_forward_2_matchInvalid,
  input          io_sqempty,
  output         io_sbempty,
  output         io_sbFull,
  input          io_flush_valid,
  output         io_flush_empty,
  input  [21:0]  io_csrCtrl_sbuffer_timeout,
  input          io_force_write,
  input  [49:0]  io_diffStore_diffInfo_0_uop_pc,
  input  [34:0]  io_diffStore_diffInfo_0_uop_fuType,
  input  [8:0]   io_diffStore_diffInfo_0_uop_fuOpType,
  input  [2:0]   io_diffStore_diffInfo_0_uop_vpu_nf,
  input  [1:0]   io_diffStore_diffInfo_0_uop_vpu_veew,
  input  [7:0]   io_diffStore_diffInfo_0_uop_robIdx_value,
  input  [5:0]   io_diffStore_diffInfo_0_offset,
  input  [49:0]  io_diffStore_diffInfo_1_uop_pc,
  input  [34:0]  io_diffStore_diffInfo_1_uop_fuType,
  input  [8:0]   io_diffStore_diffInfo_1_uop_fuOpType,
  input  [2:0]   io_diffStore_diffInfo_1_uop_vpu_nf,
  input  [1:0]   io_diffStore_diffInfo_1_uop_vpu_veew,
  input  [7:0]   io_diffStore_diffInfo_1_uop_robIdx_value,
  input  [5:0]   io_diffStore_diffInfo_1_offset,
  input          io_diffStore_pmaStore_0_valid,
  input  [127:0] io_diffStore_pmaStore_0_bits_data,
  input  [15:0]  io_diffStore_pmaStore_0_bits_mask,
  input  [47:0]  io_diffStore_pmaStore_0_bits_addr,
  input          io_diffStore_pmaStore_0_bits_wline,
  input          io_diffStore_pmaStore_0_bits_vecValid,
  input          io_diffStore_pmaStore_1_valid,
  input  [127:0] io_diffStore_pmaStore_1_bits_data,
  input  [15:0]  io_diffStore_pmaStore_1_bits_mask,
  input  [47:0]  io_diffStore_pmaStore_1_bits_addr,
  input          io_diffStore_pmaStore_1_bits_wline,
  input          io_diffStore_pmaStore_1_bits_vecValid,
  input          io_diffStore_ncStore_valid,
  input  [47:0]  io_diffStore_ncStore_bits_addr,
  input  [63:0]  io_diffStore_ncStore_bits_data,
  input  [7:0]   io_diffStore_ncStore_bits_mask,
  input          io_diffStore_ncStore_bits_memBackTypeMM,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  output [5:0]   io_perf_7_value,
  output [5:0]   io_perf_8_value,
  output [5:0]   io_perf_9_value,
  output [5:0]   io_perf_10_value,
  output [5:0]   io_perf_11_value,
  output [5:0]   io_perf_12_value,
  output [5:0]   io_perf_13_value,
  output [5:0]   io_perf_14_value,
  output [5:0]   io_perf_15_value,
  output [656:0] gatewayIn_packed_49_bore,
  output [324:0] gatewayIn_packed_50_bore,
  output [324:0] gatewayIn_packed_51_bore,
  output [324:0] gatewayIn_packed_52_bore,
  // END GENERATED(core_ports)

  // ---- SbufferData（wrapper 里的 dataModule 实例）接口 ----------------------
  //  本核不持有 data/mask 阵列：写请求发出去，全体 16×4×16B 读出收回来。
  output logic [ENSB_W-1:0]                     dm_wr_valid,
  output logic [ENSB_W-1:0][SB_SIZE-1:0]        dm_wr_wvec,
  output logic [ENSB_W-1:0][VDATA_BYTES-1:0]    dm_wr_mask,
  output logic [ENSB_W-1:0][VLEN-1:0]           dm_wr_data,
  output logic [ENSB_W-1:0][VWOFF_W-1:0]        dm_wr_vwoff,
  output logic [ENSB_W-1:0]                     dm_wr_wline,
  output logic [0:0]                            dm_flush_valid,
  output logic [0:0][SB_SIZE-1:0]               dm_flush_wvec,
  input  logic [SB_SIZE-1:0][CLINE_VWORDS-1:0][VDATA_BYTES-1:0][7:0] dm_data_out,
  input  logic [SB_SIZE-1:0][CLINE_VWORDS-1:0][VDATA_BYTES-1:0]      dm_mask_out
);

  // ===========================================================================
  //  §1 入口聚合：两路 store 端口打成数组，后面一律用 for/genvar 统一处理
  // ===========================================================================
  sbuf_inreq_t in_req [ENSB_W];
  always_comb begin
    in_req[0] = '{ vaddr:io_in_0_bits_vaddr, data:io_in_0_bits_data, mask:io_in_0_bits_mask,
                   addr:io_in_0_bits_addr, wline:io_in_0_bits_wline, vecValid:io_in_0_bits_vecValid };
    in_req[1] = '{ vaddr:io_in_1_bits_vaddr, data:io_in_1_bits_data, mask:io_in_1_bits_mask,
                   addr:io_in_1_bits_addr, wline:io_in_1_bits_wline, vecValid:io_in_1_bits_vecValid };
  end

  // ===========================================================================
  //  §2 entry 存储（meta / state / 两个计数器）与派生掩码
  // ---------------------------------------------------------------------------
  //  golden 顶层是一组独立的 vtag_<i>/ptag_<i> 寄存器（firtool 把 Vec 展平了），
  //  这里用数组表达同一件事；名字保持 ptag/vtag 以便 FM 按名配对。
  // ===========================================================================
  logic [PTAG_W-1:0]       ptag             [SB_SIZE];
  logic [VTAG_W-1:0]       vtag             [SB_SIZE];
  sbuf_state_t             stateVec         [SB_SIZE];
  logic [SB_SIZE-1:0]      waitInflightMask [SB_SIZE];  // 该 entry 在等哪个在途 entry
  logic [EVICT_CNT_W-1:0]  cohCount         [SB_SIZE];
  logic [REPLAY_CNT_W-1:0] missqReplayCount [SB_SIZE];

  logic [SB_SIZE-1:0] activeMask, validMask, invalidMask, inflightMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++) begin
      activeMask[i]   = st_is_active (stateVec[i]);
      validMask[i]    = st_is_valid  (stateVec[i]);
      invalidMask[i]  = st_is_invalid(stateVec[i]);
      inflightMask[i] = stateVec[i].state_inflight;
    end

  // 前向声明（跨节使用）
  logic                sbuffer_out_s0_fire;
  logic [SB_IDX_W-1:0] sbuffer_out_s0_evictionIdx;
  logic [SB_SIZE-1:0]  writeReq_wvec  [ENSB_W];
  logic                writeReq_valid [ENSB_W];
  logic                forward_need_uarch_drain, merge_need_uarch_drain;

  // ===========================================================================
  //  §3 全局 4 态状态机（转移条件在 §8 之前就要用到 need_drain，故先声明）
  // ===========================================================================
  sbuf_gstate_e sbuffer_state;
  wire need_drain = sbuffer_state[1];   // needDrain = state(1)

  // ===========================================================================
  //  §4 PLRU：在「DCache 写候选」里选最旧的一条
  // ---------------------------------------------------------------------------
  //  Scala 是 plru.way(candidateVec.reverse)：候选序反着喂进 ValidPseudoLRU。
  //  这里把 16 个候选按「最左叶=way15」的树叶布局直接接进 4 层归约。
  // ===========================================================================
  logic [14:0]        plru_state;
  logic [SB_SIZE-1:0] candidateVec;
  always_comb
    for (int i = 0; i < SB_SIZE; i++) candidateVec[i] = st_is_dcache_cand(stateVec[i]);

  logic pair_v [8]; logic [3:0] pair_i [8];   // 叶对（下标 1 位有效）
  logic quad_v [4]; logic [3:0] quad_i [4];   // 2 位
  logic oct_v  [2]; logic [3:0] oct_i  [2];   // 3 位
  logic way_valid;  logic [3:0] way_idx;      // 4 位 = 实际 entry 下标
  localparam int PAIR_S [8] = '{11, 10, 8, 7, 4, 3, 1, 0};
  localparam int QUAD_S [4] = '{12, 9, 5, 2};
  always_comb begin
    for (int k = 0; k < 8; k++)
      {pair_v[k], pair_i[k]} = plru_join(candidateVec[15-2*k], 4'h0,
                                         candidateVec[14-2*k], 4'h0, plru_state[PAIR_S[k]], 0);
    for (int k = 0; k < 4; k++)
      {quad_v[k], quad_i[k]} = plru_join(pair_v[2*k],   pair_i[2*k],
                                         pair_v[2*k+1], pair_i[2*k+1], plru_state[QUAD_S[k]], 1);
    {oct_v[0], oct_i[0]} = plru_join(quad_v[0], quad_i[0], quad_v[1], quad_i[1], plru_state[13], 2);
    {oct_v[1], oct_i[1]} = plru_join(quad_v[2], quad_i[2], quad_v[3], quad_i[3], plru_state[6],  2);
    {way_valid, way_idx} = plru_join(oct_v[0],  oct_i[0],  oct_v[1],  oct_i[1],  plru_state[14], 3);
  end
  wire [SB_IDX_W-1:0] replaceAlgoIdx = way_idx;
  wire [SB_IDX_W-1:0] replaceIdx     = replaceAlgoIdx;

  // ===========================================================================
  //  §5 两个超时：coh（攒够久该逐出）与 missqReplay（replay 后的重发延时）
  // ---------------------------------------------------------------------------
  //  ★G1 相对 G0 的真逻辑变化★：coh 超时阈值从固定的 cohCount[20] 位测试，
  //    改成与 CSR 可编程门限做 22 位无符号比较 {1'b0,cohCount} >= timeout。
  // ===========================================================================
  logic [SB_SIZE-1:0] cohTimeOutMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++)
      cohTimeOutMask[i] = ({1'b0, cohCount[i]} >= io_csrCtrl_sbuffer_timeout)
                        & st_is_active(stateVec[i]);
  wire [SB_IDX_W-1:0] cohTimeOutIdx = prio_enc16_deflast(cohTimeOutMask);
  wire                cohHasTimeOut = |cohTimeOutMask;

  logic [SB_SIZE-1:0] missqReplayTimeOutMask;
  always_comb
    for (int i = 0; i < SB_SIZE; i++)
      missqReplayTimeOutMask[i] = missqReplayCount[i][REPLAY_CNT_W-1] & stateVec[i].w_timeout;
  wire [SB_IDX_W-1:0] missqReplayTimeOutIdxGen = prio_enc16(missqReplayTimeOutMask);
  wire                missqReplayHasTimeOutGen = |missqReplayTimeOutMask;

  // HasTimeOut = RegNext(gen) & ~RegNext(out_s0.fire)；Idx = RegEnable(gen, gen)
  logic                missqReplayHasTimeOut_q, out_s0_fire_q;
  logic [SB_IDX_W-1:0] missqReplayTimeOutIdx;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin missqReplayHasTimeOut_q <= 1'b0; out_s0_fire_q <= 1'b0; end
    else begin
      missqReplayHasTimeOut_q <= missqReplayHasTimeOutGen;
      out_s0_fire_q           <= sbuffer_out_s0_fire;
    end
  end
  always_ff @(posedge clock)
    if (missqReplayHasTimeOutGen) missqReplayTimeOutIdx <= missqReplayTimeOutIdxGen;
  wire missqReplayHasTimeOut = missqReplayHasTimeOut_q & ~out_s0_fire_q;

  // ===========================================================================
  //  §6 Enq（in_s0/s1）：同 ptag 就 merge，否则在奇/偶分组里取第一个空位 alloc
  // ===========================================================================
  logic [PTAG_W-1:0] inptag [ENSB_W];
  logic [VTAG_W-1:0] invtag [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      inptag[i] = get_ptag(in_req[i].addr);
      invtag[i] = get_vtag(in_req[i].vaddr);
    end
  // 两路落在同一条 cacheline：第二路复用第一路的落点
  wire sameTag = (inptag[0] == inptag[1]) & io_in_0_valid & io_in_1_valid
               & in_req[0].vecValid & in_req[1].vecValid;

  logic [SB_SIZE-1:0]  mergeMask [ENSB_W];
  logic [SB_IDX_W-1:0] mergeIdx  [ENSB_W];
  logic                canMerge  [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      for (int j = 0; j < SB_SIZE; j++)
        mergeMask[i][j] = (inptag[i] == ptag[j]) & activeMask[j];
      mergeIdx[i] = prio_enc16(mergeMask[i]);
      canMerge[i] = |mergeMask[i];
    end

  // alloc：偶下标一组、奇下标一组，两路各取一组的第一个空位 → 同拍不冲突
  logic [7:0]         evenInvalidMask, oddInvalidMask, evenRawInsertVec, oddRawInsertVec;
  logic [SB_SIZE-1:0] evenInsertVec, oddInsertVec;
  always_comb begin
    for (int k = 0; k < 8; k++) begin
      evenInvalidMask[k] = invalidMask[2*k];
      oddInvalidMask[k]  = invalidMask[2*k+1];
    end
    evenRawInsertVec = first_one_oh8(evenInvalidMask);
    oddRawInsertVec  = first_one_oh8(oddInvalidMask);
    for (int k = 0; k < 8; k++) begin
      evenInsertVec[2*k]   = evenRawInsertVec[k]; evenInsertVec[2*k+1] = 1'b0;
      oddInsertVec[2*k]    = 1'b0;                oddInsertVec[2*k+1]  = oddRawInsertVec[k];
    end
  end
  wire evenCanInsert = |evenInvalidMask;
  wire oddCanInsert  = |oddInvalidMask;

  // enbufferSelReg：第 0 路每收一拍就换一组，让奇/偶两组均衡占用
  logic enbufferSelReg;
  always_ff @(posedge clock or posedge reset)
    if (reset) enbufferSelReg <= 1'b0;
    else if (io_in_0_valid) enbufferSelReg <= ~enbufferSelReg;

  logic [SB_SIZE-1:0] firstInsertVec, secondInsertVec;
  logic               firstCanInsert, secondCanInsert;
  wire drain_block = (sbuffer_state != X_DRAIN_SBUFFER);   // 排空 sbuffer 时不收新 store
  always_comb begin
    firstInsertVec  = enbufferSelReg ? evenInsertVec : oddInsertVec;
    secondInsertVec = sameTag ? firstInsertVec
                    : (~enbufferSelReg ? evenInsertVec : oddInsertVec);
    firstCanInsert  = drain_block & (enbufferSelReg ? evenCanInsert : oddCanInsert);
    secondCanInsert = drain_block & (sameTag ? firstCanInsert
                    : (~enbufferSelReg ? evenCanInsert : oddCanInsert));
  end

  // micro-arch drain：forward / merge 时发现 vtag 与 ptag 结论不一致 → 抽干重做
  logic fwd_drain_q, merge_drain_q, merge_drain_q2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin fwd_drain_q <= 1'b0; merge_drain_q <= 1'b0; merge_drain_q2 <= 1'b0; end
    else begin
      fwd_drain_q    <= forward_need_uarch_drain;
      merge_drain_q  <= merge_need_uarch_drain;
      merge_drain_q2 <= merge_drain_q;
    end
  end
  wire do_uarch_drain = fwd_drain_q | merge_drain_q2;

  assign io_in_0_ready = firstCanInsert;
  assign io_in_1_ready = secondCanInsert & firstCanInsert;

  logic [SB_SIZE-1:0]  insertVec   [ENSB_W];
  logic [SB_IDX_W-1:0] insertIdx   [ENSB_W];
  logic                accessValid [ENSB_W];
  always_comb begin
    insertVec[0] = firstInsertVec;  insertVec[1] = secondInsertVec;
    for (int i = 0; i < ENSB_W; i++) insertIdx[i] = prio_enc16(insertVec[i]);
    accessValid[0] = io_in_0_valid & io_in_0_bits_vecValid & io_in_0_ready;
    accessValid[1] = io_in_1_valid & io_in_1_bits_vecValid & io_in_1_ready;
  end

  // alloc 时同 block 是否已有 entry 在途（要挂 w_sameblock_inflight）
  logic [SB_SIZE-1:0] sameBlockInflight [ENSB_W];
  always_comb
    for (int i = 0; i < ENSB_W; i++)
      for (int j = 0; j < SB_SIZE; j++)
        sameBlockInflight[i][j] = inflightMask[j] & (inptag[i] == ptag[j]);

  // ===========================================================================
  //  §7 写数据请求：merge 打到 mergeVec，alloc 打到 insertVec；数据体在 dataModule
  // ===========================================================================
  always_comb
    for (int i = 0; i < ENSB_W; i++) begin
      writeReq_valid[i] = accessValid[i];
      writeReq_wvec[i]  = canMerge[i] ? mergeMask[i] : insertVec[i];
    end
  always_comb begin
    for (int i = 0; i < ENSB_W; i++) begin
      dm_wr_valid[i] = writeReq_valid[i];
      dm_wr_wvec[i]  = writeReq_wvec[i];
      dm_wr_mask[i]  = in_req[i].mask;
      dm_wr_data[i]  = in_req[i].data;
      dm_wr_vwoff[i] = in_req[i].addr[PADDR_BITS-1:4];  // golden: io_in_i_bits_addr[47:4]
      dm_wr_wline[i] = in_req[i].wline;
    end
  end

  // accessIdx（喂 PLRU touch）：两个 enq 口各 RegNext(merge ? mergeIdx : insertIdx)
  logic                accessIdx0_valid_q, accessIdx1_valid_q;
  logic [SB_IDX_W-1:0] accessIdx0_idx_q,  accessIdx1_idx_q;
  // golden accessIdx_N_valid_REG 在纯时钟块里、无复位 —— 照抄，不许补 reset
  always_ff @(posedge clock) begin
    accessIdx0_valid_q <= accessValid[0]; accessIdx1_valid_q <= accessValid[1];
    if (accessValid[0]) accessIdx0_idx_q <= canMerge[0] ? mergeIdx[0] : insertIdx[0];
    if (accessValid[1]) accessIdx1_idx_q <= canMerge[1] ? mergeIdx[1] : insertIdx[1];
  end

  // ===========================================================================
  //  §3' 逐出触发 / 空满标志 / 状态机转移
  // ===========================================================================
  wire sbuffer_empty = &invalidMask;
  wire sq_empty      = ~(io_in_0_valid | io_in_1_valid);
  wire empty         = sbuffer_empty & sq_empty;
  wire [4:0] ActiveCount = popcnt16(activeMask);
  wire [4:0] ValidCount  = popcnt16(validMask);
  // forceThreshold = force_write ? (7-4)=3 : 7 = {2'h0, ~force_write, 2'h3}
  wire [4:0] forceThreshold = {2'h0, ~io_force_write, 2'h3};
  wire       sbufferFull    = (ValidCount == 5'(SB_SIZE));

  logic do_eviction_q, sbFull_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin do_eviction_q <= 1'b0; sbFull_q <= 1'b0; end
    else begin
      do_eviction_q <= (ActiveCount >= forceThreshold)
                     | (ActiveCount == 5'(SB_SIZE-1))
                     | sbufferFull;
      sbFull_q      <= sbufferFull;          // G1 新增输出 io_sbFull
    end
  end
  wire do_eviction = do_eviction_q;
  assign io_sbFull = sbFull_q;

  logic sbempty_q, flush_empty_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin sbempty_q <= 1'b0; flush_empty_q <= 1'b0; end
    else begin sbempty_q <= empty; flush_empty_q <= empty & io_sqempty; end
  end
  assign io_sbempty     = sbempty_q;
  assign io_flush_empty = flush_empty_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) sbuffer_state <= X_IDLE;
    else unique case (sbuffer_state)
      X_IDLE:          if (io_flush_valid)       sbuffer_state <= X_DRAIN_ALL;
                       else if (do_uarch_drain)  sbuffer_state <= X_DRAIN_SBUFFER;
                       else if (do_eviction)     sbuffer_state <= X_REPLACE;
      X_DRAIN_ALL:     if (empty)                sbuffer_state <= X_IDLE;
      X_DRAIN_SBUFFER: if (io_flush_valid)       sbuffer_state <= X_DRAIN_ALL;
                       else if (sbuffer_empty)   sbuffer_state <= X_IDLE;
      X_REPLACE:       if (io_flush_valid)       sbuffer_state <= X_DRAIN_ALL;
                       else if (do_uarch_drain)  sbuffer_state <= X_DRAIN_SBUFFER;
                       else if (~do_eviction)    sbuffer_state <= X_IDLE;
      default: ;
    endcase
  end

  // ===========================================================================
  //  §8 Deq：out_s0 选 victim，out_s1 组 DCache 整行写请求
  // ---------------------------------------------------------------------------
  //  优先级：missqReplay 超时 > drain（状态机要求排空）> coh 超时 > PLRU 替换
  // ===========================================================================
  wire [SB_IDX_W-1:0] drainIdx     = prio_enc16_deflast(activeMask);
  wire                need_replace = do_eviction | (sbuffer_state == X_REPLACE);
  always_comb begin
    if      (missqReplayHasTimeOut) sbuffer_out_s0_evictionIdx = missqReplayTimeOutIdx;
    else if (need_drain)            sbuffer_out_s0_evictionIdx = drainIdx;
    else if (cohHasTimeOut)         sbuffer_out_s0_evictionIdx = cohTimeOutIdx;
    else                            sbuffer_out_s0_evictionIdx = replaceIdx;
  end
  wire sbuffer_out_s0_valid = missqReplayHasTimeOut
    | (st_is_dcache_cand(stateVec[sbuffer_out_s0_evictionIdx])
       & (need_drain | cohHasTimeOut | need_replace));

  logic                sbuffer_out_s1_valid;
  logic [SB_IDX_W-1:0] sbuffer_out_s1_evictionIdx;
  logic [PTAG_W-1:0]   sbuffer_out_s1_evictionPTag;
  logic [VTAG_W-1:0]   sbuffer_out_s1_evictionVTag;

  // 读写冒险：被逐出的 entry 这拍正被 writeReq 写 → 阻塞一拍再发 DCache
  logic shouldWaitWriteFinish_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) shouldWaitWriteFinish_q <= 1'b0;
    else shouldWaitWriteFinish_q <=
      ((|(writeReq_wvec[1] & (16'h1 << sbuffer_out_s0_evictionIdx))) & writeReq_valid[1]) |
      ((|(writeReq_wvec[0] & (16'h1 << sbuffer_out_s0_evictionIdx))) & writeReq_valid[0]);
  end
  wire blockDcacheWrite = shouldWaitWriteFinish_q;

  wire sbuffer_out_s1_ready = (io_dcache_req_ready & ~blockDcacheWrite) | ~sbuffer_out_s1_valid;
  wire sbuffer_out_s0_cango = sbuffer_out_s1_ready;
  assign sbuffer_out_s0_fire = sbuffer_out_s0_valid & sbuffer_out_s0_cango;
  wire sbuffer_out_s1_fire   = io_dcache_req_valid & io_dcache_req_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) sbuffer_out_s1_valid <= 1'b0;
    else begin
      if (sbuffer_out_s1_fire) sbuffer_out_s1_valid <= 1'b0;
      if (sbuffer_out_s0_cango) sbuffer_out_s1_valid <= sbuffer_out_s0_valid;
    end
  end
  always_ff @(posedge clock)
    if (sbuffer_out_s0_fire) begin
      sbuffer_out_s1_evictionIdx  <= sbuffer_out_s0_evictionIdx;
      sbuffer_out_s1_evictionPTag <= ptag[sbuffer_out_s0_evictionIdx];
      sbuffer_out_s1_evictionVTag <= vtag[sbuffer_out_s0_evictionIdx];
    end

  // 整行 data/mask 直接来自 dataModule 的全体读出，按 s1 的 victim 下标选行
  logic [CLINE_BITS-1:0]  dcache_line_data;
  logic [CLINE_BYTES-1:0] dcache_line_mask;
  always_comb
    for (int w = 0; w < CLINE_VWORDS; w++) begin
      dcache_line_data[w*VLEN +: VLEN]               = dm_data_out[sbuffer_out_s1_evictionIdx][w];
      dcache_line_mask[w*VDATA_BYTES +: VDATA_BYTES] = dm_mask_out[sbuffer_out_s1_evictionIdx][w];
    end

  assign io_dcache_req_valid      = sbuffer_out_s1_valid & ~blockDcacheWrite;
  assign io_dcache_req_bits_addr  = addr_from_ptag(sbuffer_out_s1_evictionPTag);
  assign io_dcache_req_bits_vaddr = {sbuffer_out_s1_evictionVTag, {OFFSET_W{1'b0}}};
  assign io_dcache_req_bits_data  = dcache_line_data;
  assign io_dcache_req_bits_mask  = dcache_line_mask;
  assign io_dcache_req_bits_id    = {2'h0, sbuffer_out_s1_evictionIdx};

  // PLRU 的第三个 touch：替换算法这拍被真正采纳（或该槽本来就空）
  wire accessIdx2_valid = invalidMask[replaceIdx]
    | (need_replace & ~need_drain & ~cohHasTimeOut & ~missqReplayHasTimeOut
       & sbuffer_out_s0_cango & activeMask[replaceIdx]);

  // ===========================================================================
  //  §9 Resp：hit_resp 释放 entry / replay_resp 挂超时重发；entry 时序统一更新
  // ===========================================================================
  wire                hit_resp_fire    = io_dcache_main_pipe_hit_resp_valid;
  wire [SB_IDX_W-1:0] hit_resp_id      = io_dcache_main_pipe_hit_resp_bits_id[SB_IDX_W-1:0];
  wire                replay_resp_fire = io_dcache_replay_resp_valid;
  wire [SB_IDX_W-1:0] replay_resp_id   = io_dcache_replay_resp_bits_id[SB_IDX_W-1:0];

  // 解除「同 block 在途」等待要晚一拍判定（等被等的那条真的写完）
  logic                hit_resp_fire_q;
  logic [SB_IDX_W-1:0] hit_resp_id_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) hit_resp_fire_q <= 1'b0;
    else       hit_resp_fire_q <= hit_resp_fire;
  end
  always_ff @(posedge clock)
    if (hit_resp_fire) hit_resp_id_q <= hit_resp_id;

  // mask 清除请求：hit_resp 命中的那一行整行掩码清 0（wvec = UIntToOH(resp.id)）
  // golden wvec 取自 (64'h1 << 全 6 位 id) 的低 16 位：id >= 16 时全 0，
  // 所以比较必须用**全宽 id**，不能只比低 4 位。
  always_comb begin
    dm_flush_valid[0] = hit_resp_fire;
    for (int i = 0; i < SB_SIZE; i++)
      dm_flush_wvec[0][i] = (io_dcache_main_pipe_hit_resp_bits_id == 6'(i));
  end

  genvar ge;
  generate
    for (ge = 0; ge < SB_SIZE; ge++) begin : g_entry
      wire sel_merge0 = accessValid[0] & canMerge[0] & mergeMask[0][ge];
      wire sel_merge1 = accessValid[1] & canMerge[1] & mergeMask[1][ge];
      wire sel_ins0   = accessValid[0] & ~canMerge[0] & insertVec[0][ge];
      wire sel_ins1   = accessValid[1] & ~canMerge[1] & insertVec[1][ge];
      wire sel_evict  = sbuffer_out_s0_fire & (sbuffer_out_s0_evictionIdx == ge[SB_IDX_W-1:0]);
      wire sel_hit    = hit_resp_fire    & (hit_resp_id    == ge[SB_IDX_W-1:0]);
      wire sel_replay = replay_resp_fire & (replay_resp_id == ge[SB_IDX_W-1:0]);

      wire [SB_SIZE-1:0] sb0 = sameBlockInflight[0];
      wire [SB_SIZE-1:0] sb1 = sameBlockInflight[1];

      // waitInflightMask / ptag / vtag：golden 在纯时钟块里、无复位。
      // Chisel 的 foreach 覆盖链是 port1 覆盖 port0（后写胜）：sameTag 时两口可能
      // 同拍命中同一 entry，ptag 两口相等但 vtag 不一定，优先级必须取 port1。
      always_ff @(posedge clock) begin
        if      (sel_ins1 & (|sb1)) waitInflightMask[ge] <= sb1;
        else if (sel_ins0 & (|sb0)) waitInflightMask[ge] <= sb0;
        if      (sel_ins1) begin ptag[ge] <= inptag[1]; vtag[ge] <= invtag[1]; end
        else if (sel_ins0) begin ptag[ge] <= inptag[0]; vtag[ge] <= invtag[0]; end
      end

      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          stateVec[ge]         <= '0;
          cohCount[ge]         <= '0;
          missqReplayCount[ge] <= '0;
        end else begin
          // (1) alloc：占新 entry（merge 不改 state，只清 cohCount，见下）
          if (sel_ins1) begin
            stateVec[ge].state_valid          <= 1'b1;
            stateVec[ge].w_sameblock_inflight <= |sb1;
          end else if (sel_ins0) begin
            stateVec[ge].state_valid          <= 1'b1;
            stateVec[ge].w_sameblock_inflight <= |sb0;
          end

          // (2) 发出 DCache 写：置 inflight、清 w_timeout
          if (sel_evict) begin
            stateVec[ge].state_inflight <= 1'b1;
            stateVec[ge].w_timeout      <= 1'b0;
          end

          // (3) hit_resp：释放 entry
          if (sel_hit) begin
            stateVec[ge].state_inflight <= 1'b0;
            stateVec[ge].state_valid    <= 1'b0;
          end
          // 解除同 block 等待：golden 里这条是每拍无条件求值的独立 mux，
          // 与 sel_hit 不互斥，且会覆盖同拍 alloc 写进去的值 —— 故单独一个 if。
          if (stateVec[ge].w_sameblock_inflight & stateVec[ge].state_valid
              & hit_resp_fire_q
              & (waitInflightMask[ge] == (16'h1 << hit_resp_id_q)))
            stateVec[ge].w_sameblock_inflight <= 1'b0;

          // (4) replay_resp：挂 w_timeout 等重发
          if (sel_replay) stateVec[ge].w_timeout <= 1'b1;

          // cohCount：★「active 且未超时 → +1」优先于「alloc/merge → 清 0」★
          //   （Chisel 里 +1 的 when 写在后面，last-wins）。对一个已 active 的 entry，
          //   即便这拍正被 merge 也是 +1；只有它这拍非 active 时 alloc 才清 0。
          if (st_is_active(stateVec[ge]) & ~cohTimeOutMask[ge])
            cohCount[ge] <= cohCount[ge] + 1'b1;
          else if (sel_merge0 | sel_merge1 | sel_ins0 | sel_ins1)
            cohCount[ge] <= '0;

          // missqReplayCount：同样 +1 优先于 replay_resp 清 0
          if (stateVec[ge].w_timeout & stateVec[ge].state_inflight
              & ~missqReplayCount[ge][REPLAY_CNT_W-1])
            missqReplayCount[ge] <= missqReplayCount[ge] + 1'b1;
          else if (sel_replay)
            missqReplayCount[ge] <= '0;
        end
      end
    end
  endgenerate

  // merge 时 vtag 与已存 vtag 不一致 → micro-arch drain
  always_comb begin
    merge_need_uarch_drain = 1'b0;
    for (int i = 0; i < ENSB_W; i++)
      for (int j = 0; j < SB_SIZE; j++)
        if (accessValid[i] & canMerge[i] & mergeMask[i][j] & (invtag[i] != vtag[j]))
          merge_need_uarch_drain = 1'b1;
  end

  // ===========================================================================
  //  §10 Forward：把还没写回 DCache 的 store 字节前递给 load
  // ---------------------------------------------------------------------------
  //  f0：用 forward.vaddr 做 vtag CAM，分「active 候选」与「inflight 候选」两类；
  //  f1：打一拍后用 paddr 复核 ptag。active 优先于 inflight；vtag 命中而 ptag 不命中
  //      （或反之）且该 entry active/inflight → matchInvalid + micro-arch drain。
  //  寄存器边界逐个对齐 golden（哪些有使能、哪些有复位，见块内注释）。
  // ===========================================================================
  logic [VADDR_BITS-1:0] fwd_vaddr [LD_WIDTH];
  logic [PADDR_BITS-1:0] fwd_paddr [LD_WIDTH];
  logic                  fwd_valid [LD_WIDTH];
  always_comb begin
    fwd_vaddr[0]=io_forward_0_vaddr; fwd_paddr[0]=io_forward_0_paddr; fwd_valid[0]=io_forward_0_valid;
    fwd_vaddr[1]=io_forward_1_vaddr; fwd_paddr[1]=io_forward_1_paddr; fwd_valid[1]=io_forward_1_valid;
    fwd_vaddr[2]=io_forward_2_vaddr; fwd_paddr[2]=io_forward_2_paddr; fwd_valid[2]=io_forward_2_valid;
  end

  logic [VDATA_BYTES-1:0]      fwd_o_mask [LD_WIDTH];
  logic [VDATA_BYTES-1:0][7:0] fwd_o_data [LD_WIDTH];
  logic [LD_WIDTH-1:0]         fwd_mismatch;

  genvar gf;
  generate
    for (gf = 0; gf < LD_WIDTH; gf++) begin : g_fwd
      logic [SB_SIZE-1:0] vtag_match, ptag_match_q;
      always_comb
        for (int w = 0; w < SB_SIZE; w++)
          vtag_match[w] = (vtag[w] == get_vtag(fwd_vaddr[gf]));

      // 使能 = fwd_valid、无复位（↔ golden ptag_matches_r 对、valid/inflight_tag_match_reg）
      logic [PTAG_W-1:0]  ptag_q [SB_SIZE];
      logic [PTAG_W-1:0]  fwd_ptag_q;
      logic [SB_SIZE-1:0] valid_tag_match_q, inflight_tag_match_q;
      // 无使能、异步复位 0（↔ golden tag_mismatch_REG / tag_mismatch_last_REG_*）
      logic               fwd_valid_q;
      logic [SB_SIZE-1:0] vtag_match_q, act_or_infl_q;

      always_ff @(posedge clock) begin
        if (fwd_valid[gf]) begin
          for (int w = 0; w < SB_SIZE; w++) ptag_q[w] <= ptag[w];
          fwd_ptag_q <= get_ptag(fwd_paddr[gf]);
          // ★golden 存的是 AND **之后**的结果★（与 vtag_match_q 是不同的寄存器组），
          //   不能只存分量再在 f1 级 AND —— 那会让两侧落进不同的 FM 类别。
          for (int w = 0; w < SB_SIZE; w++) begin
            valid_tag_match_q[w]    <= vtag_match[w] & activeMask[w];
            inflight_tag_match_q[w] <= vtag_match[w] & stateVec[w].state_inflight;
          end
        end
      end
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          fwd_valid_q   <= 1'b0;
          vtag_match_q  <= '0;
          act_or_infl_q <= '0;
        end else begin
          fwd_valid_q  <= fwd_valid[gf];
          vtag_match_q <= vtag_match;
          for (int w = 0; w < SB_SIZE; w++)
            act_or_infl_q[w] <= activeMask[w] | stateVec[w].state_inflight;
        end
      end
      always_comb
        for (int w = 0; w < SB_SIZE; w++) ptag_match_q[w] = (ptag_q[w] == fwd_ptag_q);

      logic mism;
      always_comb begin
        mism = 1'b0;
        for (int w = 0; w < SB_SIZE; w++)
          if (fwd_valid_q & (vtag_match_q[w] != ptag_match_q[w]) & act_or_infl_q[w])
            mism = 1'b1;
      end
      assign fwd_mismatch[gf] = mism;

      // 候选 mask/data = RegEnable(dataModule 读出的那一行对应 VWord, fwd_valid)
      logic [VDATA_BYTES-1:0]      mask_cand_q [SB_SIZE];
      logic [VDATA_BYTES-1:0][7:0] data_cand_q [SB_SIZE];
      always_ff @(posedge clock)
        if (fwd_valid[gf])
          for (int w = 0; w < SB_SIZE; w++) begin
            mask_cand_q[w] <= dm_mask_out[w][get_vword_off(fwd_paddr[gf])];
            data_cand_q[w] <= dm_data_out[w][get_vword_off(fwd_paddr[gf])];
          end

      // Mux1H：命中唯一，OR 归约即可
      logic [VDATA_BYTES-1:0]      selValidMask, selInflMask;
      logic [VDATA_BYTES-1:0][7:0] selValidData, selInflData;
      always_comb begin
        selValidMask='0; selInflMask='0; selValidData='0; selInflData='0;
        for (int w = 0; w < SB_SIZE; w++) begin
          if (valid_tag_match_q[w])    begin selValidMask |= mask_cand_q[w]; selValidData |= data_cand_q[w]; end
          if (inflight_tag_match_q[w]) begin selInflMask  |= mask_cand_q[w]; selInflData  |= data_cand_q[w]; end
        end
      end

      // 逐字节：mask = inflight | active；data 按「active 是否命中该字节」二选一。
      // ★注意 golden 的 forwardData 不被整体 mask 门控为 0★，照抄。
      always_comb
        for (int j = 0; j < VDATA_BYTES; j++) begin
          fwd_o_mask[gf][j] = selInflMask[j] | selValidMask[j];
          fwd_o_data[gf][j] = selValidMask[j] ? selValidData[j] : selInflData[j];
        end
    end
  endgenerate

  always_comb forward_need_uarch_drain = |fwd_mismatch;

  // BEGIN GENERATED(fwd_flat)
  assign io_forward_0_forwardMask_0  = fwd_o_mask[0][0];
  assign io_forward_0_forwardMask_1  = fwd_o_mask[0][1];
  assign io_forward_0_forwardMask_2  = fwd_o_mask[0][2];
  assign io_forward_0_forwardMask_3  = fwd_o_mask[0][3];
  assign io_forward_0_forwardMask_4  = fwd_o_mask[0][4];
  assign io_forward_0_forwardMask_5  = fwd_o_mask[0][5];
  assign io_forward_0_forwardMask_6  = fwd_o_mask[0][6];
  assign io_forward_0_forwardMask_7  = fwd_o_mask[0][7];
  assign io_forward_0_forwardMask_8  = fwd_o_mask[0][8];
  assign io_forward_0_forwardMask_9  = fwd_o_mask[0][9];
  assign io_forward_0_forwardMask_10 = fwd_o_mask[0][10];
  assign io_forward_0_forwardMask_11 = fwd_o_mask[0][11];
  assign io_forward_0_forwardMask_12 = fwd_o_mask[0][12];
  assign io_forward_0_forwardMask_13 = fwd_o_mask[0][13];
  assign io_forward_0_forwardMask_14 = fwd_o_mask[0][14];
  assign io_forward_0_forwardMask_15 = fwd_o_mask[0][15];
  assign io_forward_0_forwardData_0  = fwd_o_data[0][0];
  assign io_forward_0_forwardData_1  = fwd_o_data[0][1];
  assign io_forward_0_forwardData_2  = fwd_o_data[0][2];
  assign io_forward_0_forwardData_3  = fwd_o_data[0][3];
  assign io_forward_0_forwardData_4  = fwd_o_data[0][4];
  assign io_forward_0_forwardData_5  = fwd_o_data[0][5];
  assign io_forward_0_forwardData_6  = fwd_o_data[0][6];
  assign io_forward_0_forwardData_7  = fwd_o_data[0][7];
  assign io_forward_0_forwardData_8  = fwd_o_data[0][8];
  assign io_forward_0_forwardData_9  = fwd_o_data[0][9];
  assign io_forward_0_forwardData_10 = fwd_o_data[0][10];
  assign io_forward_0_forwardData_11 = fwd_o_data[0][11];
  assign io_forward_0_forwardData_12 = fwd_o_data[0][12];
  assign io_forward_0_forwardData_13 = fwd_o_data[0][13];
  assign io_forward_0_forwardData_14 = fwd_o_data[0][14];
  assign io_forward_0_forwardData_15 = fwd_o_data[0][15];
  assign io_forward_0_matchInvalid    = fwd_mismatch[0];
  assign io_forward_1_forwardMask_0  = fwd_o_mask[1][0];
  assign io_forward_1_forwardMask_1  = fwd_o_mask[1][1];
  assign io_forward_1_forwardMask_2  = fwd_o_mask[1][2];
  assign io_forward_1_forwardMask_3  = fwd_o_mask[1][3];
  assign io_forward_1_forwardMask_4  = fwd_o_mask[1][4];
  assign io_forward_1_forwardMask_5  = fwd_o_mask[1][5];
  assign io_forward_1_forwardMask_6  = fwd_o_mask[1][6];
  assign io_forward_1_forwardMask_7  = fwd_o_mask[1][7];
  assign io_forward_1_forwardMask_8  = fwd_o_mask[1][8];
  assign io_forward_1_forwardMask_9  = fwd_o_mask[1][9];
  assign io_forward_1_forwardMask_10 = fwd_o_mask[1][10];
  assign io_forward_1_forwardMask_11 = fwd_o_mask[1][11];
  assign io_forward_1_forwardMask_12 = fwd_o_mask[1][12];
  assign io_forward_1_forwardMask_13 = fwd_o_mask[1][13];
  assign io_forward_1_forwardMask_14 = fwd_o_mask[1][14];
  assign io_forward_1_forwardMask_15 = fwd_o_mask[1][15];
  assign io_forward_1_forwardData_0  = fwd_o_data[1][0];
  assign io_forward_1_forwardData_1  = fwd_o_data[1][1];
  assign io_forward_1_forwardData_2  = fwd_o_data[1][2];
  assign io_forward_1_forwardData_3  = fwd_o_data[1][3];
  assign io_forward_1_forwardData_4  = fwd_o_data[1][4];
  assign io_forward_1_forwardData_5  = fwd_o_data[1][5];
  assign io_forward_1_forwardData_6  = fwd_o_data[1][6];
  assign io_forward_1_forwardData_7  = fwd_o_data[1][7];
  assign io_forward_1_forwardData_8  = fwd_o_data[1][8];
  assign io_forward_1_forwardData_9  = fwd_o_data[1][9];
  assign io_forward_1_forwardData_10 = fwd_o_data[1][10];
  assign io_forward_1_forwardData_11 = fwd_o_data[1][11];
  assign io_forward_1_forwardData_12 = fwd_o_data[1][12];
  assign io_forward_1_forwardData_13 = fwd_o_data[1][13];
  assign io_forward_1_forwardData_14 = fwd_o_data[1][14];
  assign io_forward_1_forwardData_15 = fwd_o_data[1][15];
  assign io_forward_1_matchInvalid    = fwd_mismatch[1];
  assign io_forward_2_forwardMask_0  = fwd_o_mask[2][0];
  assign io_forward_2_forwardMask_1  = fwd_o_mask[2][1];
  assign io_forward_2_forwardMask_2  = fwd_o_mask[2][2];
  assign io_forward_2_forwardMask_3  = fwd_o_mask[2][3];
  assign io_forward_2_forwardMask_4  = fwd_o_mask[2][4];
  assign io_forward_2_forwardMask_5  = fwd_o_mask[2][5];
  assign io_forward_2_forwardMask_6  = fwd_o_mask[2][6];
  assign io_forward_2_forwardMask_7  = fwd_o_mask[2][7];
  assign io_forward_2_forwardMask_8  = fwd_o_mask[2][8];
  assign io_forward_2_forwardMask_9  = fwd_o_mask[2][9];
  assign io_forward_2_forwardMask_10 = fwd_o_mask[2][10];
  assign io_forward_2_forwardMask_11 = fwd_o_mask[2][11];
  assign io_forward_2_forwardMask_12 = fwd_o_mask[2][12];
  assign io_forward_2_forwardMask_13 = fwd_o_mask[2][13];
  assign io_forward_2_forwardMask_14 = fwd_o_mask[2][14];
  assign io_forward_2_forwardMask_15 = fwd_o_mask[2][15];
  assign io_forward_2_forwardData_0  = fwd_o_data[2][0];
  assign io_forward_2_forwardData_1  = fwd_o_data[2][1];
  assign io_forward_2_forwardData_2  = fwd_o_data[2][2];
  assign io_forward_2_forwardData_3  = fwd_o_data[2][3];
  assign io_forward_2_forwardData_4  = fwd_o_data[2][4];
  assign io_forward_2_forwardData_5  = fwd_o_data[2][5];
  assign io_forward_2_forwardData_6  = fwd_o_data[2][6];
  assign io_forward_2_forwardData_7  = fwd_o_data[2][7];
  assign io_forward_2_forwardData_8  = fwd_o_data[2][8];
  assign io_forward_2_forwardData_9  = fwd_o_data[2][9];
  assign io_forward_2_forwardData_10 = fwd_o_data[2][10];
  assign io_forward_2_forwardData_11 = fwd_o_data[2][11];
  assign io_forward_2_forwardData_12 = fwd_o_data[2][12];
  assign io_forward_2_forwardData_13 = fwd_o_data[2][13];
  assign io_forward_2_forwardData_14 = fwd_o_data[2][14];
  assign io_forward_2_forwardData_15 = fwd_o_data[2][15];
  assign io_forward_2_matchInvalid    = fwd_mismatch[2];
  // END GENERATED(fwd_flat)

  // ===========================================================================
  //  §11 PLRU touch：三个 touch 口在同一拍**依次叠加**（不是三选一）
  // ---------------------------------------------------------------------------
  //  ValidPseudoLRU.access(Seq(t0,t1,t2)) 的语义是后一个基于前一个的结果再更新。
  //  中间累积量必须放在 always_comb（放 always_ff 里当临时量会被 FM 推成伪寄存器）。
  // ===========================================================================
  logic [14:0] plru_next;
  always_comb begin
    logic [14:0] s;
    s = plru_state;
    if (accessIdx0_valid_q) s = plru_touch(s, accessIdx0_idx_q);
    if (accessIdx1_valid_q) s = plru_touch(s, accessIdx1_idx_q);
    if (accessIdx2_valid)   s = plru_touch(s, replaceAlgoIdx);
    plru_next = s;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) plru_state <= '0;
    else if (accessIdx0_valid_q | accessIdx1_valid_q | accessIdx2_valid)
      plru_state <= plru_next;
  end

  // ===========================================================================
  //  §12 perf 事件（16 路，各打两拍出口）。非功能关键，只与 golden 对齐。
  // ===========================================================================
  wire [4:0]  validEntryCnt_c = popcnt16(~invalidMask);
  logic [4:0] perf_valid_entry_count;
  always_ff @(posedge clock) perf_valid_entry_count <= validEntryCnt_c;

  wire f0 = io_in_0_valid & io_in_0_ready;
  wire f1 = io_in_1_valid & io_in_1_ready;
  wire [1:0] pe0  = {1'b0, io_in_0_valid} + {1'b0, io_in_1_valid};
  wire [1:0] pe1  = {1'b0, f0} + {1'b0, f1};
  wire [1:0] pe2  = {1'b0, f0 &  canMerge[0]} + {1'b0, f1 &  canMerge[1]};
  wire [1:0] pe3  = {1'b0, f0 & ~canMerge[0]} + {1'b0, f1 & ~canMerge[1]};
  wire pe4  = io_dcache_req_valid;
  wire pe5  = io_dcache_req_ready & io_dcache_req_valid;
  wire pe6  = ~(|sbuffer_state);
  wire pe7  = &sbuffer_state;
  wire pe8  = (sbuffer_state == X_REPLACE);
  wire pe9  = io_dcache_main_pipe_hit_resp_valid;
  wire pe10 = io_dcache_replay_resp_valid;
  wire pe11 = cohHasTimeOut;
  wire pe12 = perf_valid_entry_count < 5'h4;
  wire pe13 = (perf_valid_entry_count > 5'h4) & (perf_valid_entry_count < 5'h9);
  wire pe14 = (perf_valid_entry_count > 5'h8) & (perf_valid_entry_count < 5'hD);
  wire pe15 = perf_valid_entry_count > 5'hC;

  logic [1:0] p0a,p0b,p1a,p1b,p2a,p2b,p3a,p3b;
  logic p4a,p4b,p5a,p5b,p6a,p6b,p7a,p7b,p8a,p8b,p9a,p9b;
  logic p10a,p10b,p11a,p11b,p12a,p12b,p13a,p13b,p14a,p14b,p15a,p15b;
  always_ff @(posedge clock) begin
    p0a<=pe0;   p0b<=p0a;   p1a<=pe1;   p1b<=p1a;
    p2a<=pe2;   p2b<=p2a;   p3a<=pe3;   p3b<=p3a;
    p4a<=pe4;   p4b<=p4a;   p5a<=pe5;   p5b<=p5a;
    p6a<=pe6;   p6b<=p6a;   p7a<=pe7;   p7b<=p7a;
    p8a<=pe8;   p8b<=p8a;   p9a<=pe9;   p9b<=p9a;
    p10a<=pe10; p10b<=p10a; p11a<=pe11; p11b<=p11a;
    p12a<=pe12; p12b<=p12a; p13a<=pe13; p13b<=p13a;
    p14a<=pe14; p14b<=p14a; p15a<=pe15; p15b<=p15a;
  end
  assign io_perf_0_value ={4'h0,p0b};  assign io_perf_1_value ={4'h0,p1b};
  assign io_perf_2_value ={4'h0,p2b};  assign io_perf_3_value ={4'h0,p3b};
  assign io_perf_4_value ={5'h0,p4b};  assign io_perf_5_value ={5'h0,p5b};
  assign io_perf_6_value ={5'h0,p6b};  assign io_perf_7_value ={5'h0,p7b};
  assign io_perf_8_value ={5'h0,p8b};  assign io_perf_9_value ={5'h0,p9b};
  assign io_perf_10_value={5'h0,p10b}; assign io_perf_11_value={5'h0,p11b};
  assign io_perf_12_value={5'h0,p12b}; assign io_perf_13_value={5'h0,p13b};
  assign io_perf_14_value={5'h0,p14b}; assign io_perf_15_value={5'h0,p15b};

  // ===========================================================================
  //  §13 difftest gateway（G1 新增，G0 没有这条通路）
  // ---------------------------------------------------------------------------
  //  四根打包总线被 XSTop 里的 difftest gateway「bore」走，内容是纯组合的观测量：
  //    49 = sbuffer 写回事件（整行 64B 数据 + 64b 掩码）
  //    50/51 = 两路 PMA store 事件      52 = 一路 NC(non-cacheable) store 事件
  //  这些量不参与任何功能通路，只对外吐出；但它们是真端口，必须逐位与 golden 一致。
  // ===========================================================================
  wire [7:0] dt_coreid = {2'h0, io_hartId};

  // ---- 49：sbuffer 整行写回（hit_resp 那一拍的 entry 内容）------------------
  wire [SB_IDX_W-1:0]   dt_sb_idx  = io_dcache_main_pipe_hit_resp_bits_id[SB_IDX_W-1:0];
  wire [63:0]           dt_sb_addr = {16'h0, ptag[dt_sb_idx], 6'h0};
  logic [CLINE_BYTES-1:0][7:0] dt_sb_data;
  logic [CLINE_BYTES-1:0]      dt_sb_mask;
  always_comb
    for (int w = 0; w < CLINE_VWORDS; w++)
      for (int b = 0; b < VDATA_BYTES; b++) begin
        dt_sb_data[w*VDATA_BYTES + b] = dm_data_out[dt_sb_idx][w][b];
        dt_sb_mask[w*VDATA_BYTES + b] = dm_mask_out[dt_sb_idx][w][b];
      end
  assign gatewayIn_packed_49_bore =
    {io_dcache_main_pipe_hit_resp_valid, dt_sb_addr, dt_sb_data, dt_sb_mask, dt_coreid, 8'h0};

  // ---- 50/51：两路 PMA store 事件 ------------------------------------------
  //  vecNeedSplit：向量 store 是否要被拆开对账。fuType[32]/[34] = 两类向量访存单元；
  //  fuOpType 低 7 位 == 0 是普通 unit-stride，5'hB/5'h8 分别是 vsm（按位）/vsr（整寄存器）。
  //  这三种里除 vsm 外，nf(段数)非 0 就不拆。判据整段照抄 golden。
  function automatic logic is_vec_store(input logic [34:0] ft);
    return ft[32] | ft[34];
  endfunction
  function automatic logic vec_ls_valid(input logic [8:0] ot);
    return ot[8] ^ ot[7];
  endfunction

  logic [BORE_ST_W-1:0] bore_store [ENSB_W];
  generate
    for (genvar gs = 0; gs < ENSB_W; gs++) begin : g_dt_store
      logic [34:0] ft;  logic [8:0] ot;  logic [2:0] nf;  logic [1:0] veew;
      logic [7:0]  robv; logic [5:0] off;
      logic        valid; logic [127:0] data; logic [15:0] mask; logic [47:0] addr;
      logic        wline, vecValid;
      logic [49:0] pc;
      if (gs == 0) begin : g_p0
        assign ft=io_diffStore_diffInfo_0_uop_fuType;  assign ot=io_diffStore_diffInfo_0_uop_fuOpType;
        assign nf=io_diffStore_diffInfo_0_uop_vpu_nf;  assign veew=io_diffStore_diffInfo_0_uop_vpu_veew;
        assign robv=io_diffStore_diffInfo_0_uop_robIdx_value; assign off=io_diffStore_diffInfo_0_offset;
        assign pc=io_diffStore_diffInfo_0_uop_pc;
        assign valid=io_diffStore_pmaStore_0_valid;    assign data=io_diffStore_pmaStore_0_bits_data;
        assign mask=io_diffStore_pmaStore_0_bits_mask; assign addr=io_diffStore_pmaStore_0_bits_addr;
        assign wline=io_diffStore_pmaStore_0_bits_wline; assign vecValid=io_diffStore_pmaStore_0_bits_vecValid;
      end else begin : g_p1
        assign ft=io_diffStore_diffInfo_1_uop_fuType;  assign ot=io_diffStore_diffInfo_1_uop_fuOpType;
        assign nf=io_diffStore_diffInfo_1_uop_vpu_nf;  assign veew=io_diffStore_diffInfo_1_uop_vpu_veew;
        assign robv=io_diffStore_diffInfo_1_uop_robIdx_value; assign off=io_diffStore_diffInfo_1_offset;
        assign pc=io_diffStore_diffInfo_1_uop_pc;
        assign valid=io_diffStore_pmaStore_1_valid;    assign data=io_diffStore_pmaStore_1_bits_data;
        assign mask=io_diffStore_pmaStore_1_bits_mask; assign addr=io_diffStore_pmaStore_1_bits_addr;
        assign wline=io_diffStore_pmaStore_1_bits_wline; assign vecValid=io_diffStore_pmaStore_1_bits_vecValid;
      end
      wire isVsm = is_vec_store(ft) & ~(|ot[6:5]) & (ot[4:0] == 5'hB) & vec_ls_valid(ot);
      wire isVsr = is_vec_store(ft) & ~(|ot[6:5]) & (ot[4:0] == 5'h8) & vec_ls_valid(ot);
      wire needSplit =
        ((is_vec_store(ft) & (ot[6:0] == 7'h0) & vec_ls_valid(ot)) | isVsm | isVsr)
        & ~((|(isVsr ? 3'h0 : nf)) & ~isVsm);
      assign bore_store[gs] =
        {valid & (|mask) & vecValid,            // valid
         {16'h0, addr[47:4], 4'h0},             // addr（16B 对齐）
         data[63:0],                            // data
         data[127:64],                          // highData
         mask,                                  // mask
         wline,                                 // wLine
         needSplit,                             // vecNeedSplit
         8'h1 << veew,                          // eew
         {10'h0, off},                          // offset
         {14'h0, pc},                           // pc
         {2'h0, robv},                          // robidx
         dt_coreid,                             // coreid
         8'(gs)};                               // index
    end
  endgenerate
  assign gatewayIn_packed_50_bore = bore_store[0];
  assign gatewayIn_packed_51_bore = bore_store[1];

  // ---- 52：NC store 事件（wLine/vecNeedSplit/eew/offset/highData 恒 0）------
  wire [63:0] nc_data =
    io_diffStore_ncStore_bits_data
    & {{8{io_diffStore_ncStore_bits_mask[7]}}, {8{io_diffStore_ncStore_bits_mask[6]}},
       {8{io_diffStore_ncStore_bits_mask[5]}}, {8{io_diffStore_ncStore_bits_mask[4]}},
       {8{io_diffStore_ncStore_bits_mask[3]}}, {8{io_diffStore_ncStore_bits_mask[2]}},
       {8{io_diffStore_ncStore_bits_mask[1]}}, {8{io_diffStore_ncStore_bits_mask[0]}}};
  assign gatewayIn_packed_52_bore =
    {io_diffStore_ncStore_valid & io_diffStore_ncStore_bits_memBackTypeMM,
     {16'h0, io_diffStore_ncStore_bits_addr[47:3], 3'h0},
     nc_data,
     64'h0,                                     // highData
     {8'h0, io_diffStore_ncStore_bits_mask},    // mask
     1'h0,                                      // wLine
     1'h0,                                      // vecNeedSplit
     8'h0,                                      // eew
     16'h0,                                     // offset
     {14'h0, io_diffStore_diffInfo_0_uop_pc},   // pc（golden 复用 diffInfo_0 的 pc）
     {2'h0, io_diffStore_diffInfo_0_uop_robIdx_value},
     dt_coreid,
     8'h2};                                     // index

endmodule

// =============================================================================
//  Sbuffer —— golden 同名 wrapper
// -----------------------------------------------------------------------------
//  端口与 golden Sbuffer 逐位同名同序；内部例化：
//    u_core      可读核（本文件上方）
//    dataModule  SbufferData —— 独立签核目标；FM 的 impl 侧接的是**重写件**
//                rtl/memblock/SbufferData.sv（2026-09-20 起，codex 0168 裁定）。
//                ★不是黑盒，也不再是"两侧同一份 golden"★——后者等于白送，已改掉。
//    prefetcher  StorePfWrapper —— 本配置下 golden 已 DCE 成只剩 clock/reset 的空壳。
//                它与其内部的 Serializer **尚无重写件**，FM 两侧仍喂同一份 golden
//                （UNCHANGED_GOLDEN_DEP，见 verif/ut/Sbuffer/Makefile 的说明）：
//                本 target 对这两个模块**零信息量**，不构成对它们的证明。
// =============================================================================
module Sbuffer
  import sbuffer_pkg::*;
(
  // BEGIN GENERATED(wrapper_ports)
  input          clock,
  input          reset,
  input  [5:0]   io_hartId,
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [49:0]  io_in_0_bits_vaddr,
  input  [127:0] io_in_0_bits_data,
  input  [15:0]  io_in_0_bits_mask,
  input  [47:0]  io_in_0_bits_addr,
  input          io_in_0_bits_wline,
  input          io_in_0_bits_vecValid,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [49:0]  io_in_1_bits_vaddr,
  input  [127:0] io_in_1_bits_data,
  input  [15:0]  io_in_1_bits_mask,
  input  [47:0]  io_in_1_bits_addr,
  input          io_in_1_bits_wline,
  input          io_in_1_bits_vecValid,
  input          io_dcache_req_ready,
  output         io_dcache_req_valid,
  output [49:0]  io_dcache_req_bits_vaddr,
  output [47:0]  io_dcache_req_bits_addr,
  output [511:0] io_dcache_req_bits_data,
  output [63:0]  io_dcache_req_bits_mask,
  output [5:0]   io_dcache_req_bits_id,
  input          io_dcache_main_pipe_hit_resp_valid,
  input  [5:0]   io_dcache_main_pipe_hit_resp_bits_id,
  input          io_dcache_replay_resp_valid,
  input  [5:0]   io_dcache_replay_resp_bits_id,
  input  [49:0]  io_forward_0_vaddr,
  input  [47:0]  io_forward_0_paddr,
  input          io_forward_0_valid,
  output         io_forward_0_forwardMask_0,
  output         io_forward_0_forwardMask_1,
  output         io_forward_0_forwardMask_2,
  output         io_forward_0_forwardMask_3,
  output         io_forward_0_forwardMask_4,
  output         io_forward_0_forwardMask_5,
  output         io_forward_0_forwardMask_6,
  output         io_forward_0_forwardMask_7,
  output         io_forward_0_forwardMask_8,
  output         io_forward_0_forwardMask_9,
  output         io_forward_0_forwardMask_10,
  output         io_forward_0_forwardMask_11,
  output         io_forward_0_forwardMask_12,
  output         io_forward_0_forwardMask_13,
  output         io_forward_0_forwardMask_14,
  output         io_forward_0_forwardMask_15,
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
  output         io_forward_0_matchInvalid,
  input  [49:0]  io_forward_1_vaddr,
  input  [47:0]  io_forward_1_paddr,
  input          io_forward_1_valid,
  output         io_forward_1_forwardMask_0,
  output         io_forward_1_forwardMask_1,
  output         io_forward_1_forwardMask_2,
  output         io_forward_1_forwardMask_3,
  output         io_forward_1_forwardMask_4,
  output         io_forward_1_forwardMask_5,
  output         io_forward_1_forwardMask_6,
  output         io_forward_1_forwardMask_7,
  output         io_forward_1_forwardMask_8,
  output         io_forward_1_forwardMask_9,
  output         io_forward_1_forwardMask_10,
  output         io_forward_1_forwardMask_11,
  output         io_forward_1_forwardMask_12,
  output         io_forward_1_forwardMask_13,
  output         io_forward_1_forwardMask_14,
  output         io_forward_1_forwardMask_15,
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
  output         io_forward_1_matchInvalid,
  input  [49:0]  io_forward_2_vaddr,
  input  [47:0]  io_forward_2_paddr,
  input          io_forward_2_valid,
  output         io_forward_2_forwardMask_0,
  output         io_forward_2_forwardMask_1,
  output         io_forward_2_forwardMask_2,
  output         io_forward_2_forwardMask_3,
  output         io_forward_2_forwardMask_4,
  output         io_forward_2_forwardMask_5,
  output         io_forward_2_forwardMask_6,
  output         io_forward_2_forwardMask_7,
  output         io_forward_2_forwardMask_8,
  output         io_forward_2_forwardMask_9,
  output         io_forward_2_forwardMask_10,
  output         io_forward_2_forwardMask_11,
  output         io_forward_2_forwardMask_12,
  output         io_forward_2_forwardMask_13,
  output         io_forward_2_forwardMask_14,
  output         io_forward_2_forwardMask_15,
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
  output         io_forward_2_matchInvalid,
  input          io_sqempty,
  output         io_sbempty,
  output         io_sbFull,
  input          io_flush_valid,
  output         io_flush_empty,
  input  [21:0]  io_csrCtrl_sbuffer_timeout,
  input          io_force_write,
  input  [49:0]  io_diffStore_diffInfo_0_uop_pc,
  input  [34:0]  io_diffStore_diffInfo_0_uop_fuType,
  input  [8:0]   io_diffStore_diffInfo_0_uop_fuOpType,
  input  [2:0]   io_diffStore_diffInfo_0_uop_vpu_nf,
  input  [1:0]   io_diffStore_diffInfo_0_uop_vpu_veew,
  input  [7:0]   io_diffStore_diffInfo_0_uop_robIdx_value,
  input  [5:0]   io_diffStore_diffInfo_0_offset,
  input  [49:0]  io_diffStore_diffInfo_1_uop_pc,
  input  [34:0]  io_diffStore_diffInfo_1_uop_fuType,
  input  [8:0]   io_diffStore_diffInfo_1_uop_fuOpType,
  input  [2:0]   io_diffStore_diffInfo_1_uop_vpu_nf,
  input  [1:0]   io_diffStore_diffInfo_1_uop_vpu_veew,
  input  [7:0]   io_diffStore_diffInfo_1_uop_robIdx_value,
  input  [5:0]   io_diffStore_diffInfo_1_offset,
  input          io_diffStore_pmaStore_0_valid,
  input  [127:0] io_diffStore_pmaStore_0_bits_data,
  input  [15:0]  io_diffStore_pmaStore_0_bits_mask,
  input  [47:0]  io_diffStore_pmaStore_0_bits_addr,
  input          io_diffStore_pmaStore_0_bits_wline,
  input          io_diffStore_pmaStore_0_bits_vecValid,
  input          io_diffStore_pmaStore_1_valid,
  input  [127:0] io_diffStore_pmaStore_1_bits_data,
  input  [15:0]  io_diffStore_pmaStore_1_bits_mask,
  input  [47:0]  io_diffStore_pmaStore_1_bits_addr,
  input          io_diffStore_pmaStore_1_bits_wline,
  input          io_diffStore_pmaStore_1_bits_vecValid,
  input          io_diffStore_ncStore_valid,
  input  [47:0]  io_diffStore_ncStore_bits_addr,
  input  [63:0]  io_diffStore_ncStore_bits_data,
  input  [7:0]   io_diffStore_ncStore_bits_mask,
  input          io_diffStore_ncStore_bits_memBackTypeMM,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  output [5:0]   io_perf_7_value,
  output [5:0]   io_perf_8_value,
  output [5:0]   io_perf_9_value,
  output [5:0]   io_perf_10_value,
  output [5:0]   io_perf_11_value,
  output [5:0]   io_perf_12_value,
  output [5:0]   io_perf_13_value,
  output [5:0]   io_perf_14_value,
  output [5:0]   io_perf_15_value,
  output [656:0] gatewayIn_packed_49_bore,
  output [324:0] gatewayIn_packed_50_bore,
  output [324:0] gatewayIn_packed_51_bore,
  output [324:0] gatewayIn_packed_52_bore
  // END GENERATED(wrapper_ports)
);

  logic [ENSB_W-1:0]                  dm_wr_valid;
  logic [ENSB_W-1:0][SB_SIZE-1:0]     dm_wr_wvec;
  logic [ENSB_W-1:0][VDATA_BYTES-1:0] dm_wr_mask;
  logic [ENSB_W-1:0][VLEN-1:0]        dm_wr_data;
  logic [ENSB_W-1:0][VWOFF_W-1:0]     dm_wr_vwoff;
  logic [ENSB_W-1:0]                  dm_wr_wline;
  logic [0:0]                         dm_flush_valid;
  logic [0:0][SB_SIZE-1:0]            dm_flush_wvec;
  logic [SB_SIZE-1:0][CLINE_VWORDS-1:0][VDATA_BYTES-1:0][7:0] dm_data_out;
  logic [SB_SIZE-1:0][CLINE_VWORDS-1:0][VDATA_BYTES-1:0]      dm_mask_out;

  // BEGIN GENERATED(core_inst)
  xs_Sbuffer_core u_core (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_hartId                                (io_hartId),
    .io_in_0_ready                            (io_in_0_ready),
    .io_in_0_valid                            (io_in_0_valid),
    .io_in_0_bits_vaddr                       (io_in_0_bits_vaddr),
    .io_in_0_bits_data                        (io_in_0_bits_data),
    .io_in_0_bits_mask                        (io_in_0_bits_mask),
    .io_in_0_bits_addr                        (io_in_0_bits_addr),
    .io_in_0_bits_wline                       (io_in_0_bits_wline),
    .io_in_0_bits_vecValid                    (io_in_0_bits_vecValid),
    .io_in_1_ready                            (io_in_1_ready),
    .io_in_1_valid                            (io_in_1_valid),
    .io_in_1_bits_vaddr                       (io_in_1_bits_vaddr),
    .io_in_1_bits_data                        (io_in_1_bits_data),
    .io_in_1_bits_mask                        (io_in_1_bits_mask),
    .io_in_1_bits_addr                        (io_in_1_bits_addr),
    .io_in_1_bits_wline                       (io_in_1_bits_wline),
    .io_in_1_bits_vecValid                    (io_in_1_bits_vecValid),
    .io_dcache_req_ready                      (io_dcache_req_ready),
    .io_dcache_req_valid                      (io_dcache_req_valid),
    .io_dcache_req_bits_vaddr                 (io_dcache_req_bits_vaddr),
    .io_dcache_req_bits_addr                  (io_dcache_req_bits_addr),
    .io_dcache_req_bits_data                  (io_dcache_req_bits_data),
    .io_dcache_req_bits_mask                  (io_dcache_req_bits_mask),
    .io_dcache_req_bits_id                    (io_dcache_req_bits_id),
    .io_dcache_main_pipe_hit_resp_valid       (io_dcache_main_pipe_hit_resp_valid),
    .io_dcache_main_pipe_hit_resp_bits_id     (io_dcache_main_pipe_hit_resp_bits_id),
    .io_dcache_replay_resp_valid              (io_dcache_replay_resp_valid),
    .io_dcache_replay_resp_bits_id            (io_dcache_replay_resp_bits_id),
    .io_forward_0_vaddr                       (io_forward_0_vaddr),
    .io_forward_0_paddr                       (io_forward_0_paddr),
    .io_forward_0_valid                       (io_forward_0_valid),
    .io_forward_0_forwardMask_0               (io_forward_0_forwardMask_0),
    .io_forward_0_forwardMask_1               (io_forward_0_forwardMask_1),
    .io_forward_0_forwardMask_2               (io_forward_0_forwardMask_2),
    .io_forward_0_forwardMask_3               (io_forward_0_forwardMask_3),
    .io_forward_0_forwardMask_4               (io_forward_0_forwardMask_4),
    .io_forward_0_forwardMask_5               (io_forward_0_forwardMask_5),
    .io_forward_0_forwardMask_6               (io_forward_0_forwardMask_6),
    .io_forward_0_forwardMask_7               (io_forward_0_forwardMask_7),
    .io_forward_0_forwardMask_8               (io_forward_0_forwardMask_8),
    .io_forward_0_forwardMask_9               (io_forward_0_forwardMask_9),
    .io_forward_0_forwardMask_10              (io_forward_0_forwardMask_10),
    .io_forward_0_forwardMask_11              (io_forward_0_forwardMask_11),
    .io_forward_0_forwardMask_12              (io_forward_0_forwardMask_12),
    .io_forward_0_forwardMask_13              (io_forward_0_forwardMask_13),
    .io_forward_0_forwardMask_14              (io_forward_0_forwardMask_14),
    .io_forward_0_forwardMask_15              (io_forward_0_forwardMask_15),
    .io_forward_0_forwardData_0               (io_forward_0_forwardData_0),
    .io_forward_0_forwardData_1               (io_forward_0_forwardData_1),
    .io_forward_0_forwardData_2               (io_forward_0_forwardData_2),
    .io_forward_0_forwardData_3               (io_forward_0_forwardData_3),
    .io_forward_0_forwardData_4               (io_forward_0_forwardData_4),
    .io_forward_0_forwardData_5               (io_forward_0_forwardData_5),
    .io_forward_0_forwardData_6               (io_forward_0_forwardData_6),
    .io_forward_0_forwardData_7               (io_forward_0_forwardData_7),
    .io_forward_0_forwardData_8               (io_forward_0_forwardData_8),
    .io_forward_0_forwardData_9               (io_forward_0_forwardData_9),
    .io_forward_0_forwardData_10              (io_forward_0_forwardData_10),
    .io_forward_0_forwardData_11              (io_forward_0_forwardData_11),
    .io_forward_0_forwardData_12              (io_forward_0_forwardData_12),
    .io_forward_0_forwardData_13              (io_forward_0_forwardData_13),
    .io_forward_0_forwardData_14              (io_forward_0_forwardData_14),
    .io_forward_0_forwardData_15              (io_forward_0_forwardData_15),
    .io_forward_0_matchInvalid                (io_forward_0_matchInvalid),
    .io_forward_1_vaddr                       (io_forward_1_vaddr),
    .io_forward_1_paddr                       (io_forward_1_paddr),
    .io_forward_1_valid                       (io_forward_1_valid),
    .io_forward_1_forwardMask_0               (io_forward_1_forwardMask_0),
    .io_forward_1_forwardMask_1               (io_forward_1_forwardMask_1),
    .io_forward_1_forwardMask_2               (io_forward_1_forwardMask_2),
    .io_forward_1_forwardMask_3               (io_forward_1_forwardMask_3),
    .io_forward_1_forwardMask_4               (io_forward_1_forwardMask_4),
    .io_forward_1_forwardMask_5               (io_forward_1_forwardMask_5),
    .io_forward_1_forwardMask_6               (io_forward_1_forwardMask_6),
    .io_forward_1_forwardMask_7               (io_forward_1_forwardMask_7),
    .io_forward_1_forwardMask_8               (io_forward_1_forwardMask_8),
    .io_forward_1_forwardMask_9               (io_forward_1_forwardMask_9),
    .io_forward_1_forwardMask_10              (io_forward_1_forwardMask_10),
    .io_forward_1_forwardMask_11              (io_forward_1_forwardMask_11),
    .io_forward_1_forwardMask_12              (io_forward_1_forwardMask_12),
    .io_forward_1_forwardMask_13              (io_forward_1_forwardMask_13),
    .io_forward_1_forwardMask_14              (io_forward_1_forwardMask_14),
    .io_forward_1_forwardMask_15              (io_forward_1_forwardMask_15),
    .io_forward_1_forwardData_0               (io_forward_1_forwardData_0),
    .io_forward_1_forwardData_1               (io_forward_1_forwardData_1),
    .io_forward_1_forwardData_2               (io_forward_1_forwardData_2),
    .io_forward_1_forwardData_3               (io_forward_1_forwardData_3),
    .io_forward_1_forwardData_4               (io_forward_1_forwardData_4),
    .io_forward_1_forwardData_5               (io_forward_1_forwardData_5),
    .io_forward_1_forwardData_6               (io_forward_1_forwardData_6),
    .io_forward_1_forwardData_7               (io_forward_1_forwardData_7),
    .io_forward_1_forwardData_8               (io_forward_1_forwardData_8),
    .io_forward_1_forwardData_9               (io_forward_1_forwardData_9),
    .io_forward_1_forwardData_10              (io_forward_1_forwardData_10),
    .io_forward_1_forwardData_11              (io_forward_1_forwardData_11),
    .io_forward_1_forwardData_12              (io_forward_1_forwardData_12),
    .io_forward_1_forwardData_13              (io_forward_1_forwardData_13),
    .io_forward_1_forwardData_14              (io_forward_1_forwardData_14),
    .io_forward_1_forwardData_15              (io_forward_1_forwardData_15),
    .io_forward_1_matchInvalid                (io_forward_1_matchInvalid),
    .io_forward_2_vaddr                       (io_forward_2_vaddr),
    .io_forward_2_paddr                       (io_forward_2_paddr),
    .io_forward_2_valid                       (io_forward_2_valid),
    .io_forward_2_forwardMask_0               (io_forward_2_forwardMask_0),
    .io_forward_2_forwardMask_1               (io_forward_2_forwardMask_1),
    .io_forward_2_forwardMask_2               (io_forward_2_forwardMask_2),
    .io_forward_2_forwardMask_3               (io_forward_2_forwardMask_3),
    .io_forward_2_forwardMask_4               (io_forward_2_forwardMask_4),
    .io_forward_2_forwardMask_5               (io_forward_2_forwardMask_5),
    .io_forward_2_forwardMask_6               (io_forward_2_forwardMask_6),
    .io_forward_2_forwardMask_7               (io_forward_2_forwardMask_7),
    .io_forward_2_forwardMask_8               (io_forward_2_forwardMask_8),
    .io_forward_2_forwardMask_9               (io_forward_2_forwardMask_9),
    .io_forward_2_forwardMask_10              (io_forward_2_forwardMask_10),
    .io_forward_2_forwardMask_11              (io_forward_2_forwardMask_11),
    .io_forward_2_forwardMask_12              (io_forward_2_forwardMask_12),
    .io_forward_2_forwardMask_13              (io_forward_2_forwardMask_13),
    .io_forward_2_forwardMask_14              (io_forward_2_forwardMask_14),
    .io_forward_2_forwardMask_15              (io_forward_2_forwardMask_15),
    .io_forward_2_forwardData_0               (io_forward_2_forwardData_0),
    .io_forward_2_forwardData_1               (io_forward_2_forwardData_1),
    .io_forward_2_forwardData_2               (io_forward_2_forwardData_2),
    .io_forward_2_forwardData_3               (io_forward_2_forwardData_3),
    .io_forward_2_forwardData_4               (io_forward_2_forwardData_4),
    .io_forward_2_forwardData_5               (io_forward_2_forwardData_5),
    .io_forward_2_forwardData_6               (io_forward_2_forwardData_6),
    .io_forward_2_forwardData_7               (io_forward_2_forwardData_7),
    .io_forward_2_forwardData_8               (io_forward_2_forwardData_8),
    .io_forward_2_forwardData_9               (io_forward_2_forwardData_9),
    .io_forward_2_forwardData_10              (io_forward_2_forwardData_10),
    .io_forward_2_forwardData_11              (io_forward_2_forwardData_11),
    .io_forward_2_forwardData_12              (io_forward_2_forwardData_12),
    .io_forward_2_forwardData_13              (io_forward_2_forwardData_13),
    .io_forward_2_forwardData_14              (io_forward_2_forwardData_14),
    .io_forward_2_forwardData_15              (io_forward_2_forwardData_15),
    .io_forward_2_matchInvalid                (io_forward_2_matchInvalid),
    .io_sqempty                               (io_sqempty),
    .io_sbempty                               (io_sbempty),
    .io_sbFull                                (io_sbFull),
    .io_flush_valid                           (io_flush_valid),
    .io_flush_empty                           (io_flush_empty),
    .io_csrCtrl_sbuffer_timeout               (io_csrCtrl_sbuffer_timeout),
    .io_force_write                           (io_force_write),
    .io_diffStore_diffInfo_0_uop_pc           (io_diffStore_diffInfo_0_uop_pc),
    .io_diffStore_diffInfo_0_uop_fuType       (io_diffStore_diffInfo_0_uop_fuType),
    .io_diffStore_diffInfo_0_uop_fuOpType     (io_diffStore_diffInfo_0_uop_fuOpType),
    .io_diffStore_diffInfo_0_uop_vpu_nf       (io_diffStore_diffInfo_0_uop_vpu_nf),
    .io_diffStore_diffInfo_0_uop_vpu_veew     (io_diffStore_diffInfo_0_uop_vpu_veew),
    .io_diffStore_diffInfo_0_uop_robIdx_value (io_diffStore_diffInfo_0_uop_robIdx_value),
    .io_diffStore_diffInfo_0_offset           (io_diffStore_diffInfo_0_offset),
    .io_diffStore_diffInfo_1_uop_pc           (io_diffStore_diffInfo_1_uop_pc),
    .io_diffStore_diffInfo_1_uop_fuType       (io_diffStore_diffInfo_1_uop_fuType),
    .io_diffStore_diffInfo_1_uop_fuOpType     (io_diffStore_diffInfo_1_uop_fuOpType),
    .io_diffStore_diffInfo_1_uop_vpu_nf       (io_diffStore_diffInfo_1_uop_vpu_nf),
    .io_diffStore_diffInfo_1_uop_vpu_veew     (io_diffStore_diffInfo_1_uop_vpu_veew),
    .io_diffStore_diffInfo_1_uop_robIdx_value (io_diffStore_diffInfo_1_uop_robIdx_value),
    .io_diffStore_diffInfo_1_offset           (io_diffStore_diffInfo_1_offset),
    .io_diffStore_pmaStore_0_valid            (io_diffStore_pmaStore_0_valid),
    .io_diffStore_pmaStore_0_bits_data        (io_diffStore_pmaStore_0_bits_data),
    .io_diffStore_pmaStore_0_bits_mask        (io_diffStore_pmaStore_0_bits_mask),
    .io_diffStore_pmaStore_0_bits_addr        (io_diffStore_pmaStore_0_bits_addr),
    .io_diffStore_pmaStore_0_bits_wline       (io_diffStore_pmaStore_0_bits_wline),
    .io_diffStore_pmaStore_0_bits_vecValid    (io_diffStore_pmaStore_0_bits_vecValid),
    .io_diffStore_pmaStore_1_valid            (io_diffStore_pmaStore_1_valid),
    .io_diffStore_pmaStore_1_bits_data        (io_diffStore_pmaStore_1_bits_data),
    .io_diffStore_pmaStore_1_bits_mask        (io_diffStore_pmaStore_1_bits_mask),
    .io_diffStore_pmaStore_1_bits_addr        (io_diffStore_pmaStore_1_bits_addr),
    .io_diffStore_pmaStore_1_bits_wline       (io_diffStore_pmaStore_1_bits_wline),
    .io_diffStore_pmaStore_1_bits_vecValid    (io_diffStore_pmaStore_1_bits_vecValid),
    .io_diffStore_ncStore_valid               (io_diffStore_ncStore_valid),
    .io_diffStore_ncStore_bits_addr           (io_diffStore_ncStore_bits_addr),
    .io_diffStore_ncStore_bits_data           (io_diffStore_ncStore_bits_data),
    .io_diffStore_ncStore_bits_mask           (io_diffStore_ncStore_bits_mask),
    .io_diffStore_ncStore_bits_memBackTypeMM  (io_diffStore_ncStore_bits_memBackTypeMM),
    .io_perf_0_value                          (io_perf_0_value),
    .io_perf_1_value                          (io_perf_1_value),
    .io_perf_2_value                          (io_perf_2_value),
    .io_perf_3_value                          (io_perf_3_value),
    .io_perf_4_value                          (io_perf_4_value),
    .io_perf_5_value                          (io_perf_5_value),
    .io_perf_6_value                          (io_perf_6_value),
    .io_perf_7_value                          (io_perf_7_value),
    .io_perf_8_value                          (io_perf_8_value),
    .io_perf_9_value                          (io_perf_9_value),
    .io_perf_10_value                         (io_perf_10_value),
    .io_perf_11_value                         (io_perf_11_value),
    .io_perf_12_value                         (io_perf_12_value),
    .io_perf_13_value                         (io_perf_13_value),
    .io_perf_14_value                         (io_perf_14_value),
    .io_perf_15_value                         (io_perf_15_value),
    .gatewayIn_packed_49_bore                 (gatewayIn_packed_49_bore),
    .gatewayIn_packed_50_bore                 (gatewayIn_packed_50_bore),
    .gatewayIn_packed_51_bore                 (gatewayIn_packed_51_bore),
    .gatewayIn_packed_52_bore                 (gatewayIn_packed_52_bore),
    .dm_wr_valid                              (dm_wr_valid),
    .dm_wr_wvec                               (dm_wr_wvec),
    .dm_wr_mask                               (dm_wr_mask),
    .dm_wr_data                               (dm_wr_data),
    .dm_wr_vwoff                              (dm_wr_vwoff),
    .dm_wr_wline                              (dm_wr_wline),
    .dm_flush_valid                           (dm_flush_valid),
    .dm_flush_wvec                            (dm_flush_wvec),
    .dm_data_out                              (dm_data_out),
    .dm_mask_out                              (dm_mask_out)
  );
  // END GENERATED(core_inst)

  // BEGIN GENERATED(datamodule_inst)
  SbufferData dataModule (
    .clock                              (clock),
    .reset                              (reset),
    .io_writeReq_0_valid                (dm_wr_valid[0]),
    .io_writeReq_0_bits_wvec            (dm_wr_wvec[0]),
    .io_writeReq_0_bits_mask            (dm_wr_mask[0]),
    .io_writeReq_0_bits_data            (dm_wr_data[0]),
    .io_writeReq_0_bits_vwordOffset     (dm_wr_vwoff[0]),
    .io_writeReq_0_bits_wline           (dm_wr_wline[0]),
    .io_writeReq_1_valid                (dm_wr_valid[1]),
    .io_writeReq_1_bits_wvec            (dm_wr_wvec[1]),
    .io_writeReq_1_bits_mask            (dm_wr_mask[1]),
    .io_writeReq_1_bits_data            (dm_wr_data[1]),
    .io_writeReq_1_bits_vwordOffset     (dm_wr_vwoff[1]),
    .io_writeReq_1_bits_wline           (dm_wr_wline[1]),
    .io_maskFlushReq_0_valid            (dm_flush_valid[0]),
    .io_maskFlushReq_0_bits_wvec        (dm_flush_wvec[0]),
    .io_dataOut_0_0_0                   (dm_data_out[0][0][0]),
    .io_dataOut_0_0_1                   (dm_data_out[0][0][1]),
    .io_dataOut_0_0_2                   (dm_data_out[0][0][2]),
    .io_dataOut_0_0_3                   (dm_data_out[0][0][3]),
    .io_dataOut_0_0_4                   (dm_data_out[0][0][4]),
    .io_dataOut_0_0_5                   (dm_data_out[0][0][5]),
    .io_dataOut_0_0_6                   (dm_data_out[0][0][6]),
    .io_dataOut_0_0_7                   (dm_data_out[0][0][7]),
    .io_dataOut_0_0_8                   (dm_data_out[0][0][8]),
    .io_dataOut_0_0_9                   (dm_data_out[0][0][9]),
    .io_dataOut_0_0_10                  (dm_data_out[0][0][10]),
    .io_dataOut_0_0_11                  (dm_data_out[0][0][11]),
    .io_dataOut_0_0_12                  (dm_data_out[0][0][12]),
    .io_dataOut_0_0_13                  (dm_data_out[0][0][13]),
    .io_dataOut_0_0_14                  (dm_data_out[0][0][14]),
    .io_dataOut_0_0_15                  (dm_data_out[0][0][15]),
    .io_dataOut_0_1_0                   (dm_data_out[0][1][0]),
    .io_dataOut_0_1_1                   (dm_data_out[0][1][1]),
    .io_dataOut_0_1_2                   (dm_data_out[0][1][2]),
    .io_dataOut_0_1_3                   (dm_data_out[0][1][3]),
    .io_dataOut_0_1_4                   (dm_data_out[0][1][4]),
    .io_dataOut_0_1_5                   (dm_data_out[0][1][5]),
    .io_dataOut_0_1_6                   (dm_data_out[0][1][6]),
    .io_dataOut_0_1_7                   (dm_data_out[0][1][7]),
    .io_dataOut_0_1_8                   (dm_data_out[0][1][8]),
    .io_dataOut_0_1_9                   (dm_data_out[0][1][9]),
    .io_dataOut_0_1_10                  (dm_data_out[0][1][10]),
    .io_dataOut_0_1_11                  (dm_data_out[0][1][11]),
    .io_dataOut_0_1_12                  (dm_data_out[0][1][12]),
    .io_dataOut_0_1_13                  (dm_data_out[0][1][13]),
    .io_dataOut_0_1_14                  (dm_data_out[0][1][14]),
    .io_dataOut_0_1_15                  (dm_data_out[0][1][15]),
    .io_dataOut_0_2_0                   (dm_data_out[0][2][0]),
    .io_dataOut_0_2_1                   (dm_data_out[0][2][1]),
    .io_dataOut_0_2_2                   (dm_data_out[0][2][2]),
    .io_dataOut_0_2_3                   (dm_data_out[0][2][3]),
    .io_dataOut_0_2_4                   (dm_data_out[0][2][4]),
    .io_dataOut_0_2_5                   (dm_data_out[0][2][5]),
    .io_dataOut_0_2_6                   (dm_data_out[0][2][6]),
    .io_dataOut_0_2_7                   (dm_data_out[0][2][7]),
    .io_dataOut_0_2_8                   (dm_data_out[0][2][8]),
    .io_dataOut_0_2_9                   (dm_data_out[0][2][9]),
    .io_dataOut_0_2_10                  (dm_data_out[0][2][10]),
    .io_dataOut_0_2_11                  (dm_data_out[0][2][11]),
    .io_dataOut_0_2_12                  (dm_data_out[0][2][12]),
    .io_dataOut_0_2_13                  (dm_data_out[0][2][13]),
    .io_dataOut_0_2_14                  (dm_data_out[0][2][14]),
    .io_dataOut_0_2_15                  (dm_data_out[0][2][15]),
    .io_dataOut_0_3_0                   (dm_data_out[0][3][0]),
    .io_dataOut_0_3_1                   (dm_data_out[0][3][1]),
    .io_dataOut_0_3_2                   (dm_data_out[0][3][2]),
    .io_dataOut_0_3_3                   (dm_data_out[0][3][3]),
    .io_dataOut_0_3_4                   (dm_data_out[0][3][4]),
    .io_dataOut_0_3_5                   (dm_data_out[0][3][5]),
    .io_dataOut_0_3_6                   (dm_data_out[0][3][6]),
    .io_dataOut_0_3_7                   (dm_data_out[0][3][7]),
    .io_dataOut_0_3_8                   (dm_data_out[0][3][8]),
    .io_dataOut_0_3_9                   (dm_data_out[0][3][9]),
    .io_dataOut_0_3_10                  (dm_data_out[0][3][10]),
    .io_dataOut_0_3_11                  (dm_data_out[0][3][11]),
    .io_dataOut_0_3_12                  (dm_data_out[0][3][12]),
    .io_dataOut_0_3_13                  (dm_data_out[0][3][13]),
    .io_dataOut_0_3_14                  (dm_data_out[0][3][14]),
    .io_dataOut_0_3_15                  (dm_data_out[0][3][15]),
    .io_dataOut_1_0_0                   (dm_data_out[1][0][0]),
    .io_dataOut_1_0_1                   (dm_data_out[1][0][1]),
    .io_dataOut_1_0_2                   (dm_data_out[1][0][2]),
    .io_dataOut_1_0_3                   (dm_data_out[1][0][3]),
    .io_dataOut_1_0_4                   (dm_data_out[1][0][4]),
    .io_dataOut_1_0_5                   (dm_data_out[1][0][5]),
    .io_dataOut_1_0_6                   (dm_data_out[1][0][6]),
    .io_dataOut_1_0_7                   (dm_data_out[1][0][7]),
    .io_dataOut_1_0_8                   (dm_data_out[1][0][8]),
    .io_dataOut_1_0_9                   (dm_data_out[1][0][9]),
    .io_dataOut_1_0_10                  (dm_data_out[1][0][10]),
    .io_dataOut_1_0_11                  (dm_data_out[1][0][11]),
    .io_dataOut_1_0_12                  (dm_data_out[1][0][12]),
    .io_dataOut_1_0_13                  (dm_data_out[1][0][13]),
    .io_dataOut_1_0_14                  (dm_data_out[1][0][14]),
    .io_dataOut_1_0_15                  (dm_data_out[1][0][15]),
    .io_dataOut_1_1_0                   (dm_data_out[1][1][0]),
    .io_dataOut_1_1_1                   (dm_data_out[1][1][1]),
    .io_dataOut_1_1_2                   (dm_data_out[1][1][2]),
    .io_dataOut_1_1_3                   (dm_data_out[1][1][3]),
    .io_dataOut_1_1_4                   (dm_data_out[1][1][4]),
    .io_dataOut_1_1_5                   (dm_data_out[1][1][5]),
    .io_dataOut_1_1_6                   (dm_data_out[1][1][6]),
    .io_dataOut_1_1_7                   (dm_data_out[1][1][7]),
    .io_dataOut_1_1_8                   (dm_data_out[1][1][8]),
    .io_dataOut_1_1_9                   (dm_data_out[1][1][9]),
    .io_dataOut_1_1_10                  (dm_data_out[1][1][10]),
    .io_dataOut_1_1_11                  (dm_data_out[1][1][11]),
    .io_dataOut_1_1_12                  (dm_data_out[1][1][12]),
    .io_dataOut_1_1_13                  (dm_data_out[1][1][13]),
    .io_dataOut_1_1_14                  (dm_data_out[1][1][14]),
    .io_dataOut_1_1_15                  (dm_data_out[1][1][15]),
    .io_dataOut_1_2_0                   (dm_data_out[1][2][0]),
    .io_dataOut_1_2_1                   (dm_data_out[1][2][1]),
    .io_dataOut_1_2_2                   (dm_data_out[1][2][2]),
    .io_dataOut_1_2_3                   (dm_data_out[1][2][3]),
    .io_dataOut_1_2_4                   (dm_data_out[1][2][4]),
    .io_dataOut_1_2_5                   (dm_data_out[1][2][5]),
    .io_dataOut_1_2_6                   (dm_data_out[1][2][6]),
    .io_dataOut_1_2_7                   (dm_data_out[1][2][7]),
    .io_dataOut_1_2_8                   (dm_data_out[1][2][8]),
    .io_dataOut_1_2_9                   (dm_data_out[1][2][9]),
    .io_dataOut_1_2_10                  (dm_data_out[1][2][10]),
    .io_dataOut_1_2_11                  (dm_data_out[1][2][11]),
    .io_dataOut_1_2_12                  (dm_data_out[1][2][12]),
    .io_dataOut_1_2_13                  (dm_data_out[1][2][13]),
    .io_dataOut_1_2_14                  (dm_data_out[1][2][14]),
    .io_dataOut_1_2_15                  (dm_data_out[1][2][15]),
    .io_dataOut_1_3_0                   (dm_data_out[1][3][0]),
    .io_dataOut_1_3_1                   (dm_data_out[1][3][1]),
    .io_dataOut_1_3_2                   (dm_data_out[1][3][2]),
    .io_dataOut_1_3_3                   (dm_data_out[1][3][3]),
    .io_dataOut_1_3_4                   (dm_data_out[1][3][4]),
    .io_dataOut_1_3_5                   (dm_data_out[1][3][5]),
    .io_dataOut_1_3_6                   (dm_data_out[1][3][6]),
    .io_dataOut_1_3_7                   (dm_data_out[1][3][7]),
    .io_dataOut_1_3_8                   (dm_data_out[1][3][8]),
    .io_dataOut_1_3_9                   (dm_data_out[1][3][9]),
    .io_dataOut_1_3_10                  (dm_data_out[1][3][10]),
    .io_dataOut_1_3_11                  (dm_data_out[1][3][11]),
    .io_dataOut_1_3_12                  (dm_data_out[1][3][12]),
    .io_dataOut_1_3_13                  (dm_data_out[1][3][13]),
    .io_dataOut_1_3_14                  (dm_data_out[1][3][14]),
    .io_dataOut_1_3_15                  (dm_data_out[1][3][15]),
    .io_dataOut_2_0_0                   (dm_data_out[2][0][0]),
    .io_dataOut_2_0_1                   (dm_data_out[2][0][1]),
    .io_dataOut_2_0_2                   (dm_data_out[2][0][2]),
    .io_dataOut_2_0_3                   (dm_data_out[2][0][3]),
    .io_dataOut_2_0_4                   (dm_data_out[2][0][4]),
    .io_dataOut_2_0_5                   (dm_data_out[2][0][5]),
    .io_dataOut_2_0_6                   (dm_data_out[2][0][6]),
    .io_dataOut_2_0_7                   (dm_data_out[2][0][7]),
    .io_dataOut_2_0_8                   (dm_data_out[2][0][8]),
    .io_dataOut_2_0_9                   (dm_data_out[2][0][9]),
    .io_dataOut_2_0_10                  (dm_data_out[2][0][10]),
    .io_dataOut_2_0_11                  (dm_data_out[2][0][11]),
    .io_dataOut_2_0_12                  (dm_data_out[2][0][12]),
    .io_dataOut_2_0_13                  (dm_data_out[2][0][13]),
    .io_dataOut_2_0_14                  (dm_data_out[2][0][14]),
    .io_dataOut_2_0_15                  (dm_data_out[2][0][15]),
    .io_dataOut_2_1_0                   (dm_data_out[2][1][0]),
    .io_dataOut_2_1_1                   (dm_data_out[2][1][1]),
    .io_dataOut_2_1_2                   (dm_data_out[2][1][2]),
    .io_dataOut_2_1_3                   (dm_data_out[2][1][3]),
    .io_dataOut_2_1_4                   (dm_data_out[2][1][4]),
    .io_dataOut_2_1_5                   (dm_data_out[2][1][5]),
    .io_dataOut_2_1_6                   (dm_data_out[2][1][6]),
    .io_dataOut_2_1_7                   (dm_data_out[2][1][7]),
    .io_dataOut_2_1_8                   (dm_data_out[2][1][8]),
    .io_dataOut_2_1_9                   (dm_data_out[2][1][9]),
    .io_dataOut_2_1_10                  (dm_data_out[2][1][10]),
    .io_dataOut_2_1_11                  (dm_data_out[2][1][11]),
    .io_dataOut_2_1_12                  (dm_data_out[2][1][12]),
    .io_dataOut_2_1_13                  (dm_data_out[2][1][13]),
    .io_dataOut_2_1_14                  (dm_data_out[2][1][14]),
    .io_dataOut_2_1_15                  (dm_data_out[2][1][15]),
    .io_dataOut_2_2_0                   (dm_data_out[2][2][0]),
    .io_dataOut_2_2_1                   (dm_data_out[2][2][1]),
    .io_dataOut_2_2_2                   (dm_data_out[2][2][2]),
    .io_dataOut_2_2_3                   (dm_data_out[2][2][3]),
    .io_dataOut_2_2_4                   (dm_data_out[2][2][4]),
    .io_dataOut_2_2_5                   (dm_data_out[2][2][5]),
    .io_dataOut_2_2_6                   (dm_data_out[2][2][6]),
    .io_dataOut_2_2_7                   (dm_data_out[2][2][7]),
    .io_dataOut_2_2_8                   (dm_data_out[2][2][8]),
    .io_dataOut_2_2_9                   (dm_data_out[2][2][9]),
    .io_dataOut_2_2_10                  (dm_data_out[2][2][10]),
    .io_dataOut_2_2_11                  (dm_data_out[2][2][11]),
    .io_dataOut_2_2_12                  (dm_data_out[2][2][12]),
    .io_dataOut_2_2_13                  (dm_data_out[2][2][13]),
    .io_dataOut_2_2_14                  (dm_data_out[2][2][14]),
    .io_dataOut_2_2_15                  (dm_data_out[2][2][15]),
    .io_dataOut_2_3_0                   (dm_data_out[2][3][0]),
    .io_dataOut_2_3_1                   (dm_data_out[2][3][1]),
    .io_dataOut_2_3_2                   (dm_data_out[2][3][2]),
    .io_dataOut_2_3_3                   (dm_data_out[2][3][3]),
    .io_dataOut_2_3_4                   (dm_data_out[2][3][4]),
    .io_dataOut_2_3_5                   (dm_data_out[2][3][5]),
    .io_dataOut_2_3_6                   (dm_data_out[2][3][6]),
    .io_dataOut_2_3_7                   (dm_data_out[2][3][7]),
    .io_dataOut_2_3_8                   (dm_data_out[2][3][8]),
    .io_dataOut_2_3_9                   (dm_data_out[2][3][9]),
    .io_dataOut_2_3_10                  (dm_data_out[2][3][10]),
    .io_dataOut_2_3_11                  (dm_data_out[2][3][11]),
    .io_dataOut_2_3_12                  (dm_data_out[2][3][12]),
    .io_dataOut_2_3_13                  (dm_data_out[2][3][13]),
    .io_dataOut_2_3_14                  (dm_data_out[2][3][14]),
    .io_dataOut_2_3_15                  (dm_data_out[2][3][15]),
    .io_dataOut_3_0_0                   (dm_data_out[3][0][0]),
    .io_dataOut_3_0_1                   (dm_data_out[3][0][1]),
    .io_dataOut_3_0_2                   (dm_data_out[3][0][2]),
    .io_dataOut_3_0_3                   (dm_data_out[3][0][3]),
    .io_dataOut_3_0_4                   (dm_data_out[3][0][4]),
    .io_dataOut_3_0_5                   (dm_data_out[3][0][5]),
    .io_dataOut_3_0_6                   (dm_data_out[3][0][6]),
    .io_dataOut_3_0_7                   (dm_data_out[3][0][7]),
    .io_dataOut_3_0_8                   (dm_data_out[3][0][8]),
    .io_dataOut_3_0_9                   (dm_data_out[3][0][9]),
    .io_dataOut_3_0_10                  (dm_data_out[3][0][10]),
    .io_dataOut_3_0_11                  (dm_data_out[3][0][11]),
    .io_dataOut_3_0_12                  (dm_data_out[3][0][12]),
    .io_dataOut_3_0_13                  (dm_data_out[3][0][13]),
    .io_dataOut_3_0_14                  (dm_data_out[3][0][14]),
    .io_dataOut_3_0_15                  (dm_data_out[3][0][15]),
    .io_dataOut_3_1_0                   (dm_data_out[3][1][0]),
    .io_dataOut_3_1_1                   (dm_data_out[3][1][1]),
    .io_dataOut_3_1_2                   (dm_data_out[3][1][2]),
    .io_dataOut_3_1_3                   (dm_data_out[3][1][3]),
    .io_dataOut_3_1_4                   (dm_data_out[3][1][4]),
    .io_dataOut_3_1_5                   (dm_data_out[3][1][5]),
    .io_dataOut_3_1_6                   (dm_data_out[3][1][6]),
    .io_dataOut_3_1_7                   (dm_data_out[3][1][7]),
    .io_dataOut_3_1_8                   (dm_data_out[3][1][8]),
    .io_dataOut_3_1_9                   (dm_data_out[3][1][9]),
    .io_dataOut_3_1_10                  (dm_data_out[3][1][10]),
    .io_dataOut_3_1_11                  (dm_data_out[3][1][11]),
    .io_dataOut_3_1_12                  (dm_data_out[3][1][12]),
    .io_dataOut_3_1_13                  (dm_data_out[3][1][13]),
    .io_dataOut_3_1_14                  (dm_data_out[3][1][14]),
    .io_dataOut_3_1_15                  (dm_data_out[3][1][15]),
    .io_dataOut_3_2_0                   (dm_data_out[3][2][0]),
    .io_dataOut_3_2_1                   (dm_data_out[3][2][1]),
    .io_dataOut_3_2_2                   (dm_data_out[3][2][2]),
    .io_dataOut_3_2_3                   (dm_data_out[3][2][3]),
    .io_dataOut_3_2_4                   (dm_data_out[3][2][4]),
    .io_dataOut_3_2_5                   (dm_data_out[3][2][5]),
    .io_dataOut_3_2_6                   (dm_data_out[3][2][6]),
    .io_dataOut_3_2_7                   (dm_data_out[3][2][7]),
    .io_dataOut_3_2_8                   (dm_data_out[3][2][8]),
    .io_dataOut_3_2_9                   (dm_data_out[3][2][9]),
    .io_dataOut_3_2_10                  (dm_data_out[3][2][10]),
    .io_dataOut_3_2_11                  (dm_data_out[3][2][11]),
    .io_dataOut_3_2_12                  (dm_data_out[3][2][12]),
    .io_dataOut_3_2_13                  (dm_data_out[3][2][13]),
    .io_dataOut_3_2_14                  (dm_data_out[3][2][14]),
    .io_dataOut_3_2_15                  (dm_data_out[3][2][15]),
    .io_dataOut_3_3_0                   (dm_data_out[3][3][0]),
    .io_dataOut_3_3_1                   (dm_data_out[3][3][1]),
    .io_dataOut_3_3_2                   (dm_data_out[3][3][2]),
    .io_dataOut_3_3_3                   (dm_data_out[3][3][3]),
    .io_dataOut_3_3_4                   (dm_data_out[3][3][4]),
    .io_dataOut_3_3_5                   (dm_data_out[3][3][5]),
    .io_dataOut_3_3_6                   (dm_data_out[3][3][6]),
    .io_dataOut_3_3_7                   (dm_data_out[3][3][7]),
    .io_dataOut_3_3_8                   (dm_data_out[3][3][8]),
    .io_dataOut_3_3_9                   (dm_data_out[3][3][9]),
    .io_dataOut_3_3_10                  (dm_data_out[3][3][10]),
    .io_dataOut_3_3_11                  (dm_data_out[3][3][11]),
    .io_dataOut_3_3_12                  (dm_data_out[3][3][12]),
    .io_dataOut_3_3_13                  (dm_data_out[3][3][13]),
    .io_dataOut_3_3_14                  (dm_data_out[3][3][14]),
    .io_dataOut_3_3_15                  (dm_data_out[3][3][15]),
    .io_dataOut_4_0_0                   (dm_data_out[4][0][0]),
    .io_dataOut_4_0_1                   (dm_data_out[4][0][1]),
    .io_dataOut_4_0_2                   (dm_data_out[4][0][2]),
    .io_dataOut_4_0_3                   (dm_data_out[4][0][3]),
    .io_dataOut_4_0_4                   (dm_data_out[4][0][4]),
    .io_dataOut_4_0_5                   (dm_data_out[4][0][5]),
    .io_dataOut_4_0_6                   (dm_data_out[4][0][6]),
    .io_dataOut_4_0_7                   (dm_data_out[4][0][7]),
    .io_dataOut_4_0_8                   (dm_data_out[4][0][8]),
    .io_dataOut_4_0_9                   (dm_data_out[4][0][9]),
    .io_dataOut_4_0_10                  (dm_data_out[4][0][10]),
    .io_dataOut_4_0_11                  (dm_data_out[4][0][11]),
    .io_dataOut_4_0_12                  (dm_data_out[4][0][12]),
    .io_dataOut_4_0_13                  (dm_data_out[4][0][13]),
    .io_dataOut_4_0_14                  (dm_data_out[4][0][14]),
    .io_dataOut_4_0_15                  (dm_data_out[4][0][15]),
    .io_dataOut_4_1_0                   (dm_data_out[4][1][0]),
    .io_dataOut_4_1_1                   (dm_data_out[4][1][1]),
    .io_dataOut_4_1_2                   (dm_data_out[4][1][2]),
    .io_dataOut_4_1_3                   (dm_data_out[4][1][3]),
    .io_dataOut_4_1_4                   (dm_data_out[4][1][4]),
    .io_dataOut_4_1_5                   (dm_data_out[4][1][5]),
    .io_dataOut_4_1_6                   (dm_data_out[4][1][6]),
    .io_dataOut_4_1_7                   (dm_data_out[4][1][7]),
    .io_dataOut_4_1_8                   (dm_data_out[4][1][8]),
    .io_dataOut_4_1_9                   (dm_data_out[4][1][9]),
    .io_dataOut_4_1_10                  (dm_data_out[4][1][10]),
    .io_dataOut_4_1_11                  (dm_data_out[4][1][11]),
    .io_dataOut_4_1_12                  (dm_data_out[4][1][12]),
    .io_dataOut_4_1_13                  (dm_data_out[4][1][13]),
    .io_dataOut_4_1_14                  (dm_data_out[4][1][14]),
    .io_dataOut_4_1_15                  (dm_data_out[4][1][15]),
    .io_dataOut_4_2_0                   (dm_data_out[4][2][0]),
    .io_dataOut_4_2_1                   (dm_data_out[4][2][1]),
    .io_dataOut_4_2_2                   (dm_data_out[4][2][2]),
    .io_dataOut_4_2_3                   (dm_data_out[4][2][3]),
    .io_dataOut_4_2_4                   (dm_data_out[4][2][4]),
    .io_dataOut_4_2_5                   (dm_data_out[4][2][5]),
    .io_dataOut_4_2_6                   (dm_data_out[4][2][6]),
    .io_dataOut_4_2_7                   (dm_data_out[4][2][7]),
    .io_dataOut_4_2_8                   (dm_data_out[4][2][8]),
    .io_dataOut_4_2_9                   (dm_data_out[4][2][9]),
    .io_dataOut_4_2_10                  (dm_data_out[4][2][10]),
    .io_dataOut_4_2_11                  (dm_data_out[4][2][11]),
    .io_dataOut_4_2_12                  (dm_data_out[4][2][12]),
    .io_dataOut_4_2_13                  (dm_data_out[4][2][13]),
    .io_dataOut_4_2_14                  (dm_data_out[4][2][14]),
    .io_dataOut_4_2_15                  (dm_data_out[4][2][15]),
    .io_dataOut_4_3_0                   (dm_data_out[4][3][0]),
    .io_dataOut_4_3_1                   (dm_data_out[4][3][1]),
    .io_dataOut_4_3_2                   (dm_data_out[4][3][2]),
    .io_dataOut_4_3_3                   (dm_data_out[4][3][3]),
    .io_dataOut_4_3_4                   (dm_data_out[4][3][4]),
    .io_dataOut_4_3_5                   (dm_data_out[4][3][5]),
    .io_dataOut_4_3_6                   (dm_data_out[4][3][6]),
    .io_dataOut_4_3_7                   (dm_data_out[4][3][7]),
    .io_dataOut_4_3_8                   (dm_data_out[4][3][8]),
    .io_dataOut_4_3_9                   (dm_data_out[4][3][9]),
    .io_dataOut_4_3_10                  (dm_data_out[4][3][10]),
    .io_dataOut_4_3_11                  (dm_data_out[4][3][11]),
    .io_dataOut_4_3_12                  (dm_data_out[4][3][12]),
    .io_dataOut_4_3_13                  (dm_data_out[4][3][13]),
    .io_dataOut_4_3_14                  (dm_data_out[4][3][14]),
    .io_dataOut_4_3_15                  (dm_data_out[4][3][15]),
    .io_dataOut_5_0_0                   (dm_data_out[5][0][0]),
    .io_dataOut_5_0_1                   (dm_data_out[5][0][1]),
    .io_dataOut_5_0_2                   (dm_data_out[5][0][2]),
    .io_dataOut_5_0_3                   (dm_data_out[5][0][3]),
    .io_dataOut_5_0_4                   (dm_data_out[5][0][4]),
    .io_dataOut_5_0_5                   (dm_data_out[5][0][5]),
    .io_dataOut_5_0_6                   (dm_data_out[5][0][6]),
    .io_dataOut_5_0_7                   (dm_data_out[5][0][7]),
    .io_dataOut_5_0_8                   (dm_data_out[5][0][8]),
    .io_dataOut_5_0_9                   (dm_data_out[5][0][9]),
    .io_dataOut_5_0_10                  (dm_data_out[5][0][10]),
    .io_dataOut_5_0_11                  (dm_data_out[5][0][11]),
    .io_dataOut_5_0_12                  (dm_data_out[5][0][12]),
    .io_dataOut_5_0_13                  (dm_data_out[5][0][13]),
    .io_dataOut_5_0_14                  (dm_data_out[5][0][14]),
    .io_dataOut_5_0_15                  (dm_data_out[5][0][15]),
    .io_dataOut_5_1_0                   (dm_data_out[5][1][0]),
    .io_dataOut_5_1_1                   (dm_data_out[5][1][1]),
    .io_dataOut_5_1_2                   (dm_data_out[5][1][2]),
    .io_dataOut_5_1_3                   (dm_data_out[5][1][3]),
    .io_dataOut_5_1_4                   (dm_data_out[5][1][4]),
    .io_dataOut_5_1_5                   (dm_data_out[5][1][5]),
    .io_dataOut_5_1_6                   (dm_data_out[5][1][6]),
    .io_dataOut_5_1_7                   (dm_data_out[5][1][7]),
    .io_dataOut_5_1_8                   (dm_data_out[5][1][8]),
    .io_dataOut_5_1_9                   (dm_data_out[5][1][9]),
    .io_dataOut_5_1_10                  (dm_data_out[5][1][10]),
    .io_dataOut_5_1_11                  (dm_data_out[5][1][11]),
    .io_dataOut_5_1_12                  (dm_data_out[5][1][12]),
    .io_dataOut_5_1_13                  (dm_data_out[5][1][13]),
    .io_dataOut_5_1_14                  (dm_data_out[5][1][14]),
    .io_dataOut_5_1_15                  (dm_data_out[5][1][15]),
    .io_dataOut_5_2_0                   (dm_data_out[5][2][0]),
    .io_dataOut_5_2_1                   (dm_data_out[5][2][1]),
    .io_dataOut_5_2_2                   (dm_data_out[5][2][2]),
    .io_dataOut_5_2_3                   (dm_data_out[5][2][3]),
    .io_dataOut_5_2_4                   (dm_data_out[5][2][4]),
    .io_dataOut_5_2_5                   (dm_data_out[5][2][5]),
    .io_dataOut_5_2_6                   (dm_data_out[5][2][6]),
    .io_dataOut_5_2_7                   (dm_data_out[5][2][7]),
    .io_dataOut_5_2_8                   (dm_data_out[5][2][8]),
    .io_dataOut_5_2_9                   (dm_data_out[5][2][9]),
    .io_dataOut_5_2_10                  (dm_data_out[5][2][10]),
    .io_dataOut_5_2_11                  (dm_data_out[5][2][11]),
    .io_dataOut_5_2_12                  (dm_data_out[5][2][12]),
    .io_dataOut_5_2_13                  (dm_data_out[5][2][13]),
    .io_dataOut_5_2_14                  (dm_data_out[5][2][14]),
    .io_dataOut_5_2_15                  (dm_data_out[5][2][15]),
    .io_dataOut_5_3_0                   (dm_data_out[5][3][0]),
    .io_dataOut_5_3_1                   (dm_data_out[5][3][1]),
    .io_dataOut_5_3_2                   (dm_data_out[5][3][2]),
    .io_dataOut_5_3_3                   (dm_data_out[5][3][3]),
    .io_dataOut_5_3_4                   (dm_data_out[5][3][4]),
    .io_dataOut_5_3_5                   (dm_data_out[5][3][5]),
    .io_dataOut_5_3_6                   (dm_data_out[5][3][6]),
    .io_dataOut_5_3_7                   (dm_data_out[5][3][7]),
    .io_dataOut_5_3_8                   (dm_data_out[5][3][8]),
    .io_dataOut_5_3_9                   (dm_data_out[5][3][9]),
    .io_dataOut_5_3_10                  (dm_data_out[5][3][10]),
    .io_dataOut_5_3_11                  (dm_data_out[5][3][11]),
    .io_dataOut_5_3_12                  (dm_data_out[5][3][12]),
    .io_dataOut_5_3_13                  (dm_data_out[5][3][13]),
    .io_dataOut_5_3_14                  (dm_data_out[5][3][14]),
    .io_dataOut_5_3_15                  (dm_data_out[5][3][15]),
    .io_dataOut_6_0_0                   (dm_data_out[6][0][0]),
    .io_dataOut_6_0_1                   (dm_data_out[6][0][1]),
    .io_dataOut_6_0_2                   (dm_data_out[6][0][2]),
    .io_dataOut_6_0_3                   (dm_data_out[6][0][3]),
    .io_dataOut_6_0_4                   (dm_data_out[6][0][4]),
    .io_dataOut_6_0_5                   (dm_data_out[6][0][5]),
    .io_dataOut_6_0_6                   (dm_data_out[6][0][6]),
    .io_dataOut_6_0_7                   (dm_data_out[6][0][7]),
    .io_dataOut_6_0_8                   (dm_data_out[6][0][8]),
    .io_dataOut_6_0_9                   (dm_data_out[6][0][9]),
    .io_dataOut_6_0_10                  (dm_data_out[6][0][10]),
    .io_dataOut_6_0_11                  (dm_data_out[6][0][11]),
    .io_dataOut_6_0_12                  (dm_data_out[6][0][12]),
    .io_dataOut_6_0_13                  (dm_data_out[6][0][13]),
    .io_dataOut_6_0_14                  (dm_data_out[6][0][14]),
    .io_dataOut_6_0_15                  (dm_data_out[6][0][15]),
    .io_dataOut_6_1_0                   (dm_data_out[6][1][0]),
    .io_dataOut_6_1_1                   (dm_data_out[6][1][1]),
    .io_dataOut_6_1_2                   (dm_data_out[6][1][2]),
    .io_dataOut_6_1_3                   (dm_data_out[6][1][3]),
    .io_dataOut_6_1_4                   (dm_data_out[6][1][4]),
    .io_dataOut_6_1_5                   (dm_data_out[6][1][5]),
    .io_dataOut_6_1_6                   (dm_data_out[6][1][6]),
    .io_dataOut_6_1_7                   (dm_data_out[6][1][7]),
    .io_dataOut_6_1_8                   (dm_data_out[6][1][8]),
    .io_dataOut_6_1_9                   (dm_data_out[6][1][9]),
    .io_dataOut_6_1_10                  (dm_data_out[6][1][10]),
    .io_dataOut_6_1_11                  (dm_data_out[6][1][11]),
    .io_dataOut_6_1_12                  (dm_data_out[6][1][12]),
    .io_dataOut_6_1_13                  (dm_data_out[6][1][13]),
    .io_dataOut_6_1_14                  (dm_data_out[6][1][14]),
    .io_dataOut_6_1_15                  (dm_data_out[6][1][15]),
    .io_dataOut_6_2_0                   (dm_data_out[6][2][0]),
    .io_dataOut_6_2_1                   (dm_data_out[6][2][1]),
    .io_dataOut_6_2_2                   (dm_data_out[6][2][2]),
    .io_dataOut_6_2_3                   (dm_data_out[6][2][3]),
    .io_dataOut_6_2_4                   (dm_data_out[6][2][4]),
    .io_dataOut_6_2_5                   (dm_data_out[6][2][5]),
    .io_dataOut_6_2_6                   (dm_data_out[6][2][6]),
    .io_dataOut_6_2_7                   (dm_data_out[6][2][7]),
    .io_dataOut_6_2_8                   (dm_data_out[6][2][8]),
    .io_dataOut_6_2_9                   (dm_data_out[6][2][9]),
    .io_dataOut_6_2_10                  (dm_data_out[6][2][10]),
    .io_dataOut_6_2_11                  (dm_data_out[6][2][11]),
    .io_dataOut_6_2_12                  (dm_data_out[6][2][12]),
    .io_dataOut_6_2_13                  (dm_data_out[6][2][13]),
    .io_dataOut_6_2_14                  (dm_data_out[6][2][14]),
    .io_dataOut_6_2_15                  (dm_data_out[6][2][15]),
    .io_dataOut_6_3_0                   (dm_data_out[6][3][0]),
    .io_dataOut_6_3_1                   (dm_data_out[6][3][1]),
    .io_dataOut_6_3_2                   (dm_data_out[6][3][2]),
    .io_dataOut_6_3_3                   (dm_data_out[6][3][3]),
    .io_dataOut_6_3_4                   (dm_data_out[6][3][4]),
    .io_dataOut_6_3_5                   (dm_data_out[6][3][5]),
    .io_dataOut_6_3_6                   (dm_data_out[6][3][6]),
    .io_dataOut_6_3_7                   (dm_data_out[6][3][7]),
    .io_dataOut_6_3_8                   (dm_data_out[6][3][8]),
    .io_dataOut_6_3_9                   (dm_data_out[6][3][9]),
    .io_dataOut_6_3_10                  (dm_data_out[6][3][10]),
    .io_dataOut_6_3_11                  (dm_data_out[6][3][11]),
    .io_dataOut_6_3_12                  (dm_data_out[6][3][12]),
    .io_dataOut_6_3_13                  (dm_data_out[6][3][13]),
    .io_dataOut_6_3_14                  (dm_data_out[6][3][14]),
    .io_dataOut_6_3_15                  (dm_data_out[6][3][15]),
    .io_dataOut_7_0_0                   (dm_data_out[7][0][0]),
    .io_dataOut_7_0_1                   (dm_data_out[7][0][1]),
    .io_dataOut_7_0_2                   (dm_data_out[7][0][2]),
    .io_dataOut_7_0_3                   (dm_data_out[7][0][3]),
    .io_dataOut_7_0_4                   (dm_data_out[7][0][4]),
    .io_dataOut_7_0_5                   (dm_data_out[7][0][5]),
    .io_dataOut_7_0_6                   (dm_data_out[7][0][6]),
    .io_dataOut_7_0_7                   (dm_data_out[7][0][7]),
    .io_dataOut_7_0_8                   (dm_data_out[7][0][8]),
    .io_dataOut_7_0_9                   (dm_data_out[7][0][9]),
    .io_dataOut_7_0_10                  (dm_data_out[7][0][10]),
    .io_dataOut_7_0_11                  (dm_data_out[7][0][11]),
    .io_dataOut_7_0_12                  (dm_data_out[7][0][12]),
    .io_dataOut_7_0_13                  (dm_data_out[7][0][13]),
    .io_dataOut_7_0_14                  (dm_data_out[7][0][14]),
    .io_dataOut_7_0_15                  (dm_data_out[7][0][15]),
    .io_dataOut_7_1_0                   (dm_data_out[7][1][0]),
    .io_dataOut_7_1_1                   (dm_data_out[7][1][1]),
    .io_dataOut_7_1_2                   (dm_data_out[7][1][2]),
    .io_dataOut_7_1_3                   (dm_data_out[7][1][3]),
    .io_dataOut_7_1_4                   (dm_data_out[7][1][4]),
    .io_dataOut_7_1_5                   (dm_data_out[7][1][5]),
    .io_dataOut_7_1_6                   (dm_data_out[7][1][6]),
    .io_dataOut_7_1_7                   (dm_data_out[7][1][7]),
    .io_dataOut_7_1_8                   (dm_data_out[7][1][8]),
    .io_dataOut_7_1_9                   (dm_data_out[7][1][9]),
    .io_dataOut_7_1_10                  (dm_data_out[7][1][10]),
    .io_dataOut_7_1_11                  (dm_data_out[7][1][11]),
    .io_dataOut_7_1_12                  (dm_data_out[7][1][12]),
    .io_dataOut_7_1_13                  (dm_data_out[7][1][13]),
    .io_dataOut_7_1_14                  (dm_data_out[7][1][14]),
    .io_dataOut_7_1_15                  (dm_data_out[7][1][15]),
    .io_dataOut_7_2_0                   (dm_data_out[7][2][0]),
    .io_dataOut_7_2_1                   (dm_data_out[7][2][1]),
    .io_dataOut_7_2_2                   (dm_data_out[7][2][2]),
    .io_dataOut_7_2_3                   (dm_data_out[7][2][3]),
    .io_dataOut_7_2_4                   (dm_data_out[7][2][4]),
    .io_dataOut_7_2_5                   (dm_data_out[7][2][5]),
    .io_dataOut_7_2_6                   (dm_data_out[7][2][6]),
    .io_dataOut_7_2_7                   (dm_data_out[7][2][7]),
    .io_dataOut_7_2_8                   (dm_data_out[7][2][8]),
    .io_dataOut_7_2_9                   (dm_data_out[7][2][9]),
    .io_dataOut_7_2_10                  (dm_data_out[7][2][10]),
    .io_dataOut_7_2_11                  (dm_data_out[7][2][11]),
    .io_dataOut_7_2_12                  (dm_data_out[7][2][12]),
    .io_dataOut_7_2_13                  (dm_data_out[7][2][13]),
    .io_dataOut_7_2_14                  (dm_data_out[7][2][14]),
    .io_dataOut_7_2_15                  (dm_data_out[7][2][15]),
    .io_dataOut_7_3_0                   (dm_data_out[7][3][0]),
    .io_dataOut_7_3_1                   (dm_data_out[7][3][1]),
    .io_dataOut_7_3_2                   (dm_data_out[7][3][2]),
    .io_dataOut_7_3_3                   (dm_data_out[7][3][3]),
    .io_dataOut_7_3_4                   (dm_data_out[7][3][4]),
    .io_dataOut_7_3_5                   (dm_data_out[7][3][5]),
    .io_dataOut_7_3_6                   (dm_data_out[7][3][6]),
    .io_dataOut_7_3_7                   (dm_data_out[7][3][7]),
    .io_dataOut_7_3_8                   (dm_data_out[7][3][8]),
    .io_dataOut_7_3_9                   (dm_data_out[7][3][9]),
    .io_dataOut_7_3_10                  (dm_data_out[7][3][10]),
    .io_dataOut_7_3_11                  (dm_data_out[7][3][11]),
    .io_dataOut_7_3_12                  (dm_data_out[7][3][12]),
    .io_dataOut_7_3_13                  (dm_data_out[7][3][13]),
    .io_dataOut_7_3_14                  (dm_data_out[7][3][14]),
    .io_dataOut_7_3_15                  (dm_data_out[7][3][15]),
    .io_dataOut_8_0_0                   (dm_data_out[8][0][0]),
    .io_dataOut_8_0_1                   (dm_data_out[8][0][1]),
    .io_dataOut_8_0_2                   (dm_data_out[8][0][2]),
    .io_dataOut_8_0_3                   (dm_data_out[8][0][3]),
    .io_dataOut_8_0_4                   (dm_data_out[8][0][4]),
    .io_dataOut_8_0_5                   (dm_data_out[8][0][5]),
    .io_dataOut_8_0_6                   (dm_data_out[8][0][6]),
    .io_dataOut_8_0_7                   (dm_data_out[8][0][7]),
    .io_dataOut_8_0_8                   (dm_data_out[8][0][8]),
    .io_dataOut_8_0_9                   (dm_data_out[8][0][9]),
    .io_dataOut_8_0_10                  (dm_data_out[8][0][10]),
    .io_dataOut_8_0_11                  (dm_data_out[8][0][11]),
    .io_dataOut_8_0_12                  (dm_data_out[8][0][12]),
    .io_dataOut_8_0_13                  (dm_data_out[8][0][13]),
    .io_dataOut_8_0_14                  (dm_data_out[8][0][14]),
    .io_dataOut_8_0_15                  (dm_data_out[8][0][15]),
    .io_dataOut_8_1_0                   (dm_data_out[8][1][0]),
    .io_dataOut_8_1_1                   (dm_data_out[8][1][1]),
    .io_dataOut_8_1_2                   (dm_data_out[8][1][2]),
    .io_dataOut_8_1_3                   (dm_data_out[8][1][3]),
    .io_dataOut_8_1_4                   (dm_data_out[8][1][4]),
    .io_dataOut_8_1_5                   (dm_data_out[8][1][5]),
    .io_dataOut_8_1_6                   (dm_data_out[8][1][6]),
    .io_dataOut_8_1_7                   (dm_data_out[8][1][7]),
    .io_dataOut_8_1_8                   (dm_data_out[8][1][8]),
    .io_dataOut_8_1_9                   (dm_data_out[8][1][9]),
    .io_dataOut_8_1_10                  (dm_data_out[8][1][10]),
    .io_dataOut_8_1_11                  (dm_data_out[8][1][11]),
    .io_dataOut_8_1_12                  (dm_data_out[8][1][12]),
    .io_dataOut_8_1_13                  (dm_data_out[8][1][13]),
    .io_dataOut_8_1_14                  (dm_data_out[8][1][14]),
    .io_dataOut_8_1_15                  (dm_data_out[8][1][15]),
    .io_dataOut_8_2_0                   (dm_data_out[8][2][0]),
    .io_dataOut_8_2_1                   (dm_data_out[8][2][1]),
    .io_dataOut_8_2_2                   (dm_data_out[8][2][2]),
    .io_dataOut_8_2_3                   (dm_data_out[8][2][3]),
    .io_dataOut_8_2_4                   (dm_data_out[8][2][4]),
    .io_dataOut_8_2_5                   (dm_data_out[8][2][5]),
    .io_dataOut_8_2_6                   (dm_data_out[8][2][6]),
    .io_dataOut_8_2_7                   (dm_data_out[8][2][7]),
    .io_dataOut_8_2_8                   (dm_data_out[8][2][8]),
    .io_dataOut_8_2_9                   (dm_data_out[8][2][9]),
    .io_dataOut_8_2_10                  (dm_data_out[8][2][10]),
    .io_dataOut_8_2_11                  (dm_data_out[8][2][11]),
    .io_dataOut_8_2_12                  (dm_data_out[8][2][12]),
    .io_dataOut_8_2_13                  (dm_data_out[8][2][13]),
    .io_dataOut_8_2_14                  (dm_data_out[8][2][14]),
    .io_dataOut_8_2_15                  (dm_data_out[8][2][15]),
    .io_dataOut_8_3_0                   (dm_data_out[8][3][0]),
    .io_dataOut_8_3_1                   (dm_data_out[8][3][1]),
    .io_dataOut_8_3_2                   (dm_data_out[8][3][2]),
    .io_dataOut_8_3_3                   (dm_data_out[8][3][3]),
    .io_dataOut_8_3_4                   (dm_data_out[8][3][4]),
    .io_dataOut_8_3_5                   (dm_data_out[8][3][5]),
    .io_dataOut_8_3_6                   (dm_data_out[8][3][6]),
    .io_dataOut_8_3_7                   (dm_data_out[8][3][7]),
    .io_dataOut_8_3_8                   (dm_data_out[8][3][8]),
    .io_dataOut_8_3_9                   (dm_data_out[8][3][9]),
    .io_dataOut_8_3_10                  (dm_data_out[8][3][10]),
    .io_dataOut_8_3_11                  (dm_data_out[8][3][11]),
    .io_dataOut_8_3_12                  (dm_data_out[8][3][12]),
    .io_dataOut_8_3_13                  (dm_data_out[8][3][13]),
    .io_dataOut_8_3_14                  (dm_data_out[8][3][14]),
    .io_dataOut_8_3_15                  (dm_data_out[8][3][15]),
    .io_dataOut_9_0_0                   (dm_data_out[9][0][0]),
    .io_dataOut_9_0_1                   (dm_data_out[9][0][1]),
    .io_dataOut_9_0_2                   (dm_data_out[9][0][2]),
    .io_dataOut_9_0_3                   (dm_data_out[9][0][3]),
    .io_dataOut_9_0_4                   (dm_data_out[9][0][4]),
    .io_dataOut_9_0_5                   (dm_data_out[9][0][5]),
    .io_dataOut_9_0_6                   (dm_data_out[9][0][6]),
    .io_dataOut_9_0_7                   (dm_data_out[9][0][7]),
    .io_dataOut_9_0_8                   (dm_data_out[9][0][8]),
    .io_dataOut_9_0_9                   (dm_data_out[9][0][9]),
    .io_dataOut_9_0_10                  (dm_data_out[9][0][10]),
    .io_dataOut_9_0_11                  (dm_data_out[9][0][11]),
    .io_dataOut_9_0_12                  (dm_data_out[9][0][12]),
    .io_dataOut_9_0_13                  (dm_data_out[9][0][13]),
    .io_dataOut_9_0_14                  (dm_data_out[9][0][14]),
    .io_dataOut_9_0_15                  (dm_data_out[9][0][15]),
    .io_dataOut_9_1_0                   (dm_data_out[9][1][0]),
    .io_dataOut_9_1_1                   (dm_data_out[9][1][1]),
    .io_dataOut_9_1_2                   (dm_data_out[9][1][2]),
    .io_dataOut_9_1_3                   (dm_data_out[9][1][3]),
    .io_dataOut_9_1_4                   (dm_data_out[9][1][4]),
    .io_dataOut_9_1_5                   (dm_data_out[9][1][5]),
    .io_dataOut_9_1_6                   (dm_data_out[9][1][6]),
    .io_dataOut_9_1_7                   (dm_data_out[9][1][7]),
    .io_dataOut_9_1_8                   (dm_data_out[9][1][8]),
    .io_dataOut_9_1_9                   (dm_data_out[9][1][9]),
    .io_dataOut_9_1_10                  (dm_data_out[9][1][10]),
    .io_dataOut_9_1_11                  (dm_data_out[9][1][11]),
    .io_dataOut_9_1_12                  (dm_data_out[9][1][12]),
    .io_dataOut_9_1_13                  (dm_data_out[9][1][13]),
    .io_dataOut_9_1_14                  (dm_data_out[9][1][14]),
    .io_dataOut_9_1_15                  (dm_data_out[9][1][15]),
    .io_dataOut_9_2_0                   (dm_data_out[9][2][0]),
    .io_dataOut_9_2_1                   (dm_data_out[9][2][1]),
    .io_dataOut_9_2_2                   (dm_data_out[9][2][2]),
    .io_dataOut_9_2_3                   (dm_data_out[9][2][3]),
    .io_dataOut_9_2_4                   (dm_data_out[9][2][4]),
    .io_dataOut_9_2_5                   (dm_data_out[9][2][5]),
    .io_dataOut_9_2_6                   (dm_data_out[9][2][6]),
    .io_dataOut_9_2_7                   (dm_data_out[9][2][7]),
    .io_dataOut_9_2_8                   (dm_data_out[9][2][8]),
    .io_dataOut_9_2_9                   (dm_data_out[9][2][9]),
    .io_dataOut_9_2_10                  (dm_data_out[9][2][10]),
    .io_dataOut_9_2_11                  (dm_data_out[9][2][11]),
    .io_dataOut_9_2_12                  (dm_data_out[9][2][12]),
    .io_dataOut_9_2_13                  (dm_data_out[9][2][13]),
    .io_dataOut_9_2_14                  (dm_data_out[9][2][14]),
    .io_dataOut_9_2_15                  (dm_data_out[9][2][15]),
    .io_dataOut_9_3_0                   (dm_data_out[9][3][0]),
    .io_dataOut_9_3_1                   (dm_data_out[9][3][1]),
    .io_dataOut_9_3_2                   (dm_data_out[9][3][2]),
    .io_dataOut_9_3_3                   (dm_data_out[9][3][3]),
    .io_dataOut_9_3_4                   (dm_data_out[9][3][4]),
    .io_dataOut_9_3_5                   (dm_data_out[9][3][5]),
    .io_dataOut_9_3_6                   (dm_data_out[9][3][6]),
    .io_dataOut_9_3_7                   (dm_data_out[9][3][7]),
    .io_dataOut_9_3_8                   (dm_data_out[9][3][8]),
    .io_dataOut_9_3_9                   (dm_data_out[9][3][9]),
    .io_dataOut_9_3_10                  (dm_data_out[9][3][10]),
    .io_dataOut_9_3_11                  (dm_data_out[9][3][11]),
    .io_dataOut_9_3_12                  (dm_data_out[9][3][12]),
    .io_dataOut_9_3_13                  (dm_data_out[9][3][13]),
    .io_dataOut_9_3_14                  (dm_data_out[9][3][14]),
    .io_dataOut_9_3_15                  (dm_data_out[9][3][15]),
    .io_dataOut_10_0_0                  (dm_data_out[10][0][0]),
    .io_dataOut_10_0_1                  (dm_data_out[10][0][1]),
    .io_dataOut_10_0_2                  (dm_data_out[10][0][2]),
    .io_dataOut_10_0_3                  (dm_data_out[10][0][3]),
    .io_dataOut_10_0_4                  (dm_data_out[10][0][4]),
    .io_dataOut_10_0_5                  (dm_data_out[10][0][5]),
    .io_dataOut_10_0_6                  (dm_data_out[10][0][6]),
    .io_dataOut_10_0_7                  (dm_data_out[10][0][7]),
    .io_dataOut_10_0_8                  (dm_data_out[10][0][8]),
    .io_dataOut_10_0_9                  (dm_data_out[10][0][9]),
    .io_dataOut_10_0_10                 (dm_data_out[10][0][10]),
    .io_dataOut_10_0_11                 (dm_data_out[10][0][11]),
    .io_dataOut_10_0_12                 (dm_data_out[10][0][12]),
    .io_dataOut_10_0_13                 (dm_data_out[10][0][13]),
    .io_dataOut_10_0_14                 (dm_data_out[10][0][14]),
    .io_dataOut_10_0_15                 (dm_data_out[10][0][15]),
    .io_dataOut_10_1_0                  (dm_data_out[10][1][0]),
    .io_dataOut_10_1_1                  (dm_data_out[10][1][1]),
    .io_dataOut_10_1_2                  (dm_data_out[10][1][2]),
    .io_dataOut_10_1_3                  (dm_data_out[10][1][3]),
    .io_dataOut_10_1_4                  (dm_data_out[10][1][4]),
    .io_dataOut_10_1_5                  (dm_data_out[10][1][5]),
    .io_dataOut_10_1_6                  (dm_data_out[10][1][6]),
    .io_dataOut_10_1_7                  (dm_data_out[10][1][7]),
    .io_dataOut_10_1_8                  (dm_data_out[10][1][8]),
    .io_dataOut_10_1_9                  (dm_data_out[10][1][9]),
    .io_dataOut_10_1_10                 (dm_data_out[10][1][10]),
    .io_dataOut_10_1_11                 (dm_data_out[10][1][11]),
    .io_dataOut_10_1_12                 (dm_data_out[10][1][12]),
    .io_dataOut_10_1_13                 (dm_data_out[10][1][13]),
    .io_dataOut_10_1_14                 (dm_data_out[10][1][14]),
    .io_dataOut_10_1_15                 (dm_data_out[10][1][15]),
    .io_dataOut_10_2_0                  (dm_data_out[10][2][0]),
    .io_dataOut_10_2_1                  (dm_data_out[10][2][1]),
    .io_dataOut_10_2_2                  (dm_data_out[10][2][2]),
    .io_dataOut_10_2_3                  (dm_data_out[10][2][3]),
    .io_dataOut_10_2_4                  (dm_data_out[10][2][4]),
    .io_dataOut_10_2_5                  (dm_data_out[10][2][5]),
    .io_dataOut_10_2_6                  (dm_data_out[10][2][6]),
    .io_dataOut_10_2_7                  (dm_data_out[10][2][7]),
    .io_dataOut_10_2_8                  (dm_data_out[10][2][8]),
    .io_dataOut_10_2_9                  (dm_data_out[10][2][9]),
    .io_dataOut_10_2_10                 (dm_data_out[10][2][10]),
    .io_dataOut_10_2_11                 (dm_data_out[10][2][11]),
    .io_dataOut_10_2_12                 (dm_data_out[10][2][12]),
    .io_dataOut_10_2_13                 (dm_data_out[10][2][13]),
    .io_dataOut_10_2_14                 (dm_data_out[10][2][14]),
    .io_dataOut_10_2_15                 (dm_data_out[10][2][15]),
    .io_dataOut_10_3_0                  (dm_data_out[10][3][0]),
    .io_dataOut_10_3_1                  (dm_data_out[10][3][1]),
    .io_dataOut_10_3_2                  (dm_data_out[10][3][2]),
    .io_dataOut_10_3_3                  (dm_data_out[10][3][3]),
    .io_dataOut_10_3_4                  (dm_data_out[10][3][4]),
    .io_dataOut_10_3_5                  (dm_data_out[10][3][5]),
    .io_dataOut_10_3_6                  (dm_data_out[10][3][6]),
    .io_dataOut_10_3_7                  (dm_data_out[10][3][7]),
    .io_dataOut_10_3_8                  (dm_data_out[10][3][8]),
    .io_dataOut_10_3_9                  (dm_data_out[10][3][9]),
    .io_dataOut_10_3_10                 (dm_data_out[10][3][10]),
    .io_dataOut_10_3_11                 (dm_data_out[10][3][11]),
    .io_dataOut_10_3_12                 (dm_data_out[10][3][12]),
    .io_dataOut_10_3_13                 (dm_data_out[10][3][13]),
    .io_dataOut_10_3_14                 (dm_data_out[10][3][14]),
    .io_dataOut_10_3_15                 (dm_data_out[10][3][15]),
    .io_dataOut_11_0_0                  (dm_data_out[11][0][0]),
    .io_dataOut_11_0_1                  (dm_data_out[11][0][1]),
    .io_dataOut_11_0_2                  (dm_data_out[11][0][2]),
    .io_dataOut_11_0_3                  (dm_data_out[11][0][3]),
    .io_dataOut_11_0_4                  (dm_data_out[11][0][4]),
    .io_dataOut_11_0_5                  (dm_data_out[11][0][5]),
    .io_dataOut_11_0_6                  (dm_data_out[11][0][6]),
    .io_dataOut_11_0_7                  (dm_data_out[11][0][7]),
    .io_dataOut_11_0_8                  (dm_data_out[11][0][8]),
    .io_dataOut_11_0_9                  (dm_data_out[11][0][9]),
    .io_dataOut_11_0_10                 (dm_data_out[11][0][10]),
    .io_dataOut_11_0_11                 (dm_data_out[11][0][11]),
    .io_dataOut_11_0_12                 (dm_data_out[11][0][12]),
    .io_dataOut_11_0_13                 (dm_data_out[11][0][13]),
    .io_dataOut_11_0_14                 (dm_data_out[11][0][14]),
    .io_dataOut_11_0_15                 (dm_data_out[11][0][15]),
    .io_dataOut_11_1_0                  (dm_data_out[11][1][0]),
    .io_dataOut_11_1_1                  (dm_data_out[11][1][1]),
    .io_dataOut_11_1_2                  (dm_data_out[11][1][2]),
    .io_dataOut_11_1_3                  (dm_data_out[11][1][3]),
    .io_dataOut_11_1_4                  (dm_data_out[11][1][4]),
    .io_dataOut_11_1_5                  (dm_data_out[11][1][5]),
    .io_dataOut_11_1_6                  (dm_data_out[11][1][6]),
    .io_dataOut_11_1_7                  (dm_data_out[11][1][7]),
    .io_dataOut_11_1_8                  (dm_data_out[11][1][8]),
    .io_dataOut_11_1_9                  (dm_data_out[11][1][9]),
    .io_dataOut_11_1_10                 (dm_data_out[11][1][10]),
    .io_dataOut_11_1_11                 (dm_data_out[11][1][11]),
    .io_dataOut_11_1_12                 (dm_data_out[11][1][12]),
    .io_dataOut_11_1_13                 (dm_data_out[11][1][13]),
    .io_dataOut_11_1_14                 (dm_data_out[11][1][14]),
    .io_dataOut_11_1_15                 (dm_data_out[11][1][15]),
    .io_dataOut_11_2_0                  (dm_data_out[11][2][0]),
    .io_dataOut_11_2_1                  (dm_data_out[11][2][1]),
    .io_dataOut_11_2_2                  (dm_data_out[11][2][2]),
    .io_dataOut_11_2_3                  (dm_data_out[11][2][3]),
    .io_dataOut_11_2_4                  (dm_data_out[11][2][4]),
    .io_dataOut_11_2_5                  (dm_data_out[11][2][5]),
    .io_dataOut_11_2_6                  (dm_data_out[11][2][6]),
    .io_dataOut_11_2_7                  (dm_data_out[11][2][7]),
    .io_dataOut_11_2_8                  (dm_data_out[11][2][8]),
    .io_dataOut_11_2_9                  (dm_data_out[11][2][9]),
    .io_dataOut_11_2_10                 (dm_data_out[11][2][10]),
    .io_dataOut_11_2_11                 (dm_data_out[11][2][11]),
    .io_dataOut_11_2_12                 (dm_data_out[11][2][12]),
    .io_dataOut_11_2_13                 (dm_data_out[11][2][13]),
    .io_dataOut_11_2_14                 (dm_data_out[11][2][14]),
    .io_dataOut_11_2_15                 (dm_data_out[11][2][15]),
    .io_dataOut_11_3_0                  (dm_data_out[11][3][0]),
    .io_dataOut_11_3_1                  (dm_data_out[11][3][1]),
    .io_dataOut_11_3_2                  (dm_data_out[11][3][2]),
    .io_dataOut_11_3_3                  (dm_data_out[11][3][3]),
    .io_dataOut_11_3_4                  (dm_data_out[11][3][4]),
    .io_dataOut_11_3_5                  (dm_data_out[11][3][5]),
    .io_dataOut_11_3_6                  (dm_data_out[11][3][6]),
    .io_dataOut_11_3_7                  (dm_data_out[11][3][7]),
    .io_dataOut_11_3_8                  (dm_data_out[11][3][8]),
    .io_dataOut_11_3_9                  (dm_data_out[11][3][9]),
    .io_dataOut_11_3_10                 (dm_data_out[11][3][10]),
    .io_dataOut_11_3_11                 (dm_data_out[11][3][11]),
    .io_dataOut_11_3_12                 (dm_data_out[11][3][12]),
    .io_dataOut_11_3_13                 (dm_data_out[11][3][13]),
    .io_dataOut_11_3_14                 (dm_data_out[11][3][14]),
    .io_dataOut_11_3_15                 (dm_data_out[11][3][15]),
    .io_dataOut_12_0_0                  (dm_data_out[12][0][0]),
    .io_dataOut_12_0_1                  (dm_data_out[12][0][1]),
    .io_dataOut_12_0_2                  (dm_data_out[12][0][2]),
    .io_dataOut_12_0_3                  (dm_data_out[12][0][3]),
    .io_dataOut_12_0_4                  (dm_data_out[12][0][4]),
    .io_dataOut_12_0_5                  (dm_data_out[12][0][5]),
    .io_dataOut_12_0_6                  (dm_data_out[12][0][6]),
    .io_dataOut_12_0_7                  (dm_data_out[12][0][7]),
    .io_dataOut_12_0_8                  (dm_data_out[12][0][8]),
    .io_dataOut_12_0_9                  (dm_data_out[12][0][9]),
    .io_dataOut_12_0_10                 (dm_data_out[12][0][10]),
    .io_dataOut_12_0_11                 (dm_data_out[12][0][11]),
    .io_dataOut_12_0_12                 (dm_data_out[12][0][12]),
    .io_dataOut_12_0_13                 (dm_data_out[12][0][13]),
    .io_dataOut_12_0_14                 (dm_data_out[12][0][14]),
    .io_dataOut_12_0_15                 (dm_data_out[12][0][15]),
    .io_dataOut_12_1_0                  (dm_data_out[12][1][0]),
    .io_dataOut_12_1_1                  (dm_data_out[12][1][1]),
    .io_dataOut_12_1_2                  (dm_data_out[12][1][2]),
    .io_dataOut_12_1_3                  (dm_data_out[12][1][3]),
    .io_dataOut_12_1_4                  (dm_data_out[12][1][4]),
    .io_dataOut_12_1_5                  (dm_data_out[12][1][5]),
    .io_dataOut_12_1_6                  (dm_data_out[12][1][6]),
    .io_dataOut_12_1_7                  (dm_data_out[12][1][7]),
    .io_dataOut_12_1_8                  (dm_data_out[12][1][8]),
    .io_dataOut_12_1_9                  (dm_data_out[12][1][9]),
    .io_dataOut_12_1_10                 (dm_data_out[12][1][10]),
    .io_dataOut_12_1_11                 (dm_data_out[12][1][11]),
    .io_dataOut_12_1_12                 (dm_data_out[12][1][12]),
    .io_dataOut_12_1_13                 (dm_data_out[12][1][13]),
    .io_dataOut_12_1_14                 (dm_data_out[12][1][14]),
    .io_dataOut_12_1_15                 (dm_data_out[12][1][15]),
    .io_dataOut_12_2_0                  (dm_data_out[12][2][0]),
    .io_dataOut_12_2_1                  (dm_data_out[12][2][1]),
    .io_dataOut_12_2_2                  (dm_data_out[12][2][2]),
    .io_dataOut_12_2_3                  (dm_data_out[12][2][3]),
    .io_dataOut_12_2_4                  (dm_data_out[12][2][4]),
    .io_dataOut_12_2_5                  (dm_data_out[12][2][5]),
    .io_dataOut_12_2_6                  (dm_data_out[12][2][6]),
    .io_dataOut_12_2_7                  (dm_data_out[12][2][7]),
    .io_dataOut_12_2_8                  (dm_data_out[12][2][8]),
    .io_dataOut_12_2_9                  (dm_data_out[12][2][9]),
    .io_dataOut_12_2_10                 (dm_data_out[12][2][10]),
    .io_dataOut_12_2_11                 (dm_data_out[12][2][11]),
    .io_dataOut_12_2_12                 (dm_data_out[12][2][12]),
    .io_dataOut_12_2_13                 (dm_data_out[12][2][13]),
    .io_dataOut_12_2_14                 (dm_data_out[12][2][14]),
    .io_dataOut_12_2_15                 (dm_data_out[12][2][15]),
    .io_dataOut_12_3_0                  (dm_data_out[12][3][0]),
    .io_dataOut_12_3_1                  (dm_data_out[12][3][1]),
    .io_dataOut_12_3_2                  (dm_data_out[12][3][2]),
    .io_dataOut_12_3_3                  (dm_data_out[12][3][3]),
    .io_dataOut_12_3_4                  (dm_data_out[12][3][4]),
    .io_dataOut_12_3_5                  (dm_data_out[12][3][5]),
    .io_dataOut_12_3_6                  (dm_data_out[12][3][6]),
    .io_dataOut_12_3_7                  (dm_data_out[12][3][7]),
    .io_dataOut_12_3_8                  (dm_data_out[12][3][8]),
    .io_dataOut_12_3_9                  (dm_data_out[12][3][9]),
    .io_dataOut_12_3_10                 (dm_data_out[12][3][10]),
    .io_dataOut_12_3_11                 (dm_data_out[12][3][11]),
    .io_dataOut_12_3_12                 (dm_data_out[12][3][12]),
    .io_dataOut_12_3_13                 (dm_data_out[12][3][13]),
    .io_dataOut_12_3_14                 (dm_data_out[12][3][14]),
    .io_dataOut_12_3_15                 (dm_data_out[12][3][15]),
    .io_dataOut_13_0_0                  (dm_data_out[13][0][0]),
    .io_dataOut_13_0_1                  (dm_data_out[13][0][1]),
    .io_dataOut_13_0_2                  (dm_data_out[13][0][2]),
    .io_dataOut_13_0_3                  (dm_data_out[13][0][3]),
    .io_dataOut_13_0_4                  (dm_data_out[13][0][4]),
    .io_dataOut_13_0_5                  (dm_data_out[13][0][5]),
    .io_dataOut_13_0_6                  (dm_data_out[13][0][6]),
    .io_dataOut_13_0_7                  (dm_data_out[13][0][7]),
    .io_dataOut_13_0_8                  (dm_data_out[13][0][8]),
    .io_dataOut_13_0_9                  (dm_data_out[13][0][9]),
    .io_dataOut_13_0_10                 (dm_data_out[13][0][10]),
    .io_dataOut_13_0_11                 (dm_data_out[13][0][11]),
    .io_dataOut_13_0_12                 (dm_data_out[13][0][12]),
    .io_dataOut_13_0_13                 (dm_data_out[13][0][13]),
    .io_dataOut_13_0_14                 (dm_data_out[13][0][14]),
    .io_dataOut_13_0_15                 (dm_data_out[13][0][15]),
    .io_dataOut_13_1_0                  (dm_data_out[13][1][0]),
    .io_dataOut_13_1_1                  (dm_data_out[13][1][1]),
    .io_dataOut_13_1_2                  (dm_data_out[13][1][2]),
    .io_dataOut_13_1_3                  (dm_data_out[13][1][3]),
    .io_dataOut_13_1_4                  (dm_data_out[13][1][4]),
    .io_dataOut_13_1_5                  (dm_data_out[13][1][5]),
    .io_dataOut_13_1_6                  (dm_data_out[13][1][6]),
    .io_dataOut_13_1_7                  (dm_data_out[13][1][7]),
    .io_dataOut_13_1_8                  (dm_data_out[13][1][8]),
    .io_dataOut_13_1_9                  (dm_data_out[13][1][9]),
    .io_dataOut_13_1_10                 (dm_data_out[13][1][10]),
    .io_dataOut_13_1_11                 (dm_data_out[13][1][11]),
    .io_dataOut_13_1_12                 (dm_data_out[13][1][12]),
    .io_dataOut_13_1_13                 (dm_data_out[13][1][13]),
    .io_dataOut_13_1_14                 (dm_data_out[13][1][14]),
    .io_dataOut_13_1_15                 (dm_data_out[13][1][15]),
    .io_dataOut_13_2_0                  (dm_data_out[13][2][0]),
    .io_dataOut_13_2_1                  (dm_data_out[13][2][1]),
    .io_dataOut_13_2_2                  (dm_data_out[13][2][2]),
    .io_dataOut_13_2_3                  (dm_data_out[13][2][3]),
    .io_dataOut_13_2_4                  (dm_data_out[13][2][4]),
    .io_dataOut_13_2_5                  (dm_data_out[13][2][5]),
    .io_dataOut_13_2_6                  (dm_data_out[13][2][6]),
    .io_dataOut_13_2_7                  (dm_data_out[13][2][7]),
    .io_dataOut_13_2_8                  (dm_data_out[13][2][8]),
    .io_dataOut_13_2_9                  (dm_data_out[13][2][9]),
    .io_dataOut_13_2_10                 (dm_data_out[13][2][10]),
    .io_dataOut_13_2_11                 (dm_data_out[13][2][11]),
    .io_dataOut_13_2_12                 (dm_data_out[13][2][12]),
    .io_dataOut_13_2_13                 (dm_data_out[13][2][13]),
    .io_dataOut_13_2_14                 (dm_data_out[13][2][14]),
    .io_dataOut_13_2_15                 (dm_data_out[13][2][15]),
    .io_dataOut_13_3_0                  (dm_data_out[13][3][0]),
    .io_dataOut_13_3_1                  (dm_data_out[13][3][1]),
    .io_dataOut_13_3_2                  (dm_data_out[13][3][2]),
    .io_dataOut_13_3_3                  (dm_data_out[13][3][3]),
    .io_dataOut_13_3_4                  (dm_data_out[13][3][4]),
    .io_dataOut_13_3_5                  (dm_data_out[13][3][5]),
    .io_dataOut_13_3_6                  (dm_data_out[13][3][6]),
    .io_dataOut_13_3_7                  (dm_data_out[13][3][7]),
    .io_dataOut_13_3_8                  (dm_data_out[13][3][8]),
    .io_dataOut_13_3_9                  (dm_data_out[13][3][9]),
    .io_dataOut_13_3_10                 (dm_data_out[13][3][10]),
    .io_dataOut_13_3_11                 (dm_data_out[13][3][11]),
    .io_dataOut_13_3_12                 (dm_data_out[13][3][12]),
    .io_dataOut_13_3_13                 (dm_data_out[13][3][13]),
    .io_dataOut_13_3_14                 (dm_data_out[13][3][14]),
    .io_dataOut_13_3_15                 (dm_data_out[13][3][15]),
    .io_dataOut_14_0_0                  (dm_data_out[14][0][0]),
    .io_dataOut_14_0_1                  (dm_data_out[14][0][1]),
    .io_dataOut_14_0_2                  (dm_data_out[14][0][2]),
    .io_dataOut_14_0_3                  (dm_data_out[14][0][3]),
    .io_dataOut_14_0_4                  (dm_data_out[14][0][4]),
    .io_dataOut_14_0_5                  (dm_data_out[14][0][5]),
    .io_dataOut_14_0_6                  (dm_data_out[14][0][6]),
    .io_dataOut_14_0_7                  (dm_data_out[14][0][7]),
    .io_dataOut_14_0_8                  (dm_data_out[14][0][8]),
    .io_dataOut_14_0_9                  (dm_data_out[14][0][9]),
    .io_dataOut_14_0_10                 (dm_data_out[14][0][10]),
    .io_dataOut_14_0_11                 (dm_data_out[14][0][11]),
    .io_dataOut_14_0_12                 (dm_data_out[14][0][12]),
    .io_dataOut_14_0_13                 (dm_data_out[14][0][13]),
    .io_dataOut_14_0_14                 (dm_data_out[14][0][14]),
    .io_dataOut_14_0_15                 (dm_data_out[14][0][15]),
    .io_dataOut_14_1_0                  (dm_data_out[14][1][0]),
    .io_dataOut_14_1_1                  (dm_data_out[14][1][1]),
    .io_dataOut_14_1_2                  (dm_data_out[14][1][2]),
    .io_dataOut_14_1_3                  (dm_data_out[14][1][3]),
    .io_dataOut_14_1_4                  (dm_data_out[14][1][4]),
    .io_dataOut_14_1_5                  (dm_data_out[14][1][5]),
    .io_dataOut_14_1_6                  (dm_data_out[14][1][6]),
    .io_dataOut_14_1_7                  (dm_data_out[14][1][7]),
    .io_dataOut_14_1_8                  (dm_data_out[14][1][8]),
    .io_dataOut_14_1_9                  (dm_data_out[14][1][9]),
    .io_dataOut_14_1_10                 (dm_data_out[14][1][10]),
    .io_dataOut_14_1_11                 (dm_data_out[14][1][11]),
    .io_dataOut_14_1_12                 (dm_data_out[14][1][12]),
    .io_dataOut_14_1_13                 (dm_data_out[14][1][13]),
    .io_dataOut_14_1_14                 (dm_data_out[14][1][14]),
    .io_dataOut_14_1_15                 (dm_data_out[14][1][15]),
    .io_dataOut_14_2_0                  (dm_data_out[14][2][0]),
    .io_dataOut_14_2_1                  (dm_data_out[14][2][1]),
    .io_dataOut_14_2_2                  (dm_data_out[14][2][2]),
    .io_dataOut_14_2_3                  (dm_data_out[14][2][3]),
    .io_dataOut_14_2_4                  (dm_data_out[14][2][4]),
    .io_dataOut_14_2_5                  (dm_data_out[14][2][5]),
    .io_dataOut_14_2_6                  (dm_data_out[14][2][6]),
    .io_dataOut_14_2_7                  (dm_data_out[14][2][7]),
    .io_dataOut_14_2_8                  (dm_data_out[14][2][8]),
    .io_dataOut_14_2_9                  (dm_data_out[14][2][9]),
    .io_dataOut_14_2_10                 (dm_data_out[14][2][10]),
    .io_dataOut_14_2_11                 (dm_data_out[14][2][11]),
    .io_dataOut_14_2_12                 (dm_data_out[14][2][12]),
    .io_dataOut_14_2_13                 (dm_data_out[14][2][13]),
    .io_dataOut_14_2_14                 (dm_data_out[14][2][14]),
    .io_dataOut_14_2_15                 (dm_data_out[14][2][15]),
    .io_dataOut_14_3_0                  (dm_data_out[14][3][0]),
    .io_dataOut_14_3_1                  (dm_data_out[14][3][1]),
    .io_dataOut_14_3_2                  (dm_data_out[14][3][2]),
    .io_dataOut_14_3_3                  (dm_data_out[14][3][3]),
    .io_dataOut_14_3_4                  (dm_data_out[14][3][4]),
    .io_dataOut_14_3_5                  (dm_data_out[14][3][5]),
    .io_dataOut_14_3_6                  (dm_data_out[14][3][6]),
    .io_dataOut_14_3_7                  (dm_data_out[14][3][7]),
    .io_dataOut_14_3_8                  (dm_data_out[14][3][8]),
    .io_dataOut_14_3_9                  (dm_data_out[14][3][9]),
    .io_dataOut_14_3_10                 (dm_data_out[14][3][10]),
    .io_dataOut_14_3_11                 (dm_data_out[14][3][11]),
    .io_dataOut_14_3_12                 (dm_data_out[14][3][12]),
    .io_dataOut_14_3_13                 (dm_data_out[14][3][13]),
    .io_dataOut_14_3_14                 (dm_data_out[14][3][14]),
    .io_dataOut_14_3_15                 (dm_data_out[14][3][15]),
    .io_dataOut_15_0_0                  (dm_data_out[15][0][0]),
    .io_dataOut_15_0_1                  (dm_data_out[15][0][1]),
    .io_dataOut_15_0_2                  (dm_data_out[15][0][2]),
    .io_dataOut_15_0_3                  (dm_data_out[15][0][3]),
    .io_dataOut_15_0_4                  (dm_data_out[15][0][4]),
    .io_dataOut_15_0_5                  (dm_data_out[15][0][5]),
    .io_dataOut_15_0_6                  (dm_data_out[15][0][6]),
    .io_dataOut_15_0_7                  (dm_data_out[15][0][7]),
    .io_dataOut_15_0_8                  (dm_data_out[15][0][8]),
    .io_dataOut_15_0_9                  (dm_data_out[15][0][9]),
    .io_dataOut_15_0_10                 (dm_data_out[15][0][10]),
    .io_dataOut_15_0_11                 (dm_data_out[15][0][11]),
    .io_dataOut_15_0_12                 (dm_data_out[15][0][12]),
    .io_dataOut_15_0_13                 (dm_data_out[15][0][13]),
    .io_dataOut_15_0_14                 (dm_data_out[15][0][14]),
    .io_dataOut_15_0_15                 (dm_data_out[15][0][15]),
    .io_dataOut_15_1_0                  (dm_data_out[15][1][0]),
    .io_dataOut_15_1_1                  (dm_data_out[15][1][1]),
    .io_dataOut_15_1_2                  (dm_data_out[15][1][2]),
    .io_dataOut_15_1_3                  (dm_data_out[15][1][3]),
    .io_dataOut_15_1_4                  (dm_data_out[15][1][4]),
    .io_dataOut_15_1_5                  (dm_data_out[15][1][5]),
    .io_dataOut_15_1_6                  (dm_data_out[15][1][6]),
    .io_dataOut_15_1_7                  (dm_data_out[15][1][7]),
    .io_dataOut_15_1_8                  (dm_data_out[15][1][8]),
    .io_dataOut_15_1_9                  (dm_data_out[15][1][9]),
    .io_dataOut_15_1_10                 (dm_data_out[15][1][10]),
    .io_dataOut_15_1_11                 (dm_data_out[15][1][11]),
    .io_dataOut_15_1_12                 (dm_data_out[15][1][12]),
    .io_dataOut_15_1_13                 (dm_data_out[15][1][13]),
    .io_dataOut_15_1_14                 (dm_data_out[15][1][14]),
    .io_dataOut_15_1_15                 (dm_data_out[15][1][15]),
    .io_dataOut_15_2_0                  (dm_data_out[15][2][0]),
    .io_dataOut_15_2_1                  (dm_data_out[15][2][1]),
    .io_dataOut_15_2_2                  (dm_data_out[15][2][2]),
    .io_dataOut_15_2_3                  (dm_data_out[15][2][3]),
    .io_dataOut_15_2_4                  (dm_data_out[15][2][4]),
    .io_dataOut_15_2_5                  (dm_data_out[15][2][5]),
    .io_dataOut_15_2_6                  (dm_data_out[15][2][6]),
    .io_dataOut_15_2_7                  (dm_data_out[15][2][7]),
    .io_dataOut_15_2_8                  (dm_data_out[15][2][8]),
    .io_dataOut_15_2_9                  (dm_data_out[15][2][9]),
    .io_dataOut_15_2_10                 (dm_data_out[15][2][10]),
    .io_dataOut_15_2_11                 (dm_data_out[15][2][11]),
    .io_dataOut_15_2_12                 (dm_data_out[15][2][12]),
    .io_dataOut_15_2_13                 (dm_data_out[15][2][13]),
    .io_dataOut_15_2_14                 (dm_data_out[15][2][14]),
    .io_dataOut_15_2_15                 (dm_data_out[15][2][15]),
    .io_dataOut_15_3_0                  (dm_data_out[15][3][0]),
    .io_dataOut_15_3_1                  (dm_data_out[15][3][1]),
    .io_dataOut_15_3_2                  (dm_data_out[15][3][2]),
    .io_dataOut_15_3_3                  (dm_data_out[15][3][3]),
    .io_dataOut_15_3_4                  (dm_data_out[15][3][4]),
    .io_dataOut_15_3_5                  (dm_data_out[15][3][5]),
    .io_dataOut_15_3_6                  (dm_data_out[15][3][6]),
    .io_dataOut_15_3_7                  (dm_data_out[15][3][7]),
    .io_dataOut_15_3_8                  (dm_data_out[15][3][8]),
    .io_dataOut_15_3_9                  (dm_data_out[15][3][9]),
    .io_dataOut_15_3_10                 (dm_data_out[15][3][10]),
    .io_dataOut_15_3_11                 (dm_data_out[15][3][11]),
    .io_dataOut_15_3_12                 (dm_data_out[15][3][12]),
    .io_dataOut_15_3_13                 (dm_data_out[15][3][13]),
    .io_dataOut_15_3_14                 (dm_data_out[15][3][14]),
    .io_dataOut_15_3_15                 (dm_data_out[15][3][15]),
    .io_maskOut_0_0_0                   (dm_mask_out[0][0][0]),
    .io_maskOut_0_0_1                   (dm_mask_out[0][0][1]),
    .io_maskOut_0_0_2                   (dm_mask_out[0][0][2]),
    .io_maskOut_0_0_3                   (dm_mask_out[0][0][3]),
    .io_maskOut_0_0_4                   (dm_mask_out[0][0][4]),
    .io_maskOut_0_0_5                   (dm_mask_out[0][0][5]),
    .io_maskOut_0_0_6                   (dm_mask_out[0][0][6]),
    .io_maskOut_0_0_7                   (dm_mask_out[0][0][7]),
    .io_maskOut_0_0_8                   (dm_mask_out[0][0][8]),
    .io_maskOut_0_0_9                   (dm_mask_out[0][0][9]),
    .io_maskOut_0_0_10                  (dm_mask_out[0][0][10]),
    .io_maskOut_0_0_11                  (dm_mask_out[0][0][11]),
    .io_maskOut_0_0_12                  (dm_mask_out[0][0][12]),
    .io_maskOut_0_0_13                  (dm_mask_out[0][0][13]),
    .io_maskOut_0_0_14                  (dm_mask_out[0][0][14]),
    .io_maskOut_0_0_15                  (dm_mask_out[0][0][15]),
    .io_maskOut_0_1_0                   (dm_mask_out[0][1][0]),
    .io_maskOut_0_1_1                   (dm_mask_out[0][1][1]),
    .io_maskOut_0_1_2                   (dm_mask_out[0][1][2]),
    .io_maskOut_0_1_3                   (dm_mask_out[0][1][3]),
    .io_maskOut_0_1_4                   (dm_mask_out[0][1][4]),
    .io_maskOut_0_1_5                   (dm_mask_out[0][1][5]),
    .io_maskOut_0_1_6                   (dm_mask_out[0][1][6]),
    .io_maskOut_0_1_7                   (dm_mask_out[0][1][7]),
    .io_maskOut_0_1_8                   (dm_mask_out[0][1][8]),
    .io_maskOut_0_1_9                   (dm_mask_out[0][1][9]),
    .io_maskOut_0_1_10                  (dm_mask_out[0][1][10]),
    .io_maskOut_0_1_11                  (dm_mask_out[0][1][11]),
    .io_maskOut_0_1_12                  (dm_mask_out[0][1][12]),
    .io_maskOut_0_1_13                  (dm_mask_out[0][1][13]),
    .io_maskOut_0_1_14                  (dm_mask_out[0][1][14]),
    .io_maskOut_0_1_15                  (dm_mask_out[0][1][15]),
    .io_maskOut_0_2_0                   (dm_mask_out[0][2][0]),
    .io_maskOut_0_2_1                   (dm_mask_out[0][2][1]),
    .io_maskOut_0_2_2                   (dm_mask_out[0][2][2]),
    .io_maskOut_0_2_3                   (dm_mask_out[0][2][3]),
    .io_maskOut_0_2_4                   (dm_mask_out[0][2][4]),
    .io_maskOut_0_2_5                   (dm_mask_out[0][2][5]),
    .io_maskOut_0_2_6                   (dm_mask_out[0][2][6]),
    .io_maskOut_0_2_7                   (dm_mask_out[0][2][7]),
    .io_maskOut_0_2_8                   (dm_mask_out[0][2][8]),
    .io_maskOut_0_2_9                   (dm_mask_out[0][2][9]),
    .io_maskOut_0_2_10                  (dm_mask_out[0][2][10]),
    .io_maskOut_0_2_11                  (dm_mask_out[0][2][11]),
    .io_maskOut_0_2_12                  (dm_mask_out[0][2][12]),
    .io_maskOut_0_2_13                  (dm_mask_out[0][2][13]),
    .io_maskOut_0_2_14                  (dm_mask_out[0][2][14]),
    .io_maskOut_0_2_15                  (dm_mask_out[0][2][15]),
    .io_maskOut_0_3_0                   (dm_mask_out[0][3][0]),
    .io_maskOut_0_3_1                   (dm_mask_out[0][3][1]),
    .io_maskOut_0_3_2                   (dm_mask_out[0][3][2]),
    .io_maskOut_0_3_3                   (dm_mask_out[0][3][3]),
    .io_maskOut_0_3_4                   (dm_mask_out[0][3][4]),
    .io_maskOut_0_3_5                   (dm_mask_out[0][3][5]),
    .io_maskOut_0_3_6                   (dm_mask_out[0][3][6]),
    .io_maskOut_0_3_7                   (dm_mask_out[0][3][7]),
    .io_maskOut_0_3_8                   (dm_mask_out[0][3][8]),
    .io_maskOut_0_3_9                   (dm_mask_out[0][3][9]),
    .io_maskOut_0_3_10                  (dm_mask_out[0][3][10]),
    .io_maskOut_0_3_11                  (dm_mask_out[0][3][11]),
    .io_maskOut_0_3_12                  (dm_mask_out[0][3][12]),
    .io_maskOut_0_3_13                  (dm_mask_out[0][3][13]),
    .io_maskOut_0_3_14                  (dm_mask_out[0][3][14]),
    .io_maskOut_0_3_15                  (dm_mask_out[0][3][15]),
    .io_maskOut_1_0_0                   (dm_mask_out[1][0][0]),
    .io_maskOut_1_0_1                   (dm_mask_out[1][0][1]),
    .io_maskOut_1_0_2                   (dm_mask_out[1][0][2]),
    .io_maskOut_1_0_3                   (dm_mask_out[1][0][3]),
    .io_maskOut_1_0_4                   (dm_mask_out[1][0][4]),
    .io_maskOut_1_0_5                   (dm_mask_out[1][0][5]),
    .io_maskOut_1_0_6                   (dm_mask_out[1][0][6]),
    .io_maskOut_1_0_7                   (dm_mask_out[1][0][7]),
    .io_maskOut_1_0_8                   (dm_mask_out[1][0][8]),
    .io_maskOut_1_0_9                   (dm_mask_out[1][0][9]),
    .io_maskOut_1_0_10                  (dm_mask_out[1][0][10]),
    .io_maskOut_1_0_11                  (dm_mask_out[1][0][11]),
    .io_maskOut_1_0_12                  (dm_mask_out[1][0][12]),
    .io_maskOut_1_0_13                  (dm_mask_out[1][0][13]),
    .io_maskOut_1_0_14                  (dm_mask_out[1][0][14]),
    .io_maskOut_1_0_15                  (dm_mask_out[1][0][15]),
    .io_maskOut_1_1_0                   (dm_mask_out[1][1][0]),
    .io_maskOut_1_1_1                   (dm_mask_out[1][1][1]),
    .io_maskOut_1_1_2                   (dm_mask_out[1][1][2]),
    .io_maskOut_1_1_3                   (dm_mask_out[1][1][3]),
    .io_maskOut_1_1_4                   (dm_mask_out[1][1][4]),
    .io_maskOut_1_1_5                   (dm_mask_out[1][1][5]),
    .io_maskOut_1_1_6                   (dm_mask_out[1][1][6]),
    .io_maskOut_1_1_7                   (dm_mask_out[1][1][7]),
    .io_maskOut_1_1_8                   (dm_mask_out[1][1][8]),
    .io_maskOut_1_1_9                   (dm_mask_out[1][1][9]),
    .io_maskOut_1_1_10                  (dm_mask_out[1][1][10]),
    .io_maskOut_1_1_11                  (dm_mask_out[1][1][11]),
    .io_maskOut_1_1_12                  (dm_mask_out[1][1][12]),
    .io_maskOut_1_1_13                  (dm_mask_out[1][1][13]),
    .io_maskOut_1_1_14                  (dm_mask_out[1][1][14]),
    .io_maskOut_1_1_15                  (dm_mask_out[1][1][15]),
    .io_maskOut_1_2_0                   (dm_mask_out[1][2][0]),
    .io_maskOut_1_2_1                   (dm_mask_out[1][2][1]),
    .io_maskOut_1_2_2                   (dm_mask_out[1][2][2]),
    .io_maskOut_1_2_3                   (dm_mask_out[1][2][3]),
    .io_maskOut_1_2_4                   (dm_mask_out[1][2][4]),
    .io_maskOut_1_2_5                   (dm_mask_out[1][2][5]),
    .io_maskOut_1_2_6                   (dm_mask_out[1][2][6]),
    .io_maskOut_1_2_7                   (dm_mask_out[1][2][7]),
    .io_maskOut_1_2_8                   (dm_mask_out[1][2][8]),
    .io_maskOut_1_2_9                   (dm_mask_out[1][2][9]),
    .io_maskOut_1_2_10                  (dm_mask_out[1][2][10]),
    .io_maskOut_1_2_11                  (dm_mask_out[1][2][11]),
    .io_maskOut_1_2_12                  (dm_mask_out[1][2][12]),
    .io_maskOut_1_2_13                  (dm_mask_out[1][2][13]),
    .io_maskOut_1_2_14                  (dm_mask_out[1][2][14]),
    .io_maskOut_1_2_15                  (dm_mask_out[1][2][15]),
    .io_maskOut_1_3_0                   (dm_mask_out[1][3][0]),
    .io_maskOut_1_3_1                   (dm_mask_out[1][3][1]),
    .io_maskOut_1_3_2                   (dm_mask_out[1][3][2]),
    .io_maskOut_1_3_3                   (dm_mask_out[1][3][3]),
    .io_maskOut_1_3_4                   (dm_mask_out[1][3][4]),
    .io_maskOut_1_3_5                   (dm_mask_out[1][3][5]),
    .io_maskOut_1_3_6                   (dm_mask_out[1][3][6]),
    .io_maskOut_1_3_7                   (dm_mask_out[1][3][7]),
    .io_maskOut_1_3_8                   (dm_mask_out[1][3][8]),
    .io_maskOut_1_3_9                   (dm_mask_out[1][3][9]),
    .io_maskOut_1_3_10                  (dm_mask_out[1][3][10]),
    .io_maskOut_1_3_11                  (dm_mask_out[1][3][11]),
    .io_maskOut_1_3_12                  (dm_mask_out[1][3][12]),
    .io_maskOut_1_3_13                  (dm_mask_out[1][3][13]),
    .io_maskOut_1_3_14                  (dm_mask_out[1][3][14]),
    .io_maskOut_1_3_15                  (dm_mask_out[1][3][15]),
    .io_maskOut_2_0_0                   (dm_mask_out[2][0][0]),
    .io_maskOut_2_0_1                   (dm_mask_out[2][0][1]),
    .io_maskOut_2_0_2                   (dm_mask_out[2][0][2]),
    .io_maskOut_2_0_3                   (dm_mask_out[2][0][3]),
    .io_maskOut_2_0_4                   (dm_mask_out[2][0][4]),
    .io_maskOut_2_0_5                   (dm_mask_out[2][0][5]),
    .io_maskOut_2_0_6                   (dm_mask_out[2][0][6]),
    .io_maskOut_2_0_7                   (dm_mask_out[2][0][7]),
    .io_maskOut_2_0_8                   (dm_mask_out[2][0][8]),
    .io_maskOut_2_0_9                   (dm_mask_out[2][0][9]),
    .io_maskOut_2_0_10                  (dm_mask_out[2][0][10]),
    .io_maskOut_2_0_11                  (dm_mask_out[2][0][11]),
    .io_maskOut_2_0_12                  (dm_mask_out[2][0][12]),
    .io_maskOut_2_0_13                  (dm_mask_out[2][0][13]),
    .io_maskOut_2_0_14                  (dm_mask_out[2][0][14]),
    .io_maskOut_2_0_15                  (dm_mask_out[2][0][15]),
    .io_maskOut_2_1_0                   (dm_mask_out[2][1][0]),
    .io_maskOut_2_1_1                   (dm_mask_out[2][1][1]),
    .io_maskOut_2_1_2                   (dm_mask_out[2][1][2]),
    .io_maskOut_2_1_3                   (dm_mask_out[2][1][3]),
    .io_maskOut_2_1_4                   (dm_mask_out[2][1][4]),
    .io_maskOut_2_1_5                   (dm_mask_out[2][1][5]),
    .io_maskOut_2_1_6                   (dm_mask_out[2][1][6]),
    .io_maskOut_2_1_7                   (dm_mask_out[2][1][7]),
    .io_maskOut_2_1_8                   (dm_mask_out[2][1][8]),
    .io_maskOut_2_1_9                   (dm_mask_out[2][1][9]),
    .io_maskOut_2_1_10                  (dm_mask_out[2][1][10]),
    .io_maskOut_2_1_11                  (dm_mask_out[2][1][11]),
    .io_maskOut_2_1_12                  (dm_mask_out[2][1][12]),
    .io_maskOut_2_1_13                  (dm_mask_out[2][1][13]),
    .io_maskOut_2_1_14                  (dm_mask_out[2][1][14]),
    .io_maskOut_2_1_15                  (dm_mask_out[2][1][15]),
    .io_maskOut_2_2_0                   (dm_mask_out[2][2][0]),
    .io_maskOut_2_2_1                   (dm_mask_out[2][2][1]),
    .io_maskOut_2_2_2                   (dm_mask_out[2][2][2]),
    .io_maskOut_2_2_3                   (dm_mask_out[2][2][3]),
    .io_maskOut_2_2_4                   (dm_mask_out[2][2][4]),
    .io_maskOut_2_2_5                   (dm_mask_out[2][2][5]),
    .io_maskOut_2_2_6                   (dm_mask_out[2][2][6]),
    .io_maskOut_2_2_7                   (dm_mask_out[2][2][7]),
    .io_maskOut_2_2_8                   (dm_mask_out[2][2][8]),
    .io_maskOut_2_2_9                   (dm_mask_out[2][2][9]),
    .io_maskOut_2_2_10                  (dm_mask_out[2][2][10]),
    .io_maskOut_2_2_11                  (dm_mask_out[2][2][11]),
    .io_maskOut_2_2_12                  (dm_mask_out[2][2][12]),
    .io_maskOut_2_2_13                  (dm_mask_out[2][2][13]),
    .io_maskOut_2_2_14                  (dm_mask_out[2][2][14]),
    .io_maskOut_2_2_15                  (dm_mask_out[2][2][15]),
    .io_maskOut_2_3_0                   (dm_mask_out[2][3][0]),
    .io_maskOut_2_3_1                   (dm_mask_out[2][3][1]),
    .io_maskOut_2_3_2                   (dm_mask_out[2][3][2]),
    .io_maskOut_2_3_3                   (dm_mask_out[2][3][3]),
    .io_maskOut_2_3_4                   (dm_mask_out[2][3][4]),
    .io_maskOut_2_3_5                   (dm_mask_out[2][3][5]),
    .io_maskOut_2_3_6                   (dm_mask_out[2][3][6]),
    .io_maskOut_2_3_7                   (dm_mask_out[2][3][7]),
    .io_maskOut_2_3_8                   (dm_mask_out[2][3][8]),
    .io_maskOut_2_3_9                   (dm_mask_out[2][3][9]),
    .io_maskOut_2_3_10                  (dm_mask_out[2][3][10]),
    .io_maskOut_2_3_11                  (dm_mask_out[2][3][11]),
    .io_maskOut_2_3_12                  (dm_mask_out[2][3][12]),
    .io_maskOut_2_3_13                  (dm_mask_out[2][3][13]),
    .io_maskOut_2_3_14                  (dm_mask_out[2][3][14]),
    .io_maskOut_2_3_15                  (dm_mask_out[2][3][15]),
    .io_maskOut_3_0_0                   (dm_mask_out[3][0][0]),
    .io_maskOut_3_0_1                   (dm_mask_out[3][0][1]),
    .io_maskOut_3_0_2                   (dm_mask_out[3][0][2]),
    .io_maskOut_3_0_3                   (dm_mask_out[3][0][3]),
    .io_maskOut_3_0_4                   (dm_mask_out[3][0][4]),
    .io_maskOut_3_0_5                   (dm_mask_out[3][0][5]),
    .io_maskOut_3_0_6                   (dm_mask_out[3][0][6]),
    .io_maskOut_3_0_7                   (dm_mask_out[3][0][7]),
    .io_maskOut_3_0_8                   (dm_mask_out[3][0][8]),
    .io_maskOut_3_0_9                   (dm_mask_out[3][0][9]),
    .io_maskOut_3_0_10                  (dm_mask_out[3][0][10]),
    .io_maskOut_3_0_11                  (dm_mask_out[3][0][11]),
    .io_maskOut_3_0_12                  (dm_mask_out[3][0][12]),
    .io_maskOut_3_0_13                  (dm_mask_out[3][0][13]),
    .io_maskOut_3_0_14                  (dm_mask_out[3][0][14]),
    .io_maskOut_3_0_15                  (dm_mask_out[3][0][15]),
    .io_maskOut_3_1_0                   (dm_mask_out[3][1][0]),
    .io_maskOut_3_1_1                   (dm_mask_out[3][1][1]),
    .io_maskOut_3_1_2                   (dm_mask_out[3][1][2]),
    .io_maskOut_3_1_3                   (dm_mask_out[3][1][3]),
    .io_maskOut_3_1_4                   (dm_mask_out[3][1][4]),
    .io_maskOut_3_1_5                   (dm_mask_out[3][1][5]),
    .io_maskOut_3_1_6                   (dm_mask_out[3][1][6]),
    .io_maskOut_3_1_7                   (dm_mask_out[3][1][7]),
    .io_maskOut_3_1_8                   (dm_mask_out[3][1][8]),
    .io_maskOut_3_1_9                   (dm_mask_out[3][1][9]),
    .io_maskOut_3_1_10                  (dm_mask_out[3][1][10]),
    .io_maskOut_3_1_11                  (dm_mask_out[3][1][11]),
    .io_maskOut_3_1_12                  (dm_mask_out[3][1][12]),
    .io_maskOut_3_1_13                  (dm_mask_out[3][1][13]),
    .io_maskOut_3_1_14                  (dm_mask_out[3][1][14]),
    .io_maskOut_3_1_15                  (dm_mask_out[3][1][15]),
    .io_maskOut_3_2_0                   (dm_mask_out[3][2][0]),
    .io_maskOut_3_2_1                   (dm_mask_out[3][2][1]),
    .io_maskOut_3_2_2                   (dm_mask_out[3][2][2]),
    .io_maskOut_3_2_3                   (dm_mask_out[3][2][3]),
    .io_maskOut_3_2_4                   (dm_mask_out[3][2][4]),
    .io_maskOut_3_2_5                   (dm_mask_out[3][2][5]),
    .io_maskOut_3_2_6                   (dm_mask_out[3][2][6]),
    .io_maskOut_3_2_7                   (dm_mask_out[3][2][7]),
    .io_maskOut_3_2_8                   (dm_mask_out[3][2][8]),
    .io_maskOut_3_2_9                   (dm_mask_out[3][2][9]),
    .io_maskOut_3_2_10                  (dm_mask_out[3][2][10]),
    .io_maskOut_3_2_11                  (dm_mask_out[3][2][11]),
    .io_maskOut_3_2_12                  (dm_mask_out[3][2][12]),
    .io_maskOut_3_2_13                  (dm_mask_out[3][2][13]),
    .io_maskOut_3_2_14                  (dm_mask_out[3][2][14]),
    .io_maskOut_3_2_15                  (dm_mask_out[3][2][15]),
    .io_maskOut_3_3_0                   (dm_mask_out[3][3][0]),
    .io_maskOut_3_3_1                   (dm_mask_out[3][3][1]),
    .io_maskOut_3_3_2                   (dm_mask_out[3][3][2]),
    .io_maskOut_3_3_3                   (dm_mask_out[3][3][3]),
    .io_maskOut_3_3_4                   (dm_mask_out[3][3][4]),
    .io_maskOut_3_3_5                   (dm_mask_out[3][3][5]),
    .io_maskOut_3_3_6                   (dm_mask_out[3][3][6]),
    .io_maskOut_3_3_7                   (dm_mask_out[3][3][7]),
    .io_maskOut_3_3_8                   (dm_mask_out[3][3][8]),
    .io_maskOut_3_3_9                   (dm_mask_out[3][3][9]),
    .io_maskOut_3_3_10                  (dm_mask_out[3][3][10]),
    .io_maskOut_3_3_11                  (dm_mask_out[3][3][11]),
    .io_maskOut_3_3_12                  (dm_mask_out[3][3][12]),
    .io_maskOut_3_3_13                  (dm_mask_out[3][3][13]),
    .io_maskOut_3_3_14                  (dm_mask_out[3][3][14]),
    .io_maskOut_3_3_15                  (dm_mask_out[3][3][15]),
    .io_maskOut_4_0_0                   (dm_mask_out[4][0][0]),
    .io_maskOut_4_0_1                   (dm_mask_out[4][0][1]),
    .io_maskOut_4_0_2                   (dm_mask_out[4][0][2]),
    .io_maskOut_4_0_3                   (dm_mask_out[4][0][3]),
    .io_maskOut_4_0_4                   (dm_mask_out[4][0][4]),
    .io_maskOut_4_0_5                   (dm_mask_out[4][0][5]),
    .io_maskOut_4_0_6                   (dm_mask_out[4][0][6]),
    .io_maskOut_4_0_7                   (dm_mask_out[4][0][7]),
    .io_maskOut_4_0_8                   (dm_mask_out[4][0][8]),
    .io_maskOut_4_0_9                   (dm_mask_out[4][0][9]),
    .io_maskOut_4_0_10                  (dm_mask_out[4][0][10]),
    .io_maskOut_4_0_11                  (dm_mask_out[4][0][11]),
    .io_maskOut_4_0_12                  (dm_mask_out[4][0][12]),
    .io_maskOut_4_0_13                  (dm_mask_out[4][0][13]),
    .io_maskOut_4_0_14                  (dm_mask_out[4][0][14]),
    .io_maskOut_4_0_15                  (dm_mask_out[4][0][15]),
    .io_maskOut_4_1_0                   (dm_mask_out[4][1][0]),
    .io_maskOut_4_1_1                   (dm_mask_out[4][1][1]),
    .io_maskOut_4_1_2                   (dm_mask_out[4][1][2]),
    .io_maskOut_4_1_3                   (dm_mask_out[4][1][3]),
    .io_maskOut_4_1_4                   (dm_mask_out[4][1][4]),
    .io_maskOut_4_1_5                   (dm_mask_out[4][1][5]),
    .io_maskOut_4_1_6                   (dm_mask_out[4][1][6]),
    .io_maskOut_4_1_7                   (dm_mask_out[4][1][7]),
    .io_maskOut_4_1_8                   (dm_mask_out[4][1][8]),
    .io_maskOut_4_1_9                   (dm_mask_out[4][1][9]),
    .io_maskOut_4_1_10                  (dm_mask_out[4][1][10]),
    .io_maskOut_4_1_11                  (dm_mask_out[4][1][11]),
    .io_maskOut_4_1_12                  (dm_mask_out[4][1][12]),
    .io_maskOut_4_1_13                  (dm_mask_out[4][1][13]),
    .io_maskOut_4_1_14                  (dm_mask_out[4][1][14]),
    .io_maskOut_4_1_15                  (dm_mask_out[4][1][15]),
    .io_maskOut_4_2_0                   (dm_mask_out[4][2][0]),
    .io_maskOut_4_2_1                   (dm_mask_out[4][2][1]),
    .io_maskOut_4_2_2                   (dm_mask_out[4][2][2]),
    .io_maskOut_4_2_3                   (dm_mask_out[4][2][3]),
    .io_maskOut_4_2_4                   (dm_mask_out[4][2][4]),
    .io_maskOut_4_2_5                   (dm_mask_out[4][2][5]),
    .io_maskOut_4_2_6                   (dm_mask_out[4][2][6]),
    .io_maskOut_4_2_7                   (dm_mask_out[4][2][7]),
    .io_maskOut_4_2_8                   (dm_mask_out[4][2][8]),
    .io_maskOut_4_2_9                   (dm_mask_out[4][2][9]),
    .io_maskOut_4_2_10                  (dm_mask_out[4][2][10]),
    .io_maskOut_4_2_11                  (dm_mask_out[4][2][11]),
    .io_maskOut_4_2_12                  (dm_mask_out[4][2][12]),
    .io_maskOut_4_2_13                  (dm_mask_out[4][2][13]),
    .io_maskOut_4_2_14                  (dm_mask_out[4][2][14]),
    .io_maskOut_4_2_15                  (dm_mask_out[4][2][15]),
    .io_maskOut_4_3_0                   (dm_mask_out[4][3][0]),
    .io_maskOut_4_3_1                   (dm_mask_out[4][3][1]),
    .io_maskOut_4_3_2                   (dm_mask_out[4][3][2]),
    .io_maskOut_4_3_3                   (dm_mask_out[4][3][3]),
    .io_maskOut_4_3_4                   (dm_mask_out[4][3][4]),
    .io_maskOut_4_3_5                   (dm_mask_out[4][3][5]),
    .io_maskOut_4_3_6                   (dm_mask_out[4][3][6]),
    .io_maskOut_4_3_7                   (dm_mask_out[4][3][7]),
    .io_maskOut_4_3_8                   (dm_mask_out[4][3][8]),
    .io_maskOut_4_3_9                   (dm_mask_out[4][3][9]),
    .io_maskOut_4_3_10                  (dm_mask_out[4][3][10]),
    .io_maskOut_4_3_11                  (dm_mask_out[4][3][11]),
    .io_maskOut_4_3_12                  (dm_mask_out[4][3][12]),
    .io_maskOut_4_3_13                  (dm_mask_out[4][3][13]),
    .io_maskOut_4_3_14                  (dm_mask_out[4][3][14]),
    .io_maskOut_4_3_15                  (dm_mask_out[4][3][15]),
    .io_maskOut_5_0_0                   (dm_mask_out[5][0][0]),
    .io_maskOut_5_0_1                   (dm_mask_out[5][0][1]),
    .io_maskOut_5_0_2                   (dm_mask_out[5][0][2]),
    .io_maskOut_5_0_3                   (dm_mask_out[5][0][3]),
    .io_maskOut_5_0_4                   (dm_mask_out[5][0][4]),
    .io_maskOut_5_0_5                   (dm_mask_out[5][0][5]),
    .io_maskOut_5_0_6                   (dm_mask_out[5][0][6]),
    .io_maskOut_5_0_7                   (dm_mask_out[5][0][7]),
    .io_maskOut_5_0_8                   (dm_mask_out[5][0][8]),
    .io_maskOut_5_0_9                   (dm_mask_out[5][0][9]),
    .io_maskOut_5_0_10                  (dm_mask_out[5][0][10]),
    .io_maskOut_5_0_11                  (dm_mask_out[5][0][11]),
    .io_maskOut_5_0_12                  (dm_mask_out[5][0][12]),
    .io_maskOut_5_0_13                  (dm_mask_out[5][0][13]),
    .io_maskOut_5_0_14                  (dm_mask_out[5][0][14]),
    .io_maskOut_5_0_15                  (dm_mask_out[5][0][15]),
    .io_maskOut_5_1_0                   (dm_mask_out[5][1][0]),
    .io_maskOut_5_1_1                   (dm_mask_out[5][1][1]),
    .io_maskOut_5_1_2                   (dm_mask_out[5][1][2]),
    .io_maskOut_5_1_3                   (dm_mask_out[5][1][3]),
    .io_maskOut_5_1_4                   (dm_mask_out[5][1][4]),
    .io_maskOut_5_1_5                   (dm_mask_out[5][1][5]),
    .io_maskOut_5_1_6                   (dm_mask_out[5][1][6]),
    .io_maskOut_5_1_7                   (dm_mask_out[5][1][7]),
    .io_maskOut_5_1_8                   (dm_mask_out[5][1][8]),
    .io_maskOut_5_1_9                   (dm_mask_out[5][1][9]),
    .io_maskOut_5_1_10                  (dm_mask_out[5][1][10]),
    .io_maskOut_5_1_11                  (dm_mask_out[5][1][11]),
    .io_maskOut_5_1_12                  (dm_mask_out[5][1][12]),
    .io_maskOut_5_1_13                  (dm_mask_out[5][1][13]),
    .io_maskOut_5_1_14                  (dm_mask_out[5][1][14]),
    .io_maskOut_5_1_15                  (dm_mask_out[5][1][15]),
    .io_maskOut_5_2_0                   (dm_mask_out[5][2][0]),
    .io_maskOut_5_2_1                   (dm_mask_out[5][2][1]),
    .io_maskOut_5_2_2                   (dm_mask_out[5][2][2]),
    .io_maskOut_5_2_3                   (dm_mask_out[5][2][3]),
    .io_maskOut_5_2_4                   (dm_mask_out[5][2][4]),
    .io_maskOut_5_2_5                   (dm_mask_out[5][2][5]),
    .io_maskOut_5_2_6                   (dm_mask_out[5][2][6]),
    .io_maskOut_5_2_7                   (dm_mask_out[5][2][7]),
    .io_maskOut_5_2_8                   (dm_mask_out[5][2][8]),
    .io_maskOut_5_2_9                   (dm_mask_out[5][2][9]),
    .io_maskOut_5_2_10                  (dm_mask_out[5][2][10]),
    .io_maskOut_5_2_11                  (dm_mask_out[5][2][11]),
    .io_maskOut_5_2_12                  (dm_mask_out[5][2][12]),
    .io_maskOut_5_2_13                  (dm_mask_out[5][2][13]),
    .io_maskOut_5_2_14                  (dm_mask_out[5][2][14]),
    .io_maskOut_5_2_15                  (dm_mask_out[5][2][15]),
    .io_maskOut_5_3_0                   (dm_mask_out[5][3][0]),
    .io_maskOut_5_3_1                   (dm_mask_out[5][3][1]),
    .io_maskOut_5_3_2                   (dm_mask_out[5][3][2]),
    .io_maskOut_5_3_3                   (dm_mask_out[5][3][3]),
    .io_maskOut_5_3_4                   (dm_mask_out[5][3][4]),
    .io_maskOut_5_3_5                   (dm_mask_out[5][3][5]),
    .io_maskOut_5_3_6                   (dm_mask_out[5][3][6]),
    .io_maskOut_5_3_7                   (dm_mask_out[5][3][7]),
    .io_maskOut_5_3_8                   (dm_mask_out[5][3][8]),
    .io_maskOut_5_3_9                   (dm_mask_out[5][3][9]),
    .io_maskOut_5_3_10                  (dm_mask_out[5][3][10]),
    .io_maskOut_5_3_11                  (dm_mask_out[5][3][11]),
    .io_maskOut_5_3_12                  (dm_mask_out[5][3][12]),
    .io_maskOut_5_3_13                  (dm_mask_out[5][3][13]),
    .io_maskOut_5_3_14                  (dm_mask_out[5][3][14]),
    .io_maskOut_5_3_15                  (dm_mask_out[5][3][15]),
    .io_maskOut_6_0_0                   (dm_mask_out[6][0][0]),
    .io_maskOut_6_0_1                   (dm_mask_out[6][0][1]),
    .io_maskOut_6_0_2                   (dm_mask_out[6][0][2]),
    .io_maskOut_6_0_3                   (dm_mask_out[6][0][3]),
    .io_maskOut_6_0_4                   (dm_mask_out[6][0][4]),
    .io_maskOut_6_0_5                   (dm_mask_out[6][0][5]),
    .io_maskOut_6_0_6                   (dm_mask_out[6][0][6]),
    .io_maskOut_6_0_7                   (dm_mask_out[6][0][7]),
    .io_maskOut_6_0_8                   (dm_mask_out[6][0][8]),
    .io_maskOut_6_0_9                   (dm_mask_out[6][0][9]),
    .io_maskOut_6_0_10                  (dm_mask_out[6][0][10]),
    .io_maskOut_6_0_11                  (dm_mask_out[6][0][11]),
    .io_maskOut_6_0_12                  (dm_mask_out[6][0][12]),
    .io_maskOut_6_0_13                  (dm_mask_out[6][0][13]),
    .io_maskOut_6_0_14                  (dm_mask_out[6][0][14]),
    .io_maskOut_6_0_15                  (dm_mask_out[6][0][15]),
    .io_maskOut_6_1_0                   (dm_mask_out[6][1][0]),
    .io_maskOut_6_1_1                   (dm_mask_out[6][1][1]),
    .io_maskOut_6_1_2                   (dm_mask_out[6][1][2]),
    .io_maskOut_6_1_3                   (dm_mask_out[6][1][3]),
    .io_maskOut_6_1_4                   (dm_mask_out[6][1][4]),
    .io_maskOut_6_1_5                   (dm_mask_out[6][1][5]),
    .io_maskOut_6_1_6                   (dm_mask_out[6][1][6]),
    .io_maskOut_6_1_7                   (dm_mask_out[6][1][7]),
    .io_maskOut_6_1_8                   (dm_mask_out[6][1][8]),
    .io_maskOut_6_1_9                   (dm_mask_out[6][1][9]),
    .io_maskOut_6_1_10                  (dm_mask_out[6][1][10]),
    .io_maskOut_6_1_11                  (dm_mask_out[6][1][11]),
    .io_maskOut_6_1_12                  (dm_mask_out[6][1][12]),
    .io_maskOut_6_1_13                  (dm_mask_out[6][1][13]),
    .io_maskOut_6_1_14                  (dm_mask_out[6][1][14]),
    .io_maskOut_6_1_15                  (dm_mask_out[6][1][15]),
    .io_maskOut_6_2_0                   (dm_mask_out[6][2][0]),
    .io_maskOut_6_2_1                   (dm_mask_out[6][2][1]),
    .io_maskOut_6_2_2                   (dm_mask_out[6][2][2]),
    .io_maskOut_6_2_3                   (dm_mask_out[6][2][3]),
    .io_maskOut_6_2_4                   (dm_mask_out[6][2][4]),
    .io_maskOut_6_2_5                   (dm_mask_out[6][2][5]),
    .io_maskOut_6_2_6                   (dm_mask_out[6][2][6]),
    .io_maskOut_6_2_7                   (dm_mask_out[6][2][7]),
    .io_maskOut_6_2_8                   (dm_mask_out[6][2][8]),
    .io_maskOut_6_2_9                   (dm_mask_out[6][2][9]),
    .io_maskOut_6_2_10                  (dm_mask_out[6][2][10]),
    .io_maskOut_6_2_11                  (dm_mask_out[6][2][11]),
    .io_maskOut_6_2_12                  (dm_mask_out[6][2][12]),
    .io_maskOut_6_2_13                  (dm_mask_out[6][2][13]),
    .io_maskOut_6_2_14                  (dm_mask_out[6][2][14]),
    .io_maskOut_6_2_15                  (dm_mask_out[6][2][15]),
    .io_maskOut_6_3_0                   (dm_mask_out[6][3][0]),
    .io_maskOut_6_3_1                   (dm_mask_out[6][3][1]),
    .io_maskOut_6_3_2                   (dm_mask_out[6][3][2]),
    .io_maskOut_6_3_3                   (dm_mask_out[6][3][3]),
    .io_maskOut_6_3_4                   (dm_mask_out[6][3][4]),
    .io_maskOut_6_3_5                   (dm_mask_out[6][3][5]),
    .io_maskOut_6_3_6                   (dm_mask_out[6][3][6]),
    .io_maskOut_6_3_7                   (dm_mask_out[6][3][7]),
    .io_maskOut_6_3_8                   (dm_mask_out[6][3][8]),
    .io_maskOut_6_3_9                   (dm_mask_out[6][3][9]),
    .io_maskOut_6_3_10                  (dm_mask_out[6][3][10]),
    .io_maskOut_6_3_11                  (dm_mask_out[6][3][11]),
    .io_maskOut_6_3_12                  (dm_mask_out[6][3][12]),
    .io_maskOut_6_3_13                  (dm_mask_out[6][3][13]),
    .io_maskOut_6_3_14                  (dm_mask_out[6][3][14]),
    .io_maskOut_6_3_15                  (dm_mask_out[6][3][15]),
    .io_maskOut_7_0_0                   (dm_mask_out[7][0][0]),
    .io_maskOut_7_0_1                   (dm_mask_out[7][0][1]),
    .io_maskOut_7_0_2                   (dm_mask_out[7][0][2]),
    .io_maskOut_7_0_3                   (dm_mask_out[7][0][3]),
    .io_maskOut_7_0_4                   (dm_mask_out[7][0][4]),
    .io_maskOut_7_0_5                   (dm_mask_out[7][0][5]),
    .io_maskOut_7_0_6                   (dm_mask_out[7][0][6]),
    .io_maskOut_7_0_7                   (dm_mask_out[7][0][7]),
    .io_maskOut_7_0_8                   (dm_mask_out[7][0][8]),
    .io_maskOut_7_0_9                   (dm_mask_out[7][0][9]),
    .io_maskOut_7_0_10                  (dm_mask_out[7][0][10]),
    .io_maskOut_7_0_11                  (dm_mask_out[7][0][11]),
    .io_maskOut_7_0_12                  (dm_mask_out[7][0][12]),
    .io_maskOut_7_0_13                  (dm_mask_out[7][0][13]),
    .io_maskOut_7_0_14                  (dm_mask_out[7][0][14]),
    .io_maskOut_7_0_15                  (dm_mask_out[7][0][15]),
    .io_maskOut_7_1_0                   (dm_mask_out[7][1][0]),
    .io_maskOut_7_1_1                   (dm_mask_out[7][1][1]),
    .io_maskOut_7_1_2                   (dm_mask_out[7][1][2]),
    .io_maskOut_7_1_3                   (dm_mask_out[7][1][3]),
    .io_maskOut_7_1_4                   (dm_mask_out[7][1][4]),
    .io_maskOut_7_1_5                   (dm_mask_out[7][1][5]),
    .io_maskOut_7_1_6                   (dm_mask_out[7][1][6]),
    .io_maskOut_7_1_7                   (dm_mask_out[7][1][7]),
    .io_maskOut_7_1_8                   (dm_mask_out[7][1][8]),
    .io_maskOut_7_1_9                   (dm_mask_out[7][1][9]),
    .io_maskOut_7_1_10                  (dm_mask_out[7][1][10]),
    .io_maskOut_7_1_11                  (dm_mask_out[7][1][11]),
    .io_maskOut_7_1_12                  (dm_mask_out[7][1][12]),
    .io_maskOut_7_1_13                  (dm_mask_out[7][1][13]),
    .io_maskOut_7_1_14                  (dm_mask_out[7][1][14]),
    .io_maskOut_7_1_15                  (dm_mask_out[7][1][15]),
    .io_maskOut_7_2_0                   (dm_mask_out[7][2][0]),
    .io_maskOut_7_2_1                   (dm_mask_out[7][2][1]),
    .io_maskOut_7_2_2                   (dm_mask_out[7][2][2]),
    .io_maskOut_7_2_3                   (dm_mask_out[7][2][3]),
    .io_maskOut_7_2_4                   (dm_mask_out[7][2][4]),
    .io_maskOut_7_2_5                   (dm_mask_out[7][2][5]),
    .io_maskOut_7_2_6                   (dm_mask_out[7][2][6]),
    .io_maskOut_7_2_7                   (dm_mask_out[7][2][7]),
    .io_maskOut_7_2_8                   (dm_mask_out[7][2][8]),
    .io_maskOut_7_2_9                   (dm_mask_out[7][2][9]),
    .io_maskOut_7_2_10                  (dm_mask_out[7][2][10]),
    .io_maskOut_7_2_11                  (dm_mask_out[7][2][11]),
    .io_maskOut_7_2_12                  (dm_mask_out[7][2][12]),
    .io_maskOut_7_2_13                  (dm_mask_out[7][2][13]),
    .io_maskOut_7_2_14                  (dm_mask_out[7][2][14]),
    .io_maskOut_7_2_15                  (dm_mask_out[7][2][15]),
    .io_maskOut_7_3_0                   (dm_mask_out[7][3][0]),
    .io_maskOut_7_3_1                   (dm_mask_out[7][3][1]),
    .io_maskOut_7_3_2                   (dm_mask_out[7][3][2]),
    .io_maskOut_7_3_3                   (dm_mask_out[7][3][3]),
    .io_maskOut_7_3_4                   (dm_mask_out[7][3][4]),
    .io_maskOut_7_3_5                   (dm_mask_out[7][3][5]),
    .io_maskOut_7_3_6                   (dm_mask_out[7][3][6]),
    .io_maskOut_7_3_7                   (dm_mask_out[7][3][7]),
    .io_maskOut_7_3_8                   (dm_mask_out[7][3][8]),
    .io_maskOut_7_3_9                   (dm_mask_out[7][3][9]),
    .io_maskOut_7_3_10                  (dm_mask_out[7][3][10]),
    .io_maskOut_7_3_11                  (dm_mask_out[7][3][11]),
    .io_maskOut_7_3_12                  (dm_mask_out[7][3][12]),
    .io_maskOut_7_3_13                  (dm_mask_out[7][3][13]),
    .io_maskOut_7_3_14                  (dm_mask_out[7][3][14]),
    .io_maskOut_7_3_15                  (dm_mask_out[7][3][15]),
    .io_maskOut_8_0_0                   (dm_mask_out[8][0][0]),
    .io_maskOut_8_0_1                   (dm_mask_out[8][0][1]),
    .io_maskOut_8_0_2                   (dm_mask_out[8][0][2]),
    .io_maskOut_8_0_3                   (dm_mask_out[8][0][3]),
    .io_maskOut_8_0_4                   (dm_mask_out[8][0][4]),
    .io_maskOut_8_0_5                   (dm_mask_out[8][0][5]),
    .io_maskOut_8_0_6                   (dm_mask_out[8][0][6]),
    .io_maskOut_8_0_7                   (dm_mask_out[8][0][7]),
    .io_maskOut_8_0_8                   (dm_mask_out[8][0][8]),
    .io_maskOut_8_0_9                   (dm_mask_out[8][0][9]),
    .io_maskOut_8_0_10                  (dm_mask_out[8][0][10]),
    .io_maskOut_8_0_11                  (dm_mask_out[8][0][11]),
    .io_maskOut_8_0_12                  (dm_mask_out[8][0][12]),
    .io_maskOut_8_0_13                  (dm_mask_out[8][0][13]),
    .io_maskOut_8_0_14                  (dm_mask_out[8][0][14]),
    .io_maskOut_8_0_15                  (dm_mask_out[8][0][15]),
    .io_maskOut_8_1_0                   (dm_mask_out[8][1][0]),
    .io_maskOut_8_1_1                   (dm_mask_out[8][1][1]),
    .io_maskOut_8_1_2                   (dm_mask_out[8][1][2]),
    .io_maskOut_8_1_3                   (dm_mask_out[8][1][3]),
    .io_maskOut_8_1_4                   (dm_mask_out[8][1][4]),
    .io_maskOut_8_1_5                   (dm_mask_out[8][1][5]),
    .io_maskOut_8_1_6                   (dm_mask_out[8][1][6]),
    .io_maskOut_8_1_7                   (dm_mask_out[8][1][7]),
    .io_maskOut_8_1_8                   (dm_mask_out[8][1][8]),
    .io_maskOut_8_1_9                   (dm_mask_out[8][1][9]),
    .io_maskOut_8_1_10                  (dm_mask_out[8][1][10]),
    .io_maskOut_8_1_11                  (dm_mask_out[8][1][11]),
    .io_maskOut_8_1_12                  (dm_mask_out[8][1][12]),
    .io_maskOut_8_1_13                  (dm_mask_out[8][1][13]),
    .io_maskOut_8_1_14                  (dm_mask_out[8][1][14]),
    .io_maskOut_8_1_15                  (dm_mask_out[8][1][15]),
    .io_maskOut_8_2_0                   (dm_mask_out[8][2][0]),
    .io_maskOut_8_2_1                   (dm_mask_out[8][2][1]),
    .io_maskOut_8_2_2                   (dm_mask_out[8][2][2]),
    .io_maskOut_8_2_3                   (dm_mask_out[8][2][3]),
    .io_maskOut_8_2_4                   (dm_mask_out[8][2][4]),
    .io_maskOut_8_2_5                   (dm_mask_out[8][2][5]),
    .io_maskOut_8_2_6                   (dm_mask_out[8][2][6]),
    .io_maskOut_8_2_7                   (dm_mask_out[8][2][7]),
    .io_maskOut_8_2_8                   (dm_mask_out[8][2][8]),
    .io_maskOut_8_2_9                   (dm_mask_out[8][2][9]),
    .io_maskOut_8_2_10                  (dm_mask_out[8][2][10]),
    .io_maskOut_8_2_11                  (dm_mask_out[8][2][11]),
    .io_maskOut_8_2_12                  (dm_mask_out[8][2][12]),
    .io_maskOut_8_2_13                  (dm_mask_out[8][2][13]),
    .io_maskOut_8_2_14                  (dm_mask_out[8][2][14]),
    .io_maskOut_8_2_15                  (dm_mask_out[8][2][15]),
    .io_maskOut_8_3_0                   (dm_mask_out[8][3][0]),
    .io_maskOut_8_3_1                   (dm_mask_out[8][3][1]),
    .io_maskOut_8_3_2                   (dm_mask_out[8][3][2]),
    .io_maskOut_8_3_3                   (dm_mask_out[8][3][3]),
    .io_maskOut_8_3_4                   (dm_mask_out[8][3][4]),
    .io_maskOut_8_3_5                   (dm_mask_out[8][3][5]),
    .io_maskOut_8_3_6                   (dm_mask_out[8][3][6]),
    .io_maskOut_8_3_7                   (dm_mask_out[8][3][7]),
    .io_maskOut_8_3_8                   (dm_mask_out[8][3][8]),
    .io_maskOut_8_3_9                   (dm_mask_out[8][3][9]),
    .io_maskOut_8_3_10                  (dm_mask_out[8][3][10]),
    .io_maskOut_8_3_11                  (dm_mask_out[8][3][11]),
    .io_maskOut_8_3_12                  (dm_mask_out[8][3][12]),
    .io_maskOut_8_3_13                  (dm_mask_out[8][3][13]),
    .io_maskOut_8_3_14                  (dm_mask_out[8][3][14]),
    .io_maskOut_8_3_15                  (dm_mask_out[8][3][15]),
    .io_maskOut_9_0_0                   (dm_mask_out[9][0][0]),
    .io_maskOut_9_0_1                   (dm_mask_out[9][0][1]),
    .io_maskOut_9_0_2                   (dm_mask_out[9][0][2]),
    .io_maskOut_9_0_3                   (dm_mask_out[9][0][3]),
    .io_maskOut_9_0_4                   (dm_mask_out[9][0][4]),
    .io_maskOut_9_0_5                   (dm_mask_out[9][0][5]),
    .io_maskOut_9_0_6                   (dm_mask_out[9][0][6]),
    .io_maskOut_9_0_7                   (dm_mask_out[9][0][7]),
    .io_maskOut_9_0_8                   (dm_mask_out[9][0][8]),
    .io_maskOut_9_0_9                   (dm_mask_out[9][0][9]),
    .io_maskOut_9_0_10                  (dm_mask_out[9][0][10]),
    .io_maskOut_9_0_11                  (dm_mask_out[9][0][11]),
    .io_maskOut_9_0_12                  (dm_mask_out[9][0][12]),
    .io_maskOut_9_0_13                  (dm_mask_out[9][0][13]),
    .io_maskOut_9_0_14                  (dm_mask_out[9][0][14]),
    .io_maskOut_9_0_15                  (dm_mask_out[9][0][15]),
    .io_maskOut_9_1_0                   (dm_mask_out[9][1][0]),
    .io_maskOut_9_1_1                   (dm_mask_out[9][1][1]),
    .io_maskOut_9_1_2                   (dm_mask_out[9][1][2]),
    .io_maskOut_9_1_3                   (dm_mask_out[9][1][3]),
    .io_maskOut_9_1_4                   (dm_mask_out[9][1][4]),
    .io_maskOut_9_1_5                   (dm_mask_out[9][1][5]),
    .io_maskOut_9_1_6                   (dm_mask_out[9][1][6]),
    .io_maskOut_9_1_7                   (dm_mask_out[9][1][7]),
    .io_maskOut_9_1_8                   (dm_mask_out[9][1][8]),
    .io_maskOut_9_1_9                   (dm_mask_out[9][1][9]),
    .io_maskOut_9_1_10                  (dm_mask_out[9][1][10]),
    .io_maskOut_9_1_11                  (dm_mask_out[9][1][11]),
    .io_maskOut_9_1_12                  (dm_mask_out[9][1][12]),
    .io_maskOut_9_1_13                  (dm_mask_out[9][1][13]),
    .io_maskOut_9_1_14                  (dm_mask_out[9][1][14]),
    .io_maskOut_9_1_15                  (dm_mask_out[9][1][15]),
    .io_maskOut_9_2_0                   (dm_mask_out[9][2][0]),
    .io_maskOut_9_2_1                   (dm_mask_out[9][2][1]),
    .io_maskOut_9_2_2                   (dm_mask_out[9][2][2]),
    .io_maskOut_9_2_3                   (dm_mask_out[9][2][3]),
    .io_maskOut_9_2_4                   (dm_mask_out[9][2][4]),
    .io_maskOut_9_2_5                   (dm_mask_out[9][2][5]),
    .io_maskOut_9_2_6                   (dm_mask_out[9][2][6]),
    .io_maskOut_9_2_7                   (dm_mask_out[9][2][7]),
    .io_maskOut_9_2_8                   (dm_mask_out[9][2][8]),
    .io_maskOut_9_2_9                   (dm_mask_out[9][2][9]),
    .io_maskOut_9_2_10                  (dm_mask_out[9][2][10]),
    .io_maskOut_9_2_11                  (dm_mask_out[9][2][11]),
    .io_maskOut_9_2_12                  (dm_mask_out[9][2][12]),
    .io_maskOut_9_2_13                  (dm_mask_out[9][2][13]),
    .io_maskOut_9_2_14                  (dm_mask_out[9][2][14]),
    .io_maskOut_9_2_15                  (dm_mask_out[9][2][15]),
    .io_maskOut_9_3_0                   (dm_mask_out[9][3][0]),
    .io_maskOut_9_3_1                   (dm_mask_out[9][3][1]),
    .io_maskOut_9_3_2                   (dm_mask_out[9][3][2]),
    .io_maskOut_9_3_3                   (dm_mask_out[9][3][3]),
    .io_maskOut_9_3_4                   (dm_mask_out[9][3][4]),
    .io_maskOut_9_3_5                   (dm_mask_out[9][3][5]),
    .io_maskOut_9_3_6                   (dm_mask_out[9][3][6]),
    .io_maskOut_9_3_7                   (dm_mask_out[9][3][7]),
    .io_maskOut_9_3_8                   (dm_mask_out[9][3][8]),
    .io_maskOut_9_3_9                   (dm_mask_out[9][3][9]),
    .io_maskOut_9_3_10                  (dm_mask_out[9][3][10]),
    .io_maskOut_9_3_11                  (dm_mask_out[9][3][11]),
    .io_maskOut_9_3_12                  (dm_mask_out[9][3][12]),
    .io_maskOut_9_3_13                  (dm_mask_out[9][3][13]),
    .io_maskOut_9_3_14                  (dm_mask_out[9][3][14]),
    .io_maskOut_9_3_15                  (dm_mask_out[9][3][15]),
    .io_maskOut_10_0_0                  (dm_mask_out[10][0][0]),
    .io_maskOut_10_0_1                  (dm_mask_out[10][0][1]),
    .io_maskOut_10_0_2                  (dm_mask_out[10][0][2]),
    .io_maskOut_10_0_3                  (dm_mask_out[10][0][3]),
    .io_maskOut_10_0_4                  (dm_mask_out[10][0][4]),
    .io_maskOut_10_0_5                  (dm_mask_out[10][0][5]),
    .io_maskOut_10_0_6                  (dm_mask_out[10][0][6]),
    .io_maskOut_10_0_7                  (dm_mask_out[10][0][7]),
    .io_maskOut_10_0_8                  (dm_mask_out[10][0][8]),
    .io_maskOut_10_0_9                  (dm_mask_out[10][0][9]),
    .io_maskOut_10_0_10                 (dm_mask_out[10][0][10]),
    .io_maskOut_10_0_11                 (dm_mask_out[10][0][11]),
    .io_maskOut_10_0_12                 (dm_mask_out[10][0][12]),
    .io_maskOut_10_0_13                 (dm_mask_out[10][0][13]),
    .io_maskOut_10_0_14                 (dm_mask_out[10][0][14]),
    .io_maskOut_10_0_15                 (dm_mask_out[10][0][15]),
    .io_maskOut_10_1_0                  (dm_mask_out[10][1][0]),
    .io_maskOut_10_1_1                  (dm_mask_out[10][1][1]),
    .io_maskOut_10_1_2                  (dm_mask_out[10][1][2]),
    .io_maskOut_10_1_3                  (dm_mask_out[10][1][3]),
    .io_maskOut_10_1_4                  (dm_mask_out[10][1][4]),
    .io_maskOut_10_1_5                  (dm_mask_out[10][1][5]),
    .io_maskOut_10_1_6                  (dm_mask_out[10][1][6]),
    .io_maskOut_10_1_7                  (dm_mask_out[10][1][7]),
    .io_maskOut_10_1_8                  (dm_mask_out[10][1][8]),
    .io_maskOut_10_1_9                  (dm_mask_out[10][1][9]),
    .io_maskOut_10_1_10                 (dm_mask_out[10][1][10]),
    .io_maskOut_10_1_11                 (dm_mask_out[10][1][11]),
    .io_maskOut_10_1_12                 (dm_mask_out[10][1][12]),
    .io_maskOut_10_1_13                 (dm_mask_out[10][1][13]),
    .io_maskOut_10_1_14                 (dm_mask_out[10][1][14]),
    .io_maskOut_10_1_15                 (dm_mask_out[10][1][15]),
    .io_maskOut_10_2_0                  (dm_mask_out[10][2][0]),
    .io_maskOut_10_2_1                  (dm_mask_out[10][2][1]),
    .io_maskOut_10_2_2                  (dm_mask_out[10][2][2]),
    .io_maskOut_10_2_3                  (dm_mask_out[10][2][3]),
    .io_maskOut_10_2_4                  (dm_mask_out[10][2][4]),
    .io_maskOut_10_2_5                  (dm_mask_out[10][2][5]),
    .io_maskOut_10_2_6                  (dm_mask_out[10][2][6]),
    .io_maskOut_10_2_7                  (dm_mask_out[10][2][7]),
    .io_maskOut_10_2_8                  (dm_mask_out[10][2][8]),
    .io_maskOut_10_2_9                  (dm_mask_out[10][2][9]),
    .io_maskOut_10_2_10                 (dm_mask_out[10][2][10]),
    .io_maskOut_10_2_11                 (dm_mask_out[10][2][11]),
    .io_maskOut_10_2_12                 (dm_mask_out[10][2][12]),
    .io_maskOut_10_2_13                 (dm_mask_out[10][2][13]),
    .io_maskOut_10_2_14                 (dm_mask_out[10][2][14]),
    .io_maskOut_10_2_15                 (dm_mask_out[10][2][15]),
    .io_maskOut_10_3_0                  (dm_mask_out[10][3][0]),
    .io_maskOut_10_3_1                  (dm_mask_out[10][3][1]),
    .io_maskOut_10_3_2                  (dm_mask_out[10][3][2]),
    .io_maskOut_10_3_3                  (dm_mask_out[10][3][3]),
    .io_maskOut_10_3_4                  (dm_mask_out[10][3][4]),
    .io_maskOut_10_3_5                  (dm_mask_out[10][3][5]),
    .io_maskOut_10_3_6                  (dm_mask_out[10][3][6]),
    .io_maskOut_10_3_7                  (dm_mask_out[10][3][7]),
    .io_maskOut_10_3_8                  (dm_mask_out[10][3][8]),
    .io_maskOut_10_3_9                  (dm_mask_out[10][3][9]),
    .io_maskOut_10_3_10                 (dm_mask_out[10][3][10]),
    .io_maskOut_10_3_11                 (dm_mask_out[10][3][11]),
    .io_maskOut_10_3_12                 (dm_mask_out[10][3][12]),
    .io_maskOut_10_3_13                 (dm_mask_out[10][3][13]),
    .io_maskOut_10_3_14                 (dm_mask_out[10][3][14]),
    .io_maskOut_10_3_15                 (dm_mask_out[10][3][15]),
    .io_maskOut_11_0_0                  (dm_mask_out[11][0][0]),
    .io_maskOut_11_0_1                  (dm_mask_out[11][0][1]),
    .io_maskOut_11_0_2                  (dm_mask_out[11][0][2]),
    .io_maskOut_11_0_3                  (dm_mask_out[11][0][3]),
    .io_maskOut_11_0_4                  (dm_mask_out[11][0][4]),
    .io_maskOut_11_0_5                  (dm_mask_out[11][0][5]),
    .io_maskOut_11_0_6                  (dm_mask_out[11][0][6]),
    .io_maskOut_11_0_7                  (dm_mask_out[11][0][7]),
    .io_maskOut_11_0_8                  (dm_mask_out[11][0][8]),
    .io_maskOut_11_0_9                  (dm_mask_out[11][0][9]),
    .io_maskOut_11_0_10                 (dm_mask_out[11][0][10]),
    .io_maskOut_11_0_11                 (dm_mask_out[11][0][11]),
    .io_maskOut_11_0_12                 (dm_mask_out[11][0][12]),
    .io_maskOut_11_0_13                 (dm_mask_out[11][0][13]),
    .io_maskOut_11_0_14                 (dm_mask_out[11][0][14]),
    .io_maskOut_11_0_15                 (dm_mask_out[11][0][15]),
    .io_maskOut_11_1_0                  (dm_mask_out[11][1][0]),
    .io_maskOut_11_1_1                  (dm_mask_out[11][1][1]),
    .io_maskOut_11_1_2                  (dm_mask_out[11][1][2]),
    .io_maskOut_11_1_3                  (dm_mask_out[11][1][3]),
    .io_maskOut_11_1_4                  (dm_mask_out[11][1][4]),
    .io_maskOut_11_1_5                  (dm_mask_out[11][1][5]),
    .io_maskOut_11_1_6                  (dm_mask_out[11][1][6]),
    .io_maskOut_11_1_7                  (dm_mask_out[11][1][7]),
    .io_maskOut_11_1_8                  (dm_mask_out[11][1][8]),
    .io_maskOut_11_1_9                  (dm_mask_out[11][1][9]),
    .io_maskOut_11_1_10                 (dm_mask_out[11][1][10]),
    .io_maskOut_11_1_11                 (dm_mask_out[11][1][11]),
    .io_maskOut_11_1_12                 (dm_mask_out[11][1][12]),
    .io_maskOut_11_1_13                 (dm_mask_out[11][1][13]),
    .io_maskOut_11_1_14                 (dm_mask_out[11][1][14]),
    .io_maskOut_11_1_15                 (dm_mask_out[11][1][15]),
    .io_maskOut_11_2_0                  (dm_mask_out[11][2][0]),
    .io_maskOut_11_2_1                  (dm_mask_out[11][2][1]),
    .io_maskOut_11_2_2                  (dm_mask_out[11][2][2]),
    .io_maskOut_11_2_3                  (dm_mask_out[11][2][3]),
    .io_maskOut_11_2_4                  (dm_mask_out[11][2][4]),
    .io_maskOut_11_2_5                  (dm_mask_out[11][2][5]),
    .io_maskOut_11_2_6                  (dm_mask_out[11][2][6]),
    .io_maskOut_11_2_7                  (dm_mask_out[11][2][7]),
    .io_maskOut_11_2_8                  (dm_mask_out[11][2][8]),
    .io_maskOut_11_2_9                  (dm_mask_out[11][2][9]),
    .io_maskOut_11_2_10                 (dm_mask_out[11][2][10]),
    .io_maskOut_11_2_11                 (dm_mask_out[11][2][11]),
    .io_maskOut_11_2_12                 (dm_mask_out[11][2][12]),
    .io_maskOut_11_2_13                 (dm_mask_out[11][2][13]),
    .io_maskOut_11_2_14                 (dm_mask_out[11][2][14]),
    .io_maskOut_11_2_15                 (dm_mask_out[11][2][15]),
    .io_maskOut_11_3_0                  (dm_mask_out[11][3][0]),
    .io_maskOut_11_3_1                  (dm_mask_out[11][3][1]),
    .io_maskOut_11_3_2                  (dm_mask_out[11][3][2]),
    .io_maskOut_11_3_3                  (dm_mask_out[11][3][3]),
    .io_maskOut_11_3_4                  (dm_mask_out[11][3][4]),
    .io_maskOut_11_3_5                  (dm_mask_out[11][3][5]),
    .io_maskOut_11_3_6                  (dm_mask_out[11][3][6]),
    .io_maskOut_11_3_7                  (dm_mask_out[11][3][7]),
    .io_maskOut_11_3_8                  (dm_mask_out[11][3][8]),
    .io_maskOut_11_3_9                  (dm_mask_out[11][3][9]),
    .io_maskOut_11_3_10                 (dm_mask_out[11][3][10]),
    .io_maskOut_11_3_11                 (dm_mask_out[11][3][11]),
    .io_maskOut_11_3_12                 (dm_mask_out[11][3][12]),
    .io_maskOut_11_3_13                 (dm_mask_out[11][3][13]),
    .io_maskOut_11_3_14                 (dm_mask_out[11][3][14]),
    .io_maskOut_11_3_15                 (dm_mask_out[11][3][15]),
    .io_maskOut_12_0_0                  (dm_mask_out[12][0][0]),
    .io_maskOut_12_0_1                  (dm_mask_out[12][0][1]),
    .io_maskOut_12_0_2                  (dm_mask_out[12][0][2]),
    .io_maskOut_12_0_3                  (dm_mask_out[12][0][3]),
    .io_maskOut_12_0_4                  (dm_mask_out[12][0][4]),
    .io_maskOut_12_0_5                  (dm_mask_out[12][0][5]),
    .io_maskOut_12_0_6                  (dm_mask_out[12][0][6]),
    .io_maskOut_12_0_7                  (dm_mask_out[12][0][7]),
    .io_maskOut_12_0_8                  (dm_mask_out[12][0][8]),
    .io_maskOut_12_0_9                  (dm_mask_out[12][0][9]),
    .io_maskOut_12_0_10                 (dm_mask_out[12][0][10]),
    .io_maskOut_12_0_11                 (dm_mask_out[12][0][11]),
    .io_maskOut_12_0_12                 (dm_mask_out[12][0][12]),
    .io_maskOut_12_0_13                 (dm_mask_out[12][0][13]),
    .io_maskOut_12_0_14                 (dm_mask_out[12][0][14]),
    .io_maskOut_12_0_15                 (dm_mask_out[12][0][15]),
    .io_maskOut_12_1_0                  (dm_mask_out[12][1][0]),
    .io_maskOut_12_1_1                  (dm_mask_out[12][1][1]),
    .io_maskOut_12_1_2                  (dm_mask_out[12][1][2]),
    .io_maskOut_12_1_3                  (dm_mask_out[12][1][3]),
    .io_maskOut_12_1_4                  (dm_mask_out[12][1][4]),
    .io_maskOut_12_1_5                  (dm_mask_out[12][1][5]),
    .io_maskOut_12_1_6                  (dm_mask_out[12][1][6]),
    .io_maskOut_12_1_7                  (dm_mask_out[12][1][7]),
    .io_maskOut_12_1_8                  (dm_mask_out[12][1][8]),
    .io_maskOut_12_1_9                  (dm_mask_out[12][1][9]),
    .io_maskOut_12_1_10                 (dm_mask_out[12][1][10]),
    .io_maskOut_12_1_11                 (dm_mask_out[12][1][11]),
    .io_maskOut_12_1_12                 (dm_mask_out[12][1][12]),
    .io_maskOut_12_1_13                 (dm_mask_out[12][1][13]),
    .io_maskOut_12_1_14                 (dm_mask_out[12][1][14]),
    .io_maskOut_12_1_15                 (dm_mask_out[12][1][15]),
    .io_maskOut_12_2_0                  (dm_mask_out[12][2][0]),
    .io_maskOut_12_2_1                  (dm_mask_out[12][2][1]),
    .io_maskOut_12_2_2                  (dm_mask_out[12][2][2]),
    .io_maskOut_12_2_3                  (dm_mask_out[12][2][3]),
    .io_maskOut_12_2_4                  (dm_mask_out[12][2][4]),
    .io_maskOut_12_2_5                  (dm_mask_out[12][2][5]),
    .io_maskOut_12_2_6                  (dm_mask_out[12][2][6]),
    .io_maskOut_12_2_7                  (dm_mask_out[12][2][7]),
    .io_maskOut_12_2_8                  (dm_mask_out[12][2][8]),
    .io_maskOut_12_2_9                  (dm_mask_out[12][2][9]),
    .io_maskOut_12_2_10                 (dm_mask_out[12][2][10]),
    .io_maskOut_12_2_11                 (dm_mask_out[12][2][11]),
    .io_maskOut_12_2_12                 (dm_mask_out[12][2][12]),
    .io_maskOut_12_2_13                 (dm_mask_out[12][2][13]),
    .io_maskOut_12_2_14                 (dm_mask_out[12][2][14]),
    .io_maskOut_12_2_15                 (dm_mask_out[12][2][15]),
    .io_maskOut_12_3_0                  (dm_mask_out[12][3][0]),
    .io_maskOut_12_3_1                  (dm_mask_out[12][3][1]),
    .io_maskOut_12_3_2                  (dm_mask_out[12][3][2]),
    .io_maskOut_12_3_3                  (dm_mask_out[12][3][3]),
    .io_maskOut_12_3_4                  (dm_mask_out[12][3][4]),
    .io_maskOut_12_3_5                  (dm_mask_out[12][3][5]),
    .io_maskOut_12_3_6                  (dm_mask_out[12][3][6]),
    .io_maskOut_12_3_7                  (dm_mask_out[12][3][7]),
    .io_maskOut_12_3_8                  (dm_mask_out[12][3][8]),
    .io_maskOut_12_3_9                  (dm_mask_out[12][3][9]),
    .io_maskOut_12_3_10                 (dm_mask_out[12][3][10]),
    .io_maskOut_12_3_11                 (dm_mask_out[12][3][11]),
    .io_maskOut_12_3_12                 (dm_mask_out[12][3][12]),
    .io_maskOut_12_3_13                 (dm_mask_out[12][3][13]),
    .io_maskOut_12_3_14                 (dm_mask_out[12][3][14]),
    .io_maskOut_12_3_15                 (dm_mask_out[12][3][15]),
    .io_maskOut_13_0_0                  (dm_mask_out[13][0][0]),
    .io_maskOut_13_0_1                  (dm_mask_out[13][0][1]),
    .io_maskOut_13_0_2                  (dm_mask_out[13][0][2]),
    .io_maskOut_13_0_3                  (dm_mask_out[13][0][3]),
    .io_maskOut_13_0_4                  (dm_mask_out[13][0][4]),
    .io_maskOut_13_0_5                  (dm_mask_out[13][0][5]),
    .io_maskOut_13_0_6                  (dm_mask_out[13][0][6]),
    .io_maskOut_13_0_7                  (dm_mask_out[13][0][7]),
    .io_maskOut_13_0_8                  (dm_mask_out[13][0][8]),
    .io_maskOut_13_0_9                  (dm_mask_out[13][0][9]),
    .io_maskOut_13_0_10                 (dm_mask_out[13][0][10]),
    .io_maskOut_13_0_11                 (dm_mask_out[13][0][11]),
    .io_maskOut_13_0_12                 (dm_mask_out[13][0][12]),
    .io_maskOut_13_0_13                 (dm_mask_out[13][0][13]),
    .io_maskOut_13_0_14                 (dm_mask_out[13][0][14]),
    .io_maskOut_13_0_15                 (dm_mask_out[13][0][15]),
    .io_maskOut_13_1_0                  (dm_mask_out[13][1][0]),
    .io_maskOut_13_1_1                  (dm_mask_out[13][1][1]),
    .io_maskOut_13_1_2                  (dm_mask_out[13][1][2]),
    .io_maskOut_13_1_3                  (dm_mask_out[13][1][3]),
    .io_maskOut_13_1_4                  (dm_mask_out[13][1][4]),
    .io_maskOut_13_1_5                  (dm_mask_out[13][1][5]),
    .io_maskOut_13_1_6                  (dm_mask_out[13][1][6]),
    .io_maskOut_13_1_7                  (dm_mask_out[13][1][7]),
    .io_maskOut_13_1_8                  (dm_mask_out[13][1][8]),
    .io_maskOut_13_1_9                  (dm_mask_out[13][1][9]),
    .io_maskOut_13_1_10                 (dm_mask_out[13][1][10]),
    .io_maskOut_13_1_11                 (dm_mask_out[13][1][11]),
    .io_maskOut_13_1_12                 (dm_mask_out[13][1][12]),
    .io_maskOut_13_1_13                 (dm_mask_out[13][1][13]),
    .io_maskOut_13_1_14                 (dm_mask_out[13][1][14]),
    .io_maskOut_13_1_15                 (dm_mask_out[13][1][15]),
    .io_maskOut_13_2_0                  (dm_mask_out[13][2][0]),
    .io_maskOut_13_2_1                  (dm_mask_out[13][2][1]),
    .io_maskOut_13_2_2                  (dm_mask_out[13][2][2]),
    .io_maskOut_13_2_3                  (dm_mask_out[13][2][3]),
    .io_maskOut_13_2_4                  (dm_mask_out[13][2][4]),
    .io_maskOut_13_2_5                  (dm_mask_out[13][2][5]),
    .io_maskOut_13_2_6                  (dm_mask_out[13][2][6]),
    .io_maskOut_13_2_7                  (dm_mask_out[13][2][7]),
    .io_maskOut_13_2_8                  (dm_mask_out[13][2][8]),
    .io_maskOut_13_2_9                  (dm_mask_out[13][2][9]),
    .io_maskOut_13_2_10                 (dm_mask_out[13][2][10]),
    .io_maskOut_13_2_11                 (dm_mask_out[13][2][11]),
    .io_maskOut_13_2_12                 (dm_mask_out[13][2][12]),
    .io_maskOut_13_2_13                 (dm_mask_out[13][2][13]),
    .io_maskOut_13_2_14                 (dm_mask_out[13][2][14]),
    .io_maskOut_13_2_15                 (dm_mask_out[13][2][15]),
    .io_maskOut_13_3_0                  (dm_mask_out[13][3][0]),
    .io_maskOut_13_3_1                  (dm_mask_out[13][3][1]),
    .io_maskOut_13_3_2                  (dm_mask_out[13][3][2]),
    .io_maskOut_13_3_3                  (dm_mask_out[13][3][3]),
    .io_maskOut_13_3_4                  (dm_mask_out[13][3][4]),
    .io_maskOut_13_3_5                  (dm_mask_out[13][3][5]),
    .io_maskOut_13_3_6                  (dm_mask_out[13][3][6]),
    .io_maskOut_13_3_7                  (dm_mask_out[13][3][7]),
    .io_maskOut_13_3_8                  (dm_mask_out[13][3][8]),
    .io_maskOut_13_3_9                  (dm_mask_out[13][3][9]),
    .io_maskOut_13_3_10                 (dm_mask_out[13][3][10]),
    .io_maskOut_13_3_11                 (dm_mask_out[13][3][11]),
    .io_maskOut_13_3_12                 (dm_mask_out[13][3][12]),
    .io_maskOut_13_3_13                 (dm_mask_out[13][3][13]),
    .io_maskOut_13_3_14                 (dm_mask_out[13][3][14]),
    .io_maskOut_13_3_15                 (dm_mask_out[13][3][15]),
    .io_maskOut_14_0_0                  (dm_mask_out[14][0][0]),
    .io_maskOut_14_0_1                  (dm_mask_out[14][0][1]),
    .io_maskOut_14_0_2                  (dm_mask_out[14][0][2]),
    .io_maskOut_14_0_3                  (dm_mask_out[14][0][3]),
    .io_maskOut_14_0_4                  (dm_mask_out[14][0][4]),
    .io_maskOut_14_0_5                  (dm_mask_out[14][0][5]),
    .io_maskOut_14_0_6                  (dm_mask_out[14][0][6]),
    .io_maskOut_14_0_7                  (dm_mask_out[14][0][7]),
    .io_maskOut_14_0_8                  (dm_mask_out[14][0][8]),
    .io_maskOut_14_0_9                  (dm_mask_out[14][0][9]),
    .io_maskOut_14_0_10                 (dm_mask_out[14][0][10]),
    .io_maskOut_14_0_11                 (dm_mask_out[14][0][11]),
    .io_maskOut_14_0_12                 (dm_mask_out[14][0][12]),
    .io_maskOut_14_0_13                 (dm_mask_out[14][0][13]),
    .io_maskOut_14_0_14                 (dm_mask_out[14][0][14]),
    .io_maskOut_14_0_15                 (dm_mask_out[14][0][15]),
    .io_maskOut_14_1_0                  (dm_mask_out[14][1][0]),
    .io_maskOut_14_1_1                  (dm_mask_out[14][1][1]),
    .io_maskOut_14_1_2                  (dm_mask_out[14][1][2]),
    .io_maskOut_14_1_3                  (dm_mask_out[14][1][3]),
    .io_maskOut_14_1_4                  (dm_mask_out[14][1][4]),
    .io_maskOut_14_1_5                  (dm_mask_out[14][1][5]),
    .io_maskOut_14_1_6                  (dm_mask_out[14][1][6]),
    .io_maskOut_14_1_7                  (dm_mask_out[14][1][7]),
    .io_maskOut_14_1_8                  (dm_mask_out[14][1][8]),
    .io_maskOut_14_1_9                  (dm_mask_out[14][1][9]),
    .io_maskOut_14_1_10                 (dm_mask_out[14][1][10]),
    .io_maskOut_14_1_11                 (dm_mask_out[14][1][11]),
    .io_maskOut_14_1_12                 (dm_mask_out[14][1][12]),
    .io_maskOut_14_1_13                 (dm_mask_out[14][1][13]),
    .io_maskOut_14_1_14                 (dm_mask_out[14][1][14]),
    .io_maskOut_14_1_15                 (dm_mask_out[14][1][15]),
    .io_maskOut_14_2_0                  (dm_mask_out[14][2][0]),
    .io_maskOut_14_2_1                  (dm_mask_out[14][2][1]),
    .io_maskOut_14_2_2                  (dm_mask_out[14][2][2]),
    .io_maskOut_14_2_3                  (dm_mask_out[14][2][3]),
    .io_maskOut_14_2_4                  (dm_mask_out[14][2][4]),
    .io_maskOut_14_2_5                  (dm_mask_out[14][2][5]),
    .io_maskOut_14_2_6                  (dm_mask_out[14][2][6]),
    .io_maskOut_14_2_7                  (dm_mask_out[14][2][7]),
    .io_maskOut_14_2_8                  (dm_mask_out[14][2][8]),
    .io_maskOut_14_2_9                  (dm_mask_out[14][2][9]),
    .io_maskOut_14_2_10                 (dm_mask_out[14][2][10]),
    .io_maskOut_14_2_11                 (dm_mask_out[14][2][11]),
    .io_maskOut_14_2_12                 (dm_mask_out[14][2][12]),
    .io_maskOut_14_2_13                 (dm_mask_out[14][2][13]),
    .io_maskOut_14_2_14                 (dm_mask_out[14][2][14]),
    .io_maskOut_14_2_15                 (dm_mask_out[14][2][15]),
    .io_maskOut_14_3_0                  (dm_mask_out[14][3][0]),
    .io_maskOut_14_3_1                  (dm_mask_out[14][3][1]),
    .io_maskOut_14_3_2                  (dm_mask_out[14][3][2]),
    .io_maskOut_14_3_3                  (dm_mask_out[14][3][3]),
    .io_maskOut_14_3_4                  (dm_mask_out[14][3][4]),
    .io_maskOut_14_3_5                  (dm_mask_out[14][3][5]),
    .io_maskOut_14_3_6                  (dm_mask_out[14][3][6]),
    .io_maskOut_14_3_7                  (dm_mask_out[14][3][7]),
    .io_maskOut_14_3_8                  (dm_mask_out[14][3][8]),
    .io_maskOut_14_3_9                  (dm_mask_out[14][3][9]),
    .io_maskOut_14_3_10                 (dm_mask_out[14][3][10]),
    .io_maskOut_14_3_11                 (dm_mask_out[14][3][11]),
    .io_maskOut_14_3_12                 (dm_mask_out[14][3][12]),
    .io_maskOut_14_3_13                 (dm_mask_out[14][3][13]),
    .io_maskOut_14_3_14                 (dm_mask_out[14][3][14]),
    .io_maskOut_14_3_15                 (dm_mask_out[14][3][15]),
    .io_maskOut_15_0_0                  (dm_mask_out[15][0][0]),
    .io_maskOut_15_0_1                  (dm_mask_out[15][0][1]),
    .io_maskOut_15_0_2                  (dm_mask_out[15][0][2]),
    .io_maskOut_15_0_3                  (dm_mask_out[15][0][3]),
    .io_maskOut_15_0_4                  (dm_mask_out[15][0][4]),
    .io_maskOut_15_0_5                  (dm_mask_out[15][0][5]),
    .io_maskOut_15_0_6                  (dm_mask_out[15][0][6]),
    .io_maskOut_15_0_7                  (dm_mask_out[15][0][7]),
    .io_maskOut_15_0_8                  (dm_mask_out[15][0][8]),
    .io_maskOut_15_0_9                  (dm_mask_out[15][0][9]),
    .io_maskOut_15_0_10                 (dm_mask_out[15][0][10]),
    .io_maskOut_15_0_11                 (dm_mask_out[15][0][11]),
    .io_maskOut_15_0_12                 (dm_mask_out[15][0][12]),
    .io_maskOut_15_0_13                 (dm_mask_out[15][0][13]),
    .io_maskOut_15_0_14                 (dm_mask_out[15][0][14]),
    .io_maskOut_15_0_15                 (dm_mask_out[15][0][15]),
    .io_maskOut_15_1_0                  (dm_mask_out[15][1][0]),
    .io_maskOut_15_1_1                  (dm_mask_out[15][1][1]),
    .io_maskOut_15_1_2                  (dm_mask_out[15][1][2]),
    .io_maskOut_15_1_3                  (dm_mask_out[15][1][3]),
    .io_maskOut_15_1_4                  (dm_mask_out[15][1][4]),
    .io_maskOut_15_1_5                  (dm_mask_out[15][1][5]),
    .io_maskOut_15_1_6                  (dm_mask_out[15][1][6]),
    .io_maskOut_15_1_7                  (dm_mask_out[15][1][7]),
    .io_maskOut_15_1_8                  (dm_mask_out[15][1][8]),
    .io_maskOut_15_1_9                  (dm_mask_out[15][1][9]),
    .io_maskOut_15_1_10                 (dm_mask_out[15][1][10]),
    .io_maskOut_15_1_11                 (dm_mask_out[15][1][11]),
    .io_maskOut_15_1_12                 (dm_mask_out[15][1][12]),
    .io_maskOut_15_1_13                 (dm_mask_out[15][1][13]),
    .io_maskOut_15_1_14                 (dm_mask_out[15][1][14]),
    .io_maskOut_15_1_15                 (dm_mask_out[15][1][15]),
    .io_maskOut_15_2_0                  (dm_mask_out[15][2][0]),
    .io_maskOut_15_2_1                  (dm_mask_out[15][2][1]),
    .io_maskOut_15_2_2                  (dm_mask_out[15][2][2]),
    .io_maskOut_15_2_3                  (dm_mask_out[15][2][3]),
    .io_maskOut_15_2_4                  (dm_mask_out[15][2][4]),
    .io_maskOut_15_2_5                  (dm_mask_out[15][2][5]),
    .io_maskOut_15_2_6                  (dm_mask_out[15][2][6]),
    .io_maskOut_15_2_7                  (dm_mask_out[15][2][7]),
    .io_maskOut_15_2_8                  (dm_mask_out[15][2][8]),
    .io_maskOut_15_2_9                  (dm_mask_out[15][2][9]),
    .io_maskOut_15_2_10                 (dm_mask_out[15][2][10]),
    .io_maskOut_15_2_11                 (dm_mask_out[15][2][11]),
    .io_maskOut_15_2_12                 (dm_mask_out[15][2][12]),
    .io_maskOut_15_2_13                 (dm_mask_out[15][2][13]),
    .io_maskOut_15_2_14                 (dm_mask_out[15][2][14]),
    .io_maskOut_15_2_15                 (dm_mask_out[15][2][15]),
    .io_maskOut_15_3_0                  (dm_mask_out[15][3][0]),
    .io_maskOut_15_3_1                  (dm_mask_out[15][3][1]),
    .io_maskOut_15_3_2                  (dm_mask_out[15][3][2]),
    .io_maskOut_15_3_3                  (dm_mask_out[15][3][3]),
    .io_maskOut_15_3_4                  (dm_mask_out[15][3][4]),
    .io_maskOut_15_3_5                  (dm_mask_out[15][3][5]),
    .io_maskOut_15_3_6                  (dm_mask_out[15][3][6]),
    .io_maskOut_15_3_7                  (dm_mask_out[15][3][7]),
    .io_maskOut_15_3_8                  (dm_mask_out[15][3][8]),
    .io_maskOut_15_3_9                  (dm_mask_out[15][3][9]),
    .io_maskOut_15_3_10                 (dm_mask_out[15][3][10]),
    .io_maskOut_15_3_11                 (dm_mask_out[15][3][11]),
    .io_maskOut_15_3_12                 (dm_mask_out[15][3][12]),
    .io_maskOut_15_3_13                 (dm_mask_out[15][3][13]),
    .io_maskOut_15_3_14                 (dm_mask_out[15][3][14]),
    .io_maskOut_15_3_15                 (dm_mask_out[15][3][15])
  );
  // END GENERATED(datamodule_inst)

  StorePfWrapper prefetcher (
    .clock (clock),
    .reset (reset)
  );

endmodule
