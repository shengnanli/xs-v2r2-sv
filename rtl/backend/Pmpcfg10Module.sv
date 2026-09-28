// Pmpcfg10Module is outside the implemented PMP configuration range and reads as zero.
// The semantic core states the CSR behavior; the exact wrapper preserves ports.
// This combinational leaf contains no hidden architectural state.
module xs_Pmpcfg10Module_core (
  output logic [63:0] value,
  output logic [63:0] mirror
);
  assign value = 64'b0;
  assign mirror = 64'b0;
endmodule

module Pmpcfg10Module (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL
);
  xs_Pmpcfg10Module_core u_core (
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
