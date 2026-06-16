// 自动生成：scripts/gen_llptw.py —— 仅机械端口适配，核心逻辑在 xs_LLPTW_core
module LLPTW import xs_llptw_pkg::*; (
  input  clock,
  input  reset,
  input  io_sfence_valid,
  input  io_csr_satp_changed,
  input  io_csr_vsatp_changed,
  input  [3:0] io_csr_hgatp_mode,
  input  io_csr_hgatp_changed,
  input  io_csr_priv_mxr,
  input  io_csr_mPBMTE,
  input  io_csr_hPBMTE,
  output io_in_ready,
  input  io_in_valid,
  input  [37:0] io_in_bits_req_info_vpn,
  input  [1:0] io_in_bits_req_info_s2xlate,
  input  [1:0] io_in_bits_req_info_source,
  input  [43:0] io_in_bits_ppn,
  input  io_out_ready,
  output io_out_valid,
  output [37:0] io_out_bits_req_info_vpn,
  output [1:0] io_out_bits_req_info_s2xlate,
  output [1:0] io_out_bits_req_info_source,
  output [2:0] io_out_bits_id,
  output [37:0] io_out_bits_h_resp_entry_tag,
  output [13:0] io_out_bits_h_resp_entry_vmid,
  output io_out_bits_h_resp_entry_n,
  output [1:0] io_out_bits_h_resp_entry_pbmt,
  output [37:0] io_out_bits_h_resp_entry_ppn,
  output io_out_bits_h_resp_entry_perm_d,
  output io_out_bits_h_resp_entry_perm_a,
  output io_out_bits_h_resp_entry_perm_g,
  output io_out_bits_h_resp_entry_perm_u,
  output io_out_bits_h_resp_entry_perm_x,
  output io_out_bits_h_resp_entry_perm_w,
  output io_out_bits_h_resp_entry_perm_r,
  output [1:0] io_out_bits_h_resp_entry_level,
  output io_out_bits_h_resp_gpf,
  output io_out_bits_h_resp_gaf,
  output io_out_bits_first_s2xlate_fault,
  output io_out_bits_af,
  input  io_mem_req_ready,
  output io_mem_req_valid,
  output [47:0] io_mem_req_bits_addr,
  output [2:0] io_mem_req_bits_id,
  input  io_mem_resp_valid,
  input  [2:0] io_mem_resp_bits_id,
  input  [511:0] io_mem_resp_bits_value,
  output [2:0] io_mem_enq_ptr,
  output io_mem_buffer_it_0,
  output io_mem_buffer_it_1,
  output io_mem_buffer_it_2,
  output io_mem_buffer_it_3,
  output io_mem_buffer_it_4,
  output io_mem_buffer_it_5,
  output [37:0] io_mem_refill_vpn,
  output [1:0] io_mem_refill_s2xlate,
  output [1:0] io_mem_refill_source,
  input  io_mem_req_mask_0,
  input  io_mem_req_mask_1,
  input  io_mem_req_mask_2,
  input  io_mem_req_mask_3,
  input  io_mem_req_mask_4,
  input  io_mem_req_mask_5,
  input  io_mem_flush_latch_0,
  input  io_mem_flush_latch_1,
  input  io_mem_flush_latch_2,
  input  io_mem_flush_latch_3,
  input  io_mem_flush_latch_4,
  input  io_mem_flush_latch_5,
  input  io_cache_ready,
  output io_cache_valid,
  output [37:0] io_cache_bits_vpn,
  output [1:0] io_cache_bits_s2xlate,
  output [1:0] io_cache_bits_source,
  output [47:0] io_pmp_req_bits_addr,
  input  io_pmp_resp_ld,
  input  io_pmp_resp_mmio,
  input  io_hptw_req_ready,
  output io_hptw_req_valid,
  output [1:0] io_hptw_req_bits_source,
  output [2:0] io_hptw_req_bits_id,
  output [43:0] io_hptw_req_bits_gvpn,
  input  io_hptw_resp_valid,
  input  [2:0] io_hptw_resp_bits_id,
  input  [37:0] io_hptw_resp_bits_h_resp_entry_tag,
  input  [13:0] io_hptw_resp_bits_h_resp_entry_vmid,
  input  io_hptw_resp_bits_h_resp_entry_n,
  input  [1:0] io_hptw_resp_bits_h_resp_entry_pbmt,
  input  [37:0] io_hptw_resp_bits_h_resp_entry_ppn,
  input  io_hptw_resp_bits_h_resp_entry_perm_d,
  input  io_hptw_resp_bits_h_resp_entry_perm_a,
  input  io_hptw_resp_bits_h_resp_entry_perm_g,
  input  io_hptw_resp_bits_h_resp_entry_perm_u,
  input  io_hptw_resp_bits_h_resp_entry_perm_x,
  input  io_hptw_resp_bits_h_resp_entry_perm_w,
  input  io_hptw_resp_bits_h_resp_entry_perm_r,
  input  [1:0] io_hptw_resp_bits_h_resp_entry_level,
  input  io_hptw_resp_bits_h_resp_gpf,
  input  io_hptw_resp_bits_h_resp_gaf,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value
);

  llptw_csr_t csr_bus;
  req_info_t  in_req_info;
  req_info_t  out_req_info;
  req_info_t  cache_req_info;
  req_info_t  mem_refill_bus;
  hptw_resp_t hptw_resp_h;
  hptw_resp_t out_h_resp;
  logic [5:0] mem_buffer_it_bus;
  logic [5:0] mem_req_mask_bus;
  logic [5:0] mem_flush_latch_bus;
  logic [3:0][5:0] perf_bus;

  assign csr_bus.sfence_valid = io_sfence_valid;
  assign csr_bus.satp_changed = io_csr_satp_changed;
  assign csr_bus.vsatp_changed = io_csr_vsatp_changed;
  assign csr_bus.hgatp_mode = io_csr_hgatp_mode;
  assign csr_bus.hgatp_changed = io_csr_hgatp_changed;
  assign csr_bus.priv_mxr = io_csr_priv_mxr;
  assign csr_bus.m_pbmt_enable = io_csr_mPBMTE;
  assign csr_bus.h_pbmt_enable = io_csr_hPBMTE;

  assign in_req_info.vpn = io_in_bits_req_info_vpn;
  assign in_req_info.s2xlate = io_in_bits_req_info_s2xlate;
  assign in_req_info.source = io_in_bits_req_info_source;

  assign hptw_resp_h.tag = io_hptw_resp_bits_h_resp_entry_tag;
  assign hptw_resp_h.vmid = io_hptw_resp_bits_h_resp_entry_vmid;
  assign hptw_resp_h.n = io_hptw_resp_bits_h_resp_entry_n;
  assign hptw_resp_h.pbmt = io_hptw_resp_bits_h_resp_entry_pbmt;
  assign hptw_resp_h.ppn = io_hptw_resp_bits_h_resp_entry_ppn;
  assign hptw_resp_h.perm.d = io_hptw_resp_bits_h_resp_entry_perm_d;
  assign hptw_resp_h.perm.a = io_hptw_resp_bits_h_resp_entry_perm_a;
  assign hptw_resp_h.perm.g = io_hptw_resp_bits_h_resp_entry_perm_g;
  assign hptw_resp_h.perm.u = io_hptw_resp_bits_h_resp_entry_perm_u;
  assign hptw_resp_h.perm.x = io_hptw_resp_bits_h_resp_entry_perm_x;
  assign hptw_resp_h.perm.w = io_hptw_resp_bits_h_resp_entry_perm_w;
  assign hptw_resp_h.perm.r = io_hptw_resp_bits_h_resp_entry_perm_r;
  assign hptw_resp_h.level = io_hptw_resp_bits_h_resp_entry_level;
  assign hptw_resp_h.gpf = io_hptw_resp_bits_h_resp_gpf;
  assign hptw_resp_h.gaf = io_hptw_resp_bits_h_resp_gaf;
  assign mem_req_mask_bus = {io_mem_req_mask_5, io_mem_req_mask_4, io_mem_req_mask_3, io_mem_req_mask_2, io_mem_req_mask_1, io_mem_req_mask_0};
  assign mem_flush_latch_bus = {io_mem_flush_latch_5, io_mem_flush_latch_4, io_mem_flush_latch_3, io_mem_flush_latch_2, io_mem_flush_latch_1, io_mem_flush_latch_0};

  xs_LLPTW_core u_core (
    .clock(clock),
    .reset(reset),
    .csr(csr_bus),
    .in_ready(io_in_ready),
    .in_valid(io_in_valid),
    .in_req_info(in_req_info),
    .in_ppn(io_in_bits_ppn),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_req_info(out_req_info),
    .out_id(io_out_bits_id),
    .out_h_resp(out_h_resp),
    .out_first_s2xlate_fault(io_out_bits_first_s2xlate_fault),
    .out_af(io_out_bits_af),
    .mem_req_ready(io_mem_req_ready),
    .mem_req_valid(io_mem_req_valid),
    .mem_req_addr(io_mem_req_bits_addr),
    .mem_req_id(io_mem_req_bits_id),
    .mem_resp_valid(io_mem_resp_valid),
    .mem_resp_id(io_mem_resp_bits_id),
    .mem_resp_value(io_mem_resp_bits_value),
    .mem_enq_ptr(io_mem_enq_ptr),
    .mem_buffer_it(mem_buffer_it_bus),
    .mem_refill(mem_refill_bus),
    .mem_req_mask(mem_req_mask_bus),
    .mem_flush_latch(mem_flush_latch_bus),
    .cache_ready(io_cache_ready),
    .cache_valid(io_cache_valid),
    .cache_req_info(cache_req_info),
    .pmp_req_addr(io_pmp_req_bits_addr),
    .pmp_resp_ld(io_pmp_resp_ld),
    .pmp_resp_mmio(io_pmp_resp_mmio),
    .hptw_req_ready(io_hptw_req_ready),
    .hptw_req_valid(io_hptw_req_valid),
    .hptw_req_source(io_hptw_req_bits_source),
    .hptw_req_id(io_hptw_req_bits_id),
    .hptw_req_gvpn(io_hptw_req_bits_gvpn),
    .hptw_resp_valid(io_hptw_resp_valid),
    .hptw_resp_id(io_hptw_resp_bits_id),
    .hptw_resp_h(hptw_resp_h),
    .perf(perf_bus)
  );

  assign io_out_bits_req_info_vpn = out_req_info.vpn;
  assign io_out_bits_req_info_s2xlate = out_req_info.s2xlate;
  assign io_out_bits_req_info_source = out_req_info.source;
  assign io_cache_bits_vpn = cache_req_info.vpn;
  assign io_cache_bits_s2xlate = cache_req_info.s2xlate;
  assign io_cache_bits_source = cache_req_info.source;
  assign io_mem_refill_vpn = mem_refill_bus.vpn;
  assign io_mem_refill_s2xlate = mem_refill_bus.s2xlate;
  assign io_mem_refill_source = mem_refill_bus.source;
  assign io_mem_buffer_it_0 = mem_buffer_it_bus[0];
  assign io_mem_buffer_it_1 = mem_buffer_it_bus[1];
  assign io_mem_buffer_it_2 = mem_buffer_it_bus[2];
  assign io_mem_buffer_it_3 = mem_buffer_it_bus[3];
  assign io_mem_buffer_it_4 = mem_buffer_it_bus[4];
  assign io_mem_buffer_it_5 = mem_buffer_it_bus[5];
  assign io_out_bits_h_resp_entry_tag = out_h_resp.tag;
  assign io_out_bits_h_resp_entry_vmid = out_h_resp.vmid;
  assign io_out_bits_h_resp_entry_n = out_h_resp.n;
  assign io_out_bits_h_resp_entry_pbmt = out_h_resp.pbmt;
  assign io_out_bits_h_resp_entry_ppn = out_h_resp.ppn;
  assign io_out_bits_h_resp_entry_perm_d = out_h_resp.perm.d;
  assign io_out_bits_h_resp_entry_perm_a = out_h_resp.perm.a;
  assign io_out_bits_h_resp_entry_perm_g = out_h_resp.perm.g;
  assign io_out_bits_h_resp_entry_perm_u = out_h_resp.perm.u;
  assign io_out_bits_h_resp_entry_perm_x = out_h_resp.perm.x;
  assign io_out_bits_h_resp_entry_perm_w = out_h_resp.perm.w;
  assign io_out_bits_h_resp_entry_perm_r = out_h_resp.perm.r;
  assign io_out_bits_h_resp_entry_level = out_h_resp.level;
  assign io_out_bits_h_resp_gpf = out_h_resp.gpf;
  assign io_out_bits_h_resp_gaf = out_h_resp.gaf;
  assign io_perf_0_value = perf_bus[0];
  assign io_perf_1_value = perf_bus[1];
  assign io_perf_2_value = perf_bus[2];
  assign io_perf_3_value = perf_bus[3];

endmodule
