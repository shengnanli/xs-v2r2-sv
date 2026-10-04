// Queue1_L1PrefetchReq.sv —— L1 预取请求（L1Prefetcher → DCache）的级寄存器（深度 1，非 pipe）
//
// payload 55 位（pf_source_value + is_store + confidence + alias + paddr），父模块 Pipeline（MemBlock 里 L1 预取请求送 DCache 前的级寄存器）。
// ram 字（lsb 起）：paddr[47:0]  alias[49:48]  confidence[50:50]  is_store[51:51]  pf_source_value[54:52]
// PIPE=0：enq_ready = ~full，满时拒收；同拍入出不存在（结构性）。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 155 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_L1PrefetchReq) —— scripts/gen_depth1queue_leaves5.py
module Queue1_L1PrefetchReq (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [47:0] io_enq_bits_paddr,
  input  logic [1:0] io_enq_bits_alias,
  input  logic io_enq_bits_confidence,
  input  logic io_enq_bits_is_store,
  input  logic [2:0] io_enq_bits_pf_source_value,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [47:0] io_deq_bits_paddr,
  output logic [1:0] io_deq_bits_alias,
  output logic io_deq_bits_confidence,
  output logic io_deq_bits_is_store,
  output logic [2:0] io_deq_bits_pf_source_value
);

  logic [54:0] enqWord, deqWord;

  // 入队字（高位在前，照 golden 的 ram 拼接顺序）
  assign enqWord = {
    io_enq_bits_pf_source_value,
    io_enq_bits_is_store,
    io_enq_bits_confidence,
    io_enq_bits_alias,
    io_enq_bits_paddr
  };

  xs_ChiselQueue1_core #(.W(55), .PIPE(1'b0)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_word  (enqWord),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_word  (deqWord)
  );

  assign io_deq_bits_paddr = deqWord[47:0];
  assign io_deq_bits_alias = deqWord[49:48];
  assign io_deq_bits_confidence = deqWord[50];
  assign io_deq_bits_is_store = deqWord[51];
  assign io_deq_bits_pf_source_value = deqWord[54:52];

endmodule
// END GENERATED(Queue1_L1PrefetchReq)
