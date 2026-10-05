MODULE = ExeUnit_16

# ExeUnit_16：向量执行单元外壳 —— Vfalu(VFAlu, 延迟 1)。exublock2 lane。
# wrapper rtl/backend/ExeUnit_16.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核，不改）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（全部两侧白盒：ref 读 golden，impl 读重写件；闭包逐个取自各 child 的 receipt impl_closure / golden_closure）：
#   VFAlu（evidence/f60583b94598/VFAlu）；Dispatcher_16；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_16.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_16.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithF32EXPResult.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithF64EXPResult.sv \
           $(RTL_DIR)/backend/FloatAdderWidenFormat.sv \
           $(RTL_DIR)/backend/Adder_18.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst_18.sv \
           $(RTL_DIR)/backend/FarPathAdderF16Pipeline.sv \
           $(RTL_DIR)/backend/FarPathF16Pipeline.sv \
           $(RTL_DIR)/backend/ClosePathAdderF16Pipeline.sv \
           $(RTL_DIR)/backend/ClosePathAdderF16Pipeline_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux_9.sv \
           $(RTL_DIR)/backend/ClosePathF16Pipeline.sv \
           $(RTL_DIR)/backend/FloatAdderF16Pipeline.sv \
           $(RTL_DIR)/backend/Adder_2.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst_2.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedAdderPipeline.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux_1.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/FloatAdderF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/Adder.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst.sv \
           $(RTL_DIR)/backend/FarPathAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/FarPathFloatAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/ClosePathAdder.sv \
           $(RTL_DIR)/backend/ClosePathAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux.sv \
           $(RTL_DIR)/backend/ClosePathFloatAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/FloatAdderF64WidenPipeline.sv \
           $(RTL_DIR)/backend/VectorFloatAdder.sv \
           $(RTL_DIR)/backend/VecDataSplitModule.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv \
           $(RTL_DIR)/backend/Mgtu.sv \
           $(RTL_DIR)/backend/VFAlu.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_16.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_16))

FM_VARIANTS = ExeUnit_16
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_16 = \
                         VFAlu.sv \
                         ShiftLeftPriorityWithF32EXPResult.sv \
                         ShiftLeftPriorityWithF64EXPResult.sv \
                         FloatAdderWidenFormat.sv \
                         Adder_18.sv \
                         FarShiftRightWithMuxInvFirst_18.sv \
                         FarPathAdderF16Pipeline.sv \
                         FarPathF16Pipeline.sv \
                         ClosePathAdderF16Pipeline.sv \
                         ClosePathAdderF16Pipeline_2.sv \
                         CloseShiftLeftWithMux_9.sv \
                         ClosePathF16Pipeline.sv \
                         FloatAdderF16Pipeline.sv \
                         Adder_2.sv \
                         FarShiftRightWithMuxInvFirst_2.sv \
                         FarPathF32WidenF16MixedAdderPipeline.sv \
                         FarPathF32WidenF16MixedPipeline.sv \
                         ClosePathF32WidenF16MixedPipelineAdder.sv \
                         ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                         CloseShiftLeftWithMux_1.sv \
                         ClosePathF32WidenF16MixedPipeline.sv \
                         FloatAdderF32WidenF16MixedPipeline.sv \
                         Adder.sv \
                         FarShiftRightWithMuxInvFirst.sv \
                         FarPathAdderF64WidenPipeline.sv \
                         FarPathFloatAdderF64WidenPipeline.sv \
                         ClosePathAdder.sv \
                         ClosePathAdder_2.sv \
                         CloseShiftLeftWithMux.sv \
                         ClosePathFloatAdderF64WidenPipeline.sv \
                         FloatAdderF64WidenPipeline.sv \
                         VectorFloatAdder.sv \
                         VecDataSplitModule.sv \
                         UIntToContLow1s.sv \
                         UIntToContLow0s.sv \
                         MaskExtractor.sv \
                         ByteMaskTailGen.sv \
                         Mgu.sv \
                         Mgtu.sv \
                         ClockGate.sv \
                         Dispatcher_16.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：外壳 src_4 高位与子 FU 内两侧对称死位，依据见 verif/fm_target_config/ExeUnit_16.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
