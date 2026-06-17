MODULE = JumpUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包
RTL_SRCS = $(RTL_DIR)/backend/jumpunit_pkg.sv \
           $(RTL_DIR)/backend/JumpUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 叶子子模块(JumpDataModule 黑盒, 仅 golden 侧用)
GOLDEN_SRCS = $(GOLDEN_RTL)/JumpUnit.sv \
              $(GOLDEN_RTL)/JumpDataModule.sv

# FM: golden 顶层 JumpUnit(含 JumpDataModule 黑盒) vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/JumpUnit_wrapper.sv
FM_VARIANTS = JumpUnit
FM_REF_DEPS_JumpUnit = JumpDataModule.sv

include ../../../scripts/ut_common.mk
