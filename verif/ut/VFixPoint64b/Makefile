MODULE = VFixPoint64b

# VFixPoint64b（向量定点第二级：饱和/平均舍入/缩放移位舍入/窄化裁剪，纯组合）。
# golden 直接 child 一个：Adder_chain_rnd —— docs/coverage_three_axis.tsv PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Adder_chain_rnd.sv \
           $(RTL_DIR)/backend/VFixPoint64b.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/VFixPoint64b.sv \
              $(GOLDEN_RTL)/Adder_chain_rnd.sv
FM_VARIANTS = VFixPoint64b
FM_REF_DEPS_VFixPoint64b = Adder_chain_rnd.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
