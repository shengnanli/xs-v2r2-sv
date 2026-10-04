// NewCSR —— 香山 V2 的 CSR 单元（控制与状态寄存器堆 + 特权态机 + trap/xRET 处理）
// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala（class NewCSR）
//
// ┌─ 结构 ──────────────────────────────────────────────────────────────────────────┐
// │ 每个 CSR 是一个独立子模块（MstatusModule、SepcModule ...，共 410 个实例），寄存器 │
// │ 本身、字段的 WARL 规则、trap/xRET 时的更新都在子模块里。本模块只做"胶合"：       │
// │   1. 特权态 PRVM/V、调试态 debugMode 等少量全局状态寄存器；                       │
// │   2. CSR 地址译码 → 每个 CSR 的写使能 wen_<csr> 与读选择 hit_<csr>；              │
// │   3. 读数据 Mux（rdata）与"寄存器字段原值" Mux（regOut）；                        │
// │   4. 权限检查（CSRPermitModule）、trap/xRET 事件模块的 valid 与公共输入；         │
// │   5. IMSIC 间接访问的小状态机、输出保持（DataHoldBypass）、flushPipe 判定；       │
// │   6. 送往译码/TLB/前端/AIA/difftest 的各类状态输出。                               │
// └──────────────────────────────────────────────────────────────────────────────────┘
//
// 时序要点：
//   * 写是"晚一拍"的：本拍 permitMod 判定写合法（hasLegalWen），打一拍得 wen_legal_q，
//     下一拍用 wen_legal_q & 当拍地址命中 去写子模块，写数据也取当拍 io_in_bits_wdata
//     （Scala: wBundle.wen := GatedValidRegNext(wenLegal) && addr === id）。
//   * 读是当拍的：rdata 在请求被接收那一拍（io.in.fire）锁进 io_out_bits_rData 的保持寄存器。
//   * VS 态访问 S 级 CSR 地址时实际访问 vs* 版本（vsMapS）；对应的 s* CSR 在 VS 态不命中。
//
// 文件组织：
//   GENERATED(newcsr-ports / childnets / regout / insts) 由 scripts/gen_newcsr.py 从 golden
//   端口表与实例连线机械产出（只有连线，无逻辑）；其余全部手写，按功能分节。
//
// bug-for-bug 怪癖（照 golden，不"修"）：
//   * 退休提交信息（fsDirty/vsDirty/vstart/fflags/vxsat/vtype）在 Scala 里是对每个消费者
//     模块各 RegNext 一次，所以 mstatus/vsstatus/vstart 各有一套功能相同的寄存器 —— 照留。
//   * difftest 的"变化检测"用了两次 RegNext(x)（一次判下降、一次判上升），golden 因此每个
//     信号两份寄存器 —— 照留，并沿用 golden 寄存器名，方便等价检查按名配对。
//   * permitMod 的 csrAccess.ren 接的是 ren & valid（ren 本身已含 valid，多与一次）。
//   * difftest interrupt/exception 寄存器 golden 存 63 位、输出只用低 32 位；本实现只存 32 位
//     （高 31 位在 golden 里是读不到的死存储，见 verif/dead_ref/NewCSR.json）。
//   * CommitIDModule / PrintCommitIDModule：纯仿真打印 git SHA，综合口径无任何可观测点。
module NewCSR(
// BEGIN GENERATED(newcsr-ports) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  input           clock,
  input           reset,
  input           platformIRP_MEIP,
  input           platformIRP_MTIP,
  input           platformIRP_MSIP,
  input           platformIRP_SEIP,
  input           platformIRP_debugIP,
  input           nonMaskableIRP_NMI_43,
  input           nonMaskableIRP_NMI_31,
  input  [5:0]    io_fromTop_hartId,
  input           io_fromTop_clintTime_valid,
  input  [63:0]   io_fromTop_clintTime_bits,
  input           io_fromTop_l2FlushDone,
  input           io_fromTop_criticalErrorState,
  output          io_in_ready,
  input           io_in_valid,
  input           io_in_bits_wen,
  input           io_in_bits_ren,
  input  [1:0]    io_in_bits_op,
  input  [11:0]   io_in_bits_addr,
  input  [63:0]   io_in_bits_src,
  input  [63:0]   io_in_bits_wdata,
  input           io_in_bits_mnret,
  input           io_in_bits_mret,
  input           io_in_bits_sret,
  input           io_in_bits_dret,
  input           io_in_bits_redirectFlush,
  input           io_trapInst_valid,
  input  [31:0]   io_trapInst_bits,
  input  [63:0]   io_fromMem_excpVA,
  input  [63:0]   io_fromMem_excpGPA,
  input           io_fromMem_excpIsForVSnonLeafPTE,
  input           io_fromRob_trap_valid,
  input  [49:0]   io_fromRob_trap_bits_pc,
  input  [55:0]   io_fromRob_trap_bits_pcGPA,
  input  [31:0]   io_fromRob_trap_bits_instr,
  input  [63:0]   io_fromRob_trap_bits_trapVec,
  input           io_fromRob_trap_bits_isFetchBkpt,
  input           io_fromRob_trap_bits_singleStep,
  input  [3:0]    io_fromRob_trap_bits_trigger,
  input           io_fromRob_trap_bits_crossPageIPFFix,
  input           io_fromRob_trap_bits_isInterrupt,
  input           io_fromRob_trap_bits_isHls,
  input           io_fromRob_trap_bits_isFetchMalAddr,
  input           io_fromRob_trap_bits_isForVSnonLeafPTE,
  input           io_fromRob_trap_bits_satpFlushFirstFetchFault,
  input  [6:0]    io_fromRob_commit_instNum_bits,
  input           io_fromRob_commit_fflags_valid,
  input  [4:0]    io_fromRob_commit_fflags_bits,
  input           io_fromRob_commit_fsDirty,
  input           io_fromRob_commit_vxsat_valid,
  input           io_fromRob_commit_vxsat_bits,
  input           io_fromRob_commit_vsDirty,
  input           io_fromRob_commit_vtype_valid,
  input           io_fromRob_commit_vtype_bits_VILL,
  input           io_fromRob_commit_vtype_bits_VMA,
  input           io_fromRob_commit_vtype_bits_VTA,
  input  [2:0]    io_fromRob_commit_vtype_bits_VSEW,
  input  [2:0]    io_fromRob_commit_vtype_bits_VLMUL,
  input  [7:0]    io_fromRob_commit_vl,
  input           io_fromRob_commit_vstart_valid,
  input  [6:0]    io_fromRob_commit_vstart_bits,
  input           io_fromVecExcpMod_busy,
  input  [5:0]    io_perf_perfEventsFrontend_0_value,
  input  [5:0]    io_perf_perfEventsFrontend_1_value,
  input  [5:0]    io_perf_perfEventsFrontend_2_value,
  input  [5:0]    io_perf_perfEventsFrontend_3_value,
  input  [5:0]    io_perf_perfEventsFrontend_4_value,
  input  [5:0]    io_perf_perfEventsFrontend_5_value,
  input  [5:0]    io_perf_perfEventsFrontend_6_value,
  input  [5:0]    io_perf_perfEventsFrontend_7_value,
  input  [5:0]    io_perf_perfEventsBackend_0_value,
  input  [5:0]    io_perf_perfEventsBackend_1_value,
  input  [5:0]    io_perf_perfEventsBackend_2_value,
  input  [5:0]    io_perf_perfEventsBackend_3_value,
  input  [5:0]    io_perf_perfEventsBackend_4_value,
  input  [5:0]    io_perf_perfEventsBackend_5_value,
  input  [5:0]    io_perf_perfEventsBackend_6_value,
  input  [5:0]    io_perf_perfEventsBackend_7_value,
  input  [5:0]    io_perf_perfEventsLsu_0_value,
  input  [5:0]    io_perf_perfEventsLsu_1_value,
  input  [5:0]    io_perf_perfEventsLsu_2_value,
  input  [5:0]    io_perf_perfEventsLsu_3_value,
  input  [5:0]    io_perf_perfEventsLsu_4_value,
  input  [5:0]    io_perf_perfEventsLsu_5_value,
  input  [5:0]    io_perf_perfEventsLsu_6_value,
  input  [5:0]    io_perf_perfEventsLsu_7_value,
  input  [5:0]    io_perf_perfEventsHc_0_value,
  input  [5:0]    io_perf_perfEventsHc_1_value,
  input  [5:0]    io_perf_perfEventsHc_2_value,
  input  [5:0]    io_perf_perfEventsHc_3_value,
  input  [5:0]    io_perf_perfEventsHc_4_value,
  input  [5:0]    io_perf_perfEventsHc_5_value,
  input  [5:0]    io_perf_perfEventsHc_6_value,
  input  [5:0]    io_perf_perfEventsHc_7_value,
  input  [5:0]    io_perf_perfEventsHc_8_value,
  input  [5:0]    io_perf_perfEventsHc_9_value,
  input  [5:0]    io_perf_perfEventsHc_10_value,
  input  [5:0]    io_perf_perfEventsHc_11_value,
  input  [5:0]    io_perf_perfEventsHc_12_value,
  input  [5:0]    io_perf_perfEventsHc_13_value,
  input  [5:0]    io_perf_perfEventsHc_14_value,
  input  [5:0]    io_perf_perfEventsHc_15_value,
  input  [5:0]    io_perf_perfEventsHc_16_value,
  input  [5:0]    io_perf_perfEventsHc_17_value,
  input  [5:0]    io_perf_perfEventsHc_18_value,
  input  [5:0]    io_perf_perfEventsHc_19_value,
  input  [5:0]    io_perf_perfEventsHc_20_value,
  input  [5:0]    io_perf_perfEventsHc_21_value,
  input  [5:0]    io_perf_perfEventsHc_22_value,
  input  [5:0]    io_perf_perfEventsHc_23_value,
  input  [5:0]    io_perf_perfEventsHc_24_value,
  input  [5:0]    io_perf_perfEventsHc_25_value,
  input  [5:0]    io_perf_perfEventsHc_26_value,
  input  [5:0]    io_perf_perfEventsHc_27_value,
  input  [5:0]    io_perf_perfEventsHc_28_value,
  input  [5:0]    io_perf_perfEventsHc_29_value,
  input  [5:0]    io_perf_perfEventsHc_30_value,
  input  [5:0]    io_perf_perfEventsHc_31_value,
  input  [5:0]    io_perf_perfEventsHc_32_value,
  input  [5:0]    io_perf_perfEventsHc_33_value,
  input  [5:0]    io_perf_perfEventsHc_34_value,
  input  [5:0]    io_perf_perfEventsHc_35_value,
  input  [5:0]    io_perf_perfEventsHc_36_value,
  input  [5:0]    io_perf_perfEventsHc_37_value,
  input  [5:0]    io_perf_perfEventsHc_38_value,
  input  [5:0]    io_perf_perfEventsHc_39_value,
  input  [5:0]    io_perf_perfEventsHc_40_value,
  input  [5:0]    io_perf_perfEventsHc_41_value,
  input  [5:0]    io_perf_perfEventsHc_42_value,
  input  [5:0]    io_perf_perfEventsHc_43_value,
  input  [5:0]    io_perf_perfEventsHc_44_value,
  input  [5:0]    io_perf_perfEventsHc_45_value,
  input  [5:0]    io_perf_perfEventsHc_46_value,
  input  [5:0]    io_perf_perfEventsHc_47_value,
  input  [5:0]    io_perf_perfEventsHc_48_value,
  input  [5:0]    io_perf_perfEventsHc_49_value,
  input  [5:0]    io_perf_perfEventsHc_50_value,
  input  [5:0]    io_perf_perfEventsHc_51_value,
  input  [5:0]    io_perf_perfEventsHc_52_value,
  input  [5:0]    io_perf_perfEventsHc_53_value,
  input  [5:0]    io_perf_perfEventsHc_54_value,
  input  [5:0]    io_perf_perfEventsHc_55_value,
  input  [5:0]    io_perf_perfEventsHc_56_value,
  input  [5:0]    io_perf_perfEventsHc_57_value,
  input  [5:0]    io_perf_perfEventsHc_58_value,
  input  [5:0]    io_perf_perfEventsHc_59_value,
  input  [5:0]    io_perf_perfEventsHc_60_value,
  input  [5:0]    io_perf_perfEventsHc_61_value,
  input  [5:0]    io_perf_perfEventsHc_62_value,
  input  [5:0]    io_perf_perfEventsHc_63_value,
  input  [5:0]    io_perf_perfEventsHc_64_value,
  input  [5:0]    io_perf_perfEventsHc_65_value,
  input  [5:0]    io_perf_perfEventsHc_66_value,
  input  [5:0]    io_perf_perfEventsHc_67_value,
  input           io_out_ready,
  output          io_out_valid,
  output          io_out_bits_EX_II,
  output          io_out_bits_EX_VI,
  output          io_out_bits_flushPipe,
  output [63:0]   io_out_bits_rData,
  output          io_out_bits_targetPcUpdate,
  output [63:0]   io_out_bits_targetPc_pc,
  output          io_out_bits_targetPc_raiseIPF,
  output          io_out_bits_targetPc_raiseIAF,
  output          io_out_bits_targetPc_raiseIGPF,
  output [63:0]   io_out_bits_regOut,
  output          io_out_bits_isPerfCnt,
  output [1:0]    io_status_privState_PRVM,
  output          io_status_privState_V,
  output          io_status_interrupt,
  output          io_status_wfiEvent,
  output          io_status_satp_valid,
  output [3:0]    io_status_satp_bits,
  output          io_status_vsatp_valid,
  output [3:0]    io_status_vsatp_bits,
  output [2:0]    io_status_fpState_frm,
  output [6:0]    io_status_vecState_vstart,
  output [1:0]    io_status_vecState_vxrm,
  output          io_status_singleStepFlag,
  output          io_status_frontendTrigger_tUpdate_valid,
  output [1:0]    io_status_frontendTrigger_tUpdate_bits_addr,
  output [1:0]    io_status_frontendTrigger_tUpdate_bits_tdata_matchType,
  output          io_status_frontendTrigger_tUpdate_bits_tdata_select,
  output [3:0]    io_status_frontendTrigger_tUpdate_bits_tdata_action,
  output          io_status_frontendTrigger_tUpdate_bits_tdata_chain,
  output [63:0]   io_status_frontendTrigger_tUpdate_bits_tdata_tdata2,
  output          io_status_frontendTrigger_tEnableVec_0,
  output          io_status_frontendTrigger_tEnableVec_1,
  output          io_status_frontendTrigger_tEnableVec_2,
  output          io_status_frontendTrigger_tEnableVec_3,
  output          io_status_frontendTrigger_debugMode,
  output          io_status_frontendTrigger_triggerCanRaiseBpExp,
  output          io_status_memTrigger_tUpdate_valid,
  output [1:0]    io_status_memTrigger_tUpdate_bits_addr,
  output [1:0]    io_status_memTrigger_tUpdate_bits_tdata_matchType,
  output          io_status_memTrigger_tUpdate_bits_tdata_select,
  output [3:0]    io_status_memTrigger_tUpdate_bits_tdata_action,
  output          io_status_memTrigger_tUpdate_bits_tdata_chain,
  output          io_status_memTrigger_tUpdate_bits_tdata_store,
  output          io_status_memTrigger_tUpdate_bits_tdata_load,
  output [63:0]   io_status_memTrigger_tUpdate_bits_tdata_tdata2,
  output          io_status_memTrigger_tEnableVec_0,
  output          io_status_memTrigger_tEnableVec_1,
  output          io_status_memTrigger_tEnableVec_2,
  output          io_status_memTrigger_tEnableVec_3,
  output          io_status_memTrigger_debugMode,
  output          io_status_memTrigger_triggerCanRaiseBpExp,
  output          io_status_instrAddrTransType_bare,
  output          io_status_instrAddrTransType_sv39,
  output          io_status_instrAddrTransType_sv39x4,
  output          io_status_instrAddrTransType_sv48,
  output          io_status_instrAddrTransType_sv48x4,
  output [63:0]   io_status_traceCSR_cause,
  output [49:0]   io_status_traceCSR_tval,
  output [63:0]   io_status_traceCSR_mstatus,
  output [2:0]    io_status_traceCSR_lastPriv,
  output [2:0]    io_status_traceCSR_currentPriv,
  output          io_status_custom_pf_ctrl_l1I_pf_enable,
  output          io_status_custom_pf_ctrl_l2_pf_enable,
  output          io_status_custom_pf_ctrl_l1D_pf_enable,
  output          io_status_custom_pf_ctrl_l1D_pf_train_on_hit,
  output          io_status_custom_pf_ctrl_l1D_pf_enable_agt,
  output          io_status_custom_pf_ctrl_l1D_pf_enable_pht,
  output [3:0]    io_status_custom_pf_ctrl_l1D_pf_active_threshold,
  output [5:0]    io_status_custom_pf_ctrl_l1D_pf_active_stride,
  output          io_status_custom_pf_ctrl_l1D_pf_enable_stride,
  output          io_status_custom_pf_ctrl_l2_pf_store_only,
  output          io_status_custom_pf_ctrl_l2_pf_recv_enable,
  output          io_status_custom_pf_ctrl_l2_pf_pbop_enable,
  output          io_status_custom_pf_ctrl_l2_pf_vbop_enable,
  output [9:0]    io_status_custom_pf_ctrl_l2_pf_delay_latency,
  output [4:0]    io_status_custom_lvpred_timeout,
  output          io_status_custom_bp_ctrl_ubtb_enable,
  output          io_status_custom_bp_ctrl_btb_enable,
  output          io_status_custom_bp_ctrl_tage_enable,
  output          io_status_custom_bp_ctrl_sc_enable,
  output          io_status_custom_bp_ctrl_ras_enable,
  output [21:0]   io_status_custom_sbuffer_timeout,
  output          io_status_custom_ldld_vio_check_enable,
  output          io_status_custom_cache_error_enable,
  output          io_status_custom_uncache_write_outstanding_enable,
  output          io_status_custom_hd_misalign_st_enable,
  output          io_status_custom_hd_misalign_ld_enable,
  output          io_status_custom_power_down_enable,
  output          io_status_custom_flush_l2_enable,
  output          io_status_custom_fusion_enable,
  output          io_status_custom_wfi_enable,
  output          io_status_criticalErrorState,
  output          io_tlb_satpASIDChanged,
  output          io_tlb_vsatpASIDChanged,
  output          io_tlb_hgatpVMIDChanged,
  output [3:0]    io_tlb_satp_MODE,
  output [15:0]   io_tlb_satp_ASID,
  output [43:0]   io_tlb_satp_PPN,
  output [3:0]    io_tlb_vsatp_MODE,
  output [15:0]   io_tlb_vsatp_ASID,
  output [43:0]   io_tlb_vsatp_PPN,
  output [3:0]    io_tlb_hgatp_MODE,
  output [13:0]   io_tlb_hgatp_VMID,
  output [43:0]   io_tlb_hgatp_PPN,
  output [57:0]   io_tlb_mbmc_BMA,
  output          io_tlb_mbmc_BME,
  output          io_tlb_mbmc_BCLEAR,
  output          io_tlb_mbmc_CMODE,
  output          io_tlb_mxr,
  output          io_tlb_sum,
  output          io_tlb_vmxr,
  output          io_tlb_vsum,
  output          io_tlb_spvp,
  output [1:0]    io_tlb_imode,
  output [1:0]    io_tlb_dmode,
  output          io_tlb_debug,
  output          io_tlb_dvirt,
  output          io_tlb_mPBMTE,
  output          io_tlb_hPBMTE,
  output [1:0]    io_tlb_pmm_mseccfg,
  output [1:0]    io_tlb_pmm_menvcfg,
  output [1:0]    io_tlb_pmm_henvcfg,
  output [1:0]    io_tlb_pmm_hstatus,
  output [1:0]    io_tlb_pmm_senvcfg,
  output          io_toDecode_illegalInst_sfenceVMA,
  output          io_toDecode_illegalInst_sfencePart,
  output          io_toDecode_illegalInst_hfenceGVMA,
  output          io_toDecode_illegalInst_hfenceVVMA,
  output          io_toDecode_illegalInst_hlsv,
  output          io_toDecode_illegalInst_fsIsOff,
  output          io_toDecode_illegalInst_vsIsOff,
  output          io_toDecode_illegalInst_wfi,
  output          io_toDecode_illegalInst_wrs_nto,
  output          io_toDecode_illegalInst_frm,
  output          io_toDecode_illegalInst_cboZ,
  output          io_toDecode_illegalInst_cboCF,
  output          io_toDecode_illegalInst_cboI,
  output          io_toDecode_virtualInst_sfenceVMA,
  output          io_toDecode_virtualInst_sfencePart,
  output          io_toDecode_virtualInst_hfence,
  output          io_toDecode_virtualInst_hlsv,
  output          io_toDecode_virtualInst_wfi,
  output          io_toDecode_virtualInst_wrs_nto,
  output          io_toDecode_virtualInst_cboZ,
  output          io_toDecode_virtualInst_cboCF,
  output          io_toDecode_virtualInst_cboI,
  output          io_toDecode_special_cboI2F,
  input  [63:0]   io_fetchMalTval,
  input  [1:0]    io_oldPrivSate_PRVM,
  input           io_oldPrivSate_V,
  input  [3:0]    io_oldSatpMode,
  input  [3:0]    io_oldVsatpMode,
  output          io_distributedWenLegal,
  output          toAIA_addr_valid,
  output [11:0]   toAIA_addr_bits_addr,
  output          toAIA_addr_bits_v,
  output [1:0]    toAIA_addr_bits_prvm,
  output [5:0]    toAIA_vgein,
  output          toAIA_wdata_valid,
  output [1:0]    toAIA_wdata_bits_op,
  output [63:0]   toAIA_wdata_bits_data,
  output          toAIA_mClaim,
  output          toAIA_sClaim,
  output          toAIA_vsClaim,
  input           fromAIA_rdata_valid,
  input  [63:0]   fromAIA_rdata_bits_data,
  input           fromAIA_rdata_bits_illegal,
  input           fromAIA_meip,
  input           fromAIA_seip,
  input           fromAIA_notice_pending,
  input  [6:0]    fromAIA_vseip,
  input  [10:0]   fromAIA_mtopei_IID,
  input  [10:0]   fromAIA_mtopei_IPRIO,
  input  [10:0]   fromAIA_stopei_IID,
  input  [10:0]   fromAIA_stopei_IPRIO,
  input  [10:0]   fromAIA_vstopei_IID,
  input  [10:0]   fromAIA_vstopei_IPRIO,
  output          io_error_0,
  output [172:0]  gatewayIn_packed_29_bore,
  output [9:0]    gatewayIn_packed_30_bore,
  output [1159:0] gatewayIn_packed_31_bore,
  output [264:0]  gatewayIn_packed_32_bore,
  output [199:0]  gatewayIn_packed_33_bore,
  output [455:0]  gatewayIn_packed_34_bore,
  output [71:0]   gatewayIn_packed_35_bore,
  output [1095:0] gatewayIn_packed_36_bore,
  output [18:0]   gatewayIn_packed_37_bore,
  output [72:0]   gatewayIn_packed_38_bore,
  output [264:0]  gatewayIn_packed_39_bore,
  output [9:0]    gatewayIn_packed_40_bore
// END GENERATED(newcsr-ports)
);

  // ==========================================================================
  // 子模块输出线（GENERATED）
  // ==========================================================================
// BEGIN GENERATED(newcsr-childnets) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  // mbmc
  wire [63:0]    mbmc_rdata;
  wire [57:0]    mbmc_regOut_BMA;
  wire           mbmc_regOut_KEYIDEN;
  wire           mbmc_regOut_BME;
  wire           mbmc_regOut_BCLEAR;
  wire           mbmc_regOut_CMODE;
  // mstatus
  wire [63:0]    mstatus_rdata;
  wire           mstatus_regOut_SIE;
  wire           mstatus_regOut_MIE;
  wire           mstatus_regOut_SPIE;
  wire           mstatus_regOut_MPIE;
  wire           mstatus_regOut_SPP;
  wire [1:0]     mstatus_regOut_VS;
  wire [1:0]     mstatus_regOut_MPP;
  wire [1:0]     mstatus_regOut_FS;
  wire           mstatus_regOut_MPRV;
  wire           mstatus_regOut_SUM;
  wire           mstatus_regOut_MXR;
  wire           mstatus_regOut_TVM;
  wire           mstatus_regOut_TW;
  wire           mstatus_regOut_TSR;
  wire           mstatus_regOut_SDT;
  wire           mstatus_regOut_GVA;
  wire           mstatus_regOut_MPV;
  wire           mstatus_regOut_MDT;
  wire           mstatus_sstatus_SIE;
  wire           mstatus_sstatus_SPIE;
  wire           mstatus_sstatus_SPP;
  wire [1:0]     mstatus_sstatus_VS;
  wire [1:0]     mstatus_sstatus_FS;
  wire           mstatus_sstatus_SUM;
  wire           mstatus_sstatus_MXR;
  wire           mstatus_sstatus_SDT;
  wire           mstatus_sstatus_SD;
  wire [63:0]    mstatus_sstatusRdata;
  // medeleg
  wire [63:0]    medeleg_rdata;
  wire           medeleg_regOut_EX_IAM;
  wire           medeleg_regOut_EX_IAF;
  wire           medeleg_regOut_EX_II;
  wire           medeleg_regOut_EX_BP;
  wire           medeleg_regOut_EX_LAM;
  wire           medeleg_regOut_EX_LAF;
  wire           medeleg_regOut_EX_SAM;
  wire           medeleg_regOut_EX_SAF;
  wire           medeleg_regOut_EX_UCALL;
  wire           medeleg_regOut_EX_HSCALL;
  wire           medeleg_regOut_EX_VSCALL;
  wire           medeleg_regOut_EX_IPF;
  wire           medeleg_regOut_EX_LPF;
  wire           medeleg_regOut_EX_SPF;
  wire           medeleg_regOut_EX_SWC;
  wire           medeleg_regOut_EX_HWE;
  wire           medeleg_regOut_EX_IGPF;
  wire           medeleg_regOut_EX_LGPF;
  wire           medeleg_regOut_EX_VI;
  wire           medeleg_regOut_EX_SGPF;
  // mideleg
  wire [63:0]    mideleg_rdata;
  wire           mideleg_regOut_SSI;
  wire           mideleg_regOut_STI;
  wire           mideleg_regOut_SEI;
  wire           mideleg_regOut_LCOFI;
  // mie
  wire [63:0]    mie_rdata;
  wire           mie_regOut_SSIE;
  wire           mie_regOut_VSSIE;
  wire           mie_regOut_MSIE;
  wire           mie_regOut_STIE;
  wire           mie_regOut_VSTIE;
  wire           mie_regOut_MTIE;
  wire           mie_regOut_SEIE;
  wire           mie_regOut_VSEIE;
  wire           mie_regOut_MEIE;
  wire           mie_regOut_SGEIE;
  wire           mie_regOut_LCOFIE;
  // mtvec
  wire [63:0]    mtvec_rdata;
  wire [1:0]     mtvec_regOut_mode;
  wire [61:0]    mtvec_regOut_addr;
  // mcounteren
  wire [63:0]    mcounteren_rdata;
  wire           mcounteren_regOut_CY;
  wire           mcounteren_regOut_TM;
  wire           mcounteren_regOut_IR;
  wire [28:0]    mcounteren_regOut_HPM;
  // mvien
  wire [63:0]    mvien_rdata;
  wire           mvien_regOut_SSIE;
  wire           mvien_regOut_SEIE;
  wire           mvien_regOut_LC14IE;
  wire           mvien_regOut_LC15IE;
  wire           mvien_regOut_LC16IE;
  wire           mvien_regOut_LC17IE;
  wire           mvien_regOut_LC18IE;
  wire           mvien_regOut_LC19IE;
  wire           mvien_regOut_LC20IE;
  wire           mvien_regOut_LC21IE;
  wire           mvien_regOut_LC22IE;
  wire           mvien_regOut_LC23IE;
  wire           mvien_regOut_LC24IE;
  wire           mvien_regOut_LC25IE;
  wire           mvien_regOut_LC26IE;
  wire           mvien_regOut_LC27IE;
  wire           mvien_regOut_LC28IE;
  wire           mvien_regOut_LC29IE;
  wire           mvien_regOut_LC30IE;
  wire           mvien_regOut_LC31IE;
  wire           mvien_regOut_LC32IE;
  wire           mvien_regOut_LC33IE;
  wire           mvien_regOut_LC34IE;
  wire           mvien_regOut_LPRASEIE;
  wire           mvien_regOut_LC36IE;
  wire           mvien_regOut_LC37IE;
  wire           mvien_regOut_LC38IE;
  wire           mvien_regOut_LC39IE;
  wire           mvien_regOut_LC40IE;
  wire           mvien_regOut_LC41IE;
  wire           mvien_regOut_LC42IE;
  wire           mvien_regOut_HPRASEIE;
  wire           mvien_regOut_LC44IE;
  wire           mvien_regOut_LC45IE;
  wire           mvien_regOut_LC46IE;
  wire           mvien_regOut_LC47IE;
  wire           mvien_regOut_LC48IE;
  wire           mvien_regOut_LC49IE;
  wire           mvien_regOut_LC50IE;
  wire           mvien_regOut_LC51IE;
  wire           mvien_regOut_LC52IE;
  wire           mvien_regOut_LC53IE;
  wire           mvien_regOut_LC54IE;
  wire           mvien_regOut_LC55IE;
  wire           mvien_regOut_LC56IE;
  wire           mvien_regOut_LC57IE;
  wire           mvien_regOut_LC58IE;
  wire           mvien_regOut_LC59IE;
  wire           mvien_regOut_LC60IE;
  wire           mvien_regOut_LC61IE;
  wire           mvien_regOut_LC62IE;
  wire           mvien_regOut_LC63IE;
  // mvip
  wire [63:0]    mvip_rdata;
  wire           mvip_regOut_SSIP;
  wire           mvip_regOut_STIP;
  wire           mvip_regOut_SEIP;
  wire           mvip_regOut_LCOFIP;
  wire           mvip_regOut_LC14IP;
  wire           mvip_regOut_LC15IP;
  wire           mvip_regOut_LC16IP;
  wire           mvip_regOut_LC17IP;
  wire           mvip_regOut_LC18IP;
  wire           mvip_regOut_LC19IP;
  wire           mvip_regOut_LC20IP;
  wire           mvip_regOut_LC21IP;
  wire           mvip_regOut_LC22IP;
  wire           mvip_regOut_LC23IP;
  wire           mvip_regOut_LC24IP;
  wire           mvip_regOut_LC25IP;
  wire           mvip_regOut_LC26IP;
  wire           mvip_regOut_LC27IP;
  wire           mvip_regOut_LC28IP;
  wire           mvip_regOut_LC29IP;
  wire           mvip_regOut_LC30IP;
  wire           mvip_regOut_LC31IP;
  wire           mvip_regOut_LC32IP;
  wire           mvip_regOut_LC33IP;
  wire           mvip_regOut_LC34IP;
  wire           mvip_regOut_LPRASEIP;
  wire           mvip_regOut_LC36IP;
  wire           mvip_regOut_LC37IP;
  wire           mvip_regOut_LC38IP;
  wire           mvip_regOut_LC39IP;
  wire           mvip_regOut_LC40IP;
  wire           mvip_regOut_LC41IP;
  wire           mvip_regOut_LC42IP;
  wire           mvip_regOut_HPRASEIP;
  wire           mvip_regOut_LC44IP;
  wire           mvip_regOut_LC45IP;
  wire           mvip_regOut_LC46IP;
  wire           mvip_regOut_LC47IP;
  wire           mvip_regOut_LC48IP;
  wire           mvip_regOut_LC49IP;
  wire           mvip_regOut_LC50IP;
  wire           mvip_regOut_LC51IP;
  wire           mvip_regOut_LC52IP;
  wire           mvip_regOut_LC53IP;
  wire           mvip_regOut_LC54IP;
  wire           mvip_regOut_LC55IP;
  wire           mvip_regOut_LC56IP;
  wire           mvip_regOut_LC57IP;
  wire           mvip_regOut_LC58IP;
  wire           mvip_regOut_LC59IP;
  wire           mvip_regOut_LC60IP;
  wire           mvip_regOut_LC61IP;
  wire           mvip_regOut_LC62IP;
  wire           mvip_regOut_LC63IP;
  wire           mvip_toMip_SSIP_valid;
  wire           mvip_toMip_SSIP_bits;
  wire           mvip_toMip_STIP_valid;
  wire           mvip_toMip_STIP_bits;
  // menvcfg
  wire [63:0]    menvcfg_rdata;
  wire           menvcfg_regOut_STCE;
  wire           menvcfg_regOut_PBMTE;
  wire           menvcfg_regOut_DTE;
  wire [1:0]     menvcfg_regOut_PMM;
  wire           menvcfg_regOut_CBZE;
  wire           menvcfg_regOut_CBCFE;
  wire [1:0]     menvcfg_regOut_CBIE;
  // mcountinhibit
  wire [63:0]    mcountinhibit_rdata;
  wire           mcountinhibit_regOut_CY;
  wire           mcountinhibit_regOut_IR;
  wire [28:0]    mcountinhibit_regOut_HPM3;
  // Mhpmevent3
  wire [63:0]    Mhpmevent3_rdata;
  wire           Mhpmevent3_regOut_OF;
  wire           Mhpmevent3_regOut_MINH;
  wire           Mhpmevent3_regOut_SINH;
  wire           Mhpmevent3_regOut_UINH;
  wire           Mhpmevent3_regOut_VSINH;
  wire           Mhpmevent3_regOut_VUINH;
  wire [4:0]     Mhpmevent3_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent3_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent3_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent3_regOut_EVENT3;
  wire [9:0]     Mhpmevent3_regOut_EVENT2;
  wire [9:0]     Mhpmevent3_regOut_EVENT1;
  wire [9:0]     Mhpmevent3_regOut_EVENT0;
  // Mhpmevent4
  wire [63:0]    Mhpmevent4_rdata;
  wire           Mhpmevent4_regOut_OF;
  wire           Mhpmevent4_regOut_MINH;
  wire           Mhpmevent4_regOut_SINH;
  wire           Mhpmevent4_regOut_UINH;
  wire           Mhpmevent4_regOut_VSINH;
  wire           Mhpmevent4_regOut_VUINH;
  wire [4:0]     Mhpmevent4_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent4_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent4_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent4_regOut_EVENT3;
  wire [9:0]     Mhpmevent4_regOut_EVENT2;
  wire [9:0]     Mhpmevent4_regOut_EVENT1;
  wire [9:0]     Mhpmevent4_regOut_EVENT0;
  // Mhpmevent5
  wire [63:0]    Mhpmevent5_rdata;
  wire           Mhpmevent5_regOut_OF;
  wire           Mhpmevent5_regOut_MINH;
  wire           Mhpmevent5_regOut_SINH;
  wire           Mhpmevent5_regOut_UINH;
  wire           Mhpmevent5_regOut_VSINH;
  wire           Mhpmevent5_regOut_VUINH;
  wire [4:0]     Mhpmevent5_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent5_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent5_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent5_regOut_EVENT3;
  wire [9:0]     Mhpmevent5_regOut_EVENT2;
  wire [9:0]     Mhpmevent5_regOut_EVENT1;
  wire [9:0]     Mhpmevent5_regOut_EVENT0;
  // Mhpmevent6
  wire [63:0]    Mhpmevent6_rdata;
  wire           Mhpmevent6_regOut_OF;
  wire           Mhpmevent6_regOut_MINH;
  wire           Mhpmevent6_regOut_SINH;
  wire           Mhpmevent6_regOut_UINH;
  wire           Mhpmevent6_regOut_VSINH;
  wire           Mhpmevent6_regOut_VUINH;
  wire [4:0]     Mhpmevent6_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent6_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent6_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent6_regOut_EVENT3;
  wire [9:0]     Mhpmevent6_regOut_EVENT2;
  wire [9:0]     Mhpmevent6_regOut_EVENT1;
  wire [9:0]     Mhpmevent6_regOut_EVENT0;
  // Mhpmevent7
  wire [63:0]    Mhpmevent7_rdata;
  wire           Mhpmevent7_regOut_OF;
  wire           Mhpmevent7_regOut_MINH;
  wire           Mhpmevent7_regOut_SINH;
  wire           Mhpmevent7_regOut_UINH;
  wire           Mhpmevent7_regOut_VSINH;
  wire           Mhpmevent7_regOut_VUINH;
  wire [4:0]     Mhpmevent7_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent7_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent7_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent7_regOut_EVENT3;
  wire [9:0]     Mhpmevent7_regOut_EVENT2;
  wire [9:0]     Mhpmevent7_regOut_EVENT1;
  wire [9:0]     Mhpmevent7_regOut_EVENT0;
  // Mhpmevent8
  wire [63:0]    Mhpmevent8_rdata;
  wire           Mhpmevent8_regOut_OF;
  wire           Mhpmevent8_regOut_MINH;
  wire           Mhpmevent8_regOut_SINH;
  wire           Mhpmevent8_regOut_UINH;
  wire           Mhpmevent8_regOut_VSINH;
  wire           Mhpmevent8_regOut_VUINH;
  wire [4:0]     Mhpmevent8_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent8_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent8_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent8_regOut_EVENT3;
  wire [9:0]     Mhpmevent8_regOut_EVENT2;
  wire [9:0]     Mhpmevent8_regOut_EVENT1;
  wire [9:0]     Mhpmevent8_regOut_EVENT0;
  // Mhpmevent9
  wire [63:0]    Mhpmevent9_rdata;
  wire           Mhpmevent9_regOut_OF;
  wire           Mhpmevent9_regOut_MINH;
  wire           Mhpmevent9_regOut_SINH;
  wire           Mhpmevent9_regOut_UINH;
  wire           Mhpmevent9_regOut_VSINH;
  wire           Mhpmevent9_regOut_VUINH;
  wire [4:0]     Mhpmevent9_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent9_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent9_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent9_regOut_EVENT3;
  wire [9:0]     Mhpmevent9_regOut_EVENT2;
  wire [9:0]     Mhpmevent9_regOut_EVENT1;
  wire [9:0]     Mhpmevent9_regOut_EVENT0;
  // Mhpmevent10
  wire [63:0]    Mhpmevent10_rdata;
  wire           Mhpmevent10_regOut_OF;
  wire           Mhpmevent10_regOut_MINH;
  wire           Mhpmevent10_regOut_SINH;
  wire           Mhpmevent10_regOut_UINH;
  wire           Mhpmevent10_regOut_VSINH;
  wire           Mhpmevent10_regOut_VUINH;
  wire [4:0]     Mhpmevent10_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent10_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent10_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent10_regOut_EVENT3;
  wire [9:0]     Mhpmevent10_regOut_EVENT2;
  wire [9:0]     Mhpmevent10_regOut_EVENT1;
  wire [9:0]     Mhpmevent10_regOut_EVENT0;
  // Mhpmevent11
  wire [63:0]    Mhpmevent11_rdata;
  wire           Mhpmevent11_regOut_OF;
  wire           Mhpmevent11_regOut_MINH;
  wire           Mhpmevent11_regOut_SINH;
  wire           Mhpmevent11_regOut_UINH;
  wire           Mhpmevent11_regOut_VSINH;
  wire           Mhpmevent11_regOut_VUINH;
  wire [4:0]     Mhpmevent11_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent11_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent11_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent11_regOut_EVENT3;
  wire [9:0]     Mhpmevent11_regOut_EVENT2;
  wire [9:0]     Mhpmevent11_regOut_EVENT1;
  wire [9:0]     Mhpmevent11_regOut_EVENT0;
  // Mhpmevent12
  wire [63:0]    Mhpmevent12_rdata;
  wire           Mhpmevent12_regOut_OF;
  wire           Mhpmevent12_regOut_MINH;
  wire           Mhpmevent12_regOut_SINH;
  wire           Mhpmevent12_regOut_UINH;
  wire           Mhpmevent12_regOut_VSINH;
  wire           Mhpmevent12_regOut_VUINH;
  wire [4:0]     Mhpmevent12_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent12_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent12_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent12_regOut_EVENT3;
  wire [9:0]     Mhpmevent12_regOut_EVENT2;
  wire [9:0]     Mhpmevent12_regOut_EVENT1;
  wire [9:0]     Mhpmevent12_regOut_EVENT0;
  // Mhpmevent13
  wire [63:0]    Mhpmevent13_rdata;
  wire           Mhpmevent13_regOut_OF;
  wire           Mhpmevent13_regOut_MINH;
  wire           Mhpmevent13_regOut_SINH;
  wire           Mhpmevent13_regOut_UINH;
  wire           Mhpmevent13_regOut_VSINH;
  wire           Mhpmevent13_regOut_VUINH;
  wire [4:0]     Mhpmevent13_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent13_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent13_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent13_regOut_EVENT3;
  wire [9:0]     Mhpmevent13_regOut_EVENT2;
  wire [9:0]     Mhpmevent13_regOut_EVENT1;
  wire [9:0]     Mhpmevent13_regOut_EVENT0;
  // Mhpmevent14
  wire [63:0]    Mhpmevent14_rdata;
  wire           Mhpmevent14_regOut_OF;
  wire           Mhpmevent14_regOut_MINH;
  wire           Mhpmevent14_regOut_SINH;
  wire           Mhpmevent14_regOut_UINH;
  wire           Mhpmevent14_regOut_VSINH;
  wire           Mhpmevent14_regOut_VUINH;
  wire [4:0]     Mhpmevent14_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent14_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent14_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent14_regOut_EVENT3;
  wire [9:0]     Mhpmevent14_regOut_EVENT2;
  wire [9:0]     Mhpmevent14_regOut_EVENT1;
  wire [9:0]     Mhpmevent14_regOut_EVENT0;
  // Mhpmevent15
  wire [63:0]    Mhpmevent15_rdata;
  wire           Mhpmevent15_regOut_OF;
  wire           Mhpmevent15_regOut_MINH;
  wire           Mhpmevent15_regOut_SINH;
  wire           Mhpmevent15_regOut_UINH;
  wire           Mhpmevent15_regOut_VSINH;
  wire           Mhpmevent15_regOut_VUINH;
  wire [4:0]     Mhpmevent15_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent15_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent15_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent15_regOut_EVENT3;
  wire [9:0]     Mhpmevent15_regOut_EVENT2;
  wire [9:0]     Mhpmevent15_regOut_EVENT1;
  wire [9:0]     Mhpmevent15_regOut_EVENT0;
  // Mhpmevent16
  wire [63:0]    Mhpmevent16_rdata;
  wire           Mhpmevent16_regOut_OF;
  wire           Mhpmevent16_regOut_MINH;
  wire           Mhpmevent16_regOut_SINH;
  wire           Mhpmevent16_regOut_UINH;
  wire           Mhpmevent16_regOut_VSINH;
  wire           Mhpmevent16_regOut_VUINH;
  wire [4:0]     Mhpmevent16_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent16_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent16_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent16_regOut_EVENT3;
  wire [9:0]     Mhpmevent16_regOut_EVENT2;
  wire [9:0]     Mhpmevent16_regOut_EVENT1;
  wire [9:0]     Mhpmevent16_regOut_EVENT0;
  // Mhpmevent17
  wire [63:0]    Mhpmevent17_rdata;
  wire           Mhpmevent17_regOut_OF;
  wire           Mhpmevent17_regOut_MINH;
  wire           Mhpmevent17_regOut_SINH;
  wire           Mhpmevent17_regOut_UINH;
  wire           Mhpmevent17_regOut_VSINH;
  wire           Mhpmevent17_regOut_VUINH;
  wire [4:0]     Mhpmevent17_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent17_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent17_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent17_regOut_EVENT3;
  wire [9:0]     Mhpmevent17_regOut_EVENT2;
  wire [9:0]     Mhpmevent17_regOut_EVENT1;
  wire [9:0]     Mhpmevent17_regOut_EVENT0;
  // Mhpmevent18
  wire [63:0]    Mhpmevent18_rdata;
  wire           Mhpmevent18_regOut_OF;
  wire           Mhpmevent18_regOut_MINH;
  wire           Mhpmevent18_regOut_SINH;
  wire           Mhpmevent18_regOut_UINH;
  wire           Mhpmevent18_regOut_VSINH;
  wire           Mhpmevent18_regOut_VUINH;
  wire [4:0]     Mhpmevent18_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent18_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent18_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent18_regOut_EVENT3;
  wire [9:0]     Mhpmevent18_regOut_EVENT2;
  wire [9:0]     Mhpmevent18_regOut_EVENT1;
  wire [9:0]     Mhpmevent18_regOut_EVENT0;
  // Mhpmevent19
  wire [63:0]    Mhpmevent19_rdata;
  wire           Mhpmevent19_regOut_OF;
  wire           Mhpmevent19_regOut_MINH;
  wire           Mhpmevent19_regOut_SINH;
  wire           Mhpmevent19_regOut_UINH;
  wire           Mhpmevent19_regOut_VSINH;
  wire           Mhpmevent19_regOut_VUINH;
  wire [4:0]     Mhpmevent19_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent19_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent19_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent19_regOut_EVENT3;
  wire [9:0]     Mhpmevent19_regOut_EVENT2;
  wire [9:0]     Mhpmevent19_regOut_EVENT1;
  wire [9:0]     Mhpmevent19_regOut_EVENT0;
  // Mhpmevent20
  wire [63:0]    Mhpmevent20_rdata;
  wire           Mhpmevent20_regOut_OF;
  wire           Mhpmevent20_regOut_MINH;
  wire           Mhpmevent20_regOut_SINH;
  wire           Mhpmevent20_regOut_UINH;
  wire           Mhpmevent20_regOut_VSINH;
  wire           Mhpmevent20_regOut_VUINH;
  wire [4:0]     Mhpmevent20_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent20_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent20_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent20_regOut_EVENT3;
  wire [9:0]     Mhpmevent20_regOut_EVENT2;
  wire [9:0]     Mhpmevent20_regOut_EVENT1;
  wire [9:0]     Mhpmevent20_regOut_EVENT0;
  // Mhpmevent21
  wire [63:0]    Mhpmevent21_rdata;
  wire           Mhpmevent21_regOut_OF;
  wire           Mhpmevent21_regOut_MINH;
  wire           Mhpmevent21_regOut_SINH;
  wire           Mhpmevent21_regOut_UINH;
  wire           Mhpmevent21_regOut_VSINH;
  wire           Mhpmevent21_regOut_VUINH;
  wire [4:0]     Mhpmevent21_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent21_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent21_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent21_regOut_EVENT3;
  wire [9:0]     Mhpmevent21_regOut_EVENT2;
  wire [9:0]     Mhpmevent21_regOut_EVENT1;
  wire [9:0]     Mhpmevent21_regOut_EVENT0;
  // Mhpmevent22
  wire [63:0]    Mhpmevent22_rdata;
  wire           Mhpmevent22_regOut_OF;
  wire           Mhpmevent22_regOut_MINH;
  wire           Mhpmevent22_regOut_SINH;
  wire           Mhpmevent22_regOut_UINH;
  wire           Mhpmevent22_regOut_VSINH;
  wire           Mhpmevent22_regOut_VUINH;
  wire [4:0]     Mhpmevent22_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent22_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent22_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent22_regOut_EVENT3;
  wire [9:0]     Mhpmevent22_regOut_EVENT2;
  wire [9:0]     Mhpmevent22_regOut_EVENT1;
  wire [9:0]     Mhpmevent22_regOut_EVENT0;
  // Mhpmevent23
  wire [63:0]    Mhpmevent23_rdata;
  wire           Mhpmevent23_regOut_OF;
  wire           Mhpmevent23_regOut_MINH;
  wire           Mhpmevent23_regOut_SINH;
  wire           Mhpmevent23_regOut_UINH;
  wire           Mhpmevent23_regOut_VSINH;
  wire           Mhpmevent23_regOut_VUINH;
  wire [4:0]     Mhpmevent23_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent23_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent23_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent23_regOut_EVENT3;
  wire [9:0]     Mhpmevent23_regOut_EVENT2;
  wire [9:0]     Mhpmevent23_regOut_EVENT1;
  wire [9:0]     Mhpmevent23_regOut_EVENT0;
  // Mhpmevent24
  wire [63:0]    Mhpmevent24_rdata;
  wire           Mhpmevent24_regOut_OF;
  wire           Mhpmevent24_regOut_MINH;
  wire           Mhpmevent24_regOut_SINH;
  wire           Mhpmevent24_regOut_UINH;
  wire           Mhpmevent24_regOut_VSINH;
  wire           Mhpmevent24_regOut_VUINH;
  wire [4:0]     Mhpmevent24_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent24_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent24_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent24_regOut_EVENT3;
  wire [9:0]     Mhpmevent24_regOut_EVENT2;
  wire [9:0]     Mhpmevent24_regOut_EVENT1;
  wire [9:0]     Mhpmevent24_regOut_EVENT0;
  // Mhpmevent25
  wire [63:0]    Mhpmevent25_rdata;
  wire           Mhpmevent25_regOut_OF;
  wire           Mhpmevent25_regOut_MINH;
  wire           Mhpmevent25_regOut_SINH;
  wire           Mhpmevent25_regOut_UINH;
  wire           Mhpmevent25_regOut_VSINH;
  wire           Mhpmevent25_regOut_VUINH;
  wire [4:0]     Mhpmevent25_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent25_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent25_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent25_regOut_EVENT3;
  wire [9:0]     Mhpmevent25_regOut_EVENT2;
  wire [9:0]     Mhpmevent25_regOut_EVENT1;
  wire [9:0]     Mhpmevent25_regOut_EVENT0;
  // Mhpmevent26
  wire [63:0]    Mhpmevent26_rdata;
  wire           Mhpmevent26_regOut_OF;
  wire           Mhpmevent26_regOut_MINH;
  wire           Mhpmevent26_regOut_SINH;
  wire           Mhpmevent26_regOut_UINH;
  wire           Mhpmevent26_regOut_VSINH;
  wire           Mhpmevent26_regOut_VUINH;
  wire [4:0]     Mhpmevent26_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent26_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent26_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent26_regOut_EVENT3;
  wire [9:0]     Mhpmevent26_regOut_EVENT2;
  wire [9:0]     Mhpmevent26_regOut_EVENT1;
  wire [9:0]     Mhpmevent26_regOut_EVENT0;
  // Mhpmevent27
  wire [63:0]    Mhpmevent27_rdata;
  wire           Mhpmevent27_regOut_OF;
  wire           Mhpmevent27_regOut_MINH;
  wire           Mhpmevent27_regOut_SINH;
  wire           Mhpmevent27_regOut_UINH;
  wire           Mhpmevent27_regOut_VSINH;
  wire           Mhpmevent27_regOut_VUINH;
  wire [4:0]     Mhpmevent27_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent27_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent27_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent27_regOut_EVENT3;
  wire [9:0]     Mhpmevent27_regOut_EVENT2;
  wire [9:0]     Mhpmevent27_regOut_EVENT1;
  wire [9:0]     Mhpmevent27_regOut_EVENT0;
  // Mhpmevent28
  wire [63:0]    Mhpmevent28_rdata;
  wire           Mhpmevent28_regOut_OF;
  wire           Mhpmevent28_regOut_MINH;
  wire           Mhpmevent28_regOut_SINH;
  wire           Mhpmevent28_regOut_UINH;
  wire           Mhpmevent28_regOut_VSINH;
  wire           Mhpmevent28_regOut_VUINH;
  wire [4:0]     Mhpmevent28_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent28_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent28_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent28_regOut_EVENT3;
  wire [9:0]     Mhpmevent28_regOut_EVENT2;
  wire [9:0]     Mhpmevent28_regOut_EVENT1;
  wire [9:0]     Mhpmevent28_regOut_EVENT0;
  // Mhpmevent29
  wire [63:0]    Mhpmevent29_rdata;
  wire           Mhpmevent29_regOut_OF;
  wire           Mhpmevent29_regOut_MINH;
  wire           Mhpmevent29_regOut_SINH;
  wire           Mhpmevent29_regOut_UINH;
  wire           Mhpmevent29_regOut_VSINH;
  wire           Mhpmevent29_regOut_VUINH;
  wire [4:0]     Mhpmevent29_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent29_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent29_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent29_regOut_EVENT3;
  wire [9:0]     Mhpmevent29_regOut_EVENT2;
  wire [9:0]     Mhpmevent29_regOut_EVENT1;
  wire [9:0]     Mhpmevent29_regOut_EVENT0;
  // Mhpmevent30
  wire [63:0]    Mhpmevent30_rdata;
  wire           Mhpmevent30_regOut_OF;
  wire           Mhpmevent30_regOut_MINH;
  wire           Mhpmevent30_regOut_SINH;
  wire           Mhpmevent30_regOut_UINH;
  wire           Mhpmevent30_regOut_VSINH;
  wire           Mhpmevent30_regOut_VUINH;
  wire [4:0]     Mhpmevent30_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent30_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent30_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent30_regOut_EVENT3;
  wire [9:0]     Mhpmevent30_regOut_EVENT2;
  wire [9:0]     Mhpmevent30_regOut_EVENT1;
  wire [9:0]     Mhpmevent30_regOut_EVENT0;
  // Mhpmevent31
  wire [63:0]    Mhpmevent31_rdata;
  wire           Mhpmevent31_regOut_OF;
  wire           Mhpmevent31_regOut_MINH;
  wire           Mhpmevent31_regOut_SINH;
  wire           Mhpmevent31_regOut_UINH;
  wire           Mhpmevent31_regOut_VSINH;
  wire           Mhpmevent31_regOut_VUINH;
  wire [4:0]     Mhpmevent31_regOut_OPTYPE2;
  wire [4:0]     Mhpmevent31_regOut_OPTYPE1;
  wire [4:0]     Mhpmevent31_regOut_OPTYPE0;
  wire [9:0]     Mhpmevent31_regOut_EVENT3;
  wire [9:0]     Mhpmevent31_regOut_EVENT2;
  wire [9:0]     Mhpmevent31_regOut_EVENT1;
  wire [9:0]     Mhpmevent31_regOut_EVENT0;
  // mscratch
  wire [63:0]    mscratch_rdata;
  wire [63:0]    mscratch_regOut_ALL;
  // mepc
  wire [63:0]    mepc_rdata;
  wire [62:0]    mepc_regOut_epc;
  // mcause
  wire [63:0]    mcause_rdata;
  wire           mcause_regOut_Interrupt;
  wire [62:0]    mcause_regOut_ExceptionCode;
  // mtval
  wire [63:0]    mtval_rdata;
  wire [63:0]    mtval_regOut_ALL;
  // mip
  wire [63:0]    mip_rdata;
  wire           mip_regOut_SSIP;
  wire           mip_regOut_VSSIP;
  wire           mip_regOut_MSIP;
  wire           mip_regOut_STIP;
  wire           mip_regOut_VSTIP;
  wire           mip_regOut_MTIP;
  wire           mip_regOut_SEIP;
  wire           mip_regOut_VSEIP;
  wire           mip_regOut_MEIP;
  wire           mip_regOut_SGEIP;
  wire           mip_regOut_LCOFIP;
  wire           mip_rdataFields_SSIP;
  wire           mip_rdataFields_VSSIP;
  wire           mip_rdataFields_MSIP;
  wire           mip_rdataFields_STIP;
  wire           mip_rdataFields_VSTIP;
  wire           mip_rdataFields_MTIP;
  wire           mip_rdataFields_SEIP;
  wire           mip_rdataFields_VSEIP;
  wire           mip_rdataFields_MEIP;
  wire           mip_rdataFields_SGEIP;
  wire           mip_rdataFields_LCOFIP;
  wire           mip_toMvip_SEIP_valid;
  wire           mip_toMvip_SEIP_bits;
  wire           mip_toHvip_VSSIP_valid;
  wire           mip_toHvip_VSSIP_bits;
  // mtinst
  wire [63:0]    mtinst_rdata;
  wire [63:0]    mtinst_regOut_ALL;
  // mtval2
  wire [63:0]    mtval2_rdata;
  wire [63:0]    mtval2_regOut_ALL;
  // mseccfg
  wire [63:0]    mseccfg_rdata;
  wire [1:0]     mseccfg_regOut_PMM;
  // mcycle
  wire [63:0]    mcycle_rdata;
  wire [63:0]    mcycle_regOut_ALL;
  // minstret
  wire [63:0]    minstret_rdata;
  wire [63:0]    minstret_regOut_ALL;
  // mhpmcounters_0
  wire [63:0]    mhpmcounters_0_rdata;
  wire [63:0]    mhpmcounters_0_regOut_ALL;
  wire           mhpmcounters_0_toMhpmeventOF;
  // mhpmcounters_1
  wire [63:0]    mhpmcounters_1_rdata;
  wire [63:0]    mhpmcounters_1_regOut_ALL;
  wire           mhpmcounters_1_toMhpmeventOF;
  // mhpmcounters_2
  wire [63:0]    mhpmcounters_2_rdata;
  wire [63:0]    mhpmcounters_2_regOut_ALL;
  wire           mhpmcounters_2_toMhpmeventOF;
  // mhpmcounters_3
  wire [63:0]    mhpmcounters_3_rdata;
  wire [63:0]    mhpmcounters_3_regOut_ALL;
  wire           mhpmcounters_3_toMhpmeventOF;
  // mhpmcounters_4
  wire [63:0]    mhpmcounters_4_rdata;
  wire [63:0]    mhpmcounters_4_regOut_ALL;
  wire           mhpmcounters_4_toMhpmeventOF;
  // mhpmcounters_5
  wire [63:0]    mhpmcounters_5_rdata;
  wire [63:0]    mhpmcounters_5_regOut_ALL;
  wire           mhpmcounters_5_toMhpmeventOF;
  // mhpmcounters_6
  wire [63:0]    mhpmcounters_6_rdata;
  wire [63:0]    mhpmcounters_6_regOut_ALL;
  wire           mhpmcounters_6_toMhpmeventOF;
  // mhpmcounters_7
  wire [63:0]    mhpmcounters_7_rdata;
  wire [63:0]    mhpmcounters_7_regOut_ALL;
  wire           mhpmcounters_7_toMhpmeventOF;
  // mhpmcounters_8
  wire [63:0]    mhpmcounters_8_rdata;
  wire [63:0]    mhpmcounters_8_regOut_ALL;
  wire           mhpmcounters_8_toMhpmeventOF;
  // mhpmcounters_9
  wire [63:0]    mhpmcounters_9_rdata;
  wire [63:0]    mhpmcounters_9_regOut_ALL;
  wire           mhpmcounters_9_toMhpmeventOF;
  // mhpmcounters_10
  wire [63:0]    mhpmcounters_10_rdata;
  wire [63:0]    mhpmcounters_10_regOut_ALL;
  wire           mhpmcounters_10_toMhpmeventOF;
  // mhpmcounters_11
  wire [63:0]    mhpmcounters_11_rdata;
  wire [63:0]    mhpmcounters_11_regOut_ALL;
  wire           mhpmcounters_11_toMhpmeventOF;
  // mhpmcounters_12
  wire [63:0]    mhpmcounters_12_rdata;
  wire [63:0]    mhpmcounters_12_regOut_ALL;
  wire           mhpmcounters_12_toMhpmeventOF;
  // mhpmcounters_13
  wire [63:0]    mhpmcounters_13_rdata;
  wire [63:0]    mhpmcounters_13_regOut_ALL;
  wire           mhpmcounters_13_toMhpmeventOF;
  // mhpmcounters_14
  wire [63:0]    mhpmcounters_14_rdata;
  wire [63:0]    mhpmcounters_14_regOut_ALL;
  wire           mhpmcounters_14_toMhpmeventOF;
  // mhpmcounters_15
  wire [63:0]    mhpmcounters_15_rdata;
  wire [63:0]    mhpmcounters_15_regOut_ALL;
  wire           mhpmcounters_15_toMhpmeventOF;
  // mhpmcounters_16
  wire [63:0]    mhpmcounters_16_rdata;
  wire [63:0]    mhpmcounters_16_regOut_ALL;
  wire           mhpmcounters_16_toMhpmeventOF;
  // mhpmcounters_17
  wire [63:0]    mhpmcounters_17_rdata;
  wire [63:0]    mhpmcounters_17_regOut_ALL;
  wire           mhpmcounters_17_toMhpmeventOF;
  // mhpmcounters_18
  wire [63:0]    mhpmcounters_18_rdata;
  wire [63:0]    mhpmcounters_18_regOut_ALL;
  wire           mhpmcounters_18_toMhpmeventOF;
  // mhpmcounters_19
  wire [63:0]    mhpmcounters_19_rdata;
  wire [63:0]    mhpmcounters_19_regOut_ALL;
  wire           mhpmcounters_19_toMhpmeventOF;
  // mhpmcounters_20
  wire [63:0]    mhpmcounters_20_rdata;
  wire [63:0]    mhpmcounters_20_regOut_ALL;
  wire           mhpmcounters_20_toMhpmeventOF;
  // mhpmcounters_21
  wire [63:0]    mhpmcounters_21_rdata;
  wire [63:0]    mhpmcounters_21_regOut_ALL;
  wire           mhpmcounters_21_toMhpmeventOF;
  // mhpmcounters_22
  wire [63:0]    mhpmcounters_22_rdata;
  wire [63:0]    mhpmcounters_22_regOut_ALL;
  wire           mhpmcounters_22_toMhpmeventOF;
  // mhpmcounters_23
  wire [63:0]    mhpmcounters_23_rdata;
  wire [63:0]    mhpmcounters_23_regOut_ALL;
  wire           mhpmcounters_23_toMhpmeventOF;
  // mhpmcounters_24
  wire [63:0]    mhpmcounters_24_rdata;
  wire [63:0]    mhpmcounters_24_regOut_ALL;
  wire           mhpmcounters_24_toMhpmeventOF;
  // mhpmcounters_25
  wire [63:0]    mhpmcounters_25_rdata;
  wire [63:0]    mhpmcounters_25_regOut_ALL;
  wire           mhpmcounters_25_toMhpmeventOF;
  // mhpmcounters_26
  wire [63:0]    mhpmcounters_26_rdata;
  wire [63:0]    mhpmcounters_26_regOut_ALL;
  wire           mhpmcounters_26_toMhpmeventOF;
  // mhpmcounters_27
  wire [63:0]    mhpmcounters_27_rdata;
  wire [63:0]    mhpmcounters_27_regOut_ALL;
  wire           mhpmcounters_27_toMhpmeventOF;
  // mhpmcounters_28
  wire [63:0]    mhpmcounters_28_rdata;
  wire [63:0]    mhpmcounters_28_regOut_ALL;
  wire           mhpmcounters_28_toMhpmeventOF;
  // mhartid
  wire [63:0]    mhartid_rdata;
  // mconfigptr
  wire [63:0]    mconfigptr_rdata;
  // mstateen0
  wire [63:0]    mstateen0_rdata;
  wire           mstateen0_regOut_SE0;
  wire           mstateen0_regOut_ENVCFG;
  wire           mstateen0_regOut_CSRIND;
  wire           mstateen0_regOut_AIA;
  wire           mstateen0_regOut_IMSIC;
  wire           mstateen0_regOut_CONTEXT;
  wire           mstateen0_regOut_C;
  // mstateen1
  wire [63:0]    mstateen1_rdata;
  wire           mstateen1_regOut_SE;
  // mstateen2
  wire [63:0]    mstateen2_rdata;
  wire           mstateen2_regOut_SE;
  // mstateen3
  wire [63:0]    mstateen3_rdata;
  wire           mstateen3_regOut_SE;
  // mnepc
  wire [63:0]    mnepc_rdata;
  wire [62:0]    mnepc_regOut_epc;
  // mncause
  wire [63:0]    mncause_rdata;
  wire           mncause_regOut_Interrupt;
  wire [62:0]    mncause_regOut_ExceptionCode;
  // mnstatus
  wire [63:0]    mnstatus_rdata;
  wire           mnstatus_regOut_NMIE;
  wire           mnstatus_regOut_MNPV;
  wire [1:0]     mnstatus_regOut_MNPP;
  // mnscratch
  wire [63:0]    mnscratch_rdata;
  wire [63:0]    mnscratch_regOut_ALL;
  // mcontext
  wire [13:0]    mcontext_rdata;
  wire [13:0]    mcontext_regOut_HCONTEXT;
  wire [13:0]    mcontext_toHcontext_HCONTEXT;
  // sie
  wire [63:0]    sie_rdata;
  wire           sie_regOut_SSIE;
  wire           sie_regOut_STIE;
  wire           sie_regOut_SEIE;
  wire           sie_regOut_LCOFIE;
  wire           sie_regOut_LC14IE;
  wire           sie_regOut_LC15IE;
  wire           sie_regOut_LC16IE;
  wire           sie_regOut_LC17IE;
  wire           sie_regOut_LC18IE;
  wire           sie_regOut_LC19IE;
  wire           sie_regOut_LC20IE;
  wire           sie_regOut_LC21IE;
  wire           sie_regOut_LC22IE;
  wire           sie_regOut_LC23IE;
  wire           sie_regOut_LC24IE;
  wire           sie_regOut_LC25IE;
  wire           sie_regOut_LC26IE;
  wire           sie_regOut_LC27IE;
  wire           sie_regOut_LC28IE;
  wire           sie_regOut_LC29IE;
  wire           sie_regOut_LC30IE;
  wire           sie_regOut_LC31IE;
  wire           sie_regOut_LC32IE;
  wire           sie_regOut_LC33IE;
  wire           sie_regOut_LC34IE;
  wire           sie_regOut_LPRASEIE;
  wire           sie_regOut_LC36IE;
  wire           sie_regOut_LC37IE;
  wire           sie_regOut_LC38IE;
  wire           sie_regOut_LC39IE;
  wire           sie_regOut_LC40IE;
  wire           sie_regOut_LC41IE;
  wire           sie_regOut_LC42IE;
  wire           sie_regOut_HPRASEIE;
  wire           sie_regOut_LC44IE;
  wire           sie_regOut_LC45IE;
  wire           sie_regOut_LC46IE;
  wire           sie_regOut_LC47IE;
  wire           sie_regOut_LC48IE;
  wire           sie_regOut_LC49IE;
  wire           sie_regOut_LC50IE;
  wire           sie_regOut_LC51IE;
  wire           sie_regOut_LC52IE;
  wire           sie_regOut_LC53IE;
  wire           sie_regOut_LC54IE;
  wire           sie_regOut_LC55IE;
  wire           sie_regOut_LC56IE;
  wire           sie_regOut_LC57IE;
  wire           sie_regOut_LC58IE;
  wire           sie_regOut_LC59IE;
  wire           sie_regOut_LC60IE;
  wire           sie_regOut_LC61IE;
  wire           sie_regOut_LC62IE;
  wire           sie_regOut_LC63IE;
  wire           sie_toMie_SSIE_valid;
  wire           sie_toMie_SSIE_bits;
  wire           sie_toMie_STIE_valid;
  wire           sie_toMie_STIE_bits;
  wire           sie_toMie_SEIE_valid;
  wire           sie_toMie_SEIE_bits;
  wire           sie_toMie_LCOFIE_valid;
  wire           sie_toMie_LCOFIE_bits;
  // stvec
  wire [63:0]    stvec_rdata;
  wire [1:0]     stvec_regOut_mode;
  wire [61:0]    stvec_regOut_addr;
  // scounteren
  wire [63:0]    scounteren_rdata;
  wire           scounteren_regOut_CY;
  wire           scounteren_regOut_TM;
  wire           scounteren_regOut_IR;
  wire [28:0]    scounteren_regOut_HPM;
  // senvcfg
  wire [63:0]    senvcfg_rdata;
  wire [1:0]     senvcfg_regOut_PMM;
  wire           senvcfg_regOut_CBZE;
  wire           senvcfg_regOut_CBCFE;
  wire [1:0]     senvcfg_regOut_CBIE;
  // sscratch
  wire [63:0]    sscratch_rdata;
  wire [63:0]    sscratch_regOut_ALL;
  // sepc
  wire [63:0]    sepc_rdata;
  wire [62:0]    sepc_regOut_epc;
  // scause
  wire [63:0]    scause_rdata;
  wire           scause_regOut_Interrupt;
  wire [62:0]    scause_regOut_ExceptionCode;
  // stval
  wire [63:0]    stval_rdata;
  wire [63:0]    stval_regOut_ALL;
  // sip
  wire [63:0]    sip_rdata;
  wire           sip_regOut_SSIP;
  wire           sip_regOut_STIP;
  wire           sip_regOut_SEIP;
  wire           sip_regOut_LCOFIP;
  wire           sip_regOut_LC14IP;
  wire           sip_regOut_LC15IP;
  wire           sip_regOut_LC16IP;
  wire           sip_regOut_LC17IP;
  wire           sip_regOut_LC18IP;
  wire           sip_regOut_LC19IP;
  wire           sip_regOut_LC20IP;
  wire           sip_regOut_LC21IP;
  wire           sip_regOut_LC22IP;
  wire           sip_regOut_LC23IP;
  wire           sip_regOut_LC24IP;
  wire           sip_regOut_LC25IP;
  wire           sip_regOut_LC26IP;
  wire           sip_regOut_LC27IP;
  wire           sip_regOut_LC28IP;
  wire           sip_regOut_LC29IP;
  wire           sip_regOut_LC30IP;
  wire           sip_regOut_LC31IP;
  wire           sip_regOut_LC32IP;
  wire           sip_regOut_LC33IP;
  wire           sip_regOut_LC34IP;
  wire           sip_regOut_LPRASEIP;
  wire           sip_regOut_LC36IP;
  wire           sip_regOut_LC37IP;
  wire           sip_regOut_LC38IP;
  wire           sip_regOut_LC39IP;
  wire           sip_regOut_LC40IP;
  wire           sip_regOut_LC41IP;
  wire           sip_regOut_LC42IP;
  wire           sip_regOut_HPRASEIP;
  wire           sip_regOut_LC44IP;
  wire           sip_regOut_LC45IP;
  wire           sip_regOut_LC46IP;
  wire           sip_regOut_LC47IP;
  wire           sip_regOut_LC48IP;
  wire           sip_regOut_LC49IP;
  wire           sip_regOut_LC50IP;
  wire           sip_regOut_LC51IP;
  wire           sip_regOut_LC52IP;
  wire           sip_regOut_LC53IP;
  wire           sip_regOut_LC54IP;
  wire           sip_regOut_LC55IP;
  wire           sip_regOut_LC56IP;
  wire           sip_regOut_LC57IP;
  wire           sip_regOut_LC58IP;
  wire           sip_regOut_LC59IP;
  wire           sip_regOut_LC60IP;
  wire           sip_regOut_LC61IP;
  wire           sip_regOut_LC62IP;
  wire           sip_regOut_LC63IP;
  wire           sip_toMip_SSIP_valid;
  wire           sip_toMip_SSIP_bits;
  wire           sip_toMip_LCOFIP_valid;
  wire           sip_toMip_LCOFIP_bits;
  wire           sip_toMvip_SSIP_valid;
  wire           sip_toMvip_SSIP_bits;
  wire           sip_toMvip_LCOFIP_valid;
  wire           sip_toMvip_LCOFIP_bits;
  wire           sip_toMvip_LC14IP_valid;
  wire           sip_toMvip_LC14IP_bits;
  wire           sip_toMvip_LC15IP_valid;
  wire           sip_toMvip_LC15IP_bits;
  wire           sip_toMvip_LC16IP_valid;
  wire           sip_toMvip_LC16IP_bits;
  wire           sip_toMvip_LC17IP_valid;
  wire           sip_toMvip_LC17IP_bits;
  wire           sip_toMvip_LC18IP_valid;
  wire           sip_toMvip_LC18IP_bits;
  wire           sip_toMvip_LC19IP_valid;
  wire           sip_toMvip_LC19IP_bits;
  wire           sip_toMvip_LC20IP_valid;
  wire           sip_toMvip_LC20IP_bits;
  wire           sip_toMvip_LC21IP_valid;
  wire           sip_toMvip_LC21IP_bits;
  wire           sip_toMvip_LC22IP_valid;
  wire           sip_toMvip_LC22IP_bits;
  wire           sip_toMvip_LC23IP_valid;
  wire           sip_toMvip_LC23IP_bits;
  wire           sip_toMvip_LC24IP_valid;
  wire           sip_toMvip_LC24IP_bits;
  wire           sip_toMvip_LC25IP_valid;
  wire           sip_toMvip_LC25IP_bits;
  wire           sip_toMvip_LC26IP_valid;
  wire           sip_toMvip_LC26IP_bits;
  wire           sip_toMvip_LC27IP_valid;
  wire           sip_toMvip_LC27IP_bits;
  wire           sip_toMvip_LC28IP_valid;
  wire           sip_toMvip_LC28IP_bits;
  wire           sip_toMvip_LC29IP_valid;
  wire           sip_toMvip_LC29IP_bits;
  wire           sip_toMvip_LC30IP_valid;
  wire           sip_toMvip_LC30IP_bits;
  wire           sip_toMvip_LC31IP_valid;
  wire           sip_toMvip_LC31IP_bits;
  wire           sip_toMvip_LC32IP_valid;
  wire           sip_toMvip_LC32IP_bits;
  wire           sip_toMvip_LC33IP_valid;
  wire           sip_toMvip_LC33IP_bits;
  wire           sip_toMvip_LC34IP_valid;
  wire           sip_toMvip_LC34IP_bits;
  wire           sip_toMvip_LPRASEIP_valid;
  wire           sip_toMvip_LPRASEIP_bits;
  wire           sip_toMvip_LC36IP_valid;
  wire           sip_toMvip_LC36IP_bits;
  wire           sip_toMvip_LC37IP_valid;
  wire           sip_toMvip_LC37IP_bits;
  wire           sip_toMvip_LC38IP_valid;
  wire           sip_toMvip_LC38IP_bits;
  wire           sip_toMvip_LC39IP_valid;
  wire           sip_toMvip_LC39IP_bits;
  wire           sip_toMvip_LC40IP_valid;
  wire           sip_toMvip_LC40IP_bits;
  wire           sip_toMvip_LC41IP_valid;
  wire           sip_toMvip_LC41IP_bits;
  wire           sip_toMvip_LC42IP_valid;
  wire           sip_toMvip_LC42IP_bits;
  wire           sip_toMvip_HPRASEIP_valid;
  wire           sip_toMvip_HPRASEIP_bits;
  wire           sip_toMvip_LC44IP_valid;
  wire           sip_toMvip_LC44IP_bits;
  wire           sip_toMvip_LC45IP_valid;
  wire           sip_toMvip_LC45IP_bits;
  wire           sip_toMvip_LC46IP_valid;
  wire           sip_toMvip_LC46IP_bits;
  wire           sip_toMvip_LC47IP_valid;
  wire           sip_toMvip_LC47IP_bits;
  wire           sip_toMvip_LC48IP_valid;
  wire           sip_toMvip_LC48IP_bits;
  wire           sip_toMvip_LC49IP_valid;
  wire           sip_toMvip_LC49IP_bits;
  wire           sip_toMvip_LC50IP_valid;
  wire           sip_toMvip_LC50IP_bits;
  wire           sip_toMvip_LC51IP_valid;
  wire           sip_toMvip_LC51IP_bits;
  wire           sip_toMvip_LC52IP_valid;
  wire           sip_toMvip_LC52IP_bits;
  wire           sip_toMvip_LC53IP_valid;
  wire           sip_toMvip_LC53IP_bits;
  wire           sip_toMvip_LC54IP_valid;
  wire           sip_toMvip_LC54IP_bits;
  wire           sip_toMvip_LC55IP_valid;
  wire           sip_toMvip_LC55IP_bits;
  wire           sip_toMvip_LC56IP_valid;
  wire           sip_toMvip_LC56IP_bits;
  wire           sip_toMvip_LC57IP_valid;
  wire           sip_toMvip_LC57IP_bits;
  wire           sip_toMvip_LC58IP_valid;
  wire           sip_toMvip_LC58IP_bits;
  wire           sip_toMvip_LC59IP_valid;
  wire           sip_toMvip_LC59IP_bits;
  wire           sip_toMvip_LC60IP_valid;
  wire           sip_toMvip_LC60IP_bits;
  wire           sip_toMvip_LC61IP_valid;
  wire           sip_toMvip_LC61IP_bits;
  wire           sip_toMvip_LC62IP_valid;
  wire           sip_toMvip_LC62IP_bits;
  wire           sip_toMvip_LC63IP_valid;
  wire           sip_toMvip_LC63IP_bits;
  // stimecmp
  wire [63:0]    stimecmp_rdata;
  wire [63:0]    stimecmp_regOut_stimecmp;
  // satp
  wire [63:0]    satp_rdata;
  wire [3:0]     satp_regOut_MODE;
  wire [15:0]    satp_regOut_ASID;
  wire [43:0]    satp_regOut_PPN;
  // scountovf
  wire [31:0]    scountovf_rdata;
  // sstateen0
  wire [31:0]    sstateen0_rdata;
  wire           sstateen0_regOut_JVT;
  wire           sstateen0_regOut_FCSR;
  wire           sstateen0_regOut_C;
  // sstateen1
  wire [31:0]    sstateen1_rdata;
  wire [31:0]    sstateen1_regOut_ALL;
  // sstateen2
  wire [31:0]    sstateen2_rdata;
  wire [31:0]    sstateen2_regOut_ALL;
  // sstateen3
  wire [31:0]    sstateen3_rdata;
  wire [31:0]    sstateen3_regOut_ALL;
  // scontext
  wire [31:0]    scontext_rdata;
  wire [31:0]    scontext_regOut_ALL;
  // hstatus
  wire [63:0]    hstatus_rdata;
  wire           hstatus_regOut_GVA;
  wire           hstatus_regOut_SPV;
  wire           hstatus_regOut_SPVP;
  wire           hstatus_regOut_HU;
  wire [5:0]     hstatus_regOut_VGEIN;
  wire           hstatus_regOut_VTVM;
  wire           hstatus_regOut_VTW;
  wire           hstatus_regOut_VTSR;
  wire [1:0]     hstatus_regOut_HUPMM;
  // hedeleg
  wire [63:0]    hedeleg_rdata;
  wire           hedeleg_regOut_EX_IAM;
  wire           hedeleg_regOut_EX_IAF;
  wire           hedeleg_regOut_EX_II;
  wire           hedeleg_regOut_EX_BP;
  wire           hedeleg_regOut_EX_LAM;
  wire           hedeleg_regOut_EX_LAF;
  wire           hedeleg_regOut_EX_SAM;
  wire           hedeleg_regOut_EX_SAF;
  wire           hedeleg_regOut_EX_UCALL;
  wire           hedeleg_regOut_EX_IPF;
  wire           hedeleg_regOut_EX_LPF;
  wire           hedeleg_regOut_EX_SPF;
  wire           hedeleg_regOut_EX_SWC;
  wire           hedeleg_regOut_EX_HWE;
  // hideleg
  wire [63:0]    hideleg_rdata;
  wire           hideleg_regOut_SSI;
  wire           hideleg_regOut_VSSI;
  wire           hideleg_regOut_MSI;
  wire           hideleg_regOut_STI;
  wire           hideleg_regOut_VSTI;
  wire           hideleg_regOut_MTI;
  wire           hideleg_regOut_SEI;
  wire           hideleg_regOut_VSEI;
  wire           hideleg_regOut_MEI;
  wire           hideleg_regOut_SGEI;
  wire           hideleg_regOut_LCOFI;
  // hie
  wire [63:0]    hie_rdata;
  wire           hie_regOut_VSSIE;
  wire           hie_regOut_VSTIE;
  wire           hie_regOut_VSEIE;
  wire           hie_regOut_SGEIE;
  wire           hie_toMie_VSSIE_valid;
  wire           hie_toMie_VSSIE_bits;
  wire           hie_toMie_VSTIE_valid;
  wire           hie_toMie_VSTIE_bits;
  wire           hie_toMie_VSEIE_valid;
  wire           hie_toMie_VSEIE_bits;
  wire           hie_toMie_SGEIE_valid;
  wire           hie_toMie_SGEIE_bits;
  // htimedelta
  wire [63:0]    htimedelta_rdata;
  wire [63:0]    htimedelta_regOut_ALL;
  // hcounteren
  wire [63:0]    hcounteren_rdata;
  wire           hcounteren_regOut_CY;
  wire           hcounteren_regOut_TM;
  wire           hcounteren_regOut_IR;
  wire [28:0]    hcounteren_regOut_HPM;
  // hgeie
  wire [63:0]    hgeie_rdata;
  wire [6:0]     hgeie_regOut_ie;
  // hvien
  wire [63:0]    hvien_rdata;
  wire           hvien_regOut_LC14IE;
  wire           hvien_regOut_LC15IE;
  wire           hvien_regOut_LC16IE;
  wire           hvien_regOut_LC17IE;
  wire           hvien_regOut_LC18IE;
  wire           hvien_regOut_LC19IE;
  wire           hvien_regOut_LC20IE;
  wire           hvien_regOut_LC21IE;
  wire           hvien_regOut_LC22IE;
  wire           hvien_regOut_LC23IE;
  wire           hvien_regOut_LC24IE;
  wire           hvien_regOut_LC25IE;
  wire           hvien_regOut_LC26IE;
  wire           hvien_regOut_LC27IE;
  wire           hvien_regOut_LC28IE;
  wire           hvien_regOut_LC29IE;
  wire           hvien_regOut_LC30IE;
  wire           hvien_regOut_LC31IE;
  wire           hvien_regOut_LC32IE;
  wire           hvien_regOut_LC33IE;
  wire           hvien_regOut_LC34IE;
  wire           hvien_regOut_LPRASEIE;
  wire           hvien_regOut_LC36IE;
  wire           hvien_regOut_LC37IE;
  wire           hvien_regOut_LC38IE;
  wire           hvien_regOut_LC39IE;
  wire           hvien_regOut_LC40IE;
  wire           hvien_regOut_LC41IE;
  wire           hvien_regOut_LC42IE;
  wire           hvien_regOut_HPRASEIE;
  wire           hvien_regOut_LC44IE;
  wire           hvien_regOut_LC45IE;
  wire           hvien_regOut_LC46IE;
  wire           hvien_regOut_LC47IE;
  wire           hvien_regOut_LC48IE;
  wire           hvien_regOut_LC49IE;
  wire           hvien_regOut_LC50IE;
  wire           hvien_regOut_LC51IE;
  wire           hvien_regOut_LC52IE;
  wire           hvien_regOut_LC53IE;
  wire           hvien_regOut_LC54IE;
  wire           hvien_regOut_LC55IE;
  wire           hvien_regOut_LC56IE;
  wire           hvien_regOut_LC57IE;
  wire           hvien_regOut_LC58IE;
  wire           hvien_regOut_LC59IE;
  wire           hvien_regOut_LC60IE;
  wire           hvien_regOut_LC61IE;
  wire           hvien_regOut_LC62IE;
  wire           hvien_regOut_LC63IE;
  // hvictl
  wire [63:0]    hvictl_rdata;
  wire           hvictl_regOut_VTI;
  wire [11:0]    hvictl_regOut_IID;
  wire           hvictl_regOut_DPR;
  wire           hvictl_regOut_IPRIOM;
  wire [7:0]     hvictl_regOut_IPRIO;
  // henvcfg
  wire [63:0]    henvcfg_rdata;
  wire           henvcfg_regOut_STCE;
  wire           henvcfg_regOut_PBMTE;
  wire           henvcfg_regOut_DTE;
  wire [1:0]     henvcfg_regOut_PMM;
  wire           henvcfg_regOut_CBZE;
  wire           henvcfg_regOut_CBCFE;
  wire [1:0]     henvcfg_regOut_CBIE;
  // htval
  wire [63:0]    htval_rdata;
  wire [63:0]    htval_regOut_ALL;
  // hip
  wire [63:0]    hip_rdata;
  wire           hip_regOut_VSSIP;
  wire           hip_regOut_VSTIP;
  wire           hip_regOut_VSEIP;
  wire           hip_regOut_SGEIP;
  wire           hip_toHvip_VSSIP_valid;
  wire           hip_toHvip_VSSIP_bits;
  // hvip
  wire [63:0]    hvip_rdata;
  wire           hvip_regOut_VSSIP;
  wire           hvip_regOut_VSTIP;
  wire           hvip_regOut_VSEIP;
  wire           hvip_regOut_LCOFIP;
  wire           hvip_regOut_LC14IP;
  wire           hvip_regOut_LC15IP;
  wire           hvip_regOut_LC16IP;
  wire           hvip_regOut_LC17IP;
  wire           hvip_regOut_LC18IP;
  wire           hvip_regOut_LC19IP;
  wire           hvip_regOut_LC20IP;
  wire           hvip_regOut_LC21IP;
  wire           hvip_regOut_LC22IP;
  wire           hvip_regOut_LC23IP;
  wire           hvip_regOut_LC24IP;
  wire           hvip_regOut_LC25IP;
  wire           hvip_regOut_LC26IP;
  wire           hvip_regOut_LC27IP;
  wire           hvip_regOut_LC28IP;
  wire           hvip_regOut_LC29IP;
  wire           hvip_regOut_LC30IP;
  wire           hvip_regOut_LC31IP;
  wire           hvip_regOut_LC32IP;
  wire           hvip_regOut_LC33IP;
  wire           hvip_regOut_LC34IP;
  wire           hvip_regOut_LPRASEIP;
  wire           hvip_regOut_LC36IP;
  wire           hvip_regOut_LC37IP;
  wire           hvip_regOut_LC38IP;
  wire           hvip_regOut_LC39IP;
  wire           hvip_regOut_LC40IP;
  wire           hvip_regOut_LC41IP;
  wire           hvip_regOut_LC42IP;
  wire           hvip_regOut_HPRASEIP;
  wire           hvip_regOut_LC44IP;
  wire           hvip_regOut_LC45IP;
  wire           hvip_regOut_LC46IP;
  wire           hvip_regOut_LC47IP;
  wire           hvip_regOut_LC48IP;
  wire           hvip_regOut_LC49IP;
  wire           hvip_regOut_LC50IP;
  wire           hvip_regOut_LC51IP;
  wire           hvip_regOut_LC52IP;
  wire           hvip_regOut_LC53IP;
  wire           hvip_regOut_LC54IP;
  wire           hvip_regOut_LC55IP;
  wire           hvip_regOut_LC56IP;
  wire           hvip_regOut_LC57IP;
  wire           hvip_regOut_LC58IP;
  wire           hvip_regOut_LC59IP;
  wire           hvip_regOut_LC60IP;
  wire           hvip_regOut_LC61IP;
  wire           hvip_regOut_LC62IP;
  wire           hvip_regOut_LC63IP;
  // hviprio1
  wire [63:0]    hviprio1_rdata;
  wire [7:0]     hviprio1_regOut_PrioSSI;
  wire [7:0]     hviprio1_regOut_PrioSTI;
  wire [7:0]     hviprio1_regOut_PrioCOI;
  wire [7:0]     hviprio1_regOut_Prio14;
  wire [7:0]     hviprio1_regOut_Prio15;
  // hviprio2
  wire [63:0]    hviprio2_rdata;
  wire [63:0]    hviprio2_regOut_ALL;
  // htinst
  wire [63:0]    htinst_rdata;
  wire [63:0]    htinst_regOut_ALL;
  // hgatp
  wire [63:0]    hgatp_rdata;
  wire [3:0]     hgatp_regOut_MODE;
  wire [13:0]    hgatp_regOut_VMID;
  wire [43:0]    hgatp_regOut_PPN;
  // hgeip
  wire [63:0]    hgeip_rdata;
  wire [6:0]     hgeip_regOut_ip;
  // hstateen0
  wire [63:0]    hstateen0_rdata;
  wire           hstateen0_regOut_JVT;
  wire           hstateen0_regOut_FCSR;
  wire           hstateen0_regOut_C;
  wire           hstateen0_regOut_SE0;
  wire           hstateen0_regOut_ENVCFG;
  wire           hstateen0_regOut_CSRIND;
  wire           hstateen0_regOut_AIA;
  wire           hstateen0_regOut_IMSIC;
  wire           hstateen0_regOut_CONTEXT;
  // hstateen1
  wire [63:0]    hstateen1_rdata;
  wire           hstateen1_regOut_SE;
  // hstateen2
  wire [63:0]    hstateen2_rdata;
  wire           hstateen2_regOut_SE;
  // hstateen3
  wire [63:0]    hstateen3_rdata;
  wire           hstateen3_regOut_SE;
  // hcontext
  wire [13:0]    hcontext_rdata;
  wire [13:0]    hcontext_regOut_HCONTEXT;
  wire           hcontext_toMcontext_valid;
  wire [13:0]    hcontext_toMcontext_bits_HCONTEXT;
  // vsstatus
  wire [63:0]    vsstatus_rdata;
  wire           vsstatus_regOut_SIE;
  wire           vsstatus_regOut_SPIE;
  wire           vsstatus_regOut_SPP;
  wire [1:0]     vsstatus_regOut_VS;
  wire [1:0]     vsstatus_regOut_FS;
  wire           vsstatus_regOut_SUM;
  wire           vsstatus_regOut_MXR;
  wire           vsstatus_regOut_SDT;
  // vsie
  wire [63:0]    vsie_rdata;
  wire           vsie_regOut_SSIE;
  wire           vsie_regOut_STIE;
  wire           vsie_regOut_SEIE;
  wire           vsie_regOut_LCOFIE;
  wire           vsie_regOut_LC14IE;
  wire           vsie_regOut_LC15IE;
  wire           vsie_regOut_LC16IE;
  wire           vsie_regOut_LC17IE;
  wire           vsie_regOut_LC18IE;
  wire           vsie_regOut_LC19IE;
  wire           vsie_regOut_LC20IE;
  wire           vsie_regOut_LC21IE;
  wire           vsie_regOut_LC22IE;
  wire           vsie_regOut_LC23IE;
  wire           vsie_regOut_LC24IE;
  wire           vsie_regOut_LC25IE;
  wire           vsie_regOut_LC26IE;
  wire           vsie_regOut_LC27IE;
  wire           vsie_regOut_LC28IE;
  wire           vsie_regOut_LC29IE;
  wire           vsie_regOut_LC30IE;
  wire           vsie_regOut_LC31IE;
  wire           vsie_regOut_LC32IE;
  wire           vsie_regOut_LC33IE;
  wire           vsie_regOut_LC34IE;
  wire           vsie_regOut_LPRASEIE;
  wire           vsie_regOut_LC36IE;
  wire           vsie_regOut_LC37IE;
  wire           vsie_regOut_LC38IE;
  wire           vsie_regOut_LC39IE;
  wire           vsie_regOut_LC40IE;
  wire           vsie_regOut_LC41IE;
  wire           vsie_regOut_LC42IE;
  wire           vsie_regOut_HPRASEIE;
  wire           vsie_regOut_LC44IE;
  wire           vsie_regOut_LC45IE;
  wire           vsie_regOut_LC46IE;
  wire           vsie_regOut_LC47IE;
  wire           vsie_regOut_LC48IE;
  wire           vsie_regOut_LC49IE;
  wire           vsie_regOut_LC50IE;
  wire           vsie_regOut_LC51IE;
  wire           vsie_regOut_LC52IE;
  wire           vsie_regOut_LC53IE;
  wire           vsie_regOut_LC54IE;
  wire           vsie_regOut_LC55IE;
  wire           vsie_regOut_LC56IE;
  wire           vsie_regOut_LC57IE;
  wire           vsie_regOut_LC58IE;
  wire           vsie_regOut_LC59IE;
  wire           vsie_regOut_LC60IE;
  wire           vsie_regOut_LC61IE;
  wire           vsie_regOut_LC62IE;
  wire           vsie_regOut_LC63IE;
  wire           vsie_toMie_VSSIE_valid;
  wire           vsie_toMie_VSSIE_bits;
  wire           vsie_toMie_VSTIE_valid;
  wire           vsie_toMie_VSTIE_bits;
  wire           vsie_toMie_VSEIE_valid;
  wire           vsie_toMie_VSEIE_bits;
  wire           vsie_toMie_LCOFIE_valid;
  wire           vsie_toMie_LCOFIE_bits;
  wire           vsie_toSie_VSSIE_valid;
  wire           vsie_toSie_VSSIE_bits;
  wire           vsie_toSie_VSTIE_valid;
  wire           vsie_toSie_VSTIE_bits;
  wire           vsie_toSie_VSEIE_valid;
  wire           vsie_toSie_VSEIE_bits;
  wire           vsie_toSie_LCOFIE_valid;
  wire           vsie_toSie_LCOFIE_bits;
  wire           vsie_toSie_LC14IE_valid;
  wire           vsie_toSie_LC14IE_bits;
  wire           vsie_toSie_LC15IE_valid;
  wire           vsie_toSie_LC15IE_bits;
  wire           vsie_toSie_LC16IE_valid;
  wire           vsie_toSie_LC16IE_bits;
  wire           vsie_toSie_LC17IE_valid;
  wire           vsie_toSie_LC17IE_bits;
  wire           vsie_toSie_LC18IE_valid;
  wire           vsie_toSie_LC18IE_bits;
  wire           vsie_toSie_LC19IE_valid;
  wire           vsie_toSie_LC19IE_bits;
  wire           vsie_toSie_LC20IE_valid;
  wire           vsie_toSie_LC20IE_bits;
  wire           vsie_toSie_LC21IE_valid;
  wire           vsie_toSie_LC21IE_bits;
  wire           vsie_toSie_LC22IE_valid;
  wire           vsie_toSie_LC22IE_bits;
  wire           vsie_toSie_LC23IE_valid;
  wire           vsie_toSie_LC23IE_bits;
  wire           vsie_toSie_LC24IE_valid;
  wire           vsie_toSie_LC24IE_bits;
  wire           vsie_toSie_LC25IE_valid;
  wire           vsie_toSie_LC25IE_bits;
  wire           vsie_toSie_LC26IE_valid;
  wire           vsie_toSie_LC26IE_bits;
  wire           vsie_toSie_LC27IE_valid;
  wire           vsie_toSie_LC27IE_bits;
  wire           vsie_toSie_LC28IE_valid;
  wire           vsie_toSie_LC28IE_bits;
  wire           vsie_toSie_LC29IE_valid;
  wire           vsie_toSie_LC29IE_bits;
  wire           vsie_toSie_LC30IE_valid;
  wire           vsie_toSie_LC30IE_bits;
  wire           vsie_toSie_LC31IE_valid;
  wire           vsie_toSie_LC31IE_bits;
  wire           vsie_toSie_LC32IE_valid;
  wire           vsie_toSie_LC32IE_bits;
  wire           vsie_toSie_LC33IE_valid;
  wire           vsie_toSie_LC33IE_bits;
  wire           vsie_toSie_LC34IE_valid;
  wire           vsie_toSie_LC34IE_bits;
  wire           vsie_toSie_LPRASEIE_valid;
  wire           vsie_toSie_LPRASEIE_bits;
  wire           vsie_toSie_LC36IE_valid;
  wire           vsie_toSie_LC36IE_bits;
  wire           vsie_toSie_LC37IE_valid;
  wire           vsie_toSie_LC37IE_bits;
  wire           vsie_toSie_LC38IE_valid;
  wire           vsie_toSie_LC38IE_bits;
  wire           vsie_toSie_LC39IE_valid;
  wire           vsie_toSie_LC39IE_bits;
  wire           vsie_toSie_LC40IE_valid;
  wire           vsie_toSie_LC40IE_bits;
  wire           vsie_toSie_LC41IE_valid;
  wire           vsie_toSie_LC41IE_bits;
  wire           vsie_toSie_LC42IE_valid;
  wire           vsie_toSie_LC42IE_bits;
  wire           vsie_toSie_HPRASEIE_valid;
  wire           vsie_toSie_HPRASEIE_bits;
  wire           vsie_toSie_LC44IE_valid;
  wire           vsie_toSie_LC44IE_bits;
  wire           vsie_toSie_LC45IE_valid;
  wire           vsie_toSie_LC45IE_bits;
  wire           vsie_toSie_LC46IE_valid;
  wire           vsie_toSie_LC46IE_bits;
  wire           vsie_toSie_LC47IE_valid;
  wire           vsie_toSie_LC47IE_bits;
  wire           vsie_toSie_LC48IE_valid;
  wire           vsie_toSie_LC48IE_bits;
  wire           vsie_toSie_LC49IE_valid;
  wire           vsie_toSie_LC49IE_bits;
  wire           vsie_toSie_LC50IE_valid;
  wire           vsie_toSie_LC50IE_bits;
  wire           vsie_toSie_LC51IE_valid;
  wire           vsie_toSie_LC51IE_bits;
  wire           vsie_toSie_LC52IE_valid;
  wire           vsie_toSie_LC52IE_bits;
  wire           vsie_toSie_LC53IE_valid;
  wire           vsie_toSie_LC53IE_bits;
  wire           vsie_toSie_LC54IE_valid;
  wire           vsie_toSie_LC54IE_bits;
  wire           vsie_toSie_LC55IE_valid;
  wire           vsie_toSie_LC55IE_bits;
  wire           vsie_toSie_LC56IE_valid;
  wire           vsie_toSie_LC56IE_bits;
  wire           vsie_toSie_LC57IE_valid;
  wire           vsie_toSie_LC57IE_bits;
  wire           vsie_toSie_LC58IE_valid;
  wire           vsie_toSie_LC58IE_bits;
  wire           vsie_toSie_LC59IE_valid;
  wire           vsie_toSie_LC59IE_bits;
  wire           vsie_toSie_LC60IE_valid;
  wire           vsie_toSie_LC60IE_bits;
  wire           vsie_toSie_LC61IE_valid;
  wire           vsie_toSie_LC61IE_bits;
  wire           vsie_toSie_LC62IE_valid;
  wire           vsie_toSie_LC62IE_bits;
  wire           vsie_toSie_LC63IE_valid;
  wire           vsie_toSie_LC63IE_bits;
  // vstvec
  wire [63:0]    vstvec_rdata;
  wire [1:0]     vstvec_regOut_mode;
  wire [61:0]    vstvec_regOut_addr;
  // vsscratch
  wire [63:0]    vsscratch_rdata;
  wire [63:0]    vsscratch_regOut_ALL;
  // vsepc
  wire [63:0]    vsepc_rdata;
  wire [62:0]    vsepc_regOut_epc;
  // vscause
  wire [63:0]    vscause_rdata;
  wire           vscause_regOut_Interrupt;
  wire [62:0]    vscause_regOut_ExceptionCode;
  // vstval
  wire [63:0]    vstval_rdata;
  wire [63:0]    vstval_regOut_ALL;
  // vsip
  wire [63:0]    vsip_rdata;
  wire           vsip_regOut_SSIP;
  wire           vsip_regOut_STIP;
  wire           vsip_regOut_SEIP;
  wire           vsip_regOut_LCOFIP;
  wire           vsip_regOut_LC14IP;
  wire           vsip_regOut_LC15IP;
  wire           vsip_regOut_LC16IP;
  wire           vsip_regOut_LC17IP;
  wire           vsip_regOut_LC18IP;
  wire           vsip_regOut_LC19IP;
  wire           vsip_regOut_LC20IP;
  wire           vsip_regOut_LC21IP;
  wire           vsip_regOut_LC22IP;
  wire           vsip_regOut_LC23IP;
  wire           vsip_regOut_LC24IP;
  wire           vsip_regOut_LC25IP;
  wire           vsip_regOut_LC26IP;
  wire           vsip_regOut_LC27IP;
  wire           vsip_regOut_LC28IP;
  wire           vsip_regOut_LC29IP;
  wire           vsip_regOut_LC30IP;
  wire           vsip_regOut_LC31IP;
  wire           vsip_regOut_LC32IP;
  wire           vsip_regOut_LC33IP;
  wire           vsip_regOut_LC34IP;
  wire           vsip_regOut_LPRASEIP;
  wire           vsip_regOut_LC36IP;
  wire           vsip_regOut_LC37IP;
  wire           vsip_regOut_LC38IP;
  wire           vsip_regOut_LC39IP;
  wire           vsip_regOut_LC40IP;
  wire           vsip_regOut_LC41IP;
  wire           vsip_regOut_LC42IP;
  wire           vsip_regOut_HPRASEIP;
  wire           vsip_regOut_LC44IP;
  wire           vsip_regOut_LC45IP;
  wire           vsip_regOut_LC46IP;
  wire           vsip_regOut_LC47IP;
  wire           vsip_regOut_LC48IP;
  wire           vsip_regOut_LC49IP;
  wire           vsip_regOut_LC50IP;
  wire           vsip_regOut_LC51IP;
  wire           vsip_regOut_LC52IP;
  wire           vsip_regOut_LC53IP;
  wire           vsip_regOut_LC54IP;
  wire           vsip_regOut_LC55IP;
  wire           vsip_regOut_LC56IP;
  wire           vsip_regOut_LC57IP;
  wire           vsip_regOut_LC58IP;
  wire           vsip_regOut_LC59IP;
  wire           vsip_regOut_LC60IP;
  wire           vsip_regOut_LC61IP;
  wire           vsip_regOut_LC62IP;
  wire           vsip_regOut_LC63IP;
  wire           vsip_toMip_LCOFIP_valid;
  wire           vsip_toMip_LCOFIP_bits;
  wire           vsip_toHvip_VSSIP_valid;
  wire           vsip_toHvip_VSSIP_bits;
  wire           vsip_toHvip_LCOFIP_bits;
  wire           vsip_toHvip_LC14IP_valid;
  wire           vsip_toHvip_LC14IP_bits;
  wire           vsip_toHvip_LC15IP_valid;
  wire           vsip_toHvip_LC15IP_bits;
  wire           vsip_toHvip_LC16IP_valid;
  wire           vsip_toHvip_LC16IP_bits;
  wire           vsip_toHvip_LC17IP_valid;
  wire           vsip_toHvip_LC17IP_bits;
  wire           vsip_toHvip_LC18IP_valid;
  wire           vsip_toHvip_LC18IP_bits;
  wire           vsip_toHvip_LC19IP_valid;
  wire           vsip_toHvip_LC19IP_bits;
  wire           vsip_toHvip_LC20IP_valid;
  wire           vsip_toHvip_LC20IP_bits;
  wire           vsip_toHvip_LC21IP_valid;
  wire           vsip_toHvip_LC21IP_bits;
  wire           vsip_toHvip_LC22IP_valid;
  wire           vsip_toHvip_LC22IP_bits;
  wire           vsip_toHvip_LC23IP_valid;
  wire           vsip_toHvip_LC23IP_bits;
  wire           vsip_toHvip_LC24IP_valid;
  wire           vsip_toHvip_LC24IP_bits;
  wire           vsip_toHvip_LC25IP_valid;
  wire           vsip_toHvip_LC25IP_bits;
  wire           vsip_toHvip_LC26IP_valid;
  wire           vsip_toHvip_LC26IP_bits;
  wire           vsip_toHvip_LC27IP_valid;
  wire           vsip_toHvip_LC27IP_bits;
  wire           vsip_toHvip_LC28IP_valid;
  wire           vsip_toHvip_LC28IP_bits;
  wire           vsip_toHvip_LC29IP_valid;
  wire           vsip_toHvip_LC29IP_bits;
  wire           vsip_toHvip_LC30IP_valid;
  wire           vsip_toHvip_LC30IP_bits;
  wire           vsip_toHvip_LC31IP_valid;
  wire           vsip_toHvip_LC31IP_bits;
  wire           vsip_toHvip_LC32IP_valid;
  wire           vsip_toHvip_LC32IP_bits;
  wire           vsip_toHvip_LC33IP_valid;
  wire           vsip_toHvip_LC33IP_bits;
  wire           vsip_toHvip_LC34IP_valid;
  wire           vsip_toHvip_LC34IP_bits;
  wire           vsip_toHvip_LPRASEIP_valid;
  wire           vsip_toHvip_LPRASEIP_bits;
  wire           vsip_toHvip_LC36IP_valid;
  wire           vsip_toHvip_LC36IP_bits;
  wire           vsip_toHvip_LC37IP_valid;
  wire           vsip_toHvip_LC37IP_bits;
  wire           vsip_toHvip_LC38IP_valid;
  wire           vsip_toHvip_LC38IP_bits;
  wire           vsip_toHvip_LC39IP_valid;
  wire           vsip_toHvip_LC39IP_bits;
  wire           vsip_toHvip_LC40IP_valid;
  wire           vsip_toHvip_LC40IP_bits;
  wire           vsip_toHvip_LC41IP_valid;
  wire           vsip_toHvip_LC41IP_bits;
  wire           vsip_toHvip_LC42IP_valid;
  wire           vsip_toHvip_LC42IP_bits;
  wire           vsip_toHvip_HPRASEIP_valid;
  wire           vsip_toHvip_HPRASEIP_bits;
  wire           vsip_toHvip_LC44IP_valid;
  wire           vsip_toHvip_LC44IP_bits;
  wire           vsip_toHvip_LC45IP_valid;
  wire           vsip_toHvip_LC45IP_bits;
  wire           vsip_toHvip_LC46IP_valid;
  wire           vsip_toHvip_LC46IP_bits;
  wire           vsip_toHvip_LC47IP_valid;
  wire           vsip_toHvip_LC47IP_bits;
  wire           vsip_toHvip_LC48IP_valid;
  wire           vsip_toHvip_LC48IP_bits;
  wire           vsip_toHvip_LC49IP_valid;
  wire           vsip_toHvip_LC49IP_bits;
  wire           vsip_toHvip_LC50IP_valid;
  wire           vsip_toHvip_LC50IP_bits;
  wire           vsip_toHvip_LC51IP_valid;
  wire           vsip_toHvip_LC51IP_bits;
  wire           vsip_toHvip_LC52IP_valid;
  wire           vsip_toHvip_LC52IP_bits;
  wire           vsip_toHvip_LC53IP_valid;
  wire           vsip_toHvip_LC53IP_bits;
  wire           vsip_toHvip_LC54IP_valid;
  wire           vsip_toHvip_LC54IP_bits;
  wire           vsip_toHvip_LC55IP_valid;
  wire           vsip_toHvip_LC55IP_bits;
  wire           vsip_toHvip_LC56IP_valid;
  wire           vsip_toHvip_LC56IP_bits;
  wire           vsip_toHvip_LC57IP_valid;
  wire           vsip_toHvip_LC57IP_bits;
  wire           vsip_toHvip_LC58IP_valid;
  wire           vsip_toHvip_LC58IP_bits;
  wire           vsip_toHvip_LC59IP_valid;
  wire           vsip_toHvip_LC59IP_bits;
  wire           vsip_toHvip_LC60IP_valid;
  wire           vsip_toHvip_LC60IP_bits;
  wire           vsip_toHvip_LC61IP_valid;
  wire           vsip_toHvip_LC61IP_bits;
  wire           vsip_toHvip_LC62IP_valid;
  wire           vsip_toHvip_LC62IP_bits;
  wire           vsip_toHvip_LC63IP_valid;
  wire           vsip_toHvip_LC63IP_bits;
  // vstimecmp
  wire [63:0]    vstimecmp_rdata;
  wire [63:0]    vstimecmp_regOut_vstimecmp;
  // vsatp
  wire [63:0]    vsatp_rdata;
  wire [3:0]     vsatp_regOut_MODE;
  wire [15:0]    vsatp_regOut_ASID;
  wire [43:0]    vsatp_regOut_PPN;
  // fcsr
  wire [63:0]    fcsr_rdata;
  wire [4:0]     fcsr_fflags;
  wire [2:0]     fcsr_frm;
  wire [4:0]     fcsr_fflagsRdata;
  wire [2:0]     fcsr_frmRdata;
  // vstart
  wire [63:0]    vstart_rdata;
  wire [6:0]     vstart_regOut_vstart;
  // vcsr
  wire [63:0]    vcsr_rdata;
  wire           vcsr_vxsat;
  wire [1:0]     vcsr_vxrm;
  // vtype
  wire [63:0]    vtype_rdata;
  // cycle
  wire [63:0]    cycle_rdata;
  // time_0
  wire [63:0]    time_0_rdata;
  wire           time_0_updated;
  wire [63:0]    time_0_stime;
  wire [63:0]    time_0_vstime;
  // instret
  wire [63:0]    instret_rdata;
  // hpmcounters_0
  wire [63:0]    hpmcounters_0_rdata;
  // hpmcounters_1
  wire [63:0]    hpmcounters_1_rdata;
  // hpmcounters_2
  wire [63:0]    hpmcounters_2_rdata;
  // hpmcounters_3
  wire [63:0]    hpmcounters_3_rdata;
  // hpmcounters_4
  wire [63:0]    hpmcounters_4_rdata;
  // hpmcounters_5
  wire [63:0]    hpmcounters_5_rdata;
  // hpmcounters_6
  wire [63:0]    hpmcounters_6_rdata;
  // hpmcounters_7
  wire [63:0]    hpmcounters_7_rdata;
  // hpmcounters_8
  wire [63:0]    hpmcounters_8_rdata;
  // hpmcounters_9
  wire [63:0]    hpmcounters_9_rdata;
  // hpmcounters_10
  wire [63:0]    hpmcounters_10_rdata;
  // hpmcounters_11
  wire [63:0]    hpmcounters_11_rdata;
  // hpmcounters_12
  wire [63:0]    hpmcounters_12_rdata;
  // hpmcounters_13
  wire [63:0]    hpmcounters_13_rdata;
  // hpmcounters_14
  wire [63:0]    hpmcounters_14_rdata;
  // hpmcounters_15
  wire [63:0]    hpmcounters_15_rdata;
  // hpmcounters_16
  wire [63:0]    hpmcounters_16_rdata;
  // hpmcounters_17
  wire [63:0]    hpmcounters_17_rdata;
  // hpmcounters_18
  wire [63:0]    hpmcounters_18_rdata;
  // hpmcounters_19
  wire [63:0]    hpmcounters_19_rdata;
  // hpmcounters_20
  wire [63:0]    hpmcounters_20_rdata;
  // hpmcounters_21
  wire [63:0]    hpmcounters_21_rdata;
  // hpmcounters_22
  wire [63:0]    hpmcounters_22_rdata;
  // hpmcounters_23
  wire [63:0]    hpmcounters_23_rdata;
  // hpmcounters_24
  wire [63:0]    hpmcounters_24_rdata;
  // hpmcounters_25
  wire [63:0]    hpmcounters_25_rdata;
  // hpmcounters_26
  wire [63:0]    hpmcounters_26_rdata;
  // hpmcounters_27
  wire [63:0]    hpmcounters_27_rdata;
  // hpmcounters_28
  wire [63:0]    hpmcounters_28_rdata;
  // miselect
  wire [63:0]    miselect_rdata;
  wire [8:0]     miselect_regOut_ALL;
  wire           miselect_inIMSICRange;
  // mireg
  wire [63:0]    mireg_rdata;
  wire [63:0]    mireg_regOut_ALL;
  // mtopei
  wire [63:0]    mtopei_rdata;
  wire [10:0]    mtopei_regOut_IID;
  wire [10:0]    mtopei_regOut_IPRIO;
  // mtopi
  wire [63:0]    mtopi_rdata;
  wire [11:0]    mtopi_regOut_IID;
  // siselect
  wire [63:0]    siselect_rdata;
  wire [12:0]    siselect_regOut_ALL;
  wire           siselect_inIMSICRange;
  // sireg
  wire [63:0]    sireg_rdata;
  wire [63:0]    sireg_regOut_ALL;
  // stopei
  wire [63:0]    stopei_rdata;
  wire [10:0]    stopei_regOut_IID;
  wire [10:0]    stopei_regOut_IPRIO;
  // stopi
  wire [63:0]    stopi_rdata;
  wire [11:0]    stopi_regOut_IID;
  // vsiselect
  wire [63:0]    vsiselect_rdata;
  wire [12:0]    vsiselect_regOut_ALL;
  wire           vsiselect_inIMSICRange;
  // vsireg
  wire [63:0]    vsireg_rdata;
  wire [63:0]    vsireg_regOut_ALL;
  // vstopei
  wire [63:0]    vstopei_rdata;
  wire [10:0]    vstopei_regOut_IID;
  wire [10:0]    vstopei_regOut_IPRIO;
  // vstopi
  wire [63:0]    vstopi_rdata;
  wire [11:0]    vstopi_regOut_IID;
  // miprio0
  wire [63:0]    miprio0_rdata;
  // miprio2
  wire [63:0]    miprio2_rdata;
  // siprio0
  wire [63:0]    siprio0_rdata;
  // siprio2
  wire [63:0]    siprio2_rdata;
  // siprios_0
  wire [63:0]    siprios_0_rdata;
  // siprios_1
  wire [63:0]    siprios_1_rdata;
  // siprios_2
  wire [63:0]    siprios_2_rdata;
  // siprios_3
  wire [63:0]    siprios_3_rdata;
  // siprios_4
  wire [63:0]    siprios_4_rdata;
  // siprios_5
  wire [63:0]    siprios_5_rdata;
  // trapEntryDEvent
  wire           trapEntryDEvent_out_privState_valid;
  wire [1:0]     trapEntryDEvent_out_privState_bits_PRVM;
  wire           trapEntryDEvent_out_privState_bits_V;
  wire           trapEntryDEvent_out_dcsr_valid;
  wire [2:0]     trapEntryDEvent_out_dcsr_bits_CAUSE;
  wire           trapEntryDEvent_out_dcsr_bits_V;
  wire [1:0]     trapEntryDEvent_out_dcsr_bits_PRV;
  wire           trapEntryDEvent_out_dpc_valid;
  wire [62:0]    trapEntryDEvent_out_dpc_bits_epc;
  wire           trapEntryDEvent_out_targetPc_valid;
  wire [63:0]    trapEntryDEvent_out_targetPc_bits_pc;
  wire           trapEntryDEvent_out_targetPc_bits_raiseIPF;
  wire           trapEntryDEvent_out_targetPc_bits_raiseIAF;
  wire           trapEntryDEvent_out_targetPc_bits_raiseIGPF;
  wire           trapEntryDEvent_out_debugMode_valid;
  wire           trapEntryDEvent_out_debugMode_bits;
  wire           trapEntryDEvent_out_debugIntrEnable_valid;
  wire           trapEntryDEvent_out_debugIntrEnable_bits;
  // trapEntryMEvent
  wire           trapEntryMEvent_out_privState_valid;
  wire [1:0]     trapEntryMEvent_out_privState_bits_PRVM;
  wire           trapEntryMEvent_out_privState_bits_V;
  wire           trapEntryMEvent_out_mstatus_valid;
  wire           trapEntryMEvent_out_mstatus_bits_MIE;
  wire           trapEntryMEvent_out_mstatus_bits_MPIE;
  wire [1:0]     trapEntryMEvent_out_mstatus_bits_MPP;
  wire           trapEntryMEvent_out_mstatus_bits_GVA;
  wire           trapEntryMEvent_out_mstatus_bits_MPV;
  wire           trapEntryMEvent_out_mstatus_bits_MDT;
  wire           trapEntryMEvent_out_mepc_valid;
  wire [62:0]    trapEntryMEvent_out_mepc_bits_epc;
  wire           trapEntryMEvent_out_mcause_valid;
  wire           trapEntryMEvent_out_mcause_bits_Interrupt;
  wire [62:0]    trapEntryMEvent_out_mcause_bits_ExceptionCode;
  wire           trapEntryMEvent_out_mtval_valid;
  wire [63:0]    trapEntryMEvent_out_mtval_bits_ALL;
  wire           trapEntryMEvent_out_mtval2_valid;
  wire [63:0]    trapEntryMEvent_out_mtval2_bits_ALL;
  wire           trapEntryMEvent_out_mtinst_valid;
  wire [63:0]    trapEntryMEvent_out_mtinst_bits_ALL;
  wire           trapEntryMEvent_out_targetPc_valid;
  wire [63:0]    trapEntryMEvent_out_targetPc_bits_pc;
  wire           trapEntryMEvent_out_targetPc_bits_raiseIPF;
  wire           trapEntryMEvent_out_targetPc_bits_raiseIAF;
  wire           trapEntryMEvent_out_targetPc_bits_raiseIGPF;
  // trapEntryMNEvent
  wire           trapEntryMNEvent_out_privState_valid;
  wire [1:0]     trapEntryMNEvent_out_privState_bits_PRVM;
  wire           trapEntryMNEvent_out_privState_bits_V;
  wire           trapEntryMNEvent_out_mnstatus_valid;
  wire           trapEntryMNEvent_out_mnstatus_bits_NMIE;
  wire           trapEntryMNEvent_out_mnstatus_bits_MNPV;
  wire [1:0]     trapEntryMNEvent_out_mnstatus_bits_MNPP;
  wire           trapEntryMNEvent_out_mnepc_valid;
  wire [62:0]    trapEntryMNEvent_out_mnepc_bits_epc;
  wire           trapEntryMNEvent_out_mncause_valid;
  wire           trapEntryMNEvent_out_mncause_bits_Interrupt;
  wire [62:0]    trapEntryMNEvent_out_mncause_bits_ExceptionCode;
  wire           trapEntryMNEvent_out_targetPc_valid;
  wire [63:0]    trapEntryMNEvent_out_targetPc_bits_pc;
  wire           trapEntryMNEvent_out_targetPc_bits_raiseIPF;
  wire           trapEntryMNEvent_out_targetPc_bits_raiseIAF;
  wire           trapEntryMNEvent_out_targetPc_bits_raiseIGPF;
  // trapEntryHSEvent
  wire           trapEntryHSEvent_out_privState_valid;
  wire [1:0]     trapEntryHSEvent_out_privState_bits_PRVM;
  wire           trapEntryHSEvent_out_privState_bits_V;
  wire           trapEntryHSEvent_out_mstatus_valid;
  wire           trapEntryHSEvent_out_mstatus_bits_SIE;
  wire           trapEntryHSEvent_out_mstatus_bits_SPIE;
  wire           trapEntryHSEvent_out_mstatus_bits_SPP;
  wire           trapEntryHSEvent_out_mstatus_bits_SDT;
  wire           trapEntryHSEvent_out_hstatus_valid;
  wire           trapEntryHSEvent_out_hstatus_bits_GVA;
  wire           trapEntryHSEvent_out_hstatus_bits_SPV;
  wire           trapEntryHSEvent_out_hstatus_bits_SPVP;
  wire           trapEntryHSEvent_out_sepc_valid;
  wire [62:0]    trapEntryHSEvent_out_sepc_bits_epc;
  wire           trapEntryHSEvent_out_scause_valid;
  wire           trapEntryHSEvent_out_scause_bits_Interrupt;
  wire [62:0]    trapEntryHSEvent_out_scause_bits_ExceptionCode;
  wire           trapEntryHSEvent_out_stval_valid;
  wire [63:0]    trapEntryHSEvent_out_stval_bits_ALL;
  wire           trapEntryHSEvent_out_htval_valid;
  wire [63:0]    trapEntryHSEvent_out_htval_bits_ALL;
  wire           trapEntryHSEvent_out_htinst_valid;
  wire [63:0]    trapEntryHSEvent_out_htinst_bits_ALL;
  wire           trapEntryHSEvent_out_targetPc_valid;
  wire [63:0]    trapEntryHSEvent_out_targetPc_bits_pc;
  wire           trapEntryHSEvent_out_targetPc_bits_raiseIPF;
  wire           trapEntryHSEvent_out_targetPc_bits_raiseIAF;
  wire           trapEntryHSEvent_out_targetPc_bits_raiseIGPF;
  // trapEntryVSEvent
  wire           trapEntryVSEvent_out_privState_valid;
  wire [1:0]     trapEntryVSEvent_out_privState_bits_PRVM;
  wire           trapEntryVSEvent_out_privState_bits_V;
  wire           trapEntryVSEvent_out_vsstatus_valid;
  wire           trapEntryVSEvent_out_vsstatus_bits_SIE;
  wire           trapEntryVSEvent_out_vsstatus_bits_SPIE;
  wire           trapEntryVSEvent_out_vsstatus_bits_SPP;
  wire           trapEntryVSEvent_out_vsstatus_bits_SDT;
  wire           trapEntryVSEvent_out_vsepc_valid;
  wire [62:0]    trapEntryVSEvent_out_vsepc_bits_epc;
  wire           trapEntryVSEvent_out_vscause_valid;
  wire           trapEntryVSEvent_out_vscause_bits_Interrupt;
  wire [62:0]    trapEntryVSEvent_out_vscause_bits_ExceptionCode;
  wire           trapEntryVSEvent_out_vstval_valid;
  wire [63:0]    trapEntryVSEvent_out_vstval_bits_ALL;
  wire           trapEntryVSEvent_out_targetPc_valid;
  wire [63:0]    trapEntryVSEvent_out_targetPc_bits_pc;
  wire           trapEntryVSEvent_out_targetPc_bits_raiseIPF;
  wire           trapEntryVSEvent_out_targetPc_bits_raiseIAF;
  wire           trapEntryVSEvent_out_targetPc_bits_raiseIGPF;
  // mretEvent
  wire           mretEvent_out_privState_valid;
  wire [1:0]     mretEvent_out_privState_bits_PRVM;
  wire           mretEvent_out_privState_bits_V;
  wire           mretEvent_out_mstatus_valid;
  wire           mretEvent_out_mstatus_bits_MIE;
  wire           mretEvent_out_mstatus_bits_MPIE;
  wire [1:0]     mretEvent_out_mstatus_bits_MPP;
  wire           mretEvent_out_mstatus_bits_MPRV;
  wire           mretEvent_out_mstatus_bits_SDT;
  wire           mretEvent_out_mstatus_bits_MPV;
  wire           mretEvent_out_mstatus_bits_MDT;
  wire           mretEvent_out_vsstatus_valid;
  wire           mretEvent_out_vsstatus_bits_SDT;
  wire           mretEvent_out_targetPc_valid;
  wire [63:0]    mretEvent_out_targetPc_bits_pc;
  wire           mretEvent_out_targetPc_bits_raiseIPF;
  wire           mretEvent_out_targetPc_bits_raiseIAF;
  wire           mretEvent_out_targetPc_bits_raiseIGPF;
  // mnretEvent
  wire           mnretEvent_out_privState_valid;
  wire [1:0]     mnretEvent_out_privState_bits_PRVM;
  wire           mnretEvent_out_privState_bits_V;
  wire           mnretEvent_out_mnstatus_valid;
  wire           mnretEvent_out_mnstatus_bits_NMIE;
  wire           mnretEvent_out_mstatus_valid;
  wire           mnretEvent_out_mstatus_bits_MPRV;
  wire           mnretEvent_out_mstatus_bits_SDT;
  wire           mnretEvent_out_mstatus_bits_MDT;
  wire           mnretEvent_out_vsstatus_valid;
  wire           mnretEvent_out_vsstatus_bits_SDT;
  wire           mnretEvent_out_targetPc_valid;
  wire [63:0]    mnretEvent_out_targetPc_bits_pc;
  wire           mnretEvent_out_targetPc_bits_raiseIPF;
  wire           mnretEvent_out_targetPc_bits_raiseIAF;
  wire           mnretEvent_out_targetPc_bits_raiseIGPF;
  // sretEvent
  wire           sretEvent_out_privState_valid;
  wire [1:0]     sretEvent_out_privState_bits_PRVM;
  wire           sretEvent_out_privState_bits_V;
  wire           sretEvent_out_mstatus_valid;
  wire           sretEvent_out_mstatus_bits_SIE;
  wire           sretEvent_out_mstatus_bits_SPIE;
  wire           sretEvent_out_mstatus_bits_SPP;
  wire           sretEvent_out_mstatus_bits_MPRV;
  wire           sretEvent_out_mstatus_bits_SDT;
  wire           sretEvent_out_mstatus_bits_MDT;
  wire           sretEvent_out_hstatus_valid;
  wire           sretEvent_out_hstatus_bits_SPV;
  wire           sretEvent_out_vsstatus_valid;
  wire           sretEvent_out_vsstatus_bits_SIE;
  wire           sretEvent_out_vsstatus_bits_SPIE;
  wire           sretEvent_out_vsstatus_bits_SPP;
  wire           sretEvent_out_targetPc_valid;
  wire [63:0]    sretEvent_out_targetPc_bits_pc;
  wire           sretEvent_out_targetPc_bits_raiseIPF;
  wire           sretEvent_out_targetPc_bits_raiseIAF;
  wire           sretEvent_out_targetPc_bits_raiseIGPF;
  wire           sretEvent_outSDT_vsstatus_valid;
  // dretEvent
  wire           dretEvent_out_privState_valid;
  wire [1:0]     dretEvent_out_privState_bits_PRVM;
  wire           dretEvent_out_privState_bits_V;
  wire           dretEvent_out_dcsr_valid;
  wire           dretEvent_out_dcsr_bits_V;
  wire [1:0]     dretEvent_out_dcsr_bits_PRV;
  wire           dretEvent_out_mstatus_valid;
  wire           dretEvent_out_mstatus_bits_MPRV;
  wire           dretEvent_out_mstatus_bits_SDT;
  wire           dretEvent_out_mstatus_bits_MDT;
  wire           dretEvent_out_vsstatus_valid;
  wire           dretEvent_out_vsstatus_bits_SDT;
  wire           dretEvent_out_debugMode_valid;
  wire           dretEvent_out_debugMode_bits;
  wire           dretEvent_out_debugIntrEnable_valid;
  wire           dretEvent_out_debugIntrEnable_bits;
  wire           dretEvent_out_targetPc_valid;
  wire [63:0]    dretEvent_out_targetPc_bits_pc;
  wire           dretEvent_out_targetPc_bits_raiseIPF;
  wire           dretEvent_out_targetPc_bits_raiseIAF;
  wire           dretEvent_out_targetPc_bits_raiseIGPF;
  // tselect
  wire [1:0]     tselect_rdata;
  wire [1:0]     tselect_regOut_ALL;
  // tdata1
  wire [63:0]    tdata1_rdata;
  wire [3:0]     tdata1_regOut_TYPE;
  wire           tdata1_regOut_DMODE;
  wire [58:0]    tdata1_regOut_DATA;
  // tdata2
  wire [63:0]    tdata2_rdata;
  wire [63:0]    tdata2_regOut_ALL;
  // tdata1RegVec_0
  wire [63:0]    tdata1RegVec_0_rdata;
  // tdata1RegVec_1
  wire [63:0]    tdata1RegVec_1_rdata;
  // tdata1RegVec_2
  wire [63:0]    tdata1RegVec_2_rdata;
  // tdata1RegVec_3
  wire [63:0]    tdata1RegVec_3_rdata;
  // tdata2RegVec_0
  wire [63:0]    tdata2RegVec_0_rdata;
  // tdata2RegVec_1
  wire [63:0]    tdata2RegVec_1_rdata;
  // tdata2RegVec_2
  wire [63:0]    tdata2RegVec_2_rdata;
  // tdata2RegVec_3
  wire [63:0]    tdata2RegVec_3_rdata;
  // dcsr
  wire [31:0]    dcsr_rdata;
  wire           dcsr_regOut_CETRIG;
  wire           dcsr_regOut_EBREAKVS;
  wire           dcsr_regOut_EBREAKVU;
  wire           dcsr_regOut_EBREAKM;
  wire           dcsr_regOut_EBREAKS;
  wire           dcsr_regOut_EBREAKU;
  wire           dcsr_regOut_STEPIE;
  wire           dcsr_regOut_STOPCOUNT;
  wire           dcsr_regOut_STOPTIME;
  wire [2:0]     dcsr_regOut_CAUSE;
  wire           dcsr_regOut_V;
  wire           dcsr_regOut_MPRVEN;
  wire           dcsr_regOut_NMIP;
  wire           dcsr_regOut_STEP;
  wire [1:0]     dcsr_regOut_PRV;
  // dpc
  wire [63:0]    dpc_rdata;
  wire [62:0]    dpc_regOut_epc;
  // dscratch0
  wire [63:0]    dscratch0_rdata;
  wire [63:0]    dscratch0_regOut_ALL;
  // dscratch1
  wire [63:0]    dscratch1_rdata;
  wire [63:0]    dscratch1_regOut_ALL;
  // sbpctl
  wire [63:0]    sbpctl_rdata;
  wire           sbpctl_regOut_LOOP_ENABLE;
  wire           sbpctl_regOut_RAS_ENABLE;
  wire           sbpctl_regOut_SC_ENABLE;
  wire           sbpctl_regOut_TAGE_ENABLE;
  wire           sbpctl_regOut_BIM_ENABLE;
  wire           sbpctl_regOut_BTB_ENABLE;
  wire           sbpctl_regOut_UBTB_ENABLE;
  // spfctl
  wire [63:0]    spfctl_rdata;
  wire [9:0]     spfctl_regOut_L2_PF_DELAY_LATENCY;
  wire           spfctl_regOut_L2_PF_TP_ENABLE;
  wire           spfctl_regOut_L2_PF_VBOP_ENABLE;
  wire           spfctl_regOut_L2_PF_PBOP_ENABLE;
  wire           spfctl_regOut_L2_PF_RECV_ENABLE;
  wire           spfctl_regOut_L2_PF_STORE_ONLY;
  wire           spfctl_regOut_L1D_PF_ENABLE_STRIDE;
  wire [5:0]     spfctl_regOut_L1D_PF_ACTIVE_STRIDE;
  wire [3:0]     spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD;
  wire           spfctl_regOut_L1D_PF_ENABLE_PHT;
  wire           spfctl_regOut_L1D_PF_ENABLE_AGT;
  wire           spfctl_regOut_L1D_PF_TRAIN_ON_HIT;
  wire           spfctl_regOut_L1D_PF_ENABLE;
  wire           spfctl_regOut_L2_PF_ENABLE;
  wire           spfctl_regOut_L1I_PF_ENABLE;
  // slvpredctl
  wire [63:0]    slvpredctl_rdata;
  wire [4:0]     slvpredctl_regOut_LVPRED_TIMEOUT;
  wire           slvpredctl_regOut_STORESET_NO_FAST_WAKEUP;
  wire           slvpredctl_regOut_STORESET_WAIT_STORE;
  wire           slvpredctl_regOut_NO_SPEC_LOAD;
  wire           slvpredctl_regOut_LVPRED_DISABLE;
  // smblockctl
  wire [63:0]    smblockctl_rdata;
  wire [21:0]    smblockctl_regOut_SBUFFER_TIMEOUT;
  wire           smblockctl_regOut_HD_MISALIGN_LD_ENABLE;
  wire           smblockctl_regOut_HD_MISALIGN_ST_ENABLE;
  wire           smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  wire           smblockctl_regOut_CACHE_ERROR_ENABLE;
  wire           smblockctl_regOut_SOFT_PREFETCH_ENABLE;
  wire           smblockctl_regOut_LDLD_VIO_CHECK_ENABLE;
  wire [3:0]     smblockctl_regOut_SBUFFER_THRESHOLD;
  // srnctl
  wire [63:0]    srnctl_rdata;
  wire           srnctl_regOut_WFI_ENABLE;
  wire           srnctl_regOut_FUSION_ENABLE;
  // mcorepwr
  wire [63:0]    mcorepwr_rdata;
  wire           mcorepwr_regOut_COMMIT_STUCK_CHECK_ENABLE;
  wire           mcorepwr_regOut_POWER_DOWN_ENABLE;
  // mflushpwr
  wire [63:0]    mflushpwr_rdata;
  wire           mflushpwr_regOut_FLUSH_L2_ENABLE;
  wire           mflushpwr_regOut_L2_FLUSH_DONE;
  // pmpcfg_0
  wire [63:0]    pmpcfg_0_rdata;
  wire [63:0]    pmpcfg_0_regOut_ALL;
  // pmpcfg_1
  wire [63:0]    pmpcfg_1_rdata;
  wire [63:0]    pmpcfg_1_regOut_ALL;
  // pmpcfg_2
  wire [63:0]    pmpcfg_2_rdata;
  wire [63:0]    pmpcfg_2_regOut_ALL;
  // pmpcfg_3
  wire [63:0]    pmpcfg_3_rdata;
  wire [63:0]    pmpcfg_3_regOut_ALL;
  // pmpcfg_4
  wire [63:0]    pmpcfg_4_rdata;
  wire [63:0]    pmpcfg_4_regOut_ALL;
  // pmpcfg_5
  wire [63:0]    pmpcfg_5_rdata;
  wire [63:0]    pmpcfg_5_regOut_ALL;
  // pmpcfg_6
  wire [63:0]    pmpcfg_6_rdata;
  wire [63:0]    pmpcfg_6_regOut_ALL;
  // pmpcfg_7
  wire [63:0]    pmpcfg_7_rdata;
  wire [63:0]    pmpcfg_7_regOut_ALL;
  // pmpcfgs_0
  wire [7:0]     pmpcfgs_0_rdata;
  wire           pmpcfgs_0_regOut_R;
  wire           pmpcfgs_0_regOut_W;
  wire           pmpcfgs_0_regOut_X;
  wire [1:0]     pmpcfgs_0_regOut_A;
  wire           pmpcfgs_0_regOut_L;
  // pmpcfgs_1
  wire [7:0]     pmpcfgs_1_rdata;
  wire           pmpcfgs_1_regOut_R;
  wire           pmpcfgs_1_regOut_W;
  wire           pmpcfgs_1_regOut_X;
  wire [1:0]     pmpcfgs_1_regOut_A;
  wire           pmpcfgs_1_regOut_L;
  // pmpcfgs_2
  wire [7:0]     pmpcfgs_2_rdata;
  wire           pmpcfgs_2_regOut_R;
  wire           pmpcfgs_2_regOut_W;
  wire           pmpcfgs_2_regOut_X;
  wire [1:0]     pmpcfgs_2_regOut_A;
  wire           pmpcfgs_2_regOut_L;
  // pmpcfgs_3
  wire [7:0]     pmpcfgs_3_rdata;
  wire           pmpcfgs_3_regOut_R;
  wire           pmpcfgs_3_regOut_W;
  wire           pmpcfgs_3_regOut_X;
  wire [1:0]     pmpcfgs_3_regOut_A;
  wire           pmpcfgs_3_regOut_L;
  // pmpcfgs_4
  wire [7:0]     pmpcfgs_4_rdata;
  wire           pmpcfgs_4_regOut_R;
  wire           pmpcfgs_4_regOut_W;
  wire           pmpcfgs_4_regOut_X;
  wire [1:0]     pmpcfgs_4_regOut_A;
  wire           pmpcfgs_4_regOut_L;
  // pmpcfgs_5
  wire [7:0]     pmpcfgs_5_rdata;
  wire           pmpcfgs_5_regOut_R;
  wire           pmpcfgs_5_regOut_W;
  wire           pmpcfgs_5_regOut_X;
  wire [1:0]     pmpcfgs_5_regOut_A;
  wire           pmpcfgs_5_regOut_L;
  // pmpcfgs_6
  wire [7:0]     pmpcfgs_6_rdata;
  wire           pmpcfgs_6_regOut_R;
  wire           pmpcfgs_6_regOut_W;
  wire           pmpcfgs_6_regOut_X;
  wire [1:0]     pmpcfgs_6_regOut_A;
  wire           pmpcfgs_6_regOut_L;
  // pmpcfgs_7
  wire [7:0]     pmpcfgs_7_rdata;
  wire           pmpcfgs_7_regOut_R;
  wire           pmpcfgs_7_regOut_W;
  wire           pmpcfgs_7_regOut_X;
  wire [1:0]     pmpcfgs_7_regOut_A;
  wire           pmpcfgs_7_regOut_L;
  // pmpcfgs_8
  wire [7:0]     pmpcfgs_8_rdata;
  wire           pmpcfgs_8_regOut_R;
  wire           pmpcfgs_8_regOut_W;
  wire           pmpcfgs_8_regOut_X;
  wire [1:0]     pmpcfgs_8_regOut_A;
  wire           pmpcfgs_8_regOut_L;
  // pmpcfgs_9
  wire [7:0]     pmpcfgs_9_rdata;
  wire           pmpcfgs_9_regOut_R;
  wire           pmpcfgs_9_regOut_W;
  wire           pmpcfgs_9_regOut_X;
  wire [1:0]     pmpcfgs_9_regOut_A;
  wire           pmpcfgs_9_regOut_L;
  // pmpcfgs_10
  wire [7:0]     pmpcfgs_10_rdata;
  wire           pmpcfgs_10_regOut_R;
  wire           pmpcfgs_10_regOut_W;
  wire           pmpcfgs_10_regOut_X;
  wire [1:0]     pmpcfgs_10_regOut_A;
  wire           pmpcfgs_10_regOut_L;
  // pmpcfgs_11
  wire [7:0]     pmpcfgs_11_rdata;
  wire           pmpcfgs_11_regOut_R;
  wire           pmpcfgs_11_regOut_W;
  wire           pmpcfgs_11_regOut_X;
  wire [1:0]     pmpcfgs_11_regOut_A;
  wire           pmpcfgs_11_regOut_L;
  // pmpcfgs_12
  wire [7:0]     pmpcfgs_12_rdata;
  wire           pmpcfgs_12_regOut_R;
  wire           pmpcfgs_12_regOut_W;
  wire           pmpcfgs_12_regOut_X;
  wire [1:0]     pmpcfgs_12_regOut_A;
  wire           pmpcfgs_12_regOut_L;
  // pmpcfgs_13
  wire [7:0]     pmpcfgs_13_rdata;
  wire           pmpcfgs_13_regOut_R;
  wire           pmpcfgs_13_regOut_W;
  wire           pmpcfgs_13_regOut_X;
  wire [1:0]     pmpcfgs_13_regOut_A;
  wire           pmpcfgs_13_regOut_L;
  // pmpcfgs_14
  wire [7:0]     pmpcfgs_14_rdata;
  wire           pmpcfgs_14_regOut_R;
  wire           pmpcfgs_14_regOut_W;
  wire           pmpcfgs_14_regOut_X;
  wire [1:0]     pmpcfgs_14_regOut_A;
  wire           pmpcfgs_14_regOut_L;
  // pmpcfgs_15
  wire [7:0]     pmpcfgs_15_rdata;
  wire           pmpcfgs_15_regOut_R;
  wire           pmpcfgs_15_regOut_W;
  wire           pmpcfgs_15_regOut_X;
  wire [1:0]     pmpcfgs_15_regOut_A;
  wire           pmpcfgs_15_regOut_L;
  // pmpcfgs_16
  wire [7:0]     pmpcfgs_16_rdata;
  wire           pmpcfgs_16_regOut_R;
  wire           pmpcfgs_16_regOut_W;
  wire           pmpcfgs_16_regOut_X;
  wire [1:0]     pmpcfgs_16_regOut_A;
  wire           pmpcfgs_16_regOut_L;
  // pmpcfgs_17
  wire [7:0]     pmpcfgs_17_rdata;
  wire           pmpcfgs_17_regOut_R;
  wire           pmpcfgs_17_regOut_W;
  wire           pmpcfgs_17_regOut_X;
  wire [1:0]     pmpcfgs_17_regOut_A;
  wire           pmpcfgs_17_regOut_L;
  // pmpcfgs_18
  wire [7:0]     pmpcfgs_18_rdata;
  wire           pmpcfgs_18_regOut_R;
  wire           pmpcfgs_18_regOut_W;
  wire           pmpcfgs_18_regOut_X;
  wire [1:0]     pmpcfgs_18_regOut_A;
  wire           pmpcfgs_18_regOut_L;
  // pmpcfgs_19
  wire [7:0]     pmpcfgs_19_rdata;
  wire           pmpcfgs_19_regOut_R;
  wire           pmpcfgs_19_regOut_W;
  wire           pmpcfgs_19_regOut_X;
  wire [1:0]     pmpcfgs_19_regOut_A;
  wire           pmpcfgs_19_regOut_L;
  // pmpcfgs_20
  wire [7:0]     pmpcfgs_20_rdata;
  wire           pmpcfgs_20_regOut_R;
  wire           pmpcfgs_20_regOut_W;
  wire           pmpcfgs_20_regOut_X;
  wire [1:0]     pmpcfgs_20_regOut_A;
  wire           pmpcfgs_20_regOut_L;
  // pmpcfgs_21
  wire [7:0]     pmpcfgs_21_rdata;
  wire           pmpcfgs_21_regOut_R;
  wire           pmpcfgs_21_regOut_W;
  wire           pmpcfgs_21_regOut_X;
  wire [1:0]     pmpcfgs_21_regOut_A;
  wire           pmpcfgs_21_regOut_L;
  // pmpcfgs_22
  wire [7:0]     pmpcfgs_22_rdata;
  wire           pmpcfgs_22_regOut_R;
  wire           pmpcfgs_22_regOut_W;
  wire           pmpcfgs_22_regOut_X;
  wire [1:0]     pmpcfgs_22_regOut_A;
  wire           pmpcfgs_22_regOut_L;
  // pmpcfgs_23
  wire [7:0]     pmpcfgs_23_rdata;
  wire           pmpcfgs_23_regOut_R;
  wire           pmpcfgs_23_regOut_W;
  wire           pmpcfgs_23_regOut_X;
  wire [1:0]     pmpcfgs_23_regOut_A;
  wire           pmpcfgs_23_regOut_L;
  // pmpcfgs_24
  wire [7:0]     pmpcfgs_24_rdata;
  wire           pmpcfgs_24_regOut_R;
  wire           pmpcfgs_24_regOut_W;
  wire           pmpcfgs_24_regOut_X;
  wire [1:0]     pmpcfgs_24_regOut_A;
  wire           pmpcfgs_24_regOut_L;
  // pmpcfgs_25
  wire [7:0]     pmpcfgs_25_rdata;
  wire           pmpcfgs_25_regOut_R;
  wire           pmpcfgs_25_regOut_W;
  wire           pmpcfgs_25_regOut_X;
  wire [1:0]     pmpcfgs_25_regOut_A;
  wire           pmpcfgs_25_regOut_L;
  // pmpcfgs_26
  wire [7:0]     pmpcfgs_26_rdata;
  wire           pmpcfgs_26_regOut_R;
  wire           pmpcfgs_26_regOut_W;
  wire           pmpcfgs_26_regOut_X;
  wire [1:0]     pmpcfgs_26_regOut_A;
  wire           pmpcfgs_26_regOut_L;
  // pmpcfgs_27
  wire [7:0]     pmpcfgs_27_rdata;
  wire           pmpcfgs_27_regOut_R;
  wire           pmpcfgs_27_regOut_W;
  wire           pmpcfgs_27_regOut_X;
  wire [1:0]     pmpcfgs_27_regOut_A;
  wire           pmpcfgs_27_regOut_L;
  // pmpcfgs_28
  wire [7:0]     pmpcfgs_28_rdata;
  wire           pmpcfgs_28_regOut_R;
  wire           pmpcfgs_28_regOut_W;
  wire           pmpcfgs_28_regOut_X;
  wire [1:0]     pmpcfgs_28_regOut_A;
  wire           pmpcfgs_28_regOut_L;
  // pmpcfgs_29
  wire [7:0]     pmpcfgs_29_rdata;
  wire           pmpcfgs_29_regOut_R;
  wire           pmpcfgs_29_regOut_W;
  wire           pmpcfgs_29_regOut_X;
  wire [1:0]     pmpcfgs_29_regOut_A;
  wire           pmpcfgs_29_regOut_L;
  // pmpcfgs_30
  wire [7:0]     pmpcfgs_30_rdata;
  wire           pmpcfgs_30_regOut_R;
  wire           pmpcfgs_30_regOut_W;
  wire           pmpcfgs_30_regOut_X;
  wire [1:0]     pmpcfgs_30_regOut_A;
  wire           pmpcfgs_30_regOut_L;
  // pmpcfgs_31
  wire [7:0]     pmpcfgs_31_rdata;
  wire           pmpcfgs_31_regOut_R;
  wire           pmpcfgs_31_regOut_W;
  wire           pmpcfgs_31_regOut_X;
  wire [1:0]     pmpcfgs_31_regOut_A;
  wire           pmpcfgs_31_regOut_L;
  // pmpaddr_0
  wire [63:0]    pmpaddr_0_rdata;
  wire [45:0]    pmpaddr_0_regOut_ADDRESS;
  // pmpaddr_1
  wire [63:0]    pmpaddr_1_rdata;
  wire [45:0]    pmpaddr_1_regOut_ADDRESS;
  // pmpaddr_2
  wire [63:0]    pmpaddr_2_rdata;
  wire [45:0]    pmpaddr_2_regOut_ADDRESS;
  // pmpaddr_3
  wire [63:0]    pmpaddr_3_rdata;
  wire [45:0]    pmpaddr_3_regOut_ADDRESS;
  // pmpaddr_4
  wire [63:0]    pmpaddr_4_rdata;
  wire [45:0]    pmpaddr_4_regOut_ADDRESS;
  // pmpaddr_5
  wire [63:0]    pmpaddr_5_rdata;
  wire [45:0]    pmpaddr_5_regOut_ADDRESS;
  // pmpaddr_6
  wire [63:0]    pmpaddr_6_rdata;
  wire [45:0]    pmpaddr_6_regOut_ADDRESS;
  // pmpaddr_7
  wire [63:0]    pmpaddr_7_rdata;
  wire [45:0]    pmpaddr_7_regOut_ADDRESS;
  // pmpaddr_8
  wire [63:0]    pmpaddr_8_rdata;
  wire [45:0]    pmpaddr_8_regOut_ADDRESS;
  // pmpaddr_9
  wire [63:0]    pmpaddr_9_rdata;
  wire [45:0]    pmpaddr_9_regOut_ADDRESS;
  // pmpaddr_10
  wire [63:0]    pmpaddr_10_rdata;
  wire [45:0]    pmpaddr_10_regOut_ADDRESS;
  // pmpaddr_11
  wire [63:0]    pmpaddr_11_rdata;
  wire [45:0]    pmpaddr_11_regOut_ADDRESS;
  // pmpaddr_12
  wire [63:0]    pmpaddr_12_rdata;
  wire [45:0]    pmpaddr_12_regOut_ADDRESS;
  // pmpaddr_13
  wire [63:0]    pmpaddr_13_rdata;
  wire [45:0]    pmpaddr_13_regOut_ADDRESS;
  // pmpaddr_14
  wire [63:0]    pmpaddr_14_rdata;
  wire [45:0]    pmpaddr_14_regOut_ADDRESS;
  // pmpaddr_15
  wire [63:0]    pmpaddr_15_rdata;
  wire [45:0]    pmpaddr_15_regOut_ADDRESS;
  // pmpaddr_16
  wire [63:0]    pmpaddr_16_rdata;
  wire [45:0]    pmpaddr_16_regOut_ADDRESS;
  // pmpaddr_17
  wire [63:0]    pmpaddr_17_rdata;
  wire [45:0]    pmpaddr_17_regOut_ADDRESS;
  // pmpaddr_18
  wire [63:0]    pmpaddr_18_rdata;
  wire [45:0]    pmpaddr_18_regOut_ADDRESS;
  // pmpaddr_19
  wire [63:0]    pmpaddr_19_rdata;
  wire [45:0]    pmpaddr_19_regOut_ADDRESS;
  // pmpaddr_20
  wire [63:0]    pmpaddr_20_rdata;
  wire [45:0]    pmpaddr_20_regOut_ADDRESS;
  // pmpaddr_21
  wire [63:0]    pmpaddr_21_rdata;
  wire [45:0]    pmpaddr_21_regOut_ADDRESS;
  // pmpaddr_22
  wire [63:0]    pmpaddr_22_rdata;
  wire [45:0]    pmpaddr_22_regOut_ADDRESS;
  // pmpaddr_23
  wire [63:0]    pmpaddr_23_rdata;
  wire [45:0]    pmpaddr_23_regOut_ADDRESS;
  // pmpaddr_24
  wire [63:0]    pmpaddr_24_rdata;
  wire [45:0]    pmpaddr_24_regOut_ADDRESS;
  // pmpaddr_25
  wire [63:0]    pmpaddr_25_rdata;
  wire [45:0]    pmpaddr_25_regOut_ADDRESS;
  // pmpaddr_26
  wire [63:0]    pmpaddr_26_rdata;
  wire [45:0]    pmpaddr_26_regOut_ADDRESS;
  // pmpaddr_27
  wire [63:0]    pmpaddr_27_rdata;
  wire [45:0]    pmpaddr_27_regOut_ADDRESS;
  // pmpaddr_28
  wire [63:0]    pmpaddr_28_rdata;
  wire [45:0]    pmpaddr_28_regOut_ADDRESS;
  // pmpaddr_29
  wire [63:0]    pmpaddr_29_rdata;
  wire [45:0]    pmpaddr_29_regOut_ADDRESS;
  // pmpaddr_30
  wire [63:0]    pmpaddr_30_rdata;
  wire [45:0]    pmpaddr_30_regOut_ADDRESS;
  // pmpaddr_31
  wire [63:0]    pmpaddr_31_rdata;
  wire [45:0]    pmpaddr_31_regOut_ADDRESS;
  // pmpaddr_32
  wire [63:0]    pmpaddr_32_rdata;
  wire [63:0]    pmpaddr_32_regOut_ALL;
  // pmpaddr_33
  wire [63:0]    pmpaddr_33_rdata;
  wire [63:0]    pmpaddr_33_regOut_ALL;
  // pmpaddr_34
  wire [63:0]    pmpaddr_34_rdata;
  wire [63:0]    pmpaddr_34_regOut_ALL;
  // pmpaddr_35
  wire [63:0]    pmpaddr_35_rdata;
  wire [63:0]    pmpaddr_35_regOut_ALL;
  // pmpaddr_36
  wire [63:0]    pmpaddr_36_rdata;
  wire [63:0]    pmpaddr_36_regOut_ALL;
  // pmpaddr_37
  wire [63:0]    pmpaddr_37_rdata;
  wire [63:0]    pmpaddr_37_regOut_ALL;
  // pmpaddr_38
  wire [63:0]    pmpaddr_38_rdata;
  wire [63:0]    pmpaddr_38_regOut_ALL;
  // pmpaddr_39
  wire [63:0]    pmpaddr_39_rdata;
  wire [63:0]    pmpaddr_39_regOut_ALL;
  // pmpaddr_40
  wire [63:0]    pmpaddr_40_rdata;
  wire [63:0]    pmpaddr_40_regOut_ALL;
  // pmpaddr_41
  wire [63:0]    pmpaddr_41_rdata;
  wire [63:0]    pmpaddr_41_regOut_ALL;
  // pmpaddr_42
  wire [63:0]    pmpaddr_42_rdata;
  wire [63:0]    pmpaddr_42_regOut_ALL;
  // pmpaddr_43
  wire [63:0]    pmpaddr_43_rdata;
  wire [63:0]    pmpaddr_43_regOut_ALL;
  // pmpaddr_44
  wire [63:0]    pmpaddr_44_rdata;
  wire [63:0]    pmpaddr_44_regOut_ALL;
  // pmpaddr_45
  wire [63:0]    pmpaddr_45_rdata;
  wire [63:0]    pmpaddr_45_regOut_ALL;
  // pmpaddr_46
  wire [63:0]    pmpaddr_46_rdata;
  wire [63:0]    pmpaddr_46_regOut_ALL;
  // pmpaddr_47
  wire [63:0]    pmpaddr_47_rdata;
  wire [63:0]    pmpaddr_47_regOut_ALL;
  // pmpaddr_48
  wire [63:0]    pmpaddr_48_rdata;
  wire [63:0]    pmpaddr_48_regOut_ALL;
  // pmpaddr_49
  wire [63:0]    pmpaddr_49_rdata;
  wire [63:0]    pmpaddr_49_regOut_ALL;
  // pmpaddr_50
  wire [63:0]    pmpaddr_50_rdata;
  wire [63:0]    pmpaddr_50_regOut_ALL;
  // pmpaddr_51
  wire [63:0]    pmpaddr_51_rdata;
  wire [63:0]    pmpaddr_51_regOut_ALL;
  // pmpaddr_52
  wire [63:0]    pmpaddr_52_rdata;
  wire [63:0]    pmpaddr_52_regOut_ALL;
  // pmpaddr_53
  wire [63:0]    pmpaddr_53_rdata;
  wire [63:0]    pmpaddr_53_regOut_ALL;
  // pmpaddr_54
  wire [63:0]    pmpaddr_54_rdata;
  wire [63:0]    pmpaddr_54_regOut_ALL;
  // pmpaddr_55
  wire [63:0]    pmpaddr_55_rdata;
  wire [63:0]    pmpaddr_55_regOut_ALL;
  // pmpaddr_56
  wire [63:0]    pmpaddr_56_rdata;
  wire [63:0]    pmpaddr_56_regOut_ALL;
  // pmpaddr_57
  wire [63:0]    pmpaddr_57_rdata;
  wire [63:0]    pmpaddr_57_regOut_ALL;
  // pmpaddr_58
  wire [63:0]    pmpaddr_58_rdata;
  wire [63:0]    pmpaddr_58_regOut_ALL;
  // pmpaddr_59
  wire [63:0]    pmpaddr_59_rdata;
  wire [63:0]    pmpaddr_59_regOut_ALL;
  // pmpaddr_60
  wire [63:0]    pmpaddr_60_rdata;
  wire [63:0]    pmpaddr_60_regOut_ALL;
  // pmpaddr_61
  wire [63:0]    pmpaddr_61_rdata;
  wire [63:0]    pmpaddr_61_regOut_ALL;
  // pmpaddr_62
  wire [63:0]    pmpaddr_62_rdata;
  wire [63:0]    pmpaddr_62_regOut_ALL;
  // pmpaddr_63
  wire [63:0]    pmpaddr_63_rdata;
  wire [63:0]    pmpaddr_63_regOut_ALL;
  // pmacfg_0
  wire [63:0]    pmacfg_0_rdata;
  wire [63:0]    pmacfg_0_regOut_ALL;
  // pmacfg_1
  wire [63:0]    pmacfg_1_rdata;
  wire [63:0]    pmacfg_1_regOut_ALL;
  // pmacfg_2
  wire [63:0]    pmacfg_2_rdata;
  wire [63:0]    pmacfg_2_regOut_ALL;
  // pmacfg_3
  wire [63:0]    pmacfg_3_rdata;
  wire [63:0]    pmacfg_3_regOut_ALL;
  // pmacfgs_0
  wire [7:0]     pmacfgs_0_rdata;
  wire           pmacfgs_0_regOut_R;
  wire           pmacfgs_0_regOut_W;
  wire           pmacfgs_0_regOut_X;
  wire [1:0]     pmacfgs_0_regOut_A;
  wire           pmacfgs_0_regOut_ATOMIC;
  wire           pmacfgs_0_regOut_C;
  wire           pmacfgs_0_regOut_L;
  // pmacfgs_1
  wire [7:0]     pmacfgs_1_rdata;
  wire           pmacfgs_1_regOut_R;
  wire           pmacfgs_1_regOut_W;
  wire           pmacfgs_1_regOut_X;
  wire [1:0]     pmacfgs_1_regOut_A;
  wire           pmacfgs_1_regOut_ATOMIC;
  wire           pmacfgs_1_regOut_C;
  wire           pmacfgs_1_regOut_L;
  // pmacfgs_2
  wire [7:0]     pmacfgs_2_rdata;
  wire           pmacfgs_2_regOut_R;
  wire           pmacfgs_2_regOut_W;
  wire           pmacfgs_2_regOut_X;
  wire [1:0]     pmacfgs_2_regOut_A;
  wire           pmacfgs_2_regOut_ATOMIC;
  wire           pmacfgs_2_regOut_C;
  wire           pmacfgs_2_regOut_L;
  // pmacfgs_3
  wire [7:0]     pmacfgs_3_rdata;
  wire           pmacfgs_3_regOut_R;
  wire           pmacfgs_3_regOut_W;
  wire           pmacfgs_3_regOut_X;
  wire [1:0]     pmacfgs_3_regOut_A;
  wire           pmacfgs_3_regOut_ATOMIC;
  wire           pmacfgs_3_regOut_C;
  wire           pmacfgs_3_regOut_L;
  // pmacfgs_4
  wire [7:0]     pmacfgs_4_rdata;
  wire           pmacfgs_4_regOut_R;
  wire           pmacfgs_4_regOut_W;
  wire           pmacfgs_4_regOut_X;
  wire [1:0]     pmacfgs_4_regOut_A;
  wire           pmacfgs_4_regOut_ATOMIC;
  wire           pmacfgs_4_regOut_C;
  wire           pmacfgs_4_regOut_L;
  // pmacfgs_5
  wire [7:0]     pmacfgs_5_rdata;
  wire           pmacfgs_5_regOut_R;
  wire           pmacfgs_5_regOut_W;
  wire           pmacfgs_5_regOut_X;
  wire [1:0]     pmacfgs_5_regOut_A;
  wire           pmacfgs_5_regOut_ATOMIC;
  wire           pmacfgs_5_regOut_C;
  wire           pmacfgs_5_regOut_L;
  // pmacfgs_6
  wire [7:0]     pmacfgs_6_rdata;
  wire           pmacfgs_6_regOut_R;
  wire           pmacfgs_6_regOut_W;
  wire           pmacfgs_6_regOut_X;
  wire [1:0]     pmacfgs_6_regOut_A;
  wire           pmacfgs_6_regOut_ATOMIC;
  wire           pmacfgs_6_regOut_C;
  wire           pmacfgs_6_regOut_L;
  // pmacfgs_7
  wire [7:0]     pmacfgs_7_rdata;
  wire           pmacfgs_7_regOut_R;
  wire           pmacfgs_7_regOut_W;
  wire           pmacfgs_7_regOut_X;
  wire [1:0]     pmacfgs_7_regOut_A;
  wire           pmacfgs_7_regOut_ATOMIC;
  wire           pmacfgs_7_regOut_C;
  wire           pmacfgs_7_regOut_L;
  // pmacfgs_8
  wire [7:0]     pmacfgs_8_rdata;
  wire           pmacfgs_8_regOut_R;
  wire           pmacfgs_8_regOut_W;
  wire           pmacfgs_8_regOut_X;
  wire [1:0]     pmacfgs_8_regOut_A;
  wire           pmacfgs_8_regOut_ATOMIC;
  wire           pmacfgs_8_regOut_C;
  wire           pmacfgs_8_regOut_L;
  // pmacfgs_9
  wire [7:0]     pmacfgs_9_rdata;
  wire           pmacfgs_9_regOut_R;
  wire           pmacfgs_9_regOut_W;
  wire           pmacfgs_9_regOut_X;
  wire [1:0]     pmacfgs_9_regOut_A;
  wire           pmacfgs_9_regOut_ATOMIC;
  wire           pmacfgs_9_regOut_C;
  wire           pmacfgs_9_regOut_L;
  // pmacfgs_10
  wire [7:0]     pmacfgs_10_rdata;
  wire           pmacfgs_10_regOut_R;
  wire           pmacfgs_10_regOut_W;
  wire           pmacfgs_10_regOut_X;
  wire [1:0]     pmacfgs_10_regOut_A;
  wire           pmacfgs_10_regOut_ATOMIC;
  wire           pmacfgs_10_regOut_C;
  wire           pmacfgs_10_regOut_L;
  // pmacfgs_11
  wire [7:0]     pmacfgs_11_rdata;
  wire           pmacfgs_11_regOut_R;
  wire           pmacfgs_11_regOut_W;
  wire           pmacfgs_11_regOut_X;
  wire [1:0]     pmacfgs_11_regOut_A;
  wire           pmacfgs_11_regOut_ATOMIC;
  wire           pmacfgs_11_regOut_C;
  wire           pmacfgs_11_regOut_L;
  // pmacfgs_12
  wire [7:0]     pmacfgs_12_rdata;
  wire           pmacfgs_12_regOut_R;
  wire           pmacfgs_12_regOut_W;
  wire           pmacfgs_12_regOut_X;
  wire [1:0]     pmacfgs_12_regOut_A;
  wire           pmacfgs_12_regOut_ATOMIC;
  wire           pmacfgs_12_regOut_C;
  wire           pmacfgs_12_regOut_L;
  // pmacfgs_13
  wire [7:0]     pmacfgs_13_rdata;
  wire           pmacfgs_13_regOut_R;
  wire           pmacfgs_13_regOut_W;
  wire           pmacfgs_13_regOut_X;
  wire [1:0]     pmacfgs_13_regOut_A;
  wire           pmacfgs_13_regOut_ATOMIC;
  wire           pmacfgs_13_regOut_C;
  wire           pmacfgs_13_regOut_L;
  // pmacfgs_14
  wire [7:0]     pmacfgs_14_rdata;
  wire           pmacfgs_14_regOut_R;
  wire           pmacfgs_14_regOut_W;
  wire           pmacfgs_14_regOut_X;
  wire [1:0]     pmacfgs_14_regOut_A;
  wire           pmacfgs_14_regOut_ATOMIC;
  wire           pmacfgs_14_regOut_C;
  wire           pmacfgs_14_regOut_L;
  // pmacfgs_15
  wire [7:0]     pmacfgs_15_rdata;
  wire           pmacfgs_15_regOut_R;
  wire           pmacfgs_15_regOut_W;
  wire           pmacfgs_15_regOut_X;
  wire [1:0]     pmacfgs_15_regOut_A;
  wire           pmacfgs_15_regOut_ATOMIC;
  wire           pmacfgs_15_regOut_C;
  wire           pmacfgs_15_regOut_L;
  // pmacfgs_16
  wire [7:0]     pmacfgs_16_rdata;
  wire           pmacfgs_16_regOut_R;
  wire           pmacfgs_16_regOut_W;
  wire           pmacfgs_16_regOut_X;
  wire [1:0]     pmacfgs_16_regOut_A;
  wire           pmacfgs_16_regOut_ATOMIC;
  wire           pmacfgs_16_regOut_C;
  wire           pmacfgs_16_regOut_L;
  // pmacfgs_17
  wire [7:0]     pmacfgs_17_rdata;
  wire           pmacfgs_17_regOut_R;
  wire           pmacfgs_17_regOut_W;
  wire           pmacfgs_17_regOut_X;
  wire [1:0]     pmacfgs_17_regOut_A;
  wire           pmacfgs_17_regOut_ATOMIC;
  wire           pmacfgs_17_regOut_C;
  wire           pmacfgs_17_regOut_L;
  // pmacfgs_18
  wire [7:0]     pmacfgs_18_rdata;
  wire           pmacfgs_18_regOut_R;
  wire           pmacfgs_18_regOut_W;
  wire           pmacfgs_18_regOut_X;
  wire [1:0]     pmacfgs_18_regOut_A;
  wire           pmacfgs_18_regOut_ATOMIC;
  wire           pmacfgs_18_regOut_C;
  wire           pmacfgs_18_regOut_L;
  // pmacfgs_19
  wire [7:0]     pmacfgs_19_rdata;
  wire           pmacfgs_19_regOut_R;
  wire           pmacfgs_19_regOut_W;
  wire           pmacfgs_19_regOut_X;
  wire [1:0]     pmacfgs_19_regOut_A;
  wire           pmacfgs_19_regOut_ATOMIC;
  wire           pmacfgs_19_regOut_C;
  wire           pmacfgs_19_regOut_L;
  // pmacfgs_20
  wire [7:0]     pmacfgs_20_rdata;
  wire           pmacfgs_20_regOut_R;
  wire           pmacfgs_20_regOut_W;
  wire           pmacfgs_20_regOut_X;
  wire [1:0]     pmacfgs_20_regOut_A;
  wire           pmacfgs_20_regOut_ATOMIC;
  wire           pmacfgs_20_regOut_C;
  wire           pmacfgs_20_regOut_L;
  // pmacfgs_21
  wire [7:0]     pmacfgs_21_rdata;
  wire           pmacfgs_21_regOut_R;
  wire           pmacfgs_21_regOut_W;
  wire           pmacfgs_21_regOut_X;
  wire [1:0]     pmacfgs_21_regOut_A;
  wire           pmacfgs_21_regOut_ATOMIC;
  wire           pmacfgs_21_regOut_C;
  wire           pmacfgs_21_regOut_L;
  // pmacfgs_22
  wire [7:0]     pmacfgs_22_rdata;
  wire           pmacfgs_22_regOut_R;
  wire           pmacfgs_22_regOut_W;
  wire           pmacfgs_22_regOut_X;
  wire [1:0]     pmacfgs_22_regOut_A;
  wire           pmacfgs_22_regOut_ATOMIC;
  wire           pmacfgs_22_regOut_C;
  wire           pmacfgs_22_regOut_L;
  // pmacfgs_23
  wire [7:0]     pmacfgs_23_rdata;
  wire           pmacfgs_23_regOut_R;
  wire           pmacfgs_23_regOut_W;
  wire           pmacfgs_23_regOut_X;
  wire [1:0]     pmacfgs_23_regOut_A;
  wire           pmacfgs_23_regOut_ATOMIC;
  wire           pmacfgs_23_regOut_C;
  wire           pmacfgs_23_regOut_L;
  // pmacfgs_24
  wire [7:0]     pmacfgs_24_rdata;
  wire           pmacfgs_24_regOut_R;
  wire           pmacfgs_24_regOut_W;
  wire           pmacfgs_24_regOut_X;
  wire [1:0]     pmacfgs_24_regOut_A;
  wire           pmacfgs_24_regOut_ATOMIC;
  wire           pmacfgs_24_regOut_C;
  wire           pmacfgs_24_regOut_L;
  // pmacfgs_25
  wire [7:0]     pmacfgs_25_rdata;
  wire           pmacfgs_25_regOut_R;
  wire           pmacfgs_25_regOut_W;
  wire           pmacfgs_25_regOut_X;
  wire [1:0]     pmacfgs_25_regOut_A;
  wire           pmacfgs_25_regOut_ATOMIC;
  wire           pmacfgs_25_regOut_C;
  wire           pmacfgs_25_regOut_L;
  // pmacfgs_26
  wire [7:0]     pmacfgs_26_rdata;
  wire           pmacfgs_26_regOut_R;
  wire           pmacfgs_26_regOut_W;
  wire           pmacfgs_26_regOut_X;
  wire [1:0]     pmacfgs_26_regOut_A;
  wire           pmacfgs_26_regOut_ATOMIC;
  wire           pmacfgs_26_regOut_C;
  wire           pmacfgs_26_regOut_L;
  // pmacfgs_27
  wire [7:0]     pmacfgs_27_rdata;
  wire           pmacfgs_27_regOut_R;
  wire           pmacfgs_27_regOut_W;
  wire           pmacfgs_27_regOut_X;
  wire [1:0]     pmacfgs_27_regOut_A;
  wire           pmacfgs_27_regOut_ATOMIC;
  wire           pmacfgs_27_regOut_C;
  wire           pmacfgs_27_regOut_L;
  // pmacfgs_28
  wire [7:0]     pmacfgs_28_rdata;
  wire           pmacfgs_28_regOut_R;
  wire           pmacfgs_28_regOut_W;
  wire           pmacfgs_28_regOut_X;
  wire [1:0]     pmacfgs_28_regOut_A;
  wire           pmacfgs_28_regOut_ATOMIC;
  wire           pmacfgs_28_regOut_C;
  wire           pmacfgs_28_regOut_L;
  // pmacfgs_29
  wire [7:0]     pmacfgs_29_rdata;
  wire           pmacfgs_29_regOut_R;
  wire           pmacfgs_29_regOut_W;
  wire           pmacfgs_29_regOut_X;
  wire [1:0]     pmacfgs_29_regOut_A;
  wire           pmacfgs_29_regOut_ATOMIC;
  wire           pmacfgs_29_regOut_C;
  wire           pmacfgs_29_regOut_L;
  // pmacfgs_30
  wire [7:0]     pmacfgs_30_rdata;
  wire           pmacfgs_30_regOut_R;
  wire           pmacfgs_30_regOut_W;
  wire           pmacfgs_30_regOut_X;
  wire [1:0]     pmacfgs_30_regOut_A;
  wire           pmacfgs_30_regOut_ATOMIC;
  wire           pmacfgs_30_regOut_C;
  wire           pmacfgs_30_regOut_L;
  // pmacfgs_31
  wire [7:0]     pmacfgs_31_rdata;
  wire           pmacfgs_31_regOut_R;
  wire           pmacfgs_31_regOut_W;
  wire           pmacfgs_31_regOut_X;
  wire [1:0]     pmacfgs_31_regOut_A;
  wire           pmacfgs_31_regOut_ATOMIC;
  wire           pmacfgs_31_regOut_C;
  wire           pmacfgs_31_regOut_L;
  // pmaaddr_0
  wire [63:0]    pmaaddr_0_rdata;
  wire [63:0]    pmaaddr_0_regOut_ALL;
  // pmaaddr_1
  wire [63:0]    pmaaddr_1_rdata;
  wire [63:0]    pmaaddr_1_regOut_ALL;
  // pmaaddr_2
  wire [63:0]    pmaaddr_2_rdata;
  wire [63:0]    pmaaddr_2_regOut_ALL;
  // pmaaddr_3
  wire [63:0]    pmaaddr_3_rdata;
  wire [63:0]    pmaaddr_3_regOut_ALL;
  // pmaaddr_4
  wire [63:0]    pmaaddr_4_rdata;
  wire [63:0]    pmaaddr_4_regOut_ALL;
  // pmaaddr_5
  wire [63:0]    pmaaddr_5_rdata;
  wire [63:0]    pmaaddr_5_regOut_ALL;
  // pmaaddr_6
  wire [63:0]    pmaaddr_6_rdata;
  wire [63:0]    pmaaddr_6_regOut_ALL;
  // pmaaddr_7
  wire [63:0]    pmaaddr_7_rdata;
  wire [63:0]    pmaaddr_7_regOut_ALL;
  // pmaaddr_8
  wire [63:0]    pmaaddr_8_rdata;
  wire [63:0]    pmaaddr_8_regOut_ALL;
  // pmaaddr_9
  wire [63:0]    pmaaddr_9_rdata;
  wire [63:0]    pmaaddr_9_regOut_ALL;
  // pmaaddr_10
  wire [63:0]    pmaaddr_10_rdata;
  wire [63:0]    pmaaddr_10_regOut_ALL;
  // pmaaddr_11
  wire [63:0]    pmaaddr_11_rdata;
  wire [63:0]    pmaaddr_11_regOut_ALL;
  // pmaaddr_12
  wire [63:0]    pmaaddr_12_rdata;
  wire [63:0]    pmaaddr_12_regOut_ALL;
  // pmaaddr_13
  wire [63:0]    pmaaddr_13_rdata;
  wire [63:0]    pmaaddr_13_regOut_ALL;
  // pmaaddr_14
  wire [63:0]    pmaaddr_14_rdata;
  wire [63:0]    pmaaddr_14_regOut_ALL;
  // pmaaddr_15
  wire [63:0]    pmaaddr_15_rdata;
  wire [63:0]    pmaaddr_15_regOut_ALL;
  // pmaaddr_16
  wire [63:0]    pmaaddr_16_rdata;
  wire [63:0]    pmaaddr_16_regOut_ALL;
  // pmaaddr_17
  wire [63:0]    pmaaddr_17_rdata;
  wire [63:0]    pmaaddr_17_regOut_ALL;
  // pmaaddr_18
  wire [63:0]    pmaaddr_18_rdata;
  wire [63:0]    pmaaddr_18_regOut_ALL;
  // pmaaddr_19
  wire [63:0]    pmaaddr_19_rdata;
  wire [63:0]    pmaaddr_19_regOut_ALL;
  // pmaaddr_20
  wire [63:0]    pmaaddr_20_rdata;
  wire [63:0]    pmaaddr_20_regOut_ALL;
  // pmaaddr_21
  wire [63:0]    pmaaddr_21_rdata;
  wire [63:0]    pmaaddr_21_regOut_ALL;
  // pmaaddr_22
  wire [63:0]    pmaaddr_22_rdata;
  wire [63:0]    pmaaddr_22_regOut_ALL;
  // pmaaddr_23
  wire [63:0]    pmaaddr_23_rdata;
  wire [63:0]    pmaaddr_23_regOut_ALL;
  // pmaaddr_24
  wire [63:0]    pmaaddr_24_rdata;
  wire [63:0]    pmaaddr_24_regOut_ALL;
  // pmaaddr_25
  wire [63:0]    pmaaddr_25_rdata;
  wire [63:0]    pmaaddr_25_regOut_ALL;
  // pmaaddr_26
  wire [63:0]    pmaaddr_26_rdata;
  wire [63:0]    pmaaddr_26_regOut_ALL;
  // pmaaddr_27
  wire [63:0]    pmaaddr_27_rdata;
  wire [63:0]    pmaaddr_27_regOut_ALL;
  // pmaaddr_28
  wire [63:0]    pmaaddr_28_rdata;
  wire [63:0]    pmaaddr_28_regOut_ALL;
  // pmaaddr_29
  wire [63:0]    pmaaddr_29_rdata;
  wire [63:0]    pmaaddr_29_regOut_ALL;
  // pmaaddr_30
  wire [63:0]    pmaaddr_30_rdata;
  wire [63:0]    pmaaddr_30_regOut_ALL;
  // pmaaddr_31
  wire [63:0]    pmaaddr_31_rdata;
  wire [63:0]    pmaaddr_31_regOut_ALL;
  // permitMod
  wire           permitMod_io_out_hasLegalWen;
  wire           permitMod_io_out_hasLegalMNret;
  wire           permitMod_io_out_hasLegalMret;
  wire           permitMod_io_out_hasLegalSret;
  wire           permitMod_io_out_hasLegalDret;
  wire           permitMod_io_out_hasLegalWriteFcsr;
  wire           permitMod_io_out_hasLegalWriteVcsr;
  wire           permitMod_io_out_EX_II;
  wire           permitMod_io_out_EX_VI;
  // sstcIRGen
  wire           sstcIRGen_o_STIP;
  wire           sstcIRGen_o_VSTIP;
  // intrMod
  wire           intrMod_io_out_debug;
  wire           intrMod_io_out_nmi;
  wire           intrMod_io_out_interruptVec_valid;
  wire [7:0]     intrMod_io_out_interruptVec_bits;
  wire [11:0]    intrMod_io_out_mtopi_IID;
  wire [7:0]     intrMod_io_out_mtopi_IPRIO;
  wire [11:0]    intrMod_io_out_stopi_IID;
  wire [7:0]     intrMod_io_out_stopi_IPRIO;
  wire [11:0]    intrMod_io_out_vstopi_IID;
  wire [7:0]     intrMod_io_out_vstopi_IPRIO;
  wire           intrMod_io_out_virtualInterruptIsHvictlInject;
  wire           intrMod_io_out_irToHS;
  wire           intrMod_io_out_irToVS;
  // trapHandleMod
  wire [1:0]     trapHandleMod_io_out_entryPrivState_PRVM;
  wire           trapHandleMod_io_out_entryPrivState_V;
  wire           trapHandleMod_io_out_causeNO_Interrupt;
  wire [62:0]    trapHandleMod_io_out_causeNO_ExceptionCode;
  wire           trapHandleMod_io_out_dbltrpToMN;
  wire           trapHandleMod_io_out_hasDTExcp;
  wire [63:0]    trapHandleMod_io_out_pcFromXtvec;
  // pmpEntryMod
  wire [63:0]    pmpEntryMod_io_out_pmpCfgWData;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_0;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_1;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_2;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_3;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_4;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_5;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_6;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_7;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_8;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_9;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_10;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_11;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_12;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_13;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_14;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_15;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_16;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_17;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_18;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_19;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_20;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_21;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_22;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_23;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_24;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_25;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_26;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_27;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_28;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_29;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_30;
  wire [63:0]    pmpEntryMod_io_out_pmpAddrRData_31;
  // pmaEntryMod
  wire [63:0]    pmaEntryMod_io_out_pmaCfgWdata;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_0;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_1;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_2;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_3;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_4;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_5;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_6;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_7;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_8;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_9;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_10;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_11;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_12;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_13;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_14;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_15;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_16;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_17;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_18;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_19;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_20;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_21;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_22;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_23;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_24;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_25;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_26;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_27;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_28;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_29;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_30;
  wire [63:0]    pmaEntryMod_io_out_pmaAddrRData_31;
  // debugMod
  wire           debugMod_io_out_triggerFrontendChange;
  wire           debugMod_io_out_newTriggerChainIsLegal;
  wire           debugMod_io_out_hasDebugTrap;
  wire           debugMod_io_out_hasDebugIntr;
  wire           debugMod_io_out_hasSingleStep;
  wire           debugMod_io_out_triggerEnterDebugMode;
  wire           debugMod_io_out_hasDebugEbreakException;
  wire           debugMod_io_out_breakPoint;
  wire           debugMod_io_out_criticalErrorStateEnterDebug;
  // hpmHc
  wire [5:0]     hpmHc_io_perf_0_value;
  wire [5:0]     hpmHc_io_perf_1_value;
  wire [5:0]     hpmHc_io_perf_2_value;
  wire [5:0]     hpmHc_io_perf_3_value;
  wire [5:0]     hpmHc_io_perf_4_value;
// END GENERATED(newcsr-childnets)

  // ==========================================================================
  // 各 CSR 的 regOut 打包视图（GENERATED，只是字段拼接）
  // ==========================================================================
// BEGIN GENERATED(newcsr-regout) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  // 0x001 fflags
  wire [63:0] regout_fflags = {
    59'h0,
    fcsr_fflags
  };
  // 0x002 frm
  wire [63:0] regout_frm = {
    61'h0,
    fcsr_frm
  };
  // 0x003 fcsr
  wire [63:0] regout_fcsr = fcsr_rdata;
  // 0x008 vstart
  wire [63:0] regout_vstart = vstart_rdata;
  // 0x009 vxsat
  wire [63:0] regout_vxsat = {
    63'h0,
    vcsr_vxsat
  };
  // 0x00A vxrm
  wire [63:0] regout_vxrm = {
    62'h0,
    vcsr_vxrm
  };
  // 0x00F vcsr
  wire [63:0] regout_vcsr = vcsr_rdata;
  // 0x100 sstatus
  wire [63:0] regout_sstatus = {
    mstatus_sstatus_SD,
    38'h100,
    mstatus_sstatus_SDT,
    4'h0,
    mstatus_sstatus_MXR,
    mstatus_sstatus_SUM,
    3'h0,
    mstatus_sstatus_FS,
    2'h0,
    mstatus_sstatus_VS,
    mstatus_sstatus_SPP,
    2'h0,
    mstatus_sstatus_SPIE,
    3'h0,
    mstatus_sstatus_SIE,
    1'h0
  };
  // 0x104 sie
  wire [63:0] regout_sie = {
    sie_regOut_LC63IE,
    sie_regOut_LC62IE,
    sie_regOut_LC61IE,
    sie_regOut_LC60IE,
    sie_regOut_LC59IE,
    sie_regOut_LC58IE,
    sie_regOut_LC57IE,
    sie_regOut_LC56IE,
    sie_regOut_LC55IE,
    sie_regOut_LC54IE,
    sie_regOut_LC53IE,
    sie_regOut_LC52IE,
    sie_regOut_LC51IE,
    sie_regOut_LC50IE,
    sie_regOut_LC49IE,
    sie_regOut_LC48IE,
    sie_regOut_LC47IE,
    sie_regOut_LC46IE,
    sie_regOut_LC45IE,
    sie_regOut_LC44IE,
    sie_regOut_HPRASEIE,
    sie_regOut_LC42IE,
    sie_regOut_LC41IE,
    sie_regOut_LC40IE,
    sie_regOut_LC39IE,
    sie_regOut_LC38IE,
    sie_regOut_LC37IE,
    sie_regOut_LC36IE,
    sie_regOut_LPRASEIE,
    sie_regOut_LC34IE,
    sie_regOut_LC33IE,
    sie_regOut_LC32IE,
    sie_regOut_LC31IE,
    sie_regOut_LC30IE,
    sie_regOut_LC29IE,
    sie_regOut_LC28IE,
    sie_regOut_LC27IE,
    sie_regOut_LC26IE,
    sie_regOut_LC25IE,
    sie_regOut_LC24IE,
    sie_regOut_LC23IE,
    sie_regOut_LC22IE,
    sie_regOut_LC21IE,
    sie_regOut_LC20IE,
    sie_regOut_LC19IE,
    sie_regOut_LC18IE,
    sie_regOut_LC17IE,
    sie_regOut_LC16IE,
    sie_regOut_LC15IE,
    sie_regOut_LC14IE,
    sie_regOut_LCOFIE,
    3'h0,
    sie_regOut_SEIE,
    3'h0,
    sie_regOut_STIE,
    3'h0,
    sie_regOut_SSIE,
    1'h0
  };
  // 0x105 stvec
  wire [63:0] regout_stvec = {
    stvec_regOut_addr,
    stvec_regOut_mode
  };
  // 0x106 scounteren
  wire [63:0] regout_scounteren = {
    32'h0,
    scounteren_regOut_HPM,
    scounteren_regOut_IR,
    scounteren_regOut_TM,
    scounteren_regOut_CY
  };
  // 0x10A senvcfg
  wire [63:0] regout_senvcfg = {
    30'h0,
    senvcfg_regOut_PMM,
    24'h0,
    senvcfg_regOut_CBZE,
    senvcfg_regOut_CBCFE,
    senvcfg_regOut_CBIE,
    4'h0
  };
  // 0x10C sstateen0
  wire [63:0] regout_sstateen0 = {
    61'h0,
    sstateen0_regOut_JVT,
    sstateen0_regOut_FCSR,
    sstateen0_regOut_C
  };
  // 0x10D sstateen1
  wire [63:0] regout_sstateen1 = {
    32'h0,
    sstateen1_regOut_ALL
  };
  // 0x10E sstateen2
  wire [63:0] regout_sstateen2 = {
    32'h0,
    sstateen2_regOut_ALL
  };
  // 0x10F sstateen3
  wire [63:0] regout_sstateen3 = {
    32'h0,
    sstateen3_regOut_ALL
  };
  // 0x140 sscratch
  wire [63:0] regout_sscratch = sscratch_regOut_ALL;
  // 0x141 sepc
  wire [63:0] regout_sepc = {
    sepc_regOut_epc,
    1'h0
  };
  // 0x142 scause
  wire [63:0] regout_scause = {
    scause_regOut_Interrupt,
    scause_regOut_ExceptionCode
  };
  // 0x143 stval
  wire [63:0] regout_stval = stval_regOut_ALL;
  // 0x144 sip
  wire [63:0] regout_sip = {
    sip_regOut_LC63IP,
    sip_regOut_LC62IP,
    sip_regOut_LC61IP,
    sip_regOut_LC60IP,
    sip_regOut_LC59IP,
    sip_regOut_LC58IP,
    sip_regOut_LC57IP,
    sip_regOut_LC56IP,
    sip_regOut_LC55IP,
    sip_regOut_LC54IP,
    sip_regOut_LC53IP,
    sip_regOut_LC52IP,
    sip_regOut_LC51IP,
    sip_regOut_LC50IP,
    sip_regOut_LC49IP,
    sip_regOut_LC48IP,
    sip_regOut_LC47IP,
    sip_regOut_LC46IP,
    sip_regOut_LC45IP,
    sip_regOut_LC44IP,
    sip_regOut_HPRASEIP,
    sip_regOut_LC42IP,
    sip_regOut_LC41IP,
    sip_regOut_LC40IP,
    sip_regOut_LC39IP,
    sip_regOut_LC38IP,
    sip_regOut_LC37IP,
    sip_regOut_LC36IP,
    sip_regOut_LPRASEIP,
    sip_regOut_LC34IP,
    sip_regOut_LC33IP,
    sip_regOut_LC32IP,
    sip_regOut_LC31IP,
    sip_regOut_LC30IP,
    sip_regOut_LC29IP,
    sip_regOut_LC28IP,
    sip_regOut_LC27IP,
    sip_regOut_LC26IP,
    sip_regOut_LC25IP,
    sip_regOut_LC24IP,
    sip_regOut_LC23IP,
    sip_regOut_LC22IP,
    sip_regOut_LC21IP,
    sip_regOut_LC20IP,
    sip_regOut_LC19IP,
    sip_regOut_LC18IP,
    sip_regOut_LC17IP,
    sip_regOut_LC16IP,
    sip_regOut_LC15IP,
    sip_regOut_LC14IP,
    sip_regOut_LCOFIP,
    3'h0,
    sip_regOut_SEIP,
    3'h0,
    sip_regOut_STIP,
    3'h0,
    sip_regOut_SSIP,
    1'h0
  };
  // 0x14D stimecmp
  wire [63:0] regout_stimecmp = stimecmp_regOut_stimecmp;
  // 0x150 siselect
  wire [63:0] regout_siselect = {
    51'h0,
    siselect_regOut_ALL
  };
  // 0x151 sireg
  wire [63:0] regout_sireg = sireg_regOut_ALL;
  // 0x15C stopei
  wire [63:0] regout_stopei = {
    37'h0,
    stopei_regOut_IID,
    5'h0,
    stopei_regOut_IPRIO
  };
  // 0x180 satp
  wire [63:0] regout_satp = {
    satp_regOut_MODE,
    satp_regOut_ASID,
    satp_regOut_PPN
  };
  // 0x200 vsstatus
  wire [63:0] regout_vsstatus = {
    39'h100,
    vsstatus_regOut_SDT,
    4'h0,
    vsstatus_regOut_MXR,
    vsstatus_regOut_SUM,
    3'h0,
    vsstatus_regOut_FS,
    2'h0,
    vsstatus_regOut_VS,
    vsstatus_regOut_SPP,
    2'h0,
    vsstatus_regOut_SPIE,
    3'h0,
    vsstatus_regOut_SIE,
    1'h0
  };
  // 0x204 vsie
  wire [63:0] regout_vsie = {
    vsie_regOut_LC63IE,
    vsie_regOut_LC62IE,
    vsie_regOut_LC61IE,
    vsie_regOut_LC60IE,
    vsie_regOut_LC59IE,
    vsie_regOut_LC58IE,
    vsie_regOut_LC57IE,
    vsie_regOut_LC56IE,
    vsie_regOut_LC55IE,
    vsie_regOut_LC54IE,
    vsie_regOut_LC53IE,
    vsie_regOut_LC52IE,
    vsie_regOut_LC51IE,
    vsie_regOut_LC50IE,
    vsie_regOut_LC49IE,
    vsie_regOut_LC48IE,
    vsie_regOut_LC47IE,
    vsie_regOut_LC46IE,
    vsie_regOut_LC45IE,
    vsie_regOut_LC44IE,
    vsie_regOut_HPRASEIE,
    vsie_regOut_LC42IE,
    vsie_regOut_LC41IE,
    vsie_regOut_LC40IE,
    vsie_regOut_LC39IE,
    vsie_regOut_LC38IE,
    vsie_regOut_LC37IE,
    vsie_regOut_LC36IE,
    vsie_regOut_LPRASEIE,
    vsie_regOut_LC34IE,
    vsie_regOut_LC33IE,
    vsie_regOut_LC32IE,
    vsie_regOut_LC31IE,
    vsie_regOut_LC30IE,
    vsie_regOut_LC29IE,
    vsie_regOut_LC28IE,
    vsie_regOut_LC27IE,
    vsie_regOut_LC26IE,
    vsie_regOut_LC25IE,
    vsie_regOut_LC24IE,
    vsie_regOut_LC23IE,
    vsie_regOut_LC22IE,
    vsie_regOut_LC21IE,
    vsie_regOut_LC20IE,
    vsie_regOut_LC19IE,
    vsie_regOut_LC18IE,
    vsie_regOut_LC17IE,
    vsie_regOut_LC16IE,
    vsie_regOut_LC15IE,
    vsie_regOut_LC14IE,
    vsie_regOut_LCOFIE,
    3'h0,
    vsie_regOut_SEIE,
    3'h0,
    vsie_regOut_STIE,
    3'h0,
    vsie_regOut_SSIE,
    1'h0
  };
  // 0x205 vstvec
  wire [63:0] regout_vstvec = {
    vstvec_regOut_addr,
    vstvec_regOut_mode
  };
  // 0x240 vsscratch
  wire [63:0] regout_vsscratch = vsscratch_regOut_ALL;
  // 0x241 vsepc
  wire [63:0] regout_vsepc = {
    vsepc_regOut_epc,
    1'h0
  };
  // 0x242 vscause
  wire [63:0] regout_vscause = {
    vscause_regOut_Interrupt,
    vscause_regOut_ExceptionCode
  };
  // 0x243 vstval
  wire [63:0] regout_vstval = vstval_regOut_ALL;
  // 0x244 vsip
  wire [63:0] regout_vsip = {
    vsip_regOut_LC63IP,
    vsip_regOut_LC62IP,
    vsip_regOut_LC61IP,
    vsip_regOut_LC60IP,
    vsip_regOut_LC59IP,
    vsip_regOut_LC58IP,
    vsip_regOut_LC57IP,
    vsip_regOut_LC56IP,
    vsip_regOut_LC55IP,
    vsip_regOut_LC54IP,
    vsip_regOut_LC53IP,
    vsip_regOut_LC52IP,
    vsip_regOut_LC51IP,
    vsip_regOut_LC50IP,
    vsip_regOut_LC49IP,
    vsip_regOut_LC48IP,
    vsip_regOut_LC47IP,
    vsip_regOut_LC46IP,
    vsip_regOut_LC45IP,
    vsip_regOut_LC44IP,
    vsip_regOut_HPRASEIP,
    vsip_regOut_LC42IP,
    vsip_regOut_LC41IP,
    vsip_regOut_LC40IP,
    vsip_regOut_LC39IP,
    vsip_regOut_LC38IP,
    vsip_regOut_LC37IP,
    vsip_regOut_LC36IP,
    vsip_regOut_LPRASEIP,
    vsip_regOut_LC34IP,
    vsip_regOut_LC33IP,
    vsip_regOut_LC32IP,
    vsip_regOut_LC31IP,
    vsip_regOut_LC30IP,
    vsip_regOut_LC29IP,
    vsip_regOut_LC28IP,
    vsip_regOut_LC27IP,
    vsip_regOut_LC26IP,
    vsip_regOut_LC25IP,
    vsip_regOut_LC24IP,
    vsip_regOut_LC23IP,
    vsip_regOut_LC22IP,
    vsip_regOut_LC21IP,
    vsip_regOut_LC20IP,
    vsip_regOut_LC19IP,
    vsip_regOut_LC18IP,
    vsip_regOut_LC17IP,
    vsip_regOut_LC16IP,
    vsip_regOut_LC15IP,
    vsip_regOut_LC14IP,
    vsip_regOut_LCOFIP,
    3'h0,
    vsip_regOut_SEIP,
    3'h0,
    vsip_regOut_STIP,
    3'h0,
    vsip_regOut_SSIP,
    1'h0
  };
  // 0x24D vstimecmp
  wire [63:0] regout_vstimecmp = vstimecmp_regOut_vstimecmp;
  // 0x250 vsiselect
  wire [63:0] regout_vsiselect = {
    51'h0,
    vsiselect_regOut_ALL
  };
  // 0x251 vsireg
  wire [63:0] regout_vsireg = vsireg_regOut_ALL;
  // 0x25C vstopei
  wire [63:0] regout_vstopei = {
    37'h0,
    vstopei_regOut_IID,
    5'h0,
    vstopei_regOut_IPRIO
  };
  // 0x280 vsatp
  wire [63:0] regout_vsatp = {
    vsatp_regOut_MODE,
    vsatp_regOut_ASID,
    vsatp_regOut_PPN
  };
  // 0x300 mstatus
  wire [63:0] regout_mstatus = {
    21'h0,
    mstatus_regOut_MDT,
    2'h0,
    mstatus_regOut_MPV,
    mstatus_regOut_GVA,
    13'h500,
    mstatus_regOut_SDT,
    1'h0,
    mstatus_regOut_TSR,
    mstatus_regOut_TW,
    mstatus_regOut_TVM,
    mstatus_regOut_MXR,
    mstatus_regOut_SUM,
    mstatus_regOut_MPRV,
    2'h0,
    mstatus_regOut_FS,
    mstatus_regOut_MPP,
    mstatus_regOut_VS,
    mstatus_regOut_SPP,
    mstatus_regOut_MPIE,
    1'h0,
    mstatus_regOut_SPIE,
    1'h0,
    mstatus_regOut_MIE,
    1'h0,
    mstatus_regOut_SIE,
    1'h0
  };
  // 0x301 misa
  wire [63:0] regout_misa = 64'h80000000003411AF;
  // 0x302 medeleg
  wire [63:0] regout_medeleg = {
    40'h0,
    medeleg_regOut_EX_SGPF,
    medeleg_regOut_EX_VI,
    medeleg_regOut_EX_LGPF,
    medeleg_regOut_EX_IGPF,
    medeleg_regOut_EX_HWE,
    medeleg_regOut_EX_SWC,
    2'h0,
    medeleg_regOut_EX_SPF,
    1'h0,
    medeleg_regOut_EX_LPF,
    medeleg_regOut_EX_IPF,
    1'h0,
    medeleg_regOut_EX_VSCALL,
    medeleg_regOut_EX_HSCALL,
    medeleg_regOut_EX_UCALL,
    medeleg_regOut_EX_SAF,
    medeleg_regOut_EX_SAM,
    medeleg_regOut_EX_LAF,
    medeleg_regOut_EX_LAM,
    medeleg_regOut_EX_BP,
    medeleg_regOut_EX_II,
    medeleg_regOut_EX_IAF,
    medeleg_regOut_EX_IAM
  };
  // 0x303 mideleg
  wire [63:0] regout_mideleg = {
    50'h0,
    mideleg_regOut_LCOFI,
    3'h5,
    mideleg_regOut_SEI,
    3'h1,
    mideleg_regOut_STI,
    3'h1,
    mideleg_regOut_SSI,
    1'h0
  };
  // 0x304 mie
  wire [63:0] regout_mie = {
    50'h0,
    mie_regOut_LCOFIE,
    mie_regOut_SGEIE,
    mie_regOut_MEIE,
    mie_regOut_VSEIE,
    mie_regOut_SEIE,
    1'h0,
    mie_regOut_MTIE,
    mie_regOut_VSTIE,
    mie_regOut_STIE,
    1'h0,
    mie_regOut_MSIE,
    mie_regOut_VSSIE,
    mie_regOut_SSIE,
    1'h0
  };
  // 0x305 mtvec
  wire [63:0] regout_mtvec = {
    mtvec_regOut_addr,
    mtvec_regOut_mode
  };
  // 0x306 mcounteren
  wire [63:0] regout_mcounteren = {
    32'h0,
    mcounteren_regOut_HPM,
    mcounteren_regOut_IR,
    mcounteren_regOut_TM,
    mcounteren_regOut_CY
  };
  // 0x308 mvien
  wire [63:0] regout_mvien = {
    mvien_regOut_LC63IE,
    mvien_regOut_LC62IE,
    mvien_regOut_LC61IE,
    mvien_regOut_LC60IE,
    mvien_regOut_LC59IE,
    mvien_regOut_LC58IE,
    mvien_regOut_LC57IE,
    mvien_regOut_LC56IE,
    mvien_regOut_LC55IE,
    mvien_regOut_LC54IE,
    mvien_regOut_LC53IE,
    mvien_regOut_LC52IE,
    mvien_regOut_LC51IE,
    mvien_regOut_LC50IE,
    mvien_regOut_LC49IE,
    mvien_regOut_LC48IE,
    mvien_regOut_LC47IE,
    mvien_regOut_LC46IE,
    mvien_regOut_LC45IE,
    mvien_regOut_LC44IE,
    mvien_regOut_HPRASEIE,
    mvien_regOut_LC42IE,
    mvien_regOut_LC41IE,
    mvien_regOut_LC40IE,
    mvien_regOut_LC39IE,
    mvien_regOut_LC38IE,
    mvien_regOut_LC37IE,
    mvien_regOut_LC36IE,
    mvien_regOut_LPRASEIE,
    mvien_regOut_LC34IE,
    mvien_regOut_LC33IE,
    mvien_regOut_LC32IE,
    mvien_regOut_LC31IE,
    mvien_regOut_LC30IE,
    mvien_regOut_LC29IE,
    mvien_regOut_LC28IE,
    mvien_regOut_LC27IE,
    mvien_regOut_LC26IE,
    mvien_regOut_LC25IE,
    mvien_regOut_LC24IE,
    mvien_regOut_LC23IE,
    mvien_regOut_LC22IE,
    mvien_regOut_LC21IE,
    mvien_regOut_LC20IE,
    mvien_regOut_LC19IE,
    mvien_regOut_LC18IE,
    mvien_regOut_LC17IE,
    mvien_regOut_LC16IE,
    mvien_regOut_LC15IE,
    mvien_regOut_LC14IE,
    4'h0,
    mvien_regOut_SEIE,
    7'h0,
    mvien_regOut_SSIE,
    1'h0
  };
  // 0x309 mvip
  wire [63:0] regout_mvip = {
    mvip_regOut_LC63IP,
    mvip_regOut_LC62IP,
    mvip_regOut_LC61IP,
    mvip_regOut_LC60IP,
    mvip_regOut_LC59IP,
    mvip_regOut_LC58IP,
    mvip_regOut_LC57IP,
    mvip_regOut_LC56IP,
    mvip_regOut_LC55IP,
    mvip_regOut_LC54IP,
    mvip_regOut_LC53IP,
    mvip_regOut_LC52IP,
    mvip_regOut_LC51IP,
    mvip_regOut_LC50IP,
    mvip_regOut_LC49IP,
    mvip_regOut_LC48IP,
    mvip_regOut_LC47IP,
    mvip_regOut_LC46IP,
    mvip_regOut_LC45IP,
    mvip_regOut_LC44IP,
    mvip_regOut_HPRASEIP,
    mvip_regOut_LC42IP,
    mvip_regOut_LC41IP,
    mvip_regOut_LC40IP,
    mvip_regOut_LC39IP,
    mvip_regOut_LC38IP,
    mvip_regOut_LC37IP,
    mvip_regOut_LC36IP,
    mvip_regOut_LPRASEIP,
    mvip_regOut_LC34IP,
    mvip_regOut_LC33IP,
    mvip_regOut_LC32IP,
    mvip_regOut_LC31IP,
    mvip_regOut_LC30IP,
    mvip_regOut_LC29IP,
    mvip_regOut_LC28IP,
    mvip_regOut_LC27IP,
    mvip_regOut_LC26IP,
    mvip_regOut_LC25IP,
    mvip_regOut_LC24IP,
    mvip_regOut_LC23IP,
    mvip_regOut_LC22IP,
    mvip_regOut_LC21IP,
    mvip_regOut_LC20IP,
    mvip_regOut_LC19IP,
    mvip_regOut_LC18IP,
    mvip_regOut_LC17IP,
    mvip_regOut_LC16IP,
    mvip_regOut_LC15IP,
    mvip_regOut_LC14IP,
    mvip_regOut_LCOFIP,
    3'h0,
    mvip_regOut_SEIP,
    3'h0,
    mvip_regOut_STIP,
    3'h0,
    mvip_regOut_SSIP,
    1'h0
  };
  // 0x30A menvcfg
  wire [63:0] regout_menvcfg = {
    menvcfg_regOut_STCE,
    menvcfg_regOut_PBMTE,
    2'h0,
    menvcfg_regOut_DTE,
    25'h0,
    menvcfg_regOut_PMM,
    24'h0,
    menvcfg_regOut_CBZE,
    menvcfg_regOut_CBCFE,
    menvcfg_regOut_CBIE,
    4'h0
  };
  // 0x30C mstateen0
  wire [63:0] regout_mstateen0 = {
    mstateen0_regOut_SE0,
    mstateen0_regOut_ENVCFG,
    1'h0,
    mstateen0_regOut_CSRIND,
    mstateen0_regOut_AIA,
    mstateen0_regOut_IMSIC,
    mstateen0_regOut_CONTEXT,
    56'h0,
    mstateen0_regOut_C
  };
  // 0x30D mstateen1
  wire [63:0] regout_mstateen1 = {
    mstateen1_regOut_SE,
    63'h0
  };
  // 0x30E mstateen2
  wire [63:0] regout_mstateen2 = {
    mstateen2_regOut_SE,
    63'h0
  };
  // 0x30F mstateen3
  wire [63:0] regout_mstateen3 = {
    mstateen3_regOut_SE,
    63'h0
  };
  // 0x320 mcountinhibit
  wire [63:0] regout_mcountinhibit = {
    32'h0,
    mcountinhibit_regOut_HPM3,
    mcountinhibit_regOut_IR,
    1'h0,
    mcountinhibit_regOut_CY
  };
  // 0x323 Mhpmevent3
  wire [63:0] regout_Mhpmevent3 = {
    Mhpmevent3_regOut_OF,
    Mhpmevent3_regOut_MINH,
    Mhpmevent3_regOut_SINH,
    Mhpmevent3_regOut_UINH,
    Mhpmevent3_regOut_VSINH,
    Mhpmevent3_regOut_VUINH,
    3'h0,
    Mhpmevent3_regOut_OPTYPE2,
    Mhpmevent3_regOut_OPTYPE1,
    Mhpmevent3_regOut_OPTYPE0,
    Mhpmevent3_regOut_EVENT3,
    Mhpmevent3_regOut_EVENT2,
    Mhpmevent3_regOut_EVENT1,
    Mhpmevent3_regOut_EVENT0
  };
  // 0x324 Mhpmevent4
  wire [63:0] regout_Mhpmevent4 = {
    Mhpmevent4_regOut_OF,
    Mhpmevent4_regOut_MINH,
    Mhpmevent4_regOut_SINH,
    Mhpmevent4_regOut_UINH,
    Mhpmevent4_regOut_VSINH,
    Mhpmevent4_regOut_VUINH,
    3'h0,
    Mhpmevent4_regOut_OPTYPE2,
    Mhpmevent4_regOut_OPTYPE1,
    Mhpmevent4_regOut_OPTYPE0,
    Mhpmevent4_regOut_EVENT3,
    Mhpmevent4_regOut_EVENT2,
    Mhpmevent4_regOut_EVENT1,
    Mhpmevent4_regOut_EVENT0
  };
  // 0x325 Mhpmevent5
  wire [63:0] regout_Mhpmevent5 = {
    Mhpmevent5_regOut_OF,
    Mhpmevent5_regOut_MINH,
    Mhpmevent5_regOut_SINH,
    Mhpmevent5_regOut_UINH,
    Mhpmevent5_regOut_VSINH,
    Mhpmevent5_regOut_VUINH,
    3'h0,
    Mhpmevent5_regOut_OPTYPE2,
    Mhpmevent5_regOut_OPTYPE1,
    Mhpmevent5_regOut_OPTYPE0,
    Mhpmevent5_regOut_EVENT3,
    Mhpmevent5_regOut_EVENT2,
    Mhpmevent5_regOut_EVENT1,
    Mhpmevent5_regOut_EVENT0
  };
  // 0x326 Mhpmevent6
  wire [63:0] regout_Mhpmevent6 = {
    Mhpmevent6_regOut_OF,
    Mhpmevent6_regOut_MINH,
    Mhpmevent6_regOut_SINH,
    Mhpmevent6_regOut_UINH,
    Mhpmevent6_regOut_VSINH,
    Mhpmevent6_regOut_VUINH,
    3'h0,
    Mhpmevent6_regOut_OPTYPE2,
    Mhpmevent6_regOut_OPTYPE1,
    Mhpmevent6_regOut_OPTYPE0,
    Mhpmevent6_regOut_EVENT3,
    Mhpmevent6_regOut_EVENT2,
    Mhpmevent6_regOut_EVENT1,
    Mhpmevent6_regOut_EVENT0
  };
  // 0x327 Mhpmevent7
  wire [63:0] regout_Mhpmevent7 = {
    Mhpmevent7_regOut_OF,
    Mhpmevent7_regOut_MINH,
    Mhpmevent7_regOut_SINH,
    Mhpmevent7_regOut_UINH,
    Mhpmevent7_regOut_VSINH,
    Mhpmevent7_regOut_VUINH,
    3'h0,
    Mhpmevent7_regOut_OPTYPE2,
    Mhpmevent7_regOut_OPTYPE1,
    Mhpmevent7_regOut_OPTYPE0,
    Mhpmevent7_regOut_EVENT3,
    Mhpmevent7_regOut_EVENT2,
    Mhpmevent7_regOut_EVENT1,
    Mhpmevent7_regOut_EVENT0
  };
  // 0x328 Mhpmevent8
  wire [63:0] regout_Mhpmevent8 = {
    Mhpmevent8_regOut_OF,
    Mhpmevent8_regOut_MINH,
    Mhpmevent8_regOut_SINH,
    Mhpmevent8_regOut_UINH,
    Mhpmevent8_regOut_VSINH,
    Mhpmevent8_regOut_VUINH,
    3'h0,
    Mhpmevent8_regOut_OPTYPE2,
    Mhpmevent8_regOut_OPTYPE1,
    Mhpmevent8_regOut_OPTYPE0,
    Mhpmevent8_regOut_EVENT3,
    Mhpmevent8_regOut_EVENT2,
    Mhpmevent8_regOut_EVENT1,
    Mhpmevent8_regOut_EVENT0
  };
  // 0x329 Mhpmevent9
  wire [63:0] regout_Mhpmevent9 = {
    Mhpmevent9_regOut_OF,
    Mhpmevent9_regOut_MINH,
    Mhpmevent9_regOut_SINH,
    Mhpmevent9_regOut_UINH,
    Mhpmevent9_regOut_VSINH,
    Mhpmevent9_regOut_VUINH,
    3'h0,
    Mhpmevent9_regOut_OPTYPE2,
    Mhpmevent9_regOut_OPTYPE1,
    Mhpmevent9_regOut_OPTYPE0,
    Mhpmevent9_regOut_EVENT3,
    Mhpmevent9_regOut_EVENT2,
    Mhpmevent9_regOut_EVENT1,
    Mhpmevent9_regOut_EVENT0
  };
  // 0x32A Mhpmevent10
  wire [63:0] regout_Mhpmevent10 = {
    Mhpmevent10_regOut_OF,
    Mhpmevent10_regOut_MINH,
    Mhpmevent10_regOut_SINH,
    Mhpmevent10_regOut_UINH,
    Mhpmevent10_regOut_VSINH,
    Mhpmevent10_regOut_VUINH,
    3'h0,
    Mhpmevent10_regOut_OPTYPE2,
    Mhpmevent10_regOut_OPTYPE1,
    Mhpmevent10_regOut_OPTYPE0,
    Mhpmevent10_regOut_EVENT3,
    Mhpmevent10_regOut_EVENT2,
    Mhpmevent10_regOut_EVENT1,
    Mhpmevent10_regOut_EVENT0
  };
  // 0x32B Mhpmevent11
  wire [63:0] regout_Mhpmevent11 = {
    Mhpmevent11_regOut_OF,
    Mhpmevent11_regOut_MINH,
    Mhpmevent11_regOut_SINH,
    Mhpmevent11_regOut_UINH,
    Mhpmevent11_regOut_VSINH,
    Mhpmevent11_regOut_VUINH,
    3'h0,
    Mhpmevent11_regOut_OPTYPE2,
    Mhpmevent11_regOut_OPTYPE1,
    Mhpmevent11_regOut_OPTYPE0,
    Mhpmevent11_regOut_EVENT3,
    Mhpmevent11_regOut_EVENT2,
    Mhpmevent11_regOut_EVENT1,
    Mhpmevent11_regOut_EVENT0
  };
  // 0x32C Mhpmevent12
  wire [63:0] regout_Mhpmevent12 = {
    Mhpmevent12_regOut_OF,
    Mhpmevent12_regOut_MINH,
    Mhpmevent12_regOut_SINH,
    Mhpmevent12_regOut_UINH,
    Mhpmevent12_regOut_VSINH,
    Mhpmevent12_regOut_VUINH,
    3'h0,
    Mhpmevent12_regOut_OPTYPE2,
    Mhpmevent12_regOut_OPTYPE1,
    Mhpmevent12_regOut_OPTYPE0,
    Mhpmevent12_regOut_EVENT3,
    Mhpmevent12_regOut_EVENT2,
    Mhpmevent12_regOut_EVENT1,
    Mhpmevent12_regOut_EVENT0
  };
  // 0x32D Mhpmevent13
  wire [63:0] regout_Mhpmevent13 = {
    Mhpmevent13_regOut_OF,
    Mhpmevent13_regOut_MINH,
    Mhpmevent13_regOut_SINH,
    Mhpmevent13_regOut_UINH,
    Mhpmevent13_regOut_VSINH,
    Mhpmevent13_regOut_VUINH,
    3'h0,
    Mhpmevent13_regOut_OPTYPE2,
    Mhpmevent13_regOut_OPTYPE1,
    Mhpmevent13_regOut_OPTYPE0,
    Mhpmevent13_regOut_EVENT3,
    Mhpmevent13_regOut_EVENT2,
    Mhpmevent13_regOut_EVENT1,
    Mhpmevent13_regOut_EVENT0
  };
  // 0x32E Mhpmevent14
  wire [63:0] regout_Mhpmevent14 = {
    Mhpmevent14_regOut_OF,
    Mhpmevent14_regOut_MINH,
    Mhpmevent14_regOut_SINH,
    Mhpmevent14_regOut_UINH,
    Mhpmevent14_regOut_VSINH,
    Mhpmevent14_regOut_VUINH,
    3'h0,
    Mhpmevent14_regOut_OPTYPE2,
    Mhpmevent14_regOut_OPTYPE1,
    Mhpmevent14_regOut_OPTYPE0,
    Mhpmevent14_regOut_EVENT3,
    Mhpmevent14_regOut_EVENT2,
    Mhpmevent14_regOut_EVENT1,
    Mhpmevent14_regOut_EVENT0
  };
  // 0x32F Mhpmevent15
  wire [63:0] regout_Mhpmevent15 = {
    Mhpmevent15_regOut_OF,
    Mhpmevent15_regOut_MINH,
    Mhpmevent15_regOut_SINH,
    Mhpmevent15_regOut_UINH,
    Mhpmevent15_regOut_VSINH,
    Mhpmevent15_regOut_VUINH,
    3'h0,
    Mhpmevent15_regOut_OPTYPE2,
    Mhpmevent15_regOut_OPTYPE1,
    Mhpmevent15_regOut_OPTYPE0,
    Mhpmevent15_regOut_EVENT3,
    Mhpmevent15_regOut_EVENT2,
    Mhpmevent15_regOut_EVENT1,
    Mhpmevent15_regOut_EVENT0
  };
  // 0x330 Mhpmevent16
  wire [63:0] regout_Mhpmevent16 = {
    Mhpmevent16_regOut_OF,
    Mhpmevent16_regOut_MINH,
    Mhpmevent16_regOut_SINH,
    Mhpmevent16_regOut_UINH,
    Mhpmevent16_regOut_VSINH,
    Mhpmevent16_regOut_VUINH,
    3'h0,
    Mhpmevent16_regOut_OPTYPE2,
    Mhpmevent16_regOut_OPTYPE1,
    Mhpmevent16_regOut_OPTYPE0,
    Mhpmevent16_regOut_EVENT3,
    Mhpmevent16_regOut_EVENT2,
    Mhpmevent16_regOut_EVENT1,
    Mhpmevent16_regOut_EVENT0
  };
  // 0x331 Mhpmevent17
  wire [63:0] regout_Mhpmevent17 = {
    Mhpmevent17_regOut_OF,
    Mhpmevent17_regOut_MINH,
    Mhpmevent17_regOut_SINH,
    Mhpmevent17_regOut_UINH,
    Mhpmevent17_regOut_VSINH,
    Mhpmevent17_regOut_VUINH,
    3'h0,
    Mhpmevent17_regOut_OPTYPE2,
    Mhpmevent17_regOut_OPTYPE1,
    Mhpmevent17_regOut_OPTYPE0,
    Mhpmevent17_regOut_EVENT3,
    Mhpmevent17_regOut_EVENT2,
    Mhpmevent17_regOut_EVENT1,
    Mhpmevent17_regOut_EVENT0
  };
  // 0x332 Mhpmevent18
  wire [63:0] regout_Mhpmevent18 = {
    Mhpmevent18_regOut_OF,
    Mhpmevent18_regOut_MINH,
    Mhpmevent18_regOut_SINH,
    Mhpmevent18_regOut_UINH,
    Mhpmevent18_regOut_VSINH,
    Mhpmevent18_regOut_VUINH,
    3'h0,
    Mhpmevent18_regOut_OPTYPE2,
    Mhpmevent18_regOut_OPTYPE1,
    Mhpmevent18_regOut_OPTYPE0,
    Mhpmevent18_regOut_EVENT3,
    Mhpmevent18_regOut_EVENT2,
    Mhpmevent18_regOut_EVENT1,
    Mhpmevent18_regOut_EVENT0
  };
  // 0x333 Mhpmevent19
  wire [63:0] regout_Mhpmevent19 = {
    Mhpmevent19_regOut_OF,
    Mhpmevent19_regOut_MINH,
    Mhpmevent19_regOut_SINH,
    Mhpmevent19_regOut_UINH,
    Mhpmevent19_regOut_VSINH,
    Mhpmevent19_regOut_VUINH,
    3'h0,
    Mhpmevent19_regOut_OPTYPE2,
    Mhpmevent19_regOut_OPTYPE1,
    Mhpmevent19_regOut_OPTYPE0,
    Mhpmevent19_regOut_EVENT3,
    Mhpmevent19_regOut_EVENT2,
    Mhpmevent19_regOut_EVENT1,
    Mhpmevent19_regOut_EVENT0
  };
  // 0x334 Mhpmevent20
  wire [63:0] regout_Mhpmevent20 = {
    Mhpmevent20_regOut_OF,
    Mhpmevent20_regOut_MINH,
    Mhpmevent20_regOut_SINH,
    Mhpmevent20_regOut_UINH,
    Mhpmevent20_regOut_VSINH,
    Mhpmevent20_regOut_VUINH,
    3'h0,
    Mhpmevent20_regOut_OPTYPE2,
    Mhpmevent20_regOut_OPTYPE1,
    Mhpmevent20_regOut_OPTYPE0,
    Mhpmevent20_regOut_EVENT3,
    Mhpmevent20_regOut_EVENT2,
    Mhpmevent20_regOut_EVENT1,
    Mhpmevent20_regOut_EVENT0
  };
  // 0x335 Mhpmevent21
  wire [63:0] regout_Mhpmevent21 = {
    Mhpmevent21_regOut_OF,
    Mhpmevent21_regOut_MINH,
    Mhpmevent21_regOut_SINH,
    Mhpmevent21_regOut_UINH,
    Mhpmevent21_regOut_VSINH,
    Mhpmevent21_regOut_VUINH,
    3'h0,
    Mhpmevent21_regOut_OPTYPE2,
    Mhpmevent21_regOut_OPTYPE1,
    Mhpmevent21_regOut_OPTYPE0,
    Mhpmevent21_regOut_EVENT3,
    Mhpmevent21_regOut_EVENT2,
    Mhpmevent21_regOut_EVENT1,
    Mhpmevent21_regOut_EVENT0
  };
  // 0x336 Mhpmevent22
  wire [63:0] regout_Mhpmevent22 = {
    Mhpmevent22_regOut_OF,
    Mhpmevent22_regOut_MINH,
    Mhpmevent22_regOut_SINH,
    Mhpmevent22_regOut_UINH,
    Mhpmevent22_regOut_VSINH,
    Mhpmevent22_regOut_VUINH,
    3'h0,
    Mhpmevent22_regOut_OPTYPE2,
    Mhpmevent22_regOut_OPTYPE1,
    Mhpmevent22_regOut_OPTYPE0,
    Mhpmevent22_regOut_EVENT3,
    Mhpmevent22_regOut_EVENT2,
    Mhpmevent22_regOut_EVENT1,
    Mhpmevent22_regOut_EVENT0
  };
  // 0x337 Mhpmevent23
  wire [63:0] regout_Mhpmevent23 = {
    Mhpmevent23_regOut_OF,
    Mhpmevent23_regOut_MINH,
    Mhpmevent23_regOut_SINH,
    Mhpmevent23_regOut_UINH,
    Mhpmevent23_regOut_VSINH,
    Mhpmevent23_regOut_VUINH,
    3'h0,
    Mhpmevent23_regOut_OPTYPE2,
    Mhpmevent23_regOut_OPTYPE1,
    Mhpmevent23_regOut_OPTYPE0,
    Mhpmevent23_regOut_EVENT3,
    Mhpmevent23_regOut_EVENT2,
    Mhpmevent23_regOut_EVENT1,
    Mhpmevent23_regOut_EVENT0
  };
  // 0x338 Mhpmevent24
  wire [63:0] regout_Mhpmevent24 = {
    Mhpmevent24_regOut_OF,
    Mhpmevent24_regOut_MINH,
    Mhpmevent24_regOut_SINH,
    Mhpmevent24_regOut_UINH,
    Mhpmevent24_regOut_VSINH,
    Mhpmevent24_regOut_VUINH,
    3'h0,
    Mhpmevent24_regOut_OPTYPE2,
    Mhpmevent24_regOut_OPTYPE1,
    Mhpmevent24_regOut_OPTYPE0,
    Mhpmevent24_regOut_EVENT3,
    Mhpmevent24_regOut_EVENT2,
    Mhpmevent24_regOut_EVENT1,
    Mhpmevent24_regOut_EVENT0
  };
  // 0x339 Mhpmevent25
  wire [63:0] regout_Mhpmevent25 = {
    Mhpmevent25_regOut_OF,
    Mhpmevent25_regOut_MINH,
    Mhpmevent25_regOut_SINH,
    Mhpmevent25_regOut_UINH,
    Mhpmevent25_regOut_VSINH,
    Mhpmevent25_regOut_VUINH,
    3'h0,
    Mhpmevent25_regOut_OPTYPE2,
    Mhpmevent25_regOut_OPTYPE1,
    Mhpmevent25_regOut_OPTYPE0,
    Mhpmevent25_regOut_EVENT3,
    Mhpmevent25_regOut_EVENT2,
    Mhpmevent25_regOut_EVENT1,
    Mhpmevent25_regOut_EVENT0
  };
  // 0x33A Mhpmevent26
  wire [63:0] regout_Mhpmevent26 = {
    Mhpmevent26_regOut_OF,
    Mhpmevent26_regOut_MINH,
    Mhpmevent26_regOut_SINH,
    Mhpmevent26_regOut_UINH,
    Mhpmevent26_regOut_VSINH,
    Mhpmevent26_regOut_VUINH,
    3'h0,
    Mhpmevent26_regOut_OPTYPE2,
    Mhpmevent26_regOut_OPTYPE1,
    Mhpmevent26_regOut_OPTYPE0,
    Mhpmevent26_regOut_EVENT3,
    Mhpmevent26_regOut_EVENT2,
    Mhpmevent26_regOut_EVENT1,
    Mhpmevent26_regOut_EVENT0
  };
  // 0x33B Mhpmevent27
  wire [63:0] regout_Mhpmevent27 = {
    Mhpmevent27_regOut_OF,
    Mhpmevent27_regOut_MINH,
    Mhpmevent27_regOut_SINH,
    Mhpmevent27_regOut_UINH,
    Mhpmevent27_regOut_VSINH,
    Mhpmevent27_regOut_VUINH,
    3'h0,
    Mhpmevent27_regOut_OPTYPE2,
    Mhpmevent27_regOut_OPTYPE1,
    Mhpmevent27_regOut_OPTYPE0,
    Mhpmevent27_regOut_EVENT3,
    Mhpmevent27_regOut_EVENT2,
    Mhpmevent27_regOut_EVENT1,
    Mhpmevent27_regOut_EVENT0
  };
  // 0x33C Mhpmevent28
  wire [63:0] regout_Mhpmevent28 = {
    Mhpmevent28_regOut_OF,
    Mhpmevent28_regOut_MINH,
    Mhpmevent28_regOut_SINH,
    Mhpmevent28_regOut_UINH,
    Mhpmevent28_regOut_VSINH,
    Mhpmevent28_regOut_VUINH,
    3'h0,
    Mhpmevent28_regOut_OPTYPE2,
    Mhpmevent28_regOut_OPTYPE1,
    Mhpmevent28_regOut_OPTYPE0,
    Mhpmevent28_regOut_EVENT3,
    Mhpmevent28_regOut_EVENT2,
    Mhpmevent28_regOut_EVENT1,
    Mhpmevent28_regOut_EVENT0
  };
  // 0x33D Mhpmevent29
  wire [63:0] regout_Mhpmevent29 = {
    Mhpmevent29_regOut_OF,
    Mhpmevent29_regOut_MINH,
    Mhpmevent29_regOut_SINH,
    Mhpmevent29_regOut_UINH,
    Mhpmevent29_regOut_VSINH,
    Mhpmevent29_regOut_VUINH,
    3'h0,
    Mhpmevent29_regOut_OPTYPE2,
    Mhpmevent29_regOut_OPTYPE1,
    Mhpmevent29_regOut_OPTYPE0,
    Mhpmevent29_regOut_EVENT3,
    Mhpmevent29_regOut_EVENT2,
    Mhpmevent29_regOut_EVENT1,
    Mhpmevent29_regOut_EVENT0
  };
  // 0x33E Mhpmevent30
  wire [63:0] regout_Mhpmevent30 = {
    Mhpmevent30_regOut_OF,
    Mhpmevent30_regOut_MINH,
    Mhpmevent30_regOut_SINH,
    Mhpmevent30_regOut_UINH,
    Mhpmevent30_regOut_VSINH,
    Mhpmevent30_regOut_VUINH,
    3'h0,
    Mhpmevent30_regOut_OPTYPE2,
    Mhpmevent30_regOut_OPTYPE1,
    Mhpmevent30_regOut_OPTYPE0,
    Mhpmevent30_regOut_EVENT3,
    Mhpmevent30_regOut_EVENT2,
    Mhpmevent30_regOut_EVENT1,
    Mhpmevent30_regOut_EVENT0
  };
  // 0x33F Mhpmevent31
  wire [63:0] regout_Mhpmevent31 = {
    Mhpmevent31_regOut_OF,
    Mhpmevent31_regOut_MINH,
    Mhpmevent31_regOut_SINH,
    Mhpmevent31_regOut_UINH,
    Mhpmevent31_regOut_VSINH,
    Mhpmevent31_regOut_VUINH,
    3'h0,
    Mhpmevent31_regOut_OPTYPE2,
    Mhpmevent31_regOut_OPTYPE1,
    Mhpmevent31_regOut_OPTYPE0,
    Mhpmevent31_regOut_EVENT3,
    Mhpmevent31_regOut_EVENT2,
    Mhpmevent31_regOut_EVENT1,
    Mhpmevent31_regOut_EVENT0
  };
  // 0x340 mscratch
  wire [63:0] regout_mscratch = mscratch_regOut_ALL;
  // 0x341 mepc
  wire [63:0] regout_mepc = {
    mepc_regOut_epc,
    1'h0
  };
  // 0x342 mcause
  wire [63:0] regout_mcause = {
    mcause_regOut_Interrupt,
    mcause_regOut_ExceptionCode
  };
  // 0x343 mtval
  wire [63:0] regout_mtval = mtval_regOut_ALL;
  // 0x344 mip
  wire [63:0] regout_mip = {
    50'h0,
    mip_regOut_LCOFIP,
    mip_regOut_SGEIP,
    mip_regOut_MEIP,
    mip_regOut_VSEIP,
    mip_regOut_SEIP,
    1'h0,
    mip_regOut_MTIP,
    mip_regOut_VSTIP,
    mip_regOut_STIP,
    1'h0,
    mip_regOut_MSIP,
    mip_regOut_VSSIP,
    mip_regOut_SSIP,
    1'h0
  };
  // 0x34A mtinst
  wire [63:0] regout_mtinst = mtinst_regOut_ALL;
  // 0x34B mtval2
  wire [63:0] regout_mtval2 = mtval2_regOut_ALL;
  // 0x350 miselect
  wire [63:0] regout_miselect = {
    55'h0,
    miselect_regOut_ALL
  };
  // 0x351 mireg
  wire [63:0] regout_mireg = mireg_regOut_ALL;
  // 0x35C mtopei
  wire [63:0] regout_mtopei = {
    37'h0,
    mtopei_regOut_IID,
    5'h0,
    mtopei_regOut_IPRIO
  };
  // 0x3A0 pmpcfg_0
  wire [63:0] regout_pmpcfg_0 = pmpcfg_0_regOut_ALL;
  // 0x3A2 pmpcfg_1
  wire [63:0] regout_pmpcfg_1 = pmpcfg_1_regOut_ALL;
  // 0x3A4 pmpcfg_2
  wire [63:0] regout_pmpcfg_2 = pmpcfg_2_regOut_ALL;
  // 0x3A6 pmpcfg_3
  wire [63:0] regout_pmpcfg_3 = pmpcfg_3_regOut_ALL;
  // 0x3A8 pmpcfg_4
  wire [63:0] regout_pmpcfg_4 = pmpcfg_4_regOut_ALL;
  // 0x3AA pmpcfg_5
  wire [63:0] regout_pmpcfg_5 = pmpcfg_5_regOut_ALL;
  // 0x3AC pmpcfg_6
  wire [63:0] regout_pmpcfg_6 = pmpcfg_6_regOut_ALL;
  // 0x3AE pmpcfg_7
  wire [63:0] regout_pmpcfg_7 = pmpcfg_7_regOut_ALL;
  // 0x3B0 pmpaddr_0
  wire [63:0] regout_pmpaddr_0 = {
    18'h0,
    pmpaddr_0_regOut_ADDRESS
  };
  // 0x3B1 pmpaddr_1
  wire [63:0] regout_pmpaddr_1 = {
    18'h0,
    pmpaddr_1_regOut_ADDRESS
  };
  // 0x3B2 pmpaddr_2
  wire [63:0] regout_pmpaddr_2 = {
    18'h0,
    pmpaddr_2_regOut_ADDRESS
  };
  // 0x3B3 pmpaddr_3
  wire [63:0] regout_pmpaddr_3 = {
    18'h0,
    pmpaddr_3_regOut_ADDRESS
  };
  // 0x3B4 pmpaddr_4
  wire [63:0] regout_pmpaddr_4 = {
    18'h0,
    pmpaddr_4_regOut_ADDRESS
  };
  // 0x3B5 pmpaddr_5
  wire [63:0] regout_pmpaddr_5 = {
    18'h0,
    pmpaddr_5_regOut_ADDRESS
  };
  // 0x3B6 pmpaddr_6
  wire [63:0] regout_pmpaddr_6 = {
    18'h0,
    pmpaddr_6_regOut_ADDRESS
  };
  // 0x3B7 pmpaddr_7
  wire [63:0] regout_pmpaddr_7 = {
    18'h0,
    pmpaddr_7_regOut_ADDRESS
  };
  // 0x3B8 pmpaddr_8
  wire [63:0] regout_pmpaddr_8 = {
    18'h0,
    pmpaddr_8_regOut_ADDRESS
  };
  // 0x3B9 pmpaddr_9
  wire [63:0] regout_pmpaddr_9 = {
    18'h0,
    pmpaddr_9_regOut_ADDRESS
  };
  // 0x3BA pmpaddr_10
  wire [63:0] regout_pmpaddr_10 = {
    18'h0,
    pmpaddr_10_regOut_ADDRESS
  };
  // 0x3BB pmpaddr_11
  wire [63:0] regout_pmpaddr_11 = {
    18'h0,
    pmpaddr_11_regOut_ADDRESS
  };
  // 0x3BC pmpaddr_12
  wire [63:0] regout_pmpaddr_12 = {
    18'h0,
    pmpaddr_12_regOut_ADDRESS
  };
  // 0x3BD pmpaddr_13
  wire [63:0] regout_pmpaddr_13 = {
    18'h0,
    pmpaddr_13_regOut_ADDRESS
  };
  // 0x3BE pmpaddr_14
  wire [63:0] regout_pmpaddr_14 = {
    18'h0,
    pmpaddr_14_regOut_ADDRESS
  };
  // 0x3BF pmpaddr_15
  wire [63:0] regout_pmpaddr_15 = {
    18'h0,
    pmpaddr_15_regOut_ADDRESS
  };
  // 0x3C0 pmpaddr_16
  wire [63:0] regout_pmpaddr_16 = {
    18'h0,
    pmpaddr_16_regOut_ADDRESS
  };
  // 0x3C1 pmpaddr_17
  wire [63:0] regout_pmpaddr_17 = {
    18'h0,
    pmpaddr_17_regOut_ADDRESS
  };
  // 0x3C2 pmpaddr_18
  wire [63:0] regout_pmpaddr_18 = {
    18'h0,
    pmpaddr_18_regOut_ADDRESS
  };
  // 0x3C3 pmpaddr_19
  wire [63:0] regout_pmpaddr_19 = {
    18'h0,
    pmpaddr_19_regOut_ADDRESS
  };
  // 0x3C4 pmpaddr_20
  wire [63:0] regout_pmpaddr_20 = {
    18'h0,
    pmpaddr_20_regOut_ADDRESS
  };
  // 0x3C5 pmpaddr_21
  wire [63:0] regout_pmpaddr_21 = {
    18'h0,
    pmpaddr_21_regOut_ADDRESS
  };
  // 0x3C6 pmpaddr_22
  wire [63:0] regout_pmpaddr_22 = {
    18'h0,
    pmpaddr_22_regOut_ADDRESS
  };
  // 0x3C7 pmpaddr_23
  wire [63:0] regout_pmpaddr_23 = {
    18'h0,
    pmpaddr_23_regOut_ADDRESS
  };
  // 0x3C8 pmpaddr_24
  wire [63:0] regout_pmpaddr_24 = {
    18'h0,
    pmpaddr_24_regOut_ADDRESS
  };
  // 0x3C9 pmpaddr_25
  wire [63:0] regout_pmpaddr_25 = {
    18'h0,
    pmpaddr_25_regOut_ADDRESS
  };
  // 0x3CA pmpaddr_26
  wire [63:0] regout_pmpaddr_26 = {
    18'h0,
    pmpaddr_26_regOut_ADDRESS
  };
  // 0x3CB pmpaddr_27
  wire [63:0] regout_pmpaddr_27 = {
    18'h0,
    pmpaddr_27_regOut_ADDRESS
  };
  // 0x3CC pmpaddr_28
  wire [63:0] regout_pmpaddr_28 = {
    18'h0,
    pmpaddr_28_regOut_ADDRESS
  };
  // 0x3CD pmpaddr_29
  wire [63:0] regout_pmpaddr_29 = {
    18'h0,
    pmpaddr_29_regOut_ADDRESS
  };
  // 0x3CE pmpaddr_30
  wire [63:0] regout_pmpaddr_30 = {
    18'h0,
    pmpaddr_30_regOut_ADDRESS
  };
  // 0x3CF pmpaddr_31
  wire [63:0] regout_pmpaddr_31 = {
    18'h0,
    pmpaddr_31_regOut_ADDRESS
  };
  // 0x3D0 pmpaddr_32
  wire [63:0] regout_pmpaddr_32 = pmpaddr_32_regOut_ALL;
  // 0x3D1 pmpaddr_33
  wire [63:0] regout_pmpaddr_33 = pmpaddr_33_regOut_ALL;
  // 0x3D2 pmpaddr_34
  wire [63:0] regout_pmpaddr_34 = pmpaddr_34_regOut_ALL;
  // 0x3D3 pmpaddr_35
  wire [63:0] regout_pmpaddr_35 = pmpaddr_35_regOut_ALL;
  // 0x3D4 pmpaddr_36
  wire [63:0] regout_pmpaddr_36 = pmpaddr_36_regOut_ALL;
  // 0x3D5 pmpaddr_37
  wire [63:0] regout_pmpaddr_37 = pmpaddr_37_regOut_ALL;
  // 0x3D6 pmpaddr_38
  wire [63:0] regout_pmpaddr_38 = pmpaddr_38_regOut_ALL;
  // 0x3D7 pmpaddr_39
  wire [63:0] regout_pmpaddr_39 = pmpaddr_39_regOut_ALL;
  // 0x3D8 pmpaddr_40
  wire [63:0] regout_pmpaddr_40 = pmpaddr_40_regOut_ALL;
  // 0x3D9 pmpaddr_41
  wire [63:0] regout_pmpaddr_41 = pmpaddr_41_regOut_ALL;
  // 0x3DA pmpaddr_42
  wire [63:0] regout_pmpaddr_42 = pmpaddr_42_regOut_ALL;
  // 0x3DB pmpaddr_43
  wire [63:0] regout_pmpaddr_43 = pmpaddr_43_regOut_ALL;
  // 0x3DC pmpaddr_44
  wire [63:0] regout_pmpaddr_44 = pmpaddr_44_regOut_ALL;
  // 0x3DD pmpaddr_45
  wire [63:0] regout_pmpaddr_45 = pmpaddr_45_regOut_ALL;
  // 0x3DE pmpaddr_46
  wire [63:0] regout_pmpaddr_46 = pmpaddr_46_regOut_ALL;
  // 0x3DF pmpaddr_47
  wire [63:0] regout_pmpaddr_47 = pmpaddr_47_regOut_ALL;
  // 0x3E0 pmpaddr_48
  wire [63:0] regout_pmpaddr_48 = pmpaddr_48_regOut_ALL;
  // 0x3E1 pmpaddr_49
  wire [63:0] regout_pmpaddr_49 = pmpaddr_49_regOut_ALL;
  // 0x3E2 pmpaddr_50
  wire [63:0] regout_pmpaddr_50 = pmpaddr_50_regOut_ALL;
  // 0x3E3 pmpaddr_51
  wire [63:0] regout_pmpaddr_51 = pmpaddr_51_regOut_ALL;
  // 0x3E4 pmpaddr_52
  wire [63:0] regout_pmpaddr_52 = pmpaddr_52_regOut_ALL;
  // 0x3E5 pmpaddr_53
  wire [63:0] regout_pmpaddr_53 = pmpaddr_53_regOut_ALL;
  // 0x3E6 pmpaddr_54
  wire [63:0] regout_pmpaddr_54 = pmpaddr_54_regOut_ALL;
  // 0x3E7 pmpaddr_55
  wire [63:0] regout_pmpaddr_55 = pmpaddr_55_regOut_ALL;
  // 0x3E8 pmpaddr_56
  wire [63:0] regout_pmpaddr_56 = pmpaddr_56_regOut_ALL;
  // 0x3E9 pmpaddr_57
  wire [63:0] regout_pmpaddr_57 = pmpaddr_57_regOut_ALL;
  // 0x3EA pmpaddr_58
  wire [63:0] regout_pmpaddr_58 = pmpaddr_58_regOut_ALL;
  // 0x3EB pmpaddr_59
  wire [63:0] regout_pmpaddr_59 = pmpaddr_59_regOut_ALL;
  // 0x3EC pmpaddr_60
  wire [63:0] regout_pmpaddr_60 = pmpaddr_60_regOut_ALL;
  // 0x3ED pmpaddr_61
  wire [63:0] regout_pmpaddr_61 = pmpaddr_61_regOut_ALL;
  // 0x3EE pmpaddr_62
  wire [63:0] regout_pmpaddr_62 = pmpaddr_62_regOut_ALL;
  // 0x3EF pmpaddr_63
  wire [63:0] regout_pmpaddr_63 = pmpaddr_63_regOut_ALL;
  // 0x5A8 scontext
  wire [63:0] regout_scontext = {
    32'h0,
    scontext_regOut_ALL
  };
  // 0x5C0 sbpctl
  wire [63:0] regout_sbpctl = {
    57'h0,
    sbpctl_regOut_LOOP_ENABLE,
    sbpctl_regOut_RAS_ENABLE,
    sbpctl_regOut_SC_ENABLE,
    sbpctl_regOut_TAGE_ENABLE,
    sbpctl_regOut_BIM_ENABLE,
    sbpctl_regOut_BTB_ENABLE,
    sbpctl_regOut_UBTB_ENABLE
  };
  // 0x5C1 spfctl
  wire [63:0] regout_spfctl = {
    32'h0,
    spfctl_regOut_L2_PF_DELAY_LATENCY,
    spfctl_regOut_L2_PF_TP_ENABLE,
    spfctl_regOut_L2_PF_VBOP_ENABLE,
    spfctl_regOut_L2_PF_PBOP_ENABLE,
    spfctl_regOut_L2_PF_RECV_ENABLE,
    spfctl_regOut_L2_PF_STORE_ONLY,
    spfctl_regOut_L1D_PF_ENABLE_STRIDE,
    spfctl_regOut_L1D_PF_ACTIVE_STRIDE,
    spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD,
    spfctl_regOut_L1D_PF_ENABLE_PHT,
    spfctl_regOut_L1D_PF_ENABLE_AGT,
    spfctl_regOut_L1D_PF_TRAIN_ON_HIT,
    spfctl_regOut_L1D_PF_ENABLE,
    spfctl_regOut_L2_PF_ENABLE,
    spfctl_regOut_L1I_PF_ENABLE
  };
  // 0x5C2 slvpredctl
  wire [63:0] regout_slvpredctl = {
    55'h0,
    slvpredctl_regOut_LVPRED_TIMEOUT,
    slvpredctl_regOut_STORESET_NO_FAST_WAKEUP,
    slvpredctl_regOut_STORESET_WAIT_STORE,
    slvpredctl_regOut_NO_SPEC_LOAD,
    slvpredctl_regOut_LVPRED_DISABLE
  };
  // 0x5C3 smblockctl
  wire [63:0] regout_smblockctl = {
    32'h0,
    smblockctl_regOut_SBUFFER_TIMEOUT,
    smblockctl_regOut_HD_MISALIGN_LD_ENABLE,
    smblockctl_regOut_HD_MISALIGN_ST_ENABLE,
    smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE,
    smblockctl_regOut_CACHE_ERROR_ENABLE,
    smblockctl_regOut_SOFT_PREFETCH_ENABLE,
    smblockctl_regOut_LDLD_VIO_CHECK_ENABLE,
    smblockctl_regOut_SBUFFER_THRESHOLD
  };
  // 0x5C4 srnctl
  wire [63:0] regout_srnctl = {
    61'h0,
    srnctl_regOut_WFI_ENABLE,
    1'h0,
    srnctl_regOut_FUSION_ENABLE
  };
  // 0x600 hstatus
  wire [63:0] regout_hstatus = {
    14'h0,
    hstatus_regOut_HUPMM,
    25'h400,
    hstatus_regOut_VTSR,
    hstatus_regOut_VTW,
    hstatus_regOut_VTVM,
    2'h0,
    hstatus_regOut_VGEIN,
    2'h0,
    hstatus_regOut_HU,
    hstatus_regOut_SPVP,
    hstatus_regOut_SPV,
    hstatus_regOut_GVA,
    6'h0
  };
  // 0x602 hedeleg
  wire [63:0] regout_hedeleg = {
    44'h0,
    hedeleg_regOut_EX_HWE,
    hedeleg_regOut_EX_SWC,
    2'h0,
    hedeleg_regOut_EX_SPF,
    1'h0,
    hedeleg_regOut_EX_LPF,
    hedeleg_regOut_EX_IPF,
    3'h0,
    hedeleg_regOut_EX_UCALL,
    hedeleg_regOut_EX_SAF,
    hedeleg_regOut_EX_SAM,
    hedeleg_regOut_EX_LAF,
    hedeleg_regOut_EX_LAM,
    hedeleg_regOut_EX_BP,
    hedeleg_regOut_EX_II,
    hedeleg_regOut_EX_IAF,
    hedeleg_regOut_EX_IAM
  };
  // 0x603 hideleg
  wire [63:0] regout_hideleg = {
    50'h0,
    hideleg_regOut_LCOFI,
    hideleg_regOut_SGEI,
    hideleg_regOut_MEI,
    hideleg_regOut_VSEI,
    hideleg_regOut_SEI,
    1'h0,
    hideleg_regOut_MTI,
    hideleg_regOut_VSTI,
    hideleg_regOut_STI,
    1'h0,
    hideleg_regOut_MSI,
    hideleg_regOut_VSSI,
    hideleg_regOut_SSI,
    1'h0
  };
  // 0x604 hie
  wire [63:0] regout_hie = {
    51'h0,
    hie_regOut_SGEIE,
    1'h0,
    hie_regOut_VSEIE,
    3'h0,
    hie_regOut_VSTIE,
    3'h0,
    hie_regOut_VSSIE,
    2'h0
  };
  // 0x605 htimedelta
  wire [63:0] regout_htimedelta = htimedelta_regOut_ALL;
  // 0x606 hcounteren
  wire [63:0] regout_hcounteren = {
    32'h0,
    hcounteren_regOut_HPM,
    hcounteren_regOut_IR,
    hcounteren_regOut_TM,
    hcounteren_regOut_CY
  };
  // 0x607 hgeie
  wire [63:0] regout_hgeie = {
    56'h0,
    hgeie_regOut_ie,
    1'h0
  };
  // 0x608 hvien
  wire [63:0] regout_hvien = {
    hvien_regOut_LC63IE,
    hvien_regOut_LC62IE,
    hvien_regOut_LC61IE,
    hvien_regOut_LC60IE,
    hvien_regOut_LC59IE,
    hvien_regOut_LC58IE,
    hvien_regOut_LC57IE,
    hvien_regOut_LC56IE,
    hvien_regOut_LC55IE,
    hvien_regOut_LC54IE,
    hvien_regOut_LC53IE,
    hvien_regOut_LC52IE,
    hvien_regOut_LC51IE,
    hvien_regOut_LC50IE,
    hvien_regOut_LC49IE,
    hvien_regOut_LC48IE,
    hvien_regOut_LC47IE,
    hvien_regOut_LC46IE,
    hvien_regOut_LC45IE,
    hvien_regOut_LC44IE,
    hvien_regOut_HPRASEIE,
    hvien_regOut_LC42IE,
    hvien_regOut_LC41IE,
    hvien_regOut_LC40IE,
    hvien_regOut_LC39IE,
    hvien_regOut_LC38IE,
    hvien_regOut_LC37IE,
    hvien_regOut_LC36IE,
    hvien_regOut_LPRASEIE,
    hvien_regOut_LC34IE,
    hvien_regOut_LC33IE,
    hvien_regOut_LC32IE,
    hvien_regOut_LC31IE,
    hvien_regOut_LC30IE,
    hvien_regOut_LC29IE,
    hvien_regOut_LC28IE,
    hvien_regOut_LC27IE,
    hvien_regOut_LC26IE,
    hvien_regOut_LC25IE,
    hvien_regOut_LC24IE,
    hvien_regOut_LC23IE,
    hvien_regOut_LC22IE,
    hvien_regOut_LC21IE,
    hvien_regOut_LC20IE,
    hvien_regOut_LC19IE,
    hvien_regOut_LC18IE,
    hvien_regOut_LC17IE,
    hvien_regOut_LC16IE,
    hvien_regOut_LC15IE,
    hvien_regOut_LC14IE,
    14'h0
  };
  // 0x609 hvictl
  wire [63:0] regout_hvictl = {
    33'h0,
    hvictl_regOut_VTI,
    2'h0,
    hvictl_regOut_IID,
    6'h0,
    hvictl_regOut_DPR,
    hvictl_regOut_IPRIOM,
    hvictl_regOut_IPRIO
  };
  // 0x60A henvcfg
  wire [63:0] regout_henvcfg = {
    henvcfg_regOut_STCE,
    henvcfg_regOut_PBMTE,
    2'h0,
    henvcfg_regOut_DTE,
    25'h0,
    henvcfg_regOut_PMM,
    24'h0,
    henvcfg_regOut_CBZE,
    henvcfg_regOut_CBCFE,
    henvcfg_regOut_CBIE,
    4'h0
  };
  // 0x60C hstateen0
  wire [63:0] regout_hstateen0 = {
    hstateen0_regOut_SE0,
    hstateen0_regOut_ENVCFG,
    1'h0,
    hstateen0_regOut_CSRIND,
    hstateen0_regOut_AIA,
    hstateen0_regOut_IMSIC,
    hstateen0_regOut_CONTEXT,
    54'h0,
    hstateen0_regOut_JVT,
    hstateen0_regOut_FCSR,
    hstateen0_regOut_C
  };
  // 0x60D hstateen1
  wire [63:0] regout_hstateen1 = {
    hstateen1_regOut_SE,
    63'h0
  };
  // 0x60E hstateen2
  wire [63:0] regout_hstateen2 = {
    hstateen2_regOut_SE,
    63'h0
  };
  // 0x60F hstateen3
  wire [63:0] regout_hstateen3 = {
    hstateen3_regOut_SE,
    63'h0
  };
  // 0x643 htval
  wire [63:0] regout_htval = htval_regOut_ALL;
  // 0x644 hip
  wire [63:0] regout_hip = {
    51'h0,
    hip_regOut_SGEIP,
    1'h0,
    hip_regOut_VSEIP,
    3'h0,
    hip_regOut_VSTIP,
    3'h0,
    hip_regOut_VSSIP,
    2'h0
  };
  // 0x645 hvip
  wire [63:0] regout_hvip = {
    hvip_regOut_LC63IP,
    hvip_regOut_LC62IP,
    hvip_regOut_LC61IP,
    hvip_regOut_LC60IP,
    hvip_regOut_LC59IP,
    hvip_regOut_LC58IP,
    hvip_regOut_LC57IP,
    hvip_regOut_LC56IP,
    hvip_regOut_LC55IP,
    hvip_regOut_LC54IP,
    hvip_regOut_LC53IP,
    hvip_regOut_LC52IP,
    hvip_regOut_LC51IP,
    hvip_regOut_LC50IP,
    hvip_regOut_LC49IP,
    hvip_regOut_LC48IP,
    hvip_regOut_LC47IP,
    hvip_regOut_LC46IP,
    hvip_regOut_LC45IP,
    hvip_regOut_LC44IP,
    hvip_regOut_HPRASEIP,
    hvip_regOut_LC42IP,
    hvip_regOut_LC41IP,
    hvip_regOut_LC40IP,
    hvip_regOut_LC39IP,
    hvip_regOut_LC38IP,
    hvip_regOut_LC37IP,
    hvip_regOut_LC36IP,
    hvip_regOut_LPRASEIP,
    hvip_regOut_LC34IP,
    hvip_regOut_LC33IP,
    hvip_regOut_LC32IP,
    hvip_regOut_LC31IP,
    hvip_regOut_LC30IP,
    hvip_regOut_LC29IP,
    hvip_regOut_LC28IP,
    hvip_regOut_LC27IP,
    hvip_regOut_LC26IP,
    hvip_regOut_LC25IP,
    hvip_regOut_LC24IP,
    hvip_regOut_LC23IP,
    hvip_regOut_LC22IP,
    hvip_regOut_LC21IP,
    hvip_regOut_LC20IP,
    hvip_regOut_LC19IP,
    hvip_regOut_LC18IP,
    hvip_regOut_LC17IP,
    hvip_regOut_LC16IP,
    hvip_regOut_LC15IP,
    hvip_regOut_LC14IP,
    hvip_regOut_LCOFIP,
    2'h0,
    hvip_regOut_VSEIP,
    3'h0,
    hvip_regOut_VSTIP,
    3'h0,
    hvip_regOut_VSSIP,
    2'h0
  };
  // 0x646 hviprio1
  wire [63:0] regout_hviprio1 = {
    hviprio1_regOut_Prio15,
    hviprio1_regOut_Prio14,
    hviprio1_regOut_PrioCOI,
    8'h0,
    hviprio1_regOut_PrioSTI,
    8'h0,
    hviprio1_regOut_PrioSSI,
    8'h0
  };
  // 0x647 hviprio2
  wire [63:0] regout_hviprio2 = hviprio2_regOut_ALL;
  // 0x64A htinst
  wire [63:0] regout_htinst = htinst_regOut_ALL;
  // 0x680 hgatp
  wire [63:0] regout_hgatp = {
    hgatp_regOut_MODE,
    2'h0,
    hgatp_regOut_VMID,
    hgatp_regOut_PPN
  };
  // 0x6A8 hcontext
  wire [63:0] regout_hcontext = {
    50'h0,
    hcontext_regOut_HCONTEXT
  };
  // 0x740 mnscratch
  wire [63:0] regout_mnscratch = mnscratch_regOut_ALL;
  // 0x741 mnepc
  wire [63:0] regout_mnepc = {
    mnepc_regOut_epc,
    1'h0
  };
  // 0x742 mncause
  wire [63:0] regout_mncause = {
    mncause_regOut_Interrupt,
    mncause_regOut_ExceptionCode
  };
  // 0x744 mnstatus
  wire [63:0] regout_mnstatus = {
    51'h0,
    mnstatus_regOut_MNPP,
    3'h0,
    mnstatus_regOut_MNPV,
    3'h0,
    mnstatus_regOut_NMIE,
    3'h0
  };
  // 0x747 mseccfg
  wire [63:0] regout_mseccfg = {
    30'h0,
    mseccfg_regOut_PMM,
    32'h0
  };
  // 0x7A0 tselect
  wire [63:0] regout_tselect = {
    62'h0,
    tselect_regOut_ALL
  };
  // 0x7A1 tdata1
  wire [63:0] regout_tdata1 = {
    tdata1_regOut_TYPE,
    tdata1_regOut_DMODE,
    tdata1_regOut_DATA
  };
  // 0x7A2 tdata2
  wire [63:0] regout_tdata2 = tdata2_regOut_ALL;
  // 0x7A4 tinfo
  wire [63:0] regout_tinfo = 64'h1000040;
  // 0x7A8 mcontext
  wire [63:0] regout_mcontext = {
    50'h0,
    mcontext_regOut_HCONTEXT
  };
  // 0x7B0 dcsr
  wire [63:0] regout_dcsr = {
    44'h400,
    dcsr_regOut_CETRIG,
    1'h0,
    dcsr_regOut_EBREAKVS,
    dcsr_regOut_EBREAKVU,
    dcsr_regOut_EBREAKM,
    1'h0,
    dcsr_regOut_EBREAKS,
    dcsr_regOut_EBREAKU,
    dcsr_regOut_STEPIE,
    dcsr_regOut_STOPCOUNT,
    dcsr_regOut_STOPTIME,
    dcsr_regOut_CAUSE,
    dcsr_regOut_V,
    dcsr_regOut_MPRVEN,
    dcsr_regOut_NMIP,
    dcsr_regOut_STEP,
    dcsr_regOut_PRV
  };
  // 0x7B1 dpc
  wire [63:0] regout_dpc = {
    dpc_regOut_epc,
    1'h0
  };
  // 0x7B2 dscratch0
  wire [63:0] regout_dscratch0 = dscratch0_regOut_ALL;
  // 0x7B3 dscratch1
  wire [63:0] regout_dscratch1 = dscratch1_regOut_ALL;
  // 0x7C0 pmacfg_0
  wire [63:0] regout_pmacfg_0 = pmacfg_0_regOut_ALL;
  // 0x7C2 pmacfg_1
  wire [63:0] regout_pmacfg_1 = pmacfg_1_regOut_ALL;
  // 0x7C4 pmacfg_2
  wire [63:0] regout_pmacfg_2 = pmacfg_2_regOut_ALL;
  // 0x7C6 pmacfg_3
  wire [63:0] regout_pmacfg_3 = pmacfg_3_regOut_ALL;
  // 0x7C8 pmaaddr_0
  wire [63:0] regout_pmaaddr_0 = pmaaddr_0_regOut_ALL;
  // 0x7C9 pmaaddr_1
  wire [63:0] regout_pmaaddr_1 = pmaaddr_1_regOut_ALL;
  // 0x7CA pmaaddr_2
  wire [63:0] regout_pmaaddr_2 = pmaaddr_2_regOut_ALL;
  // 0x7CB pmaaddr_3
  wire [63:0] regout_pmaaddr_3 = pmaaddr_3_regOut_ALL;
  // 0x7CC pmaaddr_4
  wire [63:0] regout_pmaaddr_4 = pmaaddr_4_regOut_ALL;
  // 0x7CD pmaaddr_5
  wire [63:0] regout_pmaaddr_5 = pmaaddr_5_regOut_ALL;
  // 0x7CE pmaaddr_6
  wire [63:0] regout_pmaaddr_6 = pmaaddr_6_regOut_ALL;
  // 0x7CF pmaaddr_7
  wire [63:0] regout_pmaaddr_7 = pmaaddr_7_regOut_ALL;
  // 0x7D0 pmaaddr_8
  wire [63:0] regout_pmaaddr_8 = pmaaddr_8_regOut_ALL;
  // 0x7D1 pmaaddr_9
  wire [63:0] regout_pmaaddr_9 = pmaaddr_9_regOut_ALL;
  // 0x7D2 pmaaddr_10
  wire [63:0] regout_pmaaddr_10 = pmaaddr_10_regOut_ALL;
  // 0x7D3 pmaaddr_11
  wire [63:0] regout_pmaaddr_11 = pmaaddr_11_regOut_ALL;
  // 0x7D4 pmaaddr_12
  wire [63:0] regout_pmaaddr_12 = pmaaddr_12_regOut_ALL;
  // 0x7D5 pmaaddr_13
  wire [63:0] regout_pmaaddr_13 = pmaaddr_13_regOut_ALL;
  // 0x7D6 pmaaddr_14
  wire [63:0] regout_pmaaddr_14 = pmaaddr_14_regOut_ALL;
  // 0x7D7 pmaaddr_15
  wire [63:0] regout_pmaaddr_15 = pmaaddr_15_regOut_ALL;
  // 0x7D8 pmaaddr_16
  wire [63:0] regout_pmaaddr_16 = pmaaddr_16_regOut_ALL;
  // 0x7D9 pmaaddr_17
  wire [63:0] regout_pmaaddr_17 = pmaaddr_17_regOut_ALL;
  // 0x7DA pmaaddr_18
  wire [63:0] regout_pmaaddr_18 = pmaaddr_18_regOut_ALL;
  // 0x7DB pmaaddr_19
  wire [63:0] regout_pmaaddr_19 = pmaaddr_19_regOut_ALL;
  // 0x7DC pmaaddr_20
  wire [63:0] regout_pmaaddr_20 = pmaaddr_20_regOut_ALL;
  // 0x7DD pmaaddr_21
  wire [63:0] regout_pmaaddr_21 = pmaaddr_21_regOut_ALL;
  // 0x7DE pmaaddr_22
  wire [63:0] regout_pmaaddr_22 = pmaaddr_22_regOut_ALL;
  // 0x7DF pmaaddr_23
  wire [63:0] regout_pmaaddr_23 = pmaaddr_23_regOut_ALL;
  // 0x7E0 pmaaddr_24
  wire [63:0] regout_pmaaddr_24 = pmaaddr_24_regOut_ALL;
  // 0x7E1 pmaaddr_25
  wire [63:0] regout_pmaaddr_25 = pmaaddr_25_regOut_ALL;
  // 0x7E2 pmaaddr_26
  wire [63:0] regout_pmaaddr_26 = pmaaddr_26_regOut_ALL;
  // 0x7E3 pmaaddr_27
  wire [63:0] regout_pmaaddr_27 = pmaaddr_27_regOut_ALL;
  // 0x7E4 pmaaddr_28
  wire [63:0] regout_pmaaddr_28 = pmaaddr_28_regOut_ALL;
  // 0x7E5 pmaaddr_29
  wire [63:0] regout_pmaaddr_29 = pmaaddr_29_regOut_ALL;
  // 0x7E6 pmaaddr_30
  wire [63:0] regout_pmaaddr_30 = pmaaddr_30_regOut_ALL;
  // 0x7E7 pmaaddr_31
  wire [63:0] regout_pmaaddr_31 = pmaaddr_31_regOut_ALL;
  // 0xB00 mcycle
  wire [63:0] regout_mcycle = mcycle_regOut_ALL;
  // 0xB02 minstret
  wire [63:0] regout_minstret = minstret_regOut_ALL;
  // 0xB03 mhpmcounters_0
  wire [63:0] regout_mhpmcounters_0 = mhpmcounters_0_regOut_ALL;
  // 0xB04 mhpmcounters_1
  wire [63:0] regout_mhpmcounters_1 = mhpmcounters_1_regOut_ALL;
  // 0xB05 mhpmcounters_2
  wire [63:0] regout_mhpmcounters_2 = mhpmcounters_2_regOut_ALL;
  // 0xB06 mhpmcounters_3
  wire [63:0] regout_mhpmcounters_3 = mhpmcounters_3_regOut_ALL;
  // 0xB07 mhpmcounters_4
  wire [63:0] regout_mhpmcounters_4 = mhpmcounters_4_regOut_ALL;
  // 0xB08 mhpmcounters_5
  wire [63:0] regout_mhpmcounters_5 = mhpmcounters_5_regOut_ALL;
  // 0xB09 mhpmcounters_6
  wire [63:0] regout_mhpmcounters_6 = mhpmcounters_6_regOut_ALL;
  // 0xB0A mhpmcounters_7
  wire [63:0] regout_mhpmcounters_7 = mhpmcounters_7_regOut_ALL;
  // 0xB0B mhpmcounters_8
  wire [63:0] regout_mhpmcounters_8 = mhpmcounters_8_regOut_ALL;
  // 0xB0C mhpmcounters_9
  wire [63:0] regout_mhpmcounters_9 = mhpmcounters_9_regOut_ALL;
  // 0xB0D mhpmcounters_10
  wire [63:0] regout_mhpmcounters_10 = mhpmcounters_10_regOut_ALL;
  // 0xB0E mhpmcounters_11
  wire [63:0] regout_mhpmcounters_11 = mhpmcounters_11_regOut_ALL;
  // 0xB0F mhpmcounters_12
  wire [63:0] regout_mhpmcounters_12 = mhpmcounters_12_regOut_ALL;
  // 0xB10 mhpmcounters_13
  wire [63:0] regout_mhpmcounters_13 = mhpmcounters_13_regOut_ALL;
  // 0xB11 mhpmcounters_14
  wire [63:0] regout_mhpmcounters_14 = mhpmcounters_14_regOut_ALL;
  // 0xB12 mhpmcounters_15
  wire [63:0] regout_mhpmcounters_15 = mhpmcounters_15_regOut_ALL;
  // 0xB13 mhpmcounters_16
  wire [63:0] regout_mhpmcounters_16 = mhpmcounters_16_regOut_ALL;
  // 0xB14 mhpmcounters_17
  wire [63:0] regout_mhpmcounters_17 = mhpmcounters_17_regOut_ALL;
  // 0xB15 mhpmcounters_18
  wire [63:0] regout_mhpmcounters_18 = mhpmcounters_18_regOut_ALL;
  // 0xB16 mhpmcounters_19
  wire [63:0] regout_mhpmcounters_19 = mhpmcounters_19_regOut_ALL;
  // 0xB17 mhpmcounters_20
  wire [63:0] regout_mhpmcounters_20 = mhpmcounters_20_regOut_ALL;
  // 0xB18 mhpmcounters_21
  wire [63:0] regout_mhpmcounters_21 = mhpmcounters_21_regOut_ALL;
  // 0xB19 mhpmcounters_22
  wire [63:0] regout_mhpmcounters_22 = mhpmcounters_22_regOut_ALL;
  // 0xB1A mhpmcounters_23
  wire [63:0] regout_mhpmcounters_23 = mhpmcounters_23_regOut_ALL;
  // 0xB1B mhpmcounters_24
  wire [63:0] regout_mhpmcounters_24 = mhpmcounters_24_regOut_ALL;
  // 0xB1C mhpmcounters_25
  wire [63:0] regout_mhpmcounters_25 = mhpmcounters_25_regOut_ALL;
  // 0xB1D mhpmcounters_26
  wire [63:0] regout_mhpmcounters_26 = mhpmcounters_26_regOut_ALL;
  // 0xB1E mhpmcounters_27
  wire [63:0] regout_mhpmcounters_27 = mhpmcounters_27_regOut_ALL;
  // 0xB1F mhpmcounters_28
  wire [63:0] regout_mhpmcounters_28 = mhpmcounters_28_regOut_ALL;
  // 0xBC0 mcorepwr
  wire [63:0] regout_mcorepwr = {
    62'h0,
    mcorepwr_regOut_COMMIT_STUCK_CHECK_ENABLE,
    mcorepwr_regOut_POWER_DOWN_ENABLE
  };
  // 0xBC1 mflushpwr
  wire [63:0] regout_mflushpwr = {
    62'h0,
    mflushpwr_regOut_L2_FLUSH_DONE,
    mflushpwr_regOut_FLUSH_L2_ENABLE
  };
  // 0xBC2 mbmc
  wire [63:0] regout_mbmc = {
    mbmc_regOut_BMA,
    2'h0,
    mbmc_regOut_KEYIDEN,
    mbmc_regOut_BME,
    mbmc_regOut_BCLEAR,
    mbmc_regOut_CMODE
  };
// END GENERATED(newcsr-regout)

  // ==========================================================================
  // 0. 请求别名
  // ==========================================================================
  wire        wen   = io_in_bits_wen & io_in_valid;
  wire        ren   = io_in_bits_ren & io_in_valid;
  wire [11:0] addr  = io_in_bits_addr;
  wire [63:0] wdata = io_in_bits_wdata;

  // ==========================================================================
  // 1. 特权态 / 调试态
  //    PRVM、V 只在 trap 进入与 xRET 时改变；多个事件同拍时按 Scala MuxCase 的顺序取第一个：
  //    进 debug > 进 M > 进 HS > 进 VS > 进 MN > mret > sret > dret > mnret。
  // ==========================================================================
  logic [1:0] prvm;
  logic       virt;
  logic       debug_mode;
  logic       debug_intr_enable;    // 调试中断只在 debugIntrEnable 时处理

  wire mode_m  = prvm == 2'h3;
  wire mode_hs = ~virt & prvm == 2'h1;
  wire mode_hu = ~virt & prvm == 2'h0;
  wire mode_vs =  virt & prvm == 2'h1;
  wire mode_vu =  virt & prvm == 2'h0;

  wire debug_intr = platformIRP_debugIP & debug_intr_enable;

  // 下一拍的特权态（next_virt 还直接送给 time 模块）
  logic [1:0] next_prvm;
  logic       next_virt;
  always_comb begin
    next_prvm = prvm;
    next_virt = virt;
    if (trapEntryDEvent_out_privState_valid) begin
      next_prvm = trapEntryDEvent_out_privState_bits_PRVM;
      next_virt = trapEntryDEvent_out_privState_bits_V;
    end
    else if (trapEntryMEvent_out_privState_valid) begin
      next_prvm = trapEntryMEvent_out_privState_bits_PRVM;
      next_virt = trapEntryMEvent_out_privState_bits_V;
    end
    else if (trapEntryHSEvent_out_privState_valid) begin
      next_prvm = trapEntryHSEvent_out_privState_bits_PRVM;
      next_virt = trapEntryHSEvent_out_privState_bits_V;
    end
    else if (trapEntryVSEvent_out_privState_valid) begin
      next_prvm = trapEntryVSEvent_out_privState_bits_PRVM;
      next_virt = trapEntryVSEvent_out_privState_bits_V;
    end
    else if (trapEntryMNEvent_out_privState_valid) begin
      next_prvm = trapEntryMNEvent_out_privState_bits_PRVM;
      next_virt = trapEntryMNEvent_out_privState_bits_V;
    end
    else if (mretEvent_out_privState_valid) begin
      next_prvm = mretEvent_out_privState_bits_PRVM;
      next_virt = mretEvent_out_privState_bits_V;
    end
    else if (sretEvent_out_privState_valid) begin
      next_prvm = sretEvent_out_privState_bits_PRVM;
      next_virt = sretEvent_out_privState_bits_V;
    end
    else if (dretEvent_out_privState_valid) begin
      next_prvm = dretEvent_out_privState_bits_PRVM;
      next_virt = dretEvent_out_privState_bits_V;
    end
    else if (mnretEvent_out_privState_valid) begin
      next_prvm = mnretEvent_out_privState_bits_PRVM;
      next_virt = mnretEvent_out_privState_bits_V;
    end
  end

  // debug 模式：dret 退出优先于 trap 进入
  logic next_debug_mode;
  logic next_debug_intr_enable;
  always_comb begin
    next_debug_mode = debug_mode;
    if (dretEvent_out_debugMode_valid)
      next_debug_mode = dretEvent_out_debugMode_bits;
    else if (trapEntryDEvent_out_debugMode_valid)
      next_debug_mode = trapEntryDEvent_out_debugMode_bits;
    next_debug_intr_enable = debug_intr_enable;
    if (dretEvent_out_debugIntrEnable_valid)
      next_debug_intr_enable = dretEvent_out_debugIntrEnable_bits;
    else if (trapEntryDEvent_out_debugIntrEnable_valid)
      next_debug_intr_enable = trapEntryDEvent_out_debugIntrEnable_bits;
  end

  // 进入 debug 模式（Debug 模块判定有 debug trap 且当前不在 debug 模式）
  wire entry_debug_mode = debugMod_io_out_hasDebugTrap & ~debug_mode;

  // dcsr.STOPCOUNT / STOPTIME：debug 模式下停计数器 / 停 time
  wire  debug_stop_count_next = debug_mode & dcsr_regOut_STOPCOUNT;
  wire  debug_stop_time       = debug_mode & dcsr_regOut_STOPTIME;
  logic debug_stop_count_q;
  // 刚进入"停计数"的那一拍，非特权计数器（cycle/instret/hpmcounter）要同步一次
  wire  unpriv_count_update   = ~debug_stop_count_q & debug_stop_count_next;

  // critical error：一旦置位保持到复位。CSR 内部来源 = mnstatus.NMIE=0 时又来 trap（双重 trap 进 MN）
  logic critical_error_state;
  wire  critical_error_in_csr = ~mnstatus_regOut_NMIE & io_fromRob_trap_valid
                              & ~(entry_debug_mode | debug_mode);
  // dret 时记下"是否因 critical error 进的 debug"，用于保持 dpc 不被改写
  logic hold_dpc;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      prvm                 <= 2'h3;      // 复位在 M 态
      virt                 <= 1'b0;
      debug_mode           <= 1'b0;
      debug_intr_enable    <= 1'b1;
      critical_error_state <= 1'b0;
      hold_dpc             <= 1'b0;
    end
    else begin
      prvm                 <= next_prvm;
      virt                 <= next_virt;
      debug_mode           <= next_debug_mode;
      debug_intr_enable    <= next_debug_intr_enable;
      critical_error_state <= io_fromTop_criticalErrorState | critical_error_in_csr
                            | critical_error_state;
      if (permitMod_io_out_hasLegalDret)
        hold_dpc <= critical_error_state & dcsr_regOut_CETRIG;
    end
  end

  always @(posedge clock)
    debug_stop_count_q <= debug_stop_count_next;

  // ==========================================================================
  // 2. CSR 地址命中 hit_<csr>（读选择用；写使能 = wen_legal_q & hit_<csr>）
  //    三类：普通 CSR 地址相等即命中；
  //          S 级 CSR（sstatus/sie/stvec/sscratch/sepc/scause/stval/sip/stimecmp/siselect/
  //          sireg/stopei/stopi/satp）在 VS 态被重定向到 vs* 版本，所以只在非 VS 态命中；
  //          VS 级 CSR 在 VS 态用 S 级地址访问，其余态用自己的地址。
  // ==========================================================================
  wire hit_fflags          = addr == 12'h001;
  wire hit_frm             = addr == 12'h002;
  wire hit_fcsr            = addr == 12'h003;
  wire hit_vstart          = addr == 12'h008;
  wire hit_vxsat           = addr == 12'h009;
  wire hit_vxrm            = addr == 12'h00A;
  wire hit_vcsr            = addr == 12'h00F;
  wire hit_sstatus         = ~mode_vs & addr == 12'h100;
  wire hit_sie             = ~mode_vs & addr == 12'h104;
  wire hit_stvec           = ~mode_vs & addr == 12'h105;
  wire hit_scounteren      = addr == 12'h106;
  wire hit_senvcfg         = addr == 12'h10A;
  wire hit_sstateen0       = addr == 12'h10C;
  wire hit_sstateen1       = addr == 12'h10D;
  wire hit_sstateen2       = addr == 12'h10E;
  wire hit_sstateen3       = addr == 12'h10F;
  wire hit_sscratch        = ~mode_vs & addr == 12'h140;
  wire hit_sepc            = ~mode_vs & addr == 12'h141;
  wire hit_scause          = ~mode_vs & addr == 12'h142;
  wire hit_stval           = ~mode_vs & addr == 12'h143;
  wire hit_sip             = ~mode_vs & addr == 12'h144;
  wire hit_stimecmp        = ~mode_vs & addr == 12'h14D;
  wire hit_siselect        = ~mode_vs & addr == 12'h150;
  wire hit_sireg           = ~mode_vs & addr == 12'h151;
  wire hit_stopei          = ~mode_vs & addr == 12'h15C;
  wire hit_satp            = ~mode_vs & addr == 12'h180;
  wire hit_vsstatus        = mode_vs & addr == 12'h100 | ~mode_vs & addr == 12'h200;
  wire hit_vsie            = mode_vs & addr == 12'h104 | ~mode_vs & addr == 12'h204;
  wire hit_vstvec          = mode_vs & addr == 12'h105 | ~mode_vs & addr == 12'h205;
  wire hit_vsscratch       = mode_vs & addr == 12'h140 | ~mode_vs & addr == 12'h240;
  wire hit_vsepc           = mode_vs & addr == 12'h141 | ~mode_vs & addr == 12'h241;
  wire hit_vscause         = mode_vs & addr == 12'h142 | ~mode_vs & addr == 12'h242;
  wire hit_vstval          = mode_vs & addr == 12'h143 | ~mode_vs & addr == 12'h243;
  wire hit_vsip            = mode_vs & addr == 12'h144 | ~mode_vs & addr == 12'h244;
  wire hit_vstimecmp       = mode_vs & addr == 12'h14D | ~mode_vs & addr == 12'h24D;
  wire hit_vsiselect       = mode_vs & addr == 12'h150 | ~mode_vs & addr == 12'h250;
  wire hit_vsireg          = mode_vs & addr == 12'h151 | ~mode_vs & addr == 12'h251;
  wire hit_vstopei         = mode_vs & addr == 12'h15C | ~mode_vs & addr == 12'h25C;
  wire hit_vsatp           = mode_vs & addr == 12'h180 | ~mode_vs & addr == 12'h280;
  wire hit_mstatus         = addr == 12'h300;
  wire hit_misa            = addr == 12'h301;
  wire hit_medeleg         = addr == 12'h302;
  wire hit_mideleg         = addr == 12'h303;
  wire hit_mie             = addr == 12'h304;
  wire hit_mtvec           = addr == 12'h305;
  wire hit_mcounteren      = addr == 12'h306;
  wire hit_mvien           = addr == 12'h308;
  wire hit_mvip            = addr == 12'h309;
  wire hit_menvcfg         = addr == 12'h30A;
  wire hit_mstateen0       = addr == 12'h30C;
  wire hit_mstateen1       = addr == 12'h30D;
  wire hit_mstateen2       = addr == 12'h30E;
  wire hit_mstateen3       = addr == 12'h30F;
  wire hit_mcountinhibit   = addr == 12'h320;
  wire hit_Mhpmevent3      = addr == 12'h323;
  wire hit_Mhpmevent4      = addr == 12'h324;
  wire hit_Mhpmevent5      = addr == 12'h325;
  wire hit_Mhpmevent6      = addr == 12'h326;
  wire hit_Mhpmevent7      = addr == 12'h327;
  wire hit_Mhpmevent8      = addr == 12'h328;
  wire hit_Mhpmevent9      = addr == 12'h329;
  wire hit_Mhpmevent10     = addr == 12'h32A;
  wire hit_Mhpmevent11     = addr == 12'h32B;
  wire hit_Mhpmevent12     = addr == 12'h32C;
  wire hit_Mhpmevent13     = addr == 12'h32D;
  wire hit_Mhpmevent14     = addr == 12'h32E;
  wire hit_Mhpmevent15     = addr == 12'h32F;
  wire hit_Mhpmevent16     = addr == 12'h330;
  wire hit_Mhpmevent17     = addr == 12'h331;
  wire hit_Mhpmevent18     = addr == 12'h332;
  wire hit_Mhpmevent19     = addr == 12'h333;
  wire hit_Mhpmevent20     = addr == 12'h334;
  wire hit_Mhpmevent21     = addr == 12'h335;
  wire hit_Mhpmevent22     = addr == 12'h336;
  wire hit_Mhpmevent23     = addr == 12'h337;
  wire hit_Mhpmevent24     = addr == 12'h338;
  wire hit_Mhpmevent25     = addr == 12'h339;
  wire hit_Mhpmevent26     = addr == 12'h33A;
  wire hit_Mhpmevent27     = addr == 12'h33B;
  wire hit_Mhpmevent28     = addr == 12'h33C;
  wire hit_Mhpmevent29     = addr == 12'h33D;
  wire hit_Mhpmevent30     = addr == 12'h33E;
  wire hit_Mhpmevent31     = addr == 12'h33F;
  wire hit_mscratch        = addr == 12'h340;
  wire hit_mepc            = addr == 12'h341;
  wire hit_mcause          = addr == 12'h342;
  wire hit_mtval           = addr == 12'h343;
  wire hit_mip             = addr == 12'h344;
  wire hit_mtinst          = addr == 12'h34A;
  wire hit_mtval2          = addr == 12'h34B;
  wire hit_miselect        = addr == 12'h350;
  wire hit_mireg           = addr == 12'h351;
  wire hit_mtopei          = addr == 12'h35C;
  wire hit_pmpcfg_0        = addr == 12'h3A0;
  wire hit_pmpcfg_1        = addr == 12'h3A2;
  wire hit_pmpcfg_2        = addr == 12'h3A4;
  wire hit_pmpcfg_3        = addr == 12'h3A6;
  wire hit_pmpcfg_4        = addr == 12'h3A8;
  wire hit_pmpcfg_5        = addr == 12'h3AA;
  wire hit_pmpcfg_6        = addr == 12'h3AC;
  wire hit_pmpcfg_7        = addr == 12'h3AE;
  wire hit_pmpaddr_0       = addr == 12'h3B0;
  wire hit_pmpaddr_1       = addr == 12'h3B1;
  wire hit_pmpaddr_2       = addr == 12'h3B2;
  wire hit_pmpaddr_3       = addr == 12'h3B3;
  wire hit_pmpaddr_4       = addr == 12'h3B4;
  wire hit_pmpaddr_5       = addr == 12'h3B5;
  wire hit_pmpaddr_6       = addr == 12'h3B6;
  wire hit_pmpaddr_7       = addr == 12'h3B7;
  wire hit_pmpaddr_8       = addr == 12'h3B8;
  wire hit_pmpaddr_9       = addr == 12'h3B9;
  wire hit_pmpaddr_10      = addr == 12'h3BA;
  wire hit_pmpaddr_11      = addr == 12'h3BB;
  wire hit_pmpaddr_12      = addr == 12'h3BC;
  wire hit_pmpaddr_13      = addr == 12'h3BD;
  wire hit_pmpaddr_14      = addr == 12'h3BE;
  wire hit_pmpaddr_15      = addr == 12'h3BF;
  wire hit_pmpaddr_16      = addr == 12'h3C0;
  wire hit_pmpaddr_17      = addr == 12'h3C1;
  wire hit_pmpaddr_18      = addr == 12'h3C2;
  wire hit_pmpaddr_19      = addr == 12'h3C3;
  wire hit_pmpaddr_20      = addr == 12'h3C4;
  wire hit_pmpaddr_21      = addr == 12'h3C5;
  wire hit_pmpaddr_22      = addr == 12'h3C6;
  wire hit_pmpaddr_23      = addr == 12'h3C7;
  wire hit_pmpaddr_24      = addr == 12'h3C8;
  wire hit_pmpaddr_25      = addr == 12'h3C9;
  wire hit_pmpaddr_26      = addr == 12'h3CA;
  wire hit_pmpaddr_27      = addr == 12'h3CB;
  wire hit_pmpaddr_28      = addr == 12'h3CC;
  wire hit_pmpaddr_29      = addr == 12'h3CD;
  wire hit_pmpaddr_30      = addr == 12'h3CE;
  wire hit_pmpaddr_31      = addr == 12'h3CF;
  wire hit_pmpaddr_32      = addr == 12'h3D0;
  wire hit_pmpaddr_33      = addr == 12'h3D1;
  wire hit_pmpaddr_34      = addr == 12'h3D2;
  wire hit_pmpaddr_35      = addr == 12'h3D3;
  wire hit_pmpaddr_36      = addr == 12'h3D4;
  wire hit_pmpaddr_37      = addr == 12'h3D5;
  wire hit_pmpaddr_38      = addr == 12'h3D6;
  wire hit_pmpaddr_39      = addr == 12'h3D7;
  wire hit_pmpaddr_40      = addr == 12'h3D8;
  wire hit_pmpaddr_41      = addr == 12'h3D9;
  wire hit_pmpaddr_42      = addr == 12'h3DA;
  wire hit_pmpaddr_43      = addr == 12'h3DB;
  wire hit_pmpaddr_44      = addr == 12'h3DC;
  wire hit_pmpaddr_45      = addr == 12'h3DD;
  wire hit_pmpaddr_46      = addr == 12'h3DE;
  wire hit_pmpaddr_47      = addr == 12'h3DF;
  wire hit_pmpaddr_48      = addr == 12'h3E0;
  wire hit_pmpaddr_49      = addr == 12'h3E1;
  wire hit_pmpaddr_50      = addr == 12'h3E2;
  wire hit_pmpaddr_51      = addr == 12'h3E3;
  wire hit_pmpaddr_52      = addr == 12'h3E4;
  wire hit_pmpaddr_53      = addr == 12'h3E5;
  wire hit_pmpaddr_54      = addr == 12'h3E6;
  wire hit_pmpaddr_55      = addr == 12'h3E7;
  wire hit_pmpaddr_56      = addr == 12'h3E8;
  wire hit_pmpaddr_57      = addr == 12'h3E9;
  wire hit_pmpaddr_58      = addr == 12'h3EA;
  wire hit_pmpaddr_59      = addr == 12'h3EB;
  wire hit_pmpaddr_60      = addr == 12'h3EC;
  wire hit_pmpaddr_61      = addr == 12'h3ED;
  wire hit_pmpaddr_62      = addr == 12'h3EE;
  wire hit_pmpaddr_63      = addr == 12'h3EF;
  wire hit_scontext        = addr == 12'h5A8;
  wire hit_sbpctl          = addr == 12'h5C0;
  wire hit_spfctl          = addr == 12'h5C1;
  wire hit_slvpredctl      = addr == 12'h5C2;
  wire hit_smblockctl      = addr == 12'h5C3;
  wire hit_srnctl          = addr == 12'h5C4;
  wire hit_hstatus         = addr == 12'h600;
  wire hit_hedeleg         = addr == 12'h602;
  wire hit_hideleg         = addr == 12'h603;
  wire hit_hie             = addr == 12'h604;
  wire hit_htimedelta      = addr == 12'h605;
  wire hit_hcounteren      = addr == 12'h606;
  wire hit_hgeie           = addr == 12'h607;
  wire hit_hvien           = addr == 12'h608;
  wire hit_hvictl          = addr == 12'h609;
  wire hit_henvcfg         = addr == 12'h60A;
  wire hit_hstateen0       = addr == 12'h60C;
  wire hit_hstateen1       = addr == 12'h60D;
  wire hit_hstateen2       = addr == 12'h60E;
  wire hit_hstateen3       = addr == 12'h60F;
  wire hit_htval           = addr == 12'h643;
  wire hit_hip             = addr == 12'h644;
  wire hit_hvip            = addr == 12'h645;
  wire hit_hviprio1        = addr == 12'h646;
  wire hit_hviprio2        = addr == 12'h647;
  wire hit_htinst          = addr == 12'h64A;
  wire hit_hgatp           = addr == 12'h680;
  wire hit_hcontext        = addr == 12'h6A8;
  wire hit_mnscratch       = addr == 12'h740;
  wire hit_mnepc           = addr == 12'h741;
  wire hit_mncause         = addr == 12'h742;
  wire hit_mnstatus        = addr == 12'h744;
  wire hit_mseccfg         = addr == 12'h747;
  wire hit_tselect         = addr == 12'h7A0;
  wire hit_tdata1          = addr == 12'h7A1;
  wire hit_tdata2          = addr == 12'h7A2;
  wire hit_tinfo           = addr == 12'h7A4;
  wire hit_mcontext        = addr == 12'h7A8;
  wire hit_dcsr            = addr == 12'h7B0;
  wire hit_dpc             = addr == 12'h7B1;
  wire hit_dscratch0       = addr == 12'h7B2;
  wire hit_dscratch1       = addr == 12'h7B3;
  wire hit_pmacfg_0        = addr == 12'h7C0;
  wire hit_pmacfg_1        = addr == 12'h7C2;
  wire hit_pmacfg_2        = addr == 12'h7C4;
  wire hit_pmacfg_3        = addr == 12'h7C6;
  wire hit_pmaaddr_0       = addr == 12'h7C8;
  wire hit_pmaaddr_1       = addr == 12'h7C9;
  wire hit_pmaaddr_2       = addr == 12'h7CA;
  wire hit_pmaaddr_3       = addr == 12'h7CB;
  wire hit_pmaaddr_4       = addr == 12'h7CC;
  wire hit_pmaaddr_5       = addr == 12'h7CD;
  wire hit_pmaaddr_6       = addr == 12'h7CE;
  wire hit_pmaaddr_7       = addr == 12'h7CF;
  wire hit_pmaaddr_8       = addr == 12'h7D0;
  wire hit_pmaaddr_9       = addr == 12'h7D1;
  wire hit_pmaaddr_10      = addr == 12'h7D2;
  wire hit_pmaaddr_11      = addr == 12'h7D3;
  wire hit_pmaaddr_12      = addr == 12'h7D4;
  wire hit_pmaaddr_13      = addr == 12'h7D5;
  wire hit_pmaaddr_14      = addr == 12'h7D6;
  wire hit_pmaaddr_15      = addr == 12'h7D7;
  wire hit_pmaaddr_16      = addr == 12'h7D8;
  wire hit_pmaaddr_17      = addr == 12'h7D9;
  wire hit_pmaaddr_18      = addr == 12'h7DA;
  wire hit_pmaaddr_19      = addr == 12'h7DB;
  wire hit_pmaaddr_20      = addr == 12'h7DC;
  wire hit_pmaaddr_21      = addr == 12'h7DD;
  wire hit_pmaaddr_22      = addr == 12'h7DE;
  wire hit_pmaaddr_23      = addr == 12'h7DF;
  wire hit_pmaaddr_24      = addr == 12'h7E0;
  wire hit_pmaaddr_25      = addr == 12'h7E1;
  wire hit_pmaaddr_26      = addr == 12'h7E2;
  wire hit_pmaaddr_27      = addr == 12'h7E3;
  wire hit_pmaaddr_28      = addr == 12'h7E4;
  wire hit_pmaaddr_29      = addr == 12'h7E5;
  wire hit_pmaaddr_30      = addr == 12'h7E6;
  wire hit_pmaaddr_31      = addr == 12'h7E7;
  wire hit_mcycle          = addr == 12'hB00;
  wire hit_minstret        = addr == 12'hB02;
  wire hit_mhpmcounters_0  = addr == 12'hB03;
  wire hit_mhpmcounters_1  = addr == 12'hB04;
  wire hit_mhpmcounters_2  = addr == 12'hB05;
  wire hit_mhpmcounters_3  = addr == 12'hB06;
  wire hit_mhpmcounters_4  = addr == 12'hB07;
  wire hit_mhpmcounters_5  = addr == 12'hB08;
  wire hit_mhpmcounters_6  = addr == 12'hB09;
  wire hit_mhpmcounters_7  = addr == 12'hB0A;
  wire hit_mhpmcounters_8  = addr == 12'hB0B;
  wire hit_mhpmcounters_9  = addr == 12'hB0C;
  wire hit_mhpmcounters_10 = addr == 12'hB0D;
  wire hit_mhpmcounters_11 = addr == 12'hB0E;
  wire hit_mhpmcounters_12 = addr == 12'hB0F;
  wire hit_mhpmcounters_13 = addr == 12'hB10;
  wire hit_mhpmcounters_14 = addr == 12'hB11;
  wire hit_mhpmcounters_15 = addr == 12'hB12;
  wire hit_mhpmcounters_16 = addr == 12'hB13;
  wire hit_mhpmcounters_17 = addr == 12'hB14;
  wire hit_mhpmcounters_18 = addr == 12'hB15;
  wire hit_mhpmcounters_19 = addr == 12'hB16;
  wire hit_mhpmcounters_20 = addr == 12'hB17;
  wire hit_mhpmcounters_21 = addr == 12'hB18;
  wire hit_mhpmcounters_22 = addr == 12'hB19;
  wire hit_mhpmcounters_23 = addr == 12'hB1A;
  wire hit_mhpmcounters_24 = addr == 12'hB1B;
  wire hit_mhpmcounters_25 = addr == 12'hB1C;
  wire hit_mhpmcounters_26 = addr == 12'hB1D;
  wire hit_mhpmcounters_27 = addr == 12'hB1E;
  wire hit_mhpmcounters_28 = addr == 12'hB1F;
  wire hit_mcorepwr        = addr == 12'hBC0;
  wire hit_mflushpwr       = addr == 12'hBC1;
  wire hit_mbmc            = addr == 12'hBC2;
  wire hit_cycle           = addr == 12'hC00;
  wire hit_time            = addr == 12'hC01;
  wire hit_instret         = addr == 12'hC02;
  wire hit_hpmcounters_0   = addr == 12'hC03;
  wire hit_hpmcounters_1   = addr == 12'hC04;
  wire hit_hpmcounters_2   = addr == 12'hC05;
  wire hit_hpmcounters_3   = addr == 12'hC06;
  wire hit_hpmcounters_4   = addr == 12'hC07;
  wire hit_hpmcounters_5   = addr == 12'hC08;
  wire hit_hpmcounters_6   = addr == 12'hC09;
  wire hit_hpmcounters_7   = addr == 12'hC0A;
  wire hit_hpmcounters_8   = addr == 12'hC0B;
  wire hit_hpmcounters_9   = addr == 12'hC0C;
  wire hit_hpmcounters_10  = addr == 12'hC0D;
  wire hit_hpmcounters_11  = addr == 12'hC0E;
  wire hit_hpmcounters_12  = addr == 12'hC0F;
  wire hit_hpmcounters_13  = addr == 12'hC10;
  wire hit_hpmcounters_14  = addr == 12'hC11;
  wire hit_hpmcounters_15  = addr == 12'hC12;
  wire hit_hpmcounters_16  = addr == 12'hC13;
  wire hit_hpmcounters_17  = addr == 12'hC14;
  wire hit_hpmcounters_18  = addr == 12'hC15;
  wire hit_hpmcounters_19  = addr == 12'hC16;
  wire hit_hpmcounters_20  = addr == 12'hC17;
  wire hit_hpmcounters_21  = addr == 12'hC18;
  wire hit_hpmcounters_22  = addr == 12'hC19;
  wire hit_hpmcounters_23  = addr == 12'hC1A;
  wire hit_hpmcounters_24  = addr == 12'hC1B;
  wire hit_hpmcounters_25  = addr == 12'hC1C;
  wire hit_hpmcounters_26  = addr == 12'hC1D;
  wire hit_hpmcounters_27  = addr == 12'hC1E;
  wire hit_hpmcounters_28  = addr == 12'hC1F;
  wire hit_vtype           = addr == 12'hC21;
  wire hit_vlenb           = addr == 12'hC22;
  wire hit_scountovf       = addr == 12'hDA0;
  wire hit_stopi           = ~mode_vs & addr == 12'hDB0;
  wire hit_hgeip           = addr == 12'hE12;
  wire hit_vstopi          = mode_vs & addr == 12'hDB0 | ~mode_vs & addr == 12'hEB0;
  wire hit_mvendorid       = addr == 12'hF11;
  wire hit_marchid         = addr == 12'hF12;
  wire hit_mhartid         = addr == 12'hF14;
  wire hit_mconfigptr      = addr == 12'hF15;
  wire hit_mtopi           = addr == 12'hFB0;

  // ==========================================================================
  // 3. 写使能
  //    写合法性在请求那拍由 permitMod 判，打一拍后与当拍地址命中相与。
  // ==========================================================================
  logic wen_legal_q;
  always @(posedge clock or posedge reset) begin
    if (reset)
      wen_legal_q <= 1'b0;
    else
      wen_legal_q <= permitMod_io_out_hasLegalWen;
  end

  wire wen_fflags          = wen_legal_q & hit_fflags;
  wire wen_frm             = wen_legal_q & hit_frm;
  wire wen_fcsr            = wen_legal_q & hit_fcsr;
  wire wen_vstart          = wen_legal_q & hit_vstart;
  wire wen_vxsat           = wen_legal_q & hit_vxsat;
  wire wen_vxrm            = wen_legal_q & hit_vxrm;
  wire wen_vcsr            = wen_legal_q & hit_vcsr;
  wire wen_sstatus         = wen_legal_q & hit_sstatus;
  wire wen_sie             = wen_legal_q & hit_sie;
  wire wen_stvec           = wen_legal_q & hit_stvec;
  wire wen_scounteren      = wen_legal_q & hit_scounteren;
  wire wen_senvcfg         = wen_legal_q & hit_senvcfg;
  wire wen_sstateen0       = wen_legal_q & hit_sstateen0;
  wire wen_sscratch        = wen_legal_q & hit_sscratch;
  wire wen_sepc            = wen_legal_q & hit_sepc;
  wire wen_scause          = wen_legal_q & hit_scause;
  wire wen_stval           = wen_legal_q & hit_stval;
  wire wen_sip             = wen_legal_q & hit_sip;
  wire wen_stimecmp        = wen_legal_q & hit_stimecmp;
  wire wen_siselect        = wen_legal_q & hit_siselect;
  wire wen_sireg           = wen_legal_q & hit_sireg;
  wire wen_stopei          = wen_legal_q & hit_stopei;
  wire wen_satp            = wen_legal_q & hit_satp;
  wire wen_vsstatus        = wen_legal_q & hit_vsstatus;
  wire wen_vsie            = wen_legal_q & hit_vsie;
  wire wen_vstvec          = wen_legal_q & hit_vstvec;
  wire wen_vsscratch       = wen_legal_q & hit_vsscratch;
  wire wen_vsepc           = wen_legal_q & hit_vsepc;
  wire wen_vscause         = wen_legal_q & hit_vscause;
  wire wen_vstval          = wen_legal_q & hit_vstval;
  wire wen_vsip            = wen_legal_q & hit_vsip;
  wire wen_vstimecmp       = wen_legal_q & hit_vstimecmp;
  wire wen_vsiselect       = wen_legal_q & hit_vsiselect;
  wire wen_vsireg          = wen_legal_q & hit_vsireg;
  wire wen_vstopei         = wen_legal_q & hit_vstopei;
  wire wen_vsatp           = wen_legal_q & hit_vsatp;
  wire wen_mstatus         = wen_legal_q & hit_mstatus;
  wire wen_medeleg         = wen_legal_q & hit_medeleg;
  wire wen_mideleg         = wen_legal_q & hit_mideleg;
  wire wen_mie             = wen_legal_q & hit_mie;
  wire wen_mtvec           = wen_legal_q & hit_mtvec;
  wire wen_mcounteren      = wen_legal_q & hit_mcounteren;
  wire wen_mvien           = wen_legal_q & hit_mvien;
  wire wen_mvip            = wen_legal_q & hit_mvip;
  wire wen_menvcfg         = wen_legal_q & hit_menvcfg;
  wire wen_mstateen0       = wen_legal_q & hit_mstateen0;
  wire wen_mstateen1       = wen_legal_q & hit_mstateen1;
  wire wen_mstateen2       = wen_legal_q & hit_mstateen2;
  wire wen_mstateen3       = wen_legal_q & hit_mstateen3;
  wire wen_mcountinhibit   = wen_legal_q & hit_mcountinhibit;
  wire wen_Mhpmevent3      = wen_legal_q & hit_Mhpmevent3;
  wire wen_Mhpmevent4      = wen_legal_q & hit_Mhpmevent4;
  wire wen_Mhpmevent5      = wen_legal_q & hit_Mhpmevent5;
  wire wen_Mhpmevent6      = wen_legal_q & hit_Mhpmevent6;
  wire wen_Mhpmevent7      = wen_legal_q & hit_Mhpmevent7;
  wire wen_Mhpmevent8      = wen_legal_q & hit_Mhpmevent8;
  wire wen_Mhpmevent9      = wen_legal_q & hit_Mhpmevent9;
  wire wen_Mhpmevent10     = wen_legal_q & hit_Mhpmevent10;
  wire wen_Mhpmevent11     = wen_legal_q & hit_Mhpmevent11;
  wire wen_Mhpmevent12     = wen_legal_q & hit_Mhpmevent12;
  wire wen_Mhpmevent13     = wen_legal_q & hit_Mhpmevent13;
  wire wen_Mhpmevent14     = wen_legal_q & hit_Mhpmevent14;
  wire wen_Mhpmevent15     = wen_legal_q & hit_Mhpmevent15;
  wire wen_Mhpmevent16     = wen_legal_q & hit_Mhpmevent16;
  wire wen_Mhpmevent17     = wen_legal_q & hit_Mhpmevent17;
  wire wen_Mhpmevent18     = wen_legal_q & hit_Mhpmevent18;
  wire wen_Mhpmevent19     = wen_legal_q & hit_Mhpmevent19;
  wire wen_Mhpmevent20     = wen_legal_q & hit_Mhpmevent20;
  wire wen_Mhpmevent21     = wen_legal_q & hit_Mhpmevent21;
  wire wen_Mhpmevent22     = wen_legal_q & hit_Mhpmevent22;
  wire wen_Mhpmevent23     = wen_legal_q & hit_Mhpmevent23;
  wire wen_Mhpmevent24     = wen_legal_q & hit_Mhpmevent24;
  wire wen_Mhpmevent25     = wen_legal_q & hit_Mhpmevent25;
  wire wen_Mhpmevent26     = wen_legal_q & hit_Mhpmevent26;
  wire wen_Mhpmevent27     = wen_legal_q & hit_Mhpmevent27;
  wire wen_Mhpmevent28     = wen_legal_q & hit_Mhpmevent28;
  wire wen_Mhpmevent29     = wen_legal_q & hit_Mhpmevent29;
  wire wen_Mhpmevent30     = wen_legal_q & hit_Mhpmevent30;
  wire wen_Mhpmevent31     = wen_legal_q & hit_Mhpmevent31;
  wire wen_mscratch        = wen_legal_q & hit_mscratch;
  wire wen_mepc            = wen_legal_q & hit_mepc;
  wire wen_mcause          = wen_legal_q & hit_mcause;
  wire wen_mtval           = wen_legal_q & hit_mtval;
  wire wen_mip             = wen_legal_q & hit_mip;
  wire wen_mtinst          = wen_legal_q & hit_mtinst;
  wire wen_mtval2          = wen_legal_q & hit_mtval2;
  wire wen_miselect        = wen_legal_q & hit_miselect;
  wire wen_mireg           = wen_legal_q & hit_mireg;
  wire wen_mtopei          = wen_legal_q & hit_mtopei;
  wire wen_pmpcfg_0        = wen_legal_q & hit_pmpcfg_0;
  wire wen_pmpcfg_1        = wen_legal_q & hit_pmpcfg_1;
  wire wen_pmpcfg_2        = wen_legal_q & hit_pmpcfg_2;
  wire wen_pmpcfg_3        = wen_legal_q & hit_pmpcfg_3;
  wire wen_scontext        = wen_legal_q & hit_scontext;
  wire wen_sbpctl          = wen_legal_q & hit_sbpctl;
  wire wen_spfctl          = wen_legal_q & hit_spfctl;
  wire wen_slvpredctl      = wen_legal_q & hit_slvpredctl;
  wire wen_smblockctl      = wen_legal_q & hit_smblockctl;
  wire wen_srnctl          = wen_legal_q & hit_srnctl;
  wire wen_hstatus         = wen_legal_q & hit_hstatus;
  wire wen_hedeleg         = wen_legal_q & hit_hedeleg;
  wire wen_hideleg         = wen_legal_q & hit_hideleg;
  wire wen_hie             = wen_legal_q & hit_hie;
  wire wen_htimedelta      = wen_legal_q & hit_htimedelta;
  wire wen_hcounteren      = wen_legal_q & hit_hcounteren;
  wire wen_hgeie           = wen_legal_q & hit_hgeie;
  wire wen_hvien           = wen_legal_q & hit_hvien;
  wire wen_hvictl          = wen_legal_q & hit_hvictl;
  wire wen_henvcfg         = wen_legal_q & hit_henvcfg;
  wire wen_hstateen0       = wen_legal_q & hit_hstateen0;
  wire wen_hstateen1       = wen_legal_q & hit_hstateen1;
  wire wen_hstateen2       = wen_legal_q & hit_hstateen2;
  wire wen_hstateen3       = wen_legal_q & hit_hstateen3;
  wire wen_htval           = wen_legal_q & hit_htval;
  wire wen_hip             = wen_legal_q & hit_hip;
  wire wen_hvip            = wen_legal_q & hit_hvip;
  wire wen_hviprio1        = wen_legal_q & hit_hviprio1;
  wire wen_hviprio2        = wen_legal_q & hit_hviprio2;
  wire wen_htinst          = wen_legal_q & hit_htinst;
  wire wen_hgatp           = wen_legal_q & hit_hgatp;
  wire wen_hcontext        = wen_legal_q & hit_hcontext;
  wire wen_mnscratch       = wen_legal_q & hit_mnscratch;
  wire wen_mnepc           = wen_legal_q & hit_mnepc;
  wire wen_mncause         = wen_legal_q & hit_mncause;
  wire wen_mnstatus        = wen_legal_q & hit_mnstatus;
  wire wen_mseccfg         = wen_legal_q & hit_mseccfg;
  wire wen_tselect         = wen_legal_q & hit_tselect;
  wire wen_tdata1          = wen_legal_q & hit_tdata1;
  wire wen_tdata2          = wen_legal_q & hit_tdata2;
  wire wen_mcontext        = wen_legal_q & hit_mcontext;
  wire wen_dcsr            = wen_legal_q & hit_dcsr;
  wire wen_dpc             = wen_legal_q & hit_dpc;
  wire wen_dscratch0       = wen_legal_q & hit_dscratch0;
  wire wen_dscratch1       = wen_legal_q & hit_dscratch1;
  wire wen_pmacfg_0        = wen_legal_q & hit_pmacfg_0;
  wire wen_pmacfg_1        = wen_legal_q & hit_pmacfg_1;
  wire wen_pmacfg_2        = wen_legal_q & hit_pmacfg_2;
  wire wen_pmacfg_3        = wen_legal_q & hit_pmacfg_3;
  wire wen_mcycle          = wen_legal_q & hit_mcycle;
  wire wen_minstret        = wen_legal_q & hit_minstret;
  wire wen_mhpmcounters_0  = wen_legal_q & hit_mhpmcounters_0;
  wire wen_mhpmcounters_1  = wen_legal_q & hit_mhpmcounters_1;
  wire wen_mhpmcounters_2  = wen_legal_q & hit_mhpmcounters_2;
  wire wen_mhpmcounters_3  = wen_legal_q & hit_mhpmcounters_3;
  wire wen_mhpmcounters_4  = wen_legal_q & hit_mhpmcounters_4;
  wire wen_mhpmcounters_5  = wen_legal_q & hit_mhpmcounters_5;
  wire wen_mhpmcounters_6  = wen_legal_q & hit_mhpmcounters_6;
  wire wen_mhpmcounters_7  = wen_legal_q & hit_mhpmcounters_7;
  wire wen_mhpmcounters_8  = wen_legal_q & hit_mhpmcounters_8;
  wire wen_mhpmcounters_9  = wen_legal_q & hit_mhpmcounters_9;
  wire wen_mhpmcounters_10 = wen_legal_q & hit_mhpmcounters_10;
  wire wen_mhpmcounters_11 = wen_legal_q & hit_mhpmcounters_11;
  wire wen_mhpmcounters_12 = wen_legal_q & hit_mhpmcounters_12;
  wire wen_mhpmcounters_13 = wen_legal_q & hit_mhpmcounters_13;
  wire wen_mhpmcounters_14 = wen_legal_q & hit_mhpmcounters_14;
  wire wen_mhpmcounters_15 = wen_legal_q & hit_mhpmcounters_15;
  wire wen_mhpmcounters_16 = wen_legal_q & hit_mhpmcounters_16;
  wire wen_mhpmcounters_17 = wen_legal_q & hit_mhpmcounters_17;
  wire wen_mhpmcounters_18 = wen_legal_q & hit_mhpmcounters_18;
  wire wen_mhpmcounters_19 = wen_legal_q & hit_mhpmcounters_19;
  wire wen_mhpmcounters_20 = wen_legal_q & hit_mhpmcounters_20;
  wire wen_mhpmcounters_21 = wen_legal_q & hit_mhpmcounters_21;
  wire wen_mhpmcounters_22 = wen_legal_q & hit_mhpmcounters_22;
  wire wen_mhpmcounters_23 = wen_legal_q & hit_mhpmcounters_23;
  wire wen_mhpmcounters_24 = wen_legal_q & hit_mhpmcounters_24;
  wire wen_mhpmcounters_25 = wen_legal_q & hit_mhpmcounters_25;
  wire wen_mhpmcounters_26 = wen_legal_q & hit_mhpmcounters_26;
  wire wen_mhpmcounters_27 = wen_legal_q & hit_mhpmcounters_27;
  wire wen_mhpmcounters_28 = wen_legal_q & hit_mhpmcounters_28;
  wire wen_mcorepwr        = wen_legal_q & hit_mcorepwr;
  wire wen_mflushpwr       = wen_legal_q & hit_mflushpwr;
  wire wen_mbmc            = wen_legal_q & hit_mbmc;

  // 间接 CSR 背后的 iprio 寄存器：mireg/sireg 写 + *iselect 选中对应编号
  wire wen_miprio0   = wen_mireg & miselect_regOut_ALL == 9'h30;
  wire wen_miprio2   = wen_mireg & miselect_regOut_ALL == 9'h32;
  wire wen_siprio0   = wen_sireg & siselect_regOut_ALL == 13'h30;
  wire wen_siprio2   = wen_sireg & siselect_regOut_ALL == 13'h32;
  wire wen_siprios_0 = wen_sireg & siselect_regOut_ALL == 13'h34;
  wire wen_siprios_1 = wen_sireg & siselect_regOut_ALL == 13'h36;
  wire wen_siprios_2 = wen_sireg & siselect_regOut_ALL == 13'h38;
  wire wen_siprios_3 = wen_sireg & siselect_regOut_ALL == 13'h3A;
  wire wen_siprios_4 = wen_sireg & siselect_regOut_ALL == 13'h3C;
  wire wen_siprios_5 = wen_sireg & siselect_regOut_ALL == 13'h3E;

  // 触发器：tdata1/tdata2 写到 tselect 选中的那一组；DMODE=1 的触发器只有 debug 模式能写
  wire tselect_is_0 = tselect_rdata == 2'h0;
  wire tselect_is_1 = tselect_rdata == 2'h1;
  wire tselect_is_2 = tselect_rdata == 2'h2;
  wire tselect_is_3 = tselect_rdata == 2'h3;
  wire trigger_can_write = tdata1_rdata[59] & debug_mode | ~tdata1_rdata[59];   // tdata1.DMODE
  wire tdata1_update = wen_tdata1 & trigger_can_write;
  wire tdata2_update = wen_tdata2 & trigger_can_write;
  wire wen_tdata1RegVec_0 = tdata1_update & tselect_is_0;
  wire wen_tdata1RegVec_1 = tdata1_update & tselect_is_1;
  wire wen_tdata1RegVec_2 = tdata1_update & tselect_is_2;
  wire wen_tdata1RegVec_3 = tdata1_update & tselect_is_3;
  wire wen_tdata2RegVec_0 = tdata2_update & tselect_is_0;
  wire wen_tdata2RegVec_1 = tdata2_update & tselect_is_1;
  wire wen_tdata2RegVec_2 = tdata2_update & tselect_is_2;
  wire wen_tdata2RegVec_3 = tdata2_update & tselect_is_3;

  // PMP/PMA 配置：一个 pmpcfgN CSR 管 8 个条目，每个条目一个字节；写数据先经
  // PMPEntryHandleModule（锁位、TOR 等 WARL 规则）处理成 64 位，再按字节拆给 8 个条目
  wire [63:0] pmpcfg_byte_wdata [0:7];
  wire [63:0] pmacfg_byte_wdata [0:7];
  for (genvar b = 0; b < 8; b++) begin : g_cfg_byte
    assign pmpcfg_byte_wdata[b] = {56'h0, pmpEntryMod_io_out_pmpCfgWData[8*b +: 8]};
    assign pmacfg_byte_wdata[b] = {56'h0, pmaEntryMod_io_out_pmaCfgWdata[8*b +: 8]};
  end

  // ==========================================================================
  // 4. 地址是否是一个存在的 CSR（不存在 -> 非法指令）
  // ==========================================================================
  function automatic logic csr_addr_exists(input logic [11:0] a);
    case (a)
      12'h001, 12'h002, 12'h003, 12'h008, 12'h009, 12'h00A, 12'h00F, 12'h100,
      12'h104, 12'h105, 12'h106, 12'h10A, 12'h10C, 12'h10D, 12'h10E, 12'h10F,
      12'h140, 12'h141, 12'h142, 12'h143, 12'h144, 12'h14D, 12'h150, 12'h151,
      12'h152, 12'h153, 12'h155, 12'h156, 12'h157, 12'h15C, 12'h180, 12'h200,
      12'h204, 12'h205, 12'h240, 12'h241, 12'h242, 12'h243, 12'h244, 12'h24D,
      12'h250, 12'h251, 12'h252, 12'h253, 12'h255, 12'h256, 12'h257, 12'h25C,
      12'h280, 12'h300, 12'h301, 12'h302, 12'h303, 12'h304, 12'h305, 12'h306,
      12'h308, 12'h309, 12'h30A, 12'h30C, 12'h30D, 12'h30E, 12'h30F, 12'h320,
      12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32A,
      12'h32B, 12'h32C, 12'h32D, 12'h32E, 12'h32F, 12'h330, 12'h331, 12'h332,
      12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33A,
      12'h33B, 12'h33C, 12'h33D, 12'h33E, 12'h33F, 12'h340, 12'h341, 12'h342,
      12'h343, 12'h344, 12'h34A, 12'h34B, 12'h350, 12'h351, 12'h352, 12'h353,
      12'h355, 12'h356, 12'h357, 12'h35C, 12'h3A0, 12'h3A2, 12'h3A4, 12'h3A6,
      12'h3A8, 12'h3AA, 12'h3AC, 12'h3AE, 12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3,
      12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7, 12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB,
      12'h3BC, 12'h3BD, 12'h3BE, 12'h3BF, 12'h3C0, 12'h3C1, 12'h3C2, 12'h3C3,
      12'h3C4, 12'h3C5, 12'h3C6, 12'h3C7, 12'h3C8, 12'h3C9, 12'h3CA, 12'h3CB,
      12'h3CC, 12'h3CD, 12'h3CE, 12'h3CF, 12'h3D0, 12'h3D1, 12'h3D2, 12'h3D3,
      12'h3D4, 12'h3D5, 12'h3D6, 12'h3D7, 12'h3D8, 12'h3D9, 12'h3DA, 12'h3DB,
      12'h3DC, 12'h3DD, 12'h3DE, 12'h3DF, 12'h3E0, 12'h3E1, 12'h3E2, 12'h3E3,
      12'h3E4, 12'h3E5, 12'h3E6, 12'h3E7, 12'h3E8, 12'h3E9, 12'h3EA, 12'h3EB,
      12'h3EC, 12'h3ED, 12'h3EE, 12'h3EF, 12'h5A8, 12'h5C0, 12'h5C1, 12'h5C2,
      12'h5C3, 12'h5C4, 12'h600, 12'h602, 12'h603, 12'h604, 12'h605, 12'h606,
      12'h607, 12'h608, 12'h609, 12'h60A, 12'h60C, 12'h60D, 12'h60E, 12'h60F,
      12'h643, 12'h644, 12'h645, 12'h646, 12'h647, 12'h64A, 12'h680, 12'h6A8,
      12'h740, 12'h741, 12'h742, 12'h744, 12'h747, 12'h7A0, 12'h7A1, 12'h7A2,
      12'h7A4, 12'h7A8, 12'h7B0, 12'h7B1, 12'h7B2, 12'h7B3, 12'h7C0, 12'h7C2,
      12'h7C4, 12'h7C6, 12'h7C8, 12'h7C9, 12'h7CA, 12'h7CB, 12'h7CC, 12'h7CD,
      12'h7CE, 12'h7CF, 12'h7D0, 12'h7D1, 12'h7D2, 12'h7D3, 12'h7D4, 12'h7D5,
      12'h7D6, 12'h7D7, 12'h7D8, 12'h7D9, 12'h7DA, 12'h7DB, 12'h7DC, 12'h7DD,
      12'h7DE, 12'h7DF, 12'h7E0, 12'h7E1, 12'h7E2, 12'h7E3, 12'h7E4, 12'h7E5,
      12'h7E6, 12'h7E7, 12'hB00, 12'hB02, 12'hB03, 12'hB04, 12'hB05, 12'hB06,
      12'hB07, 12'hB08, 12'hB09, 12'hB0A, 12'hB0B, 12'hB0C, 12'hB0D, 12'hB0E,
      12'hB0F, 12'hB10, 12'hB11, 12'hB12, 12'hB13, 12'hB14, 12'hB15, 12'hB16,
      12'hB17, 12'hB18, 12'hB19, 12'hB1A, 12'hB1B, 12'hB1C, 12'hB1D, 12'hB1E,
      12'hB1F, 12'hBC0, 12'hBC1, 12'hBC2, 12'hC00, 12'hC01, 12'hC02, 12'hC03,
      12'hC04, 12'hC05, 12'hC06, 12'hC07, 12'hC08, 12'hC09, 12'hC0A, 12'hC0B,
      12'hC0C, 12'hC0D, 12'hC0E, 12'hC0F, 12'hC10, 12'hC11, 12'hC12, 12'hC13,
      12'hC14, 12'hC15, 12'hC16, 12'hC17, 12'hC18, 12'hC19, 12'hC1A, 12'hC1B,
      12'hC1C, 12'hC1D, 12'hC1E, 12'hC1F, 12'hC20, 12'hC21, 12'hC22, 12'hDA0,
      12'hDB0, 12'hE12, 12'hEB0, 12'hF11, 12'hF12, 12'hF13, 12'hF14, 12'hF15,
      12'hFB0:
        csr_addr_exists = 1'b1;
      default:
        csr_addr_exists = 1'b0;
    endcase
  endfunction

  wire  no_csr_illegal = (ren | wen) & ~csr_addr_exists(addr);
  logic no_csr_illegal_q;          // 打一拍，给 distributedWenLegal 用
  always @(posedge clock)
    if (ren | wen)
      no_csr_illegal_q <= no_csr_illegal;

  // ==========================================================================
  // 5. 读数据 Mux 与 regOut Mux（独热：hit_* 至多一个为 1）
  // ==========================================================================
  // 间接寄存器 mireg/sireg 读 iprio：按 *iselect 的值选
  wire [63:0] mireg_iprio_rdata =
      (miselect_rdata == 64'h30 ? miprio0_rdata : 64'h0)
    | (miselect_rdata == 64'h32 ? miprio2_rdata : 64'h0);
  wire [63:0] sireg_iprio_rdata =
      (siselect_rdata == 64'h30 ? siprio0_rdata   : 64'h0)
    | (siselect_rdata == 64'h32 ? siprio2_rdata   : 64'h0)
    | (siselect_rdata == 64'h34 ? siprios_0_rdata : 64'h0)
    | (siselect_rdata == 64'h36 ? siprios_1_rdata : 64'h0)
    | (siselect_rdata == 64'h38 ? siprios_2_rdata : 64'h0)
    | (siselect_rdata == 64'h3A ? siprios_3_rdata : 64'h0)
    | (siselect_rdata == 64'h3C ? siprios_4_rdata : 64'h0)
    | (siselect_rdata == 64'h3E ? siprios_5_rdata : 64'h0);
  // tdata1/tdata2 读 tselect 选中的那一组
  wire [63:0] tdata1_selected_rdata =
      (tselect_is_0 ? tdata1RegVec_0_rdata : 64'h0)
    | (tselect_is_1 ? tdata1RegVec_1_rdata : 64'h0)
    | (tselect_is_2 ? tdata1RegVec_2_rdata : 64'h0)
    | (tselect_is_3 ? tdata1RegVec_3_rdata : 64'h0);
  wire [63:0] tdata2_selected_rdata =
      (tselect_is_0 ? tdata2RegVec_0_rdata : 64'h0)
    | (tselect_is_1 ? tdata2RegVec_1_rdata : 64'h0)
    | (tselect_is_2 ? tdata2RegVec_2_rdata : 64'h0)
    | (tselect_is_3 ? tdata2RegVec_3_rdata : 64'h0);

  // 读数据：每个 CSR 的 rdata（常数 CSR 直接写常数：misa、tinfo、vlenb、mvendorid、marchid；
  // mimpid、vl、sireg2..6 等地址存在但读 0，所以不在表里）
  wire [63:0] rdata =
      (hit_fflags          ? {59'h0, fcsr_fflagsRdata} : 64'h0)
    | (hit_frm             ? {61'h0, fcsr_frmRdata} : 64'h0)
    | (hit_fcsr            ? fcsr_rdata : 64'h0)
    | (hit_vstart          ? vstart_rdata : 64'h0)
    | (hit_vxsat           ? {63'h0, vcsr_vxsat} : 64'h0)
    | (hit_vxrm            ? {62'h0, vcsr_vxrm} : 64'h0)
    | (hit_vcsr            ? vcsr_rdata : 64'h0)
    | (hit_sstatus         ? mstatus_sstatusRdata : 64'h0)
    | (hit_sie             ? sie_rdata : 64'h0)
    | (hit_stvec           ? stvec_rdata : 64'h0)
    | (hit_scounteren      ? scounteren_rdata : 64'h0)
    | (hit_senvcfg         ? senvcfg_rdata : 64'h0)
    | (hit_sstateen0       ? {32'h0, sstateen0_rdata} : 64'h0)
    | (hit_sstateen1       ? {32'h0, sstateen1_rdata} : 64'h0)
    | (hit_sstateen2       ? {32'h0, sstateen2_rdata} : 64'h0)
    | (hit_sstateen3       ? {32'h0, sstateen3_rdata} : 64'h0)
    | (hit_sscratch        ? sscratch_rdata : 64'h0)
    | (hit_sepc            ? sepc_rdata : 64'h0)
    | (hit_scause          ? scause_rdata : 64'h0)
    | (hit_stval           ? stval_rdata : 64'h0)
    | (hit_sip             ? sip_rdata : 64'h0)
    | (hit_stimecmp        ? stimecmp_rdata : 64'h0)
    | (hit_siselect        ? siselect_rdata : 64'h0)
    | (hit_sireg           ? sireg_rdata : 64'h0)
    | (hit_stopei          ? stopei_rdata : 64'h0)
    | (hit_satp            ? satp_rdata : 64'h0)
    | (hit_vsstatus        ? vsstatus_rdata : 64'h0)
    | (hit_vsie            ? vsie_rdata : 64'h0)
    | (hit_vstvec          ? vstvec_rdata : 64'h0)
    | (hit_vsscratch       ? vsscratch_rdata : 64'h0)
    | (hit_vsepc           ? vsepc_rdata : 64'h0)
    | (hit_vscause         ? vscause_rdata : 64'h0)
    | (hit_vstval          ? vstval_rdata : 64'h0)
    | (hit_vsip            ? vsip_rdata : 64'h0)
    | (hit_vstimecmp       ? vstimecmp_rdata : 64'h0)
    | (hit_vsiselect       ? vsiselect_rdata : 64'h0)
    | (hit_vsireg          ? vsireg_rdata : 64'h0)
    | (hit_vstopei         ? vstopei_rdata : 64'h0)
    | (hit_vsatp           ? vsatp_rdata : 64'h0)
    | (hit_mstatus         ? mstatus_rdata : 64'h0)
    | (hit_misa            ? 64'h80000000003411AF : 64'h0)
    | (hit_medeleg         ? medeleg_rdata : 64'h0)
    | (hit_mideleg         ? mideleg_rdata : 64'h0)
    | (hit_mie             ? mie_rdata : 64'h0)
    | (hit_mtvec           ? mtvec_rdata : 64'h0)
    | (hit_mcounteren      ? mcounteren_rdata : 64'h0)
    | (hit_mvien           ? mvien_rdata : 64'h0)
    | (hit_mvip            ? mvip_rdata : 64'h0)
    | (hit_menvcfg         ? menvcfg_rdata : 64'h0)
    | (hit_mstateen0       ? mstateen0_rdata : 64'h0)
    | (hit_mstateen1       ? mstateen1_rdata : 64'h0)
    | (hit_mstateen2       ? mstateen2_rdata : 64'h0)
    | (hit_mstateen3       ? mstateen3_rdata : 64'h0)
    | (hit_mcountinhibit   ? mcountinhibit_rdata : 64'h0)
    | (hit_Mhpmevent3      ? Mhpmevent3_rdata : 64'h0)
    | (hit_Mhpmevent4      ? Mhpmevent4_rdata : 64'h0)
    | (hit_Mhpmevent5      ? Mhpmevent5_rdata : 64'h0)
    | (hit_Mhpmevent6      ? Mhpmevent6_rdata : 64'h0)
    | (hit_Mhpmevent7      ? Mhpmevent7_rdata : 64'h0)
    | (hit_Mhpmevent8      ? Mhpmevent8_rdata : 64'h0)
    | (hit_Mhpmevent9      ? Mhpmevent9_rdata : 64'h0)
    | (hit_Mhpmevent10     ? Mhpmevent10_rdata : 64'h0)
    | (hit_Mhpmevent11     ? Mhpmevent11_rdata : 64'h0)
    | (hit_Mhpmevent12     ? Mhpmevent12_rdata : 64'h0)
    | (hit_Mhpmevent13     ? Mhpmevent13_rdata : 64'h0)
    | (hit_Mhpmevent14     ? Mhpmevent14_rdata : 64'h0)
    | (hit_Mhpmevent15     ? Mhpmevent15_rdata : 64'h0)
    | (hit_Mhpmevent16     ? Mhpmevent16_rdata : 64'h0)
    | (hit_Mhpmevent17     ? Mhpmevent17_rdata : 64'h0)
    | (hit_Mhpmevent18     ? Mhpmevent18_rdata : 64'h0)
    | (hit_Mhpmevent19     ? Mhpmevent19_rdata : 64'h0)
    | (hit_Mhpmevent20     ? Mhpmevent20_rdata : 64'h0)
    | (hit_Mhpmevent21     ? Mhpmevent21_rdata : 64'h0)
    | (hit_Mhpmevent22     ? Mhpmevent22_rdata : 64'h0)
    | (hit_Mhpmevent23     ? Mhpmevent23_rdata : 64'h0)
    | (hit_Mhpmevent24     ? Mhpmevent24_rdata : 64'h0)
    | (hit_Mhpmevent25     ? Mhpmevent25_rdata : 64'h0)
    | (hit_Mhpmevent26     ? Mhpmevent26_rdata : 64'h0)
    | (hit_Mhpmevent27     ? Mhpmevent27_rdata : 64'h0)
    | (hit_Mhpmevent28     ? Mhpmevent28_rdata : 64'h0)
    | (hit_Mhpmevent29     ? Mhpmevent29_rdata : 64'h0)
    | (hit_Mhpmevent30     ? Mhpmevent30_rdata : 64'h0)
    | (hit_Mhpmevent31     ? Mhpmevent31_rdata : 64'h0)
    | (hit_mscratch        ? mscratch_rdata : 64'h0)
    | (hit_mepc            ? mepc_rdata : 64'h0)
    | (hit_mcause          ? mcause_rdata : 64'h0)
    | (hit_mtval           ? mtval_rdata : 64'h0)
    | (hit_mip             ? mip_rdata : 64'h0)
    | (hit_mtinst          ? mtinst_rdata : 64'h0)
    | (hit_mtval2          ? mtval2_rdata : 64'h0)
    | (hit_miselect        ? miselect_rdata : 64'h0)
    | (hit_mireg           ? mireg_rdata : 64'h0)
    | (hit_mtopei          ? mtopei_rdata : 64'h0)
    | (hit_pmpcfg_0        ? pmpcfg_0_rdata : 64'h0)
    | (hit_pmpcfg_1        ? pmpcfg_1_rdata : 64'h0)
    | (hit_pmpcfg_2        ? pmpcfg_2_rdata : 64'h0)
    | (hit_pmpcfg_3        ? pmpcfg_3_rdata : 64'h0)
    | (hit_pmpcfg_4        ? pmpcfg_4_rdata : 64'h0)
    | (hit_pmpcfg_5        ? pmpcfg_5_rdata : 64'h0)
    | (hit_pmpcfg_6        ? pmpcfg_6_rdata : 64'h0)
    | (hit_pmpcfg_7        ? pmpcfg_7_rdata : 64'h0)
    | (hit_pmpaddr_0       ? pmpaddr_0_rdata : 64'h0)
    | (hit_pmpaddr_1       ? pmpaddr_1_rdata : 64'h0)
    | (hit_pmpaddr_2       ? pmpaddr_2_rdata : 64'h0)
    | (hit_pmpaddr_3       ? pmpaddr_3_rdata : 64'h0)
    | (hit_pmpaddr_4       ? pmpaddr_4_rdata : 64'h0)
    | (hit_pmpaddr_5       ? pmpaddr_5_rdata : 64'h0)
    | (hit_pmpaddr_6       ? pmpaddr_6_rdata : 64'h0)
    | (hit_pmpaddr_7       ? pmpaddr_7_rdata : 64'h0)
    | (hit_pmpaddr_8       ? pmpaddr_8_rdata : 64'h0)
    | (hit_pmpaddr_9       ? pmpaddr_9_rdata : 64'h0)
    | (hit_pmpaddr_10      ? pmpaddr_10_rdata : 64'h0)
    | (hit_pmpaddr_11      ? pmpaddr_11_rdata : 64'h0)
    | (hit_pmpaddr_12      ? pmpaddr_12_rdata : 64'h0)
    | (hit_pmpaddr_13      ? pmpaddr_13_rdata : 64'h0)
    | (hit_pmpaddr_14      ? pmpaddr_14_rdata : 64'h0)
    | (hit_pmpaddr_15      ? pmpaddr_15_rdata : 64'h0)
    | (hit_pmpaddr_16      ? pmpaddr_16_rdata : 64'h0)
    | (hit_pmpaddr_17      ? pmpaddr_17_rdata : 64'h0)
    | (hit_pmpaddr_18      ? pmpaddr_18_rdata : 64'h0)
    | (hit_pmpaddr_19      ? pmpaddr_19_rdata : 64'h0)
    | (hit_pmpaddr_20      ? pmpaddr_20_rdata : 64'h0)
    | (hit_pmpaddr_21      ? pmpaddr_21_rdata : 64'h0)
    | (hit_pmpaddr_22      ? pmpaddr_22_rdata : 64'h0)
    | (hit_pmpaddr_23      ? pmpaddr_23_rdata : 64'h0)
    | (hit_pmpaddr_24      ? pmpaddr_24_rdata : 64'h0)
    | (hit_pmpaddr_25      ? pmpaddr_25_rdata : 64'h0)
    | (hit_pmpaddr_26      ? pmpaddr_26_rdata : 64'h0)
    | (hit_pmpaddr_27      ? pmpaddr_27_rdata : 64'h0)
    | (hit_pmpaddr_28      ? pmpaddr_28_rdata : 64'h0)
    | (hit_pmpaddr_29      ? pmpaddr_29_rdata : 64'h0)
    | (hit_pmpaddr_30      ? pmpaddr_30_rdata : 64'h0)
    | (hit_pmpaddr_31      ? pmpaddr_31_rdata : 64'h0)
    | (hit_pmpaddr_32      ? pmpaddr_32_rdata : 64'h0)
    | (hit_pmpaddr_33      ? pmpaddr_33_rdata : 64'h0)
    | (hit_pmpaddr_34      ? pmpaddr_34_rdata : 64'h0)
    | (hit_pmpaddr_35      ? pmpaddr_35_rdata : 64'h0)
    | (hit_pmpaddr_36      ? pmpaddr_36_rdata : 64'h0)
    | (hit_pmpaddr_37      ? pmpaddr_37_rdata : 64'h0)
    | (hit_pmpaddr_38      ? pmpaddr_38_rdata : 64'h0)
    | (hit_pmpaddr_39      ? pmpaddr_39_rdata : 64'h0)
    | (hit_pmpaddr_40      ? pmpaddr_40_rdata : 64'h0)
    | (hit_pmpaddr_41      ? pmpaddr_41_rdata : 64'h0)
    | (hit_pmpaddr_42      ? pmpaddr_42_rdata : 64'h0)
    | (hit_pmpaddr_43      ? pmpaddr_43_rdata : 64'h0)
    | (hit_pmpaddr_44      ? pmpaddr_44_rdata : 64'h0)
    | (hit_pmpaddr_45      ? pmpaddr_45_rdata : 64'h0)
    | (hit_pmpaddr_46      ? pmpaddr_46_rdata : 64'h0)
    | (hit_pmpaddr_47      ? pmpaddr_47_rdata : 64'h0)
    | (hit_pmpaddr_48      ? pmpaddr_48_rdata : 64'h0)
    | (hit_pmpaddr_49      ? pmpaddr_49_rdata : 64'h0)
    | (hit_pmpaddr_50      ? pmpaddr_50_rdata : 64'h0)
    | (hit_pmpaddr_51      ? pmpaddr_51_rdata : 64'h0)
    | (hit_pmpaddr_52      ? pmpaddr_52_rdata : 64'h0)
    | (hit_pmpaddr_53      ? pmpaddr_53_rdata : 64'h0)
    | (hit_pmpaddr_54      ? pmpaddr_54_rdata : 64'h0)
    | (hit_pmpaddr_55      ? pmpaddr_55_rdata : 64'h0)
    | (hit_pmpaddr_56      ? pmpaddr_56_rdata : 64'h0)
    | (hit_pmpaddr_57      ? pmpaddr_57_rdata : 64'h0)
    | (hit_pmpaddr_58      ? pmpaddr_58_rdata : 64'h0)
    | (hit_pmpaddr_59      ? pmpaddr_59_rdata : 64'h0)
    | (hit_pmpaddr_60      ? pmpaddr_60_rdata : 64'h0)
    | (hit_pmpaddr_61      ? pmpaddr_61_rdata : 64'h0)
    | (hit_pmpaddr_62      ? pmpaddr_62_rdata : 64'h0)
    | (hit_pmpaddr_63      ? pmpaddr_63_rdata : 64'h0)
    | (hit_scontext        ? {32'h0, scontext_rdata} : 64'h0)
    | (hit_sbpctl          ? sbpctl_rdata : 64'h0)
    | (hit_spfctl          ? spfctl_rdata : 64'h0)
    | (hit_slvpredctl      ? slvpredctl_rdata : 64'h0)
    | (hit_smblockctl      ? smblockctl_rdata : 64'h0)
    | (hit_srnctl          ? srnctl_rdata : 64'h0)
    | (hit_hstatus         ? hstatus_rdata : 64'h0)
    | (hit_hedeleg         ? hedeleg_rdata : 64'h0)
    | (hit_hideleg         ? hideleg_rdata : 64'h0)
    | (hit_hie             ? hie_rdata : 64'h0)
    | (hit_htimedelta      ? htimedelta_rdata : 64'h0)
    | (hit_hcounteren      ? hcounteren_rdata : 64'h0)
    | (hit_hgeie           ? hgeie_rdata : 64'h0)
    | (hit_hvien           ? hvien_rdata : 64'h0)
    | (hit_hvictl          ? hvictl_rdata : 64'h0)
    | (hit_henvcfg         ? henvcfg_rdata : 64'h0)
    | (hit_hstateen0       ? hstateen0_rdata : 64'h0)
    | (hit_hstateen1       ? hstateen1_rdata : 64'h0)
    | (hit_hstateen2       ? hstateen2_rdata : 64'h0)
    | (hit_hstateen3       ? hstateen3_rdata : 64'h0)
    | (hit_htval           ? htval_rdata : 64'h0)
    | (hit_hip             ? hip_rdata : 64'h0)
    | (hit_hvip            ? hvip_rdata : 64'h0)
    | (hit_hviprio1        ? hviprio1_rdata : 64'h0)
    | (hit_hviprio2        ? hviprio2_rdata : 64'h0)
    | (hit_htinst          ? htinst_rdata : 64'h0)
    | (hit_hgatp           ? hgatp_rdata : 64'h0)
    | (hit_hcontext        ? {50'h0, hcontext_rdata} : 64'h0)
    | (hit_mnscratch       ? mnscratch_rdata : 64'h0)
    | (hit_mnepc           ? mnepc_rdata : 64'h0)
    | (hit_mncause         ? mncause_rdata : 64'h0)
    | (hit_mnstatus        ? mnstatus_rdata : 64'h0)
    | (hit_mseccfg         ? mseccfg_rdata : 64'h0)
    | (hit_tselect         ? {62'h0, tselect_rdata} : 64'h0)
    | (hit_tdata1          ? tdata1_rdata : 64'h0)
    | (hit_tdata2          ? tdata2_rdata : 64'h0)
    | (hit_tinfo           ? 64'h1000040 : 64'h0)
    | (hit_mcontext        ? {50'h0, mcontext_rdata} : 64'h0)
    | (hit_dcsr            ? {32'h0, dcsr_rdata} : 64'h0)
    | (hit_dpc             ? dpc_rdata : 64'h0)
    | (hit_dscratch0       ? dscratch0_rdata : 64'h0)
    | (hit_dscratch1       ? dscratch1_rdata : 64'h0)
    | (hit_pmacfg_0        ? pmacfg_0_rdata : 64'h0)
    | (hit_pmacfg_1        ? pmacfg_1_rdata : 64'h0)
    | (hit_pmacfg_2        ? pmacfg_2_rdata : 64'h0)
    | (hit_pmacfg_3        ? pmacfg_3_rdata : 64'h0)
    | (hit_pmaaddr_0       ? pmaaddr_0_rdata : 64'h0)
    | (hit_pmaaddr_1       ? pmaaddr_1_rdata : 64'h0)
    | (hit_pmaaddr_2       ? pmaaddr_2_rdata : 64'h0)
    | (hit_pmaaddr_3       ? pmaaddr_3_rdata : 64'h0)
    | (hit_pmaaddr_4       ? pmaaddr_4_rdata : 64'h0)
    | (hit_pmaaddr_5       ? pmaaddr_5_rdata : 64'h0)
    | (hit_pmaaddr_6       ? pmaaddr_6_rdata : 64'h0)
    | (hit_pmaaddr_7       ? pmaaddr_7_rdata : 64'h0)
    | (hit_pmaaddr_8       ? pmaaddr_8_rdata : 64'h0)
    | (hit_pmaaddr_9       ? pmaaddr_9_rdata : 64'h0)
    | (hit_pmaaddr_10      ? pmaaddr_10_rdata : 64'h0)
    | (hit_pmaaddr_11      ? pmaaddr_11_rdata : 64'h0)
    | (hit_pmaaddr_12      ? pmaaddr_12_rdata : 64'h0)
    | (hit_pmaaddr_13      ? pmaaddr_13_rdata : 64'h0)
    | (hit_pmaaddr_14      ? pmaaddr_14_rdata : 64'h0)
    | (hit_pmaaddr_15      ? pmaaddr_15_rdata : 64'h0)
    | (hit_pmaaddr_16      ? pmaaddr_16_rdata : 64'h0)
    | (hit_pmaaddr_17      ? pmaaddr_17_rdata : 64'h0)
    | (hit_pmaaddr_18      ? pmaaddr_18_rdata : 64'h0)
    | (hit_pmaaddr_19      ? pmaaddr_19_rdata : 64'h0)
    | (hit_pmaaddr_20      ? pmaaddr_20_rdata : 64'h0)
    | (hit_pmaaddr_21      ? pmaaddr_21_rdata : 64'h0)
    | (hit_pmaaddr_22      ? pmaaddr_22_rdata : 64'h0)
    | (hit_pmaaddr_23      ? pmaaddr_23_rdata : 64'h0)
    | (hit_pmaaddr_24      ? pmaaddr_24_rdata : 64'h0)
    | (hit_pmaaddr_25      ? pmaaddr_25_rdata : 64'h0)
    | (hit_pmaaddr_26      ? pmaaddr_26_rdata : 64'h0)
    | (hit_pmaaddr_27      ? pmaaddr_27_rdata : 64'h0)
    | (hit_pmaaddr_28      ? pmaaddr_28_rdata : 64'h0)
    | (hit_pmaaddr_29      ? pmaaddr_29_rdata : 64'h0)
    | (hit_pmaaddr_30      ? pmaaddr_30_rdata : 64'h0)
    | (hit_pmaaddr_31      ? pmaaddr_31_rdata : 64'h0)
    | (hit_mcycle          ? mcycle_rdata : 64'h0)
    | (hit_minstret        ? minstret_rdata : 64'h0)
    | (hit_mhpmcounters_0  ? mhpmcounters_0_rdata : 64'h0)
    | (hit_mhpmcounters_1  ? mhpmcounters_1_rdata : 64'h0)
    | (hit_mhpmcounters_2  ? mhpmcounters_2_rdata : 64'h0)
    | (hit_mhpmcounters_3  ? mhpmcounters_3_rdata : 64'h0)
    | (hit_mhpmcounters_4  ? mhpmcounters_4_rdata : 64'h0)
    | (hit_mhpmcounters_5  ? mhpmcounters_5_rdata : 64'h0)
    | (hit_mhpmcounters_6  ? mhpmcounters_6_rdata : 64'h0)
    | (hit_mhpmcounters_7  ? mhpmcounters_7_rdata : 64'h0)
    | (hit_mhpmcounters_8  ? mhpmcounters_8_rdata : 64'h0)
    | (hit_mhpmcounters_9  ? mhpmcounters_9_rdata : 64'h0)
    | (hit_mhpmcounters_10 ? mhpmcounters_10_rdata : 64'h0)
    | (hit_mhpmcounters_11 ? mhpmcounters_11_rdata : 64'h0)
    | (hit_mhpmcounters_12 ? mhpmcounters_12_rdata : 64'h0)
    | (hit_mhpmcounters_13 ? mhpmcounters_13_rdata : 64'h0)
    | (hit_mhpmcounters_14 ? mhpmcounters_14_rdata : 64'h0)
    | (hit_mhpmcounters_15 ? mhpmcounters_15_rdata : 64'h0)
    | (hit_mhpmcounters_16 ? mhpmcounters_16_rdata : 64'h0)
    | (hit_mhpmcounters_17 ? mhpmcounters_17_rdata : 64'h0)
    | (hit_mhpmcounters_18 ? mhpmcounters_18_rdata : 64'h0)
    | (hit_mhpmcounters_19 ? mhpmcounters_19_rdata : 64'h0)
    | (hit_mhpmcounters_20 ? mhpmcounters_20_rdata : 64'h0)
    | (hit_mhpmcounters_21 ? mhpmcounters_21_rdata : 64'h0)
    | (hit_mhpmcounters_22 ? mhpmcounters_22_rdata : 64'h0)
    | (hit_mhpmcounters_23 ? mhpmcounters_23_rdata : 64'h0)
    | (hit_mhpmcounters_24 ? mhpmcounters_24_rdata : 64'h0)
    | (hit_mhpmcounters_25 ? mhpmcounters_25_rdata : 64'h0)
    | (hit_mhpmcounters_26 ? mhpmcounters_26_rdata : 64'h0)
    | (hit_mhpmcounters_27 ? mhpmcounters_27_rdata : 64'h0)
    | (hit_mhpmcounters_28 ? mhpmcounters_28_rdata : 64'h0)
    | (hit_mcorepwr        ? mcorepwr_rdata : 64'h0)
    | (hit_mflushpwr       ? mflushpwr_rdata : 64'h0)
    | (hit_mbmc            ? mbmc_rdata : 64'h0)
    | (hit_cycle           ? cycle_rdata : 64'h0)
    | (hit_time            ? time_0_rdata : 64'h0)
    | (hit_instret         ? instret_rdata : 64'h0)
    | (hit_hpmcounters_0   ? hpmcounters_0_rdata : 64'h0)
    | (hit_hpmcounters_1   ? hpmcounters_1_rdata : 64'h0)
    | (hit_hpmcounters_2   ? hpmcounters_2_rdata : 64'h0)
    | (hit_hpmcounters_3   ? hpmcounters_3_rdata : 64'h0)
    | (hit_hpmcounters_4   ? hpmcounters_4_rdata : 64'h0)
    | (hit_hpmcounters_5   ? hpmcounters_5_rdata : 64'h0)
    | (hit_hpmcounters_6   ? hpmcounters_6_rdata : 64'h0)
    | (hit_hpmcounters_7   ? hpmcounters_7_rdata : 64'h0)
    | (hit_hpmcounters_8   ? hpmcounters_8_rdata : 64'h0)
    | (hit_hpmcounters_9   ? hpmcounters_9_rdata : 64'h0)
    | (hit_hpmcounters_10  ? hpmcounters_10_rdata : 64'h0)
    | (hit_hpmcounters_11  ? hpmcounters_11_rdata : 64'h0)
    | (hit_hpmcounters_12  ? hpmcounters_12_rdata : 64'h0)
    | (hit_hpmcounters_13  ? hpmcounters_13_rdata : 64'h0)
    | (hit_hpmcounters_14  ? hpmcounters_14_rdata : 64'h0)
    | (hit_hpmcounters_15  ? hpmcounters_15_rdata : 64'h0)
    | (hit_hpmcounters_16  ? hpmcounters_16_rdata : 64'h0)
    | (hit_hpmcounters_17  ? hpmcounters_17_rdata : 64'h0)
    | (hit_hpmcounters_18  ? hpmcounters_18_rdata : 64'h0)
    | (hit_hpmcounters_19  ? hpmcounters_19_rdata : 64'h0)
    | (hit_hpmcounters_20  ? hpmcounters_20_rdata : 64'h0)
    | (hit_hpmcounters_21  ? hpmcounters_21_rdata : 64'h0)
    | (hit_hpmcounters_22  ? hpmcounters_22_rdata : 64'h0)
    | (hit_hpmcounters_23  ? hpmcounters_23_rdata : 64'h0)
    | (hit_hpmcounters_24  ? hpmcounters_24_rdata : 64'h0)
    | (hit_hpmcounters_25  ? hpmcounters_25_rdata : 64'h0)
    | (hit_hpmcounters_26  ? hpmcounters_26_rdata : 64'h0)
    | (hit_hpmcounters_27  ? hpmcounters_27_rdata : 64'h0)
    | (hit_hpmcounters_28  ? hpmcounters_28_rdata : 64'h0)
    | (hit_vtype           ? vtype_rdata : 64'h0)
    | (hit_vlenb           ? 64'h10 : 64'h0)
    | (hit_scountovf       ? {32'h0, scountovf_rdata} : 64'h0)
    | (hit_stopi           ? stopi_rdata : 64'h0)
    | (hit_hgeip           ? hgeip_rdata : 64'h0)
    | (hit_vstopi          ? vstopi_rdata : 64'h0)
    | (hit_mvendorid       ? 64'h86F : 64'h0)
    | (hit_marchid         ? 64'h19 : 64'h0)
    | (hit_mhartid         ? mhartid_rdata : 64'h0)
    | (hit_mconfigptr      ? mconfigptr_rdata : 64'h0)
    | (hit_mtopi           ? mtopi_rdata : 64'h0);

  // regOut：各 CSR 寄存器字段的原值（不经读屏蔽），打包视图见 GENERATED(newcsr-regout)。
  // 只读的计数器/状态 CSR（地址 [11:10]==2'b11）不参与。
  assign io_out_bits_regOut =
      (hit_fflags          ? regout_fflags : 64'h0)
    | (hit_frm             ? regout_frm : 64'h0)
    | (hit_fcsr            ? regout_fcsr : 64'h0)
    | (hit_vstart          ? regout_vstart : 64'h0)
    | (hit_vxsat           ? regout_vxsat : 64'h0)
    | (hit_vxrm            ? regout_vxrm : 64'h0)
    | (hit_vcsr            ? regout_vcsr : 64'h0)
    | (hit_sstatus         ? regout_sstatus : 64'h0)
    | (hit_sie             ? regout_sie : 64'h0)
    | (hit_stvec           ? regout_stvec : 64'h0)
    | (hit_scounteren      ? regout_scounteren : 64'h0)
    | (hit_senvcfg         ? regout_senvcfg : 64'h0)
    | (hit_sstateen0       ? regout_sstateen0 : 64'h0)
    | (hit_sstateen1       ? regout_sstateen1 : 64'h0)
    | (hit_sstateen2       ? regout_sstateen2 : 64'h0)
    | (hit_sstateen3       ? regout_sstateen3 : 64'h0)
    | (hit_sscratch        ? regout_sscratch : 64'h0)
    | (hit_sepc            ? regout_sepc : 64'h0)
    | (hit_scause          ? regout_scause : 64'h0)
    | (hit_stval           ? regout_stval : 64'h0)
    | (hit_sip             ? regout_sip : 64'h0)
    | (hit_stimecmp        ? regout_stimecmp : 64'h0)
    | (hit_siselect        ? regout_siselect : 64'h0)
    | (hit_sireg           ? regout_sireg : 64'h0)
    | (hit_stopei          ? regout_stopei : 64'h0)
    | (hit_satp            ? regout_satp : 64'h0)
    | (hit_vsstatus        ? regout_vsstatus : 64'h0)
    | (hit_vsie            ? regout_vsie : 64'h0)
    | (hit_vstvec          ? regout_vstvec : 64'h0)
    | (hit_vsscratch       ? regout_vsscratch : 64'h0)
    | (hit_vsepc           ? regout_vsepc : 64'h0)
    | (hit_vscause         ? regout_vscause : 64'h0)
    | (hit_vstval          ? regout_vstval : 64'h0)
    | (hit_vsip            ? regout_vsip : 64'h0)
    | (hit_vstimecmp       ? regout_vstimecmp : 64'h0)
    | (hit_vsiselect       ? regout_vsiselect : 64'h0)
    | (hit_vsireg          ? regout_vsireg : 64'h0)
    | (hit_vstopei         ? regout_vstopei : 64'h0)
    | (hit_vsatp           ? regout_vsatp : 64'h0)
    | (hit_mstatus         ? regout_mstatus : 64'h0)
    | (hit_misa            ? regout_misa : 64'h0)
    | (hit_medeleg         ? regout_medeleg : 64'h0)
    | (hit_mideleg         ? regout_mideleg : 64'h0)
    | (hit_mie             ? regout_mie : 64'h0)
    | (hit_mtvec           ? regout_mtvec : 64'h0)
    | (hit_mcounteren      ? regout_mcounteren : 64'h0)
    | (hit_mvien           ? regout_mvien : 64'h0)
    | (hit_mvip            ? regout_mvip : 64'h0)
    | (hit_menvcfg         ? regout_menvcfg : 64'h0)
    | (hit_mstateen0       ? regout_mstateen0 : 64'h0)
    | (hit_mstateen1       ? regout_mstateen1 : 64'h0)
    | (hit_mstateen2       ? regout_mstateen2 : 64'h0)
    | (hit_mstateen3       ? regout_mstateen3 : 64'h0)
    | (hit_mcountinhibit   ? regout_mcountinhibit : 64'h0)
    | (hit_Mhpmevent3      ? regout_Mhpmevent3 : 64'h0)
    | (hit_Mhpmevent4      ? regout_Mhpmevent4 : 64'h0)
    | (hit_Mhpmevent5      ? regout_Mhpmevent5 : 64'h0)
    | (hit_Mhpmevent6      ? regout_Mhpmevent6 : 64'h0)
    | (hit_Mhpmevent7      ? regout_Mhpmevent7 : 64'h0)
    | (hit_Mhpmevent8      ? regout_Mhpmevent8 : 64'h0)
    | (hit_Mhpmevent9      ? regout_Mhpmevent9 : 64'h0)
    | (hit_Mhpmevent10     ? regout_Mhpmevent10 : 64'h0)
    | (hit_Mhpmevent11     ? regout_Mhpmevent11 : 64'h0)
    | (hit_Mhpmevent12     ? regout_Mhpmevent12 : 64'h0)
    | (hit_Mhpmevent13     ? regout_Mhpmevent13 : 64'h0)
    | (hit_Mhpmevent14     ? regout_Mhpmevent14 : 64'h0)
    | (hit_Mhpmevent15     ? regout_Mhpmevent15 : 64'h0)
    | (hit_Mhpmevent16     ? regout_Mhpmevent16 : 64'h0)
    | (hit_Mhpmevent17     ? regout_Mhpmevent17 : 64'h0)
    | (hit_Mhpmevent18     ? regout_Mhpmevent18 : 64'h0)
    | (hit_Mhpmevent19     ? regout_Mhpmevent19 : 64'h0)
    | (hit_Mhpmevent20     ? regout_Mhpmevent20 : 64'h0)
    | (hit_Mhpmevent21     ? regout_Mhpmevent21 : 64'h0)
    | (hit_Mhpmevent22     ? regout_Mhpmevent22 : 64'h0)
    | (hit_Mhpmevent23     ? regout_Mhpmevent23 : 64'h0)
    | (hit_Mhpmevent24     ? regout_Mhpmevent24 : 64'h0)
    | (hit_Mhpmevent25     ? regout_Mhpmevent25 : 64'h0)
    | (hit_Mhpmevent26     ? regout_Mhpmevent26 : 64'h0)
    | (hit_Mhpmevent27     ? regout_Mhpmevent27 : 64'h0)
    | (hit_Mhpmevent28     ? regout_Mhpmevent28 : 64'h0)
    | (hit_Mhpmevent29     ? regout_Mhpmevent29 : 64'h0)
    | (hit_Mhpmevent30     ? regout_Mhpmevent30 : 64'h0)
    | (hit_Mhpmevent31     ? regout_Mhpmevent31 : 64'h0)
    | (hit_mscratch        ? regout_mscratch : 64'h0)
    | (hit_mepc            ? regout_mepc : 64'h0)
    | (hit_mcause          ? regout_mcause : 64'h0)
    | (hit_mtval           ? regout_mtval : 64'h0)
    | (hit_mip             ? regout_mip : 64'h0)
    | (hit_mtinst          ? regout_mtinst : 64'h0)
    | (hit_mtval2          ? regout_mtval2 : 64'h0)
    | (hit_miselect        ? regout_miselect : 64'h0)
    | (hit_mireg           ? regout_mireg : 64'h0)
    | (hit_mtopei          ? regout_mtopei : 64'h0)
    | (hit_pmpcfg_0        ? regout_pmpcfg_0 : 64'h0)
    | (hit_pmpcfg_1        ? regout_pmpcfg_1 : 64'h0)
    | (hit_pmpcfg_2        ? regout_pmpcfg_2 : 64'h0)
    | (hit_pmpcfg_3        ? regout_pmpcfg_3 : 64'h0)
    | (hit_pmpcfg_4        ? regout_pmpcfg_4 : 64'h0)
    | (hit_pmpcfg_5        ? regout_pmpcfg_5 : 64'h0)
    | (hit_pmpcfg_6        ? regout_pmpcfg_6 : 64'h0)
    | (hit_pmpcfg_7        ? regout_pmpcfg_7 : 64'h0)
    | (hit_pmpaddr_0       ? regout_pmpaddr_0 : 64'h0)
    | (hit_pmpaddr_1       ? regout_pmpaddr_1 : 64'h0)
    | (hit_pmpaddr_2       ? regout_pmpaddr_2 : 64'h0)
    | (hit_pmpaddr_3       ? regout_pmpaddr_3 : 64'h0)
    | (hit_pmpaddr_4       ? regout_pmpaddr_4 : 64'h0)
    | (hit_pmpaddr_5       ? regout_pmpaddr_5 : 64'h0)
    | (hit_pmpaddr_6       ? regout_pmpaddr_6 : 64'h0)
    | (hit_pmpaddr_7       ? regout_pmpaddr_7 : 64'h0)
    | (hit_pmpaddr_8       ? regout_pmpaddr_8 : 64'h0)
    | (hit_pmpaddr_9       ? regout_pmpaddr_9 : 64'h0)
    | (hit_pmpaddr_10      ? regout_pmpaddr_10 : 64'h0)
    | (hit_pmpaddr_11      ? regout_pmpaddr_11 : 64'h0)
    | (hit_pmpaddr_12      ? regout_pmpaddr_12 : 64'h0)
    | (hit_pmpaddr_13      ? regout_pmpaddr_13 : 64'h0)
    | (hit_pmpaddr_14      ? regout_pmpaddr_14 : 64'h0)
    | (hit_pmpaddr_15      ? regout_pmpaddr_15 : 64'h0)
    | (hit_pmpaddr_16      ? regout_pmpaddr_16 : 64'h0)
    | (hit_pmpaddr_17      ? regout_pmpaddr_17 : 64'h0)
    | (hit_pmpaddr_18      ? regout_pmpaddr_18 : 64'h0)
    | (hit_pmpaddr_19      ? regout_pmpaddr_19 : 64'h0)
    | (hit_pmpaddr_20      ? regout_pmpaddr_20 : 64'h0)
    | (hit_pmpaddr_21      ? regout_pmpaddr_21 : 64'h0)
    | (hit_pmpaddr_22      ? regout_pmpaddr_22 : 64'h0)
    | (hit_pmpaddr_23      ? regout_pmpaddr_23 : 64'h0)
    | (hit_pmpaddr_24      ? regout_pmpaddr_24 : 64'h0)
    | (hit_pmpaddr_25      ? regout_pmpaddr_25 : 64'h0)
    | (hit_pmpaddr_26      ? regout_pmpaddr_26 : 64'h0)
    | (hit_pmpaddr_27      ? regout_pmpaddr_27 : 64'h0)
    | (hit_pmpaddr_28      ? regout_pmpaddr_28 : 64'h0)
    | (hit_pmpaddr_29      ? regout_pmpaddr_29 : 64'h0)
    | (hit_pmpaddr_30      ? regout_pmpaddr_30 : 64'h0)
    | (hit_pmpaddr_31      ? regout_pmpaddr_31 : 64'h0)
    | (hit_pmpaddr_32      ? regout_pmpaddr_32 : 64'h0)
    | (hit_pmpaddr_33      ? regout_pmpaddr_33 : 64'h0)
    | (hit_pmpaddr_34      ? regout_pmpaddr_34 : 64'h0)
    | (hit_pmpaddr_35      ? regout_pmpaddr_35 : 64'h0)
    | (hit_pmpaddr_36      ? regout_pmpaddr_36 : 64'h0)
    | (hit_pmpaddr_37      ? regout_pmpaddr_37 : 64'h0)
    | (hit_pmpaddr_38      ? regout_pmpaddr_38 : 64'h0)
    | (hit_pmpaddr_39      ? regout_pmpaddr_39 : 64'h0)
    | (hit_pmpaddr_40      ? regout_pmpaddr_40 : 64'h0)
    | (hit_pmpaddr_41      ? regout_pmpaddr_41 : 64'h0)
    | (hit_pmpaddr_42      ? regout_pmpaddr_42 : 64'h0)
    | (hit_pmpaddr_43      ? regout_pmpaddr_43 : 64'h0)
    | (hit_pmpaddr_44      ? regout_pmpaddr_44 : 64'h0)
    | (hit_pmpaddr_45      ? regout_pmpaddr_45 : 64'h0)
    | (hit_pmpaddr_46      ? regout_pmpaddr_46 : 64'h0)
    | (hit_pmpaddr_47      ? regout_pmpaddr_47 : 64'h0)
    | (hit_pmpaddr_48      ? regout_pmpaddr_48 : 64'h0)
    | (hit_pmpaddr_49      ? regout_pmpaddr_49 : 64'h0)
    | (hit_pmpaddr_50      ? regout_pmpaddr_50 : 64'h0)
    | (hit_pmpaddr_51      ? regout_pmpaddr_51 : 64'h0)
    | (hit_pmpaddr_52      ? regout_pmpaddr_52 : 64'h0)
    | (hit_pmpaddr_53      ? regout_pmpaddr_53 : 64'h0)
    | (hit_pmpaddr_54      ? regout_pmpaddr_54 : 64'h0)
    | (hit_pmpaddr_55      ? regout_pmpaddr_55 : 64'h0)
    | (hit_pmpaddr_56      ? regout_pmpaddr_56 : 64'h0)
    | (hit_pmpaddr_57      ? regout_pmpaddr_57 : 64'h0)
    | (hit_pmpaddr_58      ? regout_pmpaddr_58 : 64'h0)
    | (hit_pmpaddr_59      ? regout_pmpaddr_59 : 64'h0)
    | (hit_pmpaddr_60      ? regout_pmpaddr_60 : 64'h0)
    | (hit_pmpaddr_61      ? regout_pmpaddr_61 : 64'h0)
    | (hit_pmpaddr_62      ? regout_pmpaddr_62 : 64'h0)
    | (hit_pmpaddr_63      ? regout_pmpaddr_63 : 64'h0)
    | (hit_scontext        ? regout_scontext : 64'h0)
    | (hit_sbpctl          ? regout_sbpctl : 64'h0)
    | (hit_spfctl          ? regout_spfctl : 64'h0)
    | (hit_slvpredctl      ? regout_slvpredctl : 64'h0)
    | (hit_smblockctl      ? regout_smblockctl : 64'h0)
    | (hit_srnctl          ? regout_srnctl : 64'h0)
    | (hit_hstatus         ? regout_hstatus : 64'h0)
    | (hit_hedeleg         ? regout_hedeleg : 64'h0)
    | (hit_hideleg         ? regout_hideleg : 64'h0)
    | (hit_hie             ? regout_hie : 64'h0)
    | (hit_htimedelta      ? regout_htimedelta : 64'h0)
    | (hit_hcounteren      ? regout_hcounteren : 64'h0)
    | (hit_hgeie           ? regout_hgeie : 64'h0)
    | (hit_hvien           ? regout_hvien : 64'h0)
    | (hit_hvictl          ? regout_hvictl : 64'h0)
    | (hit_henvcfg         ? regout_henvcfg : 64'h0)
    | (hit_hstateen0       ? regout_hstateen0 : 64'h0)
    | (hit_hstateen1       ? regout_hstateen1 : 64'h0)
    | (hit_hstateen2       ? regout_hstateen2 : 64'h0)
    | (hit_hstateen3       ? regout_hstateen3 : 64'h0)
    | (hit_htval           ? regout_htval : 64'h0)
    | (hit_hip             ? regout_hip : 64'h0)
    | (hit_hvip            ? regout_hvip : 64'h0)
    | (hit_hviprio1        ? regout_hviprio1 : 64'h0)
    | (hit_hviprio2        ? regout_hviprio2 : 64'h0)
    | (hit_htinst          ? regout_htinst : 64'h0)
    | (hit_hgatp           ? regout_hgatp : 64'h0)
    | (hit_hcontext        ? regout_hcontext : 64'h0)
    | (hit_mnscratch       ? regout_mnscratch : 64'h0)
    | (hit_mnepc           ? regout_mnepc : 64'h0)
    | (hit_mncause         ? regout_mncause : 64'h0)
    | (hit_mnstatus        ? regout_mnstatus : 64'h0)
    | (hit_mseccfg         ? regout_mseccfg : 64'h0)
    | (hit_tselect         ? regout_tselect : 64'h0)
    | (hit_tdata1          ? regout_tdata1 : 64'h0)
    | (hit_tdata2          ? regout_tdata2 : 64'h0)
    | (hit_tinfo           ? regout_tinfo : 64'h0)
    | (hit_mcontext        ? regout_mcontext : 64'h0)
    | (hit_dcsr            ? regout_dcsr : 64'h0)
    | (hit_dpc             ? regout_dpc : 64'h0)
    | (hit_dscratch0       ? regout_dscratch0 : 64'h0)
    | (hit_dscratch1       ? regout_dscratch1 : 64'h0)
    | (hit_pmacfg_0        ? regout_pmacfg_0 : 64'h0)
    | (hit_pmacfg_1        ? regout_pmacfg_1 : 64'h0)
    | (hit_pmacfg_2        ? regout_pmacfg_2 : 64'h0)
    | (hit_pmacfg_3        ? regout_pmacfg_3 : 64'h0)
    | (hit_pmaaddr_0       ? regout_pmaaddr_0 : 64'h0)
    | (hit_pmaaddr_1       ? regout_pmaaddr_1 : 64'h0)
    | (hit_pmaaddr_2       ? regout_pmaaddr_2 : 64'h0)
    | (hit_pmaaddr_3       ? regout_pmaaddr_3 : 64'h0)
    | (hit_pmaaddr_4       ? regout_pmaaddr_4 : 64'h0)
    | (hit_pmaaddr_5       ? regout_pmaaddr_5 : 64'h0)
    | (hit_pmaaddr_6       ? regout_pmaaddr_6 : 64'h0)
    | (hit_pmaaddr_7       ? regout_pmaaddr_7 : 64'h0)
    | (hit_pmaaddr_8       ? regout_pmaaddr_8 : 64'h0)
    | (hit_pmaaddr_9       ? regout_pmaaddr_9 : 64'h0)
    | (hit_pmaaddr_10      ? regout_pmaaddr_10 : 64'h0)
    | (hit_pmaaddr_11      ? regout_pmaaddr_11 : 64'h0)
    | (hit_pmaaddr_12      ? regout_pmaaddr_12 : 64'h0)
    | (hit_pmaaddr_13      ? regout_pmaaddr_13 : 64'h0)
    | (hit_pmaaddr_14      ? regout_pmaaddr_14 : 64'h0)
    | (hit_pmaaddr_15      ? regout_pmaaddr_15 : 64'h0)
    | (hit_pmaaddr_16      ? regout_pmaaddr_16 : 64'h0)
    | (hit_pmaaddr_17      ? regout_pmaaddr_17 : 64'h0)
    | (hit_pmaaddr_18      ? regout_pmaaddr_18 : 64'h0)
    | (hit_pmaaddr_19      ? regout_pmaaddr_19 : 64'h0)
    | (hit_pmaaddr_20      ? regout_pmaaddr_20 : 64'h0)
    | (hit_pmaaddr_21      ? regout_pmaaddr_21 : 64'h0)
    | (hit_pmaaddr_22      ? regout_pmaaddr_22 : 64'h0)
    | (hit_pmaaddr_23      ? regout_pmaaddr_23 : 64'h0)
    | (hit_pmaaddr_24      ? regout_pmaaddr_24 : 64'h0)
    | (hit_pmaaddr_25      ? regout_pmaaddr_25 : 64'h0)
    | (hit_pmaaddr_26      ? regout_pmaaddr_26 : 64'h0)
    | (hit_pmaaddr_27      ? regout_pmaaddr_27 : 64'h0)
    | (hit_pmaaddr_28      ? regout_pmaaddr_28 : 64'h0)
    | (hit_pmaaddr_29      ? regout_pmaaddr_29 : 64'h0)
    | (hit_pmaaddr_30      ? regout_pmaaddr_30 : 64'h0)
    | (hit_pmaaddr_31      ? regout_pmaaddr_31 : 64'h0)
    | (hit_mcycle          ? regout_mcycle : 64'h0)
    | (hit_minstret        ? regout_minstret : 64'h0)
    | (hit_mhpmcounters_0  ? regout_mhpmcounters_0 : 64'h0)
    | (hit_mhpmcounters_1  ? regout_mhpmcounters_1 : 64'h0)
    | (hit_mhpmcounters_2  ? regout_mhpmcounters_2 : 64'h0)
    | (hit_mhpmcounters_3  ? regout_mhpmcounters_3 : 64'h0)
    | (hit_mhpmcounters_4  ? regout_mhpmcounters_4 : 64'h0)
    | (hit_mhpmcounters_5  ? regout_mhpmcounters_5 : 64'h0)
    | (hit_mhpmcounters_6  ? regout_mhpmcounters_6 : 64'h0)
    | (hit_mhpmcounters_7  ? regout_mhpmcounters_7 : 64'h0)
    | (hit_mhpmcounters_8  ? regout_mhpmcounters_8 : 64'h0)
    | (hit_mhpmcounters_9  ? regout_mhpmcounters_9 : 64'h0)
    | (hit_mhpmcounters_10 ? regout_mhpmcounters_10 : 64'h0)
    | (hit_mhpmcounters_11 ? regout_mhpmcounters_11 : 64'h0)
    | (hit_mhpmcounters_12 ? regout_mhpmcounters_12 : 64'h0)
    | (hit_mhpmcounters_13 ? regout_mhpmcounters_13 : 64'h0)
    | (hit_mhpmcounters_14 ? regout_mhpmcounters_14 : 64'h0)
    | (hit_mhpmcounters_15 ? regout_mhpmcounters_15 : 64'h0)
    | (hit_mhpmcounters_16 ? regout_mhpmcounters_16 : 64'h0)
    | (hit_mhpmcounters_17 ? regout_mhpmcounters_17 : 64'h0)
    | (hit_mhpmcounters_18 ? regout_mhpmcounters_18 : 64'h0)
    | (hit_mhpmcounters_19 ? regout_mhpmcounters_19 : 64'h0)
    | (hit_mhpmcounters_20 ? regout_mhpmcounters_20 : 64'h0)
    | (hit_mhpmcounters_21 ? regout_mhpmcounters_21 : 64'h0)
    | (hit_mhpmcounters_22 ? regout_mhpmcounters_22 : 64'h0)
    | (hit_mhpmcounters_23 ? regout_mhpmcounters_23 : 64'h0)
    | (hit_mhpmcounters_24 ? regout_mhpmcounters_24 : 64'h0)
    | (hit_mhpmcounters_25 ? regout_mhpmcounters_25 : 64'h0)
    | (hit_mhpmcounters_26 ? regout_mhpmcounters_26 : 64'h0)
    | (hit_mhpmcounters_27 ? regout_mhpmcounters_27 : 64'h0)
    | (hit_mhpmcounters_28 ? regout_mhpmcounters_28 : 64'h0)
    | (hit_mcorepwr        ? regout_mcorepwr : 64'h0)
    | (hit_mflushpwr       ? regout_mflushpwr : 64'h0)
    | (hit_mbmc            ? regout_mbmc : 64'h0);

  // ==========================================================================
  // 6. 退休提交信息打一拍（ROB -> CSR）
  //    Scala 对每个带 HasRobCommitBundle 的 CSR 模块各 RegNext 一次，所以 mstatus / vsstatus /
  //    vstart 各有一套（功能相同）；valid 类带复位，数据类只在 valid 时更新、不复位。
  // ==========================================================================
  logic       mstatus_cmt_fs_dirty_q,  mstatus_cmt_vs_dirty_q,  mstatus_cmt_vstart_valid_q;
  logic       vsstatus_cmt_fs_dirty_q, vsstatus_cmt_vs_dirty_q, vsstatus_cmt_vstart_valid_q;
  logic       vstart_cmt_vs_dirty_q,   vstart_cmt_vstart_valid_q;
  logic [6:0] mstatus_cmt_vstart_bits_q, vsstatus_cmt_vstart_bits_q, vstart_cmt_vstart_bits_q;
  logic       fcsr_cmt_fflags_valid_q;
  logic [4:0] fcsr_cmt_fflags_bits_q;
  logic       vcsr_cmt_vxsat_valid_q;
  logic       vcsr_cmt_vxsat_bits_q;
  logic       vtype_cmt_valid_q;
  logic       vtype_cmt_vill_q, vtype_cmt_vma_q, vtype_cmt_vta_q;
  logic [2:0] vtype_cmt_vsew_q, vtype_cmt_vlmul_q;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      mstatus_cmt_fs_dirty_q      <= 1'b0;
      mstatus_cmt_vs_dirty_q      <= 1'b0;
      mstatus_cmt_vstart_valid_q  <= 1'b0;
      vsstatus_cmt_fs_dirty_q     <= 1'b0;
      vsstatus_cmt_vs_dirty_q     <= 1'b0;
      vsstatus_cmt_vstart_valid_q <= 1'b0;
      vstart_cmt_vs_dirty_q       <= 1'b0;
      vstart_cmt_vstart_valid_q   <= 1'b0;
      fcsr_cmt_fflags_valid_q     <= 1'b0;
      vcsr_cmt_vxsat_valid_q      <= 1'b0;
      vtype_cmt_valid_q           <= 1'b0;
    end
    else begin
      mstatus_cmt_fs_dirty_q      <= io_fromRob_commit_fsDirty;
      mstatus_cmt_vs_dirty_q      <= io_fromRob_commit_vsDirty;
      mstatus_cmt_vstart_valid_q  <= io_fromRob_commit_vstart_valid;
      vsstatus_cmt_fs_dirty_q     <= io_fromRob_commit_fsDirty;
      vsstatus_cmt_vs_dirty_q     <= io_fromRob_commit_vsDirty;
      vsstatus_cmt_vstart_valid_q <= io_fromRob_commit_vstart_valid;
      vstart_cmt_vs_dirty_q       <= io_fromRob_commit_vsDirty;
      vstart_cmt_vstart_valid_q   <= io_fromRob_commit_vstart_valid;
      fcsr_cmt_fflags_valid_q     <= io_fromRob_commit_fflags_valid;
      vcsr_cmt_vxsat_valid_q      <= io_fromRob_commit_vxsat_valid;
      vtype_cmt_valid_q           <= io_fromRob_commit_vtype_valid;
    end
  end

  always @(posedge clock) begin
    if (io_fromRob_commit_vstart_valid) begin
      mstatus_cmt_vstart_bits_q  <= io_fromRob_commit_vstart_bits;
      vsstatus_cmt_vstart_bits_q <= io_fromRob_commit_vstart_bits;
      vstart_cmt_vstart_bits_q   <= io_fromRob_commit_vstart_bits;
    end
    if (io_fromRob_commit_fflags_valid)
      fcsr_cmt_fflags_bits_q <= io_fromRob_commit_fflags_bits;
    if (io_fromRob_commit_vxsat_valid)
      vcsr_cmt_vxsat_bits_q <= io_fromRob_commit_vxsat_bits;
    if (io_fromRob_commit_vtype_valid) begin
      vtype_cmt_vill_q  <= io_fromRob_commit_vtype_bits_VILL;
      vtype_cmt_vma_q   <= io_fromRob_commit_vtype_bits_VMA;
      vtype_cmt_vta_q   <= io_fromRob_commit_vtype_bits_VTA;
      vtype_cmt_vsew_q  <= io_fromRob_commit_vtype_bits_VSEW;
      vtype_cmt_vlmul_q <= io_fromRob_commit_vtype_bits_VLMUL;
    end
  end

  // FS/VS 为 Off（送权限检查与译码）
  wire mstatus_fs_off  = mstatus_regOut_FS  == 2'h0;
  wire mstatus_vs_off  = mstatus_regOut_VS  == 2'h0;
  wire vsstatus_fs_off = vsstatus_regOut_FS == 2'h0;
  wire vsstatus_vs_off = vsstatus_regOut_VS == 2'h0;

  // ==========================================================================
  // 7. 中断
  // ==========================================================================
  // NMI 输入打一拍；任一 NMI 挂起即 nmi_pending
  logic nmip_31_q, nmip_43_q;
  wire  nmi_pending = nmip_43_q | nmip_31_q;

  // InterruptFilter 的结果在 interruptVec.valid 时锁存，trap 进入时用
  logic [7:0] intr_vec_q;
  logic       intr_is_debug_q;
  logic       ir_to_hs_q;
  logic       ir_to_vs_q;

  // Sstc：stimecmp/vstimecmp/menvcfg/henvcfg/htimedelta 写之后一拍通知 SstcInterruptGen 重算
  logic sstc_stimecmp_wen_q, sstc_vstimecmp_wen_q, sstc_menvcfg_wen_q, sstc_henvcfg_wen_q;
  logic sstc_htimedelta_wen_q;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      nmip_31_q             <= 1'b0;
      nmip_43_q             <= 1'b0;
      intr_vec_q            <= 8'h0;
      intr_is_debug_q       <= 1'b0;
      ir_to_hs_q            <= 1'b0;
      ir_to_vs_q            <= 1'b0;
      sstc_stimecmp_wen_q   <= 1'b0;
      sstc_vstimecmp_wen_q  <= 1'b0;
      sstc_menvcfg_wen_q    <= 1'b0;
      sstc_henvcfg_wen_q    <= 1'b0;
      sstc_htimedelta_wen_q <= 1'b0;
    end
    else begin
      nmip_31_q <= nonMaskableIRP_NMI_31;
      nmip_43_q <= nonMaskableIRP_NMI_43;
      if (intrMod_io_out_interruptVec_valid) begin
        intr_vec_q      <= intrMod_io_out_interruptVec_bits;
        intr_is_debug_q <= intrMod_io_out_debug;
        ir_to_hs_q      <= intrMod_io_out_irToHS;
        ir_to_vs_q      <= intrMod_io_out_irToVS;
      end
      sstc_stimecmp_wen_q   <= wen_stimecmp;
      sstc_vstimecmp_wen_q  <= wen_vstimecmp;
      sstc_menvcfg_wen_q    <= wen_menvcfg;
      sstc_henvcfg_wen_q    <= wen_henvcfg;
      sstc_htimedelta_wen_q <= wen_htimedelta;
    end
  end

  // ==========================================================================
  // 8. 硬件性能计数器（mhpmcounter3..31 ↔ 实例 mhpmcounters_0..28，事件寄存器 Mhpmevent3..31）
  // ==========================================================================
  // 计数使能：当前特权态没有被对应 mhpmevent 的 xINH 位禁止（MINH=62 SINH=61 UINH=60
  // VSINH=59 VUINH=58），打一拍
  wire [63:0] mhpmevent_rdata [0:28];
  wire [28:0] counter_overflow;        // 计数器本拍溢出（送 mhpmevent.OF）
  assign mhpmevent_rdata[0]  = Mhpmevent3_rdata;
  assign mhpmevent_rdata[1]  = Mhpmevent4_rdata;
  assign mhpmevent_rdata[2]  = Mhpmevent5_rdata;
  assign mhpmevent_rdata[3]  = Mhpmevent6_rdata;
  assign mhpmevent_rdata[4]  = Mhpmevent7_rdata;
  assign mhpmevent_rdata[5]  = Mhpmevent8_rdata;
  assign mhpmevent_rdata[6]  = Mhpmevent9_rdata;
  assign mhpmevent_rdata[7]  = Mhpmevent10_rdata;
  assign mhpmevent_rdata[8]  = Mhpmevent11_rdata;
  assign mhpmevent_rdata[9]  = Mhpmevent12_rdata;
  assign mhpmevent_rdata[10] = Mhpmevent13_rdata;
  assign mhpmevent_rdata[11] = Mhpmevent14_rdata;
  assign mhpmevent_rdata[12] = Mhpmevent15_rdata;
  assign mhpmevent_rdata[13] = Mhpmevent16_rdata;
  assign mhpmevent_rdata[14] = Mhpmevent17_rdata;
  assign mhpmevent_rdata[15] = Mhpmevent18_rdata;
  assign mhpmevent_rdata[16] = Mhpmevent19_rdata;
  assign mhpmevent_rdata[17] = Mhpmevent20_rdata;
  assign mhpmevent_rdata[18] = Mhpmevent21_rdata;
  assign mhpmevent_rdata[19] = Mhpmevent22_rdata;
  assign mhpmevent_rdata[20] = Mhpmevent23_rdata;
  assign mhpmevent_rdata[21] = Mhpmevent24_rdata;
  assign mhpmevent_rdata[22] = Mhpmevent25_rdata;
  assign mhpmevent_rdata[23] = Mhpmevent26_rdata;
  assign mhpmevent_rdata[24] = Mhpmevent27_rdata;
  assign mhpmevent_rdata[25] = Mhpmevent28_rdata;
  assign mhpmevent_rdata[26] = Mhpmevent29_rdata;
  assign mhpmevent_rdata[27] = Mhpmevent30_rdata;
  assign mhpmevent_rdata[28] = Mhpmevent31_rdata;
  assign counter_overflow = {
    mhpmcounters_28_toMhpmeventOF, mhpmcounters_27_toMhpmeventOF, mhpmcounters_26_toMhpmeventOF,
    mhpmcounters_25_toMhpmeventOF, mhpmcounters_24_toMhpmeventOF, mhpmcounters_23_toMhpmeventOF,
    mhpmcounters_22_toMhpmeventOF, mhpmcounters_21_toMhpmeventOF, mhpmcounters_20_toMhpmeventOF,
    mhpmcounters_19_toMhpmeventOF, mhpmcounters_18_toMhpmeventOF, mhpmcounters_17_toMhpmeventOF,
    mhpmcounters_16_toMhpmeventOF, mhpmcounters_15_toMhpmeventOF, mhpmcounters_14_toMhpmeventOF,
    mhpmcounters_13_toMhpmeventOF, mhpmcounters_12_toMhpmeventOF, mhpmcounters_11_toMhpmeventOF,
    mhpmcounters_10_toMhpmeventOF, mhpmcounters_9_toMhpmeventOF,  mhpmcounters_8_toMhpmeventOF,
    mhpmcounters_7_toMhpmeventOF,  mhpmcounters_6_toMhpmeventOF,  mhpmcounters_5_toMhpmeventOF,
    mhpmcounters_4_toMhpmeventOF,  mhpmcounters_3_toMhpmeventOF,  mhpmcounters_2_toMhpmeventOF,
    mhpmcounters_1_toMhpmeventOF,  mhpmcounters_0_toMhpmeventOF};

  logic [28:0] counting_en;
  wire  [28:0] counting_en_next;
  wire  [28:0] lcofi_req_vec;          // 溢出且 OF 尚未置位 -> 请求本地计数器溢出中断
  for (genvar k = 0; k < 29; k++) begin : g_hpm
    wire [63:0] ev = mhpmevent_rdata[k];
    assign counting_en_next[k] = mode_m & ~ev[62] | mode_hs & ~ev[61] | mode_hu & ~ev[60]
                               | mode_vs & ~ev[59] | mode_vu & ~ev[58];
    assign lcofi_req_vec[k] = counter_overflow[k] & ~ev[63];
  end
  always @(posedge clock or posedge reset) begin
    if (reset)
      counting_en <= 29'h0;
    else
      counting_en <= counting_en_next;
  end
  wire lcofi_req = |lcofi_req_vec;

  // ==========================================================================
  // 9. trap 进入事件
  //    TrapHandleModule 算出 trap 进入哪个特权态（entryPrivState）；NMI / 双重 trap 走 MN；
  //    将进入 debug 或已在 debug 时，普通 trap 事件都不生效；mnstatus.NMIE=0 时也不生效。
  // ==========================================================================
  wire entry_m  = trapHandleMod_io_out_entryPrivState_PRVM == 2'h3;
  wire entry_hs = ~trapHandleMod_io_out_entryPrivState_V & trapHandleMod_io_out_entryPrivState_PRVM == 2'h1;
  wire entry_vs =  trapHandleMod_io_out_entryPrivState_V & trapHandleMod_io_out_entryPrivState_PRVM == 2'h1;
  wire trap_ok  = ~entry_debug_mode & ~debug_mode & mnstatus_regOut_NMIE;   // 公共放行条件

  wire valid_trapEntryMNEvent =
    (io_fromRob_trap_valid & intrMod_io_out_nmi | trapHandleMod_io_out_dbltrpToMN) & trap_ok;
  wire valid_trapEntryMEvent  = io_fromRob_trap_valid & entry_m & ~trapHandleMod_io_out_dbltrpToMN
                              & ~intrMod_io_out_nmi & trap_ok;
  wire valid_trapEntryHSEvent = io_fromRob_trap_valid & entry_hs & ~intrMod_io_out_nmi & trap_ok;
  wire valid_trapEntryVSEvent = io_fromRob_trap_valid & entry_vs & ~intrMod_io_out_nmi & trap_ok;

  // 取指相关的特权态：satp 刷新后第一条取指异常要用"旧"特权态 / 旧 satp.MODE
  wire       flush_first_fetch   = io_fromRob_trap_bits_satpFlushFirstFetchFault;
  wire [1:0] trap_imode_prvm     = flush_first_fetch ? io_oldPrivSate_PRVM : prvm;
  wire       trap_imode_v        = flush_first_fetch ? io_oldPrivSate_V    : virt;
  wire [3:0] trap_old_satp_mode  = flush_first_fetch ? io_oldSatpMode  : satp_regOut_MODE;
  wire [3:0] trap_old_vsatp_mode = flush_first_fetch ? io_oldVsatpMode : vsatp_regOut_MODE;
  // 访存相关的虚拟化位：MPRV 生效（且 NMIE=1）且 MPP != M 时取 MPV
  wire       trap_dmode_v        = virt | mstatus_regOut_MPRV & mnstatus_regOut_NMIE
                                        & mstatus_regOut_MPP != 2'h3 & mstatus_regOut_MPV;
  // 单步只对非中断的 trap 有意义
  wire       trap_single_step    = io_fromRob_trap_valid & ~io_fromRob_trap_bits_isInterrupt
                                 & io_fromRob_trap_bits_singleStep;

  // xRET 请求（送权限检查）
  wire permit_ren = ren & io_in_valid;
  wire xret_mnret = io_in_bits_mnret & io_in_valid;
  wire xret_mret  = io_in_bits_mret  & io_in_valid;
  wire xret_sret  = io_in_bits_sret  & io_in_valid;
  wire xret_dret  = io_in_bits_dret  & io_in_valid;

  // ==========================================================================
  // 10. 触发器链
  // ==========================================================================
  // 第 k 个触发器能否写 DMODE：前一个触发器若 chain=1，则要求前一个 DMODE=1 且类型合法
  // （mcontrol6，type=6）；第 0 个只看 debug 模式。tdata1 的 TYPE=[63:60] DMODE=[59] CHAIN=[11]
  function automatic logic can_write_dmode(input logic [63:0] prev_tdata1, input logic dbg);
    can_write_dmode = (~prev_tdata1[11] | prev_tdata1[59] & prev_tdata1[63:60] == 4'h6) & dbg;
  endfunction
  // 后一个触发器是否是合法的 DMODE 触发器
  function automatic logic dmode_trigger(input logic [63:0] t);
    dmode_trigger = t[63:60] == 4'h6 & t[59];
  endfunction
  wire trigger_can_write_dmode_1 = can_write_dmode(tdata1RegVec_0_rdata, debug_mode);
  wire trigger_can_write_dmode_2 = can_write_dmode(tdata1RegVec_1_rdata, debug_mode);
  wire trigger_can_write_dmode_3 = can_write_dmode(tdata1RegVec_2_rdata, debug_mode);
  wire trigger_dmode_next_0      = dmode_trigger(tdata1RegVec_1_rdata);
  wire trigger_dmode_next_1      = dmode_trigger(tdata1RegVec_2_rdata);
  wire trigger_dmode_next_2      = dmode_trigger(tdata1RegVec_3_rdata);

  // 断点异常能否在当前态被处理（否则 M 态 MIE=0 等情况下断点不能产生异常）
  wire trigger_can_raise_bp_exp =
    ~(mode_m & ~mstatus_regOut_MIE
      | medeleg_regOut_EX_BP & mode_hs & ~mstatus_sstatus_SIE
      | medeleg_regOut_EX_BP & hedeleg_regOut_EX_BP & mode_vs & ~vsstatus_regOut_SIE);

  // ==========================================================================
  // 11. 请求处理状态机
  //     IDLE：接收请求。普通 CSR 当拍出结果 -> FINISH；访问 IMSIC 间接寄存器（*ireg 且
  //           *iselect 落在 IMSIC 窗口）要等 AIA 回数 -> WAIT_IMSIC。
  //     WAIT_IMSIC：AIA 回数时，下游 ready 则直接回 IDLE，否则去 FINISH 等 ready。
  //     FINISH：输出有效，等下游 ready。任何状态遇到 redirectFlush 都回 IDLE。
  // ==========================================================================
  localparam logic [1:0] S_IDLE = 2'h0, S_WAIT_IMSIC = 2'h1, S_FINISH = 2'h2;
  logic [1:0] state;
  logic [1:0] state_next;

  wire async_access = (wen | ren) & ~(permitMod_io_out_EX_II | permitMod_io_out_EX_VI)
                    & (addr == 12'h351 & miselect_inIMSICRange
                       | addr == 12'h151 & (~virt & siselect_inIMSICRange | virt & vsiselect_inIMSICRange)
                       | addr == 12'h251 & vsiselect_inIMSICRange);

  always_comb begin
    state_next = state;
    case (state)
      S_IDLE:
        if (io_in_valid & io_in_bits_redirectFlush)
          state_next = S_IDLE;
        else if (io_in_valid & async_access)
          state_next = S_WAIT_IMSIC;
        else if (io_in_valid)
          state_next = S_FINISH;
      S_WAIT_IMSIC:
        if (io_in_bits_redirectFlush)
          state_next = S_IDLE;
        else if (fromAIA_rdata_valid)
          state_next = io_out_ready ? S_IDLE : S_FINISH;
      S_FINISH:
        if (io_in_bits_redirectFlush | io_out_ready)
          state_next = S_IDLE;
      default: ;
    endcase
  end

  wire in_fire        = state == S_IDLE & io_in_valid;          // io.in.fire（ready = IDLE）
  wire normal_valid   = in_fire & ~async_access;                 // 普通 CSR 当拍出结果
  wire wait_valid     = state == S_WAIT_IMSIC & fromAIA_rdata_valid;
  wire imsic_illegal  = fromAIA_rdata_valid & fromAIA_rdata_bits_illegal;
  // 写 *topei 是"认领"中断，读出的是认领前的值，所以这拍也要锁 rdata
  wire claim_aia      = wen_mtopei | wen_stopei | wen_vstopei;

  // ---- 输出保持（DataHoldBypass：使能拍直通新值，其余拍输出上次锁存值）----
  wire        ex_hold_en   = normal_valid | wait_valid;
  wire        ex_ii_now    = normal_valid & (permitMod_io_out_EX_II | no_csr_illegal)
                           | wait_valid & imsic_illegal & ~virt;
  wire        ex_vi_now    = normal_valid & permitMod_io_out_EX_VI
                           | wait_valid & imsic_illegal & virt;
  wire        rdata_hold_en = in_fire | fromAIA_rdata_valid | claim_aia;
  wire [63:0] rdata_now    = (in_fire | claim_aia ? rdata : 64'h0)
                           | (fromAIA_rdata_valid ? fromAIA_rdata_bits_data : 64'h0);

  // 本次访问是否是性能计数器（mhpmcounter/hpmcounter 窗口，或读 *topi/*topei）
  wire addr_in_perf_cnt =
      (permitMod_io_out_hasLegalWen | ren)
      & (addr > 12'hAFF & addr < 12'hB20 | addr > 12'hBFF & addr < 12'hC20)
    | ren & (addr == 12'hEB0 | addr == 12'h25C | addr == 12'hDB0 | addr == 12'h15C
             | addr == 12'hFB0 | addr == 12'h35C);

  logic        ex_ii_q, ex_vi_q;
  logic [63:0] rdata_q;
  logic        is_perf_cnt_q;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      state         <= S_IDLE;
      ex_ii_q       <= 1'b0;
      ex_vi_q       <= 1'b0;
      rdata_q       <= 64'h0;
      is_perf_cnt_q <= 1'b0;
    end
    else begin
      state <= state_next;
      if (ex_hold_en) begin
        ex_ii_q <= ex_ii_now;
        ex_vi_q <= ex_vi_now;
      end
      if (rdata_hold_en)
        rdata_q <= rdata_now;
      if (in_fire)
        is_perf_cnt_q <= addr_in_perf_cnt;
    end
  end

  assign io_in_ready           = state == S_IDLE;
  assign io_out_valid          = (wait_valid | state == S_FINISH) & ~io_in_bits_redirectFlush;
  assign io_out_bits_EX_II     = ex_hold_en ? ex_ii_now : ex_ii_q;
  assign io_out_bits_EX_VI     = ex_hold_en ? ex_vi_now : ex_vi_q;
  assign io_out_bits_rData     = rdata_hold_en ? rdata_now : rdata_q;
  assign io_out_bits_isPerfCnt = in_fire ? addr_in_perf_cnt : is_perf_cnt_q;

  // ---- 跳转目标：trap 进入 / xRET 给出新 PC。进 debug 优先，其余至多一个有效（独热或）----
  wire need_target_update =
      mnretEvent_out_targetPc_valid | mretEvent_out_targetPc_valid | sretEvent_out_targetPc_valid
    | dretEvent_out_targetPc_valid | trapEntryMEvent_out_targetPc_valid
    | trapEntryMNEvent_out_targetPc_valid | trapEntryHSEvent_out_targetPc_valid
    | trapEntryVSEvent_out_targetPc_valid | trapEntryDEvent_out_targetPc_valid;

  logic [63:0] target_pc_now;
  logic        target_ipf_now, target_iaf_now, target_igpf_now;
  always_comb begin
    if (trapEntryDEvent_out_targetPc_valid) begin
      target_pc_now   = trapEntryDEvent_out_targetPc_bits_pc;
      target_ipf_now  = trapEntryDEvent_out_targetPc_bits_raiseIPF;
      target_iaf_now  = trapEntryDEvent_out_targetPc_bits_raiseIAF;
      target_igpf_now = trapEntryDEvent_out_targetPc_bits_raiseIGPF;
    end
    else begin
      target_pc_now =
          (mnretEvent_out_targetPc_valid       ? mnretEvent_out_targetPc_bits_pc       : 64'h0)
        | (mretEvent_out_targetPc_valid        ? mretEvent_out_targetPc_bits_pc        : 64'h0)
        | (sretEvent_out_targetPc_valid        ? sretEvent_out_targetPc_bits_pc        : 64'h0)
        | (dretEvent_out_targetPc_valid        ? dretEvent_out_targetPc_bits_pc        : 64'h0)
        | (trapEntryMEvent_out_targetPc_valid  ? trapEntryMEvent_out_targetPc_bits_pc  : 64'h0)
        | (trapEntryMNEvent_out_targetPc_valid ? trapEntryMNEvent_out_targetPc_bits_pc : 64'h0)
        | (trapEntryHSEvent_out_targetPc_valid ? trapEntryHSEvent_out_targetPc_bits_pc : 64'h0)
        | (trapEntryVSEvent_out_targetPc_valid ? trapEntryVSEvent_out_targetPc_bits_pc : 64'h0);
      target_ipf_now =
          mnretEvent_out_targetPc_valid       & mnretEvent_out_targetPc_bits_raiseIPF
        | mretEvent_out_targetPc_valid        & mretEvent_out_targetPc_bits_raiseIPF
        | sretEvent_out_targetPc_valid        & sretEvent_out_targetPc_bits_raiseIPF
        | dretEvent_out_targetPc_valid        & dretEvent_out_targetPc_bits_raiseIPF
        | trapEntryMEvent_out_targetPc_valid  & trapEntryMEvent_out_targetPc_bits_raiseIPF
        | trapEntryMNEvent_out_targetPc_valid & trapEntryMNEvent_out_targetPc_bits_raiseIPF
        | trapEntryHSEvent_out_targetPc_valid & trapEntryHSEvent_out_targetPc_bits_raiseIPF
        | trapEntryVSEvent_out_targetPc_valid & trapEntryVSEvent_out_targetPc_bits_raiseIPF;
      target_iaf_now =
          mnretEvent_out_targetPc_valid       & mnretEvent_out_targetPc_bits_raiseIAF
        | mretEvent_out_targetPc_valid        & mretEvent_out_targetPc_bits_raiseIAF
        | sretEvent_out_targetPc_valid        & sretEvent_out_targetPc_bits_raiseIAF
        | dretEvent_out_targetPc_valid        & dretEvent_out_targetPc_bits_raiseIAF
        | trapEntryMEvent_out_targetPc_valid  & trapEntryMEvent_out_targetPc_bits_raiseIAF
        | trapEntryMNEvent_out_targetPc_valid & trapEntryMNEvent_out_targetPc_bits_raiseIAF
        | trapEntryHSEvent_out_targetPc_valid & trapEntryHSEvent_out_targetPc_bits_raiseIAF
        | trapEntryVSEvent_out_targetPc_valid & trapEntryVSEvent_out_targetPc_bits_raiseIAF;
      target_igpf_now =
          mnretEvent_out_targetPc_valid       & mnretEvent_out_targetPc_bits_raiseIGPF
        | mretEvent_out_targetPc_valid        & mretEvent_out_targetPc_bits_raiseIGPF
        | sretEvent_out_targetPc_valid        & sretEvent_out_targetPc_bits_raiseIGPF
        | dretEvent_out_targetPc_valid        & dretEvent_out_targetPc_bits_raiseIGPF
        | trapEntryMEvent_out_targetPc_valid  & trapEntryMEvent_out_targetPc_bits_raiseIGPF
        | trapEntryMNEvent_out_targetPc_valid & trapEntryMNEvent_out_targetPc_bits_raiseIGPF
        | trapEntryHSEvent_out_targetPc_valid & trapEntryHSEvent_out_targetPc_bits_raiseIGPF
        | trapEntryVSEvent_out_targetPc_valid & trapEntryVSEvent_out_targetPc_bits_raiseIGPF;
    end
  end

  logic [63:0] target_pc_q;       // 不复位（golden 同）
  logic        target_ipf_q, target_iaf_q, target_igpf_q;
  always @(posedge clock) begin
    if (need_target_update) begin
      target_pc_q   <= target_pc_now;
      target_ipf_q  <= target_ipf_now;
      target_iaf_q  <= target_iaf_now;
      target_igpf_q <= target_igpf_now;
    end
  end
  assign io_out_bits_targetPcUpdate     = need_target_update;
  assign io_out_bits_targetPc_pc        = need_target_update ? target_pc_now   : target_pc_q;
  assign io_out_bits_targetPc_raiseIPF  = need_target_update ? target_ipf_now  : target_ipf_q;
  assign io_out_bits_targetPc_raiseIAF  = need_target_update ? target_iaf_now  : target_iaf_q;
  assign io_out_bits_targetPc_raiseIGPF = need_target_update ? target_igpf_now : target_igpf_q;

  // ---- flushPipe：会改变取指/执行语义的 CSR 写要冲刷流水线 ----
  // 写 satp/vsatp/hgatp/mbmc（按原始地址判，不区分 VS 重定向）
  wire reset_satp = wen_legal_q & (addr == 12'h180 | addr == 12'h280 | addr == 12'h680
                                   | addr == 12'hBC2);
  // FS/VS 在 Off 与非 Off 之间切换（mstatus / sstatus 别名 / vsstatus 三个写口）
  function automatic logic on_off_change(input logic [1:0] new_v, input logic [1:0] old_v);
    on_off_change = new_v == 2'h0 & old_v != 2'h0 | new_v != 2'h0 & old_v == 2'h0;
  endfunction
  wire float_status_on_off  = wen_mstatus  & on_off_change(wdata[14:13], mstatus_regOut_FS)
                            | wen_sstatus  & on_off_change(wdata[14:13], mstatus_regOut_FS)
                            | wen_vsstatus & on_off_change(wdata[14:13], vsstatus_regOut_FS);
  wire vector_status_on_off = wen_mstatus  & on_off_change(wdata[10:9], mstatus_regOut_VS)
                            | wen_sstatus  & on_off_change(wdata[10:9], mstatus_regOut_VS)
                            | wen_vsstatus & on_off_change(wdata[10:9], vsstatus_regOut_VS);
  // vstart 在 0 与非 0 之间切换
  wire vstart_change = wen_vstart & (wdata == 64'h0 & vstart_regOut_vstart != 7'h0
                                     | wdata != 64'h0 & vstart_regOut_vstart == 7'h0);
  // frm 在保留值（5/6/7）与合法值之间切换（写 frm 看 wdata[2:0]，写 fcsr 看 wdata[7:5]）
  wire frm_is_reserved     = fcsr_frm[2] & (|fcsr_frm[1:0]);
  wire frm_wdata_reserved  = wdata[2] & (|wdata[1:0]);
  wire fcsr_wdata_reserved = wdata[7] & (|wdata[6:5]);
  wire frm_change = wen_frm  & (frm_is_reserved ^ frm_wdata_reserved)
                  | wen_fcsr & (frm_is_reserved ^ fcsr_wdata_reserved);

  assign io_out_bits_flushPipe = reset_satp | debugMod_io_out_triggerFrontendChange
                               | float_status_on_off | vector_status_on_off | vstart_change
                               | frm_change;

  // ==========================================================================
  // 12. 状态输出
  // ==========================================================================
  wire single_step_flag = ~debug_mode & dcsr_regOut_STEP;

  assign io_status_privState_PRVM  = prvm;
  assign io_status_privState_V     = virt;
  assign io_status_interrupt       = intrMod_io_out_interruptVec_valid;
  // WFI 唤醒：任何挂起的中断（含未使能的）
  assign io_status_wfiEvent        = debug_intr | nmi_pending | (|mtopi_regOut_IID)
                                   | (|stopi_regOut_IID) | (|vstopi_regOut_IID);
  assign io_status_satp_valid      = wen_satp;
  assign io_status_satp_bits       = satp_regOut_MODE;
  assign io_status_vsatp_valid     = wen_vsatp;
  assign io_status_vsatp_bits      = vsatp_regOut_MODE;
  assign io_status_fpState_frm     = fcsr_frm;
  assign io_status_vecState_vstart = vstart_rdata[6:0];
  assign io_status_vecState_vxrm   = vcsr_vxrm;
  assign io_status_singleStepFlag  = single_step_flag;

  // 取指地址翻译方式（恰好一个为 1）。satp/vsatp MODE: 0=Bare 8=Sv39 9=Sv48；hgatp 8=Sv39x4 9=Sv48x4
  wire satp_bare  = satp_regOut_MODE  == 4'h0;
  wire vsatp_bare = vsatp_regOut_MODE == 4'h0;
  assign io_status_instrAddrTransType_bare   = mode_m | ~virt & satp_bare
                                             | virt & vsatp_bare & hgatp_regOut_MODE == 4'h0;
  assign io_status_instrAddrTransType_sv39   = ~mode_m & ~virt & satp_regOut_MODE == 4'h8
                                             | virt & vsatp_regOut_MODE == 4'h8;
  assign io_status_instrAddrTransType_sv48   = ~mode_m & ~virt & satp_regOut_MODE == 4'h9
                                             | virt & vsatp_regOut_MODE == 4'h9;
  assign io_status_instrAddrTransType_sv39x4 = virt & vsatp_bare & hgatp_regOut_MODE == 4'h8;
  assign io_status_instrAddrTransType_sv48x4 = virt & vsatp_bare & hgatp_regOut_MODE == 4'h9;

  // trace：当前/上一次特权级编码（D=4 M=3 HS=1 VS=6 VU=5 HU=0）
  wire [2:0] priv_for_trace =
    debug_mode ? 3'h4
               : {1'b0, mode_m, mode_m | mode_hs} | (mode_vs ? 3'h6 : 3'h0) | (mode_vu ? 3'h5 : 3'h0);
  logic [2:0] last_priv;
  always @(posedge clock or posedge reset) begin
    if (reset)
      last_priv <= 3'h3;
    else if (permitMod_io_out_hasLegalDret | permitMod_io_out_hasLegalMNret
             | permitMod_io_out_hasLegalMret | permitMod_io_out_hasLegalSret
             | io_fromRob_trap_valid)
      last_priv <= priv_for_trace;
  end
  assign io_status_traceCSR_cause = (mode_m  ? mcause_rdata  : 64'h0)
                                  | (mode_hs ? scause_rdata  : 64'h0)
                                  | (mode_vs ? vscause_rdata : 64'h0);
  assign io_status_traceCSR_tval  = (mode_m  ? mtval_rdata[49:0]  : 50'h0)
                                  | (mode_hs ? stval_rdata[49:0]  : 50'h0)
                                  | (mode_vs ? vstval_rdata[49:0] : 50'h0);
  assign io_status_traceCSR_mstatus     = regout_mstatus;
  assign io_status_traceCSR_lastPriv    = last_priv;
  assign io_status_traceCSR_currentPriv = priv_for_trace;

  // 自定义 CSR 控制位（直接取字段）
  assign io_status_custom_pf_ctrl_l1I_pf_enable           = spfctl_regOut_L1I_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_enable            = spfctl_regOut_L2_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l1D_pf_enable           = spfctl_regOut_L1D_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l1D_pf_train_on_hit     = spfctl_regOut_L1D_PF_TRAIN_ON_HIT;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_agt       = spfctl_regOut_L1D_PF_ENABLE_AGT;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_pht       = spfctl_regOut_L1D_PF_ENABLE_PHT;
  assign io_status_custom_pf_ctrl_l1D_pf_active_threshold = spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD;
  assign io_status_custom_pf_ctrl_l1D_pf_active_stride    = spfctl_regOut_L1D_PF_ACTIVE_STRIDE;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_stride    = spfctl_regOut_L1D_PF_ENABLE_STRIDE;
  assign io_status_custom_pf_ctrl_l2_pf_store_only        = spfctl_regOut_L2_PF_STORE_ONLY;
  assign io_status_custom_pf_ctrl_l2_pf_recv_enable       = spfctl_regOut_L2_PF_RECV_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_pbop_enable       = spfctl_regOut_L2_PF_PBOP_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_vbop_enable       = spfctl_regOut_L2_PF_VBOP_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_delay_latency     = spfctl_regOut_L2_PF_DELAY_LATENCY;
  assign io_status_custom_lvpred_timeout                  = slvpredctl_regOut_LVPRED_TIMEOUT;
  assign io_status_custom_bp_ctrl_ubtb_enable             = sbpctl_regOut_UBTB_ENABLE;
  assign io_status_custom_bp_ctrl_btb_enable              = sbpctl_regOut_BTB_ENABLE;
  assign io_status_custom_bp_ctrl_tage_enable             = sbpctl_regOut_TAGE_ENABLE;
  assign io_status_custom_bp_ctrl_sc_enable               = sbpctl_regOut_SC_ENABLE;
  assign io_status_custom_bp_ctrl_ras_enable              = sbpctl_regOut_RAS_ENABLE;
  assign io_status_custom_sbuffer_timeout                 = smblockctl_regOut_SBUFFER_TIMEOUT;
  assign io_status_custom_ldld_vio_check_enable           = smblockctl_regOut_LDLD_VIO_CHECK_ENABLE;
  assign io_status_custom_cache_error_enable              = smblockctl_regOut_CACHE_ERROR_ENABLE;
  assign io_status_custom_uncache_write_outstanding_enable =
    smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  assign io_status_custom_hd_misalign_st_enable           = smblockctl_regOut_HD_MISALIGN_ST_ENABLE;
  assign io_status_custom_hd_misalign_ld_enable           = smblockctl_regOut_HD_MISALIGN_LD_ENABLE;
  assign io_status_custom_power_down_enable               = mcorepwr_regOut_POWER_DOWN_ENABLE;
  assign io_status_custom_flush_l2_enable                 = mflushpwr_regOut_FLUSH_L2_ENABLE;
  assign io_status_custom_fusion_enable                   = srnctl_regOut_FUSION_ENABLE;
  // WFI 在单步与 debug 模式下关闭
  assign io_status_custom_wfi_enable = srnctl_regOut_WFI_ENABLE & ~single_step_flag & ~debug_mode;

  // critical error 对外：dcsr.CETRIG=1 时交给 debug 处理，不对外报
  wire critical_error_out = critical_error_state & ~dcsr_regOut_CETRIG;
  assign io_status_criticalErrorState = critical_error_out;

  // ==========================================================================
  // 13. TLB 相关输出
  // ==========================================================================
  // ASID/VMID 变化：写 satp/vsatp/hgatp 且新旧 ASID/VMID 不同，打一拍通知 TLB 刷新
  logic satp_asid_changed_q, vsatp_asid_changed_q, hgatp_vmid_changed_q;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      satp_asid_changed_q  <= 1'b0;
      vsatp_asid_changed_q <= 1'b0;
      hgatp_vmid_changed_q <= 1'b0;
    end
    else begin
      satp_asid_changed_q  <= wen_satp  & satp_regOut_ASID  != wdata[59:44];
      vsatp_asid_changed_q <= wen_vsatp & vsatp_regOut_ASID != wdata[59:44];
      hgatp_vmid_changed_q <= wen_hgatp & hgatp_regOut_VMID != wdata[57:44];
    end
  end
  assign io_tlb_satpASIDChanged  = satp_asid_changed_q;
  assign io_tlb_vsatpASIDChanged = vsatp_asid_changed_q;
  assign io_tlb_hgatpVMIDChanged = hgatp_vmid_changed_q;
  assign io_tlb_satp_MODE   = satp_rdata[63:60];
  assign io_tlb_satp_ASID   = satp_rdata[59:44];
  assign io_tlb_satp_PPN    = satp_rdata[43:0];
  assign io_tlb_vsatp_MODE  = vsatp_rdata[63:60];
  assign io_tlb_vsatp_ASID  = vsatp_rdata[59:44];
  assign io_tlb_vsatp_PPN   = vsatp_rdata[43:0];
  assign io_tlb_hgatp_MODE  = hgatp_rdata[63:60];
  assign io_tlb_hgatp_VMID  = hgatp_rdata[57:44];
  assign io_tlb_hgatp_PPN   = hgatp_rdata[43:0];
  assign io_tlb_mbmc_BMA    = mbmc_rdata[63:6];
  assign io_tlb_mbmc_BME    = mbmc_rdata[2];
  assign io_tlb_mbmc_BCLEAR = mbmc_rdata[1];
  assign io_tlb_mbmc_CMODE  = mbmc_rdata[0];
  assign io_tlb_mxr         = mstatus_regOut_MXR;
  assign io_tlb_sum         = mstatus_regOut_SUM;
  assign io_tlb_vmxr        = vsstatus_regOut_MXR;
  assign io_tlb_vsum        = vsstatus_regOut_SUM;
  assign io_tlb_spvp        = hstatus_regOut_SPVP;
  assign io_tlb_imode       = prvm;
  assign io_tlb_debug       = debug_mode;
  // 访存特权级：MPRV 生效时用 MPP/MPV（debug 模式下还要 dcsr.MPRVEN；NMIE=0 时当 MPRV=0）
  wire mprv_effective = (debug_mode & dcsr_regOut_MPRVEN | ~debug_mode) & mstatus_regOut_MPRV
                      & mnstatus_regOut_NMIE;
  assign io_tlb_dmode = mprv_effective ? mstatus_regOut_MPP : prvm;
  assign io_tlb_dvirt = mprv_effective & mstatus_regOut_MPP != 2'h3 ? mstatus_regOut_MPV : virt;

  // PBMTE / 指针掩码配置打一拍（不复位）
  logic       m_pbmte_q, h_pbmte_q;
  logic [1:0] pmm_mseccfg_q, pmm_menvcfg_q, pmm_henvcfg_q, pmm_hstatus_q, pmm_senvcfg_q;
  always @(posedge clock) begin
    m_pbmte_q     <= menvcfg_regOut_PBMTE;
    h_pbmte_q     <= henvcfg_regOut_PBMTE;
    pmm_mseccfg_q <= mseccfg_regOut_PMM;
    pmm_menvcfg_q <= menvcfg_regOut_PMM;
    pmm_henvcfg_q <= henvcfg_regOut_PMM;
    pmm_hstatus_q <= hstatus_regOut_HUPMM;
    pmm_senvcfg_q <= senvcfg_regOut_PMM;
  end
  assign io_tlb_mPBMTE      = m_pbmte_q;
  assign io_tlb_hPBMTE      = h_pbmte_q;
  assign io_tlb_pmm_mseccfg = pmm_mseccfg_q;
  assign io_tlb_pmm_menvcfg = pmm_menvcfg_q;
  assign io_tlb_pmm_henvcfg = pmm_henvcfg_q;
  assign io_tlb_pmm_hstatus = pmm_hstatus_q;
  assign io_tlb_pmm_senvcfg = pmm_senvcfg_q;

  // ==========================================================================
  // 14. 送译码的特权指令检查（illegalInst = 非法指令异常；virtualInst = 虚拟指令异常）
  // ==========================================================================
  wire mode_virtual = mode_vs | mode_vu;
  assign io_toDecode_illegalInst_sfenceVMA  = mode_hs & mstatus_regOut_TVM | mode_hu;
  assign io_toDecode_illegalInst_sfencePart = mode_hu;
  assign io_toDecode_illegalInst_hfenceGVMA = mode_hs & mstatus_regOut_TVM | mode_hu;
  assign io_toDecode_illegalInst_hfenceVVMA = mode_hu;
  assign io_toDecode_illegalInst_hlsv       = mode_hu & ~hstatus_regOut_HU;
  assign io_toDecode_illegalInst_fsIsOff    = mstatus_fs_off | mode_virtual & vsstatus_fs_off;
  assign io_toDecode_illegalInst_vsIsOff    = mstatus_vs_off | mode_virtual & vsstatus_vs_off;
  assign io_toDecode_illegalInst_wfi        = mode_hu | ~mode_m & mstatus_regOut_TW;
  assign io_toDecode_illegalInst_wrs_nto    = ~mode_m & mstatus_regOut_TW;
  assign io_toDecode_illegalInst_frm        = frm_is_reserved;
  assign io_toDecode_virtualInst_sfenceVMA  = mode_vs & hstatus_regOut_VTVM | mode_vu;
  assign io_toDecode_virtualInst_sfencePart = mode_vu;
  assign io_toDecode_virtualInst_hfence     = mode_virtual;
  assign io_toDecode_virtualInst_hlsv       = mode_virtual;
  assign io_toDecode_virtualInst_wfi        = mode_vs & ~mstatus_regOut_TW & hstatus_regOut_VTW
                                            | mode_vu & ~mstatus_regOut_TW;
  assign io_toDecode_virtualInst_wrs_nto    = virt & ~mstatus_regOut_TW & hstatus_regOut_VTW;
  // Zicbom/Zicboz：xenvcfg 的 CBZE / CBCFE / CBIE 逐级放行
  assign io_toDecode_illegalInst_cboZ  = ~mode_m & ~menvcfg_regOut_CBZE | mode_hu & ~senvcfg_regOut_CBZE;
  assign io_toDecode_virtualInst_cboZ  = menvcfg_regOut_CBZE
                                       & (mode_vs & ~henvcfg_regOut_CBZE
                                          | mode_vu & ~(henvcfg_regOut_CBZE & senvcfg_regOut_CBZE));
  assign io_toDecode_illegalInst_cboCF = ~mode_m & ~menvcfg_regOut_CBCFE | mode_hu & ~senvcfg_regOut_CBCFE;
  assign io_toDecode_virtualInst_cboCF = menvcfg_regOut_CBCFE
                                       & (mode_vs & ~henvcfg_regOut_CBCFE
                                          | mode_vu & ~(henvcfg_regOut_CBCFE & senvcfg_regOut_CBCFE));
  // CBIE: 0=Off 1=Flush 3=Inval
  wire m_cbie_off = menvcfg_regOut_CBIE == 2'h0;
  wire h_cbie_off = henvcfg_regOut_CBIE == 2'h0;
  wire s_cbie_off = senvcfg_regOut_CBIE == 2'h0;
  wire illegal_cbo_i = ~mode_m & m_cbie_off | mode_hu & s_cbie_off;
  wire virtual_cbo_i = ~m_cbie_off & (mode_vs & h_cbie_off | mode_vu & (h_cbie_off | s_cbie_off));
  assign io_toDecode_illegalInst_cboI = illegal_cbo_i;
  assign io_toDecode_virtualInst_cboI = virtual_cbo_i;
  // cbo.inval 在某级被配置为 Flush 时降级成 cbo.flush
  assign io_toDecode_special_cboI2F = ~illegal_cbo_i & ~virtual_cbo_i
                                    & (menvcfg_regOut_CBIE == 2'h1 & ~mode_m
                                       | senvcfg_regOut_CBIE == 2'h1 & (mode_hu | mode_vu)
                                       | henvcfg_regOut_CBIE == 2'h1 & mode_virtual);

  assign io_distributedWenLegal = wen_legal_q & ~no_csr_illegal_q;

  // ==========================================================================
  // 15. IMSIC（AIA）间接访问
  //     mireg / sireg / vsireg 在 *iselect 落在 IMSIC 窗口时转发给 IMSIC；地址/特权态在请求的
  //     下一拍给出（csr_access = 打一拍后的读或合法写），写数据用打一拍后的 op/src。
  // ==========================================================================
  logic ren_q;
  always @(posedge clock)
    ren_q <= ren;
  wire csr_access = wen_legal_q | ren_q;
  wire aia_sel_m  = csr_access & addr == 12'h351;                              // mireg
  wire aia_sel_s  = csr_access & addr == 12'h151 & ~mode_vs;                   // sireg（非 VS）
  wire aia_sel_vs = csr_access & (addr == 12'h151 & mode_vs | addr == 12'h251); // vsireg

  assign toAIA_addr_valid = aia_sel_m & miselect_inIMSICRange | aia_sel_s & siselect_inIMSICRange
                          | aia_sel_vs & vsiselect_inIMSICRange;
  assign toAIA_addr_bits_addr = (aia_sel_m  ? miselect_rdata[11:0]  : 12'h0)
                              | (aia_sel_s  ? siselect_rdata[11:0]  : 12'h0)
                              | (aia_sel_vs ? vsiselect_rdata[11:0] : 12'h0);
  // 访问者特权态：M=(3,0) HS=(1,0) VS=(1,1)
  assign toAIA_addr_bits_v    = aia_sel_vs;
  assign toAIA_addr_bits_prvm = {aia_sel_m, aia_sel_m | aia_sel_s | aia_sel_vs};
  assign toAIA_vgein          = hstatus_regOut_VGEIN;
  assign toAIA_wdata_valid    = wen_mireg & miselect_inIMSICRange | wen_sireg & siselect_inIMSICRange
                              | wen_vsireg & vsiselect_inIMSICRange;
  logic [1:0]  aia_wdata_op_q;
  logic [63:0] aia_wdata_data_q;
  always @(posedge clock) begin
    aia_wdata_op_q   <= io_in_bits_op;
    aia_wdata_data_q <= io_in_bits_src;
  end
  assign toAIA_wdata_bits_op   = aia_wdata_op_q;
  assign toAIA_wdata_bits_data = aia_wdata_data_q;
  // 写 *topei = 认领当前最高优先级的外部中断
  assign toAIA_mClaim  = wen_mtopei;
  assign toAIA_sClaim  = wen_stopei;
  assign toAIA_vsClaim = wen_vstopei;

  // critical error 上报（打两拍，不复位）
  logic critical_error_d1, critical_error_d2;
  always @(posedge clock) begin
    critical_error_d1 <= critical_error_in_csr;
    critical_error_d2 <= critical_error_d1;
  end
  assign io_error_0 = critical_error_d2;

  // ==========================================================================
  // 16. difftest 事件（经 gatewayIn_packed_*_bore 送到顶层 difftest 网关）
  // ==========================================================================
  wire [7:0] diff_coreid = {2'h0, io_fromTop_hartId};

  // ---- ArchEvent：trap 在向量异常模块不忙时才报给 difftest ----
  logic pending_trap;
  always @(posedge clock or posedge reset) begin
    if (reset)
      pending_trap <= 1'b0;
    else
      pending_trap <= io_fromRob_trap_valid | io_fromVecExcpMod_busy & pending_trap;
  end
  wire diff_trap_valid = pending_trap & ~io_fromVecExcpMod_busy;

  wire        cause_is_intr = trapHandleMod_io_out_causeNO_Interrupt;
  wire        hvictl_inject = intrMod_io_out_virtualInterruptIsHvictlInject & cause_is_intr;
  // hvictl 注入的虚拟中断，中断号取 hvictl.IID
  wire [62:0] trap_no       = hvictl_inject ? {51'h0, hvictl_regOut_IID}
                                            : trapHandleMod_io_out_causeNO_ExceptionCode;
  // 异常 PC 按当前翻译模式符号扩展
  wire is_sv39 = (mode_hs | mode_hu) & satp_regOut_MODE == 4'h8 | mode_virtual & vsatp_regOut_MODE == 4'h8;
  wire is_sv48 = (mode_hs | mode_hu) & satp_regOut_MODE == 4'h9 | mode_virtual & vsatp_regOut_MODE == 4'h9;
  wire [63:0] exception_pc =
      (is_sv39 ? {{25{io_fromRob_trap_bits_pc[38]}}, io_fromRob_trap_bits_pc[38:0]} : 64'h0)
    | (is_sv48 ? {{16{io_fromRob_trap_bits_pc[47]}}, io_fromRob_trap_bits_pc[47:0]} : 64'h0)
    | (is_sv39 | is_sv48 ? 64'h0 : {16'h0, io_fromRob_trap_bits_pc[47:0]});

  logic [31:0] diff_interrupt_q, diff_exception_q, diff_exception_inst_q;
  logic [63:0] diff_exception_pc_q;
  logic        diff_has_nmi_q, diff_ir_to_hs_q, diff_ir_to_vs_q, diff_hvictl_inject_q;
  logic [7:0]  diff_vl_q;
  always @(posedge clock) begin
    if (io_fromRob_trap_valid) begin
      diff_interrupt_q      <= cause_is_intr ? trap_no[31:0] : 32'h0;
      diff_exception_q      <= cause_is_intr ? 32'h0 : trap_no[31:0];
      diff_exception_pc_q   <= exception_pc;
      diff_has_nmi_q        <= intrMod_io_out_nmi & io_fromRob_trap_valid;
      diff_ir_to_hs_q       <= ir_to_hs_q;
      diff_ir_to_vs_q       <= ir_to_vs_q;
      diff_exception_inst_q <= io_fromRob_trap_bits_instr;
    end
    diff_hvictl_inject_q <= hvictl_inject;
    diff_vl_q            <= io_fromRob_commit_vl;
  end

  assign gatewayIn_packed_29_bore = {
    diff_trap_valid, diff_interrupt_q, diff_exception_q, diff_exception_pc_q,
    diff_exception_inst_q, diff_has_nmi_q, diff_hvictl_inject_q, diff_ir_to_hs_q,
    diff_ir_to_vs_q, diff_coreid};
  assign gatewayIn_packed_30_bore = {critical_error_out & diff_trap_valid, critical_error_out,
                                     diff_coreid};

  // ---- CSR 快照 ----
  assign gatewayIn_packed_31_bore = {
    {62'h0, prvm}, mstatus_rdata, regout_sstatus, mepc_rdata, sepc_rdata, mtval_rdata,
    stval_rdata, mtvec_rdata, stvec_rdata, mcause_rdata, scause_rdata, satp_rdata, mip_rdata,
    mie_rdata, mscratch_rdata, sscratch_rdata, mideleg_rdata, medeleg_rdata, diff_coreid};
  assign gatewayIn_packed_32_bore = {
    debug_mode, {32'h0, dcsr_rdata}, dpc_rdata, dscratch0_rdata, dscratch1_rdata, diff_coreid};
  assign gatewayIn_packed_33_bore = {
    {62'h0, tselect_rdata}, tdata1_rdata, 64'h1000040, diff_coreid};        // tinfo 常数
  assign gatewayIn_packed_34_bore = {
    vstart_rdata, {63'h0, vcsr_vxsat}, {62'h0, vcsr_vxrm}, vcsr_rdata, {56'h0, diff_vl_q},
    vtype_rdata, 64'h10, diff_coreid};                                       // vlenb 常数
  assign gatewayIn_packed_35_bore = {fcsr_rdata, diff_coreid};
  assign gatewayIn_packed_36_bore = {
    {63'h0, virt}, mtval2_rdata, mtinst_rdata, hstatus_rdata, hideleg_rdata, hedeleg_rdata,
    hcounteren_rdata, htval_rdata, htinst_rdata, hgatp_rdata, vsstatus_rdata, vstvec_rdata,
    vsepc_rdata, vscause_rdata, vstval_rdata, vsatp_rdata, vsscratch_rdata, diff_coreid};

  // ---- NonRegInterruptPending：外部中断线有变化（或刚复位）时报一次 ----
  // Scala 用 "!x && RegNext(x) || x && !RegNext(x)"，两次 RegNext 各成一个寄存器；照留两份。
  wire vseip_from_hgeip = hgeip_rdata[hstatus_regOut_VGEIN];
  logic platformIRPMeipChange_REG,  platformIRPMeipChange_REG_1;
  logic platformIRPMtipChange_REG,  platformIRPMtipChange_REG_1;
  logic platformIRPMsipChange_REG,  platformIRPMsipChange_REG_1;
  logic platformIRPSeipChange_REG,  platformIRPSeipChange_REG_1;
  logic platformIRPStipChange_REG,  platformIRPStipChange_REG_1;
  logic platformIRPVseipChange_REG_2, platformIRPVseipChange_REG_3;
  logic platformIRPVstipChange_REG, platformIRPVstipChange_REG_1;
  logic fromAIAMeipChange_REG,      fromAIAMeipChange_REG_1;
  logic fromAIASeipChange_REG,      fromAIASeipChange_REG_1;
  logic lcofiReqChange_REG,         lcofiReqChange_REG_1;
  logic reset_q;
  always @(posedge clock) begin
    platformIRPMeipChange_REG    <= platformIRP_MEIP;
    platformIRPMeipChange_REG_1  <= platformIRP_MEIP;
    platformIRPMtipChange_REG    <= platformIRP_MTIP;
    platformIRPMtipChange_REG_1  <= platformIRP_MTIP;
    platformIRPMsipChange_REG    <= platformIRP_MSIP;
    platformIRPMsipChange_REG_1  <= platformIRP_MSIP;
    platformIRPSeipChange_REG    <= platformIRP_SEIP;
    platformIRPSeipChange_REG_1  <= platformIRP_SEIP;
    platformIRPStipChange_REG    <= sstcIRGen_o_STIP;
    platformIRPStipChange_REG_1  <= sstcIRGen_o_STIP;
    platformIRPVseipChange_REG_2 <= vseip_from_hgeip;
    platformIRPVseipChange_REG_3 <= vseip_from_hgeip;
    platformIRPVstipChange_REG   <= sstcIRGen_o_VSTIP;
    platformIRPVstipChange_REG_1 <= sstcIRGen_o_VSTIP;
    fromAIAMeipChange_REG        <= fromAIA_meip;
    fromAIAMeipChange_REG_1      <= fromAIA_meip;
    fromAIASeipChange_REG        <= fromAIA_seip;
    fromAIASeipChange_REG_1      <= fromAIA_seip;
    lcofiReqChange_REG           <= lcofi_req;
    lcofiReqChange_REG_1         <= lcofi_req;
    reset_q                      <= reset;
  end
  // 下降沿（用第一份寄存器）或上升沿（用第二份寄存器）
  function automatic logic edge2(input logic now, input logic q_fall, input logic q_rise);
    edge2 = ~now & q_fall | now & ~q_rise;
  endfunction
  wire diff_nonreg_valid =
    (edge2(platformIRP_MEIP, platformIRPMeipChange_REG, platformIRPMeipChange_REG_1)
     | edge2(platformIRP_MTIP, platformIRPMtipChange_REG, platformIRPMtipChange_REG_1)
     | edge2(platformIRP_MSIP, platformIRPMsipChange_REG, platformIRPMsipChange_REG_1)
     | edge2(platformIRP_SEIP, platformIRPSeipChange_REG, platformIRPSeipChange_REG_1)
     | edge2(sstcIRGen_o_STIP, platformIRPStipChange_REG, platformIRPStipChange_REG_1)
     | edge2(vseip_from_hgeip, platformIRPVseipChange_REG_2, platformIRPVseipChange_REG_3)
     | edge2(sstcIRGen_o_VSTIP, platformIRPVstipChange_REG, platformIRPVstipChange_REG_1)
     | edge2(fromAIA_meip, fromAIAMeipChange_REG, fromAIAMeipChange_REG_1)
     | edge2(fromAIA_seip, fromAIASeipChange_REG, fromAIASeipChange_REG_1)
     | edge2(lcofi_req, lcofiReqChange_REG, lcofiReqChange_REG_1)
     | reset_q) & ~reset;
  assign gatewayIn_packed_37_bore = {
    diff_nonreg_valid, platformIRP_MEIP, platformIRP_MTIP, platformIRP_MSIP, platformIRP_SEIP,
    sstcIRGen_o_STIP, vseip_from_hgeip, sstcIRGen_o_VSTIP, fromAIA_meip, fromAIA_seip,
    mip_regOut_LCOFIP, diff_coreid};

  // ---- MhpmeventOverflow：任一计数器溢出标志有变化（同样两份寄存器）----
  logic [28:0] overflow_fall_q, overflow_rise_q;
  always @(posedge clock) begin
    overflow_fall_q <= counter_overflow;
    overflow_rise_q <= counter_overflow;
  end
  wire diff_overflow_valid = |(~counter_overflow & overflow_fall_q | counter_overflow & ~overflow_rise_q);
  wire [28:0] mhpmevent_of = {
    Mhpmevent31_regOut_OF, Mhpmevent30_regOut_OF, Mhpmevent29_regOut_OF, Mhpmevent28_regOut_OF,
    Mhpmevent27_regOut_OF, Mhpmevent26_regOut_OF, Mhpmevent25_regOut_OF, Mhpmevent24_regOut_OF,
    Mhpmevent23_regOut_OF, Mhpmevent22_regOut_OF, Mhpmevent21_regOut_OF, Mhpmevent20_regOut_OF,
    Mhpmevent19_regOut_OF, Mhpmevent18_regOut_OF, Mhpmevent17_regOut_OF, Mhpmevent16_regOut_OF,
    Mhpmevent15_regOut_OF, Mhpmevent14_regOut_OF, Mhpmevent13_regOut_OF, Mhpmevent12_regOut_OF,
    Mhpmevent11_regOut_OF, Mhpmevent10_regOut_OF, Mhpmevent9_regOut_OF,  Mhpmevent8_regOut_OF,
    Mhpmevent7_regOut_OF,  Mhpmevent6_regOut_OF,  Mhpmevent5_regOut_OF,  Mhpmevent4_regOut_OF,
    Mhpmevent3_regOut_OF};
  assign gatewayIn_packed_38_bore = {diff_overflow_valid, {35'h0, mhpmevent_of}, diff_coreid};

  // ---- SyncAIA：*topei / VGEIN / hgeip 有变化 ----
  logic [21:0] mtopei_q, stopei_q;     // {IID, IPRIO}
  logic [5:0]  vgein_q;
  logic [6:0]  vseip_q;
  logic        l2_flush_done_q;
  always @(posedge clock) begin
    mtopei_q        <= {fromAIA_mtopei_IID, fromAIA_mtopei_IPRIO};
    stopei_q        <= {fromAIA_stopei_IID, fromAIA_stopei_IPRIO};
    vgein_q         <= hstatus_regOut_VGEIN;
    vseip_q         <= fromAIA_vseip;
    l2_flush_done_q <= io_fromTop_l2FlushDone;
  end
  wire diff_sync_aia_valid = mtopei_q != {fromAIA_mtopei_IID, fromAIA_mtopei_IPRIO}
                           | stopei_q != {fromAIA_stopei_IID, fromAIA_stopei_IPRIO}
                           | vgein_q != hstatus_regOut_VGEIN | vseip_q != fromAIA_vseip;
  assign gatewayIn_packed_39_bore = {
    diff_sync_aia_valid, mtopei_rdata, stopei_rdata, vstopei_rdata, hgeip_rdata, diff_coreid};
  assign gatewayIn_packed_40_bore = {l2_flush_done_q != io_fromTop_l2FlushDone,
                                     io_fromTop_l2FlushDone, diff_coreid};

  // ==========================================================================
  // 子模块例化（GENERATED；实例名与 golden 相同）
  // ==========================================================================
// BEGIN GENERATED(newcsr-insts) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改
  MbmcModule mbmc (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_mbmc),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (mbmc_rdata),
    .regOut_BMA     (mbmc_regOut_BMA),
    .regOut_KEYIDEN (mbmc_regOut_KEYIDEN),
    .regOut_BME     (mbmc_regOut_BME),
    .regOut_BCLEAR  (mbmc_regOut_BCLEAR),
    .regOut_CMODE   (mbmc_regOut_CMODE)
  );
  MStatusModule mstatus (
    .clock                       (clock),
    .reset                       (reset),
    .w_wen                       (wen_mstatus),
    .w_wdata                     (io_in_bits_wdata),
    .rdata                       (mstatus_rdata),
    .regOut_SIE                  (mstatus_regOut_SIE),
    .regOut_MIE                  (mstatus_regOut_MIE),
    .regOut_SPIE                 (mstatus_regOut_SPIE),
    .regOut_MPIE                 (mstatus_regOut_MPIE),
    .regOut_SPP                  (mstatus_regOut_SPP),
    .regOut_VS                   (mstatus_regOut_VS),
    .regOut_MPP                  (mstatus_regOut_MPP),
    .regOut_FS                   (mstatus_regOut_FS),
    .regOut_MPRV                 (mstatus_regOut_MPRV),
    .regOut_SUM                  (mstatus_regOut_SUM),
    .regOut_MXR                  (mstatus_regOut_MXR),
    .regOut_TVM                  (mstatus_regOut_TVM),
    .regOut_TW                   (mstatus_regOut_TW),
    .regOut_TSR                  (mstatus_regOut_TSR),
    .regOut_SDT                  (mstatus_regOut_SDT),
    .regOut_GVA                  (mstatus_regOut_GVA),
    .regOut_MPV                  (mstatus_regOut_MPV),
    .regOut_MDT                  (mstatus_regOut_MDT),
    .trapToM_mstatus_valid       (trapEntryMEvent_out_mstatus_valid),
    .trapToM_mstatus_bits_MIE    (trapEntryMEvent_out_mstatus_bits_MIE),
    .trapToM_mstatus_bits_MPIE   (trapEntryMEvent_out_mstatus_bits_MPIE),
    .trapToM_mstatus_bits_MPP    (trapEntryMEvent_out_mstatus_bits_MPP),
    .trapToM_mstatus_bits_GVA    (trapEntryMEvent_out_mstatus_bits_GVA),
    .trapToM_mstatus_bits_MPV    (trapEntryMEvent_out_mstatus_bits_MPV),
    .trapToM_mstatus_bits_MDT    (trapEntryMEvent_out_mstatus_bits_MDT),
    .trapToHS_mstatus_valid      (trapEntryHSEvent_out_mstatus_valid),
    .trapToHS_mstatus_bits_SIE   (trapEntryHSEvent_out_mstatus_bits_SIE),
    .trapToHS_mstatus_bits_SPIE  (trapEntryHSEvent_out_mstatus_bits_SPIE),
    .trapToHS_mstatus_bits_SPP   (trapEntryHSEvent_out_mstatus_bits_SPP),
    .trapToHS_mstatus_bits_SDT   (trapEntryHSEvent_out_mstatus_bits_SDT),
    .retFromD_mstatus_valid      (dretEvent_out_mstatus_valid),
    .retFromD_mstatus_bits_MPRV  (dretEvent_out_mstatus_bits_MPRV),
    .retFromD_mstatus_bits_SDT   (dretEvent_out_mstatus_bits_SDT),
    .retFromD_mstatus_bits_MDT   (dretEvent_out_mstatus_bits_MDT),
    .retFromM_mstatus_valid      (mretEvent_out_mstatus_valid),
    .retFromM_mstatus_bits_MIE   (mretEvent_out_mstatus_bits_MIE),
    .retFromM_mstatus_bits_MPIE  (mretEvent_out_mstatus_bits_MPIE),
    .retFromM_mstatus_bits_MPP   (mretEvent_out_mstatus_bits_MPP),
    .retFromM_mstatus_bits_MPRV  (mretEvent_out_mstatus_bits_MPRV),
    .retFromM_mstatus_bits_SDT   (mretEvent_out_mstatus_bits_SDT),
    .retFromM_mstatus_bits_MPV   (mretEvent_out_mstatus_bits_MPV),
    .retFromM_mstatus_bits_MDT   (mretEvent_out_mstatus_bits_MDT),
    .retFromMN_mstatus_valid     (mnretEvent_out_mstatus_valid),
    .retFromMN_mstatus_bits_MPRV (mnretEvent_out_mstatus_bits_MPRV),
    .retFromMN_mstatus_bits_SDT  (mnretEvent_out_mstatus_bits_SDT),
    .retFromMN_mstatus_bits_MDT  (mnretEvent_out_mstatus_bits_MDT),
    .retFromS_mstatus_valid      (sretEvent_out_mstatus_valid),
    .retFromS_mstatus_bits_SIE   (sretEvent_out_mstatus_bits_SIE),
    .retFromS_mstatus_bits_SPIE  (sretEvent_out_mstatus_bits_SPIE),
    .retFromS_mstatus_bits_SPP   (sretEvent_out_mstatus_bits_SPP),
    .retFromS_mstatus_bits_MPRV  (sretEvent_out_mstatus_bits_MPRV),
    .retFromS_mstatus_bits_SDT   (sretEvent_out_mstatus_bits_SDT),
    .retFromS_mstatus_bits_MDT   (sretEvent_out_mstatus_bits_MDT),
    .robCommit_fsDirty           (mstatus_cmt_fs_dirty_q),
    .robCommit_vsDirty           (mstatus_cmt_vs_dirty_q),
    .robCommit_vstart_valid      (mstatus_cmt_vstart_valid_q),
    .robCommit_vstart_bits       (mstatus_cmt_vstart_bits_q),
    .writeFCSR                   (permitMod_io_out_hasLegalWriteFcsr),
    .writeVCSR                   (permitMod_io_out_hasLegalWriteVcsr),
    .menvcfg_DTE                 (menvcfg_regOut_DTE),
    .sstatus_SIE                 (mstatus_sstatus_SIE),
    .sstatus_SPIE                (mstatus_sstatus_SPIE),
    .sstatus_SPP                 (mstatus_sstatus_SPP),
    .sstatus_VS                  (mstatus_sstatus_VS),
    .sstatus_FS                  (mstatus_sstatus_FS),
    .sstatus_SUM                 (mstatus_sstatus_SUM),
    .sstatus_MXR                 (mstatus_sstatus_MXR),
    .sstatus_SDT                 (mstatus_sstatus_SDT),
    .sstatus_SD                  (mstatus_sstatus_SD),
    .sstatusRdata                (mstatus_sstatusRdata),
    .wAliasSstatus_wen           (wen_sstatus),
    .wAliasSstatus_wdata         (io_in_bits_wdata)
  );
  MedelegModule medeleg (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_medeleg),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (medeleg_rdata),
    .regOut_EX_IAM    (medeleg_regOut_EX_IAM),
    .regOut_EX_IAF    (medeleg_regOut_EX_IAF),
    .regOut_EX_II     (medeleg_regOut_EX_II),
    .regOut_EX_BP     (medeleg_regOut_EX_BP),
    .regOut_EX_LAM    (medeleg_regOut_EX_LAM),
    .regOut_EX_LAF    (medeleg_regOut_EX_LAF),
    .regOut_EX_SAM    (medeleg_regOut_EX_SAM),
    .regOut_EX_SAF    (medeleg_regOut_EX_SAF),
    .regOut_EX_UCALL  (medeleg_regOut_EX_UCALL),
    .regOut_EX_HSCALL (medeleg_regOut_EX_HSCALL),
    .regOut_EX_VSCALL (medeleg_regOut_EX_VSCALL),
    .regOut_EX_IPF    (medeleg_regOut_EX_IPF),
    .regOut_EX_LPF    (medeleg_regOut_EX_LPF),
    .regOut_EX_SPF    (medeleg_regOut_EX_SPF),
    .regOut_EX_SWC    (medeleg_regOut_EX_SWC),
    .regOut_EX_HWE    (medeleg_regOut_EX_HWE),
    .regOut_EX_IGPF   (medeleg_regOut_EX_IGPF),
    .regOut_EX_LGPF   (medeleg_regOut_EX_LGPF),
    .regOut_EX_VI     (medeleg_regOut_EX_VI),
    .regOut_EX_SGPF   (medeleg_regOut_EX_SGPF)
  );
  MidelegModule mideleg (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_mideleg),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (mideleg_rdata),
    .regOut_SSI   (mideleg_regOut_SSI),
    .regOut_STI   (mideleg_regOut_STI),
    .regOut_SEI   (mideleg_regOut_SEI),
    .regOut_LCOFI (mideleg_regOut_LCOFI)
  );
  MieModule mie (
    .clock                 (clock),
    .reset                 (reset),
    .w_wen                 (wen_mie),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (mie_rdata),
    .regOut_SSIE           (mie_regOut_SSIE),
    .regOut_VSSIE          (mie_regOut_VSSIE),
    .regOut_MSIE           (mie_regOut_MSIE),
    .regOut_STIE           (mie_regOut_STIE),
    .regOut_VSTIE          (mie_regOut_VSTIE),
    .regOut_MTIE           (mie_regOut_MTIE),
    .regOut_SEIE           (mie_regOut_SEIE),
    .regOut_VSEIE          (mie_regOut_VSEIE),
    .regOut_MEIE           (mie_regOut_MEIE),
    .regOut_SGEIE          (mie_regOut_SGEIE),
    .regOut_LCOFIE         (mie_regOut_LCOFIE),
    .fromHie_VSSIE_valid   (hie_toMie_VSSIE_valid),
    .fromHie_VSSIE_bits    (hie_toMie_VSSIE_bits),
    .fromHie_VSTIE_valid   (hie_toMie_VSTIE_valid),
    .fromHie_VSTIE_bits    (hie_toMie_VSTIE_bits),
    .fromHie_VSEIE_valid   (hie_toMie_VSEIE_valid),
    .fromHie_VSEIE_bits    (hie_toMie_VSEIE_bits),
    .fromHie_SGEIE_valid   (hie_toMie_SGEIE_valid),
    .fromHie_SGEIE_bits    (hie_toMie_SGEIE_bits),
    .fromSie_SSIE_valid    (sie_toMie_SSIE_valid),
    .fromSie_SSIE_bits     (sie_toMie_SSIE_bits),
    .fromSie_STIE_valid    (sie_toMie_STIE_valid),
    .fromSie_STIE_bits     (sie_toMie_STIE_bits),
    .fromSie_SEIE_valid    (sie_toMie_SEIE_valid),
    .fromSie_SEIE_bits     (sie_toMie_SEIE_bits),
    .fromSie_LCOFIE_valid  (sie_toMie_LCOFIE_valid),
    .fromSie_LCOFIE_bits   (sie_toMie_LCOFIE_bits),
    .fromVSie_VSSIE_valid  (vsie_toMie_VSSIE_valid),
    .fromVSie_VSSIE_bits   (vsie_toMie_VSSIE_bits),
    .fromVSie_VSTIE_valid  (vsie_toMie_VSTIE_valid),
    .fromVSie_VSTIE_bits   (vsie_toMie_VSTIE_bits),
    .fromVSie_VSEIE_valid  (vsie_toMie_VSEIE_valid),
    .fromVSie_VSEIE_bits   (vsie_toMie_VSEIE_bits),
    .fromVSie_LCOFIE_valid (vsie_toMie_LCOFIE_valid),
    .fromVSie_LCOFIE_bits  (vsie_toMie_LCOFIE_bits)
  );
  MtvecModule mtvec (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_mtvec),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (mtvec_rdata),
    .regOut_mode (mtvec_regOut_mode),
    .regOut_addr (mtvec_regOut_addr)
  );
  McounterenModule mcounteren (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_mcounteren),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (mcounteren_rdata),
    .regOut_CY  (mcounteren_regOut_CY),
    .regOut_TM  (mcounteren_regOut_TM),
    .regOut_IR  (mcounteren_regOut_IR),
    .regOut_HPM (mcounteren_regOut_HPM)
  );
  MvienModule mvien (
    .clock           (clock),
    .reset           (reset),
    .w_wen           (wen_mvien),
    .w_wdata         (io_in_bits_wdata),
    .rdata           (mvien_rdata),
    .regOut_SSIE     (mvien_regOut_SSIE),
    .regOut_SEIE     (mvien_regOut_SEIE),
    .regOut_LC14IE   (mvien_regOut_LC14IE),
    .regOut_LC15IE   (mvien_regOut_LC15IE),
    .regOut_LC16IE   (mvien_regOut_LC16IE),
    .regOut_LC17IE   (mvien_regOut_LC17IE),
    .regOut_LC18IE   (mvien_regOut_LC18IE),
    .regOut_LC19IE   (mvien_regOut_LC19IE),
    .regOut_LC20IE   (mvien_regOut_LC20IE),
    .regOut_LC21IE   (mvien_regOut_LC21IE),
    .regOut_LC22IE   (mvien_regOut_LC22IE),
    .regOut_LC23IE   (mvien_regOut_LC23IE),
    .regOut_LC24IE   (mvien_regOut_LC24IE),
    .regOut_LC25IE   (mvien_regOut_LC25IE),
    .regOut_LC26IE   (mvien_regOut_LC26IE),
    .regOut_LC27IE   (mvien_regOut_LC27IE),
    .regOut_LC28IE   (mvien_regOut_LC28IE),
    .regOut_LC29IE   (mvien_regOut_LC29IE),
    .regOut_LC30IE   (mvien_regOut_LC30IE),
    .regOut_LC31IE   (mvien_regOut_LC31IE),
    .regOut_LC32IE   (mvien_regOut_LC32IE),
    .regOut_LC33IE   (mvien_regOut_LC33IE),
    .regOut_LC34IE   (mvien_regOut_LC34IE),
    .regOut_LPRASEIE (mvien_regOut_LPRASEIE),
    .regOut_LC36IE   (mvien_regOut_LC36IE),
    .regOut_LC37IE   (mvien_regOut_LC37IE),
    .regOut_LC38IE   (mvien_regOut_LC38IE),
    .regOut_LC39IE   (mvien_regOut_LC39IE),
    .regOut_LC40IE   (mvien_regOut_LC40IE),
    .regOut_LC41IE   (mvien_regOut_LC41IE),
    .regOut_LC42IE   (mvien_regOut_LC42IE),
    .regOut_HPRASEIE (mvien_regOut_HPRASEIE),
    .regOut_LC44IE   (mvien_regOut_LC44IE),
    .regOut_LC45IE   (mvien_regOut_LC45IE),
    .regOut_LC46IE   (mvien_regOut_LC46IE),
    .regOut_LC47IE   (mvien_regOut_LC47IE),
    .regOut_LC48IE   (mvien_regOut_LC48IE),
    .regOut_LC49IE   (mvien_regOut_LC49IE),
    .regOut_LC50IE   (mvien_regOut_LC50IE),
    .regOut_LC51IE   (mvien_regOut_LC51IE),
    .regOut_LC52IE   (mvien_regOut_LC52IE),
    .regOut_LC53IE   (mvien_regOut_LC53IE),
    .regOut_LC54IE   (mvien_regOut_LC54IE),
    .regOut_LC55IE   (mvien_regOut_LC55IE),
    .regOut_LC56IE   (mvien_regOut_LC56IE),
    .regOut_LC57IE   (mvien_regOut_LC57IE),
    .regOut_LC58IE   (mvien_regOut_LC58IE),
    .regOut_LC59IE   (mvien_regOut_LC59IE),
    .regOut_LC60IE   (mvien_regOut_LC60IE),
    .regOut_LC61IE   (mvien_regOut_LC61IE),
    .regOut_LC62IE   (mvien_regOut_LC62IE),
    .regOut_LC63IE   (mvien_regOut_LC63IE)
  );
  MvipModule mvip (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_mvip),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (mvip_rdata),
    .regOut_SSIP            (mvip_regOut_SSIP),
    .regOut_STIP            (mvip_regOut_STIP),
    .regOut_SEIP            (mvip_regOut_SEIP),
    .regOut_LCOFIP          (mvip_regOut_LCOFIP),
    .regOut_LC14IP          (mvip_regOut_LC14IP),
    .regOut_LC15IP          (mvip_regOut_LC15IP),
    .regOut_LC16IP          (mvip_regOut_LC16IP),
    .regOut_LC17IP          (mvip_regOut_LC17IP),
    .regOut_LC18IP          (mvip_regOut_LC18IP),
    .regOut_LC19IP          (mvip_regOut_LC19IP),
    .regOut_LC20IP          (mvip_regOut_LC20IP),
    .regOut_LC21IP          (mvip_regOut_LC21IP),
    .regOut_LC22IP          (mvip_regOut_LC22IP),
    .regOut_LC23IP          (mvip_regOut_LC23IP),
    .regOut_LC24IP          (mvip_regOut_LC24IP),
    .regOut_LC25IP          (mvip_regOut_LC25IP),
    .regOut_LC26IP          (mvip_regOut_LC26IP),
    .regOut_LC27IP          (mvip_regOut_LC27IP),
    .regOut_LC28IP          (mvip_regOut_LC28IP),
    .regOut_LC29IP          (mvip_regOut_LC29IP),
    .regOut_LC30IP          (mvip_regOut_LC30IP),
    .regOut_LC31IP          (mvip_regOut_LC31IP),
    .regOut_LC32IP          (mvip_regOut_LC32IP),
    .regOut_LC33IP          (mvip_regOut_LC33IP),
    .regOut_LC34IP          (mvip_regOut_LC34IP),
    .regOut_LPRASEIP        (mvip_regOut_LPRASEIP),
    .regOut_LC36IP          (mvip_regOut_LC36IP),
    .regOut_LC37IP          (mvip_regOut_LC37IP),
    .regOut_LC38IP          (mvip_regOut_LC38IP),
    .regOut_LC39IP          (mvip_regOut_LC39IP),
    .regOut_LC40IP          (mvip_regOut_LC40IP),
    .regOut_LC41IP          (mvip_regOut_LC41IP),
    .regOut_LC42IP          (mvip_regOut_LC42IP),
    .regOut_HPRASEIP        (mvip_regOut_HPRASEIP),
    .regOut_LC44IP          (mvip_regOut_LC44IP),
    .regOut_LC45IP          (mvip_regOut_LC45IP),
    .regOut_LC46IP          (mvip_regOut_LC46IP),
    .regOut_LC47IP          (mvip_regOut_LC47IP),
    .regOut_LC48IP          (mvip_regOut_LC48IP),
    .regOut_LC49IP          (mvip_regOut_LC49IP),
    .regOut_LC50IP          (mvip_regOut_LC50IP),
    .regOut_LC51IP          (mvip_regOut_LC51IP),
    .regOut_LC52IP          (mvip_regOut_LC52IP),
    .regOut_LC53IP          (mvip_regOut_LC53IP),
    .regOut_LC54IP          (mvip_regOut_LC54IP),
    .regOut_LC55IP          (mvip_regOut_LC55IP),
    .regOut_LC56IP          (mvip_regOut_LC56IP),
    .regOut_LC57IP          (mvip_regOut_LC57IP),
    .regOut_LC58IP          (mvip_regOut_LC58IP),
    .regOut_LC59IP          (mvip_regOut_LC59IP),
    .regOut_LC60IP          (mvip_regOut_LC60IP),
    .regOut_LC61IP          (mvip_regOut_LC61IP),
    .regOut_LC62IP          (mvip_regOut_LC62IP),
    .regOut_LC63IP          (mvip_regOut_LC63IP),
    .mip_SSIP               (mip_rdata[1]),
    .mip_STIP               (mip_rdata[5]),
    .mvien_SSIE             (mvien_regOut_SSIE),
    .menvcfg_STCE           (menvcfg_regOut_STCE),
    .toMip_SSIP_valid       (mvip_toMip_SSIP_valid),
    .toMip_SSIP_bits        (mvip_toMip_SSIP_bits),
    .toMip_STIP_valid       (mvip_toMip_STIP_valid),
    .toMip_STIP_bits        (mvip_toMip_STIP_bits),
    .fromMip_SEIP_valid     (mip_toMvip_SEIP_valid),
    .fromMip_SEIP_bits      (mip_toMvip_SEIP_bits),
    .fromSip_SSIP_valid     (sip_toMvip_SSIP_valid),
    .fromSip_SSIP_bits      (sip_toMvip_SSIP_bits),
    .fromSip_LCOFIP_valid   (sip_toMvip_LCOFIP_valid),
    .fromSip_LCOFIP_bits    (sip_toMvip_LCOFIP_bits),
    .fromSip_LC14IP_valid   (sip_toMvip_LC14IP_valid),
    .fromSip_LC14IP_bits    (sip_toMvip_LC14IP_bits),
    .fromSip_LC15IP_valid   (sip_toMvip_LC15IP_valid),
    .fromSip_LC15IP_bits    (sip_toMvip_LC15IP_bits),
    .fromSip_LC16IP_valid   (sip_toMvip_LC16IP_valid),
    .fromSip_LC16IP_bits    (sip_toMvip_LC16IP_bits),
    .fromSip_LC17IP_valid   (sip_toMvip_LC17IP_valid),
    .fromSip_LC17IP_bits    (sip_toMvip_LC17IP_bits),
    .fromSip_LC18IP_valid   (sip_toMvip_LC18IP_valid),
    .fromSip_LC18IP_bits    (sip_toMvip_LC18IP_bits),
    .fromSip_LC19IP_valid   (sip_toMvip_LC19IP_valid),
    .fromSip_LC19IP_bits    (sip_toMvip_LC19IP_bits),
    .fromSip_LC20IP_valid   (sip_toMvip_LC20IP_valid),
    .fromSip_LC20IP_bits    (sip_toMvip_LC20IP_bits),
    .fromSip_LC21IP_valid   (sip_toMvip_LC21IP_valid),
    .fromSip_LC21IP_bits    (sip_toMvip_LC21IP_bits),
    .fromSip_LC22IP_valid   (sip_toMvip_LC22IP_valid),
    .fromSip_LC22IP_bits    (sip_toMvip_LC22IP_bits),
    .fromSip_LC23IP_valid   (sip_toMvip_LC23IP_valid),
    .fromSip_LC23IP_bits    (sip_toMvip_LC23IP_bits),
    .fromSip_LC24IP_valid   (sip_toMvip_LC24IP_valid),
    .fromSip_LC24IP_bits    (sip_toMvip_LC24IP_bits),
    .fromSip_LC25IP_valid   (sip_toMvip_LC25IP_valid),
    .fromSip_LC25IP_bits    (sip_toMvip_LC25IP_bits),
    .fromSip_LC26IP_valid   (sip_toMvip_LC26IP_valid),
    .fromSip_LC26IP_bits    (sip_toMvip_LC26IP_bits),
    .fromSip_LC27IP_valid   (sip_toMvip_LC27IP_valid),
    .fromSip_LC27IP_bits    (sip_toMvip_LC27IP_bits),
    .fromSip_LC28IP_valid   (sip_toMvip_LC28IP_valid),
    .fromSip_LC28IP_bits    (sip_toMvip_LC28IP_bits),
    .fromSip_LC29IP_valid   (sip_toMvip_LC29IP_valid),
    .fromSip_LC29IP_bits    (sip_toMvip_LC29IP_bits),
    .fromSip_LC30IP_valid   (sip_toMvip_LC30IP_valid),
    .fromSip_LC30IP_bits    (sip_toMvip_LC30IP_bits),
    .fromSip_LC31IP_valid   (sip_toMvip_LC31IP_valid),
    .fromSip_LC31IP_bits    (sip_toMvip_LC31IP_bits),
    .fromSip_LC32IP_valid   (sip_toMvip_LC32IP_valid),
    .fromSip_LC32IP_bits    (sip_toMvip_LC32IP_bits),
    .fromSip_LC33IP_valid   (sip_toMvip_LC33IP_valid),
    .fromSip_LC33IP_bits    (sip_toMvip_LC33IP_bits),
    .fromSip_LC34IP_valid   (sip_toMvip_LC34IP_valid),
    .fromSip_LC34IP_bits    (sip_toMvip_LC34IP_bits),
    .fromSip_LPRASEIP_valid (sip_toMvip_LPRASEIP_valid),
    .fromSip_LPRASEIP_bits  (sip_toMvip_LPRASEIP_bits),
    .fromSip_LC36IP_valid   (sip_toMvip_LC36IP_valid),
    .fromSip_LC36IP_bits    (sip_toMvip_LC36IP_bits),
    .fromSip_LC37IP_valid   (sip_toMvip_LC37IP_valid),
    .fromSip_LC37IP_bits    (sip_toMvip_LC37IP_bits),
    .fromSip_LC38IP_valid   (sip_toMvip_LC38IP_valid),
    .fromSip_LC38IP_bits    (sip_toMvip_LC38IP_bits),
    .fromSip_LC39IP_valid   (sip_toMvip_LC39IP_valid),
    .fromSip_LC39IP_bits    (sip_toMvip_LC39IP_bits),
    .fromSip_LC40IP_valid   (sip_toMvip_LC40IP_valid),
    .fromSip_LC40IP_bits    (sip_toMvip_LC40IP_bits),
    .fromSip_LC41IP_valid   (sip_toMvip_LC41IP_valid),
    .fromSip_LC41IP_bits    (sip_toMvip_LC41IP_bits),
    .fromSip_LC42IP_valid   (sip_toMvip_LC42IP_valid),
    .fromSip_LC42IP_bits    (sip_toMvip_LC42IP_bits),
    .fromSip_HPRASEIP_valid (sip_toMvip_HPRASEIP_valid),
    .fromSip_HPRASEIP_bits  (sip_toMvip_HPRASEIP_bits),
    .fromSip_LC44IP_valid   (sip_toMvip_LC44IP_valid),
    .fromSip_LC44IP_bits    (sip_toMvip_LC44IP_bits),
    .fromSip_LC45IP_valid   (sip_toMvip_LC45IP_valid),
    .fromSip_LC45IP_bits    (sip_toMvip_LC45IP_bits),
    .fromSip_LC46IP_valid   (sip_toMvip_LC46IP_valid),
    .fromSip_LC46IP_bits    (sip_toMvip_LC46IP_bits),
    .fromSip_LC47IP_valid   (sip_toMvip_LC47IP_valid),
    .fromSip_LC47IP_bits    (sip_toMvip_LC47IP_bits),
    .fromSip_LC48IP_valid   (sip_toMvip_LC48IP_valid),
    .fromSip_LC48IP_bits    (sip_toMvip_LC48IP_bits),
    .fromSip_LC49IP_valid   (sip_toMvip_LC49IP_valid),
    .fromSip_LC49IP_bits    (sip_toMvip_LC49IP_bits),
    .fromSip_LC50IP_valid   (sip_toMvip_LC50IP_valid),
    .fromSip_LC50IP_bits    (sip_toMvip_LC50IP_bits),
    .fromSip_LC51IP_valid   (sip_toMvip_LC51IP_valid),
    .fromSip_LC51IP_bits    (sip_toMvip_LC51IP_bits),
    .fromSip_LC52IP_valid   (sip_toMvip_LC52IP_valid),
    .fromSip_LC52IP_bits    (sip_toMvip_LC52IP_bits),
    .fromSip_LC53IP_valid   (sip_toMvip_LC53IP_valid),
    .fromSip_LC53IP_bits    (sip_toMvip_LC53IP_bits),
    .fromSip_LC54IP_valid   (sip_toMvip_LC54IP_valid),
    .fromSip_LC54IP_bits    (sip_toMvip_LC54IP_bits),
    .fromSip_LC55IP_valid   (sip_toMvip_LC55IP_valid),
    .fromSip_LC55IP_bits    (sip_toMvip_LC55IP_bits),
    .fromSip_LC56IP_valid   (sip_toMvip_LC56IP_valid),
    .fromSip_LC56IP_bits    (sip_toMvip_LC56IP_bits),
    .fromSip_LC57IP_valid   (sip_toMvip_LC57IP_valid),
    .fromSip_LC57IP_bits    (sip_toMvip_LC57IP_bits),
    .fromSip_LC58IP_valid   (sip_toMvip_LC58IP_valid),
    .fromSip_LC58IP_bits    (sip_toMvip_LC58IP_bits),
    .fromSip_LC59IP_valid   (sip_toMvip_LC59IP_valid),
    .fromSip_LC59IP_bits    (sip_toMvip_LC59IP_bits),
    .fromSip_LC60IP_valid   (sip_toMvip_LC60IP_valid),
    .fromSip_LC60IP_bits    (sip_toMvip_LC60IP_bits),
    .fromSip_LC61IP_valid   (sip_toMvip_LC61IP_valid),
    .fromSip_LC61IP_bits    (sip_toMvip_LC61IP_bits),
    .fromSip_LC62IP_valid   (sip_toMvip_LC62IP_valid),
    .fromSip_LC62IP_bits    (sip_toMvip_LC62IP_bits),
    .fromSip_LC63IP_valid   (sip_toMvip_LC63IP_valid),
    .fromSip_LC63IP_bits    (sip_toMvip_LC63IP_bits)
  );
  MenvcfgModule menvcfg (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_menvcfg),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (menvcfg_rdata),
    .regOut_STCE  (menvcfg_regOut_STCE),
    .regOut_PBMTE (menvcfg_regOut_PBMTE),
    .regOut_DTE   (menvcfg_regOut_DTE),
    .regOut_PMM   (menvcfg_regOut_PMM),
    .regOut_CBZE  (menvcfg_regOut_CBZE),
    .regOut_CBCFE (menvcfg_regOut_CBCFE),
    .regOut_CBIE  (menvcfg_regOut_CBIE)
  );
  McountinhibitModule mcountinhibit (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_mcountinhibit),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (mcountinhibit_rdata),
    .regOut_CY   (mcountinhibit_regOut_CY),
    .regOut_IR   (mcountinhibit_regOut_IR),
    .regOut_HPM3 (mcountinhibit_regOut_HPM3)
  );
  MhpmeventModule Mhpmevent3 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent3),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent3_rdata),
    .regOut_OF      (Mhpmevent3_regOut_OF),
    .regOut_MINH    (Mhpmevent3_regOut_MINH),
    .regOut_SINH    (Mhpmevent3_regOut_SINH),
    .regOut_UINH    (Mhpmevent3_regOut_UINH),
    .regOut_VSINH   (Mhpmevent3_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent3_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent3_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent3_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent3_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent3_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent3_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent3_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent3_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_0_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent4 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent4),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent4_rdata),
    .regOut_OF      (Mhpmevent4_regOut_OF),
    .regOut_MINH    (Mhpmevent4_regOut_MINH),
    .regOut_SINH    (Mhpmevent4_regOut_SINH),
    .regOut_UINH    (Mhpmevent4_regOut_UINH),
    .regOut_VSINH   (Mhpmevent4_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent4_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent4_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent4_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent4_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent4_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent4_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent4_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent4_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_1_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent5 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent5),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent5_rdata),
    .regOut_OF      (Mhpmevent5_regOut_OF),
    .regOut_MINH    (Mhpmevent5_regOut_MINH),
    .regOut_SINH    (Mhpmevent5_regOut_SINH),
    .regOut_UINH    (Mhpmevent5_regOut_UINH),
    .regOut_VSINH   (Mhpmevent5_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent5_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent5_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent5_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent5_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent5_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent5_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent5_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent5_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_2_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent6 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent6),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent6_rdata),
    .regOut_OF      (Mhpmevent6_regOut_OF),
    .regOut_MINH    (Mhpmevent6_regOut_MINH),
    .regOut_SINH    (Mhpmevent6_regOut_SINH),
    .regOut_UINH    (Mhpmevent6_regOut_UINH),
    .regOut_VSINH   (Mhpmevent6_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent6_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent6_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent6_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent6_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent6_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent6_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent6_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent6_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_3_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent7 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent7),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent7_rdata),
    .regOut_OF      (Mhpmevent7_regOut_OF),
    .regOut_MINH    (Mhpmevent7_regOut_MINH),
    .regOut_SINH    (Mhpmevent7_regOut_SINH),
    .regOut_UINH    (Mhpmevent7_regOut_UINH),
    .regOut_VSINH   (Mhpmevent7_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent7_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent7_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent7_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent7_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent7_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent7_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent7_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent7_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_4_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent8 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent8),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent8_rdata),
    .regOut_OF      (Mhpmevent8_regOut_OF),
    .regOut_MINH    (Mhpmevent8_regOut_MINH),
    .regOut_SINH    (Mhpmevent8_regOut_SINH),
    .regOut_UINH    (Mhpmevent8_regOut_UINH),
    .regOut_VSINH   (Mhpmevent8_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent8_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent8_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent8_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent8_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent8_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent8_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent8_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent8_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_5_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent9 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent9),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent9_rdata),
    .regOut_OF      (Mhpmevent9_regOut_OF),
    .regOut_MINH    (Mhpmevent9_regOut_MINH),
    .regOut_SINH    (Mhpmevent9_regOut_SINH),
    .regOut_UINH    (Mhpmevent9_regOut_UINH),
    .regOut_VSINH   (Mhpmevent9_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent9_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent9_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent9_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent9_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent9_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent9_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent9_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent9_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_6_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent10 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent10),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent10_rdata),
    .regOut_OF      (Mhpmevent10_regOut_OF),
    .regOut_MINH    (Mhpmevent10_regOut_MINH),
    .regOut_SINH    (Mhpmevent10_regOut_SINH),
    .regOut_UINH    (Mhpmevent10_regOut_UINH),
    .regOut_VSINH   (Mhpmevent10_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent10_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent10_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent10_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent10_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent10_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent10_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent10_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent10_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_7_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent11 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent11),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent11_rdata),
    .regOut_OF      (Mhpmevent11_regOut_OF),
    .regOut_MINH    (Mhpmevent11_regOut_MINH),
    .regOut_SINH    (Mhpmevent11_regOut_SINH),
    .regOut_UINH    (Mhpmevent11_regOut_UINH),
    .regOut_VSINH   (Mhpmevent11_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent11_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent11_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent11_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent11_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent11_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent11_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent11_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent11_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_8_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent12 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent12),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent12_rdata),
    .regOut_OF      (Mhpmevent12_regOut_OF),
    .regOut_MINH    (Mhpmevent12_regOut_MINH),
    .regOut_SINH    (Mhpmevent12_regOut_SINH),
    .regOut_UINH    (Mhpmevent12_regOut_UINH),
    .regOut_VSINH   (Mhpmevent12_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent12_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent12_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent12_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent12_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent12_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent12_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent12_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent12_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_9_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent13 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent13),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent13_rdata),
    .regOut_OF      (Mhpmevent13_regOut_OF),
    .regOut_MINH    (Mhpmevent13_regOut_MINH),
    .regOut_SINH    (Mhpmevent13_regOut_SINH),
    .regOut_UINH    (Mhpmevent13_regOut_UINH),
    .regOut_VSINH   (Mhpmevent13_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent13_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent13_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent13_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent13_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent13_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent13_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent13_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent13_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_10_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent14 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent14),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent14_rdata),
    .regOut_OF      (Mhpmevent14_regOut_OF),
    .regOut_MINH    (Mhpmevent14_regOut_MINH),
    .regOut_SINH    (Mhpmevent14_regOut_SINH),
    .regOut_UINH    (Mhpmevent14_regOut_UINH),
    .regOut_VSINH   (Mhpmevent14_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent14_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent14_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent14_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent14_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent14_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent14_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent14_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent14_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_11_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent15 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent15),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent15_rdata),
    .regOut_OF      (Mhpmevent15_regOut_OF),
    .regOut_MINH    (Mhpmevent15_regOut_MINH),
    .regOut_SINH    (Mhpmevent15_regOut_SINH),
    .regOut_UINH    (Mhpmevent15_regOut_UINH),
    .regOut_VSINH   (Mhpmevent15_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent15_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent15_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent15_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent15_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent15_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent15_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent15_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent15_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_12_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent16 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent16),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent16_rdata),
    .regOut_OF      (Mhpmevent16_regOut_OF),
    .regOut_MINH    (Mhpmevent16_regOut_MINH),
    .regOut_SINH    (Mhpmevent16_regOut_SINH),
    .regOut_UINH    (Mhpmevent16_regOut_UINH),
    .regOut_VSINH   (Mhpmevent16_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent16_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent16_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent16_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent16_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent16_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent16_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent16_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent16_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_13_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent17 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent17),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent17_rdata),
    .regOut_OF      (Mhpmevent17_regOut_OF),
    .regOut_MINH    (Mhpmevent17_regOut_MINH),
    .regOut_SINH    (Mhpmevent17_regOut_SINH),
    .regOut_UINH    (Mhpmevent17_regOut_UINH),
    .regOut_VSINH   (Mhpmevent17_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent17_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent17_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent17_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent17_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent17_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent17_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent17_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent17_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_14_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent18 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent18),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent18_rdata),
    .regOut_OF      (Mhpmevent18_regOut_OF),
    .regOut_MINH    (Mhpmevent18_regOut_MINH),
    .regOut_SINH    (Mhpmevent18_regOut_SINH),
    .regOut_UINH    (Mhpmevent18_regOut_UINH),
    .regOut_VSINH   (Mhpmevent18_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent18_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent18_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent18_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent18_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent18_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent18_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent18_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent18_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_15_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent19 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent19),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent19_rdata),
    .regOut_OF      (Mhpmevent19_regOut_OF),
    .regOut_MINH    (Mhpmevent19_regOut_MINH),
    .regOut_SINH    (Mhpmevent19_regOut_SINH),
    .regOut_UINH    (Mhpmevent19_regOut_UINH),
    .regOut_VSINH   (Mhpmevent19_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent19_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent19_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent19_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent19_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent19_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent19_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent19_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent19_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_16_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent20 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent20),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent20_rdata),
    .regOut_OF      (Mhpmevent20_regOut_OF),
    .regOut_MINH    (Mhpmevent20_regOut_MINH),
    .regOut_SINH    (Mhpmevent20_regOut_SINH),
    .regOut_UINH    (Mhpmevent20_regOut_UINH),
    .regOut_VSINH   (Mhpmevent20_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent20_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent20_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent20_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent20_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent20_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent20_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent20_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent20_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_17_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent21 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent21),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent21_rdata),
    .regOut_OF      (Mhpmevent21_regOut_OF),
    .regOut_MINH    (Mhpmevent21_regOut_MINH),
    .regOut_SINH    (Mhpmevent21_regOut_SINH),
    .regOut_UINH    (Mhpmevent21_regOut_UINH),
    .regOut_VSINH   (Mhpmevent21_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent21_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent21_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent21_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent21_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent21_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent21_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent21_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent21_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_18_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent22 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent22),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent22_rdata),
    .regOut_OF      (Mhpmevent22_regOut_OF),
    .regOut_MINH    (Mhpmevent22_regOut_MINH),
    .regOut_SINH    (Mhpmevent22_regOut_SINH),
    .regOut_UINH    (Mhpmevent22_regOut_UINH),
    .regOut_VSINH   (Mhpmevent22_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent22_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent22_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent22_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent22_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent22_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent22_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent22_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent22_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_19_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent23 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent23),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent23_rdata),
    .regOut_OF      (Mhpmevent23_regOut_OF),
    .regOut_MINH    (Mhpmevent23_regOut_MINH),
    .regOut_SINH    (Mhpmevent23_regOut_SINH),
    .regOut_UINH    (Mhpmevent23_regOut_UINH),
    .regOut_VSINH   (Mhpmevent23_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent23_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent23_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent23_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent23_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent23_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent23_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent23_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent23_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_20_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent24 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent24),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent24_rdata),
    .regOut_OF      (Mhpmevent24_regOut_OF),
    .regOut_MINH    (Mhpmevent24_regOut_MINH),
    .regOut_SINH    (Mhpmevent24_regOut_SINH),
    .regOut_UINH    (Mhpmevent24_regOut_UINH),
    .regOut_VSINH   (Mhpmevent24_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent24_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent24_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent24_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent24_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent24_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent24_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent24_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent24_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_21_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent25 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent25),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent25_rdata),
    .regOut_OF      (Mhpmevent25_regOut_OF),
    .regOut_MINH    (Mhpmevent25_regOut_MINH),
    .regOut_SINH    (Mhpmevent25_regOut_SINH),
    .regOut_UINH    (Mhpmevent25_regOut_UINH),
    .regOut_VSINH   (Mhpmevent25_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent25_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent25_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent25_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent25_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent25_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent25_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent25_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent25_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_22_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent26 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent26),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent26_rdata),
    .regOut_OF      (Mhpmevent26_regOut_OF),
    .regOut_MINH    (Mhpmevent26_regOut_MINH),
    .regOut_SINH    (Mhpmevent26_regOut_SINH),
    .regOut_UINH    (Mhpmevent26_regOut_UINH),
    .regOut_VSINH   (Mhpmevent26_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent26_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent26_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent26_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent26_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent26_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent26_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent26_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent26_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_23_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent27 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent27),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent27_rdata),
    .regOut_OF      (Mhpmevent27_regOut_OF),
    .regOut_MINH    (Mhpmevent27_regOut_MINH),
    .regOut_SINH    (Mhpmevent27_regOut_SINH),
    .regOut_UINH    (Mhpmevent27_regOut_UINH),
    .regOut_VSINH   (Mhpmevent27_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent27_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent27_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent27_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent27_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent27_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent27_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent27_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent27_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_24_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent28 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent28),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent28_rdata),
    .regOut_OF      (Mhpmevent28_regOut_OF),
    .regOut_MINH    (Mhpmevent28_regOut_MINH),
    .regOut_SINH    (Mhpmevent28_regOut_SINH),
    .regOut_UINH    (Mhpmevent28_regOut_UINH),
    .regOut_VSINH   (Mhpmevent28_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent28_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent28_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent28_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent28_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent28_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent28_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent28_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent28_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_25_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent29 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent29),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent29_rdata),
    .regOut_OF      (Mhpmevent29_regOut_OF),
    .regOut_MINH    (Mhpmevent29_regOut_MINH),
    .regOut_SINH    (Mhpmevent29_regOut_SINH),
    .regOut_UINH    (Mhpmevent29_regOut_UINH),
    .regOut_VSINH   (Mhpmevent29_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent29_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent29_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent29_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent29_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent29_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent29_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent29_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent29_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_26_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent30 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent30),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent30_rdata),
    .regOut_OF      (Mhpmevent30_regOut_OF),
    .regOut_MINH    (Mhpmevent30_regOut_MINH),
    .regOut_SINH    (Mhpmevent30_regOut_SINH),
    .regOut_UINH    (Mhpmevent30_regOut_UINH),
    .regOut_VSINH   (Mhpmevent30_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent30_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent30_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent30_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent30_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent30_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent30_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent30_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent30_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_27_toMhpmeventOF)
  );
  MhpmeventModule Mhpmevent31 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_Mhpmevent31),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (Mhpmevent31_rdata),
    .regOut_OF      (Mhpmevent31_regOut_OF),
    .regOut_MINH    (Mhpmevent31_regOut_MINH),
    .regOut_SINH    (Mhpmevent31_regOut_SINH),
    .regOut_UINH    (Mhpmevent31_regOut_UINH),
    .regOut_VSINH   (Mhpmevent31_regOut_VSINH),
    .regOut_VUINH   (Mhpmevent31_regOut_VUINH),
    .regOut_OPTYPE2 (Mhpmevent31_regOut_OPTYPE2),
    .regOut_OPTYPE1 (Mhpmevent31_regOut_OPTYPE1),
    .regOut_OPTYPE0 (Mhpmevent31_regOut_OPTYPE0),
    .regOut_EVENT3  (Mhpmevent31_regOut_EVENT3),
    .regOut_EVENT2  (Mhpmevent31_regOut_EVENT2),
    .regOut_EVENT1  (Mhpmevent31_regOut_EVENT1),
    .regOut_EVENT0  (Mhpmevent31_regOut_EVENT0),
    .ofFromPerfCnt  (mhpmcounters_28_toMhpmeventOF)
  );
  MscratchModule mscratch (
    .clock      (clock),
    .w_wen      (wen_mscratch),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (mscratch_rdata),
    .regOut_ALL (mscratch_regOut_ALL)
  );
  MepcModule mepc (
    .clock                 (clock),
    .reset                 (reset),
    .w_wen                 (wen_mepc),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (mepc_rdata),
    .regOut_epc            (mepc_regOut_epc),
    .trapToM_mepc_valid    (trapEntryMEvent_out_mepc_valid),
    .trapToM_mepc_bits_epc (trapEntryMEvent_out_mepc_bits_epc)
  );
  McauseModule mcause (
    .clock                             (clock),
    .reset                             (reset),
    .w_wen                             (wen_mcause),
    .w_wdata                           (io_in_bits_wdata),
    .rdata                             (mcause_rdata),
    .regOut_Interrupt                  (mcause_regOut_Interrupt),
    .regOut_ExceptionCode              (mcause_regOut_ExceptionCode),
    .trapToM_mcause_valid              (trapEntryMEvent_out_mcause_valid),
    .trapToM_mcause_bits_Interrupt     (trapEntryMEvent_out_mcause_bits_Interrupt),
    .trapToM_mcause_bits_ExceptionCode (trapEntryMEvent_out_mcause_bits_ExceptionCode)
  );
  MtvalModule mtval (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_mtval),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (mtval_rdata),
    .regOut_ALL             (mtval_regOut_ALL),
    .trapToM_mtval_valid    (trapEntryMEvent_out_mtval_valid),
    .trapToM_mtval_bits_ALL (trapEntryMEvent_out_mtval_bits_ALL)
  );
  MipModule mip (
    .clock                 (clock),
    .reset                 (reset),
    .w_wen                 (wen_mip),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (mip_rdata),
    .regOut_SSIP           (mip_regOut_SSIP),
    .regOut_VSSIP          (mip_regOut_VSSIP),
    .regOut_MSIP           (mip_regOut_MSIP),
    .regOut_STIP           (mip_regOut_STIP),
    .regOut_VSTIP          (mip_regOut_VSTIP),
    .regOut_MTIP           (mip_regOut_MTIP),
    .regOut_SEIP           (mip_regOut_SEIP),
    .regOut_VSEIP          (mip_regOut_VSEIP),
    .regOut_MEIP           (mip_regOut_MEIP),
    .regOut_SGEIP          (mip_regOut_SGEIP),
    .regOut_LCOFIP         (mip_regOut_LCOFIP),
    .rdataFields_SSIP      (mip_rdataFields_SSIP),
    .rdataFields_VSSIP     (mip_rdataFields_VSSIP),
    .rdataFields_MSIP      (mip_rdataFields_MSIP),
    .rdataFields_STIP      (mip_rdataFields_STIP),
    .rdataFields_VSTIP     (mip_rdataFields_VSTIP),
    .rdataFields_MTIP      (mip_rdataFields_MTIP),
    .rdataFields_SEIP      (mip_rdataFields_SEIP),
    .rdataFields_VSEIP     (mip_rdataFields_VSEIP),
    .rdataFields_MEIP      (mip_rdataFields_MEIP),
    .rdataFields_SGEIP     (mip_rdataFields_SGEIP),
    .rdataFields_LCOFIP    (mip_rdataFields_LCOFIP),
    .mvip_SEIP             (mvip_regOut_SEIP),
    .mvien_SEIE            (mvien_regOut_SEIE),
    .hvip_VSSIP            (hvip_regOut_VSSIP),
    .hvip_VSTIP            (hvip_regOut_VSTIP),
    .hvip_VSEIP            (hvip_regOut_VSEIP),
    .hgeip_ip              (hgeip_regOut_ip),
    .hgeie_ie              (hgeie_regOut_ie),
    .hstatusVGEIN          (hstatus_regOut_VGEIN),
    .platformIRP_MEIP      (platformIRP_MEIP),
    .platformIRP_MTIP      (platformIRP_MTIP),
    .platformIRP_MSIP      (platformIRP_MSIP),
    .platformIRP_SEIP      (platformIRP_SEIP),
    .platformIRP_STIP      (sstcIRGen_o_STIP),
    .platformIRP_VSTIP     (sstcIRGen_o_VSTIP),
    .menvcfg_STCE          (menvcfg_regOut_STCE),
    .lcofiReq              (lcofi_req),
    .aiaToCSR_meip         (fromAIA_meip),
    .aiaToCSR_seip         (fromAIA_seip),
    .fromMvip_SSIP_valid   (mvip_toMip_SSIP_valid),
    .fromMvip_SSIP_bits    (mvip_toMip_SSIP_bits),
    .fromMvip_STIP_valid   (mvip_toMip_STIP_valid),
    .fromMvip_STIP_bits    (mvip_toMip_STIP_bits),
    .fromSip_SSIP_valid    (sip_toMip_SSIP_valid),
    .fromSip_SSIP_bits     (sip_toMip_SSIP_bits),
    .fromSip_LCOFIP_valid  (sip_toMip_LCOFIP_valid),
    .fromSip_LCOFIP_bits   (sip_toMip_LCOFIP_bits),
    .fromVSip_LCOFIP_valid (vsip_toMip_LCOFIP_valid),
    .fromVSip_LCOFIP_bits  (vsip_toMip_LCOFIP_bits),
    .toMvip_SEIP_valid     (mip_toMvip_SEIP_valid),
    .toMvip_SEIP_bits      (mip_toMvip_SEIP_bits),
    .toHvip_VSSIP_valid    (mip_toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits     (mip_toHvip_VSSIP_bits)
  );
  MtinstModule mtinst (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_mtinst),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (mtinst_rdata),
    .regOut_ALL              (mtinst_regOut_ALL),
    .trapToM_mtinst_valid    (trapEntryMEvent_out_mtinst_valid),
    .trapToM_mtinst_bits_ALL (trapEntryMEvent_out_mtinst_bits_ALL)
  );
  Mtval2Module mtval2 (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_mtval2),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (mtval2_rdata),
    .regOut_ALL              (mtval2_regOut_ALL),
    .trapToM_mtval2_valid    (trapEntryMEvent_out_mtval2_valid),
    .trapToM_mtval2_bits_ALL (trapEntryMEvent_out_mtval2_bits_ALL)
  );
  MseccfgModule mseccfg (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_mseccfg),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (mseccfg_rdata),
    .regOut_PMM (mseccfg_regOut_PMM)
  );
  McycleModule mcycle (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_mcycle),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (mcycle_rdata),
    .regOut_ALL       (mcycle_regOut_ALL),
    .mcountinhibit_CY (mcountinhibit_regOut_CY)
  );
  MinstretModule minstret (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_minstret),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (minstret_rdata),
    .regOut_ALL             (minstret_regOut_ALL),
    .mcountinhibit_IR       (mcountinhibit_regOut_IR),
    .robCommit_instNum_bits (io_fromRob_commit_instNum_bits)
  );
  Mhpmcounter3Module mhpmcounters_0 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_0),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_0_rdata),
    .regOut_ALL         (mhpmcounters_0_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[0]),
    .perf_value         (io_perf_perfEventsFrontend_0_value),
    .toMhpmeventOF      (mhpmcounters_0_toMhpmeventOF)
  );
  Mhpmcounter4Module mhpmcounters_1 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_1),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_1_rdata),
    .regOut_ALL         (mhpmcounters_1_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[1]),
    .perf_value         (io_perf_perfEventsFrontend_1_value),
    .toMhpmeventOF      (mhpmcounters_1_toMhpmeventOF)
  );
  Mhpmcounter5Module mhpmcounters_2 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_2),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_2_rdata),
    .regOut_ALL         (mhpmcounters_2_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[2]),
    .perf_value         (io_perf_perfEventsFrontend_2_value),
    .toMhpmeventOF      (mhpmcounters_2_toMhpmeventOF)
  );
  Mhpmcounter6Module mhpmcounters_3 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_3),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_3_rdata),
    .regOut_ALL         (mhpmcounters_3_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[3]),
    .perf_value         (io_perf_perfEventsFrontend_3_value),
    .toMhpmeventOF      (mhpmcounters_3_toMhpmeventOF)
  );
  Mhpmcounter7Module mhpmcounters_4 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_4),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_4_rdata),
    .regOut_ALL         (mhpmcounters_4_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[4]),
    .perf_value         (io_perf_perfEventsFrontend_4_value),
    .toMhpmeventOF      (mhpmcounters_4_toMhpmeventOF)
  );
  Mhpmcounter8Module mhpmcounters_5 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_5),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_5_rdata),
    .regOut_ALL         (mhpmcounters_5_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[5]),
    .perf_value         (io_perf_perfEventsFrontend_5_value),
    .toMhpmeventOF      (mhpmcounters_5_toMhpmeventOF)
  );
  Mhpmcounter9Module mhpmcounters_6 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_6),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_6_rdata),
    .regOut_ALL         (mhpmcounters_6_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[6]),
    .perf_value         (io_perf_perfEventsFrontend_6_value),
    .toMhpmeventOF      (mhpmcounters_6_toMhpmeventOF)
  );
  Mhpmcounter10Module mhpmcounters_7 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_7),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_7_rdata),
    .regOut_ALL         (mhpmcounters_7_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[7]),
    .perf_value         (io_perf_perfEventsFrontend_7_value),
    .toMhpmeventOF      (mhpmcounters_7_toMhpmeventOF)
  );
  Mhpmcounter11Module mhpmcounters_8 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_8),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_8_rdata),
    .regOut_ALL         (mhpmcounters_8_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[8]),
    .perf_value         (io_perf_perfEventsBackend_0_value),
    .toMhpmeventOF      (mhpmcounters_8_toMhpmeventOF)
  );
  Mhpmcounter12Module mhpmcounters_9 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_9),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_9_rdata),
    .regOut_ALL         (mhpmcounters_9_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[9]),
    .perf_value         (io_perf_perfEventsBackend_1_value),
    .toMhpmeventOF      (mhpmcounters_9_toMhpmeventOF)
  );
  Mhpmcounter13Module mhpmcounters_10 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_10),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_10_rdata),
    .regOut_ALL         (mhpmcounters_10_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[10]),
    .perf_value         (io_perf_perfEventsBackend_2_value),
    .toMhpmeventOF      (mhpmcounters_10_toMhpmeventOF)
  );
  Mhpmcounter14Module mhpmcounters_11 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_11),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_11_rdata),
    .regOut_ALL         (mhpmcounters_11_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[11]),
    .perf_value         (io_perf_perfEventsBackend_3_value),
    .toMhpmeventOF      (mhpmcounters_11_toMhpmeventOF)
  );
  Mhpmcounter15Module mhpmcounters_12 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_12),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_12_rdata),
    .regOut_ALL         (mhpmcounters_12_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[12]),
    .perf_value         (io_perf_perfEventsBackend_4_value),
    .toMhpmeventOF      (mhpmcounters_12_toMhpmeventOF)
  );
  Mhpmcounter16Module mhpmcounters_13 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_13),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_13_rdata),
    .regOut_ALL         (mhpmcounters_13_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[13]),
    .perf_value         (io_perf_perfEventsBackend_5_value),
    .toMhpmeventOF      (mhpmcounters_13_toMhpmeventOF)
  );
  Mhpmcounter17Module mhpmcounters_14 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_14),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_14_rdata),
    .regOut_ALL         (mhpmcounters_14_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[14]),
    .perf_value         (io_perf_perfEventsBackend_6_value),
    .toMhpmeventOF      (mhpmcounters_14_toMhpmeventOF)
  );
  Mhpmcounter18Module mhpmcounters_15 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_15),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_15_rdata),
    .regOut_ALL         (mhpmcounters_15_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[15]),
    .perf_value         (io_perf_perfEventsBackend_7_value),
    .toMhpmeventOF      (mhpmcounters_15_toMhpmeventOF)
  );
  Mhpmcounter19Module mhpmcounters_16 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_16),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_16_rdata),
    .regOut_ALL         (mhpmcounters_16_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[16]),
    .perf_value         (io_perf_perfEventsLsu_0_value),
    .toMhpmeventOF      (mhpmcounters_16_toMhpmeventOF)
  );
  Mhpmcounter20Module mhpmcounters_17 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_17),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_17_rdata),
    .regOut_ALL         (mhpmcounters_17_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[17]),
    .perf_value         (io_perf_perfEventsLsu_1_value),
    .toMhpmeventOF      (mhpmcounters_17_toMhpmeventOF)
  );
  Mhpmcounter21Module mhpmcounters_18 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_18),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_18_rdata),
    .regOut_ALL         (mhpmcounters_18_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[18]),
    .perf_value         (io_perf_perfEventsLsu_2_value),
    .toMhpmeventOF      (mhpmcounters_18_toMhpmeventOF)
  );
  Mhpmcounter22Module mhpmcounters_19 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_19),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_19_rdata),
    .regOut_ALL         (mhpmcounters_19_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[19]),
    .perf_value         (io_perf_perfEventsLsu_3_value),
    .toMhpmeventOF      (mhpmcounters_19_toMhpmeventOF)
  );
  Mhpmcounter23Module mhpmcounters_20 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_20),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_20_rdata),
    .regOut_ALL         (mhpmcounters_20_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[20]),
    .perf_value         (io_perf_perfEventsLsu_4_value),
    .toMhpmeventOF      (mhpmcounters_20_toMhpmeventOF)
  );
  Mhpmcounter24Module mhpmcounters_21 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_21),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_21_rdata),
    .regOut_ALL         (mhpmcounters_21_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[21]),
    .perf_value         (io_perf_perfEventsLsu_5_value),
    .toMhpmeventOF      (mhpmcounters_21_toMhpmeventOF)
  );
  Mhpmcounter25Module mhpmcounters_22 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_22),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_22_rdata),
    .regOut_ALL         (mhpmcounters_22_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[22]),
    .perf_value         (io_perf_perfEventsLsu_6_value),
    .toMhpmeventOF      (mhpmcounters_22_toMhpmeventOF)
  );
  Mhpmcounter26Module mhpmcounters_23 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_23),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_23_rdata),
    .regOut_ALL         (mhpmcounters_23_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[23]),
    .perf_value         (io_perf_perfEventsLsu_7_value),
    .toMhpmeventOF      (mhpmcounters_23_toMhpmeventOF)
  );
  Mhpmcounter27Module mhpmcounters_24 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_24),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_24_rdata),
    .regOut_ALL         (mhpmcounters_24_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[24]),
    .perf_value         (hpmHc_io_perf_0_value),
    .toMhpmeventOF      (mhpmcounters_24_toMhpmeventOF)
  );
  Mhpmcounter28Module mhpmcounters_25 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_25),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_25_rdata),
    .regOut_ALL         (mhpmcounters_25_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[25]),
    .perf_value         (hpmHc_io_perf_1_value),
    .toMhpmeventOF      (mhpmcounters_25_toMhpmeventOF)
  );
  Mhpmcounter29Module mhpmcounters_26 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_26),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_26_rdata),
    .regOut_ALL         (mhpmcounters_26_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[26]),
    .perf_value         (hpmHc_io_perf_2_value),
    .toMhpmeventOF      (mhpmcounters_26_toMhpmeventOF)
  );
  Mhpmcounter30Module mhpmcounters_27 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_27),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_27_rdata),
    .regOut_ALL         (mhpmcounters_27_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[27]),
    .perf_value         (hpmHc_io_perf_3_value),
    .toMhpmeventOF      (mhpmcounters_27_toMhpmeventOF)
  );
  Mhpmcounter31Module mhpmcounters_28 (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_mhpmcounters_28),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (mhpmcounters_28_rdata),
    .regOut_ALL         (mhpmcounters_28_regOut_ALL),
    .mcountinhibit_CY   (mcountinhibit_regOut_CY),
    .mcountinhibit_IR   (mcountinhibit_regOut_IR),
    .mcountinhibit_HPM3 (mcountinhibit_regOut_HPM3),
    .countingEn         (counting_en[28]),
    .perf_value         (hpmHc_io_perf_4_value),
    .toMhpmeventOF      (mhpmcounters_28_toMhpmeventOF)
  );
  MhartidModule mhartid (
    .rdata  (mhartid_rdata),
    .hartid (io_fromTop_hartId)
  );
  MconfigptrModule mconfigptr (
    .rdata (mconfigptr_rdata)
  );
  Mstateen0Module mstateen0 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_mstateen0),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (mstateen0_rdata),
    .regOut_SE0     (mstateen0_regOut_SE0),
    .regOut_ENVCFG  (mstateen0_regOut_ENVCFG),
    .regOut_CSRIND  (mstateen0_regOut_CSRIND),
    .regOut_AIA     (mstateen0_regOut_AIA),
    .regOut_IMSIC   (mstateen0_regOut_IMSIC),
    .regOut_CONTEXT (mstateen0_regOut_CONTEXT),
    .regOut_C       (mstateen0_regOut_C)
  );
  Mstateen1Module mstateen1 (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (wen_mstateen1),
    .w_wdata   (io_in_bits_wdata),
    .rdata     (mstateen1_rdata),
    .regOut_SE (mstateen1_regOut_SE)
  );
  Mstateen2Module mstateen2 (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (wen_mstateen2),
    .w_wdata   (io_in_bits_wdata),
    .rdata     (mstateen2_rdata),
    .regOut_SE (mstateen2_regOut_SE)
  );
  Mstateen3Module mstateen3 (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (wen_mstateen3),
    .w_wdata   (io_in_bits_wdata),
    .rdata     (mstateen3_rdata),
    .regOut_SE (mstateen3_regOut_SE)
  );
  MnepcModule mnepc (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_mnepc),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (mnepc_rdata),
    .regOut_epc              (mnepc_regOut_epc),
    .trapToMN_mnepc_valid    (trapEntryMNEvent_out_mnepc_valid),
    .trapToMN_mnepc_bits_epc (trapEntryMNEvent_out_mnepc_bits_epc)
  );
  MncauseModule mncause (
    .clock                               (clock),
    .reset                               (reset),
    .w_wen                               (wen_mncause),
    .w_wdata                             (io_in_bits_wdata),
    .rdata                               (mncause_rdata),
    .regOut_Interrupt                    (mncause_regOut_Interrupt),
    .regOut_ExceptionCode                (mncause_regOut_ExceptionCode),
    .trapToMN_mncause_valid              (trapEntryMNEvent_out_mncause_valid),
    .trapToMN_mncause_bits_Interrupt     (trapEntryMNEvent_out_mncause_bits_Interrupt),
    .trapToMN_mncause_bits_ExceptionCode (trapEntryMNEvent_out_mncause_bits_ExceptionCode)
  );
  MnstatusModule mnstatus (
    .clock                        (clock),
    .reset                        (reset),
    .w_wen                        (wen_mnstatus),
    .w_wdata                      (io_in_bits_wdata),
    .rdata                        (mnstatus_rdata),
    .regOut_NMIE                  (mnstatus_regOut_NMIE),
    .regOut_MNPV                  (mnstatus_regOut_MNPV),
    .regOut_MNPP                  (mnstatus_regOut_MNPP),
    .trapToMN_mnstatus_valid      (trapEntryMNEvent_out_mnstatus_valid),
    .trapToMN_mnstatus_bits_NMIE  (trapEntryMNEvent_out_mnstatus_bits_NMIE),
    .trapToMN_mnstatus_bits_MNPV  (trapEntryMNEvent_out_mnstatus_bits_MNPV),
    .trapToMN_mnstatus_bits_MNPP  (trapEntryMNEvent_out_mnstatus_bits_MNPP),
    .retFromMN_mnstatus_valid     (mnretEvent_out_mnstatus_valid),
    .retFromMN_mnstatus_bits_NMIE (mnretEvent_out_mnstatus_bits_NMIE)
  );
  MnscratchModule mnscratch (
    .clock      (clock),
    .w_wen      (wen_mnscratch),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (mnscratch_rdata),
    .regOut_ALL (mnscratch_regOut_ALL)
  );
  McontextModule mcontext (
    .clock                      (clock),
    .reset                      (reset),
    .w_wen                      (wen_mcontext),
    .w_wdata                    (io_in_bits_wdata),
    .rdata                      (mcontext_rdata),
    .regOut_HCONTEXT            (mcontext_regOut_HCONTEXT),
    .fromHcontext_valid         (hcontext_toMcontext_valid),
    .fromHcontext_bits_HCONTEXT (hcontext_toMcontext_bits_HCONTEXT),
    .toHcontext_HCONTEXT        (mcontext_toHcontext_HCONTEXT)
  );
  SieModule sie (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_sie),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (sie_rdata),
    .regOut_SSIE             (sie_regOut_SSIE),
    .regOut_STIE             (sie_regOut_STIE),
    .regOut_SEIE             (sie_regOut_SEIE),
    .regOut_LCOFIE           (sie_regOut_LCOFIE),
    .regOut_LC14IE           (sie_regOut_LC14IE),
    .regOut_LC15IE           (sie_regOut_LC15IE),
    .regOut_LC16IE           (sie_regOut_LC16IE),
    .regOut_LC17IE           (sie_regOut_LC17IE),
    .regOut_LC18IE           (sie_regOut_LC18IE),
    .regOut_LC19IE           (sie_regOut_LC19IE),
    .regOut_LC20IE           (sie_regOut_LC20IE),
    .regOut_LC21IE           (sie_regOut_LC21IE),
    .regOut_LC22IE           (sie_regOut_LC22IE),
    .regOut_LC23IE           (sie_regOut_LC23IE),
    .regOut_LC24IE           (sie_regOut_LC24IE),
    .regOut_LC25IE           (sie_regOut_LC25IE),
    .regOut_LC26IE           (sie_regOut_LC26IE),
    .regOut_LC27IE           (sie_regOut_LC27IE),
    .regOut_LC28IE           (sie_regOut_LC28IE),
    .regOut_LC29IE           (sie_regOut_LC29IE),
    .regOut_LC30IE           (sie_regOut_LC30IE),
    .regOut_LC31IE           (sie_regOut_LC31IE),
    .regOut_LC32IE           (sie_regOut_LC32IE),
    .regOut_LC33IE           (sie_regOut_LC33IE),
    .regOut_LC34IE           (sie_regOut_LC34IE),
    .regOut_LPRASEIE         (sie_regOut_LPRASEIE),
    .regOut_LC36IE           (sie_regOut_LC36IE),
    .regOut_LC37IE           (sie_regOut_LC37IE),
    .regOut_LC38IE           (sie_regOut_LC38IE),
    .regOut_LC39IE           (sie_regOut_LC39IE),
    .regOut_LC40IE           (sie_regOut_LC40IE),
    .regOut_LC41IE           (sie_regOut_LC41IE),
    .regOut_LC42IE           (sie_regOut_LC42IE),
    .regOut_HPRASEIE         (sie_regOut_HPRASEIE),
    .regOut_LC44IE           (sie_regOut_LC44IE),
    .regOut_LC45IE           (sie_regOut_LC45IE),
    .regOut_LC46IE           (sie_regOut_LC46IE),
    .regOut_LC47IE           (sie_regOut_LC47IE),
    .regOut_LC48IE           (sie_regOut_LC48IE),
    .regOut_LC49IE           (sie_regOut_LC49IE),
    .regOut_LC50IE           (sie_regOut_LC50IE),
    .regOut_LC51IE           (sie_regOut_LC51IE),
    .regOut_LC52IE           (sie_regOut_LC52IE),
    .regOut_LC53IE           (sie_regOut_LC53IE),
    .regOut_LC54IE           (sie_regOut_LC54IE),
    .regOut_LC55IE           (sie_regOut_LC55IE),
    .regOut_LC56IE           (sie_regOut_LC56IE),
    .regOut_LC57IE           (sie_regOut_LC57IE),
    .regOut_LC58IE           (sie_regOut_LC58IE),
    .regOut_LC59IE           (sie_regOut_LC59IE),
    .regOut_LC60IE           (sie_regOut_LC60IE),
    .regOut_LC61IE           (sie_regOut_LC61IE),
    .regOut_LC62IE           (sie_regOut_LC62IE),
    .regOut_LC63IE           (sie_regOut_LC63IE),
    .mideleg_SSI             (mideleg_regOut_SSI),
    .mideleg_STI             (mideleg_regOut_STI),
    .mideleg_SEI             (mideleg_regOut_SEI),
    .mideleg_LCOFI           (mideleg_regOut_LCOFI),
    .mie_SSIE                (mie_regOut_SSIE),
    .mie_VSSIE               (mie_regOut_VSSIE),
    .mie_MSIE                (mie_regOut_MSIE),
    .mie_STIE                (mie_regOut_STIE),
    .mie_VSTIE               (mie_regOut_VSTIE),
    .mie_MTIE                (mie_regOut_MTIE),
    .mie_SEIE                (mie_regOut_SEIE),
    .mie_VSEIE               (mie_regOut_VSEIE),
    .mie_MEIE                (mie_regOut_MEIE),
    .mie_SGEIE               (mie_regOut_SGEIE),
    .mie_LCOFIE              (mie_regOut_LCOFIE),
    .mvien_SSIE              (mvien_regOut_SSIE),
    .mvien_SEIE              (mvien_regOut_SEIE),
    .mvien_LC14IE            (mvien_regOut_LC14IE),
    .mvien_LC15IE            (mvien_regOut_LC15IE),
    .mvien_LC16IE            (mvien_regOut_LC16IE),
    .mvien_LC17IE            (mvien_regOut_LC17IE),
    .mvien_LC18IE            (mvien_regOut_LC18IE),
    .mvien_LC19IE            (mvien_regOut_LC19IE),
    .mvien_LC20IE            (mvien_regOut_LC20IE),
    .mvien_LC21IE            (mvien_regOut_LC21IE),
    .mvien_LC22IE            (mvien_regOut_LC22IE),
    .mvien_LC23IE            (mvien_regOut_LC23IE),
    .mvien_LC24IE            (mvien_regOut_LC24IE),
    .mvien_LC25IE            (mvien_regOut_LC25IE),
    .mvien_LC26IE            (mvien_regOut_LC26IE),
    .mvien_LC27IE            (mvien_regOut_LC27IE),
    .mvien_LC28IE            (mvien_regOut_LC28IE),
    .mvien_LC29IE            (mvien_regOut_LC29IE),
    .mvien_LC30IE            (mvien_regOut_LC30IE),
    .mvien_LC31IE            (mvien_regOut_LC31IE),
    .mvien_LC32IE            (mvien_regOut_LC32IE),
    .mvien_LC33IE            (mvien_regOut_LC33IE),
    .mvien_LC34IE            (mvien_regOut_LC34IE),
    .mvien_LPRASEIE          (mvien_regOut_LPRASEIE),
    .mvien_LC36IE            (mvien_regOut_LC36IE),
    .mvien_LC37IE            (mvien_regOut_LC37IE),
    .mvien_LC38IE            (mvien_regOut_LC38IE),
    .mvien_LC39IE            (mvien_regOut_LC39IE),
    .mvien_LC40IE            (mvien_regOut_LC40IE),
    .mvien_LC41IE            (mvien_regOut_LC41IE),
    .mvien_LC42IE            (mvien_regOut_LC42IE),
    .mvien_HPRASEIE          (mvien_regOut_HPRASEIE),
    .mvien_LC44IE            (mvien_regOut_LC44IE),
    .mvien_LC45IE            (mvien_regOut_LC45IE),
    .mvien_LC46IE            (mvien_regOut_LC46IE),
    .mvien_LC47IE            (mvien_regOut_LC47IE),
    .mvien_LC48IE            (mvien_regOut_LC48IE),
    .mvien_LC49IE            (mvien_regOut_LC49IE),
    .mvien_LC50IE            (mvien_regOut_LC50IE),
    .mvien_LC51IE            (mvien_regOut_LC51IE),
    .mvien_LC52IE            (mvien_regOut_LC52IE),
    .mvien_LC53IE            (mvien_regOut_LC53IE),
    .mvien_LC54IE            (mvien_regOut_LC54IE),
    .mvien_LC55IE            (mvien_regOut_LC55IE),
    .mvien_LC56IE            (mvien_regOut_LC56IE),
    .mvien_LC57IE            (mvien_regOut_LC57IE),
    .mvien_LC58IE            (mvien_regOut_LC58IE),
    .mvien_LC59IE            (mvien_regOut_LC59IE),
    .mvien_LC60IE            (mvien_regOut_LC60IE),
    .mvien_LC61IE            (mvien_regOut_LC61IE),
    .mvien_LC62IE            (mvien_regOut_LC62IE),
    .mvien_LC63IE            (mvien_regOut_LC63IE),
    .toMie_SSIE_valid        (sie_toMie_SSIE_valid),
    .toMie_SSIE_bits         (sie_toMie_SSIE_bits),
    .toMie_STIE_valid        (sie_toMie_STIE_valid),
    .toMie_STIE_bits         (sie_toMie_STIE_bits),
    .toMie_SEIE_valid        (sie_toMie_SEIE_valid),
    .toMie_SEIE_bits         (sie_toMie_SEIE_bits),
    .toMie_LCOFIE_valid      (sie_toMie_LCOFIE_valid),
    .toMie_LCOFIE_bits       (sie_toMie_LCOFIE_bits),
    .fromVSie_VSSIE_valid    (vsie_toSie_VSSIE_valid),
    .fromVSie_VSSIE_bits     (vsie_toSie_VSSIE_bits),
    .fromVSie_VSTIE_valid    (vsie_toSie_VSTIE_valid),
    .fromVSie_VSTIE_bits     (vsie_toSie_VSTIE_bits),
    .fromVSie_VSEIE_valid    (vsie_toSie_VSEIE_valid),
    .fromVSie_VSEIE_bits     (vsie_toSie_VSEIE_bits),
    .fromVSie_LCOFIE_valid   (vsie_toSie_LCOFIE_valid),
    .fromVSie_LCOFIE_bits    (vsie_toSie_LCOFIE_bits),
    .fromVSie_LC14IE_valid   (vsie_toSie_LC14IE_valid),
    .fromVSie_LC14IE_bits    (vsie_toSie_LC14IE_bits),
    .fromVSie_LC15IE_valid   (vsie_toSie_LC15IE_valid),
    .fromVSie_LC15IE_bits    (vsie_toSie_LC15IE_bits),
    .fromVSie_LC16IE_valid   (vsie_toSie_LC16IE_valid),
    .fromVSie_LC16IE_bits    (vsie_toSie_LC16IE_bits),
    .fromVSie_LC17IE_valid   (vsie_toSie_LC17IE_valid),
    .fromVSie_LC17IE_bits    (vsie_toSie_LC17IE_bits),
    .fromVSie_LC18IE_valid   (vsie_toSie_LC18IE_valid),
    .fromVSie_LC18IE_bits    (vsie_toSie_LC18IE_bits),
    .fromVSie_LC19IE_valid   (vsie_toSie_LC19IE_valid),
    .fromVSie_LC19IE_bits    (vsie_toSie_LC19IE_bits),
    .fromVSie_LC20IE_valid   (vsie_toSie_LC20IE_valid),
    .fromVSie_LC20IE_bits    (vsie_toSie_LC20IE_bits),
    .fromVSie_LC21IE_valid   (vsie_toSie_LC21IE_valid),
    .fromVSie_LC21IE_bits    (vsie_toSie_LC21IE_bits),
    .fromVSie_LC22IE_valid   (vsie_toSie_LC22IE_valid),
    .fromVSie_LC22IE_bits    (vsie_toSie_LC22IE_bits),
    .fromVSie_LC23IE_valid   (vsie_toSie_LC23IE_valid),
    .fromVSie_LC23IE_bits    (vsie_toSie_LC23IE_bits),
    .fromVSie_LC24IE_valid   (vsie_toSie_LC24IE_valid),
    .fromVSie_LC24IE_bits    (vsie_toSie_LC24IE_bits),
    .fromVSie_LC25IE_valid   (vsie_toSie_LC25IE_valid),
    .fromVSie_LC25IE_bits    (vsie_toSie_LC25IE_bits),
    .fromVSie_LC26IE_valid   (vsie_toSie_LC26IE_valid),
    .fromVSie_LC26IE_bits    (vsie_toSie_LC26IE_bits),
    .fromVSie_LC27IE_valid   (vsie_toSie_LC27IE_valid),
    .fromVSie_LC27IE_bits    (vsie_toSie_LC27IE_bits),
    .fromVSie_LC28IE_valid   (vsie_toSie_LC28IE_valid),
    .fromVSie_LC28IE_bits    (vsie_toSie_LC28IE_bits),
    .fromVSie_LC29IE_valid   (vsie_toSie_LC29IE_valid),
    .fromVSie_LC29IE_bits    (vsie_toSie_LC29IE_bits),
    .fromVSie_LC30IE_valid   (vsie_toSie_LC30IE_valid),
    .fromVSie_LC30IE_bits    (vsie_toSie_LC30IE_bits),
    .fromVSie_LC31IE_valid   (vsie_toSie_LC31IE_valid),
    .fromVSie_LC31IE_bits    (vsie_toSie_LC31IE_bits),
    .fromVSie_LC32IE_valid   (vsie_toSie_LC32IE_valid),
    .fromVSie_LC32IE_bits    (vsie_toSie_LC32IE_bits),
    .fromVSie_LC33IE_valid   (vsie_toSie_LC33IE_valid),
    .fromVSie_LC33IE_bits    (vsie_toSie_LC33IE_bits),
    .fromVSie_LC34IE_valid   (vsie_toSie_LC34IE_valid),
    .fromVSie_LC34IE_bits    (vsie_toSie_LC34IE_bits),
    .fromVSie_LPRASEIE_valid (vsie_toSie_LPRASEIE_valid),
    .fromVSie_LPRASEIE_bits  (vsie_toSie_LPRASEIE_bits),
    .fromVSie_LC36IE_valid   (vsie_toSie_LC36IE_valid),
    .fromVSie_LC36IE_bits    (vsie_toSie_LC36IE_bits),
    .fromVSie_LC37IE_valid   (vsie_toSie_LC37IE_valid),
    .fromVSie_LC37IE_bits    (vsie_toSie_LC37IE_bits),
    .fromVSie_LC38IE_valid   (vsie_toSie_LC38IE_valid),
    .fromVSie_LC38IE_bits    (vsie_toSie_LC38IE_bits),
    .fromVSie_LC39IE_valid   (vsie_toSie_LC39IE_valid),
    .fromVSie_LC39IE_bits    (vsie_toSie_LC39IE_bits),
    .fromVSie_LC40IE_valid   (vsie_toSie_LC40IE_valid),
    .fromVSie_LC40IE_bits    (vsie_toSie_LC40IE_bits),
    .fromVSie_LC41IE_valid   (vsie_toSie_LC41IE_valid),
    .fromVSie_LC41IE_bits    (vsie_toSie_LC41IE_bits),
    .fromVSie_LC42IE_valid   (vsie_toSie_LC42IE_valid),
    .fromVSie_LC42IE_bits    (vsie_toSie_LC42IE_bits),
    .fromVSie_HPRASEIE_valid (vsie_toSie_HPRASEIE_valid),
    .fromVSie_HPRASEIE_bits  (vsie_toSie_HPRASEIE_bits),
    .fromVSie_LC44IE_valid   (vsie_toSie_LC44IE_valid),
    .fromVSie_LC44IE_bits    (vsie_toSie_LC44IE_bits),
    .fromVSie_LC45IE_valid   (vsie_toSie_LC45IE_valid),
    .fromVSie_LC45IE_bits    (vsie_toSie_LC45IE_bits),
    .fromVSie_LC46IE_valid   (vsie_toSie_LC46IE_valid),
    .fromVSie_LC46IE_bits    (vsie_toSie_LC46IE_bits),
    .fromVSie_LC47IE_valid   (vsie_toSie_LC47IE_valid),
    .fromVSie_LC47IE_bits    (vsie_toSie_LC47IE_bits),
    .fromVSie_LC48IE_valid   (vsie_toSie_LC48IE_valid),
    .fromVSie_LC48IE_bits    (vsie_toSie_LC48IE_bits),
    .fromVSie_LC49IE_valid   (vsie_toSie_LC49IE_valid),
    .fromVSie_LC49IE_bits    (vsie_toSie_LC49IE_bits),
    .fromVSie_LC50IE_valid   (vsie_toSie_LC50IE_valid),
    .fromVSie_LC50IE_bits    (vsie_toSie_LC50IE_bits),
    .fromVSie_LC51IE_valid   (vsie_toSie_LC51IE_valid),
    .fromVSie_LC51IE_bits    (vsie_toSie_LC51IE_bits),
    .fromVSie_LC52IE_valid   (vsie_toSie_LC52IE_valid),
    .fromVSie_LC52IE_bits    (vsie_toSie_LC52IE_bits),
    .fromVSie_LC53IE_valid   (vsie_toSie_LC53IE_valid),
    .fromVSie_LC53IE_bits    (vsie_toSie_LC53IE_bits),
    .fromVSie_LC54IE_valid   (vsie_toSie_LC54IE_valid),
    .fromVSie_LC54IE_bits    (vsie_toSie_LC54IE_bits),
    .fromVSie_LC55IE_valid   (vsie_toSie_LC55IE_valid),
    .fromVSie_LC55IE_bits    (vsie_toSie_LC55IE_bits),
    .fromVSie_LC56IE_valid   (vsie_toSie_LC56IE_valid),
    .fromVSie_LC56IE_bits    (vsie_toSie_LC56IE_bits),
    .fromVSie_LC57IE_valid   (vsie_toSie_LC57IE_valid),
    .fromVSie_LC57IE_bits    (vsie_toSie_LC57IE_bits),
    .fromVSie_LC58IE_valid   (vsie_toSie_LC58IE_valid),
    .fromVSie_LC58IE_bits    (vsie_toSie_LC58IE_bits),
    .fromVSie_LC59IE_valid   (vsie_toSie_LC59IE_valid),
    .fromVSie_LC59IE_bits    (vsie_toSie_LC59IE_bits),
    .fromVSie_LC60IE_valid   (vsie_toSie_LC60IE_valid),
    .fromVSie_LC60IE_bits    (vsie_toSie_LC60IE_bits),
    .fromVSie_LC61IE_valid   (vsie_toSie_LC61IE_valid),
    .fromVSie_LC61IE_bits    (vsie_toSie_LC61IE_bits),
    .fromVSie_LC62IE_valid   (vsie_toSie_LC62IE_valid),
    .fromVSie_LC62IE_bits    (vsie_toSie_LC62IE_bits),
    .fromVSie_LC63IE_valid   (vsie_toSie_LC63IE_valid),
    .fromVSie_LC63IE_bits    (vsie_toSie_LC63IE_bits)
  );
  StvecModule stvec (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_stvec),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (stvec_rdata),
    .regOut_mode (stvec_regOut_mode),
    .regOut_addr (stvec_regOut_addr)
  );
  ScounterenModule scounteren (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_scounteren),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (scounteren_rdata),
    .regOut_CY  (scounteren_regOut_CY),
    .regOut_TM  (scounteren_regOut_TM),
    .regOut_IR  (scounteren_regOut_IR),
    .regOut_HPM (scounteren_regOut_HPM)
  );
  SenvcfgModule senvcfg (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_senvcfg),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (senvcfg_rdata),
    .regOut_PMM   (senvcfg_regOut_PMM),
    .regOut_CBZE  (senvcfg_regOut_CBZE),
    .regOut_CBCFE (senvcfg_regOut_CBCFE),
    .regOut_CBIE  (senvcfg_regOut_CBIE)
  );
  SscratchModule sscratch (
    .clock      (clock),
    .w_wen      (wen_sscratch),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (sscratch_rdata),
    .regOut_ALL (sscratch_regOut_ALL)
  );
  SepcModule sepc (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_sepc),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (sepc_rdata),
    .regOut_epc             (sepc_regOut_epc),
    .trapToHS_sepc_valid    (trapEntryHSEvent_out_sepc_valid),
    .trapToHS_sepc_bits_epc (trapEntryHSEvent_out_sepc_bits_epc)
  );
  ScauseModule scause (
    .clock                              (clock),
    .reset                              (reset),
    .w_wen                              (wen_scause),
    .w_wdata                            (io_in_bits_wdata),
    .rdata                              (scause_rdata),
    .regOut_Interrupt                   (scause_regOut_Interrupt),
    .regOut_ExceptionCode               (scause_regOut_ExceptionCode),
    .trapToHS_scause_valid              (trapEntryHSEvent_out_scause_valid),
    .trapToHS_scause_bits_Interrupt     (trapEntryHSEvent_out_scause_bits_Interrupt),
    .trapToHS_scause_bits_ExceptionCode (trapEntryHSEvent_out_scause_bits_ExceptionCode)
  );
  StvalModule stval (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_stval),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (stval_rdata),
    .regOut_ALL              (stval_regOut_ALL),
    .trapToHS_stval_valid    (trapEntryHSEvent_out_stval_valid),
    .trapToHS_stval_bits_ALL (trapEntryHSEvent_out_stval_bits_ALL)
  );
  SipModule sip (
    .w_wen                 (wen_sip),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (sip_rdata),
    .regOut_SSIP           (sip_regOut_SSIP),
    .regOut_STIP           (sip_regOut_STIP),
    .regOut_SEIP           (sip_regOut_SEIP),
    .regOut_LCOFIP         (sip_regOut_LCOFIP),
    .regOut_LC14IP         (sip_regOut_LC14IP),
    .regOut_LC15IP         (sip_regOut_LC15IP),
    .regOut_LC16IP         (sip_regOut_LC16IP),
    .regOut_LC17IP         (sip_regOut_LC17IP),
    .regOut_LC18IP         (sip_regOut_LC18IP),
    .regOut_LC19IP         (sip_regOut_LC19IP),
    .regOut_LC20IP         (sip_regOut_LC20IP),
    .regOut_LC21IP         (sip_regOut_LC21IP),
    .regOut_LC22IP         (sip_regOut_LC22IP),
    .regOut_LC23IP         (sip_regOut_LC23IP),
    .regOut_LC24IP         (sip_regOut_LC24IP),
    .regOut_LC25IP         (sip_regOut_LC25IP),
    .regOut_LC26IP         (sip_regOut_LC26IP),
    .regOut_LC27IP         (sip_regOut_LC27IP),
    .regOut_LC28IP         (sip_regOut_LC28IP),
    .regOut_LC29IP         (sip_regOut_LC29IP),
    .regOut_LC30IP         (sip_regOut_LC30IP),
    .regOut_LC31IP         (sip_regOut_LC31IP),
    .regOut_LC32IP         (sip_regOut_LC32IP),
    .regOut_LC33IP         (sip_regOut_LC33IP),
    .regOut_LC34IP         (sip_regOut_LC34IP),
    .regOut_LPRASEIP       (sip_regOut_LPRASEIP),
    .regOut_LC36IP         (sip_regOut_LC36IP),
    .regOut_LC37IP         (sip_regOut_LC37IP),
    .regOut_LC38IP         (sip_regOut_LC38IP),
    .regOut_LC39IP         (sip_regOut_LC39IP),
    .regOut_LC40IP         (sip_regOut_LC40IP),
    .regOut_LC41IP         (sip_regOut_LC41IP),
    .regOut_LC42IP         (sip_regOut_LC42IP),
    .regOut_HPRASEIP       (sip_regOut_HPRASEIP),
    .regOut_LC44IP         (sip_regOut_LC44IP),
    .regOut_LC45IP         (sip_regOut_LC45IP),
    .regOut_LC46IP         (sip_regOut_LC46IP),
    .regOut_LC47IP         (sip_regOut_LC47IP),
    .regOut_LC48IP         (sip_regOut_LC48IP),
    .regOut_LC49IP         (sip_regOut_LC49IP),
    .regOut_LC50IP         (sip_regOut_LC50IP),
    .regOut_LC51IP         (sip_regOut_LC51IP),
    .regOut_LC52IP         (sip_regOut_LC52IP),
    .regOut_LC53IP         (sip_regOut_LC53IP),
    .regOut_LC54IP         (sip_regOut_LC54IP),
    .regOut_LC55IP         (sip_regOut_LC55IP),
    .regOut_LC56IP         (sip_regOut_LC56IP),
    .regOut_LC57IP         (sip_regOut_LC57IP),
    .regOut_LC58IP         (sip_regOut_LC58IP),
    .regOut_LC59IP         (sip_regOut_LC59IP),
    .regOut_LC60IP         (sip_regOut_LC60IP),
    .regOut_LC61IP         (sip_regOut_LC61IP),
    .regOut_LC62IP         (sip_regOut_LC62IP),
    .regOut_LC63IP         (sip_regOut_LC63IP),
    .mideleg_SSI           (mideleg_regOut_SSI),
    .mideleg_STI           (mideleg_regOut_STI),
    .mideleg_SEI           (mideleg_regOut_SEI),
    .mideleg_LCOFI         (mideleg_regOut_LCOFI),
    .mip_SSIP              (mip_rdata[1]),
    .mip_VSSIP             (mip_rdata[2]),
    .mip_MSIP              (mip_rdata[3]),
    .mip_STIP              (mip_rdata[5]),
    .mip_VSTIP             (mip_rdata[6]),
    .mip_MTIP              (mip_rdata[7]),
    .mip_SEIP              (mip_rdata[9]),
    .mip_VSEIP             (mip_rdata[10]),
    .mip_MEIP              (mip_rdata[11]),
    .mip_SGEIP             (mip_rdata[12]),
    .mip_LCOFIP            (mip_rdata[13]),
    .mip_LC14IP            (mip_rdata[14]),
    .mip_LC15IP            (mip_rdata[15]),
    .mip_LC16IP            (mip_rdata[16]),
    .mip_LC17IP            (mip_rdata[17]),
    .mip_LC18IP            (mip_rdata[18]),
    .mip_LC19IP            (mip_rdata[19]),
    .mip_LC20IP            (mip_rdata[20]),
    .mip_LC21IP            (mip_rdata[21]),
    .mip_LC22IP            (mip_rdata[22]),
    .mip_LC23IP            (mip_rdata[23]),
    .mip_LC24IP            (mip_rdata[24]),
    .mip_LC25IP            (mip_rdata[25]),
    .mip_LC26IP            (mip_rdata[26]),
    .mip_LC27IP            (mip_rdata[27]),
    .mip_LC28IP            (mip_rdata[28]),
    .mip_LC29IP            (mip_rdata[29]),
    .mip_LC30IP            (mip_rdata[30]),
    .mip_LC31IP            (mip_rdata[31]),
    .mip_LC32IP            (mip_rdata[32]),
    .mip_LC33IP            (mip_rdata[33]),
    .mip_LC34IP            (mip_rdata[34]),
    .mip_LPRASEIP          (mip_rdata[35]),
    .mip_LC36IP            (mip_rdata[36]),
    .mip_LC37IP            (mip_rdata[37]),
    .mip_LC38IP            (mip_rdata[38]),
    .mip_LC39IP            (mip_rdata[39]),
    .mip_LC40IP            (mip_rdata[40]),
    .mip_LC41IP            (mip_rdata[41]),
    .mip_LC42IP            (mip_rdata[42]),
    .mip_HPRASEIP          (mip_rdata[43]),
    .mip_LC44IP            (mip_rdata[44]),
    .mip_LC45IP            (mip_rdata[45]),
    .mip_LC46IP            (mip_rdata[46]),
    .mip_LC47IP            (mip_rdata[47]),
    .mip_LC48IP            (mip_rdata[48]),
    .mip_LC49IP            (mip_rdata[49]),
    .mip_LC50IP            (mip_rdata[50]),
    .mip_LC51IP            (mip_rdata[51]),
    .mip_LC52IP            (mip_rdata[52]),
    .mip_LC53IP            (mip_rdata[53]),
    .mip_LC54IP            (mip_rdata[54]),
    .mip_LC55IP            (mip_rdata[55]),
    .mip_LC56IP            (mip_rdata[56]),
    .mip_LC57IP            (mip_rdata[57]),
    .mip_LC58IP            (mip_rdata[58]),
    .mip_LC59IP            (mip_rdata[59]),
    .mip_LC60IP            (mip_rdata[60]),
    .mip_LC61IP            (mip_rdata[61]),
    .mip_LC62IP            (mip_rdata[62]),
    .mip_LC63IP            (mip_rdata[63]),
    .mvip_SSIP             (mvip_regOut_SSIP),
    .mvip_STIP             (mvip_regOut_STIP),
    .mvip_SEIP             (mvip_regOut_SEIP),
    .mvip_LCOFIP           (mvip_regOut_LCOFIP),
    .mvip_LC14IP           (mvip_regOut_LC14IP),
    .mvip_LC15IP           (mvip_regOut_LC15IP),
    .mvip_LC16IP           (mvip_regOut_LC16IP),
    .mvip_LC17IP           (mvip_regOut_LC17IP),
    .mvip_LC18IP           (mvip_regOut_LC18IP),
    .mvip_LC19IP           (mvip_regOut_LC19IP),
    .mvip_LC20IP           (mvip_regOut_LC20IP),
    .mvip_LC21IP           (mvip_regOut_LC21IP),
    .mvip_LC22IP           (mvip_regOut_LC22IP),
    .mvip_LC23IP           (mvip_regOut_LC23IP),
    .mvip_LC24IP           (mvip_regOut_LC24IP),
    .mvip_LC25IP           (mvip_regOut_LC25IP),
    .mvip_LC26IP           (mvip_regOut_LC26IP),
    .mvip_LC27IP           (mvip_regOut_LC27IP),
    .mvip_LC28IP           (mvip_regOut_LC28IP),
    .mvip_LC29IP           (mvip_regOut_LC29IP),
    .mvip_LC30IP           (mvip_regOut_LC30IP),
    .mvip_LC31IP           (mvip_regOut_LC31IP),
    .mvip_LC32IP           (mvip_regOut_LC32IP),
    .mvip_LC33IP           (mvip_regOut_LC33IP),
    .mvip_LC34IP           (mvip_regOut_LC34IP),
    .mvip_LPRASEIP         (mvip_regOut_LPRASEIP),
    .mvip_LC36IP           (mvip_regOut_LC36IP),
    .mvip_LC37IP           (mvip_regOut_LC37IP),
    .mvip_LC38IP           (mvip_regOut_LC38IP),
    .mvip_LC39IP           (mvip_regOut_LC39IP),
    .mvip_LC40IP           (mvip_regOut_LC40IP),
    .mvip_LC41IP           (mvip_regOut_LC41IP),
    .mvip_LC42IP           (mvip_regOut_LC42IP),
    .mvip_HPRASEIP         (mvip_regOut_HPRASEIP),
    .mvip_LC44IP           (mvip_regOut_LC44IP),
    .mvip_LC45IP           (mvip_regOut_LC45IP),
    .mvip_LC46IP           (mvip_regOut_LC46IP),
    .mvip_LC47IP           (mvip_regOut_LC47IP),
    .mvip_LC48IP           (mvip_regOut_LC48IP),
    .mvip_LC49IP           (mvip_regOut_LC49IP),
    .mvip_LC50IP           (mvip_regOut_LC50IP),
    .mvip_LC51IP           (mvip_regOut_LC51IP),
    .mvip_LC52IP           (mvip_regOut_LC52IP),
    .mvip_LC53IP           (mvip_regOut_LC53IP),
    .mvip_LC54IP           (mvip_regOut_LC54IP),
    .mvip_LC55IP           (mvip_regOut_LC55IP),
    .mvip_LC56IP           (mvip_regOut_LC56IP),
    .mvip_LC57IP           (mvip_regOut_LC57IP),
    .mvip_LC58IP           (mvip_regOut_LC58IP),
    .mvip_LC59IP           (mvip_regOut_LC59IP),
    .mvip_LC60IP           (mvip_regOut_LC60IP),
    .mvip_LC61IP           (mvip_regOut_LC61IP),
    .mvip_LC62IP           (mvip_regOut_LC62IP),
    .mvip_LC63IP           (mvip_regOut_LC63IP),
    .mvien_SSIE            (mvien_regOut_SSIE),
    .mvien_SEIE            (mvien_regOut_SEIE),
    .mvien_LC14IE          (mvien_regOut_LC14IE),
    .mvien_LC15IE          (mvien_regOut_LC15IE),
    .mvien_LC16IE          (mvien_regOut_LC16IE),
    .mvien_LC17IE          (mvien_regOut_LC17IE),
    .mvien_LC18IE          (mvien_regOut_LC18IE),
    .mvien_LC19IE          (mvien_regOut_LC19IE),
    .mvien_LC20IE          (mvien_regOut_LC20IE),
    .mvien_LC21IE          (mvien_regOut_LC21IE),
    .mvien_LC22IE          (mvien_regOut_LC22IE),
    .mvien_LC23IE          (mvien_regOut_LC23IE),
    .mvien_LC24IE          (mvien_regOut_LC24IE),
    .mvien_LC25IE          (mvien_regOut_LC25IE),
    .mvien_LC26IE          (mvien_regOut_LC26IE),
    .mvien_LC27IE          (mvien_regOut_LC27IE),
    .mvien_LC28IE          (mvien_regOut_LC28IE),
    .mvien_LC29IE          (mvien_regOut_LC29IE),
    .mvien_LC30IE          (mvien_regOut_LC30IE),
    .mvien_LC31IE          (mvien_regOut_LC31IE),
    .mvien_LC32IE          (mvien_regOut_LC32IE),
    .mvien_LC33IE          (mvien_regOut_LC33IE),
    .mvien_LC34IE          (mvien_regOut_LC34IE),
    .mvien_LPRASEIE        (mvien_regOut_LPRASEIE),
    .mvien_LC36IE          (mvien_regOut_LC36IE),
    .mvien_LC37IE          (mvien_regOut_LC37IE),
    .mvien_LC38IE          (mvien_regOut_LC38IE),
    .mvien_LC39IE          (mvien_regOut_LC39IE),
    .mvien_LC40IE          (mvien_regOut_LC40IE),
    .mvien_LC41IE          (mvien_regOut_LC41IE),
    .mvien_LC42IE          (mvien_regOut_LC42IE),
    .mvien_HPRASEIE        (mvien_regOut_HPRASEIE),
    .mvien_LC44IE          (mvien_regOut_LC44IE),
    .mvien_LC45IE          (mvien_regOut_LC45IE),
    .mvien_LC46IE          (mvien_regOut_LC46IE),
    .mvien_LC47IE          (mvien_regOut_LC47IE),
    .mvien_LC48IE          (mvien_regOut_LC48IE),
    .mvien_LC49IE          (mvien_regOut_LC49IE),
    .mvien_LC50IE          (mvien_regOut_LC50IE),
    .mvien_LC51IE          (mvien_regOut_LC51IE),
    .mvien_LC52IE          (mvien_regOut_LC52IE),
    .mvien_LC53IE          (mvien_regOut_LC53IE),
    .mvien_LC54IE          (mvien_regOut_LC54IE),
    .mvien_LC55IE          (mvien_regOut_LC55IE),
    .mvien_LC56IE          (mvien_regOut_LC56IE),
    .mvien_LC57IE          (mvien_regOut_LC57IE),
    .mvien_LC58IE          (mvien_regOut_LC58IE),
    .mvien_LC59IE          (mvien_regOut_LC59IE),
    .mvien_LC60IE          (mvien_regOut_LC60IE),
    .mvien_LC61IE          (mvien_regOut_LC61IE),
    .mvien_LC62IE          (mvien_regOut_LC62IE),
    .mvien_LC63IE          (mvien_regOut_LC63IE),
    .toMip_SSIP_valid      (sip_toMip_SSIP_valid),
    .toMip_SSIP_bits       (sip_toMip_SSIP_bits),
    .toMip_LCOFIP_valid    (sip_toMip_LCOFIP_valid),
    .toMip_LCOFIP_bits     (sip_toMip_LCOFIP_bits),
    .toMvip_SSIP_valid     (sip_toMvip_SSIP_valid),
    .toMvip_SSIP_bits      (sip_toMvip_SSIP_bits),
    .toMvip_LCOFIP_valid   (sip_toMvip_LCOFIP_valid),
    .toMvip_LCOFIP_bits    (sip_toMvip_LCOFIP_bits),
    .toMvip_LC14IP_valid   (sip_toMvip_LC14IP_valid),
    .toMvip_LC14IP_bits    (sip_toMvip_LC14IP_bits),
    .toMvip_LC15IP_valid   (sip_toMvip_LC15IP_valid),
    .toMvip_LC15IP_bits    (sip_toMvip_LC15IP_bits),
    .toMvip_LC16IP_valid   (sip_toMvip_LC16IP_valid),
    .toMvip_LC16IP_bits    (sip_toMvip_LC16IP_bits),
    .toMvip_LC17IP_valid   (sip_toMvip_LC17IP_valid),
    .toMvip_LC17IP_bits    (sip_toMvip_LC17IP_bits),
    .toMvip_LC18IP_valid   (sip_toMvip_LC18IP_valid),
    .toMvip_LC18IP_bits    (sip_toMvip_LC18IP_bits),
    .toMvip_LC19IP_valid   (sip_toMvip_LC19IP_valid),
    .toMvip_LC19IP_bits    (sip_toMvip_LC19IP_bits),
    .toMvip_LC20IP_valid   (sip_toMvip_LC20IP_valid),
    .toMvip_LC20IP_bits    (sip_toMvip_LC20IP_bits),
    .toMvip_LC21IP_valid   (sip_toMvip_LC21IP_valid),
    .toMvip_LC21IP_bits    (sip_toMvip_LC21IP_bits),
    .toMvip_LC22IP_valid   (sip_toMvip_LC22IP_valid),
    .toMvip_LC22IP_bits    (sip_toMvip_LC22IP_bits),
    .toMvip_LC23IP_valid   (sip_toMvip_LC23IP_valid),
    .toMvip_LC23IP_bits    (sip_toMvip_LC23IP_bits),
    .toMvip_LC24IP_valid   (sip_toMvip_LC24IP_valid),
    .toMvip_LC24IP_bits    (sip_toMvip_LC24IP_bits),
    .toMvip_LC25IP_valid   (sip_toMvip_LC25IP_valid),
    .toMvip_LC25IP_bits    (sip_toMvip_LC25IP_bits),
    .toMvip_LC26IP_valid   (sip_toMvip_LC26IP_valid),
    .toMvip_LC26IP_bits    (sip_toMvip_LC26IP_bits),
    .toMvip_LC27IP_valid   (sip_toMvip_LC27IP_valid),
    .toMvip_LC27IP_bits    (sip_toMvip_LC27IP_bits),
    .toMvip_LC28IP_valid   (sip_toMvip_LC28IP_valid),
    .toMvip_LC28IP_bits    (sip_toMvip_LC28IP_bits),
    .toMvip_LC29IP_valid   (sip_toMvip_LC29IP_valid),
    .toMvip_LC29IP_bits    (sip_toMvip_LC29IP_bits),
    .toMvip_LC30IP_valid   (sip_toMvip_LC30IP_valid),
    .toMvip_LC30IP_bits    (sip_toMvip_LC30IP_bits),
    .toMvip_LC31IP_valid   (sip_toMvip_LC31IP_valid),
    .toMvip_LC31IP_bits    (sip_toMvip_LC31IP_bits),
    .toMvip_LC32IP_valid   (sip_toMvip_LC32IP_valid),
    .toMvip_LC32IP_bits    (sip_toMvip_LC32IP_bits),
    .toMvip_LC33IP_valid   (sip_toMvip_LC33IP_valid),
    .toMvip_LC33IP_bits    (sip_toMvip_LC33IP_bits),
    .toMvip_LC34IP_valid   (sip_toMvip_LC34IP_valid),
    .toMvip_LC34IP_bits    (sip_toMvip_LC34IP_bits),
    .toMvip_LPRASEIP_valid (sip_toMvip_LPRASEIP_valid),
    .toMvip_LPRASEIP_bits  (sip_toMvip_LPRASEIP_bits),
    .toMvip_LC36IP_valid   (sip_toMvip_LC36IP_valid),
    .toMvip_LC36IP_bits    (sip_toMvip_LC36IP_bits),
    .toMvip_LC37IP_valid   (sip_toMvip_LC37IP_valid),
    .toMvip_LC37IP_bits    (sip_toMvip_LC37IP_bits),
    .toMvip_LC38IP_valid   (sip_toMvip_LC38IP_valid),
    .toMvip_LC38IP_bits    (sip_toMvip_LC38IP_bits),
    .toMvip_LC39IP_valid   (sip_toMvip_LC39IP_valid),
    .toMvip_LC39IP_bits    (sip_toMvip_LC39IP_bits),
    .toMvip_LC40IP_valid   (sip_toMvip_LC40IP_valid),
    .toMvip_LC40IP_bits    (sip_toMvip_LC40IP_bits),
    .toMvip_LC41IP_valid   (sip_toMvip_LC41IP_valid),
    .toMvip_LC41IP_bits    (sip_toMvip_LC41IP_bits),
    .toMvip_LC42IP_valid   (sip_toMvip_LC42IP_valid),
    .toMvip_LC42IP_bits    (sip_toMvip_LC42IP_bits),
    .toMvip_HPRASEIP_valid (sip_toMvip_HPRASEIP_valid),
    .toMvip_HPRASEIP_bits  (sip_toMvip_HPRASEIP_bits),
    .toMvip_LC44IP_valid   (sip_toMvip_LC44IP_valid),
    .toMvip_LC44IP_bits    (sip_toMvip_LC44IP_bits),
    .toMvip_LC45IP_valid   (sip_toMvip_LC45IP_valid),
    .toMvip_LC45IP_bits    (sip_toMvip_LC45IP_bits),
    .toMvip_LC46IP_valid   (sip_toMvip_LC46IP_valid),
    .toMvip_LC46IP_bits    (sip_toMvip_LC46IP_bits),
    .toMvip_LC47IP_valid   (sip_toMvip_LC47IP_valid),
    .toMvip_LC47IP_bits    (sip_toMvip_LC47IP_bits),
    .toMvip_LC48IP_valid   (sip_toMvip_LC48IP_valid),
    .toMvip_LC48IP_bits    (sip_toMvip_LC48IP_bits),
    .toMvip_LC49IP_valid   (sip_toMvip_LC49IP_valid),
    .toMvip_LC49IP_bits    (sip_toMvip_LC49IP_bits),
    .toMvip_LC50IP_valid   (sip_toMvip_LC50IP_valid),
    .toMvip_LC50IP_bits    (sip_toMvip_LC50IP_bits),
    .toMvip_LC51IP_valid   (sip_toMvip_LC51IP_valid),
    .toMvip_LC51IP_bits    (sip_toMvip_LC51IP_bits),
    .toMvip_LC52IP_valid   (sip_toMvip_LC52IP_valid),
    .toMvip_LC52IP_bits    (sip_toMvip_LC52IP_bits),
    .toMvip_LC53IP_valid   (sip_toMvip_LC53IP_valid),
    .toMvip_LC53IP_bits    (sip_toMvip_LC53IP_bits),
    .toMvip_LC54IP_valid   (sip_toMvip_LC54IP_valid),
    .toMvip_LC54IP_bits    (sip_toMvip_LC54IP_bits),
    .toMvip_LC55IP_valid   (sip_toMvip_LC55IP_valid),
    .toMvip_LC55IP_bits    (sip_toMvip_LC55IP_bits),
    .toMvip_LC56IP_valid   (sip_toMvip_LC56IP_valid),
    .toMvip_LC56IP_bits    (sip_toMvip_LC56IP_bits),
    .toMvip_LC57IP_valid   (sip_toMvip_LC57IP_valid),
    .toMvip_LC57IP_bits    (sip_toMvip_LC57IP_bits),
    .toMvip_LC58IP_valid   (sip_toMvip_LC58IP_valid),
    .toMvip_LC58IP_bits    (sip_toMvip_LC58IP_bits),
    .toMvip_LC59IP_valid   (sip_toMvip_LC59IP_valid),
    .toMvip_LC59IP_bits    (sip_toMvip_LC59IP_bits),
    .toMvip_LC60IP_valid   (sip_toMvip_LC60IP_valid),
    .toMvip_LC60IP_bits    (sip_toMvip_LC60IP_bits),
    .toMvip_LC61IP_valid   (sip_toMvip_LC61IP_valid),
    .toMvip_LC61IP_bits    (sip_toMvip_LC61IP_bits),
    .toMvip_LC62IP_valid   (sip_toMvip_LC62IP_valid),
    .toMvip_LC62IP_bits    (sip_toMvip_LC62IP_bits),
    .toMvip_LC63IP_valid   (sip_toMvip_LC63IP_valid),
    .toMvip_LC63IP_bits    (sip_toMvip_LC63IP_bits)
  );
  StimecmpModule stimecmp (
    .clock           (clock),
    .reset           (reset),
    .w_wen           (wen_stimecmp),
    .w_wdata         (io_in_bits_wdata),
    .rdata           (stimecmp_rdata),
    .regOut_stimecmp (stimecmp_regOut_stimecmp)
  );
  SatpModule satp (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_satp),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (satp_rdata),
    .regOut_MODE (satp_regOut_MODE),
    .regOut_ASID (satp_regOut_ASID),
    .regOut_PPN  (satp_regOut_PPN)
  );
  ScountovfModule scountovf (
    .rdata          (scountovf_rdata),
    .ofVec          ({Mhpmevent31_rdata[63], Mhpmevent30_rdata[63], Mhpmevent29_rdata[63], Mhpmevent28_rdata[63], Mhpmevent27_rdata[63], Mhpmevent26_rdata[63], Mhpmevent25_rdata[63], Mhpmevent24_rdata[63], Mhpmevent23_rdata[63], Mhpmevent22_rdata[63], Mhpmevent21_rdata[63], Mhpmevent20_rdata[63], Mhpmevent19_rdata[63], Mhpmevent18_rdata[63], Mhpmevent17_rdata[63], Mhpmevent16_rdata[63], Mhpmevent15_rdata[63], Mhpmevent14_rdata[63], Mhpmevent13_rdata[63], Mhpmevent12_rdata[63], Mhpmevent11_rdata[63], Mhpmevent10_rdata[63], Mhpmevent9_rdata[63], Mhpmevent8_rdata[63], Mhpmevent7_rdata[63], Mhpmevent6_rdata[63], Mhpmevent5_rdata[63], Mhpmevent4_rdata[63], Mhpmevent3_rdata[63]}),
    .privState_PRVM (prvm),
    .privState_V    (virt),
    .mcounteren_HPM (mcounteren_rdata[31:3]),
    .hcounteren_HPM (hcounteren_rdata[31:3])
  );
  Sstateen0Module sstateen0 (
    .clock                 (clock),
    .reset                 (reset),
    .w_wen                 (wen_sstateen0),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (sstateen0_rdata),
    .regOut_JVT            (sstateen0_regOut_JVT),
    .regOut_FCSR           (sstateen0_regOut_FCSR),
    .regOut_C              (sstateen0_regOut_C),
    .fromMstateen0_SE0     (mstateen0_regOut_SE0),
    .fromMstateen0_ENVCFG  (mstateen0_regOut_ENVCFG),
    .fromMstateen0_CSRIND  (mstateen0_regOut_CSRIND),
    .fromMstateen0_AIA     (mstateen0_regOut_AIA),
    .fromMstateen0_IMSIC   (mstateen0_regOut_IMSIC),
    .fromMstateen0_CONTEXT (mstateen0_regOut_CONTEXT),
    .fromMstateen0_C       (mstateen0_regOut_C),
    .fromHstateen0_JVT     (hstateen0_regOut_JVT),
    .fromHstateen0_FCSR    (hstateen0_regOut_FCSR),
    .fromHstateen0_C       (hstateen0_regOut_C),
    .fromHstateen0_SE0     (hstateen0_regOut_SE0),
    .fromHstateen0_ENVCFG  (hstateen0_regOut_ENVCFG),
    .fromHstateen0_CSRIND  (hstateen0_regOut_CSRIND),
    .fromHstateen0_AIA     (hstateen0_regOut_AIA),
    .fromHstateen0_IMSIC   (hstateen0_regOut_IMSIC),
    .fromHstateen0_CONTEXT (hstateen0_regOut_CONTEXT),
    .privState_V           (virt)
  );
  Sstateen1Module sstateen1 (
    .rdata      (sstateen1_rdata),
    .regOut_ALL (sstateen1_regOut_ALL)
  );
  Sstateen2Module sstateen2 (
    .rdata      (sstateen2_rdata),
    .regOut_ALL (sstateen2_regOut_ALL)
  );
  Sstateen3Module sstateen3 (
    .rdata      (sstateen3_rdata),
    .regOut_ALL (sstateen3_regOut_ALL)
  );
  ScontextModule scontext (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_scontext),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (scontext_rdata),
    .regOut_ALL (scontext_regOut_ALL)
  );
  HstatusModule hstatus (
    .clock                      (clock),
    .reset                      (reset),
    .w_wen                      (wen_hstatus),
    .w_wdata                    (io_in_bits_wdata),
    .rdata                      (hstatus_rdata),
    .regOut_GVA                 (hstatus_regOut_GVA),
    .regOut_SPV                 (hstatus_regOut_SPV),
    .regOut_SPVP                (hstatus_regOut_SPVP),
    .regOut_HU                  (hstatus_regOut_HU),
    .regOut_VGEIN               (hstatus_regOut_VGEIN),
    .regOut_VTVM                (hstatus_regOut_VTVM),
    .regOut_VTW                 (hstatus_regOut_VTW),
    .regOut_VTSR                (hstatus_regOut_VTSR),
    .regOut_HUPMM               (hstatus_regOut_HUPMM),
    .retFromS_hstatus_valid     (sretEvent_out_hstatus_valid),
    .retFromS_hstatus_bits_SPV  (sretEvent_out_hstatus_bits_SPV),
    .trapToHS_hstatus_valid     (trapEntryHSEvent_out_hstatus_valid),
    .trapToHS_hstatus_bits_GVA  (trapEntryHSEvent_out_hstatus_bits_GVA),
    .trapToHS_hstatus_bits_SPV  (trapEntryHSEvent_out_hstatus_bits_SPV),
    .trapToHS_hstatus_bits_SPVP (trapEntryHSEvent_out_hstatus_bits_SPVP)
  );
  HedelegModule hedeleg (
    .clock           (clock),
    .reset           (reset),
    .w_wen           (wen_hedeleg),
    .w_wdata         (io_in_bits_wdata),
    .rdata           (hedeleg_rdata),
    .regOut_EX_IAM   (hedeleg_regOut_EX_IAM),
    .regOut_EX_IAF   (hedeleg_regOut_EX_IAF),
    .regOut_EX_II    (hedeleg_regOut_EX_II),
    .regOut_EX_BP    (hedeleg_regOut_EX_BP),
    .regOut_EX_LAM   (hedeleg_regOut_EX_LAM),
    .regOut_EX_LAF   (hedeleg_regOut_EX_LAF),
    .regOut_EX_SAM   (hedeleg_regOut_EX_SAM),
    .regOut_EX_SAF   (hedeleg_regOut_EX_SAF),
    .regOut_EX_UCALL (hedeleg_regOut_EX_UCALL),
    .regOut_EX_IPF   (hedeleg_regOut_EX_IPF),
    .regOut_EX_LPF   (hedeleg_regOut_EX_LPF),
    .regOut_EX_SPF   (hedeleg_regOut_EX_SPF),
    .regOut_EX_SWC   (hedeleg_regOut_EX_SWC),
    .regOut_EX_HWE   (hedeleg_regOut_EX_HWE)
  );
  HidelegModule hideleg (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_hideleg),
    .w_wdata       (io_in_bits_wdata),
    .rdata         (hideleg_rdata),
    .regOut_SSI    (hideleg_regOut_SSI),
    .regOut_VSSI   (hideleg_regOut_VSSI),
    .regOut_MSI    (hideleg_regOut_MSI),
    .regOut_STI    (hideleg_regOut_STI),
    .regOut_VSTI   (hideleg_regOut_VSTI),
    .regOut_MTI    (hideleg_regOut_MTI),
    .regOut_SEI    (hideleg_regOut_SEI),
    .regOut_VSEI   (hideleg_regOut_VSEI),
    .regOut_MEI    (hideleg_regOut_MEI),
    .regOut_SGEI   (hideleg_regOut_SGEI),
    .regOut_LCOFI  (hideleg_regOut_LCOFI),
    .mideleg_SSI   (mideleg_regOut_SSI),
    .mideleg_STI   (mideleg_regOut_STI),
    .mideleg_SEI   (mideleg_regOut_SEI),
    .mideleg_LCOFI (mideleg_regOut_LCOFI)
  );
  HieModule hie (
    .w_wen             (wen_hie),
    .w_wdata           (io_in_bits_wdata),
    .rdata             (hie_rdata),
    .regOut_VSSIE      (hie_regOut_VSSIE),
    .regOut_VSTIE      (hie_regOut_VSTIE),
    .regOut_VSEIE      (hie_regOut_VSEIE),
    .regOut_SGEIE      (hie_regOut_SGEIE),
    .mie_VSSIE         (mie_regOut_VSSIE),
    .mie_VSTIE         (mie_regOut_VSTIE),
    .mie_VSEIE         (mie_regOut_VSEIE),
    .mie_SGEIE         (mie_regOut_SGEIE),
    .toMie_VSSIE_valid (hie_toMie_VSSIE_valid),
    .toMie_VSSIE_bits  (hie_toMie_VSSIE_bits),
    .toMie_VSTIE_valid (hie_toMie_VSTIE_valid),
    .toMie_VSTIE_bits  (hie_toMie_VSTIE_bits),
    .toMie_VSEIE_valid (hie_toMie_VSEIE_valid),
    .toMie_VSEIE_bits  (hie_toMie_VSEIE_bits),
    .toMie_SGEIE_valid (hie_toMie_SGEIE_valid),
    .toMie_SGEIE_bits  (hie_toMie_SGEIE_bits)
  );
  HtimedeltaModule htimedelta (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_htimedelta),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (htimedelta_rdata),
    .regOut_ALL (htimedelta_regOut_ALL)
  );
  HcounterenModule hcounteren (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_hcounteren),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (hcounteren_rdata),
    .regOut_CY  (hcounteren_regOut_CY),
    .regOut_TM  (hcounteren_regOut_TM),
    .regOut_IR  (hcounteren_regOut_IR),
    .regOut_HPM (hcounteren_regOut_HPM)
  );
  HgeieModule hgeie (
    .clock     (clock),
    .reset     (reset),
    .w_wen     (wen_hgeie),
    .w_wdata   (io_in_bits_wdata),
    .rdata     (hgeie_rdata),
    .regOut_ie (hgeie_regOut_ie)
  );
  HvienModule hvien (
    .clock           (clock),
    .reset           (reset),
    .w_wen           (wen_hvien),
    .w_wdata         (io_in_bits_wdata),
    .rdata           (hvien_rdata),
    .regOut_LC14IE   (hvien_regOut_LC14IE),
    .regOut_LC15IE   (hvien_regOut_LC15IE),
    .regOut_LC16IE   (hvien_regOut_LC16IE),
    .regOut_LC17IE   (hvien_regOut_LC17IE),
    .regOut_LC18IE   (hvien_regOut_LC18IE),
    .regOut_LC19IE   (hvien_regOut_LC19IE),
    .regOut_LC20IE   (hvien_regOut_LC20IE),
    .regOut_LC21IE   (hvien_regOut_LC21IE),
    .regOut_LC22IE   (hvien_regOut_LC22IE),
    .regOut_LC23IE   (hvien_regOut_LC23IE),
    .regOut_LC24IE   (hvien_regOut_LC24IE),
    .regOut_LC25IE   (hvien_regOut_LC25IE),
    .regOut_LC26IE   (hvien_regOut_LC26IE),
    .regOut_LC27IE   (hvien_regOut_LC27IE),
    .regOut_LC28IE   (hvien_regOut_LC28IE),
    .regOut_LC29IE   (hvien_regOut_LC29IE),
    .regOut_LC30IE   (hvien_regOut_LC30IE),
    .regOut_LC31IE   (hvien_regOut_LC31IE),
    .regOut_LC32IE   (hvien_regOut_LC32IE),
    .regOut_LC33IE   (hvien_regOut_LC33IE),
    .regOut_LC34IE   (hvien_regOut_LC34IE),
    .regOut_LPRASEIE (hvien_regOut_LPRASEIE),
    .regOut_LC36IE   (hvien_regOut_LC36IE),
    .regOut_LC37IE   (hvien_regOut_LC37IE),
    .regOut_LC38IE   (hvien_regOut_LC38IE),
    .regOut_LC39IE   (hvien_regOut_LC39IE),
    .regOut_LC40IE   (hvien_regOut_LC40IE),
    .regOut_LC41IE   (hvien_regOut_LC41IE),
    .regOut_LC42IE   (hvien_regOut_LC42IE),
    .regOut_HPRASEIE (hvien_regOut_HPRASEIE),
    .regOut_LC44IE   (hvien_regOut_LC44IE),
    .regOut_LC45IE   (hvien_regOut_LC45IE),
    .regOut_LC46IE   (hvien_regOut_LC46IE),
    .regOut_LC47IE   (hvien_regOut_LC47IE),
    .regOut_LC48IE   (hvien_regOut_LC48IE),
    .regOut_LC49IE   (hvien_regOut_LC49IE),
    .regOut_LC50IE   (hvien_regOut_LC50IE),
    .regOut_LC51IE   (hvien_regOut_LC51IE),
    .regOut_LC52IE   (hvien_regOut_LC52IE),
    .regOut_LC53IE   (hvien_regOut_LC53IE),
    .regOut_LC54IE   (hvien_regOut_LC54IE),
    .regOut_LC55IE   (hvien_regOut_LC55IE),
    .regOut_LC56IE   (hvien_regOut_LC56IE),
    .regOut_LC57IE   (hvien_regOut_LC57IE),
    .regOut_LC58IE   (hvien_regOut_LC58IE),
    .regOut_LC59IE   (hvien_regOut_LC59IE),
    .regOut_LC60IE   (hvien_regOut_LC60IE),
    .regOut_LC61IE   (hvien_regOut_LC61IE),
    .regOut_LC62IE   (hvien_regOut_LC62IE),
    .regOut_LC63IE   (hvien_regOut_LC63IE)
  );
  HvictlModule hvictl (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_hvictl),
    .w_wdata       (io_in_bits_wdata),
    .rdata         (hvictl_rdata),
    .regOut_VTI    (hvictl_regOut_VTI),
    .regOut_IID    (hvictl_regOut_IID),
    .regOut_DPR    (hvictl_regOut_DPR),
    .regOut_IPRIOM (hvictl_regOut_IPRIOM),
    .regOut_IPRIO  (hvictl_regOut_IPRIO)
  );
  HenvcfgModule henvcfg (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_henvcfg),
    .w_wdata       (io_in_bits_wdata),
    .rdata         (henvcfg_rdata),
    .regOut_STCE   (henvcfg_regOut_STCE),
    .regOut_PBMTE  (henvcfg_regOut_PBMTE),
    .regOut_DTE    (henvcfg_regOut_DTE),
    .regOut_PMM    (henvcfg_regOut_PMM),
    .regOut_CBZE   (henvcfg_regOut_CBZE),
    .regOut_CBCFE  (henvcfg_regOut_CBCFE),
    .regOut_CBIE   (henvcfg_regOut_CBIE),
    .menvcfg_STCE  (menvcfg_regOut_STCE),
    .menvcfg_PBMTE (menvcfg_regOut_PBMTE),
    .menvcfg_DTE   (menvcfg_regOut_DTE)
  );
  HtvalModule htval (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_htval),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (htval_rdata),
    .regOut_ALL              (htval_regOut_ALL),
    .trapToHS_htval_valid    (trapEntryHSEvent_out_htval_valid),
    .trapToHS_htval_bits_ALL (trapEntryHSEvent_out_htval_bits_ALL)
  );
  HipModule hip (
    .w_wen              (wen_hip),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (hip_rdata),
    .regOut_VSSIP       (hip_regOut_VSSIP),
    .regOut_VSTIP       (hip_regOut_VSTIP),
    .regOut_VSEIP       (hip_regOut_VSEIP),
    .regOut_SGEIP       (hip_regOut_SGEIP),
    .mip_VSTIP          (mip_rdata[6]),
    .mip_VSEIP          (mip_rdata[10]),
    .mip_SGEIP          (mip_rdata[12]),
    .hvip_VSSIP         (hvip_regOut_VSSIP),
    .toHvip_VSSIP_valid (hip_toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits  (hip_toHvip_VSSIP_bits)
  );
  HvipModule hvip (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_hvip),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (hvip_rdata),
    .regOut_VSSIP            (hvip_regOut_VSSIP),
    .regOut_VSTIP            (hvip_regOut_VSTIP),
    .regOut_VSEIP            (hvip_regOut_VSEIP),
    .regOut_LCOFIP           (hvip_regOut_LCOFIP),
    .regOut_LC14IP           (hvip_regOut_LC14IP),
    .regOut_LC15IP           (hvip_regOut_LC15IP),
    .regOut_LC16IP           (hvip_regOut_LC16IP),
    .regOut_LC17IP           (hvip_regOut_LC17IP),
    .regOut_LC18IP           (hvip_regOut_LC18IP),
    .regOut_LC19IP           (hvip_regOut_LC19IP),
    .regOut_LC20IP           (hvip_regOut_LC20IP),
    .regOut_LC21IP           (hvip_regOut_LC21IP),
    .regOut_LC22IP           (hvip_regOut_LC22IP),
    .regOut_LC23IP           (hvip_regOut_LC23IP),
    .regOut_LC24IP           (hvip_regOut_LC24IP),
    .regOut_LC25IP           (hvip_regOut_LC25IP),
    .regOut_LC26IP           (hvip_regOut_LC26IP),
    .regOut_LC27IP           (hvip_regOut_LC27IP),
    .regOut_LC28IP           (hvip_regOut_LC28IP),
    .regOut_LC29IP           (hvip_regOut_LC29IP),
    .regOut_LC30IP           (hvip_regOut_LC30IP),
    .regOut_LC31IP           (hvip_regOut_LC31IP),
    .regOut_LC32IP           (hvip_regOut_LC32IP),
    .regOut_LC33IP           (hvip_regOut_LC33IP),
    .regOut_LC34IP           (hvip_regOut_LC34IP),
    .regOut_LPRASEIP         (hvip_regOut_LPRASEIP),
    .regOut_LC36IP           (hvip_regOut_LC36IP),
    .regOut_LC37IP           (hvip_regOut_LC37IP),
    .regOut_LC38IP           (hvip_regOut_LC38IP),
    .regOut_LC39IP           (hvip_regOut_LC39IP),
    .regOut_LC40IP           (hvip_regOut_LC40IP),
    .regOut_LC41IP           (hvip_regOut_LC41IP),
    .regOut_LC42IP           (hvip_regOut_LC42IP),
    .regOut_HPRASEIP         (hvip_regOut_HPRASEIP),
    .regOut_LC44IP           (hvip_regOut_LC44IP),
    .regOut_LC45IP           (hvip_regOut_LC45IP),
    .regOut_LC46IP           (hvip_regOut_LC46IP),
    .regOut_LC47IP           (hvip_regOut_LC47IP),
    .regOut_LC48IP           (hvip_regOut_LC48IP),
    .regOut_LC49IP           (hvip_regOut_LC49IP),
    .regOut_LC50IP           (hvip_regOut_LC50IP),
    .regOut_LC51IP           (hvip_regOut_LC51IP),
    .regOut_LC52IP           (hvip_regOut_LC52IP),
    .regOut_LC53IP           (hvip_regOut_LC53IP),
    .regOut_LC54IP           (hvip_regOut_LC54IP),
    .regOut_LC55IP           (hvip_regOut_LC55IP),
    .regOut_LC56IP           (hvip_regOut_LC56IP),
    .regOut_LC57IP           (hvip_regOut_LC57IP),
    .regOut_LC58IP           (hvip_regOut_LC58IP),
    .regOut_LC59IP           (hvip_regOut_LC59IP),
    .regOut_LC60IP           (hvip_regOut_LC60IP),
    .regOut_LC61IP           (hvip_regOut_LC61IP),
    .regOut_LC62IP           (hvip_regOut_LC62IP),
    .regOut_LC63IP           (hvip_regOut_LC63IP),
    .fromMip_VSSIP_valid     (mip_toHvip_VSSIP_valid),
    .fromMip_VSSIP_bits      (mip_toHvip_VSSIP_bits),
    .fromHip_VSSIP_valid     (hip_toHvip_VSSIP_valid),
    .fromHip_VSSIP_bits      (hip_toHvip_VSSIP_bits),
    .fromVSip_VSSIP_valid    (vsip_toHvip_VSSIP_valid),
    .fromVSip_VSSIP_bits     (vsip_toHvip_VSSIP_bits),
    .fromVSip_LCOFIP_bits    (vsip_toHvip_LCOFIP_bits),
    .fromVSip_LC14IP_valid   (vsip_toHvip_LC14IP_valid),
    .fromVSip_LC14IP_bits    (vsip_toHvip_LC14IP_bits),
    .fromVSip_LC15IP_valid   (vsip_toHvip_LC15IP_valid),
    .fromVSip_LC15IP_bits    (vsip_toHvip_LC15IP_bits),
    .fromVSip_LC16IP_valid   (vsip_toHvip_LC16IP_valid),
    .fromVSip_LC16IP_bits    (vsip_toHvip_LC16IP_bits),
    .fromVSip_LC17IP_valid   (vsip_toHvip_LC17IP_valid),
    .fromVSip_LC17IP_bits    (vsip_toHvip_LC17IP_bits),
    .fromVSip_LC18IP_valid   (vsip_toHvip_LC18IP_valid),
    .fromVSip_LC18IP_bits    (vsip_toHvip_LC18IP_bits),
    .fromVSip_LC19IP_valid   (vsip_toHvip_LC19IP_valid),
    .fromVSip_LC19IP_bits    (vsip_toHvip_LC19IP_bits),
    .fromVSip_LC20IP_valid   (vsip_toHvip_LC20IP_valid),
    .fromVSip_LC20IP_bits    (vsip_toHvip_LC20IP_bits),
    .fromVSip_LC21IP_valid   (vsip_toHvip_LC21IP_valid),
    .fromVSip_LC21IP_bits    (vsip_toHvip_LC21IP_bits),
    .fromVSip_LC22IP_valid   (vsip_toHvip_LC22IP_valid),
    .fromVSip_LC22IP_bits    (vsip_toHvip_LC22IP_bits),
    .fromVSip_LC23IP_valid   (vsip_toHvip_LC23IP_valid),
    .fromVSip_LC23IP_bits    (vsip_toHvip_LC23IP_bits),
    .fromVSip_LC24IP_valid   (vsip_toHvip_LC24IP_valid),
    .fromVSip_LC24IP_bits    (vsip_toHvip_LC24IP_bits),
    .fromVSip_LC25IP_valid   (vsip_toHvip_LC25IP_valid),
    .fromVSip_LC25IP_bits    (vsip_toHvip_LC25IP_bits),
    .fromVSip_LC26IP_valid   (vsip_toHvip_LC26IP_valid),
    .fromVSip_LC26IP_bits    (vsip_toHvip_LC26IP_bits),
    .fromVSip_LC27IP_valid   (vsip_toHvip_LC27IP_valid),
    .fromVSip_LC27IP_bits    (vsip_toHvip_LC27IP_bits),
    .fromVSip_LC28IP_valid   (vsip_toHvip_LC28IP_valid),
    .fromVSip_LC28IP_bits    (vsip_toHvip_LC28IP_bits),
    .fromVSip_LC29IP_valid   (vsip_toHvip_LC29IP_valid),
    .fromVSip_LC29IP_bits    (vsip_toHvip_LC29IP_bits),
    .fromVSip_LC30IP_valid   (vsip_toHvip_LC30IP_valid),
    .fromVSip_LC30IP_bits    (vsip_toHvip_LC30IP_bits),
    .fromVSip_LC31IP_valid   (vsip_toHvip_LC31IP_valid),
    .fromVSip_LC31IP_bits    (vsip_toHvip_LC31IP_bits),
    .fromVSip_LC32IP_valid   (vsip_toHvip_LC32IP_valid),
    .fromVSip_LC32IP_bits    (vsip_toHvip_LC32IP_bits),
    .fromVSip_LC33IP_valid   (vsip_toHvip_LC33IP_valid),
    .fromVSip_LC33IP_bits    (vsip_toHvip_LC33IP_bits),
    .fromVSip_LC34IP_valid   (vsip_toHvip_LC34IP_valid),
    .fromVSip_LC34IP_bits    (vsip_toHvip_LC34IP_bits),
    .fromVSip_LPRASEIP_valid (vsip_toHvip_LPRASEIP_valid),
    .fromVSip_LPRASEIP_bits  (vsip_toHvip_LPRASEIP_bits),
    .fromVSip_LC36IP_valid   (vsip_toHvip_LC36IP_valid),
    .fromVSip_LC36IP_bits    (vsip_toHvip_LC36IP_bits),
    .fromVSip_LC37IP_valid   (vsip_toHvip_LC37IP_valid),
    .fromVSip_LC37IP_bits    (vsip_toHvip_LC37IP_bits),
    .fromVSip_LC38IP_valid   (vsip_toHvip_LC38IP_valid),
    .fromVSip_LC38IP_bits    (vsip_toHvip_LC38IP_bits),
    .fromVSip_LC39IP_valid   (vsip_toHvip_LC39IP_valid),
    .fromVSip_LC39IP_bits    (vsip_toHvip_LC39IP_bits),
    .fromVSip_LC40IP_valid   (vsip_toHvip_LC40IP_valid),
    .fromVSip_LC40IP_bits    (vsip_toHvip_LC40IP_bits),
    .fromVSip_LC41IP_valid   (vsip_toHvip_LC41IP_valid),
    .fromVSip_LC41IP_bits    (vsip_toHvip_LC41IP_bits),
    .fromVSip_LC42IP_valid   (vsip_toHvip_LC42IP_valid),
    .fromVSip_LC42IP_bits    (vsip_toHvip_LC42IP_bits),
    .fromVSip_HPRASEIP_valid (vsip_toHvip_HPRASEIP_valid),
    .fromVSip_HPRASEIP_bits  (vsip_toHvip_HPRASEIP_bits),
    .fromVSip_LC44IP_valid   (vsip_toHvip_LC44IP_valid),
    .fromVSip_LC44IP_bits    (vsip_toHvip_LC44IP_bits),
    .fromVSip_LC45IP_valid   (vsip_toHvip_LC45IP_valid),
    .fromVSip_LC45IP_bits    (vsip_toHvip_LC45IP_bits),
    .fromVSip_LC46IP_valid   (vsip_toHvip_LC46IP_valid),
    .fromVSip_LC46IP_bits    (vsip_toHvip_LC46IP_bits),
    .fromVSip_LC47IP_valid   (vsip_toHvip_LC47IP_valid),
    .fromVSip_LC47IP_bits    (vsip_toHvip_LC47IP_bits),
    .fromVSip_LC48IP_valid   (vsip_toHvip_LC48IP_valid),
    .fromVSip_LC48IP_bits    (vsip_toHvip_LC48IP_bits),
    .fromVSip_LC49IP_valid   (vsip_toHvip_LC49IP_valid),
    .fromVSip_LC49IP_bits    (vsip_toHvip_LC49IP_bits),
    .fromVSip_LC50IP_valid   (vsip_toHvip_LC50IP_valid),
    .fromVSip_LC50IP_bits    (vsip_toHvip_LC50IP_bits),
    .fromVSip_LC51IP_valid   (vsip_toHvip_LC51IP_valid),
    .fromVSip_LC51IP_bits    (vsip_toHvip_LC51IP_bits),
    .fromVSip_LC52IP_valid   (vsip_toHvip_LC52IP_valid),
    .fromVSip_LC52IP_bits    (vsip_toHvip_LC52IP_bits),
    .fromVSip_LC53IP_valid   (vsip_toHvip_LC53IP_valid),
    .fromVSip_LC53IP_bits    (vsip_toHvip_LC53IP_bits),
    .fromVSip_LC54IP_valid   (vsip_toHvip_LC54IP_valid),
    .fromVSip_LC54IP_bits    (vsip_toHvip_LC54IP_bits),
    .fromVSip_LC55IP_valid   (vsip_toHvip_LC55IP_valid),
    .fromVSip_LC55IP_bits    (vsip_toHvip_LC55IP_bits),
    .fromVSip_LC56IP_valid   (vsip_toHvip_LC56IP_valid),
    .fromVSip_LC56IP_bits    (vsip_toHvip_LC56IP_bits),
    .fromVSip_LC57IP_valid   (vsip_toHvip_LC57IP_valid),
    .fromVSip_LC57IP_bits    (vsip_toHvip_LC57IP_bits),
    .fromVSip_LC58IP_valid   (vsip_toHvip_LC58IP_valid),
    .fromVSip_LC58IP_bits    (vsip_toHvip_LC58IP_bits),
    .fromVSip_LC59IP_valid   (vsip_toHvip_LC59IP_valid),
    .fromVSip_LC59IP_bits    (vsip_toHvip_LC59IP_bits),
    .fromVSip_LC60IP_valid   (vsip_toHvip_LC60IP_valid),
    .fromVSip_LC60IP_bits    (vsip_toHvip_LC60IP_bits),
    .fromVSip_LC61IP_valid   (vsip_toHvip_LC61IP_valid),
    .fromVSip_LC61IP_bits    (vsip_toHvip_LC61IP_bits),
    .fromVSip_LC62IP_valid   (vsip_toHvip_LC62IP_valid),
    .fromVSip_LC62IP_bits    (vsip_toHvip_LC62IP_bits),
    .fromVSip_LC63IP_valid   (vsip_toHvip_LC63IP_valid),
    .fromVSip_LC63IP_bits    (vsip_toHvip_LC63IP_bits)
  );
  Hviprio1Module hviprio1 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_hviprio1),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (hviprio1_rdata),
    .regOut_PrioSSI (hviprio1_regOut_PrioSSI),
    .regOut_PrioSTI (hviprio1_regOut_PrioSTI),
    .regOut_PrioCOI (hviprio1_regOut_PrioCOI),
    .regOut_Prio14  (hviprio1_regOut_Prio14),
    .regOut_Prio15  (hviprio1_regOut_Prio15)
  );
  Hviprio2Module hviprio2 (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_hviprio2),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (hviprio2_rdata),
    .regOut_ALL (hviprio2_regOut_ALL)
  );
  HtinstModule htinst (
    .clock                    (clock),
    .reset                    (reset),
    .w_wen                    (wen_htinst),
    .w_wdata                  (io_in_bits_wdata),
    .rdata                    (htinst_rdata),
    .regOut_ALL               (htinst_regOut_ALL),
    .trapToHS_htinst_valid    (trapEntryHSEvent_out_htinst_valid),
    .trapToHS_htinst_bits_ALL (trapEntryHSEvent_out_htinst_bits_ALL)
  );
  HgatpModule hgatp (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_hgatp),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (hgatp_rdata),
    .regOut_MODE (hgatp_regOut_MODE),
    .regOut_VMID (hgatp_regOut_VMID),
    .regOut_PPN  (hgatp_regOut_PPN)
  );
  HgeipModule hgeip (
    .rdata          (hgeip_rdata),
    .regOut_ip      (hgeip_regOut_ip),
    .aiaToCSR_vseip (fromAIA_vseip)
  );
  Hstateen0Module hstateen0 (
    .clock                 (clock),
    .reset                 (reset),
    .w_wen                 (wen_hstateen0),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (hstateen0_rdata),
    .regOut_JVT            (hstateen0_regOut_JVT),
    .regOut_FCSR           (hstateen0_regOut_FCSR),
    .regOut_C              (hstateen0_regOut_C),
    .regOut_SE0            (hstateen0_regOut_SE0),
    .regOut_ENVCFG         (hstateen0_regOut_ENVCFG),
    .regOut_CSRIND         (hstateen0_regOut_CSRIND),
    .regOut_AIA            (hstateen0_regOut_AIA),
    .regOut_IMSIC          (hstateen0_regOut_IMSIC),
    .regOut_CONTEXT        (hstateen0_regOut_CONTEXT),
    .fromMstateen0_SE0     (mstateen0_regOut_SE0),
    .fromMstateen0_ENVCFG  (mstateen0_regOut_ENVCFG),
    .fromMstateen0_CSRIND  (mstateen0_regOut_CSRIND),
    .fromMstateen0_AIA     (mstateen0_regOut_AIA),
    .fromMstateen0_IMSIC   (mstateen0_regOut_IMSIC),
    .fromMstateen0_CONTEXT (mstateen0_regOut_CONTEXT),
    .fromMstateen0_C       (mstateen0_regOut_C)
  );
  Hstateen1Module hstateen1 (
    .clock            (clock),
    .w_wen            (wen_hstateen1),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (hstateen1_rdata),
    .regOut_SE        (hstateen1_regOut_SE),
    .fromMstateen1_SE (mstateen1_regOut_SE)
  );
  Hstateen2Module hstateen2 (
    .clock            (clock),
    .w_wen            (wen_hstateen2),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (hstateen2_rdata),
    .regOut_SE        (hstateen2_regOut_SE),
    .fromMstateen2_SE (mstateen2_regOut_SE)
  );
  Hstateen3Module hstateen3 (
    .clock            (clock),
    .w_wen            (wen_hstateen3),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (hstateen3_rdata),
    .regOut_SE        (hstateen3_regOut_SE),
    .fromMstateen3_SE (mstateen3_regOut_SE)
  );
  HcontextModule hcontext (
    .w_wen                    (wen_hcontext),
    .w_wdata                  (io_in_bits_wdata),
    .rdata                    (hcontext_rdata),
    .regOut_HCONTEXT          (hcontext_regOut_HCONTEXT),
    .fromMcontext_HCONTEXT    (mcontext_toHcontext_HCONTEXT),
    .toMcontext_valid         (hcontext_toMcontext_valid),
    .toMcontext_bits_HCONTEXT (hcontext_toMcontext_bits_HCONTEXT)
  );
  VSstatusModule vsstatus (
    .clock                       (clock),
    .reset                       (reset),
    .w_wen                       (wen_vsstatus),
    .w_wdata                     (io_in_bits_wdata),
    .rdata                       (vsstatus_rdata),
    .regOut_SIE                  (vsstatus_regOut_SIE),
    .regOut_SPIE                 (vsstatus_regOut_SPIE),
    .regOut_SPP                  (vsstatus_regOut_SPP),
    .regOut_VS                   (vsstatus_regOut_VS),
    .regOut_FS                   (vsstatus_regOut_FS),
    .regOut_SUM                  (vsstatus_regOut_SUM),
    .regOut_MXR                  (vsstatus_regOut_MXR),
    .regOut_SDT                  (vsstatus_regOut_SDT),
    .retFromS_vsstatus_valid     (sretEvent_out_vsstatus_valid),
    .retFromS_vsstatus_bits_SIE  (sretEvent_out_vsstatus_bits_SIE),
    .retFromS_vsstatus_bits_SPIE (sretEvent_out_vsstatus_bits_SPIE),
    .retFromS_vsstatus_bits_SPP  (sretEvent_out_vsstatus_bits_SPP),
    .retFromSSDT_vsstatus_valid  (sretEvent_outSDT_vsstatus_valid),
    .retFromM_vsstatus_valid     (mretEvent_out_vsstatus_valid),
    .retFromM_vsstatus_bits_SDT  (mretEvent_out_vsstatus_bits_SDT),
    .retFromMN_vsstatus_valid    (mnretEvent_out_vsstatus_valid),
    .retFromMN_vsstatus_bits_SDT (mnretEvent_out_vsstatus_bits_SDT),
    .retFromD_vsstatus_valid     (dretEvent_out_vsstatus_valid),
    .retFromD_vsstatus_bits_SDT  (dretEvent_out_vsstatus_bits_SDT),
    .trapToVS_vsstatus_valid     (trapEntryVSEvent_out_vsstatus_valid),
    .trapToVS_vsstatus_bits_SIE  (trapEntryVSEvent_out_vsstatus_bits_SIE),
    .trapToVS_vsstatus_bits_SPIE (trapEntryVSEvent_out_vsstatus_bits_SPIE),
    .trapToVS_vsstatus_bits_SPP  (trapEntryVSEvent_out_vsstatus_bits_SPP),
    .trapToVS_vsstatus_bits_SDT  (trapEntryVSEvent_out_vsstatus_bits_SDT),
    .robCommit_fsDirty           (vsstatus_cmt_fs_dirty_q),
    .robCommit_vsDirty           (vsstatus_cmt_vs_dirty_q),
    .robCommit_vstart_valid      (vsstatus_cmt_vstart_valid_q),
    .robCommit_vstart_bits       (vsstatus_cmt_vstart_bits_q),
    .writeFCSR                   (permitMod_io_out_hasLegalWriteFcsr),
    .writeVCSR                   (permitMod_io_out_hasLegalWriteVcsr),
    .isVirtMode                  (virt),
    .menvcfg_DTE                 (menvcfg_regOut_DTE),
    .henvcfg_DTE                 (henvcfg_regOut_DTE)
  );
  VSieModule vsie (
    .clock                (clock),
    .reset                (reset),
    .w_wen                (wen_vsie),
    .w_wdata              (io_in_bits_wdata),
    .rdata                (vsie_rdata),
    .regOut_SSIE          (vsie_regOut_SSIE),
    .regOut_STIE          (vsie_regOut_STIE),
    .regOut_SEIE          (vsie_regOut_SEIE),
    .regOut_LCOFIE        (vsie_regOut_LCOFIE),
    .regOut_LC14IE        (vsie_regOut_LC14IE),
    .regOut_LC15IE        (vsie_regOut_LC15IE),
    .regOut_LC16IE        (vsie_regOut_LC16IE),
    .regOut_LC17IE        (vsie_regOut_LC17IE),
    .regOut_LC18IE        (vsie_regOut_LC18IE),
    .regOut_LC19IE        (vsie_regOut_LC19IE),
    .regOut_LC20IE        (vsie_regOut_LC20IE),
    .regOut_LC21IE        (vsie_regOut_LC21IE),
    .regOut_LC22IE        (vsie_regOut_LC22IE),
    .regOut_LC23IE        (vsie_regOut_LC23IE),
    .regOut_LC24IE        (vsie_regOut_LC24IE),
    .regOut_LC25IE        (vsie_regOut_LC25IE),
    .regOut_LC26IE        (vsie_regOut_LC26IE),
    .regOut_LC27IE        (vsie_regOut_LC27IE),
    .regOut_LC28IE        (vsie_regOut_LC28IE),
    .regOut_LC29IE        (vsie_regOut_LC29IE),
    .regOut_LC30IE        (vsie_regOut_LC30IE),
    .regOut_LC31IE        (vsie_regOut_LC31IE),
    .regOut_LC32IE        (vsie_regOut_LC32IE),
    .regOut_LC33IE        (vsie_regOut_LC33IE),
    .regOut_LC34IE        (vsie_regOut_LC34IE),
    .regOut_LPRASEIE      (vsie_regOut_LPRASEIE),
    .regOut_LC36IE        (vsie_regOut_LC36IE),
    .regOut_LC37IE        (vsie_regOut_LC37IE),
    .regOut_LC38IE        (vsie_regOut_LC38IE),
    .regOut_LC39IE        (vsie_regOut_LC39IE),
    .regOut_LC40IE        (vsie_regOut_LC40IE),
    .regOut_LC41IE        (vsie_regOut_LC41IE),
    .regOut_LC42IE        (vsie_regOut_LC42IE),
    .regOut_HPRASEIE      (vsie_regOut_HPRASEIE),
    .regOut_LC44IE        (vsie_regOut_LC44IE),
    .regOut_LC45IE        (vsie_regOut_LC45IE),
    .regOut_LC46IE        (vsie_regOut_LC46IE),
    .regOut_LC47IE        (vsie_regOut_LC47IE),
    .regOut_LC48IE        (vsie_regOut_LC48IE),
    .regOut_LC49IE        (vsie_regOut_LC49IE),
    .regOut_LC50IE        (vsie_regOut_LC50IE),
    .regOut_LC51IE        (vsie_regOut_LC51IE),
    .regOut_LC52IE        (vsie_regOut_LC52IE),
    .regOut_LC53IE        (vsie_regOut_LC53IE),
    .regOut_LC54IE        (vsie_regOut_LC54IE),
    .regOut_LC55IE        (vsie_regOut_LC55IE),
    .regOut_LC56IE        (vsie_regOut_LC56IE),
    .regOut_LC57IE        (vsie_regOut_LC57IE),
    .regOut_LC58IE        (vsie_regOut_LC58IE),
    .regOut_LC59IE        (vsie_regOut_LC59IE),
    .regOut_LC60IE        (vsie_regOut_LC60IE),
    .regOut_LC61IE        (vsie_regOut_LC61IE),
    .regOut_LC62IE        (vsie_regOut_LC62IE),
    .regOut_LC63IE        (vsie_regOut_LC63IE),
    .mideleg_SSI          (mideleg_regOut_SSI),
    .mideleg_STI          (mideleg_regOut_STI),
    .mideleg_SEI          (mideleg_regOut_SEI),
    .mideleg_LCOFI        (mideleg_regOut_LCOFI),
    .mie_SSIE             (mie_regOut_SSIE),
    .mie_VSSIE            (mie_regOut_VSSIE),
    .mie_MSIE             (mie_regOut_MSIE),
    .mie_STIE             (mie_regOut_STIE),
    .mie_VSTIE            (mie_regOut_VSTIE),
    .mie_MTIE             (mie_regOut_MTIE),
    .mie_SEIE             (mie_regOut_SEIE),
    .mie_VSEIE            (mie_regOut_VSEIE),
    .mie_MEIE             (mie_regOut_MEIE),
    .mie_SGEIE            (mie_regOut_SGEIE),
    .mie_LCOFIE           (mie_regOut_LCOFIE),
    .mvien_SSIE           (mvien_regOut_SSIE),
    .mvien_SEIE           (mvien_regOut_SEIE),
    .mvien_LC14IE         (mvien_regOut_LC14IE),
    .mvien_LC15IE         (mvien_regOut_LC15IE),
    .mvien_LC16IE         (mvien_regOut_LC16IE),
    .mvien_LC17IE         (mvien_regOut_LC17IE),
    .mvien_LC18IE         (mvien_regOut_LC18IE),
    .mvien_LC19IE         (mvien_regOut_LC19IE),
    .mvien_LC20IE         (mvien_regOut_LC20IE),
    .mvien_LC21IE         (mvien_regOut_LC21IE),
    .mvien_LC22IE         (mvien_regOut_LC22IE),
    .mvien_LC23IE         (mvien_regOut_LC23IE),
    .mvien_LC24IE         (mvien_regOut_LC24IE),
    .mvien_LC25IE         (mvien_regOut_LC25IE),
    .mvien_LC26IE         (mvien_regOut_LC26IE),
    .mvien_LC27IE         (mvien_regOut_LC27IE),
    .mvien_LC28IE         (mvien_regOut_LC28IE),
    .mvien_LC29IE         (mvien_regOut_LC29IE),
    .mvien_LC30IE         (mvien_regOut_LC30IE),
    .mvien_LC31IE         (mvien_regOut_LC31IE),
    .mvien_LC32IE         (mvien_regOut_LC32IE),
    .mvien_LC33IE         (mvien_regOut_LC33IE),
    .mvien_LC34IE         (mvien_regOut_LC34IE),
    .mvien_LPRASEIE       (mvien_regOut_LPRASEIE),
    .mvien_LC36IE         (mvien_regOut_LC36IE),
    .mvien_LC37IE         (mvien_regOut_LC37IE),
    .mvien_LC38IE         (mvien_regOut_LC38IE),
    .mvien_LC39IE         (mvien_regOut_LC39IE),
    .mvien_LC40IE         (mvien_regOut_LC40IE),
    .mvien_LC41IE         (mvien_regOut_LC41IE),
    .mvien_LC42IE         (mvien_regOut_LC42IE),
    .mvien_HPRASEIE       (mvien_regOut_HPRASEIE),
    .mvien_LC44IE         (mvien_regOut_LC44IE),
    .mvien_LC45IE         (mvien_regOut_LC45IE),
    .mvien_LC46IE         (mvien_regOut_LC46IE),
    .mvien_LC47IE         (mvien_regOut_LC47IE),
    .mvien_LC48IE         (mvien_regOut_LC48IE),
    .mvien_LC49IE         (mvien_regOut_LC49IE),
    .mvien_LC50IE         (mvien_regOut_LC50IE),
    .mvien_LC51IE         (mvien_regOut_LC51IE),
    .mvien_LC52IE         (mvien_regOut_LC52IE),
    .mvien_LC53IE         (mvien_regOut_LC53IE),
    .mvien_LC54IE         (mvien_regOut_LC54IE),
    .mvien_LC55IE         (mvien_regOut_LC55IE),
    .mvien_LC56IE         (mvien_regOut_LC56IE),
    .mvien_LC57IE         (mvien_regOut_LC57IE),
    .mvien_LC58IE         (mvien_regOut_LC58IE),
    .mvien_LC59IE         (mvien_regOut_LC59IE),
    .mvien_LC60IE         (mvien_regOut_LC60IE),
    .mvien_LC61IE         (mvien_regOut_LC61IE),
    .mvien_LC62IE         (mvien_regOut_LC62IE),
    .mvien_LC63IE         (mvien_regOut_LC63IE),
    .hideleg_SSI          (hideleg_regOut_SSI),
    .hideleg_VSSI         (hideleg_regOut_VSSI),
    .hideleg_MSI          (hideleg_regOut_MSI),
    .hideleg_STI          (hideleg_regOut_STI),
    .hideleg_VSTI         (hideleg_regOut_VSTI),
    .hideleg_MTI          (hideleg_regOut_MTI),
    .hideleg_SEI          (hideleg_regOut_SEI),
    .hideleg_VSEI         (hideleg_regOut_VSEI),
    .hideleg_MEI          (hideleg_regOut_MEI),
    .hideleg_SGEI         (hideleg_regOut_SGEI),
    .hideleg_LCOFI        (hideleg_regOut_LCOFI),
    .hvien_LC14IE         (hvien_regOut_LC14IE),
    .hvien_LC15IE         (hvien_regOut_LC15IE),
    .hvien_LC16IE         (hvien_regOut_LC16IE),
    .hvien_LC17IE         (hvien_regOut_LC17IE),
    .hvien_LC18IE         (hvien_regOut_LC18IE),
    .hvien_LC19IE         (hvien_regOut_LC19IE),
    .hvien_LC20IE         (hvien_regOut_LC20IE),
    .hvien_LC21IE         (hvien_regOut_LC21IE),
    .hvien_LC22IE         (hvien_regOut_LC22IE),
    .hvien_LC23IE         (hvien_regOut_LC23IE),
    .hvien_LC24IE         (hvien_regOut_LC24IE),
    .hvien_LC25IE         (hvien_regOut_LC25IE),
    .hvien_LC26IE         (hvien_regOut_LC26IE),
    .hvien_LC27IE         (hvien_regOut_LC27IE),
    .hvien_LC28IE         (hvien_regOut_LC28IE),
    .hvien_LC29IE         (hvien_regOut_LC29IE),
    .hvien_LC30IE         (hvien_regOut_LC30IE),
    .hvien_LC31IE         (hvien_regOut_LC31IE),
    .hvien_LC32IE         (hvien_regOut_LC32IE),
    .hvien_LC33IE         (hvien_regOut_LC33IE),
    .hvien_LC34IE         (hvien_regOut_LC34IE),
    .hvien_LPRASEIE       (hvien_regOut_LPRASEIE),
    .hvien_LC36IE         (hvien_regOut_LC36IE),
    .hvien_LC37IE         (hvien_regOut_LC37IE),
    .hvien_LC38IE         (hvien_regOut_LC38IE),
    .hvien_LC39IE         (hvien_regOut_LC39IE),
    .hvien_LC40IE         (hvien_regOut_LC40IE),
    .hvien_LC41IE         (hvien_regOut_LC41IE),
    .hvien_LC42IE         (hvien_regOut_LC42IE),
    .hvien_HPRASEIE       (hvien_regOut_HPRASEIE),
    .hvien_LC44IE         (hvien_regOut_LC44IE),
    .hvien_LC45IE         (hvien_regOut_LC45IE),
    .hvien_LC46IE         (hvien_regOut_LC46IE),
    .hvien_LC47IE         (hvien_regOut_LC47IE),
    .hvien_LC48IE         (hvien_regOut_LC48IE),
    .hvien_LC49IE         (hvien_regOut_LC49IE),
    .hvien_LC50IE         (hvien_regOut_LC50IE),
    .hvien_LC51IE         (hvien_regOut_LC51IE),
    .hvien_LC52IE         (hvien_regOut_LC52IE),
    .hvien_LC53IE         (hvien_regOut_LC53IE),
    .hvien_LC54IE         (hvien_regOut_LC54IE),
    .hvien_LC55IE         (hvien_regOut_LC55IE),
    .hvien_LC56IE         (hvien_regOut_LC56IE),
    .hvien_LC57IE         (hvien_regOut_LC57IE),
    .hvien_LC58IE         (hvien_regOut_LC58IE),
    .hvien_LC59IE         (hvien_regOut_LC59IE),
    .hvien_LC60IE         (hvien_regOut_LC60IE),
    .hvien_LC61IE         (hvien_regOut_LC61IE),
    .hvien_LC62IE         (hvien_regOut_LC62IE),
    .hvien_LC63IE         (hvien_regOut_LC63IE),
    .sie_SSIE             (sie_regOut_SSIE),
    .sie_STIE             (sie_regOut_STIE),
    .sie_SEIE             (sie_regOut_SEIE),
    .sie_LCOFIE           (sie_regOut_LCOFIE),
    .sie_LC14IE           (sie_regOut_LC14IE),
    .sie_LC15IE           (sie_regOut_LC15IE),
    .sie_LC16IE           (sie_regOut_LC16IE),
    .sie_LC17IE           (sie_regOut_LC17IE),
    .sie_LC18IE           (sie_regOut_LC18IE),
    .sie_LC19IE           (sie_regOut_LC19IE),
    .sie_LC20IE           (sie_regOut_LC20IE),
    .sie_LC21IE           (sie_regOut_LC21IE),
    .sie_LC22IE           (sie_regOut_LC22IE),
    .sie_LC23IE           (sie_regOut_LC23IE),
    .sie_LC24IE           (sie_regOut_LC24IE),
    .sie_LC25IE           (sie_regOut_LC25IE),
    .sie_LC26IE           (sie_regOut_LC26IE),
    .sie_LC27IE           (sie_regOut_LC27IE),
    .sie_LC28IE           (sie_regOut_LC28IE),
    .sie_LC29IE           (sie_regOut_LC29IE),
    .sie_LC30IE           (sie_regOut_LC30IE),
    .sie_LC31IE           (sie_regOut_LC31IE),
    .sie_LC32IE           (sie_regOut_LC32IE),
    .sie_LC33IE           (sie_regOut_LC33IE),
    .sie_LC34IE           (sie_regOut_LC34IE),
    .sie_LPRASEIE         (sie_regOut_LPRASEIE),
    .sie_LC36IE           (sie_regOut_LC36IE),
    .sie_LC37IE           (sie_regOut_LC37IE),
    .sie_LC38IE           (sie_regOut_LC38IE),
    .sie_LC39IE           (sie_regOut_LC39IE),
    .sie_LC40IE           (sie_regOut_LC40IE),
    .sie_LC41IE           (sie_regOut_LC41IE),
    .sie_LC42IE           (sie_regOut_LC42IE),
    .sie_HPRASEIE         (sie_regOut_HPRASEIE),
    .sie_LC44IE           (sie_regOut_LC44IE),
    .sie_LC45IE           (sie_regOut_LC45IE),
    .sie_LC46IE           (sie_regOut_LC46IE),
    .sie_LC47IE           (sie_regOut_LC47IE),
    .sie_LC48IE           (sie_regOut_LC48IE),
    .sie_LC49IE           (sie_regOut_LC49IE),
    .sie_LC50IE           (sie_regOut_LC50IE),
    .sie_LC51IE           (sie_regOut_LC51IE),
    .sie_LC52IE           (sie_regOut_LC52IE),
    .sie_LC53IE           (sie_regOut_LC53IE),
    .sie_LC54IE           (sie_regOut_LC54IE),
    .sie_LC55IE           (sie_regOut_LC55IE),
    .sie_LC56IE           (sie_regOut_LC56IE),
    .sie_LC57IE           (sie_regOut_LC57IE),
    .sie_LC58IE           (sie_regOut_LC58IE),
    .sie_LC59IE           (sie_regOut_LC59IE),
    .sie_LC60IE           (sie_regOut_LC60IE),
    .sie_LC61IE           (sie_regOut_LC61IE),
    .sie_LC62IE           (sie_regOut_LC62IE),
    .sie_LC63IE           (sie_regOut_LC63IE),
    .toMie_VSSIE_valid    (vsie_toMie_VSSIE_valid),
    .toMie_VSSIE_bits     (vsie_toMie_VSSIE_bits),
    .toMie_VSTIE_valid    (vsie_toMie_VSTIE_valid),
    .toMie_VSTIE_bits     (vsie_toMie_VSTIE_bits),
    .toMie_VSEIE_valid    (vsie_toMie_VSEIE_valid),
    .toMie_VSEIE_bits     (vsie_toMie_VSEIE_bits),
    .toMie_LCOFIE_valid   (vsie_toMie_LCOFIE_valid),
    .toMie_LCOFIE_bits    (vsie_toMie_LCOFIE_bits),
    .toSie_VSSIE_valid    (vsie_toSie_VSSIE_valid),
    .toSie_VSSIE_bits     (vsie_toSie_VSSIE_bits),
    .toSie_VSTIE_valid    (vsie_toSie_VSTIE_valid),
    .toSie_VSTIE_bits     (vsie_toSie_VSTIE_bits),
    .toSie_VSEIE_valid    (vsie_toSie_VSEIE_valid),
    .toSie_VSEIE_bits     (vsie_toSie_VSEIE_bits),
    .toSie_LCOFIE_valid   (vsie_toSie_LCOFIE_valid),
    .toSie_LCOFIE_bits    (vsie_toSie_LCOFIE_bits),
    .toSie_LC14IE_valid   (vsie_toSie_LC14IE_valid),
    .toSie_LC14IE_bits    (vsie_toSie_LC14IE_bits),
    .toSie_LC15IE_valid   (vsie_toSie_LC15IE_valid),
    .toSie_LC15IE_bits    (vsie_toSie_LC15IE_bits),
    .toSie_LC16IE_valid   (vsie_toSie_LC16IE_valid),
    .toSie_LC16IE_bits    (vsie_toSie_LC16IE_bits),
    .toSie_LC17IE_valid   (vsie_toSie_LC17IE_valid),
    .toSie_LC17IE_bits    (vsie_toSie_LC17IE_bits),
    .toSie_LC18IE_valid   (vsie_toSie_LC18IE_valid),
    .toSie_LC18IE_bits    (vsie_toSie_LC18IE_bits),
    .toSie_LC19IE_valid   (vsie_toSie_LC19IE_valid),
    .toSie_LC19IE_bits    (vsie_toSie_LC19IE_bits),
    .toSie_LC20IE_valid   (vsie_toSie_LC20IE_valid),
    .toSie_LC20IE_bits    (vsie_toSie_LC20IE_bits),
    .toSie_LC21IE_valid   (vsie_toSie_LC21IE_valid),
    .toSie_LC21IE_bits    (vsie_toSie_LC21IE_bits),
    .toSie_LC22IE_valid   (vsie_toSie_LC22IE_valid),
    .toSie_LC22IE_bits    (vsie_toSie_LC22IE_bits),
    .toSie_LC23IE_valid   (vsie_toSie_LC23IE_valid),
    .toSie_LC23IE_bits    (vsie_toSie_LC23IE_bits),
    .toSie_LC24IE_valid   (vsie_toSie_LC24IE_valid),
    .toSie_LC24IE_bits    (vsie_toSie_LC24IE_bits),
    .toSie_LC25IE_valid   (vsie_toSie_LC25IE_valid),
    .toSie_LC25IE_bits    (vsie_toSie_LC25IE_bits),
    .toSie_LC26IE_valid   (vsie_toSie_LC26IE_valid),
    .toSie_LC26IE_bits    (vsie_toSie_LC26IE_bits),
    .toSie_LC27IE_valid   (vsie_toSie_LC27IE_valid),
    .toSie_LC27IE_bits    (vsie_toSie_LC27IE_bits),
    .toSie_LC28IE_valid   (vsie_toSie_LC28IE_valid),
    .toSie_LC28IE_bits    (vsie_toSie_LC28IE_bits),
    .toSie_LC29IE_valid   (vsie_toSie_LC29IE_valid),
    .toSie_LC29IE_bits    (vsie_toSie_LC29IE_bits),
    .toSie_LC30IE_valid   (vsie_toSie_LC30IE_valid),
    .toSie_LC30IE_bits    (vsie_toSie_LC30IE_bits),
    .toSie_LC31IE_valid   (vsie_toSie_LC31IE_valid),
    .toSie_LC31IE_bits    (vsie_toSie_LC31IE_bits),
    .toSie_LC32IE_valid   (vsie_toSie_LC32IE_valid),
    .toSie_LC32IE_bits    (vsie_toSie_LC32IE_bits),
    .toSie_LC33IE_valid   (vsie_toSie_LC33IE_valid),
    .toSie_LC33IE_bits    (vsie_toSie_LC33IE_bits),
    .toSie_LC34IE_valid   (vsie_toSie_LC34IE_valid),
    .toSie_LC34IE_bits    (vsie_toSie_LC34IE_bits),
    .toSie_LPRASEIE_valid (vsie_toSie_LPRASEIE_valid),
    .toSie_LPRASEIE_bits  (vsie_toSie_LPRASEIE_bits),
    .toSie_LC36IE_valid   (vsie_toSie_LC36IE_valid),
    .toSie_LC36IE_bits    (vsie_toSie_LC36IE_bits),
    .toSie_LC37IE_valid   (vsie_toSie_LC37IE_valid),
    .toSie_LC37IE_bits    (vsie_toSie_LC37IE_bits),
    .toSie_LC38IE_valid   (vsie_toSie_LC38IE_valid),
    .toSie_LC38IE_bits    (vsie_toSie_LC38IE_bits),
    .toSie_LC39IE_valid   (vsie_toSie_LC39IE_valid),
    .toSie_LC39IE_bits    (vsie_toSie_LC39IE_bits),
    .toSie_LC40IE_valid   (vsie_toSie_LC40IE_valid),
    .toSie_LC40IE_bits    (vsie_toSie_LC40IE_bits),
    .toSie_LC41IE_valid   (vsie_toSie_LC41IE_valid),
    .toSie_LC41IE_bits    (vsie_toSie_LC41IE_bits),
    .toSie_LC42IE_valid   (vsie_toSie_LC42IE_valid),
    .toSie_LC42IE_bits    (vsie_toSie_LC42IE_bits),
    .toSie_HPRASEIE_valid (vsie_toSie_HPRASEIE_valid),
    .toSie_HPRASEIE_bits  (vsie_toSie_HPRASEIE_bits),
    .toSie_LC44IE_valid   (vsie_toSie_LC44IE_valid),
    .toSie_LC44IE_bits    (vsie_toSie_LC44IE_bits),
    .toSie_LC45IE_valid   (vsie_toSie_LC45IE_valid),
    .toSie_LC45IE_bits    (vsie_toSie_LC45IE_bits),
    .toSie_LC46IE_valid   (vsie_toSie_LC46IE_valid),
    .toSie_LC46IE_bits    (vsie_toSie_LC46IE_bits),
    .toSie_LC47IE_valid   (vsie_toSie_LC47IE_valid),
    .toSie_LC47IE_bits    (vsie_toSie_LC47IE_bits),
    .toSie_LC48IE_valid   (vsie_toSie_LC48IE_valid),
    .toSie_LC48IE_bits    (vsie_toSie_LC48IE_bits),
    .toSie_LC49IE_valid   (vsie_toSie_LC49IE_valid),
    .toSie_LC49IE_bits    (vsie_toSie_LC49IE_bits),
    .toSie_LC50IE_valid   (vsie_toSie_LC50IE_valid),
    .toSie_LC50IE_bits    (vsie_toSie_LC50IE_bits),
    .toSie_LC51IE_valid   (vsie_toSie_LC51IE_valid),
    .toSie_LC51IE_bits    (vsie_toSie_LC51IE_bits),
    .toSie_LC52IE_valid   (vsie_toSie_LC52IE_valid),
    .toSie_LC52IE_bits    (vsie_toSie_LC52IE_bits),
    .toSie_LC53IE_valid   (vsie_toSie_LC53IE_valid),
    .toSie_LC53IE_bits    (vsie_toSie_LC53IE_bits),
    .toSie_LC54IE_valid   (vsie_toSie_LC54IE_valid),
    .toSie_LC54IE_bits    (vsie_toSie_LC54IE_bits),
    .toSie_LC55IE_valid   (vsie_toSie_LC55IE_valid),
    .toSie_LC55IE_bits    (vsie_toSie_LC55IE_bits),
    .toSie_LC56IE_valid   (vsie_toSie_LC56IE_valid),
    .toSie_LC56IE_bits    (vsie_toSie_LC56IE_bits),
    .toSie_LC57IE_valid   (vsie_toSie_LC57IE_valid),
    .toSie_LC57IE_bits    (vsie_toSie_LC57IE_bits),
    .toSie_LC58IE_valid   (vsie_toSie_LC58IE_valid),
    .toSie_LC58IE_bits    (vsie_toSie_LC58IE_bits),
    .toSie_LC59IE_valid   (vsie_toSie_LC59IE_valid),
    .toSie_LC59IE_bits    (vsie_toSie_LC59IE_bits),
    .toSie_LC60IE_valid   (vsie_toSie_LC60IE_valid),
    .toSie_LC60IE_bits    (vsie_toSie_LC60IE_bits),
    .toSie_LC61IE_valid   (vsie_toSie_LC61IE_valid),
    .toSie_LC61IE_bits    (vsie_toSie_LC61IE_bits),
    .toSie_LC62IE_valid   (vsie_toSie_LC62IE_valid),
    .toSie_LC62IE_bits    (vsie_toSie_LC62IE_bits),
    .toSie_LC63IE_valid   (vsie_toSie_LC63IE_valid),
    .toSie_LC63IE_bits    (vsie_toSie_LC63IE_bits)
  );
  VStvecModule vstvec (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_vstvec),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (vstvec_rdata),
    .regOut_mode (vstvec_regOut_mode),
    .regOut_addr (vstvec_regOut_addr)
  );
  VSscratchModule vsscratch (
    .clock      (clock),
    .w_wen      (wen_vsscratch),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (vsscratch_rdata),
    .regOut_ALL (vsscratch_regOut_ALL)
  );
  VSepcModule vsepc (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_vsepc),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (vsepc_rdata),
    .regOut_epc              (vsepc_regOut_epc),
    .trapToVS_vsepc_valid    (trapEntryVSEvent_out_vsepc_valid),
    .trapToVS_vsepc_bits_epc (trapEntryVSEvent_out_vsepc_bits_epc)
  );
  VScauseModule vscause (
    .clock                               (clock),
    .reset                               (reset),
    .w_wen                               (wen_vscause),
    .w_wdata                             (io_in_bits_wdata),
    .rdata                               (vscause_rdata),
    .regOut_Interrupt                    (vscause_regOut_Interrupt),
    .regOut_ExceptionCode                (vscause_regOut_ExceptionCode),
    .trapToVS_vscause_valid              (trapEntryVSEvent_out_vscause_valid),
    .trapToVS_vscause_bits_Interrupt     (trapEntryVSEvent_out_vscause_bits_Interrupt),
    .trapToVS_vscause_bits_ExceptionCode (trapEntryVSEvent_out_vscause_bits_ExceptionCode)
  );
  VStvalModule vstval (
    .clock                    (clock),
    .reset                    (reset),
    .w_wen                    (wen_vstval),
    .w_wdata                  (io_in_bits_wdata),
    .rdata                    (vstval_rdata),
    .regOut_ALL               (vstval_regOut_ALL),
    .trapToVS_vstval_valid    (trapEntryVSEvent_out_vstval_valid),
    .trapToVS_vstval_bits_ALL (trapEntryVSEvent_out_vstval_bits_ALL)
  );
  VSipModule vsip (
    .w_wen                 (wen_vsip),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (vsip_rdata),
    .regOut_SSIP           (vsip_regOut_SSIP),
    .regOut_STIP           (vsip_regOut_STIP),
    .regOut_SEIP           (vsip_regOut_SEIP),
    .regOut_LCOFIP         (vsip_regOut_LCOFIP),
    .regOut_LC14IP         (vsip_regOut_LC14IP),
    .regOut_LC15IP         (vsip_regOut_LC15IP),
    .regOut_LC16IP         (vsip_regOut_LC16IP),
    .regOut_LC17IP         (vsip_regOut_LC17IP),
    .regOut_LC18IP         (vsip_regOut_LC18IP),
    .regOut_LC19IP         (vsip_regOut_LC19IP),
    .regOut_LC20IP         (vsip_regOut_LC20IP),
    .regOut_LC21IP         (vsip_regOut_LC21IP),
    .regOut_LC22IP         (vsip_regOut_LC22IP),
    .regOut_LC23IP         (vsip_regOut_LC23IP),
    .regOut_LC24IP         (vsip_regOut_LC24IP),
    .regOut_LC25IP         (vsip_regOut_LC25IP),
    .regOut_LC26IP         (vsip_regOut_LC26IP),
    .regOut_LC27IP         (vsip_regOut_LC27IP),
    .regOut_LC28IP         (vsip_regOut_LC28IP),
    .regOut_LC29IP         (vsip_regOut_LC29IP),
    .regOut_LC30IP         (vsip_regOut_LC30IP),
    .regOut_LC31IP         (vsip_regOut_LC31IP),
    .regOut_LC32IP         (vsip_regOut_LC32IP),
    .regOut_LC33IP         (vsip_regOut_LC33IP),
    .regOut_LC34IP         (vsip_regOut_LC34IP),
    .regOut_LPRASEIP       (vsip_regOut_LPRASEIP),
    .regOut_LC36IP         (vsip_regOut_LC36IP),
    .regOut_LC37IP         (vsip_regOut_LC37IP),
    .regOut_LC38IP         (vsip_regOut_LC38IP),
    .regOut_LC39IP         (vsip_regOut_LC39IP),
    .regOut_LC40IP         (vsip_regOut_LC40IP),
    .regOut_LC41IP         (vsip_regOut_LC41IP),
    .regOut_LC42IP         (vsip_regOut_LC42IP),
    .regOut_HPRASEIP       (vsip_regOut_HPRASEIP),
    .regOut_LC44IP         (vsip_regOut_LC44IP),
    .regOut_LC45IP         (vsip_regOut_LC45IP),
    .regOut_LC46IP         (vsip_regOut_LC46IP),
    .regOut_LC47IP         (vsip_regOut_LC47IP),
    .regOut_LC48IP         (vsip_regOut_LC48IP),
    .regOut_LC49IP         (vsip_regOut_LC49IP),
    .regOut_LC50IP         (vsip_regOut_LC50IP),
    .regOut_LC51IP         (vsip_regOut_LC51IP),
    .regOut_LC52IP         (vsip_regOut_LC52IP),
    .regOut_LC53IP         (vsip_regOut_LC53IP),
    .regOut_LC54IP         (vsip_regOut_LC54IP),
    .regOut_LC55IP         (vsip_regOut_LC55IP),
    .regOut_LC56IP         (vsip_regOut_LC56IP),
    .regOut_LC57IP         (vsip_regOut_LC57IP),
    .regOut_LC58IP         (vsip_regOut_LC58IP),
    .regOut_LC59IP         (vsip_regOut_LC59IP),
    .regOut_LC60IP         (vsip_regOut_LC60IP),
    .regOut_LC61IP         (vsip_regOut_LC61IP),
    .regOut_LC62IP         (vsip_regOut_LC62IP),
    .regOut_LC63IP         (vsip_regOut_LC63IP),
    .mideleg_SSI           (mideleg_regOut_SSI),
    .mideleg_STI           (mideleg_regOut_STI),
    .mideleg_SEI           (mideleg_regOut_SEI),
    .mideleg_LCOFI         (mideleg_regOut_LCOFI),
    .mip_SSIP              (mip_rdata[1]),
    .mip_VSSIP             (mip_rdata[2]),
    .mip_MSIP              (mip_rdata[3]),
    .mip_STIP              (mip_rdata[5]),
    .mip_VSTIP             (mip_rdata[6]),
    .mip_MTIP              (mip_rdata[7]),
    .mip_SEIP              (mip_rdata[9]),
    .mip_VSEIP             (mip_rdata[10]),
    .mip_MEIP              (mip_rdata[11]),
    .mip_SGEIP             (mip_rdata[12]),
    .mip_LCOFIP            (mip_rdata[13]),
    .mip_LC14IP            (mip_rdata[14]),
    .mip_LC15IP            (mip_rdata[15]),
    .mip_LC16IP            (mip_rdata[16]),
    .mip_LC17IP            (mip_rdata[17]),
    .mip_LC18IP            (mip_rdata[18]),
    .mip_LC19IP            (mip_rdata[19]),
    .mip_LC20IP            (mip_rdata[20]),
    .mip_LC21IP            (mip_rdata[21]),
    .mip_LC22IP            (mip_rdata[22]),
    .mip_LC23IP            (mip_rdata[23]),
    .mip_LC24IP            (mip_rdata[24]),
    .mip_LC25IP            (mip_rdata[25]),
    .mip_LC26IP            (mip_rdata[26]),
    .mip_LC27IP            (mip_rdata[27]),
    .mip_LC28IP            (mip_rdata[28]),
    .mip_LC29IP            (mip_rdata[29]),
    .mip_LC30IP            (mip_rdata[30]),
    .mip_LC31IP            (mip_rdata[31]),
    .mip_LC32IP            (mip_rdata[32]),
    .mip_LC33IP            (mip_rdata[33]),
    .mip_LC34IP            (mip_rdata[34]),
    .mip_LPRASEIP          (mip_rdata[35]),
    .mip_LC36IP            (mip_rdata[36]),
    .mip_LC37IP            (mip_rdata[37]),
    .mip_LC38IP            (mip_rdata[38]),
    .mip_LC39IP            (mip_rdata[39]),
    .mip_LC40IP            (mip_rdata[40]),
    .mip_LC41IP            (mip_rdata[41]),
    .mip_LC42IP            (mip_rdata[42]),
    .mip_HPRASEIP          (mip_rdata[43]),
    .mip_LC44IP            (mip_rdata[44]),
    .mip_LC45IP            (mip_rdata[45]),
    .mip_LC46IP            (mip_rdata[46]),
    .mip_LC47IP            (mip_rdata[47]),
    .mip_LC48IP            (mip_rdata[48]),
    .mip_LC49IP            (mip_rdata[49]),
    .mip_LC50IP            (mip_rdata[50]),
    .mip_LC51IP            (mip_rdata[51]),
    .mip_LC52IP            (mip_rdata[52]),
    .mip_LC53IP            (mip_rdata[53]),
    .mip_LC54IP            (mip_rdata[54]),
    .mip_LC55IP            (mip_rdata[55]),
    .mip_LC56IP            (mip_rdata[56]),
    .mip_LC57IP            (mip_rdata[57]),
    .mip_LC58IP            (mip_rdata[58]),
    .mip_LC59IP            (mip_rdata[59]),
    .mip_LC60IP            (mip_rdata[60]),
    .mip_LC61IP            (mip_rdata[61]),
    .mip_LC62IP            (mip_rdata[62]),
    .mip_LC63IP            (mip_rdata[63]),
    .mvip_SSIP             (mvip_regOut_SSIP),
    .mvip_STIP             (mvip_regOut_STIP),
    .mvip_SEIP             (mvip_regOut_SEIP),
    .mvip_LCOFIP           (mvip_regOut_LCOFIP),
    .mvip_LC14IP           (mvip_regOut_LC14IP),
    .mvip_LC15IP           (mvip_regOut_LC15IP),
    .mvip_LC16IP           (mvip_regOut_LC16IP),
    .mvip_LC17IP           (mvip_regOut_LC17IP),
    .mvip_LC18IP           (mvip_regOut_LC18IP),
    .mvip_LC19IP           (mvip_regOut_LC19IP),
    .mvip_LC20IP           (mvip_regOut_LC20IP),
    .mvip_LC21IP           (mvip_regOut_LC21IP),
    .mvip_LC22IP           (mvip_regOut_LC22IP),
    .mvip_LC23IP           (mvip_regOut_LC23IP),
    .mvip_LC24IP           (mvip_regOut_LC24IP),
    .mvip_LC25IP           (mvip_regOut_LC25IP),
    .mvip_LC26IP           (mvip_regOut_LC26IP),
    .mvip_LC27IP           (mvip_regOut_LC27IP),
    .mvip_LC28IP           (mvip_regOut_LC28IP),
    .mvip_LC29IP           (mvip_regOut_LC29IP),
    .mvip_LC30IP           (mvip_regOut_LC30IP),
    .mvip_LC31IP           (mvip_regOut_LC31IP),
    .mvip_LC32IP           (mvip_regOut_LC32IP),
    .mvip_LC33IP           (mvip_regOut_LC33IP),
    .mvip_LC34IP           (mvip_regOut_LC34IP),
    .mvip_LPRASEIP         (mvip_regOut_LPRASEIP),
    .mvip_LC36IP           (mvip_regOut_LC36IP),
    .mvip_LC37IP           (mvip_regOut_LC37IP),
    .mvip_LC38IP           (mvip_regOut_LC38IP),
    .mvip_LC39IP           (mvip_regOut_LC39IP),
    .mvip_LC40IP           (mvip_regOut_LC40IP),
    .mvip_LC41IP           (mvip_regOut_LC41IP),
    .mvip_LC42IP           (mvip_regOut_LC42IP),
    .mvip_HPRASEIP         (mvip_regOut_HPRASEIP),
    .mvip_LC44IP           (mvip_regOut_LC44IP),
    .mvip_LC45IP           (mvip_regOut_LC45IP),
    .mvip_LC46IP           (mvip_regOut_LC46IP),
    .mvip_LC47IP           (mvip_regOut_LC47IP),
    .mvip_LC48IP           (mvip_regOut_LC48IP),
    .mvip_LC49IP           (mvip_regOut_LC49IP),
    .mvip_LC50IP           (mvip_regOut_LC50IP),
    .mvip_LC51IP           (mvip_regOut_LC51IP),
    .mvip_LC52IP           (mvip_regOut_LC52IP),
    .mvip_LC53IP           (mvip_regOut_LC53IP),
    .mvip_LC54IP           (mvip_regOut_LC54IP),
    .mvip_LC55IP           (mvip_regOut_LC55IP),
    .mvip_LC56IP           (mvip_regOut_LC56IP),
    .mvip_LC57IP           (mvip_regOut_LC57IP),
    .mvip_LC58IP           (mvip_regOut_LC58IP),
    .mvip_LC59IP           (mvip_regOut_LC59IP),
    .mvip_LC60IP           (mvip_regOut_LC60IP),
    .mvip_LC61IP           (mvip_regOut_LC61IP),
    .mvip_LC62IP           (mvip_regOut_LC62IP),
    .mvip_LC63IP           (mvip_regOut_LC63IP),
    .mvien_SSIE            (mvien_regOut_SSIE),
    .mvien_SEIE            (mvien_regOut_SEIE),
    .mvien_LC14IE          (mvien_regOut_LC14IE),
    .mvien_LC15IE          (mvien_regOut_LC15IE),
    .mvien_LC16IE          (mvien_regOut_LC16IE),
    .mvien_LC17IE          (mvien_regOut_LC17IE),
    .mvien_LC18IE          (mvien_regOut_LC18IE),
    .mvien_LC19IE          (mvien_regOut_LC19IE),
    .mvien_LC20IE          (mvien_regOut_LC20IE),
    .mvien_LC21IE          (mvien_regOut_LC21IE),
    .mvien_LC22IE          (mvien_regOut_LC22IE),
    .mvien_LC23IE          (mvien_regOut_LC23IE),
    .mvien_LC24IE          (mvien_regOut_LC24IE),
    .mvien_LC25IE          (mvien_regOut_LC25IE),
    .mvien_LC26IE          (mvien_regOut_LC26IE),
    .mvien_LC27IE          (mvien_regOut_LC27IE),
    .mvien_LC28IE          (mvien_regOut_LC28IE),
    .mvien_LC29IE          (mvien_regOut_LC29IE),
    .mvien_LC30IE          (mvien_regOut_LC30IE),
    .mvien_LC31IE          (mvien_regOut_LC31IE),
    .mvien_LC32IE          (mvien_regOut_LC32IE),
    .mvien_LC33IE          (mvien_regOut_LC33IE),
    .mvien_LC34IE          (mvien_regOut_LC34IE),
    .mvien_LPRASEIE        (mvien_regOut_LPRASEIE),
    .mvien_LC36IE          (mvien_regOut_LC36IE),
    .mvien_LC37IE          (mvien_regOut_LC37IE),
    .mvien_LC38IE          (mvien_regOut_LC38IE),
    .mvien_LC39IE          (mvien_regOut_LC39IE),
    .mvien_LC40IE          (mvien_regOut_LC40IE),
    .mvien_LC41IE          (mvien_regOut_LC41IE),
    .mvien_LC42IE          (mvien_regOut_LC42IE),
    .mvien_HPRASEIE        (mvien_regOut_HPRASEIE),
    .mvien_LC44IE          (mvien_regOut_LC44IE),
    .mvien_LC45IE          (mvien_regOut_LC45IE),
    .mvien_LC46IE          (mvien_regOut_LC46IE),
    .mvien_LC47IE          (mvien_regOut_LC47IE),
    .mvien_LC48IE          (mvien_regOut_LC48IE),
    .mvien_LC49IE          (mvien_regOut_LC49IE),
    .mvien_LC50IE          (mvien_regOut_LC50IE),
    .mvien_LC51IE          (mvien_regOut_LC51IE),
    .mvien_LC52IE          (mvien_regOut_LC52IE),
    .mvien_LC53IE          (mvien_regOut_LC53IE),
    .mvien_LC54IE          (mvien_regOut_LC54IE),
    .mvien_LC55IE          (mvien_regOut_LC55IE),
    .mvien_LC56IE          (mvien_regOut_LC56IE),
    .mvien_LC57IE          (mvien_regOut_LC57IE),
    .mvien_LC58IE          (mvien_regOut_LC58IE),
    .mvien_LC59IE          (mvien_regOut_LC59IE),
    .mvien_LC60IE          (mvien_regOut_LC60IE),
    .mvien_LC61IE          (mvien_regOut_LC61IE),
    .mvien_LC62IE          (mvien_regOut_LC62IE),
    .mvien_LC63IE          (mvien_regOut_LC63IE),
    .hideleg_SSI           (hideleg_regOut_SSI),
    .hideleg_VSSI          (hideleg_regOut_VSSI),
    .hideleg_MSI           (hideleg_regOut_MSI),
    .hideleg_STI           (hideleg_regOut_STI),
    .hideleg_VSTI          (hideleg_regOut_VSTI),
    .hideleg_MTI           (hideleg_regOut_MTI),
    .hideleg_SEI           (hideleg_regOut_SEI),
    .hideleg_VSEI          (hideleg_regOut_VSEI),
    .hideleg_MEI           (hideleg_regOut_MEI),
    .hideleg_SGEI          (hideleg_regOut_SGEI),
    .hideleg_LCOFI         (hideleg_regOut_LCOFI),
    .hvien_LC14IE          (hvien_regOut_LC14IE),
    .hvien_LC15IE          (hvien_regOut_LC15IE),
    .hvien_LC16IE          (hvien_regOut_LC16IE),
    .hvien_LC17IE          (hvien_regOut_LC17IE),
    .hvien_LC18IE          (hvien_regOut_LC18IE),
    .hvien_LC19IE          (hvien_regOut_LC19IE),
    .hvien_LC20IE          (hvien_regOut_LC20IE),
    .hvien_LC21IE          (hvien_regOut_LC21IE),
    .hvien_LC22IE          (hvien_regOut_LC22IE),
    .hvien_LC23IE          (hvien_regOut_LC23IE),
    .hvien_LC24IE          (hvien_regOut_LC24IE),
    .hvien_LC25IE          (hvien_regOut_LC25IE),
    .hvien_LC26IE          (hvien_regOut_LC26IE),
    .hvien_LC27IE          (hvien_regOut_LC27IE),
    .hvien_LC28IE          (hvien_regOut_LC28IE),
    .hvien_LC29IE          (hvien_regOut_LC29IE),
    .hvien_LC30IE          (hvien_regOut_LC30IE),
    .hvien_LC31IE          (hvien_regOut_LC31IE),
    .hvien_LC32IE          (hvien_regOut_LC32IE),
    .hvien_LC33IE          (hvien_regOut_LC33IE),
    .hvien_LC34IE          (hvien_regOut_LC34IE),
    .hvien_LPRASEIE        (hvien_regOut_LPRASEIE),
    .hvien_LC36IE          (hvien_regOut_LC36IE),
    .hvien_LC37IE          (hvien_regOut_LC37IE),
    .hvien_LC38IE          (hvien_regOut_LC38IE),
    .hvien_LC39IE          (hvien_regOut_LC39IE),
    .hvien_LC40IE          (hvien_regOut_LC40IE),
    .hvien_LC41IE          (hvien_regOut_LC41IE),
    .hvien_LC42IE          (hvien_regOut_LC42IE),
    .hvien_HPRASEIE        (hvien_regOut_HPRASEIE),
    .hvien_LC44IE          (hvien_regOut_LC44IE),
    .hvien_LC45IE          (hvien_regOut_LC45IE),
    .hvien_LC46IE          (hvien_regOut_LC46IE),
    .hvien_LC47IE          (hvien_regOut_LC47IE),
    .hvien_LC48IE          (hvien_regOut_LC48IE),
    .hvien_LC49IE          (hvien_regOut_LC49IE),
    .hvien_LC50IE          (hvien_regOut_LC50IE),
    .hvien_LC51IE          (hvien_regOut_LC51IE),
    .hvien_LC52IE          (hvien_regOut_LC52IE),
    .hvien_LC53IE          (hvien_regOut_LC53IE),
    .hvien_LC54IE          (hvien_regOut_LC54IE),
    .hvien_LC55IE          (hvien_regOut_LC55IE),
    .hvien_LC56IE          (hvien_regOut_LC56IE),
    .hvien_LC57IE          (hvien_regOut_LC57IE),
    .hvien_LC58IE          (hvien_regOut_LC58IE),
    .hvien_LC59IE          (hvien_regOut_LC59IE),
    .hvien_LC60IE          (hvien_regOut_LC60IE),
    .hvien_LC61IE          (hvien_regOut_LC61IE),
    .hvien_LC62IE          (hvien_regOut_LC62IE),
    .hvien_LC63IE          (hvien_regOut_LC63IE),
    .hvip_VSSIP            (hvip_regOut_VSSIP),
    .hvip_VSTIP            (hvip_regOut_VSTIP),
    .hvip_VSEIP            (hvip_regOut_VSEIP),
    .hvip_LCOFIP           (hvip_regOut_LCOFIP),
    .hvip_LC14IP           (hvip_regOut_LC14IP),
    .hvip_LC15IP           (hvip_regOut_LC15IP),
    .hvip_LC16IP           (hvip_regOut_LC16IP),
    .hvip_LC17IP           (hvip_regOut_LC17IP),
    .hvip_LC18IP           (hvip_regOut_LC18IP),
    .hvip_LC19IP           (hvip_regOut_LC19IP),
    .hvip_LC20IP           (hvip_regOut_LC20IP),
    .hvip_LC21IP           (hvip_regOut_LC21IP),
    .hvip_LC22IP           (hvip_regOut_LC22IP),
    .hvip_LC23IP           (hvip_regOut_LC23IP),
    .hvip_LC24IP           (hvip_regOut_LC24IP),
    .hvip_LC25IP           (hvip_regOut_LC25IP),
    .hvip_LC26IP           (hvip_regOut_LC26IP),
    .hvip_LC27IP           (hvip_regOut_LC27IP),
    .hvip_LC28IP           (hvip_regOut_LC28IP),
    .hvip_LC29IP           (hvip_regOut_LC29IP),
    .hvip_LC30IP           (hvip_regOut_LC30IP),
    .hvip_LC31IP           (hvip_regOut_LC31IP),
    .hvip_LC32IP           (hvip_regOut_LC32IP),
    .hvip_LC33IP           (hvip_regOut_LC33IP),
    .hvip_LC34IP           (hvip_regOut_LC34IP),
    .hvip_LPRASEIP         (hvip_regOut_LPRASEIP),
    .hvip_LC36IP           (hvip_regOut_LC36IP),
    .hvip_LC37IP           (hvip_regOut_LC37IP),
    .hvip_LC38IP           (hvip_regOut_LC38IP),
    .hvip_LC39IP           (hvip_regOut_LC39IP),
    .hvip_LC40IP           (hvip_regOut_LC40IP),
    .hvip_LC41IP           (hvip_regOut_LC41IP),
    .hvip_LC42IP           (hvip_regOut_LC42IP),
    .hvip_HPRASEIP         (hvip_regOut_HPRASEIP),
    .hvip_LC44IP           (hvip_regOut_LC44IP),
    .hvip_LC45IP           (hvip_regOut_LC45IP),
    .hvip_LC46IP           (hvip_regOut_LC46IP),
    .hvip_LC47IP           (hvip_regOut_LC47IP),
    .hvip_LC48IP           (hvip_regOut_LC48IP),
    .hvip_LC49IP           (hvip_regOut_LC49IP),
    .hvip_LC50IP           (hvip_regOut_LC50IP),
    .hvip_LC51IP           (hvip_regOut_LC51IP),
    .hvip_LC52IP           (hvip_regOut_LC52IP),
    .hvip_LC53IP           (hvip_regOut_LC53IP),
    .hvip_LC54IP           (hvip_regOut_LC54IP),
    .hvip_LC55IP           (hvip_regOut_LC55IP),
    .hvip_LC56IP           (hvip_regOut_LC56IP),
    .hvip_LC57IP           (hvip_regOut_LC57IP),
    .hvip_LC58IP           (hvip_regOut_LC58IP),
    .hvip_LC59IP           (hvip_regOut_LC59IP),
    .hvip_LC60IP           (hvip_regOut_LC60IP),
    .hvip_LC61IP           (hvip_regOut_LC61IP),
    .hvip_LC62IP           (hvip_regOut_LC62IP),
    .hvip_LC63IP           (hvip_regOut_LC63IP),
    .toMip_LCOFIP_valid    (vsip_toMip_LCOFIP_valid),
    .toMip_LCOFIP_bits     (vsip_toMip_LCOFIP_bits),
    .toHvip_VSSIP_valid    (vsip_toHvip_VSSIP_valid),
    .toHvip_VSSIP_bits     (vsip_toHvip_VSSIP_bits),
    .toHvip_LCOFIP_bits    (vsip_toHvip_LCOFIP_bits),
    .toHvip_LC14IP_valid   (vsip_toHvip_LC14IP_valid),
    .toHvip_LC14IP_bits    (vsip_toHvip_LC14IP_bits),
    .toHvip_LC15IP_valid   (vsip_toHvip_LC15IP_valid),
    .toHvip_LC15IP_bits    (vsip_toHvip_LC15IP_bits),
    .toHvip_LC16IP_valid   (vsip_toHvip_LC16IP_valid),
    .toHvip_LC16IP_bits    (vsip_toHvip_LC16IP_bits),
    .toHvip_LC17IP_valid   (vsip_toHvip_LC17IP_valid),
    .toHvip_LC17IP_bits    (vsip_toHvip_LC17IP_bits),
    .toHvip_LC18IP_valid   (vsip_toHvip_LC18IP_valid),
    .toHvip_LC18IP_bits    (vsip_toHvip_LC18IP_bits),
    .toHvip_LC19IP_valid   (vsip_toHvip_LC19IP_valid),
    .toHvip_LC19IP_bits    (vsip_toHvip_LC19IP_bits),
    .toHvip_LC20IP_valid   (vsip_toHvip_LC20IP_valid),
    .toHvip_LC20IP_bits    (vsip_toHvip_LC20IP_bits),
    .toHvip_LC21IP_valid   (vsip_toHvip_LC21IP_valid),
    .toHvip_LC21IP_bits    (vsip_toHvip_LC21IP_bits),
    .toHvip_LC22IP_valid   (vsip_toHvip_LC22IP_valid),
    .toHvip_LC22IP_bits    (vsip_toHvip_LC22IP_bits),
    .toHvip_LC23IP_valid   (vsip_toHvip_LC23IP_valid),
    .toHvip_LC23IP_bits    (vsip_toHvip_LC23IP_bits),
    .toHvip_LC24IP_valid   (vsip_toHvip_LC24IP_valid),
    .toHvip_LC24IP_bits    (vsip_toHvip_LC24IP_bits),
    .toHvip_LC25IP_valid   (vsip_toHvip_LC25IP_valid),
    .toHvip_LC25IP_bits    (vsip_toHvip_LC25IP_bits),
    .toHvip_LC26IP_valid   (vsip_toHvip_LC26IP_valid),
    .toHvip_LC26IP_bits    (vsip_toHvip_LC26IP_bits),
    .toHvip_LC27IP_valid   (vsip_toHvip_LC27IP_valid),
    .toHvip_LC27IP_bits    (vsip_toHvip_LC27IP_bits),
    .toHvip_LC28IP_valid   (vsip_toHvip_LC28IP_valid),
    .toHvip_LC28IP_bits    (vsip_toHvip_LC28IP_bits),
    .toHvip_LC29IP_valid   (vsip_toHvip_LC29IP_valid),
    .toHvip_LC29IP_bits    (vsip_toHvip_LC29IP_bits),
    .toHvip_LC30IP_valid   (vsip_toHvip_LC30IP_valid),
    .toHvip_LC30IP_bits    (vsip_toHvip_LC30IP_bits),
    .toHvip_LC31IP_valid   (vsip_toHvip_LC31IP_valid),
    .toHvip_LC31IP_bits    (vsip_toHvip_LC31IP_bits),
    .toHvip_LC32IP_valid   (vsip_toHvip_LC32IP_valid),
    .toHvip_LC32IP_bits    (vsip_toHvip_LC32IP_bits),
    .toHvip_LC33IP_valid   (vsip_toHvip_LC33IP_valid),
    .toHvip_LC33IP_bits    (vsip_toHvip_LC33IP_bits),
    .toHvip_LC34IP_valid   (vsip_toHvip_LC34IP_valid),
    .toHvip_LC34IP_bits    (vsip_toHvip_LC34IP_bits),
    .toHvip_LPRASEIP_valid (vsip_toHvip_LPRASEIP_valid),
    .toHvip_LPRASEIP_bits  (vsip_toHvip_LPRASEIP_bits),
    .toHvip_LC36IP_valid   (vsip_toHvip_LC36IP_valid),
    .toHvip_LC36IP_bits    (vsip_toHvip_LC36IP_bits),
    .toHvip_LC37IP_valid   (vsip_toHvip_LC37IP_valid),
    .toHvip_LC37IP_bits    (vsip_toHvip_LC37IP_bits),
    .toHvip_LC38IP_valid   (vsip_toHvip_LC38IP_valid),
    .toHvip_LC38IP_bits    (vsip_toHvip_LC38IP_bits),
    .toHvip_LC39IP_valid   (vsip_toHvip_LC39IP_valid),
    .toHvip_LC39IP_bits    (vsip_toHvip_LC39IP_bits),
    .toHvip_LC40IP_valid   (vsip_toHvip_LC40IP_valid),
    .toHvip_LC40IP_bits    (vsip_toHvip_LC40IP_bits),
    .toHvip_LC41IP_valid   (vsip_toHvip_LC41IP_valid),
    .toHvip_LC41IP_bits    (vsip_toHvip_LC41IP_bits),
    .toHvip_LC42IP_valid   (vsip_toHvip_LC42IP_valid),
    .toHvip_LC42IP_bits    (vsip_toHvip_LC42IP_bits),
    .toHvip_HPRASEIP_valid (vsip_toHvip_HPRASEIP_valid),
    .toHvip_HPRASEIP_bits  (vsip_toHvip_HPRASEIP_bits),
    .toHvip_LC44IP_valid   (vsip_toHvip_LC44IP_valid),
    .toHvip_LC44IP_bits    (vsip_toHvip_LC44IP_bits),
    .toHvip_LC45IP_valid   (vsip_toHvip_LC45IP_valid),
    .toHvip_LC45IP_bits    (vsip_toHvip_LC45IP_bits),
    .toHvip_LC46IP_valid   (vsip_toHvip_LC46IP_valid),
    .toHvip_LC46IP_bits    (vsip_toHvip_LC46IP_bits),
    .toHvip_LC47IP_valid   (vsip_toHvip_LC47IP_valid),
    .toHvip_LC47IP_bits    (vsip_toHvip_LC47IP_bits),
    .toHvip_LC48IP_valid   (vsip_toHvip_LC48IP_valid),
    .toHvip_LC48IP_bits    (vsip_toHvip_LC48IP_bits),
    .toHvip_LC49IP_valid   (vsip_toHvip_LC49IP_valid),
    .toHvip_LC49IP_bits    (vsip_toHvip_LC49IP_bits),
    .toHvip_LC50IP_valid   (vsip_toHvip_LC50IP_valid),
    .toHvip_LC50IP_bits    (vsip_toHvip_LC50IP_bits),
    .toHvip_LC51IP_valid   (vsip_toHvip_LC51IP_valid),
    .toHvip_LC51IP_bits    (vsip_toHvip_LC51IP_bits),
    .toHvip_LC52IP_valid   (vsip_toHvip_LC52IP_valid),
    .toHvip_LC52IP_bits    (vsip_toHvip_LC52IP_bits),
    .toHvip_LC53IP_valid   (vsip_toHvip_LC53IP_valid),
    .toHvip_LC53IP_bits    (vsip_toHvip_LC53IP_bits),
    .toHvip_LC54IP_valid   (vsip_toHvip_LC54IP_valid),
    .toHvip_LC54IP_bits    (vsip_toHvip_LC54IP_bits),
    .toHvip_LC55IP_valid   (vsip_toHvip_LC55IP_valid),
    .toHvip_LC55IP_bits    (vsip_toHvip_LC55IP_bits),
    .toHvip_LC56IP_valid   (vsip_toHvip_LC56IP_valid),
    .toHvip_LC56IP_bits    (vsip_toHvip_LC56IP_bits),
    .toHvip_LC57IP_valid   (vsip_toHvip_LC57IP_valid),
    .toHvip_LC57IP_bits    (vsip_toHvip_LC57IP_bits),
    .toHvip_LC58IP_valid   (vsip_toHvip_LC58IP_valid),
    .toHvip_LC58IP_bits    (vsip_toHvip_LC58IP_bits),
    .toHvip_LC59IP_valid   (vsip_toHvip_LC59IP_valid),
    .toHvip_LC59IP_bits    (vsip_toHvip_LC59IP_bits),
    .toHvip_LC60IP_valid   (vsip_toHvip_LC60IP_valid),
    .toHvip_LC60IP_bits    (vsip_toHvip_LC60IP_bits),
    .toHvip_LC61IP_valid   (vsip_toHvip_LC61IP_valid),
    .toHvip_LC61IP_bits    (vsip_toHvip_LC61IP_bits),
    .toHvip_LC62IP_valid   (vsip_toHvip_LC62IP_valid),
    .toHvip_LC62IP_bits    (vsip_toHvip_LC62IP_bits),
    .toHvip_LC63IP_valid   (vsip_toHvip_LC63IP_valid),
    .toHvip_LC63IP_bits    (vsip_toHvip_LC63IP_bits)
  );
  VStimecmpModule vstimecmp (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_vstimecmp),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (vstimecmp_rdata),
    .regOut_vstimecmp (vstimecmp_regOut_vstimecmp)
  );
  VSatpModule vsatp (
    .clock       (clock),
    .reset       (reset),
    .w_wen       (wen_vsatp),
    .w_wdata     (io_in_bits_wdata),
    .rdata       (vsatp_rdata),
    .regOut_MODE (vsatp_regOut_MODE),
    .regOut_ASID (vsatp_regOut_ASID),
    .regOut_PPN  (vsatp_regOut_PPN),
    .v           (virt),
    .hgatp_MODE  (hgatp_regOut_MODE)
  );
  FcsrModule fcsr (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_fcsr),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (fcsr_rdata),
    .robCommit_fflags_valid (fcsr_cmt_fflags_valid_q),
    .robCommit_fflags_bits  (fcsr_cmt_fflags_bits_q),
    .wAliasFflags_wen       (wen_fflags),
    .wAliasFflags_wdata     (io_in_bits_wdata),
    .wAliasFfm_wen          (wen_frm),
    .wAliasFfm_wdata        (io_in_bits_wdata),
    .fflags                 (fcsr_fflags),
    .frm                    (fcsr_frm),
    .fflagsRdata            (fcsr_fflagsRdata),
    .frmRdata               (fcsr_frmRdata)
  );
  VstartModule vstart (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_vstart),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (vstart_rdata),
    .regOut_vstart          (vstart_regOut_vstart),
    .robCommit_vsDirty      (vstart_cmt_vs_dirty_q),
    .robCommit_vstart_valid (vstart_cmt_vstart_valid_q),
    .robCommit_vstart_bits  (vstart_cmt_vstart_bits_q)
  );
  VcsrModule vcsr (
    .clock                 (clock),
    .w_wen                 (wen_vcsr),
    .w_wdata               (io_in_bits_wdata),
    .rdata                 (vcsr_rdata),
    .robCommit_vxsat_valid (vcsr_cmt_vxsat_valid_q),
    .robCommit_vxsat_bits  (vcsr_cmt_vxsat_bits_q),
    .wAliasVxsat_wen       (wen_vxsat),
    .wAliasVxsat_wdata     (io_in_bits_wdata),
    .wAliasVxrm_wen        (wen_vxrm),
    .wAliasVxrm_wdata      (io_in_bits_wdata),
    .vxsat                 (vcsr_vxsat),
    .vxrm                  (vcsr_vxrm)
  );
  VtypeModule vtype (
    .clock                      (clock),
    .reset                      (reset),
    .rdata                      (vtype_rdata),
    .robCommit_vtype_valid      (vtype_cmt_valid_q),
    .robCommit_vtype_bits_VILL  (vtype_cmt_vill_q),
    .robCommit_vtype_bits_VMA   (vtype_cmt_vma_q),
    .robCommit_vtype_bits_VTA   (vtype_cmt_vta_q),
    .robCommit_vtype_bits_VSEW  (vtype_cmt_vsew_q),
    .robCommit_vtype_bits_VLMUL (vtype_cmt_vlmul_q)
  );
  cycleModule cycle (
    .clock              (clock),
    .rdata              (cycle_rdata),
    .mHPM_cycle         (mcycle_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  timeModule time_0 (
    .clock             (clock),
    .reset             (reset),
    .rdata             (time_0_rdata),
    .mHPM_time_valid   (io_fromTop_clintTime_valid),
    .mHPM_time_bits    (io_fromTop_clintTime_bits),
    .v                 (virt),
    .nextV             (next_virt),
    .htimedelta        (htimedelta_rdata),
    .debugModeStopTime (debug_stop_time),
    .updated           (time_0_updated),
    .stime             (time_0_stime),
    .vstime            (time_0_vstime)
  );
  instretModule instret (
    .clock              (clock),
    .rdata              (instret_rdata),
    .mHPM_instret       (minstret_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter3Module hpmcounters_0 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_0_rdata),
    .mHPM_hpmcounters_0 (mhpmcounters_0_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter4Module hpmcounters_1 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_1_rdata),
    .mHPM_hpmcounters_1 (mhpmcounters_1_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter5Module hpmcounters_2 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_2_rdata),
    .mHPM_hpmcounters_2 (mhpmcounters_2_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter6Module hpmcounters_3 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_3_rdata),
    .mHPM_hpmcounters_3 (mhpmcounters_3_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter7Module hpmcounters_4 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_4_rdata),
    .mHPM_hpmcounters_4 (mhpmcounters_4_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter8Module hpmcounters_5 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_5_rdata),
    .mHPM_hpmcounters_5 (mhpmcounters_5_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter9Module hpmcounters_6 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_6_rdata),
    .mHPM_hpmcounters_6 (mhpmcounters_6_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter10Module hpmcounters_7 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_7_rdata),
    .mHPM_hpmcounters_7 (mhpmcounters_7_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter11Module hpmcounters_8 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_8_rdata),
    .mHPM_hpmcounters_8 (mhpmcounters_8_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter12Module hpmcounters_9 (
    .clock              (clock),
    .reset              (reset),
    .rdata              (hpmcounters_9_rdata),
    .mHPM_hpmcounters_9 (mhpmcounters_9_rdata),
    .debugModeStopCount (debug_stop_count_q),
    .unprivCountUpdate  (unpriv_count_update)
  );
  Hpmcounter13Module hpmcounters_10 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_10_rdata),
    .mHPM_hpmcounters_10 (mhpmcounters_10_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter14Module hpmcounters_11 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_11_rdata),
    .mHPM_hpmcounters_11 (mhpmcounters_11_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter15Module hpmcounters_12 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_12_rdata),
    .mHPM_hpmcounters_12 (mhpmcounters_12_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter16Module hpmcounters_13 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_13_rdata),
    .mHPM_hpmcounters_13 (mhpmcounters_13_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter17Module hpmcounters_14 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_14_rdata),
    .mHPM_hpmcounters_14 (mhpmcounters_14_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter18Module hpmcounters_15 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_15_rdata),
    .mHPM_hpmcounters_15 (mhpmcounters_15_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter19Module hpmcounters_16 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_16_rdata),
    .mHPM_hpmcounters_16 (mhpmcounters_16_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter20Module hpmcounters_17 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_17_rdata),
    .mHPM_hpmcounters_17 (mhpmcounters_17_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter21Module hpmcounters_18 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_18_rdata),
    .mHPM_hpmcounters_18 (mhpmcounters_18_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter22Module hpmcounters_19 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_19_rdata),
    .mHPM_hpmcounters_19 (mhpmcounters_19_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter23Module hpmcounters_20 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_20_rdata),
    .mHPM_hpmcounters_20 (mhpmcounters_20_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter24Module hpmcounters_21 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_21_rdata),
    .mHPM_hpmcounters_21 (mhpmcounters_21_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter25Module hpmcounters_22 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_22_rdata),
    .mHPM_hpmcounters_22 (mhpmcounters_22_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter26Module hpmcounters_23 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_23_rdata),
    .mHPM_hpmcounters_23 (mhpmcounters_23_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter27Module hpmcounters_24 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_24_rdata),
    .mHPM_hpmcounters_24 (mhpmcounters_24_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter28Module hpmcounters_25 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_25_rdata),
    .mHPM_hpmcounters_25 (mhpmcounters_25_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter29Module hpmcounters_26 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_26_rdata),
    .mHPM_hpmcounters_26 (mhpmcounters_26_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter30Module hpmcounters_27 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_27_rdata),
    .mHPM_hpmcounters_27 (mhpmcounters_27_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  Hpmcounter31Module hpmcounters_28 (
    .clock               (clock),
    .reset               (reset),
    .rdata               (hpmcounters_28_rdata),
    .mHPM_hpmcounters_28 (mhpmcounters_28_rdata),
    .debugModeStopCount  (debug_stop_count_q),
    .unprivCountUpdate   (unpriv_count_update)
  );
  MiselectModule miselect (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_miselect),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (miselect_rdata),
    .regOut_ALL   (miselect_regOut_ALL),
    .inIMSICRange (miselect_inIMSICRange)
  );
  MiregModule mireg (
    .rdata          (mireg_rdata),
    .regOut_ALL     (mireg_regOut_ALL),
    .iregRead_mireg (mireg_iprio_rdata)
  );
  MtopeiModule mtopei (
    .rdata                 (mtopei_rdata),
    .regOut_IID            (mtopei_regOut_IID),
    .regOut_IPRIO          (mtopei_regOut_IPRIO),
    .aiaToCSR_mtopei_IID   (fromAIA_mtopei_IID),
    .aiaToCSR_mtopei_IPRIO (fromAIA_mtopei_IPRIO)
  );
  MtopiModule mtopi (
    .rdata             (mtopi_rdata),
    .regOut_IID        (mtopi_regOut_IID),
    .topIR_mtopi_IID   (intrMod_io_out_mtopi_IID),
    .topIR_mtopi_IPRIO (intrMod_io_out_mtopi_IPRIO)
  );
  SiselectModule siselect (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_siselect),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (siselect_rdata),
    .regOut_ALL   (siselect_regOut_ALL),
    .inIMSICRange (siselect_inIMSICRange)
  );
  SiregModule sireg (
    .rdata          (sireg_rdata),
    .regOut_ALL     (sireg_regOut_ALL),
    .iregRead_sireg (sireg_iprio_rdata)
  );
  StopeiModule stopei (
    .rdata                 (stopei_rdata),
    .regOut_IID            (stopei_regOut_IID),
    .regOut_IPRIO          (stopei_regOut_IPRIO),
    .aiaToCSR_stopei_IID   (fromAIA_stopei_IID),
    .aiaToCSR_stopei_IPRIO (fromAIA_stopei_IPRIO)
  );
  StopiModule stopi (
    .rdata             (stopi_rdata),
    .regOut_IID        (stopi_regOut_IID),
    .topIR_stopi_IID   (intrMod_io_out_stopi_IID),
    .topIR_stopi_IPRIO (intrMod_io_out_stopi_IPRIO)
  );
  VSiselectModule vsiselect (
    .clock        (clock),
    .reset        (reset),
    .w_wen        (wen_vsiselect),
    .w_wdata      (io_in_bits_wdata),
    .rdata        (vsiselect_rdata),
    .regOut_ALL   (vsiselect_regOut_ALL),
    .inIMSICRange (vsiselect_inIMSICRange)
  );
  VSiregModule vsireg (
    .rdata          (vsireg_rdata),
    .regOut_ALL     (vsireg_regOut_ALL),
    .iregRead_sireg (sireg_iprio_rdata)
  );
  VStopeiModule vstopei (
    .rdata                  (vstopei_rdata),
    .regOut_IID             (vstopei_regOut_IID),
    .regOut_IPRIO           (vstopei_regOut_IPRIO),
    .aiaToCSR_vstopei_IID   (fromAIA_vstopei_IID),
    .aiaToCSR_vstopei_IPRIO (fromAIA_vstopei_IPRIO)
  );
  VStopiModule vstopi (
    .rdata              (vstopi_rdata),
    .regOut_IID         (vstopi_regOut_IID),
    .topIR_vstopi_IID   (intrMod_io_out_vstopi_IID),
    .topIR_vstopi_IPRIO (intrMod_io_out_vstopi_IPRIO)
  );
  Iprio0Module miprio0 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (wen_miprio0),
    .w_wdata (io_in_bits_wdata),
    .rdata   (miprio0_rdata)
  );
  Iprio2Module miprio2 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (wen_miprio2),
    .w_wdata (io_in_bits_wdata),
    .rdata   (miprio2_rdata)
  );
  Iprio0Module_1 siprio0 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprio0),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprio0_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio2Module_1 siprio2 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprio2),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprio2_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio4Module_1 siprios_0 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_0),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_0_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio6Module_1 siprios_1 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_1),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_1_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio8Module_1 siprios_2 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_2),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_2_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio10Module_1 siprios_3 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_3),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_3_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio12Module_1 siprios_4 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_4),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_4_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  Iprio14Module_1 siprios_5 (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (wen_siprios_5),
    .w_wdata        (io_in_bits_wdata),
    .rdata          (siprios_5_rdata),
    .mideleg_SSI    (mideleg_regOut_SSI),
    .mideleg_STI    (mideleg_regOut_STI),
    .mideleg_SEI    (mideleg_regOut_SEI),
    .mideleg_LCOFI  (mideleg_regOut_LCOFI),
    .mvien_SSIE     (mvien_regOut_SSIE),
    .mvien_SEIE     (mvien_regOut_SEIE),
    .mvien_LC14IE   (mvien_regOut_LC14IE),
    .mvien_LC15IE   (mvien_regOut_LC15IE),
    .mvien_LC16IE   (mvien_regOut_LC16IE),
    .mvien_LC17IE   (mvien_regOut_LC17IE),
    .mvien_LC18IE   (mvien_regOut_LC18IE),
    .mvien_LC19IE   (mvien_regOut_LC19IE),
    .mvien_LC20IE   (mvien_regOut_LC20IE),
    .mvien_LC21IE   (mvien_regOut_LC21IE),
    .mvien_LC22IE   (mvien_regOut_LC22IE),
    .mvien_LC23IE   (mvien_regOut_LC23IE),
    .mvien_LC24IE   (mvien_regOut_LC24IE),
    .mvien_LC25IE   (mvien_regOut_LC25IE),
    .mvien_LC26IE   (mvien_regOut_LC26IE),
    .mvien_LC27IE   (mvien_regOut_LC27IE),
    .mvien_LC28IE   (mvien_regOut_LC28IE),
    .mvien_LC29IE   (mvien_regOut_LC29IE),
    .mvien_LC30IE   (mvien_regOut_LC30IE),
    .mvien_LC31IE   (mvien_regOut_LC31IE),
    .mvien_LC32IE   (mvien_regOut_LC32IE),
    .mvien_LC33IE   (mvien_regOut_LC33IE),
    .mvien_LC34IE   (mvien_regOut_LC34IE),
    .mvien_LPRASEIE (mvien_regOut_LPRASEIE),
    .mvien_LC36IE   (mvien_regOut_LC36IE),
    .mvien_LC37IE   (mvien_regOut_LC37IE),
    .mvien_LC38IE   (mvien_regOut_LC38IE),
    .mvien_LC39IE   (mvien_regOut_LC39IE),
    .mvien_LC40IE   (mvien_regOut_LC40IE),
    .mvien_LC41IE   (mvien_regOut_LC41IE),
    .mvien_LC42IE   (mvien_regOut_LC42IE),
    .mvien_HPRASEIE (mvien_regOut_HPRASEIE),
    .mvien_LC44IE   (mvien_regOut_LC44IE),
    .mvien_LC45IE   (mvien_regOut_LC45IE),
    .mvien_LC46IE   (mvien_regOut_LC46IE),
    .mvien_LC47IE   (mvien_regOut_LC47IE),
    .mvien_LC48IE   (mvien_regOut_LC48IE),
    .mvien_LC49IE   (mvien_regOut_LC49IE),
    .mvien_LC50IE   (mvien_regOut_LC50IE),
    .mvien_LC51IE   (mvien_regOut_LC51IE),
    .mvien_LC52IE   (mvien_regOut_LC52IE),
    .mvien_LC53IE   (mvien_regOut_LC53IE),
    .mvien_LC54IE   (mvien_regOut_LC54IE),
    .mvien_LC55IE   (mvien_regOut_LC55IE),
    .mvien_LC56IE   (mvien_regOut_LC56IE),
    .mvien_LC57IE   (mvien_regOut_LC57IE),
    .mvien_LC58IE   (mvien_regOut_LC58IE),
    .mvien_LC59IE   (mvien_regOut_LC59IE),
    .mvien_LC60IE   (mvien_regOut_LC60IE),
    .mvien_LC61IE   (mvien_regOut_LC61IE),
    .mvien_LC62IE   (mvien_regOut_LC62IE),
    .mvien_LC63IE   (mvien_regOut_LC63IE)
  );
  TrapEntryDEventModule trapEntryDEvent (
    .valid                           (entry_debug_mode),
    .in_trapPc                       (io_fromRob_trap_bits_pc),
    .in_fetchMalTval                 (io_fetchMalTval),
    .in_isFetchMalAddr               (io_fromRob_trap_bits_isFetchMalAddr),
    .in_satpFlushFirstFetchFault     (io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .in_iMode_PRVM                   (trap_imode_prvm),
    .in_iMode_V                      (trap_imode_v),
    .in_privState_PRVM               (prvm),
    .in_privState_V                  (virt),
    .in_hgatp_MODE                   (hgatp_regOut_MODE),
    .in_oldSatp_MODE                 (trap_old_satp_mode),
    .in_oldVsatp_MODE                (trap_old_vsatp_mode),
    .in_hasTrap                      (io_fromRob_trap_valid),
    .in_debugMode                    (debug_mode),
    .in_hasDebugIntr                 (debugMod_io_out_hasDebugIntr),
    .in_triggerEnterDebugMode        (debugMod_io_out_triggerEnterDebugMode),
    .in_hasDebugEbreakException      (debugMod_io_out_hasDebugEbreakException),
    .in_hasSingleStep                (debugMod_io_out_hasSingleStep),
    .in_breakPoint                   (debugMod_io_out_breakPoint),
    .in_criticalErrorStateEnterDebug (debugMod_io_out_criticalErrorStateEnterDebug),
    .in_holdDpc                      (hold_dpc),
    .out_privState_valid             (trapEntryDEvent_out_privState_valid),
    .out_privState_bits_PRVM         (trapEntryDEvent_out_privState_bits_PRVM),
    .out_privState_bits_V            (trapEntryDEvent_out_privState_bits_V),
    .out_dcsr_valid                  (trapEntryDEvent_out_dcsr_valid),
    .out_dcsr_bits_DEBUGVER          (),
    .out_dcsr_bits_EXTCAUSE          (),
    .out_dcsr_bits_CETRIG            (),
    .out_dcsr_bits_EBREAKVS          (),
    .out_dcsr_bits_EBREAKVU          (),
    .out_dcsr_bits_EBREAKM           (),
    .out_dcsr_bits_EBREAKS           (),
    .out_dcsr_bits_EBREAKU           (),
    .out_dcsr_bits_STEPIE            (),
    .out_dcsr_bits_STOPCOUNT         (),
    .out_dcsr_bits_STOPTIME          (),
    .out_dcsr_bits_CAUSE             (trapEntryDEvent_out_dcsr_bits_CAUSE),
    .out_dcsr_bits_V                 (trapEntryDEvent_out_dcsr_bits_V),
    .out_dcsr_bits_MPRVEN            (),
    .out_dcsr_bits_NMIP              (),
    .out_dcsr_bits_STEP              (),
    .out_dcsr_bits_PRV               (trapEntryDEvent_out_dcsr_bits_PRV),
    .out_dpc_valid                   (trapEntryDEvent_out_dpc_valid),
    .out_dpc_bits_epc                (trapEntryDEvent_out_dpc_bits_epc),
    .out_targetPc_valid              (trapEntryDEvent_out_targetPc_valid),
    .out_targetPc_bits_pc            (trapEntryDEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF      (trapEntryDEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF      (trapEntryDEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF     (trapEntryDEvent_out_targetPc_bits_raiseIGPF),
    .out_debugMode_valid             (trapEntryDEvent_out_debugMode_valid),
    .out_debugMode_bits              (trapEntryDEvent_out_debugMode_bits),
    .out_debugIntrEnable_valid       (trapEntryDEvent_out_debugIntrEnable_valid),
    .out_debugIntrEnable_bits        (trapEntryDEvent_out_debugIntrEnable_bits)
  );
  TrapEntryMEventModule trapEntryMEvent (
    .valid                            (valid_trapEntryMEvent),
    .in_causeNO_Interrupt             (trapHandleMod_io_out_causeNO_Interrupt),
    .in_causeNO_ExceptionCode         (trapHandleMod_io_out_causeNO_ExceptionCode),
    .in_trapPc                        (io_fromRob_trap_bits_pc),
    .in_trapPcGPA                     (io_fromRob_trap_bits_pcGPA),
    .in_trapInst_valid                (io_trapInst_valid),
    .in_trapInst_bits                 (io_trapInst_bits),
    .in_fetchMalTval                  (io_fetchMalTval),
    .in_isCrossPageIPF                (io_fromRob_trap_bits_crossPageIPFFix),
    .in_isHls                         (io_fromRob_trap_bits_isHls),
    .in_isFetchMalAddr                (io_fromRob_trap_bits_isFetchMalAddr),
    .in_satpFlushFirstFetchFault      (io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .in_isFetchBkpt                   (io_fromRob_trap_bits_isFetchBkpt),
    .in_trapIsForVSnonLeafPTE         (io_fromRob_trap_bits_isForVSnonLeafPTE),
    .in_hasDTExcp                     (trapHandleMod_io_out_hasDTExcp),
    .in_iMode_PRVM                    (trap_imode_prvm),
    .in_iMode_V                       (trap_imode_v),
    .in_dMode_V                       (trap_dmode_v),
    .in_privState_PRVM                (prvm),
    .in_privState_V                   (virt),
    .in_mstatus_MIE                   (mstatus_regOut_MIE),
    .in_pcFromXtvec                   (trapHandleMod_io_out_pcFromXtvec),
    .in_hgatp_MODE                    (hgatp_regOut_MODE),
    .in_oldSatp_MODE                  (trap_old_satp_mode),
    .in_oldVsatp_MODE                 (trap_old_vsatp_mode),
    .in_memExceptionVAddr             (io_fromMem_excpVA),
    .in_memExceptionGPAddr            (io_fromMem_excpGPA),
    .in_memExceptionIsForVSnonLeafPTE (io_fromMem_excpIsForVSnonLeafPTE),
    .out_privState_valid              (trapEntryMEvent_out_privState_valid),
    .out_privState_bits_PRVM          (trapEntryMEvent_out_privState_bits_PRVM),
    .out_privState_bits_V             (trapEntryMEvent_out_privState_bits_V),
    .out_mstatus_valid                (trapEntryMEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE             (),
    .out_mstatus_bits_MIE             (trapEntryMEvent_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE            (),
    .out_mstatus_bits_UBE             (),
    .out_mstatus_bits_MPIE            (trapEntryMEvent_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP             (),
    .out_mstatus_bits_VS              (),
    .out_mstatus_bits_MPP             (trapEntryMEvent_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS              (),
    .out_mstatus_bits_XS              (),
    .out_mstatus_bits_MPRV            (),
    .out_mstatus_bits_SUM             (),
    .out_mstatus_bits_MXR             (),
    .out_mstatus_bits_TVM             (),
    .out_mstatus_bits_TW              (),
    .out_mstatus_bits_TSR             (),
    .out_mstatus_bits_SDT             (),
    .out_mstatus_bits_UXL             (),
    .out_mstatus_bits_SXL             (),
    .out_mstatus_bits_SBE             (),
    .out_mstatus_bits_MBE             (),
    .out_mstatus_bits_GVA             (trapEntryMEvent_out_mstatus_bits_GVA),
    .out_mstatus_bits_MPV             (trapEntryMEvent_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT             (trapEntryMEvent_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD              (),
    .out_mepc_valid                   (trapEntryMEvent_out_mepc_valid),
    .out_mepc_bits_epc                (trapEntryMEvent_out_mepc_bits_epc),
    .out_mcause_valid                 (trapEntryMEvent_out_mcause_valid),
    .out_mcause_bits_Interrupt        (trapEntryMEvent_out_mcause_bits_Interrupt),
    .out_mcause_bits_ExceptionCode    (trapEntryMEvent_out_mcause_bits_ExceptionCode),
    .out_mtval_valid                  (trapEntryMEvent_out_mtval_valid),
    .out_mtval_bits_ALL               (trapEntryMEvent_out_mtval_bits_ALL),
    .out_mtval2_valid                 (trapEntryMEvent_out_mtval2_valid),
    .out_mtval2_bits_ALL              (trapEntryMEvent_out_mtval2_bits_ALL),
    .out_mtinst_valid                 (trapEntryMEvent_out_mtinst_valid),
    .out_mtinst_bits_ALL              (trapEntryMEvent_out_mtinst_bits_ALL),
    .out_targetPc_valid               (trapEntryMEvent_out_targetPc_valid),
    .out_targetPc_bits_pc             (trapEntryMEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF       (trapEntryMEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF       (trapEntryMEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF      (trapEntryMEvent_out_targetPc_bits_raiseIGPF)
  );
  TrapEntryMNEventModule trapEntryMNEvent (
    .valid                          (valid_trapEntryMNEvent),
    .in_causeNO_Interrupt           (trapHandleMod_io_out_causeNO_Interrupt),
    .in_causeNO_ExceptionCode       (trapHandleMod_io_out_causeNO_ExceptionCode),
    .in_trapPc                      (io_fromRob_trap_bits_pc),
    .in_fetchMalTval                (io_fetchMalTval),
    .in_isFetchMalAddr              (io_fromRob_trap_bits_isFetchMalAddr),
    .in_satpFlushFirstFetchFault    (io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .in_iMode_PRVM                  (trap_imode_prvm),
    .in_iMode_V                     (trap_imode_v),
    .in_privState_PRVM              (prvm),
    .in_privState_V                 (virt),
    .in_pcFromXtvec                 (trapHandleMod_io_out_pcFromXtvec),
    .in_hgatp_MODE                  (hgatp_regOut_MODE),
    .in_oldSatp_MODE                (trap_old_satp_mode),
    .in_oldVsatp_MODE               (trap_old_vsatp_mode),
    .out_privState_valid            (trapEntryMNEvent_out_privState_valid),
    .out_privState_bits_PRVM        (trapEntryMNEvent_out_privState_bits_PRVM),
    .out_privState_bits_V           (trapEntryMNEvent_out_privState_bits_V),
    .out_mnstatus_valid             (trapEntryMNEvent_out_mnstatus_valid),
    .out_mnstatus_bits_NMIE         (trapEntryMNEvent_out_mnstatus_bits_NMIE),
    .out_mnstatus_bits_MNPV         (trapEntryMNEvent_out_mnstatus_bits_MNPV),
    .out_mnstatus_bits_MNPELP       (),
    .out_mnstatus_bits_MNPP         (trapEntryMNEvent_out_mnstatus_bits_MNPP),
    .out_mnepc_valid                (trapEntryMNEvent_out_mnepc_valid),
    .out_mnepc_bits_epc             (trapEntryMNEvent_out_mnepc_bits_epc),
    .out_mncause_valid              (trapEntryMNEvent_out_mncause_valid),
    .out_mncause_bits_Interrupt     (trapEntryMNEvent_out_mncause_bits_Interrupt),
    .out_mncause_bits_ExceptionCode (trapEntryMNEvent_out_mncause_bits_ExceptionCode),
    .out_targetPc_valid             (trapEntryMNEvent_out_targetPc_valid),
    .out_targetPc_bits_pc           (trapEntryMNEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF     (trapEntryMNEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF     (trapEntryMNEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF    (trapEntryMNEvent_out_targetPc_bits_raiseIGPF)
  );
  TrapEntryHSEventModule trapEntryHSEvent (
    .valid                            (valid_trapEntryHSEvent),
    .in_causeNO_Interrupt             (trapHandleMod_io_out_causeNO_Interrupt),
    .in_causeNO_ExceptionCode         (trapHandleMod_io_out_causeNO_ExceptionCode),
    .in_trapPc                        (io_fromRob_trap_bits_pc),
    .in_trapPcGPA                     (io_fromRob_trap_bits_pcGPA),
    .in_trapInst_valid                (io_trapInst_valid),
    .in_trapInst_bits                 (io_trapInst_bits),
    .in_fetchMalTval                  (io_fetchMalTval),
    .in_isCrossPageIPF                (io_fromRob_trap_bits_crossPageIPFFix),
    .in_isHls                         (io_fromRob_trap_bits_isHls),
    .in_isFetchMalAddr                (io_fromRob_trap_bits_isFetchMalAddr),
    .in_satpFlushFirstFetchFault      (io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .in_isFetchBkpt                   (io_fromRob_trap_bits_isFetchBkpt),
    .in_trapIsForVSnonLeafPTE         (io_fromRob_trap_bits_isForVSnonLeafPTE),
    .in_iMode_PRVM                    (trap_imode_prvm),
    .in_iMode_V                       (trap_imode_v),
    .in_dMode_V                       (trap_dmode_v),
    .in_privState_PRVM                (prvm),
    .in_privState_V                   (virt),
    .in_hstatus_SPVP                  (hstatus_regOut_SPVP),
    .in_sstatus_SIE                   (mstatus_sstatus_SIE),
    .in_menvcfg_DTE                   (menvcfg_regOut_DTE),
    .in_pcFromXtvec                   (trapHandleMod_io_out_pcFromXtvec),
    .in_satp_MODE                     (satp_regOut_MODE),
    .in_hgatp_MODE                    (hgatp_regOut_MODE),
    .in_oldSatp_MODE                  (trap_old_satp_mode),
    .in_oldVsatp_MODE                 (trap_old_vsatp_mode),
    .in_memExceptionVAddr             (io_fromMem_excpVA),
    .in_memExceptionGPAddr            (io_fromMem_excpGPA),
    .in_memExceptionIsForVSnonLeafPTE (io_fromMem_excpIsForVSnonLeafPTE),
    .out_privState_valid              (trapEntryHSEvent_out_privState_valid),
    .out_privState_bits_PRVM          (trapEntryHSEvent_out_privState_bits_PRVM),
    .out_privState_bits_V             (trapEntryHSEvent_out_privState_bits_V),
    .out_mstatus_valid                (trapEntryHSEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE             (trapEntryHSEvent_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE             (),
    .out_mstatus_bits_SPIE            (trapEntryHSEvent_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE             (),
    .out_mstatus_bits_MPIE            (),
    .out_mstatus_bits_SPP             (trapEntryHSEvent_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS              (),
    .out_mstatus_bits_MPP             (),
    .out_mstatus_bits_FS              (),
    .out_mstatus_bits_XS              (),
    .out_mstatus_bits_MPRV            (),
    .out_mstatus_bits_SUM             (),
    .out_mstatus_bits_MXR             (),
    .out_mstatus_bits_TVM             (),
    .out_mstatus_bits_TW              (),
    .out_mstatus_bits_TSR             (),
    .out_mstatus_bits_SDT             (trapEntryHSEvent_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL             (),
    .out_mstatus_bits_SXL             (),
    .out_mstatus_bits_SBE             (),
    .out_mstatus_bits_MBE             (),
    .out_mstatus_bits_GVA             (),
    .out_mstatus_bits_MPV             (),
    .out_mstatus_bits_MDT             (),
    .out_mstatus_bits_SD              (),
    .out_hstatus_valid                (trapEntryHSEvent_out_hstatus_valid),
    .out_hstatus_bits_VSBE            (),
    .out_hstatus_bits_GVA             (trapEntryHSEvent_out_hstatus_bits_GVA),
    .out_hstatus_bits_SPV             (trapEntryHSEvent_out_hstatus_bits_SPV),
    .out_hstatus_bits_SPVP            (trapEntryHSEvent_out_hstatus_bits_SPVP),
    .out_hstatus_bits_HU              (),
    .out_hstatus_bits_VGEIN           (),
    .out_hstatus_bits_VTVM            (),
    .out_hstatus_bits_VTW             (),
    .out_hstatus_bits_VTSR            (),
    .out_hstatus_bits_VSXL            (),
    .out_hstatus_bits_HUPMM           (),
    .out_sepc_valid                   (trapEntryHSEvent_out_sepc_valid),
    .out_sepc_bits_epc                (trapEntryHSEvent_out_sepc_bits_epc),
    .out_scause_valid                 (trapEntryHSEvent_out_scause_valid),
    .out_scause_bits_Interrupt        (trapEntryHSEvent_out_scause_bits_Interrupt),
    .out_scause_bits_ExceptionCode    (trapEntryHSEvent_out_scause_bits_ExceptionCode),
    .out_stval_valid                  (trapEntryHSEvent_out_stval_valid),
    .out_stval_bits_ALL               (trapEntryHSEvent_out_stval_bits_ALL),
    .out_htval_valid                  (trapEntryHSEvent_out_htval_valid),
    .out_htval_bits_ALL               (trapEntryHSEvent_out_htval_bits_ALL),
    .out_htinst_valid                 (trapEntryHSEvent_out_htinst_valid),
    .out_htinst_bits_ALL              (trapEntryHSEvent_out_htinst_bits_ALL),
    .out_targetPc_valid               (trapEntryHSEvent_out_targetPc_valid),
    .out_targetPc_bits_pc             (trapEntryHSEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF       (trapEntryHSEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF       (trapEntryHSEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF      (trapEntryHSEvent_out_targetPc_bits_raiseIGPF)
  );
  TrapEntryVSEventModule trapEntryVSEvent (
    .clock                             (clock),
    .reset                             (reset),
    .valid                             (valid_trapEntryVSEvent),
    .in_causeNO_Interrupt              (trapHandleMod_io_out_causeNO_Interrupt),
    .in_causeNO_ExceptionCode          (trapHandleMod_io_out_causeNO_ExceptionCode),
    .in_trapPc                         (io_fromRob_trap_bits_pc),
    .in_trapInst_valid                 (io_trapInst_valid),
    .in_trapInst_bits                  (io_trapInst_bits),
    .in_fetchMalTval                   (io_fetchMalTval),
    .in_isCrossPageIPF                 (io_fromRob_trap_bits_crossPageIPFFix),
    .in_isFetchMalAddr                 (io_fromRob_trap_bits_isFetchMalAddr),
    .in_satpFlushFirstFetchFault       (io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .in_isFetchBkpt                    (io_fromRob_trap_bits_isFetchBkpt),
    .in_iMode_PRVM                     (trap_imode_prvm),
    .in_iMode_V                        (trap_imode_v),
    .in_dMode_V                        (trap_dmode_v),
    .in_privState_PRVM                 (prvm),
    .in_privState_V                    (virt),
    .in_vsstatus_SIE                   (vsstatus_regOut_SIE),
    .in_henvcfg_DTE                    (henvcfg_regOut_DTE),
    .in_pcFromXtvec                    (trapHandleMod_io_out_pcFromXtvec),
    .in_vsatp_MODE                     (vsatp_regOut_MODE),
    .in_hgatp_MODE                     (hgatp_regOut_MODE),
    .in_oldSatp_MODE                   (trap_old_satp_mode),
    .in_oldVsatp_MODE                  (trap_old_vsatp_mode),
    .in_memExceptionVAddr              (io_fromMem_excpVA),
    .in_virtualInterruptIsHvictlInject (intrMod_io_out_virtualInterruptIsHvictlInject),
    .in_hvictlIID                      (hvictl_regOut_IID),
    .out_privState_valid               (trapEntryVSEvent_out_privState_valid),
    .out_privState_bits_PRVM           (trapEntryVSEvent_out_privState_bits_PRVM),
    .out_privState_bits_V              (trapEntryVSEvent_out_privState_bits_V),
    .out_vsstatus_valid                (trapEntryVSEvent_out_vsstatus_valid),
    .out_vsstatus_bits_SIE             (trapEntryVSEvent_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE            (trapEntryVSEvent_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE             (),
    .out_vsstatus_bits_SPP             (trapEntryVSEvent_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS              (),
    .out_vsstatus_bits_FS              (),
    .out_vsstatus_bits_XS              (),
    .out_vsstatus_bits_SUM             (),
    .out_vsstatus_bits_MXR             (),
    .out_vsstatus_bits_SDT             (trapEntryVSEvent_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL             (),
    .out_vsstatus_bits_SD              (),
    .out_vsepc_valid                   (trapEntryVSEvent_out_vsepc_valid),
    .out_vsepc_bits_epc                (trapEntryVSEvent_out_vsepc_bits_epc),
    .out_vscause_valid                 (trapEntryVSEvent_out_vscause_valid),
    .out_vscause_bits_Interrupt        (trapEntryVSEvent_out_vscause_bits_Interrupt),
    .out_vscause_bits_ExceptionCode    (trapEntryVSEvent_out_vscause_bits_ExceptionCode),
    .out_vstval_valid                  (trapEntryVSEvent_out_vstval_valid),
    .out_vstval_bits_ALL               (trapEntryVSEvent_out_vstval_bits_ALL),
    .out_targetPc_valid                (trapEntryVSEvent_out_targetPc_valid),
    .out_targetPc_bits_pc              (trapEntryVSEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF        (trapEntryVSEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF        (trapEntryVSEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF       (trapEntryVSEvent_out_targetPc_bits_raiseIGPF)
  );
  MretEventModule mretEvent (
    .valid                       (permitMod_io_out_hasLegalMret),
    .in_mstatus_MPIE             (mstatus_regOut_MPIE),
    .in_mstatus_MPP              (mstatus_regOut_MPP),
    .in_mstatus_MPRV             (mstatus_regOut_MPRV),
    .in_mstatus_SDT              (mstatus_regOut_SDT),
    .in_mstatus_MPV              (mstatus_regOut_MPV),
    .in_vsstatus_SDT             (vsstatus_regOut_SDT),
    .in_mepc_epc                 (mepc_regOut_epc),
    .in_satp_MODE                (satp_regOut_MODE),
    .in_vsatp_MODE               (vsatp_regOut_MODE),
    .in_hgatp_MODE               (hgatp_regOut_MODE),
    .out_privState_valid         (mretEvent_out_privState_valid),
    .out_privState_bits_PRVM     (mretEvent_out_privState_bits_PRVM),
    .out_privState_bits_V        (mretEvent_out_privState_bits_V),
    .out_mstatus_valid           (mretEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE        (),
    .out_mstatus_bits_MIE        (mretEvent_out_mstatus_bits_MIE),
    .out_mstatus_bits_SPIE       (),
    .out_mstatus_bits_UBE        (),
    .out_mstatus_bits_MPIE       (mretEvent_out_mstatus_bits_MPIE),
    .out_mstatus_bits_SPP        (),
    .out_mstatus_bits_VS         (),
    .out_mstatus_bits_MPP        (mretEvent_out_mstatus_bits_MPP),
    .out_mstatus_bits_FS         (),
    .out_mstatus_bits_XS         (),
    .out_mstatus_bits_MPRV       (mretEvent_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM        (),
    .out_mstatus_bits_MXR        (),
    .out_mstatus_bits_TVM        (),
    .out_mstatus_bits_TW         (),
    .out_mstatus_bits_TSR        (),
    .out_mstatus_bits_SDT        (mretEvent_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL        (),
    .out_mstatus_bits_SXL        (),
    .out_mstatus_bits_SBE        (),
    .out_mstatus_bits_MBE        (),
    .out_mstatus_bits_GVA        (),
    .out_mstatus_bits_MPV        (mretEvent_out_mstatus_bits_MPV),
    .out_mstatus_bits_MDT        (mretEvent_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD         (),
    .out_vsstatus_valid          (mretEvent_out_vsstatus_valid),
    .out_vsstatus_bits_SIE       (),
    .out_vsstatus_bits_SPIE      (),
    .out_vsstatus_bits_UBE       (),
    .out_vsstatus_bits_SPP       (),
    .out_vsstatus_bits_VS        (),
    .out_vsstatus_bits_FS        (),
    .out_vsstatus_bits_XS        (),
    .out_vsstatus_bits_SUM       (),
    .out_vsstatus_bits_MXR       (),
    .out_vsstatus_bits_SDT       (mretEvent_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL       (),
    .out_vsstatus_bits_SD        (),
    .out_targetPc_valid          (mretEvent_out_targetPc_valid),
    .out_targetPc_bits_pc        (mretEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF  (mretEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF  (mretEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF (mretEvent_out_targetPc_bits_raiseIGPF)
  );
  MNretEventModule mnretEvent (
    .valid                       (permitMod_io_out_hasLegalMNret),
    .in_mnstatus_MNPV            (mnstatus_regOut_MNPV),
    .in_mnstatus_MNPP            (mnstatus_regOut_MNPP),
    .in_mstatus_MPRV             (mstatus_regOut_MPRV),
    .in_mstatus_SDT              (mstatus_regOut_SDT),
    .in_mstatus_MDT              (mstatus_regOut_MDT),
    .in_mnepc_epc                (mnepc_regOut_epc),
    .in_satp_MODE                (satp_regOut_MODE),
    .in_vsatp_MODE               (vsatp_regOut_MODE),
    .in_hgatp_MODE               (hgatp_regOut_MODE),
    .in_vsstatus_SDT             (vsstatus_regOut_SDT),
    .out_privState_valid         (mnretEvent_out_privState_valid),
    .out_privState_bits_PRVM     (mnretEvent_out_privState_bits_PRVM),
    .out_privState_bits_V        (mnretEvent_out_privState_bits_V),
    .out_mnstatus_valid          (mnretEvent_out_mnstatus_valid),
    .out_mnstatus_bits_NMIE      (mnretEvent_out_mnstatus_bits_NMIE),
    .out_mnstatus_bits_MNPV      (),
    .out_mnstatus_bits_MNPELP    (),
    .out_mnstatus_bits_MNPP      (),
    .out_mstatus_valid           (mnretEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE        (),
    .out_mstatus_bits_MIE        (),
    .out_mstatus_bits_SPIE       (),
    .out_mstatus_bits_UBE        (),
    .out_mstatus_bits_MPIE       (),
    .out_mstatus_bits_SPP        (),
    .out_mstatus_bits_VS         (),
    .out_mstatus_bits_MPP        (),
    .out_mstatus_bits_FS         (),
    .out_mstatus_bits_XS         (),
    .out_mstatus_bits_MPRV       (mnretEvent_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM        (),
    .out_mstatus_bits_MXR        (),
    .out_mstatus_bits_TVM        (),
    .out_mstatus_bits_TW         (),
    .out_mstatus_bits_TSR        (),
    .out_mstatus_bits_SDT        (mnretEvent_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL        (),
    .out_mstatus_bits_SXL        (),
    .out_mstatus_bits_SBE        (),
    .out_mstatus_bits_MBE        (),
    .out_mstatus_bits_GVA        (),
    .out_mstatus_bits_MPV        (),
    .out_mstatus_bits_MDT        (mnretEvent_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD         (),
    .out_vsstatus_valid          (mnretEvent_out_vsstatus_valid),
    .out_vsstatus_bits_SIE       (),
    .out_vsstatus_bits_SPIE      (),
    .out_vsstatus_bits_UBE       (),
    .out_vsstatus_bits_SPP       (),
    .out_vsstatus_bits_VS        (),
    .out_vsstatus_bits_FS        (),
    .out_vsstatus_bits_XS        (),
    .out_vsstatus_bits_SUM       (),
    .out_vsstatus_bits_MXR       (),
    .out_vsstatus_bits_SDT       (mnretEvent_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL       (),
    .out_vsstatus_bits_SD        (),
    .out_targetPc_valid          (mnretEvent_out_targetPc_valid),
    .out_targetPc_bits_pc        (mnretEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF  (mnretEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF  (mnretEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF (mnretEvent_out_targetPc_bits_raiseIGPF)
  );
  SretEventModule sretEvent (
    .valid                       (permitMod_io_out_hasLegalSret),
    .in_privState_PRVM           (prvm),
    .in_privState_V              (virt),
    .in_mstatus_SPIE             (mstatus_regOut_SPIE),
    .in_mstatus_SPP              (mstatus_regOut_SPP),
    .in_mstatus_SDT              (mstatus_regOut_SDT),
    .in_mstatus_MDT              (mstatus_regOut_MDT),
    .in_hstatus_SPV              (hstatus_regOut_SPV),
    .in_vsstatus_SPIE            (vsstatus_regOut_SPIE),
    .in_vsstatus_SPP             (vsstatus_regOut_SPP),
    .in_sepc_epc                 (sepc_regOut_epc),
    .in_vsepc_epc                (vsepc_regOut_epc),
    .in_satp_MODE                (satp_regOut_MODE),
    .in_vsatp_MODE               (vsatp_regOut_MODE),
    .in_hgatp_MODE               (hgatp_regOut_MODE),
    .out_privState_valid         (sretEvent_out_privState_valid),
    .out_privState_bits_PRVM     (sretEvent_out_privState_bits_PRVM),
    .out_privState_bits_V        (sretEvent_out_privState_bits_V),
    .out_mstatus_valid           (sretEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE        (sretEvent_out_mstatus_bits_SIE),
    .out_mstatus_bits_MIE        (),
    .out_mstatus_bits_SPIE       (sretEvent_out_mstatus_bits_SPIE),
    .out_mstatus_bits_UBE        (),
    .out_mstatus_bits_MPIE       (),
    .out_mstatus_bits_SPP        (sretEvent_out_mstatus_bits_SPP),
    .out_mstatus_bits_VS         (),
    .out_mstatus_bits_MPP        (),
    .out_mstatus_bits_FS         (),
    .out_mstatus_bits_XS         (),
    .out_mstatus_bits_MPRV       (sretEvent_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM        (),
    .out_mstatus_bits_MXR        (),
    .out_mstatus_bits_TVM        (),
    .out_mstatus_bits_TW         (),
    .out_mstatus_bits_TSR        (),
    .out_mstatus_bits_SDT        (sretEvent_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL        (),
    .out_mstatus_bits_SXL        (),
    .out_mstatus_bits_SBE        (),
    .out_mstatus_bits_MBE        (),
    .out_mstatus_bits_GVA        (),
    .out_mstatus_bits_MPV        (),
    .out_mstatus_bits_MDT        (sretEvent_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD         (),
    .out_hstatus_valid           (sretEvent_out_hstatus_valid),
    .out_hstatus_bits_VSBE       (),
    .out_hstatus_bits_GVA        (),
    .out_hstatus_bits_SPV        (sretEvent_out_hstatus_bits_SPV),
    .out_hstatus_bits_SPVP       (),
    .out_hstatus_bits_HU         (),
    .out_hstatus_bits_VGEIN      (),
    .out_hstatus_bits_VTVM       (),
    .out_hstatus_bits_VTW        (),
    .out_hstatus_bits_VTSR       (),
    .out_hstatus_bits_VSXL       (),
    .out_hstatus_bits_HUPMM      (),
    .out_vsstatus_valid          (sretEvent_out_vsstatus_valid),
    .out_vsstatus_bits_SIE       (sretEvent_out_vsstatus_bits_SIE),
    .out_vsstatus_bits_SPIE      (sretEvent_out_vsstatus_bits_SPIE),
    .out_vsstatus_bits_UBE       (),
    .out_vsstatus_bits_SPP       (sretEvent_out_vsstatus_bits_SPP),
    .out_vsstatus_bits_VS        (),
    .out_vsstatus_bits_FS        (),
    .out_vsstatus_bits_XS        (),
    .out_vsstatus_bits_SUM       (),
    .out_vsstatus_bits_MXR       (),
    .out_vsstatus_bits_SDT       (),
    .out_vsstatus_bits_UXL       (),
    .out_vsstatus_bits_SD        (),
    .out_targetPc_valid          (sretEvent_out_targetPc_valid),
    .out_targetPc_bits_pc        (sretEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF  (sretEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF  (sretEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF (sretEvent_out_targetPc_bits_raiseIGPF),
    .outSDT_vsstatus_valid       (sretEvent_outSDT_vsstatus_valid)
  );
  DretEventModule dretEvent (
    .valid                       (permitMod_io_out_hasLegalDret),
    .in_dcsr_V                   (dcsr_regOut_V),
    .in_dcsr_PRV                 (dcsr_regOut_PRV),
    .in_dpc_epc                  (dpc_regOut_epc),
    .in_mstatus_MPRV             (mstatus_regOut_MPRV),
    .in_mstatus_SDT              (mstatus_regOut_SDT),
    .in_mstatus_MDT              (mstatus_regOut_MDT),
    .in_vsstatus_SDT             (vsstatus_regOut_SDT),
    .in_satp_MODE                (satp_regOut_MODE),
    .in_vsatp_MODE               (vsatp_regOut_MODE),
    .in_hgatp_MODE               (hgatp_regOut_MODE),
    .out_privState_valid         (dretEvent_out_privState_valid),
    .out_privState_bits_PRVM     (dretEvent_out_privState_bits_PRVM),
    .out_privState_bits_V        (dretEvent_out_privState_bits_V),
    .out_dcsr_valid              (dretEvent_out_dcsr_valid),
    .out_dcsr_bits_DEBUGVER      (),
    .out_dcsr_bits_EXTCAUSE      (),
    .out_dcsr_bits_CETRIG        (),
    .out_dcsr_bits_EBREAKVS      (),
    .out_dcsr_bits_EBREAKVU      (),
    .out_dcsr_bits_EBREAKM       (),
    .out_dcsr_bits_EBREAKS       (),
    .out_dcsr_bits_EBREAKU       (),
    .out_dcsr_bits_STEPIE        (),
    .out_dcsr_bits_STOPCOUNT     (),
    .out_dcsr_bits_STOPTIME      (),
    .out_dcsr_bits_CAUSE         (),
    .out_dcsr_bits_V             (dretEvent_out_dcsr_bits_V),
    .out_dcsr_bits_MPRVEN        (),
    .out_dcsr_bits_NMIP          (),
    .out_dcsr_bits_STEP          (),
    .out_dcsr_bits_PRV           (dretEvent_out_dcsr_bits_PRV),
    .out_mstatus_valid           (dretEvent_out_mstatus_valid),
    .out_mstatus_bits_SIE        (),
    .out_mstatus_bits_MIE        (),
    .out_mstatus_bits_SPIE       (),
    .out_mstatus_bits_UBE        (),
    .out_mstatus_bits_MPIE       (),
    .out_mstatus_bits_SPP        (),
    .out_mstatus_bits_VS         (),
    .out_mstatus_bits_MPP        (),
    .out_mstatus_bits_FS         (),
    .out_mstatus_bits_XS         (),
    .out_mstatus_bits_MPRV       (dretEvent_out_mstatus_bits_MPRV),
    .out_mstatus_bits_SUM        (),
    .out_mstatus_bits_MXR        (),
    .out_mstatus_bits_TVM        (),
    .out_mstatus_bits_TW         (),
    .out_mstatus_bits_TSR        (),
    .out_mstatus_bits_SDT        (dretEvent_out_mstatus_bits_SDT),
    .out_mstatus_bits_UXL        (),
    .out_mstatus_bits_SXL        (),
    .out_mstatus_bits_SBE        (),
    .out_mstatus_bits_MBE        (),
    .out_mstatus_bits_GVA        (),
    .out_mstatus_bits_MPV        (),
    .out_mstatus_bits_MDT        (dretEvent_out_mstatus_bits_MDT),
    .out_mstatus_bits_SD         (),
    .out_vsstatus_valid          (dretEvent_out_vsstatus_valid),
    .out_vsstatus_bits_SIE       (),
    .out_vsstatus_bits_SPIE      (),
    .out_vsstatus_bits_UBE       (),
    .out_vsstatus_bits_SPP       (),
    .out_vsstatus_bits_VS        (),
    .out_vsstatus_bits_FS        (),
    .out_vsstatus_bits_XS        (),
    .out_vsstatus_bits_SUM       (),
    .out_vsstatus_bits_MXR       (),
    .out_vsstatus_bits_SDT       (dretEvent_out_vsstatus_bits_SDT),
    .out_vsstatus_bits_UXL       (),
    .out_vsstatus_bits_SD        (),
    .out_debugMode_valid         (dretEvent_out_debugMode_valid),
    .out_debugMode_bits          (dretEvent_out_debugMode_bits),
    .out_debugIntrEnable_valid   (dretEvent_out_debugIntrEnable_valid),
    .out_debugIntrEnable_bits    (dretEvent_out_debugIntrEnable_bits),
    .out_targetPc_valid          (dretEvent_out_targetPc_valid),
    .out_targetPc_bits_pc        (dretEvent_out_targetPc_bits_pc),
    .out_targetPc_bits_raiseIPF  (dretEvent_out_targetPc_bits_raiseIPF),
    .out_targetPc_bits_raiseIAF  (dretEvent_out_targetPc_bits_raiseIAF),
    .out_targetPc_bits_raiseIGPF (dretEvent_out_targetPc_bits_raiseIGPF)
  );
  TselectModule tselect (
    .clock      (clock),
    .reset      (reset),
    .w_wen      (wen_tselect),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (tselect_rdata),
    .regOut_ALL (tselect_regOut_ALL)
  );
  Tdata1Module tdata1 (
    .rdata            (tdata1_rdata),
    .regOut_TYPE      (tdata1_regOut_TYPE),
    .regOut_DMODE     (tdata1_regOut_DMODE),
    .regOut_DATA      (tdata1_regOut_DATA),
    .tdataRead_tdata1 (tdata1_selected_rdata)
  );
  Tdata2Module tdata2 (
    .rdata            (tdata2_rdata),
    .regOut_ALL       (tdata2_regOut_ALL),
    .tdataRead_tdata2 (tdata2_selected_rdata)
  );
  Trigger0_Tdata1Module tdata1RegVec_0 (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_tdata1RegVec_0),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (tdata1RegVec_0_rdata),
    .canWriteDmode    (debug_mode),
    .chainable        (debugMod_io_out_newTriggerChainIsLegal),
    .dmodeNextTrigger (trigger_dmode_next_0)
  );
  Trigger1_Tdata1Module tdata1RegVec_1 (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_tdata1RegVec_1),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (tdata1RegVec_1_rdata),
    .canWriteDmode    (trigger_can_write_dmode_1),
    .chainable        (debugMod_io_out_newTriggerChainIsLegal),
    .dmodeNextTrigger (trigger_dmode_next_1)
  );
  Trigger2_Tdata1Module tdata1RegVec_2 (
    .clock            (clock),
    .reset            (reset),
    .w_wen            (wen_tdata1RegVec_2),
    .w_wdata          (io_in_bits_wdata),
    .rdata            (tdata1RegVec_2_rdata),
    .canWriteDmode    (trigger_can_write_dmode_2),
    .chainable        (debugMod_io_out_newTriggerChainIsLegal),
    .dmodeNextTrigger (trigger_dmode_next_2)
  );
  Trigger3_Tdata1Module tdata1RegVec_3 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_tdata1RegVec_3),
    .w_wdata       (io_in_bits_wdata),
    .rdata         (tdata1RegVec_3_rdata),
    .canWriteDmode (trigger_can_write_dmode_3),
    .chainable     (debugMod_io_out_newTriggerChainIsLegal)
  );
  Trigger0_Tdata2Module tdata2RegVec_0 (
    .clock   (clock),
    .w_wen   (wen_tdata2RegVec_0),
    .w_wdata (io_in_bits_wdata),
    .rdata   (tdata2RegVec_0_rdata)
  );
  Trigger1_Tdata2Module tdata2RegVec_1 (
    .clock   (clock),
    .w_wen   (wen_tdata2RegVec_1),
    .w_wdata (io_in_bits_wdata),
    .rdata   (tdata2RegVec_1_rdata)
  );
  Trigger2_Tdata2Module tdata2RegVec_2 (
    .clock   (clock),
    .w_wen   (wen_tdata2RegVec_2),
    .w_wdata (io_in_bits_wdata),
    .rdata   (tdata2RegVec_2_rdata)
  );
  Trigger3_Tdata2Module tdata2RegVec_3 (
    .clock   (clock),
    .w_wen   (wen_tdata2RegVec_3),
    .w_wdata (io_in_bits_wdata),
    .rdata   (tdata2RegVec_3_rdata)
  );
  DcsrModule dcsr (
    .clock                   (clock),
    .reset                   (reset),
    .w_wen                   (wen_dcsr),
    .w_wdata                 (io_in_bits_wdata),
    .rdata                   (dcsr_rdata),
    .regOut_CETRIG           (dcsr_regOut_CETRIG),
    .regOut_EBREAKVS         (dcsr_regOut_EBREAKVS),
    .regOut_EBREAKVU         (dcsr_regOut_EBREAKVU),
    .regOut_EBREAKM          (dcsr_regOut_EBREAKM),
    .regOut_EBREAKS          (dcsr_regOut_EBREAKS),
    .regOut_EBREAKU          (dcsr_regOut_EBREAKU),
    .regOut_STEPIE           (dcsr_regOut_STEPIE),
    .regOut_STOPCOUNT        (dcsr_regOut_STOPCOUNT),
    .regOut_STOPTIME         (dcsr_regOut_STOPTIME),
    .regOut_CAUSE            (dcsr_regOut_CAUSE),
    .regOut_V                (dcsr_regOut_V),
    .regOut_MPRVEN           (dcsr_regOut_MPRVEN),
    .regOut_NMIP             (dcsr_regOut_NMIP),
    .regOut_STEP             (dcsr_regOut_STEP),
    .regOut_PRV              (dcsr_regOut_PRV),
    .trapToD_dcsr_valid      (trapEntryDEvent_out_dcsr_valid),
    .trapToD_dcsr_bits_CAUSE (trapEntryDEvent_out_dcsr_bits_CAUSE),
    .trapToD_dcsr_bits_V     (trapEntryDEvent_out_dcsr_bits_V),
    .trapToD_dcsr_bits_PRV   (trapEntryDEvent_out_dcsr_bits_PRV),
    .retFromD_dcsr_valid     (dretEvent_out_dcsr_valid),
    .retFromD_dcsr_bits_V    (dretEvent_out_dcsr_bits_V),
    .retFromD_dcsr_bits_PRV  (dretEvent_out_dcsr_bits_PRV),
    .nmip                    (nmi_pending)
  );
  DpcModule dpc (
    .clock                (clock),
    .reset                (reset),
    .w_wen                (wen_dpc),
    .w_wdata              (io_in_bits_wdata),
    .rdata                (dpc_rdata),
    .regOut_epc           (dpc_regOut_epc),
    .trapToD_dpc_valid    (trapEntryDEvent_out_dpc_valid),
    .trapToD_dpc_bits_epc (trapEntryDEvent_out_dpc_bits_epc)
  );
  Dscratch0Module dscratch0 (
    .clock      (clock),
    .w_wen      (wen_dscratch0),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (dscratch0_rdata),
    .regOut_ALL (dscratch0_regOut_ALL)
  );
  Dscratch1Module dscratch1 (
    .clock      (clock),
    .w_wen      (wen_dscratch1),
    .w_wdata    (io_in_bits_wdata),
    .rdata      (dscratch1_rdata),
    .regOut_ALL (dscratch1_regOut_ALL)
  );
  SbpctlModule sbpctl (
    .clock              (clock),
    .reset              (reset),
    .w_wen              (wen_sbpctl),
    .w_wdata            (io_in_bits_wdata),
    .rdata              (sbpctl_rdata),
    .regOut_LOOP_ENABLE (sbpctl_regOut_LOOP_ENABLE),
    .regOut_RAS_ENABLE  (sbpctl_regOut_RAS_ENABLE),
    .regOut_SC_ENABLE   (sbpctl_regOut_SC_ENABLE),
    .regOut_TAGE_ENABLE (sbpctl_regOut_TAGE_ENABLE),
    .regOut_BIM_ENABLE  (sbpctl_regOut_BIM_ENABLE),
    .regOut_BTB_ENABLE  (sbpctl_regOut_BTB_ENABLE),
    .regOut_UBTB_ENABLE (sbpctl_regOut_UBTB_ENABLE)
  );
  SpfctlModule spfctl (
    .clock                          (clock),
    .reset                          (reset),
    .w_wen                          (wen_spfctl),
    .w_wdata                        (io_in_bits_wdata),
    .rdata                          (spfctl_rdata),
    .regOut_L2_PF_DELAY_LATENCY     (spfctl_regOut_L2_PF_DELAY_LATENCY),
    .regOut_L2_PF_TP_ENABLE         (spfctl_regOut_L2_PF_TP_ENABLE),
    .regOut_L2_PF_VBOP_ENABLE       (spfctl_regOut_L2_PF_VBOP_ENABLE),
    .regOut_L2_PF_PBOP_ENABLE       (spfctl_regOut_L2_PF_PBOP_ENABLE),
    .regOut_L2_PF_RECV_ENABLE       (spfctl_regOut_L2_PF_RECV_ENABLE),
    .regOut_L2_PF_STORE_ONLY        (spfctl_regOut_L2_PF_STORE_ONLY),
    .regOut_L1D_PF_ENABLE_STRIDE    (spfctl_regOut_L1D_PF_ENABLE_STRIDE),
    .regOut_L1D_PF_ACTIVE_STRIDE    (spfctl_regOut_L1D_PF_ACTIVE_STRIDE),
    .regOut_L1D_PF_ACTIVE_THRESHOLD (spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD),
    .regOut_L1D_PF_ENABLE_PHT       (spfctl_regOut_L1D_PF_ENABLE_PHT),
    .regOut_L1D_PF_ENABLE_AGT       (spfctl_regOut_L1D_PF_ENABLE_AGT),
    .regOut_L1D_PF_TRAIN_ON_HIT     (spfctl_regOut_L1D_PF_TRAIN_ON_HIT),
    .regOut_L1D_PF_ENABLE           (spfctl_regOut_L1D_PF_ENABLE),
    .regOut_L2_PF_ENABLE            (spfctl_regOut_L2_PF_ENABLE),
    .regOut_L1I_PF_ENABLE           (spfctl_regOut_L1I_PF_ENABLE)
  );
  SlvpredctlModule slvpredctl (
    .clock                          (clock),
    .reset                          (reset),
    .w_wen                          (wen_slvpredctl),
    .w_wdata                        (io_in_bits_wdata),
    .rdata                          (slvpredctl_rdata),
    .regOut_LVPRED_TIMEOUT          (slvpredctl_regOut_LVPRED_TIMEOUT),
    .regOut_STORESET_NO_FAST_WAKEUP (slvpredctl_regOut_STORESET_NO_FAST_WAKEUP),
    .regOut_STORESET_WAIT_STORE     (slvpredctl_regOut_STORESET_WAIT_STORE),
    .regOut_NO_SPEC_LOAD            (slvpredctl_regOut_NO_SPEC_LOAD),
    .regOut_LVPRED_DISABLE          (slvpredctl_regOut_LVPRED_DISABLE)
  );
  SmblockctlModule smblockctl (
    .clock                                   (clock),
    .reset                                   (reset),
    .w_wen                                   (wen_smblockctl),
    .w_wdata                                 (io_in_bits_wdata),
    .rdata                                   (smblockctl_rdata),
    .regOut_SBUFFER_TIMEOUT                  (smblockctl_regOut_SBUFFER_TIMEOUT),
    .regOut_HD_MISALIGN_LD_ENABLE            (smblockctl_regOut_HD_MISALIGN_LD_ENABLE),
    .regOut_HD_MISALIGN_ST_ENABLE            (smblockctl_regOut_HD_MISALIGN_ST_ENABLE),
    .regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE (smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE),
    .regOut_CACHE_ERROR_ENABLE               (smblockctl_regOut_CACHE_ERROR_ENABLE),
    .regOut_SOFT_PREFETCH_ENABLE             (smblockctl_regOut_SOFT_PREFETCH_ENABLE),
    .regOut_LDLD_VIO_CHECK_ENABLE            (smblockctl_regOut_LDLD_VIO_CHECK_ENABLE),
    .regOut_SBUFFER_THRESHOLD                (smblockctl_regOut_SBUFFER_THRESHOLD)
  );
  SrnctlModule srnctl (
    .clock                (clock),
    .reset                (reset),
    .w_wen                (wen_srnctl),
    .w_wdata              (io_in_bits_wdata),
    .rdata                (srnctl_rdata),
    .regOut_WFI_ENABLE    (srnctl_regOut_WFI_ENABLE),
    .regOut_FUSION_ENABLE (srnctl_regOut_FUSION_ENABLE)
  );
  McorepwrModule mcorepwr (
    .clock                            (clock),
    .reset                            (reset),
    .w_wen                            (wen_mcorepwr),
    .w_wdata                          (io_in_bits_wdata),
    .rdata                            (mcorepwr_rdata),
    .regOut_COMMIT_STUCK_CHECK_ENABLE (mcorepwr_regOut_COMMIT_STUCK_CHECK_ENABLE),
    .regOut_POWER_DOWN_ENABLE         (mcorepwr_regOut_POWER_DOWN_ENABLE)
  );
  MflushpwrModule mflushpwr (
    .clock                  (clock),
    .reset                  (reset),
    .w_wen                  (wen_mflushpwr),
    .w_wdata                (io_in_bits_wdata),
    .rdata                  (mflushpwr_rdata),
    .regOut_FLUSH_L2_ENABLE (mflushpwr_regOut_FLUSH_L2_ENABLE),
    .regOut_L2_FLUSH_DONE   (mflushpwr_regOut_L2_FLUSH_DONE),
    .l2FlushDone            (io_fromTop_l2FlushDone)
  );
  Pmpcfg0Module pmpcfg_0 (
    .rdata      (pmpcfg_0_rdata),
    .regOut_ALL (pmpcfg_0_regOut_ALL),
    .cfgRData   ({pmpcfgs_7_rdata, pmpcfgs_6_rdata, pmpcfgs_5_rdata, pmpcfgs_4_rdata, pmpcfgs_3_rdata, pmpcfgs_2_rdata, pmpcfgs_1_rdata, pmpcfgs_0_rdata})
  );
  Pmpcfg2Module pmpcfg_1 (
    .rdata      (pmpcfg_1_rdata),
    .regOut_ALL (pmpcfg_1_regOut_ALL),
    .cfgRData   ({pmpcfgs_15_rdata, pmpcfgs_14_rdata, pmpcfgs_13_rdata, pmpcfgs_12_rdata, pmpcfgs_11_rdata, pmpcfgs_10_rdata, pmpcfgs_9_rdata, pmpcfgs_8_rdata})
  );
  Pmpcfg4Module pmpcfg_2 (
    .rdata      (pmpcfg_2_rdata),
    .regOut_ALL (pmpcfg_2_regOut_ALL),
    .cfgRData   ({pmpcfgs_23_rdata, pmpcfgs_22_rdata, pmpcfgs_21_rdata, pmpcfgs_20_rdata, pmpcfgs_19_rdata, pmpcfgs_18_rdata, pmpcfgs_17_rdata, pmpcfgs_16_rdata})
  );
  Pmpcfg6Module pmpcfg_3 (
    .rdata      (pmpcfg_3_rdata),
    .regOut_ALL (pmpcfg_3_regOut_ALL),
    .cfgRData   ({pmpcfgs_31_rdata, pmpcfgs_30_rdata, pmpcfgs_29_rdata, pmpcfgs_28_rdata, pmpcfgs_27_rdata, pmpcfgs_26_rdata, pmpcfgs_25_rdata, pmpcfgs_24_rdata})
  );
  Pmpcfg8Module pmpcfg_4 (
    .rdata      (pmpcfg_4_rdata),
    .regOut_ALL (pmpcfg_4_regOut_ALL)
  );
  Pmpcfg10Module pmpcfg_5 (
    .rdata      (pmpcfg_5_rdata),
    .regOut_ALL (pmpcfg_5_regOut_ALL)
  );
  Pmpcfg12Module pmpcfg_6 (
    .rdata      (pmpcfg_6_rdata),
    .regOut_ALL (pmpcfg_6_regOut_ALL)
  );
  Pmpcfg14Module pmpcfg_7 (
    .rdata      (pmpcfg_7_rdata),
    .regOut_ALL (pmpcfg_7_regOut_ALL)
  );
  Pmp0cfgModule pmpcfgs_0 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[0]),
    .rdata    (pmpcfgs_0_rdata),
    .regOut_R (pmpcfgs_0_regOut_R),
    .regOut_W (pmpcfgs_0_regOut_W),
    .regOut_X (pmpcfgs_0_regOut_X),
    .regOut_A (pmpcfgs_0_regOut_A),
    .regOut_L (pmpcfgs_0_regOut_L)
  );
  Pmp1cfgModule pmpcfgs_1 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[1]),
    .rdata    (pmpcfgs_1_rdata),
    .regOut_R (pmpcfgs_1_regOut_R),
    .regOut_W (pmpcfgs_1_regOut_W),
    .regOut_X (pmpcfgs_1_regOut_X),
    .regOut_A (pmpcfgs_1_regOut_A),
    .regOut_L (pmpcfgs_1_regOut_L)
  );
  Pmp2cfgModule pmpcfgs_2 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[2]),
    .rdata    (pmpcfgs_2_rdata),
    .regOut_R (pmpcfgs_2_regOut_R),
    .regOut_W (pmpcfgs_2_regOut_W),
    .regOut_X (pmpcfgs_2_regOut_X),
    .regOut_A (pmpcfgs_2_regOut_A),
    .regOut_L (pmpcfgs_2_regOut_L)
  );
  Pmp3cfgModule pmpcfgs_3 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[3]),
    .rdata    (pmpcfgs_3_rdata),
    .regOut_R (pmpcfgs_3_regOut_R),
    .regOut_W (pmpcfgs_3_regOut_W),
    .regOut_X (pmpcfgs_3_regOut_X),
    .regOut_A (pmpcfgs_3_regOut_A),
    .regOut_L (pmpcfgs_3_regOut_L)
  );
  Pmp4cfgModule pmpcfgs_4 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[4]),
    .rdata    (pmpcfgs_4_rdata),
    .regOut_R (pmpcfgs_4_regOut_R),
    .regOut_W (pmpcfgs_4_regOut_W),
    .regOut_X (pmpcfgs_4_regOut_X),
    .regOut_A (pmpcfgs_4_regOut_A),
    .regOut_L (pmpcfgs_4_regOut_L)
  );
  Pmp5cfgModule pmpcfgs_5 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[5]),
    .rdata    (pmpcfgs_5_rdata),
    .regOut_R (pmpcfgs_5_regOut_R),
    .regOut_W (pmpcfgs_5_regOut_W),
    .regOut_X (pmpcfgs_5_regOut_X),
    .regOut_A (pmpcfgs_5_regOut_A),
    .regOut_L (pmpcfgs_5_regOut_L)
  );
  Pmp6cfgModule pmpcfgs_6 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[6]),
    .rdata    (pmpcfgs_6_rdata),
    .regOut_R (pmpcfgs_6_regOut_R),
    .regOut_W (pmpcfgs_6_regOut_W),
    .regOut_X (pmpcfgs_6_regOut_X),
    .regOut_A (pmpcfgs_6_regOut_A),
    .regOut_L (pmpcfgs_6_regOut_L)
  );
  Pmp7cfgModule pmpcfgs_7 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_0),
    .w_wdata  (pmpcfg_byte_wdata[7]),
    .rdata    (pmpcfgs_7_rdata),
    .regOut_R (pmpcfgs_7_regOut_R),
    .regOut_W (pmpcfgs_7_regOut_W),
    .regOut_X (pmpcfgs_7_regOut_X),
    .regOut_A (pmpcfgs_7_regOut_A),
    .regOut_L (pmpcfgs_7_regOut_L)
  );
  Pmp8cfgModule pmpcfgs_8 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[0]),
    .rdata    (pmpcfgs_8_rdata),
    .regOut_R (pmpcfgs_8_regOut_R),
    .regOut_W (pmpcfgs_8_regOut_W),
    .regOut_X (pmpcfgs_8_regOut_X),
    .regOut_A (pmpcfgs_8_regOut_A),
    .regOut_L (pmpcfgs_8_regOut_L)
  );
  Pmp9cfgModule pmpcfgs_9 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[1]),
    .rdata    (pmpcfgs_9_rdata),
    .regOut_R (pmpcfgs_9_regOut_R),
    .regOut_W (pmpcfgs_9_regOut_W),
    .regOut_X (pmpcfgs_9_regOut_X),
    .regOut_A (pmpcfgs_9_regOut_A),
    .regOut_L (pmpcfgs_9_regOut_L)
  );
  Pmp10cfgModule pmpcfgs_10 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[2]),
    .rdata    (pmpcfgs_10_rdata),
    .regOut_R (pmpcfgs_10_regOut_R),
    .regOut_W (pmpcfgs_10_regOut_W),
    .regOut_X (pmpcfgs_10_regOut_X),
    .regOut_A (pmpcfgs_10_regOut_A),
    .regOut_L (pmpcfgs_10_regOut_L)
  );
  Pmp11cfgModule pmpcfgs_11 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[3]),
    .rdata    (pmpcfgs_11_rdata),
    .regOut_R (pmpcfgs_11_regOut_R),
    .regOut_W (pmpcfgs_11_regOut_W),
    .regOut_X (pmpcfgs_11_regOut_X),
    .regOut_A (pmpcfgs_11_regOut_A),
    .regOut_L (pmpcfgs_11_regOut_L)
  );
  Pmp12cfgModule pmpcfgs_12 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[4]),
    .rdata    (pmpcfgs_12_rdata),
    .regOut_R (pmpcfgs_12_regOut_R),
    .regOut_W (pmpcfgs_12_regOut_W),
    .regOut_X (pmpcfgs_12_regOut_X),
    .regOut_A (pmpcfgs_12_regOut_A),
    .regOut_L (pmpcfgs_12_regOut_L)
  );
  Pmp13cfgModule pmpcfgs_13 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[5]),
    .rdata    (pmpcfgs_13_rdata),
    .regOut_R (pmpcfgs_13_regOut_R),
    .regOut_W (pmpcfgs_13_regOut_W),
    .regOut_X (pmpcfgs_13_regOut_X),
    .regOut_A (pmpcfgs_13_regOut_A),
    .regOut_L (pmpcfgs_13_regOut_L)
  );
  Pmp14cfgModule pmpcfgs_14 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[6]),
    .rdata    (pmpcfgs_14_rdata),
    .regOut_R (pmpcfgs_14_regOut_R),
    .regOut_W (pmpcfgs_14_regOut_W),
    .regOut_X (pmpcfgs_14_regOut_X),
    .regOut_A (pmpcfgs_14_regOut_A),
    .regOut_L (pmpcfgs_14_regOut_L)
  );
  Pmp15cfgModule pmpcfgs_15 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_1),
    .w_wdata  (pmpcfg_byte_wdata[7]),
    .rdata    (pmpcfgs_15_rdata),
    .regOut_R (pmpcfgs_15_regOut_R),
    .regOut_W (pmpcfgs_15_regOut_W),
    .regOut_X (pmpcfgs_15_regOut_X),
    .regOut_A (pmpcfgs_15_regOut_A),
    .regOut_L (pmpcfgs_15_regOut_L)
  );
  Pmp16cfgModule pmpcfgs_16 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[0]),
    .rdata    (pmpcfgs_16_rdata),
    .regOut_R (pmpcfgs_16_regOut_R),
    .regOut_W (pmpcfgs_16_regOut_W),
    .regOut_X (pmpcfgs_16_regOut_X),
    .regOut_A (pmpcfgs_16_regOut_A),
    .regOut_L (pmpcfgs_16_regOut_L)
  );
  Pmp17cfgModule pmpcfgs_17 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[1]),
    .rdata    (pmpcfgs_17_rdata),
    .regOut_R (pmpcfgs_17_regOut_R),
    .regOut_W (pmpcfgs_17_regOut_W),
    .regOut_X (pmpcfgs_17_regOut_X),
    .regOut_A (pmpcfgs_17_regOut_A),
    .regOut_L (pmpcfgs_17_regOut_L)
  );
  Pmp18cfgModule pmpcfgs_18 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[2]),
    .rdata    (pmpcfgs_18_rdata),
    .regOut_R (pmpcfgs_18_regOut_R),
    .regOut_W (pmpcfgs_18_regOut_W),
    .regOut_X (pmpcfgs_18_regOut_X),
    .regOut_A (pmpcfgs_18_regOut_A),
    .regOut_L (pmpcfgs_18_regOut_L)
  );
  Pmp19cfgModule pmpcfgs_19 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[3]),
    .rdata    (pmpcfgs_19_rdata),
    .regOut_R (pmpcfgs_19_regOut_R),
    .regOut_W (pmpcfgs_19_regOut_W),
    .regOut_X (pmpcfgs_19_regOut_X),
    .regOut_A (pmpcfgs_19_regOut_A),
    .regOut_L (pmpcfgs_19_regOut_L)
  );
  Pmp20cfgModule pmpcfgs_20 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[4]),
    .rdata    (pmpcfgs_20_rdata),
    .regOut_R (pmpcfgs_20_regOut_R),
    .regOut_W (pmpcfgs_20_regOut_W),
    .regOut_X (pmpcfgs_20_regOut_X),
    .regOut_A (pmpcfgs_20_regOut_A),
    .regOut_L (pmpcfgs_20_regOut_L)
  );
  Pmp21cfgModule pmpcfgs_21 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[5]),
    .rdata    (pmpcfgs_21_rdata),
    .regOut_R (pmpcfgs_21_regOut_R),
    .regOut_W (pmpcfgs_21_regOut_W),
    .regOut_X (pmpcfgs_21_regOut_X),
    .regOut_A (pmpcfgs_21_regOut_A),
    .regOut_L (pmpcfgs_21_regOut_L)
  );
  Pmp22cfgModule pmpcfgs_22 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[6]),
    .rdata    (pmpcfgs_22_rdata),
    .regOut_R (pmpcfgs_22_regOut_R),
    .regOut_W (pmpcfgs_22_regOut_W),
    .regOut_X (pmpcfgs_22_regOut_X),
    .regOut_A (pmpcfgs_22_regOut_A),
    .regOut_L (pmpcfgs_22_regOut_L)
  );
  Pmp23cfgModule pmpcfgs_23 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_2),
    .w_wdata  (pmpcfg_byte_wdata[7]),
    .rdata    (pmpcfgs_23_rdata),
    .regOut_R (pmpcfgs_23_regOut_R),
    .regOut_W (pmpcfgs_23_regOut_W),
    .regOut_X (pmpcfgs_23_regOut_X),
    .regOut_A (pmpcfgs_23_regOut_A),
    .regOut_L (pmpcfgs_23_regOut_L)
  );
  Pmp24cfgModule pmpcfgs_24 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[0]),
    .rdata    (pmpcfgs_24_rdata),
    .regOut_R (pmpcfgs_24_regOut_R),
    .regOut_W (pmpcfgs_24_regOut_W),
    .regOut_X (pmpcfgs_24_regOut_X),
    .regOut_A (pmpcfgs_24_regOut_A),
    .regOut_L (pmpcfgs_24_regOut_L)
  );
  Pmp25cfgModule pmpcfgs_25 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[1]),
    .rdata    (pmpcfgs_25_rdata),
    .regOut_R (pmpcfgs_25_regOut_R),
    .regOut_W (pmpcfgs_25_regOut_W),
    .regOut_X (pmpcfgs_25_regOut_X),
    .regOut_A (pmpcfgs_25_regOut_A),
    .regOut_L (pmpcfgs_25_regOut_L)
  );
  Pmp26cfgModule pmpcfgs_26 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[2]),
    .rdata    (pmpcfgs_26_rdata),
    .regOut_R (pmpcfgs_26_regOut_R),
    .regOut_W (pmpcfgs_26_regOut_W),
    .regOut_X (pmpcfgs_26_regOut_X),
    .regOut_A (pmpcfgs_26_regOut_A),
    .regOut_L (pmpcfgs_26_regOut_L)
  );
  Pmp27cfgModule pmpcfgs_27 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[3]),
    .rdata    (pmpcfgs_27_rdata),
    .regOut_R (pmpcfgs_27_regOut_R),
    .regOut_W (pmpcfgs_27_regOut_W),
    .regOut_X (pmpcfgs_27_regOut_X),
    .regOut_A (pmpcfgs_27_regOut_A),
    .regOut_L (pmpcfgs_27_regOut_L)
  );
  Pmp28cfgModule pmpcfgs_28 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[4]),
    .rdata    (pmpcfgs_28_rdata),
    .regOut_R (pmpcfgs_28_regOut_R),
    .regOut_W (pmpcfgs_28_regOut_W),
    .regOut_X (pmpcfgs_28_regOut_X),
    .regOut_A (pmpcfgs_28_regOut_A),
    .regOut_L (pmpcfgs_28_regOut_L)
  );
  Pmp29cfgModule pmpcfgs_29 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[5]),
    .rdata    (pmpcfgs_29_rdata),
    .regOut_R (pmpcfgs_29_regOut_R),
    .regOut_W (pmpcfgs_29_regOut_W),
    .regOut_X (pmpcfgs_29_regOut_X),
    .regOut_A (pmpcfgs_29_regOut_A),
    .regOut_L (pmpcfgs_29_regOut_L)
  );
  Pmp30cfgModule pmpcfgs_30 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[6]),
    .rdata    (pmpcfgs_30_rdata),
    .regOut_R (pmpcfgs_30_regOut_R),
    .regOut_W (pmpcfgs_30_regOut_W),
    .regOut_X (pmpcfgs_30_regOut_X),
    .regOut_A (pmpcfgs_30_regOut_A),
    .regOut_L (pmpcfgs_30_regOut_L)
  );
  Pmp31cfgModule pmpcfgs_31 (
    .clock    (clock),
    .reset    (reset),
    .w_wen    (wen_pmpcfg_3),
    .w_wdata  (pmpcfg_byte_wdata[7]),
    .rdata    (pmpcfgs_31_rdata),
    .regOut_R (pmpcfgs_31_regOut_R),
    .regOut_W (pmpcfgs_31_regOut_W),
    .regOut_X (pmpcfgs_31_regOut_X),
    .regOut_A (pmpcfgs_31_regOut_A),
    .regOut_L (pmpcfgs_31_regOut_L)
  );
  Pmpaddr0Module pmpaddr_0 (
    .rdata          (pmpaddr_0_rdata),
    .regOut_ADDRESS (pmpaddr_0_regOut_ADDRESS),
    .addrRData_0    (pmpEntryMod_io_out_pmpAddrRData_0)
  );
  Pmpaddr1Module pmpaddr_1 (
    .rdata          (pmpaddr_1_rdata),
    .regOut_ADDRESS (pmpaddr_1_regOut_ADDRESS),
    .addrRData_1    (pmpEntryMod_io_out_pmpAddrRData_1)
  );
  Pmpaddr2Module pmpaddr_2 (
    .rdata          (pmpaddr_2_rdata),
    .regOut_ADDRESS (pmpaddr_2_regOut_ADDRESS),
    .addrRData_2    (pmpEntryMod_io_out_pmpAddrRData_2)
  );
  Pmpaddr3Module pmpaddr_3 (
    .rdata          (pmpaddr_3_rdata),
    .regOut_ADDRESS (pmpaddr_3_regOut_ADDRESS),
    .addrRData_3    (pmpEntryMod_io_out_pmpAddrRData_3)
  );
  Pmpaddr4Module pmpaddr_4 (
    .rdata          (pmpaddr_4_rdata),
    .regOut_ADDRESS (pmpaddr_4_regOut_ADDRESS),
    .addrRData_4    (pmpEntryMod_io_out_pmpAddrRData_4)
  );
  Pmpaddr5Module pmpaddr_5 (
    .rdata          (pmpaddr_5_rdata),
    .regOut_ADDRESS (pmpaddr_5_regOut_ADDRESS),
    .addrRData_5    (pmpEntryMod_io_out_pmpAddrRData_5)
  );
  Pmpaddr6Module pmpaddr_6 (
    .rdata          (pmpaddr_6_rdata),
    .regOut_ADDRESS (pmpaddr_6_regOut_ADDRESS),
    .addrRData_6    (pmpEntryMod_io_out_pmpAddrRData_6)
  );
  Pmpaddr7Module pmpaddr_7 (
    .rdata          (pmpaddr_7_rdata),
    .regOut_ADDRESS (pmpaddr_7_regOut_ADDRESS),
    .addrRData_7    (pmpEntryMod_io_out_pmpAddrRData_7)
  );
  Pmpaddr8Module pmpaddr_8 (
    .rdata          (pmpaddr_8_rdata),
    .regOut_ADDRESS (pmpaddr_8_regOut_ADDRESS),
    .addrRData_8    (pmpEntryMod_io_out_pmpAddrRData_8)
  );
  Pmpaddr9Module pmpaddr_9 (
    .rdata          (pmpaddr_9_rdata),
    .regOut_ADDRESS (pmpaddr_9_regOut_ADDRESS),
    .addrRData_9    (pmpEntryMod_io_out_pmpAddrRData_9)
  );
  Pmpaddr10Module pmpaddr_10 (
    .rdata          (pmpaddr_10_rdata),
    .regOut_ADDRESS (pmpaddr_10_regOut_ADDRESS),
    .addrRData_10   (pmpEntryMod_io_out_pmpAddrRData_10)
  );
  Pmpaddr11Module pmpaddr_11 (
    .rdata          (pmpaddr_11_rdata),
    .regOut_ADDRESS (pmpaddr_11_regOut_ADDRESS),
    .addrRData_11   (pmpEntryMod_io_out_pmpAddrRData_11)
  );
  Pmpaddr12Module pmpaddr_12 (
    .rdata          (pmpaddr_12_rdata),
    .regOut_ADDRESS (pmpaddr_12_regOut_ADDRESS),
    .addrRData_12   (pmpEntryMod_io_out_pmpAddrRData_12)
  );
  Pmpaddr13Module pmpaddr_13 (
    .rdata          (pmpaddr_13_rdata),
    .regOut_ADDRESS (pmpaddr_13_regOut_ADDRESS),
    .addrRData_13   (pmpEntryMod_io_out_pmpAddrRData_13)
  );
  Pmpaddr14Module pmpaddr_14 (
    .rdata          (pmpaddr_14_rdata),
    .regOut_ADDRESS (pmpaddr_14_regOut_ADDRESS),
    .addrRData_14   (pmpEntryMod_io_out_pmpAddrRData_14)
  );
  Pmpaddr15Module pmpaddr_15 (
    .rdata          (pmpaddr_15_rdata),
    .regOut_ADDRESS (pmpaddr_15_regOut_ADDRESS),
    .addrRData_15   (pmpEntryMod_io_out_pmpAddrRData_15)
  );
  Pmpaddr16Module pmpaddr_16 (
    .rdata          (pmpaddr_16_rdata),
    .regOut_ADDRESS (pmpaddr_16_regOut_ADDRESS),
    .addrRData_16   (pmpEntryMod_io_out_pmpAddrRData_16)
  );
  Pmpaddr17Module pmpaddr_17 (
    .rdata          (pmpaddr_17_rdata),
    .regOut_ADDRESS (pmpaddr_17_regOut_ADDRESS),
    .addrRData_17   (pmpEntryMod_io_out_pmpAddrRData_17)
  );
  Pmpaddr18Module pmpaddr_18 (
    .rdata          (pmpaddr_18_rdata),
    .regOut_ADDRESS (pmpaddr_18_regOut_ADDRESS),
    .addrRData_18   (pmpEntryMod_io_out_pmpAddrRData_18)
  );
  Pmpaddr19Module pmpaddr_19 (
    .rdata          (pmpaddr_19_rdata),
    .regOut_ADDRESS (pmpaddr_19_regOut_ADDRESS),
    .addrRData_19   (pmpEntryMod_io_out_pmpAddrRData_19)
  );
  Pmpaddr20Module pmpaddr_20 (
    .rdata          (pmpaddr_20_rdata),
    .regOut_ADDRESS (pmpaddr_20_regOut_ADDRESS),
    .addrRData_20   (pmpEntryMod_io_out_pmpAddrRData_20)
  );
  Pmpaddr21Module pmpaddr_21 (
    .rdata          (pmpaddr_21_rdata),
    .regOut_ADDRESS (pmpaddr_21_regOut_ADDRESS),
    .addrRData_21   (pmpEntryMod_io_out_pmpAddrRData_21)
  );
  Pmpaddr22Module pmpaddr_22 (
    .rdata          (pmpaddr_22_rdata),
    .regOut_ADDRESS (pmpaddr_22_regOut_ADDRESS),
    .addrRData_22   (pmpEntryMod_io_out_pmpAddrRData_22)
  );
  Pmpaddr23Module pmpaddr_23 (
    .rdata          (pmpaddr_23_rdata),
    .regOut_ADDRESS (pmpaddr_23_regOut_ADDRESS),
    .addrRData_23   (pmpEntryMod_io_out_pmpAddrRData_23)
  );
  Pmpaddr24Module pmpaddr_24 (
    .rdata          (pmpaddr_24_rdata),
    .regOut_ADDRESS (pmpaddr_24_regOut_ADDRESS),
    .addrRData_24   (pmpEntryMod_io_out_pmpAddrRData_24)
  );
  Pmpaddr25Module pmpaddr_25 (
    .rdata          (pmpaddr_25_rdata),
    .regOut_ADDRESS (pmpaddr_25_regOut_ADDRESS),
    .addrRData_25   (pmpEntryMod_io_out_pmpAddrRData_25)
  );
  Pmpaddr26Module pmpaddr_26 (
    .rdata          (pmpaddr_26_rdata),
    .regOut_ADDRESS (pmpaddr_26_regOut_ADDRESS),
    .addrRData_26   (pmpEntryMod_io_out_pmpAddrRData_26)
  );
  Pmpaddr27Module pmpaddr_27 (
    .rdata          (pmpaddr_27_rdata),
    .regOut_ADDRESS (pmpaddr_27_regOut_ADDRESS),
    .addrRData_27   (pmpEntryMod_io_out_pmpAddrRData_27)
  );
  Pmpaddr28Module pmpaddr_28 (
    .rdata          (pmpaddr_28_rdata),
    .regOut_ADDRESS (pmpaddr_28_regOut_ADDRESS),
    .addrRData_28   (pmpEntryMod_io_out_pmpAddrRData_28)
  );
  Pmpaddr29Module pmpaddr_29 (
    .rdata          (pmpaddr_29_rdata),
    .regOut_ADDRESS (pmpaddr_29_regOut_ADDRESS),
    .addrRData_29   (pmpEntryMod_io_out_pmpAddrRData_29)
  );
  Pmpaddr30Module pmpaddr_30 (
    .rdata          (pmpaddr_30_rdata),
    .regOut_ADDRESS (pmpaddr_30_regOut_ADDRESS),
    .addrRData_30   (pmpEntryMod_io_out_pmpAddrRData_30)
  );
  Pmpaddr31Module pmpaddr_31 (
    .rdata          (pmpaddr_31_rdata),
    .regOut_ADDRESS (pmpaddr_31_regOut_ADDRESS),
    .addrRData_31   (pmpEntryMod_io_out_pmpAddrRData_31)
  );
  Pmpaddr32Module pmpaddr_32 (
    .rdata      (pmpaddr_32_rdata),
    .regOut_ALL (pmpaddr_32_regOut_ALL)
  );
  Pmpaddr33Module pmpaddr_33 (
    .rdata      (pmpaddr_33_rdata),
    .regOut_ALL (pmpaddr_33_regOut_ALL)
  );
  Pmpaddr34Module pmpaddr_34 (
    .rdata      (pmpaddr_34_rdata),
    .regOut_ALL (pmpaddr_34_regOut_ALL)
  );
  Pmpaddr35Module pmpaddr_35 (
    .rdata      (pmpaddr_35_rdata),
    .regOut_ALL (pmpaddr_35_regOut_ALL)
  );
  Pmpaddr36Module pmpaddr_36 (
    .rdata      (pmpaddr_36_rdata),
    .regOut_ALL (pmpaddr_36_regOut_ALL)
  );
  Pmpaddr37Module pmpaddr_37 (
    .rdata      (pmpaddr_37_rdata),
    .regOut_ALL (pmpaddr_37_regOut_ALL)
  );
  Pmpaddr38Module pmpaddr_38 (
    .rdata      (pmpaddr_38_rdata),
    .regOut_ALL (pmpaddr_38_regOut_ALL)
  );
  Pmpaddr39Module pmpaddr_39 (
    .rdata      (pmpaddr_39_rdata),
    .regOut_ALL (pmpaddr_39_regOut_ALL)
  );
  Pmpaddr40Module pmpaddr_40 (
    .rdata      (pmpaddr_40_rdata),
    .regOut_ALL (pmpaddr_40_regOut_ALL)
  );
  Pmpaddr41Module pmpaddr_41 (
    .rdata      (pmpaddr_41_rdata),
    .regOut_ALL (pmpaddr_41_regOut_ALL)
  );
  Pmpaddr42Module pmpaddr_42 (
    .rdata      (pmpaddr_42_rdata),
    .regOut_ALL (pmpaddr_42_regOut_ALL)
  );
  Pmpaddr43Module pmpaddr_43 (
    .rdata      (pmpaddr_43_rdata),
    .regOut_ALL (pmpaddr_43_regOut_ALL)
  );
  Pmpaddr44Module pmpaddr_44 (
    .rdata      (pmpaddr_44_rdata),
    .regOut_ALL (pmpaddr_44_regOut_ALL)
  );
  Pmpaddr45Module pmpaddr_45 (
    .rdata      (pmpaddr_45_rdata),
    .regOut_ALL (pmpaddr_45_regOut_ALL)
  );
  Pmpaddr46Module pmpaddr_46 (
    .rdata      (pmpaddr_46_rdata),
    .regOut_ALL (pmpaddr_46_regOut_ALL)
  );
  Pmpaddr47Module pmpaddr_47 (
    .rdata      (pmpaddr_47_rdata),
    .regOut_ALL (pmpaddr_47_regOut_ALL)
  );
  Pmpaddr48Module pmpaddr_48 (
    .rdata      (pmpaddr_48_rdata),
    .regOut_ALL (pmpaddr_48_regOut_ALL)
  );
  Pmpaddr49Module pmpaddr_49 (
    .rdata      (pmpaddr_49_rdata),
    .regOut_ALL (pmpaddr_49_regOut_ALL)
  );
  Pmpaddr50Module pmpaddr_50 (
    .rdata      (pmpaddr_50_rdata),
    .regOut_ALL (pmpaddr_50_regOut_ALL)
  );
  Pmpaddr51Module pmpaddr_51 (
    .rdata      (pmpaddr_51_rdata),
    .regOut_ALL (pmpaddr_51_regOut_ALL)
  );
  Pmpaddr52Module pmpaddr_52 (
    .rdata      (pmpaddr_52_rdata),
    .regOut_ALL (pmpaddr_52_regOut_ALL)
  );
  Pmpaddr53Module pmpaddr_53 (
    .rdata      (pmpaddr_53_rdata),
    .regOut_ALL (pmpaddr_53_regOut_ALL)
  );
  Pmpaddr54Module pmpaddr_54 (
    .rdata      (pmpaddr_54_rdata),
    .regOut_ALL (pmpaddr_54_regOut_ALL)
  );
  Pmpaddr55Module pmpaddr_55 (
    .rdata      (pmpaddr_55_rdata),
    .regOut_ALL (pmpaddr_55_regOut_ALL)
  );
  Pmpaddr56Module pmpaddr_56 (
    .rdata      (pmpaddr_56_rdata),
    .regOut_ALL (pmpaddr_56_regOut_ALL)
  );
  Pmpaddr57Module pmpaddr_57 (
    .rdata      (pmpaddr_57_rdata),
    .regOut_ALL (pmpaddr_57_regOut_ALL)
  );
  Pmpaddr58Module pmpaddr_58 (
    .rdata      (pmpaddr_58_rdata),
    .regOut_ALL (pmpaddr_58_regOut_ALL)
  );
  Pmpaddr59Module pmpaddr_59 (
    .rdata      (pmpaddr_59_rdata),
    .regOut_ALL (pmpaddr_59_regOut_ALL)
  );
  Pmpaddr60Module pmpaddr_60 (
    .rdata      (pmpaddr_60_rdata),
    .regOut_ALL (pmpaddr_60_regOut_ALL)
  );
  Pmpaddr61Module pmpaddr_61 (
    .rdata      (pmpaddr_61_rdata),
    .regOut_ALL (pmpaddr_61_regOut_ALL)
  );
  Pmpaddr62Module pmpaddr_62 (
    .rdata      (pmpaddr_62_rdata),
    .regOut_ALL (pmpaddr_62_regOut_ALL)
  );
  Pmpaddr63Module pmpaddr_63 (
    .rdata      (pmpaddr_63_rdata),
    .regOut_ALL (pmpaddr_63_regOut_ALL)
  );
  Pmacfg0Module pmacfg_0 (
    .rdata      (pmacfg_0_rdata),
    .regOut_ALL (pmacfg_0_regOut_ALL),
    .cfgRData   ({pmacfgs_7_rdata, pmacfgs_6_rdata, pmacfgs_5_rdata, pmacfgs_4_rdata, pmacfgs_3_rdata, pmacfgs_2_rdata, pmacfgs_1_rdata, pmacfgs_0_rdata})
  );
  Pmacfg2Module pmacfg_1 (
    .rdata      (pmacfg_1_rdata),
    .regOut_ALL (pmacfg_1_regOut_ALL),
    .cfgRData   ({pmacfgs_15_rdata, pmacfgs_14_rdata, pmacfgs_13_rdata, pmacfgs_12_rdata, pmacfgs_11_rdata, pmacfgs_10_rdata, pmacfgs_9_rdata, pmacfgs_8_rdata})
  );
  Pmacfg4Module pmacfg_2 (
    .rdata      (pmacfg_2_rdata),
    .regOut_ALL (pmacfg_2_regOut_ALL),
    .cfgRData   ({pmacfgs_23_rdata, pmacfgs_22_rdata, pmacfgs_21_rdata, pmacfgs_20_rdata, pmacfgs_19_rdata, pmacfgs_18_rdata, pmacfgs_17_rdata, pmacfgs_16_rdata})
  );
  Pmacfg6Module pmacfg_3 (
    .rdata      (pmacfg_3_rdata),
    .regOut_ALL (pmacfg_3_regOut_ALL),
    .cfgRData   ({pmacfgs_31_rdata, pmacfgs_30_rdata, pmacfgs_29_rdata, pmacfgs_28_rdata, pmacfgs_27_rdata, pmacfgs_26_rdata, pmacfgs_25_rdata, pmacfgs_24_rdata})
  );
  Pma0cfgModule pmacfgs_0 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[0]),
    .rdata         (pmacfgs_0_rdata),
    .regOut_R      (pmacfgs_0_regOut_R),
    .regOut_W      (pmacfgs_0_regOut_W),
    .regOut_X      (pmacfgs_0_regOut_X),
    .regOut_A      (pmacfgs_0_regOut_A),
    .regOut_ATOMIC (pmacfgs_0_regOut_ATOMIC),
    .regOut_C      (pmacfgs_0_regOut_C),
    .regOut_L      (pmacfgs_0_regOut_L)
  );
  Pma1cfgModule pmacfgs_1 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[1]),
    .rdata         (pmacfgs_1_rdata),
    .regOut_R      (pmacfgs_1_regOut_R),
    .regOut_W      (pmacfgs_1_regOut_W),
    .regOut_X      (pmacfgs_1_regOut_X),
    .regOut_A      (pmacfgs_1_regOut_A),
    .regOut_ATOMIC (pmacfgs_1_regOut_ATOMIC),
    .regOut_C      (pmacfgs_1_regOut_C),
    .regOut_L      (pmacfgs_1_regOut_L)
  );
  Pma2cfgModule pmacfgs_2 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[2]),
    .rdata         (pmacfgs_2_rdata),
    .regOut_R      (pmacfgs_2_regOut_R),
    .regOut_W      (pmacfgs_2_regOut_W),
    .regOut_X      (pmacfgs_2_regOut_X),
    .regOut_A      (pmacfgs_2_regOut_A),
    .regOut_ATOMIC (pmacfgs_2_regOut_ATOMIC),
    .regOut_C      (pmacfgs_2_regOut_C),
    .regOut_L      (pmacfgs_2_regOut_L)
  );
  Pma3cfgModule pmacfgs_3 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[3]),
    .rdata         (pmacfgs_3_rdata),
    .regOut_R      (pmacfgs_3_regOut_R),
    .regOut_W      (pmacfgs_3_regOut_W),
    .regOut_X      (pmacfgs_3_regOut_X),
    .regOut_A      (pmacfgs_3_regOut_A),
    .regOut_ATOMIC (pmacfgs_3_regOut_ATOMIC),
    .regOut_C      (pmacfgs_3_regOut_C),
    .regOut_L      (pmacfgs_3_regOut_L)
  );
  Pma4cfgModule pmacfgs_4 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[4]),
    .rdata         (pmacfgs_4_rdata),
    .regOut_R      (pmacfgs_4_regOut_R),
    .regOut_W      (pmacfgs_4_regOut_W),
    .regOut_X      (pmacfgs_4_regOut_X),
    .regOut_A      (pmacfgs_4_regOut_A),
    .regOut_ATOMIC (pmacfgs_4_regOut_ATOMIC),
    .regOut_C      (pmacfgs_4_regOut_C),
    .regOut_L      (pmacfgs_4_regOut_L)
  );
  Pma5cfgModule pmacfgs_5 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[5]),
    .rdata         (pmacfgs_5_rdata),
    .regOut_R      (pmacfgs_5_regOut_R),
    .regOut_W      (pmacfgs_5_regOut_W),
    .regOut_X      (pmacfgs_5_regOut_X),
    .regOut_A      (pmacfgs_5_regOut_A),
    .regOut_ATOMIC (pmacfgs_5_regOut_ATOMIC),
    .regOut_C      (pmacfgs_5_regOut_C),
    .regOut_L      (pmacfgs_5_regOut_L)
  );
  Pma6cfgModule pmacfgs_6 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[6]),
    .rdata         (pmacfgs_6_rdata),
    .regOut_R      (pmacfgs_6_regOut_R),
    .regOut_W      (pmacfgs_6_regOut_W),
    .regOut_X      (pmacfgs_6_regOut_X),
    .regOut_A      (pmacfgs_6_regOut_A),
    .regOut_ATOMIC (pmacfgs_6_regOut_ATOMIC),
    .regOut_C      (pmacfgs_6_regOut_C),
    .regOut_L      (pmacfgs_6_regOut_L)
  );
  Pma7cfgModule pmacfgs_7 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_0),
    .w_wdata       (pmacfg_byte_wdata[7]),
    .rdata         (pmacfgs_7_rdata),
    .regOut_R      (pmacfgs_7_regOut_R),
    .regOut_W      (pmacfgs_7_regOut_W),
    .regOut_X      (pmacfgs_7_regOut_X),
    .regOut_A      (pmacfgs_7_regOut_A),
    .regOut_ATOMIC (pmacfgs_7_regOut_ATOMIC),
    .regOut_C      (pmacfgs_7_regOut_C),
    .regOut_L      (pmacfgs_7_regOut_L)
  );
  Pma8cfgModule pmacfgs_8 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[0]),
    .rdata         (pmacfgs_8_rdata),
    .regOut_R      (pmacfgs_8_regOut_R),
    .regOut_W      (pmacfgs_8_regOut_W),
    .regOut_X      (pmacfgs_8_regOut_X),
    .regOut_A      (pmacfgs_8_regOut_A),
    .regOut_ATOMIC (pmacfgs_8_regOut_ATOMIC),
    .regOut_C      (pmacfgs_8_regOut_C),
    .regOut_L      (pmacfgs_8_regOut_L)
  );
  Pma9cfgModule pmacfgs_9 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[1]),
    .rdata         (pmacfgs_9_rdata),
    .regOut_R      (pmacfgs_9_regOut_R),
    .regOut_W      (pmacfgs_9_regOut_W),
    .regOut_X      (pmacfgs_9_regOut_X),
    .regOut_A      (pmacfgs_9_regOut_A),
    .regOut_ATOMIC (pmacfgs_9_regOut_ATOMIC),
    .regOut_C      (pmacfgs_9_regOut_C),
    .regOut_L      (pmacfgs_9_regOut_L)
  );
  Pma10cfgModule pmacfgs_10 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[2]),
    .rdata         (pmacfgs_10_rdata),
    .regOut_R      (pmacfgs_10_regOut_R),
    .regOut_W      (pmacfgs_10_regOut_W),
    .regOut_X      (pmacfgs_10_regOut_X),
    .regOut_A      (pmacfgs_10_regOut_A),
    .regOut_ATOMIC (pmacfgs_10_regOut_ATOMIC),
    .regOut_C      (pmacfgs_10_regOut_C),
    .regOut_L      (pmacfgs_10_regOut_L)
  );
  Pma11cfgModule pmacfgs_11 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[3]),
    .rdata         (pmacfgs_11_rdata),
    .regOut_R      (pmacfgs_11_regOut_R),
    .regOut_W      (pmacfgs_11_regOut_W),
    .regOut_X      (pmacfgs_11_regOut_X),
    .regOut_A      (pmacfgs_11_regOut_A),
    .regOut_ATOMIC (pmacfgs_11_regOut_ATOMIC),
    .regOut_C      (pmacfgs_11_regOut_C),
    .regOut_L      (pmacfgs_11_regOut_L)
  );
  Pma12cfgModule pmacfgs_12 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[4]),
    .rdata         (pmacfgs_12_rdata),
    .regOut_R      (pmacfgs_12_regOut_R),
    .regOut_W      (pmacfgs_12_regOut_W),
    .regOut_X      (pmacfgs_12_regOut_X),
    .regOut_A      (pmacfgs_12_regOut_A),
    .regOut_ATOMIC (pmacfgs_12_regOut_ATOMIC),
    .regOut_C      (pmacfgs_12_regOut_C),
    .regOut_L      (pmacfgs_12_regOut_L)
  );
  Pma13cfgModule pmacfgs_13 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[5]),
    .rdata         (pmacfgs_13_rdata),
    .regOut_R      (pmacfgs_13_regOut_R),
    .regOut_W      (pmacfgs_13_regOut_W),
    .regOut_X      (pmacfgs_13_regOut_X),
    .regOut_A      (pmacfgs_13_regOut_A),
    .regOut_ATOMIC (pmacfgs_13_regOut_ATOMIC),
    .regOut_C      (pmacfgs_13_regOut_C),
    .regOut_L      (pmacfgs_13_regOut_L)
  );
  Pma14cfgModule pmacfgs_14 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[6]),
    .rdata         (pmacfgs_14_rdata),
    .regOut_R      (pmacfgs_14_regOut_R),
    .regOut_W      (pmacfgs_14_regOut_W),
    .regOut_X      (pmacfgs_14_regOut_X),
    .regOut_A      (pmacfgs_14_regOut_A),
    .regOut_ATOMIC (pmacfgs_14_regOut_ATOMIC),
    .regOut_C      (pmacfgs_14_regOut_C),
    .regOut_L      (pmacfgs_14_regOut_L)
  );
  Pma15cfgModule pmacfgs_15 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_1),
    .w_wdata       (pmacfg_byte_wdata[7]),
    .rdata         (pmacfgs_15_rdata),
    .regOut_R      (pmacfgs_15_regOut_R),
    .regOut_W      (pmacfgs_15_regOut_W),
    .regOut_X      (pmacfgs_15_regOut_X),
    .regOut_A      (pmacfgs_15_regOut_A),
    .regOut_ATOMIC (pmacfgs_15_regOut_ATOMIC),
    .regOut_C      (pmacfgs_15_regOut_C),
    .regOut_L      (pmacfgs_15_regOut_L)
  );
  Pma16cfgModule pmacfgs_16 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[0]),
    .rdata         (pmacfgs_16_rdata),
    .regOut_R      (pmacfgs_16_regOut_R),
    .regOut_W      (pmacfgs_16_regOut_W),
    .regOut_X      (pmacfgs_16_regOut_X),
    .regOut_A      (pmacfgs_16_regOut_A),
    .regOut_ATOMIC (pmacfgs_16_regOut_ATOMIC),
    .regOut_C      (pmacfgs_16_regOut_C),
    .regOut_L      (pmacfgs_16_regOut_L)
  );
  Pma17cfgModule pmacfgs_17 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[1]),
    .rdata         (pmacfgs_17_rdata),
    .regOut_R      (pmacfgs_17_regOut_R),
    .regOut_W      (pmacfgs_17_regOut_W),
    .regOut_X      (pmacfgs_17_regOut_X),
    .regOut_A      (pmacfgs_17_regOut_A),
    .regOut_ATOMIC (pmacfgs_17_regOut_ATOMIC),
    .regOut_C      (pmacfgs_17_regOut_C),
    .regOut_L      (pmacfgs_17_regOut_L)
  );
  Pma18cfgModule pmacfgs_18 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[2]),
    .rdata         (pmacfgs_18_rdata),
    .regOut_R      (pmacfgs_18_regOut_R),
    .regOut_W      (pmacfgs_18_regOut_W),
    .regOut_X      (pmacfgs_18_regOut_X),
    .regOut_A      (pmacfgs_18_regOut_A),
    .regOut_ATOMIC (pmacfgs_18_regOut_ATOMIC),
    .regOut_C      (pmacfgs_18_regOut_C),
    .regOut_L      (pmacfgs_18_regOut_L)
  );
  Pma19cfgModule pmacfgs_19 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[3]),
    .rdata         (pmacfgs_19_rdata),
    .regOut_R      (pmacfgs_19_regOut_R),
    .regOut_W      (pmacfgs_19_regOut_W),
    .regOut_X      (pmacfgs_19_regOut_X),
    .regOut_A      (pmacfgs_19_regOut_A),
    .regOut_ATOMIC (pmacfgs_19_regOut_ATOMIC),
    .regOut_C      (pmacfgs_19_regOut_C),
    .regOut_L      (pmacfgs_19_regOut_L)
  );
  Pma20cfgModule pmacfgs_20 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[4]),
    .rdata         (pmacfgs_20_rdata),
    .regOut_R      (pmacfgs_20_regOut_R),
    .regOut_W      (pmacfgs_20_regOut_W),
    .regOut_X      (pmacfgs_20_regOut_X),
    .regOut_A      (pmacfgs_20_regOut_A),
    .regOut_ATOMIC (pmacfgs_20_regOut_ATOMIC),
    .regOut_C      (pmacfgs_20_regOut_C),
    .regOut_L      (pmacfgs_20_regOut_L)
  );
  Pma21cfgModule pmacfgs_21 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[5]),
    .rdata         (pmacfgs_21_rdata),
    .regOut_R      (pmacfgs_21_regOut_R),
    .regOut_W      (pmacfgs_21_regOut_W),
    .regOut_X      (pmacfgs_21_regOut_X),
    .regOut_A      (pmacfgs_21_regOut_A),
    .regOut_ATOMIC (pmacfgs_21_regOut_ATOMIC),
    .regOut_C      (pmacfgs_21_regOut_C),
    .regOut_L      (pmacfgs_21_regOut_L)
  );
  Pma22cfgModule pmacfgs_22 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[6]),
    .rdata         (pmacfgs_22_rdata),
    .regOut_R      (pmacfgs_22_regOut_R),
    .regOut_W      (pmacfgs_22_regOut_W),
    .regOut_X      (pmacfgs_22_regOut_X),
    .regOut_A      (pmacfgs_22_regOut_A),
    .regOut_ATOMIC (pmacfgs_22_regOut_ATOMIC),
    .regOut_C      (pmacfgs_22_regOut_C),
    .regOut_L      (pmacfgs_22_regOut_L)
  );
  Pma23cfgModule pmacfgs_23 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_2),
    .w_wdata       (pmacfg_byte_wdata[7]),
    .rdata         (pmacfgs_23_rdata),
    .regOut_R      (pmacfgs_23_regOut_R),
    .regOut_W      (pmacfgs_23_regOut_W),
    .regOut_X      (pmacfgs_23_regOut_X),
    .regOut_A      (pmacfgs_23_regOut_A),
    .regOut_ATOMIC (pmacfgs_23_regOut_ATOMIC),
    .regOut_C      (pmacfgs_23_regOut_C),
    .regOut_L      (pmacfgs_23_regOut_L)
  );
  Pma24cfgModule pmacfgs_24 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[0]),
    .rdata         (pmacfgs_24_rdata),
    .regOut_R      (pmacfgs_24_regOut_R),
    .regOut_W      (pmacfgs_24_regOut_W),
    .regOut_X      (pmacfgs_24_regOut_X),
    .regOut_A      (pmacfgs_24_regOut_A),
    .regOut_ATOMIC (pmacfgs_24_regOut_ATOMIC),
    .regOut_C      (pmacfgs_24_regOut_C),
    .regOut_L      (pmacfgs_24_regOut_L)
  );
  Pma25cfgModule pmacfgs_25 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[1]),
    .rdata         (pmacfgs_25_rdata),
    .regOut_R      (pmacfgs_25_regOut_R),
    .regOut_W      (pmacfgs_25_regOut_W),
    .regOut_X      (pmacfgs_25_regOut_X),
    .regOut_A      (pmacfgs_25_regOut_A),
    .regOut_ATOMIC (pmacfgs_25_regOut_ATOMIC),
    .regOut_C      (pmacfgs_25_regOut_C),
    .regOut_L      (pmacfgs_25_regOut_L)
  );
  Pma26cfgModule pmacfgs_26 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[2]),
    .rdata         (pmacfgs_26_rdata),
    .regOut_R      (pmacfgs_26_regOut_R),
    .regOut_W      (pmacfgs_26_regOut_W),
    .regOut_X      (pmacfgs_26_regOut_X),
    .regOut_A      (pmacfgs_26_regOut_A),
    .regOut_ATOMIC (pmacfgs_26_regOut_ATOMIC),
    .regOut_C      (pmacfgs_26_regOut_C),
    .regOut_L      (pmacfgs_26_regOut_L)
  );
  Pma27cfgModule pmacfgs_27 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[3]),
    .rdata         (pmacfgs_27_rdata),
    .regOut_R      (pmacfgs_27_regOut_R),
    .regOut_W      (pmacfgs_27_regOut_W),
    .regOut_X      (pmacfgs_27_regOut_X),
    .regOut_A      (pmacfgs_27_regOut_A),
    .regOut_ATOMIC (pmacfgs_27_regOut_ATOMIC),
    .regOut_C      (pmacfgs_27_regOut_C),
    .regOut_L      (pmacfgs_27_regOut_L)
  );
  Pma28cfgModule pmacfgs_28 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[4]),
    .rdata         (pmacfgs_28_rdata),
    .regOut_R      (pmacfgs_28_regOut_R),
    .regOut_W      (pmacfgs_28_regOut_W),
    .regOut_X      (pmacfgs_28_regOut_X),
    .regOut_A      (pmacfgs_28_regOut_A),
    .regOut_ATOMIC (pmacfgs_28_regOut_ATOMIC),
    .regOut_C      (pmacfgs_28_regOut_C),
    .regOut_L      (pmacfgs_28_regOut_L)
  );
  Pma29cfgModule pmacfgs_29 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[5]),
    .rdata         (pmacfgs_29_rdata),
    .regOut_R      (pmacfgs_29_regOut_R),
    .regOut_W      (pmacfgs_29_regOut_W),
    .regOut_X      (pmacfgs_29_regOut_X),
    .regOut_A      (pmacfgs_29_regOut_A),
    .regOut_ATOMIC (pmacfgs_29_regOut_ATOMIC),
    .regOut_C      (pmacfgs_29_regOut_C),
    .regOut_L      (pmacfgs_29_regOut_L)
  );
  Pma30cfgModule pmacfgs_30 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[6]),
    .rdata         (pmacfgs_30_rdata),
    .regOut_R      (pmacfgs_30_regOut_R),
    .regOut_W      (pmacfgs_30_regOut_W),
    .regOut_X      (pmacfgs_30_regOut_X),
    .regOut_A      (pmacfgs_30_regOut_A),
    .regOut_ATOMIC (pmacfgs_30_regOut_ATOMIC),
    .regOut_C      (pmacfgs_30_regOut_C),
    .regOut_L      (pmacfgs_30_regOut_L)
  );
  Pma31cfgModule pmacfgs_31 (
    .clock         (clock),
    .reset         (reset),
    .w_wen         (wen_pmacfg_3),
    .w_wdata       (pmacfg_byte_wdata[7]),
    .rdata         (pmacfgs_31_rdata),
    .regOut_R      (pmacfgs_31_regOut_R),
    .regOut_W      (pmacfgs_31_regOut_W),
    .regOut_X      (pmacfgs_31_regOut_X),
    .regOut_A      (pmacfgs_31_regOut_A),
    .regOut_ATOMIC (pmacfgs_31_regOut_ATOMIC),
    .regOut_C      (pmacfgs_31_regOut_C),
    .regOut_L      (pmacfgs_31_regOut_L)
  );
  Pmaaddr0Module pmaaddr_0 (
    .rdata       (pmaaddr_0_rdata),
    .regOut_ALL  (pmaaddr_0_regOut_ALL),
    .addrRData_0 (pmaEntryMod_io_out_pmaAddrRData_0)
  );
  Pmaaddr1Module pmaaddr_1 (
    .rdata       (pmaaddr_1_rdata),
    .regOut_ALL  (pmaaddr_1_regOut_ALL),
    .addrRData_1 (pmaEntryMod_io_out_pmaAddrRData_1)
  );
  Pmaaddr2Module pmaaddr_2 (
    .rdata       (pmaaddr_2_rdata),
    .regOut_ALL  (pmaaddr_2_regOut_ALL),
    .addrRData_2 (pmaEntryMod_io_out_pmaAddrRData_2)
  );
  Pmaaddr3Module pmaaddr_3 (
    .rdata       (pmaaddr_3_rdata),
    .regOut_ALL  (pmaaddr_3_regOut_ALL),
    .addrRData_3 (pmaEntryMod_io_out_pmaAddrRData_3)
  );
  Pmaaddr4Module pmaaddr_4 (
    .rdata       (pmaaddr_4_rdata),
    .regOut_ALL  (pmaaddr_4_regOut_ALL),
    .addrRData_4 (pmaEntryMod_io_out_pmaAddrRData_4)
  );
  Pmaaddr5Module pmaaddr_5 (
    .rdata       (pmaaddr_5_rdata),
    .regOut_ALL  (pmaaddr_5_regOut_ALL),
    .addrRData_5 (pmaEntryMod_io_out_pmaAddrRData_5)
  );
  Pmaaddr6Module pmaaddr_6 (
    .rdata       (pmaaddr_6_rdata),
    .regOut_ALL  (pmaaddr_6_regOut_ALL),
    .addrRData_6 (pmaEntryMod_io_out_pmaAddrRData_6)
  );
  Pmaaddr7Module pmaaddr_7 (
    .rdata       (pmaaddr_7_rdata),
    .regOut_ALL  (pmaaddr_7_regOut_ALL),
    .addrRData_7 (pmaEntryMod_io_out_pmaAddrRData_7)
  );
  Pmaaddr8Module pmaaddr_8 (
    .rdata       (pmaaddr_8_rdata),
    .regOut_ALL  (pmaaddr_8_regOut_ALL),
    .addrRData_8 (pmaEntryMod_io_out_pmaAddrRData_8)
  );
  Pmaaddr9Module pmaaddr_9 (
    .rdata       (pmaaddr_9_rdata),
    .regOut_ALL  (pmaaddr_9_regOut_ALL),
    .addrRData_9 (pmaEntryMod_io_out_pmaAddrRData_9)
  );
  Pmaaddr10Module pmaaddr_10 (
    .rdata        (pmaaddr_10_rdata),
    .regOut_ALL   (pmaaddr_10_regOut_ALL),
    .addrRData_10 (pmaEntryMod_io_out_pmaAddrRData_10)
  );
  Pmaaddr11Module pmaaddr_11 (
    .rdata        (pmaaddr_11_rdata),
    .regOut_ALL   (pmaaddr_11_regOut_ALL),
    .addrRData_11 (pmaEntryMod_io_out_pmaAddrRData_11)
  );
  Pmaaddr12Module pmaaddr_12 (
    .rdata        (pmaaddr_12_rdata),
    .regOut_ALL   (pmaaddr_12_regOut_ALL),
    .addrRData_12 (pmaEntryMod_io_out_pmaAddrRData_12)
  );
  Pmaaddr13Module pmaaddr_13 (
    .rdata        (pmaaddr_13_rdata),
    .regOut_ALL   (pmaaddr_13_regOut_ALL),
    .addrRData_13 (pmaEntryMod_io_out_pmaAddrRData_13)
  );
  Pmaaddr14Module pmaaddr_14 (
    .rdata        (pmaaddr_14_rdata),
    .regOut_ALL   (pmaaddr_14_regOut_ALL),
    .addrRData_14 (pmaEntryMod_io_out_pmaAddrRData_14)
  );
  Pmaaddr15Module pmaaddr_15 (
    .rdata        (pmaaddr_15_rdata),
    .regOut_ALL   (pmaaddr_15_regOut_ALL),
    .addrRData_15 (pmaEntryMod_io_out_pmaAddrRData_15)
  );
  Pmaaddr16Module pmaaddr_16 (
    .rdata        (pmaaddr_16_rdata),
    .regOut_ALL   (pmaaddr_16_regOut_ALL),
    .addrRData_16 (pmaEntryMod_io_out_pmaAddrRData_16)
  );
  Pmaaddr17Module pmaaddr_17 (
    .rdata        (pmaaddr_17_rdata),
    .regOut_ALL   (pmaaddr_17_regOut_ALL),
    .addrRData_17 (pmaEntryMod_io_out_pmaAddrRData_17)
  );
  Pmaaddr18Module pmaaddr_18 (
    .rdata        (pmaaddr_18_rdata),
    .regOut_ALL   (pmaaddr_18_regOut_ALL),
    .addrRData_18 (pmaEntryMod_io_out_pmaAddrRData_18)
  );
  Pmaaddr19Module pmaaddr_19 (
    .rdata        (pmaaddr_19_rdata),
    .regOut_ALL   (pmaaddr_19_regOut_ALL),
    .addrRData_19 (pmaEntryMod_io_out_pmaAddrRData_19)
  );
  Pmaaddr20Module pmaaddr_20 (
    .rdata        (pmaaddr_20_rdata),
    .regOut_ALL   (pmaaddr_20_regOut_ALL),
    .addrRData_20 (pmaEntryMod_io_out_pmaAddrRData_20)
  );
  Pmaaddr21Module pmaaddr_21 (
    .rdata        (pmaaddr_21_rdata),
    .regOut_ALL   (pmaaddr_21_regOut_ALL),
    .addrRData_21 (pmaEntryMod_io_out_pmaAddrRData_21)
  );
  Pmaaddr22Module pmaaddr_22 (
    .rdata        (pmaaddr_22_rdata),
    .regOut_ALL   (pmaaddr_22_regOut_ALL),
    .addrRData_22 (pmaEntryMod_io_out_pmaAddrRData_22)
  );
  Pmaaddr23Module pmaaddr_23 (
    .rdata        (pmaaddr_23_rdata),
    .regOut_ALL   (pmaaddr_23_regOut_ALL),
    .addrRData_23 (pmaEntryMod_io_out_pmaAddrRData_23)
  );
  Pmaaddr24Module pmaaddr_24 (
    .rdata        (pmaaddr_24_rdata),
    .regOut_ALL   (pmaaddr_24_regOut_ALL),
    .addrRData_24 (pmaEntryMod_io_out_pmaAddrRData_24)
  );
  Pmaaddr25Module pmaaddr_25 (
    .rdata        (pmaaddr_25_rdata),
    .regOut_ALL   (pmaaddr_25_regOut_ALL),
    .addrRData_25 (pmaEntryMod_io_out_pmaAddrRData_25)
  );
  Pmaaddr26Module pmaaddr_26 (
    .rdata        (pmaaddr_26_rdata),
    .regOut_ALL   (pmaaddr_26_regOut_ALL),
    .addrRData_26 (pmaEntryMod_io_out_pmaAddrRData_26)
  );
  Pmaaddr27Module pmaaddr_27 (
    .rdata        (pmaaddr_27_rdata),
    .regOut_ALL   (pmaaddr_27_regOut_ALL),
    .addrRData_27 (pmaEntryMod_io_out_pmaAddrRData_27)
  );
  Pmaaddr28Module pmaaddr_28 (
    .rdata        (pmaaddr_28_rdata),
    .regOut_ALL   (pmaaddr_28_regOut_ALL),
    .addrRData_28 (pmaEntryMod_io_out_pmaAddrRData_28)
  );
  Pmaaddr29Module pmaaddr_29 (
    .rdata        (pmaaddr_29_rdata),
    .regOut_ALL   (pmaaddr_29_regOut_ALL),
    .addrRData_29 (pmaEntryMod_io_out_pmaAddrRData_29)
  );
  Pmaaddr30Module pmaaddr_30 (
    .rdata        (pmaaddr_30_rdata),
    .regOut_ALL   (pmaaddr_30_regOut_ALL),
    .addrRData_30 (pmaEntryMod_io_out_pmaAddrRData_30)
  );
  Pmaaddr31Module pmaaddr_31 (
    .rdata        (pmaaddr_31_rdata),
    .regOut_ALL   (pmaaddr_31_regOut_ALL),
    .addrRData_31 (pmaEntryMod_io_out_pmaAddrRData_31)
  );
  CSRPermitModule permitMod (
    .io_in_csrAccess_ren              (permit_ren),
    .io_in_csrAccess_wen              (wen),
    .io_in_csrAccess_addr             (io_in_bits_addr),
    .io_in_privState_PRVM             (prvm),
    .io_in_privState_V                (virt),
    .io_in_debugMode                  (debug_mode),
    .io_in_xRet_mnret                 (xret_mnret),
    .io_in_xRet_mret                  (xret_mret),
    .io_in_xRet_sret                  (xret_sret),
    .io_in_xRet_dret                  (xret_dret),
    .io_in_status_tsr                 (mstatus_regOut_TSR),
    .io_in_status_vtsr                (hstatus_regOut_VTSR),
    .io_in_status_tvm                 (mstatus_regOut_TVM),
    .io_in_status_vtvm                (hstatus_regOut_VTVM),
    .io_in_status_vgein               (hstatus_regOut_VGEIN),
    .io_in_status_mstatusFSOff        (mstatus_fs_off),
    .io_in_status_vsstatusFSOff       (vsstatus_fs_off),
    .io_in_status_mstatusVSOff        (mstatus_vs_off),
    .io_in_status_vsstatusVSOff       (vsstatus_vs_off),
    .io_in_xcounteren_mcounteren      (mcounteren_rdata[31:0]),
    .io_in_xcounteren_hcounteren      (hcounteren_rdata[31:0]),
    .io_in_xcounteren_scounteren      (scounteren_rdata[31:0]),
    .io_in_xenvcfg_menvcfg            (menvcfg_rdata),
    .io_in_xenvcfg_henvcfg            (henvcfg_rdata),
    .io_in_xstateen_mstateen0_SE0     (mstateen0_rdata[63]),
    .io_in_xstateen_mstateen0_ENVCFG  (mstateen0_rdata[62]),
    .io_in_xstateen_mstateen0_CSRIND  (mstateen0_rdata[60]),
    .io_in_xstateen_mstateen0_AIA     (mstateen0_rdata[59]),
    .io_in_xstateen_mstateen0_IMSIC   (mstateen0_rdata[58]),
    .io_in_xstateen_mstateen0_CONTEXT (mstateen0_rdata[57]),
    .io_in_xstateen_mstateen0_C       (mstateen0_rdata[0]),
    .io_in_xstateen_mstateen1_SE      (mstateen1_rdata[63]),
    .io_in_xstateen_mstateen2_SE      (mstateen2_rdata[63]),
    .io_in_xstateen_mstateen3_SE      (mstateen3_rdata[63]),
    .io_in_xstateen_hstateen0_C       (hstateen0_rdata[0]),
    .io_in_xstateen_hstateen0_SE0     (hstateen0_rdata[63]),
    .io_in_xstateen_hstateen0_ENVCFG  (hstateen0_rdata[62]),
    .io_in_xstateen_hstateen0_CSRIND  (hstateen0_rdata[60]),
    .io_in_xstateen_hstateen0_AIA     (hstateen0_rdata[59]),
    .io_in_xstateen_hstateen0_IMSIC   (hstateen0_rdata[58]),
    .io_in_xstateen_hstateen0_CONTEXT (hstateen0_rdata[57]),
    .io_in_xstateen_hstateen1_SE      (hstateen1_rdata[63]),
    .io_in_xstateen_hstateen2_SE      (hstateen2_rdata[63]),
    .io_in_xstateen_hstateen3_SE      (hstateen3_rdata[63]),
    .io_in_xstateen_sstateen0_C       (sstateen0_rdata[0]),
    .io_in_aia_miselect               (miselect_rdata),
    .io_in_aia_siselect               (siselect_rdata),
    .io_in_aia_vsiselect              (vsiselect_rdata),
    .io_in_aia_mvienSEIE              (mvien_regOut_SEIE),
    .io_in_aia_hvictlVTI              (hvictl_regOut_VTI),
    .io_out_hasLegalWen               (permitMod_io_out_hasLegalWen),
    .io_out_hasLegalMNret             (permitMod_io_out_hasLegalMNret),
    .io_out_hasLegalMret              (permitMod_io_out_hasLegalMret),
    .io_out_hasLegalSret              (permitMod_io_out_hasLegalSret),
    .io_out_hasLegalDret              (permitMod_io_out_hasLegalDret),
    .io_out_hasLegalWriteFcsr         (permitMod_io_out_hasLegalWriteFcsr),
    .io_out_hasLegalWriteVcsr         (permitMod_io_out_hasLegalWriteVcsr),
    .io_out_EX_II                     (permitMod_io_out_EX_II),
    .io_out_EX_VI                     (permitMod_io_out_EX_VI)
  );
  SstcInterruptGen sstcIRGen (
    .clock             (clock),
    .reset             (reset),
    .i_stime_valid     (time_0_updated),
    .i_stime_bits      (time_0_stime),
    .i_vstime_valid    (time_0_updated),
    .i_vstime_bits     (time_0_vstime),
    .i_stimecmp_wen    (sstc_stimecmp_wen_q),
    .i_stimecmp_rdata  (stimecmp_rdata),
    .i_vstimecmp_wen   (sstc_vstimecmp_wen_q),
    .i_vstimecmp_rdata (vstimecmp_rdata),
    .i_htimedeltaWen   (sstc_htimedelta_wen_q),
    .i_menvcfg_wen     (sstc_menvcfg_wen_q),
    .i_menvcfg_STCE    (menvcfg_regOut_STCE),
    .i_henvcfg_wen     (sstc_henvcfg_wen_q),
    .i_henvcfg_STCE    (henvcfg_regOut_STCE),
    .o_STIP            (sstcIRGen_o_STIP),
    .o_VSTIP           (sstcIRGen_o_VSTIP)
  );
  CommitIDModule commidIdMod (
    .io_hartId (io_fromTop_hartId)
  );
  InterruptFilter intrMod (
    .clock                                 (clock),
    .reset                                 (reset),
    .io_in_privState_PRVM                  (prvm),
    .io_in_privState_V                     (virt),
    .io_in_mstatusMIE                      (mstatus_regOut_MIE),
    .io_in_sstatusSIE                      (mstatus_regOut_SIE),
    .io_in_vsstatusSIE                     (vsstatus_regOut_SIE),
    .io_in_mip_SSIP                        (mip_rdataFields_SSIP),
    .io_in_mip_VSSIP                       (mip_rdataFields_VSSIP),
    .io_in_mip_MSIP                        (mip_rdataFields_MSIP),
    .io_in_mip_STIP                        (mip_rdataFields_STIP),
    .io_in_mip_VSTIP                       (mip_rdataFields_VSTIP),
    .io_in_mip_MTIP                        (mip_rdataFields_MTIP),
    .io_in_mip_SEIP                        (mip_rdataFields_SEIP),
    .io_in_mip_VSEIP                       (mip_rdataFields_VSEIP),
    .io_in_mip_MEIP                        (mip_rdataFields_MEIP),
    .io_in_mip_SGEIP                       (mip_rdataFields_SGEIP),
    .io_in_mip_LCOFIP                      (mip_rdataFields_LCOFIP),
    .io_in_mie_SSIE                        (mie_regOut_SSIE),
    .io_in_mie_VSSIE                       (mie_regOut_VSSIE),
    .io_in_mie_MSIE                        (mie_regOut_MSIE),
    .io_in_mie_STIE                        (mie_regOut_STIE),
    .io_in_mie_VSTIE                       (mie_regOut_VSTIE),
    .io_in_mie_MTIE                        (mie_regOut_MTIE),
    .io_in_mie_SEIE                        (mie_regOut_SEIE),
    .io_in_mie_VSEIE                       (mie_regOut_VSEIE),
    .io_in_mie_MEIE                        (mie_regOut_MEIE),
    .io_in_mie_SGEIE                       (mie_regOut_SGEIE),
    .io_in_mie_LCOFIE                      (mie_regOut_LCOFIE),
    .io_in_mideleg_SSI                     (mideleg_regOut_SSI),
    .io_in_mideleg_STI                     (mideleg_regOut_STI),
    .io_in_mideleg_SEI                     (mideleg_regOut_SEI),
    .io_in_mideleg_LCOFI                   (mideleg_regOut_LCOFI),
    .io_in_sip_SSIP                        (sip_regOut_SSIP),
    .io_in_sip_STIP                        (sip_regOut_STIP),
    .io_in_sip_SEIP                        (sip_regOut_SEIP),
    .io_in_sip_LCOFIP                      (sip_regOut_LCOFIP),
    .io_in_sip_LC14IP                      (sip_regOut_LC14IP),
    .io_in_sip_LC15IP                      (sip_regOut_LC15IP),
    .io_in_sip_LC16IP                      (sip_regOut_LC16IP),
    .io_in_sip_LC17IP                      (sip_regOut_LC17IP),
    .io_in_sip_LC18IP                      (sip_regOut_LC18IP),
    .io_in_sip_LC19IP                      (sip_regOut_LC19IP),
    .io_in_sip_LC20IP                      (sip_regOut_LC20IP),
    .io_in_sip_LC21IP                      (sip_regOut_LC21IP),
    .io_in_sip_LC22IP                      (sip_regOut_LC22IP),
    .io_in_sip_LC23IP                      (sip_regOut_LC23IP),
    .io_in_sip_LC24IP                      (sip_regOut_LC24IP),
    .io_in_sip_LC25IP                      (sip_regOut_LC25IP),
    .io_in_sip_LC26IP                      (sip_regOut_LC26IP),
    .io_in_sip_LC27IP                      (sip_regOut_LC27IP),
    .io_in_sip_LC28IP                      (sip_regOut_LC28IP),
    .io_in_sip_LC29IP                      (sip_regOut_LC29IP),
    .io_in_sip_LC30IP                      (sip_regOut_LC30IP),
    .io_in_sip_LC31IP                      (sip_regOut_LC31IP),
    .io_in_sip_LC32IP                      (sip_regOut_LC32IP),
    .io_in_sip_LC33IP                      (sip_regOut_LC33IP),
    .io_in_sip_LC34IP                      (sip_regOut_LC34IP),
    .io_in_sip_LPRASEIP                    (sip_regOut_LPRASEIP),
    .io_in_sip_LC36IP                      (sip_regOut_LC36IP),
    .io_in_sip_LC37IP                      (sip_regOut_LC37IP),
    .io_in_sip_LC38IP                      (sip_regOut_LC38IP),
    .io_in_sip_LC39IP                      (sip_regOut_LC39IP),
    .io_in_sip_LC40IP                      (sip_regOut_LC40IP),
    .io_in_sip_LC41IP                      (sip_regOut_LC41IP),
    .io_in_sip_LC42IP                      (sip_regOut_LC42IP),
    .io_in_sip_HPRASEIP                    (sip_regOut_HPRASEIP),
    .io_in_sip_LC44IP                      (sip_regOut_LC44IP),
    .io_in_sip_LC45IP                      (sip_regOut_LC45IP),
    .io_in_sip_LC46IP                      (sip_regOut_LC46IP),
    .io_in_sip_LC47IP                      (sip_regOut_LC47IP),
    .io_in_sip_LC48IP                      (sip_regOut_LC48IP),
    .io_in_sip_LC49IP                      (sip_regOut_LC49IP),
    .io_in_sip_LC50IP                      (sip_regOut_LC50IP),
    .io_in_sip_LC51IP                      (sip_regOut_LC51IP),
    .io_in_sip_LC52IP                      (sip_regOut_LC52IP),
    .io_in_sip_LC53IP                      (sip_regOut_LC53IP),
    .io_in_sip_LC54IP                      (sip_regOut_LC54IP),
    .io_in_sip_LC55IP                      (sip_regOut_LC55IP),
    .io_in_sip_LC56IP                      (sip_regOut_LC56IP),
    .io_in_sip_LC57IP                      (sip_regOut_LC57IP),
    .io_in_sip_LC58IP                      (sip_regOut_LC58IP),
    .io_in_sip_LC59IP                      (sip_regOut_LC59IP),
    .io_in_sip_LC60IP                      (sip_regOut_LC60IP),
    .io_in_sip_LC61IP                      (sip_regOut_LC61IP),
    .io_in_sip_LC62IP                      (sip_regOut_LC62IP),
    .io_in_sip_LC63IP                      (sip_regOut_LC63IP),
    .io_in_sie_SSIE                        (sie_regOut_SSIE),
    .io_in_sie_STIE                        (sie_regOut_STIE),
    .io_in_sie_SEIE                        (sie_regOut_SEIE),
    .io_in_sie_LCOFIE                      (sie_regOut_LCOFIE),
    .io_in_sie_LC14IE                      (sie_regOut_LC14IE),
    .io_in_sie_LC15IE                      (sie_regOut_LC15IE),
    .io_in_sie_LC16IE                      (sie_regOut_LC16IE),
    .io_in_sie_LC17IE                      (sie_regOut_LC17IE),
    .io_in_sie_LC18IE                      (sie_regOut_LC18IE),
    .io_in_sie_LC19IE                      (sie_regOut_LC19IE),
    .io_in_sie_LC20IE                      (sie_regOut_LC20IE),
    .io_in_sie_LC21IE                      (sie_regOut_LC21IE),
    .io_in_sie_LC22IE                      (sie_regOut_LC22IE),
    .io_in_sie_LC23IE                      (sie_regOut_LC23IE),
    .io_in_sie_LC24IE                      (sie_regOut_LC24IE),
    .io_in_sie_LC25IE                      (sie_regOut_LC25IE),
    .io_in_sie_LC26IE                      (sie_regOut_LC26IE),
    .io_in_sie_LC27IE                      (sie_regOut_LC27IE),
    .io_in_sie_LC28IE                      (sie_regOut_LC28IE),
    .io_in_sie_LC29IE                      (sie_regOut_LC29IE),
    .io_in_sie_LC30IE                      (sie_regOut_LC30IE),
    .io_in_sie_LC31IE                      (sie_regOut_LC31IE),
    .io_in_sie_LC32IE                      (sie_regOut_LC32IE),
    .io_in_sie_LC33IE                      (sie_regOut_LC33IE),
    .io_in_sie_LC34IE                      (sie_regOut_LC34IE),
    .io_in_sie_LPRASEIE                    (sie_regOut_LPRASEIE),
    .io_in_sie_LC36IE                      (sie_regOut_LC36IE),
    .io_in_sie_LC37IE                      (sie_regOut_LC37IE),
    .io_in_sie_LC38IE                      (sie_regOut_LC38IE),
    .io_in_sie_LC39IE                      (sie_regOut_LC39IE),
    .io_in_sie_LC40IE                      (sie_regOut_LC40IE),
    .io_in_sie_LC41IE                      (sie_regOut_LC41IE),
    .io_in_sie_LC42IE                      (sie_regOut_LC42IE),
    .io_in_sie_HPRASEIE                    (sie_regOut_HPRASEIE),
    .io_in_sie_LC44IE                      (sie_regOut_LC44IE),
    .io_in_sie_LC45IE                      (sie_regOut_LC45IE),
    .io_in_sie_LC46IE                      (sie_regOut_LC46IE),
    .io_in_sie_LC47IE                      (sie_regOut_LC47IE),
    .io_in_sie_LC48IE                      (sie_regOut_LC48IE),
    .io_in_sie_LC49IE                      (sie_regOut_LC49IE),
    .io_in_sie_LC50IE                      (sie_regOut_LC50IE),
    .io_in_sie_LC51IE                      (sie_regOut_LC51IE),
    .io_in_sie_LC52IE                      (sie_regOut_LC52IE),
    .io_in_sie_LC53IE                      (sie_regOut_LC53IE),
    .io_in_sie_LC54IE                      (sie_regOut_LC54IE),
    .io_in_sie_LC55IE                      (sie_regOut_LC55IE),
    .io_in_sie_LC56IE                      (sie_regOut_LC56IE),
    .io_in_sie_LC57IE                      (sie_regOut_LC57IE),
    .io_in_sie_LC58IE                      (sie_regOut_LC58IE),
    .io_in_sie_LC59IE                      (sie_regOut_LC59IE),
    .io_in_sie_LC60IE                      (sie_regOut_LC60IE),
    .io_in_sie_LC61IE                      (sie_regOut_LC61IE),
    .io_in_sie_LC62IE                      (sie_regOut_LC62IE),
    .io_in_sie_LC63IE                      (sie_regOut_LC63IE),
    .io_in_hip_VSSIP                       (hip_regOut_VSSIP),
    .io_in_hip_VSTIP                       (hip_regOut_VSTIP),
    .io_in_hip_VSEIP                       (hip_regOut_VSEIP),
    .io_in_hip_SGEIP                       (hip_regOut_SGEIP),
    .io_in_hie_VSSIE                       (hie_regOut_VSSIE),
    .io_in_hie_VSTIE                       (hie_regOut_VSTIE),
    .io_in_hie_VSEIE                       (hie_regOut_VSEIE),
    .io_in_hie_SGEIE                       (hie_regOut_SGEIE),
    .io_in_hideleg_SSI                     (hideleg_regOut_SSI),
    .io_in_hideleg_VSSI                    (hideleg_regOut_VSSI),
    .io_in_hideleg_MSI                     (hideleg_regOut_MSI),
    .io_in_hideleg_STI                     (hideleg_regOut_STI),
    .io_in_hideleg_VSTI                    (hideleg_regOut_VSTI),
    .io_in_hideleg_MTI                     (hideleg_regOut_MTI),
    .io_in_hideleg_SEI                     (hideleg_regOut_SEI),
    .io_in_hideleg_VSEI                    (hideleg_regOut_VSEI),
    .io_in_hideleg_MEI                     (hideleg_regOut_MEI),
    .io_in_hideleg_SGEI                    (hideleg_regOut_SGEI),
    .io_in_hideleg_LCOFI                   (hideleg_regOut_LCOFI),
    .io_in_vsip_SSIP                       (vsip_regOut_SSIP),
    .io_in_vsip_STIP                       (vsip_regOut_STIP),
    .io_in_vsip_SEIP                       (vsip_regOut_SEIP),
    .io_in_vsip_LCOFIP                     (vsip_regOut_LCOFIP),
    .io_in_vsip_LC14IP                     (vsip_regOut_LC14IP),
    .io_in_vsip_LC15IP                     (vsip_regOut_LC15IP),
    .io_in_vsip_LC16IP                     (vsip_regOut_LC16IP),
    .io_in_vsip_LC17IP                     (vsip_regOut_LC17IP),
    .io_in_vsip_LC18IP                     (vsip_regOut_LC18IP),
    .io_in_vsip_LC19IP                     (vsip_regOut_LC19IP),
    .io_in_vsip_LC20IP                     (vsip_regOut_LC20IP),
    .io_in_vsip_LC21IP                     (vsip_regOut_LC21IP),
    .io_in_vsip_LC22IP                     (vsip_regOut_LC22IP),
    .io_in_vsip_LC23IP                     (vsip_regOut_LC23IP),
    .io_in_vsip_LC24IP                     (vsip_regOut_LC24IP),
    .io_in_vsip_LC25IP                     (vsip_regOut_LC25IP),
    .io_in_vsip_LC26IP                     (vsip_regOut_LC26IP),
    .io_in_vsip_LC27IP                     (vsip_regOut_LC27IP),
    .io_in_vsip_LC28IP                     (vsip_regOut_LC28IP),
    .io_in_vsip_LC29IP                     (vsip_regOut_LC29IP),
    .io_in_vsip_LC30IP                     (vsip_regOut_LC30IP),
    .io_in_vsip_LC31IP                     (vsip_regOut_LC31IP),
    .io_in_vsip_LC32IP                     (vsip_regOut_LC32IP),
    .io_in_vsip_LC33IP                     (vsip_regOut_LC33IP),
    .io_in_vsip_LC34IP                     (vsip_regOut_LC34IP),
    .io_in_vsip_LPRASEIP                   (vsip_regOut_LPRASEIP),
    .io_in_vsip_LC36IP                     (vsip_regOut_LC36IP),
    .io_in_vsip_LC37IP                     (vsip_regOut_LC37IP),
    .io_in_vsip_LC38IP                     (vsip_regOut_LC38IP),
    .io_in_vsip_LC39IP                     (vsip_regOut_LC39IP),
    .io_in_vsip_LC40IP                     (vsip_regOut_LC40IP),
    .io_in_vsip_LC41IP                     (vsip_regOut_LC41IP),
    .io_in_vsip_LC42IP                     (vsip_regOut_LC42IP),
    .io_in_vsip_HPRASEIP                   (vsip_regOut_HPRASEIP),
    .io_in_vsip_LC44IP                     (vsip_regOut_LC44IP),
    .io_in_vsip_LC45IP                     (vsip_regOut_LC45IP),
    .io_in_vsip_LC46IP                     (vsip_regOut_LC46IP),
    .io_in_vsip_LC47IP                     (vsip_regOut_LC47IP),
    .io_in_vsip_LC48IP                     (vsip_regOut_LC48IP),
    .io_in_vsip_LC49IP                     (vsip_regOut_LC49IP),
    .io_in_vsip_LC50IP                     (vsip_regOut_LC50IP),
    .io_in_vsip_LC51IP                     (vsip_regOut_LC51IP),
    .io_in_vsip_LC52IP                     (vsip_regOut_LC52IP),
    .io_in_vsip_LC53IP                     (vsip_regOut_LC53IP),
    .io_in_vsip_LC54IP                     (vsip_regOut_LC54IP),
    .io_in_vsip_LC55IP                     (vsip_regOut_LC55IP),
    .io_in_vsip_LC56IP                     (vsip_regOut_LC56IP),
    .io_in_vsip_LC57IP                     (vsip_regOut_LC57IP),
    .io_in_vsip_LC58IP                     (vsip_regOut_LC58IP),
    .io_in_vsip_LC59IP                     (vsip_regOut_LC59IP),
    .io_in_vsip_LC60IP                     (vsip_regOut_LC60IP),
    .io_in_vsip_LC61IP                     (vsip_regOut_LC61IP),
    .io_in_vsip_LC62IP                     (vsip_regOut_LC62IP),
    .io_in_vsip_LC63IP                     (vsip_regOut_LC63IP),
    .io_in_vsie_SSIE                       (vsie_regOut_SSIE),
    .io_in_vsie_STIE                       (vsie_regOut_STIE),
    .io_in_vsie_SEIE                       (vsie_regOut_SEIE),
    .io_in_vsie_LCOFIE                     (vsie_regOut_LCOFIE),
    .io_in_vsie_LC14IE                     (vsie_regOut_LC14IE),
    .io_in_vsie_LC15IE                     (vsie_regOut_LC15IE),
    .io_in_vsie_LC16IE                     (vsie_regOut_LC16IE),
    .io_in_vsie_LC17IE                     (vsie_regOut_LC17IE),
    .io_in_vsie_LC18IE                     (vsie_regOut_LC18IE),
    .io_in_vsie_LC19IE                     (vsie_regOut_LC19IE),
    .io_in_vsie_LC20IE                     (vsie_regOut_LC20IE),
    .io_in_vsie_LC21IE                     (vsie_regOut_LC21IE),
    .io_in_vsie_LC22IE                     (vsie_regOut_LC22IE),
    .io_in_vsie_LC23IE                     (vsie_regOut_LC23IE),
    .io_in_vsie_LC24IE                     (vsie_regOut_LC24IE),
    .io_in_vsie_LC25IE                     (vsie_regOut_LC25IE),
    .io_in_vsie_LC26IE                     (vsie_regOut_LC26IE),
    .io_in_vsie_LC27IE                     (vsie_regOut_LC27IE),
    .io_in_vsie_LC28IE                     (vsie_regOut_LC28IE),
    .io_in_vsie_LC29IE                     (vsie_regOut_LC29IE),
    .io_in_vsie_LC30IE                     (vsie_regOut_LC30IE),
    .io_in_vsie_LC31IE                     (vsie_regOut_LC31IE),
    .io_in_vsie_LC32IE                     (vsie_regOut_LC32IE),
    .io_in_vsie_LC33IE                     (vsie_regOut_LC33IE),
    .io_in_vsie_LC34IE                     (vsie_regOut_LC34IE),
    .io_in_vsie_LPRASEIE                   (vsie_regOut_LPRASEIE),
    .io_in_vsie_LC36IE                     (vsie_regOut_LC36IE),
    .io_in_vsie_LC37IE                     (vsie_regOut_LC37IE),
    .io_in_vsie_LC38IE                     (vsie_regOut_LC38IE),
    .io_in_vsie_LC39IE                     (vsie_regOut_LC39IE),
    .io_in_vsie_LC40IE                     (vsie_regOut_LC40IE),
    .io_in_vsie_LC41IE                     (vsie_regOut_LC41IE),
    .io_in_vsie_LC42IE                     (vsie_regOut_LC42IE),
    .io_in_vsie_HPRASEIE                   (vsie_regOut_HPRASEIE),
    .io_in_vsie_LC44IE                     (vsie_regOut_LC44IE),
    .io_in_vsie_LC45IE                     (vsie_regOut_LC45IE),
    .io_in_vsie_LC46IE                     (vsie_regOut_LC46IE),
    .io_in_vsie_LC47IE                     (vsie_regOut_LC47IE),
    .io_in_vsie_LC48IE                     (vsie_regOut_LC48IE),
    .io_in_vsie_LC49IE                     (vsie_regOut_LC49IE),
    .io_in_vsie_LC50IE                     (vsie_regOut_LC50IE),
    .io_in_vsie_LC51IE                     (vsie_regOut_LC51IE),
    .io_in_vsie_LC52IE                     (vsie_regOut_LC52IE),
    .io_in_vsie_LC53IE                     (vsie_regOut_LC53IE),
    .io_in_vsie_LC54IE                     (vsie_regOut_LC54IE),
    .io_in_vsie_LC55IE                     (vsie_regOut_LC55IE),
    .io_in_vsie_LC56IE                     (vsie_regOut_LC56IE),
    .io_in_vsie_LC57IE                     (vsie_regOut_LC57IE),
    .io_in_vsie_LC58IE                     (vsie_regOut_LC58IE),
    .io_in_vsie_LC59IE                     (vsie_regOut_LC59IE),
    .io_in_vsie_LC60IE                     (vsie_regOut_LC60IE),
    .io_in_vsie_LC61IE                     (vsie_regOut_LC61IE),
    .io_in_vsie_LC62IE                     (vsie_regOut_LC62IE),
    .io_in_vsie_LC63IE                     (vsie_regOut_LC63IE),
    .io_in_hvictl_VTI                      (hvictl_regOut_VTI),
    .io_in_hvictl_IID                      (hvictl_regOut_IID),
    .io_in_hvictl_DPR                      (hvictl_regOut_DPR),
    .io_in_hvictl_IPRIOM                   (hvictl_regOut_IPRIOM),
    .io_in_hvictl_IPRIO                    (hvictl_regOut_IPRIO),
    .io_in_hstatus_VGEIN                   (hstatus_regOut_VGEIN),
    .io_in_mtopei_IPRIO                    (mtopei_regOut_IPRIO),
    .io_in_stopei_IPRIO                    (stopei_regOut_IPRIO),
    .io_in_vstopei_IID                     (vstopei_regOut_IID),
    .io_in_vstopei_IPRIO                   (vstopei_regOut_IPRIO),
    .io_in_hviprio1_PrioSSI                (hviprio1_regOut_PrioSSI),
    .io_in_hviprio1_PrioSTI                (hviprio1_regOut_PrioSTI),
    .io_in_hviprio1_PrioCOI                (hviprio1_regOut_PrioCOI),
    .io_in_hviprio1_Prio14                 (hviprio1_regOut_Prio14),
    .io_in_hviprio1_Prio15                 (hviprio1_regOut_Prio15),
    .io_in_hviprio2_ALL                    (hviprio2_regOut_ALL),
    .io_in_debugIntr                       (debug_intr),
    .io_in_debugMode                       (debug_mode),
    .io_in_dcsr_STEPIE                     (dcsr_regOut_STEPIE),
    .io_in_dcsr_STEP                       (dcsr_regOut_STEP),
    .io_in_miprios                         ({384'h0, miprio2_rdata, miprio0_rdata}),
    .io_in_hsiprios                        ({siprios_5_rdata, siprios_4_rdata, siprios_3_rdata, siprios_2_rdata, siprios_1_rdata, siprios_0_rdata, siprio2_rdata, siprio0_rdata}),
    .io_in_nmi                             (nmi_pending),
    .io_in_nmiVec                          ({20'h0, nmip_43_q, 11'h0, nmip_31_q, 31'h0}),
    .io_in_mnstatusNMIE                    (mnstatus_regOut_NMIE),
    .io_in_platform_meip                   (platformIRP_MEIP),
    .io_in_platform_seip                   (platformIRP_SEIP),
    .io_in_fromAIA_seip                    (fromAIA_seip),
    .io_in_mvienSEIE                       (mvien_regOut_SEIE),
    .io_in_mvipSEIP                        (mvip_regOut_SEIP),
    .io_out_debug                          (intrMod_io_out_debug),
    .io_out_nmi                            (intrMod_io_out_nmi),
    .io_out_interruptVec_valid             (intrMod_io_out_interruptVec_valid),
    .io_out_interruptVec_bits              (intrMod_io_out_interruptVec_bits),
    .io_out_mtopi_IID                      (intrMod_io_out_mtopi_IID),
    .io_out_mtopi_IPRIO                    (intrMod_io_out_mtopi_IPRIO),
    .io_out_stopi_IID                      (intrMod_io_out_stopi_IID),
    .io_out_stopi_IPRIO                    (intrMod_io_out_stopi_IPRIO),
    .io_out_vstopi_IID                     (intrMod_io_out_vstopi_IID),
    .io_out_vstopi_IPRIO                   (intrMod_io_out_vstopi_IPRIO),
    .io_out_virtualInterruptIsHvictlInject (intrMod_io_out_virtualInterruptIsHvictlInject),
    .io_out_irToHS                         (intrMod_io_out_irToHS),
    .io_out_irToVS                         (intrMod_io_out_irToVS)
  );
  TrapHandleModule trapHandleMod (
    .io_in_trapInfo_valid            (io_fromRob_trap_valid),
    .io_in_trapInfo_bits_trapVec     (io_fromRob_trap_bits_trapVec),
    .io_in_trapInfo_bits_intrVec     (intr_vec_q),
    .io_in_trapInfo_bits_isInterrupt (io_fromRob_trap_bits_isInterrupt),
    .io_in_trapInfo_bits_singleStep  (trap_single_step),
    .io_in_trapInfo_bits_irToHS      (ir_to_hs_q),
    .io_in_trapInfo_bits_irToVS      (ir_to_vs_q),
    .io_in_privState_PRVM            (prvm),
    .io_in_privState_V               (virt),
    .io_in_mstatus_MDT               (mstatus_regOut_MDT),
    .io_in_sstatus_SDT               (mstatus_sstatus_SDT),
    .io_in_vsstatus_SDT              (vsstatus_regOut_SDT),
    .io_in_mnstatus_NMIE             (mnstatus_regOut_NMIE),
    .io_in_medeleg_EX_IAM            (medeleg_regOut_EX_IAM),
    .io_in_medeleg_EX_IAF            (medeleg_regOut_EX_IAF),
    .io_in_medeleg_EX_II             (medeleg_regOut_EX_II),
    .io_in_medeleg_EX_BP             (medeleg_regOut_EX_BP),
    .io_in_medeleg_EX_LAM            (medeleg_regOut_EX_LAM),
    .io_in_medeleg_EX_LAF            (medeleg_regOut_EX_LAF),
    .io_in_medeleg_EX_SAM            (medeleg_regOut_EX_SAM),
    .io_in_medeleg_EX_SAF            (medeleg_regOut_EX_SAF),
    .io_in_medeleg_EX_UCALL          (medeleg_regOut_EX_UCALL),
    .io_in_medeleg_EX_HSCALL         (medeleg_regOut_EX_HSCALL),
    .io_in_medeleg_EX_VSCALL         (medeleg_regOut_EX_VSCALL),
    .io_in_medeleg_EX_IPF            (medeleg_regOut_EX_IPF),
    .io_in_medeleg_EX_LPF            (medeleg_regOut_EX_LPF),
    .io_in_medeleg_EX_SPF            (medeleg_regOut_EX_SPF),
    .io_in_medeleg_EX_SWC            (medeleg_regOut_EX_SWC),
    .io_in_medeleg_EX_HWE            (medeleg_regOut_EX_HWE),
    .io_in_medeleg_EX_IGPF           (medeleg_regOut_EX_IGPF),
    .io_in_medeleg_EX_LGPF           (medeleg_regOut_EX_LGPF),
    .io_in_medeleg_EX_VI             (medeleg_regOut_EX_VI),
    .io_in_medeleg_EX_SGPF           (medeleg_regOut_EX_SGPF),
    .io_in_hedeleg_EX_IAM            (hedeleg_regOut_EX_IAM),
    .io_in_hedeleg_EX_IAF            (hedeleg_regOut_EX_IAF),
    .io_in_hedeleg_EX_II             (hedeleg_regOut_EX_II),
    .io_in_hedeleg_EX_BP             (hedeleg_regOut_EX_BP),
    .io_in_hedeleg_EX_LAM            (hedeleg_regOut_EX_LAM),
    .io_in_hedeleg_EX_LAF            (hedeleg_regOut_EX_LAF),
    .io_in_hedeleg_EX_SAM            (hedeleg_regOut_EX_SAM),
    .io_in_hedeleg_EX_SAF            (hedeleg_regOut_EX_SAF),
    .io_in_hedeleg_EX_UCALL          (hedeleg_regOut_EX_UCALL),
    .io_in_hedeleg_EX_IPF            (hedeleg_regOut_EX_IPF),
    .io_in_hedeleg_EX_LPF            (hedeleg_regOut_EX_LPF),
    .io_in_hedeleg_EX_SPF            (hedeleg_regOut_EX_SPF),
    .io_in_hedeleg_EX_SWC            (hedeleg_regOut_EX_SWC),
    .io_in_hedeleg_EX_HWE            (hedeleg_regOut_EX_HWE),
    .io_in_mtvec_mode                (mtvec_regOut_mode),
    .io_in_mtvec_addr                (mtvec_regOut_addr),
    .io_in_stvec_mode                (stvec_regOut_mode),
    .io_in_stvec_addr                (stvec_regOut_addr),
    .io_in_vstvec_mode               (vstvec_regOut_mode),
    .io_in_vstvec_addr               (vstvec_regOut_addr),
    .io_out_entryPrivState_PRVM      (trapHandleMod_io_out_entryPrivState_PRVM),
    .io_out_entryPrivState_V         (trapHandleMod_io_out_entryPrivState_V),
    .io_out_causeNO_Interrupt        (trapHandleMod_io_out_causeNO_Interrupt),
    .io_out_causeNO_ExceptionCode    (trapHandleMod_io_out_causeNO_ExceptionCode),
    .io_out_dbltrpToMN               (trapHandleMod_io_out_dbltrpToMN),
    .io_out_hasDTExcp                (trapHandleMod_io_out_hasDTExcp),
    .io_out_pcFromXtvec              (trapHandleMod_io_out_pcFromXtvec)
  );
  PMPEntryHandleModule pmpEntryMod (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_wen              (wen_legal_q),
    .io_in_ren              (ren),
    .io_in_addr             (io_in_bits_addr),
    .io_in_wdata            (io_in_bits_wdata),
    .io_in_pmpCfg_0_R       (pmpcfgs_0_regOut_R),
    .io_in_pmpCfg_0_W       (pmpcfgs_0_regOut_W),
    .io_in_pmpCfg_0_X       (pmpcfgs_0_regOut_X),
    .io_in_pmpCfg_0_A       (pmpcfgs_0_regOut_A),
    .io_in_pmpCfg_0_L       (pmpcfgs_0_regOut_L),
    .io_in_pmpCfg_1_R       (pmpcfgs_1_regOut_R),
    .io_in_pmpCfg_1_W       (pmpcfgs_1_regOut_W),
    .io_in_pmpCfg_1_X       (pmpcfgs_1_regOut_X),
    .io_in_pmpCfg_1_A       (pmpcfgs_1_regOut_A),
    .io_in_pmpCfg_1_L       (pmpcfgs_1_regOut_L),
    .io_in_pmpCfg_2_R       (pmpcfgs_2_regOut_R),
    .io_in_pmpCfg_2_W       (pmpcfgs_2_regOut_W),
    .io_in_pmpCfg_2_X       (pmpcfgs_2_regOut_X),
    .io_in_pmpCfg_2_A       (pmpcfgs_2_regOut_A),
    .io_in_pmpCfg_2_L       (pmpcfgs_2_regOut_L),
    .io_in_pmpCfg_3_R       (pmpcfgs_3_regOut_R),
    .io_in_pmpCfg_3_W       (pmpcfgs_3_regOut_W),
    .io_in_pmpCfg_3_X       (pmpcfgs_3_regOut_X),
    .io_in_pmpCfg_3_A       (pmpcfgs_3_regOut_A),
    .io_in_pmpCfg_3_L       (pmpcfgs_3_regOut_L),
    .io_in_pmpCfg_4_R       (pmpcfgs_4_regOut_R),
    .io_in_pmpCfg_4_W       (pmpcfgs_4_regOut_W),
    .io_in_pmpCfg_4_X       (pmpcfgs_4_regOut_X),
    .io_in_pmpCfg_4_A       (pmpcfgs_4_regOut_A),
    .io_in_pmpCfg_4_L       (pmpcfgs_4_regOut_L),
    .io_in_pmpCfg_5_R       (pmpcfgs_5_regOut_R),
    .io_in_pmpCfg_5_W       (pmpcfgs_5_regOut_W),
    .io_in_pmpCfg_5_X       (pmpcfgs_5_regOut_X),
    .io_in_pmpCfg_5_A       (pmpcfgs_5_regOut_A),
    .io_in_pmpCfg_5_L       (pmpcfgs_5_regOut_L),
    .io_in_pmpCfg_6_R       (pmpcfgs_6_regOut_R),
    .io_in_pmpCfg_6_W       (pmpcfgs_6_regOut_W),
    .io_in_pmpCfg_6_X       (pmpcfgs_6_regOut_X),
    .io_in_pmpCfg_6_A       (pmpcfgs_6_regOut_A),
    .io_in_pmpCfg_6_L       (pmpcfgs_6_regOut_L),
    .io_in_pmpCfg_7_R       (pmpcfgs_7_regOut_R),
    .io_in_pmpCfg_7_W       (pmpcfgs_7_regOut_W),
    .io_in_pmpCfg_7_X       (pmpcfgs_7_regOut_X),
    .io_in_pmpCfg_7_A       (pmpcfgs_7_regOut_A),
    .io_in_pmpCfg_7_L       (pmpcfgs_7_regOut_L),
    .io_in_pmpCfg_8_R       (pmpcfgs_8_regOut_R),
    .io_in_pmpCfg_8_W       (pmpcfgs_8_regOut_W),
    .io_in_pmpCfg_8_X       (pmpcfgs_8_regOut_X),
    .io_in_pmpCfg_8_A       (pmpcfgs_8_regOut_A),
    .io_in_pmpCfg_8_L       (pmpcfgs_8_regOut_L),
    .io_in_pmpCfg_9_R       (pmpcfgs_9_regOut_R),
    .io_in_pmpCfg_9_W       (pmpcfgs_9_regOut_W),
    .io_in_pmpCfg_9_X       (pmpcfgs_9_regOut_X),
    .io_in_pmpCfg_9_A       (pmpcfgs_9_regOut_A),
    .io_in_pmpCfg_9_L       (pmpcfgs_9_regOut_L),
    .io_in_pmpCfg_10_R      (pmpcfgs_10_regOut_R),
    .io_in_pmpCfg_10_W      (pmpcfgs_10_regOut_W),
    .io_in_pmpCfg_10_X      (pmpcfgs_10_regOut_X),
    .io_in_pmpCfg_10_A      (pmpcfgs_10_regOut_A),
    .io_in_pmpCfg_10_L      (pmpcfgs_10_regOut_L),
    .io_in_pmpCfg_11_R      (pmpcfgs_11_regOut_R),
    .io_in_pmpCfg_11_W      (pmpcfgs_11_regOut_W),
    .io_in_pmpCfg_11_X      (pmpcfgs_11_regOut_X),
    .io_in_pmpCfg_11_A      (pmpcfgs_11_regOut_A),
    .io_in_pmpCfg_11_L      (pmpcfgs_11_regOut_L),
    .io_in_pmpCfg_12_R      (pmpcfgs_12_regOut_R),
    .io_in_pmpCfg_12_W      (pmpcfgs_12_regOut_W),
    .io_in_pmpCfg_12_X      (pmpcfgs_12_regOut_X),
    .io_in_pmpCfg_12_A      (pmpcfgs_12_regOut_A),
    .io_in_pmpCfg_12_L      (pmpcfgs_12_regOut_L),
    .io_in_pmpCfg_13_R      (pmpcfgs_13_regOut_R),
    .io_in_pmpCfg_13_W      (pmpcfgs_13_regOut_W),
    .io_in_pmpCfg_13_X      (pmpcfgs_13_regOut_X),
    .io_in_pmpCfg_13_A      (pmpcfgs_13_regOut_A),
    .io_in_pmpCfg_13_L      (pmpcfgs_13_regOut_L),
    .io_in_pmpCfg_14_R      (pmpcfgs_14_regOut_R),
    .io_in_pmpCfg_14_W      (pmpcfgs_14_regOut_W),
    .io_in_pmpCfg_14_X      (pmpcfgs_14_regOut_X),
    .io_in_pmpCfg_14_A      (pmpcfgs_14_regOut_A),
    .io_in_pmpCfg_14_L      (pmpcfgs_14_regOut_L),
    .io_in_pmpCfg_15_R      (pmpcfgs_15_regOut_R),
    .io_in_pmpCfg_15_W      (pmpcfgs_15_regOut_W),
    .io_in_pmpCfg_15_X      (pmpcfgs_15_regOut_X),
    .io_in_pmpCfg_15_A      (pmpcfgs_15_regOut_A),
    .io_in_pmpCfg_15_L      (pmpcfgs_15_regOut_L),
    .io_in_pmpCfg_16_R      (pmpcfgs_16_regOut_R),
    .io_in_pmpCfg_16_W      (pmpcfgs_16_regOut_W),
    .io_in_pmpCfg_16_X      (pmpcfgs_16_regOut_X),
    .io_in_pmpCfg_16_A      (pmpcfgs_16_regOut_A),
    .io_in_pmpCfg_16_L      (pmpcfgs_16_regOut_L),
    .io_in_pmpCfg_17_R      (pmpcfgs_17_regOut_R),
    .io_in_pmpCfg_17_W      (pmpcfgs_17_regOut_W),
    .io_in_pmpCfg_17_X      (pmpcfgs_17_regOut_X),
    .io_in_pmpCfg_17_A      (pmpcfgs_17_regOut_A),
    .io_in_pmpCfg_17_L      (pmpcfgs_17_regOut_L),
    .io_in_pmpCfg_18_R      (pmpcfgs_18_regOut_R),
    .io_in_pmpCfg_18_W      (pmpcfgs_18_regOut_W),
    .io_in_pmpCfg_18_X      (pmpcfgs_18_regOut_X),
    .io_in_pmpCfg_18_A      (pmpcfgs_18_regOut_A),
    .io_in_pmpCfg_18_L      (pmpcfgs_18_regOut_L),
    .io_in_pmpCfg_19_R      (pmpcfgs_19_regOut_R),
    .io_in_pmpCfg_19_W      (pmpcfgs_19_regOut_W),
    .io_in_pmpCfg_19_X      (pmpcfgs_19_regOut_X),
    .io_in_pmpCfg_19_A      (pmpcfgs_19_regOut_A),
    .io_in_pmpCfg_19_L      (pmpcfgs_19_regOut_L),
    .io_in_pmpCfg_20_R      (pmpcfgs_20_regOut_R),
    .io_in_pmpCfg_20_W      (pmpcfgs_20_regOut_W),
    .io_in_pmpCfg_20_X      (pmpcfgs_20_regOut_X),
    .io_in_pmpCfg_20_A      (pmpcfgs_20_regOut_A),
    .io_in_pmpCfg_20_L      (pmpcfgs_20_regOut_L),
    .io_in_pmpCfg_21_R      (pmpcfgs_21_regOut_R),
    .io_in_pmpCfg_21_W      (pmpcfgs_21_regOut_W),
    .io_in_pmpCfg_21_X      (pmpcfgs_21_regOut_X),
    .io_in_pmpCfg_21_A      (pmpcfgs_21_regOut_A),
    .io_in_pmpCfg_21_L      (pmpcfgs_21_regOut_L),
    .io_in_pmpCfg_22_R      (pmpcfgs_22_regOut_R),
    .io_in_pmpCfg_22_W      (pmpcfgs_22_regOut_W),
    .io_in_pmpCfg_22_X      (pmpcfgs_22_regOut_X),
    .io_in_pmpCfg_22_A      (pmpcfgs_22_regOut_A),
    .io_in_pmpCfg_22_L      (pmpcfgs_22_regOut_L),
    .io_in_pmpCfg_23_R      (pmpcfgs_23_regOut_R),
    .io_in_pmpCfg_23_W      (pmpcfgs_23_regOut_W),
    .io_in_pmpCfg_23_X      (pmpcfgs_23_regOut_X),
    .io_in_pmpCfg_23_A      (pmpcfgs_23_regOut_A),
    .io_in_pmpCfg_23_L      (pmpcfgs_23_regOut_L),
    .io_in_pmpCfg_24_R      (pmpcfgs_24_regOut_R),
    .io_in_pmpCfg_24_W      (pmpcfgs_24_regOut_W),
    .io_in_pmpCfg_24_X      (pmpcfgs_24_regOut_X),
    .io_in_pmpCfg_24_A      (pmpcfgs_24_regOut_A),
    .io_in_pmpCfg_24_L      (pmpcfgs_24_regOut_L),
    .io_in_pmpCfg_25_R      (pmpcfgs_25_regOut_R),
    .io_in_pmpCfg_25_W      (pmpcfgs_25_regOut_W),
    .io_in_pmpCfg_25_X      (pmpcfgs_25_regOut_X),
    .io_in_pmpCfg_25_A      (pmpcfgs_25_regOut_A),
    .io_in_pmpCfg_25_L      (pmpcfgs_25_regOut_L),
    .io_in_pmpCfg_26_R      (pmpcfgs_26_regOut_R),
    .io_in_pmpCfg_26_W      (pmpcfgs_26_regOut_W),
    .io_in_pmpCfg_26_X      (pmpcfgs_26_regOut_X),
    .io_in_pmpCfg_26_A      (pmpcfgs_26_regOut_A),
    .io_in_pmpCfg_26_L      (pmpcfgs_26_regOut_L),
    .io_in_pmpCfg_27_R      (pmpcfgs_27_regOut_R),
    .io_in_pmpCfg_27_W      (pmpcfgs_27_regOut_W),
    .io_in_pmpCfg_27_X      (pmpcfgs_27_regOut_X),
    .io_in_pmpCfg_27_A      (pmpcfgs_27_regOut_A),
    .io_in_pmpCfg_27_L      (pmpcfgs_27_regOut_L),
    .io_in_pmpCfg_28_R      (pmpcfgs_28_regOut_R),
    .io_in_pmpCfg_28_W      (pmpcfgs_28_regOut_W),
    .io_in_pmpCfg_28_X      (pmpcfgs_28_regOut_X),
    .io_in_pmpCfg_28_A      (pmpcfgs_28_regOut_A),
    .io_in_pmpCfg_28_L      (pmpcfgs_28_regOut_L),
    .io_in_pmpCfg_29_R      (pmpcfgs_29_regOut_R),
    .io_in_pmpCfg_29_W      (pmpcfgs_29_regOut_W),
    .io_in_pmpCfg_29_X      (pmpcfgs_29_regOut_X),
    .io_in_pmpCfg_29_A      (pmpcfgs_29_regOut_A),
    .io_in_pmpCfg_29_L      (pmpcfgs_29_regOut_L),
    .io_in_pmpCfg_30_R      (pmpcfgs_30_regOut_R),
    .io_in_pmpCfg_30_W      (pmpcfgs_30_regOut_W),
    .io_in_pmpCfg_30_X      (pmpcfgs_30_regOut_X),
    .io_in_pmpCfg_30_A      (pmpcfgs_30_regOut_A),
    .io_in_pmpCfg_30_L      (pmpcfgs_30_regOut_L),
    .io_in_pmpCfg_31_R      (pmpcfgs_31_regOut_R),
    .io_in_pmpCfg_31_W      (pmpcfgs_31_regOut_W),
    .io_in_pmpCfg_31_X      (pmpcfgs_31_regOut_X),
    .io_in_pmpCfg_31_A      (pmpcfgs_31_regOut_A),
    .io_in_pmpCfg_31_L      (pmpcfgs_31_regOut_L),
    .io_out_pmpCfgWData     (pmpEntryMod_io_out_pmpCfgWData),
    .io_out_pmpAddrRData_0  (pmpEntryMod_io_out_pmpAddrRData_0),
    .io_out_pmpAddrRData_1  (pmpEntryMod_io_out_pmpAddrRData_1),
    .io_out_pmpAddrRData_2  (pmpEntryMod_io_out_pmpAddrRData_2),
    .io_out_pmpAddrRData_3  (pmpEntryMod_io_out_pmpAddrRData_3),
    .io_out_pmpAddrRData_4  (pmpEntryMod_io_out_pmpAddrRData_4),
    .io_out_pmpAddrRData_5  (pmpEntryMod_io_out_pmpAddrRData_5),
    .io_out_pmpAddrRData_6  (pmpEntryMod_io_out_pmpAddrRData_6),
    .io_out_pmpAddrRData_7  (pmpEntryMod_io_out_pmpAddrRData_7),
    .io_out_pmpAddrRData_8  (pmpEntryMod_io_out_pmpAddrRData_8),
    .io_out_pmpAddrRData_9  (pmpEntryMod_io_out_pmpAddrRData_9),
    .io_out_pmpAddrRData_10 (pmpEntryMod_io_out_pmpAddrRData_10),
    .io_out_pmpAddrRData_11 (pmpEntryMod_io_out_pmpAddrRData_11),
    .io_out_pmpAddrRData_12 (pmpEntryMod_io_out_pmpAddrRData_12),
    .io_out_pmpAddrRData_13 (pmpEntryMod_io_out_pmpAddrRData_13),
    .io_out_pmpAddrRData_14 (pmpEntryMod_io_out_pmpAddrRData_14),
    .io_out_pmpAddrRData_15 (pmpEntryMod_io_out_pmpAddrRData_15),
    .io_out_pmpAddrRData_16 (pmpEntryMod_io_out_pmpAddrRData_16),
    .io_out_pmpAddrRData_17 (pmpEntryMod_io_out_pmpAddrRData_17),
    .io_out_pmpAddrRData_18 (pmpEntryMod_io_out_pmpAddrRData_18),
    .io_out_pmpAddrRData_19 (pmpEntryMod_io_out_pmpAddrRData_19),
    .io_out_pmpAddrRData_20 (pmpEntryMod_io_out_pmpAddrRData_20),
    .io_out_pmpAddrRData_21 (pmpEntryMod_io_out_pmpAddrRData_21),
    .io_out_pmpAddrRData_22 (pmpEntryMod_io_out_pmpAddrRData_22),
    .io_out_pmpAddrRData_23 (pmpEntryMod_io_out_pmpAddrRData_23),
    .io_out_pmpAddrRData_24 (pmpEntryMod_io_out_pmpAddrRData_24),
    .io_out_pmpAddrRData_25 (pmpEntryMod_io_out_pmpAddrRData_25),
    .io_out_pmpAddrRData_26 (pmpEntryMod_io_out_pmpAddrRData_26),
    .io_out_pmpAddrRData_27 (pmpEntryMod_io_out_pmpAddrRData_27),
    .io_out_pmpAddrRData_28 (pmpEntryMod_io_out_pmpAddrRData_28),
    .io_out_pmpAddrRData_29 (pmpEntryMod_io_out_pmpAddrRData_29),
    .io_out_pmpAddrRData_30 (pmpEntryMod_io_out_pmpAddrRData_30),
    .io_out_pmpAddrRData_31 (pmpEntryMod_io_out_pmpAddrRData_31)
  );
  PMAEntryHandleModule pmaEntryMod (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_wen              (wen_legal_q),
    .io_in_ren              (ren),
    .io_in_addr             (io_in_bits_addr),
    .io_in_wdata            (io_in_bits_wdata),
    .io_in_pmaCfg_0_R       (pmacfgs_0_regOut_R),
    .io_in_pmaCfg_0_W       (pmacfgs_0_regOut_W),
    .io_in_pmaCfg_0_X       (pmacfgs_0_regOut_X),
    .io_in_pmaCfg_0_A       (pmacfgs_0_regOut_A),
    .io_in_pmaCfg_0_L       (pmacfgs_0_regOut_L),
    .io_in_pmaCfg_0_ATOMIC  (pmacfgs_0_regOut_ATOMIC),
    .io_in_pmaCfg_0_C       (pmacfgs_0_regOut_C),
    .io_in_pmaCfg_1_R       (pmacfgs_1_regOut_R),
    .io_in_pmaCfg_1_W       (pmacfgs_1_regOut_W),
    .io_in_pmaCfg_1_X       (pmacfgs_1_regOut_X),
    .io_in_pmaCfg_1_A       (pmacfgs_1_regOut_A),
    .io_in_pmaCfg_1_L       (pmacfgs_1_regOut_L),
    .io_in_pmaCfg_1_ATOMIC  (pmacfgs_1_regOut_ATOMIC),
    .io_in_pmaCfg_1_C       (pmacfgs_1_regOut_C),
    .io_in_pmaCfg_2_R       (pmacfgs_2_regOut_R),
    .io_in_pmaCfg_2_W       (pmacfgs_2_regOut_W),
    .io_in_pmaCfg_2_X       (pmacfgs_2_regOut_X),
    .io_in_pmaCfg_2_A       (pmacfgs_2_regOut_A),
    .io_in_pmaCfg_2_L       (pmacfgs_2_regOut_L),
    .io_in_pmaCfg_2_ATOMIC  (pmacfgs_2_regOut_ATOMIC),
    .io_in_pmaCfg_2_C       (pmacfgs_2_regOut_C),
    .io_in_pmaCfg_3_R       (pmacfgs_3_regOut_R),
    .io_in_pmaCfg_3_W       (pmacfgs_3_regOut_W),
    .io_in_pmaCfg_3_X       (pmacfgs_3_regOut_X),
    .io_in_pmaCfg_3_A       (pmacfgs_3_regOut_A),
    .io_in_pmaCfg_3_L       (pmacfgs_3_regOut_L),
    .io_in_pmaCfg_3_ATOMIC  (pmacfgs_3_regOut_ATOMIC),
    .io_in_pmaCfg_3_C       (pmacfgs_3_regOut_C),
    .io_in_pmaCfg_4_R       (pmacfgs_4_regOut_R),
    .io_in_pmaCfg_4_W       (pmacfgs_4_regOut_W),
    .io_in_pmaCfg_4_X       (pmacfgs_4_regOut_X),
    .io_in_pmaCfg_4_A       (pmacfgs_4_regOut_A),
    .io_in_pmaCfg_4_L       (pmacfgs_4_regOut_L),
    .io_in_pmaCfg_4_ATOMIC  (pmacfgs_4_regOut_ATOMIC),
    .io_in_pmaCfg_4_C       (pmacfgs_4_regOut_C),
    .io_in_pmaCfg_5_R       (pmacfgs_5_regOut_R),
    .io_in_pmaCfg_5_W       (pmacfgs_5_regOut_W),
    .io_in_pmaCfg_5_X       (pmacfgs_5_regOut_X),
    .io_in_pmaCfg_5_A       (pmacfgs_5_regOut_A),
    .io_in_pmaCfg_5_L       (pmacfgs_5_regOut_L),
    .io_in_pmaCfg_5_ATOMIC  (pmacfgs_5_regOut_ATOMIC),
    .io_in_pmaCfg_5_C       (pmacfgs_5_regOut_C),
    .io_in_pmaCfg_6_R       (pmacfgs_6_regOut_R),
    .io_in_pmaCfg_6_W       (pmacfgs_6_regOut_W),
    .io_in_pmaCfg_6_X       (pmacfgs_6_regOut_X),
    .io_in_pmaCfg_6_A       (pmacfgs_6_regOut_A),
    .io_in_pmaCfg_6_L       (pmacfgs_6_regOut_L),
    .io_in_pmaCfg_6_ATOMIC  (pmacfgs_6_regOut_ATOMIC),
    .io_in_pmaCfg_6_C       (pmacfgs_6_regOut_C),
    .io_in_pmaCfg_7_R       (pmacfgs_7_regOut_R),
    .io_in_pmaCfg_7_W       (pmacfgs_7_regOut_W),
    .io_in_pmaCfg_7_X       (pmacfgs_7_regOut_X),
    .io_in_pmaCfg_7_A       (pmacfgs_7_regOut_A),
    .io_in_pmaCfg_7_L       (pmacfgs_7_regOut_L),
    .io_in_pmaCfg_7_ATOMIC  (pmacfgs_7_regOut_ATOMIC),
    .io_in_pmaCfg_7_C       (pmacfgs_7_regOut_C),
    .io_in_pmaCfg_8_R       (pmacfgs_8_regOut_R),
    .io_in_pmaCfg_8_W       (pmacfgs_8_regOut_W),
    .io_in_pmaCfg_8_X       (pmacfgs_8_regOut_X),
    .io_in_pmaCfg_8_A       (pmacfgs_8_regOut_A),
    .io_in_pmaCfg_8_L       (pmacfgs_8_regOut_L),
    .io_in_pmaCfg_8_ATOMIC  (pmacfgs_8_regOut_ATOMIC),
    .io_in_pmaCfg_8_C       (pmacfgs_8_regOut_C),
    .io_in_pmaCfg_9_R       (pmacfgs_9_regOut_R),
    .io_in_pmaCfg_9_W       (pmacfgs_9_regOut_W),
    .io_in_pmaCfg_9_X       (pmacfgs_9_regOut_X),
    .io_in_pmaCfg_9_A       (pmacfgs_9_regOut_A),
    .io_in_pmaCfg_9_L       (pmacfgs_9_regOut_L),
    .io_in_pmaCfg_9_ATOMIC  (pmacfgs_9_regOut_ATOMIC),
    .io_in_pmaCfg_9_C       (pmacfgs_9_regOut_C),
    .io_in_pmaCfg_10_R      (pmacfgs_10_regOut_R),
    .io_in_pmaCfg_10_W      (pmacfgs_10_regOut_W),
    .io_in_pmaCfg_10_X      (pmacfgs_10_regOut_X),
    .io_in_pmaCfg_10_A      (pmacfgs_10_regOut_A),
    .io_in_pmaCfg_10_L      (pmacfgs_10_regOut_L),
    .io_in_pmaCfg_10_ATOMIC (pmacfgs_10_regOut_ATOMIC),
    .io_in_pmaCfg_10_C      (pmacfgs_10_regOut_C),
    .io_in_pmaCfg_11_R      (pmacfgs_11_regOut_R),
    .io_in_pmaCfg_11_W      (pmacfgs_11_regOut_W),
    .io_in_pmaCfg_11_X      (pmacfgs_11_regOut_X),
    .io_in_pmaCfg_11_A      (pmacfgs_11_regOut_A),
    .io_in_pmaCfg_11_L      (pmacfgs_11_regOut_L),
    .io_in_pmaCfg_11_ATOMIC (pmacfgs_11_regOut_ATOMIC),
    .io_in_pmaCfg_11_C      (pmacfgs_11_regOut_C),
    .io_in_pmaCfg_12_R      (pmacfgs_12_regOut_R),
    .io_in_pmaCfg_12_W      (pmacfgs_12_regOut_W),
    .io_in_pmaCfg_12_X      (pmacfgs_12_regOut_X),
    .io_in_pmaCfg_12_A      (pmacfgs_12_regOut_A),
    .io_in_pmaCfg_12_L      (pmacfgs_12_regOut_L),
    .io_in_pmaCfg_12_ATOMIC (pmacfgs_12_regOut_ATOMIC),
    .io_in_pmaCfg_12_C      (pmacfgs_12_regOut_C),
    .io_in_pmaCfg_13_R      (pmacfgs_13_regOut_R),
    .io_in_pmaCfg_13_W      (pmacfgs_13_regOut_W),
    .io_in_pmaCfg_13_X      (pmacfgs_13_regOut_X),
    .io_in_pmaCfg_13_A      (pmacfgs_13_regOut_A),
    .io_in_pmaCfg_13_L      (pmacfgs_13_regOut_L),
    .io_in_pmaCfg_13_ATOMIC (pmacfgs_13_regOut_ATOMIC),
    .io_in_pmaCfg_13_C      (pmacfgs_13_regOut_C),
    .io_in_pmaCfg_14_R      (pmacfgs_14_regOut_R),
    .io_in_pmaCfg_14_W      (pmacfgs_14_regOut_W),
    .io_in_pmaCfg_14_X      (pmacfgs_14_regOut_X),
    .io_in_pmaCfg_14_A      (pmacfgs_14_regOut_A),
    .io_in_pmaCfg_14_L      (pmacfgs_14_regOut_L),
    .io_in_pmaCfg_14_ATOMIC (pmacfgs_14_regOut_ATOMIC),
    .io_in_pmaCfg_14_C      (pmacfgs_14_regOut_C),
    .io_in_pmaCfg_15_R      (pmacfgs_15_regOut_R),
    .io_in_pmaCfg_15_W      (pmacfgs_15_regOut_W),
    .io_in_pmaCfg_15_X      (pmacfgs_15_regOut_X),
    .io_in_pmaCfg_15_A      (pmacfgs_15_regOut_A),
    .io_in_pmaCfg_15_L      (pmacfgs_15_regOut_L),
    .io_in_pmaCfg_15_ATOMIC (pmacfgs_15_regOut_ATOMIC),
    .io_in_pmaCfg_15_C      (pmacfgs_15_regOut_C),
    .io_in_pmaCfg_16_R      (pmacfgs_16_regOut_R),
    .io_in_pmaCfg_16_W      (pmacfgs_16_regOut_W),
    .io_in_pmaCfg_16_X      (pmacfgs_16_regOut_X),
    .io_in_pmaCfg_16_A      (pmacfgs_16_regOut_A),
    .io_in_pmaCfg_16_L      (pmacfgs_16_regOut_L),
    .io_in_pmaCfg_16_ATOMIC (pmacfgs_16_regOut_ATOMIC),
    .io_in_pmaCfg_16_C      (pmacfgs_16_regOut_C),
    .io_in_pmaCfg_17_R      (pmacfgs_17_regOut_R),
    .io_in_pmaCfg_17_W      (pmacfgs_17_regOut_W),
    .io_in_pmaCfg_17_X      (pmacfgs_17_regOut_X),
    .io_in_pmaCfg_17_A      (pmacfgs_17_regOut_A),
    .io_in_pmaCfg_17_L      (pmacfgs_17_regOut_L),
    .io_in_pmaCfg_17_ATOMIC (pmacfgs_17_regOut_ATOMIC),
    .io_in_pmaCfg_17_C      (pmacfgs_17_regOut_C),
    .io_in_pmaCfg_18_R      (pmacfgs_18_regOut_R),
    .io_in_pmaCfg_18_W      (pmacfgs_18_regOut_W),
    .io_in_pmaCfg_18_X      (pmacfgs_18_regOut_X),
    .io_in_pmaCfg_18_A      (pmacfgs_18_regOut_A),
    .io_in_pmaCfg_18_L      (pmacfgs_18_regOut_L),
    .io_in_pmaCfg_18_ATOMIC (pmacfgs_18_regOut_ATOMIC),
    .io_in_pmaCfg_18_C      (pmacfgs_18_regOut_C),
    .io_in_pmaCfg_19_R      (pmacfgs_19_regOut_R),
    .io_in_pmaCfg_19_W      (pmacfgs_19_regOut_W),
    .io_in_pmaCfg_19_X      (pmacfgs_19_regOut_X),
    .io_in_pmaCfg_19_A      (pmacfgs_19_regOut_A),
    .io_in_pmaCfg_19_L      (pmacfgs_19_regOut_L),
    .io_in_pmaCfg_19_ATOMIC (pmacfgs_19_regOut_ATOMIC),
    .io_in_pmaCfg_19_C      (pmacfgs_19_regOut_C),
    .io_in_pmaCfg_20_R      (pmacfgs_20_regOut_R),
    .io_in_pmaCfg_20_W      (pmacfgs_20_regOut_W),
    .io_in_pmaCfg_20_X      (pmacfgs_20_regOut_X),
    .io_in_pmaCfg_20_A      (pmacfgs_20_regOut_A),
    .io_in_pmaCfg_20_L      (pmacfgs_20_regOut_L),
    .io_in_pmaCfg_20_ATOMIC (pmacfgs_20_regOut_ATOMIC),
    .io_in_pmaCfg_20_C      (pmacfgs_20_regOut_C),
    .io_in_pmaCfg_21_R      (pmacfgs_21_regOut_R),
    .io_in_pmaCfg_21_W      (pmacfgs_21_regOut_W),
    .io_in_pmaCfg_21_X      (pmacfgs_21_regOut_X),
    .io_in_pmaCfg_21_A      (pmacfgs_21_regOut_A),
    .io_in_pmaCfg_21_L      (pmacfgs_21_regOut_L),
    .io_in_pmaCfg_21_ATOMIC (pmacfgs_21_regOut_ATOMIC),
    .io_in_pmaCfg_21_C      (pmacfgs_21_regOut_C),
    .io_in_pmaCfg_22_R      (pmacfgs_22_regOut_R),
    .io_in_pmaCfg_22_W      (pmacfgs_22_regOut_W),
    .io_in_pmaCfg_22_X      (pmacfgs_22_regOut_X),
    .io_in_pmaCfg_22_A      (pmacfgs_22_regOut_A),
    .io_in_pmaCfg_22_L      (pmacfgs_22_regOut_L),
    .io_in_pmaCfg_22_ATOMIC (pmacfgs_22_regOut_ATOMIC),
    .io_in_pmaCfg_22_C      (pmacfgs_22_regOut_C),
    .io_in_pmaCfg_23_R      (pmacfgs_23_regOut_R),
    .io_in_pmaCfg_23_W      (pmacfgs_23_regOut_W),
    .io_in_pmaCfg_23_X      (pmacfgs_23_regOut_X),
    .io_in_pmaCfg_23_A      (pmacfgs_23_regOut_A),
    .io_in_pmaCfg_23_L      (pmacfgs_23_regOut_L),
    .io_in_pmaCfg_23_ATOMIC (pmacfgs_23_regOut_ATOMIC),
    .io_in_pmaCfg_23_C      (pmacfgs_23_regOut_C),
    .io_in_pmaCfg_24_R      (pmacfgs_24_regOut_R),
    .io_in_pmaCfg_24_W      (pmacfgs_24_regOut_W),
    .io_in_pmaCfg_24_X      (pmacfgs_24_regOut_X),
    .io_in_pmaCfg_24_A      (pmacfgs_24_regOut_A),
    .io_in_pmaCfg_24_L      (pmacfgs_24_regOut_L),
    .io_in_pmaCfg_24_ATOMIC (pmacfgs_24_regOut_ATOMIC),
    .io_in_pmaCfg_24_C      (pmacfgs_24_regOut_C),
    .io_in_pmaCfg_25_R      (pmacfgs_25_regOut_R),
    .io_in_pmaCfg_25_W      (pmacfgs_25_regOut_W),
    .io_in_pmaCfg_25_X      (pmacfgs_25_regOut_X),
    .io_in_pmaCfg_25_A      (pmacfgs_25_regOut_A),
    .io_in_pmaCfg_25_L      (pmacfgs_25_regOut_L),
    .io_in_pmaCfg_25_ATOMIC (pmacfgs_25_regOut_ATOMIC),
    .io_in_pmaCfg_25_C      (pmacfgs_25_regOut_C),
    .io_in_pmaCfg_26_R      (pmacfgs_26_regOut_R),
    .io_in_pmaCfg_26_W      (pmacfgs_26_regOut_W),
    .io_in_pmaCfg_26_X      (pmacfgs_26_regOut_X),
    .io_in_pmaCfg_26_A      (pmacfgs_26_regOut_A),
    .io_in_pmaCfg_26_L      (pmacfgs_26_regOut_L),
    .io_in_pmaCfg_26_ATOMIC (pmacfgs_26_regOut_ATOMIC),
    .io_in_pmaCfg_26_C      (pmacfgs_26_regOut_C),
    .io_in_pmaCfg_27_R      (pmacfgs_27_regOut_R),
    .io_in_pmaCfg_27_W      (pmacfgs_27_regOut_W),
    .io_in_pmaCfg_27_X      (pmacfgs_27_regOut_X),
    .io_in_pmaCfg_27_A      (pmacfgs_27_regOut_A),
    .io_in_pmaCfg_27_L      (pmacfgs_27_regOut_L),
    .io_in_pmaCfg_27_ATOMIC (pmacfgs_27_regOut_ATOMIC),
    .io_in_pmaCfg_27_C      (pmacfgs_27_regOut_C),
    .io_in_pmaCfg_28_R      (pmacfgs_28_regOut_R),
    .io_in_pmaCfg_28_W      (pmacfgs_28_regOut_W),
    .io_in_pmaCfg_28_X      (pmacfgs_28_regOut_X),
    .io_in_pmaCfg_28_A      (pmacfgs_28_regOut_A),
    .io_in_pmaCfg_28_L      (pmacfgs_28_regOut_L),
    .io_in_pmaCfg_28_ATOMIC (pmacfgs_28_regOut_ATOMIC),
    .io_in_pmaCfg_28_C      (pmacfgs_28_regOut_C),
    .io_in_pmaCfg_29_R      (pmacfgs_29_regOut_R),
    .io_in_pmaCfg_29_W      (pmacfgs_29_regOut_W),
    .io_in_pmaCfg_29_X      (pmacfgs_29_regOut_X),
    .io_in_pmaCfg_29_A      (pmacfgs_29_regOut_A),
    .io_in_pmaCfg_29_L      (pmacfgs_29_regOut_L),
    .io_in_pmaCfg_29_ATOMIC (pmacfgs_29_regOut_ATOMIC),
    .io_in_pmaCfg_29_C      (pmacfgs_29_regOut_C),
    .io_in_pmaCfg_30_R      (pmacfgs_30_regOut_R),
    .io_in_pmaCfg_30_W      (pmacfgs_30_regOut_W),
    .io_in_pmaCfg_30_X      (pmacfgs_30_regOut_X),
    .io_in_pmaCfg_30_A      (pmacfgs_30_regOut_A),
    .io_in_pmaCfg_30_L      (pmacfgs_30_regOut_L),
    .io_in_pmaCfg_30_ATOMIC (pmacfgs_30_regOut_ATOMIC),
    .io_in_pmaCfg_30_C      (pmacfgs_30_regOut_C),
    .io_in_pmaCfg_31_R      (pmacfgs_31_regOut_R),
    .io_in_pmaCfg_31_W      (pmacfgs_31_regOut_W),
    .io_in_pmaCfg_31_X      (pmacfgs_31_regOut_X),
    .io_in_pmaCfg_31_A      (pmacfgs_31_regOut_A),
    .io_in_pmaCfg_31_L      (pmacfgs_31_regOut_L),
    .io_in_pmaCfg_31_ATOMIC (pmacfgs_31_regOut_ATOMIC),
    .io_in_pmaCfg_31_C      (pmacfgs_31_regOut_C),
    .io_out_pmaCfgWdata     (pmaEntryMod_io_out_pmaCfgWdata),
    .io_out_pmaAddrRData_0  (pmaEntryMod_io_out_pmaAddrRData_0),
    .io_out_pmaAddrRData_1  (pmaEntryMod_io_out_pmaAddrRData_1),
    .io_out_pmaAddrRData_2  (pmaEntryMod_io_out_pmaAddrRData_2),
    .io_out_pmaAddrRData_3  (pmaEntryMod_io_out_pmaAddrRData_3),
    .io_out_pmaAddrRData_4  (pmaEntryMod_io_out_pmaAddrRData_4),
    .io_out_pmaAddrRData_5  (pmaEntryMod_io_out_pmaAddrRData_5),
    .io_out_pmaAddrRData_6  (pmaEntryMod_io_out_pmaAddrRData_6),
    .io_out_pmaAddrRData_7  (pmaEntryMod_io_out_pmaAddrRData_7),
    .io_out_pmaAddrRData_8  (pmaEntryMod_io_out_pmaAddrRData_8),
    .io_out_pmaAddrRData_9  (pmaEntryMod_io_out_pmaAddrRData_9),
    .io_out_pmaAddrRData_10 (pmaEntryMod_io_out_pmaAddrRData_10),
    .io_out_pmaAddrRData_11 (pmaEntryMod_io_out_pmaAddrRData_11),
    .io_out_pmaAddrRData_12 (pmaEntryMod_io_out_pmaAddrRData_12),
    .io_out_pmaAddrRData_13 (pmaEntryMod_io_out_pmaAddrRData_13),
    .io_out_pmaAddrRData_14 (pmaEntryMod_io_out_pmaAddrRData_14),
    .io_out_pmaAddrRData_15 (pmaEntryMod_io_out_pmaAddrRData_15),
    .io_out_pmaAddrRData_16 (pmaEntryMod_io_out_pmaAddrRData_16),
    .io_out_pmaAddrRData_17 (pmaEntryMod_io_out_pmaAddrRData_17),
    .io_out_pmaAddrRData_18 (pmaEntryMod_io_out_pmaAddrRData_18),
    .io_out_pmaAddrRData_19 (pmaEntryMod_io_out_pmaAddrRData_19),
    .io_out_pmaAddrRData_20 (pmaEntryMod_io_out_pmaAddrRData_20),
    .io_out_pmaAddrRData_21 (pmaEntryMod_io_out_pmaAddrRData_21),
    .io_out_pmaAddrRData_22 (pmaEntryMod_io_out_pmaAddrRData_22),
    .io_out_pmaAddrRData_23 (pmaEntryMod_io_out_pmaAddrRData_23),
    .io_out_pmaAddrRData_24 (pmaEntryMod_io_out_pmaAddrRData_24),
    .io_out_pmaAddrRData_25 (pmaEntryMod_io_out_pmaAddrRData_25),
    .io_out_pmaAddrRData_26 (pmaEntryMod_io_out_pmaAddrRData_26),
    .io_out_pmaAddrRData_27 (pmaEntryMod_io_out_pmaAddrRData_27),
    .io_out_pmaAddrRData_28 (pmaEntryMod_io_out_pmaAddrRData_28),
    .io_out_pmaAddrRData_29 (pmaEntryMod_io_out_pmaAddrRData_29),
    .io_out_pmaAddrRData_30 (pmaEntryMod_io_out_pmaAddrRData_30),
    .io_out_pmaAddrRData_31 (pmaEntryMod_io_out_pmaAddrRData_31)
  );
  Debug debugMod (
    .clock                                               (clock),
    .io_in_trapInfo_valid                                (io_fromRob_trap_valid),
    .io_in_trapInfo_bits_trapVec                         (io_fromRob_trap_bits_trapVec),
    .io_in_trapInfo_bits_isDebugIntr                     (intr_is_debug_q),
    .io_in_trapInfo_bits_isInterrupt                     (io_fromRob_trap_bits_isInterrupt),
    .io_in_trapInfo_bits_singleStep                      (io_fromRob_trap_bits_singleStep),
    .io_in_trapInfo_bits_trigger                         (io_fromRob_trap_bits_trigger),
    .io_in_trapInfo_bits_criticalErrorState              (critical_error_state),
    .io_in_privState_PRVM                                (prvm),
    .io_in_privState_V                                   (virt),
    .io_in_debugMode                                     (debug_mode),
    .io_in_dcsr_CETRIG                                   (dcsr_regOut_CETRIG),
    .io_in_dcsr_EBREAKVS                                 (dcsr_regOut_EBREAKVS),
    .io_in_dcsr_EBREAKVU                                 (dcsr_regOut_EBREAKVU),
    .io_in_dcsr_EBREAKM                                  (dcsr_regOut_EBREAKM),
    .io_in_dcsr_EBREAKS                                  (dcsr_regOut_EBREAKS),
    .io_in_dcsr_EBREAKU                                  (dcsr_regOut_EBREAKU),
    .io_in_tselect_ALL                                   (tselect_regOut_ALL),
    .io_in_tdata1Selected_DATA                           (tdata1_rdata[58:0]),
    .io_in_tdata2Selected_ALL                            (tdata2_rdata),
    .io_in_tdata1Vec_0_TYPE                              (tdata1RegVec_0_rdata[63:60]),
    .io_in_tdata1Vec_0_DATA                              (tdata1RegVec_0_rdata[58:0]),
    .io_in_tdata1Vec_1_TYPE                              (tdata1RegVec_1_rdata[63:60]),
    .io_in_tdata1Vec_1_DATA                              (tdata1RegVec_1_rdata[58:0]),
    .io_in_tdata1Vec_2_TYPE                              (tdata1RegVec_2_rdata[63:60]),
    .io_in_tdata1Vec_2_DATA                              (tdata1RegVec_2_rdata[58:0]),
    .io_in_tdata1Vec_3_TYPE                              (tdata1RegVec_3_rdata[63:60]),
    .io_in_tdata1Vec_3_DATA                              (tdata1RegVec_3_rdata[58:0]),
    .io_in_triggerCanRaiseBpExp                          (trigger_can_raise_bp_exp),
    .io_in_tdata1Update                                  (tdata1_update),
    .io_in_tdata2Update                                  (tdata2_update),
    .io_in_tdata1Wdata_TYPE                              (io_in_bits_wdata[63:60]),
    .io_in_tdata1Wdata_DATA                              (io_in_bits_wdata[58:0]),
    .io_out_triggerFrontendChange                        (debugMod_io_out_triggerFrontendChange),
    .io_out_newTriggerChainIsLegal                       (debugMod_io_out_newTriggerChainIsLegal),
    .io_out_memTrigger_tUpdate_valid                     (io_status_memTrigger_tUpdate_valid),
    .io_out_memTrigger_tUpdate_bits_addr                 (io_status_memTrigger_tUpdate_bits_addr),
    .io_out_memTrigger_tUpdate_bits_tdata_matchType      (io_status_memTrigger_tUpdate_bits_tdata_matchType),
    .io_out_memTrigger_tUpdate_bits_tdata_select         (io_status_memTrigger_tUpdate_bits_tdata_select),
    .io_out_memTrigger_tUpdate_bits_tdata_action         (io_status_memTrigger_tUpdate_bits_tdata_action),
    .io_out_memTrigger_tUpdate_bits_tdata_chain          (io_status_memTrigger_tUpdate_bits_tdata_chain),
    .io_out_memTrigger_tUpdate_bits_tdata_store          (io_status_memTrigger_tUpdate_bits_tdata_store),
    .io_out_memTrigger_tUpdate_bits_tdata_load           (io_status_memTrigger_tUpdate_bits_tdata_load),
    .io_out_memTrigger_tUpdate_bits_tdata_tdata2         (io_status_memTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_memTrigger_tEnableVec_0                      (io_status_memTrigger_tEnableVec_0),
    .io_out_memTrigger_tEnableVec_1                      (io_status_memTrigger_tEnableVec_1),
    .io_out_memTrigger_tEnableVec_2                      (io_status_memTrigger_tEnableVec_2),
    .io_out_memTrigger_tEnableVec_3                      (io_status_memTrigger_tEnableVec_3),
    .io_out_memTrigger_debugMode                         (io_status_memTrigger_debugMode),
    .io_out_memTrigger_triggerCanRaiseBpExp              (io_status_memTrigger_triggerCanRaiseBpExp),
    .io_out_frontendTrigger_tUpdate_valid                (io_status_frontendTrigger_tUpdate_valid),
    .io_out_frontendTrigger_tUpdate_bits_addr            (io_status_frontendTrigger_tUpdate_bits_addr),
    .io_out_frontendTrigger_tUpdate_bits_tdata_matchType (io_status_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_out_frontendTrigger_tUpdate_bits_tdata_select    (io_status_frontendTrigger_tUpdate_bits_tdata_select),
    .io_out_frontendTrigger_tUpdate_bits_tdata_action    (io_status_frontendTrigger_tUpdate_bits_tdata_action),
    .io_out_frontendTrigger_tUpdate_bits_tdata_chain     (io_status_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_out_frontendTrigger_tUpdate_bits_tdata_tdata2    (io_status_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_frontendTrigger_tEnableVec_0                 (io_status_frontendTrigger_tEnableVec_0),
    .io_out_frontendTrigger_tEnableVec_1                 (io_status_frontendTrigger_tEnableVec_1),
    .io_out_frontendTrigger_tEnableVec_2                 (io_status_frontendTrigger_tEnableVec_2),
    .io_out_frontendTrigger_tEnableVec_3                 (io_status_frontendTrigger_tEnableVec_3),
    .io_out_frontendTrigger_debugMode                    (io_status_frontendTrigger_debugMode),
    .io_out_frontendTrigger_triggerCanRaiseBpExp         (io_status_frontendTrigger_triggerCanRaiseBpExp),
    .io_out_hasDebugTrap                                 (debugMod_io_out_hasDebugTrap),
    .io_out_hasDebugIntr                                 (debugMod_io_out_hasDebugIntr),
    .io_out_hasSingleStep                                (debugMod_io_out_hasSingleStep),
    .io_out_triggerEnterDebugMode                        (debugMod_io_out_triggerEnterDebugMode),
    .io_out_hasDebugEbreakException                      (debugMod_io_out_hasDebugEbreakException),
    .io_out_breakPoint                                   (debugMod_io_out_breakPoint),
    .io_out_criticalErrorStateEnterDebug                 (debugMod_io_out_criticalErrorStateEnterDebug)
  );
  HPerfMonitor_1 hpmHc (
    .clock                   (clock),
    .io_hpm_event_0          (Mhpmevent27_rdata),
    .io_hpm_event_1          (Mhpmevent28_rdata),
    .io_hpm_event_2          (Mhpmevent29_rdata),
    .io_hpm_event_3          (Mhpmevent30_rdata),
    .io_hpm_event_4          (Mhpmevent31_rdata),
    .io_events_sets_0_value  (io_perf_perfEventsHc_0_value),
    .io_events_sets_1_value  (io_perf_perfEventsHc_1_value),
    .io_events_sets_2_value  (io_perf_perfEventsHc_2_value),
    .io_events_sets_3_value  (io_perf_perfEventsHc_3_value),
    .io_events_sets_4_value  (io_perf_perfEventsHc_4_value),
    .io_events_sets_5_value  (io_perf_perfEventsHc_5_value),
    .io_events_sets_6_value  (io_perf_perfEventsHc_6_value),
    .io_events_sets_7_value  (io_perf_perfEventsHc_7_value),
    .io_events_sets_8_value  (io_perf_perfEventsHc_8_value),
    .io_events_sets_9_value  (io_perf_perfEventsHc_9_value),
    .io_events_sets_10_value (io_perf_perfEventsHc_10_value),
    .io_events_sets_11_value (io_perf_perfEventsHc_11_value),
    .io_events_sets_12_value (io_perf_perfEventsHc_12_value),
    .io_events_sets_13_value (io_perf_perfEventsHc_13_value),
    .io_events_sets_14_value (io_perf_perfEventsHc_14_value),
    .io_events_sets_15_value (io_perf_perfEventsHc_15_value),
    .io_events_sets_16_value (io_perf_perfEventsHc_16_value),
    .io_events_sets_17_value (io_perf_perfEventsHc_17_value),
    .io_events_sets_18_value (io_perf_perfEventsHc_18_value),
    .io_events_sets_19_value (io_perf_perfEventsHc_19_value),
    .io_events_sets_20_value (io_perf_perfEventsHc_20_value),
    .io_events_sets_21_value (io_perf_perfEventsHc_21_value),
    .io_events_sets_22_value (io_perf_perfEventsHc_22_value),
    .io_events_sets_23_value (io_perf_perfEventsHc_23_value),
    .io_events_sets_24_value (io_perf_perfEventsHc_24_value),
    .io_events_sets_25_value (io_perf_perfEventsHc_25_value),
    .io_events_sets_26_value (io_perf_perfEventsHc_26_value),
    .io_events_sets_27_value (io_perf_perfEventsHc_27_value),
    .io_events_sets_28_value (io_perf_perfEventsHc_28_value),
    .io_events_sets_29_value (io_perf_perfEventsHc_29_value),
    .io_events_sets_30_value (io_perf_perfEventsHc_30_value),
    .io_events_sets_31_value (io_perf_perfEventsHc_31_value),
    .io_events_sets_32_value (io_perf_perfEventsHc_32_value),
    .io_events_sets_33_value (io_perf_perfEventsHc_33_value),
    .io_events_sets_34_value (io_perf_perfEventsHc_34_value),
    .io_events_sets_35_value (io_perf_perfEventsHc_35_value),
    .io_events_sets_36_value (io_perf_perfEventsHc_36_value),
    .io_events_sets_37_value (io_perf_perfEventsHc_37_value),
    .io_events_sets_38_value (io_perf_perfEventsHc_38_value),
    .io_events_sets_39_value (io_perf_perfEventsHc_39_value),
    .io_events_sets_40_value (io_perf_perfEventsHc_40_value),
    .io_events_sets_41_value (io_perf_perfEventsHc_41_value),
    .io_events_sets_42_value (io_perf_perfEventsHc_42_value),
    .io_events_sets_43_value (io_perf_perfEventsHc_43_value),
    .io_events_sets_44_value (io_perf_perfEventsHc_44_value),
    .io_events_sets_45_value (io_perf_perfEventsHc_45_value),
    .io_events_sets_46_value (io_perf_perfEventsHc_46_value),
    .io_events_sets_47_value (io_perf_perfEventsHc_47_value),
    .io_events_sets_48_value (io_perf_perfEventsHc_48_value),
    .io_events_sets_49_value (io_perf_perfEventsHc_49_value),
    .io_events_sets_50_value (io_perf_perfEventsHc_50_value),
    .io_events_sets_51_value (io_perf_perfEventsHc_51_value),
    .io_events_sets_52_value (io_perf_perfEventsHc_52_value),
    .io_events_sets_53_value (io_perf_perfEventsHc_53_value),
    .io_events_sets_54_value (io_perf_perfEventsHc_54_value),
    .io_events_sets_55_value (io_perf_perfEventsHc_55_value),
    .io_events_sets_56_value (io_perf_perfEventsHc_56_value),
    .io_events_sets_57_value (io_perf_perfEventsHc_57_value),
    .io_events_sets_58_value (io_perf_perfEventsHc_58_value),
    .io_events_sets_59_value (io_perf_perfEventsHc_59_value),
    .io_events_sets_60_value (io_perf_perfEventsHc_60_value),
    .io_events_sets_61_value (io_perf_perfEventsHc_61_value),
    .io_events_sets_62_value (io_perf_perfEventsHc_62_value),
    .io_events_sets_63_value (io_perf_perfEventsHc_63_value),
    .io_events_sets_64_value (io_perf_perfEventsHc_64_value),
    .io_events_sets_65_value (io_perf_perfEventsHc_65_value),
    .io_events_sets_66_value (io_perf_perfEventsHc_66_value),
    .io_events_sets_67_value (io_perf_perfEventsHc_67_value),
    .io_perf_0_value         (hpmHc_io_perf_0_value),
    .io_perf_1_value         (hpmHc_io_perf_1_value),
    .io_perf_2_value         (hpmHc_io_perf_2_value),
    .io_perf_3_value         (hpmHc_io_perf_3_value),
    .io_perf_4_value         (hpmHc_io_perf_4_value)
  );
// END GENERATED(newcsr-insts)

endmodule
