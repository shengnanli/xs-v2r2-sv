// 自动生成：scripts/gen_tlbnonblock.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst; int errors=0, checks=0;
  always #5 clk = ~clk;
  logic io_sfence_valid;
  logic io_sfence_bits_rs1;
  logic io_sfence_bits_rs2;
  logic [49:0] io_sfence_bits_addr;
  logic [15:0] io_sfence_bits_id;
  logic io_sfence_bits_flushPipe;
  logic io_sfence_bits_hv;
  logic io_sfence_bits_hg;
  logic [3:0] io_csr_satp_mode;
  logic [15:0] io_csr_satp_asid;
  logic io_csr_satp_changed;
  logic [3:0] io_csr_vsatp_mode;
  logic [15:0] io_csr_vsatp_asid;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic [15:0] io_csr_hgatp_vmid;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_mxr;
  logic io_csr_priv_sum;
  logic io_csr_priv_vmxr;
  logic io_csr_priv_vsum;
  logic io_csr_priv_virt;
  logic io_csr_priv_spvp;
  logic [1:0] io_csr_priv_imode;
  logic [1:0] io_csr_priv_dmode;
  logic [1:0] io_csr_pmm_mseccfg;
  logic [1:0] io_csr_pmm_menvcfg;
  logic [1:0] io_csr_pmm_henvcfg;
  logic [1:0] io_csr_pmm_hstatus;
  logic [1:0] io_csr_pmm_senvcfg;
  logic io_requestor_0_req_valid;
  logic [49:0] io_requestor_0_req_bits_vaddr;
  logic [63:0] io_requestor_0_req_bits_fullva;
  logic io_requestor_0_req_bits_checkfullva;
  logic [2:0] io_requestor_0_req_bits_cmd;
  logic io_requestor_0_req_bits_hyperinst;
  logic io_requestor_0_req_bits_hlvx;
  logic io_requestor_0_req_bits_kill;
  logic io_requestor_0_req_bits_isPrefetch;
  logic io_requestor_0_req_bits_no_translate;
  logic [47:0] io_requestor_0_req_bits_pmp_addr;
  logic io_requestor_0_req_bits_debug_robIdx_flag;
  logic [7:0] io_requestor_0_req_bits_debug_robIdx_value;
  logic io_requestor_0_req_bits_debug_isFirstIssue;
  logic io_requestor_0_req_kill;
  logic io_requestor_1_req_valid;
  logic [49:0] io_requestor_1_req_bits_vaddr;
  logic [63:0] io_requestor_1_req_bits_fullva;
  logic io_requestor_1_req_bits_checkfullva;
  logic [2:0] io_requestor_1_req_bits_cmd;
  logic io_requestor_1_req_bits_hyperinst;
  logic io_requestor_1_req_bits_hlvx;
  logic io_requestor_1_req_bits_kill;
  logic io_requestor_1_req_bits_isPrefetch;
  logic io_requestor_1_req_bits_no_translate;
  logic [47:0] io_requestor_1_req_bits_pmp_addr;
  logic io_requestor_1_req_bits_debug_robIdx_flag;
  logic [7:0] io_requestor_1_req_bits_debug_robIdx_value;
  logic io_requestor_1_req_bits_debug_isFirstIssue;
  logic io_requestor_1_req_kill;
  logic io_requestor_2_req_valid;
  logic [49:0] io_requestor_2_req_bits_vaddr;
  logic [63:0] io_requestor_2_req_bits_fullva;
  logic io_requestor_2_req_bits_checkfullva;
  logic [2:0] io_requestor_2_req_bits_cmd;
  logic io_requestor_2_req_bits_hyperinst;
  logic io_requestor_2_req_bits_hlvx;
  logic io_requestor_2_req_bits_kill;
  logic io_requestor_2_req_bits_isPrefetch;
  logic io_requestor_2_req_bits_no_translate;
  logic [47:0] io_requestor_2_req_bits_pmp_addr;
  logic io_requestor_2_req_bits_debug_robIdx_flag;
  logic [7:0] io_requestor_2_req_bits_debug_robIdx_value;
  logic io_requestor_2_req_bits_debug_isFirstIssue;
  logic io_requestor_2_req_kill;
  logic io_requestor_3_req_valid;
  logic [49:0] io_requestor_3_req_bits_vaddr;
  logic [63:0] io_requestor_3_req_bits_fullva;
  logic io_requestor_3_req_bits_checkfullva;
  logic [2:0] io_requestor_3_req_bits_cmd;
  logic io_requestor_3_req_bits_hyperinst;
  logic io_requestor_3_req_bits_hlvx;
  logic io_requestor_3_req_bits_kill;
  logic io_requestor_3_req_bits_isPrefetch;
  logic io_requestor_3_req_bits_no_translate;
  logic [47:0] io_requestor_3_req_bits_pmp_addr;
  logic io_requestor_3_req_bits_debug_robIdx_flag;
  logic [7:0] io_requestor_3_req_bits_debug_robIdx_value;
  logic io_requestor_3_req_bits_debug_isFirstIssue;
  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
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
  logic io_ptw_resp_bits_getGpa;
  wire g_io_requestor_0_resp_valid;
  wire i_io_requestor_0_resp_valid;
  wire [47:0] g_io_requestor_0_resp_bits_paddr_0;
  wire [47:0] i_io_requestor_0_resp_bits_paddr_0;
  wire [47:0] g_io_requestor_0_resp_bits_paddr_1;
  wire [47:0] i_io_requestor_0_resp_bits_paddr_1;
  wire [63:0] g_io_requestor_0_resp_bits_gpaddr_0;
  wire [63:0] i_io_requestor_0_resp_bits_gpaddr_0;
  wire [63:0] g_io_requestor_0_resp_bits_fullva;
  wire [63:0] i_io_requestor_0_resp_bits_fullva;
  wire [1:0] g_io_requestor_0_resp_bits_pbmt_0;
  wire [1:0] i_io_requestor_0_resp_bits_pbmt_0;
  wire g_io_requestor_0_resp_bits_miss;
  wire i_io_requestor_0_resp_bits_miss;
  wire g_io_requestor_0_resp_bits_isForVSnonLeafPTE;
  wire i_io_requestor_0_resp_bits_isForVSnonLeafPTE;
  wire g_io_requestor_0_resp_bits_excp_0_vaNeedExt;
  wire i_io_requestor_0_resp_bits_excp_0_vaNeedExt;
  wire g_io_requestor_0_resp_bits_excp_0_isHyper;
  wire i_io_requestor_0_resp_bits_excp_0_isHyper;
  wire g_io_requestor_0_resp_bits_excp_0_gpf_ld;
  wire i_io_requestor_0_resp_bits_excp_0_gpf_ld;
  wire g_io_requestor_0_resp_bits_excp_0_gpf_st;
  wire i_io_requestor_0_resp_bits_excp_0_gpf_st;
  wire g_io_requestor_0_resp_bits_excp_0_pf_ld;
  wire i_io_requestor_0_resp_bits_excp_0_pf_ld;
  wire g_io_requestor_0_resp_bits_excp_0_pf_st;
  wire i_io_requestor_0_resp_bits_excp_0_pf_st;
  wire g_io_requestor_0_resp_bits_excp_0_af_ld;
  wire i_io_requestor_0_resp_bits_excp_0_af_ld;
  wire g_io_requestor_0_resp_bits_excp_0_af_st;
  wire i_io_requestor_0_resp_bits_excp_0_af_st;
  wire g_io_requestor_1_resp_valid;
  wire i_io_requestor_1_resp_valid;
  wire [47:0] g_io_requestor_1_resp_bits_paddr_0;
  wire [47:0] i_io_requestor_1_resp_bits_paddr_0;
  wire [47:0] g_io_requestor_1_resp_bits_paddr_1;
  wire [47:0] i_io_requestor_1_resp_bits_paddr_1;
  wire [63:0] g_io_requestor_1_resp_bits_gpaddr_0;
  wire [63:0] i_io_requestor_1_resp_bits_gpaddr_0;
  wire [63:0] g_io_requestor_1_resp_bits_fullva;
  wire [63:0] i_io_requestor_1_resp_bits_fullva;
  wire [1:0] g_io_requestor_1_resp_bits_pbmt_0;
  wire [1:0] i_io_requestor_1_resp_bits_pbmt_0;
  wire g_io_requestor_1_resp_bits_miss;
  wire i_io_requestor_1_resp_bits_miss;
  wire g_io_requestor_1_resp_bits_isForVSnonLeafPTE;
  wire i_io_requestor_1_resp_bits_isForVSnonLeafPTE;
  wire g_io_requestor_1_resp_bits_excp_0_vaNeedExt;
  wire i_io_requestor_1_resp_bits_excp_0_vaNeedExt;
  wire g_io_requestor_1_resp_bits_excp_0_isHyper;
  wire i_io_requestor_1_resp_bits_excp_0_isHyper;
  wire g_io_requestor_1_resp_bits_excp_0_gpf_ld;
  wire i_io_requestor_1_resp_bits_excp_0_gpf_ld;
  wire g_io_requestor_1_resp_bits_excp_0_pf_ld;
  wire i_io_requestor_1_resp_bits_excp_0_pf_ld;
  wire g_io_requestor_1_resp_bits_excp_0_af_ld;
  wire i_io_requestor_1_resp_bits_excp_0_af_ld;
  wire g_io_requestor_2_resp_valid;
  wire i_io_requestor_2_resp_valid;
  wire [47:0] g_io_requestor_2_resp_bits_paddr_0;
  wire [47:0] i_io_requestor_2_resp_bits_paddr_0;
  wire [47:0] g_io_requestor_2_resp_bits_paddr_1;
  wire [47:0] i_io_requestor_2_resp_bits_paddr_1;
  wire [63:0] g_io_requestor_2_resp_bits_gpaddr_0;
  wire [63:0] i_io_requestor_2_resp_bits_gpaddr_0;
  wire [63:0] g_io_requestor_2_resp_bits_fullva;
  wire [63:0] i_io_requestor_2_resp_bits_fullva;
  wire [1:0] g_io_requestor_2_resp_bits_pbmt_0;
  wire [1:0] i_io_requestor_2_resp_bits_pbmt_0;
  wire g_io_requestor_2_resp_bits_miss;
  wire i_io_requestor_2_resp_bits_miss;
  wire g_io_requestor_2_resp_bits_isForVSnonLeafPTE;
  wire i_io_requestor_2_resp_bits_isForVSnonLeafPTE;
  wire g_io_requestor_2_resp_bits_excp_0_vaNeedExt;
  wire i_io_requestor_2_resp_bits_excp_0_vaNeedExt;
  wire g_io_requestor_2_resp_bits_excp_0_isHyper;
  wire i_io_requestor_2_resp_bits_excp_0_isHyper;
  wire g_io_requestor_2_resp_bits_excp_0_gpf_ld;
  wire i_io_requestor_2_resp_bits_excp_0_gpf_ld;
  wire g_io_requestor_2_resp_bits_excp_0_pf_ld;
  wire i_io_requestor_2_resp_bits_excp_0_pf_ld;
  wire g_io_requestor_2_resp_bits_excp_0_af_ld;
  wire i_io_requestor_2_resp_bits_excp_0_af_ld;
  wire g_io_requestor_3_resp_valid;
  wire i_io_requestor_3_resp_valid;
  wire [47:0] g_io_requestor_3_resp_bits_paddr_0;
  wire [47:0] i_io_requestor_3_resp_bits_paddr_0;
  wire [1:0] g_io_requestor_3_resp_bits_pbmt_0;
  wire [1:0] i_io_requestor_3_resp_bits_pbmt_0;
  wire g_io_requestor_3_resp_bits_miss;
  wire i_io_requestor_3_resp_bits_miss;
  wire g_io_requestor_3_resp_bits_excp_0_gpf_ld;
  wire i_io_requestor_3_resp_bits_excp_0_gpf_ld;
  wire g_io_requestor_3_resp_bits_excp_0_pf_ld;
  wire i_io_requestor_3_resp_bits_excp_0_pf_ld;
  wire g_io_requestor_3_resp_bits_excp_0_af_ld;
  wire i_io_requestor_3_resp_bits_excp_0_af_ld;
  wire g_io_ptw_req_0_valid;
  wire i_io_ptw_req_0_valid;
  wire [37:0] g_io_ptw_req_0_bits_vpn;
  wire [37:0] i_io_ptw_req_0_bits_vpn;
  wire [1:0] g_io_ptw_req_0_bits_s2xlate;
  wire [1:0] i_io_ptw_req_0_bits_s2xlate;
  wire g_io_ptw_req_0_bits_getGpa;
  wire i_io_ptw_req_0_bits_getGpa;
  wire g_io_ptw_req_1_valid;
  wire i_io_ptw_req_1_valid;
  wire [37:0] g_io_ptw_req_1_bits_vpn;
  wire [37:0] i_io_ptw_req_1_bits_vpn;
  wire [1:0] g_io_ptw_req_1_bits_s2xlate;
  wire [1:0] i_io_ptw_req_1_bits_s2xlate;
  wire g_io_ptw_req_1_bits_getGpa;
  wire i_io_ptw_req_1_bits_getGpa;
  wire g_io_ptw_req_2_valid;
  wire i_io_ptw_req_2_valid;
  wire [37:0] g_io_ptw_req_2_bits_vpn;
  wire [37:0] i_io_ptw_req_2_bits_vpn;
  wire [1:0] g_io_ptw_req_2_bits_s2xlate;
  wire [1:0] i_io_ptw_req_2_bits_s2xlate;
  wire g_io_ptw_req_2_bits_getGpa;
  wire i_io_ptw_req_2_bits_getGpa;
  wire g_io_ptw_req_3_valid;
  wire i_io_ptw_req_3_valid;
  wire [37:0] g_io_ptw_req_3_bits_vpn;
  wire [37:0] i_io_ptw_req_3_bits_vpn;
  wire [1:0] g_io_ptw_req_3_bits_s2xlate;
  wire [1:0] i_io_ptw_req_3_bits_s2xlate;
  wire g_io_ptw_req_3_bits_getGpa;
  wire i_io_ptw_req_3_bits_getGpa;
  wire g_io_pmp_0_valid;
  wire i_io_pmp_0_valid;
  wire [47:0] g_io_pmp_0_bits_addr;
  wire [47:0] i_io_pmp_0_bits_addr;
  wire [2:0] g_io_pmp_0_bits_cmd;
  wire [2:0] i_io_pmp_0_bits_cmd;
  wire g_io_pmp_1_valid;
  wire i_io_pmp_1_valid;
  wire [47:0] g_io_pmp_1_bits_addr;
  wire [47:0] i_io_pmp_1_bits_addr;
  wire [2:0] g_io_pmp_1_bits_cmd;
  wire [2:0] i_io_pmp_1_bits_cmd;
  wire g_io_pmp_2_valid;
  wire i_io_pmp_2_valid;
  wire [47:0] g_io_pmp_2_bits_addr;
  wire [47:0] i_io_pmp_2_bits_addr;
  wire [2:0] g_io_pmp_2_bits_cmd;
  wire [2:0] i_io_pmp_2_bits_cmd;
  wire g_io_pmp_3_valid;
  wire i_io_pmp_3_valid;
  wire [47:0] g_io_pmp_3_bits_addr;
  wire [47:0] i_io_pmp_3_bits_addr;
  wire [2:0] g_io_pmp_3_bits_cmd;
  wire [2:0] i_io_pmp_3_bits_cmd;
  wire g_io_tlbreplay_0;
  wire i_io_tlbreplay_0;
  wire g_io_tlbreplay_1;
  wire i_io_tlbreplay_1;
  wire g_io_tlbreplay_2;
  wire i_io_tlbreplay_2;
  wire g_io_tlbreplay_3;
  wire i_io_tlbreplay_3;
  TLBNonBlock    u_g (.clock(clk), .reset(rst), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_flushPipe(io_sfence_bits_flushPipe), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_mode(io_csr_satp_mode), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_satp_changed(io_csr_satp_changed), .io_csr_vsatp_mode(io_csr_vsatp_mode), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_vsatp_changed(io_csr_vsatp_changed), .io_csr_hgatp_mode(io_csr_hgatp_mode), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_hgatp_changed(io_csr_hgatp_changed), .io_csr_priv_mxr(io_csr_priv_mxr), .io_csr_priv_sum(io_csr_priv_sum), .io_csr_priv_vmxr(io_csr_priv_vmxr), .io_csr_priv_vsum(io_csr_priv_vsum), .io_csr_priv_virt(io_csr_priv_virt), .io_csr_priv_spvp(io_csr_priv_spvp), .io_csr_priv_imode(io_csr_priv_imode), .io_csr_priv_dmode(io_csr_priv_dmode), .io_csr_pmm_mseccfg(io_csr_pmm_mseccfg), .io_csr_pmm_menvcfg(io_csr_pmm_menvcfg), .io_csr_pmm_henvcfg(io_csr_pmm_henvcfg), .io_csr_pmm_hstatus(io_csr_pmm_hstatus), .io_csr_pmm_senvcfg(io_csr_pmm_senvcfg), .io_requestor_0_req_valid(io_requestor_0_req_valid), .io_requestor_0_req_bits_vaddr(io_requestor_0_req_bits_vaddr), .io_requestor_0_req_bits_fullva(io_requestor_0_req_bits_fullva), .io_requestor_0_req_bits_checkfullva(io_requestor_0_req_bits_checkfullva), .io_requestor_0_req_bits_cmd(io_requestor_0_req_bits_cmd), .io_requestor_0_req_bits_hyperinst(io_requestor_0_req_bits_hyperinst), .io_requestor_0_req_bits_hlvx(io_requestor_0_req_bits_hlvx), .io_requestor_0_req_bits_kill(io_requestor_0_req_bits_kill), .io_requestor_0_req_bits_isPrefetch(io_requestor_0_req_bits_isPrefetch), .io_requestor_0_req_bits_no_translate(io_requestor_0_req_bits_no_translate), .io_requestor_0_req_bits_pmp_addr(io_requestor_0_req_bits_pmp_addr), .io_requestor_0_req_bits_debug_robIdx_flag(io_requestor_0_req_bits_debug_robIdx_flag), .io_requestor_0_req_bits_debug_robIdx_value(io_requestor_0_req_bits_debug_robIdx_value), .io_requestor_0_req_bits_debug_isFirstIssue(io_requestor_0_req_bits_debug_isFirstIssue), .io_requestor_0_req_kill(io_requestor_0_req_kill), .io_requestor_1_req_valid(io_requestor_1_req_valid), .io_requestor_1_req_bits_vaddr(io_requestor_1_req_bits_vaddr), .io_requestor_1_req_bits_fullva(io_requestor_1_req_bits_fullva), .io_requestor_1_req_bits_checkfullva(io_requestor_1_req_bits_checkfullva), .io_requestor_1_req_bits_cmd(io_requestor_1_req_bits_cmd), .io_requestor_1_req_bits_hyperinst(io_requestor_1_req_bits_hyperinst), .io_requestor_1_req_bits_hlvx(io_requestor_1_req_bits_hlvx), .io_requestor_1_req_bits_kill(io_requestor_1_req_bits_kill), .io_requestor_1_req_bits_isPrefetch(io_requestor_1_req_bits_isPrefetch), .io_requestor_1_req_bits_no_translate(io_requestor_1_req_bits_no_translate), .io_requestor_1_req_bits_pmp_addr(io_requestor_1_req_bits_pmp_addr), .io_requestor_1_req_bits_debug_robIdx_flag(io_requestor_1_req_bits_debug_robIdx_flag), .io_requestor_1_req_bits_debug_robIdx_value(io_requestor_1_req_bits_debug_robIdx_value), .io_requestor_1_req_bits_debug_isFirstIssue(io_requestor_1_req_bits_debug_isFirstIssue), .io_requestor_1_req_kill(io_requestor_1_req_kill), .io_requestor_2_req_valid(io_requestor_2_req_valid), .io_requestor_2_req_bits_vaddr(io_requestor_2_req_bits_vaddr), .io_requestor_2_req_bits_fullva(io_requestor_2_req_bits_fullva), .io_requestor_2_req_bits_checkfullva(io_requestor_2_req_bits_checkfullva), .io_requestor_2_req_bits_cmd(io_requestor_2_req_bits_cmd), .io_requestor_2_req_bits_hyperinst(io_requestor_2_req_bits_hyperinst), .io_requestor_2_req_bits_hlvx(io_requestor_2_req_bits_hlvx), .io_requestor_2_req_bits_kill(io_requestor_2_req_bits_kill), .io_requestor_2_req_bits_isPrefetch(io_requestor_2_req_bits_isPrefetch), .io_requestor_2_req_bits_no_translate(io_requestor_2_req_bits_no_translate), .io_requestor_2_req_bits_pmp_addr(io_requestor_2_req_bits_pmp_addr), .io_requestor_2_req_bits_debug_robIdx_flag(io_requestor_2_req_bits_debug_robIdx_flag), .io_requestor_2_req_bits_debug_robIdx_value(io_requestor_2_req_bits_debug_robIdx_value), .io_requestor_2_req_bits_debug_isFirstIssue(io_requestor_2_req_bits_debug_isFirstIssue), .io_requestor_2_req_kill(io_requestor_2_req_kill), .io_requestor_3_req_valid(io_requestor_3_req_valid), .io_requestor_3_req_bits_vaddr(io_requestor_3_req_bits_vaddr), .io_requestor_3_req_bits_fullva(io_requestor_3_req_bits_fullva), .io_requestor_3_req_bits_checkfullva(io_requestor_3_req_bits_checkfullva), .io_requestor_3_req_bits_cmd(io_requestor_3_req_bits_cmd), .io_requestor_3_req_bits_hyperinst(io_requestor_3_req_bits_hyperinst), .io_requestor_3_req_bits_hlvx(io_requestor_3_req_bits_hlvx), .io_requestor_3_req_bits_kill(io_requestor_3_req_bits_kill), .io_requestor_3_req_bits_isPrefetch(io_requestor_3_req_bits_isPrefetch), .io_requestor_3_req_bits_no_translate(io_requestor_3_req_bits_no_translate), .io_requestor_3_req_bits_pmp_addr(io_requestor_3_req_bits_pmp_addr), .io_requestor_3_req_bits_debug_robIdx_flag(io_requestor_3_req_bits_debug_robIdx_flag), .io_requestor_3_req_bits_debug_robIdx_value(io_requestor_3_req_bits_debug_robIdx_value), .io_requestor_3_req_bits_debug_isFirstIssue(io_requestor_3_req_bits_debug_isFirstIssue), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_ptw_resp_bits_getGpa(io_ptw_resp_bits_getGpa), .io_requestor_0_resp_valid(g_io_requestor_0_resp_valid), .io_requestor_0_resp_bits_paddr_0(g_io_requestor_0_resp_bits_paddr_0), .io_requestor_0_resp_bits_paddr_1(g_io_requestor_0_resp_bits_paddr_1), .io_requestor_0_resp_bits_gpaddr_0(g_io_requestor_0_resp_bits_gpaddr_0), .io_requestor_0_resp_bits_fullva(g_io_requestor_0_resp_bits_fullva), .io_requestor_0_resp_bits_pbmt_0(g_io_requestor_0_resp_bits_pbmt_0), .io_requestor_0_resp_bits_miss(g_io_requestor_0_resp_bits_miss), .io_requestor_0_resp_bits_isForVSnonLeafPTE(g_io_requestor_0_resp_bits_isForVSnonLeafPTE), .io_requestor_0_resp_bits_excp_0_vaNeedExt(g_io_requestor_0_resp_bits_excp_0_vaNeedExt), .io_requestor_0_resp_bits_excp_0_isHyper(g_io_requestor_0_resp_bits_excp_0_isHyper), .io_requestor_0_resp_bits_excp_0_gpf_ld(g_io_requestor_0_resp_bits_excp_0_gpf_ld), .io_requestor_0_resp_bits_excp_0_gpf_st(g_io_requestor_0_resp_bits_excp_0_gpf_st), .io_requestor_0_resp_bits_excp_0_pf_ld(g_io_requestor_0_resp_bits_excp_0_pf_ld), .io_requestor_0_resp_bits_excp_0_pf_st(g_io_requestor_0_resp_bits_excp_0_pf_st), .io_requestor_0_resp_bits_excp_0_af_ld(g_io_requestor_0_resp_bits_excp_0_af_ld), .io_requestor_0_resp_bits_excp_0_af_st(g_io_requestor_0_resp_bits_excp_0_af_st), .io_requestor_1_resp_valid(g_io_requestor_1_resp_valid), .io_requestor_1_resp_bits_paddr_0(g_io_requestor_1_resp_bits_paddr_0), .io_requestor_1_resp_bits_paddr_1(g_io_requestor_1_resp_bits_paddr_1), .io_requestor_1_resp_bits_gpaddr_0(g_io_requestor_1_resp_bits_gpaddr_0), .io_requestor_1_resp_bits_fullva(g_io_requestor_1_resp_bits_fullva), .io_requestor_1_resp_bits_pbmt_0(g_io_requestor_1_resp_bits_pbmt_0), .io_requestor_1_resp_bits_miss(g_io_requestor_1_resp_bits_miss), .io_requestor_1_resp_bits_isForVSnonLeafPTE(g_io_requestor_1_resp_bits_isForVSnonLeafPTE), .io_requestor_1_resp_bits_excp_0_vaNeedExt(g_io_requestor_1_resp_bits_excp_0_vaNeedExt), .io_requestor_1_resp_bits_excp_0_isHyper(g_io_requestor_1_resp_bits_excp_0_isHyper), .io_requestor_1_resp_bits_excp_0_gpf_ld(g_io_requestor_1_resp_bits_excp_0_gpf_ld), .io_requestor_1_resp_bits_excp_0_pf_ld(g_io_requestor_1_resp_bits_excp_0_pf_ld), .io_requestor_1_resp_bits_excp_0_af_ld(g_io_requestor_1_resp_bits_excp_0_af_ld), .io_requestor_2_resp_valid(g_io_requestor_2_resp_valid), .io_requestor_2_resp_bits_paddr_0(g_io_requestor_2_resp_bits_paddr_0), .io_requestor_2_resp_bits_paddr_1(g_io_requestor_2_resp_bits_paddr_1), .io_requestor_2_resp_bits_gpaddr_0(g_io_requestor_2_resp_bits_gpaddr_0), .io_requestor_2_resp_bits_fullva(g_io_requestor_2_resp_bits_fullva), .io_requestor_2_resp_bits_pbmt_0(g_io_requestor_2_resp_bits_pbmt_0), .io_requestor_2_resp_bits_miss(g_io_requestor_2_resp_bits_miss), .io_requestor_2_resp_bits_isForVSnonLeafPTE(g_io_requestor_2_resp_bits_isForVSnonLeafPTE), .io_requestor_2_resp_bits_excp_0_vaNeedExt(g_io_requestor_2_resp_bits_excp_0_vaNeedExt), .io_requestor_2_resp_bits_excp_0_isHyper(g_io_requestor_2_resp_bits_excp_0_isHyper), .io_requestor_2_resp_bits_excp_0_gpf_ld(g_io_requestor_2_resp_bits_excp_0_gpf_ld), .io_requestor_2_resp_bits_excp_0_pf_ld(g_io_requestor_2_resp_bits_excp_0_pf_ld), .io_requestor_2_resp_bits_excp_0_af_ld(g_io_requestor_2_resp_bits_excp_0_af_ld), .io_requestor_3_resp_valid(g_io_requestor_3_resp_valid), .io_requestor_3_resp_bits_paddr_0(g_io_requestor_3_resp_bits_paddr_0), .io_requestor_3_resp_bits_pbmt_0(g_io_requestor_3_resp_bits_pbmt_0), .io_requestor_3_resp_bits_miss(g_io_requestor_3_resp_bits_miss), .io_requestor_3_resp_bits_excp_0_gpf_ld(g_io_requestor_3_resp_bits_excp_0_gpf_ld), .io_requestor_3_resp_bits_excp_0_pf_ld(g_io_requestor_3_resp_bits_excp_0_pf_ld), .io_requestor_3_resp_bits_excp_0_af_ld(g_io_requestor_3_resp_bits_excp_0_af_ld), .io_ptw_req_0_valid(g_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(g_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(g_io_ptw_req_0_bits_s2xlate), .io_ptw_req_0_bits_getGpa(g_io_ptw_req_0_bits_getGpa), .io_ptw_req_1_valid(g_io_ptw_req_1_valid), .io_ptw_req_1_bits_vpn(g_io_ptw_req_1_bits_vpn), .io_ptw_req_1_bits_s2xlate(g_io_ptw_req_1_bits_s2xlate), .io_ptw_req_1_bits_getGpa(g_io_ptw_req_1_bits_getGpa), .io_ptw_req_2_valid(g_io_ptw_req_2_valid), .io_ptw_req_2_bits_vpn(g_io_ptw_req_2_bits_vpn), .io_ptw_req_2_bits_s2xlate(g_io_ptw_req_2_bits_s2xlate), .io_ptw_req_2_bits_getGpa(g_io_ptw_req_2_bits_getGpa), .io_ptw_req_3_valid(g_io_ptw_req_3_valid), .io_ptw_req_3_bits_vpn(g_io_ptw_req_3_bits_vpn), .io_ptw_req_3_bits_s2xlate(g_io_ptw_req_3_bits_s2xlate), .io_ptw_req_3_bits_getGpa(g_io_ptw_req_3_bits_getGpa), .io_pmp_0_valid(g_io_pmp_0_valid), .io_pmp_0_bits_addr(g_io_pmp_0_bits_addr), .io_pmp_0_bits_cmd(g_io_pmp_0_bits_cmd), .io_pmp_1_valid(g_io_pmp_1_valid), .io_pmp_1_bits_addr(g_io_pmp_1_bits_addr), .io_pmp_1_bits_cmd(g_io_pmp_1_bits_cmd), .io_pmp_2_valid(g_io_pmp_2_valid), .io_pmp_2_bits_addr(g_io_pmp_2_bits_addr), .io_pmp_2_bits_cmd(g_io_pmp_2_bits_cmd), .io_pmp_3_valid(g_io_pmp_3_valid), .io_pmp_3_bits_addr(g_io_pmp_3_bits_addr), .io_pmp_3_bits_cmd(g_io_pmp_3_bits_cmd), .io_tlbreplay_0(g_io_tlbreplay_0), .io_tlbreplay_1(g_io_tlbreplay_1), .io_tlbreplay_2(g_io_tlbreplay_2), .io_tlbreplay_3(g_io_tlbreplay_3));
  TLBNonBlock_xs u_i (.clock(clk), .reset(rst), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_flushPipe(io_sfence_bits_flushPipe), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_csr_satp_mode(io_csr_satp_mode), .io_csr_satp_asid(io_csr_satp_asid), .io_csr_satp_changed(io_csr_satp_changed), .io_csr_vsatp_mode(io_csr_vsatp_mode), .io_csr_vsatp_asid(io_csr_vsatp_asid), .io_csr_vsatp_changed(io_csr_vsatp_changed), .io_csr_hgatp_mode(io_csr_hgatp_mode), .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_hgatp_changed(io_csr_hgatp_changed), .io_csr_priv_mxr(io_csr_priv_mxr), .io_csr_priv_sum(io_csr_priv_sum), .io_csr_priv_vmxr(io_csr_priv_vmxr), .io_csr_priv_vsum(io_csr_priv_vsum), .io_csr_priv_virt(io_csr_priv_virt), .io_csr_priv_spvp(io_csr_priv_spvp), .io_csr_priv_imode(io_csr_priv_imode), .io_csr_priv_dmode(io_csr_priv_dmode), .io_csr_pmm_mseccfg(io_csr_pmm_mseccfg), .io_csr_pmm_menvcfg(io_csr_pmm_menvcfg), .io_csr_pmm_henvcfg(io_csr_pmm_henvcfg), .io_csr_pmm_hstatus(io_csr_pmm_hstatus), .io_csr_pmm_senvcfg(io_csr_pmm_senvcfg), .io_requestor_0_req_valid(io_requestor_0_req_valid), .io_requestor_0_req_bits_vaddr(io_requestor_0_req_bits_vaddr), .io_requestor_0_req_bits_fullva(io_requestor_0_req_bits_fullva), .io_requestor_0_req_bits_checkfullva(io_requestor_0_req_bits_checkfullva), .io_requestor_0_req_bits_cmd(io_requestor_0_req_bits_cmd), .io_requestor_0_req_bits_hyperinst(io_requestor_0_req_bits_hyperinst), .io_requestor_0_req_bits_hlvx(io_requestor_0_req_bits_hlvx), .io_requestor_0_req_bits_kill(io_requestor_0_req_bits_kill), .io_requestor_0_req_bits_isPrefetch(io_requestor_0_req_bits_isPrefetch), .io_requestor_0_req_bits_no_translate(io_requestor_0_req_bits_no_translate), .io_requestor_0_req_bits_pmp_addr(io_requestor_0_req_bits_pmp_addr), .io_requestor_0_req_bits_debug_robIdx_flag(io_requestor_0_req_bits_debug_robIdx_flag), .io_requestor_0_req_bits_debug_robIdx_value(io_requestor_0_req_bits_debug_robIdx_value), .io_requestor_0_req_bits_debug_isFirstIssue(io_requestor_0_req_bits_debug_isFirstIssue), .io_requestor_0_req_kill(io_requestor_0_req_kill), .io_requestor_1_req_valid(io_requestor_1_req_valid), .io_requestor_1_req_bits_vaddr(io_requestor_1_req_bits_vaddr), .io_requestor_1_req_bits_fullva(io_requestor_1_req_bits_fullva), .io_requestor_1_req_bits_checkfullva(io_requestor_1_req_bits_checkfullva), .io_requestor_1_req_bits_cmd(io_requestor_1_req_bits_cmd), .io_requestor_1_req_bits_hyperinst(io_requestor_1_req_bits_hyperinst), .io_requestor_1_req_bits_hlvx(io_requestor_1_req_bits_hlvx), .io_requestor_1_req_bits_kill(io_requestor_1_req_bits_kill), .io_requestor_1_req_bits_isPrefetch(io_requestor_1_req_bits_isPrefetch), .io_requestor_1_req_bits_no_translate(io_requestor_1_req_bits_no_translate), .io_requestor_1_req_bits_pmp_addr(io_requestor_1_req_bits_pmp_addr), .io_requestor_1_req_bits_debug_robIdx_flag(io_requestor_1_req_bits_debug_robIdx_flag), .io_requestor_1_req_bits_debug_robIdx_value(io_requestor_1_req_bits_debug_robIdx_value), .io_requestor_1_req_bits_debug_isFirstIssue(io_requestor_1_req_bits_debug_isFirstIssue), .io_requestor_1_req_kill(io_requestor_1_req_kill), .io_requestor_2_req_valid(io_requestor_2_req_valid), .io_requestor_2_req_bits_vaddr(io_requestor_2_req_bits_vaddr), .io_requestor_2_req_bits_fullva(io_requestor_2_req_bits_fullva), .io_requestor_2_req_bits_checkfullva(io_requestor_2_req_bits_checkfullva), .io_requestor_2_req_bits_cmd(io_requestor_2_req_bits_cmd), .io_requestor_2_req_bits_hyperinst(io_requestor_2_req_bits_hyperinst), .io_requestor_2_req_bits_hlvx(io_requestor_2_req_bits_hlvx), .io_requestor_2_req_bits_kill(io_requestor_2_req_bits_kill), .io_requestor_2_req_bits_isPrefetch(io_requestor_2_req_bits_isPrefetch), .io_requestor_2_req_bits_no_translate(io_requestor_2_req_bits_no_translate), .io_requestor_2_req_bits_pmp_addr(io_requestor_2_req_bits_pmp_addr), .io_requestor_2_req_bits_debug_robIdx_flag(io_requestor_2_req_bits_debug_robIdx_flag), .io_requestor_2_req_bits_debug_robIdx_value(io_requestor_2_req_bits_debug_robIdx_value), .io_requestor_2_req_bits_debug_isFirstIssue(io_requestor_2_req_bits_debug_isFirstIssue), .io_requestor_2_req_kill(io_requestor_2_req_kill), .io_requestor_3_req_valid(io_requestor_3_req_valid), .io_requestor_3_req_bits_vaddr(io_requestor_3_req_bits_vaddr), .io_requestor_3_req_bits_fullva(io_requestor_3_req_bits_fullva), .io_requestor_3_req_bits_checkfullva(io_requestor_3_req_bits_checkfullva), .io_requestor_3_req_bits_cmd(io_requestor_3_req_bits_cmd), .io_requestor_3_req_bits_hyperinst(io_requestor_3_req_bits_hyperinst), .io_requestor_3_req_bits_hlvx(io_requestor_3_req_bits_hlvx), .io_requestor_3_req_bits_kill(io_requestor_3_req_bits_kill), .io_requestor_3_req_bits_isPrefetch(io_requestor_3_req_bits_isPrefetch), .io_requestor_3_req_bits_no_translate(io_requestor_3_req_bits_no_translate), .io_requestor_3_req_bits_pmp_addr(io_requestor_3_req_bits_pmp_addr), .io_requestor_3_req_bits_debug_robIdx_flag(io_requestor_3_req_bits_debug_robIdx_flag), .io_requestor_3_req_bits_debug_robIdx_value(io_requestor_3_req_bits_debug_robIdx_value), .io_requestor_3_req_bits_debug_isFirstIssue(io_requestor_3_req_bits_debug_isFirstIssue), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_ptw_resp_bits_getGpa(io_ptw_resp_bits_getGpa), .io_requestor_0_resp_valid(i_io_requestor_0_resp_valid), .io_requestor_0_resp_bits_paddr_0(i_io_requestor_0_resp_bits_paddr_0), .io_requestor_0_resp_bits_paddr_1(i_io_requestor_0_resp_bits_paddr_1), .io_requestor_0_resp_bits_gpaddr_0(i_io_requestor_0_resp_bits_gpaddr_0), .io_requestor_0_resp_bits_fullva(i_io_requestor_0_resp_bits_fullva), .io_requestor_0_resp_bits_pbmt_0(i_io_requestor_0_resp_bits_pbmt_0), .io_requestor_0_resp_bits_miss(i_io_requestor_0_resp_bits_miss), .io_requestor_0_resp_bits_isForVSnonLeafPTE(i_io_requestor_0_resp_bits_isForVSnonLeafPTE), .io_requestor_0_resp_bits_excp_0_vaNeedExt(i_io_requestor_0_resp_bits_excp_0_vaNeedExt), .io_requestor_0_resp_bits_excp_0_isHyper(i_io_requestor_0_resp_bits_excp_0_isHyper), .io_requestor_0_resp_bits_excp_0_gpf_ld(i_io_requestor_0_resp_bits_excp_0_gpf_ld), .io_requestor_0_resp_bits_excp_0_gpf_st(i_io_requestor_0_resp_bits_excp_0_gpf_st), .io_requestor_0_resp_bits_excp_0_pf_ld(i_io_requestor_0_resp_bits_excp_0_pf_ld), .io_requestor_0_resp_bits_excp_0_pf_st(i_io_requestor_0_resp_bits_excp_0_pf_st), .io_requestor_0_resp_bits_excp_0_af_ld(i_io_requestor_0_resp_bits_excp_0_af_ld), .io_requestor_0_resp_bits_excp_0_af_st(i_io_requestor_0_resp_bits_excp_0_af_st), .io_requestor_1_resp_valid(i_io_requestor_1_resp_valid), .io_requestor_1_resp_bits_paddr_0(i_io_requestor_1_resp_bits_paddr_0), .io_requestor_1_resp_bits_paddr_1(i_io_requestor_1_resp_bits_paddr_1), .io_requestor_1_resp_bits_gpaddr_0(i_io_requestor_1_resp_bits_gpaddr_0), .io_requestor_1_resp_bits_fullva(i_io_requestor_1_resp_bits_fullva), .io_requestor_1_resp_bits_pbmt_0(i_io_requestor_1_resp_bits_pbmt_0), .io_requestor_1_resp_bits_miss(i_io_requestor_1_resp_bits_miss), .io_requestor_1_resp_bits_isForVSnonLeafPTE(i_io_requestor_1_resp_bits_isForVSnonLeafPTE), .io_requestor_1_resp_bits_excp_0_vaNeedExt(i_io_requestor_1_resp_bits_excp_0_vaNeedExt), .io_requestor_1_resp_bits_excp_0_isHyper(i_io_requestor_1_resp_bits_excp_0_isHyper), .io_requestor_1_resp_bits_excp_0_gpf_ld(i_io_requestor_1_resp_bits_excp_0_gpf_ld), .io_requestor_1_resp_bits_excp_0_pf_ld(i_io_requestor_1_resp_bits_excp_0_pf_ld), .io_requestor_1_resp_bits_excp_0_af_ld(i_io_requestor_1_resp_bits_excp_0_af_ld), .io_requestor_2_resp_valid(i_io_requestor_2_resp_valid), .io_requestor_2_resp_bits_paddr_0(i_io_requestor_2_resp_bits_paddr_0), .io_requestor_2_resp_bits_paddr_1(i_io_requestor_2_resp_bits_paddr_1), .io_requestor_2_resp_bits_gpaddr_0(i_io_requestor_2_resp_bits_gpaddr_0), .io_requestor_2_resp_bits_fullva(i_io_requestor_2_resp_bits_fullva), .io_requestor_2_resp_bits_pbmt_0(i_io_requestor_2_resp_bits_pbmt_0), .io_requestor_2_resp_bits_miss(i_io_requestor_2_resp_bits_miss), .io_requestor_2_resp_bits_isForVSnonLeafPTE(i_io_requestor_2_resp_bits_isForVSnonLeafPTE), .io_requestor_2_resp_bits_excp_0_vaNeedExt(i_io_requestor_2_resp_bits_excp_0_vaNeedExt), .io_requestor_2_resp_bits_excp_0_isHyper(i_io_requestor_2_resp_bits_excp_0_isHyper), .io_requestor_2_resp_bits_excp_0_gpf_ld(i_io_requestor_2_resp_bits_excp_0_gpf_ld), .io_requestor_2_resp_bits_excp_0_pf_ld(i_io_requestor_2_resp_bits_excp_0_pf_ld), .io_requestor_2_resp_bits_excp_0_af_ld(i_io_requestor_2_resp_bits_excp_0_af_ld), .io_requestor_3_resp_valid(i_io_requestor_3_resp_valid), .io_requestor_3_resp_bits_paddr_0(i_io_requestor_3_resp_bits_paddr_0), .io_requestor_3_resp_bits_pbmt_0(i_io_requestor_3_resp_bits_pbmt_0), .io_requestor_3_resp_bits_miss(i_io_requestor_3_resp_bits_miss), .io_requestor_3_resp_bits_excp_0_gpf_ld(i_io_requestor_3_resp_bits_excp_0_gpf_ld), .io_requestor_3_resp_bits_excp_0_pf_ld(i_io_requestor_3_resp_bits_excp_0_pf_ld), .io_requestor_3_resp_bits_excp_0_af_ld(i_io_requestor_3_resp_bits_excp_0_af_ld), .io_ptw_req_0_valid(i_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(i_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(i_io_ptw_req_0_bits_s2xlate), .io_ptw_req_0_bits_getGpa(i_io_ptw_req_0_bits_getGpa), .io_ptw_req_1_valid(i_io_ptw_req_1_valid), .io_ptw_req_1_bits_vpn(i_io_ptw_req_1_bits_vpn), .io_ptw_req_1_bits_s2xlate(i_io_ptw_req_1_bits_s2xlate), .io_ptw_req_1_bits_getGpa(i_io_ptw_req_1_bits_getGpa), .io_ptw_req_2_valid(i_io_ptw_req_2_valid), .io_ptw_req_2_bits_vpn(i_io_ptw_req_2_bits_vpn), .io_ptw_req_2_bits_s2xlate(i_io_ptw_req_2_bits_s2xlate), .io_ptw_req_2_bits_getGpa(i_io_ptw_req_2_bits_getGpa), .io_ptw_req_3_valid(i_io_ptw_req_3_valid), .io_ptw_req_3_bits_vpn(i_io_ptw_req_3_bits_vpn), .io_ptw_req_3_bits_s2xlate(i_io_ptw_req_3_bits_s2xlate), .io_ptw_req_3_bits_getGpa(i_io_ptw_req_3_bits_getGpa), .io_pmp_0_valid(i_io_pmp_0_valid), .io_pmp_0_bits_addr(i_io_pmp_0_bits_addr), .io_pmp_0_bits_cmd(i_io_pmp_0_bits_cmd), .io_pmp_1_valid(i_io_pmp_1_valid), .io_pmp_1_bits_addr(i_io_pmp_1_bits_addr), .io_pmp_1_bits_cmd(i_io_pmp_1_bits_cmd), .io_pmp_2_valid(i_io_pmp_2_valid), .io_pmp_2_bits_addr(i_io_pmp_2_bits_addr), .io_pmp_2_bits_cmd(i_io_pmp_2_bits_cmd), .io_pmp_3_valid(i_io_pmp_3_valid), .io_pmp_3_bits_addr(i_io_pmp_3_bits_addr), .io_pmp_3_bits_cmd(i_io_pmp_3_bits_cmd), .io_tlbreplay_0(i_io_tlbreplay_0), .io_tlbreplay_1(i_io_tlbreplay_1), .io_tlbreplay_2(i_io_tlbreplay_2), .io_tlbreplay_3(i_io_tlbreplay_3));
  always @(negedge clk) begin
    if (rst) begin
      io_ptw_resp_valid <= 1'b0;
      io_redirect_valid <= 1'b0;
      io_sfence_valid <= 1'b0;
      io_csr_satp_changed <= 1'b0;
      io_csr_vsatp_changed <= 1'b0;
      io_csr_hgatp_changed <= 1'b0;
      io_requestor_0_req_valid <= 1'b0;
      io_requestor_0_req_bits_kill <= 1'b0;
      io_requestor_0_req_kill <= 1'b0;
      io_requestor_1_req_valid <= 1'b0;
      io_requestor_1_req_bits_kill <= 1'b0;
      io_requestor_1_req_kill <= 1'b0;
      io_requestor_2_req_valid <= 1'b0;
      io_requestor_2_req_bits_kill <= 1'b0;
      io_requestor_2_req_kill <= 1'b0;
      io_requestor_3_req_valid <= 1'b0;
      io_requestor_3_req_bits_kill <= 1'b0;
    end else begin
      io_sfence_valid <= ($urandom_range(0,63)==0);
      io_sfence_bits_rs1 <= $urandom_range(0,1);
      io_sfence_bits_rs2 <= $urandom_range(0,1);
      io_sfence_bits_addr <= 50'({$urandom(), $urandom()});
      io_sfence_bits_id <= 16'($urandom);
      io_sfence_bits_flushPipe <= $urandom_range(0,1);
      io_sfence_bits_hv <= $urandom_range(0,1);
      io_sfence_bits_hg <= $urandom_range(0,1);
      io_csr_satp_mode <= (4'($urandom_range(0,2))*4'h8 + (($urandom_range(0,2)==2)?4'h1:4'h0));
      io_csr_satp_asid <= 16'($urandom);
      io_csr_satp_changed <= ($urandom_range(0,63)==0);
      io_csr_vsatp_mode <= (4'($urandom_range(0,2))*4'h8 + (($urandom_range(0,2)==2)?4'h1:4'h0));
      io_csr_vsatp_asid <= 16'($urandom);
      io_csr_vsatp_changed <= ($urandom_range(0,63)==0);
      io_csr_hgatp_mode <= (4'($urandom_range(0,2))*4'h8 + (($urandom_range(0,2)==2)?4'h1:4'h0));
      io_csr_hgatp_vmid <= 16'($urandom);
      io_csr_hgatp_changed <= ($urandom_range(0,63)==0);
      io_csr_priv_mxr <= $urandom_range(0,1);
      io_csr_priv_sum <= $urandom_range(0,1);
      io_csr_priv_vmxr <= $urandom_range(0,1);
      io_csr_priv_vsum <= $urandom_range(0,1);
      io_csr_priv_virt <= $urandom_range(0,1);
      io_csr_priv_spvp <= $urandom_range(0,1);
      io_csr_priv_imode <= 2'($urandom);
      io_csr_priv_dmode <= 2'($urandom);
      io_csr_pmm_mseccfg <= 2'($urandom);
      io_csr_pmm_menvcfg <= 2'($urandom);
      io_csr_pmm_henvcfg <= 2'($urandom);
      io_csr_pmm_hstatus <= 2'($urandom);
      io_csr_pmm_senvcfg <= 2'($urandom);
      io_requestor_0_req_valid <= ($urandom_range(0,1));
      io_requestor_0_req_bits_vaddr <= {38'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_0_req_bits_fullva <= {52'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_0_req_bits_checkfullva <= {-11'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_0_req_bits_cmd <= 3'($urandom);
      io_requestor_0_req_bits_hyperinst <= $urandom_range(0,1);
      io_requestor_0_req_bits_hlvx <= $urandom_range(0,1);
      io_requestor_0_req_bits_kill <= ($urandom_range(0,7)==0);
      io_requestor_0_req_bits_isPrefetch <= $urandom_range(0,1);
      io_requestor_0_req_bits_no_translate <= $urandom_range(0,1);
      io_requestor_0_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_0_req_bits_debug_robIdx_flag <= $urandom_range(0,1);
      io_requestor_0_req_bits_debug_robIdx_value <= 8'($urandom);
      io_requestor_0_req_bits_debug_isFirstIssue <= $urandom_range(0,1);
      io_requestor_0_req_kill <= ($urandom_range(0,7)==0);
      io_requestor_1_req_valid <= ($urandom_range(0,1));
      io_requestor_1_req_bits_vaddr <= {38'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_1_req_bits_fullva <= {52'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_1_req_bits_checkfullva <= {-11'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_1_req_bits_cmd <= 3'($urandom);
      io_requestor_1_req_bits_hyperinst <= $urandom_range(0,1);
      io_requestor_1_req_bits_hlvx <= $urandom_range(0,1);
      io_requestor_1_req_bits_kill <= ($urandom_range(0,7)==0);
      io_requestor_1_req_bits_isPrefetch <= $urandom_range(0,1);
      io_requestor_1_req_bits_no_translate <= $urandom_range(0,1);
      io_requestor_1_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_1_req_bits_debug_robIdx_flag <= $urandom_range(0,1);
      io_requestor_1_req_bits_debug_robIdx_value <= 8'($urandom);
      io_requestor_1_req_bits_debug_isFirstIssue <= $urandom_range(0,1);
      io_requestor_1_req_kill <= ($urandom_range(0,7)==0);
      io_requestor_2_req_valid <= ($urandom_range(0,1));
      io_requestor_2_req_bits_vaddr <= {38'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_2_req_bits_fullva <= {52'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_2_req_bits_checkfullva <= {-11'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_2_req_bits_cmd <= 3'($urandom);
      io_requestor_2_req_bits_hyperinst <= $urandom_range(0,1);
      io_requestor_2_req_bits_hlvx <= $urandom_range(0,1);
      io_requestor_2_req_bits_kill <= ($urandom_range(0,7)==0);
      io_requestor_2_req_bits_isPrefetch <= $urandom_range(0,1);
      io_requestor_2_req_bits_no_translate <= $urandom_range(0,1);
      io_requestor_2_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_2_req_bits_debug_robIdx_flag <= $urandom_range(0,1);
      io_requestor_2_req_bits_debug_robIdx_value <= 8'($urandom);
      io_requestor_2_req_bits_debug_isFirstIssue <= $urandom_range(0,1);
      io_requestor_2_req_kill <= ($urandom_range(0,7)==0);
      io_requestor_3_req_valid <= ($urandom_range(0,1));
      io_requestor_3_req_bits_vaddr <= {38'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_3_req_bits_fullva <= {52'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_3_req_bits_checkfullva <= {-11'($urandom_range(0,7)), 12'($urandom)};
      io_requestor_3_req_bits_cmd <= 3'($urandom);
      io_requestor_3_req_bits_hyperinst <= $urandom_range(0,1);
      io_requestor_3_req_bits_hlvx <= $urandom_range(0,1);
      io_requestor_3_req_bits_kill <= ($urandom_range(0,7)==0);
      io_requestor_3_req_bits_isPrefetch <= $urandom_range(0,1);
      io_requestor_3_req_bits_no_translate <= $urandom_range(0,1);
      io_requestor_3_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_3_req_bits_debug_robIdx_flag <= $urandom_range(0,1);
      io_requestor_3_req_bits_debug_robIdx_value <= 8'($urandom);
      io_requestor_3_req_bits_debug_isFirstIssue <= $urandom_range(0,1);
      io_redirect_valid <= ($urandom_range(0,15)==0);
      io_redirect_bits_robIdx_flag <= $urandom_range(0,1);
      io_redirect_bits_robIdx_value <= 8'($urandom);
      io_redirect_bits_level <= $urandom_range(0,1);
      io_ptw_resp_valid <= ($urandom_range(0,3)==0);
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
      io_ptw_resp_bits_getGpa <= $urandom_range(0,1);
      begin int s; s=$urandom_range(0,2); io_csr_satp_mode <= (s==0)?4'h0:(s==1)?4'h8:4'h9; end
      begin int s; s=$urandom_range(0,2); io_csr_vsatp_mode <= (s==0)?4'h0:(s==1)?4'h8:4'h9; end
      begin int s; s=$urandom_range(0,2); io_csr_hgatp_mode <= (s==0)?4'h0:(s==1)?4'h8:4'h9; end
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_requestor_0_resp_valid) && g_io_requestor_0_resp_valid !== i_io_requestor_0_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_valid g=%h i=%h", $time, g_io_requestor_0_resp_valid, i_io_requestor_0_resp_valid); end
    if (!$isunknown(g_io_requestor_0_resp_bits_paddr_0) && g_io_requestor_0_resp_bits_paddr_0 !== i_io_requestor_0_resp_bits_paddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_paddr_0 g=%h i=%h", $time, g_io_requestor_0_resp_bits_paddr_0, i_io_requestor_0_resp_bits_paddr_0); end
    if (!$isunknown(g_io_requestor_0_resp_bits_paddr_1) && g_io_requestor_0_resp_bits_paddr_1 !== i_io_requestor_0_resp_bits_paddr_1) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_paddr_1 g=%h i=%h", $time, g_io_requestor_0_resp_bits_paddr_1, i_io_requestor_0_resp_bits_paddr_1); end
    if (!$isunknown(g_io_requestor_0_resp_bits_gpaddr_0) && g_io_requestor_0_resp_bits_gpaddr_0 !== i_io_requestor_0_resp_bits_gpaddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_gpaddr_0 g=%h i=%h", $time, g_io_requestor_0_resp_bits_gpaddr_0, i_io_requestor_0_resp_bits_gpaddr_0); end
    if (!$isunknown(g_io_requestor_0_resp_bits_fullva) && g_io_requestor_0_resp_bits_fullva !== i_io_requestor_0_resp_bits_fullva) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_fullva g=%h i=%h", $time, g_io_requestor_0_resp_bits_fullva, i_io_requestor_0_resp_bits_fullva); end
    if (!$isunknown(g_io_requestor_0_resp_bits_pbmt_0) && g_io_requestor_0_resp_bits_pbmt_0 !== i_io_requestor_0_resp_bits_pbmt_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_pbmt_0 g=%h i=%h", $time, g_io_requestor_0_resp_bits_pbmt_0, i_io_requestor_0_resp_bits_pbmt_0); end
    if (!$isunknown(g_io_requestor_0_resp_bits_miss) && g_io_requestor_0_resp_bits_miss !== i_io_requestor_0_resp_bits_miss) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_miss g=%h i=%h", $time, g_io_requestor_0_resp_bits_miss, i_io_requestor_0_resp_bits_miss); end
    if (!$isunknown(g_io_requestor_0_resp_bits_isForVSnonLeafPTE) && g_io_requestor_0_resp_bits_isForVSnonLeafPTE !== i_io_requestor_0_resp_bits_isForVSnonLeafPTE) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_isForVSnonLeafPTE g=%h i=%h", $time, g_io_requestor_0_resp_bits_isForVSnonLeafPTE, i_io_requestor_0_resp_bits_isForVSnonLeafPTE); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_vaNeedExt) && g_io_requestor_0_resp_bits_excp_0_vaNeedExt !== i_io_requestor_0_resp_bits_excp_0_vaNeedExt) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_vaNeedExt g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_vaNeedExt, i_io_requestor_0_resp_bits_excp_0_vaNeedExt); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_isHyper) && g_io_requestor_0_resp_bits_excp_0_isHyper !== i_io_requestor_0_resp_bits_excp_0_isHyper) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_isHyper g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_isHyper, i_io_requestor_0_resp_bits_excp_0_isHyper); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_gpf_ld) && g_io_requestor_0_resp_bits_excp_0_gpf_ld !== i_io_requestor_0_resp_bits_excp_0_gpf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_gpf_ld g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_gpf_ld, i_io_requestor_0_resp_bits_excp_0_gpf_ld); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_gpf_st) && g_io_requestor_0_resp_bits_excp_0_gpf_st !== i_io_requestor_0_resp_bits_excp_0_gpf_st) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_gpf_st g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_gpf_st, i_io_requestor_0_resp_bits_excp_0_gpf_st); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_pf_ld) && g_io_requestor_0_resp_bits_excp_0_pf_ld !== i_io_requestor_0_resp_bits_excp_0_pf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_pf_ld g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_pf_ld, i_io_requestor_0_resp_bits_excp_0_pf_ld); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_pf_st) && g_io_requestor_0_resp_bits_excp_0_pf_st !== i_io_requestor_0_resp_bits_excp_0_pf_st) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_pf_st g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_pf_st, i_io_requestor_0_resp_bits_excp_0_pf_st); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_af_ld) && g_io_requestor_0_resp_bits_excp_0_af_ld !== i_io_requestor_0_resp_bits_excp_0_af_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_af_ld g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_af_ld, i_io_requestor_0_resp_bits_excp_0_af_ld); end
    if (!$isunknown(g_io_requestor_0_resp_bits_excp_0_af_st) && g_io_requestor_0_resp_bits_excp_0_af_st !== i_io_requestor_0_resp_bits_excp_0_af_st) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_0_resp_bits_excp_0_af_st g=%h i=%h", $time, g_io_requestor_0_resp_bits_excp_0_af_st, i_io_requestor_0_resp_bits_excp_0_af_st); end
    if (!$isunknown(g_io_requestor_1_resp_valid) && g_io_requestor_1_resp_valid !== i_io_requestor_1_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_valid g=%h i=%h", $time, g_io_requestor_1_resp_valid, i_io_requestor_1_resp_valid); end
    if (!$isunknown(g_io_requestor_1_resp_bits_paddr_0) && g_io_requestor_1_resp_bits_paddr_0 !== i_io_requestor_1_resp_bits_paddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_paddr_0 g=%h i=%h", $time, g_io_requestor_1_resp_bits_paddr_0, i_io_requestor_1_resp_bits_paddr_0); end
    if (!$isunknown(g_io_requestor_1_resp_bits_paddr_1) && g_io_requestor_1_resp_bits_paddr_1 !== i_io_requestor_1_resp_bits_paddr_1) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_paddr_1 g=%h i=%h", $time, g_io_requestor_1_resp_bits_paddr_1, i_io_requestor_1_resp_bits_paddr_1); end
    if (!$isunknown(g_io_requestor_1_resp_bits_gpaddr_0) && g_io_requestor_1_resp_bits_gpaddr_0 !== i_io_requestor_1_resp_bits_gpaddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_gpaddr_0 g=%h i=%h", $time, g_io_requestor_1_resp_bits_gpaddr_0, i_io_requestor_1_resp_bits_gpaddr_0); end
    if (!$isunknown(g_io_requestor_1_resp_bits_fullva) && g_io_requestor_1_resp_bits_fullva !== i_io_requestor_1_resp_bits_fullva) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_fullva g=%h i=%h", $time, g_io_requestor_1_resp_bits_fullva, i_io_requestor_1_resp_bits_fullva); end
    if (!$isunknown(g_io_requestor_1_resp_bits_pbmt_0) && g_io_requestor_1_resp_bits_pbmt_0 !== i_io_requestor_1_resp_bits_pbmt_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_pbmt_0 g=%h i=%h", $time, g_io_requestor_1_resp_bits_pbmt_0, i_io_requestor_1_resp_bits_pbmt_0); end
    if (!$isunknown(g_io_requestor_1_resp_bits_miss) && g_io_requestor_1_resp_bits_miss !== i_io_requestor_1_resp_bits_miss) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_miss g=%h i=%h", $time, g_io_requestor_1_resp_bits_miss, i_io_requestor_1_resp_bits_miss); end
    if (!$isunknown(g_io_requestor_1_resp_bits_isForVSnonLeafPTE) && g_io_requestor_1_resp_bits_isForVSnonLeafPTE !== i_io_requestor_1_resp_bits_isForVSnonLeafPTE) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_isForVSnonLeafPTE g=%h i=%h", $time, g_io_requestor_1_resp_bits_isForVSnonLeafPTE, i_io_requestor_1_resp_bits_isForVSnonLeafPTE); end
    if (!$isunknown(g_io_requestor_1_resp_bits_excp_0_vaNeedExt) && g_io_requestor_1_resp_bits_excp_0_vaNeedExt !== i_io_requestor_1_resp_bits_excp_0_vaNeedExt) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_excp_0_vaNeedExt g=%h i=%h", $time, g_io_requestor_1_resp_bits_excp_0_vaNeedExt, i_io_requestor_1_resp_bits_excp_0_vaNeedExt); end
    if (!$isunknown(g_io_requestor_1_resp_bits_excp_0_isHyper) && g_io_requestor_1_resp_bits_excp_0_isHyper !== i_io_requestor_1_resp_bits_excp_0_isHyper) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_excp_0_isHyper g=%h i=%h", $time, g_io_requestor_1_resp_bits_excp_0_isHyper, i_io_requestor_1_resp_bits_excp_0_isHyper); end
    if (!$isunknown(g_io_requestor_1_resp_bits_excp_0_gpf_ld) && g_io_requestor_1_resp_bits_excp_0_gpf_ld !== i_io_requestor_1_resp_bits_excp_0_gpf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_excp_0_gpf_ld g=%h i=%h", $time, g_io_requestor_1_resp_bits_excp_0_gpf_ld, i_io_requestor_1_resp_bits_excp_0_gpf_ld); end
    if (!$isunknown(g_io_requestor_1_resp_bits_excp_0_pf_ld) && g_io_requestor_1_resp_bits_excp_0_pf_ld !== i_io_requestor_1_resp_bits_excp_0_pf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_excp_0_pf_ld g=%h i=%h", $time, g_io_requestor_1_resp_bits_excp_0_pf_ld, i_io_requestor_1_resp_bits_excp_0_pf_ld); end
    if (!$isunknown(g_io_requestor_1_resp_bits_excp_0_af_ld) && g_io_requestor_1_resp_bits_excp_0_af_ld !== i_io_requestor_1_resp_bits_excp_0_af_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_1_resp_bits_excp_0_af_ld g=%h i=%h", $time, g_io_requestor_1_resp_bits_excp_0_af_ld, i_io_requestor_1_resp_bits_excp_0_af_ld); end
    if (!$isunknown(g_io_requestor_2_resp_valid) && g_io_requestor_2_resp_valid !== i_io_requestor_2_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_valid g=%h i=%h", $time, g_io_requestor_2_resp_valid, i_io_requestor_2_resp_valid); end
    if (!$isunknown(g_io_requestor_2_resp_bits_paddr_0) && g_io_requestor_2_resp_bits_paddr_0 !== i_io_requestor_2_resp_bits_paddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_paddr_0 g=%h i=%h", $time, g_io_requestor_2_resp_bits_paddr_0, i_io_requestor_2_resp_bits_paddr_0); end
    if (!$isunknown(g_io_requestor_2_resp_bits_paddr_1) && g_io_requestor_2_resp_bits_paddr_1 !== i_io_requestor_2_resp_bits_paddr_1) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_paddr_1 g=%h i=%h", $time, g_io_requestor_2_resp_bits_paddr_1, i_io_requestor_2_resp_bits_paddr_1); end
    if (!$isunknown(g_io_requestor_2_resp_bits_gpaddr_0) && g_io_requestor_2_resp_bits_gpaddr_0 !== i_io_requestor_2_resp_bits_gpaddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_gpaddr_0 g=%h i=%h", $time, g_io_requestor_2_resp_bits_gpaddr_0, i_io_requestor_2_resp_bits_gpaddr_0); end
    if (!$isunknown(g_io_requestor_2_resp_bits_fullva) && g_io_requestor_2_resp_bits_fullva !== i_io_requestor_2_resp_bits_fullva) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_fullva g=%h i=%h", $time, g_io_requestor_2_resp_bits_fullva, i_io_requestor_2_resp_bits_fullva); end
    if (!$isunknown(g_io_requestor_2_resp_bits_pbmt_0) && g_io_requestor_2_resp_bits_pbmt_0 !== i_io_requestor_2_resp_bits_pbmt_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_pbmt_0 g=%h i=%h", $time, g_io_requestor_2_resp_bits_pbmt_0, i_io_requestor_2_resp_bits_pbmt_0); end
    if (!$isunknown(g_io_requestor_2_resp_bits_miss) && g_io_requestor_2_resp_bits_miss !== i_io_requestor_2_resp_bits_miss) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_miss g=%h i=%h", $time, g_io_requestor_2_resp_bits_miss, i_io_requestor_2_resp_bits_miss); end
    if (!$isunknown(g_io_requestor_2_resp_bits_isForVSnonLeafPTE) && g_io_requestor_2_resp_bits_isForVSnonLeafPTE !== i_io_requestor_2_resp_bits_isForVSnonLeafPTE) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_isForVSnonLeafPTE g=%h i=%h", $time, g_io_requestor_2_resp_bits_isForVSnonLeafPTE, i_io_requestor_2_resp_bits_isForVSnonLeafPTE); end
    if (!$isunknown(g_io_requestor_2_resp_bits_excp_0_vaNeedExt) && g_io_requestor_2_resp_bits_excp_0_vaNeedExt !== i_io_requestor_2_resp_bits_excp_0_vaNeedExt) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_excp_0_vaNeedExt g=%h i=%h", $time, g_io_requestor_2_resp_bits_excp_0_vaNeedExt, i_io_requestor_2_resp_bits_excp_0_vaNeedExt); end
    if (!$isunknown(g_io_requestor_2_resp_bits_excp_0_isHyper) && g_io_requestor_2_resp_bits_excp_0_isHyper !== i_io_requestor_2_resp_bits_excp_0_isHyper) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_excp_0_isHyper g=%h i=%h", $time, g_io_requestor_2_resp_bits_excp_0_isHyper, i_io_requestor_2_resp_bits_excp_0_isHyper); end
    if (!$isunknown(g_io_requestor_2_resp_bits_excp_0_gpf_ld) && g_io_requestor_2_resp_bits_excp_0_gpf_ld !== i_io_requestor_2_resp_bits_excp_0_gpf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_excp_0_gpf_ld g=%h i=%h", $time, g_io_requestor_2_resp_bits_excp_0_gpf_ld, i_io_requestor_2_resp_bits_excp_0_gpf_ld); end
    if (!$isunknown(g_io_requestor_2_resp_bits_excp_0_pf_ld) && g_io_requestor_2_resp_bits_excp_0_pf_ld !== i_io_requestor_2_resp_bits_excp_0_pf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_excp_0_pf_ld g=%h i=%h", $time, g_io_requestor_2_resp_bits_excp_0_pf_ld, i_io_requestor_2_resp_bits_excp_0_pf_ld); end
    if (!$isunknown(g_io_requestor_2_resp_bits_excp_0_af_ld) && g_io_requestor_2_resp_bits_excp_0_af_ld !== i_io_requestor_2_resp_bits_excp_0_af_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_2_resp_bits_excp_0_af_ld g=%h i=%h", $time, g_io_requestor_2_resp_bits_excp_0_af_ld, i_io_requestor_2_resp_bits_excp_0_af_ld); end
    if (!$isunknown(g_io_requestor_3_resp_valid) && g_io_requestor_3_resp_valid !== i_io_requestor_3_resp_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_valid g=%h i=%h", $time, g_io_requestor_3_resp_valid, i_io_requestor_3_resp_valid); end
    if (!$isunknown(g_io_requestor_3_resp_bits_paddr_0) && g_io_requestor_3_resp_bits_paddr_0 !== i_io_requestor_3_resp_bits_paddr_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_paddr_0 g=%h i=%h", $time, g_io_requestor_3_resp_bits_paddr_0, i_io_requestor_3_resp_bits_paddr_0); end
    if (!$isunknown(g_io_requestor_3_resp_bits_pbmt_0) && g_io_requestor_3_resp_bits_pbmt_0 !== i_io_requestor_3_resp_bits_pbmt_0) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_pbmt_0 g=%h i=%h", $time, g_io_requestor_3_resp_bits_pbmt_0, i_io_requestor_3_resp_bits_pbmt_0); end
    if (!$isunknown(g_io_requestor_3_resp_bits_miss) && g_io_requestor_3_resp_bits_miss !== i_io_requestor_3_resp_bits_miss) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_miss g=%h i=%h", $time, g_io_requestor_3_resp_bits_miss, i_io_requestor_3_resp_bits_miss); end
    if (!$isunknown(g_io_requestor_3_resp_bits_excp_0_gpf_ld) && g_io_requestor_3_resp_bits_excp_0_gpf_ld !== i_io_requestor_3_resp_bits_excp_0_gpf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_excp_0_gpf_ld g=%h i=%h", $time, g_io_requestor_3_resp_bits_excp_0_gpf_ld, i_io_requestor_3_resp_bits_excp_0_gpf_ld); end
    if (!$isunknown(g_io_requestor_3_resp_bits_excp_0_pf_ld) && g_io_requestor_3_resp_bits_excp_0_pf_ld !== i_io_requestor_3_resp_bits_excp_0_pf_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_excp_0_pf_ld g=%h i=%h", $time, g_io_requestor_3_resp_bits_excp_0_pf_ld, i_io_requestor_3_resp_bits_excp_0_pf_ld); end
    if (!$isunknown(g_io_requestor_3_resp_bits_excp_0_af_ld) && g_io_requestor_3_resp_bits_excp_0_af_ld !== i_io_requestor_3_resp_bits_excp_0_af_ld) begin errors++;
      if(errors<=80) $display("[%0t] io_requestor_3_resp_bits_excp_0_af_ld g=%h i=%h", $time, g_io_requestor_3_resp_bits_excp_0_af_ld, i_io_requestor_3_resp_bits_excp_0_af_ld); end
    if (!$isunknown(g_io_ptw_req_0_valid) && g_io_ptw_req_0_valid !== i_io_ptw_req_0_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_valid g=%h i=%h", $time, g_io_ptw_req_0_valid, i_io_ptw_req_0_valid); end
    if (!$isunknown(g_io_ptw_req_0_bits_vpn) && g_io_ptw_req_0_bits_vpn !== i_io_ptw_req_0_bits_vpn) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_bits_vpn g=%h i=%h", $time, g_io_ptw_req_0_bits_vpn, i_io_ptw_req_0_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_0_bits_s2xlate) && g_io_ptw_req_0_bits_s2xlate !== i_io_ptw_req_0_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_0_bits_s2xlate, i_io_ptw_req_0_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_req_0_bits_getGpa) && g_io_ptw_req_0_bits_getGpa !== i_io_ptw_req_0_bits_getGpa) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_0_bits_getGpa g=%h i=%h", $time, g_io_ptw_req_0_bits_getGpa, i_io_ptw_req_0_bits_getGpa); end
    if (!$isunknown(g_io_ptw_req_1_valid) && g_io_ptw_req_1_valid !== i_io_ptw_req_1_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_1_valid g=%h i=%h", $time, g_io_ptw_req_1_valid, i_io_ptw_req_1_valid); end
    if (!$isunknown(g_io_ptw_req_1_bits_vpn) && g_io_ptw_req_1_bits_vpn !== i_io_ptw_req_1_bits_vpn) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_1_bits_vpn g=%h i=%h", $time, g_io_ptw_req_1_bits_vpn, i_io_ptw_req_1_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_1_bits_s2xlate) && g_io_ptw_req_1_bits_s2xlate !== i_io_ptw_req_1_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_1_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_1_bits_s2xlate, i_io_ptw_req_1_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_req_1_bits_getGpa) && g_io_ptw_req_1_bits_getGpa !== i_io_ptw_req_1_bits_getGpa) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_1_bits_getGpa g=%h i=%h", $time, g_io_ptw_req_1_bits_getGpa, i_io_ptw_req_1_bits_getGpa); end
    if (!$isunknown(g_io_ptw_req_2_valid) && g_io_ptw_req_2_valid !== i_io_ptw_req_2_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_2_valid g=%h i=%h", $time, g_io_ptw_req_2_valid, i_io_ptw_req_2_valid); end
    if (!$isunknown(g_io_ptw_req_2_bits_vpn) && g_io_ptw_req_2_bits_vpn !== i_io_ptw_req_2_bits_vpn) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_2_bits_vpn g=%h i=%h", $time, g_io_ptw_req_2_bits_vpn, i_io_ptw_req_2_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_2_bits_s2xlate) && g_io_ptw_req_2_bits_s2xlate !== i_io_ptw_req_2_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_2_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_2_bits_s2xlate, i_io_ptw_req_2_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_req_2_bits_getGpa) && g_io_ptw_req_2_bits_getGpa !== i_io_ptw_req_2_bits_getGpa) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_2_bits_getGpa g=%h i=%h", $time, g_io_ptw_req_2_bits_getGpa, i_io_ptw_req_2_bits_getGpa); end
    if (!$isunknown(g_io_ptw_req_3_valid) && g_io_ptw_req_3_valid !== i_io_ptw_req_3_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_3_valid g=%h i=%h", $time, g_io_ptw_req_3_valid, i_io_ptw_req_3_valid); end
    if (!$isunknown(g_io_ptw_req_3_bits_vpn) && g_io_ptw_req_3_bits_vpn !== i_io_ptw_req_3_bits_vpn) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_3_bits_vpn g=%h i=%h", $time, g_io_ptw_req_3_bits_vpn, i_io_ptw_req_3_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_3_bits_s2xlate) && g_io_ptw_req_3_bits_s2xlate !== i_io_ptw_req_3_bits_s2xlate) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_3_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_3_bits_s2xlate, i_io_ptw_req_3_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_req_3_bits_getGpa) && g_io_ptw_req_3_bits_getGpa !== i_io_ptw_req_3_bits_getGpa) begin errors++;
      if(errors<=80) $display("[%0t] io_ptw_req_3_bits_getGpa g=%h i=%h", $time, g_io_ptw_req_3_bits_getGpa, i_io_ptw_req_3_bits_getGpa); end
    if (!$isunknown(g_io_pmp_0_valid) && g_io_pmp_0_valid !== i_io_pmp_0_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_0_valid g=%h i=%h", $time, g_io_pmp_0_valid, i_io_pmp_0_valid); end
    if (!$isunknown(g_io_pmp_0_bits_addr) && g_io_pmp_0_bits_addr !== i_io_pmp_0_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_0_bits_addr g=%h i=%h", $time, g_io_pmp_0_bits_addr, i_io_pmp_0_bits_addr); end
    if (!$isunknown(g_io_pmp_0_bits_cmd) && g_io_pmp_0_bits_cmd !== i_io_pmp_0_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_0_bits_cmd g=%h i=%h", $time, g_io_pmp_0_bits_cmd, i_io_pmp_0_bits_cmd); end
    if (!$isunknown(g_io_pmp_1_valid) && g_io_pmp_1_valid !== i_io_pmp_1_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_1_valid g=%h i=%h", $time, g_io_pmp_1_valid, i_io_pmp_1_valid); end
    if (!$isunknown(g_io_pmp_1_bits_addr) && g_io_pmp_1_bits_addr !== i_io_pmp_1_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_1_bits_addr g=%h i=%h", $time, g_io_pmp_1_bits_addr, i_io_pmp_1_bits_addr); end
    if (!$isunknown(g_io_pmp_1_bits_cmd) && g_io_pmp_1_bits_cmd !== i_io_pmp_1_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_1_bits_cmd g=%h i=%h", $time, g_io_pmp_1_bits_cmd, i_io_pmp_1_bits_cmd); end
    if (!$isunknown(g_io_pmp_2_valid) && g_io_pmp_2_valid !== i_io_pmp_2_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_2_valid g=%h i=%h", $time, g_io_pmp_2_valid, i_io_pmp_2_valid); end
    if (!$isunknown(g_io_pmp_2_bits_addr) && g_io_pmp_2_bits_addr !== i_io_pmp_2_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_2_bits_addr g=%h i=%h", $time, g_io_pmp_2_bits_addr, i_io_pmp_2_bits_addr); end
    if (!$isunknown(g_io_pmp_2_bits_cmd) && g_io_pmp_2_bits_cmd !== i_io_pmp_2_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_2_bits_cmd g=%h i=%h", $time, g_io_pmp_2_bits_cmd, i_io_pmp_2_bits_cmd); end
    if (!$isunknown(g_io_pmp_3_valid) && g_io_pmp_3_valid !== i_io_pmp_3_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_3_valid g=%h i=%h", $time, g_io_pmp_3_valid, i_io_pmp_3_valid); end
    if (!$isunknown(g_io_pmp_3_bits_addr) && g_io_pmp_3_bits_addr !== i_io_pmp_3_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_3_bits_addr g=%h i=%h", $time, g_io_pmp_3_bits_addr, i_io_pmp_3_bits_addr); end
    if (!$isunknown(g_io_pmp_3_bits_cmd) && g_io_pmp_3_bits_cmd !== i_io_pmp_3_bits_cmd) begin errors++;
      if(errors<=80) $display("[%0t] io_pmp_3_bits_cmd g=%h i=%h", $time, g_io_pmp_3_bits_cmd, i_io_pmp_3_bits_cmd); end
    if (!$isunknown(g_io_tlbreplay_0) && g_io_tlbreplay_0 !== i_io_tlbreplay_0) begin errors++;
      if(errors<=80) $display("[%0t] io_tlbreplay_0 g=%h i=%h", $time, g_io_tlbreplay_0, i_io_tlbreplay_0); end
    if (!$isunknown(g_io_tlbreplay_1) && g_io_tlbreplay_1 !== i_io_tlbreplay_1) begin errors++;
      if(errors<=80) $display("[%0t] io_tlbreplay_1 g=%h i=%h", $time, g_io_tlbreplay_1, i_io_tlbreplay_1); end
    if (!$isunknown(g_io_tlbreplay_2) && g_io_tlbreplay_2 !== i_io_tlbreplay_2) begin errors++;
      if(errors<=80) $display("[%0t] io_tlbreplay_2 g=%h i=%h", $time, g_io_tlbreplay_2, i_io_tlbreplay_2); end
    if (!$isunknown(g_io_tlbreplay_3) && g_io_tlbreplay_3 !== i_io_tlbreplay_3) begin errors++;
      if(errors<=80) $display("[%0t] io_tlbreplay_3 g=%h i=%h", $time, g_io_tlbreplay_3, i_io_tlbreplay_3); end
  end

  int pe_need_gpa_vpn=0, pe_REG=0, pe_pfld=0, pe_afld=0, pe_pfst=0;
  always @(negedge clk) if (!rst) begin #4;
    if (!$isunknown(u_g.need_gpa_vpn) && u_g.need_gpa_vpn !== u_i.u_core.need_gpa_vpn) pe_need_gpa_vpn++;
    if (!$isunknown(u_g.REG) && u_g.REG !== u_i.u_core.REG_pre[0]) pe_REG++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_pf_ld_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_pf_ld_REG !== u_i.u_core.excp_pf_ld_REG[0]) pe_pfld++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_af_ld_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_af_ld_REG !== u_i.u_core.excp_af_ld_REG[0]) pe_afld++;
    if (!$isunknown(u_g.io_requestor_0_resp_bits_excp_0_pf_st_REG)
        && u_g.io_requestor_0_resp_bits_excp_0_pf_st_REG !== u_i.u_core.excp_pf_st_REG[0]) pe_pfst++;
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("PROBE need_gpa_vpn=%0d REG=%0d pf_ld=%0d af_ld=%0d pf_st=%0d",
             pe_need_gpa_vpn, pe_REG, pe_pfld, pe_afld, pe_pfst);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
