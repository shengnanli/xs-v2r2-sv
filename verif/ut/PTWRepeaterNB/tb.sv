// PTWRepeaterNB 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= PTWRepeaterNB =================
  int unsigned r_mode = 0;
  initial begin
    #1;
    force r_u_impl.u_core.req = {r_u_gold.req_vpn, r_u_gold.req_s2xlate};
    force r_u_impl.u_core.resp = {r_u_gold.resp_s2xlate, r_u_gold.resp_s1_entry_tag, r_u_gold.resp_s1_entry_asid, r_u_gold.resp_s1_entry_vmid, r_u_gold.resp_s1_entry_n, r_u_gold.resp_s1_entry_pbmt, r_u_gold.resp_s1_entry_perm_d, r_u_gold.resp_s1_entry_perm_a, r_u_gold.resp_s1_entry_perm_g, r_u_gold.resp_s1_entry_perm_u, r_u_gold.resp_s1_entry_perm_x, r_u_gold.resp_s1_entry_perm_w, r_u_gold.resp_s1_entry_perm_r, r_u_gold.resp_s1_entry_level, r_u_gold.resp_s1_entry_v, r_u_gold.resp_s1_entry_ppn, r_u_gold.resp_s1_addr_low, r_u_gold.resp_s1_ppn_low_0, r_u_gold.resp_s1_ppn_low_1, r_u_gold.resp_s1_ppn_low_2, r_u_gold.resp_s1_ppn_low_3, r_u_gold.resp_s1_ppn_low_4, r_u_gold.resp_s1_ppn_low_5, r_u_gold.resp_s1_ppn_low_6, r_u_gold.resp_s1_ppn_low_7, r_u_gold.resp_s1_valididx_0, r_u_gold.resp_s1_valididx_1, r_u_gold.resp_s1_valididx_2, r_u_gold.resp_s1_valididx_3, r_u_gold.resp_s1_valididx_4, r_u_gold.resp_s1_valididx_5, r_u_gold.resp_s1_valididx_6, r_u_gold.resp_s1_valididx_7, r_u_gold.resp_s1_pteidx_0, r_u_gold.resp_s1_pteidx_1, r_u_gold.resp_s1_pteidx_2, r_u_gold.resp_s1_pteidx_3, r_u_gold.resp_s1_pteidx_4, r_u_gold.resp_s1_pteidx_5, r_u_gold.resp_s1_pteidx_6, r_u_gold.resp_s1_pteidx_7, r_u_gold.resp_s1_pf, r_u_gold.resp_s1_af, r_u_gold.resp_s2_entry_tag, r_u_gold.resp_s2_entry_vmid, r_u_gold.resp_s2_entry_n, r_u_gold.resp_s2_entry_pbmt, r_u_gold.resp_s2_entry_ppn, r_u_gold.resp_s2_entry_perm_d, r_u_gold.resp_s2_entry_perm_a, r_u_gold.resp_s2_entry_perm_g, r_u_gold.resp_s2_entry_perm_u, r_u_gold.resp_s2_entry_perm_x, r_u_gold.resp_s2_entry_perm_w, r_u_gold.resp_s2_entry_perm_r, r_u_gold.resp_s2_entry_level, r_u_gold.resp_s2_gpf, r_u_gold.resp_s2_gaf};
    force r_u_impl.u_core.sent = r_u_gold.sent;
    force r_u_impl.u_core.recv = r_u_gold.recv;
    #0;
    release r_u_impl.u_core.req;
    release r_u_impl.u_core.resp;
    release r_u_impl.u_core.sent;
    release r_u_impl.u_core.recv;
  end
  logic r_reset;
  logic r_io_sfence_valid;
  logic r_io_csr_satp_changed;
  logic r_io_csr_vsatp_changed;
  logic r_io_csr_hgatp_changed;
  logic r_io_csr_priv_virt_changed;
  wire  r_g_io_tlb_req_0_ready, r_i_io_tlb_req_0_ready;
  logic r_s0_io_tlb_req_0_ready = '0, r_s1_io_tlb_req_0_ready = '0;
  logic r_io_tlb_req_0_valid;
  logic [37:0] r_io_tlb_req_0_bits_vpn;
  logic [1:0] r_io_tlb_req_0_bits_s2xlate;
  logic r_io_tlb_resp_ready;
  wire  r_g_io_tlb_resp_valid, r_i_io_tlb_resp_valid;
  logic r_s0_io_tlb_resp_valid = '0, r_s1_io_tlb_resp_valid = '0;
  wire  [1:0] r_g_io_tlb_resp_bits_s2xlate, r_i_io_tlb_resp_bits_s2xlate;
  logic [1:0] r_s0_io_tlb_resp_bits_s2xlate = '0, r_s1_io_tlb_resp_bits_s2xlate = '0;
  wire  [34:0] r_g_io_tlb_resp_bits_s1_entry_tag, r_i_io_tlb_resp_bits_s1_entry_tag;
  logic [34:0] r_s0_io_tlb_resp_bits_s1_entry_tag = '0, r_s1_io_tlb_resp_bits_s1_entry_tag = '0;
  wire  [15:0] r_g_io_tlb_resp_bits_s1_entry_asid, r_i_io_tlb_resp_bits_s1_entry_asid;
  logic [15:0] r_s0_io_tlb_resp_bits_s1_entry_asid = '0, r_s1_io_tlb_resp_bits_s1_entry_asid = '0;
  wire  [13:0] r_g_io_tlb_resp_bits_s1_entry_vmid, r_i_io_tlb_resp_bits_s1_entry_vmid;
  logic [13:0] r_s0_io_tlb_resp_bits_s1_entry_vmid = '0, r_s1_io_tlb_resp_bits_s1_entry_vmid = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_n, r_i_io_tlb_resp_bits_s1_entry_n;
  logic r_s0_io_tlb_resp_bits_s1_entry_n = '0, r_s1_io_tlb_resp_bits_s1_entry_n = '0;
  wire  [1:0] r_g_io_tlb_resp_bits_s1_entry_pbmt, r_i_io_tlb_resp_bits_s1_entry_pbmt;
  logic [1:0] r_s0_io_tlb_resp_bits_s1_entry_pbmt = '0, r_s1_io_tlb_resp_bits_s1_entry_pbmt = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_d, r_i_io_tlb_resp_bits_s1_entry_perm_d;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_d = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_d = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_a, r_i_io_tlb_resp_bits_s1_entry_perm_a;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_a = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_a = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_g, r_i_io_tlb_resp_bits_s1_entry_perm_g;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_g = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_g = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_u, r_i_io_tlb_resp_bits_s1_entry_perm_u;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_u = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_u = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_x, r_i_io_tlb_resp_bits_s1_entry_perm_x;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_x = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_x = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_w, r_i_io_tlb_resp_bits_s1_entry_perm_w;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_w = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_w = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_perm_r, r_i_io_tlb_resp_bits_s1_entry_perm_r;
  logic r_s0_io_tlb_resp_bits_s1_entry_perm_r = '0, r_s1_io_tlb_resp_bits_s1_entry_perm_r = '0;
  wire  [1:0] r_g_io_tlb_resp_bits_s1_entry_level, r_i_io_tlb_resp_bits_s1_entry_level;
  logic [1:0] r_s0_io_tlb_resp_bits_s1_entry_level = '0, r_s1_io_tlb_resp_bits_s1_entry_level = '0;
  wire  r_g_io_tlb_resp_bits_s1_entry_v, r_i_io_tlb_resp_bits_s1_entry_v;
  logic r_s0_io_tlb_resp_bits_s1_entry_v = '0, r_s1_io_tlb_resp_bits_s1_entry_v = '0;
  wire  [40:0] r_g_io_tlb_resp_bits_s1_entry_ppn, r_i_io_tlb_resp_bits_s1_entry_ppn;
  logic [40:0] r_s0_io_tlb_resp_bits_s1_entry_ppn = '0, r_s1_io_tlb_resp_bits_s1_entry_ppn = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_addr_low, r_i_io_tlb_resp_bits_s1_addr_low;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_addr_low = '0, r_s1_io_tlb_resp_bits_s1_addr_low = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_0, r_i_io_tlb_resp_bits_s1_ppn_low_0;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_0 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_0 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_1, r_i_io_tlb_resp_bits_s1_ppn_low_1;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_1 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_1 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_2, r_i_io_tlb_resp_bits_s1_ppn_low_2;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_2 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_2 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_3, r_i_io_tlb_resp_bits_s1_ppn_low_3;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_3 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_3 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_4, r_i_io_tlb_resp_bits_s1_ppn_low_4;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_4 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_4 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_5, r_i_io_tlb_resp_bits_s1_ppn_low_5;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_5 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_5 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_6, r_i_io_tlb_resp_bits_s1_ppn_low_6;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_6 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_6 = '0;
  wire  [2:0] r_g_io_tlb_resp_bits_s1_ppn_low_7, r_i_io_tlb_resp_bits_s1_ppn_low_7;
  logic [2:0] r_s0_io_tlb_resp_bits_s1_ppn_low_7 = '0, r_s1_io_tlb_resp_bits_s1_ppn_low_7 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_0, r_i_io_tlb_resp_bits_s1_valididx_0;
  logic r_s0_io_tlb_resp_bits_s1_valididx_0 = '0, r_s1_io_tlb_resp_bits_s1_valididx_0 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_1, r_i_io_tlb_resp_bits_s1_valididx_1;
  logic r_s0_io_tlb_resp_bits_s1_valididx_1 = '0, r_s1_io_tlb_resp_bits_s1_valididx_1 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_2, r_i_io_tlb_resp_bits_s1_valididx_2;
  logic r_s0_io_tlb_resp_bits_s1_valididx_2 = '0, r_s1_io_tlb_resp_bits_s1_valididx_2 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_3, r_i_io_tlb_resp_bits_s1_valididx_3;
  logic r_s0_io_tlb_resp_bits_s1_valididx_3 = '0, r_s1_io_tlb_resp_bits_s1_valididx_3 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_4, r_i_io_tlb_resp_bits_s1_valididx_4;
  logic r_s0_io_tlb_resp_bits_s1_valididx_4 = '0, r_s1_io_tlb_resp_bits_s1_valididx_4 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_5, r_i_io_tlb_resp_bits_s1_valididx_5;
  logic r_s0_io_tlb_resp_bits_s1_valididx_5 = '0, r_s1_io_tlb_resp_bits_s1_valididx_5 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_6, r_i_io_tlb_resp_bits_s1_valididx_6;
  logic r_s0_io_tlb_resp_bits_s1_valididx_6 = '0, r_s1_io_tlb_resp_bits_s1_valididx_6 = '0;
  wire  r_g_io_tlb_resp_bits_s1_valididx_7, r_i_io_tlb_resp_bits_s1_valididx_7;
  logic r_s0_io_tlb_resp_bits_s1_valididx_7 = '0, r_s1_io_tlb_resp_bits_s1_valididx_7 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_0, r_i_io_tlb_resp_bits_s1_pteidx_0;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_0 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_0 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_1, r_i_io_tlb_resp_bits_s1_pteidx_1;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_1 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_1 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_2, r_i_io_tlb_resp_bits_s1_pteidx_2;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_2 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_2 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_3, r_i_io_tlb_resp_bits_s1_pteidx_3;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_3 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_3 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_4, r_i_io_tlb_resp_bits_s1_pteidx_4;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_4 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_4 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_5, r_i_io_tlb_resp_bits_s1_pteidx_5;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_5 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_5 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_6, r_i_io_tlb_resp_bits_s1_pteidx_6;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_6 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_6 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pteidx_7, r_i_io_tlb_resp_bits_s1_pteidx_7;
  logic r_s0_io_tlb_resp_bits_s1_pteidx_7 = '0, r_s1_io_tlb_resp_bits_s1_pteidx_7 = '0;
  wire  r_g_io_tlb_resp_bits_s1_pf, r_i_io_tlb_resp_bits_s1_pf;
  logic r_s0_io_tlb_resp_bits_s1_pf = '0, r_s1_io_tlb_resp_bits_s1_pf = '0;
  wire  r_g_io_tlb_resp_bits_s1_af, r_i_io_tlb_resp_bits_s1_af;
  logic r_s0_io_tlb_resp_bits_s1_af = '0, r_s1_io_tlb_resp_bits_s1_af = '0;
  wire  [37:0] r_g_io_tlb_resp_bits_s2_entry_tag, r_i_io_tlb_resp_bits_s2_entry_tag;
  logic [37:0] r_s0_io_tlb_resp_bits_s2_entry_tag = '0, r_s1_io_tlb_resp_bits_s2_entry_tag = '0;
  wire  [13:0] r_g_io_tlb_resp_bits_s2_entry_vmid, r_i_io_tlb_resp_bits_s2_entry_vmid;
  logic [13:0] r_s0_io_tlb_resp_bits_s2_entry_vmid = '0, r_s1_io_tlb_resp_bits_s2_entry_vmid = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_n, r_i_io_tlb_resp_bits_s2_entry_n;
  logic r_s0_io_tlb_resp_bits_s2_entry_n = '0, r_s1_io_tlb_resp_bits_s2_entry_n = '0;
  wire  [1:0] r_g_io_tlb_resp_bits_s2_entry_pbmt, r_i_io_tlb_resp_bits_s2_entry_pbmt;
  logic [1:0] r_s0_io_tlb_resp_bits_s2_entry_pbmt = '0, r_s1_io_tlb_resp_bits_s2_entry_pbmt = '0;
  wire  [37:0] r_g_io_tlb_resp_bits_s2_entry_ppn, r_i_io_tlb_resp_bits_s2_entry_ppn;
  logic [37:0] r_s0_io_tlb_resp_bits_s2_entry_ppn = '0, r_s1_io_tlb_resp_bits_s2_entry_ppn = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_d, r_i_io_tlb_resp_bits_s2_entry_perm_d;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_d = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_d = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_a, r_i_io_tlb_resp_bits_s2_entry_perm_a;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_a = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_a = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_g, r_i_io_tlb_resp_bits_s2_entry_perm_g;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_g = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_g = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_u, r_i_io_tlb_resp_bits_s2_entry_perm_u;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_u = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_u = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_x, r_i_io_tlb_resp_bits_s2_entry_perm_x;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_x = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_x = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_w, r_i_io_tlb_resp_bits_s2_entry_perm_w;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_w = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_w = '0;
  wire  r_g_io_tlb_resp_bits_s2_entry_perm_r, r_i_io_tlb_resp_bits_s2_entry_perm_r;
  logic r_s0_io_tlb_resp_bits_s2_entry_perm_r = '0, r_s1_io_tlb_resp_bits_s2_entry_perm_r = '0;
  wire  [1:0] r_g_io_tlb_resp_bits_s2_entry_level, r_i_io_tlb_resp_bits_s2_entry_level;
  logic [1:0] r_s0_io_tlb_resp_bits_s2_entry_level = '0, r_s1_io_tlb_resp_bits_s2_entry_level = '0;
  wire  r_g_io_tlb_resp_bits_s2_gpf, r_i_io_tlb_resp_bits_s2_gpf;
  logic r_s0_io_tlb_resp_bits_s2_gpf = '0, r_s1_io_tlb_resp_bits_s2_gpf = '0;
  wire  r_g_io_tlb_resp_bits_s2_gaf, r_i_io_tlb_resp_bits_s2_gaf;
  logic r_s0_io_tlb_resp_bits_s2_gaf = '0, r_s1_io_tlb_resp_bits_s2_gaf = '0;
  logic r_io_ptw_req_0_ready;
  wire  r_g_io_ptw_req_0_valid, r_i_io_ptw_req_0_valid;
  logic r_s0_io_ptw_req_0_valid = '0, r_s1_io_ptw_req_0_valid = '0;
  wire  [37:0] r_g_io_ptw_req_0_bits_vpn, r_i_io_ptw_req_0_bits_vpn;
  logic [37:0] r_s0_io_ptw_req_0_bits_vpn = '0, r_s1_io_ptw_req_0_bits_vpn = '0;
  wire  [1:0] r_g_io_ptw_req_0_bits_s2xlate, r_i_io_ptw_req_0_bits_s2xlate;
  logic [1:0] r_s0_io_ptw_req_0_bits_s2xlate = '0, r_s1_io_ptw_req_0_bits_s2xlate = '0;
  wire  r_g_io_ptw_resp_ready, r_i_io_ptw_resp_ready;
  logic r_s0_io_ptw_resp_ready = '0, r_s1_io_ptw_resp_ready = '0;
  logic r_io_ptw_resp_valid;
  logic [1:0] r_io_ptw_resp_bits_s2xlate;
  logic [34:0] r_io_ptw_resp_bits_s1_entry_tag;
  logic [15:0] r_io_ptw_resp_bits_s1_entry_asid;
  logic [13:0] r_io_ptw_resp_bits_s1_entry_vmid;
  logic r_io_ptw_resp_bits_s1_entry_n;
  logic [1:0] r_io_ptw_resp_bits_s1_entry_pbmt;
  logic r_io_ptw_resp_bits_s1_entry_perm_d;
  logic r_io_ptw_resp_bits_s1_entry_perm_a;
  logic r_io_ptw_resp_bits_s1_entry_perm_g;
  logic r_io_ptw_resp_bits_s1_entry_perm_u;
  logic r_io_ptw_resp_bits_s1_entry_perm_x;
  logic r_io_ptw_resp_bits_s1_entry_perm_w;
  logic r_io_ptw_resp_bits_s1_entry_perm_r;
  logic [1:0] r_io_ptw_resp_bits_s1_entry_level;
  logic r_io_ptw_resp_bits_s1_entry_v;
  logic [40:0] r_io_ptw_resp_bits_s1_entry_ppn;
  logic [2:0] r_io_ptw_resp_bits_s1_addr_low;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_0;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_1;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_2;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_3;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_4;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_5;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_6;
  logic [2:0] r_io_ptw_resp_bits_s1_ppn_low_7;
  logic r_io_ptw_resp_bits_s1_valididx_0;
  logic r_io_ptw_resp_bits_s1_valididx_1;
  logic r_io_ptw_resp_bits_s1_valididx_2;
  logic r_io_ptw_resp_bits_s1_valididx_3;
  logic r_io_ptw_resp_bits_s1_valididx_4;
  logic r_io_ptw_resp_bits_s1_valididx_5;
  logic r_io_ptw_resp_bits_s1_valididx_6;
  logic r_io_ptw_resp_bits_s1_valididx_7;
  logic r_io_ptw_resp_bits_s1_pteidx_0;
  logic r_io_ptw_resp_bits_s1_pteidx_1;
  logic r_io_ptw_resp_bits_s1_pteidx_2;
  logic r_io_ptw_resp_bits_s1_pteidx_3;
  logic r_io_ptw_resp_bits_s1_pteidx_4;
  logic r_io_ptw_resp_bits_s1_pteidx_5;
  logic r_io_ptw_resp_bits_s1_pteidx_6;
  logic r_io_ptw_resp_bits_s1_pteidx_7;
  logic r_io_ptw_resp_bits_s1_pf;
  logic r_io_ptw_resp_bits_s1_af;
  logic [37:0] r_io_ptw_resp_bits_s2_entry_tag;
  logic [13:0] r_io_ptw_resp_bits_s2_entry_vmid;
  logic r_io_ptw_resp_bits_s2_entry_n;
  logic [1:0] r_io_ptw_resp_bits_s2_entry_pbmt;
  logic [37:0] r_io_ptw_resp_bits_s2_entry_ppn;
  logic r_io_ptw_resp_bits_s2_entry_perm_d;
  logic r_io_ptw_resp_bits_s2_entry_perm_a;
  logic r_io_ptw_resp_bits_s2_entry_perm_g;
  logic r_io_ptw_resp_bits_s2_entry_perm_u;
  logic r_io_ptw_resp_bits_s2_entry_perm_x;
  logic r_io_ptw_resp_bits_s2_entry_perm_w;
  logic r_io_ptw_resp_bits_s2_entry_perm_r;
  logic [1:0] r_io_ptw_resp_bits_s2_entry_level;
  logic r_io_ptw_resp_bits_s2_gpf;
  logic r_io_ptw_resp_bits_s2_gaf;
  int r_cov_req_fire = 0;
  int r_cov_req_sent = 0;
  int r_cov_resp_recv = 0;
  int r_cov_resp_out = 0;
  int r_cov_flush_sent = 0;
  int r_cov_flush_recv = 0;
  int r_cov_sent_and_recv = 0;
  logic [0:0] r_armed = '0;
  int r_armed_at = -1;
  PTWRepeaterNB r_u_gold (
    .clock(clk),
    .reset(r_reset),
    .io_sfence_valid(r_io_sfence_valid),
    .io_csr_satp_changed(r_io_csr_satp_changed),
    .io_csr_vsatp_changed(r_io_csr_vsatp_changed),
    .io_csr_hgatp_changed(r_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(r_io_csr_priv_virt_changed),
    .io_tlb_req_0_ready(r_g_io_tlb_req_0_ready),
    .io_tlb_req_0_valid(r_io_tlb_req_0_valid),
    .io_tlb_req_0_bits_vpn(r_io_tlb_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate(r_io_tlb_req_0_bits_s2xlate),
    .io_tlb_resp_ready(r_io_tlb_resp_ready),
    .io_tlb_resp_valid(r_g_io_tlb_resp_valid),
    .io_tlb_resp_bits_s2xlate(r_g_io_tlb_resp_bits_s2xlate),
    .io_tlb_resp_bits_s1_entry_tag(r_g_io_tlb_resp_bits_s1_entry_tag),
    .io_tlb_resp_bits_s1_entry_asid(r_g_io_tlb_resp_bits_s1_entry_asid),
    .io_tlb_resp_bits_s1_entry_vmid(r_g_io_tlb_resp_bits_s1_entry_vmid),
    .io_tlb_resp_bits_s1_entry_n(r_g_io_tlb_resp_bits_s1_entry_n),
    .io_tlb_resp_bits_s1_entry_pbmt(r_g_io_tlb_resp_bits_s1_entry_pbmt),
    .io_tlb_resp_bits_s1_entry_perm_d(r_g_io_tlb_resp_bits_s1_entry_perm_d),
    .io_tlb_resp_bits_s1_entry_perm_a(r_g_io_tlb_resp_bits_s1_entry_perm_a),
    .io_tlb_resp_bits_s1_entry_perm_g(r_g_io_tlb_resp_bits_s1_entry_perm_g),
    .io_tlb_resp_bits_s1_entry_perm_u(r_g_io_tlb_resp_bits_s1_entry_perm_u),
    .io_tlb_resp_bits_s1_entry_perm_x(r_g_io_tlb_resp_bits_s1_entry_perm_x),
    .io_tlb_resp_bits_s1_entry_perm_w(r_g_io_tlb_resp_bits_s1_entry_perm_w),
    .io_tlb_resp_bits_s1_entry_perm_r(r_g_io_tlb_resp_bits_s1_entry_perm_r),
    .io_tlb_resp_bits_s1_entry_level(r_g_io_tlb_resp_bits_s1_entry_level),
    .io_tlb_resp_bits_s1_entry_v(r_g_io_tlb_resp_bits_s1_entry_v),
    .io_tlb_resp_bits_s1_entry_ppn(r_g_io_tlb_resp_bits_s1_entry_ppn),
    .io_tlb_resp_bits_s1_addr_low(r_g_io_tlb_resp_bits_s1_addr_low),
    .io_tlb_resp_bits_s1_ppn_low_0(r_g_io_tlb_resp_bits_s1_ppn_low_0),
    .io_tlb_resp_bits_s1_ppn_low_1(r_g_io_tlb_resp_bits_s1_ppn_low_1),
    .io_tlb_resp_bits_s1_ppn_low_2(r_g_io_tlb_resp_bits_s1_ppn_low_2),
    .io_tlb_resp_bits_s1_ppn_low_3(r_g_io_tlb_resp_bits_s1_ppn_low_3),
    .io_tlb_resp_bits_s1_ppn_low_4(r_g_io_tlb_resp_bits_s1_ppn_low_4),
    .io_tlb_resp_bits_s1_ppn_low_5(r_g_io_tlb_resp_bits_s1_ppn_low_5),
    .io_tlb_resp_bits_s1_ppn_low_6(r_g_io_tlb_resp_bits_s1_ppn_low_6),
    .io_tlb_resp_bits_s1_ppn_low_7(r_g_io_tlb_resp_bits_s1_ppn_low_7),
    .io_tlb_resp_bits_s1_valididx_0(r_g_io_tlb_resp_bits_s1_valididx_0),
    .io_tlb_resp_bits_s1_valididx_1(r_g_io_tlb_resp_bits_s1_valididx_1),
    .io_tlb_resp_bits_s1_valididx_2(r_g_io_tlb_resp_bits_s1_valididx_2),
    .io_tlb_resp_bits_s1_valididx_3(r_g_io_tlb_resp_bits_s1_valididx_3),
    .io_tlb_resp_bits_s1_valididx_4(r_g_io_tlb_resp_bits_s1_valididx_4),
    .io_tlb_resp_bits_s1_valididx_5(r_g_io_tlb_resp_bits_s1_valididx_5),
    .io_tlb_resp_bits_s1_valididx_6(r_g_io_tlb_resp_bits_s1_valididx_6),
    .io_tlb_resp_bits_s1_valididx_7(r_g_io_tlb_resp_bits_s1_valididx_7),
    .io_tlb_resp_bits_s1_pteidx_0(r_g_io_tlb_resp_bits_s1_pteidx_0),
    .io_tlb_resp_bits_s1_pteidx_1(r_g_io_tlb_resp_bits_s1_pteidx_1),
    .io_tlb_resp_bits_s1_pteidx_2(r_g_io_tlb_resp_bits_s1_pteidx_2),
    .io_tlb_resp_bits_s1_pteidx_3(r_g_io_tlb_resp_bits_s1_pteidx_3),
    .io_tlb_resp_bits_s1_pteidx_4(r_g_io_tlb_resp_bits_s1_pteidx_4),
    .io_tlb_resp_bits_s1_pteidx_5(r_g_io_tlb_resp_bits_s1_pteidx_5),
    .io_tlb_resp_bits_s1_pteidx_6(r_g_io_tlb_resp_bits_s1_pteidx_6),
    .io_tlb_resp_bits_s1_pteidx_7(r_g_io_tlb_resp_bits_s1_pteidx_7),
    .io_tlb_resp_bits_s1_pf(r_g_io_tlb_resp_bits_s1_pf),
    .io_tlb_resp_bits_s1_af(r_g_io_tlb_resp_bits_s1_af),
    .io_tlb_resp_bits_s2_entry_tag(r_g_io_tlb_resp_bits_s2_entry_tag),
    .io_tlb_resp_bits_s2_entry_vmid(r_g_io_tlb_resp_bits_s2_entry_vmid),
    .io_tlb_resp_bits_s2_entry_n(r_g_io_tlb_resp_bits_s2_entry_n),
    .io_tlb_resp_bits_s2_entry_pbmt(r_g_io_tlb_resp_bits_s2_entry_pbmt),
    .io_tlb_resp_bits_s2_entry_ppn(r_g_io_tlb_resp_bits_s2_entry_ppn),
    .io_tlb_resp_bits_s2_entry_perm_d(r_g_io_tlb_resp_bits_s2_entry_perm_d),
    .io_tlb_resp_bits_s2_entry_perm_a(r_g_io_tlb_resp_bits_s2_entry_perm_a),
    .io_tlb_resp_bits_s2_entry_perm_g(r_g_io_tlb_resp_bits_s2_entry_perm_g),
    .io_tlb_resp_bits_s2_entry_perm_u(r_g_io_tlb_resp_bits_s2_entry_perm_u),
    .io_tlb_resp_bits_s2_entry_perm_x(r_g_io_tlb_resp_bits_s2_entry_perm_x),
    .io_tlb_resp_bits_s2_entry_perm_w(r_g_io_tlb_resp_bits_s2_entry_perm_w),
    .io_tlb_resp_bits_s2_entry_perm_r(r_g_io_tlb_resp_bits_s2_entry_perm_r),
    .io_tlb_resp_bits_s2_entry_level(r_g_io_tlb_resp_bits_s2_entry_level),
    .io_tlb_resp_bits_s2_gpf(r_g_io_tlb_resp_bits_s2_gpf),
    .io_tlb_resp_bits_s2_gaf(r_g_io_tlb_resp_bits_s2_gaf),
    .io_ptw_req_0_ready(r_io_ptw_req_0_ready),
    .io_ptw_req_0_valid(r_g_io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn(r_g_io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate(r_g_io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_ready(r_g_io_ptw_resp_ready),
    .io_ptw_resp_valid(r_io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate(r_io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag(r_io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid(r_io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid(r_io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n(r_io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt(r_io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d(r_io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a(r_io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g(r_io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u(r_io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x(r_io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w(r_io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r(r_io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level(r_io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v(r_io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn(r_io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low(r_io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0(r_io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1(r_io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2(r_io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3(r_io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4(r_io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5(r_io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6(r_io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7(r_io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0(r_io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1(r_io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2(r_io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3(r_io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4(r_io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5(r_io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6(r_io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7(r_io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0(r_io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1(r_io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2(r_io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3(r_io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4(r_io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5(r_io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6(r_io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7(r_io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf(r_io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af(r_io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag(r_io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid(r_io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n(r_io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt(r_io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn(r_io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d(r_io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a(r_io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g(r_io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u(r_io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x(r_io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w(r_io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r(r_io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level(r_io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf(r_io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf(r_io_ptw_resp_bits_s2_gaf)
  );
  PTWRepeaterNB_xs r_u_impl (
    .clock(clk),
    .reset(r_reset),
    .io_sfence_valid(r_io_sfence_valid),
    .io_csr_satp_changed(r_io_csr_satp_changed),
    .io_csr_vsatp_changed(r_io_csr_vsatp_changed),
    .io_csr_hgatp_changed(r_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(r_io_csr_priv_virt_changed),
    .io_tlb_req_0_ready(r_i_io_tlb_req_0_ready),
    .io_tlb_req_0_valid(r_io_tlb_req_0_valid),
    .io_tlb_req_0_bits_vpn(r_io_tlb_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate(r_io_tlb_req_0_bits_s2xlate),
    .io_tlb_resp_ready(r_io_tlb_resp_ready),
    .io_tlb_resp_valid(r_i_io_tlb_resp_valid),
    .io_tlb_resp_bits_s2xlate(r_i_io_tlb_resp_bits_s2xlate),
    .io_tlb_resp_bits_s1_entry_tag(r_i_io_tlb_resp_bits_s1_entry_tag),
    .io_tlb_resp_bits_s1_entry_asid(r_i_io_tlb_resp_bits_s1_entry_asid),
    .io_tlb_resp_bits_s1_entry_vmid(r_i_io_tlb_resp_bits_s1_entry_vmid),
    .io_tlb_resp_bits_s1_entry_n(r_i_io_tlb_resp_bits_s1_entry_n),
    .io_tlb_resp_bits_s1_entry_pbmt(r_i_io_tlb_resp_bits_s1_entry_pbmt),
    .io_tlb_resp_bits_s1_entry_perm_d(r_i_io_tlb_resp_bits_s1_entry_perm_d),
    .io_tlb_resp_bits_s1_entry_perm_a(r_i_io_tlb_resp_bits_s1_entry_perm_a),
    .io_tlb_resp_bits_s1_entry_perm_g(r_i_io_tlb_resp_bits_s1_entry_perm_g),
    .io_tlb_resp_bits_s1_entry_perm_u(r_i_io_tlb_resp_bits_s1_entry_perm_u),
    .io_tlb_resp_bits_s1_entry_perm_x(r_i_io_tlb_resp_bits_s1_entry_perm_x),
    .io_tlb_resp_bits_s1_entry_perm_w(r_i_io_tlb_resp_bits_s1_entry_perm_w),
    .io_tlb_resp_bits_s1_entry_perm_r(r_i_io_tlb_resp_bits_s1_entry_perm_r),
    .io_tlb_resp_bits_s1_entry_level(r_i_io_tlb_resp_bits_s1_entry_level),
    .io_tlb_resp_bits_s1_entry_v(r_i_io_tlb_resp_bits_s1_entry_v),
    .io_tlb_resp_bits_s1_entry_ppn(r_i_io_tlb_resp_bits_s1_entry_ppn),
    .io_tlb_resp_bits_s1_addr_low(r_i_io_tlb_resp_bits_s1_addr_low),
    .io_tlb_resp_bits_s1_ppn_low_0(r_i_io_tlb_resp_bits_s1_ppn_low_0),
    .io_tlb_resp_bits_s1_ppn_low_1(r_i_io_tlb_resp_bits_s1_ppn_low_1),
    .io_tlb_resp_bits_s1_ppn_low_2(r_i_io_tlb_resp_bits_s1_ppn_low_2),
    .io_tlb_resp_bits_s1_ppn_low_3(r_i_io_tlb_resp_bits_s1_ppn_low_3),
    .io_tlb_resp_bits_s1_ppn_low_4(r_i_io_tlb_resp_bits_s1_ppn_low_4),
    .io_tlb_resp_bits_s1_ppn_low_5(r_i_io_tlb_resp_bits_s1_ppn_low_5),
    .io_tlb_resp_bits_s1_ppn_low_6(r_i_io_tlb_resp_bits_s1_ppn_low_6),
    .io_tlb_resp_bits_s1_ppn_low_7(r_i_io_tlb_resp_bits_s1_ppn_low_7),
    .io_tlb_resp_bits_s1_valididx_0(r_i_io_tlb_resp_bits_s1_valididx_0),
    .io_tlb_resp_bits_s1_valididx_1(r_i_io_tlb_resp_bits_s1_valididx_1),
    .io_tlb_resp_bits_s1_valididx_2(r_i_io_tlb_resp_bits_s1_valididx_2),
    .io_tlb_resp_bits_s1_valididx_3(r_i_io_tlb_resp_bits_s1_valididx_3),
    .io_tlb_resp_bits_s1_valididx_4(r_i_io_tlb_resp_bits_s1_valididx_4),
    .io_tlb_resp_bits_s1_valididx_5(r_i_io_tlb_resp_bits_s1_valididx_5),
    .io_tlb_resp_bits_s1_valididx_6(r_i_io_tlb_resp_bits_s1_valididx_6),
    .io_tlb_resp_bits_s1_valididx_7(r_i_io_tlb_resp_bits_s1_valididx_7),
    .io_tlb_resp_bits_s1_pteidx_0(r_i_io_tlb_resp_bits_s1_pteidx_0),
    .io_tlb_resp_bits_s1_pteidx_1(r_i_io_tlb_resp_bits_s1_pteidx_1),
    .io_tlb_resp_bits_s1_pteidx_2(r_i_io_tlb_resp_bits_s1_pteidx_2),
    .io_tlb_resp_bits_s1_pteidx_3(r_i_io_tlb_resp_bits_s1_pteidx_3),
    .io_tlb_resp_bits_s1_pteidx_4(r_i_io_tlb_resp_bits_s1_pteidx_4),
    .io_tlb_resp_bits_s1_pteidx_5(r_i_io_tlb_resp_bits_s1_pteidx_5),
    .io_tlb_resp_bits_s1_pteidx_6(r_i_io_tlb_resp_bits_s1_pteidx_6),
    .io_tlb_resp_bits_s1_pteidx_7(r_i_io_tlb_resp_bits_s1_pteidx_7),
    .io_tlb_resp_bits_s1_pf(r_i_io_tlb_resp_bits_s1_pf),
    .io_tlb_resp_bits_s1_af(r_i_io_tlb_resp_bits_s1_af),
    .io_tlb_resp_bits_s2_entry_tag(r_i_io_tlb_resp_bits_s2_entry_tag),
    .io_tlb_resp_bits_s2_entry_vmid(r_i_io_tlb_resp_bits_s2_entry_vmid),
    .io_tlb_resp_bits_s2_entry_n(r_i_io_tlb_resp_bits_s2_entry_n),
    .io_tlb_resp_bits_s2_entry_pbmt(r_i_io_tlb_resp_bits_s2_entry_pbmt),
    .io_tlb_resp_bits_s2_entry_ppn(r_i_io_tlb_resp_bits_s2_entry_ppn),
    .io_tlb_resp_bits_s2_entry_perm_d(r_i_io_tlb_resp_bits_s2_entry_perm_d),
    .io_tlb_resp_bits_s2_entry_perm_a(r_i_io_tlb_resp_bits_s2_entry_perm_a),
    .io_tlb_resp_bits_s2_entry_perm_g(r_i_io_tlb_resp_bits_s2_entry_perm_g),
    .io_tlb_resp_bits_s2_entry_perm_u(r_i_io_tlb_resp_bits_s2_entry_perm_u),
    .io_tlb_resp_bits_s2_entry_perm_x(r_i_io_tlb_resp_bits_s2_entry_perm_x),
    .io_tlb_resp_bits_s2_entry_perm_w(r_i_io_tlb_resp_bits_s2_entry_perm_w),
    .io_tlb_resp_bits_s2_entry_perm_r(r_i_io_tlb_resp_bits_s2_entry_perm_r),
    .io_tlb_resp_bits_s2_entry_level(r_i_io_tlb_resp_bits_s2_entry_level),
    .io_tlb_resp_bits_s2_gpf(r_i_io_tlb_resp_bits_s2_gpf),
    .io_tlb_resp_bits_s2_gaf(r_i_io_tlb_resp_bits_s2_gaf),
    .io_ptw_req_0_ready(r_io_ptw_req_0_ready),
    .io_ptw_req_0_valid(r_i_io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn(r_i_io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate(r_i_io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_ready(r_i_io_ptw_resp_ready),
    .io_ptw_resp_valid(r_io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate(r_io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag(r_io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid(r_io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid(r_io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n(r_io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt(r_io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d(r_io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a(r_io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g(r_io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u(r_io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x(r_io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w(r_io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r(r_io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level(r_io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v(r_io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn(r_io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low(r_io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0(r_io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1(r_io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2(r_io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3(r_io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4(r_io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5(r_io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6(r_io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7(r_io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0(r_io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1(r_io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2(r_io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3(r_io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4(r_io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5(r_io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6(r_io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7(r_io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0(r_io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1(r_io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2(r_io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3(r_io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4(r_io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5(r_io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6(r_io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7(r_io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf(r_io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af(r_io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag(r_io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid(r_io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n(r_io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt(r_io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn(r_io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d(r_io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a(r_io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g(r_io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u(r_io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x(r_io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w(r_io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r(r_io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level(r_io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf(r_io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf(r_io_ptw_resp_bits_s2_gaf)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) r_mode = $urandom_range(0, 15);
      r_io_sfence_valid = 1'($urandom);
      r_io_csr_satp_changed = 1'($urandom);
      r_io_csr_vsatp_changed = 1'($urandom);
      r_io_csr_hgatp_changed = 1'($urandom);
      r_io_csr_priv_virt_changed = 1'($urandom);
      r_io_tlb_req_0_valid = 1'($urandom);
      r_io_tlb_req_0_bits_vpn = 38'({$urandom, $urandom});
      r_io_tlb_req_0_bits_s2xlate = 2'($urandom);
      r_io_tlb_resp_ready = 1'($urandom);
      r_io_ptw_req_0_ready = 1'($urandom);
      r_io_ptw_resp_valid = 1'($urandom);
      r_io_ptw_resp_bits_s2xlate = 2'($urandom);
      r_io_ptw_resp_bits_s1_entry_tag = 35'({$urandom, $urandom});
      r_io_ptw_resp_bits_s1_entry_asid = 16'($urandom);
      r_io_ptw_resp_bits_s1_entry_vmid = 14'($urandom);
      r_io_ptw_resp_bits_s1_entry_n = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_pbmt = 2'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_d = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_a = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_g = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_u = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_x = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_w = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_perm_r = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_level = 2'($urandom);
      r_io_ptw_resp_bits_s1_entry_v = 1'($urandom);
      r_io_ptw_resp_bits_s1_entry_ppn = 41'({$urandom, $urandom});
      r_io_ptw_resp_bits_s1_addr_low = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_0 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_1 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_2 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_3 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_4 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_5 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_6 = 3'($urandom);
      r_io_ptw_resp_bits_s1_ppn_low_7 = 3'($urandom);
      r_io_ptw_resp_bits_s1_valididx_0 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_1 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_2 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_3 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_4 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_5 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_6 = 1'($urandom);
      r_io_ptw_resp_bits_s1_valididx_7 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_0 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_1 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_2 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_3 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_4 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_5 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_6 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pteidx_7 = 1'($urandom);
      r_io_ptw_resp_bits_s1_pf = 1'($urandom);
      r_io_ptw_resp_bits_s1_af = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_tag = 38'({$urandom, $urandom});
      r_io_ptw_resp_bits_s2_entry_vmid = 14'($urandom);
      r_io_ptw_resp_bits_s2_entry_n = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_pbmt = 2'($urandom);
      r_io_ptw_resp_bits_s2_entry_ppn = 38'({$urandom, $urandom});
      r_io_ptw_resp_bits_s2_entry_perm_d = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_a = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_g = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_u = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_x = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_w = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_perm_r = 1'($urandom);
      r_io_ptw_resp_bits_s2_entry_level = 2'($urandom);
      r_io_ptw_resp_bits_s2_gpf = 1'($urandom);
      r_io_ptw_resp_bits_s2_gaf = 1'($urandom);
      r_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_r
        r_io_sfence_valid          = ($urandom_range(0, 63) == 0);
        r_io_csr_satp_changed      = ($urandom_range(0, 63) == 0);
        r_io_csr_vsatp_changed     = ($urandom_range(0, 63) == 0);
        r_io_csr_hgatp_changed     = ($urandom_range(0, 63) == 0);
        r_io_csr_priv_virt_changed = ($urandom_range(0, 63) == 0);
        if (r_mode >= 12) begin
          r_io_ptw_req_0_ready = ($urandom_range(0, 7) == 0);
          r_io_tlb_resp_ready  = ($urandom_range(0, 7) == 0);
        end
      end
      #4;
      r_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&r_armed)) begin
        checks++;
        if (r_g_io_tlb_req_0_ready !== r_i_io_tlb_req_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_req_0_ready g=%h i=%h", cyc, r_g_io_tlb_req_0_ready, r_i_io_tlb_req_0_ready);
        end
        r_s1_io_tlb_req_0_ready |= r_g_io_tlb_req_0_ready;
        r_s0_io_tlb_req_0_ready |= ~r_g_io_tlb_req_0_ready;
        checks++;
        if (r_g_io_tlb_resp_valid !== r_i_io_tlb_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_valid g=%h i=%h", cyc, r_g_io_tlb_resp_valid, r_i_io_tlb_resp_valid);
        end
        r_s1_io_tlb_resp_valid |= r_g_io_tlb_resp_valid;
        r_s0_io_tlb_resp_valid |= ~r_g_io_tlb_resp_valid;
        checks++;
        if (r_g_io_tlb_resp_bits_s2xlate !== r_i_io_tlb_resp_bits_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2xlate g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2xlate, r_i_io_tlb_resp_bits_s2xlate);
        end
        r_s1_io_tlb_resp_bits_s2xlate |= r_g_io_tlb_resp_bits_s2xlate;
        r_s0_io_tlb_resp_bits_s2xlate |= ~r_g_io_tlb_resp_bits_s2xlate;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_tag !== r_i_io_tlb_resp_bits_s1_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_tag, r_i_io_tlb_resp_bits_s1_entry_tag);
        end
        r_s1_io_tlb_resp_bits_s1_entry_tag |= r_g_io_tlb_resp_bits_s1_entry_tag;
        r_s0_io_tlb_resp_bits_s1_entry_tag |= ~r_g_io_tlb_resp_bits_s1_entry_tag;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_asid !== r_i_io_tlb_resp_bits_s1_entry_asid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_asid, r_i_io_tlb_resp_bits_s1_entry_asid);
        end
        r_s1_io_tlb_resp_bits_s1_entry_asid |= r_g_io_tlb_resp_bits_s1_entry_asid;
        r_s0_io_tlb_resp_bits_s1_entry_asid |= ~r_g_io_tlb_resp_bits_s1_entry_asid;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_vmid !== r_i_io_tlb_resp_bits_s1_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_vmid, r_i_io_tlb_resp_bits_s1_entry_vmid);
        end
        r_s1_io_tlb_resp_bits_s1_entry_vmid |= r_g_io_tlb_resp_bits_s1_entry_vmid;
        r_s0_io_tlb_resp_bits_s1_entry_vmid |= ~r_g_io_tlb_resp_bits_s1_entry_vmid;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_n !== r_i_io_tlb_resp_bits_s1_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_n g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_n, r_i_io_tlb_resp_bits_s1_entry_n);
        end
        r_s1_io_tlb_resp_bits_s1_entry_n |= r_g_io_tlb_resp_bits_s1_entry_n;
        r_s0_io_tlb_resp_bits_s1_entry_n |= ~r_g_io_tlb_resp_bits_s1_entry_n;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_pbmt !== r_i_io_tlb_resp_bits_s1_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_pbmt g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_pbmt, r_i_io_tlb_resp_bits_s1_entry_pbmt);
        end
        r_s1_io_tlb_resp_bits_s1_entry_pbmt |= r_g_io_tlb_resp_bits_s1_entry_pbmt;
        r_s0_io_tlb_resp_bits_s1_entry_pbmt |= ~r_g_io_tlb_resp_bits_s1_entry_pbmt;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_d !== r_i_io_tlb_resp_bits_s1_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_d g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_d, r_i_io_tlb_resp_bits_s1_entry_perm_d);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_d |= r_g_io_tlb_resp_bits_s1_entry_perm_d;
        r_s0_io_tlb_resp_bits_s1_entry_perm_d |= ~r_g_io_tlb_resp_bits_s1_entry_perm_d;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_a !== r_i_io_tlb_resp_bits_s1_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_a g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_a, r_i_io_tlb_resp_bits_s1_entry_perm_a);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_a |= r_g_io_tlb_resp_bits_s1_entry_perm_a;
        r_s0_io_tlb_resp_bits_s1_entry_perm_a |= ~r_g_io_tlb_resp_bits_s1_entry_perm_a;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_g !== r_i_io_tlb_resp_bits_s1_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_g g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_g, r_i_io_tlb_resp_bits_s1_entry_perm_g);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_g |= r_g_io_tlb_resp_bits_s1_entry_perm_g;
        r_s0_io_tlb_resp_bits_s1_entry_perm_g |= ~r_g_io_tlb_resp_bits_s1_entry_perm_g;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_u !== r_i_io_tlb_resp_bits_s1_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_u g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_u, r_i_io_tlb_resp_bits_s1_entry_perm_u);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_u |= r_g_io_tlb_resp_bits_s1_entry_perm_u;
        r_s0_io_tlb_resp_bits_s1_entry_perm_u |= ~r_g_io_tlb_resp_bits_s1_entry_perm_u;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_x !== r_i_io_tlb_resp_bits_s1_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_x g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_x, r_i_io_tlb_resp_bits_s1_entry_perm_x);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_x |= r_g_io_tlb_resp_bits_s1_entry_perm_x;
        r_s0_io_tlb_resp_bits_s1_entry_perm_x |= ~r_g_io_tlb_resp_bits_s1_entry_perm_x;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_w !== r_i_io_tlb_resp_bits_s1_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_w g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_w, r_i_io_tlb_resp_bits_s1_entry_perm_w);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_w |= r_g_io_tlb_resp_bits_s1_entry_perm_w;
        r_s0_io_tlb_resp_bits_s1_entry_perm_w |= ~r_g_io_tlb_resp_bits_s1_entry_perm_w;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_perm_r !== r_i_io_tlb_resp_bits_s1_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_r g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_perm_r, r_i_io_tlb_resp_bits_s1_entry_perm_r);
        end
        r_s1_io_tlb_resp_bits_s1_entry_perm_r |= r_g_io_tlb_resp_bits_s1_entry_perm_r;
        r_s0_io_tlb_resp_bits_s1_entry_perm_r |= ~r_g_io_tlb_resp_bits_s1_entry_perm_r;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_level !== r_i_io_tlb_resp_bits_s1_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_level g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_level, r_i_io_tlb_resp_bits_s1_entry_level);
        end
        r_s1_io_tlb_resp_bits_s1_entry_level |= r_g_io_tlb_resp_bits_s1_entry_level;
        r_s0_io_tlb_resp_bits_s1_entry_level |= ~r_g_io_tlb_resp_bits_s1_entry_level;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_v !== r_i_io_tlb_resp_bits_s1_entry_v) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_v g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_v, r_i_io_tlb_resp_bits_s1_entry_v);
        end
        r_s1_io_tlb_resp_bits_s1_entry_v |= r_g_io_tlb_resp_bits_s1_entry_v;
        r_s0_io_tlb_resp_bits_s1_entry_v |= ~r_g_io_tlb_resp_bits_s1_entry_v;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_entry_ppn !== r_i_io_tlb_resp_bits_s1_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_entry_ppn, r_i_io_tlb_resp_bits_s1_entry_ppn);
        end
        r_s1_io_tlb_resp_bits_s1_entry_ppn |= r_g_io_tlb_resp_bits_s1_entry_ppn;
        r_s0_io_tlb_resp_bits_s1_entry_ppn |= ~r_g_io_tlb_resp_bits_s1_entry_ppn;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_addr_low !== r_i_io_tlb_resp_bits_s1_addr_low) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_addr_low g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_addr_low, r_i_io_tlb_resp_bits_s1_addr_low);
        end
        r_s1_io_tlb_resp_bits_s1_addr_low |= r_g_io_tlb_resp_bits_s1_addr_low;
        r_s0_io_tlb_resp_bits_s1_addr_low |= ~r_g_io_tlb_resp_bits_s1_addr_low;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_0 !== r_i_io_tlb_resp_bits_s1_ppn_low_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_0 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_0, r_i_io_tlb_resp_bits_s1_ppn_low_0);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_0 |= r_g_io_tlb_resp_bits_s1_ppn_low_0;
        r_s0_io_tlb_resp_bits_s1_ppn_low_0 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_0;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_1 !== r_i_io_tlb_resp_bits_s1_ppn_low_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_1 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_1, r_i_io_tlb_resp_bits_s1_ppn_low_1);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_1 |= r_g_io_tlb_resp_bits_s1_ppn_low_1;
        r_s0_io_tlb_resp_bits_s1_ppn_low_1 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_1;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_2 !== r_i_io_tlb_resp_bits_s1_ppn_low_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_2 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_2, r_i_io_tlb_resp_bits_s1_ppn_low_2);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_2 |= r_g_io_tlb_resp_bits_s1_ppn_low_2;
        r_s0_io_tlb_resp_bits_s1_ppn_low_2 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_2;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_3 !== r_i_io_tlb_resp_bits_s1_ppn_low_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_3 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_3, r_i_io_tlb_resp_bits_s1_ppn_low_3);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_3 |= r_g_io_tlb_resp_bits_s1_ppn_low_3;
        r_s0_io_tlb_resp_bits_s1_ppn_low_3 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_3;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_4 !== r_i_io_tlb_resp_bits_s1_ppn_low_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_4 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_4, r_i_io_tlb_resp_bits_s1_ppn_low_4);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_4 |= r_g_io_tlb_resp_bits_s1_ppn_low_4;
        r_s0_io_tlb_resp_bits_s1_ppn_low_4 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_4;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_5 !== r_i_io_tlb_resp_bits_s1_ppn_low_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_5 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_5, r_i_io_tlb_resp_bits_s1_ppn_low_5);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_5 |= r_g_io_tlb_resp_bits_s1_ppn_low_5;
        r_s0_io_tlb_resp_bits_s1_ppn_low_5 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_5;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_6 !== r_i_io_tlb_resp_bits_s1_ppn_low_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_6 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_6, r_i_io_tlb_resp_bits_s1_ppn_low_6);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_6 |= r_g_io_tlb_resp_bits_s1_ppn_low_6;
        r_s0_io_tlb_resp_bits_s1_ppn_low_6 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_6;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_ppn_low_7 !== r_i_io_tlb_resp_bits_s1_ppn_low_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_7 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_ppn_low_7, r_i_io_tlb_resp_bits_s1_ppn_low_7);
        end
        r_s1_io_tlb_resp_bits_s1_ppn_low_7 |= r_g_io_tlb_resp_bits_s1_ppn_low_7;
        r_s0_io_tlb_resp_bits_s1_ppn_low_7 |= ~r_g_io_tlb_resp_bits_s1_ppn_low_7;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_0 !== r_i_io_tlb_resp_bits_s1_valididx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_0 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_0, r_i_io_tlb_resp_bits_s1_valididx_0);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_0 |= r_g_io_tlb_resp_bits_s1_valididx_0;
        r_s0_io_tlb_resp_bits_s1_valididx_0 |= ~r_g_io_tlb_resp_bits_s1_valididx_0;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_1 !== r_i_io_tlb_resp_bits_s1_valididx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_1 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_1, r_i_io_tlb_resp_bits_s1_valididx_1);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_1 |= r_g_io_tlb_resp_bits_s1_valididx_1;
        r_s0_io_tlb_resp_bits_s1_valididx_1 |= ~r_g_io_tlb_resp_bits_s1_valididx_1;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_2 !== r_i_io_tlb_resp_bits_s1_valididx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_2 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_2, r_i_io_tlb_resp_bits_s1_valididx_2);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_2 |= r_g_io_tlb_resp_bits_s1_valididx_2;
        r_s0_io_tlb_resp_bits_s1_valididx_2 |= ~r_g_io_tlb_resp_bits_s1_valididx_2;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_3 !== r_i_io_tlb_resp_bits_s1_valididx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_3 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_3, r_i_io_tlb_resp_bits_s1_valididx_3);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_3 |= r_g_io_tlb_resp_bits_s1_valididx_3;
        r_s0_io_tlb_resp_bits_s1_valididx_3 |= ~r_g_io_tlb_resp_bits_s1_valididx_3;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_4 !== r_i_io_tlb_resp_bits_s1_valididx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_4 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_4, r_i_io_tlb_resp_bits_s1_valididx_4);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_4 |= r_g_io_tlb_resp_bits_s1_valididx_4;
        r_s0_io_tlb_resp_bits_s1_valididx_4 |= ~r_g_io_tlb_resp_bits_s1_valididx_4;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_5 !== r_i_io_tlb_resp_bits_s1_valididx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_5 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_5, r_i_io_tlb_resp_bits_s1_valididx_5);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_5 |= r_g_io_tlb_resp_bits_s1_valididx_5;
        r_s0_io_tlb_resp_bits_s1_valididx_5 |= ~r_g_io_tlb_resp_bits_s1_valididx_5;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_6 !== r_i_io_tlb_resp_bits_s1_valididx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_6 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_6, r_i_io_tlb_resp_bits_s1_valididx_6);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_6 |= r_g_io_tlb_resp_bits_s1_valididx_6;
        r_s0_io_tlb_resp_bits_s1_valididx_6 |= ~r_g_io_tlb_resp_bits_s1_valididx_6;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_valididx_7 !== r_i_io_tlb_resp_bits_s1_valididx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_7 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_valididx_7, r_i_io_tlb_resp_bits_s1_valididx_7);
        end
        r_s1_io_tlb_resp_bits_s1_valididx_7 |= r_g_io_tlb_resp_bits_s1_valididx_7;
        r_s0_io_tlb_resp_bits_s1_valididx_7 |= ~r_g_io_tlb_resp_bits_s1_valididx_7;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_0 !== r_i_io_tlb_resp_bits_s1_pteidx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_0 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_0, r_i_io_tlb_resp_bits_s1_pteidx_0);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_0 |= r_g_io_tlb_resp_bits_s1_pteidx_0;
        r_s0_io_tlb_resp_bits_s1_pteidx_0 |= ~r_g_io_tlb_resp_bits_s1_pteidx_0;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_1 !== r_i_io_tlb_resp_bits_s1_pteidx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_1 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_1, r_i_io_tlb_resp_bits_s1_pteidx_1);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_1 |= r_g_io_tlb_resp_bits_s1_pteidx_1;
        r_s0_io_tlb_resp_bits_s1_pteidx_1 |= ~r_g_io_tlb_resp_bits_s1_pteidx_1;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_2 !== r_i_io_tlb_resp_bits_s1_pteidx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_2 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_2, r_i_io_tlb_resp_bits_s1_pteidx_2);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_2 |= r_g_io_tlb_resp_bits_s1_pteidx_2;
        r_s0_io_tlb_resp_bits_s1_pteidx_2 |= ~r_g_io_tlb_resp_bits_s1_pteidx_2;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_3 !== r_i_io_tlb_resp_bits_s1_pteidx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_3 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_3, r_i_io_tlb_resp_bits_s1_pteidx_3);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_3 |= r_g_io_tlb_resp_bits_s1_pteidx_3;
        r_s0_io_tlb_resp_bits_s1_pteidx_3 |= ~r_g_io_tlb_resp_bits_s1_pteidx_3;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_4 !== r_i_io_tlb_resp_bits_s1_pteidx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_4 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_4, r_i_io_tlb_resp_bits_s1_pteidx_4);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_4 |= r_g_io_tlb_resp_bits_s1_pteidx_4;
        r_s0_io_tlb_resp_bits_s1_pteidx_4 |= ~r_g_io_tlb_resp_bits_s1_pteidx_4;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_5 !== r_i_io_tlb_resp_bits_s1_pteidx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_5 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_5, r_i_io_tlb_resp_bits_s1_pteidx_5);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_5 |= r_g_io_tlb_resp_bits_s1_pteidx_5;
        r_s0_io_tlb_resp_bits_s1_pteidx_5 |= ~r_g_io_tlb_resp_bits_s1_pteidx_5;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_6 !== r_i_io_tlb_resp_bits_s1_pteidx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_6 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_6, r_i_io_tlb_resp_bits_s1_pteidx_6);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_6 |= r_g_io_tlb_resp_bits_s1_pteidx_6;
        r_s0_io_tlb_resp_bits_s1_pteidx_6 |= ~r_g_io_tlb_resp_bits_s1_pteidx_6;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pteidx_7 !== r_i_io_tlb_resp_bits_s1_pteidx_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_7 g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pteidx_7, r_i_io_tlb_resp_bits_s1_pteidx_7);
        end
        r_s1_io_tlb_resp_bits_s1_pteidx_7 |= r_g_io_tlb_resp_bits_s1_pteidx_7;
        r_s0_io_tlb_resp_bits_s1_pteidx_7 |= ~r_g_io_tlb_resp_bits_s1_pteidx_7;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_pf !== r_i_io_tlb_resp_bits_s1_pf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_pf g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_pf, r_i_io_tlb_resp_bits_s1_pf);
        end
        r_s1_io_tlb_resp_bits_s1_pf |= r_g_io_tlb_resp_bits_s1_pf;
        r_s0_io_tlb_resp_bits_s1_pf |= ~r_g_io_tlb_resp_bits_s1_pf;
        checks++;
        if (r_g_io_tlb_resp_bits_s1_af !== r_i_io_tlb_resp_bits_s1_af) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s1_af g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s1_af, r_i_io_tlb_resp_bits_s1_af);
        end
        r_s1_io_tlb_resp_bits_s1_af |= r_g_io_tlb_resp_bits_s1_af;
        r_s0_io_tlb_resp_bits_s1_af |= ~r_g_io_tlb_resp_bits_s1_af;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_tag !== r_i_io_tlb_resp_bits_s2_entry_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_tag, r_i_io_tlb_resp_bits_s2_entry_tag);
        end
        r_s1_io_tlb_resp_bits_s2_entry_tag |= r_g_io_tlb_resp_bits_s2_entry_tag;
        r_s0_io_tlb_resp_bits_s2_entry_tag |= ~r_g_io_tlb_resp_bits_s2_entry_tag;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_vmid !== r_i_io_tlb_resp_bits_s2_entry_vmid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_vmid, r_i_io_tlb_resp_bits_s2_entry_vmid);
        end
        r_s1_io_tlb_resp_bits_s2_entry_vmid |= r_g_io_tlb_resp_bits_s2_entry_vmid;
        r_s0_io_tlb_resp_bits_s2_entry_vmid |= ~r_g_io_tlb_resp_bits_s2_entry_vmid;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_n !== r_i_io_tlb_resp_bits_s2_entry_n) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_n g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_n, r_i_io_tlb_resp_bits_s2_entry_n);
        end
        r_s1_io_tlb_resp_bits_s2_entry_n |= r_g_io_tlb_resp_bits_s2_entry_n;
        r_s0_io_tlb_resp_bits_s2_entry_n |= ~r_g_io_tlb_resp_bits_s2_entry_n;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_pbmt !== r_i_io_tlb_resp_bits_s2_entry_pbmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_pbmt g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_pbmt, r_i_io_tlb_resp_bits_s2_entry_pbmt);
        end
        r_s1_io_tlb_resp_bits_s2_entry_pbmt |= r_g_io_tlb_resp_bits_s2_entry_pbmt;
        r_s0_io_tlb_resp_bits_s2_entry_pbmt |= ~r_g_io_tlb_resp_bits_s2_entry_pbmt;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_ppn !== r_i_io_tlb_resp_bits_s2_entry_ppn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_ppn, r_i_io_tlb_resp_bits_s2_entry_ppn);
        end
        r_s1_io_tlb_resp_bits_s2_entry_ppn |= r_g_io_tlb_resp_bits_s2_entry_ppn;
        r_s0_io_tlb_resp_bits_s2_entry_ppn |= ~r_g_io_tlb_resp_bits_s2_entry_ppn;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_d !== r_i_io_tlb_resp_bits_s2_entry_perm_d) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_d g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_d, r_i_io_tlb_resp_bits_s2_entry_perm_d);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_d |= r_g_io_tlb_resp_bits_s2_entry_perm_d;
        r_s0_io_tlb_resp_bits_s2_entry_perm_d |= ~r_g_io_tlb_resp_bits_s2_entry_perm_d;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_a !== r_i_io_tlb_resp_bits_s2_entry_perm_a) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_a g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_a, r_i_io_tlb_resp_bits_s2_entry_perm_a);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_a |= r_g_io_tlb_resp_bits_s2_entry_perm_a;
        r_s0_io_tlb_resp_bits_s2_entry_perm_a |= ~r_g_io_tlb_resp_bits_s2_entry_perm_a;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_g !== r_i_io_tlb_resp_bits_s2_entry_perm_g) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_g g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_g, r_i_io_tlb_resp_bits_s2_entry_perm_g);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_g |= r_g_io_tlb_resp_bits_s2_entry_perm_g;
        r_s0_io_tlb_resp_bits_s2_entry_perm_g |= ~r_g_io_tlb_resp_bits_s2_entry_perm_g;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_u !== r_i_io_tlb_resp_bits_s2_entry_perm_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_u g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_u, r_i_io_tlb_resp_bits_s2_entry_perm_u);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_u |= r_g_io_tlb_resp_bits_s2_entry_perm_u;
        r_s0_io_tlb_resp_bits_s2_entry_perm_u |= ~r_g_io_tlb_resp_bits_s2_entry_perm_u;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_x !== r_i_io_tlb_resp_bits_s2_entry_perm_x) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_x g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_x, r_i_io_tlb_resp_bits_s2_entry_perm_x);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_x |= r_g_io_tlb_resp_bits_s2_entry_perm_x;
        r_s0_io_tlb_resp_bits_s2_entry_perm_x |= ~r_g_io_tlb_resp_bits_s2_entry_perm_x;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_w !== r_i_io_tlb_resp_bits_s2_entry_perm_w) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_w g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_w, r_i_io_tlb_resp_bits_s2_entry_perm_w);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_w |= r_g_io_tlb_resp_bits_s2_entry_perm_w;
        r_s0_io_tlb_resp_bits_s2_entry_perm_w |= ~r_g_io_tlb_resp_bits_s2_entry_perm_w;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_perm_r !== r_i_io_tlb_resp_bits_s2_entry_perm_r) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_r g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_perm_r, r_i_io_tlb_resp_bits_s2_entry_perm_r);
        end
        r_s1_io_tlb_resp_bits_s2_entry_perm_r |= r_g_io_tlb_resp_bits_s2_entry_perm_r;
        r_s0_io_tlb_resp_bits_s2_entry_perm_r |= ~r_g_io_tlb_resp_bits_s2_entry_perm_r;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_entry_level !== r_i_io_tlb_resp_bits_s2_entry_level) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_entry_level g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_entry_level, r_i_io_tlb_resp_bits_s2_entry_level);
        end
        r_s1_io_tlb_resp_bits_s2_entry_level |= r_g_io_tlb_resp_bits_s2_entry_level;
        r_s0_io_tlb_resp_bits_s2_entry_level |= ~r_g_io_tlb_resp_bits_s2_entry_level;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_gpf !== r_i_io_tlb_resp_bits_s2_gpf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_gpf g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_gpf, r_i_io_tlb_resp_bits_s2_gpf);
        end
        r_s1_io_tlb_resp_bits_s2_gpf |= r_g_io_tlb_resp_bits_s2_gpf;
        r_s0_io_tlb_resp_bits_s2_gpf |= ~r_g_io_tlb_resp_bits_s2_gpf;
        checks++;
        if (r_g_io_tlb_resp_bits_s2_gaf !== r_i_io_tlb_resp_bits_s2_gaf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_tlb_resp_bits_s2_gaf g=%h i=%h", cyc, r_g_io_tlb_resp_bits_s2_gaf, r_i_io_tlb_resp_bits_s2_gaf);
        end
        r_s1_io_tlb_resp_bits_s2_gaf |= r_g_io_tlb_resp_bits_s2_gaf;
        r_s0_io_tlb_resp_bits_s2_gaf |= ~r_g_io_tlb_resp_bits_s2_gaf;
        checks++;
        if (r_g_io_ptw_req_0_valid !== r_i_io_ptw_req_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_ptw_req_0_valid g=%h i=%h", cyc, r_g_io_ptw_req_0_valid, r_i_io_ptw_req_0_valid);
        end
        r_s1_io_ptw_req_0_valid |= r_g_io_ptw_req_0_valid;
        r_s0_io_ptw_req_0_valid |= ~r_g_io_ptw_req_0_valid;
        checks++;
        if (r_g_io_ptw_req_0_bits_vpn !== r_i_io_ptw_req_0_bits_vpn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_ptw_req_0_bits_vpn g=%h i=%h", cyc, r_g_io_ptw_req_0_bits_vpn, r_i_io_ptw_req_0_bits_vpn);
        end
        r_s1_io_ptw_req_0_bits_vpn |= r_g_io_ptw_req_0_bits_vpn;
        r_s0_io_ptw_req_0_bits_vpn |= ~r_g_io_ptw_req_0_bits_vpn;
        checks++;
        if (r_g_io_ptw_req_0_bits_s2xlate !== r_i_io_ptw_req_0_bits_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_ptw_req_0_bits_s2xlate g=%h i=%h", cyc, r_g_io_ptw_req_0_bits_s2xlate, r_i_io_ptw_req_0_bits_s2xlate);
        end
        r_s1_io_ptw_req_0_bits_s2xlate |= r_g_io_ptw_req_0_bits_s2xlate;
        r_s0_io_ptw_req_0_bits_s2xlate |= ~r_g_io_ptw_req_0_bits_s2xlate;
        checks++;
        if (r_g_io_ptw_resp_ready !== r_i_io_ptw_resp_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PTWRepeaterNB.io_ptw_resp_ready g=%h i=%h", cyc, r_g_io_ptw_resp_ready, r_i_io_ptw_resp_ready);
        end
        r_s1_io_ptw_resp_ready |= r_g_io_ptw_resp_ready;
        r_s0_io_ptw_resp_ready |= ~r_g_io_ptw_resp_ready;
        if (r_io_tlb_req_0_valid && r_g_io_tlb_req_0_ready) r_cov_req_fire++;
        if (r_g_io_ptw_req_0_valid && r_io_ptw_req_0_ready) r_cov_req_sent++;
        if (r_io_ptw_resp_valid && r_g_io_ptw_resp_ready) r_cov_resp_recv++;
        if (r_g_io_tlb_resp_valid && r_io_tlb_resp_ready) r_cov_resp_out++;
        if (r_u_gold._delay_io_out && r_u_gold.sent) r_cov_flush_sent++;
        if (r_u_gold._delay_io_out && r_u_gold.recv) r_cov_flush_recv++;
        if (r_u_gold.sent && r_u_gold.recv) r_cov_sent_and_recv++;
      end
      if (r_armed_at < 0 && (&r_armed)) r_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(r_s0_io_tlb_req_0_ready && r_s1_io_tlb_req_0_ready)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_req_0_ready 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_valid && r_s1_io_tlb_resp_valid)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_valid 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2xlate[0] && r_s1_io_tlb_resp_bits_s2xlate[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2xlate[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2xlate[1] && r_s1_io_tlb_resp_bits_s2xlate[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2xlate[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[0] && r_s1_io_tlb_resp_bits_s1_entry_tag[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[1] && r_s1_io_tlb_resp_bits_s1_entry_tag[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[2] && r_s1_io_tlb_resp_bits_s1_entry_tag[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[3] && r_s1_io_tlb_resp_bits_s1_entry_tag[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[4] && r_s1_io_tlb_resp_bits_s1_entry_tag[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[5] && r_s1_io_tlb_resp_bits_s1_entry_tag[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[6] && r_s1_io_tlb_resp_bits_s1_entry_tag[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[7] && r_s1_io_tlb_resp_bits_s1_entry_tag[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[8] && r_s1_io_tlb_resp_bits_s1_entry_tag[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[9] && r_s1_io_tlb_resp_bits_s1_entry_tag[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[10] && r_s1_io_tlb_resp_bits_s1_entry_tag[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[11] && r_s1_io_tlb_resp_bits_s1_entry_tag[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[12] && r_s1_io_tlb_resp_bits_s1_entry_tag[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[13] && r_s1_io_tlb_resp_bits_s1_entry_tag[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[14] && r_s1_io_tlb_resp_bits_s1_entry_tag[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[14] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[15] && r_s1_io_tlb_resp_bits_s1_entry_tag[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[15] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[16] && r_s1_io_tlb_resp_bits_s1_entry_tag[16])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[16] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[17] && r_s1_io_tlb_resp_bits_s1_entry_tag[17])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[17] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[18] && r_s1_io_tlb_resp_bits_s1_entry_tag[18])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[18] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[19] && r_s1_io_tlb_resp_bits_s1_entry_tag[19])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[19] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[20] && r_s1_io_tlb_resp_bits_s1_entry_tag[20])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[20] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[21] && r_s1_io_tlb_resp_bits_s1_entry_tag[21])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[21] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[22] && r_s1_io_tlb_resp_bits_s1_entry_tag[22])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[22] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[23] && r_s1_io_tlb_resp_bits_s1_entry_tag[23])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[23] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[24] && r_s1_io_tlb_resp_bits_s1_entry_tag[24])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[24] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[25] && r_s1_io_tlb_resp_bits_s1_entry_tag[25])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[25] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[26] && r_s1_io_tlb_resp_bits_s1_entry_tag[26])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[26] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[27] && r_s1_io_tlb_resp_bits_s1_entry_tag[27])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[27] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[28] && r_s1_io_tlb_resp_bits_s1_entry_tag[28])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[28] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[29] && r_s1_io_tlb_resp_bits_s1_entry_tag[29])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[29] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[30] && r_s1_io_tlb_resp_bits_s1_entry_tag[30])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[30] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[31] && r_s1_io_tlb_resp_bits_s1_entry_tag[31])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[31] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[32] && r_s1_io_tlb_resp_bits_s1_entry_tag[32])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[32] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[33] && r_s1_io_tlb_resp_bits_s1_entry_tag[33])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[33] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_tag[34] && r_s1_io_tlb_resp_bits_s1_entry_tag[34])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_tag[34] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[0] && r_s1_io_tlb_resp_bits_s1_entry_asid[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[1] && r_s1_io_tlb_resp_bits_s1_entry_asid[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[2] && r_s1_io_tlb_resp_bits_s1_entry_asid[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[3] && r_s1_io_tlb_resp_bits_s1_entry_asid[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[4] && r_s1_io_tlb_resp_bits_s1_entry_asid[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[5] && r_s1_io_tlb_resp_bits_s1_entry_asid[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[6] && r_s1_io_tlb_resp_bits_s1_entry_asid[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[7] && r_s1_io_tlb_resp_bits_s1_entry_asid[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[8] && r_s1_io_tlb_resp_bits_s1_entry_asid[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[9] && r_s1_io_tlb_resp_bits_s1_entry_asid[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[10] && r_s1_io_tlb_resp_bits_s1_entry_asid[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[11] && r_s1_io_tlb_resp_bits_s1_entry_asid[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[12] && r_s1_io_tlb_resp_bits_s1_entry_asid[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[13] && r_s1_io_tlb_resp_bits_s1_entry_asid[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[14] && r_s1_io_tlb_resp_bits_s1_entry_asid[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[14] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_asid[15] && r_s1_io_tlb_resp_bits_s1_entry_asid[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_asid[15] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[0] && r_s1_io_tlb_resp_bits_s1_entry_vmid[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[1] && r_s1_io_tlb_resp_bits_s1_entry_vmid[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[2] && r_s1_io_tlb_resp_bits_s1_entry_vmid[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[3] && r_s1_io_tlb_resp_bits_s1_entry_vmid[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[4] && r_s1_io_tlb_resp_bits_s1_entry_vmid[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[5] && r_s1_io_tlb_resp_bits_s1_entry_vmid[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[6] && r_s1_io_tlb_resp_bits_s1_entry_vmid[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[7] && r_s1_io_tlb_resp_bits_s1_entry_vmid[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[8] && r_s1_io_tlb_resp_bits_s1_entry_vmid[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[9] && r_s1_io_tlb_resp_bits_s1_entry_vmid[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[10] && r_s1_io_tlb_resp_bits_s1_entry_vmid[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[11] && r_s1_io_tlb_resp_bits_s1_entry_vmid[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[12] && r_s1_io_tlb_resp_bits_s1_entry_vmid[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_vmid[13] && r_s1_io_tlb_resp_bits_s1_entry_vmid[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_vmid[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_n && r_s1_io_tlb_resp_bits_s1_entry_n)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_n 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_pbmt[0] && r_s1_io_tlb_resp_bits_s1_entry_pbmt[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_pbmt[1] && r_s1_io_tlb_resp_bits_s1_entry_pbmt[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_d && r_s1_io_tlb_resp_bits_s1_entry_perm_d)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_d 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_a && r_s1_io_tlb_resp_bits_s1_entry_perm_a)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_a 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_g && r_s1_io_tlb_resp_bits_s1_entry_perm_g)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_g 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_u && r_s1_io_tlb_resp_bits_s1_entry_perm_u)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_u 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_x && r_s1_io_tlb_resp_bits_s1_entry_perm_x)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_x 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_w && r_s1_io_tlb_resp_bits_s1_entry_perm_w)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_w 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_perm_r && r_s1_io_tlb_resp_bits_s1_entry_perm_r)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_perm_r 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_level[0] && r_s1_io_tlb_resp_bits_s1_entry_level[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_level[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_level[1] && r_s1_io_tlb_resp_bits_s1_entry_level[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_level[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_v && r_s1_io_tlb_resp_bits_s1_entry_v)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_v 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[0] && r_s1_io_tlb_resp_bits_s1_entry_ppn[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[1] && r_s1_io_tlb_resp_bits_s1_entry_ppn[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[2] && r_s1_io_tlb_resp_bits_s1_entry_ppn[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[3] && r_s1_io_tlb_resp_bits_s1_entry_ppn[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[4] && r_s1_io_tlb_resp_bits_s1_entry_ppn[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[5] && r_s1_io_tlb_resp_bits_s1_entry_ppn[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[6] && r_s1_io_tlb_resp_bits_s1_entry_ppn[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[7] && r_s1_io_tlb_resp_bits_s1_entry_ppn[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[8] && r_s1_io_tlb_resp_bits_s1_entry_ppn[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[9] && r_s1_io_tlb_resp_bits_s1_entry_ppn[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[10] && r_s1_io_tlb_resp_bits_s1_entry_ppn[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[11] && r_s1_io_tlb_resp_bits_s1_entry_ppn[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[12] && r_s1_io_tlb_resp_bits_s1_entry_ppn[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[13] && r_s1_io_tlb_resp_bits_s1_entry_ppn[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[14] && r_s1_io_tlb_resp_bits_s1_entry_ppn[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[14] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[15] && r_s1_io_tlb_resp_bits_s1_entry_ppn[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[15] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[16] && r_s1_io_tlb_resp_bits_s1_entry_ppn[16])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[16] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[17] && r_s1_io_tlb_resp_bits_s1_entry_ppn[17])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[17] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[18] && r_s1_io_tlb_resp_bits_s1_entry_ppn[18])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[18] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[19] && r_s1_io_tlb_resp_bits_s1_entry_ppn[19])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[19] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[20] && r_s1_io_tlb_resp_bits_s1_entry_ppn[20])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[20] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[21] && r_s1_io_tlb_resp_bits_s1_entry_ppn[21])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[21] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[22] && r_s1_io_tlb_resp_bits_s1_entry_ppn[22])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[22] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[23] && r_s1_io_tlb_resp_bits_s1_entry_ppn[23])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[23] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[24] && r_s1_io_tlb_resp_bits_s1_entry_ppn[24])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[24] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[25] && r_s1_io_tlb_resp_bits_s1_entry_ppn[25])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[25] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[26] && r_s1_io_tlb_resp_bits_s1_entry_ppn[26])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[26] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[27] && r_s1_io_tlb_resp_bits_s1_entry_ppn[27])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[27] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[28] && r_s1_io_tlb_resp_bits_s1_entry_ppn[28])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[28] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[29] && r_s1_io_tlb_resp_bits_s1_entry_ppn[29])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[29] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[30] && r_s1_io_tlb_resp_bits_s1_entry_ppn[30])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[30] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[31] && r_s1_io_tlb_resp_bits_s1_entry_ppn[31])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[31] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[32] && r_s1_io_tlb_resp_bits_s1_entry_ppn[32])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[32] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[33] && r_s1_io_tlb_resp_bits_s1_entry_ppn[33])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[33] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[34] && r_s1_io_tlb_resp_bits_s1_entry_ppn[34])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[34] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[35] && r_s1_io_tlb_resp_bits_s1_entry_ppn[35])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[35] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[36] && r_s1_io_tlb_resp_bits_s1_entry_ppn[36])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[36] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[37] && r_s1_io_tlb_resp_bits_s1_entry_ppn[37])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[37] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[38] && r_s1_io_tlb_resp_bits_s1_entry_ppn[38])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[38] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[39] && r_s1_io_tlb_resp_bits_s1_entry_ppn[39])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[39] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_entry_ppn[40] && r_s1_io_tlb_resp_bits_s1_entry_ppn[40])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_entry_ppn[40] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_addr_low[0] && r_s1_io_tlb_resp_bits_s1_addr_low[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_addr_low[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_addr_low[1] && r_s1_io_tlb_resp_bits_s1_addr_low[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_addr_low[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_addr_low[2] && r_s1_io_tlb_resp_bits_s1_addr_low[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_addr_low[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_0[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_0[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_0[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_0[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_0[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_0[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_1[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_1[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_1[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_1[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_1[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_1[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_2[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_2[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_2[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_2[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_2[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_2[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_2[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_2[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_2[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_3[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_3[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_3[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_3[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_3[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_3[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_3[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_3[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_3[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_4[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_4[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_4[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_4[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_4[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_4[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_4[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_4[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_4[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_5[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_5[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_5[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_5[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_5[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_5[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_5[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_5[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_5[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_6[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_6[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_6[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_6[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_6[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_6[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_6[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_6[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_6[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_7[0] && r_s1_io_tlb_resp_bits_s1_ppn_low_7[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_7[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_7[1] && r_s1_io_tlb_resp_bits_s1_ppn_low_7[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_7[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_ppn_low_7[2] && r_s1_io_tlb_resp_bits_s1_ppn_low_7[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_ppn_low_7[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_0 && r_s1_io_tlb_resp_bits_s1_valididx_0)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_0 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_1 && r_s1_io_tlb_resp_bits_s1_valididx_1)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_1 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_2 && r_s1_io_tlb_resp_bits_s1_valididx_2)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_2 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_3 && r_s1_io_tlb_resp_bits_s1_valididx_3)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_3 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_4 && r_s1_io_tlb_resp_bits_s1_valididx_4)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_4 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_5 && r_s1_io_tlb_resp_bits_s1_valididx_5)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_5 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_6 && r_s1_io_tlb_resp_bits_s1_valididx_6)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_6 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_valididx_7 && r_s1_io_tlb_resp_bits_s1_valididx_7)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_valididx_7 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_0 && r_s1_io_tlb_resp_bits_s1_pteidx_0)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_0 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_1 && r_s1_io_tlb_resp_bits_s1_pteidx_1)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_1 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_2 && r_s1_io_tlb_resp_bits_s1_pteidx_2)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_2 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_3 && r_s1_io_tlb_resp_bits_s1_pteidx_3)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_3 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_4 && r_s1_io_tlb_resp_bits_s1_pteidx_4)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_4 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_5 && r_s1_io_tlb_resp_bits_s1_pteidx_5)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_5 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_6 && r_s1_io_tlb_resp_bits_s1_pteidx_6)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_6 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pteidx_7 && r_s1_io_tlb_resp_bits_s1_pteidx_7)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pteidx_7 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_pf && r_s1_io_tlb_resp_bits_s1_pf)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_pf 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s1_af && r_s1_io_tlb_resp_bits_s1_af)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s1_af 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[0] && r_s1_io_tlb_resp_bits_s2_entry_tag[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[1] && r_s1_io_tlb_resp_bits_s2_entry_tag[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[2] && r_s1_io_tlb_resp_bits_s2_entry_tag[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[3] && r_s1_io_tlb_resp_bits_s2_entry_tag[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[4] && r_s1_io_tlb_resp_bits_s2_entry_tag[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[5] && r_s1_io_tlb_resp_bits_s2_entry_tag[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[6] && r_s1_io_tlb_resp_bits_s2_entry_tag[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[7] && r_s1_io_tlb_resp_bits_s2_entry_tag[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[8] && r_s1_io_tlb_resp_bits_s2_entry_tag[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[9] && r_s1_io_tlb_resp_bits_s2_entry_tag[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[10] && r_s1_io_tlb_resp_bits_s2_entry_tag[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[11] && r_s1_io_tlb_resp_bits_s2_entry_tag[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[12] && r_s1_io_tlb_resp_bits_s2_entry_tag[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[13] && r_s1_io_tlb_resp_bits_s2_entry_tag[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[14] && r_s1_io_tlb_resp_bits_s2_entry_tag[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[14] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[15] && r_s1_io_tlb_resp_bits_s2_entry_tag[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[15] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[16] && r_s1_io_tlb_resp_bits_s2_entry_tag[16])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[16] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[17] && r_s1_io_tlb_resp_bits_s2_entry_tag[17])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[17] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[18] && r_s1_io_tlb_resp_bits_s2_entry_tag[18])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[18] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[19] && r_s1_io_tlb_resp_bits_s2_entry_tag[19])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[19] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[20] && r_s1_io_tlb_resp_bits_s2_entry_tag[20])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[20] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[21] && r_s1_io_tlb_resp_bits_s2_entry_tag[21])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[21] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[22] && r_s1_io_tlb_resp_bits_s2_entry_tag[22])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[22] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[23] && r_s1_io_tlb_resp_bits_s2_entry_tag[23])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[23] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[24] && r_s1_io_tlb_resp_bits_s2_entry_tag[24])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[24] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[25] && r_s1_io_tlb_resp_bits_s2_entry_tag[25])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[25] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[26] && r_s1_io_tlb_resp_bits_s2_entry_tag[26])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[26] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[27] && r_s1_io_tlb_resp_bits_s2_entry_tag[27])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[27] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[28] && r_s1_io_tlb_resp_bits_s2_entry_tag[28])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[28] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[29] && r_s1_io_tlb_resp_bits_s2_entry_tag[29])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[29] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[30] && r_s1_io_tlb_resp_bits_s2_entry_tag[30])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[30] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[31] && r_s1_io_tlb_resp_bits_s2_entry_tag[31])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[31] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[32] && r_s1_io_tlb_resp_bits_s2_entry_tag[32])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[32] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[33] && r_s1_io_tlb_resp_bits_s2_entry_tag[33])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[33] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[34] && r_s1_io_tlb_resp_bits_s2_entry_tag[34])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[34] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[35] && r_s1_io_tlb_resp_bits_s2_entry_tag[35])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[35] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[36] && r_s1_io_tlb_resp_bits_s2_entry_tag[36])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[36] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_tag[37] && r_s1_io_tlb_resp_bits_s2_entry_tag[37])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_tag[37] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[0] && r_s1_io_tlb_resp_bits_s2_entry_vmid[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[1] && r_s1_io_tlb_resp_bits_s2_entry_vmid[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[2] && r_s1_io_tlb_resp_bits_s2_entry_vmid[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[3] && r_s1_io_tlb_resp_bits_s2_entry_vmid[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[4] && r_s1_io_tlb_resp_bits_s2_entry_vmid[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[5] && r_s1_io_tlb_resp_bits_s2_entry_vmid[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[6] && r_s1_io_tlb_resp_bits_s2_entry_vmid[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[7] && r_s1_io_tlb_resp_bits_s2_entry_vmid[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[8] && r_s1_io_tlb_resp_bits_s2_entry_vmid[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[9] && r_s1_io_tlb_resp_bits_s2_entry_vmid[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[10] && r_s1_io_tlb_resp_bits_s2_entry_vmid[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[11] && r_s1_io_tlb_resp_bits_s2_entry_vmid[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[12] && r_s1_io_tlb_resp_bits_s2_entry_vmid[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_vmid[13] && r_s1_io_tlb_resp_bits_s2_entry_vmid[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_vmid[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_n && r_s1_io_tlb_resp_bits_s2_entry_n)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_n 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_pbmt[0] && r_s1_io_tlb_resp_bits_s2_entry_pbmt[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_pbmt[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_pbmt[1] && r_s1_io_tlb_resp_bits_s2_entry_pbmt[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_pbmt[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[0] && r_s1_io_tlb_resp_bits_s2_entry_ppn[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[1] && r_s1_io_tlb_resp_bits_s2_entry_ppn[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[2] && r_s1_io_tlb_resp_bits_s2_entry_ppn[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[2] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[3] && r_s1_io_tlb_resp_bits_s2_entry_ppn[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[3] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[4] && r_s1_io_tlb_resp_bits_s2_entry_ppn[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[4] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[5] && r_s1_io_tlb_resp_bits_s2_entry_ppn[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[5] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[6] && r_s1_io_tlb_resp_bits_s2_entry_ppn[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[6] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[7] && r_s1_io_tlb_resp_bits_s2_entry_ppn[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[7] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[8] && r_s1_io_tlb_resp_bits_s2_entry_ppn[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[8] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[9] && r_s1_io_tlb_resp_bits_s2_entry_ppn[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[9] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[10] && r_s1_io_tlb_resp_bits_s2_entry_ppn[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[10] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[11] && r_s1_io_tlb_resp_bits_s2_entry_ppn[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[11] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[12] && r_s1_io_tlb_resp_bits_s2_entry_ppn[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[12] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[13] && r_s1_io_tlb_resp_bits_s2_entry_ppn[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[13] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[14] && r_s1_io_tlb_resp_bits_s2_entry_ppn[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[14] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[15] && r_s1_io_tlb_resp_bits_s2_entry_ppn[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[15] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[16] && r_s1_io_tlb_resp_bits_s2_entry_ppn[16])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[16] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[17] && r_s1_io_tlb_resp_bits_s2_entry_ppn[17])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[17] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[18] && r_s1_io_tlb_resp_bits_s2_entry_ppn[18])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[18] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[19] && r_s1_io_tlb_resp_bits_s2_entry_ppn[19])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[19] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[20] && r_s1_io_tlb_resp_bits_s2_entry_ppn[20])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[20] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[21] && r_s1_io_tlb_resp_bits_s2_entry_ppn[21])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[21] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[22] && r_s1_io_tlb_resp_bits_s2_entry_ppn[22])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[22] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[23] && r_s1_io_tlb_resp_bits_s2_entry_ppn[23])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[23] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[24] && r_s1_io_tlb_resp_bits_s2_entry_ppn[24])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[24] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[25] && r_s1_io_tlb_resp_bits_s2_entry_ppn[25])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[25] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[26] && r_s1_io_tlb_resp_bits_s2_entry_ppn[26])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[26] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[27] && r_s1_io_tlb_resp_bits_s2_entry_ppn[27])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[27] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[28] && r_s1_io_tlb_resp_bits_s2_entry_ppn[28])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[28] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[29] && r_s1_io_tlb_resp_bits_s2_entry_ppn[29])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[29] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[30] && r_s1_io_tlb_resp_bits_s2_entry_ppn[30])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[30] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[31] && r_s1_io_tlb_resp_bits_s2_entry_ppn[31])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[31] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[32] && r_s1_io_tlb_resp_bits_s2_entry_ppn[32])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[32] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[33] && r_s1_io_tlb_resp_bits_s2_entry_ppn[33])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[33] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[34] && r_s1_io_tlb_resp_bits_s2_entry_ppn[34])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[34] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[35] && r_s1_io_tlb_resp_bits_s2_entry_ppn[35])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[35] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[36] && r_s1_io_tlb_resp_bits_s2_entry_ppn[36])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[36] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_ppn[37] && r_s1_io_tlb_resp_bits_s2_entry_ppn[37])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_ppn[37] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_d && r_s1_io_tlb_resp_bits_s2_entry_perm_d)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_d 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_a && r_s1_io_tlb_resp_bits_s2_entry_perm_a)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_a 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_g && r_s1_io_tlb_resp_bits_s2_entry_perm_g)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_g 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_u && r_s1_io_tlb_resp_bits_s2_entry_perm_u)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_u 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_x && r_s1_io_tlb_resp_bits_s2_entry_perm_x)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_x 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_w && r_s1_io_tlb_resp_bits_s2_entry_perm_w)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_w 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_perm_r && r_s1_io_tlb_resp_bits_s2_entry_perm_r)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_perm_r 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_level[0] && r_s1_io_tlb_resp_bits_s2_entry_level[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_level[0] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_entry_level[1] && r_s1_io_tlb_resp_bits_s2_entry_level[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_entry_level[1] 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_gpf && r_s1_io_tlb_resp_bits_s2_gpf)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_gpf 未见过 0 和 1"); end
    if (!(r_s0_io_tlb_resp_bits_s2_gaf && r_s1_io_tlb_resp_bits_s2_gaf)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_tlb_resp_bits_s2_gaf 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_valid && r_s1_io_ptw_req_0_valid)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_valid 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[0] && r_s1_io_ptw_req_0_bits_vpn[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[0] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[1] && r_s1_io_ptw_req_0_bits_vpn[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[1] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[2] && r_s1_io_ptw_req_0_bits_vpn[2])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[2] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[3] && r_s1_io_ptw_req_0_bits_vpn[3])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[3] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[4] && r_s1_io_ptw_req_0_bits_vpn[4])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[4] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[5] && r_s1_io_ptw_req_0_bits_vpn[5])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[5] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[6] && r_s1_io_ptw_req_0_bits_vpn[6])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[6] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[7] && r_s1_io_ptw_req_0_bits_vpn[7])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[7] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[8] && r_s1_io_ptw_req_0_bits_vpn[8])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[8] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[9] && r_s1_io_ptw_req_0_bits_vpn[9])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[9] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[10] && r_s1_io_ptw_req_0_bits_vpn[10])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[10] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[11] && r_s1_io_ptw_req_0_bits_vpn[11])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[11] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[12] && r_s1_io_ptw_req_0_bits_vpn[12])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[12] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[13] && r_s1_io_ptw_req_0_bits_vpn[13])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[13] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[14] && r_s1_io_ptw_req_0_bits_vpn[14])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[14] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[15] && r_s1_io_ptw_req_0_bits_vpn[15])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[15] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[16] && r_s1_io_ptw_req_0_bits_vpn[16])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[16] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[17] && r_s1_io_ptw_req_0_bits_vpn[17])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[17] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[18] && r_s1_io_ptw_req_0_bits_vpn[18])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[18] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[19] && r_s1_io_ptw_req_0_bits_vpn[19])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[19] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[20] && r_s1_io_ptw_req_0_bits_vpn[20])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[20] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[21] && r_s1_io_ptw_req_0_bits_vpn[21])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[21] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[22] && r_s1_io_ptw_req_0_bits_vpn[22])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[22] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[23] && r_s1_io_ptw_req_0_bits_vpn[23])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[23] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[24] && r_s1_io_ptw_req_0_bits_vpn[24])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[24] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[25] && r_s1_io_ptw_req_0_bits_vpn[25])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[25] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[26] && r_s1_io_ptw_req_0_bits_vpn[26])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[26] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[27] && r_s1_io_ptw_req_0_bits_vpn[27])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[27] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[28] && r_s1_io_ptw_req_0_bits_vpn[28])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[28] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[29] && r_s1_io_ptw_req_0_bits_vpn[29])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[29] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[30] && r_s1_io_ptw_req_0_bits_vpn[30])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[30] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[31] && r_s1_io_ptw_req_0_bits_vpn[31])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[31] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[32] && r_s1_io_ptw_req_0_bits_vpn[32])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[32] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[33] && r_s1_io_ptw_req_0_bits_vpn[33])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[33] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[34] && r_s1_io_ptw_req_0_bits_vpn[34])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[34] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[35] && r_s1_io_ptw_req_0_bits_vpn[35])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[35] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[36] && r_s1_io_ptw_req_0_bits_vpn[36])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[36] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_vpn[37] && r_s1_io_ptw_req_0_bits_vpn[37])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_vpn[37] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_s2xlate[0] && r_s1_io_ptw_req_0_bits_s2xlate[0])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_s2xlate[0] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_req_0_bits_s2xlate[1] && r_s1_io_ptw_req_0_bits_s2xlate[1])) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_req_0_bits_s2xlate[1] 未见过 0 和 1"); end
    if (!(r_s0_io_ptw_resp_ready && r_s1_io_ptw_resp_ready)) begin cov_fail++; $display("[COV] PTWRepeaterNB.io_ptw_resp_ready 未见过 0 和 1"); end
    $display("[ARM] PTWRepeaterNB armed_at=%0d", r_armed_at);
    if (r_armed_at < 0) begin cov_fail++; $display("[ARM] PTWRepeaterNB 从未 arm"); end
    $display("[COV] PTWRepeaterNB.req_fire = %0d", r_cov_req_fire);
    if (r_cov_req_fire < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.req_fire < 200"); end
    $display("[COV] PTWRepeaterNB.req_sent = %0d", r_cov_req_sent);
    if (r_cov_req_sent < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.req_sent < 200"); end
    $display("[COV] PTWRepeaterNB.resp_recv = %0d", r_cov_resp_recv);
    if (r_cov_resp_recv < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.resp_recv < 200"); end
    $display("[COV] PTWRepeaterNB.resp_out = %0d", r_cov_resp_out);
    if (r_cov_resp_out < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.resp_out < 200"); end
    $display("[COV] PTWRepeaterNB.flush_sent = %0d", r_cov_flush_sent);
    if (r_cov_flush_sent < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.flush_sent < 200"); end
    $display("[COV] PTWRepeaterNB.flush_recv = %0d", r_cov_flush_recv);
    if (r_cov_flush_recv < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.flush_recv < 200"); end
    $display("[COV] PTWRepeaterNB.sent_and_recv = %0d", r_cov_sent_and_recv);
    if (r_cov_sent_and_recv < 200) begin cov_fail++; $display("[COV] PTWRepeaterNB.sent_and_recv < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
