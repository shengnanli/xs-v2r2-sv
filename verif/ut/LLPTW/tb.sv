`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_mxr;
  logic io_csr_mPBMTE;
  logic io_csr_hPBMTE;
  logic io_in_valid;
  logic [37:0] io_in_bits_req_info_vpn;
  logic [1:0] io_in_bits_req_info_s2xlate;
  logic [1:0] io_in_bits_req_info_source;
  logic [43:0] io_in_bits_ppn;
  logic io_out_ready;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [2:0] io_mem_resp_bits_id;
  logic [511:0] io_mem_resp_bits_value;
  logic io_mem_req_mask_0;
  logic io_mem_req_mask_1;
  logic io_mem_req_mask_2;
  logic io_mem_req_mask_3;
  logic io_mem_req_mask_4;
  logic io_mem_req_mask_5;
  logic io_mem_flush_latch_0;
  logic io_mem_flush_latch_1;
  logic io_mem_flush_latch_2;
  logic io_mem_flush_latch_3;
  logic io_mem_flush_latch_4;
  logic io_mem_flush_latch_5;
  logic io_cache_ready;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  logic io_hptw_req_ready;
  logic io_hptw_resp_valid;
  logic [2:0] io_hptw_resp_bits_id;
  logic [37:0] io_hptw_resp_bits_h_resp_entry_tag;
  logic [13:0] io_hptw_resp_bits_h_resp_entry_vmid;
  logic io_hptw_resp_bits_h_resp_entry_n;
  logic [1:0] io_hptw_resp_bits_h_resp_entry_pbmt;
  logic [37:0] io_hptw_resp_bits_h_resp_entry_ppn;
  logic io_hptw_resp_bits_h_resp_entry_perm_d;
  logic io_hptw_resp_bits_h_resp_entry_perm_a;
  logic io_hptw_resp_bits_h_resp_entry_perm_g;
  logic io_hptw_resp_bits_h_resp_entry_perm_u;
  logic io_hptw_resp_bits_h_resp_entry_perm_x;
  logic io_hptw_resp_bits_h_resp_entry_perm_w;
  logic io_hptw_resp_bits_h_resp_entry_perm_r;
  logic [1:0] io_hptw_resp_bits_h_resp_entry_level;
  logic io_hptw_resp_bits_h_resp_gpf;
  logic io_hptw_resp_bits_h_resp_gaf;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [37:0] g_io_out_bits_req_info_vpn;
  wire [37:0] i_io_out_bits_req_info_vpn;
  wire [1:0] g_io_out_bits_req_info_s2xlate;
  wire [1:0] i_io_out_bits_req_info_s2xlate;
  wire [1:0] g_io_out_bits_req_info_source;
  wire [1:0] i_io_out_bits_req_info_source;
  wire [2:0] g_io_out_bits_id;
  wire [2:0] i_io_out_bits_id;
  wire [37:0] g_io_out_bits_h_resp_entry_tag;
  wire [37:0] i_io_out_bits_h_resp_entry_tag;
  wire [13:0] g_io_out_bits_h_resp_entry_vmid;
  wire [13:0] i_io_out_bits_h_resp_entry_vmid;
  wire g_io_out_bits_h_resp_entry_n;
  wire i_io_out_bits_h_resp_entry_n;
  wire [1:0] g_io_out_bits_h_resp_entry_pbmt;
  wire [1:0] i_io_out_bits_h_resp_entry_pbmt;
  wire [37:0] g_io_out_bits_h_resp_entry_ppn;
  wire [37:0] i_io_out_bits_h_resp_entry_ppn;
  wire g_io_out_bits_h_resp_entry_perm_d;
  wire i_io_out_bits_h_resp_entry_perm_d;
  wire g_io_out_bits_h_resp_entry_perm_a;
  wire i_io_out_bits_h_resp_entry_perm_a;
  wire g_io_out_bits_h_resp_entry_perm_g;
  wire i_io_out_bits_h_resp_entry_perm_g;
  wire g_io_out_bits_h_resp_entry_perm_u;
  wire i_io_out_bits_h_resp_entry_perm_u;
  wire g_io_out_bits_h_resp_entry_perm_x;
  wire i_io_out_bits_h_resp_entry_perm_x;
  wire g_io_out_bits_h_resp_entry_perm_w;
  wire i_io_out_bits_h_resp_entry_perm_w;
  wire g_io_out_bits_h_resp_entry_perm_r;
  wire i_io_out_bits_h_resp_entry_perm_r;
  wire [1:0] g_io_out_bits_h_resp_entry_level;
  wire [1:0] i_io_out_bits_h_resp_entry_level;
  wire g_io_out_bits_h_resp_gpf;
  wire i_io_out_bits_h_resp_gpf;
  wire g_io_out_bits_h_resp_gaf;
  wire i_io_out_bits_h_resp_gaf;
  wire g_io_out_bits_first_s2xlate_fault;
  wire i_io_out_bits_first_s2xlate_fault;
  wire g_io_out_bits_af;
  wire i_io_out_bits_af;
  wire g_io_mem_req_valid;
  wire i_io_mem_req_valid;
  wire [47:0] g_io_mem_req_bits_addr;
  wire [47:0] i_io_mem_req_bits_addr;
  wire [2:0] g_io_mem_req_bits_id;
  wire [2:0] i_io_mem_req_bits_id;
  wire [2:0] g_io_mem_enq_ptr;
  wire [2:0] i_io_mem_enq_ptr;
  wire g_io_mem_buffer_it_0;
  wire i_io_mem_buffer_it_0;
  wire g_io_mem_buffer_it_1;
  wire i_io_mem_buffer_it_1;
  wire g_io_mem_buffer_it_2;
  wire i_io_mem_buffer_it_2;
  wire g_io_mem_buffer_it_3;
  wire i_io_mem_buffer_it_3;
  wire g_io_mem_buffer_it_4;
  wire i_io_mem_buffer_it_4;
  wire g_io_mem_buffer_it_5;
  wire i_io_mem_buffer_it_5;
  wire [37:0] g_io_mem_refill_vpn;
  wire [37:0] i_io_mem_refill_vpn;
  wire [1:0] g_io_mem_refill_s2xlate;
  wire [1:0] i_io_mem_refill_s2xlate;
  wire [1:0] g_io_mem_refill_source;
  wire [1:0] i_io_mem_refill_source;
  wire g_io_cache_valid;
  wire i_io_cache_valid;
  wire [37:0] g_io_cache_bits_vpn;
  wire [37:0] i_io_cache_bits_vpn;
  wire [1:0] g_io_cache_bits_s2xlate;
  wire [1:0] i_io_cache_bits_s2xlate;
  wire [1:0] g_io_cache_bits_source;
  wire [1:0] i_io_cache_bits_source;
  wire [47:0] g_io_pmp_req_bits_addr;
  wire [47:0] i_io_pmp_req_bits_addr;
  wire g_io_hptw_req_valid;
  wire i_io_hptw_req_valid;
  wire [1:0] g_io_hptw_req_bits_source;
  wire [1:0] i_io_hptw_req_bits_source;
  wire [2:0] g_io_hptw_req_bits_id;
  wire [2:0] i_io_hptw_req_bits_id;
  wire [43:0] g_io_hptw_req_bits_gvpn;
  wire [43:0] i_io_hptw_req_bits_gvpn;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  integer cycle;
  integer errors;
  integer checks;
  integer probe_errors;

  LLPTW u_g (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_mxr(io_csr_priv_mxr),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_csr_hPBMTE(io_csr_hPBMTE),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_req_info_vpn(io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(io_in_bits_req_info_source),
    .io_in_bits_ppn(io_in_bits_ppn),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_req_info_vpn(g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(g_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(g_io_out_bits_req_info_source),
    .io_out_bits_id(g_io_out_bits_id),
    .io_out_bits_h_resp_entry_tag(g_io_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid(g_io_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n(g_io_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt(g_io_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn(g_io_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d(g_io_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a(g_io_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g(g_io_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u(g_io_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x(g_io_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w(g_io_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r(g_io_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level(g_io_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf(g_io_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf(g_io_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault(g_io_out_bits_first_s2xlate_fault),
    .io_out_bits_af(g_io_out_bits_af),
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(g_io_mem_req_valid),
    .io_mem_req_bits_addr(g_io_mem_req_bits_addr),
    .io_mem_req_bits_id(g_io_mem_req_bits_id),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits_id(io_mem_resp_bits_id),
    .io_mem_resp_bits_value(io_mem_resp_bits_value),
    .io_mem_enq_ptr(g_io_mem_enq_ptr),
    .io_mem_buffer_it_0(g_io_mem_buffer_it_0),
    .io_mem_buffer_it_1(g_io_mem_buffer_it_1),
    .io_mem_buffer_it_2(g_io_mem_buffer_it_2),
    .io_mem_buffer_it_3(g_io_mem_buffer_it_3),
    .io_mem_buffer_it_4(g_io_mem_buffer_it_4),
    .io_mem_buffer_it_5(g_io_mem_buffer_it_5),
    .io_mem_refill_vpn(g_io_mem_refill_vpn),
    .io_mem_refill_s2xlate(g_io_mem_refill_s2xlate),
    .io_mem_refill_source(g_io_mem_refill_source),
    .io_mem_req_mask_0(io_mem_req_mask_0),
    .io_mem_req_mask_1(io_mem_req_mask_1),
    .io_mem_req_mask_2(io_mem_req_mask_2),
    .io_mem_req_mask_3(io_mem_req_mask_3),
    .io_mem_req_mask_4(io_mem_req_mask_4),
    .io_mem_req_mask_5(io_mem_req_mask_5),
    .io_mem_flush_latch_0(io_mem_flush_latch_0),
    .io_mem_flush_latch_1(io_mem_flush_latch_1),
    .io_mem_flush_latch_2(io_mem_flush_latch_2),
    .io_mem_flush_latch_3(io_mem_flush_latch_3),
    .io_mem_flush_latch_4(io_mem_flush_latch_4),
    .io_mem_flush_latch_5(io_mem_flush_latch_5),
    .io_cache_ready(io_cache_ready),
    .io_cache_valid(g_io_cache_valid),
    .io_cache_bits_vpn(g_io_cache_bits_vpn),
    .io_cache_bits_s2xlate(g_io_cache_bits_s2xlate),
    .io_cache_bits_source(g_io_cache_bits_source),
    .io_pmp_req_bits_addr(g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_hptw_req_ready(io_hptw_req_ready),
    .io_hptw_req_valid(g_io_hptw_req_valid),
    .io_hptw_req_bits_source(g_io_hptw_req_bits_source),
    .io_hptw_req_bits_id(g_io_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn(g_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid(io_hptw_resp_valid),
    .io_hptw_resp_bits_id(io_hptw_resp_bits_id),
    .io_hptw_resp_bits_h_resp_entry_tag(io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid(io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n(io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt(io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn(io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d(io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a(io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g(io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u(io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x(io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w(io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r(io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level(io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf(io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf(io_hptw_resp_bits_h_resp_gaf),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value)
  );
  LLPTW_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_mxr(io_csr_priv_mxr),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_csr_hPBMTE(io_csr_hPBMTE),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_req_info_vpn(io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(io_in_bits_req_info_source),
    .io_in_bits_ppn(io_in_bits_ppn),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_req_info_vpn(i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(i_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(i_io_out_bits_req_info_source),
    .io_out_bits_id(i_io_out_bits_id),
    .io_out_bits_h_resp_entry_tag(i_io_out_bits_h_resp_entry_tag),
    .io_out_bits_h_resp_entry_vmid(i_io_out_bits_h_resp_entry_vmid),
    .io_out_bits_h_resp_entry_n(i_io_out_bits_h_resp_entry_n),
    .io_out_bits_h_resp_entry_pbmt(i_io_out_bits_h_resp_entry_pbmt),
    .io_out_bits_h_resp_entry_ppn(i_io_out_bits_h_resp_entry_ppn),
    .io_out_bits_h_resp_entry_perm_d(i_io_out_bits_h_resp_entry_perm_d),
    .io_out_bits_h_resp_entry_perm_a(i_io_out_bits_h_resp_entry_perm_a),
    .io_out_bits_h_resp_entry_perm_g(i_io_out_bits_h_resp_entry_perm_g),
    .io_out_bits_h_resp_entry_perm_u(i_io_out_bits_h_resp_entry_perm_u),
    .io_out_bits_h_resp_entry_perm_x(i_io_out_bits_h_resp_entry_perm_x),
    .io_out_bits_h_resp_entry_perm_w(i_io_out_bits_h_resp_entry_perm_w),
    .io_out_bits_h_resp_entry_perm_r(i_io_out_bits_h_resp_entry_perm_r),
    .io_out_bits_h_resp_entry_level(i_io_out_bits_h_resp_entry_level),
    .io_out_bits_h_resp_gpf(i_io_out_bits_h_resp_gpf),
    .io_out_bits_h_resp_gaf(i_io_out_bits_h_resp_gaf),
    .io_out_bits_first_s2xlate_fault(i_io_out_bits_first_s2xlate_fault),
    .io_out_bits_af(i_io_out_bits_af),
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(i_io_mem_req_valid),
    .io_mem_req_bits_addr(i_io_mem_req_bits_addr),
    .io_mem_req_bits_id(i_io_mem_req_bits_id),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits_id(io_mem_resp_bits_id),
    .io_mem_resp_bits_value(io_mem_resp_bits_value),
    .io_mem_enq_ptr(i_io_mem_enq_ptr),
    .io_mem_buffer_it_0(i_io_mem_buffer_it_0),
    .io_mem_buffer_it_1(i_io_mem_buffer_it_1),
    .io_mem_buffer_it_2(i_io_mem_buffer_it_2),
    .io_mem_buffer_it_3(i_io_mem_buffer_it_3),
    .io_mem_buffer_it_4(i_io_mem_buffer_it_4),
    .io_mem_buffer_it_5(i_io_mem_buffer_it_5),
    .io_mem_refill_vpn(i_io_mem_refill_vpn),
    .io_mem_refill_s2xlate(i_io_mem_refill_s2xlate),
    .io_mem_refill_source(i_io_mem_refill_source),
    .io_mem_req_mask_0(io_mem_req_mask_0),
    .io_mem_req_mask_1(io_mem_req_mask_1),
    .io_mem_req_mask_2(io_mem_req_mask_2),
    .io_mem_req_mask_3(io_mem_req_mask_3),
    .io_mem_req_mask_4(io_mem_req_mask_4),
    .io_mem_req_mask_5(io_mem_req_mask_5),
    .io_mem_flush_latch_0(io_mem_flush_latch_0),
    .io_mem_flush_latch_1(io_mem_flush_latch_1),
    .io_mem_flush_latch_2(io_mem_flush_latch_2),
    .io_mem_flush_latch_3(io_mem_flush_latch_3),
    .io_mem_flush_latch_4(io_mem_flush_latch_4),
    .io_mem_flush_latch_5(io_mem_flush_latch_5),
    .io_cache_ready(io_cache_ready),
    .io_cache_valid(i_io_cache_valid),
    .io_cache_bits_vpn(i_io_cache_bits_vpn),
    .io_cache_bits_s2xlate(i_io_cache_bits_s2xlate),
    .io_cache_bits_source(i_io_cache_bits_source),
    .io_pmp_req_bits_addr(i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_hptw_req_ready(io_hptw_req_ready),
    .io_hptw_req_valid(i_io_hptw_req_valid),
    .io_hptw_req_bits_source(i_io_hptw_req_bits_source),
    .io_hptw_req_bits_id(i_io_hptw_req_bits_id),
    .io_hptw_req_bits_gvpn(i_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid(io_hptw_resp_valid),
    .io_hptw_resp_bits_id(io_hptw_resp_bits_id),
    .io_hptw_resp_bits_h_resp_entry_tag(io_hptw_resp_bits_h_resp_entry_tag),
    .io_hptw_resp_bits_h_resp_entry_vmid(io_hptw_resp_bits_h_resp_entry_vmid),
    .io_hptw_resp_bits_h_resp_entry_n(io_hptw_resp_bits_h_resp_entry_n),
    .io_hptw_resp_bits_h_resp_entry_pbmt(io_hptw_resp_bits_h_resp_entry_pbmt),
    .io_hptw_resp_bits_h_resp_entry_ppn(io_hptw_resp_bits_h_resp_entry_ppn),
    .io_hptw_resp_bits_h_resp_entry_perm_d(io_hptw_resp_bits_h_resp_entry_perm_d),
    .io_hptw_resp_bits_h_resp_entry_perm_a(io_hptw_resp_bits_h_resp_entry_perm_a),
    .io_hptw_resp_bits_h_resp_entry_perm_g(io_hptw_resp_bits_h_resp_entry_perm_g),
    .io_hptw_resp_bits_h_resp_entry_perm_u(io_hptw_resp_bits_h_resp_entry_perm_u),
    .io_hptw_resp_bits_h_resp_entry_perm_x(io_hptw_resp_bits_h_resp_entry_perm_x),
    .io_hptw_resp_bits_h_resp_entry_perm_w(io_hptw_resp_bits_h_resp_entry_perm_w),
    .io_hptw_resp_bits_h_resp_entry_perm_r(io_hptw_resp_bits_h_resp_entry_perm_r),
    .io_hptw_resp_bits_h_resp_entry_level(io_hptw_resp_bits_h_resp_entry_level),
    .io_hptw_resp_bits_h_resp_gpf(io_hptw_resp_bits_h_resp_gpf),
    .io_hptw_resp_bits_h_resp_gaf(io_hptw_resp_bits_h_resp_gaf),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value)
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
    io_sfence_valid = $urandom;
    io_csr_satp_changed = $urandom;
    io_csr_vsatp_changed = $urandom;
    io_csr_hgatp_mode = $urandom;
    io_csr_hgatp_changed = $urandom;
    io_csr_priv_mxr = $urandom;
    io_csr_mPBMTE = $urandom;
    io_csr_hPBMTE = $urandom;
    io_in_valid = $urandom;
    io_in_bits_req_info_vpn = $urandom;
    io_in_bits_req_info_s2xlate = $urandom;
    io_in_bits_req_info_source = $urandom;
    io_in_bits_ppn = $urandom;
    io_out_ready = $urandom;
    io_mem_req_ready = $urandom;
    io_mem_resp_valid = $urandom;
    io_mem_resp_bits_id = $urandom;
    io_mem_resp_bits_value = $urandom;
    io_mem_req_mask_0 = $urandom;
    io_mem_req_mask_1 = $urandom;
    io_mem_req_mask_2 = $urandom;
    io_mem_req_mask_3 = $urandom;
    io_mem_req_mask_4 = $urandom;
    io_mem_req_mask_5 = $urandom;
    io_mem_flush_latch_0 = $urandom;
    io_mem_flush_latch_1 = $urandom;
    io_mem_flush_latch_2 = $urandom;
    io_mem_flush_latch_3 = $urandom;
    io_mem_flush_latch_4 = $urandom;
    io_mem_flush_latch_5 = $urandom;
    io_cache_ready = $urandom;
    io_pmp_resp_ld = $urandom;
    io_pmp_resp_mmio = $urandom;
    io_hptw_req_ready = $urandom;
    io_hptw_resp_valid = $urandom;
    io_hptw_resp_bits_id = $urandom;
    io_hptw_resp_bits_h_resp_entry_tag = $urandom;
    io_hptw_resp_bits_h_resp_entry_vmid = $urandom;
    io_hptw_resp_bits_h_resp_entry_n = $urandom;
    io_hptw_resp_bits_h_resp_entry_pbmt = $urandom;
    io_hptw_resp_bits_h_resp_entry_ppn = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_d = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_a = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_g = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_u = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_x = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_w = $urandom;
    io_hptw_resp_bits_h_resp_entry_perm_r = $urandom;
    io_hptw_resp_bits_h_resp_entry_level = $urandom;
    io_hptw_resp_bits_h_resp_gpf = $urandom;
    io_hptw_resp_bits_h_resp_gaf = $urandom;
    // 约束握手/CSR 环境，提高随机收敛与可达状态覆盖。
    io_in_valid = ($urandom_range(0, 1) == 0);
    io_in_bits_req_info_s2xlate = $urandom_range(0, 3);
    io_in_bits_req_info_source = $urandom_range(0, 3);
    io_out_ready = ($urandom_range(0, 3) != 0);
    io_cache_ready = ($urandom_range(0, 3) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_hptw_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_resp_valid = ($urandom_range(0, 2) == 0);
    io_hptw_resp_valid = ($urandom_range(0, 2) == 0);
    io_mem_resp_bits_id = $urandom_range(0, 5);
    io_hptw_resp_bits_id = $urandom_range(0, 5);
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0,1)==0) ? 4'h8 : 4'h9);
    io_sfence_valid = ($urandom_range(0, 127) == 0);
    io_csr_satp_changed = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
    // 同一 cacheline 概率：低位 vpn 收窄，使去重/dup 路径频繁激发。
    io_in_bits_req_info_vpn = {$urandom_range(0, 'h3F), $urandom_range(0, 'hFFFF)} & 38'h3FFFFFFFFF;
    if ($urandom_range(0, 1) == 0)
      io_in_bits_req_info_vpn[37:6] = 32'h12345; // 收敛到同一 L0 line
    io_mem_req_mask_0 = $urandom; io_mem_req_mask_1 = $urandom;
    io_mem_req_mask_2 = $urandom; io_mem_req_mask_3 = $urandom;
    io_mem_req_mask_4 = $urandom; io_mem_req_mask_5 = $urandom;
    io_mem_flush_latch_0 = ($urandom_range(0,15)==0); io_mem_flush_latch_1 = ($urandom_range(0,15)==0);
    io_mem_flush_latch_2 = ($urandom_range(0,15)==0); io_mem_flush_latch_3 = ($urandom_range(0,15)==0);
    io_mem_flush_latch_4 = ($urandom_range(0,15)==0); io_mem_flush_latch_5 = ($urandom_range(0,15)==0);
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    probe_errors = 0;
    reset = 1'b1;
    drive_random();
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (cycle = 0; cycle < 200000; cycle++) begin
      @(negedge clock);
      drive_random();
      @(posedge clock);
      #1;
      checks++;
      if (!$isunknown(g_io_in_ready) && i_io_in_ready !== g_io_in_ready) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_in_ready: g=%0h i=%0h cycle=%0d", g_io_in_ready, i_io_in_ready, cycle);
      end
      if (!$isunknown(g_io_out_valid) && i_io_out_valid !== g_io_out_valid) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_valid: g=%0h i=%0h cycle=%0d", g_io_out_valid, i_io_out_valid, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_vpn) && i_io_out_bits_req_info_vpn !== g_io_out_bits_req_info_vpn) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_req_info_vpn: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_vpn, i_io_out_bits_req_info_vpn, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_s2xlate) && i_io_out_bits_req_info_s2xlate !== g_io_out_bits_req_info_s2xlate) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_req_info_s2xlate: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_s2xlate, i_io_out_bits_req_info_s2xlate, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_source) && i_io_out_bits_req_info_source !== g_io_out_bits_req_info_source) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_req_info_source: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_source, i_io_out_bits_req_info_source, cycle);
      end
      if (!$isunknown(g_io_out_bits_id) && i_io_out_bits_id !== g_io_out_bits_id) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_id: g=%0h i=%0h cycle=%0d", g_io_out_bits_id, i_io_out_bits_id, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_tag) && i_io_out_bits_h_resp_entry_tag !== g_io_out_bits_h_resp_entry_tag) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_tag: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_tag, i_io_out_bits_h_resp_entry_tag, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_vmid) && i_io_out_bits_h_resp_entry_vmid !== g_io_out_bits_h_resp_entry_vmid) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_vmid: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_vmid, i_io_out_bits_h_resp_entry_vmid, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_n) && i_io_out_bits_h_resp_entry_n !== g_io_out_bits_h_resp_entry_n) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_n: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_n, i_io_out_bits_h_resp_entry_n, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_pbmt) && i_io_out_bits_h_resp_entry_pbmt !== g_io_out_bits_h_resp_entry_pbmt) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_pbmt: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_pbmt, i_io_out_bits_h_resp_entry_pbmt, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_ppn) && i_io_out_bits_h_resp_entry_ppn !== g_io_out_bits_h_resp_entry_ppn) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_ppn: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_ppn, i_io_out_bits_h_resp_entry_ppn, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_d) && i_io_out_bits_h_resp_entry_perm_d !== g_io_out_bits_h_resp_entry_perm_d) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_d: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_d, i_io_out_bits_h_resp_entry_perm_d, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_a) && i_io_out_bits_h_resp_entry_perm_a !== g_io_out_bits_h_resp_entry_perm_a) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_a: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_a, i_io_out_bits_h_resp_entry_perm_a, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_g) && i_io_out_bits_h_resp_entry_perm_g !== g_io_out_bits_h_resp_entry_perm_g) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_g: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_g, i_io_out_bits_h_resp_entry_perm_g, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_u) && i_io_out_bits_h_resp_entry_perm_u !== g_io_out_bits_h_resp_entry_perm_u) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_u: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_u, i_io_out_bits_h_resp_entry_perm_u, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_x) && i_io_out_bits_h_resp_entry_perm_x !== g_io_out_bits_h_resp_entry_perm_x) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_x: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_x, i_io_out_bits_h_resp_entry_perm_x, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_w) && i_io_out_bits_h_resp_entry_perm_w !== g_io_out_bits_h_resp_entry_perm_w) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_w: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_w, i_io_out_bits_h_resp_entry_perm_w, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_perm_r) && i_io_out_bits_h_resp_entry_perm_r !== g_io_out_bits_h_resp_entry_perm_r) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_perm_r: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_perm_r, i_io_out_bits_h_resp_entry_perm_r, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_entry_level) && i_io_out_bits_h_resp_entry_level !== g_io_out_bits_h_resp_entry_level) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_entry_level: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_entry_level, i_io_out_bits_h_resp_entry_level, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_gpf) && i_io_out_bits_h_resp_gpf !== g_io_out_bits_h_resp_gpf) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_gpf: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_gpf, i_io_out_bits_h_resp_gpf, cycle);
      end
      if (!$isunknown(g_io_out_bits_h_resp_gaf) && i_io_out_bits_h_resp_gaf !== g_io_out_bits_h_resp_gaf) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_h_resp_gaf: g=%0h i=%0h cycle=%0d", g_io_out_bits_h_resp_gaf, i_io_out_bits_h_resp_gaf, cycle);
      end
      if (!$isunknown(g_io_out_bits_first_s2xlate_fault) && i_io_out_bits_first_s2xlate_fault !== g_io_out_bits_first_s2xlate_fault) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_first_s2xlate_fault: g=%0h i=%0h cycle=%0d", g_io_out_bits_first_s2xlate_fault, i_io_out_bits_first_s2xlate_fault, cycle);
      end
      if (!$isunknown(g_io_out_bits_af) && i_io_out_bits_af !== g_io_out_bits_af) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_out_bits_af: g=%0h i=%0h cycle=%0d", g_io_out_bits_af, i_io_out_bits_af, cycle);
      end
      if (!$isunknown(g_io_mem_req_valid) && i_io_mem_req_valid !== g_io_mem_req_valid) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_req_valid: g=%0h i=%0h cycle=%0d", g_io_mem_req_valid, i_io_mem_req_valid, cycle);
      end
      if (!$isunknown(g_io_mem_req_bits_addr) && i_io_mem_req_bits_addr !== g_io_mem_req_bits_addr) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_mem_req_bits_addr, i_io_mem_req_bits_addr, cycle);
      end
      if (!$isunknown(g_io_mem_req_bits_id) && i_io_mem_req_bits_id !== g_io_mem_req_bits_id) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_req_bits_id: g=%0h i=%0h cycle=%0d", g_io_mem_req_bits_id, i_io_mem_req_bits_id, cycle);
      end
      if (!$isunknown(g_io_mem_enq_ptr) && i_io_mem_enq_ptr !== g_io_mem_enq_ptr) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_enq_ptr: g=%0h i=%0h cycle=%0d", g_io_mem_enq_ptr, i_io_mem_enq_ptr, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_0) && i_io_mem_buffer_it_0 !== g_io_mem_buffer_it_0) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_0: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_0, i_io_mem_buffer_it_0, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_1) && i_io_mem_buffer_it_1 !== g_io_mem_buffer_it_1) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_1: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_1, i_io_mem_buffer_it_1, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_2) && i_io_mem_buffer_it_2 !== g_io_mem_buffer_it_2) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_2: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_2, i_io_mem_buffer_it_2, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_3) && i_io_mem_buffer_it_3 !== g_io_mem_buffer_it_3) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_3: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_3, i_io_mem_buffer_it_3, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_4) && i_io_mem_buffer_it_4 !== g_io_mem_buffer_it_4) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_4: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_4, i_io_mem_buffer_it_4, cycle);
      end
      if (!$isunknown(g_io_mem_buffer_it_5) && i_io_mem_buffer_it_5 !== g_io_mem_buffer_it_5) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_buffer_it_5: g=%0h i=%0h cycle=%0d", g_io_mem_buffer_it_5, i_io_mem_buffer_it_5, cycle);
      end
      if (!$isunknown(g_io_mem_refill_vpn) && i_io_mem_refill_vpn !== g_io_mem_refill_vpn) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_refill_vpn: g=%0h i=%0h cycle=%0d", g_io_mem_refill_vpn, i_io_mem_refill_vpn, cycle);
      end
      if (!$isunknown(g_io_mem_refill_s2xlate) && i_io_mem_refill_s2xlate !== g_io_mem_refill_s2xlate) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_refill_s2xlate: g=%0h i=%0h cycle=%0d", g_io_mem_refill_s2xlate, i_io_mem_refill_s2xlate, cycle);
      end
      if (!$isunknown(g_io_mem_refill_source) && i_io_mem_refill_source !== g_io_mem_refill_source) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_mem_refill_source: g=%0h i=%0h cycle=%0d", g_io_mem_refill_source, i_io_mem_refill_source, cycle);
      end
      if (!$isunknown(g_io_cache_valid) && i_io_cache_valid !== g_io_cache_valid) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_cache_valid: g=%0h i=%0h cycle=%0d", g_io_cache_valid, i_io_cache_valid, cycle);
      end
      if (!$isunknown(g_io_cache_bits_vpn) && i_io_cache_bits_vpn !== g_io_cache_bits_vpn) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_cache_bits_vpn: g=%0h i=%0h cycle=%0d", g_io_cache_bits_vpn, i_io_cache_bits_vpn, cycle);
      end
      if (!$isunknown(g_io_cache_bits_s2xlate) && i_io_cache_bits_s2xlate !== g_io_cache_bits_s2xlate) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_cache_bits_s2xlate: g=%0h i=%0h cycle=%0d", g_io_cache_bits_s2xlate, i_io_cache_bits_s2xlate, cycle);
      end
      if (!$isunknown(g_io_cache_bits_source) && i_io_cache_bits_source !== g_io_cache_bits_source) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_cache_bits_source: g=%0h i=%0h cycle=%0d", g_io_cache_bits_source, i_io_cache_bits_source, cycle);
      end
      if (!$isunknown(g_io_pmp_req_bits_addr) && i_io_pmp_req_bits_addr !== g_io_pmp_req_bits_addr) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_pmp_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr, cycle);
      end
      if (!$isunknown(g_io_hptw_req_valid) && i_io_hptw_req_valid !== g_io_hptw_req_valid) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_hptw_req_valid: g=%0h i=%0h cycle=%0d", g_io_hptw_req_valid, i_io_hptw_req_valid, cycle);
      end
      if (!$isunknown(g_io_hptw_req_bits_source) && i_io_hptw_req_bits_source !== g_io_hptw_req_bits_source) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_hptw_req_bits_source: g=%0h i=%0h cycle=%0d", g_io_hptw_req_bits_source, i_io_hptw_req_bits_source, cycle);
      end
      if (!$isunknown(g_io_hptw_req_bits_id) && i_io_hptw_req_bits_id !== g_io_hptw_req_bits_id) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_hptw_req_bits_id: g=%0h i=%0h cycle=%0d", g_io_hptw_req_bits_id, i_io_hptw_req_bits_id, cycle);
      end
      if (!$isunknown(g_io_hptw_req_bits_gvpn) && i_io_hptw_req_bits_gvpn !== g_io_hptw_req_bits_gvpn) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_hptw_req_bits_gvpn: g=%0h i=%0h cycle=%0d", g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn, cycle);
      end
      if (!$isunknown(g_io_perf_0_value) && i_io_perf_0_value !== g_io_perf_0_value) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_perf_0_value: g=%0h i=%0h cycle=%0d", g_io_perf_0_value, i_io_perf_0_value, cycle);
      end
      if (!$isunknown(g_io_perf_1_value) && i_io_perf_1_value !== g_io_perf_1_value) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_perf_1_value: g=%0h i=%0h cycle=%0d", g_io_perf_1_value, i_io_perf_1_value, cycle);
      end
      if (!$isunknown(g_io_perf_2_value) && i_io_perf_2_value !== g_io_perf_2_value) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_perf_2_value: g=%0h i=%0h cycle=%0d", g_io_perf_2_value, i_io_perf_2_value, cycle);
      end
      if (!$isunknown(g_io_perf_3_value) && i_io_perf_3_value !== g_io_perf_3_value) begin
        errors++;
        if (errors < 30) $display("MISMATCH io_perf_3_value: g=%0h i=%0h cycle=%0d", g_io_perf_3_value, i_io_perf_3_value, cycle);
      end
      if (!$isunknown(u_g.state_0) && u_i.u_core.state[0] !== u_g.state_0) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state0 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_0, u_i.u_core.state[0], cycle);
      end
      if (!$isunknown(u_g.state_1) && u_i.u_core.state[1] !== u_g.state_1) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state1 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_1, u_i.u_core.state[1], cycle);
      end
      if (!$isunknown(u_g.state_2) && u_i.u_core.state[2] !== u_g.state_2) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state2 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_2, u_i.u_core.state[2], cycle);
      end
      if (!$isunknown(u_g.state_3) && u_i.u_core.state[3] !== u_g.state_3) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state3 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_3, u_i.u_core.state[3], cycle);
      end
      if (!$isunknown(u_g.state_4) && u_i.u_core.state[4] !== u_g.state_4) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state4 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_4, u_i.u_core.state[4], cycle);
      end
      if (!$isunknown(u_g.state_5) && u_i.u_core.state[5] !== u_g.state_5) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE state5 mismatch: g=%0h i=%0h cycle=%0d", u_g.state_5, u_i.u_core.state[5], cycle);
      end
      if (!$isunknown(u_g.addr) && u_i.u_core.addr_reg !== u_g.addr) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE addr_reg mismatch: g=%0h i=%0h cycle=%0d", u_g.addr, u_i.u_core.addr_reg, cycle);
      end
      if (!$isunknown(u_g.enq_ptr_reg) && u_i.u_core.enq_ptr_reg !== u_g.enq_ptr_reg) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE enq_ptr_reg mismatch: g=%0h i=%0h cycle=%0d", u_g.enq_ptr_reg, u_i.u_core.enq_ptr_reg, cycle);
      end
      if (!$isunknown(u_g.hptw_resp_ptr_reg) && u_i.u_core.hptw_resp_ptr_reg !== u_g.hptw_resp_ptr_reg) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE hptw_resp_ptr_reg mismatch: g=%0h i=%0h cycle=%0d", u_g.hptw_resp_ptr_reg, u_i.u_core.hptw_resp_ptr_reg, cycle);
      end
      if (!$isunknown(u_g.mem_refill_id) && u_i.u_core.mem_refill_id !== u_g.mem_refill_id) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE mem_refill_id mismatch: g=%0h i=%0h cycle=%0d", u_g.mem_refill_id, u_i.u_core.mem_refill_id, cycle);
      end
      if (!$isunknown(u_g.need_addr_check_last_REG) && u_i.u_core.need_addr_check !== u_g.need_addr_check_last_REG) begin
        probe_errors++;
        if (probe_errors < 30) $display("PROBE need_addr_check mismatch: g=%0h i=%0h cycle=%0d", u_g.need_addr_check_last_REG, u_i.u_core.need_addr_check, cycle);
      end
    end
    $display("LLPTW_UT checks=%0d errors=%0d probe_errors=%0d", checks, errors, probe_errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "LLPTW mismatch");
    $finish;
  end
endmodule
