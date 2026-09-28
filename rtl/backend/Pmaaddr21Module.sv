// Expose PMA address slot 21 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr21Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_21
);
  assign rdata = addrRData_21;
  assign regOut_ALL = addrRData_21;
endmodule
