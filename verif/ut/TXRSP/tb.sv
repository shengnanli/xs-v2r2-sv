// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXRSP 双例化逐拍比对: golden TXRSP vs 可读重写 TXRSP_xs。
`timescale 1ns/1ps
`define CHK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0; bit reset; int errors = 0; int checks = 0;
  always #5 clock = ~clock;
  logic io_pipeRsp_valid;
  logic [2:0] io_pipeRsp_bits_txChannel;
  logic io_pipeRsp_bits_denied;
  logic [10:0] io_pipeRsp_bits_tgtID;
  logic [10:0] io_pipeRsp_bits_srcID;
  logic [11:0] io_pipeRsp_bits_txnID;
  logic [11:0] io_pipeRsp_bits_dbID;
  logic [6:0] io_pipeRsp_bits_chiOpcode;
  logic [2:0] io_pipeRsp_bits_resp;
  logic [2:0] io_pipeRsp_bits_fwdState;
  logic [3:0] io_pipeRsp_bits_pCrdType;
  logic io_pipeRsp_bits_traceTag;
  logic io_mshrRsp_valid;
  logic [10:0] io_mshrRsp_bits_tgtID;
  logic [11:0] io_mshrRsp_bits_txnID;
  logic [4:0] io_mshrRsp_bits_opcode;
  logic io_mshrRsp_bits_traceTag;
  logic io_out_ready;
  logic io_pipeStatusVec_1_valid;
  logic [2:0] io_pipeStatusVec_1_bits_channel;
  logic [2:0] io_pipeStatusVec_1_bits_txChannel;
  logic io_pipeStatusVec_1_bits_mshrTask;
  logic io_pipeStatusVec_2_valid;
  logic [2:0] io_pipeStatusVec_2_bits_channel;
  logic [2:0] io_pipeStatusVec_2_bits_txChannel;
  logic io_pipeStatusVec_2_bits_mshrTask;
  logic io_pipeStatusVec_3_valid;
  logic [2:0] io_pipeStatusVec_3_bits_channel;
  logic [2:0] io_pipeStatusVec_3_bits_txChannel;
  logic io_pipeStatusVec_3_bits_mshrTask;
  logic io_pipeStatusVec_4_valid;
  logic [2:0] io_pipeStatusVec_4_bits_channel;
  logic [2:0] io_pipeStatusVec_4_bits_txChannel;
  logic io_pipeStatusVec_4_bits_mshrTask;
  wire g_io_mshrRsp_ready;
  wire i_io_mshrRsp_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [4:0] g_io_out_bits_opcode;
  wire [4:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_respErr;
  wire [1:0] i_io_out_bits_respErr;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [2:0] g_io_out_bits_fwdState;
  wire [2:0] i_io_out_bits_fwdState;
  wire [2:0] g_io_out_bits_cBusy;
  wire [2:0] i_io_out_bits_cBusy;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [3:0] g_io_out_bits_pCrdType;
  wire [3:0] i_io_out_bits_pCrdType;
  wire [1:0] g_io_out_bits_tagOp;
  wire [1:0] i_io_out_bits_tagOp;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire g_io_toReqArb_blockMSHRReqEntrance;
  wire i_io_toReqArb_blockMSHRReqEntrance;
  wire g_io_toReqArb_blockSinkBReqEntrance;
  wire i_io_toReqArb_blockSinkBReqEntrance;

  TXRSP u_g (
    .clock(clock),
    .reset(reset),
    .io_pipeRsp_valid(io_pipeRsp_valid),
    .io_pipeRsp_bits_txChannel(io_pipeRsp_bits_txChannel),
    .io_pipeRsp_bits_denied(io_pipeRsp_bits_denied),
    .io_pipeRsp_bits_tgtID(io_pipeRsp_bits_tgtID),
    .io_pipeRsp_bits_srcID(io_pipeRsp_bits_srcID),
    .io_pipeRsp_bits_txnID(io_pipeRsp_bits_txnID),
    .io_pipeRsp_bits_dbID(io_pipeRsp_bits_dbID),
    .io_pipeRsp_bits_chiOpcode(io_pipeRsp_bits_chiOpcode),
    .io_pipeRsp_bits_resp(io_pipeRsp_bits_resp),
    .io_pipeRsp_bits_fwdState(io_pipeRsp_bits_fwdState),
    .io_pipeRsp_bits_pCrdType(io_pipeRsp_bits_pCrdType),
    .io_pipeRsp_bits_traceTag(io_pipeRsp_bits_traceTag),
    .io_mshrRsp_ready(g_io_mshrRsp_ready),
    .io_mshrRsp_valid(io_mshrRsp_valid),
    .io_mshrRsp_bits_tgtID(io_mshrRsp_bits_tgtID),
    .io_mshrRsp_bits_txnID(io_mshrRsp_bits_txnID),
    .io_mshrRsp_bits_opcode(io_mshrRsp_bits_opcode),
    .io_mshrRsp_bits_traceTag(io_mshrRsp_bits_traceTag),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_respErr(g_io_out_bits_respErr),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_fwdState(g_io_out_bits_fwdState),
    .io_out_bits_cBusy(g_io_out_bits_cBusy),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_pCrdType(g_io_out_bits_pCrdType),
    .io_out_bits_tagOp(g_io_out_bits_tagOp),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(g_io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance(g_io_toReqArb_blockSinkBReqEntrance)
  );
  TXRSP_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_pipeRsp_valid(io_pipeRsp_valid),
    .io_pipeRsp_bits_txChannel(io_pipeRsp_bits_txChannel),
    .io_pipeRsp_bits_denied(io_pipeRsp_bits_denied),
    .io_pipeRsp_bits_tgtID(io_pipeRsp_bits_tgtID),
    .io_pipeRsp_bits_srcID(io_pipeRsp_bits_srcID),
    .io_pipeRsp_bits_txnID(io_pipeRsp_bits_txnID),
    .io_pipeRsp_bits_dbID(io_pipeRsp_bits_dbID),
    .io_pipeRsp_bits_chiOpcode(io_pipeRsp_bits_chiOpcode),
    .io_pipeRsp_bits_resp(io_pipeRsp_bits_resp),
    .io_pipeRsp_bits_fwdState(io_pipeRsp_bits_fwdState),
    .io_pipeRsp_bits_pCrdType(io_pipeRsp_bits_pCrdType),
    .io_pipeRsp_bits_traceTag(io_pipeRsp_bits_traceTag),
    .io_mshrRsp_ready(i_io_mshrRsp_ready),
    .io_mshrRsp_valid(io_mshrRsp_valid),
    .io_mshrRsp_bits_tgtID(io_mshrRsp_bits_tgtID),
    .io_mshrRsp_bits_txnID(io_mshrRsp_bits_txnID),
    .io_mshrRsp_bits_opcode(io_mshrRsp_bits_opcode),
    .io_mshrRsp_bits_traceTag(io_mshrRsp_bits_traceTag),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_respErr(i_io_out_bits_respErr),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_fwdState(i_io_out_bits_fwdState),
    .io_out_bits_cBusy(i_io_out_bits_cBusy),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_pCrdType(i_io_out_bits_pCrdType),
    .io_out_bits_tagOp(i_io_out_bits_tagOp),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_channel(io_pipeStatusVec_1_bits_channel),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_channel(io_pipeStatusVec_2_bits_channel),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_channel(io_pipeStatusVec_3_bits_channel),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_channel(io_pipeStatusVec_4_bits_channel),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(i_io_toReqArb_blockMSHRReqEntrance),
    .io_toReqArb_blockSinkBReqEntrance(i_io_toReqArb_blockSinkBReqEntrance)
  );

  task automatic drive_random();
    io_pipeRsp_valid = ($urandom_range(0,1) == 0);
    io_pipeRsp_bits_txChannel = $urandom;
    io_pipeRsp_bits_denied = $urandom;
    io_pipeRsp_bits_tgtID = $urandom;
    io_pipeRsp_bits_srcID = $urandom;
    io_pipeRsp_bits_txnID = $urandom;
    io_pipeRsp_bits_dbID = $urandom;
    io_pipeRsp_bits_chiOpcode = $urandom;
    io_pipeRsp_bits_resp = $urandom;
    io_pipeRsp_bits_fwdState = $urandom;
    io_pipeRsp_bits_pCrdType = $urandom;
    io_pipeRsp_bits_traceTag = $urandom;
    io_mshrRsp_valid = ($urandom_range(0,1) == 0);
    io_mshrRsp_bits_tgtID = $urandom;
    io_mshrRsp_bits_txnID = $urandom;
    io_mshrRsp_bits_opcode = $urandom;
    io_mshrRsp_bits_traceTag = $urandom;
    io_out_ready = ($urandom_range(0,3) != 0);
    io_pipeStatusVec_1_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_1_bits_channel = $urandom;
    io_pipeStatusVec_1_bits_txChannel = $urandom;
    io_pipeStatusVec_1_bits_mshrTask = $urandom;
    io_pipeStatusVec_2_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_2_bits_channel = $urandom;
    io_pipeStatusVec_2_bits_txChannel = $urandom;
    io_pipeStatusVec_2_bits_mshrTask = $urandom;
    io_pipeStatusVec_3_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_3_bits_channel = $urandom;
    io_pipeStatusVec_3_bits_txChannel = $urandom;
    io_pipeStatusVec_3_bits_mshrTask = $urandom;
    io_pipeStatusVec_4_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_4_bits_channel = $urandom;
    io_pipeStatusVec_4_bits_txChannel = $urandom;
    io_pipeStatusVec_4_bits_mshrTask = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_mshrRsp_ready)
    `CHK(io_out_valid)
    `CHK(io_out_bits_qos)
    `CHK(io_out_bits_tgtID)
    `CHK(io_out_bits_txnID)
    `CHK(io_out_bits_opcode)
    `CHK(io_out_bits_respErr)
    `CHK(io_out_bits_resp)
    `CHK(io_out_bits_fwdState)
    `CHK(io_out_bits_cBusy)
    `CHK(io_out_bits_dbID)
    `CHK(io_out_bits_pCrdType)
    `CHK(io_out_bits_tagOp)
    `CHK(io_out_bits_traceTag)
    `CHK(io_toReqArb_blockMSHRReqEntrance)
    `CHK(io_toReqArb_blockSinkBReqEntrance)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_pipeRsp_valid = '0;
    io_pipeRsp_bits_txChannel = '0;
    io_pipeRsp_bits_denied = '0;
    io_pipeRsp_bits_tgtID = '0;
    io_pipeRsp_bits_srcID = '0;
    io_pipeRsp_bits_txnID = '0;
    io_pipeRsp_bits_dbID = '0;
    io_pipeRsp_bits_chiOpcode = '0;
    io_pipeRsp_bits_resp = '0;
    io_pipeRsp_bits_fwdState = '0;
    io_pipeRsp_bits_pCrdType = '0;
    io_pipeRsp_bits_traceTag = '0;
    io_mshrRsp_valid = '0;
    io_mshrRsp_bits_tgtID = '0;
    io_mshrRsp_bits_txnID = '0;
    io_mshrRsp_bits_opcode = '0;
    io_mshrRsp_bits_traceTag = '0;
    io_out_ready = '0;
    io_pipeStatusVec_1_valid = '0;
    io_pipeStatusVec_1_bits_channel = '0;
    io_pipeStatusVec_1_bits_txChannel = '0;
    io_pipeStatusVec_1_bits_mshrTask = '0;
    io_pipeStatusVec_2_valid = '0;
    io_pipeStatusVec_2_bits_channel = '0;
    io_pipeStatusVec_2_bits_txChannel = '0;
    io_pipeStatusVec_2_bits_mshrTask = '0;
    io_pipeStatusVec_3_valid = '0;
    io_pipeStatusVec_3_bits_channel = '0;
    io_pipeStatusVec_3_bits_txChannel = '0;
    io_pipeStatusVec_3_bits_mshrTask = '0;
    io_pipeStatusVec_4_valid = '0;
    io_pipeStatusVec_4_bits_channel = '0;
    io_pipeStatusVec_4_bits_txChannel = '0;
    io_pipeStatusVec_4_bits_mshrTask = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXRSP checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
