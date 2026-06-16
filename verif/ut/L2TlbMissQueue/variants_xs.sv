// 自动生成：scripts/gen_l2tlbmissqueue.py —— 仅机械端口适配，核心逻辑在 xs_L2TlbMissQueue_core
module L2TlbMissQueue_xs import xs_l2tlbmissqueue_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  io_csr_satp_changed,
  input  io_csr_vsatp_changed,
  input  io_csr_hgatp_changed,
  output io_in_ready,
  input  io_in_valid,
  input  [37:0] io_in_bits_req_info_vpn,
  input  [1:0] io_in_bits_req_info_s2xlate,
  input  [1:0] io_in_bits_req_info_source,
  input  io_in_bits_isLLptw,
  input  io_out_ready,
  output io_out_valid,
  output [37:0] io_out_bits_req_info_vpn,
  output [1:0] io_out_bits_req_info_s2xlate,
  output [1:0] io_out_bits_req_info_source,
  output io_out_bits_isHptwReq,
  output io_out_bits_isLLptw,
  output [2:0] io_out_bits_hptwId
);

  l2tlb_mq_bundle_t enq_bits_bus;
  l2tlb_mq_bundle_t deq_bits_bus;

  // 入队 payload：isHptwReq / hptwId 入队恒为 0（与 golden 一致）。
  assign enq_bits_bus.vpn         = io_in_bits_req_info_vpn;
  assign enq_bits_bus.s2xlate     = io_in_bits_req_info_s2xlate;
  assign enq_bits_bus.source      = io_in_bits_req_info_source;
  assign enq_bits_bus.is_hptw_req = 1'b0;
  assign enq_bits_bus.is_llptw    = io_in_bits_isLLptw;
  assign enq_bits_bus.hptw_id     = 3'h0;

  xs_L2TlbMissQueue_core u_core (
    .clock(clock),
    .reset(reset),
    .flush(io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed | io_csr_hgatp_changed),
    .enq_ready(io_in_ready),
    .enq_valid(io_in_valid),
    .enq_bits(enq_bits_bus),
    .deq_ready(io_out_ready),
    .deq_valid(io_out_valid),
    .deq_bits(deq_bits_bus)
  );

  assign io_out_bits_req_info_vpn     = deq_bits_bus.vpn;
  assign io_out_bits_req_info_s2xlate = deq_bits_bus.s2xlate;
  assign io_out_bits_req_info_source  = deq_bits_bus.source;
  assign io_out_bits_isHptwReq        = deq_bits_bus.is_hptw_req;
  assign io_out_bits_isLLptw          = deq_bits_bus.is_llptw;
  assign io_out_bits_hptwId           = deq_bits_bus.hptw_id;

endmodule
