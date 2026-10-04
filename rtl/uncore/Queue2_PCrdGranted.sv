// Queue2_PCrdGranted.sv —— coupledL2 tl2chi/TL2CHICoupledL2.scala:190 `Queue(new PCrdGranted, entries = 2)`：P-credit 授予记录的第二级（供 MSHR 比对的队头）
//
// chisel3 Queue(entries=2, pipe=false, flow=false) 的单态化；例化处：TL2CHICoupledL2.pCrdQueue_s3。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_2x15 行为级叶子（2 项 x 15 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   pCrdType[3:0] srcID[14:4]
// golden 164 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue2_PCrdGranted) —— scripts/gen_uncore_queues.py
module Queue2_PCrdGranted (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_pCrdType,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_pCrdType,
  output logic [10:0] io_deq_bits_srcID
);

  logic       do_enq;
  logic [0:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [1:0] count;
  logic       enq_ready, deq_valid;
  logic [14:0] ramReadWord;

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
  ram_2x15 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_srcID, io_enq_bits_pCrdType})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;

  assign io_deq_bits_pCrdType = ramReadWord[3:0];
  assign io_deq_bits_srcID = ramReadWord[14:4];

endmodule
// END GENERATED(Queue2_PCrdGranted)
