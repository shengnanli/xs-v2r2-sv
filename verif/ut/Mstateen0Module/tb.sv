// Stateen family UT: golden vs readable primitive (_xs) cycle-by-cycle compare.
// Covers the 5 register/logic-bearing shapes (the constant-zero Sstateen{1,2,3}
// are trivially equal and covered by FM only).
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  // shared stimulus
  logic        w_wen;
  logic [63:0] w_wdata;
  // masks / delegation
  logic mSE0, mENVCFG, mCSRIND, mAIA, mIMSIC, mCONTEXT, mC;
  logic hJVT, hFCSR, hC, hSE0, hENVCFG, hCSRIND, hAIA, hIMSIC, hCONTEXT;
  logic m1SE;
  logic privV;

  // ---- Mstateen0 ----
  logic [63:0] g0_rd, i0_rd;
  logic g0_SE0,g0_ENV,g0_CS,g0_AIA,g0_IM,g0_CT,g0_C;
  logic i0_SE0,i0_ENV,i0_CS,i0_AIA,i0_IM,i0_CT,i0_C;
  Mstateen0Module    g0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g0_rd),
    .regOut_SE0(g0_SE0),.regOut_ENVCFG(g0_ENV),.regOut_CSRIND(g0_CS),.regOut_AIA(g0_AIA),
    .regOut_IMSIC(g0_IM),.regOut_CONTEXT(g0_CT),.regOut_C(g0_C));
  Mstateen0Module_xs i0(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i0_rd),
    .regOut_SE0(i0_SE0),.regOut_ENVCFG(i0_ENV),.regOut_CSRIND(i0_CS),.regOut_AIA(i0_AIA),
    .regOut_IMSIC(i0_IM),.regOut_CONTEXT(i0_CT),.regOut_C(i0_C));

  // ---- Mstateen1 ----
  logic [63:0] g1_rd, i1_rd; logic g1_SE, i1_SE;
  Mstateen1Module    g1(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(g1_rd),.regOut_SE(g1_SE));
  Mstateen1Module_xs i1(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(i1_rd),.regOut_SE(i1_SE));

  // ---- Hstateen0 ----
  logic [63:0] gh_rd, ih_rd;
  logic gh_JVT,gh_FC,gh_C,gh_SE0,gh_ENV,gh_CS,gh_AIA,gh_IM,gh_CT;
  logic ih_JVT,ih_FC,ih_C,ih_SE0,ih_ENV,ih_CS,ih_AIA,ih_IM,ih_CT;
  Hstateen0Module    gh(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(gh_rd),
    .regOut_JVT(gh_JVT),.regOut_FCSR(gh_FC),.regOut_C(gh_C),.regOut_SE0(gh_SE0),.regOut_ENVCFG(gh_ENV),
    .regOut_CSRIND(gh_CS),.regOut_AIA(gh_AIA),.regOut_IMSIC(gh_IM),.regOut_CONTEXT(gh_CT),
    .fromMstateen0_SE0(mSE0),.fromMstateen0_ENVCFG(mENVCFG),.fromMstateen0_CSRIND(mCSRIND),
    .fromMstateen0_AIA(mAIA),.fromMstateen0_IMSIC(mIMSIC),.fromMstateen0_CONTEXT(mCONTEXT),.fromMstateen0_C(mC));
  Hstateen0Module_xs ih(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(ih_rd),
    .regOut_JVT(ih_JVT),.regOut_FCSR(ih_FC),.regOut_C(ih_C),.regOut_SE0(ih_SE0),.regOut_ENVCFG(ih_ENV),
    .regOut_CSRIND(ih_CS),.regOut_AIA(ih_AIA),.regOut_IMSIC(ih_IM),.regOut_CONTEXT(ih_CT),
    .fromMstateen0_SE0(mSE0),.fromMstateen0_ENVCFG(mENVCFG),.fromMstateen0_CSRIND(mCSRIND),
    .fromMstateen0_AIA(mAIA),.fromMstateen0_IMSIC(mIMSIC),.fromMstateen0_CONTEXT(mCONTEXT),.fromMstateen0_C(mC));

  // ---- Hstateen1 (no reset) ----
  logic [63:0] gh1_rd, ih1_rd; logic gh1_SE, ih1_SE;
  Hstateen1Module    gh1(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(gh1_rd),.regOut_SE(gh1_SE),.fromMstateen1_SE(m1SE));
  Hstateen1Module_xs ih1(.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(ih1_rd),.regOut_SE(ih1_SE),.fromMstateen1_SE(m1SE));

  // ---- Sstateen0 ----
  logic [31:0] gs_rd, is_rd; logic gs_JVT,gs_FC,gs_C, is_JVT,is_FC,is_C;
  Sstateen0Module    gs(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(gs_rd),
    .regOut_JVT(gs_JVT),.regOut_FCSR(gs_FC),.regOut_C(gs_C),
    .fromMstateen0_SE0(mSE0),.fromMstateen0_ENVCFG(mENVCFG),.fromMstateen0_CSRIND(mCSRIND),
    .fromMstateen0_AIA(mAIA),.fromMstateen0_IMSIC(mIMSIC),.fromMstateen0_CONTEXT(mCONTEXT),.fromMstateen0_C(mC),
    .fromHstateen0_JVT(hJVT),.fromHstateen0_FCSR(hFCSR),.fromHstateen0_C(hC),.fromHstateen0_SE0(hSE0),
    .fromHstateen0_ENVCFG(hENVCFG),.fromHstateen0_CSRIND(hCSRIND),.fromHstateen0_AIA(hAIA),
    .fromHstateen0_IMSIC(hIMSIC),.fromHstateen0_CONTEXT(hCONTEXT),.privState_V(privV));
  Sstateen0Module_xs is(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),.rdata(is_rd),
    .regOut_JVT(is_JVT),.regOut_FCSR(is_FC),.regOut_C(is_C),
    .fromMstateen0_SE0(mSE0),.fromMstateen0_ENVCFG(mENVCFG),.fromMstateen0_CSRIND(mCSRIND),
    .fromMstateen0_AIA(mAIA),.fromMstateen0_IMSIC(mIMSIC),.fromMstateen0_CONTEXT(mCONTEXT),.fromMstateen0_C(mC),
    .fromHstateen0_JVT(hJVT),.fromHstateen0_FCSR(hFCSR),.fromHstateen0_C(hC),.fromHstateen0_SE0(hSE0),
    .fromHstateen0_ENVCFG(hENVCFG),.fromHstateen0_CSRIND(hCSRIND),.fromHstateen0_AIA(hAIA),
    .fromHstateen0_IMSIC(hIMSIC),.fromHstateen0_CONTEXT(hCONTEXT),.privState_V(privV));

  always @(negedge clk) begin
    if (rst) begin
      w_wen <= '0; w_wdata <= '0;
      {mSE0,mENVCFG,mCSRIND,mAIA,mIMSIC,mCONTEXT,mC} <= '0;
      {hJVT,hFCSR,hC,hSE0,hENVCFG,hCSRIND,hAIA,hIMSIC,hCONTEXT} <= '0;
      m1SE <= '0; privV <= '0;
    end else begin
      w_wen   <= ($urandom_range(0,1)==0);
      w_wdata <= {$urandom, $urandom};
      {mSE0,mENVCFG,mCSRIND,mAIA,mIMSIC,mCONTEXT,mC} <= 7'($urandom);
      {hJVT,hFCSR,hC,hSE0,hENVCFG,hCSRIND,hAIA,hIMSIC,hCONTEXT} <= 9'($urandom);
      m1SE  <= 1'($urandom);
      privV <= 1'($urandom);
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g0_rd!==i0_rd || {g0_SE0,g0_ENV,g0_CS,g0_AIA,g0_IM,g0_CT,g0_C}!=={i0_SE0,i0_ENV,i0_CS,i0_AIA,i0_IM,i0_CT,i0_C}) begin
        errors++; if(errors<=30) $display("[%0t] M0 g=%h i=%h",$time,g0_rd,i0_rd); end
      if (g1_rd!==i1_rd || g1_SE!==i1_SE) begin errors++; if(errors<=30) $display("[%0t] M1 g=%h i=%h",$time,g1_rd,i1_rd); end
      if (gh_rd!==ih_rd || {gh_JVT,gh_FC,gh_C,gh_SE0,gh_ENV,gh_CS,gh_AIA,gh_IM,gh_CT}!=={ih_JVT,ih_FC,ih_C,ih_SE0,ih_ENV,ih_CS,ih_AIA,ih_IM,ih_CT}) begin
        errors++; if(errors<=30) $display("[%0t] H0 g=%h i=%h",$time,gh_rd,ih_rd); end
      if (gh1_rd!==ih1_rd || gh1_SE!==ih1_SE) begin errors++; if(errors<=30) $display("[%0t] H1 g=%h i=%h",$time,gh1_rd,ih1_rd); end
      if (gs_rd!==is_rd || {gs_JVT,gs_FC,gs_C}!=={is_JVT,is_FC,is_C}) begin errors++; if(errors<=30) $display("[%0t] S0 g=%h i=%h",$time,gs_rd,is_rd); end
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
