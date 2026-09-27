// Integer adder providing independent XLEN and word-width results.
// The word path uses its dedicated first operand and the low half of source one.
// Both paths intentionally discard carry beyond their public widths.
module xs_AddModule_core(input logic [63:0] lhs, rhs, input logic [31:0] word_lhs,
                         output logic [63:0] full_sum, output logic [31:0] word_sum);
  assign full_sum = lhs + rhs;
  assign word_sum = word_lhs + rhs[31:0];
endmodule
module AddModule(input logic [63:0] io_src_0, input logic [63:0] io_src_1,
                 input logic [31:0] io_srcw, output logic [63:0] io_add,
                 output logic [31:0] io_addw);
  xs_AddModule_core u_core(.lhs(io_src_0), .rhs(io_src_1), .word_lhs(io_srcw),
                           .full_sum(io_add), .word_sum(io_addw));
endmodule
