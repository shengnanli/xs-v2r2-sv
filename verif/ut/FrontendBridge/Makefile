# 由 tools/kimi_lane.py 按模板生成（KIMI 只提供源清单）
MODULE = FrontendBridge
RTL_SRCS = $(addprefix ../../../,rtl/common/xs_ChiselQueue_core.sv rtl/uncore/Queue2_TLBundleA_8.sv rtl/uncore/Queue2_TLBundleD_7.sv rtl/uncore/Queue2_TLBundleA_12.sv rtl/uncore/Queue2_TLBundleD_13.sv rtl/uncore/Queue2_TLBundleA_10.sv rtl/uncore/Queue2_TLBundleD_11.sv rtl/memblock/ICacheBuffer.sv rtl/memblock/InstrUncacheBuffer.sv rtl/memblock/ICacheCtrlBuffer.sv rtl/memblock/FrontendBridge.sv)
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,ram_2x117.sv ram_2x133.sv ram_2x281.sv ram_2x359.sv ram_2x76.sv ram_2x80.sv)
TB_SRCS  = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,FrontendBridge.sv ICacheBuffer.sv ICacheCtrlBuffer.sv InstrUncacheBuffer.sv Queue2_TLBundleA_10.sv Queue2_TLBundleA_12.sv Queue2_TLBundleA_8.sv Queue2_TLBundleD_11.sv Queue2_TLBundleD_13.sv Queue2_TLBundleD_7.sv ram_2x117.sv ram_2x133.sv ram_2x281.sv ram_2x359.sv ram_2x76.sv ram_2x80.sv)
FM_VARIANTS = FrontendBridge
FM_REF_DEPS_FrontendBridge = ICacheBuffer.sv ICacheCtrlBuffer.sv InstrUncacheBuffer.sv Queue2_TLBundleA_10.sv Queue2_TLBundleA_12.sv Queue2_TLBundleA_8.sv Queue2_TLBundleD_11.sv Queue2_TLBundleD_13.sv Queue2_TLBundleD_7.sv ram_2x117.sv ram_2x133.sv ram_2x281.sv ram_2x359.sv ram_2x76.sv ram_2x80.sv
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
