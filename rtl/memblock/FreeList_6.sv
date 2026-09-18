// =============================================================================
// FreeList_6 —— FreeList 单态化变体：16 项 / 3 分配口 / 4 释放 bank / preAlloc
//
// 使用者：LoadQueueUncache（LoadQueueUncache.scala:302 `new FreeList(
// size = LoadUncacheBufferSize, allocWidth = LoadPipelineWidth, freeWidth = 4,
// enablePreAlloc = true, moduleName = "LoadQueueUncache freelist")`；KunminghuV2 下
// LoadUncacheBufferSize = 16、LoadPipelineWidth = 3）。本表分配的是 uncache
// load 缓冲的 16 个条目槽位号（4 位）。
//
// ★本变体是 SIZE 最小而 FREE_WIDTH 最大的组合（16 / 4）★：每个释放 bank 只覆盖
//   PER_BANK = 16/4 = 4 个槽位，优先编码器只有 4 位宽 —— 家族里 bank 最"浅"的一个。
//   与 FreeList_5（72 项）比，同样是 4 bank / 3 口 / preAlloc，只有规模与
//   「SIZE 是不是 2 的幂」两处不同（16 是 2 的幂，指针不需要显式减 SIZE）。
//
// ★enablePreAlloc = true★：6 个输出寄存器（3 个 allocateSlot + 3 个 canAllocate）
//   **不带复位**，两轮 +vcs+initreg 都要过。
// 核体见 rtl/memblock/FreeList.sv（xs_FreeList_core），本文件仅设参数与端口展平。
// =============================================================================
module FreeList_6(
  input         clock,
  input         reset,
  output [3:0]  io_allocateSlot_0,
  output [3:0]  io_allocateSlot_1,
  output [3:0]  io_allocateSlot_2,
  output        io_canAllocate_0,
  output        io_canAllocate_1,
  output        io_canAllocate_2,
  input         io_doAllocate_0,
  input         io_doAllocate_1,
  input         io_doAllocate_2,
  input  [15:0] io_free,
  output [4:0]  io_validCount,
  output        io_empty
);
  logic [3:0] allocateSlot [3];
  logic [2:0] canAllocate;

  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];
  assign io_allocateSlot_2 = allocateSlot[2];
  assign {io_canAllocate_2, io_canAllocate_1, io_canAllocate_0} = canAllocate;

  xs_FreeList_core #(
    .SIZE(16), .ALLOC_WIDTH(3), .FREE_WIDTH(4), .ENABLE_PRE_ALLOC(1'b1)
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
