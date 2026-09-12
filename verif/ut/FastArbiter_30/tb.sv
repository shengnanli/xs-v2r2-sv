// 自动生成：scripts/gen_zj_ut.py FastArbiter_30 —— 勿手改
// FastArbiter_30 双例化逐拍比对：golden FastArbiter_30 vs 重写 FastArbiter_30_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  localparam int unsigned NCYCLES     = 120000;
  localparam int unsigned MIN_TOGGLED = 23;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 23;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_in_0_valid;
  logic [3:0] io_in_0_bits_qos;
  logic [10:0] io_in_0_bits_tgtID;
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [10:0] io_in_0_bits_homeNID;
  logic [3:0] io_in_0_bits_opcode;
  logic [1:0] io_in_0_bits_respErr;
  logic [2:0] io_in_0_bits_resp;
  logic [3:0] io_in_0_bits_dataSource;
  logic [2:0] io_in_0_bits_cBusy;
  logic [11:0] io_in_0_bits_dbID;
  logic [1:0] io_in_0_bits_ccID;
  logic [1:0] io_in_0_bits_dataID;
  logic [1:0] io_in_0_bits_tagOp;
  logic [7:0] io_in_0_bits_tag;
  logic [1:0] io_in_0_bits_tu;
  logic io_in_0_bits_traceTag;
  logic [3:0] io_in_0_bits_rsvdc;
  logic [31:0] io_in_0_bits_be;
  logic [255:0] io_in_0_bits_data;
  logic [31:0] io_in_0_bits_dataCheck;
  logic [3:0] io_in_0_bits_poison;

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
  wire [10:0] g_io_out_bits_homeNID;
  wire [10:0] i_io_out_bits_homeNID;
  wire [3:0] g_io_out_bits_opcode;
  wire [3:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_respErr;
  wire [1:0] i_io_out_bits_respErr;
  wire [2:0] g_io_out_bits_resp;
  wire [2:0] i_io_out_bits_resp;
  wire [3:0] g_io_out_bits_dataSource;
  wire [3:0] i_io_out_bits_dataSource;
  wire [2:0] g_io_out_bits_cBusy;
  wire [2:0] i_io_out_bits_cBusy;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;
  wire [1:0] g_io_out_bits_ccID;
  wire [1:0] i_io_out_bits_ccID;
  wire [1:0] g_io_out_bits_dataID;
  wire [1:0] i_io_out_bits_dataID;
  wire [1:0] g_io_out_bits_tagOp;
  wire [1:0] i_io_out_bits_tagOp;
  wire [7:0] g_io_out_bits_tag;
  wire [7:0] i_io_out_bits_tag;
  wire [1:0] g_io_out_bits_tu;
  wire [1:0] i_io_out_bits_tu;
  wire g_io_out_bits_traceTag;
  wire i_io_out_bits_traceTag;
  wire [3:0] g_io_out_bits_rsvdc;
  wire [3:0] i_io_out_bits_rsvdc;
  wire [31:0] g_io_out_bits_be;
  wire [31:0] i_io_out_bits_be;
  wire [255:0] g_io_out_bits_data;
  wire [255:0] i_io_out_bits_data;
  wire [31:0] g_io_out_bits_dataCheck;
  wire [31:0] i_io_out_bits_dataCheck;
  wire [3:0] g_io_out_bits_poison;
  wire [3:0] i_io_out_bits_poison;

  logic p_io_out_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_valid;
  logic [3:0] p_io_out_bits_qos;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_qos;
  logic [10:0] p_io_out_bits_tgtID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_tgtID;
  logic [10:0] p_io_out_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_srcID;
  logic [11:0] p_io_out_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_txnID;
  logic [10:0] p_io_out_bits_homeNID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_homeNID;
  logic [3:0] p_io_out_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_opcode;
  logic [1:0] p_io_out_bits_respErr;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_respErr;
  logic [2:0] p_io_out_bits_resp;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_resp;
  logic [3:0] p_io_out_bits_dataSource;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_dataSource;
  logic [2:0] p_io_out_bits_cBusy;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_cBusy;
  logic [11:0] p_io_out_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_dbID;
  logic [1:0] p_io_out_bits_ccID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_ccID;
  logic [1:0] p_io_out_bits_dataID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_dataID;
  logic [1:0] p_io_out_bits_tagOp;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_tagOp;
  logic [7:0] p_io_out_bits_tag;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_tag;
  logic [1:0] p_io_out_bits_tu;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_tu;
  logic p_io_out_bits_traceTag;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_traceTag;
  logic [3:0] p_io_out_bits_rsvdc;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_rsvdc;
  logic [31:0] p_io_out_bits_be;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_be;
  logic [255:0] p_io_out_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_data;
  logic [31:0] p_io_out_bits_dataCheck;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_dataCheck;
  logic [3:0] p_io_out_bits_poison;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_poison;

  FastArbiter_30 u_g (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_dataSource(io_in_0_bits_dataSource),
    .io_in_0_bits_cBusy(io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_ccID(io_in_0_bits_ccID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_tu(io_in_0_bits_tu),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_rsvdc(io_in_0_bits_rsvdc),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(io_in_0_bits_poison),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_qos(g_io_out_bits_qos),
    .io_out_bits_tgtID(g_io_out_bits_tgtID),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_homeNID(g_io_out_bits_homeNID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_respErr(g_io_out_bits_respErr),
    .io_out_bits_resp(g_io_out_bits_resp),
    .io_out_bits_dataSource(g_io_out_bits_dataSource),
    .io_out_bits_cBusy(g_io_out_bits_cBusy),
    .io_out_bits_dbID(g_io_out_bits_dbID),
    .io_out_bits_ccID(g_io_out_bits_ccID),
    .io_out_bits_dataID(g_io_out_bits_dataID),
    .io_out_bits_tagOp(g_io_out_bits_tagOp),
    .io_out_bits_tag(g_io_out_bits_tag),
    .io_out_bits_tu(g_io_out_bits_tu),
    .io_out_bits_traceTag(g_io_out_bits_traceTag),
    .io_out_bits_rsvdc(g_io_out_bits_rsvdc),
    .io_out_bits_be(g_io_out_bits_be),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_dataCheck(g_io_out_bits_dataCheck),
    .io_out_bits_poison(g_io_out_bits_poison)
  );
  FastArbiter_30_xs u_i (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_qos(io_in_0_bits_qos),
    .io_in_0_bits_tgtID(io_in_0_bits_tgtID),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_homeNID(io_in_0_bits_homeNID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_respErr(io_in_0_bits_respErr),
    .io_in_0_bits_resp(io_in_0_bits_resp),
    .io_in_0_bits_dataSource(io_in_0_bits_dataSource),
    .io_in_0_bits_cBusy(io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_in_0_bits_ccID(io_in_0_bits_ccID),
    .io_in_0_bits_dataID(io_in_0_bits_dataID),
    .io_in_0_bits_tagOp(io_in_0_bits_tagOp),
    .io_in_0_bits_tag(io_in_0_bits_tag),
    .io_in_0_bits_tu(io_in_0_bits_tu),
    .io_in_0_bits_traceTag(io_in_0_bits_traceTag),
    .io_in_0_bits_rsvdc(io_in_0_bits_rsvdc),
    .io_in_0_bits_be(io_in_0_bits_be),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_dataCheck(io_in_0_bits_dataCheck),
    .io_in_0_bits_poison(io_in_0_bits_poison),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_qos(i_io_out_bits_qos),
    .io_out_bits_tgtID(i_io_out_bits_tgtID),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_homeNID(i_io_out_bits_homeNID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_respErr(i_io_out_bits_respErr),
    .io_out_bits_resp(i_io_out_bits_resp),
    .io_out_bits_dataSource(i_io_out_bits_dataSource),
    .io_out_bits_cBusy(i_io_out_bits_cBusy),
    .io_out_bits_dbID(i_io_out_bits_dbID),
    .io_out_bits_ccID(i_io_out_bits_ccID),
    .io_out_bits_dataID(i_io_out_bits_dataID),
    .io_out_bits_tagOp(i_io_out_bits_tagOp),
    .io_out_bits_tag(i_io_out_bits_tag),
    .io_out_bits_tu(i_io_out_bits_tu),
    .io_out_bits_traceTag(i_io_out_bits_traceTag),
    .io_out_bits_rsvdc(i_io_out_bits_rsvdc),
    .io_out_bits_be(i_io_out_bits_be),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_dataCheck(i_io_out_bits_dataCheck),
    .io_out_bits_poison(i_io_out_bits_poison)
  );

  task automatic drive_random();
    io_in_0_valid = $urandom % 2;
    io_in_0_bits_qos = rnd(4);
    io_in_0_bits_tgtID = rnd(11);
    io_in_0_bits_srcID = rnd(11);
    io_in_0_bits_txnID = rnd(12);
    io_in_0_bits_homeNID = rnd(11);
    io_in_0_bits_opcode = rnd(4);
    io_in_0_bits_respErr = rnd(2);
    io_in_0_bits_resp = rnd(3);
    io_in_0_bits_dataSource = rnd(4);
    io_in_0_bits_cBusy = rnd(3);
    io_in_0_bits_dbID = rnd(12);
    io_in_0_bits_ccID = rnd(2);
    io_in_0_bits_dataID = rnd(2);
    io_in_0_bits_tagOp = rnd(2);
    io_in_0_bits_tag = rnd(8);
    io_in_0_bits_tu = rnd(2);
    io_in_0_bits_traceTag = $urandom % 2;
    io_in_0_bits_rsvdc = rnd(4);
    io_in_0_bits_be = rnd(32);
    io_in_0_bits_data = rnd(256);
    io_in_0_bits_dataCheck = rnd(32);
    io_in_0_bits_poison = rnd(4);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_out_valid)) begin
      checks++;
      if (g_io_out_valid !== i_io_out_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_valid g=%0h i=%0h", $time, g_io_out_valid, i_io_out_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_qos)) begin
      checks++;
      if (g_io_out_bits_qos !== i_io_out_bits_qos) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_qos g=%0h i=%0h", $time, g_io_out_bits_qos, i_io_out_bits_qos);
      end
    end
    if (!$isunknown(g_io_out_bits_tgtID)) begin
      checks++;
      if (g_io_out_bits_tgtID !== i_io_out_bits_tgtID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_tgtID g=%0h i=%0h", $time, g_io_out_bits_tgtID, i_io_out_bits_tgtID);
      end
    end
    if (!$isunknown(g_io_out_bits_srcID)) begin
      checks++;
      if (g_io_out_bits_srcID !== i_io_out_bits_srcID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_srcID g=%0h i=%0h", $time, g_io_out_bits_srcID, i_io_out_bits_srcID);
      end
    end
    if (!$isunknown(g_io_out_bits_txnID)) begin
      checks++;
      if (g_io_out_bits_txnID !== i_io_out_bits_txnID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_txnID g=%0h i=%0h", $time, g_io_out_bits_txnID, i_io_out_bits_txnID);
      end
    end
    if (!$isunknown(g_io_out_bits_homeNID)) begin
      checks++;
      if (g_io_out_bits_homeNID !== i_io_out_bits_homeNID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_homeNID g=%0h i=%0h", $time, g_io_out_bits_homeNID, i_io_out_bits_homeNID);
      end
    end
    if (!$isunknown(g_io_out_bits_opcode)) begin
      checks++;
      if (g_io_out_bits_opcode !== i_io_out_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_opcode g=%0h i=%0h", $time, g_io_out_bits_opcode, i_io_out_bits_opcode);
      end
    end
    if (!$isunknown(g_io_out_bits_respErr)) begin
      checks++;
      if (g_io_out_bits_respErr !== i_io_out_bits_respErr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_respErr g=%0h i=%0h", $time, g_io_out_bits_respErr, i_io_out_bits_respErr);
      end
    end
    if (!$isunknown(g_io_out_bits_resp)) begin
      checks++;
      if (g_io_out_bits_resp !== i_io_out_bits_resp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_resp g=%0h i=%0h", $time, g_io_out_bits_resp, i_io_out_bits_resp);
      end
    end
    if (!$isunknown(g_io_out_bits_dataSource)) begin
      checks++;
      if (g_io_out_bits_dataSource !== i_io_out_bits_dataSource) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_dataSource g=%0h i=%0h", $time, g_io_out_bits_dataSource, i_io_out_bits_dataSource);
      end
    end
    if (!$isunknown(g_io_out_bits_cBusy)) begin
      checks++;
      if (g_io_out_bits_cBusy !== i_io_out_bits_cBusy) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_cBusy g=%0h i=%0h", $time, g_io_out_bits_cBusy, i_io_out_bits_cBusy);
      end
    end
    if (!$isunknown(g_io_out_bits_dbID)) begin
      checks++;
      if (g_io_out_bits_dbID !== i_io_out_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_dbID g=%0h i=%0h", $time, g_io_out_bits_dbID, i_io_out_bits_dbID);
      end
    end
    if (!$isunknown(g_io_out_bits_ccID)) begin
      checks++;
      if (g_io_out_bits_ccID !== i_io_out_bits_ccID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_ccID g=%0h i=%0h", $time, g_io_out_bits_ccID, i_io_out_bits_ccID);
      end
    end
    if (!$isunknown(g_io_out_bits_dataID)) begin
      checks++;
      if (g_io_out_bits_dataID !== i_io_out_bits_dataID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_dataID g=%0h i=%0h", $time, g_io_out_bits_dataID, i_io_out_bits_dataID);
      end
    end
    if (!$isunknown(g_io_out_bits_tagOp)) begin
      checks++;
      if (g_io_out_bits_tagOp !== i_io_out_bits_tagOp) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_tagOp g=%0h i=%0h", $time, g_io_out_bits_tagOp, i_io_out_bits_tagOp);
      end
    end
    if (!$isunknown(g_io_out_bits_tag)) begin
      checks++;
      if (g_io_out_bits_tag !== i_io_out_bits_tag) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_tag g=%0h i=%0h", $time, g_io_out_bits_tag, i_io_out_bits_tag);
      end
    end
    if (!$isunknown(g_io_out_bits_tu)) begin
      checks++;
      if (g_io_out_bits_tu !== i_io_out_bits_tu) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_tu g=%0h i=%0h", $time, g_io_out_bits_tu, i_io_out_bits_tu);
      end
    end
    if (!$isunknown(g_io_out_bits_traceTag)) begin
      checks++;
      if (g_io_out_bits_traceTag !== i_io_out_bits_traceTag) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_traceTag g=%0h i=%0h", $time, g_io_out_bits_traceTag, i_io_out_bits_traceTag);
      end
    end
    if (!$isunknown(g_io_out_bits_rsvdc)) begin
      checks++;
      if (g_io_out_bits_rsvdc !== i_io_out_bits_rsvdc) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_rsvdc g=%0h i=%0h", $time, g_io_out_bits_rsvdc, i_io_out_bits_rsvdc);
      end
    end
    if (!$isunknown(g_io_out_bits_be)) begin
      checks++;
      if (g_io_out_bits_be !== i_io_out_bits_be) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_be g=%0h i=%0h", $time, g_io_out_bits_be, i_io_out_bits_be);
      end
    end
    if (!$isunknown(g_io_out_bits_data)) begin
      checks++;
      if (g_io_out_bits_data !== i_io_out_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_data g=%0h i=%0h", $time, g_io_out_bits_data, i_io_out_bits_data);
      end
    end
    if (!$isunknown(g_io_out_bits_dataCheck)) begin
      checks++;
      if (g_io_out_bits_dataCheck !== i_io_out_bits_dataCheck) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_dataCheck g=%0h i=%0h", $time, g_io_out_bits_dataCheck, i_io_out_bits_dataCheck);
      end
    end
    if (!$isunknown(g_io_out_bits_poison)) begin
      checks++;
      if (g_io_out_bits_poison !== i_io_out_bits_poison) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_poison g=%0h i=%0h", $time, g_io_out_bits_poison, i_io_out_bits_poison);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_out_valid !== p_io_out_valid) tog_io_out_valid = 1'b1;
    p_io_out_valid = g_io_out_valid;
    if (g_io_out_bits_qos !== p_io_out_bits_qos) tog_io_out_bits_qos = 1'b1;
    p_io_out_bits_qos = g_io_out_bits_qos;
    if (g_io_out_bits_tgtID !== p_io_out_bits_tgtID) tog_io_out_bits_tgtID = 1'b1;
    p_io_out_bits_tgtID = g_io_out_bits_tgtID;
    if (g_io_out_bits_srcID !== p_io_out_bits_srcID) tog_io_out_bits_srcID = 1'b1;
    p_io_out_bits_srcID = g_io_out_bits_srcID;
    if (g_io_out_bits_txnID !== p_io_out_bits_txnID) tog_io_out_bits_txnID = 1'b1;
    p_io_out_bits_txnID = g_io_out_bits_txnID;
    if (g_io_out_bits_homeNID !== p_io_out_bits_homeNID) tog_io_out_bits_homeNID = 1'b1;
    p_io_out_bits_homeNID = g_io_out_bits_homeNID;
    if (g_io_out_bits_opcode !== p_io_out_bits_opcode) tog_io_out_bits_opcode = 1'b1;
    p_io_out_bits_opcode = g_io_out_bits_opcode;
    if (g_io_out_bits_respErr !== p_io_out_bits_respErr) tog_io_out_bits_respErr = 1'b1;
    p_io_out_bits_respErr = g_io_out_bits_respErr;
    if (g_io_out_bits_resp !== p_io_out_bits_resp) tog_io_out_bits_resp = 1'b1;
    p_io_out_bits_resp = g_io_out_bits_resp;
    if (g_io_out_bits_dataSource !== p_io_out_bits_dataSource) tog_io_out_bits_dataSource = 1'b1;
    p_io_out_bits_dataSource = g_io_out_bits_dataSource;
    if (g_io_out_bits_cBusy !== p_io_out_bits_cBusy) tog_io_out_bits_cBusy = 1'b1;
    p_io_out_bits_cBusy = g_io_out_bits_cBusy;
    if (g_io_out_bits_dbID !== p_io_out_bits_dbID) tog_io_out_bits_dbID = 1'b1;
    p_io_out_bits_dbID = g_io_out_bits_dbID;
    if (g_io_out_bits_ccID !== p_io_out_bits_ccID) tog_io_out_bits_ccID = 1'b1;
    p_io_out_bits_ccID = g_io_out_bits_ccID;
    if (g_io_out_bits_dataID !== p_io_out_bits_dataID) tog_io_out_bits_dataID = 1'b1;
    p_io_out_bits_dataID = g_io_out_bits_dataID;
    if (g_io_out_bits_tagOp !== p_io_out_bits_tagOp) tog_io_out_bits_tagOp = 1'b1;
    p_io_out_bits_tagOp = g_io_out_bits_tagOp;
    if (g_io_out_bits_tag !== p_io_out_bits_tag) tog_io_out_bits_tag = 1'b1;
    p_io_out_bits_tag = g_io_out_bits_tag;
    if (g_io_out_bits_tu !== p_io_out_bits_tu) tog_io_out_bits_tu = 1'b1;
    p_io_out_bits_tu = g_io_out_bits_tu;
    if (g_io_out_bits_traceTag !== p_io_out_bits_traceTag) tog_io_out_bits_traceTag = 1'b1;
    p_io_out_bits_traceTag = g_io_out_bits_traceTag;
    if (g_io_out_bits_rsvdc !== p_io_out_bits_rsvdc) tog_io_out_bits_rsvdc = 1'b1;
    p_io_out_bits_rsvdc = g_io_out_bits_rsvdc;
    if (g_io_out_bits_be !== p_io_out_bits_be) tog_io_out_bits_be = 1'b1;
    p_io_out_bits_be = g_io_out_bits_be;
    if (g_io_out_bits_data !== p_io_out_bits_data) tog_io_out_bits_data = 1'b1;
    p_io_out_bits_data = g_io_out_bits_data;
    if (g_io_out_bits_dataCheck !== p_io_out_bits_dataCheck) tog_io_out_bits_dataCheck = 1'b1;
    p_io_out_bits_dataCheck = g_io_out_bits_dataCheck;
    if (g_io_out_bits_poison !== p_io_out_bits_poison) tog_io_out_bits_poison = 1'b1;
    p_io_out_bits_poison = g_io_out_bits_poison;
  endtask

  initial begin
    io_in_0_valid = '0;
    io_in_0_bits_qos = '0;
    io_in_0_bits_tgtID = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_homeNID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_respErr = '0;
    io_in_0_bits_resp = '0;
    io_in_0_bits_dataSource = '0;
    io_in_0_bits_cBusy = '0;
    io_in_0_bits_dbID = '0;
    io_in_0_bits_ccID = '0;
    io_in_0_bits_dataID = '0;
    io_in_0_bits_tagOp = '0;
    io_in_0_bits_tag = '0;
    io_in_0_bits_tu = '0;
    io_in_0_bits_traceTag = '0;
    io_in_0_bits_rsvdc = '0;
    io_in_0_bits_be = '0;
    io_in_0_bits_data = '0;
    io_in_0_bits_dataCheck = '0;
    io_in_0_bits_poison = '0;
    p_io_out_valid = '0; tog_io_out_valid = 1'b0;
    p_io_out_bits_qos = '0; tog_io_out_bits_qos = 1'b0;
    p_io_out_bits_tgtID = '0; tog_io_out_bits_tgtID = 1'b0;
    p_io_out_bits_srcID = '0; tog_io_out_bits_srcID = 1'b0;
    p_io_out_bits_txnID = '0; tog_io_out_bits_txnID = 1'b0;
    p_io_out_bits_homeNID = '0; tog_io_out_bits_homeNID = 1'b0;
    p_io_out_bits_opcode = '0; tog_io_out_bits_opcode = 1'b0;
    p_io_out_bits_respErr = '0; tog_io_out_bits_respErr = 1'b0;
    p_io_out_bits_resp = '0; tog_io_out_bits_resp = 1'b0;
    p_io_out_bits_dataSource = '0; tog_io_out_bits_dataSource = 1'b0;
    p_io_out_bits_cBusy = '0; tog_io_out_bits_cBusy = 1'b0;
    p_io_out_bits_dbID = '0; tog_io_out_bits_dbID = 1'b0;
    p_io_out_bits_ccID = '0; tog_io_out_bits_ccID = 1'b0;
    p_io_out_bits_dataID = '0; tog_io_out_bits_dataID = 1'b0;
    p_io_out_bits_tagOp = '0; tog_io_out_bits_tagOp = 1'b0;
    p_io_out_bits_tag = '0; tog_io_out_bits_tag = 1'b0;
    p_io_out_bits_tu = '0; tog_io_out_bits_tu = 1'b0;
    p_io_out_bits_traceTag = '0; tog_io_out_bits_traceTag = 1'b0;
    p_io_out_bits_rsvdc = '0; tog_io_out_bits_rsvdc = 1'b0;
    p_io_out_bits_be = '0; tog_io_out_bits_be = 1'b0;
    p_io_out_bits_data = '0; tog_io_out_bits_data = 1'b0;
    p_io_out_bits_dataCheck = '0; tog_io_out_bits_dataCheck = 1'b0;
    p_io_out_bits_poison = '0; tog_io_out_bits_poison = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_out_valid) toggled++; else $display("COV: output io_out_valid never toggled");
    if (tog_io_out_bits_qos) toggled++; else $display("COV: output io_out_bits_qos never toggled");
    if (tog_io_out_bits_tgtID) toggled++; else $display("COV: output io_out_bits_tgtID never toggled");
    if (tog_io_out_bits_srcID) toggled++; else $display("COV: output io_out_bits_srcID never toggled");
    if (tog_io_out_bits_txnID) toggled++; else $display("COV: output io_out_bits_txnID never toggled");
    if (tog_io_out_bits_homeNID) toggled++; else $display("COV: output io_out_bits_homeNID never toggled");
    if (tog_io_out_bits_opcode) toggled++; else $display("COV: output io_out_bits_opcode never toggled");
    if (tog_io_out_bits_respErr) toggled++; else $display("COV: output io_out_bits_respErr never toggled");
    if (tog_io_out_bits_resp) toggled++; else $display("COV: output io_out_bits_resp never toggled");
    if (tog_io_out_bits_dataSource) toggled++; else $display("COV: output io_out_bits_dataSource never toggled");
    if (tog_io_out_bits_cBusy) toggled++; else $display("COV: output io_out_bits_cBusy never toggled");
    if (tog_io_out_bits_dbID) toggled++; else $display("COV: output io_out_bits_dbID never toggled");
    if (tog_io_out_bits_ccID) toggled++; else $display("COV: output io_out_bits_ccID never toggled");
    if (tog_io_out_bits_dataID) toggled++; else $display("COV: output io_out_bits_dataID never toggled");
    if (tog_io_out_bits_tagOp) toggled++; else $display("COV: output io_out_bits_tagOp never toggled");
    if (tog_io_out_bits_tag) toggled++; else $display("COV: output io_out_bits_tag never toggled");
    if (tog_io_out_bits_tu) toggled++; else $display("COV: output io_out_bits_tu never toggled");
    if (tog_io_out_bits_traceTag) toggled++; else $display("COV: output io_out_bits_traceTag never toggled");
    if (tog_io_out_bits_rsvdc) toggled++; else $display("COV: output io_out_bits_rsvdc never toggled");
    if (tog_io_out_bits_be) toggled++; else $display("COV: output io_out_bits_be never toggled");
    if (tog_io_out_bits_data) toggled++; else $display("COV: output io_out_bits_data never toggled");
    if (tog_io_out_bits_dataCheck) toggled++; else $display("COV: output io_out_bits_dataCheck never toggled");
    if (tog_io_out_bits_poison) toggled++; else $display("COV: output io_out_bits_poison never toggled");
    $display("FastArbiter_30 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
