MODULE = Directory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/directory_pkg.sv \
           $(RTL_DIR)/uncore/Directory.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/Directory_wrapper.sv

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

# FM: ref 仅给 golden Directory 本体, SRAM/mbist 两侧均黑盒
FM_VARIANTS = Directory
FM_REF_DEPS_Directory =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
