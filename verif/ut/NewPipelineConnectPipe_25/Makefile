# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = NewPipelineConnectPipe_25

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/NewPipelineConnectPipe_25.sv \
           $(RTL_DIR)/common/PipelineConnect.sv
TB_SRCS = tb.sv

# golden 双例化：golden 顶 + 其全部子模块传递闭包（两侧共用同一份子模块定义，
# 比对的是本目标自己的逻辑；子模块本身由各自的目标去证）。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewPipelineConnectPipe_25.sv

FM_VARIANTS = NewPipelineConnectPipe_25
FM_REF_DEPS_NewPipelineConnectPipe_25 = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
