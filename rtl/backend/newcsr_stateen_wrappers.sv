// NewCSR Stateen family AUX wrappers (12 golden modules).
// Thin wrappers over readable primitives in rtl/backend/newcsr_stateen.sv,
// binding golden per-instance port names. Sstateen0Module (delegation mux) and
// the constant-zero Sstateen{1,2,3}Module are implemented directly here since
// their bodies are structurally unique. FM-verified per module (signoff-strict).

// ===== Machine-mode stateen0 (7 fields, unmasked) =====
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
  xs_stateen0 u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_SE0(regOut_SE0), .regOut_ENVCFG(regOut_ENVCFG),
    .regOut_CSRIND(regOut_CSRIND), .regOut_AIA(regOut_AIA),
    .regOut_IMSIC(regOut_IMSIC), .regOut_CONTEXT(regOut_CONTEXT),
    .regOut_C(regOut_C));
endmodule

// ===== Machine-mode stateen{1,2,3} (single SE field, unmasked) =====
module Mstateen1Module(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE
);
  xs_stateen_se u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE));
endmodule

module Mstateen2Module(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE
);
  xs_stateen_se u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE));
endmodule

module Mstateen3Module(
  input         clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE
);
  xs_stateen_se u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE));
endmodule

// ===== Hypervisor stateen0 (7 fields, masked by fromMstateen0) =====
module Hstateen0Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_JVT,
  output        regOut_FCSR,
  output        regOut_C,
  output        regOut_SE0,
  output        regOut_ENVCFG,
  output        regOut_CSRIND,
  output        regOut_AIA,
  output        regOut_IMSIC,
  output        regOut_CONTEXT,
  input         fromMstateen0_SE0,
  input         fromMstateen0_ENVCFG,
  input         fromMstateen0_CSRIND,
  input         fromMstateen0_AIA,
  input         fromMstateen0_IMSIC,
  input         fromMstateen0_CONTEXT,
  input         fromMstateen0_C
);
  xs_stateen0_masked u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata),
    .regOut_JVT(regOut_JVT), .regOut_FCSR(regOut_FCSR), .regOut_C(regOut_C),
    .regOut_SE0(regOut_SE0), .regOut_ENVCFG(regOut_ENVCFG),
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

// ===== Hypervisor stateen{1,2,3} (single SE field, no reset, masked) =====
module Hstateen1Module(
  input         clock, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE, input fromMstateen1_SE
);
  xs_stateen_se_masked u_core (.clock(clock), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE),
    .fromMstateen_SE(fromMstateen1_SE));
endmodule

module Hstateen2Module(
  input         clock, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE, input fromMstateen2_SE
);
  xs_stateen_se_masked u_core (.clock(clock), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE),
    .fromMstateen_SE(fromMstateen2_SE));
endmodule

module Hstateen3Module(
  input         clock, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, output regOut_SE, input fromMstateen3_SE
);
  xs_stateen_se_masked u_core (.clock(clock), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .regOut_SE(regOut_SE),
    .fromMstateen_SE(fromMstateen3_SE));
endmodule

// ===== Supervisor stateen0 (single reg_C + privState_V delegation mux) =====
// Bespoke: _GEN = (V ? {Hstateen0.JVT,FCSR,C} : {2'h0,Mstateen0.C}) & {2'h0,reg_C}
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
  // Only the delegation lanes {Mstateen0.C, Hstateen0.JVT/FCSR/C} plus
  // privState_V are architecturally read; the remaining fromMstateen0_* /
  // fromHstateen0_* ports are present to match golden but are unread (golden
  // leaves them dangling too).
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

// ===== Supervisor stateen{1,2,3} (constant-zero read; no register) =====
module Sstateen1Module(
  output [31:0] rdata, output [31:0] regOut_ALL
);
  assign rdata      = 32'h0;
  assign regOut_ALL = 32'h0;
endmodule

module Sstateen2Module(
  output [31:0] rdata, output [31:0] regOut_ALL
);
  assign rdata      = 32'h0;
  assign regOut_ALL = 32'h0;
endmodule

module Sstateen3Module(
  output [31:0] rdata, output [31:0] regOut_ALL
);
  assign rdata      = 32'h0;
  assign regOut_ALL = 32'h0;
endmodule
