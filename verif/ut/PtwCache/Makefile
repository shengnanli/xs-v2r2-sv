# PtwCache UT/FM —— 自含 Makefile（不 include ut_common.mk，因为需要 +incdir 引入 svh）。
# 验证策略与 ut_common 一致：UT 双例化逐拍比对；FM fm_eq.tcl。
MODULE = PtwCache
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
XSSV_HOME ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)

# 手写核 + 包（svh 通过 +incdir 引入）
RTL_SRCS = $(RTL_DIR)/memblock/ptwcache_pkg.sv $(RTL_DIR)/memblock/PtwCache.sv
# golden 同名 wrapper（FM 用）；UT 用 variants_xs.sv 里的 PtwCache_xs
WRAPPER_SRCS = $(RTL_DIR)/memblock/PtwCache_wrapper.sv

# golden 黑盒存储/DFT 依赖（UT/FM 两侧共用）
SRAM_DEPS = \
  $(GOLDEN_RTL)/SplittedSRAM.sv $(GOLDEN_RTL)/SplittedSRAM_1.sv \
  $(GOLDEN_RTL)/SRAMTemplate_122.sv $(GOLDEN_RTL)/SRAMTemplate_126.sv \
  $(GOLDEN_RTL)/MbistPipePtwL1.sv $(GOLDEN_RTL)/MbistPipePtwL0.sv $(GOLDEN_RTL)/ClockGate.sv \
  $(GOLDEN_RTL)/sram_array_1p8x200m100s1h0l1b_ptw_l1.sv \
  $(GOLDEN_RTL)/sram_array_1p32x228m114s1h0l1b_ptw_l0.sv \
  $(GOLDEN_RTL)/array_10.sv $(GOLDEN_RTL)/array_10_ext.v \
  $(GOLDEN_RTL)/array_11.sv $(GOLDEN_RTL)/array_11_ext.v

GOLDEN_SRCS = $(GOLDEN_RTL)/PtwCache.sv $(SRAM_DEPS)

export VCS_ARCH_OVERRIDE := linux
VCS = vcs -full64 -sverilog -timescale=1ns/1ps -kdb -lca -debug_access+all +lint=TFIPC-L \
      +incdir+$(RTL_DIR)/memblock -l compile.log
SEED ?= 1
SIM_ARGS ?= +define+SYNTHESIS

.PHONY: compile run verdi fm clean

compile: simv
simv: $(RTL_SRCS) variants_xs.sv tb.sv $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) variants_xs.sv $(GOLDEN_SRCS) tb.sv -top tb -o simv

run: simv
	./simv +ntb_random_seed=$(SEED) $(SIM_ARGS) -l sim.log
	@grep -q "TEST PASSED" sim.log && echo "=== UT PASSED ($(MODULE)) ===" \
		|| { echo "=== UT FAILED ($(MODULE)) ==="; exit 1; }

verdi:
	verdi -ssf novas.fsdb -nologo &

# FM：ref = golden PtwCache + SRAM 黑盒；impl = 手写核 + wrapper + SRAM 黑盒。
fm:
	@mkdir -p fm_work/PtwCache
	FM_TOP=PtwCache \
	FM_REF_SRCS="$(abspath $(GOLDEN_SRCS))" \
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS) $(WRAPPER_SRCS) $(SRAM_DEPS))" \
	FM_INCDIR="$(abspath $(RTL_DIR)/memblock)" \
	FM_MERGE_DUP=false \
	fm_shell -64 -work_path fm_work/PtwCache -file $(XSSV_HOME)/scripts/fm_eq.tcl \
	    > fm_work/PtwCache/fm.log 2>&1; \
	grep -E "^FM_RESULT" fm_work/PtwCache/fm.log; \
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/PtwCache/fm.log

clean:
	rm -rf simv* csrc *.log ucli.key novas.* verdiLog fm_work *.fsdb *.daidir \
	       vc_hdrs.h formality* fm_shell_command.log* *.fdc default.svf
