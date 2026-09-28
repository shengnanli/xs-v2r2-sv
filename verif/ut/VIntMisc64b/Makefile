MODULE = VIntMisc64b

RTL_DIR  = ../../../rtl
# 本体（手写核 + wrapper）+ 子模块 CLZ_6/7/9/11 的重写件（PROVEN_DIRECT，两侧白盒：
# ref 侧用 golden CLZ，impl 侧用这里的重写件）。
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_11.sv \
           $(RTL_DIR)/backend/VIntMisc64b.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/VIntMisc64b.sv \
              $(GOLDEN_RTL)/CLZ_6.sv \
              $(GOLDEN_RTL)/CLZ_7.sv \
              $(GOLDEN_RTL)/CLZ_9.sv \
              $(GOLDEN_RTL)/CLZ_11.sv
FM_VARIANTS = VIntMisc64b
FM_REF_DEPS_VIntMisc64b = CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_11.sv

# 纯组合、无寄存器；关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
