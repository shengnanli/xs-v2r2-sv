// xs_Dispatcher_core.sv — shared combinational ready/valid dispatcher core.
//
// Each Dispatcher leaf compares the complete 35-bit FuType one-hot word with
// a proven per-output mask.  A match gates valid; payload buses are broadcast
// unchanged and are selected by each output's valid.  Ready is deliberately
// the AND of every output ready, matching the conservative golden contract.
module xs_Dispatcher_core #(
  parameter int unsigned OUTPUTS = 1,
  parameter logic [34:0] ACCEPT_MASK [0:OUTPUTS-1] = '{default: '0}
)(
  input  logic                         clock,
  input  logic                         reset,
  output logic                         in_ready,
  input  logic                         in_valid,
  input  logic [34:0]                  in_fu_type,
  input  logic [OUTPUTS-1:0]           out_ready,
  output logic [OUTPUTS-1:0]           out_valid
);
  logic [OUTPUTS-1:0] accepted;

  genvar slot;
  generate
    for (slot = 0; slot < OUTPUTS; slot = slot + 1) begin : g_route
      assign accepted[slot] = (in_fu_type == ACCEPT_MASK[slot]);
      assign out_valid[slot] = in_valid & accepted[slot];
    end
  endgenerate

  assign in_ready = &out_ready;

`ifndef SYNTHESIS
  // Golden asserts that a valid input is claimed by exactly one or at least
  // one output.  Keep equivalent checks local to the shared route core.
  always @(posedge clock) begin
    if (!reset && in_valid) begin
      if ($countones(accepted) > 1)
        $error("Dispatcher FuType claimed by multiple outputs: %h", in_fu_type);
      if (accepted == '0)
        $error("Dispatcher FuType not claimed by any output: %h", in_fu_type);
    end
  end
`endif
endmodule
