MODULE = StridePF

# SMS 的 PC 步长检测器（本配置下无输出端口，只剩表维护逻辑）。单文件：核 + golden 同名 wrapper。
# 共享辅助件：rtl/common/xs_PlruReplacer（16 路 PLRU）。无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/memblock/StridePF.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/StridePF.sv

FM_VARIANTS = StridePF
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 没有输出端口：tb 逐拍比两侧全部寄存器（层次引用）。prev_pc / entries_pc / s1_match_vec 不复位：
# 只比"已被写过"的位（valid 项的 pc、s0_valid 发生过之后的 match_vec、lookup 发生过之后的 prev_pc）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
