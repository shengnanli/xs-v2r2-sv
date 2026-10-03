// Fixed-priority four-input L2-to-L1 hint arbiter.
// Pipeline/control leaf: input 0 wins ties, and the selected input is consumed when ready.
// Ready signals preserve the source ordering and chosen index is valid with output valid.
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
  wire any_0_or_1 = io_in_0_valid | io_in_1_valid;
  wire any_0_to_2 = any_0_or_1 | io_in_2_valid;
  assign io_in_0_ready = io_out_ready;
  assign io_in_1_ready = ~io_in_0_valid & io_out_ready;
  assign io_in_2_ready = ~any_0_or_1 & io_out_ready;
  assign io_in_3_ready = ~any_0_to_2 & io_out_ready;
  assign io_out_valid = any_0_to_2 | io_in_3_valid;
  assign io_out_bits_sourceId = io_in_0_valid ? io_in_0_bits_sourceId :
                                 io_in_1_valid ? io_in_1_bits_sourceId :
                                 io_in_2_valid ? io_in_2_bits_sourceId : io_in_3_bits_sourceId;
  assign io_out_bits_isKeyword = io_in_0_valid ? io_in_0_bits_isKeyword :
                                 io_in_1_valid ? io_in_1_bits_isKeyword :
                                 io_in_2_valid ? io_in_2_bits_isKeyword : io_in_3_bits_isKeyword;
  assign io_chosen = io_in_0_valid ? 2'd0 : io_in_1_valid ? 2'd1 :
                     io_in_2_valid ? 2'd2 : 2'd3;
endmodule
