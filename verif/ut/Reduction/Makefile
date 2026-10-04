MODULE = Reduction

# Reduction（向量整数归约，两级流水）。child 全部 PROVEN_DIRECT，两侧白盒：
#   ref = golden 同名件（含 compare_* 内部的 Adder_xb*），impl = rtl/backend 下的重写件。
RTL_DIR  = ../../../rtl
CHILDREN = CSA3to2_124 CSA3to2_125 CSA3to2_127 CSA3to2_132 CSA4to2_15 CSA4to2_16 \
           compare_2to1 compare_2to1_2 compare_3to1 compare_3to1_1 compare_3to1_2 compare_3to1_6
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN))) \
           $(RTL_DIR)/backend/Reduction.sv
TB_SRCS  = tb.sv

GOLDEN_ADDERS = Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN)) $(GOLDEN_ADDERS)) \
              $(GOLDEN_RTL)/Reduction.sv
FM_VARIANTS = Reduction
# 字面文件名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_REF_DEPS_Reduction = CSA3to2_124.sv CSA3to2_125.sv CSA3to2_127.sv CSA3to2_132.sv CSA4to2_15.sv CSA4to2_16.sv \
                        compare_2to1.sv compare_2to1_2.sv compare_3to1.sv compare_3to1_1.sv compare_3to1_2.sv \
                        compare_3to1_6.sv Adder_xb.sv Adder_xb_3.sv Adder_xb_8.sv Adder_xb_20.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；
# 本模块 vd_vsew_reg_s1 与 vdType_reg_s1[1:0] 正是一对逐位恒等的寄存器。
FM_MERGE_DUP = false
# 对称死位（依据与期望数见 verif/fm_target_config/Reduction.tcl）：开 vmucp 让 FM 实际比较这些点（加强不是放宽）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 除 fire_reg_s1（RegNext，无复位）外全部异步复位；tb 先复位再比。
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
