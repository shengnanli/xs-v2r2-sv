// 自动生成：scripts/gen_ptwrepeaternb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst; int errors=0, checks=0;
  always #5 clk = ~clk;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic io_csr_hgatp_changed;
  logic io_tlb_req_0_valid;
  logic [37:0] io_tlb_req_0_bits_vpn;
  logic [1:0] io_tlb_req_0_bits_s2xlate;
  logic io_tlb_resp_ready;
  logic io_ptw_req_0_ready;
  logic io_ptw_resp_valid;
  logic [1:0] io_ptw_resp_bits_s2xlate;
  logic [34:0] io_ptw_resp_bits_s1_entry_tag;
  logic [15:0] io_ptw_resp_bits_s1_entry_asid;
  logic [13:0] io_ptw_resp_bits_s1_entry_vmid;
  logic io_ptw_resp_bits_s1_entry_n;
  logic [1:0] io_ptw_resp_bits_s1_entry_pbmt;
  logic io_ptw_resp_bits_s1_entry_perm_d;
  logic io_ptw_resp_bits_s1_entry_perm_a;
  logic io_ptw_resp_bits_s1_entry_perm_g;
  logic io_ptw_resp_bits_s1_entry_perm_u;
  logic io_ptw_resp_bits_s1_entry_perm_x;
  logic io_ptw_resp_bits_s1_entry_perm_w;
  logic io_ptw_resp_bits_s1_entry_perm_r;
  logic [1:0] io_ptw_resp_bits_s1_entry_level;
  logic io_ptw_resp_bits_s1_entry_v;
  logic [40:0] io_ptw_resp_bits_s1_entry_ppn;
  logic [2:0] io_ptw_resp_bits_s1_addr_low;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_0;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_1;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_2;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_3;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_4;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_5;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_6;
  logic [2:0] io_ptw_resp_bits_s1_ppn_low_7;
  logic io_ptw_resp_bits_s1_valididx_0;
  logic io_ptw_resp_bits_s1_valididx_1;
  logic io_ptw_resp_bits_s1_valididx_2;
  logic io_ptw_resp_bits_s1_valididx_3;
  logic io_ptw_resp_bits_s1_valididx_4;
  logic io_ptw_resp_bits_s1_valididx_5;
  logic io_ptw_resp_bits_s1_valididx_6;
  logic io_ptw_resp_bits_s1_valididx_7;
  logic io_ptw_resp_bits_s1_pteidx_0;
  logic io_ptw_resp_bits_s1_pteidx_1;
  logic io_ptw_resp_bits_s1_pteidx_2;
  logic io_ptw_resp_bits_s1_pteidx_3;
  logic io_ptw_resp_bits_s1_pteidx_4;
  logic io_ptw_resp_bits_s1_pteidx_5;
  logic io_ptw_resp_bits_s1_pteidx_6;
  logic io_ptw_resp_bits_s1_pteidx_7;
  logic io_ptw_resp_bits_s1_pf;
  logic io_ptw_resp_bits_s1_af;
  logic [37:0] io_ptw_resp_bits_s2_entry_tag;
  logic [13:0] io_ptw_resp_bits_s2_entry_vmid;
  logic io_ptw_resp_bits_s2_entry_n;
  logic [1:0] io_ptw_resp_bits_s2_entry_pbmt;
  logic [37:0] io_ptw_resp_bits_s2_entry_ppn;
  logic io_ptw_resp_bits_s2_entry_perm_d;
  logic io_ptw_resp_bits_s2_entry_perm_a;
  logic io_ptw_resp_bits_s2_entry_perm_g;
  logic io_ptw_resp_bits_s2_entry_perm_u;
  logic io_ptw_resp_bits_s2_entry_perm_x;
  logic io_ptw_resp_bits_s2_entry_perm_w;
  logic io_ptw_resp_bits_s2_entry_perm_r;
  logic [1:0] io_ptw_resp_bits_s2_entry_level;
  logic io_ptw_resp_bits_s2_gpf;
  logic io_ptw_resp_bits_s2_gaf;
  wire g_io_tlb_req_0_ready;
  wire i_io_tlb_req_0_ready;
  wire g_io_tlb_resp_valid;
  wire i_io_tlb_resp_valid;
  wire [1:0] g_io_tlb_resp_bits_s2xlate;
  wire [1:0] i_io_tlb_resp_bits_s2xlate;
  wire [34:0] g_io_tlb_resp_bits_s1_entry_tag;
  wire [34:0] i_io_tlb_resp_bits_s1_entry_tag;
  wire [15:0] g_io_tlb_resp_bits_s1_entry_asid;
  wire [15:0] i_io_tlb_resp_bits_s1_entry_asid;
  wire [13:0] g_io_tlb_resp_bits_s1_entry_vmid;
  wire [13:0] i_io_tlb_resp_bits_s1_entry_vmid;
  wire g_io_tlb_resp_bits_s1_entry_n;
  wire i_io_tlb_resp_bits_s1_entry_n;
  wire [1:0] g_io_tlb_resp_bits_s1_entry_pbmt;
  wire [1:0] i_io_tlb_resp_bits_s1_entry_pbmt;
  wire g_io_tlb_resp_bits_s1_entry_perm_d;
  wire i_io_tlb_resp_bits_s1_entry_perm_d;
  wire g_io_tlb_resp_bits_s1_entry_perm_a;
  wire i_io_tlb_resp_bits_s1_entry_perm_a;
  wire g_io_tlb_resp_bits_s1_entry_perm_g;
  wire i_io_tlb_resp_bits_s1_entry_perm_g;
  wire g_io_tlb_resp_bits_s1_entry_perm_u;
  wire i_io_tlb_resp_bits_s1_entry_perm_u;
  wire g_io_tlb_resp_bits_s1_entry_perm_x;
  wire i_io_tlb_resp_bits_s1_entry_perm_x;
  wire g_io_tlb_resp_bits_s1_entry_perm_w;
  wire i_io_tlb_resp_bits_s1_entry_perm_w;
  wire g_io_tlb_resp_bits_s1_entry_perm_r;
  wire i_io_tlb_resp_bits_s1_entry_perm_r;
  wire [1:0] g_io_tlb_resp_bits_s1_entry_level;
  wire [1:0] i_io_tlb_resp_bits_s1_entry_level;
  wire g_io_tlb_resp_bits_s1_entry_v;
  wire i_io_tlb_resp_bits_s1_entry_v;
  wire [40:0] g_io_tlb_resp_bits_s1_entry_ppn;
  wire [40:0] i_io_tlb_resp_bits_s1_entry_ppn;
  wire [2:0] g_io_tlb_resp_bits_s1_addr_low;
  wire [2:0] i_io_tlb_resp_bits_s1_addr_low;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_0;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_0;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_1;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_1;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_2;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_2;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_3;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_3;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_4;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_4;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_5;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_5;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_6;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_6;
  wire [2:0] g_io_tlb_resp_bits_s1_ppn_low_7;
  wire [2:0] i_io_tlb_resp_bits_s1_ppn_low_7;
  wire g_io_tlb_resp_bits_s1_valididx_0;
  wire i_io_tlb_resp_bits_s1_valididx_0;
  wire g_io_tlb_resp_bits_s1_valididx_1;
  wire i_io_tlb_resp_bits_s1_valididx_1;
  wire g_io_tlb_resp_bits_s1_valididx_2;
  wire i_io_tlb_resp_bits_s1_valididx_2;
  wire g_io_tlb_resp_bits_s1_valididx_3;
  wire i_io_tlb_resp_bits_s1_valididx_3;
  wire g_io_tlb_resp_bits_s1_valididx_4;
  wire i_io_tlb_resp_bits_s1_valididx_4;
  wire g_io_tlb_resp_bits_s1_valididx_5;
  wire i_io_tlb_resp_bits_s1_valididx_5;
  wire g_io_tlb_resp_bits_s1_valididx_6;
  wire i_io_tlb_resp_bits_s1_valididx_6;
  wire g_io_tlb_resp_bits_s1_valididx_7;
  wire i_io_tlb_resp_bits_s1_valididx_7;
  wire g_io_tlb_resp_bits_s1_pteidx_0;
  wire i_io_tlb_resp_bits_s1_pteidx_0;
  wire g_io_tlb_resp_bits_s1_pteidx_1;
  wire i_io_tlb_resp_bits_s1_pteidx_1;
  wire g_io_tlb_resp_bits_s1_pteidx_2;
  wire i_io_tlb_resp_bits_s1_pteidx_2;
  wire g_io_tlb_resp_bits_s1_pteidx_3;
  wire i_io_tlb_resp_bits_s1_pteidx_3;
  wire g_io_tlb_resp_bits_s1_pteidx_4;
  wire i_io_tlb_resp_bits_s1_pteidx_4;
  wire g_io_tlb_resp_bits_s1_pteidx_5;
  wire i_io_tlb_resp_bits_s1_pteidx_5;
  wire g_io_tlb_resp_bits_s1_pteidx_6;
  wire i_io_tlb_resp_bits_s1_pteidx_6;
  wire g_io_tlb_resp_bits_s1_pteidx_7;
  wire i_io_tlb_resp_bits_s1_pteidx_7;
  wire g_io_tlb_resp_bits_s1_pf;
  wire i_io_tlb_resp_bits_s1_pf;
  wire g_io_tlb_resp_bits_s1_af;
  wire i_io_tlb_resp_bits_s1_af;
  wire [37:0] g_io_tlb_resp_bits_s2_entry_tag;
  wire [37:0] i_io_tlb_resp_bits_s2_entry_tag;
  wire [13:0] g_io_tlb_resp_bits_s2_entry_vmid;
  wire [13:0] i_io_tlb_resp_bits_s2_entry_vmid;
  wire g_io_tlb_resp_bits_s2_entry_n;
  wire i_io_tlb_resp_bits_s2_entry_n;
  wire [1:0] g_io_tlb_resp_bits_s2_entry_pbmt;
  wire [1:0] i_io_tlb_resp_bits_s2_entry_pbmt;
  wire [37:0] g_io_tlb_resp_bits_s2_entry_ppn;
  wire [37:0] i_io_tlb_resp_bits_s2_entry_ppn;
  wire g_io_tlb_resp_bits_s2_entry_perm_d;
  wire i_io_tlb_resp_bits_s2_entry_perm_d;
  wire g_io_tlb_resp_bits_s2_entry_perm_a;
  wire i_io_tlb_resp_bits_s2_entry_perm_a;
  wire g_io_tlb_resp_bits_s2_entry_perm_g;
  wire i_io_tlb_resp_bits_s2_entry_perm_g;
  wire g_io_tlb_resp_bits_s2_entry_perm_u;
  wire i_io_tlb_resp_bits_s2_entry_perm_u;
  wire g_io_tlb_resp_bits_s2_entry_perm_x;
  wire i_io_tlb_resp_bits_s2_entry_perm_x;
  wire g_io_tlb_resp_bits_s2_entry_perm_w;
  wire i_io_tlb_resp_bits_s2_entry_perm_w;
  wire g_io_tlb_resp_bits_s2_entry_perm_r;
  wire i_io_tlb_resp_bits_s2_entry_perm_r;
  wire [1:0] g_io_tlb_resp_bits_s2_entry_level;
  wire [1:0] i_io_tlb_resp_bits_s2_entry_level;
  wire g_io_tlb_resp_bits_s2_gpf;
  wire i_io_tlb_resp_bits_s2_gpf;
  wire g_io_tlb_resp_bits_s2_gaf;
  wire i_io_tlb_resp_bits_s2_gaf;
  wire g_io_ptw_req_0_valid;
  wire i_io_ptw_req_0_valid;
  wire [37:0] g_io_ptw_req_0_bits_vpn;
  wire [37:0] i_io_ptw_req_0_bits_vpn;
  wire [1:0] g_io_ptw_req_0_bits_s2xlate;
  wire [1:0] i_io_ptw_req_0_bits_s2xlate;
  wire g_io_ptw_resp_ready;
  wire i_io_ptw_resp_ready;
  PTWRepeaterNB    u_g (.clock(clk), .reset(rst), .io_sfence_valid(io_sfence_valid), .io_csr_satp_changed(io_csr_satp_changed), .io_csr_vsatp_changed(io_csr_vsatp_changed), .io_csr_hgatp_changed(io_csr_hgatp_changed), .io_tlb_req_0_valid(io_tlb_req_0_valid), .io_tlb_req_0_bits_vpn(io_tlb_req_0_bits_vpn), .io_tlb_req_0_bits_s2xlate(io_tlb_req_0_bits_s2xlate), .io_tlb_resp_ready(io_tlb_resp_ready), .io_ptw_req_0_ready(io_ptw_req_0_ready), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_tlb_req_0_ready(g_io_tlb_req_0_ready), .io_tlb_resp_valid(g_io_tlb_resp_valid), .io_tlb_resp_bits_s2xlate(g_io_tlb_resp_bits_s2xlate), .io_tlb_resp_bits_s1_entry_tag(g_io_tlb_resp_bits_s1_entry_tag), .io_tlb_resp_bits_s1_entry_asid(g_io_tlb_resp_bits_s1_entry_asid), .io_tlb_resp_bits_s1_entry_vmid(g_io_tlb_resp_bits_s1_entry_vmid), .io_tlb_resp_bits_s1_entry_n(g_io_tlb_resp_bits_s1_entry_n), .io_tlb_resp_bits_s1_entry_pbmt(g_io_tlb_resp_bits_s1_entry_pbmt), .io_tlb_resp_bits_s1_entry_perm_d(g_io_tlb_resp_bits_s1_entry_perm_d), .io_tlb_resp_bits_s1_entry_perm_a(g_io_tlb_resp_bits_s1_entry_perm_a), .io_tlb_resp_bits_s1_entry_perm_g(g_io_tlb_resp_bits_s1_entry_perm_g), .io_tlb_resp_bits_s1_entry_perm_u(g_io_tlb_resp_bits_s1_entry_perm_u), .io_tlb_resp_bits_s1_entry_perm_x(g_io_tlb_resp_bits_s1_entry_perm_x), .io_tlb_resp_bits_s1_entry_perm_w(g_io_tlb_resp_bits_s1_entry_perm_w), .io_tlb_resp_bits_s1_entry_perm_r(g_io_tlb_resp_bits_s1_entry_perm_r), .io_tlb_resp_bits_s1_entry_level(g_io_tlb_resp_bits_s1_entry_level), .io_tlb_resp_bits_s1_entry_v(g_io_tlb_resp_bits_s1_entry_v), .io_tlb_resp_bits_s1_entry_ppn(g_io_tlb_resp_bits_s1_entry_ppn), .io_tlb_resp_bits_s1_addr_low(g_io_tlb_resp_bits_s1_addr_low), .io_tlb_resp_bits_s1_ppn_low_0(g_io_tlb_resp_bits_s1_ppn_low_0), .io_tlb_resp_bits_s1_ppn_low_1(g_io_tlb_resp_bits_s1_ppn_low_1), .io_tlb_resp_bits_s1_ppn_low_2(g_io_tlb_resp_bits_s1_ppn_low_2), .io_tlb_resp_bits_s1_ppn_low_3(g_io_tlb_resp_bits_s1_ppn_low_3), .io_tlb_resp_bits_s1_ppn_low_4(g_io_tlb_resp_bits_s1_ppn_low_4), .io_tlb_resp_bits_s1_ppn_low_5(g_io_tlb_resp_bits_s1_ppn_low_5), .io_tlb_resp_bits_s1_ppn_low_6(g_io_tlb_resp_bits_s1_ppn_low_6), .io_tlb_resp_bits_s1_ppn_low_7(g_io_tlb_resp_bits_s1_ppn_low_7), .io_tlb_resp_bits_s1_valididx_0(g_io_tlb_resp_bits_s1_valididx_0), .io_tlb_resp_bits_s1_valididx_1(g_io_tlb_resp_bits_s1_valididx_1), .io_tlb_resp_bits_s1_valididx_2(g_io_tlb_resp_bits_s1_valididx_2), .io_tlb_resp_bits_s1_valididx_3(g_io_tlb_resp_bits_s1_valididx_3), .io_tlb_resp_bits_s1_valididx_4(g_io_tlb_resp_bits_s1_valididx_4), .io_tlb_resp_bits_s1_valididx_5(g_io_tlb_resp_bits_s1_valididx_5), .io_tlb_resp_bits_s1_valididx_6(g_io_tlb_resp_bits_s1_valididx_6), .io_tlb_resp_bits_s1_valididx_7(g_io_tlb_resp_bits_s1_valididx_7), .io_tlb_resp_bits_s1_pteidx_0(g_io_tlb_resp_bits_s1_pteidx_0), .io_tlb_resp_bits_s1_pteidx_1(g_io_tlb_resp_bits_s1_pteidx_1), .io_tlb_resp_bits_s1_pteidx_2(g_io_tlb_resp_bits_s1_pteidx_2), .io_tlb_resp_bits_s1_pteidx_3(g_io_tlb_resp_bits_s1_pteidx_3), .io_tlb_resp_bits_s1_pteidx_4(g_io_tlb_resp_bits_s1_pteidx_4), .io_tlb_resp_bits_s1_pteidx_5(g_io_tlb_resp_bits_s1_pteidx_5), .io_tlb_resp_bits_s1_pteidx_6(g_io_tlb_resp_bits_s1_pteidx_6), .io_tlb_resp_bits_s1_pteidx_7(g_io_tlb_resp_bits_s1_pteidx_7), .io_tlb_resp_bits_s1_pf(g_io_tlb_resp_bits_s1_pf), .io_tlb_resp_bits_s1_af(g_io_tlb_resp_bits_s1_af), .io_tlb_resp_bits_s2_entry_tag(g_io_tlb_resp_bits_s2_entry_tag), .io_tlb_resp_bits_s2_entry_vmid(g_io_tlb_resp_bits_s2_entry_vmid), .io_tlb_resp_bits_s2_entry_n(g_io_tlb_resp_bits_s2_entry_n), .io_tlb_resp_bits_s2_entry_pbmt(g_io_tlb_resp_bits_s2_entry_pbmt), .io_tlb_resp_bits_s2_entry_ppn(g_io_tlb_resp_bits_s2_entry_ppn), .io_tlb_resp_bits_s2_entry_perm_d(g_io_tlb_resp_bits_s2_entry_perm_d), .io_tlb_resp_bits_s2_entry_perm_a(g_io_tlb_resp_bits_s2_entry_perm_a), .io_tlb_resp_bits_s2_entry_perm_g(g_io_tlb_resp_bits_s2_entry_perm_g), .io_tlb_resp_bits_s2_entry_perm_u(g_io_tlb_resp_bits_s2_entry_perm_u), .io_tlb_resp_bits_s2_entry_perm_x(g_io_tlb_resp_bits_s2_entry_perm_x), .io_tlb_resp_bits_s2_entry_perm_w(g_io_tlb_resp_bits_s2_entry_perm_w), .io_tlb_resp_bits_s2_entry_perm_r(g_io_tlb_resp_bits_s2_entry_perm_r), .io_tlb_resp_bits_s2_entry_level(g_io_tlb_resp_bits_s2_entry_level), .io_tlb_resp_bits_s2_gpf(g_io_tlb_resp_bits_s2_gpf), .io_tlb_resp_bits_s2_gaf(g_io_tlb_resp_bits_s2_gaf), .io_ptw_req_0_valid(g_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(g_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(g_io_ptw_req_0_bits_s2xlate), .io_ptw_resp_ready(g_io_ptw_resp_ready));
  PTWRepeaterNB_xs u_i (.clock(clk), .reset(rst), .io_sfence_valid(io_sfence_valid), .io_csr_satp_changed(io_csr_satp_changed), .io_csr_vsatp_changed(io_csr_vsatp_changed), .io_csr_hgatp_changed(io_csr_hgatp_changed), .io_tlb_req_0_valid(io_tlb_req_0_valid), .io_tlb_req_0_bits_vpn(io_tlb_req_0_bits_vpn), .io_tlb_req_0_bits_s2xlate(io_tlb_req_0_bits_s2xlate), .io_tlb_resp_ready(io_tlb_resp_ready), .io_ptw_req_0_ready(io_ptw_req_0_ready), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_tlb_req_0_ready(i_io_tlb_req_0_ready), .io_tlb_resp_valid(i_io_tlb_resp_valid), .io_tlb_resp_bits_s2xlate(i_io_tlb_resp_bits_s2xlate), .io_tlb_resp_bits_s1_entry_tag(i_io_tlb_resp_bits_s1_entry_tag), .io_tlb_resp_bits_s1_entry_asid(i_io_tlb_resp_bits_s1_entry_asid), .io_tlb_resp_bits_s1_entry_vmid(i_io_tlb_resp_bits_s1_entry_vmid), .io_tlb_resp_bits_s1_entry_n(i_io_tlb_resp_bits_s1_entry_n), .io_tlb_resp_bits_s1_entry_pbmt(i_io_tlb_resp_bits_s1_entry_pbmt), .io_tlb_resp_bits_s1_entry_perm_d(i_io_tlb_resp_bits_s1_entry_perm_d), .io_tlb_resp_bits_s1_entry_perm_a(i_io_tlb_resp_bits_s1_entry_perm_a), .io_tlb_resp_bits_s1_entry_perm_g(i_io_tlb_resp_bits_s1_entry_perm_g), .io_tlb_resp_bits_s1_entry_perm_u(i_io_tlb_resp_bits_s1_entry_perm_u), .io_tlb_resp_bits_s1_entry_perm_x(i_io_tlb_resp_bits_s1_entry_perm_x), .io_tlb_resp_bits_s1_entry_perm_w(i_io_tlb_resp_bits_s1_entry_perm_w), .io_tlb_resp_bits_s1_entry_perm_r(i_io_tlb_resp_bits_s1_entry_perm_r), .io_tlb_resp_bits_s1_entry_level(i_io_tlb_resp_bits_s1_entry_level), .io_tlb_resp_bits_s1_entry_v(i_io_tlb_resp_bits_s1_entry_v), .io_tlb_resp_bits_s1_entry_ppn(i_io_tlb_resp_bits_s1_entry_ppn), .io_tlb_resp_bits_s1_addr_low(i_io_tlb_resp_bits_s1_addr_low), .io_tlb_resp_bits_s1_ppn_low_0(i_io_tlb_resp_bits_s1_ppn_low_0), .io_tlb_resp_bits_s1_ppn_low_1(i_io_tlb_resp_bits_s1_ppn_low_1), .io_tlb_resp_bits_s1_ppn_low_2(i_io_tlb_resp_bits_s1_ppn_low_2), .io_tlb_resp_bits_s1_ppn_low_3(i_io_tlb_resp_bits_s1_ppn_low_3), .io_tlb_resp_bits_s1_ppn_low_4(i_io_tlb_resp_bits_s1_ppn_low_4), .io_tlb_resp_bits_s1_ppn_low_5(i_io_tlb_resp_bits_s1_ppn_low_5), .io_tlb_resp_bits_s1_ppn_low_6(i_io_tlb_resp_bits_s1_ppn_low_6), .io_tlb_resp_bits_s1_ppn_low_7(i_io_tlb_resp_bits_s1_ppn_low_7), .io_tlb_resp_bits_s1_valididx_0(i_io_tlb_resp_bits_s1_valididx_0), .io_tlb_resp_bits_s1_valididx_1(i_io_tlb_resp_bits_s1_valididx_1), .io_tlb_resp_bits_s1_valididx_2(i_io_tlb_resp_bits_s1_valididx_2), .io_tlb_resp_bits_s1_valididx_3(i_io_tlb_resp_bits_s1_valididx_3), .io_tlb_resp_bits_s1_valididx_4(i_io_tlb_resp_bits_s1_valididx_4), .io_tlb_resp_bits_s1_valididx_5(i_io_tlb_resp_bits_s1_valididx_5), .io_tlb_resp_bits_s1_valididx_6(i_io_tlb_resp_bits_s1_valididx_6), .io_tlb_resp_bits_s1_valididx_7(i_io_tlb_resp_bits_s1_valididx_7), .io_tlb_resp_bits_s1_pteidx_0(i_io_tlb_resp_bits_s1_pteidx_0), .io_tlb_resp_bits_s1_pteidx_1(i_io_tlb_resp_bits_s1_pteidx_1), .io_tlb_resp_bits_s1_pteidx_2(i_io_tlb_resp_bits_s1_pteidx_2), .io_tlb_resp_bits_s1_pteidx_3(i_io_tlb_resp_bits_s1_pteidx_3), .io_tlb_resp_bits_s1_pteidx_4(i_io_tlb_resp_bits_s1_pteidx_4), .io_tlb_resp_bits_s1_pteidx_5(i_io_tlb_resp_bits_s1_pteidx_5), .io_tlb_resp_bits_s1_pteidx_6(i_io_tlb_resp_bits_s1_pteidx_6), .io_tlb_resp_bits_s1_pteidx_7(i_io_tlb_resp_bits_s1_pteidx_7), .io_tlb_resp_bits_s1_pf(i_io_tlb_resp_bits_s1_pf), .io_tlb_resp_bits_s1_af(i_io_tlb_resp_bits_s1_af), .io_tlb_resp_bits_s2_entry_tag(i_io_tlb_resp_bits_s2_entry_tag), .io_tlb_resp_bits_s2_entry_vmid(i_io_tlb_resp_bits_s2_entry_vmid), .io_tlb_resp_bits_s2_entry_n(i_io_tlb_resp_bits_s2_entry_n), .io_tlb_resp_bits_s2_entry_pbmt(i_io_tlb_resp_bits_s2_entry_pbmt), .io_tlb_resp_bits_s2_entry_ppn(i_io_tlb_resp_bits_s2_entry_ppn), .io_tlb_resp_bits_s2_entry_perm_d(i_io_tlb_resp_bits_s2_entry_perm_d), .io_tlb_resp_bits_s2_entry_perm_a(i_io_tlb_resp_bits_s2_entry_perm_a), .io_tlb_resp_bits_s2_entry_perm_g(i_io_tlb_resp_bits_s2_entry_perm_g), .io_tlb_resp_bits_s2_entry_perm_u(i_io_tlb_resp_bits_s2_entry_perm_u), .io_tlb_resp_bits_s2_entry_perm_x(i_io_tlb_resp_bits_s2_entry_perm_x), .io_tlb_resp_bits_s2_entry_perm_w(i_io_tlb_resp_bits_s2_entry_perm_w), .io_tlb_resp_bits_s2_entry_perm_r(i_io_tlb_resp_bits_s2_entry_perm_r), .io_tlb_resp_bits_s2_entry_level(i_io_tlb_resp_bits_s2_entry_level), .io_tlb_resp_bits_s2_gpf(i_io_tlb_resp_bits_s2_gpf), .io_tlb_resp_bits_s2_gaf(i_io_tlb_resp_bits_s2_gaf), .io_ptw_req_0_valid(i_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(i_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(i_io_ptw_req_0_bits_s2xlate), .io_ptw_resp_ready(i_io_ptw_resp_ready));
  always @(negedge clk) begin
    if (rst) begin
      io_tlb_req_0_valid <= 1'b0;
      io_tlb_resp_ready <= 1'b0;
      io_ptw_req_0_ready <= 1'b0;
      io_ptw_resp_valid <= 1'b0;
      io_sfence_valid <= 1'b0;
      io_csr_satp_changed <= 1'b0;
      io_csr_vsatp_changed <= 1'b0;
      io_csr_hgatp_changed <= 1'b0;
    end else begin
      io_sfence_valid <= ($urandom_range(0,63)==0);
      io_csr_satp_changed <= ($urandom_range(0,63)==0);
      io_csr_vsatp_changed <= ($urandom_range(0,63)==0);
      io_csr_hgatp_changed <= ($urandom_range(0,63)==0);
      io_tlb_req_0_valid <= ($urandom_range(0,1));
      io_tlb_req_0_bits_vpn <= 38'({$urandom(), $urandom()});
      io_tlb_req_0_bits_s2xlate <= 2'($urandom);
      io_tlb_resp_ready <= ($urandom_range(0,1));
      io_ptw_req_0_ready <= ($urandom_range(0,1));
      io_ptw_resp_valid <= ($urandom_range(0,2)==0);
      io_ptw_resp_bits_s2xlate <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_tag <= 35'({$urandom(), $urandom()});
      io_ptw_resp_bits_s1_entry_asid <= 16'($urandom);
      io_ptw_resp_bits_s1_entry_vmid <= 14'($urandom);
      io_ptw_resp_bits_s1_entry_n <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_pbmt <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_perm_d <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_a <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_g <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_u <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_x <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_w <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_perm_r <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_level <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_v <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_entry_ppn <= 41'({$urandom(), $urandom()});
      io_ptw_resp_bits_s1_addr_low <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_0 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_1 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_2 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_3 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_4 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_5 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_6 <= 3'($urandom);
      io_ptw_resp_bits_s1_ppn_low_7 <= 3'($urandom);
      io_ptw_resp_bits_s1_valididx_0 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_1 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_2 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_3 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_4 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_5 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_6 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_valididx_7 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_0 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_1 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_2 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_3 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_4 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_5 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_6 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pteidx_7 <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_pf <= $urandom_range(0,1);
      io_ptw_resp_bits_s1_af <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_tag <= 38'({$urandom(), $urandom()});
      io_ptw_resp_bits_s2_entry_vmid <= 14'($urandom);
      io_ptw_resp_bits_s2_entry_n <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_pbmt <= 2'($urandom);
      io_ptw_resp_bits_s2_entry_ppn <= 38'({$urandom(), $urandom()});
      io_ptw_resp_bits_s2_entry_perm_d <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_a <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_g <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_u <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_x <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_w <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_perm_r <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_entry_level <= 2'($urandom);
      io_ptw_resp_bits_s2_gpf <= $urandom_range(0,1);
      io_ptw_resp_bits_s2_gaf <= $urandom_range(0,1);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_tlb_req_0_ready) && g_io_tlb_req_0_ready !== i_io_tlb_req_0_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_req_0_ready g=%h i=%h", $time, g_io_tlb_req_0_ready, i_io_tlb_req_0_ready); end
    if (!$isunknown(g_io_tlb_resp_valid) && g_io_tlb_resp_valid !== i_io_tlb_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_valid g=%h i=%h", $time, g_io_tlb_resp_valid, i_io_tlb_resp_valid); end
    if (!$isunknown(g_io_tlb_resp_bits_s2xlate) && g_io_tlb_resp_bits_s2xlate !== i_io_tlb_resp_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2xlate g=%h i=%h", $time, g_io_tlb_resp_bits_s2xlate, i_io_tlb_resp_bits_s2xlate); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_tag) && g_io_tlb_resp_bits_s1_entry_tag !== i_io_tlb_resp_bits_s1_entry_tag) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_tag g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_tag, i_io_tlb_resp_bits_s1_entry_tag); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_asid) && g_io_tlb_resp_bits_s1_entry_asid !== i_io_tlb_resp_bits_s1_entry_asid) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_asid g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_asid, i_io_tlb_resp_bits_s1_entry_asid); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_vmid) && g_io_tlb_resp_bits_s1_entry_vmid !== i_io_tlb_resp_bits_s1_entry_vmid) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_vmid g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_vmid, i_io_tlb_resp_bits_s1_entry_vmid); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_n) && g_io_tlb_resp_bits_s1_entry_n !== i_io_tlb_resp_bits_s1_entry_n) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_n g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_n, i_io_tlb_resp_bits_s1_entry_n); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_pbmt) && g_io_tlb_resp_bits_s1_entry_pbmt !== i_io_tlb_resp_bits_s1_entry_pbmt) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_pbmt g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_pbmt, i_io_tlb_resp_bits_s1_entry_pbmt); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_d) && g_io_tlb_resp_bits_s1_entry_perm_d !== i_io_tlb_resp_bits_s1_entry_perm_d) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_d g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_d, i_io_tlb_resp_bits_s1_entry_perm_d); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_a) && g_io_tlb_resp_bits_s1_entry_perm_a !== i_io_tlb_resp_bits_s1_entry_perm_a) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_a g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_a, i_io_tlb_resp_bits_s1_entry_perm_a); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_g) && g_io_tlb_resp_bits_s1_entry_perm_g !== i_io_tlb_resp_bits_s1_entry_perm_g) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_g g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_g, i_io_tlb_resp_bits_s1_entry_perm_g); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_u) && g_io_tlb_resp_bits_s1_entry_perm_u !== i_io_tlb_resp_bits_s1_entry_perm_u) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_u g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_u, i_io_tlb_resp_bits_s1_entry_perm_u); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_x) && g_io_tlb_resp_bits_s1_entry_perm_x !== i_io_tlb_resp_bits_s1_entry_perm_x) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_x g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_x, i_io_tlb_resp_bits_s1_entry_perm_x); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_w) && g_io_tlb_resp_bits_s1_entry_perm_w !== i_io_tlb_resp_bits_s1_entry_perm_w) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_w g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_w, i_io_tlb_resp_bits_s1_entry_perm_w); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_perm_r) && g_io_tlb_resp_bits_s1_entry_perm_r !== i_io_tlb_resp_bits_s1_entry_perm_r) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_perm_r g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_perm_r, i_io_tlb_resp_bits_s1_entry_perm_r); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_level) && g_io_tlb_resp_bits_s1_entry_level !== i_io_tlb_resp_bits_s1_entry_level) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_level g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_level, i_io_tlb_resp_bits_s1_entry_level); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_v) && g_io_tlb_resp_bits_s1_entry_v !== i_io_tlb_resp_bits_s1_entry_v) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_v g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_v, i_io_tlb_resp_bits_s1_entry_v); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_entry_ppn) && g_io_tlb_resp_bits_s1_entry_ppn !== i_io_tlb_resp_bits_s1_entry_ppn) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_entry_ppn g=%h i=%h", $time, g_io_tlb_resp_bits_s1_entry_ppn, i_io_tlb_resp_bits_s1_entry_ppn); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_addr_low) && g_io_tlb_resp_bits_s1_addr_low !== i_io_tlb_resp_bits_s1_addr_low) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_addr_low g=%h i=%h", $time, g_io_tlb_resp_bits_s1_addr_low, i_io_tlb_resp_bits_s1_addr_low); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_0) && g_io_tlb_resp_bits_s1_ppn_low_0 !== i_io_tlb_resp_bits_s1_ppn_low_0) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_0 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_0, i_io_tlb_resp_bits_s1_ppn_low_0); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_1) && g_io_tlb_resp_bits_s1_ppn_low_1 !== i_io_tlb_resp_bits_s1_ppn_low_1) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_1 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_1, i_io_tlb_resp_bits_s1_ppn_low_1); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_2) && g_io_tlb_resp_bits_s1_ppn_low_2 !== i_io_tlb_resp_bits_s1_ppn_low_2) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_2 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_2, i_io_tlb_resp_bits_s1_ppn_low_2); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_3) && g_io_tlb_resp_bits_s1_ppn_low_3 !== i_io_tlb_resp_bits_s1_ppn_low_3) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_3 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_3, i_io_tlb_resp_bits_s1_ppn_low_3); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_4) && g_io_tlb_resp_bits_s1_ppn_low_4 !== i_io_tlb_resp_bits_s1_ppn_low_4) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_4 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_4, i_io_tlb_resp_bits_s1_ppn_low_4); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_5) && g_io_tlb_resp_bits_s1_ppn_low_5 !== i_io_tlb_resp_bits_s1_ppn_low_5) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_5 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_5, i_io_tlb_resp_bits_s1_ppn_low_5); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_6) && g_io_tlb_resp_bits_s1_ppn_low_6 !== i_io_tlb_resp_bits_s1_ppn_low_6) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_6 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_6, i_io_tlb_resp_bits_s1_ppn_low_6); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_ppn_low_7) && g_io_tlb_resp_bits_s1_ppn_low_7 !== i_io_tlb_resp_bits_s1_ppn_low_7) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_ppn_low_7 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_ppn_low_7, i_io_tlb_resp_bits_s1_ppn_low_7); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_0) && g_io_tlb_resp_bits_s1_valididx_0 !== i_io_tlb_resp_bits_s1_valididx_0) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_0 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_0, i_io_tlb_resp_bits_s1_valididx_0); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_1) && g_io_tlb_resp_bits_s1_valididx_1 !== i_io_tlb_resp_bits_s1_valididx_1) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_1 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_1, i_io_tlb_resp_bits_s1_valididx_1); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_2) && g_io_tlb_resp_bits_s1_valididx_2 !== i_io_tlb_resp_bits_s1_valididx_2) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_2 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_2, i_io_tlb_resp_bits_s1_valididx_2); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_3) && g_io_tlb_resp_bits_s1_valididx_3 !== i_io_tlb_resp_bits_s1_valididx_3) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_3 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_3, i_io_tlb_resp_bits_s1_valididx_3); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_4) && g_io_tlb_resp_bits_s1_valididx_4 !== i_io_tlb_resp_bits_s1_valididx_4) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_4 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_4, i_io_tlb_resp_bits_s1_valididx_4); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_5) && g_io_tlb_resp_bits_s1_valididx_5 !== i_io_tlb_resp_bits_s1_valididx_5) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_5 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_5, i_io_tlb_resp_bits_s1_valididx_5); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_6) && g_io_tlb_resp_bits_s1_valididx_6 !== i_io_tlb_resp_bits_s1_valididx_6) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_6 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_6, i_io_tlb_resp_bits_s1_valididx_6); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_valididx_7) && g_io_tlb_resp_bits_s1_valididx_7 !== i_io_tlb_resp_bits_s1_valididx_7) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_valididx_7 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_valididx_7, i_io_tlb_resp_bits_s1_valididx_7); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_0) && g_io_tlb_resp_bits_s1_pteidx_0 !== i_io_tlb_resp_bits_s1_pteidx_0) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_0 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_0, i_io_tlb_resp_bits_s1_pteidx_0); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_1) && g_io_tlb_resp_bits_s1_pteidx_1 !== i_io_tlb_resp_bits_s1_pteidx_1) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_1 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_1, i_io_tlb_resp_bits_s1_pteidx_1); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_2) && g_io_tlb_resp_bits_s1_pteidx_2 !== i_io_tlb_resp_bits_s1_pteidx_2) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_2 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_2, i_io_tlb_resp_bits_s1_pteidx_2); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_3) && g_io_tlb_resp_bits_s1_pteidx_3 !== i_io_tlb_resp_bits_s1_pteidx_3) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_3 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_3, i_io_tlb_resp_bits_s1_pteidx_3); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_4) && g_io_tlb_resp_bits_s1_pteidx_4 !== i_io_tlb_resp_bits_s1_pteidx_4) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_4 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_4, i_io_tlb_resp_bits_s1_pteidx_4); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_5) && g_io_tlb_resp_bits_s1_pteidx_5 !== i_io_tlb_resp_bits_s1_pteidx_5) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_5 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_5, i_io_tlb_resp_bits_s1_pteidx_5); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_6) && g_io_tlb_resp_bits_s1_pteidx_6 !== i_io_tlb_resp_bits_s1_pteidx_6) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_6 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_6, i_io_tlb_resp_bits_s1_pteidx_6); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pteidx_7) && g_io_tlb_resp_bits_s1_pteidx_7 !== i_io_tlb_resp_bits_s1_pteidx_7) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pteidx_7 g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pteidx_7, i_io_tlb_resp_bits_s1_pteidx_7); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_pf) && g_io_tlb_resp_bits_s1_pf !== i_io_tlb_resp_bits_s1_pf) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_pf g=%h i=%h", $time, g_io_tlb_resp_bits_s1_pf, i_io_tlb_resp_bits_s1_pf); end
    if (!$isunknown(g_io_tlb_resp_bits_s1_af) && g_io_tlb_resp_bits_s1_af !== i_io_tlb_resp_bits_s1_af) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s1_af g=%h i=%h", $time, g_io_tlb_resp_bits_s1_af, i_io_tlb_resp_bits_s1_af); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_tag) && g_io_tlb_resp_bits_s2_entry_tag !== i_io_tlb_resp_bits_s2_entry_tag) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_tag g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_tag, i_io_tlb_resp_bits_s2_entry_tag); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_vmid) && g_io_tlb_resp_bits_s2_entry_vmid !== i_io_tlb_resp_bits_s2_entry_vmid) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_vmid g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_vmid, i_io_tlb_resp_bits_s2_entry_vmid); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_n) && g_io_tlb_resp_bits_s2_entry_n !== i_io_tlb_resp_bits_s2_entry_n) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_n g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_n, i_io_tlb_resp_bits_s2_entry_n); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_pbmt) && g_io_tlb_resp_bits_s2_entry_pbmt !== i_io_tlb_resp_bits_s2_entry_pbmt) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_pbmt g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_pbmt, i_io_tlb_resp_bits_s2_entry_pbmt); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_ppn) && g_io_tlb_resp_bits_s2_entry_ppn !== i_io_tlb_resp_bits_s2_entry_ppn) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_ppn g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_ppn, i_io_tlb_resp_bits_s2_entry_ppn); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_d) && g_io_tlb_resp_bits_s2_entry_perm_d !== i_io_tlb_resp_bits_s2_entry_perm_d) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_d g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_d, i_io_tlb_resp_bits_s2_entry_perm_d); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_a) && g_io_tlb_resp_bits_s2_entry_perm_a !== i_io_tlb_resp_bits_s2_entry_perm_a) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_a g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_a, i_io_tlb_resp_bits_s2_entry_perm_a); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_g) && g_io_tlb_resp_bits_s2_entry_perm_g !== i_io_tlb_resp_bits_s2_entry_perm_g) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_g g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_g, i_io_tlb_resp_bits_s2_entry_perm_g); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_u) && g_io_tlb_resp_bits_s2_entry_perm_u !== i_io_tlb_resp_bits_s2_entry_perm_u) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_u g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_u, i_io_tlb_resp_bits_s2_entry_perm_u); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_x) && g_io_tlb_resp_bits_s2_entry_perm_x !== i_io_tlb_resp_bits_s2_entry_perm_x) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_x g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_x, i_io_tlb_resp_bits_s2_entry_perm_x); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_w) && g_io_tlb_resp_bits_s2_entry_perm_w !== i_io_tlb_resp_bits_s2_entry_perm_w) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_w g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_w, i_io_tlb_resp_bits_s2_entry_perm_w); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_perm_r) && g_io_tlb_resp_bits_s2_entry_perm_r !== i_io_tlb_resp_bits_s2_entry_perm_r) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_perm_r g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_perm_r, i_io_tlb_resp_bits_s2_entry_perm_r); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_entry_level) && g_io_tlb_resp_bits_s2_entry_level !== i_io_tlb_resp_bits_s2_entry_level) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_entry_level g=%h i=%h", $time, g_io_tlb_resp_bits_s2_entry_level, i_io_tlb_resp_bits_s2_entry_level); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_gpf) && g_io_tlb_resp_bits_s2_gpf !== i_io_tlb_resp_bits_s2_gpf) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_gpf g=%h i=%h", $time, g_io_tlb_resp_bits_s2_gpf, i_io_tlb_resp_bits_s2_gpf); end
    if (!$isunknown(g_io_tlb_resp_bits_s2_gaf) && g_io_tlb_resp_bits_s2_gaf !== i_io_tlb_resp_bits_s2_gaf) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_resp_bits_s2_gaf g=%h i=%h", $time, g_io_tlb_resp_bits_s2_gaf, i_io_tlb_resp_bits_s2_gaf); end
    if (!$isunknown(g_io_ptw_req_0_valid) && g_io_ptw_req_0_valid !== i_io_ptw_req_0_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_valid g=%h i=%h", $time, g_io_ptw_req_0_valid, i_io_ptw_req_0_valid); end
    if (!$isunknown(g_io_ptw_req_0_bits_vpn) && g_io_ptw_req_0_bits_vpn !== i_io_ptw_req_0_bits_vpn) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_bits_vpn g=%h i=%h", $time, g_io_ptw_req_0_bits_vpn, i_io_ptw_req_0_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_0_bits_s2xlate) && g_io_ptw_req_0_bits_s2xlate !== i_io_ptw_req_0_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_0_bits_s2xlate, i_io_ptw_req_0_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_resp_ready) && g_io_ptw_resp_ready !== i_io_ptw_resp_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_resp_ready g=%h i=%h", $time, g_io_ptw_resp_ready, i_io_ptw_resp_ready); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
