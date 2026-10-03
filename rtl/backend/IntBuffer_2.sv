// Two-channel one-cycle buffer for the second integer datapath lane.
// Capture and reset timing are independent of the channel naming order at the interface.
// Registered outputs retain the exact asynchronous-reset, one-clock latency behavior.
module IntBuffer_2 (
  input logic clock, input logic reset,
  input logic auto_in_1_0, input logic auto_in_0_0,
  output logic auto_out_1_0, output logic auto_out_0_0
);
  logic value_0, value_1_0;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      value_0 <= 1'b0;
      value_1_0 <= 1'b0;
    end else begin
      value_0 <= auto_in_0_0;
      value_1_0 <= auto_in_1_0;
    end
  end
  assign auto_out_1_0 = value_1_0;
  assign auto_out_0_0 = value_0;
endmodule
