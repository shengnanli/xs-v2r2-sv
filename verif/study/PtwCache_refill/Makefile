# PtwCache 回填写数据锥体的定向差分对照（study，不是验收 UT —— 见 tb.sv 头注释）。
#
#   make run            # 默认 20000 拍
#   make run NCYCLES=200000 SEED=7
#
# 为什么不放 verif/ut/：验收 UT 要比**全部 236 个输出**并跑够 3 seed × 200k 拍；
# 本对照只比 l1/l0 SRAM 的 430 根写端口，覆盖面窄得多，拿它当验收会是假绿。
XSSV_HOME ?= $(abspath ../../..)
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
export VCS_ARCH_OVERRIDE := linux

SEED    ?= 1
NCYCLES ?= 20000

IMPL     = $(XSSV_HOME)/rtl/mmu/PtwCache.sv
DFT      = $(XSSV_HOME)/rtl/dft/MbistPipePtwL0.sv $(XSSV_HOME)/rtl/dft/MbistPipePtwL1.sv \
           $(XSSV_HOME)/rtl/dft/xs_mbist_pipe_core.sv
# 两侧共用的同一份 golden 叶子：SRAM 壳、时钟门控、SRAM 模板与厂商行为模型。
SHARED   = $(GOLDEN_RTL)/SplittedSRAM_1.sv $(GOLDEN_RTL)/SplittedSRAM_2.sv \
           $(GOLDEN_RTL)/ClockGate.sv \
           $(GOLDEN_RTL)/SRAMTemplate_128.sv $(GOLDEN_RTL)/SRAMTemplate_129.sv \
           $(GOLDEN_RTL)/SRAMTemplate_143.sv \
           $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv \
           $(wildcard $(GOLDEN_RTL)/sram_array_*ptw_l1*.sv) \
           $(GOLDEN_RTL)/array_10.sv $(GOLDEN_RTL)/array_11.sv \
           $(GOLDEN_RTL)/array_10_ext.v $(GOLDEN_RTL)/array_11_ext.v
GOLDEN   = $(GOLDEN_RTL)/PtwCache.sv

VCS = vcs -full64 -sverilog -timescale=1ns/1ps +lint=TFIPC-L -l compile.log

.PHONY: run derive clean
derive:
	python3 $(XSSV_HOME)/scripts/derive_ut_impl.py --out gen $(IMPL)

simv: derive tb.sv
	$(VCS) +define+SYNTHESIS gen/PtwCache.sv $(DFT) $(GOLDEN) $(SHARED) tb.sv -o simv

run: simv
	./simv +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l run_seed$(SEED).log

clean:
	rm -rf simv simv.daidir csrc gen *.log ucli.key

# 判别力自证（不进库的 mutant 记录见 tb.sv 头注释 B/C 两条）。
# 想复验：临时改 rtl/mmu/parts/25_refill_wdata.svpart，重跑 gen_ptwcache.py 再 make run，
# errors 必须变成非零；验完务必把 parts 改回去并重跑生成器（--check 会卡住忘记改回的情况）。
