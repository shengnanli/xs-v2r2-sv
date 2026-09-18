// =============================================================================
// FreeList_1 —— FreeList 单态化变体：16 项 / 1 分配口 / 1 释放 bank / 无 preAlloc
//
// 使用者：VStore MergeBuffer（VMergeBuffer.scala:502 `new FreeList(size = uopSize,
// allocWidth = VecStorePipelineWidth, freeWidth = deqWidth, enablePreAlloc = false,
// moduleName = "VStore MergeBuffer freelist")`，uopSize = VsMergeBufferSize = 16）。
// 本表分配的是向量 store 合并缓冲的 16 个 uop 条目槽位号（4 位）。
//
// ★本变体是家族里最"瘦"的一个，两个宽度都被 firtool 收到 1★（逐项量自 golden）：
//   · 分配口只剩 1 个：golden 只有 io_allocateSlot_0 / io_doAllocate_0，
//     且 headPtr 次态就是 `{4'h0, io_doAllocate_0} + {headPtr_flag, headPtr_value}`
//     （golden FreeList_1.sv:186）—— numAllocate 只数了 doAllocate_0 这一位，
//     所以 ALLOC_WIDTH 确实是 1，不是"3 个口里被裁掉 2 个"。
//   · 释放 bank 只剩 1 个：golden 里只有 freeReq_next_nextVec_0_r 一族寄存器
//     （其余变体有 _0.._3），故 FREE_WIDTH = 1，getRemBits 退化成恒等映射。
//   · golden 未导出 io_canAllocate（该使用者不看），核的该输出在本文件悬空。
// 核体见 rtl/memblock/FreeList.sv（xs_FreeList_core），本文件仅设参数与端口展平。
// =============================================================================
module FreeList_1(
  input         clock,
  input         reset,
  output [3:0]  io_allocateSlot_0,
  input         io_doAllocate_0,
  input  [15:0] io_free,
  output [4:0]  io_validCount,
  output        io_empty
);
  logic [3:0] allocateSlot [1];
  logic [0:0] canAllocate;   // golden 未导出，悬空

  assign io_allocateSlot_0 = allocateSlot[0];

  xs_FreeList_core #(
    .SIZE(16), .ALLOC_WIDTH(1), .FREE_WIDTH(1), .ENABLE_PRE_ALLOC(1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_allocateSlot (allocateSlot),
    .io_canAllocate  (canAllocate),
    .io_doAllocate   (io_doAllocate_0),
    .io_free         (io_free),
    .io_validCount   (io_validCount),
    .io_empty        (io_empty)
  );
endmodule
