# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = ITTageTable_3

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ITTageTable_3.sv \
           $(RTL_DIR)/frontend/ITTageTable.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTageTable_3.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_24.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/MbistPipeIttage_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_78.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_27.sv \
              $(GOLDEN_RTL)/WrBypass_43.sv \
              $(GOLDEN_RTL)/array_6.sv \
              $(GOLDEN_RTL)/array_6_ext.v \
              $(GOLDEN_RTL)/data_mem_0_4x2.sv \
              $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

FM_VARIANTS = ITTageTable_3
FM_REF_DEPS_ITTageTable_3 = ClockGate.sv FoldedSRAMTemplate_24.sv IndexableCAMTemplate_43.sv MbistClockGateCell.sv MbistPipeIttage_3.sv SRAMTemplate_78.sv SplittedSRAMTemplate_27.sv WrBypass_43.sv array_6.sv array_6_ext.v data_mem_0_4x2.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
