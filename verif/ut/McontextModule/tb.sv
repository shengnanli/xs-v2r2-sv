// mcontext UT: golden McontextModule vs readable impl copy (_xs).
// Exercises both write paths (w_wen priority over fromHcontext_valid).
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen, fh_valid;
  logic [63:0] w_wdata;
  logic [13:0] fh_bits;

  logic [13:0] g_rd, i_rd, g_ro, i_ro, g_to, i_to;

  McontextModule g(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_HCONTEXT(g_ro),
    .fromHcontext_valid(fh_valid),.fromHcontext_bits_HCONTEXT(fh_bits),
    .toHcontext_HCONTEXT(g_to));
  McontextModule_xs i(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_HCONTEXT(i_ro),
    .fromHcontext_valid(fh_valid),.fromHcontext_bits_HCONTEXT(fh_bits),
    .toHcontext_HCONTEXT(i_to));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; fh_valid<='0; w_wdata<='0; fh_bits<='0; end
    else begin
      w_wen    <= ($urandom_range(0,1)==0);
      fh_valid <= ($urandom_range(0,1)==0);
      w_wdata  <= {$urandom, $urandom};
      fh_bits  <= $urandom;
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_ro!==i_ro || g_to!==i_to) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h",$time,g_rd,i_rd);
      end
    end
  end

  initial begin
    // no reset port on mcontext; prime the register with a known write first
    rst = 1; w_wen=0; fh_valid=0; w_wdata=0; fh_bits=0;
    repeat (3) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
