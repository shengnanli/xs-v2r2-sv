MODULE = IMSIC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 依赖的已重写 IMSICGateWay 核 + pkg。
# IntFile / IMSICGateWay 子块: FM 时由 golden 侧黑盒, impl 侧也黑盒 (不引用其体);
#   IMSICGateWay 的可读核仅 UT 需要 (golden IMSICGateWay 真块编入两侧)。
RTL_SRCS = $(RTL_DIR)/uncore/imsic_pkg.sv \
           $(RTL_DIR)/uncore/IMSIC.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden RTL: IMSIC + IntFile×7 + IMSICGateWay + 3 级同步链
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSIC.sv \
              $(GOLDEN_RTL)/IntFile.sv \
              $(GOLDEN_RTL)/IMSICGateWay.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/IMSIC_wrapper.sv
FM_VARIANTS = IMSIC
# FM: IntFile / IMSICGateWay 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box
# 自动在 ref/impl 两侧黑盒化, 比对聚焦 IMSIC 自身选择/路由/聚合逻辑。
# (故 FM_REF_DEPS_IMSIC 留空, ref 侧只读 IMSIC.sv)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
