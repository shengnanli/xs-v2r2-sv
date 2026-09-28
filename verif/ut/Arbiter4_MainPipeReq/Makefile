# Arbiter4_MainPipeReq —— DCache MainPipe s0 的四路固定优先级仲裁器
# （probe > refill > store > atomic）。重写件是 xs_FixedPriorityArbiter_core 家族的
# 一个薄文件（rtl/memblock/Arbiter4_MainPipeReq.sv），核与 ICache 侧 Arbiter2/5 共用。
# golden 是纯组合自足叶子，无子模块依赖。
MODULE = Arbiter4_MainPipeReq

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/memblock/Arbiter4_MainPipeReq.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter4_MainPipeReq.sv

FM_VARIANTS = Arbiter4_MainPipeReq

# 纯组合、无寄存器：关 merge_dup 让 fm_predict 模型严格适用（期望 = 输出端口位数）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合模块没有初态，但统一开启 initreg 机制，两档命令与工程约定一致。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen.py --check
