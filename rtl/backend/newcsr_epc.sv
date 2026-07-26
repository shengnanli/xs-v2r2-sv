// NewCSR CSR-field primitive: epc (exception program counter CSR).
//
// Faithful, readable, parameterized reimplementation of the golden xepc family
// (MepcModule / SepcModule / VSepcModule — all byte-identical apart from the
// trap-write port name, which each wrapper remaps). An xepc holds the 63 high
// bits of the program counter; the architectural bit[0] is WARL-forced to 0
// (RVC alignment), so the stored register is 63 bits and rdata appends a 0 LSB.
//
//   * reg_epc[62:0] : async-reset to 0.
//   * write enable  : w_wen OR trap-entry valid. On a trap the trap epc bits
//                     are latched; a concurrent CSR write ORs in w_wdata[63:1].
//                     (Golden uses the exact OR-of-two-muxes form; transcribed.)
//   * rdata         = {reg_epc, 1'h0}.
//
// The generic trap port is named trap_valid/trap_bits_epc here; each golden
// top wraps this and connects its specific trapToM_mepc_*/trapToHS_sepc_* pins.

module xs_epc (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output [62:0] regOut_epc,
    input         trap_valid,
    input  [62:0] trap_bits_epc
);

  reg [62:0] reg_epc;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_epc <= 63'h0;
    else if (w_wen | trap_valid)
      reg_epc <=
        (trap_valid ? trap_bits_epc : 63'h0)
        | (w_wen ? w_wdata[63:1] : 63'h0);
  end

  assign rdata      = {reg_epc, 1'h0};
  assign regOut_epc = reg_epc;

endmodule
