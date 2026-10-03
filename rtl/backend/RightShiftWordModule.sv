// Compute logical, arithmetic, and reverse-control right shifts for 32-bit operands.
// Logical paths shift zeroes in; the arithmetic path propagates the source sign bit.
// Separate shift controls preserve the generated ALU leaf interface without hidden state.
module RightShiftWordModule (
  input  logic [4:0] io_shamt,
  input  logic [4:0] io_revShamt,
  input  logic [31:0] io_srlSrc,
  input  logic [31:0] io_sraSrc,
  output logic [31:0] io_srlw,
  output logic [31:0] io_sraw,
  output logic [31:0] io_revSrlw
);
  assign io_srlw = io_srlSrc >> io_shamt;
  assign io_sraw = $signed(io_sraSrc) >>> io_shamt;
  assign io_revSrlw = io_srlSrc >> io_revShamt;
endmodule
