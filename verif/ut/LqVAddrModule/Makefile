MODULE = LqVAddrModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LqVAddrModule.sv
TB_SRCS = tb.sv

# 三个延迟件（各 1 个寄存器）的处置：**两侧同源 elaborate**，不设黑盒 ——
# 与本仓已绿目标的既定做法一致（FCVT 的 FPCVT 闭包、SNXbar 的 FastArbiter、
# DuplicatedTagArray 的 TagArray 闭包都是这么做的）。ref 与 impl 读的是
# G1-canonical 下**同一份** golden 文件，不存在"拿 golden 逻辑冒充重写成果"：
# 本目标要证的是 72 项阵列的译码/分 bank/打拍/Mux1H 写入这套 glue，延迟件只是
# 它的边界元件，而且 DelayN_13 在本仓另有独立重写目标（rtl/common/DelayN_13.sv）。
# 反过来若设黑盒，24×3 个黑盒实例的路径名两侧对不上（golden 是扁平的
# sx_*_delay_<n>，重写件是 u_core.g_bank[b].g_wport[w].*），要靠 FM 的拓扑匹配
# 兜底，风险更大而证明更弱。
LQV_DELAYS = DelayN_13.sv DelayNWithValid_152.sv DelayNWithValid_155.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LqVAddrModule.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(LQV_DELAYS))
FM_REF_DEPS_LqVAddrModule = $(LQV_DELAYS)
FM_VARIANTS = LqVAddrModule

include ../../../scripts/ut_common.mk

# ★ 本模块 75 个寄存器（72 条目 + 3 读数据）**全部不复位**，两轮 initreg 都要过。
#   不复位 ⇒ 两侧随机初值不同，必须先暖机写满 72 项再比对，见 tb.sv 的 WARMUP。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
