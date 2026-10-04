MODULE = FTBBank

RTL_DIR = ../../../rtl
# frontend_common_pkg.sv 里的 xs_ftb_pkg 由 FTBEntryGen/FTBBank 共用（每个子系统至多一个公共包文件，见
# CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/frontend/FTBEntryGen.sv \
           $(RTL_DIR)/frontend/FTBBank.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/MbistPipeFtb.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
                  $(GOLDEN_RTL)/array_1.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

FM_SRAM_ELAB = $(GOLDEN_RTL)/MbistPipeFtb.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv                 $(GOLDEN_RTL)/SRAMTemplate_36.sv                 $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv                 $(GOLDEN_RTL)/array_1.sv                 $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
FM_REF_DEPS_FTBBank = MbistPipeFtb.sv SplittedSRAMTemplate_2.sv SRAMTemplate_36.sv                        sram_array_1p512x40m10s1h0l1b_bp_ftb.sv array_1.sv                        MbistClockGateCell.sv ClockGate.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FTBBank.sv \
              $(GOLDEN_RTL)/MbistPipeFtb.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
              $(GOLDEN_RTL)/SRAMTemplate_36.sv \
              $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
              $(GOLDEN_RTL)/array_1.sv \
              $(GOLDEN_RTL)/array_1_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = array_0_0_0, array_0_0_1, array_0_0_2, array_0_0_3, array_0_0_4, array_0_0_5…
FM_MODE = assembly
FM_ALLOWLIST ?= 8
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = FTBBank

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
