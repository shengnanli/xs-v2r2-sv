MODULE = VPPU

# 向量置换功能单元（fpu-parents lane，misc3 group）。
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：Permutation（及其下 slideupVs2VdTable /
#   slidednVs2VdTable）、VPermSrcTypeModule 均 REWRITTEN + PROVEN_DIRECT → 两侧白盒：
#   ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/slideupVs2VdTable.sv \
           $(RTL_DIR)/backend/slidednVs2VdTable.sv \
           $(RTL_DIR)/backend/Permutation.sv \
           $(RTL_DIR)/backend/VPermSrcTypeModule.sv \
           $(RTL_DIR)/backend/VPPU.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
# 列表逐项写开（fm_predict.py 等读表脚本按行解析 Makefile）
GOLDEN_SRCS = $(GOLDEN_RTL)/VPPU.sv \
              $(GOLDEN_RTL)/Permutation.sv \
              $(GOLDEN_RTL)/slideupVs2VdTable.sv \
              $(GOLDEN_RTL)/slidednVs2VdTable.sv \
              $(GOLDEN_RTL)/VPermSrcTypeModule.sv

FM_VARIANTS = VPPU
FM_REF_DEPS_VPPU = Permutation.sv slideupVs2VdTable.sv slidednVs2VdTable.sv VPermSrcTypeModule.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
