# FTB（BPU 的 S2/S3 块级预测器）UT / FM。
# 重写件 rtl/frontend/FTB.sv（核 xs_FTB_core + golden 同名 wrapper，wrapper 由 scripts/gen_ftb.py 生成）。
# 子模块全部两侧白盒：ref 读 golden，impl 读本仓已签核重写件
#   FTBBank           rtl/frontend/FTBBank.sv（+ frontend_common_pkg.sv 的 xs_ftb_pkg）
#   DelayNWithValid / DelayNWithValid_1 / DelayN_1   rtl/common/（+ 各自的核）
# FTBBank 之下的 SRAM/MBIST 链照 FTBBank 自己签核时的口径两侧同读 golden（RTL_GOLDEN_DEPS），
# 只有厂商 SRAM 叶子 array_1_ext 不给 FM（verif/vendor_boundary.tsv 审定的 vendor_sram_leaf，两侧对称黑盒）。
MODULE = FTB

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/frontend/FTBBank.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_1.sv \
           $(RTL_DIR)/common/xs_DelayNWithValid_core.sv \
           $(RTL_DIR)/common/DelayNWithValid.sv \
           $(RTL_DIR)/common/DelayNWithValid_1.sv \
           $(RTL_DIR)/frontend/FTB.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/MbistPipeFtb.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_36.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv \
                  $(GOLDEN_RTL)/array_1.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv

FM_REF_DEPS_FTB = FTBBank.sv DelayN_1.sv DelayNWithValid.sv DelayNWithValid_1.sv \
                  MbistPipeFtb.sv SplittedSRAMTemplate_2.sv SRAMTemplate_36.sv \
                  sram_array_1p512x40m10s1h0l1b_bp_ftb.sv array_1.sv \
                  MbistClockGateCell.sv ClockGate.sv

# UT：golden 侧整棵子树（含厂商 SRAM 行为模型 array_1_ext.v）；重写侧用 ut_gen 派生的 _xs 副本
GOLDEN_SRCS = $(GOLDEN_RTL)/FTB.sv \
              $(GOLDEN_RTL)/FTBBank.sv \
              $(GOLDEN_RTL)/DelayN_1.sv \
              $(GOLDEN_RTL)/DelayNWithValid.sv \
              $(GOLDEN_RTL)/DelayNWithValid_1.sv \
              $(GOLDEN_RTL)/array_1_ext.v \
              $(RTL_GOLDEN_DEPS)

FM_MERGE_DUP = false
FM_VARIANTS = FTB

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言/xs_assert_v2；UT 定义 SYNTHESIS 关掉。
# initreg：编译期打开机制，运行期 INITREG 选 0 / random / <种子>。
INITREG ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_ftb.py --check
