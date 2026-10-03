// xs_HPerfCounter_core.sv — shared four-stage event reduction pipeline.
// Each wrapper supplies its explicit table, retaining reserved-slot behavior.
module xs_HPerfCounter_core #(
  parameter int unsigned EVENT_INDEX_BITS = 6,
  parameter int unsigned TABLE_SIZE = 64
) (
  input  logic                         clock,
  input  logic [63:0]                  hpm_event,
  input  logic [5:0]                   event_values [0:TABLE_SIZE-1],
  output logic [5:0]                   perf_value
);
  logic [5:0] increment_0_q, increment_1_q;
  logic [5:0] increment_2_q, increment_3_q;
  logic [4:0] operation_0_q, operation_1_q, operation_2_q;
  logic [4:0] operation_2_d_q;
  logic [5:0] step_0_q, step_1_q;
  logic [5:0] result_q, output_q;

  function automatic logic [5:0] reduce_pair(
    input logic [4:0] operation,
    input logic [5:0] left_value,
    input logic [5:0] right_value
  );
    if (operation[0])
      reduce_pair = left_value & right_value;
    else if (operation[1])
      reduce_pair = left_value ^ right_value;
    else if (operation[2])
      reduce_pair = left_value + right_value;
    else
      reduce_pair = left_value | right_value;
  endfunction

  always_ff @(posedge clock) begin
    increment_0_q <= event_values[hpm_event[EVENT_INDEX_BITS-1:0]];
    increment_1_q <= event_values[hpm_event[9+EVENT_INDEX_BITS:10]];
    increment_2_q <= event_values[hpm_event[19+EVENT_INDEX_BITS:20]];
    increment_3_q <= event_values[hpm_event[29+EVENT_INDEX_BITS:30]];
    operation_0_q <= hpm_event[44:40];
    operation_1_q <= hpm_event[49:45];
    operation_2_q <= hpm_event[54:50];
    operation_2_d_q <= operation_2_q;
    step_0_q <= reduce_pair(operation_0_q, increment_0_q, increment_1_q);
    step_1_q <= reduce_pair(operation_1_q, increment_2_q, increment_3_q);
    result_q <= reduce_pair(operation_2_d_q, step_0_q, step_1_q);
    output_q <= result_q;
  end

  assign perf_value = output_q;
endmodule
