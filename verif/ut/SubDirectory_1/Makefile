MODULE = SubDirectory_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/subdirectory1_pkg.sv \
           $(RTL_DIR)/uncore/SubDirectory_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SubDirectory_1_wrapper.sv

# golden 侧 UT 依赖: golden SubDirectory_1 + 3 SRAM (含叶子阵列)
#   SRAMTemplate_199 -> array_21 (tag)
#   SRAMTemplate_200 -> array_22 (meta)
#   SRAMTemplate_201 -> array_0_0 (replacer)
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate_199.sv \
              $(GOLDEN_RTL)/SRAMTemplate_200.sv \
              $(GOLDEN_RTL)/SRAMTemplate_201.sv \
              $(GOLDEN_RTL)/array_21.sv $(GOLDEN_RTL)/array_21_ext.v \
              $(GOLDEN_RTL)/array_22.sv $(GOLDEN_RTL)/array_22_ext.v \
              $(GOLDEN_RTL)/array_0_0.sv $(GOLDEN_RTL)/array_0_0_ext.v

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SubDirectory_1 本体, SRAM 两侧均黑盒
FM_VARIANTS = SubDirectory_1
FM_REF_DEPS_SubDirectory_1 =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
