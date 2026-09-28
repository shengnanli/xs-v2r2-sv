MODULE = L2Slice

# L2Slice / L2Slice_1..3：coupledL2 Slice 层的 MBIST 分发中间节点（utility.mbist.MbistPipeline
# 单态化），与 MbistPipe* 家族共用核 rtl/dft/xs_mbist_pipe_core.sv；四个薄文件由
# scripts/gen_mbist_pipe_family.py（EXTRA_MODS）生成。0 子模块、0 黑盒。
RTL_DIR  = ../../../rtl
VARIANTS = L2Slice L2Slice_1 L2Slice_2 L2Slice_3
RTL_SRCS = $(RTL_DIR)/dft/xs_mbist_pipe_core.sv $(addprefix $(RTL_DIR)/dft/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L2Slice.sv $(GOLDEN_RTL)/L2Slice_1.sv $(GOLDEN_RTL)/L2Slice_2.sv $(GOLDEN_RTL)/L2Slice_3.sv
FM_VARIANTS = L2Slice L2Slice_1 L2Slice_2 L2Slice_3
# 0 子模块：各变体 FM_REF_DEPS 为空（不写赋值行，见 CONVENTIONS「空赋值吃下一行」）
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
