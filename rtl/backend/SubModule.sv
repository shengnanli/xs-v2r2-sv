// Unsigned 64-bit subtraction with an explicit 65-bit extended result.
// The upper bit retains the modular borrow/carry convention used by the ALU.
// Two's-complement addition is widened before the operation so bit 64 is carry-out.
module xs_SubModule_core(input logic [63:0] lhs, rhs, output logic [64:0] difference);
  assign difference = {1'b0, lhs} + {1'b0, ~rhs} + 65'd1;
endmodule
module SubModule(input logic [63:0] io_src_0, input logic [63:0] io_src_1,
                 output logic [64:0] io_sub);
  xs_SubModule_core u_core(.lhs(io_src_0), .rhs(io_src_1), .difference(io_sub));
endmodule
