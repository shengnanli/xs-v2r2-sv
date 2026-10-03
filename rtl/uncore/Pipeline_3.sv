// Pipeline_3.sv —— utility.Pipeline 的一个单态化：PrefetchResp（预取请求完成后 slice 回给预取器的响应）的打拍缓冲。
// Scala：utility/src/main/scala/utility/Pipeline.scala（class Pipeline(gen, depth, pipe=true)）
//   = depth 个 Queue(gen, entries=1, pipe=true, flow=false) 首尾相接，in -> stages_0 -> ... -> out。
// 例化：TL2CHICoupledL2 里每个 slice 一份：coupledL2/CoupledL2.scala:467 `Pipeline(s.resp)`，
//   把 slice.io.prefetch.resp 打一拍后送进 FastArbiter_1（prefetch_resp_arb）。
// 入口 tag/set/vaddr/pfSource，出口只剩 pfSource：其余字段下游不用，firtool 在队列里删掉了存储。
// 本模块没有自己的逻辑：每一级就是一个已签核的深度 1 队列 Queue1_PrefetchResp
// （rtl/frontend/Queue1_PrefetchResp.sv，控制+存储在共享核 rtl/common/xs_ChiselQueue1_core.sv），
// 这里只按 golden 的实例名 stages_<k> 把它们串起来。
module Pipeline_3 (
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input  [43:0] io_in_bits_vaddr,
  input  [4:0]  io_in_bits_pfSource,
  input         io_out_ready,
  output        io_out_valid,
  output [4:0]  io_out_bits_pfSource
);
  Queue1_PrefetchResp stages_0 (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_in_ready),
    .io_enq_valid         (io_in_valid),
    .io_enq_bits_tag      (io_in_bits_tag),
    .io_enq_bits_set      (io_in_bits_set),
    .io_enq_bits_vaddr    (io_in_bits_vaddr),
    .io_enq_bits_pfSource (io_in_bits_pfSource),
    .io_deq_ready         (io_out_ready),
    .io_deq_valid         (io_out_valid),
    .io_deq_bits_pfSource (io_out_bits_pfSource)
  );
endmodule
