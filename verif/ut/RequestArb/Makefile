MODULE = RequestArb

# RequestArb（MainPipe 入口仲裁，s0~s2）。0 子模块、0 黑盒。
# 可读核 xs_RequestArb_core 手写；TaskBundle 结构体 / wrapper / fm_pins_pre.tcl 由
# scripts/gen_l2_requestarb.py 从 golden 端口表生成（带 --check，已进 gate_all）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RequestArb.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RequestArb.sv
FM_VARIANTS = RequestArb
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
