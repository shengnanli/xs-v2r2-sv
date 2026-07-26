// Pipeline_10 —— 手写可读实现(TL2 shard 4, AUX signoff)。
//
// 两级深度-1 队列级联(stages_0 -> stages_1), 每级例化 xs_Queue1_UInt32_core。
// golden 里 stages_0/stages_1 各例化 Queue1_UInt32, 上一级 deq 直接喂下一级 enq,
// 无 ready 背压(纯 valid/bits 流水)。等效两拍延迟的 32 位数据流水缓冲。
//
// 本文件定义顶层可读核 xs_Pipeline_10_core(队列核在 rtl/l2/Queue1_UInt32.sv)。
// golden 同名扁平端口包装在 rtl/l2/Pipeline_10_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_Pipeline_10_core(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [31:0] io_in_bits,
  output        io_out_valid,
  output [31:0] io_out_bits
);

  wire        stage0_deq_valid;
  wire [31:0] stage0_deq_bits;

  xs_Queue1_UInt32_core stages_0 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (io_in_valid),
    .io_enq_bits  (io_in_bits),
    .io_deq_valid (stage0_deq_valid),
    .io_deq_bits  (stage0_deq_bits)
  );

  xs_Queue1_UInt32_core stages_1 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (stage0_deq_valid),
    .io_enq_bits  (stage0_deq_bits),
    .io_deq_valid (io_out_valid),
    .io_deq_bits  (io_out_bits)
  );

endmodule
