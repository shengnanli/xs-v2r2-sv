MODULE = SbufferData

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/SbufferData.sv
TB_SRCS  = sbd_bridge.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SbufferData.sv
FM_VARIANTS = SbufferData

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期只负责"打开 initreg 机制"，取值在运行期由 +vcs+initreg+$(INITREG) 选。
# 两处都要给：只给编译期的 +0 会拒编，只给运行期会被静默忽略（Warning-[VICIU]）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
