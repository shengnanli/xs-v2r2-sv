MODULE = ImmExtractorBypass

# BypassNetwork 用到、此前未签的两个 ImmExtractor 变体。核体共用
# rtl/backend/ImmExtractor.sv 的 xs_imm_extractor_core（不改核，只加薄 wrapper）。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ImmExtractor.sv \
           $(RTL_DIR)/backend/ImmExtractor_2.sv \
           $(RTL_DIR)/backend/ImmExtractor_37.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ImmExtractor_2.sv \
              $(GOLDEN_RTL)/ImmExtractor_37.sv
FM_VARIANTS = ImmExtractor_2 ImmExtractor_37

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合叶子：跑 initreg 各档是为了钉住"没有隐藏状态"。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
