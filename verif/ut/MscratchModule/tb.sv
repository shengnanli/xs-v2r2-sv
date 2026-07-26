// scratch family UT: golden MscratchModule vs readable primitive (_xs).
// Golden has NO reset, so both regs power up X; we force a write in the first
// post-reset cycle to seed both to the same known value, then compare. Checks
// are gated until after the seeding write has committed.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  bit seeded = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;

  logic [63:0] g_rd, i_rd, g_all, i_all;
  MscratchModule    g(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_ALL(g_all));
  MscratchModule_xs i(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_ALL(i_all));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else if (!seeded) begin
      // First post-reset cycle: force a write to seed both regs identically.
      w_wen   <= 1'b1;
      w_wdata <= {$urandom, $urandom};
      seeded  <= 1'b1;
    end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      w_wdata <= {$urandom, $urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    // Skip cyc 1 (the seeding write drives on this negedge, commits next posedge).
    if (cyc > 2) begin
      #4; checks++;
      if (g_rd!==i_rd || g_all!==i_all) begin
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
