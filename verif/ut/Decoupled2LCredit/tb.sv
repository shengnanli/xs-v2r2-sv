// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// Decoupled2LCredit 双例化逐拍比对: golden Decoupled2LCredit vs 可读重写 Decoupled2LCredit_xs。
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
  logic [10:0] io_in_bits_returnNID;
  logic io_in_bits_stashNIDValid;
  logic [11:0] io_in_bits_returnTxnID;
  logic [6:0] io_in_bits_opcode;
  logic [2:0] io_in_bits_size;
  logic [47:0] io_in_bits_addr;
  logic io_in_bits_ns;
  logic io_in_bits_likelyshared;
  logic io_in_bits_allowRetry;
  logic [1:0] io_in_bits_order;
  logic [3:0] io_in_bits_pCrdType;
  logic io_in_bits_memAttr_allocate;
  logic io_in_bits_memAttr_cacheable;
  logic io_in_bits_memAttr_device;
  logic io_in_bits_memAttr_ewa;
  logic io_in_bits_snpAttr;
  logic [7:0] io_in_bits_lpIDWithPadding;
  logic io_in_bits_snoopMe;
  logic io_in_bits_expCompAck;
  logic [1:0] io_in_bits_tagOp;
  logic io_in_bits_traceTag;
  logic io_in_bits_mpam_perfMonGroup;
  logic [8:0] io_in_bits_mpam_partID;
  logic io_in_bits_mpam_mpamNS;
  logic [3:0] io_in_bits_rsvdc;
  logic io_out_lcrdv;
  logic [1:0] io_state_state;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_flitpend;
  wire i_io_out_flitpend;
  wire g_io_out_flitv;
  wire i_io_out_flitv;
  wire [161:0] g_io_out_flit;
  wire [161:0] i_io_out_flit;

  Decoupled2LCredit u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_qos(io_in_bits_qos),
    .io_in_bits_tgtID(io_in_bits_tgtID),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_returnNID(io_in_bits_returnNID),
    .io_in_bits_stashNIDValid(io_in_bits_stashNIDValid),
    .io_in_bits_returnTxnID(io_in_bits_returnTxnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_size(io_in_bits_size),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_ns(io_in_bits_ns),
    .io_in_bits_likelyshared(io_in_bits_likelyshared),
    .io_in_bits_allowRetry(io_in_bits_allowRetry),
    .io_in_bits_order(io_in_bits_order),
    .io_in_bits_pCrdType(io_in_bits_pCrdType),
    .io_in_bits_memAttr_allocate(io_in_bits_memAttr_allocate),
    .io_in_bits_memAttr_cacheable(io_in_bits_memAttr_cacheable),
    .io_in_bits_memAttr_device(io_in_bits_memAttr_device),
    .io_in_bits_memAttr_ewa(io_in_bits_memAttr_ewa),
    .io_in_bits_snpAttr(io_in_bits_snpAttr),
    .io_in_bits_lpIDWithPadding(io_in_bits_lpIDWithPadding),
    .io_in_bits_snoopMe(io_in_bits_snoopMe),
    .io_in_bits_expCompAck(io_in_bits_expCompAck),
    .io_in_bits_tagOp(io_in_bits_tagOp),
    .io_in_bits_traceTag(io_in_bits_traceTag),
    .io_in_bits_mpam_perfMonGroup(io_in_bits_mpam_perfMonGroup),
    .io_in_bits_mpam_partID(io_in_bits_mpam_partID),
    .io_in_bits_mpam_mpamNS(io_in_bits_mpam_mpamNS),
    .io_in_bits_rsvdc(io_in_bits_rsvdc),
    .io_out_flitpend(g_io_out_flitpend),
    .io_out_flitv(g_io_out_flitv),
    .io_out_flit(g_io_out_flit),
    .io_out_lcrdv(io_out_lcrdv),
    .io_state_state(io_state_state)
  );
  Decoupled2LCredit_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_qos(io_in_bits_qos),
    .io_in_bits_tgtID(io_in_bits_tgtID),
    .io_in_bits_srcID(io_in_bits_srcID),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_returnNID(io_in_bits_returnNID),
    .io_in_bits_stashNIDValid(io_in_bits_stashNIDValid),
    .io_in_bits_returnTxnID(io_in_bits_returnTxnID),
    .io_in_bits_opcode(io_in_bits_opcode),
    .io_in_bits_size(io_in_bits_size),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_ns(io_in_bits_ns),
    .io_in_bits_likelyshared(io_in_bits_likelyshared),
    .io_in_bits_allowRetry(io_in_bits_allowRetry),
    .io_in_bits_order(io_in_bits_order),
    .io_in_bits_pCrdType(io_in_bits_pCrdType),
    .io_in_bits_memAttr_allocate(io_in_bits_memAttr_allocate),
    .io_in_bits_memAttr_cacheable(io_in_bits_memAttr_cacheable),
    .io_in_bits_memAttr_device(io_in_bits_memAttr_device),
    .io_in_bits_memAttr_ewa(io_in_bits_memAttr_ewa),
    .io_in_bits_snpAttr(io_in_bits_snpAttr),
    .io_in_bits_lpIDWithPadding(io_in_bits_lpIDWithPadding),
    .io_in_bits_snoopMe(io_in_bits_snoopMe),
    .io_in_bits_expCompAck(io_in_bits_expCompAck),
    .io_in_bits_tagOp(io_in_bits_tagOp),
    .io_in_bits_traceTag(io_in_bits_traceTag),
    .io_in_bits_mpam_perfMonGroup(io_in_bits_mpam_perfMonGroup),
    .io_in_bits_mpam_partID(io_in_bits_mpam_partID),
    .io_in_bits_mpam_mpamNS(io_in_bits_mpam_mpamNS),
    .io_in_bits_rsvdc(io_in_bits_rsvdc),
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
    io_in_bits_returnNID = $urandom;
    io_in_bits_stashNIDValid = $urandom;
    io_in_bits_returnTxnID = $urandom;
    io_in_bits_opcode = $urandom;
    io_in_bits_size = $urandom;
    io_in_bits_addr = {$urandom, $urandom};
    io_in_bits_ns = $urandom;
    io_in_bits_likelyshared = $urandom;
    io_in_bits_allowRetry = $urandom;
    io_in_bits_order = $urandom;
    io_in_bits_pCrdType = $urandom;
    io_in_bits_memAttr_allocate = $urandom;
    io_in_bits_memAttr_cacheable = $urandom;
    io_in_bits_memAttr_device = $urandom;
    io_in_bits_memAttr_ewa = $urandom;
    io_in_bits_snpAttr = $urandom;
    io_in_bits_lpIDWithPadding = $urandom;
    io_in_bits_snoopMe = $urandom;
    io_in_bits_expCompAck = $urandom;
    io_in_bits_tagOp = $urandom;
    io_in_bits_traceTag = $urandom;
    io_in_bits_mpam_perfMonGroup = $urandom;
    io_in_bits_mpam_partID = $urandom;
    io_in_bits_mpam_mpamNS = $urandom;
    io_in_bits_rsvdc = $urandom;
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
    io_in_bits_returnNID = '0;
    io_in_bits_stashNIDValid = '0;
    io_in_bits_returnTxnID = '0;
    io_in_bits_opcode = '0;
    io_in_bits_size = '0;
    io_in_bits_addr = '0;
    io_in_bits_ns = '0;
    io_in_bits_likelyshared = '0;
    io_in_bits_allowRetry = '0;
    io_in_bits_order = '0;
    io_in_bits_pCrdType = '0;
    io_in_bits_memAttr_allocate = '0;
    io_in_bits_memAttr_cacheable = '0;
    io_in_bits_memAttr_device = '0;
    io_in_bits_memAttr_ewa = '0;
    io_in_bits_snpAttr = '0;
    io_in_bits_lpIDWithPadding = '0;
    io_in_bits_snoopMe = '0;
    io_in_bits_expCompAck = '0;
    io_in_bits_tagOp = '0;
    io_in_bits_traceTag = '0;
    io_in_bits_mpam_perfMonGroup = '0;
    io_in_bits_mpam_partID = '0;
    io_in_bits_mpam_mpamNS = '0;
    io_in_bits_rsvdc = '0;
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
    $display("Decoupled2LCredit checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
