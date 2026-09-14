MODULE = L2TlbPrefetch

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch.sv
TB_SRCS = tb.sv

FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
FM_VARIANTS = L2TlbPrefetch
# 本目标的残余 unread 是 golden 侧 12 个 cone-dead 位（old_reqs_0..3_reg[2:0]，sector 位恒 0
# 且从不被读），逐条声明在 verif/dead_ref/L2TlbPrefetch.json ⇒ 判定走 PASS_DEAD_REF。
# ut_common.mk 的 fm-%% 规则按 wildcard 自动把该文件传给 fm_verdict.py，无需在此额外设开关。

include ../../../scripts/ut_common.mk

# 同 L2TlbMissQueue：原先本文件的 simv override 编的是 $(RTL_SRCS) 原文件而非
# ut_gen/ 派生副本，tb 例化的 L2TlbPrefetch_xs 找不到（Error-[CFCILFBI]），
# 这个 UT 从未真正编过。删除 override，走 ut_common.mk 的公共规则。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
