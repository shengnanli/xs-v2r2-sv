MODULE = MainPipe_1

# MainPipe_1（L2 tl2chi slice 主流水 s3/s4/s5）。golden child 都是本 lane 重写件（verif/ut/L2MainPipeLeaves），两侧白盒：
#   Arbiter3_TaskWithData x2 / Arbiter3_CHIREQ / Arbiter3_TaskBundle  共享核 xs_FixedPriorityArbiter_core
#   CustomL1Hint（+ Queue16_HintQueueEntry / Queue4_HintQueueEntry，共享核 xs_ChiselQueue_core，ram_16x11 / ram_4x11 两侧 inline）
# 可读核 xs_MainPipe_1_core 手写；TaskBundle 结构体与 wrapper 由 scripts/gen_l2_mainpipe.py 生成。0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/MainPipe_1.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/uncore/Arbiter3_CHIREQ.sv $(RTL_DIR)/uncore/Arbiter3_TaskBundle.sv \
           $(RTL_DIR)/uncore/Arbiter3_TaskWithData.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue16_HintQueueEntry.sv $(RTL_DIR)/uncore/Queue4_HintQueueEntry.sv \
           $(RTL_DIR)/uncore/CustomL1Hint.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x11.sv $(GOLDEN_RTL)/ram_4x11.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe_1.sv \
              $(GOLDEN_RTL)/Arbiter3_CHIREQ.sv $(GOLDEN_RTL)/Arbiter3_TaskBundle.sv \
              $(GOLDEN_RTL)/Arbiter3_TaskWithData.sv \
              $(GOLDEN_RTL)/Queue16_HintQueueEntry.sv $(GOLDEN_RTL)/Queue4_HintQueueEntry.sv \
              $(GOLDEN_RTL)/CustomL1Hint.sv
FM_VARIANTS = MainPipe_1
FM_REF_DEPS_MainPipe_1 = Arbiter3_CHIREQ.sv Arbiter3_TaskBundle.sv Arbiter3_TaskWithData.sv \
                         Queue16_HintQueueEntry.sv Queue4_HintQueueEntry.sv CustomL1Hint.sv \
                         ram_16x11.sv ram_4x11.sv
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
