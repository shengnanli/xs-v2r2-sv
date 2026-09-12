MODULE = TLBuffer_13

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer_13.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
                  $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv

FM_REF_DEPS_TLBuffer_13 = Queue2_TLBundleA_19.sv Queue2_TLBundleB_1.sv Queue2_TLBundleC_1.sv Queue2_TLBundleD_20.sv Queue2_TLBundleE_1.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv \
              $(GOLDEN_RTL)/ram_2x119.sv \
              $(GOLDEN_RTL)/ram_2x352.sv \
              $(GOLDEN_RTL)/ram_2x321.sv \
              $(GOLDEN_RTL)/ram_2x283.sv \
              $(GOLDEN_RTL)/ram_sink_2x8.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = nodeIn_b_q_1_ram_ext, nodeIn_b_q_2_ram_ext, nodeIn_b_q_3_ram_ext, nodeIn_b_q_ram_ext, nodeIn_d_q_1_ram_ext, nodeIn_d_q_2_ram_ext…
FM_MODE = assembly
FM_ALLOWLIST ?= 20
FM_VARIANTS = TLBuffer_13

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
