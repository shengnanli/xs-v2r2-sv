# 自动生成（scripts 归档见 docs/）: SplittedSRAMTemplate 家族，G1 依赖链两侧深 elaborate
MODULE = SplittedSRAMTemplate

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate.sv \
           $(RTL_DIR)/common/SRAMTemplate_2.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_1.sv \
           $(RTL_DIR)/common/SRAMTemplate_36.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_2.sv \
           $(RTL_DIR)/common/SRAMTemplate_44.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_3.sv \
           $(RTL_DIR)/common/SRAMTemplate_45.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_76.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_25.sv \
           $(RTL_DIR)/common/SRAMTemplate_78.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_27.sv \
           $(RTL_DIR)/common/SRAMTemplate_64.sv \
           $(RTL_DIR)/common/SplittedSRAMTemplate_23.sv
TB_SRCS = tb.sv

# 厂商 SRAM 宏：golden 同源，两侧同读（唯一黑盒是宏内 array_*_ext 叶子）
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/array_4.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/array.sv \
                  $(GOLDEN_RTL)/array_1.sv \
                  $(GOLDEN_RTL)/array_2.sv \
                  $(GOLDEN_RTL)/array_3.sv \
                  $(GOLDEN_RTL)/array_6.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

# codex 0222/0226：impl 侧 MC 存储模型必须与 ref 侧逐字节共读（proof_certificate 的 mc_not_shared 判据）——
# 下面这些 variant 只给自己 golden 闭包里真用到的那几份（frontend-asm lane 为 Frontend green_child 证书链补）。
fm-SplittedSRAMTemplate_2: RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv
fm-SplittedSRAMTemplate_23: RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv
fm-SplittedSRAMTemplate_25: RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv
fm-SplittedSRAMTemplate_27: RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv
fm-SplittedSRAMTemplate_3: RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv
fm-SplittedSRAMTemplate_4: RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv


GOLDEN_SRCS = $(GOLDEN_RTL)/array_4_ext.v \
              $(GOLDEN_RTL)/SplittedSRAMTemplate.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
              $(GOLDEN_RTL)/SRAMTemplate.sv \
              $(GOLDEN_RTL)/SRAMTemplate_2.sv \
              $(GOLDEN_RTL)/SRAMTemplate_36.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv \
              $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/SRAMTemplate_76.sv \
              $(GOLDEN_RTL)/SRAMTemplate_78.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/array.sv \
              $(GOLDEN_RTL)/array_1.sv \
              $(GOLDEN_RTL)/array_1_ext.v \
              $(GOLDEN_RTL)/array_2.sv \
              $(GOLDEN_RTL)/array_2_ext.v \
              $(GOLDEN_RTL)/array_3.sv \
              $(GOLDEN_RTL)/array_3_ext.v \
              $(GOLDEN_RTL)/array_6.sv \
              $(GOLDEN_RTL)/array_6_ext.v \
              $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
              $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
              $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
              $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv

FM_REF_DEPS_SplittedSRAMTemplate = SRAMTemplate.sv sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_1 = SRAMTemplate_2.sv sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_2 = SRAMTemplate_36.sv sram_array_1p512x40m10s1h0l1b_bp_ftb.sv array_1.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_3 = SRAMTemplate_44.sv sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_4 = SRAMTemplate_45.sv sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_25 = SRAMTemplate_76.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SplittedSRAMTemplate_27 = SRAMTemplate_78.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv

FM_REF_DEPS_SplittedSRAMTemplate_23 = SRAMTemplate_64.sv sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv array_4.sv MbistClockGateCell.sv ClockGate.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 8
FM_VARIANTS = SplittedSRAMTemplate_23 SplittedSRAMTemplate SplittedSRAMTemplate_1 SplittedSRAMTemplate_2 SplittedSRAMTemplate_3 SplittedSRAMTemplate_4 SplittedSRAMTemplate_25 SplittedSRAMTemplate_27

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
