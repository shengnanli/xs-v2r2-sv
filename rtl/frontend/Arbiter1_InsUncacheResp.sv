// Arbiter1_InsUncacheResp —— InstrMMIOEntry 单态化变体 wrapper（核体见 InstrMMIOEntry.sv）

module Arbiter1_InsUncacheResp(
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits_data,
  input         io_in_0_bits_corrupt,
  output        io_out_valid,
  output [31:0] io_out_bits_data,
  output        io_out_bits_corrupt
);
  assign io_out_valid        = io_in_0_valid;
  assign io_out_bits_data    = io_in_0_bits_data;
  assign io_out_bits_corrupt = io_in_0_bits_corrupt;
endmodule

// golden 同名 entry wrapper（端口与 golden 一致），内部用 xs 核
