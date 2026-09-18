// 由 verif/ut/TLBNonBlock/gen_tb.py 生成，勿手改。golden TLBNonBlock 与重写 TLBNonBlock_xs
// 同激励双例化，逐拍比全部 94 个输出。
`timescale 1ns/1ps
module tb;
  localparam int POOL_N = 8;
  reg clock = 1'b0;
  reg reset = 1'b1;
  always #5 clock = ~clock;

  // 激励池：让 refill 与查询打在同一批 vpn 上，命中路径才有覆盖
  reg [37:0] vpn_pool  [POOL_N];
  reg [2:0]  cmd_pool  [4];
  reg [3:0]  mode_pool [3];
  reg [15:0] asid_pool [4];
  reg [15:0] vmid_pool [4];
  reg [1:0]  priv_pool [3];

  reg io_sfence_valid;
  reg io_sfence_bits_rs1;
  reg io_sfence_bits_rs2;
  reg [49:0] io_sfence_bits_addr;
  reg [15:0] io_sfence_bits_id;
  reg io_sfence_bits_flushPipe;
  reg io_sfence_bits_hv;
  reg io_sfence_bits_hg;
  reg [3:0] io_csr_satp_mode;
  reg [15:0] io_csr_satp_asid;
  reg [43:0] io_csr_satp_ppn;
  reg io_csr_satp_changed;
  reg [3:0] io_csr_vsatp_mode;
  reg [15:0] io_csr_vsatp_asid;
  reg [43:0] io_csr_vsatp_ppn;
  reg io_csr_vsatp_changed;
  reg [3:0] io_csr_hgatp_mode;
  reg [15:0] io_csr_hgatp_vmid;
  reg [43:0] io_csr_hgatp_ppn;
  reg io_csr_hgatp_changed;
  reg io_csr_mbmc_BME;
  reg io_csr_mbmc_CMODE;
  reg io_csr_priv_mxr;
  reg io_csr_priv_sum;
  reg io_csr_priv_vmxr;
  reg io_csr_priv_vsum;
  reg io_csr_priv_virt;
  reg io_csr_priv_virt_changed;
  reg io_csr_priv_spvp;
  reg [1:0] io_csr_priv_imode;
  reg [1:0] io_csr_priv_dmode;
  reg io_csr_priv_debug;
  reg [1:0] io_csr_pmm_mseccfg;
  reg [1:0] io_csr_pmm_menvcfg;
  reg [1:0] io_csr_pmm_henvcfg;
  reg [1:0] io_csr_pmm_hstatus;
  reg [1:0] io_csr_pmm_senvcfg;
  reg [5:0] io_hartId;
  reg io_requestor_0_req_valid;
  reg [49:0] io_requestor_0_req_bits_vaddr;
  reg [63:0] io_requestor_0_req_bits_fullva;
  reg io_requestor_0_req_bits_checkfullva;
  reg [2:0] io_requestor_0_req_bits_cmd;
  reg io_requestor_0_req_bits_hyperinst;
  reg io_requestor_0_req_bits_hlvx;
  reg io_requestor_0_req_bits_kill;
  reg io_requestor_0_req_bits_isPrefetch;
  reg io_requestor_0_req_bits_no_translate;
  reg [47:0] io_requestor_0_req_bits_pmp_addr;
  reg io_requestor_0_req_bits_frm_mabuf;
  reg io_requestor_0_req_bits_debug_robIdx_flag;
  reg [7:0] io_requestor_0_req_bits_debug_robIdx_value;
  reg io_requestor_0_req_bits_debug_isFirstIssue;
  reg io_requestor_0_req_kill;
  reg io_requestor_1_req_valid;
  reg [49:0] io_requestor_1_req_bits_vaddr;
  reg [63:0] io_requestor_1_req_bits_fullva;
  reg io_requestor_1_req_bits_checkfullva;
  reg [2:0] io_requestor_1_req_bits_cmd;
  reg io_requestor_1_req_bits_hyperinst;
  reg io_requestor_1_req_bits_hlvx;
  reg io_requestor_1_req_bits_kill;
  reg io_requestor_1_req_bits_isPrefetch;
  reg io_requestor_1_req_bits_no_translate;
  reg [47:0] io_requestor_1_req_bits_pmp_addr;
  reg io_requestor_1_req_bits_frm_mabuf;
  reg io_requestor_1_req_bits_debug_robIdx_flag;
  reg [7:0] io_requestor_1_req_bits_debug_robIdx_value;
  reg io_requestor_1_req_bits_debug_isFirstIssue;
  reg io_requestor_1_req_kill;
  reg io_requestor_2_req_valid;
  reg [49:0] io_requestor_2_req_bits_vaddr;
  reg [63:0] io_requestor_2_req_bits_fullva;
  reg io_requestor_2_req_bits_checkfullva;
  reg [2:0] io_requestor_2_req_bits_cmd;
  reg io_requestor_2_req_bits_hyperinst;
  reg io_requestor_2_req_bits_hlvx;
  reg io_requestor_2_req_bits_kill;
  reg io_requestor_2_req_bits_isPrefetch;
  reg io_requestor_2_req_bits_no_translate;
  reg [47:0] io_requestor_2_req_bits_pmp_addr;
  reg io_requestor_2_req_bits_frm_mabuf;
  reg io_requestor_2_req_bits_debug_robIdx_flag;
  reg [7:0] io_requestor_2_req_bits_debug_robIdx_value;
  reg io_requestor_2_req_bits_debug_isFirstIssue;
  reg io_requestor_2_req_kill;
  reg io_requestor_3_req_valid;
  reg [49:0] io_requestor_3_req_bits_vaddr;
  reg [63:0] io_requestor_3_req_bits_fullva;
  reg io_requestor_3_req_bits_checkfullva;
  reg [2:0] io_requestor_3_req_bits_cmd;
  reg io_requestor_3_req_bits_hyperinst;
  reg io_requestor_3_req_bits_hlvx;
  reg io_requestor_3_req_bits_kill;
  reg io_requestor_3_req_bits_isPrefetch;
  reg io_requestor_3_req_bits_no_translate;
  reg [47:0] io_requestor_3_req_bits_pmp_addr;
  reg io_requestor_3_req_bits_frm_mabuf;
  reg io_requestor_3_req_bits_debug_robIdx_flag;
  reg [7:0] io_requestor_3_req_bits_debug_robIdx_value;
  reg io_requestor_3_req_bits_debug_isFirstIssue;
  reg io_redirect_valid;
  reg io_redirect_bits_robIdx_flag;
  reg [7:0] io_redirect_bits_robIdx_value;
  reg io_redirect_bits_level;
  reg io_ptw_resp_valid;
  reg [1:0] io_ptw_resp_bits_s2xlate;
  reg [34:0] io_ptw_resp_bits_s1_entry_tag;
  reg [15:0] io_ptw_resp_bits_s1_entry_asid;
  reg [13:0] io_ptw_resp_bits_s1_entry_vmid;
  reg io_ptw_resp_bits_s1_entry_n;
  reg [1:0] io_ptw_resp_bits_s1_entry_pbmt;
  reg io_ptw_resp_bits_s1_entry_perm_d;
  reg io_ptw_resp_bits_s1_entry_perm_a;
  reg io_ptw_resp_bits_s1_entry_perm_g;
  reg io_ptw_resp_bits_s1_entry_perm_u;
  reg io_ptw_resp_bits_s1_entry_perm_x;
  reg io_ptw_resp_bits_s1_entry_perm_w;
  reg io_ptw_resp_bits_s1_entry_perm_r;
  reg [1:0] io_ptw_resp_bits_s1_entry_level;
  reg io_ptw_resp_bits_s1_entry_v;
  reg [40:0] io_ptw_resp_bits_s1_entry_ppn;
  reg [2:0] io_ptw_resp_bits_s1_addr_low;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_0;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_1;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_2;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_3;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_4;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_5;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_6;
  reg [2:0] io_ptw_resp_bits_s1_ppn_low_7;
  reg io_ptw_resp_bits_s1_valididx_0;
  reg io_ptw_resp_bits_s1_valididx_1;
  reg io_ptw_resp_bits_s1_valididx_2;
  reg io_ptw_resp_bits_s1_valididx_3;
  reg io_ptw_resp_bits_s1_valididx_4;
  reg io_ptw_resp_bits_s1_valididx_5;
  reg io_ptw_resp_bits_s1_valididx_6;
  reg io_ptw_resp_bits_s1_valididx_7;
  reg io_ptw_resp_bits_s1_pteidx_0;
  reg io_ptw_resp_bits_s1_pteidx_1;
  reg io_ptw_resp_bits_s1_pteidx_2;
  reg io_ptw_resp_bits_s1_pteidx_3;
  reg io_ptw_resp_bits_s1_pteidx_4;
  reg io_ptw_resp_bits_s1_pteidx_5;
  reg io_ptw_resp_bits_s1_pteidx_6;
  reg io_ptw_resp_bits_s1_pteidx_7;
  reg io_ptw_resp_bits_s1_pf;
  reg io_ptw_resp_bits_s1_af;
  reg [37:0] io_ptw_resp_bits_s2_entry_tag;
  reg [13:0] io_ptw_resp_bits_s2_entry_vmid;
  reg io_ptw_resp_bits_s2_entry_n;
  reg [1:0] io_ptw_resp_bits_s2_entry_pbmt;
  reg [37:0] io_ptw_resp_bits_s2_entry_ppn;
  reg io_ptw_resp_bits_s2_entry_perm_d;
  reg io_ptw_resp_bits_s2_entry_perm_a;
  reg io_ptw_resp_bits_s2_entry_perm_g;
  reg io_ptw_resp_bits_s2_entry_perm_u;
  reg io_ptw_resp_bits_s2_entry_perm_x;
  reg io_ptw_resp_bits_s2_entry_perm_w;
  reg io_ptw_resp_bits_s2_entry_perm_r;
  reg [1:0] io_ptw_resp_bits_s2_entry_level;
  reg io_ptw_resp_bits_s2_gpf;
  reg io_ptw_resp_bits_s2_gaf;
  reg io_ptw_resp_bits_getGpa;
  reg io_robPendingPtr_flag;
  reg [7:0] io_robPendingPtr_value;

  wire io_requestor_0_resp_valid_g, io_requestor_0_resp_valid_x;
  wire [47:0] io_requestor_0_resp_bits_paddr_0_g, io_requestor_0_resp_bits_paddr_0_x;
  wire [47:0] io_requestor_0_resp_bits_paddr_1_g, io_requestor_0_resp_bits_paddr_1_x;
  wire [63:0] io_requestor_0_resp_bits_gpaddr_0_g, io_requestor_0_resp_bits_gpaddr_0_x;
  wire [63:0] io_requestor_0_resp_bits_fullva_g, io_requestor_0_resp_bits_fullva_x;
  wire [1:0] io_requestor_0_resp_bits_pbmt_0_g, io_requestor_0_resp_bits_pbmt_0_x;
  wire io_requestor_0_resp_bits_miss_g, io_requestor_0_resp_bits_miss_x;
  wire io_requestor_0_resp_bits_isForVSnonLeafPTE_g, io_requestor_0_resp_bits_isForVSnonLeafPTE_x;
  wire io_requestor_0_resp_bits_excp_0_vaNeedExt_g, io_requestor_0_resp_bits_excp_0_vaNeedExt_x;
  wire io_requestor_0_resp_bits_excp_0_isHyper_g, io_requestor_0_resp_bits_excp_0_isHyper_x;
  wire io_requestor_0_resp_bits_excp_0_gpf_ld_g, io_requestor_0_resp_bits_excp_0_gpf_ld_x;
  wire io_requestor_0_resp_bits_excp_0_gpf_st_g, io_requestor_0_resp_bits_excp_0_gpf_st_x;
  wire io_requestor_0_resp_bits_excp_0_pf_ld_g, io_requestor_0_resp_bits_excp_0_pf_ld_x;
  wire io_requestor_0_resp_bits_excp_0_pf_st_g, io_requestor_0_resp_bits_excp_0_pf_st_x;
  wire io_requestor_0_resp_bits_excp_0_af_ld_g, io_requestor_0_resp_bits_excp_0_af_ld_x;
  wire io_requestor_0_resp_bits_excp_0_af_st_g, io_requestor_0_resp_bits_excp_0_af_st_x;
  wire io_requestor_0_resp_bits_ptwBack_g, io_requestor_0_resp_bits_ptwBack_x;
  wire io_requestor_1_resp_valid_g, io_requestor_1_resp_valid_x;
  wire [47:0] io_requestor_1_resp_bits_paddr_0_g, io_requestor_1_resp_bits_paddr_0_x;
  wire [47:0] io_requestor_1_resp_bits_paddr_1_g, io_requestor_1_resp_bits_paddr_1_x;
  wire [63:0] io_requestor_1_resp_bits_gpaddr_0_g, io_requestor_1_resp_bits_gpaddr_0_x;
  wire [63:0] io_requestor_1_resp_bits_fullva_g, io_requestor_1_resp_bits_fullva_x;
  wire [1:0] io_requestor_1_resp_bits_pbmt_0_g, io_requestor_1_resp_bits_pbmt_0_x;
  wire io_requestor_1_resp_bits_miss_g, io_requestor_1_resp_bits_miss_x;
  wire io_requestor_1_resp_bits_isForVSnonLeafPTE_g, io_requestor_1_resp_bits_isForVSnonLeafPTE_x;
  wire io_requestor_1_resp_bits_excp_0_vaNeedExt_g, io_requestor_1_resp_bits_excp_0_vaNeedExt_x;
  wire io_requestor_1_resp_bits_excp_0_isHyper_g, io_requestor_1_resp_bits_excp_0_isHyper_x;
  wire io_requestor_1_resp_bits_excp_0_gpf_ld_g, io_requestor_1_resp_bits_excp_0_gpf_ld_x;
  wire io_requestor_1_resp_bits_excp_0_pf_ld_g, io_requestor_1_resp_bits_excp_0_pf_ld_x;
  wire io_requestor_1_resp_bits_excp_0_af_ld_g, io_requestor_1_resp_bits_excp_0_af_ld_x;
  wire io_requestor_1_resp_bits_ptwBack_g, io_requestor_1_resp_bits_ptwBack_x;
  wire io_requestor_2_resp_valid_g, io_requestor_2_resp_valid_x;
  wire [47:0] io_requestor_2_resp_bits_paddr_0_g, io_requestor_2_resp_bits_paddr_0_x;
  wire [47:0] io_requestor_2_resp_bits_paddr_1_g, io_requestor_2_resp_bits_paddr_1_x;
  wire [63:0] io_requestor_2_resp_bits_gpaddr_0_g, io_requestor_2_resp_bits_gpaddr_0_x;
  wire [63:0] io_requestor_2_resp_bits_fullva_g, io_requestor_2_resp_bits_fullva_x;
  wire [1:0] io_requestor_2_resp_bits_pbmt_0_g, io_requestor_2_resp_bits_pbmt_0_x;
  wire io_requestor_2_resp_bits_miss_g, io_requestor_2_resp_bits_miss_x;
  wire io_requestor_2_resp_bits_isForVSnonLeafPTE_g, io_requestor_2_resp_bits_isForVSnonLeafPTE_x;
  wire io_requestor_2_resp_bits_excp_0_vaNeedExt_g, io_requestor_2_resp_bits_excp_0_vaNeedExt_x;
  wire io_requestor_2_resp_bits_excp_0_isHyper_g, io_requestor_2_resp_bits_excp_0_isHyper_x;
  wire io_requestor_2_resp_bits_excp_0_gpf_ld_g, io_requestor_2_resp_bits_excp_0_gpf_ld_x;
  wire io_requestor_2_resp_bits_excp_0_pf_ld_g, io_requestor_2_resp_bits_excp_0_pf_ld_x;
  wire io_requestor_2_resp_bits_excp_0_af_ld_g, io_requestor_2_resp_bits_excp_0_af_ld_x;
  wire io_requestor_2_resp_bits_ptwBack_g, io_requestor_2_resp_bits_ptwBack_x;
  wire io_requestor_3_resp_valid_g, io_requestor_3_resp_valid_x;
  wire [47:0] io_requestor_3_resp_bits_paddr_0_g, io_requestor_3_resp_bits_paddr_0_x;
  wire [1:0] io_requestor_3_resp_bits_pbmt_0_g, io_requestor_3_resp_bits_pbmt_0_x;
  wire io_requestor_3_resp_bits_miss_g, io_requestor_3_resp_bits_miss_x;
  wire io_requestor_3_resp_bits_excp_0_gpf_ld_g, io_requestor_3_resp_bits_excp_0_gpf_ld_x;
  wire io_requestor_3_resp_bits_excp_0_pf_ld_g, io_requestor_3_resp_bits_excp_0_pf_ld_x;
  wire io_requestor_3_resp_bits_excp_0_af_ld_g, io_requestor_3_resp_bits_excp_0_af_ld_x;
  wire io_ptw_req_0_valid_g, io_ptw_req_0_valid_x;
  wire [37:0] io_ptw_req_0_bits_vpn_g, io_ptw_req_0_bits_vpn_x;
  wire [1:0] io_ptw_req_0_bits_s2xlate_g, io_ptw_req_0_bits_s2xlate_x;
  wire io_ptw_req_0_bits_getGpa_g, io_ptw_req_0_bits_getGpa_x;
  wire io_ptw_req_1_valid_g, io_ptw_req_1_valid_x;
  wire [37:0] io_ptw_req_1_bits_vpn_g, io_ptw_req_1_bits_vpn_x;
  wire [1:0] io_ptw_req_1_bits_s2xlate_g, io_ptw_req_1_bits_s2xlate_x;
  wire io_ptw_req_1_bits_getGpa_g, io_ptw_req_1_bits_getGpa_x;
  wire io_ptw_req_2_valid_g, io_ptw_req_2_valid_x;
  wire [37:0] io_ptw_req_2_bits_vpn_g, io_ptw_req_2_bits_vpn_x;
  wire [1:0] io_ptw_req_2_bits_s2xlate_g, io_ptw_req_2_bits_s2xlate_x;
  wire io_ptw_req_2_bits_getGpa_g, io_ptw_req_2_bits_getGpa_x;
  wire io_ptw_req_3_valid_g, io_ptw_req_3_valid_x;
  wire [37:0] io_ptw_req_3_bits_vpn_g, io_ptw_req_3_bits_vpn_x;
  wire [1:0] io_ptw_req_3_bits_s2xlate_g, io_ptw_req_3_bits_s2xlate_x;
  wire io_ptw_req_3_bits_getGpa_g, io_ptw_req_3_bits_getGpa_x;
  wire io_pmp_0_valid_g, io_pmp_0_valid_x;
  wire [47:0] io_pmp_0_bits_addr_g, io_pmp_0_bits_addr_x;
  wire [2:0] io_pmp_0_bits_cmd_g, io_pmp_0_bits_cmd_x;
  wire io_pmp_1_valid_g, io_pmp_1_valid_x;
  wire [47:0] io_pmp_1_bits_addr_g, io_pmp_1_bits_addr_x;
  wire [2:0] io_pmp_1_bits_cmd_g, io_pmp_1_bits_cmd_x;
  wire io_pmp_2_valid_g, io_pmp_2_valid_x;
  wire [47:0] io_pmp_2_bits_addr_g, io_pmp_2_bits_addr_x;
  wire [2:0] io_pmp_2_bits_cmd_g, io_pmp_2_bits_cmd_x;
  wire io_pmp_3_valid_g, io_pmp_3_valid_x;
  wire [47:0] io_pmp_3_bits_addr_g, io_pmp_3_bits_addr_x;
  wire [2:0] io_pmp_3_bits_cmd_g, io_pmp_3_bits_cmd_x;
  wire [1:0] io_pmpMode_0_g, io_pmpMode_0_x;
  wire [1:0] io_pmpMode_1_g, io_pmpMode_1_x;
  wire [1:0] io_pmpMode_2_g, io_pmpMode_2_x;
  wire [1:0] io_pmpMode_3_g, io_pmpMode_3_x;
  wire io_tlbreplay_0_g, io_tlbreplay_0_x;
  wire io_tlbreplay_1_g, io_tlbreplay_1_x;
  wire io_tlbreplay_2_g, io_tlbreplay_2_x;
  wire io_tlbreplay_3_g, io_tlbreplay_3_x;
  wire [5:0] io_perf_0_value_g, io_perf_0_value_x;
  wire [5:0] io_perf_1_value_g, io_perf_1_value_x;
  wire [338:0] gatewayIn_packed_53_bore_g, gatewayIn_packed_53_bore_x;
  wire [338:0] gatewayIn_packed_54_bore_g, gatewayIn_packed_54_bore_x;
  wire [338:0] gatewayIn_packed_55_bore_g, gatewayIn_packed_55_bore_x;
  wire [338:0] gatewayIn_packed_56_bore_g, gatewayIn_packed_56_bore_x;

  TLBNonBlock dut_g (
    .clock (clock), .reset (reset),
    .io_sfence_valid (io_sfence_valid),
    .io_sfence_bits_rs1 (io_sfence_bits_rs1),
    .io_sfence_bits_rs2 (io_sfence_bits_rs2),
    .io_sfence_bits_addr (io_sfence_bits_addr),
    .io_sfence_bits_id (io_sfence_bits_id),
    .io_sfence_bits_flushPipe (io_sfence_bits_flushPipe),
    .io_sfence_bits_hv (io_sfence_bits_hv),
    .io_sfence_bits_hg (io_sfence_bits_hg),
    .io_csr_satp_mode (io_csr_satp_mode),
    .io_csr_satp_asid (io_csr_satp_asid),
    .io_csr_satp_ppn (io_csr_satp_ppn),
    .io_csr_satp_changed (io_csr_satp_changed),
    .io_csr_vsatp_mode (io_csr_vsatp_mode),
    .io_csr_vsatp_asid (io_csr_vsatp_asid),
    .io_csr_vsatp_ppn (io_csr_vsatp_ppn),
    .io_csr_vsatp_changed (io_csr_vsatp_changed),
    .io_csr_hgatp_mode (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid (io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn (io_csr_hgatp_ppn),
    .io_csr_hgatp_changed (io_csr_hgatp_changed),
    .io_csr_mbmc_BME (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE (io_csr_mbmc_CMODE),
    .io_csr_priv_mxr (io_csr_priv_mxr),
    .io_csr_priv_sum (io_csr_priv_sum),
    .io_csr_priv_vmxr (io_csr_priv_vmxr),
    .io_csr_priv_vsum (io_csr_priv_vsum),
    .io_csr_priv_virt (io_csr_priv_virt),
    .io_csr_priv_virt_changed (io_csr_priv_virt_changed),
    .io_csr_priv_spvp (io_csr_priv_spvp),
    .io_csr_priv_imode (io_csr_priv_imode),
    .io_csr_priv_dmode (io_csr_priv_dmode),
    .io_csr_priv_debug (io_csr_priv_debug),
    .io_csr_pmm_mseccfg (io_csr_pmm_mseccfg),
    .io_csr_pmm_menvcfg (io_csr_pmm_menvcfg),
    .io_csr_pmm_henvcfg (io_csr_pmm_henvcfg),
    .io_csr_pmm_hstatus (io_csr_pmm_hstatus),
    .io_csr_pmm_senvcfg (io_csr_pmm_senvcfg),
    .io_hartId (io_hartId),
    .io_requestor_0_req_valid (io_requestor_0_req_valid),
    .io_requestor_0_req_bits_vaddr (io_requestor_0_req_bits_vaddr),
    .io_requestor_0_req_bits_fullva (io_requestor_0_req_bits_fullva),
    .io_requestor_0_req_bits_checkfullva (io_requestor_0_req_bits_checkfullva),
    .io_requestor_0_req_bits_cmd (io_requestor_0_req_bits_cmd),
    .io_requestor_0_req_bits_hyperinst (io_requestor_0_req_bits_hyperinst),
    .io_requestor_0_req_bits_hlvx (io_requestor_0_req_bits_hlvx),
    .io_requestor_0_req_bits_kill (io_requestor_0_req_bits_kill),
    .io_requestor_0_req_bits_isPrefetch (io_requestor_0_req_bits_isPrefetch),
    .io_requestor_0_req_bits_no_translate (io_requestor_0_req_bits_no_translate),
    .io_requestor_0_req_bits_pmp_addr (io_requestor_0_req_bits_pmp_addr),
    .io_requestor_0_req_bits_frm_mabuf (io_requestor_0_req_bits_frm_mabuf),
    .io_requestor_0_req_bits_debug_robIdx_flag (io_requestor_0_req_bits_debug_robIdx_flag),
    .io_requestor_0_req_bits_debug_robIdx_value (io_requestor_0_req_bits_debug_robIdx_value),
    .io_requestor_0_req_bits_debug_isFirstIssue (io_requestor_0_req_bits_debug_isFirstIssue),
    .io_requestor_0_req_kill (io_requestor_0_req_kill),
    .io_requestor_1_req_valid (io_requestor_1_req_valid),
    .io_requestor_1_req_bits_vaddr (io_requestor_1_req_bits_vaddr),
    .io_requestor_1_req_bits_fullva (io_requestor_1_req_bits_fullva),
    .io_requestor_1_req_bits_checkfullva (io_requestor_1_req_bits_checkfullva),
    .io_requestor_1_req_bits_cmd (io_requestor_1_req_bits_cmd),
    .io_requestor_1_req_bits_hyperinst (io_requestor_1_req_bits_hyperinst),
    .io_requestor_1_req_bits_hlvx (io_requestor_1_req_bits_hlvx),
    .io_requestor_1_req_bits_kill (io_requestor_1_req_bits_kill),
    .io_requestor_1_req_bits_isPrefetch (io_requestor_1_req_bits_isPrefetch),
    .io_requestor_1_req_bits_no_translate (io_requestor_1_req_bits_no_translate),
    .io_requestor_1_req_bits_pmp_addr (io_requestor_1_req_bits_pmp_addr),
    .io_requestor_1_req_bits_frm_mabuf (io_requestor_1_req_bits_frm_mabuf),
    .io_requestor_1_req_bits_debug_robIdx_flag (io_requestor_1_req_bits_debug_robIdx_flag),
    .io_requestor_1_req_bits_debug_robIdx_value (io_requestor_1_req_bits_debug_robIdx_value),
    .io_requestor_1_req_bits_debug_isFirstIssue (io_requestor_1_req_bits_debug_isFirstIssue),
    .io_requestor_1_req_kill (io_requestor_1_req_kill),
    .io_requestor_2_req_valid (io_requestor_2_req_valid),
    .io_requestor_2_req_bits_vaddr (io_requestor_2_req_bits_vaddr),
    .io_requestor_2_req_bits_fullva (io_requestor_2_req_bits_fullva),
    .io_requestor_2_req_bits_checkfullva (io_requestor_2_req_bits_checkfullva),
    .io_requestor_2_req_bits_cmd (io_requestor_2_req_bits_cmd),
    .io_requestor_2_req_bits_hyperinst (io_requestor_2_req_bits_hyperinst),
    .io_requestor_2_req_bits_hlvx (io_requestor_2_req_bits_hlvx),
    .io_requestor_2_req_bits_kill (io_requestor_2_req_bits_kill),
    .io_requestor_2_req_bits_isPrefetch (io_requestor_2_req_bits_isPrefetch),
    .io_requestor_2_req_bits_no_translate (io_requestor_2_req_bits_no_translate),
    .io_requestor_2_req_bits_pmp_addr (io_requestor_2_req_bits_pmp_addr),
    .io_requestor_2_req_bits_frm_mabuf (io_requestor_2_req_bits_frm_mabuf),
    .io_requestor_2_req_bits_debug_robIdx_flag (io_requestor_2_req_bits_debug_robIdx_flag),
    .io_requestor_2_req_bits_debug_robIdx_value (io_requestor_2_req_bits_debug_robIdx_value),
    .io_requestor_2_req_bits_debug_isFirstIssue (io_requestor_2_req_bits_debug_isFirstIssue),
    .io_requestor_2_req_kill (io_requestor_2_req_kill),
    .io_requestor_3_req_valid (io_requestor_3_req_valid),
    .io_requestor_3_req_bits_vaddr (io_requestor_3_req_bits_vaddr),
    .io_requestor_3_req_bits_fullva (io_requestor_3_req_bits_fullva),
    .io_requestor_3_req_bits_checkfullva (io_requestor_3_req_bits_checkfullva),
    .io_requestor_3_req_bits_cmd (io_requestor_3_req_bits_cmd),
    .io_requestor_3_req_bits_hyperinst (io_requestor_3_req_bits_hyperinst),
    .io_requestor_3_req_bits_hlvx (io_requestor_3_req_bits_hlvx),
    .io_requestor_3_req_bits_kill (io_requestor_3_req_bits_kill),
    .io_requestor_3_req_bits_isPrefetch (io_requestor_3_req_bits_isPrefetch),
    .io_requestor_3_req_bits_no_translate (io_requestor_3_req_bits_no_translate),
    .io_requestor_3_req_bits_pmp_addr (io_requestor_3_req_bits_pmp_addr),
    .io_requestor_3_req_bits_frm_mabuf (io_requestor_3_req_bits_frm_mabuf),
    .io_requestor_3_req_bits_debug_robIdx_flag (io_requestor_3_req_bits_debug_robIdx_flag),
    .io_requestor_3_req_bits_debug_robIdx_value (io_requestor_3_req_bits_debug_robIdx_value),
    .io_requestor_3_req_bits_debug_isFirstIssue (io_requestor_3_req_bits_debug_isFirstIssue),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_ptw_resp_valid (io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate (io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag (io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid (io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid (io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n (io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt (io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d (io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a (io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g (io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u (io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x (io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w (io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r (io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level (io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v (io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn (io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low (io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0 (io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1 (io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2 (io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3 (io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4 (io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5 (io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6 (io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7 (io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0 (io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1 (io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2 (io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3 (io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4 (io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5 (io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6 (io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7 (io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0 (io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1 (io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2 (io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3 (io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4 (io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5 (io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6 (io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7 (io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf (io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af (io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag (io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid (io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n (io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt (io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn (io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d (io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a (io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g (io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u (io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x (io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w (io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r (io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level (io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf (io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf (io_ptw_resp_bits_s2_gaf),
    .io_ptw_resp_bits_getGpa (io_ptw_resp_bits_getGpa),
    .io_robPendingPtr_flag (io_robPendingPtr_flag),
    .io_robPendingPtr_value (io_robPendingPtr_value),
    .io_requestor_0_resp_valid (io_requestor_0_resp_valid_g),
    .io_requestor_0_resp_bits_paddr_0 (io_requestor_0_resp_bits_paddr_0_g),
    .io_requestor_0_resp_bits_paddr_1 (io_requestor_0_resp_bits_paddr_1_g),
    .io_requestor_0_resp_bits_gpaddr_0 (io_requestor_0_resp_bits_gpaddr_0_g),
    .io_requestor_0_resp_bits_fullva (io_requestor_0_resp_bits_fullva_g),
    .io_requestor_0_resp_bits_pbmt_0 (io_requestor_0_resp_bits_pbmt_0_g),
    .io_requestor_0_resp_bits_miss (io_requestor_0_resp_bits_miss_g),
    .io_requestor_0_resp_bits_isForVSnonLeafPTE (io_requestor_0_resp_bits_isForVSnonLeafPTE_g),
    .io_requestor_0_resp_bits_excp_0_vaNeedExt (io_requestor_0_resp_bits_excp_0_vaNeedExt_g),
    .io_requestor_0_resp_bits_excp_0_isHyper (io_requestor_0_resp_bits_excp_0_isHyper_g),
    .io_requestor_0_resp_bits_excp_0_gpf_ld (io_requestor_0_resp_bits_excp_0_gpf_ld_g),
    .io_requestor_0_resp_bits_excp_0_gpf_st (io_requestor_0_resp_bits_excp_0_gpf_st_g),
    .io_requestor_0_resp_bits_excp_0_pf_ld (io_requestor_0_resp_bits_excp_0_pf_ld_g),
    .io_requestor_0_resp_bits_excp_0_pf_st (io_requestor_0_resp_bits_excp_0_pf_st_g),
    .io_requestor_0_resp_bits_excp_0_af_ld (io_requestor_0_resp_bits_excp_0_af_ld_g),
    .io_requestor_0_resp_bits_excp_0_af_st (io_requestor_0_resp_bits_excp_0_af_st_g),
    .io_requestor_0_resp_bits_ptwBack (io_requestor_0_resp_bits_ptwBack_g),
    .io_requestor_1_resp_valid (io_requestor_1_resp_valid_g),
    .io_requestor_1_resp_bits_paddr_0 (io_requestor_1_resp_bits_paddr_0_g),
    .io_requestor_1_resp_bits_paddr_1 (io_requestor_1_resp_bits_paddr_1_g),
    .io_requestor_1_resp_bits_gpaddr_0 (io_requestor_1_resp_bits_gpaddr_0_g),
    .io_requestor_1_resp_bits_fullva (io_requestor_1_resp_bits_fullva_g),
    .io_requestor_1_resp_bits_pbmt_0 (io_requestor_1_resp_bits_pbmt_0_g),
    .io_requestor_1_resp_bits_miss (io_requestor_1_resp_bits_miss_g),
    .io_requestor_1_resp_bits_isForVSnonLeafPTE (io_requestor_1_resp_bits_isForVSnonLeafPTE_g),
    .io_requestor_1_resp_bits_excp_0_vaNeedExt (io_requestor_1_resp_bits_excp_0_vaNeedExt_g),
    .io_requestor_1_resp_bits_excp_0_isHyper (io_requestor_1_resp_bits_excp_0_isHyper_g),
    .io_requestor_1_resp_bits_excp_0_gpf_ld (io_requestor_1_resp_bits_excp_0_gpf_ld_g),
    .io_requestor_1_resp_bits_excp_0_pf_ld (io_requestor_1_resp_bits_excp_0_pf_ld_g),
    .io_requestor_1_resp_bits_excp_0_af_ld (io_requestor_1_resp_bits_excp_0_af_ld_g),
    .io_requestor_1_resp_bits_ptwBack (io_requestor_1_resp_bits_ptwBack_g),
    .io_requestor_2_resp_valid (io_requestor_2_resp_valid_g),
    .io_requestor_2_resp_bits_paddr_0 (io_requestor_2_resp_bits_paddr_0_g),
    .io_requestor_2_resp_bits_paddr_1 (io_requestor_2_resp_bits_paddr_1_g),
    .io_requestor_2_resp_bits_gpaddr_0 (io_requestor_2_resp_bits_gpaddr_0_g),
    .io_requestor_2_resp_bits_fullva (io_requestor_2_resp_bits_fullva_g),
    .io_requestor_2_resp_bits_pbmt_0 (io_requestor_2_resp_bits_pbmt_0_g),
    .io_requestor_2_resp_bits_miss (io_requestor_2_resp_bits_miss_g),
    .io_requestor_2_resp_bits_isForVSnonLeafPTE (io_requestor_2_resp_bits_isForVSnonLeafPTE_g),
    .io_requestor_2_resp_bits_excp_0_vaNeedExt (io_requestor_2_resp_bits_excp_0_vaNeedExt_g),
    .io_requestor_2_resp_bits_excp_0_isHyper (io_requestor_2_resp_bits_excp_0_isHyper_g),
    .io_requestor_2_resp_bits_excp_0_gpf_ld (io_requestor_2_resp_bits_excp_0_gpf_ld_g),
    .io_requestor_2_resp_bits_excp_0_pf_ld (io_requestor_2_resp_bits_excp_0_pf_ld_g),
    .io_requestor_2_resp_bits_excp_0_af_ld (io_requestor_2_resp_bits_excp_0_af_ld_g),
    .io_requestor_2_resp_bits_ptwBack (io_requestor_2_resp_bits_ptwBack_g),
    .io_requestor_3_resp_valid (io_requestor_3_resp_valid_g),
    .io_requestor_3_resp_bits_paddr_0 (io_requestor_3_resp_bits_paddr_0_g),
    .io_requestor_3_resp_bits_pbmt_0 (io_requestor_3_resp_bits_pbmt_0_g),
    .io_requestor_3_resp_bits_miss (io_requestor_3_resp_bits_miss_g),
    .io_requestor_3_resp_bits_excp_0_gpf_ld (io_requestor_3_resp_bits_excp_0_gpf_ld_g),
    .io_requestor_3_resp_bits_excp_0_pf_ld (io_requestor_3_resp_bits_excp_0_pf_ld_g),
    .io_requestor_3_resp_bits_excp_0_af_ld (io_requestor_3_resp_bits_excp_0_af_ld_g),
    .io_ptw_req_0_valid (io_ptw_req_0_valid_g),
    .io_ptw_req_0_bits_vpn (io_ptw_req_0_bits_vpn_g),
    .io_ptw_req_0_bits_s2xlate (io_ptw_req_0_bits_s2xlate_g),
    .io_ptw_req_0_bits_getGpa (io_ptw_req_0_bits_getGpa_g),
    .io_ptw_req_1_valid (io_ptw_req_1_valid_g),
    .io_ptw_req_1_bits_vpn (io_ptw_req_1_bits_vpn_g),
    .io_ptw_req_1_bits_s2xlate (io_ptw_req_1_bits_s2xlate_g),
    .io_ptw_req_1_bits_getGpa (io_ptw_req_1_bits_getGpa_g),
    .io_ptw_req_2_valid (io_ptw_req_2_valid_g),
    .io_ptw_req_2_bits_vpn (io_ptw_req_2_bits_vpn_g),
    .io_ptw_req_2_bits_s2xlate (io_ptw_req_2_bits_s2xlate_g),
    .io_ptw_req_2_bits_getGpa (io_ptw_req_2_bits_getGpa_g),
    .io_ptw_req_3_valid (io_ptw_req_3_valid_g),
    .io_ptw_req_3_bits_vpn (io_ptw_req_3_bits_vpn_g),
    .io_ptw_req_3_bits_s2xlate (io_ptw_req_3_bits_s2xlate_g),
    .io_ptw_req_3_bits_getGpa (io_ptw_req_3_bits_getGpa_g),
    .io_pmp_0_valid (io_pmp_0_valid_g),
    .io_pmp_0_bits_addr (io_pmp_0_bits_addr_g),
    .io_pmp_0_bits_cmd (io_pmp_0_bits_cmd_g),
    .io_pmp_1_valid (io_pmp_1_valid_g),
    .io_pmp_1_bits_addr (io_pmp_1_bits_addr_g),
    .io_pmp_1_bits_cmd (io_pmp_1_bits_cmd_g),
    .io_pmp_2_valid (io_pmp_2_valid_g),
    .io_pmp_2_bits_addr (io_pmp_2_bits_addr_g),
    .io_pmp_2_bits_cmd (io_pmp_2_bits_cmd_g),
    .io_pmp_3_valid (io_pmp_3_valid_g),
    .io_pmp_3_bits_addr (io_pmp_3_bits_addr_g),
    .io_pmp_3_bits_cmd (io_pmp_3_bits_cmd_g),
    .io_pmpMode_0 (io_pmpMode_0_g),
    .io_pmpMode_1 (io_pmpMode_1_g),
    .io_pmpMode_2 (io_pmpMode_2_g),
    .io_pmpMode_3 (io_pmpMode_3_g),
    .io_tlbreplay_0 (io_tlbreplay_0_g),
    .io_tlbreplay_1 (io_tlbreplay_1_g),
    .io_tlbreplay_2 (io_tlbreplay_2_g),
    .io_tlbreplay_3 (io_tlbreplay_3_g),
    .io_perf_0_value (io_perf_0_value_g),
    .io_perf_1_value (io_perf_1_value_g),
    .gatewayIn_packed_53_bore (gatewayIn_packed_53_bore_g),
    .gatewayIn_packed_54_bore (gatewayIn_packed_54_bore_g),
    .gatewayIn_packed_55_bore (gatewayIn_packed_55_bore_g),
    .gatewayIn_packed_56_bore (gatewayIn_packed_56_bore_g)
  );
  TLBNonBlock_xs dut_x (
    .clock (clock), .reset (reset),
    .io_sfence_valid (io_sfence_valid),
    .io_sfence_bits_rs1 (io_sfence_bits_rs1),
    .io_sfence_bits_rs2 (io_sfence_bits_rs2),
    .io_sfence_bits_addr (io_sfence_bits_addr),
    .io_sfence_bits_id (io_sfence_bits_id),
    .io_sfence_bits_flushPipe (io_sfence_bits_flushPipe),
    .io_sfence_bits_hv (io_sfence_bits_hv),
    .io_sfence_bits_hg (io_sfence_bits_hg),
    .io_csr_satp_mode (io_csr_satp_mode),
    .io_csr_satp_asid (io_csr_satp_asid),
    .io_csr_satp_ppn (io_csr_satp_ppn),
    .io_csr_satp_changed (io_csr_satp_changed),
    .io_csr_vsatp_mode (io_csr_vsatp_mode),
    .io_csr_vsatp_asid (io_csr_vsatp_asid),
    .io_csr_vsatp_ppn (io_csr_vsatp_ppn),
    .io_csr_vsatp_changed (io_csr_vsatp_changed),
    .io_csr_hgatp_mode (io_csr_hgatp_mode),
    .io_csr_hgatp_vmid (io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn (io_csr_hgatp_ppn),
    .io_csr_hgatp_changed (io_csr_hgatp_changed),
    .io_csr_mbmc_BME (io_csr_mbmc_BME),
    .io_csr_mbmc_CMODE (io_csr_mbmc_CMODE),
    .io_csr_priv_mxr (io_csr_priv_mxr),
    .io_csr_priv_sum (io_csr_priv_sum),
    .io_csr_priv_vmxr (io_csr_priv_vmxr),
    .io_csr_priv_vsum (io_csr_priv_vsum),
    .io_csr_priv_virt (io_csr_priv_virt),
    .io_csr_priv_virt_changed (io_csr_priv_virt_changed),
    .io_csr_priv_spvp (io_csr_priv_spvp),
    .io_csr_priv_imode (io_csr_priv_imode),
    .io_csr_priv_dmode (io_csr_priv_dmode),
    .io_csr_priv_debug (io_csr_priv_debug),
    .io_csr_pmm_mseccfg (io_csr_pmm_mseccfg),
    .io_csr_pmm_menvcfg (io_csr_pmm_menvcfg),
    .io_csr_pmm_henvcfg (io_csr_pmm_henvcfg),
    .io_csr_pmm_hstatus (io_csr_pmm_hstatus),
    .io_csr_pmm_senvcfg (io_csr_pmm_senvcfg),
    .io_hartId (io_hartId),
    .io_requestor_0_req_valid (io_requestor_0_req_valid),
    .io_requestor_0_req_bits_vaddr (io_requestor_0_req_bits_vaddr),
    .io_requestor_0_req_bits_fullva (io_requestor_0_req_bits_fullva),
    .io_requestor_0_req_bits_checkfullva (io_requestor_0_req_bits_checkfullva),
    .io_requestor_0_req_bits_cmd (io_requestor_0_req_bits_cmd),
    .io_requestor_0_req_bits_hyperinst (io_requestor_0_req_bits_hyperinst),
    .io_requestor_0_req_bits_hlvx (io_requestor_0_req_bits_hlvx),
    .io_requestor_0_req_bits_kill (io_requestor_0_req_bits_kill),
    .io_requestor_0_req_bits_isPrefetch (io_requestor_0_req_bits_isPrefetch),
    .io_requestor_0_req_bits_no_translate (io_requestor_0_req_bits_no_translate),
    .io_requestor_0_req_bits_pmp_addr (io_requestor_0_req_bits_pmp_addr),
    .io_requestor_0_req_bits_frm_mabuf (io_requestor_0_req_bits_frm_mabuf),
    .io_requestor_0_req_bits_debug_robIdx_flag (io_requestor_0_req_bits_debug_robIdx_flag),
    .io_requestor_0_req_bits_debug_robIdx_value (io_requestor_0_req_bits_debug_robIdx_value),
    .io_requestor_0_req_bits_debug_isFirstIssue (io_requestor_0_req_bits_debug_isFirstIssue),
    .io_requestor_0_req_kill (io_requestor_0_req_kill),
    .io_requestor_1_req_valid (io_requestor_1_req_valid),
    .io_requestor_1_req_bits_vaddr (io_requestor_1_req_bits_vaddr),
    .io_requestor_1_req_bits_fullva (io_requestor_1_req_bits_fullva),
    .io_requestor_1_req_bits_checkfullva (io_requestor_1_req_bits_checkfullva),
    .io_requestor_1_req_bits_cmd (io_requestor_1_req_bits_cmd),
    .io_requestor_1_req_bits_hyperinst (io_requestor_1_req_bits_hyperinst),
    .io_requestor_1_req_bits_hlvx (io_requestor_1_req_bits_hlvx),
    .io_requestor_1_req_bits_kill (io_requestor_1_req_bits_kill),
    .io_requestor_1_req_bits_isPrefetch (io_requestor_1_req_bits_isPrefetch),
    .io_requestor_1_req_bits_no_translate (io_requestor_1_req_bits_no_translate),
    .io_requestor_1_req_bits_pmp_addr (io_requestor_1_req_bits_pmp_addr),
    .io_requestor_1_req_bits_frm_mabuf (io_requestor_1_req_bits_frm_mabuf),
    .io_requestor_1_req_bits_debug_robIdx_flag (io_requestor_1_req_bits_debug_robIdx_flag),
    .io_requestor_1_req_bits_debug_robIdx_value (io_requestor_1_req_bits_debug_robIdx_value),
    .io_requestor_1_req_bits_debug_isFirstIssue (io_requestor_1_req_bits_debug_isFirstIssue),
    .io_requestor_1_req_kill (io_requestor_1_req_kill),
    .io_requestor_2_req_valid (io_requestor_2_req_valid),
    .io_requestor_2_req_bits_vaddr (io_requestor_2_req_bits_vaddr),
    .io_requestor_2_req_bits_fullva (io_requestor_2_req_bits_fullva),
    .io_requestor_2_req_bits_checkfullva (io_requestor_2_req_bits_checkfullva),
    .io_requestor_2_req_bits_cmd (io_requestor_2_req_bits_cmd),
    .io_requestor_2_req_bits_hyperinst (io_requestor_2_req_bits_hyperinst),
    .io_requestor_2_req_bits_hlvx (io_requestor_2_req_bits_hlvx),
    .io_requestor_2_req_bits_kill (io_requestor_2_req_bits_kill),
    .io_requestor_2_req_bits_isPrefetch (io_requestor_2_req_bits_isPrefetch),
    .io_requestor_2_req_bits_no_translate (io_requestor_2_req_bits_no_translate),
    .io_requestor_2_req_bits_pmp_addr (io_requestor_2_req_bits_pmp_addr),
    .io_requestor_2_req_bits_frm_mabuf (io_requestor_2_req_bits_frm_mabuf),
    .io_requestor_2_req_bits_debug_robIdx_flag (io_requestor_2_req_bits_debug_robIdx_flag),
    .io_requestor_2_req_bits_debug_robIdx_value (io_requestor_2_req_bits_debug_robIdx_value),
    .io_requestor_2_req_bits_debug_isFirstIssue (io_requestor_2_req_bits_debug_isFirstIssue),
    .io_requestor_2_req_kill (io_requestor_2_req_kill),
    .io_requestor_3_req_valid (io_requestor_3_req_valid),
    .io_requestor_3_req_bits_vaddr (io_requestor_3_req_bits_vaddr),
    .io_requestor_3_req_bits_fullva (io_requestor_3_req_bits_fullva),
    .io_requestor_3_req_bits_checkfullva (io_requestor_3_req_bits_checkfullva),
    .io_requestor_3_req_bits_cmd (io_requestor_3_req_bits_cmd),
    .io_requestor_3_req_bits_hyperinst (io_requestor_3_req_bits_hyperinst),
    .io_requestor_3_req_bits_hlvx (io_requestor_3_req_bits_hlvx),
    .io_requestor_3_req_bits_kill (io_requestor_3_req_bits_kill),
    .io_requestor_3_req_bits_isPrefetch (io_requestor_3_req_bits_isPrefetch),
    .io_requestor_3_req_bits_no_translate (io_requestor_3_req_bits_no_translate),
    .io_requestor_3_req_bits_pmp_addr (io_requestor_3_req_bits_pmp_addr),
    .io_requestor_3_req_bits_frm_mabuf (io_requestor_3_req_bits_frm_mabuf),
    .io_requestor_3_req_bits_debug_robIdx_flag (io_requestor_3_req_bits_debug_robIdx_flag),
    .io_requestor_3_req_bits_debug_robIdx_value (io_requestor_3_req_bits_debug_robIdx_value),
    .io_requestor_3_req_bits_debug_isFirstIssue (io_requestor_3_req_bits_debug_isFirstIssue),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_ptw_resp_valid (io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate (io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag (io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid (io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid (io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n (io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt (io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d (io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a (io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g (io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u (io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x (io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w (io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r (io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level (io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v (io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn (io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low (io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0 (io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1 (io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2 (io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3 (io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4 (io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5 (io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6 (io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7 (io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0 (io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1 (io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2 (io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3 (io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4 (io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5 (io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6 (io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7 (io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0 (io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1 (io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2 (io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3 (io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4 (io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5 (io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6 (io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7 (io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf (io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af (io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag (io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid (io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n (io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt (io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn (io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d (io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a (io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g (io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u (io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x (io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w (io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r (io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level (io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf (io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf (io_ptw_resp_bits_s2_gaf),
    .io_ptw_resp_bits_getGpa (io_ptw_resp_bits_getGpa),
    .io_robPendingPtr_flag (io_robPendingPtr_flag),
    .io_robPendingPtr_value (io_robPendingPtr_value),
    .io_requestor_0_resp_valid (io_requestor_0_resp_valid_x),
    .io_requestor_0_resp_bits_paddr_0 (io_requestor_0_resp_bits_paddr_0_x),
    .io_requestor_0_resp_bits_paddr_1 (io_requestor_0_resp_bits_paddr_1_x),
    .io_requestor_0_resp_bits_gpaddr_0 (io_requestor_0_resp_bits_gpaddr_0_x),
    .io_requestor_0_resp_bits_fullva (io_requestor_0_resp_bits_fullva_x),
    .io_requestor_0_resp_bits_pbmt_0 (io_requestor_0_resp_bits_pbmt_0_x),
    .io_requestor_0_resp_bits_miss (io_requestor_0_resp_bits_miss_x),
    .io_requestor_0_resp_bits_isForVSnonLeafPTE (io_requestor_0_resp_bits_isForVSnonLeafPTE_x),
    .io_requestor_0_resp_bits_excp_0_vaNeedExt (io_requestor_0_resp_bits_excp_0_vaNeedExt_x),
    .io_requestor_0_resp_bits_excp_0_isHyper (io_requestor_0_resp_bits_excp_0_isHyper_x),
    .io_requestor_0_resp_bits_excp_0_gpf_ld (io_requestor_0_resp_bits_excp_0_gpf_ld_x),
    .io_requestor_0_resp_bits_excp_0_gpf_st (io_requestor_0_resp_bits_excp_0_gpf_st_x),
    .io_requestor_0_resp_bits_excp_0_pf_ld (io_requestor_0_resp_bits_excp_0_pf_ld_x),
    .io_requestor_0_resp_bits_excp_0_pf_st (io_requestor_0_resp_bits_excp_0_pf_st_x),
    .io_requestor_0_resp_bits_excp_0_af_ld (io_requestor_0_resp_bits_excp_0_af_ld_x),
    .io_requestor_0_resp_bits_excp_0_af_st (io_requestor_0_resp_bits_excp_0_af_st_x),
    .io_requestor_0_resp_bits_ptwBack (io_requestor_0_resp_bits_ptwBack_x),
    .io_requestor_1_resp_valid (io_requestor_1_resp_valid_x),
    .io_requestor_1_resp_bits_paddr_0 (io_requestor_1_resp_bits_paddr_0_x),
    .io_requestor_1_resp_bits_paddr_1 (io_requestor_1_resp_bits_paddr_1_x),
    .io_requestor_1_resp_bits_gpaddr_0 (io_requestor_1_resp_bits_gpaddr_0_x),
    .io_requestor_1_resp_bits_fullva (io_requestor_1_resp_bits_fullva_x),
    .io_requestor_1_resp_bits_pbmt_0 (io_requestor_1_resp_bits_pbmt_0_x),
    .io_requestor_1_resp_bits_miss (io_requestor_1_resp_bits_miss_x),
    .io_requestor_1_resp_bits_isForVSnonLeafPTE (io_requestor_1_resp_bits_isForVSnonLeafPTE_x),
    .io_requestor_1_resp_bits_excp_0_vaNeedExt (io_requestor_1_resp_bits_excp_0_vaNeedExt_x),
    .io_requestor_1_resp_bits_excp_0_isHyper (io_requestor_1_resp_bits_excp_0_isHyper_x),
    .io_requestor_1_resp_bits_excp_0_gpf_ld (io_requestor_1_resp_bits_excp_0_gpf_ld_x),
    .io_requestor_1_resp_bits_excp_0_pf_ld (io_requestor_1_resp_bits_excp_0_pf_ld_x),
    .io_requestor_1_resp_bits_excp_0_af_ld (io_requestor_1_resp_bits_excp_0_af_ld_x),
    .io_requestor_1_resp_bits_ptwBack (io_requestor_1_resp_bits_ptwBack_x),
    .io_requestor_2_resp_valid (io_requestor_2_resp_valid_x),
    .io_requestor_2_resp_bits_paddr_0 (io_requestor_2_resp_bits_paddr_0_x),
    .io_requestor_2_resp_bits_paddr_1 (io_requestor_2_resp_bits_paddr_1_x),
    .io_requestor_2_resp_bits_gpaddr_0 (io_requestor_2_resp_bits_gpaddr_0_x),
    .io_requestor_2_resp_bits_fullva (io_requestor_2_resp_bits_fullva_x),
    .io_requestor_2_resp_bits_pbmt_0 (io_requestor_2_resp_bits_pbmt_0_x),
    .io_requestor_2_resp_bits_miss (io_requestor_2_resp_bits_miss_x),
    .io_requestor_2_resp_bits_isForVSnonLeafPTE (io_requestor_2_resp_bits_isForVSnonLeafPTE_x),
    .io_requestor_2_resp_bits_excp_0_vaNeedExt (io_requestor_2_resp_bits_excp_0_vaNeedExt_x),
    .io_requestor_2_resp_bits_excp_0_isHyper (io_requestor_2_resp_bits_excp_0_isHyper_x),
    .io_requestor_2_resp_bits_excp_0_gpf_ld (io_requestor_2_resp_bits_excp_0_gpf_ld_x),
    .io_requestor_2_resp_bits_excp_0_pf_ld (io_requestor_2_resp_bits_excp_0_pf_ld_x),
    .io_requestor_2_resp_bits_excp_0_af_ld (io_requestor_2_resp_bits_excp_0_af_ld_x),
    .io_requestor_2_resp_bits_ptwBack (io_requestor_2_resp_bits_ptwBack_x),
    .io_requestor_3_resp_valid (io_requestor_3_resp_valid_x),
    .io_requestor_3_resp_bits_paddr_0 (io_requestor_3_resp_bits_paddr_0_x),
    .io_requestor_3_resp_bits_pbmt_0 (io_requestor_3_resp_bits_pbmt_0_x),
    .io_requestor_3_resp_bits_miss (io_requestor_3_resp_bits_miss_x),
    .io_requestor_3_resp_bits_excp_0_gpf_ld (io_requestor_3_resp_bits_excp_0_gpf_ld_x),
    .io_requestor_3_resp_bits_excp_0_pf_ld (io_requestor_3_resp_bits_excp_0_pf_ld_x),
    .io_requestor_3_resp_bits_excp_0_af_ld (io_requestor_3_resp_bits_excp_0_af_ld_x),
    .io_ptw_req_0_valid (io_ptw_req_0_valid_x),
    .io_ptw_req_0_bits_vpn (io_ptw_req_0_bits_vpn_x),
    .io_ptw_req_0_bits_s2xlate (io_ptw_req_0_bits_s2xlate_x),
    .io_ptw_req_0_bits_getGpa (io_ptw_req_0_bits_getGpa_x),
    .io_ptw_req_1_valid (io_ptw_req_1_valid_x),
    .io_ptw_req_1_bits_vpn (io_ptw_req_1_bits_vpn_x),
    .io_ptw_req_1_bits_s2xlate (io_ptw_req_1_bits_s2xlate_x),
    .io_ptw_req_1_bits_getGpa (io_ptw_req_1_bits_getGpa_x),
    .io_ptw_req_2_valid (io_ptw_req_2_valid_x),
    .io_ptw_req_2_bits_vpn (io_ptw_req_2_bits_vpn_x),
    .io_ptw_req_2_bits_s2xlate (io_ptw_req_2_bits_s2xlate_x),
    .io_ptw_req_2_bits_getGpa (io_ptw_req_2_bits_getGpa_x),
    .io_ptw_req_3_valid (io_ptw_req_3_valid_x),
    .io_ptw_req_3_bits_vpn (io_ptw_req_3_bits_vpn_x),
    .io_ptw_req_3_bits_s2xlate (io_ptw_req_3_bits_s2xlate_x),
    .io_ptw_req_3_bits_getGpa (io_ptw_req_3_bits_getGpa_x),
    .io_pmp_0_valid (io_pmp_0_valid_x),
    .io_pmp_0_bits_addr (io_pmp_0_bits_addr_x),
    .io_pmp_0_bits_cmd (io_pmp_0_bits_cmd_x),
    .io_pmp_1_valid (io_pmp_1_valid_x),
    .io_pmp_1_bits_addr (io_pmp_1_bits_addr_x),
    .io_pmp_1_bits_cmd (io_pmp_1_bits_cmd_x),
    .io_pmp_2_valid (io_pmp_2_valid_x),
    .io_pmp_2_bits_addr (io_pmp_2_bits_addr_x),
    .io_pmp_2_bits_cmd (io_pmp_2_bits_cmd_x),
    .io_pmp_3_valid (io_pmp_3_valid_x),
    .io_pmp_3_bits_addr (io_pmp_3_bits_addr_x),
    .io_pmp_3_bits_cmd (io_pmp_3_bits_cmd_x),
    .io_pmpMode_0 (io_pmpMode_0_x),
    .io_pmpMode_1 (io_pmpMode_1_x),
    .io_pmpMode_2 (io_pmpMode_2_x),
    .io_pmpMode_3 (io_pmpMode_3_x),
    .io_tlbreplay_0 (io_tlbreplay_0_x),
    .io_tlbreplay_1 (io_tlbreplay_1_x),
    .io_tlbreplay_2 (io_tlbreplay_2_x),
    .io_tlbreplay_3 (io_tlbreplay_3_x),
    .io_perf_0_value (io_perf_0_value_x),
    .io_perf_1_value (io_perf_1_value_x),
    .gatewayIn_packed_53_bore (gatewayIn_packed_53_bore_x),
    .gatewayIn_packed_54_bore (gatewayIn_packed_54_bore_x),
    .gatewayIn_packed_55_bore (gatewayIn_packed_55_bore_x),
    .gatewayIn_packed_56_bore (gatewayIn_packed_56_bore_x)
  );

  integer errors = 0;
  integer ncycles = 200000;
  integer i;

  task automatic drive_inputs;
    begin
      io_sfence_valid <= ($urandom() % 100) < 8;
      io_sfence_bits_rs1 <= 1'($urandom());
      io_sfence_bits_rs2 <= 1'($urandom());
      io_sfence_bits_addr <= 50'({$urandom(), $urandom()});
      io_sfence_bits_id <= 16'($urandom());
      io_sfence_bits_flushPipe <= 1'($urandom());
      io_sfence_bits_hv <= 1'($urandom());
      io_sfence_bits_hg <= 1'($urandom());
      io_csr_satp_mode <= mode_pool[$urandom() % 3];
      io_csr_satp_asid <= asid_pool[$urandom() % 4];
      io_csr_satp_ppn <= 44'({$urandom(), $urandom()});
      io_csr_satp_changed <= 1'($urandom());
      io_csr_vsatp_mode <= mode_pool[$urandom() % 3];
      io_csr_vsatp_asid <= asid_pool[$urandom() % 4];
      io_csr_vsatp_ppn <= 44'({$urandom(), $urandom()});
      io_csr_vsatp_changed <= 1'($urandom());
      io_csr_hgatp_mode <= mode_pool[$urandom() % 3];
      io_csr_hgatp_vmid <= vmid_pool[$urandom() % 4];
      io_csr_hgatp_ppn <= 44'({$urandom(), $urandom()});
      io_csr_hgatp_changed <= 1'($urandom());
      io_csr_mbmc_BME <= 1'($urandom());
      io_csr_mbmc_CMODE <= 1'($urandom());
      io_csr_priv_mxr <= 1'($urandom());
      io_csr_priv_sum <= 1'($urandom());
      io_csr_priv_vmxr <= 1'($urandom());
      io_csr_priv_vsum <= 1'($urandom());
      io_csr_priv_virt <= ($urandom() % 100) < 40;
      io_csr_priv_virt_changed <= 1'($urandom());
      io_csr_priv_spvp <= 1'($urandom());
      io_csr_priv_imode <= priv_pool[$urandom() % 3];
      io_csr_priv_dmode <= priv_pool[$urandom() % 3];
      io_csr_priv_debug <= 1'($urandom());
      io_csr_pmm_mseccfg <= 2'($urandom());
      io_csr_pmm_menvcfg <= 2'($urandom());
      io_csr_pmm_henvcfg <= 2'($urandom());
      io_csr_pmm_hstatus <= 2'($urandom());
      io_csr_pmm_senvcfg <= 2'($urandom());
      io_hartId <= 6'($urandom());
      io_requestor_0_req_valid <= ($urandom() % 100) < 70;
      io_requestor_0_req_bits_vaddr <= {vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_0_req_bits_fullva <= {14'($urandom()), vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_0_req_bits_checkfullva <= ($urandom() % 100) < 40;
      io_requestor_0_req_bits_cmd <= cmd_pool[$urandom() % 4];
      io_requestor_0_req_bits_hyperinst <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_hlvx <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_kill <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_isPrefetch <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_no_translate <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_0_req_bits_frm_mabuf <= ($urandom() % 100) < 20;
      io_requestor_0_req_bits_debug_robIdx_flag <= 1'($urandom());
      io_requestor_0_req_bits_debug_robIdx_value <= 8'($urandom() % 16);
      io_requestor_0_req_bits_debug_isFirstIssue <= 1'($urandom());
      io_requestor_0_req_kill <= ($urandom() % 100) < 15;
      io_requestor_1_req_valid <= ($urandom() % 100) < 70;
      io_requestor_1_req_bits_vaddr <= {vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_1_req_bits_fullva <= {14'($urandom()), vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_1_req_bits_checkfullva <= ($urandom() % 100) < 40;
      io_requestor_1_req_bits_cmd <= cmd_pool[$urandom() % 4];
      io_requestor_1_req_bits_hyperinst <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_hlvx <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_kill <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_isPrefetch <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_no_translate <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_1_req_bits_frm_mabuf <= ($urandom() % 100) < 20;
      io_requestor_1_req_bits_debug_robIdx_flag <= 1'($urandom());
      io_requestor_1_req_bits_debug_robIdx_value <= 8'($urandom() % 16);
      io_requestor_1_req_bits_debug_isFirstIssue <= 1'($urandom());
      io_requestor_1_req_kill <= ($urandom() % 100) < 15;
      io_requestor_2_req_valid <= ($urandom() % 100) < 70;
      io_requestor_2_req_bits_vaddr <= {vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_2_req_bits_fullva <= {14'($urandom()), vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_2_req_bits_checkfullva <= ($urandom() % 100) < 40;
      io_requestor_2_req_bits_cmd <= cmd_pool[$urandom() % 4];
      io_requestor_2_req_bits_hyperinst <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_hlvx <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_kill <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_isPrefetch <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_no_translate <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_2_req_bits_frm_mabuf <= ($urandom() % 100) < 20;
      io_requestor_2_req_bits_debug_robIdx_flag <= 1'($urandom());
      io_requestor_2_req_bits_debug_robIdx_value <= 8'($urandom() % 16);
      io_requestor_2_req_bits_debug_isFirstIssue <= 1'($urandom());
      io_requestor_2_req_kill <= ($urandom() % 100) < 15;
      io_requestor_3_req_valid <= ($urandom() % 100) < 70;
      io_requestor_3_req_bits_vaddr <= {vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_3_req_bits_fullva <= {14'($urandom()), vpn_pool[$urandom() % POOL_N], 12'($urandom())};
      io_requestor_3_req_bits_checkfullva <= ($urandom() % 100) < 40;
      io_requestor_3_req_bits_cmd <= cmd_pool[$urandom() % 4];
      io_requestor_3_req_bits_hyperinst <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_hlvx <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_kill <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_isPrefetch <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_no_translate <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_pmp_addr <= 48'({$urandom(), $urandom()});
      io_requestor_3_req_bits_frm_mabuf <= ($urandom() % 100) < 20;
      io_requestor_3_req_bits_debug_robIdx_flag <= 1'($urandom());
      io_requestor_3_req_bits_debug_robIdx_value <= 8'($urandom() % 16);
      io_requestor_3_req_bits_debug_isFirstIssue <= 1'($urandom());
      io_redirect_valid <= ($urandom() % 100) < 15;
      io_redirect_bits_robIdx_flag <= 1'($urandom());
      io_redirect_bits_robIdx_value <= 8'($urandom() % 16);
      io_redirect_bits_level <= 1'($urandom());
      io_ptw_resp_valid <= ($urandom() % 100) < 35;
      io_ptw_resp_bits_s2xlate <= 2'($urandom());
      io_ptw_resp_bits_s1_entry_tag <= vpn_pool[$urandom() % POOL_N][37:3];
      io_ptw_resp_bits_s1_entry_asid <= asid_pool[$urandom() % 4];
      io_ptw_resp_bits_s1_entry_vmid <= 14'(vmid_pool[$urandom() % 4]);
      io_ptw_resp_bits_s1_entry_n <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_pbmt <= 2'($urandom());
      io_ptw_resp_bits_s1_entry_perm_d <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_a <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_g <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_u <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_x <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_w <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_perm_r <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_level <= 2'($urandom());
      io_ptw_resp_bits_s1_entry_v <= 1'($urandom());
      io_ptw_resp_bits_s1_entry_ppn <= 41'({$urandom(), $urandom()});
      io_ptw_resp_bits_s1_addr_low <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_0 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_1 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_2 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_3 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_4 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_5 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_6 <= 3'($urandom());
      io_ptw_resp_bits_s1_ppn_low_7 <= 3'($urandom());
      io_ptw_resp_bits_s1_valididx_0 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_1 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_2 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_3 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_4 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_5 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_6 <= 1'($urandom());
      io_ptw_resp_bits_s1_valididx_7 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_0 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_1 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_2 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_3 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_4 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_5 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_6 <= 1'($urandom());
      io_ptw_resp_bits_s1_pteidx_7 <= 1'($urandom());
      io_ptw_resp_bits_s1_pf <= 1'($urandom());
      io_ptw_resp_bits_s1_af <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_tag <= vpn_pool[$urandom() % POOL_N];
      io_ptw_resp_bits_s2_entry_vmid <= 14'(vmid_pool[$urandom() % 4]);
      io_ptw_resp_bits_s2_entry_n <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_pbmt <= 2'($urandom());
      io_ptw_resp_bits_s2_entry_ppn <= 38'({$urandom(), $urandom()});
      io_ptw_resp_bits_s2_entry_perm_d <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_a <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_g <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_u <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_x <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_w <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_perm_r <= 1'($urandom());
      io_ptw_resp_bits_s2_entry_level <= 2'($urandom());
      io_ptw_resp_bits_s2_gpf <= 1'($urandom());
      io_ptw_resp_bits_s2_gaf <= 1'($urandom());
      io_ptw_resp_bits_getGpa <= 1'($urandom());
      io_robPendingPtr_flag <= 1'($urandom());
      io_robPendingPtr_value <= 8'($urandom() % 16);
    end
  endtask

  task automatic check_outputs;
    begin
      if (io_requestor_0_resp_valid_g !== io_requestor_0_resp_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_valid g=%h x=%h", $time, io_requestor_0_resp_valid_g, io_requestor_0_resp_valid_x);
      end
      if (io_requestor_0_resp_bits_paddr_0_g !== io_requestor_0_resp_bits_paddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_paddr_0 g=%h x=%h", $time, io_requestor_0_resp_bits_paddr_0_g, io_requestor_0_resp_bits_paddr_0_x);
      end
      if (io_requestor_0_resp_bits_paddr_1_g !== io_requestor_0_resp_bits_paddr_1_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_paddr_1 g=%h x=%h", $time, io_requestor_0_resp_bits_paddr_1_g, io_requestor_0_resp_bits_paddr_1_x);
      end
      if (io_requestor_0_resp_bits_gpaddr_0_g !== io_requestor_0_resp_bits_gpaddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_gpaddr_0 g=%h x=%h", $time, io_requestor_0_resp_bits_gpaddr_0_g, io_requestor_0_resp_bits_gpaddr_0_x);
      end
      if (io_requestor_0_resp_bits_fullva_g !== io_requestor_0_resp_bits_fullva_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_fullva g=%h x=%h", $time, io_requestor_0_resp_bits_fullva_g, io_requestor_0_resp_bits_fullva_x);
      end
      if (io_requestor_0_resp_bits_pbmt_0_g !== io_requestor_0_resp_bits_pbmt_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_pbmt_0 g=%h x=%h", $time, io_requestor_0_resp_bits_pbmt_0_g, io_requestor_0_resp_bits_pbmt_0_x);
      end
      if (io_requestor_0_resp_bits_miss_g !== io_requestor_0_resp_bits_miss_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_miss g=%h x=%h", $time, io_requestor_0_resp_bits_miss_g, io_requestor_0_resp_bits_miss_x);
      end
      if (io_requestor_0_resp_bits_isForVSnonLeafPTE_g !== io_requestor_0_resp_bits_isForVSnonLeafPTE_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_isForVSnonLeafPTE g=%h x=%h", $time, io_requestor_0_resp_bits_isForVSnonLeafPTE_g, io_requestor_0_resp_bits_isForVSnonLeafPTE_x);
      end
      if (io_requestor_0_resp_bits_excp_0_vaNeedExt_g !== io_requestor_0_resp_bits_excp_0_vaNeedExt_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_vaNeedExt g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_vaNeedExt_g, io_requestor_0_resp_bits_excp_0_vaNeedExt_x);
      end
      if (io_requestor_0_resp_bits_excp_0_isHyper_g !== io_requestor_0_resp_bits_excp_0_isHyper_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_isHyper g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_isHyper_g, io_requestor_0_resp_bits_excp_0_isHyper_x);
      end
      if (io_requestor_0_resp_bits_excp_0_gpf_ld_g !== io_requestor_0_resp_bits_excp_0_gpf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_gpf_ld g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_gpf_ld_g, io_requestor_0_resp_bits_excp_0_gpf_ld_x);
      end
      if (io_requestor_0_resp_bits_excp_0_gpf_st_g !== io_requestor_0_resp_bits_excp_0_gpf_st_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_gpf_st g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_gpf_st_g, io_requestor_0_resp_bits_excp_0_gpf_st_x);
      end
      if (io_requestor_0_resp_bits_excp_0_pf_ld_g !== io_requestor_0_resp_bits_excp_0_pf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_pf_ld g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_pf_ld_g, io_requestor_0_resp_bits_excp_0_pf_ld_x);
      end
      if (io_requestor_0_resp_bits_excp_0_pf_st_g !== io_requestor_0_resp_bits_excp_0_pf_st_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_pf_st g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_pf_st_g, io_requestor_0_resp_bits_excp_0_pf_st_x);
      end
      if (io_requestor_0_resp_bits_excp_0_af_ld_g !== io_requestor_0_resp_bits_excp_0_af_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_af_ld g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_af_ld_g, io_requestor_0_resp_bits_excp_0_af_ld_x);
      end
      if (io_requestor_0_resp_bits_excp_0_af_st_g !== io_requestor_0_resp_bits_excp_0_af_st_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_excp_0_af_st g=%h x=%h", $time, io_requestor_0_resp_bits_excp_0_af_st_g, io_requestor_0_resp_bits_excp_0_af_st_x);
      end
      if (io_requestor_0_resp_bits_ptwBack_g !== io_requestor_0_resp_bits_ptwBack_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_0_resp_bits_ptwBack g=%h x=%h", $time, io_requestor_0_resp_bits_ptwBack_g, io_requestor_0_resp_bits_ptwBack_x);
      end
      if (io_requestor_1_resp_valid_g !== io_requestor_1_resp_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_valid g=%h x=%h", $time, io_requestor_1_resp_valid_g, io_requestor_1_resp_valid_x);
      end
      if (io_requestor_1_resp_bits_paddr_0_g !== io_requestor_1_resp_bits_paddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_paddr_0 g=%h x=%h", $time, io_requestor_1_resp_bits_paddr_0_g, io_requestor_1_resp_bits_paddr_0_x);
      end
      if (io_requestor_1_resp_bits_paddr_1_g !== io_requestor_1_resp_bits_paddr_1_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_paddr_1 g=%h x=%h", $time, io_requestor_1_resp_bits_paddr_1_g, io_requestor_1_resp_bits_paddr_1_x);
      end
      if (io_requestor_1_resp_bits_gpaddr_0_g !== io_requestor_1_resp_bits_gpaddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_gpaddr_0 g=%h x=%h", $time, io_requestor_1_resp_bits_gpaddr_0_g, io_requestor_1_resp_bits_gpaddr_0_x);
      end
      if (io_requestor_1_resp_bits_fullva_g !== io_requestor_1_resp_bits_fullva_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_fullva g=%h x=%h", $time, io_requestor_1_resp_bits_fullva_g, io_requestor_1_resp_bits_fullva_x);
      end
      if (io_requestor_1_resp_bits_pbmt_0_g !== io_requestor_1_resp_bits_pbmt_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_pbmt_0 g=%h x=%h", $time, io_requestor_1_resp_bits_pbmt_0_g, io_requestor_1_resp_bits_pbmt_0_x);
      end
      if (io_requestor_1_resp_bits_miss_g !== io_requestor_1_resp_bits_miss_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_miss g=%h x=%h", $time, io_requestor_1_resp_bits_miss_g, io_requestor_1_resp_bits_miss_x);
      end
      if (io_requestor_1_resp_bits_isForVSnonLeafPTE_g !== io_requestor_1_resp_bits_isForVSnonLeafPTE_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_isForVSnonLeafPTE g=%h x=%h", $time, io_requestor_1_resp_bits_isForVSnonLeafPTE_g, io_requestor_1_resp_bits_isForVSnonLeafPTE_x);
      end
      if (io_requestor_1_resp_bits_excp_0_vaNeedExt_g !== io_requestor_1_resp_bits_excp_0_vaNeedExt_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_excp_0_vaNeedExt g=%h x=%h", $time, io_requestor_1_resp_bits_excp_0_vaNeedExt_g, io_requestor_1_resp_bits_excp_0_vaNeedExt_x);
      end
      if (io_requestor_1_resp_bits_excp_0_isHyper_g !== io_requestor_1_resp_bits_excp_0_isHyper_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_excp_0_isHyper g=%h x=%h", $time, io_requestor_1_resp_bits_excp_0_isHyper_g, io_requestor_1_resp_bits_excp_0_isHyper_x);
      end
      if (io_requestor_1_resp_bits_excp_0_gpf_ld_g !== io_requestor_1_resp_bits_excp_0_gpf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_excp_0_gpf_ld g=%h x=%h", $time, io_requestor_1_resp_bits_excp_0_gpf_ld_g, io_requestor_1_resp_bits_excp_0_gpf_ld_x);
      end
      if (io_requestor_1_resp_bits_excp_0_pf_ld_g !== io_requestor_1_resp_bits_excp_0_pf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_excp_0_pf_ld g=%h x=%h", $time, io_requestor_1_resp_bits_excp_0_pf_ld_g, io_requestor_1_resp_bits_excp_0_pf_ld_x);
      end
      if (io_requestor_1_resp_bits_excp_0_af_ld_g !== io_requestor_1_resp_bits_excp_0_af_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_excp_0_af_ld g=%h x=%h", $time, io_requestor_1_resp_bits_excp_0_af_ld_g, io_requestor_1_resp_bits_excp_0_af_ld_x);
      end
      if (io_requestor_1_resp_bits_ptwBack_g !== io_requestor_1_resp_bits_ptwBack_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_1_resp_bits_ptwBack g=%h x=%h", $time, io_requestor_1_resp_bits_ptwBack_g, io_requestor_1_resp_bits_ptwBack_x);
      end
      if (io_requestor_2_resp_valid_g !== io_requestor_2_resp_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_valid g=%h x=%h", $time, io_requestor_2_resp_valid_g, io_requestor_2_resp_valid_x);
      end
      if (io_requestor_2_resp_bits_paddr_0_g !== io_requestor_2_resp_bits_paddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_paddr_0 g=%h x=%h", $time, io_requestor_2_resp_bits_paddr_0_g, io_requestor_2_resp_bits_paddr_0_x);
      end
      if (io_requestor_2_resp_bits_paddr_1_g !== io_requestor_2_resp_bits_paddr_1_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_paddr_1 g=%h x=%h", $time, io_requestor_2_resp_bits_paddr_1_g, io_requestor_2_resp_bits_paddr_1_x);
      end
      if (io_requestor_2_resp_bits_gpaddr_0_g !== io_requestor_2_resp_bits_gpaddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_gpaddr_0 g=%h x=%h", $time, io_requestor_2_resp_bits_gpaddr_0_g, io_requestor_2_resp_bits_gpaddr_0_x);
      end
      if (io_requestor_2_resp_bits_fullva_g !== io_requestor_2_resp_bits_fullva_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_fullva g=%h x=%h", $time, io_requestor_2_resp_bits_fullva_g, io_requestor_2_resp_bits_fullva_x);
      end
      if (io_requestor_2_resp_bits_pbmt_0_g !== io_requestor_2_resp_bits_pbmt_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_pbmt_0 g=%h x=%h", $time, io_requestor_2_resp_bits_pbmt_0_g, io_requestor_2_resp_bits_pbmt_0_x);
      end
      if (io_requestor_2_resp_bits_miss_g !== io_requestor_2_resp_bits_miss_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_miss g=%h x=%h", $time, io_requestor_2_resp_bits_miss_g, io_requestor_2_resp_bits_miss_x);
      end
      if (io_requestor_2_resp_bits_isForVSnonLeafPTE_g !== io_requestor_2_resp_bits_isForVSnonLeafPTE_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_isForVSnonLeafPTE g=%h x=%h", $time, io_requestor_2_resp_bits_isForVSnonLeafPTE_g, io_requestor_2_resp_bits_isForVSnonLeafPTE_x);
      end
      if (io_requestor_2_resp_bits_excp_0_vaNeedExt_g !== io_requestor_2_resp_bits_excp_0_vaNeedExt_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_excp_0_vaNeedExt g=%h x=%h", $time, io_requestor_2_resp_bits_excp_0_vaNeedExt_g, io_requestor_2_resp_bits_excp_0_vaNeedExt_x);
      end
      if (io_requestor_2_resp_bits_excp_0_isHyper_g !== io_requestor_2_resp_bits_excp_0_isHyper_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_excp_0_isHyper g=%h x=%h", $time, io_requestor_2_resp_bits_excp_0_isHyper_g, io_requestor_2_resp_bits_excp_0_isHyper_x);
      end
      if (io_requestor_2_resp_bits_excp_0_gpf_ld_g !== io_requestor_2_resp_bits_excp_0_gpf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_excp_0_gpf_ld g=%h x=%h", $time, io_requestor_2_resp_bits_excp_0_gpf_ld_g, io_requestor_2_resp_bits_excp_0_gpf_ld_x);
      end
      if (io_requestor_2_resp_bits_excp_0_pf_ld_g !== io_requestor_2_resp_bits_excp_0_pf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_excp_0_pf_ld g=%h x=%h", $time, io_requestor_2_resp_bits_excp_0_pf_ld_g, io_requestor_2_resp_bits_excp_0_pf_ld_x);
      end
      if (io_requestor_2_resp_bits_excp_0_af_ld_g !== io_requestor_2_resp_bits_excp_0_af_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_excp_0_af_ld g=%h x=%h", $time, io_requestor_2_resp_bits_excp_0_af_ld_g, io_requestor_2_resp_bits_excp_0_af_ld_x);
      end
      if (io_requestor_2_resp_bits_ptwBack_g !== io_requestor_2_resp_bits_ptwBack_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_2_resp_bits_ptwBack g=%h x=%h", $time, io_requestor_2_resp_bits_ptwBack_g, io_requestor_2_resp_bits_ptwBack_x);
      end
      if (io_requestor_3_resp_valid_g !== io_requestor_3_resp_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_valid g=%h x=%h", $time, io_requestor_3_resp_valid_g, io_requestor_3_resp_valid_x);
      end
      if (io_requestor_3_resp_bits_paddr_0_g !== io_requestor_3_resp_bits_paddr_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_paddr_0 g=%h x=%h", $time, io_requestor_3_resp_bits_paddr_0_g, io_requestor_3_resp_bits_paddr_0_x);
      end
      if (io_requestor_3_resp_bits_pbmt_0_g !== io_requestor_3_resp_bits_pbmt_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_pbmt_0 g=%h x=%h", $time, io_requestor_3_resp_bits_pbmt_0_g, io_requestor_3_resp_bits_pbmt_0_x);
      end
      if (io_requestor_3_resp_bits_miss_g !== io_requestor_3_resp_bits_miss_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_miss g=%h x=%h", $time, io_requestor_3_resp_bits_miss_g, io_requestor_3_resp_bits_miss_x);
      end
      if (io_requestor_3_resp_bits_excp_0_gpf_ld_g !== io_requestor_3_resp_bits_excp_0_gpf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_excp_0_gpf_ld g=%h x=%h", $time, io_requestor_3_resp_bits_excp_0_gpf_ld_g, io_requestor_3_resp_bits_excp_0_gpf_ld_x);
      end
      if (io_requestor_3_resp_bits_excp_0_pf_ld_g !== io_requestor_3_resp_bits_excp_0_pf_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_excp_0_pf_ld g=%h x=%h", $time, io_requestor_3_resp_bits_excp_0_pf_ld_g, io_requestor_3_resp_bits_excp_0_pf_ld_x);
      end
      if (io_requestor_3_resp_bits_excp_0_af_ld_g !== io_requestor_3_resp_bits_excp_0_af_ld_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_requestor_3_resp_bits_excp_0_af_ld g=%h x=%h", $time, io_requestor_3_resp_bits_excp_0_af_ld_g, io_requestor_3_resp_bits_excp_0_af_ld_x);
      end
      if (io_ptw_req_0_valid_g !== io_ptw_req_0_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_0_valid g=%h x=%h", $time, io_ptw_req_0_valid_g, io_ptw_req_0_valid_x);
      end
      if (io_ptw_req_0_bits_vpn_g !== io_ptw_req_0_bits_vpn_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_0_bits_vpn g=%h x=%h", $time, io_ptw_req_0_bits_vpn_g, io_ptw_req_0_bits_vpn_x);
      end
      if (io_ptw_req_0_bits_s2xlate_g !== io_ptw_req_0_bits_s2xlate_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_0_bits_s2xlate g=%h x=%h", $time, io_ptw_req_0_bits_s2xlate_g, io_ptw_req_0_bits_s2xlate_x);
      end
      if (io_ptw_req_0_bits_getGpa_g !== io_ptw_req_0_bits_getGpa_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_0_bits_getGpa g=%h x=%h", $time, io_ptw_req_0_bits_getGpa_g, io_ptw_req_0_bits_getGpa_x);
      end
      if (io_ptw_req_1_valid_g !== io_ptw_req_1_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_1_valid g=%h x=%h", $time, io_ptw_req_1_valid_g, io_ptw_req_1_valid_x);
      end
      if (io_ptw_req_1_bits_vpn_g !== io_ptw_req_1_bits_vpn_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_1_bits_vpn g=%h x=%h", $time, io_ptw_req_1_bits_vpn_g, io_ptw_req_1_bits_vpn_x);
      end
      if (io_ptw_req_1_bits_s2xlate_g !== io_ptw_req_1_bits_s2xlate_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_1_bits_s2xlate g=%h x=%h", $time, io_ptw_req_1_bits_s2xlate_g, io_ptw_req_1_bits_s2xlate_x);
      end
      if (io_ptw_req_1_bits_getGpa_g !== io_ptw_req_1_bits_getGpa_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_1_bits_getGpa g=%h x=%h", $time, io_ptw_req_1_bits_getGpa_g, io_ptw_req_1_bits_getGpa_x);
      end
      if (io_ptw_req_2_valid_g !== io_ptw_req_2_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_2_valid g=%h x=%h", $time, io_ptw_req_2_valid_g, io_ptw_req_2_valid_x);
      end
      if (io_ptw_req_2_bits_vpn_g !== io_ptw_req_2_bits_vpn_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_2_bits_vpn g=%h x=%h", $time, io_ptw_req_2_bits_vpn_g, io_ptw_req_2_bits_vpn_x);
      end
      if (io_ptw_req_2_bits_s2xlate_g !== io_ptw_req_2_bits_s2xlate_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_2_bits_s2xlate g=%h x=%h", $time, io_ptw_req_2_bits_s2xlate_g, io_ptw_req_2_bits_s2xlate_x);
      end
      if (io_ptw_req_2_bits_getGpa_g !== io_ptw_req_2_bits_getGpa_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_2_bits_getGpa g=%h x=%h", $time, io_ptw_req_2_bits_getGpa_g, io_ptw_req_2_bits_getGpa_x);
      end
      if (io_ptw_req_3_valid_g !== io_ptw_req_3_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_3_valid g=%h x=%h", $time, io_ptw_req_3_valid_g, io_ptw_req_3_valid_x);
      end
      if (io_ptw_req_3_bits_vpn_g !== io_ptw_req_3_bits_vpn_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_3_bits_vpn g=%h x=%h", $time, io_ptw_req_3_bits_vpn_g, io_ptw_req_3_bits_vpn_x);
      end
      if (io_ptw_req_3_bits_s2xlate_g !== io_ptw_req_3_bits_s2xlate_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_3_bits_s2xlate g=%h x=%h", $time, io_ptw_req_3_bits_s2xlate_g, io_ptw_req_3_bits_s2xlate_x);
      end
      if (io_ptw_req_3_bits_getGpa_g !== io_ptw_req_3_bits_getGpa_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_ptw_req_3_bits_getGpa g=%h x=%h", $time, io_ptw_req_3_bits_getGpa_g, io_ptw_req_3_bits_getGpa_x);
      end
      if (io_pmp_0_valid_g !== io_pmp_0_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_0_valid g=%h x=%h", $time, io_pmp_0_valid_g, io_pmp_0_valid_x);
      end
      if (io_pmp_0_bits_addr_g !== io_pmp_0_bits_addr_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_0_bits_addr g=%h x=%h", $time, io_pmp_0_bits_addr_g, io_pmp_0_bits_addr_x);
      end
      if (io_pmp_0_bits_cmd_g !== io_pmp_0_bits_cmd_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_0_bits_cmd g=%h x=%h", $time, io_pmp_0_bits_cmd_g, io_pmp_0_bits_cmd_x);
      end
      if (io_pmp_1_valid_g !== io_pmp_1_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_1_valid g=%h x=%h", $time, io_pmp_1_valid_g, io_pmp_1_valid_x);
      end
      if (io_pmp_1_bits_addr_g !== io_pmp_1_bits_addr_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_1_bits_addr g=%h x=%h", $time, io_pmp_1_bits_addr_g, io_pmp_1_bits_addr_x);
      end
      if (io_pmp_1_bits_cmd_g !== io_pmp_1_bits_cmd_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_1_bits_cmd g=%h x=%h", $time, io_pmp_1_bits_cmd_g, io_pmp_1_bits_cmd_x);
      end
      if (io_pmp_2_valid_g !== io_pmp_2_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_2_valid g=%h x=%h", $time, io_pmp_2_valid_g, io_pmp_2_valid_x);
      end
      if (io_pmp_2_bits_addr_g !== io_pmp_2_bits_addr_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_2_bits_addr g=%h x=%h", $time, io_pmp_2_bits_addr_g, io_pmp_2_bits_addr_x);
      end
      if (io_pmp_2_bits_cmd_g !== io_pmp_2_bits_cmd_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_2_bits_cmd g=%h x=%h", $time, io_pmp_2_bits_cmd_g, io_pmp_2_bits_cmd_x);
      end
      if (io_pmp_3_valid_g !== io_pmp_3_valid_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_3_valid g=%h x=%h", $time, io_pmp_3_valid_g, io_pmp_3_valid_x);
      end
      if (io_pmp_3_bits_addr_g !== io_pmp_3_bits_addr_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_3_bits_addr g=%h x=%h", $time, io_pmp_3_bits_addr_g, io_pmp_3_bits_addr_x);
      end
      if (io_pmp_3_bits_cmd_g !== io_pmp_3_bits_cmd_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmp_3_bits_cmd g=%h x=%h", $time, io_pmp_3_bits_cmd_g, io_pmp_3_bits_cmd_x);
      end
      if (io_pmpMode_0_g !== io_pmpMode_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmpMode_0 g=%h x=%h", $time, io_pmpMode_0_g, io_pmpMode_0_x);
      end
      if (io_pmpMode_1_g !== io_pmpMode_1_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmpMode_1 g=%h x=%h", $time, io_pmpMode_1_g, io_pmpMode_1_x);
      end
      if (io_pmpMode_2_g !== io_pmpMode_2_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmpMode_2 g=%h x=%h", $time, io_pmpMode_2_g, io_pmpMode_2_x);
      end
      if (io_pmpMode_3_g !== io_pmpMode_3_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_pmpMode_3 g=%h x=%h", $time, io_pmpMode_3_g, io_pmpMode_3_x);
      end
      if (io_tlbreplay_0_g !== io_tlbreplay_0_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_tlbreplay_0 g=%h x=%h", $time, io_tlbreplay_0_g, io_tlbreplay_0_x);
      end
      if (io_tlbreplay_1_g !== io_tlbreplay_1_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_tlbreplay_1 g=%h x=%h", $time, io_tlbreplay_1_g, io_tlbreplay_1_x);
      end
      if (io_tlbreplay_2_g !== io_tlbreplay_2_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_tlbreplay_2 g=%h x=%h", $time, io_tlbreplay_2_g, io_tlbreplay_2_x);
      end
      if (io_tlbreplay_3_g !== io_tlbreplay_3_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_tlbreplay_3 g=%h x=%h", $time, io_tlbreplay_3_g, io_tlbreplay_3_x);
      end
      if (io_perf_0_value_g !== io_perf_0_value_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_perf_0_value g=%h x=%h", $time, io_perf_0_value_g, io_perf_0_value_x);
      end
      if (io_perf_1_value_g !== io_perf_1_value_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t io_perf_1_value g=%h x=%h", $time, io_perf_1_value_g, io_perf_1_value_x);
      end
      if (gatewayIn_packed_53_bore_g !== gatewayIn_packed_53_bore_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t gatewayIn_packed_53_bore g=%h x=%h", $time, gatewayIn_packed_53_bore_g, gatewayIn_packed_53_bore_x);
      end
      if (gatewayIn_packed_54_bore_g !== gatewayIn_packed_54_bore_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t gatewayIn_packed_54_bore g=%h x=%h", $time, gatewayIn_packed_54_bore_g, gatewayIn_packed_54_bore_x);
      end
      if (gatewayIn_packed_55_bore_g !== gatewayIn_packed_55_bore_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t gatewayIn_packed_55_bore g=%h x=%h", $time, gatewayIn_packed_55_bore_g, gatewayIn_packed_55_bore_x);
      end
      if (gatewayIn_packed_56_bore_g !== gatewayIn_packed_56_bore_x) begin
        errors = errors + 1;
        if (errors < 20) $display("MISMATCH @%0t gatewayIn_packed_56_bore g=%h x=%h", $time, gatewayIn_packed_56_bore_g, gatewayIn_packed_56_bore_x);
      end
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    for (i = 0; i < POOL_N; i = i + 1) vpn_pool[i] = {$urandom(), $urandom()};
    cmd_pool[0] = 3'h0; cmd_pool[1] = 3'h1; cmd_pool[2] = 3'h2; cmd_pool[3] = 3'h5;
    mode_pool[0] = 4'h0; mode_pool[1] = 4'h8; mode_pool[2] = 4'h9;
    for (i = 0; i < 4; i = i + 1) asid_pool[i] = 16'($urandom());
    for (i = 0; i < 4; i = i + 1) vmid_pool[i] = 16'($urandom() % 8);
    priv_pool[0] = 2'h0; priv_pool[1] = 2'h1; priv_pool[2] = 2'h3;
    drive_inputs();
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (i = 0; i < ncycles; i = i + 1) begin
      @(posedge clock);
      drive_inputs();
      #1 check_outputs();
    end
    if (errors == 0) $display("TEST PASSED (TLBNonBlock, %0d cycles)", ncycles);
    else $display("TEST FAILED (TLBNonBlock): errors=%0d", errors);
    $finish;
  end
endmodule
