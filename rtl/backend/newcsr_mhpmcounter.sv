// newcsr_mhpmcounter.sv — canonical shared core for machine HPM CSR counters.
// Each MhpmcounterNModule wrapper fixes IDX=N-3, selecting one architectural
// bit from the parent's mcountinhibit_HPM3 array.  The counter is asynchronously
// reset, accepts a CSR write before any event increment, and reports the carry
// from the same six-bit event add to mhpmevent.
// mcountinhibit_CY and mcountinhibit_IR are intentionally unused: they are
// golden ports for the neighboring mcycle/minstret counters, not HPM counters.
module xs_mhpmcounter #(
  parameter int unsigned IDX = 0
) (
  input  logic        clock,
  input  logic        reset,
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic [63:0] regOut_ALL,
  input  logic        mcountinhibit_CY,
  input  logic        mcountinhibit_IR,
  input  logic [28:0] mcountinhibit_HPM3,
  input  logic        countingEn,
  input  logic [5:0]  perf_value,
  output logic        toMhpmeventOF
);
  logic [63:0] counter_q;
  logic        counting_inhibit;
  logic [64:0] counter_add;

  // The CY/IR inputs deliberately have no read sites, matching golden.
  assign counting_inhibit = mcountinhibit_HPM3[IDX] | ~countingEn;
  assign counter_add = {1'b0, counter_q} + {{59{1'b0}}, perf_value};

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      counter_q <= 64'h0;
    else if (w_wen)
      counter_q <= w_wdata;
    else if ((|perf_value) && !counting_inhibit)
      counter_q <= counter_add[63:0];
  end

  assign rdata = counter_q;
  assign regOut_ALL = counter_q;
  assign toMhpmeventOF = !counting_inhibit && counter_add[64];

  generate
    if (IDX >= 29) begin : g_invalid_counter_index
      initial $fatal(1, "mHPM counter index %0d is outside mhpmcounter3..31", IDX);
    end
  endgenerate
endmodule
