MODULE = HPTW

RTL_DIR = ../../../rtl
# 单文件规范：核 + golden 同名 wrapper 全在 HPTW.sv；PTE 类型与判定函数在 mmu 公共包。
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/mmu/HPTW.sv
TB_SRCS = tb.sv

# golden HPTW 是叶子模块（无子模块），闭包只有它自己。
GOLDEN_SRCS = $(GOLDEN_RTL)/HPTW.sv

FM_VARIANTS = HPTW
FM_REF_DEPS_HPTW =
# 叶子模块、无重复寄存器结构：关掉合并，让 passing 与 fm_predict.py 的模型逐位可对账。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 里的 XSError/assert 段（`ifndef SYNTHESIS）随机激励下会触发 $fatal，统一关掉。
# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★：random 给两个实例各摇各的初值，
# HPTW 有 gpaddr/req_ppn/cache_pte_* 等不复位寄存器，两侧初态不同比出的差异与重写无关。
# 编译期只能给 +vcs+initreg+random（打开机制），档位在运行期用 +vcs+initreg+N 选。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
