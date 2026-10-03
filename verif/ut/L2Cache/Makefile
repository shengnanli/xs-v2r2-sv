MODULE = L2Cache

# L2Cache：TL2CHICoupledL2 的 L2 顶层 MBIST 分发级（utility.mbist.MbistPipeline 单态化，实例 mbistPl；
# 名字叫 L2Cache 但不是 L2 功能逻辑）。与 MbistPipe* / L2Slice 共用核 rtl/dft/xs_mbist_pipe_core.sv；
# 薄文件由 scripts/gen_mbist_pipe_family.py（EXTRA_MODS）生成。0 子模块、0 黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/dft/xs_mbist_pipe_core.sv $(RTL_DIR)/dft/L2Cache.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Cache.sv
FM_VARIANTS = L2Cache
# 0 子模块：FM_REF_DEPS 为空（不写赋值行，见 CONVENTIONS「空赋值吃下一行」）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期开机制、运行期选取值。唯一未复位寄存器 pipelineDataOutReg 由 tb 在首沿前同步初值。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
