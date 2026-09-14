MODULE = IMSICGateWay

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IMSICGateWay.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 消黑盒 (2026-09-14)：本目标此前声明 proof_mode=assembly + 对称黑盒边界
# msi_vld_req_cpu_chain（3 级异步复位同步链）。assembly 需要 verif/allow/<top>.json
# 逐对象声明，缺声明即 PARTIAL；而这个黑盒本来就没必要——
#   AsyncResetSynchronizerShiftReg_w1_d3_i0 不是厂商宏、也不是本轮的独立签核目标
#   （docs/coverage_three_axis.tsv 记它 GOLDEN_REUSE / PROVEN_IN_CONE），
#   golden 源码就在 G1 里，两侧同源 elaborate 即可白盒受验。
# 做法与 verif/ut/DebugModule 一致：放进 RTL_GOLDEN_DEPS（impl 侧）+
# FM_REF_DEPS_<top>（ref 侧），FM 于是不再有任何黑盒，模式回到 signoff-strict。
# 效果：passing 39 -> 45（同步链 3 级 DFF 两侧真比），failing/unmatched/unread 仍全 0。
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                  $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

FM_REF_DEPS_IMSICGateWay = AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
                           AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSICGateWay.sv
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
negtest: $(UT_SRCS) negtest_width.sv $(GOLDEN_SRCS) $(RTL_GOLDEN_DEPS) | derive
	rm -rf simv_negtest simv_negtest.daidir simv_negtest.csrc
	$(VCS) -Mdir=simv_negtest.csrc $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_SRCS) negtest_width.sv \
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
