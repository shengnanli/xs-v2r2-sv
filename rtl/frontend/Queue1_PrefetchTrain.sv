// Queue1_PrefetchTrain.sv —— SMS 预取训练数据在 Pipeline_2 的级寄存器（深度 1，pipe）
//
// payload 104 位（reqsource + pfsource + prefetched + hit + vaddr + source + needT + set + tag），父模块 Pipeline_2。
// ram 字（lsb 起）：tag[32:0]  set[41:33]  needT[42:42]  source[49:43]  vaddr[93:50]  hit[94:94]  prefetched[95:95]  pfsource[98:96]  reqsource[103:99]
// PIPE=1：队满时只要本拍 deq 接走就能同拍再入队（enq_ready = deq_ready | ~full）。
// ★照 golden 保留★：字段 pfsource, prefetched, hit 存进 ram 但 deq 侧无读者（firtool 留了存储删了输出；
// FM 里两侧对称的未读位，不许"顺手"删掉）。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 167 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_PrefetchTrain) —— scripts/gen_depth1queue_leaves5.py
module Queue1_PrefetchTrain (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [32:0] io_enq_bits_tag,
  input  logic [8:0] io_enq_bits_set,
  input  logic io_enq_bits_needT,
  input  logic [6:0] io_enq_bits_source,
  input  logic [43:0] io_enq_bits_vaddr,
  input  logic io_enq_bits_hit,
  input  logic io_enq_bits_prefetched,
  input  logic [2:0] io_enq_bits_pfsource,
  input  logic [4:0] io_enq_bits_reqsource,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [32:0] io_deq_bits_tag,
  output logic [8:0] io_deq_bits_set,
  output logic io_deq_bits_needT,
  output logic [6:0] io_deq_bits_source,
  output logic [43:0] io_deq_bits_vaddr,
  output logic [4:0] io_deq_bits_reqsource
);

  logic [103:0] enqWord, deqWord;

  // 入队字（高位在前，照 golden 的 ram 拼接顺序）
  assign enqWord = {
    io_enq_bits_reqsource,
    io_enq_bits_pfsource,
    io_enq_bits_prefetched,
    io_enq_bits_hit,
    io_enq_bits_vaddr,
    io_enq_bits_source,
    io_enq_bits_needT,
    io_enq_bits_set,
    io_enq_bits_tag
  };

  xs_ChiselQueue1_core #(.W(104), .PIPE(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_word  (enqWord),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_word  (deqWord)
  );

  assign io_deq_bits_tag = deqWord[32:0];
  assign io_deq_bits_set = deqWord[41:33];
  assign io_deq_bits_needT = deqWord[42];
  assign io_deq_bits_source = deqWord[49:43];
  assign io_deq_bits_vaddr = deqWord[93:50];
  assign io_deq_bits_reqsource = deqWord[103:99];

endmodule
// END GENERATED(Queue1_PrefetchTrain)
