# ChiRxPipelines —— TL2CHICoupledL2 的 2 个 utility.Pipeline 单态化（uncore-queues lane）：
#   Pipeline_12  rxdatPipe：RXDAT flit 打一拍（child Queue1_CHIDAT）
#   Pipeline_13  rxrspPipe：RXRSP flit 打一拍（child Queue1_CHIRSP）
# 薄文件由 scripts/gen_uncore_queues.py 生成（golden 体必须恰好是一个 stages_0 例化、逐口同名）。
# child 已签核（PROVEN_DIRECT，rtl/uncore/Queue1_CHI*.sv + 共享核 xs_ChiselQueue1_core）：
# 按规范两侧白盒 —— ref = golden Pipeline + golden Queue1_*，impl = 重写 Pipeline + 重写 Queue1_*。无黑盒。
MODULE = ChiRxPipelines

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/uncore/Queue1_CHIDAT.sv \
           $(RTL_DIR)/uncore/Queue1_CHIRSP.sv \
           $(RTL_DIR)/uncore/Pipeline_12.sv \
           $(RTL_DIR)/uncore/Pipeline_13.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_12.sv $(GOLDEN_RTL)/Pipeline_13.sv \
              $(GOLDEN_RTL)/Queue1_CHIDAT.sv $(GOLDEN_RTL)/Queue1_CHIRSP.sv

# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = Pipeline_12 Pipeline_13
FM_REF_DEPS_Pipeline_12 = Queue1_CHIDAT.sv
FM_REF_DEPS_Pipeline_13 = Queue1_CHIRSP.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 队列存储寄存器不复位（tb arm 后再比）；valid 位异步复位。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
