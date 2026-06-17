MODULE = VSetRvfWvf

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核:共享类型/计算包 + 组合核。
RTL_SRCS = $(RTL_DIR)/backend/vset_pkg.sv \
           $(RTL_DIR)/backend/VSetRvfWvf.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 VSetRvfWvf 例化 VsetModule(vl 计算叶子),UT 双例化需带上。
GOLDEN_SRCS = $(GOLDEN_RTL)/VSetRvfWvf.sv $(GOLDEN_RTL)/VsetModule.sv

# FM:golden 顶层 VSetRvfWvf(+ VsetModule) vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/VSetRvfWvf_wrapper.sv
FM_VARIANTS = VSetRvfWvf
FM_REF_DEPS_VSetRvfWvf = VsetModule.sv

include ../../../scripts/ut_common.mk

# golden 无断言,SYNTHESIS 关随机初始化以与可读核对齐。
VCS += +define+SYNTHESIS
