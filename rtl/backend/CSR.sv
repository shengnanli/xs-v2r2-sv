// =============================================================================
// xs_CSR_core —— CSR assembly parent 可读核。scripts/gen_csr.py 生成, 勿手改。
// 容器胶合逻辑 (寄存器/组合) 可读重写; 4 子例化 + 输出 assign 为同构接线忠实保留。
// 子: NewCSR(绿305黑盒)/IMSIC(绿305黑盒)/TrapInstMod(叶白盒)/TrapTvalMod(叶白盒)。
// =============================================================================
module xs_CSR_core(
  input         clock,
  input         reset,
  input         io_flush_valid,
  input         io_flush_bits_robIdx_flag,
  input  [7:0]  io_flush_bits_robIdx_value,
  input         io_flush_bits_ftqIdx_flag,
  input  [5:0]  io_flush_bits_ftqIdx_value,
  input  [3:0]  io_flush_bits_ftqOffset,
  input         io_flush_bits_level,
  input         io_flush_bits_cfiUpdate_backendIGPF,
  input         io_flush_bits_cfiUpdate_backendIPF,
  input         io_flush_bits_cfiUpdate_backendIAF,
  input  [63:0] io_flush_bits_fullTarget,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrl_robIdx_flag,
  input  [7:0]  io_in_bits_ctrl_robIdx_value,
  input  [7:0]  io_in_bits_ctrl_pdest,
  input         io_in_bits_ctrl_rfWen,
  input         io_in_bits_ctrl_ftqIdx_flag,
  input  [5:0]  io_in_bits_ctrl_ftqIdx_value,
  input  [3:0]  io_in_bits_ctrl_ftqOffset,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_data_imm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output        io_out_bits_ctrl_exceptionVec_2,
  output        io_out_bits_ctrl_exceptionVec_3,
  output        io_out_bits_ctrl_exceptionVec_8,
  output        io_out_bits_ctrl_exceptionVec_9,
  output        io_out_bits_ctrl_exceptionVec_10,
  output        io_out_bits_ctrl_exceptionVec_11,
  output        io_out_bits_ctrl_exceptionVec_22,
  output        io_out_bits_ctrl_flushPipe,
  output [63:0] io_out_bits_res_data,
  output        io_out_bits_res_redirect_valid,
  output        io_out_bits_res_redirect_bits_isRVC,
  output        io_out_bits_res_redirect_bits_robIdx_flag,
  output [7:0]  io_out_bits_res_redirect_bits_robIdx_value,
  output        io_out_bits_res_redirect_bits_ftqIdx_flag,
  output [5:0]  io_out_bits_res_redirect_bits_ftqIdx_value,
  output [3:0]  io_out_bits_res_redirect_bits_ftqOffset,
  output        io_out_bits_res_redirect_bits_level,
  output        io_out_bits_res_redirect_bits_interrupt,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_pc,
  output        io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
  output        io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
  output [1:0]  io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
  output        io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
  output        io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
  output [3:0]  io_out_bits_res_redirect_bits_cfiUpdate_ssp,
  output [2:0]  io_out_bits_res_redirect_bits_cfiUpdate_sctr,
  output        io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0]  io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
  output        io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0]  io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
  output        io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
  output [4:0]  io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output [6:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output [8:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output [3:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output [8:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output [6:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output [6:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output [8:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output [6:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output        io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output [2:0]  io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
  output [3:0]  io_out_bits_res_redirect_bits_cfiUpdate_ghr,
  output        io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0]  io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
  output [9:0]  io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
  output [9:0]  io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
  output        io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
  output        io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
  output        io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
  output        io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_target,
  output        io_out_bits_res_redirect_bits_cfiUpdate_taken,
  output        io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
  output [1:0]  io_out_bits_res_redirect_bits_cfiUpdate_shift,
  output        io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
  output        io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
  output        io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
  output        io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
  output [63:0] io_out_bits_res_redirect_bits_fullTarget,
  output        io_out_bits_res_redirect_bits_stFtqIdx_flag,
  output [5:0]  io_out_bits_res_redirect_bits_stFtqIdx_value,
  output [3:0]  io_out_bits_res_redirect_bits_stFtqOffset,
  output [63:0] io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
  output        io_out_bits_res_redirect_bits_debugIsCtrl,
  output        io_out_bits_res_redirect_bits_debugIsMemVio,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  [7:0]  io_csrin_hartId,
  input         io_csrin_msiInfo_valid,
  input  [10:0] io_csrin_msiInfo_bits,
  input         io_csrin_criticalErrorState,
  input         io_csrin_clintTime_valid,
  input  [63:0] io_csrin_clintTime_bits,
  input         io_csrin_l2FlushDone,
  input         io_csrin_trapInstInfo_valid,
  input  [31:0] io_csrin_trapInstInfo_bits_instr,
  input         io_csrin_trapInstInfo_bits_ftqPtr_flag,
  input  [5:0]  io_csrin_trapInstInfo_bits_ftqPtr_value,
  input  [3:0]  io_csrin_trapInstInfo_bits_ftqOffset,
  input         io_csrin_fromVecExcpMod_busy,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_0_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_1_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_2_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_3_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_4_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_5_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_6_value,
  input  [5:0]  io_csrio_perf_perfEventsFrontend_7_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_0_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_1_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_2_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_3_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_4_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_5_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_6_value,
  input  [5:0]  io_csrio_perf_perfEventsBackend_7_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_0_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_1_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_2_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_3_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_4_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_5_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_6_value,
  input  [5:0]  io_csrio_perf_perfEventsLsu_7_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_0_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_1_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_2_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_3_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_4_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_5_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_6_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_7_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_8_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_9_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_10_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_11_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_12_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_13_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_14_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_15_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_16_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_17_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_18_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_19_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_20_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_21_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_22_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_23_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_24_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_25_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_26_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_27_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_28_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_29_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_30_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_31_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_32_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_33_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_34_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_35_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_36_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_37_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_38_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_39_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_40_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_41_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_42_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_43_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_44_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_45_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_46_value,
  input  [5:0]  io_csrio_perf_perfEventsHc_47_value,
  input  [6:0]  io_csrio_perf_retiredInstr,
  output        io_csrio_criticalErrorState,
  output        io_csrio_isPerfCnt,
  input         io_csrio_fpu_fflags_valid,
  input  [4:0]  io_csrio_fpu_fflags_bits,
  input         io_csrio_fpu_dirty_fs,
  output [2:0]  io_csrio_fpu_frm,
  output [63:0] io_csrio_vpu_vstart,
  output [1:0]  io_csrio_vpu_vxrm,
  input  [63:0] io_csrio_vpu_vl,
  input         io_csrio_vpu_set_vstart_valid,
  input  [63:0] io_csrio_vpu_set_vstart_bits,
  input         io_csrio_vpu_set_vtype_valid,
  input  [63:0] io_csrio_vpu_set_vtype_bits,
  input         io_csrio_vpu_set_vxsat_valid,
  input         io_csrio_vpu_set_vxsat_bits,
  input         io_csrio_vpu_dirty_vs,
  input         io_csrio_exception_valid,
  input  [49:0] io_csrio_exception_bits_pc,
  input         io_csrio_exception_bits_exceptionVec_0,
  input         io_csrio_exception_bits_exceptionVec_1,
  input         io_csrio_exception_bits_exceptionVec_2,
  input         io_csrio_exception_bits_exceptionVec_3,
  input         io_csrio_exception_bits_exceptionVec_4,
  input         io_csrio_exception_bits_exceptionVec_5,
  input         io_csrio_exception_bits_exceptionVec_6,
  input         io_csrio_exception_bits_exceptionVec_7,
  input         io_csrio_exception_bits_exceptionVec_8,
  input         io_csrio_exception_bits_exceptionVec_9,
  input         io_csrio_exception_bits_exceptionVec_10,
  input         io_csrio_exception_bits_exceptionVec_11,
  input         io_csrio_exception_bits_exceptionVec_12,
  input         io_csrio_exception_bits_exceptionVec_13,
  input         io_csrio_exception_bits_exceptionVec_14,
  input         io_csrio_exception_bits_exceptionVec_15,
  input         io_csrio_exception_bits_exceptionVec_16,
  input         io_csrio_exception_bits_exceptionVec_17,
  input         io_csrio_exception_bits_exceptionVec_18,
  input         io_csrio_exception_bits_exceptionVec_19,
  input         io_csrio_exception_bits_exceptionVec_20,
  input         io_csrio_exception_bits_exceptionVec_21,
  input         io_csrio_exception_bits_exceptionVec_22,
  input         io_csrio_exception_bits_exceptionVec_23,
  input         io_csrio_exception_bits_isPcBkpt,
  input         io_csrio_exception_bits_isFetchMalAddr,
  input  [63:0] io_csrio_exception_bits_gpaddr,
  input         io_csrio_exception_bits_singleStep,
  input         io_csrio_exception_bits_crossPageIPFFix,
  input         io_csrio_exception_bits_isInterrupt,
  input         io_csrio_exception_bits_isHls,
  input  [3:0]  io_csrio_exception_bits_trigger,
  input         io_csrio_exception_bits_isForVSnonLeafPTE,
  input         io_csrio_robDeqPtr_flag,
  input  [7:0]  io_csrio_robDeqPtr_value,
  output [63:0] io_csrio_trapTarget_pc,
  output        io_csrio_trapTarget_raiseIPF,
  output        io_csrio_trapTarget_raiseIAF,
  output        io_csrio_trapTarget_raiseIGPF,
  output        io_csrio_interrupt,
  output        io_csrio_wfi_event,
  output [63:0] io_csrio_traceCSR_cause,
  output [49:0] io_csrio_traceCSR_tval,
  output [2:0]  io_csrio_traceCSR_lastPriv,
  output [2:0]  io_csrio_traceCSR_currentPriv,
  input  [63:0] io_csrio_memExceptionVAddr,
  input  [63:0] io_csrio_memExceptionGPAddr,
  input         io_csrio_memExceptionIsForVSnonLeafPTE,
  input         io_csrio_externalInterrupt_mtip,
  input         io_csrio_externalInterrupt_msip,
  input         io_csrio_externalInterrupt_meip,
  input         io_csrio_externalInterrupt_seip,
  input         io_csrio_externalInterrupt_debug,
  input         io_csrio_externalInterrupt_nmi_nmi_31,
  input         io_csrio_externalInterrupt_nmi_nmi_43,
  output [3:0]  io_csrio_tlb_satp_mode,
  output [15:0] io_csrio_tlb_satp_asid,
  output [43:0] io_csrio_tlb_satp_ppn,
  output        io_csrio_tlb_satp_changed,
  output [3:0]  io_csrio_tlb_vsatp_mode,
  output [15:0] io_csrio_tlb_vsatp_asid,
  output [43:0] io_csrio_tlb_vsatp_ppn,
  output        io_csrio_tlb_vsatp_changed,
  output [3:0]  io_csrio_tlb_hgatp_mode,
  output [15:0] io_csrio_tlb_hgatp_vmid,
  output [43:0] io_csrio_tlb_hgatp_ppn,
  output        io_csrio_tlb_hgatp_changed,
  output        io_csrio_tlb_priv_mxr,
  output        io_csrio_tlb_priv_sum,
  output        io_csrio_tlb_priv_vmxr,
  output        io_csrio_tlb_priv_vsum,
  output        io_csrio_tlb_priv_virt,
  output        io_csrio_tlb_priv_spvp,
  output [1:0]  io_csrio_tlb_priv_imode,
  output [1:0]  io_csrio_tlb_priv_dmode,
  output        io_csrio_tlb_mPBMTE,
  output        io_csrio_tlb_hPBMTE,
  output [1:0]  io_csrio_tlb_pmm_mseccfg,
  output [1:0]  io_csrio_tlb_pmm_menvcfg,
  output [1:0]  io_csrio_tlb_pmm_henvcfg,
  output [1:0]  io_csrio_tlb_pmm_hstatus,
  output [1:0]  io_csrio_tlb_pmm_senvcfg,
  output        io_csrio_customCtrl_pf_ctrl_l1I_pf_enable,
  output        io_csrio_customCtrl_pf_ctrl_l2_pf_enable,
  output        io_csrio_customCtrl_pf_ctrl_l1D_pf_enable,
  output        io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit,
  output        io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt,
  output        io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht,
  output [3:0]  io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold,
  output [5:0]  io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride,
  output        io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride,
  output        io_csrio_customCtrl_pf_ctrl_l2_pf_store_only,
  output        io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable,
  output        io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable,
  output        io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable,
  output [4:0]  io_csrio_customCtrl_lvpred_timeout,
  output        io_csrio_customCtrl_bp_ctrl_ubtb_enable,
  output        io_csrio_customCtrl_bp_ctrl_btb_enable,
  output        io_csrio_customCtrl_bp_ctrl_tage_enable,
  output        io_csrio_customCtrl_bp_ctrl_sc_enable,
  output        io_csrio_customCtrl_bp_ctrl_ras_enable,
  output        io_csrio_customCtrl_ldld_vio_check_enable,
  output        io_csrio_customCtrl_cache_error_enable,
  output        io_csrio_customCtrl_uncache_write_outstanding_enable,
  output        io_csrio_customCtrl_hd_misalign_st_enable,
  output        io_csrio_customCtrl_hd_misalign_ld_enable,
  output        io_csrio_customCtrl_power_down_enable,
  output        io_csrio_customCtrl_flush_l2_enable,
  output        io_csrio_customCtrl_fusion_enable,
  output        io_csrio_customCtrl_wfi_enable,
  output        io_csrio_customCtrl_distribute_csr_w_valid,
  output [11:0] io_csrio_customCtrl_distribute_csr_w_bits_addr,
  output [63:0] io_csrio_customCtrl_distribute_csr_w_bits_data,
  output        io_csrio_customCtrl_singlestep,
  output        io_csrio_customCtrl_frontend_trigger_tUpdate_valid,
  output [1:0]  io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr,
  output [1:0]  io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType,
  output        io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select,
  output [3:0]  io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action,
  output        io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain,
  output [63:0] io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2,
  output        io_csrio_customCtrl_frontend_trigger_tEnableVec_0,
  output        io_csrio_customCtrl_frontend_trigger_tEnableVec_1,
  output        io_csrio_customCtrl_frontend_trigger_tEnableVec_2,
  output        io_csrio_customCtrl_frontend_trigger_tEnableVec_3,
  output        io_csrio_customCtrl_frontend_trigger_debugMode,
  output        io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp,
  output        io_csrio_customCtrl_mem_trigger_tUpdate_valid,
  output [1:0]  io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr,
  output [1:0]  io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType,
  output        io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select,
  output [3:0]  io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action,
  output        io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain,
  output        io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store,
  output        io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load,
  output [63:0] io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2,
  output        io_csrio_customCtrl_mem_trigger_tEnableVec_0,
  output        io_csrio_customCtrl_mem_trigger_tEnableVec_1,
  output        io_csrio_customCtrl_mem_trigger_tEnableVec_2,
  output        io_csrio_customCtrl_mem_trigger_tEnableVec_3,
  output        io_csrio_customCtrl_mem_trigger_debugMode,
  output        io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp,
  output        io_csrio_customCtrl_fsIsOff,
  output        io_csrio_instrAddrTransType_bare,
  output        io_csrio_instrAddrTransType_sv39,
  output        io_csrio_instrAddrTransType_sv39x4,
  output        io_csrio_instrAddrTransType_sv48,
  output        io_csrio_instrAddrTransType_sv48x4,
  output        io_csrToDecode_illegalInst_sfenceVMA,
  output        io_csrToDecode_illegalInst_sfencePart,
  output        io_csrToDecode_illegalInst_hfenceGVMA,
  output        io_csrToDecode_illegalInst_hfenceVVMA,
  output        io_csrToDecode_illegalInst_hlsv,
  output        io_csrToDecode_illegalInst_fsIsOff,
  output        io_csrToDecode_illegalInst_vsIsOff,
  output        io_csrToDecode_illegalInst_wfi,
  output        io_csrToDecode_illegalInst_wrs_nto,
  output        io_csrToDecode_illegalInst_frm,
  output        io_csrToDecode_illegalInst_cboZ,
  output        io_csrToDecode_illegalInst_cboCF,
  output        io_csrToDecode_illegalInst_cboI,
  output        io_csrToDecode_virtualInst_sfenceVMA,
  output        io_csrToDecode_virtualInst_sfencePart,
  output        io_csrToDecode_virtualInst_hfence,
  output        io_csrToDecode_virtualInst_hlsv,
  output        io_csrToDecode_virtualInst_wfi,
  output        io_csrToDecode_virtualInst_wrs_nto,
  output        io_csrToDecode_virtualInst_cboZ,
  output        io_csrToDecode_virtualInst_cboCF,
  output        io_csrToDecode_virtualInst_cboI,
  output        io_csrToDecode_special_cboI2F,
  output        io_error_0
);

  // ===========================================================================
  //  内部信号 (子模块输出线) —— 命名与接线块一致。
  // ===========================================================================
  wire        _imsic_toCSR_rdata_valid;
  wire [63:0] _imsic_toCSR_rdata_bits;
  wire        _imsic_toCSR_illegal;
  wire [6:0]  _imsic_toCSR_pendings;
  wire [31:0] _imsic_toCSR_topeis_0;
  wire [31:0] _imsic_toCSR_topeis_1;
  wire [31:0] _imsic_toCSR_topeis_2;
  wire [63:0] _trapTvalMod_io_tval;
  wire        _trapInstMod_io_currentTrapInst_valid;
  wire [31:0] _trapInstMod_io_currentTrapInst_bits;
  wire        _csrMod_io_in_ready;
  wire        _csrMod_io_out_valid;
  wire        _csrMod_io_out_bits_EX_II;
  wire        _csrMod_io_out_bits_EX_VI;
  wire        _csrMod_io_out_bits_targetPcUpdate;
  wire [63:0] _csrMod_io_out_bits_targetPc_pc;
  wire        _csrMod_io_out_bits_targetPc_raiseIPF;
  wire        _csrMod_io_out_bits_targetPc_raiseIAF;
  wire        _csrMod_io_out_bits_targetPc_raiseIGPF;
  wire [63:0] _csrMod_io_out_bits_regOut;
  wire        _csrMod_io_out_bits_isPerfCnt;
  wire [1:0]  _csrMod_io_status_privState_PRVM;
  wire        _csrMod_io_status_privState_V;
  wire [6:0]  _csrMod_io_status_vecState_vstart;
  wire [13:0] _csrMod_io_tlb_hgatp_VMID;
  wire        _csrMod_io_toDecode_illegalInst_fsIsOff;
  wire        _csrMod_toAIA_addr_valid;
  wire [11:0] _csrMod_toAIA_addr_bits_addr;
  wire        _csrMod_toAIA_addr_bits_v;
  wire [1:0]  _csrMod_toAIA_addr_bits_prvm;
  wire [5:0]  _csrMod_toAIA_vgein;
  wire        _csrMod_toAIA_wdata_valid;
  wire [1:0]  _csrMod_toAIA_wdata_bits_op;
  wire [63:0] _csrMod_toAIA_wdata_bits_data;
  wire        _csrMod_toAIA_mClaim;
  wire        _csrMod_toAIA_sClaim;
  wire        _csrMod_toAIA_vsClaim;
  wire        _csrMod_io_error_0;

  // ===========================================================================
  //  组合派生 —— CSRI 立即数 / ecall / ebreak / 发射握手。
  // ===========================================================================
  // csri = {59'h0, imm[16:12]} : csrrwi/csrrsi/csrrci 的 5 位 zimm。
  wire [63:0] csri     = {59'h0, io_in_bits_data_imm[16:12]};
  // fuOpType[4] = 系统指令 (ecall/ebreak/xret); imm[11:0]==0 -> ECALL, ==1 -> EBREAK。
  wire        isEcall  = io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h0;
  wire        isEbreak = io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h1;
  // 本拍有新请求进 NewCSR (ready&valid), 作为各暂存寄存器的更新使能。
  wire        fire     = _csrMod_io_in_ready & io_in_valid;

  // ===========================================================================
  //  暂存/流水寄存器。
  // ===========================================================================
  reg  [11:0] waddrReg;      // distribute CSR 写地址 (imm[11:0])
  reg  [63:0] wdataReg;      // distribute CSR 写数据 (按 fuOpType 选 set/clr/imm)
  reg         robIdxReg_flag;
  reg  [7:0]  robIdxReg_value;
  // 无请求时用锁存的 robIdx (与上游 flush 比较用)。
  wire        thisRobIdx_flag  = io_in_valid ? io_in_bits_ctrl_robIdx_flag  : robIdxReg_flag;
  wire [7:0]  thisRobIdx_value = io_in_valid ? io_in_bits_ctrl_robIdx_value : robIdxReg_value;

  // TrapInstMod 输入流水: fromDecode.trapInstInfo 打一拍 valid + 一拍 bits;
  //   faultCsrUop 各字段锁存 (fire 时锁当拍, 否则保持)。
  reg         trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG;
  reg  [31:0] trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr;
  reg         trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag;
  reg  [5:0]  trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value;
  reg  [3:0]  trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset;
  reg  [8:0]  trapInstMod_io_faultCsrUop_bits_fuOpType_r;
  reg  [63:0] trapInstMod_io_faultCsrUop_bits_imm_r;
  reg         trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_flag;
  reg  [5:0]  trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_value;
  reg  [3:0]  trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset_r;

  // ecall/ebreak 例外向量按当前特权态分派 (锁存旧值供无新请求拍读)。
  reg         exceptionVec_3_r;   // EBREAK
  wire        exceptionVec_11_isModeM  = &_csrMod_io_status_privState_PRVM;      // M 态
  wire        _exceptionVec_11_T = isEcall & exceptionVec_11_isModeM;
  reg         exceptionVec_11_r;  // ecall-from-M
  wire        PrvmIsS             = _csrMod_io_status_privState_PRVM == 2'h1;
  wire        exceptionVec_9_isModeHS  = ~_csrMod_io_status_privState_V & PrvmIsS; // HS 态
  wire        _exceptionVec_9_T  = isEcall & exceptionVec_9_isModeHS;
  reg         exceptionVec_9_r;   // ecall-from-HS
  wire        exceptionVec_10_isModeVS = _csrMod_io_status_privState_V & PrvmIsS;  // VS 态
  wire        _exceptionVec_10_T = isEcall & exceptionVec_10_isModeVS;
  reg         exceptionVec_10_r;  // ecall-from-VS
  wire        exceptionVec_8_PrvmIsU    = _csrMod_io_status_privState_PRVM == 2'h0; // U 态
  wire        _exceptionVec_8_T  = isEcall & exceptionVec_8_PrvmIsU;
  reg         exceptionVec_8_r;   // ecall-from-U

  // 输出流水锁存 (fire 时锁当拍输入)。
  reg         io_out_bits_res_redirect_valid_r;
  reg         io_out_bits_res_redirect_bits_ftqIdx_r_flag;
  reg  [5:0]  io_out_bits_res_redirect_bits_ftqIdx_r_value;
  reg  [3:0]  io_out_bits_res_redirect_bits_ftqOffset_r;
  reg         io_out_bits_ctrl_robIdx_r_flag;
  reg  [7:0]  io_out_bits_ctrl_robIdx_r_value;
  reg  [7:0]  io_out_bits_ctrl_pdest_r;
  reg         io_out_bits_ctrl_rfWen_r;
  reg  [63:0] io_out_bits_perfDebugInfo_r_enqRsTime;
  reg  [63:0] io_out_bits_perfDebugInfo_r_selectTime;
  reg  [63:0] io_out_bits_perfDebugInfo_r_issueTime;
  reg         io_error_0_REG;     // error 打两拍
  reg         io_error_0_REG_1;
  reg         io_csrio_isPerfCnt_r;

  // ---- 带异步 reset 的寄存器 ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      waddrReg                                                   <= 12'h0;
      wdataReg                                                   <= 64'h0;
      trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG <= 1'h0;
      exceptionVec_3_r                                           <= 1'h0;
      exceptionVec_11_r                                          <= 1'h0;
      exceptionVec_9_r                                           <= 1'h0;
      exceptionVec_10_r                                          <= 1'h0;
      exceptionVec_8_r                                           <= 1'h0;
      io_out_bits_res_redirect_valid_r                           <= 1'h0;
      io_csrio_isPerfCnt_r                                       <= 1'h0;
    end
    else begin
      if (fire) begin
        waddrReg <= io_in_bits_data_imm[11:0];
        // wdata = 按 CSR 操作码 (fuOpType) 选择: 9=W(src), A=S(regOut|src),
        //   B=C(regOut&~src), D=WI(csri), E=SI(regOut|csri), F=CI(regOut&~csri)。
        wdataReg <=
            (io_in_bits_ctrl_fuOpType == 9'h9 ? io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hA ? _csrMod_io_out_bits_regOut | io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hB ? _csrMod_io_out_bits_regOut & ~io_in_bits_data_src_0 : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hD ? csri : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hE ? _csrMod_io_out_bits_regOut | csri : 64'h0)
          | (io_in_bits_ctrl_fuOpType == 9'hF
               ? _csrMod_io_out_bits_regOut & {59'h7FFFFFFFFFFFFFF, ~(io_in_bits_data_imm[16:12])} : 64'h0);
        exceptionVec_3_r  <= isEbreak;
        exceptionVec_11_r <= _exceptionVec_11_T;
        exceptionVec_9_r  <= _exceptionVec_9_T;
        exceptionVec_10_r <= _exceptionVec_10_T;
        exceptionVec_8_r  <= _exceptionVec_8_T;
        // redirect: fuOpType==0x10 (非 ecall/ebreak 的系统指令) 触发。
        io_out_bits_res_redirect_valid_r <=
          io_in_valid & io_in_bits_ctrl_fuOpType == 9'h10 & ~isEcall & ~isEbreak;
        io_csrio_isPerfCnt_r <= io_in_bits_ctrl_fuOpType != 9'h10;
      end
      // trapInstInfo valid 打一拍。
      trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG <= io_csrin_trapInstInfo_valid;
    end
  end

  // ---- 无 reset 的寄存器 ----
  always @(posedge clock) begin
    if (fire) begin
      robIdxReg_flag                                        <= io_in_bits_ctrl_robIdx_flag;
      robIdxReg_value                                       <= io_in_bits_ctrl_robIdx_value;
      trapInstMod_io_faultCsrUop_bits_fuOpType_r            <= io_in_bits_ctrl_fuOpType;
      trapInstMod_io_faultCsrUop_bits_imm_r                 <= io_in_bits_data_imm;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_flag  <= io_in_bits_ctrl_ftqIdx_flag;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_value <= io_in_bits_ctrl_ftqIdx_value;
      trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset_r    <= io_in_bits_ctrl_ftqOffset;
      io_out_bits_res_redirect_bits_ftqIdx_r_flag  <= io_in_bits_ctrl_ftqIdx_flag;
      io_out_bits_res_redirect_bits_ftqIdx_r_value <= io_in_bits_ctrl_ftqIdx_value;
      io_out_bits_res_redirect_bits_ftqOffset_r    <= io_in_bits_ctrl_ftqOffset;
      io_out_bits_ctrl_robIdx_r_flag  <= io_in_bits_ctrl_robIdx_flag;
      io_out_bits_ctrl_robIdx_r_value <= io_in_bits_ctrl_robIdx_value;
      io_out_bits_ctrl_pdest_r        <= io_in_bits_ctrl_pdest;
      io_out_bits_ctrl_rfWen_r        <= io_in_bits_ctrl_rfWen;
      io_out_bits_perfDebugInfo_r_enqRsTime  <= io_in_bits_perfDebugInfo_enqRsTime;
      io_out_bits_perfDebugInfo_r_selectTime <= io_in_bits_perfDebugInfo_selectTime;
      io_out_bits_perfDebugInfo_r_issueTime  <= io_in_bits_perfDebugInfo_issueTime;
    end
    if (io_csrin_trapInstInfo_valid) begin
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr        <= io_csrin_trapInstInfo_bits_instr;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag  <= io_csrin_trapInstInfo_bits_ftqPtr_flag;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value <= io_csrin_trapInstInfo_bits_ftqPtr_value;
      trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset    <= io_csrin_trapInstInfo_bits_ftqOffset;
    end
    io_error_0_REG   <= _csrMod_io_error_0;
    io_error_0_REG_1 <= io_error_0_REG;
  end

  wire _io_csrio_isPerfCnt_T_2 = fire;

  NewCSR csrMod (
    .clock                                                  (clock),
    .reset                                                  (reset),
    .platformIRP_MEIP
      (io_csrio_externalInterrupt_meip),
    .platformIRP_MTIP
      (io_csrio_externalInterrupt_mtip),
    .platformIRP_MSIP
      (io_csrio_externalInterrupt_msip),
    .platformIRP_SEIP
      (io_csrio_externalInterrupt_seip),
    .platformIRP_debugIP
      (io_csrio_externalInterrupt_debug),
    .nonMaskableIRP_NMI_43
      (io_csrio_externalInterrupt_nmi_nmi_43),
    .nonMaskableIRP_NMI_31
      (io_csrio_externalInterrupt_nmi_nmi_31),
    .io_fromTop_hartId                                      (io_csrin_hartId[5:0]),
    .io_fromTop_clintTime_valid                             (io_csrin_clintTime_valid),
    .io_fromTop_clintTime_bits                              (io_csrin_clintTime_bits),
    .io_fromTop_l2FlushDone                                 (io_csrin_l2FlushDone),
    .io_fromTop_criticalErrorState                          (io_csrin_criticalErrorState),
    .io_in_ready                                            (_csrMod_io_in_ready),
    .io_in_valid                                            (io_in_valid),
    .io_in_bits_wen
      (io_in_valid
       & (io_in_bits_ctrl_fuOpType[3] & io_in_bits_ctrl_fuOpType[1:0] == 2'h1
          | io_in_bits_ctrl_fuOpType[3] & io_in_bits_ctrl_fuOpType[1]
          & (|(io_in_bits_data_imm[16:12])))),
    .io_in_bits_ren
      (io_in_valid
       & (io_in_bits_ctrl_fuOpType[3] & io_in_bits_ctrl_fuOpType[1:0] == 2'h1
          & (|(io_in_bits_data_imm[21:17])) | io_in_bits_ctrl_fuOpType[3]
          & io_in_bits_ctrl_fuOpType[1])),
    .io_in_bits_op
      (io_in_bits_ctrl_fuOpType[1:0]),
    .io_in_bits_addr                                        (io_in_bits_data_imm[11:0]),
    .io_in_bits_src
      (io_in_bits_ctrl_fuOpType[2] ? csri : io_in_bits_data_src_0),
    .io_in_bits_wdata                                       (wdataReg),
    .io_in_bits_mnret
      (io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h702),
    .io_in_bits_mret
      (io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h302),
    .io_in_bits_sret
      (io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h102),
    .io_in_bits_dret
      (io_in_bits_ctrl_fuOpType[4] & io_in_bits_data_imm[11:0] == 12'h7B2),
    .io_in_bits_redirectFlush
      (io_flush_valid
       & (io_flush_bits_level
          & {thisRobIdx_flag,
             thisRobIdx_value} == {io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value}
          | thisRobIdx_flag ^ io_flush_bits_robIdx_flag
          ^ thisRobIdx_value > io_flush_bits_robIdx_value)),
    .io_trapInst_valid
      (_trapInstMod_io_currentTrapInst_valid),
    .io_trapInst_bits
      (_trapInstMod_io_currentTrapInst_bits),
    .io_fromMem_excpVA                                      (io_csrio_memExceptionVAddr),
    .io_fromMem_excpGPA                                     (io_csrio_memExceptionGPAddr),
    .io_fromMem_excpIsForVSnonLeafPTE
      (io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_fromRob_trap_valid                                  (io_csrio_exception_valid),
    .io_fromRob_trap_bits_pc                                (io_csrio_exception_bits_pc),
    .io_fromRob_trap_bits_pcGPA
      (io_csrio_exception_bits_gpaddr[55:0]),
    .io_fromRob_trap_bits_trapVec
      ({40'h0,
        io_csrio_exception_bits_exceptionVec_23,
        io_csrio_exception_bits_exceptionVec_22,
        io_csrio_exception_bits_exceptionVec_21,
        io_csrio_exception_bits_exceptionVec_20,
        io_csrio_exception_bits_exceptionVec_19,
        io_csrio_exception_bits_exceptionVec_18,
        io_csrio_exception_bits_exceptionVec_17,
        io_csrio_exception_bits_exceptionVec_16,
        io_csrio_exception_bits_exceptionVec_15,
        io_csrio_exception_bits_exceptionVec_14,
        io_csrio_exception_bits_exceptionVec_13,
        io_csrio_exception_bits_exceptionVec_12,
        io_csrio_exception_bits_exceptionVec_11,
        io_csrio_exception_bits_exceptionVec_10,
        io_csrio_exception_bits_exceptionVec_9,
        io_csrio_exception_bits_exceptionVec_8,
        io_csrio_exception_bits_exceptionVec_7,
        io_csrio_exception_bits_exceptionVec_6,
        io_csrio_exception_bits_exceptionVec_5,
        io_csrio_exception_bits_exceptionVec_4,
        io_csrio_exception_bits_exceptionVec_3,
        io_csrio_exception_bits_exceptionVec_2,
        io_csrio_exception_bits_exceptionVec_1,
        io_csrio_exception_bits_exceptionVec_0}),
    .io_fromRob_trap_bits_isFetchBkpt
      (io_csrio_exception_bits_isPcBkpt),
    .io_fromRob_trap_bits_singleStep
      (io_csrio_exception_bits_singleStep),
    .io_fromRob_trap_bits_trigger
      (io_csrio_exception_bits_trigger),
    .io_fromRob_trap_bits_crossPageIPFFix
      (io_csrio_exception_bits_crossPageIPFFix),
    .io_fromRob_trap_bits_isInterrupt
      (io_csrio_exception_bits_isInterrupt),
    .io_fromRob_trap_bits_isHls
      (io_csrio_exception_bits_isHls),
    .io_fromRob_trap_bits_isFetchMalAddr
      (io_csrio_exception_bits_isFetchMalAddr),
    .io_fromRob_trap_bits_isForVSnonLeafPTE
      (io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_fromRob_commit_instNum_bits                         (io_csrio_perf_retiredInstr),
    .io_fromRob_commit_fflags_valid                         (io_csrio_fpu_fflags_valid),
    .io_fromRob_commit_fflags_bits                          (io_csrio_fpu_fflags_bits),
    .io_fromRob_commit_fsDirty                              (io_csrio_fpu_dirty_fs),
    .io_fromRob_commit_vxsat_valid
      (io_csrio_vpu_set_vxsat_valid),
    .io_fromRob_commit_vxsat_bits                           (io_csrio_vpu_set_vxsat_bits),
    .io_fromRob_commit_vsDirty                              (io_csrio_vpu_dirty_vs),
    .io_fromRob_commit_vtype_valid
      (io_csrio_vpu_set_vtype_valid),
    .io_fromRob_commit_vtype_bits_VILL
      (io_csrio_vpu_set_vtype_bits[63]),
    .io_fromRob_commit_vtype_bits_VMA
      (io_csrio_vpu_set_vtype_bits[7]),
    .io_fromRob_commit_vtype_bits_VTA
      (io_csrio_vpu_set_vtype_bits[6]),
    .io_fromRob_commit_vtype_bits_VSEW
      (io_csrio_vpu_set_vtype_bits[5:3]),
    .io_fromRob_commit_vtype_bits_VLMUL
      (io_csrio_vpu_set_vtype_bits[2:0]),
    .io_fromRob_commit_vl                                   (io_csrio_vpu_vl[7:0]),
    .io_fromRob_commit_vstart_valid
      (io_csrio_vpu_set_vstart_valid),
    .io_fromRob_commit_vstart_bits
      (io_csrio_vpu_set_vstart_bits[6:0]),
    .io_fromVecExcpMod_busy
      (io_csrin_fromVecExcpMod_busy),
    .io_perf_perfEventsFrontend_0_value
      (io_csrio_perf_perfEventsFrontend_0_value),
    .io_perf_perfEventsFrontend_1_value
      (io_csrio_perf_perfEventsFrontend_1_value),
    .io_perf_perfEventsFrontend_2_value
      (io_csrio_perf_perfEventsFrontend_2_value),
    .io_perf_perfEventsFrontend_3_value
      (io_csrio_perf_perfEventsFrontend_3_value),
    .io_perf_perfEventsFrontend_4_value
      (io_csrio_perf_perfEventsFrontend_4_value),
    .io_perf_perfEventsFrontend_5_value
      (io_csrio_perf_perfEventsFrontend_5_value),
    .io_perf_perfEventsFrontend_6_value
      (io_csrio_perf_perfEventsFrontend_6_value),
    .io_perf_perfEventsFrontend_7_value
      (io_csrio_perf_perfEventsFrontend_7_value),
    .io_perf_perfEventsBackend_0_value
      (io_csrio_perf_perfEventsBackend_0_value),
    .io_perf_perfEventsBackend_1_value
      (io_csrio_perf_perfEventsBackend_1_value),
    .io_perf_perfEventsBackend_2_value
      (io_csrio_perf_perfEventsBackend_2_value),
    .io_perf_perfEventsBackend_3_value
      (io_csrio_perf_perfEventsBackend_3_value),
    .io_perf_perfEventsBackend_4_value
      (io_csrio_perf_perfEventsBackend_4_value),
    .io_perf_perfEventsBackend_5_value
      (io_csrio_perf_perfEventsBackend_5_value),
    .io_perf_perfEventsBackend_6_value
      (io_csrio_perf_perfEventsBackend_6_value),
    .io_perf_perfEventsBackend_7_value
      (io_csrio_perf_perfEventsBackend_7_value),
    .io_perf_perfEventsLsu_0_value
      (io_csrio_perf_perfEventsLsu_0_value),
    .io_perf_perfEventsLsu_1_value
      (io_csrio_perf_perfEventsLsu_1_value),
    .io_perf_perfEventsLsu_2_value
      (io_csrio_perf_perfEventsLsu_2_value),
    .io_perf_perfEventsLsu_3_value
      (io_csrio_perf_perfEventsLsu_3_value),
    .io_perf_perfEventsLsu_4_value
      (io_csrio_perf_perfEventsLsu_4_value),
    .io_perf_perfEventsLsu_5_value
      (io_csrio_perf_perfEventsLsu_5_value),
    .io_perf_perfEventsLsu_6_value
      (io_csrio_perf_perfEventsLsu_6_value),
    .io_perf_perfEventsLsu_7_value
      (io_csrio_perf_perfEventsLsu_7_value),
    .io_perf_perfEventsHc_0_value
      (io_csrio_perf_perfEventsHc_0_value),
    .io_perf_perfEventsHc_1_value
      (io_csrio_perf_perfEventsHc_1_value),
    .io_perf_perfEventsHc_2_value
      (io_csrio_perf_perfEventsHc_2_value),
    .io_perf_perfEventsHc_3_value
      (io_csrio_perf_perfEventsHc_3_value),
    .io_perf_perfEventsHc_4_value
      (io_csrio_perf_perfEventsHc_4_value),
    .io_perf_perfEventsHc_5_value
      (io_csrio_perf_perfEventsHc_5_value),
    .io_perf_perfEventsHc_6_value
      (io_csrio_perf_perfEventsHc_6_value),
    .io_perf_perfEventsHc_7_value
      (io_csrio_perf_perfEventsHc_7_value),
    .io_perf_perfEventsHc_8_value
      (io_csrio_perf_perfEventsHc_8_value),
    .io_perf_perfEventsHc_9_value
      (io_csrio_perf_perfEventsHc_9_value),
    .io_perf_perfEventsHc_10_value
      (io_csrio_perf_perfEventsHc_10_value),
    .io_perf_perfEventsHc_11_value
      (io_csrio_perf_perfEventsHc_11_value),
    .io_perf_perfEventsHc_12_value
      (io_csrio_perf_perfEventsHc_12_value),
    .io_perf_perfEventsHc_13_value
      (io_csrio_perf_perfEventsHc_13_value),
    .io_perf_perfEventsHc_14_value
      (io_csrio_perf_perfEventsHc_14_value),
    .io_perf_perfEventsHc_15_value
      (io_csrio_perf_perfEventsHc_15_value),
    .io_perf_perfEventsHc_16_value
      (io_csrio_perf_perfEventsHc_16_value),
    .io_perf_perfEventsHc_17_value
      (io_csrio_perf_perfEventsHc_17_value),
    .io_perf_perfEventsHc_18_value
      (io_csrio_perf_perfEventsHc_18_value),
    .io_perf_perfEventsHc_19_value
      (io_csrio_perf_perfEventsHc_19_value),
    .io_perf_perfEventsHc_20_value
      (io_csrio_perf_perfEventsHc_20_value),
    .io_perf_perfEventsHc_21_value
      (io_csrio_perf_perfEventsHc_21_value),
    .io_perf_perfEventsHc_22_value
      (io_csrio_perf_perfEventsHc_22_value),
    .io_perf_perfEventsHc_23_value
      (io_csrio_perf_perfEventsHc_23_value),
    .io_perf_perfEventsHc_24_value
      (io_csrio_perf_perfEventsHc_24_value),
    .io_perf_perfEventsHc_25_value
      (io_csrio_perf_perfEventsHc_25_value),
    .io_perf_perfEventsHc_26_value
      (io_csrio_perf_perfEventsHc_26_value),
    .io_perf_perfEventsHc_27_value
      (io_csrio_perf_perfEventsHc_27_value),
    .io_perf_perfEventsHc_28_value
      (io_csrio_perf_perfEventsHc_28_value),
    .io_perf_perfEventsHc_29_value
      (io_csrio_perf_perfEventsHc_29_value),
    .io_perf_perfEventsHc_30_value
      (io_csrio_perf_perfEventsHc_30_value),
    .io_perf_perfEventsHc_31_value
      (io_csrio_perf_perfEventsHc_31_value),
    .io_perf_perfEventsHc_32_value
      (io_csrio_perf_perfEventsHc_32_value),
    .io_perf_perfEventsHc_33_value
      (io_csrio_perf_perfEventsHc_33_value),
    .io_perf_perfEventsHc_34_value
      (io_csrio_perf_perfEventsHc_34_value),
    .io_perf_perfEventsHc_35_value
      (io_csrio_perf_perfEventsHc_35_value),
    .io_perf_perfEventsHc_36_value
      (io_csrio_perf_perfEventsHc_36_value),
    .io_perf_perfEventsHc_37_value
      (io_csrio_perf_perfEventsHc_37_value),
    .io_perf_perfEventsHc_38_value
      (io_csrio_perf_perfEventsHc_38_value),
    .io_perf_perfEventsHc_39_value
      (io_csrio_perf_perfEventsHc_39_value),
    .io_perf_perfEventsHc_40_value
      (io_csrio_perf_perfEventsHc_40_value),
    .io_perf_perfEventsHc_41_value
      (io_csrio_perf_perfEventsHc_41_value),
    .io_perf_perfEventsHc_42_value
      (io_csrio_perf_perfEventsHc_42_value),
    .io_perf_perfEventsHc_43_value
      (io_csrio_perf_perfEventsHc_43_value),
    .io_perf_perfEventsHc_44_value
      (io_csrio_perf_perfEventsHc_44_value),
    .io_perf_perfEventsHc_45_value
      (io_csrio_perf_perfEventsHc_45_value),
    .io_perf_perfEventsHc_46_value
      (io_csrio_perf_perfEventsHc_46_value),
    .io_perf_perfEventsHc_47_value
      (io_csrio_perf_perfEventsHc_47_value),
    .io_out_ready                                           (io_out_ready),
    .io_out_valid                                           (_csrMod_io_out_valid),
    .io_out_bits_EX_II                                      (_csrMod_io_out_bits_EX_II),
    .io_out_bits_EX_VI                                      (_csrMod_io_out_bits_EX_VI),
    .io_out_bits_flushPipe                                  (io_out_bits_ctrl_flushPipe),
    .io_out_bits_rData                                      (io_out_bits_res_data),
    .io_out_bits_targetPcUpdate
      (_csrMod_io_out_bits_targetPcUpdate),
    .io_out_bits_targetPc_pc
      (_csrMod_io_out_bits_targetPc_pc),
    .io_out_bits_targetPc_raiseIPF
      (_csrMod_io_out_bits_targetPc_raiseIPF),
    .io_out_bits_targetPc_raiseIAF
      (_csrMod_io_out_bits_targetPc_raiseIAF),
    .io_out_bits_targetPc_raiseIGPF
      (_csrMod_io_out_bits_targetPc_raiseIGPF),
    .io_out_bits_regOut                                     (_csrMod_io_out_bits_regOut),
    .io_out_bits_isPerfCnt
      (_csrMod_io_out_bits_isPerfCnt),
    .io_status_privState_PRVM
      (_csrMod_io_status_privState_PRVM),
    .io_status_privState_V
      (_csrMod_io_status_privState_V),
    .io_status_interrupt                                    (io_csrio_interrupt),
    .io_status_wfiEvent                                     (io_csrio_wfi_event),
    .io_status_fpState_frm                                  (io_csrio_fpu_frm),
    .io_status_vecState_vstart
      (_csrMod_io_status_vecState_vstart),
    .io_status_vecState_vxrm                                (io_csrio_vpu_vxrm),
    .io_status_singleStepFlag
      (io_csrio_customCtrl_singlestep),
    .io_status_frontendTrigger_tUpdate_valid
      (io_csrio_customCtrl_frontend_trigger_tUpdate_valid),
    .io_status_frontendTrigger_tUpdate_bits_addr
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr),
    .io_status_frontendTrigger_tUpdate_bits_tdata_matchType
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_status_frontendTrigger_tUpdate_bits_tdata_select
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select),
    .io_status_frontendTrigger_tUpdate_bits_tdata_action
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action),
    .io_status_frontendTrigger_tUpdate_bits_tdata_chain
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2
      (io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_status_frontendTrigger_tEnableVec_0
      (io_csrio_customCtrl_frontend_trigger_tEnableVec_0),
    .io_status_frontendTrigger_tEnableVec_1
      (io_csrio_customCtrl_frontend_trigger_tEnableVec_1),
    .io_status_frontendTrigger_tEnableVec_2
      (io_csrio_customCtrl_frontend_trigger_tEnableVec_2),
    .io_status_frontendTrigger_tEnableVec_3
      (io_csrio_customCtrl_frontend_trigger_tEnableVec_3),
    .io_status_frontendTrigger_debugMode
      (io_csrio_customCtrl_frontend_trigger_debugMode),
    .io_status_frontendTrigger_triggerCanRaiseBpExp
      (io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp),
    .io_status_memTrigger_tUpdate_valid
      (io_csrio_customCtrl_mem_trigger_tUpdate_valid),
    .io_status_memTrigger_tUpdate_bits_addr
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr),
    .io_status_memTrigger_tUpdate_bits_tdata_matchType
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_status_memTrigger_tUpdate_bits_tdata_select
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_status_memTrigger_tUpdate_bits_tdata_action
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_status_memTrigger_tUpdate_bits_tdata_chain
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_status_memTrigger_tUpdate_bits_tdata_store
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_status_memTrigger_tUpdate_bits_tdata_load
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_status_memTrigger_tUpdate_bits_tdata_tdata2
      (io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_status_memTrigger_tEnableVec_0
      (io_csrio_customCtrl_mem_trigger_tEnableVec_0),
    .io_status_memTrigger_tEnableVec_1
      (io_csrio_customCtrl_mem_trigger_tEnableVec_1),
    .io_status_memTrigger_tEnableVec_2
      (io_csrio_customCtrl_mem_trigger_tEnableVec_2),
    .io_status_memTrigger_tEnableVec_3
      (io_csrio_customCtrl_mem_trigger_tEnableVec_3),
    .io_status_memTrigger_debugMode
      (io_csrio_customCtrl_mem_trigger_debugMode),
    .io_status_memTrigger_triggerCanRaiseBpExp
      (io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_status_instrAddrTransType_bare
      (io_csrio_instrAddrTransType_bare),
    .io_status_instrAddrTransType_sv39
      (io_csrio_instrAddrTransType_sv39),
    .io_status_instrAddrTransType_sv39x4
      (io_csrio_instrAddrTransType_sv39x4),
    .io_status_instrAddrTransType_sv48
      (io_csrio_instrAddrTransType_sv48),
    .io_status_instrAddrTransType_sv48x4
      (io_csrio_instrAddrTransType_sv48x4),
    .io_status_traceCSR_cause                               (io_csrio_traceCSR_cause),
    .io_status_traceCSR_tval                                (io_csrio_traceCSR_tval),
    .io_status_traceCSR_lastPriv                            (io_csrio_traceCSR_lastPriv),
    .io_status_traceCSR_currentPriv
      (io_csrio_traceCSR_currentPriv),
    .io_status_custom_pf_ctrl_l1I_pf_enable
      (io_csrio_customCtrl_pf_ctrl_l1I_pf_enable),
    .io_status_custom_pf_ctrl_l2_pf_enable
      (io_csrio_customCtrl_pf_ctrl_l2_pf_enable),
    .io_status_custom_pf_ctrl_l1D_pf_enable
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable),
    .io_status_custom_pf_ctrl_l1D_pf_train_on_hit
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit),
    .io_status_custom_pf_ctrl_l1D_pf_enable_agt
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt),
    .io_status_custom_pf_ctrl_l1D_pf_enable_pht
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht),
    .io_status_custom_pf_ctrl_l1D_pf_active_threshold
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold),
    .io_status_custom_pf_ctrl_l1D_pf_active_stride
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride),
    .io_status_custom_pf_ctrl_l1D_pf_enable_stride
      (io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride),
    .io_status_custom_pf_ctrl_l2_pf_store_only
      (io_csrio_customCtrl_pf_ctrl_l2_pf_store_only),
    .io_status_custom_pf_ctrl_l2_pf_recv_enable
      (io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable),
    .io_status_custom_pf_ctrl_l2_pf_pbop_enable
      (io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable),
    .io_status_custom_pf_ctrl_l2_pf_vbop_enable
      (io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable),
    .io_status_custom_lvpred_timeout
      (io_csrio_customCtrl_lvpred_timeout),
    .io_status_custom_bp_ctrl_ubtb_enable
      (io_csrio_customCtrl_bp_ctrl_ubtb_enable),
    .io_status_custom_bp_ctrl_btb_enable
      (io_csrio_customCtrl_bp_ctrl_btb_enable),
    .io_status_custom_bp_ctrl_tage_enable
      (io_csrio_customCtrl_bp_ctrl_tage_enable),
    .io_status_custom_bp_ctrl_sc_enable
      (io_csrio_customCtrl_bp_ctrl_sc_enable),
    .io_status_custom_bp_ctrl_ras_enable
      (io_csrio_customCtrl_bp_ctrl_ras_enable),
    .io_status_custom_ldld_vio_check_enable
      (io_csrio_customCtrl_ldld_vio_check_enable),
    .io_status_custom_cache_error_enable
      (io_csrio_customCtrl_cache_error_enable),
    .io_status_custom_uncache_write_outstanding_enable
      (io_csrio_customCtrl_uncache_write_outstanding_enable),
    .io_status_custom_hd_misalign_st_enable
      (io_csrio_customCtrl_hd_misalign_st_enable),
    .io_status_custom_hd_misalign_ld_enable
      (io_csrio_customCtrl_hd_misalign_ld_enable),
    .io_status_custom_power_down_enable
      (io_csrio_customCtrl_power_down_enable),
    .io_status_custom_flush_l2_enable
      (io_csrio_customCtrl_flush_l2_enable),
    .io_status_custom_fusion_enable
      (io_csrio_customCtrl_fusion_enable),
    .io_status_custom_wfi_enable
      (io_csrio_customCtrl_wfi_enable),
    .io_status_criticalErrorState                           (io_csrio_criticalErrorState),
    .io_tlb_satpASIDChanged                                 (io_csrio_tlb_satp_changed),
    .io_tlb_vsatpASIDChanged                                (io_csrio_tlb_vsatp_changed),
    .io_tlb_hgatpVMIDChanged                                (io_csrio_tlb_hgatp_changed),
    .io_tlb_satp_MODE                                       (io_csrio_tlb_satp_mode),
    .io_tlb_satp_ASID                                       (io_csrio_tlb_satp_asid),
    .io_tlb_satp_PPN                                        (io_csrio_tlb_satp_ppn),
    .io_tlb_vsatp_MODE                                      (io_csrio_tlb_vsatp_mode),
    .io_tlb_vsatp_ASID                                      (io_csrio_tlb_vsatp_asid),
    .io_tlb_vsatp_PPN                                       (io_csrio_tlb_vsatp_ppn),
    .io_tlb_hgatp_MODE                                      (io_csrio_tlb_hgatp_mode),
    .io_tlb_hgatp_VMID                                      (_csrMod_io_tlb_hgatp_VMID),
    .io_tlb_hgatp_PPN                                       (io_csrio_tlb_hgatp_ppn),
    .io_tlb_mxr                                             (io_csrio_tlb_priv_mxr),
    .io_tlb_sum                                             (io_csrio_tlb_priv_sum),
    .io_tlb_vmxr                                            (io_csrio_tlb_priv_vmxr),
    .io_tlb_vsum                                            (io_csrio_tlb_priv_vsum),
    .io_tlb_spvp                                            (io_csrio_tlb_priv_spvp),
    .io_tlb_imode                                           (io_csrio_tlb_priv_imode),
    .io_tlb_dmode                                           (io_csrio_tlb_priv_dmode),
    .io_tlb_dvirt                                           (io_csrio_tlb_priv_virt),
    .io_tlb_mPBMTE                                          (io_csrio_tlb_mPBMTE),
    .io_tlb_hPBMTE                                          (io_csrio_tlb_hPBMTE),
    .io_tlb_pmm_mseccfg                                     (io_csrio_tlb_pmm_mseccfg),
    .io_tlb_pmm_menvcfg                                     (io_csrio_tlb_pmm_menvcfg),
    .io_tlb_pmm_henvcfg                                     (io_csrio_tlb_pmm_henvcfg),
    .io_tlb_pmm_hstatus                                     (io_csrio_tlb_pmm_hstatus),
    .io_tlb_pmm_senvcfg                                     (io_csrio_tlb_pmm_senvcfg),
    .io_toDecode_illegalInst_sfenceVMA
      (io_csrToDecode_illegalInst_sfenceVMA),
    .io_toDecode_illegalInst_sfencePart
      (io_csrToDecode_illegalInst_sfencePart),
    .io_toDecode_illegalInst_hfenceGVMA
      (io_csrToDecode_illegalInst_hfenceGVMA),
    .io_toDecode_illegalInst_hfenceVVMA
      (io_csrToDecode_illegalInst_hfenceVVMA),
    .io_toDecode_illegalInst_hlsv
      (io_csrToDecode_illegalInst_hlsv),
    .io_toDecode_illegalInst_fsIsOff
      (_csrMod_io_toDecode_illegalInst_fsIsOff),
    .io_toDecode_illegalInst_vsIsOff
      (io_csrToDecode_illegalInst_vsIsOff),
    .io_toDecode_illegalInst_wfi
      (io_csrToDecode_illegalInst_wfi),
    .io_toDecode_illegalInst_wrs_nto
      (io_csrToDecode_illegalInst_wrs_nto),
    .io_toDecode_illegalInst_frm
      (io_csrToDecode_illegalInst_frm),
    .io_toDecode_illegalInst_cboZ
      (io_csrToDecode_illegalInst_cboZ),
    .io_toDecode_illegalInst_cboCF
      (io_csrToDecode_illegalInst_cboCF),
    .io_toDecode_illegalInst_cboI
      (io_csrToDecode_illegalInst_cboI),
    .io_toDecode_virtualInst_sfenceVMA
      (io_csrToDecode_virtualInst_sfenceVMA),
    .io_toDecode_virtualInst_sfencePart
      (io_csrToDecode_virtualInst_sfencePart),
    .io_toDecode_virtualInst_hfence
      (io_csrToDecode_virtualInst_hfence),
    .io_toDecode_virtualInst_hlsv
      (io_csrToDecode_virtualInst_hlsv),
    .io_toDecode_virtualInst_wfi
      (io_csrToDecode_virtualInst_wfi),
    .io_toDecode_virtualInst_wrs_nto
      (io_csrToDecode_virtualInst_wrs_nto),
    .io_toDecode_virtualInst_cboZ
      (io_csrToDecode_virtualInst_cboZ),
    .io_toDecode_virtualInst_cboCF
      (io_csrToDecode_virtualInst_cboCF),
    .io_toDecode_virtualInst_cboI
      (io_csrToDecode_virtualInst_cboI),
    .io_toDecode_special_cboI2F
      (io_csrToDecode_special_cboI2F),
    .io_fetchMalTval                                        (_trapTvalMod_io_tval),
    .io_distributedWenLegal
      (io_csrio_customCtrl_distribute_csr_w_valid),
    .toAIA_addr_valid                                       (_csrMod_toAIA_addr_valid),
    .toAIA_addr_bits_addr
      (_csrMod_toAIA_addr_bits_addr),
    .toAIA_addr_bits_v                                      (_csrMod_toAIA_addr_bits_v),
    .toAIA_addr_bits_prvm
      (_csrMod_toAIA_addr_bits_prvm),
    .toAIA_vgein                                            (_csrMod_toAIA_vgein),
    .toAIA_wdata_valid                                      (_csrMod_toAIA_wdata_valid),
    .toAIA_wdata_bits_op                                    (_csrMod_toAIA_wdata_bits_op),
    .toAIA_wdata_bits_data
      (_csrMod_toAIA_wdata_bits_data),
    .toAIA_mClaim                                           (_csrMod_toAIA_mClaim),
    .toAIA_sClaim                                           (_csrMod_toAIA_sClaim),
    .toAIA_vsClaim                                          (_csrMod_toAIA_vsClaim),
    .fromAIA_rdata_valid                                    (_imsic_toCSR_rdata_valid),
    .fromAIA_rdata_bits_data                                (_imsic_toCSR_rdata_bits),
    .fromAIA_rdata_bits_illegal                             (_imsic_toCSR_illegal),
    .fromAIA_meip                                           (_imsic_toCSR_pendings[0]),
    .fromAIA_seip                                           (_imsic_toCSR_pendings[1]),
    .fromAIA_vseip                                          (_imsic_toCSR_pendings[6:2]),
    .fromAIA_mtopei_IID
      (_imsic_toCSR_topeis_0[26:16]),
    .fromAIA_mtopei_IPRIO                                   (_imsic_toCSR_topeis_0[10:0]),
    .fromAIA_stopei_IID
      (_imsic_toCSR_topeis_1[26:16]),
    .fromAIA_stopei_IPRIO                                   (_imsic_toCSR_topeis_1[10:0]),
    .fromAIA_vstopei_IID
      (_imsic_toCSR_topeis_2[26:16]),
    .fromAIA_vstopei_IPRIO                                  (_imsic_toCSR_topeis_2[10:0]),
    .io_error_0                                             (_csrMod_io_error_0)
  );
  TrapInstMod trapInstMod (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_fromDecode_trapInstInfo_valid
      (trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG),
    .io_fromDecode_trapInstInfo_bits_instr
      (trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_flag
      (trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag),
    .io_fromDecode_trapInstInfo_bits_ftqPtr_value
      (trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value),
    .io_fromDecode_trapInstInfo_bits_ftqOffset
      (trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset),
    .io_fromRob_flush_valid                       (io_flush_valid),
    .io_fromRob_flush_bits_ftqPtr_flag            (io_flush_bits_ftqIdx_flag),
    .io_fromRob_flush_bits_ftqPtr_value           (io_flush_bits_ftqIdx_value),
    .io_fromRob_flush_bits_ftqOffset              (io_flush_bits_ftqOffset),
    .io_fromRob_isInterrupt_valid                 (io_csrio_exception_valid),
    .io_fromRob_isInterrupt_bits                  (io_csrio_exception_bits_isInterrupt),
    .io_faultCsrUop_valid
      (_csrMod_io_out_valid & (_csrMod_io_out_bits_EX_II | _csrMod_io_out_bits_EX_VI)),
    .io_faultCsrUop_bits_fuOpType
      (_io_csrio_isPerfCnt_T_2
         ? io_in_bits_ctrl_fuOpType
         : trapInstMod_io_faultCsrUop_bits_fuOpType_r),
    .io_faultCsrUop_bits_imm
      (_io_csrio_isPerfCnt_T_2
         ? io_in_bits_data_imm[21:0]
         : trapInstMod_io_faultCsrUop_bits_imm_r[21:0]),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_flag
      (_io_csrio_isPerfCnt_T_2
         ? io_in_bits_ctrl_ftqIdx_flag
         : trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_flag),
    .io_faultCsrUop_bits_ftqInfo_ftqPtr_value
      (_io_csrio_isPerfCnt_T_2
         ? io_in_bits_ctrl_ftqIdx_value
         : trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqPtr_r_value),
    .io_faultCsrUop_bits_ftqInfo_ftqOffset
      (_io_csrio_isPerfCnt_T_2
         ? io_in_bits_ctrl_ftqOffset
         : trapInstMod_io_faultCsrUop_bits_ftqInfo_ftqOffset_r),
    .io_readClear
      (io_csrio_exception_valid & ~io_csrio_exception_bits_isInterrupt
       & (io_csrio_exception_bits_exceptionVec_2
          | io_csrio_exception_bits_exceptionVec_22)),
    .io_currentTrapInst_valid                     (_trapInstMod_io_currentTrapInst_valid),
    .io_currentTrapInst_bits                      (_trapInstMod_io_currentTrapInst_bits)
  );
  TrapTvalMod trapTvalMod (
    .clock                                             (clock),
    .reset                                             (reset),
    .io_fromCtrlBlock_flush_valid                      (io_flush_valid),
    .io_fromCtrlBlock_flush_bits_robIdx_flag           (io_flush_bits_robIdx_flag),
    .io_fromCtrlBlock_flush_bits_robIdx_value          (io_flush_bits_robIdx_value),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIGPF
      (io_flush_bits_cfiUpdate_backendIGPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIPF
      (io_flush_bits_cfiUpdate_backendIPF),
    .io_fromCtrlBlock_flush_bits_cfiUpdate_backendIAF
      (io_flush_bits_cfiUpdate_backendIAF),
    .io_fromCtrlBlock_flush_bits_fullTarget            (io_flush_bits_fullTarget),
    .io_fromCtrlBlock_robDeqPtr_flag                   (io_csrio_robDeqPtr_flag),
    .io_fromCtrlBlock_robDeqPtr_value                  (io_csrio_robDeqPtr_value),
    .io_targetPc_valid
      (_csrMod_io_out_bits_targetPcUpdate),
    .io_targetPc_bits_pc                               (_csrMod_io_out_bits_targetPc_pc),
    .io_targetPc_bits_raiseIPF
      (_csrMod_io_out_bits_targetPc_raiseIPF),
    .io_targetPc_bits_raiseIAF
      (_csrMod_io_out_bits_targetPc_raiseIAF),
    .io_targetPc_bits_raiseIGPF
      (_csrMod_io_out_bits_targetPc_raiseIGPF),
    .io_clear
      (io_csrio_exception_valid & io_csrio_exception_bits_isFetchMalAddr),
    .io_tval                                           (_trapTvalMod_io_tval)
  );
  IMSIC imsic (
    .clock                   (clock),
    .reset                   (reset),
    .toCSR_rdata_valid       (_imsic_toCSR_rdata_valid),
    .toCSR_rdata_bits        (_imsic_toCSR_rdata_bits),
    .toCSR_illegal           (_imsic_toCSR_illegal),
    .toCSR_pendings          (_imsic_toCSR_pendings),
    .toCSR_topeis_0          (_imsic_toCSR_topeis_0),
    .toCSR_topeis_1          (_imsic_toCSR_topeis_1),
    .toCSR_topeis_2          (_imsic_toCSR_topeis_2),
    .fromCSR_addr_valid      (_csrMod_toAIA_addr_valid),
    .fromCSR_addr_bits_addr  (_csrMod_toAIA_addr_bits_addr),
    .fromCSR_addr_bits_virt  (_csrMod_toAIA_addr_bits_v),
    .fromCSR_addr_bits_priv  (_csrMod_toAIA_addr_bits_prvm),
    .fromCSR_vgein           (_csrMod_toAIA_vgein),
    .fromCSR_wdata_valid     (_csrMod_toAIA_wdata_valid),
    .fromCSR_wdata_bits_op   (_csrMod_toAIA_wdata_bits_op),
    .fromCSR_wdata_bits_data (_csrMod_toAIA_wdata_bits_data),
    .fromCSR_claims_0        (_csrMod_toAIA_mClaim),
    .fromCSR_claims_1        (_csrMod_toAIA_sClaim),
    .fromCSR_claims_2        (_csrMod_toAIA_vsClaim),
    .msiio_vld_req           (io_csrin_msiInfo_valid),
    .msiio_data              (io_csrin_msiInfo_bits)
  );
  assign io_in_ready = _csrMod_io_in_ready;
  assign io_out_valid = _csrMod_io_out_valid;
  assign io_out_bits_ctrl_robIdx_flag = io_out_bits_ctrl_robIdx_r_flag;
  assign io_out_bits_ctrl_robIdx_value = io_out_bits_ctrl_robIdx_r_value;
  assign io_out_bits_ctrl_pdest = io_out_bits_ctrl_pdest_r;
  assign io_out_bits_ctrl_rfWen = io_out_bits_ctrl_rfWen_r;
  assign io_out_bits_ctrl_exceptionVec_2 = _csrMod_io_out_bits_EX_II;
  assign io_out_bits_ctrl_exceptionVec_3 =
    _io_csrio_isPerfCnt_T_2 ? isEbreak : exceptionVec_3_r;
  assign io_out_bits_ctrl_exceptionVec_8 =
    _io_csrio_isPerfCnt_T_2 ? _exceptionVec_8_T : exceptionVec_8_r;
  assign io_out_bits_ctrl_exceptionVec_9 =
    _io_csrio_isPerfCnt_T_2 ? _exceptionVec_9_T : exceptionVec_9_r;
  assign io_out_bits_ctrl_exceptionVec_10 =
    _io_csrio_isPerfCnt_T_2 ? _exceptionVec_10_T : exceptionVec_10_r;
  assign io_out_bits_ctrl_exceptionVec_11 =
    _io_csrio_isPerfCnt_T_2 ? _exceptionVec_11_T : exceptionVec_11_r;
  assign io_out_bits_ctrl_exceptionVec_22 = _csrMod_io_out_bits_EX_VI;
  assign io_out_bits_res_redirect_valid =
    _csrMod_io_out_valid & io_out_bits_res_redirect_valid_r;
  assign io_out_bits_res_redirect_bits_isRVC = 1'h0;
  assign io_out_bits_res_redirect_bits_robIdx_flag = robIdxReg_flag;
  assign io_out_bits_res_redirect_bits_robIdx_value = robIdxReg_value;
  assign io_out_bits_res_redirect_bits_ftqIdx_flag =
    io_out_bits_res_redirect_bits_ftqIdx_r_flag;
  assign io_out_bits_res_redirect_bits_ftqIdx_value =
    io_out_bits_res_redirect_bits_ftqIdx_r_value;
  assign io_out_bits_res_redirect_bits_ftqOffset =
    io_out_bits_res_redirect_bits_ftqOffset_r;
  assign io_out_bits_res_redirect_bits_level = 1'h0;
  assign io_out_bits_res_redirect_bits_interrupt = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pc = 50'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_valid = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_brType = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ssp = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sctr = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_topAddr = 50'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ghr = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_br_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_jr_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sc_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_predTaken = 1'h1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_target =
    _csrMod_io_out_bits_targetPc_pc[49:0];
  assign io_out_bits_res_redirect_bits_cfiUpdate_taken = 1'h1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_isMisPred = 1'h1;
  assign io_out_bits_res_redirect_bits_cfiUpdate_shift = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF =
    _csrMod_io_out_bits_targetPc_raiseIGPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIPF =
    _csrMod_io_out_bits_targetPc_raiseIPF;
  assign io_out_bits_res_redirect_bits_cfiUpdate_backendIAF =
    _csrMod_io_out_bits_targetPc_raiseIAF;
  assign io_out_bits_res_redirect_bits_fullTarget = 64'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_value = 6'h0;
  assign io_out_bits_res_redirect_bits_stFtqOffset = 4'h0;
  assign io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id = 64'h0;
  assign io_out_bits_res_redirect_bits_debugIsCtrl = 1'h0;
  assign io_out_bits_res_redirect_bits_debugIsMemVio = 1'h0;
  assign io_out_bits_perfDebugInfo_enqRsTime = io_out_bits_perfDebugInfo_r_enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime = io_out_bits_perfDebugInfo_r_selectTime;
  assign io_out_bits_perfDebugInfo_issueTime = io_out_bits_perfDebugInfo_r_issueTime;
  assign io_csrio_isPerfCnt =
    _csrMod_io_out_valid & _csrMod_io_out_bits_isPerfCnt & io_csrio_isPerfCnt_r;
  assign io_csrio_vpu_vstart = {57'h0, _csrMod_io_status_vecState_vstart};
  assign io_csrio_trapTarget_pc = _csrMod_io_out_bits_targetPc_pc;
  assign io_csrio_trapTarget_raiseIPF = _csrMod_io_out_bits_targetPc_raiseIPF;
  assign io_csrio_trapTarget_raiseIAF = _csrMod_io_out_bits_targetPc_raiseIAF;
  assign io_csrio_trapTarget_raiseIGPF = _csrMod_io_out_bits_targetPc_raiseIGPF;
  assign io_csrio_tlb_hgatp_vmid = {2'h0, _csrMod_io_tlb_hgatp_VMID};
  assign io_csrio_customCtrl_distribute_csr_w_bits_addr = waddrReg;
  assign io_csrio_customCtrl_distribute_csr_w_bits_data = wdataReg;
  assign io_csrio_customCtrl_fsIsOff = _csrMod_io_toDecode_illegalInst_fsIsOff;
  assign io_csrToDecode_illegalInst_fsIsOff = _csrMod_io_toDecode_illegalInst_fsIsOff;
  assign io_error_0 = io_error_0_REG_1;
endmodule
