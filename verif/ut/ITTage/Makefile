MODULE = ITTage

# ITTAGE：间接跳转目标预测器（BPU 链 4/5）。
# 重写件 rtl/frontend/ITTage.sv（package ittage_pkg + xs_ITTage_core + golden 同名 wrapper，wrapper 由
# scripts/gen_bpu_wrappers.py 生成），例化共享辅助件 rtl/common/xs_BpuStagePc.sv。
#
# 子模块处置（docs/coverage_three_axis.tsv 第 3 列）：
#   ITTageTable / _1.._4（PROVEN_IN_CONE，本仓已签重写件）、RegionWays / MaxPeriodFibonacciLFSR（本 lane 已签）
#   ⇒ **两侧白盒**：ref = golden 同名件，impl = 重写件（下面 RTL_SRCS）。
#   ITTageTable 的下一层（FoldedSRAMTemplate_22/24、SplittedSRAMTemplate_25/27、SRAMTemplate_76/78、WrBypass_41/43、
#   IndexableCAMTemplate_41/43、data_mem_0_4x2、SRAM 宏链）沿用 ITTageTable 自己签核时的处置：两侧共读 golden 同一份
#   （RTL_GOLDEN_DEPS）。厂商叶子 array_6_ext 按 verif/vendor_boundary.tsv 两侧黑盒：.v 只给 VCS（GOLDEN_SRCS），
#   不进 FM 任一侧（ITTageTable 自己的 Makefile 曾把它读进 FM 两侧当白盒，本目标改回审定的厂商边界）。MbistPipeIttage* 在重写 ITTageTable 里由 xs_MbistPipeIttage_core
#   实现（ref 侧为 golden MbistPipeIttage*）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_BpuStagePc.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/common/MaxPeriodFibonacciLFSR.sv \
           $(RTL_DIR)/frontend/RegionWays.sv \
           $(RTL_DIR)/frontend/ITTageTable.sv \
           $(RTL_DIR)/frontend/ITTageTable_1.sv \
           $(RTL_DIR)/frontend/ITTageTable_2.sv \
           $(RTL_DIR)/frontend/ITTageTable_3.sv \
           $(RTL_DIR)/frontend/ITTageTable_4.sv \
           $(RTL_DIR)/frontend/ITTage.sv
TB_SRCS  = tb.sv

IT_GRAND = ClockGate.sv MbistClockGateCell.sv \
           FoldedSRAMTemplate_22.sv FoldedSRAMTemplate_24.sv \
           SplittedSRAMTemplate_25.sv SplittedSRAMTemplate_27.sv \
           SRAMTemplate_76.sv SRAMTemplate_78.sv \
           WrBypass_41.sv WrBypass_43.sv IndexableCAMTemplate_41.sv IndexableCAMTemplate_43.sv \
           data_mem_0_4x2.sv array_6.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(filter-out ClockGate.sv,$(IT_GRAND))) $(XSSV_HOME)/rtl/common/ClockGate.sv

IT_CHILDREN = ITTageTable.sv ITTageTable_1.sv ITTageTable_2.sv ITTageTable_3.sv ITTageTable_4.sv \
              MbistPipeIttage.sv MbistPipeIttage_1.sv MbistPipeIttage_2.sv MbistPipeIttage_3.sv MbistPipeIttage_4.sv \
              RegionWays.sv MaxPeriodFibonacciLFSR.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTage.sv $(addprefix $(GOLDEN_RTL)/,$(IT_CHILDREN)) $(GOLDEN_RTL)/array_6_ext.v

FM_VARIANTS = ITTage
FM_REF_DEPS_ITTage = $(IT_CHILDREN) $(IT_GRAND)
FM_MERGE_DUP = false

# ★匹配前钉点 fm_pins_pre.tcl（scripts/gen_bpu_stagepc_pins.py 生成，本层全部寄存器逐位）★：不钉时 Matching 30 分钟未结束。
# ★vmucp：依据见 verif/fm_target_config/ITTage.tcl★
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
# initreg 三档：0 / random / <seed>017。★后两档用 initreg 配置文件：其余状态照常随机，
# 只把厂商 SRAM 行为模型（array_6_ext）的存储阵列初值钉 0★。原因：表项 SRAM 无复位，
# 两个实例（golden 侧 / 重写侧）各自读到"从没写过"的条目时随机初值不同 —— 那是 tb 违反
# "先写后读"的契约，不是 RTL 差异（seed 42 实测：不钉时开比第一拍 meta 目标位就不同）。
# 两侧读的是同一份 golden SRAM 模型，钉 0 不改变被比对的任何逻辑。
SRAM_LEAVES = array_6_ext
ifeq ($(INITREG),0)
SIM_ARGS += +vcs+initreg+0
else
SIM_ARGS += +vcs+initreg+config+$(UT_GEN_DIR)/initreg_$(INITREG).cfg
endif
$(UT_GEN_DIR)/initreg_%.cfg: Makefile
	@mkdir -p $(UT_GEN_DIR)
	@{ if [ "$*" = random ]; then echo "defaultvalue random"; else echo "defaultvalue random $*"; fi; \
	   for m in $(SRAM_LEAVES); do echo "module $$m 0"; done; } > $@
run: $(if $(filter-out 0,$(INITREG)),$(UT_GEN_DIR)/initreg_$(INITREG).cfg)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_bpu_wrappers.py --check
	python3 gen.py --check
