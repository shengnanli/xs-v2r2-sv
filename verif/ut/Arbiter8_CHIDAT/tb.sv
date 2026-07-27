// 自动生成: scripts/gen_arbiter8.py —— 勿手改
// Arbiter8_CHIDAT 双例化逐拍比对: golden Arbiter8_CHIDAT vs 可读 Arbiter8_CHIDAT_xs (随机激励).
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
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
  logic io_in_0_valid;
  logic [10:0] io_in_0_bits_tgtID;
  logic [11:0] io_in_0_bits_txnID;
  logic [1:0] io_in_0_bits_respErr;
  logic [1:0] io_in_0_bits_ccID;
  logic [1:0] io_in_0_bits_dataID;
  logic io_in_0_bits_traceTag;
  logic [31:0] io_in_0_bits_be;
  logic [255:0] io_in_0_bits_data;
  logic [31:0] io_in_0_bits_dataCheck;
  logic [3:0] io_in_0_bits_poison;
  logic io_in_1_valid;
  logic [10:0] io_in_1_bits_tgtID;
  logic [11:0] io_in_1_bits_txnID;
  logic [1:0] io_in_1_bits_respErr;
  logic [1:0] io_in_1_bits_ccID;
  logic [1:0] io_in_1_bits_dataID;
  logic io_in_1_bits_traceTag;
  logic [31:0] io_in_1_bits_be;
  logic [255:0] io_in_1_bits_data;
  logic [31:0] io_in_1_bits_dataCheck;
  logic [3:0] io_in_1_bits_poison;
  logic io_in_2_valid;
  logic [10:0] io_in_2_bits_tgtID;
  logic [11:0] io_in_2_bits_txnID;
  logic [1:0] io_in_2_bits_respErr;
  logic [1:0] io_in_2_bits_ccID;
  logic [1:0] io_in_2_bits_dataID;
  logic io_in_2_bits_traceTag;
  logic [31:0] io_in_2_bits_be;
  logic [255:0] io_in_2_bits_data;
  logic [31:0] io_in_2_bits_dataCheck;
  logic [3:0] io_in_2_bits_poison;
  logic io_in_3_valid;
  logic [10:0] io_in_3_bits_tgtID;
  logic [11:0] io_in_3_bits_txnID;
  logic [1:0] io_in_3_bits_respErr;
  logic [1:0] io_in_3_bits_ccID;
  logic [1:0] io_in_3_bits_dataID;
  logic io_in_3_bits_traceTag;
  logic [31:0] io_in_3_bits_be;
  logic [255:0] io_in_3_bits_data;
  logic [31:0] io_in_3_bits_dataCheck;
  logic [3:0] io_in_3_bits_poison;
  logic io_in_4_valid;
  logic [10:0] io_in_4_bits_tgtID;
  logic [11:0] io_in_4_bits_txnID;
  logic [1:0] io_in_4_bits_respErr;
  logic [1:0] io_in_4_bits_ccID;
  logic [1:0] io_in_4_bits_dataID;
  logic io_in_4_bits_traceTag;
  logic [31:0] io_in_4_bits_be;
  logic [255:0] io_in_4_bits_data;
  logic [31:0] io_in_4_bits_dataCheck;
  logic [3:0] io_in_4_bits_poison;
  logic io_in_5_valid;
  logic [10:0] io_in_5_bits_tgtID;
  logic [11:0] io_in_5_bits_txnID;
  logic [1:0] io_in_5_bits_respErr;
  logic [1:0] io_in_5_bits_ccID;
  logic [1:0] io_in_5_bits_dataID;
  logic io_in_5_bits_traceTag;
  logic [31:0] io_in_5_bits_be;
  logic [255:0] io_in_5_bits_data;
  logic [31:0] io_in_5_bits_dataCheck;
  logic [3:0] io_in_5_bits_poison;
  logic io_in_6_valid;
  logic [10:0] io_in_6_bits_tgtID;
  logic [11:0] io_in_6_bits_txnID;
  logic [1:0] io_in_6_bits_respErr;
  logic [1:0] io_in_6_bits_ccID;
  logic [1:0] io_in_6_bits_dataID;
  logic io_in_6_bits_traceTag;
  logic [31:0] io_in_6_bits_be;
  logic [255:0] io_in_6_bits_data;
  logic [31:0] io_in_6_bits_dataCheck;
  logic [3:0] io_in_6_bits_poison;
  logic io_in_7_valid;
  logic [10:0] io_in_7_bits_tgtID;
  logic [11:0] io_in_7_bits_txnID;
  logic [1:0] io_in_7_bits_respErr;
  logic [1:0] io_in_7_bits_ccID;
  logic [1:0] io_in_7_bits_dataID;
  logic io_in_7_bits_traceTag;
  logic [31:0] io_in_7_bits_be;
  logic [255:0] io_in_7_bits_data;
  logic [31:0] io_in_7_bits_dataCheck;
  logic [3:0] io_in_7_bits_poison;
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
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [10:0] g_io_out_bits_tgtID;
  wire [10:0] i_io_out_bits_tgtID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [1:0] g_io_out_bits_respErr;
  wire [1:0] i_io_out_bits_respErr;
  wire [1:0] g_io_out_bits_ccID;
  wire [1:0] i_io_out_bits_ccID;
  wire [1:0] g_io_out_bits_dataID;
  wire [1:0] i_io_out_bits_dataID;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire [31:0] g_io_out_bits_be;
  wire [31:0] i_io_out_bits_be;
  wire [255:0] g_io_out_bits_data;
  wire [255:0] i_io_out_bits_data;
  wire [31:0] g_io_out_bits_dataCheck;
  wire [31:0] i_io_out_bits_dataCheck;
  wire [3:0] g_io_out_bits_poison;
  wire [3:0] i_io_out_bits_poison;
  Arbiter8_CHIDAT u_g (
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_ccID(io_in_0_bits_ccID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(io_in_0_bits_poison),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_respErr(io_in_1_bits_respErr),
    .io_in_1_bits_ccID(io_in_1_bits_ccID),
    .io_in_1_bits_dataID(io_in_1_bits_dataID),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_be(io_in_1_bits_be),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_dataCheck(io_in_1_bits_dataCheck),
    .io_in_1_bits_poison(io_in_1_bits_poison),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_respErr(io_in_2_bits_respErr),
    .io_in_2_bits_ccID(io_in_2_bits_ccID),
    .io_in_2_bits_dataID(io_in_2_bits_dataID),
    .io_in_2_bits_traceTag(io_in_2_bits_traceTag),
    .io_in_2_bits_be(io_in_2_bits_be),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_dataCheck(io_in_2_bits_dataCheck),
    .io_in_2_bits_poison(io_in_2_bits_poison),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_respErr(io_in_3_bits_respErr),
    .io_in_3_bits_ccID(io_in_3_bits_ccID),
    .io_in_3_bits_dataID(io_in_3_bits_dataID),
    .io_in_3_bits_traceTag(io_in_3_bits_traceTag),
    .io_in_3_bits_be(io_in_3_bits_be),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_dataCheck(io_in_3_bits_dataCheck),
    .io_in_3_bits_poison(io_in_3_bits_poison),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_respErr(io_in_4_bits_respErr),
    .io_in_4_bits_ccID(io_in_4_bits_ccID),
    .io_in_4_bits_dataID(io_in_4_bits_dataID),
    .io_in_4_bits_traceTag(io_in_4_bits_traceTag),
    .io_in_4_bits_be(io_in_4_bits_be),
    .io_in_4_bits_data(io_in_4_bits_data),
    .io_in_4_bits_dataCheck(io_in_4_bits_dataCheck),
    .io_in_4_bits_poison(io_in_4_bits_poison),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_respErr(io_in_5_bits_respErr),
    .io_in_5_bits_ccID(io_in_5_bits_ccID),
    .io_in_5_bits_dataID(io_in_5_bits_dataID),
    .io_in_5_bits_traceTag(io_in_5_bits_traceTag),
    .io_in_5_bits_be(io_in_5_bits_be),
    .io_in_5_bits_data(io_in_5_bits_data),
    .io_in_5_bits_dataCheck(io_in_5_bits_dataCheck),
    .io_in_5_bits_poison(io_in_5_bits_poison),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_respErr(io_in_6_bits_respErr),
    .io_in_6_bits_ccID(io_in_6_bits_ccID),
    .io_in_6_bits_dataID(io_in_6_bits_dataID),
    .io_in_6_bits_traceTag(io_in_6_bits_traceTag),
    .io_in_6_bits_be(io_in_6_bits_be),
    .io_in_6_bits_data(io_in_6_bits_data),
    .io_in_6_bits_dataCheck(io_in_6_bits_dataCheck),
    .io_in_6_bits_poison(io_in_6_bits_poison),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_respErr(io_in_7_bits_respErr),
    .io_in_7_bits_ccID(io_in_7_bits_ccID),
    .io_in_7_bits_dataID(io_in_7_bits_dataID),
    .io_in_7_bits_traceTag(io_in_7_bits_traceTag),
    .io_in_7_bits_be(io_in_7_bits_be),
    .io_in_7_bits_data(io_in_7_bits_data),
    .io_in_7_bits_dataCheck(io_in_7_bits_dataCheck),
    .io_in_7_bits_poison(io_in_7_bits_poison),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_respErr(g_io_out_bits_respErr),
    .io_out_bits_ccID(g_io_out_bits_ccID),
    .io_out_bits_dataID(g_io_out_bits_dataID),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_be(g_io_out_bits_be),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_dataCheck(g_io_out_bits_dataCheck),
    .io_out_bits_poison(g_io_out_bits_poison)
  );
  Arbiter8_CHIDAT_xs u_i (
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_ccID(io_in_0_bits_ccID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(io_in_0_bits_poison),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_tgtID(io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(io_in_1_bits_txnID),
    .io_in_1_bits_respErr(io_in_1_bits_respErr),
    .io_in_1_bits_ccID(io_in_1_bits_ccID),
    .io_in_1_bits_dataID(io_in_1_bits_dataID),
    .io_in_1_bits_traceTag(io_in_1_bits_traceTag),
    .io_in_1_bits_be(io_in_1_bits_be),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_dataCheck(io_in_1_bits_dataCheck),
    .io_in_1_bits_poison(io_in_1_bits_poison),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_tgtID(io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(io_in_2_bits_txnID),
    .io_in_2_bits_respErr(io_in_2_bits_respErr),
    .io_in_2_bits_ccID(io_in_2_bits_ccID),
    .io_in_2_bits_dataID(io_in_2_bits_dataID),
    .io_in_2_bits_traceTag(io_in_2_bits_traceTag),
    .io_in_2_bits_be(io_in_2_bits_be),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_dataCheck(io_in_2_bits_dataCheck),
    .io_in_2_bits_poison(io_in_2_bits_poison),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_tgtID(io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(io_in_3_bits_txnID),
    .io_in_3_bits_respErr(io_in_3_bits_respErr),
    .io_in_3_bits_ccID(io_in_3_bits_ccID),
    .io_in_3_bits_dataID(io_in_3_bits_dataID),
    .io_in_3_bits_traceTag(io_in_3_bits_traceTag),
    .io_in_3_bits_be(io_in_3_bits_be),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_dataCheck(io_in_3_bits_dataCheck),
    .io_in_3_bits_poison(io_in_3_bits_poison),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_tgtID(io_in_4_bits_tgtID),
    .io_in_4_bits_txnID(io_in_4_bits_txnID),
    .io_in_4_bits_respErr(io_in_4_bits_respErr),
    .io_in_4_bits_ccID(io_in_4_bits_ccID),
    .io_in_4_bits_dataID(io_in_4_bits_dataID),
    .io_in_4_bits_traceTag(io_in_4_bits_traceTag),
    .io_in_4_bits_be(io_in_4_bits_be),
    .io_in_4_bits_data(io_in_4_bits_data),
    .io_in_4_bits_dataCheck(io_in_4_bits_dataCheck),
    .io_in_4_bits_poison(io_in_4_bits_poison),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_tgtID(io_in_5_bits_tgtID),
    .io_in_5_bits_txnID(io_in_5_bits_txnID),
    .io_in_5_bits_respErr(io_in_5_bits_respErr),
    .io_in_5_bits_ccID(io_in_5_bits_ccID),
    .io_in_5_bits_dataID(io_in_5_bits_dataID),
    .io_in_5_bits_traceTag(io_in_5_bits_traceTag),
    .io_in_5_bits_be(io_in_5_bits_be),
    .io_in_5_bits_data(io_in_5_bits_data),
    .io_in_5_bits_dataCheck(io_in_5_bits_dataCheck),
    .io_in_5_bits_poison(io_in_5_bits_poison),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_tgtID(io_in_6_bits_tgtID),
    .io_in_6_bits_txnID(io_in_6_bits_txnID),
    .io_in_6_bits_respErr(io_in_6_bits_respErr),
    .io_in_6_bits_ccID(io_in_6_bits_ccID),
    .io_in_6_bits_dataID(io_in_6_bits_dataID),
    .io_in_6_bits_traceTag(io_in_6_bits_traceTag),
    .io_in_6_bits_be(io_in_6_bits_be),
    .io_in_6_bits_data(io_in_6_bits_data),
    .io_in_6_bits_dataCheck(io_in_6_bits_dataCheck),
    .io_in_6_bits_poison(io_in_6_bits_poison),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_tgtID(io_in_7_bits_tgtID),
    .io_in_7_bits_txnID(io_in_7_bits_txnID),
    .io_in_7_bits_respErr(io_in_7_bits_respErr),
    .io_in_7_bits_ccID(io_in_7_bits_ccID),
    .io_in_7_bits_dataID(io_in_7_bits_dataID),
    .io_in_7_bits_traceTag(io_in_7_bits_traceTag),
    .io_in_7_bits_be(io_in_7_bits_be),
    .io_in_7_bits_data(io_in_7_bits_data),
    .io_in_7_bits_dataCheck(io_in_7_bits_dataCheck),
    .io_in_7_bits_poison(io_in_7_bits_poison),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_respErr(i_io_out_bits_respErr),
    .io_out_bits_ccID(i_io_out_bits_ccID),
    .io_out_bits_dataID(i_io_out_bits_dataID),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_be(i_io_out_bits_be),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_dataCheck(i_io_out_bits_dataCheck),
    .io_out_bits_poison(i_io_out_bits_poison)
  );
  task automatic drive_random_inputs();
    io_in_0_valid = $urandom_range(0, 1);
    io_in_0_bits_tgtID = 11'($urandom);
    io_in_0_bits_txnID = 12'($urandom);
    io_in_0_bits_respErr = 2'($urandom);
    io_in_0_bits_ccID = 2'($urandom);
    io_in_0_bits_dataID = 2'($urandom);
    io_in_0_bits_traceTag = $urandom_range(0, 1);
    io_in_0_bits_be = 32'($urandom);
    io_in_0_bits_data = 256'($urandom);
    io_in_0_bits_dataCheck = 32'($urandom);
    io_in_0_bits_poison = 4'($urandom);
    io_in_1_valid = $urandom_range(0, 1);
    io_in_1_bits_tgtID = 11'($urandom);
    io_in_1_bits_txnID = 12'($urandom);
    io_in_1_bits_respErr = 2'($urandom);
    io_in_1_bits_ccID = 2'($urandom);
    io_in_1_bits_dataID = 2'($urandom);
    io_in_1_bits_traceTag = $urandom_range(0, 1);
    io_in_1_bits_be = 32'($urandom);
    io_in_1_bits_data = 256'($urandom);
    io_in_1_bits_dataCheck = 32'($urandom);
    io_in_1_bits_poison = 4'($urandom);
    io_in_2_valid = $urandom_range(0, 1);
    io_in_2_bits_tgtID = 11'($urandom);
    io_in_2_bits_txnID = 12'($urandom);
    io_in_2_bits_respErr = 2'($urandom);
    io_in_2_bits_ccID = 2'($urandom);
    io_in_2_bits_dataID = 2'($urandom);
    io_in_2_bits_traceTag = $urandom_range(0, 1);
    io_in_2_bits_be = 32'($urandom);
    io_in_2_bits_data = 256'($urandom);
    io_in_2_bits_dataCheck = 32'($urandom);
    io_in_2_bits_poison = 4'($urandom);
    io_in_3_valid = $urandom_range(0, 1);
    io_in_3_bits_tgtID = 11'($urandom);
    io_in_3_bits_txnID = 12'($urandom);
    io_in_3_bits_respErr = 2'($urandom);
    io_in_3_bits_ccID = 2'($urandom);
    io_in_3_bits_dataID = 2'($urandom);
    io_in_3_bits_traceTag = $urandom_range(0, 1);
    io_in_3_bits_be = 32'($urandom);
    io_in_3_bits_data = 256'($urandom);
    io_in_3_bits_dataCheck = 32'($urandom);
    io_in_3_bits_poison = 4'($urandom);
    io_in_4_valid = $urandom_range(0, 1);
    io_in_4_bits_tgtID = 11'($urandom);
    io_in_4_bits_txnID = 12'($urandom);
    io_in_4_bits_respErr = 2'($urandom);
    io_in_4_bits_ccID = 2'($urandom);
    io_in_4_bits_dataID = 2'($urandom);
    io_in_4_bits_traceTag = $urandom_range(0, 1);
    io_in_4_bits_be = 32'($urandom);
    io_in_4_bits_data = 256'($urandom);
    io_in_4_bits_dataCheck = 32'($urandom);
    io_in_4_bits_poison = 4'($urandom);
    io_in_5_valid = $urandom_range(0, 1);
    io_in_5_bits_tgtID = 11'($urandom);
    io_in_5_bits_txnID = 12'($urandom);
    io_in_5_bits_respErr = 2'($urandom);
    io_in_5_bits_ccID = 2'($urandom);
    io_in_5_bits_dataID = 2'($urandom);
    io_in_5_bits_traceTag = $urandom_range(0, 1);
    io_in_5_bits_be = 32'($urandom);
    io_in_5_bits_data = 256'($urandom);
    io_in_5_bits_dataCheck = 32'($urandom);
    io_in_5_bits_poison = 4'($urandom);
    io_in_6_valid = $urandom_range(0, 1);
    io_in_6_bits_tgtID = 11'($urandom);
    io_in_6_bits_txnID = 12'($urandom);
    io_in_6_bits_respErr = 2'($urandom);
    io_in_6_bits_ccID = 2'($urandom);
    io_in_6_bits_dataID = 2'($urandom);
    io_in_6_bits_traceTag = $urandom_range(0, 1);
    io_in_6_bits_be = 32'($urandom);
    io_in_6_bits_data = 256'($urandom);
    io_in_6_bits_dataCheck = 32'($urandom);
    io_in_6_bits_poison = 4'($urandom);
    io_in_7_valid = $urandom_range(0, 1);
    io_in_7_bits_tgtID = 11'($urandom);
    io_in_7_bits_txnID = 12'($urandom);
    io_in_7_bits_respErr = 2'($urandom);
    io_in_7_bits_ccID = 2'($urandom);
    io_in_7_bits_dataID = 2'($urandom);
    io_in_7_bits_traceTag = $urandom_range(0, 1);
    io_in_7_bits_be = 32'($urandom);
    io_in_7_bits_data = 256'($urandom);
    io_in_7_bits_dataCheck = 32'($urandom);
    io_in_7_bits_poison = 4'($urandom);
    io_out_ready = $urandom_range(0, 1);
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
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_tgtID)
    `CHECK(io_out_bits_txnID)
    `CHECK(io_out_bits_respErr)
    `CHECK(io_out_bits_ccID)
    `CHECK(io_out_bits_dataID)
    `CHECK(io_out_bits_traceTag)
    `CHECK(io_out_bits_be)
    `CHECK(io_out_bits_data)
    `CHECK(io_out_bits_dataCheck)
    `CHECK(io_out_bits_poison)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    io_in_0_valid = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_respErr = '0;
    io_in_0_bits_ccID = '0;
    io_in_0_bits_dataID = '0;
    io_in_0_bits_traceTag = '0;
    io_in_0_bits_be = '0;
    io_in_0_bits_data = '0;
    io_in_0_bits_dataCheck = '0;
    io_in_0_bits_poison = '0;
    io_in_1_valid = '0;
    io_in_1_bits_tgtID = '0;
    io_in_1_bits_txnID = '0;
    io_in_1_bits_respErr = '0;
    io_in_1_bits_ccID = '0;
    io_in_1_bits_dataID = '0;
    io_in_1_bits_traceTag = '0;
    io_in_1_bits_be = '0;
    io_in_1_bits_data = '0;
    io_in_1_bits_dataCheck = '0;
    io_in_1_bits_poison = '0;
    io_in_2_valid = '0;
    io_in_2_bits_tgtID = '0;
    io_in_2_bits_txnID = '0;
    io_in_2_bits_respErr = '0;
    io_in_2_bits_ccID = '0;
    io_in_2_bits_dataID = '0;
    io_in_2_bits_traceTag = '0;
    io_in_2_bits_be = '0;
    io_in_2_bits_data = '0;
    io_in_2_bits_dataCheck = '0;
    io_in_2_bits_poison = '0;
    io_in_3_valid = '0;
    io_in_3_bits_tgtID = '0;
    io_in_3_bits_txnID = '0;
    io_in_3_bits_respErr = '0;
    io_in_3_bits_ccID = '0;
    io_in_3_bits_dataID = '0;
    io_in_3_bits_traceTag = '0;
    io_in_3_bits_be = '0;
    io_in_3_bits_data = '0;
    io_in_3_bits_dataCheck = '0;
    io_in_3_bits_poison = '0;
    io_in_4_valid = '0;
    io_in_4_bits_tgtID = '0;
    io_in_4_bits_txnID = '0;
    io_in_4_bits_respErr = '0;
    io_in_4_bits_ccID = '0;
    io_in_4_bits_dataID = '0;
    io_in_4_bits_traceTag = '0;
    io_in_4_bits_be = '0;
    io_in_4_bits_data = '0;
    io_in_4_bits_dataCheck = '0;
    io_in_4_bits_poison = '0;
    io_in_5_valid = '0;
    io_in_5_bits_tgtID = '0;
    io_in_5_bits_txnID = '0;
    io_in_5_bits_respErr = '0;
    io_in_5_bits_ccID = '0;
    io_in_5_bits_dataID = '0;
    io_in_5_bits_traceTag = '0;
    io_in_5_bits_be = '0;
    io_in_5_bits_data = '0;
    io_in_5_bits_dataCheck = '0;
    io_in_5_bits_poison = '0;
    io_in_6_valid = '0;
    io_in_6_bits_tgtID = '0;
    io_in_6_bits_txnID = '0;
    io_in_6_bits_respErr = '0;
    io_in_6_bits_ccID = '0;
    io_in_6_bits_dataID = '0;
    io_in_6_bits_traceTag = '0;
    io_in_6_bits_be = '0;
    io_in_6_bits_data = '0;
    io_in_6_bits_dataCheck = '0;
    io_in_6_bits_poison = '0;
    io_in_7_valid = '0;
    io_in_7_bits_tgtID = '0;
    io_in_7_bits_txnID = '0;
    io_in_7_bits_respErr = '0;
    io_in_7_bits_ccID = '0;
    io_in_7_bits_dataID = '0;
    io_in_7_bits_traceTag = '0;
    io_in_7_bits_be = '0;
    io_in_7_bits_data = '0;
    io_in_7_bits_dataCheck = '0;
    io_in_7_bits_poison = '0;
    io_out_ready = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("Arbiter8_CHIDAT checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
