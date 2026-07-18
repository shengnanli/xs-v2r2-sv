MODULE = ICacheMissUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# golden 顶层依赖的子模块（仅 golden 侧需要：UT 的 golden 例化 + FM 的 ref）
GOLDEN_SUBMODS = \
  $(GOLDEN_RTL)/DeMultiplexer.sv $(GOLDEN_RTL)/DeMultiplexer_1.sv \
  $(GOLDEN_RTL)/MuxBundle.sv $(GOLDEN_RTL)/Arbiter5_MSHRAcquire.sv \
  $(GOLDEN_RTL)/FIFOReg.sv \
  $(GOLDEN_RTL)/ICacheMSHR.sv $(GOLDEN_RTL)/ICacheMSHR_1.sv \
  $(GOLDEN_RTL)/ICacheMSHR_2.sv $(GOLDEN_RTL)/ICacheMSHR_3.sv \
  $(GOLDEN_RTL)/ICacheMSHR_4.sv $(GOLDEN_RTL)/ICacheMSHR_5.sv \
  $(GOLDEN_RTL)/ICacheMSHR_6.sv $(GOLDEN_RTL)/ICacheMSHR_7.sv \
  $(GOLDEN_RTL)/ICacheMSHR_8.sv $(GOLDEN_RTL)/ICacheMSHR_9.sv \
  $(GOLDEN_RTL)/ICacheMSHR_10.sv $(GOLDEN_RTL)/ICacheMSHR_11.sv \
  $(GOLDEN_RTL)/ICacheMSHR_12.sv $(GOLDEN_RTL)/ICacheMSHR_13.sv

# 手写可读核（自包含，不例化 golden 网表子模块）+ golden 同名包装层
RTL_SRCS = $(RTL_DIR)/frontend/ICacheMissUnit.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheMissUnit_wrapper.sv
# UT：golden 顶层 + 其子模块（双例化共用）
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMissUnit.sv $(GOLDEN_SUBMODS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = ICacheMissUnit
# 关闭重复寄存器合并：impl killed/killed2（对应 golden flush/fencei 双寄存器）是
# 有意的 1:1 复刻对，合并会把 killed/killed2 折成一只、令 flush_reg 的钉点失配。
FM_MERGE_DUP = false
# FM ref（golden 顶层）依赖：golden 子模块
FM_REF_DEPS_ICacheMissUnit = \
  DeMultiplexer.sv DeMultiplexer_1.sv MuxBundle.sv Arbiter5_MSHRAcquire.sv FIFOReg.sv \
  ICacheMSHR.sv ICacheMSHR_1.sv ICacheMSHR_2.sv ICacheMSHR_3.sv \
  ICacheMSHR_4.sv ICacheMSHR_5.sv ICacheMSHR_6.sv ICacheMSHR_7.sv \
  ICacheMSHR_8.sv ICacheMSHR_9.sv ICacheMSHR_10.sv ICacheMSHR_11.sv \
  ICacheMSHR_12.sv ICacheMSHR_13.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
# 须放在 include 之后：ut_common.mk 用 := 重置 VCS，会丢弃 include 前的 +=。
VCS += +define+SYNTHESIS
