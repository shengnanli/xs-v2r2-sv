MODULE = Og2ForVector

RTL_DIR  = ../../../rtl
# 本体（手写核 + 生成的 wrapper），无子模块。tb.sv 与 fm_pins_pre.tcl 由 scripts/gen_og2forvector.py 生成。
RTL_SRCS = $(RTL_DIR)/backend/Og2ForVector.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/Og2ForVector.sv
FM_VARIANTS = Og2ForVector

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期由 INITREG 选取值（0 / random / <数值种子>）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
