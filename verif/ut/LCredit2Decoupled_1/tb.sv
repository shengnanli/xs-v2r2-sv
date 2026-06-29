// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// LCredit2Decoupled_1 双例化逐拍比对: golden LCredit2Decoupled_1 vs 可读重写 LCredit2Decoupled_1_xs。
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
  logic io_in_flitv;
  logic [72:0] io_in_flit;
  logic io_out_ready;
  logic [1:0] io_state_state;
  wire g_io_in_lcrdv;
  wire i_io_in_lcrdv;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
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
  wire g_io_reclaimLCredit;
  wire i_io_reclaimLCredit;

  LCredit2Decoupled_1 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_flitv(io_in_flitv),
    .io_in_flit(io_in_flit),
    .io_in_lcrdv(g_io_in_lcrdv),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_srcID(g_io_out_bits_srcID),
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
    .io_state_state(io_state_state),
    .io_reclaimLCredit(g_io_reclaimLCredit)
  );
  LCredit2Decoupled_1_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_flitv(io_in_flitv),
    .io_in_flit(io_in_flit),
    .io_in_lcrdv(i_io_in_lcrdv),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_srcID(i_io_out_bits_srcID),
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
    .io_state_state(io_state_state),
    .io_reclaimLCredit(i_io_reclaimLCredit)
  );

  task automatic drive_random();
    io_in_flitv = $urandom;
    io_in_flit = {$urandom, $urandom, $urandom};
    io_out_ready = ($urandom_range(0,3) != 0);
    io_state_state = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_lcrdv)
    `CHK(io_out_valid)
    `CHK(io_out_bits_qos)
    `CHK(io_out_bits_tgtID)
    `CHK(io_out_bits_srcID)
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
    `CHK(io_reclaimLCredit)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_flitv = '0;
    io_in_flit = '0;
    io_out_ready = '0;
    io_state_state = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("LCredit2Decoupled_1 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
