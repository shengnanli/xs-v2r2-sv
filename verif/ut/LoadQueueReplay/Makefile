MODULE = LoadQueueReplay

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + svh（include 进核）+ 类型包。核内例化 3 个黑盒子模块。
RTL_SRCS = $(RTL_DIR)/memblock/loadqueuereplay_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueueReplay.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化：golden 顶层 LoadQueueReplay vs 手写 _xs 镜像（→ 可读核）。
# 两侧共用同一份 golden 子模块（AgeDetector_38 / FreeList_5 / LqVAddrModule）。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueReplay.sv \
              $(GOLDEN_RTL)/AgeDetector_38.sv \
              $(GOLDEN_RTL)/FreeList_5.sv \
              $(GOLDEN_RTL)/LqVAddrModule.sv \
              $(GOLDEN_RTL)/DelayN_13.sv \
              $(GOLDEN_RTL)/DelayNWithValid_152.sv \
              $(GOLDEN_RTL)/DelayNWithValid_155.sv

# FM：golden 顶层 vs 手写同名 wrapper（→ 可读核）。子模块两侧同源深 elaborate
# （StoreQueue/L2Top 配方）：FM_REF_DEPS 喂 ref 侧 + FM_SUBS 进 WRAPPER_SRCS 喂 impl 侧。
# 沿革：deps 只给 ref 侧曾致两侧不对称白盒展开（数万 unmatched, 8cc97a46 审计）；
# 改双侧同黑盒又违反 signoff-strict 禁黑盒（RC1 FINAL_306_REFRESH GAP）。双侧同源
# elaborate 同时满足对称性与 strict 无黑盒。
FM_SUBS = $(GOLDEN_RTL)/AgeDetector_38.sv $(GOLDEN_RTL)/FreeList_5.sv \
          $(GOLDEN_RTL)/LqVAddrModule.sv $(GOLDEN_RTL)/DelayN_13.sv \
          $(GOLDEN_RTL)/DelayNWithValid_152.sv $(GOLDEN_RTL)/DelayNWithValid_155.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueReplay_wrapper.sv $(FM_SUBS)
FM_VARIANTS = LoadQueueReplay
FM_REF_DEPS_LoadQueueReplay = AgeDetector_38.sv FreeList_5.sv LqVAddrModule.sv \
              DelayN_13.sv DelayNWithValid_152.sv DelayNWithValid_155.sv

# 关闭 FM「合并同值重复寄存器」：本模块状态规模大（72 entry × 多字段 + 3 流水级 +
# 冷却/perf），合并后未配对寄存器搜索空间组合爆炸。关掉由 fm_eq.tcl 按展平名配对阵列。
# golden 对 redirect 打拍出 s0_can_go_REG/s1_cancel_REG 等同值副本寄存器，需合并 pass 才能
# 与 impl 单份 redirect_*_q 配平（entry 元数据已显式钉点，合并不会造成不对称折叠）。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

# 让 `include 找到 rtl/memblock 下的 .svh（端口表 / 子模块实例表 / 各分节 body）
VCS += +incdir+$(RTL_DIR)/memblock

# golden 含 XSError/XSPerf 行为断言（非综合）；UT 关掉避免随机激励触发 $fatal/随机初始化
VCS += +define+SYNTHESIS
