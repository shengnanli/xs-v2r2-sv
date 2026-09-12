MODULE = Fence

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Fence.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Fence = 
GOLDEN_SRCS = $(GOLDEN_RTL)/Fence.sv
FM_VARIANTS = Fence

include ../../../scripts/ut_common.mk

# golden 内含 Scala assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
