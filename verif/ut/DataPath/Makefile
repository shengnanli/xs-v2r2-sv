MODULE = DataPath

# DataPath 本体（golden 25,618 行 / 2,426 端口）。
# 子模块（62 个实例 / 28 种）处置 —— 全部两侧白盒，无黑盒：
#   * 本 lane 重写并已签核（evidence/833a201786eb）：5 个 *RFWBCollideChecker、5 个 *RFReadArbiter、
#     Fp/Vf/V0 RegFilePart*、VlRegFile（核 xs_Regfile_core）；
#   * 已签核的重写件（docs/coverage_three_axis.tsv PROVEN_DIRECT）：WBArbiter 家族 13 变体、RegCache、
#     UIntExtractor_27_* 两个（codex/readable-leaves-15，main 9f15cac9）；
#   * IntRegFilePart0..3：intrf lane 已签核并合入 main（xs_IntRegFilePart_core + 4 个薄 wrapper），impl 用重写件；
#   * RegCache 的 6 个子模块（GOLDEN_REUSE / PROVEN_IN_CONE）两侧同源 golden（RTL_GOLDEN_DEPS）。
RTL_DIR  = ../../../rtl
WBARB    = WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_3 WBArbiter_30 WBArbiter_33 \
           WBArbiter_38 WBArbiter_52 WBArbiter_55 WBArbiter_58 WBArbiter_64 \
           WBArbiter_65 WBArbiter_66
SHELLS   = IntRFWBCollideChecker FpRFWBCollideChecker VfRFWBCollideChecker \
           V0RFWBCollideChecker VlRFWBCollideChecker \
           IntRFReadArbiter FpRFReadArbiter VfRFReadArbiter V0RFReadArbiter VlRFReadArbiter
RFILES   = IntRegFilePart0 IntRegFilePart1 IntRegFilePart2 IntRegFilePart3 \
           VlRegFile V0RegFilePart0 V0RegFilePart1 \
           VfRegFilePart0 VfRegFilePart1 VfRegFilePart2 VfRegFilePart3 \
           FpRegFilePart0 FpRegFilePart1 FpRegFilePart2 FpRegFilePart3
UEXT     = UIntExtractor_27_000011100000000000001010101 UIntExtractor_27_000000000000001010100000000
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(RTL_DIR)/backend/xs_Regfile_core.sv \
           $(RTL_DIR)/backend/xs_IntRegFilePart_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(WBARB) $(SHELLS) $(RFILES) $(UEXT))) \
           $(RTL_DIR)/backend/RegCache.sv \
           $(RTL_DIR)/backend/DataPath.sv
GOLDEN_SAME = RegCacheAgeDetector RegCacheAgeDetector_1 RegCacheAgeTimer RegCacheAgeTimer_1 \
              RegCacheDataModule RegCacheDataModule_1
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(GOLDEN_SAME)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,DataPath $(WBARB) $(SHELLS) $(RFILES) $(UEXT) RegCache $(GOLDEN_SAME)))

FM_VARIANTS = DataPath
# golden 闭包逐个写出文件名（fm_predict 的模型不展开 $(addsuffix ...)，写成函数会让模型只数到一部分）
FM_REF_DEPS_DataPath = WBArbiter.sv \
                       WBArbiter_1.sv \
                       WBArbiter_2.sv \
                       WBArbiter_3.sv \
                       WBArbiter_30.sv \
                       WBArbiter_33.sv \
                       WBArbiter_38.sv \
                       WBArbiter_52.sv \
                       WBArbiter_55.sv \
                       WBArbiter_58.sv \
                       WBArbiter_64.sv \
                       WBArbiter_65.sv \
                       WBArbiter_66.sv \
                       IntRFWBCollideChecker.sv \
                       FpRFWBCollideChecker.sv \
                       VfRFWBCollideChecker.sv \
                       V0RFWBCollideChecker.sv \
                       VlRFWBCollideChecker.sv \
                       IntRFReadArbiter.sv \
                       FpRFReadArbiter.sv \
                       VfRFReadArbiter.sv \
                       V0RFReadArbiter.sv \
                       VlRFReadArbiter.sv \
                       IntRegFilePart0.sv \
                       IntRegFilePart1.sv \
                       IntRegFilePart2.sv \
                       IntRegFilePart3.sv \
                       VlRegFile.sv \
                       V0RegFilePart0.sv \
                       V0RegFilePart1.sv \
                       VfRegFilePart0.sv \
                       VfRegFilePart1.sv \
                       VfRegFilePart2.sv \
                       VfRegFilePart3.sv \
                       FpRegFilePart0.sv \
                       FpRegFilePart1.sv \
                       FpRegFilePart2.sv \
                       FpRegFilePart3.sv \
                       UIntExtractor_27_000011100000000000001010101.sv \
                       UIntExtractor_27_000000000000001010100000000.sv \
                       RegCache.sv \
                       RegCacheAgeDetector.sv \
                       RegCacheAgeDetector_1.sv \
                       RegCacheAgeTimer.sv \
                       RegCacheAgeTimer_1.sv \
                       RegCacheDataModule.sv \
                       RegCacheDataModule_1.sv

FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_datapath.py --check

# 481 个对称死位（matched_nc）开 vmucp 让 FM 真去比；依据与六条判据见 verif/fm_target_config/DataPath.tcl。
# golden-only 的 21 个 RegCache 死位走 verif/dead_ref/DataPath.json（ut_common 自动带上 --dead-ref）。
fm-DataPath: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
