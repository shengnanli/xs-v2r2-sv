# FastArbiterL2c —— L2 顶层（TL2CHICoupledL2）3 个 FastArbiter 变体（csr-l2-leaves lane）：
#   FastArbiter     prefetch_train_arb（4 路 PrefetchTrain）
#   FastArbiter_1   prefetch_resp_arb（4 路 PrefetchResp）
#   FastArbiter_26  txrsp_arb（4 路 CHI TXRSP，带 io_chosen）
# 薄 wrapper 由 scripts/gen_fastarbiter_l2c.py 生成；核 rtl/common/xs_FastArbiter_core.sv（已签核，不改）。
# golden 全是 0 子模块叶，无黑盒，无 FM_REF_DEPS_*。
MODULE = FastArbiterL2c

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter.sv \
           $(RTL_DIR)/uncore/FastArbiter_1.sv \
           $(RTL_DIR)/uncore/FastArbiter_26.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter.sv $(GOLDEN_RTL)/FastArbiter_1.sv $(GOLDEN_RTL)/FastArbiter_26.sv

# FM_VARIANTS 必须写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = FastArbiter FastArbiter_1 FastArbiter_26
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两张掩码寄存器都异步复位；上电复位后两侧同态，三档 initreg 都可用。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
