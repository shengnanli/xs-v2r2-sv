# 自动生成：scripts/gen_snxbar.py —— 勿手改
MODULE = SNXbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/snxbar_pkg.sv \
           $(RTL_DIR)/uncore/SNXbar.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden SNXbar + 两个 FastArbiter 黑盒仲裁器 (两侧共用同一例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/SNXbar.sv \
              $(GOLDEN_RTL)/FastArbiter_47.sv \
              $(GOLDEN_RTL)/FastArbiter_46.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SNXbar_wrapper.sv
FM_VARIANTS = SNXbar
# FM: FastArbiter_46/47 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在
# ref/impl 两侧自动黑盒化并按同名配对; 比对聚焦 SNXbar 自身路由/解复用逻辑。
# (故 FM_REF_DEPS_SNXbar 留空, ref 侧只读 SNXbar.sv)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
