// Expose PMA address slot zero through the CSR and mirror views.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module Pmaaddr0Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_0
);
  assign rdata = addrRData_0;
  assign regOut_ALL = addrRData_0;
endmodule
