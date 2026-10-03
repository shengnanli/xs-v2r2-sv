MODULE = fpdiv_r64_block

# fpdiv_r64_block（标量浮点除法器一拍 3 个基 4 商位的迭代块，纯组合，只有 f64 一条通道）。
# golden 直接 child：CSA3to2_20 ×4 / CSA3to2_24 ×8 / r4_qds_v2 ×1 / r4_qds_v2_spec ×2
#   —— docs/coverage_three_axis.tsv 四者均 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CSA3to2_20.sv \
           $(RTL_DIR)/backend/CSA3to2_24.sv \
           $(RTL_DIR)/backend/r4_qds_v2.sv \
           $(RTL_DIR)/backend/r4_qds_v2_spec.sv \
           $(RTL_DIR)/backend/fpdiv_r64_block.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/fpdiv_r64_block.sv \
              $(GOLDEN_RTL)/CSA3to2_20.sv \
              $(GOLDEN_RTL)/CSA3to2_24.sv \
              $(GOLDEN_RTL)/r4_qds_v2.sv \
              $(GOLDEN_RTL)/r4_qds_v2_spec.sv
FM_VARIANTS = fpdiv_r64_block
FM_REF_DEPS_fpdiv_r64_block = CSA3to2_20.sv CSA3to2_24.sv r4_qds_v2.sv r4_qds_v2_spec.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
