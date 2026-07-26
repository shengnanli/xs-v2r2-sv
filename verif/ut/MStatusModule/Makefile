MODULE = MStatusModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke MStatusModule(newcsr_mstatus_wrappers.sv): 18 域, 多源写通仲裁,
# sstatus 别名, FS/VS dirty 跟踪, SDT/DTE 交互。CIRCT 中间 wire 全部语义改名。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_mstatus_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MStatusModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MStatusModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
