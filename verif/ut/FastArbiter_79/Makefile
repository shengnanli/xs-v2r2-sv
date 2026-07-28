# 自动生成：scripts/gen_fastarbiter77.py —— 勿手改
MODULE = FastArbiter_79

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/FastArbiter_79.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter_79.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/FastArbiter_79_wrapper.sv
FM_VARIANTS = FastArbiter_79
# FM: ref = golden FastArbiter_79.sv; impl = 可读核 + wrapper。无外部依赖/黑盒/signoff-strict。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
