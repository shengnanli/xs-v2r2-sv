# 自动生成（scripts 归档见 docs/）: FoldedSRAMTemplate 家族，G1 依赖链两侧深 elaborate
MODULE = FoldedSRAMTemplate

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_3.sv \
           $(RTL_DIR)/common/SRAMTemplate_44.sv \
           $(RTL_DIR)/common/FoldedSRAMTemplate.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_45.sv \
           $(RTL_DIR)/common/FoldedSRAMTemplate_1.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_25.sv \
           $(RTL_DIR)/common/SRAMTemplate_76.sv \
           $(RTL_DIR)/common/FoldedSRAMTemplate_22.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_27.sv \
           $(RTL_DIR)/common/SRAMTemplate_78.sv \
           $(RTL_DIR)/common/FoldedSRAMTemplate_24.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_23.sv \
           $(RTL_DIR)/common/SRAMTemplate_64.sv \
           $(RTL_DIR)/common/FoldedSRAMTemplate_20.sv
TB_SRCS = tb.sv

# 厂商 SRAM 宏：golden 同源，两侧同读（唯一黑盒是宏内 array_*_ext 叶子）
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/array_4.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/array_2.sv \
                  $(GOLDEN_RTL)/array_3.sv \
                  $(GOLDEN_RTL)/array_6.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/array_4_ext.v \
              $(GOLDEN_RTL)/FoldedSRAMTemplate.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_22.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_24.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
              $(GOLDEN_RTL)/SRAMTemplate_76.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
              $(GOLDEN_RTL)/SRAMTemplate_78.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/array_2.sv \
              $(GOLDEN_RTL)/array_2_ext.v \
              $(GOLDEN_RTL)/array_3.sv \
              $(GOLDEN_RTL)/array_3_ext.v \
              $(GOLDEN_RTL)/array_6.sv \
              $(GOLDEN_RTL)/array_6_ext.v \
              $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
              $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
              $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv

FM_REF_DEPS_FoldedSRAMTemplate = SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_FoldedSRAMTemplate_1 = SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_FoldedSRAMTemplate_22 = SplittedSRAMTemplate_25.sv SRAMTemplate_76.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_FoldedSRAMTemplate_24 = SplittedSRAMTemplate_27.sv SRAMTemplate_78.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv

FM_REF_DEPS_FoldedSRAMTemplate_20 = SplittedSRAMTemplate_23.sv SRAMTemplate_64.sv sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv array_4.sv MbistClockGateCell.sv ClockGate.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 8
FM_VARIANTS = FoldedSRAMTemplate_20 FoldedSRAMTemplate FoldedSRAMTemplate_1 FoldedSRAMTemplate_22 FoldedSRAMTemplate_24

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
