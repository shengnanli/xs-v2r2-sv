MODULE = VFDivSqrt

# 向量浮点除法 / 开方 FU 外壳（VecNonPipedFuncUnit：保持旁路 + 冲刷 + 两个 VectorFloatDivider + Mgu + fflags 合并），
# vector-fu lane。
# child 处置（各自 receipt；全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   VectorFloatDivider（evidence/6038c4afbc60）及其闭包（除法 VectorFloatDividerR64 / fpdiv_r64_block_vector / ShiftLeftPriority*
#   / CSA3to2_20/24 / r4_qds_v2(_spec)；开方 fpsqrt_vector_r16 / fpsqrt_r16_block / lzc* / r4_qds*）；
#   VecDataSplitModule（本 lane）；Mgu（evidence/d09e1997840f）+ ByteMaskTailGen / UIntToContLow1s / UIntToContLow0s / MaskExtractor。
#   impl 侧另有共享辅助件 rtl/common/xs_VecFflagsElemMask.sv（golden 里内联，无对应模块）。
# tb 另带按元素的独立 IEEE oracle（含 mask / tail / vstart 与 fflags 元素选择）。
RTL_DIR  = ../../../rtl
DIV_TREE = ShiftLeftPriorityWithLZDResult ShiftLeftPriorityWithLZDResult_6 ShiftLeftPriorityWithLZDResult_8 \
           CSA3to2_20 CSA3to2_24 r4_qds_v2 r4_qds_v2_spec fpdiv_r64_block_vector VectorFloatDividerR64 \
           lzc lzc_3 lzc_4 r4_qds_cg r4_qds r4_qds_spec fpsqrt_r16_block fpsqrt_vector_r16 VectorFloatDivider
MGU_TREE = UIntToContLow1s UIntToContLow0s MaskExtractor ByteMaskTailGen Mgu
CHILDREN = $(DIV_TREE) VecDataSplitModule $(MGU_TREE)
TARGETS  = VFDivSqrt
RTL_SRCS = $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VFDivSqrt
FM_REF_DEPS_VFDivSqrt = ShiftLeftPriorityWithLZDResult.sv ShiftLeftPriorityWithLZDResult_6.sv ShiftLeftPriorityWithLZDResult_8.sv \
    CSA3to2_20.sv CSA3to2_24.sv r4_qds_v2.sv r4_qds_v2_spec.sv fpdiv_r64_block_vector.sv VectorFloatDividerR64.sv \
    lzc.sv lzc_3.sv lzc_4.sv r4_qds_cg.sv r4_qds.sv r4_qds_spec.sv fpsqrt_r16_block.sv fpsqrt_vector_r16.sv \
    VectorFloatDivider.sv VecDataSplitModule.sv \
    UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv ByteMaskTailGen.sv Mgu.sv

# 关 merge_dup：外壳有同源双份寄存器（robIdx 锁存两份），重写件逐份照抄；fm_predict 的模型严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
