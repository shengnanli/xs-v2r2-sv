MODULE = FuBusyTableReadVariants

RTL_DIR  = ../../../rtl
VARIANTS = FuBusyTableRead FuBusyTableRead_2 FuBusyTableRead_22 FuBusyTableRead_23 \
           FuBusyTableRead_26 FuBusyTableRead_28 FuBusyTableRead_42 FuBusyTableRead_43 \
           FuBusyTableRead_52 FuBusyTableRead_53 FuBusyTableRead_68 FuBusyTableRead_69 \
           FuBusyTableRead_71 FuBusyTableRead_73 FuBusyTableRead_75 FuBusyTableRead_79 \
           FuBusyTableRead_80 FuBusyTableRead_105

# 核在 FuBusyTableRead.sv（xs_FuBusyTableRead_core，与家族最朴素的那个变体同文件），
# 其余 17 个是只设参数并对位端口的薄 wrapper（由 scripts/gen_fubusy_wbarb.py 生成）。
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。
# ★本族是纯组合，一个寄存器都没有，两轮 initreg 必然同结果★ —— 它在这里
# 证明不了复位域（本族没有复位域），跑它是为了钉住"确实没有隐藏状态"这件事：
# 若哪天核里不小心引入了一个寄存器，两轮日志就会开始分叉。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: mutants
mutants:
	python3 mutants.py
