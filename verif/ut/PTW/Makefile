MODULE = PTW

RTL_DIR = ../../../rtl
# 单文件规范：私有包 + 核 + golden 同名 wrapper 全在 PTW.sv；PTE 类型与判定函数在 mmu 公共包。
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/mmu/PTW.sv
TB_SRCS = tb.sv

# golden PTW 是叶子模块（无子模块），闭包只有它自己。
GOLDEN_SRCS = $(GOLDEN_RTL)/PTW.sv

FM_VARIANTS = PTW
FM_REF_DEPS_PTW =
# 叶子模块：关掉重复寄存器合并，让 passing 与 fm_predict.py 的模型逐位可对账。
# ★golden 里 mem_cycle 的 BoolStopWatch 有两份同样的寄存器（perfEvents_5_2 与只接悬空探针的 r）★
# impl 照抄两份（mem_cycle_watch / mem_cycle_watch_probe），后者两侧都没人读 —— 是 1↔1 的
# matched-unread 点，打开 vmucp 让 FM 把它也证一遍（更严，不是放松）；白名单依据见
# verif/fm_target_config/PTW.tcl。
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 里的 XSError/assert 段（`ifndef SYNTHESIS）随机激励下会触发 $fatal，统一关掉。
# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★：random 给两个实例各摇各的初值，
# PTW 有 vpn/ppn/stage1/hptw_resp 等大批不复位寄存器，两侧初态不同比出的差异与重写无关。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
