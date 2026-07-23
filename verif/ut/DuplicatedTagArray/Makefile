MODULE = DuplicatedTagArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# Tag SRAM 存储链（reviewer 裁定选项 2, 同 ICacheDataArray）：
#   TagArray -> TagSRAMBank -> SRAMTemplate_114 -> sram_array...tag -> array_9 -> array_9_ext
# 除最底层厂商存储宏 array_9_ext.v 外，全链（含 TagArray 副本壳 / TagSRAMBank 的 rst_cnt
# 逐组清零 / SRAMTemplate_114 的 holdRead·地址·mask·DFT 连线 / MbistClockGateCell·ClockGate）
# 均两侧 elaborate 参与 FM 证明；MbistPipeDcacheTag（纯逻辑 MBIST 流水）亦两侧展开受验。
# 仅 8 个（4 副本 × 2 TagSRAMBank）厂商宏 array_9_ext 作对称 assembly 黑盒边界
# (不提供 RTL 给任一 FM 侧 → hdlin_unresolved_modules=black_box)。
FM_ELAB = TagArray.sv \
          TagSRAMBank.sv \
          SRAMTemplate_114.sv \
          sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
          array_9.sv \
          MbistClockGateCell.sv ClockGate.sv \
          MbistPipeDcacheTag.sv
# UT（仿真）仍需全套含 vendor 宏 array_9_ext
SRAM_SRCS = $(addprefix $(GOLDEN_RTL)/,$(FM_ELAB)) $(GOLDEN_RTL)/array_9_ext.v
MBIST_SRCS =

# 手写可读核 + pkg
RTL_SRCS = $(RTL_DIR)/memblock/dtagarray_pkg.sv $(RTL_DIR)/memblock/DuplicatedTagArray.sv
# golden 同名 wrapper (仅 FM 用) ＋ impl 侧也展开同一套 golden SRAM/MBIST 链（两侧对称
# elaborate，令 TagArray/TagSRAMBank/SRAMTemplate/MBIST 逻辑受验，仅 array_9_ext 黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/DuplicatedTagArray_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(FM_ELAB))
# UT 双例化: golden 顶层 + _xs 镜像, 两侧共用 golden SRAM/MBIST 链
GOLDEN_SRCS = $(GOLDEN_RTL)/DuplicatedTagArray.sv $(SRAM_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = DuplicatedTagArray
# FM ref 侧依赖 = SRAM/MBIST 链（与 impl 侧 WRAPPER_SRCS 对称提供，两侧同名 golden 模块
# 一起 elaborate 参与证明）；array_9_ext（vendor 宏）两侧都不提供 RTL → 同名黑盒边界。
FM_REF_DEPS_DuplicatedTagArray = $(FM_ELAB)

include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
