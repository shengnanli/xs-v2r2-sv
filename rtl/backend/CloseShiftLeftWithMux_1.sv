// Fixed-width logical left shifter used by the floating-point close path.
// Bits shifted beyond the 25-bit result are intentionally discarded.
// The shift amount remains unsigned and includes all encoded boundary values.
module xs_CloseShiftLeftWithMux_1_core (
  input  logic [24:0]       source,
  input  logic [4:0] shift_amount,
  output logic [24:0]       result
);
  assign result = source << shift_amount;
endmodule

module CloseShiftLeftWithMux_1 (
  input  logic [24:0]       io_src,
  input  logic [4:0] io_shiftValue,
  output logic [24:0]       io_result
);
  xs_CloseShiftLeftWithMux_1_core u_core (
    .source       (io_src),
    .shift_amount (io_shiftValue),
    .result       (io_result)
  );
endmodule
