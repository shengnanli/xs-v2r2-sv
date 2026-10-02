// Result multiplexer for 32-bit integer word operations.
// It selects one precomputed value, then sign-extends that word to 64 bits.
// Only function_code[3:0] participates in this leaf's selection.
module xs_WordResultSelect_core (
  input  logic [8:0]  function_code,
  input  logic [31:0] shift_left_word,
  input  logic [31:0] shift_right_logical_word,
  input  logic [31:0] shift_right_arithmetic_word,
  input  logic [31:0] rotate_left_word,
  input  logic [31:0] rotate_right_word,
  input  logic [31:0] add_word,
  input  logic [31:0] subtract_word,
  output logic [63:0] selected_result
);
  logic [31:0] selected_word;

  always_comb begin
    if (function_code[3]) begin
      if (function_code[2])
        selected_word = function_code[0] ? rotate_right_word : rotate_left_word;
      else if (function_code[1])
        selected_word = shift_right_arithmetic_word;
      else
        selected_word = function_code[0] ? shift_right_logical_word : shift_left_word;
    end else begin
      selected_word = (function_code[2:0] == 3'b010) ? subtract_word : add_word;
    end
    selected_result = {{32{selected_word[31]}}, selected_word};
  end
endmodule

module WordResultSelect (
  input  logic [8:0]  io_func,
  input  logic [31:0] io_sllw,
  input  logic [31:0] io_srlw,
  input  logic [31:0] io_sraw,
  input  logic [31:0] io_rolw,
  input  logic [31:0] io_rorw,
  input  logic [31:0] io_addw,
  input  logic [31:0] io_subw,
  output logic [63:0] io_wordRes
);
  xs_WordResultSelect_core u_select (
    .function_code(io_func),
    .shift_left_word(io_sllw),
    .shift_right_logical_word(io_srlw),
    .shift_right_arithmetic_word(io_sraw),
    .rotate_left_word(io_rolw),
    .rotate_right_word(io_rorw),
    .add_word(io_addw),
    .subtract_word(io_subw),
    .selected_result(io_wordRes)
  );
endmodule
