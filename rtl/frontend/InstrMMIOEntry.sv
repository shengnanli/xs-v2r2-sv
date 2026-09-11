// InstrMMIOEntry —— Arbiter1_InsUncacheResp 单态化变体 wrapper（核体见 Arbiter1_InsUncacheResp.sv）

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
