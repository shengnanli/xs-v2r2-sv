# =============================================================================
# ExeUnit_13 UT/FM（agent/exeunit13）：外壳与钉点由 scripts/gen_exeunit.py 生成，tb 由 scripts/gen_exeunits_ut.py 生成；
# 子 FU（VFMA / VIAluFix / VIMacU / VPPU）与 Dispatcher_13、ClockGate 两侧白盒（全为已签核重写件）。
# impl 源清单 = 各子 FU 自己 UT Makefile 的 RTL_SRCS 并集（同 verif/ut/ExeUnit_14/Makefile 做法）。
# =============================================================================
MODULE = ExeUnit_13
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/ExeUnit_13.sv \
           $(RTL_DIR)/backend/xs_ExeUnit_core.sv \
           $(RTL_DIR)/backend/Dispatcher_13.sv \
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
           $(RTL_DIR)/backend/VIAluFix.sv \
           $(RTL_DIR)/backend/VIMac64b.sv \
           $(RTL_DIR)/backend/VIMacSrcTypeModule.sv \
           $(RTL_DIR)/backend/VIMacU.sv \
           $(RTL_DIR)/backend/slideupVs2VdTable.sv \
           $(RTL_DIR)/backend/slidednVs2VdTable.sv \
           $(RTL_DIR)/backend/Permutation.sv \
           $(RTL_DIR)/backend/VPermSrcTypeModule.sv \
           $(RTL_DIR)/backend/VPPU.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv
TB_SRCS  = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/ExeUnit_13.sv $(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_ExeUnit_13))
FM_VARIANTS = ExeUnit_13
FM_REF_DEPS_ExeUnit_13 = Adder_chain_rnd.sv \
                         BoothEncoderF64F32F16_3.sv \
                         ByteMaskTailGen.sv \
                         CLZ_11.sv \
                         CLZ_6.sv \
                         CLZ_7.sv \
                         CLZ_9.sv \
                         CSA3to2.sv \
                         CSA4to2.sv \
                         CSA_Nto2With3to2MainPipeline.sv \
                         ClockGate.sv \
                         Dispatcher_13.sv \
                         MaskExtractor.sv \
                         Mgtu.sv \
                         Mgu.sv \
                         Permutation.sv \
                         UIntToContLow0s.sv \
                         UIntToContLow1s.sv \
                         VFMA.sv \
                         VFixPoint64b.sv \
                         VIAluFix.sv \
                         VIAluSrcTypeModule.sv \
                         VIMac64b.sv \
                         VIMacSrcTypeModule.sv \
                         VIMacU.sv \
                         VIntAdder64b.sv \
                         VIntFixpAlu64b.sv \
                         VIntMisc64b.sv \
                         VPPU.sv \
                         VPermSrcTypeModule.sv \
                         VecDataSplitModule.sv \
                         VectorFloatFMA.sv \
                         slidednVs2VdTable.sv \
                         slideupVs2VdTable.sv
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
