// =============================================================================
//  TXSNP —— openLLC CHI SNP 发送通道 可读重写核 (xs_TXSNP_core)
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/chi/TXSNP.scala
//  LLC(L3) 侧: 接收内部 Task, 转成 CHI SNP flit 上发给各 RN(L2), 并输出 snpMask(被嗅探者掩码)。
//  单态化 (firtool TXSNP.sv): 纯组合; numRNs=1 ⇒ snpMask/snpVec 只有 1 位。
//
//  语义 (Task.toCHISNPBundle 直通):
//    snp.valid  = task.valid, task.ready = snp.ready (握手转接)
//    snp.opcode = task.chiOpcode[4:0]     (7b 内部 opcode 截到 5b CHI SNP opcode)
//    snp.addr   = {tag, set, bank, 3'b0}  (块地址重组: 物理地址低 3 位补零 = 8B 对齐)
//    txnID/fwdNID/fwdTxnID/doNotGoToSD/retToSrc 同名直通
//    snpMask_0  = task.snpVec_0           (该 RN 是否被嗅探)
// =============================================================================
module xs_TXSNP_core (
  // ---- io.task (Flipped DecoupledIO Task, 来自 LLC 内部) ----
  output        io_task_ready,
  input         io_task_valid,
  input  [11:0] io_task_bits_set,
  input  [1:0]  io_task_bits_bank,
  input  [27:0] io_task_bits_tag,
  input         io_task_bits_snpVec_0,
  input  [11:0] io_task_bits_txnID,
  input  [10:0] io_task_bits_fwdNID,
  input  [11:0] io_task_bits_fwdTxnID,
  input  [6:0]  io_task_bits_chiOpcode,
  input         io_task_bits_retToSrc,
  input         io_task_bits_doNotGoToSD,
  // ---- io.snp (DecoupledIO CHISNP, 上发给 RN) ----
  input         io_snp_ready,
  output        io_snp_valid,
  output [11:0] io_snp_bits_txnID,
  output [10:0] io_snp_bits_fwdNID,
  output [11:0] io_snp_bits_fwdTxnID,
  output [4:0]  io_snp_bits_opcode,
  output [44:0] io_snp_bits_addr,
  output        io_snp_bits_doNotGoToSD,
  output        io_snp_bits_retToSrc,
  // ---- io.snpMask (Output Vec(numRNs=1, Bool)) ----
  output        io_snpMask_0
);

  // 握手转接
  assign io_task_ready = io_snp_ready;
  assign io_snp_valid  = io_task_valid;

  // SNP flit 字段
  assign io_snp_bits_txnID       = io_task_bits_txnID;
  assign io_snp_bits_fwdNID      = io_task_bits_fwdNID;
  assign io_snp_bits_fwdTxnID    = io_task_bits_fwdTxnID;
  assign io_snp_bits_opcode      = io_task_bits_chiOpcode[4:0];
  assign io_snp_bits_addr        = {io_task_bits_tag, io_task_bits_set, io_task_bits_bank, 3'h0};
  assign io_snp_bits_doNotGoToSD = io_task_bits_doNotGoToSD;
  assign io_snp_bits_retToSrc    = io_task_bits_retToSrc;

  // 被嗅探者掩码
  assign io_snpMask_0 = io_task_bits_snpVec_0;

endmodule
