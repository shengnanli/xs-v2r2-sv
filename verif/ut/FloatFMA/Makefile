# FloatFMA —— 标量浮点乘加运算体（f16 / f32 / f64，三级寄存器）。
#
# golden 直接 child 三个，全部两侧白盒（ref = golden，impl = 本仓重写件）：
#   BoothEncoderF64F32F16          rtl/backend/BoothEncoderF64F32F16.sv（本 lane 重写，PACKED=0）
#   CSA_Nto2With3to2MainPipeline   rtl/backend/CSA_Nto2With3to2MainPipeline.sv（本 lane 重写）
#   CSA3to2                        rtl/backend/CSA3to2.sv（PROVEN_DIRECT）
# 孙辈 CSA4to2：两侧白盒，impl = rtl/backend/CSA4to2.sv（agent/fpu-parents 签核，合 main 后改指）。
# 无黑盒、无 dont_verify。
#
# UT（gen.py）：双例化逐拍比 + 独立 IEEE 754 oracle 对 golden 逐个操作判结果与 fflags。
MODULE = FloatFMA

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FloatFMA.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16.sv \
           $(RTL_DIR)/backend/CSA_Nto2With3to2MainPipeline.sv \
           $(RTL_DIR)/backend/CSA3to2.sv \
           $(RTL_DIR)/backend/CSA4to2.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

GOLDEN_SRCS = $(GOLDEN_RTL)/FloatFMA.sv \
              $(GOLDEN_RTL)/BoothEncoderF64F32F16.sv \
              $(GOLDEN_RTL)/CSA_Nto2With3to2MainPipeline.sv \
              $(GOLDEN_RTL)/CSA3to2.sv \
              $(GOLDEN_RTL)/CSA4to2.sv

FM_VARIANTS = FloatFMA
FM_REF_DEPS_FloatFMA = BoothEncoderF64F32F16.sv CSA_Nto2With3to2MainPipeline.sv CSA3to2.sv CSA4to2.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
