// Expose PMA address slot 9 through the CSR and mirror views.
// This leaf is combinational: both architectural views observe the same
// address value supplied by the shared PMA register bank.
module Pmaaddr9Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_9
);
  assign rdata = addrRData_9;
  assign regOut_ALL = addrRData_9;
endmodule
