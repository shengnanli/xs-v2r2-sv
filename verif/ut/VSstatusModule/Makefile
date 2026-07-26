MODULE = VSstatusModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke VSstatusModule(newcsr_vsstatus_wrappers.sv): VS 模式 sstatus 视图,
# 虚拟化下 FS/VS dirty 跟踪, SDT 受 menvcfg.DTE&henvcfg.DTE 门控。中间 wire 语义改名。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_vsstatus_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/VSstatusModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = VSstatusModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
