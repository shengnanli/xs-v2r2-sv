MODULE = CSRPermitModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# CSRPermit(权限检查组合逻辑)+ Mhpmevent(13 事件寄存器)。可读转写(去 sim init 块)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_permit_mhpmevent.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/CSRPermitModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = CSRPermitModule MhpmeventModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
