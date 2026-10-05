MODULE = LCredit2Decoupled_1

# LCredit2Decoupled_1：LinkMonitor 的 RXRSP 接收端（coupledL2 LinkLayer.scala LCredit2Decoupled，
# blocking=false、lcreditNum=15，无队列）。0 子模块、0 黑盒。与已签 LCredit2Decoupled_2 同构。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_1.sv
FM_VARIANTS = LCredit2Decoupled_1
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器异步复位；上电复位后两侧同态。golden 的 LinkLayer.scala:155 断言在 SYNTHESIS 下关掉。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
