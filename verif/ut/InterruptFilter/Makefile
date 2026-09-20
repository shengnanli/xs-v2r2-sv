MODULE = InterruptFilter

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/InterruptFilter.sv
TB_SRCS  = tb.sv

# ★子依赖未闭合：DelayN_17 / DelayN_208 本轮由另一条 lane（agent/delayn-clz）重写，
#   尚未合入。这里两侧同取 golden 定义（ref 走 FM_REF_DEPS，impl 走 RTL_GOLDEN_DEPS），
#   于是本目标对这两个 child **零信息量**，证明是条件性的。
#   详见 FM_PREDICTION.md §2（UNCHANGED_GOLDEN_DEP / 子依赖未闭合）。
#   选"两侧白盒同源"而不是"两侧黑盒"：不扩大黑盒，且 glue（6 个实例的接线）真的被比出来。
FM_REF_DEPS_InterruptFilter = DelayN_17.sv DelayN_208.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/DelayN_17.sv $(GOLDEN_RTL)/DelayN_208.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/InterruptFilter.sv \
              $(GOLDEN_RTL)/DelayN_17.sv \
              $(GOLDEN_RTL)/DelayN_208.sv
FM_VARIANTS = InterruptFilter
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
