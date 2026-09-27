// Conditional-zero operation shared by czero.eqz and czero.nez.
// is_nez selects which condition sense suppresses the input value.
// Reduction OR performs the architectural zero comparison across all 64 bits.
module xs_ConditionalZeroModule_core(input logic [63:0] condition, value,
                                     input logic is_nez, output logic [63:0] result);
  logic condition_is_zero;
  assign condition_is_zero = ~(|condition);
  assign result = (condition_is_zero ^ is_nez) ? 64'b0 : value;
endmodule
module ConditionalZeroModule(input logic [63:0] io_condition,
  input logic [63:0] io_value, input logic io_isNez, output logic [63:0] io_condRes);
  xs_ConditionalZeroModule_core u_core(.condition(io_condition), .value(io_value),
    .is_nez(io_isNez), .result(io_condRes));
endmodule
