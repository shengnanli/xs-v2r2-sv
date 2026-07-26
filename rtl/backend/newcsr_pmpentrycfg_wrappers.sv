// NewCSR PmpEntryCfg family AUX wrappers (Pmp0cfgModule .. Pmp15cfgModule).
// All 16 golden bodies are byte-identical apart from the module name; each is a
// thin wrapper over the readable primitive xs_pmpentrycfg
// (rtl/backend/newcsr_pmpentrycfg.sv). FM-verified strict, no black box.

module Pmp0cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp1cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp2cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp3cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp4cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp5cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp6cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp7cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp8cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp9cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp10cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp11cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp12cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp13cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp14cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule

module Pmp15cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_pmpentrycfg u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_R(regOut_R), .regOut_W(regOut_W),
    .regOut_X(regOut_X), .regOut_A(regOut_A), .regOut_L(regOut_L));
endmodule
