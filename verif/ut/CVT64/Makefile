MODULE = CVT64

# CVT64（标量浮点转换的 64 位总装，FPCVT 的唯一子模块）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子模块 FP_INCVT 及其子树（CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4）全部是已签核
# 重写件（PROVEN_DIRECT）：两侧白盒 —— impl 读重写件，ref 读 golden；无黑盒、无同源共享件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/FP_INCVT.sv \
           $(RTL_DIR)/backend/CVT64.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/CVT64.sv $(GOLDEN_RTL)/FP_INCVT.sv $(GOLDEN_RTL)/CLZ_6.sv \
               $(GOLDEN_RTL)/ShiftRightJam.sv $(GOLDEN_RTL)/RoundingUnit_3.sv $(GOLDEN_RTL)/RoundingUnit_4.sv

FM_VARIANTS = CVT64
FM_REF_DEPS_CVT64 = FP_INCVT.sv CLZ_6.sv ShiftRightJam.sv RoundingUnit_3.sv RoundingUnit_4.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：FP_INCVT 内 fcvtmodTrueExpReg[4:0] 两侧对称死位，依据见 verif/fm_target_config/CVT64.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
