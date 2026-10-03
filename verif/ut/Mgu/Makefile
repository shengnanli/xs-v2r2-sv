MODULE = Mgu

# Mgu（向量算术写回的 mask/tail 合并单元，纯组合）。golden 直接 child 一个：
#   ByteMaskTailGen（内含 UIntToContLow1s / UIntToContLow0s / MaskExtractor）
#   —— docs/coverage_three_axis.tsv 四者均 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Mgu.sv \
              $(GOLDEN_RTL)/ByteMaskTailGen.sv \
              $(GOLDEN_RTL)/UIntToContLow1s.sv \
              $(GOLDEN_RTL)/UIntToContLow0s.sv \
              $(GOLDEN_RTL)/MaskExtractor.sv
FM_VARIANTS = Mgu
FM_REF_DEPS_Mgu = ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
