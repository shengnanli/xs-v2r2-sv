// =============================================================================
//  storequeue_pkg —— StoreQueue（store 顺序队列）可读重写用的类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/StoreQueue.scala  (class StoreQueue)
//
//  StoreQueue 是访存乱序执行的「store 顺序核心」。它在派遣(dispatch)阶段为每条
//  store 分配一个 entry，跟踪其地址/数据分别就绪、提交、最终写回 Sbuffer 的全过程，
//  并向 load 流水提供 store-to-load forward（前递）。它是一条**循环队列**(circular
//  queue)，用「带 flag 的指针 + 物理下标」管理在飞 store。
//
//  ── 队列的多根指针（环形队列，flag^value 区分同一物理槽的两圈）─────────────
//    · enqPtr   入队指针：dispatch 时分配 entry，按 numLsElem(向量展开流数)推进
//    · rdataPtr 读数据指针：领先 deqPtr，提前一拍从 data/addr 子模块读出待出队 store
//    · deqPtr   出队指针：store 真正离开队列（已写 Sbuffer / mmio / nc 完成）时推进
//    · cmtPtr   提交指针：ROB 提交 store 时推进，标记 committed（不可再被 redirect 取消）
//    · addrReadyPtr / dataReadyPtr：地址/数据就绪扫描指针，给后端 issue 用
//    生命周期：  enq ──▶ [addrvalid & datavalid] ──▶ cmt(committed) ──▶ rdata ──▶ deq
//    指针顺序通常：deqPtr ≤ rdataPtr ≤ cmtPtr ≤ enqPtr（mmio 时 deq 可领先 cmt）
//
//  ── 每个 entry 的状态位（散列在多个 Vec(StoreQueueSize, Bool)）──────────────
//    allocated   : entry 已被分配（活跃）
//    completed   : 已完成出队动作（写 Sbuffer / mmio / nc 完成）→ deqPtr 可推进
//    addrvalid   : 地址已就绪（StoreUnit s1 写回，非 miss）
//    datavalid   : 数据已就绪（StoreData s1 写回）
//    committed   : ROB 已提交（可以安全送往下层，不会被 redirect 取消）
//    unaligned / cross16Byte : 非对齐 store / 跨 16B 边界（需拆两拍写 Sbuffer）
//    pending     : mmio store，须等到 ROB 头才能发 uncache
//    nc          : non-cacheable store（走 ubuffer，须等 resp 才能 deq）
//    mmio        : mmio store
//    memBackTypeMM / hasException / waitStoreS2 / prefetch
//    isVec / vecLastFlow / vecMbCommit : 向量 store 相关
//
//  ── 三个独立的小状态机 ────────────────────────────────────────────────────
//    (1) mmioState (s_idle/s_req/s_resp/s_wb/s_wait)：mmio/CMO store 在 ROB 头时
//        发 uncache 请求、等 resp、写回 ROB、等 scommit。
//    (2) ncState (nc_idle/nc_req/nc_req_ack/nc_resp)：non-cacheable store 流程。
//    (3) 全队列的 enq/commit/deq/forward 是组合+指针推进，不算 FSM。
//
//  ── 本工程 KunmingHu V2R2 配置固化参数（与 golden StoreQueue.sv 端口对齐）─────
//      StoreQueueSize   = 56  →  SQ_IDX_W = 6（entry 下标 6 位；flag 单独 1 位）
//      LSQEnqWidth      = 6   （dispatch 入队请求路数；needAlloc 表只展开到 5）
//      StorePipelineWidth = 2 （storeAddrIn / storeDataIn / storeMaskIn 各 2 路）
//      EnsbufferWidth   = 2   （出队到 Sbuffer / dataBuffer 2 路；rdata/deq 指针 2 根）
//      CommitWidth      = 8   （ROB 一拍最多提交 8 条；cmtPtr 8 根）
//      LoadPipelineWidth= 3   （forward 查询 3 路）
//      VecStorePipelineWidth = 2（向量 store 反馈 2 路）
//      VLEN=128, PAddrBits=48, VAddrBits=50, XLEN=64
//      IssuePtrMoveStride = 4 （addr/dataReadyPtr 每拍最多前移 4）
//
//  ⚠ 数据存储子模块全部黑盒（与 golden 共用）：SQDataModule（data/mask + forward CAM）、
//    SQAddrModule(paddr) / SQAddrModule_1(vaddr)（地址 + forward 地址 CAM）、
//    DatamoduleResultBuffer(dataBuffer，出队到 Sbuffer 的结果缓冲)、
//    StoreExceptionBuffer（异常地址选最老）。本核重写**控制逻辑**：指针推进、
//    entry 状态机、enq/commit/deq 仲裁、forward mask 计算、mmio/nc/cmo FSM。
// =============================================================================
package storequeue_pkg;

  // ---- 关键位宽/常量（与香山 KunmingHu V2R2 配置一致）-----------------------
  localparam int SQ_SIZE       = 56;             // StoreQueueSize
  localparam int SQ_IDX_W      = 6;              // log2 上取整后的物理下标宽（值域 0..55）
  localparam int ENQ_W         = 6;              // LSQEnqWidth（dispatch 入队路数）
  localparam int NEED_ALLOC_W  = 5;              // needAlloc 端口数（golden 仅展开 5 路）
  localparam int ST_PIPE_W     = 2;              // StorePipelineWidth
  localparam int ENSB_W        = 2;              // EnsbufferWidth（出队/读数据 2 路）
  localparam int COMMIT_W      = 8;              // CommitWidth（ROB 提交 8 路）
  localparam int LD_PIPE_W     = 3;              // LoadPipelineWidth（forward 3 路）
  localparam int VEC_PIPE_W    = 2;              // VecStorePipelineWidth
  localparam int ISSUE_STRIDE  = 4;              // IssuePtrMoveStride（就绪指针每拍前移上限）

  localparam int VLEN          = 128;
  localparam int VLEN_BYTES    = 16;             // VLEN/8（一条 store 的数据字节数）
  localparam int XLEN          = 64;
  localparam int PADDR_BITS    = 48;
  localparam int VADDR_BITS    = 50;
  localparam int ROB_IDX_W     = 8;              // RobIdx.value 宽
  localparam int UOP_IDX_W     = 7;              // uopIdx 宽（向量）

  // StoreExceptionBuffer 入队口数 = StorePipelineWidth*2 + VecStorePipelineWidth + 1 = 7
  localparam int EXC_ENQ_NUM   = ST_PIPE_W*2 + VEC_PIPE_W + 1;

  // perf 计数器路数（QueuePerf*2 + 4 个分桶 + mmio 4 个，firtool 裁剪后 8 路出顶层）
  localparam int PERF_NUM      = 8;

  // uncache id 宽（uncacheIdxBits）
  localparam int UNC_ID_W      = 7;

  // ---- forward CAM 命中位宽：SQDataModule.needForward 每路 56 位（每 entry 一位）---
  //   但 forwardMmask 端口宽是 56（StoreQueueSize），dataModule.needForward 宽 56。
  localparam int FWD_W         = SQ_SIZE;        // = 56

  // ===========================================================================
  //  环形队列指针：{flag, value}。flag 区分同一物理槽相邻两圈，比较新旧用。
  // ===========================================================================
  typedef struct packed {
    logic                 flag;   // 圈标志（每绕一圈翻转）
    logic [SQ_IDX_W-1:0]  value;  // 物理下标 0..SQ_SIZE-1
  } sqptr_t;

  // ---- mmio / CMO uncache store 的 5 态状态机 -------------------------------
  //   s_idle : 空闲，等 ROB 头的 mmio/CMO store
  //   s_req  : 向 uncache 通道发请求（或向 CMO 通道发 cmoOpReq）
  //   s_resp : 等 uncache/CMO 响应
  //   s_wb   : 把 mmio store 写回 ROB（mmioStout）
  //   s_wait : 等该 store 的 scommit，再回 idle
  typedef enum logic [2:0] {
    MMIO_IDLE = 3'd0,
    MMIO_REQ  = 3'd1,
    MMIO_RESP = 3'd2,
    MMIO_WB   = 3'd3,
    MMIO_WAIT = 3'd4
  } mmio_state_e;

  // ---- non-cacheable store 的 4 态状态机 -----------------------------------
  //   nc_idle    : 等已提交的 nc store
  //   nc_req     : 向 ubuffer 发写请求
  //   nc_req_ack : 等 ubuffer 的 idResp（确认写入、可前递）；outstanding 时直接回 idle
  //   nc_resp    : 等 ubuffer 的数据 resp（非 outstanding），完成后 deq
  typedef enum logic [1:0] {
    NC_IDLE    = 2'd0,
    NC_REQ     = 2'd1,
    NC_REQ_ACK = 2'd2,
    NC_RESP    = 2'd3
  } nc_state_e;

  // ===========================================================================
  //  纯函数
  // ===========================================================================

  // 环形指针 +N（带 flag 翻转）：value 越过 SQ_SIZE-1 则 flag 取反。
  function automatic sqptr_t sqptr_add(input sqptr_t p, input logic [SQ_IDX_W:0] n);
    logic [SQ_IDX_W+1:0] sum;
    sqptr_t r;
    sum = {1'b0, p.value} + n;
    if (sum >= SQ_SIZE) begin
      r.value = sum - SQ_SIZE;
      r.flag  = ~p.flag;
    end else begin
      r.value = sum[SQ_IDX_W-1:0];
      r.flag  = p.flag;
    end
    return r;
  endfunction

  // 环形指针 -N（带 flag 翻转）：用「加 (SQ_SIZE - n) 再回卷」实现，避免有符号运算
  //   （Formality 对 signed→unsigned 赋值会报 RTL 解释错误而阻断比对）。仅用于小 N
  //   （forward sqIdx-1）。等价于 (value - n) mod SQ_SIZE，借位时 flag 翻转。
  function automatic sqptr_t sqptr_sub(input sqptr_t p, input logic [SQ_IDX_W:0] n);
    logic [SQ_IDX_W+1:0] sum;     // value + (SQ_SIZE - n)
    logic [SQ_IDX_W:0]   compl;   // SQ_SIZE - n（n 小，结果非负）
    sqptr_t r;
    compl = SQ_SIZE[SQ_IDX_W:0] - n;
    sum   = {1'b0, p.value} + {1'b0, compl};
    if (sum >= SQ_SIZE) begin     // 未借位：减法在本圈内
      r.value = sum - SQ_SIZE;
      r.flag  = p.flag;
    end else begin                // 借位：回卷到上一圈
      r.value = sum[SQ_IDX_W-1:0];
      r.flag  = ~p.flag;
    end
    return r;
  endfunction

  // distanceBetween(enq, deq)：环形队列已用表项数 = (enq - deq) 取环长。
  function automatic logic [SQ_IDX_W:0] sq_distance(input sqptr_t enq, input sqptr_t deq);
    if (enq.flag == deq.flag) return enq.value - deq.value;
    else                      return SQ_SIZE - deq.value + enq.value;
  endfunction

  // isAfter(a, b)：a 是否比 b 更「新」（robIdx/sqPtr 环形比较）。
  //   golden 展开为 `fa ^ fb ^ (va > vb)`（与 flag 异或折叠），逐位对齐：
  //     同 flag → (va > vb)；异 flag → ~(va > vb) = (va <= vb)。
  //   ⚠ 之前实现异 flag 用 (va < vb)，在「异 flag 且 va==vb」的边角与 golden 分叉
  //     （addr/dataReadyPtr redirect 回退项两侧失配根因；FM 穷举下 va==vb 可达）。
  function automatic logic ptr_is_after(input sqptr_t a, input sqptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // UIntToMask(ptr, n)：低 ptr 位为 1 的掩码（环形 forward 范围用）。
  function automatic logic [SQ_SIZE-1:0] uint_to_mask(input logic [SQ_IDX_W-1:0] ptr);
    logic [SQ_SIZE-1:0] m;
    for (int i = 0; i < SQ_SIZE; i++) m[i] = (i[SQ_IDX_W-1:0] < ptr);
    return m;
  endfunction

  // PriorityEncoder：返回最低位 1 的下标（用于就绪指针前移步数；输入末位恒 1 保证有解）。
  function automatic logic [SQ_IDX_W:0] prio_first_one(input logic [ISSUE_STRIDE:0] v);
    prio_first_one = '0;
    for (int i = ISSUE_STRIDE; i >= 0; i--) if (v[i]) prio_first_one = i[SQ_IDX_W:0];
  endfunction

  // popcount(SQ_SIZE 位)：valid 计数 / force_write 阈值用。
  function automatic logic [SQ_IDX_W:0] popcnt_sq(input logic [SQ_SIZE-1:0] v);
    popcnt_sq = '0;
    for (int i = 0; i < SQ_SIZE; i++) popcnt_sq += {{SQ_IDX_W{1'b0}}, v[i]};
  endfunction

  // popcount(COMMIT_W 位)：一拍提交数。
  function automatic logic [3:0] popcnt_commit(input logic [COMMIT_W-1:0] v);
    popcnt_commit = '0;
    for (int i = 0; i < COMMIT_W; i++) popcnt_commit += {3'b0, v[i]};
  endfunction

  // 反向优先编码：取最高位 1 的下标（OHToUInt(Reverse(PriorityEncoderOH(Reverse(x))))）。
  //   forward 的 addrInvalid/dataInvalidSqIdx 用：在命中掩码里取「最靠近 enq 的那个」。
  function automatic logic [SQ_IDX_W-1:0] rev_prio_idx(input logic [SQ_SIZE-1:0] v);
    rev_prio_idx = '0;
    for (int i = 0; i < SQ_SIZE; i++) if (v[i]) rev_prio_idx = i[SQ_IDX_W-1:0];
  endfunction

  // shiftMaskToLow：把 mask 按 paddr 低 4 位右移对齐到字节 0（mmio/nc 发请求用）。
  function automatic logic [VLEN_BYTES-1:0] shift_mask_low(input logic [PADDR_BITS-1:0] pa,
                                                            input logic [VLEN_BYTES-1:0] mask);
    return mask >> pa[3:0];
  endfunction

  // shiftDataToLow：把 data 按 paddr 低 4 位（*8）右移对齐（mmio/nc 发请求用）。
  function automatic logic [VLEN-1:0] shift_data_low(input logic [PADDR_BITS-1:0] pa,
                                                     input logic [VLEN-1:0] data);
    return data >> ({1'b0, pa[3:0]} << 3);
  endfunction

endpackage
