// =============================================================================
// FreeList_5 —— FreeList 单态化变体：72 项 / 3 分配口 / 4 释放 bank / preAlloc
//
// 使用者：LoadQueueReplay（LoadQueueReplay.scala 里 `freeList = Module(new FreeList(
// size = LoadQueueReplaySize, allocWidth = LoadPipelineWidth, freeWidth = 4,
// enablePreAlloc = true, moduleName = "LoadQueueReplay freelist"))`）。
// 本表分配的是 LoadQueueReplay 的 72 个重放条目槽位号（7 位）。
//
// 本变体与基础 FreeList（16 项 / 2 口 / 无 preAlloc）的三处实质差别：
//   1) SIZE=72 不是 2 的幂 → 指针回绕要显式减 72（核里 IS_POW2 分支）；
//      指针 value 与空闲计数同为 7 位（基础变体是 4 位 / 5 位）。
//   2) enablePreAlloc=true → io_allocateSlot / io_canAllocate 各打一拍给出，
//      读指针从 headPtr+本拍分配数 起算。这 6 个输出寄存器 **不复位**。
//   3) golden 未导出 io_validCount（该实例不用它，被 firtool 裁掉），
//      只留 io_empty；核的 validCount 输出在本文件悬空。
// 核体见 rtl/memblock/FreeList.sv（xs_FreeList_core），本文件仅设参数与端口展平。
// =============================================================================
module FreeList_5(
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
  output        io_empty
);
  logic [6:0] allocateSlot [3];
  logic [2:0] canAllocate;
  logic [6:0] validCount;   // golden 未导出，悬空

  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];
  assign io_allocateSlot_2 = allocateSlot[2];
  assign {io_canAllocate_2, io_canAllocate_1, io_canAllocate_0} = canAllocate;

  xs_FreeList_core #(
    .SIZE(72), .ALLOC_WIDTH(3), .FREE_WIDTH(4), .ENABLE_PRE_ALLOC(1'b1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_allocateSlot (allocateSlot),
    .io_canAllocate  (canAllocate),
    .io_doAllocate   ({io_doAllocate_2, io_doAllocate_1, io_doAllocate_0}),
    .io_free         (io_free),
    .io_validCount   (validCount),
    .io_empty        (io_empty)
  );
endmodule
