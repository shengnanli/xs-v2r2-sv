// Shift a 65-bit value right and report whether any discarded bit was one.
// A shift equal to the data width discards every bit; a larger shift also returns zero.
// The explicit discarded-bit mask keeps the IEEE-style sticky/jam behavior visible.
module ShiftRightJam (
  input  logic [64:0] io_in,
  input  logic [10:0] io_shamt,
  output logic [64:0] io_out,
  output logic                 io_sticky
);
  logic [64:0] discarded_mask;
  logic                 exceeds_input_width;

  assign exceeds_input_width = io_shamt > 11'd65;
  assign discarded_mask = exceeds_input_width
    ? {65{1'b1}}
    : (({{64{1'b0}}, 1'b1} << io_shamt) - 1'b1);

  assign io_out = exceeds_input_width ? 65'b0 : io_in >> io_shamt;
  assign io_sticky = |(io_in & discarded_mask);
endmodule
