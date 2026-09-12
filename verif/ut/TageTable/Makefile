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
