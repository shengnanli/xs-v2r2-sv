// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// RXREQ 双例化逐拍比对: golden RXREQ vs 可读重写 RXREQ_xs。
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
  logic io_req_valid;
  logic [10:0] io_req_bits_tgtID;
  logic [10:0] io_req_bits_srcID;
  logic [11:0] io_req_bits_txnID;
  logic [6:0] io_req_bits_opcode;
  logic [2:0] io_req_bits_size;
  logic [47:0] io_req_bits_addr;
  logic io_req_bits_allowRetry;
  logic [1:0] io_req_bits_order;
  logic [3:0] io_req_bits_pCrdType;
  logic io_req_bits_memAttr_allocate;
  logic io_req_bits_memAttr_cacheable;
  logic io_req_bits_memAttr_device;
  logic io_req_bits_memAttr_ewa;
  logic io_req_bits_snpAttr;
  logic io_req_bits_expCompAck;
  logic io_task_ready;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_task_valid;
  wire i_io_task_valid;
  wire [11:0] g_io_task_bits_set;
  wire [11:0] i_io_task_bits_set;
  wire [1:0] g_io_task_bits_bank;
  wire [1:0] i_io_task_bits_bank;
  wire [27:0] g_io_task_bits_tag;
  wire [27:0] i_io_task_bits_tag;
  wire [5:0] g_io_task_bits_off;
  wire [5:0] i_io_task_bits_off;
  wire [2:0] g_io_task_bits_size;
  wire [2:0] i_io_task_bits_size;
  wire [11:0] g_io_task_bits_reqID;
  wire [11:0] i_io_task_bits_reqID;
  wire [10:0] g_io_task_bits_tgtID;
  wire [10:0] i_io_task_bits_tgtID;
  wire [10:0] g_io_task_bits_srcID;
  wire [10:0] i_io_task_bits_srcID;
  wire [11:0] g_io_task_bits_txnID;
  wire [11:0] i_io_task_bits_txnID;
  wire [6:0] g_io_task_bits_chiOpcode;
  wire [6:0] i_io_task_bits_chiOpcode;
  wire [3:0] g_io_task_bits_pCrdType;
  wire [3:0] i_io_task_bits_pCrdType;
  wire g_io_task_bits_expCompAck;
  wire i_io_task_bits_expCompAck;
  wire g_io_task_bits_allowRetry;
  wire i_io_task_bits_allowRetry;
  wire [1:0] g_io_task_bits_order;
  wire [1:0] i_io_task_bits_order;
  wire g_io_task_bits_memAttr_allocate;
  wire i_io_task_bits_memAttr_allocate;
  wire g_io_task_bits_memAttr_cacheable;
  wire i_io_task_bits_memAttr_cacheable;
  wire g_io_task_bits_memAttr_device;
  wire i_io_task_bits_memAttr_device;
  wire g_io_task_bits_memAttr_ewa;
  wire i_io_task_bits_memAttr_ewa;
  wire g_io_task_bits_snpAttr;
  wire i_io_task_bits_snpAttr;

  RXREQ u_g (
    .clock(clock),
    .reset(reset),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_tgtID(io_req_bits_tgtID),
    .io_req_bits_srcID(io_req_bits_srcID),
    .io_req_bits_txnID(io_req_bits_txnID),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_size(io_req_bits_size),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_allowRetry(io_req_bits_allowRetry),
    .io_req_bits_order(io_req_bits_order),
    .io_req_bits_pCrdType(io_req_bits_pCrdType),
    .io_req_bits_memAttr_allocate(io_req_bits_memAttr_allocate),
    .io_req_bits_memAttr_cacheable(io_req_bits_memAttr_cacheable),
    .io_req_bits_memAttr_device(io_req_bits_memAttr_device),
    .io_req_bits_memAttr_ewa(io_req_bits_memAttr_ewa),
    .io_req_bits_snpAttr(io_req_bits_snpAttr),
    .io_req_bits_expCompAck(io_req_bits_expCompAck),
    .io_task_ready(io_task_ready),
    .io_task_valid(g_io_task_valid),
    .io_task_bits_set(g_io_task_bits_set),
    .io_task_bits_bank(g_io_task_bits_bank),
    .io_task_bits_tag(g_io_task_bits_tag),
    .io_task_bits_off(g_io_task_bits_off),
    .io_task_bits_size(g_io_task_bits_size),
    .io_task_bits_reqID(g_io_task_bits_reqID),
    .io_task_bits_tgtID(g_io_task_bits_tgtID),
    .io_task_bits_srcID(g_io_task_bits_srcID),
    .io_task_bits_txnID(g_io_task_bits_txnID),
    .io_task_bits_chiOpcode(g_io_task_bits_chiOpcode),
    .io_task_bits_pCrdType(g_io_task_bits_pCrdType),
    .io_task_bits_expCompAck(g_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(g_io_task_bits_allowRetry),
    .io_task_bits_order(g_io_task_bits_order),
    .io_task_bits_memAttr_allocate(g_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(g_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(g_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(g_io_task_bits_memAttr_ewa),
    .io_task_bits_snpAttr(g_io_task_bits_snpAttr)
  );
  RXREQ_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_tgtID(io_req_bits_tgtID),
    .io_req_bits_srcID(io_req_bits_srcID),
    .io_req_bits_txnID(io_req_bits_txnID),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_size(io_req_bits_size),
    .io_req_bits_addr(io_req_bits_addr),
    .io_req_bits_allowRetry(io_req_bits_allowRetry),
    .io_req_bits_order(io_req_bits_order),
    .io_req_bits_pCrdType(io_req_bits_pCrdType),
    .io_req_bits_memAttr_allocate(io_req_bits_memAttr_allocate),
    .io_req_bits_memAttr_cacheable(io_req_bits_memAttr_cacheable),
    .io_req_bits_memAttr_device(io_req_bits_memAttr_device),
    .io_req_bits_memAttr_ewa(io_req_bits_memAttr_ewa),
    .io_req_bits_snpAttr(io_req_bits_snpAttr),
    .io_req_bits_expCompAck(io_req_bits_expCompAck),
    .io_task_ready(io_task_ready),
    .io_task_valid(i_io_task_valid),
    .io_task_bits_set(i_io_task_bits_set),
    .io_task_bits_bank(i_io_task_bits_bank),
    .io_task_bits_tag(i_io_task_bits_tag),
    .io_task_bits_off(i_io_task_bits_off),
    .io_task_bits_size(i_io_task_bits_size),
    .io_task_bits_reqID(i_io_task_bits_reqID),
    .io_task_bits_tgtID(i_io_task_bits_tgtID),
    .io_task_bits_srcID(i_io_task_bits_srcID),
    .io_task_bits_txnID(i_io_task_bits_txnID),
    .io_task_bits_chiOpcode(i_io_task_bits_chiOpcode),
    .io_task_bits_pCrdType(i_io_task_bits_pCrdType),
    .io_task_bits_expCompAck(i_io_task_bits_expCompAck),
    .io_task_bits_allowRetry(i_io_task_bits_allowRetry),
    .io_task_bits_order(i_io_task_bits_order),
    .io_task_bits_memAttr_allocate(i_io_task_bits_memAttr_allocate),
    .io_task_bits_memAttr_cacheable(i_io_task_bits_memAttr_cacheable),
    .io_task_bits_memAttr_device(i_io_task_bits_memAttr_device),
    .io_task_bits_memAttr_ewa(i_io_task_bits_memAttr_ewa),
    .io_task_bits_snpAttr(i_io_task_bits_snpAttr)
  );

  task automatic drive_random();
    io_req_valid = ($urandom_range(0,1) == 0);
    io_req_bits_tgtID = $urandom;
    io_req_bits_srcID = $urandom;
    io_req_bits_txnID = $urandom;
    io_req_bits_opcode = $urandom;
    io_req_bits_size = $urandom;
    io_req_bits_addr = {$urandom, $urandom};
    io_req_bits_allowRetry = $urandom;
    io_req_bits_order = $urandom;
    io_req_bits_pCrdType = $urandom;
    io_req_bits_memAttr_allocate = $urandom;
    io_req_bits_memAttr_cacheable = $urandom;
    io_req_bits_memAttr_device = $urandom;
    io_req_bits_memAttr_ewa = $urandom;
    io_req_bits_snpAttr = $urandom;
    io_req_bits_expCompAck = $urandom;
    io_task_ready = ($urandom_range(0,3) != 0);
  endtask

  task automatic check_outputs();
    `CHK(io_req_ready)
    `CHK(io_task_valid)
    `CHK(io_task_bits_set)
    `CHK(io_task_bits_bank)
    `CHK(io_task_bits_tag)
    `CHK(io_task_bits_off)
    `CHK(io_task_bits_size)
    `CHK(io_task_bits_reqID)
    `CHK(io_task_bits_tgtID)
    `CHK(io_task_bits_srcID)
    `CHK(io_task_bits_txnID)
    `CHK(io_task_bits_chiOpcode)
    `CHK(io_task_bits_pCrdType)
    `CHK(io_task_bits_expCompAck)
    `CHK(io_task_bits_allowRetry)
    `CHK(io_task_bits_order)
    `CHK(io_task_bits_memAttr_allocate)
    `CHK(io_task_bits_memAttr_cacheable)
    `CHK(io_task_bits_memAttr_device)
    `CHK(io_task_bits_memAttr_ewa)
    `CHK(io_task_bits_snpAttr)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_req_valid = '0;
    io_req_bits_tgtID = '0;
    io_req_bits_srcID = '0;
    io_req_bits_txnID = '0;
    io_req_bits_opcode = '0;
    io_req_bits_size = '0;
    io_req_bits_addr = '0;
    io_req_bits_allowRetry = '0;
    io_req_bits_order = '0;
    io_req_bits_pCrdType = '0;
    io_req_bits_memAttr_allocate = '0;
    io_req_bits_memAttr_cacheable = '0;
    io_req_bits_memAttr_device = '0;
    io_req_bits_memAttr_ewa = '0;
    io_req_bits_snpAttr = '0;
    io_req_bits_expCompAck = '0;
    io_task_ready = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("RXREQ checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
