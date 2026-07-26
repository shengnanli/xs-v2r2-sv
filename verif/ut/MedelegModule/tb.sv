// medeleg UT: golden MedelegModule vs readable bespoke core (_xs).
// Full random writes exercise the sparse WARL bit map and the rdata packing
// (reserved-bit holes read as 0). Compares rdata plus all 20 regOut fields
// (packed into a vector for a single compact compare).
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
  logic [19:0] g_ro, i_ro;

  MedelegModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),
    .regOut_EX_IAM(g_ro[0]),.regOut_EX_IAF(g_ro[1]),.regOut_EX_II(g_ro[2]),
    .regOut_EX_BP(g_ro[3]),.regOut_EX_LAM(g_ro[4]),.regOut_EX_LAF(g_ro[5]),
    .regOut_EX_SAM(g_ro[6]),.regOut_EX_SAF(g_ro[7]),.regOut_EX_UCALL(g_ro[8]),
    .regOut_EX_HSCALL(g_ro[9]),.regOut_EX_VSCALL(g_ro[10]),.regOut_EX_IPF(g_ro[11]),
    .regOut_EX_LPF(g_ro[12]),.regOut_EX_SPF(g_ro[13]),.regOut_EX_SWC(g_ro[14]),
    .regOut_EX_HWE(g_ro[15]),.regOut_EX_IGPF(g_ro[16]),.regOut_EX_LGPF(g_ro[17]),
    .regOut_EX_VI(g_ro[18]),.regOut_EX_SGPF(g_ro[19]));
  MedelegModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),
    .regOut_EX_IAM(i_ro[0]),.regOut_EX_IAF(i_ro[1]),.regOut_EX_II(i_ro[2]),
    .regOut_EX_BP(i_ro[3]),.regOut_EX_LAM(i_ro[4]),.regOut_EX_LAF(i_ro[5]),
    .regOut_EX_SAM(i_ro[6]),.regOut_EX_SAF(i_ro[7]),.regOut_EX_UCALL(i_ro[8]),
    .regOut_EX_HSCALL(i_ro[9]),.regOut_EX_VSCALL(i_ro[10]),.regOut_EX_IPF(i_ro[11]),
    .regOut_EX_LPF(i_ro[12]),.regOut_EX_SPF(i_ro[13]),.regOut_EX_SWC(i_ro[14]),
    .regOut_EX_HWE(i_ro[15]),.regOut_EX_IGPF(i_ro[16]),.regOut_EX_LGPF(i_ro[17]),
    .regOut_EX_VI(i_ro[18]),.regOut_EX_SGPF(i_ro[19]));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      w_wdata <= {$urandom, $urandom};
    end
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
