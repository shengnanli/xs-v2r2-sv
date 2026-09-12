MODULE = VSetRiWi

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VSetRiWi.sv
TB_SRCS = tb.sv

FM_REF_DEPS_VSetRiWi = VsetModule.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VSetRiWi.sv \
              $(GOLDEN_RTL)/VsetModule.sv
FM_VARIANTS = VSetRiWi

include ../../../scripts/ut_common.mk

# golden 无断言,SYNTHESIS 关随机初始化以与可读核对齐。
VCS += +define+SYNTHESIS
