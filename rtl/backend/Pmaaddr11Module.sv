// Expose PMA address slot 11 through the CSR and mirror views.
// This leaf sits at the backend CSR boundary and contains no architectural state.
// Both output views are combinational aliases of the selected 64-bit slot.
module Pmaaddr11Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_11
);
  assign rdata = addrRData_11;
  assign regOut_ALL = addrRData_11;
endmodule
