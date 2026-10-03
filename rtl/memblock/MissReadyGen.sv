// MissReadyGen —— DCache miss 请求的"就绪预算"：按固定优先级给 4 个请求口算 ready
//
// 位置：DCacheImp。4 个 miss 请求源（口 0 = MainPipe，口 1..3 = LoadPipe 0..2）
//   一边进 TreeArbiter 仲裁成一路送 MissQueue，一边**并行**经本模块各自问一次
//   MissQueue"我这一路能不能收"（queryMQ(i).ready，由 MissQueue 按该请求能否分配/合并现算）。
//   本模块把 MissQueue 的逐口回答与"前面有没有更高优先级的请求"合成每一口的 ready，
//   让请求方不必等仲裁结果就知道自己这拍是否会被接收（时序优化）。
// 语义（Scala MissReadyGen）：
//   queryMQ(i).req = in(i)              —— 原样转发（valid 与载荷）；
//   in(0).ready = queryMQ(0).ready；
//   in(i).ready = queryMQ(i).ready & 没有下标 < i 的口 valid（i >= 1）。
//   与 TreeArbiter 的 lowest-index-wins 一致，所以两边给同一口的结论不会打架。
// golden 端口裁剪（firtool，按 KunminghuV2Config 现读）：
//   queryMQ(i).req.valid 全被删（MissQueue 侧没用 valid 做判断）；
//   载荷只剩 source/addr/vaddr 三个字段（MissQueue 查询只看这三个）；
//   in(3).valid 也被删 —— 它只会出现在"下标 < i"的条件里，而口 3 是最后一口，没人用。
// 纯组合，无寄存器、无子模块。

module MissReadyGen(
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_source,
  input  [47:0] io_in_0_bits_addr,
  input  [49:0] io_in_0_bits_vaddr,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_source,
  input  [47:0] io_in_1_bits_addr,
  input  [49:0] io_in_1_bits_vaddr,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_source,
  input  [47:0] io_in_2_bits_addr,
  input  [49:0] io_in_2_bits_vaddr,
  output        io_in_3_ready,
  input  [3:0]  io_in_3_bits_source,
  input  [47:0] io_in_3_bits_addr,
  input  [49:0] io_in_3_bits_vaddr,
  output [3:0]  io_queryMQ_0_req_bits_source,
  output [47:0] io_queryMQ_0_req_bits_addr,
  output [49:0] io_queryMQ_0_req_bits_vaddr,
  input         io_queryMQ_0_ready,
  output [3:0]  io_queryMQ_1_req_bits_source,
  output [47:0] io_queryMQ_1_req_bits_addr,
  output [49:0] io_queryMQ_1_req_bits_vaddr,
  input         io_queryMQ_1_ready,
  output [3:0]  io_queryMQ_2_req_bits_source,
  output [47:0] io_queryMQ_2_req_bits_addr,
  output [49:0] io_queryMQ_2_req_bits_vaddr,
  input         io_queryMQ_2_ready,
  output [3:0]  io_queryMQ_3_req_bits_source,
  output [47:0] io_queryMQ_3_req_bits_addr,
  output [49:0] io_queryMQ_3_req_bits_vaddr,
  input         io_queryMQ_3_ready
);

  // ---- 就绪：MissQueue 说能收，且没有更高优先级（下标更小）的口在请求 ----
  // higher_req[i] = 口 0..i-1 里有人 valid
  wire [3:0] higher_req = {io_in_0_valid | io_in_1_valid | io_in_2_valid,
                           io_in_0_valid | io_in_1_valid,
                           io_in_0_valid,
                           1'b0};

  assign io_in_0_ready = io_queryMQ_0_ready & ~higher_req[0];
  assign io_in_1_ready = io_queryMQ_1_ready & ~higher_req[1];
  assign io_in_2_ready = io_queryMQ_2_ready & ~higher_req[2];
  assign io_in_3_ready = io_queryMQ_3_ready & ~higher_req[3];

  // ---- 查询载荷：原样转发 ----
  assign io_queryMQ_0_req_bits_source = io_in_0_bits_source;
  assign io_queryMQ_0_req_bits_addr   = io_in_0_bits_addr;
  assign io_queryMQ_0_req_bits_vaddr  = io_in_0_bits_vaddr;
  assign io_queryMQ_1_req_bits_source = io_in_1_bits_source;
  assign io_queryMQ_1_req_bits_addr   = io_in_1_bits_addr;
  assign io_queryMQ_1_req_bits_vaddr  = io_in_1_bits_vaddr;
  assign io_queryMQ_2_req_bits_source = io_in_2_bits_source;
  assign io_queryMQ_2_req_bits_addr   = io_in_2_bits_addr;
  assign io_queryMQ_2_req_bits_vaddr  = io_in_2_bits_vaddr;
  assign io_queryMQ_3_req_bits_source = io_in_3_bits_source;
  assign io_queryMQ_3_req_bits_addr   = io_in_3_bits_addr;
  assign io_queryMQ_3_req_bits_vaddr  = io_in_3_bits_vaddr;

endmodule
