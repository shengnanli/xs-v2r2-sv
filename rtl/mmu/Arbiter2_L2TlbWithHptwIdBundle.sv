// Merge the LLPTW and normal request streams before the L2 TLB miss queue.
// Input 0 has fixed priority and controls ready propagation while it is valid.
// Only input 0 carries isLLptw; selecting input 1 therefore clears that field.
module Arbiter2_L2TlbWithHptwIdBundle (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [37:0] io_in_0_bits_req_info_vpn,
  input  logic [1:0]  io_in_0_bits_req_info_s2xlate,
  input  logic [1:0]  io_in_0_bits_req_info_source,
  input  logic        io_in_0_bits_isLLptw,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [37:0] io_in_1_bits_req_info_vpn,
  input  logic [1:0]  io_in_1_bits_req_info_s2xlate,
  input  logic [1:0]  io_in_1_bits_req_info_source,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_req_info_vpn,
  output logic [1:0]  io_out_bits_req_info_s2xlate,
  output logic [1:0]  io_out_bits_req_info_source,
  output logic        io_out_bits_isLLptw
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_req_info_vpn = io_in_0_bits_req_info_vpn;
      io_out_bits_req_info_s2xlate = io_in_0_bits_req_info_s2xlate;
      io_out_bits_req_info_source = io_in_0_bits_req_info_source;
      io_out_bits_isLLptw = io_in_0_bits_isLLptw;
    end else begin
      io_out_bits_req_info_vpn = io_in_1_bits_req_info_vpn;
      io_out_bits_req_info_s2xlate = io_in_1_bits_req_info_s2xlate;
      io_out_bits_req_info_source = io_in_1_bits_req_info_source;
      io_out_bits_isLLptw = 1'b0;
    end
  end
endmodule
