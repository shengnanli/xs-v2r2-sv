MODULE = Directory_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# AUX 变体: 复用已签核 xs_Directory_core (与基线 Directory 逐位相同的可读核),
# 仅顶层名/SRAM·MBIST 编号/MBIST bore 位宽随 golden Directory_1 变化。
RTL_SRCS = $(RTL_DIR)/uncore/directory_pkg.sv \
           $(RTL_DIR)/uncore/Directory.sv

# option-2 (reviewer 裁定): SRAM wrapper/control 逻辑全部两侧 elaborate 参与证明
# (SplittedSRAM/SRAMTemplate/sram_array/array_N), 仅最底 vendor 宏 array_N_ext 与
# mbistPl L2Directory_1 保留 assembly 黑盒边界(L2Directory_1=golden MBIST 分发逻辑非厂商宏,
# 未独立签→assembly_depends 缺口, 见 verif/signoff/assembly_depends.tsv)。
FM_SRAM_ELAB = SplittedSRAM_3.sv \
               SRAMTemplate_152.sv \
               SRAMTemplate_156.sv \
               SRAMTemplate_157.sv \
               SRAMTemplate_158.sv \
               sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
               sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
               sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
               sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
               array_14.sv \
               array_15.sv \
               array_16.sv \
               array_17.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/Directory_1_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(FM_SRAM_ELAB))

# golden 侧 UT 依赖: golden Directory_1 + 全 SRAM 链 + MBIST 流水
GOLDEN_SRCS = $(GOLDEN_RTL)/Directory_1.sv \
              $(GOLDEN_RTL)/SplittedSRAM_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_152.sv \
              $(GOLDEN_RTL)/SRAMTemplate_156.sv \
              $(GOLDEN_RTL)/SRAMTemplate_157.sv \
              $(GOLDEN_RTL)/SRAMTemplate_158.sv \
              $(GOLDEN_RTL)/sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
              $(GOLDEN_RTL)/sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
              $(GOLDEN_RTL)/sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
              $(GOLDEN_RTL)/array_14.sv $(GOLDEN_RTL)/array_14_ext.v \
              $(GOLDEN_RTL)/array_15.sv $(GOLDEN_RTL)/array_15_ext.v \
              $(GOLDEN_RTL)/array_16.sv $(GOLDEN_RTL)/array_16_ext.v \
              $(GOLDEN_RTL)/array_17.sv $(GOLDEN_RTL)/array_17_ext.v \
              $(GOLDEN_RTL)/L2Directory_1.sv

TB_SRCS = variants_xs.sv tb.sv

# FM (option-2): ref 侧 = golden Directory_1 + SRAM 链 elaborate (与 impl 侧 WRAPPER_SRCS 对称);
# array_N_ext (vendor 宏) 与 L2Directory_1 (未独立签 MBIST 分发, assembly_depends 缺口) 两侧不提供 → 黑盒。
FM_VARIANTS = Directory_1
FM_REF_DEPS_Directory_1 = $(FM_SRAM_ELAB)

FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
