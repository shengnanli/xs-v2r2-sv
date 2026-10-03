# VMergeBuffer UT —— 向量访存合并缓冲家族（VLMergeBufferImp / VSMergeBufferImp），一个 tb 两对。
#
# 参数化核 xs_VMergeBuffer_core + VLMergeBufferImp wrapper 在 rtl/memblock/VLMergeBufferImp.sv；
# VSMergeBufferImp.sv 只是 store 变体的薄 wrapper；两者共用的 package vmergebuffer_pkg 在
# rtl/memblock/vmergebuffer_pkg.sv（单独成文件，免得 VS 依赖 VL 的编译顺序）。
# 子模块全部白盒例化本仓已签核的重写件（UT 里派生成 *_xs）：
#   FreeList（load 槽位表）/ FreeList_1（store 槽位表，核在 FreeList.sv）、
#   NewPipelineConnectPipe_29（写回口流水缓冲，核在 rtl/common/PipelineConnect.sv）。
# wrapper、核里的机械区与 tb.sv 由 scripts/gen_vmergebuf.py 生成（make gencheck 校验未过期）。
MODULE = VMergeBuffer

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/vmergebuffer_pkg.sv \
           $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_29.sv \
           $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/FreeList_1.sv \
           $(RTL_DIR)/memblock/VLMergeBufferImp.sv \
           $(RTL_DIR)/memblock/VSMergeBufferImp.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VLMergeBufferImp.sv $(GOLDEN_RTL)/VSMergeBufferImp.sv \
              $(GOLDEN_RTL)/FreeList.sv $(GOLDEN_RTL)/FreeList_1.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_29.sv

FM_VARIANTS = VLMergeBufferImp VSMergeBufferImp
# FM：子模块两侧白盒 —— ref 侧用 golden 的 FreeList(_1) / NewPipelineConnectPipe_29，
# impl 侧用 RTL_SRCS 里已签核的重写件，两侧完整 elaborate，不设任何黑盒。
FM_REF_DEPS_VLMergeBufferImp = FreeList.sv NewPipelineConnectPipe_29.sv
FM_REF_DEPS_VSMergeBufferImp = FreeList_1.sv NewPipelineConnectPipe_29.sv

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型严格适用
# （load 版里 valid / mBIndex 被打成三份独立寄存器，golden 与核都一份不少）。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/VLMergeBufferImp.tcl / VSMergeBufferImp.tcl★ ——
# 两侧对称的只写不读位（load：unit-stride 合并锁存的取不到的高位、hit 恒 1 下的 replayFlowNum、
# 流水缓冲里 store 类异常位；store：debug 的 isPartReplay、流水缓冲里 load 类异常位）。
# 名字鸿沟由 fm_pins_pre.tcl（流水缓冲 payload，生成）与 fm_pins.tcl（条目 SoA 叶名规则）消除。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值 initial 块 / XSError 断言）两侧统一关掉。
# 两轮 initreg 真有区别：条目数据字段、流水锁存、反馈寄存器都不复位；tb 用暖机把只在异常时
# 才写的字段（gpaddr 等）先写一遍，uopWriteback/toLsq/feedback 的 bits 只在 valid 时比较。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_vmergebuf.py --check
