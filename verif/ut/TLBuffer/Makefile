MODULE = TLBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/tlbuffer_pkg.sv \
           $(RTL_DIR)/memblock/TLBuffer.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD.sv \
              $(GOLDEN_RTL)/ram_2x153.sv \
              $(GOLDEN_RTL)/ram_2x90.sv

# INLINE(裁定 option2): 移除 Queue2 黑盒桩, 两侧链入真实 golden Queue2 + 其 ram 存储,
# FM 证明 TLBuffer glue + Queue2 队列(状态/回压/时序)整体 strict 等价(pilot: 739点 SUCCEEDED,
# 0黑盒/0unread/0dont-verify), 而非假设 Queue2 相同 → 无需 Queue2 独立 leaf 或 assembly 契约。
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBuffer_wrapper.sv \
               $(GOLDEN_RTL)/Queue2_TLBundleA.sv \
               $(GOLDEN_RTL)/Queue2_TLBundleD.sv \
               $(GOLDEN_RTL)/ram_2x153.sv \
               $(GOLDEN_RTL)/ram_2x90.sv
FM_REF_DEPS_TLBuffer = Queue2_TLBundleA.sv Queue2_TLBundleD.sv ram_2x153.sv ram_2x90.sv
FM_VARIANTS = TLBuffer

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
