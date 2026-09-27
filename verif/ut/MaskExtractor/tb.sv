`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [15:0] io_in_mask;
  logic [1:0] io_in_vsew;
  wire [15:0] golden_mask, impl_mask;
  MaskExtractor u_golden (.*,.io_out_mask(golden_mask));
  MaskExtractor_xs u_impl (.*,.io_out_mask(impl_mask));
  task automatic compare_now;
    #1; checks++;
    if (golden_mask !== impl_mask) begin errors++;
      if (errors < 8) $display("mismatch mask=%h vsew=%h golden=%h impl=%h",
        io_in_mask, io_in_vsew, golden_mask, impl_mask);
    end
  endtask
  initial begin
    for (int sew = 0; sew < 4; sew++) begin
      io_in_vsew = sew[1:0];
      io_in_mask = 16'h0001; compare_now();
      io_in_mask = 16'ha55a; compare_now();
      io_in_mask = 16'hffff; compare_now();
    end
    repeat (NCYCLES) begin
      io_in_mask = $urandom; io_in_vsew = $urandom; compare_now();
    end
    $display("MaskExtractor UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
