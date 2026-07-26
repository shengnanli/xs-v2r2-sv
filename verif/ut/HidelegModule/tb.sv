// hideleg UT: golden HidelegModule vs readable bespoke core (_xs).
// Random writes exercise the 4 writable VS-interrupt bits; random mideleg_*
// inputs exercise the LCOFI output gate. Compares rdata + all 11 regOut fields.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic        md_ssi, md_sti, md_sei, md_lcofi;

  logic [63:0] g_rd, i_rd;
  logic [10:0] g_ro, i_ro;

  HidelegModule g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),
    .regOut_SSI(g_ro[0]),.regOut_VSSI(g_ro[1]),.regOut_MSI(g_ro[2]),
    .regOut_STI(g_ro[3]),.regOut_VSTI(g_ro[4]),.regOut_MTI(g_ro[5]),
    .regOut_SEI(g_ro[6]),.regOut_VSEI(g_ro[7]),.regOut_MEI(g_ro[8]),
    .regOut_SGEI(g_ro[9]),.regOut_LCOFI(g_ro[10]),
    .mideleg_SSI(md_ssi),.mideleg_STI(md_sti),.mideleg_SEI(md_sei),.mideleg_LCOFI(md_lcofi));
  HidelegModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),
    .regOut_SSI(i_ro[0]),.regOut_VSSI(i_ro[1]),.regOut_MSI(i_ro[2]),
    .regOut_STI(i_ro[3]),.regOut_VSTI(i_ro[4]),.regOut_MTI(i_ro[5]),
    .regOut_SEI(i_ro[6]),.regOut_VSEI(i_ro[7]),.regOut_MEI(i_ro[8]),
    .regOut_SGEI(i_ro[9]),.regOut_LCOFI(i_ro[10]),
    .mideleg_SSI(md_ssi),.mideleg_STI(md_sti),.mideleg_SEI(md_sei),.mideleg_LCOFI(md_lcofi));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; {md_ssi,md_sti,md_sei,md_lcofi}<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      w_wdata <= {$urandom, $urandom};
      {md_ssi,md_sti,md_sei,md_lcofi} <= $urandom_range(0,15);
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
