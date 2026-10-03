// Close-path floating-point subtractor with zero-extended operands.
// The 25-bit result preserves the borrow/sign information required downstream.
// Explicit extension documents sizing and avoids implicit-expression ambiguity.
module xs_ClosePathF32WidenF16MixedPipelineAdder_core (
  input logic [23:0] lhs, rhs,
  output logic [24:0] difference
);
  assign difference = {1'b0, lhs} - {1'b0, rhs};
endmodule
module ClosePathF32WidenF16MixedPipelineAdder (
  input logic [23:0] io_adder_op0,
  input logic [23:0] io_adder_op1,
  output logic [24:0] io_result
);
  xs_ClosePathF32WidenF16MixedPipelineAdder_core u_core (.lhs(io_adder_op0), .rhs(io_adder_op1), .difference(io_result));
endmodule
