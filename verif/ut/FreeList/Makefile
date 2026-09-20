MODULE = FreeList

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/FreeList.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FreeList.sv
FM_VARIANTS = FreeList

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言；UT 关掉以免随机激励触发 $fatal
#
# ★两轮 initreg★：原先本目录**一轮都没跑**——编译行没有 +vcs+initreg+random
# （VCS 的初值注入要编译期开关，光给运行期 plusarg 无效），SIM_ARGS 里也没有
# 任何 initreg 参数，于是 `make run INITREG=...` 的 INITREG 根本没有被用到，
# 三个 sim_<seed>.log 一个 _initreg0 / _initregrandom 后缀都没有（ut_common 的
# INITREG_TAG 靠 SIM_ARGS 里的字样判定，空 = 不产生副本）。
# 本变体 enablePreAlloc=false，所有寄存器都在复位臂里，两轮**应当**同结果——
# 但"应当"要跑出来才算数，这正是那一轮要证明的结构结论。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random
