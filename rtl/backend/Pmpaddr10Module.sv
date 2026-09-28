// PMP address CSR slot 10 exposes the implemented 46-bit physical address.
// The CSR read view zero-extends that architectural field to XLEN.
// This combinational leaf contains no local state or write-side policy.
module Pmpaddr10Module (
  output logic [63:0] rdata,
  output logic [45:0] regOut_ADDRESS,
  input  logic [63:0] addrRData_10
);
  assign regOut_ADDRESS = addrRData_10[45:0];
  assign rdata = {18'b0, addrRData_10[45:0]};
endmodule
