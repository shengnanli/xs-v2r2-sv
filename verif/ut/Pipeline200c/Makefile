MODULE = Pipeline200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/Arbiter16_TLBundleD.sv \
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
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
VCS_ARCH_OVERRIDE := linux
