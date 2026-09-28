MODULE = ImmExtractor_57
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ImmExtractor_57.sv
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/ImmExtractor_57.sv
FM_VARIANTS = ImmExtractor_57
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
