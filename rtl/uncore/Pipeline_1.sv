// Pipeline_1.sv —— L2 预取器出口的一级 Decoupled 流水寄存（utility.Pipeline，depth=1、pipe=true）
//
// 位置：coupledL2 Prefetcher（coupledL2/prefetch/Prefetcher.scala:351
//   `pipe = Module(new Pipeline(io.req.bits.cloneType, 1))`）。各路 L2 预取器（BOP/Receiver…）的
//   请求先进 PrefetchQueue，再经本模块打一拍送 slice 的 SinkA —— 纯粹为了切时序。
//
// utility.Pipeline 的结构：depth 个 chisel3 Queue(gen, 1, pipe, flow=false) 首尾相接，in 接第一个的
//   enq，out 接最后一个的 deq。本实例 depth=1，所以整个模块就是**一个** Queue1_PrefetchReq
//   （stages_0，pipe=1：队满时只要本拍出队就能同拍入队，见 rtl/frontend/Queue1_PrefetchReq.sv）。
//   本层没有任何逻辑，只有这一处例化；载荷字段（tag/set/vaddr/needT/source/pfSource，99 位）原样直通。
// golden 129 行 / 18 端口；唯一子模块 Queue1_PrefetchReq（已独立签核）。

module Pipeline_1 (
  input  logic        clock,
  input  logic        reset,
  output logic        io_in_ready,
  input  logic        io_in_valid,
  input  logic [32:0] io_in_bits_tag,
  input  logic [8:0]  io_in_bits_set,
  input  logic [43:0] io_in_bits_vaddr,
  input  logic        io_in_bits_needT,
  input  logic [6:0]  io_in_bits_source,
  input  logic [4:0]  io_in_bits_pfSource,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [32:0] io_out_bits_tag,
  output logic [8:0]  io_out_bits_set,
  output logic [43:0] io_out_bits_vaddr,
  output logic        io_out_bits_needT,
  output logic [6:0]  io_out_bits_source,
  output logic [4:0]  io_out_bits_pfSource
);

  // 唯一一级（depth = 1）：in → stages_0.enq，stages_0.deq → out
  Queue1_PrefetchReq stages_0 (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_in_ready),
    .io_enq_valid         (io_in_valid),
    .io_enq_bits_tag      (io_in_bits_tag),
    .io_enq_bits_set      (io_in_bits_set),
    .io_enq_bits_vaddr    (io_in_bits_vaddr),
    .io_enq_bits_needT    (io_in_bits_needT),
    .io_enq_bits_source   (io_in_bits_source),
    .io_enq_bits_pfSource (io_in_bits_pfSource),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_tag      (io_out_bits_tag),
    .io_deq_bits_set      (io_out_bits_set),
    .io_deq_bits_vaddr    (io_out_bits_vaddr),
    .io_deq_bits_needT    (io_out_bits_needT),
    .io_deq_bits_source   (io_out_bits_source),
    .io_deq_bits_pfSource (io_out_bits_pfSource)
  );

endmodule
