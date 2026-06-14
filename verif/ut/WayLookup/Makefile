MODULE = WayLookup

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/WayLookup.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/WayLookup_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/WayLookup.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = WayLookup

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
VCS += +define+SYNTHESIS
