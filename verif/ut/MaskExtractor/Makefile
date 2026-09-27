MODULE = MaskExtractor
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/MaskExtractor.sv
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/MaskExtractor.sv
FM_VARIANTS = MaskExtractor
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
