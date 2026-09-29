MODULE = L2MainPipeLeaves

# MainPipe_1（L2 tl2chi 主流水）的 child：
#   Arbiter3_CHIREQ / Arbiter3_TaskBundle / Arbiter3_TaskWithData  已签核核 xs_FixedPriorityArbiter_core + scripts/gen_l2_arbiter3.py 薄文件
#   CustomL1Hint                                                     手写（两个 child 队列两侧白盒）
#   Queue16_HintQueueEntry / Queue4_HintQueueEntry                   共享核 xs_ChiselQueue_core + scripts/gen_l2_queues.py 薄文件
# 队列存储是 golden 的 ram_16x11 / ram_4x11 行为级叶子（深度都是 2 的幂），按 codex 0151 D60 两侧同源 inline，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/uncore/Arbiter3_CHIREQ.sv $(RTL_DIR)/uncore/Arbiter3_TaskBundle.sv \
           $(RTL_DIR)/uncore/Arbiter3_TaskWithData.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_HintQueueEntry.sv $(RTL_DIR)/uncore/Queue4_HintQueueEntry.sv \
           $(RTL_DIR)/uncore/CustomL1Hint.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x11.sv $(GOLDEN_RTL)/ram_4x11.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter3_CHIREQ.sv $(GOLDEN_RTL)/Arbiter3_TaskBundle.sv \
              $(GOLDEN_RTL)/Arbiter3_TaskWithData.sv \
              $(GOLDEN_RTL)/Queue16_HintQueueEntry.sv $(GOLDEN_RTL)/Queue4_HintQueueEntry.sv \
              $(GOLDEN_RTL)/CustomL1Hint.sv
FM_VARIANTS = Arbiter3_CHIREQ Arbiter3_TaskBundle Arbiter3_TaskWithData \
              Queue16_HintQueueEntry Queue4_HintQueueEntry CustomL1Hint
FM_REF_DEPS_Queue16_HintQueueEntry = ram_16x11.sv
FM_REF_DEPS_Queue4_HintQueueEntry = ram_4x11.sv
FM_REF_DEPS_CustomL1Hint = Queue16_HintQueueEntry.sv Queue4_HintQueueEntry.sv ram_16x11.sv ram_4x11.sv
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
