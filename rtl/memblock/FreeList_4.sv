// =============================================================================
//  FreeList_4 —— LoadQueueRAW 空闲条目环形 freelist（可读重写，镜像 golden 层次）
// -----------------------------------------------------------------------------
//  设计意图来源: src/main/scala/xiangshan/mem/lsqueue/FreeList.scala
//    参数: size=32, allocWidth=3, freeWidth=4, moduleName="LoadQueueRAWFreelist",
//          enablePreAlloc=true。
//
//  与 golden LoadQueueRAW.sv 内例化的 `FreeList_4 freeList` 端口/内部寄存器逐一对应，
//  用于 FM 层次化配对（避免与 LoadQueueRAW 主体一起被展平后签名匹配组合爆炸）。
//
//  ── 状态寄存器（与 golden 同名，便于 FM auto-match）──
//    freeList_0..31        : 32 深循环队列，存空闲条目索引（初值 = 单位排列 i）
//    headPtr_{flag,value}  : 分配指针（deq 端），value 5 位 + flag 1 位环绕
//    tailPtr_{flag,value}  : 回收指针（enq 端），复位 flag=1 表示满
//    freeMask[31:0]        : 待回收条目累积掩码（pendingFreeMask）
//    freeReq_next_nextVec_{0..3}_r    : 4 个回收 lane 的“本拍有回收请求”寄存
//    freeSlotOH_next_nextVec_{0..3}_r : 4 个回收 lane 选中的 32 位 one-hot 寄存
//    freeSlotCnt[5:0]      : 空闲槽数 = distanceBetween(tailPtr, headPtr)
//    io_canAllocate_{0..2}_r / io_allocateSlot_{0..2}_r : preAlloc 分配输出寄存
//
//  分配（deq）: 每拍从 headPtr 起连续取 allocWidth 个槽做 preAlloc（下一拍可用）；
//    真正 doAllocate 时推进 headPtr。
//  回收（enq）: freeMask 收集本拍 io_free 中的置位，freeWidth=4 lane 各按 bank 低位
//    优先选一个空闲条目，寄存其 one-hot；下一拍把 OHToUInt(one-hot) 写回 freeList 队尾，
//    推进 tailPtr。
// =============================================================================
module FreeList_4(
  input         clock,
  input         reset,
  output [4:0]  io_allocateSlot_0,
  output [4:0]  io_allocateSlot_1,
  output [4:0]  io_allocateSlot_2,
  output        io_canAllocate_0,
  output        io_canAllocate_1,
  output        io_canAllocate_2,
  input         io_doAllocate_0,
  input         io_doAllocate_1,
  input         io_doAllocate_2,
  input  [31:0] io_free,
  output [5:0]  io_validCount,
  output        io_empty
);

  localparam int SIZE = 32;

  // ---- 状态寄存器 ----
  logic [4:0]  freeList [SIZE];
  logic        headPtr_flag;
  logic [4:0]  headPtr_value;
  logic        tailPtr_flag;
  logic [4:0]  tailPtr_value;
  logic [31:0] freeMask;
  logic        freeReq_next_nextVec_r  [4];
  logic [31:0] freeSlotOH_next_nextVec_r [4];
  logic [5:0]  freeSlotCnt;
  logic        io_canAllocate_r  [3];
  logic [4:0]  io_allocateSlot_r [3];

  // ===========================================================================
  //  分配预取（preAlloc）：deqPtr = headPtr + numDoAllocate + w
  // ===========================================================================
  logic [5:0] headPtr_ptr;
  logic [1:0] numDoAllocate;
  assign headPtr_ptr   = {headPtr_flag, headPtr_value};
  assign numDoAllocate = 2'({1'b0, io_doAllocate_0} +
                            2'({1'b0, io_doAllocate_1} + {1'b0, io_doAllocate_2}));

  logic [5:0] deqPtr [3];
  always_comb
    for (int w = 0; w < 3; w++)
      deqPtr[w] = 6'(headPtr_ptr + 6'(6'(numDoAllocate) + 6'(w)));

  // canAllocate = deqPtr isBefore tailPtr（CircularQueuePtr <）
  // isBefore(a,b) = a.flag ^ b.flag ^ (a.value < b.value)
  logic       canAllocate_next  [3];
  logic [4:0] allocateSlot_next [3];
  always_comb
    for (int w = 0; w < 3; w++) begin
      canAllocate_next[w]  = deqPtr[w][5] ^ tailPtr_flag ^ (deqPtr[w][4:0] < tailPtr_value);
      allocateSlot_next[w] = freeList[deqPtr[w][4:0]];
    end

  // ===========================================================================
  //  回收（enq）：freeMask 累积 io_free，freeWidth=4 lane 低位优先选空闲条目
  // ===========================================================================
  // 已被本拍寄存的 4 lane one-hot 占用的位（下一拍要写回，故从可选集合排除）
  logic [31:0] alreadyPicked;
  always_comb begin
    alreadyPicked = '0;
    for (int l = 0; l < 4; l++)
      if (freeReq_next_nextVec_r[l]) alreadyPicked |= freeSlotOH_next_nextVec_r[l];
  end
  //  ★选择候选集合仅用**已寄存的 pendingFreeMask**(freeMask), **不含本拍 io_free**:
  //  golden remFreeSelMaskVec 门控 = `freeMask & ~alreadyPicked`(io_free 不进本拍选择)。
  //  本拍到来的 io_free 只累积进 freeMask 的 next-state(见时序块), 下一拍才可被选中。
  //  (此前误用 (io_free|freeMask) 作选择集 → 与 golden freeSlotOH_next 不等价。)
  logic [31:0] availMask;
  assign availMask = freeMask & ~alreadyPicked;

  // 4 lane 各取余数为 lane 的位（bank 交织：位 4*i+lane），低位优先选一个
  logic [7:0]  remMaskVec [4];   // 每 lane 的 8 位候选（bank 内）
  logic [7:0]  remOHVec   [4];   // 每 lane 8 位最低位 one-hot
  logic [31:0] remSelOH   [4];   // 每 lane 展回 32 位 one-hot
  logic        freeReq_next  [4];
  always_comb
    for (int l = 0; l < 4; l++) begin
      for (int i = 0; i < 8; i++) remMaskVec[l][i] = availMask[4*i + l];
      remOHVec[l]  = remMaskVec[l] & (~remMaskVec[l] + 8'd1); // 最低置位独热
      remSelOH[l]  = '0;
      for (int i = 0; i < 8; i++) remSelOH[l][4*i + l] = remOHVec[l][i];
      freeReq_next[l] = |remMaskVec[l];
    end

  // ===========================================================================
  //  OHToUInt：把选中的 32 位 one-hot 折算为 5 位索引（写回 freeList 队尾用）
  // ===========================================================================
  function automatic logic [4:0] oh32_to_idx(input logic [31:0] oh);
    logic [14:0] t1; logic [6:0] t3; logic [2:0] t5;
    t1 = oh[31:17] | oh[15:1];
    t3 = t1[14:8] | t1[6:0];
    t5 = t3[6:4] | t3[2:0];
    return {|oh[31:16], |t1[14:7], |t3[6:3], |t5[2:1], t5[2] | t5[0]};
  endfunction

  logic [4:0] recycleIdx [4];    // 各 lane 寄存 OH 折算的索引（写回 freeList）
  always_comb
    for (int l = 0; l < 4; l++)
      recycleIdx[l] = oh32_to_idx(freeSlotOH_next_nextVec_r[l]);

  // 回收写回位置 = tailPtr + 前面 lane 的有效数（PopCount 前缀）
  logic [4:0] enqIdx [4];
  always_comb
    for (int l = 0; l < 4; l++) begin
      logic [2:0] off;
      off = 3'd0;
      for (int k = 0; k < 4; k++) if (k < l && freeReq_next_nextVec_r[k]) off = off + 3'd1;
      enqIdx[l] = 5'(tailPtr_value + 5'(off));
    end

  // ===========================================================================
  //  指针推进
  // ===========================================================================
  logic [5:0] headPtrNext, tailPtrNext;
  logic [2:0] numFree;
  assign headPtrNext = 6'(headPtr_ptr + {4'h0, numDoAllocate});
  always_comb begin
    numFree = 3'd0;
    for (int l = 0; l < 4; l++) if (freeReq_next_nextVec_r[l]) numFree = numFree + 3'd1;
  end
  assign tailPtrNext = 6'({tailPtr_flag, tailPtr_value} + {3'h0, numFree});

  logic doAllocateAny, doFreeAny;
  assign doAllocateAny = io_doAllocate_0 | io_doAllocate_1 | io_doAllocate_2;
  always_comb begin
    doFreeAny = 1'b0;
    for (int l = 0; l < 4; l++) doFreeAny |= freeReq_next_nextVec_r[l];
  end

  // freeSlotCnt = distanceBetween(tailPtrNext, headPtrNext)
  logic [5:0] freeSlotCntNext;
  always_comb begin
    if (tailPtrNext[5] == headPtrNext[5])
      freeSlotCntNext = {1'h0, 5'(tailPtrNext[4:0] - headPtrNext[4:0])};
    else
      freeSlotCntNext = 6'(6'({1'h0, tailPtrNext[4:0]} - 6'h20) - {1'h0, headPtrNext[4:0]});
  end

  // ===========================================================================
  //  时序
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < SIZE; i++) freeList[i] <= 5'(unsigned'(i));
      headPtr_flag  <= 1'b0; headPtr_value <= 5'h0;
      tailPtr_flag  <= 1'b1; tailPtr_value <= 5'h0;
      freeMask      <= 32'h0;
      for (int l = 0; l < 4; l++) begin
        freeReq_next_nextVec_r[l]  <= 1'b0;
        freeSlotOH_next_nextVec_r[l] <= 32'h0;
      end
      freeSlotCnt <= 6'h20;
    end else begin
      // freeList 队尾写回（每 lane 若有回收请求，写到 enqIdx[l]）
      for (int l = 0; l < 4; l++)
        if (freeReq_next_nextVec_r[l])
          freeList[enqIdx[l]] <= recycleIdx[l];
      // 指针
      if (doAllocateAny) begin
        headPtr_flag  <= headPtrNext[5];
        headPtr_value <= headPtrNext[4:0];
      end
      if (doFreeAny) begin
        tailPtr_flag  <= tailPtrNext[5];
        tailPtr_value <= tailPtrNext[4:0];
      end
      // pendingFreeMask 更新：累积 io_free，扣除已选走的
      freeMask <= (io_free | freeMask) & ~alreadyPicked;
      // 回收 lane 请求 / one-hot 寄存
      for (int l = 0; l < 4; l++) begin
        freeReq_next_nextVec_r[l]     <= freeReq_next[l];
        freeSlotOH_next_nextVec_r[l]  <= remSelOH[l];
      end
      freeSlotCnt <= freeSlotCntNext;
    end
  end

  // preAlloc 分配输出寄存
  always_ff @(posedge clock) begin
    for (int w = 0; w < 3; w++) begin
      io_canAllocate_r[w]  <= canAllocate_next[w];
      io_allocateSlot_r[w] <= allocateSlot_next[w];
    end
  end

  assign io_allocateSlot_0 = io_allocateSlot_r[0];
  assign io_allocateSlot_1 = io_allocateSlot_r[1];
  assign io_allocateSlot_2 = io_allocateSlot_r[2];
  assign io_canAllocate_0  = io_canAllocate_r[0];
  assign io_canAllocate_1  = io_canAllocate_r[1];
  assign io_canAllocate_2  = io_canAllocate_r[2];
  assign io_validCount     = 6'(6'h20 - freeSlotCnt);
  assign io_empty          = freeSlotCnt == 6'h0;

endmodule
