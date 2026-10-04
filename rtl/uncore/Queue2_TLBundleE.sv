// Queue2_TLBundleE.sv —— rocket-chip TLBuffer（BufferParams.default = Queue(entries=2, pipe=false, flow=false)） 的 E 通道（grantAck）
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：TLBuffer_7.nodeOut_e_q。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_sink_2x10 行为级叶子（2 项 x 10 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   sink[9:0]
// golden 159 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_TLBundleE) —— scripts/gen_uncore_queues.py
module Queue2_TLBundleE (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [9:0] io_enq_bits_sink,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [9:0] io_deq_bits_sink
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [9:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(2), .FLOW(1'b0)) u_core (
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
  ram_sink_2x10 ram_sink_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_sink})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_sink = ramReadWord;

endmodule
// END GENERATED(Queue2_TLBundleE)
