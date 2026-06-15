# 双端口 SRAM 变体依赖（手写，非生成器产物）
SRAM_VARIANTS = SRAMTemplate_66
MACRO_SIM = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv \
            $(GOLDEN_RTL)/array_5.sv $(GOLDEN_RTL)/array_5_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv
MACRO_FM  = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv \
            $(GOLDEN_RTL)/array_5.sv $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv
FM_REF_DEPS_SRAMTemplate_66 = sram_array_2p256x24m6s1h0l1b_bp_sc.sv array_5.sv MbistClockGateCell.sv ClockGate.sv
