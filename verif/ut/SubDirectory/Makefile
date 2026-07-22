MODULE = SubDirectory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/subdirectory_pkg.sv \
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

# FM: 父级只证 SubDirectory glue；SRAM/LFSR 作为已独立证明的
# assembly child 边界，由 verif/signoff/assembly_depends.tsv 绑定依赖。
FM_VARIANTS = SubDirectory
FM_REF_DEPS_SubDirectory =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
