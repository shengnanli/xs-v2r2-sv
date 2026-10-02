MODULE = BranchUnit

# BranchUnit（条件分支执行单元，纯组合）。golden 直接 child 两个：
#   BranchModule（golden 内还有孙子 SubModule；重写件把减法并进核里，没有这一层）/ AddrAddModule
#   —— docs/coverage_three_axis.tsv 三者均 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/BranchModule.sv \
           $(RTL_DIR)/backend/AddrAddModule.sv \
           $(RTL_DIR)/backend/BranchUnit.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/BranchUnit.sv \
              $(GOLDEN_RTL)/BranchModule.sv \
              $(GOLDEN_RTL)/SubModule.sv \
              $(GOLDEN_RTL)/AddrAddModule.sv
FM_VARIANTS = BranchUnit
FM_REF_DEPS_BranchUnit = BranchModule.sv SubModule.sv AddrAddModule.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
