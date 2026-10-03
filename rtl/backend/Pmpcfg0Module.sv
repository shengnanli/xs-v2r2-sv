// Pmpcfg0Module exposes the decoded PMP configuration word through both CSR views.
// The semantic core states the CSR behavior; the exact wrapper preserves ports.
// This combinational leaf contains no hidden architectural state.
module xs_Pmpcfg0Module_core (
  input  logic [63:0] source,
  output logic [63:0] value,
  output logic [63:0] mirror
);
  assign value = source;
  assign mirror = source;
endmodule

module Pmpcfg0Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] cfgRData
);
  xs_Pmpcfg0Module_core u_core (
    .source(cfgRData),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
