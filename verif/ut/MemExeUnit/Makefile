MODULE = MemExeUnit

RTL_DIR = ../../../rtl
# Std 是 MemExeUnit 的唯一 child：impl 侧两者都用重写件（两侧白盒）。
RTL_SRCS = $(RTL_DIR)/backend/Std.sv $(RTL_DIR)/backend/MemExeUnit.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/Std.sv $(GOLDEN_RTL)/MemExeUnit.sv
FM_VARIANTS = Std MemExeUnit
# FM 预测模型（golden 闭包寄存器位 + 顶层 output 位）只在不合并重复寄存器时严格成立。
FM_MERGE_DUP = false
FM_REF_DEPS_MemExeUnit = Std.sv

include ../../../scripts/ut_common.mk

# initreg：编译期打开机制，运行期选取值（CONVENTIONS「+vcs+initreg 的正确用法」）。
# 三档：INITREG=0 / random / <seed>017。两个目标都是纯组合，初值档只为满足统一流程。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
