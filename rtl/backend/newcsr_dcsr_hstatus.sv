// NewCSR DcsrModule + HstatusModule — readable transcriptions.
//
// Both golden modules are plain structural RTL. The readable rewrite drops the
// non-synthesizable `ifdef ENABLE_INITIAL_REG_ sim randomize-init block; in Dcsr
// the single CIRCT intermediate wire is renamed trapOrRet (= trapToD OR retFromD
// debug-mode write-through select). FM-verified strict golden-vs-impl SUCCEEDED,
// no black box, no dont_verify.


module DcsrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output        regOut_CETRIG,
  output        regOut_EBREAKVS,
  output        regOut_EBREAKVU,
  output        regOut_EBREAKM,
  output        regOut_EBREAKS,
  output        regOut_EBREAKU,
  output        regOut_STEPIE,
  output        regOut_STOPCOUNT,
  output        regOut_STOPTIME,
  output [2:0]  regOut_CAUSE,
  output        regOut_V,
  output        regOut_MPRVEN,
  output        regOut_NMIP,
  output        regOut_STEP,
  output [1:0]  regOut_PRV,
  input         trapToD_dcsr_valid,
  input  [2:0]  trapToD_dcsr_bits_CAUSE,
  input         trapToD_dcsr_bits_V,
  input  [1:0]  trapToD_dcsr_bits_PRV,
  input         retFromD_dcsr_valid,
  input         retFromD_dcsr_bits_V,
  input  [1:0]  retFromD_dcsr_bits_PRV,
  input         nmip
);

  reg        reg_CETRIG;
  reg        reg_EBREAKVS;
  reg        reg_EBREAKVU;
  reg        reg_EBREAKM;
  reg        reg_EBREAKS;
  reg        reg_EBREAKU;
  reg        reg_STEPIE;
  reg        reg_STOPCOUNT;
  reg        reg_STOPTIME;
  reg  [2:0] reg_CAUSE;
  reg        reg_V;
  reg        reg_MPRVEN;
  reg        reg_NMIP;
  reg        reg_STEP;
  reg  [1:0] reg_PRV;
  wire       trapOrRet = trapToD_dcsr_valid | retFromD_dcsr_valid;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_CETRIG <= 1'h0;
      reg_EBREAKVS <= 1'h0;
      reg_EBREAKVU <= 1'h0;
      reg_EBREAKM <= 1'h0;
      reg_EBREAKS <= 1'h0;
      reg_EBREAKU <= 1'h0;
      reg_STEPIE <= 1'h0;
      reg_STOPCOUNT <= 1'h0;
      reg_STOPTIME <= 1'h0;
      reg_CAUSE <= 3'h0;
      reg_V <= 1'h0;
      reg_MPRVEN <= 1'h0;
      reg_NMIP <= 1'h0;
      reg_STEP <= 1'h0;
      reg_PRV <= 2'h3;
    end
    else begin
      if (w_wen) begin
        reg_CETRIG <= w_wdata[19];
        reg_EBREAKVS <= w_wdata[17];
        reg_EBREAKVU <= w_wdata[16];
        reg_EBREAKM <= w_wdata[15];
        reg_EBREAKS <= w_wdata[13];
        reg_EBREAKU <= w_wdata[12];
        reg_STEPIE <= w_wdata[11];
        reg_STOPCOUNT <= w_wdata[10];
        reg_STOPTIME <= w_wdata[9];
        reg_MPRVEN <= w_wdata[4];
        reg_STEP <= w_wdata[2];
      end
      if (trapToD_dcsr_valid)
        reg_CAUSE <=
          (trapToD_dcsr_valid ? trapToD_dcsr_bits_CAUSE : 3'h0)
          | (w_wen ? w_wdata[8:6] : 3'h0);
      if (w_wen | trapOrRet)
        reg_V <=
          trapToD_dcsr_valid & trapToD_dcsr_bits_V | retFromD_dcsr_valid
          & retFromD_dcsr_bits_V | w_wen & w_wdata[5];
      if (nmip)
        reg_NMIP <= nmip;
      if (w_wen & (|{&(w_wdata[1:0]), w_wdata[1:0] == 2'h1, w_wdata[1:0] == 2'h0}) | trapOrRet)
        reg_PRV <=
          (trapToD_dcsr_valid ? trapToD_dcsr_bits_PRV : 2'h0)
          | (retFromD_dcsr_valid ? retFromD_dcsr_bits_PRV : 2'h0)
          | (w_wen ? w_wdata[1:0] : 2'h0);
    end
  end
  assign rdata =
    {12'h400,
     reg_CETRIG,
     1'h0,
     reg_EBREAKVS,
     reg_EBREAKVU,
     reg_EBREAKM,
     1'h0,
     reg_EBREAKS,
     reg_EBREAKU,
     reg_STEPIE,
     reg_STOPCOUNT,
     reg_STOPTIME,
     reg_CAUSE,
     reg_V,
     reg_MPRVEN,
     reg_NMIP,
     reg_STEP,
     reg_PRV};
  assign regOut_CETRIG = reg_CETRIG;
  assign regOut_EBREAKVS = reg_EBREAKVS;
  assign regOut_EBREAKVU = reg_EBREAKVU;
  assign regOut_EBREAKM = reg_EBREAKM;
  assign regOut_EBREAKS = reg_EBREAKS;
  assign regOut_EBREAKU = reg_EBREAKU;
  assign regOut_STEPIE = reg_STEPIE;
  assign regOut_STOPCOUNT = reg_STOPCOUNT;
  assign regOut_STOPTIME = reg_STOPTIME;
  assign regOut_CAUSE = reg_CAUSE;
  assign regOut_V = reg_V;
  assign regOut_MPRVEN = reg_MPRVEN;
  assign regOut_NMIP = reg_NMIP;
  assign regOut_STEP = reg_STEP;
  assign regOut_PRV = reg_PRV;
endmodule


module HstatusModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_GVA,
  output        regOut_SPV,
  output        regOut_SPVP,
  output        regOut_HU,
  output [5:0]  regOut_VGEIN,
  output        regOut_VTVM,
  output        regOut_VTW,
  output        regOut_VTSR,
  output [1:0]  regOut_HUPMM,
  input         retFromS_hstatus_valid,
  input         retFromS_hstatus_bits_SPV,
  input         trapToHS_hstatus_valid,
  input         trapToHS_hstatus_bits_GVA,
  input         trapToHS_hstatus_bits_SPV,
  input         trapToHS_hstatus_bits_SPVP
);

  reg       reg_GVA;
  reg       reg_SPV;
  reg       reg_SPVP;
  reg       reg_HU;
  reg [5:0] reg_VGEIN;
  reg       reg_VTVM;
  reg       reg_VTW;
  reg       reg_VTSR;
  reg [1:0] reg_HUPMM;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_GVA <= 1'h0;
      reg_SPV <= 1'h0;
      reg_SPVP <= 1'h0;
      reg_HU <= 1'h0;
      reg_VGEIN <= 6'h0;
      reg_VTVM <= 1'h0;
      reg_VTW <= 1'h0;
      reg_VTSR <= 1'h0;
      reg_HUPMM <= 2'h0;
    end
    else begin
      if (w_wen | trapToHS_hstatus_valid) begin
        reg_GVA <=
          trapToHS_hstatus_valid & trapToHS_hstatus_bits_GVA | w_wen & w_wdata[6];
        reg_SPVP <=
          trapToHS_hstatus_valid & trapToHS_hstatus_bits_SPVP | w_wen & w_wdata[8];
      end
      if (w_wen | retFromS_hstatus_valid | trapToHS_hstatus_valid)
        reg_SPV <=
          retFromS_hstatus_valid & retFromS_hstatus_bits_SPV | trapToHS_hstatus_valid
          & trapToHS_hstatus_bits_SPV | w_wen & w_wdata[7];
      if (w_wen) begin
        reg_HU <= w_wdata[9];
        reg_VGEIN <= w_wdata[17:12];
        reg_VTVM <= w_wdata[20];
        reg_VTW <= w_wdata[21];
        reg_VTSR <= w_wdata[22];
      end
      if (w_wen & (|{&(w_wdata[49:48]), w_wdata[49:48] == 2'h2, w_wdata[49:48] == 2'h0}))
        reg_HUPMM <= w_wdata[49:48];
    end
  end
  assign rdata =
    {14'h0,
     reg_HUPMM,
     25'h400,
     reg_VTSR,
     reg_VTW,
     reg_VTVM,
     2'h0,
     reg_VGEIN,
     2'h0,
     reg_HU,
     reg_SPVP,
     reg_SPV,
     reg_GVA,
     6'h0};
  assign regOut_GVA = reg_GVA;
  assign regOut_SPV = reg_SPV;
  assign regOut_SPVP = reg_SPVP;
  assign regOut_HU = reg_HU;
  assign regOut_VGEIN = reg_VGEIN;
  assign regOut_VTVM = reg_VTVM;
  assign regOut_VTW = reg_VTW;
  assign regOut_VTSR = reg_VTSR;
  assign regOut_HUPMM = reg_HUPMM;
endmodule
