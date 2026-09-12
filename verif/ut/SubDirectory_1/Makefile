MODULE = SubDirectory_1

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SubDirectory_1.sv
TB_SRCS = tb.sv

FM_REF_DEPS_SubDirectory_1 = 
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
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = metaArray, replacer_sram_opt, tagArray
FM_MODE = assembly
FM_ALLOWLIST ?= 3
FM_VARIANTS = SubDirectory_1

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
