// Queue4_CHISNP.sv —— coupledL2 tl2chi/chi/LinkLayer.scala:182 `Queue(gen, entries = lcreditNum, pipe = true, flow = false)`：链路层收到的 SNP flit 缓冲（L-credit 数 = 深度）
//
// chisel3 Queue(entries=4, pipe=true, flow=false) 的单态化；例化处：LCredit2Decoupled.queue。
// 控制逻辑在 rtl/uncore/xs_ChiselQueuePipe_core.sv（pipe=true：满队列只要出口在接，入口照样 ready）；
// 存储是 golden 的 ram_4x115 行为级叶子（4 项 x 115 位，两侧同源 inline）。
// 本文件只做字段拼接/拆分。ram 字（lsb 起）：
//   qos[3:0] srcID[14:4] txnID[26:15] fwdNID[37:27] fwdTxnID[49:38] opcode[54:50] addr[99:55] ns[100:100]
//   doNotGoToSD[101:101] retToSrc[102:102] traceTag[103:103] mpam_perfMonGroup[104:104] mpam_partID[113:105]
//   mpam_mpamNS[114:114]
// golden 217 行；端口表与连线由 scripts/gen_uncore_queues.py 从 golden 机械生成并逐字段校验。

// BEGIN GENERATED(Queue4_CHISNP) —— scripts/gen_uncore_queues.py
module Queue4_CHISNP (
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
  output logic [3:0] io_deq_bits_qos,
  output logic [10:0] io_deq_bits_srcID,
  output logic [11:0] io_deq_bits_txnID,
  output logic [10:0] io_deq_bits_fwdNID,
  output logic [11:0] io_deq_bits_fwdTxnID,
  output logic [4:0] io_deq_bits_opcode,
  output logic [44:0] io_deq_bits_addr,
  output logic io_deq_bits_ns,
  output logic io_deq_bits_doNotGoToSD,
  output logic io_deq_bits_retToSrc,
  output logic io_deq_bits_traceTag,
  output logic io_deq_bits_mpam_perfMonGroup,
  output logic [8:0] io_deq_bits_mpam_partID,
  output logic io_deq_bits_mpam_mpamNS,
  output logic [2:0] io_count
);

  logic       do_enq;
  logic [1:0] enq_ptr, deq_ptr;
  logic       empty;
  logic [2:0] count;
  logic       enq_ready, deq_valid;
  logic [114:0] ramReadWord;

  xs_ChiselQueuePipe_core #(.DEPTH(4)) u_core (
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
  ram_4x115 ram_ext (
    .R0_addr (deq_ptr),
    .R0_en   (1'b1),
    .R0_clk  (clock),
    .R0_data (ramReadWord),
    .W0_addr (enq_ptr),
    .W0_en   (do_enq),
    .W0_clk  (clock),
    .W0_data ({io_enq_bits_mpam_mpamNS, io_enq_bits_mpam_partID, io_enq_bits_mpam_perfMonGroup, io_enq_bits_traceTag, io_enq_bits_retToSrc, io_enq_bits_doNotGoToSD, io_enq_bits_ns, io_enq_bits_addr, io_enq_bits_opcode, io_enq_bits_fwdTxnID, io_enq_bits_fwdNID, io_enq_bits_txnID, io_enq_bits_srcID, io_enq_bits_qos})
  );

  assign io_enq_ready = enq_ready;
  assign io_deq_valid = deq_valid;
  assign io_count     = count;

  assign io_deq_bits_qos = ramReadWord[3:0];
  assign io_deq_bits_srcID = ramReadWord[14:4];
  assign io_deq_bits_txnID = ramReadWord[26:15];
  assign io_deq_bits_fwdNID = ramReadWord[37:27];
  assign io_deq_bits_fwdTxnID = ramReadWord[49:38];
  assign io_deq_bits_opcode = ramReadWord[54:50];
  assign io_deq_bits_addr = ramReadWord[99:55];
  assign io_deq_bits_ns = ramReadWord[100];
  assign io_deq_bits_doNotGoToSD = ramReadWord[101];
  assign io_deq_bits_retToSrc = ramReadWord[102];
  assign io_deq_bits_traceTag = ramReadWord[103];
  assign io_deq_bits_mpam_perfMonGroup = ramReadWord[104];
  assign io_deq_bits_mpam_partID = ramReadWord[113:105];
  assign io_deq_bits_mpam_mpamNS = ramReadWord[114];

endmodule
// END GENERATED(Queue4_CHISNP)
