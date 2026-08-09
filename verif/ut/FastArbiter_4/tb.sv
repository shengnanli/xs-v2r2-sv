// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改
// FastArbiter_4 双例化逐拍比对: golden FastArbiter_4 vs 可读 FastArbiter_4_xs。
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
  logic [10:0] io_in_0_bits_tgtID;
  logic [11:0] io_in_0_bits_txnID;
  logic [6:0] io_in_0_bits_opcode;
  logic [47:0] io_in_0_bits_addr;
  logic io_in_0_bits_likelyshared;
  logic io_in_0_bits_allowRetry;
  logic [3:0] io_in_0_bits_pCrdType;
  logic io_in_0_bits_memAttr_allocate;
  logic io_in_0_bits_memAttr_ewa;
  logic io_in_0_bits_expCompAck;
  logic io_in_1_valid;
  logic [10:0] io_in_1_bits_tgtID;
  logic [11:0] io_in_1_bits_txnID;
  logic [6:0] io_in_1_bits_opcode;
  logic [47:0] io_in_1_bits_addr;
  logic io_in_1_bits_likelyshared;
  logic io_in_1_bits_allowRetry;
  logic [3:0] io_in_1_bits_pCrdType;
  logic io_in_1_bits_memAttr_allocate;
  logic io_in_1_bits_memAttr_ewa;
  logic io_in_1_bits_expCompAck;
  logic io_in_2_valid;
  logic [10:0] io_in_2_bits_tgtID;
  logic [11:0] io_in_2_bits_txnID;
  logic [6:0] io_in_2_bits_opcode;
  logic [47:0] io_in_2_bits_addr;
  logic io_in_2_bits_likelyshared;
  logic io_in_2_bits_allowRetry;
  logic [3:0] io_in_2_bits_pCrdType;
  logic io_in_2_bits_memAttr_allocate;
  logic io_in_2_bits_memAttr_ewa;
  logic io_in_2_bits_expCompAck;
  logic io_in_3_valid;
  logic [10:0] io_in_3_bits_tgtID;
  logic [11:0] io_in_3_bits_txnID;
  logic [6:0] io_in_3_bits_opcode;
  logic [47:0] io_in_3_bits_addr;
  logic io_in_3_bits_likelyshared;
  logic io_in_3_bits_allowRetry;
  logic [3:0] io_in_3_bits_pCrdType;
  logic io_in_3_bits_memAttr_allocate;
  logic io_in_3_bits_memAttr_ewa;
  logic io_in_3_bits_expCompAck;
  logic io_in_4_valid;
  logic [10:0] io_in_4_bits_tgtID;
  logic [11:0] io_in_4_bits_txnID;
  logic [6:0] io_in_4_bits_opcode;
  logic [47:0] io_in_4_bits_addr;
  logic io_in_4_bits_likelyshared;
  logic io_in_4_bits_allowRetry;
  logic [3:0] io_in_4_bits_pCrdType;
  logic io_in_4_bits_memAttr_allocate;
  logic io_in_4_bits_memAttr_ewa;
  logic io_in_4_bits_expCompAck;
  logic io_in_5_valid;
  logic [10:0] io_in_5_bits_tgtID;
  logic [11:0] io_in_5_bits_txnID;
  logic [6:0] io_in_5_bits_opcode;
  logic [47:0] io_in_5_bits_addr;
  logic io_in_5_bits_likelyshared;
  logic io_in_5_bits_allowRetry;
  logic [3:0] io_in_5_bits_pCrdType;
  logic io_in_5_bits_memAttr_allocate;
  logic io_in_5_bits_memAttr_ewa;
  logic io_in_5_bits_expCompAck;
  logic io_in_6_valid;
  logic [10:0] io_in_6_bits_tgtID;
  logic [11:0] io_in_6_bits_txnID;
  logic [6:0] io_in_6_bits_opcode;
  logic [47:0] io_in_6_bits_addr;
  logic io_in_6_bits_likelyshared;
  logic io_in_6_bits_allowRetry;
  logic [3:0] io_in_6_bits_pCrdType;
  logic io_in_6_bits_memAttr_allocate;
  logic io_in_6_bits_memAttr_ewa;
  logic io_in_6_bits_expCompAck;
  logic io_in_7_valid;
  logic [10:0] io_in_7_bits_tgtID;
  logic [11:0] io_in_7_bits_txnID;
  logic [6:0] io_in_7_bits_opcode;
  logic [47:0] io_in_7_bits_addr;
  logic io_in_7_bits_likelyshared;
  logic io_in_7_bits_allowRetry;
  logic [3:0] io_in_7_bits_pCrdType;
  logic io_in_7_bits_memAttr_allocate;
  logic io_in_7_bits_memAttr_ewa;
  logic io_in_7_bits_expCompAck;
  logic io_in_8_valid;
  logic [10:0] io_in_8_bits_tgtID;
  logic [11:0] io_in_8_bits_txnID;
  logic [6:0] io_in_8_bits_opcode;
  logic [47:0] io_in_8_bits_addr;
  logic io_in_8_bits_likelyshared;
  logic io_in_8_bits_allowRetry;
  logic [3:0] io_in_8_bits_pCrdType;
  logic io_in_8_bits_memAttr_allocate;
  logic io_in_8_bits_memAttr_ewa;
  logic io_in_8_bits_expCompAck;
  logic io_in_9_valid;
  logic [10:0] io_in_9_bits_tgtID;
  logic [11:0] io_in_9_bits_txnID;
  logic [6:0] io_in_9_bits_opcode;
  logic [47:0] io_in_9_bits_addr;
  logic io_in_9_bits_likelyshared;
  logic io_in_9_bits_allowRetry;
  logic [3:0] io_in_9_bits_pCrdType;
  logic io_in_9_bits_memAttr_allocate;
  logic io_in_9_bits_memAttr_ewa;
  logic io_in_9_bits_expCompAck;
  logic io_in_10_valid;
  logic [10:0] io_in_10_bits_tgtID;
  logic [11:0] io_in_10_bits_txnID;
  logic [6:0] io_in_10_bits_opcode;
  logic [47:0] io_in_10_bits_addr;
  logic io_in_10_bits_likelyshared;
  logic io_in_10_bits_allowRetry;
  logic [3:0] io_in_10_bits_pCrdType;
  logic io_in_10_bits_memAttr_allocate;
  logic io_in_10_bits_memAttr_ewa;
  logic io_in_10_bits_expCompAck;
  logic io_in_11_valid;
  logic [10:0] io_in_11_bits_tgtID;
  logic [11:0] io_in_11_bits_txnID;
  logic [6:0] io_in_11_bits_opcode;
  logic [47:0] io_in_11_bits_addr;
  logic io_in_11_bits_likelyshared;
  logic io_in_11_bits_allowRetry;
  logic [3:0] io_in_11_bits_pCrdType;
  logic io_in_11_bits_memAttr_allocate;
  logic io_in_11_bits_memAttr_ewa;
  logic io_in_11_bits_expCompAck;
  logic io_in_12_valid;
  logic [10:0] io_in_12_bits_tgtID;
  logic [11:0] io_in_12_bits_txnID;
  logic [6:0] io_in_12_bits_opcode;
  logic [47:0] io_in_12_bits_addr;
  logic io_in_12_bits_likelyshared;
  logic io_in_12_bits_allowRetry;
  logic [3:0] io_in_12_bits_pCrdType;
  logic io_in_12_bits_memAttr_allocate;
  logic io_in_12_bits_memAttr_ewa;
  logic io_in_12_bits_expCompAck;
  logic io_in_13_valid;
  logic [10:0] io_in_13_bits_tgtID;
  logic [11:0] io_in_13_bits_txnID;
  logic [6:0] io_in_13_bits_opcode;
  logic [47:0] io_in_13_bits_addr;
  logic io_in_13_bits_likelyshared;
  logic io_in_13_bits_allowRetry;
  logic [3:0] io_in_13_bits_pCrdType;
  logic io_in_13_bits_memAttr_allocate;
  logic io_in_13_bits_memAttr_ewa;
  logic io_in_13_bits_expCompAck;
  logic io_in_14_valid;
  logic [10:0] io_in_14_bits_tgtID;
  logic [11:0] io_in_14_bits_txnID;
  logic [6:0] io_in_14_bits_opcode;
  logic [47:0] io_in_14_bits_addr;
  logic io_in_14_bits_likelyshared;
  logic io_in_14_bits_allowRetry;
  logic [3:0] io_in_14_bits_pCrdType;
  logic io_in_14_bits_memAttr_allocate;
  logic io_in_14_bits_memAttr_ewa;
  logic io_in_14_bits_expCompAck;
  logic io_in_15_valid;
  logic [10:0] io_in_15_bits_tgtID;
  logic [11:0] io_in_15_bits_txnID;
  logic [6:0] io_in_15_bits_opcode;
  logic [47:0] io_in_15_bits_addr;
  logic io_in_15_bits_likelyshared;
  logic io_in_15_bits_allowRetry;
  logic [3:0] io_in_15_bits_pCrdType;
  logic io_in_15_bits_memAttr_allocate;
  logic io_in_15_bits_memAttr_ewa;
  logic io_in_15_bits_expCompAck;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_in_8_ready;
  wire i_io_in_8_ready;
  wire g_io_in_9_ready;
  wire i_io_in_9_ready;
  wire g_io_in_10_ready;
  wire i_io_in_10_ready;
  wire g_io_in_11_ready;
  wire i_io_in_11_ready;
  wire g_io_in_12_ready;
  wire i_io_in_12_ready;
  wire g_io_in_13_ready;
  wire i_io_in_13_ready;
  wire g_io_in_14_ready;
  wire i_io_in_14_ready;
  wire g_io_in_15_ready;
  wire i_io_in_15_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_qos;
  wire [3:0] i_io_out_bits_qos;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [6:0] g_io_out_bits_opcode;
  wire [6:0] i_io_out_bits_opcode;
  wire [2:0] g_io_out_bits_size;
  wire [2:0] i_io_out_bits_size;
  wire [47:0] g_io_out_bits_addr;
  wire [47:0] i_io_out_bits_addr;
  wire g_io_out_bits_likelyshared;
  wire i_io_out_bits_likelyshared;
  wire g_io_out_bits_allowRetry;
  wire i_io_out_bits_allowRetry;
  wire [3:0] g_io_out_bits_pCrdType;
  wire [3:0] i_io_out_bits_pCrdType;
  wire g_io_out_bits_memAttr_allocate;
  wire i_io_out_bits_memAttr_allocate;
  wire g_io_out_bits_memAttr_cacheable;
  wire i_io_out_bits_memAttr_cacheable;
  wire g_io_out_bits_memAttr_ewa;
  wire i_io_out_bits_memAttr_ewa;
  wire g_io_out_bits_snpAttr;
  wire i_io_out_bits_snpAttr;
  wire g_io_out_bits_expCompAck;
  wire i_io_out_bits_expCompAck;

  FastArbiter_4 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_likelyshared(io_in_1_bits_likelyshared),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_allocate(io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_expCompAck(io_in_1_bits_expCompAck),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_likelyshared(io_in_2_bits_likelyshared),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_pCrdType(io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_allocate(io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_expCompAck(io_in_2_bits_expCompAck),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_likelyshared(io_in_3_bits_likelyshared),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_pCrdType(io_in_3_bits_pCrdType),
    .io_in_3_bits_memAttr_allocate(io_in_3_bits_memAttr_allocate),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_3_bits_expCompAck(io_in_3_bits_expCompAck),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_likelyshared(io_in_4_bits_likelyshared),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_pCrdType(io_in_4_bits_pCrdType),
    .io_in_4_bits_memAttr_allocate(io_in_4_bits_memAttr_allocate),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_4_bits_expCompAck(io_in_4_bits_expCompAck),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_likelyshared(io_in_5_bits_likelyshared),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_pCrdType(io_in_5_bits_pCrdType),
    .io_in_5_bits_memAttr_allocate(io_in_5_bits_memAttr_allocate),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_5_bits_expCompAck(io_in_5_bits_expCompAck),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_likelyshared(io_in_6_bits_likelyshared),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_pCrdType(io_in_6_bits_pCrdType),
    .io_in_6_bits_memAttr_allocate(io_in_6_bits_memAttr_allocate),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_6_bits_expCompAck(io_in_6_bits_expCompAck),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_likelyshared(io_in_7_bits_likelyshared),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_pCrdType(io_in_7_bits_pCrdType),
    .io_in_7_bits_memAttr_allocate(io_in_7_bits_memAttr_allocate),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_in_7_bits_expCompAck(io_in_7_bits_expCompAck),
    .io_in_8_ready(g_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_tgtID(io_in_8_bits_tgtID),
    .io_in_8_bits_txnID(io_in_8_bits_txnID),
    .io_in_8_bits_opcode(io_in_8_bits_opcode),
    .io_in_8_bits_addr(io_in_8_bits_addr),
    .io_in_8_bits_likelyshared(io_in_8_bits_likelyshared),
    .io_in_8_bits_allowRetry(io_in_8_bits_allowRetry),
    .io_in_8_bits_pCrdType(io_in_8_bits_pCrdType),
    .io_in_8_bits_memAttr_allocate(io_in_8_bits_memAttr_allocate),
    .io_in_8_bits_memAttr_ewa(io_in_8_bits_memAttr_ewa),
    .io_in_8_bits_expCompAck(io_in_8_bits_expCompAck),
    .io_in_9_ready(g_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_tgtID(io_in_9_bits_tgtID),
    .io_in_9_bits_txnID(io_in_9_bits_txnID),
    .io_in_9_bits_opcode(io_in_9_bits_opcode),
    .io_in_9_bits_addr(io_in_9_bits_addr),
    .io_in_9_bits_likelyshared(io_in_9_bits_likelyshared),
    .io_in_9_bits_allowRetry(io_in_9_bits_allowRetry),
    .io_in_9_bits_pCrdType(io_in_9_bits_pCrdType),
    .io_in_9_bits_memAttr_allocate(io_in_9_bits_memAttr_allocate),
    .io_in_9_bits_memAttr_ewa(io_in_9_bits_memAttr_ewa),
    .io_in_9_bits_expCompAck(io_in_9_bits_expCompAck),
    .io_in_10_ready(g_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_tgtID(io_in_10_bits_tgtID),
    .io_in_10_bits_txnID(io_in_10_bits_txnID),
    .io_in_10_bits_opcode(io_in_10_bits_opcode),
    .io_in_10_bits_addr(io_in_10_bits_addr),
    .io_in_10_bits_likelyshared(io_in_10_bits_likelyshared),
    .io_in_10_bits_allowRetry(io_in_10_bits_allowRetry),
    .io_in_10_bits_pCrdType(io_in_10_bits_pCrdType),
    .io_in_10_bits_memAttr_allocate(io_in_10_bits_memAttr_allocate),
    .io_in_10_bits_memAttr_ewa(io_in_10_bits_memAttr_ewa),
    .io_in_10_bits_expCompAck(io_in_10_bits_expCompAck),
    .io_in_11_ready(g_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_tgtID(io_in_11_bits_tgtID),
    .io_in_11_bits_txnID(io_in_11_bits_txnID),
    .io_in_11_bits_opcode(io_in_11_bits_opcode),
    .io_in_11_bits_addr(io_in_11_bits_addr),
    .io_in_11_bits_likelyshared(io_in_11_bits_likelyshared),
    .io_in_11_bits_allowRetry(io_in_11_bits_allowRetry),
    .io_in_11_bits_pCrdType(io_in_11_bits_pCrdType),
    .io_in_11_bits_memAttr_allocate(io_in_11_bits_memAttr_allocate),
    .io_in_11_bits_memAttr_ewa(io_in_11_bits_memAttr_ewa),
    .io_in_11_bits_expCompAck(io_in_11_bits_expCompAck),
    .io_in_12_ready(g_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_tgtID(io_in_12_bits_tgtID),
    .io_in_12_bits_txnID(io_in_12_bits_txnID),
    .io_in_12_bits_opcode(io_in_12_bits_opcode),
    .io_in_12_bits_addr(io_in_12_bits_addr),
    .io_in_12_bits_likelyshared(io_in_12_bits_likelyshared),
    .io_in_12_bits_allowRetry(io_in_12_bits_allowRetry),
    .io_in_12_bits_pCrdType(io_in_12_bits_pCrdType),
    .io_in_12_bits_memAttr_allocate(io_in_12_bits_memAttr_allocate),
    .io_in_12_bits_memAttr_ewa(io_in_12_bits_memAttr_ewa),
    .io_in_12_bits_expCompAck(io_in_12_bits_expCompAck),
    .io_in_13_ready(g_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_tgtID(io_in_13_bits_tgtID),
    .io_in_13_bits_txnID(io_in_13_bits_txnID),
    .io_in_13_bits_opcode(io_in_13_bits_opcode),
    .io_in_13_bits_addr(io_in_13_bits_addr),
    .io_in_13_bits_likelyshared(io_in_13_bits_likelyshared),
    .io_in_13_bits_allowRetry(io_in_13_bits_allowRetry),
    .io_in_13_bits_pCrdType(io_in_13_bits_pCrdType),
    .io_in_13_bits_memAttr_allocate(io_in_13_bits_memAttr_allocate),
    .io_in_13_bits_memAttr_ewa(io_in_13_bits_memAttr_ewa),
    .io_in_13_bits_expCompAck(io_in_13_bits_expCompAck),
    .io_in_14_ready(g_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_tgtID(io_in_14_bits_tgtID),
    .io_in_14_bits_txnID(io_in_14_bits_txnID),
    .io_in_14_bits_opcode(io_in_14_bits_opcode),
    .io_in_14_bits_addr(io_in_14_bits_addr),
    .io_in_14_bits_likelyshared(io_in_14_bits_likelyshared),
    .io_in_14_bits_allowRetry(io_in_14_bits_allowRetry),
    .io_in_14_bits_pCrdType(io_in_14_bits_pCrdType),
    .io_in_14_bits_memAttr_allocate(io_in_14_bits_memAttr_allocate),
    .io_in_14_bits_memAttr_ewa(io_in_14_bits_memAttr_ewa),
    .io_in_14_bits_expCompAck(io_in_14_bits_expCompAck),
    .io_in_15_ready(g_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_tgtID(io_in_15_bits_tgtID),
    .io_in_15_bits_txnID(io_in_15_bits_txnID),
    .io_in_15_bits_opcode(io_in_15_bits_opcode),
    .io_in_15_bits_addr(io_in_15_bits_addr),
    .io_in_15_bits_likelyshared(io_in_15_bits_likelyshared),
    .io_in_15_bits_allowRetry(io_in_15_bits_allowRetry),
    .io_in_15_bits_pCrdType(io_in_15_bits_pCrdType),
    .io_in_15_bits_memAttr_allocate(io_in_15_bits_memAttr_allocate),
    .io_in_15_bits_memAttr_ewa(io_in_15_bits_memAttr_ewa),
    .io_in_15_bits_expCompAck(io_in_15_bits_expCompAck),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_size(g_io_out_bits_size),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_likelyshared(g_io_out_bits_likelyshared),
    .io_out_bits_allowRetry(g_io_out_bits_allowRetry),
    .io_out_bits_pCrdType(g_io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate(g_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(g_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa(g_io_out_bits_memAttr_ewa),
    .io_out_bits_snpAttr(g_io_out_bits_snpAttr),
    .io_out_bits_expCompAck(g_io_out_bits_expCompAck)
  );

  FastArbiter_4_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_addr(io_in_0_bits_addr),
    .io_in_0_bits_likelyshared(io_in_0_bits_likelyshared),
    .io_in_0_bits_allowRetry(io_in_0_bits_allowRetry),
    .io_in_0_bits_pCrdType(io_in_0_bits_pCrdType),
    .io_in_0_bits_memAttr_allocate(io_in_0_bits_memAttr_allocate),
    .io_in_0_bits_memAttr_ewa(io_in_0_bits_memAttr_ewa),
    .io_in_0_bits_expCompAck(io_in_0_bits_expCompAck),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_addr(io_in_1_bits_addr),
    .io_in_1_bits_likelyshared(io_in_1_bits_likelyshared),
    .io_in_1_bits_allowRetry(io_in_1_bits_allowRetry),
    .io_in_1_bits_pCrdType(io_in_1_bits_pCrdType),
    .io_in_1_bits_memAttr_allocate(io_in_1_bits_memAttr_allocate),
    .io_in_1_bits_memAttr_ewa(io_in_1_bits_memAttr_ewa),
    .io_in_1_bits_expCompAck(io_in_1_bits_expCompAck),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_addr(io_in_2_bits_addr),
    .io_in_2_bits_likelyshared(io_in_2_bits_likelyshared),
    .io_in_2_bits_allowRetry(io_in_2_bits_allowRetry),
    .io_in_2_bits_pCrdType(io_in_2_bits_pCrdType),
    .io_in_2_bits_memAttr_allocate(io_in_2_bits_memAttr_allocate),
    .io_in_2_bits_memAttr_ewa(io_in_2_bits_memAttr_ewa),
    .io_in_2_bits_expCompAck(io_in_2_bits_expCompAck),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_addr(io_in_3_bits_addr),
    .io_in_3_bits_likelyshared(io_in_3_bits_likelyshared),
    .io_in_3_bits_allowRetry(io_in_3_bits_allowRetry),
    .io_in_3_bits_pCrdType(io_in_3_bits_pCrdType),
    .io_in_3_bits_memAttr_allocate(io_in_3_bits_memAttr_allocate),
    .io_in_3_bits_memAttr_ewa(io_in_3_bits_memAttr_ewa),
    .io_in_3_bits_expCompAck(io_in_3_bits_expCompAck),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_addr(io_in_4_bits_addr),
    .io_in_4_bits_likelyshared(io_in_4_bits_likelyshared),
    .io_in_4_bits_allowRetry(io_in_4_bits_allowRetry),
    .io_in_4_bits_pCrdType(io_in_4_bits_pCrdType),
    .io_in_4_bits_memAttr_allocate(io_in_4_bits_memAttr_allocate),
    .io_in_4_bits_memAttr_ewa(io_in_4_bits_memAttr_ewa),
    .io_in_4_bits_expCompAck(io_in_4_bits_expCompAck),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_addr(io_in_5_bits_addr),
    .io_in_5_bits_likelyshared(io_in_5_bits_likelyshared),
    .io_in_5_bits_allowRetry(io_in_5_bits_allowRetry),
    .io_in_5_bits_pCrdType(io_in_5_bits_pCrdType),
    .io_in_5_bits_memAttr_allocate(io_in_5_bits_memAttr_allocate),
    .io_in_5_bits_memAttr_ewa(io_in_5_bits_memAttr_ewa),
    .io_in_5_bits_expCompAck(io_in_5_bits_expCompAck),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_addr(io_in_6_bits_addr),
    .io_in_6_bits_likelyshared(io_in_6_bits_likelyshared),
    .io_in_6_bits_allowRetry(io_in_6_bits_allowRetry),
    .io_in_6_bits_pCrdType(io_in_6_bits_pCrdType),
    .io_in_6_bits_memAttr_allocate(io_in_6_bits_memAttr_allocate),
    .io_in_6_bits_memAttr_ewa(io_in_6_bits_memAttr_ewa),
    .io_in_6_bits_expCompAck(io_in_6_bits_expCompAck),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_addr(io_in_7_bits_addr),
    .io_in_7_bits_likelyshared(io_in_7_bits_likelyshared),
    .io_in_7_bits_allowRetry(io_in_7_bits_allowRetry),
    .io_in_7_bits_pCrdType(io_in_7_bits_pCrdType),
    .io_in_7_bits_memAttr_allocate(io_in_7_bits_memAttr_allocate),
    .io_in_7_bits_memAttr_ewa(io_in_7_bits_memAttr_ewa),
    .io_in_7_bits_expCompAck(io_in_7_bits_expCompAck),
    .io_in_8_ready(i_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_8_bits_tgtID(io_in_8_bits_tgtID),
    .io_in_8_bits_txnID(io_in_8_bits_txnID),
    .io_in_8_bits_opcode(io_in_8_bits_opcode),
    .io_in_8_bits_addr(io_in_8_bits_addr),
    .io_in_8_bits_likelyshared(io_in_8_bits_likelyshared),
    .io_in_8_bits_allowRetry(io_in_8_bits_allowRetry),
    .io_in_8_bits_pCrdType(io_in_8_bits_pCrdType),
    .io_in_8_bits_memAttr_allocate(io_in_8_bits_memAttr_allocate),
    .io_in_8_bits_memAttr_ewa(io_in_8_bits_memAttr_ewa),
    .io_in_8_bits_expCompAck(io_in_8_bits_expCompAck),
    .io_in_9_ready(i_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_9_bits_tgtID(io_in_9_bits_tgtID),
    .io_in_9_bits_txnID(io_in_9_bits_txnID),
    .io_in_9_bits_opcode(io_in_9_bits_opcode),
    .io_in_9_bits_addr(io_in_9_bits_addr),
    .io_in_9_bits_likelyshared(io_in_9_bits_likelyshared),
    .io_in_9_bits_allowRetry(io_in_9_bits_allowRetry),
    .io_in_9_bits_pCrdType(io_in_9_bits_pCrdType),
    .io_in_9_bits_memAttr_allocate(io_in_9_bits_memAttr_allocate),
    .io_in_9_bits_memAttr_ewa(io_in_9_bits_memAttr_ewa),
    .io_in_9_bits_expCompAck(io_in_9_bits_expCompAck),
    .io_in_10_ready(i_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_10_bits_tgtID(io_in_10_bits_tgtID),
    .io_in_10_bits_txnID(io_in_10_bits_txnID),
    .io_in_10_bits_opcode(io_in_10_bits_opcode),
    .io_in_10_bits_addr(io_in_10_bits_addr),
    .io_in_10_bits_likelyshared(io_in_10_bits_likelyshared),
    .io_in_10_bits_allowRetry(io_in_10_bits_allowRetry),
    .io_in_10_bits_pCrdType(io_in_10_bits_pCrdType),
    .io_in_10_bits_memAttr_allocate(io_in_10_bits_memAttr_allocate),
    .io_in_10_bits_memAttr_ewa(io_in_10_bits_memAttr_ewa),
    .io_in_10_bits_expCompAck(io_in_10_bits_expCompAck),
    .io_in_11_ready(i_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_11_bits_tgtID(io_in_11_bits_tgtID),
    .io_in_11_bits_txnID(io_in_11_bits_txnID),
    .io_in_11_bits_opcode(io_in_11_bits_opcode),
    .io_in_11_bits_addr(io_in_11_bits_addr),
    .io_in_11_bits_likelyshared(io_in_11_bits_likelyshared),
    .io_in_11_bits_allowRetry(io_in_11_bits_allowRetry),
    .io_in_11_bits_pCrdType(io_in_11_bits_pCrdType),
    .io_in_11_bits_memAttr_allocate(io_in_11_bits_memAttr_allocate),
    .io_in_11_bits_memAttr_ewa(io_in_11_bits_memAttr_ewa),
    .io_in_11_bits_expCompAck(io_in_11_bits_expCompAck),
    .io_in_12_ready(i_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_12_bits_tgtID(io_in_12_bits_tgtID),
    .io_in_12_bits_txnID(io_in_12_bits_txnID),
    .io_in_12_bits_opcode(io_in_12_bits_opcode),
    .io_in_12_bits_addr(io_in_12_bits_addr),
    .io_in_12_bits_likelyshared(io_in_12_bits_likelyshared),
    .io_in_12_bits_allowRetry(io_in_12_bits_allowRetry),
    .io_in_12_bits_pCrdType(io_in_12_bits_pCrdType),
    .io_in_12_bits_memAttr_allocate(io_in_12_bits_memAttr_allocate),
    .io_in_12_bits_memAttr_ewa(io_in_12_bits_memAttr_ewa),
    .io_in_12_bits_expCompAck(io_in_12_bits_expCompAck),
    .io_in_13_ready(i_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_13_bits_tgtID(io_in_13_bits_tgtID),
    .io_in_13_bits_txnID(io_in_13_bits_txnID),
    .io_in_13_bits_opcode(io_in_13_bits_opcode),
    .io_in_13_bits_addr(io_in_13_bits_addr),
    .io_in_13_bits_likelyshared(io_in_13_bits_likelyshared),
    .io_in_13_bits_allowRetry(io_in_13_bits_allowRetry),
    .io_in_13_bits_pCrdType(io_in_13_bits_pCrdType),
    .io_in_13_bits_memAttr_allocate(io_in_13_bits_memAttr_allocate),
    .io_in_13_bits_memAttr_ewa(io_in_13_bits_memAttr_ewa),
    .io_in_13_bits_expCompAck(io_in_13_bits_expCompAck),
    .io_in_14_ready(i_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_14_bits_tgtID(io_in_14_bits_tgtID),
    .io_in_14_bits_txnID(io_in_14_bits_txnID),
    .io_in_14_bits_opcode(io_in_14_bits_opcode),
    .io_in_14_bits_addr(io_in_14_bits_addr),
    .io_in_14_bits_likelyshared(io_in_14_bits_likelyshared),
    .io_in_14_bits_allowRetry(io_in_14_bits_allowRetry),
    .io_in_14_bits_pCrdType(io_in_14_bits_pCrdType),
    .io_in_14_bits_memAttr_allocate(io_in_14_bits_memAttr_allocate),
    .io_in_14_bits_memAttr_ewa(io_in_14_bits_memAttr_ewa),
    .io_in_14_bits_expCompAck(io_in_14_bits_expCompAck),
    .io_in_15_ready(i_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_15_bits_tgtID(io_in_15_bits_tgtID),
    .io_in_15_bits_txnID(io_in_15_bits_txnID),
    .io_in_15_bits_opcode(io_in_15_bits_opcode),
    .io_in_15_bits_addr(io_in_15_bits_addr),
    .io_in_15_bits_likelyshared(io_in_15_bits_likelyshared),
    .io_in_15_bits_allowRetry(io_in_15_bits_allowRetry),
    .io_in_15_bits_pCrdType(io_in_15_bits_pCrdType),
    .io_in_15_bits_memAttr_allocate(io_in_15_bits_memAttr_allocate),
    .io_in_15_bits_memAttr_ewa(io_in_15_bits_memAttr_ewa),
    .io_in_15_bits_expCompAck(io_in_15_bits_expCompAck),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_size(i_io_out_bits_size),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_likelyshared(i_io_out_bits_likelyshared),
    .io_out_bits_allowRetry(i_io_out_bits_allowRetry),
    .io_out_bits_pCrdType(i_io_out_bits_pCrdType),
    .io_out_bits_memAttr_allocate(i_io_out_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(i_io_out_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa(i_io_out_bits_memAttr_ewa),
    .io_out_bits_snpAttr(i_io_out_bits_snpAttr),
    .io_out_bits_expCompAck(i_io_out_bits_expCompAck)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_tgtID <= 11'({$urandom});
    io_in_0_bits_txnID <= 12'({$urandom});
    io_in_0_bits_opcode <= 7'({$urandom});
    io_in_0_bits_addr <= 48'({$urandom, $urandom});
    io_in_0_bits_likelyshared <= $urandom_range(0, 1);
    io_in_0_bits_allowRetry <= $urandom_range(0, 1);
    io_in_0_bits_pCrdType <= 4'({$urandom});
    io_in_0_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_0_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_0_bits_expCompAck <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_tgtID <= 11'({$urandom});
    io_in_1_bits_txnID <= 12'({$urandom});
    io_in_1_bits_opcode <= 7'({$urandom});
    io_in_1_bits_addr <= 48'({$urandom, $urandom});
    io_in_1_bits_likelyshared <= $urandom_range(0, 1);
    io_in_1_bits_allowRetry <= $urandom_range(0, 1);
    io_in_1_bits_pCrdType <= 4'({$urandom});
    io_in_1_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_1_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_1_bits_expCompAck <= $urandom_range(0, 1);
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_tgtID <= 11'({$urandom});
    io_in_2_bits_txnID <= 12'({$urandom});
    io_in_2_bits_opcode <= 7'({$urandom});
    io_in_2_bits_addr <= 48'({$urandom, $urandom});
    io_in_2_bits_likelyshared <= $urandom_range(0, 1);
    io_in_2_bits_allowRetry <= $urandom_range(0, 1);
    io_in_2_bits_pCrdType <= 4'({$urandom});
    io_in_2_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_2_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_2_bits_expCompAck <= $urandom_range(0, 1);
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_tgtID <= 11'({$urandom});
    io_in_3_bits_txnID <= 12'({$urandom});
    io_in_3_bits_opcode <= 7'({$urandom});
    io_in_3_bits_addr <= 48'({$urandom, $urandom});
    io_in_3_bits_likelyshared <= $urandom_range(0, 1);
    io_in_3_bits_allowRetry <= $urandom_range(0, 1);
    io_in_3_bits_pCrdType <= 4'({$urandom});
    io_in_3_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_3_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_3_bits_expCompAck <= $urandom_range(0, 1);
    io_in_4_valid <= $urandom_range(0, 1);
    io_in_4_bits_tgtID <= 11'({$urandom});
    io_in_4_bits_txnID <= 12'({$urandom});
    io_in_4_bits_opcode <= 7'({$urandom});
    io_in_4_bits_addr <= 48'({$urandom, $urandom});
    io_in_4_bits_likelyshared <= $urandom_range(0, 1);
    io_in_4_bits_allowRetry <= $urandom_range(0, 1);
    io_in_4_bits_pCrdType <= 4'({$urandom});
    io_in_4_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_4_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_4_bits_expCompAck <= $urandom_range(0, 1);
    io_in_5_valid <= $urandom_range(0, 1);
    io_in_5_bits_tgtID <= 11'({$urandom});
    io_in_5_bits_txnID <= 12'({$urandom});
    io_in_5_bits_opcode <= 7'({$urandom});
    io_in_5_bits_addr <= 48'({$urandom, $urandom});
    io_in_5_bits_likelyshared <= $urandom_range(0, 1);
    io_in_5_bits_allowRetry <= $urandom_range(0, 1);
    io_in_5_bits_pCrdType <= 4'({$urandom});
    io_in_5_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_5_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_5_bits_expCompAck <= $urandom_range(0, 1);
    io_in_6_valid <= $urandom_range(0, 1);
    io_in_6_bits_tgtID <= 11'({$urandom});
    io_in_6_bits_txnID <= 12'({$urandom});
    io_in_6_bits_opcode <= 7'({$urandom});
    io_in_6_bits_addr <= 48'({$urandom, $urandom});
    io_in_6_bits_likelyshared <= $urandom_range(0, 1);
    io_in_6_bits_allowRetry <= $urandom_range(0, 1);
    io_in_6_bits_pCrdType <= 4'({$urandom});
    io_in_6_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_6_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_6_bits_expCompAck <= $urandom_range(0, 1);
    io_in_7_valid <= $urandom_range(0, 1);
    io_in_7_bits_tgtID <= 11'({$urandom});
    io_in_7_bits_txnID <= 12'({$urandom});
    io_in_7_bits_opcode <= 7'({$urandom});
    io_in_7_bits_addr <= 48'({$urandom, $urandom});
    io_in_7_bits_likelyshared <= $urandom_range(0, 1);
    io_in_7_bits_allowRetry <= $urandom_range(0, 1);
    io_in_7_bits_pCrdType <= 4'({$urandom});
    io_in_7_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_7_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_7_bits_expCompAck <= $urandom_range(0, 1);
    io_in_8_valid <= $urandom_range(0, 1);
    io_in_8_bits_tgtID <= 11'({$urandom});
    io_in_8_bits_txnID <= 12'({$urandom});
    io_in_8_bits_opcode <= 7'({$urandom});
    io_in_8_bits_addr <= 48'({$urandom, $urandom});
    io_in_8_bits_likelyshared <= $urandom_range(0, 1);
    io_in_8_bits_allowRetry <= $urandom_range(0, 1);
    io_in_8_bits_pCrdType <= 4'({$urandom});
    io_in_8_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_8_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_8_bits_expCompAck <= $urandom_range(0, 1);
    io_in_9_valid <= $urandom_range(0, 1);
    io_in_9_bits_tgtID <= 11'({$urandom});
    io_in_9_bits_txnID <= 12'({$urandom});
    io_in_9_bits_opcode <= 7'({$urandom});
    io_in_9_bits_addr <= 48'({$urandom, $urandom});
    io_in_9_bits_likelyshared <= $urandom_range(0, 1);
    io_in_9_bits_allowRetry <= $urandom_range(0, 1);
    io_in_9_bits_pCrdType <= 4'({$urandom});
    io_in_9_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_9_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_9_bits_expCompAck <= $urandom_range(0, 1);
    io_in_10_valid <= $urandom_range(0, 1);
    io_in_10_bits_tgtID <= 11'({$urandom});
    io_in_10_bits_txnID <= 12'({$urandom});
    io_in_10_bits_opcode <= 7'({$urandom});
    io_in_10_bits_addr <= 48'({$urandom, $urandom});
    io_in_10_bits_likelyshared <= $urandom_range(0, 1);
    io_in_10_bits_allowRetry <= $urandom_range(0, 1);
    io_in_10_bits_pCrdType <= 4'({$urandom});
    io_in_10_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_10_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_10_bits_expCompAck <= $urandom_range(0, 1);
    io_in_11_valid <= $urandom_range(0, 1);
    io_in_11_bits_tgtID <= 11'({$urandom});
    io_in_11_bits_txnID <= 12'({$urandom});
    io_in_11_bits_opcode <= 7'({$urandom});
    io_in_11_bits_addr <= 48'({$urandom, $urandom});
    io_in_11_bits_likelyshared <= $urandom_range(0, 1);
    io_in_11_bits_allowRetry <= $urandom_range(0, 1);
    io_in_11_bits_pCrdType <= 4'({$urandom});
    io_in_11_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_11_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_11_bits_expCompAck <= $urandom_range(0, 1);
    io_in_12_valid <= $urandom_range(0, 1);
    io_in_12_bits_tgtID <= 11'({$urandom});
    io_in_12_bits_txnID <= 12'({$urandom});
    io_in_12_bits_opcode <= 7'({$urandom});
    io_in_12_bits_addr <= 48'({$urandom, $urandom});
    io_in_12_bits_likelyshared <= $urandom_range(0, 1);
    io_in_12_bits_allowRetry <= $urandom_range(0, 1);
    io_in_12_bits_pCrdType <= 4'({$urandom});
    io_in_12_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_12_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_12_bits_expCompAck <= $urandom_range(0, 1);
    io_in_13_valid <= $urandom_range(0, 1);
    io_in_13_bits_tgtID <= 11'({$urandom});
    io_in_13_bits_txnID <= 12'({$urandom});
    io_in_13_bits_opcode <= 7'({$urandom});
    io_in_13_bits_addr <= 48'({$urandom, $urandom});
    io_in_13_bits_likelyshared <= $urandom_range(0, 1);
    io_in_13_bits_allowRetry <= $urandom_range(0, 1);
    io_in_13_bits_pCrdType <= 4'({$urandom});
    io_in_13_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_13_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_13_bits_expCompAck <= $urandom_range(0, 1);
    io_in_14_valid <= $urandom_range(0, 1);
    io_in_14_bits_tgtID <= 11'({$urandom});
    io_in_14_bits_txnID <= 12'({$urandom});
    io_in_14_bits_opcode <= 7'({$urandom});
    io_in_14_bits_addr <= 48'({$urandom, $urandom});
    io_in_14_bits_likelyshared <= $urandom_range(0, 1);
    io_in_14_bits_allowRetry <= $urandom_range(0, 1);
    io_in_14_bits_pCrdType <= 4'({$urandom});
    io_in_14_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_14_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_14_bits_expCompAck <= $urandom_range(0, 1);
    io_in_15_valid <= $urandom_range(0, 1);
    io_in_15_bits_tgtID <= 11'({$urandom});
    io_in_15_bits_txnID <= 12'({$urandom});
    io_in_15_bits_opcode <= 7'({$urandom});
    io_in_15_bits_addr <= 48'({$urandom, $urandom});
    io_in_15_bits_likelyshared <= $urandom_range(0, 1);
    io_in_15_bits_allowRetry <= $urandom_range(0, 1);
    io_in_15_bits_pCrdType <= 4'({$urandom});
    io_in_15_bits_memAttr_allocate <= $urandom_range(0, 1);
    io_in_15_bits_memAttr_ewa <= $urandom_range(0, 1);
    io_in_15_bits_expCompAck <= $urandom_range(0, 1);
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_in_8_ready)
    `CHECK(io_in_9_ready)
    `CHECK(io_in_10_ready)
    `CHECK(io_in_11_ready)
    `CHECK(io_in_12_ready)
    `CHECK(io_in_13_ready)
    `CHECK(io_in_14_ready)
    `CHECK(io_in_15_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_qos)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_size)
    `CHECK(io_out_bits_addr)
    `CHECK(io_out_bits_likelyshared)
    `CHECK(io_out_bits_allowRetry)
    `CHECK(io_out_bits_pCrdType)
    `CHECK(io_out_bits_memAttr_allocate)
    `CHECK(io_out_bits_memAttr_cacheable)
    `CHECK(io_out_bits_memAttr_ewa)
    `CHECK(io_out_bits_snpAttr)
    `CHECK(io_out_bits_expCompAck)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_addr = '0;
    io_in_0_bits_likelyshared = '0;
    io_in_0_bits_allowRetry = '0;
    io_in_0_bits_pCrdType = '0;
    io_in_0_bits_memAttr_allocate = '0;
    io_in_0_bits_memAttr_ewa = '0;
    io_in_0_bits_expCompAck = '0;
    io_in_1_valid = '0;
    io_in_1_bits_tgtID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_addr = '0;
    io_in_1_bits_likelyshared = '0;
    io_in_1_bits_allowRetry = '0;
    io_in_1_bits_pCrdType = '0;
    io_in_1_bits_memAttr_allocate = '0;
    io_in_1_bits_memAttr_ewa = '0;
    io_in_1_bits_expCompAck = '0;
    io_in_2_valid = '0;
    io_in_2_bits_tgtID = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_addr = '0;
    io_in_2_bits_likelyshared = '0;
    io_in_2_bits_allowRetry = '0;
    io_in_2_bits_pCrdType = '0;
    io_in_2_bits_memAttr_allocate = '0;
    io_in_2_bits_memAttr_ewa = '0;
    io_in_2_bits_expCompAck = '0;
    io_in_3_valid = '0;
    io_in_3_bits_tgtID = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_addr = '0;
    io_in_3_bits_likelyshared = '0;
    io_in_3_bits_allowRetry = '0;
    io_in_3_bits_pCrdType = '0;
    io_in_3_bits_memAttr_allocate = '0;
    io_in_3_bits_memAttr_ewa = '0;
    io_in_3_bits_expCompAck = '0;
    io_in_4_valid = '0;
    io_in_4_bits_tgtID = '0;
    io_in_4_bits_txnID = '0;
    io_in_4_bits_opcode = '0;
    io_in_4_bits_addr = '0;
    io_in_4_bits_likelyshared = '0;
    io_in_4_bits_allowRetry = '0;
    io_in_4_bits_pCrdType = '0;
    io_in_4_bits_memAttr_allocate = '0;
    io_in_4_bits_memAttr_ewa = '0;
    io_in_4_bits_expCompAck = '0;
    io_in_5_valid = '0;
    io_in_5_bits_tgtID = '0;
    io_in_5_bits_txnID = '0;
    io_in_5_bits_opcode = '0;
    io_in_5_bits_addr = '0;
    io_in_5_bits_likelyshared = '0;
    io_in_5_bits_allowRetry = '0;
    io_in_5_bits_pCrdType = '0;
    io_in_5_bits_memAttr_allocate = '0;
    io_in_5_bits_memAttr_ewa = '0;
    io_in_5_bits_expCompAck = '0;
    io_in_6_valid = '0;
    io_in_6_bits_tgtID = '0;
    io_in_6_bits_txnID = '0;
    io_in_6_bits_opcode = '0;
    io_in_6_bits_addr = '0;
    io_in_6_bits_likelyshared = '0;
    io_in_6_bits_allowRetry = '0;
    io_in_6_bits_pCrdType = '0;
    io_in_6_bits_memAttr_allocate = '0;
    io_in_6_bits_memAttr_ewa = '0;
    io_in_6_bits_expCompAck = '0;
    io_in_7_valid = '0;
    io_in_7_bits_tgtID = '0;
    io_in_7_bits_txnID = '0;
    io_in_7_bits_opcode = '0;
    io_in_7_bits_addr = '0;
    io_in_7_bits_likelyshared = '0;
    io_in_7_bits_allowRetry = '0;
    io_in_7_bits_pCrdType = '0;
    io_in_7_bits_memAttr_allocate = '0;
    io_in_7_bits_memAttr_ewa = '0;
    io_in_7_bits_expCompAck = '0;
    io_in_8_valid = '0;
    io_in_8_bits_tgtID = '0;
    io_in_8_bits_txnID = '0;
    io_in_8_bits_opcode = '0;
    io_in_8_bits_addr = '0;
    io_in_8_bits_likelyshared = '0;
    io_in_8_bits_allowRetry = '0;
    io_in_8_bits_pCrdType = '0;
    io_in_8_bits_memAttr_allocate = '0;
    io_in_8_bits_memAttr_ewa = '0;
    io_in_8_bits_expCompAck = '0;
    io_in_9_valid = '0;
    io_in_9_bits_tgtID = '0;
    io_in_9_bits_txnID = '0;
    io_in_9_bits_opcode = '0;
    io_in_9_bits_addr = '0;
    io_in_9_bits_likelyshared = '0;
    io_in_9_bits_allowRetry = '0;
    io_in_9_bits_pCrdType = '0;
    io_in_9_bits_memAttr_allocate = '0;
    io_in_9_bits_memAttr_ewa = '0;
    io_in_9_bits_expCompAck = '0;
    io_in_10_valid = '0;
    io_in_10_bits_tgtID = '0;
    io_in_10_bits_txnID = '0;
    io_in_10_bits_opcode = '0;
    io_in_10_bits_addr = '0;
    io_in_10_bits_likelyshared = '0;
    io_in_10_bits_allowRetry = '0;
    io_in_10_bits_pCrdType = '0;
    io_in_10_bits_memAttr_allocate = '0;
    io_in_10_bits_memAttr_ewa = '0;
    io_in_10_bits_expCompAck = '0;
    io_in_11_valid = '0;
    io_in_11_bits_tgtID = '0;
    io_in_11_bits_txnID = '0;
    io_in_11_bits_opcode = '0;
    io_in_11_bits_addr = '0;
    io_in_11_bits_likelyshared = '0;
    io_in_11_bits_allowRetry = '0;
    io_in_11_bits_pCrdType = '0;
    io_in_11_bits_memAttr_allocate = '0;
    io_in_11_bits_memAttr_ewa = '0;
    io_in_11_bits_expCompAck = '0;
    io_in_12_valid = '0;
    io_in_12_bits_tgtID = '0;
    io_in_12_bits_txnID = '0;
    io_in_12_bits_opcode = '0;
    io_in_12_bits_addr = '0;
    io_in_12_bits_likelyshared = '0;
    io_in_12_bits_allowRetry = '0;
    io_in_12_bits_pCrdType = '0;
    io_in_12_bits_memAttr_allocate = '0;
    io_in_12_bits_memAttr_ewa = '0;
    io_in_12_bits_expCompAck = '0;
    io_in_13_valid = '0;
    io_in_13_bits_tgtID = '0;
    io_in_13_bits_txnID = '0;
    io_in_13_bits_opcode = '0;
    io_in_13_bits_addr = '0;
    io_in_13_bits_likelyshared = '0;
    io_in_13_bits_allowRetry = '0;
    io_in_13_bits_pCrdType = '0;
    io_in_13_bits_memAttr_allocate = '0;
    io_in_13_bits_memAttr_ewa = '0;
    io_in_13_bits_expCompAck = '0;
    io_in_14_valid = '0;
    io_in_14_bits_tgtID = '0;
    io_in_14_bits_txnID = '0;
    io_in_14_bits_opcode = '0;
    io_in_14_bits_addr = '0;
    io_in_14_bits_likelyshared = '0;
    io_in_14_bits_allowRetry = '0;
    io_in_14_bits_pCrdType = '0;
    io_in_14_bits_memAttr_allocate = '0;
    io_in_14_bits_memAttr_ewa = '0;
    io_in_14_bits_expCompAck = '0;
    io_in_15_valid = '0;
    io_in_15_bits_tgtID = '0;
    io_in_15_bits_txnID = '0;
    io_in_15_bits_opcode = '0;
    io_in_15_bits_addr = '0;
    io_in_15_bits_likelyshared = '0;
    io_in_15_bits_allowRetry = '0;
    io_in_15_bits_pCrdType = '0;
    io_in_15_bits_memAttr_allocate = '0;
    io_in_15_bits_memAttr_ewa = '0;
    io_in_15_bits_expCompAck = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_4 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
