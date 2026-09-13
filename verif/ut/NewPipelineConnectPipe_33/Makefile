MODULE = NewPipelineConnectPipe_33

RTL_DIR = ../../../rtl
# 家族共享核体 xs_PipelineConnect 在 rtl/common/PipelineConnect.sv；
# 变体文件只固化参数与端口拼包。
RTL_SRCS = $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_33.sv
TB_SRCS = tb.sv

# G1 的 NewPipelineConnectPipe_33 = VSegmentUnit.VSegmentUnitPipelineConnect（17 端口）。
# ★不要拿 G0 的同名文件（96 端口）来当 golden——那是另一个模块，在 G1 里叫 _35。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewPipelineConnectPipe_33.sv
FM_VARIANTS = NewPipelineConnectPipe_33

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
