// Pipeline_2 —— 手写可读实现(TL2 shard 4, AUX signoff)。
//
// L2 预取训练信息的一级流水缓冲: 单纯例化一个深度 1 的 skid-buffer 队列
// (xs_Queue1_PrefetchTrain_core, 定义在 rtl/uncore/Queue1_PrefetchTrain.sv,
// 已独立签核 PASS), enq/deq 端口原样转发。golden 里 stages_0 例化
// Queue1_PrefetchTrain, 本实现例化可读同构核 xs_Queue1_PrefetchTrain_core。
//
// 入队载荷 11 字段(104 位): {reqsource[4:0], pfsource[2:0], prefetched, hit,
// vaddr[43:0], source[6:0], needT, set[8:0], tag[32:0]}; deq 只读回
// tag/set/needT/source/vaddr/reqsource 6 个字段(hit/prefetched/pfsource 写而不读,
// 与 golden ram 同一组对称死位)。
//
// 本文件仅定义顶层可读核 xs_Pipeline_2_core(队列核在 rtl/uncore 复用)。
// golden 同名扁平端口包装在 rtl/l2/Pipeline_2_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_Pipeline_2_core(
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

  xs_Queue1_PrefetchTrain_core stages_0 (
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
