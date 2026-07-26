// menvcfg UT: golden MenvcfgModule vs readable impl copy (_xs). Random writes
// exercise the PMM/CBIE WARL guards and the reset defaults.
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
  logic [8:0]  g_ro, i_ro;  // {CBIE[1:0],CBCFE,CBZE,PMM[1:0],DTE,PBMTE,STCE}

  MenvcfgModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g_rd),
    .regOut_STCE(g_ro[0]),.regOut_PBMTE(g_ro[1]),.regOut_DTE(g_ro[2]),
    .regOut_PMM(g_ro[4:3]),.regOut_CBZE(g_ro[5]),.regOut_CBCFE(g_ro[6]),.regOut_CBIE(g_ro[8:7]));
  MenvcfgModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i_rd),
    .regOut_STCE(i_ro[0]),.regOut_PBMTE(i_ro[1]),.regOut_DTE(i_ro[2]),
    .regOut_PMM(i_ro[4:3]),.regOut_CBZE(i_ro[5]),.regOut_CBCFE(i_ro[6]),.regOut_CBIE(i_ro[8:7]));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin w_wen <= ($urandom_range(0,1)==0); w_wdata <= {$urandom,$urandom}; end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_ro!==i_ro) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h ro g=%h i=%h",$time,g_rd,i_rd,g_ro,i_ro);
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
