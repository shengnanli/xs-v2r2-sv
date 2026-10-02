MODULE = CsrCtlLeaves5
RTL_DIR = ../../../rtl
LEAVES = FcsrModule DcsrModule VcsrModule McycleModule MinstretModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
# 5 个叶在 golden 里都是自包含（0 个子模块例化），无 FM_REF_DEPS_*。
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# golden 这 5 个模块的 `ifndef SYNTHESIS 块里没有断言，只有寄存器随机初值
# initial 块；+define+SYNTHESIS 把它关掉，与 FM 读入口径一致，初值统一交给
# +vcs+initreg 机制。
# ★双例化 + VcsrModule 的不复位寄存器★：initreg 只能用常量档（0/1）。
# random 档会给 u_g/u_i 各摇一份互不相同的初值，未复位寄存器在被写之前两侧
# 必然不等，会把"初态不同"误报成失配（scripts/ut_common.mk 有同款注释）。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+0
