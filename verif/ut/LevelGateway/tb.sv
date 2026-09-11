// 自动生成：scripts/gen_levelgateway.py —— 勿手改
// LevelGateway 双例化逐拍比对：golden LevelGateway vs 可读重写 LevelGateway_xs。
// 激励：随机驱动 interrupt/ready/complete，覆盖 set(interrupt&ready)、
// hold(在途)、clear(complete) 全部 inFlight 转移。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_interrupt;
  logic io_plic_ready;
  logic io_plic_complete;
  wire g_io_plic_valid;
  wire i_io_plic_valid;

  LevelGateway u_g (
    .clock(clock),
    .reset(reset),
    .io_interrupt(io_interrupt),
    .io_plic_valid(g_io_plic_valid),
    .io_plic_ready(io_plic_ready),
    .io_plic_complete(io_plic_complete)
  );

  LevelGateway_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_interrupt(io_interrupt),
    .io_plic_valid(i_io_plic_valid),
    .io_plic_ready(io_plic_ready),
    .io_plic_complete(io_plic_complete)
  );

  task automatic drive_random_inputs();
    // interrupt 多为电平保持 (偶尔翻转)，ready/complete 随机产生握手脉冲
    if ($urandom_range(0, 3) == 0) io_interrupt = ~io_interrupt;
    io_plic_ready    = $urandom_range(0, 1);
    io_plic_complete = ($urandom_range(0, 3) == 0);  // complete 稀疏
  endtask

  task automatic check_outputs();
    `CHECK(io_plic_valid)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_interrupt = '0;
    io_plic_ready = '0;
    io_plic_complete = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("LevelGateway checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
