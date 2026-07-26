// NewCSR CSR-field primitive: cause (trap cause CSR).
//
// Faithful, readable, parameterized reimplementation of the golden xcause
// family (McauseModule / ScauseModule / VScauseModule — all byte-identical
// apart from the trap-write port name). An xcause splits into:
//   * Interrupt      = bit[63]        (1 = interrupt, 0 = exception).
//   * ExceptionCode  = bits[62:0]     (the cause code).
// Both async-reset to 0.
//
// Write enable = w_wen OR trap-entry valid. On a trap the trap Interrupt/code
// are latched; a concurrent CSR write ORs in w_wdata (golden OR-of-muxes form,
// transcribed verbatim). rdata = {Interrupt, ExceptionCode}.
//
// The generic trap port is named trap_*; each wrapper connects its specific
// golden trap pins.

module xs_cause (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_Interrupt,
    output [62:0] regOut_ExceptionCode,
    input         trap_valid,
    input         trap_bits_Interrupt,
    input  [62:0] trap_bits_ExceptionCode
);

  reg        reg_Interrupt;
  reg [62:0] reg_ExceptionCode;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_Interrupt     <= 1'h0;
      reg_ExceptionCode <= 63'h0;
    end
    else if (w_wen | trap_valid) begin
      reg_Interrupt <=
        trap_valid & trap_bits_Interrupt | w_wen & w_wdata[63];
      reg_ExceptionCode <=
        (trap_valid ? trap_bits_ExceptionCode : 63'h0)
        | (w_wen ? w_wdata[62:0] : 63'h0);
    end
  end

  assign rdata                = {reg_Interrupt, reg_ExceptionCode};
  assign regOut_Interrupt     = reg_Interrupt;
  assign regOut_ExceptionCode = reg_ExceptionCode;

endmodule
