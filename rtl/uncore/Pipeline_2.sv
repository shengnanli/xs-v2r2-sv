// Pipeline_2.sv —— utility.Pipeline 的一个单态化：PrefetchTrain（L2 slice 发给预取器的训练请求）的打拍缓冲。
// Scala：utility/src/main/scala/utility/Pipeline.scala（class Pipeline(gen, depth, pipe=true)）
//   = depth 个 Queue(gen, entries=1, pipe=true, flow=false) 首尾相接，in -> stages_0 -> ... -> out。
// 例化：TL2CHICoupledL2 里每个 slice 一份：coupledL2/CoupledL2.scala:466 `Pipeline(s.train)`，
//   把 slice.io.prefetch.train 打一拍后送进 FastArbiter（prefetch_train_arb）。
// 入口 9 个字段，出口只剩 6 个：hit / prefetched / pfsource 下游（Prefetcher.io.train 经 FastArbiter）
//   用不到，firtool 把 deq 侧这三个端口连同队列里的存储一起删了；enq 侧端口仍在、直接悬空。
// 本模块没有自己的逻辑：每一级就是一个已签核的深度 1 队列 Queue1_PrefetchTrain
// （rtl/frontend/Queue1_PrefetchTrain.sv，控制+存储在共享核 rtl/common/xs_ChiselQueue1_core.sv），
// 这里只按 golden 的实例名 stages_<k> 把它们串起来。
module Pipeline_2 (
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input         io_in_bits_needT,
  input  [6:0]  io_in_bits_source,
  input  [43:0] io_in_bits_vaddr,
  input         io_in_bits_hit,
  input         io_in_bits_prefetched,
  input  [2:0]  io_in_bits_pfsource,
  input  [4:0]  io_in_bits_reqsource,
  input         io_out_ready,
  output        io_out_valid,
  output [32:0] io_out_bits_tag,
  output [8:0]  io_out_bits_set,
  output        io_out_bits_needT,
  output [6:0]  io_out_bits_source,
  output [43:0] io_out_bits_vaddr,
  output [4:0]  io_out_bits_reqsource
);
  Queue1_PrefetchTrain stages_0 (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq_ready           (io_in_ready),
    .io_enq_valid           (io_in_valid),
    .io_enq_bits_tag        (io_in_bits_tag),
    .io_enq_bits_set        (io_in_bits_set),
    .io_enq_bits_needT      (io_in_bits_needT),
    .io_enq_bits_source     (io_in_bits_source),
    .io_enq_bits_vaddr      (io_in_bits_vaddr),
    .io_enq_bits_hit        (io_in_bits_hit),
    .io_enq_bits_prefetched (io_in_bits_prefetched),
    .io_enq_bits_pfsource   (io_in_bits_pfsource),
    .io_enq_bits_reqsource  (io_in_bits_reqsource),
    .io_deq_ready           (io_out_ready),
    .io_deq_valid           (io_out_valid),
    .io_deq_bits_tag        (io_out_bits_tag),
    .io_deq_bits_set        (io_out_bits_set),
    .io_deq_bits_needT      (io_out_bits_needT),
    .io_deq_bits_source     (io_out_bits_source),
    .io_deq_bits_vaddr      (io_out_bits_vaddr),
    .io_deq_bits_reqsource  (io_out_bits_reqsource)
  );
endmodule
