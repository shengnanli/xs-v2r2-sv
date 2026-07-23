MODULE = SourceB

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv
# FastArbiter_6(通用仲裁器纯逻辑, 非305目标非vendor)两侧 elaborate 白盒比对
WRAPPER_SRCS = $(RTL_DIR)/uncore/SourceB_wrapper.sv $(GOLDEN_RTL)/FastArbiter_6.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv $(GOLDEN_RTL)/FastArbiter_6.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: FastArbiter_6 两侧 elaborate(非黑盒), 仅比 SourceB 控制逻辑 + 仲裁器
FM_VARIANTS = SourceB
FM_REF_DEPS_SourceB = FastArbiter_6.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
