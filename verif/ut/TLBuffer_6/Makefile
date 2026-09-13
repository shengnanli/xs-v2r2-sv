# TLBuffer_6 UT/FM 入口（xs_TLBuffer_ad_core 家族变体）
# 重写件只有两个：共享参数化核 + 本变体薄文件。
# Queue2_*/ram_2x* 是 golden 叶子，放 RTL_GOLDEN_DEPS：UT 两侧共用同一份定义
# （不改名、不复制），FM 时与 ref 侧同源 elaborate。
# 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
MODULE = TLBuffer_6

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_6.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
                  $(GOLDEN_RTL)/ram_2x281.sv \
                  $(GOLDEN_RTL)/ram_2x356.sv

FM_REF_DEPS_TLBuffer_6 = Queue2_TLBundleA_6.sv Queue2_TLBundleD_7.sv ram_2x281.sv ram_2x356.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_6.sv
FM_VARIANTS = TLBuffer_6

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# negtest：xs_TLBuffer_ad_core 载荷位数等式不变式的必失败负测（codex 0145 决策三）。
#   NEG_TLB_SOURCE     SOURCE_W 抄成旧值（G0->G1 真实事故形态）
#   NEG_TLB_NO_ANCHOR  不传 ram_2x<N> 锚点（改造前会拿 TLBuffer_6 的默认值蒙混）
# 判据：两个都必须在 elaborate 期非零退出。
NEG_CASES = NEG_TLB_SOURCE NEG_TLB_NO_ANCHOR
.PHONY: negtest
negtest:
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv negtest.sv \
	         -top neg_tlb_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：抄错的参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    sed -n '/FEST/,/^$$/p' neg_$$c.log | grep -m2 'msg:' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译是失败了, 但不是 \$$fatal 不变式拦的(看 neg_$$c.log) ==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
