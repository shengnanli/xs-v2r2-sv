// Expose PMA address slot 29 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr29Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_29
);
  assign rdata = addrRData_29;
  assign regOut_ALL = addrRData_29;
endmodule
