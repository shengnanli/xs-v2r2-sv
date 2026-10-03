// MflushpwrModule.sv — machine L2 flush power control CSR.
// The enable bit is stored; completion is a live status input and is never registered.
// The wrapper keeps the exact flattened CSR status and control ports.
module xs_MflushpwrModule_core (
  input logic clock, input logic reset, input logic csr_wen,
  input logic [63:0] csr_wdata,
  output logic [63:0] rdata, output logic flush_l2_enable,
  output logic l2_flush_done, input logic l2_flush_done_in
);
  logic flush_l2_enable_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      flush_l2_enable_q <= 1'b0;
    else if (csr_wen)
      flush_l2_enable_q <= csr_wdata[0];
  end

  assign rdata = {62'h0, l2_flush_done_in, flush_l2_enable_q};
  assign flush_l2_enable = flush_l2_enable_q;
  assign l2_flush_done = l2_flush_done_in;
endmodule

// BEGIN GENERATED(csr_m) — generated wrapper; do not edit this block.
module MflushpwrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_FLUSH_L2_ENABLE,
  output        regOut_L2_FLUSH_DONE,
  input         l2FlushDone
);

  xs_MflushpwrModule_core u_core (
    .clock            (clock),
    .reset            (reset),
    .csr_wen          (w_wen),
    .csr_wdata        (w_wdata),
    .rdata            (rdata),
    .flush_l2_enable  (regOut_FLUSH_L2_ENABLE),
    .l2_flush_done    (regOut_L2_FLUSH_DONE),
    .l2_flush_done_in (l2FlushDone)
  );
endmodule
// END GENERATED
