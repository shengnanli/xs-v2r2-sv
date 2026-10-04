MODULE = SCTable

# SCTable 家族（SC 统计校正器的 4 张计数器表，历史长度 0/4/10/16）。
# 核：rtl/frontend/SCTable.sv（xs_SCTable_core + SCTable wrapper），包 rtl/frontend/sctable_pkg.sv；
# 薄 wrapper：SCTable_1/_2/_3.sv（scripts/gen_sctable.py 生成）。
#
# 子模块处置（docs/coverage_three_axis.tsv 第 3 列）：SRAMTemplate_68 / WrBypass_33 / MbistPipeSc{,_1,_2,_3}
# 全部 PROVEN_DIRECT ⇒ **两侧白盒**：ref = golden 同名件，impl = 本仓重写件（下面 RTL_SRCS 里的 child 段）。
# SRAM 宏链 sram_array_1p128x24m6s1h0l1b_bp_sc -> array_5 以及 MbistClockGateCell / ClockGate 两侧共读 golden 同一份
# （RTL_GOLDEN_DEPS）；array_5_ext.v 是厂商行为级叶子（verif/vendor_boundary.tsv），只给 VCS，FM 两侧黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/sctable_pkg.sv \
           $(RTL_DIR)/frontend/SCTable.sv \
           $(RTL_DIR)/frontend/SCTable_1.sv \
           $(RTL_DIR)/frontend/SCTable_2.sv \
           $(RTL_DIR)/frontend/SCTable_3.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_68.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/common/IndexableCAMTemplate.sv \
           $(RTL_DIR)/frontend/WrBypass.sv \
           $(RTL_DIR)/frontend/WrBypass_33.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/MbistPipeSc.sv \
           $(RTL_DIR)/dft/MbistPipeSc_1.sv \
           $(RTL_DIR)/dft/MbistPipeSc_2.sv \
           $(RTL_DIR)/dft/MbistPipeSc_3.sv
TB_SRCS  = tb.sv

RTL_GOLDEN_DEPS = $(XSSV_HOME)/rtl/common/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
                  $(GOLDEN_RTL)/array_5.sv

SC_CHILDREN = SRAMTemplate_68.sv WrBypass_33.sv IndexableCAMTemplate_33.sv data_mem_16x12.sv
SC_SRAM     = sram_array_1p128x24m6s1h0l1b_bp_sc.sv array_5.sv MbistClockGateCell.sv ClockGate.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SCTable.sv $(GOLDEN_RTL)/SCTable_1.sv $(GOLDEN_RTL)/SCTable_2.sv $(GOLDEN_RTL)/SCTable_3.sv \
              $(addprefix $(GOLDEN_RTL)/,$(SC_CHILDREN)) \
              $(GOLDEN_RTL)/MbistPipeSc.sv $(GOLDEN_RTL)/MbistPipeSc_1.sv \
              $(GOLDEN_RTL)/MbistPipeSc_2.sv $(GOLDEN_RTL)/MbistPipeSc_3.sv \
              $(GOLDEN_RTL)/array_5_ext.v

FM_VARIANTS = SCTable SCTable_1 SCTable_2 SCTable_3
FM_REF_DEPS_SCTable   = $(SC_CHILDREN) $(SC_SRAM) MbistPipeSc.sv
FM_REF_DEPS_SCTable_1 = $(SC_CHILDREN) $(SC_SRAM) MbistPipeSc_1.sv
FM_REF_DEPS_SCTable_2 = $(SC_CHILDREN) $(SC_SRAM) MbistPipeSc_2.sv
FM_REF_DEPS_SCTable_3 = $(SC_CHILDREN) $(SC_SRAM) MbistPipeSc_3.sv

FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/SCTable*.tcl★ —— 65 位两侧对称死位（s1_pc 未读位 / s1_idx[7:1] / MBIST 流水地址寄存器），FM 按名配上。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_sctable.py --check
	python3 gen.py --check
