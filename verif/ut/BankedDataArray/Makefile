MODULE = BankedDataArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 数据 bank SRAM 黑盒链: DataSRAMBank* -> SRAMTemplate_* -> 厂商宏 dcsh_dat -> array_8
SRAM_SRCS = $(GOLDEN_RTL)/DataSRAMBank.sv $(GOLDEN_RTL)/DataSRAMBank_1.sv \
            $(GOLDEN_RTL)/DataSRAMBank_2.sv $(GOLDEN_RTL)/DataSRAMBank_4.sv \
            $(GOLDEN_RTL)/SRAMTemplate_82.sv $(GOLDEN_RTL)/SRAMTemplate_84.sv \
            $(GOLDEN_RTL)/SRAMTemplate_86.sv $(GOLDEN_RTL)/SRAMTemplate_90.sv \
            $(GOLDEN_RTL)/SRAMTemplate_98.sv \
            $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
            $(GOLDEN_RTL)/array_8.sv $(GOLDEN_RTL)/array_8_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
MBIST_SRCS = $(GOLDEN_RTL)/MbistPipeDCacheData.sv

# 手写可读核 + pkg
RTL_SRCS = $(RTL_DIR)/memblock/bankeddata_pkg.sv $(RTL_DIR)/memblock/BankedDataArray.sv
# golden 同名 wrapper (仅 FM 用)
WRAPPER_SRCS = $(RTL_DIR)/memblock/BankedDataArray_wrapper.sv
# UT 双例化: golden 顶层 + _xs 镜像, 两侧共用 golden DataSRAMBank/Mbist/SRAM 黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/BankedDataArray.sv $(SRAM_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = BankedDataArray
FM_REF_DEPS_BankedDataArray =

include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
