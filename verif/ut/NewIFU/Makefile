MODULE = NewIFU

# NewIFU（取指单元 f0–f3 + wb + MMIO 取指状态机）。golden 直接 child 21 个实例 / 5 种：
#   PreDecode / F3Predecoder / RVCExpander×17（main 上已签核，PROVEN_DIRECT）
#   PredChecker / FrontendTrigger（本 lane 重写并签核）
# 处置 = **两侧白盒**：ref 读 golden 同名件，impl 读本仓重写件（重写核直接例化各 child 的可读核
# xs_*_core），无黑盒。证明的是"golden 整棵子树 == 重写整棵子树"。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/frontend_common_pkg.sv \
           $(RTL_DIR)/frontend/NewIFU.sv \
           $(RTL_DIR)/frontend/PreDecode.sv \
           $(RTL_DIR)/frontend/F3Predecoder.sv \
           $(RTL_DIR)/frontend/RVCExpander.sv \
           $(RTL_DIR)/frontend/PredChecker.sv \
           $(RTL_DIR)/frontend/FrontendTrigger.sv
TB_SRCS  = tb.sv

NEWIFU_CHILDREN = PreDecode.sv F3Predecoder.sv RVCExpander.sv PredChecker.sv FrontendTrigger.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/NewIFU.sv $(addprefix $(GOLDEN_RTL)/,$(NEWIFU_CHILDREN))

FM_VARIANTS = NewIFU
FM_REF_DEPS_NewIFU = $(NEWIFU_CHILDREN)

# 关掉 merge_duplicated_registers：golden 有值恒等的重复寄存器（REG / wb_enable_REG 等，重写核
# 照留），合并后两侧幸存者可能不同；且只有关掉时 fm_predict 的 passing 模型才严格适用。
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_newifu_lane.py --check
