# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = OpenLLC

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/OpenLLC.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv \
              $(GOLDEN_RTL)/DataStorage_4.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_5.sv \
              $(GOLDEN_RTL)/Directory_4.sv \
              $(GOLDEN_RTL)/FastArbiter_26.sv \
              $(GOLDEN_RTL)/FastArbiter_29.sv \
              $(GOLDEN_RTL)/FastArbiter_30.sv \
              $(GOLDEN_RTL)/FastArbiter_35.sv \
              $(GOLDEN_RTL)/FastArbiter_43.sv \
              $(GOLDEN_RTL)/FastArbiter_45.sv \
              $(GOLDEN_RTL)/FastArbiter_46.sv \
              $(GOLDEN_RTL)/FastArbiter_48.sv \
              $(GOLDEN_RTL)/FastArbiter_49.sv \
              $(GOLDEN_RTL)/FastArbiter_51.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_3.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_4.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_5.sv \
              $(GOLDEN_RTL)/MMIODiverger.sv \
              $(GOLDEN_RTL)/MMIOMerger.sv \
              $(GOLDEN_RTL)/MainPipe_5.sv \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv \
              $(GOLDEN_RTL)/MemUnit.sv \
              $(GOLDEN_RTL)/Queue15_CHIDAT.sv \
              $(GOLDEN_RTL)/Queue15_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue15_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue1_CHIRSP_1.sv \
              $(GOLDEN_RTL)/RNLinkMonitor.sv \
              $(GOLDEN_RTL)/RNXbar.sv \
              $(GOLDEN_RTL)/RXDAT_4.sv \
              $(GOLDEN_RTL)/RXREQ.sv \
              $(GOLDEN_RTL)/RXRSP_4.sv \
              $(GOLDEN_RTL)/RefillUnit.sv \
              $(GOLDEN_RTL)/RequestArb_4.sv \
              $(GOLDEN_RTL)/RequestBuffer_4.sv \
              $(GOLDEN_RTL)/ResponseUnit.sv \
              $(GOLDEN_RTL)/SNLinkMonitor.sv \
              $(GOLDEN_RTL)/SNXbar.sv \
              $(GOLDEN_RTL)/SRAMTemplate_192.sv \
              $(GOLDEN_RTL)/SRAMTemplate_193.sv \
              $(GOLDEN_RTL)/SRAMTemplate_194.sv \
              $(GOLDEN_RTL)/SRAMTemplate_195.sv \
              $(GOLDEN_RTL)/SRAMTemplate_196.sv \
              $(GOLDEN_RTL)/SRAMTemplate_197.sv \
              $(GOLDEN_RTL)/Slice_4.sv \
              $(GOLDEN_RTL)/SnoopUnit.sv \
              $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/SubDirectory_1.sv \
              $(GOLDEN_RTL)/TXDAT_4.sv \
              $(GOLDEN_RTL)/TXREQ_4.sv \
              $(GOLDEN_RTL)/TXRSP_4.sv \
              $(GOLDEN_RTL)/TXSNP.sv \
              $(GOLDEN_RTL)/TopDownMonitor_1.sv \
              $(GOLDEN_RTL)/array_0_0.sv \
              $(GOLDEN_RTL)/array_0_0_ext.v \
              $(GOLDEN_RTL)/array_0_1.sv \
              $(GOLDEN_RTL)/array_0_1_ext.v \
              $(GOLDEN_RTL)/array_19.sv \
              $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20.sv \
              $(GOLDEN_RTL)/array_20_ext.v \
              $(GOLDEN_RTL)/array_21.sv \
              $(GOLDEN_RTL)/array_21_ext.v \
              $(GOLDEN_RTL)/array_22.sv \
              $(GOLDEN_RTL)/array_22_ext.v \
              $(GOLDEN_RTL)/ram_15x162.sv \
              $(GOLDEN_RTL)/ram_15x422.sv \
              $(GOLDEN_RTL)/ram_15x73.sv

FM_VARIANTS = OpenLLC
FM_REF_DEPS_OpenLLC = DataStorage_4.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv Decoupled2LCredit_5.sv Directory_4.sv FastArbiter_26.sv FastArbiter_29.sv FastArbiter_30.sv FastArbiter_35.sv FastArbiter_43.sv FastArbiter_45.sv FastArbiter_46.sv FastArbiter_48.sv FastArbiter_49.sv FastArbiter_51.sv LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv LCredit2Decoupled_5.sv MMIODiverger.sv MMIOMerger.sv MainPipe_5.sv MaxPeriodFibonacciLFSR_3.sv MemUnit.sv Queue15_CHIDAT.sv Queue15_CHIREQ.sv Queue15_CHIRSP.sv Queue1_CHIRSP_1.sv RNLinkMonitor.sv RNXbar.sv RXDAT_4.sv RXREQ.sv RXRSP_4.sv RefillUnit.sv RequestArb_4.sv RequestBuffer_4.sv ResponseUnit.sv SNLinkMonitor.sv SNXbar.sv SRAMTemplate_192.sv SRAMTemplate_193.sv SRAMTemplate_194.sv SRAMTemplate_195.sv SRAMTemplate_196.sv SRAMTemplate_197.sv Slice_4.sv SnoopUnit.sv SubDirectory.sv SubDirectory_1.sv TXDAT_4.sv TXREQ_4.sv TXRSP_4.sv TXSNP.sv TopDownMonitor_1.sv array_0_0.sv array_0_0_ext.v array_0_1.sv array_0_1_ext.v array_19.sv array_19_ext.v array_20.sv array_20_ext.v array_21.sv array_21_ext.v array_22.sv array_22_ext.v ram_15x162.sv ram_15x422.sv ram_15x73.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
