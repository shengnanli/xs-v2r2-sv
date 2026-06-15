MODULE = ICacheReplacer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 参数化可读核：UT 编译 + FM impl 都用。
#   - ICacheReplacer.sv : xs_ICacheReplacer_core
RTL_SRCS = $(RTL_DIR)/frontend/ICacheReplacer.sv

# golden 同名包装层，仅 FM 用（FM impl = RTL_SRCS + WRAPPER_SRCS）：
#   - ICacheReplacer_wrapper.sv : 模块 ICacheReplacer（核 xs_ICacheReplacer_core）
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheReplacer_wrapper.sv

# UT 双例化比对：golden ICacheReplacer。
#   tb 例化 golden ICacheReplacer 与 ICacheReplacer_xs。
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheReplacer.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = ICacheReplacer

include ../../../scripts/ut_common.mk

# golden ICacheReplacer.sv 含 firtool 随机初始化 initial 块（`ifndef SYNTHESIS）。
# 定义 SYNTHESIS 关闭随机初始化，使两侧均从复位态出发，正合逐拍输出比对所需。
VCS += +define+SYNTHESIS
