# 自动生成：scripts/gen_sram_wrappers.py
SRAM_VARIANTS = SRAMTemplate SRAMTemplate_2 SRAMTemplate_4 SRAMTemplate_8 SRAMTemplate_16 SRAMTemplate_32 SRAMTemplate_36 SRAMTemplate_45
MACRO_SIM = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/array_0_ext.v $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/array_1_ext.v $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v $(GOLDEN_RTL)/array_ext.v $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv
MACRO_FM  = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv
FM_REF_DEPS_SRAMTemplate = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_2 = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_4 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_8 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_16 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_32 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_36 = sram_array_1p512x40m10s1h0l1b_bp_ftb.sv array_1.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_45 = sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv MbistClockGateCell.sv ClockGate.sv
