MODULE = RASStack

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/RASStack.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RASStack.sv
FM_VARIANTS = RASStack

include ../../../scripts/ut_common.mk

# golden RASStack 含 `ifndef SYNTHESIS 的随机初始化与「BOS distance>2」$fatal 断言；
# UT 随机激励会触发该断言，故定义 SYNTHESIS 关掉（同时关掉随机初值注入）。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
VCS += +define+SYNTHESIS
