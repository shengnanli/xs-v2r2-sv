MODULE = JumpUnit

# JumpUnit（jal/jalr/auipc 执行单元，纯组合）。golden 直接 child 一个：
#   JumpDataModule —— docs/coverage_three_axis.tsv PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/JumpDataModule.sv \
           $(RTL_DIR)/backend/JumpUnit.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/JumpUnit.sv \
              $(GOLDEN_RTL)/JumpDataModule.sv
FM_VARIANTS = JumpUnit
FM_REF_DEPS_JumpUnit = JumpDataModule.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
