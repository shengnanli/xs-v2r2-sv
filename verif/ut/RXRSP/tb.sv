// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// RXRSP 双例化逐拍比对: golden RXRSP vs 可读重写 RXRSP_xs。
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
  logic io_out_valid;
  logic [10:0] io_out_bits_srcID;
  logic [11:0] io_out_bits_txnID;
  logic [4:0] io_out_bits_opcode;
  logic [1:0] io_out_bits_respErr;
  logic [2:0] io_out_bits_resp;
  logic [11:0] io_out_bits_dbID;
  logic [3:0] io_out_bits_pCrdType;
  logic io_out_bits_traceTag;
  wire g_io_in_valid;
  wire i_io_in_valid;
  wire [7:0] g_io_in_mshrId;
  wire [7:0] i_io_in_mshrId;
  wire [6:0] g_io_in_respInfo_chiOpcode;
  wire [6:0] i_io_in_respInfo_chiOpcode;
  wire [10:0] g_io_in_respInfo_srcID;
  wire [10:0] i_io_in_respInfo_srcID;
  wire [11:0] g_io_in_respInfo_dbID;
  wire [11:0] i_io_in_respInfo_dbID;
  wire [2:0] g_io_in_respInfo_resp;
  wire [2:0] i_io_in_respInfo_resp;
  wire [3:0] g_io_in_respInfo_pCrdType;
  wire [3:0] i_io_in_respInfo_pCrdType;
  wire [1:0] g_io_in_respInfo_respErr;
  wire [1:0] i_io_in_respInfo_respErr;
  wire g_io_in_respInfo_traceTag;
  wire i_io_in_respInfo_traceTag;

  RXRSP u_g (
    .io_out_valid(io_out_valid),
    .io_out_bits_srcID(io_out_bits_srcID),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_pCrdType(io_out_bits_pCrdType),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_in_valid(g_io_in_valid),
    .io_in_mshrId(g_io_in_mshrId),
    .io_in_respInfo_chiOpcode(g_io_in_respInfo_chiOpcode),
    .io_in_respInfo_srcID(g_io_in_respInfo_srcID),
    .io_in_respInfo_dbID(g_io_in_respInfo_dbID),
    .io_in_respInfo_resp(g_io_in_respInfo_resp),
    .io_in_respInfo_pCrdType(g_io_in_respInfo_pCrdType),
    .io_in_respInfo_respErr(g_io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(g_io_in_respInfo_traceTag)
  );
  RXRSP_xs u_i (
    .io_out_valid(io_out_valid),
    .io_out_bits_srcID(io_out_bits_srcID),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_pCrdType(io_out_bits_pCrdType),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_in_valid(i_io_in_valid),
    .io_in_mshrId(i_io_in_mshrId),
    .io_in_respInfo_chiOpcode(i_io_in_respInfo_chiOpcode),
    .io_in_respInfo_srcID(i_io_in_respInfo_srcID),
    .io_in_respInfo_dbID(i_io_in_respInfo_dbID),
    .io_in_respInfo_resp(i_io_in_respInfo_resp),
    .io_in_respInfo_pCrdType(i_io_in_respInfo_pCrdType),
    .io_in_respInfo_respErr(i_io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(i_io_in_respInfo_traceTag)
  );

  task automatic drive_random();
    io_out_valid = ($urandom_range(0,1) == 0);
    io_out_bits_srcID = $urandom;
    io_out_bits_txnID = $urandom;
    io_out_bits_opcode = $urandom;
    io_out_bits_respErr = $urandom;
    io_out_bits_resp = $urandom;
    io_out_bits_dbID = $urandom;
    io_out_bits_pCrdType = $urandom;
    io_out_bits_traceTag = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_valid)
    `CHK(io_in_mshrId)
    `CHK(io_in_respInfo_chiOpcode)
    `CHK(io_in_respInfo_srcID)
    `CHK(io_in_respInfo_dbID)
    `CHK(io_in_respInfo_resp)
    `CHK(io_in_respInfo_pCrdType)
    `CHK(io_in_respInfo_respErr)
    `CHK(io_in_respInfo_traceTag)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_out_valid = '0;
    io_out_bits_srcID = '0;
    io_out_bits_txnID = '0;
    io_out_bits_opcode = '0;
    io_out_bits_respErr = '0;
    io_out_bits_resp = '0;
    io_out_bits_dbID = '0;
    io_out_bits_pCrdType = '0;
    io_out_bits_traceTag = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("RXRSP checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
