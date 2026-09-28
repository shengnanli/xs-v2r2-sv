MODULE = NewAgeDetector

# NewAgeDetector 家族（2 个变体）：golden 里都是自包含叶子（0 个子模块），无 FM_REF_DEPS。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/NewAgeDetector.sv \
           $(RTL_DIR)/backend/NewAgeDetector_6.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/NewAgeDetector_6.sv

FM_VARIANTS = NewAgeDetector NewAgeDetector_6

# fm_predict 的 passing 模型只在 merge_dup=false 时严格适用（加强不是放宽）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 initial 块在 `ifndef SYNTHESIS 里；两侧与 FM 同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（INITREG=0 / random / <数值种子>）。
# 唯一的寄存器 age_0_1 带异步复位，tb 先复位再比，所以各档都应全绿。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
