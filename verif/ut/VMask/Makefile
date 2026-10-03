MODULE = VMask

RTL_DIR  = ../../../rtl
# 本体（手写核 + wrapper），无子模块。
RTL_SRCS = $(RTL_DIR)/backend/VMask.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/VMask.sv
FM_VARIANTS = VMask

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期由 INITREG 选取值（0 / random / <数值种子>）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

# vmucp（加强不是放宽）：唯一的 120 个 unread 点是 vs1_reg_s1[127:8]（只读低 8 位），两侧对称死位，
# 依据与复核判据见 verif/fm_target_config/VMask.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
