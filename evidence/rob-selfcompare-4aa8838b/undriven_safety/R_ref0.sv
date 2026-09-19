// ref drives o2 with something that is IDENTICALLY 0 -- a dead driver.
module U(input clock, input reset, input a, input b, output o1, output o2);
  reg q1;
  wire dead = a & ~a;            // constant 0, but syntactically driven
  always @(posedge clock) begin
    if (reset) q1 <= 1'b0; else q1 <= a & b;
  end
  assign o1 = q1;
  assign o2 = dead;
endmodule
