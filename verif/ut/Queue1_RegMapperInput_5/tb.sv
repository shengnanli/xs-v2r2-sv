// Queue1_RegMapperInput_5 双例化逐拍比对 tb —— golden Queue1_RegMapperInput_5 vs 重写 Queue1_RegMapperInput_5_xs（derive_ut_impl.py 派生）。
// 端口表机械取自 G1 golden Queue1_RegMapperInput_5.sv；所有输入逐拍随机驱动，所有输出逐拍比对。
// 本变体 = ICacheCtrlUnit.out_back_q（G0 里叫 _3，且 source 宽度 3->5）。
// 覆盖闸：errors=0 在"DUT 根本没动"时同样成立，所以另判三项——
//   checks  比对次数（0 直接 FAIL）；
//   toggled 至少翻转过一次的输出个数（< MIN_TOGGLED 判 FAIL）；
//   fires   valid&ready 同拍成立的次数（< MIN_FIRES 判 FAIL）。
`timescale 1ns/1ps
module tb;
  // 拍数默认 200000（>= CONVENTIONS 的 10 万），被 ut_common.mk 下发的 +ncycles=<n> 覆盖。
  int unsigned NCYCLES = 200000;
  localparam int unsigned MIN_TOGGLED = 8;
  localparam int unsigned MIN_FIRES   = 1000;
  localparam int unsigned N_OUT       = 8;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  // 位宽覆盖闸：G0->G1 这一轮 source 从 3 位加到 5 位。若激励只打低 3 位，
  // 位宽写错的实现照样 errors=0（要等 FM 才炸）。这里数 source >= 8 的入队，
  // 为 0 就说明这轮跑根本没验到新加的高位，直接判 FAIL。
  longint hi_src_enq = 0;
  localparam int unsigned MIN_HI_SRC = 1000;
  int     toggled = 0;

  // 宽随机：$urandom 一次给 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int bw);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < bw; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_enq_valid;
  logic io_enq_bits_read;
  logic [3:0] io_enq_bits_index;
  logic [63:0] io_enq_bits_data;
  logic [7:0] io_enq_bits_mask;
  logic [4:0] io_enq_bits_extra_tlrr_extra_source;
  logic [1:0] io_enq_bits_extra_tlrr_extra_size;
  logic io_deq_ready;

  wire g_io_enq_ready;
  wire i_io_enq_ready;
  wire g_io_deq_valid;
  wire i_io_deq_valid;
  wire g_io_deq_bits_read;
  wire i_io_deq_bits_read;
  wire [3:0] g_io_deq_bits_index;
  wire [3:0] i_io_deq_bits_index;
  wire [63:0] g_io_deq_bits_data;
  wire [63:0] i_io_deq_bits_data;
  wire [7:0] g_io_deq_bits_mask;
  wire [7:0] i_io_deq_bits_mask;
  wire [4:0] g_io_deq_bits_extra_tlrr_extra_source;
  wire [4:0] i_io_deq_bits_extra_tlrr_extra_source;
  wire [1:0] g_io_deq_bits_extra_tlrr_extra_size;
  wire [1:0] i_io_deq_bits_extra_tlrr_extra_size;

  logic p_io_enq_ready;   // 上一拍值，用于 toggle 统计
  bit tog_io_enq_ready;
  logic p_io_deq_valid;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_valid;
  logic p_io_deq_bits_read;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_read;
  logic [3:0] p_io_deq_bits_index;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_index;
  logic [63:0] p_io_deq_bits_data;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_data;
  logic [7:0] p_io_deq_bits_mask;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_mask;
  logic [4:0] p_io_deq_bits_extra_tlrr_extra_source;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_extra_tlrr_extra_source;
  logic [1:0] p_io_deq_bits_extra_tlrr_extra_size;   // 上一拍值，用于 toggle 统计
  bit tog_io_deq_bits_extra_tlrr_extra_size;

  Queue1_RegMapperInput_5 u_g (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(g_io_enq_ready),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_read(io_enq_bits_read),
    .io_enq_bits_index(io_enq_bits_index),
    .io_enq_bits_data(io_enq_bits_data),
    .io_enq_bits_mask(io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(io_deq_ready),
    .io_deq_valid(g_io_deq_valid),
    .io_deq_bits_read(g_io_deq_bits_read),
    .io_deq_bits_index(g_io_deq_bits_index),
    .io_deq_bits_data(g_io_deq_bits_data),
    .io_deq_bits_mask(g_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(g_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(g_io_deq_bits_extra_tlrr_extra_size)
  );

  Queue1_RegMapperInput_5_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(i_io_enq_ready),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_read(io_enq_bits_read),
    .io_enq_bits_index(io_enq_bits_index),
    .io_enq_bits_data(io_enq_bits_data),
    .io_enq_bits_mask(io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(io_deq_ready),
    .io_deq_valid(i_io_deq_valid),
    .io_deq_bits_read(i_io_deq_bits_read),
    .io_deq_bits_index(i_io_deq_bits_index),
    .io_deq_bits_data(i_io_deq_bits_data),
    .io_deq_bits_mask(i_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(i_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(i_io_deq_bits_extra_tlrr_extra_size)
  );

  task automatic drive_random();
    io_enq_valid = $urandom % 2;
    io_enq_bits_read = $urandom % 2;
    io_enq_bits_index = rnd(4);
    io_enq_bits_data = rnd(64);
    io_enq_bits_mask = rnd(8);
    io_enq_bits_extra_tlrr_extra_source = rnd(5);
    io_enq_bits_extra_tlrr_extra_size = rnd(2);
    io_deq_ready = (($urandom % 4) != 0);   // 75% 高：既走通路又制造反压
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_enq_ready)) begin
      checks++;
      if (g_io_enq_ready !== i_io_enq_ready) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_enq_ready g=%0h i=%0h", $time, g_io_enq_ready, i_io_enq_ready);
      end
    end
    if (!$isunknown(g_io_deq_valid)) begin
      checks++;
      if (g_io_deq_valid !== i_io_deq_valid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_valid g=%0h i=%0h", $time, g_io_deq_valid, i_io_deq_valid);
      end
    end
    if (!$isunknown(g_io_deq_bits_read)) begin
      checks++;
      if (g_io_deq_bits_read !== i_io_deq_bits_read) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_read g=%0h i=%0h", $time, g_io_deq_bits_read, i_io_deq_bits_read);
      end
    end
    if (!$isunknown(g_io_deq_bits_index)) begin
      checks++;
      if (g_io_deq_bits_index !== i_io_deq_bits_index) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_index g=%0h i=%0h", $time, g_io_deq_bits_index, i_io_deq_bits_index);
      end
    end
    if (!$isunknown(g_io_deq_bits_data)) begin
      checks++;
      if (g_io_deq_bits_data !== i_io_deq_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_data g=%0h i=%0h", $time, g_io_deq_bits_data, i_io_deq_bits_data);
      end
    end
    if (!$isunknown(g_io_deq_bits_mask)) begin
      checks++;
      if (g_io_deq_bits_mask !== i_io_deq_bits_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_mask g=%0h i=%0h", $time, g_io_deq_bits_mask, i_io_deq_bits_mask);
      end
    end
    if (!$isunknown(g_io_deq_bits_extra_tlrr_extra_source)) begin
      checks++;
      if (g_io_deq_bits_extra_tlrr_extra_source !== i_io_deq_bits_extra_tlrr_extra_source) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_extra_tlrr_extra_source g=%0h i=%0h", $time, g_io_deq_bits_extra_tlrr_extra_source, i_io_deq_bits_extra_tlrr_extra_source);
      end
    end
    if (!$isunknown(g_io_deq_bits_extra_tlrr_extra_size)) begin
      checks++;
      if (g_io_deq_bits_extra_tlrr_extra_size !== i_io_deq_bits_extra_tlrr_extra_size) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_deq_bits_extra_tlrr_extra_size g=%0h i=%0h", $time, g_io_deq_bits_extra_tlrr_extra_size, i_io_deq_bits_extra_tlrr_extra_size);
      end
    end
  endtask

  task automatic sample_coverage();
    if (io_enq_valid && g_io_enq_ready && io_enq_bits_extra_tlrr_extra_source >= 5'd8)
      hi_src_enq++;
    if (g_io_enq_ready !== p_io_enq_ready) tog_io_enq_ready = 1'b1;
    p_io_enq_ready = g_io_enq_ready;
    if (g_io_deq_valid !== p_io_deq_valid) tog_io_deq_valid = 1'b1;
    p_io_deq_valid = g_io_deq_valid;
    if (g_io_deq_bits_read !== p_io_deq_bits_read) tog_io_deq_bits_read = 1'b1;
    p_io_deq_bits_read = g_io_deq_bits_read;
    if (g_io_deq_bits_index !== p_io_deq_bits_index) tog_io_deq_bits_index = 1'b1;
    p_io_deq_bits_index = g_io_deq_bits_index;
    if (g_io_deq_bits_data !== p_io_deq_bits_data) tog_io_deq_bits_data = 1'b1;
    p_io_deq_bits_data = g_io_deq_bits_data;
    if (g_io_deq_bits_mask !== p_io_deq_bits_mask) tog_io_deq_bits_mask = 1'b1;
    p_io_deq_bits_mask = g_io_deq_bits_mask;
    if (g_io_deq_bits_extra_tlrr_extra_source !== p_io_deq_bits_extra_tlrr_extra_source) tog_io_deq_bits_extra_tlrr_extra_source = 1'b1;
    p_io_deq_bits_extra_tlrr_extra_source = g_io_deq_bits_extra_tlrr_extra_source;
    if (g_io_deq_bits_extra_tlrr_extra_size !== p_io_deq_bits_extra_tlrr_extra_size) tog_io_deq_bits_extra_tlrr_extra_size = 1'b1;
    p_io_deq_bits_extra_tlrr_extra_size = g_io_deq_bits_extra_tlrr_extra_size;
    if ((io_enq_valid && g_io_enq_ready) ||
        (g_io_deq_valid && io_deq_ready)) fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_enq_valid = '0;
    io_enq_bits_read = '0;
    io_enq_bits_index = '0;
    io_enq_bits_data = '0;
    io_enq_bits_mask = '0;
    io_enq_bits_extra_tlrr_extra_source = '0;
    io_enq_bits_extra_tlrr_extra_size = '0;
    io_deq_ready = '0;
    p_io_enq_ready = '0; tog_io_enq_ready = 1'b0;
    p_io_deq_valid = '0; tog_io_deq_valid = 1'b0;
    p_io_deq_bits_read = '0; tog_io_deq_bits_read = 1'b0;
    p_io_deq_bits_index = '0; tog_io_deq_bits_index = 1'b0;
    p_io_deq_bits_data = '0; tog_io_deq_bits_data = 1'b0;
    p_io_deq_bits_mask = '0; tog_io_deq_bits_mask = 1'b0;
    p_io_deq_bits_extra_tlrr_extra_source = '0; tog_io_deq_bits_extra_tlrr_extra_source = 1'b0;
    p_io_deq_bits_extra_tlrr_extra_size = '0; tog_io_deq_bits_extra_tlrr_extra_size = 1'b0;
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

    if (tog_io_enq_ready) toggled++; else $display("COV: output io_enq_ready never toggled");
    if (tog_io_deq_valid) toggled++; else $display("COV: output io_deq_valid never toggled");
    if (tog_io_deq_bits_read) toggled++; else $display("COV: output io_deq_bits_read never toggled");
    if (tog_io_deq_bits_index) toggled++; else $display("COV: output io_deq_bits_index never toggled");
    if (tog_io_deq_bits_data) toggled++; else $display("COV: output io_deq_bits_data never toggled");
    if (tog_io_deq_bits_mask) toggled++; else $display("COV: output io_deq_bits_mask never toggled");
    if (tog_io_deq_bits_extra_tlrr_extra_source) toggled++; else $display("COV: output io_deq_bits_extra_tlrr_extra_source never toggled");
    if (tog_io_deq_bits_extra_tlrr_extra_size) toggled++; else $display("COV: output io_deq_bits_extra_tlrr_extra_size never toggled");
    $display("Queue1_RegMapperInput_5 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d hi_src_enq=%0d",
             checks, errors, toggled, N_OUT, fires, hi_src_enq);
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
    if (hi_src_enq < MIN_HI_SRC) begin
      $display("TEST FAILED (coverage: source>=8 only %0d enqueues, need >= %0d)",
               hi_src_enq, MIN_HI_SRC);
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
