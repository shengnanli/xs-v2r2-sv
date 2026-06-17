MODULE = RenameTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包；核内例化 golden 同名 SnapshotGenerator_4 黑盒。
# UT 不编 RenameTable_wrapper.sv(模块名 RenameTable 与 golden 顶层冲突)，
# 手写侧改用 variants_xs.sv 里的 RenameTable_xs(同 wrapper 逻辑改名)。
RTL_SRCS = $(RTL_DIR)/backend/renametable_pkg.sv \
           $(RTL_DIR)/backend/RenameTable.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 RenameTable + 子模块 SnapshotGenerator_4(黑盒，UT 两侧共用)
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameTable.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_4.sv

# FM：golden RenameTable vs 手写同名 wrapper(→核)。SnapshotGenerator_4 两侧同一黑盒。
WRAPPER_SRCS = $(RTL_DIR)/backend/RenameTable_wrapper.sv \
               $(GOLDEN_RTL)/SnapshotGenerator_4.sv
FM_VARIANTS = RenameTable
FM_REF_DEPS_RenameTable = SnapshotGenerator_4.sv

include ../../../scripts/ut_common.mk

# golden 含 XSError 断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
