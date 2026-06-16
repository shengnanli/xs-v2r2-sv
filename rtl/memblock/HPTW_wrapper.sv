// 自动生成：scripts/gen_hptw.py —— 仅机械端口适配，核心逻辑在 xs_HPTW_core
module HPTW import xs_hptw_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  io_csr_satp_changed,
  input  io_csr_vsatp_changed,
  input  [3:0] io_csr_hgatp_mode,
  input  [15:0] io_csr_hgatp_vmid,
  input  [43:0] io_csr_hgatp_ppn,
  input  io_csr_hgatp_changed,
  input  io_csr_mPBMTE,
  output io_req_ready,
  input  io_req_valid,
  input  [1:0] io_req_bits_source,
  input  [2:0] io_req_bits_id,
  input  [37:0] io_req_bits_gvpn,
  input  [35:0] io_req_bits_ppn,
  input  io_req_bits_l3Hit,
  input  io_req_bits_l2Hit,
  input  io_req_bits_l1Hit,
  input  io_req_bits_bypassed,
  input  io_resp_ready,
  output io_resp_valid,
  output [37:0] io_resp_bits_resp_entry_tag,
  output [13:0] io_resp_bits_resp_entry_vmid,
  output io_resp_bits_resp_entry_n,
  output [1:0] io_resp_bits_resp_entry_pbmt,
  output [37:0] io_resp_bits_resp_entry_ppn,
  output io_resp_bits_resp_entry_perm_d,
  output io_resp_bits_resp_entry_perm_a,
  output io_resp_bits_resp_entry_perm_g,
  output io_resp_bits_resp_entry_perm_u,
  output io_resp_bits_resp_entry_perm_x,
  output io_resp_bits_resp_entry_perm_w,
  output io_resp_bits_resp_entry_perm_r,
  output [1:0] io_resp_bits_resp_entry_level,
  output io_resp_bits_resp_gpf,
  output io_resp_bits_resp_gaf,
  output [2:0] io_resp_bits_id,
  input  io_mem_req_ready,
  output io_mem_req_valid,
  output [47:0] io_mem_req_bits_addr,
  output io_mem_req_bits_hptw_bypassed,
  input  io_mem_resp_valid,
  input  [63:0] io_mem_resp_bits,
  input  io_mem_mask,
  output [37:0] io_refill_req_info_vpn,
  output [1:0] io_refill_req_info_source,
  output [1:0] io_refill_level,
  output [47:0] io_pmp_req_bits_addr,
  input  io_pmp_resp_ld,
  input  io_pmp_resp_mmio
);

  hptw_csr_t  csr_bus;
  hptw_req_t  req_bus;
  hptw_resp_t resp_bus;
  logic [1:0] resp_source_unused;

  assign csr_bus.hgatp_mode     = io_csr_hgatp_mode;
  assign csr_bus.hgatp_vmid_raw = io_csr_hgatp_vmid;
  assign csr_bus.hgatp_ppn      = io_csr_hgatp_ppn;
  assign csr_bus.hgatp_changed  = io_csr_hgatp_changed;
  assign csr_bus.satp_changed   = io_csr_satp_changed;
  assign csr_bus.vsatp_changed  = io_csr_vsatp_changed;
  assign csr_bus.m_pbmt_enable  = io_csr_mPBMTE;

  assign req_bus.source   = io_req_bits_source;
  assign req_bus.id       = io_req_bits_id;
  assign req_bus.gvpn     = io_req_bits_gvpn;
  assign req_bus.ppn      = io_req_bits_ppn;
  assign req_bus.l3_hit   = io_req_bits_l3Hit;
  assign req_bus.l2_hit   = io_req_bits_l2Hit;
  assign req_bus.l1_hit   = io_req_bits_l1Hit;
  assign req_bus.bypassed = io_req_bits_bypassed;

  xs_HPTW_core u_core (
    .clock(clock),
    .reset(reset),
    .sfence_valid(io_sfence_valid),
    .csr(csr_bus),
    .req_ready(io_req_ready),
    .req_valid(io_req_valid),
    .req(req_bus),
    .resp_ready(io_resp_ready),
    .resp_valid(io_resp_valid),
    .resp_source(resp_source_unused),
    .resp(resp_bus),
    .resp_id(io_resp_bits_id),
    .mem_req_ready(io_mem_req_ready),
    .mem_req_valid(io_mem_req_valid),
    .mem_req_addr(io_mem_req_bits_addr),
    .mem_req_hptw_bypassed(io_mem_req_bits_hptw_bypassed),
    .mem_resp_valid(io_mem_resp_valid),
    .mem_resp_bits(io_mem_resp_bits),
    .mem_mask(io_mem_mask),
    .refill_vpn(io_refill_req_info_vpn),
    .refill_source(io_refill_req_info_source),
    .refill_level(io_refill_level),
    .pmp_addr(io_pmp_req_bits_addr),
    .pmp_resp_ld(io_pmp_resp_ld),
    .pmp_resp_mmio(io_pmp_resp_mmio)
  );

  assign io_resp_bits_resp_entry_tag = resp_bus.tag;
  assign io_resp_bits_resp_entry_vmid = resp_bus.vmid;
  assign io_resp_bits_resp_entry_n = resp_bus.n;
  assign io_resp_bits_resp_entry_pbmt = resp_bus.pbmt;
  assign io_resp_bits_resp_entry_ppn = resp_bus.ppn;
  assign io_resp_bits_resp_entry_perm_d = resp_bus.perm.d;
  assign io_resp_bits_resp_entry_perm_a = resp_bus.perm.a;
  assign io_resp_bits_resp_entry_perm_g = resp_bus.perm.g;
  assign io_resp_bits_resp_entry_perm_u = resp_bus.perm.u;
  assign io_resp_bits_resp_entry_perm_x = resp_bus.perm.x;
  assign io_resp_bits_resp_entry_perm_w = resp_bus.perm.w;
  assign io_resp_bits_resp_entry_perm_r = resp_bus.perm.r;
  assign io_resp_bits_resp_entry_level = resp_bus.level;
  assign io_resp_bits_resp_gpf = resp_bus.gpf;
  assign io_resp_bits_resp_gaf = resp_bus.gaf;

endmodule
