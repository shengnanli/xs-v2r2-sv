MODULE = RRArbiterInitVariants

RTL_DIR  = ../../../rtl
VARIANTS = RRArbiterInit RRArbiterInit_1 RRArbiterInit_4 RRArbiterInit_5 \
           RRArbiterInit_6 RRArbiterInit_7 RRArbiterInit_8 RRArbiterInit_9 \
           RRArbiterInit_11 RRArbiterInit_12 RRArbiterInit_13 RRArbiterInit_14 \
           RRArbiterInit_15 RRArbiterInit_16 RRArbiterInit_20

# 核在 RRArbiterInit.sv（xs_RRArbiterInit_core，与家族最朴素的那个变体同文件），
# 其余 14 个是只设参数并对位端口的薄 wrapper（由 gen.py 生成）。
RTL_SRCS = $(addprefix $(RTL_DIR)/common/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。本族**有**上电初值的
# 作用面：唯一的寄存器 lastGrant 是异步复位的，tb 在 rst=1 的窗口里才开始比对，
# 两轮都应当绿；真正把关复位域的是与 golden 的 always 块结构比对 + M4/M5 变异。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

# 判别力负测：注入真 bug，UT 必须报出来；再单独考一遍覆盖闸本身（不该绿时不许绿）。
# 变异只发生在 neg_build/（已 gitignore），不进库。见 mutants.py 头部说明。
.PHONY: mutants mutants-cov mutants-fm
mutants:
	python3 mutants.py
mutants-cov:
	python3 mutants.py --cov
mutants-fm:
	python3 mutants.py --fm
