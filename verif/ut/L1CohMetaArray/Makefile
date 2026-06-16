MODULE = L1CohMetaArray
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l1metaarray_pkg.sv $(RTL_DIR)/memblock/L1CohMetaArray.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L1CohMetaArray_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L1CohMetaArray.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L1CohMetaArray
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

