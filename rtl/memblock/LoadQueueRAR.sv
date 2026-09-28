// =============================================================================
// LoadQueueRAR.sv —— load 队列的 RAR（load→load 读后读）违例检测队列
//
// 对应 Chisel: xiangshan.mem.LoadQueueRAR（src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAR.scala）
//
// 在流水线里的位置：
//     load 流水 s2 ──query.req──> LoadQueueRAR ──query.resp（下一拍）──> load 流水 s3
//                                     ▲    rep_frm_fetch=1：这条 load 要从取指重来
//     DCache ──release（cacheline 被换出/被别的核拿走）──┘
//
// 问题：RISC-V 的 RVWMO 要求**同地址**的两条 load 保序（读后读一致）。乱序核里年轻的
// load 可能先读到数据，老的后读；两次读之间如果别的核改了这条 cacheline（本核会看到
// 一次 release），老的读到新值、年轻的读到旧值 —— 顺序被看穿了，这是 RAR 违例。
// 本队列就是为此存档的：
//   1. 入队：load 在 s2 拿到数据时，若它前面还有**没写回的 load**（lqIdx 在 ldWbPtr 之后），
//      就占一个槽，记下 robIdx / lqIdx / 16 位折叠 paddr，以及 released 标志：
//        released = is_nc || (data_valid && 本拍或"两拍前"有同 cacheline 的 release)
//      （NC 访问不会被 release，干脆当成已 released —— 相当于对 NC 不做 RAR 保护的反面：
//        任何年轻的同地址 NC load 都会被判违例，保守正确）。
//      槽位由 FreeList 分配；满了就回 ready=0 让 load 去 replay。
//   2. 出队：它前面的 load 都写回了（ldWbPtr 追上它），或被 redirect 冲掉，槽就释放；
//      load 在下一拍被 revoke（自己要 replay）时，上一拍刚分到的槽也立即归还。
//   3. release：DCache release 一条 cacheline 时，用折叠 paddr 反查（CAM）全部 72 个槽，
//      命中且在队的槽**下一拍**置 released=1。
//   4. 检测：每条 load 流水来一个 query，就用它的折叠 paddr 反查全部槽：
//      同地址 && 槽在队 && 槽里的 load 比本 load **年轻**（robIdx 在其后）&& 已 released
//      —— 年轻的先读了、之后那条 cacheline 又被 release 过，于是本（老）load 可能读到比
//      它更新的值，必须让**年轻的**那些重来。硬件做法是给本 load 回 rep_frm_fetch，
//      由上游决定重取指（Chisel 注释：Load-to-Load violation check）。
//      匹配向量先 RegEnable 打一拍，resp 在下一拍给出。
//
// 子模块（golden 同名例化，都已签核或本 lane 签核）：
//   LqPAddrModule —— 72 项折叠 paddr CAM 阵列（本 lane 重写，rtl/memblock/LqPAddrModule.sv）
//   FreeList_3    —— 72 项槽位空闲表（3 分配口，按位 free；rtl/memblock/FreeList.sv 家族核）
//
// ★golden 的怪癖（照抄，不"修"）：
//   · release2Cycle 的 valid 实际是 io.release.valid **打两拍**，不是注释说的一拍：
//     Chisel 写的是 `release2Cycle = RegEnable(io.release, io.release.valid)` 之后又
//     `release2Cycle.valid := RegNext(io.release.valid)` —— 后者给寄存器的 valid 字段
//     重新连了 next 值，于是 valid = RegNext(RegNext(io.release.valid))，而 paddr 仍是
//     RegEnable（最近一次 release 的地址）。golden 就是这个结构
//     （release2Cycle_valid_REG -> release2Cycle_valid），本文件同样两级。
//   · release2Cycle 的 paddr 按 48 位全宽打拍，只用 [47:6]；[5:0] 是两侧对称的死位
//     （照抄 golden 位宽，不收窄 —— 收窄会变成 golden-only 死位）。
//   · lastCanAccept / lastAllocIndex 是 GatedRegNext：值变了才打拍，功能上等于 RegNext，
//     但照 golden 写成"不同才更新"（逐个元素门控）。
//   · FreeList 分配口按 offset（前面要入队的条数）选；offset 最大为 2，
//     golden 把它展开成 4 项查找表、第 3 项回落到 0 号口，本文件同形。
//
// ★golden 里被 firtool 消掉、因此本文件也不写的东西：uop 的其余字段（只剩 robIdx / lqIdx）、
//   query.resp 里除 rep_frm_fetch 以外的字段、XSError 断言、QueuePerf 的探针。
//
// 复位域（与 golden 两个 always 块逐个对齐）：
//   异步复位：allocated / released / lastCanAccept / lastAllocIndex
//   不复位  ：uop 各字段 / ldLdViolationMask / release 命中打拍（releaseHit_q）/
//             release2Cycle（valid 两级与 paddr）/ resp.valid 打拍 / perf
//
// 本文件导航：
//   package loadqueuerar_pkg ……… 配置常量、指针与总线类型、环形指针比较、折叠 paddr
//   xs_LoadQueueRAR_core ……… §1 入队  §2 槽状态  §3 出队/撤销  §4 release  §5 违例检测  §6 输出与 perf
//   LoadQueueRAR（wrapper）……… golden 端口表 <-> 核的结构体端口（scripts/gen_lqrar.py 生成）
// =============================================================================
package loadqueuerar_pkg;

  // ---- KunminghuV2Config 下的配置常量（由 golden 端口/寄存器数量核实）----
  localparam int RAR_SIZE   = 72;   // LoadQueueRARSize
  localparam int IDX_W      = 7;    // log2Up(72)
  localparam int LD_W       = 3;    // LoadPipelineWidth
  localparam int PADDR_W    = 48;   // PAddrBits
  localparam int LINE_OFF   = 6;    // DCacheLineOffset：64B cacheline
  localparam int PPADDR_W   = 16;   // PartialPAddrBits：折叠后的地址宽度

  // ---- 环形队列指针（utility.CircularQueuePtr）：{flag,value}，flag = 绕圈奇偶 ----
  typedef struct packed { logic flag; logic [7:0] value; } rob_ptr_t;  // RobSize 256
  typedef struct packed { logic flag; logic [6:0] value; } lq_ptr_t;   // VirtualLoadQueueSize 72

  // redirect：golden 只剩 valid / robIdx / level 三个字段
  typedef struct packed {
    logic     valid;
    rob_ptr_t robIdx;
    logic     level;       // 1 = flush（连 robIdx 自己也冲掉）
  } redirect_t;

  // load 流水的查询/入队请求（query.req，golden 剩下的字段）
  typedef struct packed {
    logic               valid;
    rob_ptr_t           robIdx;      // uop.robIdx
    lq_ptr_t            lqIdx;       // uop.lqIdx
    logic [PADDR_W-1:0] paddr;
    logic               data_valid;  // 这条 load 已经拿到数据
    logic               is_nc;       // 非缓存（NC）访问
  } query_req_t;

  // DCache 的 release 通知
  typedef struct packed {
    logic               valid;
    logic [PADDR_W-1:0] paddr;
  } release_t;

  // ---- 环形指针比较 ----
  // a 比 b 年轻（在 b 之后）？同圈比 value，异圈反过来。
  function automatic logic rob_is_after(input rob_ptr_t a, input rob_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  function automatic logic lq_is_after(input lq_ptr_t a, input lq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  // a 比 b 老（在 b 之前）？
  function automatic logic lq_is_before(input lq_ptr_t a, input lq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value < b.value);
  endfunction

  // RobPtr.needFlush：这条指令会被这次 redirect 冲掉吗？
  //   level=1（flush）时 robIdx 本身也冲；否则只冲它之后的。
  function automatic logic need_flush(input rob_ptr_t self, input redirect_t rd);
    return rd.valid & ((rd.level & (self == rd.robIdx)) | rob_is_after(self, rd.robIdx));
  endfunction

  // genPartialPAddr：把 paddr[47:6]（cacheline 号）异或折叠成 16 位，作为 CAM 的键。
  //   低 5 位 low[i]  = paddr[6+i] ^ paddr[15-i]            （i = 0..4，一对首尾相映）
  //   高 11 位 high[i] = paddr[6+i] ^ paddr[17+i] ^ paddr[28+i] ^ paddr[39+i]
  //                                                         （i = 0..10，每隔 11 位取一位；
  //                                                           39+i 超过 47 的项不存在）
  //   结果 = {high, low}。折叠有损：不同 cacheline 可能撞同一个键 —— 撞了只会多报违例
  //   （让 load 多重来一次），不会漏报，所以功能正确。
  function automatic logic [PPADDR_W-1:0] gen_partial_paddr(input logic [PADDR_W-1:0] paddr);
    logic [4:0]  low;
    logic [10:0] high;
    for (int i = 0; i < 5; i++)
      low[i] = paddr[6 + i] ^ paddr[15 - i];
    for (int i = 0; i < 11; i++) begin
      high[i] = paddr[6 + i] ^ paddr[17 + i] ^ paddr[28 + i];
      if (39 + i < PADDR_W) high[i] = high[i] ^ paddr[39 + i];
    end
    return {high, low};
  endfunction

  // 同一条 cacheline？（released 判定用全宽比较，不用折叠键）
  function automatic logic same_line(input logic [PADDR_W-1:0] a, input logic [PADDR_W-1:0] b);
    return a[PADDR_W-1:LINE_OFF] == b[PADDR_W-1:LINE_OFF];
  endfunction

endpackage


// -----------------------------------------------------------------------------
// xs_LoadQueueRAR_core —— 可读核
// -----------------------------------------------------------------------------
module xs_LoadQueueRAR_core
  import loadqueuerar_pkg::*;
(
  input  logic                   clock,
  input  logic                   reset,

  input  redirect_t              io_redirect,

  // load 流水的查询/入队（3 条）
  input  query_req_t [LD_W-1:0]  io_query_req,
  output logic       [LD_W-1:0]  io_query_req_ready,
  output logic       [LD_W-1:0]  io_query_resp_valid,          // = RegNext(req.valid)
  output logic       [LD_W-1:0]  io_query_resp_rep_frm_fetch,  // 有 RAR 违例：从取指重来
  input  logic       [LD_W-1:0]  io_query_revoke,              // 上一拍入队的 load 要 replay：退回槽位

  input  release_t               io_release,
  input  lq_ptr_t                io_ldWbPtr,                   // VirtualLoadQueue：写回到哪了

  output logic                   io_lqFull,
  output logic [5:0]             io_perf_0_value,              // 本拍入队条数（打两拍）
  output logic [5:0]             io_perf_1_value               // 本拍违例条数（打两拍）
);

  // ===========================================================================
  // 槽状态：per-field 数组（SoA），与 golden 的扁平命名一一对应
  // ===========================================================================
  logic                 allocated        [RAR_SIZE];  // 槽被占用（异步复位）
  logic                 released         [RAR_SIZE];  // 该 cacheline 已被 release 过（异步复位）
  logic                 uop_robIdx_flag  [RAR_SIZE];  // 以下 uop 字段不复位
  logic [7:0]           uop_robIdx_value [RAR_SIZE];
  logic                 uop_lqIdx_flag   [RAR_SIZE];
  logic [6:0]           uop_lqIdx_value  [RAR_SIZE];

  rob_ptr_t             uop_robIdx       [RAR_SIZE];
  lq_ptr_t              uop_lqIdx        [RAR_SIZE];
  always_comb
    for (int i = 0; i < RAR_SIZE; i++) begin
      uop_robIdx[i] = rob_ptr_t'{flag: uop_robIdx_flag[i], value: uop_robIdx_value[i]};
      uop_lqIdx[i]  = lq_ptr_t'{flag: uop_lqIdx_flag[i], value: uop_lqIdx_value[i]};
    end

  // 每条 load 请求的折叠 paddr（写进 CAM，也作 releaseViolation 查询键）
  logic [PPADDR_W-1:0] reqPartialPAddr [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++)
      reqPartialPAddr[w] = gen_partial_paddr(io_query_req[w].paddr);

  // ===========================================================================
  // §1 入队
  // ---------------------------------------------------------------------------
  // 只有"前面还有没写回的 load"的 load 才需要进队（lqIdx 在 ldWbPtr 之后）；
  // 被本拍 redirect 冲掉的 load 不进队。
  // 3 条流水按顺序从 FreeList 取槽：第 w 条用第 offset 个分配口，offset = 它前面
  // 要入队的条数。FreeList 口数也是 3，offset 不会到 3（到了也照 golden 回落到 0 号口）。
  // ===========================================================================
  logic [LD_W-1:0]       needEnqueue;
  logic [LD_W-1:0]       acceptedVec;
  logic [1:0]            enqOffset   [LD_W];
  logic                  canAccept   [LD_W];
  logic [IDX_W-1:0]      enqIndexVec [LD_W];

  logic [IDX_W-1:0]      fl_allocateSlot [LD_W];
  logic [LD_W-1:0]       fl_canAllocate;
  logic [6:0]            fl_validCount;
  logic                  fl_empty;

  always_comb
    for (int w = 0; w < LD_W; w++) begin
      needEnqueue[w] = io_query_req[w].valid
                     & lq_is_after(io_query_req[w].lqIdx, io_ldWbPtr)
                     & ~need_flush(io_query_req[w].robIdx, io_redirect);
      enqOffset[w] = '0;
      for (int k = 0; k < w; k++) enqOffset[w] += 2'(needEnqueue[k]);
      canAccept[w]   = fl_canAllocate[0];      // offset 越界（=3）时的回落项
      enqIndexVec[w] = fl_allocateSlot[0];
      for (int k = 0; k < LD_W; k++)
        if (enqOffset[w] == 2'(k)) begin
          canAccept[w]   = fl_canAllocate[k];
          enqIndexVec[w] = fl_allocateSlot[k];
        end
      io_query_req_ready[w] = ~needEnqueue[w] | canAccept[w];
      acceptedVec[w]        = needEnqueue[w] & canAccept[w];
    end

  // ===========================================================================
  // §4（先声明）release：本拍的 io.release 与"两拍前"的 release2Cycle
  // ---------------------------------------------------------------------------
  // 入队时 released 初值要看这两路（Chisel 注释：paddr 写要 2 拍，release 要晚一拍才能
  // 让入队的 load 赶上）。valid 两级打拍、paddr RegEnable —— 见文件头"怪癖"。
  // ===========================================================================
  logic               release2Cycle_valid_REG;   // RegNext(io.release.valid)
  logic               release2Cycle_valid;       // 再打一拍
  logic [PADDR_W-1:0] release2Cycle_bits_paddr;  // RegEnable(io.release.paddr, io.release.valid)

  always_ff @(posedge clock) begin
    release2Cycle_valid_REG <= io_release.valid;
    release2Cycle_valid     <= release2Cycle_valid_REG;
    if (io_release.valid) release2Cycle_bits_paddr <= io_release.paddr;
  end

  // 入队 load 的 released 初值
  logic enqReleased [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++)
      enqReleased[w] = io_query_req[w].is_nc
                     | io_query_req[w].data_valid
                       & (release2Cycle_valid & same_line(io_query_req[w].paddr, release2Cycle_bits_paddr)
                          | io_release.valid & same_line(io_query_req[w].paddr, io_release.paddr));

  // ===========================================================================
  // §2 槽状态更新
  // ---------------------------------------------------------------------------
  // Chisel 的 last-connect 语义决定优先级：
  //   allocated: 保持 < 入队置 1 < 出队清 0 < revoke 清 0   ⇒ next = ~free & (set | allocated)
  //   released : 保持 < 入队写初值（编号大的流水赢）< 上一拍 release 命中置 1
  //   uop      : 多条流水同拍写同一槽（FreeList 保证不会）时，编号大的流水赢。
  // ===========================================================================
  logic                  enqSet       [RAR_SIZE];
  logic [LD_W-1:0]       enqHit       [RAR_SIZE];
  logic                  freeMask     [RAR_SIZE];   // 本拍释放（出队或 revoke），§3 算
  logic                  releaseHit_q [RAR_SIZE];   // 上一拍 release CAM 命中且在队，§4 算

  always_comb
    for (int i = 0; i < RAR_SIZE; i++) begin
      for (int w = 0; w < LD_W; w++)
        enqHit[i][w] = acceptedVec[w] & (enqIndexVec[w] == IDX_W'(i));
      enqSet[i] = |enqHit[i];
    end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < RAR_SIZE; i++) begin
        allocated[i] <= 1'b0;
        released[i]  <= 1'b0;
      end
    end
    else begin
      for (int i = 0; i < RAR_SIZE; i++) begin
        allocated[i] <= ~freeMask[i] & (enqSet[i] | allocated[i]);
        if (releaseHit_q[i])
          released[i] <= 1'b1;
        else
          for (int w = 0; w < LD_W; w++)          // 升序写：编号大的流水最后写、优先
            if (enqHit[i][w]) released[i] <= enqReleased[w];
      end
    end
  end

  always_ff @(posedge clock)
    for (int i = 0; i < RAR_SIZE; i++)
      for (int w = 0; w < LD_W; w++)
        if (enqHit[i][w]) begin
          uop_robIdx_flag[i]  <= io_query_req[w].robIdx.flag;
          uop_robIdx_value[i] <= io_query_req[w].robIdx.value;
          uop_lqIdx_flag[i]   <= io_query_req[w].lqIdx.flag;
          uop_lqIdx_value[i]  <= io_query_req[w].lqIdx.value;
        end

  // ===========================================================================
  // §3 出队与 revoke
  // ---------------------------------------------------------------------------
  // 出队：槽被占用，且（它前面的 load 都写回了：ldWbPtr 不在它之前 或 它被 redirect 冲掉）。
  // revoke：load 入队的下一拍发现自己要 replay，按上一拍记下的槽号退回。
  //   lastCanAccept / lastAllocIndex 是 GatedRegNext：值变了才打拍（异步复位 0）。
  //   revoke 只在"那个槽此刻仍被占用"时生效（读的是本拍的 allocated）。
  // ===========================================================================
  logic                  lastCanAccept  [LD_W];
  logic [IDX_W-1:0]      lastAllocIndex [LD_W];
  logic                  deqFree        [RAR_SIZE];
  logic [LD_W-1:0]       revokeFire;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < LD_W; w++) begin
        lastCanAccept[w]  <= 1'b0;
        lastAllocIndex[w] <= '0;
      end
    end
    else begin
      for (int w = 0; w < LD_W; w++) begin
        if (acceptedVec[w] != lastCanAccept[w])  lastCanAccept[w]  <= acceptedVec[w];
        if (enqIndexVec[w] != lastAllocIndex[w]) lastAllocIndex[w] <= enqIndexVec[w];
      end
    end
  end

  // allocated[lastAllocIndex]：7 位下标读 72 项。Chisel 的动态下标读被 firtool 展开成
  // 2^7 = 128 项查找表，越界项（72..127）全部填 allocated_0 —— 照同一形状写：默认第 0 项，
  // 再逐项常量比较覆盖（不用变量下标，也就没有越界读）。写侧（freeMask）越界时谁也不写。
  logic revokeSlotAllocated [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++) begin
      revokeSlotAllocated[w] = allocated[0];
      for (int i = 1; i < RAR_SIZE; i++)
        if (lastAllocIndex[w] == IDX_W'(i)) revokeSlotAllocated[w] = allocated[i];
    end

  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++) begin
      deqFree[i]  =allocated[i] & (~lq_is_before(io_ldWbPtr, uop_lqIdx[i])
                                    | need_flush(uop_robIdx[i], io_redirect));
      freeMask[i] = deqFree[i];
    end
    for (int w = 0; w < LD_W; w++) begin
      revokeFire[w] = io_query_revoke[w] & lastCanAccept[w] & revokeSlotAllocated[w];
      for (int i = 0; i < RAR_SIZE; i++)
        if (revokeFire[w] && lastAllocIndex[w] == IDX_W'(i)) freeMask[i] = 1'b1;
    end
  end

  logic [RAR_SIZE-1:0] freeMaskBits;
  always_comb
    for (int i = 0; i < RAR_SIZE; i++) freeMaskBits[i] = freeMask[i];

  FreeList_3 freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (fl_allocateSlot[0]),
    .io_allocateSlot_1 (fl_allocateSlot[1]),
    .io_allocateSlot_2 (fl_allocateSlot[2]),
    .io_canAllocate_0  (fl_canAllocate[0]),
    .io_canAllocate_1  (fl_canAllocate[1]),
    .io_canAllocate_2  (fl_canAllocate[2]),
    .io_doAllocate_0   (acceptedVec[0]),
    .io_doAllocate_1   (acceptedVec[1]),
    .io_doAllocate_2   (acceptedVec[2]),
    .io_free           (freeMaskBits),
    .io_validCount     (fl_validCount),
    .io_empty          (fl_empty)
  );

  // ===========================================================================
  // §4 地址 CAM 阵列与 release 命中
  // ---------------------------------------------------------------------------
  // CAM 阵列与入队同步写（写口 = 3 条 load 流水，地址 = 分到的槽号，0 级延迟当拍写入）。
  // release CAM：io.release 的折叠 paddr 当拍反查；命中 && 槽在队 && release 有效
  //   打一拍（releaseHit_q），下一拍把 released 置 1（§2）。
  // ===========================================================================
  logic [PPADDR_W-1:0] releasePartialPAddr;
  logic [RAR_SIZE-1:0] releaseMatch;                   // release CAM 命中向量
  logic [RAR_SIZE-1:0] releaseViolationMatch [LD_W];   // 每条 load 流水的地址命中向量

  assign releasePartialPAddr = gen_partial_paddr(io_release.paddr);

  always_ff @(posedge clock)
    for (int i = 0; i < RAR_SIZE; i++)
      releaseHit_q[i] <= releaseMatch[i] & allocated[i] & io_release.valid;

  // CAM 阵列的扁平端口在这里逐位接上（golden 端口名，见 LqPAddrModule.sv）
  // BEGIN GENERATED(lqrar-cam-inst)
  LqPAddrModule paddrModule (
    .clock                            (clock),
    .reset                            (reset),
    .io_wen_0                         (acceptedVec[0]),
    .io_wen_1                         (acceptedVec[1]),
    .io_wen_2                         (acceptedVec[2]),
    .io_waddr_0                       (enqIndexVec[0]),
    .io_waddr_1                       (enqIndexVec[1]),
    .io_waddr_2                       (enqIndexVec[2]),
    .io_wdata_0                       (reqPartialPAddr[0]),
    .io_wdata_1                       (reqPartialPAddr[1]),
    .io_wdata_2                       (reqPartialPAddr[2]),
    .io_releaseMdata_2                (releasePartialPAddr),
    .io_releaseMmask_2_0              (releaseMatch[0]),
    .io_releaseMmask_2_1              (releaseMatch[1]),
    .io_releaseMmask_2_2              (releaseMatch[2]),
    .io_releaseMmask_2_3              (releaseMatch[3]),
    .io_releaseMmask_2_4              (releaseMatch[4]),
    .io_releaseMmask_2_5              (releaseMatch[5]),
    .io_releaseMmask_2_6              (releaseMatch[6]),
    .io_releaseMmask_2_7              (releaseMatch[7]),
    .io_releaseMmask_2_8              (releaseMatch[8]),
    .io_releaseMmask_2_9              (releaseMatch[9]),
    .io_releaseMmask_2_10             (releaseMatch[10]),
    .io_releaseMmask_2_11             (releaseMatch[11]),
    .io_releaseMmask_2_12             (releaseMatch[12]),
    .io_releaseMmask_2_13             (releaseMatch[13]),
    .io_releaseMmask_2_14             (releaseMatch[14]),
    .io_releaseMmask_2_15             (releaseMatch[15]),
    .io_releaseMmask_2_16             (releaseMatch[16]),
    .io_releaseMmask_2_17             (releaseMatch[17]),
    .io_releaseMmask_2_18             (releaseMatch[18]),
    .io_releaseMmask_2_19             (releaseMatch[19]),
    .io_releaseMmask_2_20             (releaseMatch[20]),
    .io_releaseMmask_2_21             (releaseMatch[21]),
    .io_releaseMmask_2_22             (releaseMatch[22]),
    .io_releaseMmask_2_23             (releaseMatch[23]),
    .io_releaseMmask_2_24             (releaseMatch[24]),
    .io_releaseMmask_2_25             (releaseMatch[25]),
    .io_releaseMmask_2_26             (releaseMatch[26]),
    .io_releaseMmask_2_27             (releaseMatch[27]),
    .io_releaseMmask_2_28             (releaseMatch[28]),
    .io_releaseMmask_2_29             (releaseMatch[29]),
    .io_releaseMmask_2_30             (releaseMatch[30]),
    .io_releaseMmask_2_31             (releaseMatch[31]),
    .io_releaseMmask_2_32             (releaseMatch[32]),
    .io_releaseMmask_2_33             (releaseMatch[33]),
    .io_releaseMmask_2_34             (releaseMatch[34]),
    .io_releaseMmask_2_35             (releaseMatch[35]),
    .io_releaseMmask_2_36             (releaseMatch[36]),
    .io_releaseMmask_2_37             (releaseMatch[37]),
    .io_releaseMmask_2_38             (releaseMatch[38]),
    .io_releaseMmask_2_39             (releaseMatch[39]),
    .io_releaseMmask_2_40             (releaseMatch[40]),
    .io_releaseMmask_2_41             (releaseMatch[41]),
    .io_releaseMmask_2_42             (releaseMatch[42]),
    .io_releaseMmask_2_43             (releaseMatch[43]),
    .io_releaseMmask_2_44             (releaseMatch[44]),
    .io_releaseMmask_2_45             (releaseMatch[45]),
    .io_releaseMmask_2_46             (releaseMatch[46]),
    .io_releaseMmask_2_47             (releaseMatch[47]),
    .io_releaseMmask_2_48             (releaseMatch[48]),
    .io_releaseMmask_2_49             (releaseMatch[49]),
    .io_releaseMmask_2_50             (releaseMatch[50]),
    .io_releaseMmask_2_51             (releaseMatch[51]),
    .io_releaseMmask_2_52             (releaseMatch[52]),
    .io_releaseMmask_2_53             (releaseMatch[53]),
    .io_releaseMmask_2_54             (releaseMatch[54]),
    .io_releaseMmask_2_55             (releaseMatch[55]),
    .io_releaseMmask_2_56             (releaseMatch[56]),
    .io_releaseMmask_2_57             (releaseMatch[57]),
    .io_releaseMmask_2_58             (releaseMatch[58]),
    .io_releaseMmask_2_59             (releaseMatch[59]),
    .io_releaseMmask_2_60             (releaseMatch[60]),
    .io_releaseMmask_2_61             (releaseMatch[61]),
    .io_releaseMmask_2_62             (releaseMatch[62]),
    .io_releaseMmask_2_63             (releaseMatch[63]),
    .io_releaseMmask_2_64             (releaseMatch[64]),
    .io_releaseMmask_2_65             (releaseMatch[65]),
    .io_releaseMmask_2_66             (releaseMatch[66]),
    .io_releaseMmask_2_67             (releaseMatch[67]),
    .io_releaseMmask_2_68             (releaseMatch[68]),
    .io_releaseMmask_2_69             (releaseMatch[69]),
    .io_releaseMmask_2_70             (releaseMatch[70]),
    .io_releaseMmask_2_71             (releaseMatch[71]),
    .io_releaseViolationMdata_0       (reqPartialPAddr[0]),
    .io_releaseViolationMdata_1       (reqPartialPAddr[1]),
    .io_releaseViolationMdata_2       (reqPartialPAddr[2]),
    .io_releaseViolationMmask_0_0     (releaseViolationMatch[0][0]),
    .io_releaseViolationMmask_0_1     (releaseViolationMatch[0][1]),
    .io_releaseViolationMmask_0_2     (releaseViolationMatch[0][2]),
    .io_releaseViolationMmask_0_3     (releaseViolationMatch[0][3]),
    .io_releaseViolationMmask_0_4     (releaseViolationMatch[0][4]),
    .io_releaseViolationMmask_0_5     (releaseViolationMatch[0][5]),
    .io_releaseViolationMmask_0_6     (releaseViolationMatch[0][6]),
    .io_releaseViolationMmask_0_7     (releaseViolationMatch[0][7]),
    .io_releaseViolationMmask_0_8     (releaseViolationMatch[0][8]),
    .io_releaseViolationMmask_0_9     (releaseViolationMatch[0][9]),
    .io_releaseViolationMmask_0_10    (releaseViolationMatch[0][10]),
    .io_releaseViolationMmask_0_11    (releaseViolationMatch[0][11]),
    .io_releaseViolationMmask_0_12    (releaseViolationMatch[0][12]),
    .io_releaseViolationMmask_0_13    (releaseViolationMatch[0][13]),
    .io_releaseViolationMmask_0_14    (releaseViolationMatch[0][14]),
    .io_releaseViolationMmask_0_15    (releaseViolationMatch[0][15]),
    .io_releaseViolationMmask_0_16    (releaseViolationMatch[0][16]),
    .io_releaseViolationMmask_0_17    (releaseViolationMatch[0][17]),
    .io_releaseViolationMmask_0_18    (releaseViolationMatch[0][18]),
    .io_releaseViolationMmask_0_19    (releaseViolationMatch[0][19]),
    .io_releaseViolationMmask_0_20    (releaseViolationMatch[0][20]),
    .io_releaseViolationMmask_0_21    (releaseViolationMatch[0][21]),
    .io_releaseViolationMmask_0_22    (releaseViolationMatch[0][22]),
    .io_releaseViolationMmask_0_23    (releaseViolationMatch[0][23]),
    .io_releaseViolationMmask_0_24    (releaseViolationMatch[0][24]),
    .io_releaseViolationMmask_0_25    (releaseViolationMatch[0][25]),
    .io_releaseViolationMmask_0_26    (releaseViolationMatch[0][26]),
    .io_releaseViolationMmask_0_27    (releaseViolationMatch[0][27]),
    .io_releaseViolationMmask_0_28    (releaseViolationMatch[0][28]),
    .io_releaseViolationMmask_0_29    (releaseViolationMatch[0][29]),
    .io_releaseViolationMmask_0_30    (releaseViolationMatch[0][30]),
    .io_releaseViolationMmask_0_31    (releaseViolationMatch[0][31]),
    .io_releaseViolationMmask_0_32    (releaseViolationMatch[0][32]),
    .io_releaseViolationMmask_0_33    (releaseViolationMatch[0][33]),
    .io_releaseViolationMmask_0_34    (releaseViolationMatch[0][34]),
    .io_releaseViolationMmask_0_35    (releaseViolationMatch[0][35]),
    .io_releaseViolationMmask_0_36    (releaseViolationMatch[0][36]),
    .io_releaseViolationMmask_0_37    (releaseViolationMatch[0][37]),
    .io_releaseViolationMmask_0_38    (releaseViolationMatch[0][38]),
    .io_releaseViolationMmask_0_39    (releaseViolationMatch[0][39]),
    .io_releaseViolationMmask_0_40    (releaseViolationMatch[0][40]),
    .io_releaseViolationMmask_0_41    (releaseViolationMatch[0][41]),
    .io_releaseViolationMmask_0_42    (releaseViolationMatch[0][42]),
    .io_releaseViolationMmask_0_43    (releaseViolationMatch[0][43]),
    .io_releaseViolationMmask_0_44    (releaseViolationMatch[0][44]),
    .io_releaseViolationMmask_0_45    (releaseViolationMatch[0][45]),
    .io_releaseViolationMmask_0_46    (releaseViolationMatch[0][46]),
    .io_releaseViolationMmask_0_47    (releaseViolationMatch[0][47]),
    .io_releaseViolationMmask_0_48    (releaseViolationMatch[0][48]),
    .io_releaseViolationMmask_0_49    (releaseViolationMatch[0][49]),
    .io_releaseViolationMmask_0_50    (releaseViolationMatch[0][50]),
    .io_releaseViolationMmask_0_51    (releaseViolationMatch[0][51]),
    .io_releaseViolationMmask_0_52    (releaseViolationMatch[0][52]),
    .io_releaseViolationMmask_0_53    (releaseViolationMatch[0][53]),
    .io_releaseViolationMmask_0_54    (releaseViolationMatch[0][54]),
    .io_releaseViolationMmask_0_55    (releaseViolationMatch[0][55]),
    .io_releaseViolationMmask_0_56    (releaseViolationMatch[0][56]),
    .io_releaseViolationMmask_0_57    (releaseViolationMatch[0][57]),
    .io_releaseViolationMmask_0_58    (releaseViolationMatch[0][58]),
    .io_releaseViolationMmask_0_59    (releaseViolationMatch[0][59]),
    .io_releaseViolationMmask_0_60    (releaseViolationMatch[0][60]),
    .io_releaseViolationMmask_0_61    (releaseViolationMatch[0][61]),
    .io_releaseViolationMmask_0_62    (releaseViolationMatch[0][62]),
    .io_releaseViolationMmask_0_63    (releaseViolationMatch[0][63]),
    .io_releaseViolationMmask_0_64    (releaseViolationMatch[0][64]),
    .io_releaseViolationMmask_0_65    (releaseViolationMatch[0][65]),
    .io_releaseViolationMmask_0_66    (releaseViolationMatch[0][66]),
    .io_releaseViolationMmask_0_67    (releaseViolationMatch[0][67]),
    .io_releaseViolationMmask_0_68    (releaseViolationMatch[0][68]),
    .io_releaseViolationMmask_0_69    (releaseViolationMatch[0][69]),
    .io_releaseViolationMmask_0_70    (releaseViolationMatch[0][70]),
    .io_releaseViolationMmask_0_71    (releaseViolationMatch[0][71]),
    .io_releaseViolationMmask_1_0     (releaseViolationMatch[1][0]),
    .io_releaseViolationMmask_1_1     (releaseViolationMatch[1][1]),
    .io_releaseViolationMmask_1_2     (releaseViolationMatch[1][2]),
    .io_releaseViolationMmask_1_3     (releaseViolationMatch[1][3]),
    .io_releaseViolationMmask_1_4     (releaseViolationMatch[1][4]),
    .io_releaseViolationMmask_1_5     (releaseViolationMatch[1][5]),
    .io_releaseViolationMmask_1_6     (releaseViolationMatch[1][6]),
    .io_releaseViolationMmask_1_7     (releaseViolationMatch[1][7]),
    .io_releaseViolationMmask_1_8     (releaseViolationMatch[1][8]),
    .io_releaseViolationMmask_1_9     (releaseViolationMatch[1][9]),
    .io_releaseViolationMmask_1_10    (releaseViolationMatch[1][10]),
    .io_releaseViolationMmask_1_11    (releaseViolationMatch[1][11]),
    .io_releaseViolationMmask_1_12    (releaseViolationMatch[1][12]),
    .io_releaseViolationMmask_1_13    (releaseViolationMatch[1][13]),
    .io_releaseViolationMmask_1_14    (releaseViolationMatch[1][14]),
    .io_releaseViolationMmask_1_15    (releaseViolationMatch[1][15]),
    .io_releaseViolationMmask_1_16    (releaseViolationMatch[1][16]),
    .io_releaseViolationMmask_1_17    (releaseViolationMatch[1][17]),
    .io_releaseViolationMmask_1_18    (releaseViolationMatch[1][18]),
    .io_releaseViolationMmask_1_19    (releaseViolationMatch[1][19]),
    .io_releaseViolationMmask_1_20    (releaseViolationMatch[1][20]),
    .io_releaseViolationMmask_1_21    (releaseViolationMatch[1][21]),
    .io_releaseViolationMmask_1_22    (releaseViolationMatch[1][22]),
    .io_releaseViolationMmask_1_23    (releaseViolationMatch[1][23]),
    .io_releaseViolationMmask_1_24    (releaseViolationMatch[1][24]),
    .io_releaseViolationMmask_1_25    (releaseViolationMatch[1][25]),
    .io_releaseViolationMmask_1_26    (releaseViolationMatch[1][26]),
    .io_releaseViolationMmask_1_27    (releaseViolationMatch[1][27]),
    .io_releaseViolationMmask_1_28    (releaseViolationMatch[1][28]),
    .io_releaseViolationMmask_1_29    (releaseViolationMatch[1][29]),
    .io_releaseViolationMmask_1_30    (releaseViolationMatch[1][30]),
    .io_releaseViolationMmask_1_31    (releaseViolationMatch[1][31]),
    .io_releaseViolationMmask_1_32    (releaseViolationMatch[1][32]),
    .io_releaseViolationMmask_1_33    (releaseViolationMatch[1][33]),
    .io_releaseViolationMmask_1_34    (releaseViolationMatch[1][34]),
    .io_releaseViolationMmask_1_35    (releaseViolationMatch[1][35]),
    .io_releaseViolationMmask_1_36    (releaseViolationMatch[1][36]),
    .io_releaseViolationMmask_1_37    (releaseViolationMatch[1][37]),
    .io_releaseViolationMmask_1_38    (releaseViolationMatch[1][38]),
    .io_releaseViolationMmask_1_39    (releaseViolationMatch[1][39]),
    .io_releaseViolationMmask_1_40    (releaseViolationMatch[1][40]),
    .io_releaseViolationMmask_1_41    (releaseViolationMatch[1][41]),
    .io_releaseViolationMmask_1_42    (releaseViolationMatch[1][42]),
    .io_releaseViolationMmask_1_43    (releaseViolationMatch[1][43]),
    .io_releaseViolationMmask_1_44    (releaseViolationMatch[1][44]),
    .io_releaseViolationMmask_1_45    (releaseViolationMatch[1][45]),
    .io_releaseViolationMmask_1_46    (releaseViolationMatch[1][46]),
    .io_releaseViolationMmask_1_47    (releaseViolationMatch[1][47]),
    .io_releaseViolationMmask_1_48    (releaseViolationMatch[1][48]),
    .io_releaseViolationMmask_1_49    (releaseViolationMatch[1][49]),
    .io_releaseViolationMmask_1_50    (releaseViolationMatch[1][50]),
    .io_releaseViolationMmask_1_51    (releaseViolationMatch[1][51]),
    .io_releaseViolationMmask_1_52    (releaseViolationMatch[1][52]),
    .io_releaseViolationMmask_1_53    (releaseViolationMatch[1][53]),
    .io_releaseViolationMmask_1_54    (releaseViolationMatch[1][54]),
    .io_releaseViolationMmask_1_55    (releaseViolationMatch[1][55]),
    .io_releaseViolationMmask_1_56    (releaseViolationMatch[1][56]),
    .io_releaseViolationMmask_1_57    (releaseViolationMatch[1][57]),
    .io_releaseViolationMmask_1_58    (releaseViolationMatch[1][58]),
    .io_releaseViolationMmask_1_59    (releaseViolationMatch[1][59]),
    .io_releaseViolationMmask_1_60    (releaseViolationMatch[1][60]),
    .io_releaseViolationMmask_1_61    (releaseViolationMatch[1][61]),
    .io_releaseViolationMmask_1_62    (releaseViolationMatch[1][62]),
    .io_releaseViolationMmask_1_63    (releaseViolationMatch[1][63]),
    .io_releaseViolationMmask_1_64    (releaseViolationMatch[1][64]),
    .io_releaseViolationMmask_1_65    (releaseViolationMatch[1][65]),
    .io_releaseViolationMmask_1_66    (releaseViolationMatch[1][66]),
    .io_releaseViolationMmask_1_67    (releaseViolationMatch[1][67]),
    .io_releaseViolationMmask_1_68    (releaseViolationMatch[1][68]),
    .io_releaseViolationMmask_1_69    (releaseViolationMatch[1][69]),
    .io_releaseViolationMmask_1_70    (releaseViolationMatch[1][70]),
    .io_releaseViolationMmask_1_71    (releaseViolationMatch[1][71]),
    .io_releaseViolationMmask_2_0     (releaseViolationMatch[2][0]),
    .io_releaseViolationMmask_2_1     (releaseViolationMatch[2][1]),
    .io_releaseViolationMmask_2_2     (releaseViolationMatch[2][2]),
    .io_releaseViolationMmask_2_3     (releaseViolationMatch[2][3]),
    .io_releaseViolationMmask_2_4     (releaseViolationMatch[2][4]),
    .io_releaseViolationMmask_2_5     (releaseViolationMatch[2][5]),
    .io_releaseViolationMmask_2_6     (releaseViolationMatch[2][6]),
    .io_releaseViolationMmask_2_7     (releaseViolationMatch[2][7]),
    .io_releaseViolationMmask_2_8     (releaseViolationMatch[2][8]),
    .io_releaseViolationMmask_2_9     (releaseViolationMatch[2][9]),
    .io_releaseViolationMmask_2_10    (releaseViolationMatch[2][10]),
    .io_releaseViolationMmask_2_11    (releaseViolationMatch[2][11]),
    .io_releaseViolationMmask_2_12    (releaseViolationMatch[2][12]),
    .io_releaseViolationMmask_2_13    (releaseViolationMatch[2][13]),
    .io_releaseViolationMmask_2_14    (releaseViolationMatch[2][14]),
    .io_releaseViolationMmask_2_15    (releaseViolationMatch[2][15]),
    .io_releaseViolationMmask_2_16    (releaseViolationMatch[2][16]),
    .io_releaseViolationMmask_2_17    (releaseViolationMatch[2][17]),
    .io_releaseViolationMmask_2_18    (releaseViolationMatch[2][18]),
    .io_releaseViolationMmask_2_19    (releaseViolationMatch[2][19]),
    .io_releaseViolationMmask_2_20    (releaseViolationMatch[2][20]),
    .io_releaseViolationMmask_2_21    (releaseViolationMatch[2][21]),
    .io_releaseViolationMmask_2_22    (releaseViolationMatch[2][22]),
    .io_releaseViolationMmask_2_23    (releaseViolationMatch[2][23]),
    .io_releaseViolationMmask_2_24    (releaseViolationMatch[2][24]),
    .io_releaseViolationMmask_2_25    (releaseViolationMatch[2][25]),
    .io_releaseViolationMmask_2_26    (releaseViolationMatch[2][26]),
    .io_releaseViolationMmask_2_27    (releaseViolationMatch[2][27]),
    .io_releaseViolationMmask_2_28    (releaseViolationMatch[2][28]),
    .io_releaseViolationMmask_2_29    (releaseViolationMatch[2][29]),
    .io_releaseViolationMmask_2_30    (releaseViolationMatch[2][30]),
    .io_releaseViolationMmask_2_31    (releaseViolationMatch[2][31]),
    .io_releaseViolationMmask_2_32    (releaseViolationMatch[2][32]),
    .io_releaseViolationMmask_2_33    (releaseViolationMatch[2][33]),
    .io_releaseViolationMmask_2_34    (releaseViolationMatch[2][34]),
    .io_releaseViolationMmask_2_35    (releaseViolationMatch[2][35]),
    .io_releaseViolationMmask_2_36    (releaseViolationMatch[2][36]),
    .io_releaseViolationMmask_2_37    (releaseViolationMatch[2][37]),
    .io_releaseViolationMmask_2_38    (releaseViolationMatch[2][38]),
    .io_releaseViolationMmask_2_39    (releaseViolationMatch[2][39]),
    .io_releaseViolationMmask_2_40    (releaseViolationMatch[2][40]),
    .io_releaseViolationMmask_2_41    (releaseViolationMatch[2][41]),
    .io_releaseViolationMmask_2_42    (releaseViolationMatch[2][42]),
    .io_releaseViolationMmask_2_43    (releaseViolationMatch[2][43]),
    .io_releaseViolationMmask_2_44    (releaseViolationMatch[2][44]),
    .io_releaseViolationMmask_2_45    (releaseViolationMatch[2][45]),
    .io_releaseViolationMmask_2_46    (releaseViolationMatch[2][46]),
    .io_releaseViolationMmask_2_47    (releaseViolationMatch[2][47]),
    .io_releaseViolationMmask_2_48    (releaseViolationMatch[2][48]),
    .io_releaseViolationMmask_2_49    (releaseViolationMatch[2][49]),
    .io_releaseViolationMmask_2_50    (releaseViolationMatch[2][50]),
    .io_releaseViolationMmask_2_51    (releaseViolationMatch[2][51]),
    .io_releaseViolationMmask_2_52    (releaseViolationMatch[2][52]),
    .io_releaseViolationMmask_2_53    (releaseViolationMatch[2][53]),
    .io_releaseViolationMmask_2_54    (releaseViolationMatch[2][54]),
    .io_releaseViolationMmask_2_55    (releaseViolationMatch[2][55]),
    .io_releaseViolationMmask_2_56    (releaseViolationMatch[2][56]),
    .io_releaseViolationMmask_2_57    (releaseViolationMatch[2][57]),
    .io_releaseViolationMmask_2_58    (releaseViolationMatch[2][58]),
    .io_releaseViolationMmask_2_59    (releaseViolationMatch[2][59]),
    .io_releaseViolationMmask_2_60    (releaseViolationMatch[2][60]),
    .io_releaseViolationMmask_2_61    (releaseViolationMatch[2][61]),
    .io_releaseViolationMmask_2_62    (releaseViolationMatch[2][62]),
    .io_releaseViolationMmask_2_63    (releaseViolationMatch[2][63]),
    .io_releaseViolationMmask_2_64    (releaseViolationMatch[2][64]),
    .io_releaseViolationMmask_2_65    (releaseViolationMatch[2][65]),
    .io_releaseViolationMmask_2_66    (releaseViolationMatch[2][66]),
    .io_releaseViolationMmask_2_67    (releaseViolationMatch[2][67]),
    .io_releaseViolationMmask_2_68    (releaseViolationMatch[2][68]),
    .io_releaseViolationMmask_2_69    (releaseViolationMatch[2][69]),
    .io_releaseViolationMmask_2_70    (releaseViolationMatch[2][70]),
    .io_releaseViolationMmask_2_71    (releaseViolationMatch[2][71])
  );
  // END GENERATED

  // ===========================================================================
  // §5 load→load 违例检测（每条 load 流水一套）
  // ---------------------------------------------------------------------------
  // 候选槽 = 在队 && 同地址（折叠键相等）&& 槽里的 load 比本 load 年轻 && 已 released。
  // 匹配向量 RegEnable(query.req.valid) 打一拍，下一拍"或"起来就是 rep_frm_fetch。
  // ===========================================================================
  logic ldLdViolationMask [LD_W][RAR_SIZE];   // 不复位
  logic respValid_q       [LD_W];             // RegNext(query.req.valid)，不复位

  always_ff @(posedge clock)
    for (int w = 0; w < LD_W; w++) begin
      respValid_q[w] <= io_query_req[w].valid;
      if (io_query_req[w].valid)
        for (int i = 0; i < RAR_SIZE; i++)
          ldLdViolationMask[w][i] <= allocated[i]
                                   & releaseViolationMatch[w][i]
                                   & rob_is_after(uop_robIdx[i], io_query_req[w].robIdx)
                                   & released[i];
    end

  always_comb
    for (int w = 0; w < LD_W; w++) begin
      io_query_resp_valid[w]         = respValid_q[w];
      io_query_resp_rep_frm_fetch[w] = 1'b0;
      for (int i = 0; i < RAR_SIZE; i++)
        io_query_resp_rep_frm_fetch[w] |= ldLdViolationMask[w][i];
    end

  // ===========================================================================
  // §6 输出与 perf
  // ===========================================================================
  assign io_lqFull = fl_empty;

  // perf：本拍入队条数（req.fire 计数）/ 本拍违例条数（resp.valid && rep_frm_fetch），各打两拍
  logic [1:0] canEnqCount;
  logic [1:0] ldLdViolationCount;
  logic [1:0] perfEnq_q [2];
  logic [1:0] perfVio_q [2];
  always_comb begin
    canEnqCount        = '0;
    ldLdViolationCount = '0;
    for (int w = 0; w < LD_W; w++) begin
      canEnqCount        += 2'(io_query_req_ready[w] & io_query_req[w].valid);
      ldLdViolationCount += 2'(io_query_resp_valid[w] & io_query_resp_rep_frm_fetch[w]);
    end
  end

  always_ff @(posedge clock) begin
    perfEnq_q[0] <= canEnqCount;
    perfEnq_q[1] <= perfEnq_q[0];
    perfVio_q[0] <= ldLdViolationCount;
    perfVio_q[1] <= perfVio_q[0];
  end

  assign io_perf_0_value = {4'h0, perfEnq_q[1]};
  assign io_perf_1_value = {4'h0, perfVio_q[1]};

endmodule


// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序，只做打包/改名
// （scripts/gen_lqrar.py 生成，勿手改）
// -----------------------------------------------------------------------------
// BEGIN GENERATED(lqrar-wrapper)
module LoadQueueRAR
  import loadqueuerar_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  output        io_query_0_req_ready,
  input         io_query_0_req_valid,
  input         io_query_0_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_0_req_bits_uop_robIdx_value,
  input         io_query_0_req_bits_uop_lqIdx_flag,
  input  [6:0]  io_query_0_req_bits_uop_lqIdx_value,
  input  [47:0] io_query_0_req_bits_paddr,
  input         io_query_0_req_bits_data_valid,
  input         io_query_0_req_bits_is_nc,
  output        io_query_0_resp_valid,
  output        io_query_0_resp_bits_rep_frm_fetch,
  input         io_query_0_revoke,
  output        io_query_1_req_ready,
  input         io_query_1_req_valid,
  input         io_query_1_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_1_req_bits_uop_robIdx_value,
  input         io_query_1_req_bits_uop_lqIdx_flag,
  input  [6:0]  io_query_1_req_bits_uop_lqIdx_value,
  input  [47:0] io_query_1_req_bits_paddr,
  input         io_query_1_req_bits_data_valid,
  input         io_query_1_req_bits_is_nc,
  output        io_query_1_resp_valid,
  output        io_query_1_resp_bits_rep_frm_fetch,
  input         io_query_1_revoke,
  output        io_query_2_req_ready,
  input         io_query_2_req_valid,
  input         io_query_2_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_2_req_bits_uop_robIdx_value,
  input         io_query_2_req_bits_uop_lqIdx_flag,
  input  [6:0]  io_query_2_req_bits_uop_lqIdx_value,
  input  [47:0] io_query_2_req_bits_paddr,
  input         io_query_2_req_bits_data_valid,
  input         io_query_2_req_bits_is_nc,
  output        io_query_2_resp_valid,
  output        io_query_2_resp_bits_rep_frm_fetch,
  input         io_query_2_revoke,
  input         io_release_valid,
  input  [47:0] io_release_bits_paddr,
  input         io_ldWbPtr_flag,
  input  [6:0]  io_ldWbPtr_value,
  output        io_lqFull,
  output [5:0]  io_perf_0_value,
  output [5:0]  io_perf_1_value
);
  // golden 的端口是 firtool 完全展平的标量；这里按语义重新装成结构体交给可读核。
  redirect_t              redirect;
  query_req_t [LD_W-1:0]  query_req;
  logic       [LD_W-1:0]  query_ready;
  logic       [LD_W-1:0]  query_resp_valid;
  logic       [LD_W-1:0]  query_resp_rep_frm_fetch;
  logic       [LD_W-1:0]  query_revoke;
  release_t               releaseIn;  // `release` 是 SV 关键字
  lq_ptr_t                ldWbPtr;

  assign redirect.valid = io_redirect_valid;
  assign redirect.robIdx.flag = io_redirect_bits_robIdx_flag;
  assign redirect.robIdx.value = io_redirect_bits_robIdx_value;
  assign redirect.level = io_redirect_bits_level;
  assign io_query_0_req_ready = query_ready[0];
  assign query_req[0].valid = io_query_0_req_valid;
  assign query_req[0].robIdx.flag = io_query_0_req_bits_uop_robIdx_flag;
  assign query_req[0].robIdx.value = io_query_0_req_bits_uop_robIdx_value;
  assign query_req[0].lqIdx.flag = io_query_0_req_bits_uop_lqIdx_flag;
  assign query_req[0].lqIdx.value = io_query_0_req_bits_uop_lqIdx_value;
  assign query_req[0].paddr = io_query_0_req_bits_paddr;
  assign query_req[0].data_valid = io_query_0_req_bits_data_valid;
  assign query_req[0].is_nc = io_query_0_req_bits_is_nc;
  assign io_query_0_resp_valid = query_resp_valid[0];
  assign io_query_0_resp_bits_rep_frm_fetch = query_resp_rep_frm_fetch[0];
  assign query_revoke[0] = io_query_0_revoke;
  assign io_query_1_req_ready = query_ready[1];
  assign query_req[1].valid = io_query_1_req_valid;
  assign query_req[1].robIdx.flag = io_query_1_req_bits_uop_robIdx_flag;
  assign query_req[1].robIdx.value = io_query_1_req_bits_uop_robIdx_value;
  assign query_req[1].lqIdx.flag = io_query_1_req_bits_uop_lqIdx_flag;
  assign query_req[1].lqIdx.value = io_query_1_req_bits_uop_lqIdx_value;
  assign query_req[1].paddr = io_query_1_req_bits_paddr;
  assign query_req[1].data_valid = io_query_1_req_bits_data_valid;
  assign query_req[1].is_nc = io_query_1_req_bits_is_nc;
  assign io_query_1_resp_valid = query_resp_valid[1];
  assign io_query_1_resp_bits_rep_frm_fetch = query_resp_rep_frm_fetch[1];
  assign query_revoke[1] = io_query_1_revoke;
  assign io_query_2_req_ready = query_ready[2];
  assign query_req[2].valid = io_query_2_req_valid;
  assign query_req[2].robIdx.flag = io_query_2_req_bits_uop_robIdx_flag;
  assign query_req[2].robIdx.value = io_query_2_req_bits_uop_robIdx_value;
  assign query_req[2].lqIdx.flag = io_query_2_req_bits_uop_lqIdx_flag;
  assign query_req[2].lqIdx.value = io_query_2_req_bits_uop_lqIdx_value;
  assign query_req[2].paddr = io_query_2_req_bits_paddr;
  assign query_req[2].data_valid = io_query_2_req_bits_data_valid;
  assign query_req[2].is_nc = io_query_2_req_bits_is_nc;
  assign io_query_2_resp_valid = query_resp_valid[2];
  assign io_query_2_resp_bits_rep_frm_fetch = query_resp_rep_frm_fetch[2];
  assign query_revoke[2] = io_query_2_revoke;
  assign releaseIn.valid = io_release_valid;
  assign releaseIn.paddr = io_release_bits_paddr;
  assign ldWbPtr.flag = io_ldWbPtr_flag;
  assign ldWbPtr.value = io_ldWbPtr_value;

  xs_LoadQueueRAR_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .io_redirect                 (redirect),
    .io_query_req                (query_req),
    .io_query_req_ready          (query_ready),
    .io_query_resp_valid         (query_resp_valid),
    .io_query_resp_rep_frm_fetch (query_resp_rep_frm_fetch),
    .io_query_revoke             (query_revoke),
    .io_release                  (releaseIn),
    .io_ldWbPtr                  (ldWbPtr),
    .io_lqFull                   (io_lqFull),
    .io_perf_0_value             (io_perf_0_value),
    .io_perf_1_value             (io_perf_1_value)
  );
endmodule
// END GENERATED
