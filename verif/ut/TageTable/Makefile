MODULE = TageTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/TageTable.sv \
           $(RTL_DIR)/frontend/TageTable_1.sv \
           $(RTL_DIR)/frontend/TageTable_2.sv \
           $(RTL_DIR)/frontend/TageTable_3.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 子模块边界：**两侧同源白盒**，不是黑盒（2026-09-14 改，worker agent/tage）
#
# 原先四个变体都走 assembly + 13 个对称黑盒(FoldedSRAMTemplate / FoldedSRAMTemplate_1 /
# WrBypass)，类别 green_child。实测那条路**现在走不通**，而且卡点不是 unread：
#   - 三个子模块都不是厂商宏(不在 verif/vendor_boundary.tsv)，只能归 green_child；
#   - green_child 自 codex 0157 D57 起必须持有 tracked 证书
#     (verif/proof_certificates/<child>.json)，而全仓一份证书都还没有，且
#     verif/proof_certificates/POLICY.json 的 freeze_commit 仍是 null ——
#     validator 按设计 fail-closed(green_child_policy_no_freeze_commit)；
#   - 于是 fm_verdict 在**黑盒检查这一步**就判 PARTIAL
#     (assembly_green_child_certificate_not_in_commit:FoldedSRAMTemplate)，
#     根本走不到后面的 unread/dead_ref 判定。填 freeze_commit 是 integrator 的动作。
# 改法不是等证书，而是**把抽象去掉**：golden 子模块闭包同时进 ref 与 impl 两侧
# elaborate（IMSIC 消黑盒的同一套做法）。于是
#   - 子模块不再是黑盒，本层 glue + 子模块内部一起受验（证明只会更强）；
#   - 剩下的唯一黑盒是 array_2_ext / array_3_ext（SRAM 编译器行为级叶子，已在
#     verif/vendor_boundary.tsv 逐条审定，两侧读同一份 .v），类别 vendor_macro，
#     不需要任何证书；
#   - impl 侧例化子模块的端口连线这次是真被检查了（黑盒时端口错配看不出来）。
# 重写版子模块(rtl/common/FoldedSRAMTemplate*.sv、rtl/frontend/WrBypass.sv)各有独立
# target 与独立签核，**不**进本目标闭包——本目标不重复证明它们。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_44.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
                  $(GOLDEN_RTL)/array_2.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_45.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
                  $(GOLDEN_RTL)/array_3.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/WrBypass.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
                  $(GOLDEN_RTL)/data_mem_0_8x3.sv

# UT 双例化只替换 TageTable 本体；子模块闭包由 RTL_GOLDEN_DEPS 提供（两侧共用），
# 这里只剩 golden 本体与厂商叶子行为模型（*_ext.v 只给 VCS，不进 FM 任一侧）。
GOLDEN_SRCS = $(GOLDEN_RTL)/TageTable.sv \
              $(GOLDEN_RTL)/TageTable_1.sv \
              $(GOLDEN_RTL)/TageTable_2.sv \
              $(GOLDEN_RTL)/TageTable_3.sv \
              $(GOLDEN_RTL)/array_2_ext.v \
              $(GOLDEN_RTL)/array_3_ext.v

# FM ref 侧闭包 = 与 RTL_GOLDEN_DEPS 同一组文件（同名同字节），impl 侧经 RTL_GOLDEN_DEPS
# 并入。两侧同源 ⇒ 子模块白盒且天然对称。四个变体的子模块完全相同（各 1×
# FoldedSRAMTemplate + 4× FoldedSRAMTemplate_1 + 8× WrBypass），故四份依赖一致。
FM_REF_DEPS_TageTable   = FoldedSRAMTemplate.sv SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv \
                       sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv \
                       FoldedSRAMTemplate_1.sv SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv \
                       sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv \
                       MbistClockGateCell.sv ClockGate.sv \
                       WrBypass.sv IndexableCAMTemplate.sv data_mem_0_8x3.sv
FM_REF_DEPS_TageTable_1 = FoldedSRAMTemplate.sv SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv \
                       sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv \
                       FoldedSRAMTemplate_1.sv SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv \
                       sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv \
                       MbistClockGateCell.sv ClockGate.sv \
                       WrBypass.sv IndexableCAMTemplate.sv data_mem_0_8x3.sv
FM_REF_DEPS_TageTable_2 = FoldedSRAMTemplate.sv SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv \
                       sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv \
                       FoldedSRAMTemplate_1.sv SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv \
                       sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv \
                       MbistClockGateCell.sv ClockGate.sv \
                       WrBypass.sv IndexableCAMTemplate.sv data_mem_0_8x3.sv
FM_REF_DEPS_TageTable_3 = FoldedSRAMTemplate.sv SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv \
                       sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv \
                       FoldedSRAMTemplate_1.sv SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv \
                       sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv \
                       MbistClockGateCell.sv ClockGate.sv \
                       WrBypass.sv IndexableCAMTemplate.sv data_mem_0_8x3.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
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
# 不是不变式拦的）。所以这里编 $(UT_SRCS)(改名后的重写侧) + $(RTL_GOLDEN_DEPS)(子模块闭包,
# 2026-09-14 起子模块从 GOLDEN_SRCS 移到这里) + $(GOLDEN_SRCS)(golden 本体与厂商叶子)，
# 并且判据要求日志里必须出现 Error-[FEST]，把假通过堵死。
negtest: $(UT_SRCS)
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(UT_SRCS) $(RTL_GOLDEN_DEPS) $(GOLDEN_SRCS) negtest.sv \
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
