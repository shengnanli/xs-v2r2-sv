MODULE = L1FlagMetaArray
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l1metaarray_pkg.sv $(RTL_DIR)/memblock/L1FlagMetaArray.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L1FlagMetaArray_wrapper.sv $(RTL_DIR)/memblock/L1FlagMetaArray_1_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L1FlagMetaArray.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L1FlagMetaArray L1FlagMetaArray_1
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# 变体 L1FlagMetaArray_1 的独立 UT（默认 compile/run 跑 L1FlagMetaArray）
SEED ?= 1
compile1: simv1
simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/L1FlagMetaArray_1.sv
	$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/L1FlagMetaArray_1_wrapper.sv $(GOLDEN_RTL)/L1FlagMetaArray_1.sv variants_xs.sv tb_1.sv -top tb -o simv1
run1: simv1
	./simv1 +ntb_random_seed=$(SEED) -l sim1.log
	@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (L1FlagMetaArray_1) ===" \
		|| { echo "=== UT FAILED (L1FlagMetaArray_1) ==="; exit 1; }
.PHONY: compile1 run1

