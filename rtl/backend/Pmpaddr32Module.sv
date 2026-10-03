// PMP address slot 32 is outside the implemented range and reads as zero.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module Pmpaddr32Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  assign rdata = 64'b0;
  assign regOut_ALL = 64'b0;
endmodule
