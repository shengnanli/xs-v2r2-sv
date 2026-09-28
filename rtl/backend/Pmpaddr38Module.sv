// PMP address slot 38 is outside this configuration's implemented PMP range.
// Both architectural views therefore read as zero; this leaf has no state.
// Keeping one named wrapper per CSR slot preserves the generated top-level interface.
module Pmpaddr38Module(
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
