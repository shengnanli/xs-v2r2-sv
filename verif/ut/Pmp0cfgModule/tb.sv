// pmpentrycfg UT: golden Pmp0cfgModule vs readable primitive (_xs).
// Random writes exercise the A-field NA4->NAPOT WARL fixup and the reserved
// W=1,R=0 write-drop rule. Compares rdata (8b) + all regOut fields.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;

  logic [7:0]  g_rd, i_rd;
  logic [5:0]  g_ro, i_ro;  // {L, A[1:0], X, W, R}

  Pmp0cfgModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_R(g_ro[0]),.regOut_W(g_ro[1]),.regOut_X(g_ro[2]),
    .regOut_A(g_ro[4:3]),.regOut_L(g_ro[5]));
  Pmp0cfgModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_R(i_ro[0]),.regOut_W(i_ro[1]),.regOut_X(i_ro[2]),
    .regOut_A(i_ro[4:3]),.regOut_L(i_ro[5]));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      // bias toward low 8 bits so the WARL corners are hit often
      w_wdata <= {$urandom, $urandom} & 64'hFF;
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
