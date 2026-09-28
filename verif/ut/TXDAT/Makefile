MODULE = TXDAT

# TXDAT（CHI DAT 发送通道）。golden child：Queue16_TaskBundle ×1、Queue16_DSBeat ×2 ——
# 本 lane 重写并签核（verif/ut/L2Queues，共享核 xs_ChiselQueue_core），两侧白盒：
# ref 读 golden 同名件，impl 读重写件；队列里的 ram_16x67 / ram_data_16x256 两侧同源 inline（D60）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXDAT.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_TaskBundle.sv $(RTL_DIR)/uncore/Queue16_DSBeat.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x67.sv $(GOLDEN_RTL)/ram_data_16x256.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TXDAT.sv $(GOLDEN_RTL)/Queue16_TaskBundle.sv $(GOLDEN_RTL)/Queue16_DSBeat.sv
FM_VARIANTS = TXDAT
FM_REF_DEPS_TXDAT = Queue16_TaskBundle.sv Queue16_DSBeat.sv ram_16x67.sv ram_data_16x256.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
