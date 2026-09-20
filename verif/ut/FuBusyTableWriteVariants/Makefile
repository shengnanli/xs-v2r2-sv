MODULE = FuBusyTableWriteVariants

RTL_DIR  = ../../../rtl
VARIANTS = FuBusyTableWrite FuBusyTableWrite_22 FuBusyTableWrite_26 FuBusyTableWrite_42 \
           FuBusyTableWrite_43 FuBusyTableWrite_52 FuBusyTableWrite_53 FuBusyTableWrite_68 \
           FuBusyTableWrite_69 FuBusyTableWrite_71 FuBusyTableWrite_73 FuBusyTableWrite_75 \
           FuBusyTableWrite_79 FuBusyTableWrite_80 FuBusyTableWrite_105

# 核在 FuBusyTableWrite.sv（xs_FuBusyTableWrite_core），其余 14 个是薄 wrapper
# （由 scripts/gen_fubusy_wbarb.py 生成）。
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。本族唯一的寄存器
# fuBusyTable 是**异步高有效**复位的，tb 起手就拉 8 拍复位，两轮都应当绿；
# 真正把关复位域的是与 golden 的 always 块结构比对 + mutants.py 的复位域变异。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: mutants
mutants:
	python3 mutants.py
