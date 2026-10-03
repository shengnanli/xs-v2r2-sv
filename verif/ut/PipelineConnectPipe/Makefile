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

# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false —— ★加强，不是放宽★（2026-09-24 首跑实测，evidence/f615eb8a5e0d）
# 默认 merge_dup=true 下 native SUCCEEDED / passing 1071 / failing 0，但 6 个 ref 寄存器
# 孤儿（DFF0X：data_lsrc_3_reg[0] + data_vpu_fpu_isFP64Instr/isFpToVecInst/isReduction、
# data_vpu_isMove、data_vpu_lastUop）⇒ signoff-strict PARTIAL。成因：13 个"只装 0"字段
# （166 位）被判成 constrained-0X 常量寄存器，golden 侧 160 个 mux 形态被合并成一个代表、
# 5 个 `~leftFire & data_x` 形态各自独立；impl 侧 166 位同一形态合成一个代表，
# 两侧代表数 1 vs 6 对不上。这不是 RTL 差异（两种写法的次态函数都是 ~fire & Q）。
# 处置：逐个而不是合并后比（更严），并由 fm_map/PipelineConnectPipe.txt 把 golden 每个
# data_<f> 位与 u_core/data_reg[bit] 的双射钉死（scripts/gen_cb_connect.py 生成，勿手改；
# ut_common.mk 的 fm-% 自动识别为 FM_FIELD_MAP）。
# ★验收判据（跑前写死）★：unmatched 0/0、failing 0、passing 1071 不变、
# constant_reg 从 1 变成 166（= 那 166 位逐个被识别成常量、两侧配对、不比）。
FM_MERGE_DUP = false

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
