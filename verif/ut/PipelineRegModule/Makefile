MODULE = PipelineRegModule

# PipelineRegModule 家族（LoadQueueUncache 的四个出口流水寄存器）：共用核 xs_PipelineRegModule_core
# 在 rtl/memblock/PipelineRegModule.sv；_1 / _2 是薄 wrapper。wrapper、钉点与 tb 由
# scripts/gen_pipelinereg.py 生成（--check 幂等）。三者都是叶子：golden 侧 0 子模块，
# 故无 FM_REF_DEPS_*，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/PipelineRegModule.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_1.sv \
           $(RTL_DIR)/memblock/PipelineRegModule_2.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PipelineRegModule.sv \
              $(GOLDEN_RTL)/PipelineRegModule_1.sv \
              $(GOLDEN_RTL)/PipelineRegModule_2.sv

FM_VARIANTS = PipelineRegModule PipelineRegModule_1 PipelineRegModule_2

# 关掉 merge_duplicated_registers：payload 里有函数相同的位时两侧合并结果可能不同；
# 且只有关掉时 fm_predict 的 passing 模型才严格适用。这是加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 与 FM 口径一致定义 SYNTHESIS（去掉 initial 随机化块）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_pipelinereg.py --check
