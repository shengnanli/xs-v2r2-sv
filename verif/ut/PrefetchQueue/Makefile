MODULE = PrefetchQueue

# L2 预取请求"只留最新"队列（单文件：核 + golden 同名 wrapper）。无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/PrefetchQueue.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchQueue.sv

FM_VARIANTS = PrefetchQueue
FM_MERGE_DUP = false

# ★vmucp + 钉点：依据见 verif/fm_target_config/PrefetchQueue.tcl★（31 位只喂自己次态的 valid）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器异步复位；复位域由 FM 把关。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
