MODULE = ExeUnit_15

# ExeUnit_15：向量执行单元外壳 —— Vfma(VFMA, 延迟 3) / VialuFix(VIAluFix, 延迟 1)。exublock2 lane。
# wrapper rtl/backend/ExeUnit_15.sv 与 fm_pins_pre.tcl 由 scripts/gen_exeunit.py 从 golden 生成；控制逻辑在
#   rtl/backend/xs_ExeUnit_core.sv（共享核，不改）。tb 由 scripts/gen_exeunits_ut.py 生成。
# 子树处置（全部两侧白盒：ref 读 golden，impl 读重写件；闭包逐个取自各 child 的 receipt impl_closure / golden_closure）：
#   VFMA（evidence/0ff9bafc9912/VFMA）；VIAluFix（evidence/65d1243f7a9c/VIAluFix）；Dispatcher_15；ClockGate 读本地签核件 rtl/common/ClockGate.sv（codex 0208）。
# 无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = \
           $(RTL_DIR)/backend/ExeUnit_15.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_15.sv \
           $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16_3.sv \
           $(RTL_DIR)/backend/BoothEncoderF64F32F16.sv \
           $(RTL_DIR)/backend/CSA_Nto2With3to2MainPipeline.sv \
           $(RTL_DIR)/backend/CSA3to2.sv \
           $(RTL_DIR)/backend/CSA4to2.sv \
           $(RTL_DIR)/backend/VectorFloatFMA.sv \
           $(RTL_DIR)/backend/VecDataSplitModule.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv \
           $(RTL_DIR)/backend/VFMA.sv \
           $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_11.sv \
           $(RTL_DIR)/backend/VIAluSrcTypeModule.sv \
           $(RTL_DIR)/backend/VIntMisc64b.sv \
           $(RTL_DIR)/backend/VIntAdder64b.sv \
           $(RTL_DIR)/backend/Adder_chain_rnd.sv \
           $(RTL_DIR)/backend/VFixPoint64b.sv \
           $(RTL_DIR)/backend/VIntFixpAlu64b.sv \
           $(RTL_DIR)/backend/Mgtu.sv \
           $(RTL_DIR)/backend/VIAluFix.sv
RTL_GOLDEN_DEPS = \
                  $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_15.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_15))

FM_VARIANTS = ExeUnit_15
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_ExeUnit_15 = \
                         VFMA.sv \
                         BoothEncoderF64F32F16_3.sv \
                         CSA_Nto2With3to2MainPipeline.sv \
                         CSA3to2.sv \
                         CSA4to2.sv \
                         VectorFloatFMA.sv \
                         VecDataSplitModule.sv \
                         UIntToContLow1s.sv \
                         UIntToContLow0s.sv \
                         MaskExtractor.sv \
                         ByteMaskTailGen.sv \
                         Mgu.sv \
                         VIAluFix.sv \
                         CLZ_6.sv \
                         CLZ_7.sv \
                         CLZ_9.sv \
                         CLZ_11.sv \
                         VIAluSrcTypeModule.sv \
                         VIntMisc64b.sv \
                         VIntAdder64b.sv \
                         Adder_chain_rnd.sv \
                         VFixPoint64b.sv \
                         VIntFixpAlu64b.sv \
                         Mgtu.sv \
                         ClockGate.sv \
                         Dispatcher_15.sv
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：外壳 inPipe 里 FU 只读低位的字段（src_4 / vuopIdx / fuOpType）两侧对称死位，依据见 verif/fm_target_config/ExeUnit_15.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
