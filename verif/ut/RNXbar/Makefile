# 自动生成：scripts/gen_rnxbar.py —— 勿手改
MODULE = RNXbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/rnxbar_pkg.sv \
           $(RTL_DIR)/uncore/RNXbar.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden RNXbar + 15 个 FastArbiter 黑盒 (6 种类型; 两侧共用同一例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/RNXbar.sv \
              $(GOLDEN_RTL)/FastArbiter_30.sv \
              $(GOLDEN_RTL)/FastArbiter_36.sv \
              $(GOLDEN_RTL)/FastArbiter_31.sv \
              $(GOLDEN_RTL)/FastArbiter_44.sv \
              $(GOLDEN_RTL)/FastArbiter_27.sv \
              $(GOLDEN_RTL)/FastArbiter_46.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/RNXbar_wrapper.sv
FM_VARIANTS = RNXbar
# FM: 6 种 FastArbiter 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在 ref/impl
# 两侧自动黑盒化并按连接配对; 比对聚焦 RNXbar 自身路由/解复用/snoop 跟踪逻辑。
# (故 FM_REF_DEPS_RNXbar 留空, ref 侧只读 RNXbar.sv)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
