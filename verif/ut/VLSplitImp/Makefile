# VLSplitImp —— 向量 load 拆分单元装配壳（拆分流水 → skid 缓冲 → 拆分缓冲）
# 三个子模块（VLSplitPipelineImp / skidBufferConnect / VLSplitBufferImp）都在本 lane 重写签核，
# 处置 = 两侧白盒：ref 读 golden 整棵子树，impl 读重写件整棵子树，无黑盒。
MODULE = VLSplitImp

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/vlsu_pkg.sv \
           $(RTL_DIR)/memblock/VLSplitPipelineImp.sv \
           $(RTL_DIR)/memblock/VLSplitBufferImp.sv \
           $(RTL_DIR)/memblock/skidBufferConnect.sv \
           $(RTL_DIR)/memblock/VLSplitImp.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VLSplitImp.sv $(GOLDEN_RTL)/VLSplitPipelineImp.sv $(GOLDEN_RTL)/VLSplitBufferImp.sv $(GOLDEN_RTL)/skidBufferConnect.sv

FM_VARIANTS = VLSplitImp
FM_REF_DEPS_VLSplitImp = VLSplitPipelineImp.sv VLSplitBufferImp.sv skidBufferConnect.sv

# 关掉 merge_duplicated_registers：逐个比而不是合并后比；也让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据与复核判据见 verif/fm_target_config/VLSplitImp.tcl★（两侧对称的死位，FM 按名 matched_nc）
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
