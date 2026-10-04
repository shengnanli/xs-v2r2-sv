# Serializer —— Sbuffer store 预取的串行化 FIFO（ENABLE_SPB=false 下只剩一个死指针）。无输出端口，tb 用层次探针逐拍比内部寄存器。
MODULE = Serializer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/Serializer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Serializer.sv

FM_VARIANTS = Serializer
FM_MERGE_DUP = false
# 全部 5 个比较点零扇出（无输出端口），只能靠 vmucp 真比较，见 verif/fm_target_config/Serializer.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
# tb.sv 手写（无输出端口，无 gen.py）；gencheck 恒真
gencheck:
	@echo "Serializer: tb.sv 为手写探针 tb，无生成器"
