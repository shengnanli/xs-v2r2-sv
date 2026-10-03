MODULE = fpsqrt_r16

# fpsqrt_r16（标量浮点开方器：状态机 + 前后处理，时序件）。golden 直接 child：
#   lzc / r4_qds_cg —— docs/coverage_three_axis.tsv 第 3 列 PROVEN_DIRECT → 两侧白盒（ref golden / impl 重写件）；
#   fpsqrt_r16_block —— 本 lane 重写并签核（verif/ut/fpsqrt_r16_block），连同它内部的 r4_qds / r4_qds_spec /
#   r4_qds_cg（均 PROVEN_DIRECT）两侧白盒。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/lzc.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/r4_qds.sv \
           $(RTL_DIR)/backend/r4_qds_spec.sv \
           $(RTL_DIR)/backend/fpsqrt_r16_block.sv \
           $(RTL_DIR)/backend/fpsqrt_r16.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/fpsqrt_r16.sv \
               $(GOLDEN_RTL)/lzc.sv \
               $(GOLDEN_RTL)/r4_qds_cg.sv \
               $(GOLDEN_RTL)/r4_qds.sv \
               $(GOLDEN_RTL)/r4_qds_spec.sv \
               $(GOLDEN_RTL)/fpsqrt_r16_block.sv

FM_VARIANTS = fpsqrt_r16
FM_REF_DEPS_fpsqrt_r16 = lzc.sv r4_qds_cg.sv r4_qds.sv r4_qds_spec.sv fpsqrt_r16_block.sv

# 关 merge_dup：golden 寄存器集合与重写件逐一对应，fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 除 fsm_q 外寄存器都不复位：tb 只在 finish_valid_o=1 时比结果/标志（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
