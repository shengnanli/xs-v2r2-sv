MODULE = Pipeline

RTL_DIR = ../../../rtl
# 子模块 Queue1_L1PrefetchReq 已独立签核（agent/fe-mem-misc），两侧白盒：ref 读 golden、impl 读重写件。
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/memblock/Queue1_L1PrefetchReq.sv \
           $(RTL_DIR)/memblock/Pipeline.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Pipeline = Queue1_L1PrefetchReq.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline.sv \
              $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv
FM_VARIANTS = Pipeline

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
