`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [8:0] io_in_fuOpType;
  logic [1:0] io_in_vsew;
  wire [3:0] golden_vs1, golden_vs2, impl_vs1, impl_vs2;

  VIMacSrcTypeModule u_golden (
    .io_in_fuOpType, .io_in_vsew,
    .io_out_vs1Type(golden_vs1), .io_out_vs2Type(golden_vs2)
  );
  VIMacSrcTypeModule_xs u_impl (
    .io_in_fuOpType, .io_in_vsew,
    .io_out_vs1Type(impl_vs1), .io_out_vs2Type(impl_vs2)
  );

  task automatic compare_now;
    #1; checks++;
    if ((golden_vs1 !== impl_vs1) || (golden_vs2 !== impl_vs2)) begin
      errors++;
      if (errors < 8)
        $display("mismatch op=%h vsew=%h golden=%h/%h impl=%h/%h",
                 io_in_fuOpType, io_in_vsew,
                 golden_vs1, golden_vs2, impl_vs1, impl_vs2);
    end
  endtask

  initial begin
    for (int op = 0; op < 512; op++) begin
      for (int sew = 0; sew < 4; sew++) begin
        io_in_fuOpType = op[8:0];
        io_in_vsew = sew[1:0];
        compare_now();
      end
    end
    repeat (NCYCLES) begin
      io_in_fuOpType = $urandom;
      io_in_vsew = $urandom;
      compare_now();
    end
    $display("VIMacSrcTypeModule UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
