// Queue1_PrefetchReq.sv —— SMS 预取请求在 Pipeline_1 的级寄存器（深度 1，pipe）
//
// payload 99 位（pfSource + source + needT + vaddr + set + tag），父模块 Pipeline_1（SMS 预取流水）。
// ram 字（lsb 起）：tag[32:0]  set[41:33]  vaddr[85:42]  needT[86:86]  source[93:87]  pfSource[98:94]
// PIPE=1：队满时只要本拍 deq 接走就能同拍再入队（enq_ready = deq_ready | ~full）。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 161 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_PrefetchReq) —— scripts/gen_depth1queue_leaves5.py
module Queue1_PrefetchReq (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [32:0] io_enq_bits_tag,
  input  logic [8:0] io_enq_bits_set,
  input  logic [43:0] io_enq_bits_vaddr,
  input  logic io_enq_bits_needT,
  input  logic [6:0] io_enq_bits_source,
  input  logic [4:0] io_enq_bits_pfSource,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [32:0] io_deq_bits_tag,
  output logic [8:0] io_deq_bits_set,
  output logic [43:0] io_deq_bits_vaddr,
  output logic io_deq_bits_needT,
  output logic [6:0] io_deq_bits_source,
  output logic [4:0] io_deq_bits_pfSource
);

  logic [98:0] enqWord, deqWord;

  // 入队字（高位在前，照 golden 的 ram 拼接顺序）
  assign enqWord = {
    io_enq_bits_pfSource,
    io_enq_bits_source,
    io_enq_bits_needT,
    io_enq_bits_vaddr,
    io_enq_bits_set,
    io_enq_bits_tag
  };

  xs_ChiselQueue1_core #(.W(99), .PIPE(1'b1)) u_core (
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
  assign io_deq_bits_vaddr = deqWord[85:42];
  assign io_deq_bits_needT = deqWord[86];
  assign io_deq_bits_source = deqWord[93:87];
  assign io_deq_bits_pfSource = deqWord[98:94];

endmodule
// END GENERATED(Queue1_PrefetchReq)
