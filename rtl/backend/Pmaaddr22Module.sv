// Expose PMA address slot 22 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr22Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_22
);
  assign rdata = addrRData_22;
  assign regOut_ALL = addrRData_22;
endmodule
