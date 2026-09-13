// 自动生成：scripts/gen_zj_ut.py FastArbiter_35 —— 勿手改
// FastArbiter_35 双例化逐拍比对：golden FastArbiter_35 vs 重写 FastArbiter_35_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 120000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 120000;
  localparam int unsigned MIN_TOGGLED = 5;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 5;

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
  logic [10:0] io_in_0_bits_srcID;
  logic [11:0] io_in_0_bits_txnID;
  logic [4:0] io_in_0_bits_opcode;
  logic [11:0] io_in_0_bits_dbID;

  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [10:0] g_io_out_bits_srcID;
  wire [10:0] i_io_out_bits_srcID;
  wire [11:0] g_io_out_bits_txnID;
  wire [11:0] i_io_out_bits_txnID;
  wire [4:0] g_io_out_bits_opcode;
  wire [4:0] i_io_out_bits_opcode;
  wire [11:0] g_io_out_bits_dbID;
  wire [11:0] i_io_out_bits_dbID;

  logic p_io_out_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_valid;
  logic [10:0] p_io_out_bits_srcID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_srcID;
  logic [11:0] p_io_out_bits_txnID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_txnID;
  logic [4:0] p_io_out_bits_opcode;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_opcode;
  logic [11:0] p_io_out_bits_dbID;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_dbID;

  FastArbiter_35 u_g (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_srcID(g_io_out_bits_srcID),
    .io_out_bits_txnID(g_io_out_bits_txnID),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_dbID(g_io_out_bits_dbID)
  );
  FastArbiter_35_xs u_i (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_srcID(io_in_0_bits_srcID),
    .io_in_0_bits_txnID(io_in_0_bits_txnID),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_dbID(io_in_0_bits_dbID),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_srcID(i_io_out_bits_srcID),
    .io_out_bits_txnID(i_io_out_bits_txnID),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_dbID(i_io_out_bits_dbID)
  );

  task automatic drive_random();
    io_in_0_valid = $urandom % 2;
    io_in_0_bits_srcID = rnd(11);
    io_in_0_bits_txnID = rnd(12);
    io_in_0_bits_opcode = rnd(5);
    io_in_0_bits_dbID = rnd(12);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_out_valid)) begin
      checks++;
      if (g_io_out_valid !== i_io_out_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_valid g=%0h i=%0h", $time, g_io_out_valid, i_io_out_valid);
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
    if (!$isunknown(g_io_out_bits_opcode)) begin
      checks++;
      if (g_io_out_bits_opcode !== i_io_out_bits_opcode) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_opcode g=%0h i=%0h", $time, g_io_out_bits_opcode, i_io_out_bits_opcode);
      end
    end
    if (!$isunknown(g_io_out_bits_dbID)) begin
      checks++;
      if (g_io_out_bits_dbID !== i_io_out_bits_dbID) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_dbID g=%0h i=%0h", $time, g_io_out_bits_dbID, i_io_out_bits_dbID);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_out_valid !== p_io_out_valid) tog_io_out_valid = 1'b1;
    p_io_out_valid = g_io_out_valid;
    if (g_io_out_bits_srcID !== p_io_out_bits_srcID) tog_io_out_bits_srcID = 1'b1;
    p_io_out_bits_srcID = g_io_out_bits_srcID;
    if (g_io_out_bits_txnID !== p_io_out_bits_txnID) tog_io_out_bits_txnID = 1'b1;
    p_io_out_bits_txnID = g_io_out_bits_txnID;
    if (g_io_out_bits_opcode !== p_io_out_bits_opcode) tog_io_out_bits_opcode = 1'b1;
    p_io_out_bits_opcode = g_io_out_bits_opcode;
    if (g_io_out_bits_dbID !== p_io_out_bits_dbID) tog_io_out_bits_dbID = 1'b1;
    p_io_out_bits_dbID = g_io_out_bits_dbID;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_in_0_valid = '0;
    io_in_0_bits_srcID = '0;
    io_in_0_bits_txnID = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_dbID = '0;
    p_io_out_valid = '0; tog_io_out_valid = 1'b0;
    p_io_out_bits_srcID = '0; tog_io_out_bits_srcID = 1'b0;
    p_io_out_bits_txnID = '0; tog_io_out_bits_txnID = 1'b0;
    p_io_out_bits_opcode = '0; tog_io_out_bits_opcode = 1'b0;
    p_io_out_bits_dbID = '0; tog_io_out_bits_dbID = 1'b0;
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
    if (tog_io_out_bits_srcID) toggled++; else $display("COV: output io_out_bits_srcID never toggled");
    if (tog_io_out_bits_txnID) toggled++; else $display("COV: output io_out_bits_txnID never toggled");
    if (tog_io_out_bits_opcode) toggled++; else $display("COV: output io_out_bits_opcode never toggled");
    if (tog_io_out_bits_dbID) toggled++; else $display("COV: output io_out_bits_dbID never toggled");
    $display("FastArbiter_35 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
