MODULE = L2DataStorage

# L2DataStorage / _1 / _2 / _3：DataStorage 层的 MBIST 分发 extraHold 叶子（utility.mbist.MbistPipeline
# 单态化）。核 rtl/dft/xs_mbist_hold_leaf_core.sv；薄文件由 scripts/gen_mbist_pipe_family.py
# （EXTRA_MODS）生成。0 子模块、0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/dft/xs_mbist_hold_leaf_core.sv \
           $(RTL_DIR)/dft/L2DataStorage.sv $(RTL_DIR)/dft/L2DataStorage_1.sv \
           $(RTL_DIR)/dft/L2DataStorage_2.sv $(RTL_DIR)/dft/L2DataStorage_3.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2DataStorage.sv $(GOLDEN_RTL)/L2DataStorage_1.sv \
              $(GOLDEN_RTL)/L2DataStorage_2.sv $(GOLDEN_RTL)/L2DataStorage_3.sv
FM_VARIANTS = L2DataStorage L2DataStorage_1 L2DataStorage_2 L2DataStorage_3
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
