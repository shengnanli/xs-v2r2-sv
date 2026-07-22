MODULE = ICacheDataArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# SRAM 存储链（reviewer 裁定选项 2）：FixedWidth 包装 + 内层 SRAMTemplate + sram_array +
# array_0 全部展开参与 FM 证明（两侧同名 golden 模块，其 fixed-width 拆分 / holdRead /
# 地址 / mask / DFT 连线逻辑均被验证），仅最底层厂商存储宏 array_0_ext 作对称 assembly
# 黑盒边界。array_0_ext.v（vendor 宏）故意不提供给任一 FM 侧 → hdlin_unresolved=black_box。
FM_SRAM_ELAB = SRAMTemplateWithFixedWidth.sv \
               SRAMTemplateWithFixedWidth_4.sv \
               SRAMTemplateWithFixedWidth_12.sv \
               SRAMTemplateWithFixedWidth_28.sv \
               SRAMTemplate_4.sv SRAMTemplate_8.sv SRAMTemplate_16.sv SRAMTemplate_32.sv \
               sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
# UT（仿真）仍需全套含 vendor 宏
SRAM_SRCS = $(addprefix $(GOLDEN_RTL)/,$(FM_SRAM_ELAB)) $(GOLDEN_RTL)/array_0_ext.v

# 每 way 一条 Mbist 流水黑盒
MBIST_SRCS = $(GOLDEN_RTL)/MbistPipeIcacheDataWay0.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay1.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay2.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay3.sv

# 手写可读核（参数化）
RTL_SRCS = $(RTL_DIR)/frontend/ICacheDataArray.sv
# golden 同名 wrapper（仅 FM 用）＋ impl 侧也展开同一套 golden SRAM 存储链（两侧对称
# elaborate，令 SRAMTemplate/sram_array/array_0 逻辑受验，仅 array_0_ext 黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheDataArray_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(FM_SRAM_ELAB))
# UT 双例化：golden 顶层 + _xs 变体；两侧均例化上面的 golden SRAM/Mbist 黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheDataArray.sv $(SRAM_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = ICacheDataArray
# FM ref 侧依赖 = SRAM 存储链（与 impl 侧 WRAPPER_SRCS 对称提供，两侧同名 golden
# 模块一起 elaborate 参与证明）。array_0_ext（vendor 宏）与 Mbist 流水在两侧都不提供
# RTL → hdlin_unresolved_modules=black_box 同名当黑盒（对称 assembly 边界）；SRAM 模板
# 逻辑（fixed-width 拆分 / holdRead / 地址 / mask / DFT 连线）全部被 FM 验证。
FM_REF_DEPS_ICacheDataArray = $(FM_SRAM_ELAB)

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
VCS += +define+SYNTHESIS
