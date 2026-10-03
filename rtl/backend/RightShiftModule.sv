// Compute logical, arithmetic, and reverse-control right shifts for 64-bit operands.
// Logical paths shift zeroes in; the arithmetic path propagates the source sign bit.
// Separate shift controls preserve the generated ALU leaf interface without hidden state.
module RightShiftModule (
  input  logic [5:0] io_shamt,
  input  logic [5:0] io_revShamt,
  input  logic [63:0] io_srlSrc,
  input  logic [63:0] io_sraSrc,
  output logic [63:0] io_srl,
  output logic [63:0] io_sra,
  output logic [63:0] io_revSrl
);
  assign io_srl = io_srlSrc >> io_shamt;
  assign io_sra = $signed(io_sraSrc) >>> io_shamt;
  assign io_revSrl = io_srlSrc >> io_revShamt;
endmodule
