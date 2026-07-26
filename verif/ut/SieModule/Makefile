MODULE = SieModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 中断使能/挂起别名 CSR: Sie/Sip(S 视图)/VSie/VSip(VS 视图)。可读转写 + wire 改名。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_sip_sie_batch.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/SieModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = SieModule SipModule VSieModule VSipModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
