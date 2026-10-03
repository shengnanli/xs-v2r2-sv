MODULE = Arithmetic200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/FastArbiter_27.sv \
           $(RTL_DIR)/backend/FliDTable.sv \
           $(RTL_DIR)/backend/FliHTable.sv \
           $(RTL_DIR)/backend/FliSTable.sv \
           $(RTL_DIR)/backend/IntBuffer_1.sv \
           $(RTL_DIR)/backend/IntBuffer_2.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS = tb.sv
RTL_GOLDEN_DEPS = $(RTL_DIR)/common/xs_FastArbiter_core.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter_27.sv \
              $(GOLDEN_RTL)/FliDTable.sv \
              $(GOLDEN_RTL)/FliHTable.sv \
              $(GOLDEN_RTL)/FliSTable.sv \
              $(GOLDEN_RTL)/IntBuffer_1.sv \
              $(GOLDEN_RTL)/IntBuffer_2.sv \
              $(GOLDEN_RTL)/Rec7Table.sv \
              $(GOLDEN_RTL)/Rsqrt7Table.sv
FM_VARIANTS = FastArbiter_27 FliDTable FliHTable FliSTable IntBuffer_1 IntBuffer_2 Rec7Table Rsqrt7Table
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS
VCS_ARCH_OVERRIDE := linux
