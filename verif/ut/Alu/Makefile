MODULE = Alu

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Alu.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Alu = AluDataModule.sv AddModule.sv SubModule.sv LeftShiftModule.sv RightShiftModule.sv LeftShiftWordModule.sv RightShiftWordModule.sv ShiftResultSelect.sv MiscResultSelect.sv ConditionalZeroModule.sv WordResultSelect.sv AluResSel.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Alu.sv \
              $(GOLDEN_RTL)/AluDataModule.sv \
              $(GOLDEN_RTL)/AddModule.sv \
              $(GOLDEN_RTL)/SubModule.sv \
              $(GOLDEN_RTL)/LeftShiftModule.sv \
              $(GOLDEN_RTL)/RightShiftModule.sv \
              $(GOLDEN_RTL)/LeftShiftWordModule.sv \
              $(GOLDEN_RTL)/RightShiftWordModule.sv \
              $(GOLDEN_RTL)/ShiftResultSelect.sv \
              $(GOLDEN_RTL)/MiscResultSelect.sv \
              $(GOLDEN_RTL)/ConditionalZeroModule.sv \
              $(GOLDEN_RTL)/WordResultSelect.sv \
              $(GOLDEN_RTL)/AluResSel.sv
FM_VARIANTS = Alu

include ../../../scripts/ut_common.mk

# golden 叶子无断言,SYNTHESIS 关随机初始化以与可读核(无随机)对齐。
VCS += +define+SYNTHESIS
