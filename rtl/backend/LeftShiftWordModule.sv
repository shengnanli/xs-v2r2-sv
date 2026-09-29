// Two independent fixed-width logical left shifts of one source operand.
// Each result wraps naturally at 32 bits; no wider carry state is retained.
// Separate shift controls serve the normal and bit-reversed ALU data paths.
module xs_LeftShiftWordModule_core (
  input  logic [31:0]       source,
  input  logic [4:0] shift_amount,
  input  logic [4:0] reverse_shift_amount,
  output logic [31:0]       shifted,
  output logic [31:0]       reverse_shifted
);
  assign shifted = source << shift_amount;
  assign reverse_shifted = source << reverse_shift_amount;
endmodule

module LeftShiftWordModule (
  input  logic [4:0] io_shamt,
  input  logic [4:0] io_revShamt,
  input  logic [31:0]       io_sllSrc,
  output logic [31:0]       io_sllw,
  output logic [31:0]       io_revSllw
);
  xs_LeftShiftWordModule_core u_core (
    .source               (io_sllSrc),
    .shift_amount         (io_shamt),
    .reverse_shift_amount (io_revShamt),
    .shifted              (io_sllw),
    .reverse_shifted      (io_revSllw)
  );
endmodule
