MODULE = Pipeline

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/Pipeline.sv \
           $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv
TB_SRCS = tb.sv

FM_REF_DEPS_Pipeline = Queue1_L1PrefetchReq.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline.sv \
              $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv
FM_VARIANTS = Pipeline

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
