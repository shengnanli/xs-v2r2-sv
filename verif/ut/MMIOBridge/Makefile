MODULE = MMIOBridge

# MMIOBridge：L2 的 TileLink→CHI MMIO 桥（手写胶合核 xs_MMIOBridge_core + 生成的 golden 同名 wrapper）。
# child 全部 PROVEN_DIRECT，两侧白盒：ref 读 golden，impl 读本仓重写件：
#   MMIOBridgeEntry / _2 / _4 / _8（xs_MMIOBridgeEntry_core）、Arbiter16_CHIDAT / Arbiter16_TLBundleD
#   （xs_FixedPriorityArbiter_core）、RRArbiterInit_13（RRArbiterInit.sv 家族核）。0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/MMIOBridge.sv \
           $(RTL_DIR)/uncore/xs_MMIOBridgeEntry_core.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry.sv $(RTL_DIR)/uncore/MMIOBridgeEntry_2.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry_4.sv $(RTL_DIR)/uncore/MMIOBridgeEntry_8.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/uncore/Arbiter16_CHIDAT.sv \
           $(RTL_DIR)/uncore/Arbiter16_TLBundleD.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_13.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MMIOBridge.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry.sv $(GOLDEN_RTL)/MMIOBridgeEntry_2.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry_4.sv $(GOLDEN_RTL)/MMIOBridgeEntry_8.sv \
              $(GOLDEN_RTL)/Arbiter16_CHIDAT.sv $(GOLDEN_RTL)/Arbiter16_TLBundleD.sv \
              $(GOLDEN_RTL)/RRArbiterInit_13.sv
FM_VARIANTS = MMIOBridge
FM_REF_DEPS_MMIOBridge = MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv MMIOBridgeEntry_8.sv \
                         Arbiter16_CHIDAT.sv Arbiter16_TLBundleD.sv RRArbiterInit_13.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
