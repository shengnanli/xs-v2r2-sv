// Expose the decoded PMP configuration word through both CSR views.
// The small semantic core makes the architectural transform explicit;
// the outer module preserves the generated RTL interface exactly.
module xs_Pmpcfg6Module_core (
  input  logic [63:0] cfg,
  output logic [63:0] read_value,
  output logic [63:0] mirror_value
);
  assign read_value = cfg;
  assign mirror_value = cfg;
endmodule

module Pmpcfg6Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] cfgRData
);
  xs_Pmpcfg6Module_core u_core (
    .cfg(cfgRData),
    .read_value(rdata),
    .mirror_value(regOut_ALL)
  );
endmodule
