MODULE = PatternHistoryTable

# PatternHistoryTable：SMS 预取器的模式历史表（手写核 xs_PatternHistoryTable_core + 生成的 golden 同名 wrapper）。
# child 全部已签核，两侧白盒：ref 读 golden，impl 读本仓重写件：
#   SRAMTemplate_145（xs_SRAMTemplate_core；其内 MbistClockGateCell 用本仓重写件 rtl/common/MbistClockGateCell.sv，
#   ClockGate 用本地共享基元 rtl/common/ClockGate.sv）、OverrideableQueue / _1（xs_OverrideableQueue_core）、
#   Arbiter3_PfGenReq（xs_FixedPriorityArbiter_core）。
# 厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht / array_12：两侧同读 golden；叶子 array_12_ext 不进 FM
# （两侧对称黑盒，verif/allow/PatternHistoryTable.json 声明 vendor_macro）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/PatternHistoryTable.sv \
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

GOLDEN_SRCS = $(GOLDEN_RTL)/PatternHistoryTable.sv \
              $(GOLDEN_RTL)/SRAMTemplate_145.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/OverrideableQueue.sv \
              $(GOLDEN_RTL)/OverrideableQueue_1.sv \
              $(GOLDEN_RTL)/Arbiter3_PfGenReq.sv \
              $(GOLDEN_RTL)/sram_array_1p32x148m74s1h0l1b_pftch_pht.sv \
              $(GOLDEN_RTL)/array_12.sv \
              $(GOLDEN_RTL)/array_12_ext.v
FM_VARIANTS = PatternHistoryTable
FM_REF_DEPS_PatternHistoryTable = SRAMTemplate_145.sv MbistClockGateCell.sv ClockGate.sv \
                                  OverrideableQueue.sv OverrideableQueue_1.sv Arbiter3_PfGenReq.sv \
                                  sram_array_1p32x148m74s1h0l1b_pftch_pht.sv array_12.sv
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
