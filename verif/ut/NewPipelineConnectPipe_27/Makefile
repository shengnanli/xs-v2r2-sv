MODULE = NewPipelineConnectPipe_27

RTL_DIR = ../../../rtl
# 家族共享核体 xs_PipelineConnect 在 rtl/common/PipelineConnect.sv；
# 变体文件只固化参数与端口拼包。
RTL_SRCS = $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_27.sv
TB_SRCS = tb.sv

# G1 的 NewPipelineConnectPipe_27 = CtrlUnit.CtrlUnitPseudoErrorPipelineConnect0/1（39 端口）。
# ★G0 的同名文件（82 端口）是 VMergeBuffer 那个连接级，在 G1 里叫 _29，不是这个。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv
FM_VARIANTS = NewPipelineConnectPipe_27

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
