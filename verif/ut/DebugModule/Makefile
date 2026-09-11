MODULE = DebugModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/DebugModule.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/AsyncQueueSink.sv \
                  $(GOLDEN_RTL)/AsyncQueueSink_1.sv \
                  $(GOLDEN_RTL)/AsyncQueueSink_2.sv \
                  $(GOLDEN_RTL)/AsyncQueueSource.sv \
                  $(GOLDEN_RTL)/AsyncQueueSource_1.sv \
                  $(GOLDEN_RTL)/AsyncQueueSource_2.sv \
                  $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv \
                  $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                  $(GOLDEN_RTL)/CaptureChain.sv \
                  $(GOLDEN_RTL)/CaptureUpdateChain.sv \
                  $(GOLDEN_RTL)/CaptureUpdateChain_1.sv \
                  $(GOLDEN_RTL)/CaptureUpdateChain_2.sv \
                  $(GOLDEN_RTL)/ClockCrossingReg_w15.sv \
                  $(GOLDEN_RTL)/ClockCrossingReg_w44.sv \
                  $(GOLDEN_RTL)/ClockCrossingReg_w56.sv \
                  $(GOLDEN_RTL)/DMIToTL.sv \
                  $(GOLDEN_RTL)/DebugTransportModuleJTAG.sv \
                  $(GOLDEN_RTL)/JtagBypassChain.sv \
                  $(GOLDEN_RTL)/JtagStateMachine.sv \
                  $(GOLDEN_RTL)/JtagTapController.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_2.sv \
                  $(GOLDEN_RTL)/SBToTL.sv \
                  $(GOLDEN_RTL)/TLAsyncCrossingSink.sv \
                  $(GOLDEN_RTL)/TLAsyncCrossingSource.sv \
                  $(GOLDEN_RTL)/TLBusBypass.sv \
                  $(GOLDEN_RTL)/TLBusBypassBar.sv \
                  $(GOLDEN_RTL)/TLDebugModule.sv \
                  $(GOLDEN_RTL)/TLDebugModuleInner.sv \
                  $(GOLDEN_RTL)/TLDebugModuleInnerAsync.sv \
                  $(GOLDEN_RTL)/TLDebugModuleOuter.sv \
                  $(GOLDEN_RTL)/TLDebugModuleOuterAsync.sv \
                  $(GOLDEN_RTL)/TLError_1.sv \
                  $(GOLDEN_RTL)/TLXbar_3.sv \
                  $(GOLDEN_RTL)/ram_2x66.sv

FM_REF_DEPS_DebugModule = AsyncQueueSink.sv AsyncQueueSink_1.sv AsyncQueueSink_2.sv    AsyncQueueSource.sv AsyncQueueSource_1.sv AsyncQueueSource_2.sv    AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv    AsyncResetSynchronizerShiftReg_w1_d3_i0.sv    CaptureChain.sv CaptureUpdateChain.sv CaptureUpdateChain_1.sv    CaptureUpdateChain_2.sv    ClockCrossingReg_w15.sv ClockCrossingReg_w44.sv ClockCrossingReg_w56.sv    DMIToTL.sv DebugTransportModuleJTAG.sv    JtagBypassChain.sv JtagStateMachine.sv JtagTapController.sv    Queue2_TLBundleD_2.sv SBToTL.sv    TLAsyncCrossingSink.sv TLAsyncCrossingSource.sv    TLBusBypass.sv TLBusBypassBar.sv    TLDebugModule.sv TLDebugModuleInner.sv TLDebugModuleInnerAsync.sv    TLDebugModuleOuter.sv TLDebugModuleOuterAsync.sv    TLError_1.sv TLXbar_3.sv ram_2x66.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/DebugModule.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = DebugModule

include ../../../scripts/ut_common.mk

# golden 子块含非综合断言/firtool 随机初始化; UT 关随机化并按 initreg+0 初始化,
# 双时钟域 + 异步跨域队列在两实例间确定性演化。
VCS += +define+SYNTHESIS
VCS += +vcs+initreg+random
VCS += -assert disable
VCS += +libext+.sv+.v
VCS += -f golden_filelist.f
SIM_ARGS += +vcs+initreg+0
