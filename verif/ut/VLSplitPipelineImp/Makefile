# VLSplitPipelineImp —— 向量 load 拆分流水（s0 译码算掩码 → s1 算偏移、向合并缓冲要条目）
# 无子模块。核 xs_VSplitPipeline_core 与 load wrapper 同在 VLSplitPipelineImp.sv，类型在 vlsu_pkg.sv。
MODULE = VLSplitPipelineImp

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/vlsu_pkg.sv \
           $(RTL_DIR)/memblock/VLSplitPipelineImp.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VLSplitPipelineImp.sv

FM_VARIANTS = VLSplitPipelineImp

# 关掉 merge_duplicated_registers：逐个比而不是合并后比；也让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 / 断言）两侧统一关掉。
# 整包寄存器不复位：非常量 initreg 档两个实例各摇各的初值，先跑 WARMUP 拍再比；常量档从第 0 拍比。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= +vcs+initreg+random
WARMUP  ?= $(if $(filter +vcs+initreg+0 +vcs+initreg+1,$(INITREG)),0,3000)
SIM_ARGS += $(INITREG) +warmup=$(WARMUP)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_vsplit.py --check
