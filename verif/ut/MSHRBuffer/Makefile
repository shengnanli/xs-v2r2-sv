MODULE = MSHRBuffer

# refillBuf（MSHRBuffer，2 写口带 beatMask）/ releaseBuf（MSHRBuffer_1，3 写口整块写）：
# 同一 Chisel 类 coupledL2.MSHRBuffer 的两个单态化，共用核 xs_MSHRBuffer_core（在 MSHRBuffer.sv）。
# 0 子模块、0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/MSHRBuffer.sv $(RTL_DIR)/uncore/MSHRBuffer_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRBuffer.sv $(GOLDEN_RTL)/MSHRBuffer_1.sv
FM_VARIANTS = MSHRBuffer MSHRBuffer_1
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期开机制、运行期选取值。存储阵列不复位，tb 首沿前同步两侧初值（见 gen.py）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
