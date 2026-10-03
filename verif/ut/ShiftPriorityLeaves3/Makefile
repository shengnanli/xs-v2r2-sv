MODULE = ShiftPriorityLeaves3

RTL_DIR = ../../../rtl
LEAVES = ShiftLeftPriorityWithLZDResult_6 ShiftLeftPriorityWithLZDResult_8 ShiftLeftPriorityWithF64EXPResult
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = ShiftLeftPriorityWithLZDResult_6 ShiftLeftPriorityWithLZDResult_8 ShiftLeftPriorityWithF64EXPResult
# FM 预测模型（golden 闭包寄存器位 + 顶层 output 位）只在不合并重复寄存器时严格成立。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# initreg：编译期打开机制，运行期选取值（CONVENTIONS「+vcs+initreg 的正确用法」）。
# 三档：INITREG=0 / random / <seed>017。三个叶全组合，初值档只为满足统一流程。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
