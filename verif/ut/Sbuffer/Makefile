MODULE = Sbuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包
RTL_SRCS = $(RTL_DIR)/memblock/sbuffer_pkg.sv \
           $(RTL_DIR)/memblock/Sbuffer.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 Sbuffer + 其子模块（SbufferData 数据阵列；StorePfWrapper 预取黑盒及其内部
# Serializer / StorePrefetchBursts / Arbiter）。UT 双例化两侧都用这些 golden 子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/Sbuffer.sv \
              $(GOLDEN_RTL)/SbufferData.sv \
              $(GOLDEN_RTL)/StorePfWrapper.sv \
              $(GOLDEN_RTL)/Serializer.sv \
              $(GOLDEN_RTL)/StorePrefetchBursts.sv \
              $(GOLDEN_RTL)/PrefetchBurstGenerator.sv \
              $(GOLDEN_RTL)/Arbiter2_StorePrefetchReq.sv

# FM：golden 顶层 Sbuffer vs 手写同名 wrapper（→ 可读核 + pkg + 黑盒 StorePfWrapper）
WRAPPER_SRCS = $(RTL_DIR)/memblock/Sbuffer_wrapper.sv
FM_VARIANTS = Sbuffer
# golden ref 侧依赖：SbufferData + 预取黑盒链。impl 侧 wrapper 例化 StorePfWrapper 作黑盒。
FM_REF_DEPS_Sbuffer = SbufferData.sv StorePfWrapper.sv Serializer.sv \
                      StorePrefetchBursts.sv PrefetchBurstGenerator.sv \
                      Arbiter2_StorePrefetchReq.sv

# 16 份结构相同的 entry/cohCount/data 寄存器，关掉“合并同值重复寄存器”pass，
# 避免把它们折叠成两侧不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
