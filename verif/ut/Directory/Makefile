MODULE = Directory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/directory_pkg.sv \
           $(RTL_DIR)/uncore/Directory.sv

# option-2 (reviewer 裁定): SRAM wrapper/control 逻辑全部两侧 elaborate 参与证明
# (SplittedSRAM/SRAMTemplate/sram_array/array_N), 仅最底 vendor 宏 array_N_ext 与
# 独立绿目标 L2Directory 保留 assembly 黑盒边界。
FM_SRAM_ELAB = SplittedSRAM_2.sv \
               SRAMTemplate_137.sv SRAMTemplate_139.sv SRAMTemplate_141.sv \
               SRAMTemplate_142.sv SRAMTemplate_143.sv \
               sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
               sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
               sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
               sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
               array_14.sv array_15.sv array_16.sv array_17.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/Directory_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(FM_SRAM_ELAB))

# golden 侧 UT 依赖: golden Directory + 全 SRAM 链 + MBIST 流水
GOLDEN_SRCS = $(GOLDEN_RTL)/Directory.sv \
              $(GOLDEN_RTL)/SplittedSRAM_2.sv \
              $(GOLDEN_RTL)/SRAMTemplate_137.sv $(GOLDEN_RTL)/SRAMTemplate_139.sv \
              $(GOLDEN_RTL)/SRAMTemplate_141.sv $(GOLDEN_RTL)/SRAMTemplate_142.sv \
              $(GOLDEN_RTL)/SRAMTemplate_143.sv \
              $(GOLDEN_RTL)/sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p512x104m13s1h0l1b_l2_meta.sv \
              $(GOLDEN_RTL)/sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
              $(GOLDEN_RTL)/sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
              $(GOLDEN_RTL)/array_14.sv $(GOLDEN_RTL)/array_14_ext.v \
              $(GOLDEN_RTL)/array_15.sv $(GOLDEN_RTL)/array_15_ext.v \
              $(GOLDEN_RTL)/array_16.sv $(GOLDEN_RTL)/array_16_ext.v \
              $(GOLDEN_RTL)/array_17.sv $(GOLDEN_RTL)/array_17_ext.v \
              $(GOLDEN_RTL)/L2Directory.sv

TB_SRCS = variants_xs.sv tb.sv

# FM (option-2): ref 侧 = golden Directory + SRAM 链 elaborate (与 impl 侧 WRAPPER_SRCS 对称);
# array_N_ext (vendor 宏) 与 L2Directory (独立绿目标) 两侧不提供 → 黑盒。
FM_VARIANTS = Directory
FM_REF_DEPS_Directory = $(FM_SRAM_ELAB)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
