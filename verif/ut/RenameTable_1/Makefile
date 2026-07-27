MODULE = RenameTable_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 参数化可读核 + 类型包; 核内不例化 SG, wrapper 侧例化 SnapshotGenerator_5 黑盒。
# UT 不编 RenameTable_1_wrapper.sv(模块名与 golden 顶层冲突), 手写侧用 variants_xs.sv 里的 RenameTable_1_xs。
RTL_SRCS = $(RTL_DIR)/backend/renametable_pkg.sv \
           $(RTL_DIR)/backend/renametable_var_core.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 RenameTable_1 + 子模块 SnapshotGenerator_5(黑盒, UT 两侧共用)
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameTable_1.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_5.sv

# FM: golden RenameTable_1 vs 手写同名 wrapper(→参数核)。SnapshotGenerator_5 两侧同一黑盒。
WRAPPER_SRCS = $(RTL_DIR)/backend/RenameTable_1_wrapper.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_5.sv
FM_VARIANTS = RenameTable_1
FM_REF_DEPS_RenameTable_1 = SnapshotGenerator_5.sv

include ../../../scripts/ut_common.mk

# golden 含 XSError 断言; UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
