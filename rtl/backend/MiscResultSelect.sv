// Select and format the ALU miscellaneous channel.  The hierarchy of
// function bits is significant: bit 5 overrides every lower family, then bit
// 4 chooses byte/pack or shift-add operations, and bit 3 selects subfamilies.
module xs_MiscResultSelect_core (
  input  logic [5:0]  function_code,
  input  logic [63:0] and_result,
  input  logic [63:0] or_result,
  input  logic [63:0] xor_result,
  input  logic [63:0] or_combine_bytes,
  input  logic [63:0] or_high_48,
  input  logic [63:0] sign_extend_byte,
  input  logic [63:0] pack_high,
  input  logic [63:0] sign_extend_half,
  input  logic [63:0] pack_word,
  input  logic [63:0] reverse_bits_in_bytes,
  input  logic [63:0] reverse_bytes,
  input  logic [63:0] pack,
  input  logic [63:0] source,
  output logic [63:0] selected_result
);
  logic [63:0] logic_result;

  always_comb begin
    case (function_code[2:1])
      2'd0:    logic_result = and_result;
      2'd1:    logic_result = or_result;
      2'd2:    logic_result = xor_result;
      default: logic_result = or_combine_bytes;
    endcase

    if (function_code[5]) begin
      selected_result = {48'b0,
                         logic_result[15:1] & {15{function_code[0]}},
                         logic_result[0]};
    end else if (function_code[4]) begin
      if (function_code[3]) begin
        case (function_code[1:0])
          2'd0:    selected_result = {31'b0, source[31:0], 1'b0};
          2'd1:    selected_result = {30'b0, source[31:0], 2'b0};
          2'd2:    selected_result = {29'b0, source[31:0], 3'b0};
          default: selected_result = {56'b0, source[15:8]};
        endcase
      end else begin
        case (function_code[1:0])
          2'd0:    selected_result = reverse_bits_in_bytes;
          2'd1:    selected_result = reverse_bytes;
          2'd2:    selected_result = pack;
          default: selected_result = or_high_48;
        endcase
      end
    end else if (function_code[3]) begin
      case (function_code[1:0])
        2'd0:    selected_result = sign_extend_byte;
        2'd1:    selected_result = pack_high;
        2'd2:    selected_result = sign_extend_half;
        default: selected_result = pack_word;
      endcase
    end else begin
      selected_result = logic_result;
    end
  end
endmodule

module MiscResultSelect (
  input  logic [5:0]  io_func,
  input  logic [63:0] io_and,
  input  logic [63:0] io_or,
  input  logic [63:0] io_xor,
  input  logic [63:0] io_orcb,
  input  logic [63:0] io_orh48,
  input  logic [63:0] io_sextb,
  input  logic [63:0] io_packh,
  input  logic [63:0] io_sexth,
  input  logic [63:0] io_packw,
  input  logic [63:0] io_revb,
  input  logic [63:0] io_rev8,
  input  logic [63:0] io_pack,
  input  logic [63:0] io_src,
  output logic [63:0] io_miscRes
);
  xs_MiscResultSelect_core u_select (
    .function_code(io_func),
    .and_result(io_and),
    .or_result(io_or),
    .xor_result(io_xor),
    .or_combine_bytes(io_orcb),
    .or_high_48(io_orh48),
    .sign_extend_byte(io_sextb),
    .pack_high(io_packh),
    .sign_extend_half(io_sexth),
    .pack_word(io_packw),
    .reverse_bits_in_bytes(io_revb),
    .reverse_bytes(io_rev8),
    .pack(io_pack),
    .source(io_src),
    .selected_result(io_miscRes)
  );
endmodule
