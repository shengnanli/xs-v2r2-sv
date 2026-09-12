// 自动生成 scripts/gen_chi_channel.py —— 勿手改
// TXREQ 双例化逐拍比对: golden TXREQ vs 可读重写 TXREQ_xs。
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
  logic io_pipeReq_valid;
  logic [10:0] io_pipeReq_bits_tgtID;
  logic [10:0] io_pipeReq_bits_srcID;
  logic [11:0] io_pipeReq_bits_txnID;
  logic [6:0] io_pipeReq_bits_opcode;
  logic [47:0] io_pipeReq_bits_addr;
  logic io_pipeReq_bits_likelyshared;
  logic io_pipeReq_bits_allowRetry;
  logic [3:0] io_pipeReq_bits_pCrdType;
  logic io_pipeReq_bits_memAttr_allocate;
  logic io_pipeReq_bits_memAttr_cacheable;
  logic io_pipeReq_bits_memAttr_device;
  logic io_pipeReq_bits_memAttr_ewa;
  logic io_pipeReq_bits_expCompAck;
  logic io_mshrReq_valid;
  logic [3:0] io_mshrReq_bits_qos;
  logic [10:0] io_mshrReq_bits_tgtID;
  logic [11:0] io_mshrReq_bits_txnID;
  logic [6:0] io_mshrReq_bits_opcode;
  logic [2:0] io_mshrReq_bits_size;
  logic [47:0] io_mshrReq_bits_addr;
  logic io_mshrReq_bits_likelyshared;
  logic io_mshrReq_bits_allowRetry;
  logic [3:0] io_mshrReq_bits_pCrdType;
  logic io_mshrReq_bits_memAttr_allocate;
  logic io_mshrReq_bits_memAttr_cacheable;
  logic io_mshrReq_bits_memAttr_ewa;
  logic io_mshrReq_bits_snpAttr;
  logic io_mshrReq_bits_expCompAck;
  logic io_out_ready;
  logic io_pipeStatusVec_1_valid;
  logic [2:0] io_pipeStatusVec_1_bits_txChannel;
  logic io_pipeStatusVec_1_bits_mshrTask;
  logic io_pipeStatusVec_2_valid;
  logic [2:0] io_pipeStatusVec_2_bits_txChannel;
  logic io_pipeStatusVec_2_bits_mshrTask;
  logic io_pipeStatusVec_3_valid;
  logic [2:0] io_pipeStatusVec_3_bits_txChannel;
  logic io_pipeStatusVec_3_bits_mshrTask;
  logic io_pipeStatusVec_4_valid;
  logic [2:0] io_pipeStatusVec_4_bits_txChannel;
  logic io_pipeStatusVec_4_bits_mshrTask;
  logic [1:0] io_sliceId;
  wire g_io_mshrReq_ready;
  wire i_io_mshrReq_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
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
  wire g_io_toReqArb_blockMSHRReqEntrance;
  wire i_io_toReqArb_blockMSHRReqEntrance;

  TXREQ u_g (
    .clock(clock),
    .reset(reset),
    .io_pipeReq_valid(io_pipeReq_valid),
    .io_pipeReq_bits_tgtID(io_pipeReq_bits_tgtID),
    .io_pipeReq_bits_srcID(io_pipeReq_bits_srcID),
    .io_pipeReq_bits_txnID(io_pipeReq_bits_txnID),
    .io_pipeReq_bits_opcode(io_pipeReq_bits_opcode),
    .io_pipeReq_bits_addr(io_pipeReq_bits_addr),
    .io_pipeReq_bits_likelyshared(io_pipeReq_bits_likelyshared),
    .io_pipeReq_bits_allowRetry(io_pipeReq_bits_allowRetry),
    .io_pipeReq_bits_pCrdType(io_pipeReq_bits_pCrdType),
    .io_pipeReq_bits_memAttr_allocate(io_pipeReq_bits_memAttr_allocate),
    .io_pipeReq_bits_memAttr_cacheable(io_pipeReq_bits_memAttr_cacheable),
    .io_pipeReq_bits_memAttr_device(io_pipeReq_bits_memAttr_device),
    .io_pipeReq_bits_memAttr_ewa(io_pipeReq_bits_memAttr_ewa),
    .io_pipeReq_bits_expCompAck(io_pipeReq_bits_expCompAck),
    .io_mshrReq_ready(g_io_mshrReq_ready),
    .io_mshrReq_valid(io_mshrReq_valid),
    .io_mshrReq_bits_qos(io_mshrReq_bits_qos),
    .io_mshrReq_bits_tgtID(io_mshrReq_bits_tgtID),
    .io_mshrReq_bits_txnID(io_mshrReq_bits_txnID),
    .io_mshrReq_bits_opcode(io_mshrReq_bits_opcode),
    .io_mshrReq_bits_size(io_mshrReq_bits_size),
    .io_mshrReq_bits_addr(io_mshrReq_bits_addr),
    .io_mshrReq_bits_likelyshared(io_mshrReq_bits_likelyshared),
    .io_mshrReq_bits_allowRetry(io_mshrReq_bits_allowRetry),
    .io_mshrReq_bits_pCrdType(io_mshrReq_bits_pCrdType),
    .io_mshrReq_bits_memAttr_allocate(io_mshrReq_bits_memAttr_allocate),
    .io_mshrReq_bits_memAttr_cacheable(io_mshrReq_bits_memAttr_cacheable),
    .io_mshrReq_bits_memAttr_ewa(io_mshrReq_bits_memAttr_ewa),
    .io_mshrReq_bits_snpAttr(io_mshrReq_bits_snpAttr),
    .io_mshrReq_bits_expCompAck(io_mshrReq_bits_expCompAck),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_returnNID(g_io_out_bits_returnNID),
    .io_out_bits_stashNIDValid(g_io_out_bits_stashNIDValid),
    .io_out_bits_returnTxnID(g_io_out_bits_returnTxnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
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
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(g_io_toReqArb_blockMSHRReqEntrance),
    .io_sliceId(io_sliceId)
  );
  TXREQ_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_pipeReq_valid(io_pipeReq_valid),
    .io_pipeReq_bits_tgtID(io_pipeReq_bits_tgtID),
    .io_pipeReq_bits_srcID(io_pipeReq_bits_srcID),
    .io_pipeReq_bits_txnID(io_pipeReq_bits_txnID),
    .io_pipeReq_bits_opcode(io_pipeReq_bits_opcode),
    .io_pipeReq_bits_addr(io_pipeReq_bits_addr),
    .io_pipeReq_bits_likelyshared(io_pipeReq_bits_likelyshared),
    .io_pipeReq_bits_allowRetry(io_pipeReq_bits_allowRetry),
    .io_pipeReq_bits_pCrdType(io_pipeReq_bits_pCrdType),
    .io_pipeReq_bits_memAttr_allocate(io_pipeReq_bits_memAttr_allocate),
    .io_pipeReq_bits_memAttr_cacheable(io_pipeReq_bits_memAttr_cacheable),
    .io_pipeReq_bits_memAttr_device(io_pipeReq_bits_memAttr_device),
    .io_pipeReq_bits_memAttr_ewa(io_pipeReq_bits_memAttr_ewa),
    .io_pipeReq_bits_expCompAck(io_pipeReq_bits_expCompAck),
    .io_mshrReq_ready(i_io_mshrReq_ready),
    .io_mshrReq_valid(io_mshrReq_valid),
    .io_mshrReq_bits_qos(io_mshrReq_bits_qos),
    .io_mshrReq_bits_tgtID(io_mshrReq_bits_tgtID),
    .io_mshrReq_bits_txnID(io_mshrReq_bits_txnID),
    .io_mshrReq_bits_opcode(io_mshrReq_bits_opcode),
    .io_mshrReq_bits_size(io_mshrReq_bits_size),
    .io_mshrReq_bits_addr(io_mshrReq_bits_addr),
    .io_mshrReq_bits_likelyshared(io_mshrReq_bits_likelyshared),
    .io_mshrReq_bits_allowRetry(io_mshrReq_bits_allowRetry),
    .io_mshrReq_bits_pCrdType(io_mshrReq_bits_pCrdType),
    .io_mshrReq_bits_memAttr_allocate(io_mshrReq_bits_memAttr_allocate),
    .io_mshrReq_bits_memAttr_cacheable(io_mshrReq_bits_memAttr_cacheable),
    .io_mshrReq_bits_memAttr_ewa(io_mshrReq_bits_memAttr_ewa),
    .io_mshrReq_bits_snpAttr(io_mshrReq_bits_snpAttr),
    .io_mshrReq_bits_expCompAck(io_mshrReq_bits_expCompAck),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_returnNID(i_io_out_bits_returnNID),
    .io_out_bits_stashNIDValid(i_io_out_bits_stashNIDValid),
    .io_out_bits_returnTxnID(i_io_out_bits_returnTxnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
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
    .io_pipeStatusVec_1_valid(io_pipeStatusVec_1_valid),
    .io_pipeStatusVec_1_bits_txChannel(io_pipeStatusVec_1_bits_txChannel),
    .io_pipeStatusVec_1_bits_mshrTask(io_pipeStatusVec_1_bits_mshrTask),
    .io_pipeStatusVec_2_valid(io_pipeStatusVec_2_valid),
    .io_pipeStatusVec_2_bits_txChannel(io_pipeStatusVec_2_bits_txChannel),
    .io_pipeStatusVec_2_bits_mshrTask(io_pipeStatusVec_2_bits_mshrTask),
    .io_pipeStatusVec_3_valid(io_pipeStatusVec_3_valid),
    .io_pipeStatusVec_3_bits_txChannel(io_pipeStatusVec_3_bits_txChannel),
    .io_pipeStatusVec_3_bits_mshrTask(io_pipeStatusVec_3_bits_mshrTask),
    .io_pipeStatusVec_4_valid(io_pipeStatusVec_4_valid),
    .io_pipeStatusVec_4_bits_txChannel(io_pipeStatusVec_4_bits_txChannel),
    .io_pipeStatusVec_4_bits_mshrTask(io_pipeStatusVec_4_bits_mshrTask),
    .io_toReqArb_blockMSHRReqEntrance(i_io_toReqArb_blockMSHRReqEntrance),
    .io_sliceId(io_sliceId)
  );

  task automatic drive_random();
    io_pipeReq_valid = ($urandom_range(0,1) == 0);
    io_pipeReq_bits_tgtID = $urandom;
    io_pipeReq_bits_srcID = $urandom;
    io_pipeReq_bits_txnID = $urandom;
    io_pipeReq_bits_opcode = $urandom;
    io_pipeReq_bits_addr = {$urandom, $urandom};
    io_pipeReq_bits_likelyshared = $urandom;
    io_pipeReq_bits_allowRetry = $urandom;
    io_pipeReq_bits_pCrdType = $urandom;
    io_pipeReq_bits_memAttr_allocate = $urandom;
    io_pipeReq_bits_memAttr_cacheable = $urandom;
    io_pipeReq_bits_memAttr_device = $urandom;
    io_pipeReq_bits_memAttr_ewa = $urandom;
    io_pipeReq_bits_expCompAck = $urandom;
    io_mshrReq_valid = ($urandom_range(0,1) == 0);
    io_mshrReq_bits_qos = $urandom;
    io_mshrReq_bits_tgtID = $urandom;
    io_mshrReq_bits_txnID = $urandom;
    io_mshrReq_bits_opcode = $urandom;
    io_mshrReq_bits_size = $urandom;
    io_mshrReq_bits_addr = {$urandom, $urandom};
    io_mshrReq_bits_likelyshared = $urandom;
    io_mshrReq_bits_allowRetry = $urandom;
    io_mshrReq_bits_pCrdType = $urandom;
    io_mshrReq_bits_memAttr_allocate = $urandom;
    io_mshrReq_bits_memAttr_cacheable = $urandom;
    io_mshrReq_bits_memAttr_ewa = $urandom;
    io_mshrReq_bits_snpAttr = $urandom;
    io_mshrReq_bits_expCompAck = $urandom;
    io_out_ready = ($urandom_range(0,3) != 0);
    io_pipeStatusVec_1_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_1_bits_txChannel = $urandom;
    io_pipeStatusVec_1_bits_mshrTask = $urandom;
    io_pipeStatusVec_2_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_2_bits_txChannel = $urandom;
    io_pipeStatusVec_2_bits_mshrTask = $urandom;
    io_pipeStatusVec_3_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_3_bits_txChannel = $urandom;
    io_pipeStatusVec_3_bits_mshrTask = $urandom;
    io_pipeStatusVec_4_valid = ($urandom_range(0,1) == 0);
    io_pipeStatusVec_4_bits_txChannel = $urandom;
    io_pipeStatusVec_4_bits_mshrTask = $urandom;
    io_sliceId = $urandom;
  endtask

  task automatic check_outputs();
    `CHK(io_mshrReq_ready)
    `CHK(io_out_valid)
    `CHK(io_out_bits_qos)
    `CHK(io_out_bits_txnID)
    `CHK(io_out_bits_returnNID)
    `CHK(io_out_bits_stashNIDValid)
    `CHK(io_out_bits_returnTxnID)
    `CHK(io_out_bits_opcode)
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
    `CHK(io_toReqArb_blockMSHRReqEntrance)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_pipeReq_valid = '0;
    io_pipeReq_bits_tgtID = '0;
    io_pipeReq_bits_srcID = '0;
    io_pipeReq_bits_txnID = '0;
    io_pipeReq_bits_opcode = '0;
    io_pipeReq_bits_addr = '0;
    io_pipeReq_bits_likelyshared = '0;
    io_pipeReq_bits_allowRetry = '0;
    io_pipeReq_bits_pCrdType = '0;
    io_pipeReq_bits_memAttr_allocate = '0;
    io_pipeReq_bits_memAttr_cacheable = '0;
    io_pipeReq_bits_memAttr_device = '0;
    io_pipeReq_bits_memAttr_ewa = '0;
    io_pipeReq_bits_expCompAck = '0;
    io_mshrReq_valid = '0;
    io_mshrReq_bits_qos = '0;
    io_mshrReq_bits_tgtID = '0;
    io_mshrReq_bits_txnID = '0;
    io_mshrReq_bits_opcode = '0;
    io_mshrReq_bits_size = '0;
    io_mshrReq_bits_addr = '0;
    io_mshrReq_bits_likelyshared = '0;
    io_mshrReq_bits_allowRetry = '0;
    io_mshrReq_bits_pCrdType = '0;
    io_mshrReq_bits_memAttr_allocate = '0;
    io_mshrReq_bits_memAttr_cacheable = '0;
    io_mshrReq_bits_memAttr_ewa = '0;
    io_mshrReq_bits_snpAttr = '0;
    io_mshrReq_bits_expCompAck = '0;
    io_out_ready = '0;
    io_pipeStatusVec_1_valid = '0;
    io_pipeStatusVec_1_bits_txChannel = '0;
    io_pipeStatusVec_1_bits_mshrTask = '0;
    io_pipeStatusVec_2_valid = '0;
    io_pipeStatusVec_2_bits_txChannel = '0;
    io_pipeStatusVec_2_bits_mshrTask = '0;
    io_pipeStatusVec_3_valid = '0;
    io_pipeStatusVec_3_bits_txChannel = '0;
    io_pipeStatusVec_3_bits_mshrTask = '0;
    io_pipeStatusVec_4_valid = '0;
    io_pipeStatusVec_4_bits_txChannel = '0;
    io_pipeStatusVec_4_bits_mshrTask = '0;
    io_sliceId = '0;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("TXREQ checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin $display("TEST PASSED"); $finish; end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHK
