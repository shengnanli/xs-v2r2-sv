MODULE = LoadQueueRAR

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 合成层次：核（xs_LoadQueueRAR_core）例化两个已证子模块 FreeList_3 + LqPAddrModule。
# ── UT 与 FM 的源列表分离（因 impl 子模块与 golden 同名，UT 双例化会撞名）──────────
#   · RTL_SRCS       = 仅类型包（UT/FM 共读，无模块撞名）。
#   · WRAPPER_SRCS   = FM-only（不进 UT）：wrapper(module LoadQueueRAR) + 核 + 两子模块
#                      （plain 名，与 golden 同名 → FM 层次配对，两侧 elaborate 比对）。
#   · TB_SRCS        = UT-only：_xs 重命名子树（核_ut + FreeList_3_xs + LqPAddrModule_xs）
#                      避免与 golden 顶层内的同名子模块在 simv 里撞名。
RTL_SRCS = $(RTL_DIR)/memblock/loadqueuerar_pkg.sv

TB_SRCS = FreeList_3_xs.sv \
          LqPAddrModule_xs.sv \
          LoadQueueRAR_core_ut.sv \
          variants_xs.sv \
          tb.sv

# UT 双例化：golden 顶层 LoadQueueRAR（含其真实子模块 LqPAddrModule / FreeList_3）
# vs 手写 _xs 镜像（→ 可读核）。只比对顶层输出。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAR.sv \
              $(GOLDEN_RTL)/LqPAddrModule.sv \
              $(GOLDEN_RTL)/FreeList_3.sv \
              $(GOLDEN_RTL)/DelayN_226.sv \
              $(GOLDEN_RTL)/DelayNWithValid_4.sv \
              $(GOLDEN_RTL)/DelayNWithValid_7.sv

# FM（both-sides elaborate）：golden 顶层 LoadQueueRAR（含子模块 FreeList_3 + LqPAddrModule）
#   vs 手写同名 wrapper（module LoadQueueRAR → 核 xs_LoadQueueRAR_core，核例化同名两子模块）。
#   两侧子模块同名 → FM 层次配对逐点比对（非黑盒）。子模块本就是已证 canary
#   （FreeList_3 passing 707、LqPAddrModule passing 1440，native SUCCEEDED）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueRAR_wrapper.sv \
               $(RTL_DIR)/memblock/LoadQueueRAR.sv \
               $(RTL_DIR)/memblock/FreeList_3.sv \
               $(RTL_DIR)/memblock/LqPAddrModule.sv
FM_VARIANTS = LoadQueueRAR
FM_REF_DEPS_LoadQueueRAR = LqPAddrModule.sv FreeList_3.sv DelayN_226.sv DelayNWithValid_4.sv DelayNWithValid_7.sv

# 关闭 FM 的“合并同值重复寄存器”pass：本模块状态规模大（72 entry × 多字段 + freelist/CAM
# 子模块阵列），开启合并后签名分析的未配对寄存器搜索空间组合爆炸（实测 31min 仅 3% matched）。
# 关掉后由 fm_eq.tcl 的 auto_match_flattened_arrays 按展平名规则配对阵列寄存器，可正常收敛。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal/随机初始化
VCS += +define+SYNTHESIS
