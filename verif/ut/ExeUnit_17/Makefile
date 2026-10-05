MODULE = ExeUnit_17

# ExeUnit_17：向量执行单元外壳 —— Vfdiv(VFDivSqrt, 不定延迟) / Vidiv(VIDiv, 不定延迟)；含 busy。exublock2 lane。
# wrapper rtl/backend/ExeUnit_17.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核，不改）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（全部两侧白盒：ref 读 golden，impl 读重写件；闭包逐个取自各 child 的 receipt impl_closure / golden_closure）：
#   VFDivSqrt（evidence/462112cae72a/VFDivSqrt）；VIDiv（evidence/9193a2e0077d/VIDiv）；Dispatcher_17；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_17.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_17.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithLZDResult.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithLZDResult_6.sv \
           $(RTL_DIR)/backend/ShiftLeftPriorityWithLZDResult_8.sv \
           $(RTL_DIR)/backend/CSA3to2_20.sv \
           $(RTL_DIR)/backend/CSA3to2_24.sv \
           $(RTL_DIR)/backend/r4_qds_v2.sv \
           $(RTL_DIR)/backend/r4_qds_v2_spec.sv \
           $(RTL_DIR)/backend/fpdiv_r64_block_vector.sv \
           $(RTL_DIR)/backend/VectorFloatDividerR64.sv \
           $(RTL_DIR)/backend/lzc.sv \
           $(RTL_DIR)/backend/lzc_3.sv \
           $(RTL_DIR)/backend/lzc_4.sv \
           $(RTL_DIR)/backend/r4_qds_cg.sv \
           $(RTL_DIR)/backend/r4_qds.sv \
           $(RTL_DIR)/backend/r4_qds_spec.sv \
           $(RTL_DIR)/backend/fpsqrt_r16_block.sv \
           $(RTL_DIR)/backend/fpsqrt_vector_r16.sv \
           $(RTL_DIR)/backend/VectorFloatDivider.sv \
           $(RTL_DIR)/backend/VecDataSplitModule.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv \
           $(RTL_DIR)/backend/VFDivSqrt.sv \
           $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/CSA3_2_3988.sv \
           $(RTL_DIR)/backend/CSA3_2_3992.sv \
           $(RTL_DIR)/backend/CSA3_2_3987.sv \
           $(RTL_DIR)/backend/CSA3_2_4017.sv \
           $(RTL_DIR)/backend/CSA3_2_4111.sv \
           $(RTL_DIR)/backend/CSA3_2_4173.sv \
           $(RTL_DIR)/backend/SignDec.sv \
           $(RTL_DIR)/backend/Conversion.sv \
           $(RTL_DIR)/backend/Conversion_8.sv \
           $(RTL_DIR)/backend/Conversion_12.sv \
           $(RTL_DIR)/backend/SelBlock_v4.sv \
           $(RTL_DIR)/backend/SpecBlock_v4.sv \
           $(RTL_DIR)/backend/IterBlock_v4.sv \
           $(RTL_DIR)/backend/IterBlock_v4_4.sv \
           $(RTL_DIR)/backend/IterBlock_v4_6.sv \
           $(RTL_DIR)/backend/SRT4qdsCons.sv \
           $(RTL_DIR)/backend/SRT16Divint.sv \
           $(RTL_DIR)/backend/SRT16Divint_4.sv \
           $(RTL_DIR)/backend/SRT16Divint_6.sv \
           $(RTL_DIR)/backend/IterBlockI8Nr4.sv \
           $(RTL_DIR)/backend/I8DivNr4.sv \
           $(RTL_DIR)/backend/VectorIdiv.sv \
           $(RTL_DIR)/backend/VIDiv.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_17.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_17))

FM_VARIANTS = ExeUnit_17
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_17 = \
                         VFDivSqrt.sv \
                         ShiftLeftPriorityWithLZDResult.sv \
                         ShiftLeftPriorityWithLZDResult_6.sv \
                         ShiftLeftPriorityWithLZDResult_8.sv \
                         CSA3to2_20.sv \
                         CSA3to2_24.sv \
                         r4_qds_v2.sv \
                         r4_qds_v2_spec.sv \
                         fpdiv_r64_block_vector.sv \
                         VectorFloatDividerR64.sv \
                         lzc.sv \
                         lzc_3.sv \
                         lzc_4.sv \
                         r4_qds_cg.sv \
                         r4_qds.sv \
                         r4_qds_spec.sv \
                         fpsqrt_r16_block.sv \
                         fpsqrt_vector_r16.sv \
                         VectorFloatDivider.sv \
                         VecDataSplitModule.sv \
                         UIntToContLow1s.sv \
                         UIntToContLow0s.sv \
                         MaskExtractor.sv \
                         ByteMaskTailGen.sv \
                         Mgu.sv \
                         VIDiv.sv \
                         VectorIdiv.sv \
                         I8DivNr4.sv \
                         IterBlockI8Nr4.sv \
                         SRT16Divint.sv \
                         SRT16Divint_4.sv \
                         SRT16Divint_6.sv \
                         SRT4qdsCons.sv \
                         IterBlock_v4.sv \
                         IterBlock_v4_4.sv \
                         IterBlock_v4_6.sv \
                         SelBlock_v4.sv \
                         SpecBlock_v4.sv \
                         CSA3_2_3988.sv \
                         CSA3_2_3992.sv \
                         SignDec.sv \
                         CSA3_2_4017.sv \
                         CSA3_2_3987.sv \
                         CSA3_2_4111.sv \
                         CSA3_2_4173.sv \
                         Conversion.sv \
                         Conversion_8.sv \
                         Conversion_12.sv \
                         ClockGate.sv \
                         Dispatcher_17.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：子 FU 内与写回 pdest[7] 两侧对称死位，依据见 verif/fm_target_config/ExeUnit_17.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
