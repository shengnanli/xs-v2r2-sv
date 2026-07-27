MODULE = IntToFP_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 (IntToFP_3 顶层胶合: valid/perf 打两拍) + golden 转换 datapath 子树。
RTL_SRCS = $(RTL_DIR)/backend/IntToFP_3.sv

TB_SRCS = variants_xs.sv tb.sv

# int->fp 转换 datapath 整颗子树 (可读逻辑, 无 vendor, 无绿305子 ⇒ 全部两侧
# elaborate 白盒). golden IntToFP_3 顶层例化 IntToFPDataModule, 后者例化
# IntToFP/_1/_2, 各例化 prenorm(LZA/CLZ) + postnorm(_1/_2)(RoundingUnit_1/_2)。
I2F_LEAVES = IntToFPDataModule.sv \
             IntToFP.sv IntToFP_1.sv IntToFP_2.sv \
             IntToFP_prenorm.sv \
             IntToFP_postnorm.sv IntToFP_postnorm_1.sv IntToFP_postnorm_2.sv \
             RoundingUnit.sv RoundingUnit_1.sv RoundingUnit_2.sv \
             LZA.sv CLZ.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/IntToFP_3.sv $(addprefix $(GOLDEN_RTL)/,$(I2F_LEAVES))

# FM: golden 顶层 IntToFP_3 (含全部叶子) vs 手写同名 wrapper (→ 可读核 +
#     两侧对称 elaborate 的 golden datapath 子树)。无黑盒 ⇒ signoff-strict。
# impl 侧 FM 输入 = 可读核 wrapper + golden datapath 子树 (与 ref 侧 FM_REF_DEPS
#   对称提供) ⇒ IntToFPDataModule 及其整颗子树两侧同 elaborate, 白盒受验, 非黑盒。
WRAPPER_SRCS = $(RTL_DIR)/backend/IntToFP_3_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(I2F_LEAVES))
FM_VARIANTS = IntToFP_3
FM_REF_DEPS_IntToFP_3 = $(I2F_LEAVES)

include ../../../scripts/ut_common.mk

# golden 叶子无断言, SYNTHESIS 关随机初值以与可读核对齐。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
