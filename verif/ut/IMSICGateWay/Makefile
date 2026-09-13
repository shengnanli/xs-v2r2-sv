MODULE = IMSICGateWay

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IMSICGateWay.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IMSICGateWay.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = msi_vld_req_cpu_chain
FM_MODE = assembly
FM_ALLOWLIST ?= 1
FM_VARIANTS = IMSICGateWay

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

# ---------------------------------------------------------------------------
# negtest —— 宽度等式自检的必失败负测（证明自检有牙齿）
#
# 编 negtest_width.sv：它把 xs_IMSICGateWay_core 的源头参数写回 G0 旧值
# (geilen=5)，而 golden 现读常量不动 ⇒ 核里的宽度等式必须 $fatal。
# 判据：run 必须**非零退出**，且日志里出现核的宽度报错；跑到 "NEGTEST ESCAPED"
# 或正常退出一律判负测失败。
# ---------------------------------------------------------------------------
.PHONY: negtest
negtest: $(UT_SRCS) negtest_width.sv $(GOLDEN_SRCS) | derive
	rm -rf simv_negtest simv_negtest.daidir simv_negtest.csrc
	$(VCS) -Mdir=simv_negtest.csrc $(UT_SRCS) $(GOLDEN_SRCS) negtest_width.sv \
	    -top tb -o simv_negtest -l compile_negtest.log
	@./simv_negtest -l negtest.log > /dev/null 2>&1 || true
	@if grep -q "NEGTEST ESCAPED" negtest.log; then \
	   echo "=== NEGTEST FAILED: 参数写回 G0 旧值却跑到了结尾 —— 宽度自检没牙齿 ==="; exit 1; fi; \
	 if ! grep -q "xs_IMSICGateWay_core:" negtest.log; then \
	   echo "=== NEGTEST FAILED: 没有出现核的宽度自检报错 ==="; tail -20 negtest.log; exit 1; fi; \
	 if ! grep -qi "^Fatal:" negtest.log; then \
	   echo "=== NEGTEST FAILED: 有报错文本但不是 \$$fatal 终止 ==="; tail -20 negtest.log; exit 1; fi; \
	 echo "=== NEGTEST PASSED: 错误参数被宽度自检在 time 0 拦下 ==="; \
	 grep -A1 -m1 "^Fatal:" negtest.log
