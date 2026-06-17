// 自动生成：scripts/gen_freelist.py —— 勿手改
// golden 同名扁平端口 → 可读核 xs_FreeList_core 的机械适配层
module FreeList_xs(
  input         clock,
  input         reset,
  output [3:0]  io_allocateSlot_0,
  output [3:0]  io_allocateSlot_1,
  input         io_doAllocate_0,
  input         io_doAllocate_1,
  input  [15:0] io_free,
  output [4:0]  io_validCount,
  output        io_empty
);
  logic [3:0] allocateSlot [2];
  logic [1:0] doAllocate;

  assign doAllocate = {io_doAllocate_1, io_doAllocate_0};
  assign io_allocateSlot_0 = allocateSlot[0];
  assign io_allocateSlot_1 = allocateSlot[1];

  xs_FreeList_core u_core (
    .clock(clock),
    .reset(reset),
    .io_allocateSlot(allocateSlot),
    .io_doAllocate(doAllocate),
    .io_free(io_free),
    .io_validCount(io_validCount),
    .io_empty(io_empty)
  );
endmodule
