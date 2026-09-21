module S(input clock, input d, output o1, output o2, output o3);
  reg g_0; reg g_1; reg q;
  always @(posedge clock) q <= d;
  assign o1 = g_0;
  assign o2 = g_1;
  assign o3 = q;
endmodule
