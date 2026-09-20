// 自动生成：verif/ut/TlbStorageWrapper/gen_tb_variant.py —— 勿手改（改生成器后重跑）
// TlbStorageWrapper_1（4 读端口 / 48 路全相联）双例化逐拍比对:
//   golden TlbStorageWrapper_1  vs  可读重写 TlbStorageWrapper_1_xs。
// 含 directed_mbmc_sfence(): 钉 io_csr_mbmc_BME/CMODE 必须透传给内层 TLBFA_1。
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
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
  logic io_csr_mbmc_BME;
  logic io_csr_mbmc_CMODE;
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
  wire g_io_r_resp_0_bits_hit;
  wire i_io_r_resp_0_bits_hit;
  wire [35:0] g_io_r_resp_0_bits_ppn_0;
  wire [35:0] i_io_r_resp_0_bits_ppn_0;
  wire [35:0] g_io_r_resp_0_bits_ppn_1;
  wire [35:0] i_io_r_resp_0_bits_ppn_1;
  wire [1:0] g_io_r_resp_0_bits_pbmt_0;
  wire [1:0] i_io_r_resp_0_bits_pbmt_0;
  wire [1:0] g_io_r_resp_0_bits_g_pbmt_0;
  wire [1:0] i_io_r_resp_0_bits_g_pbmt_0;
  wire g_io_r_resp_0_bits_perm_0_pf;
  wire i_io_r_resp_0_bits_perm_0_pf;
  wire g_io_r_resp_0_bits_perm_0_af;
  wire i_io_r_resp_0_bits_perm_0_af;
  wire g_io_r_resp_0_bits_perm_0_v;
  wire i_io_r_resp_0_bits_perm_0_v;
  wire g_io_r_resp_0_bits_perm_0_d;
  wire i_io_r_resp_0_bits_perm_0_d;
  wire g_io_r_resp_0_bits_perm_0_a;
  wire i_io_r_resp_0_bits_perm_0_a;
  wire g_io_r_resp_0_bits_perm_0_u;
  wire i_io_r_resp_0_bits_perm_0_u;
  wire g_io_r_resp_0_bits_perm_0_x;
  wire i_io_r_resp_0_bits_perm_0_x;
  wire g_io_r_resp_0_bits_perm_0_w;
  wire i_io_r_resp_0_bits_perm_0_w;
  wire g_io_r_resp_0_bits_perm_0_r;
  wire i_io_r_resp_0_bits_perm_0_r;
  wire g_io_r_resp_0_bits_perm_1_pf;
  wire i_io_r_resp_0_bits_perm_1_pf;
  wire g_io_r_resp_0_bits_perm_1_af;
  wire i_io_r_resp_0_bits_perm_1_af;
  wire g_io_r_resp_0_bits_perm_1_v;
  wire i_io_r_resp_0_bits_perm_1_v;
  wire g_io_r_resp_0_bits_perm_1_x;
  wire i_io_r_resp_0_bits_perm_1_x;
  wire g_io_r_resp_0_bits_perm_1_w;
  wire i_io_r_resp_0_bits_perm_1_w;
  wire g_io_r_resp_0_bits_perm_1_r;
  wire i_io_r_resp_0_bits_perm_1_r;
  wire g_io_r_resp_0_bits_g_perm_0_pf;
  wire i_io_r_resp_0_bits_g_perm_0_pf;
  wire g_io_r_resp_0_bits_g_perm_0_af;
  wire i_io_r_resp_0_bits_g_perm_0_af;
  wire g_io_r_resp_0_bits_g_perm_0_d;
  wire i_io_r_resp_0_bits_g_perm_0_d;
  wire g_io_r_resp_0_bits_g_perm_0_a;
  wire i_io_r_resp_0_bits_g_perm_0_a;
  wire g_io_r_resp_0_bits_g_perm_0_x;
  wire i_io_r_resp_0_bits_g_perm_0_x;
  wire g_io_r_resp_0_bits_g_perm_0_w;
  wire i_io_r_resp_0_bits_g_perm_0_w;
  wire g_io_r_resp_0_bits_g_perm_0_r;
  wire i_io_r_resp_0_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_0_bits_s2xlate_0;
  wire [1:0] i_io_r_resp_0_bits_s2xlate_0;
  wire g_io_r_resp_1_bits_hit;
  wire i_io_r_resp_1_bits_hit;
  wire [35:0] g_io_r_resp_1_bits_ppn_0;
  wire [35:0] i_io_r_resp_1_bits_ppn_0;
  wire [35:0] g_io_r_resp_1_bits_ppn_1;
  wire [35:0] i_io_r_resp_1_bits_ppn_1;
  wire [1:0] g_io_r_resp_1_bits_pbmt_0;
  wire [1:0] i_io_r_resp_1_bits_pbmt_0;
  wire [1:0] g_io_r_resp_1_bits_g_pbmt_0;
  wire [1:0] i_io_r_resp_1_bits_g_pbmt_0;
  wire g_io_r_resp_1_bits_perm_0_pf;
  wire i_io_r_resp_1_bits_perm_0_pf;
  wire g_io_r_resp_1_bits_perm_0_af;
  wire i_io_r_resp_1_bits_perm_0_af;
  wire g_io_r_resp_1_bits_perm_0_v;
  wire i_io_r_resp_1_bits_perm_0_v;
  wire g_io_r_resp_1_bits_perm_0_d;
  wire i_io_r_resp_1_bits_perm_0_d;
  wire g_io_r_resp_1_bits_perm_0_a;
  wire i_io_r_resp_1_bits_perm_0_a;
  wire g_io_r_resp_1_bits_perm_0_u;
  wire i_io_r_resp_1_bits_perm_0_u;
  wire g_io_r_resp_1_bits_perm_0_x;
  wire i_io_r_resp_1_bits_perm_0_x;
  wire g_io_r_resp_1_bits_perm_0_w;
  wire i_io_r_resp_1_bits_perm_0_w;
  wire g_io_r_resp_1_bits_perm_0_r;
  wire i_io_r_resp_1_bits_perm_0_r;
  wire g_io_r_resp_1_bits_perm_1_pf;
  wire i_io_r_resp_1_bits_perm_1_pf;
  wire g_io_r_resp_1_bits_perm_1_af;
  wire i_io_r_resp_1_bits_perm_1_af;
  wire g_io_r_resp_1_bits_perm_1_v;
  wire i_io_r_resp_1_bits_perm_1_v;
  wire g_io_r_resp_1_bits_perm_1_x;
  wire i_io_r_resp_1_bits_perm_1_x;
  wire g_io_r_resp_1_bits_perm_1_w;
  wire i_io_r_resp_1_bits_perm_1_w;
  wire g_io_r_resp_1_bits_perm_1_r;
  wire i_io_r_resp_1_bits_perm_1_r;
  wire g_io_r_resp_1_bits_g_perm_0_pf;
  wire i_io_r_resp_1_bits_g_perm_0_pf;
  wire g_io_r_resp_1_bits_g_perm_0_af;
  wire i_io_r_resp_1_bits_g_perm_0_af;
  wire g_io_r_resp_1_bits_g_perm_0_d;
  wire i_io_r_resp_1_bits_g_perm_0_d;
  wire g_io_r_resp_1_bits_g_perm_0_a;
  wire i_io_r_resp_1_bits_g_perm_0_a;
  wire g_io_r_resp_1_bits_g_perm_0_x;
  wire i_io_r_resp_1_bits_g_perm_0_x;
  wire g_io_r_resp_1_bits_g_perm_0_w;
  wire i_io_r_resp_1_bits_g_perm_0_w;
  wire g_io_r_resp_1_bits_g_perm_0_r;
  wire i_io_r_resp_1_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_1_bits_s2xlate_0;
  wire [1:0] i_io_r_resp_1_bits_s2xlate_0;
  wire g_io_r_resp_2_bits_hit;
  wire i_io_r_resp_2_bits_hit;
  wire [35:0] g_io_r_resp_2_bits_ppn_0;
  wire [35:0] i_io_r_resp_2_bits_ppn_0;
  wire [35:0] g_io_r_resp_2_bits_ppn_1;
  wire [35:0] i_io_r_resp_2_bits_ppn_1;
  wire [1:0] g_io_r_resp_2_bits_pbmt_0;
  wire [1:0] i_io_r_resp_2_bits_pbmt_0;
  wire [1:0] g_io_r_resp_2_bits_g_pbmt_0;
  wire [1:0] i_io_r_resp_2_bits_g_pbmt_0;
  wire g_io_r_resp_2_bits_perm_0_pf;
  wire i_io_r_resp_2_bits_perm_0_pf;
  wire g_io_r_resp_2_bits_perm_0_af;
  wire i_io_r_resp_2_bits_perm_0_af;
  wire g_io_r_resp_2_bits_perm_0_v;
  wire i_io_r_resp_2_bits_perm_0_v;
  wire g_io_r_resp_2_bits_perm_0_d;
  wire i_io_r_resp_2_bits_perm_0_d;
  wire g_io_r_resp_2_bits_perm_0_a;
  wire i_io_r_resp_2_bits_perm_0_a;
  wire g_io_r_resp_2_bits_perm_0_u;
  wire i_io_r_resp_2_bits_perm_0_u;
  wire g_io_r_resp_2_bits_perm_0_x;
  wire i_io_r_resp_2_bits_perm_0_x;
  wire g_io_r_resp_2_bits_perm_0_w;
  wire i_io_r_resp_2_bits_perm_0_w;
  wire g_io_r_resp_2_bits_perm_0_r;
  wire i_io_r_resp_2_bits_perm_0_r;
  wire g_io_r_resp_2_bits_perm_1_pf;
  wire i_io_r_resp_2_bits_perm_1_pf;
  wire g_io_r_resp_2_bits_perm_1_af;
  wire i_io_r_resp_2_bits_perm_1_af;
  wire g_io_r_resp_2_bits_perm_1_v;
  wire i_io_r_resp_2_bits_perm_1_v;
  wire g_io_r_resp_2_bits_perm_1_x;
  wire i_io_r_resp_2_bits_perm_1_x;
  wire g_io_r_resp_2_bits_perm_1_w;
  wire i_io_r_resp_2_bits_perm_1_w;
  wire g_io_r_resp_2_bits_perm_1_r;
  wire i_io_r_resp_2_bits_perm_1_r;
  wire g_io_r_resp_2_bits_g_perm_0_pf;
  wire i_io_r_resp_2_bits_g_perm_0_pf;
  wire g_io_r_resp_2_bits_g_perm_0_af;
  wire i_io_r_resp_2_bits_g_perm_0_af;
  wire g_io_r_resp_2_bits_g_perm_0_d;
  wire i_io_r_resp_2_bits_g_perm_0_d;
  wire g_io_r_resp_2_bits_g_perm_0_a;
  wire i_io_r_resp_2_bits_g_perm_0_a;
  wire g_io_r_resp_2_bits_g_perm_0_x;
  wire i_io_r_resp_2_bits_g_perm_0_x;
  wire g_io_r_resp_2_bits_g_perm_0_w;
  wire i_io_r_resp_2_bits_g_perm_0_w;
  wire g_io_r_resp_2_bits_g_perm_0_r;
  wire i_io_r_resp_2_bits_g_perm_0_r;
  wire [1:0] g_io_r_resp_2_bits_s2xlate_0;
  wire [1:0] i_io_r_resp_2_bits_s2xlate_0;
  wire g_io_r_resp_3_bits_hit;
  wire i_io_r_resp_3_bits_hit;
  wire [35:0] g_io_r_resp_3_bits_ppn_0;
  wire [35:0] i_io_r_resp_3_bits_ppn_0;
  wire [1:0] g_io_r_resp_3_bits_pbmt_0;
  wire [1:0] i_io_r_resp_3_bits_pbmt_0;
  wire [1:0] g_io_r_resp_3_bits_g_pbmt_0;
  wire [1:0] i_io_r_resp_3_bits_g_pbmt_0;
  wire g_io_r_resp_3_bits_perm_0_pf;
  wire i_io_r_resp_3_bits_perm_0_pf;
  wire g_io_r_resp_3_bits_perm_0_af;
  wire i_io_r_resp_3_bits_perm_0_af;
  wire g_io_r_resp_3_bits_perm_0_v;
  wire i_io_r_resp_3_bits_perm_0_v;
  wire g_io_r_resp_3_bits_perm_0_d;
  wire i_io_r_resp_3_bits_perm_0_d;
  wire g_io_r_resp_3_bits_perm_0_a;
  wire i_io_r_resp_3_bits_perm_0_a;
  wire g_io_r_resp_3_bits_perm_0_u;
  wire i_io_r_resp_3_bits_perm_0_u;
  wire g_io_r_resp_3_bits_perm_0_x;
  wire i_io_r_resp_3_bits_perm_0_x;
  wire g_io_r_resp_3_bits_perm_0_w;
  wire i_io_r_resp_3_bits_perm_0_w;
  wire g_io_r_resp_3_bits_perm_0_r;
  wire i_io_r_resp_3_bits_perm_0_r;
  wire g_io_r_resp_3_bits_g_perm_0_pf;
  wire i_io_r_resp_3_bits_g_perm_0_pf;
  wire g_io_r_resp_3_bits_g_perm_0_af;
  wire i_io_r_resp_3_bits_g_perm_0_af;
  wire g_io_r_resp_3_bits_g_perm_0_d;
  wire i_io_r_resp_3_bits_g_perm_0_d;
  wire g_io_r_resp_3_bits_g_perm_0_a;
  wire i_io_r_resp_3_bits_g_perm_0_a;
  wire g_io_r_resp_3_bits_g_perm_0_x;
  wire i_io_r_resp_3_bits_g_perm_0_x;
  wire g_io_r_resp_3_bits_g_perm_0_w;
  wire i_io_r_resp_3_bits_g_perm_0_w;
  wire g_io_r_resp_3_bits_g_perm_0_r;
  wire i_io_r_resp_3_bits_g_perm_0_r;

  TlbStorageWrapper_1 u_g_ (.clock(clock), .reset(reset), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_mbmc_BME(io_csr_mbmc_BME), .io_csr_mbmc_CMODE(io_csr_mbmc_CMODE), .io_csr_priv_virt(io_csr_priv_virt), .io_r_req_0_valid(io_r_req_0_valid), .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn), .io_r_req_0_bits_s2xlate(io_r_req_0_bits_s2xlate), .io_r_req_1_valid(io_r_req_1_valid), .io_r_req_1_bits_vpn(io_r_req_1_bits_vpn), .io_r_req_1_bits_s2xlate(io_r_req_1_bits_s2xlate), .io_r_req_2_valid(io_r_req_2_valid), .io_r_req_2_bits_vpn(io_r_req_2_bits_vpn), .io_r_req_2_bits_s2xlate(io_r_req_2_bits_s2xlate), .io_r_req_3_valid(io_r_req_3_valid), .io_r_req_3_bits_vpn(io_r_req_3_bits_vpn), .io_r_req_3_bits_s2xlate(io_r_req_3_bits_s2xlate), .io_w_valid(io_w_valid), .io_w_bits_data_s2xlate(io_w_bits_data_s2xlate), .io_w_bits_data_s1_entry_tag(io_w_bits_data_s1_entry_tag), .io_w_bits_data_s1_entry_asid(io_w_bits_data_s1_entry_asid), .io_w_bits_data_s1_entry_vmid(io_w_bits_data_s1_entry_vmid), .io_w_bits_data_s1_entry_n(io_w_bits_data_s1_entry_n), .io_w_bits_data_s1_entry_pbmt(io_w_bits_data_s1_entry_pbmt), .io_w_bits_data_s1_entry_perm_d(io_w_bits_data_s1_entry_perm_d), .io_w_bits_data_s1_entry_perm_a(io_w_bits_data_s1_entry_perm_a), .io_w_bits_data_s1_entry_perm_g(io_w_bits_data_s1_entry_perm_g), .io_w_bits_data_s1_entry_perm_u(io_w_bits_data_s1_entry_perm_u), .io_w_bits_data_s1_entry_perm_x(io_w_bits_data_s1_entry_perm_x), .io_w_bits_data_s1_entry_perm_w(io_w_bits_data_s1_entry_perm_w), .io_w_bits_data_s1_entry_perm_r(io_w_bits_data_s1_entry_perm_r), .io_w_bits_data_s1_entry_level(io_w_bits_data_s1_entry_level), .io_w_bits_data_s1_entry_v(io_w_bits_data_s1_entry_v), .io_w_bits_data_s1_entry_ppn(io_w_bits_data_s1_entry_ppn), .io_w_bits_data_s1_ppn_low_0(io_w_bits_data_s1_ppn_low_0), .io_w_bits_data_s1_ppn_low_1(io_w_bits_data_s1_ppn_low_1), .io_w_bits_data_s1_ppn_low_2(io_w_bits_data_s1_ppn_low_2), .io_w_bits_data_s1_ppn_low_3(io_w_bits_data_s1_ppn_low_3), .io_w_bits_data_s1_ppn_low_4(io_w_bits_data_s1_ppn_low_4), .io_w_bits_data_s1_ppn_low_5(io_w_bits_data_s1_ppn_low_5), .io_w_bits_data_s1_ppn_low_6(io_w_bits_data_s1_ppn_low_6), .io_w_bits_data_s1_ppn_low_7(io_w_bits_data_s1_ppn_low_7), .io_w_bits_data_s1_valididx_0(io_w_bits_data_s1_valididx_0), .io_w_bits_data_s1_valididx_1(io_w_bits_data_s1_valididx_1), .io_w_bits_data_s1_valididx_2(io_w_bits_data_s1_valididx_2), .io_w_bits_data_s1_valididx_3(io_w_bits_data_s1_valididx_3), .io_w_bits_data_s1_valididx_4(io_w_bits_data_s1_valididx_4), .io_w_bits_data_s1_valididx_5(io_w_bits_data_s1_valididx_5), .io_w_bits_data_s1_valididx_6(io_w_bits_data_s1_valididx_6), .io_w_bits_data_s1_valididx_7(io_w_bits_data_s1_valididx_7), .io_w_bits_data_s1_pteidx_0(io_w_bits_data_s1_pteidx_0), .io_w_bits_data_s1_pteidx_1(io_w_bits_data_s1_pteidx_1), .io_w_bits_data_s1_pteidx_2(io_w_bits_data_s1_pteidx_2), .io_w_bits_data_s1_pteidx_3(io_w_bits_data_s1_pteidx_3), .io_w_bits_data_s1_pteidx_4(io_w_bits_data_s1_pteidx_4), .io_w_bits_data_s1_pteidx_5(io_w_bits_data_s1_pteidx_5), .io_w_bits_data_s1_pteidx_6(io_w_bits_data_s1_pteidx_6), .io_w_bits_data_s1_pteidx_7(io_w_bits_data_s1_pteidx_7), .io_w_bits_data_s1_pf(io_w_bits_data_s1_pf), .io_w_bits_data_s1_af(io_w_bits_data_s1_af), .io_w_bits_data_s2_entry_tag(io_w_bits_data_s2_entry_tag), .io_w_bits_data_s2_entry_vmid(io_w_bits_data_s2_entry_vmid), .io_w_bits_data_s2_entry_n(io_w_bits_data_s2_entry_n), .io_w_bits_data_s2_entry_pbmt(io_w_bits_data_s2_entry_pbmt), .io_w_bits_data_s2_entry_ppn(io_w_bits_data_s2_entry_ppn), .io_w_bits_data_s2_entry_perm_d(io_w_bits_data_s2_entry_perm_d), .io_w_bits_data_s2_entry_perm_a(io_w_bits_data_s2_entry_perm_a), .io_w_bits_data_s2_entry_perm_g(io_w_bits_data_s2_entry_perm_g), .io_w_bits_data_s2_entry_perm_u(io_w_bits_data_s2_entry_perm_u), .io_w_bits_data_s2_entry_perm_x(io_w_bits_data_s2_entry_perm_x), .io_w_bits_data_s2_entry_perm_w(io_w_bits_data_s2_entry_perm_w), .io_w_bits_data_s2_entry_perm_r(io_w_bits_data_s2_entry_perm_r), .io_w_bits_data_s2_entry_level(io_w_bits_data_s2_entry_level), .io_w_bits_data_s2_gpf(io_w_bits_data_s2_gpf), .io_w_bits_data_s2_gaf(io_w_bits_data_s2_gaf), .io_r_resp_0_bits_hit(g_io_r_resp_0_bits_hit), .io_r_resp_0_bits_ppn_0(g_io_r_resp_0_bits_ppn_0), .io_r_resp_0_bits_ppn_1(g_io_r_resp_0_bits_ppn_1), .io_r_resp_0_bits_pbmt_0(g_io_r_resp_0_bits_pbmt_0), .io_r_resp_0_bits_g_pbmt_0(g_io_r_resp_0_bits_g_pbmt_0), .io_r_resp_0_bits_perm_0_pf(g_io_r_resp_0_bits_perm_0_pf), .io_r_resp_0_bits_perm_0_af(g_io_r_resp_0_bits_perm_0_af), .io_r_resp_0_bits_perm_0_v(g_io_r_resp_0_bits_perm_0_v), .io_r_resp_0_bits_perm_0_d(g_io_r_resp_0_bits_perm_0_d), .io_r_resp_0_bits_perm_0_a(g_io_r_resp_0_bits_perm_0_a), .io_r_resp_0_bits_perm_0_u(g_io_r_resp_0_bits_perm_0_u), .io_r_resp_0_bits_perm_0_x(g_io_r_resp_0_bits_perm_0_x), .io_r_resp_0_bits_perm_0_w(g_io_r_resp_0_bits_perm_0_w), .io_r_resp_0_bits_perm_0_r(g_io_r_resp_0_bits_perm_0_r), .io_r_resp_0_bits_perm_1_pf(g_io_r_resp_0_bits_perm_1_pf), .io_r_resp_0_bits_perm_1_af(g_io_r_resp_0_bits_perm_1_af), .io_r_resp_0_bits_perm_1_v(g_io_r_resp_0_bits_perm_1_v), .io_r_resp_0_bits_perm_1_x(g_io_r_resp_0_bits_perm_1_x), .io_r_resp_0_bits_perm_1_w(g_io_r_resp_0_bits_perm_1_w), .io_r_resp_0_bits_perm_1_r(g_io_r_resp_0_bits_perm_1_r), .io_r_resp_0_bits_g_perm_0_pf(g_io_r_resp_0_bits_g_perm_0_pf), .io_r_resp_0_bits_g_perm_0_af(g_io_r_resp_0_bits_g_perm_0_af), .io_r_resp_0_bits_g_perm_0_d(g_io_r_resp_0_bits_g_perm_0_d), .io_r_resp_0_bits_g_perm_0_a(g_io_r_resp_0_bits_g_perm_0_a), .io_r_resp_0_bits_g_perm_0_x(g_io_r_resp_0_bits_g_perm_0_x), .io_r_resp_0_bits_g_perm_0_w(g_io_r_resp_0_bits_g_perm_0_w), .io_r_resp_0_bits_g_perm_0_r(g_io_r_resp_0_bits_g_perm_0_r), .io_r_resp_0_bits_s2xlate_0(g_io_r_resp_0_bits_s2xlate_0), .io_r_resp_1_bits_hit(g_io_r_resp_1_bits_hit), .io_r_resp_1_bits_ppn_0(g_io_r_resp_1_bits_ppn_0), .io_r_resp_1_bits_ppn_1(g_io_r_resp_1_bits_ppn_1), .io_r_resp_1_bits_pbmt_0(g_io_r_resp_1_bits_pbmt_0), .io_r_resp_1_bits_g_pbmt_0(g_io_r_resp_1_bits_g_pbmt_0), .io_r_resp_1_bits_perm_0_pf(g_io_r_resp_1_bits_perm_0_pf), .io_r_resp_1_bits_perm_0_af(g_io_r_resp_1_bits_perm_0_af), .io_r_resp_1_bits_perm_0_v(g_io_r_resp_1_bits_perm_0_v), .io_r_resp_1_bits_perm_0_d(g_io_r_resp_1_bits_perm_0_d), .io_r_resp_1_bits_perm_0_a(g_io_r_resp_1_bits_perm_0_a), .io_r_resp_1_bits_perm_0_u(g_io_r_resp_1_bits_perm_0_u), .io_r_resp_1_bits_perm_0_x(g_io_r_resp_1_bits_perm_0_x), .io_r_resp_1_bits_perm_0_w(g_io_r_resp_1_bits_perm_0_w), .io_r_resp_1_bits_perm_0_r(g_io_r_resp_1_bits_perm_0_r), .io_r_resp_1_bits_perm_1_pf(g_io_r_resp_1_bits_perm_1_pf), .io_r_resp_1_bits_perm_1_af(g_io_r_resp_1_bits_perm_1_af), .io_r_resp_1_bits_perm_1_v(g_io_r_resp_1_bits_perm_1_v), .io_r_resp_1_bits_perm_1_x(g_io_r_resp_1_bits_perm_1_x), .io_r_resp_1_bits_perm_1_w(g_io_r_resp_1_bits_perm_1_w), .io_r_resp_1_bits_perm_1_r(g_io_r_resp_1_bits_perm_1_r), .io_r_resp_1_bits_g_perm_0_pf(g_io_r_resp_1_bits_g_perm_0_pf), .io_r_resp_1_bits_g_perm_0_af(g_io_r_resp_1_bits_g_perm_0_af), .io_r_resp_1_bits_g_perm_0_d(g_io_r_resp_1_bits_g_perm_0_d), .io_r_resp_1_bits_g_perm_0_a(g_io_r_resp_1_bits_g_perm_0_a), .io_r_resp_1_bits_g_perm_0_x(g_io_r_resp_1_bits_g_perm_0_x), .io_r_resp_1_bits_g_perm_0_w(g_io_r_resp_1_bits_g_perm_0_w), .io_r_resp_1_bits_g_perm_0_r(g_io_r_resp_1_bits_g_perm_0_r), .io_r_resp_1_bits_s2xlate_0(g_io_r_resp_1_bits_s2xlate_0), .io_r_resp_2_bits_hit(g_io_r_resp_2_bits_hit), .io_r_resp_2_bits_ppn_0(g_io_r_resp_2_bits_ppn_0), .io_r_resp_2_bits_ppn_1(g_io_r_resp_2_bits_ppn_1), .io_r_resp_2_bits_pbmt_0(g_io_r_resp_2_bits_pbmt_0), .io_r_resp_2_bits_g_pbmt_0(g_io_r_resp_2_bits_g_pbmt_0), .io_r_resp_2_bits_perm_0_pf(g_io_r_resp_2_bits_perm_0_pf), .io_r_resp_2_bits_perm_0_af(g_io_r_resp_2_bits_perm_0_af), .io_r_resp_2_bits_perm_0_v(g_io_r_resp_2_bits_perm_0_v), .io_r_resp_2_bits_perm_0_d(g_io_r_resp_2_bits_perm_0_d), .io_r_resp_2_bits_perm_0_a(g_io_r_resp_2_bits_perm_0_a), .io_r_resp_2_bits_perm_0_u(g_io_r_resp_2_bits_perm_0_u), .io_r_resp_2_bits_perm_0_x(g_io_r_resp_2_bits_perm_0_x), .io_r_resp_2_bits_perm_0_w(g_io_r_resp_2_bits_perm_0_w), .io_r_resp_2_bits_perm_0_r(g_io_r_resp_2_bits_perm_0_r), .io_r_resp_2_bits_perm_1_pf(g_io_r_resp_2_bits_perm_1_pf), .io_r_resp_2_bits_perm_1_af(g_io_r_resp_2_bits_perm_1_af), .io_r_resp_2_bits_perm_1_v(g_io_r_resp_2_bits_perm_1_v), .io_r_resp_2_bits_perm_1_x(g_io_r_resp_2_bits_perm_1_x), .io_r_resp_2_bits_perm_1_w(g_io_r_resp_2_bits_perm_1_w), .io_r_resp_2_bits_perm_1_r(g_io_r_resp_2_bits_perm_1_r), .io_r_resp_2_bits_g_perm_0_pf(g_io_r_resp_2_bits_g_perm_0_pf), .io_r_resp_2_bits_g_perm_0_af(g_io_r_resp_2_bits_g_perm_0_af), .io_r_resp_2_bits_g_perm_0_d(g_io_r_resp_2_bits_g_perm_0_d), .io_r_resp_2_bits_g_perm_0_a(g_io_r_resp_2_bits_g_perm_0_a), .io_r_resp_2_bits_g_perm_0_x(g_io_r_resp_2_bits_g_perm_0_x), .io_r_resp_2_bits_g_perm_0_w(g_io_r_resp_2_bits_g_perm_0_w), .io_r_resp_2_bits_g_perm_0_r(g_io_r_resp_2_bits_g_perm_0_r), .io_r_resp_2_bits_s2xlate_0(g_io_r_resp_2_bits_s2xlate_0), .io_r_resp_3_bits_hit(g_io_r_resp_3_bits_hit), .io_r_resp_3_bits_ppn_0(g_io_r_resp_3_bits_ppn_0), .io_r_resp_3_bits_pbmt_0(g_io_r_resp_3_bits_pbmt_0), .io_r_resp_3_bits_g_pbmt_0(g_io_r_resp_3_bits_g_pbmt_0), .io_r_resp_3_bits_perm_0_pf(g_io_r_resp_3_bits_perm_0_pf), .io_r_resp_3_bits_perm_0_af(g_io_r_resp_3_bits_perm_0_af), .io_r_resp_3_bits_perm_0_v(g_io_r_resp_3_bits_perm_0_v), .io_r_resp_3_bits_perm_0_d(g_io_r_resp_3_bits_perm_0_d), .io_r_resp_3_bits_perm_0_a(g_io_r_resp_3_bits_perm_0_a), .io_r_resp_3_bits_perm_0_u(g_io_r_resp_3_bits_perm_0_u), .io_r_resp_3_bits_perm_0_x(g_io_r_resp_3_bits_perm_0_x), .io_r_resp_3_bits_perm_0_w(g_io_r_resp_3_bits_perm_0_w), .io_r_resp_3_bits_perm_0_r(g_io_r_resp_3_bits_perm_0_r), .io_r_resp_3_bits_g_perm_0_pf(g_io_r_resp_3_bits_g_perm_0_pf), .io_r_resp_3_bits_g_perm_0_af(g_io_r_resp_3_bits_g_perm_0_af), .io_r_resp_3_bits_g_perm_0_d(g_io_r_resp_3_bits_g_perm_0_d), .io_r_resp_3_bits_g_perm_0_a(g_io_r_resp_3_bits_g_perm_0_a), .io_r_resp_3_bits_g_perm_0_x(g_io_r_resp_3_bits_g_perm_0_x), .io_r_resp_3_bits_g_perm_0_w(g_io_r_resp_3_bits_g_perm_0_w), .io_r_resp_3_bits_g_perm_0_r(g_io_r_resp_3_bits_g_perm_0_r));
  TlbStorageWrapper_1_xs u_i_ (.clock(clock), .reset(reset), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_mbmc_BME(io_csr_mbmc_BME), .io_csr_mbmc_CMODE(io_csr_mbmc_CMODE), .io_csr_priv_virt(io_csr_priv_virt), .io_r_req_0_valid(io_r_req_0_valid), .io_r_req_0_bits_vpn(io_r_req_0_bits_vpn), .io_r_req_0_bits_s2xlate(io_r_req_0_bits_s2xlate), .io_r_req_1_valid(io_r_req_1_valid), .io_r_req_1_bits_vpn(io_r_req_1_bits_vpn), .io_r_req_1_bits_s2xlate(io_r_req_1_bits_s2xlate), .io_r_req_2_valid(io_r_req_2_valid), .io_r_req_2_bits_vpn(io_r_req_2_bits_vpn), .io_r_req_2_bits_s2xlate(io_r_req_2_bits_s2xlate), .io_r_req_3_valid(io_r_req_3_valid), .io_r_req_3_bits_vpn(io_r_req_3_bits_vpn), .io_r_req_3_bits_s2xlate(io_r_req_3_bits_s2xlate), .io_w_valid(io_w_valid), .io_w_bits_data_s2xlate(io_w_bits_data_s2xlate), .io_w_bits_data_s1_entry_tag(io_w_bits_data_s1_entry_tag), .io_w_bits_data_s1_entry_asid(io_w_bits_data_s1_entry_asid), .io_w_bits_data_s1_entry_vmid(io_w_bits_data_s1_entry_vmid), .io_w_bits_data_s1_entry_n(io_w_bits_data_s1_entry_n), .io_w_bits_data_s1_entry_pbmt(io_w_bits_data_s1_entry_pbmt), .io_w_bits_data_s1_entry_perm_d(io_w_bits_data_s1_entry_perm_d), .io_w_bits_data_s1_entry_perm_a(io_w_bits_data_s1_entry_perm_a), .io_w_bits_data_s1_entry_perm_g(io_w_bits_data_s1_entry_perm_g), .io_w_bits_data_s1_entry_perm_u(io_w_bits_data_s1_entry_perm_u), .io_w_bits_data_s1_entry_perm_x(io_w_bits_data_s1_entry_perm_x), .io_w_bits_data_s1_entry_perm_w(io_w_bits_data_s1_entry_perm_w), .io_w_bits_data_s1_entry_perm_r(io_w_bits_data_s1_entry_perm_r), .io_w_bits_data_s1_entry_level(io_w_bits_data_s1_entry_level), .io_w_bits_data_s1_entry_v(io_w_bits_data_s1_entry_v), .io_w_bits_data_s1_entry_ppn(io_w_bits_data_s1_entry_ppn), .io_w_bits_data_s1_ppn_low_0(io_w_bits_data_s1_ppn_low_0), .io_w_bits_data_s1_ppn_low_1(io_w_bits_data_s1_ppn_low_1), .io_w_bits_data_s1_ppn_low_2(io_w_bits_data_s1_ppn_low_2), .io_w_bits_data_s1_ppn_low_3(io_w_bits_data_s1_ppn_low_3), .io_w_bits_data_s1_ppn_low_4(io_w_bits_data_s1_ppn_low_4), .io_w_bits_data_s1_ppn_low_5(io_w_bits_data_s1_ppn_low_5), .io_w_bits_data_s1_ppn_low_6(io_w_bits_data_s1_ppn_low_6), .io_w_bits_data_s1_ppn_low_7(io_w_bits_data_s1_ppn_low_7), .io_w_bits_data_s1_valididx_0(io_w_bits_data_s1_valididx_0), .io_w_bits_data_s1_valididx_1(io_w_bits_data_s1_valididx_1), .io_w_bits_data_s1_valididx_2(io_w_bits_data_s1_valididx_2), .io_w_bits_data_s1_valididx_3(io_w_bits_data_s1_valididx_3), .io_w_bits_data_s1_valididx_4(io_w_bits_data_s1_valididx_4), .io_w_bits_data_s1_valididx_5(io_w_bits_data_s1_valididx_5), .io_w_bits_data_s1_valididx_6(io_w_bits_data_s1_valididx_6), .io_w_bits_data_s1_valididx_7(io_w_bits_data_s1_valididx_7), .io_w_bits_data_s1_pteidx_0(io_w_bits_data_s1_pteidx_0), .io_w_bits_data_s1_pteidx_1(io_w_bits_data_s1_pteidx_1), .io_w_bits_data_s1_pteidx_2(io_w_bits_data_s1_pteidx_2), .io_w_bits_data_s1_pteidx_3(io_w_bits_data_s1_pteidx_3), .io_w_bits_data_s1_pteidx_4(io_w_bits_data_s1_pteidx_4), .io_w_bits_data_s1_pteidx_5(io_w_bits_data_s1_pteidx_5), .io_w_bits_data_s1_pteidx_6(io_w_bits_data_s1_pteidx_6), .io_w_bits_data_s1_pteidx_7(io_w_bits_data_s1_pteidx_7), .io_w_bits_data_s1_pf(io_w_bits_data_s1_pf), .io_w_bits_data_s1_af(io_w_bits_data_s1_af), .io_w_bits_data_s2_entry_tag(io_w_bits_data_s2_entry_tag), .io_w_bits_data_s2_entry_vmid(io_w_bits_data_s2_entry_vmid), .io_w_bits_data_s2_entry_n(io_w_bits_data_s2_entry_n), .io_w_bits_data_s2_entry_pbmt(io_w_bits_data_s2_entry_pbmt), .io_w_bits_data_s2_entry_ppn(io_w_bits_data_s2_entry_ppn), .io_w_bits_data_s2_entry_perm_d(io_w_bits_data_s2_entry_perm_d), .io_w_bits_data_s2_entry_perm_a(io_w_bits_data_s2_entry_perm_a), .io_w_bits_data_s2_entry_perm_g(io_w_bits_data_s2_entry_perm_g), .io_w_bits_data_s2_entry_perm_u(io_w_bits_data_s2_entry_perm_u), .io_w_bits_data_s2_entry_perm_x(io_w_bits_data_s2_entry_perm_x), .io_w_bits_data_s2_entry_perm_w(io_w_bits_data_s2_entry_perm_w), .io_w_bits_data_s2_entry_perm_r(io_w_bits_data_s2_entry_perm_r), .io_w_bits_data_s2_entry_level(io_w_bits_data_s2_entry_level), .io_w_bits_data_s2_gpf(io_w_bits_data_s2_gpf), .io_w_bits_data_s2_gaf(io_w_bits_data_s2_gaf), .io_r_resp_0_bits_hit(i_io_r_resp_0_bits_hit), .io_r_resp_0_bits_ppn_0(i_io_r_resp_0_bits_ppn_0), .io_r_resp_0_bits_ppn_1(i_io_r_resp_0_bits_ppn_1), .io_r_resp_0_bits_pbmt_0(i_io_r_resp_0_bits_pbmt_0), .io_r_resp_0_bits_g_pbmt_0(i_io_r_resp_0_bits_g_pbmt_0), .io_r_resp_0_bits_perm_0_pf(i_io_r_resp_0_bits_perm_0_pf), .io_r_resp_0_bits_perm_0_af(i_io_r_resp_0_bits_perm_0_af), .io_r_resp_0_bits_perm_0_v(i_io_r_resp_0_bits_perm_0_v), .io_r_resp_0_bits_perm_0_d(i_io_r_resp_0_bits_perm_0_d), .io_r_resp_0_bits_perm_0_a(i_io_r_resp_0_bits_perm_0_a), .io_r_resp_0_bits_perm_0_u(i_io_r_resp_0_bits_perm_0_u), .io_r_resp_0_bits_perm_0_x(i_io_r_resp_0_bits_perm_0_x), .io_r_resp_0_bits_perm_0_w(i_io_r_resp_0_bits_perm_0_w), .io_r_resp_0_bits_perm_0_r(i_io_r_resp_0_bits_perm_0_r), .io_r_resp_0_bits_perm_1_pf(i_io_r_resp_0_bits_perm_1_pf), .io_r_resp_0_bits_perm_1_af(i_io_r_resp_0_bits_perm_1_af), .io_r_resp_0_bits_perm_1_v(i_io_r_resp_0_bits_perm_1_v), .io_r_resp_0_bits_perm_1_x(i_io_r_resp_0_bits_perm_1_x), .io_r_resp_0_bits_perm_1_w(i_io_r_resp_0_bits_perm_1_w), .io_r_resp_0_bits_perm_1_r(i_io_r_resp_0_bits_perm_1_r), .io_r_resp_0_bits_g_perm_0_pf(i_io_r_resp_0_bits_g_perm_0_pf), .io_r_resp_0_bits_g_perm_0_af(i_io_r_resp_0_bits_g_perm_0_af), .io_r_resp_0_bits_g_perm_0_d(i_io_r_resp_0_bits_g_perm_0_d), .io_r_resp_0_bits_g_perm_0_a(i_io_r_resp_0_bits_g_perm_0_a), .io_r_resp_0_bits_g_perm_0_x(i_io_r_resp_0_bits_g_perm_0_x), .io_r_resp_0_bits_g_perm_0_w(i_io_r_resp_0_bits_g_perm_0_w), .io_r_resp_0_bits_g_perm_0_r(i_io_r_resp_0_bits_g_perm_0_r), .io_r_resp_0_bits_s2xlate_0(i_io_r_resp_0_bits_s2xlate_0), .io_r_resp_1_bits_hit(i_io_r_resp_1_bits_hit), .io_r_resp_1_bits_ppn_0(i_io_r_resp_1_bits_ppn_0), .io_r_resp_1_bits_ppn_1(i_io_r_resp_1_bits_ppn_1), .io_r_resp_1_bits_pbmt_0(i_io_r_resp_1_bits_pbmt_0), .io_r_resp_1_bits_g_pbmt_0(i_io_r_resp_1_bits_g_pbmt_0), .io_r_resp_1_bits_perm_0_pf(i_io_r_resp_1_bits_perm_0_pf), .io_r_resp_1_bits_perm_0_af(i_io_r_resp_1_bits_perm_0_af), .io_r_resp_1_bits_perm_0_v(i_io_r_resp_1_bits_perm_0_v), .io_r_resp_1_bits_perm_0_d(i_io_r_resp_1_bits_perm_0_d), .io_r_resp_1_bits_perm_0_a(i_io_r_resp_1_bits_perm_0_a), .io_r_resp_1_bits_perm_0_u(i_io_r_resp_1_bits_perm_0_u), .io_r_resp_1_bits_perm_0_x(i_io_r_resp_1_bits_perm_0_x), .io_r_resp_1_bits_perm_0_w(i_io_r_resp_1_bits_perm_0_w), .io_r_resp_1_bits_perm_0_r(i_io_r_resp_1_bits_perm_0_r), .io_r_resp_1_bits_perm_1_pf(i_io_r_resp_1_bits_perm_1_pf), .io_r_resp_1_bits_perm_1_af(i_io_r_resp_1_bits_perm_1_af), .io_r_resp_1_bits_perm_1_v(i_io_r_resp_1_bits_perm_1_v), .io_r_resp_1_bits_perm_1_x(i_io_r_resp_1_bits_perm_1_x), .io_r_resp_1_bits_perm_1_w(i_io_r_resp_1_bits_perm_1_w), .io_r_resp_1_bits_perm_1_r(i_io_r_resp_1_bits_perm_1_r), .io_r_resp_1_bits_g_perm_0_pf(i_io_r_resp_1_bits_g_perm_0_pf), .io_r_resp_1_bits_g_perm_0_af(i_io_r_resp_1_bits_g_perm_0_af), .io_r_resp_1_bits_g_perm_0_d(i_io_r_resp_1_bits_g_perm_0_d), .io_r_resp_1_bits_g_perm_0_a(i_io_r_resp_1_bits_g_perm_0_a), .io_r_resp_1_bits_g_perm_0_x(i_io_r_resp_1_bits_g_perm_0_x), .io_r_resp_1_bits_g_perm_0_w(i_io_r_resp_1_bits_g_perm_0_w), .io_r_resp_1_bits_g_perm_0_r(i_io_r_resp_1_bits_g_perm_0_r), .io_r_resp_1_bits_s2xlate_0(i_io_r_resp_1_bits_s2xlate_0), .io_r_resp_2_bits_hit(i_io_r_resp_2_bits_hit), .io_r_resp_2_bits_ppn_0(i_io_r_resp_2_bits_ppn_0), .io_r_resp_2_bits_ppn_1(i_io_r_resp_2_bits_ppn_1), .io_r_resp_2_bits_pbmt_0(i_io_r_resp_2_bits_pbmt_0), .io_r_resp_2_bits_g_pbmt_0(i_io_r_resp_2_bits_g_pbmt_0), .io_r_resp_2_bits_perm_0_pf(i_io_r_resp_2_bits_perm_0_pf), .io_r_resp_2_bits_perm_0_af(i_io_r_resp_2_bits_perm_0_af), .io_r_resp_2_bits_perm_0_v(i_io_r_resp_2_bits_perm_0_v), .io_r_resp_2_bits_perm_0_d(i_io_r_resp_2_bits_perm_0_d), .io_r_resp_2_bits_perm_0_a(i_io_r_resp_2_bits_perm_0_a), .io_r_resp_2_bits_perm_0_u(i_io_r_resp_2_bits_perm_0_u), .io_r_resp_2_bits_perm_0_x(i_io_r_resp_2_bits_perm_0_x), .io_r_resp_2_bits_perm_0_w(i_io_r_resp_2_bits_perm_0_w), .io_r_resp_2_bits_perm_0_r(i_io_r_resp_2_bits_perm_0_r), .io_r_resp_2_bits_perm_1_pf(i_io_r_resp_2_bits_perm_1_pf), .io_r_resp_2_bits_perm_1_af(i_io_r_resp_2_bits_perm_1_af), .io_r_resp_2_bits_perm_1_v(i_io_r_resp_2_bits_perm_1_v), .io_r_resp_2_bits_perm_1_x(i_io_r_resp_2_bits_perm_1_x), .io_r_resp_2_bits_perm_1_w(i_io_r_resp_2_bits_perm_1_w), .io_r_resp_2_bits_perm_1_r(i_io_r_resp_2_bits_perm_1_r), .io_r_resp_2_bits_g_perm_0_pf(i_io_r_resp_2_bits_g_perm_0_pf), .io_r_resp_2_bits_g_perm_0_af(i_io_r_resp_2_bits_g_perm_0_af), .io_r_resp_2_bits_g_perm_0_d(i_io_r_resp_2_bits_g_perm_0_d), .io_r_resp_2_bits_g_perm_0_a(i_io_r_resp_2_bits_g_perm_0_a), .io_r_resp_2_bits_g_perm_0_x(i_io_r_resp_2_bits_g_perm_0_x), .io_r_resp_2_bits_g_perm_0_w(i_io_r_resp_2_bits_g_perm_0_w), .io_r_resp_2_bits_g_perm_0_r(i_io_r_resp_2_bits_g_perm_0_r), .io_r_resp_2_bits_s2xlate_0(i_io_r_resp_2_bits_s2xlate_0), .io_r_resp_3_bits_hit(i_io_r_resp_3_bits_hit), .io_r_resp_3_bits_ppn_0(i_io_r_resp_3_bits_ppn_0), .io_r_resp_3_bits_pbmt_0(i_io_r_resp_3_bits_pbmt_0), .io_r_resp_3_bits_g_pbmt_0(i_io_r_resp_3_bits_g_pbmt_0), .io_r_resp_3_bits_perm_0_pf(i_io_r_resp_3_bits_perm_0_pf), .io_r_resp_3_bits_perm_0_af(i_io_r_resp_3_bits_perm_0_af), .io_r_resp_3_bits_perm_0_v(i_io_r_resp_3_bits_perm_0_v), .io_r_resp_3_bits_perm_0_d(i_io_r_resp_3_bits_perm_0_d), .io_r_resp_3_bits_perm_0_a(i_io_r_resp_3_bits_perm_0_a), .io_r_resp_3_bits_perm_0_u(i_io_r_resp_3_bits_perm_0_u), .io_r_resp_3_bits_perm_0_x(i_io_r_resp_3_bits_perm_0_x), .io_r_resp_3_bits_perm_0_w(i_io_r_resp_3_bits_perm_0_w), .io_r_resp_3_bits_perm_0_r(i_io_r_resp_3_bits_perm_0_r), .io_r_resp_3_bits_g_perm_0_pf(i_io_r_resp_3_bits_g_perm_0_pf), .io_r_resp_3_bits_g_perm_0_af(i_io_r_resp_3_bits_g_perm_0_af), .io_r_resp_3_bits_g_perm_0_d(i_io_r_resp_3_bits_g_perm_0_d), .io_r_resp_3_bits_g_perm_0_a(i_io_r_resp_3_bits_g_perm_0_a), .io_r_resp_3_bits_g_perm_0_x(i_io_r_resp_3_bits_g_perm_0_x), .io_r_resp_3_bits_g_perm_0_w(i_io_r_resp_3_bits_g_perm_0_w), .io_r_resp_3_bits_g_perm_0_r(i_io_r_resp_3_bits_g_perm_0_r));

  task automatic do_check(int t);
    checks++;
    if (g_io_r_resp_0_bits_hit !== i_io_r_resp_0_bits_hit) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_hit g=%b i=%b",t,g_io_r_resp_0_bits_hit,i_io_r_resp_0_bits_hit); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_ppn_0 !== i_io_r_resp_0_bits_ppn_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_0_bits_ppn_0,i_io_r_resp_0_bits_ppn_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_ppn_1 !== i_io_r_resp_0_bits_ppn_1)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_0_bits_ppn_1,i_io_r_resp_0_bits_ppn_1); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_pbmt_0 !== i_io_r_resp_0_bits_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_0_bits_pbmt_0,i_io_r_resp_0_bits_pbmt_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_pbmt_0 !== i_io_r_resp_0_bits_g_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_0_bits_g_pbmt_0,i_io_r_resp_0_bits_g_pbmt_0); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_pf !== i_io_r_resp_0_bits_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_pf g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_pf,i_io_r_resp_0_bits_perm_0_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_af !== i_io_r_resp_0_bits_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_af g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_af,i_io_r_resp_0_bits_perm_0_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_v !== i_io_r_resp_0_bits_perm_0_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_v g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_v,i_io_r_resp_0_bits_perm_0_v); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_d !== i_io_r_resp_0_bits_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_d g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_d,i_io_r_resp_0_bits_perm_0_d); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_a !== i_io_r_resp_0_bits_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_a g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_a,i_io_r_resp_0_bits_perm_0_a); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_u !== i_io_r_resp_0_bits_perm_0_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_u g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_u,i_io_r_resp_0_bits_perm_0_u); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_x !== i_io_r_resp_0_bits_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_x g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_x,i_io_r_resp_0_bits_perm_0_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_w !== i_io_r_resp_0_bits_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_w g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_w,i_io_r_resp_0_bits_perm_0_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_0_r !== i_io_r_resp_0_bits_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_0_r g=%b i=%b",t,g_io_r_resp_0_bits_perm_0_r,i_io_r_resp_0_bits_perm_0_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_pf !== i_io_r_resp_0_bits_perm_1_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_pf g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_pf,i_io_r_resp_0_bits_perm_1_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_af !== i_io_r_resp_0_bits_perm_1_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_af g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_af,i_io_r_resp_0_bits_perm_1_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_v !== i_io_r_resp_0_bits_perm_1_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_v g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_v,i_io_r_resp_0_bits_perm_1_v); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_x !== i_io_r_resp_0_bits_perm_1_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_x g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_x,i_io_r_resp_0_bits_perm_1_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_w !== i_io_r_resp_0_bits_perm_1_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_w g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_w,i_io_r_resp_0_bits_perm_1_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_perm_1_r !== i_io_r_resp_0_bits_perm_1_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_perm_1_r g=%b i=%b",t,g_io_r_resp_0_bits_perm_1_r,i_io_r_resp_0_bits_perm_1_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_pf !== i_io_r_resp_0_bits_g_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_pf g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_pf,i_io_r_resp_0_bits_g_perm_0_pf); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_af !== i_io_r_resp_0_bits_g_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_af g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_af,i_io_r_resp_0_bits_g_perm_0_af); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_d !== i_io_r_resp_0_bits_g_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_d g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_d,i_io_r_resp_0_bits_g_perm_0_d); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_a !== i_io_r_resp_0_bits_g_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_a g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_a,i_io_r_resp_0_bits_g_perm_0_a); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_x !== i_io_r_resp_0_bits_g_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_x g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_x,i_io_r_resp_0_bits_g_perm_0_x); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_w !== i_io_r_resp_0_bits_g_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_w g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_w,i_io_r_resp_0_bits_g_perm_0_w); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_g_perm_0_r !== i_io_r_resp_0_bits_g_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_g_perm_0_r g=%b i=%b",t,g_io_r_resp_0_bits_g_perm_0_r,i_io_r_resp_0_bits_g_perm_0_r); end
    if (g_io_r_resp_0_bits_hit && (g_io_r_resp_0_bits_s2xlate_0 !== i_io_r_resp_0_bits_s2xlate_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_0_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_0_bits_s2xlate_0,i_io_r_resp_0_bits_s2xlate_0); end
    if (g_io_r_resp_1_bits_hit !== i_io_r_resp_1_bits_hit) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_hit g=%b i=%b",t,g_io_r_resp_1_bits_hit,i_io_r_resp_1_bits_hit); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_ppn_0 !== i_io_r_resp_1_bits_ppn_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_1_bits_ppn_0,i_io_r_resp_1_bits_ppn_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_ppn_1 !== i_io_r_resp_1_bits_ppn_1)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_1_bits_ppn_1,i_io_r_resp_1_bits_ppn_1); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_pbmt_0 !== i_io_r_resp_1_bits_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_1_bits_pbmt_0,i_io_r_resp_1_bits_pbmt_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_pbmt_0 !== i_io_r_resp_1_bits_g_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_1_bits_g_pbmt_0,i_io_r_resp_1_bits_g_pbmt_0); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_pf !== i_io_r_resp_1_bits_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_pf g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_pf,i_io_r_resp_1_bits_perm_0_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_af !== i_io_r_resp_1_bits_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_af g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_af,i_io_r_resp_1_bits_perm_0_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_v !== i_io_r_resp_1_bits_perm_0_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_v g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_v,i_io_r_resp_1_bits_perm_0_v); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_d !== i_io_r_resp_1_bits_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_d g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_d,i_io_r_resp_1_bits_perm_0_d); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_a !== i_io_r_resp_1_bits_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_a g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_a,i_io_r_resp_1_bits_perm_0_a); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_u !== i_io_r_resp_1_bits_perm_0_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_u g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_u,i_io_r_resp_1_bits_perm_0_u); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_x !== i_io_r_resp_1_bits_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_x g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_x,i_io_r_resp_1_bits_perm_0_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_w !== i_io_r_resp_1_bits_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_w g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_w,i_io_r_resp_1_bits_perm_0_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_0_r !== i_io_r_resp_1_bits_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_0_r g=%b i=%b",t,g_io_r_resp_1_bits_perm_0_r,i_io_r_resp_1_bits_perm_0_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_pf !== i_io_r_resp_1_bits_perm_1_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_pf g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_pf,i_io_r_resp_1_bits_perm_1_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_af !== i_io_r_resp_1_bits_perm_1_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_af g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_af,i_io_r_resp_1_bits_perm_1_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_v !== i_io_r_resp_1_bits_perm_1_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_v g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_v,i_io_r_resp_1_bits_perm_1_v); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_x !== i_io_r_resp_1_bits_perm_1_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_x g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_x,i_io_r_resp_1_bits_perm_1_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_w !== i_io_r_resp_1_bits_perm_1_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_w g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_w,i_io_r_resp_1_bits_perm_1_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_perm_1_r !== i_io_r_resp_1_bits_perm_1_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_perm_1_r g=%b i=%b",t,g_io_r_resp_1_bits_perm_1_r,i_io_r_resp_1_bits_perm_1_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_pf !== i_io_r_resp_1_bits_g_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_pf g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_pf,i_io_r_resp_1_bits_g_perm_0_pf); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_af !== i_io_r_resp_1_bits_g_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_af g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_af,i_io_r_resp_1_bits_g_perm_0_af); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_d !== i_io_r_resp_1_bits_g_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_d g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_d,i_io_r_resp_1_bits_g_perm_0_d); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_a !== i_io_r_resp_1_bits_g_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_a g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_a,i_io_r_resp_1_bits_g_perm_0_a); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_x !== i_io_r_resp_1_bits_g_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_x g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_x,i_io_r_resp_1_bits_g_perm_0_x); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_w !== i_io_r_resp_1_bits_g_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_w g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_w,i_io_r_resp_1_bits_g_perm_0_w); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_g_perm_0_r !== i_io_r_resp_1_bits_g_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_g_perm_0_r g=%b i=%b",t,g_io_r_resp_1_bits_g_perm_0_r,i_io_r_resp_1_bits_g_perm_0_r); end
    if (g_io_r_resp_1_bits_hit && (g_io_r_resp_1_bits_s2xlate_0 !== i_io_r_resp_1_bits_s2xlate_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_1_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_1_bits_s2xlate_0,i_io_r_resp_1_bits_s2xlate_0); end
    if (g_io_r_resp_2_bits_hit !== i_io_r_resp_2_bits_hit) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_hit g=%b i=%b",t,g_io_r_resp_2_bits_hit,i_io_r_resp_2_bits_hit); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_ppn_0 !== i_io_r_resp_2_bits_ppn_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_2_bits_ppn_0,i_io_r_resp_2_bits_ppn_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_ppn_1 !== i_io_r_resp_2_bits_ppn_1)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_ppn_1 g=%h i=%h",t,g_io_r_resp_2_bits_ppn_1,i_io_r_resp_2_bits_ppn_1); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_pbmt_0 !== i_io_r_resp_2_bits_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_2_bits_pbmt_0,i_io_r_resp_2_bits_pbmt_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_pbmt_0 !== i_io_r_resp_2_bits_g_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_2_bits_g_pbmt_0,i_io_r_resp_2_bits_g_pbmt_0); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_pf !== i_io_r_resp_2_bits_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_pf g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_pf,i_io_r_resp_2_bits_perm_0_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_af !== i_io_r_resp_2_bits_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_af g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_af,i_io_r_resp_2_bits_perm_0_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_v !== i_io_r_resp_2_bits_perm_0_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_v g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_v,i_io_r_resp_2_bits_perm_0_v); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_d !== i_io_r_resp_2_bits_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_d g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_d,i_io_r_resp_2_bits_perm_0_d); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_a !== i_io_r_resp_2_bits_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_a g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_a,i_io_r_resp_2_bits_perm_0_a); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_u !== i_io_r_resp_2_bits_perm_0_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_u g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_u,i_io_r_resp_2_bits_perm_0_u); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_x !== i_io_r_resp_2_bits_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_x g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_x,i_io_r_resp_2_bits_perm_0_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_w !== i_io_r_resp_2_bits_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_w g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_w,i_io_r_resp_2_bits_perm_0_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_0_r !== i_io_r_resp_2_bits_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_0_r g=%b i=%b",t,g_io_r_resp_2_bits_perm_0_r,i_io_r_resp_2_bits_perm_0_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_pf !== i_io_r_resp_2_bits_perm_1_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_pf g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_pf,i_io_r_resp_2_bits_perm_1_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_af !== i_io_r_resp_2_bits_perm_1_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_af g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_af,i_io_r_resp_2_bits_perm_1_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_v !== i_io_r_resp_2_bits_perm_1_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_v g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_v,i_io_r_resp_2_bits_perm_1_v); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_x !== i_io_r_resp_2_bits_perm_1_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_x g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_x,i_io_r_resp_2_bits_perm_1_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_w !== i_io_r_resp_2_bits_perm_1_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_w g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_w,i_io_r_resp_2_bits_perm_1_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_perm_1_r !== i_io_r_resp_2_bits_perm_1_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_perm_1_r g=%b i=%b",t,g_io_r_resp_2_bits_perm_1_r,i_io_r_resp_2_bits_perm_1_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_pf !== i_io_r_resp_2_bits_g_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_pf g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_pf,i_io_r_resp_2_bits_g_perm_0_pf); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_af !== i_io_r_resp_2_bits_g_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_af g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_af,i_io_r_resp_2_bits_g_perm_0_af); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_d !== i_io_r_resp_2_bits_g_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_d g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_d,i_io_r_resp_2_bits_g_perm_0_d); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_a !== i_io_r_resp_2_bits_g_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_a g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_a,i_io_r_resp_2_bits_g_perm_0_a); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_x !== i_io_r_resp_2_bits_g_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_x g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_x,i_io_r_resp_2_bits_g_perm_0_x); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_w !== i_io_r_resp_2_bits_g_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_w g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_w,i_io_r_resp_2_bits_g_perm_0_w); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_g_perm_0_r !== i_io_r_resp_2_bits_g_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_g_perm_0_r g=%b i=%b",t,g_io_r_resp_2_bits_g_perm_0_r,i_io_r_resp_2_bits_g_perm_0_r); end
    if (g_io_r_resp_2_bits_hit && (g_io_r_resp_2_bits_s2xlate_0 !== i_io_r_resp_2_bits_s2xlate_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_2_bits_s2xlate_0 g=%h i=%h",t,g_io_r_resp_2_bits_s2xlate_0,i_io_r_resp_2_bits_s2xlate_0); end
    if (g_io_r_resp_3_bits_hit !== i_io_r_resp_3_bits_hit) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_hit g=%b i=%b",t,g_io_r_resp_3_bits_hit,i_io_r_resp_3_bits_hit); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_ppn_0 !== i_io_r_resp_3_bits_ppn_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_ppn_0 g=%h i=%h",t,g_io_r_resp_3_bits_ppn_0,i_io_r_resp_3_bits_ppn_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_pbmt_0 !== i_io_r_resp_3_bits_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_pbmt_0 g=%h i=%h",t,g_io_r_resp_3_bits_pbmt_0,i_io_r_resp_3_bits_pbmt_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_pbmt_0 !== i_io_r_resp_3_bits_g_pbmt_0)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_pbmt_0 g=%h i=%h",t,g_io_r_resp_3_bits_g_pbmt_0,i_io_r_resp_3_bits_g_pbmt_0); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_pf !== i_io_r_resp_3_bits_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_pf g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_pf,i_io_r_resp_3_bits_perm_0_pf); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_af !== i_io_r_resp_3_bits_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_af g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_af,i_io_r_resp_3_bits_perm_0_af); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_v !== i_io_r_resp_3_bits_perm_0_v)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_v g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_v,i_io_r_resp_3_bits_perm_0_v); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_d !== i_io_r_resp_3_bits_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_d g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_d,i_io_r_resp_3_bits_perm_0_d); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_a !== i_io_r_resp_3_bits_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_a g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_a,i_io_r_resp_3_bits_perm_0_a); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_u !== i_io_r_resp_3_bits_perm_0_u)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_u g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_u,i_io_r_resp_3_bits_perm_0_u); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_x !== i_io_r_resp_3_bits_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_x g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_x,i_io_r_resp_3_bits_perm_0_x); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_w !== i_io_r_resp_3_bits_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_w g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_w,i_io_r_resp_3_bits_perm_0_w); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_perm_0_r !== i_io_r_resp_3_bits_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_perm_0_r g=%b i=%b",t,g_io_r_resp_3_bits_perm_0_r,i_io_r_resp_3_bits_perm_0_r); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_pf !== i_io_r_resp_3_bits_g_perm_0_pf)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_pf g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_pf,i_io_r_resp_3_bits_g_perm_0_pf); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_af !== i_io_r_resp_3_bits_g_perm_0_af)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_af g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_af,i_io_r_resp_3_bits_g_perm_0_af); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_d !== i_io_r_resp_3_bits_g_perm_0_d)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_d g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_d,i_io_r_resp_3_bits_g_perm_0_d); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_a !== i_io_r_resp_3_bits_g_perm_0_a)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_a g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_a,i_io_r_resp_3_bits_g_perm_0_a); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_x !== i_io_r_resp_3_bits_g_perm_0_x)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_x g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_x,i_io_r_resp_3_bits_g_perm_0_x); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_w !== i_io_r_resp_3_bits_g_perm_0_w)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_w g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_w,i_io_r_resp_3_bits_g_perm_0_w); end
    if (g_io_r_resp_3_bits_hit && (g_io_r_resp_3_bits_g_perm_0_r !== i_io_r_resp_3_bits_g_perm_0_r)) begin errors++;
      if(errors<=80) $display("vec %0d io_r_resp_3_bits_g_perm_0_r g=%b i=%b",t,g_io_r_resp_3_bits_g_perm_0_r,i_io_r_resp_3_bits_g_perm_0_r); end
  endtask

  task automatic drive_random();
    automatic int act = $urandom_range(0,9);
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
    io_csr_mbmc_BME = $urandom_range(0,1);
    io_csr_mbmc_CMODE = $urandom_range(0,1);
    io_csr_priv_virt = $urandom_range(0,1);
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
    io_w_bits_data_s2xlate = 2'($urandom);
    io_w_bits_data_s1_entry_tag = {$urandom, $urandom};
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
    io_w_bits_data_s1_ppn_low_1 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_2 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_3 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_4 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_5 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_6 = 3'($urandom);
    io_w_bits_data_s1_ppn_low_7 = 3'($urandom);
    io_w_bits_data_s1_valididx_0 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_1 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_2 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_3 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_4 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_5 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_6 = $urandom_range(0,1);
    io_w_bits_data_s1_valididx_7 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_0 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_1 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_2 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_3 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_4 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_5 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_6 = $urandom_range(0,1);
    io_w_bits_data_s1_pteidx_7 = $urandom_range(0,1);
    io_w_bits_data_s1_pf = $urandom_range(0,1);
    io_w_bits_data_s1_af = $urandom_range(0,1);
    io_w_bits_data_s2_entry_tag = {$urandom, $urandom};
    io_w_bits_data_s2_entry_vmid = 14'($urandom);
    io_w_bits_data_s2_entry_n = $urandom_range(0,1);
    io_w_bits_data_s2_entry_pbmt = 2'($urandom);
    io_w_bits_data_s2_entry_ppn = {$urandom, $urandom};
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
  endtask

  // ---------------------------------------------------------------------------
  // 定向激励: sfence 的失效范围要看 mbmc.BME/CMODE（golden TLBFA_1.sv）
  //   else if (io_sfence_valid & ~hg & ~hv)
  //     if (rs1 | priv_virt | io_csr_mbmc_BME & ~io_csr_mbmc_CMODE)
  //   本层只透传这两根线。透传漏了 ⇒ 内层输入悬空 ⇒ if(x) 判假 ⇒ 掉进按地址失效的
  //   `else if (rs2)` 分支。所以 sfence 地址必须**不匹配**写入的 tag，否则两侧都失效、
  //   激励白做（addr[49:39] 全 1 vs tag[34:24]=0）。
  // ---------------------------------------------------------------------------
  int directed_errors = 0;
  task automatic dir_clear();
    io_sfence_valid = '0;
    io_sfence_bits_rs1 = '0;
    io_sfence_bits_rs2 = '0;
    io_sfence_bits_addr = '0;
    io_sfence_bits_id = '0;
    io_sfence_bits_hv = '0;
    io_sfence_bits_hg = '0;
    io_csr_satp_asid = '0;
    io_csr_vsatp_asid = '0;
    io_csr_hgatp_vmid = '0;
    io_csr_mbmc_BME = '0;
    io_csr_mbmc_CMODE = '0;
    io_csr_priv_virt = '0;
    io_r_req_0_valid = '0;
    io_r_req_0_bits_vpn = '0;
    io_r_req_0_bits_s2xlate = '0;
    io_r_req_1_valid = '0;
    io_r_req_1_bits_vpn = '0;
    io_r_req_1_bits_s2xlate = '0;
    io_r_req_2_valid = '0;
    io_r_req_2_bits_vpn = '0;
    io_r_req_2_bits_s2xlate = '0;
    io_r_req_3_valid = '0;
    io_r_req_3_bits_vpn = '0;
    io_r_req_3_bits_s2xlate = '0;
    io_w_valid = '0;
    io_w_bits_data_s2xlate = '0;
    io_w_bits_data_s1_entry_tag = '0;
    io_w_bits_data_s1_entry_asid = '0;
    io_w_bits_data_s1_entry_vmid = '0;
    io_w_bits_data_s1_entry_n = '0;
    io_w_bits_data_s1_entry_pbmt = '0;
    io_w_bits_data_s1_entry_perm_d = '0;
    io_w_bits_data_s1_entry_perm_a = '0;
    io_w_bits_data_s1_entry_perm_g = '0;
    io_w_bits_data_s1_entry_perm_u = '0;
    io_w_bits_data_s1_entry_perm_x = '0;
    io_w_bits_data_s1_entry_perm_w = '0;
    io_w_bits_data_s1_entry_perm_r = '0;
    io_w_bits_data_s1_entry_level = '0;
    io_w_bits_data_s1_entry_v = '0;
    io_w_bits_data_s1_entry_ppn = '0;
    io_w_bits_data_s1_ppn_low_0 = '0;
    io_w_bits_data_s1_ppn_low_1 = '0;
    io_w_bits_data_s1_ppn_low_2 = '0;
    io_w_bits_data_s1_ppn_low_3 = '0;
    io_w_bits_data_s1_ppn_low_4 = '0;
    io_w_bits_data_s1_ppn_low_5 = '0;
    io_w_bits_data_s1_ppn_low_6 = '0;
    io_w_bits_data_s1_ppn_low_7 = '0;
    io_w_bits_data_s1_valididx_0 = '0;
    io_w_bits_data_s1_valididx_1 = '0;
    io_w_bits_data_s1_valididx_2 = '0;
    io_w_bits_data_s1_valididx_3 = '0;
    io_w_bits_data_s1_valididx_4 = '0;
    io_w_bits_data_s1_valididx_5 = '0;
    io_w_bits_data_s1_valididx_6 = '0;
    io_w_bits_data_s1_valididx_7 = '0;
    io_w_bits_data_s1_pteidx_0 = '0;
    io_w_bits_data_s1_pteidx_1 = '0;
    io_w_bits_data_s1_pteidx_2 = '0;
    io_w_bits_data_s1_pteidx_3 = '0;
    io_w_bits_data_s1_pteidx_4 = '0;
    io_w_bits_data_s1_pteidx_5 = '0;
    io_w_bits_data_s1_pteidx_6 = '0;
    io_w_bits_data_s1_pteidx_7 = '0;
    io_w_bits_data_s1_pf = '0;
    io_w_bits_data_s1_af = '0;
    io_w_bits_data_s2_entry_tag = '0;
    io_w_bits_data_s2_entry_vmid = '0;
    io_w_bits_data_s2_entry_n = '0;
    io_w_bits_data_s2_entry_pbmt = '0;
    io_w_bits_data_s2_entry_ppn = '0;
    io_w_bits_data_s2_entry_perm_d = '0;
    io_w_bits_data_s2_entry_perm_a = '0;
    io_w_bits_data_s2_entry_perm_g = '0;
    io_w_bits_data_s2_entry_perm_u = '0;
    io_w_bits_data_s2_entry_perm_x = '0;
    io_w_bits_data_s2_entry_perm_w = '0;
    io_w_bits_data_s2_entry_perm_r = '0;
    io_w_bits_data_s2_entry_level = '0;
    io_w_bits_data_s2_gpf = '0;
    io_w_bits_data_s2_gaf = '0;
  endtask

  task automatic dir_write_one_entry();
    // s2xlate=0 / perm_g=1 / level=3 / valididx 全 1 ⇒ 读回命中只取决于 v_way
    io_w_valid = 1;
    io_w_bits_data_s2xlate = 2'b00;
    io_w_bits_data_s1_entry_perm_g = 1'b1;
    io_w_bits_data_s1_entry_perm_r = 1'b1;
    io_w_bits_data_s1_entry_level = 2'b11;
    io_w_bits_data_s1_entry_v = 1'b1;
    io_w_bits_data_s1_valididx_0 = 1'b1;
    io_w_bits_data_s1_valididx_1 = 1'b1;
    io_w_bits_data_s1_valididx_2 = 1'b1;
    io_w_bits_data_s1_valididx_3 = 1'b1;
    io_w_bits_data_s1_valididx_4 = 1'b1;
    io_w_bits_data_s1_valididx_5 = 1'b1;
    io_w_bits_data_s1_valididx_6 = 1'b1;
    io_w_bits_data_s1_valididx_7 = 1'b1;
    @(posedge clock); #1;
    io_w_valid = 0;
    @(posedge clock); #1;   // 等 refill_mask 落下
  endtask

  task automatic dir_read(output logic gh, output logic ih);
    io_r_req_0_valid = 1; io_r_req_0_bits_vpn = '0; io_r_req_0_bits_s2xlate = '0;
    @(posedge clock); #1;
    gh = g_io_r_resp_0_bits_hit;
    ih = i_io_r_resp_0_bits_hit;
    io_r_req_0_valid = 0;
  endtask

  task automatic directed_mbmc_sfence();
    logic gh, ih;
    dir_clear();
    @(posedge clock); #1;
    dir_write_one_entry();
    dir_read(gh, ih);
    if (gh !== 1'b1) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— 写入后 golden 未命中 (g_hit=%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc: 写入/读回阶段就已失配 g_hit=%b i_hit=%b", gh, ih);
    end
    io_sfence_valid = 1; io_sfence_bits_rs1 = 0; io_sfence_bits_rs2 = 1;
    io_sfence_bits_addr = {11'h7FF, 39'h0};
    io_sfence_bits_hv = 0; io_sfence_bits_hg = 0;
    io_csr_priv_virt = 0; io_csr_mbmc_BME = 1; io_csr_mbmc_CMODE = 0;
    @(posedge clock); #1;
    io_sfence_valid = 0;
    @(posedge clock); #1;
    dir_read(gh, ih);
    if (gh !== 1'b0) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— BME sfence 后 golden 仍命中 (g_hit=%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc MISMATCH: sfence(BME=1,CMODE=0,rs1=0,priv_virt=0) 后 g_hit=%b i_hit=%b —— io_csr_mbmc_BME/CMODE 没透传给内层 TLBFA_1", gh, ih);
    end
    dir_clear();
    @(posedge clock); #1;
    $display("DIRECTED mbmc_sfence errors=%0d", directed_errors);
  endtask

  task automatic dir_warm_ports();
    dir_clear();
    io_r_req_0_valid = 1;
    io_r_req_1_valid = 1;
    io_r_req_2_valid = 1;
    io_r_req_3_valid = 1;
    repeat (2) @(posedge clock); #1;
    dir_clear();
    @(posedge clock); #1;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NVEC));   // ut_common 统一下发 +ncycles
    reset = 1;
    dir_clear();
    repeat (3) @(posedge clock); #1; reset = 0;
    @(posedge clock);
    directed_mbmc_sfence();
    dir_warm_ports();
    errors += directed_errors;
    for (int t = 0; t < NVEC; t++) begin
      drive_random();
      @(posedge clock); #1;
      do_check(t);
    end
    $display("checks=%0d errors=%0d (含 directed=%0d)", checks, errors, directed_errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
