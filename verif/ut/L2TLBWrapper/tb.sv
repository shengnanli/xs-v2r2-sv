// 自动生成：scripts/gen_l2tlbwrapper.py —— 勿手改
// L2TLBWrapper UT：golden L2TLBWrapper vs 手写 L2TLBWrapper_xs 双例化逐拍比对。
// 内层 L2TLB 两侧共用 golden 黑盒桩；只验证顶层互联映射 + perf 2 级流水等价。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic auto_out_a_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [2:0] auto_out_d_bits_size;
  logic [2:0] auto_out_d_bits_source;
  logic [255:0] auto_out_d_bits_data;
  logic io_tlb_0_req_0_valid;
  logic [37:0] io_tlb_0_req_0_bits_vpn;
  logic [1:0] io_tlb_0_req_0_bits_s2xlate;
  logic io_tlb_0_resp_ready;
  logic io_tlb_1_req_0_valid;
  logic [37:0] io_tlb_1_req_0_bits_vpn;
  logic [1:0] io_tlb_1_req_0_bits_s2xlate;
  logic io_sfence_valid;
  logic io_sfence_bits_rs1;
  logic io_sfence_bits_rs2;
  logic [49:0] io_sfence_bits_addr;
  logic [15:0] io_sfence_bits_id;
  logic io_sfence_bits_hv;
  logic io_sfence_bits_hg;
  logic io_wfi_wfiReq;
  logic [3:0] io_csr_tlb_satp_mode;
  logic [15:0] io_csr_tlb_satp_asid;
  logic [43:0] io_csr_tlb_satp_ppn;
  logic io_csr_tlb_satp_changed;
  logic [3:0] io_csr_tlb_vsatp_mode;
  logic [15:0] io_csr_tlb_vsatp_asid;
  logic [43:0] io_csr_tlb_vsatp_ppn;
  logic io_csr_tlb_vsatp_changed;
  logic [3:0] io_csr_tlb_hgatp_mode;
  logic [15:0] io_csr_tlb_hgatp_vmid;
  logic [43:0] io_csr_tlb_hgatp_ppn;
  logic io_csr_tlb_hgatp_changed;
  logic io_csr_tlb_priv_mxr;
  logic io_csr_tlb_priv_virt;
  logic io_csr_tlb_mPBMTE;
  logic io_csr_tlb_hPBMTE;
  logic io_csr_distribute_csr_w_valid;
  logic [11:0] io_csr_distribute_csr_w_bits_addr;
  logic [63:0] io_csr_distribute_csr_w_bits_data;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [1:0] boreChildrenBd_bore_be;
  logic [3:0] boreChildrenBd_bore_addr;
  logic [199:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [3:0] boreChildrenBd_bore_addr_rd;
  logic [5:0] boreChildrenBd_bore_1_array;
  logic boreChildrenBd_bore_1_all;
  logic boreChildrenBd_bore_1_req;
  logic boreChildrenBd_bore_1_writeen;
  logic [1:0] boreChildrenBd_bore_1_be;
  logic [5:0] boreChildrenBd_bore_1_addr;
  logic [227:0] boreChildrenBd_bore_1_indata;
  logic boreChildrenBd_bore_1_readen;
  logic [5:0] boreChildrenBd_bore_1_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic sigFromSrams_bore_4_ram_hold;
  logic sigFromSrams_bore_4_ram_bypass;
  logic sigFromSrams_bore_4_ram_bp_clken;
  logic sigFromSrams_bore_4_ram_aux_clk;
  logic sigFromSrams_bore_4_ram_aux_ckbp;
  logic sigFromSrams_bore_4_ram_mcp_hold;
  logic sigFromSrams_bore_4_cgen;
  logic sigFromSrams_bore_5_ram_hold;
  logic sigFromSrams_bore_5_ram_bypass;
  logic sigFromSrams_bore_5_ram_bp_clken;
  logic sigFromSrams_bore_5_ram_aux_clk;
  logic sigFromSrams_bore_5_ram_aux_ckbp;
  logic sigFromSrams_bore_5_ram_mcp_hold;
  logic sigFromSrams_bore_5_cgen;
  logic sigFromSrams_bore_6_ram_hold;
  logic sigFromSrams_bore_6_ram_bypass;
  logic sigFromSrams_bore_6_ram_bp_clken;
  logic sigFromSrams_bore_6_ram_aux_clk;
  logic sigFromSrams_bore_6_ram_aux_ckbp;
  logic sigFromSrams_bore_6_ram_mcp_hold;
  logic sigFromSrams_bore_6_cgen;
  logic sigFromSrams_bore_7_ram_hold;
  logic sigFromSrams_bore_7_ram_bypass;
  logic sigFromSrams_bore_7_ram_bp_clken;
  logic sigFromSrams_bore_7_ram_aux_clk;
  logic sigFromSrams_bore_7_ram_aux_ckbp;
  logic sigFromSrams_bore_7_ram_mcp_hold;
  logic sigFromSrams_bore_7_cgen;
  logic sigFromSrams_bore_8_ram_hold;
  logic sigFromSrams_bore_8_ram_bypass;
  logic sigFromSrams_bore_8_ram_bp_clken;
  logic sigFromSrams_bore_8_ram_aux_clk;
  logic sigFromSrams_bore_8_ram_aux_ckbp;
  logic sigFromSrams_bore_8_ram_mcp_hold;
  logic sigFromSrams_bore_8_cgen;
  logic sigFromSrams_bore_9_ram_hold;
  logic sigFromSrams_bore_9_ram_bypass;
  logic sigFromSrams_bore_9_ram_bp_clken;
  logic sigFromSrams_bore_9_ram_aux_clk;
  logic sigFromSrams_bore_9_ram_aux_ckbp;
  logic sigFromSrams_bore_9_ram_mcp_hold;
  logic sigFromSrams_bore_9_cgen;
  logic sigFromSrams_bore_10_ram_hold;
  logic sigFromSrams_bore_10_ram_bypass;
  logic sigFromSrams_bore_10_ram_bp_clken;
  logic sigFromSrams_bore_10_ram_aux_clk;
  logic sigFromSrams_bore_10_ram_aux_ckbp;
  logic sigFromSrams_bore_10_ram_mcp_hold;
  logic sigFromSrams_bore_10_cgen;
  logic sigFromSrams_bore_11_ram_hold;
  logic sigFromSrams_bore_11_ram_bypass;
  logic sigFromSrams_bore_11_ram_bp_clken;
  logic sigFromSrams_bore_11_ram_aux_clk;
  logic sigFromSrams_bore_11_ram_aux_ckbp;
  logic sigFromSrams_bore_11_ram_mcp_hold;
  logic sigFromSrams_bore_11_cgen;
  logic cg_bore_cgen;
  wire g_auto_out_a_valid;
  wire i_auto_out_a_valid;
  wire [2:0] g_auto_out_a_bits_source;
  wire [2:0] i_auto_out_a_bits_source;
  wire [47:0] g_auto_out_a_bits_address;
  wire [47:0] i_auto_out_a_bits_address;
  wire g_io_tlb_0_req_0_ready;
  wire i_io_tlb_0_req_0_ready;
  wire g_io_tlb_0_resp_valid;
  wire i_io_tlb_0_resp_valid;
  wire [1:0] g_io_tlb_0_resp_bits_s2xlate;
  wire [1:0] i_io_tlb_0_resp_bits_s2xlate;
  wire [34:0] g_io_tlb_0_resp_bits_s1_entry_tag;
  wire [34:0] i_io_tlb_0_resp_bits_s1_entry_tag;
  wire [15:0] g_io_tlb_0_resp_bits_s1_entry_asid;
  wire [15:0] i_io_tlb_0_resp_bits_s1_entry_asid;
  wire [13:0] g_io_tlb_0_resp_bits_s1_entry_vmid;
  wire [13:0] i_io_tlb_0_resp_bits_s1_entry_vmid;
  wire g_io_tlb_0_resp_bits_s1_entry_n;
  wire i_io_tlb_0_resp_bits_s1_entry_n;
  wire [1:0] g_io_tlb_0_resp_bits_s1_entry_pbmt;
  wire [1:0] i_io_tlb_0_resp_bits_s1_entry_pbmt;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_d;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_d;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_a;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_a;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_g;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_g;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_u;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_u;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_x;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_x;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_w;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_w;
  wire g_io_tlb_0_resp_bits_s1_entry_perm_r;
  wire i_io_tlb_0_resp_bits_s1_entry_perm_r;
  wire [1:0] g_io_tlb_0_resp_bits_s1_entry_level;
  wire [1:0] i_io_tlb_0_resp_bits_s1_entry_level;
  wire g_io_tlb_0_resp_bits_s1_entry_v;
  wire i_io_tlb_0_resp_bits_s1_entry_v;
  wire [40:0] g_io_tlb_0_resp_bits_s1_entry_ppn;
  wire [40:0] i_io_tlb_0_resp_bits_s1_entry_ppn;
  wire [2:0] g_io_tlb_0_resp_bits_s1_addr_low;
  wire [2:0] i_io_tlb_0_resp_bits_s1_addr_low;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_0;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_0;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_1;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_1;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_2;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_2;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_3;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_3;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_4;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_4;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_5;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_5;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_6;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_6;
  wire [2:0] g_io_tlb_0_resp_bits_s1_ppn_low_7;
  wire [2:0] i_io_tlb_0_resp_bits_s1_ppn_low_7;
  wire g_io_tlb_0_resp_bits_s1_valididx_0;
  wire i_io_tlb_0_resp_bits_s1_valididx_0;
  wire g_io_tlb_0_resp_bits_s1_valididx_1;
  wire i_io_tlb_0_resp_bits_s1_valididx_1;
  wire g_io_tlb_0_resp_bits_s1_valididx_2;
  wire i_io_tlb_0_resp_bits_s1_valididx_2;
  wire g_io_tlb_0_resp_bits_s1_valididx_3;
  wire i_io_tlb_0_resp_bits_s1_valididx_3;
  wire g_io_tlb_0_resp_bits_s1_valididx_4;
  wire i_io_tlb_0_resp_bits_s1_valididx_4;
  wire g_io_tlb_0_resp_bits_s1_valididx_5;
  wire i_io_tlb_0_resp_bits_s1_valididx_5;
  wire g_io_tlb_0_resp_bits_s1_valididx_6;
  wire i_io_tlb_0_resp_bits_s1_valididx_6;
  wire g_io_tlb_0_resp_bits_s1_valididx_7;
  wire i_io_tlb_0_resp_bits_s1_valididx_7;
  wire g_io_tlb_0_resp_bits_s1_pteidx_0;
  wire i_io_tlb_0_resp_bits_s1_pteidx_0;
  wire g_io_tlb_0_resp_bits_s1_pteidx_1;
  wire i_io_tlb_0_resp_bits_s1_pteidx_1;
  wire g_io_tlb_0_resp_bits_s1_pteidx_2;
  wire i_io_tlb_0_resp_bits_s1_pteidx_2;
  wire g_io_tlb_0_resp_bits_s1_pteidx_3;
  wire i_io_tlb_0_resp_bits_s1_pteidx_3;
  wire g_io_tlb_0_resp_bits_s1_pteidx_4;
  wire i_io_tlb_0_resp_bits_s1_pteidx_4;
  wire g_io_tlb_0_resp_bits_s1_pteidx_5;
  wire i_io_tlb_0_resp_bits_s1_pteidx_5;
  wire g_io_tlb_0_resp_bits_s1_pteidx_6;
  wire i_io_tlb_0_resp_bits_s1_pteidx_6;
  wire g_io_tlb_0_resp_bits_s1_pteidx_7;
  wire i_io_tlb_0_resp_bits_s1_pteidx_7;
  wire g_io_tlb_0_resp_bits_s1_pf;
  wire i_io_tlb_0_resp_bits_s1_pf;
  wire g_io_tlb_0_resp_bits_s1_af;
  wire i_io_tlb_0_resp_bits_s1_af;
  wire [37:0] g_io_tlb_0_resp_bits_s2_entry_tag;
  wire [37:0] i_io_tlb_0_resp_bits_s2_entry_tag;
  wire [13:0] g_io_tlb_0_resp_bits_s2_entry_vmid;
  wire [13:0] i_io_tlb_0_resp_bits_s2_entry_vmid;
  wire g_io_tlb_0_resp_bits_s2_entry_n;
  wire i_io_tlb_0_resp_bits_s2_entry_n;
  wire [1:0] g_io_tlb_0_resp_bits_s2_entry_pbmt;
  wire [1:0] i_io_tlb_0_resp_bits_s2_entry_pbmt;
  wire [37:0] g_io_tlb_0_resp_bits_s2_entry_ppn;
  wire [37:0] i_io_tlb_0_resp_bits_s2_entry_ppn;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_d;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_d;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_a;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_a;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_g;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_g;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_u;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_u;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_x;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_x;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_w;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_w;
  wire g_io_tlb_0_resp_bits_s2_entry_perm_r;
  wire i_io_tlb_0_resp_bits_s2_entry_perm_r;
  wire [1:0] g_io_tlb_0_resp_bits_s2_entry_level;
  wire [1:0] i_io_tlb_0_resp_bits_s2_entry_level;
  wire g_io_tlb_0_resp_bits_s2_gpf;
  wire i_io_tlb_0_resp_bits_s2_gpf;
  wire g_io_tlb_0_resp_bits_s2_gaf;
  wire i_io_tlb_0_resp_bits_s2_gaf;
  wire g_io_tlb_1_req_0_ready;
  wire i_io_tlb_1_req_0_ready;
  wire g_io_tlb_1_resp_valid;
  wire i_io_tlb_1_resp_valid;
  wire [1:0] g_io_tlb_1_resp_bits_s2xlate;
  wire [1:0] i_io_tlb_1_resp_bits_s2xlate;
  wire [34:0] g_io_tlb_1_resp_bits_s1_entry_tag;
  wire [34:0] i_io_tlb_1_resp_bits_s1_entry_tag;
  wire [15:0] g_io_tlb_1_resp_bits_s1_entry_asid;
  wire [15:0] i_io_tlb_1_resp_bits_s1_entry_asid;
  wire [13:0] g_io_tlb_1_resp_bits_s1_entry_vmid;
  wire [13:0] i_io_tlb_1_resp_bits_s1_entry_vmid;
  wire g_io_tlb_1_resp_bits_s1_entry_n;
  wire i_io_tlb_1_resp_bits_s1_entry_n;
  wire [1:0] g_io_tlb_1_resp_bits_s1_entry_pbmt;
  wire [1:0] i_io_tlb_1_resp_bits_s1_entry_pbmt;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_d;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_d;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_a;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_a;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_g;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_g;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_u;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_u;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_x;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_x;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_w;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_w;
  wire g_io_tlb_1_resp_bits_s1_entry_perm_r;
  wire i_io_tlb_1_resp_bits_s1_entry_perm_r;
  wire [1:0] g_io_tlb_1_resp_bits_s1_entry_level;
  wire [1:0] i_io_tlb_1_resp_bits_s1_entry_level;
  wire g_io_tlb_1_resp_bits_s1_entry_v;
  wire i_io_tlb_1_resp_bits_s1_entry_v;
  wire [40:0] g_io_tlb_1_resp_bits_s1_entry_ppn;
  wire [40:0] i_io_tlb_1_resp_bits_s1_entry_ppn;
  wire [2:0] g_io_tlb_1_resp_bits_s1_addr_low;
  wire [2:0] i_io_tlb_1_resp_bits_s1_addr_low;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_0;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_0;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_1;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_1;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_2;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_2;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_3;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_3;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_4;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_4;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_5;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_5;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_6;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_6;
  wire [2:0] g_io_tlb_1_resp_bits_s1_ppn_low_7;
  wire [2:0] i_io_tlb_1_resp_bits_s1_ppn_low_7;
  wire g_io_tlb_1_resp_bits_s1_valididx_0;
  wire i_io_tlb_1_resp_bits_s1_valididx_0;
  wire g_io_tlb_1_resp_bits_s1_valididx_1;
  wire i_io_tlb_1_resp_bits_s1_valididx_1;
  wire g_io_tlb_1_resp_bits_s1_valididx_2;
  wire i_io_tlb_1_resp_bits_s1_valididx_2;
  wire g_io_tlb_1_resp_bits_s1_valididx_3;
  wire i_io_tlb_1_resp_bits_s1_valididx_3;
  wire g_io_tlb_1_resp_bits_s1_valididx_4;
  wire i_io_tlb_1_resp_bits_s1_valididx_4;
  wire g_io_tlb_1_resp_bits_s1_valididx_5;
  wire i_io_tlb_1_resp_bits_s1_valididx_5;
  wire g_io_tlb_1_resp_bits_s1_valididx_6;
  wire i_io_tlb_1_resp_bits_s1_valididx_6;
  wire g_io_tlb_1_resp_bits_s1_valididx_7;
  wire i_io_tlb_1_resp_bits_s1_valididx_7;
  wire g_io_tlb_1_resp_bits_s1_pteidx_0;
  wire i_io_tlb_1_resp_bits_s1_pteidx_0;
  wire g_io_tlb_1_resp_bits_s1_pteidx_1;
  wire i_io_tlb_1_resp_bits_s1_pteidx_1;
  wire g_io_tlb_1_resp_bits_s1_pteidx_2;
  wire i_io_tlb_1_resp_bits_s1_pteidx_2;
  wire g_io_tlb_1_resp_bits_s1_pteidx_3;
  wire i_io_tlb_1_resp_bits_s1_pteidx_3;
  wire g_io_tlb_1_resp_bits_s1_pteidx_4;
  wire i_io_tlb_1_resp_bits_s1_pteidx_4;
  wire g_io_tlb_1_resp_bits_s1_pteidx_5;
  wire i_io_tlb_1_resp_bits_s1_pteidx_5;
  wire g_io_tlb_1_resp_bits_s1_pteidx_6;
  wire i_io_tlb_1_resp_bits_s1_pteidx_6;
  wire g_io_tlb_1_resp_bits_s1_pteidx_7;
  wire i_io_tlb_1_resp_bits_s1_pteidx_7;
  wire g_io_tlb_1_resp_bits_s1_pf;
  wire i_io_tlb_1_resp_bits_s1_pf;
  wire g_io_tlb_1_resp_bits_s1_af;
  wire i_io_tlb_1_resp_bits_s1_af;
  wire [37:0] g_io_tlb_1_resp_bits_s2_entry_tag;
  wire [37:0] i_io_tlb_1_resp_bits_s2_entry_tag;
  wire [13:0] g_io_tlb_1_resp_bits_s2_entry_vmid;
  wire [13:0] i_io_tlb_1_resp_bits_s2_entry_vmid;
  wire g_io_tlb_1_resp_bits_s2_entry_n;
  wire i_io_tlb_1_resp_bits_s2_entry_n;
  wire [1:0] g_io_tlb_1_resp_bits_s2_entry_pbmt;
  wire [1:0] i_io_tlb_1_resp_bits_s2_entry_pbmt;
  wire [37:0] g_io_tlb_1_resp_bits_s2_entry_ppn;
  wire [37:0] i_io_tlb_1_resp_bits_s2_entry_ppn;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_d;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_d;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_a;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_a;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_g;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_g;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_u;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_u;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_x;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_x;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_w;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_w;
  wire g_io_tlb_1_resp_bits_s2_entry_perm_r;
  wire i_io_tlb_1_resp_bits_s2_entry_perm_r;
  wire [1:0] g_io_tlb_1_resp_bits_s2_entry_level;
  wire [1:0] i_io_tlb_1_resp_bits_s2_entry_level;
  wire g_io_tlb_1_resp_bits_s2_gpf;
  wire i_io_tlb_1_resp_bits_s2_gpf;
  wire g_io_tlb_1_resp_bits_s2_gaf;
  wire i_io_tlb_1_resp_bits_s2_gaf;
  wire g_io_wfi_wfiSafe;
  wire i_io_wfi_wfiSafe;
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
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;
  wire [5:0] g_io_perf_8_value;
  wire [5:0] i_io_perf_8_value;
  wire [5:0] g_io_perf_9_value;
  wire [5:0] i_io_perf_9_value;
  wire [5:0] g_io_perf_10_value;
  wire [5:0] i_io_perf_10_value;
  wire [5:0] g_io_perf_11_value;
  wire [5:0] i_io_perf_11_value;
  wire [5:0] g_io_perf_12_value;
  wire [5:0] i_io_perf_12_value;
  wire [5:0] g_io_perf_13_value;
  wire [5:0] i_io_perf_13_value;
  wire [5:0] g_io_perf_14_value;
  wire [5:0] i_io_perf_14_value;
  wire [5:0] g_io_perf_15_value;
  wire [5:0] i_io_perf_15_value;
  wire [5:0] g_io_perf_16_value;
  wire [5:0] i_io_perf_16_value;
  wire [5:0] g_io_perf_17_value;
  wire [5:0] i_io_perf_17_value;
  wire [5:0] g_io_perf_18_value;
  wire [5:0] i_io_perf_18_value;
  wire g_boreChildrenBd_bore_ack;
  wire i_boreChildrenBd_bore_ack;
  wire [199:0] g_boreChildrenBd_bore_outdata;
  wire [199:0] i_boreChildrenBd_bore_outdata;
  wire g_boreChildrenBd_bore_1_ack;
  wire i_boreChildrenBd_bore_1_ack;
  wire [227:0] g_boreChildrenBd_bore_1_outdata;
  wire [227:0] i_boreChildrenBd_bore_1_outdata;
  L2TLBWrapper    u_g (.clock(clk), .reset(rst), .auto_out_a_ready(auto_out_a_ready), .auto_out_d_valid(auto_out_d_valid), .auto_out_d_bits_opcode(auto_out_d_bits_opcode), .auto_out_d_bits_size(auto_out_d_bits_size), .auto_out_d_bits_source(auto_out_d_bits_source), .auto_out_d_bits_data(auto_out_d_bits_data), .io_tlb_0_req_0_valid(io_tlb_0_req_0_valid), .io_tlb_0_req_0_bits_vpn(io_tlb_0_req_0_bits_vpn), .io_tlb_0_req_0_bits_s2xlate(io_tlb_0_req_0_bits_s2xlate), .io_tlb_0_resp_ready(io_tlb_0_resp_ready), .io_tlb_1_req_0_valid(io_tlb_1_req_0_valid), .io_tlb_1_req_0_bits_vpn(io_tlb_1_req_0_bits_vpn), .io_tlb_1_req_0_bits_s2xlate(io_tlb_1_req_0_bits_s2xlate), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_wfi_wfiReq(io_wfi_wfiReq), .io_csr_tlb_satp_mode(io_csr_tlb_satp_mode), .io_csr_tlb_satp_asid(io_csr_tlb_satp_asid), .io_csr_tlb_satp_ppn(io_csr_tlb_satp_ppn), .io_csr_tlb_satp_changed(io_csr_tlb_satp_changed), .io_csr_tlb_vsatp_mode(io_csr_tlb_vsatp_mode), .io_csr_tlb_vsatp_asid(io_csr_tlb_vsatp_asid), .io_csr_tlb_vsatp_ppn(io_csr_tlb_vsatp_ppn), .io_csr_tlb_vsatp_changed(io_csr_tlb_vsatp_changed), .io_csr_tlb_hgatp_mode(io_csr_tlb_hgatp_mode), .io_csr_tlb_hgatp_vmid(io_csr_tlb_hgatp_vmid), .io_csr_tlb_hgatp_ppn(io_csr_tlb_hgatp_ppn), .io_csr_tlb_hgatp_changed(io_csr_tlb_hgatp_changed), .io_csr_tlb_priv_mxr(io_csr_tlb_priv_mxr), .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt), .io_csr_tlb_mPBMTE(io_csr_tlb_mPBMTE), .io_csr_tlb_hPBMTE(io_csr_tlb_hPBMTE), .io_csr_distribute_csr_w_valid(io_csr_distribute_csr_w_valid), .io_csr_distribute_csr_w_bits_addr(io_csr_distribute_csr_w_bits_addr), .io_csr_distribute_csr_w_bits_data(io_csr_distribute_csr_w_bits_data), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .cg_bore_cgen(cg_bore_cgen), .auto_out_a_valid(g_auto_out_a_valid), .auto_out_a_bits_source(g_auto_out_a_bits_source), .auto_out_a_bits_address(g_auto_out_a_bits_address), .io_tlb_0_req_0_ready(g_io_tlb_0_req_0_ready), .io_tlb_0_resp_valid(g_io_tlb_0_resp_valid), .io_tlb_0_resp_bits_s2xlate(g_io_tlb_0_resp_bits_s2xlate), .io_tlb_0_resp_bits_s1_entry_tag(g_io_tlb_0_resp_bits_s1_entry_tag), .io_tlb_0_resp_bits_s1_entry_asid(g_io_tlb_0_resp_bits_s1_entry_asid), .io_tlb_0_resp_bits_s1_entry_vmid(g_io_tlb_0_resp_bits_s1_entry_vmid), .io_tlb_0_resp_bits_s1_entry_n(g_io_tlb_0_resp_bits_s1_entry_n), .io_tlb_0_resp_bits_s1_entry_pbmt(g_io_tlb_0_resp_bits_s1_entry_pbmt), .io_tlb_0_resp_bits_s1_entry_perm_d(g_io_tlb_0_resp_bits_s1_entry_perm_d), .io_tlb_0_resp_bits_s1_entry_perm_a(g_io_tlb_0_resp_bits_s1_entry_perm_a), .io_tlb_0_resp_bits_s1_entry_perm_g(g_io_tlb_0_resp_bits_s1_entry_perm_g), .io_tlb_0_resp_bits_s1_entry_perm_u(g_io_tlb_0_resp_bits_s1_entry_perm_u), .io_tlb_0_resp_bits_s1_entry_perm_x(g_io_tlb_0_resp_bits_s1_entry_perm_x), .io_tlb_0_resp_bits_s1_entry_perm_w(g_io_tlb_0_resp_bits_s1_entry_perm_w), .io_tlb_0_resp_bits_s1_entry_perm_r(g_io_tlb_0_resp_bits_s1_entry_perm_r), .io_tlb_0_resp_bits_s1_entry_level(g_io_tlb_0_resp_bits_s1_entry_level), .io_tlb_0_resp_bits_s1_entry_v(g_io_tlb_0_resp_bits_s1_entry_v), .io_tlb_0_resp_bits_s1_entry_ppn(g_io_tlb_0_resp_bits_s1_entry_ppn), .io_tlb_0_resp_bits_s1_addr_low(g_io_tlb_0_resp_bits_s1_addr_low), .io_tlb_0_resp_bits_s1_ppn_low_0(g_io_tlb_0_resp_bits_s1_ppn_low_0), .io_tlb_0_resp_bits_s1_ppn_low_1(g_io_tlb_0_resp_bits_s1_ppn_low_1), .io_tlb_0_resp_bits_s1_ppn_low_2(g_io_tlb_0_resp_bits_s1_ppn_low_2), .io_tlb_0_resp_bits_s1_ppn_low_3(g_io_tlb_0_resp_bits_s1_ppn_low_3), .io_tlb_0_resp_bits_s1_ppn_low_4(g_io_tlb_0_resp_bits_s1_ppn_low_4), .io_tlb_0_resp_bits_s1_ppn_low_5(g_io_tlb_0_resp_bits_s1_ppn_low_5), .io_tlb_0_resp_bits_s1_ppn_low_6(g_io_tlb_0_resp_bits_s1_ppn_low_6), .io_tlb_0_resp_bits_s1_ppn_low_7(g_io_tlb_0_resp_bits_s1_ppn_low_7), .io_tlb_0_resp_bits_s1_valididx_0(g_io_tlb_0_resp_bits_s1_valididx_0), .io_tlb_0_resp_bits_s1_valididx_1(g_io_tlb_0_resp_bits_s1_valididx_1), .io_tlb_0_resp_bits_s1_valididx_2(g_io_tlb_0_resp_bits_s1_valididx_2), .io_tlb_0_resp_bits_s1_valididx_3(g_io_tlb_0_resp_bits_s1_valididx_3), .io_tlb_0_resp_bits_s1_valididx_4(g_io_tlb_0_resp_bits_s1_valididx_4), .io_tlb_0_resp_bits_s1_valididx_5(g_io_tlb_0_resp_bits_s1_valididx_5), .io_tlb_0_resp_bits_s1_valididx_6(g_io_tlb_0_resp_bits_s1_valididx_6), .io_tlb_0_resp_bits_s1_valididx_7(g_io_tlb_0_resp_bits_s1_valididx_7), .io_tlb_0_resp_bits_s1_pteidx_0(g_io_tlb_0_resp_bits_s1_pteidx_0), .io_tlb_0_resp_bits_s1_pteidx_1(g_io_tlb_0_resp_bits_s1_pteidx_1), .io_tlb_0_resp_bits_s1_pteidx_2(g_io_tlb_0_resp_bits_s1_pteidx_2), .io_tlb_0_resp_bits_s1_pteidx_3(g_io_tlb_0_resp_bits_s1_pteidx_3), .io_tlb_0_resp_bits_s1_pteidx_4(g_io_tlb_0_resp_bits_s1_pteidx_4), .io_tlb_0_resp_bits_s1_pteidx_5(g_io_tlb_0_resp_bits_s1_pteidx_5), .io_tlb_0_resp_bits_s1_pteidx_6(g_io_tlb_0_resp_bits_s1_pteidx_6), .io_tlb_0_resp_bits_s1_pteidx_7(g_io_tlb_0_resp_bits_s1_pteidx_7), .io_tlb_0_resp_bits_s1_pf(g_io_tlb_0_resp_bits_s1_pf), .io_tlb_0_resp_bits_s1_af(g_io_tlb_0_resp_bits_s1_af), .io_tlb_0_resp_bits_s2_entry_tag(g_io_tlb_0_resp_bits_s2_entry_tag), .io_tlb_0_resp_bits_s2_entry_vmid(g_io_tlb_0_resp_bits_s2_entry_vmid), .io_tlb_0_resp_bits_s2_entry_n(g_io_tlb_0_resp_bits_s2_entry_n), .io_tlb_0_resp_bits_s2_entry_pbmt(g_io_tlb_0_resp_bits_s2_entry_pbmt), .io_tlb_0_resp_bits_s2_entry_ppn(g_io_tlb_0_resp_bits_s2_entry_ppn), .io_tlb_0_resp_bits_s2_entry_perm_d(g_io_tlb_0_resp_bits_s2_entry_perm_d), .io_tlb_0_resp_bits_s2_entry_perm_a(g_io_tlb_0_resp_bits_s2_entry_perm_a), .io_tlb_0_resp_bits_s2_entry_perm_g(g_io_tlb_0_resp_bits_s2_entry_perm_g), .io_tlb_0_resp_bits_s2_entry_perm_u(g_io_tlb_0_resp_bits_s2_entry_perm_u), .io_tlb_0_resp_bits_s2_entry_perm_x(g_io_tlb_0_resp_bits_s2_entry_perm_x), .io_tlb_0_resp_bits_s2_entry_perm_w(g_io_tlb_0_resp_bits_s2_entry_perm_w), .io_tlb_0_resp_bits_s2_entry_perm_r(g_io_tlb_0_resp_bits_s2_entry_perm_r), .io_tlb_0_resp_bits_s2_entry_level(g_io_tlb_0_resp_bits_s2_entry_level), .io_tlb_0_resp_bits_s2_gpf(g_io_tlb_0_resp_bits_s2_gpf), .io_tlb_0_resp_bits_s2_gaf(g_io_tlb_0_resp_bits_s2_gaf), .io_tlb_1_req_0_ready(g_io_tlb_1_req_0_ready), .io_tlb_1_resp_valid(g_io_tlb_1_resp_valid), .io_tlb_1_resp_bits_s2xlate(g_io_tlb_1_resp_bits_s2xlate), .io_tlb_1_resp_bits_s1_entry_tag(g_io_tlb_1_resp_bits_s1_entry_tag), .io_tlb_1_resp_bits_s1_entry_asid(g_io_tlb_1_resp_bits_s1_entry_asid), .io_tlb_1_resp_bits_s1_entry_vmid(g_io_tlb_1_resp_bits_s1_entry_vmid), .io_tlb_1_resp_bits_s1_entry_n(g_io_tlb_1_resp_bits_s1_entry_n), .io_tlb_1_resp_bits_s1_entry_pbmt(g_io_tlb_1_resp_bits_s1_entry_pbmt), .io_tlb_1_resp_bits_s1_entry_perm_d(g_io_tlb_1_resp_bits_s1_entry_perm_d), .io_tlb_1_resp_bits_s1_entry_perm_a(g_io_tlb_1_resp_bits_s1_entry_perm_a), .io_tlb_1_resp_bits_s1_entry_perm_g(g_io_tlb_1_resp_bits_s1_entry_perm_g), .io_tlb_1_resp_bits_s1_entry_perm_u(g_io_tlb_1_resp_bits_s1_entry_perm_u), .io_tlb_1_resp_bits_s1_entry_perm_x(g_io_tlb_1_resp_bits_s1_entry_perm_x), .io_tlb_1_resp_bits_s1_entry_perm_w(g_io_tlb_1_resp_bits_s1_entry_perm_w), .io_tlb_1_resp_bits_s1_entry_perm_r(g_io_tlb_1_resp_bits_s1_entry_perm_r), .io_tlb_1_resp_bits_s1_entry_level(g_io_tlb_1_resp_bits_s1_entry_level), .io_tlb_1_resp_bits_s1_entry_v(g_io_tlb_1_resp_bits_s1_entry_v), .io_tlb_1_resp_bits_s1_entry_ppn(g_io_tlb_1_resp_bits_s1_entry_ppn), .io_tlb_1_resp_bits_s1_addr_low(g_io_tlb_1_resp_bits_s1_addr_low), .io_tlb_1_resp_bits_s1_ppn_low_0(g_io_tlb_1_resp_bits_s1_ppn_low_0), .io_tlb_1_resp_bits_s1_ppn_low_1(g_io_tlb_1_resp_bits_s1_ppn_low_1), .io_tlb_1_resp_bits_s1_ppn_low_2(g_io_tlb_1_resp_bits_s1_ppn_low_2), .io_tlb_1_resp_bits_s1_ppn_low_3(g_io_tlb_1_resp_bits_s1_ppn_low_3), .io_tlb_1_resp_bits_s1_ppn_low_4(g_io_tlb_1_resp_bits_s1_ppn_low_4), .io_tlb_1_resp_bits_s1_ppn_low_5(g_io_tlb_1_resp_bits_s1_ppn_low_5), .io_tlb_1_resp_bits_s1_ppn_low_6(g_io_tlb_1_resp_bits_s1_ppn_low_6), .io_tlb_1_resp_bits_s1_ppn_low_7(g_io_tlb_1_resp_bits_s1_ppn_low_7), .io_tlb_1_resp_bits_s1_valididx_0(g_io_tlb_1_resp_bits_s1_valididx_0), .io_tlb_1_resp_bits_s1_valididx_1(g_io_tlb_1_resp_bits_s1_valididx_1), .io_tlb_1_resp_bits_s1_valididx_2(g_io_tlb_1_resp_bits_s1_valididx_2), .io_tlb_1_resp_bits_s1_valididx_3(g_io_tlb_1_resp_bits_s1_valididx_3), .io_tlb_1_resp_bits_s1_valididx_4(g_io_tlb_1_resp_bits_s1_valididx_4), .io_tlb_1_resp_bits_s1_valididx_5(g_io_tlb_1_resp_bits_s1_valididx_5), .io_tlb_1_resp_bits_s1_valididx_6(g_io_tlb_1_resp_bits_s1_valididx_6), .io_tlb_1_resp_bits_s1_valididx_7(g_io_tlb_1_resp_bits_s1_valididx_7), .io_tlb_1_resp_bits_s1_pteidx_0(g_io_tlb_1_resp_bits_s1_pteidx_0), .io_tlb_1_resp_bits_s1_pteidx_1(g_io_tlb_1_resp_bits_s1_pteidx_1), .io_tlb_1_resp_bits_s1_pteidx_2(g_io_tlb_1_resp_bits_s1_pteidx_2), .io_tlb_1_resp_bits_s1_pteidx_3(g_io_tlb_1_resp_bits_s1_pteidx_3), .io_tlb_1_resp_bits_s1_pteidx_4(g_io_tlb_1_resp_bits_s1_pteidx_4), .io_tlb_1_resp_bits_s1_pteidx_5(g_io_tlb_1_resp_bits_s1_pteidx_5), .io_tlb_1_resp_bits_s1_pteidx_6(g_io_tlb_1_resp_bits_s1_pteidx_6), .io_tlb_1_resp_bits_s1_pteidx_7(g_io_tlb_1_resp_bits_s1_pteidx_7), .io_tlb_1_resp_bits_s1_pf(g_io_tlb_1_resp_bits_s1_pf), .io_tlb_1_resp_bits_s1_af(g_io_tlb_1_resp_bits_s1_af), .io_tlb_1_resp_bits_s2_entry_tag(g_io_tlb_1_resp_bits_s2_entry_tag), .io_tlb_1_resp_bits_s2_entry_vmid(g_io_tlb_1_resp_bits_s2_entry_vmid), .io_tlb_1_resp_bits_s2_entry_n(g_io_tlb_1_resp_bits_s2_entry_n), .io_tlb_1_resp_bits_s2_entry_pbmt(g_io_tlb_1_resp_bits_s2_entry_pbmt), .io_tlb_1_resp_bits_s2_entry_ppn(g_io_tlb_1_resp_bits_s2_entry_ppn), .io_tlb_1_resp_bits_s2_entry_perm_d(g_io_tlb_1_resp_bits_s2_entry_perm_d), .io_tlb_1_resp_bits_s2_entry_perm_a(g_io_tlb_1_resp_bits_s2_entry_perm_a), .io_tlb_1_resp_bits_s2_entry_perm_g(g_io_tlb_1_resp_bits_s2_entry_perm_g), .io_tlb_1_resp_bits_s2_entry_perm_u(g_io_tlb_1_resp_bits_s2_entry_perm_u), .io_tlb_1_resp_bits_s2_entry_perm_x(g_io_tlb_1_resp_bits_s2_entry_perm_x), .io_tlb_1_resp_bits_s2_entry_perm_w(g_io_tlb_1_resp_bits_s2_entry_perm_w), .io_tlb_1_resp_bits_s2_entry_perm_r(g_io_tlb_1_resp_bits_s2_entry_perm_r), .io_tlb_1_resp_bits_s2_entry_level(g_io_tlb_1_resp_bits_s2_entry_level), .io_tlb_1_resp_bits_s2_gpf(g_io_tlb_1_resp_bits_s2_gpf), .io_tlb_1_resp_bits_s2_gaf(g_io_tlb_1_resp_bits_s2_gaf), .io_wfi_wfiSafe(g_io_wfi_wfiSafe), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .io_perf_8_value(g_io_perf_8_value), .io_perf_9_value(g_io_perf_9_value), .io_perf_10_value(g_io_perf_10_value), .io_perf_11_value(g_io_perf_11_value), .io_perf_12_value(g_io_perf_12_value), .io_perf_13_value(g_io_perf_13_value), .io_perf_14_value(g_io_perf_14_value), .io_perf_15_value(g_io_perf_15_value), .io_perf_16_value(g_io_perf_16_value), .io_perf_17_value(g_io_perf_17_value), .io_perf_18_value(g_io_perf_18_value), .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata));
  L2TLBWrapper_xs u_i (.clock(clk), .reset(rst), .auto_out_a_ready(auto_out_a_ready), .auto_out_d_valid(auto_out_d_valid), .auto_out_d_bits_opcode(auto_out_d_bits_opcode), .auto_out_d_bits_size(auto_out_d_bits_size), .auto_out_d_bits_source(auto_out_d_bits_source), .auto_out_d_bits_data(auto_out_d_bits_data), .io_tlb_0_req_0_valid(io_tlb_0_req_0_valid), .io_tlb_0_req_0_bits_vpn(io_tlb_0_req_0_bits_vpn), .io_tlb_0_req_0_bits_s2xlate(io_tlb_0_req_0_bits_s2xlate), .io_tlb_0_resp_ready(io_tlb_0_resp_ready), .io_tlb_1_req_0_valid(io_tlb_1_req_0_valid), .io_tlb_1_req_0_bits_vpn(io_tlb_1_req_0_bits_vpn), .io_tlb_1_req_0_bits_s2xlate(io_tlb_1_req_0_bits_s2xlate), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_wfi_wfiReq(io_wfi_wfiReq), .io_csr_tlb_satp_mode(io_csr_tlb_satp_mode), .io_csr_tlb_satp_asid(io_csr_tlb_satp_asid), .io_csr_tlb_satp_ppn(io_csr_tlb_satp_ppn), .io_csr_tlb_satp_changed(io_csr_tlb_satp_changed), .io_csr_tlb_vsatp_mode(io_csr_tlb_vsatp_mode), .io_csr_tlb_vsatp_asid(io_csr_tlb_vsatp_asid), .io_csr_tlb_vsatp_ppn(io_csr_tlb_vsatp_ppn), .io_csr_tlb_vsatp_changed(io_csr_tlb_vsatp_changed), .io_csr_tlb_hgatp_mode(io_csr_tlb_hgatp_mode), .io_csr_tlb_hgatp_vmid(io_csr_tlb_hgatp_vmid), .io_csr_tlb_hgatp_ppn(io_csr_tlb_hgatp_ppn), .io_csr_tlb_hgatp_changed(io_csr_tlb_hgatp_changed), .io_csr_tlb_priv_mxr(io_csr_tlb_priv_mxr), .io_csr_tlb_priv_virt(io_csr_tlb_priv_virt), .io_csr_tlb_mPBMTE(io_csr_tlb_mPBMTE), .io_csr_tlb_hPBMTE(io_csr_tlb_hPBMTE), .io_csr_distribute_csr_w_valid(io_csr_distribute_csr_w_valid), .io_csr_distribute_csr_w_bits_addr(io_csr_distribute_csr_w_bits_addr), .io_csr_distribute_csr_w_bits_data(io_csr_distribute_csr_w_bits_data), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .cg_bore_cgen(cg_bore_cgen), .auto_out_a_valid(i_auto_out_a_valid), .auto_out_a_bits_source(i_auto_out_a_bits_source), .auto_out_a_bits_address(i_auto_out_a_bits_address), .io_tlb_0_req_0_ready(i_io_tlb_0_req_0_ready), .io_tlb_0_resp_valid(i_io_tlb_0_resp_valid), .io_tlb_0_resp_bits_s2xlate(i_io_tlb_0_resp_bits_s2xlate), .io_tlb_0_resp_bits_s1_entry_tag(i_io_tlb_0_resp_bits_s1_entry_tag), .io_tlb_0_resp_bits_s1_entry_asid(i_io_tlb_0_resp_bits_s1_entry_asid), .io_tlb_0_resp_bits_s1_entry_vmid(i_io_tlb_0_resp_bits_s1_entry_vmid), .io_tlb_0_resp_bits_s1_entry_n(i_io_tlb_0_resp_bits_s1_entry_n), .io_tlb_0_resp_bits_s1_entry_pbmt(i_io_tlb_0_resp_bits_s1_entry_pbmt), .io_tlb_0_resp_bits_s1_entry_perm_d(i_io_tlb_0_resp_bits_s1_entry_perm_d), .io_tlb_0_resp_bits_s1_entry_perm_a(i_io_tlb_0_resp_bits_s1_entry_perm_a), .io_tlb_0_resp_bits_s1_entry_perm_g(i_io_tlb_0_resp_bits_s1_entry_perm_g), .io_tlb_0_resp_bits_s1_entry_perm_u(i_io_tlb_0_resp_bits_s1_entry_perm_u), .io_tlb_0_resp_bits_s1_entry_perm_x(i_io_tlb_0_resp_bits_s1_entry_perm_x), .io_tlb_0_resp_bits_s1_entry_perm_w(i_io_tlb_0_resp_bits_s1_entry_perm_w), .io_tlb_0_resp_bits_s1_entry_perm_r(i_io_tlb_0_resp_bits_s1_entry_perm_r), .io_tlb_0_resp_bits_s1_entry_level(i_io_tlb_0_resp_bits_s1_entry_level), .io_tlb_0_resp_bits_s1_entry_v(i_io_tlb_0_resp_bits_s1_entry_v), .io_tlb_0_resp_bits_s1_entry_ppn(i_io_tlb_0_resp_bits_s1_entry_ppn), .io_tlb_0_resp_bits_s1_addr_low(i_io_tlb_0_resp_bits_s1_addr_low), .io_tlb_0_resp_bits_s1_ppn_low_0(i_io_tlb_0_resp_bits_s1_ppn_low_0), .io_tlb_0_resp_bits_s1_ppn_low_1(i_io_tlb_0_resp_bits_s1_ppn_low_1), .io_tlb_0_resp_bits_s1_ppn_low_2(i_io_tlb_0_resp_bits_s1_ppn_low_2), .io_tlb_0_resp_bits_s1_ppn_low_3(i_io_tlb_0_resp_bits_s1_ppn_low_3), .io_tlb_0_resp_bits_s1_ppn_low_4(i_io_tlb_0_resp_bits_s1_ppn_low_4), .io_tlb_0_resp_bits_s1_ppn_low_5(i_io_tlb_0_resp_bits_s1_ppn_low_5), .io_tlb_0_resp_bits_s1_ppn_low_6(i_io_tlb_0_resp_bits_s1_ppn_low_6), .io_tlb_0_resp_bits_s1_ppn_low_7(i_io_tlb_0_resp_bits_s1_ppn_low_7), .io_tlb_0_resp_bits_s1_valididx_0(i_io_tlb_0_resp_bits_s1_valididx_0), .io_tlb_0_resp_bits_s1_valididx_1(i_io_tlb_0_resp_bits_s1_valididx_1), .io_tlb_0_resp_bits_s1_valididx_2(i_io_tlb_0_resp_bits_s1_valididx_2), .io_tlb_0_resp_bits_s1_valididx_3(i_io_tlb_0_resp_bits_s1_valididx_3), .io_tlb_0_resp_bits_s1_valididx_4(i_io_tlb_0_resp_bits_s1_valididx_4), .io_tlb_0_resp_bits_s1_valididx_5(i_io_tlb_0_resp_bits_s1_valididx_5), .io_tlb_0_resp_bits_s1_valididx_6(i_io_tlb_0_resp_bits_s1_valididx_6), .io_tlb_0_resp_bits_s1_valididx_7(i_io_tlb_0_resp_bits_s1_valididx_7), .io_tlb_0_resp_bits_s1_pteidx_0(i_io_tlb_0_resp_bits_s1_pteidx_0), .io_tlb_0_resp_bits_s1_pteidx_1(i_io_tlb_0_resp_bits_s1_pteidx_1), .io_tlb_0_resp_bits_s1_pteidx_2(i_io_tlb_0_resp_bits_s1_pteidx_2), .io_tlb_0_resp_bits_s1_pteidx_3(i_io_tlb_0_resp_bits_s1_pteidx_3), .io_tlb_0_resp_bits_s1_pteidx_4(i_io_tlb_0_resp_bits_s1_pteidx_4), .io_tlb_0_resp_bits_s1_pteidx_5(i_io_tlb_0_resp_bits_s1_pteidx_5), .io_tlb_0_resp_bits_s1_pteidx_6(i_io_tlb_0_resp_bits_s1_pteidx_6), .io_tlb_0_resp_bits_s1_pteidx_7(i_io_tlb_0_resp_bits_s1_pteidx_7), .io_tlb_0_resp_bits_s1_pf(i_io_tlb_0_resp_bits_s1_pf), .io_tlb_0_resp_bits_s1_af(i_io_tlb_0_resp_bits_s1_af), .io_tlb_0_resp_bits_s2_entry_tag(i_io_tlb_0_resp_bits_s2_entry_tag), .io_tlb_0_resp_bits_s2_entry_vmid(i_io_tlb_0_resp_bits_s2_entry_vmid), .io_tlb_0_resp_bits_s2_entry_n(i_io_tlb_0_resp_bits_s2_entry_n), .io_tlb_0_resp_bits_s2_entry_pbmt(i_io_tlb_0_resp_bits_s2_entry_pbmt), .io_tlb_0_resp_bits_s2_entry_ppn(i_io_tlb_0_resp_bits_s2_entry_ppn), .io_tlb_0_resp_bits_s2_entry_perm_d(i_io_tlb_0_resp_bits_s2_entry_perm_d), .io_tlb_0_resp_bits_s2_entry_perm_a(i_io_tlb_0_resp_bits_s2_entry_perm_a), .io_tlb_0_resp_bits_s2_entry_perm_g(i_io_tlb_0_resp_bits_s2_entry_perm_g), .io_tlb_0_resp_bits_s2_entry_perm_u(i_io_tlb_0_resp_bits_s2_entry_perm_u), .io_tlb_0_resp_bits_s2_entry_perm_x(i_io_tlb_0_resp_bits_s2_entry_perm_x), .io_tlb_0_resp_bits_s2_entry_perm_w(i_io_tlb_0_resp_bits_s2_entry_perm_w), .io_tlb_0_resp_bits_s2_entry_perm_r(i_io_tlb_0_resp_bits_s2_entry_perm_r), .io_tlb_0_resp_bits_s2_entry_level(i_io_tlb_0_resp_bits_s2_entry_level), .io_tlb_0_resp_bits_s2_gpf(i_io_tlb_0_resp_bits_s2_gpf), .io_tlb_0_resp_bits_s2_gaf(i_io_tlb_0_resp_bits_s2_gaf), .io_tlb_1_req_0_ready(i_io_tlb_1_req_0_ready), .io_tlb_1_resp_valid(i_io_tlb_1_resp_valid), .io_tlb_1_resp_bits_s2xlate(i_io_tlb_1_resp_bits_s2xlate), .io_tlb_1_resp_bits_s1_entry_tag(i_io_tlb_1_resp_bits_s1_entry_tag), .io_tlb_1_resp_bits_s1_entry_asid(i_io_tlb_1_resp_bits_s1_entry_asid), .io_tlb_1_resp_bits_s1_entry_vmid(i_io_tlb_1_resp_bits_s1_entry_vmid), .io_tlb_1_resp_bits_s1_entry_n(i_io_tlb_1_resp_bits_s1_entry_n), .io_tlb_1_resp_bits_s1_entry_pbmt(i_io_tlb_1_resp_bits_s1_entry_pbmt), .io_tlb_1_resp_bits_s1_entry_perm_d(i_io_tlb_1_resp_bits_s1_entry_perm_d), .io_tlb_1_resp_bits_s1_entry_perm_a(i_io_tlb_1_resp_bits_s1_entry_perm_a), .io_tlb_1_resp_bits_s1_entry_perm_g(i_io_tlb_1_resp_bits_s1_entry_perm_g), .io_tlb_1_resp_bits_s1_entry_perm_u(i_io_tlb_1_resp_bits_s1_entry_perm_u), .io_tlb_1_resp_bits_s1_entry_perm_x(i_io_tlb_1_resp_bits_s1_entry_perm_x), .io_tlb_1_resp_bits_s1_entry_perm_w(i_io_tlb_1_resp_bits_s1_entry_perm_w), .io_tlb_1_resp_bits_s1_entry_perm_r(i_io_tlb_1_resp_bits_s1_entry_perm_r), .io_tlb_1_resp_bits_s1_entry_level(i_io_tlb_1_resp_bits_s1_entry_level), .io_tlb_1_resp_bits_s1_entry_v(i_io_tlb_1_resp_bits_s1_entry_v), .io_tlb_1_resp_bits_s1_entry_ppn(i_io_tlb_1_resp_bits_s1_entry_ppn), .io_tlb_1_resp_bits_s1_addr_low(i_io_tlb_1_resp_bits_s1_addr_low), .io_tlb_1_resp_bits_s1_ppn_low_0(i_io_tlb_1_resp_bits_s1_ppn_low_0), .io_tlb_1_resp_bits_s1_ppn_low_1(i_io_tlb_1_resp_bits_s1_ppn_low_1), .io_tlb_1_resp_bits_s1_ppn_low_2(i_io_tlb_1_resp_bits_s1_ppn_low_2), .io_tlb_1_resp_bits_s1_ppn_low_3(i_io_tlb_1_resp_bits_s1_ppn_low_3), .io_tlb_1_resp_bits_s1_ppn_low_4(i_io_tlb_1_resp_bits_s1_ppn_low_4), .io_tlb_1_resp_bits_s1_ppn_low_5(i_io_tlb_1_resp_bits_s1_ppn_low_5), .io_tlb_1_resp_bits_s1_ppn_low_6(i_io_tlb_1_resp_bits_s1_ppn_low_6), .io_tlb_1_resp_bits_s1_ppn_low_7(i_io_tlb_1_resp_bits_s1_ppn_low_7), .io_tlb_1_resp_bits_s1_valididx_0(i_io_tlb_1_resp_bits_s1_valididx_0), .io_tlb_1_resp_bits_s1_valididx_1(i_io_tlb_1_resp_bits_s1_valididx_1), .io_tlb_1_resp_bits_s1_valididx_2(i_io_tlb_1_resp_bits_s1_valididx_2), .io_tlb_1_resp_bits_s1_valididx_3(i_io_tlb_1_resp_bits_s1_valididx_3), .io_tlb_1_resp_bits_s1_valididx_4(i_io_tlb_1_resp_bits_s1_valididx_4), .io_tlb_1_resp_bits_s1_valididx_5(i_io_tlb_1_resp_bits_s1_valididx_5), .io_tlb_1_resp_bits_s1_valididx_6(i_io_tlb_1_resp_bits_s1_valididx_6), .io_tlb_1_resp_bits_s1_valididx_7(i_io_tlb_1_resp_bits_s1_valididx_7), .io_tlb_1_resp_bits_s1_pteidx_0(i_io_tlb_1_resp_bits_s1_pteidx_0), .io_tlb_1_resp_bits_s1_pteidx_1(i_io_tlb_1_resp_bits_s1_pteidx_1), .io_tlb_1_resp_bits_s1_pteidx_2(i_io_tlb_1_resp_bits_s1_pteidx_2), .io_tlb_1_resp_bits_s1_pteidx_3(i_io_tlb_1_resp_bits_s1_pteidx_3), .io_tlb_1_resp_bits_s1_pteidx_4(i_io_tlb_1_resp_bits_s1_pteidx_4), .io_tlb_1_resp_bits_s1_pteidx_5(i_io_tlb_1_resp_bits_s1_pteidx_5), .io_tlb_1_resp_bits_s1_pteidx_6(i_io_tlb_1_resp_bits_s1_pteidx_6), .io_tlb_1_resp_bits_s1_pteidx_7(i_io_tlb_1_resp_bits_s1_pteidx_7), .io_tlb_1_resp_bits_s1_pf(i_io_tlb_1_resp_bits_s1_pf), .io_tlb_1_resp_bits_s1_af(i_io_tlb_1_resp_bits_s1_af), .io_tlb_1_resp_bits_s2_entry_tag(i_io_tlb_1_resp_bits_s2_entry_tag), .io_tlb_1_resp_bits_s2_entry_vmid(i_io_tlb_1_resp_bits_s2_entry_vmid), .io_tlb_1_resp_bits_s2_entry_n(i_io_tlb_1_resp_bits_s2_entry_n), .io_tlb_1_resp_bits_s2_entry_pbmt(i_io_tlb_1_resp_bits_s2_entry_pbmt), .io_tlb_1_resp_bits_s2_entry_ppn(i_io_tlb_1_resp_bits_s2_entry_ppn), .io_tlb_1_resp_bits_s2_entry_perm_d(i_io_tlb_1_resp_bits_s2_entry_perm_d), .io_tlb_1_resp_bits_s2_entry_perm_a(i_io_tlb_1_resp_bits_s2_entry_perm_a), .io_tlb_1_resp_bits_s2_entry_perm_g(i_io_tlb_1_resp_bits_s2_entry_perm_g), .io_tlb_1_resp_bits_s2_entry_perm_u(i_io_tlb_1_resp_bits_s2_entry_perm_u), .io_tlb_1_resp_bits_s2_entry_perm_x(i_io_tlb_1_resp_bits_s2_entry_perm_x), .io_tlb_1_resp_bits_s2_entry_perm_w(i_io_tlb_1_resp_bits_s2_entry_perm_w), .io_tlb_1_resp_bits_s2_entry_perm_r(i_io_tlb_1_resp_bits_s2_entry_perm_r), .io_tlb_1_resp_bits_s2_entry_level(i_io_tlb_1_resp_bits_s2_entry_level), .io_tlb_1_resp_bits_s2_gpf(i_io_tlb_1_resp_bits_s2_gpf), .io_tlb_1_resp_bits_s2_gaf(i_io_tlb_1_resp_bits_s2_gaf), .io_wfi_wfiSafe(i_io_wfi_wfiSafe), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .io_perf_8_value(i_io_perf_8_value), .io_perf_9_value(i_io_perf_9_value), .io_perf_10_value(i_io_perf_10_value), .io_perf_11_value(i_io_perf_11_value), .io_perf_12_value(i_io_perf_12_value), .io_perf_13_value(i_io_perf_13_value), .io_perf_14_value(i_io_perf_14_value), .io_perf_15_value(i_io_perf_15_value), .io_perf_16_value(i_io_perf_16_value), .io_perf_17_value(i_io_perf_17_value), .io_perf_18_value(i_io_perf_18_value), .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata));
  always @(negedge clk) begin
    if (rst) begin
      auto_out_d_valid <= 1'b0;
      io_tlb_0_req_0_valid <= 1'b0;
      io_tlb_1_req_0_valid <= 1'b0;
      io_sfence_valid <= 1'b0;
      io_csr_distribute_csr_w_valid <= 1'b0;
    end else begin
      auto_out_a_ready <= ($urandom_range(0,2)!=0);
      auto_out_d_valid <= ($urandom_range(0,2)!=0);
      auto_out_d_bits_opcode <= 4'($urandom);
      auto_out_d_bits_size <= 3'($urandom);
      auto_out_d_bits_source <= 3'($urandom);
      auto_out_d_bits_data <= 256'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_tlb_0_req_0_valid <= ($urandom_range(0,2)!=0);
      io_tlb_0_req_0_bits_vpn <= {30'($urandom_range(0,3)), 8'($urandom)};
      io_tlb_0_req_0_bits_s2xlate <= 2'($urandom);
      io_tlb_0_resp_ready <= ($urandom_range(0,2)!=0);
      io_tlb_1_req_0_valid <= ($urandom_range(0,2)!=0);
      io_tlb_1_req_0_bits_vpn <= {30'($urandom_range(0,3)), 8'($urandom)};
      io_tlb_1_req_0_bits_s2xlate <= 2'($urandom);
      io_sfence_valid <= ($urandom_range(0,2)!=0);
      io_sfence_bits_rs1 <= $urandom_range(0,1);
      io_sfence_bits_rs2 <= $urandom_range(0,1);
      io_sfence_bits_addr <= {42'($urandom_range(0,3)), 8'($urandom)};
      io_sfence_bits_id <= 16'($urandom);
      io_sfence_bits_hv <= $urandom_range(0,1);
      io_sfence_bits_hg <= $urandom_range(0,1);
      io_wfi_wfiReq <= ($urandom_range(0,2)!=0);
      io_csr_tlb_satp_mode <= 4'($urandom);
      io_csr_tlb_satp_asid <= 16'($urandom);
      io_csr_tlb_satp_ppn <= {36'($urandom_range(0,3)), 8'($urandom)};
      io_csr_tlb_satp_changed <= $urandom_range(0,1);
      io_csr_tlb_vsatp_mode <= 4'($urandom);
      io_csr_tlb_vsatp_asid <= 16'($urandom);
      io_csr_tlb_vsatp_ppn <= {36'($urandom_range(0,3)), 8'($urandom)};
      io_csr_tlb_vsatp_changed <= $urandom_range(0,1);
      io_csr_tlb_hgatp_mode <= 4'($urandom);
      io_csr_tlb_hgatp_vmid <= 16'($urandom);
      io_csr_tlb_hgatp_ppn <= {36'($urandom_range(0,3)), 8'($urandom)};
      io_csr_tlb_hgatp_changed <= $urandom_range(0,1);
      io_csr_tlb_priv_mxr <= $urandom_range(0,1);
      io_csr_tlb_priv_virt <= $urandom_range(0,1);
      io_csr_tlb_mPBMTE <= $urandom_range(0,1);
      io_csr_tlb_hPBMTE <= $urandom_range(0,1);
      io_csr_distribute_csr_w_valid <= ($urandom_range(0,2)!=0);
      io_csr_distribute_csr_w_bits_addr <= {4'($urandom_range(0,3)), 8'($urandom)};
      io_csr_distribute_csr_w_bits_data <= 64'({$urandom(), $urandom()});
      boreChildrenBd_bore_array <= 6'($urandom);
      boreChildrenBd_bore_all <= ($urandom_range(0,2)!=0);
      boreChildrenBd_bore_req <= ($urandom_range(0,2)!=0);
      boreChildrenBd_bore_writeen <= $urandom_range(0,1);
      boreChildrenBd_bore_be <= 2'($urandom);
      boreChildrenBd_bore_addr <= 4'($urandom);
      boreChildrenBd_bore_indata <= 200'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      boreChildrenBd_bore_readen <= $urandom_range(0,1);
      boreChildrenBd_bore_addr_rd <= 4'($urandom);
      boreChildrenBd_bore_1_array <= 6'($urandom);
      boreChildrenBd_bore_1_all <= ($urandom_range(0,2)!=0);
      boreChildrenBd_bore_1_req <= ($urandom_range(0,2)!=0);
      boreChildrenBd_bore_1_writeen <= $urandom_range(0,1);
      boreChildrenBd_bore_1_be <= 2'($urandom);
      boreChildrenBd_bore_1_addr <= 6'($urandom);
      boreChildrenBd_bore_1_indata <= 228'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      boreChildrenBd_bore_1_readen <= $urandom_range(0,1);
      boreChildrenBd_bore_1_addr_rd <= 6'($urandom);
      sigFromSrams_bore_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_1_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_1_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_2_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_2_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_3_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_3_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_4_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_4_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_5_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_5_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_6_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_6_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_7_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_7_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_8_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_8_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_9_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_9_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_10_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_10_cgen <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_hold <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_bypass <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_bp_clken <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_aux_clk <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_aux_ckbp <= $urandom_range(0,1);
      sigFromSrams_bore_11_ram_mcp_hold <= $urandom_range(0,1);
      sigFromSrams_bore_11_cgen <= $urandom_range(0,1);
      cg_bore_cgen <= $urandom_range(0,1);
    end
  end

  initial begin
    rst = 1'b1;
    repeat (10) @(negedge clk);
    rst = 1'b0;
    repeat (4) @(negedge clk);  // 等 perf 2 级流水填满
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(posedge clk); #1;
      if (!$isunknown(g_auto_out_a_valid)) begin checks++; if (g_auto_out_a_valid !== i_auto_out_a_valid) begin errors++; if (errors<=20) $display("  MISMATCH %0t auto_out_a_valid: g=%h i=%h", $time, g_auto_out_a_valid, i_auto_out_a_valid); end end
      if (!$isunknown(g_auto_out_a_bits_source)) begin checks++; if (g_auto_out_a_bits_source !== i_auto_out_a_bits_source) begin errors++; if (errors<=20) $display("  MISMATCH %0t auto_out_a_bits_source: g=%h i=%h", $time, g_auto_out_a_bits_source, i_auto_out_a_bits_source); end end
      if (!$isunknown(g_auto_out_a_bits_address)) begin checks++; if (g_auto_out_a_bits_address !== i_auto_out_a_bits_address) begin errors++; if (errors<=20) $display("  MISMATCH %0t auto_out_a_bits_address: g=%h i=%h", $time, g_auto_out_a_bits_address, i_auto_out_a_bits_address); end end
      if (!$isunknown(g_io_tlb_0_req_0_ready)) begin checks++; if (g_io_tlb_0_req_0_ready !== i_io_tlb_0_req_0_ready) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_req_0_ready: g=%h i=%h", $time, g_io_tlb_0_req_0_ready, i_io_tlb_0_req_0_ready); end end
      if (!$isunknown(g_io_tlb_0_resp_valid)) begin checks++; if (g_io_tlb_0_resp_valid !== i_io_tlb_0_resp_valid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_valid: g=%h i=%h", $time, g_io_tlb_0_resp_valid, i_io_tlb_0_resp_valid); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2xlate)) begin checks++; if (g_io_tlb_0_resp_bits_s2xlate !== i_io_tlb_0_resp_bits_s2xlate) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2xlate: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2xlate, i_io_tlb_0_resp_bits_s2xlate); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_tag)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_tag !== i_io_tlb_0_resp_bits_s1_entry_tag) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_tag: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_tag, i_io_tlb_0_resp_bits_s1_entry_tag); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_asid)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_asid !== i_io_tlb_0_resp_bits_s1_entry_asid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_asid: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_asid, i_io_tlb_0_resp_bits_s1_entry_asid); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_vmid)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_vmid !== i_io_tlb_0_resp_bits_s1_entry_vmid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_vmid: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_vmid, i_io_tlb_0_resp_bits_s1_entry_vmid); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_n)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_n !== i_io_tlb_0_resp_bits_s1_entry_n) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_n: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_n, i_io_tlb_0_resp_bits_s1_entry_n); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_pbmt)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_pbmt !== i_io_tlb_0_resp_bits_s1_entry_pbmt) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_pbmt: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_pbmt, i_io_tlb_0_resp_bits_s1_entry_pbmt); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_d)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_d !== i_io_tlb_0_resp_bits_s1_entry_perm_d) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_d: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_d, i_io_tlb_0_resp_bits_s1_entry_perm_d); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_a)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_a !== i_io_tlb_0_resp_bits_s1_entry_perm_a) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_a: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_a, i_io_tlb_0_resp_bits_s1_entry_perm_a); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_g)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_g !== i_io_tlb_0_resp_bits_s1_entry_perm_g) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_g: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_g, i_io_tlb_0_resp_bits_s1_entry_perm_g); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_u)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_u !== i_io_tlb_0_resp_bits_s1_entry_perm_u) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_u: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_u, i_io_tlb_0_resp_bits_s1_entry_perm_u); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_x)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_x !== i_io_tlb_0_resp_bits_s1_entry_perm_x) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_x: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_x, i_io_tlb_0_resp_bits_s1_entry_perm_x); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_w)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_w !== i_io_tlb_0_resp_bits_s1_entry_perm_w) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_w: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_w, i_io_tlb_0_resp_bits_s1_entry_perm_w); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_perm_r)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_perm_r !== i_io_tlb_0_resp_bits_s1_entry_perm_r) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_perm_r: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_perm_r, i_io_tlb_0_resp_bits_s1_entry_perm_r); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_level)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_level !== i_io_tlb_0_resp_bits_s1_entry_level) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_level: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_level, i_io_tlb_0_resp_bits_s1_entry_level); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_v)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_v !== i_io_tlb_0_resp_bits_s1_entry_v) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_v: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_v, i_io_tlb_0_resp_bits_s1_entry_v); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_entry_ppn)) begin checks++; if (g_io_tlb_0_resp_bits_s1_entry_ppn !== i_io_tlb_0_resp_bits_s1_entry_ppn) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_entry_ppn: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_entry_ppn, i_io_tlb_0_resp_bits_s1_entry_ppn); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_addr_low)) begin checks++; if (g_io_tlb_0_resp_bits_s1_addr_low !== i_io_tlb_0_resp_bits_s1_addr_low) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_addr_low: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_addr_low, i_io_tlb_0_resp_bits_s1_addr_low); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_0)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_0 !== i_io_tlb_0_resp_bits_s1_ppn_low_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_0: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_0, i_io_tlb_0_resp_bits_s1_ppn_low_0); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_1)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_1 !== i_io_tlb_0_resp_bits_s1_ppn_low_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_1: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_1, i_io_tlb_0_resp_bits_s1_ppn_low_1); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_2)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_2 !== i_io_tlb_0_resp_bits_s1_ppn_low_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_2: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_2, i_io_tlb_0_resp_bits_s1_ppn_low_2); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_3)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_3 !== i_io_tlb_0_resp_bits_s1_ppn_low_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_3: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_3, i_io_tlb_0_resp_bits_s1_ppn_low_3); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_4)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_4 !== i_io_tlb_0_resp_bits_s1_ppn_low_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_4: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_4, i_io_tlb_0_resp_bits_s1_ppn_low_4); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_5)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_5 !== i_io_tlb_0_resp_bits_s1_ppn_low_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_5: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_5, i_io_tlb_0_resp_bits_s1_ppn_low_5); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_6)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_6 !== i_io_tlb_0_resp_bits_s1_ppn_low_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_6: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_6, i_io_tlb_0_resp_bits_s1_ppn_low_6); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_ppn_low_7)) begin checks++; if (g_io_tlb_0_resp_bits_s1_ppn_low_7 !== i_io_tlb_0_resp_bits_s1_ppn_low_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_ppn_low_7: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_ppn_low_7, i_io_tlb_0_resp_bits_s1_ppn_low_7); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_0)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_0 !== i_io_tlb_0_resp_bits_s1_valididx_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_0: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_0, i_io_tlb_0_resp_bits_s1_valididx_0); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_1)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_1 !== i_io_tlb_0_resp_bits_s1_valididx_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_1: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_1, i_io_tlb_0_resp_bits_s1_valididx_1); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_2)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_2 !== i_io_tlb_0_resp_bits_s1_valididx_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_2: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_2, i_io_tlb_0_resp_bits_s1_valididx_2); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_3)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_3 !== i_io_tlb_0_resp_bits_s1_valididx_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_3: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_3, i_io_tlb_0_resp_bits_s1_valididx_3); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_4)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_4 !== i_io_tlb_0_resp_bits_s1_valididx_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_4: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_4, i_io_tlb_0_resp_bits_s1_valididx_4); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_5)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_5 !== i_io_tlb_0_resp_bits_s1_valididx_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_5: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_5, i_io_tlb_0_resp_bits_s1_valididx_5); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_6)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_6 !== i_io_tlb_0_resp_bits_s1_valididx_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_6: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_6, i_io_tlb_0_resp_bits_s1_valididx_6); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_valididx_7)) begin checks++; if (g_io_tlb_0_resp_bits_s1_valididx_7 !== i_io_tlb_0_resp_bits_s1_valididx_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_valididx_7: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_valididx_7, i_io_tlb_0_resp_bits_s1_valididx_7); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_0)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_0 !== i_io_tlb_0_resp_bits_s1_pteidx_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_0: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_0, i_io_tlb_0_resp_bits_s1_pteidx_0); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_1)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_1 !== i_io_tlb_0_resp_bits_s1_pteidx_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_1: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_1, i_io_tlb_0_resp_bits_s1_pteidx_1); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_2)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_2 !== i_io_tlb_0_resp_bits_s1_pteidx_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_2: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_2, i_io_tlb_0_resp_bits_s1_pteidx_2); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_3)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_3 !== i_io_tlb_0_resp_bits_s1_pteidx_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_3: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_3, i_io_tlb_0_resp_bits_s1_pteidx_3); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_4)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_4 !== i_io_tlb_0_resp_bits_s1_pteidx_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_4: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_4, i_io_tlb_0_resp_bits_s1_pteidx_4); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_5)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_5 !== i_io_tlb_0_resp_bits_s1_pteidx_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_5: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_5, i_io_tlb_0_resp_bits_s1_pteidx_5); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_6)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_6 !== i_io_tlb_0_resp_bits_s1_pteidx_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_6: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_6, i_io_tlb_0_resp_bits_s1_pteidx_6); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pteidx_7)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pteidx_7 !== i_io_tlb_0_resp_bits_s1_pteidx_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pteidx_7: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pteidx_7, i_io_tlb_0_resp_bits_s1_pteidx_7); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_pf)) begin checks++; if (g_io_tlb_0_resp_bits_s1_pf !== i_io_tlb_0_resp_bits_s1_pf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_pf: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_pf, i_io_tlb_0_resp_bits_s1_pf); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s1_af)) begin checks++; if (g_io_tlb_0_resp_bits_s1_af !== i_io_tlb_0_resp_bits_s1_af) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s1_af: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s1_af, i_io_tlb_0_resp_bits_s1_af); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_tag)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_tag !== i_io_tlb_0_resp_bits_s2_entry_tag) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_tag: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_tag, i_io_tlb_0_resp_bits_s2_entry_tag); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_vmid)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_vmid !== i_io_tlb_0_resp_bits_s2_entry_vmid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_vmid: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_vmid, i_io_tlb_0_resp_bits_s2_entry_vmid); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_n)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_n !== i_io_tlb_0_resp_bits_s2_entry_n) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_n: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_n, i_io_tlb_0_resp_bits_s2_entry_n); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_pbmt)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_pbmt !== i_io_tlb_0_resp_bits_s2_entry_pbmt) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_pbmt: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_pbmt, i_io_tlb_0_resp_bits_s2_entry_pbmt); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_ppn)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_ppn !== i_io_tlb_0_resp_bits_s2_entry_ppn) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_ppn: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_ppn, i_io_tlb_0_resp_bits_s2_entry_ppn); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_d)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_d !== i_io_tlb_0_resp_bits_s2_entry_perm_d) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_d: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_d, i_io_tlb_0_resp_bits_s2_entry_perm_d); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_a)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_a !== i_io_tlb_0_resp_bits_s2_entry_perm_a) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_a: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_a, i_io_tlb_0_resp_bits_s2_entry_perm_a); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_g)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_g !== i_io_tlb_0_resp_bits_s2_entry_perm_g) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_g: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_g, i_io_tlb_0_resp_bits_s2_entry_perm_g); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_u)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_u !== i_io_tlb_0_resp_bits_s2_entry_perm_u) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_u: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_u, i_io_tlb_0_resp_bits_s2_entry_perm_u); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_x)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_x !== i_io_tlb_0_resp_bits_s2_entry_perm_x) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_x: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_x, i_io_tlb_0_resp_bits_s2_entry_perm_x); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_w)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_w !== i_io_tlb_0_resp_bits_s2_entry_perm_w) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_w: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_w, i_io_tlb_0_resp_bits_s2_entry_perm_w); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_perm_r)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_perm_r !== i_io_tlb_0_resp_bits_s2_entry_perm_r) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_perm_r: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_perm_r, i_io_tlb_0_resp_bits_s2_entry_perm_r); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_entry_level)) begin checks++; if (g_io_tlb_0_resp_bits_s2_entry_level !== i_io_tlb_0_resp_bits_s2_entry_level) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_entry_level: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_entry_level, i_io_tlb_0_resp_bits_s2_entry_level); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_gpf)) begin checks++; if (g_io_tlb_0_resp_bits_s2_gpf !== i_io_tlb_0_resp_bits_s2_gpf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_gpf: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_gpf, i_io_tlb_0_resp_bits_s2_gpf); end end
      if (!$isunknown(g_io_tlb_0_resp_bits_s2_gaf)) begin checks++; if (g_io_tlb_0_resp_bits_s2_gaf !== i_io_tlb_0_resp_bits_s2_gaf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_0_resp_bits_s2_gaf: g=%h i=%h", $time, g_io_tlb_0_resp_bits_s2_gaf, i_io_tlb_0_resp_bits_s2_gaf); end end
      if (!$isunknown(g_io_tlb_1_req_0_ready)) begin checks++; if (g_io_tlb_1_req_0_ready !== i_io_tlb_1_req_0_ready) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_req_0_ready: g=%h i=%h", $time, g_io_tlb_1_req_0_ready, i_io_tlb_1_req_0_ready); end end
      if (!$isunknown(g_io_tlb_1_resp_valid)) begin checks++; if (g_io_tlb_1_resp_valid !== i_io_tlb_1_resp_valid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_valid: g=%h i=%h", $time, g_io_tlb_1_resp_valid, i_io_tlb_1_resp_valid); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2xlate)) begin checks++; if (g_io_tlb_1_resp_bits_s2xlate !== i_io_tlb_1_resp_bits_s2xlate) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2xlate: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2xlate, i_io_tlb_1_resp_bits_s2xlate); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_tag)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_tag !== i_io_tlb_1_resp_bits_s1_entry_tag) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_tag: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_tag, i_io_tlb_1_resp_bits_s1_entry_tag); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_asid)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_asid !== i_io_tlb_1_resp_bits_s1_entry_asid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_asid: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_asid, i_io_tlb_1_resp_bits_s1_entry_asid); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_vmid)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_vmid !== i_io_tlb_1_resp_bits_s1_entry_vmid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_vmid: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_vmid, i_io_tlb_1_resp_bits_s1_entry_vmid); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_n)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_n !== i_io_tlb_1_resp_bits_s1_entry_n) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_n: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_n, i_io_tlb_1_resp_bits_s1_entry_n); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_pbmt)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_pbmt !== i_io_tlb_1_resp_bits_s1_entry_pbmt) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_pbmt: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_pbmt, i_io_tlb_1_resp_bits_s1_entry_pbmt); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_d)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_d !== i_io_tlb_1_resp_bits_s1_entry_perm_d) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_d: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_d, i_io_tlb_1_resp_bits_s1_entry_perm_d); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_a)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_a !== i_io_tlb_1_resp_bits_s1_entry_perm_a) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_a: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_a, i_io_tlb_1_resp_bits_s1_entry_perm_a); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_g)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_g !== i_io_tlb_1_resp_bits_s1_entry_perm_g) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_g: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_g, i_io_tlb_1_resp_bits_s1_entry_perm_g); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_u)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_u !== i_io_tlb_1_resp_bits_s1_entry_perm_u) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_u: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_u, i_io_tlb_1_resp_bits_s1_entry_perm_u); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_x)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_x !== i_io_tlb_1_resp_bits_s1_entry_perm_x) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_x: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_x, i_io_tlb_1_resp_bits_s1_entry_perm_x); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_w)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_w !== i_io_tlb_1_resp_bits_s1_entry_perm_w) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_w: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_w, i_io_tlb_1_resp_bits_s1_entry_perm_w); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_perm_r)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_perm_r !== i_io_tlb_1_resp_bits_s1_entry_perm_r) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_perm_r: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_perm_r, i_io_tlb_1_resp_bits_s1_entry_perm_r); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_level)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_level !== i_io_tlb_1_resp_bits_s1_entry_level) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_level: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_level, i_io_tlb_1_resp_bits_s1_entry_level); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_v)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_v !== i_io_tlb_1_resp_bits_s1_entry_v) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_v: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_v, i_io_tlb_1_resp_bits_s1_entry_v); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_entry_ppn)) begin checks++; if (g_io_tlb_1_resp_bits_s1_entry_ppn !== i_io_tlb_1_resp_bits_s1_entry_ppn) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_entry_ppn: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_entry_ppn, i_io_tlb_1_resp_bits_s1_entry_ppn); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_addr_low)) begin checks++; if (g_io_tlb_1_resp_bits_s1_addr_low !== i_io_tlb_1_resp_bits_s1_addr_low) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_addr_low: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_addr_low, i_io_tlb_1_resp_bits_s1_addr_low); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_0)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_0 !== i_io_tlb_1_resp_bits_s1_ppn_low_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_0: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_0, i_io_tlb_1_resp_bits_s1_ppn_low_0); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_1)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_1 !== i_io_tlb_1_resp_bits_s1_ppn_low_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_1: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_1, i_io_tlb_1_resp_bits_s1_ppn_low_1); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_2)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_2 !== i_io_tlb_1_resp_bits_s1_ppn_low_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_2: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_2, i_io_tlb_1_resp_bits_s1_ppn_low_2); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_3)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_3 !== i_io_tlb_1_resp_bits_s1_ppn_low_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_3: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_3, i_io_tlb_1_resp_bits_s1_ppn_low_3); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_4)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_4 !== i_io_tlb_1_resp_bits_s1_ppn_low_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_4: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_4, i_io_tlb_1_resp_bits_s1_ppn_low_4); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_5)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_5 !== i_io_tlb_1_resp_bits_s1_ppn_low_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_5: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_5, i_io_tlb_1_resp_bits_s1_ppn_low_5); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_6)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_6 !== i_io_tlb_1_resp_bits_s1_ppn_low_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_6: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_6, i_io_tlb_1_resp_bits_s1_ppn_low_6); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_ppn_low_7)) begin checks++; if (g_io_tlb_1_resp_bits_s1_ppn_low_7 !== i_io_tlb_1_resp_bits_s1_ppn_low_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_ppn_low_7: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_ppn_low_7, i_io_tlb_1_resp_bits_s1_ppn_low_7); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_0)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_0 !== i_io_tlb_1_resp_bits_s1_valididx_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_0: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_0, i_io_tlb_1_resp_bits_s1_valididx_0); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_1)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_1 !== i_io_tlb_1_resp_bits_s1_valididx_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_1: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_1, i_io_tlb_1_resp_bits_s1_valididx_1); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_2)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_2 !== i_io_tlb_1_resp_bits_s1_valididx_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_2: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_2, i_io_tlb_1_resp_bits_s1_valididx_2); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_3)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_3 !== i_io_tlb_1_resp_bits_s1_valididx_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_3: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_3, i_io_tlb_1_resp_bits_s1_valididx_3); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_4)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_4 !== i_io_tlb_1_resp_bits_s1_valididx_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_4: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_4, i_io_tlb_1_resp_bits_s1_valididx_4); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_5)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_5 !== i_io_tlb_1_resp_bits_s1_valididx_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_5: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_5, i_io_tlb_1_resp_bits_s1_valididx_5); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_6)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_6 !== i_io_tlb_1_resp_bits_s1_valididx_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_6: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_6, i_io_tlb_1_resp_bits_s1_valididx_6); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_valididx_7)) begin checks++; if (g_io_tlb_1_resp_bits_s1_valididx_7 !== i_io_tlb_1_resp_bits_s1_valididx_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_valididx_7: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_valididx_7, i_io_tlb_1_resp_bits_s1_valididx_7); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_0)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_0 !== i_io_tlb_1_resp_bits_s1_pteidx_0) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_0: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_0, i_io_tlb_1_resp_bits_s1_pteidx_0); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_1)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_1 !== i_io_tlb_1_resp_bits_s1_pteidx_1) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_1: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_1, i_io_tlb_1_resp_bits_s1_pteidx_1); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_2)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_2 !== i_io_tlb_1_resp_bits_s1_pteidx_2) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_2: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_2, i_io_tlb_1_resp_bits_s1_pteidx_2); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_3)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_3 !== i_io_tlb_1_resp_bits_s1_pteidx_3) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_3: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_3, i_io_tlb_1_resp_bits_s1_pteidx_3); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_4)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_4 !== i_io_tlb_1_resp_bits_s1_pteidx_4) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_4: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_4, i_io_tlb_1_resp_bits_s1_pteidx_4); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_5)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_5 !== i_io_tlb_1_resp_bits_s1_pteidx_5) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_5: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_5, i_io_tlb_1_resp_bits_s1_pteidx_5); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_6)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_6 !== i_io_tlb_1_resp_bits_s1_pteidx_6) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_6: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_6, i_io_tlb_1_resp_bits_s1_pteidx_6); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pteidx_7)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pteidx_7 !== i_io_tlb_1_resp_bits_s1_pteidx_7) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pteidx_7: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pteidx_7, i_io_tlb_1_resp_bits_s1_pteidx_7); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_pf)) begin checks++; if (g_io_tlb_1_resp_bits_s1_pf !== i_io_tlb_1_resp_bits_s1_pf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_pf: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_pf, i_io_tlb_1_resp_bits_s1_pf); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s1_af)) begin checks++; if (g_io_tlb_1_resp_bits_s1_af !== i_io_tlb_1_resp_bits_s1_af) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s1_af: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s1_af, i_io_tlb_1_resp_bits_s1_af); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_tag)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_tag !== i_io_tlb_1_resp_bits_s2_entry_tag) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_tag: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_tag, i_io_tlb_1_resp_bits_s2_entry_tag); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_vmid)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_vmid !== i_io_tlb_1_resp_bits_s2_entry_vmid) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_vmid: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_vmid, i_io_tlb_1_resp_bits_s2_entry_vmid); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_n)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_n !== i_io_tlb_1_resp_bits_s2_entry_n) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_n: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_n, i_io_tlb_1_resp_bits_s2_entry_n); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_pbmt)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_pbmt !== i_io_tlb_1_resp_bits_s2_entry_pbmt) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_pbmt: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_pbmt, i_io_tlb_1_resp_bits_s2_entry_pbmt); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_ppn)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_ppn !== i_io_tlb_1_resp_bits_s2_entry_ppn) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_ppn: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_ppn, i_io_tlb_1_resp_bits_s2_entry_ppn); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_d)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_d !== i_io_tlb_1_resp_bits_s2_entry_perm_d) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_d: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_d, i_io_tlb_1_resp_bits_s2_entry_perm_d); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_a)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_a !== i_io_tlb_1_resp_bits_s2_entry_perm_a) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_a: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_a, i_io_tlb_1_resp_bits_s2_entry_perm_a); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_g)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_g !== i_io_tlb_1_resp_bits_s2_entry_perm_g) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_g: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_g, i_io_tlb_1_resp_bits_s2_entry_perm_g); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_u)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_u !== i_io_tlb_1_resp_bits_s2_entry_perm_u) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_u: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_u, i_io_tlb_1_resp_bits_s2_entry_perm_u); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_x)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_x !== i_io_tlb_1_resp_bits_s2_entry_perm_x) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_x: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_x, i_io_tlb_1_resp_bits_s2_entry_perm_x); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_w)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_w !== i_io_tlb_1_resp_bits_s2_entry_perm_w) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_w: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_w, i_io_tlb_1_resp_bits_s2_entry_perm_w); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_perm_r)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_perm_r !== i_io_tlb_1_resp_bits_s2_entry_perm_r) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_perm_r: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_perm_r, i_io_tlb_1_resp_bits_s2_entry_perm_r); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_entry_level)) begin checks++; if (g_io_tlb_1_resp_bits_s2_entry_level !== i_io_tlb_1_resp_bits_s2_entry_level) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_entry_level: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_entry_level, i_io_tlb_1_resp_bits_s2_entry_level); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_gpf)) begin checks++; if (g_io_tlb_1_resp_bits_s2_gpf !== i_io_tlb_1_resp_bits_s2_gpf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_gpf: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_gpf, i_io_tlb_1_resp_bits_s2_gpf); end end
      if (!$isunknown(g_io_tlb_1_resp_bits_s2_gaf)) begin checks++; if (g_io_tlb_1_resp_bits_s2_gaf !== i_io_tlb_1_resp_bits_s2_gaf) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_tlb_1_resp_bits_s2_gaf: g=%h i=%h", $time, g_io_tlb_1_resp_bits_s2_gaf, i_io_tlb_1_resp_bits_s2_gaf); end end
      if (!$isunknown(g_io_wfi_wfiSafe)) begin checks++; if (g_io_wfi_wfiSafe !== i_io_wfi_wfiSafe) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_wfi_wfiSafe: g=%h i=%h", $time, g_io_wfi_wfiSafe, i_io_wfi_wfiSafe); end end
      if (!$isunknown(g_io_perf_0_value)) begin checks++; if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_0_value: g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end end
      if (!$isunknown(g_io_perf_1_value)) begin checks++; if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_1_value: g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end end
      if (!$isunknown(g_io_perf_2_value)) begin checks++; if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_2_value: g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end end
      if (!$isunknown(g_io_perf_3_value)) begin checks++; if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_3_value: g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end end
      if (!$isunknown(g_io_perf_4_value)) begin checks++; if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_4_value: g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end end
      if (!$isunknown(g_io_perf_5_value)) begin checks++; if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_5_value: g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end end
      if (!$isunknown(g_io_perf_6_value)) begin checks++; if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_6_value: g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end end
      if (!$isunknown(g_io_perf_7_value)) begin checks++; if (g_io_perf_7_value !== i_io_perf_7_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_7_value: g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end end
      if (!$isunknown(g_io_perf_8_value)) begin checks++; if (g_io_perf_8_value !== i_io_perf_8_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_8_value: g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end end
      if (!$isunknown(g_io_perf_9_value)) begin checks++; if (g_io_perf_9_value !== i_io_perf_9_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_9_value: g=%h i=%h", $time, g_io_perf_9_value, i_io_perf_9_value); end end
      if (!$isunknown(g_io_perf_10_value)) begin checks++; if (g_io_perf_10_value !== i_io_perf_10_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_10_value: g=%h i=%h", $time, g_io_perf_10_value, i_io_perf_10_value); end end
      if (!$isunknown(g_io_perf_11_value)) begin checks++; if (g_io_perf_11_value !== i_io_perf_11_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_11_value: g=%h i=%h", $time, g_io_perf_11_value, i_io_perf_11_value); end end
      if (!$isunknown(g_io_perf_12_value)) begin checks++; if (g_io_perf_12_value !== i_io_perf_12_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_12_value: g=%h i=%h", $time, g_io_perf_12_value, i_io_perf_12_value); end end
      if (!$isunknown(g_io_perf_13_value)) begin checks++; if (g_io_perf_13_value !== i_io_perf_13_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_13_value: g=%h i=%h", $time, g_io_perf_13_value, i_io_perf_13_value); end end
      if (!$isunknown(g_io_perf_14_value)) begin checks++; if (g_io_perf_14_value !== i_io_perf_14_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_14_value: g=%h i=%h", $time, g_io_perf_14_value, i_io_perf_14_value); end end
      if (!$isunknown(g_io_perf_15_value)) begin checks++; if (g_io_perf_15_value !== i_io_perf_15_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_15_value: g=%h i=%h", $time, g_io_perf_15_value, i_io_perf_15_value); end end
      if (!$isunknown(g_io_perf_16_value)) begin checks++; if (g_io_perf_16_value !== i_io_perf_16_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_16_value: g=%h i=%h", $time, g_io_perf_16_value, i_io_perf_16_value); end end
      if (!$isunknown(g_io_perf_17_value)) begin checks++; if (g_io_perf_17_value !== i_io_perf_17_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_17_value: g=%h i=%h", $time, g_io_perf_17_value, i_io_perf_17_value); end end
      if (!$isunknown(g_io_perf_18_value)) begin checks++; if (g_io_perf_18_value !== i_io_perf_18_value) begin errors++; if (errors<=20) $display("  MISMATCH %0t io_perf_18_value: g=%h i=%h", $time, g_io_perf_18_value, i_io_perf_18_value); end end
      if (!$isunknown(g_boreChildrenBd_bore_ack)) begin checks++; if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++; if (errors<=20) $display("  MISMATCH %0t boreChildrenBd_bore_ack: g=%h i=%h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end end
      if (!$isunknown(g_boreChildrenBd_bore_outdata)) begin checks++; if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++; if (errors<=20) $display("  MISMATCH %0t boreChildrenBd_bore_outdata: g=%h i=%h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end end
      if (!$isunknown(g_boreChildrenBd_bore_1_ack)) begin checks++; if (g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin errors++; if (errors<=20) $display("  MISMATCH %0t boreChildrenBd_bore_1_ack: g=%h i=%h", $time, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack); end end
      if (!$isunknown(g_boreChildrenBd_bore_1_outdata)) begin checks++; if (g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin errors++; if (errors<=20) $display("  MISMATCH %0t boreChildrenBd_bore_1_outdata: g=%h i=%h", $time, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata); end end
    end
    if (errors == 0) $display("TEST PASSED (L2TLBWrapper): checks=%0d", checks);
    else             $display("TEST FAILED (L2TLBWrapper): errors=%0d checks=%0d", errors, checks);
    $finish;
  end
endmodule
