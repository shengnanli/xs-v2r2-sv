// PMP address CSR slot 17.
// The architectural value is the low 46 address bits, zero-extended on CSR reads.
// This combinational leaf has no hidden state or side effects.
module Pmpaddr17Module (
  output logic [63:0] rdata,
  output logic [45:0] regOut_ADDRESS,
  input  logic [63:0] addrRData_17
);
  assign regOut_ADDRESS = addrRData_17[45:0];
  assign rdata = {18'b0, regOut_ADDRESS};
endmodule
