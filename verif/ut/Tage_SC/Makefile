MODULE = Tage_SC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAM 宏链：TAGE 表(us+bp_tage) + 基预测器(bp_tage_bt) + SC 表(bp_sc)
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
            $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/array_2_ext.v \
            $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
            $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v \
            $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
            $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/array_4_ext.v \
            $(GOLDEN_RTL)/sram_array_2p256x24m6s1h0l1b_bp_sc.sv \
            $(GOLDEN_RTL)/array_5.sv $(GOLDEN_RTL)/array_5_ext.v \
            $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核（xs_Tage_SC_core）
RTL_SRCS = $(RTL_DIR)/frontend/Tage_SC.sv
# FM impl：核 + golden 同名 wrapper（所有子模块当黑盒）
# FM impl 侧带上 golden MbistPipeTage（白盒；否则其黑盒输出 BBPin FM 拒配 →
# boreChildrenBd_bore_outdata 输出锥失配）。UT simv 不用 WRAPPER_SRCS，无重复定义。
# MaxPeriodFibonacciLFSR 双侧 elaborate（非 vendor 宏，是确定性 LFSR 逻辑）：
# 白盒比对 allocLFSR_prng/_1（两侧同 golden 源 → 消除 2 个黑盒对，进 passing）
WRAPPER_SRCS = $(RTL_DIR)/frontend/Tage_SC_wrapper.sv $(GOLDEN_RTL)/MbistPipeTage.sv \
               $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

# UT：golden Tage_SC 顶层 + 全部子模块链（两侧共用同名子模块）
GOLDEN_SRCS = $(GOLDEN_RTL)/Tage_SC.sv \
              $(GOLDEN_RTL)/TageTable.sv $(GOLDEN_RTL)/TageTable_1.sv \
              $(GOLDEN_RTL)/TageTable_2.sv $(GOLDEN_RTL)/TageTable_3.sv \
              $(GOLDEN_RTL)/TageBTable.sv \
              $(GOLDEN_RTL)/SCTable.sv $(GOLDEN_RTL)/SCTable_1.sv \
              $(GOLDEN_RTL)/SCTable_2.sv $(GOLDEN_RTL)/SCTable_3.sv \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv \
              $(GOLDEN_RTL)/MbistPipeTage.sv \
              $(GOLDEN_RTL)/MbistPipeSc.sv $(GOLDEN_RTL)/MbistPipeSc_1.sv \
              $(GOLDEN_RTL)/MbistPipeSc_2.sv $(GOLDEN_RTL)/MbistPipeSc_3.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv $(GOLDEN_RTL)/SRAMTemplate_66.sv \
              $(GOLDEN_RTL)/WrBypass.sv $(GOLDEN_RTL)/WrBypass_32.sv $(GOLDEN_RTL)/WrBypass_33.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate.sv $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_33.sv \
              $(GOLDEN_RTL)/data_mem_0_8x3.sv $(GOLDEN_RTL)/data_mem_8x4.sv \
              $(GOLDEN_RTL)/data_mem_16x12.sv \
              $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Tage_SC（所有子模块不列依赖 → hdlin_unresolved_modules=black_box）
FM_VARIANTS = Tage_SC
FM_REF_DEPS_Tage_SC = MbistPipeTage.sv MaxPeriodFibonacciLFSR.sv

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言 + 随机初始化；UT 仿真定义 SYNTHESIS 关掉，从复位态出发
VCS += +define+SYNTHESIS
