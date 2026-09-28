// Expose PMA address slot 28 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same value.
// Keeping the slot-named wrapper preserves the generated CSR-bank interface.
module Pmaaddr28Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_28
);
  assign rdata = addrRData_28;
  assign regOut_ALL = addrRData_28;
endmodule
