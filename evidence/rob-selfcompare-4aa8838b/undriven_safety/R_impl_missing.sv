module U(input clock, input reset, input a, input b, output o1, output o2);
  reg q1;
  wire q2_undriven;              // declared, never driven -- the injected defect
  always @(posedge clock) begin
    if (reset) q1 <= 1'b0;
    else       q1 <= a & b;
  end
  assign o1 = q1;
  assign o2 = q2_undriven;
endmodule
