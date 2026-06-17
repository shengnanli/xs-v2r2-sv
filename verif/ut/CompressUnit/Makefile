MODULE = CompressUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/compressunit_pkg.sv \
           $(RTL_DIR)/backend/CompressUnit.sv

TB_SRCS = variants_xs.sv cu_bridge.sv tb.sv

# golden 纯叶子,无子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/CompressUnit.sv

# FM:golden CompressUnit vs 手写同名 wrapper(→ 可读核)。
WRAPPER_SRCS = $(RTL_DIR)/backend/CompressUnit_wrapper.sv
FM_VARIANTS = CompressUnit

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
