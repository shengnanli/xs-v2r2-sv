MODULE = RequestBuffer

# RequestBuffer（A 通道请求缓冲）与其 child FastArbiter_2（issueArb）、Queue1_ChosenQBundle（chosenQ）。
# 三者都由本 lane 重写，两侧白盒：ref 读 golden，impl 读重写件。0 黑盒。
#   FastArbiter_2         共享核 xs_FastArbiter_core（已签核，未改动）+ 手写薄文件（载荷捎带独热标识取回 chosenOH）
#   Queue1_ChosenQBundle  新共享核 xs_ChiselQueue1_core + gen_l2_queues.py 薄文件
# 可读核 xs_RequestBuffer_core 手写；类型 / wrapper / fm_pins_pre.tcl 由 scripts/gen_l2_reqbuf.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RequestBuffer.sv \
           $(RTL_DIR)/common/xs_FastArbiter_core.sv $(RTL_DIR)/uncore/FastArbiter_2.sv \
           $(RTL_DIR)/common/xs_ChiselQueue1_core.sv $(RTL_DIR)/uncore/Queue1_ChosenQBundle.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RequestBuffer.sv $(GOLDEN_RTL)/FastArbiter_2.sv $(GOLDEN_RTL)/Queue1_ChosenQBundle.sv
FM_VARIANTS = FastArbiter_2 Queue1_ChosenQBundle RequestBuffer
FM_REF_DEPS_RequestBuffer = FastArbiter_2.sv Queue1_ChosenQBundle.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# vmucp 按目标开：RequestBuffer 107 个对称死位（依据见 verif/fm_target_config/RequestBuffer.tcl）。
fm-RequestBuffer: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
