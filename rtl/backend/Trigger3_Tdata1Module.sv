// Trigger3_Tdata1Module.sv — slot 3 mcontrol6 WARL register wrapper.
// The canonical trigger core legalizes type, debug mode, action, chain, and match fields.
// Slot 3 has no following dmode trigger, as in the G1 port contract.
module Trigger3_Tdata1Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         canWriteDmode,
  input         chainable
);
  xs_trigger_tdata1_core u_core (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata),
    .can_write_dmode(canWriteDmode), .chainable(chainable),
    .dmode_next_trigger(1'b0));
endmodule
