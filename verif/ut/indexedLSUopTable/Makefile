MODULE = indexedLSUopTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_indexedLSUopTable_core.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_1.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_2.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_3.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_4.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_5.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_6.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_7.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/indexedLSUopTable_1.sv $(GOLDEN_RTL)/indexedLSUopTable_2.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_3.sv $(GOLDEN_RTL)/indexedLSUopTable_4.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_5.sv $(GOLDEN_RTL)/indexedLSUopTable_6.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_7.sv

# 七个变体都是自包含叶子（golden 里 0 个子模块例化），所以没有 FM_REF_DEPS_*。
FM_VARIANTS = indexedLSUopTable_1 indexedLSUopTable_2 indexedLSUopTable_3 \
              indexedLSUopTable_4 indexedLSUopTable_5 indexedLSUopTable_6 \
              indexedLSUopTable_7

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 本家族**一个寄存器都没有**（golden 七个文件里 0 个 always 块、0 个 reg，端口表里
# 连 clock/reset 都没有）。两轮 initreg 照跑，作用是钉住「零寄存器」这个结论：
# 若哪天核里多出一个寄存器，两轮就会分岔。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gen mutants
gen:
	python3 gen.py

mutants:
	python3 mutants.py
