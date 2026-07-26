// NewCSR CSR-field primitive: tval (trap value / trap instruction register).
//
// Faithful, readable, parameterized reimplementation of the golden trap-value
// family whose golden bodies are byte-identical apart from the trap-write port
// name: MtvalModule, StvalModule, Mtval2Module, MtinstModule (and the
// H-extension guests HtvalModule/HtinstModule/VStvalModule, out of scope here).
//
// A tval CSR is a plain 64-bit register:
//   * reg_ALL[63:0] : async-reset to 0.
//   * write enable  : w_wen OR trap-entry valid. On a trap the trap bits are
//                     latched; a concurrent CSR write ORs in w_wdata.
//                     (Golden OR-of-two-muxes form; transcribed verbatim.)
//   * rdata = regOut_ALL = reg_ALL.
//
// The generic trap port is named trap_valid/trap_bits_ALL; each wrapper
// connects its specific golden trap pins.

module xs_tval (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output [63:0] regOut_ALL,
    input         trap_valid,
    input  [63:0] trap_bits_ALL
);

  reg [63:0] reg_ALL;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_ALL <= 64'h0;
    else if (w_wen | trap_valid)
      reg_ALL <=
        (trap_valid ? trap_bits_ALL : 64'h0)
        | (w_wen ? w_wdata : 64'h0);
  end

  assign rdata      = reg_ALL;
  assign regOut_ALL = reg_ALL;

endmodule
