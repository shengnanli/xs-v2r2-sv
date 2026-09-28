MODULE = AMOALU

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/AMOALU.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/AMOALU.sv

FM_VARIANTS = AMOALU

include ../../../scripts/ut_common.mk

# 纯组合模块没有初态，但统一开启 initreg 机制，使两档 UT 命令与工程约定一致。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
