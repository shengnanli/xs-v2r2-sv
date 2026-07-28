// ResetGen 双例化逐拍比对: golden ResetGen vs 可读 xs_ResetGen_core (经 wrapper)。
// reset 既是复位又是唯一数据输入 -> 随机脉冲遍历撤除相位, 比对 o_reset。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit  clock = 0;
  logic reset;
  int  errors = 0;
  int  checks = 0;
  always #5 clock = ~clock;

  wire g_o_reset;
  wire i_o_reset;

  // golden 叶子
  ResetGen u_g (
    .clock  (clock),
    .reset  (reset),
    .o_reset(g_o_reset)
  );
  // 可读核 (直接例化 core, 避免与 golden 同名 wrapper 撞名)
  xs_ResetGen_core u_i (
    .clock  (clock),
    .reset  (reset),
    .o_reset(i_o_reset)
  );

  task automatic check_outputs();
    if (!$isunknown(g_o_reset)) begin
      checks++;
      if (g_o_reset !== i_o_reset) begin
        errors++;
        if (errors <= 30)
          $display("[%0t] MISMATCH o_reset g=%0b i=%0b", $time, g_o_reset, i_o_reset);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    // 初始拉高复位若干拍, 令两侧同步链先置全 1。
    reset = 1'b1;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // 随机复位脉冲: 大多数时间撤除, 偶尔置位, 遍历撤除后 3 拍衰减相位。
      reset <= ($urandom_range(0, 7) == 0);
      @(posedge clock);
      #1 check_outputs();
    end
    $display("ResetGen checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
