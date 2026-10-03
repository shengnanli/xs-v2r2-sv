// Trigger1_Tdata1Module.sv — slot 1 mcontrol6 WARL register wrapper.
// The canonical trigger core legalizes type, debug mode, action, chain, and match fields.
// Reset behavior and dmode-next-trigger gating match the G1 trigger CSR contract.
module Trigger1_Tdata1Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable,
  input         dmodeNextTrigger
);
  xs_trigger_tdata1_core u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata),
    .can_write_dmode(canWriteDmode), .chainable(chainable),
    .dmode_next_trigger(dmodeNextTrigger));
endmodule
