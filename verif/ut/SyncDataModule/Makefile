MODULE = SyncDataModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DataModule.sv \
           $(RTL_DIR)/common/xs_SyncDataModule.sv \
           $(RTL_DIR)/common/DataModule_BackendPC_16entry.sv \
           $(RTL_DIR)/common/DataModule_FtqPC_16entry.sv \
           $(RTL_DIR)/common/DataModule__64entry.sv \
           $(RTL_DIR)/common/DataModule__64entry_16.sv \
           $(RTL_DIR)/common/DataModule__16entry.sv \
           $(RTL_DIR)/common/DataModule__16entry_4.sv \
           $(RTL_DIR)/common/DataModule__16entry_8.sv \
           $(RTL_DIR)/common/DataModule__16entry_12.sv \
           $(RTL_DIR)/common/DataModule__16entry_16.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate_BackendPC_64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate_FtqPC_64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry_1.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_1.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_2.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_3.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_4.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DataModule_BackendPC_16entry.sv \
              $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv \
              $(GOLDEN_RTL)/DataModule__64entry.sv \
              $(GOLDEN_RTL)/DataModule__64entry_16.sv \
              $(GOLDEN_RTL)/DataModule__16entry.sv \
              $(GOLDEN_RTL)/DataModule__16entry_4.sv \
              $(GOLDEN_RTL)/DataModule__16entry_8.sv \
              $(GOLDEN_RTL)/DataModule__16entry_12.sv \
              $(GOLDEN_RTL)/DataModule__16entry_16.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate_BackendPC_64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry_1.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_3.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_4.sv

FM_REF_DEPS_SyncDataModuleTemplate_BackendPC_64entry = DataModule_BackendPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate_FtqPC_64entry = DataModule_FtqPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry = DataModule__64entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry_1 = DataModule__64entry_16.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry = DataModule__16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_1 = DataModule__16entry_4.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_2 = DataModule__16entry_8.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_3 = DataModule__16entry_12.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_4 = DataModule__16entry_16.sv

FM_VARIANTS = DataModule_BackendPC_16entry DataModule_FtqPC_16entry DataModule__64entry DataModule__64entry_16 DataModule__16entry DataModule__16entry_4 DataModule__16entry_8 DataModule__16entry_12 DataModule__16entry_16 SyncDataModuleTemplate_BackendPC_64entry SyncDataModuleTemplate_FtqPC_64entry SyncDataModuleTemplate__1024entry SyncDataModuleTemplate__1024entry_1 SyncDataModuleTemplate__64entry SyncDataModuleTemplate__64entry_1 SyncDataModuleTemplate__64entry_2 SyncDataModuleTemplate__64entry_3 SyncDataModuleTemplate__64entry_4

include ../../../scripts/ut_common.mk

# ---------------------------------------------------------------------------
# negtest：xs_SyncDataModule 分 bank 不变式的必失败负测（codex 0145 决策三）。
#   NEG_SDM_ENTRIES   条目数抄错 → bank 数与 golden 不符
#   NEG_SDM_NO_ANCHOR 不传 G1_NUM_BANKS → fail-closed
#   NEG_SDM_ODD       bank 数不是 2 的幂 → bank_index() 越界（纯派生算术自检）
# 判据：三个都必须在 elaborate 期非零退出。
NEG_CASES = NEG_SDM_ENTRIES NEG_SDM_NO_ANCHOR NEG_SDM_ODD
.PHONY: negtest
negtest:
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(RTL_DIR)/common/xs_DataModule.sv $(RTL_DIR)/common/xs_SyncDataModule.sv \
	         negtest.sv -top neg_sdm_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：抄错的参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    sed -n '/FEST/,/^$$/p' neg_$$c.log | grep -m2 'msg:' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译是失败了, 但不是 \$$fatal 不变式拦的(看 neg_$$c.log) ==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
