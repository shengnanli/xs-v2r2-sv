MODULE = RealWBArbiterVariants

RTL_DIR  = ../../../rtl
VARIANTS = RealWBArbiter RealWBArbiter_1 RealWBArbiter_2 RealWBArbiter_3 \
           RealWBArbiter_14 RealWBArbiter_15 RealWBArbiter_20 RealWBArbiter_21 \
           RealWBArbiter_26

# 本族的核体就是优先级法则本身，即共享件 rtl/common/xs_PriorityArbSelect.sv；
# 9 个文件都只做 payload 打包/拆包与端口对位（8 个由 scripts/gen_fubusy_wbarb.py 生成）。
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。
# ★本族是纯组合，连 clock/reset 端口都没有，两轮 initreg 必然同结果★ ——
# 跑它是为了钉住"确实没有隐藏状态"：核里若混进一个寄存器，两轮日志就会分叉。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: mutants
mutants:
	python3 mutants.py
