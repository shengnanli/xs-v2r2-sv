// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：Queue16_CHIREQ Queue16_CHIRSP Queue4_CHISNP Queue2_PCrdGranted Queue78_PCrdGranted Queue40_L2TlbMQBundle
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= Queue16_CHIREQ =======================
  logic Queue16_CHIREQ__io_enq_valid;
  logic [3:0] Queue16_CHIREQ__io_enq_bits_qos;
  logic [10:0] Queue16_CHIREQ__io_enq_bits_tgtID;
  logic [10:0] Queue16_CHIREQ__io_enq_bits_srcID;
  logic [11:0] Queue16_CHIREQ__io_enq_bits_txnID;
  logic [6:0] Queue16_CHIREQ__io_enq_bits_opcode;
  logic [2:0] Queue16_CHIREQ__io_enq_bits_size;
  logic [47:0] Queue16_CHIREQ__io_enq_bits_addr;
  logic Queue16_CHIREQ__io_enq_bits_likelyshared;
  logic Queue16_CHIREQ__io_enq_bits_allowRetry;
  logic [3:0] Queue16_CHIREQ__io_enq_bits_pCrdType;
  logic Queue16_CHIREQ__io_enq_bits_memAttr_allocate;
  logic Queue16_CHIREQ__io_enq_bits_memAttr_cacheable;
  logic Queue16_CHIREQ__io_enq_bits_memAttr_device;
  logic Queue16_CHIREQ__io_enq_bits_memAttr_ewa;
  logic Queue16_CHIREQ__io_enq_bits_snpAttr;
  logic Queue16_CHIREQ__io_enq_bits_expCompAck;
  logic Queue16_CHIREQ__io_deq_ready;
  wire  g_Queue16_CHIREQ__io_deq_valid;
  wire  i_Queue16_CHIREQ__io_deq_valid;
  logic p_Queue16_CHIREQ__io_deq_valid;
  bit   t_Queue16_CHIREQ__io_deq_valid;
  wire  [3:0] g_Queue16_CHIREQ__io_deq_bits_qos;
  wire  [3:0] i_Queue16_CHIREQ__io_deq_bits_qos;
  logic [3:0] p_Queue16_CHIREQ__io_deq_bits_qos;
  bit   t_Queue16_CHIREQ__io_deq_bits_qos;
  wire  [11:0] g_Queue16_CHIREQ__io_deq_bits_txnID;
  wire  [11:0] i_Queue16_CHIREQ__io_deq_bits_txnID;
  logic [11:0] p_Queue16_CHIREQ__io_deq_bits_txnID;
  bit   t_Queue16_CHIREQ__io_deq_bits_txnID;
  wire  [10:0] g_Queue16_CHIREQ__io_deq_bits_returnNID;
  wire  [10:0] i_Queue16_CHIREQ__io_deq_bits_returnNID;
  logic [10:0] p_Queue16_CHIREQ__io_deq_bits_returnNID;
  bit   t_Queue16_CHIREQ__io_deq_bits_returnNID;
  wire  g_Queue16_CHIREQ__io_deq_bits_stashNIDValid;
  wire  i_Queue16_CHIREQ__io_deq_bits_stashNIDValid;
  logic p_Queue16_CHIREQ__io_deq_bits_stashNIDValid;
  bit   t_Queue16_CHIREQ__io_deq_bits_stashNIDValid;
  wire  [11:0] g_Queue16_CHIREQ__io_deq_bits_returnTxnID;
  wire  [11:0] i_Queue16_CHIREQ__io_deq_bits_returnTxnID;
  logic [11:0] p_Queue16_CHIREQ__io_deq_bits_returnTxnID;
  bit   t_Queue16_CHIREQ__io_deq_bits_returnTxnID;
  wire  [6:0] g_Queue16_CHIREQ__io_deq_bits_opcode;
  wire  [6:0] i_Queue16_CHIREQ__io_deq_bits_opcode;
  logic [6:0] p_Queue16_CHIREQ__io_deq_bits_opcode;
  bit   t_Queue16_CHIREQ__io_deq_bits_opcode;
  wire  [47:0] g_Queue16_CHIREQ__io_deq_bits_addr;
  wire  [47:0] i_Queue16_CHIREQ__io_deq_bits_addr;
  logic [47:0] p_Queue16_CHIREQ__io_deq_bits_addr;
  bit   t_Queue16_CHIREQ__io_deq_bits_addr;
  wire  g_Queue16_CHIREQ__io_deq_bits_ns;
  wire  i_Queue16_CHIREQ__io_deq_bits_ns;
  logic p_Queue16_CHIREQ__io_deq_bits_ns;
  bit   t_Queue16_CHIREQ__io_deq_bits_ns;
  wire  g_Queue16_CHIREQ__io_deq_bits_likelyshared;
  wire  i_Queue16_CHIREQ__io_deq_bits_likelyshared;
  logic p_Queue16_CHIREQ__io_deq_bits_likelyshared;
  bit   t_Queue16_CHIREQ__io_deq_bits_likelyshared;
  wire  g_Queue16_CHIREQ__io_deq_bits_allowRetry;
  wire  i_Queue16_CHIREQ__io_deq_bits_allowRetry;
  logic p_Queue16_CHIREQ__io_deq_bits_allowRetry;
  bit   t_Queue16_CHIREQ__io_deq_bits_allowRetry;
  wire  [1:0] g_Queue16_CHIREQ__io_deq_bits_order;
  wire  [1:0] i_Queue16_CHIREQ__io_deq_bits_order;
  logic [1:0] p_Queue16_CHIREQ__io_deq_bits_order;
  bit   t_Queue16_CHIREQ__io_deq_bits_order;
  wire  [3:0] g_Queue16_CHIREQ__io_deq_bits_pCrdType;
  wire  [3:0] i_Queue16_CHIREQ__io_deq_bits_pCrdType;
  logic [3:0] p_Queue16_CHIREQ__io_deq_bits_pCrdType;
  bit   t_Queue16_CHIREQ__io_deq_bits_pCrdType;
  wire  g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate;
  wire  i_Queue16_CHIREQ__io_deq_bits_memAttr_allocate;
  logic p_Queue16_CHIREQ__io_deq_bits_memAttr_allocate;
  bit   t_Queue16_CHIREQ__io_deq_bits_memAttr_allocate;
  wire  g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable;
  wire  i_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable;
  logic p_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable;
  bit   t_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable;
  wire  g_Queue16_CHIREQ__io_deq_bits_memAttr_device;
  wire  i_Queue16_CHIREQ__io_deq_bits_memAttr_device;
  logic p_Queue16_CHIREQ__io_deq_bits_memAttr_device;
  bit   t_Queue16_CHIREQ__io_deq_bits_memAttr_device;
  wire  g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa;
  wire  i_Queue16_CHIREQ__io_deq_bits_memAttr_ewa;
  logic p_Queue16_CHIREQ__io_deq_bits_memAttr_ewa;
  bit   t_Queue16_CHIREQ__io_deq_bits_memAttr_ewa;
  wire  g_Queue16_CHIREQ__io_deq_bits_snpAttr;
  wire  i_Queue16_CHIREQ__io_deq_bits_snpAttr;
  logic p_Queue16_CHIREQ__io_deq_bits_snpAttr;
  bit   t_Queue16_CHIREQ__io_deq_bits_snpAttr;
  wire  [7:0] g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding;
  wire  [7:0] i_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding;
  logic [7:0] p_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding;
  bit   t_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding;
  wire  g_Queue16_CHIREQ__io_deq_bits_snoopMe;
  wire  i_Queue16_CHIREQ__io_deq_bits_snoopMe;
  logic p_Queue16_CHIREQ__io_deq_bits_snoopMe;
  bit   t_Queue16_CHIREQ__io_deq_bits_snoopMe;
  wire  g_Queue16_CHIREQ__io_deq_bits_expCompAck;
  wire  i_Queue16_CHIREQ__io_deq_bits_expCompAck;
  logic p_Queue16_CHIREQ__io_deq_bits_expCompAck;
  bit   t_Queue16_CHIREQ__io_deq_bits_expCompAck;
  wire  [1:0] g_Queue16_CHIREQ__io_deq_bits_tagOp;
  wire  [1:0] i_Queue16_CHIREQ__io_deq_bits_tagOp;
  logic [1:0] p_Queue16_CHIREQ__io_deq_bits_tagOp;
  bit   t_Queue16_CHIREQ__io_deq_bits_tagOp;
  wire  g_Queue16_CHIREQ__io_deq_bits_traceTag;
  wire  i_Queue16_CHIREQ__io_deq_bits_traceTag;
  logic p_Queue16_CHIREQ__io_deq_bits_traceTag;
  bit   t_Queue16_CHIREQ__io_deq_bits_traceTag;
  wire  g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup;
  wire  i_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup;
  logic p_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup;
  bit   t_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup;
  wire  [8:0] g_Queue16_CHIREQ__io_deq_bits_mpam_partID;
  wire  [8:0] i_Queue16_CHIREQ__io_deq_bits_mpam_partID;
  logic [8:0] p_Queue16_CHIREQ__io_deq_bits_mpam_partID;
  bit   t_Queue16_CHIREQ__io_deq_bits_mpam_partID;
  wire  g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS;
  wire  i_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS;
  logic p_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS;
  bit   t_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS;
  wire  [3:0] g_Queue16_CHIREQ__io_deq_bits_rsvdc;
  wire  [3:0] i_Queue16_CHIREQ__io_deq_bits_rsvdc;
  logic [3:0] p_Queue16_CHIREQ__io_deq_bits_rsvdc;
  bit   t_Queue16_CHIREQ__io_deq_bits_rsvdc;
  wire  [4:0] g_Queue16_CHIREQ__io_count;
  wire  [4:0] i_Queue16_CHIREQ__io_count;
  logic [4:0] p_Queue16_CHIREQ__io_count;
  bit   t_Queue16_CHIREQ__io_count;
  Queue16_CHIREQ u_g_Queue16_CHIREQ (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_CHIREQ__io_enq_valid),
    .io_enq_bits_qos (Queue16_CHIREQ__io_enq_bits_qos),
    .io_enq_bits_tgtID (Queue16_CHIREQ__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_CHIREQ__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_CHIREQ__io_enq_bits_txnID),
    .io_enq_bits_opcode (Queue16_CHIREQ__io_enq_bits_opcode),
    .io_enq_bits_size (Queue16_CHIREQ__io_enq_bits_size),
    .io_enq_bits_addr (Queue16_CHIREQ__io_enq_bits_addr),
    .io_enq_bits_likelyshared (Queue16_CHIREQ__io_enq_bits_likelyshared),
    .io_enq_bits_allowRetry (Queue16_CHIREQ__io_enq_bits_allowRetry),
    .io_enq_bits_pCrdType (Queue16_CHIREQ__io_enq_bits_pCrdType),
    .io_enq_bits_memAttr_allocate (Queue16_CHIREQ__io_enq_bits_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable (Queue16_CHIREQ__io_enq_bits_memAttr_cacheable),
    .io_enq_bits_memAttr_device (Queue16_CHIREQ__io_enq_bits_memAttr_device),
    .io_enq_bits_memAttr_ewa (Queue16_CHIREQ__io_enq_bits_memAttr_ewa),
    .io_enq_bits_snpAttr (Queue16_CHIREQ__io_enq_bits_snpAttr),
    .io_enq_bits_expCompAck (Queue16_CHIREQ__io_enq_bits_expCompAck),
    .io_deq_ready (Queue16_CHIREQ__io_deq_ready),
    .io_deq_valid (g_Queue16_CHIREQ__io_deq_valid),
    .io_deq_bits_qos (g_Queue16_CHIREQ__io_deq_bits_qos),
    .io_deq_bits_txnID (g_Queue16_CHIREQ__io_deq_bits_txnID),
    .io_deq_bits_returnNID (g_Queue16_CHIREQ__io_deq_bits_returnNID),
    .io_deq_bits_stashNIDValid (g_Queue16_CHIREQ__io_deq_bits_stashNIDValid),
    .io_deq_bits_returnTxnID (g_Queue16_CHIREQ__io_deq_bits_returnTxnID),
    .io_deq_bits_opcode (g_Queue16_CHIREQ__io_deq_bits_opcode),
    .io_deq_bits_addr (g_Queue16_CHIREQ__io_deq_bits_addr),
    .io_deq_bits_ns (g_Queue16_CHIREQ__io_deq_bits_ns),
    .io_deq_bits_likelyshared (g_Queue16_CHIREQ__io_deq_bits_likelyshared),
    .io_deq_bits_allowRetry (g_Queue16_CHIREQ__io_deq_bits_allowRetry),
    .io_deq_bits_order (g_Queue16_CHIREQ__io_deq_bits_order),
    .io_deq_bits_pCrdType (g_Queue16_CHIREQ__io_deq_bits_pCrdType),
    .io_deq_bits_memAttr_allocate (g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate),
    .io_deq_bits_memAttr_cacheable (g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable),
    .io_deq_bits_memAttr_device (g_Queue16_CHIREQ__io_deq_bits_memAttr_device),
    .io_deq_bits_memAttr_ewa (g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa),
    .io_deq_bits_snpAttr (g_Queue16_CHIREQ__io_deq_bits_snpAttr),
    .io_deq_bits_lpIDWithPadding (g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding),
    .io_deq_bits_snoopMe (g_Queue16_CHIREQ__io_deq_bits_snoopMe),
    .io_deq_bits_expCompAck (g_Queue16_CHIREQ__io_deq_bits_expCompAck),
    .io_deq_bits_tagOp (g_Queue16_CHIREQ__io_deq_bits_tagOp),
    .io_deq_bits_traceTag (g_Queue16_CHIREQ__io_deq_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID (g_Queue16_CHIREQ__io_deq_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS (g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS),
    .io_deq_bits_rsvdc (g_Queue16_CHIREQ__io_deq_bits_rsvdc),
    .io_count (g_Queue16_CHIREQ__io_count)
  );
  Queue16_CHIREQ_xs u_i_Queue16_CHIREQ (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_CHIREQ__io_enq_valid),
    .io_enq_bits_qos (Queue16_CHIREQ__io_enq_bits_qos),
    .io_enq_bits_tgtID (Queue16_CHIREQ__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_CHIREQ__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_CHIREQ__io_enq_bits_txnID),
    .io_enq_bits_opcode (Queue16_CHIREQ__io_enq_bits_opcode),
    .io_enq_bits_size (Queue16_CHIREQ__io_enq_bits_size),
    .io_enq_bits_addr (Queue16_CHIREQ__io_enq_bits_addr),
    .io_enq_bits_likelyshared (Queue16_CHIREQ__io_enq_bits_likelyshared),
    .io_enq_bits_allowRetry (Queue16_CHIREQ__io_enq_bits_allowRetry),
    .io_enq_bits_pCrdType (Queue16_CHIREQ__io_enq_bits_pCrdType),
    .io_enq_bits_memAttr_allocate (Queue16_CHIREQ__io_enq_bits_memAttr_allocate),
    .io_enq_bits_memAttr_cacheable (Queue16_CHIREQ__io_enq_bits_memAttr_cacheable),
    .io_enq_bits_memAttr_device (Queue16_CHIREQ__io_enq_bits_memAttr_device),
    .io_enq_bits_memAttr_ewa (Queue16_CHIREQ__io_enq_bits_memAttr_ewa),
    .io_enq_bits_snpAttr (Queue16_CHIREQ__io_enq_bits_snpAttr),
    .io_enq_bits_expCompAck (Queue16_CHIREQ__io_enq_bits_expCompAck),
    .io_deq_ready (Queue16_CHIREQ__io_deq_ready),
    .io_deq_valid (i_Queue16_CHIREQ__io_deq_valid),
    .io_deq_bits_qos (i_Queue16_CHIREQ__io_deq_bits_qos),
    .io_deq_bits_txnID (i_Queue16_CHIREQ__io_deq_bits_txnID),
    .io_deq_bits_returnNID (i_Queue16_CHIREQ__io_deq_bits_returnNID),
    .io_deq_bits_stashNIDValid (i_Queue16_CHIREQ__io_deq_bits_stashNIDValid),
    .io_deq_bits_returnTxnID (i_Queue16_CHIREQ__io_deq_bits_returnTxnID),
    .io_deq_bits_opcode (i_Queue16_CHIREQ__io_deq_bits_opcode),
    .io_deq_bits_addr (i_Queue16_CHIREQ__io_deq_bits_addr),
    .io_deq_bits_ns (i_Queue16_CHIREQ__io_deq_bits_ns),
    .io_deq_bits_likelyshared (i_Queue16_CHIREQ__io_deq_bits_likelyshared),
    .io_deq_bits_allowRetry (i_Queue16_CHIREQ__io_deq_bits_allowRetry),
    .io_deq_bits_order (i_Queue16_CHIREQ__io_deq_bits_order),
    .io_deq_bits_pCrdType (i_Queue16_CHIREQ__io_deq_bits_pCrdType),
    .io_deq_bits_memAttr_allocate (i_Queue16_CHIREQ__io_deq_bits_memAttr_allocate),
    .io_deq_bits_memAttr_cacheable (i_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable),
    .io_deq_bits_memAttr_device (i_Queue16_CHIREQ__io_deq_bits_memAttr_device),
    .io_deq_bits_memAttr_ewa (i_Queue16_CHIREQ__io_deq_bits_memAttr_ewa),
    .io_deq_bits_snpAttr (i_Queue16_CHIREQ__io_deq_bits_snpAttr),
    .io_deq_bits_lpIDWithPadding (i_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding),
    .io_deq_bits_snoopMe (i_Queue16_CHIREQ__io_deq_bits_snoopMe),
    .io_deq_bits_expCompAck (i_Queue16_CHIREQ__io_deq_bits_expCompAck),
    .io_deq_bits_tagOp (i_Queue16_CHIREQ__io_deq_bits_tagOp),
    .io_deq_bits_traceTag (i_Queue16_CHIREQ__io_deq_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (i_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID (i_Queue16_CHIREQ__io_deq_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS (i_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS),
    .io_deq_bits_rsvdc (i_Queue16_CHIREQ__io_deq_bits_rsvdc),
    .io_count (i_Queue16_CHIREQ__io_count)
  );
  task automatic drive_Queue16_CHIREQ();
    Queue16_CHIREQ__io_enq_valid = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_qos = rnd(4);
    Queue16_CHIREQ__io_enq_bits_tgtID = rnd(11);
    Queue16_CHIREQ__io_enq_bits_srcID = rnd(11);
    Queue16_CHIREQ__io_enq_bits_txnID = rnd(12);
    Queue16_CHIREQ__io_enq_bits_opcode = rnd(7);
    Queue16_CHIREQ__io_enq_bits_size = rnd(3);
    Queue16_CHIREQ__io_enq_bits_addr = rnd(48);
    Queue16_CHIREQ__io_enq_bits_likelyshared = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_allowRetry = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_pCrdType = rnd(4);
    Queue16_CHIREQ__io_enq_bits_memAttr_allocate = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_memAttr_cacheable = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_memAttr_device = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_memAttr_ewa = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_snpAttr = $urandom % 2;
    Queue16_CHIREQ__io_enq_bits_expCompAck = $urandom % 2;
    Queue16_CHIREQ__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_CHIREQ();
    checks++;
    if (g_Queue16_CHIREQ__io_deq_valid !== i_Queue16_CHIREQ__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_valid g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_valid, i_Queue16_CHIREQ__io_deq_valid);
    end
    if (g_Queue16_CHIREQ__io_deq_valid !== p_Queue16_CHIREQ__io_deq_valid) t_Queue16_CHIREQ__io_deq_valid = 1'b1;
    p_Queue16_CHIREQ__io_deq_valid = g_Queue16_CHIREQ__io_deq_valid;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_qos !== i_Queue16_CHIREQ__io_deq_bits_qos) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_qos g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_qos, i_Queue16_CHIREQ__io_deq_bits_qos);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_qos !== p_Queue16_CHIREQ__io_deq_bits_qos) t_Queue16_CHIREQ__io_deq_bits_qos = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_qos = g_Queue16_CHIREQ__io_deq_bits_qos;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_txnID !== i_Queue16_CHIREQ__io_deq_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_txnID g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_txnID, i_Queue16_CHIREQ__io_deq_bits_txnID);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_txnID !== p_Queue16_CHIREQ__io_deq_bits_txnID) t_Queue16_CHIREQ__io_deq_bits_txnID = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_txnID = g_Queue16_CHIREQ__io_deq_bits_txnID;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_returnNID !== i_Queue16_CHIREQ__io_deq_bits_returnNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_returnNID g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_returnNID, i_Queue16_CHIREQ__io_deq_bits_returnNID);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_returnNID !== p_Queue16_CHIREQ__io_deq_bits_returnNID) t_Queue16_CHIREQ__io_deq_bits_returnNID = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_returnNID = g_Queue16_CHIREQ__io_deq_bits_returnNID;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_stashNIDValid !== i_Queue16_CHIREQ__io_deq_bits_stashNIDValid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_stashNIDValid g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_stashNIDValid, i_Queue16_CHIREQ__io_deq_bits_stashNIDValid);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_stashNIDValid !== p_Queue16_CHIREQ__io_deq_bits_stashNIDValid) t_Queue16_CHIREQ__io_deq_bits_stashNIDValid = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_stashNIDValid = g_Queue16_CHIREQ__io_deq_bits_stashNIDValid;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_returnTxnID !== i_Queue16_CHIREQ__io_deq_bits_returnTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_returnTxnID g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_returnTxnID, i_Queue16_CHIREQ__io_deq_bits_returnTxnID);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_returnTxnID !== p_Queue16_CHIREQ__io_deq_bits_returnTxnID) t_Queue16_CHIREQ__io_deq_bits_returnTxnID = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_returnTxnID = g_Queue16_CHIREQ__io_deq_bits_returnTxnID;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_opcode !== i_Queue16_CHIREQ__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_opcode, i_Queue16_CHIREQ__io_deq_bits_opcode);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_opcode !== p_Queue16_CHIREQ__io_deq_bits_opcode) t_Queue16_CHIREQ__io_deq_bits_opcode = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_opcode = g_Queue16_CHIREQ__io_deq_bits_opcode;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_addr !== i_Queue16_CHIREQ__io_deq_bits_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_addr g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_addr, i_Queue16_CHIREQ__io_deq_bits_addr);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_addr !== p_Queue16_CHIREQ__io_deq_bits_addr) t_Queue16_CHIREQ__io_deq_bits_addr = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_addr = g_Queue16_CHIREQ__io_deq_bits_addr;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_ns !== i_Queue16_CHIREQ__io_deq_bits_ns) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_ns g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_ns, i_Queue16_CHIREQ__io_deq_bits_ns);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_ns !== p_Queue16_CHIREQ__io_deq_bits_ns) t_Queue16_CHIREQ__io_deq_bits_ns = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_ns = g_Queue16_CHIREQ__io_deq_bits_ns;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_likelyshared !== i_Queue16_CHIREQ__io_deq_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_likelyshared g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_likelyshared, i_Queue16_CHIREQ__io_deq_bits_likelyshared);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_likelyshared !== p_Queue16_CHIREQ__io_deq_bits_likelyshared) t_Queue16_CHIREQ__io_deq_bits_likelyshared = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_likelyshared = g_Queue16_CHIREQ__io_deq_bits_likelyshared;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_allowRetry !== i_Queue16_CHIREQ__io_deq_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_allowRetry g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_allowRetry, i_Queue16_CHIREQ__io_deq_bits_allowRetry);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_allowRetry !== p_Queue16_CHIREQ__io_deq_bits_allowRetry) t_Queue16_CHIREQ__io_deq_bits_allowRetry = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_allowRetry = g_Queue16_CHIREQ__io_deq_bits_allowRetry;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_order !== i_Queue16_CHIREQ__io_deq_bits_order) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_order g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_order, i_Queue16_CHIREQ__io_deq_bits_order);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_order !== p_Queue16_CHIREQ__io_deq_bits_order) t_Queue16_CHIREQ__io_deq_bits_order = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_order = g_Queue16_CHIREQ__io_deq_bits_order;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_pCrdType !== i_Queue16_CHIREQ__io_deq_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_pCrdType g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_pCrdType, i_Queue16_CHIREQ__io_deq_bits_pCrdType);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_pCrdType !== p_Queue16_CHIREQ__io_deq_bits_pCrdType) t_Queue16_CHIREQ__io_deq_bits_pCrdType = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_pCrdType = g_Queue16_CHIREQ__io_deq_bits_pCrdType;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate !== i_Queue16_CHIREQ__io_deq_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_memAttr_allocate g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate, i_Queue16_CHIREQ__io_deq_bits_memAttr_allocate);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate !== p_Queue16_CHIREQ__io_deq_bits_memAttr_allocate) t_Queue16_CHIREQ__io_deq_bits_memAttr_allocate = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_memAttr_allocate = g_Queue16_CHIREQ__io_deq_bits_memAttr_allocate;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable !== i_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_memAttr_cacheable g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable, i_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable !== p_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable) t_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable = g_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_device !== i_Queue16_CHIREQ__io_deq_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_memAttr_device g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_memAttr_device, i_Queue16_CHIREQ__io_deq_bits_memAttr_device);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_device !== p_Queue16_CHIREQ__io_deq_bits_memAttr_device) t_Queue16_CHIREQ__io_deq_bits_memAttr_device = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_memAttr_device = g_Queue16_CHIREQ__io_deq_bits_memAttr_device;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa !== i_Queue16_CHIREQ__io_deq_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_memAttr_ewa g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa, i_Queue16_CHIREQ__io_deq_bits_memAttr_ewa);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa !== p_Queue16_CHIREQ__io_deq_bits_memAttr_ewa) t_Queue16_CHIREQ__io_deq_bits_memAttr_ewa = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_memAttr_ewa = g_Queue16_CHIREQ__io_deq_bits_memAttr_ewa;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_snpAttr !== i_Queue16_CHIREQ__io_deq_bits_snpAttr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_snpAttr g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_snpAttr, i_Queue16_CHIREQ__io_deq_bits_snpAttr);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_snpAttr !== p_Queue16_CHIREQ__io_deq_bits_snpAttr) t_Queue16_CHIREQ__io_deq_bits_snpAttr = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_snpAttr = g_Queue16_CHIREQ__io_deq_bits_snpAttr;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding !== i_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_lpIDWithPadding g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding, i_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding !== p_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding) t_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding = g_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_snoopMe !== i_Queue16_CHIREQ__io_deq_bits_snoopMe) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_snoopMe g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_snoopMe, i_Queue16_CHIREQ__io_deq_bits_snoopMe);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_snoopMe !== p_Queue16_CHIREQ__io_deq_bits_snoopMe) t_Queue16_CHIREQ__io_deq_bits_snoopMe = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_snoopMe = g_Queue16_CHIREQ__io_deq_bits_snoopMe;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_expCompAck !== i_Queue16_CHIREQ__io_deq_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_expCompAck g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_expCompAck, i_Queue16_CHIREQ__io_deq_bits_expCompAck);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_expCompAck !== p_Queue16_CHIREQ__io_deq_bits_expCompAck) t_Queue16_CHIREQ__io_deq_bits_expCompAck = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_expCompAck = g_Queue16_CHIREQ__io_deq_bits_expCompAck;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_tagOp !== i_Queue16_CHIREQ__io_deq_bits_tagOp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_tagOp g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_tagOp, i_Queue16_CHIREQ__io_deq_bits_tagOp);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_tagOp !== p_Queue16_CHIREQ__io_deq_bits_tagOp) t_Queue16_CHIREQ__io_deq_bits_tagOp = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_tagOp = g_Queue16_CHIREQ__io_deq_bits_tagOp;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_traceTag !== i_Queue16_CHIREQ__io_deq_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_traceTag g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_traceTag, i_Queue16_CHIREQ__io_deq_bits_traceTag);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_traceTag !== p_Queue16_CHIREQ__io_deq_bits_traceTag) t_Queue16_CHIREQ__io_deq_bits_traceTag = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_traceTag = g_Queue16_CHIREQ__io_deq_bits_traceTag;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup !== i_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_mpam_perfMonGroup g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup, i_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup !== p_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup) t_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup = g_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_partID !== i_Queue16_CHIREQ__io_deq_bits_mpam_partID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_mpam_partID g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_mpam_partID, i_Queue16_CHIREQ__io_deq_bits_mpam_partID);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_partID !== p_Queue16_CHIREQ__io_deq_bits_mpam_partID) t_Queue16_CHIREQ__io_deq_bits_mpam_partID = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_mpam_partID = g_Queue16_CHIREQ__io_deq_bits_mpam_partID;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS !== i_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_mpam_mpamNS g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS, i_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS !== p_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS) t_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS = g_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS;
    checks++;
    if (g_Queue16_CHIREQ__io_deq_bits_rsvdc !== i_Queue16_CHIREQ__io_deq_bits_rsvdc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_deq_bits_rsvdc g=%h i=%h", cyc, g_Queue16_CHIREQ__io_deq_bits_rsvdc, i_Queue16_CHIREQ__io_deq_bits_rsvdc);
    end
    if (g_Queue16_CHIREQ__io_deq_bits_rsvdc !== p_Queue16_CHIREQ__io_deq_bits_rsvdc) t_Queue16_CHIREQ__io_deq_bits_rsvdc = 1'b1;
    p_Queue16_CHIREQ__io_deq_bits_rsvdc = g_Queue16_CHIREQ__io_deq_bits_rsvdc;
    checks++;
    if (g_Queue16_CHIREQ__io_count !== i_Queue16_CHIREQ__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIREQ.io_count g=%h i=%h", cyc, g_Queue16_CHIREQ__io_count, i_Queue16_CHIREQ__io_count);
    end
    if (g_Queue16_CHIREQ__io_count !== p_Queue16_CHIREQ__io_count) t_Queue16_CHIREQ__io_count = 1'b1;
    p_Queue16_CHIREQ__io_count = g_Queue16_CHIREQ__io_count;
  endtask
  longint cov_Queue16_CHIREQ_full = 0;
  longint cov_Queue16_CHIREQ_enq = 0;
  longint cov_Queue16_CHIREQ_deq = 0;
  longint cov_Queue16_CHIREQ_enq_deq_same = 0;
  longint cov_Queue16_CHIREQ_full_blocked = 0;
  task automatic cover_Queue16_CHIREQ();
    if (u_g_Queue16_CHIREQ.maybe_full && u_g_Queue16_CHIREQ.ptr_match) cov_Queue16_CHIREQ_full++;
    if (u_g_Queue16_CHIREQ.do_enq) cov_Queue16_CHIREQ_enq++;
    if (u_g_Queue16_CHIREQ.do_deq) cov_Queue16_CHIREQ_deq++;
    if (u_g_Queue16_CHIREQ.do_enq && u_g_Queue16_CHIREQ.do_deq) cov_Queue16_CHIREQ_enq_deq_same++;
    if (u_g_Queue16_CHIREQ.maybe_full && u_g_Queue16_CHIREQ.ptr_match && Queue16_CHIREQ__io_enq_valid && !Queue16_CHIREQ__io_deq_ready) cov_Queue16_CHIREQ_full_blocked++;
  endtask
  task automatic preinit_Queue16_CHIREQ();
  endtask
  task automatic sync_Queue16_CHIREQ();
    u_i_Queue16_CHIREQ.ram_ext.Memory = u_g_Queue16_CHIREQ.ram_ext.Memory;
  endtask

  // ======================= Queue16_CHIRSP =======================
  logic Queue16_CHIRSP__io_enq_valid;
  logic [10:0] Queue16_CHIRSP__io_enq_bits_tgtID;
  logic [10:0] Queue16_CHIRSP__io_enq_bits_srcID;
  logic [11:0] Queue16_CHIRSP__io_enq_bits_txnID;
  logic [4:0] Queue16_CHIRSP__io_enq_bits_opcode;
  logic [1:0] Queue16_CHIRSP__io_enq_bits_respErr;
  logic [2:0] Queue16_CHIRSP__io_enq_bits_resp;
  logic [2:0] Queue16_CHIRSP__io_enq_bits_fwdState;
  logic [11:0] Queue16_CHIRSP__io_enq_bits_dbID;
  logic [3:0] Queue16_CHIRSP__io_enq_bits_pCrdType;
  logic Queue16_CHIRSP__io_enq_bits_traceTag;
  logic Queue16_CHIRSP__io_deq_ready;
  wire  g_Queue16_CHIRSP__io_deq_valid;
  wire  i_Queue16_CHIRSP__io_deq_valid;
  logic p_Queue16_CHIRSP__io_deq_valid;
  bit   t_Queue16_CHIRSP__io_deq_valid;
  wire  [3:0] g_Queue16_CHIRSP__io_deq_bits_qos;
  wire  [3:0] i_Queue16_CHIRSP__io_deq_bits_qos;
  logic [3:0] p_Queue16_CHIRSP__io_deq_bits_qos;
  bit   t_Queue16_CHIRSP__io_deq_bits_qos;
  wire  [10:0] g_Queue16_CHIRSP__io_deq_bits_tgtID;
  wire  [10:0] i_Queue16_CHIRSP__io_deq_bits_tgtID;
  logic [10:0] p_Queue16_CHIRSP__io_deq_bits_tgtID;
  bit   t_Queue16_CHIRSP__io_deq_bits_tgtID;
  wire  [11:0] g_Queue16_CHIRSP__io_deq_bits_txnID;
  wire  [11:0] i_Queue16_CHIRSP__io_deq_bits_txnID;
  logic [11:0] p_Queue16_CHIRSP__io_deq_bits_txnID;
  bit   t_Queue16_CHIRSP__io_deq_bits_txnID;
  wire  [4:0] g_Queue16_CHIRSP__io_deq_bits_opcode;
  wire  [4:0] i_Queue16_CHIRSP__io_deq_bits_opcode;
  logic [4:0] p_Queue16_CHIRSP__io_deq_bits_opcode;
  bit   t_Queue16_CHIRSP__io_deq_bits_opcode;
  wire  [1:0] g_Queue16_CHIRSP__io_deq_bits_respErr;
  wire  [1:0] i_Queue16_CHIRSP__io_deq_bits_respErr;
  logic [1:0] p_Queue16_CHIRSP__io_deq_bits_respErr;
  bit   t_Queue16_CHIRSP__io_deq_bits_respErr;
  wire  [2:0] g_Queue16_CHIRSP__io_deq_bits_resp;
  wire  [2:0] i_Queue16_CHIRSP__io_deq_bits_resp;
  logic [2:0] p_Queue16_CHIRSP__io_deq_bits_resp;
  bit   t_Queue16_CHIRSP__io_deq_bits_resp;
  wire  [2:0] g_Queue16_CHIRSP__io_deq_bits_fwdState;
  wire  [2:0] i_Queue16_CHIRSP__io_deq_bits_fwdState;
  logic [2:0] p_Queue16_CHIRSP__io_deq_bits_fwdState;
  bit   t_Queue16_CHIRSP__io_deq_bits_fwdState;
  wire  [2:0] g_Queue16_CHIRSP__io_deq_bits_cBusy;
  wire  [2:0] i_Queue16_CHIRSP__io_deq_bits_cBusy;
  logic [2:0] p_Queue16_CHIRSP__io_deq_bits_cBusy;
  bit   t_Queue16_CHIRSP__io_deq_bits_cBusy;
  wire  [11:0] g_Queue16_CHIRSP__io_deq_bits_dbID;
  wire  [11:0] i_Queue16_CHIRSP__io_deq_bits_dbID;
  logic [11:0] p_Queue16_CHIRSP__io_deq_bits_dbID;
  bit   t_Queue16_CHIRSP__io_deq_bits_dbID;
  wire  [3:0] g_Queue16_CHIRSP__io_deq_bits_pCrdType;
  wire  [3:0] i_Queue16_CHIRSP__io_deq_bits_pCrdType;
  logic [3:0] p_Queue16_CHIRSP__io_deq_bits_pCrdType;
  bit   t_Queue16_CHIRSP__io_deq_bits_pCrdType;
  wire  [1:0] g_Queue16_CHIRSP__io_deq_bits_tagOp;
  wire  [1:0] i_Queue16_CHIRSP__io_deq_bits_tagOp;
  logic [1:0] p_Queue16_CHIRSP__io_deq_bits_tagOp;
  bit   t_Queue16_CHIRSP__io_deq_bits_tagOp;
  wire  g_Queue16_CHIRSP__io_deq_bits_traceTag;
  wire  i_Queue16_CHIRSP__io_deq_bits_traceTag;
  logic p_Queue16_CHIRSP__io_deq_bits_traceTag;
  bit   t_Queue16_CHIRSP__io_deq_bits_traceTag;
  wire  [4:0] g_Queue16_CHIRSP__io_count;
  wire  [4:0] i_Queue16_CHIRSP__io_count;
  logic [4:0] p_Queue16_CHIRSP__io_count;
  bit   t_Queue16_CHIRSP__io_count;
  Queue16_CHIRSP u_g_Queue16_CHIRSP (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_CHIRSP__io_enq_valid),
    .io_enq_bits_tgtID (Queue16_CHIRSP__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_CHIRSP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_CHIRSP__io_enq_bits_txnID),
    .io_enq_bits_opcode (Queue16_CHIRSP__io_enq_bits_opcode),
    .io_enq_bits_respErr (Queue16_CHIRSP__io_enq_bits_respErr),
    .io_enq_bits_resp (Queue16_CHIRSP__io_enq_bits_resp),
    .io_enq_bits_fwdState (Queue16_CHIRSP__io_enq_bits_fwdState),
    .io_enq_bits_dbID (Queue16_CHIRSP__io_enq_bits_dbID),
    .io_enq_bits_pCrdType (Queue16_CHIRSP__io_enq_bits_pCrdType),
    .io_enq_bits_traceTag (Queue16_CHIRSP__io_enq_bits_traceTag),
    .io_deq_ready (Queue16_CHIRSP__io_deq_ready),
    .io_deq_valid (g_Queue16_CHIRSP__io_deq_valid),
    .io_deq_bits_qos (g_Queue16_CHIRSP__io_deq_bits_qos),
    .io_deq_bits_tgtID (g_Queue16_CHIRSP__io_deq_bits_tgtID),
    .io_deq_bits_txnID (g_Queue16_CHIRSP__io_deq_bits_txnID),
    .io_deq_bits_opcode (g_Queue16_CHIRSP__io_deq_bits_opcode),
    .io_deq_bits_respErr (g_Queue16_CHIRSP__io_deq_bits_respErr),
    .io_deq_bits_resp (g_Queue16_CHIRSP__io_deq_bits_resp),
    .io_deq_bits_fwdState (g_Queue16_CHIRSP__io_deq_bits_fwdState),
    .io_deq_bits_cBusy (g_Queue16_CHIRSP__io_deq_bits_cBusy),
    .io_deq_bits_dbID (g_Queue16_CHIRSP__io_deq_bits_dbID),
    .io_deq_bits_pCrdType (g_Queue16_CHIRSP__io_deq_bits_pCrdType),
    .io_deq_bits_tagOp (g_Queue16_CHIRSP__io_deq_bits_tagOp),
    .io_deq_bits_traceTag (g_Queue16_CHIRSP__io_deq_bits_traceTag),
    .io_count (g_Queue16_CHIRSP__io_count)
  );
  Queue16_CHIRSP_xs u_i_Queue16_CHIRSP (
    .clock (clock),
    .reset (reset),
    .io_enq_valid (Queue16_CHIRSP__io_enq_valid),
    .io_enq_bits_tgtID (Queue16_CHIRSP__io_enq_bits_tgtID),
    .io_enq_bits_srcID (Queue16_CHIRSP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue16_CHIRSP__io_enq_bits_txnID),
    .io_enq_bits_opcode (Queue16_CHIRSP__io_enq_bits_opcode),
    .io_enq_bits_respErr (Queue16_CHIRSP__io_enq_bits_respErr),
    .io_enq_bits_resp (Queue16_CHIRSP__io_enq_bits_resp),
    .io_enq_bits_fwdState (Queue16_CHIRSP__io_enq_bits_fwdState),
    .io_enq_bits_dbID (Queue16_CHIRSP__io_enq_bits_dbID),
    .io_enq_bits_pCrdType (Queue16_CHIRSP__io_enq_bits_pCrdType),
    .io_enq_bits_traceTag (Queue16_CHIRSP__io_enq_bits_traceTag),
    .io_deq_ready (Queue16_CHIRSP__io_deq_ready),
    .io_deq_valid (i_Queue16_CHIRSP__io_deq_valid),
    .io_deq_bits_qos (i_Queue16_CHIRSP__io_deq_bits_qos),
    .io_deq_bits_tgtID (i_Queue16_CHIRSP__io_deq_bits_tgtID),
    .io_deq_bits_txnID (i_Queue16_CHIRSP__io_deq_bits_txnID),
    .io_deq_bits_opcode (i_Queue16_CHIRSP__io_deq_bits_opcode),
    .io_deq_bits_respErr (i_Queue16_CHIRSP__io_deq_bits_respErr),
    .io_deq_bits_resp (i_Queue16_CHIRSP__io_deq_bits_resp),
    .io_deq_bits_fwdState (i_Queue16_CHIRSP__io_deq_bits_fwdState),
    .io_deq_bits_cBusy (i_Queue16_CHIRSP__io_deq_bits_cBusy),
    .io_deq_bits_dbID (i_Queue16_CHIRSP__io_deq_bits_dbID),
    .io_deq_bits_pCrdType (i_Queue16_CHIRSP__io_deq_bits_pCrdType),
    .io_deq_bits_tagOp (i_Queue16_CHIRSP__io_deq_bits_tagOp),
    .io_deq_bits_traceTag (i_Queue16_CHIRSP__io_deq_bits_traceTag),
    .io_count (i_Queue16_CHIRSP__io_count)
  );
  task automatic drive_Queue16_CHIRSP();
    Queue16_CHIRSP__io_enq_valid = $urandom % 2;
    Queue16_CHIRSP__io_enq_bits_tgtID = rnd(11);
    Queue16_CHIRSP__io_enq_bits_srcID = rnd(11);
    Queue16_CHIRSP__io_enq_bits_txnID = rnd(12);
    Queue16_CHIRSP__io_enq_bits_opcode = rnd(5);
    Queue16_CHIRSP__io_enq_bits_respErr = rnd(2);
    Queue16_CHIRSP__io_enq_bits_resp = rnd(3);
    Queue16_CHIRSP__io_enq_bits_fwdState = rnd(3);
    Queue16_CHIRSP__io_enq_bits_dbID = rnd(12);
    Queue16_CHIRSP__io_enq_bits_pCrdType = rnd(4);
    Queue16_CHIRSP__io_enq_bits_traceTag = $urandom % 2;
    Queue16_CHIRSP__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_CHIRSP();
    checks++;
    if (g_Queue16_CHIRSP__io_deq_valid !== i_Queue16_CHIRSP__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_valid g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_valid, i_Queue16_CHIRSP__io_deq_valid);
    end
    if (g_Queue16_CHIRSP__io_deq_valid !== p_Queue16_CHIRSP__io_deq_valid) t_Queue16_CHIRSP__io_deq_valid = 1'b1;
    p_Queue16_CHIRSP__io_deq_valid = g_Queue16_CHIRSP__io_deq_valid;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_qos !== i_Queue16_CHIRSP__io_deq_bits_qos) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_qos g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_qos, i_Queue16_CHIRSP__io_deq_bits_qos);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_qos !== p_Queue16_CHIRSP__io_deq_bits_qos) t_Queue16_CHIRSP__io_deq_bits_qos = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_qos = g_Queue16_CHIRSP__io_deq_bits_qos;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_tgtID !== i_Queue16_CHIRSP__io_deq_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_tgtID g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_tgtID, i_Queue16_CHIRSP__io_deq_bits_tgtID);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_tgtID !== p_Queue16_CHIRSP__io_deq_bits_tgtID) t_Queue16_CHIRSP__io_deq_bits_tgtID = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_tgtID = g_Queue16_CHIRSP__io_deq_bits_tgtID;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_txnID !== i_Queue16_CHIRSP__io_deq_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_txnID g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_txnID, i_Queue16_CHIRSP__io_deq_bits_txnID);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_txnID !== p_Queue16_CHIRSP__io_deq_bits_txnID) t_Queue16_CHIRSP__io_deq_bits_txnID = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_txnID = g_Queue16_CHIRSP__io_deq_bits_txnID;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_opcode !== i_Queue16_CHIRSP__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_opcode, i_Queue16_CHIRSP__io_deq_bits_opcode);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_opcode !== p_Queue16_CHIRSP__io_deq_bits_opcode) t_Queue16_CHIRSP__io_deq_bits_opcode = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_opcode = g_Queue16_CHIRSP__io_deq_bits_opcode;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_respErr !== i_Queue16_CHIRSP__io_deq_bits_respErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_respErr g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_respErr, i_Queue16_CHIRSP__io_deq_bits_respErr);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_respErr !== p_Queue16_CHIRSP__io_deq_bits_respErr) t_Queue16_CHIRSP__io_deq_bits_respErr = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_respErr = g_Queue16_CHIRSP__io_deq_bits_respErr;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_resp !== i_Queue16_CHIRSP__io_deq_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_resp g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_resp, i_Queue16_CHIRSP__io_deq_bits_resp);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_resp !== p_Queue16_CHIRSP__io_deq_bits_resp) t_Queue16_CHIRSP__io_deq_bits_resp = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_resp = g_Queue16_CHIRSP__io_deq_bits_resp;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_fwdState !== i_Queue16_CHIRSP__io_deq_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_fwdState g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_fwdState, i_Queue16_CHIRSP__io_deq_bits_fwdState);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_fwdState !== p_Queue16_CHIRSP__io_deq_bits_fwdState) t_Queue16_CHIRSP__io_deq_bits_fwdState = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_fwdState = g_Queue16_CHIRSP__io_deq_bits_fwdState;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_cBusy !== i_Queue16_CHIRSP__io_deq_bits_cBusy) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_cBusy g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_cBusy, i_Queue16_CHIRSP__io_deq_bits_cBusy);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_cBusy !== p_Queue16_CHIRSP__io_deq_bits_cBusy) t_Queue16_CHIRSP__io_deq_bits_cBusy = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_cBusy = g_Queue16_CHIRSP__io_deq_bits_cBusy;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_dbID !== i_Queue16_CHIRSP__io_deq_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_dbID g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_dbID, i_Queue16_CHIRSP__io_deq_bits_dbID);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_dbID !== p_Queue16_CHIRSP__io_deq_bits_dbID) t_Queue16_CHIRSP__io_deq_bits_dbID = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_dbID = g_Queue16_CHIRSP__io_deq_bits_dbID;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_pCrdType !== i_Queue16_CHIRSP__io_deq_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_pCrdType g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_pCrdType, i_Queue16_CHIRSP__io_deq_bits_pCrdType);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_pCrdType !== p_Queue16_CHIRSP__io_deq_bits_pCrdType) t_Queue16_CHIRSP__io_deq_bits_pCrdType = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_pCrdType = g_Queue16_CHIRSP__io_deq_bits_pCrdType;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_tagOp !== i_Queue16_CHIRSP__io_deq_bits_tagOp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_tagOp g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_tagOp, i_Queue16_CHIRSP__io_deq_bits_tagOp);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_tagOp !== p_Queue16_CHIRSP__io_deq_bits_tagOp) t_Queue16_CHIRSP__io_deq_bits_tagOp = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_tagOp = g_Queue16_CHIRSP__io_deq_bits_tagOp;
    checks++;
    if (g_Queue16_CHIRSP__io_deq_bits_traceTag !== i_Queue16_CHIRSP__io_deq_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_deq_bits_traceTag g=%h i=%h", cyc, g_Queue16_CHIRSP__io_deq_bits_traceTag, i_Queue16_CHIRSP__io_deq_bits_traceTag);
    end
    if (g_Queue16_CHIRSP__io_deq_bits_traceTag !== p_Queue16_CHIRSP__io_deq_bits_traceTag) t_Queue16_CHIRSP__io_deq_bits_traceTag = 1'b1;
    p_Queue16_CHIRSP__io_deq_bits_traceTag = g_Queue16_CHIRSP__io_deq_bits_traceTag;
    checks++;
    if (g_Queue16_CHIRSP__io_count !== i_Queue16_CHIRSP__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_CHIRSP.io_count g=%h i=%h", cyc, g_Queue16_CHIRSP__io_count, i_Queue16_CHIRSP__io_count);
    end
    if (g_Queue16_CHIRSP__io_count !== p_Queue16_CHIRSP__io_count) t_Queue16_CHIRSP__io_count = 1'b1;
    p_Queue16_CHIRSP__io_count = g_Queue16_CHIRSP__io_count;
  endtask
  longint cov_Queue16_CHIRSP_full = 0;
  longint cov_Queue16_CHIRSP_enq = 0;
  longint cov_Queue16_CHIRSP_deq = 0;
  longint cov_Queue16_CHIRSP_enq_deq_same = 0;
  longint cov_Queue16_CHIRSP_full_blocked = 0;
  task automatic cover_Queue16_CHIRSP();
    if (u_g_Queue16_CHIRSP.maybe_full && u_g_Queue16_CHIRSP.ptr_match) cov_Queue16_CHIRSP_full++;
    if (u_g_Queue16_CHIRSP.do_enq) cov_Queue16_CHIRSP_enq++;
    if (u_g_Queue16_CHIRSP.do_deq) cov_Queue16_CHIRSP_deq++;
    if (u_g_Queue16_CHIRSP.do_enq && u_g_Queue16_CHIRSP.do_deq) cov_Queue16_CHIRSP_enq_deq_same++;
    if (u_g_Queue16_CHIRSP.maybe_full && u_g_Queue16_CHIRSP.ptr_match && Queue16_CHIRSP__io_enq_valid && !Queue16_CHIRSP__io_deq_ready) cov_Queue16_CHIRSP_full_blocked++;
  endtask
  task automatic preinit_Queue16_CHIRSP();
  endtask
  task automatic sync_Queue16_CHIRSP();
    u_i_Queue16_CHIRSP.ram_ext.Memory = u_g_Queue16_CHIRSP.ram_ext.Memory;
  endtask

  // ======================= Queue4_CHISNP =======================
  logic Queue4_CHISNP__io_enq_valid;
  logic [3:0] Queue4_CHISNP__io_enq_bits_qos;
  logic [10:0] Queue4_CHISNP__io_enq_bits_srcID;
  logic [11:0] Queue4_CHISNP__io_enq_bits_txnID;
  logic [10:0] Queue4_CHISNP__io_enq_bits_fwdNID;
  logic [11:0] Queue4_CHISNP__io_enq_bits_fwdTxnID;
  logic [4:0] Queue4_CHISNP__io_enq_bits_opcode;
  logic [44:0] Queue4_CHISNP__io_enq_bits_addr;
  logic Queue4_CHISNP__io_enq_bits_ns;
  logic Queue4_CHISNP__io_enq_bits_doNotGoToSD;
  logic Queue4_CHISNP__io_enq_bits_retToSrc;
  logic Queue4_CHISNP__io_enq_bits_traceTag;
  logic Queue4_CHISNP__io_enq_bits_mpam_perfMonGroup;
  logic [8:0] Queue4_CHISNP__io_enq_bits_mpam_partID;
  logic Queue4_CHISNP__io_enq_bits_mpam_mpamNS;
  logic Queue4_CHISNP__io_deq_ready;
  wire  g_Queue4_CHISNP__io_enq_ready;
  wire  i_Queue4_CHISNP__io_enq_ready;
  logic p_Queue4_CHISNP__io_enq_ready;
  bit   t_Queue4_CHISNP__io_enq_ready;
  wire  g_Queue4_CHISNP__io_deq_valid;
  wire  i_Queue4_CHISNP__io_deq_valid;
  logic p_Queue4_CHISNP__io_deq_valid;
  bit   t_Queue4_CHISNP__io_deq_valid;
  wire  [3:0] g_Queue4_CHISNP__io_deq_bits_qos;
  wire  [3:0] i_Queue4_CHISNP__io_deq_bits_qos;
  logic [3:0] p_Queue4_CHISNP__io_deq_bits_qos;
  bit   t_Queue4_CHISNP__io_deq_bits_qos;
  wire  [10:0] g_Queue4_CHISNP__io_deq_bits_srcID;
  wire  [10:0] i_Queue4_CHISNP__io_deq_bits_srcID;
  logic [10:0] p_Queue4_CHISNP__io_deq_bits_srcID;
  bit   t_Queue4_CHISNP__io_deq_bits_srcID;
  wire  [11:0] g_Queue4_CHISNP__io_deq_bits_txnID;
  wire  [11:0] i_Queue4_CHISNP__io_deq_bits_txnID;
  logic [11:0] p_Queue4_CHISNP__io_deq_bits_txnID;
  bit   t_Queue4_CHISNP__io_deq_bits_txnID;
  wire  [10:0] g_Queue4_CHISNP__io_deq_bits_fwdNID;
  wire  [10:0] i_Queue4_CHISNP__io_deq_bits_fwdNID;
  logic [10:0] p_Queue4_CHISNP__io_deq_bits_fwdNID;
  bit   t_Queue4_CHISNP__io_deq_bits_fwdNID;
  wire  [11:0] g_Queue4_CHISNP__io_deq_bits_fwdTxnID;
  wire  [11:0] i_Queue4_CHISNP__io_deq_bits_fwdTxnID;
  logic [11:0] p_Queue4_CHISNP__io_deq_bits_fwdTxnID;
  bit   t_Queue4_CHISNP__io_deq_bits_fwdTxnID;
  wire  [4:0] g_Queue4_CHISNP__io_deq_bits_opcode;
  wire  [4:0] i_Queue4_CHISNP__io_deq_bits_opcode;
  logic [4:0] p_Queue4_CHISNP__io_deq_bits_opcode;
  bit   t_Queue4_CHISNP__io_deq_bits_opcode;
  wire  [44:0] g_Queue4_CHISNP__io_deq_bits_addr;
  wire  [44:0] i_Queue4_CHISNP__io_deq_bits_addr;
  logic [44:0] p_Queue4_CHISNP__io_deq_bits_addr;
  bit   t_Queue4_CHISNP__io_deq_bits_addr;
  wire  g_Queue4_CHISNP__io_deq_bits_ns;
  wire  i_Queue4_CHISNP__io_deq_bits_ns;
  logic p_Queue4_CHISNP__io_deq_bits_ns;
  bit   t_Queue4_CHISNP__io_deq_bits_ns;
  wire  g_Queue4_CHISNP__io_deq_bits_doNotGoToSD;
  wire  i_Queue4_CHISNP__io_deq_bits_doNotGoToSD;
  logic p_Queue4_CHISNP__io_deq_bits_doNotGoToSD;
  bit   t_Queue4_CHISNP__io_deq_bits_doNotGoToSD;
  wire  g_Queue4_CHISNP__io_deq_bits_retToSrc;
  wire  i_Queue4_CHISNP__io_deq_bits_retToSrc;
  logic p_Queue4_CHISNP__io_deq_bits_retToSrc;
  bit   t_Queue4_CHISNP__io_deq_bits_retToSrc;
  wire  g_Queue4_CHISNP__io_deq_bits_traceTag;
  wire  i_Queue4_CHISNP__io_deq_bits_traceTag;
  logic p_Queue4_CHISNP__io_deq_bits_traceTag;
  bit   t_Queue4_CHISNP__io_deq_bits_traceTag;
  wire  g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup;
  wire  i_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup;
  logic p_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup;
  bit   t_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup;
  wire  [8:0] g_Queue4_CHISNP__io_deq_bits_mpam_partID;
  wire  [8:0] i_Queue4_CHISNP__io_deq_bits_mpam_partID;
  logic [8:0] p_Queue4_CHISNP__io_deq_bits_mpam_partID;
  bit   t_Queue4_CHISNP__io_deq_bits_mpam_partID;
  wire  g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS;
  wire  i_Queue4_CHISNP__io_deq_bits_mpam_mpamNS;
  logic p_Queue4_CHISNP__io_deq_bits_mpam_mpamNS;
  bit   t_Queue4_CHISNP__io_deq_bits_mpam_mpamNS;
  wire  [2:0] g_Queue4_CHISNP__io_count;
  wire  [2:0] i_Queue4_CHISNP__io_count;
  logic [2:0] p_Queue4_CHISNP__io_count;
  bit   t_Queue4_CHISNP__io_count;
  Queue4_CHISNP u_g_Queue4_CHISNP (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue4_CHISNP__io_enq_ready),
    .io_enq_valid (Queue4_CHISNP__io_enq_valid),
    .io_enq_bits_qos (Queue4_CHISNP__io_enq_bits_qos),
    .io_enq_bits_srcID (Queue4_CHISNP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue4_CHISNP__io_enq_bits_txnID),
    .io_enq_bits_fwdNID (Queue4_CHISNP__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue4_CHISNP__io_enq_bits_fwdTxnID),
    .io_enq_bits_opcode (Queue4_CHISNP__io_enq_bits_opcode),
    .io_enq_bits_addr (Queue4_CHISNP__io_enq_bits_addr),
    .io_enq_bits_ns (Queue4_CHISNP__io_enq_bits_ns),
    .io_enq_bits_doNotGoToSD (Queue4_CHISNP__io_enq_bits_doNotGoToSD),
    .io_enq_bits_retToSrc (Queue4_CHISNP__io_enq_bits_retToSrc),
    .io_enq_bits_traceTag (Queue4_CHISNP__io_enq_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup (Queue4_CHISNP__io_enq_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID (Queue4_CHISNP__io_enq_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS (Queue4_CHISNP__io_enq_bits_mpam_mpamNS),
    .io_deq_ready (Queue4_CHISNP__io_deq_ready),
    .io_deq_valid (g_Queue4_CHISNP__io_deq_valid),
    .io_deq_bits_qos (g_Queue4_CHISNP__io_deq_bits_qos),
    .io_deq_bits_srcID (g_Queue4_CHISNP__io_deq_bits_srcID),
    .io_deq_bits_txnID (g_Queue4_CHISNP__io_deq_bits_txnID),
    .io_deq_bits_fwdNID (g_Queue4_CHISNP__io_deq_bits_fwdNID),
    .io_deq_bits_fwdTxnID (g_Queue4_CHISNP__io_deq_bits_fwdTxnID),
    .io_deq_bits_opcode (g_Queue4_CHISNP__io_deq_bits_opcode),
    .io_deq_bits_addr (g_Queue4_CHISNP__io_deq_bits_addr),
    .io_deq_bits_ns (g_Queue4_CHISNP__io_deq_bits_ns),
    .io_deq_bits_doNotGoToSD (g_Queue4_CHISNP__io_deq_bits_doNotGoToSD),
    .io_deq_bits_retToSrc (g_Queue4_CHISNP__io_deq_bits_retToSrc),
    .io_deq_bits_traceTag (g_Queue4_CHISNP__io_deq_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID (g_Queue4_CHISNP__io_deq_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS (g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS),
    .io_count (g_Queue4_CHISNP__io_count)
  );
  Queue4_CHISNP_xs u_i_Queue4_CHISNP (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue4_CHISNP__io_enq_ready),
    .io_enq_valid (Queue4_CHISNP__io_enq_valid),
    .io_enq_bits_qos (Queue4_CHISNP__io_enq_bits_qos),
    .io_enq_bits_srcID (Queue4_CHISNP__io_enq_bits_srcID),
    .io_enq_bits_txnID (Queue4_CHISNP__io_enq_bits_txnID),
    .io_enq_bits_fwdNID (Queue4_CHISNP__io_enq_bits_fwdNID),
    .io_enq_bits_fwdTxnID (Queue4_CHISNP__io_enq_bits_fwdTxnID),
    .io_enq_bits_opcode (Queue4_CHISNP__io_enq_bits_opcode),
    .io_enq_bits_addr (Queue4_CHISNP__io_enq_bits_addr),
    .io_enq_bits_ns (Queue4_CHISNP__io_enq_bits_ns),
    .io_enq_bits_doNotGoToSD (Queue4_CHISNP__io_enq_bits_doNotGoToSD),
    .io_enq_bits_retToSrc (Queue4_CHISNP__io_enq_bits_retToSrc),
    .io_enq_bits_traceTag (Queue4_CHISNP__io_enq_bits_traceTag),
    .io_enq_bits_mpam_perfMonGroup (Queue4_CHISNP__io_enq_bits_mpam_perfMonGroup),
    .io_enq_bits_mpam_partID (Queue4_CHISNP__io_enq_bits_mpam_partID),
    .io_enq_bits_mpam_mpamNS (Queue4_CHISNP__io_enq_bits_mpam_mpamNS),
    .io_deq_ready (Queue4_CHISNP__io_deq_ready),
    .io_deq_valid (i_Queue4_CHISNP__io_deq_valid),
    .io_deq_bits_qos (i_Queue4_CHISNP__io_deq_bits_qos),
    .io_deq_bits_srcID (i_Queue4_CHISNP__io_deq_bits_srcID),
    .io_deq_bits_txnID (i_Queue4_CHISNP__io_deq_bits_txnID),
    .io_deq_bits_fwdNID (i_Queue4_CHISNP__io_deq_bits_fwdNID),
    .io_deq_bits_fwdTxnID (i_Queue4_CHISNP__io_deq_bits_fwdTxnID),
    .io_deq_bits_opcode (i_Queue4_CHISNP__io_deq_bits_opcode),
    .io_deq_bits_addr (i_Queue4_CHISNP__io_deq_bits_addr),
    .io_deq_bits_ns (i_Queue4_CHISNP__io_deq_bits_ns),
    .io_deq_bits_doNotGoToSD (i_Queue4_CHISNP__io_deq_bits_doNotGoToSD),
    .io_deq_bits_retToSrc (i_Queue4_CHISNP__io_deq_bits_retToSrc),
    .io_deq_bits_traceTag (i_Queue4_CHISNP__io_deq_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (i_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID (i_Queue4_CHISNP__io_deq_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS (i_Queue4_CHISNP__io_deq_bits_mpam_mpamNS),
    .io_count (i_Queue4_CHISNP__io_count)
  );
  task automatic drive_Queue4_CHISNP();
    Queue4_CHISNP__io_enq_valid = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_qos = rnd(4);
    Queue4_CHISNP__io_enq_bits_srcID = rnd(11);
    Queue4_CHISNP__io_enq_bits_txnID = rnd(12);
    Queue4_CHISNP__io_enq_bits_fwdNID = rnd(11);
    Queue4_CHISNP__io_enq_bits_fwdTxnID = rnd(12);
    Queue4_CHISNP__io_enq_bits_opcode = rnd(5);
    Queue4_CHISNP__io_enq_bits_addr = rnd(45);
    Queue4_CHISNP__io_enq_bits_ns = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_doNotGoToSD = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_retToSrc = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_traceTag = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_mpam_perfMonGroup = $urandom % 2;
    Queue4_CHISNP__io_enq_bits_mpam_partID = rnd(9);
    Queue4_CHISNP__io_enq_bits_mpam_mpamNS = $urandom % 2;
    Queue4_CHISNP__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue4_CHISNP();
    checks++;
    if (g_Queue4_CHISNP__io_enq_ready !== i_Queue4_CHISNP__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_enq_ready g=%h i=%h", cyc, g_Queue4_CHISNP__io_enq_ready, i_Queue4_CHISNP__io_enq_ready);
    end
    if (g_Queue4_CHISNP__io_enq_ready !== p_Queue4_CHISNP__io_enq_ready) t_Queue4_CHISNP__io_enq_ready = 1'b1;
    p_Queue4_CHISNP__io_enq_ready = g_Queue4_CHISNP__io_enq_ready;
    checks++;
    if (g_Queue4_CHISNP__io_deq_valid !== i_Queue4_CHISNP__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_valid g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_valid, i_Queue4_CHISNP__io_deq_valid);
    end
    if (g_Queue4_CHISNP__io_deq_valid !== p_Queue4_CHISNP__io_deq_valid) t_Queue4_CHISNP__io_deq_valid = 1'b1;
    p_Queue4_CHISNP__io_deq_valid = g_Queue4_CHISNP__io_deq_valid;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_qos !== i_Queue4_CHISNP__io_deq_bits_qos) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_qos g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_qos, i_Queue4_CHISNP__io_deq_bits_qos);
    end
    if (g_Queue4_CHISNP__io_deq_bits_qos !== p_Queue4_CHISNP__io_deq_bits_qos) t_Queue4_CHISNP__io_deq_bits_qos = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_qos = g_Queue4_CHISNP__io_deq_bits_qos;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_srcID !== i_Queue4_CHISNP__io_deq_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_srcID g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_srcID, i_Queue4_CHISNP__io_deq_bits_srcID);
    end
    if (g_Queue4_CHISNP__io_deq_bits_srcID !== p_Queue4_CHISNP__io_deq_bits_srcID) t_Queue4_CHISNP__io_deq_bits_srcID = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_srcID = g_Queue4_CHISNP__io_deq_bits_srcID;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_txnID !== i_Queue4_CHISNP__io_deq_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_txnID g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_txnID, i_Queue4_CHISNP__io_deq_bits_txnID);
    end
    if (g_Queue4_CHISNP__io_deq_bits_txnID !== p_Queue4_CHISNP__io_deq_bits_txnID) t_Queue4_CHISNP__io_deq_bits_txnID = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_txnID = g_Queue4_CHISNP__io_deq_bits_txnID;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_fwdNID !== i_Queue4_CHISNP__io_deq_bits_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_fwdNID g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_fwdNID, i_Queue4_CHISNP__io_deq_bits_fwdNID);
    end
    if (g_Queue4_CHISNP__io_deq_bits_fwdNID !== p_Queue4_CHISNP__io_deq_bits_fwdNID) t_Queue4_CHISNP__io_deq_bits_fwdNID = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_fwdNID = g_Queue4_CHISNP__io_deq_bits_fwdNID;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_fwdTxnID !== i_Queue4_CHISNP__io_deq_bits_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_fwdTxnID g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_fwdTxnID, i_Queue4_CHISNP__io_deq_bits_fwdTxnID);
    end
    if (g_Queue4_CHISNP__io_deq_bits_fwdTxnID !== p_Queue4_CHISNP__io_deq_bits_fwdTxnID) t_Queue4_CHISNP__io_deq_bits_fwdTxnID = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_fwdTxnID = g_Queue4_CHISNP__io_deq_bits_fwdTxnID;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_opcode !== i_Queue4_CHISNP__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_opcode, i_Queue4_CHISNP__io_deq_bits_opcode);
    end
    if (g_Queue4_CHISNP__io_deq_bits_opcode !== p_Queue4_CHISNP__io_deq_bits_opcode) t_Queue4_CHISNP__io_deq_bits_opcode = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_opcode = g_Queue4_CHISNP__io_deq_bits_opcode;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_addr !== i_Queue4_CHISNP__io_deq_bits_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_addr g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_addr, i_Queue4_CHISNP__io_deq_bits_addr);
    end
    if (g_Queue4_CHISNP__io_deq_bits_addr !== p_Queue4_CHISNP__io_deq_bits_addr) t_Queue4_CHISNP__io_deq_bits_addr = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_addr = g_Queue4_CHISNP__io_deq_bits_addr;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_ns !== i_Queue4_CHISNP__io_deq_bits_ns) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_ns g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_ns, i_Queue4_CHISNP__io_deq_bits_ns);
    end
    if (g_Queue4_CHISNP__io_deq_bits_ns !== p_Queue4_CHISNP__io_deq_bits_ns) t_Queue4_CHISNP__io_deq_bits_ns = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_ns = g_Queue4_CHISNP__io_deq_bits_ns;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_doNotGoToSD !== i_Queue4_CHISNP__io_deq_bits_doNotGoToSD) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_doNotGoToSD g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_doNotGoToSD, i_Queue4_CHISNP__io_deq_bits_doNotGoToSD);
    end
    if (g_Queue4_CHISNP__io_deq_bits_doNotGoToSD !== p_Queue4_CHISNP__io_deq_bits_doNotGoToSD) t_Queue4_CHISNP__io_deq_bits_doNotGoToSD = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_doNotGoToSD = g_Queue4_CHISNP__io_deq_bits_doNotGoToSD;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_retToSrc !== i_Queue4_CHISNP__io_deq_bits_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_retToSrc g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_retToSrc, i_Queue4_CHISNP__io_deq_bits_retToSrc);
    end
    if (g_Queue4_CHISNP__io_deq_bits_retToSrc !== p_Queue4_CHISNP__io_deq_bits_retToSrc) t_Queue4_CHISNP__io_deq_bits_retToSrc = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_retToSrc = g_Queue4_CHISNP__io_deq_bits_retToSrc;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_traceTag !== i_Queue4_CHISNP__io_deq_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_traceTag g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_traceTag, i_Queue4_CHISNP__io_deq_bits_traceTag);
    end
    if (g_Queue4_CHISNP__io_deq_bits_traceTag !== p_Queue4_CHISNP__io_deq_bits_traceTag) t_Queue4_CHISNP__io_deq_bits_traceTag = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_traceTag = g_Queue4_CHISNP__io_deq_bits_traceTag;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup !== i_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_mpam_perfMonGroup g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup, i_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup);
    end
    if (g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup !== p_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup) t_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup = g_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_mpam_partID !== i_Queue4_CHISNP__io_deq_bits_mpam_partID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_mpam_partID g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_mpam_partID, i_Queue4_CHISNP__io_deq_bits_mpam_partID);
    end
    if (g_Queue4_CHISNP__io_deq_bits_mpam_partID !== p_Queue4_CHISNP__io_deq_bits_mpam_partID) t_Queue4_CHISNP__io_deq_bits_mpam_partID = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_mpam_partID = g_Queue4_CHISNP__io_deq_bits_mpam_partID;
    checks++;
    if (g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS !== i_Queue4_CHISNP__io_deq_bits_mpam_mpamNS) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_deq_bits_mpam_mpamNS g=%h i=%h", cyc, g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS, i_Queue4_CHISNP__io_deq_bits_mpam_mpamNS);
    end
    if (g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS !== p_Queue4_CHISNP__io_deq_bits_mpam_mpamNS) t_Queue4_CHISNP__io_deq_bits_mpam_mpamNS = 1'b1;
    p_Queue4_CHISNP__io_deq_bits_mpam_mpamNS = g_Queue4_CHISNP__io_deq_bits_mpam_mpamNS;
    checks++;
    if (g_Queue4_CHISNP__io_count !== i_Queue4_CHISNP__io_count) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_CHISNP.io_count g=%h i=%h", cyc, g_Queue4_CHISNP__io_count, i_Queue4_CHISNP__io_count);
    end
    if (g_Queue4_CHISNP__io_count !== p_Queue4_CHISNP__io_count) t_Queue4_CHISNP__io_count = 1'b1;
    p_Queue4_CHISNP__io_count = g_Queue4_CHISNP__io_count;
  endtask
  longint cov_Queue4_CHISNP_full = 0;
  longint cov_Queue4_CHISNP_enq = 0;
  longint cov_Queue4_CHISNP_deq = 0;
  longint cov_Queue4_CHISNP_enq_deq_same = 0;
  longint cov_Queue4_CHISNP_full_blocked = 0;
  longint cov_Queue4_CHISNP_pipe_enq_when_full = 0;
  task automatic cover_Queue4_CHISNP();
    if (u_g_Queue4_CHISNP.maybe_full && u_g_Queue4_CHISNP.ptr_match) cov_Queue4_CHISNP_full++;
    if (u_g_Queue4_CHISNP.do_enq) cov_Queue4_CHISNP_enq++;
    if (u_g_Queue4_CHISNP.do_deq) cov_Queue4_CHISNP_deq++;
    if (u_g_Queue4_CHISNP.do_enq && u_g_Queue4_CHISNP.do_deq) cov_Queue4_CHISNP_enq_deq_same++;
    if (u_g_Queue4_CHISNP.maybe_full && u_g_Queue4_CHISNP.ptr_match && Queue4_CHISNP__io_enq_valid && !Queue4_CHISNP__io_deq_ready) cov_Queue4_CHISNP_full_blocked++;
    if (u_g_Queue4_CHISNP.maybe_full && u_g_Queue4_CHISNP.ptr_match && u_g_Queue4_CHISNP.do_enq) cov_Queue4_CHISNP_pipe_enq_when_full++;
  endtask
  task automatic preinit_Queue4_CHISNP();
  endtask
  task automatic sync_Queue4_CHISNP();
    u_i_Queue4_CHISNP.ram_ext.Memory = u_g_Queue4_CHISNP.ram_ext.Memory;
  endtask

  // ======================= Queue2_PCrdGranted =======================
  logic Queue2_PCrdGranted__io_enq_valid;
  logic [3:0] Queue2_PCrdGranted__io_enq_bits_pCrdType;
  logic [10:0] Queue2_PCrdGranted__io_enq_bits_srcID;
  logic Queue2_PCrdGranted__io_deq_ready;
  wire  g_Queue2_PCrdGranted__io_enq_ready;
  wire  i_Queue2_PCrdGranted__io_enq_ready;
  logic p_Queue2_PCrdGranted__io_enq_ready;
  bit   t_Queue2_PCrdGranted__io_enq_ready;
  wire  g_Queue2_PCrdGranted__io_deq_valid;
  wire  i_Queue2_PCrdGranted__io_deq_valid;
  logic p_Queue2_PCrdGranted__io_deq_valid;
  bit   t_Queue2_PCrdGranted__io_deq_valid;
  wire  [3:0] g_Queue2_PCrdGranted__io_deq_bits_pCrdType;
  wire  [3:0] i_Queue2_PCrdGranted__io_deq_bits_pCrdType;
  logic [3:0] p_Queue2_PCrdGranted__io_deq_bits_pCrdType;
  bit   t_Queue2_PCrdGranted__io_deq_bits_pCrdType;
  wire  [10:0] g_Queue2_PCrdGranted__io_deq_bits_srcID;
  wire  [10:0] i_Queue2_PCrdGranted__io_deq_bits_srcID;
  logic [10:0] p_Queue2_PCrdGranted__io_deq_bits_srcID;
  bit   t_Queue2_PCrdGranted__io_deq_bits_srcID;
  Queue2_PCrdGranted u_g_Queue2_PCrdGranted (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue2_PCrdGranted__io_enq_ready),
    .io_enq_valid (Queue2_PCrdGranted__io_enq_valid),
    .io_enq_bits_pCrdType (Queue2_PCrdGranted__io_enq_bits_pCrdType),
    .io_enq_bits_srcID (Queue2_PCrdGranted__io_enq_bits_srcID),
    .io_deq_ready (Queue2_PCrdGranted__io_deq_ready),
    .io_deq_valid (g_Queue2_PCrdGranted__io_deq_valid),
    .io_deq_bits_pCrdType (g_Queue2_PCrdGranted__io_deq_bits_pCrdType),
    .io_deq_bits_srcID (g_Queue2_PCrdGranted__io_deq_bits_srcID)
  );
  Queue2_PCrdGranted_xs u_i_Queue2_PCrdGranted (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue2_PCrdGranted__io_enq_ready),
    .io_enq_valid (Queue2_PCrdGranted__io_enq_valid),
    .io_enq_bits_pCrdType (Queue2_PCrdGranted__io_enq_bits_pCrdType),
    .io_enq_bits_srcID (Queue2_PCrdGranted__io_enq_bits_srcID),
    .io_deq_ready (Queue2_PCrdGranted__io_deq_ready),
    .io_deq_valid (i_Queue2_PCrdGranted__io_deq_valid),
    .io_deq_bits_pCrdType (i_Queue2_PCrdGranted__io_deq_bits_pCrdType),
    .io_deq_bits_srcID (i_Queue2_PCrdGranted__io_deq_bits_srcID)
  );
  task automatic drive_Queue2_PCrdGranted();
    Queue2_PCrdGranted__io_enq_valid = $urandom % 2;
    Queue2_PCrdGranted__io_enq_bits_pCrdType = rnd(4);
    Queue2_PCrdGranted__io_enq_bits_srcID = rnd(11);
    Queue2_PCrdGranted__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue2_PCrdGranted();
    checks++;
    if (g_Queue2_PCrdGranted__io_enq_ready !== i_Queue2_PCrdGranted__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_PCrdGranted.io_enq_ready g=%h i=%h", cyc, g_Queue2_PCrdGranted__io_enq_ready, i_Queue2_PCrdGranted__io_enq_ready);
    end
    if (g_Queue2_PCrdGranted__io_enq_ready !== p_Queue2_PCrdGranted__io_enq_ready) t_Queue2_PCrdGranted__io_enq_ready = 1'b1;
    p_Queue2_PCrdGranted__io_enq_ready = g_Queue2_PCrdGranted__io_enq_ready;
    checks++;
    if (g_Queue2_PCrdGranted__io_deq_valid !== i_Queue2_PCrdGranted__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_PCrdGranted.io_deq_valid g=%h i=%h", cyc, g_Queue2_PCrdGranted__io_deq_valid, i_Queue2_PCrdGranted__io_deq_valid);
    end
    if (g_Queue2_PCrdGranted__io_deq_valid !== p_Queue2_PCrdGranted__io_deq_valid) t_Queue2_PCrdGranted__io_deq_valid = 1'b1;
    p_Queue2_PCrdGranted__io_deq_valid = g_Queue2_PCrdGranted__io_deq_valid;
    checks++;
    if (g_Queue2_PCrdGranted__io_deq_bits_pCrdType !== i_Queue2_PCrdGranted__io_deq_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_PCrdGranted.io_deq_bits_pCrdType g=%h i=%h", cyc, g_Queue2_PCrdGranted__io_deq_bits_pCrdType, i_Queue2_PCrdGranted__io_deq_bits_pCrdType);
    end
    if (g_Queue2_PCrdGranted__io_deq_bits_pCrdType !== p_Queue2_PCrdGranted__io_deq_bits_pCrdType) t_Queue2_PCrdGranted__io_deq_bits_pCrdType = 1'b1;
    p_Queue2_PCrdGranted__io_deq_bits_pCrdType = g_Queue2_PCrdGranted__io_deq_bits_pCrdType;
    checks++;
    if (g_Queue2_PCrdGranted__io_deq_bits_srcID !== i_Queue2_PCrdGranted__io_deq_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue2_PCrdGranted.io_deq_bits_srcID g=%h i=%h", cyc, g_Queue2_PCrdGranted__io_deq_bits_srcID, i_Queue2_PCrdGranted__io_deq_bits_srcID);
    end
    if (g_Queue2_PCrdGranted__io_deq_bits_srcID !== p_Queue2_PCrdGranted__io_deq_bits_srcID) t_Queue2_PCrdGranted__io_deq_bits_srcID = 1'b1;
    p_Queue2_PCrdGranted__io_deq_bits_srcID = g_Queue2_PCrdGranted__io_deq_bits_srcID;
  endtask
  longint cov_Queue2_PCrdGranted_full = 0;
  longint cov_Queue2_PCrdGranted_enq = 0;
  longint cov_Queue2_PCrdGranted_deq = 0;
  longint cov_Queue2_PCrdGranted_enq_deq_same = 0;
  longint cov_Queue2_PCrdGranted_full_blocked = 0;
  task automatic cover_Queue2_PCrdGranted();
    if (u_g_Queue2_PCrdGranted.maybe_full && u_g_Queue2_PCrdGranted.ptr_match) cov_Queue2_PCrdGranted_full++;
    if (u_g_Queue2_PCrdGranted.do_enq) cov_Queue2_PCrdGranted_enq++;
    if (u_g_Queue2_PCrdGranted.do_deq) cov_Queue2_PCrdGranted_deq++;
    if (u_g_Queue2_PCrdGranted.do_enq && u_g_Queue2_PCrdGranted.do_deq) cov_Queue2_PCrdGranted_enq_deq_same++;
    if (u_g_Queue2_PCrdGranted.maybe_full && u_g_Queue2_PCrdGranted.ptr_match && Queue2_PCrdGranted__io_enq_valid && !Queue2_PCrdGranted__io_deq_ready) cov_Queue2_PCrdGranted_full_blocked++;
  endtask
  task automatic preinit_Queue2_PCrdGranted();
  endtask
  task automatic sync_Queue2_PCrdGranted();
    u_i_Queue2_PCrdGranted.ram_ext.Memory = u_g_Queue2_PCrdGranted.ram_ext.Memory;
  endtask

  // ======================= Queue78_PCrdGranted =======================
  logic Queue78_PCrdGranted__io_enq_valid;
  logic [3:0] Queue78_PCrdGranted__io_enq_bits_pCrdType;
  logic [10:0] Queue78_PCrdGranted__io_enq_bits_srcID;
  logic Queue78_PCrdGranted__io_deq_ready;
  wire  g_Queue78_PCrdGranted__io_enq_ready;
  wire  i_Queue78_PCrdGranted__io_enq_ready;
  logic p_Queue78_PCrdGranted__io_enq_ready;
  bit   t_Queue78_PCrdGranted__io_enq_ready;
  wire  g_Queue78_PCrdGranted__io_deq_valid;
  wire  i_Queue78_PCrdGranted__io_deq_valid;
  logic p_Queue78_PCrdGranted__io_deq_valid;
  bit   t_Queue78_PCrdGranted__io_deq_valid;
  wire  [3:0] g_Queue78_PCrdGranted__io_deq_bits_pCrdType;
  wire  [3:0] i_Queue78_PCrdGranted__io_deq_bits_pCrdType;
  logic [3:0] p_Queue78_PCrdGranted__io_deq_bits_pCrdType;
  bit   t_Queue78_PCrdGranted__io_deq_bits_pCrdType;
  wire  [10:0] g_Queue78_PCrdGranted__io_deq_bits_srcID;
  wire  [10:0] i_Queue78_PCrdGranted__io_deq_bits_srcID;
  logic [10:0] p_Queue78_PCrdGranted__io_deq_bits_srcID;
  bit   t_Queue78_PCrdGranted__io_deq_bits_srcID;
  Queue78_PCrdGranted u_g_Queue78_PCrdGranted (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue78_PCrdGranted__io_enq_ready),
    .io_enq_valid (Queue78_PCrdGranted__io_enq_valid),
    .io_enq_bits_pCrdType (Queue78_PCrdGranted__io_enq_bits_pCrdType),
    .io_enq_bits_srcID (Queue78_PCrdGranted__io_enq_bits_srcID),
    .io_deq_ready (Queue78_PCrdGranted__io_deq_ready),
    .io_deq_valid (g_Queue78_PCrdGranted__io_deq_valid),
    .io_deq_bits_pCrdType (g_Queue78_PCrdGranted__io_deq_bits_pCrdType),
    .io_deq_bits_srcID (g_Queue78_PCrdGranted__io_deq_bits_srcID)
  );
  Queue78_PCrdGranted_xs u_i_Queue78_PCrdGranted (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue78_PCrdGranted__io_enq_ready),
    .io_enq_valid (Queue78_PCrdGranted__io_enq_valid),
    .io_enq_bits_pCrdType (Queue78_PCrdGranted__io_enq_bits_pCrdType),
    .io_enq_bits_srcID (Queue78_PCrdGranted__io_enq_bits_srcID),
    .io_deq_ready (Queue78_PCrdGranted__io_deq_ready),
    .io_deq_valid (i_Queue78_PCrdGranted__io_deq_valid),
    .io_deq_bits_pCrdType (i_Queue78_PCrdGranted__io_deq_bits_pCrdType),
    .io_deq_bits_srcID (i_Queue78_PCrdGranted__io_deq_bits_srcID)
  );
  task automatic drive_Queue78_PCrdGranted();
    Queue78_PCrdGranted__io_enq_valid = $urandom % 2;
    Queue78_PCrdGranted__io_enq_bits_pCrdType = rnd(4);
    Queue78_PCrdGranted__io_enq_bits_srcID = rnd(11);
    Queue78_PCrdGranted__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue78_PCrdGranted();
    checks++;
    if (g_Queue78_PCrdGranted__io_enq_ready !== i_Queue78_PCrdGranted__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue78_PCrdGranted.io_enq_ready g=%h i=%h", cyc, g_Queue78_PCrdGranted__io_enq_ready, i_Queue78_PCrdGranted__io_enq_ready);
    end
    if (g_Queue78_PCrdGranted__io_enq_ready !== p_Queue78_PCrdGranted__io_enq_ready) t_Queue78_PCrdGranted__io_enq_ready = 1'b1;
    p_Queue78_PCrdGranted__io_enq_ready = g_Queue78_PCrdGranted__io_enq_ready;
    checks++;
    if (g_Queue78_PCrdGranted__io_deq_valid !== i_Queue78_PCrdGranted__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue78_PCrdGranted.io_deq_valid g=%h i=%h", cyc, g_Queue78_PCrdGranted__io_deq_valid, i_Queue78_PCrdGranted__io_deq_valid);
    end
    if (g_Queue78_PCrdGranted__io_deq_valid !== p_Queue78_PCrdGranted__io_deq_valid) t_Queue78_PCrdGranted__io_deq_valid = 1'b1;
    p_Queue78_PCrdGranted__io_deq_valid = g_Queue78_PCrdGranted__io_deq_valid;
    checks++;
    if (g_Queue78_PCrdGranted__io_deq_bits_pCrdType !== i_Queue78_PCrdGranted__io_deq_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue78_PCrdGranted.io_deq_bits_pCrdType g=%h i=%h", cyc, g_Queue78_PCrdGranted__io_deq_bits_pCrdType, i_Queue78_PCrdGranted__io_deq_bits_pCrdType);
    end
    if (g_Queue78_PCrdGranted__io_deq_bits_pCrdType !== p_Queue78_PCrdGranted__io_deq_bits_pCrdType) t_Queue78_PCrdGranted__io_deq_bits_pCrdType = 1'b1;
    p_Queue78_PCrdGranted__io_deq_bits_pCrdType = g_Queue78_PCrdGranted__io_deq_bits_pCrdType;
    checks++;
    if (g_Queue78_PCrdGranted__io_deq_bits_srcID !== i_Queue78_PCrdGranted__io_deq_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue78_PCrdGranted.io_deq_bits_srcID g=%h i=%h", cyc, g_Queue78_PCrdGranted__io_deq_bits_srcID, i_Queue78_PCrdGranted__io_deq_bits_srcID);
    end
    if (g_Queue78_PCrdGranted__io_deq_bits_srcID !== p_Queue78_PCrdGranted__io_deq_bits_srcID) t_Queue78_PCrdGranted__io_deq_bits_srcID = 1'b1;
    p_Queue78_PCrdGranted__io_deq_bits_srcID = g_Queue78_PCrdGranted__io_deq_bits_srcID;
  endtask
  longint cov_Queue78_PCrdGranted_full = 0;
  longint cov_Queue78_PCrdGranted_enq = 0;
  longint cov_Queue78_PCrdGranted_deq = 0;
  longint cov_Queue78_PCrdGranted_enq_deq_same = 0;
  longint cov_Queue78_PCrdGranted_full_blocked = 0;
  longint cov_Queue78_PCrdGranted_enq_wrap = 0;
  longint cov_Queue78_PCrdGranted_deq_wrap = 0;
  task automatic cover_Queue78_PCrdGranted();
    if (u_g_Queue78_PCrdGranted.maybe_full && u_g_Queue78_PCrdGranted.ptr_match) cov_Queue78_PCrdGranted_full++;
    if (u_g_Queue78_PCrdGranted.do_enq) cov_Queue78_PCrdGranted_enq++;
    if (u_g_Queue78_PCrdGranted.do_deq) cov_Queue78_PCrdGranted_deq++;
    if (u_g_Queue78_PCrdGranted.do_enq && u_g_Queue78_PCrdGranted.do_deq) cov_Queue78_PCrdGranted_enq_deq_same++;
    if (u_g_Queue78_PCrdGranted.maybe_full && u_g_Queue78_PCrdGranted.ptr_match && Queue78_PCrdGranted__io_enq_valid && !Queue78_PCrdGranted__io_deq_ready) cov_Queue78_PCrdGranted_full_blocked++;
    if (u_g_Queue78_PCrdGranted.do_enq && u_g_Queue78_PCrdGranted.enq_ptr_value == 7'd77) cov_Queue78_PCrdGranted_enq_wrap++;
    if (u_g_Queue78_PCrdGranted.do_deq && u_g_Queue78_PCrdGranted.deq_ptr_value == 7'd77) cov_Queue78_PCrdGranted_deq_wrap++;
  endtask
  task automatic preinit_Queue78_PCrdGranted();
  endtask
  task automatic sync_Queue78_PCrdGranted();
    u_i_Queue78_PCrdGranted.ram_ext.Memory = u_g_Queue78_PCrdGranted.ram_ext.Memory;
  endtask

  // ======================= Queue40_L2TlbMQBundle =======================
  logic Queue40_L2TlbMQBundle__io_enq_valid;
  logic [37:0] Queue40_L2TlbMQBundle__io_enq_bits_req_info_vpn;
  logic [1:0] Queue40_L2TlbMQBundle__io_enq_bits_req_info_s2xlate;
  logic [1:0] Queue40_L2TlbMQBundle__io_enq_bits_req_info_source;
  logic Queue40_L2TlbMQBundle__io_enq_bits_isLLptw;
  logic Queue40_L2TlbMQBundle__io_deq_ready;
  logic Queue40_L2TlbMQBundle__io_flush;
  wire  g_Queue40_L2TlbMQBundle__io_enq_ready;
  wire  i_Queue40_L2TlbMQBundle__io_enq_ready;
  logic p_Queue40_L2TlbMQBundle__io_enq_ready;
  bit   t_Queue40_L2TlbMQBundle__io_enq_ready;
  wire  g_Queue40_L2TlbMQBundle__io_deq_valid;
  wire  i_Queue40_L2TlbMQBundle__io_deq_valid;
  logic p_Queue40_L2TlbMQBundle__io_deq_valid;
  bit   t_Queue40_L2TlbMQBundle__io_deq_valid;
  wire  [37:0] g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn;
  wire  [37:0] i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn;
  logic [37:0] p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn;
  wire  [1:0] g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate;
  wire  [1:0] i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate;
  logic [1:0] p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate;
  wire  [1:0] g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source;
  wire  [1:0] i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source;
  logic [1:0] p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source;
  wire  g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq;
  wire  i_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq;
  logic p_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq;
  wire  g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw;
  wire  i_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw;
  logic p_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw;
  wire  [2:0] g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId;
  wire  [2:0] i_Queue40_L2TlbMQBundle__io_deq_bits_hptwId;
  logic [2:0] p_Queue40_L2TlbMQBundle__io_deq_bits_hptwId;
  bit   t_Queue40_L2TlbMQBundle__io_deq_bits_hptwId;
  Queue40_L2TlbMQBundle u_g_Queue40_L2TlbMQBundle (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue40_L2TlbMQBundle__io_enq_ready),
    .io_enq_valid (Queue40_L2TlbMQBundle__io_enq_valid),
    .io_enq_bits_req_info_vpn (Queue40_L2TlbMQBundle__io_enq_bits_req_info_vpn),
    .io_enq_bits_req_info_s2xlate (Queue40_L2TlbMQBundle__io_enq_bits_req_info_s2xlate),
    .io_enq_bits_req_info_source (Queue40_L2TlbMQBundle__io_enq_bits_req_info_source),
    .io_enq_bits_isLLptw (Queue40_L2TlbMQBundle__io_enq_bits_isLLptw),
    .io_deq_ready (Queue40_L2TlbMQBundle__io_deq_ready),
    .io_deq_valid (g_Queue40_L2TlbMQBundle__io_deq_valid),
    .io_deq_bits_req_info_vpn (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn),
    .io_deq_bits_req_info_s2xlate (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate),
    .io_deq_bits_req_info_source (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source),
    .io_deq_bits_isHptwReq (g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq),
    .io_deq_bits_isLLptw (g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw),
    .io_deq_bits_hptwId (g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId),
    .io_flush (Queue40_L2TlbMQBundle__io_flush)
  );
  Queue40_L2TlbMQBundle_xs u_i_Queue40_L2TlbMQBundle (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue40_L2TlbMQBundle__io_enq_ready),
    .io_enq_valid (Queue40_L2TlbMQBundle__io_enq_valid),
    .io_enq_bits_req_info_vpn (Queue40_L2TlbMQBundle__io_enq_bits_req_info_vpn),
    .io_enq_bits_req_info_s2xlate (Queue40_L2TlbMQBundle__io_enq_bits_req_info_s2xlate),
    .io_enq_bits_req_info_source (Queue40_L2TlbMQBundle__io_enq_bits_req_info_source),
    .io_enq_bits_isLLptw (Queue40_L2TlbMQBundle__io_enq_bits_isLLptw),
    .io_deq_ready (Queue40_L2TlbMQBundle__io_deq_ready),
    .io_deq_valid (i_Queue40_L2TlbMQBundle__io_deq_valid),
    .io_deq_bits_req_info_vpn (i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn),
    .io_deq_bits_req_info_s2xlate (i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate),
    .io_deq_bits_req_info_source (i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source),
    .io_deq_bits_isHptwReq (i_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq),
    .io_deq_bits_isLLptw (i_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw),
    .io_deq_bits_hptwId (i_Queue40_L2TlbMQBundle__io_deq_bits_hptwId),
    .io_flush (Queue40_L2TlbMQBundle__io_flush)
  );
  task automatic drive_Queue40_L2TlbMQBundle();
    Queue40_L2TlbMQBundle__io_enq_valid = $urandom % 2;
    Queue40_L2TlbMQBundle__io_enq_bits_req_info_vpn = rnd(38);
    Queue40_L2TlbMQBundle__io_enq_bits_req_info_s2xlate = rnd(2);
    Queue40_L2TlbMQBundle__io_enq_bits_req_info_source = rnd(2);
    Queue40_L2TlbMQBundle__io_enq_bits_isLLptw = $urandom % 2;
    Queue40_L2TlbMQBundle__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
    Queue40_L2TlbMQBundle__io_flush = (($urandom % 300) == 0);
  endtask
  task automatic check_Queue40_L2TlbMQBundle();
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_enq_ready !== i_Queue40_L2TlbMQBundle__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_enq_ready g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_enq_ready, i_Queue40_L2TlbMQBundle__io_enq_ready);
    end
    if (g_Queue40_L2TlbMQBundle__io_enq_ready !== p_Queue40_L2TlbMQBundle__io_enq_ready) t_Queue40_L2TlbMQBundle__io_enq_ready = 1'b1;
    p_Queue40_L2TlbMQBundle__io_enq_ready = g_Queue40_L2TlbMQBundle__io_enq_ready;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_valid !== i_Queue40_L2TlbMQBundle__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_valid g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_valid, i_Queue40_L2TlbMQBundle__io_deq_valid);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_valid !== p_Queue40_L2TlbMQBundle__io_deq_valid) t_Queue40_L2TlbMQBundle__io_deq_valid = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_valid = g_Queue40_L2TlbMQBundle__io_deq_valid;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn !== i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_req_info_vpn g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn, i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn !== p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn) t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn = g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate !== i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_req_info_s2xlate g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate, i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate !== p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate) t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate = g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source !== i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_req_info_source g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source, i_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source !== p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source) t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source = g_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq !== i_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_isHptwReq g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq, i_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq !== p_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq) t_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq = g_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw !== i_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_isLLptw g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw, i_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw !== p_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw) t_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw = g_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw;
    checks++;
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId !== i_Queue40_L2TlbMQBundle__io_deq_bits_hptwId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue40_L2TlbMQBundle.io_deq_bits_hptwId g=%h i=%h", cyc, g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId, i_Queue40_L2TlbMQBundle__io_deq_bits_hptwId);
    end
    if (g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId !== p_Queue40_L2TlbMQBundle__io_deq_bits_hptwId) t_Queue40_L2TlbMQBundle__io_deq_bits_hptwId = 1'b1;
    p_Queue40_L2TlbMQBundle__io_deq_bits_hptwId = g_Queue40_L2TlbMQBundle__io_deq_bits_hptwId;
  endtask
  longint cov_Queue40_L2TlbMQBundle_full = 0;
  longint cov_Queue40_L2TlbMQBundle_enq = 0;
  longint cov_Queue40_L2TlbMQBundle_deq = 0;
  longint cov_Queue40_L2TlbMQBundle_enq_deq_same = 0;
  longint cov_Queue40_L2TlbMQBundle_full_blocked = 0;
  longint cov_Queue40_L2TlbMQBundle_enq_wrap = 0;
  longint cov_Queue40_L2TlbMQBundle_deq_wrap = 0;
  longint cov_Queue40_L2TlbMQBundle_flush_nonempty = 0;
  longint cov_Queue40_L2TlbMQBundle_flush_with_enq = 0;
  task automatic cover_Queue40_L2TlbMQBundle();
    if (u_g_Queue40_L2TlbMQBundle.maybe_full && u_g_Queue40_L2TlbMQBundle.ptr_match) cov_Queue40_L2TlbMQBundle_full++;
    if (u_g_Queue40_L2TlbMQBundle.do_enq) cov_Queue40_L2TlbMQBundle_enq++;
    if (u_g_Queue40_L2TlbMQBundle.do_deq) cov_Queue40_L2TlbMQBundle_deq++;
    if (u_g_Queue40_L2TlbMQBundle.do_enq && u_g_Queue40_L2TlbMQBundle.do_deq) cov_Queue40_L2TlbMQBundle_enq_deq_same++;
    if (u_g_Queue40_L2TlbMQBundle.maybe_full && u_g_Queue40_L2TlbMQBundle.ptr_match && Queue40_L2TlbMQBundle__io_enq_valid && !Queue40_L2TlbMQBundle__io_deq_ready) cov_Queue40_L2TlbMQBundle_full_blocked++;
    if (u_g_Queue40_L2TlbMQBundle.do_enq && u_g_Queue40_L2TlbMQBundle.enq_ptr_value == 6'd39) cov_Queue40_L2TlbMQBundle_enq_wrap++;
    if (u_g_Queue40_L2TlbMQBundle.do_deq && u_g_Queue40_L2TlbMQBundle.deq_ptr_value == 6'd39) cov_Queue40_L2TlbMQBundle_deq_wrap++;
    if (Queue40_L2TlbMQBundle__io_flush && !u_g_Queue40_L2TlbMQBundle.empty) cov_Queue40_L2TlbMQBundle_flush_nonempty++;
    if (Queue40_L2TlbMQBundle__io_flush && u_g_Queue40_L2TlbMQBundle.do_enq) cov_Queue40_L2TlbMQBundle_flush_with_enq++;
  endtask
  task automatic preinit_Queue40_L2TlbMQBundle();
  endtask
  task automatic sync_Queue40_L2TlbMQBundle();
    u_i_Queue40_L2TlbMQBundle.u_core.ram_ext.Memory = u_g_Queue40_L2TlbMQBundle.ram_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_Queue16_CHIREQ();
    drive_Queue16_CHIRSP();
    drive_Queue4_CHISNP();
    drive_Queue2_PCrdGranted();
    drive_Queue78_PCrdGranted();
    drive_Queue40_L2TlbMQBundle();
    #1;
    preinit_Queue16_CHIREQ();
    preinit_Queue16_CHIRSP();
    preinit_Queue4_CHISNP();
    preinit_Queue2_PCrdGranted();
    preinit_Queue78_PCrdGranted();
    preinit_Queue40_L2TlbMQBundle();
    sync_Queue16_CHIREQ();
    sync_Queue16_CHIRSP();
    sync_Queue4_CHISNP();
    sync_Queue2_PCrdGranted();
    sync_Queue78_PCrdGranted();
    sync_Queue40_L2TlbMQBundle();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_Queue16_CHIREQ();
      drive_Queue16_CHIRSP();
      drive_Queue4_CHISNP();
      drive_Queue2_PCrdGranted();
      drive_Queue78_PCrdGranted();
      drive_Queue40_L2TlbMQBundle();
      #1;
      check_Queue16_CHIREQ();
      cover_Queue16_CHIREQ();
      check_Queue16_CHIRSP();
      cover_Queue16_CHIRSP();
      check_Queue4_CHISNP();
      cover_Queue4_CHISNP();
      check_Queue2_PCrdGranted();
      cover_Queue2_PCrdGranted();
      check_Queue78_PCrdGranted();
      cover_Queue78_PCrdGranted();
      check_Queue40_L2TlbMQBundle();
      cover_Queue40_L2TlbMQBundle();
    end
    begin int tg; tg = 0;
      if (t_Queue16_CHIREQ__io_deq_valid) tg++; else $display("COV: Queue16_CHIREQ.io_deq_valid never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_qos) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_qos never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_txnID) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_txnID never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_returnNID) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_returnNID never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_stashNIDValid) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_stashNIDValid never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_returnTxnID) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_returnTxnID never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_opcode) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_opcode never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_addr) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_addr never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_ns) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_ns never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_likelyshared) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_likelyshared never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_allowRetry) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_allowRetry never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_order) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_order never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_pCrdType) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_pCrdType never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_memAttr_allocate) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_memAttr_allocate never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_memAttr_cacheable) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_memAttr_cacheable never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_memAttr_device) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_memAttr_device never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_memAttr_ewa) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_memAttr_ewa never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_snpAttr) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_snpAttr never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_lpIDWithPadding) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_lpIDWithPadding never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_snoopMe) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_snoopMe never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_expCompAck) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_expCompAck never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_tagOp) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_tagOp never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_traceTag) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_traceTag never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_mpam_perfMonGroup) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_mpam_perfMonGroup never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_mpam_partID) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_mpam_partID never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_mpam_mpamNS) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_mpam_mpamNS never toggled");
      if (t_Queue16_CHIREQ__io_deq_bits_rsvdc) tg++; else $display("COV: Queue16_CHIREQ.io_deq_bits_rsvdc never toggled");
      if (t_Queue16_CHIREQ__io_count) tg++; else $display("COV: Queue16_CHIREQ.io_count never toggled");
      $display("Queue16_CHIREQ: toggled=%0d/28 (need >= 15)", tg);
      if (tg < 15) covfail = 1;
      $display("Queue16_CHIREQ: cover full = %0d", cov_Queue16_CHIREQ_full);
      if (cov_Queue16_CHIREQ_full == 0) covfail = 1;
      $display("Queue16_CHIREQ: cover enq = %0d", cov_Queue16_CHIREQ_enq);
      if (cov_Queue16_CHIREQ_enq == 0) covfail = 1;
      $display("Queue16_CHIREQ: cover deq = %0d", cov_Queue16_CHIREQ_deq);
      if (cov_Queue16_CHIREQ_deq == 0) covfail = 1;
      $display("Queue16_CHIREQ: cover enq_deq_same = %0d", cov_Queue16_CHIREQ_enq_deq_same);
      if (cov_Queue16_CHIREQ_enq_deq_same == 0) covfail = 1;
      $display("Queue16_CHIREQ: cover full_blocked = %0d", cov_Queue16_CHIREQ_full_blocked);
      if (cov_Queue16_CHIREQ_full_blocked == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue16_CHIRSP__io_deq_valid) tg++; else $display("COV: Queue16_CHIRSP.io_deq_valid never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_qos) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_qos never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_tgtID) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_tgtID never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_txnID) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_txnID never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_opcode) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_opcode never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_respErr) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_respErr never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_resp) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_resp never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_fwdState) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_fwdState never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_cBusy) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_cBusy never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_dbID) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_dbID never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_pCrdType) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_pCrdType never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_tagOp) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_tagOp never toggled");
      if (t_Queue16_CHIRSP__io_deq_bits_traceTag) tg++; else $display("COV: Queue16_CHIRSP.io_deq_bits_traceTag never toggled");
      if (t_Queue16_CHIRSP__io_count) tg++; else $display("COV: Queue16_CHIRSP.io_count never toggled");
      $display("Queue16_CHIRSP: toggled=%0d/14 (need >= 11)", tg);
      if (tg < 11) covfail = 1;
      $display("Queue16_CHIRSP: cover full = %0d", cov_Queue16_CHIRSP_full);
      if (cov_Queue16_CHIRSP_full == 0) covfail = 1;
      $display("Queue16_CHIRSP: cover enq = %0d", cov_Queue16_CHIRSP_enq);
      if (cov_Queue16_CHIRSP_enq == 0) covfail = 1;
      $display("Queue16_CHIRSP: cover deq = %0d", cov_Queue16_CHIRSP_deq);
      if (cov_Queue16_CHIRSP_deq == 0) covfail = 1;
      $display("Queue16_CHIRSP: cover enq_deq_same = %0d", cov_Queue16_CHIRSP_enq_deq_same);
      if (cov_Queue16_CHIRSP_enq_deq_same == 0) covfail = 1;
      $display("Queue16_CHIRSP: cover full_blocked = %0d", cov_Queue16_CHIRSP_full_blocked);
      if (cov_Queue16_CHIRSP_full_blocked == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue4_CHISNP__io_enq_ready) tg++; else $display("COV: Queue4_CHISNP.io_enq_ready never toggled");
      if (t_Queue4_CHISNP__io_deq_valid) tg++; else $display("COV: Queue4_CHISNP.io_deq_valid never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_qos) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_qos never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_srcID) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_srcID never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_txnID) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_txnID never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_fwdNID) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_fwdNID never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_fwdTxnID) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_fwdTxnID never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_opcode) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_opcode never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_addr) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_addr never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_ns) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_ns never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_doNotGoToSD) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_doNotGoToSD never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_retToSrc) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_retToSrc never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_traceTag) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_traceTag never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_mpam_perfMonGroup) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_mpam_perfMonGroup never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_mpam_partID) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_mpam_partID never toggled");
      if (t_Queue4_CHISNP__io_deq_bits_mpam_mpamNS) tg++; else $display("COV: Queue4_CHISNP.io_deq_bits_mpam_mpamNS never toggled");
      if (t_Queue4_CHISNP__io_count) tg++; else $display("COV: Queue4_CHISNP.io_count never toggled");
      $display("Queue4_CHISNP: toggled=%0d/17 (need >= 17)", tg);
      if (tg < 17) covfail = 1;
      $display("Queue4_CHISNP: cover full = %0d", cov_Queue4_CHISNP_full);
      if (cov_Queue4_CHISNP_full == 0) covfail = 1;
      $display("Queue4_CHISNP: cover enq = %0d", cov_Queue4_CHISNP_enq);
      if (cov_Queue4_CHISNP_enq == 0) covfail = 1;
      $display("Queue4_CHISNP: cover deq = %0d", cov_Queue4_CHISNP_deq);
      if (cov_Queue4_CHISNP_deq == 0) covfail = 1;
      $display("Queue4_CHISNP: cover enq_deq_same = %0d", cov_Queue4_CHISNP_enq_deq_same);
      if (cov_Queue4_CHISNP_enq_deq_same == 0) covfail = 1;
      $display("Queue4_CHISNP: cover full_blocked = %0d", cov_Queue4_CHISNP_full_blocked);
      if (cov_Queue4_CHISNP_full_blocked == 0) covfail = 1;
      $display("Queue4_CHISNP: cover pipe_enq_when_full = %0d", cov_Queue4_CHISNP_pipe_enq_when_full);
      if (cov_Queue4_CHISNP_pipe_enq_when_full == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue2_PCrdGranted__io_enq_ready) tg++; else $display("COV: Queue2_PCrdGranted.io_enq_ready never toggled");
      if (t_Queue2_PCrdGranted__io_deq_valid) tg++; else $display("COV: Queue2_PCrdGranted.io_deq_valid never toggled");
      if (t_Queue2_PCrdGranted__io_deq_bits_pCrdType) tg++; else $display("COV: Queue2_PCrdGranted.io_deq_bits_pCrdType never toggled");
      if (t_Queue2_PCrdGranted__io_deq_bits_srcID) tg++; else $display("COV: Queue2_PCrdGranted.io_deq_bits_srcID never toggled");
      $display("Queue2_PCrdGranted: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("Queue2_PCrdGranted: cover full = %0d", cov_Queue2_PCrdGranted_full);
      if (cov_Queue2_PCrdGranted_full == 0) covfail = 1;
      $display("Queue2_PCrdGranted: cover enq = %0d", cov_Queue2_PCrdGranted_enq);
      if (cov_Queue2_PCrdGranted_enq == 0) covfail = 1;
      $display("Queue2_PCrdGranted: cover deq = %0d", cov_Queue2_PCrdGranted_deq);
      if (cov_Queue2_PCrdGranted_deq == 0) covfail = 1;
      $display("Queue2_PCrdGranted: cover enq_deq_same = %0d", cov_Queue2_PCrdGranted_enq_deq_same);
      if (cov_Queue2_PCrdGranted_enq_deq_same == 0) covfail = 1;
      $display("Queue2_PCrdGranted: cover full_blocked = %0d", cov_Queue2_PCrdGranted_full_blocked);
      if (cov_Queue2_PCrdGranted_full_blocked == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue78_PCrdGranted__io_enq_ready) tg++; else $display("COV: Queue78_PCrdGranted.io_enq_ready never toggled");
      if (t_Queue78_PCrdGranted__io_deq_valid) tg++; else $display("COV: Queue78_PCrdGranted.io_deq_valid never toggled");
      if (t_Queue78_PCrdGranted__io_deq_bits_pCrdType) tg++; else $display("COV: Queue78_PCrdGranted.io_deq_bits_pCrdType never toggled");
      if (t_Queue78_PCrdGranted__io_deq_bits_srcID) tg++; else $display("COV: Queue78_PCrdGranted.io_deq_bits_srcID never toggled");
      $display("Queue78_PCrdGranted: toggled=%0d/4 (need >= 4)", tg);
      if (tg < 4) covfail = 1;
      $display("Queue78_PCrdGranted: cover full = %0d", cov_Queue78_PCrdGranted_full);
      if (cov_Queue78_PCrdGranted_full == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover enq = %0d", cov_Queue78_PCrdGranted_enq);
      if (cov_Queue78_PCrdGranted_enq == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover deq = %0d", cov_Queue78_PCrdGranted_deq);
      if (cov_Queue78_PCrdGranted_deq == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover enq_deq_same = %0d", cov_Queue78_PCrdGranted_enq_deq_same);
      if (cov_Queue78_PCrdGranted_enq_deq_same == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover full_blocked = %0d", cov_Queue78_PCrdGranted_full_blocked);
      if (cov_Queue78_PCrdGranted_full_blocked == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover enq_wrap = %0d", cov_Queue78_PCrdGranted_enq_wrap);
      if (cov_Queue78_PCrdGranted_enq_wrap == 0) covfail = 1;
      $display("Queue78_PCrdGranted: cover deq_wrap = %0d", cov_Queue78_PCrdGranted_deq_wrap);
      if (cov_Queue78_PCrdGranted_deq_wrap == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue40_L2TlbMQBundle__io_enq_ready) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_enq_ready never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_valid) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_valid never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_vpn) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_req_info_vpn never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_s2xlate) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_req_info_s2xlate never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_req_info_source) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_req_info_source never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_isHptwReq) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_isHptwReq never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_isLLptw) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_isLLptw never toggled");
      if (t_Queue40_L2TlbMQBundle__io_deq_bits_hptwId) tg++; else $display("COV: Queue40_L2TlbMQBundle.io_deq_bits_hptwId never toggled");
      $display("Queue40_L2TlbMQBundle: toggled=%0d/8 (need >= 6)", tg);
      if (tg < 6) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover full = %0d", cov_Queue40_L2TlbMQBundle_full);
      if (cov_Queue40_L2TlbMQBundle_full == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover enq = %0d", cov_Queue40_L2TlbMQBundle_enq);
      if (cov_Queue40_L2TlbMQBundle_enq == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover deq = %0d", cov_Queue40_L2TlbMQBundle_deq);
      if (cov_Queue40_L2TlbMQBundle_deq == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover enq_deq_same = %0d", cov_Queue40_L2TlbMQBundle_enq_deq_same);
      if (cov_Queue40_L2TlbMQBundle_enq_deq_same == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover full_blocked = %0d", cov_Queue40_L2TlbMQBundle_full_blocked);
      if (cov_Queue40_L2TlbMQBundle_full_blocked == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover enq_wrap = %0d", cov_Queue40_L2TlbMQBundle_enq_wrap);
      if (cov_Queue40_L2TlbMQBundle_enq_wrap == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover deq_wrap = %0d", cov_Queue40_L2TlbMQBundle_deq_wrap);
      if (cov_Queue40_L2TlbMQBundle_deq_wrap == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover flush_nonempty = %0d", cov_Queue40_L2TlbMQBundle_flush_nonempty);
      if (cov_Queue40_L2TlbMQBundle_flush_nonempty == 0) covfail = 1;
      $display("Queue40_L2TlbMQBundle: cover flush_with_enq = %0d", cov_Queue40_L2TlbMQBundle_flush_with_enq);
      if (cov_Queue40_L2TlbMQBundle_flush_with_enq == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
