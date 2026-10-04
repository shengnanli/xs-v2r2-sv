// Queue16_CHIREQ.sv —— coupledL2 tl2chi/TXREQ.scala:48 `Queue(new CHIREQ, entries = mshrsAll, flow = false)`：发往 CHI 的 REQ flit 缓冲
//
// chisel3 Queue(entries=16, pipe=false, flow=false) 的单态化；例化处：TXREQ.queue。
// 控制逻辑全在已签共享核 rtl/common/xs_ChiselQueue_core.sv（语义讲在那里）；
// 存储是 golden 的 ram_16x137 行为级叶子（16 项 x 137 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   qos[3:0] txnID[15:4] 24'h0[39:16] opcode[46:40] addr[94:47] 1'h0[95:95] likelyshared[96:96]
//   allowRetry[97:97] 2'h0[99:98] pCrdType[103:100] memAttr_allocate[104:104] memAttr_cacheable[105:105]
//   memAttr_device[106:106] memAttr_ewa[107:107] snpAttr[108:108] 9'h0[117:109] expCompAck[118:118]
//   18'h0[136:119]
// 常量段：父模块入队时恒为常量的 Bundle 字段（firtool 删了入口端口，把常量直接拼进 ram 字）；
//   出队时照样从 ram 读出 —— 上电后第一次入队之前它们是 ram 的初值，照 golden 保留，不省。
// 入队端口 io_enq_bits_tgtID, io_enq_bits_srcID, io_enq_bits_size 没有存进 ram（出队侧无读者，firtool 删了存储但留了端口），这里同样只留端口。
// golden 245 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue16_CHIREQ) —— scripts/gen_uncore_queues.py
module Queue16_CHIREQ (
  input  logic clock,
  input  logic reset,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_qos,
  input  logic [10:0] io_enq_bits_tgtID,
  input  logic [10:0] io_enq_bits_srcID,
  input  logic [11:0] io_enq_bits_txnID,
  input  logic [6:0] io_enq_bits_opcode,
  input  logic [2:0] io_enq_bits_size,
  input  logic [47:0] io_enq_bits_addr,
  input  logic io_enq_bits_likelyshared,
  input  logic io_enq_bits_allowRetry,
  input  logic [3:0] io_enq_bits_pCrdType,
  input  logic io_enq_bits_memAttr_allocate,
  input  logic io_enq_bits_memAttr_cacheable,
  input  logic io_enq_bits_memAttr_device,
  input  logic io_enq_bits_memAttr_ewa,
  input  logic io_enq_bits_snpAttr,
  input  logic io_enq_bits_expCompAck,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_qos,
  output logic [11:0] io_deq_bits_txnID,
  output logic [10:0] io_deq_bits_returnNID,
  output logic io_deq_bits_stashNIDValid,
  output logic [11:0] io_deq_bits_returnTxnID,
  output logic [6:0] io_deq_bits_opcode,
  output logic [47:0] io_deq_bits_addr,
  output logic io_deq_bits_ns,
  output logic io_deq_bits_likelyshared,
  output logic io_deq_bits_allowRetry,
  output logic [1:0] io_deq_bits_order,
  output logic [3:0] io_deq_bits_pCrdType,
  output logic io_deq_bits_memAttr_allocate,
  output logic io_deq_bits_memAttr_cacheable,
  output logic io_deq_bits_memAttr_device,
  output logic io_deq_bits_memAttr_ewa,
  output logic io_deq_bits_snpAttr,
  output logic [7:0] io_deq_bits_lpIDWithPadding,
  output logic io_deq_bits_snoopMe,
  output logic io_deq_bits_expCompAck,
  output logic [1:0] io_deq_bits_tagOp,
  output logic io_deq_bits_traceTag,
  output logic io_deq_bits_mpam_perfMonGroup,
  output logic [8:0] io_deq_bits_mpam_partID,
  output logic io_deq_bits_mpam_mpamNS,
  output logic [3:0] io_deq_bits_rsvdc,
  output logic [4:0] io_count
);

  logic       do_enq;
  logic [3:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [4:0] count;
  logic       enq_ready, deq_valid;
  logic [136:0] ramReadWord;

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
  ram_16x137 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({18'h0, io_enq_bits_expCompAck, 9'h0, io_enq_bits_snpAttr, io_enq_bits_memAttr_ewa, io_enq_bits_memAttr_device, io_enq_bits_memAttr_cacheable, io_enq_bits_memAttr_allocate, io_enq_bits_pCrdType, 2'h0, io_enq_bits_allowRetry, io_enq_bits_likelyshared, 1'h0, io_enq_bits_addr, io_enq_bits_opcode, 24'h0, io_enq_bits_txnID, io_enq_bits_qos})
  );

  assign io_deq_valid = deq_valid;
  assign io_count     = count;

  assign io_deq_bits_qos = ramReadWord[3:0];
  assign io_deq_bits_txnID = ramReadWord[15:4];
  assign io_deq_bits_returnNID = ramReadWord[26:16];
  assign io_deq_bits_stashNIDValid = ramReadWord[27];
  assign io_deq_bits_returnTxnID = ramReadWord[39:28];
  assign io_deq_bits_opcode = ramReadWord[46:40];
  assign io_deq_bits_addr = ramReadWord[94:47];
  assign io_deq_bits_ns = ramReadWord[95];
  assign io_deq_bits_likelyshared = ramReadWord[96];
  assign io_deq_bits_allowRetry = ramReadWord[97];
  assign io_deq_bits_order = ramReadWord[99:98];
  assign io_deq_bits_pCrdType = ramReadWord[103:100];
  assign io_deq_bits_memAttr_allocate = ramReadWord[104];
  assign io_deq_bits_memAttr_cacheable = ramReadWord[105];
  assign io_deq_bits_memAttr_device = ramReadWord[106];
  assign io_deq_bits_memAttr_ewa = ramReadWord[107];
  assign io_deq_bits_snpAttr = ramReadWord[108];
  assign io_deq_bits_lpIDWithPadding = ramReadWord[116:109];
  assign io_deq_bits_snoopMe = ramReadWord[117];
  assign io_deq_bits_expCompAck = ramReadWord[118];
  assign io_deq_bits_tagOp = ramReadWord[120:119];
  assign io_deq_bits_traceTag = ramReadWord[121];
  assign io_deq_bits_mpam_perfMonGroup = ramReadWord[122];
  assign io_deq_bits_mpam_partID = ramReadWord[131:123];
  assign io_deq_bits_mpam_mpamNS = ramReadWord[132];
  assign io_deq_bits_rsvdc = ramReadWord[136:133];

endmodule
// END GENERATED(Queue16_CHIREQ)
