// One-entry ready/valid pipeline register for load responses.
// Pipeline/control leaf: input is accepted when the register is empty or the
// current output is consumed; payload remains stable while stalled.
module PipelineRegModule_6(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [63:0] io_in_bits_data,
  input  [3:0]  io_in_bits_id,
  input         io_in_bits_nc,
  input         io_in_bits_is2lq,
  input         io_in_bits_denied,
  input         io_in_bits_corrupt,
  input         io_out_ready,
  output        io_out_valid,
  output [63:0] io_out_bits_data,
  output [3:0]  io_out_bits_id,
  output        io_out_bits_nc,
  output        io_out_bits_is2lq,
  output        io_out_bits_denied,
  output        io_out_bits_corrupt
);
  logic valid;
  logic [63:0] data_q;
  logic [3:0] id_q;
  logic nc_q, is2lq_q, denied_q, corrupt_q;
  wire accept = io_in_valid & io_in_ready;
  assign io_in_ready = ~valid | io_out_ready;
  assign io_out_valid = valid;
  assign io_out_bits_data = data_q;
  assign io_out_bits_id = id_q;
  assign io_out_bits_nc = nc_q;
  assign io_out_bits_is2lq = is2lq_q;
  assign io_out_bits_denied = denied_q;
  assign io_out_bits_corrupt = corrupt_q;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      valid <= 1'b0;
    end else begin
      valid <= accept | (valid & ~io_out_ready);
      if (accept) begin
        data_q <= io_in_bits_data;
        id_q <= io_in_bits_id;
        nc_q <= io_in_bits_nc;
        is2lq_q <= io_in_bits_is2lq;
        denied_q <= io_in_bits_denied;
        corrupt_q <= io_in_bits_corrupt;
      end
    end
  end
endmodule
