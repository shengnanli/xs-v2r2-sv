MODULE = fpsqrt_r16_block

# fpsqrt_r16_block（radix-16 开方迭代块，纯组合）。golden 直接 child：
#   r4_qds ×4 / r4_qds_spec ×4 / r4_qds_cg ×40 —— docs/coverage_three_axis.tsv 第 3 列均 PROVEN_DIRECT
#   （本仓 rtl/backend 下的重写件，k3next20 lane 签核）→ 两侧白盒：ref 读 golden 同名件，impl 读重写件。
#   无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/r4_qds.sv \
           $(RTL_DIR)/backend/r4_qds_spec.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/fpsqrt_r16_block.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/fpsqrt_r16_block.sv \
               $(GOLDEN_RTL)/r4_qds.sv \
               $(GOLDEN_RTL)/r4_qds_spec.sv \
               $(GOLDEN_RTL)/r4_qds_cg.sv

FM_VARIANTS = fpsqrt_r16_block
FM_REF_DEPS_fpsqrt_r16_block = r4_qds.sv r4_qds_spec.sv r4_qds_cg.sv

# 纯组合、零寄存器：merge_dup 与比较点无关；按全仓口径写 false，fm_predict 的模型（输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器；initreg 三档只为与全仓 UT 口径一致（结果不应随档变化）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
