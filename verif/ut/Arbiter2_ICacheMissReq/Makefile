# ICache 固定优先级仲裁器家族 UT/FM 入口（2 变体共用 xs_FixedPriorityArbiter_core）
#   Arbiter2_ICacheMissReq  2 入口 / 载荷 50b —— ICacheMainPipe、IPrefetchPipe 各一处
#   Arbiter5_MSHRAcquire    5 入口 / 载荷 60b —— ICacheMissUnit
# golden 两个模块都是纯组合自足叶子，无子模块依赖。
MODULE = Arbiter2_ICacheMissReq

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/frontend/Arbiter2_ICacheMissReq.sv \
           $(RTL_DIR)/frontend/Arbiter5_MSHRAcquire.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Arbiter2_ICacheMissReq.sv \
              $(GOLDEN_RTL)/Arbiter5_MSHRAcquire.sv

FM_VARIANTS = Arbiter2_ICacheMissReq Arbiter5_MSHRAcquire

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 负测：核的端口数恒等式必须拦下"入口数抄错"（把 5 入口的 Arbiter5 抄成 4 入口）。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_FixedPriorityArbiter_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：入口数抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_FixedPriorityArbiter_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_FixedPriorityArbiter_core' negtest_compile.log || true; \
	 fi
