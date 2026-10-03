// Fixed-priority three-input arbiter for prefetch generation requests.
// Pipeline/control leaf: input 0 has highest priority and no output backpressure.
// Ready is advertised only for lower-priority inputs that cannot be shadowed.
module Arbiter3_PfGenReq(
  input         io_in_0_valid,
  input  [10:0] io_in_0_bits_region_tag,
  input  [39:0] io_in_0_bits_region_addr,
  input  [15:0] io_in_0_bits_region_bits,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [10:0] io_in_1_bits_region_tag,
  input  [39:0] io_in_1_bits_region_addr,
  input  [15:0] io_in_1_bits_region_bits,
  input         io_in_1_bits_paddr_valid,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [10:0] io_in_2_bits_region_tag,
  input  [39:0] io_in_2_bits_region_addr,
  input  [15:0] io_in_2_bits_region_bits,
  input         io_in_2_bits_paddr_valid,
  output        io_out_valid,
  output [10:0] io_out_bits_region_tag,
  output [39:0] io_out_bits_region_addr,
  output [15:0] io_out_bits_region_bits,
  output        io_out_bits_paddr_valid,
  output        io_out_bits_decr_mode
);
  wire higher_request = io_in_0_valid | io_in_1_valid;
  assign io_in_1_ready = ~io_in_0_valid;
  assign io_in_2_ready = ~higher_request;
  assign io_out_valid = higher_request | io_in_2_valid;
  assign io_out_bits_region_tag = io_in_0_valid ? io_in_0_bits_region_tag :
                                  io_in_1_valid ? io_in_1_bits_region_tag : io_in_2_bits_region_tag;
  assign io_out_bits_region_addr = io_in_0_valid ? io_in_0_bits_region_addr :
                                   io_in_1_valid ? io_in_1_bits_region_addr : io_in_2_bits_region_addr;
  assign io_out_bits_region_bits = io_in_0_valid ? io_in_0_bits_region_bits :
                                   io_in_1_valid ? io_in_1_bits_region_bits : io_in_2_bits_region_bits;
  assign io_out_bits_paddr_valid = io_in_0_valid ? 1'b1 :
                                   io_in_1_valid ? io_in_1_bits_paddr_valid : io_in_2_bits_paddr_valid;
  assign io_out_bits_decr_mode = ~io_in_0_valid & ~io_in_1_valid;
endmodule
