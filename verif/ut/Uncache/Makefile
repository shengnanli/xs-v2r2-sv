MODULE = Uncache

RTL_DIR  = ../../../rtl
# 单文件：uncache_pkg + 手写核 xs_Uncache_core + 生成的 wrapper（scripts/gen_uncache.py）。
RTL_SRCS = $(RTL_DIR)/memblock/Uncache.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Uncache.sv
FM_VARIANTS = Uncache

# 两侧对称的死位（f1 地址比较寄存器与 f1_fwdPAddr 的 [2:0]、条目 vaddr[2:0]：写了从不读），
# 按 vmucp standing rule 实开比较；精确绑定见 verif/fm_target_config/Uncache.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
# 关 merge_dup：fm_predict 的 passing 模型（寄存器位 + 输出位）只在它关闭时成立
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 xs_assert_v2 DPI 断言（ifndef SYNTHESIS），UT 与 FM 一样按综合视图编。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
