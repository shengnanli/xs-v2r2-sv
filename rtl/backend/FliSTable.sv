// FliSTable: 5-bit floating-point lookup table used by the arithmetic datapath.
// Each entry is an explicit value from the G1 combinational truth table; no state is present.
// The case form keeps the lookup readable while preserving every legal binary input result.
module FliSTable (input logic [4:0] src, output logic [15:0] out);
  always_comb begin
    case (src)
      5'h00: out = 16'hbf80;
      5'h01: out = 16'h0080;
      5'h02: out = 16'h3780;
      5'h03: out = 16'h3800;
      5'h04: out = 16'h3b80;
      5'h05: out = 16'h3c00;
      5'h06: out = 16'h3d80;
      5'h07: out = 16'h3e00;
      5'h08: out = 16'h3e80;
      5'h09: out = 16'h3ea0;
      5'h0a: out = 16'h3ec0;
      5'h0b: out = 16'h3ee0;
      5'h0c: out = 16'h3f00;
      5'h0d: out = 16'h3f20;
      5'h0e: out = 16'h3f40;
      5'h0f: out = 16'h3f60;
      5'h10: out = 16'h3f80;
      5'h11: out = 16'h3fa0;
      5'h12: out = 16'h3fc0;
      5'h13: out = 16'h3fe0;
      5'h14: out = 16'h4000;
      5'h15: out = 16'h4020;
      5'h16: out = 16'h4040;
      5'h17: out = 16'h4080;
      5'h18: out = 16'h4100;
      5'h19: out = 16'h4180;
      5'h1a: out = 16'h4300;
      5'h1b: out = 16'h4380;
      5'h1c: out = 16'h4700;
      5'h1d: out = 16'h4780;
      5'h1e: out = 16'h7f80;
      5'h1f: out = 16'h7fc0;
      default: out = 16'hxxxx;
    endcase
  end
endmodule
