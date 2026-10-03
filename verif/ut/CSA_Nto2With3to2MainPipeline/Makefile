# CSA_Nto2With3to2MainPipeline —— 浮点乘加的 27->2 部分积压缩树（4 个 107 位流水线寄存器）。
#
# golden 直接 child 两种：
#   CSA3to2 ×19  两侧白盒：ref = golden，impl = 本仓重写件 rtl/backend/CSA3to2.sv（PROVEN_DIRECT）
#   CSA4to2 ×3   本仓无重写件（coverage 第 3 列 PROVEN_IN_CONE、GOLDEN_REUSE）：两侧同源 elaborate golden 原件，
#                不黑盒（照 verif/ut/FMA、VectorFloatFMA 的先例）。
# UT：RTL_SRCS 含重写件 CSA3to2.sv，derive 把它和本模块 wrapper 一起改名 *_xs 并同步改引用，
#   所以 impl 侧的树用的是重写 CSA3to2；CSA4to2 两侧共用 golden 原件（RTL_GOLDEN_DEPS）。
MODULE = CSA_Nto2With3to2MainPipeline

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CSA_Nto2With3to2MainPipeline.sv \
           $(RTL_DIR)/backend/CSA3to2.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

GOLDEN_SRCS = $(GOLDEN_RTL)/CSA_Nto2With3to2MainPipeline.sv $(GOLDEN_RTL)/CSA3to2.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/CSA4to2.sv

FM_VARIANTS = CSA_Nto2With3to2MainPipeline
FM_REF_DEPS_CSA_Nto2With3to2MainPipeline = CSA3to2.sv CSA4to2.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
