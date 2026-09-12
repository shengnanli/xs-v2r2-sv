# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = RNXbar

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/RNXbar.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/RNXbar.sv \
              $(GOLDEN_RTL)/FastArbiter_26.sv \
              $(GOLDEN_RTL)/FastArbiter_29.sv \
              $(GOLDEN_RTL)/FastArbiter_30.sv \
              $(GOLDEN_RTL)/FastArbiter_35.sv \
              $(GOLDEN_RTL)/FastArbiter_43.sv \
              $(GOLDEN_RTL)/FastArbiter_45.sv

FM_VARIANTS = RNXbar
FM_REF_DEPS_RNXbar = FastArbiter_26.sv FastArbiter_29.sv FastArbiter_30.sv FastArbiter_35.sv FastArbiter_43.sv FastArbiter_45.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
