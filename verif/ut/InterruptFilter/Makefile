MODULE = InterruptFilter

RTL_DIR  = ../../../rtl
# ★子依赖已闭合（2026-09-20 升级，集成者裁定 3）★
#   DelayN_17 / DelayN_208 由 DelayN lane 重写并合入 main（`80617800`），
#   impl 侧从此用**重写件**，不再喂 golden 字节：
#     rtl/common/DelayN_17.sv / DelayN_208.sv（薄 wrapper）+ xs_DelayN_core.sv（参数化核）
#   于是 FM_REF_DEPS（golden 侧）与 impl 侧是**两套不同的字节**，这两个 child
#   对本 target 不再是零信息量，`UNCHANGED_GOLDEN_DEP` 随之摘掉。
#   升级前的配置（两侧同取 golden）与它的条件性结论留在 FM_PREDICTION.md §2/§12.1。
#   ★换了 impl 闭包就是换了前提，必须重出证 —— 不许只改台账不重跑（裁定原话）。★
RTL_SRCS = $(RTL_DIR)/backend/InterruptFilter.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_17.sv \
           $(RTL_DIR)/common/DelayN_208.sv
TB_SRCS  = tb.sv

FM_REF_DEPS_InterruptFilter = DelayN_17.sv DelayN_208.sv
# ★这里**不写** `RTL_GOLDEN_DEPS =`★（ut_common.mk 已有 `RTL_GOLDEN_DEPS ?=` 默认空）。
# 实测：写成空赋值会被仓里按行正则读 Makefile 的脚本误读 ——
#   scripts/coverage_three_axis.py 的 golden_reuse_set() 用
#   `^RTL_GOLDEN_DEPS\s*=\s*(.*)$`，而 `\s` 吃换行，于是空赋值后面那一行
#   （`GOLDEN_SRCS = .../InterruptFilter.sv ...`）被当成了本变量的值，
#   InterruptFilter 因此被误判成 GOLDEN_REUSE（"按裁定不算重写完成"）。
# make 的展开值两种写法完全一样（已 `make --eval` 逐字对照），删掉纯粹是消歧义。

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
