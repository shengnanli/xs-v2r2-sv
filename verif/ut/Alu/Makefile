MODULE = Alu

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/alu_pkg.sv \
           $(RTL_DIR)/backend/Alu.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# ALU 运算叶子（G1 与 G0 逐字一致，已核对）：两侧同源 elaborate，无黑盒
ALU_LEAVES = AluDataModule.sv AddModule.sv SubModule.sv \
             LeftShiftModule.sv RightShiftModule.sv \
             LeftShiftWordModule.sv RightShiftWordModule.sv \
             ShiftResultSelect.sv MiscResultSelect.sv \
             ConditionalZeroModule.sv WordResultSelect.sv AluResSel.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Alu.sv $(addprefix $(GOLDEN_RTL)/,$(ALU_LEAVES))
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(ALU_LEAVES))

FM_VARIANTS = Alu
FM_REF_DEPS_Alu = $(ALU_LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
