MODULE = TLBuffer_15

# TLBuffer_15：rocket-chip TLBuffer(BufferParams.default) 的 64 位 A/D 两通道变体（L2Top 3 处）。
# impl = 已签共享核 xs_TLBuffer_ad_core（不改）+ 本变体薄文件 + 已签重写队列（两侧白盒）。
# ram_2x133 / ram_2x76 是 firtool 行为级存储叶子：两侧读同一份 golden 文件（inline，不是黑盒）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \
           $(RTL_DIR)/memblock/TLBuffer_15.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_12.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_13.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x133.sv \
                  $(GOLDEN_RTL)/ram_2x76.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_15.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv
FM_REF_DEPS_TLBuffer_15 = Queue2_TLBundleA_12.sv Queue2_TLBundleD_13.sv ram_2x133.sv ram_2x76.sv
FM_VARIANTS = TLBuffer_15
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
