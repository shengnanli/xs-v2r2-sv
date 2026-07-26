// counteren UT: golden McounterenModule vs readable primitive (_xs).
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
  logic [31:0] g_ro, i_ro;  // {HPM[28:0], IR, TM, CY}

  McounterenModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_CY(g_ro[0]),.regOut_TM(g_ro[1]),.regOut_IR(g_ro[2]),.regOut_HPM(g_ro[31:3]));
  McounterenModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_CY(i_ro[0]),.regOut_TM(i_ro[1]),.regOut_IR(i_ro[2]),.regOut_HPM(i_ro[31:3]));

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
