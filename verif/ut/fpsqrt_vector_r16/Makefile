MODULE = fpsqrt_vector_r16

# fpsqrt_vector_r16（向量浮点开方器顶层：状态机 + 前后处理，时序件）。golden 直接 child：
#   lzc / lzc_3 / lzc_4 ×2 / r4_qds_cg ×4 —— docs/coverage_three_axis.tsv 均 PROVEN_DIRECT → 两侧白盒；
#   fpsqrt_r16_block（3575 行迭代块，★无重写件★，coverage 标 PROVEN_IN_CONE）→ 照 verif/ut/ArithVecLeaves5
#   的先例走 RTL_GOLDEN_DEPS：两侧同读 golden 文件（UT 不 derive 不改名，FM impl/ref 同源 elaborate）。
#   该 golden 块内部还例化 r4_qds / r4_qds_spec（同样两侧同读 golden）与 r4_qds_cg（impl 侧绑到本仓重写件，
#   ref 侧绑到 golden；两者 PROVEN_DIRECT）。无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/lzc.sv \
           $(RTL_DIR)/backend/lzc_3.sv \
           $(RTL_DIR)/backend/lzc_4.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/fpsqrt_vector_r16.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/fpsqrt_vector_r16.sv \
              $(GOLDEN_RTL)/lzc.sv \
              $(GOLDEN_RTL)/lzc_3.sv \
              $(GOLDEN_RTL)/lzc_4.sv \
              $(GOLDEN_RTL)/r4_qds_cg.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/fpsqrt_r16_block.sv \
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
