// Fixed-width logical left shifter used by the floating-point close path.
// Bits shifted beyond the 12-bit result are intentionally discarded.
// The shift amount remains unsigned and includes all encoded boundary values.
module xs_CloseShiftLeftWithMux_9_core (
  input  logic [11:0]       source,
  input  logic [3:0] shift_amount,
  output logic [11:0]       result
);
  assign result = source << shift_amount;
endmodule

module CloseShiftLeftWithMux_9 (
  input  logic [11:0]       io_src,
  input  logic [3:0] io_shiftValue,
  output logic [11:0]       io_result
);
  xs_CloseShiftLeftWithMux_9_core u_core (
    .source       (io_src),
    .shift_amount (io_shiftValue),
    .result       (io_result)
  );
endmodule
