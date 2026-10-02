// Pmp17cfgModule.sv — NewCSR PMP configuration byte 17.
// This childless CSR leaf stores the R/W/X/A/L fields and exposes both the
// packed CSR read view and decoded fields to the parent NewCSR module.
// All eight Pmp13..20 variants share xs_Pmpcfg_core_next20d; only the golden wrapper
// name and parent address decode differ.  The core preserves asynchronous reset,
// A=2 WARL conversion to NAPOT, and the reserved R=0/W=1 write rule exactly.
// The port contract and instance wiring below are generated from read-only G1
// golden RTL by scripts/gen_pmpcfg_leaves8b.py; do not hand-edit that region.
module Pmp17cfgModule (
// BEGIN GENERATED(pmpcfg-leaves8b-wrapper)
  input  logic         clock,
  input  logic         reset,
  input  logic         w_wen,
  input  logic [63:0]  w_wdata,
  output logic [7:0]   rdata,
  output logic         regOut_R,
  output logic         regOut_W,
  output logic         regOut_X,
  output logic [1:0]   regOut_A,
  output logic         regOut_L
// END GENERATED
);
  xs_Pmpcfg_core_next20d #(.LEAF_INDEX(17)) u_core (
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
