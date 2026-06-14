MODULE = IPrefetchPipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/IPrefetchPipe.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/IPrefetchPipe_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/IPrefetchPipe.sv $(GOLDEN_RTL)/Arbiter2_ICacheMissReq.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = IPrefetchPipe
# golden 顶层例化 Arbiter2_ICacheMissReq，FM ref 侧需带上其源文件
FM_REF_DEPS_IPrefetchPipe = Arbiter2_ICacheMissReq.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言（multi-hit/one-hot $fatal）；
# UT 随机激励下定义 SYNTHESIS 关掉。须在 include 之后追加，否则被 ut_common.mk
# 的 VCS := 覆盖（include 前 VCS 尚未定义）。
VCS += +define+SYNTHESIS
