MODULE = FreeListVariants

RTL_DIR = ../../../rtl
# 核体在 FreeList.sv 里（家族共用的 xs_FreeList_core，全仓只此一份），
# 四个变体文件各自只有一个设参数 + 端口展平的 wrapper。
RTL_SRCS = $(RTL_DIR)/memblock/FreeList.sv \
           $(RTL_DIR)/memblock/FreeList_1.sv \
           $(RTL_DIR)/memblock/FreeList_3.sv \
           $(RTL_DIR)/memblock/FreeList_4.sv \
           $(RTL_DIR)/memblock/FreeList_6.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/FreeList_1.sv $(GOLDEN_RTL)/FreeList_3.sv \
              $(GOLDEN_RTL)/FreeList_4.sv $(GOLDEN_RTL)/FreeList_6.sv

# 四个变体在 golden 里都是自包含叶子（`grep -cE '^  [A-Z]' 量过：0 个子模块例化），
# 所以没有 FM_REF_DEPS_*，闭包里也没有任何厂商 SRAM 宏 —— 零黑盒。
FM_VARIANTS = FreeList_1 FreeList_3 FreeList_4 FreeList_6

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言与随机初值 initial 块（都在 `ifndef SYNTHESIS 里）；
# FM 两侧都带 -define SYNTHESIS 读入，UT 保持同一口径。
#
# ★为什么两轮 initreg 在这里是真有区别的★：FreeList_4 / FreeList_6 是 preAlloc 变体，
#   io_allocateSlot_*_r / io_canAllocate_*_r 共 6 个寄存器**不在复位臂里**
#   （Chisel RegEnable(x, true.B) 展开成无条件 always @(posedge clock)）。
#   FreeList_1 / FreeList_3 不是 preAlloc，全部寄存器都有异步复位臂 ——
#   对这两个来说两轮必然同结果，那一轮证明的是"它们确实全复位"这个结构结论。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# tb 由生成器产出；这道检查防"手改 tb.sv 后被下一次生成静默覆盖"。
.PHONY: gencheck mutants
gencheck:
	python3 gen_tb.py --check

mutants:
	python3 mutants.py
