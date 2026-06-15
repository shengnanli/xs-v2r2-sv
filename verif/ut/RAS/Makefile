MODULE = RASStack

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_RASStack（含 xs_ras_pkg）
RTL_SRCS = $(RTL_DIR)/frontend/RAS.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/RAS_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RASStack.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RASStack

include ../../../scripts/ut_common.mk

# golden RASStack 含 `ifndef SYNTHESIS 的随机初始化与「BOS distance>2」$fatal 断言；
# UT 随机激励会触发该断言，故定义 SYNTHESIS 关掉（同时关掉随机初值注入）。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
VCS += +define+SYNTHESIS
