MODULE = PrefetchReceiver

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/PrefetchReceiver.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchReceiver.sv
FM_VARIANTS = PrefetchReceiver

include ../../../scripts/ut_common.mk

# initreg：编译期打开机制，运行期选取值（CONVENTIONS「+vcs+initreg 的正确用法」）。
# 三档：INITREG=0 / random / <seed>017。纯组合，初值档只为满足统一流程。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
