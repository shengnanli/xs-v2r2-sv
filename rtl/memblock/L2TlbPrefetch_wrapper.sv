// 自动生成：scripts/gen_l2tlbprefetch.py —— 仅机械端口适配，核心逻辑在 xs_L2TlbPrefetch_core
module L2TlbPrefetch import xs_l2tlbprefetch_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  io_csr_satp_changed,
  input  [3:0] io_csr_vsatp_mode,
  input  io_csr_vsatp_changed,
  input  [3:0] io_csr_hgatp_mode,
  input  io_csr_hgatp_changed,
  input  io_csr_priv_virt,
  input  io_in_valid,
  input  [37:0] io_in_bits_vpn,
  input  io_out_ready,
  output io_out_valid,
  output [37:0] io_out_bits_req_info_vpn,
  output [1:0] io_out_bits_req_info_s2xlate
);

  l2tlb_req_info_t out_req_info_bus;

  xs_L2TlbPrefetch_core u_core (
    .clock(clock),
    .reset(reset),
    .sfence_valid(io_sfence_valid),
    .satp_changed(io_csr_satp_changed),
    .vsatp_mode(io_csr_vsatp_mode),
    .vsatp_changed(io_csr_vsatp_changed),
    .hgatp_mode(io_csr_hgatp_mode),
    .hgatp_changed(io_csr_hgatp_changed),
    .priv_virt(io_csr_priv_virt),
    .in_valid(io_in_valid),
    .in_vpn(io_in_bits_vpn),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_req_info(out_req_info_bus)
  );

  assign io_out_bits_req_info_vpn     = out_req_info_bus.vpn;
  assign io_out_bits_req_info_s2xlate = out_req_info_bus.s2xlate;

endmodule
