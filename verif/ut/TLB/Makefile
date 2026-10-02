MODULE = TLB

# TLB = 前端 itlb（Frontend.inner_itlb）：2 条非阻塞取指口 + 1 条阻塞口。
# golden 直接 child 3 个：DelayN_9（sfence 延迟）/ DelayN_7（CSR 延迟）/ TlbStorageWrapper（表项，
# 内含 TLBFA 48 项全相联阵列）。docs/coverage_three_axis.tsv 里四者都是 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件（DelayN 家族核 / TlbStorageWrapper 家族核 /
# TLBFA 家族核）。无黑盒，闭包里没有厂商 SRAM 宏（TLBFA 是寄存器阵列）。
# 核与 wrapper 的机械派生区（端口表 / 三个子模块连线 / PTW 响应打包 / 输出展平）由
# scripts/gen_mmuleaf.py 生成；tb.sv 由本目录 gen_tb.py 生成。
RTL_DIR  = ../../../rtl
# memblock 公共包排最前：tlbnb_pkg / xs_tlbsw_pkg 住在这里，多个文件的模块头 import 它。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_7.sv \
           $(RTL_DIR)/common/DelayN_9.sv \
           $(RTL_DIR)/memblock/xs_TLBFA_core.sv \
           $(RTL_DIR)/memblock/TLBFA.sv \
           $(RTL_DIR)/memblock/xs_TlbStorageWrapper_core.sv \
           $(RTL_DIR)/memblock/TlbStorageWrapper.sv \
           $(RTL_DIR)/memblock/TLB.sv
TB_SRCS  = tb.sv

TLB_CHILDREN = DelayN_9.sv DelayN_7.sv TlbStorageWrapper.sv TLBFA.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/TLB.sv $(addprefix $(GOLDEN_RTL)/,$(TLB_CHILDREN))

FM_VARIANTS = TLB
FM_REF_DEPS_TLB = $(TLB_CHILDREN)

# 关掉 merge_duplicated_registers：golden 有值恒等的多份寄存器（每口一份的 PTW 旁路 p_*、
# ptw_resp_bits_reg / _1、difftest 打拍），让 FM 逐个比；fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块两侧统一关掉（与 FM 口径一致）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen_tb.py --check
	python3 ../../../scripts/gen_mmuleaf.py --check
