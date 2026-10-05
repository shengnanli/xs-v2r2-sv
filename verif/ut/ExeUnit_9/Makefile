MODULE = ExeUnit_9

# ExeUnit_9：执行单元外壳 —— 单 FDivSqrt（不定延迟：busy + uncer 门控）。
# wrapper rtl/backend/ExeUnit_9.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（rewrite 优先，逐模块查 docs/coverage_three_axis.tsv，全部 PROVEN_*）：
#   RTL_SRCS        —— 已签核重写件（含本 lane 的叶子），两侧白盒：impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_9.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_9.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/FDivSqrt.sv \
           $(RTL_DIR)/backend/fpsqrt_r16.sv \
           $(RTL_DIR)/backend/lzc.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/fpsqrt_r16_block.sv \
           $(RTL_DIR)/backend/r4_qds.sv \
           $(RTL_DIR)/backend/r4_qds_spec.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithLZDResult.sv \
           $(RTL_DIR)/backend/fpdiv_r64_block.sv \
           $(RTL_DIR)/backend/CSA3to2_20.sv \
           $(RTL_DIR)/backend/r4_qds_v2.sv \
           $(RTL_DIR)/backend/CSA3to2_24.sv \
           $(RTL_DIR)/backend/r4_qds_v2_spec.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/FloatDivider.sv \
                  $(GOLDEN_RTL)/FloatDividerR64.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_9.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_9))

FM_VARIANTS = ExeUnit_9
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_9 = \
                        FDivSqrt.sv \
                        FloatDivider.sv \
                        fpsqrt_r16.sv \
                        lzc.sv \
                        r4_qds_cg.sv \
                        fpsqrt_r16_block.sv \
                        r4_qds.sv \
                        r4_qds_spec.sv \
                        FloatDividerR64.sv \
                        ShiftLeftPriorityWithLZDResult.sv \
                        fpdiv_r64_block.sv \
                        CSA3to2_20.sv \
                        r4_qds_v2.sv \
                        CSA3to2_24.sv \
                        r4_qds_v2_spec.sv \
                        ClockGate.sv \
                        Dispatcher_9.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：子 FU 内两侧对称死位，依据见 verif/fm_target_config/ExeUnit_9.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
