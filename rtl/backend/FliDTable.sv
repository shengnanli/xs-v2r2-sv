// FliDTable: 5-bit floating-point lookup table used by the arithmetic datapath.
// Each entry is an explicit value from the G1 combinational truth table; no state is present.
// The case form keeps the lookup readable while preserving every legal binary input result.
module FliDTable (input logic [4:0] src, output logic [15:0] out);
  always_comb begin
    case (src)
      5'h00: out = 16'hbff0;
      5'h01: out = 16'h0010;
      5'h02: out = 16'h3ef0;
      5'h03: out = 16'h3f00;
      5'h04: out = 16'h3f70;
      5'h05: out = 16'h3f80;
      5'h06: out = 16'h3fb0;
      5'h07: out = 16'h3fc0;
      5'h08: out = 16'h3fd0;
      5'h09: out = 16'h3fd4;
      5'h0a: out = 16'h3fd8;
      5'h0b: out = 16'h3fdc;
      5'h0c: out = 16'h3fe0;
      5'h0d: out = 16'h3fe4;
      5'h0e: out = 16'h3fe8;
      5'h0f: out = 16'h3fec;
      5'h10: out = 16'h3ff0;
      5'h11: out = 16'h3ff4;
      5'h12: out = 16'h3ff8;
      5'h13: out = 16'h3ffc;
      5'h14: out = 16'h4000;
      5'h15: out = 16'h4004;
      5'h16: out = 16'h4008;
      5'h17: out = 16'h4010;
      5'h18: out = 16'h4020;
      5'h19: out = 16'h4030;
      5'h1a: out = 16'h4060;
      5'h1b: out = 16'h4070;
      5'h1c: out = 16'h40e0;
      5'h1d: out = 16'h40f0;
      5'h1e: out = 16'h7ff0;
      5'h1f: out = 16'h7ff8;
      default: out = 16'hxxxx;
    endcase
  end
endmodule
