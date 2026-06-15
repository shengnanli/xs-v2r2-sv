MODULE = PMPChecker
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/pmp_pkg.sv $(RTL_DIR)/memblock/PMPChecker.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/PMPChecker_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PMPChecker.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = PMPChecker PMPChecker_10
include ../../../scripts/ut_common.mk

# 寄存变体 PMPChecker_10 的独立 UT（组合变体走默认 compile/run）
SEED ?= 1
compile10: simv10
simv10: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_10.sv $(GOLDEN_RTL)/PMPChecker_10.sv
	$(VCS) $(RTL_SRCS) $(WRAPPER_SRCS) $(GOLDEN_RTL)/PMPChecker_10.sv variants_xs.sv tb_10.sv -top tb -o simv10
run10: simv10
	./simv10 +ntb_random_seed=$(SEED) -l sim10.log
	@grep -q "TEST PASSED" sim10.log && echo "=== UT PASSED (PMPChecker_10) ===" \
		|| { echo "=== UT FAILED (PMPChecker_10) ==="; exit 1; }
.PHONY: compile10 run10
