MODULE = PBestOffsetPrefetch

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_PBestOffsetPrefetch_core + 三个子核(DelayQueue/OffsetScoreTable/
# RecentRequestTable + SRAMTemplate_135 控制)在 PBestOffset_children.sv。
RTL_SRCS = $(RTL_DIR)/l2/PBestOffsetPrefetch.sv $(RTL_DIR)/l2/PBestOffset_children.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/PBestOffsetPrefetch_wrapper.sv
# golden 顶层 + 全部子模块。UT 仿真需 SRAM 宏行为模型(sram_array_.../array_13/
# array_13_ext), golden 与 impl 两侧共用同一 sram_array_ 定义(单例)。
# 注意: FM 侧(FM_REF_DEPS)不含 SRAM 宏链 → sram_array_ 两侧对称黑盒。
GOLDEN_SRCS = $(GOLDEN_RTL)/PBestOffsetPrefetch.sv \
              $(GOLDEN_RTL)/DelayQueue.sv \
              $(GOLDEN_RTL)/RecentRequestTable.sv \
              $(GOLDEN_RTL)/OffsetScoreTable.sv \
              $(GOLDEN_RTL)/SRAMTemplate_135.sv \
              $(GOLDEN_RTL)/sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv \
              $(GOLDEN_RTL)/array_13.sv \
              $(GOLDEN_RTL)/array_13_ext.v
# UT 变体: impl 顶层改名 PBestOffsetPrefetch_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 strict; 全部功能逻辑两侧可读 elaborate, 唯一黑盒 = 厂商 SRAM 宏
# sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt(两侧 unresolved → hdlin_unresolved_modules=
# black_box, 对称匹配)。
FM_VARIANTS = PBestOffsetPrefetch
FM_REF_DEPS_PBestOffsetPrefetch = DelayQueue.sv RecentRequestTable.sv OffsetScoreTable.sv SRAMTemplate_135.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值与单口 SRAM 读写冲突断言; 定义 SYNTHESIS 关掉
# (同时关随机初值, 使两侧寄存器复位到 0 后同构可比)。
VCS += +define+SYNTHESIS
