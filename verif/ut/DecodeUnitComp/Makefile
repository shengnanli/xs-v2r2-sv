MODULE = DecodeUnitComp

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VecExceptionGen.sv \
           $(RTL_DIR)/backend/xs_indexedLSUopTable_core.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_1.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_2.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_3.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_4.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_5.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_6.sv \
           $(RTL_DIR)/backend/indexedLSUopTable_7.sv \
           $(RTL_DIR)/backend/DecodeUnitComp.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/DecodeUnitComp.sv $(GOLDEN_RTL)/VecExceptionGen.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_1.sv $(GOLDEN_RTL)/indexedLSUopTable_2.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_3.sv $(GOLDEN_RTL)/indexedLSUopTable_4.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_5.sv $(GOLDEN_RTL)/indexedLSUopTable_6.sv \
              $(GOLDEN_RTL)/indexedLSUopTable_7.sv

# 本目标的子模块闭包全部**本轮自己重写**，两侧都不黑盒：FM 时 ref 侧给 golden 的
# 8 个子模块文件，impl 侧给重写的同名 wrapper，整条链两侧完整 elaborate。
FM_VARIANTS = DecodeUnitComp
FM_REF_DEPS_DecodeUnitComp = VecExceptionGen.sv \
  indexedLSUopTable_1.sv indexedLSUopTable_2.sv indexedLSUopTable_3.sv \
  indexedLSUopTable_4.sv indexedLSUopTable_5.sv indexedLSUopTable_6.sv \
  indexedLSUopTable_7.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 复位域：99 个锁存寄存器**不带复位**，3 个状态机寄存器带异步复位、复位值全 0。
# 正因为有不复位的寄存器，两轮 initreg（random / 0）才有意义：上电初值不同而
# 比对窗口（WARMUP 之后）必须一致，否则就是复位域写错了。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gen mutants
gen:
	python3 gen.py

mutants:
	python3 mutants.py
