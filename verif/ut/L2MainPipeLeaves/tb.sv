// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：Arbiter3_CHIREQ Arbiter3_TaskBundle Arbiter3_TaskWithData Queue16_HintQueueEntry Queue4_HintQueueEntry CustomL1Hint
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

  // ======================= Arbiter3_CHIREQ =======================
  logic Arbiter3_CHIREQ__io_in_0_valid;
  logic [10:0] Arbiter3_CHIREQ__io_in_0_bits_tgtID;
  logic [10:0] Arbiter3_CHIREQ__io_in_0_bits_srcID;
  logic [11:0] Arbiter3_CHIREQ__io_in_0_bits_txnID;
  logic [6:0] Arbiter3_CHIREQ__io_in_0_bits_opcode;
  logic [47:0] Arbiter3_CHIREQ__io_in_0_bits_addr;
  logic Arbiter3_CHIREQ__io_in_0_bits_likelyshared;
  logic Arbiter3_CHIREQ__io_in_0_bits_allowRetry;
  logic [3:0] Arbiter3_CHIREQ__io_in_0_bits_pCrdType;
  logic Arbiter3_CHIREQ__io_in_0_bits_memAttr_allocate;
  logic Arbiter3_CHIREQ__io_in_0_bits_memAttr_cacheable;
  logic Arbiter3_CHIREQ__io_in_0_bits_memAttr_device;
  logic Arbiter3_CHIREQ__io_in_0_bits_memAttr_ewa;
  logic Arbiter3_CHIREQ__io_in_0_bits_expCompAck;
  logic Arbiter3_CHIREQ__io_in_1_valid;
  logic [10:0] Arbiter3_CHIREQ__io_in_1_bits_tgtID;
  logic [10:0] Arbiter3_CHIREQ__io_in_1_bits_srcID;
  logic [11:0] Arbiter3_CHIREQ__io_in_1_bits_txnID;
  logic [6:0] Arbiter3_CHIREQ__io_in_1_bits_opcode;
  logic [47:0] Arbiter3_CHIREQ__io_in_1_bits_addr;
  logic Arbiter3_CHIREQ__io_in_1_bits_likelyshared;
  logic Arbiter3_CHIREQ__io_in_1_bits_allowRetry;
  logic [3:0] Arbiter3_CHIREQ__io_in_1_bits_pCrdType;
  logic Arbiter3_CHIREQ__io_in_1_bits_memAttr_allocate;
  logic Arbiter3_CHIREQ__io_in_1_bits_memAttr_cacheable;
  logic Arbiter3_CHIREQ__io_in_1_bits_memAttr_device;
  logic Arbiter3_CHIREQ__io_in_1_bits_memAttr_ewa;
  logic Arbiter3_CHIREQ__io_in_1_bits_expCompAck;
  logic Arbiter3_CHIREQ__io_in_2_valid;
  logic [10:0] Arbiter3_CHIREQ__io_in_2_bits_tgtID;
  logic [10:0] Arbiter3_CHIREQ__io_in_2_bits_srcID;
  logic [11:0] Arbiter3_CHIREQ__io_in_2_bits_txnID;
  logic [6:0] Arbiter3_CHIREQ__io_in_2_bits_opcode;
  logic [47:0] Arbiter3_CHIREQ__io_in_2_bits_addr;
  logic Arbiter3_CHIREQ__io_in_2_bits_likelyshared;
  logic Arbiter3_CHIREQ__io_in_2_bits_allowRetry;
  logic [3:0] Arbiter3_CHIREQ__io_in_2_bits_pCrdType;
  logic Arbiter3_CHIREQ__io_in_2_bits_memAttr_allocate;
  logic Arbiter3_CHIREQ__io_in_2_bits_memAttr_cacheable;
  logic Arbiter3_CHIREQ__io_in_2_bits_memAttr_device;
  logic Arbiter3_CHIREQ__io_in_2_bits_memAttr_ewa;
  logic Arbiter3_CHIREQ__io_in_2_bits_expCompAck;
  wire  g_Arbiter3_CHIREQ__io_in_1_ready;
  wire  i_Arbiter3_CHIREQ__io_in_1_ready;
  logic p_Arbiter3_CHIREQ__io_in_1_ready;
  bit   t_Arbiter3_CHIREQ__io_in_1_ready;
  wire  g_Arbiter3_CHIREQ__io_in_2_ready;
  wire  i_Arbiter3_CHIREQ__io_in_2_ready;
  logic p_Arbiter3_CHIREQ__io_in_2_ready;
  bit   t_Arbiter3_CHIREQ__io_in_2_ready;
  wire  g_Arbiter3_CHIREQ__io_out_valid;
  wire  i_Arbiter3_CHIREQ__io_out_valid;
  logic p_Arbiter3_CHIREQ__io_out_valid;
  bit   t_Arbiter3_CHIREQ__io_out_valid;
  wire  [10:0] g_Arbiter3_CHIREQ__io_out_bits_tgtID;
  wire  [10:0] i_Arbiter3_CHIREQ__io_out_bits_tgtID;
  logic [10:0] p_Arbiter3_CHIREQ__io_out_bits_tgtID;
  bit   t_Arbiter3_CHIREQ__io_out_bits_tgtID;
  wire  [10:0] g_Arbiter3_CHIREQ__io_out_bits_srcID;
  wire  [10:0] i_Arbiter3_CHIREQ__io_out_bits_srcID;
  logic [10:0] p_Arbiter3_CHIREQ__io_out_bits_srcID;
  bit   t_Arbiter3_CHIREQ__io_out_bits_srcID;
  wire  [11:0] g_Arbiter3_CHIREQ__io_out_bits_txnID;
  wire  [11:0] i_Arbiter3_CHIREQ__io_out_bits_txnID;
  logic [11:0] p_Arbiter3_CHIREQ__io_out_bits_txnID;
  bit   t_Arbiter3_CHIREQ__io_out_bits_txnID;
  wire  [6:0] g_Arbiter3_CHIREQ__io_out_bits_opcode;
  wire  [6:0] i_Arbiter3_CHIREQ__io_out_bits_opcode;
  logic [6:0] p_Arbiter3_CHIREQ__io_out_bits_opcode;
  bit   t_Arbiter3_CHIREQ__io_out_bits_opcode;
  wire  [47:0] g_Arbiter3_CHIREQ__io_out_bits_addr;
  wire  [47:0] i_Arbiter3_CHIREQ__io_out_bits_addr;
  logic [47:0] p_Arbiter3_CHIREQ__io_out_bits_addr;
  bit   t_Arbiter3_CHIREQ__io_out_bits_addr;
  wire  g_Arbiter3_CHIREQ__io_out_bits_likelyshared;
  wire  i_Arbiter3_CHIREQ__io_out_bits_likelyshared;
  logic p_Arbiter3_CHIREQ__io_out_bits_likelyshared;
  bit   t_Arbiter3_CHIREQ__io_out_bits_likelyshared;
  wire  g_Arbiter3_CHIREQ__io_out_bits_allowRetry;
  wire  i_Arbiter3_CHIREQ__io_out_bits_allowRetry;
  logic p_Arbiter3_CHIREQ__io_out_bits_allowRetry;
  bit   t_Arbiter3_CHIREQ__io_out_bits_allowRetry;
  wire  [3:0] g_Arbiter3_CHIREQ__io_out_bits_pCrdType;
  wire  [3:0] i_Arbiter3_CHIREQ__io_out_bits_pCrdType;
  logic [3:0] p_Arbiter3_CHIREQ__io_out_bits_pCrdType;
  bit   t_Arbiter3_CHIREQ__io_out_bits_pCrdType;
  wire  g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate;
  wire  i_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate;
  logic p_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate;
  bit   t_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate;
  wire  g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable;
  wire  i_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable;
  logic p_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable;
  bit   t_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable;
  wire  g_Arbiter3_CHIREQ__io_out_bits_memAttr_device;
  wire  i_Arbiter3_CHIREQ__io_out_bits_memAttr_device;
  logic p_Arbiter3_CHIREQ__io_out_bits_memAttr_device;
  bit   t_Arbiter3_CHIREQ__io_out_bits_memAttr_device;
  wire  g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa;
  wire  i_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa;
  logic p_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa;
  bit   t_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa;
  wire  g_Arbiter3_CHIREQ__io_out_bits_expCompAck;
  wire  i_Arbiter3_CHIREQ__io_out_bits_expCompAck;
  logic p_Arbiter3_CHIREQ__io_out_bits_expCompAck;
  bit   t_Arbiter3_CHIREQ__io_out_bits_expCompAck;
  Arbiter3_CHIREQ u_g_Arbiter3_CHIREQ (
    .io_in_0_valid (Arbiter3_CHIREQ__io_in_0_valid),
    .io_in_0_bits_tgtID (Arbiter3_CHIREQ__io_in_0_bits_tgtID),
    .io_in_0_bits_srcID (Arbiter3_CHIREQ__io_in_0_bits_srcID),
    .io_in_0_bits_txnID (Arbiter3_CHIREQ__io_in_0_bits_txnID),
    .io_in_0_bits_opcode (Arbiter3_CHIREQ__io_in_0_bits_opcode),
    .io_in_0_bits_addr (Arbiter3_CHIREQ__io_in_0_bits_addr),
    .io_in_0_bits_likelyshared (Arbiter3_CHIREQ__io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry (Arbiter3_CHIREQ__io_in_0_bits_allowRetry),
    .io_in_0_bits_pCrdType (Arbiter3_CHIREQ__io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_device (Arbiter3_CHIREQ__io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_expCompAck (Arbiter3_CHIREQ__io_in_0_bits_expCompAck),
    .io_in_1_ready (g_Arbiter3_CHIREQ__io_in_1_ready),
    .io_in_1_valid (Arbiter3_CHIREQ__io_in_1_valid),
    .io_in_1_bits_tgtID (Arbiter3_CHIREQ__io_in_1_bits_tgtID),
    .io_in_1_bits_srcID (Arbiter3_CHIREQ__io_in_1_bits_srcID),
    .io_in_1_bits_txnID (Arbiter3_CHIREQ__io_in_1_bits_txnID),
    .io_in_1_bits_opcode (Arbiter3_CHIREQ__io_in_1_bits_opcode),
    .io_in_1_bits_addr (Arbiter3_CHIREQ__io_in_1_bits_addr),
    .io_in_1_bits_likelyshared (Arbiter3_CHIREQ__io_in_1_bits_likelyshared),
    .io_in_1_bits_allowRetry (Arbiter3_CHIREQ__io_in_1_bits_allowRetry),
    .io_in_1_bits_pCrdType (Arbiter3_CHIREQ__io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_1_bits_memAttr_cacheable),
    .io_in_1_bits_memAttr_device (Arbiter3_CHIREQ__io_in_1_bits_memAttr_device),
    .io_in_1_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_expCompAck (Arbiter3_CHIREQ__io_in_1_bits_expCompAck),
    .io_in_2_ready (g_Arbiter3_CHIREQ__io_in_2_ready),
    .io_in_2_valid (Arbiter3_CHIREQ__io_in_2_valid),
    .io_in_2_bits_tgtID (Arbiter3_CHIREQ__io_in_2_bits_tgtID),
    .io_in_2_bits_srcID (Arbiter3_CHIREQ__io_in_2_bits_srcID),
    .io_in_2_bits_txnID (Arbiter3_CHIREQ__io_in_2_bits_txnID),
    .io_in_2_bits_opcode (Arbiter3_CHIREQ__io_in_2_bits_opcode),
    .io_in_2_bits_addr (Arbiter3_CHIREQ__io_in_2_bits_addr),
    .io_in_2_bits_likelyshared (Arbiter3_CHIREQ__io_in_2_bits_likelyshared),
    .io_in_2_bits_allowRetry (Arbiter3_CHIREQ__io_in_2_bits_allowRetry),
    .io_in_2_bits_pCrdType (Arbiter3_CHIREQ__io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_2_bits_memAttr_cacheable),
    .io_in_2_bits_memAttr_device (Arbiter3_CHIREQ__io_in_2_bits_memAttr_device),
    .io_in_2_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_expCompAck (Arbiter3_CHIREQ__io_in_2_bits_expCompAck),
    .io_out_valid (g_Arbiter3_CHIREQ__io_out_valid),
    .io_out_bits_tgtID (g_Arbiter3_CHIREQ__io_out_bits_tgtID),
    .io_out_bits_srcID (g_Arbiter3_CHIREQ__io_out_bits_srcID),
    .io_out_bits_txnID (g_Arbiter3_CHIREQ__io_out_bits_txnID),
    .io_out_bits_opcode (g_Arbiter3_CHIREQ__io_out_bits_opcode),
    .io_out_bits_addr (g_Arbiter3_CHIREQ__io_out_bits_addr),
    .io_out_bits_likelyshared (g_Arbiter3_CHIREQ__io_out_bits_likelyshared),
    .io_out_bits_allowRetry (g_Arbiter3_CHIREQ__io_out_bits_allowRetry),
    .io_out_bits_pCrdType (g_Arbiter3_CHIREQ__io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate (g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable (g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device (g_Arbiter3_CHIREQ__io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa (g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa),
    .io_out_bits_expCompAck (g_Arbiter3_CHIREQ__io_out_bits_expCompAck)
  );
  Arbiter3_CHIREQ_xs u_i_Arbiter3_CHIREQ (
    .io_in_0_valid (Arbiter3_CHIREQ__io_in_0_valid),
    .io_in_0_bits_tgtID (Arbiter3_CHIREQ__io_in_0_bits_tgtID),
    .io_in_0_bits_srcID (Arbiter3_CHIREQ__io_in_0_bits_srcID),
    .io_in_0_bits_txnID (Arbiter3_CHIREQ__io_in_0_bits_txnID),
    .io_in_0_bits_opcode (Arbiter3_CHIREQ__io_in_0_bits_opcode),
    .io_in_0_bits_addr (Arbiter3_CHIREQ__io_in_0_bits_addr),
    .io_in_0_bits_likelyshared (Arbiter3_CHIREQ__io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry (Arbiter3_CHIREQ__io_in_0_bits_allowRetry),
    .io_in_0_bits_pCrdType (Arbiter3_CHIREQ__io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_0_bits_memAttr_cacheable),
    .io_in_0_bits_memAttr_device (Arbiter3_CHIREQ__io_in_0_bits_memAttr_device),
    .io_in_0_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_expCompAck (Arbiter3_CHIREQ__io_in_0_bits_expCompAck),
    .io_in_1_ready (i_Arbiter3_CHIREQ__io_in_1_ready),
    .io_in_1_valid (Arbiter3_CHIREQ__io_in_1_valid),
    .io_in_1_bits_tgtID (Arbiter3_CHIREQ__io_in_1_bits_tgtID),
    .io_in_1_bits_srcID (Arbiter3_CHIREQ__io_in_1_bits_srcID),
    .io_in_1_bits_txnID (Arbiter3_CHIREQ__io_in_1_bits_txnID),
    .io_in_1_bits_opcode (Arbiter3_CHIREQ__io_in_1_bits_opcode),
    .io_in_1_bits_addr (Arbiter3_CHIREQ__io_in_1_bits_addr),
    .io_in_1_bits_likelyshared (Arbiter3_CHIREQ__io_in_1_bits_likelyshared),
    .io_in_1_bits_allowRetry (Arbiter3_CHIREQ__io_in_1_bits_allowRetry),
    .io_in_1_bits_pCrdType (Arbiter3_CHIREQ__io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_1_bits_memAttr_cacheable),
    .io_in_1_bits_memAttr_device (Arbiter3_CHIREQ__io_in_1_bits_memAttr_device),
    .io_in_1_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_expCompAck (Arbiter3_CHIREQ__io_in_1_bits_expCompAck),
    .io_in_2_ready (i_Arbiter3_CHIREQ__io_in_2_ready),
    .io_in_2_valid (Arbiter3_CHIREQ__io_in_2_valid),
    .io_in_2_bits_tgtID (Arbiter3_CHIREQ__io_in_2_bits_tgtID),
    .io_in_2_bits_srcID (Arbiter3_CHIREQ__io_in_2_bits_srcID),
    .io_in_2_bits_txnID (Arbiter3_CHIREQ__io_in_2_bits_txnID),
    .io_in_2_bits_opcode (Arbiter3_CHIREQ__io_in_2_bits_opcode),
    .io_in_2_bits_addr (Arbiter3_CHIREQ__io_in_2_bits_addr),
    .io_in_2_bits_likelyshared (Arbiter3_CHIREQ__io_in_2_bits_likelyshared),
    .io_in_2_bits_allowRetry (Arbiter3_CHIREQ__io_in_2_bits_allowRetry),
    .io_in_2_bits_pCrdType (Arbiter3_CHIREQ__io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_allocate (Arbiter3_CHIREQ__io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable (Arbiter3_CHIREQ__io_in_2_bits_memAttr_cacheable),
    .io_in_2_bits_memAttr_device (Arbiter3_CHIREQ__io_in_2_bits_memAttr_device),
    .io_in_2_bits_memAttr_ewa (Arbiter3_CHIREQ__io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_expCompAck (Arbiter3_CHIREQ__io_in_2_bits_expCompAck),
    .io_out_valid (i_Arbiter3_CHIREQ__io_out_valid),
    .io_out_bits_tgtID (i_Arbiter3_CHIREQ__io_out_bits_tgtID),
    .io_out_bits_srcID (i_Arbiter3_CHIREQ__io_out_bits_srcID),
    .io_out_bits_txnID (i_Arbiter3_CHIREQ__io_out_bits_txnID),
    .io_out_bits_opcode (i_Arbiter3_CHIREQ__io_out_bits_opcode),
    .io_out_bits_addr (i_Arbiter3_CHIREQ__io_out_bits_addr),
    .io_out_bits_likelyshared (i_Arbiter3_CHIREQ__io_out_bits_likelyshared),
    .io_out_bits_allowRetry (i_Arbiter3_CHIREQ__io_out_bits_allowRetry),
    .io_out_bits_pCrdType (i_Arbiter3_CHIREQ__io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate (i_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable (i_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device (i_Arbiter3_CHIREQ__io_out_bits_memAttr_device),
    .io_out_bits_memAttr_ewa (i_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa),
    .io_out_bits_expCompAck (i_Arbiter3_CHIREQ__io_out_bits_expCompAck)
  );
  task automatic drive_Arbiter3_CHIREQ();
    Arbiter3_CHIREQ__io_in_0_valid = (($urandom % 2) == 0);
    Arbiter3_CHIREQ__io_in_0_bits_tgtID = rnd(11);
    Arbiter3_CHIREQ__io_in_0_bits_srcID = rnd(11);
    Arbiter3_CHIREQ__io_in_0_bits_txnID = rnd(12);
    Arbiter3_CHIREQ__io_in_0_bits_opcode = rnd(7);
    Arbiter3_CHIREQ__io_in_0_bits_addr = rnd(48);
    Arbiter3_CHIREQ__io_in_0_bits_likelyshared = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_allowRetry = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_pCrdType = rnd(4);
    Arbiter3_CHIREQ__io_in_0_bits_memAttr_allocate = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_memAttr_cacheable = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_memAttr_device = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_memAttr_ewa = $urandom % 2;
    Arbiter3_CHIREQ__io_in_0_bits_expCompAck = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_valid = (($urandom % 2) == 0);
    Arbiter3_CHIREQ__io_in_1_bits_tgtID = rnd(11);
    Arbiter3_CHIREQ__io_in_1_bits_srcID = rnd(11);
    Arbiter3_CHIREQ__io_in_1_bits_txnID = rnd(12);
    Arbiter3_CHIREQ__io_in_1_bits_opcode = rnd(7);
    Arbiter3_CHIREQ__io_in_1_bits_addr = rnd(48);
    Arbiter3_CHIREQ__io_in_1_bits_likelyshared = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_allowRetry = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_pCrdType = rnd(4);
    Arbiter3_CHIREQ__io_in_1_bits_memAttr_allocate = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_memAttr_cacheable = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_memAttr_device = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_memAttr_ewa = $urandom % 2;
    Arbiter3_CHIREQ__io_in_1_bits_expCompAck = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_valid = (($urandom % 2) == 0);
    Arbiter3_CHIREQ__io_in_2_bits_tgtID = rnd(11);
    Arbiter3_CHIREQ__io_in_2_bits_srcID = rnd(11);
    Arbiter3_CHIREQ__io_in_2_bits_txnID = rnd(12);
    Arbiter3_CHIREQ__io_in_2_bits_opcode = rnd(7);
    Arbiter3_CHIREQ__io_in_2_bits_addr = rnd(48);
    Arbiter3_CHIREQ__io_in_2_bits_likelyshared = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_allowRetry = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_pCrdType = rnd(4);
    Arbiter3_CHIREQ__io_in_2_bits_memAttr_allocate = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_memAttr_cacheable = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_memAttr_device = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_memAttr_ewa = $urandom % 2;
    Arbiter3_CHIREQ__io_in_2_bits_expCompAck = $urandom % 2;
  endtask
  task automatic check_Arbiter3_CHIREQ();
    checks++;
    if (g_Arbiter3_CHIREQ__io_in_1_ready !== i_Arbiter3_CHIREQ__io_in_1_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_in_1_ready g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_in_1_ready, i_Arbiter3_CHIREQ__io_in_1_ready);
    end
    if (g_Arbiter3_CHIREQ__io_in_1_ready !== p_Arbiter3_CHIREQ__io_in_1_ready) t_Arbiter3_CHIREQ__io_in_1_ready = 1'b1;
    p_Arbiter3_CHIREQ__io_in_1_ready = g_Arbiter3_CHIREQ__io_in_1_ready;
    checks++;
    if (g_Arbiter3_CHIREQ__io_in_2_ready !== i_Arbiter3_CHIREQ__io_in_2_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_in_2_ready g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_in_2_ready, i_Arbiter3_CHIREQ__io_in_2_ready);
    end
    if (g_Arbiter3_CHIREQ__io_in_2_ready !== p_Arbiter3_CHIREQ__io_in_2_ready) t_Arbiter3_CHIREQ__io_in_2_ready = 1'b1;
    p_Arbiter3_CHIREQ__io_in_2_ready = g_Arbiter3_CHIREQ__io_in_2_ready;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_valid !== i_Arbiter3_CHIREQ__io_out_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_valid g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_valid, i_Arbiter3_CHIREQ__io_out_valid);
    end
    if (g_Arbiter3_CHIREQ__io_out_valid !== p_Arbiter3_CHIREQ__io_out_valid) t_Arbiter3_CHIREQ__io_out_valid = 1'b1;
    p_Arbiter3_CHIREQ__io_out_valid = g_Arbiter3_CHIREQ__io_out_valid;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_tgtID !== i_Arbiter3_CHIREQ__io_out_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_tgtID g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_tgtID, i_Arbiter3_CHIREQ__io_out_bits_tgtID);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_tgtID !== p_Arbiter3_CHIREQ__io_out_bits_tgtID) t_Arbiter3_CHIREQ__io_out_bits_tgtID = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_tgtID = g_Arbiter3_CHIREQ__io_out_bits_tgtID;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_srcID !== i_Arbiter3_CHIREQ__io_out_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_srcID g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_srcID, i_Arbiter3_CHIREQ__io_out_bits_srcID);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_srcID !== p_Arbiter3_CHIREQ__io_out_bits_srcID) t_Arbiter3_CHIREQ__io_out_bits_srcID = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_srcID = g_Arbiter3_CHIREQ__io_out_bits_srcID;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_txnID !== i_Arbiter3_CHIREQ__io_out_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_txnID g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_txnID, i_Arbiter3_CHIREQ__io_out_bits_txnID);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_txnID !== p_Arbiter3_CHIREQ__io_out_bits_txnID) t_Arbiter3_CHIREQ__io_out_bits_txnID = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_txnID = g_Arbiter3_CHIREQ__io_out_bits_txnID;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_opcode !== i_Arbiter3_CHIREQ__io_out_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_opcode g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_opcode, i_Arbiter3_CHIREQ__io_out_bits_opcode);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_opcode !== p_Arbiter3_CHIREQ__io_out_bits_opcode) t_Arbiter3_CHIREQ__io_out_bits_opcode = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_opcode = g_Arbiter3_CHIREQ__io_out_bits_opcode;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_addr !== i_Arbiter3_CHIREQ__io_out_bits_addr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_addr g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_addr, i_Arbiter3_CHIREQ__io_out_bits_addr);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_addr !== p_Arbiter3_CHIREQ__io_out_bits_addr) t_Arbiter3_CHIREQ__io_out_bits_addr = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_addr = g_Arbiter3_CHIREQ__io_out_bits_addr;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_likelyshared !== i_Arbiter3_CHIREQ__io_out_bits_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_likelyshared g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_likelyshared, i_Arbiter3_CHIREQ__io_out_bits_likelyshared);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_likelyshared !== p_Arbiter3_CHIREQ__io_out_bits_likelyshared) t_Arbiter3_CHIREQ__io_out_bits_likelyshared = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_likelyshared = g_Arbiter3_CHIREQ__io_out_bits_likelyshared;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_allowRetry !== i_Arbiter3_CHIREQ__io_out_bits_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_allowRetry g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_allowRetry, i_Arbiter3_CHIREQ__io_out_bits_allowRetry);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_allowRetry !== p_Arbiter3_CHIREQ__io_out_bits_allowRetry) t_Arbiter3_CHIREQ__io_out_bits_allowRetry = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_allowRetry = g_Arbiter3_CHIREQ__io_out_bits_allowRetry;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_pCrdType !== i_Arbiter3_CHIREQ__io_out_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_pCrdType g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_pCrdType, i_Arbiter3_CHIREQ__io_out_bits_pCrdType);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_pCrdType !== p_Arbiter3_CHIREQ__io_out_bits_pCrdType) t_Arbiter3_CHIREQ__io_out_bits_pCrdType = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_pCrdType = g_Arbiter3_CHIREQ__io_out_bits_pCrdType;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate !== i_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_memAttr_allocate g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate, i_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate !== p_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate) t_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate = g_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable !== i_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_memAttr_cacheable g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable, i_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable !== p_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable) t_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable = g_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_device !== i_Arbiter3_CHIREQ__io_out_bits_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_memAttr_device g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_memAttr_device, i_Arbiter3_CHIREQ__io_out_bits_memAttr_device);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_device !== p_Arbiter3_CHIREQ__io_out_bits_memAttr_device) t_Arbiter3_CHIREQ__io_out_bits_memAttr_device = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_memAttr_device = g_Arbiter3_CHIREQ__io_out_bits_memAttr_device;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa !== i_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_memAttr_ewa g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa, i_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa !== p_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa) t_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa = g_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa;
    checks++;
    if (g_Arbiter3_CHIREQ__io_out_bits_expCompAck !== i_Arbiter3_CHIREQ__io_out_bits_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_CHIREQ.io_out_bits_expCompAck g=%h i=%h", cyc, g_Arbiter3_CHIREQ__io_out_bits_expCompAck, i_Arbiter3_CHIREQ__io_out_bits_expCompAck);
    end
    if (g_Arbiter3_CHIREQ__io_out_bits_expCompAck !== p_Arbiter3_CHIREQ__io_out_bits_expCompAck) t_Arbiter3_CHIREQ__io_out_bits_expCompAck = 1'b1;
    p_Arbiter3_CHIREQ__io_out_bits_expCompAck = g_Arbiter3_CHIREQ__io_out_bits_expCompAck;
  endtask
  longint cov_Arbiter3_CHIREQ_only2 = 0;
  longint cov_Arbiter3_CHIREQ_all = 0;
  task automatic cover_Arbiter3_CHIREQ();
    if (!Arbiter3_CHIREQ__io_in_0_valid && !Arbiter3_CHIREQ__io_in_1_valid && Arbiter3_CHIREQ__io_in_2_valid) cov_Arbiter3_CHIREQ_only2++;
    if (Arbiter3_CHIREQ__io_in_0_valid && Arbiter3_CHIREQ__io_in_1_valid && Arbiter3_CHIREQ__io_in_2_valid) cov_Arbiter3_CHIREQ_all++;
  endtask
  task automatic preinit_Arbiter3_CHIREQ();
  endtask
  task automatic sync_Arbiter3_CHIREQ();
  endtask

  // ======================= Arbiter3_TaskBundle =======================
  logic Arbiter3_TaskBundle__io_in_0_valid;
  logic [2:0] Arbiter3_TaskBundle__io_in_0_bits_txChannel;
  logic Arbiter3_TaskBundle__io_in_0_bits_denied;
  logic [10:0] Arbiter3_TaskBundle__io_in_0_bits_tgtID;
  logic [10:0] Arbiter3_TaskBundle__io_in_0_bits_srcID;
  logic [11:0] Arbiter3_TaskBundle__io_in_0_bits_txnID;
  logic [11:0] Arbiter3_TaskBundle__io_in_0_bits_dbID;
  logic [6:0] Arbiter3_TaskBundle__io_in_0_bits_chiOpcode;
  logic [2:0] Arbiter3_TaskBundle__io_in_0_bits_resp;
  logic [2:0] Arbiter3_TaskBundle__io_in_0_bits_fwdState;
  logic [3:0] Arbiter3_TaskBundle__io_in_0_bits_pCrdType;
  logic Arbiter3_TaskBundle__io_in_0_bits_traceTag;
  logic Arbiter3_TaskBundle__io_in_1_valid;
  logic [2:0] Arbiter3_TaskBundle__io_in_1_bits_txChannel;
  logic Arbiter3_TaskBundle__io_in_1_bits_denied;
  logic [10:0] Arbiter3_TaskBundle__io_in_1_bits_tgtID;
  logic [10:0] Arbiter3_TaskBundle__io_in_1_bits_srcID;
  logic [11:0] Arbiter3_TaskBundle__io_in_1_bits_txnID;
  logic [11:0] Arbiter3_TaskBundle__io_in_1_bits_dbID;
  logic [6:0] Arbiter3_TaskBundle__io_in_1_bits_chiOpcode;
  logic [2:0] Arbiter3_TaskBundle__io_in_1_bits_resp;
  logic [2:0] Arbiter3_TaskBundle__io_in_1_bits_fwdState;
  logic [3:0] Arbiter3_TaskBundle__io_in_1_bits_pCrdType;
  logic Arbiter3_TaskBundle__io_in_1_bits_traceTag;
  logic Arbiter3_TaskBundle__io_in_2_valid;
  logic [2:0] Arbiter3_TaskBundle__io_in_2_bits_txChannel;
  logic Arbiter3_TaskBundle__io_in_2_bits_denied;
  logic [10:0] Arbiter3_TaskBundle__io_in_2_bits_tgtID;
  logic [10:0] Arbiter3_TaskBundle__io_in_2_bits_srcID;
  logic [11:0] Arbiter3_TaskBundle__io_in_2_bits_txnID;
  logic [11:0] Arbiter3_TaskBundle__io_in_2_bits_dbID;
  logic [6:0] Arbiter3_TaskBundle__io_in_2_bits_chiOpcode;
  logic [2:0] Arbiter3_TaskBundle__io_in_2_bits_resp;
  logic [2:0] Arbiter3_TaskBundle__io_in_2_bits_fwdState;
  logic [3:0] Arbiter3_TaskBundle__io_in_2_bits_pCrdType;
  logic Arbiter3_TaskBundle__io_in_2_bits_traceTag;
  wire  g_Arbiter3_TaskBundle__io_in_1_ready;
  wire  i_Arbiter3_TaskBundle__io_in_1_ready;
  logic p_Arbiter3_TaskBundle__io_in_1_ready;
  bit   t_Arbiter3_TaskBundle__io_in_1_ready;
  wire  g_Arbiter3_TaskBundle__io_in_2_ready;
  wire  i_Arbiter3_TaskBundle__io_in_2_ready;
  logic p_Arbiter3_TaskBundle__io_in_2_ready;
  bit   t_Arbiter3_TaskBundle__io_in_2_ready;
  wire  g_Arbiter3_TaskBundle__io_out_valid;
  wire  i_Arbiter3_TaskBundle__io_out_valid;
  logic p_Arbiter3_TaskBundle__io_out_valid;
  bit   t_Arbiter3_TaskBundle__io_out_valid;
  wire  [2:0] g_Arbiter3_TaskBundle__io_out_bits_txChannel;
  wire  [2:0] i_Arbiter3_TaskBundle__io_out_bits_txChannel;
  logic [2:0] p_Arbiter3_TaskBundle__io_out_bits_txChannel;
  bit   t_Arbiter3_TaskBundle__io_out_bits_txChannel;
  wire  g_Arbiter3_TaskBundle__io_out_bits_denied;
  wire  i_Arbiter3_TaskBundle__io_out_bits_denied;
  logic p_Arbiter3_TaskBundle__io_out_bits_denied;
  bit   t_Arbiter3_TaskBundle__io_out_bits_denied;
  wire  [10:0] g_Arbiter3_TaskBundle__io_out_bits_tgtID;
  wire  [10:0] i_Arbiter3_TaskBundle__io_out_bits_tgtID;
  logic [10:0] p_Arbiter3_TaskBundle__io_out_bits_tgtID;
  bit   t_Arbiter3_TaskBundle__io_out_bits_tgtID;
  wire  [10:0] g_Arbiter3_TaskBundle__io_out_bits_srcID;
  wire  [10:0] i_Arbiter3_TaskBundle__io_out_bits_srcID;
  logic [10:0] p_Arbiter3_TaskBundle__io_out_bits_srcID;
  bit   t_Arbiter3_TaskBundle__io_out_bits_srcID;
  wire  [11:0] g_Arbiter3_TaskBundle__io_out_bits_txnID;
  wire  [11:0] i_Arbiter3_TaskBundle__io_out_bits_txnID;
  logic [11:0] p_Arbiter3_TaskBundle__io_out_bits_txnID;
  bit   t_Arbiter3_TaskBundle__io_out_bits_txnID;
  wire  [11:0] g_Arbiter3_TaskBundle__io_out_bits_dbID;
  wire  [11:0] i_Arbiter3_TaskBundle__io_out_bits_dbID;
  logic [11:0] p_Arbiter3_TaskBundle__io_out_bits_dbID;
  bit   t_Arbiter3_TaskBundle__io_out_bits_dbID;
  wire  [6:0] g_Arbiter3_TaskBundle__io_out_bits_chiOpcode;
  wire  [6:0] i_Arbiter3_TaskBundle__io_out_bits_chiOpcode;
  logic [6:0] p_Arbiter3_TaskBundle__io_out_bits_chiOpcode;
  bit   t_Arbiter3_TaskBundle__io_out_bits_chiOpcode;
  wire  [2:0] g_Arbiter3_TaskBundle__io_out_bits_resp;
  wire  [2:0] i_Arbiter3_TaskBundle__io_out_bits_resp;
  logic [2:0] p_Arbiter3_TaskBundle__io_out_bits_resp;
  bit   t_Arbiter3_TaskBundle__io_out_bits_resp;
  wire  [2:0] g_Arbiter3_TaskBundle__io_out_bits_fwdState;
  wire  [2:0] i_Arbiter3_TaskBundle__io_out_bits_fwdState;
  logic [2:0] p_Arbiter3_TaskBundle__io_out_bits_fwdState;
  bit   t_Arbiter3_TaskBundle__io_out_bits_fwdState;
  wire  [3:0] g_Arbiter3_TaskBundle__io_out_bits_pCrdType;
  wire  [3:0] i_Arbiter3_TaskBundle__io_out_bits_pCrdType;
  logic [3:0] p_Arbiter3_TaskBundle__io_out_bits_pCrdType;
  bit   t_Arbiter3_TaskBundle__io_out_bits_pCrdType;
  wire  g_Arbiter3_TaskBundle__io_out_bits_traceTag;
  wire  i_Arbiter3_TaskBundle__io_out_bits_traceTag;
  logic p_Arbiter3_TaskBundle__io_out_bits_traceTag;
  bit   t_Arbiter3_TaskBundle__io_out_bits_traceTag;
  Arbiter3_TaskBundle u_g_Arbiter3_TaskBundle (
    .io_in_0_valid (Arbiter3_TaskBundle__io_in_0_valid),
    .io_in_0_bits_txChannel (Arbiter3_TaskBundle__io_in_0_bits_txChannel),
    .io_in_0_bits_denied (Arbiter3_TaskBundle__io_in_0_bits_denied),
    .io_in_0_bits_tgtID (Arbiter3_TaskBundle__io_in_0_bits_tgtID),
    .io_in_0_bits_srcID (Arbiter3_TaskBundle__io_in_0_bits_srcID),
    .io_in_0_bits_txnID (Arbiter3_TaskBundle__io_in_0_bits_txnID),
    .io_in_0_bits_dbID (Arbiter3_TaskBundle__io_in_0_bits_dbID),
    .io_in_0_bits_chiOpcode (Arbiter3_TaskBundle__io_in_0_bits_chiOpcode),
    .io_in_0_bits_resp (Arbiter3_TaskBundle__io_in_0_bits_resp),
    .io_in_0_bits_fwdState (Arbiter3_TaskBundle__io_in_0_bits_fwdState),
    .io_in_0_bits_pCrdType (Arbiter3_TaskBundle__io_in_0_bits_pCrdType),
    .io_in_0_bits_traceTag (Arbiter3_TaskBundle__io_in_0_bits_traceTag),
    .io_in_1_ready (g_Arbiter3_TaskBundle__io_in_1_ready),
    .io_in_1_valid (Arbiter3_TaskBundle__io_in_1_valid),
    .io_in_1_bits_txChannel (Arbiter3_TaskBundle__io_in_1_bits_txChannel),
    .io_in_1_bits_denied (Arbiter3_TaskBundle__io_in_1_bits_denied),
    .io_in_1_bits_tgtID (Arbiter3_TaskBundle__io_in_1_bits_tgtID),
    .io_in_1_bits_srcID (Arbiter3_TaskBundle__io_in_1_bits_srcID),
    .io_in_1_bits_txnID (Arbiter3_TaskBundle__io_in_1_bits_txnID),
    .io_in_1_bits_dbID (Arbiter3_TaskBundle__io_in_1_bits_dbID),
    .io_in_1_bits_chiOpcode (Arbiter3_TaskBundle__io_in_1_bits_chiOpcode),
    .io_in_1_bits_resp (Arbiter3_TaskBundle__io_in_1_bits_resp),
    .io_in_1_bits_fwdState (Arbiter3_TaskBundle__io_in_1_bits_fwdState),
    .io_in_1_bits_pCrdType (Arbiter3_TaskBundle__io_in_1_bits_pCrdType),
    .io_in_1_bits_traceTag (Arbiter3_TaskBundle__io_in_1_bits_traceTag),
    .io_in_2_ready (g_Arbiter3_TaskBundle__io_in_2_ready),
    .io_in_2_valid (Arbiter3_TaskBundle__io_in_2_valid),
    .io_in_2_bits_txChannel (Arbiter3_TaskBundle__io_in_2_bits_txChannel),
    .io_in_2_bits_denied (Arbiter3_TaskBundle__io_in_2_bits_denied),
    .io_in_2_bits_tgtID (Arbiter3_TaskBundle__io_in_2_bits_tgtID),
    .io_in_2_bits_srcID (Arbiter3_TaskBundle__io_in_2_bits_srcID),
    .io_in_2_bits_txnID (Arbiter3_TaskBundle__io_in_2_bits_txnID),
    .io_in_2_bits_dbID (Arbiter3_TaskBundle__io_in_2_bits_dbID),
    .io_in_2_bits_chiOpcode (Arbiter3_TaskBundle__io_in_2_bits_chiOpcode),
    .io_in_2_bits_resp (Arbiter3_TaskBundle__io_in_2_bits_resp),
    .io_in_2_bits_fwdState (Arbiter3_TaskBundle__io_in_2_bits_fwdState),
    .io_in_2_bits_pCrdType (Arbiter3_TaskBundle__io_in_2_bits_pCrdType),
    .io_in_2_bits_traceTag (Arbiter3_TaskBundle__io_in_2_bits_traceTag),
    .io_out_valid (g_Arbiter3_TaskBundle__io_out_valid),
    .io_out_bits_txChannel (g_Arbiter3_TaskBundle__io_out_bits_txChannel),
    .io_out_bits_denied (g_Arbiter3_TaskBundle__io_out_bits_denied),
    .io_out_bits_tgtID (g_Arbiter3_TaskBundle__io_out_bits_tgtID),
    .io_out_bits_srcID (g_Arbiter3_TaskBundle__io_out_bits_srcID),
    .io_out_bits_txnID (g_Arbiter3_TaskBundle__io_out_bits_txnID),
    .io_out_bits_dbID (g_Arbiter3_TaskBundle__io_out_bits_dbID),
    .io_out_bits_chiOpcode (g_Arbiter3_TaskBundle__io_out_bits_chiOpcode),
    .io_out_bits_resp (g_Arbiter3_TaskBundle__io_out_bits_resp),
    .io_out_bits_fwdState (g_Arbiter3_TaskBundle__io_out_bits_fwdState),
    .io_out_bits_pCrdType (g_Arbiter3_TaskBundle__io_out_bits_pCrdType),
    .io_out_bits_traceTag (g_Arbiter3_TaskBundle__io_out_bits_traceTag)
  );
  Arbiter3_TaskBundle_xs u_i_Arbiter3_TaskBundle (
    .io_in_0_valid (Arbiter3_TaskBundle__io_in_0_valid),
    .io_in_0_bits_txChannel (Arbiter3_TaskBundle__io_in_0_bits_txChannel),
    .io_in_0_bits_denied (Arbiter3_TaskBundle__io_in_0_bits_denied),
    .io_in_0_bits_tgtID (Arbiter3_TaskBundle__io_in_0_bits_tgtID),
    .io_in_0_bits_srcID (Arbiter3_TaskBundle__io_in_0_bits_srcID),
    .io_in_0_bits_txnID (Arbiter3_TaskBundle__io_in_0_bits_txnID),
    .io_in_0_bits_dbID (Arbiter3_TaskBundle__io_in_0_bits_dbID),
    .io_in_0_bits_chiOpcode (Arbiter3_TaskBundle__io_in_0_bits_chiOpcode),
    .io_in_0_bits_resp (Arbiter3_TaskBundle__io_in_0_bits_resp),
    .io_in_0_bits_fwdState (Arbiter3_TaskBundle__io_in_0_bits_fwdState),
    .io_in_0_bits_pCrdType (Arbiter3_TaskBundle__io_in_0_bits_pCrdType),
    .io_in_0_bits_traceTag (Arbiter3_TaskBundle__io_in_0_bits_traceTag),
    .io_in_1_ready (i_Arbiter3_TaskBundle__io_in_1_ready),
    .io_in_1_valid (Arbiter3_TaskBundle__io_in_1_valid),
    .io_in_1_bits_txChannel (Arbiter3_TaskBundle__io_in_1_bits_txChannel),
    .io_in_1_bits_denied (Arbiter3_TaskBundle__io_in_1_bits_denied),
    .io_in_1_bits_tgtID (Arbiter3_TaskBundle__io_in_1_bits_tgtID),
    .io_in_1_bits_srcID (Arbiter3_TaskBundle__io_in_1_bits_srcID),
    .io_in_1_bits_txnID (Arbiter3_TaskBundle__io_in_1_bits_txnID),
    .io_in_1_bits_dbID (Arbiter3_TaskBundle__io_in_1_bits_dbID),
    .io_in_1_bits_chiOpcode (Arbiter3_TaskBundle__io_in_1_bits_chiOpcode),
    .io_in_1_bits_resp (Arbiter3_TaskBundle__io_in_1_bits_resp),
    .io_in_1_bits_fwdState (Arbiter3_TaskBundle__io_in_1_bits_fwdState),
    .io_in_1_bits_pCrdType (Arbiter3_TaskBundle__io_in_1_bits_pCrdType),
    .io_in_1_bits_traceTag (Arbiter3_TaskBundle__io_in_1_bits_traceTag),
    .io_in_2_ready (i_Arbiter3_TaskBundle__io_in_2_ready),
    .io_in_2_valid (Arbiter3_TaskBundle__io_in_2_valid),
    .io_in_2_bits_txChannel (Arbiter3_TaskBundle__io_in_2_bits_txChannel),
    .io_in_2_bits_denied (Arbiter3_TaskBundle__io_in_2_bits_denied),
    .io_in_2_bits_tgtID (Arbiter3_TaskBundle__io_in_2_bits_tgtID),
    .io_in_2_bits_srcID (Arbiter3_TaskBundle__io_in_2_bits_srcID),
    .io_in_2_bits_txnID (Arbiter3_TaskBundle__io_in_2_bits_txnID),
    .io_in_2_bits_dbID (Arbiter3_TaskBundle__io_in_2_bits_dbID),
    .io_in_2_bits_chiOpcode (Arbiter3_TaskBundle__io_in_2_bits_chiOpcode),
    .io_in_2_bits_resp (Arbiter3_TaskBundle__io_in_2_bits_resp),
    .io_in_2_bits_fwdState (Arbiter3_TaskBundle__io_in_2_bits_fwdState),
    .io_in_2_bits_pCrdType (Arbiter3_TaskBundle__io_in_2_bits_pCrdType),
    .io_in_2_bits_traceTag (Arbiter3_TaskBundle__io_in_2_bits_traceTag),
    .io_out_valid (i_Arbiter3_TaskBundle__io_out_valid),
    .io_out_bits_txChannel (i_Arbiter3_TaskBundle__io_out_bits_txChannel),
    .io_out_bits_denied (i_Arbiter3_TaskBundle__io_out_bits_denied),
    .io_out_bits_tgtID (i_Arbiter3_TaskBundle__io_out_bits_tgtID),
    .io_out_bits_srcID (i_Arbiter3_TaskBundle__io_out_bits_srcID),
    .io_out_bits_txnID (i_Arbiter3_TaskBundle__io_out_bits_txnID),
    .io_out_bits_dbID (i_Arbiter3_TaskBundle__io_out_bits_dbID),
    .io_out_bits_chiOpcode (i_Arbiter3_TaskBundle__io_out_bits_chiOpcode),
    .io_out_bits_resp (i_Arbiter3_TaskBundle__io_out_bits_resp),
    .io_out_bits_fwdState (i_Arbiter3_TaskBundle__io_out_bits_fwdState),
    .io_out_bits_pCrdType (i_Arbiter3_TaskBundle__io_out_bits_pCrdType),
    .io_out_bits_traceTag (i_Arbiter3_TaskBundle__io_out_bits_traceTag)
  );
  task automatic drive_Arbiter3_TaskBundle();
    Arbiter3_TaskBundle__io_in_0_valid = (($urandom % 2) == 0);
    Arbiter3_TaskBundle__io_in_0_bits_txChannel = rnd(3);
    Arbiter3_TaskBundle__io_in_0_bits_denied = $urandom % 2;
    Arbiter3_TaskBundle__io_in_0_bits_tgtID = rnd(11);
    Arbiter3_TaskBundle__io_in_0_bits_srcID = rnd(11);
    Arbiter3_TaskBundle__io_in_0_bits_txnID = rnd(12);
    Arbiter3_TaskBundle__io_in_0_bits_dbID = rnd(12);
    Arbiter3_TaskBundle__io_in_0_bits_chiOpcode = rnd(7);
    Arbiter3_TaskBundle__io_in_0_bits_resp = rnd(3);
    Arbiter3_TaskBundle__io_in_0_bits_fwdState = rnd(3);
    Arbiter3_TaskBundle__io_in_0_bits_pCrdType = rnd(4);
    Arbiter3_TaskBundle__io_in_0_bits_traceTag = $urandom % 2;
    Arbiter3_TaskBundle__io_in_1_valid = (($urandom % 2) == 0);
    Arbiter3_TaskBundle__io_in_1_bits_txChannel = rnd(3);
    Arbiter3_TaskBundle__io_in_1_bits_denied = $urandom % 2;
    Arbiter3_TaskBundle__io_in_1_bits_tgtID = rnd(11);
    Arbiter3_TaskBundle__io_in_1_bits_srcID = rnd(11);
    Arbiter3_TaskBundle__io_in_1_bits_txnID = rnd(12);
    Arbiter3_TaskBundle__io_in_1_bits_dbID = rnd(12);
    Arbiter3_TaskBundle__io_in_1_bits_chiOpcode = rnd(7);
    Arbiter3_TaskBundle__io_in_1_bits_resp = rnd(3);
    Arbiter3_TaskBundle__io_in_1_bits_fwdState = rnd(3);
    Arbiter3_TaskBundle__io_in_1_bits_pCrdType = rnd(4);
    Arbiter3_TaskBundle__io_in_1_bits_traceTag = $urandom % 2;
    Arbiter3_TaskBundle__io_in_2_valid = (($urandom % 2) == 0);
    Arbiter3_TaskBundle__io_in_2_bits_txChannel = rnd(3);
    Arbiter3_TaskBundle__io_in_2_bits_denied = $urandom % 2;
    Arbiter3_TaskBundle__io_in_2_bits_tgtID = rnd(11);
    Arbiter3_TaskBundle__io_in_2_bits_srcID = rnd(11);
    Arbiter3_TaskBundle__io_in_2_bits_txnID = rnd(12);
    Arbiter3_TaskBundle__io_in_2_bits_dbID = rnd(12);
    Arbiter3_TaskBundle__io_in_2_bits_chiOpcode = rnd(7);
    Arbiter3_TaskBundle__io_in_2_bits_resp = rnd(3);
    Arbiter3_TaskBundle__io_in_2_bits_fwdState = rnd(3);
    Arbiter3_TaskBundle__io_in_2_bits_pCrdType = rnd(4);
    Arbiter3_TaskBundle__io_in_2_bits_traceTag = $urandom % 2;
  endtask
  task automatic check_Arbiter3_TaskBundle();
    checks++;
    if (g_Arbiter3_TaskBundle__io_in_1_ready !== i_Arbiter3_TaskBundle__io_in_1_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_in_1_ready g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_in_1_ready, i_Arbiter3_TaskBundle__io_in_1_ready);
    end
    if (g_Arbiter3_TaskBundle__io_in_1_ready !== p_Arbiter3_TaskBundle__io_in_1_ready) t_Arbiter3_TaskBundle__io_in_1_ready = 1'b1;
    p_Arbiter3_TaskBundle__io_in_1_ready = g_Arbiter3_TaskBundle__io_in_1_ready;
    checks++;
    if (g_Arbiter3_TaskBundle__io_in_2_ready !== i_Arbiter3_TaskBundle__io_in_2_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_in_2_ready g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_in_2_ready, i_Arbiter3_TaskBundle__io_in_2_ready);
    end
    if (g_Arbiter3_TaskBundle__io_in_2_ready !== p_Arbiter3_TaskBundle__io_in_2_ready) t_Arbiter3_TaskBundle__io_in_2_ready = 1'b1;
    p_Arbiter3_TaskBundle__io_in_2_ready = g_Arbiter3_TaskBundle__io_in_2_ready;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_valid !== i_Arbiter3_TaskBundle__io_out_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_valid g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_valid, i_Arbiter3_TaskBundle__io_out_valid);
    end
    if (g_Arbiter3_TaskBundle__io_out_valid !== p_Arbiter3_TaskBundle__io_out_valid) t_Arbiter3_TaskBundle__io_out_valid = 1'b1;
    p_Arbiter3_TaskBundle__io_out_valid = g_Arbiter3_TaskBundle__io_out_valid;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_txChannel !== i_Arbiter3_TaskBundle__io_out_bits_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_txChannel g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_txChannel, i_Arbiter3_TaskBundle__io_out_bits_txChannel);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_txChannel !== p_Arbiter3_TaskBundle__io_out_bits_txChannel) t_Arbiter3_TaskBundle__io_out_bits_txChannel = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_txChannel = g_Arbiter3_TaskBundle__io_out_bits_txChannel;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_denied !== i_Arbiter3_TaskBundle__io_out_bits_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_denied g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_denied, i_Arbiter3_TaskBundle__io_out_bits_denied);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_denied !== p_Arbiter3_TaskBundle__io_out_bits_denied) t_Arbiter3_TaskBundle__io_out_bits_denied = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_denied = g_Arbiter3_TaskBundle__io_out_bits_denied;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_tgtID !== i_Arbiter3_TaskBundle__io_out_bits_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_tgtID g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_tgtID, i_Arbiter3_TaskBundle__io_out_bits_tgtID);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_tgtID !== p_Arbiter3_TaskBundle__io_out_bits_tgtID) t_Arbiter3_TaskBundle__io_out_bits_tgtID = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_tgtID = g_Arbiter3_TaskBundle__io_out_bits_tgtID;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_srcID !== i_Arbiter3_TaskBundle__io_out_bits_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_srcID g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_srcID, i_Arbiter3_TaskBundle__io_out_bits_srcID);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_srcID !== p_Arbiter3_TaskBundle__io_out_bits_srcID) t_Arbiter3_TaskBundle__io_out_bits_srcID = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_srcID = g_Arbiter3_TaskBundle__io_out_bits_srcID;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_txnID !== i_Arbiter3_TaskBundle__io_out_bits_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_txnID g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_txnID, i_Arbiter3_TaskBundle__io_out_bits_txnID);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_txnID !== p_Arbiter3_TaskBundle__io_out_bits_txnID) t_Arbiter3_TaskBundle__io_out_bits_txnID = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_txnID = g_Arbiter3_TaskBundle__io_out_bits_txnID;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_dbID !== i_Arbiter3_TaskBundle__io_out_bits_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_dbID g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_dbID, i_Arbiter3_TaskBundle__io_out_bits_dbID);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_dbID !== p_Arbiter3_TaskBundle__io_out_bits_dbID) t_Arbiter3_TaskBundle__io_out_bits_dbID = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_dbID = g_Arbiter3_TaskBundle__io_out_bits_dbID;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_chiOpcode !== i_Arbiter3_TaskBundle__io_out_bits_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_chiOpcode g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_chiOpcode, i_Arbiter3_TaskBundle__io_out_bits_chiOpcode);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_chiOpcode !== p_Arbiter3_TaskBundle__io_out_bits_chiOpcode) t_Arbiter3_TaskBundle__io_out_bits_chiOpcode = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_chiOpcode = g_Arbiter3_TaskBundle__io_out_bits_chiOpcode;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_resp !== i_Arbiter3_TaskBundle__io_out_bits_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_resp g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_resp, i_Arbiter3_TaskBundle__io_out_bits_resp);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_resp !== p_Arbiter3_TaskBundle__io_out_bits_resp) t_Arbiter3_TaskBundle__io_out_bits_resp = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_resp = g_Arbiter3_TaskBundle__io_out_bits_resp;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_fwdState !== i_Arbiter3_TaskBundle__io_out_bits_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_fwdState g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_fwdState, i_Arbiter3_TaskBundle__io_out_bits_fwdState);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_fwdState !== p_Arbiter3_TaskBundle__io_out_bits_fwdState) t_Arbiter3_TaskBundle__io_out_bits_fwdState = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_fwdState = g_Arbiter3_TaskBundle__io_out_bits_fwdState;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_pCrdType !== i_Arbiter3_TaskBundle__io_out_bits_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_pCrdType g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_pCrdType, i_Arbiter3_TaskBundle__io_out_bits_pCrdType);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_pCrdType !== p_Arbiter3_TaskBundle__io_out_bits_pCrdType) t_Arbiter3_TaskBundle__io_out_bits_pCrdType = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_pCrdType = g_Arbiter3_TaskBundle__io_out_bits_pCrdType;
    checks++;
    if (g_Arbiter3_TaskBundle__io_out_bits_traceTag !== i_Arbiter3_TaskBundle__io_out_bits_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskBundle.io_out_bits_traceTag g=%h i=%h", cyc, g_Arbiter3_TaskBundle__io_out_bits_traceTag, i_Arbiter3_TaskBundle__io_out_bits_traceTag);
    end
    if (g_Arbiter3_TaskBundle__io_out_bits_traceTag !== p_Arbiter3_TaskBundle__io_out_bits_traceTag) t_Arbiter3_TaskBundle__io_out_bits_traceTag = 1'b1;
    p_Arbiter3_TaskBundle__io_out_bits_traceTag = g_Arbiter3_TaskBundle__io_out_bits_traceTag;
  endtask
  longint cov_Arbiter3_TaskBundle_only2 = 0;
  longint cov_Arbiter3_TaskBundle_all = 0;
  task automatic cover_Arbiter3_TaskBundle();
    if (!Arbiter3_TaskBundle__io_in_0_valid && !Arbiter3_TaskBundle__io_in_1_valid && Arbiter3_TaskBundle__io_in_2_valid) cov_Arbiter3_TaskBundle_only2++;
    if (Arbiter3_TaskBundle__io_in_0_valid && Arbiter3_TaskBundle__io_in_1_valid && Arbiter3_TaskBundle__io_in_2_valid) cov_Arbiter3_TaskBundle_all++;
  endtask
  task automatic preinit_Arbiter3_TaskBundle();
  endtask
  task automatic sync_Arbiter3_TaskBundle();
  endtask

  // ======================= Arbiter3_TaskWithData =======================
  logic Arbiter3_TaskWithData__io_in_0_valid;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_channel;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_txChannel;
  logic [8:0] Arbiter3_TaskWithData__io_in_0_bits_task_set;
  logic [30:0] Arbiter3_TaskWithData__io_in_0_bits_task_tag;
  logic [5:0] Arbiter3_TaskWithData__io_in_0_bits_task_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_0_bits_task_vaddr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_isKeyword;
  logic [3:0] Arbiter3_TaskWithData__io_in_0_bits_task_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_param;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_size;
  logic [6:0] Arbiter3_TaskWithData__io_in_0_bits_task_sourceId;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_bufIdx;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_needProbeAckData;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_denied;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_corrupt;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_mshrTask;
  logic [7:0] Arbiter3_TaskWithData__io_in_0_bits_task_mshrId;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aliasTask;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_useProbeData;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_mshrRetry;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_readProbeDataDown;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_fromL2pft;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_needHint;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_dirty;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_way;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_meta_state;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_meta_alias;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_metaWen;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_tagWen;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_dsWen;
  logic [7:0] Arbiter3_TaskWithData__io_in_0_bits_task_wayMask;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_replTask;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_cmoTask;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_cmoAll;
  logic [4:0] Arbiter3_TaskWithData__io_in_0_bits_task_reqSource;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_mergeA;
  logic [5:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_vaddr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_isKeyword;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_param;
  logic [6:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_sourceId;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_state;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_alias;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitRelease;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToInval;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToClean;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseWithData;
  logic [7:0] Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseIdx;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_state;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_alias;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_accessed;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_tagErr;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] Arbiter3_TaskWithData__io_in_0_bits_task_tgtID;
  logic [10:0] Arbiter3_TaskWithData__io_in_0_bits_task_srcID;
  logic [11:0] Arbiter3_TaskWithData__io_in_0_bits_task_txnID;
  logic [10:0] Arbiter3_TaskWithData__io_in_0_bits_task_homeNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_0_bits_task_dbID;
  logic [10:0] Arbiter3_TaskWithData__io_in_0_bits_task_fwdNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_0_bits_task_fwdTxnID;
  logic [6:0] Arbiter3_TaskWithData__io_in_0_bits_task_chiOpcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_resp;
  logic [2:0] Arbiter3_TaskWithData__io_in_0_bits_task_fwdState;
  logic [3:0] Arbiter3_TaskWithData__io_in_0_bits_task_pCrdType;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_retToSrc;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_likelyshared;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_expCompAck;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_allowRetry;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_allocate;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_cacheable;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_device;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_ewa;
  logic Arbiter3_TaskWithData__io_in_0_bits_task_traceTag;
  logic [511:0] Arbiter3_TaskWithData__io_in_0_bits_data_data;
  logic Arbiter3_TaskWithData__io_in_1_valid;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_channel;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_txChannel;
  logic [8:0] Arbiter3_TaskWithData__io_in_1_bits_task_set;
  logic [30:0] Arbiter3_TaskWithData__io_in_1_bits_task_tag;
  logic [5:0] Arbiter3_TaskWithData__io_in_1_bits_task_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_1_bits_task_vaddr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_isKeyword;
  logic [3:0] Arbiter3_TaskWithData__io_in_1_bits_task_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_param;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_size;
  logic [6:0] Arbiter3_TaskWithData__io_in_1_bits_task_sourceId;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_bufIdx;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_needProbeAckData;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_denied;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_corrupt;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_mshrTask;
  logic [7:0] Arbiter3_TaskWithData__io_in_1_bits_task_mshrId;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aliasTask;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_useProbeData;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_mshrRetry;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_readProbeDataDown;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_fromL2pft;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_needHint;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_dirty;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_way;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_meta_state;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_meta_alias;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_metaWen;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_tagWen;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_dsWen;
  logic [7:0] Arbiter3_TaskWithData__io_in_1_bits_task_wayMask;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_replTask;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_cmoTask;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_cmoAll;
  logic [4:0] Arbiter3_TaskWithData__io_in_1_bits_task_reqSource;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_mergeA;
  logic [5:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_vaddr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_isKeyword;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_param;
  logic [6:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_sourceId;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_state;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_alias;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitRelease;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToInval;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToClean;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseWithData;
  logic [7:0] Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseIdx;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_state;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_alias;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_accessed;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_tagErr;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] Arbiter3_TaskWithData__io_in_1_bits_task_tgtID;
  logic [10:0] Arbiter3_TaskWithData__io_in_1_bits_task_srcID;
  logic [11:0] Arbiter3_TaskWithData__io_in_1_bits_task_txnID;
  logic [10:0] Arbiter3_TaskWithData__io_in_1_bits_task_homeNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_1_bits_task_dbID;
  logic [10:0] Arbiter3_TaskWithData__io_in_1_bits_task_fwdNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_1_bits_task_fwdTxnID;
  logic [6:0] Arbiter3_TaskWithData__io_in_1_bits_task_chiOpcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_resp;
  logic [2:0] Arbiter3_TaskWithData__io_in_1_bits_task_fwdState;
  logic [3:0] Arbiter3_TaskWithData__io_in_1_bits_task_pCrdType;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_retToSrc;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_likelyshared;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_expCompAck;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_allowRetry;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_allocate;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_cacheable;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_device;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_ewa;
  logic Arbiter3_TaskWithData__io_in_1_bits_task_traceTag;
  logic [511:0] Arbiter3_TaskWithData__io_in_1_bits_data_data;
  logic Arbiter3_TaskWithData__io_in_2_valid;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_channel;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_txChannel;
  logic [8:0] Arbiter3_TaskWithData__io_in_2_bits_task_set;
  logic [30:0] Arbiter3_TaskWithData__io_in_2_bits_task_tag;
  logic [5:0] Arbiter3_TaskWithData__io_in_2_bits_task_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_2_bits_task_vaddr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_isKeyword;
  logic [3:0] Arbiter3_TaskWithData__io_in_2_bits_task_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_param;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_size;
  logic [6:0] Arbiter3_TaskWithData__io_in_2_bits_task_sourceId;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_bufIdx;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_needProbeAckData;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_denied;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_corrupt;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_mshrTask;
  logic [7:0] Arbiter3_TaskWithData__io_in_2_bits_task_mshrId;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aliasTask;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_useProbeData;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_mshrRetry;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_readProbeDataDown;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_fromL2pft;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_needHint;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_dirty;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_way;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_meta_state;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_meta_alias;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_metaWen;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_tagWen;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_dsWen;
  logic [7:0] Arbiter3_TaskWithData__io_in_2_bits_task_wayMask;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_replTask;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_cmoTask;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_cmoAll;
  logic [4:0] Arbiter3_TaskWithData__io_in_2_bits_task_reqSource;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_mergeA;
  logic [5:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_off;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_alias;
  logic [43:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_vaddr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_isKeyword;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_opcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_param;
  logic [6:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_sourceId;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_state;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_alias;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_accessed;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_tagErr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dataErr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitRelease;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToInval;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToClean;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseWithData;
  logic [7:0] Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseIdx;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dirty;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_state;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_clients;
  logic [1:0] Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_alias;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetch;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_accessed;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_tagErr;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dataErr;
  logic [10:0] Arbiter3_TaskWithData__io_in_2_bits_task_tgtID;
  logic [10:0] Arbiter3_TaskWithData__io_in_2_bits_task_srcID;
  logic [11:0] Arbiter3_TaskWithData__io_in_2_bits_task_txnID;
  logic [10:0] Arbiter3_TaskWithData__io_in_2_bits_task_homeNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_2_bits_task_dbID;
  logic [10:0] Arbiter3_TaskWithData__io_in_2_bits_task_fwdNID;
  logic [11:0] Arbiter3_TaskWithData__io_in_2_bits_task_fwdTxnID;
  logic [6:0] Arbiter3_TaskWithData__io_in_2_bits_task_chiOpcode;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_resp;
  logic [2:0] Arbiter3_TaskWithData__io_in_2_bits_task_fwdState;
  logic [3:0] Arbiter3_TaskWithData__io_in_2_bits_task_pCrdType;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_retToSrc;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_likelyshared;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_expCompAck;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_allowRetry;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_allocate;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_cacheable;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_device;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_ewa;
  logic Arbiter3_TaskWithData__io_in_2_bits_task_traceTag;
  logic [511:0] Arbiter3_TaskWithData__io_in_2_bits_data_data;
  logic Arbiter3_TaskWithData__io_out_ready;
  wire  g_Arbiter3_TaskWithData__io_in_0_ready;
  wire  i_Arbiter3_TaskWithData__io_in_0_ready;
  logic p_Arbiter3_TaskWithData__io_in_0_ready;
  bit   t_Arbiter3_TaskWithData__io_in_0_ready;
  wire  g_Arbiter3_TaskWithData__io_in_1_ready;
  wire  i_Arbiter3_TaskWithData__io_in_1_ready;
  logic p_Arbiter3_TaskWithData__io_in_1_ready;
  bit   t_Arbiter3_TaskWithData__io_in_1_ready;
  wire  g_Arbiter3_TaskWithData__io_in_2_ready;
  wire  i_Arbiter3_TaskWithData__io_in_2_ready;
  logic p_Arbiter3_TaskWithData__io_in_2_ready;
  bit   t_Arbiter3_TaskWithData__io_in_2_ready;
  wire  g_Arbiter3_TaskWithData__io_out_valid;
  wire  i_Arbiter3_TaskWithData__io_out_valid;
  logic p_Arbiter3_TaskWithData__io_out_valid;
  bit   t_Arbiter3_TaskWithData__io_out_valid;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_channel;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_channel;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_channel;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_channel;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_txChannel;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_txChannel;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_txChannel;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_txChannel;
  wire  [8:0] g_Arbiter3_TaskWithData__io_out_bits_task_set;
  wire  [8:0] i_Arbiter3_TaskWithData__io_out_bits_task_set;
  logic [8:0] p_Arbiter3_TaskWithData__io_out_bits_task_set;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_set;
  wire  [30:0] g_Arbiter3_TaskWithData__io_out_bits_task_tag;
  wire  [30:0] i_Arbiter3_TaskWithData__io_out_bits_task_tag;
  logic [30:0] p_Arbiter3_TaskWithData__io_out_bits_task_tag;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_tag;
  wire  [5:0] g_Arbiter3_TaskWithData__io_out_bits_task_off;
  wire  [5:0] i_Arbiter3_TaskWithData__io_out_bits_task_off;
  logic [5:0] p_Arbiter3_TaskWithData__io_out_bits_task_off;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_off;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_alias;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_alias;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_alias;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_alias;
  wire  [43:0] g_Arbiter3_TaskWithData__io_out_bits_task_vaddr;
  wire  [43:0] i_Arbiter3_TaskWithData__io_out_bits_task_vaddr;
  logic [43:0] p_Arbiter3_TaskWithData__io_out_bits_task_vaddr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_vaddr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_isKeyword;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_isKeyword;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_isKeyword;
  wire  [3:0] g_Arbiter3_TaskWithData__io_out_bits_task_opcode;
  wire  [3:0] i_Arbiter3_TaskWithData__io_out_bits_task_opcode;
  logic [3:0] p_Arbiter3_TaskWithData__io_out_bits_task_opcode;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_opcode;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_param;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_param;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_param;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_param;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_size;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_size;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_size;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_size;
  wire  [6:0] g_Arbiter3_TaskWithData__io_out_bits_task_sourceId;
  wire  [6:0] i_Arbiter3_TaskWithData__io_out_bits_task_sourceId;
  logic [6:0] p_Arbiter3_TaskWithData__io_out_bits_task_sourceId;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_sourceId;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_bufIdx;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_bufIdx;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_bufIdx;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_denied;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_denied;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_denied;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_denied;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_corrupt;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_corrupt;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_corrupt;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_corrupt;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_mshrTask;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_mshrTask;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_mshrTask;
  wire  [7:0] g_Arbiter3_TaskWithData__io_out_bits_task_mshrId;
  wire  [7:0] i_Arbiter3_TaskWithData__io_out_bits_task_mshrId;
  logic [7:0] p_Arbiter3_TaskWithData__io_out_bits_task_mshrId;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_mshrId;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aliasTask;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aliasTask;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aliasTask;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_useProbeData;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_useProbeData;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_useProbeData;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_needHint;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_needHint;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_needHint;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_needHint;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_dirty;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_dirty;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_dirty;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_dirty;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_way;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_way;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_way;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_way;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_meta_state;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_meta_state;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_meta_state;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_state;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_clients;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_clients;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_clients;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_meta_alias;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_meta_alias;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_alias;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_metaWen;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_metaWen;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_metaWen;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_metaWen;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_tagWen;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_tagWen;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_tagWen;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_tagWen;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_dsWen;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_dsWen;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_dsWen;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_dsWen;
  wire  [7:0] g_Arbiter3_TaskWithData__io_out_bits_task_wayMask;
  wire  [7:0] i_Arbiter3_TaskWithData__io_out_bits_task_wayMask;
  logic [7:0] p_Arbiter3_TaskWithData__io_out_bits_task_wayMask;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_wayMask;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_replTask;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_replTask;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_replTask;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_replTask;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_cmoTask;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_cmoTask;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_cmoTask;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_cmoAll;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_cmoAll;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_cmoAll;
  wire  [4:0] g_Arbiter3_TaskWithData__io_out_bits_task_reqSource;
  wire  [4:0] i_Arbiter3_TaskWithData__io_out_bits_task_reqSource;
  logic [4:0] p_Arbiter3_TaskWithData__io_out_bits_task_reqSource;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_reqSource;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_mergeA;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_mergeA;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_mergeA;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_mergeA;
  wire  [5:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off;
  wire  [5:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off;
  logic [5:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias;
  wire  [43:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr;
  wire  [43:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr;
  logic [43:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param;
  wire  [6:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId;
  wire  [6:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId;
  logic [6:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData;
  wire  [7:0] g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx;
  wire  [7:0] i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx;
  logic [7:0] p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients;
  wire  [1:0] g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias;
  wire  [1:0] i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias;
  logic [1:0] p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr;
  wire  [10:0] g_Arbiter3_TaskWithData__io_out_bits_task_tgtID;
  wire  [10:0] i_Arbiter3_TaskWithData__io_out_bits_task_tgtID;
  logic [10:0] p_Arbiter3_TaskWithData__io_out_bits_task_tgtID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_tgtID;
  wire  [10:0] g_Arbiter3_TaskWithData__io_out_bits_task_srcID;
  wire  [10:0] i_Arbiter3_TaskWithData__io_out_bits_task_srcID;
  logic [10:0] p_Arbiter3_TaskWithData__io_out_bits_task_srcID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_srcID;
  wire  [11:0] g_Arbiter3_TaskWithData__io_out_bits_task_txnID;
  wire  [11:0] i_Arbiter3_TaskWithData__io_out_bits_task_txnID;
  logic [11:0] p_Arbiter3_TaskWithData__io_out_bits_task_txnID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_txnID;
  wire  [10:0] g_Arbiter3_TaskWithData__io_out_bits_task_homeNID;
  wire  [10:0] i_Arbiter3_TaskWithData__io_out_bits_task_homeNID;
  logic [10:0] p_Arbiter3_TaskWithData__io_out_bits_task_homeNID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_homeNID;
  wire  [11:0] g_Arbiter3_TaskWithData__io_out_bits_task_dbID;
  wire  [11:0] i_Arbiter3_TaskWithData__io_out_bits_task_dbID;
  logic [11:0] p_Arbiter3_TaskWithData__io_out_bits_task_dbID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_dbID;
  wire  [10:0] g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID;
  wire  [10:0] i_Arbiter3_TaskWithData__io_out_bits_task_fwdNID;
  logic [10:0] p_Arbiter3_TaskWithData__io_out_bits_task_fwdNID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_fwdNID;
  wire  [11:0] g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID;
  wire  [11:0] i_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID;
  logic [11:0] p_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID;
  wire  [6:0] g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode;
  wire  [6:0] i_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode;
  logic [6:0] p_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_resp;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_resp;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_resp;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_resp;
  wire  [2:0] g_Arbiter3_TaskWithData__io_out_bits_task_fwdState;
  wire  [2:0] i_Arbiter3_TaskWithData__io_out_bits_task_fwdState;
  logic [2:0] p_Arbiter3_TaskWithData__io_out_bits_task_fwdState;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_fwdState;
  wire  [3:0] g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType;
  wire  [3:0] i_Arbiter3_TaskWithData__io_out_bits_task_pCrdType;
  logic [3:0] p_Arbiter3_TaskWithData__io_out_bits_task_pCrdType;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_pCrdType;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_retToSrc;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_retToSrc;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_retToSrc;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_likelyshared;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_likelyshared;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_likelyshared;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_expCompAck;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_expCompAck;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_expCompAck;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_allowRetry;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_allowRetry;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_allowRetry;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa;
  wire  g_Arbiter3_TaskWithData__io_out_bits_task_traceTag;
  wire  i_Arbiter3_TaskWithData__io_out_bits_task_traceTag;
  logic p_Arbiter3_TaskWithData__io_out_bits_task_traceTag;
  bit   t_Arbiter3_TaskWithData__io_out_bits_task_traceTag;
  wire  [511:0] g_Arbiter3_TaskWithData__io_out_bits_data_data;
  wire  [511:0] i_Arbiter3_TaskWithData__io_out_bits_data_data;
  logic [511:0] p_Arbiter3_TaskWithData__io_out_bits_data_data;
  bit   t_Arbiter3_TaskWithData__io_out_bits_data_data;
  Arbiter3_TaskWithData u_g_Arbiter3_TaskWithData (
    .io_in_0_ready (g_Arbiter3_TaskWithData__io_in_0_ready),
    .io_in_0_valid (Arbiter3_TaskWithData__io_in_0_valid),
    .io_in_0_bits_task_channel (Arbiter3_TaskWithData__io_in_0_bits_task_channel),
    .io_in_0_bits_task_txChannel (Arbiter3_TaskWithData__io_in_0_bits_task_txChannel),
    .io_in_0_bits_task_set (Arbiter3_TaskWithData__io_in_0_bits_task_set),
    .io_in_0_bits_task_tag (Arbiter3_TaskWithData__io_in_0_bits_task_tag),
    .io_in_0_bits_task_off (Arbiter3_TaskWithData__io_in_0_bits_task_off),
    .io_in_0_bits_task_alias (Arbiter3_TaskWithData__io_in_0_bits_task_alias),
    .io_in_0_bits_task_vaddr (Arbiter3_TaskWithData__io_in_0_bits_task_vaddr),
    .io_in_0_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_0_bits_task_isKeyword),
    .io_in_0_bits_task_opcode (Arbiter3_TaskWithData__io_in_0_bits_task_opcode),
    .io_in_0_bits_task_param (Arbiter3_TaskWithData__io_in_0_bits_task_param),
    .io_in_0_bits_task_size (Arbiter3_TaskWithData__io_in_0_bits_task_size),
    .io_in_0_bits_task_sourceId (Arbiter3_TaskWithData__io_in_0_bits_task_sourceId),
    .io_in_0_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_0_bits_task_bufIdx),
    .io_in_0_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_0_bits_task_needProbeAckData),
    .io_in_0_bits_task_denied (Arbiter3_TaskWithData__io_in_0_bits_task_denied),
    .io_in_0_bits_task_corrupt (Arbiter3_TaskWithData__io_in_0_bits_task_corrupt),
    .io_in_0_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_0_bits_task_mshrTask),
    .io_in_0_bits_task_mshrId (Arbiter3_TaskWithData__io_in_0_bits_task_mshrId),
    .io_in_0_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_0_bits_task_aliasTask),
    .io_in_0_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_0_bits_task_useProbeData),
    .io_in_0_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_0_bits_task_mshrRetry),
    .io_in_0_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_0_bits_task_readProbeDataDown),
    .io_in_0_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_0_bits_task_fromL2pft),
    .io_in_0_bits_task_needHint (Arbiter3_TaskWithData__io_in_0_bits_task_needHint),
    .io_in_0_bits_task_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_dirty),
    .io_in_0_bits_task_way (Arbiter3_TaskWithData__io_in_0_bits_task_way),
    .io_in_0_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_meta_dirty),
    .io_in_0_bits_task_meta_state (Arbiter3_TaskWithData__io_in_0_bits_task_meta_state),
    .io_in_0_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_meta_clients),
    .io_in_0_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_meta_alias),
    .io_in_0_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetch),
    .io_in_0_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetchSrc),
    .io_in_0_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_meta_accessed),
    .io_in_0_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_meta_tagErr),
    .io_in_0_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_meta_dataErr),
    .io_in_0_bits_task_metaWen (Arbiter3_TaskWithData__io_in_0_bits_task_metaWen),
    .io_in_0_bits_task_tagWen (Arbiter3_TaskWithData__io_in_0_bits_task_tagWen),
    .io_in_0_bits_task_dsWen (Arbiter3_TaskWithData__io_in_0_bits_task_dsWen),
    .io_in_0_bits_task_wayMask (Arbiter3_TaskWithData__io_in_0_bits_task_wayMask),
    .io_in_0_bits_task_replTask (Arbiter3_TaskWithData__io_in_0_bits_task_replTask),
    .io_in_0_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_0_bits_task_cmoTask),
    .io_in_0_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_0_bits_task_cmoAll),
    .io_in_0_bits_task_reqSource (Arbiter3_TaskWithData__io_in_0_bits_task_reqSource),
    .io_in_0_bits_task_mergeA (Arbiter3_TaskWithData__io_in_0_bits_task_mergeA),
    .io_in_0_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_off),
    .io_in_0_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_alias),
    .io_in_0_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_vaddr),
    .io_in_0_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_isKeyword),
    .io_in_0_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_opcode),
    .io_in_0_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_param),
    .io_in_0_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_sourceId),
    .io_in_0_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dirty),
    .io_in_0_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_state),
    .io_in_0_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_clients),
    .io_in_0_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_alias),
    .io_in_0_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetch),
    .io_in_0_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_0_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_accessed),
    .io_in_0_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_tagErr),
    .io_in_0_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dataErr),
    .io_in_0_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitRelease),
    .io_in_0_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToInval),
    .io_in_0_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToClean),
    .io_in_0_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseWithData),
    .io_in_0_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseIdx),
    .io_in_0_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dirty),
    .io_in_0_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_state),
    .io_in_0_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_clients),
    .io_in_0_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_alias),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_accessed),
    .io_in_0_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_0_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_0_bits_task_tgtID (Arbiter3_TaskWithData__io_in_0_bits_task_tgtID),
    .io_in_0_bits_task_srcID (Arbiter3_TaskWithData__io_in_0_bits_task_srcID),
    .io_in_0_bits_task_txnID (Arbiter3_TaskWithData__io_in_0_bits_task_txnID),
    .io_in_0_bits_task_homeNID (Arbiter3_TaskWithData__io_in_0_bits_task_homeNID),
    .io_in_0_bits_task_dbID (Arbiter3_TaskWithData__io_in_0_bits_task_dbID),
    .io_in_0_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_0_bits_task_fwdNID),
    .io_in_0_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_0_bits_task_fwdTxnID),
    .io_in_0_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_0_bits_task_chiOpcode),
    .io_in_0_bits_task_resp (Arbiter3_TaskWithData__io_in_0_bits_task_resp),
    .io_in_0_bits_task_fwdState (Arbiter3_TaskWithData__io_in_0_bits_task_fwdState),
    .io_in_0_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_0_bits_task_pCrdType),
    .io_in_0_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_0_bits_task_retToSrc),
    .io_in_0_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_0_bits_task_likelyshared),
    .io_in_0_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_0_bits_task_expCompAck),
    .io_in_0_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_0_bits_task_allowRetry),
    .io_in_0_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_allocate),
    .io_in_0_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_cacheable),
    .io_in_0_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_device),
    .io_in_0_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_ewa),
    .io_in_0_bits_task_traceTag (Arbiter3_TaskWithData__io_in_0_bits_task_traceTag),
    .io_in_0_bits_data_data (Arbiter3_TaskWithData__io_in_0_bits_data_data),
    .io_in_1_ready (g_Arbiter3_TaskWithData__io_in_1_ready),
    .io_in_1_valid (Arbiter3_TaskWithData__io_in_1_valid),
    .io_in_1_bits_task_channel (Arbiter3_TaskWithData__io_in_1_bits_task_channel),
    .io_in_1_bits_task_txChannel (Arbiter3_TaskWithData__io_in_1_bits_task_txChannel),
    .io_in_1_bits_task_set (Arbiter3_TaskWithData__io_in_1_bits_task_set),
    .io_in_1_bits_task_tag (Arbiter3_TaskWithData__io_in_1_bits_task_tag),
    .io_in_1_bits_task_off (Arbiter3_TaskWithData__io_in_1_bits_task_off),
    .io_in_1_bits_task_alias (Arbiter3_TaskWithData__io_in_1_bits_task_alias),
    .io_in_1_bits_task_vaddr (Arbiter3_TaskWithData__io_in_1_bits_task_vaddr),
    .io_in_1_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_1_bits_task_isKeyword),
    .io_in_1_bits_task_opcode (Arbiter3_TaskWithData__io_in_1_bits_task_opcode),
    .io_in_1_bits_task_param (Arbiter3_TaskWithData__io_in_1_bits_task_param),
    .io_in_1_bits_task_size (Arbiter3_TaskWithData__io_in_1_bits_task_size),
    .io_in_1_bits_task_sourceId (Arbiter3_TaskWithData__io_in_1_bits_task_sourceId),
    .io_in_1_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_1_bits_task_bufIdx),
    .io_in_1_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_1_bits_task_needProbeAckData),
    .io_in_1_bits_task_denied (Arbiter3_TaskWithData__io_in_1_bits_task_denied),
    .io_in_1_bits_task_corrupt (Arbiter3_TaskWithData__io_in_1_bits_task_corrupt),
    .io_in_1_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_1_bits_task_mshrTask),
    .io_in_1_bits_task_mshrId (Arbiter3_TaskWithData__io_in_1_bits_task_mshrId),
    .io_in_1_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_1_bits_task_aliasTask),
    .io_in_1_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_1_bits_task_useProbeData),
    .io_in_1_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_1_bits_task_mshrRetry),
    .io_in_1_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_1_bits_task_readProbeDataDown),
    .io_in_1_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_1_bits_task_fromL2pft),
    .io_in_1_bits_task_needHint (Arbiter3_TaskWithData__io_in_1_bits_task_needHint),
    .io_in_1_bits_task_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_dirty),
    .io_in_1_bits_task_way (Arbiter3_TaskWithData__io_in_1_bits_task_way),
    .io_in_1_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_meta_dirty),
    .io_in_1_bits_task_meta_state (Arbiter3_TaskWithData__io_in_1_bits_task_meta_state),
    .io_in_1_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_meta_clients),
    .io_in_1_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_meta_alias),
    .io_in_1_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetch),
    .io_in_1_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetchSrc),
    .io_in_1_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_meta_accessed),
    .io_in_1_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_meta_tagErr),
    .io_in_1_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_meta_dataErr),
    .io_in_1_bits_task_metaWen (Arbiter3_TaskWithData__io_in_1_bits_task_metaWen),
    .io_in_1_bits_task_tagWen (Arbiter3_TaskWithData__io_in_1_bits_task_tagWen),
    .io_in_1_bits_task_dsWen (Arbiter3_TaskWithData__io_in_1_bits_task_dsWen),
    .io_in_1_bits_task_wayMask (Arbiter3_TaskWithData__io_in_1_bits_task_wayMask),
    .io_in_1_bits_task_replTask (Arbiter3_TaskWithData__io_in_1_bits_task_replTask),
    .io_in_1_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_1_bits_task_cmoTask),
    .io_in_1_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_1_bits_task_cmoAll),
    .io_in_1_bits_task_reqSource (Arbiter3_TaskWithData__io_in_1_bits_task_reqSource),
    .io_in_1_bits_task_mergeA (Arbiter3_TaskWithData__io_in_1_bits_task_mergeA),
    .io_in_1_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_off),
    .io_in_1_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_alias),
    .io_in_1_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_vaddr),
    .io_in_1_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_isKeyword),
    .io_in_1_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_opcode),
    .io_in_1_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_param),
    .io_in_1_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_sourceId),
    .io_in_1_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dirty),
    .io_in_1_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_state),
    .io_in_1_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_clients),
    .io_in_1_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_alias),
    .io_in_1_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetch),
    .io_in_1_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_1_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_accessed),
    .io_in_1_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_tagErr),
    .io_in_1_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dataErr),
    .io_in_1_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitRelease),
    .io_in_1_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToInval),
    .io_in_1_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToClean),
    .io_in_1_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseWithData),
    .io_in_1_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseIdx),
    .io_in_1_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dirty),
    .io_in_1_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_state),
    .io_in_1_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_clients),
    .io_in_1_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_alias),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_accessed),
    .io_in_1_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_1_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_1_bits_task_tgtID (Arbiter3_TaskWithData__io_in_1_bits_task_tgtID),
    .io_in_1_bits_task_srcID (Arbiter3_TaskWithData__io_in_1_bits_task_srcID),
    .io_in_1_bits_task_txnID (Arbiter3_TaskWithData__io_in_1_bits_task_txnID),
    .io_in_1_bits_task_homeNID (Arbiter3_TaskWithData__io_in_1_bits_task_homeNID),
    .io_in_1_bits_task_dbID (Arbiter3_TaskWithData__io_in_1_bits_task_dbID),
    .io_in_1_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_1_bits_task_fwdNID),
    .io_in_1_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_1_bits_task_fwdTxnID),
    .io_in_1_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_1_bits_task_chiOpcode),
    .io_in_1_bits_task_resp (Arbiter3_TaskWithData__io_in_1_bits_task_resp),
    .io_in_1_bits_task_fwdState (Arbiter3_TaskWithData__io_in_1_bits_task_fwdState),
    .io_in_1_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_1_bits_task_pCrdType),
    .io_in_1_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_1_bits_task_retToSrc),
    .io_in_1_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_1_bits_task_likelyshared),
    .io_in_1_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_1_bits_task_expCompAck),
    .io_in_1_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_1_bits_task_allowRetry),
    .io_in_1_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_allocate),
    .io_in_1_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_cacheable),
    .io_in_1_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_device),
    .io_in_1_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_ewa),
    .io_in_1_bits_task_traceTag (Arbiter3_TaskWithData__io_in_1_bits_task_traceTag),
    .io_in_1_bits_data_data (Arbiter3_TaskWithData__io_in_1_bits_data_data),
    .io_in_2_ready (g_Arbiter3_TaskWithData__io_in_2_ready),
    .io_in_2_valid (Arbiter3_TaskWithData__io_in_2_valid),
    .io_in_2_bits_task_channel (Arbiter3_TaskWithData__io_in_2_bits_task_channel),
    .io_in_2_bits_task_txChannel (Arbiter3_TaskWithData__io_in_2_bits_task_txChannel),
    .io_in_2_bits_task_set (Arbiter3_TaskWithData__io_in_2_bits_task_set),
    .io_in_2_bits_task_tag (Arbiter3_TaskWithData__io_in_2_bits_task_tag),
    .io_in_2_bits_task_off (Arbiter3_TaskWithData__io_in_2_bits_task_off),
    .io_in_2_bits_task_alias (Arbiter3_TaskWithData__io_in_2_bits_task_alias),
    .io_in_2_bits_task_vaddr (Arbiter3_TaskWithData__io_in_2_bits_task_vaddr),
    .io_in_2_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_2_bits_task_isKeyword),
    .io_in_2_bits_task_opcode (Arbiter3_TaskWithData__io_in_2_bits_task_opcode),
    .io_in_2_bits_task_param (Arbiter3_TaskWithData__io_in_2_bits_task_param),
    .io_in_2_bits_task_size (Arbiter3_TaskWithData__io_in_2_bits_task_size),
    .io_in_2_bits_task_sourceId (Arbiter3_TaskWithData__io_in_2_bits_task_sourceId),
    .io_in_2_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_2_bits_task_bufIdx),
    .io_in_2_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_2_bits_task_needProbeAckData),
    .io_in_2_bits_task_denied (Arbiter3_TaskWithData__io_in_2_bits_task_denied),
    .io_in_2_bits_task_corrupt (Arbiter3_TaskWithData__io_in_2_bits_task_corrupt),
    .io_in_2_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_2_bits_task_mshrTask),
    .io_in_2_bits_task_mshrId (Arbiter3_TaskWithData__io_in_2_bits_task_mshrId),
    .io_in_2_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_2_bits_task_aliasTask),
    .io_in_2_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_2_bits_task_useProbeData),
    .io_in_2_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_2_bits_task_mshrRetry),
    .io_in_2_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_2_bits_task_readProbeDataDown),
    .io_in_2_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_2_bits_task_fromL2pft),
    .io_in_2_bits_task_needHint (Arbiter3_TaskWithData__io_in_2_bits_task_needHint),
    .io_in_2_bits_task_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_dirty),
    .io_in_2_bits_task_way (Arbiter3_TaskWithData__io_in_2_bits_task_way),
    .io_in_2_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_meta_dirty),
    .io_in_2_bits_task_meta_state (Arbiter3_TaskWithData__io_in_2_bits_task_meta_state),
    .io_in_2_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_meta_clients),
    .io_in_2_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_meta_alias),
    .io_in_2_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetch),
    .io_in_2_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetchSrc),
    .io_in_2_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_meta_accessed),
    .io_in_2_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_meta_tagErr),
    .io_in_2_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_meta_dataErr),
    .io_in_2_bits_task_metaWen (Arbiter3_TaskWithData__io_in_2_bits_task_metaWen),
    .io_in_2_bits_task_tagWen (Arbiter3_TaskWithData__io_in_2_bits_task_tagWen),
    .io_in_2_bits_task_dsWen (Arbiter3_TaskWithData__io_in_2_bits_task_dsWen),
    .io_in_2_bits_task_wayMask (Arbiter3_TaskWithData__io_in_2_bits_task_wayMask),
    .io_in_2_bits_task_replTask (Arbiter3_TaskWithData__io_in_2_bits_task_replTask),
    .io_in_2_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_2_bits_task_cmoTask),
    .io_in_2_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_2_bits_task_cmoAll),
    .io_in_2_bits_task_reqSource (Arbiter3_TaskWithData__io_in_2_bits_task_reqSource),
    .io_in_2_bits_task_mergeA (Arbiter3_TaskWithData__io_in_2_bits_task_mergeA),
    .io_in_2_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_off),
    .io_in_2_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_alias),
    .io_in_2_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_vaddr),
    .io_in_2_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_isKeyword),
    .io_in_2_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_opcode),
    .io_in_2_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_param),
    .io_in_2_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_sourceId),
    .io_in_2_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dirty),
    .io_in_2_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_state),
    .io_in_2_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_clients),
    .io_in_2_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_alias),
    .io_in_2_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetch),
    .io_in_2_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_2_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_accessed),
    .io_in_2_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_tagErr),
    .io_in_2_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dataErr),
    .io_in_2_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitRelease),
    .io_in_2_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToInval),
    .io_in_2_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToClean),
    .io_in_2_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseWithData),
    .io_in_2_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseIdx),
    .io_in_2_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dirty),
    .io_in_2_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_state),
    .io_in_2_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_clients),
    .io_in_2_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_alias),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_accessed),
    .io_in_2_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_2_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_2_bits_task_tgtID (Arbiter3_TaskWithData__io_in_2_bits_task_tgtID),
    .io_in_2_bits_task_srcID (Arbiter3_TaskWithData__io_in_2_bits_task_srcID),
    .io_in_2_bits_task_txnID (Arbiter3_TaskWithData__io_in_2_bits_task_txnID),
    .io_in_2_bits_task_homeNID (Arbiter3_TaskWithData__io_in_2_bits_task_homeNID),
    .io_in_2_bits_task_dbID (Arbiter3_TaskWithData__io_in_2_bits_task_dbID),
    .io_in_2_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_2_bits_task_fwdNID),
    .io_in_2_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_2_bits_task_fwdTxnID),
    .io_in_2_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_2_bits_task_chiOpcode),
    .io_in_2_bits_task_resp (Arbiter3_TaskWithData__io_in_2_bits_task_resp),
    .io_in_2_bits_task_fwdState (Arbiter3_TaskWithData__io_in_2_bits_task_fwdState),
    .io_in_2_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_2_bits_task_pCrdType),
    .io_in_2_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_2_bits_task_retToSrc),
    .io_in_2_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_2_bits_task_likelyshared),
    .io_in_2_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_2_bits_task_expCompAck),
    .io_in_2_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_2_bits_task_allowRetry),
    .io_in_2_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_allocate),
    .io_in_2_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_cacheable),
    .io_in_2_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_device),
    .io_in_2_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_ewa),
    .io_in_2_bits_task_traceTag (Arbiter3_TaskWithData__io_in_2_bits_task_traceTag),
    .io_in_2_bits_data_data (Arbiter3_TaskWithData__io_in_2_bits_data_data),
    .io_out_ready (Arbiter3_TaskWithData__io_out_ready),
    .io_out_valid (g_Arbiter3_TaskWithData__io_out_valid),
    .io_out_bits_task_channel (g_Arbiter3_TaskWithData__io_out_bits_task_channel),
    .io_out_bits_task_txChannel (g_Arbiter3_TaskWithData__io_out_bits_task_txChannel),
    .io_out_bits_task_set (g_Arbiter3_TaskWithData__io_out_bits_task_set),
    .io_out_bits_task_tag (g_Arbiter3_TaskWithData__io_out_bits_task_tag),
    .io_out_bits_task_off (g_Arbiter3_TaskWithData__io_out_bits_task_off),
    .io_out_bits_task_alias (g_Arbiter3_TaskWithData__io_out_bits_task_alias),
    .io_out_bits_task_vaddr (g_Arbiter3_TaskWithData__io_out_bits_task_vaddr),
    .io_out_bits_task_isKeyword (g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword),
    .io_out_bits_task_opcode (g_Arbiter3_TaskWithData__io_out_bits_task_opcode),
    .io_out_bits_task_param (g_Arbiter3_TaskWithData__io_out_bits_task_param),
    .io_out_bits_task_size (g_Arbiter3_TaskWithData__io_out_bits_task_size),
    .io_out_bits_task_sourceId (g_Arbiter3_TaskWithData__io_out_bits_task_sourceId),
    .io_out_bits_task_bufIdx (g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx),
    .io_out_bits_task_needProbeAckData (g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData),
    .io_out_bits_task_denied (g_Arbiter3_TaskWithData__io_out_bits_task_denied),
    .io_out_bits_task_corrupt (g_Arbiter3_TaskWithData__io_out_bits_task_corrupt),
    .io_out_bits_task_mshrTask (g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask),
    .io_out_bits_task_mshrId (g_Arbiter3_TaskWithData__io_out_bits_task_mshrId),
    .io_out_bits_task_aliasTask (g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask),
    .io_out_bits_task_useProbeData (g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData),
    .io_out_bits_task_mshrRetry (g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry),
    .io_out_bits_task_readProbeDataDown (g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown),
    .io_out_bits_task_fromL2pft (g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft),
    .io_out_bits_task_needHint (g_Arbiter3_TaskWithData__io_out_bits_task_needHint),
    .io_out_bits_task_dirty (g_Arbiter3_TaskWithData__io_out_bits_task_dirty),
    .io_out_bits_task_way (g_Arbiter3_TaskWithData__io_out_bits_task_way),
    .io_out_bits_task_meta_dirty (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty),
    .io_out_bits_task_meta_state (g_Arbiter3_TaskWithData__io_out_bits_task_meta_state),
    .io_out_bits_task_meta_clients (g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients),
    .io_out_bits_task_meta_alias (g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias),
    .io_out_bits_task_meta_prefetch (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch),
    .io_out_bits_task_meta_prefetchSrc (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc),
    .io_out_bits_task_meta_accessed (g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed),
    .io_out_bits_task_meta_tagErr (g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr),
    .io_out_bits_task_meta_dataErr (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr),
    .io_out_bits_task_metaWen (g_Arbiter3_TaskWithData__io_out_bits_task_metaWen),
    .io_out_bits_task_tagWen (g_Arbiter3_TaskWithData__io_out_bits_task_tagWen),
    .io_out_bits_task_dsWen (g_Arbiter3_TaskWithData__io_out_bits_task_dsWen),
    .io_out_bits_task_wayMask (g_Arbiter3_TaskWithData__io_out_bits_task_wayMask),
    .io_out_bits_task_replTask (g_Arbiter3_TaskWithData__io_out_bits_task_replTask),
    .io_out_bits_task_cmoTask (g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask),
    .io_out_bits_task_cmoAll (g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll),
    .io_out_bits_task_reqSource (g_Arbiter3_TaskWithData__io_out_bits_task_reqSource),
    .io_out_bits_task_mergeA (g_Arbiter3_TaskWithData__io_out_bits_task_mergeA),
    .io_out_bits_task_aMergeTask_off (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off),
    .io_out_bits_task_aMergeTask_alias (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias),
    .io_out_bits_task_aMergeTask_vaddr (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr),
    .io_out_bits_task_aMergeTask_isKeyword (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword),
    .io_out_bits_task_aMergeTask_opcode (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode),
    .io_out_bits_task_aMergeTask_param (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param),
    .io_out_bits_task_aMergeTask_sourceId (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId),
    .io_out_bits_task_aMergeTask_meta_dirty (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty),
    .io_out_bits_task_aMergeTask_meta_state (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state),
    .io_out_bits_task_aMergeTask_meta_clients (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients),
    .io_out_bits_task_aMergeTask_meta_alias (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias),
    .io_out_bits_task_aMergeTask_meta_prefetch (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch),
    .io_out_bits_task_aMergeTask_meta_prefetchSrc (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc),
    .io_out_bits_task_aMergeTask_meta_accessed (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed),
    .io_out_bits_task_aMergeTask_meta_tagErr (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr),
    .io_out_bits_task_aMergeTask_meta_dataErr (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr),
    .io_out_bits_task_snpHitRelease (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease),
    .io_out_bits_task_snpHitReleaseToInval (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval),
    .io_out_bits_task_snpHitReleaseToClean (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean),
    .io_out_bits_task_snpHitReleaseWithData (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData),
    .io_out_bits_task_snpHitReleaseIdx (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx),
    .io_out_bits_task_snpHitReleaseMeta_dirty (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty),
    .io_out_bits_task_snpHitReleaseMeta_state (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state),
    .io_out_bits_task_snpHitReleaseMeta_clients (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients),
    .io_out_bits_task_snpHitReleaseMeta_alias (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias),
    .io_out_bits_task_snpHitReleaseMeta_prefetch (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch),
    .io_out_bits_task_snpHitReleaseMeta_prefetchSrc (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_task_snpHitReleaseMeta_accessed (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed),
    .io_out_bits_task_snpHitReleaseMeta_tagErr (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr),
    .io_out_bits_task_snpHitReleaseMeta_dataErr (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr),
    .io_out_bits_task_tgtID (g_Arbiter3_TaskWithData__io_out_bits_task_tgtID),
    .io_out_bits_task_srcID (g_Arbiter3_TaskWithData__io_out_bits_task_srcID),
    .io_out_bits_task_txnID (g_Arbiter3_TaskWithData__io_out_bits_task_txnID),
    .io_out_bits_task_homeNID (g_Arbiter3_TaskWithData__io_out_bits_task_homeNID),
    .io_out_bits_task_dbID (g_Arbiter3_TaskWithData__io_out_bits_task_dbID),
    .io_out_bits_task_fwdNID (g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID),
    .io_out_bits_task_fwdTxnID (g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID),
    .io_out_bits_task_chiOpcode (g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode),
    .io_out_bits_task_resp (g_Arbiter3_TaskWithData__io_out_bits_task_resp),
    .io_out_bits_task_fwdState (g_Arbiter3_TaskWithData__io_out_bits_task_fwdState),
    .io_out_bits_task_pCrdType (g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType),
    .io_out_bits_task_retToSrc (g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc),
    .io_out_bits_task_likelyshared (g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared),
    .io_out_bits_task_expCompAck (g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck),
    .io_out_bits_task_allowRetry (g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry),
    .io_out_bits_task_memAttr_allocate (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate),
    .io_out_bits_task_memAttr_cacheable (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable),
    .io_out_bits_task_memAttr_device (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device),
    .io_out_bits_task_memAttr_ewa (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa),
    .io_out_bits_task_traceTag (g_Arbiter3_TaskWithData__io_out_bits_task_traceTag),
    .io_out_bits_data_data (g_Arbiter3_TaskWithData__io_out_bits_data_data)
  );
  Arbiter3_TaskWithData_xs u_i_Arbiter3_TaskWithData (
    .io_in_0_ready (i_Arbiter3_TaskWithData__io_in_0_ready),
    .io_in_0_valid (Arbiter3_TaskWithData__io_in_0_valid),
    .io_in_0_bits_task_channel (Arbiter3_TaskWithData__io_in_0_bits_task_channel),
    .io_in_0_bits_task_txChannel (Arbiter3_TaskWithData__io_in_0_bits_task_txChannel),
    .io_in_0_bits_task_set (Arbiter3_TaskWithData__io_in_0_bits_task_set),
    .io_in_0_bits_task_tag (Arbiter3_TaskWithData__io_in_0_bits_task_tag),
    .io_in_0_bits_task_off (Arbiter3_TaskWithData__io_in_0_bits_task_off),
    .io_in_0_bits_task_alias (Arbiter3_TaskWithData__io_in_0_bits_task_alias),
    .io_in_0_bits_task_vaddr (Arbiter3_TaskWithData__io_in_0_bits_task_vaddr),
    .io_in_0_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_0_bits_task_isKeyword),
    .io_in_0_bits_task_opcode (Arbiter3_TaskWithData__io_in_0_bits_task_opcode),
    .io_in_0_bits_task_param (Arbiter3_TaskWithData__io_in_0_bits_task_param),
    .io_in_0_bits_task_size (Arbiter3_TaskWithData__io_in_0_bits_task_size),
    .io_in_0_bits_task_sourceId (Arbiter3_TaskWithData__io_in_0_bits_task_sourceId),
    .io_in_0_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_0_bits_task_bufIdx),
    .io_in_0_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_0_bits_task_needProbeAckData),
    .io_in_0_bits_task_denied (Arbiter3_TaskWithData__io_in_0_bits_task_denied),
    .io_in_0_bits_task_corrupt (Arbiter3_TaskWithData__io_in_0_bits_task_corrupt),
    .io_in_0_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_0_bits_task_mshrTask),
    .io_in_0_bits_task_mshrId (Arbiter3_TaskWithData__io_in_0_bits_task_mshrId),
    .io_in_0_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_0_bits_task_aliasTask),
    .io_in_0_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_0_bits_task_useProbeData),
    .io_in_0_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_0_bits_task_mshrRetry),
    .io_in_0_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_0_bits_task_readProbeDataDown),
    .io_in_0_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_0_bits_task_fromL2pft),
    .io_in_0_bits_task_needHint (Arbiter3_TaskWithData__io_in_0_bits_task_needHint),
    .io_in_0_bits_task_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_dirty),
    .io_in_0_bits_task_way (Arbiter3_TaskWithData__io_in_0_bits_task_way),
    .io_in_0_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_meta_dirty),
    .io_in_0_bits_task_meta_state (Arbiter3_TaskWithData__io_in_0_bits_task_meta_state),
    .io_in_0_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_meta_clients),
    .io_in_0_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_meta_alias),
    .io_in_0_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetch),
    .io_in_0_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetchSrc),
    .io_in_0_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_meta_accessed),
    .io_in_0_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_meta_tagErr),
    .io_in_0_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_meta_dataErr),
    .io_in_0_bits_task_metaWen (Arbiter3_TaskWithData__io_in_0_bits_task_metaWen),
    .io_in_0_bits_task_tagWen (Arbiter3_TaskWithData__io_in_0_bits_task_tagWen),
    .io_in_0_bits_task_dsWen (Arbiter3_TaskWithData__io_in_0_bits_task_dsWen),
    .io_in_0_bits_task_wayMask (Arbiter3_TaskWithData__io_in_0_bits_task_wayMask),
    .io_in_0_bits_task_replTask (Arbiter3_TaskWithData__io_in_0_bits_task_replTask),
    .io_in_0_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_0_bits_task_cmoTask),
    .io_in_0_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_0_bits_task_cmoAll),
    .io_in_0_bits_task_reqSource (Arbiter3_TaskWithData__io_in_0_bits_task_reqSource),
    .io_in_0_bits_task_mergeA (Arbiter3_TaskWithData__io_in_0_bits_task_mergeA),
    .io_in_0_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_off),
    .io_in_0_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_alias),
    .io_in_0_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_vaddr),
    .io_in_0_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_isKeyword),
    .io_in_0_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_opcode),
    .io_in_0_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_param),
    .io_in_0_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_sourceId),
    .io_in_0_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dirty),
    .io_in_0_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_state),
    .io_in_0_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_clients),
    .io_in_0_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_alias),
    .io_in_0_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetch),
    .io_in_0_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_0_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_accessed),
    .io_in_0_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_tagErr),
    .io_in_0_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dataErr),
    .io_in_0_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitRelease),
    .io_in_0_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToInval),
    .io_in_0_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToClean),
    .io_in_0_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseWithData),
    .io_in_0_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseIdx),
    .io_in_0_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dirty),
    .io_in_0_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_state),
    .io_in_0_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_clients),
    .io_in_0_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_alias),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_accessed),
    .io_in_0_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_0_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_0_bits_task_tgtID (Arbiter3_TaskWithData__io_in_0_bits_task_tgtID),
    .io_in_0_bits_task_srcID (Arbiter3_TaskWithData__io_in_0_bits_task_srcID),
    .io_in_0_bits_task_txnID (Arbiter3_TaskWithData__io_in_0_bits_task_txnID),
    .io_in_0_bits_task_homeNID (Arbiter3_TaskWithData__io_in_0_bits_task_homeNID),
    .io_in_0_bits_task_dbID (Arbiter3_TaskWithData__io_in_0_bits_task_dbID),
    .io_in_0_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_0_bits_task_fwdNID),
    .io_in_0_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_0_bits_task_fwdTxnID),
    .io_in_0_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_0_bits_task_chiOpcode),
    .io_in_0_bits_task_resp (Arbiter3_TaskWithData__io_in_0_bits_task_resp),
    .io_in_0_bits_task_fwdState (Arbiter3_TaskWithData__io_in_0_bits_task_fwdState),
    .io_in_0_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_0_bits_task_pCrdType),
    .io_in_0_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_0_bits_task_retToSrc),
    .io_in_0_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_0_bits_task_likelyshared),
    .io_in_0_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_0_bits_task_expCompAck),
    .io_in_0_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_0_bits_task_allowRetry),
    .io_in_0_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_allocate),
    .io_in_0_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_cacheable),
    .io_in_0_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_device),
    .io_in_0_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_ewa),
    .io_in_0_bits_task_traceTag (Arbiter3_TaskWithData__io_in_0_bits_task_traceTag),
    .io_in_0_bits_data_data (Arbiter3_TaskWithData__io_in_0_bits_data_data),
    .io_in_1_ready (i_Arbiter3_TaskWithData__io_in_1_ready),
    .io_in_1_valid (Arbiter3_TaskWithData__io_in_1_valid),
    .io_in_1_bits_task_channel (Arbiter3_TaskWithData__io_in_1_bits_task_channel),
    .io_in_1_bits_task_txChannel (Arbiter3_TaskWithData__io_in_1_bits_task_txChannel),
    .io_in_1_bits_task_set (Arbiter3_TaskWithData__io_in_1_bits_task_set),
    .io_in_1_bits_task_tag (Arbiter3_TaskWithData__io_in_1_bits_task_tag),
    .io_in_1_bits_task_off (Arbiter3_TaskWithData__io_in_1_bits_task_off),
    .io_in_1_bits_task_alias (Arbiter3_TaskWithData__io_in_1_bits_task_alias),
    .io_in_1_bits_task_vaddr (Arbiter3_TaskWithData__io_in_1_bits_task_vaddr),
    .io_in_1_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_1_bits_task_isKeyword),
    .io_in_1_bits_task_opcode (Arbiter3_TaskWithData__io_in_1_bits_task_opcode),
    .io_in_1_bits_task_param (Arbiter3_TaskWithData__io_in_1_bits_task_param),
    .io_in_1_bits_task_size (Arbiter3_TaskWithData__io_in_1_bits_task_size),
    .io_in_1_bits_task_sourceId (Arbiter3_TaskWithData__io_in_1_bits_task_sourceId),
    .io_in_1_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_1_bits_task_bufIdx),
    .io_in_1_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_1_bits_task_needProbeAckData),
    .io_in_1_bits_task_denied (Arbiter3_TaskWithData__io_in_1_bits_task_denied),
    .io_in_1_bits_task_corrupt (Arbiter3_TaskWithData__io_in_1_bits_task_corrupt),
    .io_in_1_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_1_bits_task_mshrTask),
    .io_in_1_bits_task_mshrId (Arbiter3_TaskWithData__io_in_1_bits_task_mshrId),
    .io_in_1_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_1_bits_task_aliasTask),
    .io_in_1_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_1_bits_task_useProbeData),
    .io_in_1_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_1_bits_task_mshrRetry),
    .io_in_1_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_1_bits_task_readProbeDataDown),
    .io_in_1_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_1_bits_task_fromL2pft),
    .io_in_1_bits_task_needHint (Arbiter3_TaskWithData__io_in_1_bits_task_needHint),
    .io_in_1_bits_task_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_dirty),
    .io_in_1_bits_task_way (Arbiter3_TaskWithData__io_in_1_bits_task_way),
    .io_in_1_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_meta_dirty),
    .io_in_1_bits_task_meta_state (Arbiter3_TaskWithData__io_in_1_bits_task_meta_state),
    .io_in_1_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_meta_clients),
    .io_in_1_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_meta_alias),
    .io_in_1_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetch),
    .io_in_1_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetchSrc),
    .io_in_1_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_meta_accessed),
    .io_in_1_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_meta_tagErr),
    .io_in_1_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_meta_dataErr),
    .io_in_1_bits_task_metaWen (Arbiter3_TaskWithData__io_in_1_bits_task_metaWen),
    .io_in_1_bits_task_tagWen (Arbiter3_TaskWithData__io_in_1_bits_task_tagWen),
    .io_in_1_bits_task_dsWen (Arbiter3_TaskWithData__io_in_1_bits_task_dsWen),
    .io_in_1_bits_task_wayMask (Arbiter3_TaskWithData__io_in_1_bits_task_wayMask),
    .io_in_1_bits_task_replTask (Arbiter3_TaskWithData__io_in_1_bits_task_replTask),
    .io_in_1_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_1_bits_task_cmoTask),
    .io_in_1_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_1_bits_task_cmoAll),
    .io_in_1_bits_task_reqSource (Arbiter3_TaskWithData__io_in_1_bits_task_reqSource),
    .io_in_1_bits_task_mergeA (Arbiter3_TaskWithData__io_in_1_bits_task_mergeA),
    .io_in_1_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_off),
    .io_in_1_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_alias),
    .io_in_1_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_vaddr),
    .io_in_1_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_isKeyword),
    .io_in_1_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_opcode),
    .io_in_1_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_param),
    .io_in_1_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_sourceId),
    .io_in_1_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dirty),
    .io_in_1_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_state),
    .io_in_1_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_clients),
    .io_in_1_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_alias),
    .io_in_1_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetch),
    .io_in_1_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_1_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_accessed),
    .io_in_1_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_tagErr),
    .io_in_1_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dataErr),
    .io_in_1_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitRelease),
    .io_in_1_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToInval),
    .io_in_1_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToClean),
    .io_in_1_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseWithData),
    .io_in_1_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseIdx),
    .io_in_1_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dirty),
    .io_in_1_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_state),
    .io_in_1_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_clients),
    .io_in_1_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_alias),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_accessed),
    .io_in_1_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_1_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_1_bits_task_tgtID (Arbiter3_TaskWithData__io_in_1_bits_task_tgtID),
    .io_in_1_bits_task_srcID (Arbiter3_TaskWithData__io_in_1_bits_task_srcID),
    .io_in_1_bits_task_txnID (Arbiter3_TaskWithData__io_in_1_bits_task_txnID),
    .io_in_1_bits_task_homeNID (Arbiter3_TaskWithData__io_in_1_bits_task_homeNID),
    .io_in_1_bits_task_dbID (Arbiter3_TaskWithData__io_in_1_bits_task_dbID),
    .io_in_1_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_1_bits_task_fwdNID),
    .io_in_1_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_1_bits_task_fwdTxnID),
    .io_in_1_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_1_bits_task_chiOpcode),
    .io_in_1_bits_task_resp (Arbiter3_TaskWithData__io_in_1_bits_task_resp),
    .io_in_1_bits_task_fwdState (Arbiter3_TaskWithData__io_in_1_bits_task_fwdState),
    .io_in_1_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_1_bits_task_pCrdType),
    .io_in_1_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_1_bits_task_retToSrc),
    .io_in_1_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_1_bits_task_likelyshared),
    .io_in_1_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_1_bits_task_expCompAck),
    .io_in_1_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_1_bits_task_allowRetry),
    .io_in_1_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_allocate),
    .io_in_1_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_cacheable),
    .io_in_1_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_device),
    .io_in_1_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_ewa),
    .io_in_1_bits_task_traceTag (Arbiter3_TaskWithData__io_in_1_bits_task_traceTag),
    .io_in_1_bits_data_data (Arbiter3_TaskWithData__io_in_1_bits_data_data),
    .io_in_2_ready (i_Arbiter3_TaskWithData__io_in_2_ready),
    .io_in_2_valid (Arbiter3_TaskWithData__io_in_2_valid),
    .io_in_2_bits_task_channel (Arbiter3_TaskWithData__io_in_2_bits_task_channel),
    .io_in_2_bits_task_txChannel (Arbiter3_TaskWithData__io_in_2_bits_task_txChannel),
    .io_in_2_bits_task_set (Arbiter3_TaskWithData__io_in_2_bits_task_set),
    .io_in_2_bits_task_tag (Arbiter3_TaskWithData__io_in_2_bits_task_tag),
    .io_in_2_bits_task_off (Arbiter3_TaskWithData__io_in_2_bits_task_off),
    .io_in_2_bits_task_alias (Arbiter3_TaskWithData__io_in_2_bits_task_alias),
    .io_in_2_bits_task_vaddr (Arbiter3_TaskWithData__io_in_2_bits_task_vaddr),
    .io_in_2_bits_task_isKeyword (Arbiter3_TaskWithData__io_in_2_bits_task_isKeyword),
    .io_in_2_bits_task_opcode (Arbiter3_TaskWithData__io_in_2_bits_task_opcode),
    .io_in_2_bits_task_param (Arbiter3_TaskWithData__io_in_2_bits_task_param),
    .io_in_2_bits_task_size (Arbiter3_TaskWithData__io_in_2_bits_task_size),
    .io_in_2_bits_task_sourceId (Arbiter3_TaskWithData__io_in_2_bits_task_sourceId),
    .io_in_2_bits_task_bufIdx (Arbiter3_TaskWithData__io_in_2_bits_task_bufIdx),
    .io_in_2_bits_task_needProbeAckData (Arbiter3_TaskWithData__io_in_2_bits_task_needProbeAckData),
    .io_in_2_bits_task_denied (Arbiter3_TaskWithData__io_in_2_bits_task_denied),
    .io_in_2_bits_task_corrupt (Arbiter3_TaskWithData__io_in_2_bits_task_corrupt),
    .io_in_2_bits_task_mshrTask (Arbiter3_TaskWithData__io_in_2_bits_task_mshrTask),
    .io_in_2_bits_task_mshrId (Arbiter3_TaskWithData__io_in_2_bits_task_mshrId),
    .io_in_2_bits_task_aliasTask (Arbiter3_TaskWithData__io_in_2_bits_task_aliasTask),
    .io_in_2_bits_task_useProbeData (Arbiter3_TaskWithData__io_in_2_bits_task_useProbeData),
    .io_in_2_bits_task_mshrRetry (Arbiter3_TaskWithData__io_in_2_bits_task_mshrRetry),
    .io_in_2_bits_task_readProbeDataDown (Arbiter3_TaskWithData__io_in_2_bits_task_readProbeDataDown),
    .io_in_2_bits_task_fromL2pft (Arbiter3_TaskWithData__io_in_2_bits_task_fromL2pft),
    .io_in_2_bits_task_needHint (Arbiter3_TaskWithData__io_in_2_bits_task_needHint),
    .io_in_2_bits_task_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_dirty),
    .io_in_2_bits_task_way (Arbiter3_TaskWithData__io_in_2_bits_task_way),
    .io_in_2_bits_task_meta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_meta_dirty),
    .io_in_2_bits_task_meta_state (Arbiter3_TaskWithData__io_in_2_bits_task_meta_state),
    .io_in_2_bits_task_meta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_meta_clients),
    .io_in_2_bits_task_meta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_meta_alias),
    .io_in_2_bits_task_meta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetch),
    .io_in_2_bits_task_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetchSrc),
    .io_in_2_bits_task_meta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_meta_accessed),
    .io_in_2_bits_task_meta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_meta_tagErr),
    .io_in_2_bits_task_meta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_meta_dataErr),
    .io_in_2_bits_task_metaWen (Arbiter3_TaskWithData__io_in_2_bits_task_metaWen),
    .io_in_2_bits_task_tagWen (Arbiter3_TaskWithData__io_in_2_bits_task_tagWen),
    .io_in_2_bits_task_dsWen (Arbiter3_TaskWithData__io_in_2_bits_task_dsWen),
    .io_in_2_bits_task_wayMask (Arbiter3_TaskWithData__io_in_2_bits_task_wayMask),
    .io_in_2_bits_task_replTask (Arbiter3_TaskWithData__io_in_2_bits_task_replTask),
    .io_in_2_bits_task_cmoTask (Arbiter3_TaskWithData__io_in_2_bits_task_cmoTask),
    .io_in_2_bits_task_cmoAll (Arbiter3_TaskWithData__io_in_2_bits_task_cmoAll),
    .io_in_2_bits_task_reqSource (Arbiter3_TaskWithData__io_in_2_bits_task_reqSource),
    .io_in_2_bits_task_mergeA (Arbiter3_TaskWithData__io_in_2_bits_task_mergeA),
    .io_in_2_bits_task_aMergeTask_off (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_off),
    .io_in_2_bits_task_aMergeTask_alias (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_alias),
    .io_in_2_bits_task_aMergeTask_vaddr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_vaddr),
    .io_in_2_bits_task_aMergeTask_isKeyword (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_isKeyword),
    .io_in_2_bits_task_aMergeTask_opcode (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_opcode),
    .io_in_2_bits_task_aMergeTask_param (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_param),
    .io_in_2_bits_task_aMergeTask_sourceId (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_sourceId),
    .io_in_2_bits_task_aMergeTask_meta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dirty),
    .io_in_2_bits_task_aMergeTask_meta_state (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_state),
    .io_in_2_bits_task_aMergeTask_meta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_clients),
    .io_in_2_bits_task_aMergeTask_meta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_alias),
    .io_in_2_bits_task_aMergeTask_meta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetch),
    .io_in_2_bits_task_aMergeTask_meta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetchSrc),
    .io_in_2_bits_task_aMergeTask_meta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_accessed),
    .io_in_2_bits_task_aMergeTask_meta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_tagErr),
    .io_in_2_bits_task_aMergeTask_meta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dataErr),
    .io_in_2_bits_task_snpHitRelease (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitRelease),
    .io_in_2_bits_task_snpHitReleaseToInval (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToInval),
    .io_in_2_bits_task_snpHitReleaseToClean (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToClean),
    .io_in_2_bits_task_snpHitReleaseWithData (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseWithData),
    .io_in_2_bits_task_snpHitReleaseIdx (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseIdx),
    .io_in_2_bits_task_snpHitReleaseMeta_dirty (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dirty),
    .io_in_2_bits_task_snpHitReleaseMeta_state (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_state),
    .io_in_2_bits_task_snpHitReleaseMeta_clients (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_clients),
    .io_in_2_bits_task_snpHitReleaseMeta_alias (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_alias),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetch (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetch),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_task_snpHitReleaseMeta_accessed (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_accessed),
    .io_in_2_bits_task_snpHitReleaseMeta_tagErr (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_tagErr),
    .io_in_2_bits_task_snpHitReleaseMeta_dataErr (Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dataErr),
    .io_in_2_bits_task_tgtID (Arbiter3_TaskWithData__io_in_2_bits_task_tgtID),
    .io_in_2_bits_task_srcID (Arbiter3_TaskWithData__io_in_2_bits_task_srcID),
    .io_in_2_bits_task_txnID (Arbiter3_TaskWithData__io_in_2_bits_task_txnID),
    .io_in_2_bits_task_homeNID (Arbiter3_TaskWithData__io_in_2_bits_task_homeNID),
    .io_in_2_bits_task_dbID (Arbiter3_TaskWithData__io_in_2_bits_task_dbID),
    .io_in_2_bits_task_fwdNID (Arbiter3_TaskWithData__io_in_2_bits_task_fwdNID),
    .io_in_2_bits_task_fwdTxnID (Arbiter3_TaskWithData__io_in_2_bits_task_fwdTxnID),
    .io_in_2_bits_task_chiOpcode (Arbiter3_TaskWithData__io_in_2_bits_task_chiOpcode),
    .io_in_2_bits_task_resp (Arbiter3_TaskWithData__io_in_2_bits_task_resp),
    .io_in_2_bits_task_fwdState (Arbiter3_TaskWithData__io_in_2_bits_task_fwdState),
    .io_in_2_bits_task_pCrdType (Arbiter3_TaskWithData__io_in_2_bits_task_pCrdType),
    .io_in_2_bits_task_retToSrc (Arbiter3_TaskWithData__io_in_2_bits_task_retToSrc),
    .io_in_2_bits_task_likelyshared (Arbiter3_TaskWithData__io_in_2_bits_task_likelyshared),
    .io_in_2_bits_task_expCompAck (Arbiter3_TaskWithData__io_in_2_bits_task_expCompAck),
    .io_in_2_bits_task_allowRetry (Arbiter3_TaskWithData__io_in_2_bits_task_allowRetry),
    .io_in_2_bits_task_memAttr_allocate (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_allocate),
    .io_in_2_bits_task_memAttr_cacheable (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_cacheable),
    .io_in_2_bits_task_memAttr_device (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_device),
    .io_in_2_bits_task_memAttr_ewa (Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_ewa),
    .io_in_2_bits_task_traceTag (Arbiter3_TaskWithData__io_in_2_bits_task_traceTag),
    .io_in_2_bits_data_data (Arbiter3_TaskWithData__io_in_2_bits_data_data),
    .io_out_ready (Arbiter3_TaskWithData__io_out_ready),
    .io_out_valid (i_Arbiter3_TaskWithData__io_out_valid),
    .io_out_bits_task_channel (i_Arbiter3_TaskWithData__io_out_bits_task_channel),
    .io_out_bits_task_txChannel (i_Arbiter3_TaskWithData__io_out_bits_task_txChannel),
    .io_out_bits_task_set (i_Arbiter3_TaskWithData__io_out_bits_task_set),
    .io_out_bits_task_tag (i_Arbiter3_TaskWithData__io_out_bits_task_tag),
    .io_out_bits_task_off (i_Arbiter3_TaskWithData__io_out_bits_task_off),
    .io_out_bits_task_alias (i_Arbiter3_TaskWithData__io_out_bits_task_alias),
    .io_out_bits_task_vaddr (i_Arbiter3_TaskWithData__io_out_bits_task_vaddr),
    .io_out_bits_task_isKeyword (i_Arbiter3_TaskWithData__io_out_bits_task_isKeyword),
    .io_out_bits_task_opcode (i_Arbiter3_TaskWithData__io_out_bits_task_opcode),
    .io_out_bits_task_param (i_Arbiter3_TaskWithData__io_out_bits_task_param),
    .io_out_bits_task_size (i_Arbiter3_TaskWithData__io_out_bits_task_size),
    .io_out_bits_task_sourceId (i_Arbiter3_TaskWithData__io_out_bits_task_sourceId),
    .io_out_bits_task_bufIdx (i_Arbiter3_TaskWithData__io_out_bits_task_bufIdx),
    .io_out_bits_task_needProbeAckData (i_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData),
    .io_out_bits_task_denied (i_Arbiter3_TaskWithData__io_out_bits_task_denied),
    .io_out_bits_task_corrupt (i_Arbiter3_TaskWithData__io_out_bits_task_corrupt),
    .io_out_bits_task_mshrTask (i_Arbiter3_TaskWithData__io_out_bits_task_mshrTask),
    .io_out_bits_task_mshrId (i_Arbiter3_TaskWithData__io_out_bits_task_mshrId),
    .io_out_bits_task_aliasTask (i_Arbiter3_TaskWithData__io_out_bits_task_aliasTask),
    .io_out_bits_task_useProbeData (i_Arbiter3_TaskWithData__io_out_bits_task_useProbeData),
    .io_out_bits_task_mshrRetry (i_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry),
    .io_out_bits_task_readProbeDataDown (i_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown),
    .io_out_bits_task_fromL2pft (i_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft),
    .io_out_bits_task_needHint (i_Arbiter3_TaskWithData__io_out_bits_task_needHint),
    .io_out_bits_task_dirty (i_Arbiter3_TaskWithData__io_out_bits_task_dirty),
    .io_out_bits_task_way (i_Arbiter3_TaskWithData__io_out_bits_task_way),
    .io_out_bits_task_meta_dirty (i_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty),
    .io_out_bits_task_meta_state (i_Arbiter3_TaskWithData__io_out_bits_task_meta_state),
    .io_out_bits_task_meta_clients (i_Arbiter3_TaskWithData__io_out_bits_task_meta_clients),
    .io_out_bits_task_meta_alias (i_Arbiter3_TaskWithData__io_out_bits_task_meta_alias),
    .io_out_bits_task_meta_prefetch (i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch),
    .io_out_bits_task_meta_prefetchSrc (i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc),
    .io_out_bits_task_meta_accessed (i_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed),
    .io_out_bits_task_meta_tagErr (i_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr),
    .io_out_bits_task_meta_dataErr (i_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr),
    .io_out_bits_task_metaWen (i_Arbiter3_TaskWithData__io_out_bits_task_metaWen),
    .io_out_bits_task_tagWen (i_Arbiter3_TaskWithData__io_out_bits_task_tagWen),
    .io_out_bits_task_dsWen (i_Arbiter3_TaskWithData__io_out_bits_task_dsWen),
    .io_out_bits_task_wayMask (i_Arbiter3_TaskWithData__io_out_bits_task_wayMask),
    .io_out_bits_task_replTask (i_Arbiter3_TaskWithData__io_out_bits_task_replTask),
    .io_out_bits_task_cmoTask (i_Arbiter3_TaskWithData__io_out_bits_task_cmoTask),
    .io_out_bits_task_cmoAll (i_Arbiter3_TaskWithData__io_out_bits_task_cmoAll),
    .io_out_bits_task_reqSource (i_Arbiter3_TaskWithData__io_out_bits_task_reqSource),
    .io_out_bits_task_mergeA (i_Arbiter3_TaskWithData__io_out_bits_task_mergeA),
    .io_out_bits_task_aMergeTask_off (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off),
    .io_out_bits_task_aMergeTask_alias (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias),
    .io_out_bits_task_aMergeTask_vaddr (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr),
    .io_out_bits_task_aMergeTask_isKeyword (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword),
    .io_out_bits_task_aMergeTask_opcode (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode),
    .io_out_bits_task_aMergeTask_param (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param),
    .io_out_bits_task_aMergeTask_sourceId (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId),
    .io_out_bits_task_aMergeTask_meta_dirty (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty),
    .io_out_bits_task_aMergeTask_meta_state (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state),
    .io_out_bits_task_aMergeTask_meta_clients (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients),
    .io_out_bits_task_aMergeTask_meta_alias (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias),
    .io_out_bits_task_aMergeTask_meta_prefetch (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch),
    .io_out_bits_task_aMergeTask_meta_prefetchSrc (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc),
    .io_out_bits_task_aMergeTask_meta_accessed (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed),
    .io_out_bits_task_aMergeTask_meta_tagErr (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr),
    .io_out_bits_task_aMergeTask_meta_dataErr (i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr),
    .io_out_bits_task_snpHitRelease (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease),
    .io_out_bits_task_snpHitReleaseToInval (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval),
    .io_out_bits_task_snpHitReleaseToClean (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean),
    .io_out_bits_task_snpHitReleaseWithData (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData),
    .io_out_bits_task_snpHitReleaseIdx (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx),
    .io_out_bits_task_snpHitReleaseMeta_dirty (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty),
    .io_out_bits_task_snpHitReleaseMeta_state (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state),
    .io_out_bits_task_snpHitReleaseMeta_clients (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients),
    .io_out_bits_task_snpHitReleaseMeta_alias (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias),
    .io_out_bits_task_snpHitReleaseMeta_prefetch (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch),
    .io_out_bits_task_snpHitReleaseMeta_prefetchSrc (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_task_snpHitReleaseMeta_accessed (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed),
    .io_out_bits_task_snpHitReleaseMeta_tagErr (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr),
    .io_out_bits_task_snpHitReleaseMeta_dataErr (i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr),
    .io_out_bits_task_tgtID (i_Arbiter3_TaskWithData__io_out_bits_task_tgtID),
    .io_out_bits_task_srcID (i_Arbiter3_TaskWithData__io_out_bits_task_srcID),
    .io_out_bits_task_txnID (i_Arbiter3_TaskWithData__io_out_bits_task_txnID),
    .io_out_bits_task_homeNID (i_Arbiter3_TaskWithData__io_out_bits_task_homeNID),
    .io_out_bits_task_dbID (i_Arbiter3_TaskWithData__io_out_bits_task_dbID),
    .io_out_bits_task_fwdNID (i_Arbiter3_TaskWithData__io_out_bits_task_fwdNID),
    .io_out_bits_task_fwdTxnID (i_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID),
    .io_out_bits_task_chiOpcode (i_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode),
    .io_out_bits_task_resp (i_Arbiter3_TaskWithData__io_out_bits_task_resp),
    .io_out_bits_task_fwdState (i_Arbiter3_TaskWithData__io_out_bits_task_fwdState),
    .io_out_bits_task_pCrdType (i_Arbiter3_TaskWithData__io_out_bits_task_pCrdType),
    .io_out_bits_task_retToSrc (i_Arbiter3_TaskWithData__io_out_bits_task_retToSrc),
    .io_out_bits_task_likelyshared (i_Arbiter3_TaskWithData__io_out_bits_task_likelyshared),
    .io_out_bits_task_expCompAck (i_Arbiter3_TaskWithData__io_out_bits_task_expCompAck),
    .io_out_bits_task_allowRetry (i_Arbiter3_TaskWithData__io_out_bits_task_allowRetry),
    .io_out_bits_task_memAttr_allocate (i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate),
    .io_out_bits_task_memAttr_cacheable (i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable),
    .io_out_bits_task_memAttr_device (i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device),
    .io_out_bits_task_memAttr_ewa (i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa),
    .io_out_bits_task_traceTag (i_Arbiter3_TaskWithData__io_out_bits_task_traceTag),
    .io_out_bits_data_data (i_Arbiter3_TaskWithData__io_out_bits_data_data)
  );
  task automatic drive_Arbiter3_TaskWithData();
    Arbiter3_TaskWithData__io_in_0_valid = (($urandom % 2) == 0);
    Arbiter3_TaskWithData__io_in_0_bits_task_channel = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_txChannel = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_set = rnd(9);
    Arbiter3_TaskWithData__io_in_0_bits_task_tag = rnd(31);
    Arbiter3_TaskWithData__io_in_0_bits_task_off = rnd(6);
    Arbiter3_TaskWithData__io_in_0_bits_task_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_0_bits_task_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_opcode = rnd(4);
    Arbiter3_TaskWithData__io_in_0_bits_task_param = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_size = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_0_bits_task_bufIdx = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_needProbeAckData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_denied = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_corrupt = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_mshrTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_mshrId = rnd(8);
    Arbiter3_TaskWithData__io_in_0_bits_task_aliasTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_useProbeData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_mshrRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_readProbeDataDown = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_fromL2pft = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_needHint = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_way = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_metaWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_tagWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_dsWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_wayMask = rnd(8);
    Arbiter3_TaskWithData__io_in_0_bits_task_replTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_cmoTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_cmoAll = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_reqSource = rnd(5);
    Arbiter3_TaskWithData__io_in_0_bits_task_mergeA = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_off = rnd(6);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_opcode = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_param = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitRelease = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToInval = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseToClean = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseWithData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseIdx = rnd(8);
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_tgtID = rnd(11);
    Arbiter3_TaskWithData__io_in_0_bits_task_srcID = rnd(11);
    Arbiter3_TaskWithData__io_in_0_bits_task_txnID = rnd(12);
    Arbiter3_TaskWithData__io_in_0_bits_task_homeNID = rnd(11);
    Arbiter3_TaskWithData__io_in_0_bits_task_dbID = rnd(12);
    Arbiter3_TaskWithData__io_in_0_bits_task_fwdNID = rnd(11);
    Arbiter3_TaskWithData__io_in_0_bits_task_fwdTxnID = rnd(12);
    Arbiter3_TaskWithData__io_in_0_bits_task_chiOpcode = rnd(7);
    Arbiter3_TaskWithData__io_in_0_bits_task_resp = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_fwdState = rnd(3);
    Arbiter3_TaskWithData__io_in_0_bits_task_pCrdType = rnd(4);
    Arbiter3_TaskWithData__io_in_0_bits_task_retToSrc = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_likelyshared = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_expCompAck = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_allowRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_allocate = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_cacheable = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_device = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_memAttr_ewa = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_task_traceTag = $urandom % 2;
    Arbiter3_TaskWithData__io_in_0_bits_data_data = rnd(512);
    Arbiter3_TaskWithData__io_in_1_valid = (($urandom % 2) == 0);
    Arbiter3_TaskWithData__io_in_1_bits_task_channel = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_txChannel = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_set = rnd(9);
    Arbiter3_TaskWithData__io_in_1_bits_task_tag = rnd(31);
    Arbiter3_TaskWithData__io_in_1_bits_task_off = rnd(6);
    Arbiter3_TaskWithData__io_in_1_bits_task_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_1_bits_task_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_opcode = rnd(4);
    Arbiter3_TaskWithData__io_in_1_bits_task_param = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_size = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_1_bits_task_bufIdx = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_needProbeAckData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_denied = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_corrupt = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_mshrTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_mshrId = rnd(8);
    Arbiter3_TaskWithData__io_in_1_bits_task_aliasTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_useProbeData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_mshrRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_readProbeDataDown = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_fromL2pft = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_needHint = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_way = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_metaWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_tagWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_dsWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_wayMask = rnd(8);
    Arbiter3_TaskWithData__io_in_1_bits_task_replTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_cmoTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_cmoAll = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_reqSource = rnd(5);
    Arbiter3_TaskWithData__io_in_1_bits_task_mergeA = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_off = rnd(6);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_opcode = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_param = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitRelease = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToInval = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseToClean = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseWithData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseIdx = rnd(8);
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_tgtID = rnd(11);
    Arbiter3_TaskWithData__io_in_1_bits_task_srcID = rnd(11);
    Arbiter3_TaskWithData__io_in_1_bits_task_txnID = rnd(12);
    Arbiter3_TaskWithData__io_in_1_bits_task_homeNID = rnd(11);
    Arbiter3_TaskWithData__io_in_1_bits_task_dbID = rnd(12);
    Arbiter3_TaskWithData__io_in_1_bits_task_fwdNID = rnd(11);
    Arbiter3_TaskWithData__io_in_1_bits_task_fwdTxnID = rnd(12);
    Arbiter3_TaskWithData__io_in_1_bits_task_chiOpcode = rnd(7);
    Arbiter3_TaskWithData__io_in_1_bits_task_resp = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_fwdState = rnd(3);
    Arbiter3_TaskWithData__io_in_1_bits_task_pCrdType = rnd(4);
    Arbiter3_TaskWithData__io_in_1_bits_task_retToSrc = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_likelyshared = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_expCompAck = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_allowRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_allocate = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_cacheable = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_device = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_memAttr_ewa = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_task_traceTag = $urandom % 2;
    Arbiter3_TaskWithData__io_in_1_bits_data_data = rnd(512);
    Arbiter3_TaskWithData__io_in_2_valid = (($urandom % 2) == 0);
    Arbiter3_TaskWithData__io_in_2_bits_task_channel = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_txChannel = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_set = rnd(9);
    Arbiter3_TaskWithData__io_in_2_bits_task_tag = rnd(31);
    Arbiter3_TaskWithData__io_in_2_bits_task_off = rnd(6);
    Arbiter3_TaskWithData__io_in_2_bits_task_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_2_bits_task_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_opcode = rnd(4);
    Arbiter3_TaskWithData__io_in_2_bits_task_param = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_size = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_2_bits_task_bufIdx = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_needProbeAckData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_denied = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_corrupt = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_mshrTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_mshrId = rnd(8);
    Arbiter3_TaskWithData__io_in_2_bits_task_aliasTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_useProbeData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_mshrRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_readProbeDataDown = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_fromL2pft = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_needHint = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_way = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_metaWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_tagWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_dsWen = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_wayMask = rnd(8);
    Arbiter3_TaskWithData__io_in_2_bits_task_replTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_cmoTask = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_cmoAll = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_reqSource = rnd(5);
    Arbiter3_TaskWithData__io_in_2_bits_task_mergeA = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_off = rnd(6);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_vaddr = rnd(44);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_isKeyword = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_opcode = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_param = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_sourceId = rnd(7);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_aMergeTask_meta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitRelease = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToInval = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseToClean = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseWithData = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseIdx = rnd(8);
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dirty = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_state = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_clients = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_alias = rnd(2);
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetch = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_accessed = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_tagErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_snpHitReleaseMeta_dataErr = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_tgtID = rnd(11);
    Arbiter3_TaskWithData__io_in_2_bits_task_srcID = rnd(11);
    Arbiter3_TaskWithData__io_in_2_bits_task_txnID = rnd(12);
    Arbiter3_TaskWithData__io_in_2_bits_task_homeNID = rnd(11);
    Arbiter3_TaskWithData__io_in_2_bits_task_dbID = rnd(12);
    Arbiter3_TaskWithData__io_in_2_bits_task_fwdNID = rnd(11);
    Arbiter3_TaskWithData__io_in_2_bits_task_fwdTxnID = rnd(12);
    Arbiter3_TaskWithData__io_in_2_bits_task_chiOpcode = rnd(7);
    Arbiter3_TaskWithData__io_in_2_bits_task_resp = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_fwdState = rnd(3);
    Arbiter3_TaskWithData__io_in_2_bits_task_pCrdType = rnd(4);
    Arbiter3_TaskWithData__io_in_2_bits_task_retToSrc = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_likelyshared = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_expCompAck = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_allowRetry = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_allocate = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_cacheable = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_device = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_memAttr_ewa = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_task_traceTag = $urandom % 2;
    Arbiter3_TaskWithData__io_in_2_bits_data_data = rnd(512);
    Arbiter3_TaskWithData__io_out_ready = (($urandom % 4) != 0);
  endtask
  task automatic check_Arbiter3_TaskWithData();
    checks++;
    if (g_Arbiter3_TaskWithData__io_in_0_ready !== i_Arbiter3_TaskWithData__io_in_0_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_in_0_ready g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_in_0_ready, i_Arbiter3_TaskWithData__io_in_0_ready);
    end
    if (g_Arbiter3_TaskWithData__io_in_0_ready !== p_Arbiter3_TaskWithData__io_in_0_ready) t_Arbiter3_TaskWithData__io_in_0_ready = 1'b1;
    p_Arbiter3_TaskWithData__io_in_0_ready = g_Arbiter3_TaskWithData__io_in_0_ready;
    checks++;
    if (g_Arbiter3_TaskWithData__io_in_1_ready !== i_Arbiter3_TaskWithData__io_in_1_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_in_1_ready g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_in_1_ready, i_Arbiter3_TaskWithData__io_in_1_ready);
    end
    if (g_Arbiter3_TaskWithData__io_in_1_ready !== p_Arbiter3_TaskWithData__io_in_1_ready) t_Arbiter3_TaskWithData__io_in_1_ready = 1'b1;
    p_Arbiter3_TaskWithData__io_in_1_ready = g_Arbiter3_TaskWithData__io_in_1_ready;
    checks++;
    if (g_Arbiter3_TaskWithData__io_in_2_ready !== i_Arbiter3_TaskWithData__io_in_2_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_in_2_ready g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_in_2_ready, i_Arbiter3_TaskWithData__io_in_2_ready);
    end
    if (g_Arbiter3_TaskWithData__io_in_2_ready !== p_Arbiter3_TaskWithData__io_in_2_ready) t_Arbiter3_TaskWithData__io_in_2_ready = 1'b1;
    p_Arbiter3_TaskWithData__io_in_2_ready = g_Arbiter3_TaskWithData__io_in_2_ready;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_valid !== i_Arbiter3_TaskWithData__io_out_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_valid g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_valid, i_Arbiter3_TaskWithData__io_out_valid);
    end
    if (g_Arbiter3_TaskWithData__io_out_valid !== p_Arbiter3_TaskWithData__io_out_valid) t_Arbiter3_TaskWithData__io_out_valid = 1'b1;
    p_Arbiter3_TaskWithData__io_out_valid = g_Arbiter3_TaskWithData__io_out_valid;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_channel !== i_Arbiter3_TaskWithData__io_out_bits_task_channel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_channel g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_channel, i_Arbiter3_TaskWithData__io_out_bits_task_channel);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_channel !== p_Arbiter3_TaskWithData__io_out_bits_task_channel) t_Arbiter3_TaskWithData__io_out_bits_task_channel = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_channel = g_Arbiter3_TaskWithData__io_out_bits_task_channel;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_txChannel !== i_Arbiter3_TaskWithData__io_out_bits_task_txChannel) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_txChannel g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_txChannel, i_Arbiter3_TaskWithData__io_out_bits_task_txChannel);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_txChannel !== p_Arbiter3_TaskWithData__io_out_bits_task_txChannel) t_Arbiter3_TaskWithData__io_out_bits_task_txChannel = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_txChannel = g_Arbiter3_TaskWithData__io_out_bits_task_txChannel;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_set !== i_Arbiter3_TaskWithData__io_out_bits_task_set) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_set g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_set, i_Arbiter3_TaskWithData__io_out_bits_task_set);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_set !== p_Arbiter3_TaskWithData__io_out_bits_task_set) t_Arbiter3_TaskWithData__io_out_bits_task_set = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_set = g_Arbiter3_TaskWithData__io_out_bits_task_set;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tag !== i_Arbiter3_TaskWithData__io_out_bits_task_tag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_tag g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_tag, i_Arbiter3_TaskWithData__io_out_bits_task_tag);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tag !== p_Arbiter3_TaskWithData__io_out_bits_task_tag) t_Arbiter3_TaskWithData__io_out_bits_task_tag = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_tag = g_Arbiter3_TaskWithData__io_out_bits_task_tag;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_off !== i_Arbiter3_TaskWithData__io_out_bits_task_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_off g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_off, i_Arbiter3_TaskWithData__io_out_bits_task_off);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_off !== p_Arbiter3_TaskWithData__io_out_bits_task_off) t_Arbiter3_TaskWithData__io_out_bits_task_off = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_off = g_Arbiter3_TaskWithData__io_out_bits_task_off;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_alias !== i_Arbiter3_TaskWithData__io_out_bits_task_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_alias g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_alias, i_Arbiter3_TaskWithData__io_out_bits_task_alias);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_alias !== p_Arbiter3_TaskWithData__io_out_bits_task_alias) t_Arbiter3_TaskWithData__io_out_bits_task_alias = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_alias = g_Arbiter3_TaskWithData__io_out_bits_task_alias;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_vaddr !== i_Arbiter3_TaskWithData__io_out_bits_task_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_vaddr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_vaddr, i_Arbiter3_TaskWithData__io_out_bits_task_vaddr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_vaddr !== p_Arbiter3_TaskWithData__io_out_bits_task_vaddr) t_Arbiter3_TaskWithData__io_out_bits_task_vaddr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_vaddr = g_Arbiter3_TaskWithData__io_out_bits_task_vaddr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword !== i_Arbiter3_TaskWithData__io_out_bits_task_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_isKeyword g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword, i_Arbiter3_TaskWithData__io_out_bits_task_isKeyword);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword !== p_Arbiter3_TaskWithData__io_out_bits_task_isKeyword) t_Arbiter3_TaskWithData__io_out_bits_task_isKeyword = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_isKeyword = g_Arbiter3_TaskWithData__io_out_bits_task_isKeyword;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_opcode !== i_Arbiter3_TaskWithData__io_out_bits_task_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_opcode g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_opcode, i_Arbiter3_TaskWithData__io_out_bits_task_opcode);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_opcode !== p_Arbiter3_TaskWithData__io_out_bits_task_opcode) t_Arbiter3_TaskWithData__io_out_bits_task_opcode = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_opcode = g_Arbiter3_TaskWithData__io_out_bits_task_opcode;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_param !== i_Arbiter3_TaskWithData__io_out_bits_task_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_param g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_param, i_Arbiter3_TaskWithData__io_out_bits_task_param);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_param !== p_Arbiter3_TaskWithData__io_out_bits_task_param) t_Arbiter3_TaskWithData__io_out_bits_task_param = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_param = g_Arbiter3_TaskWithData__io_out_bits_task_param;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_size !== i_Arbiter3_TaskWithData__io_out_bits_task_size) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_size g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_size, i_Arbiter3_TaskWithData__io_out_bits_task_size);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_size !== p_Arbiter3_TaskWithData__io_out_bits_task_size) t_Arbiter3_TaskWithData__io_out_bits_task_size = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_size = g_Arbiter3_TaskWithData__io_out_bits_task_size;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_sourceId !== i_Arbiter3_TaskWithData__io_out_bits_task_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_sourceId g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_sourceId, i_Arbiter3_TaskWithData__io_out_bits_task_sourceId);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_sourceId !== p_Arbiter3_TaskWithData__io_out_bits_task_sourceId) t_Arbiter3_TaskWithData__io_out_bits_task_sourceId = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_sourceId = g_Arbiter3_TaskWithData__io_out_bits_task_sourceId;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx !== i_Arbiter3_TaskWithData__io_out_bits_task_bufIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_bufIdx g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx, i_Arbiter3_TaskWithData__io_out_bits_task_bufIdx);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx !== p_Arbiter3_TaskWithData__io_out_bits_task_bufIdx) t_Arbiter3_TaskWithData__io_out_bits_task_bufIdx = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_bufIdx = g_Arbiter3_TaskWithData__io_out_bits_task_bufIdx;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData !== i_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_needProbeAckData g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData, i_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData !== p_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData) t_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData = g_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_denied !== i_Arbiter3_TaskWithData__io_out_bits_task_denied) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_denied g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_denied, i_Arbiter3_TaskWithData__io_out_bits_task_denied);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_denied !== p_Arbiter3_TaskWithData__io_out_bits_task_denied) t_Arbiter3_TaskWithData__io_out_bits_task_denied = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_denied = g_Arbiter3_TaskWithData__io_out_bits_task_denied;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_corrupt !== i_Arbiter3_TaskWithData__io_out_bits_task_corrupt) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_corrupt g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_corrupt, i_Arbiter3_TaskWithData__io_out_bits_task_corrupt);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_corrupt !== p_Arbiter3_TaskWithData__io_out_bits_task_corrupt) t_Arbiter3_TaskWithData__io_out_bits_task_corrupt = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_corrupt = g_Arbiter3_TaskWithData__io_out_bits_task_corrupt;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask !== i_Arbiter3_TaskWithData__io_out_bits_task_mshrTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_mshrTask g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask, i_Arbiter3_TaskWithData__io_out_bits_task_mshrTask);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask !== p_Arbiter3_TaskWithData__io_out_bits_task_mshrTask) t_Arbiter3_TaskWithData__io_out_bits_task_mshrTask = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_mshrTask = g_Arbiter3_TaskWithData__io_out_bits_task_mshrTask;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrId !== i_Arbiter3_TaskWithData__io_out_bits_task_mshrId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_mshrId g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_mshrId, i_Arbiter3_TaskWithData__io_out_bits_task_mshrId);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrId !== p_Arbiter3_TaskWithData__io_out_bits_task_mshrId) t_Arbiter3_TaskWithData__io_out_bits_task_mshrId = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_mshrId = g_Arbiter3_TaskWithData__io_out_bits_task_mshrId;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask !== i_Arbiter3_TaskWithData__io_out_bits_task_aliasTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aliasTask g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask, i_Arbiter3_TaskWithData__io_out_bits_task_aliasTask);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask !== p_Arbiter3_TaskWithData__io_out_bits_task_aliasTask) t_Arbiter3_TaskWithData__io_out_bits_task_aliasTask = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aliasTask = g_Arbiter3_TaskWithData__io_out_bits_task_aliasTask;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData !== i_Arbiter3_TaskWithData__io_out_bits_task_useProbeData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_useProbeData g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData, i_Arbiter3_TaskWithData__io_out_bits_task_useProbeData);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData !== p_Arbiter3_TaskWithData__io_out_bits_task_useProbeData) t_Arbiter3_TaskWithData__io_out_bits_task_useProbeData = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_useProbeData = g_Arbiter3_TaskWithData__io_out_bits_task_useProbeData;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry !== i_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_mshrRetry g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry, i_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry !== p_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry) t_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry = g_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown !== i_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_readProbeDataDown g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown, i_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown !== p_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown) t_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown = g_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft !== i_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_fromL2pft g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft, i_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft !== p_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft) t_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft = g_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_needHint !== i_Arbiter3_TaskWithData__io_out_bits_task_needHint) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_needHint g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_needHint, i_Arbiter3_TaskWithData__io_out_bits_task_needHint);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_needHint !== p_Arbiter3_TaskWithData__io_out_bits_task_needHint) t_Arbiter3_TaskWithData__io_out_bits_task_needHint = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_needHint = g_Arbiter3_TaskWithData__io_out_bits_task_needHint;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dirty !== i_Arbiter3_TaskWithData__io_out_bits_task_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_dirty g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_dirty, i_Arbiter3_TaskWithData__io_out_bits_task_dirty);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dirty !== p_Arbiter3_TaskWithData__io_out_bits_task_dirty) t_Arbiter3_TaskWithData__io_out_bits_task_dirty = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_dirty = g_Arbiter3_TaskWithData__io_out_bits_task_dirty;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_way !== i_Arbiter3_TaskWithData__io_out_bits_task_way) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_way g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_way, i_Arbiter3_TaskWithData__io_out_bits_task_way);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_way !== p_Arbiter3_TaskWithData__io_out_bits_task_way) t_Arbiter3_TaskWithData__io_out_bits_task_way = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_way = g_Arbiter3_TaskWithData__io_out_bits_task_way;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_dirty g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty, i_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty) t_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty = g_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_state !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_state g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_state, i_Arbiter3_TaskWithData__io_out_bits_task_meta_state);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_state !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_state) t_Arbiter3_TaskWithData__io_out_bits_task_meta_state = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_state = g_Arbiter3_TaskWithData__io_out_bits_task_meta_state;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_clients g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients, i_Arbiter3_TaskWithData__io_out_bits_task_meta_clients);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_clients) t_Arbiter3_TaskWithData__io_out_bits_task_meta_clients = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_clients = g_Arbiter3_TaskWithData__io_out_bits_task_meta_clients;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_alias g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias, i_Arbiter3_TaskWithData__io_out_bits_task_meta_alias);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_alias) t_Arbiter3_TaskWithData__io_out_bits_task_meta_alias = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_alias = g_Arbiter3_TaskWithData__io_out_bits_task_meta_alias;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_prefetch g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch, i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch) t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch = g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_prefetchSrc g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc, i_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc) t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc = g_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_accessed g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed, i_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed) t_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed = g_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_tagErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr, i_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr) t_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr = g_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr !== i_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_meta_dataErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr, i_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr !== p_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr) t_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr = g_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_metaWen !== i_Arbiter3_TaskWithData__io_out_bits_task_metaWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_metaWen g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_metaWen, i_Arbiter3_TaskWithData__io_out_bits_task_metaWen);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_metaWen !== p_Arbiter3_TaskWithData__io_out_bits_task_metaWen) t_Arbiter3_TaskWithData__io_out_bits_task_metaWen = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_metaWen = g_Arbiter3_TaskWithData__io_out_bits_task_metaWen;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tagWen !== i_Arbiter3_TaskWithData__io_out_bits_task_tagWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_tagWen g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_tagWen, i_Arbiter3_TaskWithData__io_out_bits_task_tagWen);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tagWen !== p_Arbiter3_TaskWithData__io_out_bits_task_tagWen) t_Arbiter3_TaskWithData__io_out_bits_task_tagWen = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_tagWen = g_Arbiter3_TaskWithData__io_out_bits_task_tagWen;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dsWen !== i_Arbiter3_TaskWithData__io_out_bits_task_dsWen) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_dsWen g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_dsWen, i_Arbiter3_TaskWithData__io_out_bits_task_dsWen);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dsWen !== p_Arbiter3_TaskWithData__io_out_bits_task_dsWen) t_Arbiter3_TaskWithData__io_out_bits_task_dsWen = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_dsWen = g_Arbiter3_TaskWithData__io_out_bits_task_dsWen;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_wayMask !== i_Arbiter3_TaskWithData__io_out_bits_task_wayMask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_wayMask g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_wayMask, i_Arbiter3_TaskWithData__io_out_bits_task_wayMask);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_wayMask !== p_Arbiter3_TaskWithData__io_out_bits_task_wayMask) t_Arbiter3_TaskWithData__io_out_bits_task_wayMask = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_wayMask = g_Arbiter3_TaskWithData__io_out_bits_task_wayMask;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_replTask !== i_Arbiter3_TaskWithData__io_out_bits_task_replTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_replTask g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_replTask, i_Arbiter3_TaskWithData__io_out_bits_task_replTask);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_replTask !== p_Arbiter3_TaskWithData__io_out_bits_task_replTask) t_Arbiter3_TaskWithData__io_out_bits_task_replTask = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_replTask = g_Arbiter3_TaskWithData__io_out_bits_task_replTask;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask !== i_Arbiter3_TaskWithData__io_out_bits_task_cmoTask) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_cmoTask g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask, i_Arbiter3_TaskWithData__io_out_bits_task_cmoTask);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask !== p_Arbiter3_TaskWithData__io_out_bits_task_cmoTask) t_Arbiter3_TaskWithData__io_out_bits_task_cmoTask = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_cmoTask = g_Arbiter3_TaskWithData__io_out_bits_task_cmoTask;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll !== i_Arbiter3_TaskWithData__io_out_bits_task_cmoAll) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_cmoAll g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll, i_Arbiter3_TaskWithData__io_out_bits_task_cmoAll);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll !== p_Arbiter3_TaskWithData__io_out_bits_task_cmoAll) t_Arbiter3_TaskWithData__io_out_bits_task_cmoAll = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_cmoAll = g_Arbiter3_TaskWithData__io_out_bits_task_cmoAll;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_reqSource !== i_Arbiter3_TaskWithData__io_out_bits_task_reqSource) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_reqSource g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_reqSource, i_Arbiter3_TaskWithData__io_out_bits_task_reqSource);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_reqSource !== p_Arbiter3_TaskWithData__io_out_bits_task_reqSource) t_Arbiter3_TaskWithData__io_out_bits_task_reqSource = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_reqSource = g_Arbiter3_TaskWithData__io_out_bits_task_reqSource;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mergeA !== i_Arbiter3_TaskWithData__io_out_bits_task_mergeA) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_mergeA g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_mergeA, i_Arbiter3_TaskWithData__io_out_bits_task_mergeA);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_mergeA !== p_Arbiter3_TaskWithData__io_out_bits_task_mergeA) t_Arbiter3_TaskWithData__io_out_bits_task_mergeA = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_mergeA = g_Arbiter3_TaskWithData__io_out_bits_task_mergeA;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_off g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_alias g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_vaddr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_isKeyword g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_opcode g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_param g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_sourceId g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_dirty g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_state g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_clients g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_alias g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_prefetch g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_prefetchSrc g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_accessed g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_tagErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr !== i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_dataErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr, i_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr !== p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr) t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr = g_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitRelease g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseToInval g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseToClean g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseWithData g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseIdx g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_dirty g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_state g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_clients g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_alias g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_prefetch g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_prefetchSrc g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_accessed g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_tagErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr !== i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_dataErr g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr, i_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr !== p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr) t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr = g_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tgtID !== i_Arbiter3_TaskWithData__io_out_bits_task_tgtID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_tgtID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_tgtID, i_Arbiter3_TaskWithData__io_out_bits_task_tgtID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_tgtID !== p_Arbiter3_TaskWithData__io_out_bits_task_tgtID) t_Arbiter3_TaskWithData__io_out_bits_task_tgtID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_tgtID = g_Arbiter3_TaskWithData__io_out_bits_task_tgtID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_srcID !== i_Arbiter3_TaskWithData__io_out_bits_task_srcID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_srcID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_srcID, i_Arbiter3_TaskWithData__io_out_bits_task_srcID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_srcID !== p_Arbiter3_TaskWithData__io_out_bits_task_srcID) t_Arbiter3_TaskWithData__io_out_bits_task_srcID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_srcID = g_Arbiter3_TaskWithData__io_out_bits_task_srcID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_txnID !== i_Arbiter3_TaskWithData__io_out_bits_task_txnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_txnID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_txnID, i_Arbiter3_TaskWithData__io_out_bits_task_txnID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_txnID !== p_Arbiter3_TaskWithData__io_out_bits_task_txnID) t_Arbiter3_TaskWithData__io_out_bits_task_txnID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_txnID = g_Arbiter3_TaskWithData__io_out_bits_task_txnID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_homeNID !== i_Arbiter3_TaskWithData__io_out_bits_task_homeNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_homeNID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_homeNID, i_Arbiter3_TaskWithData__io_out_bits_task_homeNID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_homeNID !== p_Arbiter3_TaskWithData__io_out_bits_task_homeNID) t_Arbiter3_TaskWithData__io_out_bits_task_homeNID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_homeNID = g_Arbiter3_TaskWithData__io_out_bits_task_homeNID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dbID !== i_Arbiter3_TaskWithData__io_out_bits_task_dbID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_dbID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_dbID, i_Arbiter3_TaskWithData__io_out_bits_task_dbID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_dbID !== p_Arbiter3_TaskWithData__io_out_bits_task_dbID) t_Arbiter3_TaskWithData__io_out_bits_task_dbID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_dbID = g_Arbiter3_TaskWithData__io_out_bits_task_dbID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID !== i_Arbiter3_TaskWithData__io_out_bits_task_fwdNID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_fwdNID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID, i_Arbiter3_TaskWithData__io_out_bits_task_fwdNID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID !== p_Arbiter3_TaskWithData__io_out_bits_task_fwdNID) t_Arbiter3_TaskWithData__io_out_bits_task_fwdNID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_fwdNID = g_Arbiter3_TaskWithData__io_out_bits_task_fwdNID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID !== i_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_fwdTxnID g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID, i_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID !== p_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID) t_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID = g_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode !== i_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_chiOpcode g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode, i_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode !== p_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode) t_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode = g_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_resp !== i_Arbiter3_TaskWithData__io_out_bits_task_resp) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_resp g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_resp, i_Arbiter3_TaskWithData__io_out_bits_task_resp);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_resp !== p_Arbiter3_TaskWithData__io_out_bits_task_resp) t_Arbiter3_TaskWithData__io_out_bits_task_resp = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_resp = g_Arbiter3_TaskWithData__io_out_bits_task_resp;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdState !== i_Arbiter3_TaskWithData__io_out_bits_task_fwdState) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_fwdState g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_fwdState, i_Arbiter3_TaskWithData__io_out_bits_task_fwdState);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_fwdState !== p_Arbiter3_TaskWithData__io_out_bits_task_fwdState) t_Arbiter3_TaskWithData__io_out_bits_task_fwdState = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_fwdState = g_Arbiter3_TaskWithData__io_out_bits_task_fwdState;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType !== i_Arbiter3_TaskWithData__io_out_bits_task_pCrdType) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_pCrdType g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType, i_Arbiter3_TaskWithData__io_out_bits_task_pCrdType);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType !== p_Arbiter3_TaskWithData__io_out_bits_task_pCrdType) t_Arbiter3_TaskWithData__io_out_bits_task_pCrdType = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_pCrdType = g_Arbiter3_TaskWithData__io_out_bits_task_pCrdType;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc !== i_Arbiter3_TaskWithData__io_out_bits_task_retToSrc) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_retToSrc g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc, i_Arbiter3_TaskWithData__io_out_bits_task_retToSrc);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc !== p_Arbiter3_TaskWithData__io_out_bits_task_retToSrc) t_Arbiter3_TaskWithData__io_out_bits_task_retToSrc = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_retToSrc = g_Arbiter3_TaskWithData__io_out_bits_task_retToSrc;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared !== i_Arbiter3_TaskWithData__io_out_bits_task_likelyshared) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_likelyshared g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared, i_Arbiter3_TaskWithData__io_out_bits_task_likelyshared);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared !== p_Arbiter3_TaskWithData__io_out_bits_task_likelyshared) t_Arbiter3_TaskWithData__io_out_bits_task_likelyshared = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_likelyshared = g_Arbiter3_TaskWithData__io_out_bits_task_likelyshared;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck !== i_Arbiter3_TaskWithData__io_out_bits_task_expCompAck) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_expCompAck g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck, i_Arbiter3_TaskWithData__io_out_bits_task_expCompAck);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck !== p_Arbiter3_TaskWithData__io_out_bits_task_expCompAck) t_Arbiter3_TaskWithData__io_out_bits_task_expCompAck = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_expCompAck = g_Arbiter3_TaskWithData__io_out_bits_task_expCompAck;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry !== i_Arbiter3_TaskWithData__io_out_bits_task_allowRetry) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_allowRetry g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry, i_Arbiter3_TaskWithData__io_out_bits_task_allowRetry);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry !== p_Arbiter3_TaskWithData__io_out_bits_task_allowRetry) t_Arbiter3_TaskWithData__io_out_bits_task_allowRetry = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_allowRetry = g_Arbiter3_TaskWithData__io_out_bits_task_allowRetry;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate !== i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_memAttr_allocate g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate, i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate !== p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate) t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate = g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable !== i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_memAttr_cacheable g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable, i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable !== p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable) t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable = g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device !== i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_memAttr_device g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device, i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device !== p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device) t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device = g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa !== i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_memAttr_ewa g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa, i_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa !== p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa) t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa = g_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_task_traceTag !== i_Arbiter3_TaskWithData__io_out_bits_task_traceTag) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_task_traceTag g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_task_traceTag, i_Arbiter3_TaskWithData__io_out_bits_task_traceTag);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_task_traceTag !== p_Arbiter3_TaskWithData__io_out_bits_task_traceTag) t_Arbiter3_TaskWithData__io_out_bits_task_traceTag = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_task_traceTag = g_Arbiter3_TaskWithData__io_out_bits_task_traceTag;
    checks++;
    if (g_Arbiter3_TaskWithData__io_out_bits_data_data !== i_Arbiter3_TaskWithData__io_out_bits_data_data) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Arbiter3_TaskWithData.io_out_bits_data_data g=%h i=%h", cyc, g_Arbiter3_TaskWithData__io_out_bits_data_data, i_Arbiter3_TaskWithData__io_out_bits_data_data);
    end
    if (g_Arbiter3_TaskWithData__io_out_bits_data_data !== p_Arbiter3_TaskWithData__io_out_bits_data_data) t_Arbiter3_TaskWithData__io_out_bits_data_data = 1'b1;
    p_Arbiter3_TaskWithData__io_out_bits_data_data = g_Arbiter3_TaskWithData__io_out_bits_data_data;
  endtask
  longint cov_Arbiter3_TaskWithData_only2 = 0;
  longint cov_Arbiter3_TaskWithData_all = 0;
  task automatic cover_Arbiter3_TaskWithData();
    if (!Arbiter3_TaskWithData__io_in_0_valid && !Arbiter3_TaskWithData__io_in_1_valid && Arbiter3_TaskWithData__io_in_2_valid) cov_Arbiter3_TaskWithData_only2++;
    if (Arbiter3_TaskWithData__io_in_0_valid && Arbiter3_TaskWithData__io_in_1_valid && Arbiter3_TaskWithData__io_in_2_valid) cov_Arbiter3_TaskWithData_all++;
  endtask
  task automatic preinit_Arbiter3_TaskWithData();
  endtask
  task automatic sync_Arbiter3_TaskWithData();
  endtask

  // ======================= Queue16_HintQueueEntry =======================
  logic Queue16_HintQueueEntry__io_enq_valid;
  logic [6:0] Queue16_HintQueueEntry__io_enq_bits_source;
  logic [2:0] Queue16_HintQueueEntry__io_enq_bits_opcode;
  logic Queue16_HintQueueEntry__io_enq_bits_isKeyword;
  logic Queue16_HintQueueEntry__io_deq_ready;
  wire  g_Queue16_HintQueueEntry__io_enq_ready;
  wire  i_Queue16_HintQueueEntry__io_enq_ready;
  logic p_Queue16_HintQueueEntry__io_enq_ready;
  bit   t_Queue16_HintQueueEntry__io_enq_ready;
  wire  g_Queue16_HintQueueEntry__io_deq_valid;
  wire  i_Queue16_HintQueueEntry__io_deq_valid;
  logic p_Queue16_HintQueueEntry__io_deq_valid;
  bit   t_Queue16_HintQueueEntry__io_deq_valid;
  wire  [6:0] g_Queue16_HintQueueEntry__io_deq_bits_source;
  wire  [6:0] i_Queue16_HintQueueEntry__io_deq_bits_source;
  logic [6:0] p_Queue16_HintQueueEntry__io_deq_bits_source;
  bit   t_Queue16_HintQueueEntry__io_deq_bits_source;
  wire  [2:0] g_Queue16_HintQueueEntry__io_deq_bits_opcode;
  wire  [2:0] i_Queue16_HintQueueEntry__io_deq_bits_opcode;
  logic [2:0] p_Queue16_HintQueueEntry__io_deq_bits_opcode;
  bit   t_Queue16_HintQueueEntry__io_deq_bits_opcode;
  wire  g_Queue16_HintQueueEntry__io_deq_bits_isKeyword;
  wire  i_Queue16_HintQueueEntry__io_deq_bits_isKeyword;
  logic p_Queue16_HintQueueEntry__io_deq_bits_isKeyword;
  bit   t_Queue16_HintQueueEntry__io_deq_bits_isKeyword;
  Queue16_HintQueueEntry u_g_Queue16_HintQueueEntry (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue16_HintQueueEntry__io_enq_ready),
    .io_enq_valid (Queue16_HintQueueEntry__io_enq_valid),
    .io_enq_bits_source (Queue16_HintQueueEntry__io_enq_bits_source),
    .io_enq_bits_opcode (Queue16_HintQueueEntry__io_enq_bits_opcode),
    .io_enq_bits_isKeyword (Queue16_HintQueueEntry__io_enq_bits_isKeyword),
    .io_deq_ready (Queue16_HintQueueEntry__io_deq_ready),
    .io_deq_valid (g_Queue16_HintQueueEntry__io_deq_valid),
    .io_deq_bits_source (g_Queue16_HintQueueEntry__io_deq_bits_source),
    .io_deq_bits_opcode (g_Queue16_HintQueueEntry__io_deq_bits_opcode),
    .io_deq_bits_isKeyword (g_Queue16_HintQueueEntry__io_deq_bits_isKeyword)
  );
  Queue16_HintQueueEntry_xs u_i_Queue16_HintQueueEntry (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue16_HintQueueEntry__io_enq_ready),
    .io_enq_valid (Queue16_HintQueueEntry__io_enq_valid),
    .io_enq_bits_source (Queue16_HintQueueEntry__io_enq_bits_source),
    .io_enq_bits_opcode (Queue16_HintQueueEntry__io_enq_bits_opcode),
    .io_enq_bits_isKeyword (Queue16_HintQueueEntry__io_enq_bits_isKeyword),
    .io_deq_ready (Queue16_HintQueueEntry__io_deq_ready),
    .io_deq_valid (i_Queue16_HintQueueEntry__io_deq_valid),
    .io_deq_bits_source (i_Queue16_HintQueueEntry__io_deq_bits_source),
    .io_deq_bits_opcode (i_Queue16_HintQueueEntry__io_deq_bits_opcode),
    .io_deq_bits_isKeyword (i_Queue16_HintQueueEntry__io_deq_bits_isKeyword)
  );
  task automatic drive_Queue16_HintQueueEntry();
    Queue16_HintQueueEntry__io_enq_valid = $urandom % 2;
    Queue16_HintQueueEntry__io_enq_bits_source = rnd(7);
    Queue16_HintQueueEntry__io_enq_bits_opcode = rnd(3);
    Queue16_HintQueueEntry__io_enq_bits_isKeyword = $urandom % 2;
    Queue16_HintQueueEntry__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue16_HintQueueEntry();
    checks++;
    if (g_Queue16_HintQueueEntry__io_enq_ready !== i_Queue16_HintQueueEntry__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_HintQueueEntry.io_enq_ready g=%h i=%h", cyc, g_Queue16_HintQueueEntry__io_enq_ready, i_Queue16_HintQueueEntry__io_enq_ready);
    end
    if (g_Queue16_HintQueueEntry__io_enq_ready !== p_Queue16_HintQueueEntry__io_enq_ready) t_Queue16_HintQueueEntry__io_enq_ready = 1'b1;
    p_Queue16_HintQueueEntry__io_enq_ready = g_Queue16_HintQueueEntry__io_enq_ready;
    checks++;
    if (g_Queue16_HintQueueEntry__io_deq_valid !== i_Queue16_HintQueueEntry__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_HintQueueEntry.io_deq_valid g=%h i=%h", cyc, g_Queue16_HintQueueEntry__io_deq_valid, i_Queue16_HintQueueEntry__io_deq_valid);
    end
    if (g_Queue16_HintQueueEntry__io_deq_valid !== p_Queue16_HintQueueEntry__io_deq_valid) t_Queue16_HintQueueEntry__io_deq_valid = 1'b1;
    p_Queue16_HintQueueEntry__io_deq_valid = g_Queue16_HintQueueEntry__io_deq_valid;
    checks++;
    if (g_Queue16_HintQueueEntry__io_deq_bits_source !== i_Queue16_HintQueueEntry__io_deq_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_HintQueueEntry.io_deq_bits_source g=%h i=%h", cyc, g_Queue16_HintQueueEntry__io_deq_bits_source, i_Queue16_HintQueueEntry__io_deq_bits_source);
    end
    if (g_Queue16_HintQueueEntry__io_deq_bits_source !== p_Queue16_HintQueueEntry__io_deq_bits_source) t_Queue16_HintQueueEntry__io_deq_bits_source = 1'b1;
    p_Queue16_HintQueueEntry__io_deq_bits_source = g_Queue16_HintQueueEntry__io_deq_bits_source;
    checks++;
    if (g_Queue16_HintQueueEntry__io_deq_bits_opcode !== i_Queue16_HintQueueEntry__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_HintQueueEntry.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue16_HintQueueEntry__io_deq_bits_opcode, i_Queue16_HintQueueEntry__io_deq_bits_opcode);
    end
    if (g_Queue16_HintQueueEntry__io_deq_bits_opcode !== p_Queue16_HintQueueEntry__io_deq_bits_opcode) t_Queue16_HintQueueEntry__io_deq_bits_opcode = 1'b1;
    p_Queue16_HintQueueEntry__io_deq_bits_opcode = g_Queue16_HintQueueEntry__io_deq_bits_opcode;
    checks++;
    if (g_Queue16_HintQueueEntry__io_deq_bits_isKeyword !== i_Queue16_HintQueueEntry__io_deq_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue16_HintQueueEntry.io_deq_bits_isKeyword g=%h i=%h", cyc, g_Queue16_HintQueueEntry__io_deq_bits_isKeyword, i_Queue16_HintQueueEntry__io_deq_bits_isKeyword);
    end
    if (g_Queue16_HintQueueEntry__io_deq_bits_isKeyword !== p_Queue16_HintQueueEntry__io_deq_bits_isKeyword) t_Queue16_HintQueueEntry__io_deq_bits_isKeyword = 1'b1;
    p_Queue16_HintQueueEntry__io_deq_bits_isKeyword = g_Queue16_HintQueueEntry__io_deq_bits_isKeyword;
  endtask
  longint cov_Queue16_HintQueueEntry_full = 0;
  longint cov_Queue16_HintQueueEntry_deq = 0;
  task automatic cover_Queue16_HintQueueEntry();
    if (!u_g_Queue16_HintQueueEntry.io_enq_ready) cov_Queue16_HintQueueEntry_full++;
    if (u_g_Queue16_HintQueueEntry.do_deq) cov_Queue16_HintQueueEntry_deq++;
  endtask
  task automatic preinit_Queue16_HintQueueEntry();
  endtask
  task automatic sync_Queue16_HintQueueEntry();
    u_i_Queue16_HintQueueEntry.ram_ext.Memory = u_g_Queue16_HintQueueEntry.ram_ext.Memory;
  endtask

  // ======================= Queue4_HintQueueEntry =======================
  logic Queue4_HintQueueEntry__io_enq_valid;
  logic [6:0] Queue4_HintQueueEntry__io_enq_bits_source;
  logic [2:0] Queue4_HintQueueEntry__io_enq_bits_opcode;
  logic Queue4_HintQueueEntry__io_enq_bits_isKeyword;
  logic Queue4_HintQueueEntry__io_deq_ready;
  wire  g_Queue4_HintQueueEntry__io_enq_ready;
  wire  i_Queue4_HintQueueEntry__io_enq_ready;
  logic p_Queue4_HintQueueEntry__io_enq_ready;
  bit   t_Queue4_HintQueueEntry__io_enq_ready;
  wire  g_Queue4_HintQueueEntry__io_deq_valid;
  wire  i_Queue4_HintQueueEntry__io_deq_valid;
  logic p_Queue4_HintQueueEntry__io_deq_valid;
  bit   t_Queue4_HintQueueEntry__io_deq_valid;
  wire  [6:0] g_Queue4_HintQueueEntry__io_deq_bits_source;
  wire  [6:0] i_Queue4_HintQueueEntry__io_deq_bits_source;
  logic [6:0] p_Queue4_HintQueueEntry__io_deq_bits_source;
  bit   t_Queue4_HintQueueEntry__io_deq_bits_source;
  wire  [2:0] g_Queue4_HintQueueEntry__io_deq_bits_opcode;
  wire  [2:0] i_Queue4_HintQueueEntry__io_deq_bits_opcode;
  logic [2:0] p_Queue4_HintQueueEntry__io_deq_bits_opcode;
  bit   t_Queue4_HintQueueEntry__io_deq_bits_opcode;
  wire  g_Queue4_HintQueueEntry__io_deq_bits_isKeyword;
  wire  i_Queue4_HintQueueEntry__io_deq_bits_isKeyword;
  logic p_Queue4_HintQueueEntry__io_deq_bits_isKeyword;
  bit   t_Queue4_HintQueueEntry__io_deq_bits_isKeyword;
  Queue4_HintQueueEntry u_g_Queue4_HintQueueEntry (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (g_Queue4_HintQueueEntry__io_enq_ready),
    .io_enq_valid (Queue4_HintQueueEntry__io_enq_valid),
    .io_enq_bits_source (Queue4_HintQueueEntry__io_enq_bits_source),
    .io_enq_bits_opcode (Queue4_HintQueueEntry__io_enq_bits_opcode),
    .io_enq_bits_isKeyword (Queue4_HintQueueEntry__io_enq_bits_isKeyword),
    .io_deq_ready (Queue4_HintQueueEntry__io_deq_ready),
    .io_deq_valid (g_Queue4_HintQueueEntry__io_deq_valid),
    .io_deq_bits_source (g_Queue4_HintQueueEntry__io_deq_bits_source),
    .io_deq_bits_opcode (g_Queue4_HintQueueEntry__io_deq_bits_opcode),
    .io_deq_bits_isKeyword (g_Queue4_HintQueueEntry__io_deq_bits_isKeyword)
  );
  Queue4_HintQueueEntry_xs u_i_Queue4_HintQueueEntry (
    .clock (clock),
    .reset (reset),
    .io_enq_ready (i_Queue4_HintQueueEntry__io_enq_ready),
    .io_enq_valid (Queue4_HintQueueEntry__io_enq_valid),
    .io_enq_bits_source (Queue4_HintQueueEntry__io_enq_bits_source),
    .io_enq_bits_opcode (Queue4_HintQueueEntry__io_enq_bits_opcode),
    .io_enq_bits_isKeyword (Queue4_HintQueueEntry__io_enq_bits_isKeyword),
    .io_deq_ready (Queue4_HintQueueEntry__io_deq_ready),
    .io_deq_valid (i_Queue4_HintQueueEntry__io_deq_valid),
    .io_deq_bits_source (i_Queue4_HintQueueEntry__io_deq_bits_source),
    .io_deq_bits_opcode (i_Queue4_HintQueueEntry__io_deq_bits_opcode),
    .io_deq_bits_isKeyword (i_Queue4_HintQueueEntry__io_deq_bits_isKeyword)
  );
  task automatic drive_Queue4_HintQueueEntry();
    Queue4_HintQueueEntry__io_enq_valid = $urandom % 2;
    Queue4_HintQueueEntry__io_enq_bits_source = rnd(7);
    Queue4_HintQueueEntry__io_enq_bits_opcode = rnd(3);
    Queue4_HintQueueEntry__io_enq_bits_isKeyword = $urandom % 2;
    Queue4_HintQueueEntry__io_deq_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask
  task automatic check_Queue4_HintQueueEntry();
    checks++;
    if (g_Queue4_HintQueueEntry__io_enq_ready !== i_Queue4_HintQueueEntry__io_enq_ready) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_HintQueueEntry.io_enq_ready g=%h i=%h", cyc, g_Queue4_HintQueueEntry__io_enq_ready, i_Queue4_HintQueueEntry__io_enq_ready);
    end
    if (g_Queue4_HintQueueEntry__io_enq_ready !== p_Queue4_HintQueueEntry__io_enq_ready) t_Queue4_HintQueueEntry__io_enq_ready = 1'b1;
    p_Queue4_HintQueueEntry__io_enq_ready = g_Queue4_HintQueueEntry__io_enq_ready;
    checks++;
    if (g_Queue4_HintQueueEntry__io_deq_valid !== i_Queue4_HintQueueEntry__io_deq_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_HintQueueEntry.io_deq_valid g=%h i=%h", cyc, g_Queue4_HintQueueEntry__io_deq_valid, i_Queue4_HintQueueEntry__io_deq_valid);
    end
    if (g_Queue4_HintQueueEntry__io_deq_valid !== p_Queue4_HintQueueEntry__io_deq_valid) t_Queue4_HintQueueEntry__io_deq_valid = 1'b1;
    p_Queue4_HintQueueEntry__io_deq_valid = g_Queue4_HintQueueEntry__io_deq_valid;
    checks++;
    if (g_Queue4_HintQueueEntry__io_deq_bits_source !== i_Queue4_HintQueueEntry__io_deq_bits_source) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_HintQueueEntry.io_deq_bits_source g=%h i=%h", cyc, g_Queue4_HintQueueEntry__io_deq_bits_source, i_Queue4_HintQueueEntry__io_deq_bits_source);
    end
    if (g_Queue4_HintQueueEntry__io_deq_bits_source !== p_Queue4_HintQueueEntry__io_deq_bits_source) t_Queue4_HintQueueEntry__io_deq_bits_source = 1'b1;
    p_Queue4_HintQueueEntry__io_deq_bits_source = g_Queue4_HintQueueEntry__io_deq_bits_source;
    checks++;
    if (g_Queue4_HintQueueEntry__io_deq_bits_opcode !== i_Queue4_HintQueueEntry__io_deq_bits_opcode) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_HintQueueEntry.io_deq_bits_opcode g=%h i=%h", cyc, g_Queue4_HintQueueEntry__io_deq_bits_opcode, i_Queue4_HintQueueEntry__io_deq_bits_opcode);
    end
    if (g_Queue4_HintQueueEntry__io_deq_bits_opcode !== p_Queue4_HintQueueEntry__io_deq_bits_opcode) t_Queue4_HintQueueEntry__io_deq_bits_opcode = 1'b1;
    p_Queue4_HintQueueEntry__io_deq_bits_opcode = g_Queue4_HintQueueEntry__io_deq_bits_opcode;
    checks++;
    if (g_Queue4_HintQueueEntry__io_deq_bits_isKeyword !== i_Queue4_HintQueueEntry__io_deq_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH Queue4_HintQueueEntry.io_deq_bits_isKeyword g=%h i=%h", cyc, g_Queue4_HintQueueEntry__io_deq_bits_isKeyword, i_Queue4_HintQueueEntry__io_deq_bits_isKeyword);
    end
    if (g_Queue4_HintQueueEntry__io_deq_bits_isKeyword !== p_Queue4_HintQueueEntry__io_deq_bits_isKeyword) t_Queue4_HintQueueEntry__io_deq_bits_isKeyword = 1'b1;
    p_Queue4_HintQueueEntry__io_deq_bits_isKeyword = g_Queue4_HintQueueEntry__io_deq_bits_isKeyword;
  endtask
  longint cov_Queue4_HintQueueEntry_full = 0;
  longint cov_Queue4_HintQueueEntry_deq = 0;
  longint cov_Queue4_HintQueueEntry_bypass = 0;
  task automatic cover_Queue4_HintQueueEntry();
    if (!u_g_Queue4_HintQueueEntry.io_enq_ready) cov_Queue4_HintQueueEntry_full++;
    if (u_g_Queue4_HintQueueEntry.do_deq) cov_Queue4_HintQueueEntry_deq++;
    if (u_g_Queue4_HintQueueEntry.empty && Queue4_HintQueueEntry__io_enq_valid && Queue4_HintQueueEntry__io_deq_ready) cov_Queue4_HintQueueEntry_bypass++;
  endtask
  task automatic preinit_Queue4_HintQueueEntry();
  endtask
  task automatic sync_Queue4_HintQueueEntry();
    u_i_Queue4_HintQueueEntry.ram_ext.Memory = u_g_Queue4_HintQueueEntry.ram_ext.Memory;
  endtask

  // ======================= CustomL1Hint =======================
  logic CustomL1Hint__io_s1_valid;
  logic [2:0] CustomL1Hint__io_s1_bits_channel;
  logic CustomL1Hint__io_s1_bits_isKeyword;
  logic [3:0] CustomL1Hint__io_s1_bits_opcode;
  logic [6:0] CustomL1Hint__io_s1_bits_sourceId;
  logic CustomL1Hint__io_s1_bits_mshrTask;
  logic CustomL1Hint__io_s1_bits_mergeA;
  logic CustomL1Hint__io_s1_bits_aMergeTask_isKeyword;
  logic [2:0] CustomL1Hint__io_s1_bits_aMergeTask_opcode;
  logic [6:0] CustomL1Hint__io_s1_bits_aMergeTask_sourceId;
  logic CustomL1Hint__io_s3_task_valid;
  logic [2:0] CustomL1Hint__io_s3_task_bits_channel;
  logic CustomL1Hint__io_s3_task_bits_isKeyword;
  logic [3:0] CustomL1Hint__io_s3_task_bits_opcode;
  logic [6:0] CustomL1Hint__io_s3_task_bits_sourceId;
  logic CustomL1Hint__io_s3_task_bits_mshrTask;
  logic CustomL1Hint__io_s3_need_mshr;
  logic CustomL1Hint__io_l1Hint_ready;
  wire  g_CustomL1Hint__io_l1Hint_valid;
  wire  i_CustomL1Hint__io_l1Hint_valid;
  logic p_CustomL1Hint__io_l1Hint_valid;
  bit   t_CustomL1Hint__io_l1Hint_valid;
  wire  [31:0] g_CustomL1Hint__io_l1Hint_bits_sourceId;
  wire  [31:0] i_CustomL1Hint__io_l1Hint_bits_sourceId;
  logic [31:0] p_CustomL1Hint__io_l1Hint_bits_sourceId;
  bit   t_CustomL1Hint__io_l1Hint_bits_sourceId;
  wire  g_CustomL1Hint__io_l1Hint_bits_isKeyword;
  wire  i_CustomL1Hint__io_l1Hint_bits_isKeyword;
  logic p_CustomL1Hint__io_l1Hint_bits_isKeyword;
  bit   t_CustomL1Hint__io_l1Hint_bits_isKeyword;
  CustomL1Hint u_g_CustomL1Hint (
    .clock (clock),
    .reset (reset),
    .io_s1_valid (CustomL1Hint__io_s1_valid),
    .io_s1_bits_channel (CustomL1Hint__io_s1_bits_channel),
    .io_s1_bits_isKeyword (CustomL1Hint__io_s1_bits_isKeyword),
    .io_s1_bits_opcode (CustomL1Hint__io_s1_bits_opcode),
    .io_s1_bits_sourceId (CustomL1Hint__io_s1_bits_sourceId),
    .io_s1_bits_mshrTask (CustomL1Hint__io_s1_bits_mshrTask),
    .io_s1_bits_mergeA (CustomL1Hint__io_s1_bits_mergeA),
    .io_s1_bits_aMergeTask_isKeyword (CustomL1Hint__io_s1_bits_aMergeTask_isKeyword),
    .io_s1_bits_aMergeTask_opcode (CustomL1Hint__io_s1_bits_aMergeTask_opcode),
    .io_s1_bits_aMergeTask_sourceId (CustomL1Hint__io_s1_bits_aMergeTask_sourceId),
    .io_s3_task_valid (CustomL1Hint__io_s3_task_valid),
    .io_s3_task_bits_channel (CustomL1Hint__io_s3_task_bits_channel),
    .io_s3_task_bits_isKeyword (CustomL1Hint__io_s3_task_bits_isKeyword),
    .io_s3_task_bits_opcode (CustomL1Hint__io_s3_task_bits_opcode),
    .io_s3_task_bits_sourceId (CustomL1Hint__io_s3_task_bits_sourceId),
    .io_s3_task_bits_mshrTask (CustomL1Hint__io_s3_task_bits_mshrTask),
    .io_s3_need_mshr (CustomL1Hint__io_s3_need_mshr),
    .io_l1Hint_ready (CustomL1Hint__io_l1Hint_ready),
    .io_l1Hint_valid (g_CustomL1Hint__io_l1Hint_valid),
    .io_l1Hint_bits_sourceId (g_CustomL1Hint__io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword (g_CustomL1Hint__io_l1Hint_bits_isKeyword)
  );
  CustomL1Hint_xs u_i_CustomL1Hint (
    .clock (clock),
    .reset (reset),
    .io_s1_valid (CustomL1Hint__io_s1_valid),
    .io_s1_bits_channel (CustomL1Hint__io_s1_bits_channel),
    .io_s1_bits_isKeyword (CustomL1Hint__io_s1_bits_isKeyword),
    .io_s1_bits_opcode (CustomL1Hint__io_s1_bits_opcode),
    .io_s1_bits_sourceId (CustomL1Hint__io_s1_bits_sourceId),
    .io_s1_bits_mshrTask (CustomL1Hint__io_s1_bits_mshrTask),
    .io_s1_bits_mergeA (CustomL1Hint__io_s1_bits_mergeA),
    .io_s1_bits_aMergeTask_isKeyword (CustomL1Hint__io_s1_bits_aMergeTask_isKeyword),
    .io_s1_bits_aMergeTask_opcode (CustomL1Hint__io_s1_bits_aMergeTask_opcode),
    .io_s1_bits_aMergeTask_sourceId (CustomL1Hint__io_s1_bits_aMergeTask_sourceId),
    .io_s3_task_valid (CustomL1Hint__io_s3_task_valid),
    .io_s3_task_bits_channel (CustomL1Hint__io_s3_task_bits_channel),
    .io_s3_task_bits_isKeyword (CustomL1Hint__io_s3_task_bits_isKeyword),
    .io_s3_task_bits_opcode (CustomL1Hint__io_s3_task_bits_opcode),
    .io_s3_task_bits_sourceId (CustomL1Hint__io_s3_task_bits_sourceId),
    .io_s3_task_bits_mshrTask (CustomL1Hint__io_s3_task_bits_mshrTask),
    .io_s3_need_mshr (CustomL1Hint__io_s3_need_mshr),
    .io_l1Hint_ready (CustomL1Hint__io_l1Hint_ready),
    .io_l1Hint_valid (i_CustomL1Hint__io_l1Hint_valid),
    .io_l1Hint_bits_sourceId (i_CustomL1Hint__io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword (i_CustomL1Hint__io_l1Hint_bits_isKeyword)
  );
  task automatic drive_CustomL1Hint();
    CustomL1Hint__io_s1_valid = $urandom % 2;
    CustomL1Hint__io_s1_bits_channel = 3'($urandom_range(0, 3) == 0 ? $urandom_range(0, 7) : (($urandom % 2) ? 1 : 4));
    CustomL1Hint__io_s1_bits_isKeyword = $urandom % 2;
    CustomL1Hint__io_s1_bits_opcode = 4'($urandom_range(0, 3) == 0 ? $urandom_range(0, 15) : $urandom_range(4, 7));
    CustomL1Hint__io_s1_bits_sourceId = rnd(7);
    CustomL1Hint__io_s1_bits_mshrTask = $urandom % 2;
    CustomL1Hint__io_s1_bits_mergeA = $urandom % 2;
    CustomL1Hint__io_s1_bits_aMergeTask_isKeyword = $urandom % 2;
    CustomL1Hint__io_s1_bits_aMergeTask_opcode = 3'($urandom_range(3, 6));
    CustomL1Hint__io_s1_bits_aMergeTask_sourceId = rnd(7);
    CustomL1Hint__io_s3_task_valid = $urandom % 2;
    CustomL1Hint__io_s3_task_bits_channel = 3'($urandom_range(0, 3) == 0 ? $urandom_range(0, 7) : (($urandom % 2) ? 1 : 4));
    CustomL1Hint__io_s3_task_bits_isKeyword = $urandom % 2;
    CustomL1Hint__io_s3_task_bits_opcode = 4'($urandom_range(0, 3) == 0 ? $urandom_range(0, 15) : $urandom_range(4, 7));
    CustomL1Hint__io_s3_task_bits_sourceId = rnd(7);
    CustomL1Hint__io_s3_task_bits_mshrTask = $urandom % 2;
    CustomL1Hint__io_s3_need_mshr = $urandom % 2;
    CustomL1Hint__io_l1Hint_ready = ((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 32) == 0);
  endtask
  task automatic check_CustomL1Hint();
    checks++;
    if (g_CustomL1Hint__io_l1Hint_valid !== i_CustomL1Hint__io_l1Hint_valid) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH CustomL1Hint.io_l1Hint_valid g=%h i=%h", cyc, g_CustomL1Hint__io_l1Hint_valid, i_CustomL1Hint__io_l1Hint_valid);
    end
    if (g_CustomL1Hint__io_l1Hint_valid !== p_CustomL1Hint__io_l1Hint_valid) t_CustomL1Hint__io_l1Hint_valid = 1'b1;
    p_CustomL1Hint__io_l1Hint_valid = g_CustomL1Hint__io_l1Hint_valid;
    checks++;
    if (g_CustomL1Hint__io_l1Hint_bits_sourceId !== i_CustomL1Hint__io_l1Hint_bits_sourceId) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH CustomL1Hint.io_l1Hint_bits_sourceId g=%h i=%h", cyc, g_CustomL1Hint__io_l1Hint_bits_sourceId, i_CustomL1Hint__io_l1Hint_bits_sourceId);
    end
    if (g_CustomL1Hint__io_l1Hint_bits_sourceId !== p_CustomL1Hint__io_l1Hint_bits_sourceId) t_CustomL1Hint__io_l1Hint_bits_sourceId = 1'b1;
    p_CustomL1Hint__io_l1Hint_bits_sourceId = g_CustomL1Hint__io_l1Hint_bits_sourceId;
    checks++;
    if (g_CustomL1Hint__io_l1Hint_bits_isKeyword !== i_CustomL1Hint__io_l1Hint_bits_isKeyword) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH CustomL1Hint.io_l1Hint_bits_isKeyword g=%h i=%h", cyc, g_CustomL1Hint__io_l1Hint_bits_isKeyword, i_CustomL1Hint__io_l1Hint_bits_isKeyword);
    end
    if (g_CustomL1Hint__io_l1Hint_bits_isKeyword !== p_CustomL1Hint__io_l1Hint_bits_isKeyword) t_CustomL1Hint__io_l1Hint_bits_isKeyword = 1'b1;
    p_CustomL1Hint__io_l1Hint_bits_isKeyword = g_CustomL1Hint__io_l1Hint_bits_isKeyword;
  endtask
  longint cov_CustomL1Hint_hint = 0;
  longint cov_CustomL1Hint_s3wins = 0;
  longint cov_CustomL1Hint_s1full = 0;
  longint cov_CustomL1Hint_hqfull = 0;
  longint cov_CustomL1Hint_mergeGrant = 0;
  task automatic cover_CustomL1Hint();
    if (u_g_CustomL1Hint.io_l1Hint_valid) cov_CustomL1Hint_hint++;
    if (u_g_CustomL1Hint.enqValid_s3 && u_g_CustomL1Hint._hint_s1Queue_io_deq_valid) cov_CustomL1Hint_s3wins++;
    if (!u_g_CustomL1Hint._hint_s1Queue_io_enq_ready) cov_CustomL1Hint_s1full++;
    if (!u_g_CustomL1Hint._hintQueue_io_enq_ready) cov_CustomL1Hint_hqfull++;
    if (u_g_CustomL1Hint.mshr_Grant_s1 && u_g_CustomL1Hint.io_s1_bits_mergeA) cov_CustomL1Hint_mergeGrant++;
  endtask
  task automatic preinit_CustomL1Hint();
  endtask
  task automatic sync_CustomL1Hint();
    u_i_CustomL1Hint.hintQueue.ram_ext.Memory = u_g_CustomL1Hint.hintQueue.ram_ext.Memory;
    u_i_CustomL1Hint.hint_s1Queue.ram_ext.Memory = u_g_CustomL1Hint.hint_s1Queue.ram_ext.Memory;
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_Arbiter3_CHIREQ();
    drive_Arbiter3_TaskBundle();
    drive_Arbiter3_TaskWithData();
    drive_Queue16_HintQueueEntry();
    drive_Queue4_HintQueueEntry();
    drive_CustomL1Hint();
    #1;
    preinit_Arbiter3_CHIREQ();
    preinit_Arbiter3_TaskBundle();
    preinit_Arbiter3_TaskWithData();
    preinit_Queue16_HintQueueEntry();
    preinit_Queue4_HintQueueEntry();
    preinit_CustomL1Hint();
    sync_Arbiter3_CHIREQ();
    sync_Arbiter3_TaskBundle();
    sync_Arbiter3_TaskWithData();
    sync_Queue16_HintQueueEntry();
    sync_Queue4_HintQueueEntry();
    sync_CustomL1Hint();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_Arbiter3_CHIREQ();
      drive_Arbiter3_TaskBundle();
      drive_Arbiter3_TaskWithData();
      drive_Queue16_HintQueueEntry();
      drive_Queue4_HintQueueEntry();
      drive_CustomL1Hint();
      #1;
      check_Arbiter3_CHIREQ();
      cover_Arbiter3_CHIREQ();
      check_Arbiter3_TaskBundle();
      cover_Arbiter3_TaskBundle();
      check_Arbiter3_TaskWithData();
      cover_Arbiter3_TaskWithData();
      check_Queue16_HintQueueEntry();
      cover_Queue16_HintQueueEntry();
      check_Queue4_HintQueueEntry();
      cover_Queue4_HintQueueEntry();
      check_CustomL1Hint();
      cover_CustomL1Hint();
    end
    begin int tg; tg = 0;
      if (t_Arbiter3_CHIREQ__io_in_1_ready) tg++; else $display("COV: Arbiter3_CHIREQ.io_in_1_ready never toggled");
      if (t_Arbiter3_CHIREQ__io_in_2_ready) tg++; else $display("COV: Arbiter3_CHIREQ.io_in_2_ready never toggled");
      if (t_Arbiter3_CHIREQ__io_out_valid) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_valid never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_tgtID) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_tgtID never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_srcID) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_srcID never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_txnID) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_txnID never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_opcode) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_opcode never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_addr) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_addr never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_likelyshared) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_likelyshared never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_allowRetry) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_allowRetry never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_pCrdType) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_pCrdType never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_memAttr_allocate) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_memAttr_allocate never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_memAttr_cacheable) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_memAttr_cacheable never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_memAttr_device) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_memAttr_device never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_memAttr_ewa) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_memAttr_ewa never toggled");
      if (t_Arbiter3_CHIREQ__io_out_bits_expCompAck) tg++; else $display("COV: Arbiter3_CHIREQ.io_out_bits_expCompAck never toggled");
      $display("Arbiter3_CHIREQ: toggled=%0d/16 (need >= 16)", tg);
      if (tg < 16) covfail = 1;
      $display("Arbiter3_CHIREQ: cover only2 = %0d", cov_Arbiter3_CHIREQ_only2);
      if (cov_Arbiter3_CHIREQ_only2 == 0) covfail = 1;
      $display("Arbiter3_CHIREQ: cover all = %0d", cov_Arbiter3_CHIREQ_all);
      if (cov_Arbiter3_CHIREQ_all == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Arbiter3_TaskBundle__io_in_1_ready) tg++; else $display("COV: Arbiter3_TaskBundle.io_in_1_ready never toggled");
      if (t_Arbiter3_TaskBundle__io_in_2_ready) tg++; else $display("COV: Arbiter3_TaskBundle.io_in_2_ready never toggled");
      if (t_Arbiter3_TaskBundle__io_out_valid) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_valid never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_txChannel) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_txChannel never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_denied) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_denied never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_tgtID) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_tgtID never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_srcID) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_srcID never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_txnID) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_txnID never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_dbID) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_dbID never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_chiOpcode) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_chiOpcode never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_resp) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_resp never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_fwdState) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_fwdState never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_pCrdType) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_pCrdType never toggled");
      if (t_Arbiter3_TaskBundle__io_out_bits_traceTag) tg++; else $display("COV: Arbiter3_TaskBundle.io_out_bits_traceTag never toggled");
      $display("Arbiter3_TaskBundle: toggled=%0d/14 (need >= 14)", tg);
      if (tg < 14) covfail = 1;
      $display("Arbiter3_TaskBundle: cover only2 = %0d", cov_Arbiter3_TaskBundle_only2);
      if (cov_Arbiter3_TaskBundle_only2 == 0) covfail = 1;
      $display("Arbiter3_TaskBundle: cover all = %0d", cov_Arbiter3_TaskBundle_all);
      if (cov_Arbiter3_TaskBundle_all == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Arbiter3_TaskWithData__io_in_0_ready) tg++; else $display("COV: Arbiter3_TaskWithData.io_in_0_ready never toggled");
      if (t_Arbiter3_TaskWithData__io_in_1_ready) tg++; else $display("COV: Arbiter3_TaskWithData.io_in_1_ready never toggled");
      if (t_Arbiter3_TaskWithData__io_in_2_ready) tg++; else $display("COV: Arbiter3_TaskWithData.io_in_2_ready never toggled");
      if (t_Arbiter3_TaskWithData__io_out_valid) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_valid never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_channel) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_channel never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_txChannel) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_txChannel never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_set) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_set never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_tag) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_tag never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_off) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_off never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_alias) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_alias never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_vaddr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_vaddr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_isKeyword) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_isKeyword never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_opcode) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_opcode never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_param) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_param never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_size) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_size never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_sourceId) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_sourceId never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_bufIdx) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_bufIdx never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_needProbeAckData) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_needProbeAckData never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_denied) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_denied never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_corrupt) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_corrupt never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_mshrTask) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_mshrTask never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_mshrId) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_mshrId never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aliasTask) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aliasTask never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_useProbeData) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_useProbeData never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_mshrRetry) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_mshrRetry never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_readProbeDataDown) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_readProbeDataDown never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_fromL2pft) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_fromL2pft never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_needHint) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_needHint never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_dirty) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_dirty never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_way) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_way never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_dirty) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_dirty never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_state) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_state never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_clients) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_clients never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_alias) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_alias never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetch) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_prefetch never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_prefetchSrc) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_prefetchSrc never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_accessed) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_accessed never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_tagErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_tagErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_meta_dataErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_meta_dataErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_metaWen) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_metaWen never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_tagWen) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_tagWen never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_dsWen) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_dsWen never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_wayMask) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_wayMask never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_replTask) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_replTask never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_cmoTask) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_cmoTask never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_cmoAll) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_cmoAll never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_reqSource) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_reqSource never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_mergeA) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_mergeA never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_off) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_off never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_alias) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_alias never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_vaddr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_vaddr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_isKeyword) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_isKeyword never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_opcode) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_opcode never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_param) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_param never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_sourceId) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_sourceId never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dirty) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_dirty never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_state) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_state never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_clients) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_clients never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_alias) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_alias never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetch) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_prefetch never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_prefetchSrc) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_prefetchSrc never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_accessed) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_accessed never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_tagErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_tagErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_aMergeTask_meta_dataErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_aMergeTask_meta_dataErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitRelease) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitRelease never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToInval) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseToInval never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseToClean) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseToClean never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseWithData) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseWithData never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseIdx) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseIdx never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dirty) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_dirty never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_state) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_state never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_clients) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_clients never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_alias) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_alias never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetch) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_prefetch never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_prefetchSrc) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_prefetchSrc never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_accessed) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_accessed never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_tagErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_tagErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_snpHitReleaseMeta_dataErr) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_snpHitReleaseMeta_dataErr never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_tgtID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_tgtID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_srcID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_srcID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_txnID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_txnID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_homeNID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_homeNID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_dbID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_dbID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_fwdNID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_fwdNID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_fwdTxnID) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_fwdTxnID never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_chiOpcode) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_chiOpcode never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_resp) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_resp never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_fwdState) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_fwdState never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_pCrdType) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_pCrdType never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_retToSrc) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_retToSrc never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_likelyshared) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_likelyshared never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_expCompAck) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_expCompAck never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_allowRetry) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_allowRetry never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_allocate) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_memAttr_allocate never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_cacheable) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_memAttr_cacheable never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_device) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_memAttr_device never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_memAttr_ewa) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_memAttr_ewa never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_task_traceTag) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_task_traceTag never toggled");
      if (t_Arbiter3_TaskWithData__io_out_bits_data_data) tg++; else $display("COV: Arbiter3_TaskWithData.io_out_bits_data_data never toggled");
      $display("Arbiter3_TaskWithData: toggled=%0d/99 (need >= 99)", tg);
      if (tg < 99) covfail = 1;
      $display("Arbiter3_TaskWithData: cover only2 = %0d", cov_Arbiter3_TaskWithData_only2);
      if (cov_Arbiter3_TaskWithData_only2 == 0) covfail = 1;
      $display("Arbiter3_TaskWithData: cover all = %0d", cov_Arbiter3_TaskWithData_all);
      if (cov_Arbiter3_TaskWithData_all == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue16_HintQueueEntry__io_enq_ready) tg++; else $display("COV: Queue16_HintQueueEntry.io_enq_ready never toggled");
      if (t_Queue16_HintQueueEntry__io_deq_valid) tg++; else $display("COV: Queue16_HintQueueEntry.io_deq_valid never toggled");
      if (t_Queue16_HintQueueEntry__io_deq_bits_source) tg++; else $display("COV: Queue16_HintQueueEntry.io_deq_bits_source never toggled");
      if (t_Queue16_HintQueueEntry__io_deq_bits_opcode) tg++; else $display("COV: Queue16_HintQueueEntry.io_deq_bits_opcode never toggled");
      if (t_Queue16_HintQueueEntry__io_deq_bits_isKeyword) tg++; else $display("COV: Queue16_HintQueueEntry.io_deq_bits_isKeyword never toggled");
      $display("Queue16_HintQueueEntry: toggled=%0d/5 (need >= 5)", tg);
      if (tg < 5) covfail = 1;
      $display("Queue16_HintQueueEntry: cover full = %0d", cov_Queue16_HintQueueEntry_full);
      if (cov_Queue16_HintQueueEntry_full == 0) covfail = 1;
      $display("Queue16_HintQueueEntry: cover deq = %0d", cov_Queue16_HintQueueEntry_deq);
      if (cov_Queue16_HintQueueEntry_deq == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_Queue4_HintQueueEntry__io_enq_ready) tg++; else $display("COV: Queue4_HintQueueEntry.io_enq_ready never toggled");
      if (t_Queue4_HintQueueEntry__io_deq_valid) tg++; else $display("COV: Queue4_HintQueueEntry.io_deq_valid never toggled");
      if (t_Queue4_HintQueueEntry__io_deq_bits_source) tg++; else $display("COV: Queue4_HintQueueEntry.io_deq_bits_source never toggled");
      if (t_Queue4_HintQueueEntry__io_deq_bits_opcode) tg++; else $display("COV: Queue4_HintQueueEntry.io_deq_bits_opcode never toggled");
      if (t_Queue4_HintQueueEntry__io_deq_bits_isKeyword) tg++; else $display("COV: Queue4_HintQueueEntry.io_deq_bits_isKeyword never toggled");
      $display("Queue4_HintQueueEntry: toggled=%0d/5 (need >= 5)", tg);
      if (tg < 5) covfail = 1;
      $display("Queue4_HintQueueEntry: cover full = %0d", cov_Queue4_HintQueueEntry_full);
      if (cov_Queue4_HintQueueEntry_full == 0) covfail = 1;
      $display("Queue4_HintQueueEntry: cover deq = %0d", cov_Queue4_HintQueueEntry_deq);
      if (cov_Queue4_HintQueueEntry_deq == 0) covfail = 1;
      $display("Queue4_HintQueueEntry: cover bypass = %0d", cov_Queue4_HintQueueEntry_bypass);
      if (cov_Queue4_HintQueueEntry_bypass == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_CustomL1Hint__io_l1Hint_valid) tg++; else $display("COV: CustomL1Hint.io_l1Hint_valid never toggled");
      if (t_CustomL1Hint__io_l1Hint_bits_sourceId) tg++; else $display("COV: CustomL1Hint.io_l1Hint_bits_sourceId never toggled");
      if (t_CustomL1Hint__io_l1Hint_bits_isKeyword) tg++; else $display("COV: CustomL1Hint.io_l1Hint_bits_isKeyword never toggled");
      $display("CustomL1Hint: toggled=%0d/3 (need >= 3)", tg);
      if (tg < 3) covfail = 1;
      $display("CustomL1Hint: cover hint = %0d", cov_CustomL1Hint_hint);
      if (cov_CustomL1Hint_hint == 0) covfail = 1;
      $display("CustomL1Hint: cover s3wins = %0d", cov_CustomL1Hint_s3wins);
      if (cov_CustomL1Hint_s3wins == 0) covfail = 1;
      $display("CustomL1Hint: cover s1full = %0d", cov_CustomL1Hint_s1full);
      if (cov_CustomL1Hint_s1full == 0) covfail = 1;
      $display("CustomL1Hint: cover hqfull = %0d", cov_CustomL1Hint_hqfull);
      if (cov_CustomL1Hint_hqfull == 0) covfail = 1;
      $display("CustomL1Hint: cover mergeGrant = %0d", cov_CustomL1Hint_mergeGrant);
      if (cov_CustomL1Hint_mergeGrant == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
