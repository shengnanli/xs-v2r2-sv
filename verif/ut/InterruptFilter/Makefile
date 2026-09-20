MODULE = InterruptFilter

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/InterruptFilter.sv
TB_SRCS  = tb.sv

# ★子依赖未闭合：DelayN_17 / DelayN_208 本轮由另一条 lane（agent/delayn-clz）重写，
#   尚未合入。这里两侧同取 golden 定义（ref 走 FM_REF_DEPS，impl 走 RTL_GOLDEN_DEPS），
#   于是本目标对这两个 child **零信息量**，证明是条件性的。
#   详见 FM_PREDICTION.md §2（UNCHANGED_GOLDEN_DEP / 子依赖未闭合）。
#   选"两侧白盒同源"而不是"两侧黑盒"：不扩大黑盒，且 glue（6 个实例的接线）真的被比出来。
FM_REF_DEPS_InterruptFilter = DelayN_17.sv DelayN_208.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/DelayN_17.sv $(GOLDEN_RTL)/DelayN_208.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/InterruptFilter.sv \
              $(GOLDEN_RTL)/DelayN_17.sv \
              $(GOLDEN_RTL)/DelayN_208.sv
FM_VARIANTS = InterruptFilter
PORTLINT_ORDER = fail

# ★FM_MERGE_DUP=false（target-scoped，见 FM_PREDICTION.md §5/§6）★
# 症状正是 fm_eq.tcl 里记的那条：「合并导致的不对称孤儿点」。
# 本模块三族 iprios 条目里，第 6/7 组的 idx 高位与 enable 是**同一个函数**
#   —— 第 6 组槽位 48..55 的 idx[5]/idx[4] 恒为 1，第 7 组槽位 56..60 的
#      idx[5]/idx[4]/idx[3] 恒为 1，而"这一组一个都没使能"时整条目归零，
#      于是 idx 高位 ≡ enable。
# 合并后两侧各自留下**不同的**幸存者名字（ref 留 enable、impl 留 idx[g][5]），
# 10(ref)/7(impl) 个孤儿点配不上，输出锥随之整片判不等。
# 关掉它是**加强不是放宽**：不黑盒、不跳点、不约束 ref，比较点只增不减。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

# 判别力负测：注入 10 个真 bug，每个都必须让 UT 变红（见 mutants.py 的说明）
.PHONY: mutants
mutants:
	python3 mutants.py
