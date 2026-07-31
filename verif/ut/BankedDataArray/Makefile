MODULE = BankedDataArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 数据 bank SRAM 逻辑链: DataSRAMBank* -> SRAMTemplate_* -> sram_array dcsh_dat -> array_8
#   -> 厂商宏 array_8_ext(唯一保留黑盒叶). MbistPipeDCacheData(mbistPl)亦保留黑盒.
# ---- ELAB_SRCS: 两侧(ref+impl)同源 elaborate 的 SRAM/MBIST 逻辑(不含厂商宏)----
# FM 审计 2026-07-30(codex_0093 §1 exact-cutpoint): 之前把 DataSRAMBank*×8 + mbistPl
# 整体当 9 黑盒时, golden 侧 childBd_N_rdata(DataSRAMBank 的 boreChildrenBd_bore_*_rdata
# 输出, 本 config 悬空死网)在 FM 里因 direction-unknown 被推成黑盒**输入**引脚, 其 fan-in
# 是 undriven cut-point → 20 个 data_banks_*/boreChildrenBd_bore_1_rdata[0/10/11] BBPin
# 比对点因 ref-undriven 失配, 只能靠全局 verification_set_undriven_signals=BINARY 放宽掩盖
# (被 sidecar 判 relaxed_appvars→PARTIAL). 精确解 = 把 DataSRAMBank+SRAMTemplate 两侧同源
# elaborate(功能保持的边界建模, 同 Slice codex_0036): rdata 成 SRAM 真实驱动输出, undriven
# 死锥消失, 无需任何放宽 appvar. 唯一黑盒边界 = 厂商 array_8_ext.v + MbistPipeDCacheData.
ELAB_SRCS = $(GOLDEN_RTL)/DataSRAMBank.sv $(GOLDEN_RTL)/DataSRAMBank_1.sv \
            $(GOLDEN_RTL)/DataSRAMBank_2.sv $(GOLDEN_RTL)/DataSRAMBank_4.sv \
            $(GOLDEN_RTL)/SRAMTemplate_82.sv $(GOLDEN_RTL)/SRAMTemplate_84.sv \
            $(GOLDEN_RTL)/SRAMTemplate_86.sv $(GOLDEN_RTL)/SRAMTemplate_90.sv \
            $(GOLDEN_RTL)/SRAMTemplate_98.sv \
            $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
            $(GOLDEN_RTL)/array_8.sv \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
# 黑盒叶(两侧都不给源): 厂商 SRAM 宏 array_8_ext + MBIST 管道 MbistPipeDCacheData(mbistPl)
BBOX_SRCS = $(GOLDEN_RTL)/array_8_ext.v
MBIST_SRCS = $(GOLDEN_RTL)/MbistPipeDCacheData.sv

# 手写可读核 + pkg
RTL_SRCS = $(RTL_DIR)/memblock/bankeddata_pkg.sv $(RTL_DIR)/memblock/BankedDataArray.sv
# golden 同名 wrapper (仅 FM 用) + 两侧同源 elaborate 的 SRAM/MBIST 逻辑
WRAPPER_SRCS = $(RTL_DIR)/memblock/BankedDataArray_wrapper.sv $(ELAB_SRCS)
# UT 双例化: golden 顶层 + _xs 镜像, 两侧共用 golden SRAM 逻辑 + 厂商宏/mbistPl 黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/BankedDataArray.sv $(ELAB_SRCS) $(BBOX_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = BankedDataArray
# FM 审计 2026-07：8 bank×way 同构 ECC/raw 打拍链，合并同值寄存器 pass 会跨 bank 误
# 合并/误配（部分 ecc_data_delayed 位 unmatched + 大面积 failing），关掉合并。
FM_MERGE_DUP = false
# FM ref 侧亦 elaborate SRAM/MBIST 逻辑(与 impl WRAPPER_SRCS 同源), 唯 array_8_ext / mbistPl 黑盒
FM_REF_DEPS_BankedDataArray = DataSRAMBank.sv DataSRAMBank_1.sv DataSRAMBank_2.sv DataSRAMBank_4.sv \
            SRAMTemplate_82.sv SRAMTemplate_84.sv SRAMTemplate_86.sv SRAMTemplate_90.sv SRAMTemplate_98.sv \
            sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_8.sv MbistClockGateCell.sv ClockGate.sv

include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
