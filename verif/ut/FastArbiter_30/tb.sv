// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
// FastArbiter_30 双例化逐拍比对: golden FastArbiter_30 vs 可读 FastArbiter_30_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
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
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_0_valid;
  logic [3:0] io_in_0_bits_qos;
  logic [10:0] io_in_0_bits_tgtID;
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_returnNID;
  logic io_in_0_bits_stashNIDValid;
  logic [11:0] io_in_0_bits_returnTxnID;
  logic [6:0] io_in_0_bits_opcode;
  logic [2:0] io_in_0_bits_size;
  logic [47:0] io_in_0_bits_addr;
  logic io_in_0_bits_ns;
  logic io_in_0_bits_likelyshared;
  logic io_in_0_bits_allowRetry;
  logic [1:0] io_in_0_bits_order;
  logic [3:0] io_in_0_bits_pCrdType;
  logic io_in_0_bits_memAttr_allocate;
  logic io_in_0_bits_memAttr_cacheable;
  logic io_in_0_bits_memAttr_device;
  logic io_in_0_bits_memAttr_ewa;
  logic io_in_0_bits_snpAttr;
  logic [7:0] io_in_0_bits_lpIDWithPadding;
  logic io_in_0_bits_snoopMe;
  logic io_in_0_bits_expCompAck;
  logic [1:0] io_in_0_bits_tagOp;
  logic io_in_0_bits_traceTag;
  logic io_in_0_bits_mpam_perfMonGroup;
  logic [8:0] io_in_0_bits_mpam_partID;
  logic io_in_0_bits_mpam_mpamNS;
  logic [3:0] io_in_0_bits_rsvdc;
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

  FastArbiter_30 u_g (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_returnNID(io_in_0_bits_returnNID),
    .io_in_0_bits_stashNIDValid(io_in_0_bits_stashNIDValid),
    .io_in_0_bits_returnTxnID(io_in_0_bits_returnTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_ns(io_in_0_bits_ns),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_order(io_in_0_bits_order),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable(io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_device(io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_snpAttr(io_in_0_bits_snpAttr),
    .io_in_0_bits_lpIDWithPadding(io_in_0_bits_lpIDWithPadding),
    .io_in_0_bits_snoopMe(io_in_0_bits_snoopMe),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_mpam_perfMonGroup(io_in_0_bits_mpam_perfMonGroup),
    .io_in_0_bits_mpam_partID(io_in_0_bits_mpam_partID),
    .io_in_0_bits_mpam_mpamNS(io_in_0_bits_mpam_mpamNS),
    .io_in_0_bits_rsvdc(io_in_0_bits_rsvdc),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
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
    .io_out_bits_rsvdc(g_io_out_bits_rsvdc)
  );

  FastArbiter_30_xs u_i (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_returnNID(io_in_0_bits_returnNID),
    .io_in_0_bits_stashNIDValid(io_in_0_bits_stashNIDValid),
    .io_in_0_bits_returnTxnID(io_in_0_bits_returnTxnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_ns(io_in_0_bits_ns),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_order(io_in_0_bits_order),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable(io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_device(io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_snpAttr(io_in_0_bits_snpAttr),
    .io_in_0_bits_lpIDWithPadding(io_in_0_bits_lpIDWithPadding),
    .io_in_0_bits_snoopMe(io_in_0_bits_snoopMe),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_mpam_perfMonGroup(io_in_0_bits_mpam_perfMonGroup),
    .io_in_0_bits_mpam_partID(io_in_0_bits_mpam_partID),
    .io_in_0_bits_mpam_mpamNS(io_in_0_bits_mpam_mpamNS),
    .io_in_0_bits_rsvdc(io_in_0_bits_rsvdc),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
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
    .io_out_bits_rsvdc(i_io_out_bits_rsvdc)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_qos <= 4'({$urandom});
    io_in_0_bits_tgtID <= 11'({$urandom});
    io_in_0_bits_srcID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_returnNID <= 11'({$urandom});
    io_in_0_bits_stashNIDValid <= $urandom_range(0, 1);
    io_in_0_bits_returnTxnID <= 12'({$urandom});
    io_in_0_bits_opcode <= 7'({$urandom});
    io_in_0_bits_size <= 3'({$urandom});
    io_in_0_bits_addr <= 48'({$urandom, $urandom});
    io_in_0_bits_ns <= $urandom_range(0, 1);
    io_in_0_bits_likelyshared <= $urandom_range(0, 1);
    io_in_0_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_bits_order <= 2'({$urandom});
    io_in_0_bits_pCrdType <= 4'({$urandom});
    io_in_0_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_cacheable <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_device <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_0_bits_snpAttr <= $urandom_range(0, 1);
    io_in_0_bits_lpIDWithPadding <= 8'({$urandom});
    io_in_0_bits_snoopMe <= $urandom_range(0, 1);
    io_in_0_bits_expCompAck <= $urandom_range(0, 1);
    io_in_0_bits_tagOp <= 2'({$urandom});
    io_in_0_bits_traceTag <= $urandom_range(0, 1);
    io_in_0_bits_mpam_perfMonGroup <= $urandom_range(0, 1);
    io_in_0_bits_mpam_partID <= 9'({$urandom});
    io_in_0_bits_mpam_mpamNS <= $urandom_range(0, 1);
    io_in_0_bits_rsvdc <= 4'({$urandom});
  endtask

  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_qos)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_srcID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_returnNID)
    `CHECK(io_out_bits_stashNIDValid)
    `CHECK(io_out_bits_returnTxnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_size)
    `CHECK(io_out_bits_addr)
    `CHECK(io_out_bits_ns)
    `CHECK(io_out_bits_likelyshared)
    `CHECK(io_out_bits_allowRetry)
    `CHECK(io_out_bits_order)
    `CHECK(io_out_bits_pCrdType)
    `CHECK(io_out_bits_memAttr_allocate)
    `CHECK(io_out_bits_memAttr_cacheable)
    `CHECK(io_out_bits_memAttr_device)
    `CHECK(io_out_bits_memAttr_ewa)
    `CHECK(io_out_bits_snpAttr)
    `CHECK(io_out_bits_lpIDWithPadding)
    `CHECK(io_out_bits_snoopMe)
    `CHECK(io_out_bits_expCompAck)
    `CHECK(io_out_bits_tagOp)
    `CHECK(io_out_bits_traceTag)
    `CHECK(io_out_bits_mpam_perfMonGroup)
    `CHECK(io_out_bits_mpam_partID)
    `CHECK(io_out_bits_mpam_mpamNS)
    `CHECK(io_out_bits_rsvdc)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_qos = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_returnNID = '0;
    io_in_0_bits_stashNIDValid = '0;
    io_in_0_bits_returnTxnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_size = '0;
    io_in_0_bits_addr = '0;
    io_in_0_bits_ns = '0;
    io_in_0_bits_likelyshared = '0;
    io_in_0_bits_allowRetry = '0;
    io_in_0_bits_order = '0;
    io_in_0_bits_pCrdType = '0;
    io_in_0_bits_memAttr_allocate = '0;
    io_in_0_bits_memAttr_cacheable = '0;
    io_in_0_bits_memAttr_device = '0;
    io_in_0_bits_memAttr_ewa = '0;
    io_in_0_bits_snpAttr = '0;
    io_in_0_bits_lpIDWithPadding = '0;
    io_in_0_bits_snoopMe = '0;
    io_in_0_bits_expCompAck = '0;
    io_in_0_bits_tagOp = '0;
    io_in_0_bits_traceTag = '0;
    io_in_0_bits_mpam_perfMonGroup = '0;
    io_in_0_bits_mpam_partID = '0;
    io_in_0_bits_mpam_mpamNS = '0;
    io_in_0_bits_rsvdc = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_30 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
