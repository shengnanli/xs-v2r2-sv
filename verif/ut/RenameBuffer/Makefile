MODULE = RenameBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包；核内例化 golden 同名 SnapshotGenerator 黑盒。
# UT 不编 RenameBuffer_wrapper.sv(模块名 RenameBuffer 与 golden 顶层冲突)，
# 手写侧改用 variants_xs.sv 里的 RenameBuffer_xs(同 wrapper 逻辑改名)。
RTL_SRCS = $(RTL_DIR)/backend/renamebuffer_pkg.sv \
           $(RTL_DIR)/backend/RenameBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 RenameBuffer + 子模块 SnapshotGenerator(黑盒，UT 两侧共用)
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameBuffer.sv \
              $(GOLDEN_RTL)/SnapshotGenerator.sv

# FM：golden RenameBuffer vs 手写同名 wrapper(→核)。SnapshotGenerator 两侧同一黑盒。
WRAPPER_SRCS = $(RTL_DIR)/backend/RenameBuffer_wrapper.sv \
               $(GOLDEN_RTL)/SnapshotGenerator.sv
FM_VARIANTS = RenameBuffer
FM_REF_DEPS_RenameBuffer = SnapshotGenerator.sv

include ../../../scripts/ut_common.mk

# golden 含 XSError 断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
