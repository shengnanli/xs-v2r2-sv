MODULE = NewCSR

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_NewCSR_core（CSR 地址译码/写fanout/读mux/特权态机/trap仲裁/输出mux/副作用，
# 用 newcsr_pkg 的 enum/struct/function/genvar 表达）+ pkg + 机械互联 svh。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_pkg.sv \
               $(RTL_DIR)/backend/NewCSR.sv
# FM impl 侧顶层 wrapper（golden 同名 NewCSR，透传到可读核）。
WRAPPER_SRCS = $(RTL_DIR)/backend/NewCSR_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# golden NewCSR.sv 例化 309 子模块类型；UT 双例化仍用黑盒 stub 隔离字段子模块（两侧共用）。
# 父层官方 FM 门（fmbb→fm_eq_parent.tcl）**不**用 stub：全部字段模块两侧 elaborate。
GOLDEN_SRCS  = $(GOLDEN_RTL)/NewCSR.sv $(RTL_DIR)/backend/newcsr_stub.sv

FM_VARIANTS  = NewCSR
FM_REF_DEPS_NewCSR = ../../rtl/backend/newcsr_stub.sv

# ============================================================================
# NewCSR 父层官方 FM 装配证明的源闭包（诚实的 both-sides elaborate，非黑盒占位）。
#   REF  = golden NewCSR.sv + 全部 golden 字段模块闭包（NEWCSR_GOLDEN_DEPS），
#          13 个 DPI 包装（DummyDPICWrapper_12..23 + CommitIDModule，无可综合体）
#          保持 unresolved 黑盒。
#   IMPL = newcsr_pkg + NewCSR_wrapper + 可读核 NewCSR.sv + 全部 impl 字段模块
#          （NEWCSR_IMPL_BACKEND，含 xs_* 可读核）+ 复用的 golden 叶子模块
#          （NEWCSR_IMPL_REUSE：6 个 *PermitModule，golden 纯逻辑叶子两侧同读）。
#   impl 的 DelayN_17/210 由 newcsr_intrfilter_prims.sv 提供（impl 侧实现，
#          非 golden），故 IMPL_REUSE 不含 golden DelayN。
# ============================================================================
NEWCSR_GOLDEN_DEPS = \
    $(GOLDEN_RTL)/CSRPermitModule.sv \
    $(GOLDEN_RTL)/cycleModule.sv \
    $(GOLDEN_RTL)/DcsrModule.sv \
    $(GOLDEN_RTL)/Debug.sv \
    $(GOLDEN_RTL)/DelayN_17.sv \
    $(GOLDEN_RTL)/DelayN_210.sv \
    $(GOLDEN_RTL)/DelayReg_11.sv \
    $(GOLDEN_RTL)/DelayReg_12.sv \
    $(GOLDEN_RTL)/DpcModule.sv \
    $(GOLDEN_RTL)/DretEventModule.sv \
    $(GOLDEN_RTL)/Dscratch0Module.sv \
    $(GOLDEN_RTL)/Dscratch1Module.sv \
    $(GOLDEN_RTL)/FcsrModule.sv \
    $(GOLDEN_RTL)/HcontextModule.sv \
    $(GOLDEN_RTL)/HcounterenModule.sv \
    $(GOLDEN_RTL)/HedelegModule.sv \
    $(GOLDEN_RTL)/HenvcfgModule.sv \
    $(GOLDEN_RTL)/HgatpModule.sv \
    $(GOLDEN_RTL)/HgeieModule.sv \
    $(GOLDEN_RTL)/HgeipModule.sv \
    $(GOLDEN_RTL)/HidelegModule.sv \
    $(GOLDEN_RTL)/HieModule.sv \
    $(GOLDEN_RTL)/HipModule.sv \
    $(GOLDEN_RTL)/HPerfCounter_8.sv \
    $(GOLDEN_RTL)/HPerfMonitor_1.sv \
    $(GOLDEN_RTL)/Hpmcounter10Module.sv \
    $(GOLDEN_RTL)/Hpmcounter11Module.sv \
    $(GOLDEN_RTL)/Hpmcounter12Module.sv \
    $(GOLDEN_RTL)/Hpmcounter13Module.sv \
    $(GOLDEN_RTL)/Hpmcounter14Module.sv \
    $(GOLDEN_RTL)/Hpmcounter15Module.sv \
    $(GOLDEN_RTL)/Hpmcounter16Module.sv \
    $(GOLDEN_RTL)/Hpmcounter17Module.sv \
    $(GOLDEN_RTL)/Hpmcounter18Module.sv \
    $(GOLDEN_RTL)/Hpmcounter19Module.sv \
    $(GOLDEN_RTL)/Hpmcounter20Module.sv \
    $(GOLDEN_RTL)/Hpmcounter21Module.sv \
    $(GOLDEN_RTL)/Hpmcounter22Module.sv \
    $(GOLDEN_RTL)/Hpmcounter23Module.sv \
    $(GOLDEN_RTL)/Hpmcounter24Module.sv \
    $(GOLDEN_RTL)/Hpmcounter25Module.sv \
    $(GOLDEN_RTL)/Hpmcounter26Module.sv \
    $(GOLDEN_RTL)/Hpmcounter27Module.sv \
    $(GOLDEN_RTL)/Hpmcounter28Module.sv \
    $(GOLDEN_RTL)/Hpmcounter29Module.sv \
    $(GOLDEN_RTL)/Hpmcounter30Module.sv \
    $(GOLDEN_RTL)/Hpmcounter31Module.sv \
    $(GOLDEN_RTL)/Hpmcounter3Module.sv \
    $(GOLDEN_RTL)/Hpmcounter4Module.sv \
    $(GOLDEN_RTL)/Hpmcounter5Module.sv \
    $(GOLDEN_RTL)/Hpmcounter6Module.sv \
    $(GOLDEN_RTL)/Hpmcounter7Module.sv \
    $(GOLDEN_RTL)/Hpmcounter8Module.sv \
    $(GOLDEN_RTL)/Hpmcounter9Module.sv \
    $(GOLDEN_RTL)/Hstateen0Module.sv \
    $(GOLDEN_RTL)/Hstateen1Module.sv \
    $(GOLDEN_RTL)/Hstateen2Module.sv \
    $(GOLDEN_RTL)/Hstateen3Module.sv \
    $(GOLDEN_RTL)/HstatusModule.sv \
    $(GOLDEN_RTL)/HtimedeltaModule.sv \
    $(GOLDEN_RTL)/HtinstModule.sv \
    $(GOLDEN_RTL)/HtvalModule.sv \
    $(GOLDEN_RTL)/HvictlModule.sv \
    $(GOLDEN_RTL)/HvienModule.sv \
    $(GOLDEN_RTL)/HvipModule.sv \
    $(GOLDEN_RTL)/Hviprio1Module.sv \
    $(GOLDEN_RTL)/Hviprio2Module.sv \
    $(GOLDEN_RTL)/IndirectCSRPermitModule.sv \
    $(GOLDEN_RTL)/instretModule.sv \
    $(GOLDEN_RTL)/InterruptFilter.sv \
    $(GOLDEN_RTL)/Iprio0Module_1.sv \
    $(GOLDEN_RTL)/Iprio0Module.sv \
    $(GOLDEN_RTL)/Iprio10Module_1.sv \
    $(GOLDEN_RTL)/Iprio10Module.sv \
    $(GOLDEN_RTL)/Iprio12Module_1.sv \
    $(GOLDEN_RTL)/Iprio12Module.sv \
    $(GOLDEN_RTL)/Iprio14Module_1.sv \
    $(GOLDEN_RTL)/Iprio14Module.sv \
    $(GOLDEN_RTL)/Iprio2Module_1.sv \
    $(GOLDEN_RTL)/Iprio2Module.sv \
    $(GOLDEN_RTL)/Iprio4Module_1.sv \
    $(GOLDEN_RTL)/Iprio4Module.sv \
    $(GOLDEN_RTL)/Iprio6Module_1.sv \
    $(GOLDEN_RTL)/Iprio6Module.sv \
    $(GOLDEN_RTL)/Iprio8Module_1.sv \
    $(GOLDEN_RTL)/Iprio8Module.sv \
    $(GOLDEN_RTL)/McauseModule.sv \
    $(GOLDEN_RTL)/MconfigptrModule.sv \
    $(GOLDEN_RTL)/McontextModule.sv \
    $(GOLDEN_RTL)/McorepwrModule.sv \
    $(GOLDEN_RTL)/McounterenModule.sv \
    $(GOLDEN_RTL)/McountinhibitModule.sv \
    $(GOLDEN_RTL)/McycleModule.sv \
    $(GOLDEN_RTL)/MedelegModule.sv \
    $(GOLDEN_RTL)/MenvcfgModule.sv \
    $(GOLDEN_RTL)/MepcModule.sv \
    $(GOLDEN_RTL)/MflushpwrModule.sv \
    $(GOLDEN_RTL)/MhartidModule.sv \
    $(GOLDEN_RTL)/Mhpmcounter10Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter11Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter12Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter13Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter14Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter15Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter16Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter17Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter18Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter19Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter20Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter21Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter22Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter23Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter24Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter25Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter26Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter27Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter28Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter29Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter30Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter31Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter3Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter4Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter5Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter6Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter7Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter8Module.sv \
    $(GOLDEN_RTL)/Mhpmcounter9Module.sv \
    $(GOLDEN_RTL)/MhpmeventModule.sv \
    $(GOLDEN_RTL)/MidelegModule.sv \
    $(GOLDEN_RTL)/MieModule.sv \
    $(GOLDEN_RTL)/MinstretModule.sv \
    $(GOLDEN_RTL)/MipModule.sv \
    $(GOLDEN_RTL)/Mireg2Module.sv \
    $(GOLDEN_RTL)/Mireg3Module.sv \
    $(GOLDEN_RTL)/Mireg4Module.sv \
    $(GOLDEN_RTL)/Mireg5Module.sv \
    $(GOLDEN_RTL)/Mireg6Module.sv \
    $(GOLDEN_RTL)/MiregModule.sv \
    $(GOLDEN_RTL)/MiselectModule.sv \
    $(GOLDEN_RTL)/MLevelPermitModule.sv \
    $(GOLDEN_RTL)/MncauseModule.sv \
    $(GOLDEN_RTL)/MnepcModule.sv \
    $(GOLDEN_RTL)/MNretEventModule.sv \
    $(GOLDEN_RTL)/MnscratchModule.sv \
    $(GOLDEN_RTL)/MnstatusModule.sv \
    $(GOLDEN_RTL)/MretEventModule.sv \
    $(GOLDEN_RTL)/MscratchModule.sv \
    $(GOLDEN_RTL)/MseccfgModule.sv \
    $(GOLDEN_RTL)/Mstateen0Module.sv \
    $(GOLDEN_RTL)/Mstateen1Module.sv \
    $(GOLDEN_RTL)/Mstateen2Module.sv \
    $(GOLDEN_RTL)/Mstateen3Module.sv \
    $(GOLDEN_RTL)/MStatusModule.sv \
    $(GOLDEN_RTL)/MtinstModule.sv \
    $(GOLDEN_RTL)/MtopeiModule.sv \
    $(GOLDEN_RTL)/MtopiModule.sv \
    $(GOLDEN_RTL)/Mtval2Module.sv \
    $(GOLDEN_RTL)/MtvalModule.sv \
    $(GOLDEN_RTL)/MtvecModule.sv \
    $(GOLDEN_RTL)/MvendoridModule.sv \
    $(GOLDEN_RTL)/MvienModule.sv \
    $(GOLDEN_RTL)/MvipModule.sv \
    $(GOLDEN_RTL)/Pma0cfgModule.sv \
    $(GOLDEN_RTL)/Pma10cfgModule.sv \
    $(GOLDEN_RTL)/Pma11cfgModule.sv \
    $(GOLDEN_RTL)/Pma12cfgModule.sv \
    $(GOLDEN_RTL)/Pma13cfgModule.sv \
    $(GOLDEN_RTL)/Pma14cfgModule.sv \
    $(GOLDEN_RTL)/Pma15cfgModule.sv \
    $(GOLDEN_RTL)/Pma1cfgModule.sv \
    $(GOLDEN_RTL)/Pma2cfgModule.sv \
    $(GOLDEN_RTL)/Pma3cfgModule.sv \
    $(GOLDEN_RTL)/Pma4cfgModule.sv \
    $(GOLDEN_RTL)/Pma5cfgModule.sv \
    $(GOLDEN_RTL)/Pma6cfgModule.sv \
    $(GOLDEN_RTL)/Pma7cfgModule.sv \
    $(GOLDEN_RTL)/Pma8cfgModule.sv \
    $(GOLDEN_RTL)/Pma9cfgModule.sv \
    $(GOLDEN_RTL)/Pmaaddr0Module.sv \
    $(GOLDEN_RTL)/Pmaaddr10Module.sv \
    $(GOLDEN_RTL)/Pmaaddr11Module.sv \
    $(GOLDEN_RTL)/Pmaaddr12Module.sv \
    $(GOLDEN_RTL)/Pmaaddr13Module.sv \
    $(GOLDEN_RTL)/Pmaaddr14Module.sv \
    $(GOLDEN_RTL)/Pmaaddr15Module.sv \
    $(GOLDEN_RTL)/Pmaaddr1Module.sv \
    $(GOLDEN_RTL)/Pmaaddr2Module.sv \
    $(GOLDEN_RTL)/Pmaaddr3Module.sv \
    $(GOLDEN_RTL)/Pmaaddr4Module.sv \
    $(GOLDEN_RTL)/Pmaaddr5Module.sv \
    $(GOLDEN_RTL)/Pmaaddr6Module.sv \
    $(GOLDEN_RTL)/Pmaaddr7Module.sv \
    $(GOLDEN_RTL)/Pmaaddr8Module.sv \
    $(GOLDEN_RTL)/Pmaaddr9Module.sv \
    $(GOLDEN_RTL)/Pmacfg0Module.sv \
    $(GOLDEN_RTL)/Pmacfg2Module.sv \
    $(GOLDEN_RTL)/PMAEntryHandleModule.sv \
    $(GOLDEN_RTL)/Pmp0cfgModule.sv \
    $(GOLDEN_RTL)/Pmp10cfgModule.sv \
    $(GOLDEN_RTL)/Pmp11cfgModule.sv \
    $(GOLDEN_RTL)/Pmp12cfgModule.sv \
    $(GOLDEN_RTL)/Pmp13cfgModule.sv \
    $(GOLDEN_RTL)/Pmp14cfgModule.sv \
    $(GOLDEN_RTL)/Pmp15cfgModule.sv \
    $(GOLDEN_RTL)/Pmp1cfgModule.sv \
    $(GOLDEN_RTL)/Pmp2cfgModule.sv \
    $(GOLDEN_RTL)/Pmp3cfgModule.sv \
    $(GOLDEN_RTL)/Pmp4cfgModule.sv \
    $(GOLDEN_RTL)/Pmp5cfgModule.sv \
    $(GOLDEN_RTL)/Pmp6cfgModule.sv \
    $(GOLDEN_RTL)/Pmp7cfgModule.sv \
    $(GOLDEN_RTL)/Pmp8cfgModule.sv \
    $(GOLDEN_RTL)/Pmp9cfgModule.sv \
    $(GOLDEN_RTL)/Pmpaddr0Module.sv \
    $(GOLDEN_RTL)/Pmpaddr10Module.sv \
    $(GOLDEN_RTL)/Pmpaddr11Module.sv \
    $(GOLDEN_RTL)/Pmpaddr12Module.sv \
    $(GOLDEN_RTL)/Pmpaddr13Module.sv \
    $(GOLDEN_RTL)/Pmpaddr14Module.sv \
    $(GOLDEN_RTL)/Pmpaddr15Module.sv \
    $(GOLDEN_RTL)/Pmpaddr1Module.sv \
    $(GOLDEN_RTL)/Pmpaddr2Module.sv \
    $(GOLDEN_RTL)/Pmpaddr3Module.sv \
    $(GOLDEN_RTL)/Pmpaddr4Module.sv \
    $(GOLDEN_RTL)/Pmpaddr5Module.sv \
    $(GOLDEN_RTL)/Pmpaddr6Module.sv \
    $(GOLDEN_RTL)/Pmpaddr7Module.sv \
    $(GOLDEN_RTL)/Pmpaddr8Module.sv \
    $(GOLDEN_RTL)/Pmpaddr9Module.sv \
    $(GOLDEN_RTL)/Pmpcfg0Module.sv \
    $(GOLDEN_RTL)/Pmpcfg2Module.sv \
    $(GOLDEN_RTL)/PMPEntryHandleModule.sv \
    $(GOLDEN_RTL)/PrivilegePermitModule.sv \
    $(GOLDEN_RTL)/SatpModule.sv \
    $(GOLDEN_RTL)/SbpctlModule.sv \
    $(GOLDEN_RTL)/ScauseModule.sv \
    $(GOLDEN_RTL)/ScontextModule.sv \
    $(GOLDEN_RTL)/ScounterenModule.sv \
    $(GOLDEN_RTL)/ScountovfModule.sv \
    $(GOLDEN_RTL)/SenvcfgModule.sv \
    $(GOLDEN_RTL)/SepcModule.sv \
    $(GOLDEN_RTL)/SieModule.sv \
    $(GOLDEN_RTL)/SipModule.sv \
    $(GOLDEN_RTL)/Sireg2Module.sv \
    $(GOLDEN_RTL)/Sireg3Module.sv \
    $(GOLDEN_RTL)/Sireg4Module.sv \
    $(GOLDEN_RTL)/Sireg5Module.sv \
    $(GOLDEN_RTL)/Sireg6Module.sv \
    $(GOLDEN_RTL)/SiregModule.sv \
    $(GOLDEN_RTL)/SiselectModule.sv \
    $(GOLDEN_RTL)/SLevelPermitModule.sv \
    $(GOLDEN_RTL)/SlvpredctlModule.sv \
    $(GOLDEN_RTL)/SmblockctlModule.sv \
    $(GOLDEN_RTL)/SpfctlModule.sv \
    $(GOLDEN_RTL)/SretEventModule.sv \
    $(GOLDEN_RTL)/SrnctlModule.sv \
    $(GOLDEN_RTL)/SscratchModule.sv \
    $(GOLDEN_RTL)/Sstateen0Module.sv \
    $(GOLDEN_RTL)/Sstateen1Module.sv \
    $(GOLDEN_RTL)/Sstateen2Module.sv \
    $(GOLDEN_RTL)/Sstateen3Module.sv \
    $(GOLDEN_RTL)/SstcInterruptGen.sv \
    $(GOLDEN_RTL)/StimecmpModule.sv \
    $(GOLDEN_RTL)/StopeiModule.sv \
    $(GOLDEN_RTL)/StopiModule.sv \
    $(GOLDEN_RTL)/StvalModule.sv \
    $(GOLDEN_RTL)/StvecModule.sv \
    $(GOLDEN_RTL)/Tdata1Module.sv \
    $(GOLDEN_RTL)/Tdata2Module.sv \
    $(GOLDEN_RTL)/timeModule.sv \
    $(GOLDEN_RTL)/TrapEntryDEventModule.sv \
    $(GOLDEN_RTL)/TrapEntryHSEventModule.sv \
    $(GOLDEN_RTL)/TrapEntryMEventModule.sv \
    $(GOLDEN_RTL)/TrapEntryMNEventModule.sv \
    $(GOLDEN_RTL)/TrapEntryVSEventModule.sv \
    $(GOLDEN_RTL)/TrapHandleModule.sv \
    $(GOLDEN_RTL)/Trigger0_Tdata1Module.sv \
    $(GOLDEN_RTL)/Trigger0_Tdata2Module.sv \
    $(GOLDEN_RTL)/Trigger1_Tdata1Module.sv \
    $(GOLDEN_RTL)/Trigger1_Tdata2Module.sv \
    $(GOLDEN_RTL)/Trigger2_Tdata1Module.sv \
    $(GOLDEN_RTL)/Trigger2_Tdata2Module.sv \
    $(GOLDEN_RTL)/Trigger3_Tdata1Module.sv \
    $(GOLDEN_RTL)/Trigger3_Tdata2Module.sv \
    $(GOLDEN_RTL)/TselectModule.sv \
    $(GOLDEN_RTL)/VcsrModule.sv \
    $(GOLDEN_RTL)/VirtualLevelPermitModule.sv \
    $(GOLDEN_RTL)/VSatpModule.sv \
    $(GOLDEN_RTL)/VScauseModule.sv \
    $(GOLDEN_RTL)/VSepcModule.sv \
    $(GOLDEN_RTL)/VSieModule.sv \
    $(GOLDEN_RTL)/VSipModule.sv \
    $(GOLDEN_RTL)/VSireg2Module.sv \
    $(GOLDEN_RTL)/VSireg3Module.sv \
    $(GOLDEN_RTL)/VSireg4Module.sv \
    $(GOLDEN_RTL)/VSireg5Module.sv \
    $(GOLDEN_RTL)/VSireg6Module.sv \
    $(GOLDEN_RTL)/VSiregModule.sv \
    $(GOLDEN_RTL)/VSiselectModule.sv \
    $(GOLDEN_RTL)/VSscratchModule.sv \
    $(GOLDEN_RTL)/VSstatusModule.sv \
    $(GOLDEN_RTL)/VstartModule.sv \
    $(GOLDEN_RTL)/VStimecmpModule.sv \
    $(GOLDEN_RTL)/VStopeiModule.sv \
    $(GOLDEN_RTL)/VStopiModule.sv \
    $(GOLDEN_RTL)/VStvalModule.sv \
    $(GOLDEN_RTL)/VStvecModule.sv \
    $(GOLDEN_RTL)/VtypeModule.sv \
    $(GOLDEN_RTL)/XRetPermitModule.sv

NEWCSR_IMPL_BACKEND = \
    $(RTL_DIR)/backend/InterruptFilter.sv \
    $(RTL_DIR)/backend/newcsr_atp_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_cause.sv \
    $(RTL_DIR)/backend/newcsr_cause_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_const_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_context_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_counteren.sv \
    $(RTL_DIR)/backend/newcsr_counteren_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_counter.sv \
    $(RTL_DIR)/backend/newcsr_counter_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_dcsr_hstatus.sv \
    $(RTL_DIR)/backend/newcsr_debug.sv \
    $(RTL_DIR)/backend/newcsr_epc.sv \
    $(RTL_DIR)/backend/newcsr_epc_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_event_batch.sv \
    $(RTL_DIR)/backend/newcsr_fcsr_mnstatus.sv \
    $(RTL_DIR)/backend/newcsr_hedeleg.sv \
    $(RTL_DIR)/backend/newcsr_hedeleg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_hideleg.sv \
    $(RTL_DIR)/backend/newcsr_hideleg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_hperfmon.sv \
    $(RTL_DIR)/backend/newcsr_hpmcounter.sv \
    $(RTL_DIR)/backend/newcsr_hpmcounter_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_ie_ip_batch.sv \
    $(RTL_DIR)/backend/newcsr_indireg.sv \
    $(RTL_DIR)/backend/newcsr_indireg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_intrfilter_prims.sv \
    $(RTL_DIR)/backend/newcsr_iprio.sv \
    $(RTL_DIR)/backend/newcsr_iprio_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_iselect.sv \
    $(RTL_DIR)/backend/newcsr_iselect_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_medeleg.sv \
    $(RTL_DIR)/backend/newcsr_medeleg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_mhpmcounter.sv \
    $(RTL_DIR)/backend/newcsr_mhpmcounter_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_mideleg.sv \
    $(RTL_DIR)/backend/newcsr_mideleg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_mip.sv \
    $(RTL_DIR)/backend/newcsr_mip_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_mstatus_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_permit_mhpmevent.sv \
    $(RTL_DIR)/backend/newcsr_pma.sv \
    $(RTL_DIR)/backend/newcsr_pma_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_pmpaddr.sv \
    $(RTL_DIR)/backend/newcsr_pmpaddr_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_pmpcfg.sv \
    $(RTL_DIR)/backend/newcsr_pmpcfg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_pmpentrycfg.sv \
    $(RTL_DIR)/backend/newcsr_pmpentrycfg_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_pmp_pma_entryhandle.sv \
    $(RTL_DIR)/backend/newcsr_scratch.sv \
    $(RTL_DIR)/backend/newcsr_scratch_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_simplereg_batch1.sv \
    $(RTL_DIR)/backend/newcsr_simplereg_batch2.sv \
    $(RTL_DIR)/backend/newcsr_sip_sie_batch.sv \
    $(RTL_DIR)/backend/newcsr_sstc_delayreg.sv \
    $(RTL_DIR)/backend/newcsr_stateen.sv \
    $(RTL_DIR)/backend/newcsr_stateen_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_topi.sv \
    $(RTL_DIR)/backend/newcsr_topi_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_traphandle.sv \
    $(RTL_DIR)/backend/newcsr_trigger.sv \
    $(RTL_DIR)/backend/newcsr_trigger_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_tval.sv \
    $(RTL_DIR)/backend/newcsr_tval_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_tvec.sv \
    $(RTL_DIR)/backend/newcsr_tvec_wrappers.sv \
    $(RTL_DIR)/backend/newcsr_vsstatus_wrappers.sv

NEWCSR_IMPL_REUSE = \
    $(GOLDEN_RTL)/IndirectCSRPermitModule.sv \
    $(GOLDEN_RTL)/MLevelPermitModule.sv \
    $(GOLDEN_RTL)/PrivilegePermitModule.sv \
    $(GOLDEN_RTL)/SLevelPermitModule.sv \
    $(GOLDEN_RTL)/VirtualLevelPermitModule.sv \
    $(GOLDEN_RTL)/XRetPermitModule.sv

include ../../../scripts/ut_common.mk

VCS += +incdir+$(RTL_DIR)/backend
VCS += +define+SYNTHESIS

# ----------------------------------------------------------------------------
# 父层官方 FM 门（fmbb）：读入全部字段模块两侧闭包，逐位比较字段逻辑；仅 13 个 DPI
# 包装 unresolved 黑盒（两侧同名同签名自动配对，声明于 allow/NewCSR.json）。
# ----------------------------------------------------------------------------
.PHONY: fmbb
fmbb:
	@[ -n "$$FM_SIDECAR_OUT" ] || { echo "ERROR($(MODULE)): fmbb 须经 sidecar runner"; exit 1; }
	@mkdir -p fm_work/NewCSR
	@echo "=== FM(parent-assembly): NewCSR ==="
	FM_TOP=NewCSR \
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/NewCSR.sv $(NEWCSR_GOLDEN_DEPS))" \
	FM_IMPL_SRCS="$(abspath $(RTL_DIR)/backend/newcsr_pkg.sv $(RTL_DIR)/backend/NewCSR_wrapper.sv $(RTL_DIR)/backend/NewCSR.sv $(NEWCSR_IMPL_BACKEND) $(NEWCSR_IMPL_REUSE))" \
	FM_MERGE_DUP=false \
	$(if $(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=$(FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS),) \
	XSSV_HOME=$(XSSV_HOME) FM_RUN_ID=$$FM_RUN_ID \
	fm_shell -64 -work_path fm_work/NewCSR -file $(abspath fm_eq_parent.tcl) \
	    > fm_work/NewCSR/fm.log 2>&1; \
	rc=$$?; echo $$rc > "$$FM_SIDECAR_OUT/fm_shell.rc"; \
	grep -E "^FM_RESULT" fm_work/NewCSR/fm.log || true
