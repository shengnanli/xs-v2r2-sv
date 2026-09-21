module T(
  input        clock,
  input  [1:0] sel,
  input  [7:0] din,
  output [7:0] o_up,
  output [7:0] o_drv
);
  reg [7:0] g_0;
  reg [7:0] g_1;
  reg [7:0] g_2;
  reg [7:0] g_3;
  reg [7:0] d_0;
  always @(posedge clock) d_0 <= din;
  wire [31:0] _GEN = {g_3, g_2, g_1, g_0};
  assign o_up  = _GEN[sel*8 +: 8];
  assign o_drv = d_0;
endmodule
