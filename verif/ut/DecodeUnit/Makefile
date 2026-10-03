# DecodeUnit —— 简单译码器（6 份 decoders_0..5 例化在 DecodeStage 里，同一模块）
#
# 子模块 FPDecoder / UopInfoGen 本工程都已重写签核，两侧都不黑盒：UT 里 impl 侧用重写件
# （派生成 *_xs），golden 侧用 golden 文件；FM 里 ref 侧走 FM_REF_DEPS（golden 的 4 个文件：
# FPDecoder + UopInfoGen 及其两张表），impl 侧走 RTL_SRCS 里的重写 wrapper，两侧完整 elaborate。
MODULE = DecodeUnit

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FPDecoder.sv \
           $(RTL_DIR)/backend/UopInfoGen.sv \
           $(RTL_DIR)/backend/DecodeUnit.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/DecodeUnit.sv $(GOLDEN_RTL)/FPDecoder.sv $(GOLDEN_RTL)/UopInfoGen.sv \
              $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv

FM_VARIANTS = DecodeUnit
FM_REF_DEPS_DecodeUnit = FPDecoder.sv UopInfoGen.sv strdiedLSNumOfUopTable.sv indexedLSNumOfUopTable.sv

# 本目标没有寄存器，merge_dup 无可合并之物；关掉它只是让 fm_predict 的 passing 模型
# （寄存器位 + 输出端口位）按构造适用，不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值/断言）两侧统一关掉。
# 本目标是纯组合逻辑、无寄存器：两轮 initreg（+0 / +random）对它没有区分度，
# 但按规矩两轮都跑（编译期打开机制，运行期 INITREG 选档）。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gen
gen:
	python3 gen.py
