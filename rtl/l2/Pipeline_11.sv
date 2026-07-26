// Pipeline_11 —— 手写可读实现(TL2 shard 4, AUX signoff)。
//
// 单级深度-1 队列(stages_0), 例化 xs_Queue1_UInt32_core。golden 里 stages_0
// 例化 Queue1_UInt32, 无 ready 背压(纯 valid/bits 流水), 等效一拍延迟的 32 位
// 数据流水缓冲。
//
// 本文件定义顶层可读核 xs_Pipeline_11_core(队列核在 rtl/l2/Queue1_UInt32.sv)。
// golden 同名扁平端口包装在 rtl/l2/Pipeline_11_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_Pipeline_11_core(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [31:0] io_in_bits,
  output        io_out_valid,
  output [31:0] io_out_bits
);

  xs_Queue1_UInt32_core stages_0 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (io_in_valid),
    .io_enq_bits  (io_in_bits),
    .io_deq_valid (io_out_valid),
    .io_deq_bits  (io_out_bits)
  );

endmodule
