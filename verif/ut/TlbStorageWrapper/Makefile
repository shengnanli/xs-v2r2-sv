MODULE = TlbStorageWrapper
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/tlbstoragewrapper_pkg.sv $(RTL_DIR)/memblock/TlbStorageWrapper.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/TlbStorageWrapper_wrapper.sv \
               $(RTL_DIR)/memblock/TlbStorageWrapper_1_wrapper.sv \
               $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TlbStorageWrapper.sv $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = TlbStorageWrapper TlbStorageWrapper_1
FM_REF_DEPS_TlbStorageWrapper = TLBFA.sv
FM_REF_DEPS_TlbStorageWrapper_1 = TLBFA_1.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# 变体 _1 的独立 UT（默认 compile/run 跑变体 0）
SEED ?= 1
compile1: simv1
simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/TlbStorageWrapper_1.sv $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv
	$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/TlbStorageWrapper_1_wrapper.sv $(GOLDEN_RTL)/TlbStorageWrapper_1.sv $(GOLDEN_RTL)/TLBFA.sv $(GOLDEN_RTL)/TLBFA_1.sv variants_xs.sv tb_1.sv -top tb -o simv1
run1: simv1
	./simv1 +ntb_random_seed=$(SEED) -l sim1.log
	@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (TlbStorageWrapper_1) ===" \
		|| { echo "=== UT FAILED (TlbStorageWrapper_1) ==="; exit 1; }
.PHONY: compile1 run1

