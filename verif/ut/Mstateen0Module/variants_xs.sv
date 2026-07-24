// Stateen family UT variants (_xs): instantiate the readable primitives.
// One _xs module per representative golden shape exercised by tb.sv.

module Mstateen0Module_xs(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SE0, regOut_ENVCFG, regOut_CSRIND, regOut_AIA,
  output        regOut_IMSIC, regOut_CONTEXT, regOut_C
);
  xs_stateen0 u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_SE0(regOut_SE0), .regOut_ENVCFG(regOut_ENVCFG),
    .regOut_CSRIND(regOut_CSRIND), .regOut_AIA(regOut_AIA),
    .regOut_IMSIC(regOut_IMSIC), .regOut_CONTEXT(regOut_CONTEXT),
    .regOut_C(regOut_C));
endmodule

module Mstateen1Module_xs(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE
);
  xs_stateen_se u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE));
endmodule

module Hstateen0Module_xs(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_JVT, regOut_FCSR, regOut_C, regOut_SE0, regOut_ENVCFG,
  output        regOut_CSRIND, regOut_AIA, regOut_IMSIC, regOut_CONTEXT,
  input         fromMstateen0_SE0, fromMstateen0_ENVCFG, fromMstateen0_CSRIND,
  input         fromMstateen0_AIA, fromMstateen0_IMSIC, fromMstateen0_CONTEXT,
  input         fromMstateen0_C
);
  xs_stateen0_masked u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_JVT(regOut_JVT), .regOut_FCSR(regOut_FCSR),
    .regOut_C(regOut_C), .regOut_SE0(regOut_SE0), .regOut_ENVCFG(regOut_ENVCFG),
    .regOut_CSRIND(regOut_CSRIND), .regOut_AIA(regOut_AIA),
    .regOut_IMSIC(regOut_IMSIC), .regOut_CONTEXT(regOut_CONTEXT),
    .fromMstateen0_SE0(fromMstateen0_SE0),
    .fromMstateen0_ENVCFG(fromMstateen0_ENVCFG),
    .fromMstateen0_CSRIND(fromMstateen0_CSRIND),
    .fromMstateen0_AIA(fromMstateen0_AIA),
    .fromMstateen0_IMSIC(fromMstateen0_IMSIC),
    .fromMstateen0_CONTEXT(fromMstateen0_CONTEXT),
    .fromMstateen0_C(fromMstateen0_C));
endmodule

module Hstateen1Module_xs(
  input clock, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE, input fromMstateen1_SE
);
  xs_stateen_se_masked u_core (.clock(clock), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE),
    .fromMstateen_SE(fromMstateen1_SE));
endmodule

module Sstateen0Module_xs(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [31:0] rdata, output regOut_JVT, regOut_FCSR, regOut_C,
  input         fromMstateen0_SE0, fromMstateen0_ENVCFG, fromMstateen0_CSRIND,
  input         fromMstateen0_AIA, fromMstateen0_IMSIC, fromMstateen0_CONTEXT,
  input         fromMstateen0_C,
  input         fromHstateen0_JVT, fromHstateen0_FCSR, fromHstateen0_C,
  input         fromHstateen0_SE0, fromHstateen0_ENVCFG, fromHstateen0_CSRIND,
  input         fromHstateen0_AIA, fromHstateen0_IMSIC, fromHstateen0_CONTEXT,
  input         privState_V
);
  xs_sstateen0 u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_JVT(regOut_JVT), .regOut_FCSR(regOut_FCSR),
    .regOut_C(regOut_C),
    .fromMstateen0_C(fromMstateen0_C),
    .fromHstateen0_JVT(fromHstateen0_JVT),
    .fromHstateen0_FCSR(fromHstateen0_FCSR),
    .fromHstateen0_C(fromHstateen0_C),
    .privState_V(privState_V));
endmodule
