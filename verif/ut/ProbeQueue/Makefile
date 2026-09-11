MODULE = ProbeQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/ProbeQueue.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv \
                  $(GOLDEN_RTL)/ProbeEntry.sv

FM_REF_DEPS_ProbeQueue = ProbeEntry.sv Arbiter8_MainPipeReq.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/ProbeQueue.sv
FM_VARIANTS = ProbeQueue

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
