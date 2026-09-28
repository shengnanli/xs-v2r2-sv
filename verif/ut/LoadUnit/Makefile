# LoadUnit —— 标量/向量 load 的 4 级流水（MemBlock 里 3 条 load 流水同一模块）
#
# 子模块只有 MemTrigger（loadTrigger，本工程已重写签核）：UT 里 impl 侧用重写件（派生成 MemTrigger_xs），
# golden 侧用 golden 文件；FM 两侧都白盒 elaborate（ref 走 FM_REF_DEPS 的 golden MemTrigger.sv，
# impl 走 RTL_SRCS 里的重写 MemTrigger.sv）。
# rtl/memblock/LoadUnit.sv 的 GENERATED 段与本目录 tb.sv 由 gen_loadunit.py 生成（`make gencheck`）。
MODULE = LoadUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MemTrigger.sv \
           $(RTL_DIR)/memblock/LoadUnit.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadUnit.sv $(GOLDEN_RTL)/MemTrigger.sv

FM_VARIANTS = LoadUnit
FM_REF_DEPS_LoadUnit = MemTrigger.sv

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 / 断言）两侧统一关掉。
# 两档 initreg 真有区别：s1_in / s2_in / s3_in 三级流水寄存器、MMIO / 非对齐唤醒的打拍链、
# 预取训练锁存等都不复位。+random 档两个实例各摇各的初值，先跑 WARMUP 拍（全部被写过）再比。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= +vcs+initreg+random
WARMUP  ?= $(if $(filter +vcs+initreg+0 +vcs+initreg+1,$(INITREG)),0,3000)
SIM_ARGS += $(INITREG) +warmup=$(WARMUP)

.PHONY: gencheck
gencheck:
	python3 gen_loadunit.py --check
