`timescale 1ns/1ps
// Differential UT for Arithmetic200c: golden (g_*) vs rewritten (x_*, *_xs) side by side, same random inputs.
// Takeover changes (agent/next200c-takeover): random mid-run reset pulses on FastArbiter_27 / IntBuffer_1/_2,
// outputs compared twice per cycle (after negedge input change and after posedge, catches sync-vs-async reset),
// coverage counters (round-robin overriding fixed priority, stall, MMIO lane 4 wins, irq toggles);
// every counter must be non-zero or the test fails. Tables get all 32/128 inputs many times (uniform src).
module tb;
  parameter integer NCYCLES = 200000;
  logic clock = 1'b0;
  integer errors = 0;
  integer checks = 0;
  integer cycle = 0;
  integer rst_left = 0;
  integer cov_rst_pulses = 0;
  integer cov_fa_rr_override = 0;
  integer cov_fa_stall = 0;
  integer cov_fa_lane4 = 0;
  integer cov_irq_toggle = 0;
  always #5 clock = ~clock;

  logic FastArbiter_27_reset;
  wire FastArbiter_27_g_io_in_0_ready;
  wire FastArbiter_27_x_io_in_0_ready;
  logic FastArbiter_27_io_in_0_valid;
  logic [10:0] FastArbiter_27_io_in_0_bits_tgtID;
  logic [11:0] FastArbiter_27_io_in_0_bits_txnID;
  logic [10:0] FastArbiter_27_io_in_0_bits_homeNID;
  logic [3:0] FastArbiter_27_io_in_0_bits_opcode;
  logic [1:0] FastArbiter_27_io_in_0_bits_respErr;
  logic [2:0] FastArbiter_27_io_in_0_bits_resp;
  logic [3:0] FastArbiter_27_io_in_0_bits_dataSource;
  logic [11:0] FastArbiter_27_io_in_0_bits_dbID;
  logic [1:0] FastArbiter_27_io_in_0_bits_ccID;
  logic [1:0] FastArbiter_27_io_in_0_bits_dataID;
  logic FastArbiter_27_io_in_0_bits_traceTag;
  logic [31:0] FastArbiter_27_io_in_0_bits_be;
  logic [255:0] FastArbiter_27_io_in_0_bits_data;
  logic [31:0] FastArbiter_27_io_in_0_bits_dataCheck;
  logic [3:0] FastArbiter_27_io_in_0_bits_poison;
  wire FastArbiter_27_g_io_in_1_ready;
  wire FastArbiter_27_x_io_in_1_ready;
  logic FastArbiter_27_io_in_1_valid;
  logic [10:0] FastArbiter_27_io_in_1_bits_tgtID;
  logic [11:0] FastArbiter_27_io_in_1_bits_txnID;
  logic [10:0] FastArbiter_27_io_in_1_bits_homeNID;
  logic [3:0] FastArbiter_27_io_in_1_bits_opcode;
  logic [1:0] FastArbiter_27_io_in_1_bits_respErr;
  logic [2:0] FastArbiter_27_io_in_1_bits_resp;
  logic [3:0] FastArbiter_27_io_in_1_bits_dataSource;
  logic [11:0] FastArbiter_27_io_in_1_bits_dbID;
  logic [1:0] FastArbiter_27_io_in_1_bits_ccID;
  logic [1:0] FastArbiter_27_io_in_1_bits_dataID;
  logic FastArbiter_27_io_in_1_bits_traceTag;
  logic [31:0] FastArbiter_27_io_in_1_bits_be;
  logic [255:0] FastArbiter_27_io_in_1_bits_data;
  logic [31:0] FastArbiter_27_io_in_1_bits_dataCheck;
  logic [3:0] FastArbiter_27_io_in_1_bits_poison;
  wire FastArbiter_27_g_io_in_2_ready;
  wire FastArbiter_27_x_io_in_2_ready;
  logic FastArbiter_27_io_in_2_valid;
  logic [10:0] FastArbiter_27_io_in_2_bits_tgtID;
  logic [11:0] FastArbiter_27_io_in_2_bits_txnID;
  logic [10:0] FastArbiter_27_io_in_2_bits_homeNID;
  logic [3:0] FastArbiter_27_io_in_2_bits_opcode;
  logic [1:0] FastArbiter_27_io_in_2_bits_respErr;
  logic [2:0] FastArbiter_27_io_in_2_bits_resp;
  logic [3:0] FastArbiter_27_io_in_2_bits_dataSource;
  logic [11:0] FastArbiter_27_io_in_2_bits_dbID;
  logic [1:0] FastArbiter_27_io_in_2_bits_ccID;
  logic [1:0] FastArbiter_27_io_in_2_bits_dataID;
  logic FastArbiter_27_io_in_2_bits_traceTag;
  logic [31:0] FastArbiter_27_io_in_2_bits_be;
  logic [255:0] FastArbiter_27_io_in_2_bits_data;
  logic [31:0] FastArbiter_27_io_in_2_bits_dataCheck;
  logic [3:0] FastArbiter_27_io_in_2_bits_poison;
  wire FastArbiter_27_g_io_in_3_ready;
  wire FastArbiter_27_x_io_in_3_ready;
  logic FastArbiter_27_io_in_3_valid;
  logic [10:0] FastArbiter_27_io_in_3_bits_tgtID;
  logic [11:0] FastArbiter_27_io_in_3_bits_txnID;
  logic [10:0] FastArbiter_27_io_in_3_bits_homeNID;
  logic [3:0] FastArbiter_27_io_in_3_bits_opcode;
  logic [1:0] FastArbiter_27_io_in_3_bits_respErr;
  logic [2:0] FastArbiter_27_io_in_3_bits_resp;
  logic [3:0] FastArbiter_27_io_in_3_bits_dataSource;
  logic [11:0] FastArbiter_27_io_in_3_bits_dbID;
  logic [1:0] FastArbiter_27_io_in_3_bits_ccID;
  logic [1:0] FastArbiter_27_io_in_3_bits_dataID;
  logic FastArbiter_27_io_in_3_bits_traceTag;
  logic [31:0] FastArbiter_27_io_in_3_bits_be;
  logic [255:0] FastArbiter_27_io_in_3_bits_data;
  logic [31:0] FastArbiter_27_io_in_3_bits_dataCheck;
  logic [3:0] FastArbiter_27_io_in_3_bits_poison;
  wire FastArbiter_27_g_io_in_4_ready;
  wire FastArbiter_27_x_io_in_4_ready;
  logic FastArbiter_27_io_in_4_valid;
  logic [3:0] FastArbiter_27_io_in_4_bits_qos;
  logic [10:0] FastArbiter_27_io_in_4_bits_tgtID;
  logic [11:0] FastArbiter_27_io_in_4_bits_txnID;
  logic [10:0] FastArbiter_27_io_in_4_bits_homeNID;
  logic [3:0] FastArbiter_27_io_in_4_bits_opcode;
  logic [1:0] FastArbiter_27_io_in_4_bits_respErr;
  logic [2:0] FastArbiter_27_io_in_4_bits_resp;
  logic [3:0] FastArbiter_27_io_in_4_bits_dataSource;
  logic [2:0] FastArbiter_27_io_in_4_bits_cBusy;
  logic [11:0] FastArbiter_27_io_in_4_bits_dbID;
  logic [1:0] FastArbiter_27_io_in_4_bits_ccID;
  logic [1:0] FastArbiter_27_io_in_4_bits_dataID;
  logic [1:0] FastArbiter_27_io_in_4_bits_tagOp;
  logic [7:0] FastArbiter_27_io_in_4_bits_tag;
  logic [1:0] FastArbiter_27_io_in_4_bits_tu;
  logic FastArbiter_27_io_in_4_bits_traceTag;
  logic [3:0] FastArbiter_27_io_in_4_bits_rsvdc;
  logic [31:0] FastArbiter_27_io_in_4_bits_be;
  logic [255:0] FastArbiter_27_io_in_4_bits_data;
  logic [31:0] FastArbiter_27_io_in_4_bits_dataCheck;
  logic [3:0] FastArbiter_27_io_in_4_bits_poison;
  logic FastArbiter_27_io_out_ready;
  wire FastArbiter_27_g_io_out_valid;
  wire FastArbiter_27_x_io_out_valid;
  wire [3:0] FastArbiter_27_g_io_out_bits_qos;
  wire [3:0] FastArbiter_27_x_io_out_bits_qos;
  wire [10:0] FastArbiter_27_g_io_out_bits_tgtID;
  wire [10:0] FastArbiter_27_x_io_out_bits_tgtID;
  wire [11:0] FastArbiter_27_g_io_out_bits_txnID;
  wire [11:0] FastArbiter_27_x_io_out_bits_txnID;
  wire [10:0] FastArbiter_27_g_io_out_bits_homeNID;
  wire [10:0] FastArbiter_27_x_io_out_bits_homeNID;
  wire [3:0] FastArbiter_27_g_io_out_bits_opcode;
  wire [3:0] FastArbiter_27_x_io_out_bits_opcode;
  wire [1:0] FastArbiter_27_g_io_out_bits_respErr;
  wire [1:0] FastArbiter_27_x_io_out_bits_respErr;
  wire [2:0] FastArbiter_27_g_io_out_bits_resp;
  wire [2:0] FastArbiter_27_x_io_out_bits_resp;
  wire [3:0] FastArbiter_27_g_io_out_bits_dataSource;
  wire [3:0] FastArbiter_27_x_io_out_bits_dataSource;
  wire [2:0] FastArbiter_27_g_io_out_bits_cBusy;
  wire [2:0] FastArbiter_27_x_io_out_bits_cBusy;
  wire [11:0] FastArbiter_27_g_io_out_bits_dbID;
  wire [11:0] FastArbiter_27_x_io_out_bits_dbID;
  wire [1:0] FastArbiter_27_g_io_out_bits_ccID;
  wire [1:0] FastArbiter_27_x_io_out_bits_ccID;
  wire [1:0] FastArbiter_27_g_io_out_bits_dataID;
  wire [1:0] FastArbiter_27_x_io_out_bits_dataID;
  wire [1:0] FastArbiter_27_g_io_out_bits_tagOp;
  wire [1:0] FastArbiter_27_x_io_out_bits_tagOp;
  wire [7:0] FastArbiter_27_g_io_out_bits_tag;
  wire [7:0] FastArbiter_27_x_io_out_bits_tag;
  wire [1:0] FastArbiter_27_g_io_out_bits_tu;
  wire [1:0] FastArbiter_27_x_io_out_bits_tu;
  wire FastArbiter_27_g_io_out_bits_traceTag;
  wire FastArbiter_27_x_io_out_bits_traceTag;
  wire [3:0] FastArbiter_27_g_io_out_bits_rsvdc;
  wire [3:0] FastArbiter_27_x_io_out_bits_rsvdc;
  wire [31:0] FastArbiter_27_g_io_out_bits_be;
  wire [31:0] FastArbiter_27_x_io_out_bits_be;
  wire [255:0] FastArbiter_27_g_io_out_bits_data;
  wire [255:0] FastArbiter_27_x_io_out_bits_data;
  wire [31:0] FastArbiter_27_g_io_out_bits_dataCheck;
  wire [31:0] FastArbiter_27_x_io_out_bits_dataCheck;
  wire [3:0] FastArbiter_27_g_io_out_bits_poison;
  wire [3:0] FastArbiter_27_x_io_out_bits_poison;

  logic [4:0] FliDTable_src;
  wire [15:0] FliDTable_g_out;
  wire [15:0] FliDTable_x_out;

  logic [4:0] FliHTable_src;
  wire [15:0] FliHTable_g_out;
  wire [15:0] FliHTable_x_out;

  logic [4:0] FliSTable_src;
  wire [15:0] FliSTable_g_out;
  wire [15:0] FliSTable_x_out;

  logic IntBuffer_1_reset;
  logic IntBuffer_1_auto_in_0;
  logic IntBuffer_1_auto_in_1;
  wire IntBuffer_1_g_auto_out_0;
  wire IntBuffer_1_x_auto_out_0;
  wire IntBuffer_1_g_auto_out_1;
  wire IntBuffer_1_x_auto_out_1;

  logic IntBuffer_2_reset;
  logic IntBuffer_2_auto_in_1_0;
  logic IntBuffer_2_auto_in_0_0;
  wire IntBuffer_2_g_auto_out_1_0;
  wire IntBuffer_2_x_auto_out_1_0;
  wire IntBuffer_2_g_auto_out_0_0;
  wire IntBuffer_2_x_auto_out_0_0;

  logic [6:0] Rec7Table_src;
  wire [6:0] Rec7Table_g_out;
  wire [6:0] Rec7Table_x_out;

  logic [6:0] Rsqrt7Table_src;
  wire [6:0] Rsqrt7Table_g_out;
  wire [6:0] Rsqrt7Table_x_out;

  FastArbiter_27 g_FastArbiter_27 (
    .clock(clock),
    .reset(FastArbiter_27_reset),
    .io_in_0_ready(FastArbiter_27_g_io_in_0_ready),
    .io_in_0_valid(FastArbiter_27_io_in_0_valid),
    .io_in_0_bits_tgtID(FastArbiter_27_io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(FastArbiter_27_io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(FastArbiter_27_io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(FastArbiter_27_io_in_0_bits_opcode),
    .io_in_0_bits_respErr(FastArbiter_27_io_in_0_bits_respErr),
    .io_in_0_bits_resp(FastArbiter_27_io_in_0_bits_resp),
    .io_in_0_bits_dataSource(FastArbiter_27_io_in_0_bits_dataSource),
    .io_in_0_bits_dbID(FastArbiter_27_io_in_0_bits_dbID),
    .io_in_0_bits_ccID(FastArbiter_27_io_in_0_bits_ccID),
    .io_in_0_bits_dataID(FastArbiter_27_io_in_0_bits_dataID),
    .io_in_0_bits_traceTag(FastArbiter_27_io_in_0_bits_traceTag),
    .io_in_0_bits_be(FastArbiter_27_io_in_0_bits_be),
    .io_in_0_bits_data(FastArbiter_27_io_in_0_bits_data),
    .io_in_0_bits_dataCheck(FastArbiter_27_io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(FastArbiter_27_io_in_0_bits_poison),
    .io_in_1_ready(FastArbiter_27_g_io_in_1_ready),
    .io_in_1_valid(FastArbiter_27_io_in_1_valid),
    .io_in_1_bits_tgtID(FastArbiter_27_io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(FastArbiter_27_io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(FastArbiter_27_io_in_1_bits_homeNID),
    .io_in_1_bits_opcode(FastArbiter_27_io_in_1_bits_opcode),
    .io_in_1_bits_respErr(FastArbiter_27_io_in_1_bits_respErr),
    .io_in_1_bits_resp(FastArbiter_27_io_in_1_bits_resp),
    .io_in_1_bits_dataSource(FastArbiter_27_io_in_1_bits_dataSource),
    .io_in_1_bits_dbID(FastArbiter_27_io_in_1_bits_dbID),
    .io_in_1_bits_ccID(FastArbiter_27_io_in_1_bits_ccID),
    .io_in_1_bits_dataID(FastArbiter_27_io_in_1_bits_dataID),
    .io_in_1_bits_traceTag(FastArbiter_27_io_in_1_bits_traceTag),
    .io_in_1_bits_be(FastArbiter_27_io_in_1_bits_be),
    .io_in_1_bits_data(FastArbiter_27_io_in_1_bits_data),
    .io_in_1_bits_dataCheck(FastArbiter_27_io_in_1_bits_dataCheck),
    .io_in_1_bits_poison(FastArbiter_27_io_in_1_bits_poison),
    .io_in_2_ready(FastArbiter_27_g_io_in_2_ready),
    .io_in_2_valid(FastArbiter_27_io_in_2_valid),
    .io_in_2_bits_tgtID(FastArbiter_27_io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(FastArbiter_27_io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(FastArbiter_27_io_in_2_bits_homeNID),
    .io_in_2_bits_opcode(FastArbiter_27_io_in_2_bits_opcode),
    .io_in_2_bits_respErr(FastArbiter_27_io_in_2_bits_respErr),
    .io_in_2_bits_resp(FastArbiter_27_io_in_2_bits_resp),
    .io_in_2_bits_dataSource(FastArbiter_27_io_in_2_bits_dataSource),
    .io_in_2_bits_dbID(FastArbiter_27_io_in_2_bits_dbID),
    .io_in_2_bits_ccID(FastArbiter_27_io_in_2_bits_ccID),
    .io_in_2_bits_dataID(FastArbiter_27_io_in_2_bits_dataID),
    .io_in_2_bits_traceTag(FastArbiter_27_io_in_2_bits_traceTag),
    .io_in_2_bits_be(FastArbiter_27_io_in_2_bits_be),
    .io_in_2_bits_data(FastArbiter_27_io_in_2_bits_data),
    .io_in_2_bits_dataCheck(FastArbiter_27_io_in_2_bits_dataCheck),
    .io_in_2_bits_poison(FastArbiter_27_io_in_2_bits_poison),
    .io_in_3_ready(FastArbiter_27_g_io_in_3_ready),
    .io_in_3_valid(FastArbiter_27_io_in_3_valid),
    .io_in_3_bits_tgtID(FastArbiter_27_io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(FastArbiter_27_io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(FastArbiter_27_io_in_3_bits_homeNID),
    .io_in_3_bits_opcode(FastArbiter_27_io_in_3_bits_opcode),
    .io_in_3_bits_respErr(FastArbiter_27_io_in_3_bits_respErr),
    .io_in_3_bits_resp(FastArbiter_27_io_in_3_bits_resp),
    .io_in_3_bits_dataSource(FastArbiter_27_io_in_3_bits_dataSource),
    .io_in_3_bits_dbID(FastArbiter_27_io_in_3_bits_dbID),
    .io_in_3_bits_ccID(FastArbiter_27_io_in_3_bits_ccID),
    .io_in_3_bits_dataID(FastArbiter_27_io_in_3_bits_dataID),
    .io_in_3_bits_traceTag(FastArbiter_27_io_in_3_bits_traceTag),
    .io_in_3_bits_be(FastArbiter_27_io_in_3_bits_be),
    .io_in_3_bits_data(FastArbiter_27_io_in_3_bits_data),
    .io_in_3_bits_dataCheck(FastArbiter_27_io_in_3_bits_dataCheck),
    .io_in_3_bits_poison(FastArbiter_27_io_in_3_bits_poison),
    .io_in_4_ready(FastArbiter_27_g_io_in_4_ready),
    .io_in_4_valid(FastArbiter_27_io_in_4_valid),
    .io_in_4_bits_qos(FastArbiter_27_io_in_4_bits_qos),
    .io_in_4_bits_tgtID(FastArbiter_27_io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(FastArbiter_27_io_in_4_bits_txnID),
    .io_in_4_bits_homeNID(FastArbiter_27_io_in_4_bits_homeNID),
    .io_in_4_bits_opcode(FastArbiter_27_io_in_4_bits_opcode),
    .io_in_4_bits_respErr(FastArbiter_27_io_in_4_bits_respErr),
    .io_in_4_bits_resp(FastArbiter_27_io_in_4_bits_resp),
    .io_in_4_bits_dataSource(FastArbiter_27_io_in_4_bits_dataSource),
    .io_in_4_bits_cBusy(FastArbiter_27_io_in_4_bits_cBusy),
    .io_in_4_bits_dbID(FastArbiter_27_io_in_4_bits_dbID),
    .io_in_4_bits_ccID(FastArbiter_27_io_in_4_bits_ccID),
    .io_in_4_bits_dataID(FastArbiter_27_io_in_4_bits_dataID),
    .io_in_4_bits_tagOp(FastArbiter_27_io_in_4_bits_tagOp),
    .io_in_4_bits_tag(FastArbiter_27_io_in_4_bits_tag),
    .io_in_4_bits_tu(FastArbiter_27_io_in_4_bits_tu),
    .io_in_4_bits_traceTag(FastArbiter_27_io_in_4_bits_traceTag),
    .io_in_4_bits_rsvdc(FastArbiter_27_io_in_4_bits_rsvdc),
    .io_in_4_bits_be(FastArbiter_27_io_in_4_bits_be),
    .io_in_4_bits_data(FastArbiter_27_io_in_4_bits_data),
    .io_in_4_bits_dataCheck(FastArbiter_27_io_in_4_bits_dataCheck),
    .io_in_4_bits_poison(FastArbiter_27_io_in_4_bits_poison),
    .io_out_ready(FastArbiter_27_io_out_ready),
    .io_out_valid(FastArbiter_27_g_io_out_valid),
    .io_out_bits_qos(FastArbiter_27_g_io_out_bits_qos),
    .io_out_bits_tgtID(FastArbiter_27_g_io_out_bits_tgtID),
    .io_out_bits_txnID(FastArbiter_27_g_io_out_bits_txnID),
    .io_out_bits_homeNID(FastArbiter_27_g_io_out_bits_homeNID),
    .io_out_bits_opcode(FastArbiter_27_g_io_out_bits_opcode),
    .io_out_bits_respErr(FastArbiter_27_g_io_out_bits_respErr),
    .io_out_bits_resp(FastArbiter_27_g_io_out_bits_resp),
    .io_out_bits_dataSource(FastArbiter_27_g_io_out_bits_dataSource),
    .io_out_bits_cBusy(FastArbiter_27_g_io_out_bits_cBusy),
    .io_out_bits_dbID(FastArbiter_27_g_io_out_bits_dbID),
    .io_out_bits_ccID(FastArbiter_27_g_io_out_bits_ccID),
    .io_out_bits_dataID(FastArbiter_27_g_io_out_bits_dataID),
    .io_out_bits_tagOp(FastArbiter_27_g_io_out_bits_tagOp),
    .io_out_bits_tag(FastArbiter_27_g_io_out_bits_tag),
    .io_out_bits_tu(FastArbiter_27_g_io_out_bits_tu),
    .io_out_bits_traceTag(FastArbiter_27_g_io_out_bits_traceTag),
    .io_out_bits_rsvdc(FastArbiter_27_g_io_out_bits_rsvdc),
    .io_out_bits_be(FastArbiter_27_g_io_out_bits_be),
    .io_out_bits_data(FastArbiter_27_g_io_out_bits_data),
    .io_out_bits_dataCheck(FastArbiter_27_g_io_out_bits_dataCheck),
    .io_out_bits_poison(FastArbiter_27_g_io_out_bits_poison)
  );
  FastArbiter_27_xs x_FastArbiter_27 (
    .clock(clock),
    .reset(FastArbiter_27_reset),
    .io_in_0_ready(FastArbiter_27_x_io_in_0_ready),
    .io_in_0_valid(FastArbiter_27_io_in_0_valid),
    .io_in_0_bits_tgtID(FastArbiter_27_io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(FastArbiter_27_io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(FastArbiter_27_io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(FastArbiter_27_io_in_0_bits_opcode),
    .io_in_0_bits_respErr(FastArbiter_27_io_in_0_bits_respErr),
    .io_in_0_bits_resp(FastArbiter_27_io_in_0_bits_resp),
    .io_in_0_bits_dataSource(FastArbiter_27_io_in_0_bits_dataSource),
    .io_in_0_bits_dbID(FastArbiter_27_io_in_0_bits_dbID),
    .io_in_0_bits_ccID(FastArbiter_27_io_in_0_bits_ccID),
    .io_in_0_bits_dataID(FastArbiter_27_io_in_0_bits_dataID),
    .io_in_0_bits_traceTag(FastArbiter_27_io_in_0_bits_traceTag),
    .io_in_0_bits_be(FastArbiter_27_io_in_0_bits_be),
    .io_in_0_bits_data(FastArbiter_27_io_in_0_bits_data),
    .io_in_0_bits_dataCheck(FastArbiter_27_io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(FastArbiter_27_io_in_0_bits_poison),
    .io_in_1_ready(FastArbiter_27_x_io_in_1_ready),
    .io_in_1_valid(FastArbiter_27_io_in_1_valid),
    .io_in_1_bits_tgtID(FastArbiter_27_io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(FastArbiter_27_io_in_1_bits_txnID),
    .io_in_1_bits_homeNID(FastArbiter_27_io_in_1_bits_homeNID),
    .io_in_1_bits_opcode(FastArbiter_27_io_in_1_bits_opcode),
    .io_in_1_bits_respErr(FastArbiter_27_io_in_1_bits_respErr),
    .io_in_1_bits_resp(FastArbiter_27_io_in_1_bits_resp),
    .io_in_1_bits_dataSource(FastArbiter_27_io_in_1_bits_dataSource),
    .io_in_1_bits_dbID(FastArbiter_27_io_in_1_bits_dbID),
    .io_in_1_bits_ccID(FastArbiter_27_io_in_1_bits_ccID),
    .io_in_1_bits_dataID(FastArbiter_27_io_in_1_bits_dataID),
    .io_in_1_bits_traceTag(FastArbiter_27_io_in_1_bits_traceTag),
    .io_in_1_bits_be(FastArbiter_27_io_in_1_bits_be),
    .io_in_1_bits_data(FastArbiter_27_io_in_1_bits_data),
    .io_in_1_bits_dataCheck(FastArbiter_27_io_in_1_bits_dataCheck),
    .io_in_1_bits_poison(FastArbiter_27_io_in_1_bits_poison),
    .io_in_2_ready(FastArbiter_27_x_io_in_2_ready),
    .io_in_2_valid(FastArbiter_27_io_in_2_valid),
    .io_in_2_bits_tgtID(FastArbiter_27_io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(FastArbiter_27_io_in_2_bits_txnID),
    .io_in_2_bits_homeNID(FastArbiter_27_io_in_2_bits_homeNID),
    .io_in_2_bits_opcode(FastArbiter_27_io_in_2_bits_opcode),
    .io_in_2_bits_respErr(FastArbiter_27_io_in_2_bits_respErr),
    .io_in_2_bits_resp(FastArbiter_27_io_in_2_bits_resp),
    .io_in_2_bits_dataSource(FastArbiter_27_io_in_2_bits_dataSource),
    .io_in_2_bits_dbID(FastArbiter_27_io_in_2_bits_dbID),
    .io_in_2_bits_ccID(FastArbiter_27_io_in_2_bits_ccID),
    .io_in_2_bits_dataID(FastArbiter_27_io_in_2_bits_dataID),
    .io_in_2_bits_traceTag(FastArbiter_27_io_in_2_bits_traceTag),
    .io_in_2_bits_be(FastArbiter_27_io_in_2_bits_be),
    .io_in_2_bits_data(FastArbiter_27_io_in_2_bits_data),
    .io_in_2_bits_dataCheck(FastArbiter_27_io_in_2_bits_dataCheck),
    .io_in_2_bits_poison(FastArbiter_27_io_in_2_bits_poison),
    .io_in_3_ready(FastArbiter_27_x_io_in_3_ready),
    .io_in_3_valid(FastArbiter_27_io_in_3_valid),
    .io_in_3_bits_tgtID(FastArbiter_27_io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(FastArbiter_27_io_in_3_bits_txnID),
    .io_in_3_bits_homeNID(FastArbiter_27_io_in_3_bits_homeNID),
    .io_in_3_bits_opcode(FastArbiter_27_io_in_3_bits_opcode),
    .io_in_3_bits_respErr(FastArbiter_27_io_in_3_bits_respErr),
    .io_in_3_bits_resp(FastArbiter_27_io_in_3_bits_resp),
    .io_in_3_bits_dataSource(FastArbiter_27_io_in_3_bits_dataSource),
    .io_in_3_bits_dbID(FastArbiter_27_io_in_3_bits_dbID),
    .io_in_3_bits_ccID(FastArbiter_27_io_in_3_bits_ccID),
    .io_in_3_bits_dataID(FastArbiter_27_io_in_3_bits_dataID),
    .io_in_3_bits_traceTag(FastArbiter_27_io_in_3_bits_traceTag),
    .io_in_3_bits_be(FastArbiter_27_io_in_3_bits_be),
    .io_in_3_bits_data(FastArbiter_27_io_in_3_bits_data),
    .io_in_3_bits_dataCheck(FastArbiter_27_io_in_3_bits_dataCheck),
    .io_in_3_bits_poison(FastArbiter_27_io_in_3_bits_poison),
    .io_in_4_ready(FastArbiter_27_x_io_in_4_ready),
    .io_in_4_valid(FastArbiter_27_io_in_4_valid),
    .io_in_4_bits_qos(FastArbiter_27_io_in_4_bits_qos),
    .io_in_4_bits_tgtID(FastArbiter_27_io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(FastArbiter_27_io_in_4_bits_txnID),
    .io_in_4_bits_homeNID(FastArbiter_27_io_in_4_bits_homeNID),
    .io_in_4_bits_opcode(FastArbiter_27_io_in_4_bits_opcode),
    .io_in_4_bits_respErr(FastArbiter_27_io_in_4_bits_respErr),
    .io_in_4_bits_resp(FastArbiter_27_io_in_4_bits_resp),
    .io_in_4_bits_dataSource(FastArbiter_27_io_in_4_bits_dataSource),
    .io_in_4_bits_cBusy(FastArbiter_27_io_in_4_bits_cBusy),
    .io_in_4_bits_dbID(FastArbiter_27_io_in_4_bits_dbID),
    .io_in_4_bits_ccID(FastArbiter_27_io_in_4_bits_ccID),
    .io_in_4_bits_dataID(FastArbiter_27_io_in_4_bits_dataID),
    .io_in_4_bits_tagOp(FastArbiter_27_io_in_4_bits_tagOp),
    .io_in_4_bits_tag(FastArbiter_27_io_in_4_bits_tag),
    .io_in_4_bits_tu(FastArbiter_27_io_in_4_bits_tu),
    .io_in_4_bits_traceTag(FastArbiter_27_io_in_4_bits_traceTag),
    .io_in_4_bits_rsvdc(FastArbiter_27_io_in_4_bits_rsvdc),
    .io_in_4_bits_be(FastArbiter_27_io_in_4_bits_be),
    .io_in_4_bits_data(FastArbiter_27_io_in_4_bits_data),
    .io_in_4_bits_dataCheck(FastArbiter_27_io_in_4_bits_dataCheck),
    .io_in_4_bits_poison(FastArbiter_27_io_in_4_bits_poison),
    .io_out_ready(FastArbiter_27_io_out_ready),
    .io_out_valid(FastArbiter_27_x_io_out_valid),
    .io_out_bits_qos(FastArbiter_27_x_io_out_bits_qos),
    .io_out_bits_tgtID(FastArbiter_27_x_io_out_bits_tgtID),
    .io_out_bits_txnID(FastArbiter_27_x_io_out_bits_txnID),
    .io_out_bits_homeNID(FastArbiter_27_x_io_out_bits_homeNID),
    .io_out_bits_opcode(FastArbiter_27_x_io_out_bits_opcode),
    .io_out_bits_respErr(FastArbiter_27_x_io_out_bits_respErr),
    .io_out_bits_resp(FastArbiter_27_x_io_out_bits_resp),
    .io_out_bits_dataSource(FastArbiter_27_x_io_out_bits_dataSource),
    .io_out_bits_cBusy(FastArbiter_27_x_io_out_bits_cBusy),
    .io_out_bits_dbID(FastArbiter_27_x_io_out_bits_dbID),
    .io_out_bits_ccID(FastArbiter_27_x_io_out_bits_ccID),
    .io_out_bits_dataID(FastArbiter_27_x_io_out_bits_dataID),
    .io_out_bits_tagOp(FastArbiter_27_x_io_out_bits_tagOp),
    .io_out_bits_tag(FastArbiter_27_x_io_out_bits_tag),
    .io_out_bits_tu(FastArbiter_27_x_io_out_bits_tu),
    .io_out_bits_traceTag(FastArbiter_27_x_io_out_bits_traceTag),
    .io_out_bits_rsvdc(FastArbiter_27_x_io_out_bits_rsvdc),
    .io_out_bits_be(FastArbiter_27_x_io_out_bits_be),
    .io_out_bits_data(FastArbiter_27_x_io_out_bits_data),
    .io_out_bits_dataCheck(FastArbiter_27_x_io_out_bits_dataCheck),
    .io_out_bits_poison(FastArbiter_27_x_io_out_bits_poison)
  );

  FliDTable g_FliDTable (
    .src(FliDTable_src),
    .out(FliDTable_g_out)
  );
  FliDTable_xs x_FliDTable (
    .src(FliDTable_src),
    .out(FliDTable_x_out)
  );

  FliHTable g_FliHTable (
    .src(FliHTable_src),
    .out(FliHTable_g_out)
  );
  FliHTable_xs x_FliHTable (
    .src(FliHTable_src),
    .out(FliHTable_x_out)
  );

  FliSTable g_FliSTable (
    .src(FliSTable_src),
    .out(FliSTable_g_out)
  );
  FliSTable_xs x_FliSTable (
    .src(FliSTable_src),
    .out(FliSTable_x_out)
  );

  IntBuffer_1 g_IntBuffer_1 (
    .clock(clock),
    .reset(IntBuffer_1_reset),
    .auto_in_0(IntBuffer_1_auto_in_0),
    .auto_in_1(IntBuffer_1_auto_in_1),
    .auto_out_0(IntBuffer_1_g_auto_out_0),
    .auto_out_1(IntBuffer_1_g_auto_out_1)
  );
  IntBuffer_1_xs x_IntBuffer_1 (
    .clock(clock),
    .reset(IntBuffer_1_reset),
    .auto_in_0(IntBuffer_1_auto_in_0),
    .auto_in_1(IntBuffer_1_auto_in_1),
    .auto_out_0(IntBuffer_1_x_auto_out_0),
    .auto_out_1(IntBuffer_1_x_auto_out_1)
  );

  IntBuffer_2 g_IntBuffer_2 (
    .clock(clock),
    .reset(IntBuffer_2_reset),
    .auto_in_1_0(IntBuffer_2_auto_in_1_0),
    .auto_in_0_0(IntBuffer_2_auto_in_0_0),
    .auto_out_1_0(IntBuffer_2_g_auto_out_1_0),
    .auto_out_0_0(IntBuffer_2_g_auto_out_0_0)
  );
  IntBuffer_2_xs x_IntBuffer_2 (
    .clock(clock),
    .reset(IntBuffer_2_reset),
    .auto_in_1_0(IntBuffer_2_auto_in_1_0),
    .auto_in_0_0(IntBuffer_2_auto_in_0_0),
    .auto_out_1_0(IntBuffer_2_x_auto_out_1_0),
    .auto_out_0_0(IntBuffer_2_x_auto_out_0_0)
  );

  Rec7Table g_Rec7Table (
    .src(Rec7Table_src),
    .out(Rec7Table_g_out)
  );
  Rec7Table_xs x_Rec7Table (
    .src(Rec7Table_src),
    .out(Rec7Table_x_out)
  );

  Rsqrt7Table g_Rsqrt7Table (
    .src(Rsqrt7Table_src),
    .out(Rsqrt7Table_g_out)
  );
  Rsqrt7Table_xs x_Rsqrt7Table (
    .src(Rsqrt7Table_src),
    .out(Rsqrt7Table_x_out)
  );

  task automatic compare_outputs;
    begin
      checks = checks + 1;
      if ({FastArbiter_27_g_io_in_0_ready, FastArbiter_27_g_io_in_1_ready, FastArbiter_27_g_io_in_2_ready, FastArbiter_27_g_io_in_3_ready, FastArbiter_27_g_io_in_4_ready, FastArbiter_27_g_io_out_valid, FastArbiter_27_g_io_out_bits_qos, FastArbiter_27_g_io_out_bits_tgtID, FastArbiter_27_g_io_out_bits_txnID, FastArbiter_27_g_io_out_bits_homeNID, FastArbiter_27_g_io_out_bits_opcode, FastArbiter_27_g_io_out_bits_respErr, FastArbiter_27_g_io_out_bits_resp, FastArbiter_27_g_io_out_bits_dataSource, FastArbiter_27_g_io_out_bits_cBusy, FastArbiter_27_g_io_out_bits_dbID, FastArbiter_27_g_io_out_bits_ccID, FastArbiter_27_g_io_out_bits_dataID, FastArbiter_27_g_io_out_bits_tagOp, FastArbiter_27_g_io_out_bits_tag, FastArbiter_27_g_io_out_bits_tu, FastArbiter_27_g_io_out_bits_traceTag, FastArbiter_27_g_io_out_bits_rsvdc, FastArbiter_27_g_io_out_bits_be, FastArbiter_27_g_io_out_bits_data, FastArbiter_27_g_io_out_bits_dataCheck, FastArbiter_27_g_io_out_bits_poison} !== {FastArbiter_27_x_io_in_0_ready, FastArbiter_27_x_io_in_1_ready, FastArbiter_27_x_io_in_2_ready, FastArbiter_27_x_io_in_3_ready, FastArbiter_27_x_io_in_4_ready, FastArbiter_27_x_io_out_valid, FastArbiter_27_x_io_out_bits_qos, FastArbiter_27_x_io_out_bits_tgtID, FastArbiter_27_x_io_out_bits_txnID, FastArbiter_27_x_io_out_bits_homeNID, FastArbiter_27_x_io_out_bits_opcode, FastArbiter_27_x_io_out_bits_respErr, FastArbiter_27_x_io_out_bits_resp, FastArbiter_27_x_io_out_bits_dataSource, FastArbiter_27_x_io_out_bits_cBusy, FastArbiter_27_x_io_out_bits_dbID, FastArbiter_27_x_io_out_bits_ccID, FastArbiter_27_x_io_out_bits_dataID, FastArbiter_27_x_io_out_bits_tagOp, FastArbiter_27_x_io_out_bits_tag, FastArbiter_27_x_io_out_bits_tu, FastArbiter_27_x_io_out_bits_traceTag, FastArbiter_27_x_io_out_bits_rsvdc, FastArbiter_27_x_io_out_bits_be, FastArbiter_27_x_io_out_bits_data, FastArbiter_27_x_io_out_bits_dataCheck, FastArbiter_27_x_io_out_bits_poison}) begin
        errors = errors + 1;
        if (errors <= 8) $display("FastArbiter_27 mismatch at cycle %0d", cycle);
      end
      if ({FliDTable_g_out} !== {FliDTable_x_out}) begin
        errors = errors + 1;
        if (errors <= 8) $display("FliDTable mismatch at cycle %0d", cycle);
      end
      if ({FliHTable_g_out} !== {FliHTable_x_out}) begin
        errors = errors + 1;
        if (errors <= 8) $display("FliHTable mismatch at cycle %0d", cycle);
      end
      if ({FliSTable_g_out} !== {FliSTable_x_out}) begin
        errors = errors + 1;
        if (errors <= 8) $display("FliSTable mismatch at cycle %0d", cycle);
      end
      if ({IntBuffer_1_g_auto_out_0, IntBuffer_1_g_auto_out_1} !== {IntBuffer_1_x_auto_out_0, IntBuffer_1_x_auto_out_1}) begin
        errors = errors + 1;
        if (errors <= 8) $display("IntBuffer_1 mismatch at cycle %0d", cycle);
      end
      if ({IntBuffer_2_g_auto_out_1_0, IntBuffer_2_g_auto_out_0_0} !== {IntBuffer_2_x_auto_out_1_0, IntBuffer_2_x_auto_out_0_0}) begin
        errors = errors + 1;
        if (errors <= 8) $display("IntBuffer_2 mismatch at cycle %0d", cycle);
      end
      if ({Rec7Table_g_out} !== {Rec7Table_x_out}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Rec7Table mismatch at cycle %0d", cycle);
      end
      if ({Rsqrt7Table_g_out} !== {Rsqrt7Table_x_out}) begin
        errors = errors + 1;
        if (errors <= 8) $display("Rsqrt7Table mismatch at cycle %0d", cycle);
      end
    end
  endtask

  task automatic drive_inputs;
    begin
      FastArbiter_27_io_in_0_valid = $urandom;
      FastArbiter_27_io_in_0_bits_tgtID = $urandom;
      FastArbiter_27_io_in_0_bits_txnID = $urandom;
      FastArbiter_27_io_in_0_bits_homeNID = $urandom;
      FastArbiter_27_io_in_0_bits_opcode = $urandom;
      FastArbiter_27_io_in_0_bits_respErr = $urandom;
      FastArbiter_27_io_in_0_bits_resp = $urandom;
      FastArbiter_27_io_in_0_bits_dataSource = $urandom;
      FastArbiter_27_io_in_0_bits_dbID = $urandom;
      FastArbiter_27_io_in_0_bits_ccID = $urandom;
      FastArbiter_27_io_in_0_bits_dataID = $urandom;
      FastArbiter_27_io_in_0_bits_traceTag = $urandom;
      FastArbiter_27_io_in_0_bits_be = $urandom;
      FastArbiter_27_io_in_0_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      FastArbiter_27_io_in_0_bits_dataCheck = $urandom;
      FastArbiter_27_io_in_0_bits_poison = $urandom;
      FastArbiter_27_io_in_1_valid = $urandom;
      FastArbiter_27_io_in_1_bits_tgtID = $urandom;
      FastArbiter_27_io_in_1_bits_txnID = $urandom;
      FastArbiter_27_io_in_1_bits_homeNID = $urandom;
      FastArbiter_27_io_in_1_bits_opcode = $urandom;
      FastArbiter_27_io_in_1_bits_respErr = $urandom;
      FastArbiter_27_io_in_1_bits_resp = $urandom;
      FastArbiter_27_io_in_1_bits_dataSource = $urandom;
      FastArbiter_27_io_in_1_bits_dbID = $urandom;
      FastArbiter_27_io_in_1_bits_ccID = $urandom;
      FastArbiter_27_io_in_1_bits_dataID = $urandom;
      FastArbiter_27_io_in_1_bits_traceTag = $urandom;
      FastArbiter_27_io_in_1_bits_be = $urandom;
      FastArbiter_27_io_in_1_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      FastArbiter_27_io_in_1_bits_dataCheck = $urandom;
      FastArbiter_27_io_in_1_bits_poison = $urandom;
      FastArbiter_27_io_in_2_valid = $urandom;
      FastArbiter_27_io_in_2_bits_tgtID = $urandom;
      FastArbiter_27_io_in_2_bits_txnID = $urandom;
      FastArbiter_27_io_in_2_bits_homeNID = $urandom;
      FastArbiter_27_io_in_2_bits_opcode = $urandom;
      FastArbiter_27_io_in_2_bits_respErr = $urandom;
      FastArbiter_27_io_in_2_bits_resp = $urandom;
      FastArbiter_27_io_in_2_bits_dataSource = $urandom;
      FastArbiter_27_io_in_2_bits_dbID = $urandom;
      FastArbiter_27_io_in_2_bits_ccID = $urandom;
      FastArbiter_27_io_in_2_bits_dataID = $urandom;
      FastArbiter_27_io_in_2_bits_traceTag = $urandom;
      FastArbiter_27_io_in_2_bits_be = $urandom;
      FastArbiter_27_io_in_2_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      FastArbiter_27_io_in_2_bits_dataCheck = $urandom;
      FastArbiter_27_io_in_2_bits_poison = $urandom;
      FastArbiter_27_io_in_3_valid = $urandom;
      FastArbiter_27_io_in_3_bits_tgtID = $urandom;
      FastArbiter_27_io_in_3_bits_txnID = $urandom;
      FastArbiter_27_io_in_3_bits_homeNID = $urandom;
      FastArbiter_27_io_in_3_bits_opcode = $urandom;
      FastArbiter_27_io_in_3_bits_respErr = $urandom;
      FastArbiter_27_io_in_3_bits_resp = $urandom;
      FastArbiter_27_io_in_3_bits_dataSource = $urandom;
      FastArbiter_27_io_in_3_bits_dbID = $urandom;
      FastArbiter_27_io_in_3_bits_ccID = $urandom;
      FastArbiter_27_io_in_3_bits_dataID = $urandom;
      FastArbiter_27_io_in_3_bits_traceTag = $urandom;
      FastArbiter_27_io_in_3_bits_be = $urandom;
      FastArbiter_27_io_in_3_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      FastArbiter_27_io_in_3_bits_dataCheck = $urandom;
      FastArbiter_27_io_in_3_bits_poison = $urandom;
      FastArbiter_27_io_in_4_valid = $urandom;
      FastArbiter_27_io_in_4_bits_qos = $urandom;
      FastArbiter_27_io_in_4_bits_tgtID = $urandom;
      FastArbiter_27_io_in_4_bits_txnID = $urandom;
      FastArbiter_27_io_in_4_bits_homeNID = $urandom;
      FastArbiter_27_io_in_4_bits_opcode = $urandom;
      FastArbiter_27_io_in_4_bits_respErr = $urandom;
      FastArbiter_27_io_in_4_bits_resp = $urandom;
      FastArbiter_27_io_in_4_bits_dataSource = $urandom;
      FastArbiter_27_io_in_4_bits_cBusy = $urandom;
      FastArbiter_27_io_in_4_bits_dbID = $urandom;
      FastArbiter_27_io_in_4_bits_ccID = $urandom;
      FastArbiter_27_io_in_4_bits_dataID = $urandom;
      FastArbiter_27_io_in_4_bits_tagOp = $urandom;
      FastArbiter_27_io_in_4_bits_tag = $urandom;
      FastArbiter_27_io_in_4_bits_tu = $urandom;
      FastArbiter_27_io_in_4_bits_traceTag = $urandom;
      FastArbiter_27_io_in_4_bits_rsvdc = $urandom;
      FastArbiter_27_io_in_4_bits_be = $urandom;
      FastArbiter_27_io_in_4_bits_data = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      FastArbiter_27_io_in_4_bits_dataCheck = $urandom;
      FastArbiter_27_io_in_4_bits_poison = $urandom;
      FastArbiter_27_io_out_ready = $urandom;
      FliDTable_src = $urandom;
      FliHTable_src = $urandom;
      FliSTable_src = $urandom;
      IntBuffer_1_auto_in_0 = $urandom;
      IntBuffer_1_auto_in_1 = $urandom;
      IntBuffer_2_auto_in_1_0 = $urandom;
      IntBuffer_2_auto_in_0_0 = $urandom;
      Rec7Table_src = $urandom;
      Rsqrt7Table_src = $urandom;
    end
  endtask

  task automatic zero_inputs;
    begin
      FastArbiter_27_reset = '0;
      FastArbiter_27_io_in_0_valid = '0;
      FastArbiter_27_io_in_0_bits_tgtID = '0;
      FastArbiter_27_io_in_0_bits_txnID = '0;
      FastArbiter_27_io_in_0_bits_homeNID = '0;
      FastArbiter_27_io_in_0_bits_opcode = '0;
      FastArbiter_27_io_in_0_bits_respErr = '0;
      FastArbiter_27_io_in_0_bits_resp = '0;
      FastArbiter_27_io_in_0_bits_dataSource = '0;
      FastArbiter_27_io_in_0_bits_dbID = '0;
      FastArbiter_27_io_in_0_bits_ccID = '0;
      FastArbiter_27_io_in_0_bits_dataID = '0;
      FastArbiter_27_io_in_0_bits_traceTag = '0;
      FastArbiter_27_io_in_0_bits_be = '0;
      FastArbiter_27_io_in_0_bits_data = '0;
      FastArbiter_27_io_in_0_bits_dataCheck = '0;
      FastArbiter_27_io_in_0_bits_poison = '0;
      FastArbiter_27_io_in_1_valid = '0;
      FastArbiter_27_io_in_1_bits_tgtID = '0;
      FastArbiter_27_io_in_1_bits_txnID = '0;
      FastArbiter_27_io_in_1_bits_homeNID = '0;
      FastArbiter_27_io_in_1_bits_opcode = '0;
      FastArbiter_27_io_in_1_bits_respErr = '0;
      FastArbiter_27_io_in_1_bits_resp = '0;
      FastArbiter_27_io_in_1_bits_dataSource = '0;
      FastArbiter_27_io_in_1_bits_dbID = '0;
      FastArbiter_27_io_in_1_bits_ccID = '0;
      FastArbiter_27_io_in_1_bits_dataID = '0;
      FastArbiter_27_io_in_1_bits_traceTag = '0;
      FastArbiter_27_io_in_1_bits_be = '0;
      FastArbiter_27_io_in_1_bits_data = '0;
      FastArbiter_27_io_in_1_bits_dataCheck = '0;
      FastArbiter_27_io_in_1_bits_poison = '0;
      FastArbiter_27_io_in_2_valid = '0;
      FastArbiter_27_io_in_2_bits_tgtID = '0;
      FastArbiter_27_io_in_2_bits_txnID = '0;
      FastArbiter_27_io_in_2_bits_homeNID = '0;
      FastArbiter_27_io_in_2_bits_opcode = '0;
      FastArbiter_27_io_in_2_bits_respErr = '0;
      FastArbiter_27_io_in_2_bits_resp = '0;
      FastArbiter_27_io_in_2_bits_dataSource = '0;
      FastArbiter_27_io_in_2_bits_dbID = '0;
      FastArbiter_27_io_in_2_bits_ccID = '0;
      FastArbiter_27_io_in_2_bits_dataID = '0;
      FastArbiter_27_io_in_2_bits_traceTag = '0;
      FastArbiter_27_io_in_2_bits_be = '0;
      FastArbiter_27_io_in_2_bits_data = '0;
      FastArbiter_27_io_in_2_bits_dataCheck = '0;
      FastArbiter_27_io_in_2_bits_poison = '0;
      FastArbiter_27_io_in_3_valid = '0;
      FastArbiter_27_io_in_3_bits_tgtID = '0;
      FastArbiter_27_io_in_3_bits_txnID = '0;
      FastArbiter_27_io_in_3_bits_homeNID = '0;
      FastArbiter_27_io_in_3_bits_opcode = '0;
      FastArbiter_27_io_in_3_bits_respErr = '0;
      FastArbiter_27_io_in_3_bits_resp = '0;
      FastArbiter_27_io_in_3_bits_dataSource = '0;
      FastArbiter_27_io_in_3_bits_dbID = '0;
      FastArbiter_27_io_in_3_bits_ccID = '0;
      FastArbiter_27_io_in_3_bits_dataID = '0;
      FastArbiter_27_io_in_3_bits_traceTag = '0;
      FastArbiter_27_io_in_3_bits_be = '0;
      FastArbiter_27_io_in_3_bits_data = '0;
      FastArbiter_27_io_in_3_bits_dataCheck = '0;
      FastArbiter_27_io_in_3_bits_poison = '0;
      FastArbiter_27_io_in_4_valid = '0;
      FastArbiter_27_io_in_4_bits_qos = '0;
      FastArbiter_27_io_in_4_bits_tgtID = '0;
      FastArbiter_27_io_in_4_bits_txnID = '0;
      FastArbiter_27_io_in_4_bits_homeNID = '0;
      FastArbiter_27_io_in_4_bits_opcode = '0;
      FastArbiter_27_io_in_4_bits_respErr = '0;
      FastArbiter_27_io_in_4_bits_resp = '0;
      FastArbiter_27_io_in_4_bits_dataSource = '0;
      FastArbiter_27_io_in_4_bits_cBusy = '0;
      FastArbiter_27_io_in_4_bits_dbID = '0;
      FastArbiter_27_io_in_4_bits_ccID = '0;
      FastArbiter_27_io_in_4_bits_dataID = '0;
      FastArbiter_27_io_in_4_bits_tagOp = '0;
      FastArbiter_27_io_in_4_bits_tag = '0;
      FastArbiter_27_io_in_4_bits_tu = '0;
      FastArbiter_27_io_in_4_bits_traceTag = '0;
      FastArbiter_27_io_in_4_bits_rsvdc = '0;
      FastArbiter_27_io_in_4_bits_be = '0;
      FastArbiter_27_io_in_4_bits_data = '0;
      FastArbiter_27_io_in_4_bits_dataCheck = '0;
      FastArbiter_27_io_in_4_bits_poison = '0;
      FastArbiter_27_io_out_ready = '0;
      FliDTable_src = '0;
      FliHTable_src = '0;
      FliSTable_src = '0;
      IntBuffer_1_reset = '0;
      IntBuffer_1_auto_in_0 = '0;
      IntBuffer_1_auto_in_1 = '0;
      IntBuffer_2_reset = '0;
      IntBuffer_2_auto_in_1_0 = '0;
      IntBuffer_2_auto_in_0_0 = '0;
      Rec7Table_src = '0;
      Rsqrt7Table_src = '0;
    end
  endtask

  task automatic sample_coverage;
    logic [4:0] v;
    logic [4:0] r;
    begin
      v = {FastArbiter_27_io_in_4_valid, FastArbiter_27_io_in_3_valid, FastArbiter_27_io_in_2_valid,
           FastArbiter_27_io_in_1_valid, FastArbiter_27_io_in_0_valid};
      r = {g_FastArbiter_27.io_in_4_ready, g_FastArbiter_27.io_in_3_ready, g_FastArbiter_27.io_in_2_ready,
           g_FastArbiter_27.io_in_1_ready, g_FastArbiter_27.io_in_0_ready};
      // winner is not the lowest valid lane -> the pending/round-robin path decided
      if (!FastArbiter_27_reset && FastArbiter_27_io_out_ready && (r & v) != 0 && (r & v) != (v & (~v + 5'd1)))
        cov_fa_rr_override = cov_fa_rr_override + 1;
      if (!FastArbiter_27_reset && g_FastArbiter_27.io_out_valid && !FastArbiter_27_io_out_ready)
        cov_fa_stall = cov_fa_stall + 1;
      if (!FastArbiter_27_reset && r[4] && v[4])
        cov_fa_lane4 = cov_fa_lane4 + 1;
      if (!IntBuffer_1_reset && (IntBuffer_1_auto_in_0 != g_IntBuffer_1.auto_out_0))
        cov_irq_toggle = cov_irq_toggle + 1;
    end
  endtask

  initial begin
    zero_inputs();
    FastArbiter_27_reset = 1'b1;
    IntBuffer_1_reset = 1'b1;
    IntBuffer_2_reset = 1'b1;
    repeat (2) @(posedge clock);
    #1;
    FastArbiter_27_reset = 1'b0;
    IntBuffer_1_reset = 1'b0;
    IntBuffer_2_reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      cycle = cycle + 1;
      drive_inputs();
      if (rst_left > 0)
        rst_left = rst_left - 1;
      else if ($urandom % 512 == 0) begin
        rst_left = 1 + $urandom % 3;
        cov_rst_pulses = cov_rst_pulses + 1;
      end
      FastArbiter_27_reset = (rst_left > 0);
      IntBuffer_1_reset = (rst_left > 0);
      IntBuffer_2_reset = (rst_left > 0);
      #1;
      sample_coverage();
      // mid-cycle compare: an async reset raised at this negedge must already have cleared state
      compare_outputs();
      @(posedge clock);
      #1;
      compare_outputs();
    end
    $display("COVERAGE rst_pulses=%0d fa_rr_override=%0d fa_stall=%0d fa_lane4=%0d irq_toggle=%0d",
             cov_rst_pulses, cov_fa_rr_override, cov_fa_stall, cov_fa_lane4, cov_irq_toggle);
    if (cov_rst_pulses == 0 || cov_fa_rr_override == 0 || cov_fa_stall == 0 || cov_fa_lane4 == 0 || cov_irq_toggle == 0) begin
      $display("COVERAGE HOLE: at least one counter is zero");
      errors = errors + 1;
    end
    $display("Arithmetic200c UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
