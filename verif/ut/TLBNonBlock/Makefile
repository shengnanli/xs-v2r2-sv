MODULE = TLBNonBlock

RTL_DIR = ../../../rtl
# 一个参数化核 + 三个薄 wrapper（家族规矩：核体全仓只有一份）。
# 核文件必须排在 wrapper 之前：wrapper 的模块头 import tlbnb_pkg::*。
# memblock 公共包必须排在最前：tlbnb_pkg 住在这里（跨文件共享包按 CONVENTIONS.md
# 放 rtl/<subsys>/<subsys>_common_pkg.sv），三个 wrapper 的模块头 import 它。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/xs_TLBNonBlock_core.sv \
           $(RTL_DIR)/memblock/TLBNonBlock.sv \
           $(RTL_DIR)/memblock/TLBNonBlock_1.sv \
           $(RTL_DIR)/memblock/TLBNonBlock_2.sv
TB_SRCS = tb.sv

# 子模块处理：DelayN_7/_9、TlbStorageWrapper_1/2/3、TLBFA_1/2/3 都**不是本目标**，
# 两侧同源 elaborate（同一份 golden 文件同时进 ref 与 impl），不做黑盒。
#   · 依据：这正是 TlbStorageWrapper 那一轮对 TLBFA 用过的办法
#     （evidence/f40deba9439d/TlbStorageWrapper_1/receipt.json：
#      impl_closure 里有 golden TLBFA/TLBFA_1，matched_blackbox_pairs 为空，
#      passing 8682 / unmatched 全 0）。
#   · ★闭包里没有厂商 SRAM 宏★：TLBFA 是寄存器实现的全相联 CAM（48 路 entry 全是
#     reg），整棵闭包 grep 不到任何 array_*_ext / *_ext 例化。所以本目标不声明、
#     也不需要任何黑盒 —— 不存在"默认黑盒化"的问题。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/DelayN_9.sv \
                  $(GOLDEN_RTL)/DelayN_7.sv \
                  $(GOLDEN_RTL)/TlbStorageWrapper_1.sv \
                  $(GOLDEN_RTL)/TlbStorageWrapper_2.sv \
                  $(GOLDEN_RTL)/TlbStorageWrapper_3.sv \
                  $(GOLDEN_RTL)/TLBFA_1.sv \
                  $(GOLDEN_RTL)/TLBFA_2.sv \
                  $(GOLDEN_RTL)/TLBFA_3.sv

FM_REF_DEPS_TLBNonBlock   = DelayN_9.sv DelayN_7.sv TlbStorageWrapper_1.sv TLBFA_1.sv
FM_REF_DEPS_TLBNonBlock_1 = DelayN_9.sv DelayN_7.sv TlbStorageWrapper_2.sv TLBFA_2.sv
FM_REF_DEPS_TLBNonBlock_2 = DelayN_9.sv DelayN_7.sv TlbStorageWrapper_3.sv TLBFA_3.sv
# golden 里有成组的"值恒等的重复寄存器"（同一个 RegNext 在 Chisel 里被写了两遍：
# useReqS1Paddr/noTranslateReg、last_REG/result_ok_last_REG、pre_pf_ld/pre_pf_st…）。
# 合并重复寄存器会把这些点配成一个，配对就残缺了，所以关掉。
FM_MERGE_DUP = false
# golden 自己就带没人读的寄存器（每 lane 两个 first_issue 打拍，是 XSPerfAccumulate
# 被消掉之后的残留）。它们在两侧成对存在，开 vmucp 让 FM **实开比较**这些
# matched-unread 点（加强证明，不是 waiver）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = TLBNonBlock TLBNonBlock_1 TLBNonBlock_2

GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock.sv \
              $(GOLDEN_RTL)/TLBNonBlock_1.sv \
              $(GOLDEN_RTL)/TLBNonBlock_2.sv \
              $(RTL_GOLDEN_DEPS)

include ../../../scripts/ut_common.mk

# golden TLBFA 的 `ifndef SYNTHESIS 断言段调用未定义函数 xs_assert_v2（Scala assert
# 的落地），编译期就报 Identifier not declared；UT 两侧统一定义 SYNTHESIS 关掉断言段。
#
# ★+vcs+initreg 的两处都要给★（CONVENTIONS.md 2026-09-17 实测更正）：
#   编译期 +vcs+initreg+random 打开机制，运行期 +vcs+initreg+<值> 选取值。
#   只给运行期，VCS 报 Warning-[VICIU] 然后静默忽略 —— 那一轮等于没测。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

# ---------------------------------------------------------------------------
# 变体 _1 / _2 的独立 UT（默认 compile/run 跑变体 0）。
# 三份 tb 都由本目录的 gen_tb.py 从 golden 端口表机械生成。
# ---------------------------------------------------------------------------
tb.sv tb_1.sv tb_2.sv: gen_tb.py
	python3 gen_tb.py

define VARIANT_UT
compile$(1): simv$(1)
simv$(1): $$(UT_SRCS) tb_$(1).sv $$(GOLDEN_SRCS) $$(RTL_GOLDEN_DEPS) | portlint derive
	$$(VCS) $$(UT_SRCS) $$(GOLDEN_SRCS_UNIQ) $$(RTL_GOLDEN_DEPS) tb_$(1).sv -top tb -o simv$(1)
run$(1): simv$(1)
	@rm -f sim$(1)_$$(SEED).log sim$(1)_$$(SEED)$$(INITREG_TAG).log
	./simv$(1) +ntb_random_seed=$$(SEED) $$(SIM_ARGS) -l sim$(1)_$$(SEED).log
	@$$(if $$(INITREG_TAG),cp -f sim$(1)_$$(SEED).log sim$(1)_$$(SEED)$$(INITREG_TAG).log,:)
	@grep -q "TEST PASSED" sim$(1)_$$(SEED).log \
		&& echo "=== UT PASSED ($$(MODULE)_$(1) seed=$$(SEED) initreg=$$(INITREG)) ===" \
		|| { echo "=== UT FAILED ($$(MODULE)_$(1) seed=$$(SEED) initreg=$$(INITREG)) ==="; exit 1; }
.PHONY: compile$(1) run$(1)
endef
$(eval $(call VARIANT_UT,1))
$(eval $(call VARIANT_UT,2))

# ---------------------------------------------------------------------------
# 判别力负测（mutation test）。变异只发生在 neg_build/（已 gitignore），不进库。
# 三个方向：mutants = 注入真 bug 必须红；mutants-cov = 覆盖闸自身必须能独立判红；
# mutants-fm = 只有 FM 看得见的复位域变异，FM 必须判不等价。
# 表与判据见 mutants.py 头部说明。
# ---------------------------------------------------------------------------
.PHONY: mutants mutants-cov mutants-fm
mutants:
	python3 mutants.py
mutants-cov:
	python3 mutants.py --cov
mutants-fm:
	python3 mutants.py --fm
