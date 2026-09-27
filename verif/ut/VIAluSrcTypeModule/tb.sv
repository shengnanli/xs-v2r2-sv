`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0;
  logic [8:0] io_in_fuOpType;
  logic [1:0] io_in_vsew;
  logic io_in_isExt, io_in_isDstMask;
  wire [3:0] g_vs1, g_vs2, g_vd, i_vs1, i_vs2, i_vd;
  wire g_f2, g_f4, g_f8, i_f2, i_f4, i_f8;
  VIAluSrcTypeModule u_golden (.io_in_fuOpType,.io_in_vsew,.io_in_isExt,.io_in_isDstMask,
    .io_out_vs1Type(g_vs1),.io_out_vs2Type(g_vs2),.io_out_vdType(g_vd),
    .io_out_isVextF2(g_f2),.io_out_isVextF4(g_f4),.io_out_isVextF8(g_f8));
  VIAluSrcTypeModule_xs u_impl (.io_in_fuOpType,.io_in_vsew,.io_in_isExt,.io_in_isDstMask,
    .io_out_vs1Type(i_vs1),.io_out_vs2Type(i_vs2),.io_out_vdType(i_vd),
    .io_out_isVextF2(i_f2),.io_out_isVextF4(i_f4),.io_out_isVextF8(i_f8));
  task automatic compare_now;
    #1; checks++;
    if ({g_vs1,g_vs2,g_vd,g_f2,g_f4,g_f8} !== {i_vs1,i_vs2,i_vd,i_f2,i_f4,i_f8}) begin
      errors++;
      if (errors < 8) $display("mismatch op=%h sew=%h ext=%b mask=%b g=%h/%h/%h/%b%b%b i=%h/%h/%h/%b%b%b",
        io_in_fuOpType,io_in_vsew,io_in_isExt,io_in_isDstMask,
        g_vs1,g_vs2,g_vd,g_f2,g_f4,g_f8,i_vs1,i_vs2,i_vd,i_f2,i_f4,i_f8);
    end
  endtask
  initial begin
    for (int op = 0; op < 512; op++) for (int sew = 0; sew < 4; sew++)
      for (int flags = 0; flags < 4; flags++) begin
        io_in_fuOpType=op[8:0]; io_in_vsew=sew[1:0];
        {io_in_isExt,io_in_isDstMask}=flags[1:0]; compare_now();
      end
    repeat (NCYCLES) begin
      io_in_fuOpType=$urandom; io_in_vsew=$urandom;
      io_in_isExt=$urandom; io_in_isDstMask=$urandom; compare_now();
    end
    $display("VIAluSrcTypeModule UT: checks=%0d errors=%0d",checks,errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
