MODULE = TLFIFOFixer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TLFIFOFixer.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLFIFOFixer.sv
FM_VARIANTS = TLFIFOFixer

include ../../../scripts/ut_common.mk

PORTLINT_ORDER = fail

# golden 有 96 个**不复位**寄存器 (stalls_id_0..95), 两种 initreg 策略都要过。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
