MODULE = Pipeline

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/pipeline_pkg.sv \
           $(RTL_DIR)/memblock/Pipeline.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline.sv \
              $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv

# Queue1_L1PrefetchReq is a shared firtool-generated Decoupled Queue leaf (pure
# logic, NOT a 305 signoff target). Elaborate the real golden leaf on BOTH FM
# sides (ref via FM_REF_DEPS, impl via WRAPPER_SRCS) so it is a symmetric
# white-box comparison instead of an asymmetric black box (golden unresolved vs
# impl empty stub) that leaves a strict-mode residual -> PARTIAL. This is real
# equivalence (no waiver): the impl core drives the identical Queue leaf.
FM_REF_DEPS_Pipeline = Queue1_L1PrefetchReq.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/Pipeline_wrapper.sv \
               $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv
FM_VARIANTS = Pipeline

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
