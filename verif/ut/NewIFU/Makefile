MODULE = NewIFU

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 子模块黑盒适配器 + 共享译码包
RTL_SRCS = $(RTL_DIR)/frontend/predecode_pkg.sv \
           $(RTL_DIR)/frontend/NewIFU.sv \
           $(RTL_DIR)/frontend/NewIFU_subs.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/NewIFU_wrapper.sv

# golden NewIFU 及其例化的子模块(UT 双例化 / FM 比对 golden 侧需要)
GOLDEN_SRCS = $(GOLDEN_RTL)/NewIFU.sv \
              $(GOLDEN_RTL)/PreDecode.sv \
              $(GOLDEN_RTL)/RVCExpander.sv \
              $(GOLDEN_RTL)/F3Predecoder.sv \
              $(GOLDEN_RTL)/PredChecker.sv \
              $(GOLDEN_RTL)/FrontendTrigger.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = NewIFU
# FM ref 侧依赖：golden NewIFU 例化的子模块
# 两侧都把子模块当黑盒(impl 的 xs_newifu_* 适配层内例化同名 PreDecode/RVCExpander/...,
# ref 直接例化;均不读其源 → hdlin_unresolved_modules=black_box 统一黑盒,边界对齐)
FM_REF_DEPS_NewIFU =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
