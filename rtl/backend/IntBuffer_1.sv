// Two-channel one-cycle buffer used by the integer datapath.
// Both channels share an asynchronous active-high reset and capture on each clock edge.
// Outputs expose the registered values directly, matching the G1 timing contract.
module IntBuffer_1 (
  input logic clock, input logic reset,
  input logic auto_in_0, input logic auto_in_1,
  output logic auto_out_0, output logic auto_out_1
);
  logic value_0, value_1;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      value_0 <= 1'b0;
      value_1 <= 1'b0;
    end else begin
      value_0 <= auto_in_0;
      value_1 <= auto_in_1;
    end
  end
  assign auto_out_0 = value_0;
  assign auto_out_1 = value_1;
endmodule
