// MnstatusModule.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_MnstatusModule_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_NMIE,
  output logic regOut_MNPV,
  output logic [1:0]  regOut_MNPP,
  input         trapToMN_mnstatus_valid,
  input         trapToMN_mnstatus_bits_NMIE,
  input         trapToMN_mnstatus_bits_MNPV,
  input  [1:0]  trapToMN_mnstatus_bits_MNPP,
  input         retFromMN_mnstatus_valid,
  input         retFromMN_mnstatus_bits_NMIE
);
logic       reg_NMIE;
  logic       reg_MNPV;
  logic [1:0] reg_MNPP;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_NMIE <= 1'h0;
      reg_MNPV <= 1'h0;
      reg_MNPP <= 2'h0;
    end
    else begin
      if (w_wen & ~(w_wdata[3])
          | ~(w_wen | trapToMN_mnstatus_valid | retFromMN_mnstatus_valid)) begin
      end
      else
        reg_NMIE <=
          trapToMN_mnstatus_valid & trapToMN_mnstatus_bits_NMIE | retFromMN_mnstatus_valid
          & retFromMN_mnstatus_bits_NMIE | w_wen & w_wdata[3];
      if (w_wen | trapToMN_mnstatus_valid)
        reg_MNPV <=
          trapToMN_mnstatus_valid & trapToMN_mnstatus_bits_MNPV | w_wen & w_wdata[7];
      if (w_wen & (w_wdata[12:11] == 2'h0 | w_wdata[12:11] == 2'h1 | (&(w_wdata[12:11])))
          | trapToMN_mnstatus_valid)
        reg_MNPP <=
          (trapToMN_mnstatus_valid ? trapToMN_mnstatus_bits_MNPP : 2'h0)
          | (w_wen ? w_wdata[12:11] : 2'h0);
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {51'h0, reg_MNPP, 3'h0, reg_MNPV, 3'h0, reg_NMIE, 3'h0};
  end
  always_comb begin
    regOut_NMIE = reg_NMIE;
  end
  always_comb begin
    regOut_MNPV = reg_MNPV;
  end
  always_comb begin
    regOut_MNPP = reg_MNPP;
  end
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
  input         retFromMN_mnstatus_bits_NMIE
);
  xs_MnstatusModule_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_NMIE(regOut_NMIE),
    .regOut_MNPV(regOut_MNPV),
    .regOut_MNPP(regOut_MNPP),
    .trapToMN_mnstatus_valid(trapToMN_mnstatus_valid),
    .trapToMN_mnstatus_bits_NMIE(trapToMN_mnstatus_bits_NMIE),
    .trapToMN_mnstatus_bits_MNPV(trapToMN_mnstatus_bits_MNPV),
    .trapToMN_mnstatus_bits_MNPP(trapToMN_mnstatus_bits_MNPP),
    .retFromMN_mnstatus_valid(retFromMN_mnstatus_valid),
    .retFromMN_mnstatus_bits_NMIE(retFromMN_mnstatus_bits_NMIE)
  );
endmodule
