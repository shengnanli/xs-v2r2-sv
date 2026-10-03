// Mstateen0Module.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_Mstateen0Module_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic regOut_SE0,
  output logic regOut_ENVCFG,
  output logic regOut_CSRIND,
  output logic regOut_AIA,
  output logic regOut_IMSIC,
  output logic regOut_CONTEXT,
  output logic regOut_C
);
logic reg_SE0;
  logic reg_ENVCFG;
  logic reg_CSRIND;
  logic reg_AIA;
  logic reg_IMSIC;
  logic reg_CONTEXT;
  logic reg_C;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SE0 <= 1'h0;
      reg_ENVCFG <= 1'h0;
      reg_CSRIND <= 1'h0;
      reg_AIA <= 1'h0;
      reg_IMSIC <= 1'h0;
      reg_CONTEXT <= 1'h0;
      reg_C <= 1'h0;
    end
    else if (w_wen) begin
      reg_SE0 <= w_wdata[63];
      reg_ENVCFG <= w_wdata[62];
      reg_CSRIND <= w_wdata[60];
      reg_AIA <= w_wdata[59];
      reg_IMSIC <= w_wdata[58];
      reg_CONTEXT <= w_wdata[57];
      reg_C <= w_wdata[0];
    end
  end // always @(posedge, posedge)
always_comb begin
    rdata = {reg_SE0,
     reg_ENVCFG,
     1'h0,
     reg_CSRIND,
     reg_AIA,
     reg_IMSIC,
     reg_CONTEXT,
     56'h0,
     reg_C};
  end
  always_comb begin
    regOut_SE0 = reg_SE0;
  end
  always_comb begin
    regOut_ENVCFG = reg_ENVCFG;
  end
  always_comb begin
    regOut_CSRIND = reg_CSRIND;
  end
  always_comb begin
    regOut_AIA = reg_AIA;
  end
  always_comb begin
    regOut_IMSIC = reg_IMSIC;
  end
  always_comb begin
    regOut_CONTEXT = reg_CONTEXT;
  end
  always_comb begin
    regOut_C = reg_C;
  end
endmodule

module Mstateen0Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE0,
  output        regOut_ENVCFG,
  output        regOut_CSRIND,
  output        regOut_AIA,
  output        regOut_IMSIC,
  output        regOut_CONTEXT,
  output        regOut_C
);
  xs_Mstateen0Module_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SE0(regOut_SE0),
    .regOut_ENVCFG(regOut_ENVCFG),
    .regOut_CSRIND(regOut_CSRIND),
    .regOut_AIA(regOut_AIA),
    .regOut_IMSIC(regOut_IMSIC),
    .regOut_CONTEXT(regOut_CONTEXT),
    .regOut_C(regOut_C)
  );
endmodule
