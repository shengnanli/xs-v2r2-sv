MODULE = FarPathAdderF16Pipeline

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FarPathAdderF16Pipeline.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/FarPathAdderF16Pipeline.sv
FM_VARIANTS = FarPathAdderF16Pipeline

include ../../../scripts/ut_common.mk

# initreg：编译期打开机制，运行期选取值（CONVENTIONS「+vcs+initreg 的正确用法」）。
# 三档：INITREG=0 / random / <seed>017。两个寄存器不复位：非常量档下两实例初值各异，
# tb 只在第一次 fire 之后比较（见 tb 文件头）。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
