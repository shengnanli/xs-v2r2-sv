MODULE = VLMergeBufferImp

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/vlmergebuffer_pkg.sv $(RTL_DIR)/memblock/VLMergeBufferImp.sv
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/FreeList.sv \
  $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VLMergeBufferImp.sv $(GOLDEN_SUBS)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VLMergeBufferImp_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = VLMergeBufferImp
FM_REF_DEPS_VLMergeBufferImp = FreeList.sv NewPipelineConnectPipe_27.sv
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
