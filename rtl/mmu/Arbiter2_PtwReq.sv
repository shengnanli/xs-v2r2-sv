// PTW request arbitration at the L2 TLB input.
// Input 0 has fixed priority and alone receives ready when both inputs are valid.
// The chosen output uses the original Chisel convention: 0 for input 0, 1 otherwise.
module Arbiter2_PtwReq (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [37:0] io_in_0_bits_vpn,
  input  logic [1:0]  io_in_0_bits_s2xlate,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [37:0] io_in_1_bits_vpn,
  input  logic [1:0]  io_in_1_bits_s2xlate,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_vpn,
  output logic [1:0]  io_out_bits_s2xlate,
  output logic        io_chosen
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;
    io_chosen = !select_input_0;

    if (select_input_0) begin
      io_out_bits_vpn = io_in_0_bits_vpn;
      io_out_bits_s2xlate = io_in_0_bits_s2xlate;
    end else begin
      io_out_bits_vpn = io_in_1_bits_vpn;
      io_out_bits_s2xlate = io_in_1_bits_s2xlate;
    end
  end
endmodule
