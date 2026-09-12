// Arbiter1_InsUncacheResp —— 单入仲裁器（InstrUncache 的响应通道）
// 只有一个输入源，所谓"仲裁"退化为直通：valid/data/corrupt 三条各自一条 assign。
// golden 里它是 Arbiter 的单入特化实例；本文件自足，不例化任何核。
// 端口规模：3 输入 / 3 输出。

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
