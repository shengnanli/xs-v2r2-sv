// Select the signed or unsigned minimum/maximum of three values.
// Maximum ties prefer A, then B, then C. Minimum ties use the reverse
// priority: C, then B, then A. Naming every relation keeps that policy visible.
module compare_3to1_6 (
  input  logic [7:0] io_a,
  input  logic [7:0] io_b,
  input  logic [7:0] io_c,
  input  logic               io_max,
  input  logic               io_signed,
  output logic [7:0] io_d
);
  logic a_less_than_b;
  logic a_less_than_c;
  logic b_less_than_c;

  always_comb begin
    if (io_signed) begin
      a_less_than_b = $signed(io_a) < $signed(io_b);
      a_less_than_c = $signed(io_a) < $signed(io_c);
      b_less_than_c = $signed(io_b) < $signed(io_c);
    end else begin
      a_less_than_b = io_a < io_b;
      a_less_than_c = io_a < io_c;
      b_less_than_c = io_b < io_c;
    end
  end

  always_comb begin
    if (io_max) begin
      if (!a_less_than_b && !a_less_than_c)
        io_d = io_a;
      else if (!b_less_than_c)
        io_d = io_b;
      else
        io_d = io_c;
    end else begin
      if (a_less_than_b && a_less_than_c)
        io_d = io_a;
      else if (b_less_than_c)
        io_d = io_b;
      else
        io_d = io_c;
    end
  end
endmodule
