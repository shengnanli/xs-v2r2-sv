MODULE = SinkC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/sinkc_pkg.sv $(RTL_DIR)/uncore/SinkC.sv
# RRArbiterInit_14(通用轮询仲裁器纯逻辑, 非305目标非vendor)两侧 elaborate 白盒比对
# (SourceB 对 FastArbiter_6 同法), 禁止黑盒非vendor逻辑子模块
WRAPPER_SRCS = $(RTL_DIR)/uncore/SinkC_wrapper.sv $(GOLDEN_RTL)/RRArbiterInit_14.sv

# 核内例化 RRArbiterInit_14: UT/变体编译与 golden 比对都需要它
GOLDEN_SRCS = $(GOLDEN_RTL)/SinkC.sv $(GOLDEN_RTL)/RRArbiterInit_14.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: RRArbiterInit_14 两侧 elaborate(非黑盒), 比 SinkC 控制逻辑 + 仲裁器内部状态
FM_VARIANTS = SinkC
FM_REF_DEPS_SinkC = RRArbiterInit_14.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
