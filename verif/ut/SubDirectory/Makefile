MODULE = SubDirectory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/subdirectory_pkg.sv \
           $(RTL_DIR)/common/xs_Simple1PSRAM_core.sv \
           $(RTL_DIR)/uncore/SRAMTemplate_197.sv \
           $(RTL_DIR)/uncore/SRAMTemplate_198.sv \
           $(RTL_DIR)/uncore/MaxPeriodFibonacciLFSR_3.sv \
           $(RTL_DIR)/uncore/SubDirectory.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SubDirectory_wrapper.sv

# golden 侧 UT 依赖: golden SubDirectory + 2 SRAM + LFSR (含 SRAM 叶子阵列)
#   SRAMTemplate_197 -> array_19 -> array_19_ext (tag)
#   SRAMTemplate_198 -> array_20 -> array_20_ext (meta)
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/SRAMTemplate_197.sv \
              $(GOLDEN_RTL)/SRAMTemplate_198.sv \
              $(GOLDEN_RTL)/array_19.sv $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20.sv $(GOLDEN_RTL)/array_20_ext.v \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv

TB_SRCS = variants_xs.sv tb.sv

# FM: 两侧都展开 SRAM/LFSR 真实 RTL，不以子模块黑盒隐藏差异。
FM_VARIANTS = SubDirectory
FM_REF_DEPS_SubDirectory = SRAMTemplate_197.sv SRAMTemplate_198.sv \
                           array_19.sv array_19_ext.v \
                           array_20.sv array_20_ext.v \
                           MaxPeriodFibonacciLFSR_3.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
