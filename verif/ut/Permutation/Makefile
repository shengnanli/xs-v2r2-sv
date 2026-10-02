MODULE = Permutation

RTL_DIR  = ../../../rtl
# 本体（手写核 + wrapper）+ 两个 child 查表的重写件（本 lane 已签：两侧白盒，
# ref 侧 golden slide*Vs2VdTable，impl 侧这里的重写件）。
RTL_SRCS = $(RTL_DIR)/backend/slideupVs2VdTable.sv \
           $(RTL_DIR)/backend/slidednVs2VdTable.sv \
           $(RTL_DIR)/backend/Permutation.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/Permutation.sv \
              $(GOLDEN_RTL)/slideupVs2VdTable.sv \
              $(GOLDEN_RTL)/slidednVs2VdTable.sv
FM_VARIANTS = Permutation
FM_REF_DEPS_Permutation = slideupVs2VdTable.sv slidednVs2VdTable.sv

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期由 INITREG 选取值（0 / random / <数值种子>）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
