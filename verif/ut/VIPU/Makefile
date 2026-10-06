# 由 tools/kimi_lane.py 按模板生成（KIMI 只提供源清单）
MODULE = VIPU
RTL_SRCS = $(addprefix ../../../,rtl/backend/CSA3to2_124.sv rtl/backend/CSA3to2_125.sv rtl/backend/CSA3to2_127.sv rtl/backend/CSA3to2_132.sv rtl/backend/CSA4to2_15.sv rtl/backend/CSA4to2_16.sv rtl/backend/compare_2to1.sv rtl/backend/compare_2to1_2.sv rtl/backend/compare_3to1.sv rtl/backend/compare_3to1_1.sv rtl/backend/compare_3to1_2.sv rtl/backend/compare_3to1_6.sv rtl/backend/Reduction.sv rtl/backend/VMask.sv rtl/backend/VIAluDecoder.sv rtl/backend/VIAlu.sv rtl/backend/VIPU.sv)
TB_SRCS  = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,VIPU.sv CSA3to2_124.sv CSA3to2_125.sv CSA3to2_127.sv CSA3to2_132.sv CSA4to2_15.sv CSA4to2_16.sv compare_2to1.sv compare_2to1_2.sv compare_3to1.sv compare_3to1_1.sv compare_3to1_2.sv compare_3to1_6.sv Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv Reduction.sv VMask.sv VIAluDecoder.sv VIAlu.sv)
FM_VARIANTS = VIPU
FM_REF_DEPS_VIPU = CSA3to2_124.sv CSA3to2_125.sv CSA3to2_127.sv CSA3to2_132.sv CSA4to2_15.sv CSA4to2_16.sv compare_2to1.sv compare_2to1_2.sv compare_3to1.sv compare_3to1_1.sv compare_3to1_2.sv compare_3to1_6.sv Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv Reduction.sv VMask.sv VIAluDecoder.sv VIAlu.sv
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
