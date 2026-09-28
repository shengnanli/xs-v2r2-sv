MODULE = RealWBCollideChecker

RTL_DIR  = ../../../rtl
VARIANTS = RealWBCollideChecker RealWBCollideChecker_1 RealWBCollideChecker_2 \
           RealWBCollideChecker_3 RealWBCollideChecker_4

# 家族核 xs_RealWBCollideChecker_core 在 RealWBCollideChecker.sv；组内仲裁法则是共享件
# rtl/common/xs_PriorityArbSelect.sv。4 个薄 wrapper 与 tb 由 scripts/gen_realwbcc.py 生成。
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

# golden 侧：本族 5 变体 + 它们例化的 RealWBArbiter 子仲裁器（golden 原件）
GOLDEN_ARBS = RealWBArbiter RealWBArbiter_1 RealWBArbiter_2 RealWBArbiter_3 \
              RealWBArbiter_14 RealWBArbiter_15 RealWBArbiter_20 RealWBArbiter_21 \
              RealWBArbiter_26
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS) $(GOLDEN_ARBS)))
FM_VARIANTS = RealWBCollideChecker RealWBCollideChecker_1 RealWBCollideChecker_2 RealWBCollideChecker_3 RealWBCollideChecker_4
# 模型严格适用（fm_predict.py）：不合并重复寄存器（本族纯组合，本就没有寄存器）
FM_MERGE_DUP = false

# FM ref 侧依赖：golden 子仲裁器原件（impl 侧不例化 RealWBArbiter_*，直接用共享法则
# xs_PriorityArbSelect；FM 比的是展平后的组合锥，无黑盒）
FM_REF_DEPS_RealWBCollideChecker   = RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv
FM_REF_DEPS_RealWBCollideChecker_1 = RealWBArbiter_2.sv RealWBArbiter_3.sv
FM_REF_DEPS_RealWBCollideChecker_2 = RealWBArbiter_14.sv RealWBArbiter_15.sv
FM_REF_DEPS_RealWBCollideChecker_3 = RealWBArbiter_20.sv RealWBArbiter_21.sv
FM_REF_DEPS_RealWBCollideChecker_4 = RealWBArbiter_26.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合、无 clock/reset：三档 initreg 必然同结果 —— 跑它是为钉住「核里没有隐藏状态」。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
