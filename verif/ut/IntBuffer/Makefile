MODULE = IntBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IntBuffer.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/IntBuffer.sv
FM_VARIANTS = IntBuffer

include ../../../scripts/ut_common.mk

# initreg：编译期打开机制，运行期选取值（CONVENTIONS「+vcs+initreg 的正确用法」）。
# 三档：INITREG=0 / random / <seed>017。唯一寄存器异步复位：tb 在第一次复位前不比较。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
