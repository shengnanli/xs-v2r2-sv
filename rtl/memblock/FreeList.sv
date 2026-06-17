// =====================================================================
// xs_FreeList_core —— 访存队列「空闲槽位表」可读重写
// ---------------------------------------------------------------------
// 功能定位(MemBlock)：为 Load/Store 队列(如 LoadQueueRAW)管理条目【槽位号】
// 的空闲池。入队的访存指令向本表【分配(alloc)】一个空闲槽位号作为它在队列里的
// 索引；条目完成/被清除时，把槽位号【释放(free)】回池以便复用。
//
// 数据通路(本例化 size=16, 双分配口, 双释放 bank, 无预分配)：
//   1) 释放位图 io_free：每位表示该槽位本拍被释放。先累加进 freeMask(避免一次
//      释放过多来不及回收)。
//   2) bank 优先编码：把 16 位 freeMask 按"下标 mod FREE_WIDTH"分成 FREE_WIDTH
//      个 bank，每 bank 用 PriorityEncoder 挑一个待回收槽位 → freeSlotOH。
//   3) 打一拍(freeReq/freeSlotOH 寄存)后，把选中的槽位号 OHToUInt 写回 freeList
//      的 tailPtr 位置，并推进 tailPtr；同时把已回收位从 freeMask 清掉。
//   4) 分配：allocateSlot(i) = freeList(headPtr + i)；headPtr 按 doAllocate 个数前移。
//   5) 计数：freeSlotCnt = 队列内有效(空闲)条目数；validCount=size-空闲；empty=空闲为0。
//
// 与重命名 StdFreeList 的差别：这里释放接口是【位图】并带 bank 优先编码 + 打拍，
// 因为释放来源分散(多条目可能同拍释放)，需要序列化为每拍 freeWidth 个回收。
// =====================================================================
module xs_FreeList_core
  import freelist_pkg::*;
(
  input  logic                     clock,
  input  logic                     reset,

  // 分配口：给出空闲槽位号；doAllocate 表示该口本拍确实取走一个
  output logic [IDX_W-1:0]         io_allocateSlot [ALLOC_WIDTH],
  input  logic [ALLOC_WIDTH-1:0]   io_doAllocate,

  // 释放位图：每位代表对应槽位本拍被释放回池
  input  logic [SIZE-1:0]          io_free,

  output logic [CNT_W-1:0]         io_validCount,  // 已占用条目数
  output logic                     io_empty        // 空闲池是否为空
);

  // -------------------- 小工具函数 --------------------
  // 取 freeMask 中"下标 % FREE_WIDTH == rem"的那些位，压成一个 (SIZE/FREE_WIDTH) 位向量
  function automatic logic [SIZE/FREE_WIDTH-1:0] get_rem_bits
      (input logic [SIZE-1:0] in, input int rem);
    logic [SIZE/FREE_WIDTH-1:0] y;
    begin
      y = '0;
      for (int i = 0; i < SIZE/FREE_WIDTH; i++)
        y[i] = in[FREE_WIDTH*i + rem];
      return y;
    end
  endfunction

  // 最低位优先的 one-hot(PriorityEncoderOH)：返回最低置位的 one-hot
  function automatic logic [SIZE/FREE_WIDTH-1:0] prio_oh
      (input logic [SIZE/FREE_WIDTH-1:0] x);
    logic [SIZE/FREE_WIDTH-1:0] y;
    logic                       found;
    begin
      y = '0; found = 1'b0;
      for (int i = 0; i < SIZE/FREE_WIDTH; i++)
        if (!found && x[i]) begin y[i] = 1'b1; found = 1'b1; end
      return y;
    end
  endfunction

  // one-hot → 槽位号(OHToUInt)
  function automatic logic [IDX_W-1:0] oh_to_idx(input logic [SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    begin
      r = '0;
      for (int i = 0; i < SIZE; i++)
        if (oh[i]) r |= IDX_W'(i);
      return r;
    end
  endfunction

  function automatic logic [IDX_W:0] popcnt_alloc(input logic [ALLOC_WIDTH-1:0] v);
    logic [IDX_W:0] s; begin s='0; for(int k=0;k<ALLOC_WIDTH;k++) if(v[k]) s+=1'b1; return s; end
  endfunction
  function automatic logic [IDX_W:0] popcnt_free(input logic [FREE_WIDTH-1:0] v);
    logic [IDX_W:0] s; begin s='0; for(int k=0;k<FREE_WIDTH;k++) if(v[k]) s+=1'b1; return s; end
  endfunction
  function automatic logic [IDX_W:0] popcnt_free_below(input logic [FREE_WIDTH-1:0] v, input int i);
    logic [IDX_W:0] s; begin s='0; for(int k=0;k<FREE_WIDTH;k++) if(k<i && v[k]) s+=1'b1; return s; end
  endfunction

  // =====================================================================
  // 1. 存储 + 指针 + 释放打拍寄存器
  // =====================================================================
  logic [IDX_W-1:0] freeList [SIZE];
  fl_ptr_t          headPtr;   // 分配出队端
  fl_ptr_t          tailPtr;   // 释放入队端
  logic [SIZE-1:0]  freeMask;  // 待回收位图(尚未写回 freeList 的释放请求)
  logic [CNT_W-1:0] freeSlotCnt;

  // 上一拍选出的待回收(打拍)：freeReq[b] 表示 bank b 本拍有回收，freeSlotOH[b] 是其 one-hot
  logic [FREE_WIDTH-1:0]            freeReqReg;
  logic [SIZE-1:0]                  freeSlotOHReg [FREE_WIDTH];

  // =====================================================================
  // 2. 释放路径：bank 优先编码，从 freeMask 选本拍要回收的槽位
  // =====================================================================
  // 本拍已被选中(打拍后)的位，需从 freeMask 中扣除，避免重复回收
  logic [SIZE-1:0] freeSelMask;
  always_comb begin
    freeSelMask = '0;
    for (int b = 0; b < FREE_WIDTH; b++)
      if (freeReqReg[b]) freeSelMask |= freeSlotOHReg[b];
  end

  // 各 bank 本拍的候选(freeMask 去掉已选)、优先 one-hot、以及散回 SIZE 位的 one-hot
  logic [SIZE/FREE_WIDTH-1:0] remFreeSelMask   [FREE_WIDTH];
  logic [SIZE-1:0]            remFreeSelIndexOH [FREE_WIDTH];
  logic [FREE_WIDTH-1:0]      freeReqNext;
  always_comb begin
    for (int b = 0; b < FREE_WIDTH; b++) begin
      logic [SIZE/FREE_WIDTH-1:0] hi;
      remFreeSelMask[b] = get_rem_bits(freeMask & ~freeSelMask, b);
      hi               = prio_oh(remFreeSelMask[b]);
      // 把 bank 内 one-hot 散回 SIZE 位(位置 = i*FREE_WIDTH + b)
      remFreeSelIndexOH[b] = '0;
      for (int i = 0; i < SIZE/FREE_WIDTH; i++)
        remFreeSelIndexOH[b][i*FREE_WIDTH + b] = hi[i];
      freeReqNext[b] = |remFreeSelMask[b];
    end
  end

  // =====================================================================
  // 3. 释放写回(下一拍生效)：把打拍后选中的槽位号写入 freeList[tailPtr+offset]
  //    高编号 bank 优先(与 golden 一致；正常下各 bank 写不同地址不冲突)。
  //    用显式地址译码(常量比较)避免变量下标越界 X。
  // =====================================================================
  logic [IDX_W-1:0] freeEnqIdx [FREE_WIDTH];
  always_comb
    for (int b = 0; b < FREE_WIDTH; b++) begin
      fl_ptr_t enq;
      enq = ptr_add(tailPtr, popcnt_free_below(freeReqReg, b));
      freeEnqIdx[b] = enq.value;
    end

  logic doFree;
  always_comb doFree = |freeReqReg;

  // =====================================================================
  // 4. 分配：allocateSlot(i) = freeList(headPtr + i)
  // =====================================================================
  always_comb
    for (int i = 0; i < ALLOC_WIDTH; i++) begin
      fl_ptr_t deq;
      deq = ptr_add(headPtr, IDX_W'(i));
      io_allocateSlot[i] = freeList[deq.value];
    end

  // =====================================================================
  // 5. 指针/计数下一值
  // =====================================================================
  wire doAllocate = |io_doAllocate;
  wire fl_ptr_t headPtrNext = ptr_add(headPtr, popcnt_alloc(io_doAllocate));
  wire fl_ptr_t tailPtrNext = ptr_add(tailPtr, popcnt_free(freeReqReg));

  // 空闲条目数 = tailPtrNext 与 headPtrNext 的循环距离(distanceBetween)。
  //   flag 相同：tail.value - head.value
  //   flag 不同：SIZE + tail.value - head.value
  logic [CNT_W-1:0] freeSlotCntNext;
  always_comb begin
    if (tailPtrNext.flag == headPtrNext.flag)
      // flag 相同：在 IDX_W 位内相减(借位自然回绕，top bit 恒 0)，再零扩展。
      // 与 golden 的 {1'h0, 4'(tail.value - head.value)} 完全一致。
      freeSlotCntNext = {1'b0, IDX_W'(tailPtrNext.value - headPtrNext.value)};
    else
      // flag 不同：SIZE + tail.value - head.value
      freeSlotCntNext = CNT_W'(CNT_W'({1'b0,tailPtrNext.value}) + CNT_W'(SIZE)
                               - CNT_W'({1'b0,headPtrNext.value}));
  end

  // =====================================================================
  // 6. 时序更新(异步复位，与 golden 一致)
  // =====================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < SIZE; i++) freeList[i] <= IDX_W'(i);
      headPtr   <= '{flag:1'b0, value:'0};
      tailPtr   <= '{flag:1'b1, value:'0};
      freeMask  <= '0;
      freeReqReg <= '0;
      for (int b = 0; b < FREE_WIDTH; b++) freeSlotOHReg[b] <= '0;
      freeSlotCnt <= CNT_W'(SIZE);
    end else begin
      // 释放写回：对每个条目 E 译码，命中则写其槽位号(高 bank 优先)
      for (int e = 0; e < SIZE; e++)
        for (int b = 0; b < FREE_WIDTH; b++)
          if (freeReqReg[b] && freeEnqIdx[b] == IDX_W'(e))
            freeList[e] <= oh_to_idx(freeSlotOHReg[b]);

      if (doAllocate) headPtr <= headPtrNext;
      if (doFree)     tailPtr <= tailPtrNext;

      // freeMask 累加新释放、扣除本拍已选中
      freeMask <= (io_free | freeMask) & ~freeSelMask;

      // freeReq/freeSlotOH 打拍(仅在值变化时更新，匹配 golden 的条件赋值)
      for (int b = 0; b < FREE_WIDTH; b++) begin
        if (freeReqNext[b] != freeReqReg[b])
          freeReqReg[b] <= freeReqNext[b];
        if (remFreeSelIndexOH[b] != freeSlotOHReg[b])
          freeSlotOHReg[b] <= remFreeSelIndexOH[b];
      end

      freeSlotCnt <= freeSlotCntNext;
    end
  end

  // =====================================================================
  // 7. 输出
  // =====================================================================
  assign io_validCount = CNT_W'(SIZE) - freeSlotCnt;
  assign io_empty      = (freeSlotCnt == '0);

endmodule
