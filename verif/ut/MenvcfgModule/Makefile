MODULE = MenvcfgModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 简单单一用途寄存器 CSR 批次2(newcsr_simplereg_batch2.sv): 可读转写。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_simplereg_batch2.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MenvcfgModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MseccfgModule SenvcfgModule MenvcfgModule HenvcfgModule \
              TselectModule VtypeModule VcsrModule Hviprio1Module \
              Hviprio2Module HvictlModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
