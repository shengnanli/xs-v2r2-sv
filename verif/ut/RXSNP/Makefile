MODULE = RXSNP

# RXSNP（CHI SNP 接收通道）。golden child：Queue2_CHISNP（本 lane 重写并签核，verif/ut/L2Queues），
# 两侧白盒；其 ram_2x98 两侧同源 inline（D60）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RXSNP.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv $(RTL_DIR)/uncore/Queue2_CHISNP.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x98.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RXSNP.sv $(GOLDEN_RTL)/Queue2_CHISNP.sv
FM_VARIANTS = RXSNP
FM_REF_DEPS_RXSNP = Queue2_CHISNP.sv ram_2x98.sv
FM_MERGE_DUP = false
# 68 个对称死位（stallCnt 64 位 + 队列 ram 里 addr[4:3] 4 位）vmucp 实比，依据见 verif/fm_target_config/RXSNP.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

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
