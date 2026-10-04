MODULE = SMSPrefetcher

# SMSPrefetcher：SMS 空间预取器总控（手写核 xs_SMSPrefetcher_core + 生成的 golden 同名 wrapper，scripts/gen_sms.py）。
# 5 个直接 child 全部已签核，两侧白盒：ref 读 golden，impl 读本仓重写件：
#   train_filter = SMSTrainFilter（xs_TrainFilter_core）、active_gen_table = ActiveGenerationTable、
#   stride = StridePF（二者用 xs_PlruReplacer）、pf_filter = PrefetchFilter（RRArbiterInit 家族）、
#   pht = PatternHistoryTable（其下 SRAMTemplate_145 / MbistClockGateCell / OverrideableQueue(_1) / Arbiter3_PfGenReq）。
# ClockGate 读本地签核件 rtl/common/ClockGate.sv；厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht / array_12
# 两侧同读 golden，叶子 array_12_ext 不进 FM（两侧对称黑盒，verif/allow/SMSPrefetcher.json 声明 vendor_macro，
# 与 PatternHistoryTable 签核时同一处置）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/SMSPrefetcher.sv \
           $(RTL_DIR)/memblock/xs_TrainFilter_core.sv \
           $(RTL_DIR)/memblock/SMSTrainFilter.sv \
           $(RTL_DIR)/memblock/ActiveGenerationTable.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/memblock/StridePF.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_5.sv \
           $(RTL_DIR)/common/RRArbiterInit_6.sv \
           $(RTL_DIR)/memblock/PrefetchFilter.sv \
           $(RTL_DIR)/memblock/PatternHistoryTable.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_145.sv \
           $(RTL_DIR)/common/MbistClockGateCell.sv \
           $(RTL_DIR)/common/xs_OverrideableQueue_core.sv \
           $(RTL_DIR)/frontend/OverrideableQueue.sv \
           $(RTL_DIR)/frontend/OverrideableQueue_1.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/frontend/Arbiter3_PfGenReq.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
                  $(GOLDEN_RTL)/array_12.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SMSPrefetcher.sv \
              $(GOLDEN_RTL)/SMSTrainFilter.sv \
              $(GOLDEN_RTL)/ActiveGenerationTable.sv \
              $(GOLDEN_RTL)/StridePF.sv \
              $(GOLDEN_RTL)/PrefetchFilter.sv \
              $(GOLDEN_RTL)/RRArbiterInit_5.sv \
              $(GOLDEN_RTL)/RRArbiterInit_6.sv \
              $(GOLDEN_RTL)/PatternHistoryTable.sv \
              $(GOLDEN_RTL)/SRAMTemplate_145.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/OverrideableQueue.sv \
              $(GOLDEN_RTL)/OverrideableQueue_1.sv \
              $(GOLDEN_RTL)/Arbiter3_PfGenReq.sv \
              $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
              $(GOLDEN_RTL)/array_12.sv \
              $(GOLDEN_RTL)/array_12_ext.v
FM_VARIANTS = SMSPrefetcher
# golden 闭包逐个写字面文件名（fm_predict 的模型不展开 make 函数）
FM_REF_DEPS_SMSPrefetcher = SMSTrainFilter.sv \
                            ActiveGenerationTable.sv \
                            StridePF.sv \
                            PrefetchFilter.sv \
                            RRArbiterInit_5.sv \
                            RRArbiterInit_6.sv \
                            PatternHistoryTable.sv \
                            SRAMTemplate_145.sv \
                            MbistClockGateCell.sv \
                            ClockGate.sv \
                            OverrideableQueue.sv \
                            OverrideableQueue_1.sv \
                            Arbiter3_PfGenReq.sv \
                            sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
                            array_12.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
# 关 merge_dup 让 fm_predict 的模型严格适用（加强，不是放宽）
FM_MERGE_DUP = false
# vmucp：child 内两侧对称死位，依据见 verif/fm_target_config/SMSPrefetcher.tcl
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
