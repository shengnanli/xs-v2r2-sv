MODULE = IntFile

# IntFile（IMSIC 的一个中断文件：256 位 eip/eie + eidelivery/eithreshold + topei 优先级）。
# golden 无子模块；impl 单文件核 + wrapper。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IntFile.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IntFile.sv
FM_VARIANTS = IntFile

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在 false 下严格适用；加强不是放宽。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 随机初始化块与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。全部寄存器异步复位，
# 复位撤销后两侧状态确定，initreg 三档只是按全仓规矩跑。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
