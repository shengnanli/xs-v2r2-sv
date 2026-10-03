MODULE = fpsqrt_vector_r16

# fpsqrt_vector_r16（向量浮点开方器顶层：状态机 + 前后处理，时序件）。golden 直接 child：
#   lzc / lzc_3 / lzc_4 ×2 / r4_qds_cg ×4 —— docs/coverage_three_axis.tsv 均 PROVEN_DIRECT → 两侧白盒；
#   fpsqrt_r16_block（迭代块）—— fpaddpath-sqrtblock lane 重写并签核（verif/ut/fpsqrt_r16_block），连同其内部的
#   r4_qds / r4_qds_spec / r4_qds_cg（均 PROVEN_DIRECT）两侧白盒：ref 读 golden 同名件，impl 读重写件。
#   （此前该块无重写件、两侧同读 golden，见 evidence/5a3282d30ab1 那一版。）无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/lzc.sv \
           $(RTL_DIR)/backend/lzc_3.sv \
           $(RTL_DIR)/backend/lzc_4.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/r4_qds.sv \
           $(RTL_DIR)/backend/r4_qds_spec.sv \
           $(RTL_DIR)/backend/fpsqrt_r16_block.sv \
           $(RTL_DIR)/backend/fpsqrt_vector_r16.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/fpsqrt_vector_r16.sv \
              $(GOLDEN_RTL)/lzc.sv \
              $(GOLDEN_RTL)/lzc_3.sv \
              $(GOLDEN_RTL)/lzc_4.sv \
              $(GOLDEN_RTL)/r4_qds_cg.sv \
              $(GOLDEN_RTL)/fpsqrt_r16_block.sv \
              $(GOLDEN_RTL)/r4_qds.sv \
              $(GOLDEN_RTL)/r4_qds_spec.sv
FM_VARIANTS = fpsqrt_vector_r16
FM_REF_DEPS_fpsqrt_vector_r16 = lzc.sv lzc_3.sv lzc_4.sv r4_qds_cg.sv fpsqrt_r16_block.sv r4_qds.sv r4_qds_spec.sv

# 关 merge_dup：golden 寄存器集合与重写件逐一对应，让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初始化 initial 块只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 口径一致。
# 除 fsm_q 外所有寄存器不复位：+random 档两侧初值不同，tb 只在 finish_valid_o 为 1 时比结果/标志（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
