MODULE = ExuBlock_1

# ExuBlock_1：浮点执行块（Backend fp 调度块的执行侧）—— 5 个 ExeUnit 的装配外壳。
# wrapper rtl/backend/ExuBlock_1.sv 与 fm_pins_pre.tcl 由 scripts/gen_exublock.py 从 golden 生成；本层唯一的时序逻辑
#   （每个 ExeUnit 一份 frm 打拍）在 rtl/backend/xs_ExuBlock_core.sv。tb 由本目录 gen.py 生成。
# 子树处置：5 个直接 child = ExeUnit_8 ×1 / ExeUnit_9 ×2 / ExeUnit_10 ×2，均已签核（exeunits lane），两侧白盒；
#   闭包 = 三个 ExeUnit UT Makefile 的 RTL_SRCS / RTL_GOLDEN_DEPS / FM_REF_DEPS 的并集（同一处置原样继承）：
#   RTL_SRCS        —— 已签核重写件，impl 读重写件、ref 读 golden；
#   RTL_GOLDEN_DEPS —— 无重写件的 PROVEN_IN_CONE 件两侧同读 golden；ClockGate 读本地签核件 rtl/common/ClockGate.sv。
# 无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExuBlock_1.sv \
           $(RTL_DIR)/backend/xs_ExuBlock_core.sv \
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
           $(RTL_DIR)/backend/CSA4to2.sv \
           $(RTL_DIR)/backend/ExeUnit_9.sv \
           $(RTL_DIR)/backend/Dispatcher_9.sv \
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
           $(RTL_DIR)/backend/r4_qds_v2_spec.sv \
           $(RTL_DIR)/backend/ExeUnit_10.sv \
           $(RTL_DIR)/backend/Dispatcher_10.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/FloatAdder.sv \
                  $(GOLDEN_RTL)/FloatAdderF64Pipeline.sv \
                  $(GOLDEN_RTL)/FarPathFloatAdderF64WidenPipeline.sv \
                  $(GOLDEN_RTL)/FPCVT.sv \
                  $(GOLDEN_RTL)/FloatDivider.sv \
                  $(GOLDEN_RTL)/FloatDividerR64.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExuBlock_1.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExuBlock_1))

FM_VARIANTS = ExuBlock_1
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExuBlock_1 = \
                         ExeUnit_8.sv \
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
                         Dispatcher_8.sv \
                         ExeUnit_9.sv \
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
                         Dispatcher_9.sv \
                         ExeUnit_10.sv \
                         Dispatcher_10.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：子 FU 内两侧对称死位，依据见 verif/fm_target_config/ExuBlock_1.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
