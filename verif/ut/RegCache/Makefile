MODULE = RegCache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:参数包 + 顶层路由/流水核(黑盒子模块在 core 内 `include 例化)。
# regcache_blackbox.svh 由 scripts/gen_regcache.py 生成,需在 RTL_DIR/backend 下。
RTL_SRCS = $(RTL_DIR)/backend/regcache_pkg.sv \
           $(RTL_DIR)/backend/RegCache.sv

TB_SRCS = variants_xs.sv tb.sv

# RegCache 的 6 个黑盒叶子(数据体/年龄计时/替换选择,各 Int+Mem 两份)。
RC_LEAVES = RegCacheDataModule.sv RegCacheDataModule_1.sv \
            RegCacheAgeTimer.sv RegCacheAgeTimer_1.sv \
            RegCacheAgeDetector.sv RegCacheAgeDetector_1.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/RegCache.sv $(addprefix $(GOLDEN_RTL)/,$(RC_LEAVES))

# FM:golden 顶层 RegCache(含黑盒叶子) vs 手写同名 wrapper(-> 核 + 同名黑盒叶子)。
# impl 侧也带上同一份 golden 叶子,使两边子模块完全相同、只比对顶层路由/流水逻辑。
WRAPPER_SRCS = $(RTL_DIR)/backend/RegCache_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(RC_LEAVES))
FM_VARIANTS = RegCache
FM_REF_DEPS_RegCache = $(RC_LEAVES)

include ../../../scripts/ut_common.mk

# core `include 的 svh 在 RTL_DIR/backend,需把该目录加入 incdir;
# golden 叶子在 SYNTHESIS 下关随机初始化,与可读核对齐。
VCS += +incdir+$(RTL_DIR)/backend +define+SYNTHESIS
