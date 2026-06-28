# 自动生成：scripts/gen_tlxbar1.py —— 勿手改
MODULE = TLXbar_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/tlxbar1_pkg.sv \
           $(RTL_DIR)/uncore/TLXbar_1.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TLXbar_1_wrapper.sv
FM_VARIANTS = TLXbar_1
# FM: ref = golden TLXbar_1.sv; impl = pkg + 可读核 + wrapper。无外部依赖/黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
