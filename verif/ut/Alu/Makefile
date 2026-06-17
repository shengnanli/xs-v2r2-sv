MODULE = Alu

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:类型包 + 组合核(纯叶子,无黑盒子模块)。
RTL_SRCS = $(RTL_DIR)/backend/alu_pkg.sv \
           $(RTL_DIR)/backend/Alu.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 Alu 例化 AluDataModule,后者再例化 11 个运算叶子。UT 双例化需全量。
ALU_LEAVES = AluDataModule.sv AddModule.sv SubModule.sv \
             LeftShiftModule.sv RightShiftModule.sv \
             LeftShiftWordModule.sv RightShiftWordModule.sv \
             ShiftResultSelect.sv MiscResultSelect.sv \
             ConditionalZeroModule.sv WordResultSelect.sv AluResSel.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Alu.sv $(addprefix $(GOLDEN_RTL)/,$(ALU_LEAVES))

# FM:golden 顶层 Alu(含全部叶子) vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/Alu_wrapper.sv
FM_VARIANTS = Alu
FM_REF_DEPS_Alu = $(ALU_LEAVES)

include ../../../scripts/ut_common.mk

# golden 叶子无断言,SYNTHESIS 关随机初始化以与可读核(无随机)对齐。
VCS += +define+SYNTHESIS
