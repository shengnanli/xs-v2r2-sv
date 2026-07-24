MODULE = Mhpmcounter3Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读参数化 primitive xs_mhpmcounter + 该 index 的薄 wrapper Mhpmcounter3Module。
# wrapper 固定 IDX=0；primitive 内部选 mcountinhibit_HPM3[IDX]，与 golden 一致。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_mhpmcounter.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/Mhpmcounter3Module_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Mhpmcounter3Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden Mhpmcounter3Module.sv(ref) vs impl(primitive + wrapper)。
# 无黑盒、无 dont_verify、无 allow —— 逐寄存器/逐 compare-point 全等价。
FM_VARIANTS = Mhpmcounter3Module

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
