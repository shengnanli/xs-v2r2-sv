MODULE = PMPEntryHandleModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# PMP/PMA entry-handle(跨条目 WARL 合法化: 地址解码 + lock/grain 规则 + 打包写总线)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_pmp_pma_entryhandle.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/PMPEntryHandleModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = PMPEntryHandleModule PMAEntryHandleModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
