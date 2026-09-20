module U(input clock, input reset, input a, input b, output o1, output o2);
  reg q1, q2;
  always @(posedge clock) begin
    if (reset) begin q1 <= 1'b0; q2 <= 1'b0; end
    else begin q1 <= a & b; q2 <= a | b; end
  end
  assign o1 = q1;
  assign o2 = q2;
endmodule
