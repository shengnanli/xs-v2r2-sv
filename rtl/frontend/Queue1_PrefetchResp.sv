// Queue1_PrefetchResp.sv —— SMS 预取响应在 Pipeline_3 的级寄存器（深度 1，pipe）
//
// payload 91 位（pfSource + vaddr + set + tag），父模块 Pipeline_3。
// ram 字（lsb 起）：tag[32:0]  set[41:33]  vaddr[85:42]  pfSource[90:86]
// PIPE=1：队满时只要本拍 deq 接走就能同拍再入队（enq_ready = deq_ready | ~full）。
// ★照 golden 保留★：字段 vaddr, set, tag 存进 ram 但 deq 侧无读者（firtool 留了存储删了输出；
// FM 里两侧对称的未读位，不许"顺手"删掉）。
// 控制 + 存储复用共享核 rtl/common/xs_ChiselQueue1_core.sv（语义见该文件头，Queue1_ChosenQBundle 同用）；本文件只把字段按 golden 的顺序拼成整字、再拆回来。
// golden 143 行；端口表与连线由 scripts/gen_depth1queue_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Queue1_PrefetchResp) —— scripts/gen_depth1queue_leaves5.py
module Queue1_PrefetchResp (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [32:0] io_enq_bits_tag,
  input  logic [8:0] io_enq_bits_set,
  input  logic [43:0] io_enq_bits_vaddr,
  input  logic [4:0] io_enq_bits_pfSource,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [4:0] io_deq_bits_pfSource
);

  logic [90:0] enqWord, deqWord;

  // 入队字（高位在前，照 golden 的 ram 拼接顺序）
  assign enqWord = {
    io_enq_bits_pfSource,
    io_enq_bits_vaddr,
    io_enq_bits_set,
    io_enq_bits_tag
  };

  xs_ChiselQueue1_core #(.W(91), .PIPE(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (io_enq_ready),
    .enq_word  (enqWord),
    .deq_valid (io_deq_valid),
    .deq_ready (io_deq_ready),
    .deq_word  (deqWord)
  );

  assign io_deq_bits_pfSource = deqWord[90:86];

endmodule
// END GENERATED(Queue1_PrefetchResp)
