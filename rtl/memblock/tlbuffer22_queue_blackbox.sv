// 自动生成：scripts/gen_tlbuffer22.py —— 勿手改
// Queue 叶子黑盒声明 (FM 两侧统一边界)。
(* black_box *)
module Queue2_TLBundleA_31(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [3:0] io_enq_bits_opcode,
  input [2:0] io_enq_bits_param,
  input [1:0] io_enq_bits_size,
  input [2:0] io_enq_bits_source,
  input [47:0] io_enq_bits_address,
  input io_enq_bits_user_memBackType_MM,
  input io_enq_bits_user_memPageType_NC,
  input [7:0] io_enq_bits_mask,
  input [63:0] io_enq_bits_data,
  input io_enq_bits_corrupt,
  input io_deq_ready,
  output io_deq_valid,
  output [3:0] io_deq_bits_opcode,
  output [2:0] io_deq_bits_param,
  output [1:0] io_deq_bits_size,
  output [2:0] io_deq_bits_source,
  output [47:0] io_deq_bits_address,
  output io_deq_bits_user_memBackType_MM,
  output io_deq_bits_user_memPageType_NC,
  output [7:0] io_deq_bits_mask,
  output [63:0] io_deq_bits_data,
  output io_deq_bits_corrupt
);
endmodule

(* black_box *)
module Queue2_TLBundleD_11(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [3:0] io_enq_bits_opcode,
  input [1:0] io_enq_bits_param,
  input [1:0] io_enq_bits_size,
  input [2:0] io_enq_bits_source,
  input io_enq_bits_sink,
  input io_enq_bits_denied,
  input [63:0] io_enq_bits_data,
  input io_enq_bits_corrupt,
  input io_deq_ready,
  output io_deq_valid,
  output [3:0] io_deq_bits_opcode,
  output [1:0] io_deq_bits_param,
  output [1:0] io_deq_bits_size,
  output [2:0] io_deq_bits_source,
  output io_deq_bits_sink,
  output io_deq_bits_denied,
  output [63:0] io_deq_bits_data,
  output io_deq_bits_corrupt
);
endmodule
