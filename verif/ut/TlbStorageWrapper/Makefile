MODULE = TlbStorageWrapper

RTL_DIR = ../../../rtl
# memblock_common_pkg.sv 里的 xs_tlbsw_pkg 由 TlbStorageWrapper/_1 共用（每个子系统至多一个公共包文件，见
# CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
# 家族形态（CONVENTIONS「变体家族」）：一个参数化核文件 + 每变体一个薄文件。
# xs_TlbStorageWrapper_core.sv 是 2026-09-20 从 TlbStorageWrapper.sv 原样搬出来的
# （模块正文 sha256 不变，见该次提交）。搬之前核住在变体 0 的文件里，新加的 _2/_3
# 只能靠依赖变体 0 才编得动 —— 那既不是核文件也不是薄文件。
#
# ★_2/_3 的内层阵列用**重写件** TLBFA_2/_3，不是 golden★
#   变体 0/_1 当年（f40deba）把 golden TLBFA.sv / TLBFA_1.sv 读进 impl 侧，那是
#   **golden 逻辑复用**；按现行判据（CONVENTIONS「黑盒边界要审」）这是 NO-GO。
#   TLBFA_2/_3 现在已经是重写件且已独立签核，所以 _2/_3 这两个目标的 impl 侧
#   **全是重写件、一个 golden 字节都没有**，证明是自足的、不挂任何条件绿。
#   变体 0/_1 的既有闭包本轮不动（不在本 lane 的目标里），故 golden TLBFA{,_1}.sv
#   仍留在 RTL_GOLDEN_DEPS。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/xs_TlbStorageWrapper_core.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper_1.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper_2.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper_3.sv \
           $(RTL_DIR)/memblock/xs_TLBFA_core.sv \
           $(RTL_DIR)/memblock/TLBFA_2.sv \
           $(RTL_DIR)/memblock/TLBFA_3.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/TLBFA.sv \
                  $(GOLDEN_RTL)/TLBFA_1.sv

FM_REF_DEPS_TlbStorageWrapper = TLBFA.sv
FM_REF_DEPS_TlbStorageWrapper_1 = TLBFA_1.sv
FM_REF_DEPS_TlbStorageWrapper_2 = TLBFA_2.sv
FM_REF_DEPS_TlbStorageWrapper_3 = TLBFA_3.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/TlbStorageWrapper.sv \
              $(GOLDEN_RTL)/TLBFA.sv \
              $(GOLDEN_RTL)/TLBFA_1.sv \
              $(GOLDEN_RTL)/TLBFA_2.sv \
              $(GOLDEN_RTL)/TLBFA_3.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = TlbStorageWrapper TlbStorageWrapper_1 TlbStorageWrapper_2 TlbStorageWrapper_3

include ../../../scripts/ut_common.mk

# 变体 _1 的独立 UT（默认 compile/run 跑变体 0；这里是 TlbStorageWrapper_1）
#
# 2026-09-12 diag-tlb-txreq 修：原规则指向三个**不存在**的文件
# （TlbStorageWrapper_1_wrapper.sv / variants_xs.sv / tb_1.sv），即 _1 从来没有过
# 能跑的 UT，虽然它是 FM_VARIANTS 里声明要签核的顶层。现在 tb_1.sv 由本目录的
# gen_tb_1.py 从 golden TlbStorageWrapper_1.sv 端口表机械生成，两侧例化改成和
# 变体 0 同一套（derive 出来的 ut_gen/ 副本 + golden 闭包）。
compile1: simv1
simv1: $(UT_SRCS) tb_1.sv $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS) | portlint derive
	$(VCS) $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/TlbStorageWrapper_1.sv tb_1.sv -top tb -o simv1
run1: simv1
	./simv1 +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim1_$(SEED).log
	@grep -q "TEST PASSED" sim1_$(SEED).log && echo "=== UT PASSED (TlbStorageWrapper_1 seed=$(SEED)) ===" \
		|| { echo "=== UT FAILED (TlbStorageWrapper_1 seed=$(SEED)) ==="; exit 1; }
.PHONY: compile1 run1


# golden TLBFA 的 `ifndef SYNTHESIS 断言段调用未定义函数 xs_assert_v2（Scala assert
# 的落地），编译期就报 Identifier not declared；UT 两侧统一定义 SYNTHESIS 关掉断言段。
# （2026-09-12 diag-tlb-txreq 补：本 UT 此前卡在 portlint，从没走到 VCS，这个坑一直没暴露。）
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0


# ---------------------------------------------------------------------------
# 变体 _2 / _3 的独立 UT（tb_2.sv / tb_3.sv 由 gen_tb_variant.py 从 golden 端口表生成）
#
# 两侧例化：golden TlbStorageWrapper_<n> + golden TLBFA_<n>
#      vs   重写 TlbStorageWrapper_<n>_xs + 重写 TLBFA_<n>_xs（derive 改的名）。
# RTL_GOLDEN_DEPS 仍要给：UT_SRCS 里含变体 0/_1 的重写 wrapper，它们例化的 TLBFA /
# TLBFA_1 是 golden 名（没进 RTL_SRCS 所以 derive 不改它），不给就 elaborate 缺模块。
# ---------------------------------------------------------------------------
compile2: simv2
simv2: $(UT_SRCS) tb_2.sv $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS) | portlint derive
	$(VCS) $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/TLBFA_2.sv $(GOLDEN_RTL)/TlbStorageWrapper_2.sv tb_2.sv -top tb -o simv2
run2: simv2
	./simv2 +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim2_$(SEED).log
	@grep -q "TEST PASSED" sim2_$(SEED).log && echo "=== UT PASSED (TlbStorageWrapper_2 seed=$(SEED)) ===" \
		|| { echo "=== UT FAILED (TlbStorageWrapper_2 seed=$(SEED)) ==="; exit 1; }

compile3: simv3
simv3: $(UT_SRCS) tb_3.sv $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS) | portlint derive
	$(VCS) $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_RTL)/TLBFA_3.sv $(GOLDEN_RTL)/TlbStorageWrapper_3.sv tb_3.sv -top tb -o simv3
run3: simv3
	./simv3 +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim3_$(SEED).log
	@grep -q "TEST PASSED" sim3_$(SEED).log && echo "=== UT PASSED (TlbStorageWrapper_3 seed=$(SEED)) ===" \
		|| { echo "=== UT FAILED (TlbStorageWrapper_3 seed=$(SEED)) ==="; exit 1; }
.PHONY: compile2 run2 compile3 run3
