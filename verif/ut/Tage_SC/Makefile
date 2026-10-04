MODULE = Tage_SC

# TAGE-SC：BPU 主方向预测器（链 2/5）。重写件 rtl/frontend/Tage_SC.sv（package tage_sc_pkg + xs_Tage_SC_core +
# golden 同名 wrapper，wrapper 由 scripts/gen_bpu_wrappers.py 生成），例化共享辅助件 rtl/common/xs_BpuStagePc.sv。
#
# 子模块处置（docs/coverage_three_axis.tsv 第 3 列）—— 全部两侧白盒（ref = golden，impl = 已签重写件）：
#   TageTable / _1 / _2 / _3（PROVEN_DIRECT）、TageBTable（PROVEN_IN_CONE）、MbistPipeTage（PROVEN_DIRECT）、
#   SCTable / _1 / _2 / _3 与 MaxPeriodFibonacciLFSR（本 lane 已签）。
#   SCTable 的下一层沿用其签核处置：SRAMTemplate_68 / WrBypass_33 / MbistPipeSc* 用重写件（RTL_SRCS）。
#   TageTable / TageBTable 的下一层沿用它们签核时的处置：两侧共读 golden（RTL_GOLDEN_DEPS）；
#   唯一例外 WrBypass（TageTable 的写旁路）——它与 WrBypass_33 同住 rtl/frontend/WrBypass.sv（同一个核文件），
#   impl 侧只能有一份 WrBypass 定义，故 impl 用重写件（PROVEN_DIRECT），ref 用 golden。
#   厂商叶子 array_2/3/4/5_ext 两侧黑盒（verif/vendor_boundary.tsv）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_BpuStagePc.sv \
           $(RTL_DIR)/common/MaxPeriodFibonacciLFSR.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_68.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate.sv \
           $(RTL_DIR)/frontend/WrBypass.sv \
           $(RTL_DIR)/frontend/WrBypass_33.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeTage.sv \
           $(RTL_DIR)/dft/MbistPipeSc.sv \
           $(RTL_DIR)/dft/MbistPipeSc_1.sv \
           $(RTL_DIR)/dft/MbistPipeSc_2.sv \
           $(RTL_DIR)/dft/MbistPipeSc_3.sv \
           $(RTL_DIR)/frontend/sctable_pkg.sv \
           $(RTL_DIR)/frontend/SCTable.sv \
           $(RTL_DIR)/frontend/SCTable_1.sv \
           $(RTL_DIR)/frontend/SCTable_2.sv \
           $(RTL_DIR)/frontend/SCTable_3.sv \
           $(RTL_DIR)/frontend/TageTable.sv \
           $(RTL_DIR)/frontend/TageTable_1.sv \
           $(RTL_DIR)/frontend/TageTable_2.sv \
           $(RTL_DIR)/frontend/TageTable_3.sv \
           $(RTL_DIR)/frontend/TageBTable.sv \
           $(RTL_DIR)/frontend/Tage_SC.sv
TB_SRCS  = tb.sv

TAGE_GRAND = ClockGate.sv MbistClockGateCell.sv \
             FoldedSRAMTemplate.sv SplittedSRAMTemplate_3.sv SRAMTemplate_44.sv \
             sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv \
             FoldedSRAMTemplate_1.sv SplittedSRAMTemplate_4.sv SRAMTemplate_45.sv \
             sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv \
             FoldedSRAMTemplate_20.sv SplittedSRAMTemplate_23.sv SRAMTemplate_64.sv \
             sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv array_4.sv \
             WrBypass_32.sv IndexableCAMTemplate_32.sv data_mem_8x4.sv \
             sram_array_1p128x24m6s1h0l1b_bp_sc.sv array_5.sv
TAGE_EXT   = array_2_ext.v array_3_ext.v array_4_ext.v array_5_ext.v
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(TAGE_GRAND))

TAGE_CHILDREN = TageTable.sv TageTable_1.sv TageTable_2.sv TageTable_3.sv TageBTable.sv MbistPipeTage.sv \
                SCTable.sv SCTable_1.sv SCTable_2.sv SCTable_3.sv \
                MbistPipeSc.sv MbistPipeSc_1.sv MbistPipeSc_2.sv MbistPipeSc_3.sv \
                SRAMTemplate_68.sv WrBypass_33.sv IndexableCAMTemplate_33.sv data_mem_16x12.sv \
                WrBypass.sv IndexableCAMTemplate.sv data_mem_0_8x3.sv \
                MaxPeriodFibonacciLFSR.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Tage_SC.sv $(addprefix $(GOLDEN_RTL)/,$(TAGE_CHILDREN) $(TAGE_EXT))

FM_VARIANTS = Tage_SC
FM_REF_DEPS_Tage_SC = $(TAGE_CHILDREN) $(TAGE_GRAND)
FM_MERGE_DUP = false

# ★匹配前钉点 fm_pins_pre.tcl（scripts/gen_bpu_stagepc_pins.py 生成）★ + ★vmucp：依据见 verif/fm_target_config/Tage_SC.tcl★
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
# initreg 三档：0 / random / <seed>017。★后两档用 initreg 配置文件：其余状态照常随机，
# 只把厂商 SRAM 行为模型（array_2_ext / array_3_ext / array_4_ext / array_5_ext）的存储阵列初值钉 0★。原因：表项 SRAM 无复位，
# 两个实例（golden 侧 / 重写侧）各自读到"从没写过"的条目时随机初值不同 —— 那是 tb 违反
# "先写后读"的契约，不是 RTL 差异（seed 42 实测：不钉时开比第一拍 meta 目标位就不同）。
# 两侧读的是同一份 golden SRAM 模型，钉 0 不改变被比对的任何逻辑。
SRAM_LEAVES = array_2_ext array_3_ext array_4_ext array_5_ext
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
