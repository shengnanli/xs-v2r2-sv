MODULE = Directory

# Directory / _1 / _2 / _3（L2 目录）与其 tag 阵列 SplittedSRAM_3 / _4 / _5 / _6。
# 子树两侧白盒（impl 读本仓重写件）：
#   xs_Directory_core（本 lane）；SplittedSRAM_3..6（本 lane，纯连线，scripts/gen_l2_splitted_sram.py）；
#   L2Directory（PROVEN_DIRECT，rtl/uncore/L2Directory.sv）、L2Directory_1..3（本 lane，verif/ut/L2DirectoryVariants）；
#   SRAMTemplate_148/150/152/153/154/159/162/163/164/165/181/185/186/187（全部 PROVEN_DIRECT，共用核 xs_SRAMTemplate_core）。
# 两侧同源 golden：sram_array_* 与 array_14..17（SRAM 宏包装层）。
# 唯一抽象边界：厂商 SRAM 宏叶子 array_14/15/16/17_ext（verif/vendor_boundary.tsv 审定的 vendor_sram_leaf），
# FM 不读 .v ⇒ 两侧对称未解析黑盒 → assembly 模式 + verif/allow/<T>.json 逐条声明。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/uncore_common_pkg.sv $(RTL_DIR)/uncore/xs_Directory_core.sv \
           $(RTL_DIR)/uncore/Directory.sv $(RTL_DIR)/uncore/Directory_1.sv \
           $(RTL_DIR)/uncore/Directory_2.sv $(RTL_DIR)/uncore/Directory_3.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_3.sv $(RTL_DIR)/uncore/SplittedSRAM_4.sv \
           $(RTL_DIR)/uncore/SplittedSRAM_5.sv $(RTL_DIR)/uncore/SplittedSRAM_6.sv \
           $(RTL_DIR)/uncore/L2Directory.sv \
           $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
           $(RTL_DIR)/dft/L2Directory_1.sv $(RTL_DIR)/dft/L2Directory_2.sv $(RTL_DIR)/dft/L2Directory_3.sv \
           $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate_148.sv $(RTL_DIR)/common/SRAMTemplate_150.sv \
           $(RTL_DIR)/common/SRAMTemplate_152.sv $(RTL_DIR)/common/SRAMTemplate_153.sv \
           $(RTL_DIR)/common/SRAMTemplate_154.sv $(RTL_DIR)/common/SRAMTemplate_159.sv \
           $(RTL_DIR)/common/SRAMTemplate_162.sv $(RTL_DIR)/common/SRAMTemplate_163.sv \
           $(RTL_DIR)/common/SRAMTemplate_164.sv $(RTL_DIR)/common/SRAMTemplate_165.sv \
           $(RTL_DIR)/common/SRAMTemplate_181.sv $(RTL_DIR)/common/SRAMTemplate_185.sv \
           $(RTL_DIR)/common/SRAMTemplate_186.sv $(RTL_DIR)/common/SRAMTemplate_187.sv
SRAM_MACROS = sram_array_1p512x76m19s1h0l1b_l2_tag.sv sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
              sram_array_1p512x16m16s1h0l1b_l2_repl.sv sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
              array_14.sv array_15.sv array_16.sv array_17.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SRAM_MACROS))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Directory.sv $(GOLDEN_RTL)/Directory_1.sv \
              $(GOLDEN_RTL)/Directory_2.sv $(GOLDEN_RTL)/Directory_3.sv \
              $(GOLDEN_RTL)/SplittedSRAM_3.sv $(GOLDEN_RTL)/SplittedSRAM_4.sv \
              $(GOLDEN_RTL)/SplittedSRAM_5.sv $(GOLDEN_RTL)/SplittedSRAM_6.sv \
              $(GOLDEN_RTL)/L2Directory.sv $(GOLDEN_RTL)/L2Directory_1.sv \
              $(GOLDEN_RTL)/L2Directory_2.sv $(GOLDEN_RTL)/L2Directory_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_148.sv $(GOLDEN_RTL)/SRAMTemplate_150.sv \
              $(GOLDEN_RTL)/SRAMTemplate_152.sv $(GOLDEN_RTL)/SRAMTemplate_153.sv \
              $(GOLDEN_RTL)/SRAMTemplate_154.sv $(GOLDEN_RTL)/SRAMTemplate_159.sv \
              $(GOLDEN_RTL)/SRAMTemplate_162.sv $(GOLDEN_RTL)/SRAMTemplate_163.sv \
              $(GOLDEN_RTL)/SRAMTemplate_164.sv $(GOLDEN_RTL)/SRAMTemplate_165.sv \
              $(GOLDEN_RTL)/SRAMTemplate_181.sv $(GOLDEN_RTL)/SRAMTemplate_185.sv \
              $(GOLDEN_RTL)/SRAMTemplate_186.sv $(GOLDEN_RTL)/SRAMTemplate_187.sv \
              $(addprefix $(GOLDEN_RTL)/,$(SRAM_MACROS)) \
              $(GOLDEN_RTL)/array_14_ext.v $(GOLDEN_RTL)/array_15_ext.v \
              $(GOLDEN_RTL)/array_16_ext.v $(GOLDEN_RTL)/array_17_ext.v

FM_REF_DEPS_SplittedSRAM_3 = SRAMTemplate_148.sv SRAMTemplate_150.sv $(SRAM_MACROS)
FM_REF_DEPS_SplittedSRAM_4 = SRAMTemplate_159.sv SRAMTemplate_162.sv $(SRAM_MACROS)
FM_REF_DEPS_SplittedSRAM_5 = SRAMTemplate_162.sv $(SRAM_MACROS)
FM_REF_DEPS_SplittedSRAM_6 = SRAMTemplate_181.sv $(SRAM_MACROS)
FM_REF_DEPS_Directory   = SplittedSRAM_3.sv L2Directory.sv SRAMTemplate_152.sv SRAMTemplate_153.sv SRAMTemplate_154.sv $(FM_REF_DEPS_SplittedSRAM_3)
FM_REF_DEPS_Directory_1 = SplittedSRAM_4.sv L2Directory_1.sv SRAMTemplate_163.sv SRAMTemplate_164.sv SRAMTemplate_165.sv $(FM_REF_DEPS_SplittedSRAM_4)
FM_REF_DEPS_Directory_2 = SplittedSRAM_5.sv L2Directory_2.sv SRAMTemplate_163.sv SRAMTemplate_164.sv SRAMTemplate_165.sv $(FM_REF_DEPS_SplittedSRAM_5)
FM_REF_DEPS_Directory_3 = SplittedSRAM_6.sv L2Directory_3.sv SRAMTemplate_185.sv SRAMTemplate_186.sv SRAMTemplate_187.sv $(FM_REF_DEPS_SplittedSRAM_6)
FM_VARIANTS = SplittedSRAM_3 SplittedSRAM_4 SplittedSRAM_5 SplittedSRAM_6 \
              Directory Directory_1 Directory_2 Directory_3
# FM_MERGE_DUP 取默认（true），与 SRAMTemplate 两个 UT 目录一致：共用核 xs_SRAMTemplate_core 的非 MCP 形态
# 有一个 golden 没有的 rdata_last_REG（holdRead 关时与 respReg 同方程，靠 merge 合并），关掉 merge 它就成了
# 重写侧独有的未读寄存器（第一跑 evidence/2690db305435 实测：每块 SRAM 1 个，Directory 7 个 / SplittedSRAM 4 个）。
# 代价：fm_predict 的 passing 模型只在 merge 关时严格成立，本目录第二跑起 passing 不再与模型逐位对账（MODEL_NA）。

# assembly：唯一黑盒 = array_14..17_ext（verif/allow/<T>.json 逐条声明，class vendor_macro）
FM_MODE = assembly
FM_ALLOWLIST ?= 14

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# vmucp 只对 Directory*（各 27 个对称死位，依据见 verif/fm_target_config/Directory*.tcl）；SplittedSRAM_* 不开。
fm-Directory fm-Directory_1 fm-Directory_2 fm-Directory_3: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
