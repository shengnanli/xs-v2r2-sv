// =============================================================================
//  FastArbiter_79 —— CHI RXDAT (dat, 256b data) 2 路 round-robin 仲裁器 (可读核 xs_FastArbiter_79_core)
// -----------------------------------------------------------------------------
//  XSTop 顶层 CHI 交叉开关: 2 个上行主口经本仲裁器轮转选一路发往下游。
//  与 SNXbar/RNXbar 的 4 输入 FastArbiter 同族, 但 N=2 且 golden 用特化的 2 位
//  rrSelOH/rrGrantMask 展开式 (非通用 pkg), 本核逐位忠实复刻。
//  payload = CHI RXDAT (dat, 256b data) flit 子集, 打包成 packed struct 后用胜者 one-hot OR
//  归约多路选择到 io_out。无 io_in_ready 端口 (上游用 io_chosen 自行回送),
//  下游背压只看 io_out_ready。
// =============================================================================
module xs_FastArbiter_79_core(
  input clock,
  input reset,
  input io_in_0_valid,
  input [3:0] io_in_0_bits_qos,
  input [10:0] io_in_0_bits_tgtID,
  input [10:0] io_in_0_bits_srcID,
  input [11:0] io_in_0_bits_txnID,
  input [10:0] io_in_0_bits_homeNID,
  input [3:0] io_in_0_bits_opcode,
  input [1:0] io_in_0_bits_respErr,
  input [2:0] io_in_0_bits_resp,
  input [3:0] io_in_0_bits_dataSource,
  input [2:0] io_in_0_bits_cBusy,
  input [11:0] io_in_0_bits_dbID,
  input [1:0] io_in_0_bits_ccID,
  input [1:0] io_in_0_bits_dataID,
  input [1:0] io_in_0_bits_tagOp,
  input [7:0] io_in_0_bits_tag,
  input [1:0] io_in_0_bits_tu,
  input io_in_0_bits_traceTag,
  input [3:0] io_in_0_bits_rsvdc,
  input [31:0] io_in_0_bits_be,
  input [255:0] io_in_0_bits_data,
  input [31:0] io_in_0_bits_dataCheck,
  input [3:0] io_in_0_bits_poison,
  input io_in_1_valid,
  input [3:0] io_in_1_bits_qos,
  input [10:0] io_in_1_bits_tgtID,
  input [10:0] io_in_1_bits_srcID,
  input [11:0] io_in_1_bits_txnID,
  input [10:0] io_in_1_bits_homeNID,
  input [3:0] io_in_1_bits_opcode,
  input [1:0] io_in_1_bits_respErr,
  input [2:0] io_in_1_bits_resp,
  input [3:0] io_in_1_bits_dataSource,
  input [2:0] io_in_1_bits_cBusy,
  input [11:0] io_in_1_bits_dbID,
  input [1:0] io_in_1_bits_ccID,
  input [1:0] io_in_1_bits_dataID,
  input [1:0] io_in_1_bits_tagOp,
  input [7:0] io_in_1_bits_tag,
  input [1:0] io_in_1_bits_tu,
  input io_in_1_bits_traceTag,
  input [3:0] io_in_1_bits_rsvdc,
  input [31:0] io_in_1_bits_be,
  input [255:0] io_in_1_bits_data,
  input [31:0] io_in_1_bits_dataCheck,
  input [3:0] io_in_1_bits_poison,
  input io_out_ready,
  output io_out_valid,
  output [3:0] io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_homeNID,
  output [3:0] io_out_bits_opcode,
  output [1:0] io_out_bits_respErr,
  output [2:0] io_out_bits_resp,
  output [3:0] io_out_bits_dataSource,
  output [2:0] io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [1:0] io_out_bits_ccID,
  output [1:0] io_out_bits_dataID,
  output [1:0] io_out_bits_tagOp,
  output [7:0] io_out_bits_tag,
  output [1:0] io_out_bits_tu,
  output io_out_bits_traceTag,
  output [3:0] io_out_bits_rsvdc,
  output [31:0] io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0] io_out_bits_dataCheck,
  output [3:0] io_out_bits_poison,
  output io_chosen
);

  // ---- CHI RXDAT (dat, 256b data) flit payload (打包成 packed struct, 便于 one-hot OR 多路选择) ----
  typedef struct packed {
    logic [3:0] qos;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [3:0] opcode;
    logic [1:0] respErr;
    logic [2:0] resp;
    logic [3:0] dataSource;
    logic [2:0] cBusy;
    logic [11:0] dbID;
    logic [1:0] ccID;
    logic [1:0] dataID;
    logic [1:0] tagOp;
    logic [7:0] tag;
    logic [1:0] tu;
    logic traceTag;
    logic [3:0] rsvdc;
    logic [31:0] be;
    logic [255:0] data;
    logic [31:0] dataCheck;
    logic [3:0] poison;
  } flit_t;

  flit_t       pin [2];
  logic [1:0]  valids;

  assign valids = {io_in_1_valid, io_in_0_valid};
  assign pin[0] = '{qos:io_in_0_bits_qos, tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID, homeNID:io_in_0_bits_homeNID, opcode:io_in_0_bits_opcode, respErr:io_in_0_bits_respErr, resp:io_in_0_bits_resp, dataSource:io_in_0_bits_dataSource, cBusy:io_in_0_bits_cBusy, dbID:io_in_0_bits_dbID, ccID:io_in_0_bits_ccID, dataID:io_in_0_bits_dataID, tagOp:io_in_0_bits_tagOp, tag:io_in_0_bits_tag, tu:io_in_0_bits_tu, traceTag:io_in_0_bits_traceTag, rsvdc:io_in_0_bits_rsvdc, be:io_in_0_bits_be, data:io_in_0_bits_data, dataCheck:io_in_0_bits_dataCheck, poison:io_in_0_bits_poison};
  assign pin[1] = '{qos:io_in_1_bits_qos, tgtID:io_in_1_bits_tgtID, srcID:io_in_1_bits_srcID, txnID:io_in_1_bits_txnID, homeNID:io_in_1_bits_homeNID, opcode:io_in_1_bits_opcode, respErr:io_in_1_bits_respErr, resp:io_in_1_bits_resp, dataSource:io_in_1_bits_dataSource, cBusy:io_in_1_bits_cBusy, dbID:io_in_1_bits_dbID, ccID:io_in_1_bits_ccID, dataID:io_in_1_bits_dataID, tagOp:io_in_1_bits_tagOp, tag:io_in_1_bits_tag, tu:io_in_1_bits_tu, traceTag:io_in_1_bits_traceTag, rsvdc:io_in_1_bits_rsvdc, be:io_in_1_bits_be, data:io_in_1_bits_data, dataCheck:io_in_1_bits_dataCheck, poison:io_in_1_bits_poison};

  // ---- 2 输入 round-robin 状态 + 组合选胜 (逐位复刻 golden 特化展开) ----
  reg   [1:0] pendingMask;
  reg   [1:0] rrGrantMask;
  logic [1:0] chosenOH;

  wire        rrSelOH_T3 = rrGrantMask[0] & pendingMask[0];
  wire [1:0]  rrSelOH    = {rrGrantMask[1] & pendingMask[1] & ~rrSelOH_T3, rrSelOH_T3};
  assign chosenOH =
    (|(rrSelOH & valids)) ? rrSelOH
                          : {io_in_1_valid & ~io_in_0_valid, io_in_0_valid};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= 2'h0;
      rrGrantMask <= 2'h0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;     // 没被选中的 valid 转入欠服务
      rrGrantMask <= {chosenOH[0], 1'h0};  // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  flit_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < 2; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid = |valids;
  assign io_out_bits_qos                  = psel.qos;
  assign io_out_bits_tgtID                = psel.tgtID;
  assign io_out_bits_srcID                = psel.srcID;
  assign io_out_bits_txnID                = psel.txnID;
  assign io_out_bits_homeNID              = psel.homeNID;
  assign io_out_bits_opcode               = psel.opcode;
  assign io_out_bits_respErr              = psel.respErr;
  assign io_out_bits_resp                 = psel.resp;
  assign io_out_bits_dataSource           = psel.dataSource;
  assign io_out_bits_cBusy                = psel.cBusy;
  assign io_out_bits_dbID                 = psel.dbID;
  assign io_out_bits_ccID                 = psel.ccID;
  assign io_out_bits_dataID               = psel.dataID;
  assign io_out_bits_tagOp                = psel.tagOp;
  assign io_out_bits_tag                  = psel.tag;
  assign io_out_bits_tu                   = psel.tu;
  assign io_out_bits_traceTag             = psel.traceTag;
  assign io_out_bits_rsvdc                = psel.rsvdc;
  assign io_out_bits_be                   = psel.be;
  assign io_out_bits_data                 = psel.data;
  assign io_out_bits_dataCheck            = psel.dataCheck;
  assign io_out_bits_poison               = psel.poison;
  assign io_chosen    = chosenOH[1];

endmodule
