MODULE = DelayQueue

# BOP 延迟队列家族：一个参数化核 xs_DelayQueue_core + 两个薄 wrapper（地址宽 42 / 44）。
# 一个 UT 同测两对；无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/xs_DelayQueue_core.sv \
           $(RTL_DIR)/l2/DelayQueue.sv \
           $(RTL_DIR)/l2/DelayQueue_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayQueue.sv \
              $(GOLDEN_RTL)/DelayQueue_1.sv

FM_VARIANTS = DelayQueue DelayQueue_1
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（见 CONVENTIONS）。本模块全部寄存器异步复位，
# 上电初值不可观测；复位域由 FM 把关。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
