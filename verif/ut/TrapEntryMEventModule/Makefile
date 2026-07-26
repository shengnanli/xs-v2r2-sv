MODULE = TrapEntryMEventModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# trap-entry / xret 事件 CSR(组合次态函数)。可读转写 + _T_<n>→_t<n> 改名。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_event_batch.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/TrapEntryMEventModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MretEventModule SretEventModule DretEventModule MNretEventModule \
              TrapEntryMEventModule TrapEntryHSEventModule TrapEntryVSEventModule \
              TrapEntryDEventModule TrapEntryMNEventModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
