MODULE = ExeUnit_8

# ExeUnit_8：执行单元外壳 —— FAlu / FCVT / f2v(IntFPToVec) / FMA；三个门控，inPipe 3 级。
# wrapper rtl/backend/ExeUnit_8.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（rewrite 优先，逐模块查 docs/coverage_three_axis.tsv，全部 PROVEN_*）：
#   RTL_SRCS        —— 已签核重写件（含本 lane 的叶子），两侧白盒：impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_8.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_8.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/FAlu.sv \
           $(RTL_DIR)/backend/Adder.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst.sv \
           $(RTL_DIR)/backend/FarPathAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/ClosePathFloatAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/ClosePathAdder.sv \
           $(RTL_DIR)/backend/ClosePathAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux.sv \
           $(RTL_DIR)/backend/FloatAdderF32F16MixedPipeline.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/Adder_2.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst_2.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedAdderPipeline.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux_1.sv \
           $(RTL_DIR)/backend/FCVT.sv \
           $(RTL_DIR)/backend/CVT64.sv \
           $(RTL_DIR)/backend/FP_INCVT.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/IntFPToVec.sv \
           $(RTL_DIR)/backend/FliHTable.sv \
           $(RTL_DIR)/backend/FliSTable.sv \
           $(RTL_DIR)/backend/FliDTable.sv \
           $(RTL_DIR)/backend/FMA.sv \
           $(RTL_DIR)/backend/FloatFMA.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16.sv \
           $(RTL_DIR)/backend/CSA_Nto2With3to2MainPipeline.sv \
           $(RTL_DIR)/backend/CSA3to2.sv \
           $(RTL_DIR)/backend/CSA4to2.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/FloatAdder.sv \
                  $(GOLDEN_RTL)/FloatAdderF64Pipeline.sv \
                  $(GOLDEN_RTL)/FarPathFloatAdderF64WidenPipeline.sv \
                  $(GOLDEN_RTL)/FPCVT.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_8.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_8))

FM_VARIANTS = ExeUnit_8
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_8 = \
                        FAlu.sv \
                        FloatAdder.sv \
                        FloatAdderF64Pipeline.sv \
                        FarPathFloatAdderF64WidenPipeline.sv \
                        Adder.sv \
                        FarShiftRightWithMuxInvFirst.sv \
                        FarPathAdderF64WidenPipeline.sv \
                        ClosePathFloatAdderF64WidenPipeline.sv \
                        ClosePathAdder.sv \
                        ClosePathAdder_2.sv \
                        CloseShiftLeftWithMux.sv \
                        FloatAdderF32F16MixedPipeline.sv \
                        FarPathF32WidenF16MixedPipeline.sv \
                        Adder_2.sv \
                        FarShiftRightWithMuxInvFirst_2.sv \
                        FarPathF32WidenF16MixedAdderPipeline.sv \
                        ClosePathF32WidenF16MixedPipeline.sv \
                        ClosePathF32WidenF16MixedPipelineAdder.sv \
                        ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                        CloseShiftLeftWithMux_1.sv \
                        FCVT.sv \
                        FPCVT.sv \
                        CVT64.sv \
                        FP_INCVT.sv \
                        CLZ_6.sv \
                        ShiftRightJam.sv \
                        RoundingUnit_3.sv \
                        RoundingUnit_4.sv \
                        IntFPToVec.sv \
                        FliHTable.sv \
                        FliSTable.sv \
                        FliDTable.sv \
                        FMA.sv \
                        FloatFMA.sv \
                        BoothEncoderF64F32F16.sv \
                        CSA_Nto2With3to2MainPipeline.sv \
                        CSA3to2.sv \
                        CSA4to2.sv \
                        ClockGate.sv \
                        Dispatcher_8.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：子 FU 内两侧对称死位，依据见 verif/fm_target_config/ExeUnit_8.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
