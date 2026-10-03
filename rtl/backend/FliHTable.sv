// FliHTable: 5-bit floating-point lookup table used by the arithmetic datapath.
// Each entry is an explicit value from the G1 combinational truth table; no state is present.
// The case form keeps the lookup readable while preserving every legal binary input result.
module FliHTable (input logic [4:0] src, output logic [15:0] out);
  always_comb begin
    case (src)
      5'h00: out = 16'hbc00;
      5'h01: out = 16'h0400;
      5'h02: out = 16'h0100;
      5'h03: out = 16'h0200;
      5'h04: out = 16'h1c00;
      5'h05: out = 16'h2000;
      5'h06: out = 16'h2c00;
      5'h07: out = 16'h3000;
      5'h08: out = 16'h3400;
      5'h09: out = 16'h3500;
      5'h0a: out = 16'h3600;
      5'h0b: out = 16'h3700;
      5'h0c: out = 16'h3800;
      5'h0d: out = 16'h3900;
      5'h0e: out = 16'h3a00;
      5'h0f: out = 16'h3b00;
      5'h10: out = 16'h3c00;
      5'h11: out = 16'h3d00;
      5'h12: out = 16'h3e00;
      5'h13: out = 16'h3f00;
      5'h14: out = 16'h4000;
      5'h15: out = 16'h4100;
      5'h16: out = 16'h4200;
      5'h17: out = 16'h4400;
      5'h18: out = 16'h4800;
      5'h19: out = 16'h4c00;
      5'h1a: out = 16'h5800;
      5'h1b: out = 16'h5c00;
      5'h1c: out = 16'h7800;
      5'h1d: out = 16'h7c00;
      5'h1e: out = 16'h7c00;
      5'h1f: out = 16'h7e00;
      default: out = 16'hxxxx;
    endcase
  end
endmodule
