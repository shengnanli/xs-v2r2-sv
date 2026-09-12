// InstrUncache —— InstrMMIOEntry 单态化变体 wrapper（核体见 InstrMMIOEntry.sv）

module InstrUncache(
  input         clock,
  input         reset,
  input         auto_client_out_a_ready,
  output        auto_client_out_a_valid,
  output [47:0] auto_client_out_a_bits_address,
  input         auto_client_out_d_valid,
  input         auto_client_out_d_bits_source,
  input  [63:0] auto_client_out_d_bits_data,
  input         auto_client_out_d_bits_corrupt,
  output        io_req_ready,
  input         io_req_valid,
  input  [47:0] io_req_bits_addr,
  output        io_resp_valid,
  output [31:0] io_resp_bits_data,
  output        io_resp_bits_corrupt,
  input         io_wfi_wfiReq,
  output        io_wfi_wfiSafe
);
  wire        ent_resp_valid, ent_resp_corrupt;
  wire [31:0] ent_resp_data;

  InstrMMIOEntry entries_0 (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid), .io_req_bits_addr(io_req_bits_addr),
    .io_resp_valid(ent_resp_valid), .io_resp_bits_data(ent_resp_data),
    .io_resp_bits_corrupt(ent_resp_corrupt),
    .io_mmio_acquire_ready(auto_client_out_a_ready),
    .io_mmio_acquire_valid(auto_client_out_a_valid),
    .io_mmio_acquire_bits_address(auto_client_out_a_bits_address),
    // 单 entry，source 恒 0：grant 仅当 d_source==0
    .io_mmio_grant_valid(~auto_client_out_d_bits_source & auto_client_out_d_valid),
    .io_mmio_grant_bits_data(auto_client_out_d_bits_data),
    .io_mmio_grant_bits_corrupt(auto_client_out_d_bits_corrupt),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(io_wfi_wfiSafe)
  );

  Arbiter1_InsUncacheResp resp_arb (
    .io_in_0_valid(ent_resp_valid),
    .io_in_0_bits_data(ent_resp_data),
    .io_in_0_bits_corrupt(ent_resp_corrupt),
    .io_out_valid(io_resp_valid),
    .io_out_bits_data(io_resp_bits_data),
    .io_out_bits_corrupt(io_resp_bits_corrupt)
  );
endmodule
