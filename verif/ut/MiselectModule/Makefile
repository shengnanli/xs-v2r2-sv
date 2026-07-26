MODULE = MiselectModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 parametric primitive(newcsr_iselect.sv)+ 3 个薄 wrapper。
# iselect family: Miselect(9b)/Siselect(13b)/VSiselect(13b); 写高位=0 才更新,
# inIMSICRange = value∈(0x6F,0x100)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_iselect.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_iselect_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MiselectModule.sv $(GOLDEN_RTL)/SiselectModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MiselectModule SiselectModule VSiselectModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
