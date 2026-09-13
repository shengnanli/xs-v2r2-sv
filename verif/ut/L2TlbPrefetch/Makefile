MODULE = L2TlbPrefetch

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch.sv
TB_SRCS = tb.sv

FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
FM_VARIANTS = L2TlbPrefetch

include ../../../scripts/ut_common.mk

# 同 L2TlbMissQueue：原先本文件的 simv override 编的是 $(RTL_SRCS) 原文件而非
# ut_gen/ 派生副本，tb 例化的 L2TlbPrefetch_xs 找不到（Error-[CFCILFBI]），
# 这个 UT 从未真正编过。删除 override，走 ut_common.mk 的公共规则。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
