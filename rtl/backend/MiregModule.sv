// MiregModule mirrors its selected 64-bit indirect read source to both views.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_MiregModule_core (
  input  logic [63:0] source,
  output logic [63:0] value,
  output logic [63:0] mirror
);
  assign value = source;
  assign mirror = source;
endmodule

module MiregModule (
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic [63:0] iregRead_mireg
);
  xs_MiregModule_core u_core (
    .source(iregRead_mireg),
    .value(rdata),
    .mirror(regOut_ALL)
  );
endmodule
