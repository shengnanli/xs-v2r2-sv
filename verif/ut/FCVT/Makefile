MODULE = FCVT

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FCVT.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FPCVT 及其闭包（fudian 浮点转换器，不是本轮重写目标）：
# 已逐字节核对 G0 与 G1 这 7 个文件完全一致，故两侧同源 elaborate，不设黑盒。
FCVT_LEAVES = FPCVT.sv CVT64.sv FP_INCVT.sv \
              RoundingUnit_3.sv RoundingUnit_4.sv \
              ShiftRightJam.sv CLZ_6.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FCVT.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FCVT_LEAVES))

FM_VARIANTS = FCVT
FM_REF_DEPS_FCVT = $(FCVT_LEAVES)

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS
