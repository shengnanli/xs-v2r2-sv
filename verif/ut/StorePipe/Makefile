MODULE = StorePipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 = storepipe_pkg + StorePipe(xs_StorePipe_core 完整三级流水, 对齐 derivative)
RTL_SRCS = $(RTL_DIR)/memblock/storepipe_pkg.sv $(RTL_DIR)/memblock/StorePipe.sv
# WRAPPER_SRCS 进入 FM 的 impl 侧(顶层 golden 同名 StorePipe 包装)。
WRAPPER_SRCS = $(RTL_DIR)/memblock/StorePipe_wrapper.sv
# UT 对拍 reference = codex_0088 §3 canonical-derivative(module StorePipe;
# G0-StorePipe-observable-v1 G0-flags 派生; sha 7d675b69...)。不进 FM(FM 侧 golden
# 由 plumbing owner 经 manifest/runner 指向 canonical_derivative)。
GOLDEN_SRCS = StorePipe_derivative_ref.sv
TB_SRCS = tb.sv

# 本 target FM 官方 golden = canonical-derivative(main-owned manifest/runner 指向,
# 见 plumbing owner)。UT 只做 derivative-vs-core 对拍。FM_VARIANTS 留给官方 runner。
FM_VARIANTS = StorePipe

include ../../../scripts/ut_common.mk

# derivative 与核都用 init-free 寄存器; UT 用 +vcs+initreg+0 令两侧初值一致。
VCS      += +define+SYNTHESIS
SIM_ARGS += +vcs+initreg+0
