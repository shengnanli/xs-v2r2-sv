// golden 同名包装层：例化参数化核心 xs_Queue1_RegMapperInput，供 FM 单独比对队列。
module Queue1_RegMapperInput_3(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input         io_enq_bits_read,
  input  [3:0]  io_enq_bits_index,
  input  [63:0] io_enq_bits_data,
  input  [7:0]  io_enq_bits_mask,
  input  [2:0]  io_enq_bits_extra_tlrr_extra_source,
  input  [1:0]  io_enq_bits_extra_tlrr_extra_size,
  input         io_deq_ready,
  output        io_deq_valid,
  output        io_deq_bits_read,
  output [3:0]  io_deq_bits_index,
  output [63:0] io_deq_bits_data,
  output [7:0]  io_deq_bits_mask,
  output [2:0]  io_deq_bits_extra_tlrr_extra_source,
  output [1:0]  io_deq_bits_extra_tlrr_extra_size
);
  xs_Queue1_RegMapperInput #(
    .INDEX_W(4), .DATA_W(64), .MASK_W(8), .SOURCE_W(3), .SIZE_W(2)
  ) u_core (
    .clock                               (clock),
    .reset                               (reset),
    .io_enq_ready                        (io_enq_ready),
    .io_enq_valid                        (io_enq_valid),
    .io_enq_bits_read                    (io_enq_bits_read),
    .io_enq_bits_index                   (io_enq_bits_index),
    .io_enq_bits_data                    (io_enq_bits_data),
    .io_enq_bits_mask                    (io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source (io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size   (io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready                        (io_deq_ready),
    .io_deq_valid                        (io_deq_valid),
    .io_deq_bits_read                    (io_deq_bits_read),
    .io_deq_bits_index                   (io_deq_bits_index),
    .io_deq_bits_data                    (io_deq_bits_data),
    .io_deq_bits_mask                    (io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source (io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size   (io_deq_bits_extra_tlrr_extra_size)
  );
endmodule
