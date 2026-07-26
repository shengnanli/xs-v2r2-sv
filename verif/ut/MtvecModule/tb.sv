// tvec family UT: golden vs readable primitive (_xs) cycle-by-cycle compare.
// Exercises the WARL mode legalization (reject modes 2/3) and addr register.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;

  logic [63:0] g_rd, i_rd; logic [1:0] g_mode, i_mode; logic [61:0] g_addr, i_addr;
  MtvecModule    g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_mode(g_mode),.regOut_addr(g_addr));
  MtvecModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_mode(i_mode),.regOut_addr(i_addr));

  // Stimulus: sweep the full mode nibble (incl. reserved 2/3) to exercise WARL.
  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      // Full 64-bit random write; low 2 bits sweep all mode encodings incl.
      // reserved 2/3 so the WARL legalization is exercised.
      w_wdata <= {$urandom, $urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_mode!==i_mode || g_addr!==i_addr) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h mode g=%h i=%h",$time,g_rd,i_rd,g_mode,i_mode);
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
