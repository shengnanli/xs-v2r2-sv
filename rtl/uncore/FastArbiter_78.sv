// =============================================================================
//  FastArbiter_78 —— CHI RXRSP (rsp) 2 路 round-robin 仲裁器 (可读核 xs_FastArbiter_78_core)
// -----------------------------------------------------------------------------
//  XSTop 顶层 CHI 交叉开关: 2 个上行主口经本仲裁器轮转选一路发往下游。
//  与 SNXbar/RNXbar 的 4 输入 FastArbiter 同族, 但 N=2 且 golden 用特化的 2 位
//  rrSelOH/rrGrantMask 展开式 (非通用 pkg), 本核逐位忠实复刻。
//  payload = CHI RXRSP (rsp) flit 子集, 打包成 packed struct 后用胜者 one-hot OR
//  归约多路选择到 io_out。无 io_in_ready 端口 (上游用 io_chosen 自行回送),
//  下游背压只看 io_out_ready。
// =============================================================================
module xs_FastArbiter_78_core(
  input clock,
  input reset,
  input io_in_0_valid,
  input [3:0] io_in_0_bits_qos,
  input [10:0] io_in_0_bits_tgtID,
  input [10:0] io_in_0_bits_srcID,
  input [11:0] io_in_0_bits_txnID,
  input [4:0] io_in_0_bits_opcode,
  input [1:0] io_in_0_bits_respErr,
  input [2:0] io_in_0_bits_resp,
  input [2:0] io_in_0_bits_fwdState,
  input [2:0] io_in_0_bits_cBusy,
  input [11:0] io_in_0_bits_dbID,
  input [3:0] io_in_0_bits_pCrdType,
  input [1:0] io_in_0_bits_tagOp,
  input io_in_0_bits_traceTag,
  input io_in_1_valid,
  input [3:0] io_in_1_bits_qos,
  input [10:0] io_in_1_bits_tgtID,
  input [10:0] io_in_1_bits_srcID,
  input [11:0] io_in_1_bits_txnID,
  input [4:0] io_in_1_bits_opcode,
  input [1:0] io_in_1_bits_respErr,
  input [2:0] io_in_1_bits_resp,
  input [2:0] io_in_1_bits_fwdState,
  input [2:0] io_in_1_bits_cBusy,
  input [11:0] io_in_1_bits_dbID,
  input [3:0] io_in_1_bits_pCrdType,
  input [1:0] io_in_1_bits_tagOp,
  input io_in_1_bits_traceTag,
  input io_out_ready,
  output io_out_valid,
  output [3:0] io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [4:0] io_out_bits_opcode,
  output [1:0] io_out_bits_respErr,
  output [2:0] io_out_bits_resp,
  output [2:0] io_out_bits_fwdState,
  output [2:0] io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [3:0] io_out_bits_pCrdType,
  output [1:0] io_out_bits_tagOp,
  output io_out_bits_traceTag,
  output io_chosen
);

  // ---- CHI RXRSP (rsp) flit payload (打包成 packed struct, 便于 one-hot OR 多路选择) ----
  typedef struct packed {
    logic [3:0] qos;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [4:0] opcode;
    logic [1:0] respErr;
    logic [2:0] resp;
    logic [2:0] fwdState;
    logic [2:0] cBusy;
    logic [11:0] dbID;
    logic [3:0] pCrdType;
    logic [1:0] tagOp;
    logic traceTag;
  } flit_t;

  flit_t       pin [2];
  logic [1:0]  valids;

  assign valids = {io_in_1_valid, io_in_0_valid};
  assign pin[0] = '{qos:io_in_0_bits_qos, tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID, opcode:io_in_0_bits_opcode, respErr:io_in_0_bits_respErr, resp:io_in_0_bits_resp, fwdState:io_in_0_bits_fwdState, cBusy:io_in_0_bits_cBusy, dbID:io_in_0_bits_dbID, pCrdType:io_in_0_bits_pCrdType, tagOp:io_in_0_bits_tagOp, traceTag:io_in_0_bits_traceTag};
  assign pin[1] = '{qos:io_in_1_bits_qos, tgtID:io_in_1_bits_tgtID, srcID:io_in_1_bits_srcID, txnID:io_in_1_bits_txnID, opcode:io_in_1_bits_opcode, respErr:io_in_1_bits_respErr, resp:io_in_1_bits_resp, fwdState:io_in_1_bits_fwdState, cBusy:io_in_1_bits_cBusy, dbID:io_in_1_bits_dbID, pCrdType:io_in_1_bits_pCrdType, tagOp:io_in_1_bits_tagOp, traceTag:io_in_1_bits_traceTag};

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
  assign io_out_bits_opcode               = psel.opcode;
  assign io_out_bits_respErr              = psel.respErr;
  assign io_out_bits_resp                 = psel.resp;
  assign io_out_bits_fwdState             = psel.fwdState;
  assign io_out_bits_cBusy                = psel.cBusy;
  assign io_out_bits_dbID                 = psel.dbID;
  assign io_out_bits_pCrdType             = psel.pCrdType;
  assign io_out_bits_tagOp                = psel.tagOp;
  assign io_out_bits_traceTag             = psel.traceTag;
  assign io_chosen    = chosenOH[1];

endmodule
