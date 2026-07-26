MODULE = LoadQueueRAW

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 合成层次：核（xs_LoadQueueRAW_core）例化三个镜像 golden 层次的子模块
#   FreeList_4 + LqPAddrModule_1 + LqMaskModule（可读重写，与 golden 同名 → FM 层次配对）。
# ── UT 与 FM 的源列表分离（因 impl 子模块与 golden 同名，UT 双例化会撞名）──────────
#   · RTL_SRCS       = 仅类型包（UT/FM 共读，无模块撞名）。
#   · WRAPPER_SRCS   = FM-only：wrapper(module LoadQueueRAW) + 核 + 三子模块
#                      （plain 名，与 golden 同名 → FM 两侧 elaborate 逐点比对）。
#   · TB_SRCS        = UT-only：_xs 重命名子树（核_ut + 三子模块_xs）
#                      避免与 golden 顶层内的同名子模块在 simv 里撞名。
RTL_SRCS = $(RTL_DIR)/memblock/loadqueueraw_pkg.sv

TB_SRCS = FreeList_4_xs.sv \
          LqPAddrModule_1_xs.sv \
          LqMaskModule_xs.sv \
          LoadQueueRAW_delays_xs.sv \
          LoadQueueRAW_core_ut.sv \
          variants_xs.sv \
          tb.sv

# golden 顶层 LoadQueueRAW 例化的叶子子模块：
#   paddr/mask CAM、freelist、违例输出的 DelayN / DelayNWithValid。
#   含 CAM/freelist 各自再例化的 DelayN(WithValid) 写时序子模块（递归依赖）。
GOLDEN_DEPS = LqPAddrModule_1.sv LqMaskModule.sv FreeList_4.sv \
              DelayN_298.sv DelayN_13.sv \
              DelayNWithValid_148.sv DelayNWithValid_149.sv \
              DelayNWithValid_52.sv DelayNWithValid_55.sv DelayNWithValid_103.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAW.sv $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_DEPS))

# FM（both-sides elaborate）：golden 顶层 LoadQueueRAW（含 FreeList_4/LqPAddrModule_1/
#   LqMaskModule + 各自 DelayN 写时序子模块）vs 手写同名 wrapper（→ 核 xs_LoadQueueRAW_core，
#   核例化同名三子模块）。两侧子模块同名 → FM 层次配对逐点比对（非黑盒），
#   避免整体展平后签名匹配组合爆炸。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueRAW_wrapper.sv \
               $(RTL_DIR)/memblock/LoadQueueRAW.sv \
               $(RTL_DIR)/memblock/FreeList_4.sv \
               $(RTL_DIR)/memblock/LqPAddrModule_1.sv \
               $(RTL_DIR)/memblock/LqMaskModule.sv \
               $(RTL_DIR)/memblock/LoadQueueRAW_delays.sv
FM_VARIANTS = LoadQueueRAW
FM_REF_DEPS_LoadQueueRAW = $(GOLDEN_DEPS)

# 关闭 FM 的“合并同值重复寄存器”pass：本模块状态规模大（32 entry × 多字段 + CAM/freelist
# 子模块阵列），开启合并后签名分析的未配对寄存器搜索空间组合爆炸。关掉后由
# fm_eq.tcl 的 auto_match_flattened_arrays 按展平名规则配对阵列寄存器，可正常收敛。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
