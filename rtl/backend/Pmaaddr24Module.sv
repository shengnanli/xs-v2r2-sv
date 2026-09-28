// Expose PMA address slot 24 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr24Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_24
);
  assign rdata = addrRData_24;
  assign regOut_ALL = addrRData_24;
endmodule
