MODULE = LoadQueueRAR

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内联实现 freelist / paddr CAM，无子模块）
RTL_SRCS = $(RTL_DIR)/memblock/loadqueuerar_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueueRAR.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化：golden 顶层 LoadQueueRAR（含其真实子模块 LqPAddrModule / FreeList_3）
# vs 手写 _xs 镜像（→ 可读核）。只比对顶层输出。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAR.sv \
              $(GOLDEN_RTL)/LqPAddrModule.sv \
              $(GOLDEN_RTL)/FreeList_3.sv \
              $(GOLDEN_RTL)/DelayN_226.sv \
              $(GOLDEN_RTL)/DelayNWithValid_4.sv \
              $(GOLDEN_RTL)/DelayNWithValid_7.sv

# FM：golden 顶层（含两子模块）vs 手写同名 wrapper（→ 可读核，核内联了 freelist/CAM）。
# golden 侧两子模块逻辑在 impl 无对应边界，按签名/输出比对；不可判点用 tb 探针证伪。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueRAR_wrapper.sv
FM_VARIANTS = LoadQueueRAR
FM_REF_DEPS_LoadQueueRAR = LqPAddrModule.sv FreeList_3.sv DelayN_226.sv DelayNWithValid_4.sv DelayNWithValid_7.sv

# 关闭 FM 的“合并同值重复寄存器”pass：本模块状态规模大（72 entry × 多字段 + freelist/CAM
# 子模块阵列），开启合并后签名分析的未配对寄存器搜索空间组合爆炸（实测 31min 仅 3% matched）。
# 关掉后由 fm_eq.tcl 的 auto_match_flattened_arrays 按展平名规则配对阵列寄存器，可正常收敛。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal/随机初始化
VCS += +define+SYNTHESIS
