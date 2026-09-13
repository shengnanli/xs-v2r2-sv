# IndexableCAMTemplate 家族 UT/FM 入口（5 变体共用 xs_IndexableCAMTemplate_core）
# 重写件 = 1 个参数化核（在基础变体文件里）+ 4 个变体薄文件；核体不复制。
# golden 侧 5 个模块都是自足叶子（只有无复位寄存器 + 相等比较），无子模块依赖。
MODULE = IndexableCAMTemplate

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/IndexableCAMTemplate.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate_32.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate_33.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate_41.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate_43.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv

FM_VARIANTS = IndexableCAMTemplate IndexableCAMTemplate_32 IndexableCAMTemplate_33 \
              IndexableCAMTemplate_41 IndexableCAMTemplate_43

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 负测：家族核的 elaborate 期不变式必须真能拦下错参数。
# negtest.sv 故意把 _33（16 项 / 8 位键）的参数抄成基础变体（8 项 / 9 位键），
# 端口表照旧 —— 逻辑一行不改、UT 也测不出，只有核里的 $bits 契约等式能拦。
# 判据：编译期报错 或 运行期 time 0 $fatal，二者之一都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_SRCS) negtest.sv -top neg_tb -o simv_neg \
	      > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：错参数竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_IndexableCAMTemplate_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_IndexableCAMTemplate_core' negtest_compile.log || true; \
	 fi
