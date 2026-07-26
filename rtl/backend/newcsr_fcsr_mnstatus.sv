// NewCSR FcsrModule + MnstatusModule — readable transcriptions.
//
// Both golden modules are plain structural RTL (async-reset always_ff + write
// arm + rdata packing). The readable rewrite drops the non-synthesizable
// `ifdef ENABLE_INITIAL_REG_ sim randomize-init block and renames the two CIRCT
// intermediate wires for clarity:
//   Fcsr:     fflags_val  = accrued {NV,DZ,OF,UF,NX} (shared by fflags/rdata)
//   Mnstatus: trapOrRet   = trapToMN OR retFromMN write-through select
// FM-verified strict golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module FcsrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         robCommit_fflags_valid,
  input  [4:0]  robCommit_fflags_bits,
  input         wAliasFflags_wen,
  input  [63:0] wAliasFflags_wdata,
  input         wAliasFfm_wen,
  input  [63:0] wAliasFfm_wdata,
  output [4:0]  fflags,
  output [2:0]  frm,
  output [4:0]  fflagsRdata,
  output [2:0]  frmRdata
);

  reg        reg_NX;
  reg        reg_UF;
  reg        reg_OF;
  reg        reg_DZ;
  reg        reg_NV;
  reg  [2:0] reg_FRM;
  wire [4:0] fflags_val = {reg_NV, reg_DZ, reg_OF, reg_UF, reg_NX};
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_NX <= 1'h0;
      reg_UF <= 1'h0;
      reg_OF <= 1'h0;
      reg_DZ <= 1'h0;
      reg_NV <= 1'h0;
      reg_FRM <= 3'h0;
    end
    else begin
      if (robCommit_fflags_valid) begin
        reg_NX <= robCommit_fflags_bits[0] | reg_NX;
        reg_UF <= robCommit_fflags_bits[1] | reg_UF;
        reg_OF <= robCommit_fflags_bits[2] | reg_OF;
        reg_DZ <= robCommit_fflags_bits[3] | reg_DZ;
        reg_NV <= robCommit_fflags_bits[4] | reg_NV;
      end
      else if (w_wen | wAliasFflags_wen) begin
        reg_NX <= wAliasFflags_wen & wAliasFflags_wdata[0] | w_wen & w_wdata[0];
        reg_UF <= wAliasFflags_wen & wAliasFflags_wdata[1] | w_wen & w_wdata[1];
        reg_OF <= wAliasFflags_wen & wAliasFflags_wdata[2] | w_wen & w_wdata[2];
        reg_DZ <= wAliasFflags_wen & wAliasFflags_wdata[3] | w_wen & w_wdata[3];
        reg_NV <= wAliasFflags_wen & wAliasFflags_wdata[4] | w_wen & w_wdata[4];
      end
      if (w_wen | wAliasFfm_wen)
        reg_FRM <=
          (wAliasFfm_wen ? wAliasFfm_wdata[2:0] : 3'h0) | (w_wen ? w_wdata[7:5] : 3'h0);
    end
  end
  assign rdata = {56'h0, reg_FRM, reg_NV, reg_DZ, reg_OF, reg_UF, reg_NX};
  assign fflags = fflags_val;
  assign frm = reg_FRM;
  assign fflagsRdata = fflags_val;
  assign frmRdata = reg_FRM;
endmodule


module MnstatusModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_NMIE,
  output        regOut_MNPV,
  output [1:0]  regOut_MNPP,
  input         trapToMN_mnstatus_valid,
  input         trapToMN_mnstatus_bits_NMIE,
  input         trapToMN_mnstatus_bits_MNPV,
  input  [1:0]  trapToMN_mnstatus_bits_MNPP,
  input         retFromMN_mnstatus_valid,
  input         retFromMN_mnstatus_bits_NMIE,
  input         retFromMN_mnstatus_bits_MNPV,
  input  [1:0]  retFromMN_mnstatus_bits_MNPP
);

  reg        reg_NMIE;
  reg        reg_MNPV;
  reg  [1:0] reg_MNPP;
  wire       trapOrRet = trapToMN_mnstatus_valid | retFromMN_mnstatus_valid;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_NMIE <= 1'h1;
      reg_MNPV <= 1'h0;
      reg_MNPP <= 2'h0;
    end
    else begin
      if (w_wen | trapOrRet) begin
        reg_NMIE <=
          trapToMN_mnstatus_valid & trapToMN_mnstatus_bits_NMIE | retFromMN_mnstatus_valid
          & retFromMN_mnstatus_bits_NMIE | w_wen & w_wdata[3];
        reg_MNPV <=
          trapToMN_mnstatus_valid & trapToMN_mnstatus_bits_MNPV | retFromMN_mnstatus_valid
          & retFromMN_mnstatus_bits_MNPV | w_wen & w_wdata[7];
      end
      if (w_wen & (|{&(w_wdata[12:11]), w_wdata[12:11] == 2'h1, w_wdata[12:11] == 2'h0})
          | trapOrRet)
        reg_MNPP <=
          (trapToMN_mnstatus_valid ? trapToMN_mnstatus_bits_MNPP : 2'h0)
          | (retFromMN_mnstatus_valid ? retFromMN_mnstatus_bits_MNPP : 2'h0)
          | (w_wen ? w_wdata[12:11] : 2'h0);
    end
  end
  assign rdata = {51'h0, reg_MNPP, 3'h0, reg_MNPV, 3'h0, reg_NMIE, 3'h0};
  assign regOut_NMIE = reg_NMIE;
  assign regOut_MNPV = reg_MNPV;
  assign regOut_MNPP = reg_MNPP;
endmodule
