// =============================================================================
//  FastArbiter_31 —— 单输入退化 FastArbiter (可读核 xs_FastArbiter_31_core)
// -----------------------------------------------------------------------------
//  RNXbar TXDAT: 每个 bank 只有 1 路输入, FastArbiter 退化为纯透传 (恒授权 input 0,
//  无状态、无 clock/reset)。本核把完整 CHI DAT flit payload 打包成 struct 后原样输出,
//  文档化通道字段布局; 组合等价于逐字段直连。
// =============================================================================
module xs_FastArbiter_31_core(
  input          io_in_0_valid,
  input  [3:0]   io_in_0_bits_qos,
  input  [10:0]  io_in_0_bits_tgtID,
  input  [10:0]  io_in_0_bits_srcID,
  input  [11:0]  io_in_0_bits_txnID,
  input  [10:0]  io_in_0_bits_homeNID,
  input  [3:0]   io_in_0_bits_opcode,
  input  [1:0]   io_in_0_bits_respErr,
  input  [2:0]   io_in_0_bits_resp,
  input  [3:0]   io_in_0_bits_dataSource,
  input  [2:0]   io_in_0_bits_cBusy,
  input  [11:0]  io_in_0_bits_dbID,
  input  [1:0]   io_in_0_bits_ccID,
  input  [1:0]   io_in_0_bits_dataID,
  input  [1:0]   io_in_0_bits_tagOp,
  input  [7:0]   io_in_0_bits_tag,
  input  [1:0]   io_in_0_bits_tu,
  input          io_in_0_bits_traceTag,
  input  [3:0]   io_in_0_bits_rsvdc,
  input  [31:0]  io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0]  io_in_0_bits_dataCheck,
  input  [3:0]   io_in_0_bits_poison,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_tgtID,
  output [10:0]  io_out_bits_srcID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [1:0]   io_out_bits_respErr,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [2:0]   io_out_bits_cBusy,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_ccID,
  output [1:0]   io_out_bits_dataID,
  output [1:0]   io_out_bits_tagOp,
  output [7:0]   io_out_bits_tag,
  output [1:0]   io_out_bits_tu,
  output         io_out_bits_traceTag,
  output [3:0]   io_out_bits_rsvdc,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [3:0]   io_out_bits_poison
);

  typedef struct packed {
    logic [3:0]   qos;
    logic [10:0]  tgtID;
    logic [10:0]  srcID;
    logic [11:0]  txnID;
    logic [10:0]  homeNID;
    logic [3:0]   opcode;
    logic [1:0]   respErr;
    logic [2:0]   resp;
    logic [3:0]   dataSource;
    logic [2:0]   cBusy;
    logic [11:0]  dbID;
    logic [1:0]   ccID;
    logic [1:0]   dataID;
    logic [1:0]   tagOp;
    logic [7:0]   tag;
    logic [1:0]   tu;
    logic         traceTag;
    logic [3:0]   rsvdc;
    logic [31:0]  be;
    logic [255:0] data;
    logic [31:0]  dataCheck;
    logic [3:0]   poison;
  } dat_t;

  dat_t flit;
  assign flit = '{qos:io_in_0_bits_qos, tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID,
                  txnID:io_in_0_bits_txnID, homeNID:io_in_0_bits_homeNID, opcode:io_in_0_bits_opcode,
                  respErr:io_in_0_bits_respErr, resp:io_in_0_bits_resp,
                  dataSource:io_in_0_bits_dataSource, cBusy:io_in_0_bits_cBusy, dbID:io_in_0_bits_dbID,
                  ccID:io_in_0_bits_ccID, dataID:io_in_0_bits_dataID, tagOp:io_in_0_bits_tagOp,
                  tag:io_in_0_bits_tag, tu:io_in_0_bits_tu, traceTag:io_in_0_bits_traceTag,
                  rsvdc:io_in_0_bits_rsvdc, be:io_in_0_bits_be, data:io_in_0_bits_data,
                  dataCheck:io_in_0_bits_dataCheck, poison:io_in_0_bits_poison};

  assign io_out_valid           = io_in_0_valid;   // 单输入: 恒透传
  assign io_out_bits_qos        = flit.qos;
  assign io_out_bits_tgtID      = flit.tgtID;
  assign io_out_bits_srcID      = flit.srcID;
  assign io_out_bits_txnID      = flit.txnID;
  assign io_out_bits_homeNID    = flit.homeNID;
  assign io_out_bits_opcode     = flit.opcode;
  assign io_out_bits_respErr    = flit.respErr;
  assign io_out_bits_resp       = flit.resp;
  assign io_out_bits_dataSource = flit.dataSource;
  assign io_out_bits_cBusy      = flit.cBusy;
  assign io_out_bits_dbID       = flit.dbID;
  assign io_out_bits_ccID       = flit.ccID;
  assign io_out_bits_dataID     = flit.dataID;
  assign io_out_bits_tagOp      = flit.tagOp;
  assign io_out_bits_tag        = flit.tag;
  assign io_out_bits_tu         = flit.tu;
  assign io_out_bits_traceTag   = flit.traceTag;
  assign io_out_bits_rsvdc      = flit.rsvdc;
  assign io_out_bits_be         = flit.be;
  assign io_out_bits_data       = flit.data;
  assign io_out_bits_dataCheck  = flit.dataCheck;
  assign io_out_bits_poison     = flit.poison;

endmodule
