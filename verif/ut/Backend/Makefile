# 自动生成:scripts/gen_backend.py —— 勿手改
MODULE = Backend

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/glue/inst svh)。
RTL_SRCS = $(RTL_DIR)/backend/backend_pkg.sv \
           $(RTL_DIR)/backend/Backend.sv

TB_SRCS = variants_xs.sv tb.sv

# 31 子模块类型作 golden 黑盒;UT 双例化两侧共用同一份 golden 定义。
# 更深的 golden 叶子由 -y GOLDEN_RTL 按文件名自动解析。
SUB_DEPS = $(GOLDEN_RTL)/BypassNetwork.sv \
           $(GOLDEN_RTL)/CtrlBlock.sv \
           $(GOLDEN_RTL)/DataPath.sv \
           $(GOLDEN_RTL)/DelayN_1.sv \
           $(GOLDEN_RTL)/ExuBlock.sv \
           $(GOLDEN_RTL)/ExuBlock_1.sv \
           $(GOLDEN_RTL)/ExuBlock_2.sv \
           $(GOLDEN_RTL)/HPerfMonitor_2.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_1.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_10.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_13.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_14.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_16.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_18.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_20.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_23.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_25.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_5.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_7.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_8.sv \
           $(GOLDEN_RTL)/NewPipelineConnectPipe_9.sv \
           $(GOLDEN_RTL)/Og2ForVector.sv \
           $(GOLDEN_RTL)/PFEvent.sv \
           $(GOLDEN_RTL)/Scheduler.sv \
           $(GOLDEN_RTL)/Scheduler_1.sv \
           $(GOLDEN_RTL)/Scheduler_2.sv \
           $(GOLDEN_RTL)/Scheduler_3.sv \
           $(GOLDEN_RTL)/VecExcpDataMergeModule.sv \
           $(GOLDEN_RTL)/WbDataPath.sv \
           $(GOLDEN_RTL)/WbFuBusyTable.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Backend.sv $(SUB_DEPS)

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/backend/Backend_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = Backend
FM_REF_DEPS_Backend = BypassNetwork.sv CtrlBlock.sv DataPath.sv DelayN_1.sv ExuBlock.sv ExuBlock_1.sv ExuBlock_2.sv HPerfMonitor_2.sv NewPipelineConnectPipe.sv NewPipelineConnectPipe_1.sv NewPipelineConnectPipe_10.sv NewPipelineConnectPipe_13.sv NewPipelineConnectPipe_14.sv NewPipelineConnectPipe_16.sv NewPipelineConnectPipe_18.sv NewPipelineConnectPipe_20.sv NewPipelineConnectPipe_23.sv NewPipelineConnectPipe_25.sv NewPipelineConnectPipe_5.sv NewPipelineConnectPipe_7.sv NewPipelineConnectPipe_8.sv NewPipelineConnectPipe_9.sv Og2ForVector.sv PFEvent.sv Scheduler.sv Scheduler_1.sv Scheduler_2.sv Scheduler_3.sv VecExcpDataMergeModule.sv WbDataPath.sv WbFuBusyTable.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
