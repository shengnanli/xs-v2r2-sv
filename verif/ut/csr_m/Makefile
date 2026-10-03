MODULE = csr_m
RTL_DIR = ../../../rtl
LEAVES = MLevelPermitModule MbmcModule McontextModule McorepwrModule McounterenModule McountinhibitModule MedelegModule MenvcfgModule MflushpwrModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= +vcs+initreg+0
SIM_ARGS += $(INITREG)
