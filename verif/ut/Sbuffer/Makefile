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
# golden ref 侧依赖：仅 SbufferData（数据阵列白盒展开、与 impl 平铺阵列逐点钉）。
# StorePfWrapper 预取器链**两侧都不给源码**→ hdlin_unresolved_modules=black_box 同名
# 黑盒配对（两侧实例名同为 prefetcher）；否则 ref 白盒/impl 黑盒不对称，
# io_store_prefetch_* 输出锥必失配。UT 仍用完整 GOLDEN_SRCS 不受影响。
FM_REF_DEPS_Sbuffer = SbufferData.sv

# 16 份结构相同的 entry/cohCount/data 寄存器，关掉“合并同值重复寄存器”pass，
# 避免把它们折叠成两侧不对称。
# FM 审计 2026-07：golden 侧存在大量真「同值重复副本」（每 forward 口 16 份 fwd_ptag
# 打拍、line_wen 复制等），重写核只留一份；合并 pass 正是为折叠这类副本，改回 true。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
