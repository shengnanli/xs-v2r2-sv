MODULE = TLBNonBlock_2
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbnonblock2_pkg.sv $(RTL_DIR)/memblock/TLBNonBlock_2.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBNonBlock_2_wrapper.sv
BLACKBOX = $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_9.sv \
           $(GOLDEN_RTL)/TlbStorageWrapper_3.sv $(GOLDEN_RTL)/TLBFA_3.sv $(GOLDEN_RTL)/TLBFA.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock_2.sv $(BLACKBOX)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TLBNonBlock_2
FM_REF_DEPS_TLBNonBlock_2 =
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(BLACKBOX) $(GOLDEN_RTL)/TLBNonBlock_2.sv $(TB_SRCS) -top tb -o simv
