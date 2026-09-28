MODULE = BypassNetwork

# 核 + wrapper 在 rtl/backend/BypassNetwork.sv；子模块 ImmExtractor 各变体用本仓重写件
# （均已独立签核：ImmExtractor/_12/_57 在 main，_2/_37 本 lane）。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ImmExtractor.sv \
           $(RTL_DIR)/backend/ImmExtractor_2.sv \
           $(RTL_DIR)/backend/ImmExtractor_12.sv \
           $(RTL_DIR)/backend/ImmExtractor_37.sv \
           $(RTL_DIR)/backend/ImmExtractor_57.sv \
           $(RTL_DIR)/backend/BypassNetwork.sv
TB_SRCS = tb.sv

# golden 侧闭包：本体 + ImmExtractor 五个变体 + UIntExtractor 两个（one-hot 展开件）
GOLDEN_DEPS = ImmExtractor.sv ImmExtractor_2.sv ImmExtractor_12.sv ImmExtractor_37.sv \
              ImmExtractor_57.sv UIntExtractor_27_000011100000000000001010101.sv \
              UIntExtractor_27_000000000000001010100000000.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/BypassNetwork.sv $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_DEPS))
FM_VARIANTS = BypassNetwork
FM_REF_DEPS_BypassNetwork = $(GOLDEN_DEPS)

PORTLINT_ORDER = fail

# 关掉重复寄存器合并，让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
