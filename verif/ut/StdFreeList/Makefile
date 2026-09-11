MODULE = StdFreeList

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/StdFreeList.sv \
           $(GOLDEN_RTL)/SnapshotGenerator.sv
TB_SRCS = tb.sv

FM_REF_DEPS_StdFreeList = SnapshotGenerator.sv
FM_MERGE_DUP = true
GOLDEN_SRCS = $(GOLDEN_RTL)/StdFreeList.sv \
              $(GOLDEN_RTL)/SnapshotGenerator.sv
FM_VARIANTS = StdFreeList

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
