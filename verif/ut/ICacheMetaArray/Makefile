MODULE = ICacheMetaArray

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheMetaArray.sv
TB_SRCS = tb.sv

FM_REF_DEPS_ICacheMetaArray = 
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMetaArray.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate.sv \
              $(GOLDEN_RTL)/SRAMTemplate_2.sv \
              $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
              $(GOLDEN_RTL)/array.sv \
              $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheTag.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = mbistPl, tagArrays_0, tagArrays_1
FM_MODE = assembly
FM_ALLOWLIST ?= 3
FM_VARIANTS = ICacheMetaArray

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 的随机初始化/断言；UT 与 FM 均定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
