// 自动生成：scripts/gen_zj_ut.py NewPipelineConnectPipe_25 —— 勿手改
// NewPipelineConnectPipe_25 双例化逐拍比对：golden NewPipelineConnectPipe_25 vs 重写 NewPipelineConnectPipe_25_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  localparam int unsigned NCYCLES     = 120000;
  localparam int unsigned MIN_TOGGLED = 9;
  localparam int unsigned MIN_FIRES   = 30000;
  localparam int unsigned N_OUT       = 9;

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

  logic io_in_valid;
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic [63:0] io_in_bits_src_0;
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic io_in_bits_sqIdx_flag;
  logic [5:0] io_in_bits_sqIdx_value;
  logic io_out_ready;
  logic io_rightOutFire;
  logic io_isFlush;

  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [34:0] g_io_out_bits_fuType;
  wire [34:0] i_io_out_bits_fuType;
  wire [8:0] g_io_out_bits_fuOpType;
  wire [8:0] i_io_out_bits_fuOpType;
  wire [63:0] g_io_out_bits_src_0;
  wire [63:0] i_io_out_bits_src_0;
  wire g_io_out_bits_robIdx_flag;
  wire i_io_out_bits_robIdx_flag;
  wire [7:0] g_io_out_bits_robIdx_value;
  wire [7:0] i_io_out_bits_robIdx_value;
  wire g_io_out_bits_sqIdx_flag;
  wire i_io_out_bits_sqIdx_flag;
  wire [5:0] g_io_out_bits_sqIdx_value;
  wire [5:0] i_io_out_bits_sqIdx_value;

  logic p_io_in_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_ready;
  logic p_io_out_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_valid;
  logic [34:0] p_io_out_bits_fuType;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_fuType;
  logic [8:0] p_io_out_bits_fuOpType;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_fuOpType;
  logic [63:0] p_io_out_bits_src_0;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_src_0;
  logic p_io_out_bits_robIdx_flag;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_robIdx_flag;
  logic [7:0] p_io_out_bits_robIdx_value;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_robIdx_value;
  logic p_io_out_bits_sqIdx_flag;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_sqIdx_flag;
  logic [5:0] p_io_out_bits_sqIdx_value;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_sqIdx_value;

  NewPipelineConnectPipe_25 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_sqIdx_flag(io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(io_in_bits_sqIdx_value),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_fuType(g_io_out_bits_fuType),
    .io_out_bits_fuOpType(g_io_out_bits_fuOpType),
    .io_out_bits_src_0(g_io_out_bits_src_0),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_sqIdx_flag(g_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(g_io_out_bits_sqIdx_value),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
  NewPipelineConnectPipe_25_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_sqIdx_flag(io_in_bits_sqIdx_flag),
    .io_in_bits_sqIdx_value(io_in_bits_sqIdx_value),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_fuType(i_io_out_bits_fuType),
    .io_out_bits_fuOpType(i_io_out_bits_fuOpType),
    .io_out_bits_src_0(i_io_out_bits_src_0),
    .io_out_bits_robIdx_flag(i_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_io_out_bits_robIdx_value),
    .io_out_bits_sqIdx_flag(i_io_out_bits_sqIdx_flag),
    .io_out_bits_sqIdx_value(i_io_out_bits_sqIdx_value),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );

  task automatic drive_random();
    io_in_valid = $urandom % 2;
    io_in_bits_fuType = rnd(35);
    io_in_bits_fuOpType = rnd(9);
    io_in_bits_src_0 = rnd(64);
    io_in_bits_robIdx_flag = $urandom % 2;
    io_in_bits_robIdx_value = rnd(8);
    io_in_bits_sqIdx_flag = $urandom % 2;
    io_in_bits_sqIdx_value = rnd(6);
    io_out_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_rightOutFire = $urandom % 2;
    io_isFlush = $urandom % 2;
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
    if (!$isunknown(g_io_out_bits_fuType)) begin
      checks++;
      if (g_io_out_bits_fuType !== i_io_out_bits_fuType) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_fuType g=%0h i=%0h", $time, g_io_out_bits_fuType, i_io_out_bits_fuType);
      end
    end
    if (!$isunknown(g_io_out_bits_fuOpType)) begin
      checks++;
      if (g_io_out_bits_fuOpType !== i_io_out_bits_fuOpType) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_fuOpType g=%0h i=%0h", $time, g_io_out_bits_fuOpType, i_io_out_bits_fuOpType);
      end
    end
    if (!$isunknown(g_io_out_bits_src_0)) begin
      checks++;
      if (g_io_out_bits_src_0 !== i_io_out_bits_src_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_src_0 g=%0h i=%0h", $time, g_io_out_bits_src_0, i_io_out_bits_src_0);
      end
    end
    if (!$isunknown(g_io_out_bits_robIdx_flag)) begin
      checks++;
      if (g_io_out_bits_robIdx_flag !== i_io_out_bits_robIdx_flag) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_robIdx_flag g=%0h i=%0h", $time, g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag);
      end
    end
    if (!$isunknown(g_io_out_bits_robIdx_value)) begin
      checks++;
      if (g_io_out_bits_robIdx_value !== i_io_out_bits_robIdx_value) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_robIdx_value g=%0h i=%0h", $time, g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value);
      end
    end
    if (!$isunknown(g_io_out_bits_sqIdx_flag)) begin
      checks++;
      if (g_io_out_bits_sqIdx_flag !== i_io_out_bits_sqIdx_flag) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_sqIdx_flag g=%0h i=%0h", $time, g_io_out_bits_sqIdx_flag, i_io_out_bits_sqIdx_flag);
      end
    end
    if (!$isunknown(g_io_out_bits_sqIdx_value)) begin
      checks++;
      if (g_io_out_bits_sqIdx_value !== i_io_out_bits_sqIdx_value) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_sqIdx_value g=%0h i=%0h", $time, g_io_out_bits_sqIdx_value, i_io_out_bits_sqIdx_value);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_in_ready !== p_io_in_ready) tog_io_in_ready = 1'b1;
    p_io_in_ready = g_io_in_ready;
    if (g_io_out_valid !== p_io_out_valid) tog_io_out_valid = 1'b1;
    p_io_out_valid = g_io_out_valid;
    if (g_io_out_bits_fuType !== p_io_out_bits_fuType) tog_io_out_bits_fuType = 1'b1;
    p_io_out_bits_fuType = g_io_out_bits_fuType;
    if (g_io_out_bits_fuOpType !== p_io_out_bits_fuOpType) tog_io_out_bits_fuOpType = 1'b1;
    p_io_out_bits_fuOpType = g_io_out_bits_fuOpType;
    if (g_io_out_bits_src_0 !== p_io_out_bits_src_0) tog_io_out_bits_src_0 = 1'b1;
    p_io_out_bits_src_0 = g_io_out_bits_src_0;
    if (g_io_out_bits_robIdx_flag !== p_io_out_bits_robIdx_flag) tog_io_out_bits_robIdx_flag = 1'b1;
    p_io_out_bits_robIdx_flag = g_io_out_bits_robIdx_flag;
    if (g_io_out_bits_robIdx_value !== p_io_out_bits_robIdx_value) tog_io_out_bits_robIdx_value = 1'b1;
    p_io_out_bits_robIdx_value = g_io_out_bits_robIdx_value;
    if (g_io_out_bits_sqIdx_flag !== p_io_out_bits_sqIdx_flag) tog_io_out_bits_sqIdx_flag = 1'b1;
    p_io_out_bits_sqIdx_flag = g_io_out_bits_sqIdx_flag;
    if (g_io_out_bits_sqIdx_value !== p_io_out_bits_sqIdx_value) tog_io_out_bits_sqIdx_value = 1'b1;
    p_io_out_bits_sqIdx_value = g_io_out_bits_sqIdx_value;
    if ((g_io_in_ready && io_in_valid) ||
        (g_io_out_valid && io_out_ready)) fires++;
  endtask

  initial begin
    io_in_valid = '0;
    io_in_bits_fuType = '0;
    io_in_bits_fuOpType = '0;
    io_in_bits_src_0 = '0;
    io_in_bits_robIdx_flag = '0;
    io_in_bits_robIdx_value = '0;
    io_in_bits_sqIdx_flag = '0;
    io_in_bits_sqIdx_value = '0;
    io_out_ready = '0;
    io_rightOutFire = '0;
    io_isFlush = '0;
    p_io_in_ready = '0; tog_io_in_ready = 1'b0;
    p_io_out_valid = '0; tog_io_out_valid = 1'b0;
    p_io_out_bits_fuType = '0; tog_io_out_bits_fuType = 1'b0;
    p_io_out_bits_fuOpType = '0; tog_io_out_bits_fuOpType = 1'b0;
    p_io_out_bits_src_0 = '0; tog_io_out_bits_src_0 = 1'b0;
    p_io_out_bits_robIdx_flag = '0; tog_io_out_bits_robIdx_flag = 1'b0;
    p_io_out_bits_robIdx_value = '0; tog_io_out_bits_robIdx_value = 1'b0;
    p_io_out_bits_sqIdx_flag = '0; tog_io_out_bits_sqIdx_flag = 1'b0;
    p_io_out_bits_sqIdx_value = '0; tog_io_out_bits_sqIdx_value = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
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
    if (tog_io_out_bits_fuType) toggled++; else $display("COV: output io_out_bits_fuType never toggled");
    if (tog_io_out_bits_fuOpType) toggled++; else $display("COV: output io_out_bits_fuOpType never toggled");
    if (tog_io_out_bits_src_0) toggled++; else $display("COV: output io_out_bits_src_0 never toggled");
    if (tog_io_out_bits_robIdx_flag) toggled++; else $display("COV: output io_out_bits_robIdx_flag never toggled");
    if (tog_io_out_bits_robIdx_value) toggled++; else $display("COV: output io_out_bits_robIdx_value never toggled");
    if (tog_io_out_bits_sqIdx_flag) toggled++; else $display("COV: output io_out_bits_sqIdx_flag never toggled");
    if (tog_io_out_bits_sqIdx_value) toggled++; else $display("COV: output io_out_bits_sqIdx_value never toggled");
    $display("NewPipelineConnectPipe_25 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    if (fires < MIN_FIRES) begin $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
