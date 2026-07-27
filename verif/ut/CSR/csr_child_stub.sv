// csr_child_stub.sv —— UT 用: NewCSR + IMSICGateWay 的确定性行为 stub。
// 两个 UT DUT (golden CSR u_g / 可读核 CSR_xs u_i) 共用同一 stub 例化,
// stub 输出 = 输入的确定性组合 (非 X), 故 CSR 胶合逻辑的任何差异必现于比对。
// clock/reset 端口忽略 (纯组合 stub); 仅供 UT, 非 FM (FM 里两者是黑盒)。

module NewCSR(
  input         clock,
  input         reset,
  input         platformIRP_MEIP,
  input         platformIRP_MTIP,
  input         platformIRP_MSIP,
  input         platformIRP_SEIP,
  input         platformIRP_debugIP,
  input         nonMaskableIRP_NMI_43,
  input         nonMaskableIRP_NMI_31,
  input  [5:0]  io_fromTop_hartId,
  input         io_fromTop_clintTime_valid,
  input  [63:0] io_fromTop_clintTime_bits,
  input         io_fromTop_l2FlushDone,
  input         io_fromTop_criticalErrorState,
  output        io_in_ready,
  input         io_in_valid,
  input         io_in_bits_wen,
  input         io_in_bits_ren,
  input  [1:0]  io_in_bits_op,
  input  [11:0] io_in_bits_addr,
  input  [63:0] io_in_bits_src,
  input  [63:0] io_in_bits_wdata,
  input         io_in_bits_mnret,
  input         io_in_bits_mret,
  input         io_in_bits_sret,
  input         io_in_bits_dret,
  input         io_in_bits_redirectFlush,
  input         io_trapInst_valid,
  input  [31:0] io_trapInst_bits,
  input  [63:0] io_fromMem_excpVA,
  input  [63:0] io_fromMem_excpGPA,
  input         io_fromMem_excpIsForVSnonLeafPTE,
  input         io_fromRob_trap_valid,
  input  [49:0] io_fromRob_trap_bits_pc,
  input  [55:0] io_fromRob_trap_bits_pcGPA,
  input  [63:0] io_fromRob_trap_bits_trapVec,
  input         io_fromRob_trap_bits_isFetchBkpt,
  input         io_fromRob_trap_bits_singleStep,
  input  [3:0]  io_fromRob_trap_bits_trigger,
  input         io_fromRob_trap_bits_crossPageIPFFix,
  input         io_fromRob_trap_bits_isInterrupt,
  input         io_fromRob_trap_bits_isHls,
  input         io_fromRob_trap_bits_isFetchMalAddr,
  input         io_fromRob_trap_bits_isForVSnonLeafPTE,
  input  [6:0]  io_fromRob_commit_instNum_bits,
  input         io_fromRob_commit_fflags_valid,
  input  [4:0]  io_fromRob_commit_fflags_bits,
  input         io_fromRob_commit_fsDirty,
  input         io_fromRob_commit_vxsat_valid,
  input         io_fromRob_commit_vxsat_bits,
  input         io_fromRob_commit_vsDirty,
  input         io_fromRob_commit_vtype_valid,
  input         io_fromRob_commit_vtype_bits_VILL,
  input         io_fromRob_commit_vtype_bits_VMA,
  input         io_fromRob_commit_vtype_bits_VTA,
  input  [2:0]  io_fromRob_commit_vtype_bits_VSEW,
  input  [2:0]  io_fromRob_commit_vtype_bits_VLMUL,
  input  [7:0]  io_fromRob_commit_vl,
  input         io_fromRob_commit_vstart_valid,
  input  [6:0]  io_fromRob_commit_vstart_bits,
  input         io_fromVecExcpMod_busy,
  input  [5:0]  io_perf_perfEventsFrontend_0_value,
  input  [5:0]  io_perf_perfEventsFrontend_1_value,
  input  [5:0]  io_perf_perfEventsFrontend_2_value,
  input  [5:0]  io_perf_perfEventsFrontend_3_value,
  input  [5:0]  io_perf_perfEventsFrontend_4_value,
  input  [5:0]  io_perf_perfEventsFrontend_5_value,
  input  [5:0]  io_perf_perfEventsFrontend_6_value,
  input  [5:0]  io_perf_perfEventsFrontend_7_value,
  input  [5:0]  io_perf_perfEventsBackend_0_value,
  input  [5:0]  io_perf_perfEventsBackend_1_value,
  input  [5:0]  io_perf_perfEventsBackend_2_value,
  input  [5:0]  io_perf_perfEventsBackend_3_value,
  input  [5:0]  io_perf_perfEventsBackend_4_value,
  input  [5:0]  io_perf_perfEventsBackend_5_value,
  input  [5:0]  io_perf_perfEventsBackend_6_value,
  input  [5:0]  io_perf_perfEventsBackend_7_value,
  input  [5:0]  io_perf_perfEventsLsu_0_value,
  input  [5:0]  io_perf_perfEventsLsu_1_value,
  input  [5:0]  io_perf_perfEventsLsu_2_value,
  input  [5:0]  io_perf_perfEventsLsu_3_value,
  input  [5:0]  io_perf_perfEventsLsu_4_value,
  input  [5:0]  io_perf_perfEventsLsu_5_value,
  input  [5:0]  io_perf_perfEventsLsu_6_value,
  input  [5:0]  io_perf_perfEventsLsu_7_value,
  input  [5:0]  io_perf_perfEventsHc_0_value,
  input  [5:0]  io_perf_perfEventsHc_1_value,
  input  [5:0]  io_perf_perfEventsHc_2_value,
  input  [5:0]  io_perf_perfEventsHc_3_value,
  input  [5:0]  io_perf_perfEventsHc_4_value,
  input  [5:0]  io_perf_perfEventsHc_5_value,
  input  [5:0]  io_perf_perfEventsHc_6_value,
  input  [5:0]  io_perf_perfEventsHc_7_value,
  input  [5:0]  io_perf_perfEventsHc_8_value,
  input  [5:0]  io_perf_perfEventsHc_9_value,
  input  [5:0]  io_perf_perfEventsHc_10_value,
  input  [5:0]  io_perf_perfEventsHc_11_value,
  input  [5:0]  io_perf_perfEventsHc_12_value,
  input  [5:0]  io_perf_perfEventsHc_13_value,
  input  [5:0]  io_perf_perfEventsHc_14_value,
  input  [5:0]  io_perf_perfEventsHc_15_value,
  input  [5:0]  io_perf_perfEventsHc_16_value,
  input  [5:0]  io_perf_perfEventsHc_17_value,
  input  [5:0]  io_perf_perfEventsHc_18_value,
  input  [5:0]  io_perf_perfEventsHc_19_value,
  input  [5:0]  io_perf_perfEventsHc_20_value,
  input  [5:0]  io_perf_perfEventsHc_21_value,
  input  [5:0]  io_perf_perfEventsHc_22_value,
  input  [5:0]  io_perf_perfEventsHc_23_value,
  input  [5:0]  io_perf_perfEventsHc_24_value,
  input  [5:0]  io_perf_perfEventsHc_25_value,
  input  [5:0]  io_perf_perfEventsHc_26_value,
  input  [5:0]  io_perf_perfEventsHc_27_value,
  input  [5:0]  io_perf_perfEventsHc_28_value,
  input  [5:0]  io_perf_perfEventsHc_29_value,
  input  [5:0]  io_perf_perfEventsHc_30_value,
  input  [5:0]  io_perf_perfEventsHc_31_value,
  input  [5:0]  io_perf_perfEventsHc_32_value,
  input  [5:0]  io_perf_perfEventsHc_33_value,
  input  [5:0]  io_perf_perfEventsHc_34_value,
  input  [5:0]  io_perf_perfEventsHc_35_value,
  input  [5:0]  io_perf_perfEventsHc_36_value,
  input  [5:0]  io_perf_perfEventsHc_37_value,
  input  [5:0]  io_perf_perfEventsHc_38_value,
  input  [5:0]  io_perf_perfEventsHc_39_value,
  input  [5:0]  io_perf_perfEventsHc_40_value,
  input  [5:0]  io_perf_perfEventsHc_41_value,
  input  [5:0]  io_perf_perfEventsHc_42_value,
  input  [5:0]  io_perf_perfEventsHc_43_value,
  input  [5:0]  io_perf_perfEventsHc_44_value,
  input  [5:0]  io_perf_perfEventsHc_45_value,
  input  [5:0]  io_perf_perfEventsHc_46_value,
  input  [5:0]  io_perf_perfEventsHc_47_value,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_EX_II,
  output        io_out_bits_EX_VI,
  output        io_out_bits_flushPipe,
  output [63:0] io_out_bits_rData,
  output        io_out_bits_targetPcUpdate,
  output [63:0] io_out_bits_targetPc_pc,
  output        io_out_bits_targetPc_raiseIPF,
  output        io_out_bits_targetPc_raiseIAF,
  output        io_out_bits_targetPc_raiseIGPF,
  output [63:0] io_out_bits_regOut,
  output        io_out_bits_isPerfCnt,
  output [1:0]  io_status_privState_PRVM,
  output        io_status_privState_V,
  output        io_status_interrupt,
  output        io_status_wfiEvent,
  output [2:0]  io_status_fpState_frm,
  output [6:0]  io_status_vecState_vstart,
  output [1:0]  io_status_vecState_vxrm,
  output        io_status_singleStepFlag,
  output        io_status_frontendTrigger_tUpdate_valid,
  output [1:0]  io_status_frontendTrigger_tUpdate_bits_addr,
  output [1:0]  io_status_frontendTrigger_tUpdate_bits_tdata_matchType,
  output        io_status_frontendTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_status_frontendTrigger_tUpdate_bits_tdata_action,
  output        io_status_frontendTrigger_tUpdate_bits_tdata_chain,
  output [63:0] io_status_frontendTrigger_tUpdate_bits_tdata_tdata2,
  output        io_status_frontendTrigger_tEnableVec_0,
  output        io_status_frontendTrigger_tEnableVec_1,
  output        io_status_frontendTrigger_tEnableVec_2,
  output        io_status_frontendTrigger_tEnableVec_3,
  output        io_status_frontendTrigger_debugMode,
  output        io_status_frontendTrigger_triggerCanRaiseBpExp,
  output        io_status_memTrigger_tUpdate_valid,
  output [1:0]  io_status_memTrigger_tUpdate_bits_addr,
  output [1:0]  io_status_memTrigger_tUpdate_bits_tdata_matchType,
  output        io_status_memTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_status_memTrigger_tUpdate_bits_tdata_action,
  output        io_status_memTrigger_tUpdate_bits_tdata_chain,
  output        io_status_memTrigger_tUpdate_bits_tdata_store,
  output        io_status_memTrigger_tUpdate_bits_tdata_load,
  output [63:0] io_status_memTrigger_tUpdate_bits_tdata_tdata2,
  output        io_status_memTrigger_tEnableVec_0,
  output        io_status_memTrigger_tEnableVec_1,
  output        io_status_memTrigger_tEnableVec_2,
  output        io_status_memTrigger_tEnableVec_3,
  output        io_status_memTrigger_debugMode,
  output        io_status_memTrigger_triggerCanRaiseBpExp,
  output        io_status_instrAddrTransType_bare,
  output        io_status_instrAddrTransType_sv39,
  output        io_status_instrAddrTransType_sv39x4,
  output        io_status_instrAddrTransType_sv48,
  output        io_status_instrAddrTransType_sv48x4,
  output [63:0] io_status_traceCSR_cause,
  output [49:0] io_status_traceCSR_tval,
  output [2:0]  io_status_traceCSR_lastPriv,
  output [2:0]  io_status_traceCSR_currentPriv,
  output        io_status_custom_pf_ctrl_l1I_pf_enable,
  output        io_status_custom_pf_ctrl_l2_pf_enable,
  output        io_status_custom_pf_ctrl_l1D_pf_enable,
  output        io_status_custom_pf_ctrl_l1D_pf_train_on_hit,
  output        io_status_custom_pf_ctrl_l1D_pf_enable_agt,
  output        io_status_custom_pf_ctrl_l1D_pf_enable_pht,
  output [3:0]  io_status_custom_pf_ctrl_l1D_pf_active_threshold,
  output [5:0]  io_status_custom_pf_ctrl_l1D_pf_active_stride,
  output        io_status_custom_pf_ctrl_l1D_pf_enable_stride,
  output        io_status_custom_pf_ctrl_l2_pf_store_only,
  output        io_status_custom_pf_ctrl_l2_pf_recv_enable,
  output        io_status_custom_pf_ctrl_l2_pf_pbop_enable,
  output        io_status_custom_pf_ctrl_l2_pf_vbop_enable,
  output [4:0]  io_status_custom_lvpred_timeout,
  output        io_status_custom_bp_ctrl_ubtb_enable,
  output        io_status_custom_bp_ctrl_btb_enable,
  output        io_status_custom_bp_ctrl_tage_enable,
  output        io_status_custom_bp_ctrl_sc_enable,
  output        io_status_custom_bp_ctrl_ras_enable,
  output        io_status_custom_ldld_vio_check_enable,
  output        io_status_custom_cache_error_enable,
  output        io_status_custom_uncache_write_outstanding_enable,
  output        io_status_custom_hd_misalign_st_enable,
  output        io_status_custom_hd_misalign_ld_enable,
  output        io_status_custom_power_down_enable,
  output        io_status_custom_flush_l2_enable,
  output        io_status_custom_fusion_enable,
  output        io_status_custom_wfi_enable,
  output        io_status_criticalErrorState,
  output        io_tlb_satpASIDChanged,
  output        io_tlb_vsatpASIDChanged,
  output        io_tlb_hgatpVMIDChanged,
  output [3:0]  io_tlb_satp_MODE,
  output [15:0] io_tlb_satp_ASID,
  output [43:0] io_tlb_satp_PPN,
  output [3:0]  io_tlb_vsatp_MODE,
  output [15:0] io_tlb_vsatp_ASID,
  output [43:0] io_tlb_vsatp_PPN,
  output [3:0]  io_tlb_hgatp_MODE,
  output [13:0] io_tlb_hgatp_VMID,
  output [43:0] io_tlb_hgatp_PPN,
  output        io_tlb_mxr,
  output        io_tlb_sum,
  output        io_tlb_vmxr,
  output        io_tlb_vsum,
  output        io_tlb_spvp,
  output [1:0]  io_tlb_imode,
  output [1:0]  io_tlb_dmode,
  output        io_tlb_dvirt,
  output        io_tlb_mPBMTE,
  output        io_tlb_hPBMTE,
  output [1:0]  io_tlb_pmm_mseccfg,
  output [1:0]  io_tlb_pmm_menvcfg,
  output [1:0]  io_tlb_pmm_henvcfg,
  output [1:0]  io_tlb_pmm_hstatus,
  output [1:0]  io_tlb_pmm_senvcfg,
  output        io_toDecode_illegalInst_sfenceVMA,
  output        io_toDecode_illegalInst_sfencePart,
  output        io_toDecode_illegalInst_hfenceGVMA,
  output        io_toDecode_illegalInst_hfenceVVMA,
  output        io_toDecode_illegalInst_hlsv,
  output        io_toDecode_illegalInst_fsIsOff,
  output        io_toDecode_illegalInst_vsIsOff,
  output        io_toDecode_illegalInst_wfi,
  output        io_toDecode_illegalInst_wrs_nto,
  output        io_toDecode_illegalInst_frm,
  output        io_toDecode_illegalInst_cboZ,
  output        io_toDecode_illegalInst_cboCF,
  output        io_toDecode_illegalInst_cboI,
  output        io_toDecode_virtualInst_sfenceVMA,
  output        io_toDecode_virtualInst_sfencePart,
  output        io_toDecode_virtualInst_hfence,
  output        io_toDecode_virtualInst_hlsv,
  output        io_toDecode_virtualInst_wfi,
  output        io_toDecode_virtualInst_wrs_nto,
  output        io_toDecode_virtualInst_cboZ,
  output        io_toDecode_virtualInst_cboCF,
  output        io_toDecode_virtualInst_cboI,
  output        io_toDecode_special_cboI2F,
  input  [63:0] io_fetchMalTval,
  output        io_distributedWenLegal,
  output        toAIA_addr_valid,
  output [11:0] toAIA_addr_bits_addr,
  output        toAIA_addr_bits_v,
  output [1:0]  toAIA_addr_bits_prvm,
  output [5:0]  toAIA_vgein,
  output        toAIA_wdata_valid,
  output [1:0]  toAIA_wdata_bits_op,
  output [63:0] toAIA_wdata_bits_data,
  output        toAIA_mClaim,
  output        toAIA_sClaim,
  output        toAIA_vsClaim,
  input         fromAIA_rdata_valid,
  input  [63:0] fromAIA_rdata_bits_data,
  input         fromAIA_rdata_bits_illegal,
  input         fromAIA_meip,
  input         fromAIA_seip,
  input  [4:0]  fromAIA_vseip,
  input  [10:0] fromAIA_mtopei_IID,
  input  [10:0] fromAIA_mtopei_IPRIO,
  input  [10:0] fromAIA_stopei_IID,
  input  [10:0] fromAIA_stopei_IPRIO,
  input  [10:0] fromAIA_vstopei_IID,
  input  [10:0] fromAIA_vstopei_IPRIO,
  output        io_error_0
);

  wire _seed = (^{1'b0,platformIRP_MEIP}) ^ (^{1'b0,platformIRP_MTIP}) ^ (^{1'b0,platformIRP_MSIP}) ^ (^{1'b0,platformIRP_SEIP}) ^ (^{1'b0,platformIRP_debugIP}) ^ (^{1'b0,nonMaskableIRP_NMI_43}) ^ (^{1'b0,nonMaskableIRP_NMI_31}) ^ (^{1'b0,io_fromTop_hartId}) ^ (^{1'b0,io_fromTop_clintTime_valid}) ^ (^{1'b0,io_fromTop_clintTime_bits}) ^ (^{1'b0,io_fromTop_l2FlushDone}) ^ (^{1'b0,io_fromTop_criticalErrorState}) ^ (^{1'b0,io_in_valid}) ^ (^{1'b0,io_in_bits_wen}) ^ (^{1'b0,io_in_bits_ren}) ^ (^{1'b0,io_in_bits_op}) ^ (^{1'b0,io_in_bits_addr}) ^ (^{1'b0,io_in_bits_src}) ^ (^{1'b0,io_in_bits_wdata}) ^ (^{1'b0,io_in_bits_mnret}) ^ (^{1'b0,io_in_bits_mret}) ^ (^{1'b0,io_in_bits_sret}) ^ (^{1'b0,io_in_bits_dret}) ^ (^{1'b0,io_in_bits_redirectFlush}) ^ (^{1'b0,io_trapInst_valid}) ^ (^{1'b0,io_trapInst_bits}) ^ (^{1'b0,io_fromMem_excpVA}) ^ (^{1'b0,io_fromMem_excpGPA}) ^ (^{1'b0,io_fromMem_excpIsForVSnonLeafPTE}) ^ (^{1'b0,io_fromRob_trap_valid}) ^ (^{1'b0,io_fromRob_trap_bits_pc}) ^ (^{1'b0,io_fromRob_trap_bits_pcGPA}) ^ (^{1'b0,io_fromRob_trap_bits_trapVec}) ^ (^{1'b0,io_fromRob_trap_bits_isFetchBkpt}) ^ (^{1'b0,io_fromRob_trap_bits_singleStep}) ^ (^{1'b0,io_fromRob_trap_bits_trigger}) ^ (^{1'b0,io_fromRob_trap_bits_crossPageIPFFix}) ^ (^{1'b0,io_fromRob_trap_bits_isInterrupt}) ^ (^{1'b0,io_fromRob_trap_bits_isHls}) ^ (^{1'b0,io_fromRob_trap_bits_isFetchMalAddr}) ^ (^{1'b0,io_fromRob_trap_bits_isForVSnonLeafPTE}) ^ (^{1'b0,io_fromRob_commit_instNum_bits}) ^ (^{1'b0,io_fromRob_commit_fflags_valid}) ^ (^{1'b0,io_fromRob_commit_fflags_bits}) ^ (^{1'b0,io_fromRob_commit_fsDirty}) ^ (^{1'b0,io_fromRob_commit_vxsat_valid}) ^ (^{1'b0,io_fromRob_commit_vxsat_bits}) ^ (^{1'b0,io_fromRob_commit_vsDirty}) ^ (^{1'b0,io_fromRob_commit_vtype_valid}) ^ (^{1'b0,io_fromRob_commit_vtype_bits_VILL}) ^ (^{1'b0,io_fromRob_commit_vtype_bits_VMA}) ^ (^{1'b0,io_fromRob_commit_vtype_bits_VTA}) ^ (^{1'b0,io_fromRob_commit_vtype_bits_VSEW}) ^ (^{1'b0,io_fromRob_commit_vtype_bits_VLMUL}) ^ (^{1'b0,io_fromRob_commit_vl}) ^ (^{1'b0,io_fromRob_commit_vstart_valid}) ^ (^{1'b0,io_fromRob_commit_vstart_bits}) ^ (^{1'b0,io_fromVecExcpMod_busy}) ^ (^{1'b0,io_perf_perfEventsFrontend_0_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_1_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_2_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_3_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_4_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_5_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_6_value}) ^ (^{1'b0,io_perf_perfEventsFrontend_7_value}) ^ (^{1'b0,io_perf_perfEventsBackend_0_value}) ^ (^{1'b0,io_perf_perfEventsBackend_1_value}) ^ (^{1'b0,io_perf_perfEventsBackend_2_value}) ^ (^{1'b0,io_perf_perfEventsBackend_3_value}) ^ (^{1'b0,io_perf_perfEventsBackend_4_value}) ^ (^{1'b0,io_perf_perfEventsBackend_5_value}) ^ (^{1'b0,io_perf_perfEventsBackend_6_value}) ^ (^{1'b0,io_perf_perfEventsBackend_7_value}) ^ (^{1'b0,io_perf_perfEventsLsu_0_value}) ^ (^{1'b0,io_perf_perfEventsLsu_1_value}) ^ (^{1'b0,io_perf_perfEventsLsu_2_value}) ^ (^{1'b0,io_perf_perfEventsLsu_3_value}) ^ (^{1'b0,io_perf_perfEventsLsu_4_value}) ^ (^{1'b0,io_perf_perfEventsLsu_5_value}) ^ (^{1'b0,io_perf_perfEventsLsu_6_value}) ^ (^{1'b0,io_perf_perfEventsLsu_7_value}) ^ (^{1'b0,io_perf_perfEventsHc_0_value}) ^ (^{1'b0,io_perf_perfEventsHc_1_value}) ^ (^{1'b0,io_perf_perfEventsHc_2_value}) ^ (^{1'b0,io_perf_perfEventsHc_3_value}) ^ (^{1'b0,io_perf_perfEventsHc_4_value}) ^ (^{1'b0,io_perf_perfEventsHc_5_value}) ^ (^{1'b0,io_perf_perfEventsHc_6_value}) ^ (^{1'b0,io_perf_perfEventsHc_7_value}) ^ (^{1'b0,io_perf_perfEventsHc_8_value}) ^ (^{1'b0,io_perf_perfEventsHc_9_value}) ^ (^{1'b0,io_perf_perfEventsHc_10_value}) ^ (^{1'b0,io_perf_perfEventsHc_11_value}) ^ (^{1'b0,io_perf_perfEventsHc_12_value}) ^ (^{1'b0,io_perf_perfEventsHc_13_value}) ^ (^{1'b0,io_perf_perfEventsHc_14_value}) ^ (^{1'b0,io_perf_perfEventsHc_15_value}) ^ (^{1'b0,io_perf_perfEventsHc_16_value}) ^ (^{1'b0,io_perf_perfEventsHc_17_value}) ^ (^{1'b0,io_perf_perfEventsHc_18_value}) ^ (^{1'b0,io_perf_perfEventsHc_19_value}) ^ (^{1'b0,io_perf_perfEventsHc_20_value}) ^ (^{1'b0,io_perf_perfEventsHc_21_value}) ^ (^{1'b0,io_perf_perfEventsHc_22_value}) ^ (^{1'b0,io_perf_perfEventsHc_23_value}) ^ (^{1'b0,io_perf_perfEventsHc_24_value}) ^ (^{1'b0,io_perf_perfEventsHc_25_value}) ^ (^{1'b0,io_perf_perfEventsHc_26_value}) ^ (^{1'b0,io_perf_perfEventsHc_27_value}) ^ (^{1'b0,io_perf_perfEventsHc_28_value}) ^ (^{1'b0,io_perf_perfEventsHc_29_value}) ^ (^{1'b0,io_perf_perfEventsHc_30_value}) ^ (^{1'b0,io_perf_perfEventsHc_31_value}) ^ (^{1'b0,io_perf_perfEventsHc_32_value}) ^ (^{1'b0,io_perf_perfEventsHc_33_value}) ^ (^{1'b0,io_perf_perfEventsHc_34_value}) ^ (^{1'b0,io_perf_perfEventsHc_35_value}) ^ (^{1'b0,io_perf_perfEventsHc_36_value}) ^ (^{1'b0,io_perf_perfEventsHc_37_value}) ^ (^{1'b0,io_perf_perfEventsHc_38_value}) ^ (^{1'b0,io_perf_perfEventsHc_39_value}) ^ (^{1'b0,io_perf_perfEventsHc_40_value}) ^ (^{1'b0,io_perf_perfEventsHc_41_value}) ^ (^{1'b0,io_perf_perfEventsHc_42_value}) ^ (^{1'b0,io_perf_perfEventsHc_43_value}) ^ (^{1'b0,io_perf_perfEventsHc_44_value}) ^ (^{1'b0,io_perf_perfEventsHc_45_value}) ^ (^{1'b0,io_perf_perfEventsHc_46_value}) ^ (^{1'b0,io_perf_perfEventsHc_47_value}) ^ (^{1'b0,io_out_ready}) ^ (^{1'b0,io_fetchMalTval}) ^ (^{1'b0,fromAIA_rdata_valid}) ^ (^{1'b0,fromAIA_rdata_bits_data}) ^ (^{1'b0,fromAIA_rdata_bits_illegal}) ^ (^{1'b0,fromAIA_meip}) ^ (^{1'b0,fromAIA_seip}) ^ (^{1'b0,fromAIA_vseip}) ^ (^{1'b0,fromAIA_mtopei_IID}) ^ (^{1'b0,fromAIA_mtopei_IPRIO}) ^ (^{1'b0,fromAIA_stopei_IID}) ^ (^{1'b0,fromAIA_stopei_IPRIO}) ^ (^{1'b0,fromAIA_vstopei_IID}) ^ (^{1'b0,fromAIA_vstopei_IPRIO});
  assign io_in_ready = {1{_seed}} ^ 1'd0;
  assign io_out_valid = {1{_seed}} ^ 1'd1;
  assign io_out_bits_EX_II = {1{_seed}} ^ 1'd0;
  assign io_out_bits_EX_VI = {1{_seed}} ^ 1'd1;
  assign io_out_bits_flushPipe = {1{_seed}} ^ 1'd0;
  assign io_out_bits_rData = {64{_seed}} ^ 64'd13272178805;
  assign io_out_bits_targetPcUpdate = {1{_seed}} ^ 1'd0;
  assign io_out_bits_targetPc_pc = {64{_seed}} ^ 64'd18581050327;
  assign io_out_bits_targetPc_raiseIPF = {1{_seed}} ^ 1'd0;
  assign io_out_bits_targetPc_raiseIAF = {1{_seed}} ^ 1'd1;
  assign io_out_bits_targetPc_raiseIGPF = {1{_seed}} ^ 1'd0;
  assign io_out_bits_regOut = {64{_seed}} ^ 64'd29198793371;
  assign io_out_bits_isPerfCnt = {1{_seed}} ^ 1'd0;
  assign io_status_privState_PRVM = {2{_seed}} ^ 2'd1;
  assign io_status_privState_V = {1{_seed}} ^ 1'd0;
  assign io_status_interrupt = {1{_seed}} ^ 1'd1;
  assign io_status_wfiEvent = {1{_seed}} ^ 1'd0;
  assign io_status_fpState_frm = {3{_seed}} ^ 3'd1;
  assign io_status_vecState_vstart = {7{_seed}} ^ 7'd114;
  assign io_status_vecState_vxrm = {2{_seed}} ^ 2'd3;
  assign io_status_singleStepFlag = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_tUpdate_valid = {1{_seed}} ^ 1'd1;
  assign io_status_frontendTrigger_tUpdate_bits_addr = {2{_seed}} ^ 2'd2;
  assign io_status_frontendTrigger_tUpdate_bits_tdata_matchType = {2{_seed}} ^ 2'd3;
  assign io_status_frontendTrigger_tUpdate_bits_tdata_select = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_tUpdate_bits_tdata_action = {4{_seed}} ^ 4'd9;
  assign io_status_frontendTrigger_tUpdate_bits_tdata_chain = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_tUpdate_bits_tdata_tdata2 = {64{_seed}} ^ 64'd71669765547;
  assign io_status_frontendTrigger_tEnableVec_0 = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_tEnableVec_1 = {1{_seed}} ^ 1'd1;
  assign io_status_frontendTrigger_tEnableVec_2 = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_tEnableVec_3 = {1{_seed}} ^ 1'd1;
  assign io_status_frontendTrigger_debugMode = {1{_seed}} ^ 1'd0;
  assign io_status_frontendTrigger_triggerCanRaiseBpExp = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tUpdate_valid = {1{_seed}} ^ 1'd0;
  assign io_status_memTrigger_tUpdate_bits_addr = {2{_seed}} ^ 2'd3;
  assign io_status_memTrigger_tUpdate_bits_tdata_matchType = {2{_seed}} ^ 2'd0;
  assign io_status_memTrigger_tUpdate_bits_tdata_select = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tUpdate_bits_tdata_action = {4{_seed}} ^ 4'd6;
  assign io_status_memTrigger_tUpdate_bits_tdata_chain = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tUpdate_bits_tdata_store = {1{_seed}} ^ 1'd0;
  assign io_status_memTrigger_tUpdate_bits_tdata_load = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tUpdate_bits_tdata_tdata2 = {64{_seed}} ^ 64'd111486301962;
  assign io_status_memTrigger_tEnableVec_0 = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tEnableVec_1 = {1{_seed}} ^ 1'd0;
  assign io_status_memTrigger_tEnableVec_2 = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_tEnableVec_3 = {1{_seed}} ^ 1'd0;
  assign io_status_memTrigger_debugMode = {1{_seed}} ^ 1'd1;
  assign io_status_memTrigger_triggerCanRaiseBpExp = {1{_seed}} ^ 1'd0;
  assign io_status_instrAddrTransType_bare = {1{_seed}} ^ 1'd1;
  assign io_status_instrAddrTransType_sv39 = {1{_seed}} ^ 1'd0;
  assign io_status_instrAddrTransType_sv39x4 = {1{_seed}} ^ 1'd1;
  assign io_status_instrAddrTransType_sv48 = {1{_seed}} ^ 1'd0;
  assign io_status_instrAddrTransType_sv48x4 = {1{_seed}} ^ 1'd1;
  assign io_status_traceCSR_cause = {64{_seed}} ^ 64'd143339531094;
  assign io_status_traceCSR_tval = {50{_seed}} ^ 50'd145993966855;
  assign io_status_traceCSR_lastPriv = {3{_seed}} ^ 3'd0;
  assign io_status_traceCSR_currentPriv = {3{_seed}} ^ 3'd1;
  assign io_status_custom_pf_ctrl_l1I_pf_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_pf_ctrl_l2_pf_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_pf_ctrl_l1D_pf_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_pf_ctrl_l1D_pf_train_on_hit = {1{_seed}} ^ 1'd1;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_agt = {1{_seed}} ^ 1'd0;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_pht = {1{_seed}} ^ 1'd1;
  assign io_status_custom_pf_ctrl_l1D_pf_active_threshold = {4{_seed}} ^ 4'd0;
  assign io_status_custom_pf_ctrl_l1D_pf_active_stride = {6{_seed}} ^ 6'd49;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_stride = {1{_seed}} ^ 1'd0;
  assign io_status_custom_pf_ctrl_l2_pf_store_only = {1{_seed}} ^ 1'd1;
  assign io_status_custom_pf_ctrl_l2_pf_recv_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_pf_ctrl_l2_pf_pbop_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_pf_ctrl_l2_pf_vbop_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_lvpred_timeout = {5{_seed}} ^ 5'd23;
  assign io_status_custom_bp_ctrl_ubtb_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_bp_ctrl_btb_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_bp_ctrl_tage_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_bp_ctrl_sc_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_bp_ctrl_ras_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_ldld_vio_check_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_cache_error_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_uncache_write_outstanding_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_hd_misalign_st_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_hd_misalign_ld_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_power_down_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_flush_l2_enable = {1{_seed}} ^ 1'd1;
  assign io_status_custom_fusion_enable = {1{_seed}} ^ 1'd0;
  assign io_status_custom_wfi_enable = {1{_seed}} ^ 1'd1;
  assign io_status_criticalErrorState = {1{_seed}} ^ 1'd0;
  assign io_tlb_satpASIDChanged = {1{_seed}} ^ 1'd1;
  assign io_tlb_vsatpASIDChanged = {1{_seed}} ^ 1'd0;
  assign io_tlb_hgatpVMIDChanged = {1{_seed}} ^ 1'd1;
  assign io_tlb_satp_MODE = {4{_seed}} ^ 4'd10;
  assign io_tlb_satp_ASID = {16{_seed}} ^ 16'd16875;
  assign io_tlb_satp_PPN = {44{_seed}} ^ 44'd244208090012;
  assign io_tlb_vsatp_MODE = {4{_seed}} ^ 4'd13;
  assign io_tlb_vsatp_ASID = {16{_seed}} ^ 16'd44798;
  assign io_tlb_vsatp_PPN = {44{_seed}} ^ 44'd252171397295;
  assign io_tlb_hgatp_MODE = {4{_seed}} ^ 4'd0;
  assign io_tlb_hgatp_VMID = {14{_seed}} ^ 14'd7185;
  assign io_tlb_hgatp_PPN = {44{_seed}} ^ 44'd260134704578;
  assign io_tlb_mxr = {1{_seed}} ^ 1'd1;
  assign io_tlb_sum = {1{_seed}} ^ 1'd0;
  assign io_tlb_vmxr = {1{_seed}} ^ 1'd1;
  assign io_tlb_vsum = {1{_seed}} ^ 1'd0;
  assign io_tlb_spvp = {1{_seed}} ^ 1'd1;
  assign io_tlb_imode = {2{_seed}} ^ 2'd0;
  assign io_tlb_dmode = {2{_seed}} ^ 2'd1;
  assign io_tlb_dvirt = {1{_seed}} ^ 1'd0;
  assign io_tlb_mPBMTE = {1{_seed}} ^ 1'd1;
  assign io_tlb_hPBMTE = {1{_seed}} ^ 1'd0;
  assign io_tlb_pmm_mseccfg = {2{_seed}} ^ 2'd1;
  assign io_tlb_pmm_menvcfg = {2{_seed}} ^ 2'd2;
  assign io_tlb_pmm_henvcfg = {2{_seed}} ^ 2'd3;
  assign io_tlb_pmm_hstatus = {2{_seed}} ^ 2'd0;
  assign io_tlb_pmm_senvcfg = {2{_seed}} ^ 2'd1;
  assign io_toDecode_illegalInst_sfenceVMA = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_sfencePart = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_hfenceGVMA = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_hfenceVVMA = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_hlsv = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_fsIsOff = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_vsIsOff = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_wfi = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_wrs_nto = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_frm = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_cboZ = {1{_seed}} ^ 1'd0;
  assign io_toDecode_illegalInst_cboCF = {1{_seed}} ^ 1'd1;
  assign io_toDecode_illegalInst_cboI = {1{_seed}} ^ 1'd0;
  assign io_toDecode_virtualInst_sfenceVMA = {1{_seed}} ^ 1'd1;
  assign io_toDecode_virtualInst_sfencePart = {1{_seed}} ^ 1'd0;
  assign io_toDecode_virtualInst_hfence = {1{_seed}} ^ 1'd1;
  assign io_toDecode_virtualInst_hlsv = {1{_seed}} ^ 1'd0;
  assign io_toDecode_virtualInst_wfi = {1{_seed}} ^ 1'd1;
  assign io_toDecode_virtualInst_wrs_nto = {1{_seed}} ^ 1'd0;
  assign io_toDecode_virtualInst_cboZ = {1{_seed}} ^ 1'd1;
  assign io_toDecode_virtualInst_cboCF = {1{_seed}} ^ 1'd0;
  assign io_toDecode_virtualInst_cboI = {1{_seed}} ^ 1'd1;
  assign io_toDecode_special_cboI2F = {1{_seed}} ^ 1'd0;
  assign io_distributedWenLegal = {1{_seed}} ^ 1'd1;
  assign toAIA_addr_valid = {1{_seed}} ^ 1'd0;
  assign toAIA_addr_bits_addr = {12{_seed}} ^ 12'd795;
  assign toAIA_addr_bits_v = {1{_seed}} ^ 1'd0;
  assign toAIA_addr_bits_prvm = {2{_seed}} ^ 2'd1;
  assign toAIA_vgein = {6{_seed}} ^ 6'd46;
  assign toAIA_wdata_valid = {1{_seed}} ^ 1'd1;
  assign toAIA_wdata_bits_op = {2{_seed}} ^ 2'd0;
  assign toAIA_wdata_bits_data = {64{_seed}} ^ 64'd384893185345;
  assign toAIA_mClaim = {1{_seed}} ^ 1'd0;
  assign toAIA_sClaim = {1{_seed}} ^ 1'd1;
  assign toAIA_vsClaim = {1{_seed}} ^ 1'd0;
  assign io_error_0 = {1{_seed}} ^ 1'd1;
endmodule

module IMSICGateWay(
  input         clock,
  input         reset,
  input         msiio_vld_req,
  input  [10:0] msiio_data,
  output [7:0]  msi_data_o,
  output [6:0]  msi_valid_o
);

  wire _seed = (^{1'b0,msiio_vld_req}) ^ (^{1'b0,msiio_data});
  assign msi_data_o = {8{_seed}} ^ 8'd0;
  assign msi_valid_o = {7{_seed}} ^ 7'd49;
endmodule
