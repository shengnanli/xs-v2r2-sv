# PFEvent —— 24 个 mhpmevent CSR 影子副本（perfEventsModule ×24），监听 CSR 写总线。
# child perfEventsModule 已签核（PROVEN_DIRECT）：两侧白盒，ref = golden，impl = 重写件。无黑盒。
# UT（gen.py）：双例化逐拍比 + 独立参考模型（mhpmevent 字段布局 / OPTYPE WARL / 异步复位）。
MODULE = PFEvent

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/perfEventsModule.sv \
           $(RTL_DIR)/backend/PFEvent.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/perfEventsModule.sv \
              $(GOLDEN_RTL)/PFEvent.sv

FM_VARIANTS = PFEvent
FM_REF_DEPS_PFEvent = perfEventsModule.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
