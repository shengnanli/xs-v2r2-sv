MODULE = TageTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/TageTable.sv \
           $(RTL_DIR)/frontend/TageTable_1.sv \
           $(RTL_DIR)/frontend/TageTable_2.sv \
           $(RTL_DIR)/frontend/TageTable_3.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TageTable = 
FM_REF_DEPS_TageTable_1 = 
FM_REF_DEPS_TageTable_2 = 
FM_REF_DEPS_TageTable_3 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/TageTable.sv \
              $(GOLDEN_RTL)/TageTable_1.sv \
              $(GOLDEN_RTL)/TageTable_2.sv \
              $(GOLDEN_RTL)/TageTable_3.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv \
              $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/WrBypass.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
              $(GOLDEN_RTL)/data_mem_0_8x3.sv \
              $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
              $(GOLDEN_RTL)/array_2.sv \
              $(GOLDEN_RTL)/array_2_ext.v \
              $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
              $(GOLDEN_RTL)/array_3.sv \
              $(GOLDEN_RTL)/array_3_ext.v \
              $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = bank_wrbypasses_0_0, bank_wrbypasses_0_1, bank_wrbypasses_1_0, bank_wrbypasses_1_1, bank_wrbypasses_2_0, bank_wrbypasses_2_1…
FM_MODE = assembly
FM_ALLOWLIST ?= 13
FM_VARIANTS = TageTable TageTable_1 TageTable_2 TageTable_3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# negtest：xs_TageTable_core 折叠历史位数不变式的必失败负测（codex 0145 决策三）。
#   NEG_TT_HIST      HIST_LEN 抄错 → 三份折叠历史位数与 golden 端口不符
#   NEG_TT_NO_ANCHOR 不传 G1_*_FH_W → fail-closed
# 判据：两个都必须在 elaborate 期非零退出。
NEG_CASES = NEG_TT_HIST NEG_TT_NO_ANCHOR
.PHONY: negtest
# 注意：xs_TageTable_core 例化了 FoldedSRAMTemplate / FoldedSRAMTemplate_1 / WrBypass，
# 只编核文件的话 VCS 会先因"找不到 cell"报错 —— 那是**假通过**（负测看起来炸了，其实
# 不是不变式拦的）。所以这里编 $(UT_SRCS)(改名后的重写侧) + $(GOLDEN_SRCS)(子模块闭包)，
# 并且判据要求日志里必须出现 Error-[FEST]，把假通过堵死。
negtest: $(UT_SRCS)
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(UT_SRCS) $(GOLDEN_SRCS) negtest.sv \
	         -top neg_tt_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：抄错的参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    sed -n '/FEST/,/^$$/p' neg_$$c.log | grep -m2 'msg:' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译是失败了, 但不是 \$$fatal 不变式拦的(看 neg_$$c.log) ==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
