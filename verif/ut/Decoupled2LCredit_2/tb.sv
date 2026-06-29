// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// Decoupled2LCredit_2 双例化逐拍比对: golden Decoupled2LCredit_2 vs 可读重写 Decoupled2LCredit_2_xs。
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
  logic [3:0] io_in_bits_qos;
  logic [10:0] io_in_bits_tgtID;
  logic [10:0] io_in_bits_srcID;
  logic [11:0] io_in_bits_txnID;
  logic [10:0] io_in_bits_homeNID;
  logic [3:0] io_in_bits_opcode;
  logic [1:0] io_in_bits_respErr;
  logic [2:0] io_in_bits_resp;
  logic [3:0] io_in_bits_dataSource;
  logic [2:0] io_in_bits_cBusy;
  logic [11:0] io_in_bits_dbID;
  logic [1:0] io_in_bits_ccID;
  logic [1:0] io_in_bits_dataID;
  logic [1:0] io_in_bits_tagOp;
  logic [7:0] io_in_bits_tag;
  logic [1:0] io_in_bits_tu;
  logic io_in_bits_traceTag;
  logic [3:0] io_in_bits_rsvdc;
  logic [31:0] io_in_bits_be;
  logic [255:0] io_in_bits_data;
  logic [31:0] io_in_bits_dataCheck;
  logic [3:0] io_in_bits_poison;
  logic io_out_lcrdv;
  logic [1:0] io_state_state;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_flitpend;
  wire i_io_out_flitpend;
  wire g_io_out_flitv;
  wire i_io_out_flitv;
  wire [421:0] g_io_out_flit;
  wire [421:0] i_io_out_flit;

  Decoupled2LCredit_2 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_qos(io_in_bits_qos),
    .io_in_bits_tgtID(io_in_bits_tgtID),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_homeNID(io_in_bits_homeNID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_respErr(io_in_bits_respErr),
    .io_in_bits_resp(io_in_bits_resp),
    .io_in_bits_dataSource(io_in_bits_dataSource),
    .io_in_bits_cBusy(io_in_bits_cBusy),
    .io_in_bits_dbID(io_in_bits_dbID),
    .io_in_bits_ccID(io_in_bits_ccID),
    .io_in_bits_dataID(io_in_bits_dataID),
    .io_in_bits_tagOp(io_in_bits_tagOp),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_tu(io_in_bits_tu),
    .io_in_bits_traceTag(io_in_bits_traceTag),
    .io_in_bits_rsvdc(io_in_bits_rsvdc),
    .io_in_bits_be(io_in_bits_be),
    .io_in_bits_data(io_in_bits_data),
    .io_in_bits_dataCheck(io_in_bits_dataCheck),
    .io_in_bits_poison(io_in_bits_poison),
    .io_out_flitpend(g_io_out_flitpend),
    .io_out_flitv(g_io_out_flitv),
    .io_out_flit(g_io_out_flit),
    .io_out_lcrdv(io_out_lcrdv),
    .io_state_state(io_state_state)
  );
  Decoupled2LCredit_2_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_qos(io_in_bits_qos),
    .io_in_bits_tgtID(io_in_bits_tgtID),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_homeNID(io_in_bits_homeNID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_respErr(io_in_bits_respErr),
    .io_in_bits_resp(io_in_bits_resp),
    .io_in_bits_dataSource(io_in_bits_dataSource),
    .io_in_bits_cBusy(io_in_bits_cBusy),
    .io_in_bits_dbID(io_in_bits_dbID),
    .io_in_bits_ccID(io_in_bits_ccID),
    .io_in_bits_dataID(io_in_bits_dataID),
    .io_in_bits_tagOp(io_in_bits_tagOp),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_tu(io_in_bits_tu),
    .io_in_bits_traceTag(io_in_bits_traceTag),
    .io_in_bits_rsvdc(io_in_bits_rsvdc),
    .io_in_bits_be(io_in_bits_be),
    .io_in_bits_data(io_in_bits_data),
    .io_in_bits_dataCheck(io_in_bits_dataCheck),
    .io_in_bits_poison(io_in_bits_poison),
    .io_out_flitpend(i_io_out_flitpend),
    .io_out_flitv(i_io_out_flitv),
    .io_out_flit(i_io_out_flit),
    .io_out_lcrdv(io_out_lcrdv),
    .io_state_state(io_state_state)
  );

  task automatic drive_random();
    io_in_valid = ($urandom_range(0,1) == 0);
    io_in_bits_qos = $urandom;
    io_in_bits_tgtID = $urandom;
    io_in_bits_srcID = $urandom;
    io_in_bits_txnID = $urandom;
    io_in_bits_homeNID = $urandom;
    io_in_bits_opcode = $urandom;
    io_in_bits_respErr = $urandom;
    io_in_bits_resp = $urandom;
    io_in_bits_dataSource = $urandom;
    io_in_bits_cBusy = $urandom;
    io_in_bits_dbID = $urandom;
    io_in_bits_ccID = $urandom;
    io_in_bits_dataID = $urandom;
    io_in_bits_tagOp = $urandom;
    io_in_bits_tag = $urandom;
    io_in_bits_tu = $urandom;
    io_in_bits_traceTag = $urandom;
    io_in_bits_rsvdc = $urandom;
    io_in_bits_be = $urandom;
    io_in_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_in_bits_dataCheck = $urandom;
    io_in_bits_poison = $urandom;
    io_out_lcrdv = $urandom;
    io_state_state = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_ready)
    `CHK(io_out_flitpend)
    `CHK(io_out_flitv)
    `CHK(io_out_flit)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_valid = '0;
    io_in_bits_qos = '0;
    io_in_bits_tgtID = '0;
    io_in_bits_srcID = '0;
    io_in_bits_txnID = '0;
    io_in_bits_homeNID = '0;
    io_in_bits_opcode = '0;
    io_in_bits_respErr = '0;
    io_in_bits_resp = '0;
    io_in_bits_dataSource = '0;
    io_in_bits_cBusy = '0;
    io_in_bits_dbID = '0;
    io_in_bits_ccID = '0;
    io_in_bits_dataID = '0;
    io_in_bits_tagOp = '0;
    io_in_bits_tag = '0;
    io_in_bits_tu = '0;
    io_in_bits_traceTag = '0;
    io_in_bits_rsvdc = '0;
    io_in_bits_be = '0;
    io_in_bits_data = '0;
    io_in_bits_dataCheck = '0;
    io_in_bits_poison = '0;
    io_out_lcrdv = '0;
    io_state_state = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("Decoupled2LCredit_2 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
