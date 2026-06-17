MODULE = MEFreeList

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包；核内例化 golden 同名 SnapshotGenerator 黑盒。
# 注意 UT 不编 MEFreeList_wrapper.sv(模块名 MEFreeList 与 golden 顶层冲突)，
# 手写侧改用 variants_xs.sv 里的 MEFreeList_xs(同 wrapper 逻辑改名)。
RTL_SRCS = $(RTL_DIR)/backend/mefreelist_pkg.sv \
           $(RTL_DIR)/backend/MEFreeList.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 MEFreeList + 其子模块 SnapshotGenerator(黑盒，UT 两侧共用同一实现)
GOLDEN_SRCS = $(GOLDEN_RTL)/MEFreeList.sv \
              $(GOLDEN_RTL)/SnapshotGenerator.sv

# FM：golden MEFreeList vs 手写同名 wrapper(→核)。SnapshotGenerator 子模块两侧
# 都提供同一份 golden RTL(同名同端口)，FM 按名一一配对其内部寄存器后干净比对。
WRAPPER_SRCS = $(RTL_DIR)/backend/MEFreeList_wrapper.sv \
               $(GOLDEN_RTL)/SnapshotGenerator.sv
FM_VARIANTS = MEFreeList
FM_REF_DEPS_MEFreeList = SnapshotGenerator.sv

# 关闭"合并同值重复寄存器"pass：headPtr/headPtrOH 是同一指针的两种冗余表示，
# 在 golden 顶层 vs impl 的 u_core 层次边界两侧会被不对称常量传播，关掉后按名配对。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
