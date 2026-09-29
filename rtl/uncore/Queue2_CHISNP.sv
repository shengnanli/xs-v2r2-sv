// Queue2_CHISNP.sv —— RXSNP 入口的 2 项 snoop 缓冲
//
// chisel3 Queue(entries=2, flow=false) 的单态化（父模块 RXSNP）。控制逻辑全在
// rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；存储是 golden 的 ram_2x98 行为级
// 存储叶子（2 项 x 98 位，两侧同源 inline）。本文件只做字段拼接/拆分：
//   ram 字（lsb 起）：srcID[10:0]  txnID[22:11]  fwdNID[33:23]  fwdTxnID[45:34]  opcode[50:46]  addr[95:51]  retToSrc[96:96]  traceTag[97:97]
// 另有 6 个 io_enq_bits_* 端口在 golden 里没有被存进 ram（父模块出队时用不到，firtool
// 删掉了存储但保留了端口），这里同样只留端口、不接任何东西。
// golden 196 行；端口表与连线由 scripts/gen_l2_queues.py 从 golden 机械生成并逐字段校验切片。

// BEGIN GENERATED(Queue2_CHISNP) —— scripts/gen_l2_queues.py
module Queue2_CHISNP (
  input  logic clock,
  input  logic reset,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_qos,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [10:0] io_enq_bits_fwdNID,
  input  logic [11:0] io_enq_bits_fwdTxnID,
  input  logic [4:0] io_enq_bits_opcode,
  input  logic [44:0] io_enq_bits_addr,
  input  logic io_enq_bits_ns,
  input  logic io_enq_bits_doNotGoToSD,
  input  logic io_enq_bits_retToSrc,
  input  logic io_enq_bits_traceTag,
  input  logic io_enq_bits_mpam_perfMonGroup,
  input  logic [8:0] io_enq_bits_mpam_partID,
  input  logic io_enq_bits_mpam_mpamNS,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [10:0] io_deq_bits_srcID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [10:0] io_deq_bits_fwdNID,
  output logic [11:0] io_deq_bits_fwdTxnID,
  output logic [4:0] io_deq_bits_opcode,
  output logic [44:0] io_deq_bits_addr,
  output logic io_deq_bits_retToSrc,
  output logic io_deq_bits_traceTag
);

  logic             do_enq;
  logic [0:0]       enq_ptr, deq_ptr;
  logic             empty;
  logic [1:0]       count;
  logic             enq_ready, deq_valid;
  logic [97:0] ramReadWord;

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
  ram_2x98 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_traceTag, io_enq_bits_retToSrc, io_enq_bits_addr, io_enq_bits_opcode, io_enq_bits_fwdTxnID, io_enq_bits_fwdNID, io_enq_bits_txnID, io_enq_bits_srcID})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  assign io_deq_bits_traceTag = ramReadWord[97];
  assign io_deq_bits_retToSrc = ramReadWord[96];
  assign io_deq_bits_addr = ramReadWord[95:51];
  assign io_deq_bits_opcode = ramReadWord[50:46];
  assign io_deq_bits_fwdTxnID = ramReadWord[45:34];
  assign io_deq_bits_fwdNID = ramReadWord[33:23];
  assign io_deq_bits_txnID = ramReadWord[22:11];
  assign io_deq_bits_srcID = ramReadWord[10:0];

endmodule
// END GENERATED(Queue2_CHISNP)
