# SCTable 的双口 SRAM 宏依赖（bp_sc：256set × 4way × 6bit）。
#   MACRO_SIM：可仿真宏链（UT simv 用）。MACRO_FM：FM impl 侧（array_ext 当黑盒，不读）。
MACRO_SIM = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv \
            $(GOLDEN_RTL)/array_5.sv $(GOLDEN_RTL)/array_5_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv
MACRO_FM  = $(GOLDEN_RTL)/ClockGate.sv $(GOLDEN_RTL)/MbistClockGateCell.sv \
            $(GOLDEN_RTL)/array_5.sv \
            $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv
