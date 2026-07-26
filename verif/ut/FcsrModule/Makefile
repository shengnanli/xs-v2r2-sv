MODULE = FcsrModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# Fcsr/Mnstatus/Dcsr/Hstatus 可读转写(去 sim init 块 + CIRCT 中间 wire 改名)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_fcsr_mnstatus.sv $(RTL_DIR)/backend/newcsr_dcsr_hstatus.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/FcsrModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = FcsrModule MnstatusModule DcsrModule HstatusModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
