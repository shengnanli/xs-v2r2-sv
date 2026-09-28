// Decode the architectural type, debug-mode, and payload fields of tdata1.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module Tdata1Module (
  output logic [63:0] rdata,
  output logic [3:0]  regOut_TYPE,
  output logic        regOut_DMODE,
  output logic [58:0] regOut_DATA,
  input  logic [63:0] tdataRead_tdata1
);
  assign rdata = tdataRead_tdata1;
  assign regOut_TYPE = tdataRead_tdata1[63:60];
  assign regOut_DMODE = tdataRead_tdata1[59];
  assign regOut_DATA = tdataRead_tdata1[58:0];
endmodule
