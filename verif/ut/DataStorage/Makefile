MODULE = DataStorage

# DataStorage / _1 / _2 / _3（L2 slice 数据阵列前端）与其结构子模块 GatedSplittedSRAM / _1 / _2 / _3。
# 子树（两侧白盒，impl 读本仓重写件）：
#   xs_DataStorage_core（本 lane）；GatedSplittedSRAM*（本 lane，纯连线，scripts/gen_l2_gated_sram.py）；
#   MbistClockGateCell_93 + ClockMux（本 lane，verif/ut/ClockGateCell93）；
#   L2DataStorage*（本 lane，verif/ut/L2DataStorage）；SRAMTemplate_155/166/178（PROVEN_DIRECT，
#   verif/ut/SRAMTemplateNewForm，共用核 xs_SRAMTemplate_core）。
# 两侧同源 golden：ClockGate（锁存器门控单元模型）、sram_array_1p4096x137m137s1h1l2b_l2_dat、array_18。
# 唯一抽象边界：厂商 SRAM 宏叶子 array_18_ext（verif/vendor_boundary.tsv 审定的 vendor_sram_leaf，
# FM 不读 .v ⇒ 两侧对称未解析黑盒，每个目标 4 个/侧）→ assembly 模式 + verif/allow/<T>.json 逐条声明。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/xs_DataStorage_core.sv \
           $(RTL_DIR)/uncore/DataStorage.sv $(RTL_DIR)/uncore/DataStorage_1.sv \
           $(RTL_DIR)/uncore/DataStorage_2.sv $(RTL_DIR)/uncore/DataStorage_3.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM.sv $(RTL_DIR)/uncore/GatedSplittedSRAM_1.sv \
           $(RTL_DIR)/uncore/GatedSplittedSRAM_2.sv $(RTL_DIR)/uncore/GatedSplittedSRAM_3.sv \
           $(RTL_DIR)/common/MbistClockGateCell_93.sv $(RTL_DIR)/common/ClockMux.sv \
           $(RTL_DIR)/dft/xs_mbist_hold_leaf_core.sv \
           $(RTL_DIR)/dft/L2DataStorage.sv $(RTL_DIR)/dft/L2DataStorage_1.sv \
           $(RTL_DIR)/dft/L2DataStorage_2.sv $(RTL_DIR)/dft/L2DataStorage_3.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_155.sv $(RTL_DIR)/common/SRAMTemplate_166.sv \
           $(RTL_DIR)/common/SRAMTemplate_178.sv
RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
                  $(GOLDEN_RTL)/array_18.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DataStorage.sv $(GOLDEN_RTL)/DataStorage_1.sv \
              $(GOLDEN_RTL)/DataStorage_2.sv $(GOLDEN_RTL)/DataStorage_3.sv \
              $(GOLDEN_RTL)/GatedSplittedSRAM.sv $(GOLDEN_RTL)/GatedSplittedSRAM_1.sv \
              $(GOLDEN_RTL)/GatedSplittedSRAM_2.sv $(GOLDEN_RTL)/GatedSplittedSRAM_3.sv \
              $(GOLDEN_RTL)/MbistClockGateCell_93.sv $(GOLDEN_RTL)/ClockMux.sv \
              $(GOLDEN_RTL)/L2DataStorage.sv $(GOLDEN_RTL)/L2DataStorage_1.sv \
              $(GOLDEN_RTL)/L2DataStorage_2.sv $(GOLDEN_RTL)/L2DataStorage_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_155.sv $(GOLDEN_RTL)/SRAMTemplate_166.sv \
              $(GOLDEN_RTL)/SRAMTemplate_178.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/sram_array_1p4096x137m137s1h1l2b_l2_dat.sv \
              $(GOLDEN_RTL)/array_18.sv $(GOLDEN_RTL)/array_18_ext.v

DS_COMMON = MbistClockGateCell_93.sv ClockMux.sv ClockGate.sv sram_array_1p4096x137m137s1h1l2b_l2_dat.sv array_18.sv
FM_REF_DEPS_GatedSplittedSRAM   = SRAMTemplate_155.sv $(DS_COMMON)
FM_REF_DEPS_GatedSplittedSRAM_1 = SRAMTemplate_166.sv $(DS_COMMON)
FM_REF_DEPS_GatedSplittedSRAM_2 = SRAMTemplate_166.sv SRAMTemplate_178.sv $(DS_COMMON)
FM_REF_DEPS_GatedSplittedSRAM_3 = SRAMTemplate_178.sv $(DS_COMMON)
FM_REF_DEPS_DataStorage   = GatedSplittedSRAM.sv L2DataStorage.sv $(FM_REF_DEPS_GatedSplittedSRAM)
FM_REF_DEPS_DataStorage_1 = GatedSplittedSRAM_1.sv L2DataStorage_1.sv $(FM_REF_DEPS_GatedSplittedSRAM_1)
FM_REF_DEPS_DataStorage_2 = GatedSplittedSRAM_2.sv L2DataStorage_2.sv $(FM_REF_DEPS_GatedSplittedSRAM_2)
FM_REF_DEPS_DataStorage_3 = GatedSplittedSRAM_3.sv L2DataStorage_3.sv $(FM_REF_DEPS_GatedSplittedSRAM_3)
FM_VARIANTS = GatedSplittedSRAM GatedSplittedSRAM_1 GatedSplittedSRAM_2 GatedSplittedSRAM_3 \
              DataStorage DataStorage_1 DataStorage_2 DataStorage_3
FM_MERGE_DUP = false

# assembly：唯一黑盒 = array_18_ext x4/侧（verif/allow/<T>.json 逐条声明，class vendor_macro）
FM_MODE = assembly
FM_ALLOWLIST ?= 8

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# vmucp 只对 DataStorage*（各 544 个对称死位，依据见 verif/fm_target_config/DataStorage*.tcl）；
# GatedSplittedSRAM* 没有未读点，不开（按目标设，不影响同目录其它变体）。
fm-DataStorage fm-DataStorage_1 fm-DataStorage_2 fm-DataStorage_3: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
