MODULE = SourceB

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv
TB_SRCS = tb.sv

# FastArbiter_5（4 入 1 出轮转仲裁器）两侧同源 elaborate：golden 的同一份文件
# 同时进 FM 的 impl 侧（RTL_GOLDEN_DEPS）与 ref 侧（FM_REF_DEPS）。
# 注意它**不能**再出现在 GOLDEN_SRCS 里——RTL_GOLDEN_DEPS 与 GOLDEN_SRCS 都会进
# VCS 命令行，列两次就是同一模块的重复定义（SNXbar 的 Makefile 里记过这条）。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FastArbiter_5.sv

FM_REF_DEPS_SourceB = FastArbiter_5.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = SourceB

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
