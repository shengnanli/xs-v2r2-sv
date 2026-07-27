MODULE = RenameTableWrapper

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/RenameTableWrapper_core.sv
# 5 个 RenameTable 实例(RenameTable/_1/_2/_3)在 FM assembly 下声明为对称黑盒
# (FM_INTERFACE_ONLY), 只证 wrapper wiring glue。UT 侧例化真体逐拍比对。
RAT_VARIANTS = $(GOLDEN_RTL)/RenameTable.sv $(GOLDEN_RTL)/RenameTable_1.sv \
               $(GOLDEN_RTL)/RenameTable_2.sv $(GOLDEN_RTL)/RenameTable_3.sv
# RAT 子孙(仅 UT 编译真体需要; FM assembly 黑盒 RAT 后不引用):
#   各 RenameTable{,_1,_2,_3} -> SnapshotGenerator_{4,5,6,7}
RAT_CHILDREN = $(GOLDEN_RTL)/SnapshotGenerator_4.sv $(GOLDEN_RTL)/SnapshotGenerator_5.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_6.sv $(GOLDEN_RTL)/SnapshotGenerator_7.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/RenameTableWrapper_wrapper.sv $(RAT_VARIANTS)
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameTableWrapper.sv $(RAT_VARIANTS) $(RAT_CHILDREN)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = RenameTableWrapper
FM_REF_DEPS_RenameTableWrapper = RenameTable.sv RenameTable_1.sv RenameTable_2.sv RenameTable_3.sv
# assembly: 5 RAT 实例对称黑盒(逻辑在各 RenameTable 里, 本层只证分发 wiring)
FM_MODE = assembly
FM_INTERFACE_ONLY = RenameTable RenameTable_1 RenameTable_2 RenameTable_3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
