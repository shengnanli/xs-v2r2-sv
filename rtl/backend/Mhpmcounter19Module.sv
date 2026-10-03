// Mhpmcounter19Module.sv — machine-mode HPM counter 19 CSR leaf.
// The architectural index 19 selects HPM3[16]; this is the
// parent-array mapping, not a local tail index.  The canonical shared core
// preserves asynchronous reset, CSR-write priority, six-bit event increment,
// and carry.
// BEGIN GENERATED(mhpmcounter-tail-wrapper)
module Mhpmcounter19Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY,
  input         mcountinhibit_IR,
  input  [28:0] mcountinhibit_HPM3,
  input         countingEn,
  input  [5:0]  perf_value,
  output        toMhpmeventOF
);
  xs_mhpmcounter #(.IDX(16)) u_core (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (w_wen),
    .w_wdata            (w_wdata),
    .rdata              (rdata),
    .regOut_ALL         (regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_CY),
    .mcountinhibit_IR   (mcountinhibit_IR),
    .mcountinhibit_HPM3 (mcountinhibit_HPM3),
    .countingEn         (countingEn),
    .perf_value         (perf_value),
    .toMhpmeventOF      (toMhpmeventOF)
  );
endmodule
// END GENERATED(mhpmcounter-tail-wrapper)
