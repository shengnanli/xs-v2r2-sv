// PMA address slot 31 exposes the address value supplied by the shared PMA bank.
// The software-visible read port and the internal mirror are intentionally identical.
// This leaf is combinational and contains no local architectural state.
module Pmaaddr31Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] addrRData_31
);
  assign rdata = addrRData_31;
  assign regOut_ALL = addrRData_31;
endmodule
