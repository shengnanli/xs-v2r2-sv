// xs_Pmpcfg_core_next20d.sv — PMP configuration byte core for Pmp13..20.
// This private family core is isolated from earlier lanes and serves eight
// childless NewCSR leaves.  LEAF_INDEX documents the selected parent entry.
// It stores R/W/X/A/L with asynchronous reset and exposes the packed CSR byte.
// A=2 is WARL-converted to 3; reserved R=0,W=1 suppresses only W's update.
module xs_Pmpcfg_core_next20d #(
  parameter int unsigned LEAF_INDEX = 0
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        wr_en,
  input  logic [63:0] wr_data,
  output logic [7:0]  rd_data,
  output logic        cfg_r,
  output logic        cfg_w,
  output logic        cfg_x,
  output logic [1:0]  cfg_a,
  output logic        cfg_l
);
  localparam int unsigned R_BIT = 0;
  localparam int unsigned W_BIT = 1;
  localparam int unsigned X_BIT = 2;
  localparam int unsigned A_LOW = 3;
  localparam int unsigned A_HIGH = 4;
  localparam int unsigned L_BIT = 7;

  logic r_q;
  logic w_q;
  logic x_q;
  logic [1:0] a_q;
  logic l_q;
  logic write_w_allowed;
  logic [1:0] write_a_warl;

  assign write_w_allowed = wr_data[R_BIT] | ~wr_data[W_BIT];
  assign write_a_warl = (wr_data[A_HIGH:A_LOW] == 2'd2)
                      ? 2'd3 : wr_data[A_HIGH:A_LOW];

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      r_q <= 1'b0;
      w_q <= 1'b0;
      x_q <= 1'b0;
      a_q <= 2'b00;
      l_q <= 1'b0;
    end else begin
      if (wr_en) begin
        r_q <= wr_data[R_BIT];
        x_q <= wr_data[X_BIT];
        a_q <= write_a_warl;
        l_q <= wr_data[L_BIT];
      end
      if (wr_en && write_w_allowed)
        w_q <= wr_data[W_BIT];
    end
  end

  assign rd_data = {l_q, 2'b00, a_q, x_q, w_q, r_q};
  assign cfg_r = r_q;
  assign cfg_w = w_q;
  assign cfg_x = x_q;
  assign cfg_a = a_q;
  assign cfg_l = l_q;
endmodule
