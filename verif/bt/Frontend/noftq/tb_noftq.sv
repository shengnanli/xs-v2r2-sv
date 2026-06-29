// ===========================================================================
// Frontend BT testbench (noftq 子集) —— golden Frontend (u_g) vs Frontend_bt_noftq (u_i)
//   u_i = BPU+IFU+ICache+IBuffer 全重写 + 顶层 glue xs_Frontend_core，Ftq 还原 golden。
//   目的：隔离掉已知 xs_Ftq_core 核内 bug，验证其余四簇+glue 的跨簇集成为 errors=0。
// Frontend BT testbench —— golden Frontend (u_g) vs 全重写装配 Frontend_bt (u_i)
//   由 verif/ut/Frontend/tb.sv 机械变换：仅把第二例化 Frontend_xs -> Frontend_bt
//   （端口逐字相同，激励/检查器复用）。Frontend_bt 内部五大子模块为重写装配
//   （Predictor_it / NewIFU_it / ICache_xs / Ftq_xs / IBuffer_xs）+ 重写顶层
//   glue xs_Frontend_core 在环观察。
//
//   errors      : 顶层全输出 g vs i 逐拍比对（!$isunknown 守门）——BT 主判据。
//   core_errors : 重写顶层 glue 观察核 xs_Frontend_core 的 q 输出 vs golden 内部
//                 同名信号交叉检查（u_g.inner_* vs xs_dbg_*）。注意：u_i 侧喂入观察核
//                 的是【重写子模块】输出，与 u_g 的【golden 子模块】内部信号比对，
//                 属顶层 glue 自洽性观察，非纯功能口；如有分叉单列、不计入 errors 主判据。
//   源自 scripts/gen_frontend.py 生成件。
// ===========================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 4000;
  bit clk = 0, rst;
  int errors = 0, checks = 0, core_errors = 0, nonfunc_errors = 0;
  always #5 clk = ~clk;

  logic auto_inner_icache_ctrlUnitOpt_in_a_valid;
  logic [3:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode;
  logic [1:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_size;
  logic [2:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_source;
  logic [29:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_address;
  logic [7:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_mask;
  logic [63:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_data;
  logic auto_inner_icache_ctrlUnitOpt_in_d_ready;
  logic auto_inner_icache_client_out_a_ready;
  logic auto_inner_icache_client_out_d_valid;
  logic [3:0] auto_inner_icache_client_out_d_bits_opcode;
  logic [2:0] auto_inner_icache_client_out_d_bits_size;
  logic [3:0] auto_inner_icache_client_out_d_bits_source;
  logic [255:0] auto_inner_icache_client_out_d_bits_data;
  logic auto_inner_icache_client_out_d_bits_corrupt;
  logic auto_inner_instrUncache_client_out_a_ready;
  logic auto_inner_instrUncache_client_out_d_valid;
  logic auto_inner_instrUncache_client_out_d_bits_source;
  logic [63:0] auto_inner_instrUncache_client_out_d_bits_data;
  logic auto_inner_instrUncache_client_out_d_bits_corrupt;
  logic [47:0] io_reset_vector;
  logic io_fencei;
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
  logic io_backend_cfVec_0_ready;
  logic io_backend_cfVec_1_ready;
  logic io_backend_cfVec_2_ready;
  logic io_backend_cfVec_3_ready;
  logic io_backend_cfVec_4_ready;
  logic io_backend_cfVec_5_ready;
  logic io_backend_stallReason_backReason_valid;
  logic [5:0] io_backend_stallReason_backReason_bits;
  logic io_backend_toFtq_rob_commits_0_valid;
  logic [2:0] io_backend_toFtq_rob_commits_0_bits_commitType;
  logic io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_0_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_0_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_1_valid;
  logic [2:0] io_backend_toFtq_rob_commits_1_bits_commitType;
  logic io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_1_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_1_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_2_valid;
  logic [2:0] io_backend_toFtq_rob_commits_2_bits_commitType;
  logic io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_2_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_2_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_3_valid;
  logic [2:0] io_backend_toFtq_rob_commits_3_bits_commitType;
  logic io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_3_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_3_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_4_valid;
  logic [2:0] io_backend_toFtq_rob_commits_4_bits_commitType;
  logic io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_4_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_4_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_5_valid;
  logic [2:0] io_backend_toFtq_rob_commits_5_bits_commitType;
  logic io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_5_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_5_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_6_valid;
  logic [2:0] io_backend_toFtq_rob_commits_6_bits_commitType;
  logic io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_6_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_6_bits_ftqOffset;
  logic io_backend_toFtq_rob_commits_7_valid;
  logic [2:0] io_backend_toFtq_rob_commits_7_bits_commitType;
  logic io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_rob_commits_7_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_rob_commits_7_bits_ftqOffset;
  logic io_backend_toFtq_redirect_valid;
  logic io_backend_toFtq_redirect_bits_ftqIdx_flag;
  logic [5:0] io_backend_toFtq_redirect_bits_ftqIdx_value;
  logic [3:0] io_backend_toFtq_redirect_bits_ftqOffset;
  logic io_backend_toFtq_redirect_bits_level;
  logic [49:0] io_backend_toFtq_redirect_bits_cfiUpdate_pc;
  logic [49:0] io_backend_toFtq_redirect_bits_cfiUpdate_target;
  logic io_backend_toFtq_redirect_bits_cfiUpdate_taken;
  logic io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred;
  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF;
  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF;
  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF;
  logic io_backend_toFtq_redirect_bits_debugIsCtrl;
  logic io_backend_toFtq_redirect_bits_debugIsMemVio;
  logic io_backend_toFtq_ftqIdxAhead_0_valid;
  logic [5:0] io_backend_toFtq_ftqIdxAhead_0_bits_value;
  logic [2:0] io_backend_toFtq_ftqIdxSelOH_bits;
  logic io_backend_canAccept;
  logic io_backend_wfi_wfiReq;
  logic io_softPrefetch_0_valid;
  logic [49:0] io_softPrefetch_0_bits_vaddr;
  logic io_softPrefetch_1_valid;
  logic [49:0] io_softPrefetch_1_bits_vaddr;
  logic io_softPrefetch_2_valid;
  logic [49:0] io_softPrefetch_2_bits_vaddr;
  logic io_sfence_valid;
  logic io_sfence_bits_rs1;
  logic io_sfence_bits_rs2;
  logic [49:0] io_sfence_bits_addr;
  logic [15:0] io_sfence_bits_id;
  logic io_sfence_bits_flushPipe;
  logic io_sfence_bits_hv;
  logic io_sfence_bits_hg;
  logic [3:0] io_tlbCsr_satp_mode;
  logic [15:0] io_tlbCsr_satp_asid;
  logic io_tlbCsr_satp_changed;
  logic [3:0] io_tlbCsr_vsatp_mode;
  logic [15:0] io_tlbCsr_vsatp_asid;
  logic io_tlbCsr_vsatp_changed;
  logic [3:0] io_tlbCsr_hgatp_mode;
  logic [15:0] io_tlbCsr_hgatp_vmid;
  logic io_tlbCsr_hgatp_changed;
  logic io_tlbCsr_priv_mxr;
  logic io_tlbCsr_priv_sum;
  logic io_tlbCsr_priv_vmxr;
  logic io_tlbCsr_priv_vsum;
  logic io_tlbCsr_priv_virt;
  logic io_tlbCsr_priv_spvp;
  logic [1:0] io_tlbCsr_priv_imode;
  logic [1:0] io_tlbCsr_priv_dmode;
  logic [1:0] io_tlbCsr_pmm_mseccfg;
  logic [1:0] io_tlbCsr_pmm_menvcfg;
  logic [1:0] io_tlbCsr_pmm_henvcfg;
  logic [1:0] io_tlbCsr_pmm_hstatus;
  logic [1:0] io_tlbCsr_pmm_senvcfg;
  logic io_csrCtrl_pf_ctrl_l1I_pf_enable;
  logic io_csrCtrl_bp_ctrl_ubtb_enable;
  logic io_csrCtrl_bp_ctrl_btb_enable;
  logic io_csrCtrl_bp_ctrl_tage_enable;
  logic io_csrCtrl_bp_ctrl_sc_enable;
  logic io_csrCtrl_bp_ctrl_ras_enable;
  logic io_csrCtrl_ldld_vio_check_enable;
  logic io_csrCtrl_cache_error_enable;
  logic io_csrCtrl_hd_misalign_st_enable;
  logic io_csrCtrl_hd_misalign_ld_enable;
  logic io_csrCtrl_distribute_csr_w_valid;
  logic [11:0] io_csrCtrl_distribute_csr_w_bits_addr;
  logic [63:0] io_csrCtrl_distribute_csr_w_bits_data;
  logic io_csrCtrl_frontend_trigger_tUpdate_valid;
  logic [1:0] io_csrCtrl_frontend_trigger_tUpdate_bits_addr;
  logic [1:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType;
  logic io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select;
  logic [3:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action;
  logic io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain;
  logic [63:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2;
  logic io_csrCtrl_frontend_trigger_tEnableVec_0;
  logic io_csrCtrl_frontend_trigger_tEnableVec_1;
  logic io_csrCtrl_frontend_trigger_tEnableVec_2;
  logic io_csrCtrl_frontend_trigger_tEnableVec_3;
  logic io_csrCtrl_frontend_trigger_debugMode;
  logic io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp;
  logic io_csrCtrl_mem_trigger_tUpdate_valid;
  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_addr;
  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select;
  logic [3:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store;
  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load;
  logic [63:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
  logic io_csrCtrl_mem_trigger_tEnableVec_0;
  logic io_csrCtrl_mem_trigger_tEnableVec_1;
  logic io_csrCtrl_mem_trigger_tEnableVec_2;
  logic io_csrCtrl_mem_trigger_tEnableVec_3;
  logic io_csrCtrl_mem_trigger_debugMode;
  logic io_csrCtrl_mem_trigger_triggerCanRaiseBpExp;
  logic io_csrCtrl_fsIsOff;
  logic io_dft_ram_hold;
  logic io_dft_ram_bypass;
  logic io_dft_ram_bp_clken;
  logic io_dft_ram_aux_clk;
  logic io_dft_ram_aux_ckbp;
  logic io_dft_ram_mcp_hold;
  logic io_dft_cgen;
  wire g_auto_inner_icache_ctrlUnitOpt_in_a_ready;
  wire i_auto_inner_icache_ctrlUnitOpt_in_a_ready;
  wire g_auto_inner_icache_ctrlUnitOpt_in_d_valid;
  wire i_auto_inner_icache_ctrlUnitOpt_in_d_valid;
  wire [3:0] g_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode;
  wire [3:0] i_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode;
  wire [1:0] g_auto_inner_icache_ctrlUnitOpt_in_d_bits_size;
  wire [1:0] i_auto_inner_icache_ctrlUnitOpt_in_d_bits_size;
  wire [2:0] g_auto_inner_icache_ctrlUnitOpt_in_d_bits_source;
  wire [2:0] i_auto_inner_icache_ctrlUnitOpt_in_d_bits_source;
  wire [63:0] g_auto_inner_icache_ctrlUnitOpt_in_d_bits_data;
  wire [63:0] i_auto_inner_icache_ctrlUnitOpt_in_d_bits_data;
  wire g_auto_inner_icache_client_out_a_valid;
  wire i_auto_inner_icache_client_out_a_valid;
  wire [3:0] g_auto_inner_icache_client_out_a_bits_source;
  wire [3:0] i_auto_inner_icache_client_out_a_bits_source;
  wire [47:0] g_auto_inner_icache_client_out_a_bits_address;
  wire [47:0] i_auto_inner_icache_client_out_a_bits_address;
  wire g_auto_inner_instrUncache_client_out_a_valid;
  wire i_auto_inner_instrUncache_client_out_a_valid;
  wire [47:0] g_auto_inner_instrUncache_client_out_a_bits_address;
  wire [47:0] i_auto_inner_instrUncache_client_out_a_bits_address;
  wire g_io_ptw_req_0_valid;
  wire i_io_ptw_req_0_valid;
  wire [37:0] g_io_ptw_req_0_bits_vpn;
  wire [37:0] i_io_ptw_req_0_bits_vpn;
  wire [1:0] g_io_ptw_req_0_bits_s2xlate;
  wire [1:0] i_io_ptw_req_0_bits_s2xlate;
  wire g_io_ptw_resp_ready;
  wire i_io_ptw_resp_ready;
  wire g_io_backend_cfVec_0_valid;
  wire i_io_backend_cfVec_0_valid;
  wire [31:0] g_io_backend_cfVec_0_bits_instr;
  wire [31:0] i_io_backend_cfVec_0_bits_instr;
  wire [9:0] g_io_backend_cfVec_0_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_0_bits_foldpc;
  wire g_io_backend_cfVec_0_bits_exceptionVec_1;
  wire i_io_backend_cfVec_0_bits_exceptionVec_1;
  wire g_io_backend_cfVec_0_bits_exceptionVec_2;
  wire i_io_backend_cfVec_0_bits_exceptionVec_2;
  wire g_io_backend_cfVec_0_bits_exceptionVec_12;
  wire i_io_backend_cfVec_0_bits_exceptionVec_12;
  wire g_io_backend_cfVec_0_bits_exceptionVec_20;
  wire i_io_backend_cfVec_0_bits_exceptionVec_20;
  wire g_io_backend_cfVec_0_bits_backendException;
  wire i_io_backend_cfVec_0_bits_backendException;
  wire [3:0] g_io_backend_cfVec_0_bits_trigger;
  wire [3:0] i_io_backend_cfVec_0_bits_trigger;
  wire g_io_backend_cfVec_0_bits_pd_isRVC;
  wire i_io_backend_cfVec_0_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_0_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_0_bits_pd_brType;
  wire g_io_backend_cfVec_0_bits_pred_taken;
  wire i_io_backend_cfVec_0_bits_pred_taken;
  wire g_io_backend_cfVec_0_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_0_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_0_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_0_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_0_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_0_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_0_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_0_bits_ftqOffset;
  wire g_io_backend_cfVec_0_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_0_bits_isLastInFtqEntry;
  wire g_io_backend_cfVec_1_valid;
  wire i_io_backend_cfVec_1_valid;
  wire [31:0] g_io_backend_cfVec_1_bits_instr;
  wire [31:0] i_io_backend_cfVec_1_bits_instr;
  wire [9:0] g_io_backend_cfVec_1_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_1_bits_foldpc;
  wire g_io_backend_cfVec_1_bits_exceptionVec_1;
  wire i_io_backend_cfVec_1_bits_exceptionVec_1;
  wire g_io_backend_cfVec_1_bits_exceptionVec_2;
  wire i_io_backend_cfVec_1_bits_exceptionVec_2;
  wire g_io_backend_cfVec_1_bits_exceptionVec_12;
  wire i_io_backend_cfVec_1_bits_exceptionVec_12;
  wire g_io_backend_cfVec_1_bits_exceptionVec_20;
  wire i_io_backend_cfVec_1_bits_exceptionVec_20;
  wire g_io_backend_cfVec_1_bits_backendException;
  wire i_io_backend_cfVec_1_bits_backendException;
  wire [3:0] g_io_backend_cfVec_1_bits_trigger;
  wire [3:0] i_io_backend_cfVec_1_bits_trigger;
  wire g_io_backend_cfVec_1_bits_pd_isRVC;
  wire i_io_backend_cfVec_1_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_1_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_1_bits_pd_brType;
  wire g_io_backend_cfVec_1_bits_pred_taken;
  wire i_io_backend_cfVec_1_bits_pred_taken;
  wire g_io_backend_cfVec_1_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_1_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_1_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_1_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_1_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_1_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_1_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_1_bits_ftqOffset;
  wire g_io_backend_cfVec_1_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_1_bits_isLastInFtqEntry;
  wire g_io_backend_cfVec_2_valid;
  wire i_io_backend_cfVec_2_valid;
  wire [31:0] g_io_backend_cfVec_2_bits_instr;
  wire [31:0] i_io_backend_cfVec_2_bits_instr;
  wire [9:0] g_io_backend_cfVec_2_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_2_bits_foldpc;
  wire g_io_backend_cfVec_2_bits_exceptionVec_1;
  wire i_io_backend_cfVec_2_bits_exceptionVec_1;
  wire g_io_backend_cfVec_2_bits_exceptionVec_2;
  wire i_io_backend_cfVec_2_bits_exceptionVec_2;
  wire g_io_backend_cfVec_2_bits_exceptionVec_12;
  wire i_io_backend_cfVec_2_bits_exceptionVec_12;
  wire g_io_backend_cfVec_2_bits_exceptionVec_20;
  wire i_io_backend_cfVec_2_bits_exceptionVec_20;
  wire g_io_backend_cfVec_2_bits_backendException;
  wire i_io_backend_cfVec_2_bits_backendException;
  wire [3:0] g_io_backend_cfVec_2_bits_trigger;
  wire [3:0] i_io_backend_cfVec_2_bits_trigger;
  wire g_io_backend_cfVec_2_bits_pd_isRVC;
  wire i_io_backend_cfVec_2_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_2_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_2_bits_pd_brType;
  wire g_io_backend_cfVec_2_bits_pred_taken;
  wire i_io_backend_cfVec_2_bits_pred_taken;
  wire g_io_backend_cfVec_2_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_2_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_2_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_2_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_2_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_2_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_2_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_2_bits_ftqOffset;
  wire g_io_backend_cfVec_2_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_2_bits_isLastInFtqEntry;
  wire g_io_backend_cfVec_3_valid;
  wire i_io_backend_cfVec_3_valid;
  wire [31:0] g_io_backend_cfVec_3_bits_instr;
  wire [31:0] i_io_backend_cfVec_3_bits_instr;
  wire [9:0] g_io_backend_cfVec_3_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_3_bits_foldpc;
  wire g_io_backend_cfVec_3_bits_exceptionVec_1;
  wire i_io_backend_cfVec_3_bits_exceptionVec_1;
  wire g_io_backend_cfVec_3_bits_exceptionVec_2;
  wire i_io_backend_cfVec_3_bits_exceptionVec_2;
  wire g_io_backend_cfVec_3_bits_exceptionVec_12;
  wire i_io_backend_cfVec_3_bits_exceptionVec_12;
  wire g_io_backend_cfVec_3_bits_exceptionVec_20;
  wire i_io_backend_cfVec_3_bits_exceptionVec_20;
  wire g_io_backend_cfVec_3_bits_backendException;
  wire i_io_backend_cfVec_3_bits_backendException;
  wire [3:0] g_io_backend_cfVec_3_bits_trigger;
  wire [3:0] i_io_backend_cfVec_3_bits_trigger;
  wire g_io_backend_cfVec_3_bits_pd_isRVC;
  wire i_io_backend_cfVec_3_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_3_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_3_bits_pd_brType;
  wire g_io_backend_cfVec_3_bits_pred_taken;
  wire i_io_backend_cfVec_3_bits_pred_taken;
  wire g_io_backend_cfVec_3_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_3_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_3_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_3_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_3_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_3_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_3_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_3_bits_ftqOffset;
  wire g_io_backend_cfVec_3_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_3_bits_isLastInFtqEntry;
  wire g_io_backend_cfVec_4_valid;
  wire i_io_backend_cfVec_4_valid;
  wire [31:0] g_io_backend_cfVec_4_bits_instr;
  wire [31:0] i_io_backend_cfVec_4_bits_instr;
  wire [9:0] g_io_backend_cfVec_4_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_4_bits_foldpc;
  wire g_io_backend_cfVec_4_bits_exceptionVec_1;
  wire i_io_backend_cfVec_4_bits_exceptionVec_1;
  wire g_io_backend_cfVec_4_bits_exceptionVec_2;
  wire i_io_backend_cfVec_4_bits_exceptionVec_2;
  wire g_io_backend_cfVec_4_bits_exceptionVec_12;
  wire i_io_backend_cfVec_4_bits_exceptionVec_12;
  wire g_io_backend_cfVec_4_bits_exceptionVec_20;
  wire i_io_backend_cfVec_4_bits_exceptionVec_20;
  wire g_io_backend_cfVec_4_bits_backendException;
  wire i_io_backend_cfVec_4_bits_backendException;
  wire [3:0] g_io_backend_cfVec_4_bits_trigger;
  wire [3:0] i_io_backend_cfVec_4_bits_trigger;
  wire g_io_backend_cfVec_4_bits_pd_isRVC;
  wire i_io_backend_cfVec_4_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_4_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_4_bits_pd_brType;
  wire g_io_backend_cfVec_4_bits_pred_taken;
  wire i_io_backend_cfVec_4_bits_pred_taken;
  wire g_io_backend_cfVec_4_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_4_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_4_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_4_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_4_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_4_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_4_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_4_bits_ftqOffset;
  wire g_io_backend_cfVec_4_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_4_bits_isLastInFtqEntry;
  wire g_io_backend_cfVec_5_valid;
  wire i_io_backend_cfVec_5_valid;
  wire [31:0] g_io_backend_cfVec_5_bits_instr;
  wire [31:0] i_io_backend_cfVec_5_bits_instr;
  wire [9:0] g_io_backend_cfVec_5_bits_foldpc;
  wire [9:0] i_io_backend_cfVec_5_bits_foldpc;
  wire g_io_backend_cfVec_5_bits_exceptionVec_1;
  wire i_io_backend_cfVec_5_bits_exceptionVec_1;
  wire g_io_backend_cfVec_5_bits_exceptionVec_2;
  wire i_io_backend_cfVec_5_bits_exceptionVec_2;
  wire g_io_backend_cfVec_5_bits_exceptionVec_12;
  wire i_io_backend_cfVec_5_bits_exceptionVec_12;
  wire g_io_backend_cfVec_5_bits_exceptionVec_20;
  wire i_io_backend_cfVec_5_bits_exceptionVec_20;
  wire g_io_backend_cfVec_5_bits_backendException;
  wire i_io_backend_cfVec_5_bits_backendException;
  wire [3:0] g_io_backend_cfVec_5_bits_trigger;
  wire [3:0] i_io_backend_cfVec_5_bits_trigger;
  wire g_io_backend_cfVec_5_bits_pd_isRVC;
  wire i_io_backend_cfVec_5_bits_pd_isRVC;
  wire [1:0] g_io_backend_cfVec_5_bits_pd_brType;
  wire [1:0] i_io_backend_cfVec_5_bits_pd_brType;
  wire g_io_backend_cfVec_5_bits_pred_taken;
  wire i_io_backend_cfVec_5_bits_pred_taken;
  wire g_io_backend_cfVec_5_bits_crossPageIPFFix;
  wire i_io_backend_cfVec_5_bits_crossPageIPFFix;
  wire g_io_backend_cfVec_5_bits_ftqPtr_flag;
  wire i_io_backend_cfVec_5_bits_ftqPtr_flag;
  wire [5:0] g_io_backend_cfVec_5_bits_ftqPtr_value;
  wire [5:0] i_io_backend_cfVec_5_bits_ftqPtr_value;
  wire [3:0] g_io_backend_cfVec_5_bits_ftqOffset;
  wire [3:0] i_io_backend_cfVec_5_bits_ftqOffset;
  wire g_io_backend_cfVec_5_bits_isLastInFtqEntry;
  wire i_io_backend_cfVec_5_bits_isLastInFtqEntry;
  wire [5:0] g_io_backend_stallReason_reason_0;
  wire [5:0] i_io_backend_stallReason_reason_0;
  wire [5:0] g_io_backend_stallReason_reason_1;
  wire [5:0] i_io_backend_stallReason_reason_1;
  wire [5:0] g_io_backend_stallReason_reason_2;
  wire [5:0] i_io_backend_stallReason_reason_2;
  wire [5:0] g_io_backend_stallReason_reason_3;
  wire [5:0] i_io_backend_stallReason_reason_3;
  wire [5:0] g_io_backend_stallReason_reason_4;
  wire [5:0] i_io_backend_stallReason_reason_4;
  wire [5:0] g_io_backend_stallReason_reason_5;
  wire [5:0] i_io_backend_stallReason_reason_5;
  wire g_io_backend_fromFtq_pc_mem_wen;
  wire i_io_backend_fromFtq_pc_mem_wen;
  wire [5:0] g_io_backend_fromFtq_pc_mem_waddr;
  wire [5:0] i_io_backend_fromFtq_pc_mem_waddr;
  wire [49:0] g_io_backend_fromFtq_pc_mem_wdata_startAddr;
  wire [49:0] i_io_backend_fromFtq_pc_mem_wdata_startAddr;
  wire g_io_backend_fromFtq_newest_entry_en;
  wire i_io_backend_fromFtq_newest_entry_en;
  wire [49:0] g_io_backend_fromFtq_newest_entry_target;
  wire [49:0] i_io_backend_fromFtq_newest_entry_target;
  wire [5:0] g_io_backend_fromFtq_newest_entry_ptr_value;
  wire [5:0] i_io_backend_fromFtq_newest_entry_ptr_value;
  wire g_io_backend_fromIfu_gpaddrMem_wen;
  wire i_io_backend_fromIfu_gpaddrMem_wen;
  wire [5:0] g_io_backend_fromIfu_gpaddrMem_waddr;
  wire [5:0] i_io_backend_fromIfu_gpaddrMem_waddr;
  wire [55:0] g_io_backend_fromIfu_gpaddrMem_wdata_gpaddr;
  wire [55:0] i_io_backend_fromIfu_gpaddrMem_wdata_gpaddr;
  wire g_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE;
  wire i_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE;
  wire g_io_backend_wfi_wfiSafe;
  wire i_io_backend_wfi_wfiSafe;
  wire g_io_error_valid;
  wire i_io_error_valid;
  wire [47:0] g_io_error_bits_paddr;
  wire [47:0] i_io_error_bits_paddr;
  wire g_io_error_bits_report_to_beu;
  wire i_io_error_bits_report_to_beu;
  wire g_io_resetInFrontend;
  wire i_io_resetInFrontend;
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
  wire xs_dbg_flush;
  wire xs_dbg_flush_ctrl;
  wire xs_dbg_flush_memvio;
  wire xs_dbg_sfence_q_valid;
  wire xs_dbg_sfence_q_rs1;
  wire xs_dbg_sfence_q_rs2;
  wire [49:0] xs_dbg_sfence_q_addr;
  wire [15:0] xs_dbg_sfence_q_id;
  wire xs_dbg_sfence_q_flushPipe;
  wire xs_dbg_sfence_q_hv;
  wire xs_dbg_sfence_q_hg;
  wire xs_dbg_icache_fencei_q;
  wire xs_dbg_icache_pf_enable_q;
  wire xs_dbg_error_valid_q;
  wire [47:0] xs_dbg_error_paddr_q;
  wire xs_dbg_error_to_beu_q;
  wire xs_dbg_pc_vio;
  wire [5:0] xs_dbg_perf_q_0;
  wire [5:0] xs_dbg_perf_q_1;
  wire [5:0] xs_dbg_perf_q_2;
  wire [5:0] xs_dbg_perf_q_3;
  wire [5:0] xs_dbg_perf_q_4;
  wire [5:0] xs_dbg_perf_q_5;
  wire [5:0] xs_dbg_perf_q_6;
  wire [5:0] xs_dbg_perf_q_7;
  wire [5:0] xs_dbg_perf_q [8];
  assign xs_dbg_perf_q_0 = xs_dbg_perf_q[0];
  assign xs_dbg_perf_q_1 = xs_dbg_perf_q[1];
  assign xs_dbg_perf_q_2 = xs_dbg_perf_q[2];
  assign xs_dbg_perf_q_3 = xs_dbg_perf_q[3];
  assign xs_dbg_perf_q_4 = xs_dbg_perf_q[4];
  assign xs_dbg_perf_q_5 = xs_dbg_perf_q[5];
  assign xs_dbg_perf_q_6 = xs_dbg_perf_q[6];
  assign xs_dbg_perf_q_7 = xs_dbg_perf_q[7];
  Frontend    u_g (.clock(clk), .reset(rst), .auto_inner_icache_ctrlUnitOpt_in_a_valid(auto_inner_icache_ctrlUnitOpt_in_a_valid), .auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode(auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode), .auto_inner_icache_ctrlUnitOpt_in_a_bits_size(auto_inner_icache_ctrlUnitOpt_in_a_bits_size), .auto_inner_icache_ctrlUnitOpt_in_a_bits_source(auto_inner_icache_ctrlUnitOpt_in_a_bits_source), .auto_inner_icache_ctrlUnitOpt_in_a_bits_address(auto_inner_icache_ctrlUnitOpt_in_a_bits_address), .auto_inner_icache_ctrlUnitOpt_in_a_bits_mask(auto_inner_icache_ctrlUnitOpt_in_a_bits_mask), .auto_inner_icache_ctrlUnitOpt_in_a_bits_data(auto_inner_icache_ctrlUnitOpt_in_a_bits_data), .auto_inner_icache_ctrlUnitOpt_in_d_ready(auto_inner_icache_ctrlUnitOpt_in_d_ready), .auto_inner_icache_client_out_a_ready(auto_inner_icache_client_out_a_ready), .auto_inner_icache_client_out_d_valid(auto_inner_icache_client_out_d_valid), .auto_inner_icache_client_out_d_bits_opcode(auto_inner_icache_client_out_d_bits_opcode), .auto_inner_icache_client_out_d_bits_size(auto_inner_icache_client_out_d_bits_size), .auto_inner_icache_client_out_d_bits_source(auto_inner_icache_client_out_d_bits_source), .auto_inner_icache_client_out_d_bits_data(auto_inner_icache_client_out_d_bits_data), .auto_inner_icache_client_out_d_bits_corrupt(auto_inner_icache_client_out_d_bits_corrupt), .auto_inner_instrUncache_client_out_a_ready(auto_inner_instrUncache_client_out_a_ready), .auto_inner_instrUncache_client_out_d_valid(auto_inner_instrUncache_client_out_d_valid), .auto_inner_instrUncache_client_out_d_bits_source(auto_inner_instrUncache_client_out_d_bits_source), .auto_inner_instrUncache_client_out_d_bits_data(auto_inner_instrUncache_client_out_d_bits_data), .auto_inner_instrUncache_client_out_d_bits_corrupt(auto_inner_instrUncache_client_out_d_bits_corrupt), .io_reset_vector(io_reset_vector), .io_fencei(io_fencei), .io_ptw_req_0_ready(io_ptw_req_0_ready), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_backend_cfVec_0_ready(io_backend_cfVec_0_ready), .io_backend_cfVec_1_ready(io_backend_cfVec_1_ready), .io_backend_cfVec_2_ready(io_backend_cfVec_2_ready), .io_backend_cfVec_3_ready(io_backend_cfVec_3_ready), .io_backend_cfVec_4_ready(io_backend_cfVec_4_ready), .io_backend_cfVec_5_ready(io_backend_cfVec_5_ready), .io_backend_stallReason_backReason_valid(io_backend_stallReason_backReason_valid), .io_backend_stallReason_backReason_bits(io_backend_stallReason_backReason_bits), .io_backend_toFtq_rob_commits_0_valid(io_backend_toFtq_rob_commits_0_valid), .io_backend_toFtq_rob_commits_0_bits_commitType(io_backend_toFtq_rob_commits_0_bits_commitType), .io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_0_bits_ftqIdx_value(io_backend_toFtq_rob_commits_0_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_0_bits_ftqOffset(io_backend_toFtq_rob_commits_0_bits_ftqOffset), .io_backend_toFtq_rob_commits_1_valid(io_backend_toFtq_rob_commits_1_valid), .io_backend_toFtq_rob_commits_1_bits_commitType(io_backend_toFtq_rob_commits_1_bits_commitType), .io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_1_bits_ftqIdx_value(io_backend_toFtq_rob_commits_1_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_1_bits_ftqOffset(io_backend_toFtq_rob_commits_1_bits_ftqOffset), .io_backend_toFtq_rob_commits_2_valid(io_backend_toFtq_rob_commits_2_valid), .io_backend_toFtq_rob_commits_2_bits_commitType(io_backend_toFtq_rob_commits_2_bits_commitType), .io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_2_bits_ftqIdx_value(io_backend_toFtq_rob_commits_2_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_2_bits_ftqOffset(io_backend_toFtq_rob_commits_2_bits_ftqOffset), .io_backend_toFtq_rob_commits_3_valid(io_backend_toFtq_rob_commits_3_valid), .io_backend_toFtq_rob_commits_3_bits_commitType(io_backend_toFtq_rob_commits_3_bits_commitType), .io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_3_bits_ftqIdx_value(io_backend_toFtq_rob_commits_3_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_3_bits_ftqOffset(io_backend_toFtq_rob_commits_3_bits_ftqOffset), .io_backend_toFtq_rob_commits_4_valid(io_backend_toFtq_rob_commits_4_valid), .io_backend_toFtq_rob_commits_4_bits_commitType(io_backend_toFtq_rob_commits_4_bits_commitType), .io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_4_bits_ftqIdx_value(io_backend_toFtq_rob_commits_4_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_4_bits_ftqOffset(io_backend_toFtq_rob_commits_4_bits_ftqOffset), .io_backend_toFtq_rob_commits_5_valid(io_backend_toFtq_rob_commits_5_valid), .io_backend_toFtq_rob_commits_5_bits_commitType(io_backend_toFtq_rob_commits_5_bits_commitType), .io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_5_bits_ftqIdx_value(io_backend_toFtq_rob_commits_5_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_5_bits_ftqOffset(io_backend_toFtq_rob_commits_5_bits_ftqOffset), .io_backend_toFtq_rob_commits_6_valid(io_backend_toFtq_rob_commits_6_valid), .io_backend_toFtq_rob_commits_6_bits_commitType(io_backend_toFtq_rob_commits_6_bits_commitType), .io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_6_bits_ftqIdx_value(io_backend_toFtq_rob_commits_6_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_6_bits_ftqOffset(io_backend_toFtq_rob_commits_6_bits_ftqOffset), .io_backend_toFtq_rob_commits_7_valid(io_backend_toFtq_rob_commits_7_valid), .io_backend_toFtq_rob_commits_7_bits_commitType(io_backend_toFtq_rob_commits_7_bits_commitType), .io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_7_bits_ftqIdx_value(io_backend_toFtq_rob_commits_7_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_7_bits_ftqOffset(io_backend_toFtq_rob_commits_7_bits_ftqOffset), .io_backend_toFtq_redirect_valid(io_backend_toFtq_redirect_valid), .io_backend_toFtq_redirect_bits_ftqIdx_flag(io_backend_toFtq_redirect_bits_ftqIdx_flag), .io_backend_toFtq_redirect_bits_ftqIdx_value(io_backend_toFtq_redirect_bits_ftqIdx_value), .io_backend_toFtq_redirect_bits_ftqOffset(io_backend_toFtq_redirect_bits_ftqOffset), .io_backend_toFtq_redirect_bits_level(io_backend_toFtq_redirect_bits_level), .io_backend_toFtq_redirect_bits_cfiUpdate_pc(io_backend_toFtq_redirect_bits_cfiUpdate_pc), .io_backend_toFtq_redirect_bits_cfiUpdate_target(io_backend_toFtq_redirect_bits_cfiUpdate_target), .io_backend_toFtq_redirect_bits_cfiUpdate_taken(io_backend_toFtq_redirect_bits_cfiUpdate_taken), .io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred(io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF), .io_backend_toFtq_redirect_bits_debugIsCtrl(io_backend_toFtq_redirect_bits_debugIsCtrl), .io_backend_toFtq_redirect_bits_debugIsMemVio(io_backend_toFtq_redirect_bits_debugIsMemVio), .io_backend_toFtq_ftqIdxAhead_0_valid(io_backend_toFtq_ftqIdxAhead_0_valid), .io_backend_toFtq_ftqIdxAhead_0_bits_value(io_backend_toFtq_ftqIdxAhead_0_bits_value), .io_backend_toFtq_ftqIdxSelOH_bits(io_backend_toFtq_ftqIdxSelOH_bits), .io_backend_canAccept(io_backend_canAccept), .io_backend_wfi_wfiReq(io_backend_wfi_wfiReq), .io_softPrefetch_0_valid(io_softPrefetch_0_valid), .io_softPrefetch_0_bits_vaddr(io_softPrefetch_0_bits_vaddr), .io_softPrefetch_1_valid(io_softPrefetch_1_valid), .io_softPrefetch_1_bits_vaddr(io_softPrefetch_1_bits_vaddr), .io_softPrefetch_2_valid(io_softPrefetch_2_valid), .io_softPrefetch_2_bits_vaddr(io_softPrefetch_2_bits_vaddr), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_flushPipe(io_sfence_bits_flushPipe), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_tlbCsr_satp_mode(io_tlbCsr_satp_mode), .io_tlbCsr_satp_asid(io_tlbCsr_satp_asid), .io_tlbCsr_satp_changed(io_tlbCsr_satp_changed), .io_tlbCsr_vsatp_mode(io_tlbCsr_vsatp_mode), .io_tlbCsr_vsatp_asid(io_tlbCsr_vsatp_asid), .io_tlbCsr_vsatp_changed(io_tlbCsr_vsatp_changed), .io_tlbCsr_hgatp_mode(io_tlbCsr_hgatp_mode), .io_tlbCsr_hgatp_vmid(io_tlbCsr_hgatp_vmid), .io_tlbCsr_hgatp_changed(io_tlbCsr_hgatp_changed), .io_tlbCsr_priv_mxr(io_tlbCsr_priv_mxr), .io_tlbCsr_priv_sum(io_tlbCsr_priv_sum), .io_tlbCsr_priv_vmxr(io_tlbCsr_priv_vmxr), .io_tlbCsr_priv_vsum(io_tlbCsr_priv_vsum), .io_tlbCsr_priv_virt(io_tlbCsr_priv_virt), .io_tlbCsr_priv_spvp(io_tlbCsr_priv_spvp), .io_tlbCsr_priv_imode(io_tlbCsr_priv_imode), .io_tlbCsr_priv_dmode(io_tlbCsr_priv_dmode), .io_tlbCsr_pmm_mseccfg(io_tlbCsr_pmm_mseccfg), .io_tlbCsr_pmm_menvcfg(io_tlbCsr_pmm_menvcfg), .io_tlbCsr_pmm_henvcfg(io_tlbCsr_pmm_henvcfg), .io_tlbCsr_pmm_hstatus(io_tlbCsr_pmm_hstatus), .io_tlbCsr_pmm_senvcfg(io_tlbCsr_pmm_senvcfg), .io_csrCtrl_pf_ctrl_l1I_pf_enable(io_csrCtrl_pf_ctrl_l1I_pf_enable), .io_csrCtrl_bp_ctrl_ubtb_enable(io_csrCtrl_bp_ctrl_ubtb_enable), .io_csrCtrl_bp_ctrl_btb_enable(io_csrCtrl_bp_ctrl_btb_enable), .io_csrCtrl_bp_ctrl_tage_enable(io_csrCtrl_bp_ctrl_tage_enable), .io_csrCtrl_bp_ctrl_sc_enable(io_csrCtrl_bp_ctrl_sc_enable), .io_csrCtrl_bp_ctrl_ras_enable(io_csrCtrl_bp_ctrl_ras_enable), .io_csrCtrl_ldld_vio_check_enable(io_csrCtrl_ldld_vio_check_enable), .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable), .io_csrCtrl_hd_misalign_st_enable(io_csrCtrl_hd_misalign_st_enable), .io_csrCtrl_hd_misalign_ld_enable(io_csrCtrl_hd_misalign_ld_enable), .io_csrCtrl_distribute_csr_w_valid(io_csrCtrl_distribute_csr_w_valid), .io_csrCtrl_distribute_csr_w_bits_addr(io_csrCtrl_distribute_csr_w_bits_addr), .io_csrCtrl_distribute_csr_w_bits_data(io_csrCtrl_distribute_csr_w_bits_data), .io_csrCtrl_frontend_trigger_tUpdate_valid(io_csrCtrl_frontend_trigger_tUpdate_valid), .io_csrCtrl_frontend_trigger_tUpdate_bits_addr(io_csrCtrl_frontend_trigger_tUpdate_bits_addr), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2), .io_csrCtrl_frontend_trigger_tEnableVec_0(io_csrCtrl_frontend_trigger_tEnableVec_0), .io_csrCtrl_frontend_trigger_tEnableVec_1(io_csrCtrl_frontend_trigger_tEnableVec_1), .io_csrCtrl_frontend_trigger_tEnableVec_2(io_csrCtrl_frontend_trigger_tEnableVec_2), .io_csrCtrl_frontend_trigger_tEnableVec_3(io_csrCtrl_frontend_trigger_tEnableVec_3), .io_csrCtrl_frontend_trigger_debugMode(io_csrCtrl_frontend_trigger_debugMode), .io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp(io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp), .io_csrCtrl_mem_trigger_tUpdate_valid(io_csrCtrl_mem_trigger_tUpdate_valid), .io_csrCtrl_mem_trigger_tUpdate_bits_addr(io_csrCtrl_mem_trigger_tUpdate_bits_addr), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2), .io_csrCtrl_mem_trigger_tEnableVec_0(io_csrCtrl_mem_trigger_tEnableVec_0), .io_csrCtrl_mem_trigger_tEnableVec_1(io_csrCtrl_mem_trigger_tEnableVec_1), .io_csrCtrl_mem_trigger_tEnableVec_2(io_csrCtrl_mem_trigger_tEnableVec_2), .io_csrCtrl_mem_trigger_tEnableVec_3(io_csrCtrl_mem_trigger_tEnableVec_3), .io_csrCtrl_mem_trigger_debugMode(io_csrCtrl_mem_trigger_debugMode), .io_csrCtrl_mem_trigger_triggerCanRaiseBpExp(io_csrCtrl_mem_trigger_triggerCanRaiseBpExp), .io_csrCtrl_fsIsOff(io_csrCtrl_fsIsOff), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen), .auto_inner_icache_ctrlUnitOpt_in_a_ready(g_auto_inner_icache_ctrlUnitOpt_in_a_ready), .auto_inner_icache_ctrlUnitOpt_in_d_valid(g_auto_inner_icache_ctrlUnitOpt_in_d_valid), .auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode), .auto_inner_icache_ctrlUnitOpt_in_d_bits_size(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_size), .auto_inner_icache_ctrlUnitOpt_in_d_bits_source(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_source), .auto_inner_icache_ctrlUnitOpt_in_d_bits_data(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_data), .auto_inner_icache_client_out_a_valid(g_auto_inner_icache_client_out_a_valid), .auto_inner_icache_client_out_a_bits_source(g_auto_inner_icache_client_out_a_bits_source), .auto_inner_icache_client_out_a_bits_address(g_auto_inner_icache_client_out_a_bits_address), .auto_inner_instrUncache_client_out_a_valid(g_auto_inner_instrUncache_client_out_a_valid), .auto_inner_instrUncache_client_out_a_bits_address(g_auto_inner_instrUncache_client_out_a_bits_address), .io_ptw_req_0_valid(g_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(g_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(g_io_ptw_req_0_bits_s2xlate), .io_ptw_resp_ready(g_io_ptw_resp_ready), .io_backend_cfVec_0_valid(g_io_backend_cfVec_0_valid), .io_backend_cfVec_0_bits_instr(g_io_backend_cfVec_0_bits_instr), .io_backend_cfVec_0_bits_foldpc(g_io_backend_cfVec_0_bits_foldpc), .io_backend_cfVec_0_bits_exceptionVec_1(g_io_backend_cfVec_0_bits_exceptionVec_1), .io_backend_cfVec_0_bits_exceptionVec_2(g_io_backend_cfVec_0_bits_exceptionVec_2), .io_backend_cfVec_0_bits_exceptionVec_12(g_io_backend_cfVec_0_bits_exceptionVec_12), .io_backend_cfVec_0_bits_exceptionVec_20(g_io_backend_cfVec_0_bits_exceptionVec_20), .io_backend_cfVec_0_bits_backendException(g_io_backend_cfVec_0_bits_backendException), .io_backend_cfVec_0_bits_trigger(g_io_backend_cfVec_0_bits_trigger), .io_backend_cfVec_0_bits_pd_isRVC(g_io_backend_cfVec_0_bits_pd_isRVC), .io_backend_cfVec_0_bits_pd_brType(g_io_backend_cfVec_0_bits_pd_brType), .io_backend_cfVec_0_bits_pred_taken(g_io_backend_cfVec_0_bits_pred_taken), .io_backend_cfVec_0_bits_crossPageIPFFix(g_io_backend_cfVec_0_bits_crossPageIPFFix), .io_backend_cfVec_0_bits_ftqPtr_flag(g_io_backend_cfVec_0_bits_ftqPtr_flag), .io_backend_cfVec_0_bits_ftqPtr_value(g_io_backend_cfVec_0_bits_ftqPtr_value), .io_backend_cfVec_0_bits_ftqOffset(g_io_backend_cfVec_0_bits_ftqOffset), .io_backend_cfVec_0_bits_isLastInFtqEntry(g_io_backend_cfVec_0_bits_isLastInFtqEntry), .io_backend_cfVec_1_valid(g_io_backend_cfVec_1_valid), .io_backend_cfVec_1_bits_instr(g_io_backend_cfVec_1_bits_instr), .io_backend_cfVec_1_bits_foldpc(g_io_backend_cfVec_1_bits_foldpc), .io_backend_cfVec_1_bits_exceptionVec_1(g_io_backend_cfVec_1_bits_exceptionVec_1), .io_backend_cfVec_1_bits_exceptionVec_2(g_io_backend_cfVec_1_bits_exceptionVec_2), .io_backend_cfVec_1_bits_exceptionVec_12(g_io_backend_cfVec_1_bits_exceptionVec_12), .io_backend_cfVec_1_bits_exceptionVec_20(g_io_backend_cfVec_1_bits_exceptionVec_20), .io_backend_cfVec_1_bits_backendException(g_io_backend_cfVec_1_bits_backendException), .io_backend_cfVec_1_bits_trigger(g_io_backend_cfVec_1_bits_trigger), .io_backend_cfVec_1_bits_pd_isRVC(g_io_backend_cfVec_1_bits_pd_isRVC), .io_backend_cfVec_1_bits_pd_brType(g_io_backend_cfVec_1_bits_pd_brType), .io_backend_cfVec_1_bits_pred_taken(g_io_backend_cfVec_1_bits_pred_taken), .io_backend_cfVec_1_bits_crossPageIPFFix(g_io_backend_cfVec_1_bits_crossPageIPFFix), .io_backend_cfVec_1_bits_ftqPtr_flag(g_io_backend_cfVec_1_bits_ftqPtr_flag), .io_backend_cfVec_1_bits_ftqPtr_value(g_io_backend_cfVec_1_bits_ftqPtr_value), .io_backend_cfVec_1_bits_ftqOffset(g_io_backend_cfVec_1_bits_ftqOffset), .io_backend_cfVec_1_bits_isLastInFtqEntry(g_io_backend_cfVec_1_bits_isLastInFtqEntry), .io_backend_cfVec_2_valid(g_io_backend_cfVec_2_valid), .io_backend_cfVec_2_bits_instr(g_io_backend_cfVec_2_bits_instr), .io_backend_cfVec_2_bits_foldpc(g_io_backend_cfVec_2_bits_foldpc), .io_backend_cfVec_2_bits_exceptionVec_1(g_io_backend_cfVec_2_bits_exceptionVec_1), .io_backend_cfVec_2_bits_exceptionVec_2(g_io_backend_cfVec_2_bits_exceptionVec_2), .io_backend_cfVec_2_bits_exceptionVec_12(g_io_backend_cfVec_2_bits_exceptionVec_12), .io_backend_cfVec_2_bits_exceptionVec_20(g_io_backend_cfVec_2_bits_exceptionVec_20), .io_backend_cfVec_2_bits_backendException(g_io_backend_cfVec_2_bits_backendException), .io_backend_cfVec_2_bits_trigger(g_io_backend_cfVec_2_bits_trigger), .io_backend_cfVec_2_bits_pd_isRVC(g_io_backend_cfVec_2_bits_pd_isRVC), .io_backend_cfVec_2_bits_pd_brType(g_io_backend_cfVec_2_bits_pd_brType), .io_backend_cfVec_2_bits_pred_taken(g_io_backend_cfVec_2_bits_pred_taken), .io_backend_cfVec_2_bits_crossPageIPFFix(g_io_backend_cfVec_2_bits_crossPageIPFFix), .io_backend_cfVec_2_bits_ftqPtr_flag(g_io_backend_cfVec_2_bits_ftqPtr_flag), .io_backend_cfVec_2_bits_ftqPtr_value(g_io_backend_cfVec_2_bits_ftqPtr_value), .io_backend_cfVec_2_bits_ftqOffset(g_io_backend_cfVec_2_bits_ftqOffset), .io_backend_cfVec_2_bits_isLastInFtqEntry(g_io_backend_cfVec_2_bits_isLastInFtqEntry), .io_backend_cfVec_3_valid(g_io_backend_cfVec_3_valid), .io_backend_cfVec_3_bits_instr(g_io_backend_cfVec_3_bits_instr), .io_backend_cfVec_3_bits_foldpc(g_io_backend_cfVec_3_bits_foldpc), .io_backend_cfVec_3_bits_exceptionVec_1(g_io_backend_cfVec_3_bits_exceptionVec_1), .io_backend_cfVec_3_bits_exceptionVec_2(g_io_backend_cfVec_3_bits_exceptionVec_2), .io_backend_cfVec_3_bits_exceptionVec_12(g_io_backend_cfVec_3_bits_exceptionVec_12), .io_backend_cfVec_3_bits_exceptionVec_20(g_io_backend_cfVec_3_bits_exceptionVec_20), .io_backend_cfVec_3_bits_backendException(g_io_backend_cfVec_3_bits_backendException), .io_backend_cfVec_3_bits_trigger(g_io_backend_cfVec_3_bits_trigger), .io_backend_cfVec_3_bits_pd_isRVC(g_io_backend_cfVec_3_bits_pd_isRVC), .io_backend_cfVec_3_bits_pd_brType(g_io_backend_cfVec_3_bits_pd_brType), .io_backend_cfVec_3_bits_pred_taken(g_io_backend_cfVec_3_bits_pred_taken), .io_backend_cfVec_3_bits_crossPageIPFFix(g_io_backend_cfVec_3_bits_crossPageIPFFix), .io_backend_cfVec_3_bits_ftqPtr_flag(g_io_backend_cfVec_3_bits_ftqPtr_flag), .io_backend_cfVec_3_bits_ftqPtr_value(g_io_backend_cfVec_3_bits_ftqPtr_value), .io_backend_cfVec_3_bits_ftqOffset(g_io_backend_cfVec_3_bits_ftqOffset), .io_backend_cfVec_3_bits_isLastInFtqEntry(g_io_backend_cfVec_3_bits_isLastInFtqEntry), .io_backend_cfVec_4_valid(g_io_backend_cfVec_4_valid), .io_backend_cfVec_4_bits_instr(g_io_backend_cfVec_4_bits_instr), .io_backend_cfVec_4_bits_foldpc(g_io_backend_cfVec_4_bits_foldpc), .io_backend_cfVec_4_bits_exceptionVec_1(g_io_backend_cfVec_4_bits_exceptionVec_1), .io_backend_cfVec_4_bits_exceptionVec_2(g_io_backend_cfVec_4_bits_exceptionVec_2), .io_backend_cfVec_4_bits_exceptionVec_12(g_io_backend_cfVec_4_bits_exceptionVec_12), .io_backend_cfVec_4_bits_exceptionVec_20(g_io_backend_cfVec_4_bits_exceptionVec_20), .io_backend_cfVec_4_bits_backendException(g_io_backend_cfVec_4_bits_backendException), .io_backend_cfVec_4_bits_trigger(g_io_backend_cfVec_4_bits_trigger), .io_backend_cfVec_4_bits_pd_isRVC(g_io_backend_cfVec_4_bits_pd_isRVC), .io_backend_cfVec_4_bits_pd_brType(g_io_backend_cfVec_4_bits_pd_brType), .io_backend_cfVec_4_bits_pred_taken(g_io_backend_cfVec_4_bits_pred_taken), .io_backend_cfVec_4_bits_crossPageIPFFix(g_io_backend_cfVec_4_bits_crossPageIPFFix), .io_backend_cfVec_4_bits_ftqPtr_flag(g_io_backend_cfVec_4_bits_ftqPtr_flag), .io_backend_cfVec_4_bits_ftqPtr_value(g_io_backend_cfVec_4_bits_ftqPtr_value), .io_backend_cfVec_4_bits_ftqOffset(g_io_backend_cfVec_4_bits_ftqOffset), .io_backend_cfVec_4_bits_isLastInFtqEntry(g_io_backend_cfVec_4_bits_isLastInFtqEntry), .io_backend_cfVec_5_valid(g_io_backend_cfVec_5_valid), .io_backend_cfVec_5_bits_instr(g_io_backend_cfVec_5_bits_instr), .io_backend_cfVec_5_bits_foldpc(g_io_backend_cfVec_5_bits_foldpc), .io_backend_cfVec_5_bits_exceptionVec_1(g_io_backend_cfVec_5_bits_exceptionVec_1), .io_backend_cfVec_5_bits_exceptionVec_2(g_io_backend_cfVec_5_bits_exceptionVec_2), .io_backend_cfVec_5_bits_exceptionVec_12(g_io_backend_cfVec_5_bits_exceptionVec_12), .io_backend_cfVec_5_bits_exceptionVec_20(g_io_backend_cfVec_5_bits_exceptionVec_20), .io_backend_cfVec_5_bits_backendException(g_io_backend_cfVec_5_bits_backendException), .io_backend_cfVec_5_bits_trigger(g_io_backend_cfVec_5_bits_trigger), .io_backend_cfVec_5_bits_pd_isRVC(g_io_backend_cfVec_5_bits_pd_isRVC), .io_backend_cfVec_5_bits_pd_brType(g_io_backend_cfVec_5_bits_pd_brType), .io_backend_cfVec_5_bits_pred_taken(g_io_backend_cfVec_5_bits_pred_taken), .io_backend_cfVec_5_bits_crossPageIPFFix(g_io_backend_cfVec_5_bits_crossPageIPFFix), .io_backend_cfVec_5_bits_ftqPtr_flag(g_io_backend_cfVec_5_bits_ftqPtr_flag), .io_backend_cfVec_5_bits_ftqPtr_value(g_io_backend_cfVec_5_bits_ftqPtr_value), .io_backend_cfVec_5_bits_ftqOffset(g_io_backend_cfVec_5_bits_ftqOffset), .io_backend_cfVec_5_bits_isLastInFtqEntry(g_io_backend_cfVec_5_bits_isLastInFtqEntry), .io_backend_stallReason_reason_0(g_io_backend_stallReason_reason_0), .io_backend_stallReason_reason_1(g_io_backend_stallReason_reason_1), .io_backend_stallReason_reason_2(g_io_backend_stallReason_reason_2), .io_backend_stallReason_reason_3(g_io_backend_stallReason_reason_3), .io_backend_stallReason_reason_4(g_io_backend_stallReason_reason_4), .io_backend_stallReason_reason_5(g_io_backend_stallReason_reason_5), .io_backend_fromFtq_pc_mem_wen(g_io_backend_fromFtq_pc_mem_wen), .io_backend_fromFtq_pc_mem_waddr(g_io_backend_fromFtq_pc_mem_waddr), .io_backend_fromFtq_pc_mem_wdata_startAddr(g_io_backend_fromFtq_pc_mem_wdata_startAddr), .io_backend_fromFtq_newest_entry_en(g_io_backend_fromFtq_newest_entry_en), .io_backend_fromFtq_newest_entry_target(g_io_backend_fromFtq_newest_entry_target), .io_backend_fromFtq_newest_entry_ptr_value(g_io_backend_fromFtq_newest_entry_ptr_value), .io_backend_fromIfu_gpaddrMem_wen(g_io_backend_fromIfu_gpaddrMem_wen), .io_backend_fromIfu_gpaddrMem_waddr(g_io_backend_fromIfu_gpaddrMem_waddr), .io_backend_fromIfu_gpaddrMem_wdata_gpaddr(g_io_backend_fromIfu_gpaddrMem_wdata_gpaddr), .io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE(g_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE), .io_backend_wfi_wfiSafe(g_io_backend_wfi_wfiSafe), .io_error_valid(g_io_error_valid), .io_error_bits_paddr(g_io_error_bits_paddr), .io_error_bits_report_to_beu(g_io_error_bits_report_to_beu), .io_resetInFrontend(g_io_resetInFrontend), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value));
  Frontend_bt_noftq u_i (.clock(clk), .reset(rst), .auto_inner_icache_ctrlUnitOpt_in_a_valid(auto_inner_icache_ctrlUnitOpt_in_a_valid), .auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode(auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode), .auto_inner_icache_ctrlUnitOpt_in_a_bits_size(auto_inner_icache_ctrlUnitOpt_in_a_bits_size), .auto_inner_icache_ctrlUnitOpt_in_a_bits_source(auto_inner_icache_ctrlUnitOpt_in_a_bits_source), .auto_inner_icache_ctrlUnitOpt_in_a_bits_address(auto_inner_icache_ctrlUnitOpt_in_a_bits_address), .auto_inner_icache_ctrlUnitOpt_in_a_bits_mask(auto_inner_icache_ctrlUnitOpt_in_a_bits_mask), .auto_inner_icache_ctrlUnitOpt_in_a_bits_data(auto_inner_icache_ctrlUnitOpt_in_a_bits_data), .auto_inner_icache_ctrlUnitOpt_in_d_ready(auto_inner_icache_ctrlUnitOpt_in_d_ready), .auto_inner_icache_client_out_a_ready(auto_inner_icache_client_out_a_ready), .auto_inner_icache_client_out_d_valid(auto_inner_icache_client_out_d_valid), .auto_inner_icache_client_out_d_bits_opcode(auto_inner_icache_client_out_d_bits_opcode), .auto_inner_icache_client_out_d_bits_size(auto_inner_icache_client_out_d_bits_size), .auto_inner_icache_client_out_d_bits_source(auto_inner_icache_client_out_d_bits_source), .auto_inner_icache_client_out_d_bits_data(auto_inner_icache_client_out_d_bits_data), .auto_inner_icache_client_out_d_bits_corrupt(auto_inner_icache_client_out_d_bits_corrupt), .auto_inner_instrUncache_client_out_a_ready(auto_inner_instrUncache_client_out_a_ready), .auto_inner_instrUncache_client_out_d_valid(auto_inner_instrUncache_client_out_d_valid), .auto_inner_instrUncache_client_out_d_bits_source(auto_inner_instrUncache_client_out_d_bits_source), .auto_inner_instrUncache_client_out_d_bits_data(auto_inner_instrUncache_client_out_d_bits_data), .auto_inner_instrUncache_client_out_d_bits_corrupt(auto_inner_instrUncache_client_out_d_bits_corrupt), .io_reset_vector(io_reset_vector), .io_fencei(io_fencei), .io_ptw_req_0_ready(io_ptw_req_0_ready), .io_ptw_resp_valid(io_ptw_resp_valid), .io_ptw_resp_bits_s2xlate(io_ptw_resp_bits_s2xlate), .io_ptw_resp_bits_s1_entry_tag(io_ptw_resp_bits_s1_entry_tag), .io_ptw_resp_bits_s1_entry_asid(io_ptw_resp_bits_s1_entry_asid), .io_ptw_resp_bits_s1_entry_vmid(io_ptw_resp_bits_s1_entry_vmid), .io_ptw_resp_bits_s1_entry_n(io_ptw_resp_bits_s1_entry_n), .io_ptw_resp_bits_s1_entry_pbmt(io_ptw_resp_bits_s1_entry_pbmt), .io_ptw_resp_bits_s1_entry_perm_d(io_ptw_resp_bits_s1_entry_perm_d), .io_ptw_resp_bits_s1_entry_perm_a(io_ptw_resp_bits_s1_entry_perm_a), .io_ptw_resp_bits_s1_entry_perm_g(io_ptw_resp_bits_s1_entry_perm_g), .io_ptw_resp_bits_s1_entry_perm_u(io_ptw_resp_bits_s1_entry_perm_u), .io_ptw_resp_bits_s1_entry_perm_x(io_ptw_resp_bits_s1_entry_perm_x), .io_ptw_resp_bits_s1_entry_perm_w(io_ptw_resp_bits_s1_entry_perm_w), .io_ptw_resp_bits_s1_entry_perm_r(io_ptw_resp_bits_s1_entry_perm_r), .io_ptw_resp_bits_s1_entry_level(io_ptw_resp_bits_s1_entry_level), .io_ptw_resp_bits_s1_entry_v(io_ptw_resp_bits_s1_entry_v), .io_ptw_resp_bits_s1_entry_ppn(io_ptw_resp_bits_s1_entry_ppn), .io_ptw_resp_bits_s1_addr_low(io_ptw_resp_bits_s1_addr_low), .io_ptw_resp_bits_s1_ppn_low_0(io_ptw_resp_bits_s1_ppn_low_0), .io_ptw_resp_bits_s1_ppn_low_1(io_ptw_resp_bits_s1_ppn_low_1), .io_ptw_resp_bits_s1_ppn_low_2(io_ptw_resp_bits_s1_ppn_low_2), .io_ptw_resp_bits_s1_ppn_low_3(io_ptw_resp_bits_s1_ppn_low_3), .io_ptw_resp_bits_s1_ppn_low_4(io_ptw_resp_bits_s1_ppn_low_4), .io_ptw_resp_bits_s1_ppn_low_5(io_ptw_resp_bits_s1_ppn_low_5), .io_ptw_resp_bits_s1_ppn_low_6(io_ptw_resp_bits_s1_ppn_low_6), .io_ptw_resp_bits_s1_ppn_low_7(io_ptw_resp_bits_s1_ppn_low_7), .io_ptw_resp_bits_s1_valididx_0(io_ptw_resp_bits_s1_valididx_0), .io_ptw_resp_bits_s1_valididx_1(io_ptw_resp_bits_s1_valididx_1), .io_ptw_resp_bits_s1_valididx_2(io_ptw_resp_bits_s1_valididx_2), .io_ptw_resp_bits_s1_valididx_3(io_ptw_resp_bits_s1_valididx_3), .io_ptw_resp_bits_s1_valididx_4(io_ptw_resp_bits_s1_valididx_4), .io_ptw_resp_bits_s1_valididx_5(io_ptw_resp_bits_s1_valididx_5), .io_ptw_resp_bits_s1_valididx_6(io_ptw_resp_bits_s1_valididx_6), .io_ptw_resp_bits_s1_valididx_7(io_ptw_resp_bits_s1_valididx_7), .io_ptw_resp_bits_s1_pteidx_0(io_ptw_resp_bits_s1_pteidx_0), .io_ptw_resp_bits_s1_pteidx_1(io_ptw_resp_bits_s1_pteidx_1), .io_ptw_resp_bits_s1_pteidx_2(io_ptw_resp_bits_s1_pteidx_2), .io_ptw_resp_bits_s1_pteidx_3(io_ptw_resp_bits_s1_pteidx_3), .io_ptw_resp_bits_s1_pteidx_4(io_ptw_resp_bits_s1_pteidx_4), .io_ptw_resp_bits_s1_pteidx_5(io_ptw_resp_bits_s1_pteidx_5), .io_ptw_resp_bits_s1_pteidx_6(io_ptw_resp_bits_s1_pteidx_6), .io_ptw_resp_bits_s1_pteidx_7(io_ptw_resp_bits_s1_pteidx_7), .io_ptw_resp_bits_s1_pf(io_ptw_resp_bits_s1_pf), .io_ptw_resp_bits_s1_af(io_ptw_resp_bits_s1_af), .io_ptw_resp_bits_s2_entry_tag(io_ptw_resp_bits_s2_entry_tag), .io_ptw_resp_bits_s2_entry_vmid(io_ptw_resp_bits_s2_entry_vmid), .io_ptw_resp_bits_s2_entry_n(io_ptw_resp_bits_s2_entry_n), .io_ptw_resp_bits_s2_entry_pbmt(io_ptw_resp_bits_s2_entry_pbmt), .io_ptw_resp_bits_s2_entry_ppn(io_ptw_resp_bits_s2_entry_ppn), .io_ptw_resp_bits_s2_entry_perm_d(io_ptw_resp_bits_s2_entry_perm_d), .io_ptw_resp_bits_s2_entry_perm_a(io_ptw_resp_bits_s2_entry_perm_a), .io_ptw_resp_bits_s2_entry_perm_g(io_ptw_resp_bits_s2_entry_perm_g), .io_ptw_resp_bits_s2_entry_perm_u(io_ptw_resp_bits_s2_entry_perm_u), .io_ptw_resp_bits_s2_entry_perm_x(io_ptw_resp_bits_s2_entry_perm_x), .io_ptw_resp_bits_s2_entry_perm_w(io_ptw_resp_bits_s2_entry_perm_w), .io_ptw_resp_bits_s2_entry_perm_r(io_ptw_resp_bits_s2_entry_perm_r), .io_ptw_resp_bits_s2_entry_level(io_ptw_resp_bits_s2_entry_level), .io_ptw_resp_bits_s2_gpf(io_ptw_resp_bits_s2_gpf), .io_ptw_resp_bits_s2_gaf(io_ptw_resp_bits_s2_gaf), .io_backend_cfVec_0_ready(io_backend_cfVec_0_ready), .io_backend_cfVec_1_ready(io_backend_cfVec_1_ready), .io_backend_cfVec_2_ready(io_backend_cfVec_2_ready), .io_backend_cfVec_3_ready(io_backend_cfVec_3_ready), .io_backend_cfVec_4_ready(io_backend_cfVec_4_ready), .io_backend_cfVec_5_ready(io_backend_cfVec_5_ready), .io_backend_stallReason_backReason_valid(io_backend_stallReason_backReason_valid), .io_backend_stallReason_backReason_bits(io_backend_stallReason_backReason_bits), .io_backend_toFtq_rob_commits_0_valid(io_backend_toFtq_rob_commits_0_valid), .io_backend_toFtq_rob_commits_0_bits_commitType(io_backend_toFtq_rob_commits_0_bits_commitType), .io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_0_bits_ftqIdx_value(io_backend_toFtq_rob_commits_0_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_0_bits_ftqOffset(io_backend_toFtq_rob_commits_0_bits_ftqOffset), .io_backend_toFtq_rob_commits_1_valid(io_backend_toFtq_rob_commits_1_valid), .io_backend_toFtq_rob_commits_1_bits_commitType(io_backend_toFtq_rob_commits_1_bits_commitType), .io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_1_bits_ftqIdx_value(io_backend_toFtq_rob_commits_1_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_1_bits_ftqOffset(io_backend_toFtq_rob_commits_1_bits_ftqOffset), .io_backend_toFtq_rob_commits_2_valid(io_backend_toFtq_rob_commits_2_valid), .io_backend_toFtq_rob_commits_2_bits_commitType(io_backend_toFtq_rob_commits_2_bits_commitType), .io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_2_bits_ftqIdx_value(io_backend_toFtq_rob_commits_2_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_2_bits_ftqOffset(io_backend_toFtq_rob_commits_2_bits_ftqOffset), .io_backend_toFtq_rob_commits_3_valid(io_backend_toFtq_rob_commits_3_valid), .io_backend_toFtq_rob_commits_3_bits_commitType(io_backend_toFtq_rob_commits_3_bits_commitType), .io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_3_bits_ftqIdx_value(io_backend_toFtq_rob_commits_3_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_3_bits_ftqOffset(io_backend_toFtq_rob_commits_3_bits_ftqOffset), .io_backend_toFtq_rob_commits_4_valid(io_backend_toFtq_rob_commits_4_valid), .io_backend_toFtq_rob_commits_4_bits_commitType(io_backend_toFtq_rob_commits_4_bits_commitType), .io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_4_bits_ftqIdx_value(io_backend_toFtq_rob_commits_4_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_4_bits_ftqOffset(io_backend_toFtq_rob_commits_4_bits_ftqOffset), .io_backend_toFtq_rob_commits_5_valid(io_backend_toFtq_rob_commits_5_valid), .io_backend_toFtq_rob_commits_5_bits_commitType(io_backend_toFtq_rob_commits_5_bits_commitType), .io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_5_bits_ftqIdx_value(io_backend_toFtq_rob_commits_5_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_5_bits_ftqOffset(io_backend_toFtq_rob_commits_5_bits_ftqOffset), .io_backend_toFtq_rob_commits_6_valid(io_backend_toFtq_rob_commits_6_valid), .io_backend_toFtq_rob_commits_6_bits_commitType(io_backend_toFtq_rob_commits_6_bits_commitType), .io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_6_bits_ftqIdx_value(io_backend_toFtq_rob_commits_6_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_6_bits_ftqOffset(io_backend_toFtq_rob_commits_6_bits_ftqOffset), .io_backend_toFtq_rob_commits_7_valid(io_backend_toFtq_rob_commits_7_valid), .io_backend_toFtq_rob_commits_7_bits_commitType(io_backend_toFtq_rob_commits_7_bits_commitType), .io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag(io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag), .io_backend_toFtq_rob_commits_7_bits_ftqIdx_value(io_backend_toFtq_rob_commits_7_bits_ftqIdx_value), .io_backend_toFtq_rob_commits_7_bits_ftqOffset(io_backend_toFtq_rob_commits_7_bits_ftqOffset), .io_backend_toFtq_redirect_valid(io_backend_toFtq_redirect_valid), .io_backend_toFtq_redirect_bits_ftqIdx_flag(io_backend_toFtq_redirect_bits_ftqIdx_flag), .io_backend_toFtq_redirect_bits_ftqIdx_value(io_backend_toFtq_redirect_bits_ftqIdx_value), .io_backend_toFtq_redirect_bits_ftqOffset(io_backend_toFtq_redirect_bits_ftqOffset), .io_backend_toFtq_redirect_bits_level(io_backend_toFtq_redirect_bits_level), .io_backend_toFtq_redirect_bits_cfiUpdate_pc(io_backend_toFtq_redirect_bits_cfiUpdate_pc), .io_backend_toFtq_redirect_bits_cfiUpdate_target(io_backend_toFtq_redirect_bits_cfiUpdate_target), .io_backend_toFtq_redirect_bits_cfiUpdate_taken(io_backend_toFtq_redirect_bits_cfiUpdate_taken), .io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred(io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF), .io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF(io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF), .io_backend_toFtq_redirect_bits_debugIsCtrl(io_backend_toFtq_redirect_bits_debugIsCtrl), .io_backend_toFtq_redirect_bits_debugIsMemVio(io_backend_toFtq_redirect_bits_debugIsMemVio), .io_backend_toFtq_ftqIdxAhead_0_valid(io_backend_toFtq_ftqIdxAhead_0_valid), .io_backend_toFtq_ftqIdxAhead_0_bits_value(io_backend_toFtq_ftqIdxAhead_0_bits_value), .io_backend_toFtq_ftqIdxSelOH_bits(io_backend_toFtq_ftqIdxSelOH_bits), .io_backend_canAccept(io_backend_canAccept), .io_backend_wfi_wfiReq(io_backend_wfi_wfiReq), .io_softPrefetch_0_valid(io_softPrefetch_0_valid), .io_softPrefetch_0_bits_vaddr(io_softPrefetch_0_bits_vaddr), .io_softPrefetch_1_valid(io_softPrefetch_1_valid), .io_softPrefetch_1_bits_vaddr(io_softPrefetch_1_bits_vaddr), .io_softPrefetch_2_valid(io_softPrefetch_2_valid), .io_softPrefetch_2_bits_vaddr(io_softPrefetch_2_bits_vaddr), .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1), .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr), .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_flushPipe(io_sfence_bits_flushPipe), .io_sfence_bits_hv(io_sfence_bits_hv), .io_sfence_bits_hg(io_sfence_bits_hg), .io_tlbCsr_satp_mode(io_tlbCsr_satp_mode), .io_tlbCsr_satp_asid(io_tlbCsr_satp_asid), .io_tlbCsr_satp_changed(io_tlbCsr_satp_changed), .io_tlbCsr_vsatp_mode(io_tlbCsr_vsatp_mode), .io_tlbCsr_vsatp_asid(io_tlbCsr_vsatp_asid), .io_tlbCsr_vsatp_changed(io_tlbCsr_vsatp_changed), .io_tlbCsr_hgatp_mode(io_tlbCsr_hgatp_mode), .io_tlbCsr_hgatp_vmid(io_tlbCsr_hgatp_vmid), .io_tlbCsr_hgatp_changed(io_tlbCsr_hgatp_changed), .io_tlbCsr_priv_mxr(io_tlbCsr_priv_mxr), .io_tlbCsr_priv_sum(io_tlbCsr_priv_sum), .io_tlbCsr_priv_vmxr(io_tlbCsr_priv_vmxr), .io_tlbCsr_priv_vsum(io_tlbCsr_priv_vsum), .io_tlbCsr_priv_virt(io_tlbCsr_priv_virt), .io_tlbCsr_priv_spvp(io_tlbCsr_priv_spvp), .io_tlbCsr_priv_imode(io_tlbCsr_priv_imode), .io_tlbCsr_priv_dmode(io_tlbCsr_priv_dmode), .io_tlbCsr_pmm_mseccfg(io_tlbCsr_pmm_mseccfg), .io_tlbCsr_pmm_menvcfg(io_tlbCsr_pmm_menvcfg), .io_tlbCsr_pmm_henvcfg(io_tlbCsr_pmm_henvcfg), .io_tlbCsr_pmm_hstatus(io_tlbCsr_pmm_hstatus), .io_tlbCsr_pmm_senvcfg(io_tlbCsr_pmm_senvcfg), .io_csrCtrl_pf_ctrl_l1I_pf_enable(io_csrCtrl_pf_ctrl_l1I_pf_enable), .io_csrCtrl_bp_ctrl_ubtb_enable(io_csrCtrl_bp_ctrl_ubtb_enable), .io_csrCtrl_bp_ctrl_btb_enable(io_csrCtrl_bp_ctrl_btb_enable), .io_csrCtrl_bp_ctrl_tage_enable(io_csrCtrl_bp_ctrl_tage_enable), .io_csrCtrl_bp_ctrl_sc_enable(io_csrCtrl_bp_ctrl_sc_enable), .io_csrCtrl_bp_ctrl_ras_enable(io_csrCtrl_bp_ctrl_ras_enable), .io_csrCtrl_ldld_vio_check_enable(io_csrCtrl_ldld_vio_check_enable), .io_csrCtrl_cache_error_enable(io_csrCtrl_cache_error_enable), .io_csrCtrl_hd_misalign_st_enable(io_csrCtrl_hd_misalign_st_enable), .io_csrCtrl_hd_misalign_ld_enable(io_csrCtrl_hd_misalign_ld_enable), .io_csrCtrl_distribute_csr_w_valid(io_csrCtrl_distribute_csr_w_valid), .io_csrCtrl_distribute_csr_w_bits_addr(io_csrCtrl_distribute_csr_w_bits_addr), .io_csrCtrl_distribute_csr_w_bits_data(io_csrCtrl_distribute_csr_w_bits_data), .io_csrCtrl_frontend_trigger_tUpdate_valid(io_csrCtrl_frontend_trigger_tUpdate_valid), .io_csrCtrl_frontend_trigger_tUpdate_bits_addr(io_csrCtrl_frontend_trigger_tUpdate_bits_addr), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain), .io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2), .io_csrCtrl_frontend_trigger_tEnableVec_0(io_csrCtrl_frontend_trigger_tEnableVec_0), .io_csrCtrl_frontend_trigger_tEnableVec_1(io_csrCtrl_frontend_trigger_tEnableVec_1), .io_csrCtrl_frontend_trigger_tEnableVec_2(io_csrCtrl_frontend_trigger_tEnableVec_2), .io_csrCtrl_frontend_trigger_tEnableVec_3(io_csrCtrl_frontend_trigger_tEnableVec_3), .io_csrCtrl_frontend_trigger_debugMode(io_csrCtrl_frontend_trigger_debugMode), .io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp(io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp), .io_csrCtrl_mem_trigger_tUpdate_valid(io_csrCtrl_mem_trigger_tUpdate_valid), .io_csrCtrl_mem_trigger_tUpdate_bits_addr(io_csrCtrl_mem_trigger_tUpdate_bits_addr), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load), .io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2), .io_csrCtrl_mem_trigger_tEnableVec_0(io_csrCtrl_mem_trigger_tEnableVec_0), .io_csrCtrl_mem_trigger_tEnableVec_1(io_csrCtrl_mem_trigger_tEnableVec_1), .io_csrCtrl_mem_trigger_tEnableVec_2(io_csrCtrl_mem_trigger_tEnableVec_2), .io_csrCtrl_mem_trigger_tEnableVec_3(io_csrCtrl_mem_trigger_tEnableVec_3), .io_csrCtrl_mem_trigger_debugMode(io_csrCtrl_mem_trigger_debugMode), .io_csrCtrl_mem_trigger_triggerCanRaiseBpExp(io_csrCtrl_mem_trigger_triggerCanRaiseBpExp), .io_csrCtrl_fsIsOff(io_csrCtrl_fsIsOff), .io_dft_ram_hold(io_dft_ram_hold), .io_dft_ram_bypass(io_dft_ram_bypass), .io_dft_ram_bp_clken(io_dft_ram_bp_clken), .io_dft_ram_aux_clk(io_dft_ram_aux_clk), .io_dft_ram_aux_ckbp(io_dft_ram_aux_ckbp), .io_dft_ram_mcp_hold(io_dft_ram_mcp_hold), .io_dft_cgen(io_dft_cgen), .auto_inner_icache_ctrlUnitOpt_in_a_ready(i_auto_inner_icache_ctrlUnitOpt_in_a_ready), .auto_inner_icache_ctrlUnitOpt_in_d_valid(i_auto_inner_icache_ctrlUnitOpt_in_d_valid), .auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode(i_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode), .auto_inner_icache_ctrlUnitOpt_in_d_bits_size(i_auto_inner_icache_ctrlUnitOpt_in_d_bits_size), .auto_inner_icache_ctrlUnitOpt_in_d_bits_source(i_auto_inner_icache_ctrlUnitOpt_in_d_bits_source), .auto_inner_icache_ctrlUnitOpt_in_d_bits_data(i_auto_inner_icache_ctrlUnitOpt_in_d_bits_data), .auto_inner_icache_client_out_a_valid(i_auto_inner_icache_client_out_a_valid), .auto_inner_icache_client_out_a_bits_source(i_auto_inner_icache_client_out_a_bits_source), .auto_inner_icache_client_out_a_bits_address(i_auto_inner_icache_client_out_a_bits_address), .auto_inner_instrUncache_client_out_a_valid(i_auto_inner_instrUncache_client_out_a_valid), .auto_inner_instrUncache_client_out_a_bits_address(i_auto_inner_instrUncache_client_out_a_bits_address), .io_ptw_req_0_valid(i_io_ptw_req_0_valid), .io_ptw_req_0_bits_vpn(i_io_ptw_req_0_bits_vpn), .io_ptw_req_0_bits_s2xlate(i_io_ptw_req_0_bits_s2xlate), .io_ptw_resp_ready(i_io_ptw_resp_ready), .io_backend_cfVec_0_valid(i_io_backend_cfVec_0_valid), .io_backend_cfVec_0_bits_instr(i_io_backend_cfVec_0_bits_instr), .io_backend_cfVec_0_bits_foldpc(i_io_backend_cfVec_0_bits_foldpc), .io_backend_cfVec_0_bits_exceptionVec_1(i_io_backend_cfVec_0_bits_exceptionVec_1), .io_backend_cfVec_0_bits_exceptionVec_2(i_io_backend_cfVec_0_bits_exceptionVec_2), .io_backend_cfVec_0_bits_exceptionVec_12(i_io_backend_cfVec_0_bits_exceptionVec_12), .io_backend_cfVec_0_bits_exceptionVec_20(i_io_backend_cfVec_0_bits_exceptionVec_20), .io_backend_cfVec_0_bits_backendException(i_io_backend_cfVec_0_bits_backendException), .io_backend_cfVec_0_bits_trigger(i_io_backend_cfVec_0_bits_trigger), .io_backend_cfVec_0_bits_pd_isRVC(i_io_backend_cfVec_0_bits_pd_isRVC), .io_backend_cfVec_0_bits_pd_brType(i_io_backend_cfVec_0_bits_pd_brType), .io_backend_cfVec_0_bits_pred_taken(i_io_backend_cfVec_0_bits_pred_taken), .io_backend_cfVec_0_bits_crossPageIPFFix(i_io_backend_cfVec_0_bits_crossPageIPFFix), .io_backend_cfVec_0_bits_ftqPtr_flag(i_io_backend_cfVec_0_bits_ftqPtr_flag), .io_backend_cfVec_0_bits_ftqPtr_value(i_io_backend_cfVec_0_bits_ftqPtr_value), .io_backend_cfVec_0_bits_ftqOffset(i_io_backend_cfVec_0_bits_ftqOffset), .io_backend_cfVec_0_bits_isLastInFtqEntry(i_io_backend_cfVec_0_bits_isLastInFtqEntry), .io_backend_cfVec_1_valid(i_io_backend_cfVec_1_valid), .io_backend_cfVec_1_bits_instr(i_io_backend_cfVec_1_bits_instr), .io_backend_cfVec_1_bits_foldpc(i_io_backend_cfVec_1_bits_foldpc), .io_backend_cfVec_1_bits_exceptionVec_1(i_io_backend_cfVec_1_bits_exceptionVec_1), .io_backend_cfVec_1_bits_exceptionVec_2(i_io_backend_cfVec_1_bits_exceptionVec_2), .io_backend_cfVec_1_bits_exceptionVec_12(i_io_backend_cfVec_1_bits_exceptionVec_12), .io_backend_cfVec_1_bits_exceptionVec_20(i_io_backend_cfVec_1_bits_exceptionVec_20), .io_backend_cfVec_1_bits_backendException(i_io_backend_cfVec_1_bits_backendException), .io_backend_cfVec_1_bits_trigger(i_io_backend_cfVec_1_bits_trigger), .io_backend_cfVec_1_bits_pd_isRVC(i_io_backend_cfVec_1_bits_pd_isRVC), .io_backend_cfVec_1_bits_pd_brType(i_io_backend_cfVec_1_bits_pd_brType), .io_backend_cfVec_1_bits_pred_taken(i_io_backend_cfVec_1_bits_pred_taken), .io_backend_cfVec_1_bits_crossPageIPFFix(i_io_backend_cfVec_1_bits_crossPageIPFFix), .io_backend_cfVec_1_bits_ftqPtr_flag(i_io_backend_cfVec_1_bits_ftqPtr_flag), .io_backend_cfVec_1_bits_ftqPtr_value(i_io_backend_cfVec_1_bits_ftqPtr_value), .io_backend_cfVec_1_bits_ftqOffset(i_io_backend_cfVec_1_bits_ftqOffset), .io_backend_cfVec_1_bits_isLastInFtqEntry(i_io_backend_cfVec_1_bits_isLastInFtqEntry), .io_backend_cfVec_2_valid(i_io_backend_cfVec_2_valid), .io_backend_cfVec_2_bits_instr(i_io_backend_cfVec_2_bits_instr), .io_backend_cfVec_2_bits_foldpc(i_io_backend_cfVec_2_bits_foldpc), .io_backend_cfVec_2_bits_exceptionVec_1(i_io_backend_cfVec_2_bits_exceptionVec_1), .io_backend_cfVec_2_bits_exceptionVec_2(i_io_backend_cfVec_2_bits_exceptionVec_2), .io_backend_cfVec_2_bits_exceptionVec_12(i_io_backend_cfVec_2_bits_exceptionVec_12), .io_backend_cfVec_2_bits_exceptionVec_20(i_io_backend_cfVec_2_bits_exceptionVec_20), .io_backend_cfVec_2_bits_backendException(i_io_backend_cfVec_2_bits_backendException), .io_backend_cfVec_2_bits_trigger(i_io_backend_cfVec_2_bits_trigger), .io_backend_cfVec_2_bits_pd_isRVC(i_io_backend_cfVec_2_bits_pd_isRVC), .io_backend_cfVec_2_bits_pd_brType(i_io_backend_cfVec_2_bits_pd_brType), .io_backend_cfVec_2_bits_pred_taken(i_io_backend_cfVec_2_bits_pred_taken), .io_backend_cfVec_2_bits_crossPageIPFFix(i_io_backend_cfVec_2_bits_crossPageIPFFix), .io_backend_cfVec_2_bits_ftqPtr_flag(i_io_backend_cfVec_2_bits_ftqPtr_flag), .io_backend_cfVec_2_bits_ftqPtr_value(i_io_backend_cfVec_2_bits_ftqPtr_value), .io_backend_cfVec_2_bits_ftqOffset(i_io_backend_cfVec_2_bits_ftqOffset), .io_backend_cfVec_2_bits_isLastInFtqEntry(i_io_backend_cfVec_2_bits_isLastInFtqEntry), .io_backend_cfVec_3_valid(i_io_backend_cfVec_3_valid), .io_backend_cfVec_3_bits_instr(i_io_backend_cfVec_3_bits_instr), .io_backend_cfVec_3_bits_foldpc(i_io_backend_cfVec_3_bits_foldpc), .io_backend_cfVec_3_bits_exceptionVec_1(i_io_backend_cfVec_3_bits_exceptionVec_1), .io_backend_cfVec_3_bits_exceptionVec_2(i_io_backend_cfVec_3_bits_exceptionVec_2), .io_backend_cfVec_3_bits_exceptionVec_12(i_io_backend_cfVec_3_bits_exceptionVec_12), .io_backend_cfVec_3_bits_exceptionVec_20(i_io_backend_cfVec_3_bits_exceptionVec_20), .io_backend_cfVec_3_bits_backendException(i_io_backend_cfVec_3_bits_backendException), .io_backend_cfVec_3_bits_trigger(i_io_backend_cfVec_3_bits_trigger), .io_backend_cfVec_3_bits_pd_isRVC(i_io_backend_cfVec_3_bits_pd_isRVC), .io_backend_cfVec_3_bits_pd_brType(i_io_backend_cfVec_3_bits_pd_brType), .io_backend_cfVec_3_bits_pred_taken(i_io_backend_cfVec_3_bits_pred_taken), .io_backend_cfVec_3_bits_crossPageIPFFix(i_io_backend_cfVec_3_bits_crossPageIPFFix), .io_backend_cfVec_3_bits_ftqPtr_flag(i_io_backend_cfVec_3_bits_ftqPtr_flag), .io_backend_cfVec_3_bits_ftqPtr_value(i_io_backend_cfVec_3_bits_ftqPtr_value), .io_backend_cfVec_3_bits_ftqOffset(i_io_backend_cfVec_3_bits_ftqOffset), .io_backend_cfVec_3_bits_isLastInFtqEntry(i_io_backend_cfVec_3_bits_isLastInFtqEntry), .io_backend_cfVec_4_valid(i_io_backend_cfVec_4_valid), .io_backend_cfVec_4_bits_instr(i_io_backend_cfVec_4_bits_instr), .io_backend_cfVec_4_bits_foldpc(i_io_backend_cfVec_4_bits_foldpc), .io_backend_cfVec_4_bits_exceptionVec_1(i_io_backend_cfVec_4_bits_exceptionVec_1), .io_backend_cfVec_4_bits_exceptionVec_2(i_io_backend_cfVec_4_bits_exceptionVec_2), .io_backend_cfVec_4_bits_exceptionVec_12(i_io_backend_cfVec_4_bits_exceptionVec_12), .io_backend_cfVec_4_bits_exceptionVec_20(i_io_backend_cfVec_4_bits_exceptionVec_20), .io_backend_cfVec_4_bits_backendException(i_io_backend_cfVec_4_bits_backendException), .io_backend_cfVec_4_bits_trigger(i_io_backend_cfVec_4_bits_trigger), .io_backend_cfVec_4_bits_pd_isRVC(i_io_backend_cfVec_4_bits_pd_isRVC), .io_backend_cfVec_4_bits_pd_brType(i_io_backend_cfVec_4_bits_pd_brType), .io_backend_cfVec_4_bits_pred_taken(i_io_backend_cfVec_4_bits_pred_taken), .io_backend_cfVec_4_bits_crossPageIPFFix(i_io_backend_cfVec_4_bits_crossPageIPFFix), .io_backend_cfVec_4_bits_ftqPtr_flag(i_io_backend_cfVec_4_bits_ftqPtr_flag), .io_backend_cfVec_4_bits_ftqPtr_value(i_io_backend_cfVec_4_bits_ftqPtr_value), .io_backend_cfVec_4_bits_ftqOffset(i_io_backend_cfVec_4_bits_ftqOffset), .io_backend_cfVec_4_bits_isLastInFtqEntry(i_io_backend_cfVec_4_bits_isLastInFtqEntry), .io_backend_cfVec_5_valid(i_io_backend_cfVec_5_valid), .io_backend_cfVec_5_bits_instr(i_io_backend_cfVec_5_bits_instr), .io_backend_cfVec_5_bits_foldpc(i_io_backend_cfVec_5_bits_foldpc), .io_backend_cfVec_5_bits_exceptionVec_1(i_io_backend_cfVec_5_bits_exceptionVec_1), .io_backend_cfVec_5_bits_exceptionVec_2(i_io_backend_cfVec_5_bits_exceptionVec_2), .io_backend_cfVec_5_bits_exceptionVec_12(i_io_backend_cfVec_5_bits_exceptionVec_12), .io_backend_cfVec_5_bits_exceptionVec_20(i_io_backend_cfVec_5_bits_exceptionVec_20), .io_backend_cfVec_5_bits_backendException(i_io_backend_cfVec_5_bits_backendException), .io_backend_cfVec_5_bits_trigger(i_io_backend_cfVec_5_bits_trigger), .io_backend_cfVec_5_bits_pd_isRVC(i_io_backend_cfVec_5_bits_pd_isRVC), .io_backend_cfVec_5_bits_pd_brType(i_io_backend_cfVec_5_bits_pd_brType), .io_backend_cfVec_5_bits_pred_taken(i_io_backend_cfVec_5_bits_pred_taken), .io_backend_cfVec_5_bits_crossPageIPFFix(i_io_backend_cfVec_5_bits_crossPageIPFFix), .io_backend_cfVec_5_bits_ftqPtr_flag(i_io_backend_cfVec_5_bits_ftqPtr_flag), .io_backend_cfVec_5_bits_ftqPtr_value(i_io_backend_cfVec_5_bits_ftqPtr_value), .io_backend_cfVec_5_bits_ftqOffset(i_io_backend_cfVec_5_bits_ftqOffset), .io_backend_cfVec_5_bits_isLastInFtqEntry(i_io_backend_cfVec_5_bits_isLastInFtqEntry), .io_backend_stallReason_reason_0(i_io_backend_stallReason_reason_0), .io_backend_stallReason_reason_1(i_io_backend_stallReason_reason_1), .io_backend_stallReason_reason_2(i_io_backend_stallReason_reason_2), .io_backend_stallReason_reason_3(i_io_backend_stallReason_reason_3), .io_backend_stallReason_reason_4(i_io_backend_stallReason_reason_4), .io_backend_stallReason_reason_5(i_io_backend_stallReason_reason_5), .io_backend_fromFtq_pc_mem_wen(i_io_backend_fromFtq_pc_mem_wen), .io_backend_fromFtq_pc_mem_waddr(i_io_backend_fromFtq_pc_mem_waddr), .io_backend_fromFtq_pc_mem_wdata_startAddr(i_io_backend_fromFtq_pc_mem_wdata_startAddr), .io_backend_fromFtq_newest_entry_en(i_io_backend_fromFtq_newest_entry_en), .io_backend_fromFtq_newest_entry_target(i_io_backend_fromFtq_newest_entry_target), .io_backend_fromFtq_newest_entry_ptr_value(i_io_backend_fromFtq_newest_entry_ptr_value), .io_backend_fromIfu_gpaddrMem_wen(i_io_backend_fromIfu_gpaddrMem_wen), .io_backend_fromIfu_gpaddrMem_waddr(i_io_backend_fromIfu_gpaddrMem_waddr), .io_backend_fromIfu_gpaddrMem_wdata_gpaddr(i_io_backend_fromIfu_gpaddrMem_wdata_gpaddr), .io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE(i_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE), .io_backend_wfi_wfiSafe(i_io_backend_wfi_wfiSafe), .io_error_valid(i_io_error_valid), .io_error_bits_paddr(i_io_error_bits_paddr), .io_error_bits_report_to_beu(i_io_error_bits_report_to_beu), .io_resetInFrontend(i_io_resetInFrontend), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .xs_dbg_flush(xs_dbg_flush), .xs_dbg_flush_ctrl(xs_dbg_flush_ctrl), .xs_dbg_flush_memvio(xs_dbg_flush_memvio), .xs_dbg_sfence_q_valid(xs_dbg_sfence_q_valid), .xs_dbg_sfence_q_rs1(xs_dbg_sfence_q_rs1), .xs_dbg_sfence_q_rs2(xs_dbg_sfence_q_rs2), .xs_dbg_sfence_q_addr(xs_dbg_sfence_q_addr), .xs_dbg_sfence_q_id(xs_dbg_sfence_q_id), .xs_dbg_sfence_q_flushPipe(xs_dbg_sfence_q_flushPipe), .xs_dbg_sfence_q_hv(xs_dbg_sfence_q_hv), .xs_dbg_sfence_q_hg(xs_dbg_sfence_q_hg), .xs_dbg_icache_fencei_q(xs_dbg_icache_fencei_q), .xs_dbg_icache_pf_enable_q(xs_dbg_icache_pf_enable_q), .xs_dbg_error_valid_q(xs_dbg_error_valid_q), .xs_dbg_error_paddr_q(xs_dbg_error_paddr_q), .xs_dbg_error_to_beu_q(xs_dbg_error_to_beu_q), .xs_dbg_pc_vio(xs_dbg_pc_vio), .xs_dbg_perf_q(xs_dbg_perf_q));
  always @(negedge clk) begin
    if (rst) begin
      io_sfence_valid <= 1'b0;
      io_backend_toFtq_redirect_valid <= 1'b0;
      io_ptw_resp_valid <= 1'b0;
      io_ptw_req_0_ready <= 1'b0;
      io_backend_canAccept <= 1'b0;
      io_backend_wfi_wfiReq <= 1'b0;
      io_softPrefetch_0_valid <= 1'b0;
      io_softPrefetch_1_valid <= 1'b0;
      io_softPrefetch_2_valid <= 1'b0;
      auto_inner_icache_ctrlUnitOpt_in_a_valid <= 1'b0;
      auto_inner_icache_ctrlUnitOpt_in_d_ready <= 1'b0;
      auto_inner_icache_client_out_a_ready <= 1'b0;
      auto_inner_icache_client_out_d_valid <= 1'b0;
      auto_inner_instrUncache_client_out_a_ready <= 1'b0;
      auto_inner_instrUncache_client_out_d_valid <= 1'b0;
      io_backend_toFtq_rob_commits_0_valid <= 1'b0;
      io_backend_toFtq_rob_commits_1_valid <= 1'b0;
      io_backend_toFtq_rob_commits_2_valid <= 1'b0;
      io_backend_toFtq_rob_commits_3_valid <= 1'b0;
      io_backend_toFtq_rob_commits_4_valid <= 1'b0;
      io_backend_toFtq_rob_commits_5_valid <= 1'b0;
      io_backend_toFtq_rob_commits_6_valid <= 1'b0;
      io_backend_toFtq_rob_commits_7_valid <= 1'b0;
      io_backend_cfVec_0_ready <= 1'b0;
      io_backend_cfVec_1_ready <= 1'b0;
      io_backend_cfVec_2_ready <= 1'b0;
      io_backend_cfVec_3_ready <= 1'b0;
      io_backend_cfVec_4_ready <= 1'b0;
      io_backend_cfVec_5_ready <= 1'b0;
    end else begin
      auto_inner_icache_ctrlUnitOpt_in_a_valid <= ($urandom_range(0,3)==0);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode <= 4'($urandom);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_size <= 2'($urandom);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_source <= 3'($urandom);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_address <= 30'($urandom);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_mask <= 8'($urandom);
      auto_inner_icache_ctrlUnitOpt_in_a_bits_data <= 64'({$urandom(), $urandom()});
      auto_inner_icache_ctrlUnitOpt_in_d_ready <= ($urandom_range(0,1)==0);
      auto_inner_icache_client_out_a_ready <= ($urandom_range(0,1)==0);
      auto_inner_icache_client_out_d_valid <= ($urandom_range(0,2)==0);
      auto_inner_icache_client_out_d_bits_opcode <= 4'($urandom);
      auto_inner_icache_client_out_d_bits_size <= 3'($urandom);
      auto_inner_icache_client_out_d_bits_source <= 4'($urandom);
      auto_inner_icache_client_out_d_bits_data <= 256'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      auto_inner_icache_client_out_d_bits_corrupt <= 1'($urandom);
      auto_inner_instrUncache_client_out_a_ready <= ($urandom_range(0,1)==0);
      auto_inner_instrUncache_client_out_d_valid <= ($urandom_range(0,3)==0);
      auto_inner_instrUncache_client_out_d_bits_source <= 1'($urandom);
      auto_inner_instrUncache_client_out_d_bits_data <= 64'({$urandom(), $urandom()});
      auto_inner_instrUncache_client_out_d_bits_corrupt <= 1'($urandom);
      io_reset_vector <= 48'($urandom);
      io_fencei <= ($urandom_range(0,63)==0);
      io_ptw_req_0_ready <= ($urandom_range(0,1)==0);
      io_ptw_resp_valid <= ($urandom_range(0,3)!=0);
      io_ptw_resp_bits_s2xlate <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_tag <= 35'({$urandom(), $urandom()});
      io_ptw_resp_bits_s1_entry_asid <= 16'($urandom);
      io_ptw_resp_bits_s1_entry_vmid <= 14'($urandom);
      io_ptw_resp_bits_s1_entry_n <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_pbmt <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_perm_d <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_a <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_g <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_u <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_x <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_w <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_perm_r <= 1'($urandom);
      io_ptw_resp_bits_s1_entry_level <= 2'($urandom);
      io_ptw_resp_bits_s1_entry_v <= 1'($urandom);
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
      io_ptw_resp_bits_s1_valididx_0 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_1 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_2 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_3 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_4 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_5 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_6 <= 1'($urandom);
      io_ptw_resp_bits_s1_valididx_7 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_0 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_1 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_2 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_3 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_4 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_5 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_6 <= 1'($urandom);
      io_ptw_resp_bits_s1_pteidx_7 <= 1'($urandom);
      io_ptw_resp_bits_s1_pf <= 1'($urandom);
      io_ptw_resp_bits_s1_af <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_tag <= 38'({$urandom(), $urandom()});
      io_ptw_resp_bits_s2_entry_vmid <= 14'($urandom);
      io_ptw_resp_bits_s2_entry_n <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_pbmt <= 2'($urandom);
      io_ptw_resp_bits_s2_entry_ppn <= 38'({$urandom(), $urandom()});
      io_ptw_resp_bits_s2_entry_perm_d <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_a <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_g <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_u <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_x <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_w <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_perm_r <= 1'($urandom);
      io_ptw_resp_bits_s2_entry_level <= 2'($urandom);
      io_ptw_resp_bits_s2_gpf <= 1'($urandom);
      io_ptw_resp_bits_s2_gaf <= 1'($urandom);
      io_backend_cfVec_0_ready <= ($urandom_range(0,4)!=0);
      io_backend_cfVec_1_ready <= ($urandom_range(0,4)!=0);
      io_backend_cfVec_2_ready <= ($urandom_range(0,4)!=0);
      io_backend_cfVec_3_ready <= ($urandom_range(0,4)!=0);
      io_backend_cfVec_4_ready <= ($urandom_range(0,4)!=0);
      io_backend_cfVec_5_ready <= ($urandom_range(0,4)!=0);
      io_backend_stallReason_backReason_valid <= 1'($urandom);
      io_backend_stallReason_backReason_bits <= 6'($urandom);
      io_backend_toFtq_rob_commits_0_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_0_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_0_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_0_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_1_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_1_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_1_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_1_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_2_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_2_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_2_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_2_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_3_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_3_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_3_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_3_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_4_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_4_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_4_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_4_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_5_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_5_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_5_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_5_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_6_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_6_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_6_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_6_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_rob_commits_7_valid <= ($urandom_range(0,2)!=0);
      io_backend_toFtq_rob_commits_7_bits_commitType <= 3'($urandom);
      io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_rob_commits_7_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_rob_commits_7_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_redirect_valid <= ($urandom_range(0,15)==0);
      io_backend_toFtq_redirect_bits_ftqIdx_flag <= 1'($urandom);
      io_backend_toFtq_redirect_bits_ftqIdx_value <= 6'($urandom);
      io_backend_toFtq_redirect_bits_ftqOffset <= 4'($urandom);
      io_backend_toFtq_redirect_bits_level <= 1'($urandom);
      io_backend_toFtq_redirect_bits_cfiUpdate_pc <= 50'({$urandom(), $urandom()});
      io_backend_toFtq_redirect_bits_cfiUpdate_target <= 50'({$urandom(), $urandom()});
      io_backend_toFtq_redirect_bits_cfiUpdate_taken <= 1'($urandom);
      io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred <= 1'($urandom);
      io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF <= 1'($urandom);
      io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF <= 1'($urandom);
      io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF <= 1'($urandom);
      io_backend_toFtq_redirect_bits_debugIsCtrl <= 1'($urandom);
      io_backend_toFtq_redirect_bits_debugIsMemVio <= 1'($urandom);
      io_backend_toFtq_ftqIdxAhead_0_valid <= 1'($urandom);
      io_backend_toFtq_ftqIdxAhead_0_bits_value <= 6'($urandom);
      io_backend_toFtq_ftqIdxSelOH_bits <= 3'($urandom);
      io_backend_canAccept <= ($urandom_range(0,3)!=0);
      io_backend_wfi_wfiReq <= ($urandom_range(0,31)==0);
      io_softPrefetch_0_valid <= ($urandom_range(0,7)==0);
      io_softPrefetch_0_bits_vaddr <= 50'({$urandom(), $urandom()});
      io_softPrefetch_1_valid <= ($urandom_range(0,7)==0);
      io_softPrefetch_1_bits_vaddr <= 50'({$urandom(), $urandom()});
      io_softPrefetch_2_valid <= ($urandom_range(0,7)==0);
      io_softPrefetch_2_bits_vaddr <= 50'({$urandom(), $urandom()});
      io_sfence_valid <= ($urandom_range(0,31)==0);
      io_sfence_bits_rs1 <= 1'($urandom);
      io_sfence_bits_rs2 <= 1'($urandom);
      io_sfence_bits_addr <= 50'({$urandom(), $urandom()});
      io_sfence_bits_id <= 16'($urandom);
      io_sfence_bits_flushPipe <= 1'($urandom);
      io_sfence_bits_hv <= 1'($urandom);
      io_sfence_bits_hg <= 1'($urandom);
      io_tlbCsr_satp_mode <= 4'($urandom);
      io_tlbCsr_satp_asid <= 16'($urandom);
      io_tlbCsr_satp_changed <= 1'($urandom);
      io_tlbCsr_vsatp_mode <= 4'($urandom);
      io_tlbCsr_vsatp_asid <= 16'($urandom);
      io_tlbCsr_vsatp_changed <= 1'($urandom);
      io_tlbCsr_hgatp_mode <= 4'($urandom);
      io_tlbCsr_hgatp_vmid <= 16'($urandom);
      io_tlbCsr_hgatp_changed <= 1'($urandom);
      io_tlbCsr_priv_mxr <= 1'($urandom);
      io_tlbCsr_priv_sum <= 1'($urandom);
      io_tlbCsr_priv_vmxr <= 1'($urandom);
      io_tlbCsr_priv_vsum <= 1'($urandom);
      io_tlbCsr_priv_virt <= 1'($urandom);
      io_tlbCsr_priv_spvp <= 1'($urandom);
      io_tlbCsr_priv_imode <= 2'($urandom);
      io_tlbCsr_priv_dmode <= 2'($urandom);
      io_tlbCsr_pmm_mseccfg <= 2'($urandom);
      io_tlbCsr_pmm_menvcfg <= 2'($urandom);
      io_tlbCsr_pmm_henvcfg <= 2'($urandom);
      io_tlbCsr_pmm_hstatus <= 2'($urandom);
      io_tlbCsr_pmm_senvcfg <= 2'($urandom);
      io_csrCtrl_pf_ctrl_l1I_pf_enable <= 1'($urandom);
      io_csrCtrl_bp_ctrl_ubtb_enable <= 1'($urandom);
      io_csrCtrl_bp_ctrl_btb_enable <= 1'($urandom);
      io_csrCtrl_bp_ctrl_tage_enable <= 1'($urandom);
      io_csrCtrl_bp_ctrl_sc_enable <= 1'($urandom);
      io_csrCtrl_bp_ctrl_ras_enable <= 1'($urandom);
      io_csrCtrl_ldld_vio_check_enable <= 1'($urandom);
      io_csrCtrl_cache_error_enable <= 1'($urandom);
      io_csrCtrl_hd_misalign_st_enable <= 1'($urandom);
      io_csrCtrl_hd_misalign_ld_enable <= 1'($urandom);
      io_csrCtrl_distribute_csr_w_valid <= 1'($urandom);
      io_csrCtrl_distribute_csr_w_bits_addr <= 12'($urandom);
      io_csrCtrl_distribute_csr_w_bits_data <= 64'({$urandom(), $urandom()});
      io_csrCtrl_frontend_trigger_tUpdate_valid <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_addr <= 2'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType <= 2'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action <= 4'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2 <= 64'({$urandom(), $urandom()});
      io_csrCtrl_frontend_trigger_tEnableVec_0 <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tEnableVec_1 <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tEnableVec_2 <= 1'($urandom);
      io_csrCtrl_frontend_trigger_tEnableVec_3 <= 1'($urandom);
      io_csrCtrl_frontend_trigger_debugMode <= 1'($urandom);
      io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_valid <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_addr <= 2'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType <= 2'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action <= 4'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load <= 1'($urandom);
      io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2 <= 64'({$urandom(), $urandom()});
      io_csrCtrl_mem_trigger_tEnableVec_0 <= 1'($urandom);
      io_csrCtrl_mem_trigger_tEnableVec_1 <= 1'($urandom);
      io_csrCtrl_mem_trigger_tEnableVec_2 <= 1'($urandom);
      io_csrCtrl_mem_trigger_tEnableVec_3 <= 1'($urandom);
      io_csrCtrl_mem_trigger_debugMode <= 1'($urandom);
      io_csrCtrl_mem_trigger_triggerCanRaiseBpExp <= 1'($urandom);
      io_csrCtrl_fsIsOff <= 1'($urandom);
      io_dft_ram_hold <= 1'($urandom);
      io_dft_ram_bypass <= 1'($urandom);
      io_dft_ram_bp_clken <= 1'($urandom);
      io_dft_ram_aux_clk <= 1'($urandom);
      io_dft_ram_aux_ckbp <= 1'($urandom);
      io_dft_ram_mcp_hold <= 1'($urandom);
      io_dft_cgen <= 1'($urandom);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_a_ready) && (g_auto_inner_icache_ctrlUnitOpt_in_a_ready !== i_auto_inner_icache_ctrlUnitOpt_in_a_ready)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_a_ready g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_a_ready, i_auto_inner_icache_ctrlUnitOpt_in_a_ready); end
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_d_valid) && (g_auto_inner_icache_ctrlUnitOpt_in_d_valid !== i_auto_inner_icache_ctrlUnitOpt_in_d_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_d_valid g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_d_valid, i_auto_inner_icache_ctrlUnitOpt_in_d_valid); end
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode) && (g_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode !== i_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode, i_auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode); end
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_size) && (g_auto_inner_icache_ctrlUnitOpt_in_d_bits_size !== i_auto_inner_icache_ctrlUnitOpt_in_d_bits_size)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_d_bits_size g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_d_bits_size, i_auto_inner_icache_ctrlUnitOpt_in_d_bits_size); end
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_source) && (g_auto_inner_icache_ctrlUnitOpt_in_d_bits_source !== i_auto_inner_icache_ctrlUnitOpt_in_d_bits_source)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_d_bits_source g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_d_bits_source, i_auto_inner_icache_ctrlUnitOpt_in_d_bits_source); end
    if (!$isunknown(g_auto_inner_icache_ctrlUnitOpt_in_d_bits_data) && (g_auto_inner_icache_ctrlUnitOpt_in_d_bits_data !== i_auto_inner_icache_ctrlUnitOpt_in_d_bits_data)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_ctrlUnitOpt_in_d_bits_data g=%h i=%h", $time, g_auto_inner_icache_ctrlUnitOpt_in_d_bits_data, i_auto_inner_icache_ctrlUnitOpt_in_d_bits_data); end
    if (!$isunknown(g_auto_inner_icache_client_out_a_valid) && (g_auto_inner_icache_client_out_a_valid !== i_auto_inner_icache_client_out_a_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_client_out_a_valid g=%h i=%h", $time, g_auto_inner_icache_client_out_a_valid, i_auto_inner_icache_client_out_a_valid); end
    if (!$isunknown(g_auto_inner_icache_client_out_a_bits_source) && (g_auto_inner_icache_client_out_a_bits_source !== i_auto_inner_icache_client_out_a_bits_source)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_client_out_a_bits_source g=%h i=%h", $time, g_auto_inner_icache_client_out_a_bits_source, i_auto_inner_icache_client_out_a_bits_source); end
    if (!$isunknown(g_auto_inner_icache_client_out_a_bits_address) && (g_auto_inner_icache_client_out_a_bits_address !== i_auto_inner_icache_client_out_a_bits_address)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_icache_client_out_a_bits_address g=%h i=%h", $time, g_auto_inner_icache_client_out_a_bits_address, i_auto_inner_icache_client_out_a_bits_address); end
    if (!$isunknown(g_auto_inner_instrUncache_client_out_a_valid) && (g_auto_inner_instrUncache_client_out_a_valid !== i_auto_inner_instrUncache_client_out_a_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_instrUncache_client_out_a_valid g=%h i=%h", $time, g_auto_inner_instrUncache_client_out_a_valid, i_auto_inner_instrUncache_client_out_a_valid); end
    if (!$isunknown(g_auto_inner_instrUncache_client_out_a_bits_address) && (g_auto_inner_instrUncache_client_out_a_bits_address !== i_auto_inner_instrUncache_client_out_a_bits_address)) begin errors++;
      if(errors<=4000) $display("[%0t] auto_inner_instrUncache_client_out_a_bits_address g=%h i=%h", $time, g_auto_inner_instrUncache_client_out_a_bits_address, i_auto_inner_instrUncache_client_out_a_bits_address); end
    if (!$isunknown(g_io_ptw_req_0_valid) && (g_io_ptw_req_0_valid !== i_io_ptw_req_0_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_ptw_req_0_valid g=%h i=%h", $time, g_io_ptw_req_0_valid, i_io_ptw_req_0_valid); end
    if (!$isunknown(g_io_ptw_req_0_bits_vpn) && (g_io_ptw_req_0_bits_vpn !== i_io_ptw_req_0_bits_vpn)) begin errors++;
      if(errors<=4000) $display("[%0t] io_ptw_req_0_bits_vpn g=%h i=%h", $time, g_io_ptw_req_0_bits_vpn, i_io_ptw_req_0_bits_vpn); end
    if (!$isunknown(g_io_ptw_req_0_bits_s2xlate) && (g_io_ptw_req_0_bits_s2xlate !== i_io_ptw_req_0_bits_s2xlate)) begin errors++;
      if(errors<=4000) $display("[%0t] io_ptw_req_0_bits_s2xlate g=%h i=%h", $time, g_io_ptw_req_0_bits_s2xlate, i_io_ptw_req_0_bits_s2xlate); end
    if (!$isunknown(g_io_ptw_resp_ready) && (g_io_ptw_resp_ready !== i_io_ptw_resp_ready)) begin errors++;
      if(errors<=4000) $display("[%0t] io_ptw_resp_ready g=%h i=%h", $time, g_io_ptw_resp_ready, i_io_ptw_resp_ready); end
    if (!$isunknown(g_io_backend_cfVec_0_valid) && (g_io_backend_cfVec_0_valid !== i_io_backend_cfVec_0_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_valid g=%h i=%h", $time, g_io_backend_cfVec_0_valid, i_io_backend_cfVec_0_valid); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_instr) && (g_io_backend_cfVec_0_bits_instr !== i_io_backend_cfVec_0_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_0_bits_instr, i_io_backend_cfVec_0_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_foldpc) && (g_io_backend_cfVec_0_bits_foldpc !== i_io_backend_cfVec_0_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_0_bits_foldpc, i_io_backend_cfVec_0_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_exceptionVec_1) && (g_io_backend_cfVec_0_bits_exceptionVec_1 !== i_io_backend_cfVec_0_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_0_bits_exceptionVec_1, i_io_backend_cfVec_0_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_exceptionVec_2) && (g_io_backend_cfVec_0_bits_exceptionVec_2 !== i_io_backend_cfVec_0_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_0_bits_exceptionVec_2, i_io_backend_cfVec_0_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_exceptionVec_12) && (g_io_backend_cfVec_0_bits_exceptionVec_12 !== i_io_backend_cfVec_0_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_0_bits_exceptionVec_12, i_io_backend_cfVec_0_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_exceptionVec_20) && (g_io_backend_cfVec_0_bits_exceptionVec_20 !== i_io_backend_cfVec_0_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_0_bits_exceptionVec_20, i_io_backend_cfVec_0_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_backendException) && (g_io_backend_cfVec_0_bits_backendException !== i_io_backend_cfVec_0_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_0_bits_backendException, i_io_backend_cfVec_0_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_trigger) && (g_io_backend_cfVec_0_bits_trigger !== i_io_backend_cfVec_0_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_0_bits_trigger, i_io_backend_cfVec_0_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_pd_isRVC) && (g_io_backend_cfVec_0_bits_pd_isRVC !== i_io_backend_cfVec_0_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_0_bits_pd_isRVC, i_io_backend_cfVec_0_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_pd_brType) && (g_io_backend_cfVec_0_bits_pd_brType !== i_io_backend_cfVec_0_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_0_bits_pd_brType, i_io_backend_cfVec_0_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_pred_taken) && (g_io_backend_cfVec_0_bits_pred_taken !== i_io_backend_cfVec_0_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_0_bits_pred_taken, i_io_backend_cfVec_0_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_crossPageIPFFix) && (g_io_backend_cfVec_0_bits_crossPageIPFFix !== i_io_backend_cfVec_0_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_0_bits_crossPageIPFFix, i_io_backend_cfVec_0_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_ftqPtr_flag) && (g_io_backend_cfVec_0_bits_ftqPtr_flag !== i_io_backend_cfVec_0_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_0_bits_ftqPtr_flag, i_io_backend_cfVec_0_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_ftqPtr_value) && (g_io_backend_cfVec_0_bits_ftqPtr_value !== i_io_backend_cfVec_0_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_0_bits_ftqPtr_value, i_io_backend_cfVec_0_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_ftqOffset) && (g_io_backend_cfVec_0_bits_ftqOffset !== i_io_backend_cfVec_0_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_0_bits_ftqOffset, i_io_backend_cfVec_0_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_0_bits_isLastInFtqEntry) && (g_io_backend_cfVec_0_bits_isLastInFtqEntry !== i_io_backend_cfVec_0_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_0_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_0_bits_isLastInFtqEntry, i_io_backend_cfVec_0_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_cfVec_1_valid) && (g_io_backend_cfVec_1_valid !== i_io_backend_cfVec_1_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_valid g=%h i=%h", $time, g_io_backend_cfVec_1_valid, i_io_backend_cfVec_1_valid); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_instr) && (g_io_backend_cfVec_1_bits_instr !== i_io_backend_cfVec_1_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_1_bits_instr, i_io_backend_cfVec_1_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_foldpc) && (g_io_backend_cfVec_1_bits_foldpc !== i_io_backend_cfVec_1_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_1_bits_foldpc, i_io_backend_cfVec_1_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_exceptionVec_1) && (g_io_backend_cfVec_1_bits_exceptionVec_1 !== i_io_backend_cfVec_1_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_1_bits_exceptionVec_1, i_io_backend_cfVec_1_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_exceptionVec_2) && (g_io_backend_cfVec_1_bits_exceptionVec_2 !== i_io_backend_cfVec_1_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_1_bits_exceptionVec_2, i_io_backend_cfVec_1_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_exceptionVec_12) && (g_io_backend_cfVec_1_bits_exceptionVec_12 !== i_io_backend_cfVec_1_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_1_bits_exceptionVec_12, i_io_backend_cfVec_1_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_exceptionVec_20) && (g_io_backend_cfVec_1_bits_exceptionVec_20 !== i_io_backend_cfVec_1_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_1_bits_exceptionVec_20, i_io_backend_cfVec_1_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_backendException) && (g_io_backend_cfVec_1_bits_backendException !== i_io_backend_cfVec_1_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_1_bits_backendException, i_io_backend_cfVec_1_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_trigger) && (g_io_backend_cfVec_1_bits_trigger !== i_io_backend_cfVec_1_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_1_bits_trigger, i_io_backend_cfVec_1_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_pd_isRVC) && (g_io_backend_cfVec_1_bits_pd_isRVC !== i_io_backend_cfVec_1_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_1_bits_pd_isRVC, i_io_backend_cfVec_1_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_pd_brType) && (g_io_backend_cfVec_1_bits_pd_brType !== i_io_backend_cfVec_1_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_1_bits_pd_brType, i_io_backend_cfVec_1_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_pred_taken) && (g_io_backend_cfVec_1_bits_pred_taken !== i_io_backend_cfVec_1_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_1_bits_pred_taken, i_io_backend_cfVec_1_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_crossPageIPFFix) && (g_io_backend_cfVec_1_bits_crossPageIPFFix !== i_io_backend_cfVec_1_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_1_bits_crossPageIPFFix, i_io_backend_cfVec_1_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_ftqPtr_flag) && (g_io_backend_cfVec_1_bits_ftqPtr_flag !== i_io_backend_cfVec_1_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_1_bits_ftqPtr_flag, i_io_backend_cfVec_1_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_ftqPtr_value) && (g_io_backend_cfVec_1_bits_ftqPtr_value !== i_io_backend_cfVec_1_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_1_bits_ftqPtr_value, i_io_backend_cfVec_1_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_ftqOffset) && (g_io_backend_cfVec_1_bits_ftqOffset !== i_io_backend_cfVec_1_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_1_bits_ftqOffset, i_io_backend_cfVec_1_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_1_bits_isLastInFtqEntry) && (g_io_backend_cfVec_1_bits_isLastInFtqEntry !== i_io_backend_cfVec_1_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_1_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_1_bits_isLastInFtqEntry, i_io_backend_cfVec_1_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_cfVec_2_valid) && (g_io_backend_cfVec_2_valid !== i_io_backend_cfVec_2_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_valid g=%h i=%h", $time, g_io_backend_cfVec_2_valid, i_io_backend_cfVec_2_valid); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_instr) && (g_io_backend_cfVec_2_bits_instr !== i_io_backend_cfVec_2_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_2_bits_instr, i_io_backend_cfVec_2_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_foldpc) && (g_io_backend_cfVec_2_bits_foldpc !== i_io_backend_cfVec_2_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_2_bits_foldpc, i_io_backend_cfVec_2_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_exceptionVec_1) && (g_io_backend_cfVec_2_bits_exceptionVec_1 !== i_io_backend_cfVec_2_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_2_bits_exceptionVec_1, i_io_backend_cfVec_2_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_exceptionVec_2) && (g_io_backend_cfVec_2_bits_exceptionVec_2 !== i_io_backend_cfVec_2_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_2_bits_exceptionVec_2, i_io_backend_cfVec_2_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_exceptionVec_12) && (g_io_backend_cfVec_2_bits_exceptionVec_12 !== i_io_backend_cfVec_2_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_2_bits_exceptionVec_12, i_io_backend_cfVec_2_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_exceptionVec_20) && (g_io_backend_cfVec_2_bits_exceptionVec_20 !== i_io_backend_cfVec_2_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_2_bits_exceptionVec_20, i_io_backend_cfVec_2_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_backendException) && (g_io_backend_cfVec_2_bits_backendException !== i_io_backend_cfVec_2_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_2_bits_backendException, i_io_backend_cfVec_2_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_trigger) && (g_io_backend_cfVec_2_bits_trigger !== i_io_backend_cfVec_2_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_2_bits_trigger, i_io_backend_cfVec_2_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_pd_isRVC) && (g_io_backend_cfVec_2_bits_pd_isRVC !== i_io_backend_cfVec_2_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_2_bits_pd_isRVC, i_io_backend_cfVec_2_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_pd_brType) && (g_io_backend_cfVec_2_bits_pd_brType !== i_io_backend_cfVec_2_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_2_bits_pd_brType, i_io_backend_cfVec_2_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_pred_taken) && (g_io_backend_cfVec_2_bits_pred_taken !== i_io_backend_cfVec_2_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_2_bits_pred_taken, i_io_backend_cfVec_2_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_crossPageIPFFix) && (g_io_backend_cfVec_2_bits_crossPageIPFFix !== i_io_backend_cfVec_2_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_2_bits_crossPageIPFFix, i_io_backend_cfVec_2_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_ftqPtr_flag) && (g_io_backend_cfVec_2_bits_ftqPtr_flag !== i_io_backend_cfVec_2_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_2_bits_ftqPtr_flag, i_io_backend_cfVec_2_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_ftqPtr_value) && (g_io_backend_cfVec_2_bits_ftqPtr_value !== i_io_backend_cfVec_2_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_2_bits_ftqPtr_value, i_io_backend_cfVec_2_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_ftqOffset) && (g_io_backend_cfVec_2_bits_ftqOffset !== i_io_backend_cfVec_2_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_2_bits_ftqOffset, i_io_backend_cfVec_2_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_2_bits_isLastInFtqEntry) && (g_io_backend_cfVec_2_bits_isLastInFtqEntry !== i_io_backend_cfVec_2_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_2_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_2_bits_isLastInFtqEntry, i_io_backend_cfVec_2_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_cfVec_3_valid) && (g_io_backend_cfVec_3_valid !== i_io_backend_cfVec_3_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_valid g=%h i=%h", $time, g_io_backend_cfVec_3_valid, i_io_backend_cfVec_3_valid); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_instr) && (g_io_backend_cfVec_3_bits_instr !== i_io_backend_cfVec_3_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_3_bits_instr, i_io_backend_cfVec_3_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_foldpc) && (g_io_backend_cfVec_3_bits_foldpc !== i_io_backend_cfVec_3_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_3_bits_foldpc, i_io_backend_cfVec_3_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_exceptionVec_1) && (g_io_backend_cfVec_3_bits_exceptionVec_1 !== i_io_backend_cfVec_3_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_3_bits_exceptionVec_1, i_io_backend_cfVec_3_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_exceptionVec_2) && (g_io_backend_cfVec_3_bits_exceptionVec_2 !== i_io_backend_cfVec_3_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_3_bits_exceptionVec_2, i_io_backend_cfVec_3_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_exceptionVec_12) && (g_io_backend_cfVec_3_bits_exceptionVec_12 !== i_io_backend_cfVec_3_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_3_bits_exceptionVec_12, i_io_backend_cfVec_3_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_exceptionVec_20) && (g_io_backend_cfVec_3_bits_exceptionVec_20 !== i_io_backend_cfVec_3_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_3_bits_exceptionVec_20, i_io_backend_cfVec_3_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_backendException) && (g_io_backend_cfVec_3_bits_backendException !== i_io_backend_cfVec_3_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_3_bits_backendException, i_io_backend_cfVec_3_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_trigger) && (g_io_backend_cfVec_3_bits_trigger !== i_io_backend_cfVec_3_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_3_bits_trigger, i_io_backend_cfVec_3_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_pd_isRVC) && (g_io_backend_cfVec_3_bits_pd_isRVC !== i_io_backend_cfVec_3_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_3_bits_pd_isRVC, i_io_backend_cfVec_3_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_pd_brType) && (g_io_backend_cfVec_3_bits_pd_brType !== i_io_backend_cfVec_3_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_3_bits_pd_brType, i_io_backend_cfVec_3_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_pred_taken) && (g_io_backend_cfVec_3_bits_pred_taken !== i_io_backend_cfVec_3_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_3_bits_pred_taken, i_io_backend_cfVec_3_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_crossPageIPFFix) && (g_io_backend_cfVec_3_bits_crossPageIPFFix !== i_io_backend_cfVec_3_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_3_bits_crossPageIPFFix, i_io_backend_cfVec_3_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_ftqPtr_flag) && (g_io_backend_cfVec_3_bits_ftqPtr_flag !== i_io_backend_cfVec_3_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_3_bits_ftqPtr_flag, i_io_backend_cfVec_3_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_ftqPtr_value) && (g_io_backend_cfVec_3_bits_ftqPtr_value !== i_io_backend_cfVec_3_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_3_bits_ftqPtr_value, i_io_backend_cfVec_3_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_ftqOffset) && (g_io_backend_cfVec_3_bits_ftqOffset !== i_io_backend_cfVec_3_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_3_bits_ftqOffset, i_io_backend_cfVec_3_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_3_bits_isLastInFtqEntry) && (g_io_backend_cfVec_3_bits_isLastInFtqEntry !== i_io_backend_cfVec_3_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_3_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_3_bits_isLastInFtqEntry, i_io_backend_cfVec_3_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_cfVec_4_valid) && (g_io_backend_cfVec_4_valid !== i_io_backend_cfVec_4_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_valid g=%h i=%h", $time, g_io_backend_cfVec_4_valid, i_io_backend_cfVec_4_valid); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_instr) && (g_io_backend_cfVec_4_bits_instr !== i_io_backend_cfVec_4_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_4_bits_instr, i_io_backend_cfVec_4_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_foldpc) && (g_io_backend_cfVec_4_bits_foldpc !== i_io_backend_cfVec_4_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_4_bits_foldpc, i_io_backend_cfVec_4_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_exceptionVec_1) && (g_io_backend_cfVec_4_bits_exceptionVec_1 !== i_io_backend_cfVec_4_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_4_bits_exceptionVec_1, i_io_backend_cfVec_4_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_exceptionVec_2) && (g_io_backend_cfVec_4_bits_exceptionVec_2 !== i_io_backend_cfVec_4_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_4_bits_exceptionVec_2, i_io_backend_cfVec_4_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_exceptionVec_12) && (g_io_backend_cfVec_4_bits_exceptionVec_12 !== i_io_backend_cfVec_4_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_4_bits_exceptionVec_12, i_io_backend_cfVec_4_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_exceptionVec_20) && (g_io_backend_cfVec_4_bits_exceptionVec_20 !== i_io_backend_cfVec_4_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_4_bits_exceptionVec_20, i_io_backend_cfVec_4_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_backendException) && (g_io_backend_cfVec_4_bits_backendException !== i_io_backend_cfVec_4_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_4_bits_backendException, i_io_backend_cfVec_4_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_trigger) && (g_io_backend_cfVec_4_bits_trigger !== i_io_backend_cfVec_4_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_4_bits_trigger, i_io_backend_cfVec_4_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_pd_isRVC) && (g_io_backend_cfVec_4_bits_pd_isRVC !== i_io_backend_cfVec_4_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_4_bits_pd_isRVC, i_io_backend_cfVec_4_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_pd_brType) && (g_io_backend_cfVec_4_bits_pd_brType !== i_io_backend_cfVec_4_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_4_bits_pd_brType, i_io_backend_cfVec_4_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_pred_taken) && (g_io_backend_cfVec_4_bits_pred_taken !== i_io_backend_cfVec_4_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_4_bits_pred_taken, i_io_backend_cfVec_4_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_crossPageIPFFix) && (g_io_backend_cfVec_4_bits_crossPageIPFFix !== i_io_backend_cfVec_4_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_4_bits_crossPageIPFFix, i_io_backend_cfVec_4_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_ftqPtr_flag) && (g_io_backend_cfVec_4_bits_ftqPtr_flag !== i_io_backend_cfVec_4_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_4_bits_ftqPtr_flag, i_io_backend_cfVec_4_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_ftqPtr_value) && (g_io_backend_cfVec_4_bits_ftqPtr_value !== i_io_backend_cfVec_4_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_4_bits_ftqPtr_value, i_io_backend_cfVec_4_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_ftqOffset) && (g_io_backend_cfVec_4_bits_ftqOffset !== i_io_backend_cfVec_4_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_4_bits_ftqOffset, i_io_backend_cfVec_4_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_4_bits_isLastInFtqEntry) && (g_io_backend_cfVec_4_bits_isLastInFtqEntry !== i_io_backend_cfVec_4_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_4_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_4_bits_isLastInFtqEntry, i_io_backend_cfVec_4_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_cfVec_5_valid) && (g_io_backend_cfVec_5_valid !== i_io_backend_cfVec_5_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_valid g=%h i=%h", $time, g_io_backend_cfVec_5_valid, i_io_backend_cfVec_5_valid); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_instr) && (g_io_backend_cfVec_5_bits_instr !== i_io_backend_cfVec_5_bits_instr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_instr g=%h i=%h", $time, g_io_backend_cfVec_5_bits_instr, i_io_backend_cfVec_5_bits_instr); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_foldpc) && (g_io_backend_cfVec_5_bits_foldpc !== i_io_backend_cfVec_5_bits_foldpc)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_foldpc g=%h i=%h", $time, g_io_backend_cfVec_5_bits_foldpc, i_io_backend_cfVec_5_bits_foldpc); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_exceptionVec_1) && (g_io_backend_cfVec_5_bits_exceptionVec_1 !== i_io_backend_cfVec_5_bits_exceptionVec_1)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_exceptionVec_1 g=%h i=%h", $time, g_io_backend_cfVec_5_bits_exceptionVec_1, i_io_backend_cfVec_5_bits_exceptionVec_1); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_exceptionVec_2) && (g_io_backend_cfVec_5_bits_exceptionVec_2 !== i_io_backend_cfVec_5_bits_exceptionVec_2)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_exceptionVec_2 g=%h i=%h", $time, g_io_backend_cfVec_5_bits_exceptionVec_2, i_io_backend_cfVec_5_bits_exceptionVec_2); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_exceptionVec_12) && (g_io_backend_cfVec_5_bits_exceptionVec_12 !== i_io_backend_cfVec_5_bits_exceptionVec_12)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_exceptionVec_12 g=%h i=%h", $time, g_io_backend_cfVec_5_bits_exceptionVec_12, i_io_backend_cfVec_5_bits_exceptionVec_12); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_exceptionVec_20) && (g_io_backend_cfVec_5_bits_exceptionVec_20 !== i_io_backend_cfVec_5_bits_exceptionVec_20)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_exceptionVec_20 g=%h i=%h", $time, g_io_backend_cfVec_5_bits_exceptionVec_20, i_io_backend_cfVec_5_bits_exceptionVec_20); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_backendException) && (g_io_backend_cfVec_5_bits_backendException !== i_io_backend_cfVec_5_bits_backendException)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_backendException g=%h i=%h", $time, g_io_backend_cfVec_5_bits_backendException, i_io_backend_cfVec_5_bits_backendException); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_trigger) && (g_io_backend_cfVec_5_bits_trigger !== i_io_backend_cfVec_5_bits_trigger)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_trigger g=%h i=%h", $time, g_io_backend_cfVec_5_bits_trigger, i_io_backend_cfVec_5_bits_trigger); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_pd_isRVC) && (g_io_backend_cfVec_5_bits_pd_isRVC !== i_io_backend_cfVec_5_bits_pd_isRVC)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_pd_isRVC g=%h i=%h", $time, g_io_backend_cfVec_5_bits_pd_isRVC, i_io_backend_cfVec_5_bits_pd_isRVC); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_pd_brType) && (g_io_backend_cfVec_5_bits_pd_brType !== i_io_backend_cfVec_5_bits_pd_brType)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_pd_brType g=%h i=%h", $time, g_io_backend_cfVec_5_bits_pd_brType, i_io_backend_cfVec_5_bits_pd_brType); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_pred_taken) && (g_io_backend_cfVec_5_bits_pred_taken !== i_io_backend_cfVec_5_bits_pred_taken)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_pred_taken g=%h i=%h", $time, g_io_backend_cfVec_5_bits_pred_taken, i_io_backend_cfVec_5_bits_pred_taken); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_crossPageIPFFix) && (g_io_backend_cfVec_5_bits_crossPageIPFFix !== i_io_backend_cfVec_5_bits_crossPageIPFFix)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_crossPageIPFFix g=%h i=%h", $time, g_io_backend_cfVec_5_bits_crossPageIPFFix, i_io_backend_cfVec_5_bits_crossPageIPFFix); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_ftqPtr_flag) && (g_io_backend_cfVec_5_bits_ftqPtr_flag !== i_io_backend_cfVec_5_bits_ftqPtr_flag)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_ftqPtr_flag g=%h i=%h", $time, g_io_backend_cfVec_5_bits_ftqPtr_flag, i_io_backend_cfVec_5_bits_ftqPtr_flag); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_ftqPtr_value) && (g_io_backend_cfVec_5_bits_ftqPtr_value !== i_io_backend_cfVec_5_bits_ftqPtr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_ftqPtr_value g=%h i=%h", $time, g_io_backend_cfVec_5_bits_ftqPtr_value, i_io_backend_cfVec_5_bits_ftqPtr_value); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_ftqOffset) && (g_io_backend_cfVec_5_bits_ftqOffset !== i_io_backend_cfVec_5_bits_ftqOffset)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_ftqOffset g=%h i=%h", $time, g_io_backend_cfVec_5_bits_ftqOffset, i_io_backend_cfVec_5_bits_ftqOffset); end
    if (!$isunknown(g_io_backend_cfVec_5_bits_isLastInFtqEntry) && (g_io_backend_cfVec_5_bits_isLastInFtqEntry !== i_io_backend_cfVec_5_bits_isLastInFtqEntry)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_cfVec_5_bits_isLastInFtqEntry g=%h i=%h", $time, g_io_backend_cfVec_5_bits_isLastInFtqEntry, i_io_backend_cfVec_5_bits_isLastInFtqEntry); end
    if (!$isunknown(g_io_backend_stallReason_reason_0) && (g_io_backend_stallReason_reason_0 !== i_io_backend_stallReason_reason_0)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_0 g=%h i=%h", $time, g_io_backend_stallReason_reason_0, i_io_backend_stallReason_reason_0); end
    if (!$isunknown(g_io_backend_stallReason_reason_1) && (g_io_backend_stallReason_reason_1 !== i_io_backend_stallReason_reason_1)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_1 g=%h i=%h", $time, g_io_backend_stallReason_reason_1, i_io_backend_stallReason_reason_1); end
    if (!$isunknown(g_io_backend_stallReason_reason_2) && (g_io_backend_stallReason_reason_2 !== i_io_backend_stallReason_reason_2)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_2 g=%h i=%h", $time, g_io_backend_stallReason_reason_2, i_io_backend_stallReason_reason_2); end
    if (!$isunknown(g_io_backend_stallReason_reason_3) && (g_io_backend_stallReason_reason_3 !== i_io_backend_stallReason_reason_3)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_3 g=%h i=%h", $time, g_io_backend_stallReason_reason_3, i_io_backend_stallReason_reason_3); end
    if (!$isunknown(g_io_backend_stallReason_reason_4) && (g_io_backend_stallReason_reason_4 !== i_io_backend_stallReason_reason_4)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_4 g=%h i=%h", $time, g_io_backend_stallReason_reason_4, i_io_backend_stallReason_reason_4); end
    if (!$isunknown(g_io_backend_stallReason_reason_5) && (g_io_backend_stallReason_reason_5 !== i_io_backend_stallReason_reason_5)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_backend_stallReason_reason_5 g=%h i=%h", $time, g_io_backend_stallReason_reason_5, i_io_backend_stallReason_reason_5); end
    if (!$isunknown(g_io_backend_fromFtq_pc_mem_wen) && (g_io_backend_fromFtq_pc_mem_wen !== i_io_backend_fromFtq_pc_mem_wen)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_pc_mem_wen g=%h i=%h", $time, g_io_backend_fromFtq_pc_mem_wen, i_io_backend_fromFtq_pc_mem_wen); end
    if (!$isunknown(g_io_backend_fromFtq_pc_mem_waddr) && (g_io_backend_fromFtq_pc_mem_waddr !== i_io_backend_fromFtq_pc_mem_waddr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_pc_mem_waddr g=%h i=%h", $time, g_io_backend_fromFtq_pc_mem_waddr, i_io_backend_fromFtq_pc_mem_waddr); end
    if (!$isunknown(g_io_backend_fromFtq_pc_mem_wdata_startAddr) && (g_io_backend_fromFtq_pc_mem_wdata_startAddr !== i_io_backend_fromFtq_pc_mem_wdata_startAddr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_pc_mem_wdata_startAddr g=%h i=%h", $time, g_io_backend_fromFtq_pc_mem_wdata_startAddr, i_io_backend_fromFtq_pc_mem_wdata_startAddr); end
    if (!$isunknown(g_io_backend_fromFtq_newest_entry_en) && (g_io_backend_fromFtq_newest_entry_en !== i_io_backend_fromFtq_newest_entry_en)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_newest_entry_en g=%h i=%h", $time, g_io_backend_fromFtq_newest_entry_en, i_io_backend_fromFtq_newest_entry_en); end
    if (!$isunknown(g_io_backend_fromFtq_newest_entry_target) && (g_io_backend_fromFtq_newest_entry_target !== i_io_backend_fromFtq_newest_entry_target)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_newest_entry_target g=%h i=%h", $time, g_io_backend_fromFtq_newest_entry_target, i_io_backend_fromFtq_newest_entry_target); end
    if (!$isunknown(g_io_backend_fromFtq_newest_entry_ptr_value) && (g_io_backend_fromFtq_newest_entry_ptr_value !== i_io_backend_fromFtq_newest_entry_ptr_value)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromFtq_newest_entry_ptr_value g=%h i=%h", $time, g_io_backend_fromFtq_newest_entry_ptr_value, i_io_backend_fromFtq_newest_entry_ptr_value); end
    if (!$isunknown(g_io_backend_fromIfu_gpaddrMem_wen) && (g_io_backend_fromIfu_gpaddrMem_wen !== i_io_backend_fromIfu_gpaddrMem_wen)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromIfu_gpaddrMem_wen g=%h i=%h", $time, g_io_backend_fromIfu_gpaddrMem_wen, i_io_backend_fromIfu_gpaddrMem_wen); end
    if (!$isunknown(g_io_backend_fromIfu_gpaddrMem_waddr) && (g_io_backend_fromIfu_gpaddrMem_waddr !== i_io_backend_fromIfu_gpaddrMem_waddr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromIfu_gpaddrMem_waddr g=%h i=%h", $time, g_io_backend_fromIfu_gpaddrMem_waddr, i_io_backend_fromIfu_gpaddrMem_waddr); end
    if (!$isunknown(g_io_backend_fromIfu_gpaddrMem_wdata_gpaddr) && (g_io_backend_fromIfu_gpaddrMem_wdata_gpaddr !== i_io_backend_fromIfu_gpaddrMem_wdata_gpaddr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromIfu_gpaddrMem_wdata_gpaddr g=%h i=%h", $time, g_io_backend_fromIfu_gpaddrMem_wdata_gpaddr, i_io_backend_fromIfu_gpaddrMem_wdata_gpaddr); end
    if (!$isunknown(g_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE) && (g_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE !== i_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE g=%h i=%h", $time, g_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE, i_io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE); end
    if (!$isunknown(g_io_backend_wfi_wfiSafe) && (g_io_backend_wfi_wfiSafe !== i_io_backend_wfi_wfiSafe)) begin errors++;
      if(errors<=4000) $display("[%0t] io_backend_wfi_wfiSafe g=%h i=%h", $time, g_io_backend_wfi_wfiSafe, i_io_backend_wfi_wfiSafe); end
    if (!$isunknown(g_io_error_valid) && (g_io_error_valid !== i_io_error_valid)) begin errors++;
      if(errors<=4000) $display("[%0t] io_error_valid g=%h i=%h", $time, g_io_error_valid, i_io_error_valid); end
    if (!$isunknown(g_io_error_bits_paddr) && (g_io_error_bits_paddr !== i_io_error_bits_paddr)) begin errors++;
      if(errors<=4000) $display("[%0t] io_error_bits_paddr g=%h i=%h", $time, g_io_error_bits_paddr, i_io_error_bits_paddr); end
    if (!$isunknown(g_io_error_bits_report_to_beu) && (g_io_error_bits_report_to_beu !== i_io_error_bits_report_to_beu)) begin errors++;
      if(errors<=4000) $display("[%0t] io_error_bits_report_to_beu g=%h i=%h", $time, g_io_error_bits_report_to_beu, i_io_error_bits_report_to_beu); end
    if (!$isunknown(g_io_resetInFrontend) && (g_io_resetInFrontend !== i_io_resetInFrontend)) begin errors++;
      if(errors<=4000) $display("[%0t] io_resetInFrontend g=%h i=%h", $time, g_io_resetInFrontend, i_io_resetInFrontend); end
    if (!$isunknown(g_io_perf_0_value) && (g_io_perf_0_value !== i_io_perf_0_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && (g_io_perf_1_value !== i_io_perf_1_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && (g_io_perf_2_value !== i_io_perf_2_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && (g_io_perf_3_value !== i_io_perf_3_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && (g_io_perf_4_value !== i_io_perf_4_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
    if (!$isunknown(g_io_perf_5_value) && (g_io_perf_5_value !== i_io_perf_5_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end
    if (!$isunknown(g_io_perf_6_value) && (g_io_perf_6_value !== i_io_perf_6_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end
    if (!$isunknown(g_io_perf_7_value) && (g_io_perf_7_value !== i_io_perf_7_value)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC io_perf_7_value g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end
    if (!$isunknown(u_g.inner_needFlush) && (u_g.inner_needFlush !== xs_dbg_flush)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE flush g=%h core=%h", $time, u_g.inner_needFlush, xs_dbg_flush); end
    if (!$isunknown(u_g.inner_FlushControlRedirect) && (u_g.inner_FlushControlRedirect !== xs_dbg_flush_ctrl)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE flush_ctrl g=%h core=%h", $time, u_g.inner_FlushControlRedirect, xs_dbg_flush_ctrl); end
    if (!$isunknown(u_g.inner_FlushMemVioRedirect) && (u_g.inner_FlushMemVioRedirect !== xs_dbg_flush_memvio)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE flush_memvio g=%h core=%h", $time, u_g.inner_FlushMemVioRedirect, xs_dbg_flush_memvio); end
    if (!$isunknown(u_g.inner_sfence_valid) && (u_g.inner_sfence_valid !== xs_dbg_sfence_q_valid)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_valid g=%h core=%h", $time, u_g.inner_sfence_valid, xs_dbg_sfence_q_valid); end
    if (!$isunknown(u_g.inner_sfence_bits_rs1) && (u_g.inner_sfence_bits_rs1 !== xs_dbg_sfence_q_rs1)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_rs1 g=%h core=%h", $time, u_g.inner_sfence_bits_rs1, xs_dbg_sfence_q_rs1); end
    if (!$isunknown(u_g.inner_sfence_bits_rs2) && (u_g.inner_sfence_bits_rs2 !== xs_dbg_sfence_q_rs2)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_rs2 g=%h core=%h", $time, u_g.inner_sfence_bits_rs2, xs_dbg_sfence_q_rs2); end
    if (!$isunknown(u_g.inner_sfence_bits_addr) && (u_g.inner_sfence_bits_addr !== xs_dbg_sfence_q_addr)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_addr g=%h core=%h", $time, u_g.inner_sfence_bits_addr, xs_dbg_sfence_q_addr); end
    if (!$isunknown(u_g.inner_sfence_bits_id) && (u_g.inner_sfence_bits_id !== xs_dbg_sfence_q_id)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_id g=%h core=%h", $time, u_g.inner_sfence_bits_id, xs_dbg_sfence_q_id); end
    if (!$isunknown(u_g.inner_sfence_bits_flushPipe) && (u_g.inner_sfence_bits_flushPipe !== xs_dbg_sfence_q_flushPipe)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_flushPipe g=%h core=%h", $time, u_g.inner_sfence_bits_flushPipe, xs_dbg_sfence_q_flushPipe); end
    if (!$isunknown(u_g.inner_sfence_bits_hv) && (u_g.inner_sfence_bits_hv !== xs_dbg_sfence_q_hv)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_hv g=%h core=%h", $time, u_g.inner_sfence_bits_hv, xs_dbg_sfence_q_hv); end
    if (!$isunknown(u_g.inner_sfence_bits_hg) && (u_g.inner_sfence_bits_hg !== xs_dbg_sfence_q_hg)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE sfence_q_hg g=%h core=%h", $time, u_g.inner_sfence_bits_hg, xs_dbg_sfence_q_hg); end
    if (!$isunknown(u_g.inner_icache_io_fencei_REG) && (u_g.inner_icache_io_fencei_REG !== xs_dbg_icache_fencei_q)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE icache_fencei_q g=%h core=%h", $time, u_g.inner_icache_io_fencei_REG, xs_dbg_icache_fencei_q); end
    if (!$isunknown(u_g.inner_icache_io_csr_pf_enable_REG) && (u_g.inner_icache_io_csr_pf_enable_REG !== xs_dbg_icache_pf_enable_q)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE icache_pf_enable_q g=%h core=%h", $time, u_g.inner_icache_io_csr_pf_enable_REG, xs_dbg_icache_pf_enable_q); end
    if (!$isunknown(u_g.io_error_valid) && (u_g.io_error_valid !== xs_dbg_error_valid_q)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE error_valid_q g=%h core=%h", $time, u_g.io_error_valid, xs_dbg_error_valid_q); end
    if (!$isunknown(u_g.io_error_bits_paddr) && (u_g.io_error_bits_paddr !== xs_dbg_error_paddr_q)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE error_paddr_q g=%h core=%h", $time, u_g.io_error_bits_paddr, xs_dbg_error_paddr_q); end
    if (!$isunknown(u_g.io_error_bits_report_to_beu) && (u_g.io_error_bits_report_to_beu !== xs_dbg_error_to_beu_q)) begin core_errors++;
      if(core_errors<=4000) $display("[%0t] CORE error_to_beu_q g=%h core=%h", $time, u_g.io_error_bits_report_to_beu, xs_dbg_error_to_beu_q); end
    if (!$isunknown(u_g.io_perf_0_value) && (u_g.io_perf_0_value !== xs_dbg_perf_q_0)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_0 g=%h core=%h", $time, u_g.io_perf_0_value, xs_dbg_perf_q_0); end
    if (!$isunknown(u_g.io_perf_1_value) && (u_g.io_perf_1_value !== xs_dbg_perf_q_1)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_1 g=%h core=%h", $time, u_g.io_perf_1_value, xs_dbg_perf_q_1); end
    if (!$isunknown(u_g.io_perf_2_value) && (u_g.io_perf_2_value !== xs_dbg_perf_q_2)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_2 g=%h core=%h", $time, u_g.io_perf_2_value, xs_dbg_perf_q_2); end
    if (!$isunknown(u_g.io_perf_3_value) && (u_g.io_perf_3_value !== xs_dbg_perf_q_3)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_3 g=%h core=%h", $time, u_g.io_perf_3_value, xs_dbg_perf_q_3); end
    if (!$isunknown(u_g.io_perf_4_value) && (u_g.io_perf_4_value !== xs_dbg_perf_q_4)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_4 g=%h core=%h", $time, u_g.io_perf_4_value, xs_dbg_perf_q_4); end
    if (!$isunknown(u_g.io_perf_5_value) && (u_g.io_perf_5_value !== xs_dbg_perf_q_5)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_5 g=%h core=%h", $time, u_g.io_perf_5_value, xs_dbg_perf_q_5); end
    if (!$isunknown(u_g.io_perf_6_value) && (u_g.io_perf_6_value !== xs_dbg_perf_q_6)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_6 g=%h core=%h", $time, u_g.io_perf_6_value, xs_dbg_perf_q_6); end
    if (!$isunknown(u_g.io_perf_7_value) && (u_g.io_perf_7_value !== xs_dbg_perf_q_7)) begin nonfunc_errors++;
      if(nonfunc_errors<=200) $display("[%0t] NONFUNC CORE perf_q_7 g=%h core=%h", $time, u_g.io_perf_7_value, xs_dbg_perf_q_7); end
  end
  initial begin
    void'($value$plusargs("NCYCLES=%d", NCYCLES));
    rst = 1; repeat (30) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d core_errors=%0d nonfunc_errors=%0d", checks, errors, core_errors, nonfunc_errors);
    // PASS = 功能输出逐拍等于 golden（errors）且顶层 glue 观察核自洽（core_errors）。
    // nonfunc_errors（topdown stallReason / perf 性能计数器）单列打印、不计入 PASS——
    // 与 BPU IT 样板同口径：重写在叶子级对 perf/topdown 分析口有意简化。
    if (errors == 0 && core_errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
