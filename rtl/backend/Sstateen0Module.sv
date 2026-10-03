// Sstateen0Module.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

module xs_Sstateen0Module_core(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output logic [31:0] rdata,
  output logic regOut_JVT,
  output logic regOut_FCSR,
  output logic regOut_C,
  input         fromMstateen0_SE0,
  input         fromMstateen0_ENVCFG,
  input         fromMstateen0_CSRIND,
  input         fromMstateen0_AIA,
  input         fromMstateen0_IMSIC,
  input         fromMstateen0_CONTEXT,
  input         fromMstateen0_C,
  input         fromHstateen0_JVT,
  input         fromHstateen0_FCSR,
  input         fromHstateen0_C,
  input         fromHstateen0_SE0,
  input         fromHstateen0_ENVCFG,
  input         fromHstateen0_CSRIND,
  input         fromHstateen0_AIA,
  input         fromHstateen0_IMSIC,
  input         fromHstateen0_CONTEXT,
  input         privState_V
);
logic [2:0] enabled_state;
  logic        reg_C;
  always_comb begin
    enabled_state = (privState_V
       ? {fromHstateen0_JVT, fromHstateen0_FCSR, fromHstateen0_C}
       : {2'h0, fromMstateen0_C}) & {2'h0, reg_C};
  end
  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_C <= 1'h0;
    else if (w_wen)
      reg_C <= w_wdata[0];
  end // always @(posedge, posedge)
always_comb begin
    rdata = {29'h0, enabled_state};
  end
  always_comb begin
    regOut_JVT = enabled_state[2];
  end
  always_comb begin
    regOut_FCSR = enabled_state[1];
  end
  always_comb begin
    regOut_C = enabled_state[0];
  end
endmodule

module Sstateen0Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [31:0] rdata,
  output        regOut_JVT,
  output        regOut_FCSR,
  output        regOut_C,
  input         fromMstateen0_SE0,
  input         fromMstateen0_ENVCFG,
  input         fromMstateen0_CSRIND,
  input         fromMstateen0_AIA,
  input         fromMstateen0_IMSIC,
  input         fromMstateen0_CONTEXT,
  input         fromMstateen0_C,
  input         fromHstateen0_JVT,
  input         fromHstateen0_FCSR,
  input         fromHstateen0_C,
  input         fromHstateen0_SE0,
  input         fromHstateen0_ENVCFG,
  input         fromHstateen0_CSRIND,
  input         fromHstateen0_AIA,
  input         fromHstateen0_IMSIC,
  input         fromHstateen0_CONTEXT,
  input         privState_V
);
  xs_Sstateen0Module_core u_core (
    .clock(clock),
    .reset(reset),
    .w_wen(w_wen),
    .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_JVT(regOut_JVT),
    .regOut_FCSR(regOut_FCSR),
    .regOut_C(regOut_C),
    .fromMstateen0_SE0(fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(fromMstateen0_CSRIND),
    .fromMstateen0_AIA(fromMstateen0_AIA),
    .fromMstateen0_IMSIC(fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(fromMstateen0_CONTEXT),
    .fromMstateen0_C(fromMstateen0_C),
    .fromHstateen0_JVT(fromHstateen0_JVT),
    .fromHstateen0_FCSR(fromHstateen0_FCSR),
    .fromHstateen0_C(fromHstateen0_C),
    .fromHstateen0_SE0(fromHstateen0_SE0),
    .fromHstateen0_ENVCFG(fromHstateen0_ENVCFG),
    .fromHstateen0_CSRIND(fromHstateen0_CSRIND),
    .fromHstateen0_AIA(fromHstateen0_AIA),
    .fromHstateen0_IMSIC(fromHstateen0_IMSIC),
    .fromHstateen0_CONTEXT(fromHstateen0_CONTEXT),
    .privState_V(privState_V)
  );
endmodule
