# DeMultiplexer 家族 UT/FM 入口（2 变体共用 xs_DeMultiplexer_core）
#   DeMultiplexer    4 出口 / 载荷 50b / 无 chosen —— ICacheMissUnit 分发取指 miss
#   DeMultiplexer_1 10 出口 / 载荷 50b / chosen 4b —— ICacheMissUnit 分发预取 miss
# golden 两个模块都是纯组合自足叶子，无子模块依赖。
MODULE = DeMultiplexer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_DeMultiplexer_core.sv \
           $(RTL_DIR)/frontend/DeMultiplexer.sv \
           $(RTL_DIR)/frontend/DeMultiplexer_1.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DeMultiplexer.sv \
              $(GOLDEN_RTL)/DeMultiplexer_1.sv

FM_VARIANTS = DeMultiplexer DeMultiplexer_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 负测：核的 elaborate 期不变式必须拦下"出口数抄错"（把 10 出口的 _1 抄成 8 出口；
# 实测被 chosen 位宽等式 clog2(NUM_OUT) 先拦下，端口数恒等式是第二道）。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_DeMultiplexer_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：出口数抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_DeMultiplexer_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_DeMultiplexer_core' negtest_compile.log || true; \
	 fi
