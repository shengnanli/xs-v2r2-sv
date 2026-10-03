// Pipeline_10.sv —— utility.Pipeline 的一个单态化：32 位 hint source（L2 发往 L1 的 grant 提示 sourceId）的打拍缓冲。
// Scala：utility/src/main/scala/utility/Pipeline.scala（class Pipeline(gen, depth, pipe=true)）
//   = depth 个 Queue(gen, entries=1, pipe=true, flow=false) 首尾相接，in -> stages_0 -> ... -> out。
// 例化：TL2CHICoupledL2.hintPipe2：coupledL2/CoupledL2.scala:595 `new Pipeline(UInt(32.W), 2)`，
//   深度 2 = 两个深度 1 队列首尾相接（stages_0 -> stages_1），用来和 2 拍后的 grant 比对提示是否准确。
// out.ready 被例化者钉成 true.B，enq/deq 的 ready 端口都被 firtool 折掉了：每拍都能进、每拍都出。
// 本模块没有自己的逻辑：每一级就是一个已签核的深度 1 队列 Queue1_UInt32
// （rtl/frontend/Queue1_UInt32.sv，控制+存储在共享核 rtl/common/xs_ChiselQueue1_core.sv），
// 这里只按 golden 的实例名 stages_<k> 把它们串起来。
module Pipeline_10 (
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [31:0] io_in_bits,
  output        io_out_valid,
  output [31:0] io_out_bits
);
  // 两级之间的连线：stages_0 的出口就是 stages_1 的入口
  logic        stage0_out_valid;
  logic [31:0] stage0_out_bits;

  // 第 1 级：in -> stages_0
  Queue1_UInt32 stages_0 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (io_in_valid),
    .io_enq_bits  (io_in_bits),
    .io_deq_valid (stage0_out_valid),
    .io_deq_bits  (stage0_out_bits)
  );
  // 第 2 级：stages_0 -> stages_1 -> out
  Queue1_UInt32 stages_1 (
    .clock        (clock),
    .reset        (reset),
    .io_enq_valid (stage0_out_valid),
    .io_enq_bits  (stage0_out_bits),
    .io_deq_valid (io_out_valid),
    .io_deq_bits  (io_out_bits)
  );
endmodule
