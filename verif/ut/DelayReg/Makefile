MODULE = DelayReg

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:payload 类型包 + 通用延迟核。
RTL_SRCS = $(RTL_DIR)/backend/delayreg_pkg.sv \
           $(RTL_DIR)/backend/DelayReg.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层(纯叶子,无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/DelayReg.sv

# FM:golden DelayReg vs 手写同名 wrapper(-> 通用延迟核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/DelayReg_wrapper.sv
FM_VARIANTS = DelayReg

include ../../../scripts/ut_common.mk

# golden 在 SYNTHESIS 下关随机初始化,与可读核(复位到 0)对齐。
VCS += +define+SYNTHESIS
