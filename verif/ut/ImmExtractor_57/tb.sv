`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [31:0] io_in_imm;
  logic [3:0] io_in_immType;
  wire [63:0] golden_imm, impl_imm;
  ImmExtractor_57 u_golden (.*,.io_out_imm(golden_imm));
  ImmExtractor_57_xs u_impl (.*,.io_out_imm(impl_imm));
  task automatic compare_now;
    #1; checks++;
    if (golden_imm !== impl_imm) begin errors++;
      if (errors < 8) $display("mismatch imm=%h type=%h golden=%h impl=%h",
        io_in_imm, io_in_immType, golden_imm, impl_imm);
    end
  endtask
  initial begin
    for (int typ = 0; typ < 16; typ++) begin
      io_in_immType = typ[3:0];
      io_in_imm = 32'h0000_07ff; compare_now();
      io_in_imm = 32'hffff_f800; compare_now();
      io_in_imm = 32'ha5a5_5a5a; compare_now();
    end
    repeat (NCYCLES) begin
      io_in_imm = $urandom; io_in_immType = $urandom; compare_now();
    end
    $display("ImmExtractor_57 UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
