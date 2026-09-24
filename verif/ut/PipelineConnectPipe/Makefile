# PipelineConnectPipe UT —— CtrlBlock 译码→重命名单拍流水缓冲（6 例化同一模块，一个 target）。
#
# 重写核 xs_PipelineConnectPipe_core 与 golden 同名 wrapper 同在 rtl/backend/PipelineConnectPipe.sv
# （单文件规范；由 scripts/gen_cb_connect.py 从 G1 golden 端口表生成）。
# 它是老式 PipelineConnect（in_ready = out_ready），**不是** NewPipelineConnectPipe 家族，
# 所以不依赖 rtl/common/PipelineConnect.sv。
MODULE = PipelineConnectPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/PipelineConnectPipe.sv
TB_SRCS  = tb.sv

# golden 自包含（0 子模块），不需要任何 FM_REF_DEPS_*。
GOLDEN_SRCS = $(GOLDEN_RTL)/PipelineConnectPipe.sv

FM_VARIANTS = PipelineConnectPipe

# 端口表逐行照 golden 生成（含顺序），把 ORDER 从 warn 升成硬闸。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两档 initreg：编译期打开机制，运行期 make run INITREG=+vcs+initreg+0 / +1 选取值。
# ★双例化 UT 不用 +random★：golden 与重写件是两个独立例化，random 给各自不同初值，
# 数据寄存器（无复位）在首个 fire 前两侧初态就不同，比出来的差异与重写无关。
# +0 / +1 都是常量档，两侧必然同初态、又互不相同。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+0

# ---------------------------------------------------------------------------
# negtest：核的 G1 锚点不变式必失败负测。
#   NEG_NARROW    payload 比锚点少 1 位      NEG_NO_ANCHOR 不传锚点
# 判据：两个都必须在 elaborate 期非零退出（Error-[FEST]）。**跑不失败就说明闸是摆设**。
# ---------------------------------------------------------------------------
NEG_CASES = NEG_NARROW NEG_NO_ANCHOR
.PHONY: negtest
negtest:
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(RTL_SRCS) negtest.sv -top neg_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：错误参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    grep -m1 -A3 'FEST' neg_$$c.log | grep -m1 'xs_' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译失败但不是 \$$fatal 不变式拦的（看 neg_$$c.log）==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
