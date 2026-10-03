# VectorFloatFMA —— 向量浮点乘加单元（f64 / f32x2 / f16x4 共用一套 Booth + CSA 阵列，三级寄存器）。
#
# golden 直接 child 三个，处置：
#   BoothEncoderF64F32F16_3      两侧白盒：ref = golden，impl = 本仓重写件（已单独签核）
#   CSA3to2                      两侧白盒：ref = golden，impl = 本仓重写件 rtl/backend/CSA3to2.sv（PROVEN_DIRECT）
#   CSA_Nto2With3to2MainPipeline ★golden 复用，不是重写★：本仓没有重写件（内含 CSA4to2，同样没有），
#                                两侧同源 elaborate（RTL_GOLDEN_DEPS），不设黑盒。照 verif/ut/FMA 的先例。
#     —— FM 的 impl 侧，这棵树里例化的 CSA3to2 解析到本仓重写件；
#        UT 里它不被 derive 改名，两侧共用同一份定义（内部的 CSA3to2 / CSA4to2 也是 golden 的）。
# 无黑盒、无 dont_verify。
MODULE = VectorFloatFMA

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VectorFloatFMA.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16_3.sv \
           $(RTL_DIR)/backend/CSA3to2.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

GOLDEN_SRCS = $(GOLDEN_RTL)/VectorFloatFMA.sv \
              $(GOLDEN_RTL)/BoothEncoderF64F32F16_3.sv \
              $(GOLDEN_RTL)/CSA3to2.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/CSA_Nto2With3to2MainPipeline.sv \
                  $(GOLDEN_RTL)/CSA4to2.sv

FM_VARIANTS = VectorFloatFMA
FM_REF_DEPS_VectorFloatFMA = BoothEncoderF64F32F16_3.sv CSA3to2.sv CSA_Nto2With3to2MainPipeline.sv CSA4to2.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
