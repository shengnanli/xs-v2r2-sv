// Queue16_CHIRSP.sv —— coupledL2 tl2chi/TXRSP.scala:48 `Queue(new CHIRSP, entries = mshrsAll, flow = false)`：发往 CHI 的 RSP flit 缓冲
//
// chisel3 Queue(entries=16, pipe=false, flow=false) 的单态化；例化处：TXRSP.queue。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_16x62 行为级叶子（16 项 x 62 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   4'h0[3:0] tgtID[14:4] txnID[26:15] opcode[31:27] respErr[33:32] resp[36:34] fwdState[39:37] 3'h0[42:40]
//   dbID[54:43] pCrdType[58:55] 2'h0[60:59] traceTag[61:61]
// 常量段：父模块入队时恒为常量的 Bundle 字段（firtool 删了入口端口，把常量直接拼进 ram 字）；
//   出队时照样从 ram 读出 —— 上电后第一次入队之前它们是 ram 的初值，照 golden 保留，不省。
// 入队端口 io_enq_bits_srcID 没有存进 ram（出队侧无读者，firtool 删了存储但留了端口），这里同样只留端口。
// golden 205 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue16_CHIRSP) —— scripts/gen_uncore_queues.py
module Queue16_CHIRSP (
  input  logic clock,
  input  logic reset,
  input  logic io_enq_valid,
  input  logic [10:0] io_enq_bits_tgtID,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [4:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_respErr,
  input  logic [2:0] io_enq_bits_resp,
  input  logic [2:0] io_enq_bits_fwdState,
  input  logic [11:0] io_enq_bits_dbID,
  input  logic [3:0] io_enq_bits_pCrdType,
  input  logic io_enq_bits_traceTag,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_qos,
  output logic [10:0] io_deq_bits_tgtID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [4:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_respErr,
  output logic [2:0] io_deq_bits_resp,
  output logic [2:0] io_deq_bits_fwdState,
  output logic [2:0] io_deq_bits_cBusy,
  output logic [11:0] io_deq_bits_dbID,
  output logic [3:0] io_deq_bits_pCrdType,
  output logic [1:0] io_deq_bits_tagOp,
  output logic io_deq_bits_traceTag,
  output logic [4:0] io_count
);

  logic       do_enq;
  logic [3:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [4:0] count;
  logic       enq_ready, deq_valid;
  logic [61:0] ramReadWord;

  xs_ChiselQueue_core #(.DEPTH(16), .FLOW(1'b0)) u_core (
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
  ram_16x62 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_traceTag, 2'h0, io_enq_bits_pCrdType, io_enq_bits_dbID, 3'h0, io_enq_bits_fwdState, io_enq_bits_resp, io_enq_bits_respErr, io_enq_bits_opcode, io_enq_bits_txnID, io_enq_bits_tgtID, 4'h0})
  );

  assign io_deq_valid = deq_valid;
  assign io_count     = count;

  assign io_deq_bits_qos = ramReadWord[3:0];
  assign io_deq_bits_tgtID = ramReadWord[14:4];
  assign io_deq_bits_txnID = ramReadWord[26:15];
  assign io_deq_bits_opcode = ramReadWord[31:27];
  assign io_deq_bits_respErr = ramReadWord[33:32];
  assign io_deq_bits_resp = ramReadWord[36:34];
  assign io_deq_bits_fwdState = ramReadWord[39:37];
  assign io_deq_bits_cBusy = ramReadWord[42:40];
  assign io_deq_bits_dbID = ramReadWord[54:43];
  assign io_deq_bits_pCrdType = ramReadWord[58:55];
  assign io_deq_bits_tagOp = ramReadWord[60:59];
  assign io_deq_bits_traceTag = ramReadWord[61];

endmodule
// END GENERATED(Queue16_CHIRSP)
