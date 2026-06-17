MODULE = Rename

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包；核内例化 golden 同名黑盒(CompressUnit/各 FreeList/SnapshotGenerator)。
# UT 不编 Rename_wrapper.sv(模块名 Rename 与 golden 顶层冲突)，手写侧用 Rename_xs。
RTL_SRCS = $(RTL_DIR)/backend/rename_pkg.sv \
           $(RTL_DIR)/backend/Rename.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 Rename + 全部子模块(黑盒，UT 两侧共用)
GOLDEN_SRCS = $(GOLDEN_RTL)/Rename.sv \
              $(GOLDEN_RTL)/CompressUnit.sv \
              $(GOLDEN_RTL)/MEFreeList.sv \
              $(GOLDEN_RTL)/StdFreeList.sv \
              $(GOLDEN_RTL)/StdFreeList_1.sv \
              $(GOLDEN_RTL)/StdFreeList_2.sv \
              $(GOLDEN_RTL)/StdFreeList_3.sv \
              $(GOLDEN_RTL)/SnapshotGenerator.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_11.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_12.sv

# FM：golden Rename vs 手写同名 wrapper(→核)。
# impl 侧也要带上 golden 子模块(CompressUnit/各 FreeList/SnapshotGenerator)，让两侧
# 用同一套真实子模块、其内部寄存器逐一配对(否则全成 unmatched 黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/backend/Rename_wrapper.sv \
               $(GOLDEN_RTL)/CompressUnit.sv \
               $(GOLDEN_RTL)/MEFreeList.sv \
               $(GOLDEN_RTL)/StdFreeList.sv \
               $(GOLDEN_RTL)/StdFreeList_1.sv \
               $(GOLDEN_RTL)/StdFreeList_2.sv \
               $(GOLDEN_RTL)/StdFreeList_3.sv \
               $(GOLDEN_RTL)/SnapshotGenerator.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_11.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_12.sv
FM_VARIANTS = Rename
FM_REF_DEPS_Rename = CompressUnit.sv MEFreeList.sv StdFreeList.sv StdFreeList_1.sv \
                     StdFreeList_2.sv StdFreeList_3.sv SnapshotGenerator.sv \
                     SnapshotGenerator_11.sv SnapshotGenerator_12.sv

include ../../../scripts/ut_common.mk

# golden 含 XSError/assert；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
