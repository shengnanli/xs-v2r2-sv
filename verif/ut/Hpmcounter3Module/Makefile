MODULE = Hpmcounter3Module

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读参数化 primitive xs_hpmcounter + 该 index 的薄 wrapper Hpmcounter3Module。
# wrapper 绑定 golden 的 per-instance 端口名 mHPM_hpmcounters_0 到 primitive 的 mhpm_src。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_hpmcounter.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/Hpmcounter3Module_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Hpmcounter3Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden Hpmcounter3Module.sv(ref) vs impl(primitive + wrapper)。
# 无黑盒、无 dont_verify、无 allow —— 逐寄存器/逐 compare-point 全等价。
FM_VARIANTS = Hpmcounter3Module

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS
