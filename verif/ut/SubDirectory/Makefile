MODULE = SubDirectory

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory.sv
TB_SRCS = tb.sv

FM_REF_DEPS_SubDirectory = 
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory.sv \
              $(GOLDEN_RTL)/SRAMTemplate_192.sv \
              $(GOLDEN_RTL)/SRAMTemplate_193.sv \
              $(GOLDEN_RTL)/array_19.sv \
              $(GOLDEN_RTL)/array_19_ext.v \
              $(GOLDEN_RTL)/array_20.sv \
              $(GOLDEN_RTL)/array_20_ext.v \
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = lfsr_prng, metaArray, tagArray
FM_MODE = assembly
FM_ALLOWLIST ?= 3
FM_VARIANTS = SubDirectory

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
