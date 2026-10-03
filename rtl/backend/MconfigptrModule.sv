// Machine configuration pointer is architecturally hard-wired to zero.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_MconfigptrModule_core (
  output logic [63:0] value
);
  assign value = 64'b0;
endmodule

module MconfigptrModule (
  output logic [63:0] rdata
);
  xs_MconfigptrModule_core u_core (
    .value(rdata)
  );
endmodule
