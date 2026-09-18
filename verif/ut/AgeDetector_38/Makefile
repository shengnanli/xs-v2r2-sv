MODULE = AgeDetector_38

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/AgeDetector_38.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/AgeDetector_38.sv
FM_REF_DEPS_AgeDetector_38 =
FM_VARIANTS = AgeDetector_38

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块会调用未定义的 xs_assert_v2；与 FM 侧口径一致，
# UT 也定义 SYNTHESIS。本模块 300 个寄存器全部复位，两轮 initreg 都要过。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
