// iselect UT: golden Miselect(9b) + Siselect(13b) vs readable primitive (_xs).
// Random writes bias toward the IMSIC-range boundary (0x6F..0x100) so the
// range comparators and the write-high-bit guard are exercised.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;

  // Machine (9-bit)
  logic [63:0] gm_rd, im_rd; logic [8:0] gm_ro, im_ro; logic gm_ir, im_ir;
  // Supervisor (13-bit)
  logic [63:0] gs_rd, is_rd; logic [12:0] gs_ro, is_ro; logic gs_ir, is_ir;

  MiselectModule    gm(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(gm_rd),.regOut_ALL(gm_ro),.inIMSICRange(gm_ir));
  MiselectModule_xs im(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(im_rd),.regOut_ALL(im_ro),.inIMSICRange(im_ir));
  SiselectModule    gs(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(gs_rd),.regOut_ALL(gs_ro),.inIMSICRange(gs_ir));
  SiselectModule_xs is(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(is_rd),.regOut_ALL(is_ro),.inIMSICRange(is_ir));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; end
    else begin
      w_wen   <= ($urandom_range(0,1)==0);
      // bias to low 14 bits around the range boundary
      w_wdata <= {$urandom, $urandom} & 64'h3FFF;
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (gm_rd!==im_rd || gm_ro!==im_ro || gm_ir!==im_ir ||
          gs_rd!==is_rd || gs_ro!==is_ro || gs_ir!==is_ir) begin
        errors++;
        if(errors<=30) $display("[%0t] M rd g=%h i=%h ir g=%b i=%b | S rd g=%h i=%h ir g=%b i=%b",
          $time,gm_rd,im_rd,gm_ir,im_ir,gs_rd,is_rd,gs_ir,is_ir);
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
