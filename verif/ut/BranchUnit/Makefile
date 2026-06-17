MODULE = BranchUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包
RTL_SRCS = $(RTL_DIR)/backend/branchunit_pkg.sv \
           $(RTL_DIR)/backend/BranchUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 叶子子模块(BranchModule/AddrAddModule/SubModule 黑盒, 仅 golden 侧用)
GOLDEN_SRCS = $(GOLDEN_RTL)/BranchUnit.sv \
              $(GOLDEN_RTL)/BranchModule.sv \
              $(GOLDEN_RTL)/AddrAddModule.sv \
              $(GOLDEN_RTL)/SubModule.sv

# FM: golden 顶层 BranchUnit(含三个黑盒子模块) vs 手写同名 wrapper(→ 可读核, 纯组合)。
WRAPPER_SRCS = $(RTL_DIR)/backend/BranchUnit_wrapper.sv
FM_VARIANTS = BranchUnit
FM_REF_DEPS_BranchUnit = BranchModule.sv AddrAddModule.sv SubModule.sv

include ../../../scripts/ut_common.mk
