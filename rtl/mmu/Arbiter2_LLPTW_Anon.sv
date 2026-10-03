// HPTW request arbitration inside the last-level page-table walker.
// Input 0 has fixed priority; input 1 receives ready only when input 0 is invalid.
// The selected source, ID, and PPN remain combinational through the arbiter.
module Arbiter2_LLPTW_Anon (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [1:0]  io_in_0_bits_source,
  input  logic [2:0]  io_in_0_bits_id,
  input  logic [43:0] io_in_0_bits_ppn,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [1:0]  io_in_1_bits_source,
  input  logic [2:0]  io_in_1_bits_id,
  input  logic [43:0] io_in_1_bits_ppn,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [1:0]  io_out_bits_source,
  output logic [2:0]  io_out_bits_id,
  output logic [43:0] io_out_bits_ppn
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_source = io_in_0_bits_source;
      io_out_bits_id = io_in_0_bits_id;
      io_out_bits_ppn = io_in_0_bits_ppn;
    end else begin
      io_out_bits_source = io_in_1_bits_source;
      io_out_bits_id = io_in_1_bits_id;
      io_out_bits_ppn = io_in_1_bits_ppn;
    end
  end
endmodule
