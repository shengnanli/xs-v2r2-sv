# DelayN 家族 UT/FM 入口（6 变体共用 xs_DelayN_core）
# 重写件 = 1 个参数化核 + 6 个变体薄文件（rtl/common/），核体不复制。
# golden 侧 6 个模块都是自足叶子（只有无复位 reg 与直连 assign），无子模块依赖。
# 覆盖的是 Frontend 例化闭包里的 6 个 DelayN 变体：
#   DelayN(5b×1) DelayN_1(1b×2) DelayN_7(219b×2) DelayN_8(274b×2)
#   DelayN_9(72b×2) DelayN_13(1b×1)
MODULE = DelayN

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN.sv \
           $(RTL_DIR)/common/DelayN_1.sv \
           $(RTL_DIR)/common/DelayN_7.sv \
           $(RTL_DIR)/common/DelayN_8.sv \
           $(RTL_DIR)/common/DelayN_9.sv \
           $(RTL_DIR)/common/DelayN_13.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN.sv \
              $(GOLDEN_RTL)/DelayN_1.sv \
              $(GOLDEN_RTL)/DelayN_7.sv \
              $(GOLDEN_RTL)/DelayN_8.sv \
              $(GOLDEN_RTL)/DelayN_9.sv \
              $(GOLDEN_RTL)/DelayN_13.sv

FM_VARIANTS = DelayN DelayN_1 DelayN_7 DelayN_8 DelayN_9 DelayN_13

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 负测：家族核的 elaborate 期不变式必须真能拦下"位宽静默写错"。
# negtest.sv 复制 DelayN_9 的薄文件，只把 io_in_bits_addr 从 50 位抄成 49 位
# （本轮真实事故的形态：端口位宽被改小，逻辑一行没动，UT 按旧位宽驱动照过）。
# 判据：编译期报错 或 运行期 time 0 $fatal 都算 PASS；跑通了才是 FAIL。
.PHONY: negtest
negtest: $(UT_SRCS)
	@rm -rf simv_neg simv_neg.daidir simv_neg_csrc negtest_compile.log negtest_run.log
	@if $(VCS) -Mdir=simv_neg_csrc $(UT_GEN_DIR)/xs_DelayN_core.sv negtest.sv \
	      -top neg_tb -o simv_neg > negtest_compile.log 2>&1; then \
	   ./simv_neg -l negtest_run.log > /dev/null 2>&1; \
	   if grep -qE 'NEGTEST_UNREACHED' negtest_run.log; then \
	     echo "=== NEGTEST FAILED：位宽抄错竟然跑通了，不变式形同虚设 ==="; exit 1; \
	   else \
	     echo "=== NEGTEST PASSED（运行期 \$$fatal 拦下）==="; \
	     grep -m2 -E 'Fatal|xs_DelayN_core' negtest_run.log || true; \
	   fi; \
	 else \
	   echo "=== NEGTEST PASSED（编译期就拦下）==="; \
	   grep -m2 -E 'Error|xs_DelayN_core' negtest_compile.log || true; \
	 fi
