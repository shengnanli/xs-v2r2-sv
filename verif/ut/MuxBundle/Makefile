# MuxBundle UT/FM 入口 —— ICacheMissUnit 的 10 路预取 Acquire 出口（按下标选一路）
# golden 纯组合自足叶子，无子模块依赖。
MODULE = MuxBundle

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/MuxBundle.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MuxBundle.sv
FM_VARIANTS = MuxBundle
# 纯组合、0 寄存器：关 merge 不改变任何比较点（比较点 = 71 个输出位），只让 fm_predict 模型严格适用。
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。本模块无寄存器，
# 三档（0 / random / <seed>017）只为与全仓 UT 口径一致，不期望结果随档变化。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

# 负测：核的 source 空间等式必须拦下"source 基址抄错"。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/MuxBundle.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：source 基址抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_MuxBundle_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_MuxBundle_core' negtest_compile.log || true; \
	 fi
