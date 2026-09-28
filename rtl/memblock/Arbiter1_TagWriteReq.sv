// Arbiter1_TagWriteReq —— DCache tag 写口前的单入仲裁器（退化为直通）
//
// 位置：DCacheImp 里 `tag_write_arb = Module(new Arbiter(new TagWriteReq, 1))`，
//   唯一的输入是 MainPipe 的 tag_write（refill/替换写新 tag），输出接 DuplicatedTagArray
//   的写口。历史上还有一条 RefillPipe 的写口（Scala 里已注释掉），所以这里保留了
//   "仲裁器"这个壳，但入口数只剩 1。
// 语义：单入 Chisel Arbiter —— chosen 恒 0、in.ready 恒等于 out.ready、out 就是 in。
//   tag 阵列写口的 ready 在 DCache 里恒 1，上游也不读 in.ready，所以两根 ready 端口
//   连同 chosen 一起被 firtool 删掉，golden 只剩 valid + 三个载荷字段四条直连线。
// 载荷（TagWriteReq）：idx = set 下标 vaddr[13:6]；way_en = 4 路独热写使能；
//   tag = 物理 tag paddr[47:12]（36 位；ECC 位由 tag 阵列内部现算，不走这里）。
// 本文件自足，不例化任何核（共享核 xs_FixedPriorityArbiter_core 要求 NUM_IN >= 2）。

module Arbiter1_TagWriteReq(
  input         io_in_0_valid,
  input  [7:0]  io_in_0_bits_idx,
  input  [3:0]  io_in_0_bits_way_en,
  input  [35:0] io_in_0_bits_tag,
  output        io_out_valid,
  output [7:0]  io_out_bits_idx,
  output [3:0]  io_out_bits_way_en,
  output [35:0] io_out_bits_tag
);
  assign io_out_valid       = io_in_0_valid;
  assign io_out_bits_idx    = io_in_0_bits_idx;
  assign io_out_bits_way_en = io_in_0_bits_way_en;
  assign io_out_bits_tag    = io_in_0_bits_tag;
endmodule
