// BEGIN GENERATED(pmpcfg-leaves8)
// Pmp5cfgModule is PMP configuration CSR entry 5 in NewCSR.
// The shared core implements WARL permissions, lock behavior, and reset.
// This wrapper preserves the exact golden port contract for integration.
module Pmp5cfgModule (
  input logic clock,
  input logic reset,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [7:0] rdata,
  output logic regOut_R,
  output logic regOut_W,
  output logic regOut_X,
  output logic [1:0] regOut_A,
  output logic regOut_L
);
  xs_Pmpcfg_core #(.SLOT(5)) u_core (
    .clk     (clock),
    .rst     (reset),
    .wr_en   (w_wen),
    .wr_data (w_wdata),
    .rd_data (rdata),
    .cfg_r   (regOut_R),
    .cfg_w   (regOut_W),
    .cfg_x   (regOut_X),
    .cfg_a   (regOut_A),
    .cfg_l   (regOut_L)
  );
endmodule
// END GENERATED(pmpcfg-leaves8)
