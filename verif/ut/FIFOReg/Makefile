# FIFOReg UT/FM 入口 —— ICacheMissUnit 的预取 MSHR 空闲队列（10 深 × 4 位）
# golden 自足叶子（14 个异步复位寄存器 + 组合读口），无子模块依赖。
MODULE = FIFOReg

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/FIFOReg.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FIFOReg.sv
FM_VARIANTS = FIFOReg

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 负测：核的指针位宽等式必须拦下"深度与指针位宽对不上"。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/FIFOReg.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：深度抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_FIFOReg_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_FIFOReg_core' negtest_compile.log || true; \
	 fi
