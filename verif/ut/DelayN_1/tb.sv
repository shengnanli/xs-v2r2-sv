// =============================================================================
// tb —— DelayN_1 UT: golden DelayN_1 (u_g) vs 可读核 DelayN_1_xs (u_i) 逐拍比对。
// DelayN_1 = 4 级 1-bit 移位链(无 reset)。每拍随机驱动 io_in, 上升沿后比对 io_out。
// 上电先跑若干拍填满流水(消除两侧寄存器 X)。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in;
  logic g_out, i_out;

  DelayN_1    u_g (.clock(clk), .io_in(io_in), .io_out(g_out));
  DelayN_1_xs u_i (.clock(clk), .io_in(io_in), .io_out(i_out));

  task automatic drive_inputs();
    io_in = $urandom;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_out) && (g_out) !== (i_out)) begin
      errors++;
      if (errors <= 60) $display("[%0t] io_out g=%b i=%b", $time, g_out, i_out);
    end
    checks++;
  endtask

  initial begin
    // 上电填满流水(无 reset, 靠先驱动几拍已知值把两侧 X 冲掉)。
    io_in = 0;
    repeat (8) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();      // negedge 后驱动, 远离上升采样沿
      @(posedge clk);      // 寄存器在此沿更新
      #1 check_outputs();  // 稳定后比对
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
