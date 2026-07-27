MODULE = MMIOBridgeEntry_4

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 参数化可读核 xs_MMIOBridgeEntry_core(自包含 MMIO 事务 FSM, 无子模块)。
RTL_SRCS = $(RTL_DIR)/l2/MMIOBridgeEntry.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/MMIOBridgeEntry_4_wrapper.sv
# golden 顶层(叶子, 无子模块依赖)。
GOLDEN_SRCS = $(GOLDEN_RTL)/MMIOBridgeEntry_4.sv
# UT 变体: impl 顶层改名 MMIOBridgeEntry_4_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 signoff-strict; 无子模块无黑盒。golden 参数变体家族(io_id 位宽 + txnID
# 零填充), 单参数化核 #(.ID_W(N)) 逐位复刻。
FM_VARIANTS = MMIOBridgeEntry_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
