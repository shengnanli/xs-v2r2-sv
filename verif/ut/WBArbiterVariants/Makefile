MODULE = WBArbiterVariants

RTL_DIR  = ../../../rtl
VARIANTS = WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_3 WBArbiter_30 WBArbiter_33 \
           WBArbiter_38 WBArbiter_52 WBArbiter_55 WBArbiter_58 WBArbiter_64 \
           WBArbiter_65 WBArbiter_66

# 核在 WBArbiter.sv（xs_WBArbiter_core），其余 12 个是薄 wrapper
# （由 scripts/gen_fubusy_wbarb.py 生成）。优先级那一级是与 RealWBArbiter 族
# 共用的 rtl/common/xs_PriorityArbSelect.sv，必须一起编。
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。本族 2N+1 个寄存器
# 全是**异步高有效**复位，tb 起手拉 8 拍复位，两轮都应当绿；真正把关复位域的是
# 与 golden 的 always 块结构比对 + mutants.py 的复位域变异。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: mutants
mutants:
	python3 mutants.py
