`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic [3:0] io_csr_satp_mode;
  logic [15:0] io_csr_satp_asid;
  logic [43:0] io_csr_satp_ppn;
  logic io_csr_satp_changed;
  logic [3:0] io_csr_vsatp_mode;
  logic [15:0] io_csr_vsatp_asid;
  logic [43:0] io_csr_vsatp_ppn;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_mxr;
  logic io_csr_mPBMTE;
  logic io_csr_hPBMTE;
  logic io_req_valid;
  logic [37:0] io_req_bits_req_info_vpn;
  logic [1:0] io_req_bits_req_info_s2xlate;
  logic [1:0] io_req_bits_req_info_source;
  logic io_req_bits_l3Hit;
  logic io_req_bits_l2Hit;
  logic [43:0] io_req_bits_ppn;
  logic io_req_bits_stage1Hit;
  logic [34:0] io_req_bits_stage1_entry_0_tag;
  logic [15:0] io_req_bits_stage1_entry_0_asid;
  logic [13:0] io_req_bits_stage1_entry_0_vmid;
  logic io_req_bits_stage1_entry_0_n;
  logic [1:0] io_req_bits_stage1_entry_0_pbmt;
  logic io_req_bits_stage1_entry_0_perm_d;
  logic io_req_bits_stage1_entry_0_perm_a;
  logic io_req_bits_stage1_entry_0_perm_g;
  logic io_req_bits_stage1_entry_0_perm_u;
  logic io_req_bits_stage1_entry_0_perm_x;
  logic io_req_bits_stage1_entry_0_perm_w;
  logic io_req_bits_stage1_entry_0_perm_r;
  logic [1:0] io_req_bits_stage1_entry_0_level;
  logic io_req_bits_stage1_entry_0_v;
  logic [40:0] io_req_bits_stage1_entry_0_ppn;
  logic [2:0] io_req_bits_stage1_entry_0_ppn_low;
  logic io_req_bits_stage1_entry_0_pf;
  logic [34:0] io_req_bits_stage1_entry_1_tag;
  logic [15:0] io_req_bits_stage1_entry_1_asid;
  logic [13:0] io_req_bits_stage1_entry_1_vmid;
  logic io_req_bits_stage1_entry_1_n;
  logic [1:0] io_req_bits_stage1_entry_1_pbmt;
  logic io_req_bits_stage1_entry_1_perm_d;
  logic io_req_bits_stage1_entry_1_perm_a;
  logic io_req_bits_stage1_entry_1_perm_g;
  logic io_req_bits_stage1_entry_1_perm_u;
  logic io_req_bits_stage1_entry_1_perm_x;
  logic io_req_bits_stage1_entry_1_perm_w;
  logic io_req_bits_stage1_entry_1_perm_r;
  logic [1:0] io_req_bits_stage1_entry_1_level;
  logic io_req_bits_stage1_entry_1_v;
  logic [40:0] io_req_bits_stage1_entry_1_ppn;
  logic [2:0] io_req_bits_stage1_entry_1_ppn_low;
  logic io_req_bits_stage1_entry_1_pf;
  logic [34:0] io_req_bits_stage1_entry_2_tag;
  logic [15:0] io_req_bits_stage1_entry_2_asid;
  logic [13:0] io_req_bits_stage1_entry_2_vmid;
  logic io_req_bits_stage1_entry_2_n;
  logic [1:0] io_req_bits_stage1_entry_2_pbmt;
  logic io_req_bits_stage1_entry_2_perm_d;
  logic io_req_bits_stage1_entry_2_perm_a;
  logic io_req_bits_stage1_entry_2_perm_g;
  logic io_req_bits_stage1_entry_2_perm_u;
  logic io_req_bits_stage1_entry_2_perm_x;
  logic io_req_bits_stage1_entry_2_perm_w;
  logic io_req_bits_stage1_entry_2_perm_r;
  logic [1:0] io_req_bits_stage1_entry_2_level;
  logic io_req_bits_stage1_entry_2_v;
  logic [40:0] io_req_bits_stage1_entry_2_ppn;
  logic [2:0] io_req_bits_stage1_entry_2_ppn_low;
  logic io_req_bits_stage1_entry_2_pf;
  logic [34:0] io_req_bits_stage1_entry_3_tag;
  logic [15:0] io_req_bits_stage1_entry_3_asid;
  logic [13:0] io_req_bits_stage1_entry_3_vmid;
  logic io_req_bits_stage1_entry_3_n;
  logic [1:0] io_req_bits_stage1_entry_3_pbmt;
  logic io_req_bits_stage1_entry_3_perm_d;
  logic io_req_bits_stage1_entry_3_perm_a;
  logic io_req_bits_stage1_entry_3_perm_g;
  logic io_req_bits_stage1_entry_3_perm_u;
  logic io_req_bits_stage1_entry_3_perm_x;
  logic io_req_bits_stage1_entry_3_perm_w;
  logic io_req_bits_stage1_entry_3_perm_r;
  logic [1:0] io_req_bits_stage1_entry_3_level;
  logic io_req_bits_stage1_entry_3_v;
  logic [40:0] io_req_bits_stage1_entry_3_ppn;
  logic [2:0] io_req_bits_stage1_entry_3_ppn_low;
  logic io_req_bits_stage1_entry_3_pf;
  logic [34:0] io_req_bits_stage1_entry_4_tag;
  logic [15:0] io_req_bits_stage1_entry_4_asid;
  logic [13:0] io_req_bits_stage1_entry_4_vmid;
  logic io_req_bits_stage1_entry_4_n;
  logic [1:0] io_req_bits_stage1_entry_4_pbmt;
  logic io_req_bits_stage1_entry_4_perm_d;
  logic io_req_bits_stage1_entry_4_perm_a;
  logic io_req_bits_stage1_entry_4_perm_g;
  logic io_req_bits_stage1_entry_4_perm_u;
  logic io_req_bits_stage1_entry_4_perm_x;
  logic io_req_bits_stage1_entry_4_perm_w;
  logic io_req_bits_stage1_entry_4_perm_r;
  logic [1:0] io_req_bits_stage1_entry_4_level;
  logic io_req_bits_stage1_entry_4_v;
  logic [40:0] io_req_bits_stage1_entry_4_ppn;
  logic [2:0] io_req_bits_stage1_entry_4_ppn_low;
  logic io_req_bits_stage1_entry_4_pf;
  logic [34:0] io_req_bits_stage1_entry_5_tag;
  logic [15:0] io_req_bits_stage1_entry_5_asid;
  logic [13:0] io_req_bits_stage1_entry_5_vmid;
  logic io_req_bits_stage1_entry_5_n;
  logic [1:0] io_req_bits_stage1_entry_5_pbmt;
  logic io_req_bits_stage1_entry_5_perm_d;
  logic io_req_bits_stage1_entry_5_perm_a;
  logic io_req_bits_stage1_entry_5_perm_g;
  logic io_req_bits_stage1_entry_5_perm_u;
  logic io_req_bits_stage1_entry_5_perm_x;
  logic io_req_bits_stage1_entry_5_perm_w;
  logic io_req_bits_stage1_entry_5_perm_r;
  logic [1:0] io_req_bits_stage1_entry_5_level;
  logic io_req_bits_stage1_entry_5_v;
  logic [40:0] io_req_bits_stage1_entry_5_ppn;
  logic [2:0] io_req_bits_stage1_entry_5_ppn_low;
  logic io_req_bits_stage1_entry_5_pf;
  logic [34:0] io_req_bits_stage1_entry_6_tag;
  logic [15:0] io_req_bits_stage1_entry_6_asid;
  logic [13:0] io_req_bits_stage1_entry_6_vmid;
  logic io_req_bits_stage1_entry_6_n;
  logic [1:0] io_req_bits_stage1_entry_6_pbmt;
  logic io_req_bits_stage1_entry_6_perm_d;
  logic io_req_bits_stage1_entry_6_perm_a;
  logic io_req_bits_stage1_entry_6_perm_g;
  logic io_req_bits_stage1_entry_6_perm_u;
  logic io_req_bits_stage1_entry_6_perm_x;
  logic io_req_bits_stage1_entry_6_perm_w;
  logic io_req_bits_stage1_entry_6_perm_r;
  logic [1:0] io_req_bits_stage1_entry_6_level;
  logic io_req_bits_stage1_entry_6_v;
  logic [40:0] io_req_bits_stage1_entry_6_ppn;
  logic [2:0] io_req_bits_stage1_entry_6_ppn_low;
  logic io_req_bits_stage1_entry_6_pf;
  logic [34:0] io_req_bits_stage1_entry_7_tag;
  logic [15:0] io_req_bits_stage1_entry_7_asid;
  logic [13:0] io_req_bits_stage1_entry_7_vmid;
  logic io_req_bits_stage1_entry_7_n;
  logic [1:0] io_req_bits_stage1_entry_7_pbmt;
  logic io_req_bits_stage1_entry_7_perm_d;
  logic io_req_bits_stage1_entry_7_perm_a;
  logic io_req_bits_stage1_entry_7_perm_g;
  logic io_req_bits_stage1_entry_7_perm_u;
  logic io_req_bits_stage1_entry_7_perm_x;
  logic io_req_bits_stage1_entry_7_perm_w;
  logic io_req_bits_stage1_entry_7_perm_r;
  logic [1:0] io_req_bits_stage1_entry_7_level;
  logic io_req_bits_stage1_entry_7_v;
  logic [40:0] io_req_bits_stage1_entry_7_ppn;
  logic [2:0] io_req_bits_stage1_entry_7_ppn_low;
  logic io_req_bits_stage1_entry_7_pf;
  logic io_req_bits_stage1_pteidx_0;
  logic io_req_bits_stage1_pteidx_1;
  logic io_req_bits_stage1_pteidx_2;
  logic io_req_bits_stage1_pteidx_3;
  logic io_req_bits_stage1_pteidx_4;
  logic io_req_bits_stage1_pteidx_5;
  logic io_req_bits_stage1_pteidx_6;
  logic io_req_bits_stage1_pteidx_7;
  logic io_req_bits_stage1_not_super;
  logic io_resp_ready;
  logic io_llptw_ready;
  logic io_hptw_req_ready;
  logic io_hptw_resp_valid;
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
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [63:0] io_mem_resp_bits;
  logic io_mem_mask;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire [1:0] g_io_resp_bits_source;
  wire [1:0] i_io_resp_bits_source;
  wire [1:0] g_io_resp_bits_s2xlate;
  wire [1:0] i_io_resp_bits_s2xlate;
  wire [34:0] g_io_resp_bits_resp_entry_0_tag;
  wire [34:0] i_io_resp_bits_resp_entry_0_tag;
  wire [15:0] g_io_resp_bits_resp_entry_0_asid;
  wire [15:0] i_io_resp_bits_resp_entry_0_asid;
  wire [13:0] g_io_resp_bits_resp_entry_0_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_0_vmid;
  wire g_io_resp_bits_resp_entry_0_n;
  wire i_io_resp_bits_resp_entry_0_n;
  wire [1:0] g_io_resp_bits_resp_entry_0_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_0_pbmt;
  wire g_io_resp_bits_resp_entry_0_perm_d;
  wire i_io_resp_bits_resp_entry_0_perm_d;
  wire g_io_resp_bits_resp_entry_0_perm_a;
  wire i_io_resp_bits_resp_entry_0_perm_a;
  wire g_io_resp_bits_resp_entry_0_perm_g;
  wire i_io_resp_bits_resp_entry_0_perm_g;
  wire g_io_resp_bits_resp_entry_0_perm_u;
  wire i_io_resp_bits_resp_entry_0_perm_u;
  wire g_io_resp_bits_resp_entry_0_perm_x;
  wire i_io_resp_bits_resp_entry_0_perm_x;
  wire g_io_resp_bits_resp_entry_0_perm_w;
  wire i_io_resp_bits_resp_entry_0_perm_w;
  wire g_io_resp_bits_resp_entry_0_perm_r;
  wire i_io_resp_bits_resp_entry_0_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_0_level;
  wire [1:0] i_io_resp_bits_resp_entry_0_level;
  wire g_io_resp_bits_resp_entry_0_v;
  wire i_io_resp_bits_resp_entry_0_v;
  wire [40:0] g_io_resp_bits_resp_entry_0_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_0_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_0_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_0_ppn_low;
  wire g_io_resp_bits_resp_entry_0_af;
  wire i_io_resp_bits_resp_entry_0_af;
  wire g_io_resp_bits_resp_entry_0_pf;
  wire i_io_resp_bits_resp_entry_0_pf;
  wire [34:0] g_io_resp_bits_resp_entry_1_tag;
  wire [34:0] i_io_resp_bits_resp_entry_1_tag;
  wire [15:0] g_io_resp_bits_resp_entry_1_asid;
  wire [15:0] i_io_resp_bits_resp_entry_1_asid;
  wire [13:0] g_io_resp_bits_resp_entry_1_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_1_vmid;
  wire g_io_resp_bits_resp_entry_1_n;
  wire i_io_resp_bits_resp_entry_1_n;
  wire [1:0] g_io_resp_bits_resp_entry_1_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_1_pbmt;
  wire g_io_resp_bits_resp_entry_1_perm_d;
  wire i_io_resp_bits_resp_entry_1_perm_d;
  wire g_io_resp_bits_resp_entry_1_perm_a;
  wire i_io_resp_bits_resp_entry_1_perm_a;
  wire g_io_resp_bits_resp_entry_1_perm_g;
  wire i_io_resp_bits_resp_entry_1_perm_g;
  wire g_io_resp_bits_resp_entry_1_perm_u;
  wire i_io_resp_bits_resp_entry_1_perm_u;
  wire g_io_resp_bits_resp_entry_1_perm_x;
  wire i_io_resp_bits_resp_entry_1_perm_x;
  wire g_io_resp_bits_resp_entry_1_perm_w;
  wire i_io_resp_bits_resp_entry_1_perm_w;
  wire g_io_resp_bits_resp_entry_1_perm_r;
  wire i_io_resp_bits_resp_entry_1_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_1_level;
  wire [1:0] i_io_resp_bits_resp_entry_1_level;
  wire g_io_resp_bits_resp_entry_1_v;
  wire i_io_resp_bits_resp_entry_1_v;
  wire [40:0] g_io_resp_bits_resp_entry_1_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_1_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_1_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_1_ppn_low;
  wire g_io_resp_bits_resp_entry_1_af;
  wire i_io_resp_bits_resp_entry_1_af;
  wire g_io_resp_bits_resp_entry_1_pf;
  wire i_io_resp_bits_resp_entry_1_pf;
  wire [34:0] g_io_resp_bits_resp_entry_2_tag;
  wire [34:0] i_io_resp_bits_resp_entry_2_tag;
  wire [15:0] g_io_resp_bits_resp_entry_2_asid;
  wire [15:0] i_io_resp_bits_resp_entry_2_asid;
  wire [13:0] g_io_resp_bits_resp_entry_2_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_2_vmid;
  wire g_io_resp_bits_resp_entry_2_n;
  wire i_io_resp_bits_resp_entry_2_n;
  wire [1:0] g_io_resp_bits_resp_entry_2_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_2_pbmt;
  wire g_io_resp_bits_resp_entry_2_perm_d;
  wire i_io_resp_bits_resp_entry_2_perm_d;
  wire g_io_resp_bits_resp_entry_2_perm_a;
  wire i_io_resp_bits_resp_entry_2_perm_a;
  wire g_io_resp_bits_resp_entry_2_perm_g;
  wire i_io_resp_bits_resp_entry_2_perm_g;
  wire g_io_resp_bits_resp_entry_2_perm_u;
  wire i_io_resp_bits_resp_entry_2_perm_u;
  wire g_io_resp_bits_resp_entry_2_perm_x;
  wire i_io_resp_bits_resp_entry_2_perm_x;
  wire g_io_resp_bits_resp_entry_2_perm_w;
  wire i_io_resp_bits_resp_entry_2_perm_w;
  wire g_io_resp_bits_resp_entry_2_perm_r;
  wire i_io_resp_bits_resp_entry_2_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_2_level;
  wire [1:0] i_io_resp_bits_resp_entry_2_level;
  wire g_io_resp_bits_resp_entry_2_v;
  wire i_io_resp_bits_resp_entry_2_v;
  wire [40:0] g_io_resp_bits_resp_entry_2_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_2_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_2_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_2_ppn_low;
  wire g_io_resp_bits_resp_entry_2_af;
  wire i_io_resp_bits_resp_entry_2_af;
  wire g_io_resp_bits_resp_entry_2_pf;
  wire i_io_resp_bits_resp_entry_2_pf;
  wire [34:0] g_io_resp_bits_resp_entry_3_tag;
  wire [34:0] i_io_resp_bits_resp_entry_3_tag;
  wire [15:0] g_io_resp_bits_resp_entry_3_asid;
  wire [15:0] i_io_resp_bits_resp_entry_3_asid;
  wire [13:0] g_io_resp_bits_resp_entry_3_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_3_vmid;
  wire g_io_resp_bits_resp_entry_3_n;
  wire i_io_resp_bits_resp_entry_3_n;
  wire [1:0] g_io_resp_bits_resp_entry_3_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_3_pbmt;
  wire g_io_resp_bits_resp_entry_3_perm_d;
  wire i_io_resp_bits_resp_entry_3_perm_d;
  wire g_io_resp_bits_resp_entry_3_perm_a;
  wire i_io_resp_bits_resp_entry_3_perm_a;
  wire g_io_resp_bits_resp_entry_3_perm_g;
  wire i_io_resp_bits_resp_entry_3_perm_g;
  wire g_io_resp_bits_resp_entry_3_perm_u;
  wire i_io_resp_bits_resp_entry_3_perm_u;
  wire g_io_resp_bits_resp_entry_3_perm_x;
  wire i_io_resp_bits_resp_entry_3_perm_x;
  wire g_io_resp_bits_resp_entry_3_perm_w;
  wire i_io_resp_bits_resp_entry_3_perm_w;
  wire g_io_resp_bits_resp_entry_3_perm_r;
  wire i_io_resp_bits_resp_entry_3_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_3_level;
  wire [1:0] i_io_resp_bits_resp_entry_3_level;
  wire g_io_resp_bits_resp_entry_3_v;
  wire i_io_resp_bits_resp_entry_3_v;
  wire [40:0] g_io_resp_bits_resp_entry_3_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_3_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_3_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_3_ppn_low;
  wire g_io_resp_bits_resp_entry_3_af;
  wire i_io_resp_bits_resp_entry_3_af;
  wire g_io_resp_bits_resp_entry_3_pf;
  wire i_io_resp_bits_resp_entry_3_pf;
  wire [34:0] g_io_resp_bits_resp_entry_4_tag;
  wire [34:0] i_io_resp_bits_resp_entry_4_tag;
  wire [15:0] g_io_resp_bits_resp_entry_4_asid;
  wire [15:0] i_io_resp_bits_resp_entry_4_asid;
  wire [13:0] g_io_resp_bits_resp_entry_4_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_4_vmid;
  wire g_io_resp_bits_resp_entry_4_n;
  wire i_io_resp_bits_resp_entry_4_n;
  wire [1:0] g_io_resp_bits_resp_entry_4_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_4_pbmt;
  wire g_io_resp_bits_resp_entry_4_perm_d;
  wire i_io_resp_bits_resp_entry_4_perm_d;
  wire g_io_resp_bits_resp_entry_4_perm_a;
  wire i_io_resp_bits_resp_entry_4_perm_a;
  wire g_io_resp_bits_resp_entry_4_perm_g;
  wire i_io_resp_bits_resp_entry_4_perm_g;
  wire g_io_resp_bits_resp_entry_4_perm_u;
  wire i_io_resp_bits_resp_entry_4_perm_u;
  wire g_io_resp_bits_resp_entry_4_perm_x;
  wire i_io_resp_bits_resp_entry_4_perm_x;
  wire g_io_resp_bits_resp_entry_4_perm_w;
  wire i_io_resp_bits_resp_entry_4_perm_w;
  wire g_io_resp_bits_resp_entry_4_perm_r;
  wire i_io_resp_bits_resp_entry_4_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_4_level;
  wire [1:0] i_io_resp_bits_resp_entry_4_level;
  wire g_io_resp_bits_resp_entry_4_v;
  wire i_io_resp_bits_resp_entry_4_v;
  wire [40:0] g_io_resp_bits_resp_entry_4_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_4_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_4_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_4_ppn_low;
  wire g_io_resp_bits_resp_entry_4_af;
  wire i_io_resp_bits_resp_entry_4_af;
  wire g_io_resp_bits_resp_entry_4_pf;
  wire i_io_resp_bits_resp_entry_4_pf;
  wire [34:0] g_io_resp_bits_resp_entry_5_tag;
  wire [34:0] i_io_resp_bits_resp_entry_5_tag;
  wire [15:0] g_io_resp_bits_resp_entry_5_asid;
  wire [15:0] i_io_resp_bits_resp_entry_5_asid;
  wire [13:0] g_io_resp_bits_resp_entry_5_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_5_vmid;
  wire g_io_resp_bits_resp_entry_5_n;
  wire i_io_resp_bits_resp_entry_5_n;
  wire [1:0] g_io_resp_bits_resp_entry_5_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_5_pbmt;
  wire g_io_resp_bits_resp_entry_5_perm_d;
  wire i_io_resp_bits_resp_entry_5_perm_d;
  wire g_io_resp_bits_resp_entry_5_perm_a;
  wire i_io_resp_bits_resp_entry_5_perm_a;
  wire g_io_resp_bits_resp_entry_5_perm_g;
  wire i_io_resp_bits_resp_entry_5_perm_g;
  wire g_io_resp_bits_resp_entry_5_perm_u;
  wire i_io_resp_bits_resp_entry_5_perm_u;
  wire g_io_resp_bits_resp_entry_5_perm_x;
  wire i_io_resp_bits_resp_entry_5_perm_x;
  wire g_io_resp_bits_resp_entry_5_perm_w;
  wire i_io_resp_bits_resp_entry_5_perm_w;
  wire g_io_resp_bits_resp_entry_5_perm_r;
  wire i_io_resp_bits_resp_entry_5_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_5_level;
  wire [1:0] i_io_resp_bits_resp_entry_5_level;
  wire g_io_resp_bits_resp_entry_5_v;
  wire i_io_resp_bits_resp_entry_5_v;
  wire [40:0] g_io_resp_bits_resp_entry_5_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_5_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_5_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_5_ppn_low;
  wire g_io_resp_bits_resp_entry_5_af;
  wire i_io_resp_bits_resp_entry_5_af;
  wire g_io_resp_bits_resp_entry_5_pf;
  wire i_io_resp_bits_resp_entry_5_pf;
  wire [34:0] g_io_resp_bits_resp_entry_6_tag;
  wire [34:0] i_io_resp_bits_resp_entry_6_tag;
  wire [15:0] g_io_resp_bits_resp_entry_6_asid;
  wire [15:0] i_io_resp_bits_resp_entry_6_asid;
  wire [13:0] g_io_resp_bits_resp_entry_6_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_6_vmid;
  wire g_io_resp_bits_resp_entry_6_n;
  wire i_io_resp_bits_resp_entry_6_n;
  wire [1:0] g_io_resp_bits_resp_entry_6_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_6_pbmt;
  wire g_io_resp_bits_resp_entry_6_perm_d;
  wire i_io_resp_bits_resp_entry_6_perm_d;
  wire g_io_resp_bits_resp_entry_6_perm_a;
  wire i_io_resp_bits_resp_entry_6_perm_a;
  wire g_io_resp_bits_resp_entry_6_perm_g;
  wire i_io_resp_bits_resp_entry_6_perm_g;
  wire g_io_resp_bits_resp_entry_6_perm_u;
  wire i_io_resp_bits_resp_entry_6_perm_u;
  wire g_io_resp_bits_resp_entry_6_perm_x;
  wire i_io_resp_bits_resp_entry_6_perm_x;
  wire g_io_resp_bits_resp_entry_6_perm_w;
  wire i_io_resp_bits_resp_entry_6_perm_w;
  wire g_io_resp_bits_resp_entry_6_perm_r;
  wire i_io_resp_bits_resp_entry_6_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_6_level;
  wire [1:0] i_io_resp_bits_resp_entry_6_level;
  wire g_io_resp_bits_resp_entry_6_v;
  wire i_io_resp_bits_resp_entry_6_v;
  wire [40:0] g_io_resp_bits_resp_entry_6_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_6_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_6_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_6_ppn_low;
  wire g_io_resp_bits_resp_entry_6_af;
  wire i_io_resp_bits_resp_entry_6_af;
  wire g_io_resp_bits_resp_entry_6_pf;
  wire i_io_resp_bits_resp_entry_6_pf;
  wire [34:0] g_io_resp_bits_resp_entry_7_tag;
  wire [34:0] i_io_resp_bits_resp_entry_7_tag;
  wire [15:0] g_io_resp_bits_resp_entry_7_asid;
  wire [15:0] i_io_resp_bits_resp_entry_7_asid;
  wire [13:0] g_io_resp_bits_resp_entry_7_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_7_vmid;
  wire g_io_resp_bits_resp_entry_7_n;
  wire i_io_resp_bits_resp_entry_7_n;
  wire [1:0] g_io_resp_bits_resp_entry_7_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_7_pbmt;
  wire g_io_resp_bits_resp_entry_7_perm_d;
  wire i_io_resp_bits_resp_entry_7_perm_d;
  wire g_io_resp_bits_resp_entry_7_perm_a;
  wire i_io_resp_bits_resp_entry_7_perm_a;
  wire g_io_resp_bits_resp_entry_7_perm_g;
  wire i_io_resp_bits_resp_entry_7_perm_g;
  wire g_io_resp_bits_resp_entry_7_perm_u;
  wire i_io_resp_bits_resp_entry_7_perm_u;
  wire g_io_resp_bits_resp_entry_7_perm_x;
  wire i_io_resp_bits_resp_entry_7_perm_x;
  wire g_io_resp_bits_resp_entry_7_perm_w;
  wire i_io_resp_bits_resp_entry_7_perm_w;
  wire g_io_resp_bits_resp_entry_7_perm_r;
  wire i_io_resp_bits_resp_entry_7_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_7_level;
  wire [1:0] i_io_resp_bits_resp_entry_7_level;
  wire g_io_resp_bits_resp_entry_7_v;
  wire i_io_resp_bits_resp_entry_7_v;
  wire [40:0] g_io_resp_bits_resp_entry_7_ppn;
  wire [40:0] i_io_resp_bits_resp_entry_7_ppn;
  wire [2:0] g_io_resp_bits_resp_entry_7_ppn_low;
  wire [2:0] i_io_resp_bits_resp_entry_7_ppn_low;
  wire g_io_resp_bits_resp_entry_7_af;
  wire i_io_resp_bits_resp_entry_7_af;
  wire g_io_resp_bits_resp_entry_7_pf;
  wire i_io_resp_bits_resp_entry_7_pf;
  wire g_io_resp_bits_resp_pteidx_0;
  wire i_io_resp_bits_resp_pteidx_0;
  wire g_io_resp_bits_resp_pteidx_1;
  wire i_io_resp_bits_resp_pteidx_1;
  wire g_io_resp_bits_resp_pteidx_2;
  wire i_io_resp_bits_resp_pteidx_2;
  wire g_io_resp_bits_resp_pteidx_3;
  wire i_io_resp_bits_resp_pteidx_3;
  wire g_io_resp_bits_resp_pteidx_4;
  wire i_io_resp_bits_resp_pteidx_4;
  wire g_io_resp_bits_resp_pteidx_5;
  wire i_io_resp_bits_resp_pteidx_5;
  wire g_io_resp_bits_resp_pteidx_6;
  wire i_io_resp_bits_resp_pteidx_6;
  wire g_io_resp_bits_resp_pteidx_7;
  wire i_io_resp_bits_resp_pteidx_7;
  wire g_io_resp_bits_resp_not_super;
  wire i_io_resp_bits_resp_not_super;
  wire [37:0] g_io_resp_bits_h_resp_entry_tag;
  wire [37:0] i_io_resp_bits_h_resp_entry_tag;
  wire [13:0] g_io_resp_bits_h_resp_entry_vmid;
  wire [13:0] i_io_resp_bits_h_resp_entry_vmid;
  wire g_io_resp_bits_h_resp_entry_n;
  wire i_io_resp_bits_h_resp_entry_n;
  wire [1:0] g_io_resp_bits_h_resp_entry_pbmt;
  wire [1:0] i_io_resp_bits_h_resp_entry_pbmt;
  wire [37:0] g_io_resp_bits_h_resp_entry_ppn;
  wire [37:0] i_io_resp_bits_h_resp_entry_ppn;
  wire g_io_resp_bits_h_resp_entry_perm_d;
  wire i_io_resp_bits_h_resp_entry_perm_d;
  wire g_io_resp_bits_h_resp_entry_perm_a;
  wire i_io_resp_bits_h_resp_entry_perm_a;
  wire g_io_resp_bits_h_resp_entry_perm_g;
  wire i_io_resp_bits_h_resp_entry_perm_g;
  wire g_io_resp_bits_h_resp_entry_perm_u;
  wire i_io_resp_bits_h_resp_entry_perm_u;
  wire g_io_resp_bits_h_resp_entry_perm_x;
  wire i_io_resp_bits_h_resp_entry_perm_x;
  wire g_io_resp_bits_h_resp_entry_perm_w;
  wire i_io_resp_bits_h_resp_entry_perm_w;
  wire g_io_resp_bits_h_resp_entry_perm_r;
  wire i_io_resp_bits_h_resp_entry_perm_r;
  wire [1:0] g_io_resp_bits_h_resp_entry_level;
  wire [1:0] i_io_resp_bits_h_resp_entry_level;
  wire g_io_resp_bits_h_resp_gpf;
  wire i_io_resp_bits_h_resp_gpf;
  wire g_io_resp_bits_h_resp_gaf;
  wire i_io_resp_bits_h_resp_gaf;
  wire g_io_llptw_valid;
  wire i_io_llptw_valid;
  wire [37:0] g_io_llptw_bits_req_info_vpn;
  wire [37:0] i_io_llptw_bits_req_info_vpn;
  wire [1:0] g_io_llptw_bits_req_info_s2xlate;
  wire [1:0] i_io_llptw_bits_req_info_s2xlate;
  wire [1:0] g_io_llptw_bits_req_info_source;
  wire [1:0] i_io_llptw_bits_req_info_source;
  wire g_io_hptw_req_valid;
  wire i_io_hptw_req_valid;
  wire [1:0] g_io_hptw_req_bits_source;
  wire [1:0] i_io_hptw_req_bits_source;
  wire [43:0] g_io_hptw_req_bits_gvpn;
  wire [43:0] i_io_hptw_req_bits_gvpn;
  wire g_io_mem_req_valid;
  wire i_io_mem_req_valid;
  wire [47:0] g_io_mem_req_bits_addr;
  wire [47:0] i_io_mem_req_bits_addr;
  wire [47:0] g_io_pmp_req_bits_addr;
  wire [47:0] i_io_pmp_req_bits_addr;
  wire [37:0] g_io_refill_req_info_vpn;
  wire [37:0] i_io_refill_req_info_vpn;
  wire [1:0] g_io_refill_req_info_s2xlate;
  wire [1:0] i_io_refill_req_info_s2xlate;
  wire [1:0] g_io_refill_req_info_source;
  wire [1:0] i_io_refill_req_info_source;
  wire [1:0] g_io_refill_level;
  wire [1:0] i_io_refill_level;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  integer cycle;
  integer errors;
  integer checks;
  integer probe_errors;

  PTW u_g (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_mode(io_csr_satp_mode),
    .io_csr_satp_asid(io_csr_satp_asid),
    .io_csr_satp_ppn(io_csr_satp_ppn),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_mode(io_csr_vsatp_mode),
    .io_csr_vsatp_asid(io_csr_vsatp_asid),
    .io_csr_vsatp_ppn(io_csr_vsatp_ppn),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_mxr(io_csr_priv_mxr),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_csr_hPBMTE(io_csr_hPBMTE),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_req_info_vpn(io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate(io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source(io_req_bits_req_info_source),
    .io_req_bits_l3Hit(io_req_bits_l3Hit),
    .io_req_bits_l2Hit(io_req_bits_l2Hit),
    .io_req_bits_ppn(io_req_bits_ppn),
    .io_req_bits_stage1Hit(io_req_bits_stage1Hit),
    .io_req_bits_stage1_entry_0_tag(io_req_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid(io_req_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid(io_req_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n(io_req_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt(io_req_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d(io_req_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a(io_req_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g(io_req_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u(io_req_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x(io_req_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w(io_req_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r(io_req_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level(io_req_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v(io_req_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn(io_req_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low(io_req_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf(io_req_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_1_tag(io_req_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid(io_req_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid(io_req_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n(io_req_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt(io_req_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d(io_req_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a(io_req_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g(io_req_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u(io_req_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x(io_req_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w(io_req_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r(io_req_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level(io_req_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v(io_req_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn(io_req_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low(io_req_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf(io_req_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_2_tag(io_req_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid(io_req_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid(io_req_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n(io_req_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt(io_req_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d(io_req_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a(io_req_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g(io_req_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u(io_req_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x(io_req_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w(io_req_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r(io_req_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level(io_req_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v(io_req_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn(io_req_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low(io_req_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf(io_req_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_3_tag(io_req_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid(io_req_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid(io_req_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n(io_req_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt(io_req_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d(io_req_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a(io_req_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g(io_req_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u(io_req_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x(io_req_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w(io_req_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r(io_req_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level(io_req_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v(io_req_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn(io_req_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low(io_req_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf(io_req_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_4_tag(io_req_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid(io_req_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid(io_req_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n(io_req_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt(io_req_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d(io_req_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a(io_req_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g(io_req_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u(io_req_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x(io_req_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w(io_req_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r(io_req_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level(io_req_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v(io_req_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn(io_req_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low(io_req_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf(io_req_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_5_tag(io_req_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid(io_req_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid(io_req_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n(io_req_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt(io_req_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d(io_req_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a(io_req_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g(io_req_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u(io_req_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x(io_req_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w(io_req_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r(io_req_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level(io_req_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v(io_req_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn(io_req_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low(io_req_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf(io_req_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_6_tag(io_req_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid(io_req_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid(io_req_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n(io_req_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt(io_req_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d(io_req_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a(io_req_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g(io_req_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u(io_req_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x(io_req_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w(io_req_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r(io_req_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level(io_req_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v(io_req_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn(io_req_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low(io_req_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf(io_req_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_7_tag(io_req_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid(io_req_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid(io_req_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n(io_req_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt(io_req_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d(io_req_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a(io_req_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g(io_req_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u(io_req_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x(io_req_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w(io_req_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r(io_req_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level(io_req_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v(io_req_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn(io_req_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low(io_req_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf(io_req_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_pteidx_0(io_req_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1(io_req_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2(io_req_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3(io_req_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4(io_req_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5(io_req_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6(io_req_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7(io_req_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super(io_req_bits_stage1_not_super),
    .io_resp_ready(io_resp_ready),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_source(g_io_resp_bits_source),
    .io_resp_bits_s2xlate(g_io_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag(g_io_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid(g_io_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid(g_io_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n(g_io_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt(g_io_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d(g_io_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a(g_io_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g(g_io_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u(g_io_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x(g_io_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w(g_io_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r(g_io_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level(g_io_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v(g_io_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn(g_io_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low(g_io_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af(g_io_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf(g_io_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_1_tag(g_io_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid(g_io_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid(g_io_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n(g_io_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt(g_io_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d(g_io_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a(g_io_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g(g_io_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u(g_io_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x(g_io_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w(g_io_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r(g_io_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level(g_io_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v(g_io_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn(g_io_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low(g_io_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af(g_io_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf(g_io_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_2_tag(g_io_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid(g_io_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid(g_io_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n(g_io_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt(g_io_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d(g_io_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a(g_io_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g(g_io_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u(g_io_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x(g_io_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w(g_io_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r(g_io_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level(g_io_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v(g_io_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn(g_io_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low(g_io_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af(g_io_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf(g_io_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_3_tag(g_io_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid(g_io_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid(g_io_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n(g_io_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt(g_io_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d(g_io_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a(g_io_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g(g_io_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u(g_io_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x(g_io_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w(g_io_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r(g_io_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level(g_io_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v(g_io_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn(g_io_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low(g_io_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af(g_io_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf(g_io_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_4_tag(g_io_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid(g_io_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid(g_io_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n(g_io_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt(g_io_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d(g_io_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a(g_io_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g(g_io_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u(g_io_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x(g_io_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w(g_io_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r(g_io_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level(g_io_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v(g_io_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn(g_io_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low(g_io_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af(g_io_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf(g_io_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_5_tag(g_io_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid(g_io_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid(g_io_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n(g_io_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt(g_io_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d(g_io_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a(g_io_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g(g_io_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u(g_io_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x(g_io_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w(g_io_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r(g_io_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level(g_io_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v(g_io_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn(g_io_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low(g_io_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af(g_io_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf(g_io_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_6_tag(g_io_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid(g_io_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid(g_io_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n(g_io_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt(g_io_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d(g_io_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a(g_io_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g(g_io_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u(g_io_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x(g_io_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w(g_io_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r(g_io_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level(g_io_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v(g_io_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn(g_io_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low(g_io_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af(g_io_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf(g_io_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_7_tag(g_io_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid(g_io_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid(g_io_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n(g_io_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt(g_io_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d(g_io_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a(g_io_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g(g_io_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u(g_io_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x(g_io_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w(g_io_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r(g_io_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level(g_io_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v(g_io_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn(g_io_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low(g_io_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af(g_io_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf(g_io_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_pteidx_0(g_io_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1(g_io_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2(g_io_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3(g_io_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4(g_io_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5(g_io_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6(g_io_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7(g_io_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super(g_io_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag(g_io_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid(g_io_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n(g_io_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt(g_io_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn(g_io_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d(g_io_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a(g_io_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g(g_io_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u(g_io_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x(g_io_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w(g_io_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r(g_io_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level(g_io_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf(g_io_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf(g_io_resp_bits_h_resp_gaf),
    .io_llptw_ready(io_llptw_ready),
    .io_llptw_valid(g_io_llptw_valid),
    .io_llptw_bits_req_info_vpn(g_io_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate(g_io_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source(g_io_llptw_bits_req_info_source),
    .io_hptw_req_ready(io_hptw_req_ready),
    .io_hptw_req_valid(g_io_hptw_req_valid),
    .io_hptw_req_bits_source(g_io_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn(g_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid(io_hptw_resp_valid),
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
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(g_io_mem_req_valid),
    .io_mem_req_bits_addr(g_io_mem_req_bits_addr),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits(io_mem_resp_bits),
    .io_mem_mask(io_mem_mask),
    .io_pmp_req_bits_addr(g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_refill_req_info_vpn(g_io_refill_req_info_vpn),
    .io_refill_req_info_s2xlate(g_io_refill_req_info_s2xlate),
    .io_refill_req_info_source(g_io_refill_req_info_source),
    .io_refill_level(g_io_refill_level),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value)
  );
  PTW_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_mode(io_csr_satp_mode),
    .io_csr_satp_asid(io_csr_satp_asid),
    .io_csr_satp_ppn(io_csr_satp_ppn),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_mode(io_csr_vsatp_mode),
    .io_csr_vsatp_asid(io_csr_vsatp_asid),
    .io_csr_vsatp_ppn(io_csr_vsatp_ppn),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_mxr(io_csr_priv_mxr),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_csr_hPBMTE(io_csr_hPBMTE),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_req_info_vpn(io_req_bits_req_info_vpn),
    .io_req_bits_req_info_s2xlate(io_req_bits_req_info_s2xlate),
    .io_req_bits_req_info_source(io_req_bits_req_info_source),
    .io_req_bits_l3Hit(io_req_bits_l3Hit),
    .io_req_bits_l2Hit(io_req_bits_l2Hit),
    .io_req_bits_ppn(io_req_bits_ppn),
    .io_req_bits_stage1Hit(io_req_bits_stage1Hit),
    .io_req_bits_stage1_entry_0_tag(io_req_bits_stage1_entry_0_tag),
    .io_req_bits_stage1_entry_0_asid(io_req_bits_stage1_entry_0_asid),
    .io_req_bits_stage1_entry_0_vmid(io_req_bits_stage1_entry_0_vmid),
    .io_req_bits_stage1_entry_0_n(io_req_bits_stage1_entry_0_n),
    .io_req_bits_stage1_entry_0_pbmt(io_req_bits_stage1_entry_0_pbmt),
    .io_req_bits_stage1_entry_0_perm_d(io_req_bits_stage1_entry_0_perm_d),
    .io_req_bits_stage1_entry_0_perm_a(io_req_bits_stage1_entry_0_perm_a),
    .io_req_bits_stage1_entry_0_perm_g(io_req_bits_stage1_entry_0_perm_g),
    .io_req_bits_stage1_entry_0_perm_u(io_req_bits_stage1_entry_0_perm_u),
    .io_req_bits_stage1_entry_0_perm_x(io_req_bits_stage1_entry_0_perm_x),
    .io_req_bits_stage1_entry_0_perm_w(io_req_bits_stage1_entry_0_perm_w),
    .io_req_bits_stage1_entry_0_perm_r(io_req_bits_stage1_entry_0_perm_r),
    .io_req_bits_stage1_entry_0_level(io_req_bits_stage1_entry_0_level),
    .io_req_bits_stage1_entry_0_v(io_req_bits_stage1_entry_0_v),
    .io_req_bits_stage1_entry_0_ppn(io_req_bits_stage1_entry_0_ppn),
    .io_req_bits_stage1_entry_0_ppn_low(io_req_bits_stage1_entry_0_ppn_low),
    .io_req_bits_stage1_entry_0_pf(io_req_bits_stage1_entry_0_pf),
    .io_req_bits_stage1_entry_1_tag(io_req_bits_stage1_entry_1_tag),
    .io_req_bits_stage1_entry_1_asid(io_req_bits_stage1_entry_1_asid),
    .io_req_bits_stage1_entry_1_vmid(io_req_bits_stage1_entry_1_vmid),
    .io_req_bits_stage1_entry_1_n(io_req_bits_stage1_entry_1_n),
    .io_req_bits_stage1_entry_1_pbmt(io_req_bits_stage1_entry_1_pbmt),
    .io_req_bits_stage1_entry_1_perm_d(io_req_bits_stage1_entry_1_perm_d),
    .io_req_bits_stage1_entry_1_perm_a(io_req_bits_stage1_entry_1_perm_a),
    .io_req_bits_stage1_entry_1_perm_g(io_req_bits_stage1_entry_1_perm_g),
    .io_req_bits_stage1_entry_1_perm_u(io_req_bits_stage1_entry_1_perm_u),
    .io_req_bits_stage1_entry_1_perm_x(io_req_bits_stage1_entry_1_perm_x),
    .io_req_bits_stage1_entry_1_perm_w(io_req_bits_stage1_entry_1_perm_w),
    .io_req_bits_stage1_entry_1_perm_r(io_req_bits_stage1_entry_1_perm_r),
    .io_req_bits_stage1_entry_1_level(io_req_bits_stage1_entry_1_level),
    .io_req_bits_stage1_entry_1_v(io_req_bits_stage1_entry_1_v),
    .io_req_bits_stage1_entry_1_ppn(io_req_bits_stage1_entry_1_ppn),
    .io_req_bits_stage1_entry_1_ppn_low(io_req_bits_stage1_entry_1_ppn_low),
    .io_req_bits_stage1_entry_1_pf(io_req_bits_stage1_entry_1_pf),
    .io_req_bits_stage1_entry_2_tag(io_req_bits_stage1_entry_2_tag),
    .io_req_bits_stage1_entry_2_asid(io_req_bits_stage1_entry_2_asid),
    .io_req_bits_stage1_entry_2_vmid(io_req_bits_stage1_entry_2_vmid),
    .io_req_bits_stage1_entry_2_n(io_req_bits_stage1_entry_2_n),
    .io_req_bits_stage1_entry_2_pbmt(io_req_bits_stage1_entry_2_pbmt),
    .io_req_bits_stage1_entry_2_perm_d(io_req_bits_stage1_entry_2_perm_d),
    .io_req_bits_stage1_entry_2_perm_a(io_req_bits_stage1_entry_2_perm_a),
    .io_req_bits_stage1_entry_2_perm_g(io_req_bits_stage1_entry_2_perm_g),
    .io_req_bits_stage1_entry_2_perm_u(io_req_bits_stage1_entry_2_perm_u),
    .io_req_bits_stage1_entry_2_perm_x(io_req_bits_stage1_entry_2_perm_x),
    .io_req_bits_stage1_entry_2_perm_w(io_req_bits_stage1_entry_2_perm_w),
    .io_req_bits_stage1_entry_2_perm_r(io_req_bits_stage1_entry_2_perm_r),
    .io_req_bits_stage1_entry_2_level(io_req_bits_stage1_entry_2_level),
    .io_req_bits_stage1_entry_2_v(io_req_bits_stage1_entry_2_v),
    .io_req_bits_stage1_entry_2_ppn(io_req_bits_stage1_entry_2_ppn),
    .io_req_bits_stage1_entry_2_ppn_low(io_req_bits_stage1_entry_2_ppn_low),
    .io_req_bits_stage1_entry_2_pf(io_req_bits_stage1_entry_2_pf),
    .io_req_bits_stage1_entry_3_tag(io_req_bits_stage1_entry_3_tag),
    .io_req_bits_stage1_entry_3_asid(io_req_bits_stage1_entry_3_asid),
    .io_req_bits_stage1_entry_3_vmid(io_req_bits_stage1_entry_3_vmid),
    .io_req_bits_stage1_entry_3_n(io_req_bits_stage1_entry_3_n),
    .io_req_bits_stage1_entry_3_pbmt(io_req_bits_stage1_entry_3_pbmt),
    .io_req_bits_stage1_entry_3_perm_d(io_req_bits_stage1_entry_3_perm_d),
    .io_req_bits_stage1_entry_3_perm_a(io_req_bits_stage1_entry_3_perm_a),
    .io_req_bits_stage1_entry_3_perm_g(io_req_bits_stage1_entry_3_perm_g),
    .io_req_bits_stage1_entry_3_perm_u(io_req_bits_stage1_entry_3_perm_u),
    .io_req_bits_stage1_entry_3_perm_x(io_req_bits_stage1_entry_3_perm_x),
    .io_req_bits_stage1_entry_3_perm_w(io_req_bits_stage1_entry_3_perm_w),
    .io_req_bits_stage1_entry_3_perm_r(io_req_bits_stage1_entry_3_perm_r),
    .io_req_bits_stage1_entry_3_level(io_req_bits_stage1_entry_3_level),
    .io_req_bits_stage1_entry_3_v(io_req_bits_stage1_entry_3_v),
    .io_req_bits_stage1_entry_3_ppn(io_req_bits_stage1_entry_3_ppn),
    .io_req_bits_stage1_entry_3_ppn_low(io_req_bits_stage1_entry_3_ppn_low),
    .io_req_bits_stage1_entry_3_pf(io_req_bits_stage1_entry_3_pf),
    .io_req_bits_stage1_entry_4_tag(io_req_bits_stage1_entry_4_tag),
    .io_req_bits_stage1_entry_4_asid(io_req_bits_stage1_entry_4_asid),
    .io_req_bits_stage1_entry_4_vmid(io_req_bits_stage1_entry_4_vmid),
    .io_req_bits_stage1_entry_4_n(io_req_bits_stage1_entry_4_n),
    .io_req_bits_stage1_entry_4_pbmt(io_req_bits_stage1_entry_4_pbmt),
    .io_req_bits_stage1_entry_4_perm_d(io_req_bits_stage1_entry_4_perm_d),
    .io_req_bits_stage1_entry_4_perm_a(io_req_bits_stage1_entry_4_perm_a),
    .io_req_bits_stage1_entry_4_perm_g(io_req_bits_stage1_entry_4_perm_g),
    .io_req_bits_stage1_entry_4_perm_u(io_req_bits_stage1_entry_4_perm_u),
    .io_req_bits_stage1_entry_4_perm_x(io_req_bits_stage1_entry_4_perm_x),
    .io_req_bits_stage1_entry_4_perm_w(io_req_bits_stage1_entry_4_perm_w),
    .io_req_bits_stage1_entry_4_perm_r(io_req_bits_stage1_entry_4_perm_r),
    .io_req_bits_stage1_entry_4_level(io_req_bits_stage1_entry_4_level),
    .io_req_bits_stage1_entry_4_v(io_req_bits_stage1_entry_4_v),
    .io_req_bits_stage1_entry_4_ppn(io_req_bits_stage1_entry_4_ppn),
    .io_req_bits_stage1_entry_4_ppn_low(io_req_bits_stage1_entry_4_ppn_low),
    .io_req_bits_stage1_entry_4_pf(io_req_bits_stage1_entry_4_pf),
    .io_req_bits_stage1_entry_5_tag(io_req_bits_stage1_entry_5_tag),
    .io_req_bits_stage1_entry_5_asid(io_req_bits_stage1_entry_5_asid),
    .io_req_bits_stage1_entry_5_vmid(io_req_bits_stage1_entry_5_vmid),
    .io_req_bits_stage1_entry_5_n(io_req_bits_stage1_entry_5_n),
    .io_req_bits_stage1_entry_5_pbmt(io_req_bits_stage1_entry_5_pbmt),
    .io_req_bits_stage1_entry_5_perm_d(io_req_bits_stage1_entry_5_perm_d),
    .io_req_bits_stage1_entry_5_perm_a(io_req_bits_stage1_entry_5_perm_a),
    .io_req_bits_stage1_entry_5_perm_g(io_req_bits_stage1_entry_5_perm_g),
    .io_req_bits_stage1_entry_5_perm_u(io_req_bits_stage1_entry_5_perm_u),
    .io_req_bits_stage1_entry_5_perm_x(io_req_bits_stage1_entry_5_perm_x),
    .io_req_bits_stage1_entry_5_perm_w(io_req_bits_stage1_entry_5_perm_w),
    .io_req_bits_stage1_entry_5_perm_r(io_req_bits_stage1_entry_5_perm_r),
    .io_req_bits_stage1_entry_5_level(io_req_bits_stage1_entry_5_level),
    .io_req_bits_stage1_entry_5_v(io_req_bits_stage1_entry_5_v),
    .io_req_bits_stage1_entry_5_ppn(io_req_bits_stage1_entry_5_ppn),
    .io_req_bits_stage1_entry_5_ppn_low(io_req_bits_stage1_entry_5_ppn_low),
    .io_req_bits_stage1_entry_5_pf(io_req_bits_stage1_entry_5_pf),
    .io_req_bits_stage1_entry_6_tag(io_req_bits_stage1_entry_6_tag),
    .io_req_bits_stage1_entry_6_asid(io_req_bits_stage1_entry_6_asid),
    .io_req_bits_stage1_entry_6_vmid(io_req_bits_stage1_entry_6_vmid),
    .io_req_bits_stage1_entry_6_n(io_req_bits_stage1_entry_6_n),
    .io_req_bits_stage1_entry_6_pbmt(io_req_bits_stage1_entry_6_pbmt),
    .io_req_bits_stage1_entry_6_perm_d(io_req_bits_stage1_entry_6_perm_d),
    .io_req_bits_stage1_entry_6_perm_a(io_req_bits_stage1_entry_6_perm_a),
    .io_req_bits_stage1_entry_6_perm_g(io_req_bits_stage1_entry_6_perm_g),
    .io_req_bits_stage1_entry_6_perm_u(io_req_bits_stage1_entry_6_perm_u),
    .io_req_bits_stage1_entry_6_perm_x(io_req_bits_stage1_entry_6_perm_x),
    .io_req_bits_stage1_entry_6_perm_w(io_req_bits_stage1_entry_6_perm_w),
    .io_req_bits_stage1_entry_6_perm_r(io_req_bits_stage1_entry_6_perm_r),
    .io_req_bits_stage1_entry_6_level(io_req_bits_stage1_entry_6_level),
    .io_req_bits_stage1_entry_6_v(io_req_bits_stage1_entry_6_v),
    .io_req_bits_stage1_entry_6_ppn(io_req_bits_stage1_entry_6_ppn),
    .io_req_bits_stage1_entry_6_ppn_low(io_req_bits_stage1_entry_6_ppn_low),
    .io_req_bits_stage1_entry_6_pf(io_req_bits_stage1_entry_6_pf),
    .io_req_bits_stage1_entry_7_tag(io_req_bits_stage1_entry_7_tag),
    .io_req_bits_stage1_entry_7_asid(io_req_bits_stage1_entry_7_asid),
    .io_req_bits_stage1_entry_7_vmid(io_req_bits_stage1_entry_7_vmid),
    .io_req_bits_stage1_entry_7_n(io_req_bits_stage1_entry_7_n),
    .io_req_bits_stage1_entry_7_pbmt(io_req_bits_stage1_entry_7_pbmt),
    .io_req_bits_stage1_entry_7_perm_d(io_req_bits_stage1_entry_7_perm_d),
    .io_req_bits_stage1_entry_7_perm_a(io_req_bits_stage1_entry_7_perm_a),
    .io_req_bits_stage1_entry_7_perm_g(io_req_bits_stage1_entry_7_perm_g),
    .io_req_bits_stage1_entry_7_perm_u(io_req_bits_stage1_entry_7_perm_u),
    .io_req_bits_stage1_entry_7_perm_x(io_req_bits_stage1_entry_7_perm_x),
    .io_req_bits_stage1_entry_7_perm_w(io_req_bits_stage1_entry_7_perm_w),
    .io_req_bits_stage1_entry_7_perm_r(io_req_bits_stage1_entry_7_perm_r),
    .io_req_bits_stage1_entry_7_level(io_req_bits_stage1_entry_7_level),
    .io_req_bits_stage1_entry_7_v(io_req_bits_stage1_entry_7_v),
    .io_req_bits_stage1_entry_7_ppn(io_req_bits_stage1_entry_7_ppn),
    .io_req_bits_stage1_entry_7_ppn_low(io_req_bits_stage1_entry_7_ppn_low),
    .io_req_bits_stage1_entry_7_pf(io_req_bits_stage1_entry_7_pf),
    .io_req_bits_stage1_pteidx_0(io_req_bits_stage1_pteidx_0),
    .io_req_bits_stage1_pteidx_1(io_req_bits_stage1_pteidx_1),
    .io_req_bits_stage1_pteidx_2(io_req_bits_stage1_pteidx_2),
    .io_req_bits_stage1_pteidx_3(io_req_bits_stage1_pteidx_3),
    .io_req_bits_stage1_pteidx_4(io_req_bits_stage1_pteidx_4),
    .io_req_bits_stage1_pteidx_5(io_req_bits_stage1_pteidx_5),
    .io_req_bits_stage1_pteidx_6(io_req_bits_stage1_pteidx_6),
    .io_req_bits_stage1_pteidx_7(io_req_bits_stage1_pteidx_7),
    .io_req_bits_stage1_not_super(io_req_bits_stage1_not_super),
    .io_resp_ready(io_resp_ready),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_source(i_io_resp_bits_source),
    .io_resp_bits_s2xlate(i_io_resp_bits_s2xlate),
    .io_resp_bits_resp_entry_0_tag(i_io_resp_bits_resp_entry_0_tag),
    .io_resp_bits_resp_entry_0_asid(i_io_resp_bits_resp_entry_0_asid),
    .io_resp_bits_resp_entry_0_vmid(i_io_resp_bits_resp_entry_0_vmid),
    .io_resp_bits_resp_entry_0_n(i_io_resp_bits_resp_entry_0_n),
    .io_resp_bits_resp_entry_0_pbmt(i_io_resp_bits_resp_entry_0_pbmt),
    .io_resp_bits_resp_entry_0_perm_d(i_io_resp_bits_resp_entry_0_perm_d),
    .io_resp_bits_resp_entry_0_perm_a(i_io_resp_bits_resp_entry_0_perm_a),
    .io_resp_bits_resp_entry_0_perm_g(i_io_resp_bits_resp_entry_0_perm_g),
    .io_resp_bits_resp_entry_0_perm_u(i_io_resp_bits_resp_entry_0_perm_u),
    .io_resp_bits_resp_entry_0_perm_x(i_io_resp_bits_resp_entry_0_perm_x),
    .io_resp_bits_resp_entry_0_perm_w(i_io_resp_bits_resp_entry_0_perm_w),
    .io_resp_bits_resp_entry_0_perm_r(i_io_resp_bits_resp_entry_0_perm_r),
    .io_resp_bits_resp_entry_0_level(i_io_resp_bits_resp_entry_0_level),
    .io_resp_bits_resp_entry_0_v(i_io_resp_bits_resp_entry_0_v),
    .io_resp_bits_resp_entry_0_ppn(i_io_resp_bits_resp_entry_0_ppn),
    .io_resp_bits_resp_entry_0_ppn_low(i_io_resp_bits_resp_entry_0_ppn_low),
    .io_resp_bits_resp_entry_0_af(i_io_resp_bits_resp_entry_0_af),
    .io_resp_bits_resp_entry_0_pf(i_io_resp_bits_resp_entry_0_pf),
    .io_resp_bits_resp_entry_1_tag(i_io_resp_bits_resp_entry_1_tag),
    .io_resp_bits_resp_entry_1_asid(i_io_resp_bits_resp_entry_1_asid),
    .io_resp_bits_resp_entry_1_vmid(i_io_resp_bits_resp_entry_1_vmid),
    .io_resp_bits_resp_entry_1_n(i_io_resp_bits_resp_entry_1_n),
    .io_resp_bits_resp_entry_1_pbmt(i_io_resp_bits_resp_entry_1_pbmt),
    .io_resp_bits_resp_entry_1_perm_d(i_io_resp_bits_resp_entry_1_perm_d),
    .io_resp_bits_resp_entry_1_perm_a(i_io_resp_bits_resp_entry_1_perm_a),
    .io_resp_bits_resp_entry_1_perm_g(i_io_resp_bits_resp_entry_1_perm_g),
    .io_resp_bits_resp_entry_1_perm_u(i_io_resp_bits_resp_entry_1_perm_u),
    .io_resp_bits_resp_entry_1_perm_x(i_io_resp_bits_resp_entry_1_perm_x),
    .io_resp_bits_resp_entry_1_perm_w(i_io_resp_bits_resp_entry_1_perm_w),
    .io_resp_bits_resp_entry_1_perm_r(i_io_resp_bits_resp_entry_1_perm_r),
    .io_resp_bits_resp_entry_1_level(i_io_resp_bits_resp_entry_1_level),
    .io_resp_bits_resp_entry_1_v(i_io_resp_bits_resp_entry_1_v),
    .io_resp_bits_resp_entry_1_ppn(i_io_resp_bits_resp_entry_1_ppn),
    .io_resp_bits_resp_entry_1_ppn_low(i_io_resp_bits_resp_entry_1_ppn_low),
    .io_resp_bits_resp_entry_1_af(i_io_resp_bits_resp_entry_1_af),
    .io_resp_bits_resp_entry_1_pf(i_io_resp_bits_resp_entry_1_pf),
    .io_resp_bits_resp_entry_2_tag(i_io_resp_bits_resp_entry_2_tag),
    .io_resp_bits_resp_entry_2_asid(i_io_resp_bits_resp_entry_2_asid),
    .io_resp_bits_resp_entry_2_vmid(i_io_resp_bits_resp_entry_2_vmid),
    .io_resp_bits_resp_entry_2_n(i_io_resp_bits_resp_entry_2_n),
    .io_resp_bits_resp_entry_2_pbmt(i_io_resp_bits_resp_entry_2_pbmt),
    .io_resp_bits_resp_entry_2_perm_d(i_io_resp_bits_resp_entry_2_perm_d),
    .io_resp_bits_resp_entry_2_perm_a(i_io_resp_bits_resp_entry_2_perm_a),
    .io_resp_bits_resp_entry_2_perm_g(i_io_resp_bits_resp_entry_2_perm_g),
    .io_resp_bits_resp_entry_2_perm_u(i_io_resp_bits_resp_entry_2_perm_u),
    .io_resp_bits_resp_entry_2_perm_x(i_io_resp_bits_resp_entry_2_perm_x),
    .io_resp_bits_resp_entry_2_perm_w(i_io_resp_bits_resp_entry_2_perm_w),
    .io_resp_bits_resp_entry_2_perm_r(i_io_resp_bits_resp_entry_2_perm_r),
    .io_resp_bits_resp_entry_2_level(i_io_resp_bits_resp_entry_2_level),
    .io_resp_bits_resp_entry_2_v(i_io_resp_bits_resp_entry_2_v),
    .io_resp_bits_resp_entry_2_ppn(i_io_resp_bits_resp_entry_2_ppn),
    .io_resp_bits_resp_entry_2_ppn_low(i_io_resp_bits_resp_entry_2_ppn_low),
    .io_resp_bits_resp_entry_2_af(i_io_resp_bits_resp_entry_2_af),
    .io_resp_bits_resp_entry_2_pf(i_io_resp_bits_resp_entry_2_pf),
    .io_resp_bits_resp_entry_3_tag(i_io_resp_bits_resp_entry_3_tag),
    .io_resp_bits_resp_entry_3_asid(i_io_resp_bits_resp_entry_3_asid),
    .io_resp_bits_resp_entry_3_vmid(i_io_resp_bits_resp_entry_3_vmid),
    .io_resp_bits_resp_entry_3_n(i_io_resp_bits_resp_entry_3_n),
    .io_resp_bits_resp_entry_3_pbmt(i_io_resp_bits_resp_entry_3_pbmt),
    .io_resp_bits_resp_entry_3_perm_d(i_io_resp_bits_resp_entry_3_perm_d),
    .io_resp_bits_resp_entry_3_perm_a(i_io_resp_bits_resp_entry_3_perm_a),
    .io_resp_bits_resp_entry_3_perm_g(i_io_resp_bits_resp_entry_3_perm_g),
    .io_resp_bits_resp_entry_3_perm_u(i_io_resp_bits_resp_entry_3_perm_u),
    .io_resp_bits_resp_entry_3_perm_x(i_io_resp_bits_resp_entry_3_perm_x),
    .io_resp_bits_resp_entry_3_perm_w(i_io_resp_bits_resp_entry_3_perm_w),
    .io_resp_bits_resp_entry_3_perm_r(i_io_resp_bits_resp_entry_3_perm_r),
    .io_resp_bits_resp_entry_3_level(i_io_resp_bits_resp_entry_3_level),
    .io_resp_bits_resp_entry_3_v(i_io_resp_bits_resp_entry_3_v),
    .io_resp_bits_resp_entry_3_ppn(i_io_resp_bits_resp_entry_3_ppn),
    .io_resp_bits_resp_entry_3_ppn_low(i_io_resp_bits_resp_entry_3_ppn_low),
    .io_resp_bits_resp_entry_3_af(i_io_resp_bits_resp_entry_3_af),
    .io_resp_bits_resp_entry_3_pf(i_io_resp_bits_resp_entry_3_pf),
    .io_resp_bits_resp_entry_4_tag(i_io_resp_bits_resp_entry_4_tag),
    .io_resp_bits_resp_entry_4_asid(i_io_resp_bits_resp_entry_4_asid),
    .io_resp_bits_resp_entry_4_vmid(i_io_resp_bits_resp_entry_4_vmid),
    .io_resp_bits_resp_entry_4_n(i_io_resp_bits_resp_entry_4_n),
    .io_resp_bits_resp_entry_4_pbmt(i_io_resp_bits_resp_entry_4_pbmt),
    .io_resp_bits_resp_entry_4_perm_d(i_io_resp_bits_resp_entry_4_perm_d),
    .io_resp_bits_resp_entry_4_perm_a(i_io_resp_bits_resp_entry_4_perm_a),
    .io_resp_bits_resp_entry_4_perm_g(i_io_resp_bits_resp_entry_4_perm_g),
    .io_resp_bits_resp_entry_4_perm_u(i_io_resp_bits_resp_entry_4_perm_u),
    .io_resp_bits_resp_entry_4_perm_x(i_io_resp_bits_resp_entry_4_perm_x),
    .io_resp_bits_resp_entry_4_perm_w(i_io_resp_bits_resp_entry_4_perm_w),
    .io_resp_bits_resp_entry_4_perm_r(i_io_resp_bits_resp_entry_4_perm_r),
    .io_resp_bits_resp_entry_4_level(i_io_resp_bits_resp_entry_4_level),
    .io_resp_bits_resp_entry_4_v(i_io_resp_bits_resp_entry_4_v),
    .io_resp_bits_resp_entry_4_ppn(i_io_resp_bits_resp_entry_4_ppn),
    .io_resp_bits_resp_entry_4_ppn_low(i_io_resp_bits_resp_entry_4_ppn_low),
    .io_resp_bits_resp_entry_4_af(i_io_resp_bits_resp_entry_4_af),
    .io_resp_bits_resp_entry_4_pf(i_io_resp_bits_resp_entry_4_pf),
    .io_resp_bits_resp_entry_5_tag(i_io_resp_bits_resp_entry_5_tag),
    .io_resp_bits_resp_entry_5_asid(i_io_resp_bits_resp_entry_5_asid),
    .io_resp_bits_resp_entry_5_vmid(i_io_resp_bits_resp_entry_5_vmid),
    .io_resp_bits_resp_entry_5_n(i_io_resp_bits_resp_entry_5_n),
    .io_resp_bits_resp_entry_5_pbmt(i_io_resp_bits_resp_entry_5_pbmt),
    .io_resp_bits_resp_entry_5_perm_d(i_io_resp_bits_resp_entry_5_perm_d),
    .io_resp_bits_resp_entry_5_perm_a(i_io_resp_bits_resp_entry_5_perm_a),
    .io_resp_bits_resp_entry_5_perm_g(i_io_resp_bits_resp_entry_5_perm_g),
    .io_resp_bits_resp_entry_5_perm_u(i_io_resp_bits_resp_entry_5_perm_u),
    .io_resp_bits_resp_entry_5_perm_x(i_io_resp_bits_resp_entry_5_perm_x),
    .io_resp_bits_resp_entry_5_perm_w(i_io_resp_bits_resp_entry_5_perm_w),
    .io_resp_bits_resp_entry_5_perm_r(i_io_resp_bits_resp_entry_5_perm_r),
    .io_resp_bits_resp_entry_5_level(i_io_resp_bits_resp_entry_5_level),
    .io_resp_bits_resp_entry_5_v(i_io_resp_bits_resp_entry_5_v),
    .io_resp_bits_resp_entry_5_ppn(i_io_resp_bits_resp_entry_5_ppn),
    .io_resp_bits_resp_entry_5_ppn_low(i_io_resp_bits_resp_entry_5_ppn_low),
    .io_resp_bits_resp_entry_5_af(i_io_resp_bits_resp_entry_5_af),
    .io_resp_bits_resp_entry_5_pf(i_io_resp_bits_resp_entry_5_pf),
    .io_resp_bits_resp_entry_6_tag(i_io_resp_bits_resp_entry_6_tag),
    .io_resp_bits_resp_entry_6_asid(i_io_resp_bits_resp_entry_6_asid),
    .io_resp_bits_resp_entry_6_vmid(i_io_resp_bits_resp_entry_6_vmid),
    .io_resp_bits_resp_entry_6_n(i_io_resp_bits_resp_entry_6_n),
    .io_resp_bits_resp_entry_6_pbmt(i_io_resp_bits_resp_entry_6_pbmt),
    .io_resp_bits_resp_entry_6_perm_d(i_io_resp_bits_resp_entry_6_perm_d),
    .io_resp_bits_resp_entry_6_perm_a(i_io_resp_bits_resp_entry_6_perm_a),
    .io_resp_bits_resp_entry_6_perm_g(i_io_resp_bits_resp_entry_6_perm_g),
    .io_resp_bits_resp_entry_6_perm_u(i_io_resp_bits_resp_entry_6_perm_u),
    .io_resp_bits_resp_entry_6_perm_x(i_io_resp_bits_resp_entry_6_perm_x),
    .io_resp_bits_resp_entry_6_perm_w(i_io_resp_bits_resp_entry_6_perm_w),
    .io_resp_bits_resp_entry_6_perm_r(i_io_resp_bits_resp_entry_6_perm_r),
    .io_resp_bits_resp_entry_6_level(i_io_resp_bits_resp_entry_6_level),
    .io_resp_bits_resp_entry_6_v(i_io_resp_bits_resp_entry_6_v),
    .io_resp_bits_resp_entry_6_ppn(i_io_resp_bits_resp_entry_6_ppn),
    .io_resp_bits_resp_entry_6_ppn_low(i_io_resp_bits_resp_entry_6_ppn_low),
    .io_resp_bits_resp_entry_6_af(i_io_resp_bits_resp_entry_6_af),
    .io_resp_bits_resp_entry_6_pf(i_io_resp_bits_resp_entry_6_pf),
    .io_resp_bits_resp_entry_7_tag(i_io_resp_bits_resp_entry_7_tag),
    .io_resp_bits_resp_entry_7_asid(i_io_resp_bits_resp_entry_7_asid),
    .io_resp_bits_resp_entry_7_vmid(i_io_resp_bits_resp_entry_7_vmid),
    .io_resp_bits_resp_entry_7_n(i_io_resp_bits_resp_entry_7_n),
    .io_resp_bits_resp_entry_7_pbmt(i_io_resp_bits_resp_entry_7_pbmt),
    .io_resp_bits_resp_entry_7_perm_d(i_io_resp_bits_resp_entry_7_perm_d),
    .io_resp_bits_resp_entry_7_perm_a(i_io_resp_bits_resp_entry_7_perm_a),
    .io_resp_bits_resp_entry_7_perm_g(i_io_resp_bits_resp_entry_7_perm_g),
    .io_resp_bits_resp_entry_7_perm_u(i_io_resp_bits_resp_entry_7_perm_u),
    .io_resp_bits_resp_entry_7_perm_x(i_io_resp_bits_resp_entry_7_perm_x),
    .io_resp_bits_resp_entry_7_perm_w(i_io_resp_bits_resp_entry_7_perm_w),
    .io_resp_bits_resp_entry_7_perm_r(i_io_resp_bits_resp_entry_7_perm_r),
    .io_resp_bits_resp_entry_7_level(i_io_resp_bits_resp_entry_7_level),
    .io_resp_bits_resp_entry_7_v(i_io_resp_bits_resp_entry_7_v),
    .io_resp_bits_resp_entry_7_ppn(i_io_resp_bits_resp_entry_7_ppn),
    .io_resp_bits_resp_entry_7_ppn_low(i_io_resp_bits_resp_entry_7_ppn_low),
    .io_resp_bits_resp_entry_7_af(i_io_resp_bits_resp_entry_7_af),
    .io_resp_bits_resp_entry_7_pf(i_io_resp_bits_resp_entry_7_pf),
    .io_resp_bits_resp_pteidx_0(i_io_resp_bits_resp_pteidx_0),
    .io_resp_bits_resp_pteidx_1(i_io_resp_bits_resp_pteidx_1),
    .io_resp_bits_resp_pteidx_2(i_io_resp_bits_resp_pteidx_2),
    .io_resp_bits_resp_pteidx_3(i_io_resp_bits_resp_pteidx_3),
    .io_resp_bits_resp_pteidx_4(i_io_resp_bits_resp_pteidx_4),
    .io_resp_bits_resp_pteidx_5(i_io_resp_bits_resp_pteidx_5),
    .io_resp_bits_resp_pteidx_6(i_io_resp_bits_resp_pteidx_6),
    .io_resp_bits_resp_pteidx_7(i_io_resp_bits_resp_pteidx_7),
    .io_resp_bits_resp_not_super(i_io_resp_bits_resp_not_super),
    .io_resp_bits_h_resp_entry_tag(i_io_resp_bits_h_resp_entry_tag),
    .io_resp_bits_h_resp_entry_vmid(i_io_resp_bits_h_resp_entry_vmid),
    .io_resp_bits_h_resp_entry_n(i_io_resp_bits_h_resp_entry_n),
    .io_resp_bits_h_resp_entry_pbmt(i_io_resp_bits_h_resp_entry_pbmt),
    .io_resp_bits_h_resp_entry_ppn(i_io_resp_bits_h_resp_entry_ppn),
    .io_resp_bits_h_resp_entry_perm_d(i_io_resp_bits_h_resp_entry_perm_d),
    .io_resp_bits_h_resp_entry_perm_a(i_io_resp_bits_h_resp_entry_perm_a),
    .io_resp_bits_h_resp_entry_perm_g(i_io_resp_bits_h_resp_entry_perm_g),
    .io_resp_bits_h_resp_entry_perm_u(i_io_resp_bits_h_resp_entry_perm_u),
    .io_resp_bits_h_resp_entry_perm_x(i_io_resp_bits_h_resp_entry_perm_x),
    .io_resp_bits_h_resp_entry_perm_w(i_io_resp_bits_h_resp_entry_perm_w),
    .io_resp_bits_h_resp_entry_perm_r(i_io_resp_bits_h_resp_entry_perm_r),
    .io_resp_bits_h_resp_entry_level(i_io_resp_bits_h_resp_entry_level),
    .io_resp_bits_h_resp_gpf(i_io_resp_bits_h_resp_gpf),
    .io_resp_bits_h_resp_gaf(i_io_resp_bits_h_resp_gaf),
    .io_llptw_ready(io_llptw_ready),
    .io_llptw_valid(i_io_llptw_valid),
    .io_llptw_bits_req_info_vpn(i_io_llptw_bits_req_info_vpn),
    .io_llptw_bits_req_info_s2xlate(i_io_llptw_bits_req_info_s2xlate),
    .io_llptw_bits_req_info_source(i_io_llptw_bits_req_info_source),
    .io_hptw_req_ready(io_hptw_req_ready),
    .io_hptw_req_valid(i_io_hptw_req_valid),
    .io_hptw_req_bits_source(i_io_hptw_req_bits_source),
    .io_hptw_req_bits_gvpn(i_io_hptw_req_bits_gvpn),
    .io_hptw_resp_valid(io_hptw_resp_valid),
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
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(i_io_mem_req_valid),
    .io_mem_req_bits_addr(i_io_mem_req_bits_addr),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits(io_mem_resp_bits),
    .io_mem_mask(io_mem_mask),
    .io_pmp_req_bits_addr(i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_refill_req_info_vpn(i_io_refill_req_info_vpn),
    .io_refill_req_info_s2xlate(i_io_refill_req_info_s2xlate),
    .io_refill_req_info_source(i_io_refill_req_info_source),
    .io_refill_level(i_io_refill_level),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value)
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
    io_sfence_valid = $urandom;
    io_csr_satp_mode = $urandom;
    io_csr_satp_asid = $urandom;
    io_csr_satp_ppn = $urandom;
    io_csr_satp_changed = $urandom;
    io_csr_vsatp_mode = $urandom;
    io_csr_vsatp_asid = $urandom;
    io_csr_vsatp_ppn = $urandom;
    io_csr_vsatp_changed = $urandom;
    io_csr_hgatp_mode = $urandom;
    io_csr_hgatp_vmid = $urandom;
    io_csr_hgatp_changed = $urandom;
    io_csr_priv_mxr = $urandom;
    io_csr_mPBMTE = $urandom;
    io_csr_hPBMTE = $urandom;
    io_req_valid = $urandom;
    io_req_bits_req_info_vpn = $urandom;
    io_req_bits_req_info_s2xlate = $urandom;
    io_req_bits_req_info_source = $urandom;
    io_req_bits_l3Hit = $urandom;
    io_req_bits_l2Hit = $urandom;
    io_req_bits_ppn = $urandom;
    io_req_bits_stage1Hit = $urandom;
    io_req_bits_stage1_entry_0_tag = $urandom;
    io_req_bits_stage1_entry_0_asid = $urandom;
    io_req_bits_stage1_entry_0_vmid = $urandom;
    io_req_bits_stage1_entry_0_n = $urandom;
    io_req_bits_stage1_entry_0_pbmt = $urandom;
    io_req_bits_stage1_entry_0_perm_d = $urandom;
    io_req_bits_stage1_entry_0_perm_a = $urandom;
    io_req_bits_stage1_entry_0_perm_g = $urandom;
    io_req_bits_stage1_entry_0_perm_u = $urandom;
    io_req_bits_stage1_entry_0_perm_x = $urandom;
    io_req_bits_stage1_entry_0_perm_w = $urandom;
    io_req_bits_stage1_entry_0_perm_r = $urandom;
    io_req_bits_stage1_entry_0_level = $urandom;
    io_req_bits_stage1_entry_0_v = $urandom;
    io_req_bits_stage1_entry_0_ppn = $urandom;
    io_req_bits_stage1_entry_0_ppn_low = $urandom;
    io_req_bits_stage1_entry_0_pf = $urandom;
    io_req_bits_stage1_entry_1_tag = $urandom;
    io_req_bits_stage1_entry_1_asid = $urandom;
    io_req_bits_stage1_entry_1_vmid = $urandom;
    io_req_bits_stage1_entry_1_n = $urandom;
    io_req_bits_stage1_entry_1_pbmt = $urandom;
    io_req_bits_stage1_entry_1_perm_d = $urandom;
    io_req_bits_stage1_entry_1_perm_a = $urandom;
    io_req_bits_stage1_entry_1_perm_g = $urandom;
    io_req_bits_stage1_entry_1_perm_u = $urandom;
    io_req_bits_stage1_entry_1_perm_x = $urandom;
    io_req_bits_stage1_entry_1_perm_w = $urandom;
    io_req_bits_stage1_entry_1_perm_r = $urandom;
    io_req_bits_stage1_entry_1_level = $urandom;
    io_req_bits_stage1_entry_1_v = $urandom;
    io_req_bits_stage1_entry_1_ppn = $urandom;
    io_req_bits_stage1_entry_1_ppn_low = $urandom;
    io_req_bits_stage1_entry_1_pf = $urandom;
    io_req_bits_stage1_entry_2_tag = $urandom;
    io_req_bits_stage1_entry_2_asid = $urandom;
    io_req_bits_stage1_entry_2_vmid = $urandom;
    io_req_bits_stage1_entry_2_n = $urandom;
    io_req_bits_stage1_entry_2_pbmt = $urandom;
    io_req_bits_stage1_entry_2_perm_d = $urandom;
    io_req_bits_stage1_entry_2_perm_a = $urandom;
    io_req_bits_stage1_entry_2_perm_g = $urandom;
    io_req_bits_stage1_entry_2_perm_u = $urandom;
    io_req_bits_stage1_entry_2_perm_x = $urandom;
    io_req_bits_stage1_entry_2_perm_w = $urandom;
    io_req_bits_stage1_entry_2_perm_r = $urandom;
    io_req_bits_stage1_entry_2_level = $urandom;
    io_req_bits_stage1_entry_2_v = $urandom;
    io_req_bits_stage1_entry_2_ppn = $urandom;
    io_req_bits_stage1_entry_2_ppn_low = $urandom;
    io_req_bits_stage1_entry_2_pf = $urandom;
    io_req_bits_stage1_entry_3_tag = $urandom;
    io_req_bits_stage1_entry_3_asid = $urandom;
    io_req_bits_stage1_entry_3_vmid = $urandom;
    io_req_bits_stage1_entry_3_n = $urandom;
    io_req_bits_stage1_entry_3_pbmt = $urandom;
    io_req_bits_stage1_entry_3_perm_d = $urandom;
    io_req_bits_stage1_entry_3_perm_a = $urandom;
    io_req_bits_stage1_entry_3_perm_g = $urandom;
    io_req_bits_stage1_entry_3_perm_u = $urandom;
    io_req_bits_stage1_entry_3_perm_x = $urandom;
    io_req_bits_stage1_entry_3_perm_w = $urandom;
    io_req_bits_stage1_entry_3_perm_r = $urandom;
    io_req_bits_stage1_entry_3_level = $urandom;
    io_req_bits_stage1_entry_3_v = $urandom;
    io_req_bits_stage1_entry_3_ppn = $urandom;
    io_req_bits_stage1_entry_3_ppn_low = $urandom;
    io_req_bits_stage1_entry_3_pf = $urandom;
    io_req_bits_stage1_entry_4_tag = $urandom;
    io_req_bits_stage1_entry_4_asid = $urandom;
    io_req_bits_stage1_entry_4_vmid = $urandom;
    io_req_bits_stage1_entry_4_n = $urandom;
    io_req_bits_stage1_entry_4_pbmt = $urandom;
    io_req_bits_stage1_entry_4_perm_d = $urandom;
    io_req_bits_stage1_entry_4_perm_a = $urandom;
    io_req_bits_stage1_entry_4_perm_g = $urandom;
    io_req_bits_stage1_entry_4_perm_u = $urandom;
    io_req_bits_stage1_entry_4_perm_x = $urandom;
    io_req_bits_stage1_entry_4_perm_w = $urandom;
    io_req_bits_stage1_entry_4_perm_r = $urandom;
    io_req_bits_stage1_entry_4_level = $urandom;
    io_req_bits_stage1_entry_4_v = $urandom;
    io_req_bits_stage1_entry_4_ppn = $urandom;
    io_req_bits_stage1_entry_4_ppn_low = $urandom;
    io_req_bits_stage1_entry_4_pf = $urandom;
    io_req_bits_stage1_entry_5_tag = $urandom;
    io_req_bits_stage1_entry_5_asid = $urandom;
    io_req_bits_stage1_entry_5_vmid = $urandom;
    io_req_bits_stage1_entry_5_n = $urandom;
    io_req_bits_stage1_entry_5_pbmt = $urandom;
    io_req_bits_stage1_entry_5_perm_d = $urandom;
    io_req_bits_stage1_entry_5_perm_a = $urandom;
    io_req_bits_stage1_entry_5_perm_g = $urandom;
    io_req_bits_stage1_entry_5_perm_u = $urandom;
    io_req_bits_stage1_entry_5_perm_x = $urandom;
    io_req_bits_stage1_entry_5_perm_w = $urandom;
    io_req_bits_stage1_entry_5_perm_r = $urandom;
    io_req_bits_stage1_entry_5_level = $urandom;
    io_req_bits_stage1_entry_5_v = $urandom;
    io_req_bits_stage1_entry_5_ppn = $urandom;
    io_req_bits_stage1_entry_5_ppn_low = $urandom;
    io_req_bits_stage1_entry_5_pf = $urandom;
    io_req_bits_stage1_entry_6_tag = $urandom;
    io_req_bits_stage1_entry_6_asid = $urandom;
    io_req_bits_stage1_entry_6_vmid = $urandom;
    io_req_bits_stage1_entry_6_n = $urandom;
    io_req_bits_stage1_entry_6_pbmt = $urandom;
    io_req_bits_stage1_entry_6_perm_d = $urandom;
    io_req_bits_stage1_entry_6_perm_a = $urandom;
    io_req_bits_stage1_entry_6_perm_g = $urandom;
    io_req_bits_stage1_entry_6_perm_u = $urandom;
    io_req_bits_stage1_entry_6_perm_x = $urandom;
    io_req_bits_stage1_entry_6_perm_w = $urandom;
    io_req_bits_stage1_entry_6_perm_r = $urandom;
    io_req_bits_stage1_entry_6_level = $urandom;
    io_req_bits_stage1_entry_6_v = $urandom;
    io_req_bits_stage1_entry_6_ppn = $urandom;
    io_req_bits_stage1_entry_6_ppn_low = $urandom;
    io_req_bits_stage1_entry_6_pf = $urandom;
    io_req_bits_stage1_entry_7_tag = $urandom;
    io_req_bits_stage1_entry_7_asid = $urandom;
    io_req_bits_stage1_entry_7_vmid = $urandom;
    io_req_bits_stage1_entry_7_n = $urandom;
    io_req_bits_stage1_entry_7_pbmt = $urandom;
    io_req_bits_stage1_entry_7_perm_d = $urandom;
    io_req_bits_stage1_entry_7_perm_a = $urandom;
    io_req_bits_stage1_entry_7_perm_g = $urandom;
    io_req_bits_stage1_entry_7_perm_u = $urandom;
    io_req_bits_stage1_entry_7_perm_x = $urandom;
    io_req_bits_stage1_entry_7_perm_w = $urandom;
    io_req_bits_stage1_entry_7_perm_r = $urandom;
    io_req_bits_stage1_entry_7_level = $urandom;
    io_req_bits_stage1_entry_7_v = $urandom;
    io_req_bits_stage1_entry_7_ppn = $urandom;
    io_req_bits_stage1_entry_7_ppn_low = $urandom;
    io_req_bits_stage1_entry_7_pf = $urandom;
    io_req_bits_stage1_pteidx_0 = $urandom;
    io_req_bits_stage1_pteidx_1 = $urandom;
    io_req_bits_stage1_pteidx_2 = $urandom;
    io_req_bits_stage1_pteidx_3 = $urandom;
    io_req_bits_stage1_pteidx_4 = $urandom;
    io_req_bits_stage1_pteidx_5 = $urandom;
    io_req_bits_stage1_pteidx_6 = $urandom;
    io_req_bits_stage1_pteidx_7 = $urandom;
    io_req_bits_stage1_not_super = $urandom;
    io_resp_ready = $urandom;
    io_llptw_ready = $urandom;
    io_hptw_req_ready = $urandom;
    io_hptw_resp_valid = $urandom;
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
    io_mem_req_ready = $urandom;
    io_mem_resp_valid = $urandom;
    io_mem_resp_bits = $urandom;
    io_mem_mask = $urandom;
    io_pmp_resp_ld = $urandom;
    io_pmp_resp_mmio = $urandom;
    // 约束握手环境，避免无界 backpressure 干扰随机 UT 收敛。
    io_resp_ready = ($urandom_range(0, 7) != 0);
    io_llptw_ready = ($urandom_range(0, 3) != 0);
    io_hptw_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_mask = ($urandom_range(0, 31) == 0);
    io_csr_satp_mode = ($urandom_range(0, 3) == 0) ? 4'h8 : 4'h9;
    io_csr_vsatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_req_valid = ($urandom_range(0, 3) == 0);
    io_req_bits_req_info_s2xlate = $urandom_range(0, 3);
    io_req_bits_req_info_source = $urandom_range(0, 2);
    io_req_bits_stage1Hit = ($urandom_range(0, 31) == 0);
    io_req_bits_l2Hit = ($urandom_range(0, 7) == 0);
    io_req_bits_l3Hit = ($urandom_range(0, 7) == 0);
    io_mem_resp_valid = ($urandom_range(0, 3) == 0);
    io_hptw_resp_valid = ($urandom_range(0, 3) == 0);
    io_sfence_valid = ($urandom_range(0, 127) == 0);
    io_csr_satp_changed = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
    {io_req_bits_stage1_pteidx_7, io_req_bits_stage1_pteidx_6,
     io_req_bits_stage1_pteidx_5, io_req_bits_stage1_pteidx_4,
     io_req_bits_stage1_pteidx_3, io_req_bits_stage1_pteidx_2,
     io_req_bits_stage1_pteidx_1, io_req_bits_stage1_pteidx_0} = 8'b0000_0001 << io_req_bits_req_info_vpn[2:0];
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
      if (!$isunknown(g_io_req_ready) && i_io_req_ready !== g_io_req_ready) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_req_ready: g=%0h i=%0h cycle=%0d", g_io_req_ready, i_io_req_ready, cycle);
      end
      if (!$isunknown(g_io_resp_valid) && i_io_resp_valid !== g_io_resp_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_valid: g=%0h i=%0h cycle=%0d", g_io_resp_valid, i_io_resp_valid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_source) && i_io_resp_bits_source !== g_io_resp_bits_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_source: g=%0h i=%0h cycle=%0d", g_io_resp_bits_source, i_io_resp_bits_source, cycle);
      end
      if (!$isunknown(g_io_resp_bits_s2xlate) && i_io_resp_bits_s2xlate !== g_io_resp_bits_s2xlate) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_s2xlate: g=%0h i=%0h cycle=%0d", g_io_resp_bits_s2xlate, i_io_resp_bits_s2xlate, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_tag) && i_io_resp_bits_resp_entry_0_tag !== g_io_resp_bits_resp_entry_0_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_tag, i_io_resp_bits_resp_entry_0_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_asid) && i_io_resp_bits_resp_entry_0_asid !== g_io_resp_bits_resp_entry_0_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_asid, i_io_resp_bits_resp_entry_0_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_vmid) && i_io_resp_bits_resp_entry_0_vmid !== g_io_resp_bits_resp_entry_0_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_vmid, i_io_resp_bits_resp_entry_0_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_n) && i_io_resp_bits_resp_entry_0_n !== g_io_resp_bits_resp_entry_0_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_n, i_io_resp_bits_resp_entry_0_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_pbmt) && i_io_resp_bits_resp_entry_0_pbmt !== g_io_resp_bits_resp_entry_0_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_pbmt, i_io_resp_bits_resp_entry_0_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_d) && i_io_resp_bits_resp_entry_0_perm_d !== g_io_resp_bits_resp_entry_0_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_d, i_io_resp_bits_resp_entry_0_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_a) && i_io_resp_bits_resp_entry_0_perm_a !== g_io_resp_bits_resp_entry_0_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_a, i_io_resp_bits_resp_entry_0_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_g) && i_io_resp_bits_resp_entry_0_perm_g !== g_io_resp_bits_resp_entry_0_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_g, i_io_resp_bits_resp_entry_0_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_u) && i_io_resp_bits_resp_entry_0_perm_u !== g_io_resp_bits_resp_entry_0_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_u, i_io_resp_bits_resp_entry_0_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_x) && i_io_resp_bits_resp_entry_0_perm_x !== g_io_resp_bits_resp_entry_0_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_x, i_io_resp_bits_resp_entry_0_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_w) && i_io_resp_bits_resp_entry_0_perm_w !== g_io_resp_bits_resp_entry_0_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_w, i_io_resp_bits_resp_entry_0_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_perm_r) && i_io_resp_bits_resp_entry_0_perm_r !== g_io_resp_bits_resp_entry_0_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_perm_r, i_io_resp_bits_resp_entry_0_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_level) && i_io_resp_bits_resp_entry_0_level !== g_io_resp_bits_resp_entry_0_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_level, i_io_resp_bits_resp_entry_0_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_v) && i_io_resp_bits_resp_entry_0_v !== g_io_resp_bits_resp_entry_0_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_v, i_io_resp_bits_resp_entry_0_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_ppn) && i_io_resp_bits_resp_entry_0_ppn !== g_io_resp_bits_resp_entry_0_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_ppn, i_io_resp_bits_resp_entry_0_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_ppn_low) && i_io_resp_bits_resp_entry_0_ppn_low !== g_io_resp_bits_resp_entry_0_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_ppn_low, i_io_resp_bits_resp_entry_0_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_af) && i_io_resp_bits_resp_entry_0_af !== g_io_resp_bits_resp_entry_0_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_af, i_io_resp_bits_resp_entry_0_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_0_pf) && i_io_resp_bits_resp_entry_0_pf !== g_io_resp_bits_resp_entry_0_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_0_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_0_pf, i_io_resp_bits_resp_entry_0_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_tag) && i_io_resp_bits_resp_entry_1_tag !== g_io_resp_bits_resp_entry_1_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_tag, i_io_resp_bits_resp_entry_1_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_asid) && i_io_resp_bits_resp_entry_1_asid !== g_io_resp_bits_resp_entry_1_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_asid, i_io_resp_bits_resp_entry_1_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_vmid) && i_io_resp_bits_resp_entry_1_vmid !== g_io_resp_bits_resp_entry_1_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_vmid, i_io_resp_bits_resp_entry_1_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_n) && i_io_resp_bits_resp_entry_1_n !== g_io_resp_bits_resp_entry_1_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_n, i_io_resp_bits_resp_entry_1_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_pbmt) && i_io_resp_bits_resp_entry_1_pbmt !== g_io_resp_bits_resp_entry_1_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_pbmt, i_io_resp_bits_resp_entry_1_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_d) && i_io_resp_bits_resp_entry_1_perm_d !== g_io_resp_bits_resp_entry_1_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_d, i_io_resp_bits_resp_entry_1_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_a) && i_io_resp_bits_resp_entry_1_perm_a !== g_io_resp_bits_resp_entry_1_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_a, i_io_resp_bits_resp_entry_1_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_g) && i_io_resp_bits_resp_entry_1_perm_g !== g_io_resp_bits_resp_entry_1_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_g, i_io_resp_bits_resp_entry_1_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_u) && i_io_resp_bits_resp_entry_1_perm_u !== g_io_resp_bits_resp_entry_1_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_u, i_io_resp_bits_resp_entry_1_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_x) && i_io_resp_bits_resp_entry_1_perm_x !== g_io_resp_bits_resp_entry_1_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_x, i_io_resp_bits_resp_entry_1_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_w) && i_io_resp_bits_resp_entry_1_perm_w !== g_io_resp_bits_resp_entry_1_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_w, i_io_resp_bits_resp_entry_1_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_perm_r) && i_io_resp_bits_resp_entry_1_perm_r !== g_io_resp_bits_resp_entry_1_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_perm_r, i_io_resp_bits_resp_entry_1_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_level) && i_io_resp_bits_resp_entry_1_level !== g_io_resp_bits_resp_entry_1_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_level, i_io_resp_bits_resp_entry_1_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_v) && i_io_resp_bits_resp_entry_1_v !== g_io_resp_bits_resp_entry_1_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_v, i_io_resp_bits_resp_entry_1_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_ppn) && i_io_resp_bits_resp_entry_1_ppn !== g_io_resp_bits_resp_entry_1_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_ppn, i_io_resp_bits_resp_entry_1_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_ppn_low) && i_io_resp_bits_resp_entry_1_ppn_low !== g_io_resp_bits_resp_entry_1_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_ppn_low, i_io_resp_bits_resp_entry_1_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_af) && i_io_resp_bits_resp_entry_1_af !== g_io_resp_bits_resp_entry_1_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_af, i_io_resp_bits_resp_entry_1_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_1_pf) && i_io_resp_bits_resp_entry_1_pf !== g_io_resp_bits_resp_entry_1_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_1_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_1_pf, i_io_resp_bits_resp_entry_1_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_tag) && i_io_resp_bits_resp_entry_2_tag !== g_io_resp_bits_resp_entry_2_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_tag, i_io_resp_bits_resp_entry_2_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_asid) && i_io_resp_bits_resp_entry_2_asid !== g_io_resp_bits_resp_entry_2_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_asid, i_io_resp_bits_resp_entry_2_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_vmid) && i_io_resp_bits_resp_entry_2_vmid !== g_io_resp_bits_resp_entry_2_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_vmid, i_io_resp_bits_resp_entry_2_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_n) && i_io_resp_bits_resp_entry_2_n !== g_io_resp_bits_resp_entry_2_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_n, i_io_resp_bits_resp_entry_2_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_pbmt) && i_io_resp_bits_resp_entry_2_pbmt !== g_io_resp_bits_resp_entry_2_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_pbmt, i_io_resp_bits_resp_entry_2_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_d) && i_io_resp_bits_resp_entry_2_perm_d !== g_io_resp_bits_resp_entry_2_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_d, i_io_resp_bits_resp_entry_2_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_a) && i_io_resp_bits_resp_entry_2_perm_a !== g_io_resp_bits_resp_entry_2_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_a, i_io_resp_bits_resp_entry_2_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_g) && i_io_resp_bits_resp_entry_2_perm_g !== g_io_resp_bits_resp_entry_2_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_g, i_io_resp_bits_resp_entry_2_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_u) && i_io_resp_bits_resp_entry_2_perm_u !== g_io_resp_bits_resp_entry_2_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_u, i_io_resp_bits_resp_entry_2_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_x) && i_io_resp_bits_resp_entry_2_perm_x !== g_io_resp_bits_resp_entry_2_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_x, i_io_resp_bits_resp_entry_2_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_w) && i_io_resp_bits_resp_entry_2_perm_w !== g_io_resp_bits_resp_entry_2_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_w, i_io_resp_bits_resp_entry_2_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_perm_r) && i_io_resp_bits_resp_entry_2_perm_r !== g_io_resp_bits_resp_entry_2_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_perm_r, i_io_resp_bits_resp_entry_2_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_level) && i_io_resp_bits_resp_entry_2_level !== g_io_resp_bits_resp_entry_2_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_level, i_io_resp_bits_resp_entry_2_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_v) && i_io_resp_bits_resp_entry_2_v !== g_io_resp_bits_resp_entry_2_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_v, i_io_resp_bits_resp_entry_2_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_ppn) && i_io_resp_bits_resp_entry_2_ppn !== g_io_resp_bits_resp_entry_2_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_ppn, i_io_resp_bits_resp_entry_2_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_ppn_low) && i_io_resp_bits_resp_entry_2_ppn_low !== g_io_resp_bits_resp_entry_2_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_ppn_low, i_io_resp_bits_resp_entry_2_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_af) && i_io_resp_bits_resp_entry_2_af !== g_io_resp_bits_resp_entry_2_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_af, i_io_resp_bits_resp_entry_2_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_2_pf) && i_io_resp_bits_resp_entry_2_pf !== g_io_resp_bits_resp_entry_2_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_2_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_2_pf, i_io_resp_bits_resp_entry_2_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_tag) && i_io_resp_bits_resp_entry_3_tag !== g_io_resp_bits_resp_entry_3_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_tag, i_io_resp_bits_resp_entry_3_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_asid) && i_io_resp_bits_resp_entry_3_asid !== g_io_resp_bits_resp_entry_3_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_asid, i_io_resp_bits_resp_entry_3_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_vmid) && i_io_resp_bits_resp_entry_3_vmid !== g_io_resp_bits_resp_entry_3_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_vmid, i_io_resp_bits_resp_entry_3_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_n) && i_io_resp_bits_resp_entry_3_n !== g_io_resp_bits_resp_entry_3_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_n, i_io_resp_bits_resp_entry_3_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_pbmt) && i_io_resp_bits_resp_entry_3_pbmt !== g_io_resp_bits_resp_entry_3_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_pbmt, i_io_resp_bits_resp_entry_3_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_d) && i_io_resp_bits_resp_entry_3_perm_d !== g_io_resp_bits_resp_entry_3_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_d, i_io_resp_bits_resp_entry_3_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_a) && i_io_resp_bits_resp_entry_3_perm_a !== g_io_resp_bits_resp_entry_3_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_a, i_io_resp_bits_resp_entry_3_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_g) && i_io_resp_bits_resp_entry_3_perm_g !== g_io_resp_bits_resp_entry_3_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_g, i_io_resp_bits_resp_entry_3_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_u) && i_io_resp_bits_resp_entry_3_perm_u !== g_io_resp_bits_resp_entry_3_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_u, i_io_resp_bits_resp_entry_3_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_x) && i_io_resp_bits_resp_entry_3_perm_x !== g_io_resp_bits_resp_entry_3_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_x, i_io_resp_bits_resp_entry_3_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_w) && i_io_resp_bits_resp_entry_3_perm_w !== g_io_resp_bits_resp_entry_3_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_w, i_io_resp_bits_resp_entry_3_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_perm_r) && i_io_resp_bits_resp_entry_3_perm_r !== g_io_resp_bits_resp_entry_3_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_perm_r, i_io_resp_bits_resp_entry_3_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_level) && i_io_resp_bits_resp_entry_3_level !== g_io_resp_bits_resp_entry_3_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_level, i_io_resp_bits_resp_entry_3_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_v) && i_io_resp_bits_resp_entry_3_v !== g_io_resp_bits_resp_entry_3_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_v, i_io_resp_bits_resp_entry_3_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_ppn) && i_io_resp_bits_resp_entry_3_ppn !== g_io_resp_bits_resp_entry_3_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_ppn, i_io_resp_bits_resp_entry_3_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_ppn_low) && i_io_resp_bits_resp_entry_3_ppn_low !== g_io_resp_bits_resp_entry_3_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_ppn_low, i_io_resp_bits_resp_entry_3_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_af) && i_io_resp_bits_resp_entry_3_af !== g_io_resp_bits_resp_entry_3_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_af, i_io_resp_bits_resp_entry_3_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_3_pf) && i_io_resp_bits_resp_entry_3_pf !== g_io_resp_bits_resp_entry_3_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_3_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_3_pf, i_io_resp_bits_resp_entry_3_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_tag) && i_io_resp_bits_resp_entry_4_tag !== g_io_resp_bits_resp_entry_4_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_tag, i_io_resp_bits_resp_entry_4_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_asid) && i_io_resp_bits_resp_entry_4_asid !== g_io_resp_bits_resp_entry_4_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_asid, i_io_resp_bits_resp_entry_4_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_vmid) && i_io_resp_bits_resp_entry_4_vmid !== g_io_resp_bits_resp_entry_4_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_vmid, i_io_resp_bits_resp_entry_4_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_n) && i_io_resp_bits_resp_entry_4_n !== g_io_resp_bits_resp_entry_4_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_n, i_io_resp_bits_resp_entry_4_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_pbmt) && i_io_resp_bits_resp_entry_4_pbmt !== g_io_resp_bits_resp_entry_4_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_pbmt, i_io_resp_bits_resp_entry_4_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_d) && i_io_resp_bits_resp_entry_4_perm_d !== g_io_resp_bits_resp_entry_4_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_d, i_io_resp_bits_resp_entry_4_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_a) && i_io_resp_bits_resp_entry_4_perm_a !== g_io_resp_bits_resp_entry_4_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_a, i_io_resp_bits_resp_entry_4_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_g) && i_io_resp_bits_resp_entry_4_perm_g !== g_io_resp_bits_resp_entry_4_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_g, i_io_resp_bits_resp_entry_4_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_u) && i_io_resp_bits_resp_entry_4_perm_u !== g_io_resp_bits_resp_entry_4_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_u, i_io_resp_bits_resp_entry_4_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_x) && i_io_resp_bits_resp_entry_4_perm_x !== g_io_resp_bits_resp_entry_4_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_x, i_io_resp_bits_resp_entry_4_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_w) && i_io_resp_bits_resp_entry_4_perm_w !== g_io_resp_bits_resp_entry_4_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_w, i_io_resp_bits_resp_entry_4_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_perm_r) && i_io_resp_bits_resp_entry_4_perm_r !== g_io_resp_bits_resp_entry_4_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_perm_r, i_io_resp_bits_resp_entry_4_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_level) && i_io_resp_bits_resp_entry_4_level !== g_io_resp_bits_resp_entry_4_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_level, i_io_resp_bits_resp_entry_4_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_v) && i_io_resp_bits_resp_entry_4_v !== g_io_resp_bits_resp_entry_4_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_v, i_io_resp_bits_resp_entry_4_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_ppn) && i_io_resp_bits_resp_entry_4_ppn !== g_io_resp_bits_resp_entry_4_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_ppn, i_io_resp_bits_resp_entry_4_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_ppn_low) && i_io_resp_bits_resp_entry_4_ppn_low !== g_io_resp_bits_resp_entry_4_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_ppn_low, i_io_resp_bits_resp_entry_4_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_af) && i_io_resp_bits_resp_entry_4_af !== g_io_resp_bits_resp_entry_4_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_af, i_io_resp_bits_resp_entry_4_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_4_pf) && i_io_resp_bits_resp_entry_4_pf !== g_io_resp_bits_resp_entry_4_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_4_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_4_pf, i_io_resp_bits_resp_entry_4_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_tag) && i_io_resp_bits_resp_entry_5_tag !== g_io_resp_bits_resp_entry_5_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_tag, i_io_resp_bits_resp_entry_5_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_asid) && i_io_resp_bits_resp_entry_5_asid !== g_io_resp_bits_resp_entry_5_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_asid, i_io_resp_bits_resp_entry_5_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_vmid) && i_io_resp_bits_resp_entry_5_vmid !== g_io_resp_bits_resp_entry_5_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_vmid, i_io_resp_bits_resp_entry_5_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_n) && i_io_resp_bits_resp_entry_5_n !== g_io_resp_bits_resp_entry_5_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_n, i_io_resp_bits_resp_entry_5_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_pbmt) && i_io_resp_bits_resp_entry_5_pbmt !== g_io_resp_bits_resp_entry_5_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_pbmt, i_io_resp_bits_resp_entry_5_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_d) && i_io_resp_bits_resp_entry_5_perm_d !== g_io_resp_bits_resp_entry_5_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_d, i_io_resp_bits_resp_entry_5_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_a) && i_io_resp_bits_resp_entry_5_perm_a !== g_io_resp_bits_resp_entry_5_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_a, i_io_resp_bits_resp_entry_5_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_g) && i_io_resp_bits_resp_entry_5_perm_g !== g_io_resp_bits_resp_entry_5_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_g, i_io_resp_bits_resp_entry_5_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_u) && i_io_resp_bits_resp_entry_5_perm_u !== g_io_resp_bits_resp_entry_5_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_u, i_io_resp_bits_resp_entry_5_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_x) && i_io_resp_bits_resp_entry_5_perm_x !== g_io_resp_bits_resp_entry_5_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_x, i_io_resp_bits_resp_entry_5_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_w) && i_io_resp_bits_resp_entry_5_perm_w !== g_io_resp_bits_resp_entry_5_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_w, i_io_resp_bits_resp_entry_5_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_perm_r) && i_io_resp_bits_resp_entry_5_perm_r !== g_io_resp_bits_resp_entry_5_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_perm_r, i_io_resp_bits_resp_entry_5_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_level) && i_io_resp_bits_resp_entry_5_level !== g_io_resp_bits_resp_entry_5_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_level, i_io_resp_bits_resp_entry_5_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_v) && i_io_resp_bits_resp_entry_5_v !== g_io_resp_bits_resp_entry_5_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_v, i_io_resp_bits_resp_entry_5_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_ppn) && i_io_resp_bits_resp_entry_5_ppn !== g_io_resp_bits_resp_entry_5_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_ppn, i_io_resp_bits_resp_entry_5_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_ppn_low) && i_io_resp_bits_resp_entry_5_ppn_low !== g_io_resp_bits_resp_entry_5_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_ppn_low, i_io_resp_bits_resp_entry_5_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_af) && i_io_resp_bits_resp_entry_5_af !== g_io_resp_bits_resp_entry_5_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_af, i_io_resp_bits_resp_entry_5_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_5_pf) && i_io_resp_bits_resp_entry_5_pf !== g_io_resp_bits_resp_entry_5_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_5_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_5_pf, i_io_resp_bits_resp_entry_5_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_tag) && i_io_resp_bits_resp_entry_6_tag !== g_io_resp_bits_resp_entry_6_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_tag, i_io_resp_bits_resp_entry_6_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_asid) && i_io_resp_bits_resp_entry_6_asid !== g_io_resp_bits_resp_entry_6_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_asid, i_io_resp_bits_resp_entry_6_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_vmid) && i_io_resp_bits_resp_entry_6_vmid !== g_io_resp_bits_resp_entry_6_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_vmid, i_io_resp_bits_resp_entry_6_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_n) && i_io_resp_bits_resp_entry_6_n !== g_io_resp_bits_resp_entry_6_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_n, i_io_resp_bits_resp_entry_6_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_pbmt) && i_io_resp_bits_resp_entry_6_pbmt !== g_io_resp_bits_resp_entry_6_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_pbmt, i_io_resp_bits_resp_entry_6_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_d) && i_io_resp_bits_resp_entry_6_perm_d !== g_io_resp_bits_resp_entry_6_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_d, i_io_resp_bits_resp_entry_6_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_a) && i_io_resp_bits_resp_entry_6_perm_a !== g_io_resp_bits_resp_entry_6_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_a, i_io_resp_bits_resp_entry_6_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_g) && i_io_resp_bits_resp_entry_6_perm_g !== g_io_resp_bits_resp_entry_6_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_g, i_io_resp_bits_resp_entry_6_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_u) && i_io_resp_bits_resp_entry_6_perm_u !== g_io_resp_bits_resp_entry_6_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_u, i_io_resp_bits_resp_entry_6_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_x) && i_io_resp_bits_resp_entry_6_perm_x !== g_io_resp_bits_resp_entry_6_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_x, i_io_resp_bits_resp_entry_6_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_w) && i_io_resp_bits_resp_entry_6_perm_w !== g_io_resp_bits_resp_entry_6_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_w, i_io_resp_bits_resp_entry_6_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_perm_r) && i_io_resp_bits_resp_entry_6_perm_r !== g_io_resp_bits_resp_entry_6_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_perm_r, i_io_resp_bits_resp_entry_6_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_level) && i_io_resp_bits_resp_entry_6_level !== g_io_resp_bits_resp_entry_6_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_level, i_io_resp_bits_resp_entry_6_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_v) && i_io_resp_bits_resp_entry_6_v !== g_io_resp_bits_resp_entry_6_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_v, i_io_resp_bits_resp_entry_6_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_ppn) && i_io_resp_bits_resp_entry_6_ppn !== g_io_resp_bits_resp_entry_6_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_ppn, i_io_resp_bits_resp_entry_6_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_ppn_low) && i_io_resp_bits_resp_entry_6_ppn_low !== g_io_resp_bits_resp_entry_6_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_ppn_low, i_io_resp_bits_resp_entry_6_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_af) && i_io_resp_bits_resp_entry_6_af !== g_io_resp_bits_resp_entry_6_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_af, i_io_resp_bits_resp_entry_6_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_6_pf) && i_io_resp_bits_resp_entry_6_pf !== g_io_resp_bits_resp_entry_6_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_6_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_6_pf, i_io_resp_bits_resp_entry_6_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_tag) && i_io_resp_bits_resp_entry_7_tag !== g_io_resp_bits_resp_entry_7_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_tag, i_io_resp_bits_resp_entry_7_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_asid) && i_io_resp_bits_resp_entry_7_asid !== g_io_resp_bits_resp_entry_7_asid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_asid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_asid, i_io_resp_bits_resp_entry_7_asid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_vmid) && i_io_resp_bits_resp_entry_7_vmid !== g_io_resp_bits_resp_entry_7_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_vmid, i_io_resp_bits_resp_entry_7_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_n) && i_io_resp_bits_resp_entry_7_n !== g_io_resp_bits_resp_entry_7_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_n, i_io_resp_bits_resp_entry_7_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_pbmt) && i_io_resp_bits_resp_entry_7_pbmt !== g_io_resp_bits_resp_entry_7_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_pbmt, i_io_resp_bits_resp_entry_7_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_d) && i_io_resp_bits_resp_entry_7_perm_d !== g_io_resp_bits_resp_entry_7_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_d, i_io_resp_bits_resp_entry_7_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_a) && i_io_resp_bits_resp_entry_7_perm_a !== g_io_resp_bits_resp_entry_7_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_a, i_io_resp_bits_resp_entry_7_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_g) && i_io_resp_bits_resp_entry_7_perm_g !== g_io_resp_bits_resp_entry_7_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_g, i_io_resp_bits_resp_entry_7_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_u) && i_io_resp_bits_resp_entry_7_perm_u !== g_io_resp_bits_resp_entry_7_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_u, i_io_resp_bits_resp_entry_7_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_x) && i_io_resp_bits_resp_entry_7_perm_x !== g_io_resp_bits_resp_entry_7_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_x, i_io_resp_bits_resp_entry_7_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_w) && i_io_resp_bits_resp_entry_7_perm_w !== g_io_resp_bits_resp_entry_7_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_w, i_io_resp_bits_resp_entry_7_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_perm_r) && i_io_resp_bits_resp_entry_7_perm_r !== g_io_resp_bits_resp_entry_7_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_perm_r, i_io_resp_bits_resp_entry_7_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_level) && i_io_resp_bits_resp_entry_7_level !== g_io_resp_bits_resp_entry_7_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_level, i_io_resp_bits_resp_entry_7_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_v) && i_io_resp_bits_resp_entry_7_v !== g_io_resp_bits_resp_entry_7_v) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_v: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_v, i_io_resp_bits_resp_entry_7_v, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_ppn) && i_io_resp_bits_resp_entry_7_ppn !== g_io_resp_bits_resp_entry_7_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_ppn, i_io_resp_bits_resp_entry_7_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_ppn_low) && i_io_resp_bits_resp_entry_7_ppn_low !== g_io_resp_bits_resp_entry_7_ppn_low) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_ppn_low: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_ppn_low, i_io_resp_bits_resp_entry_7_ppn_low, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_af) && i_io_resp_bits_resp_entry_7_af !== g_io_resp_bits_resp_entry_7_af) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_af: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_af, i_io_resp_bits_resp_entry_7_af, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_7_pf) && i_io_resp_bits_resp_entry_7_pf !== g_io_resp_bits_resp_entry_7_pf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_7_pf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_7_pf, i_io_resp_bits_resp_entry_7_pf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_0) && i_io_resp_bits_resp_pteidx_0 !== g_io_resp_bits_resp_pteidx_0) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_0: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_0, i_io_resp_bits_resp_pteidx_0, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_1) && i_io_resp_bits_resp_pteidx_1 !== g_io_resp_bits_resp_pteidx_1) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_1: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_1, i_io_resp_bits_resp_pteidx_1, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_2) && i_io_resp_bits_resp_pteidx_2 !== g_io_resp_bits_resp_pteidx_2) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_2: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_2, i_io_resp_bits_resp_pteidx_2, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_3) && i_io_resp_bits_resp_pteidx_3 !== g_io_resp_bits_resp_pteidx_3) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_3: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_3, i_io_resp_bits_resp_pteidx_3, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_4) && i_io_resp_bits_resp_pteidx_4 !== g_io_resp_bits_resp_pteidx_4) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_4: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_4, i_io_resp_bits_resp_pteidx_4, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_5) && i_io_resp_bits_resp_pteidx_5 !== g_io_resp_bits_resp_pteidx_5) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_5: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_5, i_io_resp_bits_resp_pteidx_5, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_6) && i_io_resp_bits_resp_pteidx_6 !== g_io_resp_bits_resp_pteidx_6) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_6: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_6, i_io_resp_bits_resp_pteidx_6, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_pteidx_7) && i_io_resp_bits_resp_pteidx_7 !== g_io_resp_bits_resp_pteidx_7) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_pteidx_7: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_pteidx_7, i_io_resp_bits_resp_pteidx_7, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_not_super) && i_io_resp_bits_resp_not_super !== g_io_resp_bits_resp_not_super) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_not_super: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_not_super, i_io_resp_bits_resp_not_super, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_tag) && i_io_resp_bits_h_resp_entry_tag !== g_io_resp_bits_h_resp_entry_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_tag, i_io_resp_bits_h_resp_entry_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_vmid) && i_io_resp_bits_h_resp_entry_vmid !== g_io_resp_bits_h_resp_entry_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_vmid, i_io_resp_bits_h_resp_entry_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_n) && i_io_resp_bits_h_resp_entry_n !== g_io_resp_bits_h_resp_entry_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_n, i_io_resp_bits_h_resp_entry_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_pbmt) && i_io_resp_bits_h_resp_entry_pbmt !== g_io_resp_bits_h_resp_entry_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_pbmt, i_io_resp_bits_h_resp_entry_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_ppn) && i_io_resp_bits_h_resp_entry_ppn !== g_io_resp_bits_h_resp_entry_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_ppn, i_io_resp_bits_h_resp_entry_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_d) && i_io_resp_bits_h_resp_entry_perm_d !== g_io_resp_bits_h_resp_entry_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_d, i_io_resp_bits_h_resp_entry_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_a) && i_io_resp_bits_h_resp_entry_perm_a !== g_io_resp_bits_h_resp_entry_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_a, i_io_resp_bits_h_resp_entry_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_g) && i_io_resp_bits_h_resp_entry_perm_g !== g_io_resp_bits_h_resp_entry_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_g, i_io_resp_bits_h_resp_entry_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_u) && i_io_resp_bits_h_resp_entry_perm_u !== g_io_resp_bits_h_resp_entry_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_u, i_io_resp_bits_h_resp_entry_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_x) && i_io_resp_bits_h_resp_entry_perm_x !== g_io_resp_bits_h_resp_entry_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_x, i_io_resp_bits_h_resp_entry_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_w) && i_io_resp_bits_h_resp_entry_perm_w !== g_io_resp_bits_h_resp_entry_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_w, i_io_resp_bits_h_resp_entry_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_perm_r) && i_io_resp_bits_h_resp_entry_perm_r !== g_io_resp_bits_h_resp_entry_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_perm_r, i_io_resp_bits_h_resp_entry_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_entry_level) && i_io_resp_bits_h_resp_entry_level !== g_io_resp_bits_h_resp_entry_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_entry_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_entry_level, i_io_resp_bits_h_resp_entry_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_gpf) && i_io_resp_bits_h_resp_gpf !== g_io_resp_bits_h_resp_gpf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_gpf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_gpf, i_io_resp_bits_h_resp_gpf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_h_resp_gaf) && i_io_resp_bits_h_resp_gaf !== g_io_resp_bits_h_resp_gaf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_h_resp_gaf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_h_resp_gaf, i_io_resp_bits_h_resp_gaf, cycle);
      end
      if (!$isunknown(g_io_llptw_valid) && i_io_llptw_valid !== g_io_llptw_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_llptw_valid: g=%0h i=%0h cycle=%0d", g_io_llptw_valid, i_io_llptw_valid, cycle);
      end
      if (!$isunknown(g_io_llptw_bits_req_info_vpn) && i_io_llptw_bits_req_info_vpn !== g_io_llptw_bits_req_info_vpn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_llptw_bits_req_info_vpn: g=%0h i=%0h cycle=%0d", g_io_llptw_bits_req_info_vpn, i_io_llptw_bits_req_info_vpn, cycle);
      end
      if (!$isunknown(g_io_llptw_bits_req_info_s2xlate) && i_io_llptw_bits_req_info_s2xlate !== g_io_llptw_bits_req_info_s2xlate) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_llptw_bits_req_info_s2xlate: g=%0h i=%0h cycle=%0d", g_io_llptw_bits_req_info_s2xlate, i_io_llptw_bits_req_info_s2xlate, cycle);
      end
      if (!$isunknown(g_io_llptw_bits_req_info_source) && i_io_llptw_bits_req_info_source !== g_io_llptw_bits_req_info_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_llptw_bits_req_info_source: g=%0h i=%0h cycle=%0d", g_io_llptw_bits_req_info_source, i_io_llptw_bits_req_info_source, cycle);
      end
      if (!$isunknown(g_io_hptw_req_valid) && i_io_hptw_req_valid !== g_io_hptw_req_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_hptw_req_valid: g=%0h i=%0h cycle=%0d", g_io_hptw_req_valid, i_io_hptw_req_valid, cycle);
      end
      if (!$isunknown(g_io_hptw_req_bits_source) && i_io_hptw_req_bits_source !== g_io_hptw_req_bits_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_hptw_req_bits_source: g=%0h i=%0h cycle=%0d", g_io_hptw_req_bits_source, i_io_hptw_req_bits_source, cycle);
      end
      if (!$isunknown(g_io_hptw_req_bits_gvpn) && i_io_hptw_req_bits_gvpn !== g_io_hptw_req_bits_gvpn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_hptw_req_bits_gvpn: g=%0h i=%0h cycle=%0d", g_io_hptw_req_bits_gvpn, i_io_hptw_req_bits_gvpn, cycle);
      end
      if (!$isunknown(g_io_mem_req_valid) && i_io_mem_req_valid !== g_io_mem_req_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_mem_req_valid: g=%0h i=%0h cycle=%0d", g_io_mem_req_valid, i_io_mem_req_valid, cycle);
      end
      if (!$isunknown(g_io_mem_req_bits_addr) && i_io_mem_req_bits_addr !== g_io_mem_req_bits_addr) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_mem_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_mem_req_bits_addr, i_io_mem_req_bits_addr, cycle);
      end
      if (!$isunknown(g_io_pmp_req_bits_addr) && i_io_pmp_req_bits_addr !== g_io_pmp_req_bits_addr) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_pmp_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr, cycle);
      end
      if (!$isunknown(g_io_refill_req_info_vpn) && i_io_refill_req_info_vpn !== g_io_refill_req_info_vpn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_req_info_vpn: g=%0h i=%0h cycle=%0d", g_io_refill_req_info_vpn, i_io_refill_req_info_vpn, cycle);
      end
      if (!$isunknown(g_io_refill_req_info_s2xlate) && i_io_refill_req_info_s2xlate !== g_io_refill_req_info_s2xlate) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_req_info_s2xlate: g=%0h i=%0h cycle=%0d", g_io_refill_req_info_s2xlate, i_io_refill_req_info_s2xlate, cycle);
      end
      if (!$isunknown(g_io_refill_req_info_source) && i_io_refill_req_info_source !== g_io_refill_req_info_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_req_info_source: g=%0h i=%0h cycle=%0d", g_io_refill_req_info_source, i_io_refill_req_info_source, cycle);
      end
      if (!$isunknown(g_io_refill_level) && i_io_refill_level !== g_io_refill_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_level: g=%0h i=%0h cycle=%0d", g_io_refill_level, i_io_refill_level, cycle);
      end
      if (!$isunknown(g_io_perf_0_value) && i_io_perf_0_value !== g_io_perf_0_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_0_value: g=%0h i=%0h cycle=%0d", g_io_perf_0_value, i_io_perf_0_value, cycle);
      end
      if (!$isunknown(g_io_perf_1_value) && i_io_perf_1_value !== g_io_perf_1_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_1_value: g=%0h i=%0h cycle=%0d", g_io_perf_1_value, i_io_perf_1_value, cycle);
      end
      if (!$isunknown(g_io_perf_2_value) && i_io_perf_2_value !== g_io_perf_2_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_2_value: g=%0h i=%0h cycle=%0d", g_io_perf_2_value, i_io_perf_2_value, cycle);
      end
      if (!$isunknown(g_io_perf_3_value) && i_io_perf_3_value !== g_io_perf_3_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_3_value: g=%0h i=%0h cycle=%0d", g_io_perf_3_value, i_io_perf_3_value, cycle);
      end
      if (!$isunknown(g_io_perf_4_value) && i_io_perf_4_value !== g_io_perf_4_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_4_value: g=%0h i=%0h cycle=%0d", g_io_perf_4_value, i_io_perf_4_value, cycle);
      end
      if (!$isunknown(g_io_perf_5_value) && i_io_perf_5_value !== g_io_perf_5_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_5_value: g=%0h i=%0h cycle=%0d", g_io_perf_5_value, i_io_perf_5_value, cycle);
      end
      if (!$isunknown(g_io_perf_6_value) && i_io_perf_6_value !== g_io_perf_6_value) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_perf_6_value: g=%0h i=%0h cycle=%0d", g_io_perf_6_value, i_io_perf_6_value, cycle);
      end
      if (!$isunknown(u_g.full_gvpn_reg) && u_i.u_core.full_gvpn_r !== u_g.full_gvpn_reg) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE full_gvpn mismatch: g=%0h i=%0h cycle=%0d",
          u_g.full_gvpn_reg, u_i.u_core.full_gvpn_r, cycle);
      end
    end
    $display("PTW_UT checks=%0d errors=%0d probe_full_gvpn=%0d", checks, errors, probe_errors);
    if (errors == 0 && probe_errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "PTW mismatch");
    $finish;
  end
endmodule
