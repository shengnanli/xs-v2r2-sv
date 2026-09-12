// 自动生成：scripts/gen_zj_ut.py NewPipelineConnectPipe_33 —— 勿手改
// NewPipelineConnectPipe_33 双例化逐拍比对：golden NewPipelineConnectPipe_33 vs 重写 NewPipelineConnectPipe_33_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 120000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 120000;
  localparam int unsigned MIN_TOGGLED = 7;
  localparam int unsigned MIN_FIRES   = 30000;
  localparam int unsigned N_OUT       = 7;

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
  logic [49:0] io_in_bits_vaddr;
  logic [127:0] io_in_bits_data;
  logic [15:0] io_in_bits_mask;
  logic [47:0] io_in_bits_addr;
  logic io_in_bits_vecValid;
  logic io_out_ready;
  logic io_rightOutFire;

  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [49:0] g_io_out_bits_vaddr;
  wire [49:0] i_io_out_bits_vaddr;
  wire [127:0] g_io_out_bits_data;
  wire [127:0] i_io_out_bits_data;
  wire [15:0] g_io_out_bits_mask;
  wire [15:0] i_io_out_bits_mask;
  wire [47:0] g_io_out_bits_addr;
  wire [47:0] i_io_out_bits_addr;
  wire g_io_out_bits_vecValid;
  wire i_io_out_bits_vecValid;

  logic p_io_in_ready;   // 上一拍值（toggle 统计）
  bit tog_io_in_ready;
  logic p_io_out_valid;   // 上一拍值（toggle 统计）
  bit tog_io_out_valid;
  logic [49:0] p_io_out_bits_vaddr;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_vaddr;
  logic [127:0] p_io_out_bits_data;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_data;
  logic [15:0] p_io_out_bits_mask;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_mask;
  logic [47:0] p_io_out_bits_addr;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_addr;
  logic p_io_out_bits_vecValid;   // 上一拍值（toggle 统计）
  bit tog_io_out_bits_vecValid;

  NewPipelineConnectPipe_33 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_data(io_in_bits_data),
    .io_in_bits_mask(io_in_bits_mask),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_vecValid(io_in_bits_vecValid),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_vaddr(g_io_out_bits_vaddr),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_mask(g_io_out_bits_mask),
    .io_out_bits_addr(g_io_out_bits_addr),
    .io_out_bits_vecValid(g_io_out_bits_vecValid),
    .io_rightOutFire(io_rightOutFire)
  );
  NewPipelineConnectPipe_33_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_data(io_in_bits_data),
    .io_in_bits_mask(io_in_bits_mask),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_vecValid(io_in_bits_vecValid),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_vaddr(i_io_out_bits_vaddr),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_mask(i_io_out_bits_mask),
    .io_out_bits_addr(i_io_out_bits_addr),
    .io_out_bits_vecValid(i_io_out_bits_vecValid),
    .io_rightOutFire(io_rightOutFire)
  );

  task automatic drive_random();
    io_in_valid = $urandom % 2;
    io_in_bits_vaddr = rnd(50);
    io_in_bits_data = rnd(128);
    io_in_bits_mask = rnd(16);
    io_in_bits_addr = rnd(48);
    io_in_bits_vecValid = $urandom % 2;
    io_out_ready = (($urandom % 4) != 0);            // 75% 高：制造反压
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
    if (!$isunknown(g_io_out_bits_vaddr)) begin
      checks++;
      if (g_io_out_bits_vaddr !== i_io_out_bits_vaddr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_vaddr g=%0h i=%0h", $time, g_io_out_bits_vaddr, i_io_out_bits_vaddr);
      end
    end
    if (!$isunknown(g_io_out_bits_data)) begin
      checks++;
      if (g_io_out_bits_data !== i_io_out_bits_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_data g=%0h i=%0h", $time, g_io_out_bits_data, i_io_out_bits_data);
      end
    end
    if (!$isunknown(g_io_out_bits_mask)) begin
      checks++;
      if (g_io_out_bits_mask !== i_io_out_bits_mask) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_mask g=%0h i=%0h", $time, g_io_out_bits_mask, i_io_out_bits_mask);
      end
    end
    if (!$isunknown(g_io_out_bits_addr)) begin
      checks++;
      if (g_io_out_bits_addr !== i_io_out_bits_addr) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_addr g=%0h i=%0h", $time, g_io_out_bits_addr, i_io_out_bits_addr);
      end
    end
    if (!$isunknown(g_io_out_bits_vecValid)) begin
      checks++;
      if (g_io_out_bits_vecValid !== i_io_out_bits_vecValid) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_out_bits_vecValid g=%0h i=%0h", $time, g_io_out_bits_vecValid, i_io_out_bits_vecValid);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_in_ready !== p_io_in_ready) tog_io_in_ready = 1'b1;
    p_io_in_ready = g_io_in_ready;
    if (g_io_out_valid !== p_io_out_valid) tog_io_out_valid = 1'b1;
    p_io_out_valid = g_io_out_valid;
    if (g_io_out_bits_vaddr !== p_io_out_bits_vaddr) tog_io_out_bits_vaddr = 1'b1;
    p_io_out_bits_vaddr = g_io_out_bits_vaddr;
    if (g_io_out_bits_data !== p_io_out_bits_data) tog_io_out_bits_data = 1'b1;
    p_io_out_bits_data = g_io_out_bits_data;
    if (g_io_out_bits_mask !== p_io_out_bits_mask) tog_io_out_bits_mask = 1'b1;
    p_io_out_bits_mask = g_io_out_bits_mask;
    if (g_io_out_bits_addr !== p_io_out_bits_addr) tog_io_out_bits_addr = 1'b1;
    p_io_out_bits_addr = g_io_out_bits_addr;
    if (g_io_out_bits_vecValid !== p_io_out_bits_vecValid) tog_io_out_bits_vecValid = 1'b1;
    p_io_out_bits_vecValid = g_io_out_bits_vecValid;
    if ((g_io_in_ready && io_in_valid) ||
        (g_io_out_valid && io_out_ready)) fires++;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_in_valid = '0;
    io_in_bits_vaddr = '0;
    io_in_bits_data = '0;
    io_in_bits_mask = '0;
    io_in_bits_addr = '0;
    io_in_bits_vecValid = '0;
    io_out_ready = '0;
    io_rightOutFire = '0;
    p_io_in_ready = '0; tog_io_in_ready = 1'b0;
    p_io_out_valid = '0; tog_io_out_valid = 1'b0;
    p_io_out_bits_vaddr = '0; tog_io_out_bits_vaddr = 1'b0;
    p_io_out_bits_data = '0; tog_io_out_bits_data = 1'b0;
    p_io_out_bits_mask = '0; tog_io_out_bits_mask = 1'b0;
    p_io_out_bits_addr = '0; tog_io_out_bits_addr = 1'b0;
    p_io_out_bits_vecValid = '0; tog_io_out_bits_vecValid = 1'b0;
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
    if (tog_io_out_bits_vaddr) toggled++; else $display("COV: output io_out_bits_vaddr never toggled");
    if (tog_io_out_bits_data) toggled++; else $display("COV: output io_out_bits_data never toggled");
    if (tog_io_out_bits_mask) toggled++; else $display("COV: output io_out_bits_mask never toggled");
    if (tog_io_out_bits_addr) toggled++; else $display("COV: output io_out_bits_addr never toggled");
    if (tog_io_out_bits_vecValid) toggled++; else $display("COV: output io_out_bits_vecValid never toggled");
    $display("NewPipelineConnectPipe_33 checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    if (fires < MIN_FIRES) begin $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, MIN_FIRES); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
