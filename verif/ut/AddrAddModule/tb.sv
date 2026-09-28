`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  bit clk = 0;
  always #5 clk = ~clk;

  logic [50:0] io_pcExtend;
  logic io_taken;
  logic [31:0] io_imm;
  logic [4:0] io_nextPcOffset;
  wire [63:0] golden_target, impl_target;

  AddrAddModule u_golden (.*,.io_target(golden_target));
  AddrAddModule_xs u_impl (.*,.io_target(impl_target));

  task automatic compare_now;
    #1; checks++;
    if (golden_target !== impl_target) begin
      errors++;
      if (errors < 8)
        $display("mismatch pc=%h taken=%b imm=%h off=%h golden=%h impl=%h",
                 io_pcExtend, io_taken, io_imm, io_nextPcOffset,
                 golden_target, impl_target);
    end
  endtask

  initial begin
    io_pcExtend = '0; io_taken = 0; io_imm = '0; io_nextPcOffset = 0;
    compare_now();
    io_pcExtend = 51'h7_ffff_ffff_fff; io_taken = 0; io_nextPcOffset = 31;
    compare_now();
    io_pcExtend = 51'h4_0000_0000_000; io_taken = 1; io_imm = 32'h0000_3fff;
    compare_now();
    io_imm = 32'h0000_4000;
    compare_now();
    repeat (NCYCLES) begin
      io_pcExtend = {$urandom, $urandom} & 51'h7_ffff_ffff_fff;
      io_taken = $urandom;
      io_imm = $urandom;
      io_nextPcOffset = $urandom;
      compare_now();
    end
    $display("AddrAddModule UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
