// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// LCredit2Decoupled_8 双例化逐拍比对: golden LCredit2Decoupled_8 vs 可读重写 LCredit2Decoupled_8_xs。
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
  logic [161:0] io_in_flit;
  logic io_out_ready;
  logic [1:0] io_state_state;
  wire g_io_in_lcrdv;
  wire i_io_in_lcrdv;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_returnNID;
  wire [10:0] i_io_out_bits_returnNID;
  wire g_io_out_bits_stashNIDValid;
  wire i_io_out_bits_stashNIDValid;
  wire [11:0] g_io_out_bits_returnTxnID;
  wire [11:0] i_io_out_bits_returnTxnID;
  wire [6:0] g_io_out_bits_opcode;
  wire [6:0] i_io_out_bits_opcode;
  wire [2:0] g_io_out_bits_size;
  wire [2:0] i_io_out_bits_size;
  wire [47:0] g_io_out_bits_addr;
  wire [47:0] i_io_out_bits_addr;
  wire g_io_out_bits_ns;
  wire i_io_out_bits_ns;
  wire g_io_out_bits_likelyshared;
  wire i_io_out_bits_likelyshared;
  wire g_io_out_bits_allowRetry;
  wire i_io_out_bits_allowRetry;
  wire [1:0] g_io_out_bits_order;
  wire [1:0] i_io_out_bits_order;
  wire [3:0] g_io_out_bits_pCrdType;
  wire [3:0] i_io_out_bits_pCrdType;
  wire g_io_out_bits_memAttr_allocate;
  wire i_io_out_bits_memAttr_allocate;
  wire g_io_out_bits_memAttr_cacheable;
  wire i_io_out_bits_memAttr_cacheable;
  wire g_io_out_bits_memAttr_device;
  wire i_io_out_bits_memAttr_device;
  wire g_io_out_bits_memAttr_ewa;
  wire i_io_out_bits_memAttr_ewa;
  wire g_io_out_bits_snpAttr;
  wire i_io_out_bits_snpAttr;
  wire [7:0] g_io_out_bits_lpIDWithPadding;
  wire [7:0] i_io_out_bits_lpIDWithPadding;
  wire g_io_out_bits_snoopMe;
  wire i_io_out_bits_snoopMe;
  wire g_io_out_bits_expCompAck;
  wire i_io_out_bits_expCompAck;
  wire [1:0] g_io_out_bits_tagOp;
  wire [1:0] i_io_out_bits_tagOp;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire g_io_out_bits_mpam_perfMonGroup;
  wire i_io_out_bits_mpam_perfMonGroup;
  wire [8:0] g_io_out_bits_mpam_partID;
  wire [8:0] i_io_out_bits_mpam_partID;
  wire g_io_out_bits_mpam_mpamNS;
  wire i_io_out_bits_mpam_mpamNS;
  wire [3:0] g_io_out_bits_rsvdc;
  wire [3:0] i_io_out_bits_rsvdc;
  wire g_io_reclaimLCredit;
  wire i_io_reclaimLCredit;

  LCredit2Decoupled_8 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_flitv(io_in_flitv),
    .io_in_flit(io_in_flit),
    .io_in_lcrdv(g_io_in_lcrdv),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_returnNID(g_io_out_bits_returnNID),
    .io_out_bits_stashNIDValid(g_io_out_bits_stashNIDValid),
    .io_out_bits_returnTxnID(g_io_out_bits_returnTxnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_size(g_io_out_bits_size),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_ns(g_io_out_bits_ns),
    .io_out_bits_likelyshared(g_io_out_bits_likelyshared),
    .io_out_bits_allowRetry(g_io_out_bits_allowRetry),
    .io_out_bits_order(g_io_out_bits_order),
    .io_out_bits_pCrdType(g_io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate(g_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(g_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device(g_io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa(g_io_out_bits_memAttr_ewa),
    .io_out_bits_snpAttr(g_io_out_bits_snpAttr),
    .io_out_bits_lpIDWithPadding(g_io_out_bits_lpIDWithPadding),
    .io_out_bits_snoopMe(g_io_out_bits_snoopMe),
    .io_out_bits_expCompAck(g_io_out_bits_expCompAck),
    .io_out_bits_tagOp(g_io_out_bits_tagOp),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup(g_io_out_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID(g_io_out_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS(g_io_out_bits_mpam_mpamNS),
    .io_out_bits_rsvdc(g_io_out_bits_rsvdc),
    .io_state_state(io_state_state),
    .io_reclaimLCredit(g_io_reclaimLCredit)
  );
  LCredit2Decoupled_8_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_flitv(io_in_flitv),
    .io_in_flit(io_in_flit),
    .io_in_lcrdv(i_io_in_lcrdv),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_returnNID(i_io_out_bits_returnNID),
    .io_out_bits_stashNIDValid(i_io_out_bits_stashNIDValid),
    .io_out_bits_returnTxnID(i_io_out_bits_returnTxnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_size(i_io_out_bits_size),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_ns(i_io_out_bits_ns),
    .io_out_bits_likelyshared(i_io_out_bits_likelyshared),
    .io_out_bits_allowRetry(i_io_out_bits_allowRetry),
    .io_out_bits_order(i_io_out_bits_order),
    .io_out_bits_pCrdType(i_io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate(i_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(i_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device(i_io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa(i_io_out_bits_memAttr_ewa),
    .io_out_bits_snpAttr(i_io_out_bits_snpAttr),
    .io_out_bits_lpIDWithPadding(i_io_out_bits_lpIDWithPadding),
    .io_out_bits_snoopMe(i_io_out_bits_snoopMe),
    .io_out_bits_expCompAck(i_io_out_bits_expCompAck),
    .io_out_bits_tagOp(i_io_out_bits_tagOp),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup(i_io_out_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID(i_io_out_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS(i_io_out_bits_mpam_mpamNS),
    .io_out_bits_rsvdc(i_io_out_bits_rsvdc),
    .io_state_state(io_state_state),
    .io_reclaimLCredit(i_io_reclaimLCredit)
  );

  task automatic drive_random();
    io_in_flitv = $urandom;
    io_in_flit = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
    io_out_ready = ($urandom_range(0,3) != 0);
    io_state_state = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_in_lcrdv)
    `CHK(io_out_valid)
    `CHK(io_out_bits_qos)
    `CHK(io_out_bits_srcID)
    `CHK(io_out_bits_txnID)
    `CHK(io_out_bits_returnNID)
    `CHK(io_out_bits_stashNIDValid)
    `CHK(io_out_bits_returnTxnID)
    `CHK(io_out_bits_opcode)
    `CHK(io_out_bits_size)
    `CHK(io_out_bits_addr)
    `CHK(io_out_bits_ns)
    `CHK(io_out_bits_likelyshared)
    `CHK(io_out_bits_allowRetry)
    `CHK(io_out_bits_order)
    `CHK(io_out_bits_pCrdType)
    `CHK(io_out_bits_memAttr_allocate)
    `CHK(io_out_bits_memAttr_cacheable)
    `CHK(io_out_bits_memAttr_device)
    `CHK(io_out_bits_memAttr_ewa)
    `CHK(io_out_bits_snpAttr)
    `CHK(io_out_bits_lpIDWithPadding)
    `CHK(io_out_bits_snoopMe)
    `CHK(io_out_bits_expCompAck)
    `CHK(io_out_bits_tagOp)
    `CHK(io_out_bits_traceTag)
    `CHK(io_out_bits_mpam_perfMonGroup)
    `CHK(io_out_bits_mpam_partID)
    `CHK(io_out_bits_mpam_mpamNS)
    `CHK(io_out_bits_rsvdc)
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
    $display("LCredit2Decoupled_8 checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
