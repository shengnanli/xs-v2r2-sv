`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic io_sign_0, io_sign_1, io_sign_2, io_sign_3;
  wire [4:0] golden_q, impl_q;

  SignDec u_golden (.*,.io_q(golden_q));
  SignDec_xs u_impl (.*,.io_q(impl_q));

  task automatic compare_now;
    #1; checks++;
    if (golden_q !== impl_q) begin
      errors++;
      if (errors < 8)
        $display("mismatch signs=%b%b%b%b golden=%h impl=%h",
                 io_sign_3, io_sign_2, io_sign_1, io_sign_0, golden_q, impl_q);
    end
  endtask

  initial begin
    for (int signs = 0; signs < 16; signs++) begin
      {io_sign_3, io_sign_2, io_sign_1, io_sign_0} = signs[3:0];
      compare_now();
    end
    repeat (NCYCLES) begin
      {io_sign_3, io_sign_2, io_sign_1, io_sign_0} = $urandom;
      compare_now();
    end
    $display("SignDec UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
