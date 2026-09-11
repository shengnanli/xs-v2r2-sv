// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXDAT_4 双例化逐拍比对: golden TXDAT_4 vs 可读重写 TXDAT_4_xs。
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
  logic io_dat_ready;
  logic io_task_valid;
  logic [10:0] io_task_bits_task_tgtID;
  logic [10:0] io_task_bits_task_srcID;
  logic [11:0] io_task_bits_task_txnID;
  logic [10:0] io_task_bits_task_homeNID;
  logic [11:0] io_task_bits_task_dbID;
  logic [6:0] io_task_bits_task_chiOpcode;
  logic [2:0] io_task_bits_task_resp;
  logic [2:0] io_task_bits_task_fwdState;
  logic [255:0] io_task_bits_data_data_0_data;
  logic [255:0] io_task_bits_data_data_1_data;
  wire g_io_dat_valid;
  wire i_io_dat_valid;
  wire [10:0] g_io_dat_bits_tgtID;
  wire [10:0] i_io_dat_bits_tgtID;
  wire [10:0] g_io_dat_bits_srcID;
  wire [10:0] i_io_dat_bits_srcID;
  wire [11:0] g_io_dat_bits_txnID;
  wire [11:0] i_io_dat_bits_txnID;
  wire [10:0] g_io_dat_bits_homeNID;
  wire [10:0] i_io_dat_bits_homeNID;
  wire [3:0] g_io_dat_bits_opcode;
  wire [3:0] i_io_dat_bits_opcode;
  wire [2:0] g_io_dat_bits_resp;
  wire [2:0] i_io_dat_bits_resp;
  wire [3:0] g_io_dat_bits_dataSource;
  wire [3:0] i_io_dat_bits_dataSource;
  wire [11:0] g_io_dat_bits_dbID;
  wire [11:0] i_io_dat_bits_dbID;
  wire [1:0] g_io_dat_bits_dataID;
  wire [1:0] i_io_dat_bits_dataID;
  wire [31:0] g_io_dat_bits_be;
  wire [31:0] i_io_dat_bits_be;
  wire [255:0] g_io_dat_bits_data;
  wire [255:0] i_io_dat_bits_data;
  wire [31:0] g_io_dat_bits_dataCheck;
  wire [31:0] i_io_dat_bits_dataCheck;
  wire g_io_task_ready;
  wire i_io_task_ready;

  TXDAT_4 u_g (
    .clock(clock),
    .reset(reset),
    .io_dat_ready(io_dat_ready),
    .io_dat_valid(g_io_dat_valid),
    .io_dat_bits_tgtID(g_io_dat_bits_tgtID),
    .io_dat_bits_srcID(g_io_dat_bits_srcID),
    .io_dat_bits_txnID(g_io_dat_bits_txnID),
    .io_dat_bits_homeNID(g_io_dat_bits_homeNID),
    .io_dat_bits_opcode(g_io_dat_bits_opcode),
    .io_dat_bits_resp(g_io_dat_bits_resp),
    .io_dat_bits_dataSource(g_io_dat_bits_dataSource),
    .io_dat_bits_dbID(g_io_dat_bits_dbID),
    .io_dat_bits_dataID(g_io_dat_bits_dataID),
    .io_dat_bits_be(g_io_dat_bits_be),
    .io_dat_bits_data(g_io_dat_bits_data),
    .io_dat_bits_dataCheck(g_io_dat_bits_dataCheck),
    .io_task_ready(g_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_task_tgtID(io_task_bits_task_tgtID),
    .io_task_bits_task_srcID(io_task_bits_task_srcID),
    .io_task_bits_task_txnID(io_task_bits_task_txnID),
    .io_task_bits_task_homeNID(io_task_bits_task_homeNID),
    .io_task_bits_task_dbID(io_task_bits_task_dbID),
    .io_task_bits_task_chiOpcode(io_task_bits_task_chiOpcode),
    .io_task_bits_task_resp(io_task_bits_task_resp),
    .io_task_bits_task_fwdState(io_task_bits_task_fwdState),
    .io_task_bits_data_data_0_data(io_task_bits_data_data_0_data),
    .io_task_bits_data_data_1_data(io_task_bits_data_data_1_data)
  );
  TXDAT_4_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_dat_ready(io_dat_ready),
    .io_dat_valid(i_io_dat_valid),
    .io_dat_bits_tgtID(i_io_dat_bits_tgtID),
    .io_dat_bits_srcID(i_io_dat_bits_srcID),
    .io_dat_bits_txnID(i_io_dat_bits_txnID),
    .io_dat_bits_homeNID(i_io_dat_bits_homeNID),
    .io_dat_bits_opcode(i_io_dat_bits_opcode),
    .io_dat_bits_resp(i_io_dat_bits_resp),
    .io_dat_bits_dataSource(i_io_dat_bits_dataSource),
    .io_dat_bits_dbID(i_io_dat_bits_dbID),
    .io_dat_bits_dataID(i_io_dat_bits_dataID),
    .io_dat_bits_be(i_io_dat_bits_be),
    .io_dat_bits_data(i_io_dat_bits_data),
    .io_dat_bits_dataCheck(i_io_dat_bits_dataCheck),
    .io_task_ready(i_io_task_ready),
    .io_task_valid(io_task_valid),
    .io_task_bits_task_tgtID(io_task_bits_task_tgtID),
    .io_task_bits_task_srcID(io_task_bits_task_srcID),
    .io_task_bits_task_txnID(io_task_bits_task_txnID),
    .io_task_bits_task_homeNID(io_task_bits_task_homeNID),
    .io_task_bits_task_dbID(io_task_bits_task_dbID),
    .io_task_bits_task_chiOpcode(io_task_bits_task_chiOpcode),
    .io_task_bits_task_resp(io_task_bits_task_resp),
    .io_task_bits_task_fwdState(io_task_bits_task_fwdState),
    .io_task_bits_data_data_0_data(io_task_bits_data_data_0_data),
    .io_task_bits_data_data_1_data(io_task_bits_data_data_1_data)
  );

  task automatic drive_random();
    io_dat_ready = ($urandom_range(0,3) != 0);
    io_task_valid = ($urandom_range(0,1) == 0);
    io_task_bits_task_tgtID = $urandom;
    io_task_bits_task_srcID = $urandom;
    io_task_bits_task_txnID = $urandom;
    io_task_bits_task_homeNID = $urandom;
    io_task_bits_task_dbID = $urandom;
    io_task_bits_task_chiOpcode = $urandom;
    io_task_bits_task_resp = $urandom;
    io_task_bits_task_fwdState = $urandom;
    io_task_bits_data_data_0_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_task_bits_data_data_1_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
  endtask

  task automatic check_outputs();
    `CHK(io_dat_valid)
    `CHK(io_dat_bits_tgtID)
    `CHK(io_dat_bits_srcID)
    `CHK(io_dat_bits_txnID)
    `CHK(io_dat_bits_homeNID)
    `CHK(io_dat_bits_opcode)
    `CHK(io_dat_bits_resp)
    `CHK(io_dat_bits_dataSource)
    `CHK(io_dat_bits_dbID)
    `CHK(io_dat_bits_dataID)
    `CHK(io_dat_bits_be)
    `CHK(io_dat_bits_data)
    `CHK(io_dat_bits_dataCheck)
    `CHK(io_task_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_dat_ready = '0;
    io_task_valid = '0;
    io_task_bits_task_tgtID = '0;
    io_task_bits_task_srcID = '0;
    io_task_bits_task_txnID = '0;
    io_task_bits_task_homeNID = '0;
    io_task_bits_task_dbID = '0;
    io_task_bits_task_chiOpcode = '0;
    io_task_bits_task_resp = '0;
    io_task_bits_task_fwdState = '0;
    io_task_bits_data_data_0_data = '0;
    io_task_bits_data_data_1_data = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXDAT_4 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
