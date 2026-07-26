// satp UT: golden SatpModule vs readable impl copy (_xs). Biases MODE nibble to
// legal/illegal values so the WARL drop-on-illegal-MODE path is exercised.
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
  logic [3:0]  g_mode, i_mode;
  logic [15:0] g_asid, i_asid;
  logic [43:0] g_ppn, i_ppn;

  SatpModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_MODE(g_mode),.regOut_ASID(g_asid),.regOut_PPN(g_ppn));
  SatpModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_MODE(i_mode),.regOut_ASID(i_asid),.regOut_PPN(i_ppn));

  logic [3:0]  modesel, modenib;
  logic [59:0] lowbits;
  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      // pick MODE nibble from {0,8,9,random} to hit both legal and illegal
      modesel = $urandom_range(0,3);
      modenib = (modesel==0) ? 4'h0 : (modesel==1) ? 4'h8 : (modesel==2) ? 4'h9 : $urandom_range(0,15);
      lowbits = {$urandom, $urandom};
      w_wdata <= {modenib, lowbits};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_mode!==i_mode || g_asid!==i_asid || g_ppn!==i_ppn) begin
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
