# VSSplitBufferImp —— 向量 store 拆分缓冲（VSplitBuffer 家族的 store 变体：多 vstd 数据通路与非对齐门控）
# 无子模块。核 xs_VSplitBuffer_core 在 VLSplitBufferImp.sv（那个文件里的 load wrapper 在本 UT 里不被例化）。
MODULE = VSSplitBufferImp

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/vlsu_pkg.sv \
           $(RTL_DIR)/memblock/VLSplitBufferImp.sv \
           $(RTL_DIR)/memblock/VSSplitBufferImp.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VSSplitBufferImp.sv

FM_VARIANTS = VSSplitBufferImp

# 关掉 merge_duplicated_registers：逐个比而不是合并后比；也让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据与复核判据见 verif/fm_target_config/VSSplitBufferImp.tcl★（两侧对称的死位，FM 按名 matched_nc）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

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
