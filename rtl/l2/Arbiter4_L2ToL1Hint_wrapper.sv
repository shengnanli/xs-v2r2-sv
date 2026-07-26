// 4 输入固定优先级仲裁器可读实现: xs_arbiter4_core.
// golden Arbiter4_L2ToL1Hint: 有 ready 链 + chosen 输出, payload =
// {bits_sourceId(32), bits_isKeyword(1)}。
module Arbiter4_L2ToL1Hint(
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits_sourceId,
  input         io_in_0_bits_isKeyword,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits_sourceId,
  input         io_in_1_bits_isKeyword,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [31:0] io_in_2_bits_sourceId,
  input         io_in_2_bits_isKeyword,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [31:0] io_in_3_bits_sourceId,
  input         io_in_3_bits_isKeyword,
  input         io_out_ready,
  output        io_out_valid,
  output [31:0] io_out_bits_sourceId,
  output        io_out_bits_isKeyword,
  output [1:0]  io_chosen
);
  // ---- 4 输入固定优先级仲裁器: xs_arbiter4_core (WIDTH=33) ----
  localparam int unsigned W = 33;
  logic [3:0]   c_valids;
  logic [3:0]   c_readies;
  logic [W-1:0] c_pin [4];
  logic [W-1:0] c_pout;
  logic [1:0]   c_chosen;
  wire          c_out_valid;

  assign c_valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign c_pin[0] = {io_in_0_bits_sourceId, io_in_0_bits_isKeyword};
  assign c_pin[1] = {io_in_1_bits_sourceId, io_in_1_bits_isKeyword};
  assign c_pin[2] = {io_in_2_bits_sourceId, io_in_2_bits_isKeyword};
  assign c_pin[3] = {io_in_3_bits_sourceId, io_in_3_bits_isKeyword};

  xs_arbiter4_core #(.WIDTH(W)) u_core (
    .valids(c_valids), .out_ready(io_out_ready), .pin(c_pin),
    .readies(c_readies), .out_valid(c_out_valid), .pout(c_pout), .chosen(c_chosen)
  );

  assign io_in_0_ready = c_readies[0];
  assign io_in_1_ready = c_readies[1];
  assign io_in_2_ready = c_readies[2];
  assign io_in_3_ready = c_readies[3];
  assign io_out_valid       = c_out_valid;
  assign io_out_bits_sourceId  = c_pout[32:1];
  assign io_out_bits_isKeyword = c_pout[0];
  assign io_chosen          = c_chosen;
endmodule
