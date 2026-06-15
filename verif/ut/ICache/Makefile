MODULE = ICache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核（含 package + xs_ICache_core）
RTL_SRCS     = $(RTL_DIR)/frontend/ICache.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICache_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# ----------------------------------------------------------------------------
# golden ICache 例化的 8 个子模块及其全部传递依赖（SRAM 模板/MBIST/仲裁/MSHR/vendor 宏）。
# UT 双例化时 golden ICache 与 _xs（核例化同名子模块）共用这一批 golden 实现，
# 故比对仅检验顶层互联 / 仲裁逻辑等价；子模块本身已各自验证过。
# ----------------------------------------------------------------------------
SUBMODS = \
  $(GOLDEN_RTL)/ICacheCtrlUnit.sv $(GOLDEN_RTL)/Queue1_RegMapperInput_3.sv \
  $(GOLDEN_RTL)/ICacheMetaArray.sv \
  $(GOLDEN_RTL)/SplittedSRAMTemplate.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
  $(GOLDEN_RTL)/SRAMTemplate.sv $(GOLDEN_RTL)/SRAMTemplate_2.sv \
  $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
  $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_ext.v \
  $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheTag.sv \
  $(GOLDEN_RTL)/ICacheDataArray.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth.sv $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_4.sv \
  $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_12.sv $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_28.sv \
  $(GOLDEN_RTL)/SRAMTemplate_4.sv $(GOLDEN_RTL)/SRAMTemplate_8.sv \
  $(GOLDEN_RTL)/SRAMTemplate_16.sv $(GOLDEN_RTL)/SRAMTemplate_32.sv \
  $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
  $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/array_0_ext.v \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay0.sv $(GOLDEN_RTL)/MbistPipeIcacheDataWay1.sv \
  $(GOLDEN_RTL)/MbistPipeIcacheDataWay2.sv $(GOLDEN_RTL)/MbistPipeIcacheDataWay3.sv \
  $(GOLDEN_RTL)/ICacheMainPipe.sv $(GOLDEN_RTL)/Arbiter2_ICacheMissReq.sv \
  $(GOLDEN_RTL)/ICacheMissUnit.sv \
  $(GOLDEN_RTL)/DeMultiplexer.sv $(GOLDEN_RTL)/DeMultiplexer_1.sv \
  $(GOLDEN_RTL)/MuxBundle.sv $(GOLDEN_RTL)/Arbiter5_MSHRAcquire.sv $(GOLDEN_RTL)/FIFOReg.sv \
  $(GOLDEN_RTL)/ICacheMSHR.sv $(GOLDEN_RTL)/ICacheMSHR_1.sv $(GOLDEN_RTL)/ICacheMSHR_2.sv \
  $(GOLDEN_RTL)/ICacheMSHR_3.sv $(GOLDEN_RTL)/ICacheMSHR_4.sv $(GOLDEN_RTL)/ICacheMSHR_5.sv \
  $(GOLDEN_RTL)/ICacheMSHR_6.sv $(GOLDEN_RTL)/ICacheMSHR_7.sv $(GOLDEN_RTL)/ICacheMSHR_8.sv \
  $(GOLDEN_RTL)/ICacheMSHR_9.sv $(GOLDEN_RTL)/ICacheMSHR_10.sv $(GOLDEN_RTL)/ICacheMSHR_11.sv \
  $(GOLDEN_RTL)/ICacheMSHR_12.sv $(GOLDEN_RTL)/ICacheMSHR_13.sv \
  $(GOLDEN_RTL)/ICacheReplacer.sv \
  $(GOLDEN_RTL)/IPrefetchPipe.sv \
  $(GOLDEN_RTL)/WayLookup.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ICache.sv $(SUBMODS)

FM_VARIANTS = ICache
# FM ref 侧依赖留空：8 个子模块两侧均不读源 → hdlin_unresolved_modules=black_box 统一黑盒，
# 顶层互联/仲裁按签名比对等价（子模块边界对齐）。
FM_REF_DEPS_ICache =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
