// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// RXRSP_4 双例化逐拍比对: golden RXRSP_4 vs 可读重写 RXRSP_4_xs。
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
  logic io_in_valid;
  logic [10:0] io_in_bits_srcID;
  logic [11:0] io_in_bits_txnID;
  logic [4:0] io_in_bits_opcode;
  logic [11:0] io_in_bits_dbID;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [6:0] g_io_out_bits_opcode;
  wire [6:0] i_io_out_bits_opcode;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;

  RXRSP_4 u_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_dbID(io_in_bits_dbID),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_srcID(g_io_out_bits_srcID)
  );
  RXRSP_4_xs u_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_dbID(io_in_bits_dbID),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_srcID(i_io_out_bits_srcID)
  );

  task automatic drive_random();
    io_in_valid = ($urandom_range(0,1) == 0);
    io_in_bits_srcID = $urandom;
    io_in_bits_txnID = $urandom;
    io_in_bits_opcode = $urandom;
    io_in_bits_dbID = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_out_valid)
    `CHK(io_out_bits_txnID)
    `CHK(io_out_bits_dbID)
    `CHK(io_out_bits_opcode)
    `CHK(io_out_bits_srcID)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_valid = '0;
    io_in_bits_srcID = '0;
    io_in_bits_txnID = '0;
    io_in_bits_opcode = '0;
    io_in_bits_dbID = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("RXRSP_4 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
