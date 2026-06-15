// 自动生成：scripts/gen_tlbfa.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 60000;
  int errors = 0, checks = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;
  logic io_sfence_valid;
  logic io_sfence_bits_rs1;
  logic io_sfence_bits_rs2;
  logic [49:0] io_sfence_bits_addr;
  logic [15:0] io_sfence_bits_id;
  logic io_sfence_bits_hv;
  logic io_sfence_bits_hg;
  logic [15:0] io_csr_satp_asid;
  logic [15:0] io_csr_vsatp_asid;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_csr_priv_virt;
  logic io_r_req_0_valid;
  logic [37:0] io_r_req_0_bits_vpn;
  logic [1:0] io_r_req_0_bits_s2xlate;
  logic io_r_req_1_valid;
  logic [37:0] io_r_req_1_bits_vpn;
  logic [1:0] io_r_req_1_bits_s2xlate;
  logic io_r_req_2_valid;
  logic [37:0] io_r_req_2_bits_vpn;
  logic [1:0] io_r_req_2_bits_s2xlate;
  logic io_r_req_3_valid;
  logic [37:0] io_r_req_3_bits_vpn;
  logic [1:0] io_r_req_3_bits_s2xlate;
  logic io_w_valid;
  logic [5:0] io_w_bits_wayIdx;
  logic [1:0] io_w_bits_data_s2xlate;
  logic [34:0] io_w_bits_data_s1_entry_tag;
  logic [15:0] io_w_bits_data_s1_entry_asid;
  logic [13:0] io_w_bits_data_s1_entry_vmid;
  logic io_w_bits_data_s1_entry_n;
  logic [1:0] io_w_bits_data_s1_entry_pbmt;
  logic io_w_bits_data_s1_entry_perm_d;
  logic io_w_bits_data_s1_entry_perm_a;
  logic io_w_bits_data_s1_entry_perm_g;
  logic io_w_bits_data_s1_entry_perm_u;
  logic io_w_bits_data_s1_entry_perm_x;
  logic io_w_bits_data_s1_entry_perm_w;
  logic io_w_bits_data_s1_entry_perm_r;
  logic [1:0] io_w_bits_data_s1_entry_level;
  logic io_w_bits_data_s1_entry_v;
  logic [40:0] io_w_bits_data_s1_entry_ppn;
  logic [2:0] io_w_bits_data_s1_ppn_low_0;
  logic [2:0] io_w_bits_data_s1_ppn_low_1;
  logic [2:0] io_w_bits_data_s1_ppn_low_2;
  logic [2:0] io_w_bits_data_s1_ppn_low_3;
  logic [2:0] io_w_bits_data_s1_ppn_low_4;
  logic [2:0] io_w_bits_data_s1_ppn_low_5;
  logic [2:0] io_w_bits_data_s1_ppn_low_6;
  logic [2:0] io_w_bits_data_s1_ppn_low_7;
  logic io_w_bits_data_s1_valididx_0;
  logic io_w_bits_data_s1_valididx_1;
  logic io_w_bits_data_s1_valididx_2;
  logic io_w_bits_data_s1_valididx_3;
  logic io_w_bits_data_s1_valididx_4;
  logic io_w_bits_data_s1_valididx_5;
  logic io_w_bits_data_s1_valididx_6;
  logic io_w_bits_data_s1_valididx_7;
  logic io_w_bits_data_s1_pteidx_0;
  logic io_w_bits_data_s1_pteidx_1;
  logic io_w_bits_data_s1_pteidx_2;
  logic io_w_bits_data_s1_pteidx_3;
  logic io_w_bits_data_s1_pteidx_4;
  logic io_w_bits_data_s1_pteidx_5;
  logic io_w_bits_data_s1_pteidx_6;
  logic io_w_bits_data_s1_pteidx_7;
  logic io_w_bits_data_s1_pf;
  logic io_w_bits_data_s1_af;
  logic [37:0] io_w_bits_data_s2_entry_tag;
  logic [13:0] io_w_bits_data_s2_entry_vmid;
  logic io_w_bits_data_s2_entry_n;
  logic [1:0] io_w_bits_data_s2_entry_pbmt;
  logic [37:0] io_w_bits_data_s2_entry_ppn;
  logic io_w_bits_data_s2_entry_perm_d;
  logic io_w_bits_data_s2_entry_perm_a;
  logic io_w_bits_data_s2_entry_perm_g;
  logic io_w_bits_data_s2_entry_perm_u;
  logic io_w_bits_data_s2_entry_perm_x;
  logic io_w_bits_data_s2_entry_perm_w;
  logic io_w_bits_data_s2_entry_perm_r;
  logic [1:0] io_w_bits_data_s2_entry_level;
  logic io_w_bits_data_s2_gpf;
  logic io_w_bits_data_s2_gaf;
  wire g_io_r_resp_0_bits_hit;  wire i_io_r_resp_0_bits_hit;
  wire [35:0] g_io_r_resp_0_bits_ppn_0;  wire [35:0] i_io_r_resp_0_bits_ppn_0;
  wire [35:0] g_io_r_resp_0_bits_ppn_1;  wire [35:0] i_io_r_resp_0_bits_ppn_1;
  wire [1:0] g_io_r_resp_0_bits_pbmt_0;  wire [1:0] i_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_io_r_resp_0_bits_g_pbmt_0;  wire [1:0] i_io_r_resp_0_bits_g_pbmt_0;
  wire g_io_r_resp_0_bits_perm_0_pf;  wire i_io_r_resp_0_bits_perm_0_pf;
  wire g_io_r_resp_0_bits_perm_0_af;  wire i_io_r_resp_0_bits_perm_0_af;
  wire g_io_r_resp_0_bits_perm_0_v;  wire i_io_r_resp_0_bits_perm_0_v;
  wire g_io_r_resp_0_bits_perm_0_d;  wire i_io_r_resp_0_bits_perm_0_d;
  wire g_io_r_resp_0_bits_perm_0_a;  wire i_io_r_resp_0_bits_perm_0_a;
  wire g_io_r_resp_0_bits_perm_0_u;  wire i_io_r_resp_0_bits_perm_0_u;
  wire g_io_r_resp_0_bits_perm_0_x;  wire i_io_r_resp_0_bits_perm_0_x;
  wire g_io_r_resp_0_bits_perm_0_w;  wire i_io_r_resp_0_bits_perm_0_w;
  wire g_io_r_resp_0_bits_perm_0_r;  wire i_io_r_resp_0_bits_perm_0_r;
  wire g_io_r_resp_0_bits_perm_1_pf;  wire i_io_r_resp_0_bits_perm_1_pf;
  wire g_io_r_resp_0_bits_perm_1_af;  wire i_io_r_resp_0_bits_perm_1_af;
  wire g_io_r_resp_0_bits_perm_1_v;  wire i_io_r_resp_0_bits_perm_1_v;
  wire g_io_r_resp_0_bits_perm_1_x;  wire i_io_r_resp_0_bits_perm_1_x;
  wire g_io_r_resp_0_bits_perm_1_w;  wire i_io_r_resp_0_bits_perm_1_w;
  wire g_io_r_resp_0_bits_perm_1_r;  wire i_io_r_resp_0_bits_perm_1_r;
  wire g_io_r_resp_0_bits_g_perm_0_pf;  wire i_io_r_resp_0_bits_g_perm_0_pf;
  wire g_io_r_resp_0_bits_g_perm_0_af;  wire i_io_r_resp_0_bits_g_perm_0_af;
  wire g_io_r_resp_0_bits_g_perm_0_d;  wire i_io_r_resp_0_bits_g_perm_0_d;
  wire g_io_r_resp_0_bits_g_perm_0_a;  wire i_io_r_resp_0_bits_g_perm_0_a;
  wire g_io_r_resp_0_bits_g_perm_0_x;  wire i_io_r_resp_0_bits_g_perm_0_x;
  wire g_io_r_resp_0_bits_g_perm_0_w;  wire i_io_r_resp_0_bits_g_perm_0_w;
  wire g_io_r_resp_0_bits_g_perm_0_r;  wire i_io_r_resp_0_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_0_bits_s2xlate_0;  wire [1:0] i_io_r_resp_0_bits_s2xlate_0;
  wire g_io_r_resp_1_bits_hit;  wire i_io_r_resp_1_bits_hit;
  wire [35:0] g_io_r_resp_1_bits_ppn_0;  wire [35:0] i_io_r_resp_1_bits_ppn_0;
  wire [35:0] g_io_r_resp_1_bits_ppn_1;  wire [35:0] i_io_r_resp_1_bits_ppn_1;
  wire [1:0] g_io_r_resp_1_bits_pbmt_0;  wire [1:0] i_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_io_r_resp_1_bits_g_pbmt_0;  wire [1:0] i_io_r_resp_1_bits_g_pbmt_0;
  wire g_io_r_resp_1_bits_perm_0_pf;  wire i_io_r_resp_1_bits_perm_0_pf;
  wire g_io_r_resp_1_bits_perm_0_af;  wire i_io_r_resp_1_bits_perm_0_af;
  wire g_io_r_resp_1_bits_perm_0_v;  wire i_io_r_resp_1_bits_perm_0_v;
  wire g_io_r_resp_1_bits_perm_0_d;  wire i_io_r_resp_1_bits_perm_0_d;
  wire g_io_r_resp_1_bits_perm_0_a;  wire i_io_r_resp_1_bits_perm_0_a;
  wire g_io_r_resp_1_bits_perm_0_u;  wire i_io_r_resp_1_bits_perm_0_u;
  wire g_io_r_resp_1_bits_perm_0_x;  wire i_io_r_resp_1_bits_perm_0_x;
  wire g_io_r_resp_1_bits_perm_0_w;  wire i_io_r_resp_1_bits_perm_0_w;
  wire g_io_r_resp_1_bits_perm_0_r;  wire i_io_r_resp_1_bits_perm_0_r;
  wire g_io_r_resp_1_bits_perm_1_pf;  wire i_io_r_resp_1_bits_perm_1_pf;
  wire g_io_r_resp_1_bits_perm_1_af;  wire i_io_r_resp_1_bits_perm_1_af;
  wire g_io_r_resp_1_bits_perm_1_v;  wire i_io_r_resp_1_bits_perm_1_v;
  wire g_io_r_resp_1_bits_perm_1_x;  wire i_io_r_resp_1_bits_perm_1_x;
  wire g_io_r_resp_1_bits_perm_1_w;  wire i_io_r_resp_1_bits_perm_1_w;
  wire g_io_r_resp_1_bits_perm_1_r;  wire i_io_r_resp_1_bits_perm_1_r;
  wire g_io_r_resp_1_bits_g_perm_0_pf;  wire i_io_r_resp_1_bits_g_perm_0_pf;
  wire g_io_r_resp_1_bits_g_perm_0_af;  wire i_io_r_resp_1_bits_g_perm_0_af;
  wire g_io_r_resp_1_bits_g_perm_0_d;  wire i_io_r_resp_1_bits_g_perm_0_d;
  wire g_io_r_resp_1_bits_g_perm_0_a;  wire i_io_r_resp_1_bits_g_perm_0_a;
  wire g_io_r_resp_1_bits_g_perm_0_x;  wire i_io_r_resp_1_bits_g_perm_0_x;
  wire g_io_r_resp_1_bits_g_perm_0_w;  wire i_io_r_resp_1_bits_g_perm_0_w;
  wire g_io_r_resp_1_bits_g_perm_0_r;  wire i_io_r_resp_1_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_1_bits_s2xlate_0;  wire [1:0] i_io_r_resp_1_bits_s2xlate_0;
  wire g_io_r_resp_2_bits_hit;  wire i_io_r_resp_2_bits_hit;
  wire [35:0] g_io_r_resp_2_bits_ppn_0;  wire [35:0] i_io_r_resp_2_bits_ppn_0;
  wire [35:0] g_io_r_resp_2_bits_ppn_1;  wire [35:0] i_io_r_resp_2_bits_ppn_1;
  wire [1:0] g_io_r_resp_2_bits_pbmt_0;  wire [1:0] i_io_r_resp_2_bits_pbmt_0;
  wire [1:0] g_io_r_resp_2_bits_g_pbmt_0;  wire [1:0] i_io_r_resp_2_bits_g_pbmt_0;
  wire g_io_r_resp_2_bits_perm_0_pf;  wire i_io_r_resp_2_bits_perm_0_pf;
  wire g_io_r_resp_2_bits_perm_0_af;  wire i_io_r_resp_2_bits_perm_0_af;
  wire g_io_r_resp_2_bits_perm_0_v;  wire i_io_r_resp_2_bits_perm_0_v;
  wire g_io_r_resp_2_bits_perm_0_d;  wire i_io_r_resp_2_bits_perm_0_d;
  wire g_io_r_resp_2_bits_perm_0_a;  wire i_io_r_resp_2_bits_perm_0_a;
  wire g_io_r_resp_2_bits_perm_0_u;  wire i_io_r_resp_2_bits_perm_0_u;
  wire g_io_r_resp_2_bits_perm_0_x;  wire i_io_r_resp_2_bits_perm_0_x;
  wire g_io_r_resp_2_bits_perm_0_w;  wire i_io_r_resp_2_bits_perm_0_w;
  wire g_io_r_resp_2_bits_perm_0_r;  wire i_io_r_resp_2_bits_perm_0_r;
  wire g_io_r_resp_2_bits_perm_1_pf;  wire i_io_r_resp_2_bits_perm_1_pf;
  wire g_io_r_resp_2_bits_perm_1_af;  wire i_io_r_resp_2_bits_perm_1_af;
  wire g_io_r_resp_2_bits_perm_1_v;  wire i_io_r_resp_2_bits_perm_1_v;
  wire g_io_r_resp_2_bits_perm_1_x;  wire i_io_r_resp_2_bits_perm_1_x;
  wire g_io_r_resp_2_bits_perm_1_w;  wire i_io_r_resp_2_bits_perm_1_w;
  wire g_io_r_resp_2_bits_perm_1_r;  wire i_io_r_resp_2_bits_perm_1_r;
  wire g_io_r_resp_2_bits_g_perm_0_pf;  wire i_io_r_resp_2_bits_g_perm_0_pf;
  wire g_io_r_resp_2_bits_g_perm_0_af;  wire i_io_r_resp_2_bits_g_perm_0_af;
  wire g_io_r_resp_2_bits_g_perm_0_d;  wire i_io_r_resp_2_bits_g_perm_0_d;
  wire g_io_r_resp_2_bits_g_perm_0_a;  wire i_io_r_resp_2_bits_g_perm_0_a;
  wire g_io_r_resp_2_bits_g_perm_0_x;  wire i_io_r_resp_2_bits_g_perm_0_x;
  wire g_io_r_resp_2_bits_g_perm_0_w;  wire i_io_r_resp_2_bits_g_perm_0_w;
  wire g_io_r_resp_2_bits_g_perm_0_r;  wire i_io_r_resp_2_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_2_bits_s2xlate_0;  wire [1:0] i_io_r_resp_2_bits_s2xlate_0;
  wire g_io_r_resp_3_bits_hit;  wire i_io_r_resp_3_bits_hit;
  wire [35:0] g_io_r_resp_3_bits_ppn_0;  wire [35:0] i_io_r_resp_3_bits_ppn_0;
  wire [1:0] g_io_r_resp_3_bits_pbmt_0;  wire [1:0] i_io_r_resp_3_bits_pbmt_0;
  wire [1:0] g_io_r_resp_3_bits_g_pbmt_0;  wire [1:0] i_io_r_resp_3_bits_g_pbmt_0;
  wire g_io_r_resp_3_bits_perm_0_pf;  wire i_io_r_resp_3_bits_perm_0_pf;
  wire g_io_r_resp_3_bits_perm_0_af;  wire i_io_r_resp_3_bits_perm_0_af;
  wire g_io_r_resp_3_bits_perm_0_v;  wire i_io_r_resp_3_bits_perm_0_v;
  wire g_io_r_resp_3_bits_perm_0_d;  wire i_io_r_resp_3_bits_perm_0_d;
  wire g_io_r_resp_3_bits_perm_0_a;  wire i_io_r_resp_3_bits_perm_0_a;
  wire g_io_r_resp_3_bits_perm_0_u;  wire i_io_r_resp_3_bits_perm_0_u;
  wire g_io_r_resp_3_bits_perm_0_x;  wire i_io_r_resp_3_bits_perm_0_x;
  wire g_io_r_resp_3_bits_perm_0_w;  wire i_io_r_resp_3_bits_perm_0_w;
  wire g_io_r_resp_3_bits_perm_0_r;  wire i_io_r_resp_3_bits_perm_0_r;
  wire g_io_r_resp_3_bits_g_perm_0_pf;  wire i_io_r_resp_3_bits_g_perm_0_pf;
  wire g_io_r_resp_3_bits_g_perm_0_af;  wire i_io_r_resp_3_bits_g_perm_0_af;
  wire g_io_r_resp_3_bits_g_perm_0_d;  wire i_io_r_resp_3_bits_g_perm_0_d;
  wire g_io_r_resp_3_bits_g_perm_0_a;  wire i_io_r_resp_3_bits_g_perm_0_a;
  wire g_io_r_resp_3_bits_g_perm_0_x;  wire i_io_r_resp_3_bits_g_perm_0_x;
  wire g_io_r_resp_3_bits_g_perm_0_w;  wire i_io_r_resp_3_bits_g_perm_0_w;
  wire g_io_r_resp_3_bits_g_perm_0_r;  wire i_io_r_resp_3_bits_g_perm_0_r;
  wire g_io_access_0_touch_ways_valid;  wire i_io_access_0_touch_ways_valid;
  wire [5:0] g_io_access_0_touch_ways_bits;  wire [5:0] i_io_access_0_touch_ways_bits;
  wire g_io_access_1_touch_ways_valid;  wire i_io_access_1_touch_ways_valid;
  wire [5:0] g_io_access_1_touch_ways_bits;  wire [5:0] i_io_access_1_touch_ways_bits;
  wire g_io_access_2_touch_ways_valid;  wire i_io_access_2_touch_ways_valid;
  wire [5:0] g_io_access_2_touch_ways_bits;  wire [5:0] i_io_access_2_touch_ways_bits;
  wire g_io_access_3_touch_ways_valid;  wire i_io_access_3_touch_ways_valid;
  wire [5:0] g_io_access_3_touch_ways_bits;  wire [5:0] i_io_access_3_touch_ways_bits;
  TLBFA_1 u_g_ (.clock(clock), .reset(reset), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_priv_virt(io_csr_priv_virt), .io_r_req_0_valid(io_r_req_0_valid), .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn), .io_r_req_0_bits_s2xlate(io_r_req_0_bits_s2xlate), .io_r_req_1_valid(io_r_req_1_valid), .io_r_req_1_bits_vpn(io_r_req_1_bits_vpn), .io_r_req_1_bits_s2xlate(io_r_req_1_bits_s2xlate), .io_r_req_2_valid(io_r_req_2_valid), .io_r_req_2_bits_vpn(io_r_req_2_bits_vpn), .io_r_req_2_bits_s2xlate(io_r_req_2_bits_s2xlate), .io_r_req_3_valid(io_r_req_3_valid), .io_r_req_3_bits_vpn(io_r_req_3_bits_vpn), .io_r_req_3_bits_s2xlate(io_r_req_3_bits_s2xlate), .io_w_valid(io_w_valid), .io_w_bits_wayIdx(io_w_bits_wayIdx), .io_w_bits_data_s2xlate(io_w_bits_data_s2xlate), .io_w_bits_data_s1_entry_tag(io_w_bits_data_s1_entry_tag), .io_w_bits_data_s1_entry_asid(io_w_bits_data_s1_entry_asid), .io_w_bits_data_s1_entry_vmid(io_w_bits_data_s1_entry_vmid), .io_w_bits_data_s1_entry_n(io_w_bits_data_s1_entry_n), .io_w_bits_data_s1_entry_pbmt(io_w_bits_data_s1_entry_pbmt), .io_w_bits_data_s1_entry_perm_d(io_w_bits_data_s1_entry_perm_d), .io_w_bits_data_s1_entry_perm_a(io_w_bits_data_s1_entry_perm_a), .io_w_bits_data_s1_entry_perm_g(io_w_bits_data_s1_entry_perm_g), .io_w_bits_data_s1_entry_perm_u(io_w_bits_data_s1_entry_perm_u), .io_w_bits_data_s1_entry_perm_x(io_w_bits_data_s1_entry_perm_x), .io_w_bits_data_s1_entry_perm_w(io_w_bits_data_s1_entry_perm_w), .io_w_bits_data_s1_entry_perm_r(io_w_bits_data_s1_entry_perm_r), .io_w_bits_data_s1_entry_level(io_w_bits_data_s1_entry_level), .io_w_bits_data_s1_entry_v(io_w_bits_data_s1_entry_v), .io_w_bits_data_s1_entry_ppn(io_w_bits_data_s1_entry_ppn), .io_w_bits_data_s1_ppn_low_0(io_w_bits_data_s1_ppn_low_0), .io_w_bits_data_s1_ppn_low_1(io_w_bits_data_s1_ppn_low_1), .io_w_bits_data_s1_ppn_low_2(io_w_bits_data_s1_ppn_low_2), .io_w_bits_data_s1_ppn_low_3(io_w_bits_data_s1_ppn_low_3), .io_w_bits_data_s1_ppn_low_4(io_w_bits_data_s1_ppn_low_4), .io_w_bits_data_s1_ppn_low_5(io_w_bits_data_s1_ppn_low_5), .io_w_bits_data_s1_ppn_low_6(io_w_bits_data_s1_ppn_low_6), .io_w_bits_data_s1_ppn_low_7(io_w_bits_data_s1_ppn_low_7), .io_w_bits_data_s1_valididx_0(io_w_bits_data_s1_valididx_0), .io_w_bits_data_s1_valididx_1(io_w_bits_data_s1_valididx_1), .io_w_bits_data_s1_valididx_2(io_w_bits_data_s1_valididx_2), .io_w_bits_data_s1_valididx_3(io_w_bits_data_s1_valididx_3), .io_w_bits_data_s1_valididx_4(io_w_bits_data_s1_valididx_4), .io_w_bits_data_s1_valididx_5(io_w_bits_data_s1_valididx_5), .io_w_bits_data_s1_valididx_6(io_w_bits_data_s1_valididx_6), .io_w_bits_data_s1_valididx_7(io_w_bits_data_s1_valididx_7), .io_w_bits_data_s1_pteidx_0(io_w_bits_data_s1_pteidx_0), .io_w_bits_data_s1_pteidx_1(io_w_bits_data_s1_pteidx_1), .io_w_bits_data_s1_pteidx_2(io_w_bits_data_s1_pteidx_2), .io_w_bits_data_s1_pteidx_3(io_w_bits_data_s1_pteidx_3), .io_w_bits_data_s1_pteidx_4(io_w_bits_data_s1_pteidx_4), .io_w_bits_data_s1_pteidx_5(io_w_bits_data_s1_pteidx_5), .io_w_bits_data_s1_pteidx_6(io_w_bits_data_s1_pteidx_6), .io_w_bits_data_s1_pteidx_7(io_w_bits_data_s1_pteidx_7), .io_w_bits_data_s1_pf(io_w_bits_data_s1_pf), .io_w_bits_data_s1_af(io_w_bits_data_s1_af), .io_w_bits_data_s2_entry_tag(io_w_bits_data_s2_entry_tag), .io_w_bits_data_s2_entry_vmid(io_w_bits_data_s2_entry_vmid), .io_w_bits_data_s2_entry_n(io_w_bits_data_s2_entry_n), .io_w_bits_data_s2_entry_pbmt(io_w_bits_data_s2_entry_pbmt), .io_w_bits_data_s2_entry_ppn(io_w_bits_data_s2_entry_ppn), .io_w_bits_data_s2_entry_perm_d(io_w_bits_data_s2_entry_perm_d), .io_w_bits_data_s2_entry_perm_a(io_w_bits_data_s2_entry_perm_a), .io_w_bits_data_s2_entry_perm_g(io_w_bits_data_s2_entry_perm_g), .io_w_bits_data_s2_entry_perm_u(io_w_bits_data_s2_entry_perm_u), .io_w_bits_data_s2_entry_perm_x(io_w_bits_data_s2_entry_perm_x), .io_w_bits_data_s2_entry_perm_w(io_w_bits_data_s2_entry_perm_w), .io_w_bits_data_s2_entry_perm_r(io_w_bits_data_s2_entry_perm_r), .io_w_bits_data_s2_entry_level(io_w_bits_data_s2_entry_level), .io_w_bits_data_s2_gpf(io_w_bits_data_s2_gpf), .io_w_bits_data_s2_gaf(io_w_bits_data_s2_gaf), .io_r_resp_0_bits_hit(g_io_r_resp_0_bits_hit), .io_r_resp_0_bits_ppn_0(g_io_r_resp_0_bits_ppn_0), .io_r_resp_0_bits_ppn_1(g_io_r_resp_0_bits_ppn_1), .io_r_resp_0_bits_pbmt_0(g_io_r_resp_0_bits_pbmt_0), .io_r_resp_0_bits_g_pbmt_0(g_io_r_resp_0_bits_g_pbmt_0), .io_r_resp_0_bits_perm_0_pf(g_io_r_resp_0_bits_perm_0_pf), .io_r_resp_0_bits_perm_0_af(g_io_r_resp_0_bits_perm_0_af), .io_r_resp_0_bits_perm_0_v(g_io_r_resp_0_bits_perm_0_v), .io_r_resp_0_bits_perm_0_d(g_io_r_resp_0_bits_perm_0_d), .io_r_resp_0_bits_perm_0_a(g_io_r_resp_0_bits_perm_0_a), .io_r_resp_0_bits_perm_0_u(g_io_r_resp_0_bits_perm_0_u), .io_r_resp_0_bits_perm_0_x(g_io_r_resp_0_bits_perm_0_x), .io_r_resp_0_bits_perm_0_w(g_io_r_resp_0_bits_perm_0_w), .io_r_resp_0_bits_perm_0_r(g_io_r_resp_0_bits_perm_0_r), .io_r_resp_0_bits_perm_1_pf(g_io_r_resp_0_bits_perm_1_pf), .io_r_resp_0_bits_perm_1_af(g_io_r_resp_0_bits_perm_1_af), .io_r_resp_0_bits_perm_1_v(g_io_r_resp_0_bits_perm_1_v), .io_r_resp_0_bits_perm_1_x(g_io_r_resp_0_bits_perm_1_x), .io_r_resp_0_bits_perm_1_w(g_io_r_resp_0_bits_perm_1_w), .io_r_resp_0_bits_perm_1_r(g_io_r_resp_0_bits_perm_1_r), .io_r_resp_0_bits_g_perm_0_pf(g_io_r_resp_0_bits_g_perm_0_pf), .io_r_resp_0_bits_g_perm_0_af(g_io_r_resp_0_bits_g_perm_0_af), .io_r_resp_0_bits_g_perm_0_d(g_io_r_resp_0_bits_g_perm_0_d), .io_r_resp_0_bits_g_perm_0_a(g_io_r_resp_0_bits_g_perm_0_a), .io_r_resp_0_bits_g_perm_0_x(g_io_r_resp_0_bits_g_perm_0_x), .io_r_resp_0_bits_g_perm_0_w(g_io_r_resp_0_bits_g_perm_0_w), .io_r_resp_0_bits_g_perm_0_r(g_io_r_resp_0_bits_g_perm_0_r), .io_r_resp_0_bits_s2xlate_0(g_io_r_resp_0_bits_s2xlate_0), .io_r_resp_1_bits_hit(g_io_r_resp_1_bits_hit), .io_r_resp_1_bits_ppn_0(g_io_r_resp_1_bits_ppn_0), .io_r_resp_1_bits_ppn_1(g_io_r_resp_1_bits_ppn_1), .io_r_resp_1_bits_pbmt_0(g_io_r_resp_1_bits_pbmt_0), .io_r_resp_1_bits_g_pbmt_0(g_io_r_resp_1_bits_g_pbmt_0), .io_r_resp_1_bits_perm_0_pf(g_io_r_resp_1_bits_perm_0_pf), .io_r_resp_1_bits_perm_0_af(g_io_r_resp_1_bits_perm_0_af), .io_r_resp_1_bits_perm_0_v(g_io_r_resp_1_bits_perm_0_v), .io_r_resp_1_bits_perm_0_d(g_io_r_resp_1_bits_perm_0_d), .io_r_resp_1_bits_perm_0_a(g_io_r_resp_1_bits_perm_0_a), .io_r_resp_1_bits_perm_0_u(g_io_r_resp_1_bits_perm_0_u), .io_r_resp_1_bits_perm_0_x(g_io_r_resp_1_bits_perm_0_x), .io_r_resp_1_bits_perm_0_w(g_io_r_resp_1_bits_perm_0_w), .io_r_resp_1_bits_perm_0_r(g_io_r_resp_1_bits_perm_0_r), .io_r_resp_1_bits_perm_1_pf(g_io_r_resp_1_bits_perm_1_pf), .io_r_resp_1_bits_perm_1_af(g_io_r_resp_1_bits_perm_1_af), .io_r_resp_1_bits_perm_1_v(g_io_r_resp_1_bits_perm_1_v), .io_r_resp_1_bits_perm_1_x(g_io_r_resp_1_bits_perm_1_x), .io_r_resp_1_bits_perm_1_w(g_io_r_resp_1_bits_perm_1_w), .io_r_resp_1_bits_perm_1_r(g_io_r_resp_1_bits_perm_1_r), .io_r_resp_1_bits_g_perm_0_pf(g_io_r_resp_1_bits_g_perm_0_pf), .io_r_resp_1_bits_g_perm_0_af(g_io_r_resp_1_bits_g_perm_0_af), .io_r_resp_1_bits_g_perm_0_d(g_io_r_resp_1_bits_g_perm_0_d), .io_r_resp_1_bits_g_perm_0_a(g_io_r_resp_1_bits_g_perm_0_a), .io_r_resp_1_bits_g_perm_0_x(g_io_r_resp_1_bits_g_perm_0_x), .io_r_resp_1_bits_g_perm_0_w(g_io_r_resp_1_bits_g_perm_0_w), .io_r_resp_1_bits_g_perm_0_r(g_io_r_resp_1_bits_g_perm_0_r), .io_r_resp_1_bits_s2xlate_0(g_io_r_resp_1_bits_s2xlate_0), .io_r_resp_2_bits_hit(g_io_r_resp_2_bits_hit), .io_r_resp_2_bits_ppn_0(g_io_r_resp_2_bits_ppn_0), .io_r_resp_2_bits_ppn_1(g_io_r_resp_2_bits_ppn_1), .io_r_resp_2_bits_pbmt_0(g_io_r_resp_2_bits_pbmt_0), .io_r_resp_2_bits_g_pbmt_0(g_io_r_resp_2_bits_g_pbmt_0), .io_r_resp_2_bits_perm_0_pf(g_io_r_resp_2_bits_perm_0_pf), .io_r_resp_2_bits_perm_0_af(g_io_r_resp_2_bits_perm_0_af), .io_r_resp_2_bits_perm_0_v(g_io_r_resp_2_bits_perm_0_v), .io_r_resp_2_bits_perm_0_d(g_io_r_resp_2_bits_perm_0_d), .io_r_resp_2_bits_perm_0_a(g_io_r_resp_2_bits_perm_0_a), .io_r_resp_2_bits_perm_0_u(g_io_r_resp_2_bits_perm_0_u), .io_r_resp_2_bits_perm_0_x(g_io_r_resp_2_bits_perm_0_x), .io_r_resp_2_bits_perm_0_w(g_io_r_resp_2_bits_perm_0_w), .io_r_resp_2_bits_perm_0_r(g_io_r_resp_2_bits_perm_0_r), .io_r_resp_2_bits_perm_1_pf(g_io_r_resp_2_bits_perm_1_pf), .io_r_resp_2_bits_perm_1_af(g_io_r_resp_2_bits_perm_1_af), .io_r_resp_2_bits_perm_1_v(g_io_r_resp_2_bits_perm_1_v), .io_r_resp_2_bits_perm_1_x(g_io_r_resp_2_bits_perm_1_x), .io_r_resp_2_bits_perm_1_w(g_io_r_resp_2_bits_perm_1_w), .io_r_resp_2_bits_perm_1_r(g_io_r_resp_2_bits_perm_1_r), .io_r_resp_2_bits_g_perm_0_pf(g_io_r_resp_2_bits_g_perm_0_pf), .io_r_resp_2_bits_g_perm_0_af(g_io_r_resp_2_bits_g_perm_0_af), .io_r_resp_2_bits_g_perm_0_d(g_io_r_resp_2_bits_g_perm_0_d), .io_r_resp_2_bits_g_perm_0_a(g_io_r_resp_2_bits_g_perm_0_a), .io_r_resp_2_bits_g_perm_0_x(g_io_r_resp_2_bits_g_perm_0_x), .io_r_resp_2_bits_g_perm_0_w(g_io_r_resp_2_bits_g_perm_0_w), .io_r_resp_2_bits_g_perm_0_r(g_io_r_resp_2_bits_g_perm_0_r), .io_r_resp_2_bits_s2xlate_0(g_io_r_resp_2_bits_s2xlate_0), .io_r_resp_3_bits_hit(g_io_r_resp_3_bits_hit), .io_r_resp_3_bits_ppn_0(g_io_r_resp_3_bits_ppn_0), .io_r_resp_3_bits_pbmt_0(g_io_r_resp_3_bits_pbmt_0), .io_r_resp_3_bits_g_pbmt_0(g_io_r_resp_3_bits_g_pbmt_0), .io_r_resp_3_bits_perm_0_pf(g_io_r_resp_3_bits_perm_0_pf), .io_r_resp_3_bits_perm_0_af(g_io_r_resp_3_bits_perm_0_af), .io_r_resp_3_bits_perm_0_v(g_io_r_resp_3_bits_perm_0_v), .io_r_resp_3_bits_perm_0_d(g_io_r_resp_3_bits_perm_0_d), .io_r_resp_3_bits_perm_0_a(g_io_r_resp_3_bits_perm_0_a), .io_r_resp_3_bits_perm_0_u(g_io_r_resp_3_bits_perm_0_u), .io_r_resp_3_bits_perm_0_x(g_io_r_resp_3_bits_perm_0_x), .io_r_resp_3_bits_perm_0_w(g_io_r_resp_3_bits_perm_0_w), .io_r_resp_3_bits_perm_0_r(g_io_r_resp_3_bits_perm_0_r), .io_r_resp_3_bits_g_perm_0_pf(g_io_r_resp_3_bits_g_perm_0_pf), .io_r_resp_3_bits_g_perm_0_af(g_io_r_resp_3_bits_g_perm_0_af), .io_r_resp_3_bits_g_perm_0_d(g_io_r_resp_3_bits_g_perm_0_d), .io_r_resp_3_bits_g_perm_0_a(g_io_r_resp_3_bits_g_perm_0_a), .io_r_resp_3_bits_g_perm_0_x(g_io_r_resp_3_bits_g_perm_0_x), .io_r_resp_3_bits_g_perm_0_w(g_io_r_resp_3_bits_g_perm_0_w), .io_r_resp_3_bits_g_perm_0_r(g_io_r_resp_3_bits_g_perm_0_r), .io_access_0_touch_ways_valid(g_io_access_0_touch_ways_valid), .io_access_0_touch_ways_bits(g_io_access_0_touch_ways_bits), .io_access_1_touch_ways_valid(g_io_access_1_touch_ways_valid), .io_access_1_touch_ways_bits(g_io_access_1_touch_ways_bits), .io_access_2_touch_ways_valid(g_io_access_2_touch_ways_valid), .io_access_2_touch_ways_bits(g_io_access_2_touch_ways_bits), .io_access_3_touch_ways_valid(g_io_access_3_touch_ways_valid), .io_access_3_touch_ways_bits(g_io_access_3_touch_ways_bits));
  TLBFA_1_xs u_i_ (.clock(clock), .reset(reset), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_priv_virt(io_csr_priv_virt), .io_r_req_0_valid(io_r_req_0_valid), .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn), .io_r_req_0_bits_s2xlate(io_r_req_0_bits_s2xlate), .io_r_req_1_valid(io_r_req_1_valid), .io_r_req_1_bits_vpn(io_r_req_1_bits_vpn), .io_r_req_1_bits_s2xlate(io_r_req_1_bits_s2xlate), .io_r_req_2_valid(io_r_req_2_valid), .io_r_req_2_bits_vpn(io_r_req_2_bits_vpn), .io_r_req_2_bits_s2xlate(io_r_req_2_bits_s2xlate), .io_r_req_3_valid(io_r_req_3_valid), .io_r_req_3_bits_vpn(io_r_req_3_bits_vpn), .io_r_req_3_bits_s2xlate(io_r_req_3_bits_s2xlate), .io_w_valid(io_w_valid), .io_w_bits_wayIdx(io_w_bits_wayIdx), .io_w_bits_data_s2xlate(io_w_bits_data_s2xlate), .io_w_bits_data_s1_entry_tag(io_w_bits_data_s1_entry_tag), .io_w_bits_data_s1_entry_asid(io_w_bits_data_s1_entry_asid), .io_w_bits_data_s1_entry_vmid(io_w_bits_data_s1_entry_vmid), .io_w_bits_data_s1_entry_n(io_w_bits_data_s1_entry_n), .io_w_bits_data_s1_entry_pbmt(io_w_bits_data_s1_entry_pbmt), .io_w_bits_data_s1_entry_perm_d(io_w_bits_data_s1_entry_perm_d), .io_w_bits_data_s1_entry_perm_a(io_w_bits_data_s1_entry_perm_a), .io_w_bits_data_s1_entry_perm_g(io_w_bits_data_s1_entry_perm_g), .io_w_bits_data_s1_entry_perm_u(io_w_bits_data_s1_entry_perm_u), .io_w_bits_data_s1_entry_perm_x(io_w_bits_data_s1_entry_perm_x), .io_w_bits_data_s1_entry_perm_w(io_w_bits_data_s1_entry_perm_w), .io_w_bits_data_s1_entry_perm_r(io_w_bits_data_s1_entry_perm_r), .io_w_bits_data_s1_entry_level(io_w_bits_data_s1_entry_level), .io_w_bits_data_s1_entry_v(io_w_bits_data_s1_entry_v), .io_w_bits_data_s1_entry_ppn(io_w_bits_data_s1_entry_ppn), .io_w_bits_data_s1_ppn_low_0(io_w_bits_data_s1_ppn_low_0), .io_w_bits_data_s1_ppn_low_1(io_w_bits_data_s1_ppn_low_1), .io_w_bits_data_s1_ppn_low_2(io_w_bits_data_s1_ppn_low_2), .io_w_bits_data_s1_ppn_low_3(io_w_bits_data_s1_ppn_low_3), .io_w_bits_data_s1_ppn_low_4(io_w_bits_data_s1_ppn_low_4), .io_w_bits_data_s1_ppn_low_5(io_w_bits_data_s1_ppn_low_5), .io_w_bits_data_s1_ppn_low_6(io_w_bits_data_s1_ppn_low_6), .io_w_bits_data_s1_ppn_low_7(io_w_bits_data_s1_ppn_low_7), .io_w_bits_data_s1_valididx_0(io_w_bits_data_s1_valididx_0), .io_w_bits_data_s1_valididx_1(io_w_bits_data_s1_valididx_1), .io_w_bits_data_s1_valididx_2(io_w_bits_data_s1_valididx_2), .io_w_bits_data_s1_valididx_3(io_w_bits_data_s1_valididx_3), .io_w_bits_data_s1_valididx_4(io_w_bits_data_s1_valididx_4), .io_w_bits_data_s1_valididx_5(io_w_bits_data_s1_valididx_5), .io_w_bits_data_s1_valididx_6(io_w_bits_data_s1_valididx_6), .io_w_bits_data_s1_valididx_7(io_w_bits_data_s1_valididx_7), .io_w_bits_data_s1_pteidx_0(io_w_bits_data_s1_pteidx_0), .io_w_bits_data_s1_pteidx_1(io_w_bits_data_s1_pteidx_1), .io_w_bits_data_s1_pteidx_2(io_w_bits_data_s1_pteidx_2), .io_w_bits_data_s1_pteidx_3(io_w_bits_data_s1_pteidx_3), .io_w_bits_data_s1_pteidx_4(io_w_bits_data_s1_pteidx_4), .io_w_bits_data_s1_pteidx_5(io_w_bits_data_s1_pteidx_5), .io_w_bits_data_s1_pteidx_6(io_w_bits_data_s1_pteidx_6), .io_w_bits_data_s1_pteidx_7(io_w_bits_data_s1_pteidx_7), .io_w_bits_data_s1_pf(io_w_bits_data_s1_pf), .io_w_bits_data_s1_af(io_w_bits_data_s1_af), .io_w_bits_data_s2_entry_tag(io_w_bits_data_s2_entry_tag), .io_w_bits_data_s2_entry_vmid(io_w_bits_data_s2_entry_vmid), .io_w_bits_data_s2_entry_n(io_w_bits_data_s2_entry_n), .io_w_bits_data_s2_entry_pbmt(io_w_bits_data_s2_entry_pbmt), .io_w_bits_data_s2_entry_ppn(io_w_bits_data_s2_entry_ppn), .io_w_bits_data_s2_entry_perm_d(io_w_bits_data_s2_entry_perm_d), .io_w_bits_data_s2_entry_perm_a(io_w_bits_data_s2_entry_perm_a), .io_w_bits_data_s2_entry_perm_g(io_w_bits_data_s2_entry_perm_g), .io_w_bits_data_s2_entry_perm_u(io_w_bits_data_s2_entry_perm_u), .io_w_bits_data_s2_entry_perm_x(io_w_bits_data_s2_entry_perm_x), .io_w_bits_data_s2_entry_perm_w(io_w_bits_data_s2_entry_perm_w), .io_w_bits_data_s2_entry_perm_r(io_w_bits_data_s2_entry_perm_r), .io_w_bits_data_s2_entry_level(io_w_bits_data_s2_entry_level), .io_w_bits_data_s2_gpf(io_w_bits_data_s2_gpf), .io_w_bits_data_s2_gaf(io_w_bits_data_s2_gaf), .io_r_resp_0_bits_hit(i_io_r_resp_0_bits_hit), .io_r_resp_0_bits_ppn_0(i_io_r_resp_0_bits_ppn_0), .io_r_resp_0_bits_ppn_1(i_io_r_resp_0_bits_ppn_1), .io_r_resp_0_bits_pbmt_0(i_io_r_resp_0_bits_pbmt_0), .io_r_resp_0_bits_g_pbmt_0(i_io_r_resp_0_bits_g_pbmt_0), .io_r_resp_0_bits_perm_0_pf(i_io_r_resp_0_bits_perm_0_pf), .io_r_resp_0_bits_perm_0_af(i_io_r_resp_0_bits_perm_0_af), .io_r_resp_0_bits_perm_0_v(i_io_r_resp_0_bits_perm_0_v), .io_r_resp_0_bits_perm_0_d(i_io_r_resp_0_bits_perm_0_d), .io_r_resp_0_bits_perm_0_a(i_io_r_resp_0_bits_perm_0_a), .io_r_resp_0_bits_perm_0_u(i_io_r_resp_0_bits_perm_0_u), .io_r_resp_0_bits_perm_0_x(i_io_r_resp_0_bits_perm_0_x), .io_r_resp_0_bits_perm_0_w(i_io_r_resp_0_bits_perm_0_w), .io_r_resp_0_bits_perm_0_r(i_io_r_resp_0_bits_perm_0_r), .io_r_resp_0_bits_perm_1_pf(i_io_r_resp_0_bits_perm_1_pf), .io_r_resp_0_bits_perm_1_af(i_io_r_resp_0_bits_perm_1_af), .io_r_resp_0_bits_perm_1_v(i_io_r_resp_0_bits_perm_1_v), .io_r_resp_0_bits_perm_1_x(i_io_r_resp_0_bits_perm_1_x), .io_r_resp_0_bits_perm_1_w(i_io_r_resp_0_bits_perm_1_w), .io_r_resp_0_bits_perm_1_r(i_io_r_resp_0_bits_perm_1_r), .io_r_resp_0_bits_g_perm_0_pf(i_io_r_resp_0_bits_g_perm_0_pf), .io_r_resp_0_bits_g_perm_0_af(i_io_r_resp_0_bits_g_perm_0_af), .io_r_resp_0_bits_g_perm_0_d(i_io_r_resp_0_bits_g_perm_0_d), .io_r_resp_0_bits_g_perm_0_a(i_io_r_resp_0_bits_g_perm_0_a), .io_r_resp_0_bits_g_perm_0_x(i_io_r_resp_0_bits_g_perm_0_x), .io_r_resp_0_bits_g_perm_0_w(i_io_r_resp_0_bits_g_perm_0_w), .io_r_resp_0_bits_g_perm_0_r(i_io_r_resp_0_bits_g_perm_0_r), .io_r_resp_0_bits_s2xlate_0(i_io_r_resp_0_bits_s2xlate_0), .io_r_resp_1_bits_hit(i_io_r_resp_1_bits_hit), .io_r_resp_1_bits_ppn_0(i_io_r_resp_1_bits_ppn_0), .io_r_resp_1_bits_ppn_1(i_io_r_resp_1_bits_ppn_1), .io_r_resp_1_bits_pbmt_0(i_io_r_resp_1_bits_pbmt_0), .io_r_resp_1_bits_g_pbmt_0(i_io_r_resp_1_bits_g_pbmt_0), .io_r_resp_1_bits_perm_0_pf(i_io_r_resp_1_bits_perm_0_pf), .io_r_resp_1_bits_perm_0_af(i_io_r_resp_1_bits_perm_0_af), .io_r_resp_1_bits_perm_0_v(i_io_r_resp_1_bits_perm_0_v), .io_r_resp_1_bits_perm_0_d(i_io_r_resp_1_bits_perm_0_d), .io_r_resp_1_bits_perm_0_a(i_io_r_resp_1_bits_perm_0_a), .io_r_resp_1_bits_perm_0_u(i_io_r_resp_1_bits_perm_0_u), .io_r_resp_1_bits_perm_0_x(i_io_r_resp_1_bits_perm_0_x), .io_r_resp_1_bits_perm_0_w(i_io_r_resp_1_bits_perm_0_w), .io_r_resp_1_bits_perm_0_r(i_io_r_resp_1_bits_perm_0_r), .io_r_resp_1_bits_perm_1_pf(i_io_r_resp_1_bits_perm_1_pf), .io_r_resp_1_bits_perm_1_af(i_io_r_resp_1_bits_perm_1_af), .io_r_resp_1_bits_perm_1_v(i_io_r_resp_1_bits_perm_1_v), .io_r_resp_1_bits_perm_1_x(i_io_r_resp_1_bits_perm_1_x), .io_r_resp_1_bits_perm_1_w(i_io_r_resp_1_bits_perm_1_w), .io_r_resp_1_bits_perm_1_r(i_io_r_resp_1_bits_perm_1_r), .io_r_resp_1_bits_g_perm_0_pf(i_io_r_resp_1_bits_g_perm_0_pf), .io_r_resp_1_bits_g_perm_0_af(i_io_r_resp_1_bits_g_perm_0_af), .io_r_resp_1_bits_g_perm_0_d(i_io_r_resp_1_bits_g_perm_0_d), .io_r_resp_1_bits_g_perm_0_a(i_io_r_resp_1_bits_g_perm_0_a), .io_r_resp_1_bits_g_perm_0_x(i_io_r_resp_1_bits_g_perm_0_x), .io_r_resp_1_bits_g_perm_0_w(i_io_r_resp_1_bits_g_perm_0_w), .io_r_resp_1_bits_g_perm_0_r(i_io_r_resp_1_bits_g_perm_0_r), .io_r_resp_1_bits_s2xlate_0(i_io_r_resp_1_bits_s2xlate_0), .io_r_resp_2_bits_hit(i_io_r_resp_2_bits_hit), .io_r_resp_2_bits_ppn_0(i_io_r_resp_2_bits_ppn_0), .io_r_resp_2_bits_ppn_1(i_io_r_resp_2_bits_ppn_1), .io_r_resp_2_bits_pbmt_0(i_io_r_resp_2_bits_pbmt_0), .io_r_resp_2_bits_g_pbmt_0(i_io_r_resp_2_bits_g_pbmt_0), .io_r_resp_2_bits_perm_0_pf(i_io_r_resp_2_bits_perm_0_pf), .io_r_resp_2_bits_perm_0_af(i_io_r_resp_2_bits_perm_0_af), .io_r_resp_2_bits_perm_0_v(i_io_r_resp_2_bits_perm_0_v), .io_r_resp_2_bits_perm_0_d(i_io_r_resp_2_bits_perm_0_d), .io_r_resp_2_bits_perm_0_a(i_io_r_resp_2_bits_perm_0_a), .io_r_resp_2_bits_perm_0_u(i_io_r_resp_2_bits_perm_0_u), .io_r_resp_2_bits_perm_0_x(i_io_r_resp_2_bits_perm_0_x), .io_r_resp_2_bits_perm_0_w(i_io_r_resp_2_bits_perm_0_w), .io_r_resp_2_bits_perm_0_r(i_io_r_resp_2_bits_perm_0_r), .io_r_resp_2_bits_perm_1_pf(i_io_r_resp_2_bits_perm_1_pf), .io_r_resp_2_bits_perm_1_af(i_io_r_resp_2_bits_perm_1_af), .io_r_resp_2_bits_perm_1_v(i_io_r_resp_2_bits_perm_1_v), .io_r_resp_2_bits_perm_1_x(i_io_r_resp_2_bits_perm_1_x), .io_r_resp_2_bits_perm_1_w(i_io_r_resp_2_bits_perm_1_w), .io_r_resp_2_bits_perm_1_r(i_io_r_resp_2_bits_perm_1_r), .io_r_resp_2_bits_g_perm_0_pf(i_io_r_resp_2_bits_g_perm_0_pf), .io_r_resp_2_bits_g_perm_0_af(i_io_r_resp_2_bits_g_perm_0_af), .io_r_resp_2_bits_g_perm_0_d(i_io_r_resp_2_bits_g_perm_0_d), .io_r_resp_2_bits_g_perm_0_a(i_io_r_resp_2_bits_g_perm_0_a), .io_r_resp_2_bits_g_perm_0_x(i_io_r_resp_2_bits_g_perm_0_x), .io_r_resp_2_bits_g_perm_0_w(i_io_r_resp_2_bits_g_perm_0_w), .io_r_resp_2_bits_g_perm_0_r(i_io_r_resp_2_bits_g_perm_0_r), .io_r_resp_2_bits_s2xlate_0(i_io_r_resp_2_bits_s2xlate_0), .io_r_resp_3_bits_hit(i_io_r_resp_3_bits_hit), .io_r_resp_3_bits_ppn_0(i_io_r_resp_3_bits_ppn_0), .io_r_resp_3_bits_pbmt_0(i_io_r_resp_3_bits_pbmt_0), .io_r_resp_3_bits_g_pbmt_0(i_io_r_resp_3_bits_g_pbmt_0), .io_r_resp_3_bits_perm_0_pf(i_io_r_resp_3_bits_perm_0_pf), .io_r_resp_3_bits_perm_0_af(i_io_r_resp_3_bits_perm_0_af), .io_r_resp_3_bits_perm_0_v(i_io_r_resp_3_bits_perm_0_v), .io_r_resp_3_bits_perm_0_d(i_io_r_resp_3_bits_perm_0_d), .io_r_resp_3_bits_perm_0_a(i_io_r_resp_3_bits_perm_0_a), .io_r_resp_3_bits_perm_0_u(i_io_r_resp_3_bits_perm_0_u), .io_r_resp_3_bits_perm_0_x(i_io_r_resp_3_bits_perm_0_x), .io_r_resp_3_bits_perm_0_w(i_io_r_resp_3_bits_perm_0_w), .io_r_resp_3_bits_perm_0_r(i_io_r_resp_3_bits_perm_0_r), .io_r_resp_3_bits_g_perm_0_pf(i_io_r_resp_3_bits_g_perm_0_pf), .io_r_resp_3_bits_g_perm_0_af(i_io_r_resp_3_bits_g_perm_0_af), .io_r_resp_3_bits_g_perm_0_d(i_io_r_resp_3_bits_g_perm_0_d), .io_r_resp_3_bits_g_perm_0_a(i_io_r_resp_3_bits_g_perm_0_a), .io_r_resp_3_bits_g_perm_0_x(i_io_r_resp_3_bits_g_perm_0_x), .io_r_resp_3_bits_g_perm_0_w(i_io_r_resp_3_bits_g_perm_0_w), .io_r_resp_3_bits_g_perm_0_r(i_io_r_resp_3_bits_g_perm_0_r), .io_access_0_touch_ways_valid(i_io_access_0_touch_ways_valid), .io_access_0_touch_ways_bits(i_io_access_0_touch_ways_bits), .io_access_1_touch_ways_valid(i_io_access_1_touch_ways_valid), .io_access_1_touch_ways_bits(i_io_access_1_touch_ways_bits), .io_access_2_touch_ways_valid(i_io_access_2_touch_ways_valid), .io_access_2_touch_ways_bits(i_io_access_2_touch_ways_bits), .io_access_3_touch_ways_valid(i_io_access_3_touch_ways_valid), .io_access_3_touch_ways_bits(i_io_access_3_touch_ways_bits));
  task automatic do_check(int t);
    checks++;
    if (g_io_r_resp_0_bits_hit !== i_io_r_resp_0_bits_hit) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_hit g=%b i=%b",t,g_io_r_resp_0_bits_hit,i_io_r_resp_0_bits_hit); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_ppn_0 !== i_io_r_resp_0_bits_ppn_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_0_bits_ppn_0,i_io_r_resp_0_bits_ppn_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_ppn_1 !== i_io_r_resp_0_bits_ppn_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_0_bits_ppn_1,i_io_r_resp_0_bits_ppn_1); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_pbmt_0 !== i_io_r_resp_0_bits_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_0_bits_pbmt_0,i_io_r_resp_0_bits_pbmt_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_pbmt_0 !== i_io_r_resp_0_bits_g_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_0_bits_g_pbmt_0,i_io_r_resp_0_bits_g_pbmt_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_pf !== i_io_r_resp_0_bits_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_pf g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_pf,i_io_r_resp_0_bits_perm_0_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_af !== i_io_r_resp_0_bits_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_af g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_af,i_io_r_resp_0_bits_perm_0_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_v !== i_io_r_resp_0_bits_perm_0_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_v g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_v,i_io_r_resp_0_bits_perm_0_v); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_d !== i_io_r_resp_0_bits_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_d g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_d,i_io_r_resp_0_bits_perm_0_d); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_a !== i_io_r_resp_0_bits_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_a g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_a,i_io_r_resp_0_bits_perm_0_a); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_u !== i_io_r_resp_0_bits_perm_0_u)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_u g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_u,i_io_r_resp_0_bits_perm_0_u); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_x !== i_io_r_resp_0_bits_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_x g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_x,i_io_r_resp_0_bits_perm_0_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_w !== i_io_r_resp_0_bits_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_w g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_w,i_io_r_resp_0_bits_perm_0_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_r !== i_io_r_resp_0_bits_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_0_r g=%h i=%h",t,g_io_r_resp_0_bits_perm_0_r,i_io_r_resp_0_bits_perm_0_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_pf !== i_io_r_resp_0_bits_perm_1_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_pf g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_pf,i_io_r_resp_0_bits_perm_1_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_af !== i_io_r_resp_0_bits_perm_1_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_af g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_af,i_io_r_resp_0_bits_perm_1_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_v !== i_io_r_resp_0_bits_perm_1_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_v g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_v,i_io_r_resp_0_bits_perm_1_v); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_x !== i_io_r_resp_0_bits_perm_1_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_x g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_x,i_io_r_resp_0_bits_perm_1_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_w !== i_io_r_resp_0_bits_perm_1_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_w g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_w,i_io_r_resp_0_bits_perm_1_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_r !== i_io_r_resp_0_bits_perm_1_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_perm_1_r g=%h i=%h",t,g_io_r_resp_0_bits_perm_1_r,i_io_r_resp_0_bits_perm_1_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_pf !== i_io_r_resp_0_bits_g_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_pf g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_pf,i_io_r_resp_0_bits_g_perm_0_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_af !== i_io_r_resp_0_bits_g_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_af g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_af,i_io_r_resp_0_bits_g_perm_0_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_d !== i_io_r_resp_0_bits_g_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_d g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_d,i_io_r_resp_0_bits_g_perm_0_d); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_a !== i_io_r_resp_0_bits_g_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_a g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_a,i_io_r_resp_0_bits_g_perm_0_a); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_x !== i_io_r_resp_0_bits_g_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_x g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_x,i_io_r_resp_0_bits_g_perm_0_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_w !== i_io_r_resp_0_bits_g_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_w g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_w,i_io_r_resp_0_bits_g_perm_0_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_r !== i_io_r_resp_0_bits_g_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_g_perm_0_r g=%h i=%h",t,g_io_r_resp_0_bits_g_perm_0_r,i_io_r_resp_0_bits_g_perm_0_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_s2xlate_0 !== i_io_r_resp_0_bits_s2xlate_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_0_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_0_bits_s2xlate_0,i_io_r_resp_0_bits_s2xlate_0); end
    if (g_io_access_0_touch_ways_valid !== i_io_access_0_touch_ways_valid) begin errors++;
      if(errors<=60) $display("vec %0d io_access_0_touch_ways_valid g=%b i=%b",t,g_io_access_0_touch_ways_valid,i_io_access_0_touch_ways_valid); end
    if (g_io_access_0_touch_ways_valid && (g_io_access_0_touch_ways_bits !== i_io_access_0_touch_ways_bits)) begin errors++;
      if(errors<=60) $display("vec %0d io_access_0_touch_ways_bits g=%h i=%h",t,g_io_access_0_touch_ways_bits,i_io_access_0_touch_ways_bits); end
    if (g_io_r_resp_1_bits_hit !== i_io_r_resp_1_bits_hit) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_hit g=%b i=%b",t,g_io_r_resp_1_bits_hit,i_io_r_resp_1_bits_hit); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_ppn_0 !== i_io_r_resp_1_bits_ppn_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_1_bits_ppn_0,i_io_r_resp_1_bits_ppn_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_ppn_1 !== i_io_r_resp_1_bits_ppn_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_1_bits_ppn_1,i_io_r_resp_1_bits_ppn_1); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_pbmt_0 !== i_io_r_resp_1_bits_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_1_bits_pbmt_0,i_io_r_resp_1_bits_pbmt_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_pbmt_0 !== i_io_r_resp_1_bits_g_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_1_bits_g_pbmt_0,i_io_r_resp_1_bits_g_pbmt_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_pf !== i_io_r_resp_1_bits_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_pf g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_pf,i_io_r_resp_1_bits_perm_0_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_af !== i_io_r_resp_1_bits_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_af g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_af,i_io_r_resp_1_bits_perm_0_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_v !== i_io_r_resp_1_bits_perm_0_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_v g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_v,i_io_r_resp_1_bits_perm_0_v); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_d !== i_io_r_resp_1_bits_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_d g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_d,i_io_r_resp_1_bits_perm_0_d); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_a !== i_io_r_resp_1_bits_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_a g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_a,i_io_r_resp_1_bits_perm_0_a); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_u !== i_io_r_resp_1_bits_perm_0_u)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_u g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_u,i_io_r_resp_1_bits_perm_0_u); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_x !== i_io_r_resp_1_bits_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_x g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_x,i_io_r_resp_1_bits_perm_0_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_w !== i_io_r_resp_1_bits_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_w g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_w,i_io_r_resp_1_bits_perm_0_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_r !== i_io_r_resp_1_bits_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_0_r g=%h i=%h",t,g_io_r_resp_1_bits_perm_0_r,i_io_r_resp_1_bits_perm_0_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_pf !== i_io_r_resp_1_bits_perm_1_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_pf g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_pf,i_io_r_resp_1_bits_perm_1_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_af !== i_io_r_resp_1_bits_perm_1_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_af g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_af,i_io_r_resp_1_bits_perm_1_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_v !== i_io_r_resp_1_bits_perm_1_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_v g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_v,i_io_r_resp_1_bits_perm_1_v); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_x !== i_io_r_resp_1_bits_perm_1_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_x g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_x,i_io_r_resp_1_bits_perm_1_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_w !== i_io_r_resp_1_bits_perm_1_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_w g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_w,i_io_r_resp_1_bits_perm_1_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_r !== i_io_r_resp_1_bits_perm_1_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_perm_1_r g=%h i=%h",t,g_io_r_resp_1_bits_perm_1_r,i_io_r_resp_1_bits_perm_1_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_pf !== i_io_r_resp_1_bits_g_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_pf g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_pf,i_io_r_resp_1_bits_g_perm_0_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_af !== i_io_r_resp_1_bits_g_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_af g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_af,i_io_r_resp_1_bits_g_perm_0_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_d !== i_io_r_resp_1_bits_g_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_d g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_d,i_io_r_resp_1_bits_g_perm_0_d); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_a !== i_io_r_resp_1_bits_g_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_a g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_a,i_io_r_resp_1_bits_g_perm_0_a); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_x !== i_io_r_resp_1_bits_g_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_x g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_x,i_io_r_resp_1_bits_g_perm_0_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_w !== i_io_r_resp_1_bits_g_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_w g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_w,i_io_r_resp_1_bits_g_perm_0_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_r !== i_io_r_resp_1_bits_g_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_g_perm_0_r g=%h i=%h",t,g_io_r_resp_1_bits_g_perm_0_r,i_io_r_resp_1_bits_g_perm_0_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_s2xlate_0 !== i_io_r_resp_1_bits_s2xlate_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_1_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_1_bits_s2xlate_0,i_io_r_resp_1_bits_s2xlate_0); end
    if (g_io_access_1_touch_ways_valid !== i_io_access_1_touch_ways_valid) begin errors++;
      if(errors<=60) $display("vec %0d io_access_1_touch_ways_valid g=%b i=%b",t,g_io_access_1_touch_ways_valid,i_io_access_1_touch_ways_valid); end
    if (g_io_access_1_touch_ways_valid && (g_io_access_1_touch_ways_bits !== i_io_access_1_touch_ways_bits)) begin errors++;
      if(errors<=60) $display("vec %0d io_access_1_touch_ways_bits g=%h i=%h",t,g_io_access_1_touch_ways_bits,i_io_access_1_touch_ways_bits); end
    if (g_io_r_resp_2_bits_hit !== i_io_r_resp_2_bits_hit) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_hit g=%b i=%b",t,g_io_r_resp_2_bits_hit,i_io_r_resp_2_bits_hit); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_ppn_0 !== i_io_r_resp_2_bits_ppn_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_2_bits_ppn_0,i_io_r_resp_2_bits_ppn_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_ppn_1 !== i_io_r_resp_2_bits_ppn_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_2_bits_ppn_1,i_io_r_resp_2_bits_ppn_1); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_pbmt_0 !== i_io_r_resp_2_bits_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_2_bits_pbmt_0,i_io_r_resp_2_bits_pbmt_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_pbmt_0 !== i_io_r_resp_2_bits_g_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_2_bits_g_pbmt_0,i_io_r_resp_2_bits_g_pbmt_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_pf !== i_io_r_resp_2_bits_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_pf g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_pf,i_io_r_resp_2_bits_perm_0_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_af !== i_io_r_resp_2_bits_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_af g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_af,i_io_r_resp_2_bits_perm_0_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_v !== i_io_r_resp_2_bits_perm_0_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_v g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_v,i_io_r_resp_2_bits_perm_0_v); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_d !== i_io_r_resp_2_bits_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_d g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_d,i_io_r_resp_2_bits_perm_0_d); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_a !== i_io_r_resp_2_bits_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_a g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_a,i_io_r_resp_2_bits_perm_0_a); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_u !== i_io_r_resp_2_bits_perm_0_u)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_u g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_u,i_io_r_resp_2_bits_perm_0_u); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_x !== i_io_r_resp_2_bits_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_x g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_x,i_io_r_resp_2_bits_perm_0_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_w !== i_io_r_resp_2_bits_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_w g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_w,i_io_r_resp_2_bits_perm_0_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_r !== i_io_r_resp_2_bits_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_0_r g=%h i=%h",t,g_io_r_resp_2_bits_perm_0_r,i_io_r_resp_2_bits_perm_0_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_pf !== i_io_r_resp_2_bits_perm_1_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_pf g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_pf,i_io_r_resp_2_bits_perm_1_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_af !== i_io_r_resp_2_bits_perm_1_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_af g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_af,i_io_r_resp_2_bits_perm_1_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_v !== i_io_r_resp_2_bits_perm_1_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_v g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_v,i_io_r_resp_2_bits_perm_1_v); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_x !== i_io_r_resp_2_bits_perm_1_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_x g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_x,i_io_r_resp_2_bits_perm_1_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_w !== i_io_r_resp_2_bits_perm_1_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_w g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_w,i_io_r_resp_2_bits_perm_1_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_r !== i_io_r_resp_2_bits_perm_1_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_perm_1_r g=%h i=%h",t,g_io_r_resp_2_bits_perm_1_r,i_io_r_resp_2_bits_perm_1_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_pf !== i_io_r_resp_2_bits_g_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_pf g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_pf,i_io_r_resp_2_bits_g_perm_0_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_af !== i_io_r_resp_2_bits_g_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_af g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_af,i_io_r_resp_2_bits_g_perm_0_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_d !== i_io_r_resp_2_bits_g_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_d g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_d,i_io_r_resp_2_bits_g_perm_0_d); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_a !== i_io_r_resp_2_bits_g_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_a g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_a,i_io_r_resp_2_bits_g_perm_0_a); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_x !== i_io_r_resp_2_bits_g_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_x g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_x,i_io_r_resp_2_bits_g_perm_0_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_w !== i_io_r_resp_2_bits_g_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_w g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_w,i_io_r_resp_2_bits_g_perm_0_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_r !== i_io_r_resp_2_bits_g_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_g_perm_0_r g=%h i=%h",t,g_io_r_resp_2_bits_g_perm_0_r,i_io_r_resp_2_bits_g_perm_0_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_s2xlate_0 !== i_io_r_resp_2_bits_s2xlate_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_2_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_2_bits_s2xlate_0,i_io_r_resp_2_bits_s2xlate_0); end
    if (g_io_access_2_touch_ways_valid !== i_io_access_2_touch_ways_valid) begin errors++;
      if(errors<=60) $display("vec %0d io_access_2_touch_ways_valid g=%b i=%b",t,g_io_access_2_touch_ways_valid,i_io_access_2_touch_ways_valid); end
    if (g_io_access_2_touch_ways_valid && (g_io_access_2_touch_ways_bits !== i_io_access_2_touch_ways_bits)) begin errors++;
      if(errors<=60) $display("vec %0d io_access_2_touch_ways_bits g=%h i=%h",t,g_io_access_2_touch_ways_bits,i_io_access_2_touch_ways_bits); end
    if (g_io_r_resp_3_bits_hit !== i_io_r_resp_3_bits_hit) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_hit g=%b i=%b",t,g_io_r_resp_3_bits_hit,i_io_r_resp_3_bits_hit); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_ppn_0 !== i_io_r_resp_3_bits_ppn_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_3_bits_ppn_0,i_io_r_resp_3_bits_ppn_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_pbmt_0 !== i_io_r_resp_3_bits_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_3_bits_pbmt_0,i_io_r_resp_3_bits_pbmt_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_pbmt_0 !== i_io_r_resp_3_bits_g_pbmt_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_3_bits_g_pbmt_0,i_io_r_resp_3_bits_g_pbmt_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_pf !== i_io_r_resp_3_bits_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_pf g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_pf,i_io_r_resp_3_bits_perm_0_pf); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_af !== i_io_r_resp_3_bits_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_af g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_af,i_io_r_resp_3_bits_perm_0_af); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_v !== i_io_r_resp_3_bits_perm_0_v)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_v g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_v,i_io_r_resp_3_bits_perm_0_v); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_d !== i_io_r_resp_3_bits_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_d g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_d,i_io_r_resp_3_bits_perm_0_d); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_a !== i_io_r_resp_3_bits_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_a g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_a,i_io_r_resp_3_bits_perm_0_a); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_u !== i_io_r_resp_3_bits_perm_0_u)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_u g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_u,i_io_r_resp_3_bits_perm_0_u); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_x !== i_io_r_resp_3_bits_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_x g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_x,i_io_r_resp_3_bits_perm_0_x); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_w !== i_io_r_resp_3_bits_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_w g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_w,i_io_r_resp_3_bits_perm_0_w); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_r !== i_io_r_resp_3_bits_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_perm_0_r g=%h i=%h",t,g_io_r_resp_3_bits_perm_0_r,i_io_r_resp_3_bits_perm_0_r); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_pf !== i_io_r_resp_3_bits_g_perm_0_pf)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_pf g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_pf,i_io_r_resp_3_bits_g_perm_0_pf); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_af !== i_io_r_resp_3_bits_g_perm_0_af)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_af g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_af,i_io_r_resp_3_bits_g_perm_0_af); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_d !== i_io_r_resp_3_bits_g_perm_0_d)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_d g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_d,i_io_r_resp_3_bits_g_perm_0_d); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_a !== i_io_r_resp_3_bits_g_perm_0_a)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_a g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_a,i_io_r_resp_3_bits_g_perm_0_a); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_x !== i_io_r_resp_3_bits_g_perm_0_x)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_x g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_x,i_io_r_resp_3_bits_g_perm_0_x); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_w !== i_io_r_resp_3_bits_g_perm_0_w)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_w g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_w,i_io_r_resp_3_bits_g_perm_0_w); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_r !== i_io_r_resp_3_bits_g_perm_0_r)) begin errors++;
      if(errors<=60) $display("vec %0d io_r_resp_3_bits_g_perm_0_r g=%h i=%h",t,g_io_r_resp_3_bits_g_perm_0_r,i_io_r_resp_3_bits_g_perm_0_r); end
    if (g_io_access_3_touch_ways_valid !== i_io_access_3_touch_ways_valid) begin errors++;
      if(errors<=60) $display("vec %0d io_access_3_touch_ways_valid g=%b i=%b",t,g_io_access_3_touch_ways_valid,i_io_access_3_touch_ways_valid); end
    if (g_io_access_3_touch_ways_valid && (g_io_access_3_touch_ways_bits !== i_io_access_3_touch_ways_bits)) begin errors++;
      if(errors<=60) $display("vec %0d io_access_3_touch_ways_bits g=%h i=%h",t,g_io_access_3_touch_ways_bits,i_io_access_3_touch_ways_bits); end
  endtask
  task automatic drive_random();
    automatic int act = $urandom_range(0,9);
    io_r_req_0_valid = $urandom_range(0,1);
    io_r_req_0_bits_vpn = {$urandom, $urandom};
    io_r_req_0_bits_s2xlate = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;
    io_r_req_1_valid = $urandom_range(0,1);
    io_r_req_1_bits_vpn = {$urandom, $urandom};
    io_r_req_1_bits_s2xlate = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;
    io_r_req_2_valid = $urandom_range(0,1);
    io_r_req_2_bits_vpn = {$urandom, $urandom};
    io_r_req_2_bits_s2xlate = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;
    io_r_req_3_valid = $urandom_range(0,1);
    io_r_req_3_bits_vpn = {$urandom, $urandom};
    io_r_req_3_bits_s2xlate = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;
    io_w_valid = ($urandom_range(0,3) == 0);
    io_w_bits_wayIdx = 6'($urandom_range(0,47));
    io_w_bits_data_s2xlate = 2'($urandom_range(0,3));
    io_w_bits_data_s1_entry_tag = {$urandom};
    io_w_bits_data_s1_entry_asid = 16'($urandom);
    io_w_bits_data_s1_entry_vmid = 14'($urandom);
    io_w_bits_data_s1_entry_n = $urandom_range(0,1);
    io_w_bits_data_s1_entry_pbmt = 2'($urandom);
    io_w_bits_data_s1_entry_perm_d = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_a = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_g = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_u = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_x = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_w = $urandom_range(0,1);
    io_w_bits_data_s1_entry_perm_r = $urandom_range(0,1);
    io_w_bits_data_s1_entry_level = 2'($urandom_range(0,2));
    io_w_bits_data_s1_entry_v = $urandom_range(0,1);
    io_w_bits_data_s1_entry_ppn = {$urandom, $urandom};
    io_w_bits_data_s1_ppn_low_0 = 3'($urandom);
    io_w_bits_data_s1_valididx_0 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_0 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_1 = 3'($urandom);
    io_w_bits_data_s1_valididx_1 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_1 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_2 = 3'($urandom);
    io_w_bits_data_s1_valididx_2 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_2 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_3 = 3'($urandom);
    io_w_bits_data_s1_valididx_3 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_3 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_4 = 3'($urandom);
    io_w_bits_data_s1_valididx_4 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_4 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_5 = 3'($urandom);
    io_w_bits_data_s1_valididx_5 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_5 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_6 = 3'($urandom);
    io_w_bits_data_s1_valididx_6 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_6 = $urandom_range(0,1);
    io_w_bits_data_s1_ppn_low_7 = 3'($urandom);
    io_w_bits_data_s1_valididx_7 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_7 = $urandom_range(0,1);
    io_w_bits_data_s1_pf = $urandom_range(0,1);
    io_w_bits_data_s1_af = $urandom_range(0,1);
    io_w_bits_data_s2_entry_tag = {$urandom};
    io_w_bits_data_s2_entry_vmid = 14'($urandom);
    io_w_bits_data_s2_entry_n = $urandom_range(0,1);
    io_w_bits_data_s2_entry_pbmt = 2'($urandom);
    io_w_bits_data_s2_entry_ppn = {$urandom};
    io_w_bits_data_s2_entry_perm_d = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_a = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_g = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_u = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_x = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_w = $urandom_range(0,1);
    io_w_bits_data_s2_entry_perm_r = $urandom_range(0,1);
    io_w_bits_data_s2_entry_level = 2'($urandom_range(0,2));
    io_w_bits_data_s2_gpf = $urandom_range(0,1);
    io_w_bits_data_s2_gaf = $urandom_range(0,1);
    io_sfence_valid = (act == 0);
    io_sfence_bits_rs1 = $urandom_range(0,1);
    io_sfence_bits_rs2 = $urandom_range(0,1);
    io_sfence_bits_addr = {$urandom, $urandom};
    io_sfence_bits_id = 16'($urandom);
    io_sfence_bits_hv = $urandom_range(0,1);
    io_sfence_bits_hg = $urandom_range(0,1);
    io_csr_satp_asid = 16'($urandom);
    io_csr_vsatp_asid = 16'($urandom);
    io_csr_hgatp_vmid = 16'($urandom);
    io_csr_priv_virt = $urandom_range(0,1);
  endtask
  initial begin
    reset = 1; io_w_valid = 0; io_sfence_valid = 0;
    io_r_req_0_valid = 0;
    io_r_req_1_valid = 0;
    io_r_req_2_valid = 0;
    io_r_req_3_valid = 0;
    io_csr_satp_asid=0; io_csr_vsatp_asid=0; io_csr_hgatp_vmid=0; io_csr_priv_virt=0;
    io_sfence_bits_rs1=0; io_sfence_bits_rs2=0; io_sfence_bits_addr=0;
    io_sfence_bits_id=0; io_sfence_bits_hv=0; io_sfence_bits_hg=0;
    repeat (3) @(posedge clock); #1; reset = 0;
    @(posedge clock);
    for (int t = 0; t < NVEC; t++) begin
      drive_random();
      @(posedge clock); #1;
      do_check(t);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
