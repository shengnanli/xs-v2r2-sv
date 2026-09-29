// Final result multiplexer at the output of the integer ALU datapath.
// The function code chooses among six already-computed result channels.
// Its encoding is sparse: the three middle values all select miscellaneous.
module xs_AluResSel_core (
  input  logic [2:0]  function_code,
  input  logic [63:0] add_result,
  input  logic [63:0] shift_result,
  input  logic [63:0] misc_result,
  input  logic [63:0] compare_result,
  input  logic [63:0] word_result,
  input  logic [63:0] conditional_result,
  output logic [63:0] selected_result
);
  always_comb begin
    case (function_code)
      3'd0: selected_result = shift_result;
      3'd1: selected_result = word_result;
      3'd2: selected_result = add_result;
      3'd3: selected_result = compare_result;
      3'd7: selected_result = conditional_result;
      default: selected_result = misc_result;
    endcase
  end
endmodule

module AluResSel (
  input  logic [2:0]  io_func,
  input  logic [63:0] io_addRes,
  input  logic [63:0] io_shiftRes,
  input  logic [63:0] io_miscRes,
  input  logic [63:0] io_compareRes,
  input  logic [63:0] io_wordRes,
  input  logic [63:0] io_condRes,
  output logic [63:0] io_aluRes
);
  xs_AluResSel_core u_select (
    .function_code(io_func),
    .add_result(io_addRes),
    .shift_result(io_shiftRes),
    .misc_result(io_miscRes),
    .compare_result(io_compareRes),
    .word_result(io_wordRes),
    .conditional_result(io_condRes),
    .selected_result(io_aluRes)
  );
endmodule
