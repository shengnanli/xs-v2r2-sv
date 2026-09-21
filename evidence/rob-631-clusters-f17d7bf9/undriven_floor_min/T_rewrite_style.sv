module T_core(
  input  logic        clock,
  input  logic [1:0]  sel,
  input  logic [7:0]  din,
  output logic [7:0]  o_up,
  output logic [7:0]  o_drv
);
  logic [7:0] g [4];
  logic [7:0] d_0;
  always_ff @(posedge clock) d_0 <= din;
  always_comb begin
    o_up = g[0];
    for (int b = 0; b < 4; b++) if (sel == 2'(b)) o_up = g[b];
  end
  assign o_drv = d_0;
endmodule
module T(
  input  logic        clock,
  input  logic [1:0]  sel,
  input  logic [7:0]  din,
  output logic [7:0]  o_up,
  output logic [7:0]  o_drv
);
  T_core u_core(.clock(clock), .sel(sel), .din(din), .o_up(o_up), .o_drv(o_drv));
endmodule
