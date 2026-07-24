// Trigger family UT: golden vs readable primitive (_xs) cycle-by-cycle compare.
// Covers tdata read pass-through, mcontrol6 tdata1 WARL, and tdata2 register.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic        canWriteDmode, chainable;
  logic [63:0] tdataRead;

  // ---- Tdata1 read pass-through ----
  logic [63:0] gr_rd, ir_rd, gr_ro, ir_ro;
  Tdata1Module    gr(.rdata(gr_rd),.regOut_ALL(gr_ro),.tdataRead_tdata1(tdataRead));
  Tdata1Module_xs ir(.rdata(ir_rd),.regOut_ALL(ir_ro),.tdataRead_tdata1(tdataRead));

  // ---- Trigger0_Tdata1 WARL ----
  logic [63:0] g1_rd, i1_rd;
  Trigger0_Tdata1Module    g1(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g1_rd),.canWriteDmode(canWriteDmode),.chainable(chainable));
  Trigger0_Tdata1Module_xs i1(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i1_rd),.canWriteDmode(canWriteDmode),.chainable(chainable));

  // ---- Trigger0_Tdata2 register (no reset) ----
  logic [63:0] g2_rd, i2_rd;
  Trigger0_Tdata2Module    g2(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g2_rd));
  Trigger0_Tdata2Module_xs i2(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i2_rd));

  // stimulus: bias type field so mcontrol6 (type==6) path is frequently taken.
  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; canWriteDmode<='0; chainable<='0; tdataRead<='0; end
    else begin
      w_wen <= ($urandom_range(0,1)==0);
      // 50% of the time force the top nibble to 6 (mcontrol6) to exercise WARL.
      if ($urandom_range(0,1)==0)
        w_wdata <= {4'h6, 4'($urandom), {$urandom, $urandom} & 64'h0FFF_FFFF_FFFF_FFFF};
      else
        w_wdata <= {$urandom, $urandom};
      canWriteDmode <= 1'($urandom);
      chainable     <= 1'($urandom);
      tdataRead     <= {$urandom, $urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (gr_rd!==ir_rd || gr_ro!==ir_ro) begin errors++; if(errors<=30) $display("[%0t] Tr g=%h i=%h",$time,gr_rd,ir_rd); end
      if (g1_rd!==i1_rd) begin errors++; if(errors<=30) $display("[%0t] T1 g=%h i=%h",$time,g1_rd,i1_rd); end
      if (g2_rd!==i2_rd) begin errors++; if(errors<=30) $display("[%0t] T2 g=%h i=%h",$time,g2_rd,i2_rd); end
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
