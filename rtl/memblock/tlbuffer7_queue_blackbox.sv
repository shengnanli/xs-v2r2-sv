// 自动生成：scripts/gen_tlbuffer7.py —— 勿手改
// Queue 叶子黑盒声明 (FM 两侧统一边界)。
(* black_box *)
module Queue2_TLBundleA_7(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [3:0] io_enq_bits_opcode,
  input [2:0] io_enq_bits_param,
  input [2:0] io_enq_bits_size,
  input [5:0] io_enq_bits_source,
  input [47:0] io_enq_bits_address,
  input [1:0] io_enq_bits_user_alias,
  input [43:0] io_enq_bits_user_vaddr,
  input [4:0] io_enq_bits_user_reqSource,
  input io_enq_bits_user_needHint,
  input io_enq_bits_echo_isKeyword,
  input [31:0] io_enq_bits_mask,
  input io_deq_ready,
  output io_deq_valid,
  output [3:0] io_deq_bits_opcode,
  output [2:0] io_deq_bits_param,
  output [2:0] io_deq_bits_size,
  output [5:0] io_deq_bits_source,
  output [47:0] io_deq_bits_address,
  output [1:0] io_deq_bits_user_alias,
  output [43:0] io_deq_bits_user_vaddr,
  output [4:0] io_deq_bits_user_reqSource,
  output io_deq_bits_user_needHint,
  output io_deq_bits_echo_isKeyword,
  output [31:0] io_deq_bits_mask,
  output [255:0] io_deq_bits_data,
  output io_deq_bits_corrupt
);
endmodule

(* black_box *)
module Queue2_TLBundleD_8(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [3:0] io_enq_bits_opcode,
  input [1:0] io_enq_bits_param,
  input [2:0] io_enq_bits_size,
  input [5:0] io_enq_bits_source,
  input [9:0] io_enq_bits_sink,
  input io_enq_bits_denied,
  input io_enq_bits_echo_isKeyword,
  input [255:0] io_enq_bits_data,
  input io_enq_bits_corrupt,
  input io_deq_ready,
  output io_deq_valid,
  output [3:0] io_deq_bits_opcode,
  output [1:0] io_deq_bits_param,
  output [2:0] io_deq_bits_size,
  output [5:0] io_deq_bits_source,
  output [9:0] io_deq_bits_sink,
  output io_deq_bits_denied,
  output io_deq_bits_echo_isKeyword,
  output [255:0] io_deq_bits_data,
  output io_deq_bits_corrupt
);
endmodule

(* black_box *)
module Queue2_TLBundleB(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [2:0] io_enq_bits_opcode,
  input [1:0] io_enq_bits_param,
  input [2:0] io_enq_bits_size,
  input [5:0] io_enq_bits_source,
  input [47:0] io_enq_bits_address,
  input [31:0] io_enq_bits_mask,
  input [255:0] io_enq_bits_data,
  input io_enq_bits_corrupt,
  input io_deq_ready,
  output io_deq_valid,
  output [2:0] io_deq_bits_opcode,
  output [1:0] io_deq_bits_param,
  output [47:0] io_deq_bits_address,
  output [255:0] io_deq_bits_data
);
endmodule

(* black_box *)
module Queue2_TLBundleC(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [2:0] io_enq_bits_opcode,
  input [2:0] io_enq_bits_param,
  input [2:0] io_enq_bits_size,
  input [5:0] io_enq_bits_source,
  input [47:0] io_enq_bits_address,
  input [255:0] io_enq_bits_data,
  input io_enq_bits_corrupt,
  input io_deq_ready,
  output io_deq_valid,
  output [2:0] io_deq_bits_opcode,
  output [2:0] io_deq_bits_param,
  output [2:0] io_deq_bits_size,
  output [5:0] io_deq_bits_source,
  output [47:0] io_deq_bits_address,
  output [1:0] io_deq_bits_user_alias,
  output [43:0] io_deq_bits_user_vaddr,
  output [4:0] io_deq_bits_user_reqSource,
  output io_deq_bits_user_needHint,
  output io_deq_bits_echo_isKeyword,
  output [255:0] io_deq_bits_data,
  output io_deq_bits_corrupt
);
endmodule

(* black_box *)
module Queue2_TLBundleE(
  input clock,
  input reset,
  output io_enq_ready,
  input io_enq_valid,
  input [9:0] io_enq_bits_sink,
  input io_deq_ready,
  output io_deq_valid,
  output [9:0] io_deq_bits_sink
);
endmodule
