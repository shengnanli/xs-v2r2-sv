// Arbiter1_InsUncacheResp —— 单入仲裁器（InstrUncache 的响应通道）
// Chisel 里是 Arbiter(new InsUncacheResp, cacheParams.nMMIOs)；KunminghuV2 的 nMMIOs=1，
// 于是"仲裁"退化成直通：只有一个输入源，chosen 恒 0、in.ready 恒等于 out.ready，
// 连 ready 端口本身都因为上下游都恒 1 而被 firtool 消掉了（见 InstrUncache.sv 文件头）。
// 剩下的就是 valid/data/corrupt 三条直连线。本文件自足，不例化任何核。
// 端口规模：3 输入 / 3 输出（都是 1 位，除 data 32 位）。

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
