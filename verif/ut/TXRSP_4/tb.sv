// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXRSP_4 双例化逐拍比对: golden TXRSP_4 vs 可读重写 TXRSP_4_xs。
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
  logic io_task_valid;
  logic [10:0] io_task_bits_tgtID;
  logic [10:0] io_task_bits_srcID;
  logic [11:0] io_task_bits_txnID;
  logic [11:0] io_task_bits_dbID;
  logic [6:0] io_task_bits_chiOpcode;
  logic [2:0] io_task_bits_resp;
  logic [2:0] io_task_bits_fwdState;
  logic [3:0] io_task_bits_pCrdType;
  logic io_rsp_ready;
  wire g_io_task_ready;
  wire i_io_task_ready;
  wire g_io_rsp_valid;
  wire i_io_rsp_valid;
  wire [10:0] g_io_rsp_bits_tgtID;
  wire [10:0] i_io_rsp_bits_tgtID;
  wire [10:0] g_io_rsp_bits_srcID;
  wire [10:0] i_io_rsp_bits_srcID;
  wire [11:0] g_io_rsp_bits_txnID;
  wire [11:0] i_io_rsp_bits_txnID;
  wire [4:0] g_io_rsp_bits_opcode;
  wire [4:0] i_io_rsp_bits_opcode;
  wire [2:0] g_io_rsp_bits_resp;
  wire [2:0] i_io_rsp_bits_resp;
  wire [2:0] g_io_rsp_bits_fwdState;
  wire [2:0] i_io_rsp_bits_fwdState;
  wire [11:0] g_io_rsp_bits_dbID;
  wire [11:0] i_io_rsp_bits_dbID;
  wire [3:0] g_io_rsp_bits_pCrdType;
  wire [3:0] i_io_rsp_bits_pCrdType;

  TXRSP_4 u_g (
    .io_task_ready(g_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_tgtID(io_task_bits_tgtID),
    .io_task_bits_srcID(io_task_bits_srcID),
    .io_task_bits_txnID(io_task_bits_txnID),
    .io_task_bits_dbID(io_task_bits_dbID),
    .io_task_bits_chiOpcode(io_task_bits_chiOpcode),
    .io_task_bits_resp(io_task_bits_resp),
    .io_task_bits_fwdState(io_task_bits_fwdState),
    .io_task_bits_pCrdType(io_task_bits_pCrdType),
    .io_rsp_ready(io_rsp_ready),
    .io_rsp_valid(g_io_rsp_valid),
    .io_rsp_bits_tgtID(g_io_rsp_bits_tgtID),
    .io_rsp_bits_srcID(g_io_rsp_bits_srcID),
    .io_rsp_bits_txnID(g_io_rsp_bits_txnID),
    .io_rsp_bits_opcode(g_io_rsp_bits_opcode),
    .io_rsp_bits_resp(g_io_rsp_bits_resp),
    .io_rsp_bits_fwdState(g_io_rsp_bits_fwdState),
    .io_rsp_bits_dbID(g_io_rsp_bits_dbID),
    .io_rsp_bits_pCrdType(g_io_rsp_bits_pCrdType)
  );
  TXRSP_4_xs u_i (
    .io_task_ready(i_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_tgtID(io_task_bits_tgtID),
    .io_task_bits_srcID(io_task_bits_srcID),
    .io_task_bits_txnID(io_task_bits_txnID),
    .io_task_bits_dbID(io_task_bits_dbID),
    .io_task_bits_chiOpcode(io_task_bits_chiOpcode),
    .io_task_bits_resp(io_task_bits_resp),
    .io_task_bits_fwdState(io_task_bits_fwdState),
    .io_task_bits_pCrdType(io_task_bits_pCrdType),
    .io_rsp_ready(io_rsp_ready),
    .io_rsp_valid(i_io_rsp_valid),
    .io_rsp_bits_tgtID(i_io_rsp_bits_tgtID),
    .io_rsp_bits_srcID(i_io_rsp_bits_srcID),
    .io_rsp_bits_txnID(i_io_rsp_bits_txnID),
    .io_rsp_bits_opcode(i_io_rsp_bits_opcode),
    .io_rsp_bits_resp(i_io_rsp_bits_resp),
    .io_rsp_bits_fwdState(i_io_rsp_bits_fwdState),
    .io_rsp_bits_dbID(i_io_rsp_bits_dbID),
    .io_rsp_bits_pCrdType(i_io_rsp_bits_pCrdType)
  );

  task automatic drive_random();
    io_task_valid = ($urandom_range(0,1) == 0);
    io_task_bits_tgtID = $urandom;
    io_task_bits_srcID = $urandom;
    io_task_bits_txnID = $urandom;
    io_task_bits_dbID = $urandom;
    io_task_bits_chiOpcode = $urandom;
    io_task_bits_resp = $urandom;
    io_task_bits_fwdState = $urandom;
    io_task_bits_pCrdType = $urandom;
    io_rsp_ready = ($urandom_range(0,3) != 0);
  endtask

  task automatic check_outputs();
    `CHK(io_task_ready)
    `CHK(io_rsp_valid)
    `CHK(io_rsp_bits_tgtID)
    `CHK(io_rsp_bits_srcID)
    `CHK(io_rsp_bits_txnID)
    `CHK(io_rsp_bits_opcode)
    `CHK(io_rsp_bits_resp)
    `CHK(io_rsp_bits_fwdState)
    `CHK(io_rsp_bits_dbID)
    `CHK(io_rsp_bits_pCrdType)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_task_valid = '0;
    io_task_bits_tgtID = '0;
    io_task_bits_srcID = '0;
    io_task_bits_txnID = '0;
    io_task_bits_dbID = '0;
    io_task_bits_chiOpcode = '0;
    io_task_bits_resp = '0;
    io_task_bits_fwdState = '0;
    io_task_bits_pCrdType = '0;
    io_rsp_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXRSP_4 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
