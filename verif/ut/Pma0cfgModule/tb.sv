// PMA family UT: golden vs readable primitive (_xs) cycle-by-cycle compare.
// Covers config-entry (reset 0x00 and 0x6F), the cfg slice, and addr pass-thru.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic [127:0] cfgRData;
  logic [63:0]  addrRData;

  // ---- Pma0cfg (reset 0x00) ----
  logic [7:0] g0_rd,i0_rd; logic g0_R,g0_W,g0_X,g0_AT,g0_C,g0_L; logic [1:0] g0_A;
  logic i0_R,i0_W,i0_X,i0_AT,i0_C,i0_L; logic [1:0] i0_A;
  Pma0cfgModule    g0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g0_rd),
    .regOut_R(g0_R),.regOut_W(g0_W),.regOut_X(g0_X),.regOut_A(g0_A),.regOut_ATOMIC(g0_AT),.regOut_C(g0_C),.regOut_L(g0_L));
  Pma0cfgModule_xs i0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i0_rd),
    .regOut_R(i0_R),.regOut_W(i0_W),.regOut_X(i0_X),.regOut_A(i0_A),.regOut_ATOMIC(i0_AT),.regOut_C(i0_C),.regOut_L(i0_L));

  // ---- Pma14cfg (reset 0x6F) ----
  logic [7:0] g4_rd,i4_rd; logic g4_R,g4_W,g4_X,g4_AT,g4_C,g4_L; logic [1:0] g4_A;
  logic i4_R,i4_W,i4_X,i4_AT,i4_C,i4_L; logic [1:0] i4_A;
  Pma14cfgModule    g4(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g4_rd),
    .regOut_R(g4_R),.regOut_W(g4_W),.regOut_X(g4_X),.regOut_A(g4_A),.regOut_ATOMIC(g4_AT),.regOut_C(g4_C),.regOut_L(g4_L));
  Pma14cfgModule_xs i4(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i4_rd),
    .regOut_R(i4_R),.regOut_W(i4_W),.regOut_X(i4_X),.regOut_A(i4_A),.regOut_ATOMIC(i4_AT),.regOut_C(i4_C),.regOut_L(i4_L));

  // ---- Pmacfg0 slice ----
  logic [63:0] gc_rd, ic_rd;
  Pmacfg0Module    gc(.rdata(gc_rd),.cfgRData(cfgRData));
  Pmacfg0Module_xs ic(.rdata(ic_rd),.cfgRData(cfgRData));

  // ---- Pmaaddr0 ----
  logic [63:0] ga_rd, ia_rd;
  Pmaaddr0Module    ga(.rdata(ga_rd),.addrRData_0(addrRData));
  Pmaaddr0Module_xs ia(.rdata(ia_rd),.addrRData_0(addrRData));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; cfgRData<='0; addrRData<='0; end
    else begin
      w_wen<=($urandom_range(0,1)==0);
      w_wdata<={$urandom,$urandom};
      cfgRData<={$urandom,$urandom,$urandom,$urandom};
      addrRData<={$urandom,$urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g0_rd!==i0_rd || {g0_R,g0_W,g0_X,g0_A,g0_AT,g0_C,g0_L}!=={i0_R,i0_W,i0_X,i0_A,i0_AT,i0_C,i0_L}) begin
        errors++; if(errors<=30) $display("[%0t] P0 g=%h i=%h",$time,g0_rd,i0_rd); end
      if (g4_rd!==i4_rd || {g4_R,g4_W,g4_X,g4_A,g4_AT,g4_C,g4_L}!=={i4_R,i4_W,i4_X,i4_A,i4_AT,i4_C,i4_L}) begin
        errors++; if(errors<=30) $display("[%0t] P14 g=%h i=%h",$time,g4_rd,i4_rd); end
      if (gc_rd!==ic_rd) begin errors++; if(errors<=30) $display("[%0t] cfg0 g=%h i=%h",$time,gc_rd,ic_rd); end
      if (ga_rd!==ia_rd) begin errors++; if(errors<=30) $display("[%0t] addr0 g=%h i=%h",$time,ga_rd,ia_rd); end
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
