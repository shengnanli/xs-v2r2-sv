// =============================================================================
//  loadqueuerar_pkg —— LoadQueueRAR（load-load 违例检测队列）可读重写用的
//                      类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAR.scala
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala（LqPAddrModule）
//
//  ── LoadQueueRAR 是干什么的（RAR = Read-After-Read 违例检测）──────────────────
//  乱序处理器允许同一物理地址上的两条 load 乱序执行。RVWMO 内存模型要求：在“同一
//  地址”的两条 load 之间，如果中间发生了别的核对该 cacheline 的写（通过 L2 的
//  release/probe 通知本核 DCache 失效），那么“较老的 load 拿到旧值、较新的 load 已经
//  先执行拿到新值”这种乱序结果是**非法**的（会破坏 coherence 顺序）。
//
//  LoadQueueRAR 维护所有“已经在 DCache 命中拿到数据、但还没提交（retire）”的 load。
//  对每条新执行的 load 做一次 CAM 查询：若队列里存在一条
//      ① 物理地址同 cacheline（部分地址哈希匹配）；
//      ② 该条目的 cacheline 已经被 release（别的核写过）/ 或是 nc_with_data；
//      ③ 该条目比当前 load **更年轻**（robIdx 更大）；
//  则说明“较新的那条 load 已经先于当前老 load 执行、且其数据已被 invalidate”——
//  当前 load 必须从取指阶段重新执行（rep_frm_fetch），把违例 squash 掉。
//
//  ── 队列条目字段（每 entry）──────────────────────────────────────────────────
//      allocated : 该 entry 是否有效（占用）。
//      uop       : 关联的 micro-op（这里只需 robIdx 判年龄 + lqIdx 判出队）。
//      paddr     : 物理地址的 16-bit 哈希（PartialPAddr），用于 CAM 匹配。
//      released  : 该条目的 cacheline 已被 DCache release（或 nc_with_data），即“失效过”。
//
//  ── 三段时序要点 ────────────────────────────────────────────────────────────
//   (1) 入队在 load_s2（query.req）：分配 freelist 槽、写 paddr 哈希、填 uop、置 released。
//       paddr 写需要 1 拍才可见，故 release 信号要延 1 拍（release2Cycle）让入队能追上。
//   (2) 查询 resp 比入队晚 1 拍（resp.valid = RegNext(req.valid)，matchMask 也打 1 拍）。
//   (3) release1Cycle 那一拍用最后一个 CAM 口现场更新已有条目的 released 标志（延 1 拍写回）。
//
//  ── freelist（FreeList.scala）────────────────────────────────────────────────
//  存“空闲 entry 的 index”的循环队列：headPtr 出队分配、tailPtr 入队回收。
//  allocWidth=3（3 个 load 流水口同拍各分配 1 个），freeWidth=4（每拍最多回收 4 个）。
//  回收口按 entry 编号模 freeWidth 分 rem-bank，PriorityEncoder 各选一个，打 1 拍写回。
//  validCount = size - 空闲槽数；empty(=lqFull) 表示无空闲槽。
// =============================================================================
package loadqueuerar_pkg;

  // ---- 关键参数（与香山 KunmingHu V2R2 配置一致）-----------------------------
  localparam int RAR_SIZE   = 72;  // LoadQueueRARSize：队列条目数
  localparam int LD_WIDTH   = 3;   // LoadPipelineWidth：load 流水/查询口数
  localparam int N_WBANK    = 8;   // LoadQueueNWriteBanks：paddr 写 bank 数（本核未用 bank 分时序，numWDelay=1）
  localparam int FREE_WIDTH = 4;   // FreeList freeWidth：每拍最多回收的条目数
  localparam int IDX_W      = 7;   // log2Up(72) = 7：entry index 位宽
  localparam int CNT_W      = 7;   // validCount 位宽（0..72）

  localparam int PADDR_BITS = 48;  // 物理地址位宽
  localparam int ROB_W      = 8;   // robIdx.value 位宽
  localparam int LQ_W       = 7;   // lqIdx.value 位宽
  localparam int DCACHE_LINE_OFF = 6;  // DCacheLineOffset：cacheline 内偏移位数（64B 行）

  // ---- PartialPAddr 哈希参数（见 Scala genPartialPAddr）-----------------------
  //   把 48-bit 物理地址异或折叠成 16-bit 哈希，做 CAM 匹配（省 CAM 位宽）。
  //   低 5 位 + 高 11 位，按 Scala 的 lowMapping/highMapping 折叠。
  localparam int PP_STRIDE   = 6;
  localparam int PP_BITS     = 16;
  localparam int PP_LOW_BITS = (PP_BITS - PP_STRIDE) / 2;  // = 5
  localparam int PP_HIGH_BITS = PP_BITS - PP_LOW_BITS;     // = 11

  // ===========================================================================
  //  循环指针类型：robIdx / lqIdx / freelist 指针均用 {flag, value} 表达环形队列
  // ===========================================================================
  typedef struct packed {
    logic              flag;          // 环形 wrap 标志（每绕一圈翻转）
    logic [ROB_W-1:0]  value;
  } rob_ptr_t;

  typedef struct packed {
    logic              flag;
    logic [LQ_W-1:0]   value;
  } lq_ptr_t;

  // freelist 内部 head/tail 指针：value 宽 = IDX_W（0..size-1），多 1 bit flag 区分空满
  typedef struct packed {
    logic              flag;
    logic [IDX_W-1:0]  value;
  } free_ptr_t;

  // ---- 入队时“为何把条目标记为 released（已失效）”的离散原因（仅用于阅读/分类）----
  //   一条 load 在入队那拍被立即置 released 的可能原因，按设计意图分类：
  //     REL_NONE       : 不立即失效（普通命中、且未撞上 release）。
  //     REL_NC         : NC（non-cacheable）请求——不会被显式 release，按约定直接视为失效，
  //                      使其永不参与 RAR 命中（NC 不允许 RAR）。
  //     REL_HIT_CYCLE1 : 入队同拍 io.release（release1Cycle）命中本条 cacheline（[47:6] 相等）。
  //     REL_HIT_CYCLE2 : 入队时延 1 拍的 release2Cycle 命中本条 cacheline。
  //   优先级：NC > cycle1 > cycle2 > none（最终 released = 该原因是否非 NONE）。
  typedef enum logic [1:0] {
    REL_NONE       = 2'd0,
    REL_NC         = 2'd1,
    REL_HIT_CYCLE1 = 2'd2,
    REL_HIT_CYCLE2 = 2'd3
  } released_cause_e;

  // ===========================================================================
  //  队列条目（每 entry 一份）
  // ===========================================================================
  typedef struct packed {
    logic                allocated;    // 占用标志
    rob_ptr_t            robIdx;       // 关联 uop 的 robIdx（判年龄 / 冲刷）
    lq_ptr_t             lqIdx;        // 关联 uop 的 lqIdx（判“老于 ldWbPtr”可出队）
    logic                released;     // cacheline 已被 release（失效过）
    logic [PP_BITS-1:0]  ppaddr;       // 16-bit 物理地址哈希（CAM 匹配键）
  } rar_entry_t;

  // ===========================================================================
  //  纯函数区
  // ===========================================================================

  // ---- genPartialPAddr：48-bit paddr → 16-bit 哈希（与 Scala 完全一致）--------
  //   高 11 位：bit i 折叠 {paddr[i+6], paddr[i+17], paddr[i+28], paddr[i+39]}（越界丢弃）。
  //   低 5  位：bit i 折叠 {paddr[i+6], paddr[15-i]}。
  //   输出 = {high[10:0], low[4:0]}（高位在前，与 Chisel Cat(high, low) 一致）。
  function automatic logic [PP_BITS-1:0] gen_partial_paddr(input logic [PADDR_BITS-1:0] paddr);
    logic [PP_HIGH_BITS-1:0] high;
    logic [PP_LOW_BITS-1:0]  low;
    for (int i = 0; i < PP_HIGH_BITS; i++) begin
      logic b;
      b = paddr[i + PP_STRIDE];                          // i+6，恒 <48
      b ^= paddr[i + PP_STRIDE + 11];                    // i+17
      b ^= paddr[i + PP_STRIDE + 22];                    // i+28
      if (i + PP_STRIDE + 33 < PADDR_BITS)               // i+39 仅 i<=8 有效
        b ^= paddr[i + PP_STRIDE + 33];
      high[i] = b;
    end
    for (int i = 0; i < PP_LOW_BITS; i++) begin
      // boundary(6+i,16) 恒有效；boundary(15-i,16) 恒有效
      low[i] = paddr[PP_STRIDE + i] ^ paddr[PP_BITS - i - 1];
    end
    return {high, low};
  endfunction

  // ---- 环形指针比较（HasCircularQueuePtrHelper）------------------------------
  //   isAfter(a,b)：a 是否“比 b 更年轻/更靠后”。环形比较：异 flag 时 value 小的反而更靠后。
  function automatic logic ptr_is_after_rob(input rob_ptr_t a, input rob_ptr_t b);
    // 当 a==b 时（同 flag 同 value）结果为 0：a 不晚于自身。
    // 不同 flag 且 value 相等 → a 比 b 晚整整一圈 → true。
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // isBefore(a,b)：a 是否比 b 更老/更靠前。
  function automatic logic ptr_is_before_lq(input lq_ptr_t a, input lq_ptr_t b);
    return a.flag ^ b.flag ^ (a.value < b.value);
  endfunction

  // ---- robIdx.needFlush(redirect)：当前 uop 是否被本次重定向冲刷 ---------------
  //   level=1（异常/flushPipe 型）：含自身在内、robIdx >= redirect 的都冲刷；
  //   分支误预测型：仅排在 redirect **之后**（更年轻）的冲刷。
  function automatic logic rob_need_flush(
      input logic     redir_valid,
      input logic     redir_level,
      input rob_ptr_t self,
      input rob_ptr_t redir);
    logic flush_itself, flush_after;
    flush_itself = redir_level & (self.flag == redir.flag) & (self.value == redir.value);
    flush_after  = self.flag ^ redir.flag ^ (self.value > redir.value);
    return redir_valid & (flush_itself | flush_after);
  endfunction

  // ---- 环形距离 distanceBetween(enq, deq)（FreeList 用，求队列内有效数）--------
  //   同 flag：enq.value - deq.value；异 flag：size - deq.value + enq.value。
  function automatic logic [CNT_W:0] free_distance(
      input free_ptr_t enq, input free_ptr_t deq);
    logic [CNT_W:0] d;
    if (enq.flag == deq.flag)
      d = {1'b0, enq.value} - {1'b0, deq.value};
    else
      d = (RAR_SIZE[CNT_W:0] - {1'b0, deq.value}) + {1'b0, enq.value};
    return d;
  endfunction

endpackage
