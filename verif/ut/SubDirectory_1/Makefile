MODULE = SubDirectory_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory_1.sv
TB_SRCS = tb.sv

# closure 对称 + 边界下推（2026-09-14，PARTIAL 收口簇）
# ------------------------------------------------------------------------
# 原状：FM_REF_DEPS 为空、无 RTL_GOLDEN_DEPS，于是 tagArray / metaArray /
# replacer_sram_opt 三个**设计级**黑盒两侧对称出现。它们是 SRAMTemplate_194/195/196
# —— 既不在 verif/vendor_boundary.tsv（不是厂商硬宏），也没有独立 UT 目标，
# declare_allow.py 因此拒绝出声明，assembly 永远卡在 no_allow_decl。
# 处置：把三棵子树的 golden 源**两侧同源 elaborate**（ref 走 FM_REF_DEPS_*，
# impl 走 RTL_GOLDEN_DEPS，同一份 G1-canonical 文件），边界下推到叶子
# array_21_ext / array_22_ext / array_0_0_ext —— 这三条已由 codex 0153 D67
# 逐条审定入 verif/vendor_boundary.tsv（APPROVED_MEMORY_MACRO_MODEL）。
# ★加强不是放宽★：SRAM wrapper 的地址/使能/掩码寄存与 shouldReset 复位机
# 全部进入比对，只剩存储阵列本身作对称黑盒。
# 三个 *_ext.v 两侧都不读，仍是 vendor_boundary.tsv 认定的 regimeA
# （两侧同为未解析黑盒），只进 GOLDEN_SRCS 供 VCS 行为仿真。
SUBDIR1_LEAVES = SRAMTemplate_194.sv SRAMTemplate_195.sv SRAMTemplate_196.sv \
                 array_21.sv array_22.sv array_0_0.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(SUBDIR1_LEAVES))
FM_REF_DEPS_SubDirectory_1 = $(SUBDIR1_LEAVES)
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_194.sv \
              $(GOLDEN_RTL)/SRAMTemplate_195.sv \
              $(GOLDEN_RTL)/SRAMTemplate_196.sv \
              $(GOLDEN_RTL)/array_21.sv \
              $(GOLDEN_RTL)/array_21_ext.v \
              $(GOLDEN_RTL)/array_22.sv \
              $(GOLDEN_RTL)/array_22_ext.v \
              $(GOLDEN_RTL)/array_0_0.sv \
              $(GOLDEN_RTL)/array_0_0_ext.v
# assembly：对称黑盒边界 = array_21_ext / array_22_ext / array_0_0_ext 各 1/侧，
# 逐对象声明见 verif/allow/SubDirectory_1.json。
# FM_ALLOWLIST 是 **unmatched compare points** 的数字粗筛，与黑盒条数无关；
# 本目标 unmatched 实测为 0，故收紧到 0（原值 3 是老战役继承的松口径）。
FM_MODE = assembly
FM_ALLOWLIST ?= 0
FM_VARIANTS = SubDirectory_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
