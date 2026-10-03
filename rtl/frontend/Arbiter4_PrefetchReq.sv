// Fixed-priority prefetch request arbiter with source tagging.
// Pipeline/control leaf: input 0 is the generated request and wins over demand requests.
// Inputs 1 and 2 are accepted only when all higher-priority valid bits are clear.
module Arbiter4_PrefetchReq(
  input         io_in_0_valid,
  input  [32:0] io_in_0_bits_tag,
  input  [8:0]  io_in_0_bits_set,
  input  [4:0]  io_in_0_bits_pfSource,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [32:0] io_in_1_bits_tag,
  input  [8:0]  io_in_1_bits_set,
  input  [43:0] io_in_1_bits_vaddr,
  input         io_in_1_bits_needT,
  input  [6:0]  io_in_1_bits_source,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [32:0] io_in_2_bits_tag,
  input  [8:0]  io_in_2_bits_set,
  input  [43:0] io_in_2_bits_vaddr,
  input         io_in_2_bits_needT,
  input  [6:0]  io_in_2_bits_source,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output [43:0] io_out_bits_vaddr,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [4:0]  io_out_bits_pfSource
);
  wire higher_request = io_in_0_valid | io_in_1_valid;
  assign io_in_1_ready = ~io_in_0_valid;
  assign io_in_2_ready = ~higher_request;
  assign io_out_valid = higher_request | io_in_2_valid;
  assign io_out_bits_tag = io_in_0_valid ? io_in_0_bits_tag :
                           io_in_1_valid ? io_in_1_bits_tag : io_in_2_valid ? io_in_2_bits_tag : 33'd0;
  assign io_out_bits_set = io_in_0_valid ? io_in_0_bits_set :
                           io_in_1_valid ? io_in_1_bits_set : io_in_2_valid ? io_in_2_bits_set : 9'd0;
  assign io_out_bits_vaddr = io_in_0_valid ? 44'd0 :
                             io_in_1_valid ? io_in_1_bits_vaddr : io_in_2_valid ? io_in_2_bits_vaddr : 44'd0;
  assign io_out_bits_needT = ~io_in_0_valid &
                             (io_in_1_valid ? io_in_1_bits_needT : io_in_2_valid & io_in_2_bits_needT);
  assign io_out_bits_source = io_in_0_valid ? 7'd0 :
                              io_in_1_valid ? io_in_1_bits_source : io_in_2_valid ? io_in_2_bits_source : 7'd0;
  assign io_out_bits_pfSource = io_in_0_valid ? io_in_0_bits_pfSource :
                                io_in_1_valid ? 5'd8 : io_in_2_valid ? 5'd9 : 5'd0;
endmodule
