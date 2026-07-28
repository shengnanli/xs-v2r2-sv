// IntBuffer 双例化逐拍比对: golden IntBuffer vs 可读 xs_IntBuffer_core。
// 随机中断脉冲, 比对 auto_out_0 (单拍延迟)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit  clock = 0;
  bit  reset;
  logic auto_in_0;
  int  errors = 0;
  int  checks = 0;
  always #5 clock = ~clock;

  wire g_auto_out_0;
  wire i_auto_out_0;

  IntBuffer u_g (
    .clock     (clock),
    .reset     (reset),
    .auto_in_0 (auto_in_0),
    .auto_out_0(g_auto_out_0)
  );
  xs_IntBuffer_core u_i (
    .clock     (clock),
    .reset     (reset),
    .auto_in_0 (auto_in_0),
    .auto_out_0(i_auto_out_0)
  );

  task automatic check_outputs();
    if (!$isunknown(g_auto_out_0)) begin
      checks++;
      if (g_auto_out_0 !== i_auto_out_0) begin
        errors++;
        if (errors <= 30)
          $display("[%0t] MISMATCH auto_out_0 g=%0b i=%0b", $time, g_auto_out_0, i_auto_out_0);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_0 = 1'b0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      auto_in_0 <= $urandom_range(0, 1);
      @(posedge clock);
      #1 check_outputs();
    end
    $display("IntBuffer checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
