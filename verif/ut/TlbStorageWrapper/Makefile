MODULE = TlbStorageWrapper

RTL_DIR = ../../../rtl
# memblock_common_pkg.sv 里的 xs_tlbsw_pkg 由 TlbStorageWrapper/_1 共用（每个子系统至多一个公共包文件，见
# CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper_1.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/TLBFA.sv \
                  $(GOLDEN_RTL)/TLBFA_1.sv

FM_REF_DEPS_TlbStorageWrapper = TLBFA.sv
FM_REF_DEPS_TlbStorageWrapper_1 = TLBFA_1.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/TlbStorageWrapper.sv \
              $(GOLDEN_RTL)/TLBFA.sv \
              $(GOLDEN_RTL)/TLBFA_1.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = TlbStorageWrapper TlbStorageWrapper_1

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
