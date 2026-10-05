MODULE = VFMA

# 向量浮点乘加 FU 外壳（VecPipedFuncUnit，LAT=3：valid / 反压链 + 两个 VectorFloatFMA + Mgu + fflags 合并），vector-fu lane。
# child 处置（各自 receipt；全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   VectorFloatFMA（evidence/a757ff84032a 等，impl 闭包 sha 与当前字节一致）+ BoothEncoderF64F32F16_3 / CSA_Nto2With3to2MainPipeline /
#   CSA3to2 / CSA4to2（重写侧另有家族核文件 BoothEncoderF64F32F16.sv）；VecDataSplitModule（本 lane）；
#   Mgu（evidence/d09e1997840f）+ ByteMaskTailGen / UIntToContLow1s / UIntToContLow0s / MaskExtractor。
#   impl 侧另有共享辅助件 rtl/common/xs_VecFflagsElemMask.sv（golden 里内联，无对应模块）。
# tb 另带按元素的独立 IEEE oracle（本目录 fp_fma_oracle_pkg.sv：乘加 / 乘法精确算术 + 舍入；含 mask / tail / vstart 与 fflags 元素选择）。
RTL_DIR  = ../../../rtl
FMA_TREE = BoothEncoderF64F32F16_3 BoothEncoderF64F32F16 CSA_Nto2With3to2MainPipeline CSA3to2 CSA4to2 VectorFloatFMA
MGU_TREE = UIntToContLow1s UIntToContLow0s MaskExtractor ByteMaskTailGen Mgu
TARGETS  = VFMA
RTL_SRCS = $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(FMA_TREE) VecDataSplitModule $(MGU_TREE) $(TARGETS)))
TB_SRCS  = fp_fma_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,BoothEncoderF64F32F16_3.sv CSA_Nto2With3to2MainPipeline.sv CSA3to2.sv CSA4to2.sv \
               VectorFloatFMA.sv VecDataSplitModule.sv $(addsuffix .sv,$(MGU_TREE)) VFMA.sv)

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VFMA
FM_REF_DEPS_VFMA = BoothEncoderF64F32F16_3.sv CSA_Nto2With3to2MainPipeline.sv CSA3to2.sv CSA4to2.sv VectorFloatFMA.sv \
    VecDataSplitModule.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv ByteMaskTailGen.sv Mgu.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
