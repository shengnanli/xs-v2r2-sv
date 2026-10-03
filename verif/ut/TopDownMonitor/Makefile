MODULE = TopDownMonitor

RTL_DIR  = ../../../rtl
# 本体（手写核 + 生成的 wrapper），无子模块。tb.sv 由 scripts/gen_topdownmonitor.py 生成。
RTL_SRCS = $(RTL_DIR)/l2/TopDownMonitor.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/TopDownMonitor.sv
FM_VARIANTS = TopDownMonitor

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
