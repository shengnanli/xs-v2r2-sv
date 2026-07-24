MODULE = Pmpcfg0Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读参数化 primitive xs_pmpcfg + 该 index 的薄 wrapper Pmpcfg0Module (HI=0)。
# 纯组合: rdata = regOut_ALL = cfgRData[63:0]。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_pmpcfg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/Pmpcfg0Module_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Pmpcfg0Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden Pmpcfg0Module.sv(ref) vs impl(primitive + wrapper)。
# 无黑盒、无 dont_verify、无 allow —— 逐 compare-point 全等价。
FM_VARIANTS = Pmpcfg0Module

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐语义(纯组合无寄存器)。
VCS += +define+SYNTHESIS
