// Queue4_HintQueueEntry.sv —— CustomL1Hint 的 hint_s1Queue（s1 级提示的暂存，flow）
//
// chisel3 Queue(entries=4, flow=true) 的单态化（父模块 CustomL1Hint）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_4x11 行为级
// 存储叶子（4 项 x 11 位，两侧同源 inline）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：source[6:0]  opcode[9:7]  isKeyword[10:10]
// golden 168 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue4_HintQueueEntry) —— scripts/gen_l2_queues.py
module Queue4_HintQueueEntry (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [6:0] io_enq_bits_source,
  input  logic [2:0] io_enq_bits_opcode,
  input  logic io_enq_bits_isKeyword,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [6:0] io_deq_bits_source,
  output logic [2:0] io_deq_bits_opcode,
  output logic io_deq_bits_isKeyword
);

  logic             do_enq;
  logic [1:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [2:0]       count;
  logic             enq_ready, deq_valid;
  logic [10:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(4), .FLOW(1'b1)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_valid (io_enq_valid),
    .enq_ready (enq_ready),
    .deq_valid (deq_valid),
    .deq_ready (io_deq_ready),
    .do_enq    (do_enq),
    .enq_ptr   (enq_ptr),
    .deq_ptr   (deq_ptr),
    .empty     (empty),
    .count     (count)
  );

  // 存储：写口在 enq_ptr、读口恒使能读 deq_ptr（组合读）
  ram_4x11 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_isKeyword, io_enq_bits_opcode, io_enq_bits_source})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  // flow：队列空时 enq 数据直接旁路到 deq
  assign io_deq_bits_isKeyword = empty ? io_enq_bits_isKeyword : ramReadWord[10];
  assign io_deq_bits_opcode = empty ? io_enq_bits_opcode : ramReadWord[9:7];
  assign io_deq_bits_source = empty ? io_enq_bits_source : ramReadWord[6:0];

endmodule
// END GENERATED(Queue4_HintQueueEntry)
