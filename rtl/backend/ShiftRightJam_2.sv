// Shift a 25-bit value right and report whether any discarded bit was one.
// A shift equal to the data width discards every bit; a larger shift also returns zero.
// The explicit discarded-bit mask keeps the IEEE-style sticky/jam behavior visible.
module ShiftRightJam_2 (
  input  logic [24:0] io_in,
  input  logic [7:0] io_shamt,
  output logic [24:0] io_out,
  output logic                 io_sticky
);
  logic [24:0] discarded_mask;
  logic                 exceeds_input_width;

  assign exceeds_input_width = io_shamt > 8'd25;
  assign discarded_mask = exceeds_input_width
    ? {25{1'b1}}
    : (({{24{1'b0}}, 1'b1} << io_shamt) - 1'b1);

  assign io_out = exceeds_input_width ? 25'b0 : io_in >> io_shamt;
  assign io_sticky = |(io_in & discarded_mask);
endmodule
