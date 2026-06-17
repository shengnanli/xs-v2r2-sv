MODULE = UopInfoGen

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/uopinfogen_pkg.sv \
           $(RTL_DIR)/backend/UopInfoGen.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层例化两张 LS 真值表子模块,UT 双例化需全量。
LS_TABLES = strdiedLSNumOfUopTable.sv indexedLSNumOfUopTable.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/UopInfoGen.sv $(addprefix $(GOLDEN_RTL)/,$(LS_TABLES))

# FM:golden 顶层(含两张表)vs 手写同名 wrapper(→ 可读核,表已内联)。
WRAPPER_SRCS = $(RTL_DIR)/backend/UopInfoGen_wrapper.sv
FM_VARIANTS = UopInfoGen
FM_REF_DEPS_UopInfoGen = $(LS_TABLES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
