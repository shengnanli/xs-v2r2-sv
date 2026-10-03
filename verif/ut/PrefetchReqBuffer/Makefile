MODULE = PrefetchReqBuffer

# VBOP 的虚地址预取请求缓冲（单文件：核 + golden 同名 wrapper）。
# 子模块：两个轮转仲裁器 RRArbiterInit_14（TLB 口）/ RRArbiterInit_15（PF 口），
# docs/coverage_three_axis.tsv 均 PROVEN_DIRECT → 两侧白盒：ref 用 golden 同名件，impl 用 rtl/common 重写件。无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_14.sv \
           $(RTL_DIR)/common/RRArbiterInit_15.sv \
           $(RTL_DIR)/l2/PrefetchReqBuffer.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchReqBuffer.sv \
              $(GOLDEN_RTL)/RRArbiterInit_14.sv \
              $(GOLDEN_RTL)/RRArbiterInit_15.sv

FM_VARIANTS = PrefetchReqBuffer
FM_REF_DEPS_PrefetchReqBuffer = RRArbiterInit_14.sv RRArbiterInit_15.sv
FM_MERGE_DUP = false

# ★vmucp + 钉点：依据见 verif/fm_target_config/PrefetchReqBuffer.tcl★（146 位块内偏移 / paddr 高位）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 条目字段 / s1 打拍 / TLB 发出寄存器不复位：tb 只在相应 valid 出现过之后比数据（见 tb 头注释）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)
