// Two independent fixed-width logical left shifts of one source operand.
// Each result wraps naturally at 64 bits; no wider carry state is retained.
// Separate shift controls serve the normal and bit-reversed ALU data paths.
module xs_LeftShiftModule_core (
  input  logic [63:0]       source,
  input  logic [5:0] shift_amount,
  input  logic [5:0] reverse_shift_amount,
  output logic [63:0]       shifted,
  output logic [63:0]       reverse_shifted
);
  assign shifted = source << shift_amount;
  assign reverse_shifted = source << reverse_shift_amount;
endmodule

module LeftShiftModule (
  input  logic [5:0] io_shamt,
  input  logic [5:0] io_revShamt,
  input  logic [63:0]       io_sllSrc,
  output logic [63:0]       io_sll,
  output logic [63:0]       io_revSll
);
  xs_LeftShiftModule_core u_core (
    .source               (io_sllSrc),
    .shift_amount         (io_shamt),
    .reverse_shift_amount (io_revShamt),
    .shifted              (io_sll),
    .reverse_shifted      (io_revSll)
  );
endmodule
