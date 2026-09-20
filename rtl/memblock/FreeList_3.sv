// =============================================================================
// FreeList_3 —— FreeList 单态化变体：72 项 / 3 分配口 / 4 释放 bank / 无 preAlloc
//
// 使用者：LoadQueueRAR（LoadQueueRAR.scala:115 `new FreeList(size = LoadQueueRARSize,
// allocWidth = LoadPipelineWidth, freeWidth = 4, enablePreAlloc = false,
// moduleName = "LoadQueueRAR freelist")`；KunminghuV2 下 LoadQueueRARSize = 72、
// LoadPipelineWidth = 3）。本表分配的是 RAR 队列的 72 个条目槽位号（7 位）。
//
// 与同为 72 项的 FreeList_5（LoadQueueReplay）的**唯一**差别是 enablePreAlloc：
//   _3 组合给出 io_allocateSlot / io_canAllocate（读指针 = headPtr + i）；
//   _5 打一拍给出（读指针 = headPtr + numAllocate + i）。
// 另外 _3 导出 io_validCount 而 _5 没有（_5 的使用者不看，被 firtool 裁掉）。
//
// ★72 不是 2 的幂★：指针 {flag,value} 的 value 是 7 位（0..127），而有效范围只有
//   0..71，所以每次 `+` 都要显式减 72 判回绕；golden 把 freeList 的读展开成
//   **128 项**查找表，72..127 这些越界项全部填 freeList_0（实测 golden
//   FreeList_3.sv:195 `wire [127:0][6:0] _GEN_0` 的前 56 项都是 {freeList_0}）。
//   核里按同一形状写（默认第 0 项 + 逐项常量比较覆盖），不用变量下标。
// 核体见 rtl/memblock/FreeList.sv（xs_FreeList_core），本文件仅设参数与端口展平。
// =============================================================================
module FreeList_3(
  input         clock,
  input         reset,
  output [6:0]  io_allocateSlot_0,
  output [6:0]  io_allocateSlot_1,
  output [6:0]  io_allocateSlot_2,
  output        io_canAllocate_0,
  output        io_canAllocate_1,
  output        io_canAllocate_2,
  input         io_doAllocate_0,
  input         io_doAllocate_1,
  input         io_doAllocate_2,
  input  [71:0] io_free,
  output [6:0]  io_validCount,
  output        io_empty
);
  logic [6:0] allocateSlot [3];
  logic [2:0] canAllocate;

  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];
  assign io_allocateSlot_2 = allocateSlot[2];
  assign {io_canAllocate_2, io_canAllocate_1, io_canAllocate_0} = canAllocate;

  xs_FreeList_core #(
    .SIZE(72), .ALLOC_WIDTH(3), .FREE_WIDTH(4), .ENABLE_PRE_ALLOC(1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_allocateSlot (allocateSlot),
    .io_canAllocate  (canAllocate),
    .io_doAllocate   ({io_doAllocate_2, io_doAllocate_1, io_doAllocate_0}),
    .io_free         (io_free),
    .io_validCount   (io_validCount),
    .io_empty        (io_empty)
  );
endmodule
