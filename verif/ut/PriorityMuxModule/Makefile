# PriorityMuxModule 家族 UT/FM 入口（6 变体共用 xs_PriorityMuxModule_core）
# 重写件 = 1 个参数化核 + 6 个变体薄文件（rtl/frontend/），核体不复制。
# golden 侧 6 个模块都是纯组合自足叶子（只有三元链 assign），无子模块依赖。
# 都是 Predictor 的直接子模块，各管一类预测状态：
#   PriorityMuxModule(target 50b) _4(FGH 140b) _8(GHPtr 9b)
#   _12(AFHOB 23b) _16(BrNumOH 3b) _20(new_bit 1b，只有 3 路 sel)
MODULE = PriorityMuxModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_PriorityMuxModule_core.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule_4.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule_8.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule_12.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule_16.sv \
           $(RTL_DIR)/frontend/PriorityMuxModule_20.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PriorityMuxModule.sv \
              $(GOLDEN_RTL)/PriorityMuxModule_4.sv \
              $(GOLDEN_RTL)/PriorityMuxModule_8.sv \
              $(GOLDEN_RTL)/PriorityMuxModule_12.sv \
              $(GOLDEN_RTL)/PriorityMuxModule_16.sv \
              $(GOLDEN_RTL)/PriorityMuxModule_20.sv

FM_VARIANTS = PriorityMuxModule PriorityMuxModule_4 PriorityMuxModule_8 \
              PriorityMuxModule_12 PriorityMuxModule_16 PriorityMuxModule_20

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 负测：家族核的 elaborate 期不变式必须真能拦下"少抄一个字段"。
# negtest.sv 复制 PriorityMuxModule_8 的薄文件，但把 NUM_FIELDS 抄成 1（漏掉
# value 字段）。端口表照旧、逻辑一行不改 —— 只有端口数恒等式能拦。
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_PriorityMuxModule_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：字段数抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_PriorityMuxModule_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_PriorityMuxModule_core' negtest_compile.log || true; \
	 fi
