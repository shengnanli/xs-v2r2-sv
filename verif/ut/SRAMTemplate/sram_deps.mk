# 自动生成：scripts/gen_sram_wrappers.py
SRAM_VARIANTS = SRAMTemplate SRAMTemplate_2 SRAMTemplate_4 SRAMTemplate_8 SRAMTemplate_16 SRAMTemplate_32
MACRO_SIM = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/array_0_ext.v $(GOLDEN_RTL)/array_ext.v $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv
MACRO_FM  = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv
FM_REF_DEPS_SRAMTemplate = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_2 = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_4 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_8 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_16 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_32 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
