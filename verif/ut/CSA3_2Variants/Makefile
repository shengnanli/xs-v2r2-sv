MODULE = CSA3_2Variants

RTL_DIR  = ../../../rtl
VARIANTS = CSA3_2_3956 CSA3_2_3960 CSA3_2_3962 CSA3_2_3987 CSA3_2_3988 \
           CSA3_2_3992 CSA3_2_4017 CSA3_2_4111 CSA3_2_4173

# 核在 CSA3_2.sv（xs_CSA3_2_core），9 个薄 wrapper 只设 WIDTH 参数并对位端口。
RTL_SRCS = $(RTL_DIR)/backend/CSA3_2.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。本族纯组合零寄存器，
# initreg 对它没有作用面，但两轮仍照跑——"没有作用面"是结论，不是免跑的理由。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
