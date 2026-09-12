MODULE = DuplicatedTagArray

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/DuplicatedTagArray.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/MbistPipeDcacheTag.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_116.sv \
                  $(GOLDEN_RTL)/TagArray.sv \
                  $(GOLDEN_RTL)/TagSRAMBank.sv \
                  $(GOLDEN_RTL)/array_9.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv

FM_ELAB = TagArray.sv TagSRAMBank.sv SRAMTemplate_116.sv sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_9.sv MbistClockGateCell.sv ClockGate.sv MbistPipeDcacheTag.sv
FM_REF_DEPS_DuplicatedTagArray = TagArray.sv TagSRAMBank.sv SRAMTemplate_116.sv sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_9.sv MbistClockGateCell.sv ClockGate.sv MbistPipeDcacheTag.sv array_8.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/DuplicatedTagArray.sv \
              $(GOLDEN_RTL)/TagArray.sv \
              $(GOLDEN_RTL)/TagSRAMBank.sv \
              $(GOLDEN_RTL)/SRAMTemplate_116.sv \
              $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
              $(GOLDEN_RTL)/array_9.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistPipeDcacheTag.sv \
              $(GOLDEN_RTL)/array_9_ext.v \
              $(GOLDEN_RTL)/array_8.sv \
              $(GOLDEN_RTL)/array_8_ext.v
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = array_0_tag_arrays_0, array_0_tag_arrays_1, array_1_tag_arrays_0, array_1_tag_arrays_1, array_2_tag_arrays_0, array_2_tag_arrays_1…
FM_MODE = assembly
FM_ALLOWLIST ?= 8
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = DuplicatedTagArray

include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
