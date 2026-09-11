// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXSNP 双例化逐拍比对: golden TXSNP vs 可读重写 TXSNP_xs。
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
  logic [11:0] io_task_bits_set;
  logic [1:0] io_task_bits_bank;
  logic [27:0] io_task_bits_tag;
  logic io_task_bits_snpVec_0;
  logic [11:0] io_task_bits_txnID;
  logic [10:0] io_task_bits_fwdNID;
  logic [11:0] io_task_bits_fwdTxnID;
  logic [6:0] io_task_bits_chiOpcode;
  logic io_task_bits_retToSrc;
  logic io_task_bits_doNotGoToSD;
  logic io_snp_ready;
  wire g_io_task_ready;
  wire i_io_task_ready;
  wire g_io_snp_valid;
  wire i_io_snp_valid;
  wire [11:0] g_io_snp_bits_txnID;
  wire [11:0] i_io_snp_bits_txnID;
  wire [10:0] g_io_snp_bits_fwdNID;
  wire [10:0] i_io_snp_bits_fwdNID;
  wire [11:0] g_io_snp_bits_fwdTxnID;
  wire [11:0] i_io_snp_bits_fwdTxnID;
  wire [4:0] g_io_snp_bits_opcode;
  wire [4:0] i_io_snp_bits_opcode;
  wire [44:0] g_io_snp_bits_addr;
  wire [44:0] i_io_snp_bits_addr;
  wire g_io_snp_bits_doNotGoToSD;
  wire i_io_snp_bits_doNotGoToSD;
  wire g_io_snp_bits_retToSrc;
  wire i_io_snp_bits_retToSrc;
  wire g_io_snpMask_0;
  wire i_io_snpMask_0;

  TXSNP u_g (
    .io_task_ready(g_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_set(io_task_bits_set),
    .io_task_bits_bank(io_task_bits_bank),
    .io_task_bits_tag(io_task_bits_tag),
    .io_task_bits_snpVec_0(io_task_bits_snpVec_0),
    .io_task_bits_txnID(io_task_bits_txnID),
    .io_task_bits_fwdNID(io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(io_task_bits_chiOpcode),
    .io_task_bits_retToSrc(io_task_bits_retToSrc),
    .io_task_bits_doNotGoToSD(io_task_bits_doNotGoToSD),
    .io_snp_ready(io_snp_ready),
    .io_snp_valid(g_io_snp_valid),
    .io_snp_bits_txnID(g_io_snp_bits_txnID),
    .io_snp_bits_fwdNID(g_io_snp_bits_fwdNID),
    .io_snp_bits_fwdTxnID(g_io_snp_bits_fwdTxnID),
    .io_snp_bits_opcode(g_io_snp_bits_opcode),
    .io_snp_bits_addr(g_io_snp_bits_addr),
    .io_snp_bits_doNotGoToSD(g_io_snp_bits_doNotGoToSD),
    .io_snp_bits_retToSrc(g_io_snp_bits_retToSrc),
    .io_snpMask_0(g_io_snpMask_0)
  );
  TXSNP_xs u_i (
    .io_task_ready(i_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_set(io_task_bits_set),
    .io_task_bits_bank(io_task_bits_bank),
    .io_task_bits_tag(io_task_bits_tag),
    .io_task_bits_snpVec_0(io_task_bits_snpVec_0),
    .io_task_bits_txnID(io_task_bits_txnID),
    .io_task_bits_fwdNID(io_task_bits_fwdNID),
    .io_task_bits_fwdTxnID(io_task_bits_fwdTxnID),
    .io_task_bits_chiOpcode(io_task_bits_chiOpcode),
    .io_task_bits_retToSrc(io_task_bits_retToSrc),
    .io_task_bits_doNotGoToSD(io_task_bits_doNotGoToSD),
    .io_snp_ready(io_snp_ready),
    .io_snp_valid(i_io_snp_valid),
    .io_snp_bits_txnID(i_io_snp_bits_txnID),
    .io_snp_bits_fwdNID(i_io_snp_bits_fwdNID),
    .io_snp_bits_fwdTxnID(i_io_snp_bits_fwdTxnID),
    .io_snp_bits_opcode(i_io_snp_bits_opcode),
    .io_snp_bits_addr(i_io_snp_bits_addr),
    .io_snp_bits_doNotGoToSD(i_io_snp_bits_doNotGoToSD),
    .io_snp_bits_retToSrc(i_io_snp_bits_retToSrc),
    .io_snpMask_0(i_io_snpMask_0)
  );

  task automatic drive_random();
    io_task_valid = ($urandom_range(0,1) == 0);
    io_task_bits_set = $urandom;
    io_task_bits_bank = $urandom;
    io_task_bits_tag = $urandom;
    io_task_bits_snpVec_0 = $urandom;
    io_task_bits_txnID = $urandom;
    io_task_bits_fwdNID = $urandom;
    io_task_bits_fwdTxnID = $urandom;
    io_task_bits_chiOpcode = $urandom;
    io_task_bits_retToSrc = $urandom;
    io_task_bits_doNotGoToSD = $urandom;
    io_snp_ready = ($urandom_range(0,3) != 0);
  endtask

  task automatic check_outputs();
    `CHK(io_task_ready)
    `CHK(io_snp_valid)
    `CHK(io_snp_bits_txnID)
    `CHK(io_snp_bits_fwdNID)
    `CHK(io_snp_bits_fwdTxnID)
    `CHK(io_snp_bits_opcode)
    `CHK(io_snp_bits_addr)
    `CHK(io_snp_bits_doNotGoToSD)
    `CHK(io_snp_bits_retToSrc)
    `CHK(io_snpMask_0)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_task_valid = '0;
    io_task_bits_set = '0;
    io_task_bits_bank = '0;
    io_task_bits_tag = '0;
    io_task_bits_snpVec_0 = '0;
    io_task_bits_txnID = '0;
    io_task_bits_fwdNID = '0;
    io_task_bits_fwdTxnID = '0;
    io_task_bits_chiOpcode = '0;
    io_task_bits_retToSrc = '0;
    io_task_bits_doNotGoToSD = '0;
    io_snp_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXSNP checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
