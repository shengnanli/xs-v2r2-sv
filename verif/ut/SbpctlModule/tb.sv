// sbpctl UT: golden SbpctlModule vs readable impl copy (_xs). Reset defaults are
// all-ones; random writes exercise every enable bit.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;

  logic [63:0] g_rd, i_rd;
  logic [6:0]  g_ro, i_ro;

  SbpctlModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_LOOP_ENABLE(g_ro[6]),.regOut_RAS_ENABLE(g_ro[5]),
    .regOut_SC_ENABLE(g_ro[4]),.regOut_TAGE_ENABLE(g_ro[3]),.regOut_BIM_ENABLE(g_ro[2]),
    .regOut_BTB_ENABLE(g_ro[1]),.regOut_UBTB_ENABLE(g_ro[0]));
  SbpctlModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_LOOP_ENABLE(i_ro[6]),.regOut_RAS_ENABLE(i_ro[5]),
    .regOut_SC_ENABLE(i_ro[4]),.regOut_TAGE_ENABLE(i_ro[3]),.regOut_BIM_ENABLE(i_ro[2]),
    .regOut_BTB_ENABLE(i_ro[1]),.regOut_UBTB_ENABLE(i_ro[0]));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin w_wen <= ($urandom_range(0,1)==0); w_wdata <= {$urandom,$urandom}; end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_ro!==i_ro) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h",$time,g_rd,i_rd);
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
