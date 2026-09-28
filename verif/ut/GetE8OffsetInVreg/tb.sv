`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [3:0] in_eewOH;
  logic [6:0] in_idx;
  wire [3:0] golden_offset, impl_offset;

  GetE8OffsetInVreg u_golden (.*,.out_offset(golden_offset));
  GetE8OffsetInVreg_xs u_impl (.*,.out_offset(impl_offset));

  task automatic compare_now;
    #1; checks++;
    if (golden_offset !== impl_offset) begin
      errors++;
      if (errors < 8)
        $display("mismatch eewOH=%h idx=%h golden=%h impl=%h",
                 in_eewOH, in_idx, golden_offset, impl_offset);
    end
  endtask

  initial begin
    for (int eew = 0; eew < 4; eew++) begin
      in_eewOH = 4'b0001 << eew;
      for (int idx = 0; idx < 128; idx++) begin
        in_idx = idx[6:0];
        compare_now();
      end
    end
    repeat (NCYCLES) begin
      in_eewOH = $urandom;
      in_idx = $urandom;
      compare_now();
    end
    $display("GetE8OffsetInVreg UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
