// NewCSR constant / trivial read-only CSR wrappers.
//
// These golden modules are pure combinational reads with no registers, so there
// is no shared "primitive" to factor out — each is faithfully transcribed here
// as its own tiny module. FM-verified strict, no black box.
//
//   MvendoridModule : mvendorid = 0 (no commercial JEDEC vendor id).
//   MconfigptrModule: mconfigptr = 0 (no configuration data structure pointer).
//   MhartidModule   : mhartid    = zero-extended 6-bit hartid input.

module MvendoridModule(
  output [63:0] rdata
);
  assign rdata = 64'h0;
endmodule

module MconfigptrModule(
  output [63:0] rdata
);
  assign rdata = 64'h0;
endmodule

module MhartidModule(
  output [63:0] rdata,
  input  [5:0]  hartid
);
  assign rdata = {58'h0, hartid};
endmodule
