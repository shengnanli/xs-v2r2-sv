`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [5:0] io_shiftNum;
  logic [63:0] io_in;
  logic io_msb;
  wire [63:0] golden_out, impl_out;

  RightShifter u_golden (.*,.io_out(golden_out));
  RightShifter_xs u_impl (.*,.io_out(impl_out));

  task automatic compare_now;
    #1; checks++;
    if (golden_out !== impl_out) begin
      errors++;
      if (errors < 8)
        $display("mismatch shift=%0d in=%h fill=%b golden=%h impl=%h",
                 io_shiftNum, io_in, io_msb, golden_out, impl_out);
    end
  endtask

  initial begin
    for (int fill = 0; fill < 2; fill++) begin
      io_msb = fill;
      io_in = 64'h8123_4567_89ab_cdef;
      for (int shift = 0; shift < 64; shift++) begin
        io_shiftNum = shift[5:0];
        compare_now();
      end
    end
    repeat (NCYCLES) begin
      io_shiftNum = $urandom;
      io_in = {$urandom, $urandom};
      io_msb = $urandom;
      compare_now();
    end
    $display("RightShifter UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
