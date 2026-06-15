MODULE = TLBFA
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/tlbfa_pkg.sv $(RTL_DIR)/memblock/TLBFA.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBFA_wrapper.sv $(RTL_DIR)/memblock/TLBFA_1_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBFA.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = TLBFA TLBFA_1
# 纯叶子逻辑，关合并以免跨条目常量误并影响签名比对
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# 变体 TLBFA_1 的独立 UT（默认 compile/run 跑 TLBFA）
SEED ?= 1
compile1: simv1
simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/TLBFA_1.sv
	$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/TLBFA_1_wrapper.sv $(GOLDEN_RTL)/TLBFA_1.sv variants_xs.sv tb_1.sv -top tb -o simv1
run1: simv1
	./simv1 +ntb_random_seed=$(SEED) -l sim1.log
	@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (TLBFA_1) ===" \
		|| { echo "=== UT FAILED (TLBFA_1) ==="; exit 1; }
.PHONY: compile1 run1

