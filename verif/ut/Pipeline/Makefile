MODULE = Pipeline

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/pipeline_pkg.sv \
           $(RTL_DIR)/memblock/Pipeline.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline.sv \
              $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/Pipeline_wrapper.sv \
               $(RTL_DIR)/memblock/pipeline_queue_blackbox.sv
FM_VARIANTS = Pipeline

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
