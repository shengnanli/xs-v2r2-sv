// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [11:0] io_in_bits_set;
  logic [1:0] io_in_bits_bank;
  logic [27:0] io_in_bits_tag;
  logic io_in_bits_replSnp;
  logic io_in_bits_snpVec_0;
  logic [11:0] io_in_bits_txnID;
  logic [6:0] io_in_bits_chiOpcode;
  logic io_in_bits_retToSrc;
  logic io_out_ready;
  logic io_ack_valid;
  logic [11:0] io_ack_bits_txnID;
  logic [6:0] io_ack_bits_opcode;
  logic io_respInfo_0_valid;
  logic [11:0] io_respInfo_0_bits_set;
  logic [27:0] io_respInfo_0_bits_tag;
  logic [6:0] io_respInfo_0_bits_opcode;
  logic [11:0] io_respInfo_0_bits_reqID;
  logic io_respInfo_0_bits_w_compack;
  logic io_respInfo_1_valid;
  logic [11:0] io_respInfo_1_bits_set;
  logic [27:0] io_respInfo_1_bits_tag;
  logic [6:0] io_respInfo_1_bits_opcode;
  logic [11:0] io_respInfo_1_bits_reqID;
  logic io_respInfo_1_bits_w_compack;
  logic io_respInfo_2_valid;
  logic [11:0] io_respInfo_2_bits_set;
  logic [27:0] io_respInfo_2_bits_tag;
  logic [6:0] io_respInfo_2_bits_opcode;
  logic [11:0] io_respInfo_2_bits_reqID;
  logic io_respInfo_2_bits_w_compack;
  logic io_respInfo_3_valid;
  logic [11:0] io_respInfo_3_bits_set;
  logic [27:0] io_respInfo_3_bits_tag;
  logic [6:0] io_respInfo_3_bits_opcode;
  logic [11:0] io_respInfo_3_bits_reqID;
  logic io_respInfo_3_bits_w_compack;
  logic io_respInfo_4_valid;
  logic [11:0] io_respInfo_4_bits_set;
  logic [27:0] io_respInfo_4_bits_tag;
  logic [6:0] io_respInfo_4_bits_opcode;
  logic [11:0] io_respInfo_4_bits_reqID;
  logic io_respInfo_4_bits_w_compack;
  logic io_respInfo_5_valid;
  logic [11:0] io_respInfo_5_bits_set;
  logic [27:0] io_respInfo_5_bits_tag;
  logic [6:0] io_respInfo_5_bits_opcode;
  logic [11:0] io_respInfo_5_bits_reqID;
  logic io_respInfo_5_bits_w_compack;
  logic io_respInfo_6_valid;
  logic [11:0] io_respInfo_6_bits_set;
  logic [27:0] io_respInfo_6_bits_tag;
  logic [6:0] io_respInfo_6_bits_opcode;
  logic [11:0] io_respInfo_6_bits_reqID;
  logic io_respInfo_6_bits_w_compack;
  logic io_respInfo_7_valid;
  logic [11:0] io_respInfo_7_bits_set;
  logic [27:0] io_respInfo_7_bits_tag;
  logic [6:0] io_respInfo_7_bits_opcode;
  logic [11:0] io_respInfo_7_bits_reqID;
  logic io_respInfo_7_bits_w_compack;
  logic io_respInfo_8_valid;
  logic [11:0] io_respInfo_8_bits_set;
  logic [27:0] io_respInfo_8_bits_tag;
  logic [6:0] io_respInfo_8_bits_opcode;
  logic [11:0] io_respInfo_8_bits_reqID;
  logic io_respInfo_8_bits_w_compack;
  logic io_respInfo_9_valid;
  logic [11:0] io_respInfo_9_bits_set;
  logic [27:0] io_respInfo_9_bits_tag;
  logic [6:0] io_respInfo_9_bits_opcode;
  logic [11:0] io_respInfo_9_bits_reqID;
  logic io_respInfo_9_bits_w_compack;
  logic io_respInfo_10_valid;
  logic [11:0] io_respInfo_10_bits_set;
  logic [27:0] io_respInfo_10_bits_tag;
  logic [6:0] io_respInfo_10_bits_opcode;
  logic [11:0] io_respInfo_10_bits_reqID;
  logic io_respInfo_10_bits_w_compack;
  logic io_respInfo_11_valid;
  logic [11:0] io_respInfo_11_bits_set;
  logic [27:0] io_respInfo_11_bits_tag;
  logic [6:0] io_respInfo_11_bits_opcode;
  logic [11:0] io_respInfo_11_bits_reqID;
  logic io_respInfo_11_bits_w_compack;
  logic io_respInfo_12_valid;
  logic [11:0] io_respInfo_12_bits_set;
  logic [27:0] io_respInfo_12_bits_tag;
  logic [6:0] io_respInfo_12_bits_opcode;
  logic [11:0] io_respInfo_12_bits_reqID;
  logic io_respInfo_12_bits_w_compack;
  logic io_respInfo_13_valid;
  logic [11:0] io_respInfo_13_bits_set;
  logic [27:0] io_respInfo_13_bits_tag;
  logic [6:0] io_respInfo_13_bits_opcode;
  logic [11:0] io_respInfo_13_bits_reqID;
  logic io_respInfo_13_bits_w_compack;
  logic io_respInfo_14_valid;
  logic [11:0] io_respInfo_14_bits_set;
  logic [27:0] io_respInfo_14_bits_tag;
  logic [6:0] io_respInfo_14_bits_opcode;
  logic [11:0] io_respInfo_14_bits_reqID;
  logic io_respInfo_14_bits_w_compack;
  logic io_respInfo_15_valid;
  logic [11:0] io_respInfo_15_bits_set;
  logic [27:0] io_respInfo_15_bits_tag;
  logic [6:0] io_respInfo_15_bits_opcode;
  logic [11:0] io_respInfo_15_bits_reqID;
  logic io_respInfo_15_bits_w_compack;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [11:0] g_io_out_bits_set;
  wire [11:0] i_io_out_bits_set;
  wire [1:0] g_io_out_bits_bank;
  wire [1:0] i_io_out_bits_bank;
  wire [27:0] g_io_out_bits_tag;
  wire [27:0] i_io_out_bits_tag;
  wire g_io_out_bits_snpVec_0;
  wire i_io_out_bits_snpVec_0;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [10:0] g_io_out_bits_fwdNID;
  wire [10:0] i_io_out_bits_fwdNID;
  wire [11:0] g_io_out_bits_fwdTxnID;
  wire [11:0] i_io_out_bits_fwdTxnID;
  wire [6:0] g_io_out_bits_chiOpcode;
  wire [6:0] i_io_out_bits_chiOpcode;
  wire g_io_out_bits_retToSrc;
  wire i_io_out_bits_retToSrc;
  wire g_io_out_bits_doNotGoToSD;
  wire i_io_out_bits_doNotGoToSD;

  SnoopUnit dut_g (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_bank(io_in_bits_bank),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_replSnp(io_in_bits_replSnp),
    .io_in_bits_snpVec_0(io_in_bits_snpVec_0),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_chiOpcode(io_in_bits_chiOpcode),
    .io_in_bits_retToSrc(io_in_bits_retToSrc),
    .io_out_ready(io_out_ready),
    .io_ack_valid(io_ack_valid),
    .io_ack_bits_txnID(io_ack_bits_txnID),
    .io_ack_bits_opcode(io_ack_bits_opcode),
    .io_respInfo_0_valid(io_respInfo_0_valid),
    .io_respInfo_0_bits_set(io_respInfo_0_bits_set),
    .io_respInfo_0_bits_tag(io_respInfo_0_bits_tag),
    .io_respInfo_0_bits_opcode(io_respInfo_0_bits_opcode),
    .io_respInfo_0_bits_reqID(io_respInfo_0_bits_reqID),
    .io_respInfo_0_bits_w_compack(io_respInfo_0_bits_w_compack),
    .io_respInfo_1_valid(io_respInfo_1_valid),
    .io_respInfo_1_bits_set(io_respInfo_1_bits_set),
    .io_respInfo_1_bits_tag(io_respInfo_1_bits_tag),
    .io_respInfo_1_bits_opcode(io_respInfo_1_bits_opcode),
    .io_respInfo_1_bits_reqID(io_respInfo_1_bits_reqID),
    .io_respInfo_1_bits_w_compack(io_respInfo_1_bits_w_compack),
    .io_respInfo_2_valid(io_respInfo_2_valid),
    .io_respInfo_2_bits_set(io_respInfo_2_bits_set),
    .io_respInfo_2_bits_tag(io_respInfo_2_bits_tag),
    .io_respInfo_2_bits_opcode(io_respInfo_2_bits_opcode),
    .io_respInfo_2_bits_reqID(io_respInfo_2_bits_reqID),
    .io_respInfo_2_bits_w_compack(io_respInfo_2_bits_w_compack),
    .io_respInfo_3_valid(io_respInfo_3_valid),
    .io_respInfo_3_bits_set(io_respInfo_3_bits_set),
    .io_respInfo_3_bits_tag(io_respInfo_3_bits_tag),
    .io_respInfo_3_bits_opcode(io_respInfo_3_bits_opcode),
    .io_respInfo_3_bits_reqID(io_respInfo_3_bits_reqID),
    .io_respInfo_3_bits_w_compack(io_respInfo_3_bits_w_compack),
    .io_respInfo_4_valid(io_respInfo_4_valid),
    .io_respInfo_4_bits_set(io_respInfo_4_bits_set),
    .io_respInfo_4_bits_tag(io_respInfo_4_bits_tag),
    .io_respInfo_4_bits_opcode(io_respInfo_4_bits_opcode),
    .io_respInfo_4_bits_reqID(io_respInfo_4_bits_reqID),
    .io_respInfo_4_bits_w_compack(io_respInfo_4_bits_w_compack),
    .io_respInfo_5_valid(io_respInfo_5_valid),
    .io_respInfo_5_bits_set(io_respInfo_5_bits_set),
    .io_respInfo_5_bits_tag(io_respInfo_5_bits_tag),
    .io_respInfo_5_bits_opcode(io_respInfo_5_bits_opcode),
    .io_respInfo_5_bits_reqID(io_respInfo_5_bits_reqID),
    .io_respInfo_5_bits_w_compack(io_respInfo_5_bits_w_compack),
    .io_respInfo_6_valid(io_respInfo_6_valid),
    .io_respInfo_6_bits_set(io_respInfo_6_bits_set),
    .io_respInfo_6_bits_tag(io_respInfo_6_bits_tag),
    .io_respInfo_6_bits_opcode(io_respInfo_6_bits_opcode),
    .io_respInfo_6_bits_reqID(io_respInfo_6_bits_reqID),
    .io_respInfo_6_bits_w_compack(io_respInfo_6_bits_w_compack),
    .io_respInfo_7_valid(io_respInfo_7_valid),
    .io_respInfo_7_bits_set(io_respInfo_7_bits_set),
    .io_respInfo_7_bits_tag(io_respInfo_7_bits_tag),
    .io_respInfo_7_bits_opcode(io_respInfo_7_bits_opcode),
    .io_respInfo_7_bits_reqID(io_respInfo_7_bits_reqID),
    .io_respInfo_7_bits_w_compack(io_respInfo_7_bits_w_compack),
    .io_respInfo_8_valid(io_respInfo_8_valid),
    .io_respInfo_8_bits_set(io_respInfo_8_bits_set),
    .io_respInfo_8_bits_tag(io_respInfo_8_bits_tag),
    .io_respInfo_8_bits_opcode(io_respInfo_8_bits_opcode),
    .io_respInfo_8_bits_reqID(io_respInfo_8_bits_reqID),
    .io_respInfo_8_bits_w_compack(io_respInfo_8_bits_w_compack),
    .io_respInfo_9_valid(io_respInfo_9_valid),
    .io_respInfo_9_bits_set(io_respInfo_9_bits_set),
    .io_respInfo_9_bits_tag(io_respInfo_9_bits_tag),
    .io_respInfo_9_bits_opcode(io_respInfo_9_bits_opcode),
    .io_respInfo_9_bits_reqID(io_respInfo_9_bits_reqID),
    .io_respInfo_9_bits_w_compack(io_respInfo_9_bits_w_compack),
    .io_respInfo_10_valid(io_respInfo_10_valid),
    .io_respInfo_10_bits_set(io_respInfo_10_bits_set),
    .io_respInfo_10_bits_tag(io_respInfo_10_bits_tag),
    .io_respInfo_10_bits_opcode(io_respInfo_10_bits_opcode),
    .io_respInfo_10_bits_reqID(io_respInfo_10_bits_reqID),
    .io_respInfo_10_bits_w_compack(io_respInfo_10_bits_w_compack),
    .io_respInfo_11_valid(io_respInfo_11_valid),
    .io_respInfo_11_bits_set(io_respInfo_11_bits_set),
    .io_respInfo_11_bits_tag(io_respInfo_11_bits_tag),
    .io_respInfo_11_bits_opcode(io_respInfo_11_bits_opcode),
    .io_respInfo_11_bits_reqID(io_respInfo_11_bits_reqID),
    .io_respInfo_11_bits_w_compack(io_respInfo_11_bits_w_compack),
    .io_respInfo_12_valid(io_respInfo_12_valid),
    .io_respInfo_12_bits_set(io_respInfo_12_bits_set),
    .io_respInfo_12_bits_tag(io_respInfo_12_bits_tag),
    .io_respInfo_12_bits_opcode(io_respInfo_12_bits_opcode),
    .io_respInfo_12_bits_reqID(io_respInfo_12_bits_reqID),
    .io_respInfo_12_bits_w_compack(io_respInfo_12_bits_w_compack),
    .io_respInfo_13_valid(io_respInfo_13_valid),
    .io_respInfo_13_bits_set(io_respInfo_13_bits_set),
    .io_respInfo_13_bits_tag(io_respInfo_13_bits_tag),
    .io_respInfo_13_bits_opcode(io_respInfo_13_bits_opcode),
    .io_respInfo_13_bits_reqID(io_respInfo_13_bits_reqID),
    .io_respInfo_13_bits_w_compack(io_respInfo_13_bits_w_compack),
    .io_respInfo_14_valid(io_respInfo_14_valid),
    .io_respInfo_14_bits_set(io_respInfo_14_bits_set),
    .io_respInfo_14_bits_tag(io_respInfo_14_bits_tag),
    .io_respInfo_14_bits_opcode(io_respInfo_14_bits_opcode),
    .io_respInfo_14_bits_reqID(io_respInfo_14_bits_reqID),
    .io_respInfo_14_bits_w_compack(io_respInfo_14_bits_w_compack),
    .io_respInfo_15_valid(io_respInfo_15_valid),
    .io_respInfo_15_bits_set(io_respInfo_15_bits_set),
    .io_respInfo_15_bits_tag(io_respInfo_15_bits_tag),
    .io_respInfo_15_bits_opcode(io_respInfo_15_bits_opcode),
    .io_respInfo_15_bits_reqID(io_respInfo_15_bits_reqID),
    .io_respInfo_15_bits_w_compack(io_respInfo_15_bits_w_compack),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_set(g_io_out_bits_set),
    .io_out_bits_bank(g_io_out_bits_bank),
    .io_out_bits_tag(g_io_out_bits_tag),
    .io_out_bits_snpVec_0(g_io_out_bits_snpVec_0),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_fwdNID(g_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(g_io_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode(g_io_out_bits_chiOpcode),
    .io_out_bits_retToSrc(g_io_out_bits_retToSrc),
    .io_out_bits_doNotGoToSD(g_io_out_bits_doNotGoToSD)
  );

  SnoopUnit_xs dut_i (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_bank(io_in_bits_bank),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_replSnp(io_in_bits_replSnp),
    .io_in_bits_snpVec_0(io_in_bits_snpVec_0),
    .io_in_bits_txnID(io_in_bits_txnID),
    .io_in_bits_chiOpcode(io_in_bits_chiOpcode),
    .io_in_bits_retToSrc(io_in_bits_retToSrc),
    .io_out_ready(io_out_ready),
    .io_ack_valid(io_ack_valid),
    .io_ack_bits_txnID(io_ack_bits_txnID),
    .io_ack_bits_opcode(io_ack_bits_opcode),
    .io_respInfo_0_valid(io_respInfo_0_valid),
    .io_respInfo_0_bits_set(io_respInfo_0_bits_set),
    .io_respInfo_0_bits_tag(io_respInfo_0_bits_tag),
    .io_respInfo_0_bits_opcode(io_respInfo_0_bits_opcode),
    .io_respInfo_0_bits_reqID(io_respInfo_0_bits_reqID),
    .io_respInfo_0_bits_w_compack(io_respInfo_0_bits_w_compack),
    .io_respInfo_1_valid(io_respInfo_1_valid),
    .io_respInfo_1_bits_set(io_respInfo_1_bits_set),
    .io_respInfo_1_bits_tag(io_respInfo_1_bits_tag),
    .io_respInfo_1_bits_opcode(io_respInfo_1_bits_opcode),
    .io_respInfo_1_bits_reqID(io_respInfo_1_bits_reqID),
    .io_respInfo_1_bits_w_compack(io_respInfo_1_bits_w_compack),
    .io_respInfo_2_valid(io_respInfo_2_valid),
    .io_respInfo_2_bits_set(io_respInfo_2_bits_set),
    .io_respInfo_2_bits_tag(io_respInfo_2_bits_tag),
    .io_respInfo_2_bits_opcode(io_respInfo_2_bits_opcode),
    .io_respInfo_2_bits_reqID(io_respInfo_2_bits_reqID),
    .io_respInfo_2_bits_w_compack(io_respInfo_2_bits_w_compack),
    .io_respInfo_3_valid(io_respInfo_3_valid),
    .io_respInfo_3_bits_set(io_respInfo_3_bits_set),
    .io_respInfo_3_bits_tag(io_respInfo_3_bits_tag),
    .io_respInfo_3_bits_opcode(io_respInfo_3_bits_opcode),
    .io_respInfo_3_bits_reqID(io_respInfo_3_bits_reqID),
    .io_respInfo_3_bits_w_compack(io_respInfo_3_bits_w_compack),
    .io_respInfo_4_valid(io_respInfo_4_valid),
    .io_respInfo_4_bits_set(io_respInfo_4_bits_set),
    .io_respInfo_4_bits_tag(io_respInfo_4_bits_tag),
    .io_respInfo_4_bits_opcode(io_respInfo_4_bits_opcode),
    .io_respInfo_4_bits_reqID(io_respInfo_4_bits_reqID),
    .io_respInfo_4_bits_w_compack(io_respInfo_4_bits_w_compack),
    .io_respInfo_5_valid(io_respInfo_5_valid),
    .io_respInfo_5_bits_set(io_respInfo_5_bits_set),
    .io_respInfo_5_bits_tag(io_respInfo_5_bits_tag),
    .io_respInfo_5_bits_opcode(io_respInfo_5_bits_opcode),
    .io_respInfo_5_bits_reqID(io_respInfo_5_bits_reqID),
    .io_respInfo_5_bits_w_compack(io_respInfo_5_bits_w_compack),
    .io_respInfo_6_valid(io_respInfo_6_valid),
    .io_respInfo_6_bits_set(io_respInfo_6_bits_set),
    .io_respInfo_6_bits_tag(io_respInfo_6_bits_tag),
    .io_respInfo_6_bits_opcode(io_respInfo_6_bits_opcode),
    .io_respInfo_6_bits_reqID(io_respInfo_6_bits_reqID),
    .io_respInfo_6_bits_w_compack(io_respInfo_6_bits_w_compack),
    .io_respInfo_7_valid(io_respInfo_7_valid),
    .io_respInfo_7_bits_set(io_respInfo_7_bits_set),
    .io_respInfo_7_bits_tag(io_respInfo_7_bits_tag),
    .io_respInfo_7_bits_opcode(io_respInfo_7_bits_opcode),
    .io_respInfo_7_bits_reqID(io_respInfo_7_bits_reqID),
    .io_respInfo_7_bits_w_compack(io_respInfo_7_bits_w_compack),
    .io_respInfo_8_valid(io_respInfo_8_valid),
    .io_respInfo_8_bits_set(io_respInfo_8_bits_set),
    .io_respInfo_8_bits_tag(io_respInfo_8_bits_tag),
    .io_respInfo_8_bits_opcode(io_respInfo_8_bits_opcode),
    .io_respInfo_8_bits_reqID(io_respInfo_8_bits_reqID),
    .io_respInfo_8_bits_w_compack(io_respInfo_8_bits_w_compack),
    .io_respInfo_9_valid(io_respInfo_9_valid),
    .io_respInfo_9_bits_set(io_respInfo_9_bits_set),
    .io_respInfo_9_bits_tag(io_respInfo_9_bits_tag),
    .io_respInfo_9_bits_opcode(io_respInfo_9_bits_opcode),
    .io_respInfo_9_bits_reqID(io_respInfo_9_bits_reqID),
    .io_respInfo_9_bits_w_compack(io_respInfo_9_bits_w_compack),
    .io_respInfo_10_valid(io_respInfo_10_valid),
    .io_respInfo_10_bits_set(io_respInfo_10_bits_set),
    .io_respInfo_10_bits_tag(io_respInfo_10_bits_tag),
    .io_respInfo_10_bits_opcode(io_respInfo_10_bits_opcode),
    .io_respInfo_10_bits_reqID(io_respInfo_10_bits_reqID),
    .io_respInfo_10_bits_w_compack(io_respInfo_10_bits_w_compack),
    .io_respInfo_11_valid(io_respInfo_11_valid),
    .io_respInfo_11_bits_set(io_respInfo_11_bits_set),
    .io_respInfo_11_bits_tag(io_respInfo_11_bits_tag),
    .io_respInfo_11_bits_opcode(io_respInfo_11_bits_opcode),
    .io_respInfo_11_bits_reqID(io_respInfo_11_bits_reqID),
    .io_respInfo_11_bits_w_compack(io_respInfo_11_bits_w_compack),
    .io_respInfo_12_valid(io_respInfo_12_valid),
    .io_respInfo_12_bits_set(io_respInfo_12_bits_set),
    .io_respInfo_12_bits_tag(io_respInfo_12_bits_tag),
    .io_respInfo_12_bits_opcode(io_respInfo_12_bits_opcode),
    .io_respInfo_12_bits_reqID(io_respInfo_12_bits_reqID),
    .io_respInfo_12_bits_w_compack(io_respInfo_12_bits_w_compack),
    .io_respInfo_13_valid(io_respInfo_13_valid),
    .io_respInfo_13_bits_set(io_respInfo_13_bits_set),
    .io_respInfo_13_bits_tag(io_respInfo_13_bits_tag),
    .io_respInfo_13_bits_opcode(io_respInfo_13_bits_opcode),
    .io_respInfo_13_bits_reqID(io_respInfo_13_bits_reqID),
    .io_respInfo_13_bits_w_compack(io_respInfo_13_bits_w_compack),
    .io_respInfo_14_valid(io_respInfo_14_valid),
    .io_respInfo_14_bits_set(io_respInfo_14_bits_set),
    .io_respInfo_14_bits_tag(io_respInfo_14_bits_tag),
    .io_respInfo_14_bits_opcode(io_respInfo_14_bits_opcode),
    .io_respInfo_14_bits_reqID(io_respInfo_14_bits_reqID),
    .io_respInfo_14_bits_w_compack(io_respInfo_14_bits_w_compack),
    .io_respInfo_15_valid(io_respInfo_15_valid),
    .io_respInfo_15_bits_set(io_respInfo_15_bits_set),
    .io_respInfo_15_bits_tag(io_respInfo_15_bits_tag),
    .io_respInfo_15_bits_opcode(io_respInfo_15_bits_opcode),
    .io_respInfo_15_bits_reqID(io_respInfo_15_bits_reqID),
    .io_respInfo_15_bits_w_compack(io_respInfo_15_bits_w_compack),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_set(i_io_out_bits_set),
    .io_out_bits_bank(i_io_out_bits_bank),
    .io_out_bits_tag(i_io_out_bits_tag),
    .io_out_bits_snpVec_0(i_io_out_bits_snpVec_0),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_fwdNID(i_io_out_bits_fwdNID),
    .io_out_bits_fwdTxnID(i_io_out_bits_fwdTxnID),
    .io_out_bits_chiOpcode(i_io_out_bits_chiOpcode),
    .io_out_bits_retToSrc(i_io_out_bits_retToSrc),
    .io_out_bits_doNotGoToSD(i_io_out_bits_doNotGoToSD)
  );

  // 随机激励: 对每个输入独立取随机值; 部分字段偏置以覆盖控制路径
  task automatic drive_random();
    io_in_valid = $random;
    io_in_bits_set = $random;
    io_in_bits_bank = $random;
    io_in_bits_tag = $random;
    io_in_bits_replSnp = $random;
    io_in_bits_snpVec_0 = $random;
    io_in_bits_txnID = $random;
    io_in_bits_chiOpcode = $random;
    io_in_bits_retToSrc = $random;
    io_out_ready = $random;
    io_ack_valid = $random;
    io_ack_bits_txnID = $random;
    io_ack_bits_opcode = $random;
    io_respInfo_0_valid = $random;
    io_respInfo_0_bits_set = $random;
    io_respInfo_0_bits_tag = $random;
    io_respInfo_0_bits_opcode = $random;
    io_respInfo_0_bits_reqID = $random;
    io_respInfo_0_bits_w_compack = $random;
    io_respInfo_1_valid = $random;
    io_respInfo_1_bits_set = $random;
    io_respInfo_1_bits_tag = $random;
    io_respInfo_1_bits_opcode = $random;
    io_respInfo_1_bits_reqID = $random;
    io_respInfo_1_bits_w_compack = $random;
    io_respInfo_2_valid = $random;
    io_respInfo_2_bits_set = $random;
    io_respInfo_2_bits_tag = $random;
    io_respInfo_2_bits_opcode = $random;
    io_respInfo_2_bits_reqID = $random;
    io_respInfo_2_bits_w_compack = $random;
    io_respInfo_3_valid = $random;
    io_respInfo_3_bits_set = $random;
    io_respInfo_3_bits_tag = $random;
    io_respInfo_3_bits_opcode = $random;
    io_respInfo_3_bits_reqID = $random;
    io_respInfo_3_bits_w_compack = $random;
    io_respInfo_4_valid = $random;
    io_respInfo_4_bits_set = $random;
    io_respInfo_4_bits_tag = $random;
    io_respInfo_4_bits_opcode = $random;
    io_respInfo_4_bits_reqID = $random;
    io_respInfo_4_bits_w_compack = $random;
    io_respInfo_5_valid = $random;
    io_respInfo_5_bits_set = $random;
    io_respInfo_5_bits_tag = $random;
    io_respInfo_5_bits_opcode = $random;
    io_respInfo_5_bits_reqID = $random;
    io_respInfo_5_bits_w_compack = $random;
    io_respInfo_6_valid = $random;
    io_respInfo_6_bits_set = $random;
    io_respInfo_6_bits_tag = $random;
    io_respInfo_6_bits_opcode = $random;
    io_respInfo_6_bits_reqID = $random;
    io_respInfo_6_bits_w_compack = $random;
    io_respInfo_7_valid = $random;
    io_respInfo_7_bits_set = $random;
    io_respInfo_7_bits_tag = $random;
    io_respInfo_7_bits_opcode = $random;
    io_respInfo_7_bits_reqID = $random;
    io_respInfo_7_bits_w_compack = $random;
    io_respInfo_8_valid = $random;
    io_respInfo_8_bits_set = $random;
    io_respInfo_8_bits_tag = $random;
    io_respInfo_8_bits_opcode = $random;
    io_respInfo_8_bits_reqID = $random;
    io_respInfo_8_bits_w_compack = $random;
    io_respInfo_9_valid = $random;
    io_respInfo_9_bits_set = $random;
    io_respInfo_9_bits_tag = $random;
    io_respInfo_9_bits_opcode = $random;
    io_respInfo_9_bits_reqID = $random;
    io_respInfo_9_bits_w_compack = $random;
    io_respInfo_10_valid = $random;
    io_respInfo_10_bits_set = $random;
    io_respInfo_10_bits_tag = $random;
    io_respInfo_10_bits_opcode = $random;
    io_respInfo_10_bits_reqID = $random;
    io_respInfo_10_bits_w_compack = $random;
    io_respInfo_11_valid = $random;
    io_respInfo_11_bits_set = $random;
    io_respInfo_11_bits_tag = $random;
    io_respInfo_11_bits_opcode = $random;
    io_respInfo_11_bits_reqID = $random;
    io_respInfo_11_bits_w_compack = $random;
    io_respInfo_12_valid = $random;
    io_respInfo_12_bits_set = $random;
    io_respInfo_12_bits_tag = $random;
    io_respInfo_12_bits_opcode = $random;
    io_respInfo_12_bits_reqID = $random;
    io_respInfo_12_bits_w_compack = $random;
    io_respInfo_13_valid = $random;
    io_respInfo_13_bits_set = $random;
    io_respInfo_13_bits_tag = $random;
    io_respInfo_13_bits_opcode = $random;
    io_respInfo_13_bits_reqID = $random;
    io_respInfo_13_bits_w_compack = $random;
    io_respInfo_14_valid = $random;
    io_respInfo_14_bits_set = $random;
    io_respInfo_14_bits_tag = $random;
    io_respInfo_14_bits_opcode = $random;
    io_respInfo_14_bits_reqID = $random;
    io_respInfo_14_bits_w_compack = $random;
    io_respInfo_15_valid = $random;
    io_respInfo_15_bits_set = $random;
    io_respInfo_15_bits_tag = $random;
    io_respInfo_15_bits_opcode = $random;
    io_respInfo_15_bits_reqID = $random;
    io_respInfo_15_bits_w_compack = $random;
    // 偏置: 使控制路径更常被触发
    if (($random & 1) == 0) io_ack_bits_opcode = 7'h2;
    if (($random & 3) != 0) io_out_ready = 1'b1;
    // 让部分 respInfo 与入站任务同地址且合法 opcode 以触发 canFlow / initReady
    if (($random & 7) == 0) begin
      io_respInfo_0_valid = 1'b1;
      io_respInfo_0_bits_set = io_in_bits_set;
      io_respInfo_0_bits_tag = io_in_bits_tag;
      io_respInfo_0_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_0_bits_opcode = 7'h26; 1: io_respInfo_0_bits_opcode = 7'h7; default: io_respInfo_0_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_1_valid = 1'b1;
      io_respInfo_1_bits_set = io_in_bits_set;
      io_respInfo_1_bits_tag = io_in_bits_tag;
      io_respInfo_1_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_1_bits_opcode = 7'h26; 1: io_respInfo_1_bits_opcode = 7'h7; default: io_respInfo_1_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_2_valid = 1'b1;
      io_respInfo_2_bits_set = io_in_bits_set;
      io_respInfo_2_bits_tag = io_in_bits_tag;
      io_respInfo_2_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_2_bits_opcode = 7'h26; 1: io_respInfo_2_bits_opcode = 7'h7; default: io_respInfo_2_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_3_valid = 1'b1;
      io_respInfo_3_bits_set = io_in_bits_set;
      io_respInfo_3_bits_tag = io_in_bits_tag;
      io_respInfo_3_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_3_bits_opcode = 7'h26; 1: io_respInfo_3_bits_opcode = 7'h7; default: io_respInfo_3_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_4_valid = 1'b1;
      io_respInfo_4_bits_set = io_in_bits_set;
      io_respInfo_4_bits_tag = io_in_bits_tag;
      io_respInfo_4_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_4_bits_opcode = 7'h26; 1: io_respInfo_4_bits_opcode = 7'h7; default: io_respInfo_4_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_5_valid = 1'b1;
      io_respInfo_5_bits_set = io_in_bits_set;
      io_respInfo_5_bits_tag = io_in_bits_tag;
      io_respInfo_5_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_5_bits_opcode = 7'h26; 1: io_respInfo_5_bits_opcode = 7'h7; default: io_respInfo_5_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_6_valid = 1'b1;
      io_respInfo_6_bits_set = io_in_bits_set;
      io_respInfo_6_bits_tag = io_in_bits_tag;
      io_respInfo_6_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_6_bits_opcode = 7'h26; 1: io_respInfo_6_bits_opcode = 7'h7; default: io_respInfo_6_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_7_valid = 1'b1;
      io_respInfo_7_bits_set = io_in_bits_set;
      io_respInfo_7_bits_tag = io_in_bits_tag;
      io_respInfo_7_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_7_bits_opcode = 7'h26; 1: io_respInfo_7_bits_opcode = 7'h7; default: io_respInfo_7_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_8_valid = 1'b1;
      io_respInfo_8_bits_set = io_in_bits_set;
      io_respInfo_8_bits_tag = io_in_bits_tag;
      io_respInfo_8_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_8_bits_opcode = 7'h26; 1: io_respInfo_8_bits_opcode = 7'h7; default: io_respInfo_8_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_9_valid = 1'b1;
      io_respInfo_9_bits_set = io_in_bits_set;
      io_respInfo_9_bits_tag = io_in_bits_tag;
      io_respInfo_9_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_9_bits_opcode = 7'h26; 1: io_respInfo_9_bits_opcode = 7'h7; default: io_respInfo_9_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_10_valid = 1'b1;
      io_respInfo_10_bits_set = io_in_bits_set;
      io_respInfo_10_bits_tag = io_in_bits_tag;
      io_respInfo_10_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_10_bits_opcode = 7'h26; 1: io_respInfo_10_bits_opcode = 7'h7; default: io_respInfo_10_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_11_valid = 1'b1;
      io_respInfo_11_bits_set = io_in_bits_set;
      io_respInfo_11_bits_tag = io_in_bits_tag;
      io_respInfo_11_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_11_bits_opcode = 7'h26; 1: io_respInfo_11_bits_opcode = 7'h7; default: io_respInfo_11_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_12_valid = 1'b1;
      io_respInfo_12_bits_set = io_in_bits_set;
      io_respInfo_12_bits_tag = io_in_bits_tag;
      io_respInfo_12_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_12_bits_opcode = 7'h26; 1: io_respInfo_12_bits_opcode = 7'h7; default: io_respInfo_12_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_13_valid = 1'b1;
      io_respInfo_13_bits_set = io_in_bits_set;
      io_respInfo_13_bits_tag = io_in_bits_tag;
      io_respInfo_13_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_13_bits_opcode = 7'h26; 1: io_respInfo_13_bits_opcode = 7'h7; default: io_respInfo_13_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_14_valid = 1'b1;
      io_respInfo_14_bits_set = io_in_bits_set;
      io_respInfo_14_bits_tag = io_in_bits_tag;
      io_respInfo_14_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_14_bits_opcode = 7'h26; 1: io_respInfo_14_bits_opcode = 7'h7; default: io_respInfo_14_bits_opcode = 7'hC; endcase
    end
    if (($random & 7) == 0) begin
      io_respInfo_15_valid = 1'b1;
      io_respInfo_15_bits_set = io_in_bits_set;
      io_respInfo_15_bits_tag = io_in_bits_tag;
      io_respInfo_15_bits_w_compack = 1'b0;
      case ($random & 3) 0: io_respInfo_15_bits_opcode = 7'h26; 1: io_respInfo_15_bits_opcode = 7'h7; default: io_respInfo_15_bits_opcode = 7'hC; endcase
    end
    io_in_bits_replSnp = ($random & 1) ? 1'b1 : io_in_bits_replSnp;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_set !== i_io_out_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_set: g=%h i=%h", cyc, g_io_out_bits_set, i_io_out_bits_set); end
    if (g_io_out_bits_bank !== i_io_out_bits_bank) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_bank: g=%h i=%h", cyc, g_io_out_bits_bank, i_io_out_bits_bank); end
    if (g_io_out_bits_tag !== i_io_out_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_tag: g=%h i=%h", cyc, g_io_out_bits_tag, i_io_out_bits_tag); end
    if (g_io_out_bits_snpVec_0 !== i_io_out_bits_snpVec_0) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_snpVec_0: g=%h i=%h", cyc, g_io_out_bits_snpVec_0, i_io_out_bits_snpVec_0); end
    if (g_io_out_bits_txnID !== i_io_out_bits_txnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_txnID: g=%h i=%h", cyc, g_io_out_bits_txnID, i_io_out_bits_txnID); end
    if (g_io_out_bits_fwdNID !== i_io_out_bits_fwdNID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_fwdNID: g=%h i=%h", cyc, g_io_out_bits_fwdNID, i_io_out_bits_fwdNID); end
    if (g_io_out_bits_fwdTxnID !== i_io_out_bits_fwdTxnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_fwdTxnID: g=%h i=%h", cyc, g_io_out_bits_fwdTxnID, i_io_out_bits_fwdTxnID); end
    if (g_io_out_bits_chiOpcode !== i_io_out_bits_chiOpcode) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_chiOpcode: g=%h i=%h", cyc, g_io_out_bits_chiOpcode, i_io_out_bits_chiOpcode); end
    if (g_io_out_bits_retToSrc !== i_io_out_bits_retToSrc) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_retToSrc: g=%h i=%h", cyc, g_io_out_bits_retToSrc, i_io_out_bits_retToSrc); end
    if (g_io_out_bits_doNotGoToSD !== i_io_out_bits_doNotGoToSD) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_doNotGoToSD: g=%h i=%h", cyc, g_io_out_bits_doNotGoToSD, i_io_out_bits_doNotGoToSD); end
  endtask

  initial begin
    rst = 1'b1;
    io_in_valid = '0;
    io_in_bits_set = '0;
    io_in_bits_bank = '0;
    io_in_bits_tag = '0;
    io_in_bits_replSnp = '0;
    io_in_bits_snpVec_0 = '0;
    io_in_bits_txnID = '0;
    io_in_bits_chiOpcode = '0;
    io_in_bits_retToSrc = '0;
    io_out_ready = '0;
    io_ack_valid = '0;
    io_ack_bits_txnID = '0;
    io_ack_bits_opcode = '0;
    io_respInfo_0_valid = '0;
    io_respInfo_0_bits_set = '0;
    io_respInfo_0_bits_tag = '0;
    io_respInfo_0_bits_opcode = '0;
    io_respInfo_0_bits_reqID = '0;
    io_respInfo_0_bits_w_compack = '0;
    io_respInfo_1_valid = '0;
    io_respInfo_1_bits_set = '0;
    io_respInfo_1_bits_tag = '0;
    io_respInfo_1_bits_opcode = '0;
    io_respInfo_1_bits_reqID = '0;
    io_respInfo_1_bits_w_compack = '0;
    io_respInfo_2_valid = '0;
    io_respInfo_2_bits_set = '0;
    io_respInfo_2_bits_tag = '0;
    io_respInfo_2_bits_opcode = '0;
    io_respInfo_2_bits_reqID = '0;
    io_respInfo_2_bits_w_compack = '0;
    io_respInfo_3_valid = '0;
    io_respInfo_3_bits_set = '0;
    io_respInfo_3_bits_tag = '0;
    io_respInfo_3_bits_opcode = '0;
    io_respInfo_3_bits_reqID = '0;
    io_respInfo_3_bits_w_compack = '0;
    io_respInfo_4_valid = '0;
    io_respInfo_4_bits_set = '0;
    io_respInfo_4_bits_tag = '0;
    io_respInfo_4_bits_opcode = '0;
    io_respInfo_4_bits_reqID = '0;
    io_respInfo_4_bits_w_compack = '0;
    io_respInfo_5_valid = '0;
    io_respInfo_5_bits_set = '0;
    io_respInfo_5_bits_tag = '0;
    io_respInfo_5_bits_opcode = '0;
    io_respInfo_5_bits_reqID = '0;
    io_respInfo_5_bits_w_compack = '0;
    io_respInfo_6_valid = '0;
    io_respInfo_6_bits_set = '0;
    io_respInfo_6_bits_tag = '0;
    io_respInfo_6_bits_opcode = '0;
    io_respInfo_6_bits_reqID = '0;
    io_respInfo_6_bits_w_compack = '0;
    io_respInfo_7_valid = '0;
    io_respInfo_7_bits_set = '0;
    io_respInfo_7_bits_tag = '0;
    io_respInfo_7_bits_opcode = '0;
    io_respInfo_7_bits_reqID = '0;
    io_respInfo_7_bits_w_compack = '0;
    io_respInfo_8_valid = '0;
    io_respInfo_8_bits_set = '0;
    io_respInfo_8_bits_tag = '0;
    io_respInfo_8_bits_opcode = '0;
    io_respInfo_8_bits_reqID = '0;
    io_respInfo_8_bits_w_compack = '0;
    io_respInfo_9_valid = '0;
    io_respInfo_9_bits_set = '0;
    io_respInfo_9_bits_tag = '0;
    io_respInfo_9_bits_opcode = '0;
    io_respInfo_9_bits_reqID = '0;
    io_respInfo_9_bits_w_compack = '0;
    io_respInfo_10_valid = '0;
    io_respInfo_10_bits_set = '0;
    io_respInfo_10_bits_tag = '0;
    io_respInfo_10_bits_opcode = '0;
    io_respInfo_10_bits_reqID = '0;
    io_respInfo_10_bits_w_compack = '0;
    io_respInfo_11_valid = '0;
    io_respInfo_11_bits_set = '0;
    io_respInfo_11_bits_tag = '0;
    io_respInfo_11_bits_opcode = '0;
    io_respInfo_11_bits_reqID = '0;
    io_respInfo_11_bits_w_compack = '0;
    io_respInfo_12_valid = '0;
    io_respInfo_12_bits_set = '0;
    io_respInfo_12_bits_tag = '0;
    io_respInfo_12_bits_opcode = '0;
    io_respInfo_12_bits_reqID = '0;
    io_respInfo_12_bits_w_compack = '0;
    io_respInfo_13_valid = '0;
    io_respInfo_13_bits_set = '0;
    io_respInfo_13_bits_tag = '0;
    io_respInfo_13_bits_opcode = '0;
    io_respInfo_13_bits_reqID = '0;
    io_respInfo_13_bits_w_compack = '0;
    io_respInfo_14_valid = '0;
    io_respInfo_14_bits_set = '0;
    io_respInfo_14_bits_tag = '0;
    io_respInfo_14_bits_opcode = '0;
    io_respInfo_14_bits_reqID = '0;
    io_respInfo_14_bits_w_compack = '0;
    io_respInfo_15_valid = '0;
    io_respInfo_15_bits_set = '0;
    io_respInfo_15_bits_tag = '0;
    io_respInfo_15_bits_opcode = '0;
    io_respInfo_15_bits_reqID = '0;
    io_respInfo_15_bits_w_compack = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
