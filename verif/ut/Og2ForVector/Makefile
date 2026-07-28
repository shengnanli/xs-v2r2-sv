MODULE = Og2ForVector

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 (golden 同名 self-contained, 纯逻辑无子模块)。
# UT 双例化: golden Og2ForVector (u_g) vs 可读核 _xs 变体 (u_i)。为避免 UT 编译期与
# golden 同名撞名, golden-名可读核 Og2ForVector.sv 只进 FM impl 侧 (WRAPPER_SRCS)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/Og2ForVector.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Og2ForVector.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = Og2ForVector

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
