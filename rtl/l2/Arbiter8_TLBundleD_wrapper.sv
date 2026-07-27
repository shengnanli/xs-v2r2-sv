// 自动生成: scripts/gen_arbiter8.py —— 勿手改
// 8 输入固定优先级仲裁器可读实现: xs_arbiter8_core.
module Arbiter8_TLBundleD(
  output io_in_0_ready,
  input io_in_0_valid,
  input [3:0] io_in_0_bits_opcode,
  input [1:0] io_in_0_bits_size,
  input [2:0] io_in_0_bits_source,
  input io_in_0_bits_denied,
  input [63:0] io_in_0_bits_data,
  input io_in_0_bits_corrupt,
  output io_in_1_ready,
  input io_in_1_valid,
  input [3:0] io_in_1_bits_opcode,
  input [1:0] io_in_1_bits_size,
  input [2:0] io_in_1_bits_source,
  input io_in_1_bits_denied,
  input [63:0] io_in_1_bits_data,
  input io_in_1_bits_corrupt,
  output io_in_2_ready,
  input io_in_2_valid,
  input [3:0] io_in_2_bits_opcode,
  input [1:0] io_in_2_bits_size,
  input [2:0] io_in_2_bits_source,
  input io_in_2_bits_denied,
  input [63:0] io_in_2_bits_data,
  input io_in_2_bits_corrupt,
  output io_in_3_ready,
  input io_in_3_valid,
  input [3:0] io_in_3_bits_opcode,
  input [1:0] io_in_3_bits_size,
  input [2:0] io_in_3_bits_source,
  input io_in_3_bits_denied,
  input [63:0] io_in_3_bits_data,
  input io_in_3_bits_corrupt,
  output io_in_4_ready,
  input io_in_4_valid,
  input [3:0] io_in_4_bits_opcode,
  input [1:0] io_in_4_bits_size,
  input [2:0] io_in_4_bits_source,
  input io_in_4_bits_denied,
  input [63:0] io_in_4_bits_data,
  input io_in_4_bits_corrupt,
  output io_in_5_ready,
  input io_in_5_valid,
  input [3:0] io_in_5_bits_opcode,
  input [1:0] io_in_5_bits_size,
  input [2:0] io_in_5_bits_source,
  input io_in_5_bits_denied,
  input [63:0] io_in_5_bits_data,
  input io_in_5_bits_corrupt,
  output io_in_6_ready,
  input io_in_6_valid,
  input [3:0] io_in_6_bits_opcode,
  input [1:0] io_in_6_bits_size,
  input [2:0] io_in_6_bits_source,
  input io_in_6_bits_denied,
  input [63:0] io_in_6_bits_data,
  input io_in_6_bits_corrupt,
  output io_in_7_ready,
  input io_in_7_valid,
  input [3:0] io_in_7_bits_opcode,
  input [1:0] io_in_7_bits_size,
  input [2:0] io_in_7_bits_source,
  input io_in_7_bits_denied,
  input [63:0] io_in_7_bits_data,
  input io_in_7_bits_corrupt,
  input io_out_ready,
  output io_out_valid,
  output [3:0] io_out_bits_opcode,
  output [1:0] io_out_bits_size,
  output [2:0] io_out_bits_source,
  output io_out_bits_denied,
  output [63:0] io_out_bits_data,
  output io_out_bits_corrupt
);
  // ---- 8 输入固定优先级仲裁器: xs_arbiter8_core (WIDTH=75) ----
  localparam int unsigned W = 75;
  logic [7:0] c_valids;
  logic [7:0] c_readies;
  logic [W-1:0] c_pin [8];
  logic [W-1:0] c_pout;
  wire c_out_valid;
  assign c_valids = {io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign c_pin[0] = {io_in_0_bits_opcode, io_in_0_bits_size, io_in_0_bits_source, io_in_0_bits_denied, io_in_0_bits_data, io_in_0_bits_corrupt};
  assign c_pin[1] = {io_in_1_bits_opcode, io_in_1_bits_size, io_in_1_bits_source, io_in_1_bits_denied, io_in_1_bits_data, io_in_1_bits_corrupt};
  assign c_pin[2] = {io_in_2_bits_opcode, io_in_2_bits_size, io_in_2_bits_source, io_in_2_bits_denied, io_in_2_bits_data, io_in_2_bits_corrupt};
  assign c_pin[3] = {io_in_3_bits_opcode, io_in_3_bits_size, io_in_3_bits_source, io_in_3_bits_denied, io_in_3_bits_data, io_in_3_bits_corrupt};
  assign c_pin[4] = {io_in_4_bits_opcode, io_in_4_bits_size, io_in_4_bits_source, io_in_4_bits_denied, io_in_4_bits_data, io_in_4_bits_corrupt};
  assign c_pin[5] = {io_in_5_bits_opcode, io_in_5_bits_size, io_in_5_bits_source, io_in_5_bits_denied, io_in_5_bits_data, io_in_5_bits_corrupt};
  assign c_pin[6] = {io_in_6_bits_opcode, io_in_6_bits_size, io_in_6_bits_source, io_in_6_bits_denied, io_in_6_bits_data, io_in_6_bits_corrupt};
  assign c_pin[7] = {io_in_7_bits_opcode, io_in_7_bits_size, io_in_7_bits_source, io_in_7_bits_denied, io_in_7_bits_data, io_in_7_bits_corrupt};
  xs_arbiter8_core #(.WIDTH(W)) u_core (
    .valids(c_valids), .out_ready(io_out_ready), .pin(c_pin),
    .readies(c_readies), .out_valid(c_out_valid), .pout(c_pout)
  );
  assign io_in_0_ready = c_readies[0];
  assign io_in_1_ready = c_readies[1];
  assign io_in_2_ready = c_readies[2];
  assign io_in_3_ready = c_readies[3];
  assign io_in_4_ready = c_readies[4];
  assign io_in_5_ready = c_readies[5];
  assign io_in_6_ready = c_readies[6];
  assign io_in_7_ready = c_readies[7];
  assign io_out_valid = c_out_valid;
  assign io_out_bits_opcode = c_pout[74:71];
  assign io_out_bits_size = c_pout[70:69];
  assign io_out_bits_source = c_pout[68:66];
  assign io_out_bits_denied = c_pout[65];
  assign io_out_bits_data = c_pout[64:1];
  assign io_out_bits_corrupt = c_pout[0];
endmodule
