MODULE = TLPLIC

RTL_DIR = ../../../rtl
# uncore_common_pkg.sv 里的 plic_pkg 由 PLICFanIn/TLPLIC 共用（每个子系统至多一个公共包文件，见
# CONVENTIONS.md）。必须排在使用者之前：package 要先于引用它的模块可见。
RTL_SRCS = $(RTL_DIR)/uncore/uncore_common_pkg.sv \
           $(RTL_DIR)/uncore/PLICFanIn.sv \
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
