# EnqPolicy 家族 UT/FM 入口：发射队列入队策略，4 个位宽变体一个 UT 同测
#   EnqPolicy (W=22) / EnqPolicy_8 (W=16) / EnqPolicy_14 (W=14) / EnqPolicy_18 (W=8)
# 重写件 = 手写共享核 xs_EnqPolicy_core.sv + 4 个生成的薄 wrapper
# （scripts/gen_enqpolicy.py，带 --check）。golden 0 child，两侧都无黑盒。
MODULE = EnqPolicy

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_EnqPolicy_core.sv \
           $(RTL_DIR)/backend/EnqPolicy.sv \
           $(RTL_DIR)/backend/EnqPolicy_8.sv \
           $(RTL_DIR)/backend/EnqPolicy_14.sv \
           $(RTL_DIR)/backend/EnqPolicy_18.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/EnqPolicy.sv \
              $(GOLDEN_RTL)/EnqPolicy_8.sv \
              $(GOLDEN_RTL)/EnqPolicy_14.sv \
              $(GOLDEN_RTL)/EnqPolicy_18.sv

FM_VARIANTS = EnqPolicy EnqPolicy_8 EnqPolicy_14 EnqPolicy_18
FM_REF_DEPS_EnqPolicy    =
FM_REF_DEPS_EnqPolicy_8  =
FM_REF_DEPS_EnqPolicy_14 =
FM_REF_DEPS_EnqPolicy_18 =

# 纯组合、无寄存器：merge_dup 对它无作用，置 false 只为让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# 与仓内其它 UT 同一套编译设定（golden 的 $fatal 类断言关掉；initreg 机制打开，
# 本块无寄存器，三档 initreg 只为与全仓 9 档口径一致）。
VCS += +define+SYNTHESIS +vcs+initreg+random
