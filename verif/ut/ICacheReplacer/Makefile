MODULE = ICacheReplacer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheReplacer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheReplacer.sv
FM_VARIANTS = ICacheReplacer

include ../../../scripts/ut_common.mk

# golden ICacheReplacer.sv 含 firtool 随机初始化 initial 块（`ifndef SYNTHESIS）。
# 定义 SYNTHESIS 关闭随机初始化，使两侧均从复位态出发，正合逐拍输出比对所需。
VCS += +define+SYNTHESIS
