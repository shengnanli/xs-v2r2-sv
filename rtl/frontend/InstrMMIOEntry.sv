// =============================================================================
// InstrUncache 变体包装层（golden 同名，FM/ST 用）
//   - InstrMMIOEntry          : 例化 xs_InstrMMIOEntry 核
//   - Arbiter1_InsUncacheResp : 单输入仲裁（透传）
//   - InstrUncache            : 顶层（nMMIOs=1，单 entry + 仲裁 + TileLink 路由）
// =============================================================================

// 单输入响应仲裁器：透传

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

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
