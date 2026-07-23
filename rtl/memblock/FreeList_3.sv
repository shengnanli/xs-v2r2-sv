// =============================================================================
//  FreeList_3 —— LoadQueueRAR 分区证明「块 1：allocation / free-list」的
//               可读重写（standalone canary）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala
//
//  ── 本文件是什么 ────────────────────────────────────────────────────────────
//  LoadQueueRAR 分区证明 plan（verif/signoff/loadqueuerar_partition_plan.md）把整
//  LoadQueueRAR 拆成三块，块 1 = 空闲槽循环队列（golden 里就是独立子模块 FreeList_3）。
//  本模块把 rtl/memblock/LoadQueueRAR.sv 里内联的 freelist 逻辑（第 92-137 / 316-425
//  行）提取成一个 **端口与 golden FreeList_3 逐一对应** 的 standalone 模块，供 FM 做
//  块级关系等价证明（golden FreeList_3 ↔ 本模块，同名 FM_TOP）。
//
//  ── 块 1 的抽象关系 R1（reset 建立 + 每拍更新保持 + 推出输出一致）──────────────
//  状态对应（golden 平寄存器 ↔ 本模块结构/数组）：
//      golden.headPtr_{flag,value}                  ≡ headPtr.{flag,value}
//      golden.tailPtr_{flag,value}                  ≡ tailPtr.{flag,value}
//      golden.freeList_i          (i∈[0,72))        ≡ freeList[i]
//      golden.freeMask                              ≡ freeMask
//      golden.freeReq_next_nextVec_r_r  (r∈[0,4))   ≡ freeReq_d[r]
//      golden.freeSlotOH_next_nextVec_r_r           ≡ freeSelOH_d[r]
//      golden.freeSlotCnt                           ≡ freeSlotCnt
//  证明义务（FM 承担归纳）：
//    (R1-reset)  reset 后：headPtr=(0,0)、tailPtr=(1,0)、freeList={0..71}、
//                freeMask=0、freeReq/freeSlotOH pipe=0、freeSlotCnt=72。
//    (R1-update) 给定 R1 与相同输入 {io_doAllocate_*, io_free}，下一拍两侧 R1 保持。
//    (R1-output) R1 ⟹ io_allocateSlot_* / io_canAllocate_* / io_validCount / io_empty
//                逐 bit 一致。
//
//  ── 关键时序不变式（极易写错，与 golden 逐拍对齐）──────────────────────────────
//   · 分配侧组合：deqPtr(w)=ptr_add(headPtr, PopCount(doAllocate.take(w)))；
//                 allocateSlot(w)=freeList[deqPtr(w).value]；
//                 canAllocate(w)=isBefore(deqPtr(w), tailPtr)。
//   · 回收侧两拍流水：本拍用 **上一拍寄存的** freeReq_d/freeSelOH_d 写回 freeList
//                     并推进 tailPtr；freeMask 累积寄存；选择候选池只看寄存器 freeMask
//                     去掉本拍正在写回的 freeSelMask，不含本拍 io_free。
//   · freeSlotCnt = distanceBetween(tailPtrNext, headPtrNext)（异 flag 时 -56 ≡ +72 mod128）。
//   · 异步 reset：golden 是 always @(posedge clock or posedge reset)，本模块照搬。
// =============================================================================
module FreeList_3
  import loadqueuerar_pkg::*;
(
  input  logic          clock,
  input  logic          reset,
  output logic [6:0]    io_allocateSlot_0,
  output logic [6:0]    io_allocateSlot_1,
  output logic [6:0]    io_allocateSlot_2,
  output logic          io_canAllocate_0,
  output logic          io_canAllocate_1,
  output logic          io_canAllocate_2,
  input  logic          io_doAllocate_0,
  input  logic          io_doAllocate_1,
  input  logic          io_doAllocate_2,
  input  logic [71:0]   io_free,
  output logic [6:0]    io_validCount,
  output logic          io_empty
);

  // ===========================================================================
  //  状态寄存器（对应 R1 的实现侧）
  // ===========================================================================
  // 空闲编号循环缓冲：深度取真实 RAR_SIZE（72），镜像 golden freeList_0..71。
  //  headPtr.value / tailPtr.value 恒 <72（ptr_add 在 >=72 时回绕），故 7-bit 索引恒在界，
  //  无需过配到 2^IDX_W（128）——过配会留 56 个死槽（golden 无对应寄存器）。
  logic [IDX_W-1:0] freeList [RAR_SIZE];
  free_ptr_t        headPtr, tailPtr;       // 分配头 / 回收尾
  logic [CNT_W-1:0] freeSlotCnt;            // 当前空闲槽数（0..72）

  // 回收侧两拍流水寄存器
  logic [RAR_SIZE-1:0]                  freeMask;      // 待回收累积掩码
  logic [FREE_WIDTH-1:0]                freeReq_d;     // 上拍选择寄存（本拍写回）
  logic [FREE_WIDTH-1:0][RAR_SIZE-1:0]  freeSelOH_d;

  // 把三口 doAllocate 收成向量，方便读
  logic [LD_WIDTH-1:0] doAllocateVec;
  assign doAllocateVec = {io_doAllocate_2, io_doAllocate_1, io_doAllocate_0};

  // ===========================================================================
  //  分配侧（组合）：deqPtr / allocateSlot / canAllocate
  //  ── 边界语义（与 golden FreeList_3 一致，勿混入 top-level 逻辑）──────────────
  //  FreeList（enablePreAlloc=false）对第 w 个分配口 **固定** 呈现 headPtr+w 处的槽：
  //      allocateSlot(w) = freeList[(headPtr + w).value]
  //      canAllocate(w)  = isBefore(headPtr + w, tailPtr)
  //  offset 是常量 0/1/2，**不** 由 io_doAllocate 门控（那是 LoadQueueRAR 顶层把
  //  needEnqueue 端口按 PopCount 映射到连续槽的逻辑，属块外，不在本模块）。
  // ===========================================================================
  // 128-wide 填充读向量（镜像 golden `_GEN_0`）：72..127 别名到 freeList[0]。
  //  存储只有 RAR_SIZE(72) 个寄存器，但 7-bit 索引读经此填充向量恒在界，
  //  既消 Formality FMR_ELAB-147「index may exceed array bound」又不留死存储槽。
  logic [IDX_W-1:0] freeListPad [(1<<IDX_W)];
  always_comb begin
    for (int n = 0; n < (1<<IDX_W); n++)
      freeListPad[n] = (n < RAR_SIZE) ? freeList[n] : freeList[0];
  end

  free_ptr_t        alloc_deqPtr [LD_WIDTH];
  logic [IDX_W-1:0] alloc_slot   [LD_WIDTH];
  logic             alloc_can    [LD_WIDTH];
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      alloc_deqPtr[w] = ptr_add(headPtr, IDX_W'(w));   // 固定 offset = w（0/1/2）
      alloc_slot[w]   = freeListPad[alloc_deqPtr[w].value];
      alloc_can[w]    = free_is_before(alloc_deqPtr[w], tailPtr);
    end
  end
  assign io_allocateSlot_0 = alloc_slot[0];
  assign io_allocateSlot_1 = alloc_slot[1];
  assign io_allocateSlot_2 = alloc_slot[2];
  assign io_canAllocate_0  = alloc_can[0];
  assign io_canAllocate_1  = alloc_can[1];
  assign io_canAllocate_2  = alloc_can[2];

  // ===========================================================================
  //  回收侧（组合）：freeSelMask（本拍写回）+ 本拍新选择
  // ===========================================================================
  logic [RAR_SIZE-1:0] freeSelMask;   // 本拍正在写回 freeList 的槽（来自寄存的上拍选择）
  always_comb begin
    freeSelMask = '0;
    for (int r = 0; r < FREE_WIDTH; r++)
      if (freeReq_d[r]) freeSelMask |= freeSelOH_d[r];
  end

  logic [FREE_WIDTH-1:0]                freeReq_c;    // 本拍组合：各 rem-bank 有无可回收
  logic [FREE_WIDTH-1:0][RAR_SIZE-1:0]  freeSelOH_c;  // 本拍组合：各 rem-bank 选中 one-hot
  always_comb begin
    logic [RAR_SIZE-1:0] avail;
    avail = freeMask & ~freeSelMask;   // 候选 = 寄存器 freeMask 去掉本拍写回；不含本拍 io_free
    for (int r = 0; r < FREE_WIDTH; r++) begin
      logic [RAR_SIZE/FREE_WIDTH-1:0] remBits;
      logic found;
      freeSelOH_c[r] = '0;
      remBits = '0;
      for (int j = 0; j < RAR_SIZE/FREE_WIDTH; j++)
        remBits[j] = avail[j*FREE_WIDTH + r];
      found = 1'b0;
      for (int j = 0; j < RAR_SIZE/FREE_WIDTH; j++)   // PriorityEncoderOH：取最低有效位
        if (!found && remBits[j]) begin
          freeSelOH_c[r][j*FREE_WIDTH + r] = 1'b1;
          found = 1'b1;
        end
      freeReq_c[r] = |remBits;
    end
  end

  // ===========================================================================
  //  指针 / 计数（组合下一态）
  // ===========================================================================
  logic [IDX_W-1:0] numAllocate;
  logic             doAllocate;
  logic [IDX_W-1:0] numFree;
  logic             doFree;
  always_comb begin
    numAllocate = '0; doAllocate = 1'b0;
    for (int w = 0; w < LD_WIDTH; w++) numAllocate += {6'b0, doAllocateVec[w]};
    doAllocate = |doAllocateVec;
    numFree = '0; doFree = 1'b0;
    for (int r = 0; r < FREE_WIDTH; r++) numFree += {6'b0, freeReq_d[r]};
    doFree = |freeReq_d;
  end

  free_ptr_t headPtrNext, tailPtrNext;
  always_comb begin
    headPtrNext = ptr_add(headPtr, numAllocate);
    tailPtrNext = ptr_add(tailPtr, numFree);
  end

  // ---- 回收写地址（组合预算）：rem-bank r 写到 tailPtr+offset(r) ----------------
  //   offset(r)=PopCount(freeReq_d.take(r))；enqValue(r) 是写入目标 entry 编号。
  //   写值 = oh_to_idx(freeSelOH_d[r])（该 bank 选中的槽编号）。
  //   预算成组合信号后，写回按 **每个存储槽 i 逐一比较 enqValue(r)==i**（镜像 golden
  //   的 per-index 结构），使数组写下标静态在界（消 FMR_ELAB-147）。
  logic [IDX_W-1:0] enqValue  [FREE_WIDTH];   // rem-bank r 的写目标 entry 编号
  logic [IDX_W-1:0] enqData   [FREE_WIDTH];   // rem-bank r 写入的 freeList 值
  always_comb begin
    for (int r = 0; r < FREE_WIDTH; r++) begin
      logic [IDX_W-1:0] foff;
      free_ptr_t        enqp;
      foff = '0;
      for (int k = 0; k < FREE_WIDTH; k++) if (k < r) foff += {6'b0, freeReq_d[k]};
      enqp        = ptr_add(tailPtr, foff);
      enqValue[r] = enqp.value;
      enqData[r]  = oh_to_idx(freeSelOH_d[r]);
    end
  end

  // ===========================================================================
  //  状态更新（异步 reset，镜像 golden 的 posedge clock or posedge reset）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      headPtr     <= '{flag:1'b0, value:'0};
      tailPtr     <= '{flag:1'b1, value:'0};
      freeSlotCnt <= CNT_W'(RAR_SIZE);
      freeMask    <= '0;
      freeReq_d   <= '0;
      freeSelOH_d <= '0;
      for (int n = 0; n < RAR_SIZE; n++) freeList[n] <= IDX_W'(n);
    end else begin
      if (doAllocate) headPtr <= headPtrNext;
      if (doFree)     tailPtr <= tailPtrNext;
      // 回收写 freeList：逐存储槽 i 选中写它的 rem-bank（优先级 r 高覆盖低 = 与 Chisel
      //   last-connect 一致，见 golden freeList_N 的 else-if 链 r=3>2>1>0）。
      //   per-index 比较使写下标静态在界。
      for (int i = 0; i < RAR_SIZE; i++)
        for (int r = 0; r < FREE_WIDTH; r++)
          if (freeReq_d[r] && enqValue[r] == IDX_W'(i))
            freeList[i] <= enqData[r];
      freeMask    <= (io_free | freeMask) & ~freeSelMask;   // io_free = LoadQueueRAR.freeMaskVec
      freeReq_d   <= freeReq_c;
      freeSelOH_d <= freeSelOH_c;
      freeSlotCnt <= free_distance(tailPtrNext, headPtrNext);
    end
  end

  assign io_validCount = CNT_W'(RAR_SIZE) - freeSlotCnt;
  assign io_empty      = (freeSlotCnt == '0);

  // ===========================================================================
  //  局部纯函数（与核内联版同定义；放此使模块自包含）
  // ===========================================================================
  function automatic free_ptr_t ptr_add(input free_ptr_t p, input logic [IDX_W-1:0] off);
    free_ptr_t r;
    logic [IDX_W:0] sum;
    sum = {1'b0, p.value} + {1'b0, off};
    if (sum >= RAR_SIZE) begin
      r.value = sum[IDX_W-1:0] - IDX_W'(RAR_SIZE);
      r.flag  = ~p.flag;
    end else begin
      r.value = sum[IDX_W-1:0];
      r.flag  = p.flag;
    end
    return r;
  endfunction

  function automatic logic free_is_before(input free_ptr_t a, input free_ptr_t b);
    return a.flag ^ b.flag ^ (a.value < b.value);
  endfunction

  function automatic logic [IDX_W-1:0] oh_to_idx(input logic [RAR_SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int i = 0; i < RAR_SIZE; i++) if (oh[i]) r |= IDX_W'(i);
    return r;
  endfunction

endmodule
