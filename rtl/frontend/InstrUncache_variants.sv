// =============================================================================
// InstrUncache 变体包装层（golden 同名，FM/ST 用）
//   - InstrMMIOEntry          : 例化 xs_InstrMMIOEntry 核
//   - Arbiter1_InsUncacheResp : 单输入仲裁（透传）
//   - InstrUncache            : 顶层（nMMIOs=1，单 entry + 仲裁 + TileLink 路由）
// =============================================================================

// 单输入响应仲裁器：透传
module Arbiter1_InsUncacheResp(
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits_data,
  input         io_in_0_bits_corrupt,
  output        io_out_valid,
  output [31:0] io_out_bits_data,
  output        io_out_bits_corrupt
);
  assign io_out_valid        = io_in_0_valid;
  assign io_out_bits_data    = io_in_0_bits_data;
  assign io_out_bits_corrupt = io_in_0_bits_corrupt;
endmodule

// golden 同名 entry wrapper（端口与 golden 一致），内部用 xs 核
module InstrMMIOEntry(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [47:0] io_req_bits_addr,
  output        io_resp_valid,
  output [31:0] io_resp_bits_data,
  output        io_resp_bits_corrupt,
  input         io_mmio_acquire_ready,
  output        io_mmio_acquire_valid,
  output [47:0] io_mmio_acquire_bits_address,
  input         io_mmio_grant_valid,
  input  [63:0] io_mmio_grant_bits_data,
  input         io_mmio_grant_bits_corrupt,
  input         io_wfi_wfiReq,
  output        io_wfi_wfiSafe
);
  xs_InstrMMIOEntry u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid), .io_req_bits_addr(io_req_bits_addr),
    .io_resp_valid(io_resp_valid), .io_resp_bits_data(io_resp_bits_data),
    .io_resp_bits_corrupt(io_resp_bits_corrupt),
    .io_mmio_acquire_ready(io_mmio_acquire_ready), .io_mmio_acquire_valid(io_mmio_acquire_valid),
    .io_mmio_acquire_bits_address(io_mmio_acquire_bits_address),
    .io_mmio_grant_valid(io_mmio_grant_valid), .io_mmio_grant_bits_data(io_mmio_grant_bits_data),
    .io_mmio_grant_bits_corrupt(io_mmio_grant_bits_corrupt),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(io_wfi_wfiSafe)
  );
endmodule

// 顶层：单 entry + 响应仲裁 + TileLink A/D 路由（结构层）
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
