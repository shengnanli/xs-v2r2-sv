MODULE = Pipeline200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/common/xs_OverrideableQueue_core.sv \
           $(RTL_DIR)/uncore/Arbiter16_TLBundleD.sv \
           $(RTL_DIR)/frontend/Arbiter3_PfGenReq.sv \
           $(RTL_DIR)/frontend/Arbiter4_L2ToL1Hint.sv \
           $(RTL_DIR)/frontend/Arbiter4_PrefetchReq.sv \
           $(RTL_DIR)/backend/CSA4to2_15.sv \
           $(RTL_DIR)/frontend/MbistIntfFrontend.sv \
           $(RTL_DIR)/memblock/MbistIntfMemBlk.sv \
           $(RTL_DIR)/backend/NfMappedElemIdx.sv \
           $(RTL_DIR)/frontend/OverrideableQueue.sv \
           $(RTL_DIR)/frontend/OverrideableQueue_1.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_6.sv \
           $(RTL_DIR)/mmu/SatpFlushMod.sv
TB_SRCS = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter16_TLBundleD.sv \
              $(GOLDEN_RTL)/Arbiter3_PfGenReq.sv \
              $(GOLDEN_RTL)/Arbiter4_L2ToL1Hint.sv \
              $(GOLDEN_RTL)/Arbiter4_PrefetchReq.sv \
              $(GOLDEN_RTL)/CSA4to2_15.sv \
              $(GOLDEN_RTL)/MbistIntfFrontend.sv \
              $(GOLDEN_RTL)/MbistIntfMemBlk.sv \
              $(GOLDEN_RTL)/NfMappedElemIdx.sv \
              $(GOLDEN_RTL)/OverrideableQueue.sv \
              $(GOLDEN_RTL)/OverrideableQueue_1.sv \
              $(GOLDEN_RTL)/PipelineRegModule_6.sv \
              $(GOLDEN_RTL)/SatpFlushMod.sv
FM_VARIANTS = Arbiter16_TLBundleD Arbiter3_PfGenReq Arbiter4_L2ToL1Hint Arbiter4_PrefetchReq CSA4to2_15 MbistIntfFrontend MbistIntfMemBlk NfMappedElemIdx OverrideableQueue OverrideableQueue_1 PipelineRegModule_6 SatpFlushMod
PORTLINT_ORDER = fail
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用（加强，不是放宽）。
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
INITREG ?= 0
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
VCS_ARCH_OVERRIDE := linux
