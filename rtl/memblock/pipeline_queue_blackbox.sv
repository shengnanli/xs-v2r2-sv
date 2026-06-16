// 自动生成：scripts/gen_pipeline.py —— 勿手改
// Queue 叶子黑盒声明：FM 两侧统一边界。
(* black_box *)
module Queue1_L1PrefetchReq(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [47:0] io_enq_bits_paddr,
  input [1:0] io_enq_bits_alias,
  input io_enq_bits_confidence,
  input io_enq_bits_is_store,
  input [2:0] io_enq_bits_pf_source_value,
  input io_deq_ready,
  output io_deq_valid,
  output [47:0] io_deq_bits_paddr,
  output [1:0] io_deq_bits_alias,
  output io_deq_bits_confidence,
  output io_deq_bits_is_store,
  output [2:0] io_deq_bits_pf_source_value
);
endmodule
