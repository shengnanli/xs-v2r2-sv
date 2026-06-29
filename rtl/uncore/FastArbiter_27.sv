// =============================================================================
//  FastArbiter_27 —— CHI RSP 4 路 round-robin 仲裁器 (可读核 xs_FastArbiter_27_core)
// -----------------------------------------------------------------------------
//  RNXbar RXRSP: 4 路 CHI 响应 (response) flit 经本仲裁器轮转选一路输出。
//  payload = CHI RSP flit 子集 (qos/tgtID/txnID/opcode/respErr/resp/fwdState/cBusy/
//  dbID/pCrdType/tagOp/traceTag)。仲裁算法见 fastarbiter_pkg。
//  与 _44/_46/_47 唯一结构差异: 带 io_in_X_ready 输出 (= 选中 & 下游 ready),
//  即标准 Decoupled 握手 (DecoupledIO.fire = ready & valid)。
// =============================================================================
module xs_FastArbiter_27_core
  import fastarbiter_pkg::*;
(
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input  [4:0]  io_in_0_bits_opcode,
  input  [1:0]  io_in_0_bits_respErr,
  input  [2:0]  io_in_0_bits_resp,
  input  [2:0]  io_in_0_bits_fwdState,
  input  [2:0]  io_in_0_bits_cBusy,
  input  [11:0] io_in_0_bits_dbID,
  input  [3:0]  io_in_0_bits_pCrdType,
  input  [1:0]  io_in_0_bits_tagOp,
  input         io_in_0_bits_traceTag,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input  [4:0]  io_in_1_bits_opcode,
  input  [1:0]  io_in_1_bits_respErr,
  input  [2:0]  io_in_1_bits_resp,
  input  [2:0]  io_in_1_bits_fwdState,
  input  [2:0]  io_in_1_bits_cBusy,
  input  [11:0] io_in_1_bits_dbID,
  input  [3:0]  io_in_1_bits_pCrdType,
  input  [1:0]  io_in_1_bits_tagOp,
  input         io_in_1_bits_traceTag,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_qos,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input  [4:0]  io_in_2_bits_opcode,
  input  [1:0]  io_in_2_bits_respErr,
  input  [2:0]  io_in_2_bits_resp,
  input  [2:0]  io_in_2_bits_fwdState,
  input  [2:0]  io_in_2_bits_cBusy,
  input  [11:0] io_in_2_bits_dbID,
  input  [3:0]  io_in_2_bits_pCrdType,
  input  [1:0]  io_in_2_bits_tagOp,
  input         io_in_2_bits_traceTag,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [3:0]  io_in_3_bits_qos,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input  [4:0]  io_in_3_bits_opcode,
  input  [1:0]  io_in_3_bits_respErr,
  input  [2:0]  io_in_3_bits_resp,
  input  [2:0]  io_in_3_bits_fwdState,
  input  [2:0]  io_in_3_bits_cBusy,
  input  [11:0] io_in_3_bits_dbID,
  input  [3:0]  io_in_3_bits_pCrdType,
  input  [1:0]  io_in_3_bits_tagOp,
  input         io_in_3_bits_traceTag,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_respErr,
  output [2:0]  io_out_bits_resp,
  output [2:0]  io_out_bits_fwdState,
  output [2:0]  io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [3:0]  io_out_bits_pCrdType,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  output [IDXW-1:0] io_chosen
);

  // ---- CHI RSP flit payload ----
  typedef struct packed {
    logic [3:0]  qos;
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [4:0]  opcode;
    logic [1:0]  respErr;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic [2:0]  cBusy;
    logic [11:0] dbID;
    logic [3:0]  pCrdType;
    logic [1:0]  tagOp;
    logic        traceTag;
  } rsp_t;

  rsp_t            pin [NUM];
  logic [NUM-1:0]  valids;

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  assign pin[0] = '{qos:io_in_0_bits_qos, tgtID:io_in_0_bits_tgtID, txnID:io_in_0_bits_txnID,
                    opcode:io_in_0_bits_opcode, respErr:io_in_0_bits_respErr, resp:io_in_0_bits_resp,
                    fwdState:io_in_0_bits_fwdState, cBusy:io_in_0_bits_cBusy, dbID:io_in_0_bits_dbID,
                    pCrdType:io_in_0_bits_pCrdType, tagOp:io_in_0_bits_tagOp,
                    traceTag:io_in_0_bits_traceTag};
  assign pin[1] = '{qos:io_in_1_bits_qos, tgtID:io_in_1_bits_tgtID, txnID:io_in_1_bits_txnID,
                    opcode:io_in_1_bits_opcode, respErr:io_in_1_bits_respErr, resp:io_in_1_bits_resp,
                    fwdState:io_in_1_bits_fwdState, cBusy:io_in_1_bits_cBusy, dbID:io_in_1_bits_dbID,
                    pCrdType:io_in_1_bits_pCrdType, tagOp:io_in_1_bits_tagOp,
                    traceTag:io_in_1_bits_traceTag};
  assign pin[2] = '{qos:io_in_2_bits_qos, tgtID:io_in_2_bits_tgtID, txnID:io_in_2_bits_txnID,
                    opcode:io_in_2_bits_opcode, respErr:io_in_2_bits_respErr, resp:io_in_2_bits_resp,
                    fwdState:io_in_2_bits_fwdState, cBusy:io_in_2_bits_cBusy, dbID:io_in_2_bits_dbID,
                    pCrdType:io_in_2_bits_pCrdType, tagOp:io_in_2_bits_tagOp,
                    traceTag:io_in_2_bits_traceTag};
  assign pin[3] = '{qos:io_in_3_bits_qos, tgtID:io_in_3_bits_tgtID, txnID:io_in_3_bits_txnID,
                    opcode:io_in_3_bits_opcode, respErr:io_in_3_bits_respErr, resp:io_in_3_bits_resp,
                    fwdState:io_in_3_bits_fwdState, cBusy:io_in_3_bits_cBusy, dbID:io_in_3_bits_dbID,
                    pCrdType:io_in_3_bits_pCrdType, tagOp:io_in_3_bits_tagOp,
                    traceTag:io_in_3_bits_traceTag};

  // ---- round-robin 状态 + 组合选胜 ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  assign chosenOH = rr_choose(valids, pendingMask, rrGrantMask);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;
      rrGrantMask <= gt_mask(chosenOH);
    end
  end

  // ---- 胜者 payload 多路选择 ----
  rsp_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  // 输入握手: 第 i 路 ready = 被选中 (chosenOH[i]) 且下游可收 (io_out_ready)。
  assign io_in_0_ready = chosenOH[0] & io_out_ready;
  assign io_in_1_ready = chosenOH[1] & io_out_ready;
  assign io_in_2_ready = chosenOH[2] & io_out_ready;
  assign io_in_3_ready = chosenOH[3] & io_out_ready;

  assign io_out_valid          = |valids;
  assign io_out_bits_qos       = psel.qos;
  assign io_out_bits_tgtID     = psel.tgtID;
  assign io_out_bits_txnID     = psel.txnID;
  assign io_out_bits_opcode    = psel.opcode;
  assign io_out_bits_respErr   = psel.respErr;
  assign io_out_bits_resp      = psel.resp;
  assign io_out_bits_fwdState  = psel.fwdState;
  assign io_out_bits_cBusy     = psel.cBusy;
  assign io_out_bits_dbID      = psel.dbID;
  assign io_out_bits_pCrdType  = psel.pCrdType;
  assign io_out_bits_tagOp     = psel.tagOp;
  assign io_out_bits_traceTag  = psel.traceTag;
  assign io_chosen             = encode_oh(chosenOH);

endmodule
