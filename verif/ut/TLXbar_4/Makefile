MODULE = TLXbar_4

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TLXbar_4.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_4.sv
FM_VARIANTS = TLXbar_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

# ---------------------------------------------------------------------------
# negtest —— 宽度等式自检的必失败负测（证明自检有牙齿）
#
# negtest_width.sv 把 xs_TLXbar_4_core 的 SOURCE_W 传回 G0 旧值 2，核里的
# "D 多位字段合计 == golden D-mux 常量合计 76 位" 等式立刻不成立 ⇒ 必须 $fatal。
# 判据：日志里要有 "Fatal:" + "xs_TLXbar_4_core:"；出现 "NEGTEST ESCAPED" 判失败。
# 注：VCS 对 $fatal 不保证非零退出码，所以判据看日志内容而不是 rc。
# ---------------------------------------------------------------------------
.PHONY: negtest
negtest: $(UT_SRCS) negtest_width.sv | derive
	rm -rf simv_negtest simv_negtest.daidir simv_negtest.csrc
	$(VCS) -Mdir=simv_negtest.csrc $(UT_SRCS) negtest_width.sv \
	    -top tb -o simv_negtest -l compile_negtest.log
	@./simv_negtest -l negtest.log > /dev/null 2>&1 || true
	@if grep -q "NEGTEST ESCAPED" negtest.log; then \
	   echo "=== NEGTEST FAILED: SOURCE_W 写回 2 却跑到了结尾 —— 宽度自检没牙齿 ==="; exit 1; fi; \
	 if ! grep -q "xs_TLXbar_4_core:" negtest.log; then \
	   echo "=== NEGTEST FAILED: 没有出现核的宽度自检报错 ==="; tail -20 negtest.log; exit 1; fi; \
	 if ! grep -qi "^Fatal:" negtest.log; then \
	   echo "=== NEGTEST FAILED: 有报错文本但不是 \$$fatal 终止 ==="; tail -20 negtest.log; exit 1; fi; \
	 echo "=== NEGTEST PASSED: 错误 SOURCE_W 被宽度自检在 time 0 拦下 ==="; \
	 grep -A1 -m1 "^Fatal:" negtest.log
