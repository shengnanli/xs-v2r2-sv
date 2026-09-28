// Expose PMA address slot 30 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr30Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_30
);
  assign rdata = addrRData_30;
  assign regOut_ALL = addrRData_30;
endmodule
