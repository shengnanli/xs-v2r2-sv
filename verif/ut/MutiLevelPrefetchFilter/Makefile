# MutiLevelPrefetchFilter —— L1 流式预取的多级预取请求过滤表（MemBlock/L1Prefetcher.pf_queue_filter）
#
# 子模块 = 4 个轮转仲裁器 RRArbiterInit_7/8/9/6，本仓已重写并签核（PROVEN_DIRECT），两侧白盒：
# UT 里 impl 侧用重写件（派生成 *_xs），golden 侧用 golden 文件；FM 里 ref 侧走 FM_REF_DEPS
# （golden 的 4 个仲裁器文件），impl 侧走 RTL_SRCS 里的重写件（家族核 RRArbiterInit.sv + 4 个薄 wrapper）。
MODULE = MutiLevelPrefetchFilter

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_6.sv \
           $(RTL_DIR)/common/RRArbiterInit_7.sv \
           $(RTL_DIR)/common/RRArbiterInit_8.sv \
           $(RTL_DIR)/common/RRArbiterInit_9.sv \
           $(RTL_DIR)/memblock/MutiLevelPrefetchFilter.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
MLPF_CHILDREN = RRArbiterInit_6.sv RRArbiterInit_7.sv RRArbiterInit_8.sv RRArbiterInit_9.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MutiLevelPrefetchFilter.sv $(addprefix $(GOLDEN_RTL)/,$(MLPF_CHILDREN))

FM_VARIANTS = MutiLevelPrefetchFilter
FM_REF_DEPS_MutiLevelPrefetchFilter = $(MLPF_CHILDREN)

# 关掉 merge_duplicated_registers：golden 里有值恒等的多份寄存器（s1_l1_region 与
# s1_l1_prefetch_req_region 等），让 FM 逐个比而不是各侧自己合并；也让 fm_predict 的
# passing 模型严格适用。这是加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值/断言）两侧统一关掉。
# 两轮 initreg 有区别：表项内容、s1 流水、s3 回应、冲刷打拍、s1_pf_valid 都不复位。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen.py --check
