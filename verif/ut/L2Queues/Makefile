MODULE = L2Queues

# coupledL2 Slice 子树里的 chisel Queue 单态化（TXDAT / RXSNP / GrantBuffer 的 child）：
# 共享控制核 rtl/common/xs_ChiselQueue_core.sv + 薄文件（scripts/gen_l2_queues.py 生成）。
# 存储是 golden 的 ram_<D>x<W> 行为级叶子：按 codex 0151 D60 两侧同源 inline elaborate
# （同时进 RTL_GOLDEN_DEPS 与 FM_REF_DEPS），无黑盒。五者深度都是 2 的幂（2^addr == depth）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_DSBeat.sv $(RTL_DIR)/uncore/Queue16_TaskBundle.sv \
           $(RTL_DIR)/uncore/Queue2_CHISNP.sv $(RTL_DIR)/uncore/Queue16_GrantQueueTask.sv \
           $(RTL_DIR)/uncore/Queue16_GrantQueueData.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_data_16x256.sv $(GOLDEN_RTL)/ram_16x67.sv \
                  $(GOLDEN_RTL)/ram_2x98.sv $(GOLDEN_RTL)/ram_16x25.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue16_DSBeat.sv $(GOLDEN_RTL)/Queue16_TaskBundle.sv \
              $(GOLDEN_RTL)/Queue2_CHISNP.sv $(GOLDEN_RTL)/Queue16_GrantQueueTask.sv \
              $(GOLDEN_RTL)/Queue16_GrantQueueData.sv
FM_VARIANTS = Queue16_DSBeat Queue16_TaskBundle Queue2_CHISNP Queue16_GrantQueueTask Queue16_GrantQueueData
FM_REF_DEPS_Queue16_DSBeat = ram_data_16x256.sv
FM_REF_DEPS_Queue16_TaskBundle = ram_16x67.sv
FM_REF_DEPS_Queue2_CHISNP = ram_2x98.sv
FM_REF_DEPS_Queue16_GrantQueueTask = ram_16x25.sv
FM_REF_DEPS_Queue16_GrantQueueData = ram_data_16x256.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
