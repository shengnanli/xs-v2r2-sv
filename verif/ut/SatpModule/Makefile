MODULE = SatpModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# atp/gatp CSRs(newcsr_atp_wrappers.sv): Satp / VSatp(hgatp_MODE 掩码) / Hgatp。
# MODE WARL 仅接受 Bare(0)/Sv39(8)/Sv48(9), 非法 MODE 丢弃。三者结构各异。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_atp_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/SatpModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = SatpModule VSatpModule HgatpModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
