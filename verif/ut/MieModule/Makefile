MODULE = MieModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 中断使能/挂起 CSR 批次(newcsr_ie_ip_batch.sv): Mie(多源写仲裁)/Hip(组合)/
# Hie(组合别名)/Mvip/Mvien/Hvip/Hvien(大位向量寄存器)。可读转写(去 sim init 块)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_ie_ip_batch.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MieModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MieModule HipModule HieModule MvipModule MvienModule HvipModule HvienModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
