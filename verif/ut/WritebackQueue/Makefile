MODULE = WritebackQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/WritebackQueue.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/WritebackEntry.sv \
                  $(GOLDEN_RTL)/WritebackEntry_15.sv

FM_REF_DEPS_WritebackQueue = WritebackEntry.sv WritebackEntry_15.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/WritebackQueue.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = WritebackQueue

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
