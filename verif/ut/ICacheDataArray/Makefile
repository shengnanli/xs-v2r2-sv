MODULE = ICacheDataArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 数据 SRAM 黑盒 + 内层 SRAMTemplate + 厂商存储宏（4 个 FixedWidth 变体共用 icsh_dat 宏）
SRAM_SRCS = $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth.sv \
            $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_4.sv \
            $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_12.sv \
            $(GOLDEN_RTL)/SRAMTemplateWithFixedWidth_28.sv \
            $(GOLDEN_RTL)/SRAMTemplate_4.sv \
            $(GOLDEN_RTL)/SRAMTemplate_8.sv \
            $(GOLDEN_RTL)/SRAMTemplate_16.sv \
            $(GOLDEN_RTL)/SRAMTemplate_32.sv \
            $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
            $(GOLDEN_RTL)/array_0.sv $(GOLDEN_RTL)/array_0_ext.v

# 每 way 一条 Mbist 流水黑盒
MBIST_SRCS = $(GOLDEN_RTL)/MbistPipeIcacheDataWay0.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay1.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay2.sv \
             $(GOLDEN_RTL)/MbistPipeIcacheDataWay3.sv

# 手写可读核（参数化）
RTL_SRCS = $(RTL_DIR)/frontend/ICacheDataArray.sv
# golden 同名 wrapper（仅 FM 用）
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheDataArray_wrapper.sv
# UT 双例化：golden 顶层 + _xs 变体；两侧均例化上面的 golden SRAM/Mbist 黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheDataArray.sv $(SRAM_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = ICacheDataArray
# FM ref 侧依赖留空：SRAM/Mbist 在两侧都不提供 RTL，经 hdlin_unresolved_modules=
# black_box 同名当黑盒。两侧黑盒实例一致，FM 在黑盒输入引脚(BBPin)处比对，证明
# 可读核 + wrapper 把读写/DFT 信号接到各 SRAM/Mbist 的方式与 golden 完全一致。
# （若给 ref 侧提供真实 SRAM/Mbist RTL 而 impl 侧为黑盒，两侧不对称会令 Mbist
#  outdata 等穿过黑盒的输出无法判等。）
FM_REF_DEPS_ICacheDataArray =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
# 必须在 include 之后 append（ut_common.mk 用 := 定义 VCS）。
VCS += +define+SYNTHESIS
