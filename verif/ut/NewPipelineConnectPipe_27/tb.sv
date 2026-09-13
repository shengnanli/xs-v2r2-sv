// NewPipelineConnectPipe_27 双例化逐拍比对 tb —— golden NewPipelineConnectPipe_27 vs 重写 NewPipelineConnectPipe_27_xs（derive_ut_impl.py 派生）。
// 端口表机械取自 G1 golden NewPipelineConnectPipe_27.sv；所有输入逐拍随机驱动，所有输出逐拍比对。
// 本变体 = CtrlUnit 的伪错误注入缓冲（G1 新增；G0 的 _27 是 VMergeBuffer 那个，在 G1 叫 _29）。
// 覆盖闸：errors=0 在"DUT 根本没动"时同样成立，所以另判三项——
//   checks  比对次数（0 直接 FAIL）；
//   toggled 至少翻转过一次的输出个数（< MIN_TOGGLED 判 FAIL）；
//   fires   valid&ready 同拍成立的次数（< MIN_FIRES 判 FAIL）。
`timescale 1ns/1ps
module tb;
  // 拍数默认 200000（>= CONVENTIONS 的 10 万），被 ut_common.mk 下发的 +ncycles=<n> 覆盖。
  int unsigned NCYCLES = 200000;
  localparam int unsigned MIN_TOGGLED = 18;
  localparam int unsigned MIN_FIRES   = 1000;
  localparam int unsigned N_OUT       = 18;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int     toggled = 0;

  // 宽随机：$urandom 一次给 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int bw);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < bw; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_in_valid;
  logic io_in_bits_0_valid;
  logic [63:0] io_in_bits_0_mask;
  logic io_in_bits_1_valid;
  logic [63:0] io_in_bits_1_mask;
  logic io_in_bits_2_valid;
  logic [63:0] io_in_bits_2_mask;
  logic io_in_bits_3_valid;
  logic [63:0] io_in_bits_3_mask;
  logic io_in_bits_4_valid;
  logic [63:0] io_in_bits_4_mask;
  logic io_in_bits_5_valid;
  logic [63:0] io_in_bits_5_mask;
  logic io_in_bits_6_valid;
  logic [63:0] io_in_bits_6_mask;
  logic io_in_bits_7_valid;
  logic [63:0] io_in_bits_7_mask;
  logic io_out_ready;
  logic io_rightOutFire;

  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire g_io_out_bits_0_valid;
  wire i_io_out_bits_0_valid;
  wire [63:0] g_io_out_bits_0_mask;
  wire [63:0] i_io_out_bits_0_mask;
  wire g_io_out_bits_1_valid;
  wire i_io_out_bits_1_valid;
  wire [63:0] g_io_out_bits_1_mask;
  wire [63:0] i_io_out_bits_1_mask;
  wire g_io_out_bits_2_valid;
  wire i_io_out_bits_2_valid;
  wire [63:0] g_io_out_bits_2_mask;
  wire [63:0] i_io_out_bits_2_mask;
  wire g_io_out_bits_3_valid;
  wire i_io_out_bits_3_valid;
  wire [63:0] g_io_out_bits_3_mask;
  wire [63:0] i_io_out_bits_3_mask;
  wire g_io_out_bits_4_valid;
  wire i_io_out_bits_4_valid;
  wire [63:0] g_io_out_bits_4_mask;
  wire [63:0] i_io_out_bits_4_mask;
  wire g_io_out_bits_5_valid;
  wire i_io_out_bits_5_valid;
  wire [63:0] g_io_out_bits_5_mask;
  wire [63:0] i_io_out_bits_5_mask;
  wire g_io_out_bits_6_valid;
  wire i_io_out_bits_6_valid;
  wire [63:0] g_io_out_bits_6_mask;
  wire [63:0] i_io_out_bits_6_mask;
  wire g_io_out_bits_7_valid;
  wire i_io_out_bits_7_valid;
  wire [63:0] g_io_out_bits_7_mask;
  wire [63:0] i_io_out_bits_7_mask;

  logic p_io_in_ready;   // 上一拍值，用于 toggle 统计
  bit tog_io_in_ready;
  logic p_io_out_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_valid;
  logic p_io_out_bits_0_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_0_valid;
  logic [63:0] p_io_out_bits_0_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_0_mask;
  logic p_io_out_bits_1_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_1_valid;
  logic [63:0] p_io_out_bits_1_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_1_mask;
  logic p_io_out_bits_2_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_2_valid;
  logic [63:0] p_io_out_bits_2_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_2_mask;
  logic p_io_out_bits_3_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_3_valid;
  logic [63:0] p_io_out_bits_3_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_3_mask;
  logic p_io_out_bits_4_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_4_valid;
  logic [63:0] p_io_out_bits_4_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_4_mask;
  logic p_io_out_bits_5_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_5_valid;
  logic [63:0] p_io_out_bits_5_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_5_mask;
  logic p_io_out_bits_6_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_6_valid;
  logic [63:0] p_io_out_bits_6_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_6_mask;
  logic p_io_out_bits_7_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_7_valid;
  logic [63:0] p_io_out_bits_7_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_out_bits_7_mask;

  NewPipelineConnectPipe_27 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_0_valid(io_in_bits_0_valid),
    .io_in_bits_0_mask(io_in_bits_0_mask),
    .io_in_bits_1_valid(io_in_bits_1_valid),
    .io_in_bits_1_mask(io_in_bits_1_mask),
    .io_in_bits_2_valid(io_in_bits_2_valid),
    .io_in_bits_2_mask(io_in_bits_2_mask),
    .io_in_bits_3_valid(io_in_bits_3_valid),
    .io_in_bits_3_mask(io_in_bits_3_mask),
    .io_in_bits_4_valid(io_in_bits_4_valid),
    .io_in_bits_4_mask(io_in_bits_4_mask),
    .io_in_bits_5_valid(io_in_bits_5_valid),
    .io_in_bits_5_mask(io_in_bits_5_mask),
    .io_in_bits_6_valid(io_in_bits_6_valid),
    .io_in_bits_6_mask(io_in_bits_6_mask),
    .io_in_bits_7_valid(io_in_bits_7_valid),
    .io_in_bits_7_mask(io_in_bits_7_mask),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_0_valid(g_io_out_bits_0_valid),
    .io_out_bits_0_mask(g_io_out_bits_0_mask),
    .io_out_bits_1_valid(g_io_out_bits_1_valid),
    .io_out_bits_1_mask(g_io_out_bits_1_mask),
    .io_out_bits_2_valid(g_io_out_bits_2_valid),
    .io_out_bits_2_mask(g_io_out_bits_2_mask),
    .io_out_bits_3_valid(g_io_out_bits_3_valid),
    .io_out_bits_3_mask(g_io_out_bits_3_mask),
    .io_out_bits_4_valid(g_io_out_bits_4_valid),
    .io_out_bits_4_mask(g_io_out_bits_4_mask),
    .io_out_bits_5_valid(g_io_out_bits_5_valid),
    .io_out_bits_5_mask(g_io_out_bits_5_mask),
    .io_out_bits_6_valid(g_io_out_bits_6_valid),
    .io_out_bits_6_mask(g_io_out_bits_6_mask),
    .io_out_bits_7_valid(g_io_out_bits_7_valid),
    .io_out_bits_7_mask(g_io_out_bits_7_mask),
    .io_rightOutFire(io_rightOutFire)
  );

  NewPipelineConnectPipe_27_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_0_valid(io_in_bits_0_valid),
    .io_in_bits_0_mask(io_in_bits_0_mask),
    .io_in_bits_1_valid(io_in_bits_1_valid),
    .io_in_bits_1_mask(io_in_bits_1_mask),
    .io_in_bits_2_valid(io_in_bits_2_valid),
    .io_in_bits_2_mask(io_in_bits_2_mask),
    .io_in_bits_3_valid(io_in_bits_3_valid),
    .io_in_bits_3_mask(io_in_bits_3_mask),
    .io_in_bits_4_valid(io_in_bits_4_valid),
    .io_in_bits_4_mask(io_in_bits_4_mask),
    .io_in_bits_5_valid(io_in_bits_5_valid),
    .io_in_bits_5_mask(io_in_bits_5_mask),
    .io_in_bits_6_valid(io_in_bits_6_valid),
    .io_in_bits_6_mask(io_in_bits_6_mask),
    .io_in_bits_7_valid(io_in_bits_7_valid),
    .io_in_bits_7_mask(io_in_bits_7_mask),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_0_valid(i_io_out_bits_0_valid),
    .io_out_bits_0_mask(i_io_out_bits_0_mask),
    .io_out_bits_1_valid(i_io_out_bits_1_valid),
    .io_out_bits_1_mask(i_io_out_bits_1_mask),
    .io_out_bits_2_valid(i_io_out_bits_2_valid),
    .io_out_bits_2_mask(i_io_out_bits_2_mask),
    .io_out_bits_3_valid(i_io_out_bits_3_valid),
    .io_out_bits_3_mask(i_io_out_bits_3_mask),
    .io_out_bits_4_valid(i_io_out_bits_4_valid),
    .io_out_bits_4_mask(i_io_out_bits_4_mask),
    .io_out_bits_5_valid(i_io_out_bits_5_valid),
    .io_out_bits_5_mask(i_io_out_bits_5_mask),
    .io_out_bits_6_valid(i_io_out_bits_6_valid),
    .io_out_bits_6_mask(i_io_out_bits_6_mask),
    .io_out_bits_7_valid(i_io_out_bits_7_valid),
    .io_out_bits_7_mask(i_io_out_bits_7_mask),
    .io_rightOutFire(io_rightOutFire)
  );

  task automatic drive_random();
    io_in_valid = $urandom % 2;
    io_in_bits_0_valid = $urandom % 2;
    io_in_bits_0_mask = rnd(64);
    io_in_bits_1_valid = $urandom % 2;
    io_in_bits_1_mask = rnd(64);
    io_in_bits_2_valid = $urandom % 2;
    io_in_bits_2_mask = rnd(64);
    io_in_bits_3_valid = $urandom % 2;
    io_in_bits_3_mask = rnd(64);
    io_in_bits_4_valid = $urandom % 2;
    io_in_bits_4_mask = rnd(64);
    io_in_bits_5_valid = $urandom % 2;
    io_in_bits_5_mask = rnd(64);
    io_in_bits_6_valid = $urandom % 2;
    io_in_bits_6_mask = rnd(64);
    io_in_bits_7_valid = $urandom % 2;
    io_in_bits_7_mask = rnd(64);
    io_out_ready = (($urandom % 4) != 0);   // 75% 高：既走通路又制造反压
    io_rightOutFire = $urandom % 2;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_in_ready)) begin
      checks++;
      if (g_io_in_ready !== i_io_in_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_in_ready g=%0h i=%0h", $time, g_io_in_ready, i_io_in_ready);
      end
    end
    if (!$isunknown(g_io_out_valid)) begin
      checks++;
      if (g_io_out_valid !== i_io_out_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_valid g=%0h i=%0h", $time, g_io_out_valid, i_io_out_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_0_valid)) begin
      checks++;
      if (g_io_out_bits_0_valid !== i_io_out_bits_0_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_0_valid g=%0h i=%0h", $time, g_io_out_bits_0_valid, i_io_out_bits_0_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_0_mask)) begin
      checks++;
      if (g_io_out_bits_0_mask !== i_io_out_bits_0_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_0_mask g=%0h i=%0h", $time, g_io_out_bits_0_mask, i_io_out_bits_0_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_1_valid)) begin
      checks++;
      if (g_io_out_bits_1_valid !== i_io_out_bits_1_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_1_valid g=%0h i=%0h", $time, g_io_out_bits_1_valid, i_io_out_bits_1_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_1_mask)) begin
      checks++;
      if (g_io_out_bits_1_mask !== i_io_out_bits_1_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_1_mask g=%0h i=%0h", $time, g_io_out_bits_1_mask, i_io_out_bits_1_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_2_valid)) begin
      checks++;
      if (g_io_out_bits_2_valid !== i_io_out_bits_2_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_2_valid g=%0h i=%0h", $time, g_io_out_bits_2_valid, i_io_out_bits_2_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_2_mask)) begin
      checks++;
      if (g_io_out_bits_2_mask !== i_io_out_bits_2_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_2_mask g=%0h i=%0h", $time, g_io_out_bits_2_mask, i_io_out_bits_2_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_3_valid)) begin
      checks++;
      if (g_io_out_bits_3_valid !== i_io_out_bits_3_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_3_valid g=%0h i=%0h", $time, g_io_out_bits_3_valid, i_io_out_bits_3_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_3_mask)) begin
      checks++;
      if (g_io_out_bits_3_mask !== i_io_out_bits_3_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_3_mask g=%0h i=%0h", $time, g_io_out_bits_3_mask, i_io_out_bits_3_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_4_valid)) begin
      checks++;
      if (g_io_out_bits_4_valid !== i_io_out_bits_4_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_4_valid g=%0h i=%0h", $time, g_io_out_bits_4_valid, i_io_out_bits_4_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_4_mask)) begin
      checks++;
      if (g_io_out_bits_4_mask !== i_io_out_bits_4_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_4_mask g=%0h i=%0h", $time, g_io_out_bits_4_mask, i_io_out_bits_4_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_5_valid)) begin
      checks++;
      if (g_io_out_bits_5_valid !== i_io_out_bits_5_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_5_valid g=%0h i=%0h", $time, g_io_out_bits_5_valid, i_io_out_bits_5_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_5_mask)) begin
      checks++;
      if (g_io_out_bits_5_mask !== i_io_out_bits_5_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_5_mask g=%0h i=%0h", $time, g_io_out_bits_5_mask, i_io_out_bits_5_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_6_valid)) begin
      checks++;
      if (g_io_out_bits_6_valid !== i_io_out_bits_6_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_6_valid g=%0h i=%0h", $time, g_io_out_bits_6_valid, i_io_out_bits_6_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_6_mask)) begin
      checks++;
      if (g_io_out_bits_6_mask !== i_io_out_bits_6_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_6_mask g=%0h i=%0h", $time, g_io_out_bits_6_mask, i_io_out_bits_6_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_7_valid)) begin
      checks++;
      if (g_io_out_bits_7_valid !== i_io_out_bits_7_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_7_valid g=%0h i=%0h", $time, g_io_out_bits_7_valid, i_io_out_bits_7_valid);
      end
    end
    if (!$isunknown(g_io_out_bits_7_mask)) begin
      checks++;
      if (g_io_out_bits_7_mask !== i_io_out_bits_7_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_7_mask g=%0h i=%0h", $time, g_io_out_bits_7_mask, i_io_out_bits_7_mask);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_in_ready !== p_io_in_ready) tog_io_in_ready = 1'b1;
    p_io_in_ready = g_io_in_ready;
    if (g_io_out_valid !== p_io_out_valid) tog_io_out_valid = 1'b1;
    p_io_out_valid = g_io_out_valid;
    if (g_io_out_bits_0_valid !== p_io_out_bits_0_valid) tog_io_out_bits_0_valid = 1'b1;
    p_io_out_bits_0_valid = g_io_out_bits_0_valid;
    if (g_io_out_bits_0_mask !== p_io_out_bits_0_mask) tog_io_out_bits_0_mask = 1'b1;
    p_io_out_bits_0_mask = g_io_out_bits_0_mask;
    if (g_io_out_bits_1_valid !== p_io_out_bits_1_valid) tog_io_out_bits_1_valid = 1'b1;
    p_io_out_bits_1_valid = g_io_out_bits_1_valid;
    if (g_io_out_bits_1_mask !== p_io_out_bits_1_mask) tog_io_out_bits_1_mask = 1'b1;
    p_io_out_bits_1_mask = g_io_out_bits_1_mask;
    if (g_io_out_bits_2_valid !== p_io_out_bits_2_valid) tog_io_out_bits_2_valid = 1'b1;
    p_io_out_bits_2_valid = g_io_out_bits_2_valid;
    if (g_io_out_bits_2_mask !== p_io_out_bits_2_mask) tog_io_out_bits_2_mask = 1'b1;
    p_io_out_bits_2_mask = g_io_out_bits_2_mask;
    if (g_io_out_bits_3_valid !== p_io_out_bits_3_valid) tog_io_out_bits_3_valid = 1'b1;
    p_io_out_bits_3_valid = g_io_out_bits_3_valid;
    if (g_io_out_bits_3_mask !== p_io_out_bits_3_mask) tog_io_out_bits_3_mask = 1'b1;
    p_io_out_bits_3_mask = g_io_out_bits_3_mask;
    if (g_io_out_bits_4_valid !== p_io_out_bits_4_valid) tog_io_out_bits_4_valid = 1'b1;
    p_io_out_bits_4_valid = g_io_out_bits_4_valid;
    if (g_io_out_bits_4_mask !== p_io_out_bits_4_mask) tog_io_out_bits_4_mask = 1'b1;
    p_io_out_bits_4_mask = g_io_out_bits_4_mask;
    if (g_io_out_bits_5_valid !== p_io_out_bits_5_valid) tog_io_out_bits_5_valid = 1'b1;
    p_io_out_bits_5_valid = g_io_out_bits_5_valid;
    if (g_io_out_bits_5_mask !== p_io_out_bits_5_mask) tog_io_out_bits_5_mask = 1'b1;
    p_io_out_bits_5_mask = g_io_out_bits_5_mask;
    if (g_io_out_bits_6_valid !== p_io_out_bits_6_valid) tog_io_out_bits_6_valid = 1'b1;
    p_io_out_bits_6_valid = g_io_out_bits_6_valid;
    if (g_io_out_bits_6_mask !== p_io_out_bits_6_mask) tog_io_out_bits_6_mask = 1'b1;
    p_io_out_bits_6_mask = g_io_out_bits_6_mask;
    if (g_io_out_bits_7_valid !== p_io_out_bits_7_valid) tog_io_out_bits_7_valid = 1'b1;
    p_io_out_bits_7_valid = g_io_out_bits_7_valid;
    if (g_io_out_bits_7_mask !== p_io_out_bits_7_mask) tog_io_out_bits_7_mask = 1'b1;
    p_io_out_bits_7_mask = g_io_out_bits_7_mask;
    if ((io_in_valid && g_io_in_ready) ||
        (g_io_out_valid && io_out_ready)) fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_in_valid = '0;
    io_in_bits_0_valid = '0;
    io_in_bits_0_mask = '0;
    io_in_bits_1_valid = '0;
    io_in_bits_1_mask = '0;
    io_in_bits_2_valid = '0;
    io_in_bits_2_mask = '0;
    io_in_bits_3_valid = '0;
    io_in_bits_3_mask = '0;
    io_in_bits_4_valid = '0;
    io_in_bits_4_mask = '0;
    io_in_bits_5_valid = '0;
    io_in_bits_5_mask = '0;
    io_in_bits_6_valid = '0;
    io_in_bits_6_mask = '0;
    io_in_bits_7_valid = '0;
    io_in_bits_7_mask = '0;
    io_out_ready = '0;
    io_rightOutFire = '0;
    p_io_in_ready = '0; tog_io_in_ready = 1'b0;
    p_io_out_valid = '0; tog_io_out_valid = 1'b0;
    p_io_out_bits_0_valid = '0; tog_io_out_bits_0_valid = 1'b0;
    p_io_out_bits_0_mask = '0; tog_io_out_bits_0_mask = 1'b0;
    p_io_out_bits_1_valid = '0; tog_io_out_bits_1_valid = 1'b0;
    p_io_out_bits_1_mask = '0; tog_io_out_bits_1_mask = 1'b0;
    p_io_out_bits_2_valid = '0; tog_io_out_bits_2_valid = 1'b0;
    p_io_out_bits_2_mask = '0; tog_io_out_bits_2_mask = 1'b0;
    p_io_out_bits_3_valid = '0; tog_io_out_bits_3_valid = 1'b0;
    p_io_out_bits_3_mask = '0; tog_io_out_bits_3_mask = 1'b0;
    p_io_out_bits_4_valid = '0; tog_io_out_bits_4_valid = 1'b0;
    p_io_out_bits_4_mask = '0; tog_io_out_bits_4_mask = 1'b0;
    p_io_out_bits_5_valid = '0; tog_io_out_bits_5_valid = 1'b0;
    p_io_out_bits_5_mask = '0; tog_io_out_bits_5_mask = 1'b0;
    p_io_out_bits_6_valid = '0; tog_io_out_bits_6_valid = 1'b0;
    p_io_out_bits_6_mask = '0; tog_io_out_bits_6_mask = 1'b0;
    p_io_out_bits_7_valid = '0; tog_io_out_bits_7_valid = 1'b0;
    p_io_out_bits_7_mask = '0; tog_io_out_bits_7_mask = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再复位一次，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_in_ready) toggled++; else $display("COV: output io_in_ready never toggled");
    if (tog_io_out_valid) toggled++; else $display("COV: output io_out_valid never toggled");
    if (tog_io_out_bits_0_valid) toggled++; else $display("COV: output io_out_bits_0_valid never toggled");
    if (tog_io_out_bits_0_mask) toggled++; else $display("COV: output io_out_bits_0_mask never toggled");
    if (tog_io_out_bits_1_valid) toggled++; else $display("COV: output io_out_bits_1_valid never toggled");
    if (tog_io_out_bits_1_mask) toggled++; else $display("COV: output io_out_bits_1_mask never toggled");
    if (tog_io_out_bits_2_valid) toggled++; else $display("COV: output io_out_bits_2_valid never toggled");
    if (tog_io_out_bits_2_mask) toggled++; else $display("COV: output io_out_bits_2_mask never toggled");
    if (tog_io_out_bits_3_valid) toggled++; else $display("COV: output io_out_bits_3_valid never toggled");
    if (tog_io_out_bits_3_mask) toggled++; else $display("COV: output io_out_bits_3_mask never toggled");
    if (tog_io_out_bits_4_valid) toggled++; else $display("COV: output io_out_bits_4_valid never toggled");
    if (tog_io_out_bits_4_mask) toggled++; else $display("COV: output io_out_bits_4_mask never toggled");
    if (tog_io_out_bits_5_valid) toggled++; else $display("COV: output io_out_bits_5_valid never toggled");
    if (tog_io_out_bits_5_mask) toggled++; else $display("COV: output io_out_bits_5_mask never toggled");
    if (tog_io_out_bits_6_valid) toggled++; else $display("COV: output io_out_bits_6_valid never toggled");
    if (tog_io_out_bits_6_mask) toggled++; else $display("COV: output io_out_bits_6_mask never toggled");
    if (tog_io_out_bits_7_valid) toggled++; else $display("COV: output io_out_bits_7_valid never toggled");
    if (tog_io_out_bits_7_mask) toggled++; else $display("COV: output io_out_bits_7_mask never toggled");
    $display("NewPipelineConnectPipe_27 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d",
             checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin
      $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED);
      $fatal(1);
    end
    if (fires < MIN_FIRES) begin
      $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES);
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
