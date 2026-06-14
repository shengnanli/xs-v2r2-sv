MODULE = ICacheMainPipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/frontend/ICacheMainPipe.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheMainPipe_wrapper.sv
# golden ICacheMainPipe 例化子模块 Arbiter2_ICacheMissReq；手写核已内联，
# 但 UT 双例化时 golden 侧仍需该子模块文件。
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheMainPipe.sv $(GOLDEN_RTL)/Arbiter2_ICacheMissReq.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = ICacheMainPipe
# FM ref 侧依赖（除变体本体外）：内联前的 Arbiter 子模块
FM_REF_DEPS_ICacheMainPipe = Arbiter2_ICacheMissReq.sv

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

include ../../../scripts/ut_common.mk
