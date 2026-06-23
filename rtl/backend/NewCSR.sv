// 骨架由 scripts/gen_newcsr.py 生成；步1/步2 译码+特权态机为手写真逻辑。
// 警告：勿再跑 gen_newcsr.py 的 gen_decls_and_core()——会覆盖本文件手写部分。
//       步9 须改 gen 让其「保留手写核 / 只重映射 inst.svh 的 _T_/_GEN_」。

// ============================================================================
// xs_NewCSR_core —— 香山 NewCSR 可读核（步0：骨架 + 契约锁定）
// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala（class NewCSR）
//   * 296 端口 = NewCSR_wrapper.sv 模块头 1:1（contract 锁定）。
//   * include newcsr_decls.svh（inst.svh 引用的内部网声明）。
//   * include newcsr_inst.svh（341 子模块黑盒实例，机械互联）。
//   * 核须驱动的 glue/具名网 + 全部输出端口：步0 暂以占位 '0 驱动，
//     仅为令 VCS elaborate 通过、锁死端口与 inst.svh 契约。
// 步1-9（读Mux→priority case / 写fanout / 特权FSM / trap派发 / 副作用 / 输出广播 /
//   perf·trigger / IMSIC异步 / difftest打拍 / inst.svh重映射）逐组替换占位。
// ============================================================================
import newcsr_pkg::*;

module xs_NewCSR_core(

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

  // ====== 子模块输出网 + glue/具名网 声明 ======
  `include "newcsr_decls.svh"

  // ======================================================================
  // 步1/步2：CSR 地址译码（addr 命中）+ 特权态寄存器/派生。
  //   设计意图：NewCSR.scala 译码表 + privState 寄存器（PRVM/V/debugMode）。
  //   每个 _noCSRIllegal_T_<n> 是「io_in_bits_addr == <CSR地址>」的 one-hot 命中位，
  //   被读出 OR-mux 与写 fanout（newcsr_inst.svh）共同消费。名字暂沿用 golden
  //   _noCSRIllegal_T_<n>（待步9 gen 重映射为可读 addrHit_<csr>）。
  // ======================================================================

  // ----- 仅本核内部使用、未在 decls 声明的译码网（local）-----
  logic addrHit_mireg;
  logic addrHit_sireg;
  logic addrHit_vsireg;
  logic addrHit_misa;
  logic addrHit_menvcfg;
  logic addrHit_sstatus;
  logic addrHit_mtopei;
  logic addrHit_sstateen1;
  logic addrHit_htimedelta;
  logic addrHit_henvcfg;
  logic addrHit_sstateen2;
  logic addrHit_frm;
  logic addrHit_hgatp;
  logic addrHit_sstateen3;
  logic addrHit_tdata1;
  logic addrHit_tdata2;
  logic addrHit_tinfo;
  logic addrHit_stimecmp;
  logic addrHit_fcsr;
  logic addrHit_stopei;
  logic addrHit_satp;
  logic addrHit_vsstatus;
  logic addrHit_vstart;
  logic addrHit_vstimecmp;
  logic addrHit_vstopei;
  logic addrHit_vsatp;
  logic addrHit_mstatus;

  // ----- CSR 地址译码：addr 命中（按 CSR 地址升序）-----
  assign addrHit_fflags = io_in_bits_addr == 12'h1;  // fflags
  assign addrHit_frm = io_in_bits_addr == 12'h2;  // frm
  assign addrHit_fcsr = io_in_bits_addr == 12'h3;  // fcsr
  assign addrHit_vstart = io_in_bits_addr == 12'h8;  // vstart
  assign addrHit_vxsat = io_in_bits_addr == 12'h9;  // vxsat
  assign addrHit_vxrm = io_in_bits_addr == 12'hA;  // vxrm
  assign addrHit_vcsr = io_in_bits_addr == 12'hF;  // vcsr
  assign addrHit_sstatus = io_in_bits_addr == 12'h100;  // sstatus
  assign addrHit_sie = io_in_bits_addr == 12'h104;  // sie
  assign addrHit_stvec = io_in_bits_addr == 12'h105;  // stvec
  assign addrHit_scounteren = io_in_bits_addr == 12'h106;  // scounteren
  assign addrHit_senvcfg = io_in_bits_addr == 12'h10A;  // senvcfg
  assign addrHit_sstateen0 = io_in_bits_addr == 12'h10C;  // sstateen0
  assign addrHit_sstateen1 = io_in_bits_addr == 12'h10D;  // sstateen1
  assign addrHit_sstateen2 = io_in_bits_addr == 12'h10E;  // sstateen2
  assign addrHit_sstateen3 = io_in_bits_addr == 12'h10F;  // sstateen3
  assign addrHit_sscratch = io_in_bits_addr == 12'h140;  // sscratch
  assign addrHit_sepc = io_in_bits_addr == 12'h141;  // sepc
  assign addrHit_scause = io_in_bits_addr == 12'h142;  // scause
  assign addrHit_stval = io_in_bits_addr == 12'h143;  // stval
  assign addrHit_sip = io_in_bits_addr == 12'h144;  // sip
  assign addrHit_stimecmp = io_in_bits_addr == 12'h14D;  // stimecmp
  assign addrHit_siselect = io_in_bits_addr == 12'h150;  // siselect
  assign addrHit_sireg = io_in_bits_addr == 12'h151;  // sireg
  assign addrHit_sireg2 = io_in_bits_addr == 12'h152;
  assign addrHit_sireg3 = io_in_bits_addr == 12'h153;
  assign addrHit_sireg4 = io_in_bits_addr == 12'h155;
  assign addrHit_sireg5 = io_in_bits_addr == 12'h156;
  assign addrHit_sireg6 = io_in_bits_addr == 12'h157;
  assign addrHit_stopei = io_in_bits_addr == 12'h15C;  // stopei
  assign addrHit_satp = io_in_bits_addr == 12'h180;  // satp
  assign addrHit_vsstatus = io_in_bits_addr == 12'h200;  // vsstatus
  assign addrHit_vsie = io_in_bits_addr == 12'h204;  // vsie
  assign addrHit_vstvec = io_in_bits_addr == 12'h205;  // vstvec
  assign addrHit_vsscratch = io_in_bits_addr == 12'h240;  // vsscratch
  assign addrHit_vsepc = io_in_bits_addr == 12'h241;  // vsepc
  assign addrHit_vscause = io_in_bits_addr == 12'h242;  // vscause
  assign addrHit_vstval = io_in_bits_addr == 12'h243;  // vstval
  assign addrHit_vsip = io_in_bits_addr == 12'h244;  // vsip
  assign addrHit_vstimecmp = io_in_bits_addr == 12'h24D;  // vstimecmp
  assign addrHit_vsiselect = io_in_bits_addr == 12'h250;  // vsiselect
  assign addrHit_vsireg = io_in_bits_addr == 12'h251;  // vsireg
  assign addrHit_vsireg2 = io_in_bits_addr == 12'h252;
  assign addrHit_vsireg3 = io_in_bits_addr == 12'h253;
  assign addrHit_vsireg4 = io_in_bits_addr == 12'h255;
  assign addrHit_vsireg5 = io_in_bits_addr == 12'h256;
  assign addrHit_vsireg6 = io_in_bits_addr == 12'h257;
  assign addrHit_vstopei = io_in_bits_addr == 12'h25C;  // vstopei
  assign addrHit_vsatp = io_in_bits_addr == 12'h280;  // vsatp
  assign addrHit_mstatus = io_in_bits_addr == 12'h300;  // mstatus
  assign addrHit_misa = io_in_bits_addr == 12'h301;  // misa
  assign addrHit_medeleg = io_in_bits_addr == 12'h302;  // medeleg
  assign addrHit_mideleg = io_in_bits_addr == 12'h303;  // mideleg
  assign addrHit_mie = io_in_bits_addr == 12'h304;  // mie
  assign addrHit_mtvec = io_in_bits_addr == 12'h305;  // mtvec
  assign addrHit_mcounteren = io_in_bits_addr == 12'h306;  // mcounteren
  assign addrHit_mvien = io_in_bits_addr == 12'h308;  // mvien
  assign addrHit_mvip = io_in_bits_addr == 12'h309;  // mvip
  assign addrHit_menvcfg = io_in_bits_addr == 12'h30A;  // menvcfg
  assign addrHit_mstateen0 = io_in_bits_addr == 12'h30C;  // mstateen0
  assign addrHit_mstateen1 = io_in_bits_addr == 12'h30D;  // mstateen1
  assign addrHit_mstateen2 = io_in_bits_addr == 12'h30E;  // mstateen2
  assign addrHit_mstateen3 = io_in_bits_addr == 12'h30F;  // mstateen3
  assign addrHit_mcountinhibit = io_in_bits_addr == 12'h320;  // mcountinhibit
  assign addrHit_mhpmevent3 = io_in_bits_addr == 12'h323;
  assign addrHit_mhpmevent4 = io_in_bits_addr == 12'h324;
  assign addrHit_mhpmevent5 = io_in_bits_addr == 12'h325;
  assign addrHit_mhpmevent6 = io_in_bits_addr == 12'h326;
  assign addrHit_mhpmevent7 = io_in_bits_addr == 12'h327;
  assign addrHit_mhpmevent8 = io_in_bits_addr == 12'h328;
  assign addrHit_mhpmevent9 = io_in_bits_addr == 12'h329;
  assign addrHit_mhpmevent10 = io_in_bits_addr == 12'h32A;
  assign addrHit_mhpmevent11 = io_in_bits_addr == 12'h32B;
  assign addrHit_mhpmevent12 = io_in_bits_addr == 12'h32C;
  assign addrHit_mhpmevent13 = io_in_bits_addr == 12'h32D;
  assign addrHit_mhpmevent14 = io_in_bits_addr == 12'h32E;
  assign addrHit_mhpmevent15 = io_in_bits_addr == 12'h32F;
  assign addrHit_mhpmevent16 = io_in_bits_addr == 12'h330;
  assign addrHit_mhpmevent17 = io_in_bits_addr == 12'h331;
  assign addrHit_mhpmevent18 = io_in_bits_addr == 12'h332;
  assign addrHit_mhpmevent19 = io_in_bits_addr == 12'h333;
  assign addrHit_mhpmevent20 = io_in_bits_addr == 12'h334;
  assign addrHit_mhpmevent21 = io_in_bits_addr == 12'h335;
  assign addrHit_mhpmevent22 = io_in_bits_addr == 12'h336;
  assign addrHit_mhpmevent23 = io_in_bits_addr == 12'h337;
  assign addrHit_mhpmevent24 = io_in_bits_addr == 12'h338;
  assign addrHit_mhpmevent25 = io_in_bits_addr == 12'h339;
  assign addrHit_mhpmevent26 = io_in_bits_addr == 12'h33A;
  assign addrHit_mhpmevent27 = io_in_bits_addr == 12'h33B;
  assign addrHit_mhpmevent28 = io_in_bits_addr == 12'h33C;
  assign addrHit_mhpmevent29 = io_in_bits_addr == 12'h33D;
  assign addrHit_mhpmevent30 = io_in_bits_addr == 12'h33E;
  assign addrHit_mhpmevent31 = io_in_bits_addr == 12'h33F;
  assign addrHit_mscratch = io_in_bits_addr == 12'h340;  // mscratch
  assign addrHit_mepc = io_in_bits_addr == 12'h341;  // mepc
  assign addrHit_mcause = io_in_bits_addr == 12'h342;  // mcause
  assign addrHit_mtval = io_in_bits_addr == 12'h343;  // mtval
  assign addrHit_mip = io_in_bits_addr == 12'h344;  // mip
  assign addrHit_mtinst = io_in_bits_addr == 12'h34A;  // mtinst
  assign addrHit_mtval2 = io_in_bits_addr == 12'h34B;  // mtval2
  assign addrHit_miselect = io_in_bits_addr == 12'h350;  // miselect
  assign addrHit_mireg = io_in_bits_addr == 12'h351;  // mireg
  assign addrHit_mireg2 = io_in_bits_addr == 12'h352;
  assign addrHit_mireg3 = io_in_bits_addr == 12'h353;
  assign addrHit_mireg4 = io_in_bits_addr == 12'h355;
  assign addrHit_mireg5 = io_in_bits_addr == 12'h356;
  assign addrHit_mireg6 = io_in_bits_addr == 12'h357;
  assign addrHit_mtopei = io_in_bits_addr == 12'h35C;  // mtopei
  assign addrHit_pmpcfg_0 = io_in_bits_addr == 12'h3A0;
  assign addrHit_pmpcfg_1 = io_in_bits_addr == 12'h3A2;
  assign addrHit_pmpaddr_0 = io_in_bits_addr == 12'h3B0;
  assign addrHit_pmpaddr_1 = io_in_bits_addr == 12'h3B1;
  assign addrHit_pmpaddr_2 = io_in_bits_addr == 12'h3B2;
  assign addrHit_pmpaddr_3 = io_in_bits_addr == 12'h3B3;
  assign addrHit_pmpaddr_4 = io_in_bits_addr == 12'h3B4;
  assign addrHit_pmpaddr_5 = io_in_bits_addr == 12'h3B5;
  assign addrHit_pmpaddr_6 = io_in_bits_addr == 12'h3B6;
  assign addrHit_pmpaddr_7 = io_in_bits_addr == 12'h3B7;
  assign addrHit_pmpaddr_8 = io_in_bits_addr == 12'h3B8;
  assign addrHit_pmpaddr_9 = io_in_bits_addr == 12'h3B9;
  assign addrHit_pmpaddr_10 = io_in_bits_addr == 12'h3BA;
  assign addrHit_pmpaddr_11 = io_in_bits_addr == 12'h3BB;
  assign addrHit_pmpaddr_12 = io_in_bits_addr == 12'h3BC;
  assign addrHit_pmpaddr_13 = io_in_bits_addr == 12'h3BD;
  assign addrHit_pmpaddr_14 = io_in_bits_addr == 12'h3BE;
  assign addrHit_pmpaddr_15 = io_in_bits_addr == 12'h3BF;
  assign addrHit_scontext = io_in_bits_addr == 12'h5A8;
  assign addrHit_sbpctl = io_in_bits_addr == 12'h5C0;
  assign addrHit_spfctl = io_in_bits_addr == 12'h5C1;
  assign addrHit_slvpredctl = io_in_bits_addr == 12'h5C2;
  assign addrHit_smblockctl = io_in_bits_addr == 12'h5C3;
  assign addrHit_srnctl = io_in_bits_addr == 12'h5C4;
  assign addrHit_hstatus = io_in_bits_addr == 12'h600;
  assign addrHit_hedeleg = io_in_bits_addr == 12'h602;
  assign addrHit_hideleg = io_in_bits_addr == 12'h603;
  assign addrHit_hie = io_in_bits_addr == 12'h604;
  assign addrHit_htimedelta = io_in_bits_addr == 12'h605;  // htimedelta
  assign addrHit_hcounteren = io_in_bits_addr == 12'h606;
  assign addrHit_hgeie = io_in_bits_addr == 12'h607;
  assign addrHit_hvien = io_in_bits_addr == 12'h608;
  assign addrHit_hvictl = io_in_bits_addr == 12'h609;
  assign addrHit_henvcfg = io_in_bits_addr == 12'h60A;  // henvcfg
  assign addrHit_hstateen0 = io_in_bits_addr == 12'h60C;
  assign addrHit_hstateen1 = io_in_bits_addr == 12'h60D;
  assign addrHit_hstateen2 = io_in_bits_addr == 12'h60E;
  assign addrHit_hstateen3 = io_in_bits_addr == 12'h60F;
  assign addrHit_htval = io_in_bits_addr == 12'h643;
  assign addrHit_hip = io_in_bits_addr == 12'h644;
  assign addrHit_hvip = io_in_bits_addr == 12'h645;
  assign addrHit_hviprio1 = io_in_bits_addr == 12'h646;
  assign addrHit_hviprio2 = io_in_bits_addr == 12'h647;
  assign addrHit_htinst = io_in_bits_addr == 12'h64A;
  assign addrHit_hgatp = io_in_bits_addr == 12'h680;  // hgatp
  assign addrHit_hcontext = io_in_bits_addr == 12'h6A8;
  assign addrHit_mnscratch = io_in_bits_addr == 12'h740;
  assign addrHit_mnepc = io_in_bits_addr == 12'h741;
  assign addrHit_mncause = io_in_bits_addr == 12'h742;
  assign addrHit_mnstatus = io_in_bits_addr == 12'h744;
  assign addrHit_mseccfg = io_in_bits_addr == 12'h747;  // mseccfg
  assign addrHit_tselect = io_in_bits_addr == 12'h7A0;  // tselect
  assign addrHit_tdata1 = io_in_bits_addr == 12'h7A1;  // tdata1
  assign addrHit_tdata2 = io_in_bits_addr == 12'h7A2;  // tdata2
  assign addrHit_tinfo = io_in_bits_addr == 12'h7A4;  // tinfo
  assign addrHit_mcontext = io_in_bits_addr == 12'h7A8;  // mcontext
  assign addrHit_dcsr = io_in_bits_addr == 12'h7B0;
  assign addrHit_dpc = io_in_bits_addr == 12'h7B1;
  assign addrHit_dscratch0 = io_in_bits_addr == 12'h7B2;
  assign addrHit_dscratch1 = io_in_bits_addr == 12'h7B3;
  assign addrHit_pmacfg_0 = io_in_bits_addr == 12'h7C0;
  assign addrHit_pmacfg_1 = io_in_bits_addr == 12'h7C2;
  assign addrHit_mcycle = io_in_bits_addr == 12'hB00;
  assign addrHit_minstret = io_in_bits_addr == 12'hB02;
  assign addrHit_mhpmcounters_0 = io_in_bits_addr == 12'hB03;
  assign addrHit_mhpmcounters_1 = io_in_bits_addr == 12'hB04;
  assign addrHit_mhpmcounters_2 = io_in_bits_addr == 12'hB05;
  assign addrHit_mhpmcounters_3 = io_in_bits_addr == 12'hB06;
  assign addrHit_mhpmcounters_4 = io_in_bits_addr == 12'hB07;
  assign addrHit_mhpmcounters_5 = io_in_bits_addr == 12'hB08;
  assign addrHit_mhpmcounters_6 = io_in_bits_addr == 12'hB09;
  assign addrHit_mhpmcounters_7 = io_in_bits_addr == 12'hB0A;
  assign addrHit_mhpmcounters_8 = io_in_bits_addr == 12'hB0B;
  assign addrHit_mhpmcounters_9 = io_in_bits_addr == 12'hB0C;
  assign addrHit_mhpmcounters_10 = io_in_bits_addr == 12'hB0D;
  assign addrHit_mhpmcounters_11 = io_in_bits_addr == 12'hB0E;
  assign addrHit_mhpmcounters_12 = io_in_bits_addr == 12'hB0F;
  assign addrHit_mhpmcounters_13 = io_in_bits_addr == 12'hB10;
  assign addrHit_mhpmcounters_14 = io_in_bits_addr == 12'hB11;
  assign addrHit_mhpmcounters_15 = io_in_bits_addr == 12'hB12;
  assign addrHit_mhpmcounters_16 = io_in_bits_addr == 12'hB13;
  assign addrHit_mhpmcounters_17 = io_in_bits_addr == 12'hB14;
  assign addrHit_mhpmcounters_18 = io_in_bits_addr == 12'hB15;
  assign addrHit_mhpmcounters_19 = io_in_bits_addr == 12'hB16;
  assign addrHit_mhpmcounters_20 = io_in_bits_addr == 12'hB17;
  assign addrHit_mhpmcounters_21 = io_in_bits_addr == 12'hB18;
  assign addrHit_mhpmcounters_22 = io_in_bits_addr == 12'hB19;
  assign addrHit_mhpmcounters_23 = io_in_bits_addr == 12'hB1A;
  assign addrHit_mhpmcounters_24 = io_in_bits_addr == 12'hB1B;
  assign addrHit_mhpmcounters_25 = io_in_bits_addr == 12'hB1C;
  assign addrHit_mhpmcounters_26 = io_in_bits_addr == 12'hB1D;
  assign addrHit_mhpmcounters_27 = io_in_bits_addr == 12'hB1E;
  assign addrHit_mhpmcounters_28 = io_in_bits_addr == 12'hB1F;
  assign addrHit_mcorepwr = io_in_bits_addr == 12'hBC0;
  assign addrHit_mflushpwr = io_in_bits_addr == 12'hBC1;

  // ======================================================================
  // 步2：访问别名 + 特权态寄存器 + 派生组合
  //   设计意图：NewCSR.scala 239-301 / 897-929 / 1232-1253 / 1359-1368。
  //   PRVM/V/debugMode/debugIntrEnable 等是真核状态；事件 valid（trap-entry/xret，
  //   均来自子模块输出）按严格优先级更新；本轮子模块为黑盒 stub，事件 valid 为 X，
  //   故 if(X) 不取（4 态），PRVM 保持复位值 3（M 态），与 golden 行为一致。
  // ======================================================================

  // ----- 访问别名（输入直驱）-----
  assign wen = io_in_bits_wen & io_in_valid;
  assign ren = io_in_bits_ren & io_in_valid;

  // ----- 特权态寄存器（事件优先级更新；复位 M 态）-----
  // 这些寄存器在 decls 中以 logic 声明（PRVM/V/debugMode/debugModeStopCount/
  // criticalErrorState/nmip_*/intrVec/debug/nmi/irToHS/irToVS/virtualInterruptIsHvictlInject）。
  // debugIntrEnable / lastPriv 未在 decls，本核局部声明。
  logic        debugIntrEnable;
  logic [2:0]  lastPriv;

  wire debugModeStopCountNext = debugMode & _dcsr_regOut_STOPCOUNT;
  assign unprivCountUpdate  = ~debugModeStopCount & debugModeStopCountNext;
  assign debugIntr          = platformIRP_debugIP & debugIntrEnable;
  assign _GEN               = {nmip_NMI_43, nmip_NMI_31};

  // criticalErrorStateInCSR：进 M 之外的致命错误锁存条件（含子模块 X，本轮不验值）。
  wire criticalErrorStateInCSR =
    ~_mnstatus_regOut_NMIE & io_fromRob_trap_valid & ~entryDebugMode;

  // ----- 特权态译码（M/HS/HU/VS/VU）-----
  wire PrvmIsM = &PRVM;
  wire PrvmIsS = PRVM == 2'h1;
  wire PrvmIsU = PRVM == 2'h0;
  assign isModeM  = PrvmIsM;
  assign isModeHS = ~V & PrvmIsS;
  wire   isModeHU = ~V & PrvmIsU;
  assign isModeVS =  V & PrvmIsS;
  wire   isModeVU =  V & PrvmIsU;

  // ----- privForTrace（trace 当前特权）/ lastPriv -----
  wire [2:0] privForTrace =
    debugMode ? 3'h4
              : {1'h0, isModeM, isModeM | isModeHS}
                | (isModeVS ? 3'h6 : 3'h0)
                | (isModeVU ? 3'h5 : 3'h0);

  // ----- instrAddrTransType（bare/sv39/sv48/sv39x4/sv48x4，one-hot）-----
  // M 态时 bare = isModeM | ... → 1（X-OR-1 短路），与 golden 一致。
  // golden vsatpModeBare = (vsatp.MODE == 0)
  wire instrTT_vEnable = _vsatp_regOut_MODE == 4'h0;
  wire instrTT_bare =
    isModeM | ~V & _satp_regOut_MODE == 4'h0
    | V & instrTT_vEnable & _hgatp_regOut_MODE == 4'h0;
  wire instrTT_sv39   = ~isModeM & ~V & _satp_regOut_MODE == 4'h8 | V & _vsatp_regOut_MODE == 4'h8;
  wire instrTT_sv48   = ~isModeM & ~V & _satp_regOut_MODE == 4'h9 | V & _vsatp_regOut_MODE == 4'h9;
  wire instrTT_sv39x4 = V & instrTT_vEnable & _hgatp_regOut_MODE == 4'h8;
  wire instrTT_sv48x4 = V & instrTT_vEnable & _hgatp_regOut_MODE == 4'h9;

  // ======================================================================
  // 特权态寄存器更新（事件优先级，严格照 NewCSR.scala 897-929 的 MuxCase）。
  // 事件 valid/bits 均为子模块输出（trapEntry*Event/*retEvent）。
  // ======================================================================
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      debugIntrEnable    <= 1'h1;
      PRVM               <= 2'h3;
      V                  <= 1'h0;
      debugMode          <= 1'h0;
      criticalErrorState <= 1'h0;
      nmip_NMI_31        <= 1'h0;
      nmip_NMI_43        <= 1'h0;
      intrVec            <= 8'h0;
      debug              <= 1'h0;
      nmi                <= 1'h0;
      virtualInterruptIsHvictlInject <= 1'h0;
      irToHS             <= 1'h0;
      irToVS             <= 1'h0;
      lastPriv           <= 3'h3;
    end
    else begin
      // debugIntrEnable：dret 优先于 trapEntryD
      if (_dretEvent_out_debugIntrEnable_valid)
        debugIntrEnable <= _dretEvent_out_debugIntrEnable_bits;
      else if (_trapEntryDEvent_out_debugIntrEnable_valid)
        debugIntrEnable <= _trapEntryDEvent_out_debugIntrEnable_bits;

      // PRVM/V：trapEntryD > M > HS > VS > MN > mret > sret > dret > mnret
      if (_trapEntryDEvent_out_privState_valid) begin
        PRVM <= _trapEntryDEvent_out_privState_bits_PRVM; V <= _trapEntryDEvent_out_privState_bits_V;
      end
      else if (_trapEntryMEvent_out_privState_valid) begin
        PRVM <= _trapEntryMEvent_out_privState_bits_PRVM; V <= _trapEntryMEvent_out_privState_bits_V;
      end
      else if (_trapEntryHSEvent_out_privState_valid) begin
        PRVM <= _trapEntryHSEvent_out_privState_bits_PRVM; V <= _trapEntryHSEvent_out_privState_bits_V;
      end
      else if (_trapEntryVSEvent_out_privState_valid) begin
        PRVM <= _trapEntryVSEvent_out_privState_bits_PRVM; V <= _trapEntryVSEvent_out_privState_bits_V;
      end
      else if (_trapEntryMNEvent_out_privState_valid) begin
        PRVM <= _trapEntryMNEvent_out_privState_bits_PRVM; V <= _trapEntryMNEvent_out_privState_bits_V;
      end
      else if (_mretEvent_out_privState_valid) begin
        PRVM <= _mretEvent_out_privState_bits_PRVM; V <= _mretEvent_out_privState_bits_V;
      end
      else if (_sretEvent_out_privState_valid) begin
        PRVM <= _sretEvent_out_privState_bits_PRVM; V <= _sretEvent_out_privState_bits_V;
      end
      else if (_dretEvent_out_privState_valid) begin
        PRVM <= _dretEvent_out_privState_bits_PRVM; V <= _dretEvent_out_privState_bits_V;
      end
      else if (_mnretEvent_out_privState_valid) begin
        PRVM <= _mnretEvent_out_privState_bits_PRVM; V <= _mnretEvent_out_privState_bits_V;
      end

      // debugMode：dret 优先于 trapEntryD
      if (_dretEvent_out_debugMode_valid)
        debugMode <= _dretEvent_out_debugMode_bits;
      else if (_trapEntryDEvent_out_debugMode_valid)
        debugMode <= _trapEntryDEvent_out_debugMode_bits;

      criticalErrorState <=
        io_fromTop_criticalErrorState | criticalErrorStateInCSR | criticalErrorState;

      // nmip 锁存：中断派发清/置（NewCSR.scala 351-404）
      if (_intrMod_io_out_nmi & _intrMod_io_out_interruptVec_valid) begin
        nmip_NMI_31 <= nmip_NMI_31 & _intrMod_io_out_interruptVec_bits[5:0] != 6'h1F;
        nmip_NMI_43 <= nmip_NMI_43 & _intrMod_io_out_interruptVec_bits[5:0] != 6'h2B;
      end
      else begin
        nmip_NMI_31 <= nonMaskableIRP_NMI_31 | nmip_NMI_31;
        nmip_NMI_43 <= nonMaskableIRP_NMI_43 | nmip_NMI_43;
      end

      // 中断向量锁存（on interruptVec.valid）
      if (_intrMod_io_out_interruptVec_valid) begin
        intrVec   <= _intrMod_io_out_interruptVec_bits;
        debug     <= _intrMod_io_out_debug;
        nmi       <= _intrMod_io_out_nmi;
        virtualInterruptIsHvictlInject <= _intrMod_io_out_virtualInterruptIsHvictlInject;
        irToHS    <= _intrMod_io_out_irToHS;
        irToVS    <= _intrMod_io_out_irToVS;
      end

      // lastPriv：xret / trap 提交时记录上一特权
      if (_permitMod_io_out_hasLegalDret | _permitMod_io_out_hasLegalMNret
          | _permitMod_io_out_hasLegalMret | _permitMod_io_out_hasLegalSret
          | io_fromRob_trap_valid)
        lastPriv <= privForTrace;
    end
  end

  // debugModeStopCount：golden 为无复位寄存器（每拍更新），独立 always。
  always @(posedge clock)
    debugModeStopCount <= debugModeStopCountNext;

  // ======================================================================
  // 步2：特权态派生的对外输出（不依赖子模块 X 的部分可被 UT 验证）。
  // ======================================================================
  assign io_status_privState_PRVM = PRVM;
  assign io_status_privState_V    = V;
  assign io_tlb_imode             = PRVM;
  assign io_status_traceCSR_lastPriv    = lastPriv;
  assign io_status_traceCSR_currentPriv = privForTrace;
  assign io_status_instrAddrTransType_bare   = instrTT_bare;
  assign io_status_instrAddrTransType_sv39   = instrTT_sv39;
  assign io_status_instrAddrTransType_sv39x4 = instrTT_sv39x4;
  assign io_status_instrAddrTransType_sv48   = instrTT_sv48;
  assign io_status_instrAddrTransType_sv48x4 = instrTT_sv48x4;
  assign io_status_wfiEvent  = debugIntr | (|(_mie_rdata & _mip_rdata)) | (|_GEN);
  assign io_status_interrupt = _intrMod_io_out_interruptVec_valid;

  // ======================================================================
  // 步1：CSR 读出 OR-mux（rData 路径）。
  //   设计意图：NewCSR.scala 读出选择——每个 CSR 命中位选其 rdata，OR 汇聚。
  //   分层：machine / mhpm / hyper / vs / fp / all，最后含 IMSIC/perf 间接读出。
  //   命中位沿用 _noCSRIllegal_T_* / addrHit_mireg*（待步9 重映射）。
  //   叶子 _<csr>_rdata 均为子模块输出（decls 声明，inst.svh 驱动）；UT 中为 X，
  //   故本路径只能由 FM 验等价。
  // ======================================================================

  // ----- 补齐译码命中位（高地址段：perf-counter / 只读 ID / trigger 扩展）-----
  logic addrHit_pmaaddr_0; assign addrHit_pmaaddr_0 = io_in_bits_addr == 12'h7C8;
  logic addrHit_pmaaddr_1; assign addrHit_pmaaddr_1 = io_in_bits_addr == 12'h7C9;
  logic addrHit_pmaaddr_2; assign addrHit_pmaaddr_2 = io_in_bits_addr == 12'h7CA;
  logic addrHit_pmaaddr_3; assign addrHit_pmaaddr_3 = io_in_bits_addr == 12'h7CB;
  logic addrHit_pmaaddr_4; assign addrHit_pmaaddr_4 = io_in_bits_addr == 12'h7CC;
  logic addrHit_pmaaddr_5; assign addrHit_pmaaddr_5 = io_in_bits_addr == 12'h7CD;
  logic addrHit_pmaaddr_6; assign addrHit_pmaaddr_6 = io_in_bits_addr == 12'h7CE;
  logic addrHit_pmaaddr_7; assign addrHit_pmaaddr_7 = io_in_bits_addr == 12'h7CF;
  logic addrHit_pmaaddr_8; assign addrHit_pmaaddr_8 = io_in_bits_addr == 12'h7D0;
  logic addrHit_pmaaddr_9; assign addrHit_pmaaddr_9 = io_in_bits_addr == 12'h7D1;
  logic addrHit_pmaaddr_10; assign addrHit_pmaaddr_10 = io_in_bits_addr == 12'h7D2;
  logic addrHit_pmaaddr_11; assign addrHit_pmaaddr_11 = io_in_bits_addr == 12'h7D3;
  logic addrHit_pmaaddr_12; assign addrHit_pmaaddr_12 = io_in_bits_addr == 12'h7D4;
  logic addrHit_pmaaddr_13; assign addrHit_pmaaddr_13 = io_in_bits_addr == 12'h7D5;
  logic addrHit_pmaaddr_14; assign addrHit_pmaaddr_14 = io_in_bits_addr == 12'h7D6;
  logic addrHit_pmaaddr_15; assign addrHit_pmaaddr_15 = io_in_bits_addr == 12'h7D7;
  logic addrHit_cycle; assign addrHit_cycle = io_in_bits_addr == 12'hC00;
  logic addrHit_time; assign addrHit_time = io_in_bits_addr == 12'hC01;
  logic addrHit_instret; assign addrHit_instret = io_in_bits_addr == 12'hC02;
  logic addrHit_hpmcounters_0; assign addrHit_hpmcounters_0 = io_in_bits_addr == 12'hC03;
  logic addrHit_hpmcounters_1; assign addrHit_hpmcounters_1 = io_in_bits_addr == 12'hC04;
  logic addrHit_hpmcounters_2; assign addrHit_hpmcounters_2 = io_in_bits_addr == 12'hC05;
  logic addrHit_hpmcounters_3; assign addrHit_hpmcounters_3 = io_in_bits_addr == 12'hC06;
  logic addrHit_hpmcounters_4; assign addrHit_hpmcounters_4 = io_in_bits_addr == 12'hC07;
  logic addrHit_hpmcounters_5; assign addrHit_hpmcounters_5 = io_in_bits_addr == 12'hC08;
  logic addrHit_hpmcounters_6; assign addrHit_hpmcounters_6 = io_in_bits_addr == 12'hC09;
  logic addrHit_hpmcounters_7; assign addrHit_hpmcounters_7 = io_in_bits_addr == 12'hC0A;
  logic addrHit_hpmcounters_8; assign addrHit_hpmcounters_8 = io_in_bits_addr == 12'hC0B;
  logic addrHit_hpmcounters_9; assign addrHit_hpmcounters_9 = io_in_bits_addr == 12'hC0C;
  logic addrHit_hpmcounters_10; assign addrHit_hpmcounters_10 = io_in_bits_addr == 12'hC0D;
  logic addrHit_hpmcounters_11; assign addrHit_hpmcounters_11 = io_in_bits_addr == 12'hC0E;
  logic addrHit_hpmcounters_12; assign addrHit_hpmcounters_12 = io_in_bits_addr == 12'hC0F;
  logic addrHit_hpmcounters_13; assign addrHit_hpmcounters_13 = io_in_bits_addr == 12'hC10;
  logic addrHit_hpmcounters_14; assign addrHit_hpmcounters_14 = io_in_bits_addr == 12'hC11;
  logic addrHit_hpmcounters_15; assign addrHit_hpmcounters_15 = io_in_bits_addr == 12'hC12;
  logic addrHit_hpmcounters_16; assign addrHit_hpmcounters_16 = io_in_bits_addr == 12'hC13;
  logic addrHit_hpmcounters_17; assign addrHit_hpmcounters_17 = io_in_bits_addr == 12'hC14;
  logic addrHit_hpmcounters_18; assign addrHit_hpmcounters_18 = io_in_bits_addr == 12'hC15;
  logic addrHit_hpmcounters_19; assign addrHit_hpmcounters_19 = io_in_bits_addr == 12'hC16;
  logic addrHit_hpmcounters_20; assign addrHit_hpmcounters_20 = io_in_bits_addr == 12'hC17;
  logic addrHit_hpmcounters_21; assign addrHit_hpmcounters_21 = io_in_bits_addr == 12'hC18;
  logic addrHit_hpmcounters_22; assign addrHit_hpmcounters_22 = io_in_bits_addr == 12'hC19;
  logic addrHit_hpmcounters_23; assign addrHit_hpmcounters_23 = io_in_bits_addr == 12'hC1A;
  logic addrHit_hpmcounters_24; assign addrHit_hpmcounters_24 = io_in_bits_addr == 12'hC1B;
  logic addrHit_hpmcounters_25; assign addrHit_hpmcounters_25 = io_in_bits_addr == 12'hC1C;
  logic addrHit_hpmcounters_26; assign addrHit_hpmcounters_26 = io_in_bits_addr == 12'hC1D;
  logic addrHit_hpmcounters_27; assign addrHit_hpmcounters_27 = io_in_bits_addr == 12'hC1E;
  logic addrHit_hpmcounters_28; assign addrHit_hpmcounters_28 = io_in_bits_addr == 12'hC1F;
  logic addrHit_vtype; assign addrHit_vtype = io_in_bits_addr == 12'hC21;
  logic addrHit_vlenb; assign addrHit_vlenb = io_in_bits_addr == 12'hC22;
  logic addrHit_scountovf; assign addrHit_scountovf = io_in_bits_addr == 12'hDA0;
  logic addrHit_stopi; assign addrHit_stopi = io_in_bits_addr == 12'hDB0;
  logic addrHit_hgeip; assign addrHit_hgeip = io_in_bits_addr == 12'hE12;
  logic addrHit_vstopi; assign addrHit_vstopi = io_in_bits_addr == 12'hEB0;
  logic addrHit_mvendorid; assign addrHit_mvendorid = io_in_bits_addr == 12'hF11;
  logic addrHit_marchid; assign addrHit_marchid = io_in_bits_addr == 12'hF12;
  logic addrHit_mhartid; assign addrHit_mhartid = io_in_bits_addr == 12'hF14;
  logic addrHit_mconfigptr; assign addrHit_mconfigptr = io_in_bits_addr == 12'hF15;
  logic addrHit_mtopi; assign addrHit_mtopi = io_in_bits_addr == 12'hFB0;

  // ----- frm/fcsr 保留值检测（flushPipe 与读出共用）-----
  wire frmIsReserved     = _fcsr_frm[2] & (|(_fcsr_frm[1:0]));
  wire frmWdataReserved  = io_in_bits_wdata[2] & (|(io_in_bits_wdata[1:0]));
  wire fcsrWdataReserved = io_in_bits_wdata[7] & (|(io_in_bits_wdata[6:5]));

  // ----- 读出 OR-树（per-CSR packing）-----
  wire [63:0]  rdata_machine =
    (addrHit_mstatus ? _mstatus_rdata : 64'h0)
    | (addrHit_misa ? 64'h80000000003411AF : 64'h0)
    | (addrHit_medeleg ? _medeleg_rdata : 64'h0)
    | (addrHit_mideleg ? _mideleg_rdata : 64'h0)
    | (addrHit_mie ? _mie_rdata : 64'h0)
    | (addrHit_mtvec ? _mtvec_rdata : 64'h0)
    | (addrHit_mcounteren ? _mcounteren_rdata : 64'h0)
    | (addrHit_mvien ? _mvien_rdata : 64'h0)
    | (addrHit_mvip ? _mvip_rdata : 64'h0)
    | (addrHit_menvcfg ? _menvcfg_rdata : 64'h0)
    | (addrHit_mcountinhibit ? _mcountinhibit_rdata : 64'h0)
    | (addrHit_mscratch ? _mscratch_rdata : 64'h0)
    | (addrHit_mepc ? _mepc_rdata : 64'h0)
    | (addrHit_mcause ? _mcause_rdata : 64'h0)
    | (addrHit_mtval ? _mtval_rdata : 64'h0)
    | (addrHit_mip ? _mip_rdata : 64'h0)
    | (addrHit_mtinst ? _mtinst_rdata : 64'h0)
    | (addrHit_mtval2 ? _mtval2_rdata : 64'h0)
    | (addrHit_mseccfg ? _mseccfg_rdata : 64'h0)
    | (addrHit_mcycle ? _mcycle_rdata : 64'h0)
    | (addrHit_minstret ? _minstret_rdata : 64'h0)
    | (addrHit_mvendorid ? _mvendorid_rdata : 64'h0)
    | (addrHit_marchid ? 64'h19 : 64'h0)
    | (addrHit_mhartid ? _mhartid_rdata : 64'h0)
    | (addrHit_mconfigptr ? _mconfigptr_rdata : 64'h0)
    | (addrHit_mstateen0 ? _mstateen0_rdata : 64'h0)
    | (addrHit_mstateen1 ? _mstateen1_rdata : 64'h0)
    | (addrHit_mstateen2 ? _mstateen2_rdata : 64'h0)
    | (addrHit_mstateen3 ? _mstateen3_rdata : 64'h0)
    | (addrHit_mnepc ? _mnepc_rdata : 64'h0)
    | (addrHit_mncause ? _mncause_rdata : 64'h0)
    | (addrHit_mnstatus ? _mnstatus_rdata : 64'h0)
    | (addrHit_mnscratch ? _mnscratch_rdata : 64'h0);
  wire [63:0]  rdata_mhpm =
    {rdata_machine[63:14],
     rdata_machine[13:0] | (addrHit_mcontext ? _mcontext_rdata : 14'h0)}
    | (addrHit_mhpmevent3 ? _Mhpmevent3_rdata : 64'h0)
    | (addrHit_mhpmevent4 ? _Mhpmevent4_rdata : 64'h0)
    | (addrHit_mhpmevent5 ? _Mhpmevent5_rdata : 64'h0)
    | (addrHit_mhpmevent6 ? _Mhpmevent6_rdata : 64'h0)
    | (addrHit_mhpmevent7 ? _Mhpmevent7_rdata : 64'h0)
    | (addrHit_mhpmevent8 ? _Mhpmevent8_rdata : 64'h0)
    | (addrHit_mhpmevent9 ? _Mhpmevent9_rdata : 64'h0)
    | (addrHit_mhpmevent10 ? _Mhpmevent10_rdata : 64'h0)
    | (addrHit_mhpmevent11 ? _Mhpmevent11_rdata : 64'h0)
    | (addrHit_mhpmevent12 ? _Mhpmevent12_rdata : 64'h0)
    | (addrHit_mhpmevent13 ? _Mhpmevent13_rdata : 64'h0)
    | (addrHit_mhpmevent14 ? _Mhpmevent14_rdata : 64'h0)
    | (addrHit_mhpmevent15 ? _Mhpmevent15_rdata : 64'h0)
    | (addrHit_mhpmevent16 ? _Mhpmevent16_rdata : 64'h0)
    | (addrHit_mhpmevent17 ? _Mhpmevent17_rdata : 64'h0)
    | (addrHit_mhpmevent18 ? _Mhpmevent18_rdata : 64'h0)
    | (addrHit_mhpmevent19 ? _Mhpmevent19_rdata : 64'h0)
    | (addrHit_mhpmevent20 ? _Mhpmevent20_rdata : 64'h0)
    | (addrHit_mhpmevent21 ? _Mhpmevent21_rdata : 64'h0)
    | (addrHit_mhpmevent22 ? _Mhpmevent22_rdata : 64'h0)
    | (addrHit_mhpmevent23 ? _Mhpmevent23_rdata : 64'h0)
    | (addrHit_mhpmevent24 ? _Mhpmevent24_rdata : 64'h0)
    | (addrHit_mhpmevent25 ? _Mhpmevent25_rdata : 64'h0)
    | (addrHit_mhpmevent26 ? _Mhpmevent26_rdata : 64'h0)
    | (addrHit_mhpmevent27 ? _Mhpmevent27_rdata : 64'h0)
    | (addrHit_mhpmevent28 ? _Mhpmevent28_rdata : 64'h0)
    | (addrHit_mhpmevent29 ? _Mhpmevent29_rdata : 64'h0)
    | (addrHit_mhpmevent30 ? _Mhpmevent30_rdata : 64'h0)
    | (addrHit_mhpmevent31 ? _Mhpmevent31_rdata : 64'h0)
    | (addrHit_mhpmcounters_0 ? _mhpmcounters_0_rdata : 64'h0)
    | (addrHit_mhpmcounters_1 ? _mhpmcounters_1_rdata : 64'h0)
    | (addrHit_mhpmcounters_2 ? _mhpmcounters_2_rdata : 64'h0)
    | (addrHit_mhpmcounters_3 ? _mhpmcounters_3_rdata : 64'h0)
    | (addrHit_mhpmcounters_4 ? _mhpmcounters_4_rdata : 64'h0)
    | (addrHit_mhpmcounters_5 ? _mhpmcounters_5_rdata : 64'h0)
    | (addrHit_mhpmcounters_6 ? _mhpmcounters_6_rdata : 64'h0)
    | (addrHit_mhpmcounters_7 ? _mhpmcounters_7_rdata : 64'h0)
    | (addrHit_mhpmcounters_8 ? _mhpmcounters_8_rdata : 64'h0)
    | (addrHit_mhpmcounters_9 ? _mhpmcounters_9_rdata : 64'h0)
    | (addrHit_mhpmcounters_10 ? _mhpmcounters_10_rdata : 64'h0)
    | (addrHit_mhpmcounters_11 ? _mhpmcounters_11_rdata : 64'h0)
    | (addrHit_mhpmcounters_12 ? _mhpmcounters_12_rdata : 64'h0)
    | (addrHit_mhpmcounters_13 ? _mhpmcounters_13_rdata : 64'h0)
    | (addrHit_mhpmcounters_14 ? _mhpmcounters_14_rdata : 64'h0)
    | (addrHit_mhpmcounters_15 ? _mhpmcounters_15_rdata : 64'h0)
    | (addrHit_mhpmcounters_16 ? _mhpmcounters_16_rdata : 64'h0)
    | (addrHit_mhpmcounters_17 ? _mhpmcounters_17_rdata : 64'h0)
    | (addrHit_mhpmcounters_18 ? _mhpmcounters_18_rdata : 64'h0)
    | (addrHit_mhpmcounters_19 ? _mhpmcounters_19_rdata : 64'h0)
    | (addrHit_mhpmcounters_20 ? _mhpmcounters_20_rdata : 64'h0)
    | (addrHit_mhpmcounters_21 ? _mhpmcounters_21_rdata : 64'h0)
    | (addrHit_mhpmcounters_22 ? _mhpmcounters_22_rdata : 64'h0)
    | (addrHit_mhpmcounters_23 ? _mhpmcounters_23_rdata : 64'h0)
    | (addrHit_mhpmcounters_24 ? _mhpmcounters_24_rdata : 64'h0)
    | (addrHit_mhpmcounters_25 ? _mhpmcounters_25_rdata : 64'h0)
    | (addrHit_mhpmcounters_26 ? _mhpmcounters_26_rdata : 64'h0)
    | (addrHit_mhpmcounters_27 ? _mhpmcounters_27_rdata : 64'h0)
    | (addrHit_mhpmcounters_28 ? _mhpmcounters_28_rdata : 64'h0)
    | (~isModeVS & addrHit_sstatus ? _mstatus_sstatusRdata : 64'h0)
    | (~isModeVS & addrHit_sie ? _sie_rdata : 64'h0)
    | (~isModeVS & addrHit_stvec ? _stvec_rdata : 64'h0)
    | (addrHit_scounteren ? _scounteren_rdata : 64'h0)
    | (addrHit_senvcfg ? _senvcfg_rdata : 64'h0)
    | (~isModeVS & addrHit_sscratch ? _sscratch_rdata : 64'h0)
    | (~isModeVS & addrHit_sepc ? _sepc_rdata : 64'h0)
    | (~isModeVS & addrHit_scause ? _scause_rdata : 64'h0)
    | (~isModeVS & addrHit_stval ? _stval_rdata : 64'h0)
    | (~isModeVS & addrHit_sip ? _sip_rdata : 64'h0)
    | (~isModeVS & addrHit_stimecmp ? _stimecmp_rdata : 64'h0)
    | (~isModeVS & addrHit_satp ? _satp_rdata : 64'h0);
  wire [63:0]  rdata_hyper =
    {rdata_mhpm[63:32],
     rdata_mhpm[31:0] | (addrHit_scountovf ? _scountovf_rdata : 32'h0)
       | (addrHit_sstateen0 ? _sstateen0_rdata : 32'h0)
       | (addrHit_sstateen1 ? _sstateen1_rdata : 32'h0)
       | (addrHit_sstateen2 ? _sstateen2_rdata : 32'h0)
       | (addrHit_sstateen3 ? _sstateen3_rdata : 32'h0)
       | (addrHit_scontext ? _scontext_rdata : 32'h0)}
    | (addrHit_hstatus ? _hstatus_rdata : 64'h0)
    | (addrHit_hedeleg ? _hedeleg_rdata : 64'h0)
    | (addrHit_hideleg ? _hideleg_rdata : 64'h0)
    | (addrHit_hie ? _hie_rdata : 64'h0)
    | (addrHit_htimedelta ? _htimedelta_rdata : 64'h0)
    | (addrHit_hcounteren ? _hcounteren_rdata : 64'h0)
    | (addrHit_hgeie ? _hgeie_rdata : 64'h0)
    | (addrHit_hvien ? _hvien_rdata : 64'h0)
    | (addrHit_hvictl ? _hvictl_rdata : 64'h0)
    | (addrHit_henvcfg ? _henvcfg_rdata : 64'h0)
    | (addrHit_htval ? _htval_rdata : 64'h0)
    | (addrHit_hip ? _hip_rdata : 64'h0)
    | (addrHit_hvip ? _hvip_rdata : 64'h0)
    | (addrHit_hviprio1 ? _hviprio1_rdata : 64'h0)
    | (addrHit_hviprio2 ? _hviprio2_rdata : 64'h0)
    | (addrHit_htinst ? _htinst_rdata : 64'h0)
    | (addrHit_hgatp ? _hgatp_rdata : 64'h0)
    | (addrHit_hgeip ? _hgeip_rdata : 64'h0)
    | (addrHit_hstateen0 ? _hstateen0_rdata : 64'h0)
    | (addrHit_hstateen1 ? _hstateen1_rdata : 64'h0)
    | (addrHit_hstateen2 ? _hstateen2_rdata : 64'h0)
    | (addrHit_hstateen3 ? _hstateen3_rdata : 64'h0);
  wire [63:0]  rdata_vs =
    {rdata_hyper[63:14],
     rdata_hyper[13:0] | (addrHit_hcontext ? _hcontext_rdata : 14'h0)}
    | (isModeVS & addrHit_sstatus | ~isModeVS & addrHit_vsstatus
         ? _vsstatus_rdata
         : 64'h0)
    | (isModeVS & addrHit_sie | ~isModeVS & addrHit_vsie
         ? _vsie_rdata
         : 64'h0)
    | (isModeVS & addrHit_stvec | ~isModeVS & addrHit_vstvec
         ? _vstvec_rdata
         : 64'h0)
    | (isModeVS & addrHit_sscratch | ~isModeVS & addrHit_vsscratch
         ? _vsscratch_rdata
         : 64'h0)
    | (isModeVS & addrHit_sepc | ~isModeVS & addrHit_vsepc
         ? _vsepc_rdata
         : 64'h0)
    | (isModeVS & addrHit_scause | ~isModeVS & addrHit_vscause
         ? _vscause_rdata
         : 64'h0)
    | (isModeVS & addrHit_stval | ~isModeVS & addrHit_vstval
         ? _vstval_rdata
         : 64'h0)
    | (isModeVS & addrHit_sip | ~isModeVS & addrHit_vsip
         ? _vsip_rdata
         : 64'h0)
    | (isModeVS & addrHit_stimecmp | ~isModeVS & addrHit_vstimecmp
         ? _vstimecmp_rdata
         : 64'h0)
    | (isModeVS & addrHit_satp | ~isModeVS & addrHit_vsatp
         ? _vsatp_rdata
         : 64'h0);
  wire [4:0]   rdata_fflagsMerge =
    rdata_vs[4:0] | (addrHit_fflags ? _fcsr_fflagsRdata : 5'h0);
  wire [63:0]  rdata_fp =
    {rdata_vs[63:5],
     rdata_fflagsMerge[4:3],
     rdata_fflagsMerge[2:0] | (addrHit_frm ? _fcsr_frmRdata : 3'h0)}
    | (addrHit_fcsr ? _fcsr_rdata : 64'h0)
    | (addrHit_vstart ? _vstart_rdata : 64'h0);
  wire [63:0]  rdata_all =
    (addrHit_vcsr ? _vcsr_rdata : 64'h0)
    | (addrHit_vtype ? _vtype_rdata : 64'h0)
    | {rdata_fp[63:5],
       rdata_fp[4] | addrHit_vlenb,
       rdata_fp[3:2],
       {rdata_fp[1], rdata_fp[0] | addrHit_vxsat & _vcsr_vxsat}
         | (addrHit_vxrm ? _vcsr_vxrm : 2'h0)}
    | (addrHit_cycle ? _cycle_rdata : 64'h0)
    | (addrHit_time ? _time_rdata : 64'h0)
    | (addrHit_instret ? _instret_rdata : 64'h0)
    | (addrHit_hpmcounters_0 ? _hpmcounters_0_rdata : 64'h0)
    | (addrHit_hpmcounters_1 ? _hpmcounters_1_rdata : 64'h0)
    | (addrHit_hpmcounters_2 ? _hpmcounters_2_rdata : 64'h0)
    | (addrHit_hpmcounters_3 ? _hpmcounters_3_rdata : 64'h0)
    | (addrHit_hpmcounters_4 ? _hpmcounters_4_rdata : 64'h0)
    | (addrHit_hpmcounters_5 ? _hpmcounters_5_rdata : 64'h0)
    | (addrHit_hpmcounters_6 ? _hpmcounters_6_rdata : 64'h0)
    | (addrHit_hpmcounters_7 ? _hpmcounters_7_rdata : 64'h0)
    | (addrHit_hpmcounters_8 ? _hpmcounters_8_rdata : 64'h0)
    | (addrHit_hpmcounters_9 ? _hpmcounters_9_rdata : 64'h0)
    | (addrHit_hpmcounters_10 ? _hpmcounters_10_rdata : 64'h0)
    | (addrHit_hpmcounters_11 ? _hpmcounters_11_rdata : 64'h0)
    | (addrHit_hpmcounters_12 ? _hpmcounters_12_rdata : 64'h0)
    | (addrHit_hpmcounters_13 ? _hpmcounters_13_rdata : 64'h0)
    | (addrHit_hpmcounters_14 ? _hpmcounters_14_rdata : 64'h0)
    | (addrHit_hpmcounters_15 ? _hpmcounters_15_rdata : 64'h0)
    | (addrHit_hpmcounters_16 ? _hpmcounters_16_rdata : 64'h0)
    | (addrHit_hpmcounters_17 ? _hpmcounters_17_rdata : 64'h0)
    | (addrHit_hpmcounters_18 ? _hpmcounters_18_rdata : 64'h0)
    | (addrHit_hpmcounters_19 ? _hpmcounters_19_rdata : 64'h0)
    | (addrHit_hpmcounters_20 ? _hpmcounters_20_rdata : 64'h0)
    | (addrHit_hpmcounters_21 ? _hpmcounters_21_rdata : 64'h0)
    | (addrHit_hpmcounters_22 ? _hpmcounters_22_rdata : 64'h0)
    | (addrHit_hpmcounters_23 ? _hpmcounters_23_rdata : 64'h0)
    | (addrHit_hpmcounters_24 ? _hpmcounters_24_rdata : 64'h0)
    | (addrHit_hpmcounters_25 ? _hpmcounters_25_rdata : 64'h0)
    | (addrHit_hpmcounters_26 ? _hpmcounters_26_rdata : 64'h0)
    | (addrHit_hpmcounters_27 ? _hpmcounters_27_rdata : 64'h0)
    | (addrHit_hpmcounters_28 ? _hpmcounters_28_rdata : 64'h0)
    | (addrHit_tdata1 ? _tdata1_rdata : 64'h0)
    | (addrHit_tdata2 ? _tdata2_rdata : 64'h0);

  // ======================================================================
  // 步2：访问 FSM（s_idle=0 / s_waitIMSIC=1 / s_finish=2）+ EX_II/EX_VI/rData
  //   DataHoldBypass 锁存。设计意图：NewCSR.scala 访问握手状态机。
  //   * 普通 CSR：valid 当拍进 finish，下拍 io_out_valid；
  //   * 异步 IMSIC 访问（mireg/sireg/vsireg 落在 IMSIC 区间）：进 waitIMSIC，
  //     等 fromAIA_rdata_valid 回数。
  //   asyncAccess / claimAIA / _permitMod_io_out_EX_* 含子模块输出，UT 中为 X；
  //   X-传播与 golden 完全一致（同源 X），故 io_in_ready/out_valid/EX_II/rData
  //   在 golden 定义处与 golden 相等、在 golden 为 X 处被 tb 的 !$isunknown 跳过。
  // ======================================================================

  // ----- 写使能派生（claimAIA / IMSIC 写）：wenLegalReg_last_REG 为打拍写合法位 -----
  // wenLegalReg_last_REG 在 decls 声明（logic），此处直接作为复位寄存器驱动。
  assign mireg_wen = wenLegalReg_last_REG & addrHit_mireg;
  wire mtopeiClaimWen  = wenLegalReg_last_REG & addrHit_mtopei;
  assign sireg_wen = wenLegalReg_last_REG & ~isModeVS & addrHit_sireg;
  wire stopeiClaimWen  = wenLegalReg_last_REG & ~isModeVS & addrHit_stopei;
  assign vsireg_wen =
    wenLegalReg_last_REG
    & (isModeVS & addrHit_sireg | ~isModeVS & addrHit_vsireg);
  wire vstopeiClaimWen =
    wenLegalReg_last_REG
    & (isModeVS & addrHit_stopei | ~isModeVS & addrHit_vstopei);
  wire claimAIA = mtopeiClaimWen | stopeiClaimWen | vstopeiClaimWen;

  // ----- noCSRIllegal：地址不在任何已知 CSR 命中位（且为读/写访问）-----
  wire isCsrAccess = ren | wen;
  wire [263:0] csrAddrLegalVec =
    {~addrHit_fflags,
     ~addrHit_frm,
     ~addrHit_fcsr,
     ~addrHit_vstart,
     ~addrHit_vxsat,
     ~addrHit_vxrm,
     ~addrHit_vcsr,
     ~addrHit_sstatus,
     ~addrHit_sie,
     ~addrHit_stvec,
     ~addrHit_scounteren,
     ~addrHit_senvcfg,
     ~addrHit_sstateen0,
     ~addrHit_sstateen1,
     ~addrHit_sstateen2,
     ~addrHit_sstateen3,
     ~addrHit_sscratch,
     ~addrHit_sepc,
     ~addrHit_scause,
     ~addrHit_stval,
     ~addrHit_sip,
     ~addrHit_stimecmp,
     ~addrHit_siselect,
     ~addrHit_sireg,
     ~addrHit_sireg2,
     ~addrHit_sireg3,
     ~addrHit_sireg4,
     ~addrHit_sireg5,
     ~addrHit_sireg6,
     ~addrHit_stopei,
     ~addrHit_satp,
     ~addrHit_vsstatus,
     ~addrHit_vsie,
     ~addrHit_vstvec,
     ~addrHit_vsscratch,
     ~addrHit_vsepc,
     ~addrHit_vscause,
     ~addrHit_vstval,
     ~addrHit_vsip,
     ~addrHit_vstimecmp,
     ~addrHit_vsiselect,
     ~addrHit_vsireg,
     ~addrHit_vsireg2,
     ~addrHit_vsireg3,
     ~addrHit_vsireg4,
     ~addrHit_vsireg5,
     ~addrHit_vsireg6,
     ~addrHit_vstopei,
     ~addrHit_vsatp,
     ~addrHit_mstatus,
     ~addrHit_misa,
     ~addrHit_medeleg,
     ~addrHit_mideleg,
     ~addrHit_mie,
     ~addrHit_mtvec,
     ~addrHit_mcounteren,
     ~addrHit_mvien,
     ~addrHit_mvip,
     ~addrHit_menvcfg,
     ~addrHit_mstateen0,
     ~addrHit_mstateen1,
     ~addrHit_mstateen2,
     ~addrHit_mstateen3,
     ~addrHit_mcountinhibit,
     ~addrHit_mhpmevent3,
     ~addrHit_mhpmevent4,
     ~addrHit_mhpmevent5,
     ~addrHit_mhpmevent6,
     ~addrHit_mhpmevent7,
     ~addrHit_mhpmevent8,
     ~addrHit_mhpmevent9,
     ~addrHit_mhpmevent10,
     ~addrHit_mhpmevent11,
     ~addrHit_mhpmevent12,
     ~addrHit_mhpmevent13,
     ~addrHit_mhpmevent14,
     ~addrHit_mhpmevent15,
     ~addrHit_mhpmevent16,
     ~addrHit_mhpmevent17,
     ~addrHit_mhpmevent18,
     ~addrHit_mhpmevent19,
     ~addrHit_mhpmevent20,
     ~addrHit_mhpmevent21,
     ~addrHit_mhpmevent22,
     ~addrHit_mhpmevent23,
     ~addrHit_mhpmevent24,
     ~addrHit_mhpmevent25,
     ~addrHit_mhpmevent26,
     ~addrHit_mhpmevent27,
     ~addrHit_mhpmevent28,
     ~addrHit_mhpmevent29,
     ~addrHit_mhpmevent30,
     ~addrHit_mhpmevent31,
     ~addrHit_mscratch,
     ~addrHit_mepc,
     ~addrHit_mcause,
     ~addrHit_mtval,
     ~addrHit_mip,
     ~addrHit_mtinst,
     ~addrHit_mtval2,
     ~addrHit_miselect,
     ~addrHit_mireg,
     ~addrHit_mireg2,
     ~addrHit_mireg3,
     ~addrHit_mireg4,
     ~addrHit_mireg5,
     ~addrHit_mireg6,
     ~addrHit_mtopei,
     ~addrHit_pmpcfg_0,
     ~addrHit_pmpcfg_1,
     ~addrHit_pmpaddr_0,
     ~addrHit_pmpaddr_1,
     ~addrHit_pmpaddr_2,
     ~addrHit_pmpaddr_3,
     ~addrHit_pmpaddr_4,
     ~addrHit_pmpaddr_5,
     ~addrHit_pmpaddr_6,
     ~addrHit_pmpaddr_7,
     ~addrHit_pmpaddr_8,
     ~addrHit_pmpaddr_9,
     ~addrHit_pmpaddr_10,
     ~addrHit_pmpaddr_11,
     ~addrHit_pmpaddr_12,
     ~addrHit_pmpaddr_13,
     ~addrHit_pmpaddr_14,
     ~addrHit_pmpaddr_15,
     ~addrHit_scontext,
     ~addrHit_sbpctl,
     ~addrHit_spfctl,
     ~addrHit_slvpredctl,
     ~addrHit_smblockctl,
     ~addrHit_srnctl,
     ~addrHit_hstatus,
     ~addrHit_hedeleg,
     ~addrHit_hideleg,
     ~addrHit_hie,
     ~addrHit_htimedelta,
     ~addrHit_hcounteren,
     ~addrHit_hgeie,
     ~addrHit_hvien,
     ~addrHit_hvictl,
     ~addrHit_henvcfg,
     ~addrHit_hstateen0,
     ~addrHit_hstateen1,
     ~addrHit_hstateen2,
     ~addrHit_hstateen3,
     ~addrHit_htval,
     ~addrHit_hip,
     ~addrHit_hvip,
     ~addrHit_hviprio1,
     ~addrHit_hviprio2,
     ~addrHit_htinst,
     ~addrHit_hgatp,
     ~addrHit_hcontext,
     ~addrHit_mnscratch,
     ~addrHit_mnepc,
     ~addrHit_mncause,
     ~addrHit_mnstatus,
     ~addrHit_mseccfg,
     ~addrHit_tselect,
     ~addrHit_tdata1,
     ~addrHit_tdata2,
     ~addrHit_tinfo,
     ~addrHit_mcontext,
     ~addrHit_dcsr,
     ~addrHit_dpc,
     ~addrHit_dscratch0,
     ~addrHit_dscratch1,
     ~addrHit_pmacfg_0,
     ~addrHit_pmacfg_1,
     ~addrHit_pmaaddr_0,
     ~addrHit_pmaaddr_1,
     ~addrHit_pmaaddr_2,
     ~addrHit_pmaaddr_3,
     ~addrHit_pmaaddr_4,
     ~addrHit_pmaaddr_5,
     ~addrHit_pmaaddr_6,
     ~addrHit_pmaaddr_7,
     ~addrHit_pmaaddr_8,
     ~addrHit_pmaaddr_9,
     ~addrHit_pmaaddr_10,
     ~addrHit_pmaaddr_11,
     ~addrHit_pmaaddr_12,
     ~addrHit_pmaaddr_13,
     ~addrHit_pmaaddr_14,
     ~addrHit_pmaaddr_15,
     ~addrHit_mcycle,
     ~addrHit_minstret,
     ~addrHit_mhpmcounters_0,
     ~addrHit_mhpmcounters_1,
     ~addrHit_mhpmcounters_2,
     ~addrHit_mhpmcounters_3,
     ~addrHit_mhpmcounters_4,
     ~addrHit_mhpmcounters_5,
     ~addrHit_mhpmcounters_6,
     ~addrHit_mhpmcounters_7,
     ~addrHit_mhpmcounters_8,
     ~addrHit_mhpmcounters_9,
     ~addrHit_mhpmcounters_10,
     ~addrHit_mhpmcounters_11,
     ~addrHit_mhpmcounters_12,
     ~addrHit_mhpmcounters_13,
     ~addrHit_mhpmcounters_14,
     ~addrHit_mhpmcounters_15,
     ~addrHit_mhpmcounters_16,
     ~addrHit_mhpmcounters_17,
     ~addrHit_mhpmcounters_18,
     ~addrHit_mhpmcounters_19,
     ~addrHit_mhpmcounters_20,
     ~addrHit_mhpmcounters_21,
     ~addrHit_mhpmcounters_22,
     ~addrHit_mhpmcounters_23,
     ~addrHit_mhpmcounters_24,
     ~addrHit_mhpmcounters_25,
     ~addrHit_mhpmcounters_26,
     ~addrHit_mhpmcounters_27,
     ~addrHit_mhpmcounters_28,
     ~addrHit_mcorepwr,
     ~addrHit_mflushpwr,
     ~addrHit_cycle,
     ~addrHit_time,
     ~addrHit_instret,
     ~addrHit_hpmcounters_0,
     ~addrHit_hpmcounters_1,
     ~addrHit_hpmcounters_2,
     ~addrHit_hpmcounters_3,
     ~addrHit_hpmcounters_4,
     ~addrHit_hpmcounters_5,
     ~addrHit_hpmcounters_6,
     ~addrHit_hpmcounters_7,
     ~addrHit_hpmcounters_8,
     ~addrHit_hpmcounters_9,
     ~addrHit_hpmcounters_10,
     ~addrHit_hpmcounters_11,
     ~addrHit_hpmcounters_12,
     ~addrHit_hpmcounters_13,
     ~addrHit_hpmcounters_14,
     ~addrHit_hpmcounters_15,
     ~addrHit_hpmcounters_16,
     ~addrHit_hpmcounters_17,
     ~addrHit_hpmcounters_18,
     ~addrHit_hpmcounters_19,
     ~addrHit_hpmcounters_20,
     ~addrHit_hpmcounters_21,
     ~addrHit_hpmcounters_22,
     ~addrHit_hpmcounters_23,
     ~addrHit_hpmcounters_24,
     ~addrHit_hpmcounters_25,
     ~addrHit_hpmcounters_26,
     ~addrHit_hpmcounters_27,
     ~addrHit_hpmcounters_28,
     io_in_bits_addr != 12'hC20,
     ~addrHit_vtype,
     ~addrHit_vlenb,
     ~addrHit_scountovf,
     ~addrHit_stopi,
     ~addrHit_hgeip,
     ~addrHit_vstopi,
     ~addrHit_mvendorid,
     ~addrHit_marchid,
     io_in_bits_addr != 12'hF13,
     ~addrHit_mhartid,
     ~addrHit_mconfigptr,
     ~addrHit_mtopi};
  wire         noCSRIllegal = isCsrAccess & (&csrAddrLegalVec);
  reg          noCSRIllegalReg;

  // ----- FSM 与握手派生 -----
  reg  [1:0]   state;
  wire         asyncAccess =
    (wen | ren) & ~(_permitMod_io_out_EX_II | _permitMod_io_out_EX_VI)
    & (io_in_bits_addr == 12'h351 & _miselect_inIMSICRange | io_in_bits_addr == 12'h151
       & (~V & _siselect_inIMSICRange | V & _vsiselect_inIMSICRange)
       | io_in_bits_addr == 12'h251 & _vsiselect_inIMSICRange);
  wire         imsicIllegal = fromAIA_rdata_valid & fromAIA_rdata_bits_illegal;
  wire         normalCSRValid = ~(|state) & io_in_valid & ~asyncAccess;
  wire         waitIMSICValid = state == 2'h1 & fromAIA_rdata_valid;
  wire         exII_comb =
    normalCSRValid & (_permitMod_io_out_EX_II | noCSRIllegal) | waitIMSICValid
    & imsicIllegal & ~V;
  wire         excValidThisCycle = normalCSRValid | waitIMSICValid;
  wire         exVI_comb =
    normalCSRValid & _permitMod_io_out_EX_VI | waitIMSICValid & imsicIllegal & V;
  reg          io_out_bits_EX_II_r;
  reg          io_out_bits_EX_VI_r;
  wire         isNormalRead = ~(|state) & io_in_valid;
  reg  [63:0]  io_out_bits_rData_r;
  reg          io_out_bits_isPerfCnt_r;
  // addrInPerfCnt：访问命中 perf-counter 区间（写须合法 / 读直接）。
  wire         addrInPerfCnt =
    (_permitMod_io_out_hasLegalWen | ren)
    & (io_in_bits_addr > 12'hAFF & io_in_bits_addr < 12'hB20 | io_in_bits_addr > 12'hBFF
       & io_in_bits_addr < 12'hC20) | ren
    & (addrHit_vstopi | addrHit_vstopei | addrHit_stopi | addrHit_stopei
       | addrHit_mtopi | addrHit_mtopei);

  wire [63:0]  rData_comb =
    (isNormalRead | claimAIA
       ? {rdata_all[63:32],
          {rdata_all[31:7],
           rdata_all[6] | addrHit_tinfo,
           rdata_all[5:2],
           rdata_all[1:0] | (addrHit_tselect ? _tselect_rdata : 2'h0)}
            | (addrHit_dcsr ? _dcsr_rdata : 32'h0)}
         | (addrHit_dpc ? _dpc_rdata : 64'h0)
         | (addrHit_dscratch0 ? _dscratch0_rdata : 64'h0)
         | (addrHit_dscratch1 ? _dscratch1_rdata : 64'h0)
         | (addrHit_miselect ? _miselect_rdata : 64'h0)
         | (addrHit_mireg ? _mireg_rdata : 64'h0)
         | (addrHit_mtopei ? _mtopei_rdata : 64'h0)
         | (addrHit_mtopi ? _mtopi_rdata : 64'h0)
         | (~isModeVS & addrHit_siselect ? _siselect_rdata : 64'h0)
         | (~isModeVS & addrHit_sireg ? _sireg_rdata : 64'h0)
         | (~isModeVS & addrHit_stopei ? _stopei_rdata : 64'h0)
         | (~isModeVS & addrHit_stopi ? _stopi_rdata : 64'h0)
         | (isModeVS & addrHit_siselect | ~isModeVS & addrHit_vsiselect
              ? _vsiselect_rdata
              : 64'h0)
         | (isModeVS & addrHit_sireg | ~isModeVS & addrHit_vsireg
              ? _vsireg_rdata
              : 64'h0)
         | (isModeVS & addrHit_stopi | ~isModeVS & addrHit_vstopi
              ? _vstopi_rdata
              : 64'h0)
         | (isModeVS & addrHit_stopei | ~isModeVS & addrHit_vstopei
              ? _vstopei_rdata
              : 64'h0) | (addrHit_sbpctl ? _sbpctl_rdata : 64'h0)
         | (addrHit_spfctl ? _spfctl_rdata : 64'h0)
         | (addrHit_slvpredctl ? _slvpredctl_rdata : 64'h0)
         | (addrHit_smblockctl ? _smblockctl_rdata : 64'h0)
         | (addrHit_srnctl ? _srnctl_rdata : 64'h0)
         | (addrHit_mcorepwr ? _mcorepwr_rdata : 64'h0)
         | (addrHit_mflushpwr ? _mflushpwr_rdata : 64'h0)
         | (addrHit_pmpcfg_0 ? _pmpcfg_0_rdata : 64'h0)
         | (addrHit_pmpcfg_1 ? _pmpcfg_1_rdata : 64'h0)
         | (addrHit_pmpaddr_0 ? _pmpaddr_0_rdata : 64'h0)
         | (addrHit_pmpaddr_1 ? _pmpaddr_1_rdata : 64'h0)
         | (addrHit_pmpaddr_2 ? _pmpaddr_2_rdata : 64'h0)
         | (addrHit_pmpaddr_3 ? _pmpaddr_3_rdata : 64'h0)
         | (addrHit_pmpaddr_4 ? _pmpaddr_4_rdata : 64'h0)
         | (addrHit_pmpaddr_5 ? _pmpaddr_5_rdata : 64'h0)
         | (addrHit_pmpaddr_6 ? _pmpaddr_6_rdata : 64'h0)
         | (addrHit_pmpaddr_7 ? _pmpaddr_7_rdata : 64'h0)
         | (addrHit_pmpaddr_8 ? _pmpaddr_8_rdata : 64'h0)
         | (addrHit_pmpaddr_9 ? _pmpaddr_9_rdata : 64'h0)
         | (addrHit_pmpaddr_10 ? _pmpaddr_10_rdata : 64'h0)
         | (addrHit_pmpaddr_11 ? _pmpaddr_11_rdata : 64'h0)
         | (addrHit_pmpaddr_12 ? _pmpaddr_12_rdata : 64'h0)
         | (addrHit_pmpaddr_13 ? _pmpaddr_13_rdata : 64'h0)
         | (addrHit_pmpaddr_14 ? _pmpaddr_14_rdata : 64'h0)
         | (addrHit_pmpaddr_15 ? _pmpaddr_15_rdata : 64'h0)
         | (addrHit_pmacfg_0 ? _pmacfg_0_rdata : 64'h0)
         | (addrHit_pmacfg_1 ? _pmacfg_1_rdata : 64'h0)
         | (addrHit_pmaaddr_0 ? _pmaaddr_0_rdata : 64'h0)
         | (addrHit_pmaaddr_1 ? _pmaaddr_1_rdata : 64'h0)
         | (addrHit_pmaaddr_2 ? _pmaaddr_2_rdata : 64'h0)
         | (addrHit_pmaaddr_3 ? _pmaaddr_3_rdata : 64'h0)
         | (addrHit_pmaaddr_4 ? _pmaaddr_4_rdata : 64'h0)
         | (addrHit_pmaaddr_5 ? _pmaaddr_5_rdata : 64'h0)
         | (addrHit_pmaaddr_6 ? _pmaaddr_6_rdata : 64'h0)
         | (addrHit_pmaaddr_7 ? _pmaaddr_7_rdata : 64'h0)
         | (addrHit_pmaaddr_8 ? _pmaaddr_8_rdata : 64'h0)
         | (addrHit_pmaaddr_9 ? _pmaaddr_9_rdata : 64'h0)
         | (addrHit_pmaaddr_10 ? _pmaaddr_10_rdata : 64'h0)
         | (addrHit_pmaaddr_11 ? _pmaaddr_11_rdata : 64'h0)
         | (addrHit_pmaaddr_12 ? _pmaaddr_12_rdata : 64'h0)
         | (addrHit_pmaaddr_13 ? _pmaaddr_13_rdata : 64'h0)
         | (addrHit_pmaaddr_14 ? _pmaaddr_14_rdata : 64'h0)
         | (addrHit_pmaaddr_15 ? _pmaaddr_15_rdata : 64'h0)
       : 64'h0) | (fromAIA_rdata_valid ? fromAIA_rdata_bits_data : 64'h0);
  wire         rData_useComb =
    isNormalRead | fromAIA_rdata_valid | claimAIA;

  // ----- csrAccess / IMSIC 写打拍寄存器（toAIA_wdata）-----
  reg          csrAccess_REG;
  reg  [1:0]   toAIA_wdata_bits_op_REG;
  reg  [63:0]  toAIA_wdata_bits_data_REG;
  wire         csrAccess = wenLegalReg_last_REG | csrAccess_REG;
  wire         toAIA_addr_v =
    csrAccess & (addrHit_sireg & isModeVS | addrHit_vsireg);

  // ----- FSM 状态/锁存寄存器更新（照 NewCSR.scala state 机）-----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      wenLegalReg_last_REG     <= 1'h0;
      state                    <= 2'h0;
      io_out_bits_EX_II_r      <= 1'h0;
      io_out_bits_EX_VI_r      <= 1'h0;
      io_out_bits_rData_r      <= 64'h0;
      io_out_bits_isPerfCnt_r  <= 1'h0;
    end
    else begin
      wenLegalReg_last_REG <= _permitMod_io_out_hasLegalWen;
      if (|state) begin
        if (state == 2'h1) begin
          if (io_in_bits_redirectFlush)
            state <= 2'h0;
          else if (fromAIA_rdata_valid)
            state <= {~io_out_ready, 1'h0};
        end
        else if (state == 2'h2 & (io_in_bits_redirectFlush | io_out_ready))
          state <= 2'h0;
      end
      else if (io_in_valid & io_in_bits_redirectFlush)
        state <= 2'h0;
      else if (io_in_valid & asyncAccess)
        state <= 2'h1;
      else if (io_in_valid)
        state <= 2'h2;
      if (excValidThisCycle) begin
        io_out_bits_EX_II_r <= exII_comb;
        io_out_bits_EX_VI_r <= exVI_comb;
      end
      if (rData_useComb)
        io_out_bits_rData_r <= rData_comb;
      if (isNormalRead)
        io_out_bits_isPerfCnt_r <= addrInPerfCnt;
    end
  end

  // 步3：TLB PBMTE/PMM 打拍寄存器（无复位）与 ASID/VMID 变更寄存器（有复位）声明。
  reg io_tlb_mPBMTE_REG;
  reg io_tlb_hPBMTE_REG;
  reg [1:0] io_tlb_pmm_mseccfg_REG;
  reg [1:0] io_tlb_pmm_menvcfg_REG;
  reg [1:0] io_tlb_pmm_henvcfg_REG;
  reg [1:0] io_tlb_pmm_hstatus_REG;
  reg [1:0] io_tlb_pmm_senvcfg_REG;
  reg io_tlb_satpASIDChanged_last_REG;
  reg io_tlb_vsatpASIDChanged_last_REG;
  reg io_tlb_hgatpVMIDChanged_last_REG;

  // noCSRIllegalReg / csrAccess_REG / toAIA_wdata_*_REG：golden 为无复位寄存器
  // （每拍更新，独立 always；照 NewCSR.scala 5878/5885-5887；放进复位块会令 FM DFF 失配）。
  always @(posedge clock) begin
    if (isCsrAccess)
      noCSRIllegalReg <= noCSRIllegal;
    csrAccess_REG             <= ren;
    toAIA_wdata_bits_op_REG   <= io_in_bits_op;
    toAIA_wdata_bits_data_REG <= io_in_bits_src;
    // 步3：TLB PBMTE / PMM 打拍寄存器（无复位，每拍跟随对应 CSR 读出，golden 5888-5894）。
    io_tlb_mPBMTE_REG      <= _menvcfg_regOut_PBMTE;
    io_tlb_hPBMTE_REG      <= _henvcfg_regOut_PBMTE;
    io_tlb_pmm_mseccfg_REG <= _mseccfg_regOut_PMM;
    io_tlb_pmm_menvcfg_REG <= _menvcfg_regOut_PMM;
    io_tlb_pmm_henvcfg_REG <= _henvcfg_regOut_PMM;
    io_tlb_pmm_hstatus_REG <= _hstatus_regOut_HUPMM;
    io_tlb_pmm_senvcfg_REG <= _senvcfg_regOut_PMM;
  end

  // 步3：TLB ASID/VMID 变更打拍寄存器更新（有复位，golden 5613-5615/5840-5845）。
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      io_tlb_satpASIDChanged_last_REG  <= 1'h0;
      io_tlb_vsatpASIDChanged_last_REG <= 1'h0;
      io_tlb_hgatpVMIDChanged_last_REG <= 1'h0;
    end
    else begin
      io_tlb_satpASIDChanged_last_REG <=
        satp_wen & _satp_regOut_ASID != io_in_bits_wdata[59:44];
      io_tlb_vsatpASIDChanged_last_REG <=
        vsatp_wen & _vsatp_regOut_ASID != io_in_bits_wdata[59:44];
      io_tlb_hgatpVMIDChanged_last_REG <=
        hgatp_wen & _hgatp_regOut_VMID != io_in_bits_wdata[57:44];
    end
  end

  // ----- FSM 派生输出（步2：5 个口在 UT 收敛）-----
  assign io_in_ready  = ~(|state);
  assign io_out_valid = (waitIMSICValid | state == 2'h2) & ~io_in_bits_redirectFlush;
  assign io_out_bits_EX_II =
    excValidThisCycle ? exII_comb : io_out_bits_EX_II_r;
  assign io_out_bits_EX_VI =
    excValidThisCycle ? exVI_comb : io_out_bits_EX_VI_r;
  assign io_out_bits_rData = rData_useComb ? rData_comb : io_out_bits_rData_r;

  // ----- toAIA_wdata 输出（IMSIC 写转发 + claim）-----
  assign toAIA_wdata_valid =
    mireg_wen & _miselect_inIMSICRange | sireg_wen & _siselect_inIMSICRange
    | vsireg_wen & _vsiselect_inIMSICRange;
  assign toAIA_wdata_bits_op   = toAIA_wdata_bits_op_REG;
  assign toAIA_wdata_bits_data = toAIA_wdata_bits_data_REG;
  assign toAIA_mClaim  = mtopeiClaimWen;
  assign toAIA_sClaim  = stopeiClaimWen;
  assign toAIA_vsClaim = vstopeiClaimWen;

  // ----- isPerfCnt 输出（DataHoldBypass：普通读当拍取 addrInPerfCnt，否则锁存值）-----
  assign io_out_bits_isPerfCnt =
    isNormalRead ? addrInPerfCnt : io_out_bits_isPerfCnt_r;

  // ----- toAIA_addr 输出（IMSIC 间接寄存器寻址转发）-----
  assign toAIA_addr_valid =
    csrAccess & addrHit_mireg & _miselect_inIMSICRange | csrAccess
    & addrHit_sireg & ~isModeVS & _siselect_inIMSICRange | csrAccess
    & (addrHit_sireg & isModeVS | addrHit_vsireg)
    & _vsiselect_inIMSICRange;
  assign toAIA_addr_bits_addr =
    (csrAccess & addrHit_mireg ? _miselect_rdata[11:0] : 12'h0)
    | (csrAccess & addrHit_sireg & ~isModeVS ? _siselect_rdata[11:0] : 12'h0)
    | (csrAccess & (addrHit_sireg & isModeVS | addrHit_vsireg)
         ? _vsiselect_rdata[11:0]
         : 12'h0);
  assign toAIA_addr_bits_v = toAIA_addr_v;
  assign toAIA_addr_bits_prvm =
    {2{csrAccess & addrHit_mireg}}
    | {1'h0, csrAccess & addrHit_sireg & ~isModeVS | toAIA_addr_v};
  assign toAIA_vgein = _hstatus_regOut_VGEIN;



  // ========================================================================
  // 步3+ 待实现：仍以占位 '0 驱动的 glue/具名网（读出 OR-mux / FSM / trap 派发 /
  //   副作用 / perf / IMSIC / difftest 打拍）。步1/步2 已实装的译码 + 特权态在上方。
  //   以 _T_/_GEN_ 命名者为 golden 余项——待步9 gen 重映射为可读具名网后消除。
  // ========================================================================
  // ======================================================================
  // 步4/步9 辅助 wire（trap 特权命中 / trigger 可写 / VS-EIP 投影）。`default_nettype none
  //   → 先声明后用，故置于本节最前。
  // ======================================================================
  wire PrvmIsS_1 = _trapHandleMod_io_out_entryPrivState_PRVM == 2'h1;  // golden 3182
  // trigger 可写：tdata1.DMODE(=[59]) 置位时仅 debug 态可写，否则恒可写（golden 5231）。
  wire triggerCanWrite = _tdata1_rdata[59] & debugMode | ~_tdata1_rdata[59];
  // VS-EIP 投影：hgeip 右移 VGEIN（golden 5388-5392）。供 platformIRPVseip change-detect。
  wire [63:0] hgeipVgeinShamt = {58'h0, _hstatus_regOut_VGEIN};
  wire [63:0] hgeipForVseip_6  = _hgeip_rdata >> hgeipVgeinShamt;
  wire [63:0] hgeipForVseip_15 = _hgeip_rdata >> hgeipVgeinShamt;
  wire [63:0] hgeipForVseip_10 = _hgeip_rdata >> hgeipVgeinShamt;
  wire [63:0] hgeipForVseip_18 = _hgeip_rdata >> hgeipVgeinShamt;
  // 步4：PMP/PMA cfg 写数据按字节切片（zero-ext 到 64bit，送各 pmpcfg/pmacfg 子模块的
  //   写口；golden 3146-3161）。pmpCfgWdataByte_0..7=pmpCfgWData 8 字节，pmaCfgWdataByte_0..15=pmaCfgWdata 8 字节。
  assign pmpCfgWdataByte_0  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[7:0]};
  assign pmpCfgWdataByte_1  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[15:8]};
  assign pmpCfgWdataByte_2  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[23:16]};
  assign pmpCfgWdataByte_3  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[31:24]};
  assign pmpCfgWdataByte_4  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[39:32]};
  assign pmpCfgWdataByte_5  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[47:40]};
  assign pmpCfgWdataByte_6  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[55:48]};
  assign pmpCfgWdataByte_7  = {56'h0, _pmpEntryMod_io_out_pmpCfgWData[63:56]};
  assign pmaCfgWdataByte_0  = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[7:0]};
  assign pmaCfgWdataByte_1  = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[15:8]};
  assign pmaCfgWdataByte_2 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[23:16]};
  assign pmaCfgWdataByte_3 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[31:24]};
  assign pmaCfgWdataByte_4 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[39:32]};
  assign pmaCfgWdataByte_5 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[47:40]};
  assign pmaCfgWdataByte_6 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[55:48]};
  assign pmaCfgWdataByte_7 = {56'h0, _pmaEntryMod_io_out_pmaCfgWdata[63:56]};
  // 步4/步9 新增寄存器声明（`default_nettype none → 先声明后用）。
  //   pendingTrap：trap 待提交锁存（送 trapValid）。change-detect 两级快照：difftest 事件 valid。
  reg pendingTrap;
  reg platformIRPMeipChange_REG, platformIRPMeipChange_REG_1;
  reg platformIRPMtipChange_REG, platformIRPMtipChange_REG_1;
  reg platformIRPMsipChange_REG, platformIRPMsipChange_REG_1;
  reg platformIRPSeipChange_REG, platformIRPSeipChange_REG_1;
  reg platformIRPStipChange_REG, platformIRPStipChange_REG_1;
  reg platformIRPVseipChange_REG_2, platformIRPVseipChange_REG_3;
  reg platformIRPVstipChange_REG, platformIRPVstipChange_REG_1;
  reg fromAIAMeipChange_REG, fromAIAMeipChange_REG_1;
  reg fromAIASeipChange_REG, fromAIASeipChange_REG_1;
  reg lcofiReqChange_REG, lcofiReqChange_REG_1;
  reg diffNonRegInterruptPendingEvent_valid_REG;
  reg diffMhpmeventOverflowEvent_valid_REG;
  reg diffMhpmeventOverflowEvent_valid_REG_1,  diffMhpmeventOverflowEvent_valid_REG_2;
  reg diffMhpmeventOverflowEvent_valid_REG_3,  diffMhpmeventOverflowEvent_valid_REG_4;
  reg diffMhpmeventOverflowEvent_valid_REG_5,  diffMhpmeventOverflowEvent_valid_REG_6;
  reg diffMhpmeventOverflowEvent_valid_REG_7,  diffMhpmeventOverflowEvent_valid_REG_8;
  reg diffMhpmeventOverflowEvent_valid_REG_9,  diffMhpmeventOverflowEvent_valid_REG_10;
  reg diffMhpmeventOverflowEvent_valid_REG_11, diffMhpmeventOverflowEvent_valid_REG_12;
  reg diffMhpmeventOverflowEvent_valid_REG_13, diffMhpmeventOverflowEvent_valid_REG_14;
  reg diffMhpmeventOverflowEvent_valid_REG_15, diffMhpmeventOverflowEvent_valid_REG_16;
  reg diffMhpmeventOverflowEvent_valid_REG_17, diffMhpmeventOverflowEvent_valid_REG_18;
  reg diffMhpmeventOverflowEvent_valid_REG_19, diffMhpmeventOverflowEvent_valid_REG_20;
  reg diffMhpmeventOverflowEvent_valid_REG_21, diffMhpmeventOverflowEvent_valid_REG_22;
  reg diffMhpmeventOverflowEvent_valid_REG_23, diffMhpmeventOverflowEvent_valid_REG_24;
  reg diffMhpmeventOverflowEvent_valid_REG_25, diffMhpmeventOverflowEvent_valid_REG_26;
  reg diffMhpmeventOverflowEvent_valid_REG_27, diffMhpmeventOverflowEvent_valid_REG_28;
  reg diffMhpmeventOverflowEvent_valid_REG_29, diffMhpmeventOverflowEvent_valid_REG_30;
  reg diffMhpmeventOverflowEvent_valid_REG_31, diffMhpmeventOverflowEvent_valid_REG_32;
  reg diffMhpmeventOverflowEvent_valid_REG_33, diffMhpmeventOverflowEvent_valid_REG_34;
  reg diffMhpmeventOverflowEvent_valid_REG_35, diffMhpmeventOverflowEvent_valid_REG_36;
  reg diffMhpmeventOverflowEvent_valid_REG_37, diffMhpmeventOverflowEvent_valid_REG_38;
  reg diffMhpmeventOverflowEvent_valid_REG_39, diffMhpmeventOverflowEvent_valid_REG_40;
  reg diffMhpmeventOverflowEvent_valid_REG_41, diffMhpmeventOverflowEvent_valid_REG_42;
  reg diffMhpmeventOverflowEvent_valid_REG_43, diffMhpmeventOverflowEvent_valid_REG_44;
  reg diffMhpmeventOverflowEvent_valid_REG_45, diffMhpmeventOverflowEvent_valid_REG_46;
  reg diffMhpmeventOverflowEvent_valid_REG_47, diffMhpmeventOverflowEvent_valid_REG_48;
  reg diffMhpmeventOverflowEvent_valid_REG_49, diffMhpmeventOverflowEvent_valid_REG_50;
  reg diffMhpmeventOverflowEvent_valid_REG_51, diffMhpmeventOverflowEvent_valid_REG_52;
  reg diffMhpmeventOverflowEvent_valid_REG_53, diffMhpmeventOverflowEvent_valid_REG_54;
  reg diffMhpmeventOverflowEvent_valid_REG_55, diffMhpmeventOverflowEvent_valid_REG_56;
  reg diffMhpmeventOverflowEvent_valid_REG_57;
  reg [63:0] mtopeiChange_REG;
  reg [63:0] stopeiChange_REG;
  reg [5:0]  vstopeiChange_REG;
  reg [4:0]  hgeipChange_REG;
  reg        diffCustomMflushpwr_valid_REG;
  // 步9：difftest mhpmevent 溢出事件 valid 向量（29 路；每路 = 计数器 OF 与其两级
  //   change-detect 寄存器的边沿差；golden 5478-5536）。
  assign diffMhpmeventOverflowVec = {
    ~_mhpmcounters_28_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_56 | _mhpmcounters_28_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_57,
    ~_mhpmcounters_27_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_54 | _mhpmcounters_27_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_55,
    ~_mhpmcounters_26_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_52 | _mhpmcounters_26_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_53,
    ~_mhpmcounters_25_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_50 | _mhpmcounters_25_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_51,
    ~_mhpmcounters_24_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_48 | _mhpmcounters_24_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_49,
    ~_mhpmcounters_23_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_46 | _mhpmcounters_23_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_47,
    ~_mhpmcounters_22_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_44 | _mhpmcounters_22_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_45,
    ~_mhpmcounters_21_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_42 | _mhpmcounters_21_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_43,
    ~_mhpmcounters_20_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_40 | _mhpmcounters_20_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_41,
    ~_mhpmcounters_19_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_38 | _mhpmcounters_19_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_39,
    ~_mhpmcounters_18_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_36 | _mhpmcounters_18_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_37,
    ~_mhpmcounters_17_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_34 | _mhpmcounters_17_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_35,
    ~_mhpmcounters_16_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_32 | _mhpmcounters_16_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_33,
    ~_mhpmcounters_15_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_30 | _mhpmcounters_15_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_31,
    ~_mhpmcounters_14_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_28 | _mhpmcounters_14_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_29,
    ~_mhpmcounters_13_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_26 | _mhpmcounters_13_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_27,
    ~_mhpmcounters_12_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_24 | _mhpmcounters_12_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_25,
    ~_mhpmcounters_11_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_22 | _mhpmcounters_11_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_23,
    ~_mhpmcounters_10_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_20 | _mhpmcounters_10_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_21,
    ~_mhpmcounters_9_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_18 | _mhpmcounters_9_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_19,
    ~_mhpmcounters_8_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_16 | _mhpmcounters_8_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_17,
    ~_mhpmcounters_7_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_14 | _mhpmcounters_7_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_15,
    ~_mhpmcounters_6_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_12 | _mhpmcounters_6_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_13,
    ~_mhpmcounters_5_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_10 | _mhpmcounters_5_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_11,
    ~_mhpmcounters_4_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_8 | _mhpmcounters_4_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_9,
    ~_mhpmcounters_3_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_6 | _mhpmcounters_3_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_7,
    ~_mhpmcounters_2_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_4 | _mhpmcounters_2_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_5,
    ~_mhpmcounters_1_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG_2 | _mhpmcounters_1_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_3,
    ~_mhpmcounters_0_toMhpmeventOF & diffMhpmeventOverflowEvent_valid_REG   | _mhpmcounters_0_toMhpmeventOF & ~diffMhpmeventOverflowEvent_valid_REG_1
  };
  // 步9：VS-EIP（hgeip >> VGEIN 的最低位），送 diffNonRegInterruptPending 模块（golden 5418-5419）。
  assign diffHgeipForVseip = _hgeip_rdata >> hgeipVgeinShamt;
  // 合法写使能（wenLegalReg_last_REG & 对应地址命中；golden 3006/3008/2843/2937/2986/3010/2952/3001）。
  //   flushPipe 与 TLB ASIDChanged 副作用共用。
  assign fcsr_wAliasFfm_wen = wenLegalReg_last_REG & addrHit_frm;  // frm
  assign fcsr_wen         = wenLegalReg_last_REG & addrHit_fcsr;  // fcsr
  assign henvcfg_wen = wenLegalReg_last_REG & addrHit_henvcfg;  // henvcfg
  assign hgatp_wen = wenLegalReg_last_REG & addrHit_hgatp;  // hgatp 合法写
  assign htimedelta_wen = wenLegalReg_last_REG & addrHit_htimedelta;  // htimedelta
  // FS/VS 关闭检测（mstatus/vsstatus 对应域 == 0；golden 3137-3140，flushPipe 与 toDecode 共用）。
  assign mstatusFsIsOff   = _mstatus_regOut_FS  == 2'h0;
  assign vsFsIsOff = _vsstatus_regOut_FS == 2'h0;
  assign mstatusVsIsOff   = _mstatus_regOut_VS  == 2'h0;
  assign vsVsIsOff = _vsstatus_regOut_VS == 2'h0;
  // 步9：local counter overflow interrupt 请求向量（29 路；每路 = 计数器 OF & ~mhpmeventN.OF
  //   的禁止位；golden 5272-5301）。供 diffNonRegInterruptPending lcofiReqChange 检测。
  assign lcofiReqVec = {
    _mhpmcounters_28_toMhpmeventOF & ~_Mhpmevent31_rdata[63],
    _mhpmcounters_27_toMhpmeventOF & ~_Mhpmevent30_rdata[63],
    _mhpmcounters_26_toMhpmeventOF & ~_Mhpmevent29_rdata[63],
    _mhpmcounters_25_toMhpmeventOF & ~_Mhpmevent28_rdata[63],
    _mhpmcounters_24_toMhpmeventOF & ~_Mhpmevent27_rdata[63],
    _mhpmcounters_23_toMhpmeventOF & ~_Mhpmevent26_rdata[63],
    _mhpmcounters_22_toMhpmeventOF & ~_Mhpmevent25_rdata[63],
    _mhpmcounters_21_toMhpmeventOF & ~_Mhpmevent24_rdata[63],
    _mhpmcounters_20_toMhpmeventOF & ~_Mhpmevent23_rdata[63],
    _mhpmcounters_19_toMhpmeventOF & ~_Mhpmevent22_rdata[63],
    _mhpmcounters_18_toMhpmeventOF & ~_Mhpmevent21_rdata[63],
    _mhpmcounters_17_toMhpmeventOF & ~_Mhpmevent20_rdata[63],
    _mhpmcounters_16_toMhpmeventOF & ~_Mhpmevent19_rdata[63],
    _mhpmcounters_15_toMhpmeventOF & ~_Mhpmevent18_rdata[63],
    _mhpmcounters_14_toMhpmeventOF & ~_Mhpmevent17_rdata[63],
    _mhpmcounters_13_toMhpmeventOF & ~_Mhpmevent16_rdata[63],
    _mhpmcounters_12_toMhpmeventOF & ~_Mhpmevent15_rdata[63],
    _mhpmcounters_11_toMhpmeventOF & ~_Mhpmevent14_rdata[63],
    _mhpmcounters_10_toMhpmeventOF & ~_Mhpmevent13_rdata[63],
    _mhpmcounters_9_toMhpmeventOF & ~_Mhpmevent12_rdata[63],
    _mhpmcounters_8_toMhpmeventOF & ~_Mhpmevent11_rdata[63],
    _mhpmcounters_7_toMhpmeventOF & ~_Mhpmevent10_rdata[63],
    _mhpmcounters_6_toMhpmeventOF & ~_Mhpmevent9_rdata[63],
    _mhpmcounters_5_toMhpmeventOF & ~_Mhpmevent8_rdata[63],
    _mhpmcounters_4_toMhpmeventOF & ~_Mhpmevent7_rdata[63],
    _mhpmcounters_3_toMhpmeventOF & ~_Mhpmevent6_rdata[63],
    _mhpmcounters_2_toMhpmeventOF & ~_Mhpmevent5_rdata[63],
    _mhpmcounters_1_toMhpmeventOF & ~_Mhpmevent4_rdata[63],
    _mhpmcounters_0_toMhpmeventOF & ~_Mhpmevent3_rdata[63]
  };
  assign menvcfg_wen = wenLegalReg_last_REG & addrHit_menvcfg;  // menvcfg
  // mireg_wen 在步2 FSM 块驱动（IMSIC 写）。
  assign mstatus_wAliasSstatus_wen =
    wenLegalReg_last_REG & ~isModeVS & addrHit_sstatus;  // sstatus 别名写
  assign mstatus_wen = wenLegalReg_last_REG & addrHit_mstatus;  // mstatus
  assign satp_wen = wenLegalReg_last_REG & ~isModeVS & addrHit_satp;  // satp
  // sireg_wen 在步2 FSM 块驱动（IMSIC sireg 写）。
  assign stimecmp_wen =
    wenLegalReg_last_REG & ~isModeVS & addrHit_stimecmp;  // stimecmp（S 别名，非 VS 态）
  // tdata2 写口选择：按 tselect 当前指向哪个 trigger 槽（golden 2776-2778）。
  assign triggerSel0Hit = _tselect_rdata == 2'h0;
  assign triggerSel1Hit = _tselect_rdata == 2'h1;
  assign triggerSel2Hit = _tselect_rdata == 2'h2;
  // trapEntryM 进入时的虚拟化态判定（V 或 MPRV+NMIE+MPP!=M+MPV；golden 3188-3190）。
  assign _trapEntryMEvent_in_dMode_V_WIRE =
    V | _mstatus_regOut_MPRV & _mnstatus_regOut_NMIE
        & (_mstatus_regOut_MPP != 2'h3) & _mstatus_regOut_MPV;
  assign vsatp_wen =
    wenLegalReg_last_REG & (isModeVS & addrHit_satp | ~isModeVS & addrHit_vsatp);
  // vsireg_wen 在步2 FSM 块驱动（IMSIC vsireg 写）。
  assign vsstatus_wen =
    wenLegalReg_last_REG & (isModeVS & addrHit_sstatus | ~isModeVS & addrHit_vsstatus);
  assign vstart_wen = wenLegalReg_last_REG & addrHit_vstart;  // vstart
  assign vstimecmp_wen =
    wenLegalReg_last_REG
    & (isModeVS & addrHit_stimecmp | ~isModeVS & addrHit_vstimecmp);  // vstimecmp（VS 别名 stimecmp）
  // countingEn 各路组合式（每拍计算，供下方寄存器锁存；与 golden 5724-5839 逐路等价）。
  wire countEn_M3 = isModeM & ~_Mhpmevent3_rdata[62] | isModeHS & ~_Mhpmevent3_rdata[61] | isModeHU & ~_Mhpmevent3_rdata[60] | isModeVS & ~_Mhpmevent3_rdata[59] | isModeVU & ~_Mhpmevent3_rdata[58];
  wire countEn_M4 = isModeM & ~_Mhpmevent4_rdata[62] | isModeHS & ~_Mhpmevent4_rdata[61] | isModeHU & ~_Mhpmevent4_rdata[60] | isModeVS & ~_Mhpmevent4_rdata[59] | isModeVU & ~_Mhpmevent4_rdata[58];
  wire countEn_M5 = isModeM & ~_Mhpmevent5_rdata[62] | isModeHS & ~_Mhpmevent5_rdata[61] | isModeHU & ~_Mhpmevent5_rdata[60] | isModeVS & ~_Mhpmevent5_rdata[59] | isModeVU & ~_Mhpmevent5_rdata[58];
  wire countEn_M6 = isModeM & ~_Mhpmevent6_rdata[62] | isModeHS & ~_Mhpmevent6_rdata[61] | isModeHU & ~_Mhpmevent6_rdata[60] | isModeVS & ~_Mhpmevent6_rdata[59] | isModeVU & ~_Mhpmevent6_rdata[58];
  wire countEn_M7 = isModeM & ~_Mhpmevent7_rdata[62] | isModeHS & ~_Mhpmevent7_rdata[61] | isModeHU & ~_Mhpmevent7_rdata[60] | isModeVS & ~_Mhpmevent7_rdata[59] | isModeVU & ~_Mhpmevent7_rdata[58];
  wire countEn_M8 = isModeM & ~_Mhpmevent8_rdata[62] | isModeHS & ~_Mhpmevent8_rdata[61] | isModeHU & ~_Mhpmevent8_rdata[60] | isModeVS & ~_Mhpmevent8_rdata[59] | isModeVU & ~_Mhpmevent8_rdata[58];
  wire countEn_M9 = isModeM & ~_Mhpmevent9_rdata[62] | isModeHS & ~_Mhpmevent9_rdata[61] | isModeHU & ~_Mhpmevent9_rdata[60] | isModeVS & ~_Mhpmevent9_rdata[59] | isModeVU & ~_Mhpmevent9_rdata[58];
  wire countEn_M10 = isModeM & ~_Mhpmevent10_rdata[62] | isModeHS & ~_Mhpmevent10_rdata[61] | isModeHU & ~_Mhpmevent10_rdata[60] | isModeVS & ~_Mhpmevent10_rdata[59] | isModeVU & ~_Mhpmevent10_rdata[58];
  wire countEn_M11 = isModeM & ~_Mhpmevent11_rdata[62] | isModeHS & ~_Mhpmevent11_rdata[61] | isModeHU & ~_Mhpmevent11_rdata[60] | isModeVS & ~_Mhpmevent11_rdata[59] | isModeVU & ~_Mhpmevent11_rdata[58];
  wire countEn_M12 = isModeM & ~_Mhpmevent12_rdata[62] | isModeHS & ~_Mhpmevent12_rdata[61] | isModeHU & ~_Mhpmevent12_rdata[60] | isModeVS & ~_Mhpmevent12_rdata[59] | isModeVU & ~_Mhpmevent12_rdata[58];
  wire countEn_M13 = isModeM & ~_Mhpmevent13_rdata[62] | isModeHS & ~_Mhpmevent13_rdata[61] | isModeHU & ~_Mhpmevent13_rdata[60] | isModeVS & ~_Mhpmevent13_rdata[59] | isModeVU & ~_Mhpmevent13_rdata[58];
  wire countEn_M14 = isModeM & ~_Mhpmevent14_rdata[62] | isModeHS & ~_Mhpmevent14_rdata[61] | isModeHU & ~_Mhpmevent14_rdata[60] | isModeVS & ~_Mhpmevent14_rdata[59] | isModeVU & ~_Mhpmevent14_rdata[58];
  wire countEn_M15 = isModeM & ~_Mhpmevent15_rdata[62] | isModeHS & ~_Mhpmevent15_rdata[61] | isModeHU & ~_Mhpmevent15_rdata[60] | isModeVS & ~_Mhpmevent15_rdata[59] | isModeVU & ~_Mhpmevent15_rdata[58];
  wire countEn_M16 = isModeM & ~_Mhpmevent16_rdata[62] | isModeHS & ~_Mhpmevent16_rdata[61] | isModeHU & ~_Mhpmevent16_rdata[60] | isModeVS & ~_Mhpmevent16_rdata[59] | isModeVU & ~_Mhpmevent16_rdata[58];
  wire countEn_M17 = isModeM & ~_Mhpmevent17_rdata[62] | isModeHS & ~_Mhpmevent17_rdata[61] | isModeHU & ~_Mhpmevent17_rdata[60] | isModeVS & ~_Mhpmevent17_rdata[59] | isModeVU & ~_Mhpmevent17_rdata[58];
  wire countEn_M18 = isModeM & ~_Mhpmevent18_rdata[62] | isModeHS & ~_Mhpmevent18_rdata[61] | isModeHU & ~_Mhpmevent18_rdata[60] | isModeVS & ~_Mhpmevent18_rdata[59] | isModeVU & ~_Mhpmevent18_rdata[58];
  wire countEn_M19 = isModeM & ~_Mhpmevent19_rdata[62] | isModeHS & ~_Mhpmevent19_rdata[61] | isModeHU & ~_Mhpmevent19_rdata[60] | isModeVS & ~_Mhpmevent19_rdata[59] | isModeVU & ~_Mhpmevent19_rdata[58];
  wire countEn_M20 = isModeM & ~_Mhpmevent20_rdata[62] | isModeHS & ~_Mhpmevent20_rdata[61] | isModeHU & ~_Mhpmevent20_rdata[60] | isModeVS & ~_Mhpmevent20_rdata[59] | isModeVU & ~_Mhpmevent20_rdata[58];
  wire countEn_M21 = isModeM & ~_Mhpmevent21_rdata[62] | isModeHS & ~_Mhpmevent21_rdata[61] | isModeHU & ~_Mhpmevent21_rdata[60] | isModeVS & ~_Mhpmevent21_rdata[59] | isModeVU & ~_Mhpmevent21_rdata[58];
  wire countEn_M22 = isModeM & ~_Mhpmevent22_rdata[62] | isModeHS & ~_Mhpmevent22_rdata[61] | isModeHU & ~_Mhpmevent22_rdata[60] | isModeVS & ~_Mhpmevent22_rdata[59] | isModeVU & ~_Mhpmevent22_rdata[58];
  wire countEn_M23 = isModeM & ~_Mhpmevent23_rdata[62] | isModeHS & ~_Mhpmevent23_rdata[61] | isModeHU & ~_Mhpmevent23_rdata[60] | isModeVS & ~_Mhpmevent23_rdata[59] | isModeVU & ~_Mhpmevent23_rdata[58];
  wire countEn_M24 = isModeM & ~_Mhpmevent24_rdata[62] | isModeHS & ~_Mhpmevent24_rdata[61] | isModeHU & ~_Mhpmevent24_rdata[60] | isModeVS & ~_Mhpmevent24_rdata[59] | isModeVU & ~_Mhpmevent24_rdata[58];
  wire countEn_M25 = isModeM & ~_Mhpmevent25_rdata[62] | isModeHS & ~_Mhpmevent25_rdata[61] | isModeHU & ~_Mhpmevent25_rdata[60] | isModeVS & ~_Mhpmevent25_rdata[59] | isModeVU & ~_Mhpmevent25_rdata[58];
  wire countEn_M26 = isModeM & ~_Mhpmevent26_rdata[62] | isModeHS & ~_Mhpmevent26_rdata[61] | isModeHU & ~_Mhpmevent26_rdata[60] | isModeVS & ~_Mhpmevent26_rdata[59] | isModeVU & ~_Mhpmevent26_rdata[58];
  wire countEn_M27 = isModeM & ~_Mhpmevent27_rdata[62] | isModeHS & ~_Mhpmevent27_rdata[61] | isModeHU & ~_Mhpmevent27_rdata[60] | isModeVS & ~_Mhpmevent27_rdata[59] | isModeVU & ~_Mhpmevent27_rdata[58];
  wire countEn_M28 = isModeM & ~_Mhpmevent28_rdata[62] | isModeHS & ~_Mhpmevent28_rdata[61] | isModeHU & ~_Mhpmevent28_rdata[60] | isModeVS & ~_Mhpmevent28_rdata[59] | isModeVU & ~_Mhpmevent28_rdata[58];
  wire countEn_M29 = isModeM & ~_Mhpmevent29_rdata[62] | isModeHS & ~_Mhpmevent29_rdata[61] | isModeHU & ~_Mhpmevent29_rdata[60] | isModeVS & ~_Mhpmevent29_rdata[59] | isModeVU & ~_Mhpmevent29_rdata[58];
  wire countEn_M30 = isModeM & ~_Mhpmevent30_rdata[62] | isModeHS & ~_Mhpmevent30_rdata[61] | isModeHU & ~_Mhpmevent30_rdata[60] | isModeVS & ~_Mhpmevent30_rdata[59] | isModeVU & ~_Mhpmevent30_rdata[58];
  wire countEn_M31 = isModeM & ~_Mhpmevent31_rdata[62] | isModeHS & ~_Mhpmevent31_rdata[61] | isModeHU & ~_Mhpmevent31_rdata[60] | isModeVS & ~_Mhpmevent31_rdata[59] | isModeVU & ~_Mhpmevent31_rdata[58];
  // 步3：性能计数使能 countingEn_N（送各 mhpmcounter 子模块）。每路按当前特权态
  //   与对应 mhpmeventN+3 的 inhibit 位（[62:58] 对应 M/HS/HU/VS/VU）判定是否计数。
  //   有复位寄存器，golden 5584-5612(复位) / 5724-5839(更新)。countingEn_N ↔ Mhpmevent(N+3)。
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      countingEn_0  <= 1'h0; countingEn_1  <= 1'h0; countingEn_2  <= 1'h0;
      countingEn_3  <= 1'h0; countingEn_4  <= 1'h0; countingEn_5  <= 1'h0;
      countingEn_6  <= 1'h0; countingEn_7  <= 1'h0; countingEn_8  <= 1'h0;
      countingEn_9  <= 1'h0; countingEn_10 <= 1'h0; countingEn_11 <= 1'h0;
      countingEn_12 <= 1'h0; countingEn_13 <= 1'h0; countingEn_14 <= 1'h0;
      countingEn_15 <= 1'h0; countingEn_16 <= 1'h0; countingEn_17 <= 1'h0;
      countingEn_18 <= 1'h0; countingEn_19 <= 1'h0; countingEn_20 <= 1'h0;
      countingEn_21 <= 1'h0; countingEn_22 <= 1'h0; countingEn_23 <= 1'h0;
      countingEn_24 <= 1'h0; countingEn_25 <= 1'h0; countingEn_26 <= 1'h0;
      countingEn_27 <= 1'h0; countingEn_28 <= 1'h0;
    end
    else begin
      countingEn_0  <= countEn_M3;   countingEn_1  <= countEn_M4;
      countingEn_2  <= countEn_M5;   countingEn_3  <= countEn_M6;
      countingEn_4  <= countEn_M7;   countingEn_5  <= countEn_M8;
      countingEn_6  <= countEn_M9;   countingEn_7  <= countEn_M10;
      countingEn_8  <= countEn_M11;  countingEn_9  <= countEn_M12;
      countingEn_10 <= countEn_M13;  countingEn_11 <= countEn_M14;
      countingEn_12 <= countEn_M15;  countingEn_13 <= countEn_M16;
      countingEn_14 <= countEn_M17;  countingEn_15 <= countEn_M18;
      countingEn_16 <= countEn_M19;  countingEn_17 <= countEn_M20;
      countingEn_18 <= countEn_M21;  countingEn_19 <= countEn_M22;
      countingEn_20 <= countEn_M23;  countingEn_21 <= countEn_M24;
      countingEn_22 <= countEn_M25;  countingEn_23 <= countEn_M26;
      countingEn_24 <= countEn_M27;  countingEn_25 <= countEn_M28;
      countingEn_26 <= countEn_M29;  countingEn_27 <= countEn_M30;
      countingEn_28 <= countEn_M31;
    end
  end
  // 步3：difftest 异常 PC 打拍（trap 当拍按页表模式 sign-extend trap pc；golden 5902-5909）。
  //   isSv39/isSv48：当前有效页表模式（satp/vsatp.MODE，HS/HU 用 satp，V 态用 vsatp）。
  wire isSv39_diff =
    (isModeHS | isModeHU) & (_satp_regOut_MODE == 4'h8)
    | (isModeVS | isModeVU) & (_vsatp_regOut_MODE == 4'h8);
  wire isSv48_diff =
    (isModeHS | isModeHU) & (_satp_regOut_MODE == 4'h9)
    | (isModeVS | isModeVU) & (_vsatp_regOut_MODE == 4'h9);
  always @(posedge clock) begin
    if (io_fromRob_trap_valid)
      diffArchEvent_exceptionPC_r <=
        (isSv39_diff
           ? {{25{io_fromRob_trap_bits_pc[38]}}, io_fromRob_trap_bits_pc[38:0]}
           : 64'h0)
        | (isSv48_diff
             ? {{16{io_fromRob_trap_bits_pc[47]}}, io_fromRob_trap_bits_pc[47:0]}
             : 64'h0)
        | (isSv39_diff | isSv48_diff ? 64'h0 : {16'h0, io_fromRob_trap_bits_pc[47:0]});
  end
  // 步3：difftest 架构事件打拍寄存器（trap 当拍锁存 cause/NMI/路由；golden 5856-5915）。
  //   trapNO：中断/异常号——hvictl 注入时取 hvictl.IID，否则取 trapHandle 的 ExceptionCode。
  wire diffArchHvictlInject =
    virtualInterruptIsHvictlInject & io_fromRob_trap_valid;
  wire [62:0] trapNO =
    diffArchHvictlInject
      ? {51'h0, _hvictl_regOut_IID}
      : _trapHandleMod_io_out_causeNO_ExceptionCode;
  always @(posedge clock) begin
    if (io_fromRob_trap_valid) begin
      diffArchEvent_interrupt_r <=
        _trapHandleMod_io_out_causeNO_Interrupt ? trapNO : 63'h0;
      diffArchEvent_exception_r <=
        _trapHandleMod_io_out_causeNO_Interrupt ? 63'h0 : trapNO;
      diffArchEvent_hasNMI_r <= nmi & io_fromRob_trap_valid;
      diffArchEvent_irToHS_r <= irToHS;
      diffArchEvent_irToVS_r <= irToVS;
    end
    diffArchEvent_virtualInterruptIsHvictlInject_REG <= diffArchHvictlInject;
  end
  // 步3：difftest coreid = {2'h0, hartId}（golden 5369）；致命错误事件直通（golden 5361-5362）。
  assign diffCSRState_coreid = {2'h0, io_fromTop_hartId};
  assign diffCriticalErrorEvent_criticalError = criticalErrorState & ~_dcsr_regOut_CETRIG;
  // 步9：difftest 非寄存器中断 pending 事件 valid（任一 platformIRP/AIA/sstc/lcofi 源相对
  //   其两级 change-detect 寄存器发生边沿；golden 5402-5417）。复位拍强制为 0。
  assign diffNonRegInterruptPendingEvent_valid =
    (~platformIRP_MEIP & platformIRPMeipChange_REG | platformIRP_MEIP & ~platformIRPMeipChange_REG_1
     | ~platformIRP_MTIP & platformIRPMtipChange_REG | platformIRP_MTIP & ~platformIRPMtipChange_REG_1
     | ~platformIRP_MSIP & platformIRPMsipChange_REG | platformIRP_MSIP & ~platformIRPMsipChange_REG_1
     | ~platformIRP_SEIP & platformIRPSeipChange_REG | platformIRP_SEIP & ~platformIRPSeipChange_REG_1
     | ~_sstcIRGen_o_STIP & platformIRPStipChange_REG | _sstcIRGen_o_STIP & ~platformIRPStipChange_REG_1
     | ~hgeipForVseip_6[0] & platformIRPVseipChange_REG_2
     | hgeipForVseip_15[0] & ~platformIRPVseipChange_REG_3
     | ~_sstcIRGen_o_VSTIP & platformIRPVstipChange_REG | _sstcIRGen_o_VSTIP & ~platformIRPVstipChange_REG_1
     | ~fromAIA_meip & fromAIAMeipChange_REG | fromAIA_meip & ~fromAIAMeipChange_REG_1
     | ~fromAIA_seip & fromAIASeipChange_REG | fromAIA_seip & ~fromAIASeipChange_REG_1
     | ~(|lcofiReqVec) & lcofiReqChange_REG | (|lcofiReqVec) & ~lcofiReqChange_REG_1
     | diffNonRegInterruptPendingEvent_valid_REG)
    & ~reset;
  // 步9：difftest AIA 同步事件 valid（mtopei/stopei/vstopei/hgeip 相对其打拍快照变化；golden 5541-5544）。
  assign diffSyncAIAEvent_valid =
    mtopeiChange_REG != {37'h0, fromAIA_mtopei_IID, 5'h0, fromAIA_mtopei_IPRIO}
    | stopeiChange_REG != {37'h0, fromAIA_stopei_IID, 5'h0, fromAIA_stopei_IPRIO}
    | vstopeiChange_REG != _hstatus_regOut_VGEIN | hgeipChange_REG != fromAIA_vseip;
  // 步9：difftest custom mflushpwr 事件 valid（l2FlushDone 相对其打拍快照变化；golden 5546-5547）。
  assign diffCustomMflushpwr_valid =
    diffCustomMflushpwr_valid_REG != io_fromTop_l2FlushDone;
  // 步3：进入 debug 模式 = debug 模块报硬件 debug trap 且当前不在 debug 模式
  //   （golden 5236；被 criticalErrorStateInCSR 消费）。
  assign entryDebugMode = _debugMod_io_out_hasDebugTrap & ~debugMode;
  // 步3：PMP/PMA cfg 读出打包（16×8bit 拼成 128bit，回送各 pmpcfg/pmacfg 子模块；golden 2779-2812）。
  assign pmaCfgRead =
    {_pmacfgs_15_rdata, _pmacfgs_14_rdata, _pmacfgs_13_rdata, _pmacfgs_12_rdata,
     _pmacfgs_11_rdata, _pmacfgs_10_rdata, _pmacfgs_9_rdata,  _pmacfgs_8_rdata,
     _pmacfgs_7_rdata,  _pmacfgs_6_rdata,  _pmacfgs_5_rdata,  _pmacfgs_4_rdata,
     _pmacfgs_3_rdata,  _pmacfgs_2_rdata,  _pmacfgs_1_rdata,  _pmacfgs_0_rdata};
  assign pmpCfgRead =
    {_pmpcfgs_15_rdata, _pmpcfgs_14_rdata, _pmpcfgs_13_rdata, _pmpcfgs_12_rdata,
     _pmpcfgs_11_rdata, _pmpcfgs_10_rdata, _pmpcfgs_9_rdata,  _pmpcfgs_8_rdata,
     _pmpcfgs_7_rdata,  _pmpcfgs_6_rdata,  _pmpcfgs_5_rdata,  _pmpcfgs_4_rdata,
     _pmpcfgs_3_rdata,  _pmpcfgs_2_rdata,  _pmpcfgs_1_rdata,  _pmpcfgs_0_rdata};
  // 步6：sireg 间接读出 OR-mux（按 siselect 选 siprio0/2/siprios_0..5；golden 2767-2775）。
  assign siregRData =
      (_siselect_rdata == 64'h30 ? _siprio0_rdata   : 64'h0)
    | (_siselect_rdata == 64'h32 ? _siprio2_rdata   : 64'h0)
    | (_siselect_rdata == 64'h34 ? _siprios_0_rdata : 64'h0)
    | (_siselect_rdata == 64'h36 ? _siprios_1_rdata : 64'h0)
    | (_siselect_rdata == 64'h38 ? _siprios_2_rdata : 64'h0)
    | (_siselect_rdata == 64'h3A ? _siprios_3_rdata : 64'h0)
    | (_siselect_rdata == 64'h3C ? _siprios_4_rdata : 64'h0)
    | (_siselect_rdata == 64'h3E ? _siprios_5_rdata : 64'h0);
  // 步4：trigger tdata1/tdata2 写使能（合法写 & 地址命中 & trigger 可写；golden 5231-5235）。
  //   triggerCanWrite：tdata1.DMODE 置位时仅 debug 态可写，否则恒可写。
  assign tdata1Update = wenLegalReg_last_REG & addrHit_tdata1 & triggerCanWrite;
  assign tdata2Update = wenLegalReg_last_REG & addrHit_tdata2 & triggerCanWrite;
  // 步3：trapEntry 各事件的目标特权态命中（来自 trapHandle 输出的 entryPrivState；golden 3179-3186）。
  assign trapEntryMEvent_valid_isModeM   = &_trapHandleMod_io_out_entryPrivState_PRVM;
  assign trapEntryHSEvent_valid_isModeHS = ~_trapHandleMod_io_out_entryPrivState_V  & PrvmIsS_1;
  assign trapEntryVSEvent_valid_isModeVS =  _trapHandleMod_io_out_entryPrivState_V  & PrvmIsS_1;
  // 步9：difftest 架构事件触发（待提交 trap 且向量异常模块不忙；golden 5368）。送 diffArchEvent_delayer。
  assign trapValid = pendingTrap & ~io_fromVecExcpMod_busy;
  assign unused = '0;
  // wenLegalReg_last_REG 在步2 FSM 块驱动（打拍写合法位）。


  // ======================================================================
  // 步4：rob-commit 打拍 + sstc 写使能打拍寄存器（golden 5569-5577 复位 / 5682-5695 更新，
  //   以及无复位的 *_bits_r golden 5864-5876）。送各 mstatus/fcsr/vcsr/vstart/vtype/vsstatus
  //   子模块的 robCommit 输入；sstcIRGen_i_*_wen 送 sstc 中断生成器。
  // ----------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      sstcIRGen_i_stimecmp_wen_last_REG  <= 1'h0;
      sstcIRGen_i_vstimecmp_wen_last_REG <= 1'h0;
      sstcIRGen_i_menvcfg_wen_last_REG   <= 1'h0;
      sstcIRGen_i_henvcfg_wen_last_REG   <= 1'h0;
      sstcIRGen_i_htimedeltaWen_last_REG <= 1'h0;
      mstatus_robCommit_fsDirty_last_REG          <= 1'h0;
      mstatus_robCommit_vsDirty_last_REG          <= 1'h0;
      vsstatus_robCommit_fsDirty_last_REG         <= 1'h0;
      vsstatus_robCommit_vsDirty_last_REG         <= 1'h0;
      fcsr_robCommit_fflags_next_valid_last_REG   <= 1'h0;
      vcsr_robCommit_vxsat_next_valid_last_REG    <= 1'h0;
      vstart_robCommit_vsDirty_last_REG           <= 1'h0;
      vstart_robCommit_vstart_next_valid_last_REG <= 1'h0;
      vtype_robCommit_vtype_next_valid_last_REG   <= 1'h0;
      pendingTrap <= 1'h0;
    end
    else begin
      sstcIRGen_i_stimecmp_wen_last_REG  <= stimecmp_wen;
      sstcIRGen_i_vstimecmp_wen_last_REG <= vstimecmp_wen;
      sstcIRGen_i_menvcfg_wen_last_REG   <= menvcfg_wen;
      sstcIRGen_i_henvcfg_wen_last_REG   <= henvcfg_wen;
      sstcIRGen_i_htimedeltaWen_last_REG <= htimedelta_wen;
      mstatus_robCommit_fsDirty_last_REG          <= io_fromRob_commit_fsDirty;
      mstatus_robCommit_vsDirty_last_REG          <= io_fromRob_commit_vsDirty;
      vsstatus_robCommit_fsDirty_last_REG         <= io_fromRob_commit_fsDirty;
      vsstatus_robCommit_vsDirty_last_REG         <= io_fromRob_commit_vsDirty;
      fcsr_robCommit_fflags_next_valid_last_REG   <= io_fromRob_commit_fflags_valid;
      vcsr_robCommit_vxsat_next_valid_last_REG    <= io_fromRob_commit_vxsat_valid;
      vstart_robCommit_vsDirty_last_REG           <= io_fromRob_commit_vsDirty;
      vstart_robCommit_vstart_next_valid_last_REG <= io_fromRob_commit_vstart_valid;
      vtype_robCommit_vtype_next_valid_last_REG   <= io_fromRob_commit_vtype_valid;
      pendingTrap <= io_fromRob_trap_valid | io_fromVecExcpMod_busy & pendingTrap;
    end
  end

  // 步4：rob-commit 数据打拍（无复位，valid 守卫；golden 5864-5876）。
  always @(posedge clock) begin
    if (io_fromRob_commit_fflags_valid)
      fcsr_robCommit_fflags_next_bits_r <= io_fromRob_commit_fflags_bits;
    if (io_fromRob_commit_vxsat_valid)
      vcsr_robCommit_vxsat_next_bits_r <= io_fromRob_commit_vxsat_bits;
    if (io_fromRob_commit_vstart_valid)
      vstart_robCommit_vstart_next_bits_r <= io_fromRob_commit_vstart_bits;
    if (io_fromRob_commit_vtype_valid) begin
      vtype_robCommit_vtype_next_bits_r_VILL  <= io_fromRob_commit_vtype_bits_VILL;
      vtype_robCommit_vtype_next_bits_r_VMA   <= io_fromRob_commit_vtype_bits_VMA;
      vtype_robCommit_vtype_next_bits_r_VTA   <= io_fromRob_commit_vtype_bits_VTA;
      vtype_robCommit_vtype_next_bits_r_VSEW  <= io_fromRob_commit_vtype_bits_VSEW;
      vtype_robCommit_vtype_next_bits_r_VLMUL <= io_fromRob_commit_vtype_bits_VLMUL;
    end
  end

  // ======================================================================
  // 步9：difftest 事件 change-detect 打拍寄存器更新（无复位，每拍跟随源信号；golden 5916-6000）。
  //   （reg 声明已上移到本节顶部以满足 `default_nettype none 的先声明后用。）
  always @(posedge clock) begin
    diffVecCSRState_vl_REG <= io_fromRob_commit_vl;
    platformIRPMeipChange_REG    <= platformIRP_MEIP;
    platformIRPMeipChange_REG_1  <= platformIRP_MEIP;
    platformIRPMtipChange_REG    <= platformIRP_MTIP;
    platformIRPMtipChange_REG_1  <= platformIRP_MTIP;
    platformIRPMsipChange_REG    <= platformIRP_MSIP;
    platformIRPMsipChange_REG_1  <= platformIRP_MSIP;
    platformIRPSeipChange_REG    <= platformIRP_SEIP;
    platformIRPSeipChange_REG_1  <= platformIRP_SEIP;
    platformIRPStipChange_REG    <= _sstcIRGen_o_STIP;
    platformIRPStipChange_REG_1  <= _sstcIRGen_o_STIP;
    platformIRPVseipChange_REG_2 <= hgeipForVseip_10[0];
    platformIRPVseipChange_REG_3 <= hgeipForVseip_18[0];
    platformIRPVstipChange_REG   <= _sstcIRGen_o_VSTIP;
    platformIRPVstipChange_REG_1 <= _sstcIRGen_o_VSTIP;
    fromAIAMeipChange_REG        <= fromAIA_meip;
    fromAIAMeipChange_REG_1      <= fromAIA_meip;
    fromAIASeipChange_REG        <= fromAIA_seip;
    fromAIASeipChange_REG_1      <= fromAIA_seip;
    lcofiReqChange_REG           <= |lcofiReqVec;
    lcofiReqChange_REG_1         <= |lcofiReqVec;
    diffNonRegInterruptPendingEvent_valid_REG <= reset;
    diffMhpmeventOverflowEvent_valid_REG    <= _mhpmcounters_0_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_1  <= _mhpmcounters_0_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_2  <= _mhpmcounters_1_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_3  <= _mhpmcounters_1_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_4  <= _mhpmcounters_2_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_5  <= _mhpmcounters_2_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_6  <= _mhpmcounters_3_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_7  <= _mhpmcounters_3_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_8  <= _mhpmcounters_4_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_9  <= _mhpmcounters_4_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_10 <= _mhpmcounters_5_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_11 <= _mhpmcounters_5_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_12 <= _mhpmcounters_6_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_13 <= _mhpmcounters_6_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_14 <= _mhpmcounters_7_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_15 <= _mhpmcounters_7_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_16 <= _mhpmcounters_8_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_17 <= _mhpmcounters_8_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_18 <= _mhpmcounters_9_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_19 <= _mhpmcounters_9_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_20 <= _mhpmcounters_10_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_21 <= _mhpmcounters_10_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_22 <= _mhpmcounters_11_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_23 <= _mhpmcounters_11_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_24 <= _mhpmcounters_12_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_25 <= _mhpmcounters_12_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_26 <= _mhpmcounters_13_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_27 <= _mhpmcounters_13_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_28 <= _mhpmcounters_14_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_29 <= _mhpmcounters_14_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_30 <= _mhpmcounters_15_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_31 <= _mhpmcounters_15_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_32 <= _mhpmcounters_16_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_33 <= _mhpmcounters_16_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_34 <= _mhpmcounters_17_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_35 <= _mhpmcounters_17_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_36 <= _mhpmcounters_18_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_37 <= _mhpmcounters_18_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_38 <= _mhpmcounters_19_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_39 <= _mhpmcounters_19_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_40 <= _mhpmcounters_20_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_41 <= _mhpmcounters_20_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_42 <= _mhpmcounters_21_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_43 <= _mhpmcounters_21_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_44 <= _mhpmcounters_22_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_45 <= _mhpmcounters_22_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_46 <= _mhpmcounters_23_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_47 <= _mhpmcounters_23_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_48 <= _mhpmcounters_24_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_49 <= _mhpmcounters_24_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_50 <= _mhpmcounters_25_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_51 <= _mhpmcounters_25_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_52 <= _mhpmcounters_26_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_53 <= _mhpmcounters_26_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_54 <= _mhpmcounters_27_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_55 <= _mhpmcounters_27_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_56 <= _mhpmcounters_28_toMhpmeventOF;
    diffMhpmeventOverflowEvent_valid_REG_57 <= _mhpmcounters_28_toMhpmeventOF;
    mtopeiChange_REG  <= {37'h0, fromAIA_mtopei_IID, 5'h0, fromAIA_mtopei_IPRIO};
    stopeiChange_REG  <= {37'h0, fromAIA_stopei_IID, 5'h0, fromAIA_stopei_IPRIO};
    vstopeiChange_REG <= _hstatus_regOut_VGEIN;
    hgeipChange_REG   <= fromAIA_vseip;
    diffCustomMflushpwr_valid_REG <= io_fromTop_l2FlushDone;
  end

  // ======================================================================
  // 步3：trap 派发 + targetPc 输出。
  //   NewCSR.scala：9 个事件源（mnret/mret/sret/dret + trapEntryM/MN/HS/VS/D）
  //   各产生一个 out.targetPc（valid + pc + raiseIPF/IAF/IGPF），互斥。
  //   needTargetUpdate = 任一事件 valid 的 OR；targetPc 用 trapEntryD 优先、
  //   其余 OR-tree 选择（golden 5161-5224 + 4791-4796）。每个事件输出为子模块
  //   黑盒输出（_<evt>Event_out_targetPc_*，在 decls.svh 声明、inst.svh 驱动）。
  // ----------------------------------------------------------------------
  wire needTargetUpdate =
    _mnretEvent_out_targetPc_valid     | _mretEvent_out_targetPc_valid
    | _sretEvent_out_targetPc_valid    | _dretEvent_out_targetPc_valid
    | _trapEntryMEvent_out_targetPc_valid  | _trapEntryMNEvent_out_targetPc_valid
    | _trapEntryHSEvent_out_targetPc_valid | _trapEntryVSEvent_out_targetPc_valid
    | _trapEntryDEvent_out_targetPc_valid;

  // trapEntryD 优先；其余事件 valid 互斥，按 valid 守卫 OR 汇聚。
  wire [63:0] targetPcSel_pc =
    _trapEntryDEvent_out_targetPc_valid
      ? _trapEntryDEvent_out_targetPc_bits_pc
      : (_mnretEvent_out_targetPc_valid ? _mnretEvent_out_targetPc_bits_pc : 64'h0)
        | (_mretEvent_out_targetPc_valid ? _mretEvent_out_targetPc_bits_pc : 64'h0)
        | (_sretEvent_out_targetPc_valid ? _sretEvent_out_targetPc_bits_pc : 64'h0)
        | (_dretEvent_out_targetPc_valid ? _dretEvent_out_targetPc_bits_pc : 64'h0)
        | (_trapEntryMEvent_out_targetPc_valid  ? _trapEntryMEvent_out_targetPc_bits_pc  : 64'h0)
        | (_trapEntryMNEvent_out_targetPc_valid ? _trapEntryMNEvent_out_targetPc_bits_pc : 64'h0)
        | (_trapEntryHSEvent_out_targetPc_valid ? _trapEntryHSEvent_out_targetPc_bits_pc : 64'h0)
        | (_trapEntryVSEvent_out_targetPc_valid ? _trapEntryVSEvent_out_targetPc_bits_pc : 64'h0);
  wire targetPcSel_raiseIPF =
    _trapEntryDEvent_out_targetPc_valid
      ? _trapEntryDEvent_out_targetPc_bits_raiseIPF
      : _mnretEvent_out_targetPc_valid     & _mnretEvent_out_targetPc_bits_raiseIPF
        | _mretEvent_out_targetPc_valid    & _mretEvent_out_targetPc_bits_raiseIPF
        | _sretEvent_out_targetPc_valid    & _sretEvent_out_targetPc_bits_raiseIPF
        | _dretEvent_out_targetPc_valid    & _dretEvent_out_targetPc_bits_raiseIPF
        | _trapEntryMEvent_out_targetPc_valid  & _trapEntryMEvent_out_targetPc_bits_raiseIPF
        | _trapEntryMNEvent_out_targetPc_valid & _trapEntryMNEvent_out_targetPc_bits_raiseIPF
        | _trapEntryHSEvent_out_targetPc_valid & _trapEntryHSEvent_out_targetPc_bits_raiseIPF
        | _trapEntryVSEvent_out_targetPc_valid & _trapEntryVSEvent_out_targetPc_bits_raiseIPF;
  wire targetPcSel_raiseIAF =
    _trapEntryDEvent_out_targetPc_valid
      ? _trapEntryDEvent_out_targetPc_bits_raiseIAF
      : _mnretEvent_out_targetPc_valid     & _mnretEvent_out_targetPc_bits_raiseIAF
        | _mretEvent_out_targetPc_valid    & _mretEvent_out_targetPc_bits_raiseIAF
        | _sretEvent_out_targetPc_valid    & _sretEvent_out_targetPc_bits_raiseIAF
        | _dretEvent_out_targetPc_valid    & _dretEvent_out_targetPc_bits_raiseIAF
        | _trapEntryMEvent_out_targetPc_valid  & _trapEntryMEvent_out_targetPc_bits_raiseIAF
        | _trapEntryMNEvent_out_targetPc_valid & _trapEntryMNEvent_out_targetPc_bits_raiseIAF
        | _trapEntryHSEvent_out_targetPc_valid & _trapEntryHSEvent_out_targetPc_bits_raiseIAF
        | _trapEntryVSEvent_out_targetPc_valid & _trapEntryVSEvent_out_targetPc_bits_raiseIAF;
  wire targetPcSel_raiseIGPF =
    _trapEntryDEvent_out_targetPc_valid
      ? _trapEntryDEvent_out_targetPc_bits_raiseIGPF
      : _mnretEvent_out_targetPc_valid     & _mnretEvent_out_targetPc_bits_raiseIGPF
        | _mretEvent_out_targetPc_valid    & _mretEvent_out_targetPc_bits_raiseIGPF
        | _sretEvent_out_targetPc_valid    & _sretEvent_out_targetPc_bits_raiseIGPF
        | _dretEvent_out_targetPc_valid    & _dretEvent_out_targetPc_bits_raiseIGPF
        | _trapEntryMEvent_out_targetPc_valid  & _trapEntryMEvent_out_targetPc_bits_raiseIGPF
        | _trapEntryMNEvent_out_targetPc_valid & _trapEntryMNEvent_out_targetPc_bits_raiseIGPF
        | _trapEntryHSEvent_out_targetPc_valid & _trapEntryHSEvent_out_targetPc_bits_raiseIGPF
        | _trapEntryVSEvent_out_targetPc_valid & _trapEntryVSEvent_out_targetPc_bits_raiseIGPF;

  // targetPc 保留寄存器：needTargetUpdate 时透传当拍选择值，否则保持（无复位，
  // golden 5879-5884 在无复位 always 内、needTargetUpdate 守卫更新）。
  reg  [63:0] targetPc_r_pc;
  reg         targetPc_r_raiseIPF;
  reg         targetPc_r_raiseIAF;
  reg         targetPc_r_raiseIGPF;

  // io_error_0 两级打拍寄存器（无复位，golden 5365-5366）。
  reg         io_error_0_REG;
  reg         io_error_0_REG_1;

  // 无复位寄存器更新（独立 always@(posedge clock)，与 golden 5879-5896 同结构；
  // 放进复位块会令 FM DFF 失配，故单列）。
  always @(posedge clock) begin
    // targetPc 保留寄存器（needTargetUpdate 守卫，golden 5879-5884）。
    if (needTargetUpdate) begin
      targetPc_r_pc        <= targetPcSel_pc;
      targetPc_r_raiseIPF  <= targetPcSel_raiseIPF;
      targetPc_r_raiseIAF  <= targetPcSel_raiseIAF;
      targetPc_r_raiseIGPF <= targetPcSel_raiseIGPF;
    end
    // io_error_0 两级打拍（golden 5895-5896）。
    io_error_0_REG   <= criticalErrorStateInCSR;
    io_error_0_REG_1 <= io_error_0_REG;
  end

  assign io_out_bits_targetPcUpdate    = needTargetUpdate;
  assign io_out_bits_targetPc_pc       = needTargetUpdate ? targetPcSel_pc       : targetPc_r_pc;
  assign io_out_bits_targetPc_raiseIPF = needTargetUpdate ? targetPcSel_raiseIPF : targetPc_r_raiseIPF;
  assign io_out_bits_targetPc_raiseIAF = needTargetUpdate ? targetPcSel_raiseIAF : targetPc_r_raiseIAF;
  assign io_out_bits_targetPc_raiseIGPF= needTargetUpdate ? targetPcSel_raiseIGPF: targetPc_r_raiseIGPF;

  // ----- flushPipe（步3）：satp/vsatp/hgatp 写 + trigger 前端变更 + fs/vs/vstart/frm/fcsr
  //   写副作用的合法-写触发（golden 13921-13948）。-----
  assign io_out_bits_flushPipe =
    (|{io_in_bits_addr == 12'h180,
       io_in_bits_addr == 12'h280,
       io_in_bits_addr == 12'h680}) & wenLegalReg_last_REG
    | _debugMod_io_out_triggerFrontendChange | mstatus_wen
    & (io_in_bits_wdata[14:13] == 2'h0 & (|_mstatus_regOut_FS)
       | (|(io_in_bits_wdata[14:13])) & mstatusFsIsOff)
    | mstatus_wAliasSstatus_wen
    & (io_in_bits_wdata[14:13] == 2'h0 & (|_mstatus_regOut_FS)
       | (|(io_in_bits_wdata[14:13])) & mstatusFsIsOff)
    | vsstatus_wen
    & (io_in_bits_wdata[14:13] == 2'h0 & (|_vsstatus_regOut_FS)
       | (|(io_in_bits_wdata[14:13])) & vsFsIsOff)
    | mstatus_wen
    & (io_in_bits_wdata[10:9] == 2'h0 & (|_mstatus_regOut_VS)
       | (|(io_in_bits_wdata[10:9])) & mstatusVsIsOff)
    | mstatus_wAliasSstatus_wen
    & (io_in_bits_wdata[10:9] == 2'h0 & (|_mstatus_regOut_VS)
       | (|(io_in_bits_wdata[10:9])) & mstatusVsIsOff)
    | vsstatus_wen
    & (io_in_bits_wdata[10:9] == 2'h0 & (|_vsstatus_regOut_VS)
       | (|(io_in_bits_wdata[10:9])) & vsVsIsOff)
    | vstart_wen
    & (io_in_bits_wdata == 64'h0 & (|_vstart_regOut_vstart) | (|io_in_bits_wdata)
       & _vstart_regOut_vstart == 7'h0) | fcsr_wAliasFfm_wen
    & (~frmIsReserved & frmWdataReserved | frmIsReserved & ~frmWdataReserved)
    | fcsr_wen
    & (~frmIsReserved & fcsrWdataReserved | frmIsReserved & ~fcsrWdataReserved);
  // io_out_bits_regOut 在步1 regOut OR-mux 块驱动。

  // ======================================================================
  // 步1：CSR 写回值读出 OR-mux（regOut 路径）。
  //   设计意图：NewCSR.scala regOut 选择——每个 CSR 命中位选其 regOut 位域打包，
  //   OR 汇聚（含 dcsr/pmp/spfctl 等的 per-field 拼装 + fflags/frm/vxsat 位域 merge）。
  //   叶子 _<csr>_regOut_* 为子模块输出（decls 声明）；UT 中多为 X，FM 验等价。
  //   分层 regOut_m/mhpm/hyper/vs/fp/pre + 尾部 IMSIC/pmp 打包。
  // ======================================================================
  wire [63:0]  regOut_m =
    (addrHit_mstatus
       ? {21'h0,
          _mstatus_regOut_MDT,
          2'h0,
          _mstatus_regOut_MPV,
          _mstatus_regOut_GVA,
          13'h500,
          _mstatus_regOut_SDT,
          1'h0,
          _mstatus_regOut_TSR,
          _mstatus_regOut_TW,
          _mstatus_regOut_TVM,
          _mstatus_regOut_MXR,
          _mstatus_regOut_SUM,
          _mstatus_regOut_MPRV,
          2'h0,
          _mstatus_regOut_FS,
          _mstatus_regOut_MPP,
          _mstatus_regOut_VS,
          _mstatus_regOut_SPP,
          _mstatus_regOut_MPIE,
          1'h0,
          _mstatus_regOut_SPIE,
          1'h0,
          _mstatus_regOut_MIE,
          1'h0,
          _mstatus_regOut_SIE,
          1'h0}
       : 64'h0) | (addrHit_misa ? 64'h80000000003411AF : 64'h0)
    | (addrHit_medeleg
         ? {40'h0,
            _medeleg_regOut_EX_SGPF,
            _medeleg_regOut_EX_VI,
            _medeleg_regOut_EX_LGPF,
            _medeleg_regOut_EX_IGPF,
            _medeleg_regOut_EX_HWE,
            _medeleg_regOut_EX_SWC,
            2'h0,
            _medeleg_regOut_EX_SPF,
            1'h0,
            _medeleg_regOut_EX_LPF,
            _medeleg_regOut_EX_IPF,
            1'h0,
            _medeleg_regOut_EX_VSCALL,
            _medeleg_regOut_EX_HSCALL,
            _medeleg_regOut_EX_UCALL,
            _medeleg_regOut_EX_SAF,
            _medeleg_regOut_EX_SAM,
            _medeleg_regOut_EX_LAF,
            _medeleg_regOut_EX_LAM,
            _medeleg_regOut_EX_BP,
            _medeleg_regOut_EX_II,
            _medeleg_regOut_EX_IAF,
            _medeleg_regOut_EX_IAM}
         : 64'h0)
    | (addrHit_mideleg
         ? {50'h0,
            _mideleg_regOut_LCOFI,
            3'h5,
            _mideleg_regOut_SEI,
            3'h1,
            _mideleg_regOut_STI,
            3'h1,
            _mideleg_regOut_SSI,
            1'h0}
         : 64'h0)
    | (addrHit_mie
         ? {50'h0,
            _mie_regOut_LCOFIE,
            _mie_regOut_SGEIE,
            _mie_regOut_MEIE,
            _mie_regOut_VSEIE,
            _mie_regOut_SEIE,
            1'h0,
            _mie_regOut_MTIE,
            _mie_regOut_VSTIE,
            _mie_regOut_STIE,
            1'h0,
            _mie_regOut_MSIE,
            _mie_regOut_VSSIE,
            _mie_regOut_SSIE,
            1'h0}
         : 64'h0)
    | (addrHit_mtvec ? {_mtvec_regOut_addr, _mtvec_regOut_mode} : 64'h0)
    | (addrHit_mcounteren
         ? {32'h0,
            _mcounteren_regOut_HPM,
            _mcounteren_regOut_IR,
            _mcounteren_regOut_TM,
            _mcounteren_regOut_CY}
         : 64'h0)
    | (addrHit_mvien
         ? {_mvien_regOut_LC63IE,
            _mvien_regOut_LC62IE,
            _mvien_regOut_LC61IE,
            _mvien_regOut_LC60IE,
            _mvien_regOut_LC59IE,
            _mvien_regOut_LC58IE,
            _mvien_regOut_LC57IE,
            _mvien_regOut_LC56IE,
            _mvien_regOut_LC55IE,
            _mvien_regOut_LC54IE,
            _mvien_regOut_LC53IE,
            _mvien_regOut_LC52IE,
            _mvien_regOut_LC51IE,
            _mvien_regOut_LC50IE,
            _mvien_regOut_LC49IE,
            _mvien_regOut_LC48IE,
            _mvien_regOut_LC47IE,
            _mvien_regOut_LC46IE,
            _mvien_regOut_LC45IE,
            _mvien_regOut_LC44IE,
            _mvien_regOut_HPRASEIE,
            _mvien_regOut_LC42IE,
            _mvien_regOut_LC41IE,
            _mvien_regOut_LC40IE,
            _mvien_regOut_LC39IE,
            _mvien_regOut_LC38IE,
            _mvien_regOut_LC37IE,
            _mvien_regOut_LC36IE,
            _mvien_regOut_LPRASEIE,
            _mvien_regOut_LC34IE,
            _mvien_regOut_LC33IE,
            _mvien_regOut_LC32IE,
            _mvien_regOut_LC31IE,
            _mvien_regOut_LC30IE,
            _mvien_regOut_LC29IE,
            _mvien_regOut_LC28IE,
            _mvien_regOut_LC27IE,
            _mvien_regOut_LC26IE,
            _mvien_regOut_LC25IE,
            _mvien_regOut_LC24IE,
            _mvien_regOut_LC23IE,
            _mvien_regOut_LC22IE,
            _mvien_regOut_LC21IE,
            _mvien_regOut_LC20IE,
            _mvien_regOut_LC19IE,
            _mvien_regOut_LC18IE,
            _mvien_regOut_LC17IE,
            _mvien_regOut_LC16IE,
            _mvien_regOut_LC15IE,
            _mvien_regOut_LC14IE,
            4'h0,
            _mvien_regOut_SEIE,
            7'h0,
            _mvien_regOut_SSIE,
            1'h0}
         : 64'h0)
    | (addrHit_mvip
         ? {_mvip_regOut_LC63IP,
            _mvip_regOut_LC62IP,
            _mvip_regOut_LC61IP,
            _mvip_regOut_LC60IP,
            _mvip_regOut_LC59IP,
            _mvip_regOut_LC58IP,
            _mvip_regOut_LC57IP,
            _mvip_regOut_LC56IP,
            _mvip_regOut_LC55IP,
            _mvip_regOut_LC54IP,
            _mvip_regOut_LC53IP,
            _mvip_regOut_LC52IP,
            _mvip_regOut_LC51IP,
            _mvip_regOut_LC50IP,
            _mvip_regOut_LC49IP,
            _mvip_regOut_LC48IP,
            _mvip_regOut_LC47IP,
            _mvip_regOut_LC46IP,
            _mvip_regOut_LC45IP,
            _mvip_regOut_LC44IP,
            _mvip_regOut_HPRASEIP,
            _mvip_regOut_LC42IP,
            _mvip_regOut_LC41IP,
            _mvip_regOut_LC40IP,
            _mvip_regOut_LC39IP,
            _mvip_regOut_LC38IP,
            _mvip_regOut_LC37IP,
            _mvip_regOut_LC36IP,
            _mvip_regOut_LPRASEIP,
            _mvip_regOut_LC34IP,
            _mvip_regOut_LC33IP,
            _mvip_regOut_LC32IP,
            _mvip_regOut_LC31IP,
            _mvip_regOut_LC30IP,
            _mvip_regOut_LC29IP,
            _mvip_regOut_LC28IP,
            _mvip_regOut_LC27IP,
            _mvip_regOut_LC26IP,
            _mvip_regOut_LC25IP,
            _mvip_regOut_LC24IP,
            _mvip_regOut_LC23IP,
            _mvip_regOut_LC22IP,
            _mvip_regOut_LC21IP,
            _mvip_regOut_LC20IP,
            _mvip_regOut_LC19IP,
            _mvip_regOut_LC18IP,
            _mvip_regOut_LC17IP,
            _mvip_regOut_LC16IP,
            _mvip_regOut_LC15IP,
            _mvip_regOut_LC14IP,
            _mvip_regOut_LCOFIP,
            3'h0,
            _mvip_regOut_SEIP,
            3'h0,
            _mvip_regOut_STIP,
            3'h0,
            _mvip_regOut_SSIP,
            1'h0}
         : 64'h0)
    | (addrHit_menvcfg
         ? {_menvcfg_regOut_STCE,
            _menvcfg_regOut_PBMTE,
            2'h0,
            _menvcfg_regOut_DTE,
            25'h0,
            _menvcfg_regOut_PMM,
            24'h0,
            _menvcfg_regOut_CBZE,
            _menvcfg_regOut_CBCFE,
            _menvcfg_regOut_CBIE,
            4'h0}
         : 64'h0)
    | (addrHit_mcountinhibit
         ? {32'h0,
            _mcountinhibit_regOut_HPM3,
            _mcountinhibit_regOut_IR,
            1'h0,
            _mcountinhibit_regOut_CY}
         : 64'h0) | (addrHit_mscratch ? _mscratch_regOut_ALL : 64'h0)
    | (addrHit_mepc ? {_mepc_regOut_epc, 1'h0} : 64'h0)
    | (addrHit_mcause
         ? {_mcause_regOut_Interrupt, _mcause_regOut_ExceptionCode}
         : 64'h0) | (addrHit_mtval ? _mtval_regOut_ALL : 64'h0)
    | (addrHit_mip
         ? {50'h0,
            _mip_regOut_LCOFIP,
            _mip_regOut_SGEIP,
            _mip_regOut_MEIP,
            _mip_regOut_VSEIP,
            _mip_regOut_SEIP,
            1'h0,
            _mip_regOut_MTIP,
            _mip_regOut_VSTIP,
            _mip_regOut_STIP,
            1'h0,
            _mip_regOut_MSIP,
            _mip_regOut_VSSIP,
            _mip_regOut_SSIP,
            1'h0}
         : 64'h0) | (addrHit_mtinst ? _mtinst_regOut_ALL : 64'h0)
    | (addrHit_mtval2 ? _mtval2_regOut_ALL : 64'h0)
    | (addrHit_mseccfg ? {30'h0, _mseccfg_regOut_PMM, 32'h0} : 64'h0)
    | (addrHit_mcycle ? _mcycle_regOut_ALL : 64'h0)
    | (addrHit_minstret ? _minstret_regOut_ALL : 64'h0)
    | (addrHit_mstateen0
         ? {_mstateen0_regOut_SE0,
            _mstateen0_regOut_ENVCFG,
            1'h0,
            _mstateen0_regOut_CSRIND,
            _mstateen0_regOut_AIA,
            _mstateen0_regOut_IMSIC,
            _mstateen0_regOut_CONTEXT,
            56'h0,
            _mstateen0_regOut_C}
         : 64'h0) | (addrHit_mstateen1 ? {_mstateen1_regOut_SE, 63'h0} : 64'h0)
    | (addrHit_mstateen2 ? {_mstateen2_regOut_SE, 63'h0} : 64'h0)
    | (addrHit_mstateen3 ? {_mstateen3_regOut_SE, 63'h0} : 64'h0)
    | (addrHit_mnepc ? {_mnepc_regOut_epc, 1'h0} : 64'h0)
    | (addrHit_mncause
         ? {_mncause_regOut_Interrupt, _mncause_regOut_ExceptionCode}
         : 64'h0)
    | (addrHit_mnstatus
         ? {51'h0,
            _mnstatus_regOut_MNPP,
            3'h0,
            _mnstatus_regOut_MNPV,
            3'h0,
            _mnstatus_regOut_NMIE,
            3'h0}
         : 64'h0) | (addrHit_mnscratch ? _mnscratch_regOut_ALL : 64'h0);
  wire [63:0]  regOut_mrg17 =
    {regOut_m[63:14],
     regOut_m[13:0] | (addrHit_mcontext ? _mcontext_regOut_HCONTEXT : 14'h0)}
    | (addrHit_mhpmevent3
         ? {_Mhpmevent3_regOut_OF,
            _Mhpmevent3_regOut_MINH,
            _Mhpmevent3_regOut_SINH,
            _Mhpmevent3_regOut_UINH,
            _Mhpmevent3_regOut_VSINH,
            _Mhpmevent3_regOut_VUINH,
            3'h0,
            _Mhpmevent3_regOut_OPTYPE2,
            _Mhpmevent3_regOut_OPTYPE1,
            _Mhpmevent3_regOut_OPTYPE0,
            _Mhpmevent3_regOut_EVENT3,
            _Mhpmevent3_regOut_EVENT2,
            _Mhpmevent3_regOut_EVENT1,
            _Mhpmevent3_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent4
         ? {_Mhpmevent4_regOut_OF,
            _Mhpmevent4_regOut_MINH,
            _Mhpmevent4_regOut_SINH,
            _Mhpmevent4_regOut_UINH,
            _Mhpmevent4_regOut_VSINH,
            _Mhpmevent4_regOut_VUINH,
            3'h0,
            _Mhpmevent4_regOut_OPTYPE2,
            _Mhpmevent4_regOut_OPTYPE1,
            _Mhpmevent4_regOut_OPTYPE0,
            _Mhpmevent4_regOut_EVENT3,
            _Mhpmevent4_regOut_EVENT2,
            _Mhpmevent4_regOut_EVENT1,
            _Mhpmevent4_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent5
         ? {_Mhpmevent5_regOut_OF,
            _Mhpmevent5_regOut_MINH,
            _Mhpmevent5_regOut_SINH,
            _Mhpmevent5_regOut_UINH,
            _Mhpmevent5_regOut_VSINH,
            _Mhpmevent5_regOut_VUINH,
            3'h0,
            _Mhpmevent5_regOut_OPTYPE2,
            _Mhpmevent5_regOut_OPTYPE1,
            _Mhpmevent5_regOut_OPTYPE0,
            _Mhpmevent5_regOut_EVENT3,
            _Mhpmevent5_regOut_EVENT2,
            _Mhpmevent5_regOut_EVENT1,
            _Mhpmevent5_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent6
         ? {_Mhpmevent6_regOut_OF,
            _Mhpmevent6_regOut_MINH,
            _Mhpmevent6_regOut_SINH,
            _Mhpmevent6_regOut_UINH,
            _Mhpmevent6_regOut_VSINH,
            _Mhpmevent6_regOut_VUINH,
            3'h0,
            _Mhpmevent6_regOut_OPTYPE2,
            _Mhpmevent6_regOut_OPTYPE1,
            _Mhpmevent6_regOut_OPTYPE0,
            _Mhpmevent6_regOut_EVENT3,
            _Mhpmevent6_regOut_EVENT2,
            _Mhpmevent6_regOut_EVENT1,
            _Mhpmevent6_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent7
         ? {_Mhpmevent7_regOut_OF,
            _Mhpmevent7_regOut_MINH,
            _Mhpmevent7_regOut_SINH,
            _Mhpmevent7_regOut_UINH,
            _Mhpmevent7_regOut_VSINH,
            _Mhpmevent7_regOut_VUINH,
            3'h0,
            _Mhpmevent7_regOut_OPTYPE2,
            _Mhpmevent7_regOut_OPTYPE1,
            _Mhpmevent7_regOut_OPTYPE0,
            _Mhpmevent7_regOut_EVENT3,
            _Mhpmevent7_regOut_EVENT2,
            _Mhpmevent7_regOut_EVENT1,
            _Mhpmevent7_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent8
         ? {_Mhpmevent8_regOut_OF,
            _Mhpmevent8_regOut_MINH,
            _Mhpmevent8_regOut_SINH,
            _Mhpmevent8_regOut_UINH,
            _Mhpmevent8_regOut_VSINH,
            _Mhpmevent8_regOut_VUINH,
            3'h0,
            _Mhpmevent8_regOut_OPTYPE2,
            _Mhpmevent8_regOut_OPTYPE1,
            _Mhpmevent8_regOut_OPTYPE0,
            _Mhpmevent8_regOut_EVENT3,
            _Mhpmevent8_regOut_EVENT2,
            _Mhpmevent8_regOut_EVENT1,
            _Mhpmevent8_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent9
         ? {_Mhpmevent9_regOut_OF,
            _Mhpmevent9_regOut_MINH,
            _Mhpmevent9_regOut_SINH,
            _Mhpmevent9_regOut_UINH,
            _Mhpmevent9_regOut_VSINH,
            _Mhpmevent9_regOut_VUINH,
            3'h0,
            _Mhpmevent9_regOut_OPTYPE2,
            _Mhpmevent9_regOut_OPTYPE1,
            _Mhpmevent9_regOut_OPTYPE0,
            _Mhpmevent9_regOut_EVENT3,
            _Mhpmevent9_regOut_EVENT2,
            _Mhpmevent9_regOut_EVENT1,
            _Mhpmevent9_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent10
         ? {_Mhpmevent10_regOut_OF,
            _Mhpmevent10_regOut_MINH,
            _Mhpmevent10_regOut_SINH,
            _Mhpmevent10_regOut_UINH,
            _Mhpmevent10_regOut_VSINH,
            _Mhpmevent10_regOut_VUINH,
            3'h0,
            _Mhpmevent10_regOut_OPTYPE2,
            _Mhpmevent10_regOut_OPTYPE1,
            _Mhpmevent10_regOut_OPTYPE0,
            _Mhpmevent10_regOut_EVENT3,
            _Mhpmevent10_regOut_EVENT2,
            _Mhpmevent10_regOut_EVENT1,
            _Mhpmevent10_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent11
         ? {_Mhpmevent11_regOut_OF,
            _Mhpmevent11_regOut_MINH,
            _Mhpmevent11_regOut_SINH,
            _Mhpmevent11_regOut_UINH,
            _Mhpmevent11_regOut_VSINH,
            _Mhpmevent11_regOut_VUINH,
            3'h0,
            _Mhpmevent11_regOut_OPTYPE2,
            _Mhpmevent11_regOut_OPTYPE1,
            _Mhpmevent11_regOut_OPTYPE0,
            _Mhpmevent11_regOut_EVENT3,
            _Mhpmevent11_regOut_EVENT2,
            _Mhpmevent11_regOut_EVENT1,
            _Mhpmevent11_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent12
         ? {_Mhpmevent12_regOut_OF,
            _Mhpmevent12_regOut_MINH,
            _Mhpmevent12_regOut_SINH,
            _Mhpmevent12_regOut_UINH,
            _Mhpmevent12_regOut_VSINH,
            _Mhpmevent12_regOut_VUINH,
            3'h0,
            _Mhpmevent12_regOut_OPTYPE2,
            _Mhpmevent12_regOut_OPTYPE1,
            _Mhpmevent12_regOut_OPTYPE0,
            _Mhpmevent12_regOut_EVENT3,
            _Mhpmevent12_regOut_EVENT2,
            _Mhpmevent12_regOut_EVENT1,
            _Mhpmevent12_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent13
         ? {_Mhpmevent13_regOut_OF,
            _Mhpmevent13_regOut_MINH,
            _Mhpmevent13_regOut_SINH,
            _Mhpmevent13_regOut_UINH,
            _Mhpmevent13_regOut_VSINH,
            _Mhpmevent13_regOut_VUINH,
            3'h0,
            _Mhpmevent13_regOut_OPTYPE2,
            _Mhpmevent13_regOut_OPTYPE1,
            _Mhpmevent13_regOut_OPTYPE0,
            _Mhpmevent13_regOut_EVENT3,
            _Mhpmevent13_regOut_EVENT2,
            _Mhpmevent13_regOut_EVENT1,
            _Mhpmevent13_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent14
         ? {_Mhpmevent14_regOut_OF,
            _Mhpmevent14_regOut_MINH,
            _Mhpmevent14_regOut_SINH,
            _Mhpmevent14_regOut_UINH,
            _Mhpmevent14_regOut_VSINH,
            _Mhpmevent14_regOut_VUINH,
            3'h0,
            _Mhpmevent14_regOut_OPTYPE2,
            _Mhpmevent14_regOut_OPTYPE1,
            _Mhpmevent14_regOut_OPTYPE0,
            _Mhpmevent14_regOut_EVENT3,
            _Mhpmevent14_regOut_EVENT2,
            _Mhpmevent14_regOut_EVENT1,
            _Mhpmevent14_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent15
         ? {_Mhpmevent15_regOut_OF,
            _Mhpmevent15_regOut_MINH,
            _Mhpmevent15_regOut_SINH,
            _Mhpmevent15_regOut_UINH,
            _Mhpmevent15_regOut_VSINH,
            _Mhpmevent15_regOut_VUINH,
            3'h0,
            _Mhpmevent15_regOut_OPTYPE2,
            _Mhpmevent15_regOut_OPTYPE1,
            _Mhpmevent15_regOut_OPTYPE0,
            _Mhpmevent15_regOut_EVENT3,
            _Mhpmevent15_regOut_EVENT2,
            _Mhpmevent15_regOut_EVENT1,
            _Mhpmevent15_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent16
         ? {_Mhpmevent16_regOut_OF,
            _Mhpmevent16_regOut_MINH,
            _Mhpmevent16_regOut_SINH,
            _Mhpmevent16_regOut_UINH,
            _Mhpmevent16_regOut_VSINH,
            _Mhpmevent16_regOut_VUINH,
            3'h0,
            _Mhpmevent16_regOut_OPTYPE2,
            _Mhpmevent16_regOut_OPTYPE1,
            _Mhpmevent16_regOut_OPTYPE0,
            _Mhpmevent16_regOut_EVENT3,
            _Mhpmevent16_regOut_EVENT2,
            _Mhpmevent16_regOut_EVENT1,
            _Mhpmevent16_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent17
         ? {_Mhpmevent17_regOut_OF,
            _Mhpmevent17_regOut_MINH,
            _Mhpmevent17_regOut_SINH,
            _Mhpmevent17_regOut_UINH,
            _Mhpmevent17_regOut_VSINH,
            _Mhpmevent17_regOut_VUINH,
            3'h0,
            _Mhpmevent17_regOut_OPTYPE2,
            _Mhpmevent17_regOut_OPTYPE1,
            _Mhpmevent17_regOut_OPTYPE0,
            _Mhpmevent17_regOut_EVENT3,
            _Mhpmevent17_regOut_EVENT2,
            _Mhpmevent17_regOut_EVENT1,
            _Mhpmevent17_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent18
         ? {_Mhpmevent18_regOut_OF,
            _Mhpmevent18_regOut_MINH,
            _Mhpmevent18_regOut_SINH,
            _Mhpmevent18_regOut_UINH,
            _Mhpmevent18_regOut_VSINH,
            _Mhpmevent18_regOut_VUINH,
            3'h0,
            _Mhpmevent18_regOut_OPTYPE2,
            _Mhpmevent18_regOut_OPTYPE1,
            _Mhpmevent18_regOut_OPTYPE0,
            _Mhpmevent18_regOut_EVENT3,
            _Mhpmevent18_regOut_EVENT2,
            _Mhpmevent18_regOut_EVENT1,
            _Mhpmevent18_regOut_EVENT0}
         : 64'h0);
  wire [63:0]  regOut_mrg18 =
    (addrHit_mhpmcounters_5 ? _mhpmcounters_5_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_6 ? _mhpmcounters_6_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_7 ? _mhpmcounters_7_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_8 ? _mhpmcounters_8_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_9 ? _mhpmcounters_9_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_10 ? _mhpmcounters_10_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_11 ? _mhpmcounters_11_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_12 ? _mhpmcounters_12_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_13 ? _mhpmcounters_13_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_14 ? _mhpmcounters_14_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_15 ? _mhpmcounters_15_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_16 ? _mhpmcounters_16_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_17 ? _mhpmcounters_17_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_18 ? _mhpmcounters_18_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_19 ? _mhpmcounters_19_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_20 ? _mhpmcounters_20_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_21 ? _mhpmcounters_21_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_22 ? _mhpmcounters_22_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_23 ? _mhpmcounters_23_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_24 ? _mhpmcounters_24_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_25 ? _mhpmcounters_25_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_26 ? _mhpmcounters_26_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_27 ? _mhpmcounters_27_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_28 ? _mhpmcounters_28_regOut_ALL : 64'h0)
    | (~isModeVS & addrHit_sstatus
         ? {_mstatus_sstatus_SD,
            38'h100,
            _mstatus_sstatus_SDT,
            4'h0,
            _mstatus_sstatus_MXR,
            _mstatus_sstatus_SUM,
            3'h0,
            _mstatus_sstatus_FS,
            2'h0,
            _mstatus_sstatus_VS,
            _mstatus_sstatus_SPP,
            2'h0,
            _mstatus_sstatus_SPIE,
            3'h0,
            _mstatus_sstatus_SIE,
            1'h0}
         : 64'h0)
    | (~isModeVS & addrHit_sie
         ? {_sie_regOut_LC63IE,
            _sie_regOut_LC62IE,
            _sie_regOut_LC61IE,
            _sie_regOut_LC60IE,
            _sie_regOut_LC59IE,
            _sie_regOut_LC58IE,
            _sie_regOut_LC57IE,
            _sie_regOut_LC56IE,
            _sie_regOut_LC55IE,
            _sie_regOut_LC54IE,
            _sie_regOut_LC53IE,
            _sie_regOut_LC52IE,
            _sie_regOut_LC51IE,
            _sie_regOut_LC50IE,
            _sie_regOut_LC49IE,
            _sie_regOut_LC48IE,
            _sie_regOut_LC47IE,
            _sie_regOut_LC46IE,
            _sie_regOut_LC45IE,
            _sie_regOut_LC44IE,
            _sie_regOut_HPRASEIE,
            _sie_regOut_LC42IE,
            _sie_regOut_LC41IE,
            _sie_regOut_LC40IE,
            _sie_regOut_LC39IE,
            _sie_regOut_LC38IE,
            _sie_regOut_LC37IE,
            _sie_regOut_LC36IE,
            _sie_regOut_LPRASEIE,
            _sie_regOut_LC34IE,
            _sie_regOut_LC33IE,
            _sie_regOut_LC32IE,
            _sie_regOut_LC31IE,
            _sie_regOut_LC30IE,
            _sie_regOut_LC29IE,
            _sie_regOut_LC28IE,
            _sie_regOut_LC27IE,
            _sie_regOut_LC26IE,
            _sie_regOut_LC25IE,
            _sie_regOut_LC24IE,
            _sie_regOut_LC23IE,
            _sie_regOut_LC22IE,
            _sie_regOut_LC21IE,
            _sie_regOut_LC20IE,
            _sie_regOut_LC19IE,
            _sie_regOut_LC18IE,
            _sie_regOut_LC17IE,
            _sie_regOut_LC16IE,
            _sie_regOut_LC15IE,
            _sie_regOut_LC14IE,
            _sie_regOut_LCOFIE,
            3'h0,
            _sie_regOut_SEIE,
            3'h0,
            _sie_regOut_STIE,
            3'h0,
            _sie_regOut_SSIE,
            1'h0}
         : 64'h0)
    | (~isModeVS & addrHit_stvec ? {_stvec_regOut_addr, _stvec_regOut_mode} : 64'h0)
    | (addrHit_scounteren
         ? {32'h0,
            _scounteren_regOut_HPM,
            _scounteren_regOut_IR,
            _scounteren_regOut_TM,
            _scounteren_regOut_CY}
         : 64'h0)
    | (addrHit_senvcfg
         ? {30'h0,
            _senvcfg_regOut_PMM,
            24'h0,
            _senvcfg_regOut_CBZE,
            _senvcfg_regOut_CBCFE,
            _senvcfg_regOut_CBIE,
            4'h0}
         : 64'h0) | (~isModeVS & addrHit_sscratch ? _sscratch_regOut_ALL : 64'h0)
    | (~isModeVS & addrHit_sepc ? {_sepc_regOut_epc, 1'h0} : 64'h0)
    | (~isModeVS & addrHit_scause
         ? {_scause_regOut_Interrupt, _scause_regOut_ExceptionCode}
         : 64'h0) | (~isModeVS & addrHit_stval ? _stval_regOut_ALL : 64'h0)
    | (~isModeVS & addrHit_sip
         ? {_sip_regOut_LC63IP,
            _sip_regOut_LC62IP,
            _sip_regOut_LC61IP,
            _sip_regOut_LC60IP,
            _sip_regOut_LC59IP,
            _sip_regOut_LC58IP,
            _sip_regOut_LC57IP,
            _sip_regOut_LC56IP,
            _sip_regOut_LC55IP,
            _sip_regOut_LC54IP,
            _sip_regOut_LC53IP,
            _sip_regOut_LC52IP,
            _sip_regOut_LC51IP,
            _sip_regOut_LC50IP,
            _sip_regOut_LC49IP,
            _sip_regOut_LC48IP,
            _sip_regOut_LC47IP,
            _sip_regOut_LC46IP,
            _sip_regOut_LC45IP,
            _sip_regOut_LC44IP,
            _sip_regOut_HPRASEIP,
            _sip_regOut_LC42IP,
            _sip_regOut_LC41IP,
            _sip_regOut_LC40IP,
            _sip_regOut_LC39IP,
            _sip_regOut_LC38IP,
            _sip_regOut_LC37IP,
            _sip_regOut_LC36IP,
            _sip_regOut_LPRASEIP,
            _sip_regOut_LC34IP,
            _sip_regOut_LC33IP,
            _sip_regOut_LC32IP,
            _sip_regOut_LC31IP,
            _sip_regOut_LC30IP,
            _sip_regOut_LC29IP,
            _sip_regOut_LC28IP,
            _sip_regOut_LC27IP,
            _sip_regOut_LC26IP,
            _sip_regOut_LC25IP,
            _sip_regOut_LC24IP,
            _sip_regOut_LC23IP,
            _sip_regOut_LC22IP,
            _sip_regOut_LC21IP,
            _sip_regOut_LC20IP,
            _sip_regOut_LC19IP,
            _sip_regOut_LC18IP,
            _sip_regOut_LC17IP,
            _sip_regOut_LC16IP,
            _sip_regOut_LC15IP,
            _sip_regOut_LC14IP,
            _sip_regOut_LCOFIP,
            3'h0,
            _sip_regOut_SEIP,
            3'h0,
            _sip_regOut_STIP,
            3'h0,
            _sip_regOut_SSIP,
            1'h0}
         : 64'h0) | (~isModeVS & addrHit_stimecmp ? _stimecmp_regOut_stimecmp : 64'h0)
    | (~isModeVS & addrHit_satp
         ? {_satp_regOut_MODE, _satp_regOut_ASID, _satp_regOut_PPN}
         : 64'h0);
  wire [63:0]  regOut_mhpm =
    regOut_mrg17
    | (addrHit_mhpmevent19
         ? {_Mhpmevent19_regOut_OF,
            _Mhpmevent19_regOut_MINH,
            _Mhpmevent19_regOut_SINH,
            _Mhpmevent19_regOut_UINH,
            _Mhpmevent19_regOut_VSINH,
            _Mhpmevent19_regOut_VUINH,
            3'h0,
            _Mhpmevent19_regOut_OPTYPE2,
            _Mhpmevent19_regOut_OPTYPE1,
            _Mhpmevent19_regOut_OPTYPE0,
            _Mhpmevent19_regOut_EVENT3,
            _Mhpmevent19_regOut_EVENT2,
            _Mhpmevent19_regOut_EVENT1,
            _Mhpmevent19_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent20
         ? {_Mhpmevent20_regOut_OF,
            _Mhpmevent20_regOut_MINH,
            _Mhpmevent20_regOut_SINH,
            _Mhpmevent20_regOut_UINH,
            _Mhpmevent20_regOut_VSINH,
            _Mhpmevent20_regOut_VUINH,
            3'h0,
            _Mhpmevent20_regOut_OPTYPE2,
            _Mhpmevent20_regOut_OPTYPE1,
            _Mhpmevent20_regOut_OPTYPE0,
            _Mhpmevent20_regOut_EVENT3,
            _Mhpmevent20_regOut_EVENT2,
            _Mhpmevent20_regOut_EVENT1,
            _Mhpmevent20_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent21
         ? {_Mhpmevent21_regOut_OF,
            _Mhpmevent21_regOut_MINH,
            _Mhpmevent21_regOut_SINH,
            _Mhpmevent21_regOut_UINH,
            _Mhpmevent21_regOut_VSINH,
            _Mhpmevent21_regOut_VUINH,
            3'h0,
            _Mhpmevent21_regOut_OPTYPE2,
            _Mhpmevent21_regOut_OPTYPE1,
            _Mhpmevent21_regOut_OPTYPE0,
            _Mhpmevent21_regOut_EVENT3,
            _Mhpmevent21_regOut_EVENT2,
            _Mhpmevent21_regOut_EVENT1,
            _Mhpmevent21_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent22
         ? {_Mhpmevent22_regOut_OF,
            _Mhpmevent22_regOut_MINH,
            _Mhpmevent22_regOut_SINH,
            _Mhpmevent22_regOut_UINH,
            _Mhpmevent22_regOut_VSINH,
            _Mhpmevent22_regOut_VUINH,
            3'h0,
            _Mhpmevent22_regOut_OPTYPE2,
            _Mhpmevent22_regOut_OPTYPE1,
            _Mhpmevent22_regOut_OPTYPE0,
            _Mhpmevent22_regOut_EVENT3,
            _Mhpmevent22_regOut_EVENT2,
            _Mhpmevent22_regOut_EVENT1,
            _Mhpmevent22_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent23
         ? {_Mhpmevent23_regOut_OF,
            _Mhpmevent23_regOut_MINH,
            _Mhpmevent23_regOut_SINH,
            _Mhpmevent23_regOut_UINH,
            _Mhpmevent23_regOut_VSINH,
            _Mhpmevent23_regOut_VUINH,
            3'h0,
            _Mhpmevent23_regOut_OPTYPE2,
            _Mhpmevent23_regOut_OPTYPE1,
            _Mhpmevent23_regOut_OPTYPE0,
            _Mhpmevent23_regOut_EVENT3,
            _Mhpmevent23_regOut_EVENT2,
            _Mhpmevent23_regOut_EVENT1,
            _Mhpmevent23_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent24
         ? {_Mhpmevent24_regOut_OF,
            _Mhpmevent24_regOut_MINH,
            _Mhpmevent24_regOut_SINH,
            _Mhpmevent24_regOut_UINH,
            _Mhpmevent24_regOut_VSINH,
            _Mhpmevent24_regOut_VUINH,
            3'h0,
            _Mhpmevent24_regOut_OPTYPE2,
            _Mhpmevent24_regOut_OPTYPE1,
            _Mhpmevent24_regOut_OPTYPE0,
            _Mhpmevent24_regOut_EVENT3,
            _Mhpmevent24_regOut_EVENT2,
            _Mhpmevent24_regOut_EVENT1,
            _Mhpmevent24_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent25
         ? {_Mhpmevent25_regOut_OF,
            _Mhpmevent25_regOut_MINH,
            _Mhpmevent25_regOut_SINH,
            _Mhpmevent25_regOut_UINH,
            _Mhpmevent25_regOut_VSINH,
            _Mhpmevent25_regOut_VUINH,
            3'h0,
            _Mhpmevent25_regOut_OPTYPE2,
            _Mhpmevent25_regOut_OPTYPE1,
            _Mhpmevent25_regOut_OPTYPE0,
            _Mhpmevent25_regOut_EVENT3,
            _Mhpmevent25_regOut_EVENT2,
            _Mhpmevent25_regOut_EVENT1,
            _Mhpmevent25_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent26
         ? {_Mhpmevent26_regOut_OF,
            _Mhpmevent26_regOut_MINH,
            _Mhpmevent26_regOut_SINH,
            _Mhpmevent26_regOut_UINH,
            _Mhpmevent26_regOut_VSINH,
            _Mhpmevent26_regOut_VUINH,
            3'h0,
            _Mhpmevent26_regOut_OPTYPE2,
            _Mhpmevent26_regOut_OPTYPE1,
            _Mhpmevent26_regOut_OPTYPE0,
            _Mhpmevent26_regOut_EVENT3,
            _Mhpmevent26_regOut_EVENT2,
            _Mhpmevent26_regOut_EVENT1,
            _Mhpmevent26_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent27
         ? {_Mhpmevent27_regOut_OF,
            _Mhpmevent27_regOut_MINH,
            _Mhpmevent27_regOut_SINH,
            _Mhpmevent27_regOut_UINH,
            _Mhpmevent27_regOut_VSINH,
            _Mhpmevent27_regOut_VUINH,
            3'h0,
            _Mhpmevent27_regOut_OPTYPE2,
            _Mhpmevent27_regOut_OPTYPE1,
            _Mhpmevent27_regOut_OPTYPE0,
            _Mhpmevent27_regOut_EVENT3,
            _Mhpmevent27_regOut_EVENT2,
            _Mhpmevent27_regOut_EVENT1,
            _Mhpmevent27_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent28
         ? {_Mhpmevent28_regOut_OF,
            _Mhpmevent28_regOut_MINH,
            _Mhpmevent28_regOut_SINH,
            _Mhpmevent28_regOut_UINH,
            _Mhpmevent28_regOut_VSINH,
            _Mhpmevent28_regOut_VUINH,
            3'h0,
            _Mhpmevent28_regOut_OPTYPE2,
            _Mhpmevent28_regOut_OPTYPE1,
            _Mhpmevent28_regOut_OPTYPE0,
            _Mhpmevent28_regOut_EVENT3,
            _Mhpmevent28_regOut_EVENT2,
            _Mhpmevent28_regOut_EVENT1,
            _Mhpmevent28_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent29
         ? {_Mhpmevent29_regOut_OF,
            _Mhpmevent29_regOut_MINH,
            _Mhpmevent29_regOut_SINH,
            _Mhpmevent29_regOut_UINH,
            _Mhpmevent29_regOut_VSINH,
            _Mhpmevent29_regOut_VUINH,
            3'h0,
            _Mhpmevent29_regOut_OPTYPE2,
            _Mhpmevent29_regOut_OPTYPE1,
            _Mhpmevent29_regOut_OPTYPE0,
            _Mhpmevent29_regOut_EVENT3,
            _Mhpmevent29_regOut_EVENT2,
            _Mhpmevent29_regOut_EVENT1,
            _Mhpmevent29_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent30
         ? {_Mhpmevent30_regOut_OF,
            _Mhpmevent30_regOut_MINH,
            _Mhpmevent30_regOut_SINH,
            _Mhpmevent30_regOut_UINH,
            _Mhpmevent30_regOut_VSINH,
            _Mhpmevent30_regOut_VUINH,
            3'h0,
            _Mhpmevent30_regOut_OPTYPE2,
            _Mhpmevent30_regOut_OPTYPE1,
            _Mhpmevent30_regOut_OPTYPE0,
            _Mhpmevent30_regOut_EVENT3,
            _Mhpmevent30_regOut_EVENT2,
            _Mhpmevent30_regOut_EVENT1,
            _Mhpmevent30_regOut_EVENT0}
         : 64'h0)
    | (addrHit_mhpmevent31
         ? {_Mhpmevent31_regOut_OF,
            _Mhpmevent31_regOut_MINH,
            _Mhpmevent31_regOut_SINH,
            _Mhpmevent31_regOut_UINH,
            _Mhpmevent31_regOut_VSINH,
            _Mhpmevent31_regOut_VUINH,
            3'h0,
            _Mhpmevent31_regOut_OPTYPE2,
            _Mhpmevent31_regOut_OPTYPE1,
            _Mhpmevent31_regOut_OPTYPE0,
            _Mhpmevent31_regOut_EVENT3,
            _Mhpmevent31_regOut_EVENT2,
            _Mhpmevent31_regOut_EVENT1,
            _Mhpmevent31_regOut_EVENT0}
         : 64'h0) | (addrHit_mhpmcounters_0 ? _mhpmcounters_0_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_1 ? _mhpmcounters_1_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_2 ? _mhpmcounters_2_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_3 ? _mhpmcounters_3_regOut_ALL : 64'h0)
    | (addrHit_mhpmcounters_4 ? _mhpmcounters_4_regOut_ALL : 64'h0) | regOut_mrg18;
  wire [63:0]  regOut_hyper =
    {regOut_mhpm[63:32],
     regOut_mhpm[31:0]
       | (addrHit_sstateen0
            ? {29'h0, _sstateen0_regOut_JVT, _sstateen0_regOut_FCSR, _sstateen0_regOut_C}
            : 32'h0) | (addrHit_sstateen1 ? _sstateen1_regOut_ALL : 32'h0)
       | (addrHit_sstateen2 ? _sstateen2_regOut_ALL : 32'h0)
       | (addrHit_sstateen3 ? _sstateen3_regOut_ALL : 32'h0)
       | (addrHit_scontext ? _scontext_regOut_ALL : 32'h0)}
    | (addrHit_hstatus
         ? {14'h0,
            _hstatus_regOut_HUPMM,
            25'h400,
            _hstatus_regOut_VTSR,
            _hstatus_regOut_VTW,
            _hstatus_regOut_VTVM,
            2'h0,
            _hstatus_regOut_VGEIN,
            2'h0,
            _hstatus_regOut_HU,
            _hstatus_regOut_SPVP,
            _hstatus_regOut_SPV,
            _hstatus_regOut_GVA,
            6'h0}
         : 64'h0)
    | (addrHit_hedeleg
         ? {44'h0,
            _hedeleg_regOut_EX_HWE,
            _hedeleg_regOut_EX_SWC,
            2'h0,
            _hedeleg_regOut_EX_SPF,
            1'h0,
            _hedeleg_regOut_EX_LPF,
            _hedeleg_regOut_EX_IPF,
            3'h0,
            _hedeleg_regOut_EX_UCALL,
            _hedeleg_regOut_EX_SAF,
            _hedeleg_regOut_EX_SAM,
            _hedeleg_regOut_EX_LAF,
            _hedeleg_regOut_EX_LAM,
            _hedeleg_regOut_EX_BP,
            _hedeleg_regOut_EX_II,
            _hedeleg_regOut_EX_IAF,
            _hedeleg_regOut_EX_IAM}
         : 64'h0)
    | (addrHit_hideleg
         ? {50'h0,
            _hideleg_regOut_LCOFI,
            _hideleg_regOut_SGEI,
            _hideleg_regOut_MEI,
            _hideleg_regOut_VSEI,
            _hideleg_regOut_SEI,
            1'h0,
            _hideleg_regOut_MTI,
            _hideleg_regOut_VSTI,
            _hideleg_regOut_STI,
            1'h0,
            _hideleg_regOut_MSI,
            _hideleg_regOut_VSSI,
            _hideleg_regOut_SSI,
            1'h0}
         : 64'h0)
    | (addrHit_hie
         ? {51'h0,
            _hie_regOut_SGEIE,
            1'h0,
            _hie_regOut_VSEIE,
            3'h0,
            _hie_regOut_VSTIE,
            3'h0,
            _hie_regOut_VSSIE,
            2'h0}
         : 64'h0) | (addrHit_htimedelta ? _htimedelta_regOut_ALL : 64'h0)
    | (addrHit_hcounteren
         ? {32'h0,
            _hcounteren_regOut_HPM,
            _hcounteren_regOut_IR,
            _hcounteren_regOut_TM,
            _hcounteren_regOut_CY}
         : 64'h0) | (addrHit_hgeie ? {58'h0, _hgeie_regOut_ie, 1'h0} : 64'h0)
    | (addrHit_hvien
         ? {_hvien_regOut_LC63IE,
            _hvien_regOut_LC62IE,
            _hvien_regOut_LC61IE,
            _hvien_regOut_LC60IE,
            _hvien_regOut_LC59IE,
            _hvien_regOut_LC58IE,
            _hvien_regOut_LC57IE,
            _hvien_regOut_LC56IE,
            _hvien_regOut_LC55IE,
            _hvien_regOut_LC54IE,
            _hvien_regOut_LC53IE,
            _hvien_regOut_LC52IE,
            _hvien_regOut_LC51IE,
            _hvien_regOut_LC50IE,
            _hvien_regOut_LC49IE,
            _hvien_regOut_LC48IE,
            _hvien_regOut_LC47IE,
            _hvien_regOut_LC46IE,
            _hvien_regOut_LC45IE,
            _hvien_regOut_LC44IE,
            _hvien_regOut_HPRASEIE,
            _hvien_regOut_LC42IE,
            _hvien_regOut_LC41IE,
            _hvien_regOut_LC40IE,
            _hvien_regOut_LC39IE,
            _hvien_regOut_LC38IE,
            _hvien_regOut_LC37IE,
            _hvien_regOut_LC36IE,
            _hvien_regOut_LPRASEIE,
            _hvien_regOut_LC34IE,
            _hvien_regOut_LC33IE,
            _hvien_regOut_LC32IE,
            _hvien_regOut_LC31IE,
            _hvien_regOut_LC30IE,
            _hvien_regOut_LC29IE,
            _hvien_regOut_LC28IE,
            _hvien_regOut_LC27IE,
            _hvien_regOut_LC26IE,
            _hvien_regOut_LC25IE,
            _hvien_regOut_LC24IE,
            _hvien_regOut_LC23IE,
            _hvien_regOut_LC22IE,
            _hvien_regOut_LC21IE,
            _hvien_regOut_LC20IE,
            _hvien_regOut_LC19IE,
            _hvien_regOut_LC18IE,
            _hvien_regOut_LC17IE,
            _hvien_regOut_LC16IE,
            _hvien_regOut_LC15IE,
            _hvien_regOut_LC14IE,
            14'h0}
         : 64'h0)
    | (addrHit_hvictl
         ? {33'h0,
            _hvictl_regOut_VTI,
            2'h0,
            _hvictl_regOut_IID,
            6'h0,
            _hvictl_regOut_DPR,
            _hvictl_regOut_IPRIOM,
            _hvictl_regOut_IPRIO}
         : 64'h0)
    | (addrHit_henvcfg
         ? {_henvcfg_regOut_STCE,
            _henvcfg_regOut_PBMTE,
            2'h0,
            _henvcfg_regOut_DTE,
            25'h0,
            _henvcfg_regOut_PMM,
            24'h0,
            _henvcfg_regOut_CBZE,
            _henvcfg_regOut_CBCFE,
            _henvcfg_regOut_CBIE,
            4'h0}
         : 64'h0) | (addrHit_htval ? _htval_regOut_ALL : 64'h0)
    | (addrHit_hip
         ? {51'h0,
            _hip_regOut_SGEIP,
            1'h0,
            _hip_regOut_VSEIP,
            3'h0,
            _hip_regOut_VSTIP,
            3'h0,
            _hip_regOut_VSSIP,
            2'h0}
         : 64'h0)
    | (addrHit_hvip
         ? {_hvip_regOut_LC63IP,
            _hvip_regOut_LC62IP,
            _hvip_regOut_LC61IP,
            _hvip_regOut_LC60IP,
            _hvip_regOut_LC59IP,
            _hvip_regOut_LC58IP,
            _hvip_regOut_LC57IP,
            _hvip_regOut_LC56IP,
            _hvip_regOut_LC55IP,
            _hvip_regOut_LC54IP,
            _hvip_regOut_LC53IP,
            _hvip_regOut_LC52IP,
            _hvip_regOut_LC51IP,
            _hvip_regOut_LC50IP,
            _hvip_regOut_LC49IP,
            _hvip_regOut_LC48IP,
            _hvip_regOut_LC47IP,
            _hvip_regOut_LC46IP,
            _hvip_regOut_LC45IP,
            _hvip_regOut_LC44IP,
            _hvip_regOut_HPRASEIP,
            _hvip_regOut_LC42IP,
            _hvip_regOut_LC41IP,
            _hvip_regOut_LC40IP,
            _hvip_regOut_LC39IP,
            _hvip_regOut_LC38IP,
            _hvip_regOut_LC37IP,
            _hvip_regOut_LC36IP,
            _hvip_regOut_LPRASEIP,
            _hvip_regOut_LC34IP,
            _hvip_regOut_LC33IP,
            _hvip_regOut_LC32IP,
            _hvip_regOut_LC31IP,
            _hvip_regOut_LC30IP,
            _hvip_regOut_LC29IP,
            _hvip_regOut_LC28IP,
            _hvip_regOut_LC27IP,
            _hvip_regOut_LC26IP,
            _hvip_regOut_LC25IP,
            _hvip_regOut_LC24IP,
            _hvip_regOut_LC23IP,
            _hvip_regOut_LC22IP,
            _hvip_regOut_LC21IP,
            _hvip_regOut_LC20IP,
            _hvip_regOut_LC19IP,
            _hvip_regOut_LC18IP,
            _hvip_regOut_LC17IP,
            _hvip_regOut_LC16IP,
            _hvip_regOut_LC15IP,
            _hvip_regOut_LC14IP,
            _hvip_regOut_LCOFIP,
            2'h0,
            _hvip_regOut_VSEIP,
            3'h0,
            _hvip_regOut_VSTIP,
            3'h0,
            _hvip_regOut_VSSIP,
            2'h0}
         : 64'h0)
    | (addrHit_hviprio1
         ? {_hviprio1_regOut_Prio15,
            _hviprio1_regOut_Prio14,
            _hviprio1_regOut_PrioCOI,
            8'h0,
            _hviprio1_regOut_PrioSTI,
            8'h0,
            _hviprio1_regOut_PrioSSI,
            8'h0}
         : 64'h0) | (addrHit_hviprio2 ? _hviprio2_regOut_ALL : 64'h0)
    | (addrHit_htinst ? _htinst_regOut_ALL : 64'h0)
    | (addrHit_hgatp
         ? {_hgatp_regOut_MODE, 2'h0, _hgatp_regOut_VMID, _hgatp_regOut_PPN}
         : 64'h0)
    | (addrHit_hstateen0
         ? {_hstateen0_regOut_SE0,
            _hstateen0_regOut_ENVCFG,
            1'h0,
            _hstateen0_regOut_CSRIND,
            _hstateen0_regOut_AIA,
            _hstateen0_regOut_IMSIC,
            _hstateen0_regOut_CONTEXT,
            54'h0,
            _hstateen0_regOut_JVT,
            _hstateen0_regOut_FCSR,
            _hstateen0_regOut_C}
         : 64'h0) | (addrHit_hstateen1 ? {_hstateen1_regOut_SE, 63'h0} : 64'h0)
    | (addrHit_hstateen2 ? {_hstateen2_regOut_SE, 63'h0} : 64'h0)
    | (addrHit_hstateen3 ? {_hstateen3_regOut_SE, 63'h0} : 64'h0);
  wire [63:0]  regOut_vs =
    {regOut_hyper[63:14],
     regOut_hyper[13:0] | (addrHit_hcontext ? _hcontext_regOut_HCONTEXT : 14'h0)}
    | (isModeVS & addrHit_sstatus | ~isModeVS & addrHit_vsstatus
         ? {39'h100,
            _vsstatus_regOut_SDT,
            4'h0,
            _vsstatus_regOut_MXR,
            _vsstatus_regOut_SUM,
            3'h0,
            _vsstatus_regOut_FS,
            2'h0,
            _vsstatus_regOut_VS,
            _vsstatus_regOut_SPP,
            2'h0,
            _vsstatus_regOut_SPIE,
            3'h0,
            _vsstatus_regOut_SIE,
            1'h0}
         : 64'h0)
    | (isModeVS & addrHit_sie | ~isModeVS & addrHit_vsie
         ? {_vsie_regOut_LC63IE,
            _vsie_regOut_LC62IE,
            _vsie_regOut_LC61IE,
            _vsie_regOut_LC60IE,
            _vsie_regOut_LC59IE,
            _vsie_regOut_LC58IE,
            _vsie_regOut_LC57IE,
            _vsie_regOut_LC56IE,
            _vsie_regOut_LC55IE,
            _vsie_regOut_LC54IE,
            _vsie_regOut_LC53IE,
            _vsie_regOut_LC52IE,
            _vsie_regOut_LC51IE,
            _vsie_regOut_LC50IE,
            _vsie_regOut_LC49IE,
            _vsie_regOut_LC48IE,
            _vsie_regOut_LC47IE,
            _vsie_regOut_LC46IE,
            _vsie_regOut_LC45IE,
            _vsie_regOut_LC44IE,
            _vsie_regOut_HPRASEIE,
            _vsie_regOut_LC42IE,
            _vsie_regOut_LC41IE,
            _vsie_regOut_LC40IE,
            _vsie_regOut_LC39IE,
            _vsie_regOut_LC38IE,
            _vsie_regOut_LC37IE,
            _vsie_regOut_LC36IE,
            _vsie_regOut_LPRASEIE,
            _vsie_regOut_LC34IE,
            _vsie_regOut_LC33IE,
            _vsie_regOut_LC32IE,
            _vsie_regOut_LC31IE,
            _vsie_regOut_LC30IE,
            _vsie_regOut_LC29IE,
            _vsie_regOut_LC28IE,
            _vsie_regOut_LC27IE,
            _vsie_regOut_LC26IE,
            _vsie_regOut_LC25IE,
            _vsie_regOut_LC24IE,
            _vsie_regOut_LC23IE,
            _vsie_regOut_LC22IE,
            _vsie_regOut_LC21IE,
            _vsie_regOut_LC20IE,
            _vsie_regOut_LC19IE,
            _vsie_regOut_LC18IE,
            _vsie_regOut_LC17IE,
            _vsie_regOut_LC16IE,
            _vsie_regOut_LC15IE,
            _vsie_regOut_LC14IE,
            _vsie_regOut_LCOFIE,
            3'h0,
            _vsie_regOut_SEIE,
            3'h0,
            _vsie_regOut_STIE,
            3'h0,
            _vsie_regOut_SSIE,
            1'h0}
         : 64'h0)
    | (isModeVS & addrHit_stvec | ~isModeVS & addrHit_vstvec
         ? {_vstvec_regOut_addr, _vstvec_regOut_mode}
         : 64'h0)
    | (isModeVS & addrHit_sscratch | ~isModeVS & addrHit_vsscratch
         ? _vsscratch_regOut_ALL
         : 64'h0)
    | (isModeVS & addrHit_sepc | ~isModeVS & addrHit_vsepc
         ? {_vsepc_regOut_epc, 1'h0}
         : 64'h0)
    | (isModeVS & addrHit_scause | ~isModeVS & addrHit_vscause
         ? {_vscause_regOut_Interrupt, _vscause_regOut_ExceptionCode}
         : 64'h0)
    | (isModeVS & addrHit_stval | ~isModeVS & addrHit_vstval
         ? _vstval_regOut_ALL
         : 64'h0)
    | (isModeVS & addrHit_sip | ~isModeVS & addrHit_vsip
         ? {_vsip_regOut_LC63IP,
            _vsip_regOut_LC62IP,
            _vsip_regOut_LC61IP,
            _vsip_regOut_LC60IP,
            _vsip_regOut_LC59IP,
            _vsip_regOut_LC58IP,
            _vsip_regOut_LC57IP,
            _vsip_regOut_LC56IP,
            _vsip_regOut_LC55IP,
            _vsip_regOut_LC54IP,
            _vsip_regOut_LC53IP,
            _vsip_regOut_LC52IP,
            _vsip_regOut_LC51IP,
            _vsip_regOut_LC50IP,
            _vsip_regOut_LC49IP,
            _vsip_regOut_LC48IP,
            _vsip_regOut_LC47IP,
            _vsip_regOut_LC46IP,
            _vsip_regOut_LC45IP,
            _vsip_regOut_LC44IP,
            _vsip_regOut_HPRASEIP,
            _vsip_regOut_LC42IP,
            _vsip_regOut_LC41IP,
            _vsip_regOut_LC40IP,
            _vsip_regOut_LC39IP,
            _vsip_regOut_LC38IP,
            _vsip_regOut_LC37IP,
            _vsip_regOut_LC36IP,
            _vsip_regOut_LPRASEIP,
            _vsip_regOut_LC34IP,
            _vsip_regOut_LC33IP,
            _vsip_regOut_LC32IP,
            _vsip_regOut_LC31IP,
            _vsip_regOut_LC30IP,
            _vsip_regOut_LC29IP,
            _vsip_regOut_LC28IP,
            _vsip_regOut_LC27IP,
            _vsip_regOut_LC26IP,
            _vsip_regOut_LC25IP,
            _vsip_regOut_LC24IP,
            _vsip_regOut_LC23IP,
            _vsip_regOut_LC22IP,
            _vsip_regOut_LC21IP,
            _vsip_regOut_LC20IP,
            _vsip_regOut_LC19IP,
            _vsip_regOut_LC18IP,
            _vsip_regOut_LC17IP,
            _vsip_regOut_LC16IP,
            _vsip_regOut_LC15IP,
            _vsip_regOut_LC14IP,
            _vsip_regOut_LCOFIP,
            3'h0,
            _vsip_regOut_SEIP,
            3'h0,
            _vsip_regOut_STIP,
            3'h0,
            _vsip_regOut_SSIP,
            1'h0}
         : 64'h0)
    | (isModeVS & addrHit_stimecmp | ~isModeVS & addrHit_vstimecmp
         ? _vstimecmp_regOut_vstimecmp
         : 64'h0)
    | (isModeVS & addrHit_satp | ~isModeVS & addrHit_vsatp
         ? {_vsatp_regOut_MODE, _vsatp_regOut_ASID, _vsatp_regOut_PPN}
         : 64'h0);
  wire [4:0]   regOut_mrg19 = regOut_vs[4:0] | (addrHit_fflags ? _fcsr_fflags : 5'h0);
  wire [63:0]  regOut_fp =
    {regOut_vs[63:5],
     regOut_mrg19[4:3],
     regOut_mrg19[2:0] | (addrHit_frm ? _fcsr_frm : 3'h0)}
    | (addrHit_fcsr ? _fcsr_rdata : 64'h0)
    | (addrHit_vstart ? _vstart_rdata : 64'h0);
  wire [63:0]  regOut_pre =
    {regOut_fp[63:2],
     {regOut_fp[1], regOut_fp[0] | addrHit_vxsat & _vcsr_vxsat}
       | (addrHit_vxrm ? _vcsr_vxrm : 2'h0)}
    | (addrHit_vcsr ? _vcsr_rdata : 64'h0)
    | (addrHit_tdata1 ? _tdata1_regOut_ALL : 64'h0)
    | (addrHit_tdata2 ? _tdata2_regOut_ALL : 64'h0);

  // ----- regOut 输出（pre 的尾部位域 merge + IMSIC/pmp/扩展 OR-树）-----
  assign io_out_bits_regOut =
    {regOut_pre[63:32],
     {regOut_pre[31:7],
      regOut_pre[6] | addrHit_tinfo,
      regOut_pre[5:2],
      regOut_pre[1:0] | (addrHit_tselect ? _tselect_regOut_ALL : 2'h0)}
       | (addrHit_dcsr
            ? {12'h400,
               _dcsr_regOut_CETRIG,
               1'h0,
               _dcsr_regOut_EBREAKVS,
               _dcsr_regOut_EBREAKVU,
               _dcsr_regOut_EBREAKM,
               1'h0,
               _dcsr_regOut_EBREAKS,
               _dcsr_regOut_EBREAKU,
               _dcsr_regOut_STEPIE,
               _dcsr_regOut_STOPCOUNT,
               _dcsr_regOut_STOPTIME,
               _dcsr_regOut_CAUSE,
               _dcsr_regOut_V,
               _dcsr_regOut_MPRVEN,
               _dcsr_regOut_NMIP,
               _dcsr_regOut_STEP,
               _dcsr_regOut_PRV}
            : 32'h0)} | (addrHit_dpc ? {_dpc_regOut_epc, 1'h0} : 64'h0)
    | (addrHit_dscratch0 ? _dscratch0_regOut_ALL : 64'h0)
    | (addrHit_dscratch1 ? _dscratch1_regOut_ALL : 64'h0)
    | (addrHit_miselect ? {55'h0, _miselect_regOut_ALL} : 64'h0)
    | (addrHit_mireg ? _mireg_regOut_ALL : 64'h0)
    | (addrHit_mtopei
         ? {37'h0, _mtopei_regOut_IID, 5'h0, _mtopei_regOut_IPRIO}
         : 64'h0)
    | (~isModeVS & addrHit_siselect ? {51'h0, _siselect_regOut_ALL} : 64'h0)
    | (~isModeVS & addrHit_sireg ? _sireg_regOut_ALL : 64'h0)
    | (~isModeVS & addrHit_stopei
         ? {37'h0, _stopei_regOut_IID, 5'h0, _stopei_regOut_IPRIO}
         : 64'h0)
    | (isModeVS & addrHit_siselect | ~isModeVS & addrHit_vsiselect
         ? {51'h0, _vsiselect_regOut_ALL}
         : 64'h0)
    | (isModeVS & addrHit_sireg | ~isModeVS & addrHit_vsireg
         ? _vsireg_regOut_ALL
         : 64'h0)
    | (isModeVS & addrHit_stopei | ~isModeVS & addrHit_vstopei
         ? {37'h0, _vstopei_regOut_IID, 5'h0, _vstopei_regOut_IPRIO}
         : 64'h0) | (addrHit_mireg2 ? _mireg2_regOut_ALL : 64'h0)
    | (addrHit_mireg3 ? _mireg3_regOut_ALL : 64'h0)
    | (addrHit_mireg4 ? _mireg4_regOut_ALL : 64'h0)
    | (addrHit_mireg5 ? _mireg5_regOut_ALL : 64'h0)
    | (addrHit_mireg6 ? _mireg6_regOut_ALL : 64'h0)
    | (addrHit_sireg2 ? _sireg2_regOut_ALL : 64'h0)
    | (addrHit_sireg3 ? _sireg3_regOut_ALL : 64'h0)
    | (addrHit_sireg4 ? _sireg4_regOut_ALL : 64'h0)
    | (addrHit_sireg5 ? _sireg5_regOut_ALL : 64'h0)
    | (addrHit_sireg6 ? _sireg6_regOut_ALL : 64'h0)
    | (addrHit_vsireg2 ? _vsireg2_regOut_ALL : 64'h0)
    | (addrHit_vsireg3 ? _vsireg3_regOut_ALL : 64'h0)
    | (addrHit_vsireg4 ? _vsireg4_regOut_ALL : 64'h0)
    | (addrHit_vsireg5 ? _vsireg5_regOut_ALL : 64'h0)
    | (addrHit_vsireg6 ? _vsireg6_regOut_ALL : 64'h0)
    | (addrHit_sbpctl
         ? {57'h0,
            _sbpctl_regOut_LOOP_ENABLE,
            _sbpctl_regOut_RAS_ENABLE,
            _sbpctl_regOut_SC_ENABLE,
            _sbpctl_regOut_TAGE_ENABLE,
            _sbpctl_regOut_BIM_ENABLE,
            _sbpctl_regOut_BTB_ENABLE,
            _sbpctl_regOut_UBTB_ENABLE}
         : 64'h0)
    | (addrHit_spfctl
         ? {42'h0,
            _spfctl_regOut_L2_PF_TP_ENABLE,
            _spfctl_regOut_L2_PF_VBOP_ENABLE,
            _spfctl_regOut_L2_PF_PBOP_ENABLE,
            _spfctl_regOut_L2_PF_RECV_ENABLE,
            _spfctl_regOut_L2_PF_STORE_ONLY,
            _spfctl_regOut_L1D_PF_ENABLE_STRIDE,
            _spfctl_regOut_L1D_PF_ACTIVE_STRIDE,
            _spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD,
            _spfctl_regOut_L1D_PF_ENABLE_PHT,
            _spfctl_regOut_L1D_PF_ENABLE_AGT,
            _spfctl_regOut_L1D_PF_TRAIN_ON_HIT,
            _spfctl_regOut_L1D_PF_ENABLE,
            _spfctl_regOut_L2_PF_ENABLE,
            _spfctl_regOut_L1I_PF_ENABLE}
         : 64'h0)
    | (addrHit_slvpredctl
         ? {55'h0,
            _slvpredctl_regOut_LVPRED_TIMEOUT,
            _slvpredctl_regOut_STORESET_NO_FAST_WAKEUP,
            _slvpredctl_regOut_STORESET_WAIT_STORE,
            _slvpredctl_regOut_NO_SPEC_LOAD,
            _slvpredctl_regOut_LVPRED_DISABLE}
         : 64'h0)
    | (addrHit_smblockctl
         ? {54'h0,
            _smblockctl_regOut_HD_MISALIGN_LD_ENABLE,
            _smblockctl_regOut_HD_MISALIGN_ST_ENABLE,
            _smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE,
            _smblockctl_regOut_CACHE_ERROR_ENABLE,
            _smblockctl_regOut_SOFT_PREFETCH_ENABLE,
            _smblockctl_regOut_LDLD_VIO_CHECK_ENABLE,
            _smblockctl_regOut_SBUFFER_THRESHOLD}
         : 64'h0)
    | (addrHit_srnctl
         ? {61'h0, _srnctl_regOut_WFI_ENABLE, 1'h0, _srnctl_regOut_FUSION_ENABLE}
         : 64'h0)
    | (addrHit_mcorepwr ? {63'h0, _mcorepwr_regOut_POWER_DOWN_ENABLE} : 64'h0)
    | (addrHit_mflushpwr
         ? {62'h0, _mflushpwr_regOut_L2_FLUSH_DONE, _mflushpwr_regOut_FLUSH_L2_ENABLE}
         : 64'h0) | (addrHit_pmpcfg_0 ? _pmpcfg_0_regOut_ALL : 64'h0)
    | (addrHit_pmpcfg_1 ? _pmpcfg_1_regOut_ALL : 64'h0)
    | (addrHit_pmpaddr_0 ? {18'h0, _pmpaddr_0_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_1 ? {18'h0, _pmpaddr_1_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_2 ? {18'h0, _pmpaddr_2_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_3 ? {18'h0, _pmpaddr_3_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_4 ? {18'h0, _pmpaddr_4_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_5 ? {18'h0, _pmpaddr_5_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_6 ? {18'h0, _pmpaddr_6_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_7 ? {18'h0, _pmpaddr_7_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_8 ? {18'h0, _pmpaddr_8_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_9 ? {18'h0, _pmpaddr_9_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_10 ? {18'h0, _pmpaddr_10_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_11 ? {18'h0, _pmpaddr_11_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_12 ? {18'h0, _pmpaddr_12_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_13 ? {18'h0, _pmpaddr_13_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_14 ? {18'h0, _pmpaddr_14_regOut_ADDRESS} : 64'h0)
    | (addrHit_pmpaddr_15 ? {18'h0, _pmpaddr_15_regOut_ADDRESS} : 64'h0);

  // io_out_bits_isPerfCnt 在步2 FSM 块驱动。
  // 步3：fp/vec 状态直通 fcsr/vstart/vcsr 读出位域（golden 14102-14104）。
  assign io_status_fpState_frm     = _fcsr_frm;
  assign io_status_vecState_vstart = _vstart_rdata[6:0];
  assign io_status_vecState_vxrm   = _vcsr_vxrm;
  // 单步标志：非 debug 模式且 dcsr.STEP 置位（golden 5230）。供 wfi_enable / 本输出共用。
  wire singleStepFlag = ~debugMode & _dcsr_regOut_STEP;
  assign io_status_singleStepFlag = singleStepFlag;
  // io_status_frontendTrigger_* / io_status_memTrigger_* 由 debugMod 子模块实例
  //   直接驱动（newcsr_inst.svh，golden 13570-13608）；此处不再占位（占位会形成多驱动）。
  // 步3：traceCSR cause/tval 按当前特权态选 mcause/scause/vscause（golden 14111-14116）。
  assign io_status_traceCSR_cause =
    (isModeM ? _mcause_rdata : 64'h0) | (isModeHS ? _scause_rdata : 64'h0)
    | (isModeVS ? _vscause_rdata : 64'h0);
  assign io_status_traceCSR_tval =
    (isModeM ? _mtval_rdata[49:0] : 50'h0) | (isModeHS ? _stval_rdata[49:0] : 50'h0)
    | (isModeVS ? _vstval_rdata[49:0] : 50'h0);
  // 步3：io_status_custom_* 直通各控制 CSR 的 regOut 位域（golden 14119-14156）。
  //   这些 regOut 源为子模块黑盒输出（decls 网，inst.svh 驱动）；本块为纯组合直通。
  assign io_status_custom_pf_ctrl_l1I_pf_enable       = _spfctl_regOut_L1I_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_enable        = _spfctl_regOut_L2_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l1D_pf_enable       = _spfctl_regOut_L1D_PF_ENABLE;
  assign io_status_custom_pf_ctrl_l1D_pf_train_on_hit = _spfctl_regOut_L1D_PF_TRAIN_ON_HIT;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_agt   = _spfctl_regOut_L1D_PF_ENABLE_AGT;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_pht   = _spfctl_regOut_L1D_PF_ENABLE_PHT;
  assign io_status_custom_pf_ctrl_l1D_pf_active_threshold = _spfctl_regOut_L1D_PF_ACTIVE_THRESHOLD;
  assign io_status_custom_pf_ctrl_l1D_pf_active_stride    = _spfctl_regOut_L1D_PF_ACTIVE_STRIDE;
  assign io_status_custom_pf_ctrl_l1D_pf_enable_stride    = _spfctl_regOut_L1D_PF_ENABLE_STRIDE;
  assign io_status_custom_pf_ctrl_l2_pf_store_only    = _spfctl_regOut_L2_PF_STORE_ONLY;
  assign io_status_custom_pf_ctrl_l2_pf_recv_enable   = _spfctl_regOut_L2_PF_RECV_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_pbop_enable   = _spfctl_regOut_L2_PF_PBOP_ENABLE;
  assign io_status_custom_pf_ctrl_l2_pf_vbop_enable   = _spfctl_regOut_L2_PF_VBOP_ENABLE;
  assign io_status_custom_lvpred_timeout      = _slvpredctl_regOut_LVPRED_TIMEOUT;
  assign io_status_custom_bp_ctrl_ubtb_enable = _sbpctl_regOut_UBTB_ENABLE;
  assign io_status_custom_bp_ctrl_btb_enable  = _sbpctl_regOut_BTB_ENABLE;
  assign io_status_custom_bp_ctrl_tage_enable = _sbpctl_regOut_TAGE_ENABLE;
  assign io_status_custom_bp_ctrl_sc_enable   = _sbpctl_regOut_SC_ENABLE;
  assign io_status_custom_bp_ctrl_ras_enable  = _sbpctl_regOut_RAS_ENABLE;
  assign io_status_custom_ldld_vio_check_enable = _smblockctl_regOut_LDLD_VIO_CHECK_ENABLE;
  assign io_status_custom_cache_error_enable    = _smblockctl_regOut_CACHE_ERROR_ENABLE;
  assign io_status_custom_uncache_write_outstanding_enable = _smblockctl_regOut_UNCACHE_WRITE_OUTSTANDING_ENABLE;
  assign io_status_custom_hd_misalign_st_enable = _smblockctl_regOut_HD_MISALIGN_ST_ENABLE;
  assign io_status_custom_hd_misalign_ld_enable = _smblockctl_regOut_HD_MISALIGN_LD_ENABLE;
  assign io_status_custom_power_down_enable      = _mcorepwr_regOut_POWER_DOWN_ENABLE;
  assign io_status_custom_flush_l2_enable        = _mflushpwr_regOut_FLUSH_L2_ENABLE;
  assign io_status_custom_fusion_enable          = _srnctl_regOut_FUSION_ENABLE;
  assign io_status_custom_wfi_enable =
    _srnctl_regOut_WFI_ENABLE & ~singleStepFlag & ~debugMode;
  // io_status_criticalErrorState = criticalErrorState & ~CETRIG（golden 5361-5362/14156）。
  assign io_status_criticalErrorState = criticalErrorState & ~_dcsr_regOut_CETRIG;
  // 步3：TLB 视图输出（golden 14157-14191）——satp/vsatp/hgatp 字段切片、
  //   mxr/sum/spvp 直通、dmode/dvirt 按 MPRV/debug 决定有效特权态、PBMTE/PMM 打拍。
  assign io_tlb_satpASIDChanged  = io_tlb_satpASIDChanged_last_REG;
  assign io_tlb_vsatpASIDChanged = io_tlb_vsatpASIDChanged_last_REG;
  assign io_tlb_hgatpVMIDChanged = io_tlb_hgatpVMIDChanged_last_REG;
  assign io_tlb_satp_MODE  = _satp_rdata[63:60];
  assign io_tlb_satp_ASID  = _satp_rdata[59:44];
  assign io_tlb_satp_PPN   = _satp_rdata[43:0];
  assign io_tlb_vsatp_MODE = _vsatp_rdata[63:60];
  assign io_tlb_vsatp_ASID = _vsatp_rdata[59:44];
  assign io_tlb_vsatp_PPN  = _vsatp_rdata[43:0];
  assign io_tlb_hgatp_MODE = _hgatp_rdata[63:60];
  assign io_tlb_hgatp_VMID = _hgatp_rdata[57:44];
  assign io_tlb_hgatp_PPN  = _hgatp_rdata[43:0];
  assign io_tlb_mxr  = _mstatus_regOut_MXR;
  assign io_tlb_sum  = _mstatus_regOut_SUM;
  assign io_tlb_vmxr = _vsstatus_regOut_MXR;
  assign io_tlb_vsum = _vsstatus_regOut_SUM;
  assign io_tlb_spvp = _hstatus_regOut_SPVP;
  assign io_tlb_dmode =
    (debugMode & _dcsr_regOut_MPRVEN | ~debugMode) & _mstatus_regOut_MPRV
    & _mnstatus_regOut_NMIE
      ? _mstatus_regOut_MPP
      : PRVM;
  assign io_tlb_dvirt =
    (debugMode & _dcsr_regOut_MPRVEN | ~debugMode) & _mstatus_regOut_MPRV
    & _mnstatus_regOut_NMIE & (_mstatus_regOut_MPP != 2'h3)
      ? _mstatus_regOut_MPV
      : V;
  assign io_tlb_mPBMTE      = io_tlb_mPBMTE_REG;
  assign io_tlb_hPBMTE      = io_tlb_hPBMTE_REG;
  assign io_tlb_pmm_mseccfg = io_tlb_pmm_mseccfg_REG;
  assign io_tlb_pmm_menvcfg = io_tlb_pmm_menvcfg_REG;
  assign io_tlb_pmm_henvcfg = io_tlb_pmm_henvcfg_REG;
  assign io_tlb_pmm_hstatus = io_tlb_pmm_hstatus_REG;
  assign io_tlb_pmm_senvcfg = io_tlb_pmm_senvcfg_REG;
  // 步3：toDecode 非法/虚拟指令判定（golden 5351-5359 helper + 14192-14231）。
  //   按当前特权态 + 各 envcfg/status 控制位判定 fence/hlsv/wfi/cbo 等指令是否非法。
  wire io_toDecode_virtualInst_hlsv_0 = isModeVS | isModeVU;
  wire io_toDecode_illegalInst_cboI_0 =
    ~isModeM & _menvcfg_regOut_CBIE == 2'h0
    | isModeHU & (_senvcfg_regOut_CBIE == 2'h0);
  wire io_toDecode_virtualInst_cboI_0 =
    (|_menvcfg_regOut_CBIE)
    & (isModeVS & (_henvcfg_regOut_CBIE == 2'h0)
       | isModeVU & ((_henvcfg_regOut_CBIE == 2'h0) | (_senvcfg_regOut_CBIE == 2'h0)));

  assign io_toDecode_illegalInst_sfenceVMA  = isModeHS & _mstatus_regOut_TVM | isModeHU;
  assign io_toDecode_illegalInst_sfencePart = isModeHU;
  assign io_toDecode_illegalInst_hfenceGVMA = isModeHS & _mstatus_regOut_TVM | isModeHU;
  assign io_toDecode_illegalInst_hfenceVVMA = isModeHU;
  assign io_toDecode_illegalInst_hlsv       = isModeHU & ~_hstatus_regOut_HU;
  assign io_toDecode_illegalInst_fsIsOff =
    mstatusFsIsOff | io_toDecode_virtualInst_hlsv_0
    & vsFsIsOff;
  assign io_toDecode_illegalInst_vsIsOff =
    mstatusVsIsOff | io_toDecode_virtualInst_hlsv_0
    & vsVsIsOff;
  assign io_toDecode_illegalInst_wfi    = isModeHU | ~isModeM & _mstatus_regOut_TW;
  assign io_toDecode_illegalInst_wrs_nto = ~isModeM & _mstatus_regOut_TW;
  assign io_toDecode_illegalInst_frm    = frmIsReserved;
  assign io_toDecode_illegalInst_cboZ =
    ~isModeM & ~_menvcfg_regOut_CBZE | isModeHU & ~_senvcfg_regOut_CBZE;
  assign io_toDecode_illegalInst_cboCF =
    ~isModeM & ~_menvcfg_regOut_CBCFE | isModeHU & ~_senvcfg_regOut_CBCFE;
  assign io_toDecode_illegalInst_cboI   = io_toDecode_illegalInst_cboI_0;
  assign io_toDecode_virtualInst_sfenceVMA  = isModeVS & _hstatus_regOut_VTVM | isModeVU;
  assign io_toDecode_virtualInst_sfencePart = isModeVU;
  assign io_toDecode_virtualInst_hfence = io_toDecode_virtualInst_hlsv_0;
  assign io_toDecode_virtualInst_hlsv   = io_toDecode_virtualInst_hlsv_0;
  assign io_toDecode_virtualInst_wfi =
    isModeVS & ~_mstatus_regOut_TW & _hstatus_regOut_VTW | isModeVU & ~_mstatus_regOut_TW;
  assign io_toDecode_virtualInst_wrs_nto = V & ~_mstatus_regOut_TW & _hstatus_regOut_VTW;
  assign io_toDecode_virtualInst_cboZ =
    _menvcfg_regOut_CBZE
    & (isModeVS & ~_henvcfg_regOut_CBZE | isModeVU
       & ~(_henvcfg_regOut_CBZE & _senvcfg_regOut_CBZE));
  assign io_toDecode_virtualInst_cboCF =
    _menvcfg_regOut_CBCFE
    & (isModeVS & ~_henvcfg_regOut_CBCFE | isModeVU
       & ~(_henvcfg_regOut_CBCFE & _senvcfg_regOut_CBCFE));
  assign io_toDecode_virtualInst_cboI   = io_toDecode_virtualInst_cboI_0;
  assign io_toDecode_special_cboI2F =
    ~io_toDecode_illegalInst_cboI_0 & ~io_toDecode_virtualInst_cboI_0
    & (_menvcfg_regOut_CBIE == 2'h1 & ~isModeM | _senvcfg_regOut_CBIE == 2'h1
       & (isModeHU | isModeVU) | _henvcfg_regOut_CBIE == 2'h1
       & io_toDecode_virtualInst_hlsv_0);
  // 步3：分发给各 CSR 子模块的写合法位 = 打拍写合法 & 非译码非法（golden 14232）。
  assign io_distributedWenLegal = wenLegalReg_last_REG & ~noCSRIllegalReg;
  // toAIA_addr_* / toAIA_vgein 在步2 FSM 块驱动。
  // toAIA_wdata_* / toAIA_mClaim/sClaim/vsClaim 在步2 FSM 块驱动。
  // 步3：致命错误对外报告，criticalErrorStateInCSR 经两级打拍（golden 5895-5896/14257）。
  assign io_error_0 = io_error_0_REG_1;

  // ====== 341 子模块实例（机械互联，黑盒）======
  `include "newcsr_inst.svh"
endmodule
