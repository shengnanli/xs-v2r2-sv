MODULE = L2TlbMissQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue.sv
TB_SRCS = tb.sv

FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv \
              $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
              $(GOLDEN_RTL)/ram_40x47.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = ram_40x47
FM_MODE = assembly
FM_ALLOWLIST ?= 1
FM_VARIANTS = L2TlbMissQueue

include ../../../scripts/ut_common.mk

# 这里**不再**自定义 simv 规则。原先本文件有一条 override:
#     simv: ...; $(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) ...
# 它直接编 $(RTL_SRCS)（原文件，wrapper 与 golden 同名）而不是 ut_gen/ 里派生出的
# _xs 副本，于是 tb 例化的 L2TlbMissQueue_xs 根本不存在：
#     Error-[CFCILFBI] Cannot find cell 'L2TlbMissQueue_xs' in liblist
# ——也就是说这个 UT 从来没有真正编译通过过（make 只打一行
# "warning: overriding recipe for target 'simv'" 就把公共规则顶掉了）。
# 删掉 override，改用 ut_common.mk 的公共规则（编 $(UT_SRCS)）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
