# 自动生成：scripts/gen_fastarbiter.py —— 勿手改
MODULE = FastArbiter_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/FastArbiter_2.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter_2.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/FastArbiter_2_wrapper.sv
FM_VARIANTS = FastArbiter_2
# FM: ref = golden FastArbiter_2.sv; impl = 自包含可读核 + wrapper (无 pkg 依赖/无黑盒)。
# 加强证明: pendingMask_reg[0] 是本族 round-robin 结构死位 (rrGrantMask[0]≡0 掩掉),
# 两侧同名对称 cone-dead → FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM 实际比较
# 证等价 (非 waiver), 得 0 unread clean SUCCEEDED。须 main 把 FastArbiter_2 加入 fm_eq.tcl 白名单。

FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
