MODULE = TLPLIC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 依赖的已重写叶子 (PLICFanIn / LevelGateway) + pkg
RTL_SRCS = $(RTL_DIR)/uncore/plic_pkg.sv \
           $(RTL_DIR)/uncore/PLICFanIn.sv \
           $(RTL_DIR)/uncore/LevelGateway.sv \
           $(RTL_DIR)/uncore/TLPLIC.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden: TLPLIC 及其子模块
GOLDEN_SRCS = $(GOLDEN_RTL)/TLPLIC.sv \
              $(GOLDEN_RTL)/PLICFanIn.sv \
              $(GOLDEN_RTL)/LevelGateway.sv \
              $(GOLDEN_RTL)/Queue1_RegMapperInput.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TLPLIC_wrapper.sv
FM_VARIANTS = TLPLIC
# FM ref 侧 golden TLPLIC 的子模块依赖
FM_REF_DEPS_TLPLIC = PLICFanIn.sv LevelGateway.sv Queue1_RegMapperInput.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
