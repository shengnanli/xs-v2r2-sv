// NewCSR epc family AUX wrappers (MepcModule, SepcModule).
// Both golden modules are byte-identical apart from the trap-write port names;
// each is a thin wrapper over the readable primitive xs_epc
// (rtl/backend/newcsr_epc.sv). FM-verified strict, no black box.
//
// (VSepcModule is the H-extension guest variant and is intentionally out of
// scope for this wave; its trap port is trapToVS_vsepc_* over the same core.)

module MepcModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToM_mepc_valid,
  input  [62:0] trapToM_mepc_bits_epc
);
  xs_epc u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_epc(regOut_epc),
    .trap_valid(trapToM_mepc_valid), .trap_bits_epc(trapToM_mepc_bits_epc));
endmodule

module SepcModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [62:0] regOut_epc,
  input         trapToHS_sepc_valid,
  input  [62:0] trapToHS_sepc_bits_epc
);
  xs_epc u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(rdata), .regOut_epc(regOut_epc),
    .trap_valid(trapToHS_sepc_valid), .trap_bits_epc(trapToHS_sepc_bits_epc));
endmodule
