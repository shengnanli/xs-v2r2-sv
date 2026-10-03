MODULE = PmpcfgLeaves5

RTL_DIR = ../../../rtl
# 族 C：PMP cfg 五变体共用一个无参数核（golden 五变体去模块名后逐字节相同，
# 由 scripts/gen_pmpcfg_leaves5.py 每次重跑断言），故 RTL_SRCS = 共享核 + 5 薄 wrapper。
LEAVES = Pmp0cfgModule Pmp1cfgModule Pmp2cfgModule Pmp3cfgModule Pmp4cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmpcfg_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
