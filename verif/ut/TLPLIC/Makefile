MODULE = TLPLIC

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/PLICFanIn.sv \
           $(RTL_DIR)/uncore/LevelGateway.sv \
           $(RTL_DIR)/uncore/TLPLIC.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TLPLIC = PLICFanIn.sv LevelGateway.sv Queue1_RegMapperInput.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLPLIC.sv \
              $(GOLDEN_RTL)/PLICFanIn.sv \
              $(GOLDEN_RTL)/LevelGateway.sv \
              $(GOLDEN_RTL)/Queue1_RegMapperInput.sv
FM_VARIANTS = TLPLIC

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
