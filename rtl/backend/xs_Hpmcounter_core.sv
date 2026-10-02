// xs_Hpmcounter_core.sv — readable stopped-view core shared by the HPM CSR leaves.
// Each leaf is a read-only view of one machine performance counter supplied by NewCSR.
// While debug stop-count is asserted, the counter value is held in a resettable snapshot;
// otherwise the live performance-counter input is visible.  The update input is the
// one-cycle valid event used when entering the stopped-count view.
// COUNTER_INDEX identifies the selected HPM leaf; COUNTER_WIDTH keeps the core reusable.
module xs_Hpmcounter_core #(
  parameter int unsigned COUNTER_INDEX = 0,
  parameter int unsigned COUNTER_WIDTH = 64
) (
  input  logic                     clk,
  input  logic                     rst,
  input  logic [COUNTER_WIDTH-1:0] counter_value,
  input  logic                     debug_stop_count,
  input  logic                     count_update,
  output logic [COUNTER_WIDTH-1:0] rdata
);
  logic [COUNTER_WIDTH-1:0] stopped_value;

  // The snapshot is asynchronously cleared.  A valid update takes the live
  // counter value; otherwise it holds, matching the CSR's stopped-view latch.
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      stopped_value <= '0;
    else if (count_update)
      stopped_value <= counter_value;
  end

  assign rdata = debug_stop_count ? stopped_value : counter_value;

  // Keep an invalid leaf selection from being silently instantiated.
  generate
    if (COUNTER_INDEX >= 32) begin : g_invalid_counter_index
      initial $fatal(1, "HPM counter index %0d is outside mhpmcounter3..31", COUNTER_INDEX);
    end
  endgenerate
endmodule
