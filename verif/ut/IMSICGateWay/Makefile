MODULE = IMSICGateWay

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/IMSICGateWay.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IMSICGateWay.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = msi_vld_req_cpu_chain
FM_MODE = assembly
FM_ALLOWLIST ?= 1
FM_VARIANTS = IMSICGateWay

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
