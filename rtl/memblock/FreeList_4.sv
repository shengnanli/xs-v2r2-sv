// =============================================================================
// FreeList_4 —— FreeList 单态化变体：32 项 / 3 分配口 / 4 释放 bank / preAlloc
//
// 使用者：LoadQueueRAW（LoadQueueRAW.scala:106 `new FreeList(size = LoadQueueRAWSize,
// allocWidth = LoadPipelineWidth, freeWidth = 4, enablePreAlloc = true,
// moduleName = "LoadQueueRAW freelist")`；KunminghuV2 下 LoadQueueRAWSize = 32、
// LoadPipelineWidth = 3）。本表分配的是 RAW 队列的 32 个条目槽位号（5 位）。
//
// 本变体是家族里唯一 32 项的：SIZE 是 2 的幂（与 16 项的 _6、非 2 幂的 _3/_5 对照），
// 所以指针 {flag,value} 拼成 6 位直接加即可回绕，freeList 的读也没有越界项。
// 指针 value 5 位、空闲计数 6 位。
//
// ★enablePreAlloc = true★：io_allocateSlot_* / io_canAllocate_* 各打一拍给出
//   （golden 里就是 io_allocateSlot_0_r / io_canAllocate_0_r 这 6 个寄存器），
//   读指针从 headPtr + 本拍分配数 起算。这 6 个寄存器**不带复位**
//   （Chisel `RegEnable(x, true.B)` 展开成无条件 always @(posedge clock)），
//   两轮 +vcs+initreg 都要过。
// 核体见 rtl/memblock/FreeList.sv（xs_FreeList_core），本文件仅设参数与端口展平。
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
  logic [4:0] allocateSlot [3];
  logic [2:0] canAllocate;

  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];
  assign io_allocateSlot_2 = allocateSlot[2];
  assign {io_canAllocate_2, io_canAllocate_1, io_canAllocate_0} = canAllocate;

  xs_FreeList_core #(
    .SIZE(32), .ALLOC_WIDTH(3), .FREE_WIDTH(4), .ENABLE_PRE_ALLOC(1'b1)
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
