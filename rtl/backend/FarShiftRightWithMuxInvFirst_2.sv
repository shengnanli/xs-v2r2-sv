// Fixed-width right shifter used by the floating-point far path.
// fill_bit is prepended as a sign bit, making it the value shifted into every
// vacated upper position without interpreting the source payload as signed.
module xs_FarShiftRightWithMuxInvFirst_2_core (
  input  logic [51:0]       source,
  input  logic [4:0] shift_amount,
  input  logic                       fill_bit,
  output logic [51:0]       result
);
  logic signed [52:0] source_with_fill;

  assign source_with_fill = {fill_bit, source};
  assign result = source_with_fill >>> shift_amount;
endmodule

module FarShiftRightWithMuxInvFirst_2 (
  input  logic [51:0]       io_src,
  input  logic [4:0] io_shiftValue,
  output logic [51:0]       io_result,
  input  logic                       io_EOP
);
  xs_FarShiftRightWithMuxInvFirst_2_core u_core (
    .source       (io_src),
    .shift_amount (io_shiftValue),
    .fill_bit     (io_EOP),
    .result       (io_result)
  );
endmodule
