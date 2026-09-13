# DelayNWithValid 家族 UT/FM 入口（2 变体共用 xs_DelayNWithValid_core）
#   DelayNWithValid    载荷 50b（FTB 预测目标地址）
#   DelayNWithValid_1  载荷 60b（FTB 的 FTBEntry）
# golden 两个模块都是自足叶子（3 个寄存器 + 直连 assign），无子模块依赖。
MODULE = DelayNWithValid

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayNWithValid.sv \
           $(RTL_DIR)/common/DelayNWithValid_1.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayNWithValid.sv \
              $(GOLDEN_RTL)/DelayNWithValid_1.sv

FM_VARIANTS = DelayNWithValid DelayNWithValid_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# 负测：核的位宽等式必须拦下"载荷位宽抄错"（把 _1 的 60b 载荷里的一个字段抄窄）。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_DelayNWithValid_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：位宽抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_DelayNWithValid_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_DelayNWithValid_core' negtest_compile.log || true; \
	 fi
