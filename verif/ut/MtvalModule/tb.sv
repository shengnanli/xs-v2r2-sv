// tval family UT: golden MtvalModule vs readable primitive (_xs).
// Exercises the trap-write port and the OR-of-CSR-write path.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic        trap_valid;
  logic [63:0] trap_bits;

  logic [63:0] g_rd, i_rd, g_all, i_all;
  MtvalModule    g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_ALL(g_all),
    .trapToM_mtval_valid(trap_valid),.trapToM_mtval_bits_ALL(trap_bits));
  MtvalModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_ALL(i_all),
    .trapToM_mtval_valid(trap_valid),.trapToM_mtval_bits_ALL(trap_bits));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; trap_valid<='0; trap_bits<='0; end
    else begin
      w_wen      <= ($urandom_range(0,1)==0);
      w_wdata    <= {$urandom, $urandom};
      trap_valid <= ($urandom_range(0,3)==0);
      trap_bits  <= {$urandom, $urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_all!==i_all) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h all g=%h i=%h",$time,g_rd,i_rd,g_all,i_all);
      end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
