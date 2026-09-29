MODULE = L2DirectoryVariants

# L2Directory_1 / _2 / _3：Directory_1..3 层的 MBIST 分发普通叶子，与 MbistPipe* 家族共用核
# rtl/dft/xs_mbist_pipe_core.sv，薄文件由 scripts/gen_mbist_pipe_family.py（EXTRA_MODS）生成。
# （slice 0 的 L2Directory 另有已签核的手写件 rtl/uncore/L2Directory.sv，见 verif/ut/L2Directory。）
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/L2Directory_1.sv $(RTL_DIR)/dft/L2Directory_2.sv $(RTL_DIR)/dft/L2Directory_3.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Directory_1.sv $(GOLDEN_RTL)/L2Directory_2.sv $(GOLDEN_RTL)/L2Directory_3.sv
FM_VARIANTS = L2Directory_1 L2Directory_2 L2Directory_3
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
