MODULE = SbpctlModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 简单单一用途寄存器 CSR 批次1(newcsr_simplereg_batch1.sv): 可读转写
# (golden 结构体已是清晰 always_ff, 去掉不可综合 randomize-init 块 + 文档头)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_simplereg_batch1.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/SbpctlModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = HgeipModule HgeieModule ScountovfModule McorepwrModule \
              MflushpwrModule VstartModule SrnctlModule McountinhibitModule \
              SbpctlModule SpfctlModule SmblockctlModule SlvpredctlModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
