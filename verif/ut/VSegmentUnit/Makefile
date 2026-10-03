# VSegmentUnit —— 向量 segment 访存单元（14 态状态机：逐元素 TLB → PMP → DCache / sbuffer，逐条 uop 写回）
#
# 子模块 2 个，两侧白盒：VSegmentTrigger（本 lane 重写签核，核与 MemTrigger 共用 rtl/memblock/MemTrigger.sv）、
# NewPipelineConnectPipe_33（已签核：rtl/uncore/NewPipelineConnectPipe_33.sv + rtl/common/PipelineConnect.sv）。
# ref 读 golden 整棵子树，impl 读重写件整棵子树，无黑盒。
# rtl/memblock/VSegmentUnit.sv / vsegment_pkg.sv 的 GENERATED 段与本目录 tb.sv 由 scripts/gen_vsegmentunit.py 生成。
MODULE = VSegmentUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/vlsu_pkg.sv \
           $(RTL_DIR)/memblock/vsegment_pkg.sv \
           $(RTL_DIR)/memblock/MemTrigger.sv \
           $(RTL_DIR)/memblock/VSegmentTrigger.sv \
           $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_33.sv \
           $(RTL_DIR)/memblock/VSegmentUnit.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VSegmentUnit.sv $(GOLDEN_RTL)/VSegmentTrigger.sv $(GOLDEN_RTL)/NewPipelineConnectPipe_33.sv

FM_VARIANTS = VSegmentUnit
FM_REF_DEPS_VSegmentUnit = VSegmentTrigger.sv NewPipelineConnectPipe_33.sv

# 关掉 merge_duplicated_registers：latchVaddr / latchVaddrDup 这类同源寄存器逐个比；fm_predict 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据与复核判据见 verif/fm_target_config/VSegmentUnit.tcl★（22 个两侧对称的死位，FM 按名 matched_nc）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 / 断言）两侧统一关掉。
# 队列 / instMicroOp 的 payload 寄存器不复位：非常量 initreg 档两个实例各摇各的初值，先跑 WARMUP 拍再比。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= +vcs+initreg+random
WARMUP  ?= $(if $(filter +vcs+initreg+0 +vcs+initreg+1,$(INITREG)),0,6000)
SIM_ARGS += $(INITREG) +warmup=$(WARMUP)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_vsegmentunit.py --check
