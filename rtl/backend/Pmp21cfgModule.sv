// Pmp21cfgModule.sv — PMP configuration CSR leaf 21.
// This tail wrapper preserves the G1 module name and exact port contract while
// reusing the single canonical PMP state machine.  SLOT is the architectural
// PMP entry number, including the 21..31 tail; it is not local.
// The shared core owns asynchronous reset, WARL, reserved R/W handling, and
// decoded outputs.
// BEGIN GENERATED(pmpcfg-tail-wrapper)
module Pmp21cfgModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [7:0]  rdata,
  output        regOut_R,
  output        regOut_W,
  output        regOut_X,
  output [1:0]  regOut_A,
  output        regOut_L
);
  xs_Pmpcfg_core #(.SLOT(21)) u_core (
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
// END GENERATED(pmpcfg-tail-wrapper)
