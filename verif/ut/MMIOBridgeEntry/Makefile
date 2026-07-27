MODULE = MMIOBridgeEntry

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 参数化可读核 xs_MMIOBridgeEntry_core(自包含 MMIO 事务 FSM, 无子模块)。
RTL_SRCS = $(RTL_DIR)/l2/MMIOBridgeEntry.sv
WRAPPER_SRCS = $(RTL_DIR)/l2/MMIOBridgeEntry_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MMIOBridgeEntry.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 signoff-strict; 无子模块无黑盒。base 变体 io_id 1 位, #(.ID_W(1))。
FM_VARIANTS = MMIOBridgeEntry

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
