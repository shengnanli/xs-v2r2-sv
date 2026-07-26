MODULE = SiregModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitives xs_indireg (base: 写锁存+外部 rdata 透传+regOut) / xs_indireg_wo
# (numbered: 写锁存+regOut)。golden 无 reset —— clock-only 写锁存。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_indireg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/SiregModule_wrapper.sv \
               $(RTL_DIR)/backend/Sireg2Module_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/SiregModule.sv $(GOLDEN_RTL)/Sireg2Module.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 两形态代表各干净 SUCCEEDED (regOut_ALL/rdata 全读, 无死寄存器)。
# 无黑盒/无 dont_verify/无 allow。同 primitive 证 Mireg*/VSireg* 及 N=3..6。
FM_VARIANTS = SiregModule Sireg2Module

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
