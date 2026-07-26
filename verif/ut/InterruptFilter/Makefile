MODULE = InterruptFilter

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# Readable, primitive-factored InterruptFilter, emitted as two identical-body
# modules (different names) plus xs_iprio_merge / xs_delay_n primitives (which
# also provide the readable DelayN_17 / DelayN_210 bodies):
#   - InterruptFilter.sv     module InterruptFilter    (FM impl side, golden name)
#   - InterruptFilter_xs.sv  module InterruptFilter_xs (UT twin, distinct name)
#
#   RTL_SRCS     : primitives + UT twin.  For the UT: dut_g = golden InterruptFilter
#                  (GOLDEN_SRCS), dut_x = InterruptFilter_xs — no name collision, so
#                  the comparison is genuine (verified by a bug-injection negctl).
#   WRAPPER_SRCS : the golden-named InterruptFilter core (FM impl only; NOT in
#                  RTL_SRCS so the UT never sees a second `InterruptFilter`).  FM
#                  reads it DIRECTLY (flat, no wrapper hierarchy) → 0 failing.
#   TB_SRCS      : the dual-instantiation testbench.
# FM impl = RTL_SRCS + WRAPPER_SRCS = prims + twin + InterruptFilter (twin is an
# unused extra top; FM_TOP=InterruptFilter).
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_intrfilter_prims.sv \
               $(RTL_DIR)/backend/InterruptFilter_xs.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/InterruptFilter.sv
TB_SRCS      = tb.sv

# golden InterruptFilter + its two DelayN shift-register cells (deps).
GOLDEN_SRCS  = $(GOLDEN_RTL)/InterruptFilter.sv \
               $(GOLDEN_RTL)/DelayN_17.sv \
               $(GOLDEN_RTL)/DelayN_210.sv

FM_VARIANTS         = InterruptFilter
FM_REF_DEPS_InterruptFilter = DelayN_17.sv DelayN_210.sv

include ../../../scripts/ut_common.mk

VCS += +incdir+$(RTL_DIR)/backend
VCS += +define+SYNTHESIS
