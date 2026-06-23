// 自动生成：scripts/gen_newcsr.py —— 勿手改

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; logic rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
  logic platformIRP_MEIP;
  logic platformIRP_MTIP;
  logic platformIRP_MSIP;
  logic platformIRP_SEIP;
  logic platformIRP_debugIP;
  logic nonMaskableIRP_NMI_43;
  logic nonMaskableIRP_NMI_31;
  logic [5:0] io_fromTop_hartId;
  logic io_fromTop_clintTime_valid;
  logic [63:0] io_fromTop_clintTime_bits;
  logic io_fromTop_l2FlushDone;
  logic io_fromTop_criticalErrorState;
  logic io_in_valid;
  logic io_in_bits_wen;
  logic io_in_bits_ren;
  logic [1:0] io_in_bits_op;
  logic [11:0] io_in_bits_addr;
  logic [63:0] io_in_bits_src;
  logic [63:0] io_in_bits_wdata;
  logic io_in_bits_mnret;
  logic io_in_bits_mret;
  logic io_in_bits_sret;
  logic io_in_bits_dret;
  logic io_in_bits_redirectFlush;
  logic io_trapInst_valid;
  logic [31:0] io_trapInst_bits;
  logic [63:0] io_fromMem_excpVA;
  logic [63:0] io_fromMem_excpGPA;
  logic io_fromMem_excpIsForVSnonLeafPTE;
  logic io_fromRob_trap_valid;
  logic [49:0] io_fromRob_trap_bits_pc;
  logic [55:0] io_fromRob_trap_bits_pcGPA;
  logic [63:0] io_fromRob_trap_bits_trapVec;
  logic io_fromRob_trap_bits_isFetchBkpt;
  logic io_fromRob_trap_bits_singleStep;
  logic [3:0] io_fromRob_trap_bits_trigger;
  logic io_fromRob_trap_bits_crossPageIPFFix;
  logic io_fromRob_trap_bits_isInterrupt;
  logic io_fromRob_trap_bits_isHls;
  logic io_fromRob_trap_bits_isFetchMalAddr;
  logic io_fromRob_trap_bits_isForVSnonLeafPTE;
  logic [6:0] io_fromRob_commit_instNum_bits;
  logic io_fromRob_commit_fflags_valid;
  logic [4:0] io_fromRob_commit_fflags_bits;
  logic io_fromRob_commit_fsDirty;
  logic io_fromRob_commit_vxsat_valid;
  logic io_fromRob_commit_vxsat_bits;
  logic io_fromRob_commit_vsDirty;
  logic io_fromRob_commit_vtype_valid;
  logic io_fromRob_commit_vtype_bits_VILL;
  logic io_fromRob_commit_vtype_bits_VMA;
  logic io_fromRob_commit_vtype_bits_VTA;
  logic [2:0] io_fromRob_commit_vtype_bits_VSEW;
  logic [2:0] io_fromRob_commit_vtype_bits_VLMUL;
  logic [7:0] io_fromRob_commit_vl;
  logic io_fromRob_commit_vstart_valid;
  logic [6:0] io_fromRob_commit_vstart_bits;
  logic io_fromVecExcpMod_busy;
  logic [5:0] io_perf_perfEventsFrontend_0_value;
  logic [5:0] io_perf_perfEventsFrontend_1_value;
  logic [5:0] io_perf_perfEventsFrontend_2_value;
  logic [5:0] io_perf_perfEventsFrontend_3_value;
  logic [5:0] io_perf_perfEventsFrontend_4_value;
  logic [5:0] io_perf_perfEventsFrontend_5_value;
  logic [5:0] io_perf_perfEventsFrontend_6_value;
  logic [5:0] io_perf_perfEventsFrontend_7_value;
  logic [5:0] io_perf_perfEventsBackend_0_value;
  logic [5:0] io_perf_perfEventsBackend_1_value;
  logic [5:0] io_perf_perfEventsBackend_2_value;
  logic [5:0] io_perf_perfEventsBackend_3_value;
  logic [5:0] io_perf_perfEventsBackend_4_value;
  logic [5:0] io_perf_perfEventsBackend_5_value;
  logic [5:0] io_perf_perfEventsBackend_6_value;
  logic [5:0] io_perf_perfEventsBackend_7_value;
  logic [5:0] io_perf_perfEventsLsu_0_value;
  logic [5:0] io_perf_perfEventsLsu_1_value;
  logic [5:0] io_perf_perfEventsLsu_2_value;
  logic [5:0] io_perf_perfEventsLsu_3_value;
  logic [5:0] io_perf_perfEventsLsu_4_value;
  logic [5:0] io_perf_perfEventsLsu_5_value;
  logic [5:0] io_perf_perfEventsLsu_6_value;
  logic [5:0] io_perf_perfEventsLsu_7_value;
  logic [5:0] io_perf_perfEventsHc_0_value;
  logic [5:0] io_perf_perfEventsHc_1_value;
  logic [5:0] io_perf_perfEventsHc_2_value;
  logic [5:0] io_perf_perfEventsHc_3_value;
  logic [5:0] io_perf_perfEventsHc_4_value;
  logic [5:0] io_perf_perfEventsHc_5_value;
  logic [5:0] io_perf_perfEventsHc_6_value;
  logic [5:0] io_perf_perfEventsHc_7_value;
  logic [5:0] io_perf_perfEventsHc_8_value;
  logic [5:0] io_perf_perfEventsHc_9_value;
  logic [5:0] io_perf_perfEventsHc_10_value;
  logic [5:0] io_perf_perfEventsHc_11_value;
  logic [5:0] io_perf_perfEventsHc_12_value;
  logic [5:0] io_perf_perfEventsHc_13_value;
  logic [5:0] io_perf_perfEventsHc_14_value;
  logic [5:0] io_perf_perfEventsHc_15_value;
  logic [5:0] io_perf_perfEventsHc_16_value;
  logic [5:0] io_perf_perfEventsHc_17_value;
  logic [5:0] io_perf_perfEventsHc_18_value;
  logic [5:0] io_perf_perfEventsHc_19_value;
  logic [5:0] io_perf_perfEventsHc_20_value;
  logic [5:0] io_perf_perfEventsHc_21_value;
  logic [5:0] io_perf_perfEventsHc_22_value;
  logic [5:0] io_perf_perfEventsHc_23_value;
  logic [5:0] io_perf_perfEventsHc_24_value;
  logic [5:0] io_perf_perfEventsHc_25_value;
  logic [5:0] io_perf_perfEventsHc_26_value;
  logic [5:0] io_perf_perfEventsHc_27_value;
  logic [5:0] io_perf_perfEventsHc_28_value;
  logic [5:0] io_perf_perfEventsHc_29_value;
  logic [5:0] io_perf_perfEventsHc_30_value;
  logic [5:0] io_perf_perfEventsHc_31_value;
  logic [5:0] io_perf_perfEventsHc_32_value;
  logic [5:0] io_perf_perfEventsHc_33_value;
  logic [5:0] io_perf_perfEventsHc_34_value;
  logic [5:0] io_perf_perfEventsHc_35_value;
  logic [5:0] io_perf_perfEventsHc_36_value;
  logic [5:0] io_perf_perfEventsHc_37_value;
  logic [5:0] io_perf_perfEventsHc_38_value;
  logic [5:0] io_perf_perfEventsHc_39_value;
  logic [5:0] io_perf_perfEventsHc_40_value;
  logic [5:0] io_perf_perfEventsHc_41_value;
  logic [5:0] io_perf_perfEventsHc_42_value;
  logic [5:0] io_perf_perfEventsHc_43_value;
  logic [5:0] io_perf_perfEventsHc_44_value;
  logic [5:0] io_perf_perfEventsHc_45_value;
  logic [5:0] io_perf_perfEventsHc_46_value;
  logic [5:0] io_perf_perfEventsHc_47_value;
  logic io_out_ready;
  logic [63:0] io_fetchMalTval;
  logic fromAIA_rdata_valid;
  logic [63:0] fromAIA_rdata_bits_data;
  logic fromAIA_rdata_bits_illegal;
  logic fromAIA_meip;
  logic fromAIA_seip;
  logic [4:0] fromAIA_vseip;
  logic [10:0] fromAIA_mtopei_IID;
  logic [10:0] fromAIA_mtopei_IPRIO;
  logic [10:0] fromAIA_stopei_IID;
  logic [10:0] fromAIA_stopei_IPRIO;
  logic [10:0] fromAIA_vstopei_IID;
  logic [10:0] fromAIA_vstopei_IPRIO;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire g_io_out_bits_EX_II;
  wire i_io_out_bits_EX_II;
  wire g_io_out_bits_EX_VI;
  wire i_io_out_bits_EX_VI;
  wire g_io_out_bits_flushPipe;
  wire i_io_out_bits_flushPipe;
  wire [63:0] g_io_out_bits_rData;
  wire [63:0] i_io_out_bits_rData;
  wire g_io_out_bits_targetPcUpdate;
  wire i_io_out_bits_targetPcUpdate;
  wire [63:0] g_io_out_bits_targetPc_pc;
  wire [63:0] i_io_out_bits_targetPc_pc;
  wire g_io_out_bits_targetPc_raiseIPF;
  wire i_io_out_bits_targetPc_raiseIPF;
  wire g_io_out_bits_targetPc_raiseIAF;
  wire i_io_out_bits_targetPc_raiseIAF;
  wire g_io_out_bits_targetPc_raiseIGPF;
  wire i_io_out_bits_targetPc_raiseIGPF;
  wire [63:0] g_io_out_bits_regOut;
  wire [63:0] i_io_out_bits_regOut;
  wire g_io_out_bits_isPerfCnt;
  wire i_io_out_bits_isPerfCnt;
  wire [1:0] g_io_status_privState_PRVM;
  wire [1:0] i_io_status_privState_PRVM;
  wire g_io_status_privState_V;
  wire i_io_status_privState_V;
  wire g_io_status_interrupt;
  wire i_io_status_interrupt;
  wire g_io_status_wfiEvent;
  wire i_io_status_wfiEvent;
  wire [2:0] g_io_status_fpState_frm;
  wire [2:0] i_io_status_fpState_frm;
  wire [6:0] g_io_status_vecState_vstart;
  wire [6:0] i_io_status_vecState_vstart;
  wire [1:0] g_io_status_vecState_vxrm;
  wire [1:0] i_io_status_vecState_vxrm;
  wire g_io_status_singleStepFlag;
  wire i_io_status_singleStepFlag;
  wire g_io_status_frontendTrigger_tUpdate_valid;
  wire i_io_status_frontendTrigger_tUpdate_valid;
  wire [1:0] g_io_status_frontendTrigger_tUpdate_bits_addr;
  wire [1:0] i_io_status_frontendTrigger_tUpdate_bits_addr;
  wire [1:0] g_io_status_frontendTrigger_tUpdate_bits_tdata_matchType;
  wire [1:0] i_io_status_frontendTrigger_tUpdate_bits_tdata_matchType;
  wire g_io_status_frontendTrigger_tUpdate_bits_tdata_select;
  wire i_io_status_frontendTrigger_tUpdate_bits_tdata_select;
  wire [3:0] g_io_status_frontendTrigger_tUpdate_bits_tdata_action;
  wire [3:0] i_io_status_frontendTrigger_tUpdate_bits_tdata_action;
  wire g_io_status_frontendTrigger_tUpdate_bits_tdata_chain;
  wire i_io_status_frontendTrigger_tUpdate_bits_tdata_chain;
  wire [63:0] g_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2;
  wire [63:0] i_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2;
  wire g_io_status_frontendTrigger_tEnableVec_0;
  wire i_io_status_frontendTrigger_tEnableVec_0;
  wire g_io_status_frontendTrigger_tEnableVec_1;
  wire i_io_status_frontendTrigger_tEnableVec_1;
  wire g_io_status_frontendTrigger_tEnableVec_2;
  wire i_io_status_frontendTrigger_tEnableVec_2;
  wire g_io_status_frontendTrigger_tEnableVec_3;
  wire i_io_status_frontendTrigger_tEnableVec_3;
  wire g_io_status_frontendTrigger_debugMode;
  wire i_io_status_frontendTrigger_debugMode;
  wire g_io_status_frontendTrigger_triggerCanRaiseBpExp;
  wire i_io_status_frontendTrigger_triggerCanRaiseBpExp;
  wire g_io_status_memTrigger_tUpdate_valid;
  wire i_io_status_memTrigger_tUpdate_valid;
  wire [1:0] g_io_status_memTrigger_tUpdate_bits_addr;
  wire [1:0] i_io_status_memTrigger_tUpdate_bits_addr;
  wire [1:0] g_io_status_memTrigger_tUpdate_bits_tdata_matchType;
  wire [1:0] i_io_status_memTrigger_tUpdate_bits_tdata_matchType;
  wire g_io_status_memTrigger_tUpdate_bits_tdata_select;
  wire i_io_status_memTrigger_tUpdate_bits_tdata_select;
  wire [3:0] g_io_status_memTrigger_tUpdate_bits_tdata_action;
  wire [3:0] i_io_status_memTrigger_tUpdate_bits_tdata_action;
  wire g_io_status_memTrigger_tUpdate_bits_tdata_chain;
  wire i_io_status_memTrigger_tUpdate_bits_tdata_chain;
  wire g_io_status_memTrigger_tUpdate_bits_tdata_store;
  wire i_io_status_memTrigger_tUpdate_bits_tdata_store;
  wire g_io_status_memTrigger_tUpdate_bits_tdata_load;
  wire i_io_status_memTrigger_tUpdate_bits_tdata_load;
  wire [63:0] g_io_status_memTrigger_tUpdate_bits_tdata_tdata2;
  wire [63:0] i_io_status_memTrigger_tUpdate_bits_tdata_tdata2;
  wire g_io_status_memTrigger_tEnableVec_0;
  wire i_io_status_memTrigger_tEnableVec_0;
  wire g_io_status_memTrigger_tEnableVec_1;
  wire i_io_status_memTrigger_tEnableVec_1;
  wire g_io_status_memTrigger_tEnableVec_2;
  wire i_io_status_memTrigger_tEnableVec_2;
  wire g_io_status_memTrigger_tEnableVec_3;
  wire i_io_status_memTrigger_tEnableVec_3;
  wire g_io_status_memTrigger_debugMode;
  wire i_io_status_memTrigger_debugMode;
  wire g_io_status_memTrigger_triggerCanRaiseBpExp;
  wire i_io_status_memTrigger_triggerCanRaiseBpExp;
  wire g_io_status_instrAddrTransType_bare;
  wire i_io_status_instrAddrTransType_bare;
  wire g_io_status_instrAddrTransType_sv39;
  wire i_io_status_instrAddrTransType_sv39;
  wire g_io_status_instrAddrTransType_sv39x4;
  wire i_io_status_instrAddrTransType_sv39x4;
  wire g_io_status_instrAddrTransType_sv48;
  wire i_io_status_instrAddrTransType_sv48;
  wire g_io_status_instrAddrTransType_sv48x4;
  wire i_io_status_instrAddrTransType_sv48x4;
  wire [63:0] g_io_status_traceCSR_cause;
  wire [63:0] i_io_status_traceCSR_cause;
  wire [49:0] g_io_status_traceCSR_tval;
  wire [49:0] i_io_status_traceCSR_tval;
  wire [2:0] g_io_status_traceCSR_lastPriv;
  wire [2:0] i_io_status_traceCSR_lastPriv;
  wire [2:0] g_io_status_traceCSR_currentPriv;
  wire [2:0] i_io_status_traceCSR_currentPriv;
  wire g_io_status_custom_pf_ctrl_l1I_pf_enable;
  wire i_io_status_custom_pf_ctrl_l1I_pf_enable;
  wire g_io_status_custom_pf_ctrl_l2_pf_enable;
  wire i_io_status_custom_pf_ctrl_l2_pf_enable;
  wire g_io_status_custom_pf_ctrl_l1D_pf_enable;
  wire i_io_status_custom_pf_ctrl_l1D_pf_enable;
  wire g_io_status_custom_pf_ctrl_l1D_pf_train_on_hit;
  wire i_io_status_custom_pf_ctrl_l1D_pf_train_on_hit;
  wire g_io_status_custom_pf_ctrl_l1D_pf_enable_agt;
  wire i_io_status_custom_pf_ctrl_l1D_pf_enable_agt;
  wire g_io_status_custom_pf_ctrl_l1D_pf_enable_pht;
  wire i_io_status_custom_pf_ctrl_l1D_pf_enable_pht;
  wire [3:0] g_io_status_custom_pf_ctrl_l1D_pf_active_threshold;
  wire [3:0] i_io_status_custom_pf_ctrl_l1D_pf_active_threshold;
  wire [5:0] g_io_status_custom_pf_ctrl_l1D_pf_active_stride;
  wire [5:0] i_io_status_custom_pf_ctrl_l1D_pf_active_stride;
  wire g_io_status_custom_pf_ctrl_l1D_pf_enable_stride;
  wire i_io_status_custom_pf_ctrl_l1D_pf_enable_stride;
  wire g_io_status_custom_pf_ctrl_l2_pf_store_only;
  wire i_io_status_custom_pf_ctrl_l2_pf_store_only;
  wire g_io_status_custom_pf_ctrl_l2_pf_recv_enable;
  wire i_io_status_custom_pf_ctrl_l2_pf_recv_enable;
  wire g_io_status_custom_pf_ctrl_l2_pf_pbop_enable;
  wire i_io_status_custom_pf_ctrl_l2_pf_pbop_enable;
  wire g_io_status_custom_pf_ctrl_l2_pf_vbop_enable;
  wire i_io_status_custom_pf_ctrl_l2_pf_vbop_enable;
  wire [4:0] g_io_status_custom_lvpred_timeout;
  wire [4:0] i_io_status_custom_lvpred_timeout;
  wire g_io_status_custom_bp_ctrl_ubtb_enable;
  wire i_io_status_custom_bp_ctrl_ubtb_enable;
  wire g_io_status_custom_bp_ctrl_btb_enable;
  wire i_io_status_custom_bp_ctrl_btb_enable;
  wire g_io_status_custom_bp_ctrl_tage_enable;
  wire i_io_status_custom_bp_ctrl_tage_enable;
  wire g_io_status_custom_bp_ctrl_sc_enable;
  wire i_io_status_custom_bp_ctrl_sc_enable;
  wire g_io_status_custom_bp_ctrl_ras_enable;
  wire i_io_status_custom_bp_ctrl_ras_enable;
  wire g_io_status_custom_ldld_vio_check_enable;
  wire i_io_status_custom_ldld_vio_check_enable;
  wire g_io_status_custom_cache_error_enable;
  wire i_io_status_custom_cache_error_enable;
  wire g_io_status_custom_uncache_write_outstanding_enable;
  wire i_io_status_custom_uncache_write_outstanding_enable;
  wire g_io_status_custom_hd_misalign_st_enable;
  wire i_io_status_custom_hd_misalign_st_enable;
  wire g_io_status_custom_hd_misalign_ld_enable;
  wire i_io_status_custom_hd_misalign_ld_enable;
  wire g_io_status_custom_power_down_enable;
  wire i_io_status_custom_power_down_enable;
  wire g_io_status_custom_flush_l2_enable;
  wire i_io_status_custom_flush_l2_enable;
  wire g_io_status_custom_fusion_enable;
  wire i_io_status_custom_fusion_enable;
  wire g_io_status_custom_wfi_enable;
  wire i_io_status_custom_wfi_enable;
  wire g_io_status_criticalErrorState;
  wire i_io_status_criticalErrorState;
  wire g_io_tlb_satpASIDChanged;
  wire i_io_tlb_satpASIDChanged;
  wire g_io_tlb_vsatpASIDChanged;
  wire i_io_tlb_vsatpASIDChanged;
  wire g_io_tlb_hgatpVMIDChanged;
  wire i_io_tlb_hgatpVMIDChanged;
  wire [3:0] g_io_tlb_satp_MODE;
  wire [3:0] i_io_tlb_satp_MODE;
  wire [15:0] g_io_tlb_satp_ASID;
  wire [15:0] i_io_tlb_satp_ASID;
  wire [43:0] g_io_tlb_satp_PPN;
  wire [43:0] i_io_tlb_satp_PPN;
  wire [3:0] g_io_tlb_vsatp_MODE;
  wire [3:0] i_io_tlb_vsatp_MODE;
  wire [15:0] g_io_tlb_vsatp_ASID;
  wire [15:0] i_io_tlb_vsatp_ASID;
  wire [43:0] g_io_tlb_vsatp_PPN;
  wire [43:0] i_io_tlb_vsatp_PPN;
  wire [3:0] g_io_tlb_hgatp_MODE;
  wire [3:0] i_io_tlb_hgatp_MODE;
  wire [13:0] g_io_tlb_hgatp_VMID;
  wire [13:0] i_io_tlb_hgatp_VMID;
  wire [43:0] g_io_tlb_hgatp_PPN;
  wire [43:0] i_io_tlb_hgatp_PPN;
  wire g_io_tlb_mxr;
  wire i_io_tlb_mxr;
  wire g_io_tlb_sum;
  wire i_io_tlb_sum;
  wire g_io_tlb_vmxr;
  wire i_io_tlb_vmxr;
  wire g_io_tlb_vsum;
  wire i_io_tlb_vsum;
  wire g_io_tlb_spvp;
  wire i_io_tlb_spvp;
  wire [1:0] g_io_tlb_imode;
  wire [1:0] i_io_tlb_imode;
  wire [1:0] g_io_tlb_dmode;
  wire [1:0] i_io_tlb_dmode;
  wire g_io_tlb_dvirt;
  wire i_io_tlb_dvirt;
  wire g_io_tlb_mPBMTE;
  wire i_io_tlb_mPBMTE;
  wire g_io_tlb_hPBMTE;
  wire i_io_tlb_hPBMTE;
  wire [1:0] g_io_tlb_pmm_mseccfg;
  wire [1:0] i_io_tlb_pmm_mseccfg;
  wire [1:0] g_io_tlb_pmm_menvcfg;
  wire [1:0] i_io_tlb_pmm_menvcfg;
  wire [1:0] g_io_tlb_pmm_henvcfg;
  wire [1:0] i_io_tlb_pmm_henvcfg;
  wire [1:0] g_io_tlb_pmm_hstatus;
  wire [1:0] i_io_tlb_pmm_hstatus;
  wire [1:0] g_io_tlb_pmm_senvcfg;
  wire [1:0] i_io_tlb_pmm_senvcfg;
  wire g_io_toDecode_illegalInst_sfenceVMA;
  wire i_io_toDecode_illegalInst_sfenceVMA;
  wire g_io_toDecode_illegalInst_sfencePart;
  wire i_io_toDecode_illegalInst_sfencePart;
  wire g_io_toDecode_illegalInst_hfenceGVMA;
  wire i_io_toDecode_illegalInst_hfenceGVMA;
  wire g_io_toDecode_illegalInst_hfenceVVMA;
  wire i_io_toDecode_illegalInst_hfenceVVMA;
  wire g_io_toDecode_illegalInst_hlsv;
  wire i_io_toDecode_illegalInst_hlsv;
  wire g_io_toDecode_illegalInst_fsIsOff;
  wire i_io_toDecode_illegalInst_fsIsOff;
  wire g_io_toDecode_illegalInst_vsIsOff;
  wire i_io_toDecode_illegalInst_vsIsOff;
  wire g_io_toDecode_illegalInst_wfi;
  wire i_io_toDecode_illegalInst_wfi;
  wire g_io_toDecode_illegalInst_wrs_nto;
  wire i_io_toDecode_illegalInst_wrs_nto;
  wire g_io_toDecode_illegalInst_frm;
  wire i_io_toDecode_illegalInst_frm;
  wire g_io_toDecode_illegalInst_cboZ;
  wire i_io_toDecode_illegalInst_cboZ;
  wire g_io_toDecode_illegalInst_cboCF;
  wire i_io_toDecode_illegalInst_cboCF;
  wire g_io_toDecode_illegalInst_cboI;
  wire i_io_toDecode_illegalInst_cboI;
  wire g_io_toDecode_virtualInst_sfenceVMA;
  wire i_io_toDecode_virtualInst_sfenceVMA;
  wire g_io_toDecode_virtualInst_sfencePart;
  wire i_io_toDecode_virtualInst_sfencePart;
  wire g_io_toDecode_virtualInst_hfence;
  wire i_io_toDecode_virtualInst_hfence;
  wire g_io_toDecode_virtualInst_hlsv;
  wire i_io_toDecode_virtualInst_hlsv;
  wire g_io_toDecode_virtualInst_wfi;
  wire i_io_toDecode_virtualInst_wfi;
  wire g_io_toDecode_virtualInst_wrs_nto;
  wire i_io_toDecode_virtualInst_wrs_nto;
  wire g_io_toDecode_virtualInst_cboZ;
  wire i_io_toDecode_virtualInst_cboZ;
  wire g_io_toDecode_virtualInst_cboCF;
  wire i_io_toDecode_virtualInst_cboCF;
  wire g_io_toDecode_virtualInst_cboI;
  wire i_io_toDecode_virtualInst_cboI;
  wire g_io_toDecode_special_cboI2F;
  wire i_io_toDecode_special_cboI2F;
  wire g_io_distributedWenLegal;
  wire i_io_distributedWenLegal;
  wire g_toAIA_addr_valid;
  wire i_toAIA_addr_valid;
  wire [11:0] g_toAIA_addr_bits_addr;
  wire [11:0] i_toAIA_addr_bits_addr;
  wire g_toAIA_addr_bits_v;
  wire i_toAIA_addr_bits_v;
  wire [1:0] g_toAIA_addr_bits_prvm;
  wire [1:0] i_toAIA_addr_bits_prvm;
  wire [5:0] g_toAIA_vgein;
  wire [5:0] i_toAIA_vgein;
  wire g_toAIA_wdata_valid;
  wire i_toAIA_wdata_valid;
  wire [1:0] g_toAIA_wdata_bits_op;
  wire [1:0] i_toAIA_wdata_bits_op;
  wire [63:0] g_toAIA_wdata_bits_data;
  wire [63:0] i_toAIA_wdata_bits_data;
  wire g_toAIA_mClaim;
  wire i_toAIA_mClaim;
  wire g_toAIA_sClaim;
  wire i_toAIA_sClaim;
  wire g_toAIA_vsClaim;
  wire i_toAIA_vsClaim;
  wire g_io_error_0;
  wire i_io_error_0;
  NewCSR    u_g (.clock(clk), .reset(rst), .platformIRP_MEIP(platformIRP_MEIP), .platformIRP_MTIP(platformIRP_MTIP), .platformIRP_MSIP(platformIRP_MSIP), .platformIRP_SEIP(platformIRP_SEIP), .platformIRP_debugIP(platformIRP_debugIP), .nonMaskableIRP_NMI_43(nonMaskableIRP_NMI_43), .nonMaskableIRP_NMI_31(nonMaskableIRP_NMI_31), .io_fromTop_hartId(io_fromTop_hartId), .io_fromTop_clintTime_valid(io_fromTop_clintTime_valid), .io_fromTop_clintTime_bits(io_fromTop_clintTime_bits), .io_fromTop_l2FlushDone(io_fromTop_l2FlushDone), .io_fromTop_criticalErrorState(io_fromTop_criticalErrorState), .io_in_valid(io_in_valid), .io_in_bits_wen(io_in_bits_wen), .io_in_bits_ren(io_in_bits_ren), .io_in_bits_op(io_in_bits_op), .io_in_bits_addr(io_in_bits_addr), .io_in_bits_src(io_in_bits_src), .io_in_bits_wdata(io_in_bits_wdata), .io_in_bits_mnret(io_in_bits_mnret), .io_in_bits_mret(io_in_bits_mret), .io_in_bits_sret(io_in_bits_sret), .io_in_bits_dret(io_in_bits_dret), .io_in_bits_redirectFlush(io_in_bits_redirectFlush), .io_trapInst_valid(io_trapInst_valid), .io_trapInst_bits(io_trapInst_bits), .io_fromMem_excpVA(io_fromMem_excpVA), .io_fromMem_excpGPA(io_fromMem_excpGPA), .io_fromMem_excpIsForVSnonLeafPTE(io_fromMem_excpIsForVSnonLeafPTE), .io_fromRob_trap_valid(io_fromRob_trap_valid), .io_fromRob_trap_bits_pc(io_fromRob_trap_bits_pc), .io_fromRob_trap_bits_pcGPA(io_fromRob_trap_bits_pcGPA), .io_fromRob_trap_bits_trapVec(io_fromRob_trap_bits_trapVec), .io_fromRob_trap_bits_isFetchBkpt(io_fromRob_trap_bits_isFetchBkpt), .io_fromRob_trap_bits_singleStep(io_fromRob_trap_bits_singleStep), .io_fromRob_trap_bits_trigger(io_fromRob_trap_bits_trigger), .io_fromRob_trap_bits_crossPageIPFFix(io_fromRob_trap_bits_crossPageIPFFix), .io_fromRob_trap_bits_isInterrupt(io_fromRob_trap_bits_isInterrupt), .io_fromRob_trap_bits_isHls(io_fromRob_trap_bits_isHls), .io_fromRob_trap_bits_isFetchMalAddr(io_fromRob_trap_bits_isFetchMalAddr), .io_fromRob_trap_bits_isForVSnonLeafPTE(io_fromRob_trap_bits_isForVSnonLeafPTE), .io_fromRob_commit_instNum_bits(io_fromRob_commit_instNum_bits), .io_fromRob_commit_fflags_valid(io_fromRob_commit_fflags_valid), .io_fromRob_commit_fflags_bits(io_fromRob_commit_fflags_bits), .io_fromRob_commit_fsDirty(io_fromRob_commit_fsDirty), .io_fromRob_commit_vxsat_valid(io_fromRob_commit_vxsat_valid), .io_fromRob_commit_vxsat_bits(io_fromRob_commit_vxsat_bits), .io_fromRob_commit_vsDirty(io_fromRob_commit_vsDirty), .io_fromRob_commit_vtype_valid(io_fromRob_commit_vtype_valid), .io_fromRob_commit_vtype_bits_VILL(io_fromRob_commit_vtype_bits_VILL), .io_fromRob_commit_vtype_bits_VMA(io_fromRob_commit_vtype_bits_VMA), .io_fromRob_commit_vtype_bits_VTA(io_fromRob_commit_vtype_bits_VTA), .io_fromRob_commit_vtype_bits_VSEW(io_fromRob_commit_vtype_bits_VSEW), .io_fromRob_commit_vtype_bits_VLMUL(io_fromRob_commit_vtype_bits_VLMUL), .io_fromRob_commit_vl(io_fromRob_commit_vl), .io_fromRob_commit_vstart_valid(io_fromRob_commit_vstart_valid), .io_fromRob_commit_vstart_bits(io_fromRob_commit_vstart_bits), .io_fromVecExcpMod_busy(io_fromVecExcpMod_busy), .io_perf_perfEventsFrontend_0_value(io_perf_perfEventsFrontend_0_value), .io_perf_perfEventsFrontend_1_value(io_perf_perfEventsFrontend_1_value), .io_perf_perfEventsFrontend_2_value(io_perf_perfEventsFrontend_2_value), .io_perf_perfEventsFrontend_3_value(io_perf_perfEventsFrontend_3_value), .io_perf_perfEventsFrontend_4_value(io_perf_perfEventsFrontend_4_value), .io_perf_perfEventsFrontend_5_value(io_perf_perfEventsFrontend_5_value), .io_perf_perfEventsFrontend_6_value(io_perf_perfEventsFrontend_6_value), .io_perf_perfEventsFrontend_7_value(io_perf_perfEventsFrontend_7_value), .io_perf_perfEventsBackend_0_value(io_perf_perfEventsBackend_0_value), .io_perf_perfEventsBackend_1_value(io_perf_perfEventsBackend_1_value), .io_perf_perfEventsBackend_2_value(io_perf_perfEventsBackend_2_value), .io_perf_perfEventsBackend_3_value(io_perf_perfEventsBackend_3_value), .io_perf_perfEventsBackend_4_value(io_perf_perfEventsBackend_4_value), .io_perf_perfEventsBackend_5_value(io_perf_perfEventsBackend_5_value), .io_perf_perfEventsBackend_6_value(io_perf_perfEventsBackend_6_value), .io_perf_perfEventsBackend_7_value(io_perf_perfEventsBackend_7_value), .io_perf_perfEventsLsu_0_value(io_perf_perfEventsLsu_0_value), .io_perf_perfEventsLsu_1_value(io_perf_perfEventsLsu_1_value), .io_perf_perfEventsLsu_2_value(io_perf_perfEventsLsu_2_value), .io_perf_perfEventsLsu_3_value(io_perf_perfEventsLsu_3_value), .io_perf_perfEventsLsu_4_value(io_perf_perfEventsLsu_4_value), .io_perf_perfEventsLsu_5_value(io_perf_perfEventsLsu_5_value), .io_perf_perfEventsLsu_6_value(io_perf_perfEventsLsu_6_value), .io_perf_perfEventsLsu_7_value(io_perf_perfEventsLsu_7_value), .io_perf_perfEventsHc_0_value(io_perf_perfEventsHc_0_value), .io_perf_perfEventsHc_1_value(io_perf_perfEventsHc_1_value), .io_perf_perfEventsHc_2_value(io_perf_perfEventsHc_2_value), .io_perf_perfEventsHc_3_value(io_perf_perfEventsHc_3_value), .io_perf_perfEventsHc_4_value(io_perf_perfEventsHc_4_value), .io_perf_perfEventsHc_5_value(io_perf_perfEventsHc_5_value), .io_perf_perfEventsHc_6_value(io_perf_perfEventsHc_6_value), .io_perf_perfEventsHc_7_value(io_perf_perfEventsHc_7_value), .io_perf_perfEventsHc_8_value(io_perf_perfEventsHc_8_value), .io_perf_perfEventsHc_9_value(io_perf_perfEventsHc_9_value), .io_perf_perfEventsHc_10_value(io_perf_perfEventsHc_10_value), .io_perf_perfEventsHc_11_value(io_perf_perfEventsHc_11_value), .io_perf_perfEventsHc_12_value(io_perf_perfEventsHc_12_value), .io_perf_perfEventsHc_13_value(io_perf_perfEventsHc_13_value), .io_perf_perfEventsHc_14_value(io_perf_perfEventsHc_14_value), .io_perf_perfEventsHc_15_value(io_perf_perfEventsHc_15_value), .io_perf_perfEventsHc_16_value(io_perf_perfEventsHc_16_value), .io_perf_perfEventsHc_17_value(io_perf_perfEventsHc_17_value), .io_perf_perfEventsHc_18_value(io_perf_perfEventsHc_18_value), .io_perf_perfEventsHc_19_value(io_perf_perfEventsHc_19_value), .io_perf_perfEventsHc_20_value(io_perf_perfEventsHc_20_value), .io_perf_perfEventsHc_21_value(io_perf_perfEventsHc_21_value), .io_perf_perfEventsHc_22_value(io_perf_perfEventsHc_22_value), .io_perf_perfEventsHc_23_value(io_perf_perfEventsHc_23_value), .io_perf_perfEventsHc_24_value(io_perf_perfEventsHc_24_value), .io_perf_perfEventsHc_25_value(io_perf_perfEventsHc_25_value), .io_perf_perfEventsHc_26_value(io_perf_perfEventsHc_26_value), .io_perf_perfEventsHc_27_value(io_perf_perfEventsHc_27_value), .io_perf_perfEventsHc_28_value(io_perf_perfEventsHc_28_value), .io_perf_perfEventsHc_29_value(io_perf_perfEventsHc_29_value), .io_perf_perfEventsHc_30_value(io_perf_perfEventsHc_30_value), .io_perf_perfEventsHc_31_value(io_perf_perfEventsHc_31_value), .io_perf_perfEventsHc_32_value(io_perf_perfEventsHc_32_value), .io_perf_perfEventsHc_33_value(io_perf_perfEventsHc_33_value), .io_perf_perfEventsHc_34_value(io_perf_perfEventsHc_34_value), .io_perf_perfEventsHc_35_value(io_perf_perfEventsHc_35_value), .io_perf_perfEventsHc_36_value(io_perf_perfEventsHc_36_value), .io_perf_perfEventsHc_37_value(io_perf_perfEventsHc_37_value), .io_perf_perfEventsHc_38_value(io_perf_perfEventsHc_38_value), .io_perf_perfEventsHc_39_value(io_perf_perfEventsHc_39_value), .io_perf_perfEventsHc_40_value(io_perf_perfEventsHc_40_value), .io_perf_perfEventsHc_41_value(io_perf_perfEventsHc_41_value), .io_perf_perfEventsHc_42_value(io_perf_perfEventsHc_42_value), .io_perf_perfEventsHc_43_value(io_perf_perfEventsHc_43_value), .io_perf_perfEventsHc_44_value(io_perf_perfEventsHc_44_value), .io_perf_perfEventsHc_45_value(io_perf_perfEventsHc_45_value), .io_perf_perfEventsHc_46_value(io_perf_perfEventsHc_46_value), .io_perf_perfEventsHc_47_value(io_perf_perfEventsHc_47_value), .io_out_ready(io_out_ready), .io_fetchMalTval(io_fetchMalTval), .fromAIA_rdata_valid(fromAIA_rdata_valid), .fromAIA_rdata_bits_data(fromAIA_rdata_bits_data), .fromAIA_rdata_bits_illegal(fromAIA_rdata_bits_illegal), .fromAIA_meip(fromAIA_meip), .fromAIA_seip(fromAIA_seip), .fromAIA_vseip(fromAIA_vseip), .fromAIA_mtopei_IID(fromAIA_mtopei_IID), .fromAIA_mtopei_IPRIO(fromAIA_mtopei_IPRIO), .fromAIA_stopei_IID(fromAIA_stopei_IID), .fromAIA_stopei_IPRIO(fromAIA_stopei_IPRIO), .fromAIA_vstopei_IID(fromAIA_vstopei_IID), .fromAIA_vstopei_IPRIO(fromAIA_vstopei_IPRIO), .io_in_ready(g_io_in_ready), .io_out_valid(g_io_out_valid), .io_out_bits_EX_II(g_io_out_bits_EX_II), .io_out_bits_EX_VI(g_io_out_bits_EX_VI), .io_out_bits_flushPipe(g_io_out_bits_flushPipe), .io_out_bits_rData(g_io_out_bits_rData), .io_out_bits_targetPcUpdate(g_io_out_bits_targetPcUpdate), .io_out_bits_targetPc_pc(g_io_out_bits_targetPc_pc), .io_out_bits_targetPc_raiseIPF(g_io_out_bits_targetPc_raiseIPF), .io_out_bits_targetPc_raiseIAF(g_io_out_bits_targetPc_raiseIAF), .io_out_bits_targetPc_raiseIGPF(g_io_out_bits_targetPc_raiseIGPF), .io_out_bits_regOut(g_io_out_bits_regOut), .io_out_bits_isPerfCnt(g_io_out_bits_isPerfCnt), .io_status_privState_PRVM(g_io_status_privState_PRVM), .io_status_privState_V(g_io_status_privState_V), .io_status_interrupt(g_io_status_interrupt), .io_status_wfiEvent(g_io_status_wfiEvent), .io_status_fpState_frm(g_io_status_fpState_frm), .io_status_vecState_vstart(g_io_status_vecState_vstart), .io_status_vecState_vxrm(g_io_status_vecState_vxrm), .io_status_singleStepFlag(g_io_status_singleStepFlag), .io_status_frontendTrigger_tUpdate_valid(g_io_status_frontendTrigger_tUpdate_valid), .io_status_frontendTrigger_tUpdate_bits_addr(g_io_status_frontendTrigger_tUpdate_bits_addr), .io_status_frontendTrigger_tUpdate_bits_tdata_matchType(g_io_status_frontendTrigger_tUpdate_bits_tdata_matchType), .io_status_frontendTrigger_tUpdate_bits_tdata_select(g_io_status_frontendTrigger_tUpdate_bits_tdata_select), .io_status_frontendTrigger_tUpdate_bits_tdata_action(g_io_status_frontendTrigger_tUpdate_bits_tdata_action), .io_status_frontendTrigger_tUpdate_bits_tdata_chain(g_io_status_frontendTrigger_tUpdate_bits_tdata_chain), .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2(g_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2), .io_status_frontendTrigger_tEnableVec_0(g_io_status_frontendTrigger_tEnableVec_0), .io_status_frontendTrigger_tEnableVec_1(g_io_status_frontendTrigger_tEnableVec_1), .io_status_frontendTrigger_tEnableVec_2(g_io_status_frontendTrigger_tEnableVec_2), .io_status_frontendTrigger_tEnableVec_3(g_io_status_frontendTrigger_tEnableVec_3), .io_status_frontendTrigger_debugMode(g_io_status_frontendTrigger_debugMode), .io_status_frontendTrigger_triggerCanRaiseBpExp(g_io_status_frontendTrigger_triggerCanRaiseBpExp), .io_status_memTrigger_tUpdate_valid(g_io_status_memTrigger_tUpdate_valid), .io_status_memTrigger_tUpdate_bits_addr(g_io_status_memTrigger_tUpdate_bits_addr), .io_status_memTrigger_tUpdate_bits_tdata_matchType(g_io_status_memTrigger_tUpdate_bits_tdata_matchType), .io_status_memTrigger_tUpdate_bits_tdata_select(g_io_status_memTrigger_tUpdate_bits_tdata_select), .io_status_memTrigger_tUpdate_bits_tdata_action(g_io_status_memTrigger_tUpdate_bits_tdata_action), .io_status_memTrigger_tUpdate_bits_tdata_chain(g_io_status_memTrigger_tUpdate_bits_tdata_chain), .io_status_memTrigger_tUpdate_bits_tdata_store(g_io_status_memTrigger_tUpdate_bits_tdata_store), .io_status_memTrigger_tUpdate_bits_tdata_load(g_io_status_memTrigger_tUpdate_bits_tdata_load), .io_status_memTrigger_tUpdate_bits_tdata_tdata2(g_io_status_memTrigger_tUpdate_bits_tdata_tdata2), .io_status_memTrigger_tEnableVec_0(g_io_status_memTrigger_tEnableVec_0), .io_status_memTrigger_tEnableVec_1(g_io_status_memTrigger_tEnableVec_1), .io_status_memTrigger_tEnableVec_2(g_io_status_memTrigger_tEnableVec_2), .io_status_memTrigger_tEnableVec_3(g_io_status_memTrigger_tEnableVec_3), .io_status_memTrigger_debugMode(g_io_status_memTrigger_debugMode), .io_status_memTrigger_triggerCanRaiseBpExp(g_io_status_memTrigger_triggerCanRaiseBpExp), .io_status_instrAddrTransType_bare(g_io_status_instrAddrTransType_bare), .io_status_instrAddrTransType_sv39(g_io_status_instrAddrTransType_sv39), .io_status_instrAddrTransType_sv39x4(g_io_status_instrAddrTransType_sv39x4), .io_status_instrAddrTransType_sv48(g_io_status_instrAddrTransType_sv48), .io_status_instrAddrTransType_sv48x4(g_io_status_instrAddrTransType_sv48x4), .io_status_traceCSR_cause(g_io_status_traceCSR_cause), .io_status_traceCSR_tval(g_io_status_traceCSR_tval), .io_status_traceCSR_lastPriv(g_io_status_traceCSR_lastPriv), .io_status_traceCSR_currentPriv(g_io_status_traceCSR_currentPriv), .io_status_custom_pf_ctrl_l1I_pf_enable(g_io_status_custom_pf_ctrl_l1I_pf_enable), .io_status_custom_pf_ctrl_l2_pf_enable(g_io_status_custom_pf_ctrl_l2_pf_enable), .io_status_custom_pf_ctrl_l1D_pf_enable(g_io_status_custom_pf_ctrl_l1D_pf_enable), .io_status_custom_pf_ctrl_l1D_pf_train_on_hit(g_io_status_custom_pf_ctrl_l1D_pf_train_on_hit), .io_status_custom_pf_ctrl_l1D_pf_enable_agt(g_io_status_custom_pf_ctrl_l1D_pf_enable_agt), .io_status_custom_pf_ctrl_l1D_pf_enable_pht(g_io_status_custom_pf_ctrl_l1D_pf_enable_pht), .io_status_custom_pf_ctrl_l1D_pf_active_threshold(g_io_status_custom_pf_ctrl_l1D_pf_active_threshold), .io_status_custom_pf_ctrl_l1D_pf_active_stride(g_io_status_custom_pf_ctrl_l1D_pf_active_stride), .io_status_custom_pf_ctrl_l1D_pf_enable_stride(g_io_status_custom_pf_ctrl_l1D_pf_enable_stride), .io_status_custom_pf_ctrl_l2_pf_store_only(g_io_status_custom_pf_ctrl_l2_pf_store_only), .io_status_custom_pf_ctrl_l2_pf_recv_enable(g_io_status_custom_pf_ctrl_l2_pf_recv_enable), .io_status_custom_pf_ctrl_l2_pf_pbop_enable(g_io_status_custom_pf_ctrl_l2_pf_pbop_enable), .io_status_custom_pf_ctrl_l2_pf_vbop_enable(g_io_status_custom_pf_ctrl_l2_pf_vbop_enable), .io_status_custom_lvpred_timeout(g_io_status_custom_lvpred_timeout), .io_status_custom_bp_ctrl_ubtb_enable(g_io_status_custom_bp_ctrl_ubtb_enable), .io_status_custom_bp_ctrl_btb_enable(g_io_status_custom_bp_ctrl_btb_enable), .io_status_custom_bp_ctrl_tage_enable(g_io_status_custom_bp_ctrl_tage_enable), .io_status_custom_bp_ctrl_sc_enable(g_io_status_custom_bp_ctrl_sc_enable), .io_status_custom_bp_ctrl_ras_enable(g_io_status_custom_bp_ctrl_ras_enable), .io_status_custom_ldld_vio_check_enable(g_io_status_custom_ldld_vio_check_enable), .io_status_custom_cache_error_enable(g_io_status_custom_cache_error_enable), .io_status_custom_uncache_write_outstanding_enable(g_io_status_custom_uncache_write_outstanding_enable), .io_status_custom_hd_misalign_st_enable(g_io_status_custom_hd_misalign_st_enable), .io_status_custom_hd_misalign_ld_enable(g_io_status_custom_hd_misalign_ld_enable), .io_status_custom_power_down_enable(g_io_status_custom_power_down_enable), .io_status_custom_flush_l2_enable(g_io_status_custom_flush_l2_enable), .io_status_custom_fusion_enable(g_io_status_custom_fusion_enable), .io_status_custom_wfi_enable(g_io_status_custom_wfi_enable), .io_status_criticalErrorState(g_io_status_criticalErrorState), .io_tlb_satpASIDChanged(g_io_tlb_satpASIDChanged), .io_tlb_vsatpASIDChanged(g_io_tlb_vsatpASIDChanged), .io_tlb_hgatpVMIDChanged(g_io_tlb_hgatpVMIDChanged), .io_tlb_satp_MODE(g_io_tlb_satp_MODE), .io_tlb_satp_ASID(g_io_tlb_satp_ASID), .io_tlb_satp_PPN(g_io_tlb_satp_PPN), .io_tlb_vsatp_MODE(g_io_tlb_vsatp_MODE), .io_tlb_vsatp_ASID(g_io_tlb_vsatp_ASID), .io_tlb_vsatp_PPN(g_io_tlb_vsatp_PPN), .io_tlb_hgatp_MODE(g_io_tlb_hgatp_MODE), .io_tlb_hgatp_VMID(g_io_tlb_hgatp_VMID), .io_tlb_hgatp_PPN(g_io_tlb_hgatp_PPN), .io_tlb_mxr(g_io_tlb_mxr), .io_tlb_sum(g_io_tlb_sum), .io_tlb_vmxr(g_io_tlb_vmxr), .io_tlb_vsum(g_io_tlb_vsum), .io_tlb_spvp(g_io_tlb_spvp), .io_tlb_imode(g_io_tlb_imode), .io_tlb_dmode(g_io_tlb_dmode), .io_tlb_dvirt(g_io_tlb_dvirt), .io_tlb_mPBMTE(g_io_tlb_mPBMTE), .io_tlb_hPBMTE(g_io_tlb_hPBMTE), .io_tlb_pmm_mseccfg(g_io_tlb_pmm_mseccfg), .io_tlb_pmm_menvcfg(g_io_tlb_pmm_menvcfg), .io_tlb_pmm_henvcfg(g_io_tlb_pmm_henvcfg), .io_tlb_pmm_hstatus(g_io_tlb_pmm_hstatus), .io_tlb_pmm_senvcfg(g_io_tlb_pmm_senvcfg), .io_toDecode_illegalInst_sfenceVMA(g_io_toDecode_illegalInst_sfenceVMA), .io_toDecode_illegalInst_sfencePart(g_io_toDecode_illegalInst_sfencePart), .io_toDecode_illegalInst_hfenceGVMA(g_io_toDecode_illegalInst_hfenceGVMA), .io_toDecode_illegalInst_hfenceVVMA(g_io_toDecode_illegalInst_hfenceVVMA), .io_toDecode_illegalInst_hlsv(g_io_toDecode_illegalInst_hlsv), .io_toDecode_illegalInst_fsIsOff(g_io_toDecode_illegalInst_fsIsOff), .io_toDecode_illegalInst_vsIsOff(g_io_toDecode_illegalInst_vsIsOff), .io_toDecode_illegalInst_wfi(g_io_toDecode_illegalInst_wfi), .io_toDecode_illegalInst_wrs_nto(g_io_toDecode_illegalInst_wrs_nto), .io_toDecode_illegalInst_frm(g_io_toDecode_illegalInst_frm), .io_toDecode_illegalInst_cboZ(g_io_toDecode_illegalInst_cboZ), .io_toDecode_illegalInst_cboCF(g_io_toDecode_illegalInst_cboCF), .io_toDecode_illegalInst_cboI(g_io_toDecode_illegalInst_cboI), .io_toDecode_virtualInst_sfenceVMA(g_io_toDecode_virtualInst_sfenceVMA), .io_toDecode_virtualInst_sfencePart(g_io_toDecode_virtualInst_sfencePart), .io_toDecode_virtualInst_hfence(g_io_toDecode_virtualInst_hfence), .io_toDecode_virtualInst_hlsv(g_io_toDecode_virtualInst_hlsv), .io_toDecode_virtualInst_wfi(g_io_toDecode_virtualInst_wfi), .io_toDecode_virtualInst_wrs_nto(g_io_toDecode_virtualInst_wrs_nto), .io_toDecode_virtualInst_cboZ(g_io_toDecode_virtualInst_cboZ), .io_toDecode_virtualInst_cboCF(g_io_toDecode_virtualInst_cboCF), .io_toDecode_virtualInst_cboI(g_io_toDecode_virtualInst_cboI), .io_toDecode_special_cboI2F(g_io_toDecode_special_cboI2F), .io_distributedWenLegal(g_io_distributedWenLegal), .toAIA_addr_valid(g_toAIA_addr_valid), .toAIA_addr_bits_addr(g_toAIA_addr_bits_addr), .toAIA_addr_bits_v(g_toAIA_addr_bits_v), .toAIA_addr_bits_prvm(g_toAIA_addr_bits_prvm), .toAIA_vgein(g_toAIA_vgein), .toAIA_wdata_valid(g_toAIA_wdata_valid), .toAIA_wdata_bits_op(g_toAIA_wdata_bits_op), .toAIA_wdata_bits_data(g_toAIA_wdata_bits_data), .toAIA_mClaim(g_toAIA_mClaim), .toAIA_sClaim(g_toAIA_sClaim), .toAIA_vsClaim(g_toAIA_vsClaim), .io_error_0(g_io_error_0));
  NewCSR_xs u_i (.clock(clk), .reset(rst), .platformIRP_MEIP(platformIRP_MEIP), .platformIRP_MTIP(platformIRP_MTIP), .platformIRP_MSIP(platformIRP_MSIP), .platformIRP_SEIP(platformIRP_SEIP), .platformIRP_debugIP(platformIRP_debugIP), .nonMaskableIRP_NMI_43(nonMaskableIRP_NMI_43), .nonMaskableIRP_NMI_31(nonMaskableIRP_NMI_31), .io_fromTop_hartId(io_fromTop_hartId), .io_fromTop_clintTime_valid(io_fromTop_clintTime_valid), .io_fromTop_clintTime_bits(io_fromTop_clintTime_bits), .io_fromTop_l2FlushDone(io_fromTop_l2FlushDone), .io_fromTop_criticalErrorState(io_fromTop_criticalErrorState), .io_in_valid(io_in_valid), .io_in_bits_wen(io_in_bits_wen), .io_in_bits_ren(io_in_bits_ren), .io_in_bits_op(io_in_bits_op), .io_in_bits_addr(io_in_bits_addr), .io_in_bits_src(io_in_bits_src), .io_in_bits_wdata(io_in_bits_wdata), .io_in_bits_mnret(io_in_bits_mnret), .io_in_bits_mret(io_in_bits_mret), .io_in_bits_sret(io_in_bits_sret), .io_in_bits_dret(io_in_bits_dret), .io_in_bits_redirectFlush(io_in_bits_redirectFlush), .io_trapInst_valid(io_trapInst_valid), .io_trapInst_bits(io_trapInst_bits), .io_fromMem_excpVA(io_fromMem_excpVA), .io_fromMem_excpGPA(io_fromMem_excpGPA), .io_fromMem_excpIsForVSnonLeafPTE(io_fromMem_excpIsForVSnonLeafPTE), .io_fromRob_trap_valid(io_fromRob_trap_valid), .io_fromRob_trap_bits_pc(io_fromRob_trap_bits_pc), .io_fromRob_trap_bits_pcGPA(io_fromRob_trap_bits_pcGPA), .io_fromRob_trap_bits_trapVec(io_fromRob_trap_bits_trapVec), .io_fromRob_trap_bits_isFetchBkpt(io_fromRob_trap_bits_isFetchBkpt), .io_fromRob_trap_bits_singleStep(io_fromRob_trap_bits_singleStep), .io_fromRob_trap_bits_trigger(io_fromRob_trap_bits_trigger), .io_fromRob_trap_bits_crossPageIPFFix(io_fromRob_trap_bits_crossPageIPFFix), .io_fromRob_trap_bits_isInterrupt(io_fromRob_trap_bits_isInterrupt), .io_fromRob_trap_bits_isHls(io_fromRob_trap_bits_isHls), .io_fromRob_trap_bits_isFetchMalAddr(io_fromRob_trap_bits_isFetchMalAddr), .io_fromRob_trap_bits_isForVSnonLeafPTE(io_fromRob_trap_bits_isForVSnonLeafPTE), .io_fromRob_commit_instNum_bits(io_fromRob_commit_instNum_bits), .io_fromRob_commit_fflags_valid(io_fromRob_commit_fflags_valid), .io_fromRob_commit_fflags_bits(io_fromRob_commit_fflags_bits), .io_fromRob_commit_fsDirty(io_fromRob_commit_fsDirty), .io_fromRob_commit_vxsat_valid(io_fromRob_commit_vxsat_valid), .io_fromRob_commit_vxsat_bits(io_fromRob_commit_vxsat_bits), .io_fromRob_commit_vsDirty(io_fromRob_commit_vsDirty), .io_fromRob_commit_vtype_valid(io_fromRob_commit_vtype_valid), .io_fromRob_commit_vtype_bits_VILL(io_fromRob_commit_vtype_bits_VILL), .io_fromRob_commit_vtype_bits_VMA(io_fromRob_commit_vtype_bits_VMA), .io_fromRob_commit_vtype_bits_VTA(io_fromRob_commit_vtype_bits_VTA), .io_fromRob_commit_vtype_bits_VSEW(io_fromRob_commit_vtype_bits_VSEW), .io_fromRob_commit_vtype_bits_VLMUL(io_fromRob_commit_vtype_bits_VLMUL), .io_fromRob_commit_vl(io_fromRob_commit_vl), .io_fromRob_commit_vstart_valid(io_fromRob_commit_vstart_valid), .io_fromRob_commit_vstart_bits(io_fromRob_commit_vstart_bits), .io_fromVecExcpMod_busy(io_fromVecExcpMod_busy), .io_perf_perfEventsFrontend_0_value(io_perf_perfEventsFrontend_0_value), .io_perf_perfEventsFrontend_1_value(io_perf_perfEventsFrontend_1_value), .io_perf_perfEventsFrontend_2_value(io_perf_perfEventsFrontend_2_value), .io_perf_perfEventsFrontend_3_value(io_perf_perfEventsFrontend_3_value), .io_perf_perfEventsFrontend_4_value(io_perf_perfEventsFrontend_4_value), .io_perf_perfEventsFrontend_5_value(io_perf_perfEventsFrontend_5_value), .io_perf_perfEventsFrontend_6_value(io_perf_perfEventsFrontend_6_value), .io_perf_perfEventsFrontend_7_value(io_perf_perfEventsFrontend_7_value), .io_perf_perfEventsBackend_0_value(io_perf_perfEventsBackend_0_value), .io_perf_perfEventsBackend_1_value(io_perf_perfEventsBackend_1_value), .io_perf_perfEventsBackend_2_value(io_perf_perfEventsBackend_2_value), .io_perf_perfEventsBackend_3_value(io_perf_perfEventsBackend_3_value), .io_perf_perfEventsBackend_4_value(io_perf_perfEventsBackend_4_value), .io_perf_perfEventsBackend_5_value(io_perf_perfEventsBackend_5_value), .io_perf_perfEventsBackend_6_value(io_perf_perfEventsBackend_6_value), .io_perf_perfEventsBackend_7_value(io_perf_perfEventsBackend_7_value), .io_perf_perfEventsLsu_0_value(io_perf_perfEventsLsu_0_value), .io_perf_perfEventsLsu_1_value(io_perf_perfEventsLsu_1_value), .io_perf_perfEventsLsu_2_value(io_perf_perfEventsLsu_2_value), .io_perf_perfEventsLsu_3_value(io_perf_perfEventsLsu_3_value), .io_perf_perfEventsLsu_4_value(io_perf_perfEventsLsu_4_value), .io_perf_perfEventsLsu_5_value(io_perf_perfEventsLsu_5_value), .io_perf_perfEventsLsu_6_value(io_perf_perfEventsLsu_6_value), .io_perf_perfEventsLsu_7_value(io_perf_perfEventsLsu_7_value), .io_perf_perfEventsHc_0_value(io_perf_perfEventsHc_0_value), .io_perf_perfEventsHc_1_value(io_perf_perfEventsHc_1_value), .io_perf_perfEventsHc_2_value(io_perf_perfEventsHc_2_value), .io_perf_perfEventsHc_3_value(io_perf_perfEventsHc_3_value), .io_perf_perfEventsHc_4_value(io_perf_perfEventsHc_4_value), .io_perf_perfEventsHc_5_value(io_perf_perfEventsHc_5_value), .io_perf_perfEventsHc_6_value(io_perf_perfEventsHc_6_value), .io_perf_perfEventsHc_7_value(io_perf_perfEventsHc_7_value), .io_perf_perfEventsHc_8_value(io_perf_perfEventsHc_8_value), .io_perf_perfEventsHc_9_value(io_perf_perfEventsHc_9_value), .io_perf_perfEventsHc_10_value(io_perf_perfEventsHc_10_value), .io_perf_perfEventsHc_11_value(io_perf_perfEventsHc_11_value), .io_perf_perfEventsHc_12_value(io_perf_perfEventsHc_12_value), .io_perf_perfEventsHc_13_value(io_perf_perfEventsHc_13_value), .io_perf_perfEventsHc_14_value(io_perf_perfEventsHc_14_value), .io_perf_perfEventsHc_15_value(io_perf_perfEventsHc_15_value), .io_perf_perfEventsHc_16_value(io_perf_perfEventsHc_16_value), .io_perf_perfEventsHc_17_value(io_perf_perfEventsHc_17_value), .io_perf_perfEventsHc_18_value(io_perf_perfEventsHc_18_value), .io_perf_perfEventsHc_19_value(io_perf_perfEventsHc_19_value), .io_perf_perfEventsHc_20_value(io_perf_perfEventsHc_20_value), .io_perf_perfEventsHc_21_value(io_perf_perfEventsHc_21_value), .io_perf_perfEventsHc_22_value(io_perf_perfEventsHc_22_value), .io_perf_perfEventsHc_23_value(io_perf_perfEventsHc_23_value), .io_perf_perfEventsHc_24_value(io_perf_perfEventsHc_24_value), .io_perf_perfEventsHc_25_value(io_perf_perfEventsHc_25_value), .io_perf_perfEventsHc_26_value(io_perf_perfEventsHc_26_value), .io_perf_perfEventsHc_27_value(io_perf_perfEventsHc_27_value), .io_perf_perfEventsHc_28_value(io_perf_perfEventsHc_28_value), .io_perf_perfEventsHc_29_value(io_perf_perfEventsHc_29_value), .io_perf_perfEventsHc_30_value(io_perf_perfEventsHc_30_value), .io_perf_perfEventsHc_31_value(io_perf_perfEventsHc_31_value), .io_perf_perfEventsHc_32_value(io_perf_perfEventsHc_32_value), .io_perf_perfEventsHc_33_value(io_perf_perfEventsHc_33_value), .io_perf_perfEventsHc_34_value(io_perf_perfEventsHc_34_value), .io_perf_perfEventsHc_35_value(io_perf_perfEventsHc_35_value), .io_perf_perfEventsHc_36_value(io_perf_perfEventsHc_36_value), .io_perf_perfEventsHc_37_value(io_perf_perfEventsHc_37_value), .io_perf_perfEventsHc_38_value(io_perf_perfEventsHc_38_value), .io_perf_perfEventsHc_39_value(io_perf_perfEventsHc_39_value), .io_perf_perfEventsHc_40_value(io_perf_perfEventsHc_40_value), .io_perf_perfEventsHc_41_value(io_perf_perfEventsHc_41_value), .io_perf_perfEventsHc_42_value(io_perf_perfEventsHc_42_value), .io_perf_perfEventsHc_43_value(io_perf_perfEventsHc_43_value), .io_perf_perfEventsHc_44_value(io_perf_perfEventsHc_44_value), .io_perf_perfEventsHc_45_value(io_perf_perfEventsHc_45_value), .io_perf_perfEventsHc_46_value(io_perf_perfEventsHc_46_value), .io_perf_perfEventsHc_47_value(io_perf_perfEventsHc_47_value), .io_out_ready(io_out_ready), .io_fetchMalTval(io_fetchMalTval), .fromAIA_rdata_valid(fromAIA_rdata_valid), .fromAIA_rdata_bits_data(fromAIA_rdata_bits_data), .fromAIA_rdata_bits_illegal(fromAIA_rdata_bits_illegal), .fromAIA_meip(fromAIA_meip), .fromAIA_seip(fromAIA_seip), .fromAIA_vseip(fromAIA_vseip), .fromAIA_mtopei_IID(fromAIA_mtopei_IID), .fromAIA_mtopei_IPRIO(fromAIA_mtopei_IPRIO), .fromAIA_stopei_IID(fromAIA_stopei_IID), .fromAIA_stopei_IPRIO(fromAIA_stopei_IPRIO), .fromAIA_vstopei_IID(fromAIA_vstopei_IID), .fromAIA_vstopei_IPRIO(fromAIA_vstopei_IPRIO), .io_in_ready(i_io_in_ready), .io_out_valid(i_io_out_valid), .io_out_bits_EX_II(i_io_out_bits_EX_II), .io_out_bits_EX_VI(i_io_out_bits_EX_VI), .io_out_bits_flushPipe(i_io_out_bits_flushPipe), .io_out_bits_rData(i_io_out_bits_rData), .io_out_bits_targetPcUpdate(i_io_out_bits_targetPcUpdate), .io_out_bits_targetPc_pc(i_io_out_bits_targetPc_pc), .io_out_bits_targetPc_raiseIPF(i_io_out_bits_targetPc_raiseIPF), .io_out_bits_targetPc_raiseIAF(i_io_out_bits_targetPc_raiseIAF), .io_out_bits_targetPc_raiseIGPF(i_io_out_bits_targetPc_raiseIGPF), .io_out_bits_regOut(i_io_out_bits_regOut), .io_out_bits_isPerfCnt(i_io_out_bits_isPerfCnt), .io_status_privState_PRVM(i_io_status_privState_PRVM), .io_status_privState_V(i_io_status_privState_V), .io_status_interrupt(i_io_status_interrupt), .io_status_wfiEvent(i_io_status_wfiEvent), .io_status_fpState_frm(i_io_status_fpState_frm), .io_status_vecState_vstart(i_io_status_vecState_vstart), .io_status_vecState_vxrm(i_io_status_vecState_vxrm), .io_status_singleStepFlag(i_io_status_singleStepFlag), .io_status_frontendTrigger_tUpdate_valid(i_io_status_frontendTrigger_tUpdate_valid), .io_status_frontendTrigger_tUpdate_bits_addr(i_io_status_frontendTrigger_tUpdate_bits_addr), .io_status_frontendTrigger_tUpdate_bits_tdata_matchType(i_io_status_frontendTrigger_tUpdate_bits_tdata_matchType), .io_status_frontendTrigger_tUpdate_bits_tdata_select(i_io_status_frontendTrigger_tUpdate_bits_tdata_select), .io_status_frontendTrigger_tUpdate_bits_tdata_action(i_io_status_frontendTrigger_tUpdate_bits_tdata_action), .io_status_frontendTrigger_tUpdate_bits_tdata_chain(i_io_status_frontendTrigger_tUpdate_bits_tdata_chain), .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2(i_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2), .io_status_frontendTrigger_tEnableVec_0(i_io_status_frontendTrigger_tEnableVec_0), .io_status_frontendTrigger_tEnableVec_1(i_io_status_frontendTrigger_tEnableVec_1), .io_status_frontendTrigger_tEnableVec_2(i_io_status_frontendTrigger_tEnableVec_2), .io_status_frontendTrigger_tEnableVec_3(i_io_status_frontendTrigger_tEnableVec_3), .io_status_frontendTrigger_debugMode(i_io_status_frontendTrigger_debugMode), .io_status_frontendTrigger_triggerCanRaiseBpExp(i_io_status_frontendTrigger_triggerCanRaiseBpExp), .io_status_memTrigger_tUpdate_valid(i_io_status_memTrigger_tUpdate_valid), .io_status_memTrigger_tUpdate_bits_addr(i_io_status_memTrigger_tUpdate_bits_addr), .io_status_memTrigger_tUpdate_bits_tdata_matchType(i_io_status_memTrigger_tUpdate_bits_tdata_matchType), .io_status_memTrigger_tUpdate_bits_tdata_select(i_io_status_memTrigger_tUpdate_bits_tdata_select), .io_status_memTrigger_tUpdate_bits_tdata_action(i_io_status_memTrigger_tUpdate_bits_tdata_action), .io_status_memTrigger_tUpdate_bits_tdata_chain(i_io_status_memTrigger_tUpdate_bits_tdata_chain), .io_status_memTrigger_tUpdate_bits_tdata_store(i_io_status_memTrigger_tUpdate_bits_tdata_store), .io_status_memTrigger_tUpdate_bits_tdata_load(i_io_status_memTrigger_tUpdate_bits_tdata_load), .io_status_memTrigger_tUpdate_bits_tdata_tdata2(i_io_status_memTrigger_tUpdate_bits_tdata_tdata2), .io_status_memTrigger_tEnableVec_0(i_io_status_memTrigger_tEnableVec_0), .io_status_memTrigger_tEnableVec_1(i_io_status_memTrigger_tEnableVec_1), .io_status_memTrigger_tEnableVec_2(i_io_status_memTrigger_tEnableVec_2), .io_status_memTrigger_tEnableVec_3(i_io_status_memTrigger_tEnableVec_3), .io_status_memTrigger_debugMode(i_io_status_memTrigger_debugMode), .io_status_memTrigger_triggerCanRaiseBpExp(i_io_status_memTrigger_triggerCanRaiseBpExp), .io_status_instrAddrTransType_bare(i_io_status_instrAddrTransType_bare), .io_status_instrAddrTransType_sv39(i_io_status_instrAddrTransType_sv39), .io_status_instrAddrTransType_sv39x4(i_io_status_instrAddrTransType_sv39x4), .io_status_instrAddrTransType_sv48(i_io_status_instrAddrTransType_sv48), .io_status_instrAddrTransType_sv48x4(i_io_status_instrAddrTransType_sv48x4), .io_status_traceCSR_cause(i_io_status_traceCSR_cause), .io_status_traceCSR_tval(i_io_status_traceCSR_tval), .io_status_traceCSR_lastPriv(i_io_status_traceCSR_lastPriv), .io_status_traceCSR_currentPriv(i_io_status_traceCSR_currentPriv), .io_status_custom_pf_ctrl_l1I_pf_enable(i_io_status_custom_pf_ctrl_l1I_pf_enable), .io_status_custom_pf_ctrl_l2_pf_enable(i_io_status_custom_pf_ctrl_l2_pf_enable), .io_status_custom_pf_ctrl_l1D_pf_enable(i_io_status_custom_pf_ctrl_l1D_pf_enable), .io_status_custom_pf_ctrl_l1D_pf_train_on_hit(i_io_status_custom_pf_ctrl_l1D_pf_train_on_hit), .io_status_custom_pf_ctrl_l1D_pf_enable_agt(i_io_status_custom_pf_ctrl_l1D_pf_enable_agt), .io_status_custom_pf_ctrl_l1D_pf_enable_pht(i_io_status_custom_pf_ctrl_l1D_pf_enable_pht), .io_status_custom_pf_ctrl_l1D_pf_active_threshold(i_io_status_custom_pf_ctrl_l1D_pf_active_threshold), .io_status_custom_pf_ctrl_l1D_pf_active_stride(i_io_status_custom_pf_ctrl_l1D_pf_active_stride), .io_status_custom_pf_ctrl_l1D_pf_enable_stride(i_io_status_custom_pf_ctrl_l1D_pf_enable_stride), .io_status_custom_pf_ctrl_l2_pf_store_only(i_io_status_custom_pf_ctrl_l2_pf_store_only), .io_status_custom_pf_ctrl_l2_pf_recv_enable(i_io_status_custom_pf_ctrl_l2_pf_recv_enable), .io_status_custom_pf_ctrl_l2_pf_pbop_enable(i_io_status_custom_pf_ctrl_l2_pf_pbop_enable), .io_status_custom_pf_ctrl_l2_pf_vbop_enable(i_io_status_custom_pf_ctrl_l2_pf_vbop_enable), .io_status_custom_lvpred_timeout(i_io_status_custom_lvpred_timeout), .io_status_custom_bp_ctrl_ubtb_enable(i_io_status_custom_bp_ctrl_ubtb_enable), .io_status_custom_bp_ctrl_btb_enable(i_io_status_custom_bp_ctrl_btb_enable), .io_status_custom_bp_ctrl_tage_enable(i_io_status_custom_bp_ctrl_tage_enable), .io_status_custom_bp_ctrl_sc_enable(i_io_status_custom_bp_ctrl_sc_enable), .io_status_custom_bp_ctrl_ras_enable(i_io_status_custom_bp_ctrl_ras_enable), .io_status_custom_ldld_vio_check_enable(i_io_status_custom_ldld_vio_check_enable), .io_status_custom_cache_error_enable(i_io_status_custom_cache_error_enable), .io_status_custom_uncache_write_outstanding_enable(i_io_status_custom_uncache_write_outstanding_enable), .io_status_custom_hd_misalign_st_enable(i_io_status_custom_hd_misalign_st_enable), .io_status_custom_hd_misalign_ld_enable(i_io_status_custom_hd_misalign_ld_enable), .io_status_custom_power_down_enable(i_io_status_custom_power_down_enable), .io_status_custom_flush_l2_enable(i_io_status_custom_flush_l2_enable), .io_status_custom_fusion_enable(i_io_status_custom_fusion_enable), .io_status_custom_wfi_enable(i_io_status_custom_wfi_enable), .io_status_criticalErrorState(i_io_status_criticalErrorState), .io_tlb_satpASIDChanged(i_io_tlb_satpASIDChanged), .io_tlb_vsatpASIDChanged(i_io_tlb_vsatpASIDChanged), .io_tlb_hgatpVMIDChanged(i_io_tlb_hgatpVMIDChanged), .io_tlb_satp_MODE(i_io_tlb_satp_MODE), .io_tlb_satp_ASID(i_io_tlb_satp_ASID), .io_tlb_satp_PPN(i_io_tlb_satp_PPN), .io_tlb_vsatp_MODE(i_io_tlb_vsatp_MODE), .io_tlb_vsatp_ASID(i_io_tlb_vsatp_ASID), .io_tlb_vsatp_PPN(i_io_tlb_vsatp_PPN), .io_tlb_hgatp_MODE(i_io_tlb_hgatp_MODE), .io_tlb_hgatp_VMID(i_io_tlb_hgatp_VMID), .io_tlb_hgatp_PPN(i_io_tlb_hgatp_PPN), .io_tlb_mxr(i_io_tlb_mxr), .io_tlb_sum(i_io_tlb_sum), .io_tlb_vmxr(i_io_tlb_vmxr), .io_tlb_vsum(i_io_tlb_vsum), .io_tlb_spvp(i_io_tlb_spvp), .io_tlb_imode(i_io_tlb_imode), .io_tlb_dmode(i_io_tlb_dmode), .io_tlb_dvirt(i_io_tlb_dvirt), .io_tlb_mPBMTE(i_io_tlb_mPBMTE), .io_tlb_hPBMTE(i_io_tlb_hPBMTE), .io_tlb_pmm_mseccfg(i_io_tlb_pmm_mseccfg), .io_tlb_pmm_menvcfg(i_io_tlb_pmm_menvcfg), .io_tlb_pmm_henvcfg(i_io_tlb_pmm_henvcfg), .io_tlb_pmm_hstatus(i_io_tlb_pmm_hstatus), .io_tlb_pmm_senvcfg(i_io_tlb_pmm_senvcfg), .io_toDecode_illegalInst_sfenceVMA(i_io_toDecode_illegalInst_sfenceVMA), .io_toDecode_illegalInst_sfencePart(i_io_toDecode_illegalInst_sfencePart), .io_toDecode_illegalInst_hfenceGVMA(i_io_toDecode_illegalInst_hfenceGVMA), .io_toDecode_illegalInst_hfenceVVMA(i_io_toDecode_illegalInst_hfenceVVMA), .io_toDecode_illegalInst_hlsv(i_io_toDecode_illegalInst_hlsv), .io_toDecode_illegalInst_fsIsOff(i_io_toDecode_illegalInst_fsIsOff), .io_toDecode_illegalInst_vsIsOff(i_io_toDecode_illegalInst_vsIsOff), .io_toDecode_illegalInst_wfi(i_io_toDecode_illegalInst_wfi), .io_toDecode_illegalInst_wrs_nto(i_io_toDecode_illegalInst_wrs_nto), .io_toDecode_illegalInst_frm(i_io_toDecode_illegalInst_frm), .io_toDecode_illegalInst_cboZ(i_io_toDecode_illegalInst_cboZ), .io_toDecode_illegalInst_cboCF(i_io_toDecode_illegalInst_cboCF), .io_toDecode_illegalInst_cboI(i_io_toDecode_illegalInst_cboI), .io_toDecode_virtualInst_sfenceVMA(i_io_toDecode_virtualInst_sfenceVMA), .io_toDecode_virtualInst_sfencePart(i_io_toDecode_virtualInst_sfencePart), .io_toDecode_virtualInst_hfence(i_io_toDecode_virtualInst_hfence), .io_toDecode_virtualInst_hlsv(i_io_toDecode_virtualInst_hlsv), .io_toDecode_virtualInst_wfi(i_io_toDecode_virtualInst_wfi), .io_toDecode_virtualInst_wrs_nto(i_io_toDecode_virtualInst_wrs_nto), .io_toDecode_virtualInst_cboZ(i_io_toDecode_virtualInst_cboZ), .io_toDecode_virtualInst_cboCF(i_io_toDecode_virtualInst_cboCF), .io_toDecode_virtualInst_cboI(i_io_toDecode_virtualInst_cboI), .io_toDecode_special_cboI2F(i_io_toDecode_special_cboI2F), .io_distributedWenLegal(i_io_distributedWenLegal), .toAIA_addr_valid(i_toAIA_addr_valid), .toAIA_addr_bits_addr(i_toAIA_addr_bits_addr), .toAIA_addr_bits_v(i_toAIA_addr_bits_v), .toAIA_addr_bits_prvm(i_toAIA_addr_bits_prvm), .toAIA_vgein(i_toAIA_vgein), .toAIA_wdata_valid(i_toAIA_wdata_valid), .toAIA_wdata_bits_op(i_toAIA_wdata_bits_op), .toAIA_wdata_bits_data(i_toAIA_wdata_bits_data), .toAIA_mClaim(i_toAIA_mClaim), .toAIA_sClaim(i_toAIA_sClaim), .toAIA_vsClaim(i_toAIA_vsClaim), .io_error_0(i_io_error_0));
  always @(negedge clk) begin
    if (rst) begin
      io_fromTop_clintTime_valid <= 1'b0;
      io_in_valid <= 1'b0;
      io_trapInst_valid <= 1'b0;
      io_fromRob_trap_valid <= 1'b0;
      io_fromRob_commit_fflags_valid <= 1'b0;
      io_fromRob_commit_vxsat_valid <= 1'b0;
      io_fromRob_commit_vtype_valid <= 1'b0;
      io_fromRob_commit_vstart_valid <= 1'b0;
      fromAIA_rdata_valid <= 1'b0;
    end else begin
      platformIRP_MEIP <= $urandom_range(0,1);
      platformIRP_MTIP <= $urandom_range(0,1);
      platformIRP_MSIP <= $urandom_range(0,1);
      platformIRP_SEIP <= $urandom_range(0,1);
      platformIRP_debugIP <= $urandom_range(0,1);
      nonMaskableIRP_NMI_43 <= $urandom_range(0,1);
      nonMaskableIRP_NMI_31 <= $urandom_range(0,1);
      io_fromTop_hartId <= 6'($urandom);
      io_fromTop_clintTime_valid <= $urandom_range(0,1);
      io_fromTop_clintTime_bits <= 64'({$urandom(), $urandom()});
      io_fromTop_l2FlushDone <= $urandom_range(0,1);
      io_fromTop_criticalErrorState <= $urandom_range(0,1);
      io_in_valid <= $urandom_range(0,1);
      io_in_bits_wen <= $urandom_range(0,1);
      io_in_bits_ren <= $urandom_range(0,1);
      io_in_bits_op <= 2'($urandom);
      io_in_bits_addr <= 12'($urandom);
      io_in_bits_src <= 64'({$urandom(), $urandom()});
      io_in_bits_wdata <= 64'({$urandom(), $urandom()});
      io_in_bits_mnret <= $urandom_range(0,1);
      io_in_bits_mret <= $urandom_range(0,1);
      io_in_bits_sret <= $urandom_range(0,1);
      io_in_bits_dret <= $urandom_range(0,1);
      io_in_bits_redirectFlush <= $urandom_range(0,1);
      io_trapInst_valid <= $urandom_range(0,1);
      io_trapInst_bits <= 32'($urandom);
      io_fromMem_excpVA <= 64'({$urandom(), $urandom()});
      io_fromMem_excpGPA <= 64'({$urandom(), $urandom()});
      io_fromMem_excpIsForVSnonLeafPTE <= $urandom_range(0,1);
      io_fromRob_trap_valid <= $urandom_range(0,1);
      io_fromRob_trap_bits_pc <= 50'({$urandom(), $urandom()});
      io_fromRob_trap_bits_pcGPA <= 56'({$urandom(), $urandom()});
      io_fromRob_trap_bits_trapVec <= 64'({$urandom(), $urandom()});
      io_fromRob_trap_bits_isFetchBkpt <= $urandom_range(0,1);
      io_fromRob_trap_bits_singleStep <= $urandom_range(0,1);
      io_fromRob_trap_bits_trigger <= 4'($urandom);
      io_fromRob_trap_bits_crossPageIPFFix <= $urandom_range(0,1);
      io_fromRob_trap_bits_isInterrupt <= $urandom_range(0,1);
      io_fromRob_trap_bits_isHls <= $urandom_range(0,1);
      io_fromRob_trap_bits_isFetchMalAddr <= $urandom_range(0,1);
      io_fromRob_trap_bits_isForVSnonLeafPTE <= $urandom_range(0,1);
      io_fromRob_commit_instNum_bits <= 7'($urandom);
      io_fromRob_commit_fflags_valid <= $urandom_range(0,1);
      io_fromRob_commit_fflags_bits <= 5'($urandom);
      io_fromRob_commit_fsDirty <= $urandom_range(0,1);
      io_fromRob_commit_vxsat_valid <= $urandom_range(0,1);
      io_fromRob_commit_vxsat_bits <= $urandom_range(0,1);
      io_fromRob_commit_vsDirty <= $urandom_range(0,1);
      io_fromRob_commit_vtype_valid <= $urandom_range(0,1);
      io_fromRob_commit_vtype_bits_VILL <= $urandom_range(0,1);
      io_fromRob_commit_vtype_bits_VMA <= $urandom_range(0,1);
      io_fromRob_commit_vtype_bits_VTA <= $urandom_range(0,1);
      io_fromRob_commit_vtype_bits_VSEW <= 3'($urandom);
      io_fromRob_commit_vtype_bits_VLMUL <= 3'($urandom);
      io_fromRob_commit_vl <= 8'($urandom);
      io_fromRob_commit_vstart_valid <= $urandom_range(0,1);
      io_fromRob_commit_vstart_bits <= 7'($urandom);
      io_fromVecExcpMod_busy <= $urandom_range(0,1);
      io_perf_perfEventsFrontend_0_value <= 6'($urandom);
      io_perf_perfEventsFrontend_1_value <= 6'($urandom);
      io_perf_perfEventsFrontend_2_value <= 6'($urandom);
      io_perf_perfEventsFrontend_3_value <= 6'($urandom);
      io_perf_perfEventsFrontend_4_value <= 6'($urandom);
      io_perf_perfEventsFrontend_5_value <= 6'($urandom);
      io_perf_perfEventsFrontend_6_value <= 6'($urandom);
      io_perf_perfEventsFrontend_7_value <= 6'($urandom);
      io_perf_perfEventsBackend_0_value <= 6'($urandom);
      io_perf_perfEventsBackend_1_value <= 6'($urandom);
      io_perf_perfEventsBackend_2_value <= 6'($urandom);
      io_perf_perfEventsBackend_3_value <= 6'($urandom);
      io_perf_perfEventsBackend_4_value <= 6'($urandom);
      io_perf_perfEventsBackend_5_value <= 6'($urandom);
      io_perf_perfEventsBackend_6_value <= 6'($urandom);
      io_perf_perfEventsBackend_7_value <= 6'($urandom);
      io_perf_perfEventsLsu_0_value <= 6'($urandom);
      io_perf_perfEventsLsu_1_value <= 6'($urandom);
      io_perf_perfEventsLsu_2_value <= 6'($urandom);
      io_perf_perfEventsLsu_3_value <= 6'($urandom);
      io_perf_perfEventsLsu_4_value <= 6'($urandom);
      io_perf_perfEventsLsu_5_value <= 6'($urandom);
      io_perf_perfEventsLsu_6_value <= 6'($urandom);
      io_perf_perfEventsLsu_7_value <= 6'($urandom);
      io_perf_perfEventsHc_0_value <= 6'($urandom);
      io_perf_perfEventsHc_1_value <= 6'($urandom);
      io_perf_perfEventsHc_2_value <= 6'($urandom);
      io_perf_perfEventsHc_3_value <= 6'($urandom);
      io_perf_perfEventsHc_4_value <= 6'($urandom);
      io_perf_perfEventsHc_5_value <= 6'($urandom);
      io_perf_perfEventsHc_6_value <= 6'($urandom);
      io_perf_perfEventsHc_7_value <= 6'($urandom);
      io_perf_perfEventsHc_8_value <= 6'($urandom);
      io_perf_perfEventsHc_9_value <= 6'($urandom);
      io_perf_perfEventsHc_10_value <= 6'($urandom);
      io_perf_perfEventsHc_11_value <= 6'($urandom);
      io_perf_perfEventsHc_12_value <= 6'($urandom);
      io_perf_perfEventsHc_13_value <= 6'($urandom);
      io_perf_perfEventsHc_14_value <= 6'($urandom);
      io_perf_perfEventsHc_15_value <= 6'($urandom);
      io_perf_perfEventsHc_16_value <= 6'($urandom);
      io_perf_perfEventsHc_17_value <= 6'($urandom);
      io_perf_perfEventsHc_18_value <= 6'($urandom);
      io_perf_perfEventsHc_19_value <= 6'($urandom);
      io_perf_perfEventsHc_20_value <= 6'($urandom);
      io_perf_perfEventsHc_21_value <= 6'($urandom);
      io_perf_perfEventsHc_22_value <= 6'($urandom);
      io_perf_perfEventsHc_23_value <= 6'($urandom);
      io_perf_perfEventsHc_24_value <= 6'($urandom);
      io_perf_perfEventsHc_25_value <= 6'($urandom);
      io_perf_perfEventsHc_26_value <= 6'($urandom);
      io_perf_perfEventsHc_27_value <= 6'($urandom);
      io_perf_perfEventsHc_28_value <= 6'($urandom);
      io_perf_perfEventsHc_29_value <= 6'($urandom);
      io_perf_perfEventsHc_30_value <= 6'($urandom);
      io_perf_perfEventsHc_31_value <= 6'($urandom);
      io_perf_perfEventsHc_32_value <= 6'($urandom);
      io_perf_perfEventsHc_33_value <= 6'($urandom);
      io_perf_perfEventsHc_34_value <= 6'($urandom);
      io_perf_perfEventsHc_35_value <= 6'($urandom);
      io_perf_perfEventsHc_36_value <= 6'($urandom);
      io_perf_perfEventsHc_37_value <= 6'($urandom);
      io_perf_perfEventsHc_38_value <= 6'($urandom);
      io_perf_perfEventsHc_39_value <= 6'($urandom);
      io_perf_perfEventsHc_40_value <= 6'($urandom);
      io_perf_perfEventsHc_41_value <= 6'($urandom);
      io_perf_perfEventsHc_42_value <= 6'($urandom);
      io_perf_perfEventsHc_43_value <= 6'($urandom);
      io_perf_perfEventsHc_44_value <= 6'($urandom);
      io_perf_perfEventsHc_45_value <= 6'($urandom);
      io_perf_perfEventsHc_46_value <= 6'($urandom);
      io_perf_perfEventsHc_47_value <= 6'($urandom);
      io_out_ready <= $urandom_range(0,1);
      io_fetchMalTval <= 64'({$urandom(), $urandom()});
      fromAIA_rdata_valid <= $urandom_range(0,1);
      fromAIA_rdata_bits_data <= 64'({$urandom(), $urandom()});
      fromAIA_rdata_bits_illegal <= $urandom_range(0,1);
      fromAIA_meip <= $urandom_range(0,1);
      fromAIA_seip <= $urandom_range(0,1);
      fromAIA_vseip <= 5'($urandom);
      fromAIA_mtopei_IID <= 11'($urandom);
      fromAIA_mtopei_IPRIO <= 11'($urandom);
      fromAIA_stopei_IID <= 11'($urandom);
      fromAIA_stopei_IPRIO <= 11'($urandom);
      fromAIA_vstopei_IID <= 11'($urandom);
      fromAIA_vstopei_IPRIO <= 11'($urandom);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_in_ready) && g_io_in_ready !== i_io_in_ready) begin errors++;
      if(errors<=80) $display("[%0t] io_in_ready g=%h i=%h", $time, g_io_in_ready, i_io_in_ready); end
    if (!$isunknown(g_io_out_valid) && g_io_out_valid !== i_io_out_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_out_valid g=%h i=%h", $time, g_io_out_valid, i_io_out_valid); end
    if (!$isunknown(g_io_out_bits_EX_II) && g_io_out_bits_EX_II !== i_io_out_bits_EX_II) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_EX_II g=%h i=%h", $time, g_io_out_bits_EX_II, i_io_out_bits_EX_II); end
    if (!$isunknown(g_io_out_bits_EX_VI) && g_io_out_bits_EX_VI !== i_io_out_bits_EX_VI) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_EX_VI g=%h i=%h", $time, g_io_out_bits_EX_VI, i_io_out_bits_EX_VI); end
    if (!$isunknown(g_io_out_bits_flushPipe) && g_io_out_bits_flushPipe !== i_io_out_bits_flushPipe) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_flushPipe g=%h i=%h", $time, g_io_out_bits_flushPipe, i_io_out_bits_flushPipe); end
    if (!$isunknown(g_io_out_bits_rData) && g_io_out_bits_rData !== i_io_out_bits_rData) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_rData g=%h i=%h", $time, g_io_out_bits_rData, i_io_out_bits_rData); end
    if (!$isunknown(g_io_out_bits_targetPcUpdate) && g_io_out_bits_targetPcUpdate !== i_io_out_bits_targetPcUpdate) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_targetPcUpdate g=%h i=%h", $time, g_io_out_bits_targetPcUpdate, i_io_out_bits_targetPcUpdate); end
    if (!$isunknown(g_io_out_bits_targetPc_pc) && g_io_out_bits_targetPc_pc !== i_io_out_bits_targetPc_pc) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_targetPc_pc g=%h i=%h", $time, g_io_out_bits_targetPc_pc, i_io_out_bits_targetPc_pc); end
    if (!$isunknown(g_io_out_bits_targetPc_raiseIPF) && g_io_out_bits_targetPc_raiseIPF !== i_io_out_bits_targetPc_raiseIPF) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_targetPc_raiseIPF g=%h i=%h", $time, g_io_out_bits_targetPc_raiseIPF, i_io_out_bits_targetPc_raiseIPF); end
    if (!$isunknown(g_io_out_bits_targetPc_raiseIAF) && g_io_out_bits_targetPc_raiseIAF !== i_io_out_bits_targetPc_raiseIAF) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_targetPc_raiseIAF g=%h i=%h", $time, g_io_out_bits_targetPc_raiseIAF, i_io_out_bits_targetPc_raiseIAF); end
    if (!$isunknown(g_io_out_bits_targetPc_raiseIGPF) && g_io_out_bits_targetPc_raiseIGPF !== i_io_out_bits_targetPc_raiseIGPF) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_targetPc_raiseIGPF g=%h i=%h", $time, g_io_out_bits_targetPc_raiseIGPF, i_io_out_bits_targetPc_raiseIGPF); end
    if (!$isunknown(g_io_out_bits_regOut) && g_io_out_bits_regOut !== i_io_out_bits_regOut) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_regOut g=%h i=%h", $time, g_io_out_bits_regOut, i_io_out_bits_regOut); end
    if (!$isunknown(g_io_out_bits_isPerfCnt) && g_io_out_bits_isPerfCnt !== i_io_out_bits_isPerfCnt) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_isPerfCnt g=%h i=%h", $time, g_io_out_bits_isPerfCnt, i_io_out_bits_isPerfCnt); end
    if (!$isunknown(g_io_status_privState_PRVM) && g_io_status_privState_PRVM !== i_io_status_privState_PRVM) begin errors++;
      if(errors<=80) $display("[%0t] io_status_privState_PRVM g=%h i=%h", $time, g_io_status_privState_PRVM, i_io_status_privState_PRVM); end
    if (!$isunknown(g_io_status_privState_V) && g_io_status_privState_V !== i_io_status_privState_V) begin errors++;
      if(errors<=80) $display("[%0t] io_status_privState_V g=%h i=%h", $time, g_io_status_privState_V, i_io_status_privState_V); end
    if (!$isunknown(g_io_status_interrupt) && g_io_status_interrupt !== i_io_status_interrupt) begin errors++;
      if(errors<=80) $display("[%0t] io_status_interrupt g=%h i=%h", $time, g_io_status_interrupt, i_io_status_interrupt); end
    if (!$isunknown(g_io_status_wfiEvent) && g_io_status_wfiEvent !== i_io_status_wfiEvent) begin errors++;
      if(errors<=80) $display("[%0t] io_status_wfiEvent g=%h i=%h", $time, g_io_status_wfiEvent, i_io_status_wfiEvent); end
    if (!$isunknown(g_io_status_fpState_frm) && g_io_status_fpState_frm !== i_io_status_fpState_frm) begin errors++;
      if(errors<=80) $display("[%0t] io_status_fpState_frm g=%h i=%h", $time, g_io_status_fpState_frm, i_io_status_fpState_frm); end
    if (!$isunknown(g_io_status_vecState_vstart) && g_io_status_vecState_vstart !== i_io_status_vecState_vstart) begin errors++;
      if(errors<=80) $display("[%0t] io_status_vecState_vstart g=%h i=%h", $time, g_io_status_vecState_vstart, i_io_status_vecState_vstart); end
    if (!$isunknown(g_io_status_vecState_vxrm) && g_io_status_vecState_vxrm !== i_io_status_vecState_vxrm) begin errors++;
      if(errors<=80) $display("[%0t] io_status_vecState_vxrm g=%h i=%h", $time, g_io_status_vecState_vxrm, i_io_status_vecState_vxrm); end
    if (!$isunknown(g_io_status_singleStepFlag) && g_io_status_singleStepFlag !== i_io_status_singleStepFlag) begin errors++;
      if(errors<=80) $display("[%0t] io_status_singleStepFlag g=%h i=%h", $time, g_io_status_singleStepFlag, i_io_status_singleStepFlag); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_valid) && g_io_status_frontendTrigger_tUpdate_valid !== i_io_status_frontendTrigger_tUpdate_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_valid g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_valid, i_io_status_frontendTrigger_tUpdate_valid); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_addr) && g_io_status_frontendTrigger_tUpdate_bits_addr !== i_io_status_frontendTrigger_tUpdate_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_addr g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_addr, i_io_status_frontendTrigger_tUpdate_bits_addr); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_tdata_matchType) && g_io_status_frontendTrigger_tUpdate_bits_tdata_matchType !== i_io_status_frontendTrigger_tUpdate_bits_tdata_matchType) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_tdata_matchType g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_tdata_matchType, i_io_status_frontendTrigger_tUpdate_bits_tdata_matchType); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_tdata_select) && g_io_status_frontendTrigger_tUpdate_bits_tdata_select !== i_io_status_frontendTrigger_tUpdate_bits_tdata_select) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_tdata_select g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_tdata_select, i_io_status_frontendTrigger_tUpdate_bits_tdata_select); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_tdata_action) && g_io_status_frontendTrigger_tUpdate_bits_tdata_action !== i_io_status_frontendTrigger_tUpdate_bits_tdata_action) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_tdata_action g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_tdata_action, i_io_status_frontendTrigger_tUpdate_bits_tdata_action); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_tdata_chain) && g_io_status_frontendTrigger_tUpdate_bits_tdata_chain !== i_io_status_frontendTrigger_tUpdate_bits_tdata_chain) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_tdata_chain g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_tdata_chain, i_io_status_frontendTrigger_tUpdate_bits_tdata_chain); end
    if (!$isunknown(g_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2) && g_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2 !== i_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tUpdate_bits_tdata_tdata2 g=%h i=%h", $time, g_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2, i_io_status_frontendTrigger_tUpdate_bits_tdata_tdata2); end
    if (!$isunknown(g_io_status_frontendTrigger_tEnableVec_0) && g_io_status_frontendTrigger_tEnableVec_0 !== i_io_status_frontendTrigger_tEnableVec_0) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tEnableVec_0 g=%h i=%h", $time, g_io_status_frontendTrigger_tEnableVec_0, i_io_status_frontendTrigger_tEnableVec_0); end
    if (!$isunknown(g_io_status_frontendTrigger_tEnableVec_1) && g_io_status_frontendTrigger_tEnableVec_1 !== i_io_status_frontendTrigger_tEnableVec_1) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tEnableVec_1 g=%h i=%h", $time, g_io_status_frontendTrigger_tEnableVec_1, i_io_status_frontendTrigger_tEnableVec_1); end
    if (!$isunknown(g_io_status_frontendTrigger_tEnableVec_2) && g_io_status_frontendTrigger_tEnableVec_2 !== i_io_status_frontendTrigger_tEnableVec_2) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tEnableVec_2 g=%h i=%h", $time, g_io_status_frontendTrigger_tEnableVec_2, i_io_status_frontendTrigger_tEnableVec_2); end
    if (!$isunknown(g_io_status_frontendTrigger_tEnableVec_3) && g_io_status_frontendTrigger_tEnableVec_3 !== i_io_status_frontendTrigger_tEnableVec_3) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_tEnableVec_3 g=%h i=%h", $time, g_io_status_frontendTrigger_tEnableVec_3, i_io_status_frontendTrigger_tEnableVec_3); end
    if (!$isunknown(g_io_status_frontendTrigger_debugMode) && g_io_status_frontendTrigger_debugMode !== i_io_status_frontendTrigger_debugMode) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_debugMode g=%h i=%h", $time, g_io_status_frontendTrigger_debugMode, i_io_status_frontendTrigger_debugMode); end
    if (!$isunknown(g_io_status_frontendTrigger_triggerCanRaiseBpExp) && g_io_status_frontendTrigger_triggerCanRaiseBpExp !== i_io_status_frontendTrigger_triggerCanRaiseBpExp) begin errors++;
      if(errors<=80) $display("[%0t] io_status_frontendTrigger_triggerCanRaiseBpExp g=%h i=%h", $time, g_io_status_frontendTrigger_triggerCanRaiseBpExp, i_io_status_frontendTrigger_triggerCanRaiseBpExp); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_valid) && g_io_status_memTrigger_tUpdate_valid !== i_io_status_memTrigger_tUpdate_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_valid g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_valid, i_io_status_memTrigger_tUpdate_valid); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_addr) && g_io_status_memTrigger_tUpdate_bits_addr !== i_io_status_memTrigger_tUpdate_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_addr g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_addr, i_io_status_memTrigger_tUpdate_bits_addr); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_matchType) && g_io_status_memTrigger_tUpdate_bits_tdata_matchType !== i_io_status_memTrigger_tUpdate_bits_tdata_matchType) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_matchType g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_matchType, i_io_status_memTrigger_tUpdate_bits_tdata_matchType); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_select) && g_io_status_memTrigger_tUpdate_bits_tdata_select !== i_io_status_memTrigger_tUpdate_bits_tdata_select) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_select g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_select, i_io_status_memTrigger_tUpdate_bits_tdata_select); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_action) && g_io_status_memTrigger_tUpdate_bits_tdata_action !== i_io_status_memTrigger_tUpdate_bits_tdata_action) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_action g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_action, i_io_status_memTrigger_tUpdate_bits_tdata_action); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_chain) && g_io_status_memTrigger_tUpdate_bits_tdata_chain !== i_io_status_memTrigger_tUpdate_bits_tdata_chain) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_chain g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_chain, i_io_status_memTrigger_tUpdate_bits_tdata_chain); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_store) && g_io_status_memTrigger_tUpdate_bits_tdata_store !== i_io_status_memTrigger_tUpdate_bits_tdata_store) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_store g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_store, i_io_status_memTrigger_tUpdate_bits_tdata_store); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_load) && g_io_status_memTrigger_tUpdate_bits_tdata_load !== i_io_status_memTrigger_tUpdate_bits_tdata_load) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_load g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_load, i_io_status_memTrigger_tUpdate_bits_tdata_load); end
    if (!$isunknown(g_io_status_memTrigger_tUpdate_bits_tdata_tdata2) && g_io_status_memTrigger_tUpdate_bits_tdata_tdata2 !== i_io_status_memTrigger_tUpdate_bits_tdata_tdata2) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tUpdate_bits_tdata_tdata2 g=%h i=%h", $time, g_io_status_memTrigger_tUpdate_bits_tdata_tdata2, i_io_status_memTrigger_tUpdate_bits_tdata_tdata2); end
    if (!$isunknown(g_io_status_memTrigger_tEnableVec_0) && g_io_status_memTrigger_tEnableVec_0 !== i_io_status_memTrigger_tEnableVec_0) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tEnableVec_0 g=%h i=%h", $time, g_io_status_memTrigger_tEnableVec_0, i_io_status_memTrigger_tEnableVec_0); end
    if (!$isunknown(g_io_status_memTrigger_tEnableVec_1) && g_io_status_memTrigger_tEnableVec_1 !== i_io_status_memTrigger_tEnableVec_1) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tEnableVec_1 g=%h i=%h", $time, g_io_status_memTrigger_tEnableVec_1, i_io_status_memTrigger_tEnableVec_1); end
    if (!$isunknown(g_io_status_memTrigger_tEnableVec_2) && g_io_status_memTrigger_tEnableVec_2 !== i_io_status_memTrigger_tEnableVec_2) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tEnableVec_2 g=%h i=%h", $time, g_io_status_memTrigger_tEnableVec_2, i_io_status_memTrigger_tEnableVec_2); end
    if (!$isunknown(g_io_status_memTrigger_tEnableVec_3) && g_io_status_memTrigger_tEnableVec_3 !== i_io_status_memTrigger_tEnableVec_3) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_tEnableVec_3 g=%h i=%h", $time, g_io_status_memTrigger_tEnableVec_3, i_io_status_memTrigger_tEnableVec_3); end
    if (!$isunknown(g_io_status_memTrigger_debugMode) && g_io_status_memTrigger_debugMode !== i_io_status_memTrigger_debugMode) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_debugMode g=%h i=%h", $time, g_io_status_memTrigger_debugMode, i_io_status_memTrigger_debugMode); end
    if (!$isunknown(g_io_status_memTrigger_triggerCanRaiseBpExp) && g_io_status_memTrigger_triggerCanRaiseBpExp !== i_io_status_memTrigger_triggerCanRaiseBpExp) begin errors++;
      if(errors<=80) $display("[%0t] io_status_memTrigger_triggerCanRaiseBpExp g=%h i=%h", $time, g_io_status_memTrigger_triggerCanRaiseBpExp, i_io_status_memTrigger_triggerCanRaiseBpExp); end
    if (!$isunknown(g_io_status_instrAddrTransType_bare) && g_io_status_instrAddrTransType_bare !== i_io_status_instrAddrTransType_bare) begin errors++;
      if(errors<=80) $display("[%0t] io_status_instrAddrTransType_bare g=%h i=%h", $time, g_io_status_instrAddrTransType_bare, i_io_status_instrAddrTransType_bare); end
    if (!$isunknown(g_io_status_instrAddrTransType_sv39) && g_io_status_instrAddrTransType_sv39 !== i_io_status_instrAddrTransType_sv39) begin errors++;
      if(errors<=80) $display("[%0t] io_status_instrAddrTransType_sv39 g=%h i=%h", $time, g_io_status_instrAddrTransType_sv39, i_io_status_instrAddrTransType_sv39); end
    if (!$isunknown(g_io_status_instrAddrTransType_sv39x4) && g_io_status_instrAddrTransType_sv39x4 !== i_io_status_instrAddrTransType_sv39x4) begin errors++;
      if(errors<=80) $display("[%0t] io_status_instrAddrTransType_sv39x4 g=%h i=%h", $time, g_io_status_instrAddrTransType_sv39x4, i_io_status_instrAddrTransType_sv39x4); end
    if (!$isunknown(g_io_status_instrAddrTransType_sv48) && g_io_status_instrAddrTransType_sv48 !== i_io_status_instrAddrTransType_sv48) begin errors++;
      if(errors<=80) $display("[%0t] io_status_instrAddrTransType_sv48 g=%h i=%h", $time, g_io_status_instrAddrTransType_sv48, i_io_status_instrAddrTransType_sv48); end
    if (!$isunknown(g_io_status_instrAddrTransType_sv48x4) && g_io_status_instrAddrTransType_sv48x4 !== i_io_status_instrAddrTransType_sv48x4) begin errors++;
      if(errors<=80) $display("[%0t] io_status_instrAddrTransType_sv48x4 g=%h i=%h", $time, g_io_status_instrAddrTransType_sv48x4, i_io_status_instrAddrTransType_sv48x4); end
    if (!$isunknown(g_io_status_traceCSR_cause) && g_io_status_traceCSR_cause !== i_io_status_traceCSR_cause) begin errors++;
      if(errors<=80) $display("[%0t] io_status_traceCSR_cause g=%h i=%h", $time, g_io_status_traceCSR_cause, i_io_status_traceCSR_cause); end
    if (!$isunknown(g_io_status_traceCSR_tval) && g_io_status_traceCSR_tval !== i_io_status_traceCSR_tval) begin errors++;
      if(errors<=80) $display("[%0t] io_status_traceCSR_tval g=%h i=%h", $time, g_io_status_traceCSR_tval, i_io_status_traceCSR_tval); end
    if (!$isunknown(g_io_status_traceCSR_lastPriv) && g_io_status_traceCSR_lastPriv !== i_io_status_traceCSR_lastPriv) begin errors++;
      if(errors<=80) $display("[%0t] io_status_traceCSR_lastPriv g=%h i=%h", $time, g_io_status_traceCSR_lastPriv, i_io_status_traceCSR_lastPriv); end
    if (!$isunknown(g_io_status_traceCSR_currentPriv) && g_io_status_traceCSR_currentPriv !== i_io_status_traceCSR_currentPriv) begin errors++;
      if(errors<=80) $display("[%0t] io_status_traceCSR_currentPriv g=%h i=%h", $time, g_io_status_traceCSR_currentPriv, i_io_status_traceCSR_currentPriv); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1I_pf_enable) && g_io_status_custom_pf_ctrl_l1I_pf_enable !== i_io_status_custom_pf_ctrl_l1I_pf_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1I_pf_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1I_pf_enable, i_io_status_custom_pf_ctrl_l1I_pf_enable); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l2_pf_enable) && g_io_status_custom_pf_ctrl_l2_pf_enable !== i_io_status_custom_pf_ctrl_l2_pf_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l2_pf_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l2_pf_enable, i_io_status_custom_pf_ctrl_l2_pf_enable); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_enable) && g_io_status_custom_pf_ctrl_l1D_pf_enable !== i_io_status_custom_pf_ctrl_l1D_pf_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_enable, i_io_status_custom_pf_ctrl_l1D_pf_enable); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_train_on_hit) && g_io_status_custom_pf_ctrl_l1D_pf_train_on_hit !== i_io_status_custom_pf_ctrl_l1D_pf_train_on_hit) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_train_on_hit g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_train_on_hit, i_io_status_custom_pf_ctrl_l1D_pf_train_on_hit); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_enable_agt) && g_io_status_custom_pf_ctrl_l1D_pf_enable_agt !== i_io_status_custom_pf_ctrl_l1D_pf_enable_agt) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_enable_agt g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_enable_agt, i_io_status_custom_pf_ctrl_l1D_pf_enable_agt); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_enable_pht) && g_io_status_custom_pf_ctrl_l1D_pf_enable_pht !== i_io_status_custom_pf_ctrl_l1D_pf_enable_pht) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_enable_pht g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_enable_pht, i_io_status_custom_pf_ctrl_l1D_pf_enable_pht); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_active_threshold) && g_io_status_custom_pf_ctrl_l1D_pf_active_threshold !== i_io_status_custom_pf_ctrl_l1D_pf_active_threshold) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_active_threshold g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_active_threshold, i_io_status_custom_pf_ctrl_l1D_pf_active_threshold); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_active_stride) && g_io_status_custom_pf_ctrl_l1D_pf_active_stride !== i_io_status_custom_pf_ctrl_l1D_pf_active_stride) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_active_stride g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_active_stride, i_io_status_custom_pf_ctrl_l1D_pf_active_stride); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l1D_pf_enable_stride) && g_io_status_custom_pf_ctrl_l1D_pf_enable_stride !== i_io_status_custom_pf_ctrl_l1D_pf_enable_stride) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l1D_pf_enable_stride g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l1D_pf_enable_stride, i_io_status_custom_pf_ctrl_l1D_pf_enable_stride); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l2_pf_store_only) && g_io_status_custom_pf_ctrl_l2_pf_store_only !== i_io_status_custom_pf_ctrl_l2_pf_store_only) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l2_pf_store_only g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l2_pf_store_only, i_io_status_custom_pf_ctrl_l2_pf_store_only); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l2_pf_recv_enable) && g_io_status_custom_pf_ctrl_l2_pf_recv_enable !== i_io_status_custom_pf_ctrl_l2_pf_recv_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l2_pf_recv_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l2_pf_recv_enable, i_io_status_custom_pf_ctrl_l2_pf_recv_enable); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l2_pf_pbop_enable) && g_io_status_custom_pf_ctrl_l2_pf_pbop_enable !== i_io_status_custom_pf_ctrl_l2_pf_pbop_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l2_pf_pbop_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l2_pf_pbop_enable, i_io_status_custom_pf_ctrl_l2_pf_pbop_enable); end
    if (!$isunknown(g_io_status_custom_pf_ctrl_l2_pf_vbop_enable) && g_io_status_custom_pf_ctrl_l2_pf_vbop_enable !== i_io_status_custom_pf_ctrl_l2_pf_vbop_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_pf_ctrl_l2_pf_vbop_enable g=%h i=%h", $time, g_io_status_custom_pf_ctrl_l2_pf_vbop_enable, i_io_status_custom_pf_ctrl_l2_pf_vbop_enable); end
    if (!$isunknown(g_io_status_custom_lvpred_timeout) && g_io_status_custom_lvpred_timeout !== i_io_status_custom_lvpred_timeout) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_lvpred_timeout g=%h i=%h", $time, g_io_status_custom_lvpred_timeout, i_io_status_custom_lvpred_timeout); end
    if (!$isunknown(g_io_status_custom_bp_ctrl_ubtb_enable) && g_io_status_custom_bp_ctrl_ubtb_enable !== i_io_status_custom_bp_ctrl_ubtb_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_bp_ctrl_ubtb_enable g=%h i=%h", $time, g_io_status_custom_bp_ctrl_ubtb_enable, i_io_status_custom_bp_ctrl_ubtb_enable); end
    if (!$isunknown(g_io_status_custom_bp_ctrl_btb_enable) && g_io_status_custom_bp_ctrl_btb_enable !== i_io_status_custom_bp_ctrl_btb_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_bp_ctrl_btb_enable g=%h i=%h", $time, g_io_status_custom_bp_ctrl_btb_enable, i_io_status_custom_bp_ctrl_btb_enable); end
    if (!$isunknown(g_io_status_custom_bp_ctrl_tage_enable) && g_io_status_custom_bp_ctrl_tage_enable !== i_io_status_custom_bp_ctrl_tage_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_bp_ctrl_tage_enable g=%h i=%h", $time, g_io_status_custom_bp_ctrl_tage_enable, i_io_status_custom_bp_ctrl_tage_enable); end
    if (!$isunknown(g_io_status_custom_bp_ctrl_sc_enable) && g_io_status_custom_bp_ctrl_sc_enable !== i_io_status_custom_bp_ctrl_sc_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_bp_ctrl_sc_enable g=%h i=%h", $time, g_io_status_custom_bp_ctrl_sc_enable, i_io_status_custom_bp_ctrl_sc_enable); end
    if (!$isunknown(g_io_status_custom_bp_ctrl_ras_enable) && g_io_status_custom_bp_ctrl_ras_enable !== i_io_status_custom_bp_ctrl_ras_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_bp_ctrl_ras_enable g=%h i=%h", $time, g_io_status_custom_bp_ctrl_ras_enable, i_io_status_custom_bp_ctrl_ras_enable); end
    if (!$isunknown(g_io_status_custom_ldld_vio_check_enable) && g_io_status_custom_ldld_vio_check_enable !== i_io_status_custom_ldld_vio_check_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_ldld_vio_check_enable g=%h i=%h", $time, g_io_status_custom_ldld_vio_check_enable, i_io_status_custom_ldld_vio_check_enable); end
    if (!$isunknown(g_io_status_custom_cache_error_enable) && g_io_status_custom_cache_error_enable !== i_io_status_custom_cache_error_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_cache_error_enable g=%h i=%h", $time, g_io_status_custom_cache_error_enable, i_io_status_custom_cache_error_enable); end
    if (!$isunknown(g_io_status_custom_uncache_write_outstanding_enable) && g_io_status_custom_uncache_write_outstanding_enable !== i_io_status_custom_uncache_write_outstanding_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_uncache_write_outstanding_enable g=%h i=%h", $time, g_io_status_custom_uncache_write_outstanding_enable, i_io_status_custom_uncache_write_outstanding_enable); end
    if (!$isunknown(g_io_status_custom_hd_misalign_st_enable) && g_io_status_custom_hd_misalign_st_enable !== i_io_status_custom_hd_misalign_st_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_hd_misalign_st_enable g=%h i=%h", $time, g_io_status_custom_hd_misalign_st_enable, i_io_status_custom_hd_misalign_st_enable); end
    if (!$isunknown(g_io_status_custom_hd_misalign_ld_enable) && g_io_status_custom_hd_misalign_ld_enable !== i_io_status_custom_hd_misalign_ld_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_hd_misalign_ld_enable g=%h i=%h", $time, g_io_status_custom_hd_misalign_ld_enable, i_io_status_custom_hd_misalign_ld_enable); end
    if (!$isunknown(g_io_status_custom_power_down_enable) && g_io_status_custom_power_down_enable !== i_io_status_custom_power_down_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_power_down_enable g=%h i=%h", $time, g_io_status_custom_power_down_enable, i_io_status_custom_power_down_enable); end
    if (!$isunknown(g_io_status_custom_flush_l2_enable) && g_io_status_custom_flush_l2_enable !== i_io_status_custom_flush_l2_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_flush_l2_enable g=%h i=%h", $time, g_io_status_custom_flush_l2_enable, i_io_status_custom_flush_l2_enable); end
    if (!$isunknown(g_io_status_custom_fusion_enable) && g_io_status_custom_fusion_enable !== i_io_status_custom_fusion_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_fusion_enable g=%h i=%h", $time, g_io_status_custom_fusion_enable, i_io_status_custom_fusion_enable); end
    if (!$isunknown(g_io_status_custom_wfi_enable) && g_io_status_custom_wfi_enable !== i_io_status_custom_wfi_enable) begin errors++;
      if(errors<=80) $display("[%0t] io_status_custom_wfi_enable g=%h i=%h", $time, g_io_status_custom_wfi_enable, i_io_status_custom_wfi_enable); end
    if (!$isunknown(g_io_status_criticalErrorState) && g_io_status_criticalErrorState !== i_io_status_criticalErrorState) begin errors++;
      if(errors<=80) $display("[%0t] io_status_criticalErrorState g=%h i=%h", $time, g_io_status_criticalErrorState, i_io_status_criticalErrorState); end
    if (!$isunknown(g_io_tlb_satpASIDChanged) && g_io_tlb_satpASIDChanged !== i_io_tlb_satpASIDChanged) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_satpASIDChanged g=%h i=%h", $time, g_io_tlb_satpASIDChanged, i_io_tlb_satpASIDChanged); end
    if (!$isunknown(g_io_tlb_vsatpASIDChanged) && g_io_tlb_vsatpASIDChanged !== i_io_tlb_vsatpASIDChanged) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vsatpASIDChanged g=%h i=%h", $time, g_io_tlb_vsatpASIDChanged, i_io_tlb_vsatpASIDChanged); end
    if (!$isunknown(g_io_tlb_hgatpVMIDChanged) && g_io_tlb_hgatpVMIDChanged !== i_io_tlb_hgatpVMIDChanged) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_hgatpVMIDChanged g=%h i=%h", $time, g_io_tlb_hgatpVMIDChanged, i_io_tlb_hgatpVMIDChanged); end
    if (!$isunknown(g_io_tlb_satp_MODE) && g_io_tlb_satp_MODE !== i_io_tlb_satp_MODE) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_satp_MODE g=%h i=%h", $time, g_io_tlb_satp_MODE, i_io_tlb_satp_MODE); end
    if (!$isunknown(g_io_tlb_satp_ASID) && g_io_tlb_satp_ASID !== i_io_tlb_satp_ASID) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_satp_ASID g=%h i=%h", $time, g_io_tlb_satp_ASID, i_io_tlb_satp_ASID); end
    if (!$isunknown(g_io_tlb_satp_PPN) && g_io_tlb_satp_PPN !== i_io_tlb_satp_PPN) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_satp_PPN g=%h i=%h", $time, g_io_tlb_satp_PPN, i_io_tlb_satp_PPN); end
    if (!$isunknown(g_io_tlb_vsatp_MODE) && g_io_tlb_vsatp_MODE !== i_io_tlb_vsatp_MODE) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vsatp_MODE g=%h i=%h", $time, g_io_tlb_vsatp_MODE, i_io_tlb_vsatp_MODE); end
    if (!$isunknown(g_io_tlb_vsatp_ASID) && g_io_tlb_vsatp_ASID !== i_io_tlb_vsatp_ASID) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vsatp_ASID g=%h i=%h", $time, g_io_tlb_vsatp_ASID, i_io_tlb_vsatp_ASID); end
    if (!$isunknown(g_io_tlb_vsatp_PPN) && g_io_tlb_vsatp_PPN !== i_io_tlb_vsatp_PPN) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vsatp_PPN g=%h i=%h", $time, g_io_tlb_vsatp_PPN, i_io_tlb_vsatp_PPN); end
    if (!$isunknown(g_io_tlb_hgatp_MODE) && g_io_tlb_hgatp_MODE !== i_io_tlb_hgatp_MODE) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_hgatp_MODE g=%h i=%h", $time, g_io_tlb_hgatp_MODE, i_io_tlb_hgatp_MODE); end
    if (!$isunknown(g_io_tlb_hgatp_VMID) && g_io_tlb_hgatp_VMID !== i_io_tlb_hgatp_VMID) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_hgatp_VMID g=%h i=%h", $time, g_io_tlb_hgatp_VMID, i_io_tlb_hgatp_VMID); end
    if (!$isunknown(g_io_tlb_hgatp_PPN) && g_io_tlb_hgatp_PPN !== i_io_tlb_hgatp_PPN) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_hgatp_PPN g=%h i=%h", $time, g_io_tlb_hgatp_PPN, i_io_tlb_hgatp_PPN); end
    if (!$isunknown(g_io_tlb_mxr) && g_io_tlb_mxr !== i_io_tlb_mxr) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_mxr g=%h i=%h", $time, g_io_tlb_mxr, i_io_tlb_mxr); end
    if (!$isunknown(g_io_tlb_sum) && g_io_tlb_sum !== i_io_tlb_sum) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_sum g=%h i=%h", $time, g_io_tlb_sum, i_io_tlb_sum); end
    if (!$isunknown(g_io_tlb_vmxr) && g_io_tlb_vmxr !== i_io_tlb_vmxr) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vmxr g=%h i=%h", $time, g_io_tlb_vmxr, i_io_tlb_vmxr); end
    if (!$isunknown(g_io_tlb_vsum) && g_io_tlb_vsum !== i_io_tlb_vsum) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_vsum g=%h i=%h", $time, g_io_tlb_vsum, i_io_tlb_vsum); end
    if (!$isunknown(g_io_tlb_spvp) && g_io_tlb_spvp !== i_io_tlb_spvp) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_spvp g=%h i=%h", $time, g_io_tlb_spvp, i_io_tlb_spvp); end
    if (!$isunknown(g_io_tlb_imode) && g_io_tlb_imode !== i_io_tlb_imode) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_imode g=%h i=%h", $time, g_io_tlb_imode, i_io_tlb_imode); end
    if (!$isunknown(g_io_tlb_dmode) && g_io_tlb_dmode !== i_io_tlb_dmode) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_dmode g=%h i=%h", $time, g_io_tlb_dmode, i_io_tlb_dmode); end
    if (!$isunknown(g_io_tlb_dvirt) && g_io_tlb_dvirt !== i_io_tlb_dvirt) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_dvirt g=%h i=%h", $time, g_io_tlb_dvirt, i_io_tlb_dvirt); end
    if (!$isunknown(g_io_tlb_mPBMTE) && g_io_tlb_mPBMTE !== i_io_tlb_mPBMTE) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_mPBMTE g=%h i=%h", $time, g_io_tlb_mPBMTE, i_io_tlb_mPBMTE); end
    if (!$isunknown(g_io_tlb_hPBMTE) && g_io_tlb_hPBMTE !== i_io_tlb_hPBMTE) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_hPBMTE g=%h i=%h", $time, g_io_tlb_hPBMTE, i_io_tlb_hPBMTE); end
    if (!$isunknown(g_io_tlb_pmm_mseccfg) && g_io_tlb_pmm_mseccfg !== i_io_tlb_pmm_mseccfg) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_pmm_mseccfg g=%h i=%h", $time, g_io_tlb_pmm_mseccfg, i_io_tlb_pmm_mseccfg); end
    if (!$isunknown(g_io_tlb_pmm_menvcfg) && g_io_tlb_pmm_menvcfg !== i_io_tlb_pmm_menvcfg) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_pmm_menvcfg g=%h i=%h", $time, g_io_tlb_pmm_menvcfg, i_io_tlb_pmm_menvcfg); end
    if (!$isunknown(g_io_tlb_pmm_henvcfg) && g_io_tlb_pmm_henvcfg !== i_io_tlb_pmm_henvcfg) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_pmm_henvcfg g=%h i=%h", $time, g_io_tlb_pmm_henvcfg, i_io_tlb_pmm_henvcfg); end
    if (!$isunknown(g_io_tlb_pmm_hstatus) && g_io_tlb_pmm_hstatus !== i_io_tlb_pmm_hstatus) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_pmm_hstatus g=%h i=%h", $time, g_io_tlb_pmm_hstatus, i_io_tlb_pmm_hstatus); end
    if (!$isunknown(g_io_tlb_pmm_senvcfg) && g_io_tlb_pmm_senvcfg !== i_io_tlb_pmm_senvcfg) begin errors++;
      if(errors<=80) $display("[%0t] io_tlb_pmm_senvcfg g=%h i=%h", $time, g_io_tlb_pmm_senvcfg, i_io_tlb_pmm_senvcfg); end
    if (!$isunknown(g_io_toDecode_illegalInst_sfenceVMA) && g_io_toDecode_illegalInst_sfenceVMA !== i_io_toDecode_illegalInst_sfenceVMA) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_sfenceVMA g=%h i=%h", $time, g_io_toDecode_illegalInst_sfenceVMA, i_io_toDecode_illegalInst_sfenceVMA); end
    if (!$isunknown(g_io_toDecode_illegalInst_sfencePart) && g_io_toDecode_illegalInst_sfencePart !== i_io_toDecode_illegalInst_sfencePart) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_sfencePart g=%h i=%h", $time, g_io_toDecode_illegalInst_sfencePart, i_io_toDecode_illegalInst_sfencePart); end
    if (!$isunknown(g_io_toDecode_illegalInst_hfenceGVMA) && g_io_toDecode_illegalInst_hfenceGVMA !== i_io_toDecode_illegalInst_hfenceGVMA) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_hfenceGVMA g=%h i=%h", $time, g_io_toDecode_illegalInst_hfenceGVMA, i_io_toDecode_illegalInst_hfenceGVMA); end
    if (!$isunknown(g_io_toDecode_illegalInst_hfenceVVMA) && g_io_toDecode_illegalInst_hfenceVVMA !== i_io_toDecode_illegalInst_hfenceVVMA) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_hfenceVVMA g=%h i=%h", $time, g_io_toDecode_illegalInst_hfenceVVMA, i_io_toDecode_illegalInst_hfenceVVMA); end
    if (!$isunknown(g_io_toDecode_illegalInst_hlsv) && g_io_toDecode_illegalInst_hlsv !== i_io_toDecode_illegalInst_hlsv) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_hlsv g=%h i=%h", $time, g_io_toDecode_illegalInst_hlsv, i_io_toDecode_illegalInst_hlsv); end
    if (!$isunknown(g_io_toDecode_illegalInst_fsIsOff) && g_io_toDecode_illegalInst_fsIsOff !== i_io_toDecode_illegalInst_fsIsOff) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_fsIsOff g=%h i=%h", $time, g_io_toDecode_illegalInst_fsIsOff, i_io_toDecode_illegalInst_fsIsOff); end
    if (!$isunknown(g_io_toDecode_illegalInst_vsIsOff) && g_io_toDecode_illegalInst_vsIsOff !== i_io_toDecode_illegalInst_vsIsOff) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_vsIsOff g=%h i=%h", $time, g_io_toDecode_illegalInst_vsIsOff, i_io_toDecode_illegalInst_vsIsOff); end
    if (!$isunknown(g_io_toDecode_illegalInst_wfi) && g_io_toDecode_illegalInst_wfi !== i_io_toDecode_illegalInst_wfi) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_wfi g=%h i=%h", $time, g_io_toDecode_illegalInst_wfi, i_io_toDecode_illegalInst_wfi); end
    if (!$isunknown(g_io_toDecode_illegalInst_wrs_nto) && g_io_toDecode_illegalInst_wrs_nto !== i_io_toDecode_illegalInst_wrs_nto) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_wrs_nto g=%h i=%h", $time, g_io_toDecode_illegalInst_wrs_nto, i_io_toDecode_illegalInst_wrs_nto); end
    if (!$isunknown(g_io_toDecode_illegalInst_frm) && g_io_toDecode_illegalInst_frm !== i_io_toDecode_illegalInst_frm) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_frm g=%h i=%h", $time, g_io_toDecode_illegalInst_frm, i_io_toDecode_illegalInst_frm); end
    if (!$isunknown(g_io_toDecode_illegalInst_cboZ) && g_io_toDecode_illegalInst_cboZ !== i_io_toDecode_illegalInst_cboZ) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_cboZ g=%h i=%h", $time, g_io_toDecode_illegalInst_cboZ, i_io_toDecode_illegalInst_cboZ); end
    if (!$isunknown(g_io_toDecode_illegalInst_cboCF) && g_io_toDecode_illegalInst_cboCF !== i_io_toDecode_illegalInst_cboCF) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_cboCF g=%h i=%h", $time, g_io_toDecode_illegalInst_cboCF, i_io_toDecode_illegalInst_cboCF); end
    if (!$isunknown(g_io_toDecode_illegalInst_cboI) && g_io_toDecode_illegalInst_cboI !== i_io_toDecode_illegalInst_cboI) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_illegalInst_cboI g=%h i=%h", $time, g_io_toDecode_illegalInst_cboI, i_io_toDecode_illegalInst_cboI); end
    if (!$isunknown(g_io_toDecode_virtualInst_sfenceVMA) && g_io_toDecode_virtualInst_sfenceVMA !== i_io_toDecode_virtualInst_sfenceVMA) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_sfenceVMA g=%h i=%h", $time, g_io_toDecode_virtualInst_sfenceVMA, i_io_toDecode_virtualInst_sfenceVMA); end
    if (!$isunknown(g_io_toDecode_virtualInst_sfencePart) && g_io_toDecode_virtualInst_sfencePart !== i_io_toDecode_virtualInst_sfencePart) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_sfencePart g=%h i=%h", $time, g_io_toDecode_virtualInst_sfencePart, i_io_toDecode_virtualInst_sfencePart); end
    if (!$isunknown(g_io_toDecode_virtualInst_hfence) && g_io_toDecode_virtualInst_hfence !== i_io_toDecode_virtualInst_hfence) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_hfence g=%h i=%h", $time, g_io_toDecode_virtualInst_hfence, i_io_toDecode_virtualInst_hfence); end
    if (!$isunknown(g_io_toDecode_virtualInst_hlsv) && g_io_toDecode_virtualInst_hlsv !== i_io_toDecode_virtualInst_hlsv) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_hlsv g=%h i=%h", $time, g_io_toDecode_virtualInst_hlsv, i_io_toDecode_virtualInst_hlsv); end
    if (!$isunknown(g_io_toDecode_virtualInst_wfi) && g_io_toDecode_virtualInst_wfi !== i_io_toDecode_virtualInst_wfi) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_wfi g=%h i=%h", $time, g_io_toDecode_virtualInst_wfi, i_io_toDecode_virtualInst_wfi); end
    if (!$isunknown(g_io_toDecode_virtualInst_wrs_nto) && g_io_toDecode_virtualInst_wrs_nto !== i_io_toDecode_virtualInst_wrs_nto) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_wrs_nto g=%h i=%h", $time, g_io_toDecode_virtualInst_wrs_nto, i_io_toDecode_virtualInst_wrs_nto); end
    if (!$isunknown(g_io_toDecode_virtualInst_cboZ) && g_io_toDecode_virtualInst_cboZ !== i_io_toDecode_virtualInst_cboZ) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_cboZ g=%h i=%h", $time, g_io_toDecode_virtualInst_cboZ, i_io_toDecode_virtualInst_cboZ); end
    if (!$isunknown(g_io_toDecode_virtualInst_cboCF) && g_io_toDecode_virtualInst_cboCF !== i_io_toDecode_virtualInst_cboCF) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_cboCF g=%h i=%h", $time, g_io_toDecode_virtualInst_cboCF, i_io_toDecode_virtualInst_cboCF); end
    if (!$isunknown(g_io_toDecode_virtualInst_cboI) && g_io_toDecode_virtualInst_cboI !== i_io_toDecode_virtualInst_cboI) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_virtualInst_cboI g=%h i=%h", $time, g_io_toDecode_virtualInst_cboI, i_io_toDecode_virtualInst_cboI); end
    if (!$isunknown(g_io_toDecode_special_cboI2F) && g_io_toDecode_special_cboI2F !== i_io_toDecode_special_cboI2F) begin errors++;
      if(errors<=80) $display("[%0t] io_toDecode_special_cboI2F g=%h i=%h", $time, g_io_toDecode_special_cboI2F, i_io_toDecode_special_cboI2F); end
    if (!$isunknown(g_io_distributedWenLegal) && g_io_distributedWenLegal !== i_io_distributedWenLegal) begin errors++;
      if(errors<=80) $display("[%0t] io_distributedWenLegal g=%h i=%h", $time, g_io_distributedWenLegal, i_io_distributedWenLegal); end
    if (!$isunknown(g_toAIA_addr_valid) && g_toAIA_addr_valid !== i_toAIA_addr_valid) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_addr_valid g=%h i=%h", $time, g_toAIA_addr_valid, i_toAIA_addr_valid); end
    if (!$isunknown(g_toAIA_addr_bits_addr) && g_toAIA_addr_bits_addr !== i_toAIA_addr_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_addr_bits_addr g=%h i=%h", $time, g_toAIA_addr_bits_addr, i_toAIA_addr_bits_addr); end
    if (!$isunknown(g_toAIA_addr_bits_v) && g_toAIA_addr_bits_v !== i_toAIA_addr_bits_v) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_addr_bits_v g=%h i=%h", $time, g_toAIA_addr_bits_v, i_toAIA_addr_bits_v); end
    if (!$isunknown(g_toAIA_addr_bits_prvm) && g_toAIA_addr_bits_prvm !== i_toAIA_addr_bits_prvm) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_addr_bits_prvm g=%h i=%h", $time, g_toAIA_addr_bits_prvm, i_toAIA_addr_bits_prvm); end
    if (!$isunknown(g_toAIA_vgein) && g_toAIA_vgein !== i_toAIA_vgein) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_vgein g=%h i=%h", $time, g_toAIA_vgein, i_toAIA_vgein); end
    if (!$isunknown(g_toAIA_wdata_valid) && g_toAIA_wdata_valid !== i_toAIA_wdata_valid) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_wdata_valid g=%h i=%h", $time, g_toAIA_wdata_valid, i_toAIA_wdata_valid); end
    if (!$isunknown(g_toAIA_wdata_bits_op) && g_toAIA_wdata_bits_op !== i_toAIA_wdata_bits_op) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_wdata_bits_op g=%h i=%h", $time, g_toAIA_wdata_bits_op, i_toAIA_wdata_bits_op); end
    if (!$isunknown(g_toAIA_wdata_bits_data) && g_toAIA_wdata_bits_data !== i_toAIA_wdata_bits_data) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_wdata_bits_data g=%h i=%h", $time, g_toAIA_wdata_bits_data, i_toAIA_wdata_bits_data); end
    if (!$isunknown(g_toAIA_mClaim) && g_toAIA_mClaim !== i_toAIA_mClaim) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_mClaim g=%h i=%h", $time, g_toAIA_mClaim, i_toAIA_mClaim); end
    if (!$isunknown(g_toAIA_sClaim) && g_toAIA_sClaim !== i_toAIA_sClaim) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_sClaim g=%h i=%h", $time, g_toAIA_sClaim, i_toAIA_sClaim); end
    if (!$isunknown(g_toAIA_vsClaim) && g_toAIA_vsClaim !== i_toAIA_vsClaim) begin errors++;
      if(errors<=80) $display("[%0t] toAIA_vsClaim g=%h i=%h", $time, g_toAIA_vsClaim, i_toAIA_vsClaim); end
    if (!$isunknown(g_io_error_0) && g_io_error_0 !== i_io_error_0) begin errors++;
      if(errors<=80) $display("[%0t] io_error_0 g=%h i=%h", $time, g_io_error_0, i_io_error_0); end
  end
  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
