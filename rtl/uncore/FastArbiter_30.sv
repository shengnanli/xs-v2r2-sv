// =============================================================================
//  FastArbiter_30 —— 单输入退化 FastArbiter (可读核 xs_FastArbiter_30_core)
// -----------------------------------------------------------------------------
//  RNXbar TXREQ: 每个 bank 只有 1 路输入, FastArbiter 退化为纯透传 (恒授权 input 0,
//  无状态、无 clock/reset)。本核把完整 CHI REQ flit payload 打包成 struct 后原样输出,
//  文档化通道字段布局 (含 memAttr/mpam 子结构); 组合等价于逐字段直连。
// =============================================================================
module xs_FastArbiter_30_core(
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_returnNID,
  input         io_in_0_bits_stashNIDValid,
  input  [11:0] io_in_0_bits_returnTxnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [2:0]  io_in_0_bits_size,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_ns,
  input         io_in_0_bits_likelyshared,
  input         io_in_0_bits_allowRetry,
  input  [1:0]  io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_memAttr_cacheable,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  input         io_in_0_bits_snpAttr,
  input  [7:0]  io_in_0_bits_lpIDWithPadding,
  input         io_in_0_bits_snoopMe,
  input         io_in_0_bits_expCompAck,
  input  [1:0]  io_in_0_bits_tagOp,
  input         io_in_0_bits_traceTag,
  input         io_in_0_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_0_bits_mpam_partID,
  input         io_in_0_bits_mpam_mpamNS,
  input  [3:0]  io_in_0_bits_rsvdc,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_returnNID,
  output        io_out_bits_stashNIDValid,
  output [11:0] io_out_bits_returnTxnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_ns,
  output        io_out_bits_likelyshared,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_snpAttr,
  output [7:0]  io_out_bits_lpIDWithPadding,
  output        io_out_bits_snoopMe,
  output        io_out_bits_expCompAck,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  output        io_out_bits_mpam_perfMonGroup,
  output [8:0]  io_out_bits_mpam_partID,
  output        io_out_bits_mpam_mpamNS,
  output [3:0]  io_out_bits_rsvdc
);

  typedef struct packed {
    logic [3:0]  qos;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] returnNID;
    logic        stashNIDValid;
    logic [11:0] returnTxnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        ns;
    logic        likelyshared;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
    logic [7:0]  lpIDWithPadding;
    logic        snoopMe;
    logic        expCompAck;
    logic [1:0]  tagOp;
    logic        traceTag;
    logic        mpam_perfMonGroup;
    logic [8:0]  mpam_partID;
    logic        mpam_mpamNS;
    logic [3:0]  rsvdc;
  } req_t;

  req_t flit;
  assign flit = '{qos:io_in_0_bits_qos, tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID,
                  txnID:io_in_0_bits_txnID, returnNID:io_in_0_bits_returnNID,
                  stashNIDValid:io_in_0_bits_stashNIDValid, returnTxnID:io_in_0_bits_returnTxnID,
                  opcode:io_in_0_bits_opcode, size:io_in_0_bits_size, addr:io_in_0_bits_addr,
                  ns:io_in_0_bits_ns, likelyshared:io_in_0_bits_likelyshared,
                  allowRetry:io_in_0_bits_allowRetry, order:io_in_0_bits_order,
                  pCrdType:io_in_0_bits_pCrdType, memAttr_allocate:io_in_0_bits_memAttr_allocate,
                  memAttr_cacheable:io_in_0_bits_memAttr_cacheable,
                  memAttr_device:io_in_0_bits_memAttr_device, memAttr_ewa:io_in_0_bits_memAttr_ewa,
                  snpAttr:io_in_0_bits_snpAttr, lpIDWithPadding:io_in_0_bits_lpIDWithPadding,
                  snoopMe:io_in_0_bits_snoopMe, expCompAck:io_in_0_bits_expCompAck,
                  tagOp:io_in_0_bits_tagOp, traceTag:io_in_0_bits_traceTag,
                  mpam_perfMonGroup:io_in_0_bits_mpam_perfMonGroup,
                  mpam_partID:io_in_0_bits_mpam_partID, mpam_mpamNS:io_in_0_bits_mpam_mpamNS,
                  rsvdc:io_in_0_bits_rsvdc};

  assign io_out_valid                 = io_in_0_valid;   // 单输入: 恒透传
  assign io_out_bits_qos              = flit.qos;
  assign io_out_bits_tgtID            = flit.tgtID;
  assign io_out_bits_srcID            = flit.srcID;
  assign io_out_bits_txnID            = flit.txnID;
  assign io_out_bits_returnNID        = flit.returnNID;
  assign io_out_bits_stashNIDValid    = flit.stashNIDValid;
  assign io_out_bits_returnTxnID      = flit.returnTxnID;
  assign io_out_bits_opcode           = flit.opcode;
  assign io_out_bits_size             = flit.size;
  assign io_out_bits_addr             = flit.addr;
  assign io_out_bits_ns               = flit.ns;
  assign io_out_bits_likelyshared     = flit.likelyshared;
  assign io_out_bits_allowRetry       = flit.allowRetry;
  assign io_out_bits_order            = flit.order;
  assign io_out_bits_pCrdType         = flit.pCrdType;
  assign io_out_bits_memAttr_allocate = flit.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable= flit.memAttr_cacheable;
  assign io_out_bits_memAttr_device   = flit.memAttr_device;
  assign io_out_bits_memAttr_ewa      = flit.memAttr_ewa;
  assign io_out_bits_snpAttr          = flit.snpAttr;
  assign io_out_bits_lpIDWithPadding  = flit.lpIDWithPadding;
  assign io_out_bits_snoopMe          = flit.snoopMe;
  assign io_out_bits_expCompAck       = flit.expCompAck;
  assign io_out_bits_tagOp            = flit.tagOp;
  assign io_out_bits_traceTag         = flit.traceTag;
  assign io_out_bits_mpam_perfMonGroup= flit.mpam_perfMonGroup;
  assign io_out_bits_mpam_partID      = flit.mpam_partID;
  assign io_out_bits_mpam_mpamNS      = flit.mpam_mpamNS;
  assign io_out_bits_rsvdc            = flit.rsvdc;

endmodule
