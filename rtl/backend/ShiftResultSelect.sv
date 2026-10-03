// Result multiplexer for 64-bit shifts, rotates, and single-bit operations.
// Inputs are already-computed datapath values; this leaf only decodes control.
// Rotate encodings deliberately ignore function_code[2] and [0].
module xs_ShiftResultSelect_core (
  input  logic [3:0]  function_code,
  input  logic [63:0] shift_left,
  input  logic [63:0] shift_right_logical,
  input  logic [63:0] shift_right_arithmetic,
  input  logic [63:0] rotate_left,
  input  logic [63:0] rotate_right,
  input  logic [63:0] bit_clear,
  input  logic [63:0] bit_set,
  input  logic [63:0] bit_invert,
  input  logic [63:0] bit_extract,
  output logic [63:0] selected_result
);
  always_comb begin
    if (function_code[3]) begin
      selected_result = function_code[1] ? rotate_right : rotate_left;
    end else begin
      case (function_code[2:0])
        3'd0, 3'd1: selected_result = shift_left;
        3'd2:       selected_result = bit_clear;
        3'd3:       selected_result = bit_set;
        3'd4:       selected_result = bit_invert;
        3'd5:       selected_result = shift_right_logical;
        3'd6:       selected_result = bit_extract;
        default:    selected_result = shift_right_arithmetic;
      endcase
    end
  end
endmodule

module ShiftResultSelect (
  input  logic [3:0]  io_func,
  input  logic [63:0] io_sll,
  input  logic [63:0] io_srl,
  input  logic [63:0] io_sra,
  input  logic [63:0] io_rol,
  input  logic [63:0] io_ror,
  input  logic [63:0] io_bclr,
  input  logic [63:0] io_bset,
  input  logic [63:0] io_binv,
  input  logic [63:0] io_bext,
  output logic [63:0] io_shiftRes
);
  xs_ShiftResultSelect_core u_select (
    .function_code(io_func),
    .shift_left(io_sll),
    .shift_right_logical(io_srl),
    .shift_right_arithmetic(io_sra),
    .rotate_left(io_rol),
    .rotate_right(io_ror),
    .bit_clear(io_bclr),
    .bit_set(io_bset),
    .bit_invert(io_binv),
    .bit_extract(io_bext),
    .selected_result(io_shiftRes)
  );
endmodule
