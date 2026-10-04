MODULE = RegionWays

# ITTage 的 16 项全相联"高位区域"表（PLRU 替换）。golden 0 child，无黑盒。
# 重写件 rtl/frontend/RegionWays.sv 例化共享辅助件 rtl/common/xs_PlruReplacer.sv（树形 PLRU，golden 内联）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/frontend/RegionWays.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RegionWays.sv

FM_VARIANTS = RegionWays
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
