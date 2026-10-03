// Select the signed or unsigned minimum/maximum of two values.
// Ties select A for maximum and B for minimum, matching the architectural
// priority encoded by the generated reference implementation.
module compare_2to1_2 (
  input  logic [7:0] io_a,
  input  logic [7:0] io_b,
  input  logic               io_max,
  input  logic               io_signed,
  output logic [7:0] io_c
);
  logic a_less_than_b;

  always_comb begin
    if (io_signed)
      a_less_than_b = $signed(io_a) < $signed(io_b);
    else
      a_less_than_b = io_a < io_b;
  end

  always_comb begin
    if (io_max)
      io_c = a_less_than_b ? io_b : io_a;
    else
      io_c = a_less_than_b ? io_a : io_b;
  end
endmodule
