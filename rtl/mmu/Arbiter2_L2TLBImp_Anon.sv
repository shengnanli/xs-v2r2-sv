// HPTW request arbitration at the L2 TLB boundary.
// Input 0 has fixed priority; ready follows that priority and downstream readiness.
// Input 0 has no ID field, so the architectural HPTW ID (6) is inserted.
module Arbiter2_L2TLBImp_Anon (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [1:0]  io_in_0_bits_source,
  input  logic [37:0] io_in_0_bits_gvpn,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [2:0]  io_in_1_bits_id,
  input  logic [1:0]  io_in_1_bits_source,
  input  logic [37:0] io_in_1_bits_gvpn,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [2:0]  io_out_bits_id,
  output logic [1:0]  io_out_bits_source,
  output logic [37:0] io_out_bits_gvpn
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_id = 3'd6;
      io_out_bits_source = io_in_0_bits_source;
      io_out_bits_gvpn = io_in_0_bits_gvpn;
    end else begin
      io_out_bits_id = io_in_1_bits_id;
      io_out_bits_source = io_in_1_bits_source;
      io_out_bits_gvpn = io_in_1_bits_gvpn;
    end
  end
endmodule
