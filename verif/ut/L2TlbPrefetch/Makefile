MODULE = L2TlbPrefetch

# L2TLB 的"下一行"页表预取器（lane l2tlb-leaves 重写）：训练 / 去重 / 发出 三节，单叶子无子模块。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch.sv
TB_SRCS = tb.sv

FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
FM_VARIANTS = L2TlbPrefetch
# 本目标的残余 unread 是 golden 侧 12 个 cone-dead 位（old_reqs_0..3_reg[2:0]，sector 位恒 0
# 且从不被读），逐条声明在 verif/dead_ref/L2TlbPrefetch.json ⇒ 判定走 PASS_DEAD_REF。
# ut_common.mk 的 fm-%% 规则按 wildcard 自动把该文件传给 fm_verdict.py，无需在此额外设开关。

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两处都要给：编译期打开机制，运行期选取值（0 / random / <seed>017 三档，见 CONVENTIONS initreg 节）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
