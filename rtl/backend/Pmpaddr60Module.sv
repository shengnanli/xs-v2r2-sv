// PMP address slot 60 is outside this configuration's implemented PMP range.
// Both architectural views therefore return zero, with no hidden state.
// The named wrapper preserves the generated CSR interface used by the parent block.
module Pmpaddr60Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
