MODULE = IntFPToVec

# IntFPToVec（标量 → 向量 / fli / fmv，组合 FU）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子模块 FliHTable / FliSTable / FliDTable：已签核重写件（PROVEN_DIRECT），两侧白盒 ——
#   UT 里 impl 用派生的 *_xs 重写件，golden 用 golden 原件；FM impl 读重写件、ref 读 golden。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FliHTable.sv \
           $(RTL_DIR)/backend/FliSTable.sv \
           $(RTL_DIR)/backend/FliDTable.sv \
           $(RTL_DIR)/backend/IntFPToVec.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IntFPToVec.sv $(GOLDEN_RTL)/FliHTable.sv $(GOLDEN_RTL)/FliSTable.sv \
               $(GOLDEN_RTL)/FliDTable.sv

FM_VARIANTS = IntFPToVec
FM_REF_DEPS_IntFPToVec = FliHTable.sv FliSTable.sv FliDTable.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
